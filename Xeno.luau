--[[
zlib
Copyright (c) 2026 .hilkach.
This software is provided 'as-is', without any express or implied warranty.
In no event will the authors be held liable for any damages arising from
the use of this software.
Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:
1. The origin of this software must not be misrepresented; you must not
   claim that you wrote the original software. If you use this software
   in a product, an acknowledgment in the product documentation would be
   appreciated but is not required.
2. Altered source versions must be plainly marked as such, and must not be
   misrepresented as being the original software.
3. This notice may not be removed or altered from any source distribution.
]]

local freecamActive = false
local rightMousePressed = false
local fovCircle = nil
local RunService = game:GetService("RunService")
local flyActive = false
local noclipActive = false
local noclipConnection = nil

-- unload function
if _G.XenoUnload then _G.XenoUnload() end
local scriptRunning = true
local allConnections = {}
local ESPObjects = {}
local deleteHistory = {}

-- settings
local settings = {
    fly = false, flySpeed = 0.8,
    walkBoost = false, walkPower = 0.5,
    jumpBoost = false, jumpPower = 3.5,
    noJumpCooldown = false,
    espHighlight = false, espHighlightColor = Color3.fromRGB(0, 60, 150),
    espName = false, espBox = false, espHealth = false,
    fullbright = false,
    noclip = false,
    hitbox = false, hitboxSize = 5,
    freecam = false,
    aimbot = false,
    aimbotFov = 90,
    aimbotSmoothness = 5,
    aimPart = "Head",
    showFovCircle = false,
    aimOnKey = false,
    wallCheck = false,
    teamCheck = false,
    aimKey = Enum.UserInputType.MouseButton2,
    gravityEnabled = false,
    gravityValue = 50,
    teleportToMouse = false
}

local function clearAllESP()
    for _, objList in pairs(ESPObjects) do
        for _, obj in pairs(objList) do
            pcall(function() obj:Destroy() end)
        end
    end
    ESPObjects = {}

    local PlayersService = game:GetService("Players")
    for _, p in pairs(PlayersService:GetPlayers()) do
        if p.Character then
            local c = p.Character
            if c:FindFirstChild("XenoESP_Highlight") then c.XenoESP_Highlight:Destroy() end
            if c:FindFirstChild("XenoESP_Name") then c.XenoESP_Name:Destroy() end
            local root = c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso")
            if root then
                if root:FindFirstChild("XenoESP_Box") then root.XenoESP_Box:Destroy() end
                if root:FindFirstChild("XenoESP_Health") then root.XenoESP_Health:Destroy() end
            end
        end
    end
end


local function restoreAllDeleted()
    if deleteHistory and #deleteHistory > 0 then
        print("🔄 Restoring " .. #deleteHistory .. " deleted objects...")
        while #deleteHistory > 0 do
            local data = table.remove(deleteHistory)
            pcall(function()
                local newPart = data.clone:Clone()
                for prop, val in pairs(data.props) do
                    newPart[prop] = val
                end
                newPart.Parent = data.props.Parent
            end)
        end
        print("✅ All objects restored!")
    end
end


local function resetAllSettings()

    workspace.Gravity = 196.2
    

    local Lighting = game:GetService("Lighting")
    Lighting.Brightness = 1
    Lighting.GlobalShadows = true

    local cam = workspace.CurrentCamera
    cam.CameraType = Enum.CameraType.Custom


    local player = game.Players.LocalPlayer
    local char = player.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.Anchored = false
            hrp.Velocity = Vector3.zero
        end

        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end

        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = 16
            hum.JumpPower = 50
        end
    end


    local PlayersService = game:GetService("Players")
    for _, p in pairs(PlayersService:GetPlayers()) do
        if p ~= player and p.Character then
            local head = p.Character:FindFirstChild("Head")
            if head then
                head.Size = Vector3.new(2, 1, 1)
                head.Transparency = 0
                head.CanCollide = true
            end
        end
    end


    if freecamActive then
        RunService:UnbindFromRenderStep("Freecam")
        freecamActive = false
        rightMousePressed = false
        UIS.MouseBehavior = Enum.MouseBehavior.Default
    end


    if fovCircle then
        pcall(function() fovCircle:Remove() end)
        fovCircle = nil
    end


    flyActive = false
    settings.fly = false

    settings.walkBoost = false
    settings.walkPower = 0.5

    settings.jumpBoost = false
    settings.jumpPower = 3.5


    if noclipActive then
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
        noclipActive = false
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
    settings.noclip = false

    settings.fullbright = false
    Lighting.Brightness = 1
    Lighting.GlobalShadows = true


    settings.gravityEnabled = false
    settings.gravityValue = 50
    workspace.Gravity = 196.2
end


_G.XenoUnload = function()
    if not scriptRunning then return end
    scriptRunning = false

    print("🔄 Unloading XENO DARK...")


    restoreAllDeleted()


    resetAllSettings()


    for _, conn in pairs(allConnections) do
        pcall(function() conn:Disconnect() end)
    end
    allConnections = {}

    clearAllESP()


    local player = game.Players.LocalPlayer
    local gui = player.PlayerGui:FindFirstChild("MinimalUI")
    if gui then gui:Destroy() end

    local splash = player.PlayerGui:FindFirstChild("MinimalUILoader")
    if splash then splash:Destroy() end


    if fovCircle then
        pcall(function() fovCircle:Remove() end)
        fovCircle = nil
    end

    _G.XenoUnload = nil
    print("✅ XENO DARK: Fully Unloaded!")
end

-- loading logo
local player = game.Players.LocalPlayer
local splashGui = Instance.new("ScreenGui")
splashGui.Name = "MinimalUILoader"
splashGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
splashGui.ResetOnSpawn = false
splashGui.Parent = player.PlayerGui

local splashContainer = Instance.new("Frame")
splashContainer.Name = "SplashContainer"
splashContainer.Size = UDim2.new(1, 0, 1, 0)
splashContainer.BackgroundTransparency = 1
splashContainer.Parent = splashGui

local splashIcon = Instance.new("ImageLabel")
splashIcon.Name = "SplashIcon"
splashIcon.Size = UDim2.new(0, 150, 0, 150)
splashIcon.Position = UDim2.new(0.5, -75, 0.5, -75)
splashIcon.BackgroundTransparency = 1
splashIcon.Image = "rbxassetid://78139268098085"
splashIcon.ImageTransparency = 1
splashIcon.ScaleType = Enum.ScaleType.Fit
splashIcon.Parent = splashContainer

local tweenService = game:GetService("TweenService")
local fadeIn = tweenService:Create(splashIcon, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 0.3})
local fadeOut = tweenService:Create(splashIcon, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {ImageTransparency = 1})
fadeIn:Play()
task.wait(0.8)
task.wait(0.5)

-- library
local MinimalUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Hilka-dilka/MinimalUI/main/MinimalUI.lua"))()

local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local cam = workspace.CurrentCamera
local Players = game:GetService("Players")
local mouse = player:GetMouse()

-- freecam
local pi, rad, clamp, exp = math.pi, math.rad, math.clamp, math.exp
local NAV_GAIN = Vector3.new(1, 1, 1)*64
local PAN_GAIN = Vector2.new(0.2, 0.2)*0.8
local FOV_GAIN = 300
local PITCH_LIMIT = rad(90)

local Spring = {}
Spring.__index = Spring
function Spring.new(freq, pos) 
    return setmetatable({f = freq, p = pos, v = pos*0}, Spring) 
end

function Spring:Update(dt, goal)
    local f = self.f*2*pi
    local offset = goal - self.p
    local decay = exp(-f*dt)
    local p1 = goal + (self.v*dt - offset*(f*dt + 1))*decay
    local v1 = (f*dt*(offset*f - self.v) + self.v)*decay
    self.p, self.v = p1, v1
    return p1
end

function Spring:Reset(pos) 
    self.p = pos
    self.v = pos*0 
end

local cameraPos, cameraRot, cameraFov = Vector3.new(), Vector2.new(), 70
local velSpring, panSpring, fovSpring = Spring.new(1.5, Vector3.new()), Spring.new(1.0, Vector2.new()), Spring.new(4.0, 0)
local InputMap = {keys = {W=0,A=0,S=0,D=0,E=0,Q=0}, mouse = {Delta = Vector2.new(), Wheel = 0}}
local rightMousePressed = false

local function StepFreecam(dt)
    if not freecamActive then 
        return 
    end
    
    local moveZ = InputMap.keys.W - InputMap.keys.S 
    local moveX = InputMap.keys.D - InputMap.keys.A
    local moveY = InputMap.keys.E - InputMap.keys.Q
    
    local speedMult = (UIS:IsKeyDown(Enum.KeyCode.LeftShift) and 0.25 or 1)
    local vel = velSpring:Update(dt, Vector3.new(moveX, moveY, moveZ) * speedMult)

    local fov = fovSpring:Update(dt, InputMap.mouse.Wheel)
    InputMap.mouse.Wheel = 0
    cameraFov = clamp(cameraFov + fov*FOV_GAIN*dt, 1, 120)

    if rightMousePressed then
        local pan = panSpring:Update(dt, InputMap.mouse.Delta)
        InputMap.mouse.Delta = Vector2.new()
        cameraRot = cameraRot + pan*PAN_GAIN*dt
        cameraRot = Vector2.new(clamp(cameraRot.x, -PITCH_LIMIT, PITCH_LIMIT), cameraRot.y%(2*pi))
    end

    local moveVector = Vector3.new()
    if vel.X ~= 0 or vel.Y ~= 0 or vel.Z ~= 0 then
        local camCF = CFrame.fromOrientation(cameraRot.x, cameraRot.y, 0)

        moveVector = moveVector + camCF.LookVector * vel.Z      
        moveVector = moveVector + camCF.RightVector * vel.X     
        moveVector = moveVector + camCF.UpVector * vel.Y        
    end
    
    cameraPos = cameraPos + moveVector * NAV_GAIN * dt

    local cf = CFrame.new(cameraPos) * CFrame.fromOrientation(cameraRot.x, cameraRot.y, 0)
    cam.CFrame = cf
    cam.Focus = cf
    cam.FieldOfView = cameraFov
end

local function ToggleFreecam(state)
    if state then
        local cf = cam.CFrame
        cameraRot = Vector2.new(cf:toEulerAnglesYXZ())
        cameraPos = cf.p
        cameraFov = cam.FieldOfView
        velSpring:Reset(Vector3.new())
        panSpring:Reset(Vector2.new())
        fovSpring:Reset(0)

        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            player.Character.HumanoidRootPart.Anchored = true
        end
        
        RunService:BindToRenderStep("Freecam", 201, StepFreecam)
        freecamActive = true
        UIS.MouseBehavior = Enum.MouseBehavior.Default
    else
        RunService:UnbindFromRenderStep("Freecam")

        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            player.Character.HumanoidRootPart.Anchored = false
        end
        
        cam.CameraType = Enum.CameraType.Custom
        freecamActive = false
        rightMousePressed = false
        UIS.MouseBehavior = Enum.MouseBehavior.Default
    end
end


UIS.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and settings.freecam and freecamActive then
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            rightMousePressed = true
            UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
        end
    end
end)

UIS.InputEnded:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        if settings.freecam and freecamActive then
            rightMousePressed = false
            UIS.MouseBehavior = Enum.MouseBehavior.Default
        end
    end
end)

UIS.InputChanged:Connect(function(input)
    if settings.freecam and freecamActive and rightMousePressed then
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            InputMap.mouse.Delta = Vector2.new(-input.Delta.y, -input.Delta.x)
        end
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            InputMap.mouse.Wheel = -input.Position.z
        end
    end
end)

UIS.InputBegan:Connect(function(i)
    if i.KeyCode and i.KeyCode.Name:len() == 1 and settings.freecam and freecamActive then
        InputMap.keys[i.KeyCode.Name] = 1
    end
end)

UIS.InputEnded:Connect(function(i)
    if i.KeyCode and i.KeyCode.Name:len() == 1 and settings.freecam and freecamActive then
        InputMap.keys[i.KeyCode.Name] = 0
    end
end)



-- mtp, partial name
local function teleportToMouse()
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local mousePos = mouse.Hit
    if mousePos and mousePos.Position then
        local wasAnchored = hrp.Anchored
        if wasAnchored then hrp.Anchored = false end
        hrp.CFrame = CFrame.new(mousePos.Position)
        task.wait(0.05)
        if wasAnchored then hrp.Anchored = true end
    end
end

local function findPlayerByPartialName(partialName)
    if not partialName or partialName == "" then return nil end
    local partialLower = string.lower(partialName)
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player then
            if string.sub(string.lower(p.Name), 1, #partialLower) == partialLower then
                return p.Name
            end
        end
    end
    return nil
end

-- aimbot
local Drawing = Drawing or {}
local fovCircle = Drawing.new("Circle")
if fovCircle then
    fovCircle.Thickness = 1
    fovCircle.NumSides = 64
    fovCircle.Radius = settings.aimbotFov
    fovCircle.Filled = false
    fovCircle.Visible = false
    fovCircle.Color = Color3.new(1, 0, 0)
    fovCircle.Transparency = 0.5
end

local targetDot = Drawing.new("Circle")
if targetDot then
    targetDot.Thickness = 2
    targetDot.NumSides = 32
    targetDot.Radius = 6
    targetDot.Filled = true
    targetDot.Color = Color3.new(1, 1, 1)
    targetDot.Transparency = 0.3
    targetDot.Visible = false
end

local targetDotOutline = Drawing.new("Circle")
if targetDotOutline then
    targetDotOutline.Thickness = 1
    targetDotOutline.NumSides = 32
    targetDotOutline.Radius = 8
    targetDotOutline.Filled = false
    targetDotOutline.Color = Color3.new(0, 0, 0)
    targetDotOutline.Transparency = 0.5
    targetDotOutline.Visible = false
end

local targetDotWall = Drawing.new("Circle")
if targetDotWall then
    targetDotWall.Thickness = 2
    targetDotWall.NumSides = 32
    targetDotWall.Radius = 6
    targetDotWall.Filled = true
    targetDotWall.Color = Color3.new(1, 0, 0)
    targetDotWall.Transparency = 0.3
    targetDotWall.Visible = false
end

local currentTarget = nil
local targetPart = nil
local lockedPart = nil
local isAiming = false
local targetVisible = false

local function isSameTeam(player1, player2)
    if not player1 or not player2 then return false end
    local team1 = player1.Team
    local team2 = player2.Team
    if not team1 or not team2 then return false end
    return team1 == team2
end

local function isTargetVisible(targetPos, targetPart)
    if not player.Character or not player.Character:FindFirstChild("Head") then 
        return false 
    end
    
    local pos, onScreen = cam:WorldToViewportPoint(targetPos)
    if not onScreen then return false end
    
    local origin = cam.CFrame.Position
    local distance = (targetPos - origin).Magnitude
    
    if distance > 1000 then return false end
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {player.Character}
    
    local checkPos = targetPos + Vector3.new(0, 0.3, 0)
    local direction = (checkPos - origin).Unit
    
    local raycastResult = workspace:Raycast(origin, direction * distance, raycastParams)
    
    if not raycastResult then
        return true
    end
    
    local hit = raycastResult.Instance
    
    if targetPart and hit:IsDescendantOf(targetPart.Parent) then
        return true
    end
    
    if hit.Transparency and hit.Transparency > 0.8 then
        return true
    end
    
    if hit.CanCollide == false then
        return true
    end
    
    return false
end

local function getClosestTarget()
    if not settings.aimbot then return nil, nil end
    local center = Vector2.new(mouse.X, mouse.Y + 60)
    local closestDist = settings.aimbotFov
    local closestPlayer = nil
    local closestPart = nil
    local bestScore = math.huge
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            if settings.teamCheck then
                if isSameTeam(player, p) then
                    continue
                end
            end
            
            local char = p.Character
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local partsToCheck = {"Head", "HumanoidRootPart"}
                
                for _, partName in pairs(partsToCheck) do
                    local part = char:FindFirstChild(partName)
                    if part then
                        local pos, onScreen = cam:WorldToViewportPoint(part.Position)
                        if onScreen then
                            local aimDist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                            local playerDist = 0
                            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                                local myPos = player.Character.HumanoidRootPart.Position
                                playerDist = (part.Position - myPos).Magnitude
                            end
                            
                            local visible = true
                            if settings.wallCheck then
                                visible = isTargetVisible(part.Position, part)
                            end

                            if not settings.wallCheck or visible then
                                local score
                                
                                if settings.aimPart == "Head" then
                                    if partName == "Head" then
                                        score = aimDist * 0.7 + playerDist * 0.3
                                    else
                                        score = math.huge
                                    end
                                elseif settings.aimPart == "Torso" then
                                    if partName == "HumanoidRootPart" then
                                        score = aimDist * 0.7 + playerDist * 0.3
                                    else
                                        score = math.huge
                                    end
                                else
                                    if partName == "Head" then
                                        score = aimDist * 0.7 + playerDist * 0.3 - 0.1
                                    else
                                        score = aimDist * 0.7 + playerDist * 0.3
                                    end
                                end
                                
                                if aimDist < closestDist and score < bestScore then
                                    bestScore = score
                                    closestPlayer = p
                                    closestPart = part
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return closestPlayer, closestPart
end

local function smoothAim(targetPos, smoothness)
    if not targetPos then return end
    local currentLook = cam.CFrame.LookVector
    local targetLook = (targetPos - cam.CFrame.Position).Unit
    local smoothFactor = math.min(1, smoothness * 0.1)
    local newLook = currentLook:Lerp(targetLook, smoothFactor)
    local newCF = CFrame.lookAt(cam.CFrame.Position, cam.CFrame.Position + newLook)
    cam.CFrame = newCF
end

UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if settings.aimbot and currentTarget and targetPart then
            if settings.wallCheck then
                if targetVisible then
                    lockedPart = targetPart
                    isAiming = true
                end
            else
                lockedPart = targetPart
                isAiming = true
            end
        end
    end
end)

UIS.InputEnded:Connect(function(input, gp)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isAiming = false
        lockedPart = nil
    end
end)

RunService.RenderStepped:Connect(function()
    if settings.showFovCircle and settings.aimbot and fovCircle then
        fovCircle.Position = Vector2.new(mouse.X, mouse.Y + 60)
        fovCircle.Radius = settings.aimbotFov
        fovCircle.Visible = true
    elseif fovCircle then
        fovCircle.Visible = false
    end
    
    if not isAiming then
        local target, part = getClosestTarget()
        currentTarget = target
        targetPart = part
        if targetPart then
            if settings.wallCheck then
                targetVisible = isTargetVisible(targetPart.Position, targetPart)
            else
                targetVisible = true
            end
        end
    else
        if lockedPart then
            if settings.wallCheck then
                targetVisible = isTargetVisible(lockedPart.Position, lockedPart)
            else
                targetVisible = true
            end
        end
    end
    
    local showPart = isAiming and lockedPart or targetPart
    if settings.aimbot and showPart and settings.showFovCircle then
        local pos, onScreen = cam:WorldToViewportPoint(showPart.Position)
        if onScreen then
            local dotPos = Vector2.new(pos.X, pos.Y)
            if settings.wallCheck and not targetVisible then
                if targetDot then targetDot.Visible = false end
                if targetDotOutline then targetDotOutline.Visible = false end
                if targetDotWall then
                    targetDotWall.Position = dotPos
                    targetDotWall.Visible = true
                end
            else
                if targetDot then
                    targetDot.Position = dotPos
                    targetDot.Visible = true
                end
                if targetDotOutline then
                    targetDotOutline.Position = dotPos
                    targetDotOutline.Visible = true
                end
                if targetDotWall then targetDotWall.Visible = false end
            end
        else
            if targetDot then targetDot.Visible = false end
            if targetDotOutline then targetDotOutline.Visible = false end
            if targetDotWall then targetDotWall.Visible = false end
        end
    else
        if targetDot then targetDot.Visible = false end
        if targetDotOutline then targetDotOutline.Visible = false end
        if targetDotWall then targetDotWall.Visible = false end
    end
    
    if settings.aimbot then
        local shouldAim = false
        
        if settings.aimOnKey then
            if typeof(settings.aimKey) == "EnumItem" then
                if settings.aimKey.EnumType == Enum.UserInputType then
                    shouldAim = UIS:IsMouseButtonPressed(settings.aimKey)
                elseif settings.aimKey.EnumType == Enum.KeyCode then
                    shouldAim = UIS:IsKeyDown(settings.aimKey)
                end
            end
        else
            shouldAim = true
        end
        
        if shouldAim then
            local aimAt = lockedPart or targetPart
            if aimAt then
                local canAim = true
                if settings.wallCheck then
                    canAim = isTargetVisible(aimAt.Position, aimAt)
                end
                if canAim and aimAt and aimAt.Parent then
                    local smoothness = 11 - settings.aimbotSmoothness
                    smoothAim(aimAt.Position, smoothness)
                end
            end
        else
            isAiming = false
            lockedPart = nil
        end
    end
end)

-- fly
local flyActive = false
local function ToggleFly(state)
    flyActive = state
    settings.fly = state
    if not state then
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.Velocity = Vector3.zero
        end
    end
end

-- noclip
local noclipConnection = nil
local noclipActive = false
local function enableNoclip()
    if noclipActive then return end
    noclipActive = true
    if noclipConnection then noclipConnection:Disconnect() end
    noclipConnection = RunService.Stepped:Connect(function()
        if settings.noclip and player.Character then
            for _, part in pairs(player.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
end
local function disableNoclip()
    noclipActive = false
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    if player.Character then
        -- Части, которые должны иметь коллизию (НЕ проходить сквозь стены)
        local partsWithCollision = {"HumanoidRootPart", "LeftLeg", "RightLeg", "Torso"}
        
        for _, part in pairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                local hasCollision = false
                for _, name in pairs(partsWithCollision) do
                    if part.Name == name then
                        hasCollision = true
                        break
                    end
                end
                part.CanCollide = hasCollision
            end
        end
    end
end
local function toggleNoclip(state)
    settings.noclip = state
    if state then enableNoclip() else disableNoclip() end
end

-- UI
local Window = MinimalUI:CreateWindow("XENO DARK")
Window:SetTheme(Color3.fromRGB(0, 60, 150))
Window:SetMenuTheme("dark")

-- close
local function onMenuClose()
    if scriptRunning then 
        _G.XenoUnload() 
    end
end

local oldClose = Window.Close
Window.Close = function()
    onMenuClose()
    if oldClose then oldClose() end
end

Window:SetKey(Enum.KeyCode.RightControl)

local flyToggleSlider = nil
local walkToggleSlider = nil
local jumpToggleSlider = nil
local hitboxToggleSlider = nil
local freecamToggle = nil
local teleportToMouseToggle = nil

local CombatTab = Window:CreateTab("😎 MAIN")

-- movement
local MovementSec = CombatTab:CreateSection("MOVEMENT")
flyToggleSlider = MovementSec:CreateToggleSlider("Fly (Q)", 0.1, 5, 0.8, false, function(e, v)
    settings.fly = e; settings.flySpeed = v; ToggleFly(e)
end)
walkToggleSlider = MovementSec:CreateToggleSlider("Walk Boost", 0.1, 3, 0.5, false, function(e, v)
    settings.walkBoost = e; settings.walkPower = v
end)
jumpToggleSlider = MovementSec:CreateToggleSlider("Jump Boost", 1, 15, 3.5, false, function(e, v)
    settings.jumpBoost = e; settings.jumpPower = v
end)

gravityToggleSlider = MovementSec:CreateToggleSlider("Gravity", 0, 500, 196.2, false, function(e, v)
    settings.gravityEnabled = e
    settings.gravityValue = v
    workspace.Gravity = e and v or 196.2
end)
MovementSec:CreateToggle("No Jump Cooldown", false, function(v) settings.noJumpCooldown = v end)

-- visuals
local VisualSec = CombatTab:CreateSection("OTHER")
-- VisualSec:CreateToggle("FullBright", false, function(v) settings.fullbright = v end)
VisualSec:CreateToggle("NoClip", false, function(v) toggleNoclip(v) end)
hitboxToggleSlider = VisualSec:CreateToggleSlider("Hitbox Extender", 1, 20, 5, false, function(e, v)
    settings.hitbox = e; settings.hitboxSize = v
end)

freecamToggle = VisualSec:CreateToggle("Freecam (Shift+P)", false, function(v)
    settings.freecam = v
    ToggleFreecam(v)
end)

-- aim
local AIMTab = Window:CreateTab("🎯 AIMBOT")
local AimbotSec = AIMTab:CreateSection("Main")

AimbotSec:CreateToggle("Enable Aimbot", false, function(v) settings.aimbot = v end)
AimbotSec:CreateSlider("Aimbot FOV", 10, 360, 90, function(v)
    settings.aimbotFov = v
    if fovCircle then fovCircle.Radius = v end
end)
AimbotSec:CreateSlider("Smoothness", 1, 10, 5, function(v) settings.aimbotSmoothness = v end)
AimbotSec:CreateDropdown("Target Part", {"Auto", "Head", "Torso", }, "Auto", function(selected)
    settings.aimPart = selected
end)
AimbotSec:CreateToggle("Show FOV Circle", false, function(v) settings.showFovCircle = v end)
AimbotSec:CreateToggle("Aim on key", false, function(v) 
    settings.aimOnKey = v
end)
AimbotSec:CreateKeybind("Aim Key", Enum.KeyCode.LeftAlt, function(key)
    settings.aimKey = key
    settings.aimOnKey = true
end)
AimbotSec:CreateToggle("Wall Check", false, function(v) settings.wallCheck = v end)
AimbotSec:CreateToggle("Team Check", false, function(v) settings.teamCheck = v end)

-- esp
local ESPTab = Window:CreateTab("☣️ ESP")

local ESPSec = ESPTab:CreateSection("Main")
ESPSec:CreateTogglePicker("ESP Highlight", settings.espHighlightColor, false, function(e, c)
    settings.espHighlight = e
    if typeof(c) == "Color3" then settings.espHighlightColor = c end
end)
ESPSec:CreateToggle("ESP Name", false, function(v) settings.espName = v end)
ESPSec:CreateToggle("ESP Box", false, function(v) settings.espBox = v end)
ESPSec:CreateToggle("ESP Health", false, function(v) settings.espHealth = v end)


local WorldTab = Window:CreateTab("🌍 World")
local WorldSec = WorldTab:CreateSection("Main")

WorldSec:CreateToggle("FullBright", false, function(v) 
    settings.fullbright = v 
end)
WorldSec:CreateDualButton("☀️ Day", "🌙 Night", "left", function(side)
    local Lighting = game:GetService("Lighting")
    if side == "left" then 
        Lighting.ClockTime = 14
        Lighting.Brightness = 2
        Lighting.Ambient = Color3.fromRGB(128, 128, 128)
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    else 
        Lighting.ClockTime = 0
        Lighting.Brightness = 0.5
        Lighting.Ambient = Color3.fromRGB(20, 20, 40)
        Lighting.OutdoorAmbient = Color3.fromRGB(20, 20, 40)
    end
end)
local savedMaterials = {}
WorldSec:CreateToggle("No Textures", false, function(v)
    if v then
        savedMaterials = {}
        for _, part in pairs(workspace:GetDescendants()) do
            if part:IsA("BasePart") then
                savedMaterials[part] = part.Material
                part.Material = Enum.Material.SmoothPlastic
            end
        end
    else
        for part, material in pairs(savedMaterials) do
            if part and part.Parent then
                part.Material = material
            end
        end
        savedMaterials = {}
    end
end)
WorldSec:CreateToggle("No Shadows", false, function(v)
    local Lighting = game:GetService("Lighting")
    Lighting.GlobalShadows = not v
    for _, light in pairs(workspace:GetDescendants()) do
        if light:IsA("Light") then
            light.Shadows = not v
        end
    end
end)
WorldSec:CreateToggle("No Fog", false, function(v)
    local Lighting = game:GetService("Lighting")
    if v then
        Lighting.FogEnd = 100000
        Lighting.FogStart = 0
    else
        Lighting.FogEnd = 1000
        Lighting.FogStart = 0
    end
end)
local savedDecals = {}
WorldSec:CreateToggle("No Decals", false, function(v)
    if v then
        savedDecals = {}
        for _, decal in pairs(workspace:GetDescendants()) do
            if decal:IsA("Decal") or decal:IsA("Texture") then
                savedDecals[decal] = decal.Transparency
                decal.Transparency = 1
            end
        end
    else
        for decal, transparency in pairs(savedDecals) do
            if decal and decal.Parent then
                decal.Transparency = transparency
            end
        end
        savedDecals = {}
    end
end)
WorldSec:CreateToggle("No Water Reflect", false, function(v)
    for _, part in pairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") and part.Material == Enum.Material.Water then
            part.Reflectance = v and 0 or 0.5
        end
    end
end)
local savedTransparency = {}
WorldSec:CreateToggle("X-Ray", false, function(v)
    local player = game.Players.LocalPlayer
    if v then
        savedTransparency = {}
        for _, part in pairs(workspace:GetDescendants()) do
            if part:IsA("BasePart") and not part:IsDescendantOf(player.Character) then
                savedTransparency[part] = part.Transparency
                part.Transparency = 0.5
            end
        end
    else
        for part, transparency in pairs(savedTransparency) do
            if part and part.Parent then
                part.Transparency = transparency
            end
        end
        savedTransparency = {}
    end
end)
local bloomEffect = nil
WorldSec:CreateToggleSlider("Bloom", 0, 100, 50, false, function(e, v)
    local Lighting = game:GetService("Lighting")
    if e then
        if bloomEffect then bloomEffect:Destroy() end
        
        bloomEffect = Instance.new("BloomEffect")
        bloomEffect.Name = "XenoBloom"
        bloomEffect.Intensity = v / 100
        bloomEffect.Size = 16
        bloomEffect.Threshold = 0.8
        bloomEffect.Parent = Lighting
    else
        if bloomEffect then
            bloomEffect:Destroy()
            bloomEffect = nil
        end
    end
end, function(v)
    if bloomEffect then
        bloomEffect.Intensity = v / 100
    end
end)

local atmosphereEffect = nil
WorldSec:CreateColorPicker("Atmosphere", Color3.fromRGB(135, 206, 235), function(color)
    local Lighting = game:GetService("Lighting")
    if not atmosphereEffect then
        atmosphereEffect = Lighting:FindFirstChild("XenoAtmosphere")
        if not atmosphereEffect then
            atmosphereEffect = Instance.new("Atmosphere")
            atmosphereEffect.Name = "XenoAtmosphere"
            atmosphereEffect.Parent = Lighting
        end
    end
    atmosphereEffect.Color = color
    atmosphereEffect.Density = 0.5
    atmosphereEffect.Offset = 0.5
    atmosphereEffect.Decay = Color3.new(1, 1, 1)
end)

-- other
local OtherTab = Window:CreateTab("🛠 OTHER")

-- view
local ViewSec = OtherTab:CreateSection("VIEW")
local selectedViewPlayer = nil
local isSpectating = false
local viewPlayerDropdown = nil
local viewTextBoxApi = nil

local function getViewPlayersList()
    local playersList = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player then table.insert(playersList, p.Name) end
    end
    if #playersList == 0 then table.insert(playersList, "No players") end
    return playersList
end

local function refreshViewDropdown()
    if not viewPlayerDropdown then return end
    local newList = getViewPlayersList()
    viewPlayerDropdown:SetOptions(newList)
    if #newList > 0 and newList[1] ~= "No players" then
        viewPlayerDropdown:SetValue(newList[1])
        selectedViewPlayer = newList[1]
        if viewTextBoxApi then viewTextBoxApi:Set(selectedViewPlayer) end
    else
        viewPlayerDropdown:SetValue("No players")
        selectedViewPlayer = nil
        if viewTextBoxApi then viewTextBoxApi:Set("") end
    end
end

local function startSpectating()
    if selectedViewPlayer and selectedViewPlayer ~= "No players" and selectedViewPlayer ~= "Select..." then
        local target = Players:FindFirstChild(selectedViewPlayer)
        if target and target.Character then
            workspace.CurrentCamera.CameraSubject = target.Character
            isSpectating = true
        end
    end
end

local function stopSpectating()
    local char = player.Character
    if char then
        workspace.CurrentCamera.CameraSubject = char
        isSpectating = false
    end
end

viewTextBoxApi = ViewSec:CreateTextBox("Enter player name:", "Type first letters...", function(inputText)
    if inputText and inputText ~= "" then
        local matchedPlayer = findPlayerByPartialName(inputText)
        if matchedPlayer then
            viewTextBoxApi:Set(matchedPlayer)
            selectedViewPlayer = matchedPlayer
            if viewPlayerDropdown then viewPlayerDropdown:SetValue(selectedViewPlayer) end
        end
    end
end)

viewPlayerDropdown = ViewSec:CreateDropdown("Select player:", getViewPlayersList(), "Select...", function(selected)
    selectedViewPlayer = selected
    if viewTextBoxApi then viewTextBoxApi:Set(selected) end
    if isSpectating then startSpectating() end
end)

ViewSec:CreateButton("Refresh Players", function() refreshViewDropdown() end)
ViewSec:CreateToggle("Spectate Mode", false, function(v)
    if v then startSpectating() else stopSpectating() end
end)

-- tp
local TeleportSec = OtherTab:CreateSection("TELEPORT")
local selectedPlayer = nil
local playerDropdown = nil
local teleportTextBoxApi = nil

local function safeTeleport(targetCFrame)
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local wasAnchored = hrp.Anchored
    if wasAnchored then hrp.Anchored = false end
    hrp.CFrame = targetCFrame
    task.wait(0.05)
    if wasAnchored then hrp.Anchored = true end
end

local function getPlayersList()
    local playersList = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player then table.insert(playersList, p.Name) end
    end
    if #playersList == 0 then table.insert(playersList, "No players") end
    return playersList
end

local function refreshPlayerDropdown()
    if not playerDropdown then return end
    playerDropdown:SetOptions(getPlayersList())
end

teleportTextBoxApi = TeleportSec:CreateTextBox("Enter player name:", "Type first letters...", function(inputText)
    if inputText and inputText ~= "" then
        local matchedPlayer = findPlayerByPartialName(inputText)
        if matchedPlayer then
            teleportTextBoxApi:Set(matchedPlayer)
            selectedPlayer = matchedPlayer
            if playerDropdown then playerDropdown:SetValue(selectedPlayer) end
        end
    end
end)

playerDropdown = TeleportSec:CreateDropdown("Select Player", getPlayersList(), "Select...", function(selected)
    selectedPlayer = selected
    if teleportTextBoxApi then teleportTextBoxApi:Set(selected) end
end)

TeleportSec:CreateButton("Teleport to Selected", function()
    if selectedPlayer and selectedPlayer ~= "No players" and selectedPlayer ~= "Select..." then
        local target = Players:FindFirstChild(selectedPlayer)
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            safeTeleport(target.Character.HumanoidRootPart.CFrame)
        end
    end
end)

TeleportSec:CreateButton("Teleport to Camera", function()
    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        safeTeleport(cam.CFrame)
    end
end)

TeleportSec:CreateButton("Refresh List", function() refreshPlayerDropdown() end)

teleportToMouseToggle = TeleportSec:CreateToggle("Tp to Mouse (Ctrl+LBM)", false, function(v)
    settings.teleportToMouse = v
end)


local DeleteToolsSec = OtherTab:CreateSection("DELETE TOOLS")

local deleting = false
local history = {}

DeleteToolsSec:CreateToggle("Delete Mode", false, function(v)
    deleting = v
end)

DeleteToolsSec:CreateButton("Restore All", function()
    local count = #history
    if count == 0 then
        print("Nothing to restore!")
        return
    end
    while #history > 0 do
        local data = table.remove(history)
        pcall(function()
            local newPart = data.clone:Clone()
            for prop, val in pairs(data.props) do
                newPart[prop] = val
            end
            newPart.Parent = data.props.Parent
        end)
    end
    print("Restored " .. count .. " objects!")
end)

mouse.Button1Down:Connect(function()
    if not deleting then return end
    local target = mouse.Target
    if target and target:IsA("BasePart") and not target:IsDescendantOf(player.Character) then
        local clone = target:Clone()
        local props = {
            Parent = target.Parent,
            Material = target.Material,
            Color = target.Color,
            Size = target.Size,
            CFrame = target.CFrame,
            Anchored = target.Anchored,
            Transparency = target.Transparency,
            CanCollide = target.CanCollide,
            Name = target.Name
        }
        table.insert(history, {props = props, clone = clone})
        target:Destroy()
    end
end)

-- info
local InfoTab = Window:CreateTab("ℹ INFO")
local InfoSec = InfoTab:CreateSection("ABOUT")
InfoSec:CreateButton("XENO DARK", function() print("XENO DARK") end)
InfoSec:CreateButton("Credits: Hilka-dilka , MinimalUI (github)", function() end)
InfoSec:CreateButton("Version: 4.1", function() end)

--update
local lastESPUpdate = 0

local function clearPlayerESP(c)
    if c:FindFirstChild("XenoESP_Highlight") then c.XenoESP_Highlight:Destroy() end
    if c:FindFirstChild("XenoESP_Name") then c.XenoESP_Name:Destroy() end
    local root = c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso")
    if root then
        if root:FindFirstChild("XenoESP_Box") then root.XenoESP_Box:Destroy() end
        if root:FindFirstChild("XenoESP_Health") then root.XenoESP_Health:Destroy() end
    end
end

RunService.RenderStepped:Connect(function(dt)
    if not scriptRunning then return end

    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")


    if hrp and hum and not settings.freecam then
        if settings.noJumpCooldown and UIS:IsKeyDown(Enum.KeyCode.Space) then
            hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
            hum.Jump = true
        end

        if flyActive then
            hrp.Velocity = Vector3.zero
            local move = Vector3.zero
            if UIS:IsKeyDown(Enum.KeyCode.W) then move = move + cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then move = move - cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then move = move - cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then move = move + cam.CFrame.RightVector end
            if move.Magnitude > 0 then
                hrp.CFrame = hrp.CFrame + move.Unit * settings.flySpeed
            end
        end

        if settings.walkBoost and hum.MoveDirection.Magnitude > 0 then
            hrp.CFrame = hrp.CFrame + hum.MoveDirection * settings.walkPower
        end
    end

    if settings.fullbright then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
    else
        Lighting.Brightness = 1
        Lighting.GlobalShadows = true
    end

    if settings.hitbox then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and p.Character then
                local head = p.Character:FindFirstChild("Head")
                if head then
                    head.Size = Vector3.new(settings.hitboxSize, settings.hitboxSize, settings.hitboxSize)
                    head.Transparency = 0.5
                    head.CanCollide = false
                end
            end
        end
    else
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and p.Character then
                local head = p.Character:FindFirstChild("Head")
                if head then
                    head.Size = Vector3.new(2, 1, 1)
                    head.Transparency = 0
                    head.CanCollide = true
                end
            end
        end
    end

    if settings.espHighlight or settings.espName or settings.espBox or settings.espHealth then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and p.Character then
                local c = p.Character
                local humTarget = c:FindFirstChildOfClass("Humanoid")
                local root = c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso")
                if humTarget and humTarget.Health > 0 and root then
                    
                    if settings.espHighlight then
                        local h = c:FindFirstChild("XenoESP_Highlight") or Instance.new("Highlight", c)
                        h.Name = "XenoESP_Highlight"
                        h.FillColor = settings.espHighlightColor
                        h.FillTransparency = 0.5
                        h.OutlineColor = Color3.new(1,1,1)
                        h.OutlineTransparency = 0
                    else
                        if c:FindFirstChild("XenoESP_Highlight") then c.XenoESP_Highlight:Destroy() end
                    end

                    if settings.espName then
                        if not c:FindFirstChild("XenoESP_Name") then
                            local bg = Instance.new("BillboardGui", c)
                            bg.Name = "XenoESP_Name"
                            bg.Size = UDim2.new(0, 100, 0, 30)
                            bg.StudsOffset = Vector3.new(0, 3, 0)
                            bg.AlwaysOnTop = true
                            local name = Instance.new("TextLabel", bg)
                            name.Size = UDim2.new(1,0,1,0)
                            name.BackgroundTransparency = 1
                            name.Text = p.Name
                            name.TextColor3 = Color3.new(1,1,1)
                            name.TextStrokeColor3 = Color3.new(0,0,0)
                            name.TextStrokeTransparency = 0
                            name.Font = Enum.Font.GothamBold
                            name.TextSize = 13
                        end
                    else
                        if c:FindFirstChild("XenoESP_Name") then c.XenoESP_Name:Destroy() end
                    end

                    if settings.espBox then
                        if not root:FindFirstChild("XenoESP_Box") then
                            local box = Instance.new("BillboardGui", root)
                            box.Name = "XenoESP_Box"
                            box.Size = UDim2.new(4,0,6,0)
                            box.AlwaysOnTop = true
                            local frame = Instance.new("Frame", box)
                            frame.Size = UDim2.new(1,0,1,0)
                            frame.BackgroundTransparency = 1
                            local stroke = Instance.new("UIStroke", frame)
                            stroke.Color = Color3.new(1,1,1)
                            stroke.Thickness = 1
                        end
                    else
                        if root:FindFirstChild("XenoESP_Box") then root.XenoESP_Box:Destroy() end
                    end

                    if settings.espHealth then
                        local healthGui = root:FindFirstChild("XenoESP_Health")
                        if not healthGui then
                            healthGui = Instance.new("BillboardGui", root)
                            healthGui.Name = "XenoESP_Health"
                            healthGui.Size = UDim2.new(5, 0, 6, 0)
                            healthGui.StudsOffset = Vector3.new(0, 0, 0)
                            healthGui.AlwaysOnTop = true
                            healthGui.Adornee = root
                            healthGui.MaxDistance = 500

                            local bg = Instance.new("Frame", healthGui)
                            bg.Name = "BG"
                            bg.Size = UDim2.new(0.05, 0, 1, 0)
                            bg.Position = UDim2.new(0, 0, 0, 0)
                            bg.BackgroundColor3 = Color3.new(0,0,0)
                            bg.BackgroundTransparency = 0.3
                            bg.BorderSizePixel = 1
                            bg.BorderColor3 = Color3.new(1,1,1)

                            local fill = Instance.new("Frame", bg)
                            fill.Name = "Fill"
                            fill.Size = UDim2.new(1,0,1,0)
                            fill.BackgroundColor3 = Color3.new(0,1,0)
                            fill.BorderSizePixel = 0
                            fill.BackgroundTransparency = 0.1
                        end

                        local fill = healthGui.BG.Fill
                        local pct = math.clamp(humTarget.Health / humTarget.MaxHealth, 0, 1)
                        fill.Size = UDim2.new(1,0,pct,0)
                        fill.Position = UDim2.new(0,0,1-pct,0)
                        fill.BackgroundColor3 = Color3.fromHSV(pct * 0.35, 1, 0.8)
                        fill.BackgroundTransparency = 0.1
                    else
                        if root:FindFirstChild("XenoESP_Health") then root.XenoESP_Health:Destroy() end
                    end
                else
                    clearPlayerESP(c)
                end
            end
        end
    else
        clearAllESP()
    end
end)

UIS.InputBegan:Connect(function(i, gp)
    if gp then return end
    
    if i.KeyCode == Enum.KeyCode.Q then
        settings.fly = not settings.fly
        ToggleFly(settings.fly)
        if flyToggleSlider then flyToggleSlider:SetEnabled(settings.fly) end
    end

    if i.KeyCode == Enum.KeyCode.P and UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
        settings.freecam = not settings.freecam
        ToggleFreecam(settings.freecam)
        if freecamToggle then freecamToggle:Set(settings.freecam) end
    end

    if i.KeyCode == Enum.KeyCode.Space and settings.jumpBoost and player.Character then
        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = hrp.CFrame + Vector3.new(0, settings.jumpPower, 0)
        end
    end

    if settings.teleportToMouse and i.UserInputType == Enum.UserInputType.MouseButton1 and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
        teleportToMouse()
    end
end)

UIS.InputEnded:Connect(function(i, gp)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        isAiming = false
        lockedPart = nil
    end
end)

player.CameraMaxZoomDistance = 1000

fadeOut:Play()
task.wait(0.6)
splashGui:Destroy()

print("XENO DARK V4.1 LOADED")
