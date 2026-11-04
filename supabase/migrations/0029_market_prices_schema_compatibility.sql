DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'market_prices'
      AND column_name = 'crop_type'
  ) AND NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'market_prices'
      AND column_name = 'crop_name'
  ) THEN
    ALTER TABLE public.market_prices RENAME COLUMN crop_type TO crop_name;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'market_prices'
      AND column_name = 'wholesale_price_ugx'
  ) THEN
    ALTER TABLE public.market_prices
      ADD COLUMN wholesale_price_ugx numeric(14, 2)
        CHECK (wholesale_price_ugx IS NULL OR wholesale_price_ugx >= 0);
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'market_prices'
      AND column_name = 'retail_price_ugx'
  ) THEN
    ALTER TABLE public.market_prices
      ADD COLUMN retail_price_ugx numeric(14, 2)
        CHECK (retail_price_ugx IS NULL OR retail_price_ugx >= 0);
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'market_prices'
      AND column_name = 'price_change_percent'
  ) THEN
    ALTER TABLE public.market_prices
      ADD COLUMN price_change_percent numeric(8, 2) NOT NULL DEFAULT 0;
  END IF;
END;
$$;
