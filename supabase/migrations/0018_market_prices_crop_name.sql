DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'market_prices'
      AND column_name = 'item_name'
  ) AND NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'market_prices'
      AND column_name = 'crop_name'
  ) THEN
    ALTER TABLE public.market_prices RENAME COLUMN item_name TO crop_name;
  END IF;
END;
$$;
