-- Los sonidos del juego. Pon aquí el número de un sonido de la Caja de herramientas de Studio
-- (Toolbox > Audio). 0 = sin sonido.
--
-- Para encontrar el número: en la Caja de herramientas, clic derecho en el sonido > "Copiar ID
-- del recurso". Pega solo los números.

return {
	swing = 0, -- cada golpe del bastón
	hit = 0, -- cuando le pegas a algo
	spin = 0, -- el giro cargado
	charged = 0, -- cuando el giro ya está cargado
	dodge = 0, -- rodar
	zap = 0, -- el rayito de Chispa
	chispa = 0, -- cuando Chispa habla
	scan = 0, -- el escaneo
	hurt = 0, -- cuando te pegan
	crystal = 0, -- recoger un cristal
	heart = 0, -- recoger un corazón
	chest = 0, -- abrir un cofre
	block = 0, -- tu golpe rebota en un escudo
	breakEnemy = 0, -- una máquina del Óxido se rompe
	push = 0, -- el Empuje
	door = 0, -- una puerta se abre o se cierra
	slam = 0, -- el gusano sale de la tierra o se lanza
	portal = 0, -- cruzar un portal
}
