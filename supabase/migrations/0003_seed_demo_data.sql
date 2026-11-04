WITH demo_listings (
  category_id,
  title,
  description,
  price_ugx,
  quantity,
  image_url
) AS (
  VALUES
    (
      'produce',
      'Premium White Maize',
      'Clean, well-dried white maize suitable for milling and household use.',
      1200,
      '10 Tons',
      'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?w=600'
    ),
    (
      'produce',
      'Fresh Cassava',
      'Freshly harvested cassava roots, ready for collection.',
      800,
      '5 Bags',
      'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?w=600'
    ),
    (
      'produce',
      'Soybeans (Non-GMO)',
      'Non-GMO soybeans, carefully sorted and ready for sale.',
      2500,
      '2 Tons',
      'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?w=600'
    ),
    (
      'livestock',
      'Boer Goats',
      'Healthy Boer goats raised on a local farm.',
      350000,
      '5 Goats',
      'https://images.unsplash.com/photo-1500595046743-cd271d694d30?w=600'
    ),
    (
      'livestock',
      'Local Chickens',
      'Hardy local chickens available for household or small-scale farming.',
      20000,
      '20 Birds',
      'https://images.unsplash.com/photo-1500595046743-cd271d694d30?w=600'
    ),
    (
      'services',
      'Tractor Hire',
      'Tractor hire for land preparation. Contact the seller to arrange a date.',
      80000,
      'Per Acre',
      'https://images.unsplash.com/photo-1521791136064-7986c2920216?w=600'
    ),
    (
      'jobs',
      'Farm Workers Needed',
      'Farm workers needed for general seasonal work. Daily pay.',
      15000,
      'Per Day',
      'https://images.unsplash.com/photo-1521737604893-d14cc237f11d?w=600'
    ),
    (
      'cooperatives',
      'Lango Farmers Co-op',
      'Join a local farmers cooperative to connect with growers and share resources.',
      0,
      'Membership',
      'https://images.unsplash.com/photo-1595278069441-2cf29f8005a4?w=600'
    )
),
inserted_listings AS (
  INSERT INTO public.listings (
    user_id,
    category_id,
    title,
    description,
    price_ugx,
    quantity,
    district_id,
    subcounty_id,
    parish_id
  )
  SELECT
    '6549904a-a231-4871-aec9-fdeb6e08dc2f'::uuid,
    category_id,
    title,
    description,
    price_ugx,
    quantity,
    1,
    1,
    1
  FROM demo_listings
  RETURNING id, title
)
INSERT INTO public.listing_media (listing_id, media_url, media_type, sort_order)
SELECT inserted_listings.id, demo_listings.image_url, 'image', 0
FROM inserted_listings
JOIN demo_listings USING (title);
