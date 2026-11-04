ALTER TABLE public.market_prices
  ADD COLUMN price_per_kg_ugx numeric(14, 2)
    CHECK (price_per_kg_ugx IS NULL OR price_per_kg_ugx >= 0);
