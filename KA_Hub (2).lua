-- KA Hub | Kaiju Alpha
-- Secciones: Macro (spam de ataques), Autofarm (ciudad), Misc (Anti-AFK, rejoin, etc.)

local SRC = [==[
if getgenv().KA_UNLOAD then pcall(getgenv().KA_UNLOAD) end

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local VU = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local Stats = game:GetService("Stats")
local Lighting = game:GetService("Lighting")
local lp = Players.LocalPlayer

if not game:IsLoaded() then game.Loaded:Wait() end

local running = true
local conns = {}
local state = {
    Macro = false, Farm = false, ByBuilding = true, Noclip = false,
    AntiAFK = true, Rejoin = true, AutoExec = false, Low = false,
}
local cfg = {Distance = 25, Height = 8, Timeout = 2, Delay = 250}
local selected = {true, true, true, true}
local visited = setmetatable({}, {__mode = "k"})
local center
local fps = 0
local fpsHook -- se llena con la interfaz

-- ===== Utilidades del juego =====
local combat = RS:FindFirstChild("CombatRemote", true)

local function useSkill(n)
    if not combat then return end
    pcall(function()
        if combat:IsA("RemoteFunction") then
            combat:InvokeServer("UseSkill", "Attack" .. n)
        else
            combat:FireServer("UseSkill", "Attack" .. n)
        end
    end)
end

local function cityCenter()
    local map = workspace:FindFirstChild("Map")
    local folder = map and map:FindFirstChild("CityFolder")
    if not folder then return end
    local sum, n = Vector3.zero, 0
    for _, d in ipairs(folder:GetDescendants()) do
        if d:IsA("BasePart") then sum += d.Position; n += 1 end
    end
    if n > 0 then return sum / n end
end

local function collectTargets()
    local map = workspace:FindFirstChild("Map")
    local folder = map and map:FindFirstChild("CityFolder")
    local list = {}
    if not folder then return list end
    for _, d in ipairs(folder:GetDescendants()) do
        if d:IsA("Model") and not d:FindFirstChildWhichIsA("Model")
            and d:FindFirstChildWhichIsA("BasePart") then
            list[#list + 1] = d
        end
    end
    if #list == 0 then
        for _, d in ipairs(folder:GetDescendants()) do
            if d:IsA("BasePart") and d.Size.Magnitude > 20 then
                list[#list + 1] = d
            end
        end
    end
    return list
end

local function posOf(t)
    return t:IsA("Model") and t:GetPivot().Position or t.Position
end

local function nextTarget(list, from)
    local best, bd
    for i = #list, 1, -1 do
        local t = list[i]
        if not t.Parent then
            table.remove(list, i)
        elseif not visited[t] then
            local d = (posOf(t) - from).Magnitude
            if not bd or d < bd then best, bd = t, d end
        end
    end
    return best
end

-- ===== Anti-AFK =====
conns[#conns + 1] = lp.Idled:Connect(function()
    if state.AntiAFK then
        VU:CaptureController()
        VU:ClickButton2(Vector2.new())
    end
end)

-- ===== Auto Rejoin =====
task.spawn(function()
    pcall(function()
        local g = CoreGui:WaitForChild("RobloxPromptGui", 10)
        local ov = g and g:WaitForChild("promptOverlay", 10)
        if ov then
            conns[#conns + 1] = ov.ChildAdded:Connect(function(c)
                if state.Rejoin and c.Name == "ErrorPrompt" then
                    task.wait(2)
                    TeleportService:Teleport(game.PlaceId, lp)
                end
            end)
        end
    end)
end)

-- ===== Noclip =====
conns[#conns + 1] = RunService.Stepped:Connect(function()
    if state.Noclip and lp.Character then
        for _, p in ipairs(lp.Character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
end)

-- ===== Autofarm =====
task.spawn(function()
    local targets, target, t0 = nil, nil, 0
    while running do
        local char = lp.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if state.Farm and hrp then
            if state.ByBuilding then
                targets = targets or collectTargets()
                if not target or not target.Parent or os.clock() - t0 > cfg.Timeout then
                    if target then visited[target] = true end
                    target = nextTarget(targets, hrp.Position)
                    t0 = os.clock()
                    if not target then
                        table.clear(visited)
                        targets = nil
                        task.wait(1)
                    end
                end
                if target and target.Parent then
                    local p = posOf(target)
                    local flat = Vector3.new(hrp.Position.X - p.X, 0, hrp.Position.Z - p.Z).Magnitude
                    if flat > cfg.Distance + 15 or math.abs(hrp.Position.Y - (p.Y + cfg.Height)) > 40 then
                        local pos = p + Vector3.new(cfg.Distance, cfg.Height, 0)
                        char:PivotTo(CFrame.lookAt(pos, Vector3.new(p.X, pos.Y, p.Z)))
                    else
                        hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(p.X, hrp.Position.Y, p.Z))
                    end
                    task.spawn(useSkill, 3)
                end
            else
                center = center or cityCenter()
                if center and (hrp.Position - center).Magnitude > 40 then
                    char:PivotTo(CFrame.new(center + Vector3.new(0, 15, 0)))
                end
                task.spawn(useSkill, 3)
            end
        end
        task.wait(0.25)
    end
end)

-- ===== Macro (ataques elegidos) =====
task.spawn(function()
    while running do
        if state.Macro then
            for i = 1, 4 do
                if selected[i] then task.spawn(useSkill, i) end
            end
        end
        task.wait(cfg.Delay / 1000)
    end
end)

-- ===== Interfaz =====
local gui = Instance.new("ScreenGui")
gui.Name = "KAHub"
gui.ResetOnSpawn = false
gui.Parent = (gethui and gethui()) or CoreGui

local BG, TOP = Color3.fromRGB(22, 22, 28), Color3.fromRGB(35, 35, 48)
local OFF, ON = Color3.fromRGB(55, 55, 65), Color3.fromRGB(40, 150, 80)
local ACC = Color3.fromRGB(70, 110, 220)
local WHITE = Color3.new(1, 1, 1)

local function corner(o, r) Instance.new("UICorner", o).CornerRadius = UDim.new(0, r or 6) end

-- Marca de agua
local mark = Instance.new("TextLabel")
mark.Size = UDim2.fromOffset(320, 18)
mark.Position = UDim2.new(0, 12, 0, 4)
mark.BackgroundTransparency = 1
mark.TextColor3 = WHITE
mark.TextStrokeTransparency = 0.5
mark.TextXAlignment = Enum.TextXAlignment.Left
mark.Font = Enum.Font.GothamMedium
mark.TextSize = 12
mark.Parent = gui

-- Bienvenida
local splash = Instance.new("Frame")
splash.Size = UDim2.fromOffset(270, 120)
splash.AnchorPoint = Vector2.new(0.5, 0.5)
splash.Position = UDim2.new(0.5, 0, 0.5, 0)
splash.BackgroundColor3 = BG
splash.BorderSizePixel = 0
splash.Parent = gui
corner(splash, 10)

local function splashLabel(text, y, size, font, color)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -20, 0, size + 6)
    l.Position = UDim2.new(0, 10, 0, y)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = color or WHITE
    l.Font = font
    l.TextSize = size
    l.Parent = splash
    return l
end
splashLabel("KA Hub | Kaiju Alpha", 12, 18, Enum.Font.GothamBold)
splashLabel("Bienvenido, " .. lp.DisplayName, 42, 15, Enum.Font.GothamMedium)
local splashFps = splashLabel("FPS: --", 70, 15, Enum.Font.GothamMedium, Color3.fromRGB(120, 220, 140))
splashLabel("Cargando menú...", 94, 12, Enum.Font.Gotham, Color3.fromRGB(150, 150, 170))

-- Ventana principal
local win = Instance.new("Frame")
win.Size = UDim2.fromOffset(240, 0)
win.AutomaticSize = Enum.AutomaticSize.Y
win.Position = UDim2.new(0, 12, 0.18, 0)
win.BackgroundColor3 = BG
win.BorderSizePixel = 0
win.Active = true
win.Visible = false
win.Parent = gui
corner(win, 8)
Instance.new("UIListLayout", win).SortOrder = Enum.SortOrder.LayoutOrder

local title = Instance.new("Frame")
title.Size = UDim2.new(1, 0, 0, 34)
title.BackgroundColor3 = TOP
title.BorderSizePixel = 0
title.LayoutOrder = 0
title.Parent = win
corner(title, 8)

local tl = Instance.new("TextLabel")
tl.Size = UDim2.new(1, -44, 1, 0)
tl.Position = UDim2.new(0, 10, 0, 0)
tl.BackgroundTransparency = 1
tl.Text = "KA Hub | Kaiju Alpha"
tl.TextColor3 = WHITE
tl.TextXAlignment = Enum.TextXAlignment.Left
tl.Font = Enum.Font.GothamBold
tl.TextSize = 14
tl.Parent = title

local content = Instance.new("Frame")
content.Size = UDim2.new(1, 0, 0, 0)
content.AutomaticSize = Enum.AutomaticSize.Y
content.BackgroundTransparency = 1
content.LayoutOrder = 1
content.Parent = win
Instance.new("UIListLayout", content).SortOrder = Enum.SortOrder.LayoutOrder

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.fromOffset(30, 26)
minBtn.Position = UDim2.new(1, -34, 0, 4)
minBtn.BackgroundColor3 = OFF
minBtn.Text = "-"
minBtn.TextColor3 = WHITE
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 16
minBtn.Parent = title
corner(minBtn)
minBtn.Activated:Connect(function()
    content.Visible = not content.Visible
    minBtn.Text = content.Visible and "-" or "+"
end)

-- Arrastrar
do
    local dragging, startPos, startInput
    title.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            dragging, startPos, startInput = true, win.Position, i.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    conns[#conns + 1] = UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
            or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - startInput
            win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

-- Pestañas
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -16, 0, 30)
tabBar.BackgroundTransparency = 1
tabBar.LayoutOrder = 0
tabBar.Parent = content
local tabPad = Instance.new("UIPadding", tabBar)
tabPad.PaddingLeft = UDim.new(0, 8)
tabPad.PaddingTop = UDim.new(0, 6)
local tabLayout = Instance.new("UIListLayout", tabBar)
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 4)

local holder = Instance.new("Frame")
holder.Size = UDim2.new(1, 0, 0, 0)
holder.AutomaticSize = Enum.AutomaticSize.Y
holder.BackgroundTransparency = 1
holder.LayoutOrder = 1
holder.Parent = content

local pages, tabBtns = {}, {}

local function show(name)
    for n, f in pairs(pages) do f.Parent = (n == name) and holder or nil end
    for n, b in pairs(tabBtns) do b.BackgroundColor3 = (n == name) and ACC or OFF end
end

local function newPage(name)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 0)
    f.AutomaticSize = Enum.AutomaticSize.Y
    f.BackgroundTransparency = 1
    local l = Instance.new("UIListLayout", f)
    l.Padding = UDim.new(0, 5)
    l.HorizontalAlignment = Enum.HorizontalAlignment.Center
    local p = Instance.new("UIPadding", f)
    p.PaddingTop = UDim.new(0, 6)
    p.PaddingBottom = UDim.new(0, 8)
    pages[name] = f

    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1 / 3, -3, 0, 24)
    b.BackgroundColor3 = OFF
    b.Text = name
    b.TextColor3 = WHITE
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 12
    b.Parent = tabBar
    corner(b)
    b.Activated:Connect(function() show(name) end)
    tabBtns[name] = b
    return f
end

-- Componentes
local function section(page, text)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -16, 0, 16)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.fromRGB(150, 150, 170)
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Font = Enum.Font.GothamMedium
    l.TextSize = 12
    l.Parent = page
end

local function button(page, text, color, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -16, 0, 32)
    b.BackgroundColor3 = color
    b.Text = text
    b.TextColor3 = WHITE
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 14
    b.Parent = page
    corner(b)
    b.Activated:Connect(function() cb(b) end)
    return b
end

local function toggle(page, name, key, onChange)
    local function label() return name .. ": " .. (state[key] and "ON" or "OFF") end
    return button(page, label(), state[key] and ON or OFF, function(btn)
        state[key] = not state[key]
        btn.Text = label()
        btn.BackgroundColor3 = state[key] and ON or OFF
        if onChange then onChange(state[key]) end
    end)
end

local function stepper(page, name, key, step, min, max)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -16, 0, 30)
    row.BackgroundTransparency = 1
    row.Parent = page
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -70, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = WHITE
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.Parent = row
    local function refresh() lbl.Text = name .. ": " .. cfg[key] end
    refresh()
    local function mk(txt, x, delta)
        local b = Instance.new("TextButton")
        b.Size = UDim2.fromOffset(32, 30)
        b.Position = UDim2.new(1, x, 0, 0)
        b.BackgroundColor3 = OFF
        b.Text = txt
        b.TextColor3 = WHITE
        b.Font = Enum.Font.GothamBold
        b.TextSize = 16
        b.Parent = row
        corner(b)
        b.Activated:Connect(function()
            cfg[key] = math.clamp(cfg[key] + delta, min, max)
            refresh()
        end)
    end
    mk("-", -68, -step)
    mk("+", -34, step)
end

local qot = queue_on_teleport or (syn and syn.queue_on_teleport)

-- ===== Sección: Macro =====
local pMacro = newPage("Macro")
section(pMacro, "SPAM DE ATAQUES")
toggle(pMacro, "Macro", "Macro")
do
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -16, 0, 30)
    row.BackgroundTransparency = 1
    row.Parent = pMacro
    local rl = Instance.new("UIListLayout", row)
    rl.FillDirection = Enum.FillDirection.Horizontal
    rl.Padding = UDim.new(0, 4)
    for i = 1, 4 do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0.25, -3, 1, 0)
        b.BackgroundColor3 = selected[i] and ON or OFF
        b.Text = "Atq " .. i
        b.TextColor3 = WHITE
        b.Font = Enum.Font.GothamMedium
        b.TextSize = 12
        b.Parent = row
        corner(b)
        b.Activated:Connect(function()
            selected[i] = not selected[i]
            b.BackgroundColor3 = selected[i] and ON or OFF
        end)
    end
end
stepper(pMacro, "Delay (ms)", "Delay", 50, 50, 1000)

-- ===== Sección: Autofarm =====
local pFarm = newPage("Autofarm")
section(pFarm, "CIUDAD")
toggle(pFarm, "Auto Farm City", "Farm", function()
    center = nil
    table.clear(visited)
end)
toggle(pFarm, "Modo edificios", "ByBuilding")
stepper(pFarm, "Distancia", "Distance", 5, 5, 80)
stepper(pFarm, "Altura", "Height", 4, 0, 40)
stepper(pFarm, "Seg. por objetivo", "Timeout", 1, 1, 10)

-- ===== Sección: Misc =====
local pMisc = newPage("Misc")
section(pMisc, "SISTEMA")
toggle(pMisc, "Anti-AFK", "AntiAFK")
toggle(pMisc, "Auto Rejoin", "Rejoin")
toggle(pMisc, "Auto Execute", "AutoExec", function(on)
    if on and qot then pcall(qot, getgenv().KA_SRC or "") end
end)
toggle(pMisc, "Noclip", "Noclip")
toggle(pMisc, "Modo bajo consumo", "Low", function(on)
    pcall(function() RunService:Set3dRenderingEnabled(not on) end)
    pcall(function() settings().Rendering.QualityLevel = on and 1 or 10 end)
    Lighting.GlobalShadows = not on
end)

local function unload()
    running = false
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    pcall(function() RunService:Set3dRenderingEnabled(true) end)
    gui:Destroy()
    getgenv().KA_UNLOAD = nil
end
getgenv().KA_UNLOAD = unload
section(pMisc, "")
button(pMisc, "Descargar script", Color3.fromRGB(160, 45, 45), function() unload() end)

show("Macro")

-- ===== FPS / marca de agua =====
local frames, last = 0, os.clock()
conns[#conns + 1] = RunService.Heartbeat:Connect(function()
    frames += 1
    if os.clock() - last >= 1 then
        fps = frames
        frames, last = 0, os.clock()
        if splash and splash.Parent then splashFps.Text = "FPS: " .. fps end
        local ping = 0
        pcall(function()
            ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        local ls = lp:FindFirstChild("leaderstats")
        local cells = ls and ls:FindFirstChild("Cells") and tostring(ls.Cells.Value) or "?"
        local kills = ls and ls:FindFirstChild("Kills") and tostring(ls.Kills.Value) or "?"
        mark.Text = ("KA | Cells %s | Kills %s | %d FPS | %d ms"):format(cells, kills, fps, ping)
    end
end)

-- Cerrar la bienvenida y mostrar el menú
task.delay(3.5, function()
    if not running then return end
    splash:Destroy()
    win.Visible = true
end)
]==]

getgenv().KA_SRC = SRC
loadstring(SRC)()
