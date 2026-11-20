-- La cacería de las 7 llaves.
--
-- Cada TEMPORADA (2 semanas) las 7 llaves cambian de mundo y de escondite. El servidor elige
-- los lugares con el número de la temporada (server/Services/KeyService), así todos los
-- servidores ponen las llaves en el mismo lugar sin hablar entre sí.
--
-- Quien junta las 7 en una temporada es LEYENDA: su nombre va al Salón de Leyendas del Nexo,
-- gana el título y el aura dorada, y (cuando haya número) la insignia.

local Keys = {}

Keys.count = 7

-- Cuándo empieza la temporada 2 (lunes 23 de noviembre de 2026, 00:00 en Ciudad de México).
-- Todo lo anterior cuenta como temporada 1. Cada temporada dura seasonDays días.
Keys.epoch = 1795413600
Keys.seasonDays = 14

-- El color de cada llave (y de su hueco en el pedestal)
Keys.colors = {
	Color3.fromRGB(255, 90, 90),
	Color3.fromRGB(255, 160, 50),
	Color3.fromRGB(255, 225, 60),
	Color3.fromRGB(90, 230, 110),
	Color3.fromRGB(80, 200, 255),
	Color3.fromRGB(110, 120, 255),
	Color3.fromRGB(210, 110, 255),
}

-- Frío o caliente (Chispa al escanear): distancia en studs a la llave más cercana
Keys.hot = 45
Keys.warm = 130

-- Salón de Leyendas: cuántos nombres se ven en el muro (y los 3 primeros tienen estatua)
Keys.hallSize = 10

-- Número de la insignia de Leyenda (Creator Hub > tu experiencia > Insignias). 0 = sin insignia.
Keys.badge = 0

-- La temporada de este momento (1, 2, 3...)
function Keys.Season(now: number?): number
	local t = now or os.time()
	local length = Keys.seasonDays * 24 * 60 * 60
	return math.max(1, math.floor((t - Keys.epoch) / length) + 2)
end

-- Cuándo termina esta temporada (en os.time)
function Keys.SeasonEnd(season: number): number
	local length = Keys.seasonDays * 24 * 60 * 60
	return Keys.epoch + (season - 1) * length
end

return Keys
