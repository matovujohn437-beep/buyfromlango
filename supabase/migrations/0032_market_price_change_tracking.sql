CREATE OR REPLACE FUNCTION public.calculate_market_price_change()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    NEW.price_change_percent := 0;
    RETURN NEW;
  END IF;

  IF NEW.price_per_kg_ugx IS NULL
    OR OLD.price_per_kg_ugx IS NULL
    OR OLD.price_per_kg_ugx <= 0 THEN
    NEW.price_change_percent := 0;
  ELSE
    NEW.price_change_percent := round(
      ((NEW.price_per_kg_ugx - OLD.price_per_kg_ugx)
        / OLD.price_per_kg_ugx) * 100,
      2
    );
  END IF;

  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS market_prices_track_price_change
  ON public.market_prices;

CREATE TRIGGER market_prices_track_price_change
  BEFORE INSERT OR UPDATE OF price_per_kg_ugx
  ON public.market_prices
  FOR EACH ROW
  EXECUTE FUNCTION public.calculate_market_price_change();