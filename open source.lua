--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]





if _G.ViolenceDistrictLoaded then
    warn("[Violence District] Script is already loaded. Unload first before re-running.")
    return
end
_G.ViolenceDistrictLoaded = true




local function detectMobilePlatform()
    local UserInputService = game:GetService("UserInputService")
    local hasTouchScreen = UserInputService.TouchEnabled
    local camera = workspace.CurrentCamera
    local viewportSize = camera and camera.ViewportSize or Vector2.new(0, 0)
    local isSmallScreen = viewportSize.X <= 1024 or viewportSize.Y <= 768
    local hasGyroscope = UserInputService.GyroscopeEnabled or UserInputService.AccelerometerEnabled
    local noKeyboard = not UserInputService.KeyboardEnabled

    local executorName = identifyexecutor and identifyexecutor() or "Unknown"
    local isMobileExecutor = executorName:lower():find("delta")
        or executorName:lower():find("arceus")
        or executorName:lower():find("fluxus")
        or executorName:lower():find("krnl")

    return hasTouchScreen and (noKeyboard or isSmallScreen or hasGyroscope or isMobileExecutor)
end

local isMobile = detectMobilePlatform()
local executorName = identifyexecutor and identifyexecutor() or "Unknown"

print("=== Violence District v2.3 Enhanced Edition ===")
print("Platform: " .. (isMobile and "Mobile" or "PC"))
print("Executor: " .. executorName)
print("================================================")




local function safeHttpGet(url)
    local methods = {}

    if game.HttpGet then
        table.insert(methods, function() return game:HttpGet(url) end)
    end
    if syn and syn.request then
        table.insert(methods, function() return syn.request({Url = url, Method = "GET"}).Body end)
    end
    if http and http.request then
        table.insert(methods, function() return http.request({Url = url, Method = "GET"}).Body end)
    end
    if http_request then
        table.insert(methods, function() return http_request({Url = url, Method = "GET"}).Body end)
    end
    if request then
        table.insert(methods, function() return request({Url = url, Method = "GET"}).Body end)
    end

    for _, method in ipairs(methods) do
        local success, result = pcall(method)
        if success and result and #result > 0 then
            return result
        end
    end

    error("Failed to load URL: " .. url)
end




local Rayfield
local loadSuccess = pcall(function()
    Rayfield = loadstring(safeHttpGet('https://sirius.menu/rayfield'))()
end)

if not loadSuccess then
    warn("Failed to load Rayfield from sirius.menu, trying backup...")
    pcall(function()
        Rayfield = loadstring(safeHttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()
    end)
    if not Rayfield then
        _G.ViolenceDistrictLoaded = nil
        error("CRITICAL: Could not load Rayfield UI Library.")
    end
end




local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer




local AllConnections = {}

local function trackConnection(connection)
    if connection then
        table.insert(AllConnections, connection)
    end
    return connection
end

local function disconnectAll()
    for _, conn in ipairs(AllConnections) do
        pcall(function()
            if conn and typeof(conn) == "RBXScriptConnection" and conn.Connected then
                conn:Disconnect()
            end
        end)
    end
    AllConnections = {}
end




local Config = {
    ESP = {
        Killer = false,
        Survivor = false,
        Generator = false,
        Gate = false,
        Hook = false,
        Pallet = false,
        Window = false,
        Pumpkin = false,
        ClosestHook = false,
        ShowOnlyClosestHook = false,
        ShowDistance = true,
        MaxDistance = 500,
    },
    AutoFeatures = {
        AutoGenerator = false,
        GeneratorMode = "great",
        AutoLeaveGenerator = false,
        LeaveDistance = 15,
        LeaveKeybind = Enum.KeyCode.Q,
        AutoAttack = false,
        AttackRange = 10,
    },
    Teleportation = {
        TeleportOffset = 3,
        SafeTeleport = true,
        TeleportDelay = 0.1,
    },
    Performance = {
        UpdateRate = 0.5,
        UseDistanceCulling = true,
        MaxESPObjects = isMobile and 50 or 100,
        DisableParticles = false,
        LowerGraphics = false,
        DisableShadows = false,
        ReduceRenderDistance = false,
    },
    Mobile = {
        TouchControlsEnabled = isMobile,
        ButtonSize = 80,
        ButtonTransparency = 0.3,
        AutoOptimize = true,
        AggressiveOptimization = false,
    },
}




local Highlights = {}
local BillboardGuis = {}
local LastUpdate = 0
local UpdateConnection = nil
local LeaveGeneratorConnection = nil
local AutoAttackConnection = nil
local MobileUI = nil
local FPSCounterEnabled = false
local FPSCounterUI = nil
local FPSHeartbeatConnection = nil
local ScriptRunning = true  
local TeleportDebounce = false




local function notify(title, content, duration)
    if not ScriptRunning then return end
    local success = pcall(function()
        Rayfield:Notify({
            Title = title,
            Content = content,
            Duration = duration or 3,
            Image = 4483362458,
        })
    end)
    if not success then
        warn(string.format("[%s] %s", title, content))
    end
end

local function safeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then return nil end
    return result
end

local function validateInstance(instance)
    return instance and typeof(instance) == "Instance" and instance.Parent ~= nil
end

local function isKiller()
    return LocalPlayer.Team and LocalPlayer.Team.Name == "Killer"
end

local function isSurvivor()
    return LocalPlayer.Team and LocalPlayer.Team.Name == "Survivors"
end

local function getCharacterRootPart()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function getMap()
    return Workspace:FindFirstChild("Map")
end

local function clampNumber(value, min, max)
    return math.max(min, math.min(max, value))
end




local function getAllGenerators()
    local generators = {}
    local map = getMap()
    if not map then return generators end

    for _, obj in ipairs(map:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Generator" then
            local genPart = obj:FindFirstChildWhichIsA("BasePart")
            if genPart then
                table.insert(generators, {
                    model = obj,
                    part = genPart,
                    position = genPart.Position,
                })
            end
        end
    end
    return generators
end

local function getGeneratorsByDistance()
    local hrp = getCharacterRootPart()
    if not hrp then return {} end

    local generators = getAllGenerators()
    for _, gen in ipairs(generators) do
        gen.distance = (gen.position - hrp.Position).Magnitude
    end
    table.sort(generators, function(a, b) return a.distance < b.distance end)
    return generators
end




local function safeTeleport(targetCFrame, offset)
    local hrp = getCharacterRootPart()
    if not hrp then
        notify("Error", "Character not found", 3)
        return false
    end

    offset = offset or Vector3.new(0, Config.Teleportation.TeleportOffset, 0)

    if Config.Teleportation.SafeTeleport then
        safeCall(function()
            for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    end

    hrp.CFrame = targetCFrame + offset

    if Config.Teleportation.SafeTeleport then
        task.delay(0.5, function()
            safeCall(function()
                if not LocalPlayer.Character then return end
                for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        part.CanCollide = true
                    end
                end
            end)
        end)
    end

    return true
end

local function debouncedTeleport(targetCFrame, offset)
    if TeleportDebounce then
        notify("Cooldown", "Please wait before teleporting again", 2)
        return false
    end
    TeleportDebounce = true
    local result = safeTeleport(targetCFrame, offset)
    task.delay(0.5, function() TeleportDebounce = false end)
    return result
end




local function isNearGenerator()
    local hrp = getCharacterRootPart()
    if not hrp then return false, nil, nil end

    local map = getMap()
    if not map then return false, nil, nil end

    local nearestGen = nil
    local nearestDist = math.huge

    for _, obj in ipairs(map:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Generator" then
            local genPart = obj:FindFirstChildWhichIsA("BasePart")
            if genPart then
                local distance = (genPart.Position - hrp.Position).Magnitude
                if distance < nearestDist then
                    nearestDist = distance
                    nearestGen = obj
                end
            end
        end
    end

    if nearestGen and nearestDist <= Config.AutoFeatures.LeaveDistance then
        return true, nearestGen, nearestDist
    end
    return false, nil, nil
end

local function leaveGenerator()
    local hrp = getCharacterRootPart()
    if not hrp then return false end

    local isNear, nearestGen, _ = isNearGenerator()
    if not isNear then
        notify("Not Near", "You're not near any generator", 2)
        return false
    end

    local genPart = nearestGen:FindFirstChildWhichIsA("BasePart")
    if genPart then
        local direction = (hrp.Position - genPart.Position).Unit
        local escapeDistance = Config.AutoFeatures.LeaveDistance + 15
        local escapePosition = hrp.Position + (direction * escapeDistance)
        local escapeCFrame = CFrame.new(escapePosition, escapePosition + hrp.CFrame.LookVector)

        if safeTeleport(escapeCFrame, Vector3.new(0, 2, 0)) then
            notify("Escaped!", string.format("Moved %.0f studs away", escapeDistance), 2)
            return true
        end
    end
    return false
end




local function applyMobileOptimizations()
    if not isMobile then return end
    local lighting = game:GetService("Lighting")

    safeCall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        lighting.GlobalShadows = false
        lighting.FogEnd = 100
        lighting.Brightness = 2

        for _, effect in ipairs(lighting:GetChildren()) do
            if effect:IsA("PostEffect") then
                effect.Enabled = false
            end
        end

        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam")
                or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
                obj.Enabled = false
            end
        end

        pcall(function()
            Workspace.StreamingEnabled = true
            Workspace.StreamingMinRadius = 32
            Workspace.StreamingTargetRadius = 64
        end)

        if Workspace:FindFirstChild("Terrain") then
            pcall(function() Workspace.Terrain.Decoration = false end)
        end
    end)
end

local function applyAggressiveMobileOptimizations()
    if not isMobile then return end
    applyMobileOptimizations()

    safeCall(function()
        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
        end)

        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Texture") or obj:IsA("Decal") then
                obj.Transparency = 1
            elseif obj:IsA("SurfaceAppearance") then
                pcall(function() obj.Parent = nil end)
            end
        end

        Config.Performance.UpdateRate = 1.0
        Config.Performance.MaxESPObjects = 25
    end)
end

local function applyPerformanceSettings()
    local lighting = game:GetService("Lighting")

    if Config.Performance.DisableParticles then
        safeCall(function()
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
                    obj.Enabled = false
                end
            end
        end)
    end

    if Config.Performance.LowerGraphics then
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
    end

    if Config.Performance.DisableShadows then
        safeCall(function()
            lighting.GlobalShadows = false
            lighting.FogEnd = 100
        end)
    end

    if Config.Performance.ReduceRenderDistance then
        pcall(function()
            Workspace.StreamingEnabled = true
            Workspace.StreamingMinRadius = 32
            Workspace.StreamingTargetRadius = 64
        end)
    end
end

local function resetPerformanceSettings()
    local lighting = game:GetService("Lighting")
    safeCall(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
                obj.Enabled = true
            elseif obj:IsA("Texture") or obj:IsA("Decal") then
                obj.Transparency = 0
            end
        end

        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic end)
        lighting.GlobalShadows = true
        lighting.FogEnd = 100000

        for _, effect in ipairs(lighting:GetChildren()) do
            if effect:IsA("PostEffect") then
                effect.Enabled = true
            end
        end
    end)
end




local function createHighlight(obj, color)
    if not validateInstance(obj) then return end
    if Highlights[obj] and validateInstance(Highlights[obj]) then return end

    
    if Highlights[obj] then
        Highlights[obj] = nil
    end

    
    local existingH = obj:FindFirstChild("H")
    if existingH then existingH:Destroy() end

    safeCall(function()
        local h = Instance.new("Highlight")
        h.Name = "H"
        h.Adornee = obj
        h.FillColor = color
        h.OutlineColor = color
        h.FillTransparency = 0.5
        h.OutlineTransparency = 0
        h.Parent = obj
        Highlights[obj] = h
    end)
end

local function removeHighlight(obj)
    if Highlights[obj] then
        safeCall(function()
            if validateInstance(Highlights[obj]) then
                Highlights[obj]:Destroy()
            end
        end)
        Highlights[obj] = nil
    end

    
    local existingH = obj:FindFirstChild("H")
    if existingH then
        pcall(function() existingH:Destroy() end)
    end
end

local function createLabel(obj, text, color)
    if not validateInstance(obj) then return end
    local playerRoot = getCharacterRootPart()
    if not playerRoot then return end

    local rootPart = obj:IsA("Model") and obj:FindFirstChildWhichIsA("BasePart")
        or (obj:IsA("BasePart") and obj or nil)
    if not rootPart then return end

    local distance = (playerRoot.Position - rootPart.Position).Magnitude

    
    if Config.Performance.UseDistanceCulling and distance > Config.ESP.MaxDistance then
        if BillboardGuis[obj] and validateInstance(BillboardGuis[obj]) then
            safeCall(function() BillboardGuis[obj]:Destroy() end)
            BillboardGuis[obj] = nil
        end
        return
    end

    
    if BillboardGuis[obj] and validateInstance(BillboardGuis[obj]) then
        local textLabel = BillboardGuis[obj]:FindFirstChild("TextLabel")
        if textLabel then
            textLabel.Text = Config.ESP.ShowDistance
                and string.format("%s\n%.0fm", text, distance)
                or text
        end
        return
    end

    
    BillboardGuis[obj] = nil

    safeCall(function()
        local billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.AlwaysOnTop = true
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.Adornee = rootPart
        billboard.Parent = obj

        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextColor3 = color
        textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        textLabel.TextStrokeTransparency = 0
        textLabel.Font = Enum.Font.GothamBold
        textLabel.TextScaled = true
        textLabel.Text = Config.ESP.ShowDistance
            and string.format("%s\n%.0fm", text, distance)
            or text
        textLabel.Parent = billboard

        BillboardGuis[obj] = billboard
    end)
end

local function removeLabel(obj)
    if BillboardGuis[obj] then
        safeCall(function()
            if validateInstance(BillboardGuis[obj]) then
                BillboardGuis[obj]:Destroy()
            end
        end)
        BillboardGuis[obj] = nil
    end
end

local function clearAllESP()
    for obj, _ in pairs(Highlights) do
        removeHighlight(obj)
    end
    for obj, _ in pairs(BillboardGuis) do
        removeLabel(obj)
    end
    Highlights = {}
    BillboardGuis = {}
end




local function updatePlayerESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Team then
            local teamName = player.Team.Name
            if teamName == "Killer" and Config.ESP.Killer then
                createHighlight(player.Character, Color3.fromRGB(255, 0, 0))
                createLabel(player.Character, player.Name .. "\n[KILLER]", Color3.fromRGB(255, 0, 0))
            elseif teamName == "Survivors" and Config.ESP.Survivor then
                createHighlight(player.Character, Color3.fromRGB(0, 255, 0))
                createLabel(player.Character, player.Name .. "\n[SURVIVOR]", Color3.fromRGB(0, 255, 0))
            else
                removeHighlight(player.Character)
                removeLabel(player.Character)
            end
        end
    end
end

local function updateGeneratorESP()
    if not Config.ESP.Generator then return end
    local map = getMap()
    if not map then return end

    for _, obj in ipairs(map:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Generator" then
            createHighlight(obj, Color3.fromRGB(203, 132, 66))
            createLabel(obj, "Generator", Color3.fromRGB(203, 132, 66))
        end
    end
end

local function updateGateESP()
    if not Config.ESP.Gate then return end
    local map = getMap()
    if not map then return end

    for _, obj in ipairs(map:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Gate" then
            createHighlight(obj, Color3.fromRGB(255, 255, 255))
            createLabel(obj, "Gate", Color3.fromRGB(255, 255, 255))
        end
    end
end

local function updateHookESP()
    if not Config.ESP.Hook then return end
    local map = getMap()
    if not map then return end

    if Config.ESP.ShowOnlyClosestHook then
        local hrp = getCharacterRootPart()
        if not hrp then return end

        local closestHook = nil
        local closestDist = math.huge

        for _, obj in ipairs(map:GetDescendants()) do
            if obj:IsA("Model") and obj.Name == "Hook" then
                local hookPart = obj:FindFirstChildWhichIsA("BasePart")
                if hookPart then
                    local dist = (hookPart.Position - hrp.Position).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closestHook = obj
                    end
                end
            end
        end

        
        for _, obj in ipairs(map:GetDescendants()) do
            if obj:IsA("Model") and obj.Name == "Hook" then
                removeHighlight(obj)
                removeLabel(obj)
                if obj:FindFirstChild("Model") then
                    for _, part in ipairs(obj.Model:GetDescendants()) do
                        if part:IsA("MeshPart") then removeHighlight(part) end
                    end
                end
            end
        end

        if closestHook then
            if closestHook:FindFirstChild("Model") then
                for _, part in ipairs(closestHook.Model:GetDescendants()) do
                    if part:IsA("MeshPart") then
                        createHighlight(part, Color3.fromRGB(255, 255, 0))
                    end
                end
            end
            createLabel(closestHook, "CLOSEST HOOK", Color3.fromRGB(255, 255, 0))
        end
    else
        for _, obj in ipairs(map:GetDescendants()) do
            if obj:IsA("Model") and obj.Name == "Hook" then
                if obj:FindFirstChild("Model") then
                    for _, part in ipairs(obj.Model:GetDescendants()) do
                        if part:IsA("MeshPart") then
                            createHighlight(part, Color3.fromRGB(255, 0, 0))
                        end
                    end
                end
                createLabel(obj, "Hook", Color3.fromRGB(255, 0, 0))
            end
        end
    end
end

local function updatePalletESP()
    if not Config.ESP.Pallet then return end
    local map = getMap()
    if not map then return end

    for _, obj in ipairs(map:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Palletwrong" then
            createHighlight(obj, Color3.fromRGB(255, 255, 0))
            createLabel(obj, "Pallet", Color3.fromRGB(255, 255, 0))
        end
    end
end

local function updateWindowESP()
    if not Config.ESP.Window then return end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Window" then
            createHighlight(obj, Color3.fromRGB(173, 216, 230))
            createLabel(obj, "Window", Color3.fromRGB(173, 216, 230))
        end
    end
end

local function updatePumpkinESP()
    if not Config.ESP.Pumpkin then return end
    local map = getMap()
    if not map then return end

    local pumpkins = map:FindFirstChild("Pumpkins")
    if not pumpkins then return end

    for _, obj in ipairs(pumpkins:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:find("Pumpkin") then
            createHighlight(obj, Color3.fromRGB(255, 140, 0))
            createLabel(obj, "Pumpkin", Color3.fromRGB(255, 140, 0))
        end
    end
end

local function updateAllESP()
    if not ScriptRunning then return end

    local currentTime = tick()
    if currentTime - LastUpdate < Config.Performance.UpdateRate then return end
    LastUpdate = currentTime

    
    local espCount = 0
    for obj, h in pairs(Highlights) do
        if not validateInstance(obj) or not validateInstance(h) then
            Highlights[obj] = nil
        else
            espCount = espCount + 1
        end
    end

    for obj, gui in pairs(BillboardGuis) do
        if not validateInstance(obj) or not validateInstance(gui) then
            BillboardGuis[obj] = nil
        end
    end

    if espCount >= Config.Performance.MaxESPObjects then return end

    safeCall(updatePlayerESP)
    safeCall(updateGeneratorESP)
    safeCall(updateGateESP)
    safeCall(updateHookESP)
    safeCall(updatePalletESP)
    safeCall(updateWindowESP)
    safeCall(updatePumpkinESP)
end

local function startESP()
    if UpdateConnection then return end
    UpdateConnection = trackConnection(RunService.Heartbeat:Connect(updateAllESP))
    notify("ESP Started", "All ESP features activated", 2)
end

local function stopESP()
    if UpdateConnection then
        UpdateConnection:Disconnect()
        UpdateConnection = nil
    end
    clearAllESP()
    notify("ESP Stopped", "All ESP disabled", 2)
end




local function startAutoLeaveGenerator()
    if LeaveGeneratorConnection then return end

    if not isMobile then
        LeaveGeneratorConnection = trackConnection(
            UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if gameProcessed then return end
                if input.KeyCode == Config.AutoFeatures.LeaveKeybind then
                    leaveGenerator()
                end
            end)
        )
        notify("Auto Leave Enabled", string.format("Press %s to leave generator", Config.AutoFeatures.LeaveKeybind.Name), 3)
    else
        notify("Mobile Mode", "Use the LEAVE button to escape generators", 3)
    end
end

local function stopAutoLeaveGenerator()
    if LeaveGeneratorConnection then
        LeaveGeneratorConnection:Disconnect()
        LeaveGeneratorConnection = nil
    end
    notify("Auto Leave Disabled", "Keybind disabled", 2)
end




local function findClosestSurvivor()
    if not isKiller() then return nil, nil end
    local hrp = getCharacterRootPart()
    if not hrp then return nil, nil end

    local closestPlayer = nil
    local closestDist = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Team and player.Team.Name == "Survivors" and player.Character then
            local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP then
                local dist = (targetHRP.Position - hrp.Position).Magnitude
                if dist < closestDist and dist <= Config.AutoFeatures.AttackRange then
                    closestDist = dist
                    closestPlayer = player
                end
            end
        end
    end
    return closestPlayer, closestDist
end

local function performAutoAttack()
    if not isKiller() then return end
    local target, _ = findClosestSurvivor()
    if not target then return end

    safeCall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if not remotes then return end
        local attacks = remotes:FindFirstChild("Attacks")
        if not attacks then return end
        local basicAttack = attacks:FindFirstChild("BasicAttack")
        if basicAttack then
            basicAttack:FireServer(false)
        end
    end)
end

local lastAttackTime = 0
local ATTACK_COOLDOWN = 0.3 

local function startAutoAttack()
    if AutoAttackConnection then return end
    if not isKiller() then
        notify("Error", "You must be the Killer to use Auto Attack!", 3)
        return
    end

    AutoAttackConnection = trackConnection(
        RunService.Heartbeat:Connect(function()
            if not ScriptRunning then return end
            if not Config.AutoFeatures.AutoAttack then return end

            local now = tick()
            if now - lastAttackTime < ATTACK_COOLDOWN then return end
            lastAttackTime = now

            performAutoAttack()
        end)
    )
    notify("Auto Attack Enabled", string.format("Range: %d studs", Config.AutoFeatures.AttackRange), 3)
end

local function stopAutoAttack()
    if AutoAttackConnection then
        AutoAttackConnection:Disconnect()
        AutoAttackConnection = nil
    end
    notify("Auto Attack Disabled", "Auto attack stopped", 2)
end




local function createMobileControls()
    if not isMobile then return end
    if MobileUI then return end 

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MobileControls"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local leaveButton = Instance.new("TextButton")
    leaveButton.Name = "LeaveGenerator"
    leaveButton.Size = UDim2.new(0, Config.Mobile.ButtonSize, 0, Config.Mobile.ButtonSize)
    leaveButton.Position = UDim2.new(1, -100, 0.5, -40)
    leaveButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    leaveButton.BackgroundTransparency = Config.Mobile.ButtonTransparency
    leaveButton.Text = "LEAVE"
    leaveButton.TextColor3 = Color3.new(1, 1, 1)
    leaveButton.TextScaled = true
    leaveButton.Font = Enum.Font.GothamBold
    leaveButton.Parent = screenGui

    Instance.new("UICorner", leaveButton).CornerRadius = UDim.new(0, 10)

    leaveButton.MouseButton1Click:Connect(function()
        leaveGenerator()
    end)

    local tpButton = Instance.new("TextButton")
    tpButton.Name = "TeleportGen"
    tpButton.Size = UDim2.new(0, Config.Mobile.ButtonSize, 0, Config.Mobile.ButtonSize)
    tpButton.Position = UDim2.new(1, -100, 0.5, 60)
    tpButton.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    tpButton.BackgroundTransparency = Config.Mobile.ButtonTransparency
    tpButton.Text = "TP GEN"
    tpButton.TextColor3 = Color3.new(1, 1, 1)
    tpButton.TextScaled = true
    tpButton.Font = Enum.Font.GothamBold
    tpButton.Parent = screenGui

    Instance.new("UICorner", tpButton).CornerRadius = UDim.new(0, 10)

    tpButton.MouseButton1Click:Connect(function()
        local generators = getGeneratorsByDistance()
        if #generators > 0 then
            debouncedTeleport(generators[1].part.CFrame)
            notify("Teleported!", "Moved to closest generator", 2)
        end
    end)

    local success = pcall(function()
        screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end)

    if success then
        notify("Mobile Controls", "Touch controls enabled!", 3)
        MobileUI = screenGui
    else
        screenGui:Destroy()
    end
end




local function createFPSCounter()
    if FPSCounterUI then return end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FPSCounter"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local frame = Instance.new("Frame")
    frame.Name = "FPSFrame"
    frame.Size = UDim2.new(0, 120, 0, 50)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local fpsLabel = Instance.new("TextLabel")
    fpsLabel.Name = "FPSLabel"
    fpsLabel.Size = UDim2.new(1, 0, 1, 0)
    fpsLabel.BackgroundTransparency = 1
    fpsLabel.Text = "FPS: 0"
    fpsLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    fpsLabel.TextStrokeTransparency = 0
    fpsLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    fpsLabel.Font = Enum.Font.GothamBold
    fpsLabel.TextSize = 18
    fpsLabel.Parent = frame

    
    local dragging = false
    local dragInput, mousePos, framePos

    trackConnection(frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            mousePos = input.Position
            framePos = frame.Position
            trackConnection(input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end))
        end
    end))

    trackConnection(frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end))

    trackConnection(UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            frame.Position = UDim2.new(
                framePos.X.Scale, framePos.X.Offset + delta.X,
                framePos.Y.Scale, framePos.Y.Offset + delta.Y
            )
        end
    end))

    
    local lastTime = tick()
    local frameCount = 0

    FPSHeartbeatConnection = trackConnection(RunService.Heartbeat:Connect(function()
        if not FPSCounterEnabled then return end

        frameCount = frameCount + 1
        local currentTime = tick()
        local deltaTime = currentTime - lastTime

        if deltaTime >= 1.0 then
            local fps = math.floor(frameCount / deltaTime)
            frameCount = 0
            lastTime = currentTime

            if fps >= 60 then
                fpsLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
            elseif fps >= 30 then
                fpsLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
            else
                fpsLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
            end
            fpsLabel.Text = string.format("FPS: %d", fps)
        end
    end))

    local success = pcall(function()
        screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end)

    if success then
        FPSCounterUI = screenGui
        FPSCounterEnabled = true
        notify("FPS Counter", "Enabled - Drag to move!", 3)
    else
        screenGui:Destroy()
    end
end

local function removeFPSCounter()
    FPSCounterEnabled = false
    if FPSHeartbeatConnection then
        FPSHeartbeatConnection:Disconnect()
        FPSHeartbeatConnection = nil
    end
    if FPSCounterUI then
        FPSCounterUI:Destroy()
        FPSCounterUI = nil
    end
end




local function unloadScript()
    ScriptRunning = false
    _G.ViolenceDistrictLoaded = nil

    stopESP()
    clearAllESP()
    stopAutoLeaveGenerator()
    stopAutoAttack()
    resetPerformanceSettings()
    removeFPSCounter()

    if MobileUI then
        MobileUI:Destroy()
        MobileUI = nil
    end

    disconnectAll()

    pcall(function() Rayfield:Destroy() end)
    notify("Unloaded", "Script unloaded completely", 2)
end




local Window = Rayfield:CreateWindow({
    Name = "🎮 Golds Easy Hub - Violence District v2.3",
    LoadingTitle = "Loading Enhanced Script",
    LoadingSubtitle = "by goldgoldgoldblazn | " .. (isMobile and "Mobile Mode" or "PC Mode"),
    ConfigurationSaving = {
        Enabled = true,
        FolderName = nil,
        FileName = "ViolenceDistrictConfig",
    },
    Discord = {
        Enabled = false,
        Invite = "CnNqEVFxh6",
        RememberJoins = false,
    },
    KeySystem = false,
})




local CreditsTab = Window:CreateTab("ℹ️ Credits & Info", 4483362458)

CreditsTab:CreateSection("👤 Main Developer")
CreditsTab:CreateLabel("Created by: goldgoldgoldblazn")
CreditsTab:CreateLabel("Version: 2.3 (Enhanced Edition)")
CreditsTab:CreateLabel("")
CreditsTab:CreateLabel("🌟 Thank you for using my script!")

CreditsTab:CreateSection("💬 Discord Community")
CreditsTab:CreateLabel("Join for updates, support & more!")
CreditsTab:CreateLabel("Discord: discord.gg/CnNqEVFxh6")

CreditsTab:CreateButton({
    Name = "📋 Copy Discord Invite Link",
    Callback = function()
        local inviteLink = "https://discord.gg/CnNqEVFxh6"
        local success = pcall(function() setclipboard(inviteLink) end)
        if success then
            notify("Discord Link Copied!", "discord.gg/CnNqEVFxh6 copied to clipboard!", 4)
        else
            notify("Discord Server", "discord.gg/CnNqEVFxh6 - Copy this manually!", 5)
        end
    end,
})

if isMobile then
    CreditsTab:CreateLabel("")
    CreditsTab:CreateLabel("📱 Mobile Tip: Link copied!")
    CreditsTab:CreateLabel("Paste in Discord app or browser")
end

CreditsTab:CreateSection("📊 Script Information")
CreditsTab:CreateLabel("Game: Violence District")
CreditsTab:CreateLabel("Platform: " .. (isMobile and "📱 Mobile" or "💻 PC"))
CreditsTab:CreateLabel("Executor: " .. executorName)
CreditsTab:CreateLabel("UI Library: Rayfield by Sirius")

CreditsTab:CreateSection("✨ What's New in v2.3")

CreditsTab:CreateParagraph({
    Title = "v2.3 Enhanced Edition",
    Content = "✅ Fixed duplicate tab creation bugs\n✅ Fixed memory leaks & orphaned ESP\n✅ Fixed unload not stopping loops\n✅ Added teleport debounce\n✅ Added connection tracking\n✅ Added double-init guard\n✅ Improved error resilience\n✅ Attack cooldown to prevent spam",
})

CreditsTab:CreateParagraph({
    Title = "All Features",
    Content = "• Player & Object ESP\n• Auto-Complete Generators\n• Smart Auto Attack (Killer)\n• Quick Leave Generator\n• Advanced Teleportation\n• Performance Boost (Mobile)\n• Killer Powers\n• Touch Controls",
})




local ESPTab = Window:CreateTab("👁️ ESP", 4483362458)
ESPTab:CreateSection("Player ESP")

ESPTab:CreateToggle({
    Name = "Killer ESP (Red)",
    CurrentValue = false,
    Flag = "KillerESP",
    Callback = function(Value)
        Config.ESP.Killer = Value
        if Value then
            startESP()
        else
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character and player.Team and player.Team.Name == "Killer" then
                    removeHighlight(player.Character)
                    removeLabel(player.Character)
                end
            end
        end
    end,
})

ESPTab:CreateToggle({
    Name = "Survivor ESP (Green)",
    CurrentValue = false,
    Flag = "SurvivorESP",
    Callback = function(Value)
        Config.ESP.Survivor = Value
        if Value then
            startESP()
        else
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character and player.Team and player.Team.Name == "Survivors" then
                    removeHighlight(player.Character)
                    removeLabel(player.Character)
                end
            end
        end
    end,
})

ESPTab:CreateSection("Object ESP")

ESPTab:CreateToggle({
    Name = "Generator ESP (Orange)",
    CurrentValue = false,
    Flag = "GeneratorESP",
    Callback = function(Value)
        Config.ESP.Generator = Value
        if Value then
            startESP()
        else
            local map = getMap()
            if map then
                for _, obj in ipairs(map:GetDescendants()) do
                    if obj:IsA("Model") and obj.Name == "Generator" then
                        removeHighlight(obj)
                        removeLabel(obj)
                    end
                end
            end
        end
    end,
})

ESPTab:CreateToggle({
    Name = "Gate ESP (White)",
    CurrentValue = false,
    Flag = "GateESP",
    Callback = function(Value)
        Config.ESP.Gate = Value
        if Value then startESP() end
    end,
})

ESPTab:CreateToggle({
    Name = "Hook ESP (Red)",
    CurrentValue = false,
    Flag = "HookESP",
    Callback = function(Value)
        Config.ESP.Hook = Value
        if Value then
            startESP()
        else
            local map = getMap()
            if map then
                for _, obj in ipairs(map:GetDescendants()) do
                    if obj:IsA("Model") and obj.Name == "Hook" then
                        removeHighlight(obj)
                        removeLabel(obj)
                        if obj:FindFirstChild("Model") then
                            for _, part in ipairs(obj.Model:GetDescendants()) do
                                if part:IsA("MeshPart") then removeHighlight(part) end
                            end
                        end
                    end
                end
            end
        end
    end,
})

ESPTab:CreateToggle({
    Name = "Show Only Closest Hook",
    CurrentValue = false,
    Flag = "ShowOnlyClosestHook",
    Callback = function(Value)
        Config.ESP.ShowOnlyClosestHook = Value
        local map = getMap()
        if map then
            for _, obj in ipairs(map:GetDescendants()) do
                if obj:IsA("Model") and obj.Name == "Hook" then
                    removeHighlight(obj)
                    removeLabel(obj)
                end
            end
        end
        if Config.ESP.Hook then updateHookESP() end
        notify("Hook ESP", Value and "Showing only closest hook" or "Showing all hooks", 2)
    end,
})

ESPTab:CreateToggle({
    Name = "Pallet ESP (Yellow)",
    CurrentValue = false,
    Flag = "PalletESP",
    Callback = function(Value)
        Config.ESP.Pallet = Value
        if Value then startESP() end
    end,
})

ESPTab:CreateToggle({
    Name = "Window ESP (Light Blue)",
    CurrentValue = false,
    Flag = "WindowESP",
    Callback = function(Value)
        Config.ESP.Window = Value
        if Value then startESP() end
    end,
})

ESPTab:CreateToggle({
    Name = "Pumpkin ESP (Orange)",
    CurrentValue = false,
    Flag = "PumpkinESP",
    Callback = function(Value)
        Config.ESP.Pumpkin = Value
        if Value then startESP() end
    end,
})

ESPTab:CreateSection("Settings")

ESPTab:CreateToggle({
    Name = "Show Distance",
    CurrentValue = true,
    Flag = "ShowDistance",
    Callback = function(Value) Config.ESP.ShowDistance = Value end,
})

ESPTab:CreateSlider({
    Name = "Max Distance",
    Range = {100, 1000},
    Increment = 50,
    CurrentValue = 500,
    Flag = "MaxDistance",
    Callback = function(Value) Config.ESP.MaxDistance = Value end,
})

ESPTab:CreateSlider({
    Name = "Update Rate (seconds)",
    Range = {0.1, 2},
    Increment = 0.1,
    CurrentValue = 0.5,
    Flag = "UpdateRate",
    Callback = function(Value) Config.Performance.UpdateRate = Value end,
})

ESPTab:CreateSlider({
    Name = "Max ESP Objects",
    Range = {25, 500},
    Increment = 25,
    CurrentValue = isMobile and 50 or 100,
    Flag = "MaxESPObjects",
    Callback = function(Value) Config.Performance.MaxESPObjects = Value end,
})




local GameplayTab = Window:CreateTab("🎮 Gameplay", 4483362458)
GameplayTab:CreateSection("Auto Features")

GameplayTab:CreateToggle({
    Name = "Auto Complete Generators",
    CurrentValue = false,
    Flag = "AutoGenerator",
    Callback = function(Value)
        Config.AutoFeatures.AutoGenerator = Value
        notify("Auto Generator", Value and "Enabled - Generators will auto-complete" or "Disabled", Value and 3 or 2)
    end,
})

GameplayTab:CreateDropdown({
    Name = "Generator Mode",
    Options = {"Great (Fast)", "Normal (Slow)"},
    CurrentOption = "Great (Fast)",
    Flag = "GeneratorMode",
    Callback = function(Option)
        Config.AutoFeatures.GeneratorMode = (Option == "Great (Fast)") and "great" or "normal"
    end,
})

GameplayTab:CreateSection("Quick Escape")

GameplayTab:CreateToggle({
    Name = "Enable Quick Leave Generator",
    CurrentValue = false,
    Flag = "AutoLeaveGenerator",
    Callback = function(Value)
        Config.AutoFeatures.AutoLeaveGenerator = Value
        if Value then startAutoLeaveGenerator() else stopAutoLeaveGenerator() end
    end,
})

if not isMobile then
    GameplayTab:CreateDropdown({
        Name = "Leave Generator Keybind",
        Options = {"Q", "E", "F", "G", "X", "Z", "V", "B"},
        CurrentOption = "Q",
        Flag = "LeaveKeybind",
        Callback = function(Option)
            local keyMap = {
                Q = Enum.KeyCode.Q, E = Enum.KeyCode.E,
                F = Enum.KeyCode.F, G = Enum.KeyCode.G,
                X = Enum.KeyCode.X, Z = Enum.KeyCode.Z,
                V = Enum.KeyCode.V, B = Enum.KeyCode.B,
            }
            Config.AutoFeatures.LeaveKeybind = keyMap[Option]
            if Config.AutoFeatures.AutoLeaveGenerator then
                stopAutoLeaveGenerator()
                startAutoLeaveGenerator()
            end
            notify("Keybind Changed", "Leave generator key set to: " .. Option, 2)
        end,
    })
end

GameplayTab:CreateSlider({
    Name = "Detection Range (studs)",
    Range = {5, 30},
    Increment = 1,
    CurrentValue = 15,
    Flag = "LeaveDistance",
    Callback = function(Value) Config.AutoFeatures.LeaveDistance = Value end,
})

GameplayTab:CreateButton({
    Name = "Leave Generator Now",
    Callback = function() leaveGenerator() end,
})

GameplayTab:CreateSection("Manual Actions")

GameplayTab:CreateButton({
    Name = "Complete All Generators (Instant)",
    Callback = function()
        local map = getMap()
        if not map then
            notify("Error", "Map not found", 3)
            return
        end

        local completed = 0
        safeCall(function()
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            if not remotes then return end
            local genRemotes = remotes:FindFirstChild("Generator")
            if not genRemotes then return end
            local repairEvent = genRemotes:FindFirstChild("RepairEvent")
            local skillCheckEvent = genRemotes:FindFirstChild("SkillCheckResultEvent")
            if not repairEvent or not skillCheckEvent then return end

            for _, obj in ipairs(map:GetDescendants()) do
                if obj:IsA("Model") and obj.Name == "Generator" then
                    for _, point in ipairs(obj:GetChildren()) do
                        if point.Name:find("GeneratorPoint") then
                            pcall(function()
                                for i = 1, 10 do
                                    repairEvent:FireServer(point, true)
                                    skillCheckEvent:FireServer("success", 1, obj, point)
                                end
                                completed = completed + 1
                            end)
                        end
                    end
                end
            end
        end)

        notify(completed > 0 and "Complete!" or "Failed",
            completed > 0 and string.format("Completed %d generator(s)", completed) or "Could not find generators",
            completed > 0 and 4 or 3)
    end,
})

GameplayTab:CreateSection("Killer Powers")

GameplayTab:CreateToggle({
    Name = "Auto Attack Nearby Survivors",
    CurrentValue = false,
    Flag = "AutoAttack",
    Callback = function(Value)
        Config.AutoFeatures.AutoAttack = Value
        if Value then startAutoAttack() else stopAutoAttack() end
    end,
})

GameplayTab:CreateSlider({
    Name = "Auto Attack Range (studs)",
    Range = {5, 20},
    Increment = 1,
    CurrentValue = 10,
    Flag = "AttackRange",
    Callback = function(Value) Config.AutoFeatures.AttackRange = Value end,
})

GameplayTab:CreateButton({
    Name = "Activate Killer Power",
    Callback = function()
        safeCall(function()
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            if not remotes then return end
            local killerRemotes = remotes:FindFirstChild("Killers")
            if not killerRemotes then return end
            local killerFolder = killerRemotes:FindFirstChild("Killer")
            if not killerFolder then return end
            local activatePower = killerFolder:FindFirstChild("ActivatePower")
            if activatePower then
                activatePower:FireServer()
                notify("Power Activated", "Killer power triggered", 2)
            end
        end)
    end,
})

GameplayTab:CreateButton({
    Name = "Basic Attack (Killer)",
    Callback = function()
        safeCall(function()
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            if not remotes then return end
            local attacks = remotes:FindFirstChild("Attacks")
            if not attacks then return end
            local basicAttack = attacks:FindFirstChild("BasicAttack")
            if basicAttack then
                basicAttack:FireServer(false)
                notify("Attack", "Basic attack executed", 2)
            end
        end)
    end,
})




local TeleportTab = Window:CreateTab("🚀 Teleport", 4483362458)
TeleportTab:CreateSection("Generator Teleportation")

TeleportTab:CreateButton({
    Name = "Teleport to Closest Generator",
    Callback = function()
        local generators = getGeneratorsByDistance()
        if #generators == 0 then
            notify("Not Found", "No generators found on the map", 3)
            return
        end
        local closest = generators[1]
        if debouncedTeleport(closest.part.CFrame) then
            notify("Teleported!", string.format("Teleported to closest generator (%.0fm)", closest.distance), 3)
        end
    end,
})

TeleportTab:CreateButton({
    Name = "Teleport to Farthest Generator",
    Callback = function()
        local generators = getGeneratorsByDistance()
        if #generators == 0 then
            notify("Not Found", "No generators found on the map", 3)
            return
        end
        local farthest = generators[#generators]
        if debouncedTeleport(farthest.part.CFrame) then
            notify("Teleported!", string.format("Teleported to farthest generator (%.0fm)", farthest.distance), 3)
        end
    end,
})

TeleportTab:CreateButton({
    Name = "Teleport Through All Generators",
    Callback = function()
        local generators = getGeneratorsByDistance()
        if #generators == 0 then
            notify("Not Found", "No generators found on the map", 3)
            return
        end

        notify("Starting", string.format("Teleporting through %d generators...", #generators), 3)

        task.spawn(function()
            for i, gen in ipairs(generators) do
                if not ScriptRunning or not getCharacterRootPart() then break end
                safeTeleport(gen.part.CFrame)
                notify("Generator " .. i, string.format("At generator %d/%d (%.0fm)", i, #generators, gen.distance), 2)
                task.wait(Config.Teleportation.TeleportDelay)
            end
            notify("Complete!", "Visited all generators", 3)
        end)
    end,
})

TeleportTab:CreateButton({
    Name = "Show Generator List (Console)",
    Callback = function()
        local generators = getGeneratorsByDistance()
        if #generators == 0 then
            notify("Not Found", "No generators found", 3)
            return
        end

        print("\n=== GENERATOR LIST ===")
        for i, gen in ipairs(generators) do
            print(string.format("%d. Generator at %.0fm - Position: %s", i, gen.distance, tostring(gen.position)))
        end
        print("======================\n")
        notify("List Printed", string.format("Found %d generators - Check console (F9)", #generators), 3)
    end,
})

TeleportTab:CreateSection("Other Teleports")

TeleportTab:CreateButton({
    Name = "Teleport to Nearest Gate",
    Callback = function()
        local hrp = getCharacterRootPart()
        if not hrp then
            notify("Error", "Character not found", 3)
            return
        end

        local map = getMap()
        if not map then
            notify("Error", "Map not found", 3)
            return
        end

        local nearestGate = nil
        local nearestDist = math.huge

        for _, obj in ipairs(map:GetDescendants()) do
            if obj:IsA("Model") and obj.Name == "Gate" then
                local gatePart = obj:FindFirstChildWhichIsA("BasePart")
                if gatePart then
                    local dist = (gatePart.Position - hrp.Position).Magnitude
                    if dist < nearestDist then
                        nearestGate = gatePart
                        nearestDist = dist
                    end
                end
            end
        end

        if nearestGate then
            debouncedTeleport(nearestGate.CFrame)
            notify("Teleported", string.format("Teleported to gate (%.0fm)", nearestDist), 3)
        else
            notify("Not Found", "No gates found", 3)
        end
    end,
})

TeleportTab:CreateSection("Survivor Win")

TeleportTab:CreateButton({
    Name = "Escape Game (Survivor Only)",
    Callback = function()
        if not isSurvivor() then
            notify("Error", "You must be a Survivor to use this!", 3)
            return
        end

        local hrp = getCharacterRootPart()
        if not hrp then
            notify("Error", "Character not found", 3)
            return
        end

        local map = getMap()
        if not map then
            notify("Error", "Map not found", 3)
            return
        end

        local gate = nil
        for _, obj in ipairs(map:GetDescendants()) do
            if obj:IsA("Model") and obj.Name == "Gate" then
                gate = obj
                break
            end
        end

        if not gate then
            notify("Error", "No gates found on map", 3)
            return
        end

        local escapeZone = gate:FindFirstChild("Escape") or gate:FindFirstChildWhichIsA("BasePart")

        if escapeZone then
            debouncedTeleport(escapeZone.CFrame, Vector3.new(0, 5, 0))
            task.wait(0.5)

            safeCall(function()
                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                if not remotes then return end
                local gateRemote = remotes:FindFirstChild("Gate")
                if not gateRemote then return end
                local escapeEvent = gateRemote:FindFirstChild("Escape")
                if escapeEvent then escapeEvent:FireServer() end
            end)

            notify("Escape!", "Teleported to exit gate - Walk through to escape!", 4)
        else
            notify("Error", "Could not find escape zone", 3)
        end
    end,
})

TeleportTab:CreateSection("Teleport Settings")

TeleportTab:CreateSlider({
    Name = "Teleport Height Offset",
    Range = {0, 10},
    Increment = 1,
    CurrentValue = 3,
    Flag = "TeleportOffset",
    Callback = function(Value) Config.Teleportation.TeleportOffset = Value end,
})

TeleportTab:CreateSlider({
    Name = "Multi-Teleport Delay (seconds)",
    Range = {0.1, 5},
    Increment = 0.1,
    CurrentValue = 0.1,
    Flag = "TeleportDelay",
    Callback = function(Value) Config.Teleportation.TeleportDelay = Value end,
})

TeleportTab:CreateToggle({
    Name = "Safe Teleport (Disable Collision)",
    CurrentValue = true,
    Flag = "SafeTeleport",
    Callback = function(Value) Config.Teleportation.SafeTeleport = Value end,
})


local SettingsTab = Window:CreateTab("⚙️ Settings", 4483362458)
SettingsTab:CreateSection("Performance Options")

SettingsTab:CreateToggle({
    Name = "Disable Particles & Effects",
    CurrentValue = false,
    Flag = "DisableParticles",
    Callback = function(Value)
        Config.Performance.DisableParticles = Value
        applyPerformanceSettings()
        notify("Performance", Value and "Particles disabled" or "Particles enabled", 2)
    end,
})

SettingsTab:CreateToggle({
    Name = "Lower Graphics Quality",
    CurrentValue = false,
    Flag = "LowerGraphics",
    Callback = function(Value)
        Config.Performance.LowerGraphics = Value
        applyPerformanceSettings()
        notify("Performance", Value and "Graphics lowered" or "Graphics reset", 2)
    end,
})

SettingsTab:CreateToggle({
    Name = "Disable Shadows",
    CurrentValue = false,
    Flag = "DisableShadows",
    Callback = function(Value)
        Config.Performance.DisableShadows = Value
        applyPerformanceSettings()
        notify("Performance", Value and "Shadows disabled" or "Shadows enabled", 2)
    end,
})

SettingsTab:CreateToggle({
    Name = "Reduce Render Distance",
    CurrentValue = false,
    Flag = "ReduceRenderDistance",
    Callback = function(Value)
        Config.Performance.ReduceRenderDistance = Value
        applyPerformanceSettings()
        notify("Performance", Value and "Render distance reduced" or "Render distance normal", 2)
    end,
})

SettingsTab:CreateToggle({
    Name = "Use Distance Culling (ESP)",
    CurrentValue = true,
    Flag = "UseDistanceCulling",
    Callback = function(Value)
        Config.Performance.UseDistanceCulling = Value
        notify("Performance", Value and "Distance culling enabled" or "Distance culling disabled", 2)
    end,
})

SettingsTab:CreateButton({
    Name = "Apply All Performance Boosts",
    Callback = function()
        Config.Performance.DisableParticles = true
        Config.Performance.LowerGraphics = true
        Config.Performance.DisableShadows = true
        Config.Performance.ReduceRenderDistance = true
        Config.Performance.UseDistanceCulling = true
        applyPerformanceSettings()
        notify("Performance", "All performance boosts applied!", 3)
    end,
})

SettingsTab:CreateButton({
    Name = "Reset Performance Settings",
    Callback = function()
        Config.Performance.DisableParticles = false
        Config.Performance.LowerGraphics = false
        Config.Performance.DisableShadows = false
        Config.Performance.ReduceRenderDistance = false
        resetPerformanceSettings()
        notify("Performance", "Settings reset to default", 2)
    end,
})


if isMobile then
    SettingsTab:CreateSection("Mobile Controls")

    SettingsTab:CreateToggle({
        Name = "Enable Touch Controls",
        CurrentValue = true,
        Flag = "TouchControls",
        Callback = function(Value)
            Config.Mobile.TouchControlsEnabled = Value
            if Value and not MobileUI then
                createMobileControls()
            elseif not Value and MobileUI then
                MobileUI:Destroy()
                MobileUI = nil
            end
        end,
    })

    SettingsTab:CreateSlider({
        Name = "Button Size",
        Range = {60, 120},
        Increment = 10,
        CurrentValue = 80,
        Flag = "ButtonSize",
        Callback = function(Value)
            Config.Mobile.ButtonSize = Value
            if MobileUI then
                MobileUI:Destroy()
                MobileUI = nil
                createMobileControls()
            end
        end,
    })

    SettingsTab:CreateSlider({
        Name = "Button Transparency",
        Range = {0, 0.8},
        Increment = 0.1,
        CurrentValue = 0.3,
        Flag = "ButtonTransparency",
        Callback = function(Value)
            Config.Mobile.ButtonTransparency = Value
            if MobileUI then
                for _, button in ipairs(MobileUI:GetChildren()) do
                    if button:IsA("TextButton") then
                        button.BackgroundTransparency = Value
                    end
                end
            end
        end,
    })

    SettingsTab:CreateSection("📱 Mobile Performance Boost")

    SettingsTab:CreateToggle({
        Name = "Auto Mobile Optimization",
        CurrentValue = true,
        Flag = "AutoOptimize",
        Callback = function(Value)
            Config.Mobile.AutoOptimize = Value
            if Value then
                applyMobileOptimizations()
                notify("Mobile Optimization", "Basic optimizations applied!", 3)
            else
                resetPerformanceSettings()
                notify("Mobile Optimization", "Optimizations reset", 2)
            end
        end,
    })

    SettingsTab:CreateToggle({
        Name = "🔥 ULTRA Performance Mode (Aggressive)",
        CurrentValue = false,
        Flag = "AggressiveOptimization",
        Callback = function(Value)
            Config.Mobile.AggressiveOptimization = Value
            if Value then
                applyAggressiveMobileOptimizations()
                notify("ULTRA MODE", "Maximum FPS boost! (Lower graphics)", 4)
            else
                resetPerformanceSettings()
                if Config.Mobile.AutoOptimize then applyMobileOptimizations() end
                notify("ULTRA MODE", "Disabled - Graphics restored", 2)
            end
        end,
    })

    SettingsTab:CreateButton({
        Name = "🚀 Apply All Mobile Optimizations NOW",
        Callback = function()
            Config.Performance.DisableParticles = true
            Config.Performance.LowerGraphics = true
            Config.Performance.DisableShadows = true
            Config.Performance.ReduceRenderDistance = true
            Config.Performance.UseDistanceCulling = true
            Config.Performance.UpdateRate = 1.0
            Config.Performance.MaxESPObjects = 25
            applyAggressiveMobileOptimizations()
            notify("ALL OPTIMIZATIONS", "Maximum mobile performance applied! 🚀", 5)
        end,
    })

    SettingsTab:CreateButton({
        Name = "Reset All Optimizations",
        Callback = function()
            Config.Performance.DisableParticles = false
            Config.Performance.LowerGraphics = false
            Config.Performance.DisableShadows = false
            Config.Performance.ReduceRenderDistance = false
            Config.Performance.UpdateRate = 0.5
            Config.Performance.MaxESPObjects = 50
            Config.Mobile.AutoOptimize = false
            Config.Mobile.AggressiveOptimization = false
            resetPerformanceSettings()
            notify("Reset Complete", "All settings restored to default", 3)
        end,
    })
end

SettingsTab:CreateSection("Display Options")

SettingsTab:CreateToggle({
    Name = "Show FPS Counter",
    CurrentValue = false,
    Flag = "FPSCounter",
    Callback = function(Value)
        if Value then
            createFPSCounter()
        else
            removeFPSCounter()
            notify("FPS Counter", "Disabled", 2)
        end
    end,
})

SettingsTab:CreateSection("Script Controls")

SettingsTab:CreateButton({
    Name = "Clear All ESP",
    Callback = function()
        clearAllESP()
        notify("Cleared", "All ESP cleared", 2)
    end,
})

SettingsTab:CreateButton({
    Name = "Refresh ESP",
    Callback = function()
        clearAllESP()
        LastUpdate = 0 
        updateAllESP()
        notify("Refreshed", "ESP refreshed", 2)
    end,
})

SettingsTab:CreateButton({
    Name = "Unload Script",
    Callback = function()
        unloadScript()
    end,
})


task.spawn(function()
    while ScriptRunning do
        task.wait(0.2)
        if not ScriptRunning then break end

        if Config.AutoFeatures.AutoGenerator then
            safeCall(function()
                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                if not remotes then return end
                local genRemotes = remotes:FindFirstChild("Generator")
                if not genRemotes then return end
                local repairEvent = genRemotes:FindFirstChild("RepairEvent")
                local skillCheckEvent = genRemotes:FindFirstChild("SkillCheckResultEvent")
                if not repairEvent or not skillCheckEvent then return end

                local map = getMap()
                if not map then return end

                for _, obj in ipairs(map:GetDescendants()) do
                    if not ScriptRunning then break end
                    if obj:IsA("Model") and obj.Name == "Generator" then
                        for _, point in ipairs(obj:GetChildren()) do
                            if point.Name:find("GeneratorPoint") then
                                pcall(function()
                                    repairEvent:FireServer(point, true)
                                    local result = Config.AutoFeatures.GeneratorMode == "great" and "success" or "neutral"
                                    local value = Config.AutoFeatures.GeneratorMode == "great" and 1 or 0
                                    skillCheckEvent:FireServer(result, value, obj, point)
                                end)
                            end
                        end
                    end
                end
            end)
        end
    end
end)


if isMobile then
    task.wait(1)
    createMobileControls()

    if Config.Mobile.AutoOptimize then
        task.wait(0.5)
        applyMobileOptimizations()
        notify("Mobile Mode", "Auto-optimizations applied for better FPS!", 4)
    end
end


notify("Script Loaded!", "Violence District v2.3 by goldgoldgoldblazn", 4)

print("=== Violence District Golds Easy Hub v2.3 ===")
print("Developer: goldgoldgoldblazn")
print("Discord: https://discord.gg/CnNqEVFxh6")
print("Platform: " .. (isMobile and "Mobile" or "PC"))
print("Executor: " .. executorName)
print("")
print("v2.3 Changes:")
print("- ✅ Fixed duplicate tab creation (GameplayTab, TeleportTab, SettingsTab)")
print("- ✅ Fixed global function leaks (leaveGenerator, safeTeleport, etc.)")
print("- ✅ Fixed memory leaks from orphaned ESP objects")
print("- ✅ Fixed unload not stopping auto-generator loop")
print("- ✅ Added connection tracking for proper cleanup")
print("- ✅ Added double-initialization guard")
print("- ✅ Added teleport debounce to prevent spam")
print("- ✅ Added auto-attack cooldown")
print("- ✅ Improved error resilience across all features")
print("==============================================")
