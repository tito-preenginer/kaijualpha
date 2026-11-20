-- KA Hub | Kaiju Alpha
-- Pestañas: Macro, Farm, Misc, Webhook
-- Guarda configuración, calibra el rango solo, webhook de Discord, ES/EN,
-- reclamo de misiones (aprendido) y accesos a Event Shop / Battle Pass.

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
local HttpService = game:GetService("HttpService")
local lp = Players.LocalPlayer

if not game:IsLoaded() then game.Loaded:Wait() end

-- ===== Configuración guardada =====
local FILE = "KA_Hub_Config.json"
local saved = {}
pcall(function()
    if isfile and readfile and isfile(FILE) then
        saved = HttpService:JSONDecode(readfile(FILE))
    end
end)
if type(saved) ~= "table" then saved = {} end

local running = true
local conns = {}
local state = {
    Macro = false, Farm = false, Zone = true, ByBuilding = true, Noclip = false,
    AntiAFK = true, Rejoin = true, AutoExec = false, Low = false,
    AutoCalib = true, AutoQuest = false, Webhook = false, Calibrating = false, NoCD = false,
}
local cfg = {
    Distance = 25, Height = 8, Timeout = 2, Delay = 250, Range = 60,
    QuestEvery = 60, WebhookMin = 10,
}
local selected = {true, true, true, true}
local rangeStore = {}
local wh = {url = ""}
local learned = {}
local lang = "es"

for k, v in pairs(saved.state or {}) do
    if state[k] ~= nil and type(v) == "boolean" and k ~= "Low" and k ~= "Calibrating" then
        state[k] = v
    end
end
for k, v in pairs(saved.cfg or {}) do
    if cfg[k] ~= nil and type(v) == "number" then cfg[k] = v end
end
if type(saved.selected) == "table" then
    for i = 1, 4 do
        if type(saved.selected[i]) == "boolean" then selected[i] = saved.selected[i] end
    end
end
if type(saved.ranges) == "table" then
    for k, v in pairs(saved.ranges) do
        if type(v) == "number" then rangeStore[k] = v end
    end
end
if type(saved.webhook) == "table" and type(saved.webhook.url) == "string" then
    wh.url = saved.webhook.url
end
if type(saved.learned) == "table" then learned = saved.learned end
if saved.lang == "en" then lang = "en" end
-- El farm siempre usa la zona de máxima cobertura y calibra solo
state.Zone = true
state.AutoCalib = true

local saveQueued = false
local function saveConfig()
    if saveQueued or not writefile then return end
    saveQueued = true
    task.delay(1, function()
        saveQueued = false
        local s = {}
        for k, v in pairs(state) do
            if k ~= "Low" and k ~= "Calibrating" then s[k] = v end
        end
        pcall(writefile, FILE, HttpService:JSONEncode({
            state = s, cfg = cfg, selected = selected, ranges = rangeStore,
            webhook = wh, learned = learned, lang = lang,
        }))
    end)
end

-- ===== Idioma =====
local binds = {}
local function tx(pair) return pair[lang == "es" and 1 or 2] end
local function bind(fn)
    binds[#binds + 1] = fn
    pcall(fn)
end
local function setLang(l)
    lang = l
    for _, f in ipairs(binds) do pcall(f) end
end

-- ===== Utilidades =====
local fps = 0
local rangeRefresh = function() end
local statusCb = function() end

local function fmt(n)
    local s = tostring(math.floor(n or 0))
    local neg = s:sub(1, 1) == "-"
    if neg then s = s:sub(2) end
    local r = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    r = r:gsub("^,", "")
    return (neg and "-" or "") .. r
end

local function cellsNum()
    local ls = lp:FindFirstChild("leaderstats")
    local c = ls and ls:FindFirstChild("Cells")
    if not c then return nil end
    local v = c.Value
    if type(v) == "string" then v = tonumber((v:gsub("[^%d%.%-]", ""))) end
    return v
end

local function kaiju()
    local ls = lp:FindFirstChild("leaderstats")
    local k = ls and ls:FindFirstChild("Kaiju")
    return k and tostring(k.Value) or "?"
end

-- ===== Webhook =====
local httpReq = (syn and syn.request) or request or http_request or (http and http.request)

local function startsWith(s, p) return s:sub(1, #p) == p end
local function validWebhook(u)
    return type(u) == "string" and (startsWith(u, "https://discord.com/api/webhooks/")
        or startsWith(u, "https://discordapp.com/api/webhooks/"))
end

local function sendWebhook(title, desc, force)
    if not httpReq or not validWebhook(wh.url) then return false end
    if not (state.Webhook or force) then return false end
    task.spawn(function()
        pcall(httpReq, {
            Url = wh.url,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({
                username = "KA Hub",
                embeds = {{title = title, description = desc, color = 5814783,
                    footer = {text = lp.DisplayName}}},
            }),
        })
    end)
    return true
end

local t0Session = os.clock()
local startCells
task.spawn(function()
    local ls = lp:WaitForChild("leaderstats", 15)
    if ls then ls:WaitForChild("Cells", 15) end
    startCells = cellsNum()
end)

local function reportText()
    local c = cellsNum() or 0
    local gained = startCells and (c - startCells) or 0
    local mins = (os.clock() - t0Session) / 60
    local perHour = gained / math.max(mins / 60, 1 / 3600)
    local ls = lp:FindFirstChild("leaderstats")
    local kills = ls and ls:FindFirstChild("Kills") and tostring(ls.Kills.Value) or "?"
    return ("Kaiju: %s\nCells: %s (+%s)\nCells/h: %s\nKills: %s\nFPS: %d\nTiempo: %d min")
        :format(kaiju(), fmt(c), fmt(gained), fmt(perHour), kills, fps, math.floor(mins))
end

-- ===== Utilidades del juego =====
local cfgSelectedCount = 0
local combat = RS:FindFirstChild("CombatRemote", true)
local visited = setmetatable({}, {__mode = "k"})
local center

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

-- Objetos especiales que se ignoran
local EXCLUDE = {
    ["building3ad"] = true,
    ["tokyotower"] = true,
    ["godzillahotel"] = true,
    ["godzilla zou hibiya square statue"] = true,
    ["bridge"] = true,
}

local function collectTargets()
    local map = workspace:FindFirstChild("Map")
    local folder = map and map:FindFirstChild("CityFolder")
    local list = {}
    if not folder then return list end
    for _, d in ipairs(folder:GetDescendants()) do
        -- Con streaming, los edificios lejanos son modelos vacíos: se cuentan igual
        if d:IsA("Model") and not d:FindFirstChildWhichIsA("Model")
            and not EXCLUDE[d.Name:lower()] then
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

-- ===== Zona de máxima cobertura =====
local function bestSpot(list, R)
    local pts = {}
    for _, t in ipairs(list) do
        if t.Parent then
            local p = posOf(t)
            if p.Magnitude > 1 then pts[#pts + 1] = {t = t, p = p} end
        end
    end
    if #pts == 0 then return nil end

    local function countAt(stand)
        local n = 0
        for _, q in ipairs(pts) do
            if (q.p - stand).Magnitude <= R then n += 1 end
        end
        return n
    end
    local function coveredAt(stand)
        local cov = {}
        for _, q in ipairs(pts) do
            if (q.p - stand).Magnitude <= R then cov[#cov + 1] = q.t end
        end
        return cov
    end

    local stride = math.max(1, math.floor(#pts / 900))
    local bestN, bestStand = 0, nil
    local k = 0
    for i = 1, #pts, stride do
        local stand = pts[i].p + Vector3.new(0, cfg.Height, 0)
        local n = countAt(stand)
        if n > bestN then bestN, bestStand = n, stand end
        k += 1
        if k % 10 == 0 then task.wait() end
    end
    if not bestStand then return nil end

    local cov = coveredAt(bestStand)
    local sum = Vector3.zero
    for _, t in ipairs(cov) do sum += posOf(t) end
    local c2 = sum / #cov + Vector3.new(0, cfg.Height, 0)
    local n2 = countAt(c2)
    if n2 > bestN then bestN, bestStand = n2, c2; cov = coveredAt(c2) end

    return bestStand, cov, bestN
end

local function aliveCount(cov)
    local n = 0
    for _, t in ipairs(cov) do if t.Parent then n += 1 end end
    return n
end

local function nearestAlive(cov, from)
    local best, bd
    for _, t in ipairs(cov) do
        if t.Parent then
            local d = (posOf(t) - from).Magnitude
            if not bd or d < bd then best, bd = t, d end
        end
    end
    return best
end

-- ===== Calibrar rango =====
local calibrating = false

local function calibrate()
    if calibrating then return end
    calibrating = true
    state.Calibrating = true
    task.spawn(function()
        local lastOk, failed = nil, false
        local list = collectTargets()
        table.clear(visited)
        for _, d in ipairs({20, 40, 60, 80, 100, 130, 160, 200, 250}) do
            if not running then break end
            local char = lp.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then break end
            local t = nextTarget(list, hrp.Position)
            if not t then
                statusCb({"No hay objetivos para calibrar", "No targets to calibrate on"})
                break
            end
            visited[t] = true
            statusCb({"Calibrando a " .. d .. "...", "Calibrating at " .. d .. "..."})
            local p = posOf(t)
            local dh = math.max(1, math.sqrt(math.max(d * d - cfg.Height * cfg.Height, 0)))
            local pos = p + Vector3.new(dh, cfg.Height, 0)
            local t0 = os.clock()
            while os.clock() - t0 < 2.5 and t.Parent and running do
                char:PivotTo(CFrame.lookAt(pos, Vector3.new(p.X, pos.Y, p.Z)))
                hrp.AssemblyLinearVelocity = Vector3.zero
                task.spawn(useSkill, 3)
                task.wait(0.2)
            end
            if not t.Parent then lastOk = d else failed = true; break end
        end
        state.Calibrating = false
        calibrating = false
        table.clear(visited)
        if lastOk and failed then
            cfg.Range = math.max(10, math.floor(lastOk * 0.9 / 5) * 5)
            rangeStore[kaiju()] = cfg.Range
            statusCb({"Rango detectado: " .. cfg.Range, "Detected range: " .. cfg.Range})
            sendWebhook("Rango calibrado", kaiju() .. ": " .. cfg.Range)
        elseif lastOk then
            cfg.Range = lastOk
            rangeStore[kaiju()] = cfg.Range
            statusCb({"Alcanza " .. lastOk .. "+ (máximo probado)", "Reaches " .. lastOk .. "+ (max tested)"})
            sendWebhook("Rango calibrado", kaiju() .. ": " .. cfg.Range .. "+")
        else
            statusCb({"No se destruyó nada ni a 20. Ajusta el rango a mano.",
                "Nothing was destroyed even at 20. Set the range manually."})
        end
        rangeRefresh()
        saveConfig()
    end)
end

-- ===== Misiones (aprendidas) =====
local captured = {}
local learning, hooked = false, false
local questStatus = function() end

local function questRemote() return RS:FindFirstChild("InvokeQuest", true) end

local function claimQuests()
    local r = questRemote()
    if not r then return end
    for _, args in ipairs(learned) do
        task.spawn(function()
            pcall(function()
                if r:IsA("RemoteFunction") then
                    r:InvokeServer(table.unpack(args))
                else
                    r:FireServer(table.unpack(args))
                end
            end)
        end)
    end
end

local function learnQuests()
    if learning then return end
    if not hookmetamethod or not getnamecallmethod then
        questStatus({"Tu executor no soporta esto (hookmetamethod).",
            "Your executor doesn't support this (hookmetamethod)."})
        return
    end
    learning = true
    table.clear(captured)
    if not hooked then
        hooked = true
        local old
        old = hookmetamethod(game, "__namecall", function(self, ...)
            if learning then
                local m = getnamecallmethod()
                if (m == "InvokeServer" or m == "FireServer") and typeof(self) == "Instance"
                    and self.Name == "InvokeQuest" then
                    local ser, ok = {}, true
                    for i, a in ipairs({...}) do
                        local ty = type(a)
                        if ty == "string" or ty == "number" or ty == "boolean" then
                            ser[i] = a
                        else
                            ok = false
                        end
                    end
                    if ok then captured[#captured + 1] = ser end
                end
            end
            return old(self, ...)
        end)
    end
    questStatus({"Reclama una misión a mano durante 20 s...", "Claim a quest by hand for 20 s..."})
    task.spawn(function()
        task.wait(20)
        learning = false
        local added = 0
        for _, ser in ipairs(captured) do
            local key = HttpService:JSONEncode(ser)
            local dup = false
            for _, e in ipairs(learned) do
                if HttpService:JSONEncode(e) == key then dup = true; break end
            end
            if not dup then learned[#learned + 1] = ser; added += 1 end
        end
        saveConfig()
        questStatus({"Aprendidas: " .. #learned .. " (nuevas: " .. added .. ")",
            "Learned: " .. #learned .. " (new: " .. added .. ")"})
    end)
end

-- ===== Abrir Event Shop / Battle Pass =====
local function normalize(s) return (s:lower():gsub("[%s_%-%.]", "")) end

local function clickButton(btn)
    for _, sig in ipairs({"Activated", "MouseButton1Click", "MouseButton1Down", "MouseButton1Up"}) do
        local ok, cons = pcall(function() return getconnections(btn[sig]) end)
        if ok and type(cons) == "table" and #cons > 0 then
            for _, c in ipairs(cons) do
                local fired = pcall(function() c:Fire() end)
                if not fired then pcall(function() c.Function() end) end
            end
            return true
        end
    end
    return false
end

local function openGui(words)
    local pg = lp:FindFirstChildOfClass("PlayerGui")
    if not pg then return false end
    local function matches(n)
        n = normalize(n)
        for _, w in ipairs(words) do
            if n:find(w, 1, true) then return true end
        end
        return false
    end
    -- 1) Botón del menú del juego
    if getconnections then
        for _, d in ipairs(pg:GetDescendants()) do
            if (d:IsA("TextButton") or d:IsA("ImageButton")) and matches(d.Name) then
                if clickButton(d) then return true end
            end
        end
    end
    -- 2) Ventana directa
    local hits = 0
    for _, g in ipairs(pg:GetChildren()) do
        if g:IsA("ScreenGui") then
            if matches(g.Name) then
                g.Enabled = true
                hits += 1
            else
                for _, f in ipairs(g:GetChildren()) do
                    if f:IsA("GuiObject") and not f:IsA("GuiButton") and matches(f.Name) then
                        g.Enabled = true
                        f.Visible = true
                        hits += 1
                    end
                end
            end
        end
    end
    return hits > 0
end

local function guiList()
    local out = {}
    local pg = lp:FindFirstChildOfClass("PlayerGui")
    if not pg then return "" end
    for _, g in ipairs(pg:GetChildren()) do
        if g:IsA("ScreenGui") then
            out[#out + 1] = "ScreenGui | " .. g.Name .. " | Enabled=" .. tostring(g.Enabled)
            for i, f in ipairs(g:GetChildren()) do
                if i > 30 then out[#out + 1] = "    ..."; break end
                out[#out + 1] = "    " .. f.ClassName .. " | " .. f.Name
            end
        end
    end
    out[#out + 1] = "--- Botones relevantes ---"
    for _, d in ipairs(pg:GetDescendants()) do
        if d:IsA("TextButton") or d:IsA("ImageButton") then
            local n = normalize(d.Name)
            if n:find("shop", 1, true) or n:find("pass", 1, true) or n:find("event", 1, true)
                or n:find("quest", 1, true) or n:find("battle", 1, true) then
                out[#out + 1] = d:GetFullName()
            end
        end
    end
    return table.concat(out, "\n")
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
                    sendWebhook("Desconexión", "Reconectando al juego...")
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
    local spot, cov, n0, ts = nil, {}, 0, 0
    local lastKaiju, calibTries = nil, 0
    while running do
        local char = lp.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")

        -- Rango por kaiju: carga el guardado o calibra solo
        local kj = kaiju()
        if kj ~= lastKaiju and kj ~= "?" then
            lastKaiju = kj
            calibTries = 0
            if rangeStore[kj] then
                cfg.Range = rangeStore[kj]
                rangeRefresh()
                statusCb({"Rango guardado para " .. kj .. ": " .. cfg.Range,
                    "Saved range for " .. kj .. ": " .. cfg.Range})
            end
        end
        if state.Farm and state.Zone and state.AutoCalib and hrp and not rangeStore[kj]
            and kj ~= "?" and calibTries < 2 and not calibrating then
            calibTries += 1
            calibrate()
        end

        if state.Farm and hrp and not state.Calibrating then
            if state.Zone then
                if not spot or aliveCount(cov) < math.min(n0, math.max(3, math.floor(n0 * 0.5)))
                    or os.clock() - ts > 12 then
                    spot, cov, n0 = bestSpot(collectTargets(), cfg.Range)
                    ts = os.clock()
                    if not spot then task.wait(1) end
                end
                if spot then
                    if (hrp.Position - spot).Magnitude > 20 then
                        char:PivotTo(CFrame.new(spot))
                    end
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    local near = nearestAlive(cov, hrp.Position)
                    if near then
                        local p = posOf(near)
                        if Vector3.new(hrp.Position.X - p.X, 0, hrp.Position.Z - p.Z).Magnitude > 1 then
                            hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(p.X, hrp.Position.Y, p.Z))
                        end
                    end
                    task.spawn(useSkill, 3)
                end
            elseif state.ByBuilding then
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
        task.wait(state.NoCD and 0.05 or 0.25)
    end
end)

-- ===== Macro =====
-- Cada ataque tiene su propio hilo: ninguno espera a que otro termine.
for i = 1, 4 do
    task.spawn(function()
        while running do
            if state.Macro and selected[i] then task.spawn(useSkill, i) end
            task.wait(state.NoCD and 0.03 or cfg.Delay / 1000)
        end
    end)
end

-- ===== Sin cooldown (intento) =====
-- Pone en 0 los valores/atributos de cooldown del cliente. Si el cooldown real
-- lo controla el servidor, esto no lo salta; el modo también dispara más rápido.
local function cdName(n)
    n = n:lower()
    return n:find("cooldown", 1, true) or n:find("^cd") or n:find("cd$")
end

local function cdTargets()
    local out = {}
    local function check(o)
        for k, v in pairs(o:GetAttributes()) do
            if cdName(k) then out[#out + 1] = {o = o, attr = k, v = v} end
        end
        if (o:IsA("NumberValue") or o:IsA("IntValue") or o:IsA("BoolValue")) and cdName(o.Name) then
            out[#out + 1] = {o = o, v = o.Value}
        end
    end
    local roots = {lp.Character}
    for _, c in ipairs(lp:GetChildren()) do
        if not c:IsA("PlayerGui") then roots[#roots + 1] = c end
    end
    check(lp)
    for _, r in ipairs(roots) do
        check(r)
        for _, d in ipairs(r:GetDescendants()) do check(d) end
    end
    return out
end

task.spawn(function()
    while running do
        task.wait(0.5)
        if state.NoCD then
            for _, t in ipairs(cdTargets()) do
                pcall(function()
                    if t.attr then
                        if type(t.v) == "number" then t.o:SetAttribute(t.attr, 0)
                        elseif type(t.v) == "boolean" then t.o:SetAttribute(t.attr, false) end
                    elseif t.o:IsA("BoolValue") then
                        t.o.Value = false
                    else
                        t.o.Value = 0
                    end
                end)
            end
        end
    end
end)

-- ===== Reclamo automático de misiones =====
task.spawn(function()
    while running do
        task.wait(math.max(10, cfg.QuestEvery))
        if state.AutoQuest and #learned > 0 and not state.Calibrating then
            claimQuests()
        end
    end
end)

-- ===== Reporte periódico por webhook =====
task.spawn(function()
    local lastSent = os.clock()
    while running do
        task.wait(5)
        if state.Webhook and os.clock() - lastSent >= cfg.WebhookMin * 60 then
            lastSent = os.clock()
            sendWebhook("Reporte KA Hub", reportText())
        end
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
local RED = Color3.fromRGB(160, 45, 45)
local WHITE = Color3.new(1, 1, 1)
local GREY = Color3.fromRGB(150, 150, 170)

local function corner(o, r) Instance.new("UICorner", o).CornerRadius = UDim.new(0, r or 6) end

-- Marca de agua
local mark = Instance.new("TextLabel")
mark.Size = UDim2.fromOffset(440, 18)
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
splashLabel(tx({"Bienvenido, ", "Welcome, "}) .. lp.DisplayName, 42, 15, Enum.Font.GothamMedium)
local splashFps = splashLabel("FPS: --", 70, 15, Enum.Font.GothamMedium, Color3.fromRGB(120, 220, 140))
splashLabel(tx({"Cargando menú...", "Loading menu..."}), 94, 12, Enum.Font.Gotham, GREY)

-- Ventana principal
local win = Instance.new("Frame")
win.Size = UDim2.fromOffset(250, 0)
win.AutomaticSize = Enum.AutomaticSize.Y
win.Position = UDim2.new(0, 12, 0.15, 0)
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
tabLayout.Padding = UDim.new(0, 3)

local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800, 400)
local holder = Instance.new("ScrollingFrame")
holder.Size = UDim2.new(1, 0, 0, math.clamp(math.floor(vp.Y * 0.5), 150, 320))
holder.CanvasSize = UDim2.new(0, 0, 0, 0)
holder.AutomaticCanvasSize = Enum.AutomaticSize.Y
holder.ScrollBarThickness = 4
holder.BackgroundTransparency = 1
holder.BorderSizePixel = 0
holder.LayoutOrder = 1
holder.Parent = content

local pages, tabBtns = {}, {}

local function show(name)
    for n, f in pairs(pages) do f.Parent = (n == name) and holder or nil end
    for n, b in pairs(tabBtns) do b.BackgroundColor3 = (n == name) and ACC or OFF end
end

local function newPage(id, name)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -6, 0, 0)
    f.AutomaticSize = Enum.AutomaticSize.Y
    f.BackgroundTransparency = 1
    local l = Instance.new("UIListLayout", f)
    l.Padding = UDim.new(0, 5)
    l.HorizontalAlignment = Enum.HorizontalAlignment.Center
    local p = Instance.new("UIPadding", f)
    p.PaddingTop = UDim.new(0, 6)
    p.PaddingBottom = UDim.new(0, 8)
    pages[id] = f

    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.25, -3, 0, 24)
    b.BackgroundColor3 = OFF
    b.TextColor3 = WHITE
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 11
    b.Parent = tabBar
    corner(b)
    bind(function() b.Text = tx(name) end)
    b.Activated:Connect(function() show(id) end)
    tabBtns[id] = b
    return f
end

-- Componentes
local function section(page, name)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -16, 0, 16)
    l.BackgroundTransparency = 1
    l.TextColor3 = GREY
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Font = Enum.Font.GothamMedium
    l.TextSize = 12
    l.Parent = page
    bind(function() l.Text = tx(name) end)
end

local function makeBtn(page, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -16, 0, 32)
    b.BackgroundColor3 = color
    b.TextColor3 = WHITE
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 13
    b.Parent = page
    corner(b)
    return b
end

local function button(page, name, color, cb)
    local b = makeBtn(page, color)
    bind(function() b.Text = tx(name) end)
    b.Activated:Connect(function() cb(b) end)
    return b
end

local function toggle(page, name, key, onChange)
    local b = makeBtn(page, OFF)
    bind(function()
        b.Text = tx(name) .. ": " .. (state[key] and "ON" or "OFF")
        b.BackgroundColor3 = state[key] and ON or OFF
    end)
    b.Activated:Connect(function()
        state[key] = not state[key]
        b.Text = tx(name) .. ": " .. (state[key] and "ON" or "OFF")
        b.BackgroundColor3 = state[key] and ON or OFF
        if onChange then onChange(state[key]) end
        saveConfig()
    end)
    return b
end

local function stepper(page, name, key, step, min, max, onChange)
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
    lbl.TextSize = 12
    lbl.Parent = row
    local function refresh() lbl.Text = tx(name) .. ": " .. cfg[key] end
    bind(refresh)
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
            if onChange then onChange(cfg[key]) end
            saveConfig()
        end)
    end
    mk("-", -68, -step)
    mk("+", -34, step)
    return refresh
end

local function statusLabel(page, initial)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -16, 0, 28)
    l.BackgroundTransparency = 1
    l.TextColor3 = GREY
    l.TextWrapped = true
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Font = Enum.Font.Gotham
    l.TextSize = 12
    l.Parent = page
    local cur = initial
    bind(function() l.Text = tx(cur) end)
    return function(pair)
        cur = pair
        l.Text = tx(cur)
    end
end

local qot = queue_on_teleport or (syn and syn.queue_on_teleport)

-- ===== Pestaña: Macro =====
local pMacro = newPage("Macro", {"Macro", "Macro"})
section(pMacro, {"SPAM DE ATAQUES", "ATTACK SPAM"})
toggle(pMacro, {"Macro", "Macro"}, "Macro")
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
        b.TextColor3 = WHITE
        b.Font = Enum.Font.GothamMedium
        b.TextSize = 12
        b.Parent = row
        corner(b)
        bind(function() b.Text = tx({"Atq ", "Atk "}) .. i end)
        b.Activated:Connect(function()
            selected[i] = not selected[i]
            b.BackgroundColor3 = selected[i] and ON or OFF
            saveConfig()
        end)
    end
end
stepper(pMacro, {"Delay (ms)", "Delay (ms)"}, "Delay", 50, 50, 1000)

-- ===== Pestaña: Farm =====
local pFarm = newPage("Farm", {"Farm", "Farm"})
section(pFarm, {"CIUDAD", "CITY"})
toggle(pFarm, {"Auto Farm City", "Auto Farm City"}, "Farm", function()
    center = nil
    table.clear(visited)
end)
statusCb = statusLabel(pFarm, {"El rango y la mejor zona se detectan solos al activar el farm.",
    "Range and best spot are detected automatically when you start farming."})

section(pFarm, {"MISIONES", "QUESTS"})
toggle(pFarm, {"Reclamar misiones", "Auto-claim quests"}, "AutoQuest")
stepper(pFarm, {"Cada (s)", "Every (s)"}, "QuestEvery", 10, 10, 600)
button(pFarm, {"Aprender reclamo (20 s)", "Learn claim (20 s)"}, ACC, function() learnQuests() end)
button(pFarm, {"Copiar lo aprendido", "Copy learned data"}, OFF, function()
    if setclipboard then
        setclipboard(HttpService:JSONEncode(learned))
        questStatus({"Copiado al portapapeles.", "Copied to clipboard."})
    else
        questStatus({"Tu executor no tiene setclipboard.", "Your executor has no setclipboard."})
    end
end)
button(pFarm, {"Borrar lo aprendido", "Clear learned data"}, RED, function()
    table.clear(learned)
    saveConfig()
    questStatus({"Aprendidas: 0", "Learned: 0"})
end)
questStatus = statusLabel(pFarm, {"Aprendidas: " .. #learned, "Learned: " .. #learned})


-- ===== Pestaña: Misc =====
local pMisc = newPage("Misc", {"Misc", "Misc"})
section(pMisc, {"SISTEMA", "SYSTEM"})
toggle(pMisc, {"Anti-AFK", "Anti-AFK"}, "AntiAFK")
toggle(pMisc, {"Auto Rejoin", "Auto Rejoin"}, "Rejoin")
toggle(pMisc, {"Auto Execute", "Auto Execute"}, "AutoExec", function(on)
    if on and qot then pcall(qot, getgenv().KA_SRC or "") end
end)
toggle(pMisc, {"Noclip", "Noclip"}, "Noclip")
toggle(pMisc, {"Modo bajo consumo", "Low-power mode"}, "Low", function(on)
    pcall(function() RunService:Set3dRenderingEnabled(not on) end)
    pcall(function() settings().Rendering.QualityLevel = on and 1 or 10 end)
    Lighting.GlobalShadows = not on
end)

section(pMisc, {"ACCESOS", "SHORTCUTS"})
local miscStatus = statusLabel(pMisc, {"", ""})
local function openAndReport(words, nameEs, nameEn)
    if openGui(words) then
        miscStatus({nameEs .. ": abierto.", nameEn .. ": opened."})
    else
        miscStatus({"No encontré " .. nameEs .. ". Usa 'Copiar lista de GUIs' y pásamela.",
            "Couldn't find " .. nameEn .. ". Use 'Copy GUI list' and send it to me."})
    end
end
button(pMisc, {"Abrir Event Shop", "Open Event Shop"}, ACC, function()
    openAndReport({"eventshop", "eventstore"}, "Event Shop", "Event Shop")
end)
button(pMisc, {"Abrir Battle Pass", "Open Battle Pass"}, ACC, function()
    openAndReport({"battlepass", "battlepas"}, "Battle Pass", "Battle Pass")
end)
button(pMisc, {"Copiar lista de GUIs", "Copy GUI list"}, OFF, function()
    if setclipboard then
        setclipboard(guiList())
        miscStatus({"Lista copiada al portapapeles.", "List copied to clipboard."})
    else
        miscStatus({"Tu executor no tiene setclipboard.", "Your executor has no setclipboard."})
    end
end)

section(pMisc, {"COMBATE", "COMBAT"})
button(pMisc, {"Recalibrar rango", "Recalibrate range"}, ACC, function()
    rangeStore[kaiju()] = nil
    calibrate()
    miscStatus({"Recalibrando... el resultado sale en la pestaña Farm.",
        "Recalibrating... result shows in the Farm tab."})
end)
toggle(pMisc, {"Sin cooldown (intento)", "No cooldown (attempt)"}, "NoCD")
button(pMisc, {"Buscar cooldowns", "Find cooldowns"}, OFF, function()
    local list = cdTargets()
    local lines = {}
    for _, t in ipairs(list) do
        lines[#lines + 1] = t.o:GetFullName() .. (t.attr and ("@" .. t.attr) or "") .. " = " .. tostring(t.v)
    end
    if setclipboard then setclipboard(table.concat(lines, "\n")) end
    miscStatus({"Encontrados: " .. #list .. (setclipboard and " (copiados)" or ""),
        "Found: " .. #list .. (setclipboard and " (copied)" or "")})
end)

section(pMisc, {"CONFIGURACIÓN", "SETTINGS"})
do
    local lb = makeBtn(pMisc, OFF)
    bind(function() lb.Text = tx({"Idioma: Español", "Language: English"}) end)
    lb.Activated:Connect(function()
        setLang(lang == "es" and "en" or "es")
        saveConfig()
    end)
end
button(pMisc, {"Guardar config ahora", "Save config now"}, OFF, function()
    saveConfig()
    miscStatus({"Configuración guardada.", "Settings saved."})
end)
button(pMisc, {"Borrar config guardada", "Delete saved config"}, RED, function()
    if delfile and isfile and isfile(FILE) then pcall(delfile, FILE) end
    miscStatus({"Config borrada (se aplica al reiniciar).", "Config deleted (applies on restart)."})
end)

local function unload()
    running = false
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    pcall(function() RunService:Set3dRenderingEnabled(true) end)
    gui:Destroy()
    getgenv().KA_UNLOAD = nil
end
getgenv().KA_UNLOAD = unload
button(pMisc, {"Descargar script", "Unload script"}, RED, function() unload() end)

-- ===== Pestaña: Webhook =====
local pHook = newPage("Webhook", {"Webhook", "Webhook"})
section(pHook, {"DISCORD", "DISCORD"})
toggle(pHook, {"Webhook", "Webhook"}, "Webhook")
do
    local tb = Instance.new("TextBox")
    tb.Size = UDim2.new(1, -16, 0, 30)
    tb.BackgroundColor3 = OFF
    tb.TextColor3 = WHITE
    tb.PlaceholderColor3 = GREY
    tb.PlaceholderText = "https://discord.com/api/webhooks/..."
    tb.Text = wh.url
    tb.ClearTextOnFocus = false
    tb.TextXAlignment = Enum.TextXAlignment.Left
    tb.TextTruncate = Enum.TextTruncate.AtEnd
    tb.Font = Enum.Font.Gotham
    tb.TextSize = 11
    tb.Parent = pHook
    corner(tb)
    tb.FocusLost:Connect(function()
        wh.url = (tb.Text:gsub("^%s+", ""):gsub("%s+$", ""))
        saveConfig()
    end)
end
stepper(pHook, {"Reporte cada (min)", "Report every (min)"}, "WebhookMin", 5, 1, 120)
local hookStatus = statusLabel(pHook, {"Pega la URL del webhook y pulsa Probar.", "Paste the webhook URL and press Test."})
button(pHook, {"Probar webhook", "Test webhook"}, ACC, function()
    if not httpReq then
        hookStatus({"Tu executor no soporta peticiones HTTP.", "Your executor doesn't support HTTP requests."})
    elseif not validWebhook(wh.url) then
        hookStatus({"La URL no parece un webhook de Discord.", "That URL doesn't look like a Discord webhook."})
    else
        sendWebhook("KA Hub", reportText(), true)
        hookStatus({"Enviado. Revisa tu canal de Discord.", "Sent. Check your Discord channel."})
    end
end)
statusLabel(pHook, {"Se envía: inicio, rango calibrado, desconexión y reporte periódico.",
    "Sends: start, calibrated range, disconnects and periodic report."})

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
        local c = cellsNum()
        local gained = (c and startCells) and (c - startCells) or 0
        local hours = math.max((os.clock() - t0Session) / 3600, 1 / 3600)
        mark.Text = ("KA | Cells %s | +%s | %s/h | %d FPS | %d ms")
            :format(c and fmt(c) or "?", fmt(gained), fmt(gained / hours), fps, ping)
    end
end)

-- Cerrar la bienvenida y mostrar el menú
task.delay(3.5, function()
    if not running then return end
    splash:Destroy()
    win.Visible = true
    sendWebhook("KA Hub iniciado", "Kaiju: " .. kaiju() .. "\nRango: " .. cfg.Range)
end)
]==]

getgenv().KA_SRC = SRC
loadstring(SRC)()
