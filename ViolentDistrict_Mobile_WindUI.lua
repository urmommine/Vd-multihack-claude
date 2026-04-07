-- Violent District - Mobile Edition (WindUI)
-- Original script converted for mobile: keybinds removed, UI rebuilt with WindUI
-- Requires executor with Drawing API support

local function SafeDrawing(type)
    local success, result = pcall(function()
        return Drawing.new(type)
    end)
    if success then return result end
    return nil
end

local function SafeRemove(obj)
    if obj and obj.Remove then
        pcall(function() obj:Remove() end)
    end
end

if not Drawing or not Drawing.new then
    local waited = 0
    while not Drawing and waited < 5 do
        task.wait(0.1)
        waited = waited + 0.1
    end
    if not Drawing then
        warn("[Violence] Drawing library not available.")
        return
    end
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local Config = {
    ESP_Enabled = true,
    ESP_Killer = true,
    ESP_Survivor = true,
    ESP_Generator = true,
    ESP_Gate = true,
    ESP_Hook = true,
    ESP_Pallet = true,
    ESP_Window = false,
    ESP_Distance = true,
    ESP_Names = true,
    ESP_Health = true,
    ESP_Skeleton = false,
    ESP_Offscreen = true,
    ESP_Velocity = false,
    ESP_ClosestHook = true,
    ESP_MaxDist = 500,
    ESP_PlayerChams = false,
    ESP_ObjectChams = true,

    RADAR_Enabled = false,
    RADAR_Size = 120,
    RADAR_Circle = false,
    RADAR_Killer = true,
    RADAR_Survivor = true,
    RADAR_Generator = true,
    RADAR_Pallet = true,

    AUTO_Generator = false,
    AUTO_GenMode = "Fast",
    AUTO_LeaveGen = false,
    AUTO_LeaveDist = 18,
    AUTO_Attack = false,
    AUTO_AttackRange = 12,
    HITBOX_Enabled = false,
    HITBOX_Size = 15,
    AUTO_TeleAway = false,
    AUTO_TeleAwayDist = 40,

    AUTO_Parry = false,
    AUTO_SkillCheck = false,
    SURV_NoFall = false,
    SURV_AutoWiggle = false,
    KILLER_DestroyPallets = false,
    KILLER_FullGenBreak = false,
    KILLER_NoPalletStun = false,
    KILLER_AutoHook = false,
    KILLER_AntiBlind = false,
    KILLER_NoSlowdown = false,
    KILLER_DoubleTap = false,
    KILLER_InfiniteLunge = false,
    SPEED_Enabled = false,
    SPEED_Value = 32,
    SPEED_Method = "Attribute",
    NOCLIP_Enabled = false,
    FLY_Enabled = false,
    FLY_Speed = 50,
    FLY_Method = "CFrame",
    JUMP_Power = 50,
    JUMP_Infinite = false,

    NO_Fog = false,
    CAM_FOVEnabled = false,
    CAM_FOV = 90,
    CAM_ThirdPerson = false,
    CAM_ShiftLock = false,
    FLING_Enabled = false,
    FLING_Strength = 10000,

    BEAT_Survivor = false,
    BEAT_Killer = false,

    TP_Offset = 3,

    AIM_Enabled = false,
    AIM_FOV = 120,
    AIM_Smooth = 0.3,
    AIM_TargetPart = "Head",
    AIM_VisCheck = true,
    AIM_ShowFOV = true,
    AIM_Predict = true,

    SPEAR_Aimbot = false,
    SPEAR_Gravity = 50,
    SPEAR_Speed = 100
}

local Tuning = {
    ESP_RefreshRate = 0.08,
    ESP_VisCheckRate = 0.15,
    Gen_RefreshRate = 0.2,
    CacheRefreshRate = 1.0,
    Box_WidthRatio = 0.55,
    Name_Offset = 18,
    Dist_Offset = 5,
    Health_Width = 4,
    Health_Offset = 6,
    Offscreen_Edge = 50,
    Offscreen_Size = 12,
    Skel_Thickness = 1,
    Box_Thickness = 1,
    RadarRange = 150,
    RadarDotSize = 5,
    RadarArrowSize = 8
}

local Colors = {
    Killer = Color3.fromRGB(255, 65, 65),
    KillerVis = Color3.fromRGB(255, 120, 120),
    Survivor = Color3.fromRGB(65, 220, 130),
    SurvivorVis = Color3.fromRGB(120, 255, 170),
    Generator = Color3.fromRGB(255, 180, 50),
    GeneratorDone = Color3.fromRGB(100, 255, 130),
    Gate = Color3.fromRGB(200, 200, 220),
    Hook = Color3.fromRGB(255, 100, 100),
    HookClose = Color3.fromRGB(255, 230, 80),
    Pallet = Color3.fromRGB(220, 180, 100),
    Window = Color3.fromRGB(100, 180, 255),
    Skeleton = Color3.fromRGB(255, 255, 255),
    SkeletonVis = Color3.fromRGB(150, 255, 150),
    Offscreen = Color3.fromRGB(255, 255, 255),
    HealthHigh = Color3.fromRGB(100, 255, 100),
    HealthMid = Color3.fromRGB(255, 220, 60),
    HealthLow = Color3.fromRGB(255, 70, 70),
    HealthBg = Color3.fromRGB(25, 25, 25),
    RadarBg = Color3.fromRGB(20, 20, 20),
    RadarBorder = Color3.fromRGB(255, 65, 65),
    RadarYou = Color3.fromRGB(0, 255, 0)
}

local ChamsColors = {
    Killer = {fill = Color3.fromRGB(180, 40, 40), outline = Color3.fromRGB(255, 80, 80), fillTrans = 0.6},
    Survivor = {fill = Color3.fromRGB(40, 160, 80), outline = Color3.fromRGB(80, 255, 130), fillTrans = 0.6},
    Generator = {fill = Color3.fromRGB(200, 140, 30), outline = Color3.fromRGB(255, 200, 80), fillTrans = 0.5},
    Gate = {fill = Color3.fromRGB(150, 150, 170), outline = Color3.fromRGB(220, 220, 255), fillTrans = 0.5},
    Hook = {fill = Color3.fromRGB(180, 60, 60), outline = Color3.fromRGB(255, 100, 100), fillTrans = 0.5},
    HookClose = {fill = Color3.fromRGB(200, 180, 40), outline = Color3.fromRGB(255, 240, 100), fillTrans = 0.4},
    Pallet = {fill = Color3.fromRGB(180, 140, 70), outline = Color3.fromRGB(255, 210, 130), fillTrans = 0.5},
    Window = {fill = Color3.fromRGB(60, 140, 200), outline = Color3.fromRGB(120, 200, 255), fillTrans = 0.5}
}

local Bones_R15 = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
}

local Bones_R6 = {
    {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"}, {"Torso", "Left Leg"}, {"Torso", "Right Leg"}
}

local State = {
    Unloaded = false,
    LastESPUpdate = 0,
    LastVisCheck = 0,
    LastGenUpdate = 0,
    LastCacheUpdate = 0,
    LastTeleAway = 0,
    AimTarget = nil,
    AimHolding = false,
    OriginalSpeed = 16,
    LastFogState = false,
    KillerTarget = nil,
    LastBeatTP = 0,
    LastFinishPos = nil,
    BeatSurvivorDone = false
}

local Cache = {
    Players = {},
    Generators = {},
    Gates = {},
    Hooks = {},
    Pallets = {},
    Windows = {},
    Visibility = {},
    ClosestHook = nil
}

local Connections = {}
local Unload

-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================

local function GetRole()
    if not LocalPlayer.Team then return "Unknown" end
    local name = LocalPlayer.Team.Name
    if name == "Killer" then return "Killer" end
    if name == "Survivors" then return "Survivor" end
    return "Lobby"
end

local function IsKiller(player)
    return player and player.Team and player.Team.Name == "Killer"
end

local function IsSurvivor(player)
    return player and player.Team and player.Team.Name == "Survivors"
end

local function GetCharacterRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function IsR6(char)
    return char:FindFirstChild("Torso") ~= nil
end

local function GetDistance(pos)
    local root = GetCharacterRoot()
    if not root then return math.huge end
    return (pos - root.Position).Magnitude
end

local function IsVisible(char)
    if not char then return false end
    local cam = workspace.CurrentCamera
    if not cam then return false end
    local origin = cam.CFrame.Position
    local parts = {"Head", "UpperTorso", "Torso", "HumanoidRootPart"}
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {cam, LocalPlayer.Character, char}
    for _, partName in ipairs(parts) do
        local part = char:FindFirstChild(partName)
        if part then
            local dir = part.Position - origin
            local ray = workspace:Raycast(origin, dir, params)
            if not ray then return true end
        end
    end
    return false
end

local function WorldToScreen(pos)
    local cam = workspace.CurrentCamera
    if not cam then return Vector2.new(), false, 0 end
    local screen, onScreen = cam:WorldToViewportPoint(pos)
    return Vector2.new(screen.X, screen.Y), onScreen, screen.Z
end

local function Lerp(a, b, t)
    return a + (b - a) * t
end

local function LerpColor(c1, c2, t)
    return Color3.new(
        c1.R + (c2.R - c1.R) * t,
        c1.G + (c2.G - c1.G) * t,
        c1.B + (c2.B - c1.B) * t
    )
end

-- ============================================================
-- CHAMS
-- ============================================================

local Chams = { Objects = {}, Labels = {} }

function Chams.Create(target, colorData, label)
    if not target or not target:IsA("Instance") then return nil end
    local existing = target:FindFirstChild("_ViolenceChams")
    if existing then existing:Destroy() end
    local highlight = Instance.new("Highlight")
    highlight.Name = "_ViolenceChams"
    highlight.Adornee = target
    highlight.FillColor = colorData.fill
    highlight.OutlineColor = colorData.outline
    highlight.FillTransparency = colorData.fillTrans
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = target
    local data = {highlight = highlight, target = target}
    if label then
        local rootPart = target:IsA("Model") and (target:FindFirstChild("HumanoidRootPart") or target:FindFirstChildWhichIsA("BasePart")) or target
        if rootPart then
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "_ViolenceLabel"
            billboard.Size = UDim2.new(0, 80, 0, 18)
            billboard.AlwaysOnTop = true
            billboard.StudsOffset = Vector3.new(0, 3, 0)
            billboard.Adornee = rootPart
            billboard.Parent = target
            local textLabel = Instance.new("TextLabel")
            textLabel.Size = UDim2.new(1, 0, 1, 0)
            textLabel.BackgroundTransparency = 1
            textLabel.TextColor3 = colorData.outline
            textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
            textLabel.TextStrokeTransparency = 0.2
            textLabel.Font = Enum.Font.Gotham
            textLabel.TextSize = 10
            textLabel.TextScaled = false
            textLabel.Text = label
            textLabel.Parent = billboard
            data.billboard = billboard
            data.textLabel = textLabel
            data.rootPart = rootPart
        end
    end
    Chams.Objects[target] = data
    return data
end

function Chams.Update(target, newLabel, newDist)
    local data = Chams.Objects[target]
    if not data then return end
    if data.textLabel and newLabel then
        local text = newLabel
        if newDist and Config.ESP_Distance then
            text = text .. "\n" .. math.floor(newDist) .. "m"
        end
        data.textLabel.Text = text
    end
end

function Chams.SetColor(target, colorData)
    local data = Chams.Objects[target]
    if not data or not data.highlight then return end
    data.highlight.FillColor = colorData.fill
    data.highlight.OutlineColor = colorData.outline
    data.highlight.FillTransparency = colorData.fillTrans
    if data.textLabel then
        data.textLabel.TextColor3 = colorData.outline
    end
end

function Chams.Remove(target)
    local data = Chams.Objects[target]
    if data then
        if data.highlight and data.highlight.Parent then data.highlight:Destroy() end
        if data.billboard and data.billboard.Parent then data.billboard:Destroy() end
        Chams.Objects[target] = nil
    end
    if target then
        local existing = target:FindFirstChild("_ViolenceChams")
        if existing then existing:Destroy() end
        local existingLabel = target:FindFirstChild("_ViolenceLabel")
        if existingLabel then existingLabel:Destroy() end
    end
end

function Chams.ClearAll()
    for target, _ in pairs(Chams.Objects) do Chams.Remove(target) end
    Chams.Objects = {}
end

-- ============================================================
-- ESP
-- ============================================================

local ESP = { cache = {}, objectCache = {}, velocityData = {} }

function ESP.create()
    local skel = {}
    for i = 1, 14 do
        skel[i] = Drawing.new("Line")
        skel[i].Thickness = 1
        skel[i].Visible = false
    end
    local box = {}
    for i = 1, 4 do
        box[i] = Drawing.new("Line")
        box[i].Thickness = 1
        box[i].Visible = false
    end
    return {
        Box = box,
        Name = Drawing.new("Text"),
        Dist = Drawing.new("Text"),
        Skel = skel,
        HealthBg = Drawing.new("Square"),
        HealthBar = Drawing.new("Square"),
        Offscreen = Drawing.new("Triangle"),
        VelLine = Drawing.new("Line"),
        VelArrow = Drawing.new("Triangle")
    }
end

function ESP.setup(esp)
    for _, l in ipairs(esp.Box) do l.Thickness = 1; l.Visible = false end
    esp.Name.Size = 14; esp.Name.Font = Drawing.Fonts.Monospace
    esp.Name.Center = true; esp.Name.Outline = true; esp.Name.Visible = false
    esp.Dist.Size = 12; esp.Dist.Font = Drawing.Fonts.Monospace
    esp.Dist.Center = true; esp.Dist.Outline = true
    esp.Dist.Color = Color3.fromRGB(180, 180, 180); esp.Dist.Visible = false
    for _, l in ipairs(esp.Skel) do l.Thickness = 1; l.Visible = false end
    esp.HealthBg.Filled = true; esp.HealthBg.Color = Colors.HealthBg; esp.HealthBg.Visible = false
    esp.HealthBar.Filled = true; esp.HealthBar.Visible = false
    esp.Offscreen.Filled = true; esp.Offscreen.Visible = false
    esp.VelLine.Thickness = 2; esp.VelLine.Color = Color3.fromRGB(0, 255, 255); esp.VelLine.Visible = false
    esp.VelArrow.Filled = true; esp.VelArrow.Color = Color3.fromRGB(0, 255, 255); esp.VelArrow.Visible = false
end

function ESP.hide(esp)
    if not esp then return end
    for _, l in ipairs(esp.Box) do l.Visible = false end
    esp.Name.Visible = false; esp.Dist.Visible = false
    for _, l in ipairs(esp.Skel) do l.Visible = false end
    esp.HealthBg.Visible = false; esp.HealthBar.Visible = false
    esp.Offscreen.Visible = false; esp.VelLine.Visible = false; esp.VelArrow.Visible = false
end

function ESP.destroy(esp)
    if not esp then return end
    pcall(function()
        for _, l in ipairs(esp.Box) do l:Remove() end
        esp.Name:Remove(); esp.Dist:Remove()
        for _, l in ipairs(esp.Skel) do l:Remove() end
        esp.HealthBg:Remove(); esp.HealthBar:Remove()
        esp.Offscreen:Remove(); esp.VelLine:Remove(); esp.VelArrow:Remove()
    end)
end

function ESP.hideAll()
    for _, esp in pairs(ESP.cache) do ESP.hide(esp) end
end

function ESP.cleanup()
    local validPlayers = {}
    for _, p in ipairs(Players:GetPlayers()) do validPlayers[p] = true end
    for player, esp in pairs(ESP.cache) do
        if not validPlayers[player] then
            ESP.hide(esp); ESP.destroy(esp)
            ESP.cache[player] = nil; ESP.velocityData[player] = nil
        end
    end
end

function ESP.createObject()
    local box = {}
    for i = 1, 4 do
        box[i] = Drawing.new("Line"); box[i].Thickness = 1; box[i].Visible = false
    end
    return { Box = box, Label = Drawing.new("Text"), Dist = Drawing.new("Text") }
end

function ESP.setupObject(esp)
    for _, l in ipairs(esp.Box) do l.Thickness = 1; l.Visible = false end
    esp.Label.Size = 13; esp.Label.Font = Drawing.Fonts.Monospace
    esp.Label.Center = true; esp.Label.Outline = true; esp.Label.Visible = false
    esp.Dist.Size = 11; esp.Dist.Font = Drawing.Fonts.Monospace
    esp.Dist.Center = true; esp.Dist.Outline = true
    esp.Dist.Color = Color3.fromRGB(160, 160, 160); esp.Dist.Visible = false
end

function ESP.hideObject(esp)
    if not esp then return end
    for _, l in ipairs(esp.Box) do l.Visible = false end
    esp.Label.Visible = false; esp.Dist.Visible = false
end

function ESP.destroyObject(esp)
    if not esp then return end
    pcall(function()
        for _, l in ipairs(esp.Box) do l:Remove() end
        esp.Label:Remove(); esp.Dist:Remove()
    end)
end

function ESP.render(esp, player, char, cam, screenSize, screenCenter)
    local root = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not root or not head then ESP.hide(esp); return end
    local myRoot = GetCharacterRoot()
    local dist = myRoot and (root.Position - myRoot.Position).Magnitude or 0
    if dist > Config.ESP_MaxDist then ESP.hide(esp); return end
    local isKillerPlayer = IsKiller(player)
    local visible = Cache.Visibility[player]
    local col = isKillerPlayer and (visible and Colors.KillerVis or Colors.Killer) or (visible and Colors.SurvivorVis or Colors.Survivor)
    local skelCol = visible and Colors.SkeletonVis or Colors.Skeleton
    local headPos = head.Position + Vector3.new(0, 0.5, 0)
    local feetPos = root.Position - Vector3.new(0, 3, 0)
    local rs = cam:WorldToViewportPoint(root.Position)
    local hs = cam:WorldToViewportPoint(headPos)
    local fs = cam:WorldToViewportPoint(feetPos)
    local onScreen = rs.Z > 0 and rs.X > 0 and rs.X < screenSize.X and rs.Y > 0 and rs.Y < screenSize.Y
    if not onScreen then
        for _, l in ipairs(esp.Box) do l.Visible = false end
        esp.Name.Visible = false; esp.Dist.Visible = false
        for _, l in ipairs(esp.Skel) do l.Visible = false end
        esp.HealthBg.Visible = false; esp.HealthBar.Visible = false
        esp.VelLine.Visible = false; esp.VelArrow.Visible = false
        if Config.ESP_Offscreen and visible then
            local dx = rs.X - screenCenter.X
            local dy = rs.Y - screenCenter.Y
            local angle = math.atan2(dy, dx)
            local edge = 50
            local arrowX = math.clamp(screenCenter.X + math.cos(angle) * (screenSize.X/2 - edge), edge, screenSize.X - edge)
            local arrowY = math.clamp(screenCenter.Y + math.sin(angle) * (screenSize.Y/2 - edge), edge, screenSize.Y - edge)
            local fwd = Vector2.new(math.cos(angle), math.sin(angle))
            local right = Vector2.new(-fwd.Y, fwd.X)
            local pos = Vector2.new(arrowX, arrowY)
            local arrowSize = 12
            esp.Offscreen.PointA = pos + fwd * arrowSize
            esp.Offscreen.PointB = pos - fwd * arrowSize/2 - right * arrowSize/2
            esp.Offscreen.PointC = pos - fwd * arrowSize/2 + right * arrowSize/2
            esp.Offscreen.Color = col; esp.Offscreen.Visible = true
        else
            esp.Offscreen.Visible = false
        end
        return
    end
    esp.Offscreen.Visible = false
    local boxTop = hs.Y
    local boxBottom = fs.Y
    local boxHeight = math.abs(boxBottom - boxTop)
    local boxWidth = boxHeight * 0.6
    local cx = rs.X
    esp.Box[1].From = Vector2.new(cx - boxWidth/2, boxTop); esp.Box[1].To = Vector2.new(cx + boxWidth/2, boxTop)
    esp.Box[2].From = Vector2.new(cx + boxWidth/2, boxTop); esp.Box[2].To = Vector2.new(cx + boxWidth/2, boxBottom)
    esp.Box[3].From = Vector2.new(cx + boxWidth/2, boxBottom); esp.Box[3].To = Vector2.new(cx - boxWidth/2, boxBottom)
    esp.Box[4].From = Vector2.new(cx - boxWidth/2, boxBottom); esp.Box[4].To = Vector2.new(cx - boxWidth/2, boxTop)
    for _, l in ipairs(esp.Box) do l.Color = col; l.Visible = true end
    if Config.ESP_Names then
        esp.Name.Text = player.Name; esp.Name.Position = Vector2.new(cx, boxTop - 18)
        esp.Name.Color = col; esp.Name.Visible = true
    else esp.Name.Visible = false end
    if Config.ESP_Distance then
        esp.Dist.Text = math.floor(dist) .. "m"
        esp.Dist.Position = Vector2.new(cx, boxBottom + 4); esp.Dist.Visible = true
    else esp.Dist.Visible = false end
    if Config.ESP_Health and hum then
        local pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
        local barX = cx - boxWidth/2 - 6
        local barH = boxHeight * pct
        esp.HealthBg.Position = Vector2.new(barX - 1, boxTop - 1)
        esp.HealthBg.Size = Vector2.new(5, boxHeight + 2); esp.HealthBg.Visible = true
        esp.HealthBar.Position = Vector2.new(barX, boxBottom - barH)
        esp.HealthBar.Size = Vector2.new(3, barH)
        esp.HealthBar.Color = pct > 0.6 and Colors.HealthHigh or pct > 0.3 and Colors.HealthMid or Colors.HealthLow
        esp.HealthBar.Visible = true
    else esp.HealthBg.Visible = false; esp.HealthBar.Visible = false end
    if Config.ESP_Skeleton then
        local bones = IsR6(char) and Bones_R6 or Bones_R15
        for i, b in ipairs(bones) do
            if esp.Skel[i] then
                local p1 = char:FindFirstChild(b[1]); local p2 = char:FindFirstChild(b[2])
                if p1 and p2 then
                    local s1 = cam:WorldToViewportPoint(p1.Position)
                    local s2 = cam:WorldToViewportPoint(p2.Position)
                    if s1.Z > 0 and s2.Z > 0 then
                        esp.Skel[i].From = Vector2.new(s1.X, s1.Y); esp.Skel[i].To = Vector2.new(s2.X, s2.Y)
                        esp.Skel[i].Color = skelCol; esp.Skel[i].Visible = true
                    else esp.Skel[i].Visible = false end
                else esp.Skel[i].Visible = false end
            end
        end
        for i = #bones + 1, #esp.Skel do
            if esp.Skel[i] then esp.Skel[i].Visible = false end
        end
    else for _, l in ipairs(esp.Skel) do l.Visible = false end end
    local vd = ESP.velocityData[player]
    if not vd then
        vd = {pos = root.Position, vel = Vector3.zero, time = tick()}
        ESP.velocityData[player] = vd
    end
    local now = tick()
    local dt = now - vd.time
    if dt > 0.03 then
        local rawVel = (root.Position - vd.pos) / dt
        vd.vel = vd.vel * 0.7 + rawVel * 0.3
        vd.pos = root.Position; vd.time = now
    end
    if Config.ESP_Velocity then
        local velFlat = Vector3.new(vd.vel.X, 0, vd.vel.Z)
        local velMag = velFlat.Magnitude
        if velMag > 2 then
            local futurePos = root.Position + velFlat.Unit * math.clamp(velMag * 0.4, 5, 20)
            local futureScreen, futureOn = cam:WorldToViewportPoint(futurePos)
            if futureOn and futureScreen.Z > 0 then
                esp.VelLine.From = Vector2.new(rs.X, rs.Y)
                esp.VelLine.To = Vector2.new(futureScreen.X, futureScreen.Y); esp.VelLine.Visible = true
                local dx, dy = futureScreen.X - rs.X, futureScreen.Y - rs.Y
                local len = math.sqrt(dx*dx + dy*dy)
                if len > 5 then
                    local fx, fy = dx/len, dy/len
                    esp.VelArrow.PointA = Vector2.new(futureScreen.X, futureScreen.Y)
                    esp.VelArrow.PointB = Vector2.new(futureScreen.X - fx*10 + fy*5, futureScreen.Y - fy*10 - fx*5)
                    esp.VelArrow.PointC = Vector2.new(futureScreen.X - fx*10 - fy*5, futureScreen.Y - fy*10 + fx*5)
                    esp.VelArrow.Visible = true
                else esp.VelArrow.Visible = false end
            else esp.VelLine.Visible = false; esp.VelArrow.Visible = false end
        else esp.VelLine.Visible = false; esp.VelArrow.Visible = false end
    else esp.VelLine.Visible = false; esp.VelArrow.Visible = false end
end

function ESP.renderObject(esp, pos, label, color, cam)
    local myRoot = GetCharacterRoot()
    local dist = myRoot and (pos - myRoot.Position).Magnitude or 0
    if dist > Config.ESP_MaxDist then ESP.hideObject(esp); return end
    local screen = cam:WorldToViewportPoint(pos)
    if screen.Z <= 0 then ESP.hideObject(esp); return end
    local size = math.clamp(800 / screen.Z, 16, 60)
    esp.Box[1].From = Vector2.new(screen.X - size/2, screen.Y - size/2); esp.Box[1].To = Vector2.new(screen.X + size/2, screen.Y - size/2)
    esp.Box[2].From = Vector2.new(screen.X + size/2, screen.Y - size/2); esp.Box[2].To = Vector2.new(screen.X + size/2, screen.Y + size/2)
    esp.Box[3].From = Vector2.new(screen.X + size/2, screen.Y + size/2); esp.Box[3].To = Vector2.new(screen.X - size/2, screen.Y + size/2)
    esp.Box[4].From = Vector2.new(screen.X - size/2, screen.Y + size/2); esp.Box[4].To = Vector2.new(screen.X - size/2, screen.Y - size/2)
    for _, l in ipairs(esp.Box) do l.Color = color; l.Visible = true end
    esp.Label.Text = label; esp.Label.Position = Vector2.new(screen.X, screen.Y - size/2 - 14)
    esp.Label.Color = color; esp.Label.Visible = true
    if Config.ESP_Distance then
        esp.Dist.Text = math.floor(dist) .. "m"
        esp.Dist.Position = Vector2.new(screen.X, screen.Y + size/2 + 2); esp.Dist.Visible = true
    else esp.Dist.Visible = false end
end

function ESP.step(cam, screenSize, screenCenter)
    if not Config.ESP_Enabled then ESP.hideAll(); return end
    ESP.cleanup()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then
                if ESP.cache[player] then ESP.hide(ESP.cache[player]) end
            else
                local isKillerPlayer = IsKiller(player)
                local shouldShow = (isKillerPlayer and Config.ESP_Killer) or (not isKillerPlayer and Config.ESP_Survivor)
                if not shouldShow then
                    if ESP.cache[player] then ESP.hide(ESP.cache[player]) end
                    Chams.Remove(char)
                else
                    if not Config.ESP_PlayerChams then
                        if not ESP.cache[player] then
                            ESP.cache[player] = ESP.create(); ESP.setup(ESP.cache[player])
                        end
                        ESP.render(ESP.cache[player], player, char, cam, screenSize, screenCenter)
                        Chams.Remove(char)
                    else
                        if ESP.cache[player] then ESP.hide(ESP.cache[player]) end
                        local colorData = isKillerPlayer and ChamsColors.Killer or ChamsColors.Survivor
                        local root = char:FindFirstChild("HumanoidRootPart")
                        local dist = root and GetDistance(root.Position) or 0
                        if not Chams.Objects[char] then
                            Chams.Create(char, colorData, player.Name)
                        else
                            Chams.SetColor(char, colorData)
                        end
                        Chams.Update(char, player.Name, dist)
                    end
                end
            end
        end
    end
end

-- ============================================================
-- RADAR
-- ============================================================

local Radar = {
    bg = Drawing.new("Square"),
    circleBg = Drawing.new("Circle"),
    border = Drawing.new("Square"),
    circleBorder = Drawing.new("Circle"),
    cross1 = Drawing.new("Line"),
    cross2 = Drawing.new("Line"),
    center = Drawing.new("Triangle"),
    dots = {},
    objectDots = {},
    palletSquares = {}
}

do
    Radar.bg.Filled = true; Radar.bg.Color = Colors.RadarBg; Radar.bg.Transparency = 0.8
    Radar.circleBg.Filled = true; Radar.circleBg.Color = Colors.RadarBg; Radar.circleBg.Transparency = 0.8; Radar.circleBg.NumSides = 64
    Radar.border.Filled = false; Radar.border.Color = Colors.RadarBorder; Radar.border.Thickness = 2
    Radar.circleBorder.Filled = false; Radar.circleBorder.Color = Colors.RadarBorder; Radar.circleBorder.Thickness = 2; Radar.circleBorder.NumSides = 64
    Radar.cross1.Color = Color3.fromRGB(40, 40, 40); Radar.cross1.Thickness = 1
    Radar.cross2.Color = Color3.fromRGB(40, 40, 40); Radar.cross2.Thickness = 1
    Radar.center.Filled = true; Radar.center.Color = Colors.RadarYou
    for i = 1, 100 do
        local d = Drawing.new("Triangle"); d.Filled = true; d.Visible = false; Radar.dots[i] = d
    end
    for i = 1, 100 do
        local d = Drawing.new("Circle"); d.Filled = true; d.Visible = false; d.NumSides = 16; Radar.objectDots[i] = d
    end
    for i = 1, 100 do
        local d = Drawing.new("Square"); d.Filled = true; d.Visible = false; Radar.palletSquares[i] = d
    end
end

function Radar.hideAll()
    Radar.bg.Visible = false; Radar.circleBg.Visible = false; Radar.border.Visible = false
    Radar.circleBorder.Visible = false; Radar.center.Visible = false
    Radar.cross1.Visible = false; Radar.cross2.Visible = false
    for _, d in pairs(Radar.dots) do d.Visible = false end
    for _, d in pairs(Radar.objectDots) do d.Visible = false end
    for _, d in pairs(Radar.palletSquares) do d.Visible = false end
end

function Radar.step(cam)
    if not Config.RADAR_Enabled then Radar.hideAll(); return end
    local size = Config.RADAR_Size
    local pos = Vector2.new(cam.ViewportSize.X - size - 20, 20)
    local center = pos + Vector2.new(size/2, size/2)
    local useCircle = Config.RADAR_Circle
    if useCircle then
        Radar.bg.Visible = false; Radar.border.Visible = false
        Radar.circleBg.Position = center; Radar.circleBg.Radius = size/2; Radar.circleBg.Visible = true
        Radar.circleBorder.Position = center; Radar.circleBorder.Radius = size/2; Radar.circleBorder.Visible = true
    else
        Radar.circleBg.Visible = false; Radar.circleBorder.Visible = false
        Radar.bg.Position = pos; Radar.bg.Size = Vector2.new(size, size); Radar.bg.Visible = true
        Radar.border.Position = pos; Radar.border.Size = Vector2.new(size, size); Radar.border.Visible = true
    end
    Radar.cross1.From = Vector2.new(center.X - size/2, center.Y); Radar.cross1.To = Vector2.new(center.X + size/2, center.Y); Radar.cross1.Visible = true
    Radar.cross2.From = Vector2.new(center.X, center.Y - size/2); Radar.cross2.To = Vector2.new(center.X, center.Y + size/2); Radar.cross2.Visible = true
    Radar.center.PointA = center + Vector2.new(0, -5)
    Radar.center.PointB = center + Vector2.new(-4, 4)
    Radar.center.PointC = center + Vector2.new(4, 4)
    Radar.center.Visible = true
    local myRoot = GetCharacterRoot()
    if not myRoot then Radar.hideAll(); return end
    local myCF = myRoot.CFrame
    local range = Tuning.RadarRange
    local dotIdx = 0
    for _, d in pairs(Radar.dots) do d.Visible = false end
    for _, d in pairs(Radar.objectDots) do d.Visible = false end
    for _, d in pairs(Radar.palletSquares) do d.Visible = false end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local pRoot = player.Character:FindFirstChild("HumanoidRootPart")
            if pRoot then
                local isKillerPlayer = IsKiller(player)
                local shouldShow = (isKillerPlayer and Config.RADAR_Killer) or (not isKillerPlayer and Config.RADAR_Survivor)
                if shouldShow then
                    dotIdx = dotIdx + 1
                    if dotIdx <= 100 then
                        local rel = myCF:PointToObjectSpace(pRoot.Position)
                        local rx = math.clamp(rel.X / range, -1, 1)
                        local rz = math.clamp(-rel.Z / range, -1, 1)
                        local dx = rx * (size/2 - 8)
                        local dz = rz * (size/2 - 8)
                        local dotPos = center + Vector2.new(dx, -dz)
                        local dot = Radar.dots[dotIdx]
                        local col = isKillerPlayer and Colors.Killer or Colors.Survivor
                        local ds = Tuning.RadarDotSize
                        dot.PointA = dotPos + Vector2.new(0, -ds)
                        dot.PointB = dotPos + Vector2.new(-ds, ds)
                        dot.PointC = dotPos + Vector2.new(ds, ds)
                        dot.Color = col; dot.Visible = true
                    end
                end
            end
        end
    end
    local objIdx = 0
    for _, gen in ipairs(Cache.Generators) do
        if gen.part and Config.RADAR_Generator then
            objIdx = objIdx + 1
            if objIdx <= 100 then
                local rel = myCF:PointToObjectSpace(gen.part.Position)
                local rx = math.clamp(rel.X / range, -1, 1)
                local rz = math.clamp(-rel.Z / range, -1, 1)
                local dotPos = center + Vector2.new(rx * (size/2 - 8), -rz * (size/2 - 8))
                local dot = Radar.objectDots[objIdx]
                dot.Position = dotPos; dot.Radius = 3; dot.Color = Colors.Generator; dot.Visible = true
            end
        end
    end
end

-- ============================================================
-- MAP SCAN & VISIBILITY
-- ============================================================

local function ScanMap()
    Cache.Generators = {}; Cache.Gates = {}; Cache.Hooks = {}; Cache.Pallets = {}; Cache.Windows = {}
    local map = Workspace:FindFirstChild("Map")
    if not map then return end
    for _, obj in ipairs(map:GetDescendants()) do
        local n = obj.Name
        if obj:IsA("Model") then
            if n == "Generator" then
                local part = obj:FindFirstChildWhichIsA("BasePart")
                if part then table.insert(Cache.Generators, {model = obj, part = part}) end
            elseif n == "ExitGate" or n == "Gate" then
                local part = obj:FindFirstChildWhichIsA("BasePart")
                if part then table.insert(Cache.Gates, {model = obj, part = part}) end
            elseif n == "Hook" then
                local part = obj:FindFirstChildWhichIsA("BasePart")
                if part then table.insert(Cache.Hooks, {model = obj, part = part}) end
            elseif n == "Pallet" then
                local part = obj:FindFirstChildWhichIsA("BasePart")
                if part then table.insert(Cache.Pallets, {model = obj, part = part}) end
            elseif n == "Window" then
                local part = obj:FindFirstChildWhichIsA("BasePart")
                if part then table.insert(Cache.Windows, {model = obj, part = part}) end
            end
        end
    end
    local myRoot = GetCharacterRoot()
    if myRoot then
        local closestDist = math.huge
        for _, hook in ipairs(Cache.Hooks) do
            if hook.part then
                local d = (hook.part.Position - myRoot.Position).Magnitude
                if d < closestDist then closestDist = d; Cache.ClosestHook = hook end
            end
        end
    end
end

local function UpdateVisibility()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            Cache.Visibility[player] = IsVisible(player.Character)
        end
    end
end

local function UpdateObjectESP(cam)
    local objIdx = 0
    local function ensureObjESP()
        objIdx = objIdx + 1
        if not ESP.objectCache[objIdx] then
            ESP.objectCache[objIdx] = ESP.createObject()
            ESP.setupObject(ESP.objectCache[objIdx])
        end
        return ESP.objectCache[objIdx]
    end
    local function renderObj(pos, label, color)
        local esp = ensureObjESP()
        ESP.renderObject(esp, pos, label, color, cam)
    end
    local myRoot = GetCharacterRoot()
    if Config.ESP_Generator then
        for _, gen in ipairs(Cache.Generators) do
            if gen.part then
                local prog = gen.model:FindFirstChild("Progress")
                local done = prog and prog.Value >= 100
                renderObj(gen.part.Position, done and "GEN [DONE]" or "GEN", done and Colors.GeneratorDone or Colors.Generator)
                if Config.ESP_ObjectChams and not done then
                    if not Chams.Objects[gen.model] then Chams.Create(gen.model, ChamsColors.Generator, nil) end
                elseif Chams.Objects[gen.model] then Chams.Remove(gen.model) end
            end
        end
    end
    if Config.ESP_Gate then
        for _, gate in ipairs(Cache.Gates) do
            if gate.part then renderObj(gate.part.Position, "GATE", Colors.Gate) end
        end
    end
    if Config.ESP_Hook then
        for _, hook in ipairs(Cache.Hooks) do
            if hook.part then
                local isClosest = Config.ESP_ClosestHook and (Cache.ClosestHook == hook)
                local col = isClosest and Colors.HookClose or Colors.Hook
                renderObj(hook.part.Position, isClosest and "HOOK [CLOSE]" or "HOOK", col)
                if Config.ESP_ObjectChams then
                    local cd = isClosest and ChamsColors.HookClose or ChamsColors.Hook
                    if not Chams.Objects[hook.model] then Chams.Create(hook.model, cd, nil)
                    else Chams.SetColor(hook.model, cd) end
                end
            end
        end
    end
    if Config.ESP_Pallet then
        for _, pallet in ipairs(Cache.Pallets) do
            if pallet.part then renderObj(pallet.part.Position, "PALLET", Colors.Pallet) end
        end
    end
    if Config.ESP_Window then
        for _, win in ipairs(Cache.Windows) do
            if win.part then renderObj(win.part.Position, "WINDOW", Colors.Window) end
        end
    end
    for i = objIdx + 1, #ESP.objectCache do
        ESP.hideObject(ESP.objectCache[i])
    end
end

-- ============================================================
-- AIMBOT
-- ============================================================

local Aimbot = {}
function Aimbot.Update(cam, screenSize, screenCenter)
    if not Config.AIM_Enabled then State.AimTarget = nil; return end
    local myRoot = GetCharacterRoot()
    if not myRoot then return end
    local bestTarget, bestDist = nil, Config.AIM_FOV
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetPart = player.Character:FindFirstChild(Config.AIM_TargetPart)
                or player.Character:FindFirstChild("HumanoidRootPart")
            if targetPart then
                if not Config.AIM_VisCheck or Cache.Visibility[player] then
                    local screenPos, onScreen = cam:WorldToViewportPoint(targetPart.Position)
                    if onScreen and screenPos.Z > 0 then
                        local dx = screenPos.X - screenCenter.X
                        local dy = screenPos.Y - screenCenter.Y
                        local dist = math.sqrt(dx*dx + dy*dy)
                        if dist < bestDist then
                            bestDist = dist; bestTarget = {player = player, part = targetPart}
                        end
                    end
                end
            end
        end
    end
    State.AimTarget = bestTarget
    if bestTarget and State.AimHolding then
        local targetPos = bestTarget.part.Position
        if Config.AIM_Predict then
            local vd = ESP.velocityData[bestTarget.player]
            if vd and vd.vel.Magnitude > 1 then
                local screenDist = (cam:WorldToViewportPoint(targetPos) - Vector3.new(screenCenter.X, screenCenter.Y, 0)).Magnitude
                local predictTime = screenDist / 1000
                targetPos = targetPos + vd.vel * predictTime
            end
        end
        local currentLook = cam.CFrame.LookVector
        local targetDir = (targetPos - cam.CFrame.Position).Unit
        local lerpedDir = currentLook:Lerp(targetDir, Config.AIM_Smooth)
        cam.CFrame = CFrame.new(cam.CFrame.Position, cam.CFrame.Position + lerpedDir)
    end
end

-- ============================================================
-- GAME MECHANICS
-- ============================================================

local OriginalHitboxSizes = {}

local function TeleportToGenerator(idx)
    if #Cache.Generators == 0 then return end
    local gen = Cache.Generators[idx or 1]
    if gen and gen.part then
        local root = GetCharacterRoot()
        if root then root.CFrame = CFrame.new(gen.part.Position + Vector3.new(0, Config.TP_Offset, 0)) end
    end
end

local function TeleportToGate()
    if #Cache.Gates == 0 then return end
    local gate = Cache.Gates[1]
    if gate and gate.part then
        local root = GetCharacterRoot()
        if root then root.CFrame = CFrame.new(gate.part.Position + Vector3.new(0, Config.TP_Offset, 0)) end
    end
end

local function TeleportToHook()
    if not Cache.ClosestHook then return end
    local hook = Cache.ClosestHook
    if hook and hook.part then
        local root = GetCharacterRoot()
        if root then root.CFrame = CFrame.new(hook.part.Position + Vector3.new(0, Config.TP_Offset, 0)) end
    end
end

local function LeaveGenerator()
    local root = GetCharacterRoot()
    if not root then return end
    local myPos = root.Position
    local farthestGen, farthestDist = nil, 0
    for _, gen in ipairs(Cache.Generators) do
        if gen.part then
            local d = (gen.part.Position - myPos).Magnitude
            if d > farthestDist then farthestDist = d; farthestGen = gen end
        end
    end
    if farthestGen then
        root.CFrame = CFrame.new(farthestGen.part.Position + Vector3.new(0, Config.TP_Offset, 0))
    end
end

local function StopAutoGen()
    Config.AUTO_Generator = false
end

local function TeleportAway()
    if not Config.AUTO_TeleAway then return end
    if GetRole() ~= "Survivor" then return end
    if tick() - State.LastTeleAway < 0.5 then return end
    local root = GetCharacterRoot()
    if not root then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and IsKiller(player) and player.Character then
            local killerRoot = player.Character:FindFirstChild("HumanoidRootPart")
            if killerRoot then
                local dist = (killerRoot.Position - root.Position).Magnitude
                if dist <= Config.AUTO_TeleAwayDist then
                    local awayDir = (root.Position - killerRoot.Position).Unit
                    root.CFrame = CFrame.new(root.Position + awayDir * 30)
                    State.LastTeleAway = tick()
                    break
                end
            end
        end
    end
end

local function UpdateHitboxes()
    if GetRole() ~= "Killer" then
        for player, originalSize in pairs(OriginalHitboxSizes) do
            if player and player.Character then
                local root = player.Character:FindFirstChild("HumanoidRootPart")
                if root then root.Size = originalSize; root.Transparency = 1; root.CanCollide = true end
            end
        end
        OriginalHitboxSizes = {}; return
    end
    if not Config.HITBOX_Enabled then
        for player, originalSize in pairs(OriginalHitboxSizes) do
            if player and player.Character then
                local root = player.Character:FindFirstChild("HumanoidRootPart")
                if root then root.Size = originalSize; root.Transparency = 1; root.CanCollide = true end
            end
        end
        OriginalHitboxSizes = {}; return
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and IsSurvivor(player) then
            local char = player.Character
            if char then
                local root = char:FindFirstChild("HumanoidRootPart")
                local hum = char:FindFirstChildOfClass("Humanoid")
                if root and hum and hum.Health > 0 then
                    if not OriginalHitboxSizes[player] then OriginalHitboxSizes[player] = root.Size end
                    local size = Config.HITBOX_Size
                    root.Size = Vector3.new(size, size, size); root.CanCollide = false; root.Transparency = 0.7
                elseif root then
                    if OriginalHitboxSizes[player] then
                        root.Size = OriginalHitboxSizes[player]; root.Transparency = 1; root.CanCollide = true
                        OriginalHitboxSizes[player] = nil
                    end
                end
            end
        end
    end
end

Players.PlayerRemoving:Connect(function(player) OriginalHitboxSizes[player] = nil end)

local function AutoAttack()
    if not Config.AUTO_Attack then return end
    if GetRole() ~= "Killer" then return end
    local root = GetCharacterRoot()
    if not root then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local dist = (targetRoot.Position - root.Position).Magnitude
                if dist <= Config.AUTO_AttackRange then
                    pcall(function()
                        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                        if remotes then
                            local attacks = remotes:FindFirstChild("Attacks")
                            if attacks then
                                local basicAttack = attacks:FindFirstChild("BasicAttack")
                                if basicAttack then basicAttack:FireServer(false) end
                            end
                        end
                    end)
                    break
                end
            end
        end
    end
end

local LastParryTime = 0
local function AutoParry()
    if not Config.AUTO_Parry then return end
    if GetRole() ~= "Survivor" then return end
    if tick() - LastParryTime < 0.5 then return end
    local root = GetCharacterRoot()
    if not root then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and IsKiller(player) and player.Character then
            local killerRoot = player.Character:FindFirstChild("HumanoidRootPart")
            if killerRoot then
                local dist = (killerRoot.Position - root.Position).Magnitude
                if dist <= 15 then
                    pcall(function()
                        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                        if remotes then
                            local items = remotes:FindFirstChild("Items")
                            if items then
                                local dagger = items:FindFirstChild("Parrying Dagger")
                                if dagger then
                                    local parry = dagger:FindFirstChild("parry")
                                    if parry then parry:FireServer(); LastParryTime = tick() end
                                end
                            end
                        end
                    end)
                    break
                end
            end
        end
    end
end

local LastWiggleTime = 0
local function AutoWiggle()
    if not Config.SURV_AutoWiggle then return end
    if GetRole() ~= "Survivor" then return end
    if tick() - LastWiggleTime < 0.3 then return end
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            local carry = remotes:FindFirstChild("Carry")
            if carry then
                local selfUnhook = carry:FindFirstChild("SelfUnHookEvent")
                if selfUnhook then selfUnhook:FireServer(); LastWiggleTime = tick() end
            end
        end
    end)
end

local QTEHandler = { Monitoring = false, FrameConn = nil, UIConn = nil, Elements = nil }

local function QTE_SimulateInput()
    local inputMgr = game:GetService("VirtualInputManager")
    inputMgr:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
    task.defer(function() inputMgr:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end)
end

local function QTE_GetUIElements()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return nil end
    local prompt = pg:FindFirstChild("SkillCheckPromptGui")
    if not prompt then return nil end
    local frame = prompt:FindFirstChild("Check")
    if not frame then return nil end
    return { frame = frame, needle = frame:FindFirstChild("Line"), target = frame:FindFirstChild("Goal") }
end

local function QTE_IsNeedleInZone(needleAngle, targetAngle)
    local needle = needleAngle % 360
    local target = targetAngle % 360
    local sweetSpotStart = (target + 104) % 360
    local sweetSpotEnd = (target + 114) % 360
    if sweetSpotStart > sweetSpotEnd then return needle >= sweetSpotStart or needle <= sweetSpotEnd end
    return needle >= sweetSpotStart and needle <= sweetSpotEnd
end

local function QTE_StopMonitoring()
    if QTEHandler.FrameConn then QTEHandler.FrameConn:Disconnect(); QTEHandler.FrameConn = nil end
    QTEHandler.Monitoring = false
end

local function QTE_FrameUpdate()
    if not Config.AUTO_SkillCheck or GetRole() ~= "Survivor" then QTE_StopMonitoring(); return end
    local ui = QTEHandler.Elements
    if not ui or not ui.needle or not ui.target then QTE_StopMonitoring(); return end
    if QTE_IsNeedleInZone(ui.needle.Rotation, ui.target.Rotation) then
        QTE_SimulateInput(); QTE_StopMonitoring()
    end
end

local function QTE_StartMonitoring()
    if QTEHandler.Monitoring then return end
    QTEHandler.Monitoring = true
    QTEHandler.FrameConn = RunService.Heartbeat:Connect(QTE_FrameUpdate)
end

local function SetupSkillCheckMonitor()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return end
    QTEHandler.UIConn = pg.ChildAdded:Connect(function(child)
        if child.Name == "SkillCheckPromptGui" then
            task.wait(0.1)
            QTEHandler.Elements = QTE_GetUIElements()
            if QTEHandler.Elements and Config.AUTO_SkillCheck then QTE_StartMonitoring() end
        end
    end)
end

local OriginalFOV = nil
local function UpdateCameraFOV()
    local cam = workspace.CurrentCamera
    if not cam then return end
    if not OriginalFOV then OriginalFOV = cam.FieldOfView end
    if Config.CAM_FOVEnabled then cam.FieldOfView = Config.CAM_FOV
    else cam.FieldOfView = OriginalFOV end
end

local function UpdateShiftLock()
    if not Config.CAM_ShiftLock then return end
    local starterGui = game:GetService("StarterGui")
    pcall(function() starterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true) end)
end

local FlyBodyVelocity, FlyBodyGyro = nil, nil
local function UpdateFly()
    if State.Unloaded then return end
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if Config.FLY_Enabled then
        if not root or not hum then return end
        hum.PlatformStand = true
        if not FlyBodyVelocity then
            FlyBodyVelocity = Instance.new("BodyVelocity")
            FlyBodyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
            FlyBodyVelocity.Velocity = Vector3.zero
            FlyBodyVelocity.Parent = root
        end
        if not FlyBodyGyro then
            FlyBodyGyro = Instance.new("BodyGyro")
            FlyBodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
            FlyBodyGyro.D = 100
            FlyBodyGyro.Parent = root
        end
        local cam = workspace.CurrentCamera
        if not cam then return end
        local moveDir = Vector3.zero
        local cf = cam.CFrame
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end
        if moveDir.Magnitude > 0 then moveDir = moveDir.Unit * Config.FLY_Speed end
        if Config.FLY_Method == "Velocity" then
            FlyBodyVelocity.Velocity = moveDir
        else
            FlyBodyVelocity.Velocity = Vector3.zero
            if moveDir.Magnitude > 0 then root.CFrame = root.CFrame + moveDir * 0.05 end
        end
        FlyBodyGyro.CFrame = cam.CFrame
    else
        if FlyBodyVelocity then FlyBodyVelocity:Destroy(); FlyBodyVelocity = nil end
        if FlyBodyGyro then FlyBodyGyro:Destroy(); FlyBodyGyro = nil end
        if hum then hum.PlatformStand = false end
    end
end

local InfiniteJumpConnection = nil
local function SetupInfiniteJump()
    if InfiniteJumpConnection then InfiniteJumpConnection:Disconnect(); InfiniteJumpConnection = nil end
    InfiniteJumpConnection = UserInputService.JumpRequest:Connect(function()
        if not Config.JUMP_Infinite then return end
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)
end

local OriginalJumpPower = nil
local function UpdateJumpPower()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if not OriginalJumpPower then OriginalJumpPower = hum.JumpPower end
    if Config.JUMP_Power ~= 50 then hum.JumpPower = Config.JUMP_Power; hum.UseJumpPower = true end
end

local function UpdateSpeed()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if Config.SPEED_Enabled then
        if Config.SPEED_Method == "Attribute" then
            hum.WalkSpeed = Config.SPEED_Value
        else
            local root = char:FindFirstChild("HumanoidRootPart")
            if root and hum.MoveDirection.Magnitude > 0 then
                root.CFrame = root.CFrame + hum.MoveDirection * (Config.SPEED_Value - 16) * 0.05
            end
        end
    else hum.WalkSpeed = State.OriginalSpeed end
end

local NoclipWasOn = false
local function UpdateNoclip()
    local char = LocalPlayer.Character
    if not char then return end
    if Config.NOCLIP_Enabled then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
        NoclipWasOn = true
    elseif NoclipWasOn then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then part.CanCollide = true end
        end
        NoclipWasOn = false
    end
end

local FogCache = {}
local function RemoveFog()
    pcall(function()
        local map = Workspace:FindFirstChild("Map")
        if map then
            for _, obj in ipairs(map:GetDescendants()) do
                if obj.Name:lower():find("fog") or obj:IsA("Atmosphere") or obj:IsA("BloomEffect") or obj:IsA("BlurEffect") or obj:IsA("ColorCorrectionEffect") then
                    if not FogCache[obj] then FogCache[obj] = {enabled = obj:IsA("PostEffect") and obj.Enabled or true, parent = obj.Parent} end
                    if obj:IsA("PostEffect") then obj.Enabled = false else obj.Parent = nil end
                end
            end
        end
    end)
    pcall(function()
        local lighting = game:GetService("Lighting")
        for _, obj in ipairs(lighting:GetChildren()) do
            if obj:IsA("Atmosphere") or obj.Name:lower():find("fog") then
                if not FogCache[obj] then FogCache[obj] = {enabled = true, parent = obj.Parent} end
                if obj:IsA("Atmosphere") then obj.Density = 0 else obj.Parent = nil end
            end
        end
        lighting.FogEnd = 100000; lighting.FogStart = 0
    end)
end

local function RestoreFog()
    pcall(function()
        for obj, data in pairs(FogCache) do
            if obj and data.parent then
                if obj:IsA("PostEffect") then obj.Enabled = data.enabled else obj.Parent = data.parent end
            end
        end
        FogCache = {}
        local lighting = game:GetService("Lighting")
        lighting.FogEnd = 1000
    end)
end

local function UpdateNoFall()
    if not Config.SURV_NoFall then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    end
end

local function SetupAntiBlind()
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if not remotes then return end
        local items = remotes:FindFirstChild("Items")
        if not items then return end
        local flashlight = items:FindFirstChild("Flashlight")
        if not flashlight then return end
        local gotBlinded = flashlight:FindFirstChild("GotBlinded")
        if gotBlinded and gotBlinded:IsA("RemoteEvent") then
            local oldFire = gotBlinded.FireServer
            gotBlinded.FireServer = function(self, ...)
                if Config.KILLER_AntiBlind and GetRole() == "Killer" then return nil end
                return oldFire(self, ...)
            end
        end
    end)
end

local function UpdateNoSlowdown()
    if not Config.KILLER_NoSlowdown then return end
    if GetRole() ~= "Killer" then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if hum.WalkSpeed < 16 then hum.WalkSpeed = State.OriginalSpeed or 16 end
end

local LastDoubleTapTime = 0
local function DoubleTap()
    if not Config.KILLER_DoubleTap then return end
    if GetRole() ~= "Killer" then return end
    if tick() - LastDoubleTapTime < 0.5 then return end
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if not remotes then return end
        local attacks = remotes:FindFirstChild("Attacks")
        if not attacks then return end
        local basicAttack = attacks:FindFirstChild("BasicAttack")
        if basicAttack then
            basicAttack:FireServer(false); task.wait(0.05); basicAttack:FireServer(false)
            LastDoubleTapTime = tick()
        end
    end)
end

local function InfiniteLunge()
    if not Config.KILLER_InfiniteLunge then return end
    if GetRole() ~= "Killer" then return end
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then
        local lookVector = root.CFrame.LookVector
        root.Velocity = lookVector * 100 + Vector3.new(0, 10, 0)
    end
end

local function SetupNoPalletStun()
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if not remotes then return end
        local pallet = remotes:FindFirstChild("Pallet")
        if pallet then
            local jason = pallet:FindFirstChild("Jason")
            if jason then
                local stun = jason:FindFirstChild("Stun")
                local stunDrop = jason:FindFirstChild("StunDrop")
                if stun and stun:IsA("RemoteEvent") then
                    local mt = getrawmetatable(game)
                    if mt and setreadonly then
                        setreadonly(mt, false)
                        local oldIndex = mt.__namecall
                        mt.__namecall = newcclosure(function(self, ...)
                            if Config.KILLER_NoPalletStun and GetRole() == "Killer" then
                                if self == stun or self == stunDrop then return nil end
                            end
                            return oldIndex(self, ...)
                        end)
                        setreadonly(mt, true)
                    end
                end
            end
        end
    end)
end

local OriginalCameraType = nil
local ThirdPersonWasActive = false
local function UpdateThirdPerson()
    local cam = workspace.CurrentCamera
    if not cam then return end
    local isKiller = GetRole() == "Killer"
    local shouldBeActive = Config.CAM_ThirdPerson and isKiller
    if shouldBeActive then
        if not ThirdPersonWasActive then OriginalCameraType = cam.CameraType end
        cam.CameraType = Enum.CameraType.Custom
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.CameraOffset = Vector3.new(2, 1, 8) end
        end
        ThirdPersonWasActive = true
    elseif ThirdPersonWasActive then
        if OriginalCameraType then cam.CameraType = OriginalCameraType end
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.CameraOffset = Vector3.new(0, 0, 0) end
        end
        ThirdPersonWasActive = false
    end
end

local function FlingNearest()
    if not Config.FLING_Enabled then return end
    local root = GetCharacterRoot()
    if not root then return end
    local closest, closestDist = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local dist = (targetRoot.Position - root.Position).Magnitude
                if dist < closestDist then closestDist = dist; closest = player end
            end
        end
    end
    if closest and closest.Character then
        local targetRoot = closest.Character:FindFirstChild("HumanoidRootPart")
        if targetRoot then
            local originalPos = root.CFrame
            for i = 1, 10 do
                root.CFrame = targetRoot.CFrame
                root.Velocity = Vector3.new(Config.FLING_Strength, Config.FLING_Strength/2, Config.FLING_Strength)
                root.RotVelocity = Vector3.new(9999, 9999, 9999)
                task.wait()
            end
            root.CFrame = originalPos; root.Velocity = Vector3.zero; root.RotVelocity = Vector3.zero
        end
    end
end

local function FlingAll()
    if not Config.FLING_Enabled then return end
    local root = GetCharacterRoot()
    if not root then return end
    local originalPos = root.CFrame
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                for i = 1, 5 do
                    root.CFrame = targetRoot.CFrame
                    root.Velocity = Vector3.new(Config.FLING_Strength, Config.FLING_Strength/2, Config.FLING_Strength)
                    root.RotVelocity = Vector3.new(9999, 9999, 9999)
                    task.wait()
                end
            end
        end
    end
    root.CFrame = originalPos; root.Velocity = Vector3.zero; root.RotVelocity = Vector3.zero
end

local function UpdateFog()
    if Config.NO_Fog ~= State.LastFogState then
        State.LastFogState = Config.NO_Fog
        if Config.NO_Fog then RemoveFog() else RestoreFog() end
    end
end

local function BeatGameSurvivor()
    if not Config.BEAT_Survivor then State.BeatSurvivorDone = false; State.LastFinishPos = nil; return end
    if GetRole() ~= "Survivor" then return end
    local root = GetCharacterRoot()
    if not root then return end
    local map = Workspace:FindFirstChild("Map")
    if not map then return end
    local exitPos = nil
    pcall(function()
        if map:FindFirstChild("RooftopHitbox") or map:FindFirstChild("Rooftop") then
            exitPos = Vector3.new(3098.16, 454.04, -4918.74); return
        end
        if map:FindFirstChild("HooksMeat") then exitPos = Vector3.new(1546.12, 152.21, -796.72); return end
        if map:FindFirstChild("churchbell") then exitPos = Vector3.new(760.98, -20.14, -78.48); return end
        local finish = map:FindFirstChild("Finishline") or map:FindFirstChild("FinishLine") or map:FindFirstChild("Fininshline")
        if finish then
            if finish:IsA("BasePart") then exitPos = finish.Position
            elseif finish:IsA("Model") then
                local part = finish:FindFirstChildWhichIsA("BasePart")
                if part then exitPos = part.Position end
            end
            return
        end
        for _, obj in ipairs(map:GetDescendants()) do
            if obj.Name:lower():find("finish") then
                if obj:IsA("BasePart") then exitPos = obj.Position; break
                elseif obj:IsA("Model") then
                    local part = obj:FindFirstChildWhichIsA("BasePart")
                    if part then exitPos = part.Position; break end
                end
            end
        end
    end)
    if not exitPos then return end
    if State.LastFinishPos then
        local dist = (exitPos - State.LastFinishPos).Magnitude
        if dist > 50 then State.BeatSurvivorDone = false end
    end
    if State.BeatSurvivorDone then return end
    root.CFrame = CFrame.new(exitPos + Vector3.new(0, 3, 0))
    State.BeatSurvivorDone = true; State.LastFinishPos = exitPos
end

local function GetHealthPercent(hum)
    if not hum or hum.MaxHealth <= 0 then return 0 end
    return hum.Health / hum.MaxHealth
end
local function IsPlayerDowned(hum) local pct = GetHealthPercent(hum); return pct <= 0.25 and pct > 0 end
local function IsPlayerAlive(hum) return GetHealthPercent(hum) > 0.25 end

local function BeatGameKiller()
    if not Config.BEAT_Killer then State.KillerTarget = nil; return end
    if GetRole() ~= "Killer" then State.KillerTarget = nil; return end
    local root = GetCharacterRoot()
    if not root then return end
    local target = State.KillerTarget
    local needNewTarget = true
    if target and target.Character then
        local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
        local targetHum = target.Character:FindFirstChildOfClass("Humanoid")
        if targetRoot and targetHum and IsPlayerAlive(targetHum) then needNewTarget = false
        else State.KillerTarget = nil end
    end
    if needNewTarget then
        local closestDist = math.huge; local closest = nil
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and IsSurvivor(player) and player.Character then
                local pRoot = player.Character:FindFirstChild("HumanoidRootPart")
                local pHum = player.Character:FindFirstChildOfClass("Humanoid")
                if pRoot and pHum and IsPlayerAlive(pHum) then
                    local dist = (pRoot.Position - root.Position).Magnitude
                    if dist < closestDist then closestDist = dist; closest = player end
                end
            end
        end
        if closest then State.KillerTarget = closest; target = closest
        else State.KillerTarget = nil; return end
    end
    if not target or not target.Character then return end
    local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
    local targetHum = target.Character:FindFirstChildOfClass("Humanoid")
    if not targetRoot or not targetHum then State.KillerTarget = nil; return end
    if not IsPlayerAlive(targetHum) then State.KillerTarget = nil; return end
    for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = false end
    end
    local targetPos = targetRoot.Position
    local direction = (root.Position - targetPos).Unit
    if direction.Magnitude ~= direction.Magnitude then direction = Vector3.new(1, 0, 0) end
    local offsetPos = targetPos + direction * 3 + Vector3.new(0, 1, 0)
    root.CFrame = CFrame.new(offsetPos, targetPos)
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            local attacks = remotes:FindFirstChild("Attacks")
            if attacks then
                local basicAttack = attacks:FindFirstChild("BasicAttack")
                if basicAttack then basicAttack:FireServer(false) end
            end
        end
    end)
end

local LastAutoHookTime = 0
local AutoHookState = { phase = 0, target = nil, startTime = 0, spamCount = 0 }

local function AutoHook_SpamSpace(duration)
    task.spawn(function()
        local vim = game:GetService("VirtualInputManager")
        local endTime = tick() + duration
        while tick() < endTime do
            pcall(function()
                vim:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                task.wait(0.05)
                vim:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
            end)
            task.wait(0.08)
        end
    end)
end

local function AutoHook_LookAt(targetPos)
    local cam = workspace.CurrentCamera
    if not cam then return end
    local root = GetCharacterRoot()
    if not root then return end
    cam.CFrame = CFrame.new(cam.CFrame.Position, targetPos)
end

local function AutoHook_IsHookOccupied(hook)
    if not hook or not hook.part then return true end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and IsSurvivor(player) and player.Character then
            local pRoot = player.Character:FindFirstChild("HumanoidRootPart")
            if pRoot then
                local dist = (pRoot.Position - hook.part.Position).Magnitude
                if dist < 8 then return true end
            end
        end
    end
    return false
end

local function AutoHook_FindBestHook()
    local root = GetCharacterRoot()
    if not root then return nil end
    local bestHook, bestDist = nil, math.huge
    for _, hook in ipairs(Cache.Hooks) do
        if hook.part and hook.part.Parent then
            if not AutoHook_IsHookOccupied(hook) then
                local dist = (hook.part.Position - root.Position).Magnitude
                if dist < bestDist then bestDist = dist; bestHook = hook end
            end
        end
    end
    return bestHook
end

local function AutoHook()
    if not Config.KILLER_AutoHook then AutoHookState.phase = 0; AutoHookState.target = nil; return end
    if GetRole() ~= "Killer" then return end
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    if AutoHookState.phase == 1 then
        if tick() - AutoHookState.startTime > 1.5 then AutoHookState.phase = 2 end
        return
    end
    if tick() - LastAutoHookTime < 0.5 then return end
    local closestDowned, closestDist = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and IsSurvivor(player) and player.Character then
            local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
            local targetHum = player.Character:FindFirstChildOfClass("Humanoid")
            if targetRoot and targetHum and IsPlayerDowned(targetHum) then
                local dist = (targetRoot.Position - root.Position).Magnitude
                if dist < closestDist then closestDist = dist; closestDowned = {player = player, root = targetRoot} end
            end
        end
    end
    if closestDowned then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
        local targetPos = closestDowned.root.Position
        root.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0), targetPos + Vector3.new(0, -5, 0))
        AutoHook_LookAt(targetPos)
        AutoHook_SpamSpace(1.5)
        AutoHookState.phase = 1; AutoHookState.target = closestDowned.player; AutoHookState.startTime = tick()
        task.delay(0.5, function()
            if LocalPlayer.Character then
                for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then part.CanCollide = true end
                end
            end
        end)
    end
end

-- ============================================================
-- FOV CIRCLE (Drawing)
-- ============================================================

local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1
FOVCircle.Color = Color3.fromRGB(220, 70, 70)
FOVCircle.Filled = false
FOVCircle.NumSides = 60
FOVCircle.Transparency = 0.8
FOVCircle.Visible = false

-- ============================================================
-- AUTO GEN HINT
-- ============================================================

local AutoGenHint = Drawing.new("Text")
AutoGenHint.Size = 16
AutoGenHint.Font = Drawing.Fonts.UI
AutoGenHint.Center = true
AutoGenHint.Outline = true
AutoGenHint.Color = Color3.fromRGB(220, 70, 70)
AutoGenHint.Visible = false

-- ============================================================
-- WINDUI MENU
-- ============================================================

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Violent District",
    Icon = "skull",
    Author = "Mobile Edition",
    Folder = "ViolentDistrict",
    Size = UDim2.fromOffset(580, 460),
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 200,
    HasCustomBar = false,
})

-- =============== TAB: ESP ===============
local ESPTab = Window:Tab({ Title = "ESP", Icon = "eye" })

local ESPSection = ESPTab:Section({ Title = "General" })
ESPSection:Toggle({ Title = "Enable ESP", Default = Config.ESP_Enabled,
    Callback = function(v) Config.ESP_Enabled = v end })
ESPSection:Slider({ Title = "Max Distance", Min = 100, Max = 1000, Default = Config.ESP_MaxDist, Decimals = 0,
    Callback = function(v) Config.ESP_MaxDist = v end })

local ESPPlayerSection = ESPTab:Section({ Title = "Players" })
ESPPlayerSection:Toggle({ Title = "Killer ESP", Default = Config.ESP_Killer,
    Callback = function(v) Config.ESP_Killer = v end })
ESPPlayerSection:Toggle({ Title = "Survivor ESP", Default = Config.ESP_Survivor,
    Callback = function(v) Config.ESP_Survivor = v end })
ESPPlayerSection:Toggle({ Title = "Player Chams Mode", Default = Config.ESP_PlayerChams,
    Callback = function(v) Config.ESP_PlayerChams = v end })

local ESPObjectSection = ESPTab:Section({ Title = "Objects" })
ESPObjectSection:Toggle({ Title = "Generator", Default = Config.ESP_Generator,
    Callback = function(v) Config.ESP_Generator = v end })
ESPObjectSection:Toggle({ Title = "Gate", Default = Config.ESP_Gate,
    Callback = function(v) Config.ESP_Gate = v end })
ESPObjectSection:Toggle({ Title = "Hook", Default = Config.ESP_Hook,
    Callback = function(v) Config.ESP_Hook = v end })
ESPObjectSection:Toggle({ Title = "Pallet", Default = Config.ESP_Pallet,
    Callback = function(v) Config.ESP_Pallet = v end })
ESPObjectSection:Toggle({ Title = "Window", Default = Config.ESP_Window,
    Callback = function(v) Config.ESP_Window = v end })
ESPObjectSection:Toggle({ Title = "Closest Hook", Default = Config.ESP_ClosestHook,
    Callback = function(v) Config.ESP_ClosestHook = v end })
ESPObjectSection:Toggle({ Title = "Object Chams Mode", Default = Config.ESP_ObjectChams,
    Callback = function(v) Config.ESP_ObjectChams = v end })

local ESPDetailSection = ESPTab:Section({ Title = "Details" })
ESPDetailSection:Toggle({ Title = "Names", Default = Config.ESP_Names,
    Callback = function(v) Config.ESP_Names = v end })
ESPDetailSection:Toggle({ Title = "Distance", Default = Config.ESP_Distance,
    Callback = function(v) Config.ESP_Distance = v end })
ESPDetailSection:Toggle({ Title = "Health Bar", Default = Config.ESP_Health,
    Callback = function(v) Config.ESP_Health = v end })
ESPDetailSection:Toggle({ Title = "Skeleton", Default = Config.ESP_Skeleton,
    Callback = function(v) Config.ESP_Skeleton = v end })
ESPDetailSection:Toggle({ Title = "Offscreen Arrow", Default = Config.ESP_Offscreen,
    Callback = function(v) Config.ESP_Offscreen = v end })
ESPDetailSection:Toggle({ Title = "Velocity", Default = Config.ESP_Velocity,
    Callback = function(v) Config.ESP_Velocity = v end })

local RadarSection = ESPTab:Section({ Title = "Radar" })
RadarSection:Toggle({ Title = "Enable Radar", Default = Config.RADAR_Enabled,
    Callback = function(v) Config.RADAR_Enabled = v end })
RadarSection:Slider({ Title = "Radar Size", Min = 80, Max = 200, Default = Config.RADAR_Size, Decimals = 0,
    Callback = function(v) Config.RADAR_Size = v end })
RadarSection:Toggle({ Title = "Circle Shape", Default = Config.RADAR_Circle,
    Callback = function(v) Config.RADAR_Circle = v end })
RadarSection:Toggle({ Title = "Show Killer", Default = Config.RADAR_Killer,
    Callback = function(v) Config.RADAR_Killer = v end })
RadarSection:Toggle({ Title = "Show Survivor", Default = Config.RADAR_Survivor,
    Callback = function(v) Config.RADAR_Survivor = v end })
RadarSection:Toggle({ Title = "Show Generator", Default = Config.RADAR_Generator,
    Callback = function(v) Config.RADAR_Generator = v end })
RadarSection:Toggle({ Title = "Show Pallet", Default = Config.RADAR_Pallet,
    Callback = function(v) Config.RADAR_Pallet = v end })

-- =============== TAB: AIM ===============
local AIMTab = Window:Tab({ Title = "Aim", Icon = "crosshair" })

local AimbotSection = AIMTab:Section({ Title = "Camera Aimbot" })
AimbotSection:Toggle({ Title = "Enable Aimbot", Default = Config.AIM_Enabled,
    Callback = function(v) Config.AIM_Enabled = v end })
AimbotSection:Toggle({ Title = "Aim On Touch (Hold)", Default = false,
    Callback = function(v) State.AimHolding = v end })
AimbotSection:Toggle({ Title = "Show FOV Circle", Default = Config.AIM_ShowFOV,
    Callback = function(v) Config.AIM_ShowFOV = v end })
AimbotSection:Slider({ Title = "FOV Size", Min = 50, Max = 400, Default = Config.AIM_FOV, Decimals = 0,
    Callback = function(v) Config.AIM_FOV = v end })
AimbotSection:Slider({ Title = "Smoothness", Min = 0.1, Max = 1.0, Default = Config.AIM_Smooth, Decimals = 2,
    Callback = function(v) Config.AIM_Smooth = v end })
AimbotSection:Dropdown({ Title = "Target Part", Options = {"Head", "Torso", "Root"}, Default = "Head",
    Callback = function(v) Config.AIM_TargetPart = v end })
AimbotSection:Toggle({ Title = "Visibility Check", Default = Config.AIM_VisCheck,
    Callback = function(v) Config.AIM_VisCheck = v end })
AimbotSection:Toggle({ Title = "Prediction", Default = Config.AIM_Predict,
    Callback = function(v) Config.AIM_Predict = v end })

local SpearSection = AIMTab:Section({ Title = "Spear Aimbot (Veil)" })
SpearSection:Toggle({ Title = "Spear Aimbot", Default = Config.SPEAR_Aimbot,
    Callback = function(v) Config.SPEAR_Aimbot = v end })
SpearSection:Slider({ Title = "Spear Gravity", Min = 10, Max = 200, Default = Config.SPEAR_Gravity, Decimals = 0,
    Callback = function(v) Config.SPEAR_Gravity = v end })
SpearSection:Slider({ Title = "Spear Speed", Min = 50, Max = 300, Default = Config.SPEAR_Speed, Decimals = 0,
    Callback = function(v) Config.SPEAR_Speed = v end })

-- =============== TAB: SURVIVOR ===============
local SURVTab = Window:Tab({ Title = "Survivor", Icon = "user" })

local GenSection = SURVTab:Section({ Title = "Generators" })
GenSection:Toggle({ Title = "Auto Generator", Default = Config.AUTO_Generator,
    Callback = function(v) Config.AUTO_Generator = v end })
GenSection:Dropdown({ Title = "Gen Speed", Options = {"Fast", "Slow"}, Default = "Fast",
    Callback = function(v) Config.AUTO_GenMode = v end })
GenSection:Slider({ Title = "Leave Gen Distance", Min = 10, Max = 30, Default = Config.AUTO_LeaveDist, Decimals = 0,
    Callback = function(v) Config.AUTO_LeaveDist = v end })
GenSection:Button({ Title = "Leave Generator", Callback = function() LeaveGenerator() end })
GenSection:Button({ Title = "Stop Auto Gen", Callback = function() StopAutoGen() end })

local SurvivalSection = SURVTab:Section({ Title = "Survival" })
SurvivalSection:Toggle({ Title = "No Fall Damage", Default = Config.SURV_NoFall,
    Callback = function(v) Config.SURV_NoFall = v end })
SurvivalSection:Toggle({ Title = "Auto Flee Killer", Default = Config.AUTO_TeleAway,
    Callback = function(v) Config.AUTO_TeleAway = v end })
SurvivalSection:Slider({ Title = "Flee Distance", Min = 20, Max = 80, Default = Config.AUTO_TeleAwayDist, Decimals = 0,
    Callback = function(v) Config.AUTO_TeleAwayDist = v end })
SurvivalSection:Toggle({ Title = "Auto Parry", Default = Config.AUTO_Parry,
    Callback = function(v) Config.AUTO_Parry = v end })
SurvivalSection:Toggle({ Title = "Auto Wiggle", Default = Config.SURV_AutoWiggle,
    Callback = function(v) Config.SURV_AutoWiggle = v end })
SurvivalSection:Toggle({ Title = "Perfect Skill Check", Default = Config.AUTO_SkillCheck,
    Callback = function(v) Config.AUTO_SkillCheck = v end })

local BeatSurvSection = SURVTab:Section({ Title = "Beat Game" })
BeatSurvSection:Toggle({ Title = "Beat Survivor (Auto-TP to Exit)", Default = Config.BEAT_Survivor,
    Callback = function(v) Config.BEAT_Survivor = v end })

-- =============== TAB: KILLER ===============
local KILLTab = Window:Tab({ Title = "Killer", Icon = "zap" })

local CombatSection = KILLTab:Section({ Title = "Combat" })
CombatSection:Toggle({ Title = "Auto Attack", Default = Config.AUTO_Attack,
    Callback = function(v) Config.AUTO_Attack = v end })
CombatSection:Slider({ Title = "Attack Range", Min = 5, Max = 20, Default = Config.AUTO_AttackRange, Decimals = 0,
    Callback = function(v) Config.AUTO_AttackRange = v end })
CombatSection:Toggle({ Title = "Double Tap (Instant Kill)", Default = Config.KILLER_DoubleTap,
    Callback = function(v) Config.KILLER_DoubleTap = v end })
CombatSection:Toggle({ Title = "Infinite Lunge", Default = Config.KILLER_InfiniteLunge,
    Callback = function(v) Config.KILLER_InfiniteLunge = v end })
CombatSection:Toggle({ Title = "Auto Hook", Default = Config.KILLER_AutoHook,
    Callback = function(v) Config.KILLER_AutoHook = v end })

local HitboxSection = KILLTab:Section({ Title = "Hitbox" })
HitboxSection:Toggle({ Title = "Expand Hitbox", Default = Config.HITBOX_Enabled,
    Callback = function(v) Config.HITBOX_Enabled = v end })
HitboxSection:Slider({ Title = "Hitbox Size", Min = 5, Max = 30, Default = Config.HITBOX_Size, Decimals = 0,
    Callback = function(v) Config.HITBOX_Size = v end })

local ProtectionSection = KILLTab:Section({ Title = "Protection" })
ProtectionSection:Toggle({ Title = "No Pallet Stun", Default = Config.KILLER_NoPalletStun,
    Callback = function(v) Config.KILLER_NoPalletStun = v end })
ProtectionSection:Toggle({ Title = "Anti Blind", Default = Config.KILLER_AntiBlind,
    Callback = function(v) Config.KILLER_AntiBlind = v end })
ProtectionSection:Toggle({ Title = "No Slowdown", Default = Config.KILLER_NoSlowdown,
    Callback = function(v) Config.KILLER_NoSlowdown = v end })

local DestructionSection = KILLTab:Section({ Title = "Destruction" })
DestructionSection:Toggle({ Title = "Full Gen Break", Default = Config.KILLER_FullGenBreak,
    Callback = function(v) Config.KILLER_FullGenBreak = v end })
DestructionSection:Toggle({ Title = "Destroy Pallets", Default = Config.KILLER_DestroyPallets,
    Callback = function(v) Config.KILLER_DestroyPallets = v end })

local KillerCamSection = KILLTab:Section({ Title = "Camera" })
KillerCamSection:Toggle({ Title = "Third Person", Default = Config.CAM_ThirdPerson,
    Callback = function(v) Config.CAM_ThirdPerson = v end })
KillerCamSection:Toggle({ Title = "Shift Lock", Default = Config.CAM_ShiftLock,
    Callback = function(v) Config.CAM_ShiftLock = v end })

local BeatKillSection = KILLTab:Section({ Title = "Beat Game" })
BeatKillSection:Toggle({ Title = "Beat Killer (Auto-Chase & Kill)", Default = Config.BEAT_Killer,
    Callback = function(v) Config.BEAT_Killer = v end })

-- =============== TAB: MOVEMENT ===============
local MOVETab = Window:Tab({ Title = "Movement", Icon = "move" })

local SpeedSection = MOVETab:Section({ Title = "Speed" })
SpeedSection:Toggle({ Title = "Speed Hack", Default = Config.SPEED_Enabled,
    Callback = function(v) Config.SPEED_Enabled = v end })
SpeedSection:Slider({ Title = "Speed Value", Min = 16, Max = 150, Default = Config.SPEED_Value, Decimals = 0,
    Callback = function(v) Config.SPEED_Value = v end })
SpeedSection:Dropdown({ Title = "Speed Method", Options = {"Attribute", "TP"}, Default = "Attribute",
    Callback = function(v) Config.SPEED_Method = v end })

local FlySection = MOVETab:Section({ Title = "Flight" })
FlySection:Toggle({ Title = "Fly", Default = Config.FLY_Enabled,
    Callback = function(v) Config.FLY_Enabled = v end })
FlySection:Slider({ Title = "Fly Speed", Min = 10, Max = 200, Default = Config.FLY_Speed, Decimals = 0,
    Callback = function(v) Config.FLY_Speed = v end })
FlySection:Dropdown({ Title = "Fly Method", Options = {"CFrame", "Velocity"}, Default = "CFrame",
    Callback = function(v) Config.FLY_Method = v end })

local JumpSection = MOVETab:Section({ Title = "Jump" })
JumpSection:Slider({ Title = "Jump Power", Min = 50, Max = 200, Default = Config.JUMP_Power, Decimals = 0,
    Callback = function(v) Config.JUMP_Power = v end })
JumpSection:Toggle({ Title = "Infinite Jump", Default = Config.JUMP_Infinite,
    Callback = function(v) Config.JUMP_Infinite = v end })

local CollisionSection = MOVETab:Section({ Title = "Collision" })
CollisionSection:Toggle({ Title = "Noclip", Default = Config.NOCLIP_Enabled,
    Callback = function(v) Config.NOCLIP_Enabled = v end })

local TeleportSection = MOVETab:Section({ Title = "Teleport" })
TeleportSection:Slider({ Title = "TP Height Offset", Min = 0, Max = 10, Default = Config.TP_Offset, Decimals = 0,
    Callback = function(v) Config.TP_Offset = v end })
TeleportSection:Button({ Title = "TP to Generator", Callback = function() TeleportToGenerator(1) end })
TeleportSection:Button({ Title = "TP to Gate", Callback = function() TeleportToGate() end })
TeleportSection:Button({ Title = "TP to Hook", Callback = function() TeleportToHook() end })

-- =============== TAB: MISC ===============
local MISCTab = Window:Tab({ Title = "Misc", Icon = "settings" })

local VisualSection = MISCTab:Section({ Title = "Visual" })
VisualSection:Toggle({ Title = "Remove Fog", Default = Config.NO_Fog,
    Callback = function(v) Config.NO_Fog = v end })
VisualSection:Toggle({ Title = "Custom FOV", Default = Config.CAM_FOVEnabled,
    Callback = function(v) Config.CAM_FOVEnabled = v end })
VisualSection:Slider({ Title = "FOV Value", Min = 30, Max = 120, Default = Config.CAM_FOV, Decimals = 0,
    Callback = function(v) Config.CAM_FOV = v end })

local FlingSection = MISCTab:Section({ Title = "Fling" })
FlingSection:Toggle({ Title = "Enable Fling", Default = Config.FLING_Enabled,
    Callback = function(v) Config.FLING_Enabled = v end })
FlingSection:Slider({ Title = "Fling Strength", Min = 1000, Max = 50000, Default = Config.FLING_Strength, Decimals = 0,
    Callback = function(v) Config.FLING_Strength = v end })
FlingSection:Button({ Title = "Fling Nearest", Callback = function() FlingNearest() end })
FlingSection:Button({ Title = "Fling All", Callback = function() FlingAll() end })

local DangerSection = MISCTab:Section({ Title = "Danger Zone" })
DangerSection:Button({ Title = "Unload Script", Callback = function() Unload() end })

-- ============================================================
-- MAIN LOOP
-- ============================================================

local function UpdateSpearAim()
    if not Config.SPEAR_Aimbot then return end
    if GetRole() ~= "Killer" then return end
    local root = GetCharacterRoot()
    if not root then return end
    local closest, closestDist = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and IsSurvivor(player) and player.Character then
            local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local dist = (targetRoot.Position - root.Position).Magnitude
                if dist < closestDist and Cache.Visibility[player] then
                    closestDist = dist; closest = player
                end
            end
        end
    end
    if closest and closest.Character then
        local targetRoot = closest.Character:FindFirstChild("HumanoidRootPart")
        if targetRoot then
            local startPos = root.Position + Vector3.new(0, 2, 0)
            local distance = (targetRoot.Position - startPos).Magnitude
            local time = distance / Config.SPEAR_Speed
            local gravityDrop = 0.5 * Config.SPEAR_Gravity * time * time
            local aimPos = targetRoot.Position + Vector3.new(0, gravityDrop, 0)
            local cam = workspace.CurrentCamera
            if cam then cam.CFrame = CFrame.new(cam.CFrame.Position, aimPos) end
        end
    end
end

local function MainLoop()
    if State.Unloaded then return end
    local cam = workspace.CurrentCamera
    if not cam then return end
    local screenSize = cam.ViewportSize
    local screenCenter = Vector2.new(screenSize.X / 2, screenSize.Y / 2)
    local now = tick()
    if now - State.LastCacheUpdate >= Tuning.CacheRefreshRate then
        State.LastCacheUpdate = now; ScanMap()
    end
    if now - State.LastVisCheck >= Tuning.ESP_VisCheckRate then
        State.LastVisCheck = now; UpdateVisibility()
    end
    ESP.step(cam, screenSize, screenCenter)
    UpdateObjectESP(cam)
    Radar.step(cam)
    if Config.AUTO_Generator and AutoGenHint then
        AutoGenHint.Text = "AUTO GEN ACTIVE  |  [Buttons in SURV tab]"
        AutoGenHint.Position = Vector2.new(screenSize.X / 2, 30)
        AutoGenHint.Visible = true
    elseif AutoGenHint then
        AutoGenHint.Visible = false
    end
    Aimbot.Update(cam, screenSize, screenCenter)
    if FOVCircle then
        if Config.AIM_Enabled and Config.AIM_ShowFOV then
            FOVCircle.Position = screenCenter
            FOVCircle.Radius = Config.AIM_FOV
            FOVCircle.Color = State.AimTarget and Color3.fromRGB(90, 220, 120) or Color3.fromRGB(220, 70, 70)
            FOVCircle.Visible = true
        else
            FOVCircle.Visible = false
        end
    end
end

local function AutoLoop()
    while not State.Unloaded do
        AutoAttack()
        TeleportAway()
        UpdateNoFall()
        AutoWiggle()
        DoubleTap()
        UpdateNoSlowdown()
        AutoHook()
        UpdateSpeed()
        UpdateNoclip()
        UpdateFly()
        UpdateJumpPower()
        UpdateFog()
        UpdateCameraFOV()
        UpdateThirdPerson()
        UpdateShiftLock()
        UpdateHitboxes()
        UpdateSpearAim()
        BeatGameSurvivor()
        BeatGameKiller()
        task.wait(0.1)
    end
end

-- ============================================================
-- UNLOAD
-- ============================================================

Unload = function()
    State.Unloaded = true
    Config.AUTO_Generator = false; Config.AUTO_Attack = false
    Config.AUTO_TeleAway = false; Config.SPEED_Enabled = false
    Config.NOCLIP_Enabled = false; Config.BEAT_Survivor = false
    Config.BEAT_Killer = false; Config.HITBOX_Enabled = false
    Config.FLY_Enabled = false; Config.FLING_Enabled = false
    Config.KILLER_DoubleTap = false; Config.KILLER_InfiniteLunge = false
    Config.KILLER_AutoHook = false; Config.AUTO_SkillCheck = false
    State.KillerTarget = nil; AutoHookState.phase = 0; AutoHookState.target = nil
    pcall(QTE_StopMonitoring)
    if QTEHandler.UIConn then pcall(function() QTEHandler.UIConn:Disconnect() end); QTEHandler.UIConn = nil end
    for player, originalSize in pairs(OriginalHitboxSizes) do
        pcall(function()
            if player and player.Character then
                local root = player.Character:FindFirstChild("HumanoidRootPart")
                if root then root.Size = originalSize; root.Transparency = 1; root.CanCollide = true end
            end
        end)
    end
    OriginalHitboxSizes = {}
    pcall(function()
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = State.OriginalSpeed end
    end)
    pcall(function()
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum and OriginalJumpPower then hum.JumpPower = OriginalJumpPower end
    end)
    pcall(function()
        local cam = workspace.CurrentCamera
        if cam and OriginalFOV then cam.FieldOfView = OriginalFOV end
    end)
    pcall(function()
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.CameraOffset = Vector3.new(0, 0, 0) end
        local cam = workspace.CurrentCamera
        if cam and OriginalCameraType then cam.CameraType = OriginalCameraType end
    end)
    pcall(function()
        if FlyBodyVelocity then FlyBodyVelocity:Destroy() end
        if FlyBodyGyro then FlyBodyGyro:Destroy() end
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end)
    pcall(function() if InfiniteJumpConnection then InfiniteJumpConnection:Disconnect() end end)
    pcall(function()
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then part.CanCollide = true end
            end
        end
    end)
    if Config.NO_Fog then RestoreFog() end
    for name, conn in pairs(Connections) do
        if conn then pcall(function() conn:Disconnect() end); Connections[name] = nil end
    end
    for _, esp in pairs(ESP.cache) do ESP.destroy(esp) end; ESP.cache = {}
    for _, esp in pairs(ESP.objectCache) do ESP.destroyObject(esp) end; ESP.objectCache = {}
    Chams.ClearAll()
    pcall(function()
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj.Name == "_ViolenceChams" or obj.Name == "_ViolenceLabel" then pcall(function() obj:Destroy() end) end
        end
        for _, player in pairs(Players:GetPlayers()) do
            if player.Character then
                local c = player.Character:FindFirstChild("_ViolenceChams")
                if c then c:Destroy() end
                local l = player.Character:FindFirstChild("_ViolenceLabel")
                if l then l:Destroy() end
            end
        end
    end)
    pcall(function()
        Radar.bg:Remove(); Radar.circleBg:Remove(); Radar.border:Remove(); Radar.circleBorder:Remove()
        Radar.cross1:Remove(); Radar.cross2:Remove(); Radar.center:Remove()
        for _, d in pairs(Radar.dots) do if d then d:Remove() end end
        for _, d in pairs(Radar.objectDots) do if d then d:Remove() end end
        for _, d in pairs(Radar.palletSquares) do if d then d:Remove() end end
    end)
    SafeRemove(FOVCircle)
    SafeRemove(AutoGenHint)
    pcall(function() Window:Destroy() end)
end

-- ============================================================
-- INIT
-- ============================================================

local function Init()
    ScanMap()
    pcall(SetupAntiBlind)
    pcall(SetupNoPalletStun)
    pcall(SetupInfiniteJump)
    pcall(SetupSkillCheckMonitor)

    -- Only keep input connection for aimbot RMB (touch equivalent handled via WindUI toggle)
    Connections.InputEnd = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            -- keep for PC executor compatibility
        end
    end)

    Connections.Render = RunService.RenderStepped:Connect(MainLoop)
    task.spawn(AutoLoop)

    -- Auto generator background task
    task.spawn(function()
        local repairRemote, skillRemote
        local lastScan = 0
        local genPoints = {}
        while not State.Unloaded do
            if Config.AUTO_Generator then
                if not repairRemote then
                    local r = ReplicatedStorage:FindFirstChild("Remotes")
                    local g = r and r:FindFirstChild("Generator")
                    repairRemote = g and g:FindFirstChild("RepairEvent")
                    skillRemote = g and g:FindFirstChild("SkillCheckResultEvent")
                end
                if tick() - lastScan > 2 then
                    genPoints = {}
                    local m = Workspace:FindFirstChild("Map")
                    if m then
                        for _, v in ipairs(m:GetDescendants()) do
                            if v:IsA("Model") and v.Name == "Generator" then
                                for _, c in ipairs(v:GetChildren()) do
                                    if c.Name:match("GeneratorPoint") then
                                        table.insert(genPoints, {gen = v, pt = c})
                                    end
                                end
                            end
                        end
                    end
                    lastScan = tick()
                end
                if repairRemote and skillRemote then
                    local mode = Config.AUTO_GenMode == "Fast"
                    for _, data in ipairs(genPoints) do
                        pcall(repairRemote.FireServer, repairRemote, data.pt, true)
                        pcall(skillRemote.FireServer, skillRemote, mode and "success" or "neutral", mode and 1 or 0, data.gen, data.pt)
                    end
                end
            end
            task.wait(0.15)
        end
    end)

    Connections.PlayerLeft = Players.PlayerRemoving:Connect(function(player)
        if ESP.cache[player] then ESP.hide(ESP.cache[player]); ESP.destroy(ESP.cache[player]); ESP.cache[player] = nil end
        if player.Character then Chams.Remove(player.Character) end
        Cache.Visibility[player] = nil
    end)

    Connections.PlayerAdded = Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function() task.wait(1); ScanMap() end)
    end)
end

Init()
