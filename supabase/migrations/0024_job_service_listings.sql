ALTER TABLE public.listings
  ADD COLUMN IF NOT EXISTS workers_needed integer,
  ADD COLUMN IF NOT EXISTS service_type text;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conrelid = 'public.listings'::regclass
      AND conname = 'listings_workers_needed_check'
  ) THEN
    ALTER TABLE public.listings
      ADD CONSTRAINT listings_workers_needed_check
      CHECK (workers_needed IS NULL OR workers_needed > 0);
  END IF;
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conrelid = 'public.listings'::regclass
      AND conname = 'listings_service_type_check'
  ) THEN
    ALTER TABLE public.listings
      ADD CONSTRAINT listings_service_type_check
      CHECK (service_type IS NULL OR length(btrim(service_type)) > 0);
  END IF;
END;
$$;
