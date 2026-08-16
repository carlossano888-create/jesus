local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/download/1.6.66/main.lua"))()
local Window = WindUI:CreateWindow({
    Title = "Alexx hub",
    Theme = "Dark",
    Author = "Yisuhub",
    Folder = "Alexx/beta",
    Acrylic = false,
    Transparent = false,
    NewElements = true,
    HideSearchBar = false,
    OpenButton = { Enabled = true, Draggable = true, Title = "YisusHub", CornerRadius = UDim.new(1), Scale = 0.8 },
    Topbar = { Height = 44, ButtonsType = "Default" }
})
WindUI:SetTheme("Dark")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local function getCurrentCamera()
    return Workspace.CurrentCamera or camera
end

local clientGlobalsOk, ClientGlobals = pcall(function()
    return require(ReplicatedStorage.Client.Modules.ClientGlobals)
end)
if not clientGlobalsOk then
    ClientGlobals = {}
end

local UIElements = {}
local hitboxEnabled = false
local hitboxSize = 15
local wallHitboxEnabled = false
local wallHitboxSize = 15
local wallHitboxNormalSize = Vector3.new(2, 2, 1)
local hitboxSizeVector = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
local wallHitboxSizeVector = Vector3.new(wallHitboxSize, wallHitboxSize, wallHitboxSize)
local hitboxRayParams = RaycastParams.new()
hitboxRayParams.FilterType = Enum.RaycastFilterType.Exclude

local espEnabled = false
local espColor = Color3.fromRGB(255, 0, 0)
local customHighlights = {}
local lastHitboxUpdate = 0
local lastEspUpdate = 0

local function destroyChild(parent, childName)
    local child = parent and parent:FindFirstChild(childName)
    if child then
        child:Destroy()
    end
end

local function clearHitboxes(character)
    if not character then return end
    destroyChild(character, "GhostHitbox")
    destroyChild(character, "WallGhostHitbox")
end

local function isEnemy(target)
    if not target or target == player or not target:IsA("Player") then return false end
    local myTeam = player:GetAttribute("Team") or player.Team
    local targetTeam = target:GetAttribute("Team") or target.Team
    return myTeam ~= targetTeam
end

local function estaEnLobby()
    local mapa = player:GetAttribute("Map")
    local partida = player:GetAttribute("Game")
    return mapa == nil or partida == nil
end

local Tabs = {
    Aim = Window:Tab({ Title = "Esp", Icon = "crosshair" })
}

Tabs.Aim:Section({Title = "Visuales de Enemigos"})

UIElements.TogEsp = Tabs.Aim:Toggle({
    Title = "Activar ESP",
    Desc = "YisusHub",
    Callback = function(s) 
        espEnabled = s 
        if not s then
            for v, h in pairs(customHighlights) do
                pcall(function() h:Destroy() end)
                customHighlights[v] = nil
            end
        end
    end
})

UIElements.ColEsp = Tabs.Aim:Colorpicker({
    Title = "Color del ESP", 
    Default = Color3.fromRGB(255, 0, 0), 
    Callback = function(c) espColor = c end
})

Tabs.Aim:Section({Title = "Hitbox"})

Tabs.Aim:Toggle({
    Title = "Activar Hitbox",
    Desc = "YisusHub",
    Value = false,
    Callback = function(Value)
        hitboxEnabled = Value
        if not Value then
            for _, v in ipairs(Players:GetPlayers()) do
                pcall(function()
                    if v.Character and v.Character:FindFirstChild("GhostHitbox") then
                        v.Character.GhostHitbox:Destroy()
                    end
                end)
            end
        end
    end
})

Tabs.Aim:Slider({
    Title = "Tamaño Hitbox",
    Value = { Min = 1, Max = 20, Default = 15 },
    Callback = function(v)
        hitboxSize = v
        hitboxSizeVector = Vector3.new(v, v, v)
    end
})

Tabs.Aim:Section({Title = "Hitbox Disimulada "})

Tabs.Aim:Toggle({
    Title = "Activar Hitbox",
    Desc = "YisusHub",
    Value = false,
    Callback = function(Value)
        wallHitboxEnabled = Value
        if not Value then
            for _, v in ipairs(Players:GetPlayers()) do
                pcall(function()
                    if v.Character and v.Character:FindFirstChild("WallGhostHitbox") then
                        v.Character.WallGhostHitbox:Destroy()
                    end
                end)
            end
        end
    end
})

Tabs.Aim:Slider({
    Title = "Tamaño Hitbox Dinámica",
    Value = { Min = 1, Max = 20, Default = 15 },
    Callback = function(v)
        wallHitboxSize = v
        wallHitboxSizeVector = Vector3.new(v, v, v)
    end
})

-- Bucle unificado optimizado para Hitbox y WallHitbox
RunService.Heartbeat:Connect(function()
    if not hitboxEnabled and not wallHitboxEnabled then return end

    local now = os.clock()
    if now - lastHitboxUpdate < 0.05 then return end
    lastHitboxUpdate = now
    
    local charLocal = player.Character
    local hrpLocal = charLocal and charLocal:FindFirstChild("HumanoidRootPart")

    for _, playerObj in ipairs(Players:GetPlayers()) do
        if playerObj ~= player and isEnemy(playerObj) and playerObj.Character then
            local character = playerObj.Character
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            local humanoid = character:FindFirstChild("Humanoid")
            
            if rootPart and humanoid and humanoid.Health > 0 then
                if hitboxEnabled then
                    local p = character:FindFirstChild("GhostHitbox")
                    if not p then
                        p = Instance.new("Part")
                        p.Name = "GhostHitbox"
                        p.Size = hitboxSizeVector
                        p.Transparency = 0.7
                        p.CanCollide = false
                        p.Massless = true
                        p.CFrame = rootPart.CFrame
                        p.Parent = character
                        
                        local weld = Instance.new("WeldConstraint")
                        weld.Part0 = rootPart
                        weld.Part1 = p
                        weld.Parent = p
                    else
                        p.Size = hitboxSizeVector
                    end
                else
                    destroyChild(character, "GhostHitbox")
                end

                if wallHitboxEnabled and hrpLocal then
                    hitboxRayParams.FilterDescendantsInstances = {charLocal, character}
                    local rayResult = Workspace:Raycast(hrpLocal.Position, rootPart.Position - hrpLocal.Position, hitboxRayParams)
                    local isBehindWall = rayResult ~= nil 

                    local pWall = character:FindFirstChild("WallGhostHitbox")
                    if not pWall then
                        pWall = Instance.new("Part")
                        pWall.Name = "WallGhostHitbox"
                        pWall.Transparency = 0.7
                        pWall.CanCollide = false
                        pWall.Massless = true
                        pWall.CFrame = rootPart.CFrame
                        pWall.Parent = character
                        
                        local weld = Instance.new("WeldConstraint")
                        weld.Part0 = rootPart
                        weld.Part1 = pWall
                        weld.Parent = pWall
                    end
                    
                    if isBehindWall then
                        pWall.Size = wallHitboxNormalSize
                        pWall.Transparency = 1 
                    else
                        pWall.Size = wallHitboxSizeVector
                        pWall.Transparency = 0.7
                    end
                else
                    destroyChild(character, "WallGhostHitbox")
                end
            else
                clearHitboxes(character)
            end
        else
            clearHitboxes(playerObj.Character)
        end
    end
end)

local safeEspFolder = Instance.new("Folder")
safeEspFolder.Name = "SafeHighlightsFolder"
pcall(function()
    safeEspFolder.Parent = CoreGui
end)
if safeEspFolder.Parent ~= CoreGui then
    safeEspFolder.Parent = player:WaitForChild("PlayerGui")
end

RunService.Heartbeat:Connect(function()
    local now = os.clock()
    if now - lastEspUpdate < 0.1 then return end
    lastEspUpdate = now
    local inLobby = estaEnLobby()

    for _, playerObj in ipairs(Players:GetPlayers()) do
        if playerObj ~= player and playerObj:IsA("Player") and espEnabled and playerObj.Character then
            local character = playerObj.Character
            local humanoid = character:FindFirstChild("Humanoid")
            
            if humanoid and humanoid.Health > 0 and isEnemy(playerObj) and not inLobby then
                if not customHighlights[playerObj] or not customHighlights[playerObj].Parent then
                    local success, highlight = pcall(function()
                        local h = Instance.new("Highlight")
                        h.Name = "PlayerHighlight"
                        h.Adornee = character
                        h.FillColor = espColor
                        h.OutlineColor = Color3.fromRGB(255, 255, 255)
                        h.FillTransparency = 0.5
                        h.OutlineTransparency = 0
                        h.Parent = safeEspFolder
                        return h
                    end)
                    
                    if success and highlight then
                        customHighlights[playerObj] = highlight
                    end
                else
                    customHighlights[playerObj].Adornee = character
                    customHighlights[playerObj].FillColor = espColor
                end
            else
                if customHighlights[playerObj] then
                    pcall(function() customHighlights[playerObj]:Destroy() end)
                    customHighlights[playerObj] = nil
                end
            end
        else
            if customHighlights[playerObj] then
                pcall(function() customHighlights[playerObj]:Destroy() end)
                customHighlights[playerObj] = nil
            end
        end
    end
end)

Players.PlayerRemoving:Connect(function(playerObj)
    local highlight = customHighlights[playerObj]
    if highlight then
        pcall(function() highlight:Destroy() end)
        customHighlights[playerObj] = nil
    end
end)

local playerGui = player:WaitForChild("PlayerGui")
local screenGui = playerGui:FindFirstChild("AstraScreenGui")
if not screenGui then
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AstraScreenGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
end

local function makeDraggableSafe(frame, handle)
    local dragging, dragInput, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local deadZoneFrame = Instance.new("Frame")
deadZoneFrame.Size = UDim2.new(0, 150, 0, 150)
deadZoneFrame.Position = UDim2.new(0.8, -75, 0.8, -75) 
deadZoneFrame.BackgroundColor3 = Color3.fromRGB(255, 50, 50) 
deadZoneFrame.BackgroundTransparency = 0.5
deadZoneFrame.Visible = false
deadZoneFrame.ZIndex = 100
deadZoneFrame.Parent = screenGui 
Instance.new("UICorner", deadZoneFrame).CornerRadius = UDim.new(0, 16)

local dzStroke = Instance.new("UIStroke", deadZoneFrame)
dzStroke.Color = Color3.fromRGB(255, 255, 255)
dzStroke.Thickness = 2
dzStroke.LineJoinMode = Enum.LineJoinMode.Round

local dzLabel = Instance.new("TextLabel", deadZoneFrame)
dzLabel.Size = UDim2.new(1, 0, 1, 0)
dzLabel.BackgroundTransparency = 1
dzLabel.Text = "ZONA MUERTA\n(Arrastrar)"
dzLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
dzLabel.Font = Enum.Font.GothamBold
dzLabel.TextSize = 14
dzLabel.TextWrapped = true

makeDraggableSafe(deadZoneFrame, deadZoneFrame)

getgenv().AutoEquipEnabled = false
local startPosVector = Vector2.new(0, 0)
local startTime = 0 
local CLICK_THRESHOLD = 20 

local function buscarArma()
    local backpack = player:FindFirstChild("Backpack")
    local char = player.Character
    
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") and item:FindFirstChild("fire") then
                return item
            end
        end
    end
    
    if char then
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Tool") and item:FindFirstChild("fire") then
                return item
            end
        end
        local currentTool = char:FindFirstChildOfClass("Tool")
        if currentTool and (currentTool:FindFirstChild("Kill") or currentTool:FindFirstChild("ActivateThrowing")) then
            return nil 
        end
    end
    
    return nil
end

local function hasCombatTool(character)
    local tool = character and character:FindFirstChildOfClass("Tool")
    return tool and (
        tool:FindFirstChild("Kill")
        or tool:FindFirstChild("ThrowKill")
        or tool:FindFirstChild("ActivateThrowing")
    ) ~= nil
end

local function verificarEnemigosMacro()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and isEnemy(p) then
            local pChar = p.Character
            if pChar and pChar:FindFirstChild("Humanoid") and pChar.Humanoid.Health > 0 then
                return true
            end
        end
    end
    return false
end

local function ejecutarAccionMacro()
    if not verificarEnemigosMacro() then return end
    
    local char = player.Character
    if not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then return end

    if hasCombatTool(char) then return end

    local backpack = player:FindFirstChild("Backpack")
    local arma = buscarArma()
    
    if arma then
        task.spawn(function()
            char.Humanoid:EquipTool(arma)
            task.wait(0.04)
            arma:Activate()
            task.wait(0.1)
            if arma.Parent == char and backpack then
                arma.Parent = backpack
            end
        end)
    end
end

local silentAimManualEnabled = false
local silentAimTargetPart = "Cabeza"
getgenv().yisusTargetPart = nil
getgenv().yisusAutoShootTarget = nil

if hookmetamethod and checkcaller then
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local activeTarget = getgenv().yisusTargetPart or getgenv().yisusAutoShootTarget

        if not checkcaller() and activeTarget and activeTarget.Parent then
            if method == "Raycast" and self == Workspace then
                local origin, direction, p3 = ...
                if typeof(direction) == "Vector3" and direction.Magnitude > 15 then
                    local newDir = (activeTarget.Position - origin).Unit * 8000 
                    return oldNamecall(self, origin, newDir, p3)
                end
            elseif string.find(method, "FindPartOnRay") and self == Workspace then
                local ray, p2, p3, p4 = ...
                if typeof(ray) == "Ray" and ray.Direction.Magnitude > 15 then
                    local newRay = Ray.new(ray.Origin, (activeTarget.Position - ray.Origin).Unit * 8000)
                    return oldNamecall(self, newRay, p2, p3, p4)
                end
            end
        end
        return oldNamecall(self, ...)
    end)
end

local autoShootNormalEnabled = false
local autoShootAgresivoEnabled = false
local nextAutoShootAt = 0
local backpack = player:WaitForChild("Backpack")

local function findToolWithFire(container)
    if not container then return nil end
    for _, tool in ipairs(container:GetChildren()) do
        if tool:IsA("Tool") and tool:FindFirstChild("fire") then
            return tool
        end
    end
    return nil
end

local function buscarArmaAutoShoot()
    return findToolWithFire(backpack) or findToolWithFire(player.Character)
end

local silentAimTorsoPartSet = {
    UpperTorso = true,
    Torso = true,
    HumanoidRootPart = true,
}
local autoShootNormalPartSet = {
    Head = true,
    HumanoidRootPart = true,
    UpperTorso = true,
    Torso = true,
}

task.spawn(function()
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude

    while task.wait(0.12) do
        local silentEnabled = silentAimManualEnabled
        local autoEnabled = autoShootNormalEnabled or autoShootAgresivoEnabled

        if not silentEnabled and not autoEnabled then
            getgenv().yisusTargetPart = nil
            getgenv().yisusAutoShootTarget = nil
            continue
        end

        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not char or not root then
            getgenv().yisusTargetPart = nil
            getgenv().yisusAutoShootTarget = nil
            continue
        end

        local arma = autoEnabled and buscarArmaAutoShoot() or nil
        local autoCanRun = autoEnabled and arma ~= nil
        if autoEnabled and not autoCanRun then
            getgenv().yisusAutoShootTarget = nil
        end

        local silentTargetPart = nil
        local autoShootTargetPart = nil
        local silentShortestDistance = math.huge
        local autoShortestDistance = math.huge
        local myPos = root.Position
        local head = char:FindFirstChild("Head")
        local headPos = head and head.Position or myPos

        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player and isEnemy(p) and p.Character then
                local enemyChar = p.Character
                local enemyHum = enemyChar:FindFirstChild("Humanoid")

                if enemyHum and enemyHum.Health > 0 then
                    params.FilterDescendantsInstances = {char, enemyChar}

                    for _, part in ipairs(enemyChar:GetChildren()) do
                        if part:IsA("BasePart") then
                            local isSilentCandidate = false
                            if silentEnabled then
                                if silentAimTargetPart == "Cabeza" then
                                    isSilentCandidate = part.Name == "Head"
                                elseif silentAimTargetPart == "Torso" then
                                    isSilentCandidate = silentAimTorsoPartSet[part.Name] == true
                                else
                                    isSilentCandidate = part.Name ~= "HumanoidRootPart"
                                end
                            end

                            local isAutoCandidate = false
                            if autoCanRun then
                                isAutoCandidate = (autoShootAgresivoEnabled and part.Name ~= "HumanoidRootPart")
                                    or autoShootNormalPartSet[part.Name] == true
                            end

                            local distance = (part.Position - myPos).Magnitude
                            local shouldCheckVisibility =
                                (isSilentCandidate and distance < silentShortestDistance)
                                or (isAutoCandidate and distance < autoShortestDistance)

                            if shouldCheckVisibility
                                and not Workspace:Raycast(headPos, part.Position - headPos, params) then
                                if isSilentCandidate and distance < silentShortestDistance then
                                    silentShortestDistance = distance
                                    silentTargetPart = part
                                end
                                if isAutoCandidate and distance < autoShortestDistance then
                                    autoShortestDistance = distance
                                    autoShootTargetPart = part
                                end
                            end
                        end
                    end
                end
            end
        end

        getgenv().yisusTargetPart = silentEnabled and silentTargetPart or nil
        getgenv().yisusAutoShootTarget = autoCanRun and autoShootTargetPart or nil

        local now = os.clock()
        if autoCanRun and autoShootTargetPart and now >= nextAutoShootAt then
            nextAutoShootAt = now + 0.15
            pcall(function()
                arma:Activate()
                task.delay(0.04, function()
                    if arma.Parent == char then
                        arma:Deactivate()
                    end
                end)
            end)
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not getgenv().AutoEquipEnabled or gameProcessed or estaEnLobby() then return end

    local char = player.Character
    if hasCombatTool(char) then return end

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        ejecutarAccionMacro()
    elseif input.UserInputType == Enum.UserInputType.Touch then
        startPosVector = input.Position
        startTime = tick()
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if not getgenv().AutoEquipEnabled or gameProcessed then return end

    local char = player.Character
    if hasCombatTool(char) then return end

    if input.UserInputType ~= Enum.UserInputType.Touch then return end

    local pos = input.Position
    local dzPos = deadZoneFrame.AbsolutePosition
    local dzSize = deadZoneFrame.AbsoluteSize

    if pos.X >= dzPos.X and pos.X <= dzPos.X + dzSize.X and pos.Y >= dzPos.Y and pos.Y <= dzPos.Y + dzSize.Y then
        return
    end

    if (input.Position - startPosVector).Magnitude < CLICK_THRESHOLD and (tick() - startTime) < 0.25 then
        ejecutarAccionMacro()
    end
end)

local AimTab = Window:Tab({ Title = "Combat", Icon = "target" })
AimTab:Section({Title = "Macro"})

AimTab:Toggle({
    Title = "Macro",
    Desc = "Dirige las balas al enemigo",
    Value = false,
    Callback = function(Value)
        silentAimManualEnabled = Value
        getgenv().AutoEquipEnabled = Value
        if not Value then getgenv().yisusTargetPart = nil end
    end,
})

AimTab:Dropdown({
    Title = "Target: Parte del cuerpo",
    Values = {"Cabeza", "Torso", "Cuerpo Completo"},
    Value = "Cabeza",
    Callback = function(Value)
        silentAimTargetPart = Value
    end
})

getgenv().AutoEquipEnabled2 = false
local startPosVector2 = Vector2.new()
local startTime2 = 0
local CLICK_THRESHOLD2 = 20

local function buscarArmaMacro2()
    local backpack = player:FindFirstChild("Backpack")
    local char = player.Character

    if char then
        if hasCombatTool(char) then
            return nil
        end
    end

    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and tool:FindFirstChild("fire") then
                return tool
            end
        end
    end

    if char then
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") and tool:FindFirstChild("fire") then
                return tool
            end
        end
    end

    return nil
end

local function verificarEnemigosMacro2()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and isEnemy(p) then
            local c = p.Character
            if c and c:FindFirstChild("Humanoid") and c.Humanoid.Health > 0 then
                return true
            end
        end
    end
    return false
end

local function ejecutarMacro2()
    if not verificarEnemigosMacro2() then return end

    local char = player.Character
    if not char then return end

    local hum = char:FindFirstChild("Humanoid")
    if not hum or hum.Health <= 0 then return end

    local backpack = player:FindFirstChild("Backpack")
    local arma = buscarArmaMacro2()

    if arma then
        task.spawn(function()
            hum:EquipTool(arma)
            task.wait(0.04)
            arma:Activate()
            task.wait(0.10)

            if backpack and arma.Parent == char then
                arma.Parent = backpack
            end
        end)
    end
end

UserInputService.InputBegan:Connect(function(input, gp)
    if gp or not getgenv().AutoEquipEnabled2 or estaEnLobby() then return end

    local char = player.Character
    if char then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool and (
            tool:FindFirstChild("Kill")
            or tool:FindFirstChild("ThrowKill")
            or tool:FindFirstChild("ActivateThrowing")
        ) then
            return
        end
    end

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        ejecutarMacro2()
    elseif input.UserInputType == Enum.UserInputType.Touch then
        startPosVector2 = input.Position
        startTime2 = tick()
    end
end)

UserInputService.InputEnded:Connect(function(input, gp)
    if gp or not getgenv().AutoEquipEnabled2 or input.UserInputType ~= Enum.UserInputType.Touch then return end

    local char = player.Character
    if char then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool and (
            tool:FindFirstChild("Kill")
            or tool:FindFirstChild("ThrowKill")
            or tool:FindFirstChild("ActivateThrowing")
        ) then
            return
        end
    end

    local pos = input.Position
    local dzPos = deadZoneFrame.AbsolutePosition
    local dzSize = deadZoneFrame.AbsoluteSize

    if pos.X >= dzPos.X and pos.X <= dzPos.X + dzSize.X and pos.Y >= dzPos.Y and pos.Y <= dzPos.Y + dzSize.Y then
        return
    end

    if (input.Position - startPosVector2).Magnitude < CLICK_THRESHOLD2 and (tick() - startTime2) < 0.25 then
        ejecutarMacro2()
    end
end)

AimTab:Toggle({
    Title = "Macro Normal",
    Desc = "Normal",
    Value = false,
    Callback = function(Value)
        getgenv().AutoEquipEnabled2 = Value
    end
})

local Mouse = player:GetMouse() 
getgenv().SilentAim = {
    Enabled = false, 
    Part = "Head",
}

local function getClosest()
    local targetPart, targetPlayer = nil, nil
    local currentCamera = getCurrentCamera()
    if not currentCamera then return nil, nil end
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character and isEnemy(p) then
            local char = p.Character
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local part = char:FindFirstChild(getgenv().SilentAim.Part)
            local hum = char:FindFirstChildOfClass("Humanoid")
            
            if part and hrp and hum and hum.Health > 0 then
                local ray = Ray.new(currentCamera.CFrame.Position, (part.Position - currentCamera.CFrame.Position).Unit * 600)
                local hit = Workspace:FindPartOnRayWithIgnoreList(ray, {player.Character, currentCamera})
                local isVisible = hit and hit:IsDescendantOf(char)
                
                if isVisible then
                    targetPart = part 
                    targetPlayer = p 
                    break
                end
            end
        end
    end
    return targetPart, targetPlayer
end

if hookmetamethod and checkcaller then
    local oldIndex
    oldIndex = hookmetamethod(game, "__index", function(self, index)
        if not getgenv().SilentAim.Enabled or self ~= Mouse or index ~= "Hit" or checkcaller() or getgenv().yisusAutoShootTarget then
            return oldIndex(self, index)
        end

        local targetPart, targetPlayer = getClosest()
        if targetPart and targetPlayer then
            getgenv().yisusTargetPart = targetPart
            return CFrame.new(targetPart.Position)
        else
            getgenv().yisusTargetPart = nil
        end

        return oldIndex(self, index)
    end)
end

AimTab:Section({Title = "Silent Aim"})
AimTab:Toggle({
    Title = "Activar Silent Aim",
    Value = false,
    Callback = function(v) 
        getgenv().SilentAim.Enabled = v 
        if not v then getgenv().yisusTargetPart = nil end
    end
})

AimTab:Dropdown({
    Title = "Target: Parte del cuerpo",
    Values = {"Cabeza", "Torso", "Cuerpo Completo"},
    Value = "Cabeza",
    Callback = function(Value)
        if Value == "Cabeza" then
            getgenv().SilentAim.Part = "Head"
        elseif Value == "Torso" then
            getgenv().SilentAim.Part = "HumanoidRootPart"
        else
            getgenv().SilentAim.Part = "Head"
        end
    end
})

AimTab:Section({Title = "Auto Shoot"})
AimTab:Toggle({
    Title = "Auto Shoot",
    Desc = "Dispara automáticamente.",
    Value = false,
    Callback = function(Value)
        autoShootNormalEnabled = Value
        if not Value then getgenv().yisusAutoShootTarget = nil end
    end,
})

AimTab:Toggle({
    Title = "Auto Shoot Agresivo",
    Desc = "Más agresivo.",
    Value = false,
    Callback = function(Value)
        autoShootAgresivoEnabled = Value
        if not Value then getgenv().yisusAutoShootTarget = nil end
    end,
})

local autoEquipGunEnabled = false
local ultimoCambioGun = 0

local function obtenerArmaGun()
    local character = player.Character
    if character then
        local toolMano = character:FindFirstChildOfClass("Tool")
        if toolMano and toolMano.Name ~= "Knife" and toolMano.Name ~= "Cuchillo" then
            if not toolMano:FindFirstChild("Stab") then
                return toolMano
            end
        end
    end
    
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        local gun = backpack:FindFirstChild("Gun") or backpack:FindFirstChild("DefaultGun") or backpack:FindFirstChild("Revolver")
        if not gun then
            for _, item in ipairs(backpack:GetChildren()) do
                if item:IsA("Tool") then
                    local nombreLower = string.lower(item.Name)
                    if not string.find(nombreLower, "knife") and not string.find(nombreLower, "cuchillo") then
                        if item:FindFirstChild("fire") or item:FindFirstChild("showBeam") or item:FindFirstChild("Shoot") then
                            gun = item
                            break
                        end
                    end
                end
            end
        end
        if gun and gun.Parent then return gun end
    end
    return nil
end

local gunVisibilityRaycastParams = RaycastParams.new()
gunVisibilityRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
gunVisibilityRaycastParams.IgnoreWater = true

local function hayVisionLibreGun(origen, enemyChar, characterLocal)
    gunVisibilityRaycastParams.FilterDescendantsInstances = {characterLocal, enemyChar}

    local enemyRoot = enemyChar:FindFirstChild("HumanoidRootPart")
    if not enemyRoot then return false end
    
    local enemyHead = enemyChar:FindFirstChild("Head")
    local objetivos = {
        enemyRoot.Position,
        enemyHead and enemyHead.Position or (enemyRoot.Position + Vector3.new(0, 2, 0)),
        enemyRoot.Position - Vector3.new(0, 2, 0)
    }

    local puntosVisibles = 0
    for _, objetivo in ipairs(objetivos) do
        if not Workspace:Raycast(origen, objetivo - origen, gunVisibilityRaycastParams) then
            puntosVisibles = puntosVisibles + 1
        end
    end
    return puntosVisibles >= 2
end

local function hayEnemigoValidoYVisibleGun()
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return false end
    
    local rootPart = character.HumanoidRootPart
    local mapaActual = player:GetAttribute("Map")
    local partidaActual = player:GetAttribute("Game")

    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player and isEnemy(otherPlayer) then
            if (mapaActual == nil or otherPlayer:GetAttribute("Map") == mapaActual) and (partidaActual == nil or otherPlayer:GetAttribute("Game") == partidaActual) then
                local enemyChar = otherPlayer.Character
                if enemyChar then
                    local enemyRoot = enemyChar:FindFirstChild("HumanoidRootPart")
                    local enemyHum = enemyChar:FindFirstChildOfClass("Humanoid")
                    
                    if enemyRoot and enemyHum and enemyHum.Health > 0 then
                        if hayVisionLibreGun(rootPart.Position, enemyChar, character) then
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

local function puedeUsarGun()
    local gameId = player:GetAttribute("Game")
    if typeof(gameId) ~= "string" then return false end

    local runningGames = ClientGlobals.RunningGames
    if not runningGames or not runningGames.TryIndex then return false end

    local gameData = runningGames:TryIndex({gameId})
    if not gameData then return false end

    return gameData.RoundStarted == false and gameData.CurrentRoundEnded == false
end

RunService.Heartbeat:Connect(function()
    if not autoEquipGunEnabled or not puedeUsarGun() or (tick() - ultimoCambioGun < 0.5) then return end

    local character = player.Character
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local backpack = player:FindFirstChildOfClass("Backpack")

    if not humanoid or humanoid.Health <= 0 or not backpack or character:FindFirstChildOfClass("Tool") then return end

    if hayEnemigoValidoYVisibleGun() then
        local gun = obtenerArmaGun()
        if gun and gun.Parent == backpack then
            pcall(function() humanoid:EquipTool(gun) end)
            ultimoCambioGun = tick()
        end
    end
end)

AimTab:Toggle({
    Title = "Auto Equipar",
    Desc = "Usalo solo con el Autoshoot",
    Value = false,
    Callback = function(Value)
        autoEquipGunEnabled = Value
    end,
})

local AutoFarmTab = Window:Tab({ Title = "Auto Farm", Icon = "coins" })
AutoFarmTab:Section({Title = "Funciones Automáticas"})

local AutoFarmActivo = false
local autoFarmLoopRunning = false
AutoFarmTab:Toggle({
    Title = "Auto Farm",
    Value = false,
    Callback = function(state)
        AutoFarmActivo = state
        if AutoFarmActivo and not autoFarmLoopRunning then
            autoFarmLoopRunning = true
            task.spawn(function()
                local container = Workspace:WaitForChild("SpawnablesClient")
                while AutoFarmActivo do
                    for _, obj in ipairs(container:GetChildren()) do
                        if not AutoFarmActivo then break end
                        local touchPart = obj:FindFirstChild("Touch")
                        if touchPart and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                            pcall(function()
                                firetouchinterest(player.Character.HumanoidRootPart, touchPart, 0)
                                firetouchinterest(player.Character.HumanoidRootPart, touchPart, 1)
                            end)
                        end
                    end
                    task.wait(0.45)
                end
                autoFarmLoopRunning = false
            end)
        end
    end
})

AutoFarmTab:Section({Title = "Player"})
_G.SpeedEnabled = false
_G.SpeedMultiplier = 0

AutoFarmTab:Toggle({
    Title = "Activar Speed",
    Value = false,
    Callback = function(state) _G.SpeedEnabled = state end
})

AutoFarmTab:Slider({
    Title = "Speed Slider",
    Value = { Min = 0, Max = 100, Default = 0 },
    Callback = function(v) _G.SpeedMultiplier = v / 100 end
})

RunService.RenderStepped:Connect(function()
    if _G.SpeedEnabled and _G.SpeedMultiplier > 0 then
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp and hum and hum.MoveDirection.Magnitude > 0 then
            hrp.CFrame = hrp.CFrame + (hum.MoveDirection * _G.SpeedMultiplier)
        end
    end
end)

_G.InfiniteJump = false
AutoFarmTab:Toggle({
    Title = "Salto Infinito",
    Value = false,
    Callback = function(state) _G.InfiniteJump = state end
})

UserInputService.JumpRequest:Connect(function()
    if _G.InfiniteJump then
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end
end)

_G.FOVEnabled = false
local DefaultFOV = 70 

AutoFarmTab:Toggle({
    Title = "Activar FOV",
    Value = false,
    Callback = function(state)
        _G.FOVEnabled = state
        local currentCamera = getCurrentCamera()
        if currentCamera and not state then currentCamera.FieldOfView = DefaultFOV end
    end
})

AutoFarmTab:Slider({
    Title = "Valor FOV",
    Value = { Min = 70, Max = 120, Default = 70 },
    Callback = function(v)
        local currentCamera = getCurrentCamera()
        if currentCamera and _G.FOVEnabled then currentCamera.FieldOfView = v end
    end
})

_G.WallClimb = false
AutoFarmTab:Toggle({
    Title = "Wall Climb",
    Value = false,
    Callback = function(state) _G.WallClimb = state end
})

RunService.RenderStepped:Connect(function()
    if _G.WallClimb then
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hum and hrp and hum.MoveDirection.Magnitude > 0 then
            hrp.Velocity = Vector3.new(hrp.Velocity.X, 25, hrp.Velocity.Z)
        end
    end
end)

local KORBLOX_MESH_ID = "rbxassetid://101851696"
local KORBLOX_TEXTURE_ID = "rbxassetid://101851254"
local DARK_GREY_COLOR = Color3.fromRGB(64, 64, 64)

local function applyKorblox()
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if hum.RigType == Enum.HumanoidRigType.R15 then
        local rf = char:FindFirstChild("RightFoot")
        local rl = char:FindFirstChild("RightLowerLeg")
        local ru = char:FindFirstChild("RightUpperLeg")

        if ru and rl and rf then
            rf.Transparency = 1
            rl.Transparency = 1
            ru.MeshId = "http://www.roblox.com/asset/?id=902942096"
            ru.TextureID = "http://roblox.com/asset/?id=902843398"
            ru.Color = Color3.new(1, 1, 1)
            ru.Transparency = 0
        end
    else
        local rightLeg = char:FindFirstChild("Right Leg")
        if rightLeg then
            for _, v in ipairs(char:GetChildren()) do
                if v:IsA("CharacterMesh") and v.BodyPart == Enum.BodyPart.RightLeg then
                    v:Destroy()
                end
            end
            
            local mesh = rightLeg:FindFirstChildOfClass("SpecialMesh") or Instance.new("SpecialMesh", rightLeg)
            rightLeg.Color = DARK_GREY_COLOR
            rightLeg.Transparency = 0
            mesh.MeshType = Enum.MeshType.FileMesh
            mesh.MeshId = KORBLOX_MESH_ID
            mesh.TextureId = KORBLOX_TEXTURE_ID
            mesh.Scale = Vector3.new(1, 1, 1)
        end
    end
end

AutoFarmTab:Button({
    Title = "Korblox",
    Desc = "YisusHub",
    Callback = function() applyKorblox() end
})

local SelectedTargetName = nil 
local LastTeleportedCharacter = nil
_G.AutoTeleport = false

local MoveTab = Window:Tab({ Title = "Movimiento", Icon = "move" })
MoveTab:Section({Title = "Teletransporte a Jugadores"})

local function GetPlayerList()
    local list = {}
    for _, v in ipairs(Players:GetPlayers()) do
        if v ~= player then table.insert(list, v.Name) end
    end
    return #list > 0 and list or {"Esperando jugadores..."}
end

local PlayerDropdown = MoveTab:Dropdown({
    Title = "Seleccionar Jugador",
    List = GetPlayerList(),
    Callback = function(Option) SelectedTargetName = Option end
})

MoveTab:Button({
    Title = "🔄 Refrescar Lista",
    Callback = function() PlayerDropdown:Refresh(GetPlayerList()) end
})

task.spawn(function()
    while true do
        task.wait(0.45)
        if _G.AutoTeleport and SelectedTargetName then
            local targetPlayer = Players:FindFirstChild(SelectedTargetName)
            local targetChar = targetPlayer and targetPlayer.Character
            local targetHRP = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
            local myChar = player.Character
            local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
            
            if targetChar and targetHRP and myHRP and targetChar ~= LastTeleportedCharacter then
                myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 3)
                LastTeleportedCharacter = targetChar
            end
        end
    end
end)

MoveTab:Toggle({
    Title = "Teletransport Player",
    Value = false,
    Callback = function(state) _G.AutoTeleport = state end
})

MoveTab:Section({Title = "Anti-Contador"})
local superBypassLoopRunning = false
MoveTab:Toggle({
    Title = "Anti Contador",
    Value = false,
    Callback = function(state)
        _G.SuperBypass = state
        if state and not superBypassLoopRunning then
            superBypassLoopRunning = true
            task.spawn(function()
                while _G.SuperBypass do
                    pcall(function()
                        local char = player.Character
                        if char then
                            for _, v in ipairs(char:GetDescendants()) do
                                if v:IsA("BasePart") then v.Anchored = false end
                            end
                            local hum = char:FindFirstChildOfClass("Humanoid")
                            if hum and hum.WalkSpeed < 10 then hum.WalkSpeed = 16 end
                        end
                    end)
                    task.wait(0.12)
                end
                superBypassLoopRunning = false
            end)
        end
    end
})

AimTab:Section({Title = "Knife"})
local killAuraActivo = false
local objetivoActual = nil

if ClientGlobals.RunningGames and ClientGlobals.RunningGames.ListenRaw then
    ClientGlobals.RunningGames:ListenRaw(function(data)
        for _, gameData in pairs(data) do
            if gameData.Phase == "InGame" and gameData.RoundStarted == false and gameData.Protection == nil and not gameData.RoundEnded and not gameData.CurrentRoundEnded then
                break
            end
        end
    end)
end

player:GetAttributeChangedSignal("Map"):Connect(function()
    if estaEnLobby() then objetivoActual = nil end
end)

player.CharacterAdded:Connect(function() objetivoActual = nil end)

AimTab:Toggle({
    Title = "KillAura",
    Desc = "Aviso pueden banearte",
    Value = false,
    Callback = function(Value)
        killAuraActivo = Value
        if not Value then objetivoActual = nil end
    end
})

local function obtenerEnemigoPorMapa()
    if estaEnLobby() then return nil end

    local mapa = player:GetAttribute("Map")
    local partida = player:GetAttribute("Game")
    local miCharacter = player.Character
    if not miCharacter or not miCharacter:FindFirstChild("HumanoidRootPart") then return nil end

    local miRoot = miCharacter.HumanoidRootPart
    local enemigoMasCercano = nil
    local menorDistancia = math.huge

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and isEnemy(p) and p:GetAttribute("Map") == mapa and p:GetAttribute("Game") == partida then
            local character = p.Character
            if character then
                local enemyRoot = character:FindFirstChild("HumanoidRootPart")
                local humanoid = character:FindFirstChildOfClass("Humanoid")

                if enemyRoot and humanoid and humanoid.Health > 0 then
                    local distancia = (enemyRoot.Position - miRoot.Position).Magnitude
                    if distancia < menorDistancia then
                        menorDistancia = distancia
                        enemigoMasCercano = enemyRoot
                    end
                end
            end
        end
    end
    return enemigoMasCercano
end

local function actualizarObjetivo()
    local objetivoRoot = nil
    if objetivoActual and objetivoActual.Parent then
        local humActual = objetivoActual.Parent:FindFirstChildOfClass("Humanoid")
        local pActual = Players:GetPlayerFromCharacter(objetivoActual.Parent)
        local mapaActual = player:GetAttribute("Map")
        local partidaActual = player:GetAttribute("Game")

        if humActual and humActual.Health > 0 and pActual and pActual:GetAttribute("Map") == mapaActual and pActual:GetAttribute("Game") == partidaActual then
            objetivoRoot = objetivoActual
        end
    end

    if not objetivoRoot then
        objetivoRoot = obtenerEnemigoPorMapa()
        objetivoActual = objetivoRoot
    end
    return objetivoRoot
end

local function puedeUsarKnife()
    local gameId = player:GetAttribute("Game")
    if typeof(gameId) ~= "string" then return false end

    local runningGames = ClientGlobals.RunningGames
    if not runningGames or not runningGames.TryIndex then return false end

    local gameData = runningGames:TryIndex({gameId})
    if not gameData then return false end

    return gameData.RoundStarted == false and gameData.CurrentRoundEnded == false
end

task.spawn(function()
    while player:GetAttribute("Map") == nil do
        player:GetAttributeChangedSignal("Map"):Wait()
    end
    while true do
        task.wait(0.05)
        if killAuraActivo and puedeUsarKnife() and not estaEnLobby() then
            local objetivoRoot = actualizarObjetivo()

            if objetivoRoot and objetivoRoot.Parent then
                local character = player.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    local rootPart = character.HumanoidRootPart
                    local backpack = player:FindFirstChildOfClass("Backpack")

                    local toolEquipada = nil
                    local killEvent = nil

                    local function verificarTool(item)
                        if item:IsA("Tool") then
                            local h = item:FindFirstChild("Handle")
                            local evento = item:FindFirstChild("Kill") or (h and h:FindFirstChild("Kill")) or item:FindFirstChild("ThrowKill") or (h and h:FindFirstChild("ThrowKill"))
                            if evento and evento:IsA("RemoteEvent") then
                                toolEquipada = item
                                killEvent = evento
                                return true
                            end
                        end
                        return false
                    end

                    for _, item in ipairs(character:GetChildren()) do
                        if verificarTool(item) then break end
                    end

                    if not toolEquipada and backpack then
                        for _, item in ipairs(backpack:GetChildren()) do
                            if verificarTool(item) then break end
                        end
                    end

                    if toolEquipada and killEvent then
                        if toolEquipada.Parent ~= character then
                            local humanoid = character:FindFirstChildOfClass("Humanoid")
                            if humanoid then
                                humanoid:EquipTool(toolEquipada)
                                task.wait(0.1)
                            end
                        end

                        if toolEquipada.Parent == character then
                            local enemyHumanoid = objetivoRoot.Parent:FindFirstChildOfClass("Humanoid")
                            if enemyHumanoid and enemyHumanoid.Health > 0 then
                                pcall(function()
                                    local destino = objetivoRoot.Position - Vector3.new(0, 3.5, 0)
                                    if (rootPart.Position - destino).Magnitude > 1 then
                                        rootPart.CFrame = CFrame.new(destino, objetivoRoot.Position)
                                    end
                                    killEvent:FireServer(enemyHumanoid)
                                    toolEquipada:Activate()
                                end)
                            end
                        end
                    end
                end
            else
                objetivoActual = nil
            end
        else
            objetivoActual = nil
            task.wait(0.3)
        end
    end
end)

local autoShootCuchilloEnabled = false
local autoShootTargetPart = "Cabeza"
local isAttackingWithKnife = false

local predictionPart = Instance.new("Part")
predictionPart.Name = "YisusPredictionPart"
predictionPart.Size = Vector3.new(0.2, 0.2, 0.2)
predictionPart.Transparency = 1
predictionPart.Anchored = true
predictionPart.CanCollide = false
predictionPart.CanQuery = false
predictionPart.CanTouch = false
predictionPart.Parent = Workspace

pcall(function() getgenv().YisusTargetPart = nil end)

local excludedGunNameParts = {
    "combat", "fist", "wallet", "phone", "punch", "boombox", "radio",
    "knife", "blade", "cuchillo", "dagger", "kunai", "sword", "toy",
    "juguete", "pizza", "burger", "teddy", "balloon", "drink", "food",
}

local function esLaPistola(item)
    if not item:IsA("Tool") then return false end
    if item:FindFirstChild("Throw", true) or item:FindFirstChild("KnifeClient", true) or item:FindFirstChild("KnifeServer", true) then return false end
    local nombre = string.lower(item.Name)
    for _, palabra in ipairs(excludedGunNameParts) do
        if string.find(nombre, palabra) then return false end
    end
    return true
end

if hookmetamethod and checkcaller then
    local oldNamecallKnife
    oldNamecallKnife = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if not checkcaller() and getgenv().YisusTargetPart and isAttackingWithKnife then
            local target = getgenv().YisusTargetPart
            if target and target.Parent then
                if method == "Raycast" and self == Workspace then
                    local origin, direction, p3 = ...
                    if typeof(direction) == "Vector3" then
                        local newDir = (target.Position - origin).Unit * 8000
                        return oldNamecallKnife(self, origin, newDir, p3)
                    end
                elseif string.find(method, "FindPartOnRay") and self == Workspace then
                    local ray, p2, p3, p4 = ...
                    if typeof(ray) == "Ray" then
                        local newRay = Ray.new(ray.Origin, (target.Position - ray.Origin).Unit * 8000)
                        return oldNamecallKnife(self, newRay, p2, p3, p4)
                    end
                end
            end
        end
        return oldNamecallKnife(self, ...)
    end)

    local oldIndexKnife
    oldIndexKnife = hookmetamethod(game, "__index", function(t, k)
        if not checkcaller() and t == Mouse and getgenv().YisusTargetPart and isAttackingWithKnife then
            if k == "Hit" or k == "hit" then return getgenv().YisusTargetPart.CFrame
            elseif k == "Target" or k == "target" then return getgenv().YisusTargetPart end
        end
        return oldIndexKnife(t, k)
    end)
end

local knifeHeadParts = {"HumanoidRootPart", "Head", "UpperTorso", "Torso"}
local knifeTorsoParts = {"HumanoidRootPart", "UpperTorso", "Torso", "LowerTorso"}
local knifeFullBodyParts = {
    "HumanoidRootPart", "Head", "UpperTorso", "LowerTorso", "Torso",
    "LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg",
    "LeftArm", "RightArm", "LeftLeg", "RightLeg",
}

task.spawn(function()
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude

    while true do
        if autoShootCuchilloEnabled then
            local char = player.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then
                getgenv().YisusTargetPart = nil
                isAttackingWithKnife = false
                task.wait(0.01)
                continue
            end

            local arma = char:FindFirstChildOfClass("Tool")
            if not arma or not arma:FindFirstChild("Handle") or esLaPistola(arma) then
                getgenv().YisusTargetPart = nil
                isAttackingWithKnife = false
                task.wait(0.01)
                continue
            end

            local hum = char:FindFirstChildOfClass("Humanoid")
            local myPos = char.HumanoidRootPart.Position
            local origin = (char:FindFirstChild("Head") and hum and hum.FloorMaterial ~= Enum.Material.Air) and char.Head.Position or myPos

            local objetivosPotenciales = {}
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= player and isEnemy(p) and p.Character then
                    local enemyHum = p.Character:FindFirstChild("Humanoid")
                    if enemyHum and enemyHum.Health > 0 then
                        local partesAEscanear = autoShootTargetPart == "Cabeza" and knifeHeadParts
                            or (autoShootTargetPart == "Torso" and knifeTorsoParts or knifeFullBodyParts)

                        for _, partName in ipairs(partesAEscanear) do
                            local part = p.Character:FindFirstChild(partName)
                            if part and part:IsA("BasePart") then
                                table.insert(objetivosPotenciales, {
                                    Part = part,
                                    Dist = (part.Position - myPos).Magnitude,
                                    Char = p.Character,
                                    Priority = (partName == "HumanoidRootPart") and 0 or 1
                                })
                            end
                        end
                    end
                end
            end

            table.sort(objetivosPotenciales, function(a, b)
                if a.Priority ~= b.Priority then return a.Priority < b.Priority end
                return a.Dist < b.Dist
            end)

            local closestTargetPart, closestEnemyChar = nil, nil
            for _, obj in ipairs(objetivosPotenciales) do
                local part = obj.Part
                params.FilterDescendantsInstances = {char, obj.Char}

                local sizeX, sizeY = part.Size.X / 2.05, part.Size.Y / 2.05
                local cf = part.CFrame

                local visible = not Workspace:Raycast(origin, cf.Position - origin, params)
                    or not Workspace:Raycast(origin, (cf * CFrame.new(sizeX, 0, 0)).Position - origin, params)
                    or not Workspace:Raycast(origin, (cf * CFrame.new(-sizeX, 0, 0)).Position - origin, params)
                    or not Workspace:Raycast(origin, (cf * CFrame.new(0, sizeY, 0)).Position - origin, params)
                    or not Workspace:Raycast(origin, (cf * CFrame.new(0, -sizeY, 0)).Position - origin, params)

                if visible then
                    closestTargetPart = part
                    closestEnemyChar = obj.Char
                    break
                end
            end

            if closestTargetPart and closestEnemyChar then
                local enemyHRP = closestEnemyChar:FindFirstChild("HumanoidRootPart")
                local finalTarget = closestTargetPart

                if enemyHRP then
                    local velocity = enemyHRP.AssemblyLinearVelocity
                    if velocity.Magnitude > 0.5 then
                        predictionPart.CFrame = CFrame.new(enemyHRP.Position + (velocity * ((hum and hum.FloorMaterial == Enum.Material.Air) and 0.18 or 0.12)))
                        finalTarget = predictionPart
                    else
                        finalTarget = enemyHRP
                    end
                end

                getgenv().YisusTargetPart = finalTarget
                isAttackingWithKnife = true
                pcall(function()
                    arma:Activate()
                    task.delay(0.002, function()
                        if arma.Parent == char then arma:Deactivate() end
                        isAttackingWithKnife = false
                    end)
                end)
                task.wait(0.003)
            else
                getgenv().YisusTargetPart = nil
                isAttackingWithKnife = false
                task.wait(0.01)
            end
        else
            getgenv().YisusTargetPart = nil
            isAttackingWithKnife = false
            task.wait(0.05)
        end
    end
end)

AimTab:Toggle({
    Title = "Auto Shoot (Cuchillo)",
    Value = false,
    Callback = function(Value)
        autoShootCuchilloEnabled = Value
        if not Value then
            getgenv().YisusTargetPart = nil
            isAttackingWithKnife = false
        end
    end,
})

AimTab:Dropdown({
    Title = "Target: Parte del cuerpo",
    Values = {"Cabeza", "Torso", "Cuerpo Completo"},
    Value = "Cabeza",
    Callback = function(Value) autoShootTargetPart = Value end,
})

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local event = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Networking"):WaitForChild("RE/Match/SetStatePlr")

local TeleportTab = Window:Tab({ Title = "Auto Partida", Icon = "plane" })
TeleportTab:Section({ Title = "Pad" })

local mainRunning = false
local altRunning = false
local mainTeleportLoopRunning = false
local altTeleportLoopRunning = false

local function checkAndFireMenu()
    local mainScreen = PlayerGui:FindFirstChild("Main")
    if mainScreen and mainScreen:FindFirstChild("MainGameFrame") and mainScreen.MainGameFrame:FindFirstChild("GameStats") then
        pcall(function()
            event:FireServer("REMOVE")
        end)
    end
end

local function getTargetPosition(obj)
    if obj:IsA("Model") then return obj:GetPivot().Position
    elseif obj:IsA("BasePart") then return obj.Position end
    return nil
end

local function handleTeleportPad(isMain)
    if isMain then
        if mainTeleportLoopRunning then return end
        mainTeleportLoopRunning = true
    else
        if altTeleportLoopRunning then return end
        altTeleportLoopRunning = true
    end

    task.spawn(function()
        while (isMain and mainRunning) or (not isMain and altRunning) do
            checkAndFireMenu()

            local character = LocalPlayer.Character
            local rootPart = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChild("Humanoid")
            
            if not rootPart or not humanoid then
                task.wait(1)
                continue
            end

            local padZones = workspace:FindFirstChild("PadZones")
            local targetPart = padZones and padZones:FindFirstChild("PadZone1") and padZones.PadZone1:FindFirstChild(isMain and "Pad1" or "Pad2")

            if targetPart then
                local targetPos = getTargetPosition(targetPart)
                if targetPos then
                    targetPos += Vector3.new(0, 3, 0)
                    humanoid:MoveTo(targetPos)
                    
                    while ((isMain and mainRunning) or (not isMain and altRunning)) and character and rootPart and targetPart do
                        checkAndFireMenu()

                        local currentTargetPos = getTargetPosition(targetPart)
                        if not currentTargetPos then break end
                        
                        currentTargetPos += Vector3.new(0, 3, 0)
                        local direction = currentTargetPos - rootPart.Position
                        local distance = direction.Magnitude
                        
                        if distance < 1.5 then 
                            break
                        else
                            local dt = RunService.RenderStepped:Wait()
                            rootPart.CFrame += direction.Unit * math.min(40 * dt, distance)
                        end
                    end
                end
            end
            task.wait(0.5)
        end

        if isMain then
            mainTeleportLoopRunning = false
        else
            altTeleportLoopRunning = false
        end
    end)
end

TeleportTab:Toggle({
    Title = "Auto teleport Main",
    Desc = "Yisus",
    Value = false,
    Callback = function(state)
        mainRunning = state
        if state then handleTeleportPad(true) end
    end
})

TeleportTab:Toggle({
    Title = "Auto teleport ALT",
    Desc = "Yisus",
    Value = false,
    Callback = function(state)
        altRunning = state
        if state then handleTeleportPad(false) end
    end
})


local InvisActive = false
local InvisFrame, InvisBtn, InvisStroke
local Theme = {
    Ghost = Color3.fromRGB(140, 50, 255)
}

local InvisGui = Instance.new("ScreenGui")
InvisGui.Name = "NexusInvisBtn"
InvisGui.Parent = game:GetService("CoreGui")
InvisGui.IgnoreGuiInset = true
InvisGui.ResetOnSpawn = false

InvisFrame = Instance.new("Frame")
InvisFrame.Parent = InvisGui
InvisFrame.Size = UDim2.new(0, 80, 0, 30)
InvisFrame.Position = UDim2.new(0.7, 0, 0.6, 0)
InvisFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
InvisFrame.BackgroundTransparency = 0.5
InvisFrame.BorderSizePixel = 0
InvisFrame.Visible = false

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 6)
corner.Parent = InvisFrame

InvisStroke = Instance.new("UIStroke")
InvisStroke.Parent = InvisFrame
InvisStroke.Color = Theme.Ghost
InvisStroke.Thickness = 1.5

InvisBtn = Instance.new("TextButton")
InvisBtn.Parent = InvisFrame
InvisBtn.Size = UDim2.new(1, 0, 1, 0)
InvisBtn.BackgroundTransparency = 1
InvisBtn.Text = "INVISIBLE"
InvisBtn.TextColor3 = Theme.Ghost
InvisBtn.Font = Enum.Font.GothamBlack
InvisBtn.TextSize = 11

local function SetInvisState(state)
    InvisFrame.Visible = state
    
    if not state then
        InvisActive = false
        InvisBtn.Text = "INVISIBLE"
        InvisBtn.TextColor3 = Theme.Ghost
        InvisStroke.Color = Theme.Ghost
        
        if game.Players.LocalPlayer.Character then
            for _, v in pairs(game.Players.LocalPlayer.Character:GetDescendants()) do
                if v:IsA("BasePart") and v.Transparency == 0.5 then
                    v.Transparency = 0
                end
            end
        end
    end
end

local function ToggleInvis()
    if not InvisFrame.Visible then return end
    InvisActive = not InvisActive
    
    if InvisActive then
        InvisBtn.Text = "ACTIVE"
        InvisBtn.TextColor3 = Color3.fromRGB(0, 255, 100)
        InvisStroke.Color = Color3.fromRGB(0, 255, 100)
        
        if game.Players.LocalPlayer.Character then
            for _, v in pairs(game.Players.LocalPlayer.Character:GetDescendants()) do
                if v:IsA("BasePart") and v.Transparency == 0 then
                    v.Transparency = 0.5
                end
            end
        end
    else
        InvisBtn.Text = "INVISIBLE"
        InvisBtn.TextColor3 = Theme.Ghost
        InvisStroke.Color = Theme.Ghost
        
        if game.Players.LocalPlayer.Character then
            for _, v in pairs(game.Players.LocalPlayer.Character:GetDescendants()) do
                if v:IsA("BasePart") and v.Transparency == 0.5 then
                    v.Transparency = 0
                end
            end
        end
    end
end

InvisBtn.MouseButton1Click:Connect(ToggleInvis)

-- Bucle Heartbeat con la estructura original idéntica
game:GetService("RunService").Heartbeat:Connect(function()
    if InvisActive and InvisFrame.Visible then
        local Char = game.Players.LocalPlayer.Character
        if Char then
            local Root = Char:FindFirstChild("HumanoidRootPart")
            local Hum = Char:FindFirstChild("Humanoid")
            
            if Root and Hum then
                -- Si estás en la zona alta del lobby, simplemente salta el truco de void en este frame sin romper el bucle
                if Root.Position.Y > 200 then return end
                
                local oldCF = Root.CFrame
                local oldCamOffset = Hum.CameraOffset
                
                local invisCF = oldCF * CFrame.new(0, -200000, 0)
                Root.CFrame = invisCF
                Hum.CameraOffset = invisCF:ToObjectSpace(CFrame.new(oldCF.Position)).Position
                
                game:GetService("RunService").RenderStepped:Wait()
                
                if Root and Root.Parent then
                    Root.CFrame = oldCF
                    Hum.CameraOffset = oldCamOffset
                end
            end
        end
    end
end)

game.Players.LocalPlayer.CharacterAdded:Connect(function(character)
    if InvisFrame.Visible then
        InvisActive = false
        InvisBtn.Text = "INVISIBLE"
        InvisBtn.TextColor3 = Theme.Ghost
        InvisStroke.Color = Theme.Ghost
    end
end)

task.spawn(function()
    local TweenService = game:GetService("TweenService")
    while true do
        if InvisFrame and InvisFrame.Visible and not InvisActive then
            local t1 = TweenService:Create(InvisStroke, TweenInfo.new(1, Enum.EasingStyle.Sine), {Transparency = 0.4})
            t1:Play()
            t1.Completed:Wait()
            
            local t2 = TweenService:Create(InvisStroke, TweenInfo.new(1, Enum.EasingStyle.Sine), {Transparency = 0})
            t2:Play()
            t2.Completed:Wait()
        else
            task.wait(0.5)
        end
    end
end)

AimTab:Toggle({
    Title = "Invisible",
    Desc = "YisusHub.",
    Value = false,
    Callback = function(Value)
        SetInvisState(Value)
    end,
})

local AnimsTab = Window:Tab({ Title = "Animaciones", Icon = "user" })
AnimsTab:Section({Title = "Packs de Animaciones"})

local dropdownRef
local packActualActivo = nil
local animationNames = {
    idle2 = "Animation2",
    idle3 = "Animation3",
    swimidle = "SwimIdle",
    walk = "WalkAnim",
    run = "RunAnim",
    jump = "JumpAnim",
    fall = "FallAnim",
    climb = "ClimbAnim",
    toolnone = "ToolNoneAnim",
    toolslash = "ToolSlashAnim",
    toollunge = "ToolLungeAnim",
    sit = "SitAnim",
    wave = "WaveAnim",
    point = "PointAnim",
    cheer = "CheerAnim",
    laugh = "LaughAnim",
    stylishpose = "StylishPose",
    ninjapose = "NinjaPose",
    elderpose = "ElderPose",
}

local function aplicarPackAnimaciones(idsPack)
    task.spawn(function()
        local character = player.Character or player.CharacterAdded:Wait()
        local animateScript = character:WaitForChild("Animate", 5)
        if not animateScript then return end

        animateScript.Disabled = true

        for nombre, id in pairs(idsPack) do
            local carpeta = animateScript:FindFirstChild(nombre)
                or animateScript:FindFirstChild(nombre:gsub("^%l", string.upper) .. "Anim")
                or animateScript:FindFirstChild(nombre:upper())

            if carpeta then
                local nombreAnim = animationNames[nombre] or "Animation1"
                local anim = carpeta:FindFirstChild(nombreAnim)
                if anim and anim:IsA("Animation") then anim.AnimationId = id end
            end
        end

        local function limpiarPose(nombreCarpeta, nombreAnim)
            local carpeta = animateScript:FindFirstChild(nombreCarpeta)
            if carpeta then
                local anim = carpeta:FindFirstChild(nombreAnim)
                if anim and anim:IsA("Animation") then anim.AnimationId = "" end
            end
        end

        limpiarPose("stylishpose", "StylishPose")
        limpiarPose("ninjapose", "NinjaPose")
        limpiarPose("elderpose", "ElderPose")
        task.wait()
        animateScript.Disabled = false
    end)
end

player.CharacterAdded:Connect(function()
    if packActualActivo then aplicarPackAnimaciones(packActualActivo) end
end)

local packsAnimaciones = {
    Ninja = { walk = "rbxassetid://10921162768", run = "rbxassetid://10921157929", jump = "rbxassetid://10921160088", fall = "rbxassetid://10921159222", climb = "rbxassetid://10921154678", idle = "rbxassetid://10921155160", ninjapose = "rbxassetid://10921156883", toolnone = "rbxassetid://507768375", toollunge = "rbxassetid://522638767", toolslash = "rbxassetid://522635514", swim = "rbxassetid://10922757002", sit = "rbxassetid://2506281703", cheer = "rbxassetid://507770677", laugh = "rbxassetid://507770818", wave = "rbxassetid://507770239", point = "rbxassetid://507770453" },
    Zombie = { walk = "rbxassetid://10921355261", run = "rbxassetid://616163682", jump = "rbxassetid://10921351278", fall = "rbxassetid://10921350320", climb = "rbxassetid://10921343576", toolnone = "rbxassetid://507768375", idle = "rbxassetid://10921347258" },
    Stylish = { walk = "rbxassetid://109168724482748", run = "rbxassetid://81024476153754", jump = "rbxassetid://116936326516985", fall = "rbxassetid://92294537340807", climb = "rbxassetid://119377220967554", idle = "rbxassetid://133806214992291", stylishpose = "rbxassetid://87105332133518", toolnone = "rbxassetid://507768375", toollunge = "rbxassetid://522638767", toolslash = "rbxassetid://522635514", swim = "rbxassetid://134591743181628", swimidle = "rbxassetid://98854111361360", sit = "rbxassetid://2506281703", cheer = "rbxassetid://507770677", laugh = "rbxassetid://507770818", wave = "rbxassetid://507770239", point = "rbxassetid://507770453" },
    Ghost = { walk = "rbxassetid://122150855457006", run = "rbxassetid://82598234841035", jump = "rbxassetid://75290611992385", fall = "rbxassetid://98600215928904", climb = "rbxassetid://88763136693023", idle = "rbxassetid://122257458498464", stylishpose = "rbxassetid://89262795687364", toolnone = "rbxassetid://507768375", toollunge = "rbxassetid://522638767", toolslash = "rbxassetid://522635514", swim = "rbxassetid://133308483266208", swimidle = "rbxassetid://109346520324160", sit = "rbxassetid://2506281703", cheer = "rbxassetid://507770677", laugh = "rbxassetid://507770818", wave = "rbxassetid://507770239", point = "rbxassetid://507770453" },
    Mage = { walk = "rbxassetid://84782014405060", run = "rbxassetid://85232146719894", jump = "rbxassetid://140300561900880", fall = "rbxassetid://129591520941189", climb = "rbxassetid://94364927317793", idle = "rbxassetid://133226513780673", toolnone = "rbxassetid://507768375", toollunge = "rbxassetid://522638767", toolslash = "rbxassetid://522635514", swim = "rbxassetid://117741052845105", swimidle = "rbxassetid://133871172755161", sit = "rbxassetid://2506281703", cheer = "rbxassetid://507770677", laugh = "rbxassetid://507770818", wave = "rbxassetid://507770239", point = "rbxassetid://507770453" },
    Levitation = { walk = "rbxassetid://83842218823011", run = "rbxassetid://118320322718866", jump = "rbxassetid://109996626521204", fall = "rbxassetid://95603166884636", climb = "rbxassetid://97824616490448", idle = "rbxassetid://110211186840347", stylishpose = "rbxassetid://99129837931148", toolnone = "rbxassetid://507768375", toollunge = "rbxassetid://522638767", toolslash = "rbxassetid://522635514", swim = "rbxassetid://134530128383903", swimidle = "rbxassetid://94922130551805", sit = "rbxassetid://2506281703", cheer = "rbxassetid://507770677", laugh = "rbxassetid://507770818", wave = "rbxassetid://507770239", point = "rbxassetid://507770453" },
    Elder = { walk = "rbxassetid://10921111375", run = "rbxassetid://10921104374", jump = "rbxassetid://10921107367", fall = "rbxassetid://10921105765", climb = "rbxassetid://10921100400", idle = "rbxassetid://10921101664", elderpose = "rbxassetid://10921103538", toolnone = "rbxassetid://507768375", toollunge = "rbxassetid://522638767", toolslash = "rbxassetid://522635514", swim = "rbxassetid://10921108971", swimidle = "rbxassetid://1092110146", sit = "rbxassetid://2506281703", cheer = "rbxassetid://507770677", laugh = "rbxassetid://507770818", wave = "rbxassetid://507770239", point = "rbxassetid://507770453" },
    Bicicleta = { walk = "rbxassetid://98707881660541", run = "rbxassetid://102775737211919", jump = "rbxassetid://129144847881258", fall = "rbxassetid://110684787086498", climb = "rbxassetid://88267082364595", idle = "rbxassetid://126390120399173", idle2 = "rbxassetid://136791517336633", idle3 = "rbxassetid://14366558676", swim = "rbxassetid://116700888013068", swimidle = "rbxassetid://87621024705272", toolnone = "rbxassetid://507768375", toollunge = "rbxassetid://522638767", toolslash = "rbxassetid://522635514", sit = "rbxassetid://2506281703", cheer = "rbxassetid://507770677", laugh = "rbxassetid://507770818", wave = "rbxassetid://507770239", point = "rbxassetid://507770453" },
    Bubbly = { walk = "rbxassetid://90478085024465", run = "rbxassetid://134824450619865", jump = "rbxassetid://121454505477205", fall = "rbxassetid://94788218468396", climb = "rbxassetid://12114583950231", idle = "rbxassetid://98281136301627", swim = "rbxassetid://105962919001086", swimidle = "rbxassetid://129126268464847", stylishpose = "rbxassetid://133117300343405", toolnone = "rbxassetid://507768375", toollunge = "rbxassetid://522638767", toolslash = "rbxassetid://522635514", sit = "rbxassetid://2506281703", cheer = "rbxassetid://507770677", laugh = "rbxassetid://507770818", wave = "rbxassetid://507770239", point = "rbxassetid://507770453" }
}

dropdownRef = AnimsTab:Dropdown({
    Title = "Seleccionar Pack",
    Values = {"Ninguno", "Ninja", "Zombie", "Stylish", "Ghost", "Mage", "Levitation", "Elder", "Bicicleta", "Bubbly"},
    Value = "Ninguno",
    Callback = function(Value)
        if Value == "Ninguno" then
            packActualActivo = nil
            return
        end
        local pack = packsAnimaciones[Value]
        if pack then
            packActualActivo = pack
            aplicarPackAnimaciones(pack)
            task.delay(0.2, function()
                if dropdownRef and dropdownRef.Set then dropdownRef:Set("Ninguno") end
            end)
        end
    end
})

AnimsTab:Section({ Title = "Emotes" })
local EmoteTrack
local EmoteAnimation
local Emotes = {
    ["YB Jump"] = "15609995579",
    ["Dance"] = "10714340543",
    ["Bubly"] = "93120341268524",
    ["Baile"] = "114774556469581",
    ["Baile2"] = "88050523705839",
    ["mediohueva"] = "92747295139963",
    ["Baile3"] = "104748118296461",
    ["Elmejordetodos"] = "74430100028293",
    ["Emote1"] = "82238508652742",
}

local function StopEmote()
    if EmoteTrack then
        EmoteTrack:Stop()
        EmoteTrack:Destroy()
        EmoteTrack = nil
    end
    if EmoteAnimation then
        EmoteAnimation:Destroy()
        EmoteAnimation = nil
    end
end

local function PlayEmote(AnimationId)
    StopEmote()
    local Character = player.Character or player.CharacterAdded:Wait()
    local Humanoid = Character:WaitForChild("Humanoid")
    local Animator = Humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", Humanoid)

    local Animation = Instance.new("Animation")
    Animation.AnimationId = "rbxassetid://" .. AnimationId
    EmoteAnimation = Animation

    EmoteTrack = Animator:LoadAnimation(Animation)
    EmoteTrack.Priority = Enum.AnimationPriority.Action
    EmoteTrack.Looped = true
    EmoteTrack:Play()
end

if player.Character then
    player.Character:WaitForChild("Humanoid").Running:Connect(function(speed)
        if speed > 0 then StopEmote() end
    end)
end
player.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid").Running:Connect(function(speed)
        if speed > 0 then StopEmote() end
    end)
end)

AnimsTab:Dropdown({
    Title = "Seleccionar Emote",
    Values = {"Ninguno", "YB Jump", "Dance", "Bubly", "Baile", "Baile2", "mediohueva", "Baile3", "Elmejordetodos", "Emote1"},
    Value = "Ninguno",
    Callback = function(Value)
        if Value == "Ninguno" then StopEmote()
        else PlayEmote(Emotes[Value]) end
    end
})

local PerformanceTab = Window:Tab({ Title = "Fps", Icon = "gauge" })
local PerformanceSection = PerformanceTab:Section({ Title = "Turbo FPS" })
local turboDescendantConnection

PerformanceSection:Toggle({
    Title = " Turbo FPS",
    Desc = "Optimiza los gráficos para mejorar el rendimiento.",
    Value = false,
    Callback = function(Value)
        if Value then
            local Lighting = game:GetService("Lighting")
            local Terrain = workspace:FindFirstChildOfClass("Terrain")

            Lighting.GlobalShadows = false
            Lighting.Brightness = 1
            Lighting.EnvironmentDiffuseScale = 0
            Lighting.EnvironmentSpecularScale = 0
            Lighting.FogEnd = math.huge
            Lighting.ClockTime = 14

            pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)

            if Terrain then
                Terrain.WaterWaveSize = 0
                Terrain.WaterWaveSpeed = 0
                Terrain.WaterReflectance = 0
                Terrain.WaterTransparency = 1
            end

            for _, v in ipairs(Lighting:GetChildren()) do
                if v:IsA("PostEffect") then v.Enabled = false end
            end

            local function optimizar(obj)
                if obj:IsA("BasePart") then
                    obj.Material = Enum.Material.SmoothPlastic
                    obj.CastShadow = false
                    obj.Reflectance = 0
                elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
                    obj.Enabled = false
                elseif obj:IsA("Explosion") then
                    obj.BlastPressure = 0
                    obj.BlastRadius = 0
                end
            end

            for _, v in ipairs(workspace:GetDescendants()) do optimizar(v) end
            if not turboDescendantConnection then
                turboDescendantConnection = workspace.DescendantAdded:Connect(optimizar)
            end
        elseif turboDescendantConnection then
            turboDescendantConnection:Disconnect()
            turboDescendantConnection = nil
        end
    end
})

local SettingsTab = Window:Tab({ Title = "Configuración", Icon = "palette" })
SettingsTab:Section({ Title = "Temas" })

SettingsTab:Dropdown({
    Title = "Seleccionar Tema",
    Values = {"Negro", "Medianoche", "Rojo", "Rojo Carmesí", "Ámbar", "Rosa", "Esmeralda", "Cielo", "Violeta", "Blanco", "Arcoíris", "Planta", "Índigo", "Suave"},
    Value = "Negro",
    Callback = function(Theme)
        local Themes = {
            ["Negro"] = "Dark", ["Medianoche"] = "Midnight", ["Rojo"] = "Red", ["Rojo Carmesí"] = "Crimson",
            ["Ámbar"] = "Amber", ["Rosa"] = "Rose", ["Esmeralda"] = "Emerald", ["Cielo"] = "Sky",
            ["Violeta"] = "Violet", ["Blanco"] = "Light", ["Arcoíris"] = "Rainbow", ["Planta"] = "Plant",
            ["Índigo"] = "Indigo", ["Suave"] = "Mellowsi"
        }
        WindUI:SetTheme(Themes[Theme])
        WindUI:Notify({ Title = "Tema", Content = "Tema aplicado: " .. Theme, Duration = 2 })
    end
})

local InfoTab = Window:Tab({ Title = "Información", Icon = "info" })
InfoTab:Paragraph({
    Title = "📢 Información Importante",
    Desc = [[
El uso excesivo de Kill Aura o AutoShot puede aumentar el riesgo de sanciones.
 Estas funciones aún se encuentran en proceso de optimización para mejorar su estabilidad y funcionamiento.
💬 Si encuentras errores o tienes sugerencias, únete a nuestro servidor de Discord.
❤️ ¡Gracias por usar Alexx Hub!
]]
})

InfoTab:Button({
    Title = "📋 Copiar enlace de Discord",
    Desc = "Únete a nuestro servidor oficial",
    Callback = function()
        local Link = "https://discord.gg/eQa4HsgVKk"
        if setclipboard then
            setclipboard(Link)
            WindUI:Notify({ Title = "✅ Enlace copiado", Content = "El enlace de Discord se copió al portapapeles.", Duration = 3, Icon = "clipboard" })
        else
            WindUI:Notify({ Title = "❌ Error", Content = "Tu executor no admite copiar al portapapeles.", Duration = 3, Icon = "triangle-alert" })
        end
    end
})
