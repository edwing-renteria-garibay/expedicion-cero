-- Dónde está cada isla y cómo se ve por dentro (el cliente cambia la niebla al entrar).
--
--   center = el centro de la isla (las islas están lejos de Puerto Eco, en el mismo lugar)
--   area   = el rectángulo donde está todo lo de la isla (para saber si estás adentro)
--   fog    = la niebla al estar adentro (Atmosphere)

local Zones = {}

Zones.Selva = {
	name = "Selva Brumosa",
	center = Vector3.new(1500, 0, 0),
	area = { center = Vector3.new(1500, 0, -150), size = Vector3.new(240, 120, 520) },
	fog = {
		Density = 0.5,
		Haze = 2.4,
		Color = Color3.fromRGB(170, 210, 170),
		Decay = Color3.fromRGB(90, 130, 100),
	},
}

-- ¿Esta posición está dentro de la isla?
function Zones.Inside(zone, position: Vector3): boolean
	local offset = position - zone.area.center
	return math.abs(offset.X) < zone.area.size.X / 2 and math.abs(offset.Z) < zone.area.size.Z / 2
end

return Zones
