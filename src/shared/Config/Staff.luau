-- El bastón de energía: cuánto pega cada golpe, qué tan lejos llega y cuánto tarda.
--
-- Cambia los números aquí para ajustar cómo se siente pelear. Los usan el cliente (la animación
-- y cuándo puedes volver a golpear) y el servidor (el daño y a quién le pegas).
--
--   damage   = vida que le quita al enemigo
--   range    = hasta dónde llega el golpe (en studs, desde el centro del personaje)
--   angle    = qué tan abierto es el golpe: 1 = solo enfrente, 0 = medio círculo, -1 = todo alrededor
--   duration = segundos que dura la animación (no puedes volver a golpear mientras tanto)
--   push     = qué tan fuerte empuja al enemigo hacia atrás

local Staff = {}

Staff.attacks = {
	-- El combo: clic, clic, clic. El tercero es un golpe de arriba hacia abajo que pega más
	{ name = "Golpe 1", damage = 18, range = 9, angle = 0.25, duration = 0.28, push = 18 },
	{ name = "Golpe 2", damage = 18, range = 9, angle = 0.25, duration = 0.28, push = 18 },
	{ name = "Remate", damage = 34, range = 10, angle = 0.1, duration = 0.42, push = 45 },
	-- Mantén el clic y suelta: das una vuelta completa y le pegas a todo lo que está alrededor
	Giro = { name = "Giro", damage = 30, range = 12, angle = -1, duration = 0.5, push = 55 },
}

-- Si vuelves a hacer clic antes de que pase esto (al terminar el golpe), sigue el combo
Staff.comboWindow = 0.6

-- Cuánto tienes que mantener el clic para que el giro esté cargado
Staff.chargeTime = 0.6

-- Rodar (Shift): qué tan rápido, cuánto dura y cada cuánto se puede
Staff.dodge = {
	speed = 55,
	duration = 0.32,
	cooldown = 0.7,
	invulnerable = 0.4, -- segundos en que nada te hace daño (para esquivar ataques en la semana 2)
}

-- Fijar objetivo (F): hasta dónde busca enemigos y a qué distancia se suelta solo
Staff.lockRange = 45
Staff.lockBreak = 60

return Staff
