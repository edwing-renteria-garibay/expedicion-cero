-- Ajustes generales del juego.

local RunService = game:GetService("RunService")

local Settings = {}

-- Dónde se guarda el progreso (no lo cambies después de publicar o todos empiezan de cero)
Settings.saveKey = "ExpedicionCeroPerfiles"

-- En Studio no se guarda nada (para probar sin miedo)
Settings.testing = RunService:IsStudio()

-- Corazones: con cuántos empiezas, el máximo que puedes llegar a tener y cuánta vida vale uno.
-- Los golpes de los enemigos quitan medio corazón (10) o uno entero (20).
Settings.hearts = {
	start = 3,
	max = 12,
	value = 20,
}

-- Segundos para volver a aparecer después de caer
Settings.respawnTime = 4

return Settings
