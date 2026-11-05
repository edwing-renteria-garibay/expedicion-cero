-- Lo que el servidor avisa por el remote Fx:
--   "Hit"   (posición, daño)   -> chispas y un número de daño que sube y se desvanece
--   "Swing" (personaje, golpe) -> la animación del golpe de OTRO jugador
--   "Dodge" (personaje)        -> la rodada de otro jugador
--   "Zap"   (jugador, posición) -> el rayito de su Chispa
--   "Say"   (frase)            -> Chispa dice algo (Config/Drone)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Chispa = require(script.Parent.Chispa)
local Drones = require(script.Parent.Drones)
local Sfx = require(script.Parent.Sfx)
local Swing = require(script.Parent.Swing)

local fx = ReplicatedStorage.Remotes.Fx :: RemoteEvent

local Fx = {}

local SPARK = Color3.fromRGB(255, 230, 120)

local folder: Folder

local function damageNumber(position: Vector3, amount: number)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one * 0.2
	anchor.Position = position + Vector3.new(math.random() * 2 - 1, 2.5, math.random() * 2 - 1)
	anchor.Parent = folder
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(70, 34)
	gui.AlwaysOnTop = true
	gui.Parent = anchor
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.Text = tostring(math.floor(amount + 0.5))
	label.TextScaled = true
	label.TextColor3 = if amount >= 30 then Color3.fromRGB(255, 150, 60) else Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.2
	label.Parent = gui
	local info = TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(anchor, info, { Position = anchor.Position + Vector3.new(0, 3, 0) }):Play()
	TweenService:Create(label, info, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(0.75, function()
		anchor:Destroy()
	end)
end

local function sparks(position: Vector3)
	for _ = 1, 6 do
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Material = Enum.Material.Neon
		p.Color = SPARK
		p.Shape = Enum.PartType.Ball
		p.Size = Vector3.one * 0.4
		p.Position = position
		p.Parent = folder
		local direction = Vector3.new(math.random() - 0.5, math.random() * 0.8, math.random() - 0.5).Unit
		local tween = TweenService:Create(p, TweenInfo.new(0.25), {
			Position = position + direction * 3,
			Size = Vector3.one * 0.05,
			Transparency = 1,
		})
		tween:Play()
		tween.Completed:Once(function()
			p:Destroy()
		end)
	end
end

function Fx.Start()
	folder = Instance.new("Folder")
	folder.Name = "Efectos"
	folder.Parent = workspace
	fx.OnClientEvent:Connect(function(kind: string, a: any, b: any)
		if kind == "Hit" and typeof(a) == "Vector3" then
			sparks(a)
			damageNumber(a, b)
			Sfx.Play("hit")
		elseif kind == "Swing" and typeof(a) == "Instance" and a:IsA("Model") then
			Swing.Play(a, b)
		elseif kind == "Dodge" and typeof(a) == "Instance" and a:IsA("Model") then
			Swing.Roll(a)
		elseif kind == "Zap" and typeof(a) == "Instance" and a:IsA("Player") then
			Drones.Zap(a, b)
			if a == Players.LocalPlayer then
				Sfx.Play("zap")
			end
		elseif kind == "Say" then
			Chispa.Say(a)
		end
	end)
end

return Fx
