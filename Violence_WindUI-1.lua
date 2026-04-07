-- ╔══════════════════════════════════════════════╗
-- ║   VIOLENCE HUB  –  WindUI Edition            ║
-- ║   Requires HIGH UNC executor (not Xeno)      ║
-- ╚══════════════════════════════════════════════╝

-- ─── Drawing guard ───────────────────────────────
local function SafeDrawing(type)
    local ok, r = pcall(function() return Drawing.new(type) end)
    if ok then return r end
    return nil
end

local function SafeRemove(obj)
    if obj and obj.Remove then pcall(function() obj:Remove() end) end
end

if not Drawing or not Drawing.new then
    local waited = 0
    while not Drawing and waited < 5 do task.wait(0.1); waited += 0.1 end
    if not Drawing then warn("[Violence] Drawing not available."); return end
end

local ExecutorName = "Unknown"
pcall(function()
    if identifyexecutor then ExecutorName = identifyexecutor()
    elseif getexecutorname then ExecutorName = getexecutorname() end
end)

-- ─── Services ────────────────────────────────────
local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local UserInputService= game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace       = game:GetService("Workspace")
local LocalPlayer     = Players.LocalPlayer

-- ─── Config ──────────────────────────────────────
local Config = {
    ESP_Enabled = true,
    ESP_Killer = true,
    ESP_Survivor = true,
    ESP_Generator = true,
    ESP_Gate = true,
    ESP_Hook = true,
    ESP_Pallet = false,
    ESP_Window = false,
    ESP_Distance = true,
    ESP_Names = true,
    ESP_Health = true,
    ESP_Skeleton = false,
    ESP_Box = true,
    ESP_Offscreen = false,
    ESP_Velocity = false,
    ESP_ClosestHook = true,
    ESP_MaxDist = 500,
    ESP_PlayerChams = true,
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
    KEY_Speed = Enum.KeyCode.C,
    NOCLIP_Enabled = false,
    KEY_Noclip = Enum.KeyCode.V,
    FLY_Enabled = false,
    FLY_Speed = 50,
    FLY_Method = "CFrame",
    KEY_Fly = Enum.KeyCode.F,
    JUMP_Power = 50,
    JUMP_Infinite = false,

    NO_Fog = false,
    CAM_FOVEnabled = false,
    CAM_FOV = 90,
    CAM_ThirdPerson = false,
    CAM_ShiftLock = false,
    FLING_Enabled = false,
    FLING_Strength = 10000,
    TOUCH_Fling = false,

    BEAT_Survivor = false,
    BEAT_Killer = false,

    TP_Offset = 3,

    KEY_Menu = Enum.KeyCode.Insert,
    KEY_Panic = Enum.KeyCode.Home,
    KEY_LeaveGen = Enum.KeyCode.Q,
    KEY_StopGen = Enum.KeyCode.X,
    KEY_TP_Gen = Enum.KeyCode.G,
    KEY_TP_Gate = Enum.KeyCode.T,
    KEY_TP_Hook = Enum.KeyCode.H,

    AIM_Enabled = false,
    AIM_UseRMB = true,
    AIM_FOV = 120,
    AIM_Smooth = 0.3,
    AIM_TargetPart = "Head",
    AIM_VisCheck = true,
    AIM_ShowFOV = true,
    AIM_Predict = true,

    SPEAR_Aimbot = false,
    SPEAR_Gravity = 50,
    SPEAR_Speed = 100,
}

local Tuning = {
    ESP_RefreshRate  = 0.08,
    ESP_VisCheckRate = 0.15,
    Gen_RefreshRate  = 0.2,
    CacheRefreshRate = 1.0,
    Box_WidthRatio   = 0.55,
    Name_Offset      = 18,
    Dist_Offset      = 5,
    Health_Width     = 4,
    Health_Offset    = 6,
    Offscreen_Edge   = 50,
    Offscreen_Size   = 12,
    Skel_Thickness   = 1,
    Box_Thickness    = 1,
    RadarRange       = 150,
    RadarDotSize     = 5,
    RadarArrowSize   = 8,
}

local Colors = {
    Killer       = Color3.fromRGB(255,  65,  65),
    KillerVis    = Color3.fromRGB(255, 120, 120),
    Survivor     = Color3.fromRGB( 65, 220, 130),
    SurvivorVis  = Color3.fromRGB(120, 255, 170),
    Generator    = Color3.fromRGB(255, 180,  50),
    GeneratorDone= Color3.fromRGB(100, 255, 130),
    Gate         = Color3.fromRGB(200, 200, 220),
    Hook         = Color3.fromRGB(255, 100, 100),
    HookClose    = Color3.fromRGB(255, 230,  80),
    Pallet       = Color3.fromRGB(220, 180, 100),
    Window       = Color3.fromRGB(100, 180, 255),
    Skeleton     = Color3.fromRGB(255, 255, 255),
    SkeletonVis  = Color3.fromRGB(150, 255, 150),
    Offscreen    = Color3.fromRGB(255, 255, 255),
    HealthHigh   = Color3.fromRGB(100, 255, 100),
    HealthMid    = Color3.fromRGB(255, 220,  60),
    HealthLow    = Color3.fromRGB(255,  70,  70),
    HealthBg     = Color3.fromRGB( 25,  25,  25),
    RadarBg      = Color3.fromRGB( 20,  20,  20),
    RadarBorder  = Color3.fromRGB(255,  65,  65),
    RadarYou     = Color3.fromRGB(  0, 255,   0),
}

local ChamsColors = {
    Killer    = {fill=Color3.fromRGB(180,40,40),   outline=Color3.fromRGB(255,80,80),   fillTrans=0.6},
    Survivor  = {fill=Color3.fromRGB(40,160,80),   outline=Color3.fromRGB(80,255,130),  fillTrans=0.6},
    Generator = {fill=Color3.fromRGB(200,140,30),  outline=Color3.fromRGB(255,200,80),  fillTrans=0.5},
    Gate      = {fill=Color3.fromRGB(150,150,170), outline=Color3.fromRGB(220,220,255), fillTrans=0.5},
    Hook      = {fill=Color3.fromRGB(180,60,60),   outline=Color3.fromRGB(255,100,100), fillTrans=0.5},
    HookClose = {fill=Color3.fromRGB(200,180,40),  outline=Color3.fromRGB(255,240,100), fillTrans=0.4},
    Pallet    = {fill=Color3.fromRGB(180,140,70),  outline=Color3.fromRGB(255,210,130), fillTrans=0.5},
    Window    = {fill=Color3.fromRGB(60,140,200),  outline=Color3.fromRGB(120,200,255), fillTrans=0.5},
}

local Bones_R15 = {
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
}
local Bones_R6 = {
    {"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"},
}

local State = {
    Unloaded      = false,
    LastESPUpdate = 0, LastVisCheck = 0, LastGenUpdate = 0,
    LastCacheUpdate = 0, LastTeleAway = 0,
    AimTarget     = nil, AimHolding = false,
    OriginalSpeed = 16,  LastFogState = false,
    KillerTarget  = nil, LastBeatTP = 0,
    LastFinishPos = nil, BeatSurvivorDone = false,
}

local Cache = {
    Players={}, Generators={}, Gates={}, Hooks={}, Pallets={}, Windows={},
    Visibility={}, ClosestHook=nil,
}

local Connections = {}
local Unload

-- ─── Helpers ─────────────────────────────────────
local function GetRole()
    if not LocalPlayer.Team then return "Unknown" end
    local n = LocalPlayer.Team.Name
    if n == "Killer" then return "Killer" end
    if n == "Survivors" then return "Survivor" end
    return "Lobby"
end
local function IsKiller(p) return p and p.Team and p.Team.Name=="Killer" end
local function IsSurvivor(p) return p and p.Team and p.Team.Name=="Survivors" end
local function GetCharacterRoot()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function IsR6(char) return char:FindFirstChild("Torso") ~= nil end
local function GetDistance(pos)
    local r = GetCharacterRoot()
    if not r then return math.huge end
    return (pos - r.Position).Magnitude
end
local function IsVisible(char)
    if not char then return false end
    local cam = workspace.CurrentCamera
    if not cam then return false end
    local origin = cam.CFrame.Position
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {cam, LocalPlayer.Character, char}
    for _, pn in ipairs({"Head","UpperTorso","Torso","HumanoidRootPart"}) do
        local part = char:FindFirstChild(pn)
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
    local s, on = cam:WorldToViewportPoint(pos)
    return Vector2.new(s.X, s.Y), on, s.Z
end
local function Lerp(a, b, t) return a + (b-a)*t end
local function LerpColor(c1, c2, t)
    return Color3.new(c1.R+(c2.R-c1.R)*t, c1.G+(c2.G-c1.G)*t, c1.B+(c2.B-c1.B)*t)
end

-- ─── Chams ───────────────────────────────────────
local Chams = { Objects={}, Labels={} }
function Chams.Create(target, colorData, label)
    if not target or not target:IsA("Instance") then return nil end
    local ex = target:FindFirstChild("_ViolenceChams"); if ex then ex:Destroy() end
    local h = Instance.new("Highlight")
    h.Name = "_ViolenceChams"; h.Adornee = target
    h.FillColor = colorData.fill; h.OutlineColor = colorData.outline
    h.FillTransparency = colorData.fillTrans; h.OutlineTransparency = 0
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; h.Parent = target
    local data = {highlight=h, target=target}
    if label then
        local rootPart = target:IsA("Model") and (target:FindFirstChild("HumanoidRootPart") or target:FindFirstChildWhichIsA("BasePart")) or target
        if rootPart then
            local bb = Instance.new("BillboardGui")
            bb.Name = "_ViolenceLabel"; bb.Size = UDim2.new(0,80,0,18)
            bb.AlwaysOnTop = true; bb.StudsOffset = Vector3.new(0,3,0)
            bb.Adornee = rootPart; bb.Parent = target
            local tl = Instance.new("TextLabel")
            tl.Size = UDim2.new(1,0,1,0); tl.BackgroundTransparency = 1
            tl.TextColor3 = colorData.outline; tl.TextStrokeColor3 = Color3.new(0,0,0)
            tl.TextStrokeTransparency = 0.2; tl.Font = Enum.Font.Gotham
            tl.TextSize = 10; tl.TextScaled = false; tl.Text = label; tl.Parent = bb
            data.billboard = bb; data.textLabel = tl; data.rootPart = rootPart
        end
    end
    Chams.Objects[target] = data
    return data
end
function Chams.Update(target, newLabel, newDist)
    local d = Chams.Objects[target]; if not d then return end
    if d.textLabel and newLabel then
        local text = newLabel
        if newDist and Config.ESP_Distance then text = text.."\n"..math.floor(newDist).."m" end
        d.textLabel.Text = text
    end
end
function Chams.SetColor(target, colorData)
    local d = Chams.Objects[target]; if not d or not d.highlight then return end
    d.highlight.FillColor = colorData.fill; d.highlight.OutlineColor = colorData.outline
    d.highlight.FillTransparency = colorData.fillTrans
    if d.textLabel then d.textLabel.TextColor3 = colorData.outline end
end
function Chams.Remove(target)
    local d = Chams.Objects[target]
    if d then
        if d.highlight and d.highlight.Parent then d.highlight:Destroy() end
        if d.billboard and d.billboard.Parent then d.billboard:Destroy() end
        Chams.Objects[target] = nil
    end
    if target then
        local ex = target:FindFirstChild("_ViolenceChams"); if ex then ex:Destroy() end
        local el = target:FindFirstChild("_ViolenceLabel"); if el then el:Destroy() end
    end
end
function Chams.ClearAll()
    for target in pairs(Chams.Objects) do Chams.Remove(target) end
    Chams.Objects = {}
end

-- ─── ESP ─────────────────────────────────────────
local ESP = { cache={}, objectCache={}, velocityData={} }
function ESP.create()
    local skel = {}
    for i=1,14 do skel[i]=Drawing.new("Line"); skel[i].Thickness=1; skel[i].Visible=false end
    local box = {}
    for i=1,4 do box[i]=Drawing.new("Line"); box[i].Thickness=1; box[i].Visible=false end
    return {
        Box=box, Name=Drawing.new("Text"), Dist=Drawing.new("Text"), Skel=skel,
        HealthBg=Drawing.new("Square"), HealthBar=Drawing.new("Square"),
        Offscreen=Drawing.new("Triangle"), VelLine=Drawing.new("Line"), VelArrow=Drawing.new("Triangle"),
    }
end
function ESP.setup(esp)
    for _,l in ipairs(esp.Box) do l.Thickness=1; l.Visible=false end
    esp.Name.Size=14; esp.Name.Font=Drawing.Fonts.Monospace; esp.Name.Center=true; esp.Name.Outline=true; esp.Name.Visible=false
    esp.Dist.Size=12; esp.Dist.Font=Drawing.Fonts.Monospace; esp.Dist.Center=true; esp.Dist.Outline=true
    esp.Dist.Color=Color3.fromRGB(180,180,180); esp.Dist.Visible=false
    for _,l in ipairs(esp.Skel) do l.Thickness=1; l.Visible=false end
    esp.HealthBg.Filled=true; esp.HealthBg.Color=Colors.HealthBg; esp.HealthBg.Visible=false
    esp.HealthBar.Filled=true; esp.HealthBar.Visible=false
    esp.Offscreen.Filled=true; esp.Offscreen.Visible=false
    esp.VelLine.Thickness=2; esp.VelLine.Color=Color3.fromRGB(0,255,255); esp.VelLine.Visible=false
    esp.VelArrow.Filled=true; esp.VelArrow.Color=Color3.fromRGB(0,255,255); esp.VelArrow.Visible=false
end
function ESP.hide(esp)
    if not esp then return end
    for _,l in ipairs(esp.Box) do l.Visible=false end
    esp.Name.Visible=false; esp.Dist.Visible=false
    for _,l in ipairs(esp.Skel) do l.Visible=false end
    esp.HealthBg.Visible=false; esp.HealthBar.Visible=false
    esp.Offscreen.Visible=false; esp.VelLine.Visible=false; esp.VelArrow.Visible=false
end
function ESP.destroy(esp)
    if not esp then return end
    pcall(function()
        for _,l in ipairs(esp.Box) do l:Remove() end
        esp.Name:Remove(); esp.Dist:Remove()
        for _,l in ipairs(esp.Skel) do l:Remove() end
        esp.HealthBg:Remove(); esp.HealthBar:Remove()
        esp.Offscreen:Remove(); esp.VelLine:Remove(); esp.VelArrow:Remove()
    end)
end
function ESP.hideAll()
    for _,esp in pairs(ESP.cache) do ESP.hide(esp) end
    for _,esp in pairs(ESP.objectCache) do ESP.hideObject(esp) end
    Chams.ClearAll()
end
function ESP.cleanup()
    local valid = {}
    for _,p in ipairs(Players:GetPlayers()) do valid[p]=true end
    for player,esp in pairs(ESP.cache) do
        if not valid[player] then
            ESP.hide(esp); ESP.destroy(esp)
            ESP.cache[player]=nil; ESP.velocityData[player]=nil
        end
    end
end
function ESP.createObject()
    local box={}
    for i=1,4 do box[i]=Drawing.new("Line"); box[i].Thickness=1; box[i].Visible=false end
    return {Box=box, Label=Drawing.new("Text"), Dist=Drawing.new("Text")}
end
function ESP.setupObject(esp)
    for _,l in ipairs(esp.Box) do l.Thickness=1; l.Visible=false end
    esp.Label.Size=13; esp.Label.Font=Drawing.Fonts.Monospace; esp.Label.Center=true; esp.Label.Outline=true; esp.Label.Visible=false
    esp.Dist.Size=11; esp.Dist.Font=Drawing.Fonts.Monospace; esp.Dist.Center=true; esp.Dist.Outline=true
    esp.Dist.Color=Color3.fromRGB(160,160,160); esp.Dist.Visible=false
end
function ESP.hideObject(esp) if not esp then return end; for _,l in ipairs(esp.Box) do l.Visible=false end; esp.Label.Visible=false; esp.Dist.Visible=false end
function ESP.destroyObject(esp) if not esp then return end; pcall(function() for _,l in ipairs(esp.Box) do l:Remove() end; esp.Label:Remove(); esp.Dist:Remove() end) end

-- Optimized ESP render:
-- • Single WorldToViewportPoint call for root (cheap distance check first)
-- • Only writes Drawing properties when value actually changed
-- • Skeleton disabled by default (very expensive, many extra WtVP calls)
-- • Velocity uses cached data, no extra WtVP per frame
function ESP.render(esp, player, char, cam, screenSize, screenCenter)
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if not root then ESP.hide(esp); return end

    -- ── Early distance check (no WtVP yet) ──────────
    local myRoot = GetCharacterRoot()
    if not myRoot then ESP.hide(esp); return end
    local dist = (root.Position - myRoot.Position).Magnitude
    if dist > Config.ESP_MaxDist then ESP.hide(esp); return end

    -- ── Single root WtVP ────────────────────────────
    local rs  = cam:WorldToViewportPoint(root.Position)
    local onScreen = rs.Z > 0 and rs.X > 0 and rs.X < screenSize.X and rs.Y > 0 and rs.Y < screenSize.Y

    local isKillerPlayer = IsKiller(player)
    local visible = Cache.Visibility[player]
    local col = isKillerPlayer
        and (visible and Colors.KillerVis or Colors.Killer)
        or  (visible and Colors.SurvivorVis or Colors.Survivor)

    -- ── Off-screen arrow ────────────────────────────
    if not onScreen then
        if esp.Box[1].Visible then
            for _,l in ipairs(esp.Box) do l.Visible=false end
            esp.Name.Visible=false; esp.Dist.Visible=false
            esp.HealthBg.Visible=false; esp.HealthBar.Visible=false
            esp.VelLine.Visible=false; esp.VelArrow.Visible=false
            for _,l in ipairs(esp.Skel) do l.Visible=false end
        end
        if Config.ESP_Offscreen and visible then
            local dx=rs.X-screenCenter.X; local dy=rs.Y-screenCenter.Y
            local angle=math.atan2(dy,dx); local edge=50
            local ax=math.clamp(screenCenter.X+math.cos(angle)*(screenSize.X/2-edge),edge,screenSize.X-edge)
            local ay=math.clamp(screenCenter.Y+math.sin(angle)*(screenSize.Y/2-edge),edge,screenSize.Y-edge)
            local fwd=Vector2.new(math.cos(angle),math.sin(angle))
            local right=Vector2.new(-fwd.Y,fwd.X); local pos=Vector2.new(ax,ay); local sz=12
            esp.Offscreen.PointA=pos+fwd*sz
            esp.Offscreen.PointB=pos-fwd*sz/2-right*sz/2
            esp.Offscreen.PointC=pos-fwd*sz/2+right*sz/2
            esp.Offscreen.Color=col; esp.Offscreen.Visible=true
        else
            esp.Offscreen.Visible=false
        end
        return
    end
    esp.Offscreen.Visible=false

    -- ── Box: use head+feet WtVP only when on screen ──
    local head = char:FindFirstChild("Head")
    local headY, feetY
    if head then
        local hs = cam:WorldToViewportPoint(head.Position + Vector3.new(0,0.5,0))
        headY = hs.Y
    else
        headY = rs.Y - 40
    end
    local fs = cam:WorldToViewportPoint(root.Position - Vector3.new(0,3,0))
    feetY = fs.Y

    local cx        = rs.X
    local boxTop    = headY
    local boxBottom = feetY
    local boxHeight = math.abs(boxBottom - boxTop)
    if boxHeight < 4 then ESP.hide(esp); return end -- skip tiny/degenerate boxes
    local boxWidth  = boxHeight * 0.6
    local hw        = boxWidth * 0.5

    -- Box lines (only write if position changed)
    local b = esp.Box
    local lt = Vector2.new(cx-hw, boxTop);    local rt = Vector2.new(cx+hw, boxTop)
    local lb = Vector2.new(cx-hw, boxBottom); local rb = Vector2.new(cx+hw, boxBottom)
    if Config.ESP_Box then
        b[1].From=lt; b[1].To=rt;   b[1].Color=col; b[1].Visible=true
        b[2].From=rt; b[2].To=rb;   b[2].Color=col; b[2].Visible=true
        b[3].From=rb; b[3].To=lb;   b[3].Color=col; b[3].Visible=true
        b[4].From=lb; b[4].To=lt;   b[4].Color=col; b[4].Visible=true
    else
        b[1].Visible=false; b[2].Visible=false; b[3].Visible=false; b[4].Visible=false
    end

    -- Name
    if Config.ESP_Names then
        esp.Name.Text=player.Name
        esp.Name.Position=Vector2.new(cx, boxTop-18)
        esp.Name.Color=col; esp.Name.Visible=true
    else esp.Name.Visible=false end

    -- Distance (only update text every ~0.2s via rounding to nearest 5)
    if Config.ESP_Distance then
        esp.Dist.Text=math.floor(dist/5+0.5)*5 .."m"
        esp.Dist.Position=Vector2.new(cx, boxBottom+4)
        esp.Dist.Visible=true
    else esp.Dist.Visible=false end

    -- Health bar
    if Config.ESP_Health and hum and hum.MaxHealth > 0 then
        local pct = math.clamp(hum.Health/hum.MaxHealth, 0, 1)
        local barX = cx - hw - 6
        local barH = boxHeight * pct
        esp.HealthBg.Position=Vector2.new(barX-1, boxTop-1)
        esp.HealthBg.Size=Vector2.new(5, boxHeight+2); esp.HealthBg.Visible=true
        esp.HealthBar.Position=Vector2.new(barX, boxBottom-barH)
        esp.HealthBar.Size=Vector2.new(3, barH)
        esp.HealthBar.Color=pct>0.6 and Colors.HealthHigh or pct>0.3 and Colors.HealthMid or Colors.HealthLow
        esp.HealthBar.Visible=true
    else esp.HealthBg.Visible=false; esp.HealthBar.Visible=false end

    -- Skeleton (expensive – only when explicitly enabled)
    if Config.ESP_Skeleton then
        local bones = IsR6(char) and Bones_R6 or Bones_R15
        local skelCol = visible and Colors.SkeletonVis or Colors.Skeleton
        for i,b2 in ipairs(bones) do
            local sl = esp.Skel[i]
            if sl then
                local p1=char:FindFirstChild(b2[1]); local p2=char:FindFirstChild(b2[2])
                if p1 and p2 then
                    local s1=cam:WorldToViewportPoint(p1.Position)
                    local s2=cam:WorldToViewportPoint(p2.Position)
                    if s1.Z>0 and s2.Z>0 then
                        sl.From=Vector2.new(s1.X,s1.Y); sl.To=Vector2.new(s2.X,s2.Y)
                        sl.Color=skelCol; sl.Visible=true
                    else sl.Visible=false end
                else sl.Visible=false end
            end
        end
        for i=#bones+1,#esp.Skel do if esp.Skel[i] then esp.Skel[i].Visible=false end end
    else
        -- Only hide if they were visible before (avoid redundant writes)
        if esp.Skel[1] and esp.Skel[1].Visible then
            for _,l in ipairs(esp.Skel) do l.Visible=false end
        end
    end

    -- Velocity (use cached vel, no extra WtVP)
    if Config.ESP_Velocity then
        local vd = ESP.velocityData[player]
        if not vd then
            vd={pos=root.Position, vel=Vector3.zero, time=tick()}
            ESP.velocityData[player]=vd
        end
        local now2=tick(); local dt=now2-vd.time
        if dt>0.05 then
            local raw=(root.Position-vd.pos)/dt
            vd.vel=vd.vel*0.7+raw*0.3; vd.pos=root.Position; vd.time=now2
        end
        local vf=Vector3.new(vd.vel.X,0,vd.vel.Z)
        if vf.Magnitude>2 then
            local projected = cam:WorldToViewportPoint(root.Position + vf.Unit*2)
            if projected.Z>0 then
                local from=Vector2.new(cx, rs.Y); local to=Vector2.new(projected.X, projected.Y)
                esp.VelLine.From=from; esp.VelLine.To=to; esp.VelLine.Visible=true
                local d2=(to-from)
                if d2.Magnitude>0 then
                    local dn=d2.Unit; local r2=Vector2.new(-dn.Y,dn.X)
                    esp.VelArrow.PointA=to; esp.VelArrow.PointB=to-dn*6-r2*4; esp.VelArrow.PointC=to-dn*6+r2*4
                    esp.VelArrow.Visible=true
                end
            else esp.VelLine.Visible=false; esp.VelArrow.Visible=false end
        else esp.VelLine.Visible=false; esp.VelArrow.Visible=false end
    else
        if esp.VelLine.Visible then esp.VelLine.Visible=false; esp.VelArrow.Visible=false end
    end
end

function ESP.renderObject(esp, pos, label, color, cam)
    local screenSize = workspace.CurrentCamera.ViewportSize
    local s = cam:WorldToViewportPoint(pos)
    local onScreen = s.Z>0 and s.X>0 and s.X<screenSize.X and s.Y>0 and s.Y<screenSize.Y
    if not onScreen then ESP.hideObject(esp); return end
    local w,h = 20,20
    local x,y = s.X,s.Y
    if Config.ESP_Box then
        esp.Box[1].From=Vector2.new(x-w,y-h); esp.Box[1].To=Vector2.new(x+w,y-h)
        esp.Box[2].From=Vector2.new(x+w,y-h); esp.Box[2].To=Vector2.new(x+w,y+h)
        esp.Box[3].From=Vector2.new(x+w,y+h); esp.Box[3].To=Vector2.new(x-w,y+h)
        esp.Box[4].From=Vector2.new(x-w,y+h); esp.Box[4].To=Vector2.new(x-w,y-h)
        for _,l in ipairs(esp.Box) do l.Color=color; l.Visible=true end
    else
        for _,l in ipairs(esp.Box) do l.Visible=false end
    end
    esp.Label.Text=label; esp.Label.Position=Vector2.new(x,y-h-14); esp.Label.Color=color; esp.Label.Visible=true
    local dist=GetDistance(pos)
    esp.Dist.Text=math.floor(dist).."m"; esp.Dist.Position=Vector2.new(x,y+h+2); esp.Dist.Visible=Config.ESP_Distance
end

-- ─── Radar ───────────────────────────────────────
local Radar = {
    bg=SafeDrawing("Square"), circleBg=SafeDrawing("Circle"), border=SafeDrawing("Square"),
    circleBorder=SafeDrawing("Circle"), cross1=SafeDrawing("Line"), cross2=SafeDrawing("Line"),
    center=SafeDrawing("Circle"), dots={}, objectDots={}, palletSquares={},
}
local function SetupRadarDrawings()
    if Radar.bg then Radar.bg.Filled=true; Radar.bg.Color=Colors.RadarBg; Radar.bg.Transparency=0.4; Radar.bg.Visible=false end
    if Radar.border then Radar.border.Filled=false; Radar.border.Color=Colors.RadarBorder; Radar.border.Thickness=1; Radar.border.Visible=false end
    if Radar.circleBg then Radar.circleBg.Filled=true; Radar.circleBg.Color=Colors.RadarBg; Radar.circleBg.Transparency=0.6; Radar.circleBg.Visible=false end
    if Radar.circleBorder then Radar.circleBorder.Filled=false; Radar.circleBorder.Color=Colors.RadarBorder; Radar.circleBorder.Thickness=1; Radar.circleBorder.Visible=false end
    for _, line in ipairs({Radar.cross1, Radar.cross2}) do
        if line then line.Color=Color3.fromRGB(60,60,60); line.Thickness=1; line.Visible=false end
    end
    if Radar.center then Radar.center.Filled=true; Radar.center.Color=Colors.RadarYou; Radar.center.Radius=4; Radar.center.Visible=false end
end
SetupRadarDrawings()

local function UpdateRadar()
    if not Config.RADAR_Enabled then
        if Radar.bg then Radar.bg.Visible=false end
        if Radar.border then Radar.border.Visible=false end
        if Radar.circleBg then Radar.circleBg.Visible=false end
        if Radar.circleBorder then Radar.circleBorder.Visible=false end
        if Radar.cross1 then Radar.cross1.Visible=false end
        if Radar.cross2 then Radar.cross2.Visible=false end
        if Radar.center then Radar.center.Visible=false end
        for _,d in pairs(Radar.dots) do if d then d.Visible=false end end
        for _,d in pairs(Radar.objectDots) do if d then d.Visible=false end end
        for _,d in pairs(Radar.palletSquares) do if d then d.Visible=false end end
        return
    end
    local screenSize = workspace.CurrentCamera.ViewportSize
    local size = Config.RADAR_Size
    local radarX = screenSize.X - size - 20
    local radarY = 20
    local cx = radarX + size/2
    local cy = radarY + size/2
    local isCircle = Config.RADAR_Circle
    if isCircle then
        if Radar.bg then Radar.bg.Visible=false end
        if Radar.border then Radar.border.Visible=false end
        if Radar.circleBg then Radar.circleBg.Position=Vector2.new(cx,cy); Radar.circleBg.Radius=size/2; Radar.circleBg.Visible=true end
        if Radar.circleBorder then Radar.circleBorder.Position=Vector2.new(cx,cy); Radar.circleBorder.Radius=size/2; Radar.circleBorder.Visible=true end
    else
        if Radar.circleBg then Radar.circleBg.Visible=false end
        if Radar.circleBorder then Radar.circleBorder.Visible=false end
        if Radar.bg then Radar.bg.Position=Vector2.new(radarX,radarY); Radar.bg.Size=Vector2.new(size,size); Radar.bg.Visible=true end
        if Radar.border then Radar.border.Position=Vector2.new(radarX,radarY); Radar.border.Size=Vector2.new(size,size); Radar.border.Visible=true end
    end
    if Radar.cross1 then Radar.cross1.From=Vector2.new(cx,radarY); Radar.cross1.To=Vector2.new(cx,radarY+size); Radar.cross1.Visible=true end
    if Radar.cross2 then Radar.cross2.From=Vector2.new(radarX,cy); Radar.cross2.To=Vector2.new(radarX+size,cy); Radar.cross2.Visible=true end
    if Radar.center then Radar.center.Position=Vector2.new(cx,cy); Radar.center.Visible=true end
    local myRoot = GetCharacterRoot()
    if not myRoot then return end
    local myCF = myRoot.CFrame
    local range = Tuning.RadarRange
    local dotIdx = 0
    for _,player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local pr = player.Character:FindFirstChild("HumanoidRootPart")
            if pr then
                local isK = IsKiller(player)
                if (isK and Config.RADAR_Killer) or (not isK and Config.RADAR_Survivor) then
                    local rel = myCF:PointToObjectSpace(pr.Position)
                    local rx = cx + (rel.X/range)*(size/2); local ry = cy - (rel.Z/range)*(size/2)
                    rx = math.clamp(rx, radarX+3, radarX+size-3); ry = math.clamp(ry, radarY+3, radarY+size-3)
                    dotIdx += 1
                    if not Radar.dots[dotIdx] then Radar.dots[dotIdx]=Drawing.new("Circle"); Radar.dots[dotIdx].Filled=true end
                    local d = Radar.dots[dotIdx]
                    d.Position=Vector2.new(rx,ry); d.Radius=Tuning.RadarDotSize
                    d.Color=isK and Colors.Killer or Colors.Survivor; d.Visible=true
                end
            end
        end
    end
    for i=dotIdx+1,#Radar.dots do if Radar.dots[i] then Radar.dots[i].Visible=false end end
    local objIdx = 0
    if Config.RADAR_Generator then
        for _,obj in ipairs(Cache.Generators) do
            if obj.part and obj.part.Parent then
                local rel=myCF:PointToObjectSpace(obj.part.Position)
                local rx=cx+(rel.X/range)*(size/2); local ry=cy-(rel.Z/range)*(size/2)
                rx=math.clamp(rx,radarX+3,radarX+size-3); ry=math.clamp(ry,radarY+3,radarY+size-3)
                objIdx+=1
                if not Radar.objectDots[objIdx] then Radar.objectDots[objIdx]=Drawing.new("Circle"); Radar.objectDots[objIdx].Filled=true end
                local d=Radar.objectDots[objIdx]
                d.Position=Vector2.new(rx,ry); d.Radius=3; d.Color=Colors.Generator; d.Visible=true
            end
        end
    end
    for i=objIdx+1,#Radar.objectDots do if Radar.objectDots[i] then Radar.objectDots[i].Visible=false end end
end

-- ─── Map scanning ────────────────────────────────
local function ScanMap()
    Cache.Generators={}; Cache.Gates={}; Cache.Hooks={}; Cache.Pallets={}; Cache.Windows={}
    local map = Workspace:FindFirstChild("Map")
    local objectsToScan = map and map:GetDescendants() or Workspace:GetDescendants()
    
    for _,obj in ipairs(objectsToScan) do
        local n = obj.Name
        if obj:IsA("Model") then
            if n=="Generator" then local p=obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true); if p then table.insert(Cache.Generators,{model=obj,part=p}) end end
            if n=="Hook" or n:find("Hook") then local p=obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true); if p then table.insert(Cache.Hooks,{model=obj,part=p}) end end
            if n=="Pallet" then local p=obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true); if p then table.insert(Cache.Pallets,{model=obj,part=p}) end end
            if n=="Window" or n:find("Window") then local p=obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true); if p then table.insert(Cache.Windows,{model=obj,part=p}) end end
        elseif obj:IsA("BasePart") then
            if n=="Gate" or n:find("ExitGate") or n:find("Gate") then table.insert(Cache.Gates,{part=obj}) end
        end
    end
end

local function UpdateClosestHook()
    local root = GetCharacterRoot()
    if not root then Cache.ClosestHook=nil; return end
    local closest,closestDist = nil,math.huge
    for _,obj in ipairs(Cache.Hooks) do
        if obj.part and obj.part.Parent then
            local d = GetDistance(obj.part.Position)
            if d < closestDist then closestDist=d; closest=obj end
        end
    end
    Cache.ClosestHook = closest
end

-- ─── Teleport helpers ────────────────────────────
local function TeleportToGenerator(index)
    if #Cache.Generators==0 then return false end
    local sorted={}
    for _,g in ipairs(Cache.Generators) do table.insert(sorted,{gen=g,dist=GetDistance(g.part.Position)}) end
    table.sort(sorted,function(a,b) return a.dist<b.dist end)
    local target=sorted[index or 1]; if not target then return false end
    local root=GetCharacterRoot(); if not root then return false end
    pcall(function() for _,p in ipairs(LocalPlayer.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end)
    root.CFrame=target.gen.part.CFrame+Vector3.new(0,Config.TP_Offset,0)
    task.delay(0.3,function() if LocalPlayer.Character then for _,p in ipairs(LocalPlayer.Character:GetDescendants()) do if p:IsA("BasePart") and p.Name~="HumanoidRootPart" then p.CanCollide=true end end end end)
    return true
end

local function TeleportToGate()
    if #Cache.Gates==0 then return false end
    local sorted={}
    for _,g in ipairs(Cache.Gates) do table.insert(sorted,{gate=g,dist=GetDistance(g.part.Position)}) end
    table.sort(sorted,function(a,b) return a.dist<b.dist end)
    local root=GetCharacterRoot(); if not root then return false end
    pcall(function() for _,p in ipairs(LocalPlayer.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end)
    root.CFrame=sorted[1].gate.part.CFrame+Vector3.new(0,Config.TP_Offset,0)
    task.delay(0.3,function() if LocalPlayer.Character then for _,p in ipairs(LocalPlayer.Character:GetDescendants()) do if p:IsA("BasePart") and p.Name~="HumanoidRootPart" then p.CanCollide=true end end end end)
    return true
end

local function TeleportToHook()
    if not Cache.ClosestHook then return false end
    local root=GetCharacterRoot(); if not root then return false end
    pcall(function() for _,p in ipairs(LocalPlayer.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end)
    root.CFrame=Cache.ClosestHook.part.CFrame+Vector3.new(0,Config.TP_Offset,0)
    task.delay(0.3,function() if LocalPlayer.Character then for _,p in ipairs(LocalPlayer.Character:GetDescendants()) do if p:IsA("BasePart") and p.Name~="HumanoidRootPart" then p.CanCollide=true end end end end)
    return true
end

local function GetKillerDistance()
    local root=GetCharacterRoot(); if not root then return math.huge end
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer and IsKiller(p) then
            local kr=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if kr then return (kr.Position-root.Position).Magnitude, kr.Position end
        end
    end
    return math.huge,nil
end

-- ─── Fling ───────────────────────────────────────
local function FlingNearest()
    if not Config.FLING_Enabled then return end
    local root=GetCharacterRoot(); if not root then return end
    local closest,closestDist=nil,math.huge
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer and p.Character then
            local tr=p.Character:FindFirstChild("HumanoidRootPart")
            if tr then local d=(tr.Position-root.Position).Magnitude; if d<closestDist then closestDist=d;closest=p end end
        end
    end
    if closest and closest.Character then
        local tr=closest.Character:FindFirstChild("HumanoidRootPart")
        if tr then
            local orig=root.CFrame
            for i=1,10 do root.CFrame=tr.CFrame; root.Velocity=Vector3.new(Config.FLING_Strength,Config.FLING_Strength/2,Config.FLING_Strength); root.RotVelocity=Vector3.new(9999,9999,9999); task.wait() end
            root.CFrame=orig; root.Velocity=Vector3.zero; root.RotVelocity=Vector3.zero
        end
    end
end

local function FlingAll()
    if not Config.FLING_Enabled then return end
    local root=GetCharacterRoot(); if not root then return end
    local orig=root.CFrame
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer and p.Character then
            local tr=p.Character:FindFirstChild("HumanoidRootPart")
            if tr then for i=1,5 do root.CFrame=tr.CFrame; root.Velocity=Vector3.new(Config.FLING_Strength,Config.FLING_Strength/2,Config.FLING_Strength); root.RotVelocity=Vector3.new(9999,9999,9999); task.wait() end end
        end
    end
    root.CFrame=orig; root.Velocity=Vector3.zero; root.RotVelocity=Vector3.zero
end

local function StartTouchFling()
    if not ReplicatedStorage:FindFirstChild("juisdfj0i32i0eidsuf0iok") then
        local detection = Instance.new("Decal")
        detection.Name = "juisdfj0i32i0eidsuf0iok"
        detection.Parent = ReplicatedStorage
    end
    
    local function doFling()
        local c, hrp, vel, movel = nil, nil, nil, 0.1
        while Config.TOUCH_Fling do
            RunService.Heartbeat:Wait()
            c = LocalPlayer.Character
            hrp = c and c:FindFirstChild("HumanoidRootPart")
            if hrp then
                vel = hrp.Velocity
                hrp.Velocity = vel * 10000 + Vector3.new(0, 10000, 0)
                RunService.RenderStepped:Wait()
                hrp.Velocity = vel
                RunService.Stepped:Wait()
                hrp.Velocity = vel + Vector3.new(0, movel, 0)
                movel = -movel
            end
        end
    end
    
    coroutine.wrap(doFling)()
end

-- ─── Movement / Combat ───────────────────────────
local OriginalHitboxSizes={}
local function UpdateHitboxes()
    if GetRole()~="Killer" or not Config.HITBOX_Enabled then
        for player,orig in pairs(OriginalHitboxSizes) do
            pcall(function() if player.Character then local r=player.Character:FindFirstChild("HumanoidRootPart"); if r then r.Size=orig;r.Transparency=1;r.CanCollide=true end end end)
        end
        OriginalHitboxSizes={}; return
    end
    for _,player in ipairs(Players:GetPlayers()) do
        if player~=LocalPlayer and IsSurvivor(player) then
            local char=player.Character
            if char then
                local root=char:FindFirstChild("HumanoidRootPart"); local hum=char:FindFirstChildOfClass("Humanoid")
                if root and hum and hum.Health>0 then
                    if not OriginalHitboxSizes[player] then OriginalHitboxSizes[player]=root.Size end
                    local s=Config.HITBOX_Size; root.Size=Vector3.new(s,s,s); root.CanCollide=false; root.Transparency=0.7
                elseif root and OriginalHitboxSizes[player] then
                    root.Size=OriginalHitboxSizes[player]; root.Transparency=1; root.CanCollide=true; OriginalHitboxSizes[player]=nil
                end
            end
        end
    end
end

local FlyBodyVelocity,FlyBodyGyro=nil,nil
local function UpdateFly()
    local char=LocalPlayer.Character; if not char then return end
    local root=char:FindFirstChild("HumanoidRootPart"); local hum=char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    if Config.FLY_Enabled then
        hum.PlatformStand=true
        if not FlyBodyVelocity then FlyBodyVelocity=Instance.new("BodyVelocity"); FlyBodyVelocity.MaxForce=Vector3.new(math.huge,math.huge,math.huge); FlyBodyVelocity.Velocity=Vector3.zero; FlyBodyVelocity.Parent=root end
        if not FlyBodyGyro then FlyBodyGyro=Instance.new("BodyGyro"); FlyBodyGyro.MaxTorque=Vector3.new(math.huge,math.huge,math.huge); FlyBodyGyro.P=9e4; FlyBodyGyro.Parent=root end
        local cam=workspace.CurrentCamera; local dir=Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir+=cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir-=cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir-=cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir+=cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir+=Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir-=Vector3.new(0,1,0) end
        if dir.Magnitude>0 then dir=dir.Unit*Config.FLY_Speed end
        if Config.FLY_Method=="Velocity" then FlyBodyVelocity.Velocity=dir
        else FlyBodyVelocity.Velocity=Vector3.zero; if dir.Magnitude>0 then root.CFrame=root.CFrame+dir*0.05 end end
        FlyBodyGyro.CFrame=cam.CFrame
    else
        if FlyBodyVelocity then FlyBodyVelocity:Destroy(); FlyBodyVelocity=nil end
        if FlyBodyGyro then FlyBodyGyro:Destroy(); FlyBodyGyro=nil end
        if hum then hum.PlatformStand=false end
    end
end

local InfiniteJumpConnection=nil
local function SetupInfiniteJump()
    if InfiniteJumpConnection then InfiniteJumpConnection:Disconnect(); InfiniteJumpConnection=nil end
    InfiniteJumpConnection=UserInputService.JumpRequest:Connect(function()
        if not Config.JUMP_Infinite then return end
        local char=LocalPlayer.Character; if not char then return end
        local hum=char:FindFirstChildOfClass("Humanoid"); if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)
end

local OriginalJumpPower=nil
local function UpdateJumpPower()
    local char=LocalPlayer.Character; if not char then return end
    local hum=char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    if not OriginalJumpPower then OriginalJumpPower=hum.JumpPower end
    if Config.JUMP_Power~=50 then hum.JumpPower=Config.JUMP_Power; hum.UseJumpPower=true end
end

local OriginalFOV=nil
local function UpdateCameraFOV()
    local cam=workspace.CurrentCamera; if not cam then return end
    if not OriginalFOV then OriginalFOV=cam.FieldOfView end
    if Config.CAM_FOVEnabled then cam.FieldOfView=Config.CAM_FOV elseif OriginalFOV then cam.FieldOfView=OriginalFOV end
end

local ThirdPersonWasActive=false
local OriginalCameraType=nil
local function UpdateThirdPerson()
    local cam=workspace.CurrentCamera; if not cam then return end
    local isKiller=GetRole()=="Killer"
    if Config.CAM_ThirdPerson and isKiller then
        if not ThirdPersonWasActive then OriginalCameraType=cam.CameraType end
        cam.CameraType=Enum.CameraType.Custom
        local char=LocalPlayer.Character
        if char then local hum=char:FindFirstChildOfClass("Humanoid"); if hum then hum.CameraOffset=Vector3.new(2,1,8) end end
        ThirdPersonWasActive=true
    elseif ThirdPersonWasActive then
        if OriginalCameraType then cam.CameraType=OriginalCameraType; OriginalCameraType=nil end
        local char=LocalPlayer.Character
        if char then local hum=char:FindFirstChildOfClass("Humanoid"); if hum then hum.CameraOffset=Vector3.new(0,0,0) end end
        ThirdPersonWasActive=false
    end
end

local function UpdateShiftLock()
    if not Config.CAM_ShiftLock then return end
    local char=LocalPlayer.Character; if not char then return end
    local root=char:FindFirstChild("HumanoidRootPart"); local cam=workspace.CurrentCamera
    if not root or not cam then return end
    local look=Vector3.new(cam.CFrame.LookVector.X,0,cam.CFrame.LookVector.Z).Unit
    root.CFrame=CFrame.new(root.Position,root.Position+look)
end

local FogCache={}
local function RemoveFog()
    pcall(function()
        local lighting=game:GetService("Lighting")
        for _,obj in ipairs(lighting:GetChildren()) do
            if obj:IsA("Atmosphere") or obj.Name:lower():find("fog") then
                if not FogCache[obj] then FogCache[obj]={enabled=true,parent=obj.Parent} end
                if obj:IsA("Atmosphere") then obj.Density=0 else obj.Parent=nil end
            end
        end
        lighting.FogEnd=100000; lighting.FogStart=0
    end)
end
local function RestoreFog()
    pcall(function()
        for obj,data in pairs(FogCache) do if obj and data.parent then if obj:IsA("PostEffect") then obj.Enabled=data.enabled else obj.Parent=data.parent end end end
        FogCache={}; game:GetService("Lighting").FogEnd=1000
    end)
end

local function UpdateNoFall()
    if not Config.SURV_NoFall then return end
    local char=LocalPlayer.Character; if not char then return end
    local hum=char:FindFirstChildOfClass("Humanoid")
    if hum then hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown,false); hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,false) end
end

local function SetupAntiBlind()
    pcall(function()
        local r=ReplicatedStorage:FindFirstChild("Remotes"); if not r then return end
        local items=r:FindFirstChild("Items"); if not items then return end
        local fl=items:FindFirstChild("Flashlight"); if not fl then return end
        local gb=fl:FindFirstChild("GotBlinded"); if not (gb and gb:IsA("RemoteEvent")) then return end
        local old=gb.FireServer
        gb.FireServer=function(self,...) if Config.KILLER_AntiBlind and GetRole()=="Killer" then return nil end; return old(self,...) end
    end)
end

local function SetupNoPalletStun()
    pcall(function()
        local r=ReplicatedStorage:FindFirstChild("Remotes"); if not r then return end
        local pallet=r:FindFirstChild("Pallet"); if not pallet then return end
        local jason=pallet:FindFirstChild("Jason"); if not jason then return end
        local stun=jason:FindFirstChild("Stun"); local stunDrop=jason:FindFirstChild("StunDrop")
        if stun and stun:IsA("RemoteEvent") then
            local mt=getrawmetatable(game)
            if mt and setreadonly then
                setreadonly(mt,false)
                local oldIdx=mt.__namecall
                mt.__namecall=newcclosure(function(self,...)
                    if Config.KILLER_NoPalletStun and GetRole()=="Killer" then
                        if self==stun or self==stunDrop then return nil end
                    end
                    return oldIdx(self,...)
                end)
                setreadonly(mt,true)
            end
        end
    end)
end

local QTEHandler={Active=false,Conn=nil,UIConn=nil}
local function SetupSkillCheckMonitor()
    QTEHandler.Conn=RunService.Heartbeat:Connect(function()
        if not Config.AUTO_SkillCheck then return end
        pcall(function()
            local r=ReplicatedStorage:FindFirstChild("Remotes"); if not r then return end
            local grem=r:FindFirstChild("Generator"); if not grem then return end
            local sc=grem:FindFirstChild("SkillCheckResultEvent"); if not sc then return end
            
            -- Find nearest generator and its repair point
            local root = GetCharacterRoot()
            if not root then return end
            
            local closestGen, closestPoint = nil, nil
            local minDist = 12
            
            for _, gen in ipairs(Cache.Generators) do
                if gen.part and (gen.part.Position - root.Position).Magnitude < minDist then
                    closestGen = gen.model or gen.part
                    -- Look for a repair point child
                    for _, child in ipairs(gen.model:GetChildren()) do
                        if child.Name:find("Point") then
                            closestPoint = child
                            break
                        end
                    end
                    if closestGen then break end
                end
            end
            
            if closestGen then
                sc:FireServer("success", 1, closestGen, closestPoint)
            end
        end)
    end)
end

-- ─── Aimbot ──────────────────────────────────────
local AimFOVCircle=SafeDrawing("Circle")
if AimFOVCircle then
    AimFOVCircle.Filled=false; AimFOVCircle.Color=Color3.fromRGB(255,255,255)
    AimFOVCircle.Thickness=1; AimFOVCircle.Transparency=0.6; AimFOVCircle.Visible=false
end

local function GetAimTarget()
    local cam=workspace.CurrentCamera; if not cam then return nil end
    local screenCenter=Vector2.new(cam.ViewportSize.X/2,cam.ViewportSize.Y/2)
    local closest,closestDist=nil,math.huge
    for _,player in ipairs(Players:GetPlayers()) do
        if player~=LocalPlayer and player.Character then
            local targetPart=player.Character:FindFirstChild(Config.AIM_TargetPart) or player.Character:FindFirstChild("HumanoidRootPart")
            if targetPart then
                local hum=player.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health>0 then
                    if Config.AIM_VisCheck and not Cache.Visibility[player] then continue end
                    local s,on=WorldToScreen(targetPart.Position)
                    if on then
                        local d=(s-screenCenter).Magnitude
                        if d<Config.AIM_FOV/2 and d<closestDist then closestDist=d; closest={player=player,part=targetPart} end
                    end
                end
            end
        end
    end
    return closest
end

local function UpdateAimbot()
    local cam=workspace.CurrentCamera; if not cam then return end
    local screenCenter=Vector2.new(cam.ViewportSize.X/2,cam.ViewportSize.Y/2)
    if AimFOVCircle then
        AimFOVCircle.Position=screenCenter; AimFOVCircle.Radius=Config.AIM_FOV/2
        AimFOVCircle.Visible=Config.AIM_Enabled and Config.AIM_ShowFOV
    end
    if not Config.AIM_Enabled then State.AimTarget=nil; return end
    if Config.AIM_UseRMB and not State.AimHolding then State.AimTarget=nil; return end
    local target=GetAimTarget()
    if not target then State.AimTarget=nil; return end
    State.AimTarget=target
    local aimPos=target.part.Position
    if Config.AIM_Predict then
        local vd=ESP.velocityData[target.player]
        if vd then aimPos=aimPos+vd.vel*0.1 end
    end
    local dir=(aimPos-cam.CFrame.Position).Unit
    local targetCF=CFrame.new(cam.CFrame.Position,cam.CFrame.Position+dir)
    cam.CFrame=CFrame.new(cam.CFrame.Position,cam.CFrame.Position+Lerp(cam.CFrame.LookVector,dir,1-Config.AIM_Smooth))
end

-- ─── Auto-attack & Auto-hook ─────────────────────
local function AutoAttack()
    if not Config.AUTO_Attack or GetRole()~="Killer" then return end
    local root=GetCharacterRoot(); if not root then return end
    for _,player in ipairs(Players:GetPlayers()) do
        if player~=LocalPlayer and player.Character then
            local tr=player.Character:FindFirstChild("HumanoidRootPart")
            if tr and (tr.Position-root.Position).Magnitude<=Config.AUTO_AttackRange then
                pcall(function()
                    local rem=ReplicatedStorage:FindFirstChild("Remotes")
                    local atk=rem and rem:FindFirstChild("Attacks")
                    local ba=atk and atk:FindFirstChild("BasicAttack")
                    if ba then ba:FireServer(false) end
                end); break
            end
        end
    end
end

local function AutoHook()
    if not Config.KILLER_AutoHook or GetRole()~="Killer" then return end
    local root=GetCharacterRoot(); if not root then return end
    for _,player in ipairs(Players:GetPlayers()) do
        if player~=LocalPlayer and IsSurvivor(player) and player.Character then
            local tr=player.Character:FindFirstChild("HumanoidRootPart")
            if tr and (tr.Position-root.Position).Magnitude<=6 then
                if Cache.ClosestHook then root.CFrame=Cache.ClosestHook.part.CFrame+Vector3.new(0,Config.TP_Offset,0) end; break
            end
        end
    end
end

local LastDoubleTapTime=0
local function DoubleTap()
    if not Config.KILLER_DoubleTap or GetRole()~="Killer" then return end
    if tick()-LastDoubleTapTime<0.5 then return end
    pcall(function()
        local r=ReplicatedStorage:FindFirstChild("Remotes"); local a=r and r:FindFirstChild("Attacks"); local b=a and a:FindFirstChild("BasicAttack")
        if b then b:FireServer(false); task.wait(0.05); b:FireServer(false); LastDoubleTapTime=tick() end
    end)
end

local function InfiniteLunge()
    if not Config.KILLER_InfiniteLunge or GetRole()~="Killer" then return end
    local char=LocalPlayer.Character; if not char then return end
    local root=char:FindFirstChild("HumanoidRootPart"); if not root then return end
    root.Velocity=root.CFrame.LookVector*100+Vector3.new(0,10,0)
end

-- ─── ESP render loop ─────────────────────────────
local function RenderESP()
    if not Config.ESP_Enabled then ESP.hideAll(); return end
    local cam=workspace.CurrentCamera; if not cam then return end
    local screenSize=cam.ViewportSize; local screenCenter=Vector2.new(screenSize.X/2,screenSize.Y/2)
    -- players
    for _,player in ipairs(Players:GetPlayers()) do
        if player==LocalPlayer then continue end
        local char=player.Character
        local isK=IsKiller(player); local isS=IsSurvivor(player)
        if not char or not ((isK and Config.ESP_Killer) or (isS and Config.ESP_Survivor)) then
            if ESP.cache[player] then ESP.hide(ESP.cache[player]) end
            Chams.Remove(char)
            continue
        end
        if Config.ESP_PlayerChams then
            local cd=isK and ChamsColors.Killer or ChamsColors.Survivor
            if not Chams.Objects[char] then Chams.Create(char,cd,player.Name) else Chams.SetColor(char,cd) end
            Chams.Update(char,player.Name)
            if ESP.cache[player] then ESP.hide(ESP.cache[player]) end
        else
            Chams.Remove(char)
            if not ESP.cache[player] then ESP.cache[player]=ESP.create(); ESP.setup(ESP.cache[player]) end
            ESP.render(ESP.cache[player],player,char,cam,screenSize,screenCenter)
        end
    end
    -- objects
    for _,obj in ipairs(Cache.Generators) do
        local key=tostring(obj.model or obj.part)
        if Config.ESP_Generator and obj.part and obj.part.Parent then
            if Config.ESP_ObjectChams then
                if not Chams.Objects[obj.model or obj.part] then Chams.Create(obj.model or obj.part,ChamsColors.Generator,"GEN") end
                Chams.Update(obj.model or obj.part,"GEN",GetDistance(obj.part.Position))
                if ESP.objectCache[key] then ESP.hideObject(ESP.objectCache[key]) end
            else
                if not ESP.objectCache[key] then ESP.objectCache[key]=ESP.createObject(); ESP.setupObject(ESP.objectCache[key]) end
                ESP.renderObject(ESP.objectCache[key],obj.part.Position,"GEN",Colors.Generator,cam)
                Chams.Remove(obj.model or obj.part)
            end
        else
            Chams.Remove(obj.model or obj.part)
            if ESP.objectCache[key] then ESP.hideObject(ESP.objectCache[key]) end
        end
    end
    for _,obj in ipairs(Cache.Hooks) do
        local target=obj.model or obj.part
        local key=tostring(target)
        local isClosest=Config.ESP_ClosestHook and obj==Cache.ClosestHook
        if Config.ESP_Hook and obj.part and obj.part.Parent then
            local uc=isClosest and ChamsColors.HookClose or ChamsColors.Hook
            local ul=isClosest and "HOOK!" or "HOOK"
            if Config.ESP_ObjectChams then
                if not Chams.Objects[target] then Chams.Create(target,uc,ul) else Chams.SetColor(target,uc) end
                Chams.Update(target,ul,GetDistance(obj.part.Position))
                if ESP.objectCache[key] then ESP.hideObject(ESP.objectCache[key]) end
            else
                if not ESP.objectCache[key] then ESP.objectCache[key]=ESP.createObject(); ESP.setupObject(ESP.objectCache[key]) end
                ESP.renderObject(ESP.objectCache[key],obj.part.Position,ul,isClosest and Colors.HookClose or Colors.Hook,cam)
                Chams.Remove(target)
            end
        else
            Chams.Remove(target)
            if ESP.objectCache[key] then ESP.hideObject(ESP.objectCache[key]) end
        end
    end
    for _,obj in ipairs(Cache.Pallets) do
        local target=obj.model or obj.part
        local key=tostring(target)
        if Config.ESP_Pallet and obj.part and obj.part.Parent then
            if Config.ESP_ObjectChams then
                if not Chams.Objects[target] then Chams.Create(target,ChamsColors.Pallet,"PALLET") end
                Chams.Update(target,"PALLET",GetDistance(obj.part.Position))
                if ESP.objectCache[key] then ESP.hideObject(ESP.objectCache[key]) end
            else
                if not ESP.objectCache[key] then ESP.objectCache[key]=ESP.createObject(); ESP.setupObject(ESP.objectCache[key]) end
                ESP.renderObject(ESP.objectCache[key],obj.part.Position,"PALLET",Colors.Pallet,cam)
                Chams.Remove(target)
            end
        else
            Chams.Remove(target)
            if ESP.objectCache[key] then ESP.hideObject(ESP.objectCache[key]) end
        end
    end
    for _,obj in ipairs(Cache.Windows) do
        local target=obj.model or obj.part
        local key=tostring(target)
        if Config.ESP_Window and obj.part and obj.part.Parent then
            if Config.ESP_ObjectChams then
                if not Chams.Objects[target] then Chams.Create(target,ChamsColors.Window,"WINDOW") end
                Chams.Update(target,"WINDOW",GetDistance(obj.part.Position))
                if ESP.objectCache[key] then ESP.hideObject(ESP.objectCache[key]) end
            else
                if not ESP.objectCache[key] then ESP.objectCache[key]=ESP.createObject(); ESP.setupObject(ESP.objectCache[key]) end
                ESP.renderObject(ESP.objectCache[key],obj.part.Position,"WINDOW",Colors.Window,cam)
                Chams.Remove(target)
            end
        else
            Chams.Remove(target)
            if ESP.objectCache[key] then ESP.hideObject(ESP.objectCache[key]) end
        end
    end
    for _,obj in ipairs(Cache.Gates) do
        local key=tostring(obj.part)
        if Config.ESP_Gate and obj.part and obj.part.Parent then
            if Config.ESP_ObjectChams then
                if not Chams.Objects[obj.part] then Chams.Create(obj.part,ChamsColors.Gate,"GATE") end
                Chams.Update(obj.part,"GATE",GetDistance(obj.part.Position))
                if ESP.objectCache[key] then ESP.hideObject(ESP.objectCache[key]) end
            else
                if not ESP.objectCache[key] then ESP.objectCache[key]=ESP.createObject(); ESP.setupObject(ESP.objectCache[key]) end
                ESP.renderObject(ESP.objectCache[key],obj.part.Position,"GATE",Colors.Gate,cam)
                Chams.Remove(obj.part)
            end
        else
            Chams.Remove(obj.part)
            if ESP.objectCache[key] then ESP.hideObject(ESP.objectCache[key]) end
        end
    end
end

-- ─── Speed hack ──────────────────────────────────
local _wasSpeedEnabled = false
local function UpdateSpeed()
    local char=LocalPlayer.Character; if not char then return end
    local hum=char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    if Config.SPEED_Enabled then
        if Config.SPEED_Method == "Attribute" then
            hum.WalkSpeed = Config.SPEED_Value
            -- Also set attributes for bypass
            pcall(function()
                hum:SetAttribute("WalkSpeed", Config.SPEED_Value)
                hum:SetAttribute("Speed", Config.SPEED_Value)
                char:SetAttribute("WalkSpeed", Config.SPEED_Value)
            end)
        elseif Config.SPEED_Method == "TP" then
            hum.WalkSpeed = 16
            local root = char:FindFirstChild("HumanoidRootPart")
            if root and hum.MoveDirection.Magnitude > 0 then
                local extraSpeed = Config.SPEED_Value - 16
                if extraSpeed > 0 then
                    root.CFrame = root.CFrame + (hum.MoveDirection * (extraSpeed / 60))
                end
            end
        end
        _wasSpeedEnabled = true
    elseif _wasSpeedEnabled then
        hum.WalkSpeed = 16
        pcall(function()
            hum:SetAttribute("WalkSpeed", 16)
            hum:SetAttribute("Speed", 16)
            char:SetAttribute("WalkSpeed", 16)
        end)
        _wasSpeedEnabled = false
    end
end

-- ─── Noclip ──────────────────────────────────────
local function UpdateNoclip()
    if not Config.NOCLIP_Enabled then return end
    local char=LocalPlayer.Character; if not char then return end
    for _,p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") and p.Name~="HumanoidRootPart" then p.CanCollide=false end
    end
end

-- ─── TeleAway ────────────────────────────────────
local function TeleportAway()
    if not Config.AUTO_TeleAway or GetRole()=="Killer" then return end
    local now=tick(); if now-State.LastTeleAway<3 then return end
    local root=GetCharacterRoot(); if not root then return end
    local killerDist,killerPos=GetKillerDistance()
    if killerDist>Config.AUTO_TeleAwayDist then return end
    State.LastTeleAway=now
    local bestSpot,bestDist=nil,0
    for _,gate in ipairs(Cache.Gates) do
        if gate.part and killerPos then
            local d=(gate.part.Position-killerPos).Magnitude
            if d>bestDist then bestDist=d;bestSpot=gate.part.Position end
        end
    end
    if not bestSpot or bestDist<50 then
        for _,gen in ipairs(Cache.Generators) do
            if gen.part and killerPos then
                local d=(gen.part.Position-killerPos).Magnitude
                if d>bestDist then bestDist=d;bestSpot=gen.part.Position end
            end
        end
    end
    if not bestSpot and killerPos then
        local dir=(root.Position-killerPos).Unit; bestSpot=root.Position+dir*80
    end
    if bestSpot then
        pcall(function() for _,p in ipairs(LocalPlayer.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end)
        root.CFrame=CFrame.new(bestSpot+Vector3.new(0,Config.TP_Offset,0))
        task.delay(0.3,function() if LocalPlayer.Character then for _,p in ipairs(LocalPlayer.Character:GetDescendants()) do if p:IsA("BasePart") and p.Name~="HumanoidRootPart" then p.CanCollide=true end end end end)
    end
end

-- ─── Auto-wiggle ─────────────────────────────────
local WiggleDir=1
local function UpdateAutoWiggle()
    if not Config.SURV_AutoWiggle then return end
    local char=LocalPlayer.Character; if not char then return end
    local hum=char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    if hum:GetState()==Enum.HumanoidStateType.Physics then
        hum:Move(Vector3.new(WiggleDir,0,0),true); WiggleDir=-WiggleDir
    end
end

-- ─── BEAT GAME ───────────────────────────────────
local function UpdateBeatGame()
    local now=tick(); if now-State.LastBeatTP<1 then return end
    if Config.BEAT_Survivor and GetRole()=="Survivor" then
        local root=GetCharacterRoot(); if not root then return end
        local bestGate=nil; local bestDist=math.huge
        for _,g in ipairs(Cache.Gates) do
            if g.part then local d=GetDistance(g.part.Position); if d<bestDist then bestDist=d;bestGate=g end end
        end
        if bestGate then
            State.LastBeatTP=now
            pcall(function() for _,p in ipairs(LocalPlayer.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end)
            root.CFrame=bestGate.part.CFrame+Vector3.new(0,Config.TP_Offset,0)
        end
    end
    if Config.BEAT_Killer and GetRole()=="Killer" then
        local root=GetCharacterRoot(); if not root then return end
        for _,player in ipairs(Players:GetPlayers()) do
            if player~=LocalPlayer and IsSurvivor(player) and player.Character then
                local sr=player.Character:FindFirstChild("HumanoidRootPart")
                if sr then
                    State.LastBeatTP=now
                    pcall(function() for _,p in ipairs(LocalPlayer.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end)
                    root.CFrame=sr.CFrame+Vector3.new(0,Config.TP_Offset,0)
                    break
                end
            end
        end
    end
end

-- ─── KILLER – destroy pallets/gens ───────────────
local function UpdateDestroyPallets()
    if not Config.KILLER_DestroyPallets or GetRole()~="Killer" then return end
    local root=GetCharacterRoot(); if not root then return end
    for _,obj in ipairs(Cache.Pallets) do
        if obj.part and obj.part.Parent and GetDistance(obj.part.Position)<10 then
            pcall(function()
                local r=ReplicatedStorage:FindFirstChild("Remotes"); local p=r and r:FindFirstChild("Pallet"); local bp=p and p:FindFirstChild("Break")
                if bp then bp:FireServer(obj.part) end
            end)
        end
    end
end

local function UpdateFullGenBreak()
    if not Config.KILLER_FullGenBreak or GetRole()~="Killer" then return end
    local root=GetCharacterRoot(); if not root then return end
    for _,obj in ipairs(Cache.Generators) do
        if obj.part and obj.part.Parent and GetDistance(obj.part.Position)<10 then
            pcall(function()
                local r=ReplicatedStorage:FindFirstChild("Remotes"); local g=r and r:FindFirstChild("Generator"); local kb=g and g:FindFirstChild("KickEvent")
                if kb then for i=1,5 do kb:FireServer(obj.model,obj.part) end end
            end)
        end
    end
end

-- ─── Visibility update ───────────────────────────
local function UpdateVisibility()
    for _,player in ipairs(Players:GetPlayers()) do
        if player~=LocalPlayer and player.Character then
            Cache.Visibility[player]=IsVisible(player.Character)
        end
    end
end

-- ─── Main render/auto loop ───────────────────────
-- ─── Separated loops for performance ─────────────
-- RenderStepped: ONLY smooth per-frame things (fly, aimbot FOV circle, camera)
-- Heartbeat (throttled): ESP box drawing, radar — does NOT need to run 60fps
local function MainLoop()
    -- Per-frame: character movement & camera (must be smooth)
    UpdateFly()
    UpdateThirdPerson()
    UpdateShiftLock()
    UpdateCameraFOV()
    UpdateAimbot()
    if Config.ESP_Enabled then RenderESP() else ESP.hideAll() end
    UpdateRadar()
end

-- Cache and Raycasting runs on its own throttled Heartbeat loop
local function ESPLoop()
    while not State.Unloaded do
        local now = tick()

        -- Visibility raycast: 10fps (0.1s) — raycasts are expensive
        if now - State.LastVisCheck >= 0.1 then
            UpdateVisibility()
            State.LastVisCheck = now
        end

        -- Cache/cleanup: 1fps (1.0s)
        if now - State.LastCacheUpdate >= 1.0 then
            UpdateClosestHook()
            ESP.cleanup()
            State.LastCacheUpdate = now
        end

        -- Misc game state (cheap)
        UpdateSpeed()
        UpdateNoclip()
        UpdateNoFall()
        UpdateHitboxes()

        if Config.NO_Fog then
            RemoveFog()
        elseif State.LastFogState then
            RestoreFog()
        end
        State.LastFogState = Config.NO_Fog

        task.wait(0.05) -- ~20fps for ESP thread
    end
end

local function AutoLoop()
    while not State.Unloaded do
        task.wait(0.1)
        AutoAttack(); AutoHook(); TeleportAway(); UpdateAutoWiggle()
        UpdateBeatGame(); DoubleTap(); InfiniteLunge()
        UpdateDestroyPallets(); UpdateFullGenBreak()
    end
end

-- ╔══════════════════════════════════════════════╗
-- ║   W I N D U I  –  MENU                       ║
-- ╚══════════════════════════════════════════════╝

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Violence Hub",
    Icon = "skull",
    Author = "by Violence",
    Folder = "ViolenceHub",
    Size = UDim2.fromOffset(560, 460),
    Transparent = true,
    Theme = "Dark",
    Resizable = false,
    ScrollBarEnabled = true,
})

-- ─── Helper to send notification ─────────────────
local function Notif(title, desc, dur)
    WindUI:Notify({ Title=title, Desc=desc, Duration=dur or 3 })
end

-- ══════════════════════════════════════════════════
--  TAB 1 – ESP
-- ══════════════════════════════════════════════════
local TabESP = Window:Tab({ Title = "ESP", Icon = "eye" })

local SecESPGeneral = TabESP:Section({ Title = "General" })
SecESPGeneral:Toggle({ Title="Enable ESP", Value=Config.ESP_Enabled, Callback=function(v) Config.ESP_Enabled=v; if not v then ESP.hideAll() end end })
SecESPGeneral:Toggle({ Title="Max Distance", Desc="Toggle distance limiter", Value=false, Callback=function(v) end })
SecESPGeneral:Slider({ Title="Max Dist", Value={Min=100,Max=1000,Default=Config.ESP_MaxDist}, Step=50, Callback=function(v) Config.ESP_MaxDist=v end })

local SecESPPlayers = TabESP:Section({ Title = "Players" })
SecESPPlayers:Toggle({ Title="Killer ESP", Value=Config.ESP_Killer, Callback=function(v) Config.ESP_Killer=v end })
SecESPPlayers:Toggle({ Title="Survivor ESP", Value=Config.ESP_Survivor, Callback=function(v) Config.ESP_Survivor=v end })
SecESPPlayers:Toggle({ Title="Player Chams", Desc="Highlight mode for players", Value=Config.ESP_PlayerChams, Callback=function(v) Config.ESP_PlayerChams=v end })

local SecESPObj = TabESP:Section({ Title = "Objects" })
SecESPObj:Toggle({ Title="Generator", Value=Config.ESP_Generator, Callback=function(v) Config.ESP_Generator=v end })
SecESPObj:Toggle({ Title="Gate", Value=Config.ESP_Gate, Callback=function(v) Config.ESP_Gate=v end })
SecESPObj:Toggle({ Title="Hook", Value=Config.ESP_Hook, Callback=function(v) Config.ESP_Hook=v end })
SecESPObj:Toggle({ Title="Closest Hook Highlight", Value=Config.ESP_ClosestHook, Callback=function(v) Config.ESP_ClosestHook=v end })
SecESPObj:Toggle({ Title="Pallet", Value=Config.ESP_Pallet, Callback=function(v) Config.ESP_Pallet=v end })
SecESPObj:Toggle({ Title="Window", Value=Config.ESP_Window, Callback=function(v) Config.ESP_Window=v end })
SecESPObj:Toggle({ Title="Object Chams", Desc="Highlight mode for objects", Value=Config.ESP_ObjectChams, Callback=function(v) Config.ESP_ObjectChams=v end })

local SecESPDetail = TabESP:Section({ Title = "Details" })
SecESPDetail:Toggle({ Title="ESP Box", Value=Config.ESP_Box, Callback=function(v) Config.ESP_Box=v end })
SecESPDetail:Toggle({ Title="Names", Value=Config.ESP_Names, Callback=function(v) Config.ESP_Names=v end })
SecESPDetail:Toggle({ Title="Distance", Value=Config.ESP_Distance, Callback=function(v) Config.ESP_Distance=v end })
SecESPDetail:Toggle({ Title="Health Bar", Value=Config.ESP_Health, Callback=function(v) Config.ESP_Health=v end })
SecESPDetail:Toggle({ Title="Skeleton", Value=Config.ESP_Skeleton, Callback=function(v) Config.ESP_Skeleton=v end })
SecESPDetail:Toggle({ Title="Offscreen Arrows", Value=Config.ESP_Offscreen, Callback=function(v) Config.ESP_Offscreen=v end })
SecESPDetail:Toggle({ Title="Velocity", Value=Config.ESP_Velocity, Callback=function(v) Config.ESP_Velocity=v end })

local SecRadar = TabESP:Section({ Title = "Radar" })
SecRadar:Toggle({ Title="Enable Radar", Value=Config.RADAR_Enabled, Callback=function(v) Config.RADAR_Enabled=v end })
SecRadar:Toggle({ Title="Circle Shape", Value=Config.RADAR_Circle, Callback=function(v) Config.RADAR_Circle=v end })
SecRadar:Slider({ Title="Radar Size", Value={Min=80,Max=200,Default=Config.RADAR_Size}, Step=10, Callback=function(v) Config.RADAR_Size=v end })
SecRadar:Toggle({ Title="Show Killer", Value=Config.RADAR_Killer, Callback=function(v) Config.RADAR_Killer=v end })
SecRadar:Toggle({ Title="Show Survivor", Value=Config.RADAR_Survivor, Callback=function(v) Config.RADAR_Survivor=v end })
SecRadar:Toggle({ Title="Show Generator", Value=Config.RADAR_Generator, Callback=function(v) Config.RADAR_Generator=v end })
SecRadar:Toggle({ Title="Show Pallet", Value=Config.RADAR_Pallet, Callback=function(v) Config.RADAR_Pallet=v end })

-- ══════════════════════════════════════════════════
--  TAB 2 – AIM
-- ══════════════════════════════════════════════════
local TabAIM = Window:Tab({ Title = "Aim", Icon = "crosshair" })

local SecAim = TabAIM:Section({ Title = "Camera Aimbot" })
SecAim:Toggle({ Title="Enable Aimbot", Value=Config.AIM_Enabled, Callback=function(v) Config.AIM_Enabled=v end })
SecAim:Toggle({ Title="Hold RMB to Aim", Value=Config.AIM_UseRMB, Callback=function(v) Config.AIM_UseRMB=v end })
SecAim:Toggle({ Title="Show FOV Circle", Value=Config.AIM_ShowFOV, Callback=function(v) Config.AIM_ShowFOV=v end })
SecAim:Toggle({ Title="Visibility Check", Value=Config.AIM_VisCheck, Callback=function(v) Config.AIM_VisCheck=v end })
SecAim:Toggle({ Title="Prediction", Value=Config.AIM_Predict, Callback=function(v) Config.AIM_Predict=v end })
SecAim:Slider({ Title="FOV Size", Value={Min=50,Max=400,Default=Config.AIM_FOV}, Step=10, Callback=function(v) Config.AIM_FOV=v end })
SecAim:Slider({ Title="Smoothness", Desc="Lower = more snappy", Value={Min=1,Max=10,Default=math.floor(Config.AIM_Smooth*10)}, Step=1,
    Callback=function(v) Config.AIM_Smooth=v/10 end })
SecAim:Dropdown({ Title="Target Part", Values={"Head","Torso","Root"}, Value=Config.AIM_TargetPart, Callback=function(v) Config.AIM_TargetPart=v end })

local SecSpear = TabAIM:Section({ Title = "Spear Aimbot (Veil Killer)" })
SecSpear:Toggle({ Title="Spear Aimbot", Value=Config.SPEAR_Aimbot, Callback=function(v) Config.SPEAR_Aimbot=v end })
SecSpear:Slider({ Title="Spear Gravity", Value={Min=10,Max=200,Default=Config.SPEAR_Gravity}, Step=5, Callback=function(v) Config.SPEAR_Gravity=v end })
SecSpear:Slider({ Title="Spear Speed", Value={Min=50,Max=300,Default=Config.SPEAR_Speed}, Step=10, Callback=function(v) Config.SPEAR_Speed=v end })

-- ══════════════════════════════════════════════════
--  TAB 3 – SURVIVOR
-- ══════════════════════════════════════════════════
local TabSurv = Window:Tab({ Title = "Survivor", Icon = "user" })

local SecGen = TabSurv:Section({ Title = "Generators" })
SecGen:Toggle({ Title="Auto Generator", Value=Config.AUTO_Generator, Callback=function(v) Config.AUTO_Generator=v; if v then Notif("Violence","Auto Generator ON!",3) end end })
SecGen:Dropdown({ Title="Gen Speed", Values={"Fast","Slow"}, Value=Config.AUTO_GenMode, Callback=function(v) Config.AUTO_GenMode=v end })
SecGen:Slider({ Title="Leave Distance", Value={Min=10,Max=30,Default=Config.AUTO_LeaveDist}, Step=2, Callback=function(v) Config.AUTO_LeaveDist=v end })
SecGen:Keybind({ Title="Leave Gen Key", Value=tostring(Config.KEY_LeaveGen):gsub("Enum.KeyCode.",""), Callback=function(v) pcall(function() Config.KEY_LeaveGen=Enum.KeyCode[v] end) end })
SecGen:Keybind({ Title="Stop Gen Key", Value=tostring(Config.KEY_StopGen):gsub("Enum.KeyCode.",""), Callback=function(v) pcall(function() Config.KEY_StopGen=Enum.KeyCode[v] end) end })

local SecSurvival = TabSurv:Section({ Title = "Survival" })
SecSurvival:Toggle({ Title="No Fall Damage", Value=Config.SURV_NoFall, Callback=function(v) Config.SURV_NoFall=v end })
SecSurvival:Toggle({ Title="Flee Killer (Auto TP)", Value=Config.AUTO_TeleAway, Callback=function(v) Config.AUTO_TeleAway=v end })
SecSurvival:Slider({ Title="Flee Distance", Value={Min=20,Max=80,Default=Config.AUTO_TeleAwayDist}, Step=5, Callback=function(v) Config.AUTO_TeleAwayDist=v end })
SecSurvival:Toggle({ Title="Auto Parry", Value=Config.AUTO_Parry, Callback=function(v) Config.AUTO_Parry=v end })
SecSurvival:Toggle({ Title="Auto Wiggle", Value=Config.SURV_AutoWiggle, Callback=function(v) Config.SURV_AutoWiggle=v end })
SecSurvival:Toggle({ Title="Perfect Skill Check", Value=Config.AUTO_SkillCheck, Callback=function(v) Config.AUTO_SkillCheck=v end })

local SecBeatSurv = TabSurv:Section({ Title = "Beat Game" })
SecBeatSurv:Toggle({ Title="Beat Game (Survivor)", Desc="Teleports to nearest gate", Value=Config.BEAT_Survivor, Callback=function(v) Config.BEAT_Survivor=v end })

-- ══════════════════════════════════════════════════
--  TAB 4 – KILLER
-- ══════════════════════════════════════════════════
local TabKill = Window:Tab({ Title = "Killer", Icon = "zap" })

local SecCombat = TabKill:Section({ Title = "Combat" })
SecCombat:Toggle({ Title="Auto Attack", Value=Config.AUTO_Attack, Callback=function(v) Config.AUTO_Attack=v end })
SecCombat:Slider({ Title="Attack Range", Value={Min=5,Max=20,Default=Config.AUTO_AttackRange}, Step=1, Callback=function(v) Config.AUTO_AttackRange=v end })
SecCombat:Toggle({ Title="Double Tap (Instant Kill)", Value=Config.KILLER_DoubleTap, Callback=function(v) Config.KILLER_DoubleTap=v end })
SecCombat:Toggle({ Title="Infinite Lunge", Value=Config.KILLER_InfiniteLunge, Callback=function(v) Config.KILLER_InfiniteLunge=v end })
SecCombat:Toggle({ Title="Auto Hook", Value=Config.KILLER_AutoHook, Callback=function(v) Config.KILLER_AutoHook=v end })

local SecHitbox = TabKill:Section({ Title = "Hitbox" })
SecHitbox:Toggle({ Title="Hitbox Expand", Value=Config.HITBOX_Enabled, Callback=function(v) Config.HITBOX_Enabled=v end })
SecHitbox:Slider({ Title="Hitbox Size", Value={Min=5,Max=30,Default=Config.HITBOX_Size}, Step=1, Callback=function(v) Config.HITBOX_Size=v end })

local SecProtect = TabKill:Section({ Title = "Protection" })
SecProtect:Toggle({ Title="No Pallet Stun", Value=Config.KILLER_NoPalletStun, Callback=function(v) Config.KILLER_NoPalletStun=v end })
SecProtect:Toggle({ Title="Anti Blind", Value=Config.KILLER_AntiBlind, Callback=function(v) Config.KILLER_AntiBlind=v end })
SecProtect:Toggle({ Title="No Slowdown", Value=Config.KILLER_NoSlowdown, Callback=function(v) Config.KILLER_NoSlowdown=v end })

local SecDestroy = TabKill:Section({ Title = "Destruction" })
SecDestroy:Toggle({ Title="Full Gen Break", Value=Config.KILLER_FullGenBreak, Callback=function(v) Config.KILLER_FullGenBreak=v end })
SecDestroy:Toggle({ Title="Destroy Pallets", Value=Config.KILLER_DestroyPallets, Callback=function(v) Config.KILLER_DestroyPallets=v end })

local SecKillCam = TabKill:Section({ Title = "Camera" })
SecKillCam:Toggle({ Title="Third Person", Value=Config.CAM_ThirdPerson, Callback=function(v) Config.CAM_ThirdPerson=v end })
SecKillCam:Toggle({ Title="Shift Lock", Value=Config.CAM_ShiftLock, Callback=function(v) Config.CAM_ShiftLock=v end })

local SecBeatKill = TabKill:Section({ Title = "Beat Game" })
SecBeatKill:Toggle({ Title="Beat Game (Killer)", Desc="Teleports to nearest survivor", Value=Config.BEAT_Killer, Callback=function(v) Config.BEAT_Killer=v end })

-- ══════════════════════════════════════════════════
--  TAB 5 – MOVEMENT
-- ══════════════════════════════════════════════════
local TabMove = Window:Tab({ Title = "Move", Icon = "move" })

local SecSpeed = TabMove:Section({ Title = "Speed" })
SecSpeed:Toggle({ Title="Speed Hack", Value=Config.SPEED_Enabled, Callback=function(v) Config.SPEED_Enabled=v end })
SecSpeed:Slider({ Title="Speed Value", Value={Min=16,Max=150,Default=Config.SPEED_Value}, Step=2, Callback=function(v) Config.SPEED_Value=v end })
SecSpeed:Dropdown({ Title="Speed Method", Values={"Attribute","TP"}, Value=Config.SPEED_Method, Callback=function(v) Config.SPEED_Method=v end })
SecSpeed:Keybind({ Title="Speed Key", Value=tostring(Config.KEY_Speed):gsub("Enum.KeyCode.",""), Callback=function(v) pcall(function() Config.KEY_Speed=Enum.KeyCode[v] end) end })

local SecFly = TabMove:Section({ Title = "Flight" })
SecFly:Toggle({ Title="Fly", Value=Config.FLY_Enabled, Callback=function(v) Config.FLY_Enabled=v end })
SecFly:Slider({ Title="Fly Speed", Value={Min=10,Max=200,Default=Config.FLY_Speed}, Step=5, Callback=function(v) Config.FLY_Speed=v end })
SecFly:Dropdown({ Title="Fly Method", Values={"CFrame","Velocity"}, Value=Config.FLY_Method, Callback=function(v) Config.FLY_Method=v end })
SecFly:Keybind({ Title="Fly Key", Value=tostring(Config.KEY_Fly):gsub("Enum.KeyCode.",""), Callback=function(v) pcall(function() Config.KEY_Fly=Enum.KeyCode[v] end) end })

local SecJump = TabMove:Section({ Title = "Jump" })
SecJump:Slider({ Title="Jump Power", Value={Min=50,Max=200,Default=Config.JUMP_Power}, Step=5, Callback=function(v) Config.JUMP_Power=v; UpdateJumpPower() end })
SecJump:Toggle({ Title="Infinite Jump", Value=Config.JUMP_Infinite, Callback=function(v) Config.JUMP_Infinite=v end })

local SecCollision = TabMove:Section({ Title = "Collision" })
SecCollision:Toggle({ Title="Noclip", Value=Config.NOCLIP_Enabled, Callback=function(v) Config.NOCLIP_Enabled=v end })
SecCollision:Keybind({ Title="Noclip Key", Value=tostring(Config.KEY_Noclip):gsub("Enum.KeyCode.",""), Callback=function(v) pcall(function() Config.KEY_Noclip=Enum.KeyCode[v] end) end })

local SecTP = TabMove:Section({ Title = "Teleport" })
SecTP:Slider({ Title="TP Height Offset", Value={Min=0,Max=10,Default=Config.TP_Offset}, Step=1, Callback=function(v) Config.TP_Offset=v end })
SecTP:Button({ Title="TP to Nearest Gen", Callback=function() TeleportToGenerator(1); Notif("Teleport","Sent to generator",2) end })
SecTP:Button({ Title="TP to Gate", Callback=function() TeleportToGate(); Notif("Teleport","Sent to gate",2) end })
SecTP:Button({ Title="TP to Hook", Callback=function() TeleportToHook(); Notif("Teleport","Sent to hook",2) end })
SecTP:Keybind({ Title="Gen Key", Value=tostring(Config.KEY_TP_Gen):gsub("Enum.KeyCode.",""), Callback=function(v) pcall(function() Config.KEY_TP_Gen=Enum.KeyCode[v] end) end })
SecTP:Keybind({ Title="Gate Key", Value=tostring(Config.KEY_TP_Gate):gsub("Enum.KeyCode.",""), Callback=function(v) pcall(function() Config.KEY_TP_Gate=Enum.KeyCode[v] end) end })
SecTP:Keybind({ Title="Hook Key", Value=tostring(Config.KEY_TP_Hook):gsub("Enum.KeyCode.",""), Callback=function(v) pcall(function() Config.KEY_TP_Hook=Enum.KeyCode[v] end) end })

-- ══════════════════════════════════════════════════
--  TAB 6 – MISC
-- ══════════════════════════════════════════════════
local TabMisc = Window:Tab({ Title = "Misc", Icon = "settings" })

local SecVisual = TabMisc:Section({ Title = "Visual" })
SecVisual:Toggle({ Title="No Fog", Value=Config.NO_Fog, Callback=function(v) Config.NO_Fog=v; if not v then RestoreFog() end end })
SecVisual:Toggle({ Title="Custom FOV", Value=Config.CAM_FOVEnabled, Callback=function(v) Config.CAM_FOVEnabled=v end })
SecVisual:Slider({ Title="FOV Value", Value={Min=30,Max=120,Default=Config.CAM_FOV}, Step=5, Callback=function(v) Config.CAM_FOV=v end })

local SecFling = TabMisc:Section({ Title = "Fling" })
SecFling:Toggle({ Title="Enable Fling", Value=Config.FLING_Enabled, Callback=function(v) Config.FLING_Enabled=v end })
SecFling:Slider({ Title="Fling Strength", Value={Min=1000,Max=50000,Default=Config.FLING_Strength}, Step=1000, Callback=function(v) Config.FLING_Strength=v end })
SecFling:Button({ Title="Fling Nearest", Callback=function() FlingNearest(); Notif("Fling","Flinging nearest player",2) end })
SecFling:Button({ Title="Fling All", Callback=function() FlingAll(); Notif("Fling","Flinging all players",2) end })
SecFling:Toggle({ Title="Touch Fling", Desc="Walk into players to fling them", Value=Config.TOUCH_Fling, Callback=function(v) Config.TOUCH_Fling=v; if v then StartTouchFling(); Notif("Touch Fling","Enabled",2) else Notif("Touch Fling","Disabled",2) end end })

local SecMenu = TabMisc:Section({ Title = "Menu" })
SecMenu:Keybind({ Title="Toggle Menu Key", Value=tostring(Config.KEY_Menu):gsub("Enum.KeyCode.",""),
    Callback=function(v)
        pcall(function()
            Config.KEY_Menu=Enum.KeyCode[v]
            Window:SetToggleKey(Enum.KeyCode[v])
        end)
    end
})
SecMenu:Keybind({ Title="Panic Key (Unload)", Value=tostring(Config.KEY_Panic):gsub("Enum.KeyCode.",""),
    Callback=function(v) pcall(function() Config.KEY_Panic=Enum.KeyCode[v] end) end
})
SecMenu:Button({ Title="Unload Script", Desc="Removes all ESP and UI", Callback=function()
    Notif("Violence","Unloading script...",3)
    task.delay(0.5,function() if Unload then Unload() end end)
end })
SecMenu:Button({ Title="Rescan Map", Desc="Re-cache generators / hooks / etc", Callback=function()
    ScanMap(); Notif("Violence","Map rescanned!",2)
end })

-- Set toggle key from config
Window:SetToggleKey(Config.KEY_Menu)

-- ─── Keyboard shortcuts (non-WindUI keybinds) ────
Connections.Input = UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    local kc=input.KeyCode
    if kc==Config.KEY_TP_Gen  then TeleportToGenerator(1) end
    if kc==Config.KEY_TP_Gate then TeleportToGate() end
    if kc==Config.KEY_TP_Hook then TeleportToHook() end
    if kc==Config.KEY_LeaveGen then
        local root=GetCharacterRoot()
        if root then
            local nearestGen,nearestDist=nil,math.huge
            for _,gen in ipairs(Cache.Generators) do local d=GetDistance(gen.part.Position); if d<nearestDist then nearestDist=d;nearestGen=gen end end
            if nearestGen and nearestDist<Config.AUTO_LeaveDist then
                local dir=(root.Position-nearestGen.part.Position).Unit
                root.CFrame=CFrame.new(root.Position+dir*(Config.AUTO_LeaveDist+10)+Vector3.new(0,Config.TP_Offset,0))
            end
        end
    end
    if kc==Config.KEY_StopGen then Config.AUTO_Generator=false; Notif("Violence","Auto Gen stopped",2) end
    if kc==Config.KEY_Speed then Config.SPEED_Enabled=not Config.SPEED_Enabled end
    if kc==Config.KEY_Noclip then Config.NOCLIP_Enabled=not Config.NOCLIP_Enabled end
    if kc==Config.KEY_Fly then Config.FLY_Enabled=not Config.FLY_Enabled end
    if kc==Config.KEY_Panic then if Unload then Unload() end end
end)

Connections.InputEnd = UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton2 then
        if Config.AIM_UseRMB then State.AimHolding=false; State.AimTarget=nil end
    end
end)

Connections.InputChanged = UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton2 then
        if Config.AIM_Enabled and Config.AIM_UseRMB then State.AimHolding=true end
    end
end)

-- ─── Unload ──────────────────────────────────────
Unload = function()
    State.Unloaded=true
    for name,conn in pairs(Connections) do
        if conn then pcall(function() conn:Disconnect() end); Connections[name]=nil end
    end
    if InfiniteJumpConnection then InfiniteJumpConnection:Disconnect() end
    for _,esp in pairs(ESP.cache) do ESP.destroy(esp) end; ESP.cache={}
    for _,esp in pairs(ESP.objectCache) do ESP.destroyObject(esp) end; ESP.objectCache={}
    Chams.ClearAll()
    if AimFOVCircle then pcall(function() AimFOVCircle:Remove() end) end
    pcall(function() Radar.bg:Remove(); Radar.circleBg:Remove(); Radar.border:Remove(); Radar.circleBorder:Remove(); Radar.cross1:Remove(); Radar.cross2:Remove(); Radar.center:Remove() end)
    for _,d in pairs(Radar.dots) do if d then pcall(function() d:Remove() end) end end
    for _,d in pairs(Radar.objectDots) do if d then pcall(function() d:Remove() end) end end
    if Config.NO_Fog then RestoreFog() end
    pcall(function()
        local hum=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed=State.OriginalSpeed; hum.PlatformStand=false end
    end)
    pcall(function()
        if FlyBodyVelocity then FlyBodyVelocity:Destroy() end
        if FlyBodyGyro then FlyBodyGyro:Destroy() end
    end)
    pcall(function()
        local cam=workspace.CurrentCamera
        if cam and OriginalFOV then cam.FieldOfView=OriginalFOV end
        if cam and OriginalCameraType then cam.CameraType=OriginalCameraType end
    end)
    pcall(function()
        for player,orig in pairs(OriginalHitboxSizes) do
            if player.Character then
                local r=player.Character:FindFirstChild("HumanoidRootPart")
                if r then r.Size=orig; r.Transparency=1; r.CanCollide=true end
            end
        end
    end)
    -- Destroy WindUI
    pcall(function() WindUI:Destroy() end)
end

-- ─── Start loops ─────────────────────────────────
ScanMap()
pcall(SetupAntiBlind)
pcall(SetupNoPalletStun)
pcall(SetupInfiniteJump)
pcall(SetupSkillCheckMonitor)

-- RenderStepped: only smooth per-frame camera/fly stuff
Connections.Render = RunService.RenderStepped:Connect(MainLoop)
-- ESP runs in its own throttled thread — not every frame
task.spawn(ESPLoop)
task.spawn(AutoLoop)

-- Auto-gen background loop
task.spawn(function()
    local repairRemote,skillRemote
    local lastScan=0; local genPoints={}
    while not State.Unloaded do
        if Config.AUTO_Generator then
            if not repairRemote then
                local r=ReplicatedStorage:FindFirstChild("Remotes"); local g=r and r:FindFirstChild("Generator")
                repairRemote=g and g:FindFirstChild("RepairEvent"); skillRemote=g and g:FindFirstChild("SkillCheckResultEvent")
            end
            if tick()-lastScan>2 then
                genPoints={}
                local m=Workspace:FindFirstChild("Map")
                if m then
                    for _,v in ipairs(m:GetDescendants()) do
                        if v:IsA("Model") and v.Name=="Generator" then
                            for _,c in ipairs(v:GetChildren()) do
                                if c.Name:match("GeneratorPoint") then table.insert(genPoints,{gen=v,pt=c}) end
                            end
                        end
                    end
                end
                lastScan=tick()
            end
            if repairRemote and skillRemote then
                local mode=Config.AUTO_GenMode=="Fast"
                for _,data in ipairs(genPoints) do
                    pcall(repairRemote.FireServer,repairRemote,data.pt,true)
                    pcall(skillRemote.FireServer,skillRemote,mode and "success" or "neutral",mode and 1 or 0,data.gen,data.pt)
                end
            end
        end
        task.wait(0.15)
    end
end)

Connections.PlayerLeft=Players.PlayerRemoving:Connect(function(player)
    if ESP.cache[player] then ESP.hide(ESP.cache[player]); ESP.destroy(ESP.cache[player]); ESP.cache[player]=nil end
    if player.Character then Chams.Remove(player.Character) end
    Cache.Visibility[player]=nil; OriginalHitboxSizes[player]=nil
end)

Connections.PlayerAdded=Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function() task.wait(1); ScanMap() end)
end)

-- Welcome notification
task.delay(1, function()
    Notif("Violence Hub", "Loaded! Executor: "..ExecutorName, 5)
end)
