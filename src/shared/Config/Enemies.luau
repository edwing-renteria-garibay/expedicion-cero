-- Las máquinas del Óxido: cuánta vida tienen, cuánto pegan y cómo se comportan.
--
--   health    = vida (el bastón pega 18 por golpe y 34 con el remate)
--   speed     = qué tan rápido caminan (0 = no se mueven)
--   sight     = a qué distancia te ven y te persiguen
--   reach     = a qué distancia te pueden pegar
--   damage    = vida que te quitan (20 = un corazón)
--   windup    = segundos que brillan en rojo ANTES de pegar: ese es tu momento para rodar
--   cooldown  = segundos entre ataque y ataque
--   crystals  = cuántos cristales sueltan al romperse { mínimo, máximo }
--   heartChance = probabilidad de soltar un corazón (0.25 = una de cada cuatro)

local Enemies = {}

Enemies.types = {
	-- Pequeño y rápido: se te acerca y te muerde
	Rastreador = {
		health = 45,
		speed = 15,
		sight = 40,
		reach = 5,
		damage = 10,
		windup = 0.5,
		cooldown = 1.4,
		crystals = { 2, 4 },
		heartChance = 0.2,
		color = Color3.fromRGB(190, 96, 52),
		size = 1,
	},
	-- Grande, lento y con un escudo al frente: los golpes normales de frente rebotan.
	-- Rodéalo y pégale por la espalda, o rómpele la guardia con el remate o el giro.
	Escudero = {
		health = 110,
		speed = 10,
		sight = 40,
		reach = 7,
		damage = 20,
		windup = 0.8,
		cooldown = 2.2,
		crystals = { 6, 9 },
		heartChance = 0.5,
		color = Color3.fromRGB(150, 80, 60),
		size = 1.6,
		shield = true,
	},
	-- No se mueve: gira y dispara bolas de óxido lentas que puedes esquivar
	Torreta = {
		health = 60,
		speed = 0,
		sight = 60,
		reach = 60,
		damage = 10,
		windup = 0.7,
		cooldown = 2.6,
		crystals = { 3, 5 },
		heartChance = 0.25,
		color = Color3.fromRGB(120, 110, 100),
		size = 1,
		projectileSpeed = 40,
	},
}

-- Golpes que rompen la guardia del Escudero aunque le pegues de frente
Enemies.guardBreakers = { [3] = true, Giro = true }

-- Segundos para que vuelva a salir una máquina después de romperla
Enemies.respawn = 25

-- Cuánto tiempo se quedan quietos al recibir un golpe
Enemies.stun = 0.35

return Enemies
