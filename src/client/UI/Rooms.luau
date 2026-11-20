-- El menú SALAS (RoomService): crear una sala privada para jugar con tus amigos, entrar a la de
-- un amigo con su código de 6 números, o volver a un servidor público. En la sala se ve su código.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Layout = require(script.Parent.Parent.Layout)
local Menus = require(script.Parent.Parent.Menus)

local roomRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Room") :: RemoteEvent
local player = Players.LocalPlayer

local RoomsUI = {}

local BACKGROUND = Color3.fromRGB(24, 36, 54)
local GOLD = Color3.fromRGB(255, 205, 70)

local function corner(target: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = target
end

local function label(parent: Instance, text: string, height: number, size: number, order: number): TextLabel
	local l = Instance.new("TextLabel")
	l.LayoutOrder = order
	l.BackgroundTransparency = 1
	l.Size = UDim2.new(1, 0, 0, height)
	l.Font = Enum.Font.GothamBold
	l.Text = text
	l.TextSize = size
	l.TextWrapped = true
	l.TextColor3 = Color3.new(1, 1, 1)
	l.Parent = parent
	return l
end

local function button(parent: Instance, text: string, color: Color3, order: number): TextButton
	local b = Instance.new("TextButton")
	b.LayoutOrder = order
	b.Size = UDim2.new(1, 0, 0, 44)
	b.BackgroundColor3 = color
	b.Font = Enum.Font.GothamBlack
	b.Text = text
	b.TextSize = 17
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Parent = parent
	corner(b, 10)
	return b
end

function RoomsUI.Start()
	local gui = Instance.new("ScreenGui")
	gui.Name = "Salas"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 6
	gui.Parent = player:WaitForChild("PlayerGui")

	local open = Instance.new("TextButton")
	open.Size = UDim2.fromOffset(130, 44)
	open.BackgroundColor3 = Color3.fromRGB(120, 70, 170)
	open.Font = Enum.Font.FredokaOne
	open.Text = "SALAS"
	open.TextSize = 18
	open.TextColor3 = Color3.new(1, 1, 1)
	corner(open, 10)
	Layout.Dock(open, 3)

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromOffset(380, 0)
	panel.AutomaticSize = Enum.AutomaticSize.Y
	panel.BackgroundColor3 = BACKGROUND
	panel.Visible = false
	panel.Parent = gui
	corner(panel, 12)
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 16)
	padding.PaddingRight = UDim.new(0, 16)
	padding.PaddingTop = UDim.new(0, 12)
	padding.PaddingBottom = UDim.new(0, 16)
	padding.Parent = panel
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = panel

	local title = label(panel, "Salas", 34, 24, 1)
	title.Font = Enum.Font.GothamBlack
	title.TextXAlignment = Enum.TextXAlignment.Left
	local close = Instance.new("TextButton")
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, 0, 0, 0)
	close.Size = UDim2.fromOffset(34, 34)
	close.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
	close.Font = Enum.Font.GothamBlack
	close.Text = "X"
	close.TextSize = 18
	close.TextColor3 = Color3.new(1, 1, 1)
	close.Parent = title
	corner(close, 8)
	Menus.Register(close)

	local where = label(panel, "", 40, 15, 2)
	local code = label(panel, "", 40, 30, 3)
	code.Font = Enum.Font.GothamBlack
	code.TextColor3 = GOLD
	local create = button(panel, "CREAR SALA PRIVADA", Color3.fromRGB(120, 70, 170), 4)
	local box = Instance.new("TextBox")
	box.LayoutOrder = 5
	box.Size = UDim2.new(1, 0, 0, 44)
	box.BackgroundColor3 = Color3.fromRGB(36, 52, 76)
	box.Font = Enum.Font.GothamBlack
	box.PlaceholderText = "Código de tu amigo (6 números)"
	box.Text = ""
	box.TextSize = 18
	box.TextColor3 = Color3.new(1, 1, 1)
	box.ClearTextOnFocus = false
	box.Parent = panel
	corner(box, 10)
	local join = button(panel, "UNIRSE CON CÓDIGO", Color3.fromRGB(60, 120, 200), 6)
	local leave = button(panel, "SALIR A UN SERVIDOR PÚBLICO", Color3.fromRGB(90, 96, 110), 7)
	local status = label(panel, "", 22, 14, 8)
	status.TextColor3 = Color3.fromRGB(255, 120, 100)

	local function refresh()
		local kind = ReplicatedStorage:GetAttribute("ServerKind")
		local private = kind == "private" or kind == "loading"
		local roomCode = ReplicatedStorage:GetAttribute("RoomCode")
		if private then
			where.Text =
				"Estás en una sala privada. Tus amigos entran con este código (en SALAS, Unirse con código):"
			code.Text = roomCode or "..."
		else
			where.Text =
				"Estás en un servidor público. Crea una sala para jugar solo con tus amigos (tus cristales, corazones y poderes van contigo)."
			code.Text = ""
		end
		code.Visible = private
		create.Visible = not private
		leave.Visible = private
	end
	refresh()
	ReplicatedStorage:GetAttributeChangedSignal("ServerKind"):Connect(refresh)
	ReplicatedStorage:GetAttributeChangedSignal("RoomCode"):Connect(refresh)

	open.Activated:Connect(function()
		panel.Visible = not panel.Visible
		status.Text = ""
	end)
	close.Activated:Connect(function()
		panel.Visible = false
	end)
	create.Activated:Connect(function()
		status.Text = "Creando la sala..."
		roomRemote:FireServer("create")
	end)
	join.Activated:Connect(function()
		local digits = box.Text:gsub("%D", "")
		status.Text = "Buscando la sala..."
		roomRemote:FireServer("join", digits)
	end)
	leave.Activated:Connect(function()
		status.Text = "Buscando un servidor público..."
		roomRemote:FireServer("leave")
	end)
	roomRemote.OnClientEvent:Connect(function(kind: string, message: string?)
		if kind == "teleporting" then
			status.TextColor3 = Color3.fromRGB(120, 230, 120)
			status.Text = "Cambiando de servidor..."
		elseif kind == "error" then
			status.TextColor3 = Color3.fromRGB(255, 120, 100)
			status.Text = message or "Algo falló"
			panel.Visible = true
		end
	end)
end

return RoomsUI
