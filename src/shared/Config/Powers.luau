-- Los poderes del bastón. Se ganan en las mazmorras y se guardan.
--
-- Empuje (E, L2 en control, botón "Empuje" en celular): una onda hacia enfrente que
--   * mueve los bloques de piedra (etiqueta "Empujable") un paso, como en un tablero
--   * rompe las paredes agrietadas (etiqueta "Agrietado")
--   * empuja y aturde a las máquinas, y TUMBA al jefe de la selva para que le puedas pegar

local Powers = {}

Powers.Empuje = {
	range = 13, -- hasta dónde llega la onda
	angle = 0.4, -- qué tan abierta es (1 = solo enfrente)
	damage = 6,
	push = 90,
	stun = 1.2, -- segundos que deja quietas a las máquinas
	cooldown = 1.1,
	duration = 0.4, -- la animación
	step = 8, -- cuánto se mueve un bloque por cada empuje
}

return Powers
