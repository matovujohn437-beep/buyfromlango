ALTER TABLE public.market_prices
  ADD COLUMN farm_gate_price_ugx numeric(14, 2)
    CHECK (farm_gate_price_ugx IS NULL OR farm_gate_price_ugx >= 0);
