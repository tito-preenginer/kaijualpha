-- KA Hub | Kaiju Alpha
-- Funciones: Auto Farm City, Spam Skills 1-4, Noclip, Anti-AFK, Auto Rejoin,
-- Auto Execute, Modo bajo consumo, Marca de agua, Descargar script

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
    Farm = false, Skills = false, Noclip = false,
    AntiAFK = true, Rejoin = true, AutoExec = false, Low = false,
}
local center

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
        local gui = CoreGui:WaitForChild("RobloxPromptGui", 10)
        local ov = gui and gui:WaitForChild("promptOverlay", 10)
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

-- ===== Bucle principal =====
task.spawn(function()
    while running do
        local char = lp.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if state.Farm and hrp then
            center = center or cityCenter()
            if center and (hrp.Position - center).Magnitude > 40 then
                char:PivotTo(CFrame.new(center + Vector3.new(0, 15, 0)))
            end
            task.spawn(useSkill, 3)
        end
        if state.Skills then
            for i = 1, 4 do task.spawn(useSkill, i) end
        end
        task.wait(0.25)
    end
end)

-- ===== Interfaz =====
local gui = Instance.new("ScreenGui")
gui.Name = "KAHub"
gui.ResetOnSpawn = false
gui.Parent = (gethui and gethui()) or CoreGui

local BG, TOP = Color3.fromRGB(22, 22, 28), Color3.fromRGB(35, 35, 48)
local OFF, ON = Color3.fromRGB(55, 55, 65), Color3.fromRGB(40, 150, 80)

local win = Instance.new("Frame")
win.Size = UDim2.fromOffset(230, 0)
win.AutomaticSize = Enum.AutomaticSize.Y
win.Position = UDim2.new(0, 12, 0.18, 0)
win.BackgroundColor3 = BG
win.BorderSizePixel = 0
win.Active = true
win.Parent = gui
Instance.new("UICorner", win).CornerRadius = UDim.new(0, 8)

local winLayout = Instance.new("UIListLayout", win)
winLayout.SortOrder = Enum.SortOrder.LayoutOrder

local title = Instance.new("Frame")
title.Size = UDim2.new(1, 0, 0, 34)
title.BackgroundColor3 = TOP
title.BorderSizePixel = 0
title.LayoutOrder = 0
title.Parent = win
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)

local tl = Instance.new("TextLabel")
tl.Size = UDim2.new(1, -44, 1, 0)
tl.Position = UDim2.new(0, 10, 0, 0)
tl.BackgroundTransparency = 1
tl.Text = "KA Hub | Kaiju Alpha"
tl.TextColor3 = Color3.new(1, 1, 1)
tl.TextXAlignment = Enum.TextXAlignment.Left
tl.Font = Enum.Font.GothamBold
tl.TextSize = 14
tl.Parent = title

local body = Instance.new("Frame")
body.Size = UDim2.new(1, 0, 0, 0)
body.AutomaticSize = Enum.AutomaticSize.Y
body.BackgroundTransparency = 1
body.LayoutOrder = 1
body.Parent = win
local bl = Instance.new("UIListLayout", body)
bl.Padding = UDim.new(0, 5)
bl.HorizontalAlignment = Enum.HorizontalAlignment.Center
local bp = Instance.new("UIPadding", body)
bp.PaddingTop = UDim.new(0, 6)
bp.PaddingBottom = UDim.new(0, 8)

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.fromOffset(30, 26)
minBtn.Position = UDim2.new(1, -34, 0, 4)
minBtn.BackgroundColor3 = OFF
minBtn.Text = "-"
minBtn.TextColor3 = Color3.new(1, 1, 1)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 16
minBtn.Parent = title
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)
minBtn.Activated:Connect(function()
    body.Visible = not body.Visible
    minBtn.Text = body.Visible and "-" or "+"
end)

-- Arrastrar (PC y celular)
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

local function section(text)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -16, 0, 16)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.fromRGB(150, 150, 170)
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Font = Enum.Font.GothamMedium
    l.TextSize = 12
    l.Parent = body
end

local function button(text, color, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -16, 0, 32)
    b.BackgroundColor3 = color
    b.Text = text
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 14
    b.Parent = body
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    b.Activated:Connect(function() cb(b) end)
    return b
end

local function toggle(name, key, onChange)
    local function label() return name .. ": " .. (state[key] and "ON" or "OFF") end
    local b = button(label(), state[key] and ON or OFF, function(btn)
        state[key] = not state[key]
        btn.Text = label()
        btn.BackgroundColor3 = state[key] and ON or OFF
        if onChange then onChange(state[key]) end
    end)
    return b
end

local qot = queue_on_teleport or (syn and syn.queue_on_teleport)

section("FARM")
toggle("Auto Farm City", "Farm", function() center = nil end)
toggle("Spam Skills 1-4", "Skills")
toggle("Noclip", "Noclip")

section("SISTEMA")
toggle("Anti-AFK", "AntiAFK")
toggle("Auto Rejoin", "Rejoin")
toggle("Auto Execute", "AutoExec", function(on)
    if on and qot then
        pcall(qot, getgenv().KA_SRC or "")
    end
end)
toggle("Modo bajo consumo", "Low", function(on)
    pcall(function() RunService:Set3dRenderingEnabled(not on) end)
    pcall(function() settings().Rendering.QualityLevel = on and 1 or 10 end)
    Lighting.GlobalShadows = not on
end)

-- ===== Marca de agua =====
local mark = Instance.new("TextLabel")
mark.Size = UDim2.fromOffset(320, 18)
mark.Position = UDim2.new(0, 12, 0, 4)
mark.BackgroundTransparency = 1
mark.TextColor3 = Color3.new(1, 1, 1)
mark.TextStrokeTransparency = 0.5
mark.TextXAlignment = Enum.TextXAlignment.Left
mark.Font = Enum.Font.GothamMedium
mark.TextSize = 12
mark.Parent = gui

local frames, last = 0, os.clock()
conns[#conns + 1] = RunService.Heartbeat:Connect(function()
    frames += 1
    if os.clock() - last >= 1 then
        local fps = frames
        frames, last = 0, os.clock()
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

-- ===== Descargar =====
local function unload()
    running = false
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    pcall(function() RunService:Set3dRenderingEnabled(true) end)
    gui:Destroy()
    getgenv().KA_UNLOAD = nil
end
getgenv().KA_UNLOAD = unload
section("")
button("Descargar script", Color3.fromRGB(160, 45, 45), function() unload() end)
]==]

getgenv().KA_SRC = SRC
loadstring(SRC)()
