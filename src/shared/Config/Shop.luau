-- Lo que se compra con CRISTALES. Cada mejora tiene niveles: el precio de cada nivel, en orden.
--
-- Tienda (la casa de techo rojo en Puerto Eco, o el botón TIENDA):
--   Baston   = el bastón pega más (+15% por nivel)
--   Corazon  = un contenedor de corazón (+1 corazón)
-- Taller de Chispa (la casa de techo azul, o el botón TALLER):
--   Rayo     = el rayito de Chispa pega más (+3 por nivel)
--   Recarga  = Chispa dispara más seguido (-0.25 s por nivel)
--   Iman     = los cristales y corazones se vienen hacia ti desde más lejos (+6 por nivel)
--   Escaner  = el escaneo llega más lejos (+40 por nivel)

local Shop = {}

Shop.items = {
	Baston = {
		place = "Tienda",
		name = "Bastón reforzado",
		description = "Tu bastón pega 15% más por cada nivel.",
		prices = { 60, 150, 300 },
		staffBonus = 0.15,
	},
	Corazon = {
		place = "Tienda",
		name = "Contenedor de corazón",
		description = "Un corazón más para siempre.",
		prices = { 120, 250 },
	},
	Rayo = {
		place = "Taller",
		name = "Rayo de Chispa",
		description = "El rayito de Chispa pega 3 más por cada nivel.",
		prices = { 40, 100, 220 },
		zapBonus = 3,
	},
	Recarga = {
		place = "Taller",
		name = "Recarga rápida",
		description = "Chispa dispara su rayito más seguido.",
		prices = { 80, 180 },
		cooldownBonus = 0.25,
	},
	Iman = {
		place = "Taller",
		name = "Imán de cristales",
		description = "Los cristales y corazones se vienen hacia ti desde más lejos.",
		prices = { 50, 120 },
		magnetBonus = 6,
	},
	Escaner = {
		place = "Taller",
		name = "Escáner de largo alcance",
		description = "Chispa escanea más lejos.",
		prices = { 60 },
		scanBonus = 40,
	},
}

-- En qué orden salen en cada menú
Shop.order = {
	Tienda = { "Baston", "Corazon" },
	Taller = { "Rayo", "Recarga", "Iman", "Escaner" },
}

return Shop
