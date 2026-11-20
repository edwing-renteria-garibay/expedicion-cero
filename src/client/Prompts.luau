-- Esconde en TU pantalla los avisos de cosas que ya tomaste (cofres, el gran cofre, las llaves),
-- para que no parezca que todavía hay algo ahí.
--
-- Cada aviso (ProximityPrompt) que se puede esconder tiene el atributo OcultarSi con el nombre
-- de un atributo del jugador (por ejemplo "Cofre_CofrePlaya" o "Empuje"). Si tú lo tienes, el
-- aviso se apaga solo para ti. Además:
--   * si el cofre tiene tapa ("Tapa"), se ve abierto
--   * con el atributo EsconderPieza, la pieza desaparece; con EsconderPieza = "Modelo",
--     desaparece todo el modelo (por ejemplo, una llave)

local Players = game:GetService("Players")

local player = Players.LocalPlayer

local Prompts = {}

local watched: { ProximityPrompt } = {}
local opened: { [Instance]: boolean } = setmetatable({}, { __mode = "k" }) :: any

local function openLid(prompt: ProximityPrompt)
	local model = prompt:FindFirstAncestorOfClass("Model")
	local lid = model and model:FindFirstChild("Tapa") :: BasePart?
	if not lid or opened[lid] then
		return
	end
	opened[lid] = true
	-- Gira la tapa hacia atrás desde su orilla
	local back = lid.CFrame * CFrame.new(0, 0, lid.Size.Z / 2)
	lid.CFrame = back * CFrame.Angles(math.rad(-100), 0, 0) * CFrame.new(0, 0, -lid.Size.Z / 2)
end

local function refresh(prompt: ProximityPrompt)
	local key = prompt:GetAttribute("OcultarSi")
	if typeof(key) ~= "string" then
		return
	end
	local taken = player:GetAttribute(key) == true
	prompt.Enabled = not taken
	if taken then
		openLid(prompt)
		local piece = prompt.Parent
		local hide = prompt:GetAttribute("EsconderPieza")
		local whole = if hide == "Modelo" and piece then piece:FindFirstAncestorOfClass("Model") else nil
		local pieces = if whole then whole:GetDescendants() elseif hide and piece then { piece } else {}
		for _, item in pieces do
			if item:IsA("BasePart") then
				item.LocalTransparencyModifier = 1
			end
			for _, effect in item:GetChildren() do
				if effect:IsA("PointLight") or effect:IsA("ParticleEmitter") then
					effect.Enabled = false
				end
			end
		end
	end
end

local function track(item: Instance)
	if item:IsA("ProximityPrompt") then
		table.insert(watched, item)
		-- El atributo puede llegar un instante después que el aviso
		task.defer(refresh, item)
	end
end

function Prompts.Start()
	workspace.DescendantAdded:Connect(track)
	for _, item in workspace:GetDescendants() do
		track(item)
	end
	player.AttributeChanged:Connect(function()
		for i = #watched, 1, -1 do
			local prompt = watched[i]
			if prompt.Parent then
				refresh(prompt)
			else
				table.remove(watched, i)
			end
		end
	end)
end

return Prompts
