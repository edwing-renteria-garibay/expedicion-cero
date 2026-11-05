-- Esconde en TU pantalla los avisos de cosas que ya tomaste (cofres, el gran cofre, el núcleo),
-- para que no parezca que todavía hay algo ahí.
--
-- Cada aviso (ProximityPrompt) que se puede esconder tiene el atributo OcultarSi con el nombre
-- de un atributo del jugador (por ejemplo "Cofre_CofrePlaya" o "Empuje"). Si tú lo tienes, el
-- aviso se apaga solo para ti. Además:
--   * si el cofre tiene tapa ("Tapa"), se ve abierto
--   * con el atributo EsconderPieza, la pieza desaparece (por ejemplo, el núcleo)

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
		if prompt:GetAttribute("EsconderPieza") and piece and piece:IsA("BasePart") then
			piece.LocalTransparencyModifier = 1
			local light = piece:FindFirstChildOfClass("PointLight")
			if light then
				light.Enabled = false
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
