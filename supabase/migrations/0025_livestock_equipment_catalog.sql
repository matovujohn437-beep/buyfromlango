BEGIN;

INSERT INTO public.catalog_items (category_id, name, sort_order, is_active)
VALUES
  ('livestock', 'Beef', 11, true),
  ('livestock', 'Pork', 12, true),
  ('equipment', 'Tractor', 2, true),
  ('equipment', 'Water Pump', 3, true),
  ('equipment', 'Sprayer', 4, true)
ON CONFLICT (category_id, name) DO UPDATE
SET sort_order = EXCLUDED.sort_order,
    is_active = true;

UPDATE public.catalog_items
SET is_active = false
WHERE category_id = 'equipment'
  AND name IN ('Tractors', 'Sprayers');

UPDATE public.item_units AS unit
SET is_active = false
FROM public.catalog_items AS item
WHERE unit.item_id = item.id
  AND item.category_id IN ('livestock', 'equipment');

WITH unit_seed (category_id, item_name, unit_name, sort_order) AS (
  VALUES
    ('livestock', 'Cattle', 'head', 1),
    ('livestock', 'Cattle', 'herd', 2),
    ('livestock', 'Goats', 'head', 1),
    ('livestock', 'Goats', 'herd', 2),
    ('livestock', 'Sheep', 'head', 1),
    ('livestock', 'Sheep', 'flock', 2),
    ('livestock', 'Pigs', 'head', 1),
    ('livestock', 'Chicken', 'head', 1),
    ('livestock', 'Chicken', 'flock', 2),
    ('livestock', 'Ducks', 'head', 1),
    ('livestock', 'Ducks', 'flock', 2),
    ('livestock', 'Turkeys', 'head', 1),
    ('livestock', 'Turkeys', 'flock', 2),
    ('livestock', 'Eggs', 'Trays', 1),
    ('livestock', 'Milk', 'Litres', 1),
    ('livestock', 'Beef', 'Kilograms', 1),
    ('livestock', 'Pork', 'Kilograms', 1),
    ('livestock', 'Fish', 'Kilograms', 1),
    ('equipment', 'Tractor', 'Per Day', 1),
    ('equipment', 'Tractor', 'Per Hour', 2),
    ('equipment', 'Tractor', 'For Sale', 3),
    ('equipment', 'Water Pump', 'Per Day', 1),
    ('equipment', 'Water Pump', 'Per Hour', 2),
    ('equipment', 'Water Pump', 'For Sale', 3),
    ('equipment', 'Sprayer', 'Per Day', 1),
    ('equipment', 'Sprayer', 'Per Hour', 2),
    ('equipment', 'Sprayer', 'For Sale', 3),
    ('equipment', 'Hoes', 'For Sale', 1),
    ('equipment', 'Mills', 'For Sale', 1),
    ('equipment', 'Irrigation equipment', 'For Sale', 1)
)
INSERT INTO public.item_units (item_id, unit_name, sort_order, is_active)
SELECT item.id, unit.unit_name, unit.sort_order, true
FROM unit_seed AS unit
JOIN public.catalog_items AS item
  ON item.category_id = unit.category_id
 AND item.name = unit.item_name
WHERE item.is_active
ON CONFLICT (item_id, unit_name) DO UPDATE
SET sort_order = EXCLUDED.sort_order,
    is_active = true;

COMMIT;
