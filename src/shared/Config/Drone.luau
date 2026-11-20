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
	Hola = "¡Hola, explorador! Soy Chispa. Bienvenido al Nexo: de aquí salen los portales a todos los mundos.",
	Plaza = "El pedestal de las 7 llaves. Están escondidas en los mundos y cambian de lugar cada temporada.",
	Salon = "El Salón de Leyendas. Quien junta las 7 llaves en una temporada pone aquí su nombre.",
	Campo = "Prueba tu bastón con los muñecos: haz clic tres veces seguidas para el combo.",
	Giro = "Truco: mantén el clic y suelta para dar un giro que pega a todo lo de alrededor.",
	Portales = "Cada portal lleva a un mundo distinto. Los apagados todavía no tienen energía.",
	SelvaAbierto = "¡El portal de la Selva Brumosa tiene energía! Crúzalo cuando estés listo.",
	Volcan = "El Volcán Brasa: saltos sobre lava. Todavía no tiene energía.",
	Pista = "La Pista Neón: carreras a toda velocidad. Todavía no tiene energía.",
	Arena = "La Arena del Óxido: oleadas de máquinas. Todavía no tiene energía.",
	Mansion = "La Mansión Eco... dicen que hay fantasmas. Todavía no tiene energía.",
	Glaciar = "El Glaciar Silencio está congelado. Todavía no tiene energía.",
	Ruinas = "Las Ruinas del Cielo: islas que flotan. Todavía no tiene energía.",
	Laberinto = "El Laberinto Espejo cambia de forma. Todavía no tiene energía.",
	Pixel = "El Mundo Píxel se ve... cuadrado. Todavía no tiene energía.",
	Tienda = "¡La tienda! Con cristales refuerzas el bastón y compras corazones. Ábrela aquí o con B.",
	Taller = "¡Mi taller! Aquí me mejoras: rayito más fuerte, recarga, imán y escáner. Ábrelo aquí o con T.",
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
	Caida = "¡Auch! Te traigo de vuelta al Nexo.",
	-- Selva Brumosa
	SelvaLlegada = "La Selva Brumosa. Escanea con R: si hay una llave en este mundo, te digo si estás cerca.",
	Templo = "El Templo de raíces. Huele a aceite viejo... aquí hay algo grande.",
	Sala = "¡Se cerró la puerta! Rompe todas las máquinas de la sala para abrirla.",
	SalaLimpia = "¡Sala limpia! La puerta se abrió.",
	Placa = "Una placa: párate encima y la puerta se abre unos segundos. ¡Corre!",
	GranCofreCerca = "Ese cofre es enorme. Ábrelo.",
	GranCofre = "¡El poder de EMPUJE! Pulsa E para lanzar una onda: mueve bloques, rompe paredes agrietadas y tumba máquinas.",
	YaEmpuje = "Ya tienes el Empuje. El cofre está vacío.",
	Bloque = "Ese bloque se puede mover con el Empuje (E). ¿Y si lo pones sobre la placa?",
	Agrietado = "Esa pared está agrietada... un Empuje la tumbaría.",
	Llave = "¡La llave del jefe! Ahora abre la puerta grande.",
	PuertaJefe = "Está cerrada con llave. Debe haber una escondida por aquí.",
	Jefe = "¡Un gusano de chatarra gigante! Su armadura aguanta el bastón: túmbalo con Empuje (E) y luego pégale.",
	JefeTumbado = "¡Lo tumbaste! ¡Pégale ahora que no tiene armadura!",
	Blindado = "Su armadura aguanta el bastón. ¡Túmbalo primero con el Empuje (E)!",
	JefeVencido = "¡Lo rompiste! ¡Mira cuántos cristales!",
	Secretos = "Marqué %d cofres escondidos en dorado.",
	-- Las 7 llaves (el %s es "" o ", hacia el norte" con el escáner del taller)
	LlaveCaliente = "¡Caliente! Hay una llave muy cerca%s.",
	LlaveTibia = "Tibio... hay una llave por esta zona%s.",
	LlaveFria = "Frío. Hay una llave en este mundo, pero lejos%s.",
	LlaveNinguna = "No siento llaves en este mundo. Prueba en otro portal.",
	LlavesCompletas = "¡Ya tienes las 7 llaves de esta temporada!",
	LlaveTomada = "¡Una llave! Llevas %d de 7.",
	LlaveYa = "Esta llave ya la tienes.",
	Leyenda = "¡LAS 7 LLAVES! Ya eres Leyenda: tu nombre está en el Salón de Leyendas.",
	NuevaLeyenda = "¡%s juntó las 7 llaves y es Leyenda!",
	NuevaTemporada = "¡Empezó una temporada nueva! Las 7 llaves cambiaron de lugar.",
}

return Drone
