DO $$
DECLARE
  category_id_type text;
  categories_primary_key text;
BEGIN
  SELECT data_type INTO category_id_type
  FROM information_schema.columns
  WHERE table_schema = 'public'
    AND table_name = 'categories'
    AND column_name = 'id';

  IF category_id_type = 'uuid' THEN
    IF EXISTS (
      SELECT 1
      FROM pg_constraint
      WHERE contype = 'f'
        AND confrelid = 'public.categories'::regclass
        AND conrelid <> COALESCE(
          to_regclass('public.catalog_items'),
          'public.categories'::regclass
        )
    ) THEN
      RAISE EXCEPTION
        'Cannot convert category IDs while other tables reference categories';
    END IF;

    ALTER TABLE public.categories
      ADD COLUMN repo_category_id text;
    UPDATE public.categories
    SET repo_category_id = CASE lower(btrim(name))
      WHEN 'crops' THEN 'crops'
      WHEN 'crops and produce' THEN 'crops'
      WHEN 'livestock' THEN 'livestock'
      WHEN 'services' THEN 'services'
      WHEN 'jobs' THEN 'jobs'
      WHEN 'cooperatives' THEN 'cooperatives'
      WHEN 'supplies' THEN 'supplies'
      WHEN 'equipment' THEN 'equipment'
      WHEN 'equipment & machinery' THEN 'equipment'
      ELSE NULL
    END;

    IF EXISTS (
      SELECT 1 FROM public.categories WHERE repo_category_id IS NULL
    ) OR EXISTS (
      SELECT repo_category_id
      FROM public.categories
      GROUP BY repo_category_id
      HAVING count(*) > 1
    ) THEN
      RAISE EXCEPTION
        'Category names cannot be mapped uniquely to repository category keys';
    END IF;

    IF to_regclass('public.catalog_items') IS NOT NULL
       AND EXISTS (
         SELECT 1
         FROM information_schema.columns
         WHERE table_schema = 'public'
           AND table_name = 'catalog_items'
           AND column_name = 'category_id'
           AND data_type = 'uuid'
       ) THEN
      ALTER TABLE public.catalog_items
        DROP CONSTRAINT IF EXISTS catalog_items_category_id_fkey;
      ALTER TABLE public.catalog_items
        ADD COLUMN legacy_category_uuid uuid;
      ALTER TABLE public.catalog_items
        RENAME COLUMN category_id TO category_id_uuid_old;
      ALTER TABLE public.catalog_items
        ADD COLUMN category_id text;
      UPDATE public.catalog_items AS item
      SET category_id = category.repo_category_id,
          legacy_category_uuid = item.category_id_uuid_old
      FROM public.categories AS category
      WHERE category.id = item.category_id_uuid_old;

      IF EXISTS (
        SELECT 1 FROM public.catalog_items WHERE category_id IS NULL
      ) THEN
        RAISE EXCEPTION
          'Some catalog items do not map to a known category';
      END IF;

      ALTER TABLE public.catalog_items
        DROP COLUMN category_id_uuid_old;
      ALTER TABLE public.catalog_items
        ALTER COLUMN category_id SET NOT NULL;
    END IF;

    UPDATE public.listings AS listing
    SET category_id = category.repo_category_id
    FROM public.categories AS category
    WHERE listing.category_id = category.id::text;

    SELECT conname INTO categories_primary_key
    FROM pg_constraint
    WHERE conrelid = 'public.categories'::regclass
      AND contype = 'p';
    IF categories_primary_key IS NULL THEN
      RAISE EXCEPTION 'Cannot find the categories primary key';
    END IF;
    EXECUTE format(
      'ALTER TABLE public.categories DROP CONSTRAINT %I',
      categories_primary_key
    );
    ALTER TABLE public.categories RENAME COLUMN id TO legacy_uuid_id;
    ALTER TABLE public.categories
      RENAME COLUMN repo_category_id TO id;
    ALTER TABLE public.categories
      ALTER COLUMN id SET NOT NULL;
    ALTER TABLE public.categories
      ADD CONSTRAINT categories_pkey PRIMARY KEY (id);

    IF to_regclass('public.catalog_items') IS NOT NULL
       AND EXISTS (
         SELECT 1
         FROM information_schema.columns
         WHERE table_schema = 'public'
           AND table_name = 'catalog_items'
           AND column_name = 'category_id'
           AND data_type = 'text'
       ) THEN
      ALTER TABLE public.catalog_items
        ADD CONSTRAINT catalog_items_category_id_fkey
        FOREIGN KEY (category_id) REFERENCES public.categories(id)
        ON DELETE CASCADE;
    END IF;
  END IF;
END;
$$;

ALTER TABLE public.categories
  ADD COLUMN IF NOT EXISTS name text,
  ADD COLUMN IF NOT EXISTS label_en text,
  ADD COLUMN IF NOT EXISTS label_lg text,
  ADD COLUMN IF NOT EXISTS icon_name text,
  ADD COLUMN IF NOT EXISTS sort_order integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS is_active boolean NOT NULL DEFAULT true;

UPDATE public.categories
SET label_en = COALESCE(NULLIF(label_en, ''), NULLIF(name, ''), id),
    icon_name = COALESCE(NULLIF(icon_name, ''), 'category');

ALTER TABLE public.categories
  ALTER COLUMN label_en SET NOT NULL,
  ALTER COLUMN icon_name SET NOT NULL;

UPDATE public.categories
SET label_en = CASE id
      WHEN 'crops' THEN 'Crops'
      WHEN 'livestock' THEN 'Livestock'
      WHEN 'services' THEN 'Services'
      WHEN 'supplies' THEN 'Supplies'
      WHEN 'equipment' THEN 'Equipment & Machinery'
      WHEN 'jobs' THEN 'Jobs'
      WHEN 'cooperatives' THEN 'Cooperatives'
      ELSE label_en
    END,
    icon_name = CASE id
      WHEN 'crops' THEN 'crops'
      WHEN 'livestock' THEN 'livestock'
      WHEN 'services' THEN 'service'
      WHEN 'supplies' THEN 'supplies'
      WHEN 'equipment' THEN 'equipment'
      WHEN 'jobs' THEN 'job'
      WHEN 'cooperatives' THEN 'coop'
      ELSE icon_name
    END,
    sort_order = CASE id
      WHEN 'crops' THEN 1
      WHEN 'livestock' THEN 2
      WHEN 'services' THEN 3
      WHEN 'supplies' THEN 4
      WHEN 'equipment' THEN 5
      WHEN 'jobs' THEN 6
      WHEN 'cooperatives' THEN 7
      ELSE sort_order
    END;

INSERT INTO public.categories
  (id, name, label_en, label_lg, icon_name, sort_order, is_active)
VALUES
  ('supplies', 'Supplies', 'Supplies', NULL, 'supplies', 4, true),
  ('equipment', 'Equipment', 'Equipment & Machinery', NULL, 'equipment', 5, true)
ON CONFLICT (id) DO UPDATE
SET label_en = EXCLUDED.label_en,
    icon_name = EXCLUDED.icon_name,
    sort_order = EXCLUDED.sort_order,
    is_active = true;

ALTER TABLE public.buyer_needs
  ADD COLUMN category_id text REFERENCES public.categories(id) ON DELETE SET NULL,
  ADD COLUMN created_via text NOT NULL DEFAULT 'app'
    CHECK (created_via IN ('app', 'sms', 'ussd'));

ALTER TABLE public.listings
  ADD COLUMN IF NOT EXISTS created_via text NOT NULL DEFAULT 'app'
    CHECK (created_via IN ('app', 'sms', 'ussd'));

CREATE OR REPLACE VIEW public.public_buyer_needs AS
SELECT
  need.id,
  need.user_id,
  need.item_name,
  need.quantity,
  need.unit,
  need.proposed_price_ugx,
  need.notes,
  need.contact_person,
  need.district_id,
  district.name AS district_name,
  need.subcounty_id,
  subcounty.name AS subcounty_name,
  need.parish_id,
  parish.name AS parish_name,
  need.created_at,
  CASE
    WHEN profile.is_anonymous THEN 'Anonymous buyer'
    ELSE COALESCE(NULLIF(profile.full_name, ''), 'Buyer')
  END AS poster_name,
  CASE WHEN profile.is_anonymous THEN NULL ELSE profile.avatar_url END
    AS poster_avatar_url,
  profile.is_verified AS poster_is_verified,
  profile.account_type AS poster_account_type,
  need.item_image_url,
  need.category_id,
  need.created_via
FROM public.buyer_needs AS need
JOIN public.districts AS district ON district.id = need.district_id
LEFT JOIN public.subcounties AS subcounty
  ON subcounty.id = need.subcounty_id
LEFT JOIN public.parishes AS parish
  ON parish.id = need.parish_id
JOIN public.profiles AS profile ON profile.id = need.user_id
WHERE need.status = 'active';

GRANT SELECT ON public.public_buyer_needs TO anon, authenticated;
