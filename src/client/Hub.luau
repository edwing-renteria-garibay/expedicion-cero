-- El pedestal de la plaza de Puerto Eco, visto desde tu pantalla: cada núcleo que recuperaste
-- (atributo "Nucleos") enciende uno de los cuatro huecos y el letrero dice cuántos llevas.
-- Cada jugador ve SU progreso.

local Players = game:GetService("Players")

local player = Players.LocalPlayer

local Hub = {}

-- El color de cada núcleo, en el orden de los huecos: Selva, Volcán, Glaciar, Ruinas
local COLORS = {
	Color3.fromRGB(90, 255, 120),
	Color3.fromRGB(255, 120, 40),
	Color3.fromRGB(120, 220, 255),
	Color3.fromRGB(190, 120, 255),
}

local function refresh()
	local plaza = workspace:FindFirstChild("PuertoEco")
	if not plaza then
		return
	end
	local count = player:GetAttribute("Nucleos") or 0
	for i = 1, 4 do
		local hole = plaza:FindFirstChild("Hueco" .. i) :: BasePart?
		if hole then
			local lit = i <= count
			hole.Color = if lit then COLORS[i] else Color3.fromRGB(70, 74, 82)
			hole.Material = if lit then Enum.Material.Neon else Enum.Material.Glass
			hole.Transparency = if lit then 0 else 0.3
		end
	end
	local heart = plaza:FindFirstChild("Corazon") :: BasePart?
	if heart then
		heart.Transparency = 0.6 - 0.12 * count
	end
	local pedestal = plaza:FindFirstChild("Pedestal")
	local gui = pedestal and pedestal:FindFirstChildOfClass("BillboardGui")
	local subtitle = gui and gui:FindFirstChild("Subtitulo") :: TextLabel?
	if subtitle then
		subtitle.Text = `{count} de 4`
	end
end

function Hub.Start()
	workspace:WaitForChild("PuertoEco", 30)
	refresh()
	player:GetAttributeChangedSignal("Nucleos"):Connect(refresh)
end

return Hub
