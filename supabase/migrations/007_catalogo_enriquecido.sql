-- ============================================================
-- Migración 007 — Catálogo enriquecido con 80 comidas completas
-- NutriOliva — 2026
-- ============================================================

-- ── 1. Agregar columnas nuevas a catalogo_alimentos ─────────────────────────

ALTER TABLE catalogo_alimentos
  ADD COLUMN IF NOT EXISTS tipo_comida          TEXT,
  ADD COLUMN IF NOT EXISTS objetivo_ideal       TEXT,
  ADD COLUMN IF NOT EXISTS perfil_paciente      TEXT,
  ADD COLUMN IF NOT EXISTS descripcion_completa TEXT,
  ADD COLUMN IF NOT EXISTS es_comida_completa   BOOLEAN NOT NULL DEFAULT FALSE;

-- Índice para búsquedas por tipo de comida
CREATE INDEX IF NOT EXISTS idx_catalogo_tipo_comida
  ON catalogo_alimentos (tipo_comida);

-- ── 2. Política RLS: paciente puede leer el catálogo ────────────────────────
-- (puede estar del nutricionista asignado o ser global: nutricionista_id IS NULL)

DROP POLICY IF EXISTS "paciente_lee_catalogo" ON catalogo_alimentos;
CREATE POLICY "paciente_lee_catalogo"
  ON catalogo_alimentos FOR SELECT
  USING (
    nutricionista_id IS NULL
    OR nutricionista_id IN (
      SELECT nutricionista_id FROM pacientes WHERE auth_user_id = auth.uid()
    )
    OR nutricionista_id = get_nutricionista_id()
  );

-- Política INSERT para nutricionista (guardar comidas nuevas al catálogo)
DROP POLICY IF EXISTS "nutricionista_inserta_catalogo" ON catalogo_alimentos;
CREATE POLICY "nutricionista_inserta_catalogo"
  ON catalogo_alimentos FOR INSERT
  WITH CHECK (nutricionista_id = get_nutricionista_id());

-- ── 3. Seed: 80 comidas completas por categoría ─────────────────────────────
-- Fuente: Guia_Nutricional_Ampliada.md
-- Las macros son estimaciones nutricionales estándar por preparación.

INSERT INTO catalogo_alimentos (
  nombre, calorias_por_unidad, unidad,
  proteinas_g, carbos_g, grasas_g,
  tipo_comida, objetivo_ideal, perfil_paciente,
  descripcion_completa, es_comida_completa,
  nutricionista_id
) VALUES

-- ── DESAYUNOS ──────────────────────────────────────────────────────────────
('2 Huevos revueltos + pan integral + Té sin azúcar',
  220, 'porcion', 16, 18, 7,
  'desayuno', 'Bajar de peso', 'Sedentario / Actividad Ligera',
  '2 huevos revueltos, 1 rebanada de pan integral, té o café sin azúcar', TRUE, NULL),

('Yogur descremado + frutos rojos + semillas de chia',
  180, 'porcion', 10, 22, 4,
  'desayuno', 'Bajar de peso', 'Paciente con ansiedad dulce',
  '1 yogur descremado, 150g de frutos rojos, 1 cucharada de semillas de chía', TRUE, NULL),

('Batido verde (espinaca, manzana, pepino, proteína)',
  160, 'vaso', 20, 14, 2,
  'desayuno', 'Bajar de peso', 'Definición extrema / Rápida absorción',
  'Espinaca, manzana, pepino, 1 scoop de proteína whey, agua', TRUE, NULL),

('Tofu revuelto con cúrcuma + espinaca + pan integral',
  280, 'porcion', 18, 22, 10,
  'desayuno', 'Mantenimiento', 'Vegetariano / Bajar peso',
  '150g de tofu revuelto con cúrcuma, espinaca salteada, 1 pan integral', TRUE, NULL),

('Avena con leche descremada + manzana + canela',
  310, 'bowl', 12, 52, 5,
  'desayuno', 'Mantenimiento', 'Runner / Fitness general',
  '50g de avena, 200ml de leche descremada, 1 manzana, canela al gusto', TRUE, NULL),

('Waffles de avena y clara + queso crema light + fruta',
  320, 'porcion', 18, 34, 9,
  'desayuno', 'Mantenimiento', 'Estética / Fitness',
  '2 waffles de avena y clara de huevo, 50g de queso crema light, fruta a elección', TRUE, NULL),

('Tostadas integrales + palta + huevo pochado + café',
  350, 'porcion', 16, 28, 18,
  'desayuno', 'Mantenimiento', 'Actividad Moderada',
  '2 tostadas integrales, 50g de palta, 1 huevo pochado, café sin azúcar', TRUE, NULL),

('Arroz blanco con huevos fritos (aceite de coco)',
  600, 'porcion', 24, 62, 22,
  'desayuno', 'Aumento de fuerza', 'Fuerza Estricta / Strongman',
  '150g de arroz blanco cocido, 3 huevos fritos en aceite de coco', TRUE, NULL),

('Panqueques de avena con miel y proteína whey',
  780, 'porcion', 42, 88, 16,
  'desayuno', 'Deportistas', 'Natación / Rugby',
  '4 panqueques (100g avena, 2 huevos, 1 banana), 30g de miel, 1 scoop proteína', TRUE, NULL),

('Desayuno hipercalórico: avena + leche + huevos + maní',
  850, 'porcion', 48, 80, 30,
  'desayuno', 'Aumento de peso', 'Powerlifter / Hipertrofia',
  '3 huevos, 100g de avena, 300ml de leche entera, 30g de maní, 1 banana', TRUE, NULL),

-- ── COLACIONES (media mañana/tarde) ────────────────────────────────────────
('Gelatina light + té verde',
  10, 'porcion', 1, 1, 0,
  'colacion', 'Bajar de peso', 'Fase final de corte / Ansiedad',
  '1 gelatina light, 1 taza de té verde o negro sin azúcar', TRUE, NULL),

('Manzana verde o pera',
  80, 'unidad', 0, 20, 0,
  'colacion', 'Bajar de peso', 'Cualquier paciente',
  '1 manzana verde (150g) o 1 pera, fibra y agua', TRUE, NULL),

('Rollitos de lomito y queso light',
  120, 'porcion', 14, 2, 6,
  'colacion', 'Bajar de peso', 'Keto / Low-Carb',
  '3 rollitos de lomito ahumado con queso en hebras light, sin carbohidratos', TRUE, NULL),

('2 Huevos duros',
  140, 'porcion', 12, 1, 10,
  'colacion', 'Mantenimiento / Fuerza', 'Fitness general',
  '2 huevos duros, proteína de alto valor biológico', TRUE, NULL),

('Yogur griego natural + almendras',
  180, 'porcion', 14, 10, 10,
  'colacion', 'Bajar / Mantener', 'Oficinista / Estética',
  '150g de yogur griego natural, 15g de almendras, caseína y grasas saludables', TRUE, NULL),

('Garbanzos tostados con pimentón',
  190, 'porcion', 9, 28, 4,
  'colacion', 'Mantenimiento', 'Vegano / Actividad Moderada',
  '50g de garbanzos tostados al horno con pimentón, carbohidratos lentos y fibra', TRUE, NULL),

('Barrita proteica casera (avena, pasta de maní, proteína)',
  220, 'barra', 18, 20, 8,
  'colacion', 'Deportistas', 'Jugadores de voley / Tenis',
  'Avena, pasta de maní y proteína whey compactados, energía compacta', TRUE, NULL),

('Pan con mermelada y queso magro',
  280, 'porcion', 12, 40, 6,
  'colacion', 'Deportistas', 'Pre-entrenamiento fútbol/hockey',
  '2 rebanadas de pan, 40g de mermelada, 40g de queso magro, carbos de asimilación media', TRUE, NULL),

('Batido proteico con banana y nueces',
  400, 'vaso', 30, 32, 14,
  'colacion', 'Aumento / Fuerza', 'Hipertrofia',
  '1 scoop de proteína whey, 1 banana, 30g de nueces, agua, recuperación rápida', TRUE, NULL),

('Mix de frutos secos y pasas de uva',
  450, 'porcion', 10, 45, 26,
  'colacion', 'Aumento de peso', 'Ectomorfos / Hardgainers',
  '50g de mix de frutos secos, 50g de pasas de uva, alta densidad calórica', TRUE, NULL),

-- ── ALMUERZOS ──────────────────────────────────────────────────────────────
('Merluza con ensalada verde (sin aceite)',
  180, 'porcion', 28, 6, 2,
  'almuerzo', 'Bajar de peso', 'Corte agresivo de grasa',
  '150g de merluza, ensalada verde grande sin aceite, proteína magra pura', TRUE, NULL),

('Calamares a la plancha + rúcula y tomate',
  200, 'porcion', 30, 8, 4,
  'almuerzo', 'Bajar de peso', 'Fitness en déficit estricto',
  '200g de calamares a la plancha, rúcula y tomate fresco, altísima proteína', TRUE, NULL),

('Pechuga a la plancha + brócoli y zanahoria',
  260, 'porcion', 40, 10, 4,
  'almuerzo', 'Bajar de peso', 'Sedentario',
  '150g de pechuga de pollo, 250g de brócoli y zanahoria, 5ml de aceite', TRUE, NULL),

('Ensalada César light con pechuga',
  350, 'porcion', 38, 18, 12,
  'almuerzo', 'Bajar de peso', 'Paciente en transición',
  '150g de pechuga, lechuga, 30g de crutones, aderezo de yogur', TRUE, NULL),

('Milanesas de soja al horno + ensalada',
  380, 'porcion', 26, 30, 14,
  'almuerzo', 'Mantenimiento', 'Vegano en bajar peso',
  '2 milanesas de soja al horno, ensalada de tomate y zanahoria', TRUE, NULL),

('Seitán a la plancha + papa al horno',
  380, 'porcion', 30, 32, 10,
  'almuerzo', 'Mantenimiento', 'Vegano / Atleta',
  '150g de seitán, 200g de papa al horno, proteína de gluten y carbo complejo', TRUE, NULL),

('Atún + fideos integrales + tomate',
  390, 'porcion', 32, 42, 6,
  'almuerzo', 'Mantenimiento', 'Actividad General',
  '150g de atún natural, 150g de fideos integrales cocidos, tomate', TRUE, NULL),

('Pechuga + papa hervida + calabaza al horno',
  420, 'porcion', 42, 32, 6,
  'almuerzo', 'Deportistas', 'Fútbol / Hockey',
  '200g de pechuga, 150g de papa hervida, 150g de calabaza, energía sostenida', TRUE, NULL),

('Pizza proteica con base de pollo',
  450, 'porcion', 40, 20, 18,
  'almuerzo', 'Mantenimiento', 'Keto / Definición',
  'Base de pollo licuado, salsa de tomate, queso light, sin harinas', TRUE, NULL),

('Tofu firme + quinoa + vegetales salteados',
  480, 'porcion', 28, 44, 14,
  'almuerzo', 'Mantenimiento', 'Vegetariano',
  '150g de tofu firme, 150g de quinoa cocida, vegetales de estación salteados', TRUE, NULL),

('Guiso de lentejas con carne magra',
  500, 'porcion', 38, 44, 10,
  'almuerzo', 'Mantenimiento', 'Runner / Actividad Moderada',
  '200g de lentejas cocidas, 100g de carne magra, vegetales, hierro y fibra', TRUE, NULL),

('Lomo de ternera + arroz integral + ensalada',
  550, 'porcion', 46, 36, 14,
  'almuerzo', 'Deportistas', 'Voley / Mantenimiento',
  '200g de lomo de ternera, 100g de arroz integral cocido, ensalada, hierro hemo', TRUE, NULL),

('Wok de cerdo magro con fideos de arroz',
  550, 'porcion', 40, 50, 14,
  'almuerzo', 'Deportistas', 'Nadadores (carga media)',
  '150g de cerdo magro, 100g de fideos de arroz cocidos, carbohidrato rápido', TRUE, NULL),

('3 Wraps integrales con pollo, palta y queso',
  750, 'porcion', 52, 60, 24,
  'almuerzo', 'Aumento de peso', 'Rugby (día de entrenamiento)',
  '3 wraps integrales, 200g de pollo, palta, queso, tomate, gran volumen limpio', TRUE, NULL),

('Omelette 4 huevos + queso + arroz blanco',
  800, 'porcion', 46, 62, 28,
  'almuerzo', 'Aumento de peso', 'Ganancia de masa magra',
  '4 huevos, 100g de queso, 200g de arroz blanco, digestión rápida', TRUE, NULL),

('Bife de chorizo + puré de papas con manteca',
  950, 'porcion', 62, 60, 36,
  'almuerzo', 'Aumento de peso', 'Ectomorfos',
  '250g de bife de chorizo, 200g de puré de papas con manteca', TRUE, NULL),

('Ojo de bife + papas airfryer + huevos fritos',
  1050, 'porcion', 72, 50, 46,
  'almuerzo', 'Aumento de fuerza', 'Strongman / Levantamiento',
  '250g de ojo de bife, 200g de papas airfryer, 2 huevos fritos', TRUE, NULL),

('Fideos con carne picada magra y queso',
  1100, 'porcion', 60, 100, 30,
  'almuerzo', 'Aumento de fuerza', 'Powerlifter',
  '200g de fideos (crudos), 200g de carne picada magra, salsa de tomate, queso', TRUE, NULL),

('Boloñesa XL: fideos + carne + salsa + queso',
  1200, 'porcion', 70, 120, 34,
  'almuerzo', 'Volumen sucio', 'Hardgainer Extremo',
  '250g de carne picada, 300g de fideos, salsa boloñesa completa, queso rallado', TRUE, NULL),

('2 Hamburguesas dobles caseras + pan + panceta',
  1350, 'porcion', 80, 80, 60,
  'almuerzo', 'Volumen sucio', 'Atleta Pesado (Rugby Pilar)',
  '2 hamburguesas caseras (300g de carne), pan de hamburguesa, panceta', TRUE, NULL),

-- ── MERIENDAS ──────────────────────────────────────────────────────────────
('Galletas de arroz con queso untable light',
  110, 'porcion', 6, 14, 3,
  'merienda', 'Bajar de peso', 'Sedentario / Oficinista',
  'Infusión, 2 galletas de arroz, 30g de queso untable light, snack ligero', TRUE, NULL),

('Lata de atún al natural + rodajas de tomate',
  130, 'porcion', 24, 4, 2,
  'merienda', 'Bajar peso / Fuerza', 'Definición muscular',
  '1 lata de atún al natural, tomate en rodajas, proteína pura sin carbos', TRUE, NULL),

('Pudding de chía con leche de almendras y frutillas',
  150, 'vaso', 6, 16, 6,
  'merienda', 'Bajar de peso', 'Vegano / Ansiedad',
  '20g de chía, 100ml de leche de almendras, frutillas, omega 3 y fibra', TRUE, NULL),

('Tostadas francesas integrales con sirope sin azúcar',
  280, 'porcion', 14, 36, 8,
  'merienda', 'Mantenimiento', 'Fitness',
  '3 tostadas francesas de pan integral con huevo y stevia, sirope zero', TRUE, NULL),

('Tostadas con jamón cocido y queso',
  290, 'porcion', 18, 28, 10,
  'merienda', 'Mantenimiento', 'Actividad general',
  '2 tostadas integrales, 2 fetas de jamón cocido, 2 fetas de queso', TRUE, NULL),

('Arepas de maíz con queso blanco light',
  300, 'porcion', 14, 38, 8,
  'merienda', 'Mantenimiento', 'Carga glucémica suave / Sin TACC',
  '2 arepas de maíz chicas, 50g de queso blanco light', TRUE, NULL),

('Omelette con queso cremoso y jamón',
  410, 'porcion', 30, 4, 30,
  'merienda', 'Aumento de fuerza', 'Dieta alta en proteína',
  '3 huevos, 50g de queso cremoso, jamón cocido, grasas y proteínas', TRUE, NULL),

('Bowl de cereales con leche entera',
  450, 'bowl', 12, 72, 12,
  'merienda', 'Deportistas', 'Nadadores post-entrenamiento',
  '80g de cereales, 200ml de leche entera, reposición rápida de glucógeno', TRUE, NULL),

('Bowl de açaí con granola, banana y miel',
  450, 'bowl', 10, 72, 14,
  'merienda', 'Deportistas', 'Rugby / Triatlón',
  'Bowl de açaí, 50g de granola, banana, miel, antioxidantes y carbos mixtos', TRUE, NULL),

('Licuado hipercalórico: leche + bananas + avena + maní',
  750, 'vaso', 26, 88, 26,
  'merienda', 'Aumento de peso', 'Volumen limpio',
  '500ml de leche entera, 2 bananas, 50g de avena, 30g de mantequilla de maní', TRUE, NULL),

-- ── CENAS ──────────────────────────────────────────────────────────────────
('Sopa crema de calabaza casera + huevo picado',
  180, 'porcion', 10, 22, 6,
  'cena', 'Bajar de peso', 'Ansiedad nocturna',
  'Sopa crema de calabaza sin crema de leche, 1 huevo duro picado encima', TRUE, NULL),

('Tortilla de zapallitos al horno',
  200, 'porcion', 14, 8, 12,
  'cena', 'Bajar de peso', 'Sedentario',
  '2 huevos, 2 zapallitos, tortilla al horno, baja densidad calórica', TRUE, NULL),

('Filet de merluza + espárragos a la plancha',
  210, 'porcion', 32, 6, 4,
  'cena', 'Bajar de peso', 'Corte extremo de grasa',
  '200g de filet de merluza, espárragos a la plancha, limón, digestión ultra ligera', TRUE, NULL),

('Pescado blanco al papillot + brócoli al vapor',
  220, 'porcion', 34, 6, 4,
  'cena', 'Bajar de peso', 'Definición Fitness',
  '200g de pescado blanco al papillot, brócoli al vapor, cero grasas añadidas', TRUE, NULL),

('Pechuga cortada en wok con vegetales chinos',
  250, 'porcion', 38, 10, 4,
  'cena', 'Bajar de peso', 'Fitness en déficit',
  '150g de pechuga, wok de vegetales chinos sin fideos, alto volumen estomacal', TRUE, NULL),

('Lentejas cocidas con espinaca y tomate',
  250, 'porcion', 16, 32, 2,
  'cena', 'Bajar de peso', 'Cena ligera vegana',
  '200g de lentejas cocidas, espinaca, tomate fresco, hierro y digestión media', TRUE, NULL),

('Pavo a la plancha + coliflor gratinada con queso light',
  300, 'porcion', 38, 10, 10,
  'cena', 'Bajar peso / Mantener', 'Low Carb',
  '150g de pavo, 150g de coliflor gratinada con queso light, carbos mínimos', TRUE, NULL),

('Hamburguesas de soja + ensalada mixta',
  350, 'porcion', 24, 24, 12,
  'cena', 'Mantenimiento', 'Vegano',
  '2 hamburguesas de soja al plato, ensalada mixta de estación', TRUE, NULL),

('Tarta de verdura y queso con masa integral',
  450, 'porcion', 20, 40, 18,
  'cena', 'Mantenimiento', 'Cena familiar estándar',
  '2 porciones de tarta de verdura y queso con masa integral, balanceado', TRUE, NULL),

('Risotto de champiñones con parmesano',
  480, 'porcion', 16, 70, 14,
  'cena', 'Mantenimiento', 'Carga glucémica moderada',
  '100g de arroz carnaroli, champiñones, parmesano, confort food', TRUE, NULL),

('3 Empanadas de carne al horno + ensalada verde',
  550, 'porcion', 28, 50, 22,
  'cena', 'Mantenimiento', 'Equilibrio social',
  '3 empanadas de carne al horno, ensalada verde, porciones controladas', TRUE, NULL),

('Salmón rosado + quinoa + palta',
  580, 'porcion', 42, 28, 28,
  'cena', 'Mantenimiento', 'Salud / Longevidad',
  '150g de salmón rosado, 100g de quinoa cocida, 50g de palta, omega 3 premium', TRUE, NULL),

('Pollo pata/muslo + arroz con arvejas',
  600, 'porcion', 46, 50, 16,
  'cena', 'Deportistas', 'Voley / Fútbol post-partido',
  '250g de pata/muslo de pollo sin piel, 200g de arroz con arvejas, recuperación', TRUE, NULL),

('3 Fajitas de carne con morrón y cebolla',
  650, 'porcion', 42, 52, 22,
  'cena', 'Aumento / Mantenimiento', 'Crossfit',
  '150g de tira de asado, morrón, cebolla, 3 tortillas, proteína hierro recarga', TRUE, NULL),

('Pollo asado + batata al horno + aceite de oliva',
  650, 'porcion', 44, 52, 18,
  'cena', 'Deportistas', 'Carga para partido siguiente',
  '250g de pollo asado, 300g de batata al horno, aceite de oliva', TRUE, NULL),

('Pizza napolitana casera + cerveza sin alcohol',
  700, 'porcion', 28, 80, 22,
  'cena', 'Volumen / Mantenimiento', 'Cheat Meal Controlado',
  '2 porciones de pizza napolitana casera, cerveza sin alcohol, relajo psicológico', TRUE, NULL),

('2 Hamburguesas de carne caseras al plato + puré',
  800, 'porcion', 52, 60, 34,
  'cena', 'Aumento de peso', 'Volumen general',
  '2 hamburguesas caseras (150g cada una) al plato, puré de papas', TRUE, NULL),

('Salmón + fideos de arroz + salsa teriyaki',
  900, 'porcion', 54, 72, 24,
  'cena', 'Aumento de peso', 'Hipertrofia Magra',
  '300g de salmón, 200g de fideos de arroz, salsa teriyaki, grasas limpias', TRUE, NULL),

('Pollo al spiedo con piel + papas al horno',
  1100, 'porcion', 72, 70, 44,
  'cena', 'Aumento de peso', 'Volumen Rugby',
  '400g de pollo al spiedo con piel, 300g de papas al horno, alta carga', TRUE, NULL),

('Bondiola de cerdo + arroz blanco + huevos fritos',
  1250, 'porcion', 76, 72, 60,
  'cena', 'Aumento de fuerza', 'Strongman / Halterofilia',
  '300g de bondiola de cerdo, 200g de arroz blanco, 2 huevos fritos, bomba calórica', TRUE, NULL),

-- ── COLACIONES NOCTURNAS ───────────────────────────────────────────────────
('Caldo de verduras + infusión relajante',
  15, 'porcion', 1, 2, 0,
  'colacion_nocturna', 'Bajar de peso', 'Ansiedad nocturna extrema',
  '1 taza de caldo de verduras dietético, infusión de tilo o valeriana', TRUE, NULL),

('2 Claras de huevo cocidas',
  35, 'porcion', 8, 0, 0,
  'colacion_nocturna', 'Bajar de peso', 'Atleta en corte final',
  '2 claras de huevo cocidas, proteína pura de albúmina', TRUE, NULL),

('Leche dorada con cúrcuma',
  60, 'vaso', 4, 8, 1,
  'colacion_nocturna', 'Bajar de peso', 'Recuperación / Antiinflamatorio',
  'Medio vaso de leche descremada con cúrcuma, inductor del sueño', TRUE, NULL),

('Té de manzanilla con almendras',
  75, 'porcion', 2, 2, 6,
  'colacion_nocturna', 'Bajar / Mantener', 'Keto / Control hormonal',
  '1 té de manzanilla, 10 almendras, grasas para control hormonal nocturno', TRUE, NULL),

('Queso cottage o ricota magra',
  90, 'porcion', 12, 4, 2,
  'colacion_nocturna', 'Mantenimiento', 'Fitness general',
  '100g de queso cottage o ricota magra, caseína de liberación lenta', TRUE, NULL),

('Kéfir de leche',
  100, 'vaso', 6, 12, 2,
  'colacion_nocturna', 'Mantenimiento', 'Salud digestiva',
  '1 vaso de kéfir de leche, probióticos vivos para microbiota', TRUE, NULL),

('Proteína de caseína en agua',
  110, 'vaso', 24, 4, 1,
  'colacion_nocturna', 'Aumento / Fuerza', 'Culturistas',
  '1 scoop de proteína de caseína en agua, anti-catabólico nocturno estricto', TRUE, NULL),

('Chocolate amargo 80% cacao',
  120, 'porcion', 2, 10, 8,
  'colacion_nocturna', 'Mantener / Salud', 'Paciente con antojos',
  '20g de chocolate amargo mayor 80% cacao, polifenoles y control de estrés', TRUE, NULL),

('Yogur entero con nueces y miel',
  400, 'porcion', 16, 36, 20,
  'colacion_nocturna', 'Aumento de peso', 'Hardgainers',
  '200g de yogur entero, 30g de nueces, 1 cucharada de miel, digestión media', TRUE, NULL),

('Batido gainer nocturno: avena + leche + proteína + maní',
  650, 'vaso', 40, 68, 22,
  'colacion_nocturna', 'Aumento de fuerza', 'Ectomorfo extremo',
  '50g de avena, 250ml de leche entera, 1 scoop de proteína, 30g de maní', TRUE, NULL)

ON CONFLICT DO NOTHING;
