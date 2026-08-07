-- =============================================================
-- NutriOliva — Migración 004: Catálogo base de alimentos
-- Aplica un catálogo global disponible para todos los nutricionistas
-- (nutricionista_id = NULL → global)
-- =============================================================

INSERT INTO catalogo_alimentos
  (id, nutricionista_id, nombre, calorias_por_unidad, unidad, proteinas_g, carbos_g, grasas_g)
VALUES
  -- Cereales y derivados
  (gen_random_uuid(), NULL, 'Avena',               68,  '100g',   2.4,  12.0, 1.4),
  (gen_random_uuid(), NULL, 'Pan integral',        247, '100g',   8.0,  41.0, 3.4),
  (gen_random_uuid(), NULL, 'Pan blanco',          265, '100g',   8.5,  50.0, 2.7),
  (gen_random_uuid(), NULL, 'Arroz cocido',        130, '100g',   2.7,  28.0, 0.3),
  (gen_random_uuid(), NULL, 'Pasta cocida',        131, '100g',   5.0,  25.0, 1.1),
  -- Proteínas
  (gen_random_uuid(), NULL, 'Pollo grillado',      165, '100g',  31.0,   0.0, 3.6),
  (gen_random_uuid(), NULL, 'Pechuga de pavo',     135, '100g',  29.0,   0.0, 1.0),
  (gen_random_uuid(), NULL, 'Carne vacuna magra',  218, '100g',  26.0,   0.0,12.0),
  (gen_random_uuid(), NULL, 'Salmón',              208, '100g',  20.0,   0.0,13.0),
  (gen_random_uuid(), NULL, 'Huevo',                78, 'unidad', 6.0,   0.6, 5.0),
  (gen_random_uuid(), NULL, 'Atún en agua',        116, '100g',  26.0,   0.0, 0.5),
  -- Lácteos
  (gen_random_uuid(), NULL, 'Yogur natural',        59, '100ml',  3.5,   4.7, 3.3),
  (gen_random_uuid(), NULL, 'Yogur descremado',     56, '100ml',  5.7,   8.0, 0.1),
  (gen_random_uuid(), NULL, 'Leche descremada',     35, '100ml',  3.4,   5.0, 0.1),
  (gen_random_uuid(), NULL, 'Queso cottage',       110, '100g',  11.0,   3.0, 5.0),
  -- Frutas
  (gen_random_uuid(), NULL, 'Banana',               89, 'unidad', 1.1,  23.0, 0.3),
  (gen_random_uuid(), NULL, 'Manzana',              52, 'unidad', 0.3,  14.0, 0.2),
  (gen_random_uuid(), NULL, 'Naranja',              47, 'unidad', 0.9,  12.0, 0.1),
  (gen_random_uuid(), NULL, 'Pera',                 57, 'unidad', 0.4,  15.0, 0.1),
  (gen_random_uuid(), NULL, 'Frutilla',             32, '100g',   0.7,   7.7, 0.3),
  (gen_random_uuid(), NULL, 'Arándano',             57, '100g',   0.7,  14.5, 0.3),
  -- Verduras
  (gen_random_uuid(), NULL, 'Brócoli',              34, '100g',   2.8,   7.0, 0.4),
  (gen_random_uuid(), NULL, 'Espinaca',             23, '100g',   2.9,   3.6, 0.4),
  (gen_random_uuid(), NULL, 'Zanahoria',            41, '100g',   0.9,  10.0, 0.2),
  (gen_random_uuid(), NULL, 'Tomate',               18, '100g',   0.9,   3.9, 0.2),
  (gen_random_uuid(), NULL, 'Lechuga',              15, '100g',   1.4,   2.9, 0.2),
  (gen_random_uuid(), NULL, 'Papa hervida',         87, '100g',   1.9,  20.0, 0.1),
  (gen_random_uuid(), NULL, 'Batata hervida',       90, '100g',   2.0,  21.0, 0.1),
  -- Legumbres
  (gen_random_uuid(), NULL, 'Lentejas cocidas',    116, '100g',   9.0,  20.0, 0.4),
  (gen_random_uuid(), NULL, 'Garbanzos cocidos',   164, '100g',   8.9,  27.0, 2.6),
  (gen_random_uuid(), NULL, 'Porotos negros',      132, '100g',   8.9,  24.0, 0.5),
  -- Grasas saludables
  (gen_random_uuid(), NULL, 'Palta',               160, '100g',   2.0,   9.0,15.0),
  (gen_random_uuid(), NULL, 'Almendras',           579, '100g',  21.0,  22.0,50.0),
  (gen_random_uuid(), NULL, 'Nueces',              654, '100g',  15.0,  14.0,65.0),
  (gen_random_uuid(), NULL, 'Aceite de oliva',     884, '100ml',  0.0,   0.0,100.0);
