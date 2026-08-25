-- ============================================================
-- Migración 008 — Catálogo profesional ampliado
-- Correcciones + 90 comidas nuevas organizadas por objetivo
-- NutriOliva — 2026
-- ============================================================

-- ── 1. Corrección de entradas problemáticas de 007 ──────────────────────────

-- Corrección de terminología: "Vol. Sucio" → "Volumen hipercalórico"
UPDATE catalogo_alimentos SET objetivo_ideal = 'Volumen hipercalórico'
WHERE objetivo_ideal = 'Volumen sucio';

-- Corrección de "Pizza proteica con base de pollo" — la preparación es válida
-- pero estaba mal descrita. 450 kcal para keto/definición no es coherente.
-- La base de pollo molido es alta en proteína pero no "keto" si tiene salsa.
UPDATE catalogo_alimentos
SET
  descripcion_completa = 'Masa preparada con 200g de pechuga de pollo molida y 2 claras de huevo, condimentada con orégano. Salsa de tomate natural, mozzarella light. Sin harinas, alta en proteína.',
  objetivo_ideal       = 'Recomposicion corporal',
  perfil_paciente      = 'Fitness / Definicion muscular',
  calorias_por_unidad  = 380,
  proteinas_g          = 48,
  carbos_g             = 10,
  grasas_g             = 16
WHERE nombre = 'Pizza proteica con base de pollo';

-- Corrección macro: "Batido verde" (160 kcal, P:20 no cuadra con 160 kcal)
-- 20*4 + 14*4 + 2*9 = 80+56+18 = 154 ≈ 160 ✓ — OK, dejo.

-- Corrección: "3 Huevos + 100g Avena + 300ml Leche entera + 30g Maní + 1 Banana"
-- Calculemos: 3 huevos=216, 100g avena=389, 300ml leche entera=186, 30g maní=180, banana=105 = 1076
-- El catálogo decía 850. Corrijo.
UPDATE catalogo_alimentos
SET calorias_por_unidad = 1080, proteinas_g = 56, carbos_g = 98, grasas_g = 40
WHERE nombre LIKE '3 Huevos + 100g Avena + 300ml Leche entera%';

-- ── 2. NUEVO SEED: 90 comidas profesionales ampliadas ───────────────────────

INSERT INTO catalogo_alimentos (
  nombre, calorias_por_unidad, unidad,
  proteinas_g, carbos_g, grasas_g,
  tipo_comida, objetivo_ideal, perfil_paciente,
  descripcion_completa, es_comida_completa, nutricionista_id
) VALUES

-- ═══════════════════════════════════════════════════════════
-- DESAYUNOS (15 nuevos)
-- ═══════════════════════════════════════════════════════════

('Claras de huevo revueltas con espinaca y tomate',
  140, 'porcion', 20, 6, 3,
  'desayuno', 'Reduccion de peso', 'Sedentario / Oficinista',
  '4 claras de huevo revueltas con 100g de espinaca y tomate cherry. Cocinar en sartén antiadherente con spray vegetal.',
  TRUE, NULL),

('Yogur griego 0% con frutillas y stevia',
  130, 'porcion', 18, 14, 0,
  'desayuno', 'Reduccion de peso', 'Cualquier paciente',
  '200g de yogur griego 0% materia grasa, 100g de frutillas, stevia al gusto. Alto en proteína, índice glucémico bajo.',
  TRUE, NULL),

('Ricota magra con naranja y canela',
  210, 'porcion', 12, 20, 8,
  'desayuno', 'Reduccion de peso', 'Paciente con preferencia por lácteos',
  '150g de ricota descremada, 1 naranja en gajos, canela al gusto. Opción saciante y vitamínica.',
  TRUE, NULL),

('Avena con proteína de vainilla y cacao amargo',
  370, 'bowl', 34, 42, 7,
  'desayuno', 'Deportistas', 'Deportista de fuerza / Culturista',
  '60g de avena cocida, 1 scoop de proteína whey de vainilla, 1 cucharadita de cacao amargo puro. Carbohidratos de absorción lenta y proteína de alta calidad.',
  TRUE, NULL),

('Pan de salvado con queso cottage y pepino',
  260, 'porcion', 16, 26, 4,
  'desayuno', 'Mantenimiento', 'Paciente con control glucémico',
  '2 rebanadas de pan de salvado, 100g de queso cottage, rodajas de pepino y tomate. Alta fibra, bajo índice glucémico.',
  TRUE, NULL),

('Mate cocido con leche descremada + tostadas integrales light',
  170, 'porcion', 9, 26, 2,
  'desayuno', 'Reduccion de peso', 'Paciente argentino típico en déficit',
  'Mate cocido en 200ml de leche descremada, 2 tostadas de pan integral light sin manteca. Opción muy baja en calorías pero con calcio y fibra.',
  TRUE, NULL),

('Smoothie bowl: banana, espinaca, proteína y granola',
  400, 'bowl', 28, 52, 8,
  'desayuno', 'Deportistas', 'Atleta de resistencia / Triatlón',
  '1 banana, 50g espinaca, 1 scoop proteína whey, 40g granola artesanal sin azúcar. Antioxidantes, potasio y energía sostenida.',
  TRUE, NULL),

('Huevos revueltos con salmón ahumado + tostada integral',
  320, 'porcion', 26, 16, 16,
  'desayuno', 'Mantenimiento', 'Paciente adulto con enfoque en salud cardiovascular',
  '2 huevos, 50g de salmón ahumado, 1 tostada integral. Rico en omega-3, proteína completa y carbohidratos de calidad.',
  TRUE, NULL),

('Cereal de salvado con leche descremada y arándanos',
  210, 'bowl', 10, 34, 2,
  'desayuno', 'Reduccion de peso', 'Paciente con colesterol alto / Diabético tipo 2',
  '40g de cereal de salvado de avena, 200ml de leche descremada, 50g de arándanos frescos. Alto en fibra soluble, antiinflamatorio.',
  TRUE, NULL),

('Porridge overnight de avena con chía y leche',
  340, 'bowl', 14, 48, 8,
  'desayuno', 'Mantenimiento', 'Cualquier perfil / Practicidad matutina',
  '50g de avena, 15g de semillas de chía, 200ml de leche parcialmente descremada. Preparar la noche anterior. Rico en omega-3 vegetal y fibra.',
  TRUE, NULL),

('Muesli artesanal sin azúcar con yogur natural',
  330, 'bowl', 12, 46, 10,
  'desayuno', 'Mantenimiento', 'Paciente activo moderado',
  '60g de muesli sin azúcar añadida (avena, frutas secas, semillas), 150g de yogur natural entero. Equilibrado y saciante.',
  TRUE, NULL),

('Crepes de avena con ricota y banana',
  300, 'porcion', 16, 38, 8,
  'desayuno', 'Mantenimiento', 'Paciente joven / Fitness estética',
  '2 crepes (40g avena + 1 huevo + agua), rellenas con 80g de ricota y media banana. Saciante, equilibrado, sin azúcar añadida.',
  TRUE, NULL),

('Revuelto de huevo con queso, jamón y pimiento',
  390, 'porcion', 30, 8, 26,
  'desayuno', 'Recomposicion corporal', 'Paciente con alta demanda proteica matutina',
  '3 huevos enteros, 30g queso light, 30g jamón cocido magro, 100g pimiento salteado. Sin carbohidratos refinados, alto en proteína.',
  TRUE, NULL),

('Tortilla de claras con vegetales salteados',
  130, 'porcion', 14, 6, 4,
  'desayuno', 'Reduccion de peso', 'Fase de corte / Déficit estricto',
  '4 claras de huevo, 150g vegetales variados (cebolla, morrón, calabacín). Cocinar sin aceite con spray. Proteína pura, mínimas calorías.',
  TRUE, NULL),

('Medialunas de manteca con café (referencia social)',
  290, 'porcion', 6, 34, 14,
  'desayuno', 'Mantenimiento', 'Paciente en contexto social / Cheat meal controlado',
  '2 medialunas de manteca de panadería + café negro o con leche descremada. Incluir en el plan semanal como comida social controlada.',
  TRUE, NULL),

-- ═══════════════════════════════════════════════════════════
-- COLACIONES (15 nuevas)
-- ═══════════════════════════════════════════════════════════

('Pepinos y zanahorias con hummus casero',
  90, 'porcion', 4, 12, 3,
  'colacion', 'Reduccion de peso', 'Paciente con ansiedad alimentaria',
  '200g de pepino y zanahoria en bastones, 40g de hummus casero. Volumen grande, pocas calorías, fibra y saciedad.',
  TRUE, NULL),

('Manzana con mantequilla de almendra',
  200, 'porcion', 4, 28, 9,
  'colacion', 'Mantenimiento', 'Paciente con metabolismo acelerado',
  '1 manzana verde o roja, 1 cucharada (15g) de mantequilla de almendra sin sal ni azúcar. Fibra soluble y grasas monoinsaturadas.',
  TRUE, NULL),

('Copa de frutas mixtas con yogur griego light',
  140, 'porcion', 10, 18, 2,
  'colacion', 'Reduccion de peso', 'Paciente con preferencia por algo dulce',
  '150g de frutas de estación (fresa, kiwi, naranja), 100g yogur griego 0%. Vitaminas y proteína sin azúcar.',
  TRUE, NULL),

('Edamame al vapor con sal marina',
  120, 'porcion', 10, 8, 4,
  'colacion', 'Mantenimiento', 'Vegano / Vegetariano',
  '150g de edamame (soja tierna) al vapor. Proteína vegetal completa, fibra y potasio. Snack ideal para media tarde.',
  TRUE, NULL),

('Rollitos de pechuga de pavo con pepino y mostaza',
  80, 'porcion', 12, 2, 2,
  'colacion', 'Reduccion de peso', 'Fase de corte / Keto / Low-Carb',
  '3 fetas de pechuga de pavo ahumada, pepino en bastones, mostaza Dijon. Proteína pura, prácticamente sin carbohidratos.',
  TRUE, NULL),

('Palitos de apio con queso untable light',
  60, 'porcion', 4, 4, 2,
  'colacion', 'Reduccion de peso', 'Fase final de corte / Ansiedad',
  '3 ramas de apio con 30g de queso crema light. Casi sin calorías, alto en agua y saciedad mecánica.',
  TRUE, NULL),

('Cracker de arroz con hummus y pimiento asado',
  100, 'porcion', 4, 14, 3,
  'colacion', 'Reduccion de peso', 'Celiaco / Sin TACC',
  '2 crackers de arroz sin sal, 40g de hummus, pimiento asado en tiras. Sin gluten, bajo en calorías.',
  TRUE, NULL),

('Batido pre-entrenamiento: banana + avena + whey',
  350, 'vaso', 28, 42, 5,
  'colacion', 'Deportistas', 'Pre-entrenamiento cualquier deporte',
  '1 banana, 30g avena cruda, 1 scoop proteína whey, 200ml agua. Consumir 45-60 minutos antes del entrenamiento. Energía + proteína.',
  TRUE, NULL),

('Turrón de avena y maní sin azúcar (casero)',
  280, 'porcion', 10, 28, 14,
  'colacion', 'Aumento de peso', 'Paciente con dificultad para ganar masa',
  'Barra casera de avena, mantequilla de maní, miel y proteína prensada. Alta densidad energética en poco volumen. Ideal para hardgainers.',
  TRUE, NULL),

('Fiambre de pechuga de pavo + mozzarella light',
  160, 'porcion', 18, 1, 8,
  'colacion', 'Mantenimiento', 'Fitness / Post-entrenamiento ligero',
  '3 fetas pechuga de pavo, 1 feta mozzarella light. Sin carbohidratos, proteína y calcio. Práctico para llevar.',
  TRUE, NULL),

('Semillas de zapallo tostadas (sin sal)',
  180, 'porcion', 8, 6, 14,
  'colacion', 'Mantenimiento', 'Paciente con déficit de zinc y magnesio',
  '30g de semillas de zapallo tostadas sin aceite ni sal. Ricas en zinc, magnesio y grasas saludables. Antiinflamatorias.',
  TRUE, NULL),

('Batido de recuperación post-entreno: whey + leche + cacao',
  320, 'vaso', 36, 26, 6,
  'colacion', 'Deportistas', 'Post-entrenamiento de fuerza / Hipertrofia',
  '1 scoop proteína whey, 200ml leche descremada, 1 cucharadita cacao amargo. Tomar dentro de los 30 minutos post-entrenamiento.',
  TRUE, NULL),

('Gelatina sin azúcar con frutos rojos',
  30, 'porcion', 2, 4, 0,
  'colacion', 'Reduccion de peso', 'Paciente en déficit muy estricto / Ansiedad nocturna',
  'Gelatina dietética sabor frutos rojos, 50g de arándanos frescos. Saciedad psicológica y volumen sin calorías significativas.',
  TRUE, NULL),

('Mini ensalada de garbanzos con limón y páprika',
  190, 'porcion', 8, 26, 4,
  'colacion', 'Mantenimiento', 'Vegano / Vegetariano activo',
  '100g de garbanzos cocidos, jugo de limón, páprika ahumada, perejil fresco. Fibra, proteína vegetal y hierro no-hemo.',
  TRUE, NULL),

('Cuadradito de chocolate amargo 85% + nueces (10g)',
  160, 'porcion', 3, 10, 12,
  'colacion', 'Mantenimiento', 'Paciente con antojos nocturnos controlados',
  '20g chocolate amargo mínimo 85% cacao, 10g nueces. Control del cortisol, polifenoles y grasas antiinflamatorias.',
  TRUE, NULL),

-- ═══════════════════════════════════════════════════════════
-- ALMUERZOS (20 nuevos)
-- ═══════════════════════════════════════════════════════════

('Milanesa de ternera al horno con ensalada mixta',
  480, 'porcion', 42, 22, 18,
  'almuerzo', 'Mantenimiento', 'Cualquier paciente argentino / Sabor familiar',
  '200g de milanesa de peceto o nalga, empanado con pan rallado integral, al horno. Ensalada de lechuga, tomate, zanahoria. Reducción de grasa versus fritura: -40%.',
  TRUE, NULL),

('Pollo al limón con brócoli y zanahoria al vapor',
  270, 'porcion', 38, 10, 6,
  'almuerzo', 'Reduccion de peso', 'Sedentario / Paciente con síndrome metabólico',
  '200g de pechuga de pollo marinada en limón y ajo, a la plancha. 200g de brócoli y zanahoria al vapor. Bajo en grasa, muy alto en proteína.',
  TRUE, NULL),

('Sopa de pollo casera con fideos integrales',
  360, 'porcion', 28, 32, 8,
  'almuerzo', 'Mantenimiento', 'Convalecencia / Digestión delicada / Invierno',
  '150g pechuga de pollo desmenuzada, caldo casero desgrasado, 50g fideos integrales, zanahoria, apio, cebolla, puerro. Reconfortante y nutritiva.',
  TRUE, NULL),

('Zapallitos rellenos de carne magra y queso light',
  300, 'porcion', 30, 12, 12,
  'almuerzo', 'Reduccion de peso', 'Paciente que necesita variedad culinaria',
  '3 zapallitos vaciados, rellenos con 150g carne picada magra, cebolla, tomate, queso light rallado. Al horno. Bajo en carbohidratos.',
  TRUE, NULL),

('Ensalada de lentejas con zanahoria y perejil',
  290, 'porcion', 14, 38, 6,
  'almuerzo', 'Mantenimiento', 'Vegano / Vegetariano / Hipercolesterolemia',
  '200g lentejas cocidas, zanahoria rallada, perejil, cebolla morada, aderezo de limón y aceite de oliva. Hierro, fibra y proteína vegetal.',
  TRUE, NULL),

('Arroz integral con pechuga y wok de vegetales',
  460, 'porcion', 38, 46, 8,
  'almuerzo', 'Deportistas', 'Fútbol / Natación / Vóley / Atletismo',
  '150g arroz integral cocido, 200g pechuga salteada, 200g vegetales de estación en wok con salsa de soja baja en sodio. Carga de glucógeno + proteína.',
  TRUE, NULL),

('Pollo al curry suave con arroz basmati',
  480, 'porcion', 36, 46, 10,
  'almuerzo', 'Mantenimiento', 'Paciente que busca variedad / Sabores del mundo',
  '200g pechuga en curry suave (cúrcuma, comino, leche de coco light), 150g arroz basmati. Antiinflamatorio y saciante.',
  TRUE, NULL),

('Estofado de carne magra con papas y zanahorias',
  520, 'porcion', 38, 40, 12,
  'almuerzo', 'Mantenimiento', 'Paciente adulto mayor / Contexto familiar',
  '200g nalga o peceto trozado, papas, zanahorias, cebolla y pimiento en caldo casero. Cocción lenta. Hierro hemo biodisponible.',
  TRUE, NULL),

('Fideos integrales con boloñesa de carne magra',
  580, 'porcion', 40, 58, 14,
  'almuerzo', 'Deportistas', 'Futbolista / Ciclista / Maratonista',
  '150g fideos integrales, 200g carne picada magra (no más de 10% grasa), salsa de tomate natural, ajo, albahaca. Carga de carbohidratos y proteína.',
  TRUE, NULL),

('Salmón grillado con palta y tomate cherry',
  480, 'porcion', 38, 10, 30,
  'almuerzo', 'Mantenimiento', 'Salud cardiovascular / Adulto mayor activo',
  '200g de salmón fresco grillado, media palta en rodajas, tomate cherry, rúcula, aderezo de limón. Omega-3, proteína premium, grasas cardioprotectoras.',
  TRUE, NULL),

('Revuelto gramajo de pollo light',
  400, 'porcion', 28, 32, 12,
  'almuerzo', 'Mantenimiento', 'Paciente argentino / Comida familiar reconocida',
  '200g pechuga de pollo, 200g papas fritas al horno (no fritas), 3 claras + 1 huevo entero, cebolla y perejil. Versión light del clásico.',
  TRUE, NULL),

('Carbonada de carne con batata y choclo',
  460, 'porcion', 28, 44, 14,
  'almuerzo', 'Mantenimiento', 'Contexto social / Invierno / Paciente familiar',
  '150g de carne magra (roast beef), batata, choclo, calabaza, tomate, caldo casero. Plato completo y nutritivo de la cocina argentina.',
  TRUE, NULL),

('Cazuela de pollo y garbanzo con pimentón ahumado',
  500, 'porcion', 40, 40, 12,
  'almuerzo', 'Mantenimiento', 'Actividad moderada / Sin TACC',
  '200g pollo, 150g garbanzos cocidos, pimiento, tomate, pimentón ahumado. Sin gluten, alta proteína y fibra. Muy saciante.',
  TRUE, NULL),

('Brochettes de pollo con pimiento y cebolla + arroz',
  420, 'porcion', 38, 36, 8,
  'almuerzo', 'Deportistas', 'Hockey / Voley / Tenis',
  '200g pechuga en cubos marinados, pimiento rojo y verde, cebolla en brochette al grill. 100g arroz blanco. Magro y completo.',
  TRUE, NULL),

('Fideos sin TACC con pollo y pesto de albahaca',
  500, 'porcion', 34, 48, 14,
  'almuerzo', 'Mantenimiento', 'Celiaco activo / Sin TACC',
  '150g fideos sin TACC (maíz/arroz), 200g pechuga de pollo, pesto casero de albahaca, nueces y aceite de oliva. Completo y seguro para celíacos.',
  TRUE, NULL),

('Locro de garbanzos y verduras light',
  380, 'porcion', 18, 52, 8,
  'almuerzo', 'Mantenimiento', 'Invernal / Vegano / Contexto social',
  'Garbanzos, zapallo, batata, choclo, puerro. Sin grasa animal. Versión vegana del clásico locro argentino. Alta fibra y hierro.',
  TRUE, NULL),

('Milanesa de pollo al horno con puré de zapallo',
  460, 'porcion', 38, 38, 10,
  'almuerzo', 'Mantenimiento', 'Paciente joven / Familia con niños',
  '200g milanesa de pechuga de pollo al horno, 200g puré de zapallo con nuez moscada sin manteca. Magro, nutritivo y familiar.',
  TRUE, NULL),

('Tarta de verdura y queso light sin masa',
  200, 'porcion', 18, 10, 8,
  'almuerzo', 'Reduccion de peso', 'Paciente en déficit / Sin TACC (adaptable)',
  'Relleno de espinaca, zapallito, cebolla, queso light y 2 huevos. Sin masa. Muy bajo en carbohidratos, alto en proteína y micronutrientes.',
  TRUE, NULL),

('Carga de carbohidratos pre-partido rugby: pasta con pollo',
  720, 'porcion', 48, 80, 16,
  'almuerzo', 'Deportistas', 'Rugby / Jugador de alta demanda física',
  '200g pasta integral, 200g pechuga de pollo grillada, salsa de tomate natural, aceite de oliva, parmesano rallado. Consumir 3-4 horas antes del partido.',
  TRUE, NULL),

('Pastel de papa con carne magra al horno',
  540, 'porcion', 36, 44, 16,
  'almuerzo', 'Mantenimiento', 'Paciente adulto / Comfort food controlado',
  '200g carne picada magra, 300g papas cocidas en puré sin manteca excesiva, queso rallado. Al horno. Versión equilibrada del clásico.',
  TRUE, NULL),

-- ═══════════════════════════════════════════════════════════
-- MERIENDAS (10 nuevas)
-- ═══════════════════════════════════════════════════════════

('Budin de avena y banana sin azúcar',
  240, 'porcion', 8, 36, 6,
  'merienda', 'Mantenimiento', 'Paciente que cocina y prefiere alternativas naturales',
  '2 rodajas de budín casero: avena, banana madura, huevo, canela. Sin azúcar ni harina refinada. Carbohidratos lentos y fibra.',
  TRUE, NULL),

('Mate cocido con leche + galleta de arroz y mantequilla de maní',
  200, 'porcion', 8, 24, 8,
  'merienda', 'Mantenimiento', 'Paciente argentino activo',
  'Mate cocido en leche parcialmente descremada, 1 galleta de arroz con 15g de mantequilla de maní natural sin azúcar.',
  TRUE, NULL),

('Flan casero de leche descremada (sin caramelo)',
  120, 'porcion', 8, 14, 2,
  'merienda', 'Reduccion de peso', 'Paciente con antojos dulces en déficit',
  'Flan preparado con leche descremada, 2 huevos, stevia y vainilla. Sin caramelo de azúcar. Saciante y con proteína.',
  TRUE, NULL),

('Toast integral con queso magro y tomate',
  190, 'porcion', 14, 20, 4,
  'merienda', 'Mantenimiento', 'Actividad general',
  '2 tostadas de pan integral, 40g de queso semidescremado, tomate en rodajas, sal y orégano. Proteína moderada, bajo en grasa.',
  TRUE, NULL),

('Batido de chocolate: leche + cacao + proteína',
  340, 'vaso', 32, 28, 8,
  'merienda', 'Deportistas', 'Post-entrenamiento moderado / Deportista joven',
  '200ml leche descremada, 1 scoop proteína whey, 1 cucharadita cacao amargo, hielo. Sin azúcar añadida. Rápida recuperación muscular.',
  TRUE, NULL),

('Tostadas de avena con mantequilla de maní y miel',
  310, 'porcion', 12, 36, 14,
  'merienda', 'Deportistas', 'Pre-entrenamiento nocturno / Reposición energética',
  '2 tostadas caseras de avena, 15g mantequilla de maní natural, 10g de miel cruda. Carbohidratos lentos + rápidos + grasa saludable.',
  TRUE, NULL),

('Yogur descremado con granola artesanal y maracuyá',
  260, 'porcion', 10, 38, 6,
  'merienda', 'Mantenimiento', 'Paciente con hábitos saludables establecidos',
  '150g yogur descremado, 30g granola artesanal sin azúcar, jugo y pulpa de maracuyá fresco. Probióticos y fibra.',
  TRUE, NULL),

('Porción de sandía con ricota (verano)',
  180, 'porcion', 8, 22, 4,
  'merienda', 'Mantenimiento', 'Verano / Hidratación y frescura',
  '300g de sandía fresca, 80g de ricota magra, menta. Hidratante, baja en calorías, proteína de calidad. Índice glucémico moderado.',
  TRUE, NULL),

('Mini wrap integral con atún, palta y lechuga',
  280, 'porcion', 20, 22, 10,
  'merienda', 'Mantenimiento', 'Deporte moderado / Vida activa',
  '1 tortilla integral pequeña, 80g atún al natural, cuarto de palta, lechuga. Omega-3, proteína y grasas saludables. Fácil de preparar.',
  TRUE, NULL),

('Empanada de verdura al horno + infusión sin azúcar',
  200, 'porcion', 8, 22, 8,
  'merienda', 'Mantenimiento', 'Contexto social / Familia',
  '1 empanada de verdura (espinaca + ricota) al horno. Mejor opción dentro del contexto social. Incluir en el plan como comida social moderada.',
  TRUE, NULL),

-- ═══════════════════════════════════════════════════════════
-- CENAS (20 nuevas)
-- ═══════════════════════════════════════════════════════════

('Crema de zapallo con semillas de chía y jengibre',
  160, 'porcion', 4, 22, 6,
  'cena', 'Reduccion de peso', 'Ansiedad nocturna / Digestión sensible',
  '400g zapallo, cebolla, caldo vegetal, jengibre fresco. Sin crema. 1 cucharadita de chía al servir. Reconfortante, baja en calorías, antiinflamatoria.',
  TRUE, NULL),

('Brochettes de pollo con vegetales al horno',
  260, 'porcion', 36, 10, 6,
  'cena', 'Reduccion de peso', 'Deportista en período de definición',
  '200g pechuga en cubos, zucchini, morrón, cebolla, condimentados con limón y orégano. Al horno. Muy magro, alto en proteína.',
  TRUE, NULL),

('Tortilla española de papa light (al horno)',
  340, 'porcion', 16, 28, 14,
  'cena', 'Mantenimiento', 'Contexto familiar / Cena social liviana',
  '2 huevos + 1 clara, 150g papas cocidas (no fritas), cebolla confitada. Al horno sin aceite excesivo. Versión light de la tortilla española.',
  TRUE, NULL),

('Wraps de lechuga con atún y palta',
  220, 'porcion', 24, 8, 10,
  'cena', 'Reduccion de peso', 'Keto / Low-Carb / Fase de corte',
  '4 hojas grandes de lechuga, 160g atún al natural, cuarto de palta, tomate cherry, cebolla morada. Sin carbohidratos, alta saciedad.',
  TRUE, NULL),

('Caldo de pollo con vegetales y fideos finos',
  200, 'porcion', 18, 20, 4,
  'cena', 'Reduccion de peso', 'Invierno / Convalecencia / Cena muy liviana',
  'Caldo casero de pollo desgrasado, 100g pollo desmenuzado, 30g fideos finos, zanahoria, apio, cebolla. La cena más reconfortante y liviana.',
  TRUE, NULL),

('Crema de brócoli con queso rallado light',
  180, 'porcion', 12, 14, 6,
  'cena', 'Reduccion de peso', 'Paciente con restricción calórica nocturna',
  '300g brócoli, cebolla, ajo, caldo de verduras, 30g queso rallado light. Sin crema de leche. Vitamina C, calcio, fibra y muy pocas calorías.',
  TRUE, NULL),

('Cazuela de mariscos con vegetales de estación',
  360, 'porcion', 38, 16, 12,
  'cena', 'Mantenimiento', 'Salud cardiovascular / Adulto activo',
  '200g mix de mariscos (camarones, mejillones, calamares), pimiento, tomate, cebolla, caldo de pescado. Omega-3, proteína magra de alta calidad.',
  TRUE, NULL),

('Ravioles de ricota y espinaca con salsa de tomate',
  460, 'porcion', 22, 52, 14,
  'cena', 'Mantenimiento', 'Cena familiar / Pasta saludable',
  '200g ravioles de ricota y espinaca (frescos, preferir artesanales), salsa de tomate natural con ajo y albahaca. Versión moderada de la pasta italiana.',
  TRUE, NULL),

('Pollo con salsa de mostaza y miel + batata asada',
  520, 'porcion', 42, 44, 10,
  'cena', 'Deportistas', 'Fútbol / Hockey / Post-partido',
  '200g pechuga con salsa de mostaza y miel, 200g batata asada con romero. Cena de recuperación con glucógeno, proteína y antioxidantes.',
  TRUE, NULL),

('Zoodles de calabacín con boloñesa de pavo',
  270, 'porcion', 28, 14, 10,
  'cena', 'Reduccion de peso', 'Paciente que quiere reducir carbohidratos',
  '3 calabacines espiralizados, 200g carne picada de pavo (muy magra), salsa de tomate natural. Sin pasta. Sensación de plato abundante con muy pocas calorías.',
  TRUE, NULL),

('Ensalada de pollo, espinaca y palta con limón',
  320, 'porcion', 34, 10, 16,
  'cena', 'Reduccion de peso', 'Paciente en déficit moderado / Fitness',
  '150g pechuga grillada en tiras, 100g espinaca baby, media palta, tomate cherry, aderezo de limón y aceite de oliva extra virgen.',
  TRUE, NULL),

('Guiso de arroz integral con pollo y vegetales',
  500, 'porcion', 36, 52, 10,
  'cena', 'Deportistas', 'Natación / Atletismo / Noche de entrenamiento',
  '200g pechuga de pollo, 100g arroz integral, choclo, arvejas, zanahoria, caldo casero. Recuperación de glucógeno y proteína para reparación muscular.',
  TRUE, NULL),

('Chorizos de pollo al horno con chimichurri liviano',
  440, 'porcion', 30, 6, 32,
  'cena', 'Mantenimiento', 'Contexto social / Asado de domingo',
  '2 chorizos de pollo al horno (no al carbón para reducir HAAs). Chimichurri con perejil, ajo, orégano, aceite de oliva y vinagre. Moderado en grasa.',
  TRUE, NULL),

('Milanesa de berenjena al horno con mozzarella',
  300, 'porcion', 14, 24, 14,
  'cena', 'Mantenimiento', 'Vegetariano / Cena familiar sin carne',
  '1 berenjena grande en rodajas, empanada con pan rallado integral al horno, salsa de tomate natural, mozzarella light derretida. Versión vegetal del clásico.',
  TRUE, NULL),

('Salmón al horno con costra de almendras y espárragos',
  500, 'porcion', 42, 8, 32,
  'cena', 'Mantenimiento', 'Salud premium / Adulto activo saludable',
  '200g salmón fresco, costra de 20g almendras molidas y hierbas al horno. 200g espárragos a la plancha. Omega-3, vitamina D, proteína de alta calidad.',
  TRUE, NULL),

('Asado magro de ternera con ensalada de rúcula y tomate',
  480, 'porcion', 48, 8, 28,
  'cena', 'Mantenimiento', 'Contexto social / Asado argentino moderado',
  '200g de corte magro (peceto, bola de lomo, nalga) a la parrilla. Ensalada de rúcula, tomate y cebolla morada con aceite de oliva y limón. Sin embutidos.',
  TRUE, NULL),

('Hamburguesa casera de ternera magra con pan integral',
  680, 'porcion', 46, 42, 26,
  'cena', 'Aumento de peso', 'Hardgainer / Volumen magro',
  '200g carne picada con menos de 10% grasa, 1 pan integral de hamburguesa, queso magro, lechuga y tomate. Versión nutritiva del clásico.',
  TRUE, NULL),

('Locro de invierno con pollo y vegetales (light)',
  340, 'porcion', 26, 36, 8,
  'cena', 'Mantenimiento', 'Invernal / Contexto social / Sin cerdo',
  'Variante light del locro con pechuga de pollo, garbanzos, batata, choclo. Sin embutidos grasos. Alta fibra y proteína sin exceso de grasa saturada.',
  TRUE, NULL),

('Rollito de tapa de asado con ensalada de verdes',
  560, 'porcion', 42, 10, 38,
  'cena', 'Aumento de peso', 'Aumento de masa muscular / Atleta de fuerza',
  '200g de tapa de asado grillada, arrollada con chimichurri de hierbas. Ensalada de rúcula, berro y escarola. Carne con mayor infiltración grasa, ideal en volumen.',
  TRUE, NULL),

('Milanga de soja al horno con puré de batata',
  380, 'porcion', 18, 52, 8,
  'cena', 'Mantenimiento', 'Vegano / Vegetariano activo',
  '2 milanesas de soja al horno con pan rallado, 200g puré de batata sin manteca. Proteína vegetal completa, fibra y vitamina A.',
  TRUE, NULL),

-- ═══════════════════════════════════════════════════════════
-- COLACIONES NOCTURNAS adicionales (5)
-- ═══════════════════════════════════════════════════════════

('Infusion de tilo con 15 almendras',
  95, 'porcion', 4, 4, 8,
  'colacion_nocturna', 'Reduccion de peso', 'Ansiedad nocturna / Insomnio leve',
  'Té de tilo o manzanilla sin azúcar, 15 almendras naturales sin sal. Magnesio para relajación muscular y grasas saciantes.',
  TRUE, NULL),

('Bowl de queso cottage con stevia y canela',
  100, 'porcion', 14, 4, 2,
  'colacion_nocturna', 'Mantenimiento', 'Culturismo / Alta demanda proteica nocturna',
  '150g de queso cottage con stevia y canela. Proteína de caseína: digestión lenta para prevenir catabolismo durante el ayuno nocturno.',
  TRUE, NULL),

('Media taza de leche con cúrcuma y jengibre',
  60, 'porcion', 4, 6, 1,
  'colacion_nocturna', 'Reduccion de peso', 'Paciente con inflamación crónica / Diabético',
  '100ml leche descremada tibia, pizca de cúrcuma, jengibre rallado y pimienta negra. Antiinflamatorio, bajo en calorías, inductor del sueño.',
  TRUE, NULL),

('Scoop de proteína caseína con agua y canela',
  120, 'porcion', 26, 3, 1,
  'colacion_nocturna', 'Aumento de peso', 'Culturista / Hipertrofia avanzada',
  '1 scoop de proteína caseína micelar disuelta en agua fría. Liberación lenta de aminoácidos durante 7-8 horas de sueño. Anti-catabólico óptimo.',
  TRUE, NULL),

('Kéfir con arándanos y semillas de lino',
  130, 'porcion', 8, 14, 4,
  'colacion_nocturna', 'Mantenimiento', 'Salud digestiva / Microbiota intestinal',
  '150ml de kéfir de leche, 30g de arándanos, 1 cucharadita de semillas de lino molidas. Probióticos vivos, omega-3 vegetal y fibra prebiótica.',
  TRUE, NULL),

-- ═══════════════════════════════════════════════════════════
-- DEPORTISTAS ESPECÍFICOS (preparaciones estratégicas)
-- ═══════════════════════════════════════════════════════════

('Pre-partido fútbol: arroz + pollo + banana (3h antes)',
  490, 'porcion', 38, 58, 6,
  'almuerzo', 'Deportistas', 'Futbolista (categorías amateur y profesional)',
  '150g arroz blanco, 200g pechuga de pollo grillada sin condimentos fuertes, 1 banana. Consumir 2.5-3 horas antes del partido. Fácil digestión.',
  TRUE, NULL),

('Post-partido fútbol: batido whey + avena + banana',
  450, 'vaso', 30, 50, 6,
  'colacion', 'Deportistas', 'Futbolista / Recuperación inmediata',
  '1 scoop proteína whey, 40g avena, 1 banana, 200ml leche descremada. Tomar dentro de los 30 minutos post-partido. Reposición glucógeno + síntesis proteica.',
  TRUE, NULL),

('Pre-entrenamiento natación: tostadas con miel y banana',
  280, 'porcion', 6, 56, 3,
  'merienda', 'Deportistas', 'Nadador / Triatleta (60-90 min antes)',
  '2 tostadas de pan blanco (digestión más rápida), 15g de miel, 1 banana. Carbohidratos de rápida absorción. Pan blanco > integral antes del agua.',
  TRUE, NULL),

('Post-sesión natación larga: batido recuperacion completo',
  420, 'vaso', 38, 40, 8,
  'colacion', 'Deportistas', 'Nadador / Waterpolo (post-sesión > 90 min)',
  '1 scoop proteína whey, 40g avena, 1 banana, 200ml leche entera. La sesión larga agota glucógeno muscular hepático. Reposición completa.',
  TRUE, NULL),

('Pre-partido rugby: desayuno de alto rendimiento',
  650, 'porcion', 38, 72, 16,
  'desayuno', 'Deportistas', 'Rugbier (día de partido / entrenamiento intenso)',
  '100g avena con leche entera, 3 huevos revueltos, 1 banana, 200ml jugo de naranja. Consumir 3-4 horas antes. Máxima carga energética sin malestar.',
  TRUE, NULL),

('Post-entrenamiento rugby: pasta con carne y queso',
  800, 'porcion', 50, 80, 22,
  'cena', 'Deportistas', 'Rugbier (post-entrenamiento de alta intensidad)',
  '200g pasta (tipo penne o spaghetti), 200g carne picada magra, salsa de tomate, 30g queso parmesano. Máxima reposición de glucógeno y síntesis proteica.',
  TRUE, NULL),

('Pre-partido hockey: arroz con pollo y vegetales',
  460, 'almuerzo', 38, 46, 8,
  'almuerzo', 'Deportistas', 'Jugador/a de hockey (3h antes del partido)',
  '150g arroz blanco, 200g pechuga grillada, 100g vegetales cocidos al vapor. Sin fibra excesiva antes del partido para minimizar malestar gastrointestinal.',
  TRUE, NULL),

('Post-partido hockey: sandwich integral de pollo',
  380, 'porcion', 34, 36, 8,
  'merienda', 'Deportistas', 'Jugador/a hockey (recuperación rápida)',
  '2 rebanadas pan integral, 150g pechuga de pollo en lonja, lechuga, tomate, mostaza. Práctico y completo para la vuelta a casa.',
  TRUE, NULL),

('Pre-entrenamiento vóley: banana + yogur + granola',
  280, 'porcion', 12, 44, 6,
  'colacion', 'Deportistas', 'Voleibolista (45-60 min antes)',
  '1 banana, 100g yogur griego natural, 20g granola artesanal. Energía rápida y proteína para explosividad. Fácil digestión.',
  TRUE, NULL),

('Pre-carrera corta (hasta 10km): banana con tostada y miel',
  220, 'porcion', 4, 46, 2,
  'desayuno', 'Deportistas', 'Runner / Atletismo de velocidad-fondo',
  '1 banana madura, 1 tostada de pan blanco, 10g de miel. 45-60 min antes. Carbohidratos simples de rápida absorción. Evitar fibra y grasa excesiva.',
  TRUE, NULL),

('Post-carrera larga (>10km): pasta integral con atún',
  580, 'porcion', 40, 60, 10,
  'cena', 'Deportistas', 'Maratonista / Runner de fondo',
  '150g pasta integral, 160g atún al natural, aceite de oliva, ajo, perejil. La ventana anabólica post-maratón exige carbohidratos + proteína en cantidad.',
  TRUE, NULL),

('Post-WOD crossfit: whey + leche de coco + plátano',
  400, 'vaso', 32, 40, 8,
  'colacion', 'Deportistas', 'Crossfit / HIIT de alta intensidad',
  '1 scoop proteína whey, 150ml leche de coco, 1 banana, hielo. Carbohidratos rápidos + proteína + electrolitos. Ideal post-WOD intenso.',
  TRUE, NULL)

ON CONFLICT DO NOTHING;
