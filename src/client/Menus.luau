-- Los menús (tienda, taller, salas). Cada menú registra aquí su botón X: Roblox suelta el mouse
-- mientras se ve un botón con Modal = true, y con control se selecciona para moverse por el
-- menú (Layout). El bastón no golpea mientras hay un menú abierto (Staff pregunta AnyOpen).

local Menus = {}

local buttons: { GuiButton } = {}
local others: { [string]: boolean } = {} -- ventanas que no son nuestras (la de invitar de Roblox)

function Menus.Register(button: GuiButton)
	button.Modal = true
	table.insert(buttons, button)
end

-- ¿Se ve en la pantalla? (él y todo lo que lo contiene)
local function shown(gui: Instance?): boolean
	while gui do
		if gui:IsA("GuiObject") and not gui.Visible then
			return false
		elseif gui:IsA("ScreenGui") then
			return gui.Enabled
		end
		gui = gui.Parent
	end
	return false
end

-- Para una ventana de Roblox que no tiene botón nuestro: mientras open sea true, cuenta como
-- menú abierto (el mouse queda libre)
function Menus.SetOpen(name: string, open: boolean)
	others[name] = if open then true else nil
end

-- El botón (la X) del primer menú abierto, o nil: con control, se selecciona para moverse
-- por el menú con el stick
function Menus.FirstOpen(): GuiButton?
	for _, button in buttons do
		if shown(button) then
			return button
		end
	end
	return nil
end

function Menus.AnyOpen(): boolean
	if next(others) then
		return true
	end
	for _, button in buttons do
		if shown(button) then
			return true
		end
	end
	return false
end

return Menus
