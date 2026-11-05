-- Punto de entrada del cliente: el bastón (golpes, combo y giro), rodar, fijar objetivo,
-- los poderes (Empuje), Chispa (el dron que te sigue, habla y escanea), los efectos, tus
-- corazones y cristales, la barra del jefe, el pedestal de núcleos, la niebla de cada isla, la
-- lista de controles, los botones de celular, la tienda y el taller, las salas privadas y la
-- música.

local Chispa = require(script.Chispa)
local Dodge = require(script.Dodge)
local Drones = require(script.Drones)
local Fx = require(script.Fx)
local Hub = require(script.Hub)
local Layout = require(script.Layout)
local LockOn = require(script.LockOn)
local Music = require(script.Music)
local Powers = require(script.Powers)
local Prompts = require(script.Prompts)
local Staff = require(script.Staff)
local Zones = require(script.Zones)
local BossBar = require(script.UI.BossBar)
local ControlsUI = require(script.UI.Controls)
local HUD = require(script.UI.HUD)
local RoomsUI = require(script.UI.Rooms)
local ShopUI = require(script.UI.Shop)
local TouchButtons = require(script.UI.TouchButtons)

-- Cada parte arranca por separado: si una falla (sale en rojo en Output), las demás siguen
local parts = {
	Layout,
	Drones,
	LockOn,
	Staff,
	Powers,
	Dodge,
	Chispa,
	Fx,
	ControlsUI,
	HUD,
	TouchButtons,
	BossBar,
	Hub,
	Zones,
	Prompts,
	ShopUI,
	RoomsUI,
	Music,
}
for _, part in parts do
	task.spawn(function()
		local ok, err = pcall(part.Start)
		if not ok then
			warn("[Cliente] No arrancó una parte:", err)
		end
	end)
end
