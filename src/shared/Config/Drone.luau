-- Chispa, el dron compañero: lo que dice, cuándo ayuda a pelear y el escaneo.
--
-- Las frases se pueden cambiar libremente. Cada "pista" del mapa (una pieza con la etiqueta
-- "Pista" y el atributo Pista = "<nombre>") hace que Chispa diga la frase con ese nombre la
-- primera vez que te acercas.

local Drone = {}

Drone.name = "Chispa"

-- Ayudar a pelear: cuando le pegas a un enemigo, Chispa le dispara un rayito
Drone.zap = {
	damage = 5,
	delay = 0.25, -- segundos después de tu golpe
	cooldown = 1.2, -- como mínimo entre rayo y rayo
}

-- Escanear (R): marca a los enemigos cercanos a través de las paredes
Drone.scan = {
	range = 90,
	duration = 5,
	cooldown = 8,
}

-- Lo que dice Chispa
Drone.lines = {
	Hola = "¡Hola, explorador! Soy Chispa. Te acompaño a recuperar los núcleos del Archipiélago Eco.",
	Plaza = "Ese pedestal tenía los cuatro núcleos de energía. El Óxido se los llevó todos.",
	Campo = "Prueba tu bastón con los muñecos: haz clic tres veces seguidas para el combo.",
	Giro = "Truco: mantén el clic y suelta para dar un giro que pega a todo lo de alrededor.",
	Portales = "Cada portal lleva a una isla. Hay que encontrar la manera de encenderlos.",
	Selva = "La Selva Brumosa... huele a chatarra mojada. El portal todavía no tiene energía.",
	Volcan = "El Volcán Brasa. Necesitamos más poder antes de ir ahí.",
	Glaciar = "El Glaciar Silencio está congelado. Ni yo quiero entrar todavía.",
	Ruinas = "Las Ruinas del Cielo. Ahí se esconde el que empezó todo esto.",
	Tienda = "La tienda abre pronto. Junta cristales mientras tanto.",
	Taller = "¡Mi taller! Aquí me vas a poder mejorar más adelante.",
	Escaneo = "Escaneando...",
	EscaneoNada = "No veo enemigos cerca.",
	EscaneoAlgo = "Veo %d objetivos. Los marqué para ti.",
	EscaneoEspera = "Dame un segundo, me estoy recargando.",
	Muneco = "¡Muñeco roto! Vuelve a armarse en un momento.",
	Chatarra = "¡Cuidado, máquinas del Óxido! Cuando su ojo se ponga rojo, rueda con Shift.",
	Escudo = "¡Rebotó en el escudo! Pégale por la espalda o usa el remate o el giro.",
	CofreVacio = "Este cofre ya lo abrimos. Vacío.",
	Cofre = "¡Un cofre! +%d cristales.",
	CofreCorazon = "¡Un contenedor de corazón! Ahora tienes un corazón más.",
	Caida = "¡Auch! Te traigo de vuelta a Puerto Eco.",
	Secretos = "Marqué %d cofres escondidos en dorado.",
}

return Drone
