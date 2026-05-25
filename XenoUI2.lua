-- Load via loadstring
local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Hilka-dilka/MinimalUI/main/MinimalUI.lua"))()


local player = game.Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local cam = workspace.CurrentCamera
local Players = game:GetService("Players")
local mouse = player:GetMouse()

local settings = {
    fly = false, flySpeed = 0.8,
    walkBoost = false, walkPower = 0.5,
    jumpBoost = false, jumpPower = 3.5,
    noJumpCooldown = false,
    esp = false,
    fullbright = false,
    noclip = false,
    hitbox = false,
    hitboxSize = 5,
    freecam = false,
    aimbot = false,
    aimbotFov =90,
    aimbotSmoothness = 5,
    aimPart = "Head",
    showFovCircle = false,
    aimOnKey = true,
    wallCheck = false,
    aimKey = Enum.UserInputType.MouseButton2,
    gravityEnabled = false,
    gravityValue = 50,
    teleportToMouse = false
}

------------------------------------------------------------------------
-- Teleport to Mouse Function
------------------------------------------------------------------------
local function teleportToMouse()
    local char = player.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local mousePos = mouse.Hit
    if mousePos and mousePos.Position then
        local wasAnchored = hrp.Anchored
        
        if wasAnchored then
            hrp.Anchored = false
        end
        
        hrp.CFrame = CFrame.new(mousePos.Position)
        
        task.wait(0.05)
        
        if wasAnchored then
            hrp.Anchored = true
        end
        
        print("Teleported to mouse position")
    end
end

------------------------------------------------------------------------
-- aimbot
------------------------------------------------------------------------
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

local function isTargetVisible(targetPos)
    if not player.Character or not player.Character:FindFirstChild("Head") then return false end
    
    local origin = cam.CFrame.Position
    local direction = (targetPos - origin).Unit
    local ray = Ray.new(origin, direction * 1000)
    local hit, position = workspace:FindPartOnRayWithIgnoreList(ray, {player.Character})
    
    if hit then
        if targetPart and (hit:IsDescendantOf(targetPart.Parent) or hit == targetPart) then
            return true
        end
        return false
    end
    return true
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
            local char = p.Character
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            
            if humanoid and humanoid.Health > 0 then
                local parts = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "Torso"}
                for _, partName in pairs(parts) do
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
                                visible = isTargetVisible(part.Position)
                            end

                            if not (settings.wallCheck and not visible) then
                                local score = (aimDist * 0.7) + (playerDist * 0.3)

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
        
        if targetPart and settings.wallCheck then
            targetVisible = isTargetVisible(targetPart.Position)
        else
            targetVisible = true
        end
    else
        if lockedPart and settings.wallCheck then
            targetVisible = isTargetVisible(lockedPart.Position)
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
            if settings.aimKey == Enum.UserInputType.MouseButton2 then
                shouldAim = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
            elseif settings.aimKey == Enum.UserInputType.MouseButton1 then
                shouldAim = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
            elseif settings.aimKey == Enum.KeyCode.LeftAlt then
                shouldAim = UIS:IsKeyDown(Enum.KeyCode.LeftAlt)
            else
                shouldAim = UIS:IsKeyDown(settings.aimKey)
            end
        else
            shouldAim = true
        end
        
        if shouldAim and (targetPart or lockedPart) then
            local aimAt = lockedPart or targetPart
            
            local canAim = true
            if settings.wallCheck and lockedPart then
                canAim = isTargetVisible(aimAt.Position)
            end
            
            if canAim and aimAt then
                local smoothness = 11 - settings.aimbotSmoothness
                smoothAim(aimAt.Position, smoothness)
            end
        elseif not shouldAim then
            isAiming = false
            lockedPart = nil
        end
    end
end)


------------------------------------------------------------------------
-- FREECAM
------------------------------------------------------------------------
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
local freecamActive = false
local rightMousePressed = false
local lastMousePos = nil

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


------------------------------------------------------------------------
-- FLY (FIXED)
------------------------------------------------------------------------
local flyActive = false

local function ToggleFly(state)
    flyActive = state
    settings.fly = state
    
    if not state then
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local hrp = char.HumanoidRootPart
            hrp.Velocity = Vector3.zero
        end
    end
end

------------------------------------------------------------------------
-- NOCLIP
------------------------------------------------------------------------
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
        for _, part in pairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

local function toggleNoclip(state)
    settings.noclip = state
    if state then
        enableNoclip()
    else
        disableNoclip()
    end
end


------------------------------------------------------------------------
-- UI
------------------------------------------------------------------------

local Window = UI:CreateWindow("XENO DARK V17")
Window:SetTheme(Color3.fromRGB(0, 60, 150))
Window:SetMenuTheme("dark")

local flyToggleSlider = nil
local walkToggleSlider = nil
local jumpToggleSlider = nil
local hitboxToggleSlider = nil
local freecamToggle = nil
local teleportToMouseToggle = nil


local CombatTab = Window:CreateTab("⚔ COMBAT")


local MovementSec = CombatTab:CreateSection("🏃 MOVEMENT")

flyToggleSlider = MovementSec:CreateToggleSlider("Fly (Q)", 0.1, 5, 0.8, false, function(enabled, value)
    settings.fly = enabled
    settings.flySpeed = value
    ToggleFly(enabled)
    print("Fly toggled via UI:", enabled, "Speed:", value)
end)

walkToggleSlider = MovementSec:CreateToggleSlider("Walk Boost", 0.1, 3, 0.5, false, function(enabled, value)
    settings.walkBoost = enabled
    settings.walkPower = value
end)

jumpToggleSlider = MovementSec:CreateToggleSlider("Jump Boost", 1, 15, 3.5, false, function(enabled, value)
    settings.jumpBoost = enabled
    settings.jumpPower = value
end)

MovementSec:CreateToggle("No Jump Cooldown", false, function(v)
    settings.noJumpCooldown = v
end)

local VisualSec = CombatTab:CreateSection("👁 VISUAL")


VisualSec:CreateToggle("ESP Full", false, function(v)
    settings.esp = v
end)

VisualSec:CreateToggle("FullBright", false, function(v)
    settings.fullbright = v
end)

VisualSec:CreateToggle("NoClip", false, function(v)
    toggleNoclip(v)
end)

hitboxToggleSlider = VisualSec:CreateToggleSlider("Hitbox Extender", 1, 20, 5, false, function(enabled, value)
    settings.hitbox = enabled
    settings.hitboxSize = value
end)

freecamToggle = VisualSec:CreateToggle("Freecam (Shift+P)", false, function(v)
    settings.freecam = v
    ToggleFreecam(settings.freecam)
end)

local AimbotSec = CombatTab:CreateSection("🎯 AIMBOT")


AimbotSec:CreateToggle("Enable Aimbot", false, function(v)
    settings.aimbot = v
end)

AimbotSec:CreateSlider("Aimbot FOV", 10, 360, 90, function(v)
    settings.aimbotFov = v
    if fovCircle then
        fovCircle.Radius = v
    end
end)

AimbotSec:CreateSlider("Smoothness", 1, 10, 5, function(v)
    settings.aimbotSmoothness = v
end)

AimbotSec:CreateToggle("Show FOV Circle", false, function(v)
    settings.showFovCircle = v
end)

AimbotSec:CreateToggle("Aim on Key (RMB)", true, function(v)
    settings.aimOnKey = v
end)

AimbotSec:CreateToggle("Wall Check", false, function(v)
    settings.wallCheck = v
end)

------------------------------------------------------------------------
-- Other
------------------------------------------------------------------------
local OtherTab = Window:CreateTab("🛠 OTHER")

------------------------------------------------------------------------
-- View Section (Spectate)
------------------------------------------------------------------------
local ViewSec = OtherTab:CreateSection("👁 VIEW")

local selectedViewPlayer = nil
local isSpectating = false
local viewPlayerDropdown = nil

local function getViewPlayersList()
    local playersList = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player then
            table.insert(playersList, p.Name)
        end
    end
    if #playersList == 0 then
        table.insert(playersList, "No players")
    end
    return playersList
end

local function refreshViewDropdown()
    if not viewPlayerDropdown then 
        print("viewPlayerDropdown is nil, cannot refresh")
        return 
    end
    local newList = getViewPlayersList()
    viewPlayerDropdown:SetOptions(newList)
    if #newList > 0 and newList[1] ~= "No players" then
        viewPlayerDropdown:SetValue(newList[1])
        selectedViewPlayer = newList[1]
    else
        viewPlayerDropdown:SetValue("No players")
        selectedViewPlayer = nil
    end
end

local function startSpectating()
    if selectedViewPlayer and selectedViewPlayer ~= "No players" and selectedViewPlayer ~= "Select..." then
        local target = Players:FindFirstChild(selectedViewPlayer)
        if target and target.Character then
            workspace.CurrentCamera.CameraSubject = target.Character
            isSpectating = true
            print("Now spectating: " .. selectedViewPlayer)
        else
            print("Player not found or no character: " .. selectedViewPlayer)
        end
    else
        print("Select a player first!")
    end
end

local function stopSpectating()
    local char = player.Character
    if char then
        workspace.CurrentCamera.CameraSubject = char
        isSpectating = false
        print("Stopped spectating")
    end
end

viewPlayerDropdown = ViewSec:CreateDropdown("Select player:", getViewPlayersList(), "Select...", function(selected)
    selectedViewPlayer = selected
    if isSpectating then
        startSpectating()
    end
end)

ViewSec:CreateButton("🔄 Refresh Players", function()
    refreshViewDropdown()
    print("Players list refreshed!")
end)

ViewSec:CreateToggle("👁 Spectate Mode", false, function(v)
    if v then
        startSpectating()
    else
        stopSpectating()
    end
end)

------------------------------------------------------------------------
-- Teleport Section
------------------------------------------------------------------------
local TeleportSec = OtherTab:CreateSection("📍 TELEPORT")

local selectedPlayer = nil
local playerDropdown = nil

local function safeTeleport(targetCFrame)
    local char = player.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local wasAnchored = hrp.Anchored
    
    if wasAnchored then
        hrp.Anchored = false
    end
    
    hrp.CFrame = targetCFrame
    
    task.wait(0.05)
    
    if wasAnchored then
        hrp.Anchored = true
    end
end

local function getPlayersList()
    local playersList = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player then
            table.insert(playersList, p.Name)
        end
    end
    if #playersList == 0 then
        table.insert(playersList, "No players")
    end
    return playersList
end

local function refreshPlayerDropdown()
    if not playerDropdown then return end
    local newList = getPlayersList()
    playerDropdown:SetOptions(newList)
    print("Players refreshed: " .. table.concat(newList, ", "))
end

playerDropdown = TeleportSec:CreateDropdown("Select Player", getPlayersList(), "Select...", function(selected)
    selectedPlayer = selected
    print("Selected: " .. (selected or "none"))
end)

TeleportSec:CreateButton("📌 Teleport to Selected", function()
    if selectedPlayer and selectedPlayer ~= "No players" and selectedPlayer ~= "Select..." then
        local target = Players:FindFirstChild(selectedPlayer)
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            safeTeleport(target.Character.HumanoidRootPart.CFrame)
            print("Teleported to " .. selectedPlayer)
        else
            print("Player not found or no character: " .. selectedPlayer)
        end
    else
        print("Select a player first!")
    end
end)

TeleportSec:CreateButton("🎥 Teleport to Camera", function()
    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        safeTeleport(cam.CFrame)
        print("Teleported to camera position")
    end
end)

TeleportSec:CreateButton("🔄 Refresh List", function()
    refreshPlayerDropdown()
end)

teleportToMouseToggle = TeleportSec:CreateToggle("🎯 Teleport to Mouse (Ctrl+LMB)", false, function(v)
    settings.teleportToMouse = v
    print("Teleport to Mouse: " .. (v and "ON" or "OFF"))
end)



-- Gravity
local GravitySec = OtherTab:CreateSection("🌍 GRAVITY")

GravitySec:CreateToggleSlider("Gravity Control", 0, 196.2, 50, false, function(enabled, value)
    settings.gravityEnabled = enabled
    settings.gravityValue = value
    
    if enabled then
        workspace.Gravity = value
    else
        workspace.Gravity = 196.2
    end
end)

-- info
local InfoTab = Window:CreateTab("ℹ INFO")
local InfoSec = InfoTab:CreateSection("ABOUT")
InfoSec:CreateButton("XENO DARK V17", function()
    print("XENO DARK V17 - Ultimate Cheat Hub")
end)
InfoSec:CreateButton("Credits: Xeno Team", function() end)
InfoSec:CreateButton("Version: 17.0", function() end)

Window:SetKey(Enum.KeyCode.RightControl)


------------------------------------------------------------------------
-- esp
------------------------------------------------------------------------
local lastESPUpdate = 0


local function clearAllESP()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local c = p.Character

            if c:FindFirstChild("XenoESP_Highlight") then
                c.XenoESP_Highlight:Destroy()
            end

            if c:FindFirstChild("XenoESP_Name") then
                c.XenoESP_Name:Destroy()
            end

            local root = c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso")
            if root and root:FindFirstChild("XenoESP_Box") then
                root.XenoESP_Box:Destroy()
            end
        end
    end
end

RunService.RenderStepped:Connect(function(dt)
    local char = player.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    
    if hrp and hum and not settings.freecam then
        if settings.noJumpCooldown and UIS:IsKeyDown(Enum.KeyCode.Space) then
            hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
            hum.Jump = true
        end
        
        -- FLY LOGIC (works)
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

    if settings.esp then
        if tick() - lastESPUpdate > 0.3 then
            lastESPUpdate = tick()
            
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= player and p.Character then
                    local c = p.Character
                    local humTarget = c:FindFirstChildOfClass("Humanoid")

                    if humTarget and humTarget.Health > 0 then

                        if not c:FindFirstChild("XenoESP_Highlight") then
                            local h = Instance.new("Highlight", c)
                            h.Name = "XenoESP_Highlight"
                            h.FillColor = Color3.fromRGB(0, 60, 150)
                            h.FillTransparency = 0.5
                            h.OutlineColor = Color3.new(1, 1, 1)
                            h.OutlineTransparency = 0
                        end

                        if not c:FindFirstChild("XenoESP_Name") then
                            local root = c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso")
                            if root then
                                local bg = Instance.new("BillboardGui", c)
                                bg.Name = "XenoESP_Name"
                                bg.Size = UDim2.new(0, 100, 0, 30)
                                bg.StudsOffset = Vector3.new(0, 3, 0)
                                bg.AlwaysOnTop = true
                                
                                local name = Instance.new("TextLabel", bg)
                                name.Size = UDim2.new(1, 0, 1, 0)
                                name.BackgroundTransparency = 1
                                name.Text = p.Name
                                name.TextColor3 = Color3.new(1, 1, 1)
                                name.TextStrokeColor3 = Color3.new(0, 0, 0)
                                name.TextStrokeTransparency = 0
                                name.Font = Enum.Font.GothamBold
                                name.TextSize = 13
                            end
                        end
                        

                        local root = c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso")
                        if root and not root:FindFirstChild("XenoESP_Box") then
                            local box = Instance.new("BillboardGui", root)
                            box.Name = "XenoESP_Box"
                            box.Size = UDim2.new(4, 0, 6, 0)
                            box.AlwaysOnTop = true
                            
                            local frame = Instance.new("Frame", box)
                            frame.Size = UDim2.new(1, 0, 1, 0)
                            frame.BackgroundTransparency = 1
                            
                            local stroke = Instance.new("UIStroke", frame)
                            stroke.Color = Color3.new(1, 1, 1)
                            stroke.Thickness = 1
                        end
                    else

                        if c:FindFirstChild("XenoESP_Highlight") then
                            c.XenoESP_Highlight:Destroy()
                        end
                        if c:FindFirstChild("XenoESP_Name") then
                            c.XenoESP_Name:Destroy()
                        end
                        local rootDel = c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso")
                        if rootDel and rootDel:FindFirstChild("XenoESP_Box") then
                            rootDel.XenoESP_Box:Destroy()
                        end
                    end
                end
            end
        end
    else

        clearAllESP()
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
end)

-- MAIN KEY HANDLER (FIXED)
UIS.InputBegan:Connect(function(i, gp)
    if gp then return end
    
    -- Q KEY FOR FLY (FIXED)
    if i.KeyCode == Enum.KeyCode.Q then
        if settings.fly then
            -- TURN OFF
            settings.fly = false
            ToggleFly(false)
            if flyToggleSlider then 
                flyToggleSlider:SetEnabled(false)
            end
            print("Fly disabled via Q key")
        else
            -- TURN ON
            settings.fly = true
            ToggleFly(true)
            if flyToggleSlider then 
                flyToggleSlider:SetEnabled(true)
            end
            print("Fly enabled via Q key")
        end
    end
    
    -- SHIFT+P FOR FREECAM
    if i.KeyCode == Enum.KeyCode.P and UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
        if settings.freecam then
            settings.freecam = false
            ToggleFreecam(false)
            if freecamToggle then freecamToggle:Set(false) end
        else
            settings.freecam = true
            ToggleFreecam(true)
            if freecamToggle then freecamToggle:Set(true) end
        end
    end
    
    -- SPACE KEY FOR JUMP BOOST
    if i.KeyCode == Enum.KeyCode.Space and settings.jumpBoost and player.Character then
        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = hrp.CFrame + Vector3.new(0, settings.jumpPower, 0)
        end
    end
    
    -- TELEPORT TO MOUSE (Ctrl + Left Click)
    if settings.teleportToMouse and i.UserInputType == Enum.UserInputType.MouseButton1 and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
        teleportToMouse()
    end
end)

-- disable max zoom
local Players = game:GetService("Players")
local player = Players.LocalPlayer

player.CameraMaxZoomDistance = 1000

print("XENO DARK V17 [MinimalUI] Loaded! Fly Q key FIXED! Teleport to Mouse added (Ctrl+Click)!")
