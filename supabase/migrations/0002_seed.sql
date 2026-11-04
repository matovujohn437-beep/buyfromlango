INSERT INTO public.districts (id, name) VALUES
  (1, 'Alebtong'),
  (2, 'Amolatar'),
  (3, 'Apac'),
  (4, 'Dokolo'),
  (5, 'Kole'),
  (6, 'Kwania'),
  (7, 'Lira'),
  (8, 'Otuke'),
  (9, 'Oyam')
ON CONFLICT (name) DO UPDATE SET is_active = true;

SELECT setval(
  pg_get_serial_sequence('public.districts', 'id'),
  GREATEST((SELECT COALESCE(MAX(id), 1) FROM public.districts), 1),
  true
);

INSERT INTO public.subcounties (district_id, name)
SELECT districts.id, subcounties.name
FROM (VALUES
  ('Alebtong', 'Abako'),
  ('Alebtong', 'Abia'),
  ('Alebtong', 'Alebtong Town Council'),
  ('Alebtong', 'Amugu'),
  ('Alebtong', 'Apala'),
  ('Alebtong', 'Awei'),
  ('Alebtong', 'Awiri'),
  ('Alebtong', 'Omoro'),
  ('Amolatar', 'Amolatar Town Council'),
  ('Amolatar', 'Arwotcek'),
  ('Amolatar', 'Awelo'),
  ('Amolatar', 'Etam'),
  ('Amolatar', 'Muntu'),
  ('Amolatar', 'Namasale'),
  ('Amolatar', 'Nawalu'),
  ('Apac', 'Akokoro'),
  ('Apac', 'Apac Municipality'),
  ('Apac', 'Apoi'),
  ('Apac', 'Atik'),
  ('Apac', 'Chegere'),
  ('Apac', 'Ibuje'),
  ('Apac', 'Nambieso'),
  ('Apac', 'Ngai'),
  ('Dokolo', 'Adok'),
  ('Dokolo', 'Agwata'),
  ('Dokolo', 'Amwoma'),
  ('Dokolo', 'Bata'),
  ('Dokolo', 'Dokolo Town Council'),
  ('Dokolo', 'Kangai'),
  ('Dokolo', 'Okwongodul'),
  ('Dokolo', 'Kwera'),
  ('Kole', 'Aboke'),
  ('Kole', 'Alito'),
  ('Kole', 'Ayer'),
  ('Kole', 'Bala'),
  ('Kole', 'Kole Town Council'),
  ('Kole', 'Okwerodot'),
  ('Kwania', 'Abongomola'),
  ('Kwania', 'Aduku'),
  ('Kwania', 'Aduku Town Council'),
  ('Kwania', 'Atongtidi'),
  ('Kwania', 'Chawente'),
  ('Kwania', 'Inomo'),
  ('Kwania', 'Nambieso'),
  ('Lira', 'Adekokwok'),
  ('Lira', 'Agali'),
  ('Lira', 'Amach'),
  ('Lira', 'Aromo'),
  ('Lira', 'Barr'),
  ('Lira', 'Itek'),
  ('Lira', 'Lira City East Division'),
  ('Lira', 'Lira City West Division'),
  ('Lira', 'Ngetta'),
  ('Lira', 'Ogur'),
  ('Lira', 'Omito'),
  ('Otuke', 'Adwari'),
  ('Otuke', 'Ogwete'),
  ('Otuke', 'Olilim'),
  ('Otuke', 'Okwang'),
  ('Otuke', 'Orum'),
  ('Otuke', 'Otuke Town Council'),
  ('Oyam', 'Aber'),
  ('Oyam', 'Acaba'),
  ('Oyam', 'Aleka'),
  ('Oyam', 'Iceme'),
  ('Oyam', 'Loro'),
  ('Oyam', 'Minakulu'),
  ('Oyam', 'Myene'),
  ('Oyam', 'Ngai'),
  ('Oyam', 'Otwal'),
  ('Oyam', 'Oyam Town Council')
) AS subcounties(district_name, name)
JOIN public.districts ON districts.name = subcounties.district_name
ON CONFLICT (district_id, name) DO NOTHING;

INSERT INTO public.parishes (subcounty_id, name)
SELECT subcounties.id, 'Other'
FROM public.subcounties
ON CONFLICT (subcounty_id, name) DO NOTHING;

INSERT INTO public.categories (id, label_en, label_lg, icon_name, sort_order) VALUES
  ('produce', 'Crops and Produce', NULL, 'crops', 1),
  ('livestock', 'Livestock', NULL, 'livestock', 2),
  ('services', 'Services', NULL, 'service', 3),
  ('jobs', 'Jobs', NULL, 'job', 4),
  ('cooperatives', 'Cooperatives', NULL, 'coop', 5)
ON CONFLICT (id) DO UPDATE SET
  label_en = EXCLUDED.label_en,
  icon_name = EXCLUDED.icon_name,
  sort_order = EXCLUDED.sort_order,
  is_active = true;

INSERT INTO public.app_settings (key, value, description, is_public) VALUES
  ('app_name', '"Buy From Lango"'::jsonb, 'Application display name', true),
  ('currency', '"UGX"'::jsonb, 'Currency used for marketplace prices', true),
  ('country_code', '"UG"'::jsonb, 'ISO country code for the service area', true),
  ('allow_anonymous_listings', 'true'::jsonb, 'Allow sellers to hide their name on listings', true),
  ('max_listing_images', '6'::jsonb, 'Maximum number of images per listing', true),
  ('listing_fee_ugx', '0'::jsonb, 'Base listing fee in Ugandan shillings', true)
ON CONFLICT (key) DO UPDATE SET
  value = EXCLUDED.value,
  description = EXCLUDED.description,
  is_public = EXCLUDED.is_public,
  updated_at = now();

INSERT INTO public.banners (title, image_url, cta_route, sort_order, is_active) VALUES
  (
    'Buy and sell across Lango',
    'https://images.unsplash.com/photo-1500382017468-9049fed747ef?auto=format&fit=crop&w=1200&q=80',
    '/search',
    1,
    true
  ),
  (
    'Find fresh local produce',
    'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1200&q=80',
    '/search?category=produce',
    2,
    true
  ),
  (
    'Connect with local livestock sellers',
    'https://images.unsplash.com/photo-1516467508483-a7212febe31a?auto=format&fit=crop&w=1200&q=80',
    '/search?category=livestock',
    3,
    true
  );
