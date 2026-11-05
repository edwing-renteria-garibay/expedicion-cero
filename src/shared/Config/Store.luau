-- Lo que se compra con ROBUX. Los números (id) se crean en el Creator Hub después de publicar:
--   Pases:     Creator Hub > tu experiencia > Monetización > Pases
--   Productos: Creator Hub > tu experiencia > Monetización > Productos para desarrolladores
-- Copia el número de cada uno aquí. Con id = 0 no se puede comprar (en Studio sale "Probar").

local Store = {}

-- Pases: se compran una vez y son para siempre (Roblox recuerda quién los tiene)
Store.passes = {
	{
		key = "x2",
		id = 0,
		name = "Cristales x2",
		description = "Todos los cristales que ganas valen el doble.",
		price = 199,
	},
	{
		key = "VIP",
		id = 0,
		name = "VIP",
		description = "Chispa y tu bastón dorados, y un corazón extra mientras juegas.",
		price = 299,
	},
}

-- Productos: se pueden comprar las veces que quieras
Store.products = {
	{
		key = "Bolsa",
		id = 0,
		name = "Bolsa de cristales",
		description = "+150 cristales.",
		price = 49,
		crystals = 150,
	},
	{
		key = "Cofre",
		id = 0,
		name = "Cofre de cristales",
		description = "+600 cristales.",
		price = 149,
		crystals = 600,
	},
}

return Store
