-- KA HUB | Kaiju Alpha
-- Secciones: Macro (grabadora de movimientos), Autofarm, Alertas, Misc

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
local TweenService = game:GetService("TweenService")
local lp = Players.LocalPlayer

if not game:IsLoaded() then game.Loaded:Wait() end

local genv = getgenv()
local running = true
local conns = {}
local state = {
    Farm = genv.KA_RESUME == true, Calibrating = false, Noclip = false,
    AntiAFK = true, Rejoin = true, AutoExec = genv.KA_AUTOEXEC == true, Low = false,
    AutoRespawn = true, Collect = true, Collecting = false,
    Recording = false, Playing = false, Loop = false,
    Notify = false, Report = false, Detect = true, LogRemotes = false,
}
genv.KA_RESUME = nil
-- Height y Range los ajusta el script solo
local cfg = {Height = 8, Range = 60, Speed = 1, Webhook = "", Lang = "es"}

-- ===== Idiomas (es / en / th) =====
-- La clave es el texto en español; si no hay traducción se muestra tal cual.
-- Va dentro de un bloque y cuelga de cfg para no gastar variables locales (límite de 200).
do
local TR = {
    -- Estados y avisos
    ["Detectando el rango del ataque..."] = {en = "Detecting attack range...", th = "กำลังตรวจจับระยะโจมตี..."},
    ["Rango detectado: "] = {en = "Range detected: ", th = "ตรวจพบระยะ: "},
    ["No pude detectar el rango, uso "] = {en = "Couldn't detect the range, using ", th = "ตรวจจับระยะไม่ได้ ใช้ค่า "},
    [" (error interno)"] = {en = " (internal error)", th = " (ข้อผิดพลาดภายใน)"},
    ["Esperando datos del jugador..."] = {en = "Waiting for player data...", th = "กำลังรอข้อมูลผู้เล่น..."},
    ["Zona: %d edificios | Rango %d | Altura %d"] = {en = "Zone: %d buildings | Range %d | Height %d", th = "โซน: %d อาคาร | ระยะ %d | ความสูง %d"},
    ["No encuentro edificios, reintentando..."] = {en = "No buildings found, retrying...", th = "ไม่พบอาคาร กำลังลองใหม่..."},
    ["Reapareciendo en "] = {en = "Respawning in ", th = "กำลังเกิดใหม่ที่ "},
    ["Recogido: "] = {en = "Collected: ", th = "เก็บแล้ว: "},
    ["Registrando en "] = {en = "Logging to ", th = "กำลังบันทึกลงใน "},
    ["Macro guardada: %s (%s)"] = {en = "Macro saved: %s (%s)", th = "บันทึกมาโครแล้ว: %s (%s)"},
    ["Grabación muy corta, descartada"] = {en = "Recording too short, discarded", th = "บันทึกสั้นเกินไป ถูกยกเลิก"},
    ["No hay personaje"] = {en = "No character", th = "ไม่พบตัวละคร"},
    ["Grabando... muévete y ataca"] = {en = "Recording... move and attack", th = "กำลังบันทึก... เดินและโจมตีได้เลย"},
    ["Límite de grabación alcanzado (10 min)"] = {en = "Recording limit reached (10 min)", th = "ถึงขีดจำกัดการบันทึกแล้ว (10 นาที)"},
    ["Selecciona una macro de la lista"] = {en = "Select a macro from the list", th = "เลือกมาโครจากรายการ"},
    ["Apaga el Auto Farm antes de reproducir una macro"] = {en = "Turn off Auto Farm before playing a macro", th = "ปิดออโต้ฟาร์มก่อนเล่นมาโคร"},
    ["Cambiando idioma..."] = {en = "Changing language...", th = "กำลังเปลี่ยนภาษา..."},
    -- Bienvenida y marco
    ["Bienvenido, "] = {en = "Welcome, ", th = "ยินดีต้อนรับ, "},
    ["Cargando menú..."] = {en = "Loading menu...", th = "กำลังโหลดเมนู..."},
    ["RightShift: mostrar / ocultar"] = {en = "RightShift: show / hide", th = "RightShift: แสดง / ซ่อน"},
    -- Pestañas
    ["Macro"] = {en = "Macro", th = "มาโคร"},
    ["Autofarm"] = {en = "Autofarm", th = "ออโต้ฟาร์ม"},
    ["Alertas"] = {en = "Alerts", th = "แจ้งเตือน"},
    ["Misc"] = {en = "Misc", th = "อื่นๆ"},
    -- Secciones
    ["GRABADORA DE MOVIMIENTOS"] = {en = "MOVEMENT RECORDER", th = "ตัวบันทึกการเคลื่อนไหว"},
    ["ATAQUES (se graban mientras grabas)"] = {en = "ATTACKS (recorded while recording)", th = "การโจมตี (บันทึกขณะอัดมาโคร)"},
    ["MACROS GUARDADOS"] = {en = "SAVED MACROS", th = "มาโครที่บันทึกไว้"},
    ["CIUDAD"] = {en = "CITY", th = "เมือง"},
    ["ATAQUES A USAR"] = {en = "ATTACKS TO USE", th = "การโจมตีที่จะใช้"},
    ["DETECCIÓN"] = {en = "DETECTION", th = "การตรวจจับ"},
    ["SISTEMA"] = {en = "SYSTEM", th = "ระบบ"},
    ["IDIOMA"] = {en = "LANGUAGE", th = "ภาษา"},
    -- Interruptores
    ["Repetir en bucle"] = {en = "Loop playback", th = "เล่นซ้ำ"},
    ["Velocidad"] = {en = "Speed", th = "ความเร็ว"},
    ["Auto Farm City"] = {en = "Auto Farm City", th = "ออโต้ฟาร์มเมือง"},
    ["Auto reaparecer"] = {en = "Auto respawn", th = "เกิดใหม่อัตโนมัติ"},
    ["Recolectar Skull/Archetype"] = {en = "Collect Skull/Archetype", th = "เก็บ Skull/Archetype"},
    ["Enviar notificaciones"] = {en = "Send notifications", th = "ส่งการแจ้งเตือน"},
    ["Reporte cada 15 min"] = {en = "Report every 15 min", th = "รายงานทุก 15 นาที"},
    ["Jefes / eventos / airdrops"] = {en = "Bosses / events / airdrops", th = "บอส / อีเวนต์ / แอร์ดรอป"},
    ["Registrar remotes (depurar)"] = {en = "Log remotes (debug)", th = "บันทึกรีโมต (ดีบัก)"},
    ["Anti-AFK"] = {en = "Anti-AFK", th = "ป้องกัน AFK"},
    ["Auto Rejoin"] = {en = "Auto Rejoin", th = "เข้าเซิร์ฟเวอร์ใหม่อัตโนมัติ"},
    ["Auto Execute"] = {en = "Auto Execute", th = "รันสคริปต์อัตโนมัติ"},
    ["Noclip"] = {en = "Noclip", th = "ทะลุสิ่งกีดขวาง (Noclip)"},
    ["Modo bajo consumo"] = {en = "Low power mode", th = "โหมดประหยัดทรัพยากร"},
    -- Botones
    ["Grabar"] = {en = "Record", th = "บันทึก"},
    ["Reproducir"] = {en = "Play", th = "เล่น"},
    ["Play"] = {en = "Play", th = "เล่น"},
    ["Detener"] = {en = "Stop", th = "หยุด"},
    ["Detener y guardar"] = {en = "Stop and save", th = "หยุดและบันทึก"},
    ["Recalibrar rango"] = {en = "Recalibrate range", th = "ปรับเทียบระยะใหม่"},
    ["Enviar mensaje de prueba"] = {en = "Send test message", th = "ส่งข้อความทดสอบ"},
    ["Escanear ahora"] = {en = "Scan now", th = "สแกนตอนนี้"},
    ["Descargar script"] = {en = "Unload script", th = "ยกเลิกการโหลดสคริปต์"},
    -- Estado de la grabadora
    ["Listo para grabar"] = {en = "Ready to record", th = "พร้อมบันทึก"},
    ["Seleccionada: "] = {en = "Selected: ", th = "เลือกไว้: "},
    ["ninguna"] = {en = "none", th = "ไม่มี"},
    ["GRABANDO  %s  |  %d puntos  |  %d ataques"] = {en = "RECORDING  %s  |  %d points  |  %d attacks", th = "กำลังบันทึก  %s  |  %d จุด  |  %d การโจมตี"},
    ["REPRODUCIENDO  %s  |  %s / %s"] = {en = "PLAYING  %s  |  %s / %s", th = "กำลังเล่น  %s  |  %s / %s"},
    -- Textos y avisos de la interfaz
    ["Nombre de la macro (opcional)"] = {en = "Macro name (optional)", th = "ชื่อมาโคร (ไม่บังคับ)"},
    ["Aún no hay macros. Pulsa Grabar, muévete y ataca, y luego Detener y guardar."] = {en = "No macros yet. Press Record, move and attack, then Stop and save.", th = "ยังไม่มีมาโคร กด บันทึก แล้วเดินและโจมตี จากนั้นกด หยุดและบันทึก"},
    ["Tu ejecutor no permite guardar archivos: las macros se perderán al salir."] = {en = "Your executor can't save files: macros will be lost when you leave.", th = "เอ็กเซกูเตอร์ของคุณไม่รองรับการบันทึกไฟล์: มาโครจะหายเมื่อออก"},
    ["Automático: detecta el rango, ajusta la altura y va a la zona con más edificios."] = {en = "Automatic: detects the range, adjusts the height and goes to the zone with the most buildings.", th = "อัตโนมัติ: ตรวจจับระยะ ปรับความสูง และไปยังโซนที่มีอาคารมากที่สุด"},
    ["URL del webhook de Discord"] = {en = "Discord webhook URL", th = "URL เว็บฮุก Discord"},
    ["Tu ejecutor no soporta peticiones HTTP"] = {en = "Your executor doesn't support HTTP requests", th = "เอ็กเซกูเตอร์ของคุณไม่รองรับคำขอ HTTP"},
    ["Pega primero la URL del webhook"] = {en = "Paste the webhook URL first", th = "วาง URL เว็บฮุกก่อน"},
    ["El webhook funciona"] = {en = "The webhook works", th = "เว็บฮุกใช้งานได้"},
    ["Prueba enviada"] = {en = "Test sent", th = "ส่งการทดสอบแล้ว"},
    ["Prueba"] = {en = "Test", th = "ทดสอบ"},
    ["Escaneo listo: %d coincidencias"] = {en = "Scan done: %d matches", th = "สแกนเสร็จ: พบ %d รายการ"},
    ["Último: "] = {en = "Last: ", th = "ล่าสุด: "},
    ["Historial en "] = {en = "History in ", th = "ประวัติใน "},
    ["Tu ejecutor no soporta queue_on_teleport"] = {en = "Your executor doesn't support queue_on_teleport", th = "เอ็กเซกูเตอร์ของคุณไม่รองรับ queue_on_teleport"},
    -- Alertas (Discord y registro)
    ["Jefe detectado"] = {en = "Boss detected", th = "ตรวจพบบอส"},
    ["Airdrop detectado"] = {en = "Airdrop detected", th = "ตรวจพบแอร์ดรอป"},
    ["Evento detectado"] = {en = "Event detected", th = "ตรวจพบอีเวนต์"},
    ["Posición: "] = {en = "Position: ", th = "ตำแหน่ง: "},
    ["Servidor: "] = {en = "Server: ", th = "เซิร์ฟเวอร์: "},
    [" | Jugadores: "] = {en = " | Players: ", th = " | ผู้เล่น: "},
    [" (ya presente)"] = {en = " (already present)", th = " (มีอยู่แล้ว)"},
    ["Mensaje: "] = {en = "Message: ", th = "ข้อความ: "},
    ["Chat: "] = {en = "Chat: ", th = "แชท: "},
    ["Reporte"] = {en = "Report", th = "รายงาน"},
    ["Kaiju: %s\nCells: %s\nKills: %s"] = {en = "Kaiju: %s\nCells: %s\nKills: %s", th = "ไคจู: %s\nCells: %s\nKills: %s"},
    ["Hub iniciado"] = {en = "Hub started", th = "เริ่มฮับแล้ว"},
    ["KA Hub cargado en "] = {en = "KA Hub loaded for ", th = "โหลด KA Hub แล้วสำหรับ "},
}
cfg.T = function(s)
    local e = TR[s]
    return (e and e[cfg.Lang]) or s
end
end
local selected = {true, true, true, true, true}
local visited = setmetatable({}, {__mode = "k"})
local fps = 0
local farmActive = false
local farmSpot = nil

-- Rangos detectados (se guardan en archivo para no recalibrar cada vez)
local canFile = type(writefile) == "function" and type(readfile) == "function"
    and type(isfile) == "function"
local RANGE_FILE = "KAHub_Ranges.json"
local rangeBase = {}   -- rango detectado por kaiju (persistente)
local rangeStore = {}  -- rango de trabajo (puede bajar si el farm rinde poco)
local function saveRanges()
    if not canFile then return end
    pcall(function() writefile(RANGE_FILE, HttpService:JSONEncode(rangeBase)) end)
end
if canFile then
    pcall(function()
        if isfile(RANGE_FILE) then
            local d = HttpService:JSONDecode(readfile(RANGE_FILE))
            if type(d) == "table" then
                for k, v in pairs(d) do
                    if type(v) == "number" then rangeBase[k] = v; rangeStore[k] = v end
                end
            end
        end
    end)
end

-- ===== Configuración guardada =====
local CFG_FILE = "KAHub_Config.json"
local SAVE_KEYS = {"AntiAFK", "Rejoin", "AutoExec", "Noclip", "Loop", "AutoRespawn", "Collect",
    "Notify", "Report", "Detect"}
local saveQueued = false
local function saveConfig()
    if not canFile or saveQueued then return end
    saveQueued = true
    task.delay(0.5, function()
        saveQueued = false
        pcall(function()
            local d = {sel = selected, speed = cfg.Speed, webhook = cfg.Webhook, lang = cfg.Lang}
            for _, k in ipairs(SAVE_KEYS) do d[k] = state[k] end
            writefile(CFG_FILE, HttpService:JSONEncode(d))
        end)
    end)
end
if canFile then
    pcall(function()
        if isfile(CFG_FILE) then
            local d = HttpService:JSONDecode(readfile(CFG_FILE))
            if type(d) == "table" then
                for _, k in ipairs(SAVE_KEYS) do
                    if type(d[k]) == "boolean" then state[k] = d[k] end
                end
                if type(d.speed) == "number" then cfg.Speed = math.clamp(d.speed, 0.25, 3) end
                if type(d.webhook) == "string" then cfg.Webhook = d.webhook end
                if d.lang == "es" or d.lang == "en" or d.lang == "th" then cfg.Lang = d.lang end
                if type(d.sel) == "table" then
                    for i = 1, 5 do
                        if type(d.sel[i]) == "boolean" then selected[i] = d.sel[i] end
                    end
                end
            end
        end
    end)
end
if genv.KA_LANG == "es" or genv.KA_LANG == "en" or genv.KA_LANG == "th" then cfg.Lang = genv.KA_LANG end
if genv.KA_AUTOEXEC == true then state.AutoExec = true end

-- Funciones que se rellenan más abajo (interfaz)
local toast = function() end
local refreshList = function() end
local statusCb = function() end
local setOpen = function() end

-- ===== Utilidades del juego =====
local combat = RS:FindFirstChild("CombatRemote", true)
local ownCalls = 0 -- llamadas hechas por el propio script (no se graban)
local pending = {}  -- llamadas aún sin responder por ataque (evita acumular hilos)
local MAX_PENDING = 4

local function useSkill(n)
    if not combat then return end
    if (pending[n] or 0) >= MAX_PENDING then return end
    pending[n] = (pending[n] or 0) + 1
    ownCalls += 1
    pcall(function()
        if combat:IsA("RemoteFunction") then
            combat:InvokeServer("UseSkill", "Attack" .. n)
        else
            combat:FireServer("UseSkill", "Attack" .. n)
        end
    end)
    ownCalls -= 1
    pending[n] = math.max(0, (pending[n] or 1) - 1)
end

local function kaiju()
    local ls = lp:FindFirstChild("leaderstats")
    local k = ls and ls:FindFirstChild("Kaiju")
    return k and tostring(k.Value) or "?"
end

-- Dispara los ataques elegidos (si no hay ninguno, el 3)
local function fireSelectedOnce()
    local any = false
    for i = 1, 5 do
        if selected[i] then any = true; task.spawn(useSkill, i) end
    end
    if not any then task.spawn(useSkill, 3) end
end

local function anySelected()
    for i = 1, 5 do if selected[i] then return true end end
    return false
end

-- Altura automática según el tamaño del kaiju
local function autoHeight(char)
    local ok, size = pcall(function() return char:GetExtentsSize() end)
    if ok and size then
        cfg.Height = math.clamp(math.floor(size.Y * 0.2), 6, 30)
    end
end

-- Objetos especiales que se ignoran (aguantan más y distorsionan el conteo)
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

-- Los objetivos se guardan en caché: recorrer todo el mapa es caro
local tCache, tCacheT = nil, 0
local function getTargets(force)
    if force or not tCache or #tCache == 0 or os.clock() - tCacheT > 25 then
        tCache, tCacheT = collectTargets(), os.clock()
    end
    return tCache
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

-- ===== Zona con más edificios =====
-- Busca el punto desde el que más objetivos quedan dentro del rango y lo
-- centra sobre el grupo (así quedan edificios a todos los lados).
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

    -- Centrar sobre el grupo (hasta 3 pasos mientras mejore la cobertura)
    local cov = coveredAt(bestStand)
    for _ = 1, 3 do
        if #cov == 0 then break end
        local sum = Vector3.zero
        for _, t in ipairs(cov) do sum += posOf(t) end
        local c2 = sum / #cov + Vector3.new(0, cfg.Height, 0)
        local n2 = countAt(c2)
        if n2 > bestN then
            bestN, bestStand = n2, c2
            cov = coveredAt(c2)
        else
            break
        end
    end

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

-- ===== Detección automática del rango =====
-- Prueba los ataques elegidos desde distancias crecientes sobre edificios distintos.
-- La última distancia a la que se destruye uno marca el alcance real.
local calibrating = false

local function calibrate()
    if calibrating then return end
    calibrating = true
    state.Calibrating = true
    task.spawn(function()
        local lastOk, failed = nil, false
        local ok, err = pcall(function()
            local list = getTargets(true)
            table.clear(visited)
            statusCb(cfg.T("Detectando el rango del ataque..."))
            for _, d in ipairs({20, 40, 60, 80, 100, 130, 160, 200, 250}) do
                if not running then break end
                local char = lp.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if not hrp or not hum or hum.Health <= 0 then break end
                autoHeight(char)
                local t = nextTarget(list, hrp.Position)
                if not t then break end
                visited[t] = true
                local p = posOf(t)
                local dh = math.max(1, math.sqrt(math.max(d * d - cfg.Height * cfg.Height, 0)))
                local pos = p + Vector3.new(dh, cfg.Height, 0)
                local t0 = os.clock()
                while os.clock() - t0 < 2.5 and t.Parent and running do
                    char:PivotTo(CFrame.lookAt(pos, Vector3.new(p.X, pos.Y, p.Z)))
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    fireSelectedOnce()
                    task.wait(0.1)
                end
                if not t.Parent then lastOk = d else failed = true; break end
            end
        end)
        state.Calibrating = false
        calibrating = false
        table.clear(visited)
        if lastOk then
            if failed then
                cfg.Range = math.max(10, math.floor(lastOk * 0.9 / 5) * 5)
            else
                cfg.Range = lastOk
            end
            local k = kaiju()
            rangeStore[k] = cfg.Range
            rangeBase[k] = cfg.Range
            saveRanges()
            statusCb(cfg.T("Rango detectado: ") .. cfg.Range)
        else
            -- No se guarda nada: se reintentará (o se usa el rango por defecto)
            statusCb(cfg.T("No pude detectar el rango, uso ") .. cfg.Range .. (ok and "" or cfg.T(" (error interno)")))
        end
    end)
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
                    for _ = 1, 6 do
                        if not (running and state.Rejoin) then break end
                        pcall(function() TeleportService:Teleport(game.PlaceId, lp) end)
                        task.wait(8) -- si el teletransporte falla, se reintenta
                    end
                end
            end)
        end
    end)
end)

-- ===== Noclip =====
local ncChar, ncParts, ncT = nil, {}, 0
conns[#conns + 1] = RunService.Stepped:Connect(function()
    if not state.Noclip then return end
    local char = lp.Character
    if not char then return end
    if char ~= ncChar or os.clock() - ncT > 1 then
        ncChar, ncT = char, os.clock()
        table.clear(ncParts)
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then ncParts[#ncParts + 1] = p end
        end
    end
    for _, p in ipairs(ncParts) do
        if p.Parent and p.CanCollide then p.CanCollide = false end
    end
end)

-- ===== Autofarm (automático) =====
-- Mantiene al personaje en el punto elegido (cada frame, sin caer ni derivar)
conns[#conns + 1] = RunService.Heartbeat:Connect(function()
    local s = farmSpot
    if not (s and state.Farm) then return end
    local char = lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    hrp.AssemblyLinearVelocity = Vector3.zero
    if (hrp.Position - s).Magnitude > 8 then
        char:PivotTo(CFrame.new(s) * hrp.CFrame.Rotation)
    end
end)

task.spawn(function()
    local spot, cov, n0, ts = nil, {}, 0, 0
    local lastKaiju, calibTries = nil, 0
    local chkT, chkAlive = 0, 0
    local startT = os.clock()
    while running do
        local char = lp.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        farmActive = false
        farmSpot = nil

        if not state.Farm then
            spot = nil
        elseif hrp and hum and hum.Health > 0 and not state.Calibrating and not state.Collecting then
            local kj = kaiju()
            if kj == "?" and os.clock() - startT < 15 then
                -- esperando a que carguen los datos del jugador
                statusCb(cfg.T("Esperando datos del jugador..."))
                task.wait(1)
            else
                -- Rango guardado por kaiju, o detectarlo la primera vez
                if kj ~= lastKaiju then
                    lastKaiju = kj
                    calibTries = 0
                    spot = nil
                    if rangeStore[kj] then cfg.Range = rangeStore[kj] end
                end
                if not rangeStore[kj] and calibTries < 2 and not calibrating then
                    calibTries += 1
                    calibrate()
                else
                    local now = os.clock()
                    local left = spot and aliveCount(cov) or 0
                    -- Cada 6 s se comprueba si de verdad se está destruyendo algo
                    local stalled = false
                    if spot and now - chkT >= 6 then
                        stalled = left > 0 and left >= chkAlive
                        chkT, chkAlive = now, left
                    end
                    local depleted = spot and left < math.min(n0, math.max(3, math.floor(n0 * 0.5)))
                    if not spot or depleted or stalled or now - ts > 45 then
                        -- Si no destruye nada, se acorta el rango (sin bajar de la mitad
                        -- del detectado ni de 20)
                        if stalled and n0 >= 5 and (n0 - left) / n0 < 0.25 then
                            local floorR = math.max(20, math.floor((rangeBase[kj] or cfg.Range) * 0.5))
                            cfg.Range = math.max(floorR, math.floor(cfg.Range * 0.85))
                            rangeStore[kj] = cfg.Range
                        end
                        autoHeight(char)
                        spot, cov, n0 = bestSpot(getTargets(stalled), cfg.Range)
                        ts, chkT = os.clock(), os.clock()
                        chkAlive = spot and aliveCount(cov) or 0
                        if spot then
                            statusCb((cfg.T("Zona: %d edificios | Rango %d | Altura %d")):format(n0, cfg.Range, cfg.Height))
                        else
                            statusCb(cfg.T("No encuentro edificios, reintentando..."))
                            task.wait(1)
                        end
                    end
                    if spot then
                        farmActive = true
                        farmSpot = spot
                        if (hrp.Position - spot).Magnitude > 20 then
                            char:PivotTo(CFrame.new(spot))
                        end
                        local near = nearestAlive(cov, hrp.Position)
                        if near then
                            local p = posOf(near)
                            if Vector3.new(hrp.Position.X - p.X, 0, hrp.Position.Z - p.Z).Magnitude > 1 then
                                hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(p.X, hrp.Position.Y, p.Z))
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.15)
    end
end)

-- ===== Ataques del farm: lo más rápido que permita el juego =====
-- Un hilo por ataque (ninguno espera a otro). El ritmo se adapta a los FPS.
local function fireDelay()
    if fps >= 45 then return 0.03
    elseif fps >= 30 then return 0.06
    elseif fps >= 20 then return 0.12
    else return 0.25 end
end

for i = 1, 5 do
    task.spawn(function()
        while running do
            if state.Farm and farmActive then
                if selected[i] or (i == 3 and not anySelected()) then
                    task.spawn(useSkill, i)
                end
            end
            task.wait(fireDelay())
        end
    end)
end

-- ===== Auto reaparecer =====
-- El juego usa: Remotes.FireServer:FireServer("Spawn", <kaiju>, <ciudad>)
local CITY = "Tokyo"

local function shown(o)
    while o and o ~= game do
        if o:IsA("GuiObject") and not o.Visible then return false end
        if o:IsA("ScreenGui") and not o.Enabled then return false end
        o = o.Parent
    end
    return true
end

-- Estás en el menú cuando se ve el botón PLAY
local function menuVisible()
    local pg = lp:FindFirstChildOfClass("PlayerGui")
    local m = pg and pg:FindFirstChild("Menu")
    m = m and m:FindFirstChild("Menu")
    m = m and m:FindFirstChild("ButtonList")
    m = m and m:FindFirstChild("Play")
    return m ~= nil and shown(m)
end

local function currentKaiju()
    local pg = lp:FindFirstChildOfClass("PlayerGui")
    local ok, name = pcall(function() return pg.Menu.Menu.Status.CurrentKaiju.TextLabel.Text end)
    if ok and type(name) == "string" and name ~= "" then return name end
    local ls = lp:FindFirstChild("leaderstats")
    local v = ls and ls:FindFirstChild("Kaiju")
    return v and tostring(v.Value) or nil
end

task.spawn(function()
    local since
    while running do
        if state.AutoRespawn and menuVisible() then
            since = since or os.clock()
            if os.clock() - since >= 1.5 then
                local k = currentKaiju()
                local r = RS:FindFirstChild("Remotes")
                r = r and r:FindFirstChild("FireServer")
                if k and r then
                    pcall(function() r:FireServer("Spawn", k, CITY) end)
                    toast(cfg.T("Reapareciendo en ") .. CITY)
                end
                since = os.clock() + 2.5 -- reintenta cada ~4 s si sigue en el menú
            end
        else
            since = nil
        end
        task.wait(0.5)
    end
end)

-- =====================================================================
-- ===== ALERTAS: webhook + detección de jefes, eventos y airdrops =====
-- =====================================================================
local okAL, AL = pcall(function()
local httpReq = request or http_request or (syn and syn.request) or (http and http.request)
local EVENT_FILE, LOG_FILE = "KAHub_Events.txt", "KAHub_Log.txt"
local startClock = os.clock()

local function appendTo(file, text)
    if not canFile then return end
    pcall(function()
        if appendfile then
            appendfile(file, text)
        else
            writefile(file, (isfile(file) and readfile(file) or "") .. text)
        end
    end)
end

-- ---------- Webhook de Discord (cola con pausa para no pasarse del límite) ----------
local whQueue, whBusy, whLast = {}, false, {}
local function whSend(title, desc, color, key, force)
    if not (state.Notify or force) then return end
    local url = cfg.Webhook
    if not httpReq or type(url) ~= "string" or not url:find("/api/webhooks/", 1, true) then return end
    if key then
        if whLast[key] and os.clock() - whLast[key] < 30 then return end
        whLast[key] = os.clock()
    end
    if #whQueue >= 20 then return end
    local okEnc, body = pcall(function()
        return HttpService:JSONEncode({
            username = "KA Hub",
            embeds = {{
                title = title,
                description = desc,
                color = color or 9133302,
                footer = {text = lp.DisplayName .. " | " .. kaiju()},
                timestamp = DateTime.now():ToIsoDate(),
            }},
        })
    end)
    if not okEnc then return end
    whQueue[#whQueue + 1] = {url = url, body = body}
    if whBusy then return end
    whBusy = true
    task.spawn(function()
        while running and #whQueue > 0 do
            local it = table.remove(whQueue, 1)
            local ok, res = pcall(httpReq, {
                Url = it.url, Method = "POST",
                Headers = {["Content-Type"] = "application/json"}, Body = it.body,
            })
            if ok and type(res) == "table" and res.StatusCode == 429 then
                table.insert(whQueue, 1, it)
                task.wait(4)
            end
            task.wait(1.2)
        end
        whBusy = false
    end)
end

-- ---------- Detección de jefes / eventos / airdrops ----------
-- Edita estas palabras si el juego usa otros nombres. "event" solo se busca en textos largos.
local WORDS = {
    boss    = {"boss", "raid", "jefe"},
    airdrop = {"airdrop", "air drop", "supply", "crate"},
    event   = {"event", "invasion", "meteor"},
}
local ORDER = {"boss", "airdrop", "event"}
local LABEL = {boss = cfg.T("Jefe detectado"), airdrop = cfg.T("Airdrop detectado"), event = cfg.T("Evento detectado")}
local COLOR = {boss = 15158332, airdrop = 3447003, event = 15844367}

local function classify(s, isText)
    s = string.lower(tostring(s))
    for _, kind in ipairs(ORDER) do
        if kind ~= "event" or (isText and #s >= 15) then
            for _, w in ipairs(WORDS[kind]) do
                if string.find(s, w, 1, true) then return kind end
            end
        end
    end
end

local function brief(v)
    local t = typeof(v)
    if t == "string" then return '"' .. string.sub(v, 1, 40) .. '"'
    elseif t == "number" or t == "boolean" then return tostring(v)
    elseif t == "Instance" then return v.Name
    else return t end
end
local function briefArgs(...)
    local n, parts = select("#", ...), {}
    for i = 1, math.min(n, 6) do parts[i] = brief((select(i, ...))) end
    return table.concat(parts, ", ")
end

-- Límite de llamadas por segundo y remote (evita saturar con remotes muy frecuentes)
local rate, rateT = {}, 0
local function allowed(r)
    local now = os.clock()
    if now - rateT > 1 then table.clear(rate); rateT = now end
    rate[r] = (rate[r] or 0) + 1
    return rate[r] <= 15
end

local seenEv, lastEv = {}, "ninguno"
local function posText(inst)
    local ok, p = pcall(function()
        if inst:IsA("Model") then return inst:GetPivot().Position end
        return inst.Position
    end)
    if ok and typeof(p) == "Vector3" then
        return ("X %d, Y %d, Z %d"):format(p.X, p.Y, p.Z)
    end
end

local function detected(kind, text, inst)
    if not (running and state.Detect) then return end
    local key = kind .. ":" .. string.sub(tostring(text), 1, 50)
    if seenEv[key] and os.clock() - seenEv[key] < 60 then return end
    seenEv[key] = os.clock()
    local where = inst and posText(inst)
    local msg = tostring(text) .. (where and ("\n" .. cfg.T("Posición: ") .. where) or "")
        .. "\n" .. cfg.T("Servidor: ") .. string.sub(game.JobId, 1, 8) .. cfg.T(" | Jugadores: ") .. #Players:GetPlayers()
    lastEv = LABEL[kind] .. ": " .. string.sub(tostring(text), 1, 60)
    -- el archivo guarda la hora de cada evento: sirve para ver si salen a intervalos fijos
    appendTo(EVENT_FILE, ("[%s] %s | %s\n"):format(os.date("%Y-%m-%d %H:%M:%S"), LABEL[kind], (msg:gsub("\n", " | "))))
    toast(LABEL[kind])
    whSend(LABEL[kind], msg, COLOR[kind], key)
end

local function isCandidate(o)
    return (o:IsA("Model") or o:IsA("BasePart") or o:IsA("Folder"))
        and not Players:GetPlayerFromCharacter(o)
end

local function checkInstance(o)
    if not (running and state.Detect) or not isCandidate(o) then return end
    local kind = classify(o.Name, false)
    if not kind then return end
    task.wait(0.3) -- deja que carguen las partes para leer la posición
    if o.Parent then detected(kind, o.Name, o) end
end

local function watchContainer(c)
    conns[#conns + 1] = c.ChildAdded:Connect(function(o) task.spawn(checkInstance, o) end)
end
watchContainer(workspace)
do
    local mapF = workspace:FindFirstChild("Map")
    if mapF then watchContainer(mapF) end
end

local function scanNow()
    local n = 0
    local function sweep(c)
        for _, o in ipairs(c:GetChildren()) do
            if isCandidate(o) then
                local k = classify(o.Name, false)
                if k then n += 1; detected(k, o.Name .. cfg.T(" (ya presente)"), o) end
            end
        end
    end
    sweep(workspace)
    local m = workspace:FindFirstChild("Map")
    if m then sweep(m) end
    return n
end

-- Avisos del servidor: mensajes del sistema del chat y argumentos de los RemoteEvent
local function scanArgs(v, depth)
    if type(v) == "string" then
        local k = classify(v, true)
        if k then return k, v end
    elseif type(v) == "table" and depth < 3 then
        for _, x in pairs(v) do
            local k, s = scanArgs(x, depth + 1)
            if k then return k, s end
        end
    end
end

local logBuf = {}
local hookedR = setmetatable({}, {__mode = "k"})
local function hookRemote(r)
    if hookedR[r] or not r:IsA("RemoteEvent") then return end
    hookedR[r] = true
    local lname = string.lower(r.Name)
    conns[#conns + 1] = r.OnClientEvent:Connect(function(...)
        if not allowed(r) then return end
        if state.LogRemotes then
            logBuf[#logBuf + 1] = string.format("[%s] IN  %s(%s)", os.date("%H:%M:%S"), r.Name, briefArgs(...))
        end
        if not state.Detect or string.find(lname, "quest", 1, true) then return end
        local kind, txt = classify(lname, false), nil
        if not kind then
            for i = 1, select("#", ...) do
                kind, txt = scanArgs((select(i, ...)), 0)
                if kind then break end
            end
        end
        if kind then
            detected(kind, txt and (cfg.T("Mensaje: ") .. string.sub(txt, 1, 150))
                or ("Remote " .. r.Name .. "(" .. briefArgs(...) .. ")"))
        end
    end)
end
task.spawn(function()
    for i, d in ipairs(RS:GetDescendants()) do
        hookRemote(d)
        if i % 500 == 0 then task.wait() end
    end
end)
conns[#conns + 1] = RS.DescendantAdded:Connect(hookRemote)

pcall(function()
    local TCS = game:GetService("TextChatService")
    conns[#conns + 1] = TCS.MessageReceived:Connect(function(m)
        if m.TextSource ~= nil then return end -- solo mensajes del sistema
        local k = classify(m.Text, true)
        if k then detected(k, cfg.T("Chat: ") .. string.sub(m.Text, 1, 120)) end
    end)
end)

-- ---------- Registro de remotes (para descubrir nombres: battlepass, airdrops...) ----------
-- Guarda en KAHub_Log.txt lo que el servidor manda (IN) y lo que tú envías (OUT).
-- OUT necesita que tu ejecutor soporte hookmetamethod.
local function outFn(self, m, ...)
    if not state.LogRemotes or self == combat then return end
    if not allowed(self) then return end
    logBuf[#logBuf + 1] = string.format("[%s] OUT %s:%s(%s)", os.date("%H:%M:%S"), self.Name, m, briefArgs(...))
end
local function setLogging(on)
    genv.KA_OUT = on and outFn or nil
    if on then toast(cfg.T("Registrando en ") .. LOG_FILE) end
end
task.spawn(function()
    while running do
        task.wait(2)
        if #logBuf > 0 then
            local txt = table.concat(logBuf, "\n") .. "\n"
            table.clear(logBuf)
            appendTo(LOG_FILE, txt)
        end
    end
end)

-- ---------- Reporte periódico y aviso de inicio ----------
task.spawn(function()
    local nextT = os.clock() + 900
    while running do
        if state.Report and os.clock() >= nextT then
            nextT = os.clock() + 900
            local ls = lp:FindFirstChild("leaderstats")
            local function lv(n)
                local v = ls and ls:FindFirstChild(n)
                if not v then return "?" end
                local num = tonumber(v.Value)
                return num and tostring(math.floor(num)) or tostring(v.Value)
            end
            whSend(cfg.T("Reporte"), (cfg.T("Kaiju: %s\nCells: %s\nKills: %s")):format(kaiju(), lv("Cells"), lv("Kills")), 9133302, "report")
        end
        task.wait(5)
    end
end)
task.delay(4, function()
    if running then whSend(cfg.T("Hub iniciado"), cfg.T("KA Hub cargado en ") .. lp.DisplayName, 5763719, "start") end
end)
task.delay(6, function()
    if running then scanNow() end
end)

return {
    httpReq = httpReq, whSend = whSend, setLogging = setLogging, scanNow = scanNow,
    EVENT_FILE = EVENT_FILE,
    last = function() return lastEv end,
}
end)
if not okAL then
    -- si el módulo de alertas falla, el resto del hub sigue cargando
    local why = tostring(AL)
    warn("[KA Hub] módulo de alertas con error: " .. why)
    AL = {
        whSend = function() end, setLogging = function() end, scanNow = function() return 0 end,
        last = function() return "error" end, EVENT_FILE = "KAHub_Events.txt",
    }
end

-- ===== Recolectar Monster Zero Skull / Archetype =====
-- Aparecen como ProximityPrompt (ej: Workspace.Map.Debris.Skull.Cube.ProximityPrompt).
local LOOT_WORDS = {"archetype", "monster zero", "skull", "airdrop"}

local function wordHit(s)
    s = tostring(s):lower()
    for _, w in ipairs(LOOT_WORDS) do
        if s:find(w, 1, true) then return true end
    end
    return false
end

local function lootMatch(pr)
    if wordHit(pr.ObjectText) or wordHit(pr.ActionText) then return true end
    local o = pr.Parent
    for _ = 1, 3 do
        if not o or o == workspace then break end
        if wordHit(o.Name) then return true end
        o = o.Parent
    end
    return false
end

local function lootPos(pr)
    local par = pr.Parent
    if par and par:IsA("Attachment") then return par.WorldPosition end
    if par and par:IsA("BasePart") then return par.Position end
    local bp = pr:FindFirstAncestorWhichIsA("BasePart")
    if bp then return bp.Position end
    local m = pr:FindFirstAncestorWhichIsA("Model")
    return m and m:GetPivot().Position or nil
end

local loot, lootSkip = {}, {}
local function consider(o)
    if o:IsA("ProximityPrompt") and lootMatch(o) then loot[o] = true end
end
conns[#conns + 1] = workspace.DescendantAdded:Connect(function(o)
    if o:IsA("ProximityPrompt") then
        task.wait(0.3)
        if running and o.Parent then consider(o) end
    end
end)
task.spawn(function()
    for i, o in ipairs(workspace:GetDescendants()) do
        consider(o)
        if i % 3000 == 0 then task.wait() end
    end
end)

local function collect(pr)
    local p0 = lootPos(pr)
    if not p0 then return false end
    state.Collecting = true
    farmSpot, farmActive = nil, false
    task.wait(0.4) -- deja que el farm se pause
    pcall(function()
        local tries = 0
        while running and state.Collect and pr.Parent and pr.Enabled and tries < 8 do
            tries += 1
            local char = lp.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not hrp or (hum and hum.Health <= 0) then break end
            char:PivotTo(CFrame.new((lootPos(pr) or p0) + Vector3.new(0, 4, 0)))
            hrp.AssemblyLinearVelocity = Vector3.zero
            task.wait(0.4)
            if fireproximityprompt then
                pcall(fireproximityprompt, pr)
            else
                pcall(function()
                    pr:InputHoldBegin()
                    task.wait(pr.HoldDuration + 0.1)
                    pr:InputHoldEnd()
                end)
            end
            task.wait(0.6)
        end
    end)
    state.Collecting = false
    return (not pr.Parent) or (not pr.Enabled)
end

task.spawn(function()
    while running do
        if state.Collect and not state.Calibrating and not menuVisible() then
            for pr in pairs(loot) do
                if not pr.Parent or not pr.Enabled then
                    loot[pr] = nil
                elseif (lootSkip[pr] or 0) < os.clock() then
                    local label = tostring(pr.ObjectText)
                    if label == "" then label = "item" end
                    if collect(pr) then
                        loot[pr] = nil
                        toast(cfg.T("Recogido: ") .. label)
                    else
                        lootSkip[pr] = os.clock() + 120 -- no lo pudo coger: reintenta en 2 min
                    end
                    break
                end
            end
        end
        task.wait(2)
    end
end)

-- =====================================================================
-- ===== MACRO: grabadora y reproductor de movimientos =================
-- =====================================================================
-- Graba posición, dirección de movimiento, saltos y ataques (1-5).
-- Las macros se guardan en el archivo KAHub_Macros.json si tu ejecutor lo permite.
local REC_STEP = 1 / 25
local MAX_FRAMES = 15000 -- 10 minutos
local FILE = "KAHub_Macros.json"

local rec = {on = false, t0 = 0, last = -1, frames = {}, events = {}}
local play = {token = 0, name = "", t = 0, dur = 0}
local macros, macroOrder, selectedMacro = {}, {}, nil
local nameBox

local function r4(x) return math.floor(x * 10000 + 0.5) / 10000 end

local function fmt(s)
    s = math.max(0, math.floor(s))
    return ("%d:%02d"):format(math.floor(s / 60), s % 60)
end

local function saveMacros()
    if not canFile then return end
    pcall(function()
        writefile(FILE, HttpService:JSONEncode({macros = macros, order = macroOrder}))
    end)
end

local function loadMacros()
    if not canFile then return end
    pcall(function()
        if isfile(FILE) then
            local d = HttpService:JSONDecode(readfile(FILE))
            if d and type(d.macros) == "table" then
                macros = d.macros
                macroOrder = {}
                for _, n in ipairs(d.order or {}) do
                    if macros[n] then macroOrder[#macroOrder + 1] = n end
                end
            end
        end
    end)
end
loadMacros()

local function cfOf(f)
    return CFrame.new(f[2], f[3], f[4], f[5], f[6], f[7], f[8], f[9], f[10], f[11], f[12], f[13])
end

local function recAttack(n)
    if rec.on then
        rec.events[#rec.events + 1] = {t = r4(os.clock() - rec.t0), n = n}
    end
end

-- Ataque hecho desde los botones del hub (se graba y se dispara)
local function playerAttack(n)
    recAttack(n)
    task.spawn(useSkill, n)
end

-- Si el ejecutor lo permite, se detectan también los ataques de los botones del juego.
-- El hook se instala una sola vez (aunque ejecutes el script varias veces).
local hooked = false
genv.KA_COMBAT = combat
genv.KA_OWNFN = function() return ownCalls > 0 end
genv.KA_ATTACK = function(n) if running and rec.on then recAttack(n) end end
pcall(function()
    if genv.KA_HOOKED then hooked = true; return end
    if hookmetamethod and getnamecallmethod then
        local old
        local fn = function(self, ...)
            if genv.KA_OUT and not genv.KA_BUSY then
                local m0 = getnamecallmethod()
                if m0 == "FireServer" or m0 == "InvokeServer" then
                    genv.KA_BUSY = true
                    pcall(genv.KA_OUT, self, m0, ...)
                    genv.KA_BUSY = nil
                end
                if setnamecallmethod then setnamecallmethod(m0) end
            end
            if self == genv.KA_COMBAT and genv.KA_ATTACK then
                local m = getnamecallmethod()
                if m == "FireServer" or m == "InvokeServer" then
                    local mine
                    if checkcaller then mine = checkcaller()
                    else mine = genv.KA_OWNFN and genv.KA_OWNFN() end
                    if not mine then
                        local a, b = ...
                        if a == "UseSkill" and type(b) == "string" then
                            local n = tonumber(b:match("%d+"))
                            if n then genv.KA_ATTACK(n) end
                        end
                    end
                end
            end
            return old(self, ...)
        end
        old = hookmetamethod(game, "__namecall", newcclosure and newcclosure(fn) or fn)
        genv.KA_HOOKED = true
        hooked = true
    end
end)

local KEYMAP = {
    [Enum.KeyCode.One] = 1, [Enum.KeyCode.Two] = 2, [Enum.KeyCode.Three] = 3,
    [Enum.KeyCode.Four] = 4, [Enum.KeyCode.Five] = 5,
}
conns[#conns + 1] = UIS.InputBegan:Connect(function(i)
    if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if i.KeyCode == Enum.KeyCode.RightShift then
        setOpen("toggle")
    elseif rec.on and not hooked and KEYMAP[i.KeyCode] and not UIS:GetFocusedTextBox() then
        recAttack(KEYMAP[i.KeyCode])
    end
end)

local function stopPlayback()
    play.token += 1
    if state.Playing then
        state.Playing = false
        local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
        if hum then pcall(function() hum:Move(Vector3.zero, false) end) end
    end
end

local function stopRecording(save)
    if not rec.on then return end
    rec.on = false
    state.Recording = false
    if save and #rec.frames >= 2 then
        local name = (nameBox and nameBox.Text or ""):match("^%s*(.-)%s*$")
        if name == "" or macros[name] then
            local n = #macroOrder + 1
            if name ~= "" then name = name .. " " end
            local base = name == "" and "Macro " or name
            repeat name = base .. n; n += 1 until not macros[name]
        end
        local last = rec.frames[#rec.frames]
        macros[name] = {dur = last[1], frames = rec.frames, events = rec.events}
        macroOrder[#macroOrder + 1] = name
        selectedMacro = name
        saveMacros()
        refreshList()
        if nameBox then nameBox.Text = "" end
        toast((cfg.T("Macro guardada: %s (%s)")):format(name, fmt(last[1])))
    elseif save then
        toast(cfg.T("Grabación muy corta, descartada"))
    end
    rec.frames, rec.events = {}, {}
end

local function startRecording()
    local char = lp.Character
    if not (char and char:FindFirstChild("HumanoidRootPart")) then
        toast(cfg.T("No hay personaje"))
        return
    end
    stopPlayback()
    rec.frames, rec.events = {}, {}
    rec.t0, rec.last = os.clock(), -1
    rec.on = true
    state.Recording = true
    toast(cfg.T("Grabando... muévete y ataca"))
end

conns[#conns + 1] = RunService.Heartbeat:Connect(function()
    if not rec.on then return end
    local char = lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local t = os.clock() - rec.t0
    if t - rec.last < REC_STEP then return end
    rec.last = t
    local hum = char:FindFirstChildOfClass("Humanoid")
    local md = hum and hum.MoveDirection or Vector3.zero
    local f = {r4(t)}
    local c = {hrp.CFrame:GetComponents()}
    for k = 1, 12 do f[k + 1] = r4(c[k]) end
    f[14], f[15] = r4(md.X), r4(md.Z)
    f[16] = (hum and (hum.Jump or hum:GetState() == Enum.HumanoidStateType.Jumping)) and 1 or 0
    rec.frames[#rec.frames + 1] = f
    if #rec.frames >= MAX_FRAMES then
        stopRecording(true)
        toast(cfg.T("Límite de grabación alcanzado (10 min)"))
    end
end)

local function playMacro(name)
    local m = name and macros[name]
    if not m or not m.frames or #m.frames < 2 then
        toast(cfg.T("Selecciona una macro de la lista"))
        return
    end
    if state.Farm then
        toast(cfg.T("Apaga el Auto Farm antes de reproducir una macro"))
        return
    end
    if rec.on then stopRecording(true) end
    stopPlayback()
    local my = play.token
    state.Playing = true
    play.name, play.dur, play.t = name, m.dur or 0, 0
    task.spawn(function()
        local frames, events = m.frames, m.events or {}
        local base = frames[1][1]
        local lastT = frames[#frames][1]
        repeat
            local char = lp.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hrp and hum then
                local i, ei, wasJ = 1, 1, false
                hrp.CFrame = cfOf(frames[1])
                local t0 = os.clock()
                while running and play.token == my and hrp.Parent do
                    local t = base + (os.clock() - t0) * cfg.Speed
                    if t >= lastT then break end
                    while i < #frames - 1 and frames[i + 1][1] <= t do i += 1 end
                    local a, b = frames[i], frames[i + 1]
                    local al = math.clamp((t - a[1]) / math.max(b[1] - a[1], 1e-3), 0, 1)
                    hrp.CFrame = cfOf(a):Lerp(cfOf(b), al)
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hum:Move(Vector3.new(a[14], 0, a[15]), false)
                    local j = a[16] == 1
                    if j and not wasJ then hum.Jump = true end
                    wasJ = j
                    while events[ei] and events[ei].t <= t do
                        task.spawn(useSkill, events[ei].n)
                        ei += 1
                    end
                    play.t = t - base
                    RunService.Heartbeat:Wait()
                end
                pcall(function() hum:Move(Vector3.zero, false) end)
            else
                task.wait(0.5)
            end
            task.wait(0.05)
        until not (state.Loop and running and play.token == my)
        if play.token == my then stopPlayback() end
    end)
end

-- =====================================================================
-- ===== INTERFAZ ======================================================
-- =====================================================================
local gui = Instance.new("ScreenGui")
gui.Name = "KAHub"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = (gethui and gethui()) or CoreGui

-- Paleta morado / negro
local BG     = Color3.fromRGB(10, 8, 17)
local BG2    = Color3.fromRGB(26, 15, 44)
local PANEL  = Color3.fromRGB(18, 13, 30)
local CARD   = Color3.fromRGB(30, 22, 49)
local OFF    = Color3.fromRGB(47, 38, 72)
local ACC    = Color3.fromRGB(139, 92, 246)
local ACC2   = Color3.fromRGB(196, 150, 255)
local DEEP   = Color3.fromRGB(92, 53, 172)
local DANGER = Color3.fromRGB(190, 48, 96)
local TXT    = Color3.fromRGB(242, 236, 255)
local SUB    = Color3.fromRGB(150, 138, 182)

local LEFT = Enum.TextXAlignment.Left
local GM, GB = Enum.Font.GothamMedium, Enum.Font.GothamBold
local TI = TweenInfo.new(0.15, Enum.EasingStyle.Quad)

local function mk(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end
local function corner(o, r) return mk("UICorner", {CornerRadius = UDim.new(0, r or 8)}, o) end
local function stroke(o, col, tr, th)
    return mk("UIStroke", {
        Color = col or ACC, Transparency = tr or 0.75, Thickness = th or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, o)
end
local function titleGradient(o)
    mk("UIGradient", {Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, ACC2),
        ColorSequenceKeypoint.new(1, ACC),
    })}, o)
end

-- Marca de agua
local mark = mk("TextLabel", {
    Size = UDim2.fromOffset(330, 18), Position = UDim2.new(0, 12, 0, 4),
    BackgroundTransparency = 1, TextColor3 = ACC2, TextStrokeTransparency = 0.4,
    TextStrokeColor3 = Color3.new(0, 0, 0), TextXAlignment = LEFT, Font = GM, TextSize = 12,
}, gui)

-- Bienvenida
local splash = mk("Frame", {
    Size = UDim2.fromOffset(300, 140), AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundColor3 = BG, BorderSizePixel = 0,
}, gui)
corner(splash, 14); stroke(splash, ACC, 0.3, 1.5)
mk("UIGradient", {Color = ColorSequence.new(BG2, BG), Rotation = 90}, splash)
local function splashLabel(text, y, size, font, color)
    return mk("TextLabel", {
        Size = UDim2.new(1, -20, 0, size + 6), Position = UDim2.new(0, 10, 0, y),
        BackgroundTransparency = 1, Text = text, TextColor3 = color or TXT,
        Font = font, TextSize = size,
    }, splash)
end
titleGradient(splashLabel("KA HUB", 12, 30, Enum.Font.GothamBlack, Color3.new(1, 1, 1)))
splashLabel(cfg.T("Bienvenido, ") .. lp.DisplayName, 56, 15, GM)
local splashFps = splashLabel("FPS: --", 82, 14, GM, ACC2)
splashLabel(cfg.T("Cargando menú..."), 110, 12, Enum.Font.Gotham, SUB)

-- Ventana principal
local win = mk("Frame", {
    Size = UDim2.fromOffset(580, 360), AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundColor3 = BG,
    BorderSizePixel = 0, Active = true, Visible = false,
}, gui)
corner(win, 14); stroke(win, ACC, 0.35, 1.5)
mk("UIGradient", {Color = ColorSequence.new(BG2, BG), Rotation = 90}, win)
local uiScale = mk("UIScale", {}, win)

local function rescale()
    local cam = workspace.CurrentCamera
    if not cam then return end
    local v = cam.ViewportSize
    uiScale.Scale = math.clamp(math.min(v.X / 620, v.Y / 400), 0.5, 1)
end
rescale()
pcall(function()
    conns[#conns + 1] = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
end)

-- Barra de título
local titleBar = mk("Frame", {Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1}, win)
titleGradient(mk("TextLabel", {
    Size = UDim2.fromOffset(110, 46), Position = UDim2.new(0, 18, 0, 0),
    BackgroundTransparency = 1, Text = "KA HUB", TextColor3 = Color3.new(1, 1, 1),
    TextXAlignment = LEFT, Font = Enum.Font.GothamBlack, TextSize = 24,
}, titleBar))
mk("TextLabel", {
    Size = UDim2.fromOffset(160, 46), Position = UDim2.new(0, 124, 0, 2),
    BackgroundTransparency = 1, Text = "Kaiju Alpha", TextColor3 = SUB,
    TextXAlignment = LEFT, Font = GM, TextSize = 12,
}, titleBar)
local minBtn = mk("TextButton", {
    Size = UDim2.fromOffset(32, 26), Position = UDim2.new(1, -44, 0.5, -13),
    BackgroundColor3 = OFF, Text = "-", TextColor3 = TXT, Font = GB, TextSize = 18,
    AutoButtonColor = false,
}, titleBar)
corner(minBtn, 8)
mk("Frame", {
    Size = UDim2.new(1, -28, 0, 1), Position = UDim2.new(0, 14, 0, 46),
    BackgroundColor3 = ACC, BackgroundTransparency = 0.7, BorderSizePixel = 0,
}, win)

-- Burbuja para reabrir el menú
local bubble = mk("TextButton", {
    Size = UDim2.fromOffset(46, 46), Position = UDim2.new(0, 16, 0.5, -23),
    BackgroundColor3 = DEEP, Text = "KA", TextColor3 = TXT, Font = Enum.Font.GothamBlack,
    TextSize = 16, AutoButtonColor = false, Visible = false,
}, gui)
corner(bubble, 23); stroke(bubble, ACC2, 0.2, 1.5)

setOpen = function(v)
    if v == "toggle" then v = not win.Visible end
    if splash.Parent then return end
    win.Visible = v
    bubble.Visible = not v
end
minBtn.Activated:Connect(function() setOpen(false) end)
bubble.Activated:Connect(function() setOpen(true) end)

-- Arrastrar
do
    local dragging, startPos, startInput
    titleBar.InputBegan:Connect(function(i)
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
            local d = (i.Position - startInput) / uiScale.Scale
            win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

-- Barra lateral (secciones)
local sidebar = mk("Frame", {
    Size = UDim2.new(0, 150, 1, -96), Position = UDim2.new(0, 0, 0, 56),
    BackgroundTransparency = 1,
}, win)
mk("UIListLayout", {Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder}, sidebar)
mk("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 8)}, sidebar)
mk("TextLabel", {
    Size = UDim2.new(0, 140, 0, 28), Position = UDim2.new(0, 12, 1, -34),
    BackgroundTransparency = 1, Text = cfg.T("RightShift: mostrar / ocultar"),
    TextColor3 = SUB, TextWrapped = true, TextXAlignment = LEFT,
    Font = Enum.Font.Gotham, TextSize = 10,
}, win)

-- Panel de contenido
local panel = mk("Frame", {
    Size = UDim2.new(1, -160, 1, -64), Position = UDim2.new(0, 150, 0, 54),
    BackgroundColor3 = PANEL, BorderSizePixel = 0,
}, win)
corner(panel, 10); stroke(panel, ACC, 0.82, 1)
local footer = mk("TextLabel", {
    Size = UDim2.new(1, -24, 0, 18), Position = UDim2.new(0, 12, 1, -22),
    BackgroundTransparency = 1, Text = "", TextColor3 = ACC2, TextXAlignment = LEFT,
    Font = GM, TextSize = 11,
}, panel)
toast = function(t)
    footer.Text = t
    task.delay(4, function()
        if footer.Parent and footer.Text == t then footer.Text = "" end
    end)
end

local pages, tabBtns, tabBars, tabCount = {}, {}, {}, 0
local orders = {}

local function show(name)
    for n, p in pairs(pages) do p.Visible = (n == name) end
    for n, b in pairs(tabBtns) do
        local on = (n == name)
        b.BackgroundTransparency = on and 0.35 or 1
        b.TextColor3 = on and TXT or SUB
        tabBars[n].Visible = on
    end
end

local function newPage(name, label)
    local p = mk("ScrollingFrame", {
        Size = UDim2.new(1, -16, 1, -34), Position = UDim2.new(0, 8, 0, 8),
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
        ScrollBarImageColor3 = ACC, CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
        Visible = false,
    }, panel)
    mk("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, p)
    mk("UIPadding", {
        PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 8),
    }, p)
    pages[name] = p

    tabCount += 1
    local b = mk("TextButton", {
        Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = DEEP, BackgroundTransparency = 1,
        Text = cfg.T(label), TextColor3 = SUB, TextXAlignment = LEFT, Font = GB, TextSize = 14,
        AutoButtonColor = false, LayoutOrder = tabCount,
    }, sidebar)
    corner(b, 9)
    mk("UIPadding", {PaddingLeft = UDim.new(0, 16)}, b)
    tabBars[name] = mk("Frame", {
        Size = UDim2.new(0, 3, 0.55, 0), Position = UDim2.new(0, -12, 0.225, 0),
        BackgroundColor3 = ACC2, BorderSizePixel = 0, Visible = false,
    }, b)
    corner(tabBars[name], 2)
    b.Activated:Connect(function() show(name) end)
    tabBtns[name] = b
    return p
end

-- ===== Componentes =====
local function place(page, obj)
    orders[page] = (orders[page] or 0) + 1
    obj.LayoutOrder = orders[page]
    obj.Parent = page
    return obj
end

local function section(page, text)
    return place(page, mk("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = cfg.T(text),
        TextColor3 = ACC2, TextXAlignment = LEFT, Font = GB, TextSize = 11,
    }))
end

local function card(page, h)
    local f = mk("Frame", {Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = CARD, BorderSizePixel = 0})
    corner(f, 9); stroke(f, ACC, 0.8, 1)
    return place(page, f)
end

local function button(page, text, color, cb)
    local b = mk("TextButton", {
        Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = color, Text = cfg.T(text), TextColor3 = TXT,
        Font = GB, TextSize = 14, AutoButtonColor = false,
    })
    corner(b, 9)
    place(page, b)
    b.Activated:Connect(function() cb(b) end)
    return b
end

local function row(page, h)
    return place(page, mk("Frame", {Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1}))
end

local function half(r, idx, text, color, cb)
    local b = mk("TextButton", {
        Size = UDim2.new(0.5, -3, 1, 0),
        Position = idx == 1 and UDim2.new(0, 0, 0, 0) or UDim2.new(0.5, 3, 0, 0),
        BackgroundColor3 = color, Text = cfg.T(text), TextColor3 = TXT, Font = GB, TextSize = 14,
        AutoButtonColor = false,
    }, r)
    corner(b, 9)
    b.Activated:Connect(function() cb(b) end)
    return b
end

local function toggle(page, name, key, onChange)
    local c = card(page, 38)
    mk("TextLabel", {
        Size = UDim2.new(1, -70, 1, 0), Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1, Text = cfg.T(name), TextColor3 = TXT, TextXAlignment = LEFT,
        Font = GM, TextSize = 14,
    }, c)
    local function knobPos(on) return on and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7) end
    local track = mk("Frame", {
        Size = UDim2.fromOffset(40, 20), Position = UDim2.new(1, -52, 0.5, -10),
        BackgroundColor3 = state[key] and ACC or OFF, BorderSizePixel = 0,
    }, c)
    corner(track, 10)
    local knob = mk("Frame", {
        Size = UDim2.fromOffset(14, 14), Position = knobPos(state[key]),
        BackgroundColor3 = TXT, BorderSizePixel = 0,
    }, track)
    corner(knob, 7)
    local hit = mk("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = ""}, c)
    hit.Activated:Connect(function()
        state[key] = not state[key]
        TweenService:Create(track, TI, {BackgroundColor3 = state[key] and ACC or OFF}):Play()
        TweenService:Create(knob, TI, {Position = knobPos(state[key])}):Play()
        if onChange then onChange(state[key]) end
        saveConfig()
    end)
    return c
end

local function stepper(page, name, key, step, min, max, suffix)
    local c = card(page, 38)
    local lbl = mk("TextLabel", {
        Size = UDim2.new(1, -90, 1, 0), Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1, TextColor3 = TXT, TextXAlignment = LEFT, Font = GM, TextSize = 14,
    }, c)
    local function refresh() lbl.Text = cfg.T(name) .. ": " .. cfg[key] .. (suffix or "") end
    refresh()
    local function mkb(txt, x, delta)
        local b = mk("TextButton", {
            Size = UDim2.fromOffset(30, 26), Position = UDim2.new(1, x, 0.5, -13),
            BackgroundColor3 = OFF, Text = txt, TextColor3 = TXT, Font = GB, TextSize = 16,
            AutoButtonColor = false,
        }, c)
        corner(b, 8)
        b.Activated:Connect(function()
            cfg[key] = math.clamp(cfg[key] + delta, min, max)
            refresh()
            saveConfig()
        end)
    end
    mkb("-", -74, -step)
    mkb("+", -40, step)
    return c
end

-- Fila de 5 botones numerados
local function chips(page, onClick)
    local r = row(page, 32)
    mk("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, r)
    local btns = {}
    for i = 1, 5 do
        local b = mk("TextButton", {
            Size = UDim2.new(0.2, -5, 1, 0), BackgroundColor3 = OFF, Text = tostring(i),
            TextColor3 = TXT, Font = GB, TextSize = 14, AutoButtonColor = false, LayoutOrder = i,
        }, r)
        corner(b, 9)
        b.Activated:Connect(function() onClick(i, b) end)
        btns[i] = b
    end
    return btns
end

local qot = queue_on_teleport or (syn and syn.queue_on_teleport)
-- Al teletransportarte (rejoin, cambio de servidor) se vuelve a poner en cola el script
-- con el farm en el mismo estado en que estaba.
if qot then
    conns[#conns + 1] = lp.OnTeleport:Connect(function()
        if not state.AutoExec then return end
        local code = "getgenv().KA_AUTOEXEC = true\ngetgenv().KA_RESUME = " .. tostring(state.Farm)
            .. "\ngetgenv().KA_SRC = [=====[" .. (genv.KA_SRC or "") .. "]=====]"
            .. "\nloadstring(getgenv().KA_SRC)()"
        pcall(qot, code)
    end)
end

-- =====================================================================
-- Sección: MACRO (grabadora)
-- =====================================================================
local pMacro = newPage("Macro", "Macro")
section(pMacro, "GRABADORA DE MOVIMIENTOS")

local stCard = card(pMacro, 54)
local macroStatus = mk("TextLabel", {
    Size = UDim2.new(1, -24, 0, 22), Position = UDim2.new(0, 12, 0, 6), BackgroundTransparency = 1,
    Text = cfg.T("Listo para grabar"), TextColor3 = TXT, TextXAlignment = LEFT, Font = GB, TextSize = 14,
}, stCard)
local macroInfo = mk("TextLabel", {
    Size = UDim2.new(1, -24, 0, 18), Position = UDim2.new(0, 12, 0, 30), BackgroundTransparency = 1,
    Text = cfg.T("Seleccionada: ") .. cfg.T("ninguna"), TextColor3 = SUB, TextXAlignment = LEFT, Font = GM, TextSize = 12,
}, stCard)

local nameCard = card(pMacro, 36)
nameBox = mk("TextBox", {
    Size = UDim2.new(1, -24, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1,
    Text = "", PlaceholderText = cfg.T("Nombre de la macro (opcional)"), PlaceholderColor3 = SUB,
    TextColor3 = TXT, TextXAlignment = LEFT, ClearTextOnFocus = false, Font = GM, TextSize = 13,
}, nameCard)

local ctl = row(pMacro, 36)
local recBtn = half(ctl, 1, "Grabar", DANGER, function()
    if rec.on then stopRecording(true) else startRecording() end
end)
local playBtn = half(ctl, 2, "Reproducir", ACC, function()
    if state.Playing then stopPlayback() else playMacro(selectedMacro) end
end)

toggle(pMacro, "Repetir en bucle", "Loop")
stepper(pMacro, "Velocidad", "Speed", 0.25, 0.25, 3, "x")

section(pMacro, "ATAQUES (se graban mientras grabas)")
chips(pMacro, function(i, b)
    playerAttack(i)
    b.BackgroundColor3 = ACC
    task.delay(0.15, function() if b.Parent then b.BackgroundColor3 = OFF end end)
end)

section(pMacro, "MACROS GUARDADOS")
local listFrame = place(pMacro, mk("Frame", {
    Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
}))
mk("UIListLayout", {Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder}, listFrame)

refreshList = function()
    for _, c in ipairs(listFrame:GetChildren()) do
        if c:IsA("GuiObject") then c:Destroy() end
    end
    local shown = 0
    for idx, name in ipairs(macroOrder) do
        local m = macros[name]
        if m then
            shown += 1
            local r = mk("Frame", {
                Size = UDim2.new(1, 0, 0, 38),
                BackgroundColor3 = (name == selectedMacro) and DEEP or CARD,
                BorderSizePixel = 0, LayoutOrder = idx,
            }, listFrame)
            corner(r, 9); stroke(r, ACC, (name == selectedMacro) and 0.3 or 0.8, 1)
            local nb = mk("TextButton", {
                Size = UDim2.new(1, -112, 1, 0), Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1, TextColor3 = TXT, TextXAlignment = LEFT,
                Font = GM, TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd,
                Text = name .. "  (" .. fmt(m.dur or 0) .. ")",
            }, r)
            nb.Activated:Connect(function() selectedMacro = name; refreshList() end)
            local pb = mk("TextButton", {
                Size = UDim2.fromOffset(46, 26), Position = UDim2.new(1, -98, 0.5, -13),
                BackgroundColor3 = ACC, Text = cfg.T("Play"), TextColor3 = TXT, Font = GB, TextSize = 12,
                AutoButtonColor = false,
            }, r)
            corner(pb, 8)
            pb.Activated:Connect(function()
                selectedMacro = name
                refreshList()
                playMacro(name)
            end)
            local db = mk("TextButton", {
                Size = UDim2.fromOffset(40, 26), Position = UDim2.new(1, -48, 0.5, -13),
                BackgroundColor3 = DANGER, Text = "X", TextColor3 = TXT, Font = GB, TextSize = 12,
                AutoButtonColor = false,
            }, r)
            corner(db, 8)
            db.Activated:Connect(function()
                if state.Playing and play.name == name then stopPlayback() end
                macros[name] = nil
                for k, n in ipairs(macroOrder) do
                    if n == name then table.remove(macroOrder, k); break end
                end
                if selectedMacro == name then selectedMacro = nil end
                saveMacros()
                refreshList()
            end)
        end
    end
    if shown == 0 then
        mk("TextLabel", {
            Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, TextWrapped = true,
            Text = cfg.T("Aún no hay macros. Pulsa Grabar, muévete y ataca, y luego Detener y guardar."),
            TextColor3 = SUB, TextXAlignment = LEFT, Font = Enum.Font.Gotham, TextSize = 12,
        }, listFrame)
    end
end
if not selectedMacro then selectedMacro = macroOrder[1] end
refreshList()

if not canFile then
    mk("TextLabel", {
        Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, TextWrapped = true,
        Text = cfg.T("Tu ejecutor no permite guardar archivos: las macros se perderán al salir."),
        TextColor3 = SUB, TextXAlignment = LEFT, Font = Enum.Font.Gotham, TextSize = 11,
    }, pMacro).LayoutOrder = 999
end

-- =====================================================================
-- Sección: AUTOFARM
-- =====================================================================
local pFarm = newPage("Autofarm", "Autofarm")
section(pFarm, "CIUDAD")
toggle(pFarm, "Auto Farm City", "Farm", function(on)
    if on and state.Playing then stopPlayback() end
end)
local farmCard = card(pFarm, 62)
local farmStatus = mk("TextLabel", {
    Size = UDim2.new(1, -24, 1, -12), Position = UDim2.new(0, 12, 0, 6), BackgroundTransparency = 1,
    Text = cfg.T("Automático: detecta el rango, ajusta la altura y va a la zona con más edificios."),
    TextColor3 = SUB, TextWrapped = true, TextXAlignment = LEFT,
    TextYAlignment = Enum.TextYAlignment.Top, Font = Enum.Font.Gotham, TextSize = 12,
}, farmCard)
statusCb = function(text) farmStatus.Text = text end
toggle(pFarm, "Auto reaparecer", "AutoRespawn")
toggle(pFarm, "Recolectar Skull/Archetype", "Collect")
button(pFarm, "Recalibrar rango", DEEP, function()
    local k = kaiju()
    rangeStore[k], rangeBase[k] = nil, nil
    saveRanges()
    calibrate()
end)

section(pFarm, "ATAQUES A USAR")
local atkBtns = chips(pFarm, function(i, b)
    selected[i] = not selected[i]
    b.BackgroundColor3 = selected[i] and ACC or OFF
    saveConfig()
end)
for i, b in ipairs(atkBtns) do b.BackgroundColor3 = selected[i] and ACC or OFF end

do
local okUI, errUI = pcall(function()
    local function infoLabel(c)
        return mk("TextLabel", {
            Size = UDim2.new(1, -24, 1, -8), Position = UDim2.new(0, 12, 0, 4), BackgroundTransparency = 1,
            Text = "", TextColor3 = SUB, TextWrapped = true, TextXAlignment = LEFT,
            TextYAlignment = Enum.TextYAlignment.Top, Font = Enum.Font.Gotham, TextSize = 12,
        }, c)
    end

    -- =================================================================
    -- Sección: ALERTAS (webhook y detección)
    -- =================================================================
    local pAlert = newPage("Alertas", "Alertas")
    section(pAlert, "DISCORD")
    local whCard = card(pAlert, 36)
    local whBox = mk("TextBox", {
        Size = UDim2.new(1, -24, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1,
        Text = cfg.Webhook, PlaceholderText = cfg.T("URL del webhook de Discord"), PlaceholderColor3 = SUB,
        TextColor3 = TXT, TextXAlignment = LEFT, ClearTextOnFocus = false, Font = GM, TextSize = 12,
    }, whCard)
    whBox.FocusLost:Connect(function()
        cfg.Webhook = whBox.Text:match("^%s*(.-)%s*$") or ""
        saveConfig()
    end)
    toggle(pAlert, "Enviar notificaciones", "Notify")
    toggle(pAlert, "Reporte cada 15 min", "Report")
    button(pAlert, "Enviar mensaje de prueba", DEEP, function()
        if not AL.httpReq then toast(cfg.T("Tu ejecutor no soporta peticiones HTTP")); return end
        if not cfg.Webhook:find("/api/webhooks/", 1, true) then toast(cfg.T("Pega primero la URL del webhook")); return end
        AL.whSend(cfg.T("Prueba"), cfg.T("El webhook funciona"), 5763719, nil, true)
        toast(cfg.T("Prueba enviada"))
    end)

    section(pAlert, "DETECCIÓN")
    toggle(pAlert, "Jefes / eventos / airdrops", "Detect")
    toggle(pAlert, "Registrar remotes (depurar)", "LogRemotes", AL.setLogging)
    local dLbl = infoLabel(card(pAlert, 54))
    button(pAlert, "Escanear ahora", DEEP, function()
        toast((cfg.T("Escaneo listo: %d coincidencias")):format(AL.scanNow()))
    end)

    task.spawn(function()
        while running do
            dLbl.Text = cfg.T("Último: ") .. AL.last() .. "\n" .. cfg.T("Historial en ") .. AL.EVENT_FILE
            task.wait(1)
        end
    end)
end)
if not okUI then warn("[KA Hub] UI Auto/Alertas: " .. tostring(errUI)) end
end

-- =====================================================================
-- Sección: MISC
-- =====================================================================
local pMisc = newPage("Misc", "Misc")
section(pMisc, "SISTEMA")
toggle(pMisc, "Anti-AFK", "AntiAFK")
toggle(pMisc, "Auto Rejoin", "Rejoin")
toggle(pMisc, "Auto Execute", "AutoExec", function(on)
    genv.KA_AUTOEXEC = on
    if on and not qot then toast(cfg.T("Tu ejecutor no soporta queue_on_teleport")) end
end)
toggle(pMisc, "Noclip", "Noclip")
local origShadows = Lighting.GlobalShadows
local origQuality
pcall(function() origQuality = settings().Rendering.QualityLevel end)
local function applyLow(on)
    pcall(function() RunService:Set3dRenderingEnabled(not on) end)
    pcall(function()
        settings().Rendering.QualityLevel = on and Enum.QualityLevel.Level01 or (origQuality or Enum.QualityLevel.Automatic)
    end)
    Lighting.GlobalShadows = on and false or origShadows
end
toggle(pMisc, "Modo bajo consumo", "Low", applyLow)

local function unload()
    running = false
    stopPlayback()
    rec.on = false
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    farmSpot = nil
    if state.Low then pcall(applyLow, false) end
    pcall(function() RunService:Set3dRenderingEnabled(true) end)
    genv.KA_ATTACK = nil
    genv.KA_OUT = nil
    gui:Destroy()
    genv.KA_UNLOAD = nil
end
genv.KA_UNLOAD = unload
section(pMisc, "IDIOMA")
pcall(function()
    local langRow = row(pMisc, 34)
    local langs = {{"es", "Español"}, {"en", "English"}, {"th", "ไทย"}}
    for i, L in ipairs(langs) do
        local b = mk("TextButton", {
            Size = UDim2.new(1 / 3, -4, 1, 0), Position = UDim2.new((i - 1) / 3, (i - 1) * 2, 0, 0),
            BackgroundColor3 = (cfg.Lang == L[1]) and ACC or OFF, Text = L[2], TextColor3 = TXT,
            Font = GB, TextSize = 13, AutoButtonColor = false,
        }, langRow)
        corner(b, 9)
        b.Activated:Connect(function()
            if cfg.Lang == L[1] then return end
            cfg.Lang = L[1]
            genv.KA_LANG = L[1]
            saveConfig()
            toast(cfg.T("Cambiando idioma..."))
            -- Se recarga el hub para reconstruir toda la interfaz en el nuevo idioma
            task.delay(0.8, function()
                genv.KA_RESUME = state.Farm
                local src = genv.KA_SRC
                if src then loadstring(src)() end
            end)
        end)
    end
end)
section(pMisc, "")
button(pMisc, "Descargar script", DANGER, function() unload() end)

show("Macro")

-- ===== Estado de la grabadora (se actualiza solo) =====
task.spawn(function()
    while running do
        if rec.on then
            macroStatus.Text = (cfg.T("GRABANDO  %s  |  %d puntos  |  %d ataques"))
                :format(fmt(os.clock() - rec.t0), #rec.frames, #rec.events)
            macroStatus.TextColor3 = Color3.fromRGB(255, 120, 160)
            recBtn.Text = cfg.T("Detener y guardar")
        elseif state.Playing then
            macroStatus.Text = (cfg.T("REPRODUCIENDO  %s  |  %s / %s"))
                :format(play.name, fmt(play.t), fmt(play.dur))
            macroStatus.TextColor3 = ACC2
            recBtn.Text = cfg.T("Grabar")
        else
            macroStatus.Text = cfg.T("Listo para grabar")
            macroStatus.TextColor3 = TXT
            recBtn.Text = cfg.T("Grabar")
        end
        playBtn.Text = state.Playing and cfg.T("Detener") or cfg.T("Reproducir")
        playBtn.BackgroundColor3 = state.Playing and DANGER or ACC
        macroInfo.Text = cfg.T("Seleccionada: ") .. (selectedMacro or cfg.T("ninguna"))
        task.wait(0.2)
    end
end)

-- ===== FPS / marca de agua =====
local frames, last = 0, os.clock()
local killLog = {}
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
        local kn = tonumber(kills)
        local perMin = "-"
        if kn then
            killLog[#killLog + 1] = {os.clock(), kn}
            while #killLog > 2 and os.clock() - killLog[1][1] > 60 do table.remove(killLog, 1) end
            local f, l = killLog[1], killLog[#killLog]
            if l[1] - f[1] >= 5 then perMin = tostring(math.floor((l[2] - f[2]) * 60 / (l[1] - f[1]))) end
        end
        mark.Text = ("KA HUB | Cells %s | Kills %s (%s/min) | %d FPS | %d ms"):format(cells, kills, perMin, fps, ping)
    end
end)

-- Cerrar la bienvenida y mostrar el menú
task.delay(3.5, function()
    if not running then return end
    splash:Destroy()
    setOpen(true)
end)
]==]

getgenv().KA_SRC = SRC
loadstring(SRC)()
