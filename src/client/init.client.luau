-- Punto de entrada del cliente: el bastón (golpes, combo y giro), rodar, fijar objetivo,
-- Chispa (el dron que te sigue, habla y escanea), los efectos, tus corazones y cristales, la
-- lista de controles y los botones de celular.

local Chispa = require(script.Chispa)
local Dodge = require(script.Dodge)
local Drones = require(script.Drones)
local Fx = require(script.Fx)
local LockOn = require(script.LockOn)
local Staff = require(script.Staff)
local ControlsUI = require(script.UI.Controls)
local HUD = require(script.UI.HUD)
local TouchButtons = require(script.UI.TouchButtons)

-- Cada parte arranca por separado: si una falla (sale en rojo en Output), las demás siguen
local parts = {
	Drones,
	LockOn,
	Staff,
	Dodge,
	Chispa,
	Fx,
	ControlsUI,
	HUD,
	TouchButtons,
}
for _, part in parts do
	task.spawn(function()
		local ok, err = pcall(part.Start)
		if not ok then
			warn("[Cliente] No arrancó una parte:", err)
		end
	end)
end
