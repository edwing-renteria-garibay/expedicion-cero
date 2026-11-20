-- El Nexo visto desde tu pantalla:
--   * el pedestal de la plaza enciende un hueco por cada llave de esta temporada que tienes
--     (atributos "Llave_1"... "Llave_7") y el letrero dice cuántas llevas
--   * las llaves escondidas giran despacio (solo en tu pantalla: el servidor no las mueve)
-- Cada jugador ve SU progreso.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Keys = require(ReplicatedStorage.Shared.Config.Keys)

local player = Players.LocalPlayer

local Hub = {}

local function refresh()
	local plaza = workspace:FindFirstChild("PuertoEco")
	if not plaza then
		return
	end
	local count = 0
	for i = 1, Keys.count do
		local lit = player:GetAttribute("Llave_" .. i) == true
		if lit then
			count += 1
		end
		local hole = plaza:FindFirstChild("Hueco" .. i) :: BasePart?
		if hole then
			hole.Color = if lit then Keys.colors[i] else Color3.fromRGB(70, 74, 82)
			hole.Material = if lit then Enum.Material.Neon else Enum.Material.Glass
			hole.Transparency = if lit then 0 else 0.3
		end
	end
	local heart = plaza:FindFirstChild("Corazon") :: BasePart?
	if heart then
		heart.Transparency = 0.6 - 0.6 * count / Keys.count
	end
	local pedestal = plaza:FindFirstChild("Pedestal")
	local gui = pedestal and pedestal:FindFirstChildOfClass("BillboardGui")
	local subtitle = gui and gui:FindFirstChild("Subtitulo") :: TextLabel?
	if subtitle then
		subtitle.Text = `{count} de {Keys.count}`
	end
end

-- Las llaves giran y suben y bajan un poco
local function spin()
	local base: { [Model]: CFrame } = setmetatable({}, { __mode = "k" }) :: any
	RunService.RenderStepped:Connect(function()
		local t = os.clock()
		for _, key in CollectionService:GetTagged("Llave") do
			if key:IsA("Model") then
				local start = base[key]
				if not start then
					start = key:GetPivot()
					base[key] = start
				end
				key:PivotTo(start * CFrame.new(0, math.sin(t * 2) * 0.4, 0) * CFrame.Angles(0, t * 1.5, 0))
			end
		end
	end)
end

function Hub.Start()
	spin()
	workspace:WaitForChild("PuertoEco", 30)
	refresh()
	player:GetAttributeChangedSignal("Llaves"):Connect(refresh)
end

return Hub
