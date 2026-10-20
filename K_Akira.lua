-- K akira e filho do asta
-- Universal PvP script for Blox Fruits
-- UI baseada na print: Memory / Visuals / Misc

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ============================================================
-- SETTINGS
-- ============================================================
local Settings = {
    Aimbot = {
        Enabled = false,
        Key = Enum.KeyCode.Q,
        FOV = 120,
        Smoothness = 0.2,
        TargetPart = "Head",
    },
    SilentAim = {
        Enabled = false,
        Key = Enum.KeyCode.Z,
    },
    CamLock = {
        Enabled = false,
        Key = Enum.KeyCode.E,
    },
    ESP = {
        Enabled = false,
        FillColor = Color3.fromRGB(255, 60, 60),
        OutlineColor = Color3.fromRGB(255, 255, 255),
        ShowHealth = true,
    },
    Speed = {
        Enabled = false,
        Value = 16,
        Key = Enum.KeyCode.F,
    },
    Jump = {
        Enabled = false,
        Value = 50,
        Key = Enum.KeyCode.G,
    },
    FastAttack = {
        Enabled = false,
        Range = 20,
        Key = Enum.KeyCode.H,
    },
}

-- ============================================================
-- STATE
-- ============================================================
local CurrentTarget = nil
local CamLockTarget = nil
local FOVCircle = nil
local SilentAimConnection = nil

-- ============================================================
-- DRAWING (FOV circle)
-- ============================================================
if Drawing then
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Thickness = 2
    FOVCircle.NumSides = 64
    FOVCircle.Radius = Settings.Aimbot.FOV
    FOVCircle.Filled = false
    FOVCircle.Transparency = 1
    FOVCircle.Color = Color3.fromRGB(255, 255, 255)
    FOVCircle.Visible = false
end

local function UpdateFOVCircle()
    if not FOVCircle then return end
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOVCircle.Radius = Settings.Aimbot.FOV
    FOVCircle.Visible = Settings.Aimbot.Enabled
end

-- ============================================================
-- UTILS
-- ============================================================
local function IsValidTarget(player)
    if player == LocalPlayer then return false end
    local char = player.Character
    if not char then return false end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local part = char:FindFirstChild(Settings.Aimbot.TargetPart)
    return humanoid and humanoid.Health > 0 and part ~= nil
end

local function GetScreenCenter()
    return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end

local function GetClosestToCenter()
    local closest = nil
    local closestDist = math.huge
    local center = GetScreenCenter()

    for _, player in ipairs(Players:GetPlayers()) do
        if IsValidTarget(player) then
            local part = player.Character[Settings.Aimbot.TargetPart]
            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
            if onScreen then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                if dist <= Settings.Aimbot.FOV and dist < closestDist then
                    closestDist = dist
                    closest = player
                end
            end
        end
    end
    return closest
end

local function GetClosestToMouse()
    local closest = nil
    local closestDist = math.huge
    local mousePos = UserInputService:GetMouseLocation()

    for _, player in ipairs(Players:GetPlayers()) do
        if IsValidTarget(player) then
            local part = player.Character[Settings.Aimbot.TargetPart]
            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
            if onScreen then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                if dist <= Settings.Aimbot.FOV and dist < closestDist then
                    closestDist = dist
                    closest = player
                end
            end
        end
    end
    return closest
end

-- ============================================================
-- AIMBOT / SILENT AIM / CAM LOCK
-- ============================================================
local function ApplyAimbot()
    if not Settings.Aimbot.Enabled then return end
    CurrentTarget = GetClosestToCenter()
    if CurrentTarget and IsValidTarget(CurrentTarget) then
        local part = CurrentTarget.Character[Settings.Aimbot.TargetPart]
        local targetPos = part.Position
        local newCFrame = CFrame.new(Camera.CFrame.Position, targetPos)
        Camera.CFrame = Camera.CFrame:Lerp(newCFrame, Settings.Aimbot.Smoothness)
    end
end

local function ApplySilentAim()
    if not Settings.SilentAim.Enabled then return end
    -- Silent aim: redireciona o mouse pro alvo mais próximo sem mover a câmera
    local target = GetClosestToMouse()
    if target and IsValidTarget(target) then
        local part = target.Character[Settings.Aimbot.TargetPart]
        local screenPos = Camera:WorldToViewportPoint(part.Position)
        if screenPos then
            -- força a posição do mouse pro alvo (funciona em alguns executores)
            if mousemoverel then
                local center = GetScreenCenter()
                local delta = Vector2.new(screenPos.X, screenPos.Y) - center
                mousemoverel(delta.X, delta.Y)
            end
        end
    end
end

local function ApplyCamLock()
    if not Settings.CamLock.Enabled then return end
    if not CamLockTarget or not IsValidTarget(CamLockTarget) then
        CamLockTarget = GetClosestToCenter()
    end
    if CamLockTarget and IsValidTarget(CamLockTarget) then
        local part = CamLockTarget.Character[Settings.Aimbot.TargetPart]
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, part.Position)
    end
end

-- ============================================================
-- ESP
-- ============================================================
local ESPObjects = {}

local function CreateESP(player)
    if player == LocalPlayer then return end
    local char = player.Character
    if not char then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "KAkiraESP"
    highlight.FillColor = Settings.ESP.FillColor
    highlight.OutlineColor = Settings.ESP.OutlineColor
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Adornee = char
    highlight.Parent = char

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "KAkiraHealth"
    billboard.Size = UDim2.new(0, 100, 0, 20)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Adornee = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
    billboard.Parent = char

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0
    label.TextScaled = true
    label.Font = Enum.Font.SourceSansBold
    label.Parent = billboard

    ESPObjects[player] = {Highlight = highlight, Billboard = billboard, Label = label}
end

local function RemoveESP(player)
    local obj = ESPObjects[player]
    if obj then
        if obj.Highlight then obj.Highlight:Destroy() end
        if obj.Billboard then obj.Billboard:Destroy() end
        ESPObjects[player] = nil
    end
end

local function UpdateESP()
    for player, obj in pairs(ESPObjects) do
        if not player.Character or not player.Character:FindFirstChildOfClass("Humanoid") or player.Character.Humanoid.Health <= 0 then
            RemoveESP(player)
        else
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hum and obj.Label then
                obj.Label.Text = player.Name .. " [" .. math.floor(hum.Health) .. "]"
            end
        end
    end
end

-- ============================================================
-- SPEED / JUMP
-- ============================================================
local function ApplySpeed()
    if not Settings.Speed.Enabled then return end
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = Settings.Speed.Value
        end
    end
end

local function ApplyJump()
    if not Settings.Jump.Enabled then return end
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.UseJumpPower = true
            hum.JumpPower = Settings.Jump.Value
        end
    end
end

-- ============================================================
-- FAST ATTACK
-- ============================================================
local function ApplyFastAttack()
    if not Settings.FastAttack.Enabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end

    local closestPlayer = GetClosestToCenter()
    if closestPlayer and IsValidTarget(closestPlayer) then
        local targetRoot = closestPlayer.Character:FindFirstChild("HumanoidRootPart")
        local myRoot = char:FindFirstChild("HumanoidRootPart")
        if targetRoot and myRoot then
            local dist = (targetRoot.Position - myRoot.Position).Magnitude
            if dist <= Settings.FastAttack.Range then
                tool:Activate()
            end
        end
    end
end

-- ============================================================
-- MAIN LOOP
-- ============================================================
RunService.RenderStepped:Connect(function()
    UpdateFOVCircle()
    ApplyAimbot()
    ApplySilentAim()
    ApplyCamLock()
    ApplySpeed()
    ApplyJump()
    ApplyFastAttack()
    UpdateESP()
end)

-- ============================================================
-- PLAYER HOOKS
-- ============================================================
local function OnCharacterAdded(char)
    char:WaitForChild("Humanoid")
    if Settings.ESP.Enabled then
        CreateESP(LocalPlayer) -- não faz nada pro local, mas garante
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            if Settings.ESP.Enabled then CreateESP(p) end
        end
    end
end

local function OnPlayerAdded(player)
    if Settings.ESP.Enabled then
        CreateESP(player)
    end
    player.CharacterAdded:Connect(function()
        if Settings.ESP.Enabled then
            CreateESP(player)
        end
    end)
end

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        OnPlayerAdded(p)
    end
end
Players.PlayerAdded:Connect(OnPlayerAdded)

LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)

-- ============================================================
-- INPUT
-- ============================================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Settings.Aimbot.Key then
        Settings.Aimbot.Enabled = not Settings.Aimbot.Enabled
    elseif input.KeyCode == Settings.SilentAim.Key then
        Settings.SilentAim.Enabled = not Settings.SilentAim.Enabled
    elseif input.KeyCode == Settings.CamLock.Key then
        Settings.CamLock.Enabled = not Settings.CamLock.Enabled
        CamLockTarget = nil
    elseif input.KeyCode == Settings.Speed.Key then
        Settings.Speed.Enabled = not Settings.Speed.Enabled
    elseif input.KeyCode == Settings.Jump.Key then
        Settings.Jump.Enabled = not Settings.Jump.Enabled
    elseif input.KeyCode == Settings.FastAttack.Key then
        Settings.FastAttack.Enabled = not Settings.FastAttack.Enabled
    end
end)

-- ============================================================
-- UI
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KAkiraHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Name = "Main"
MainFrame.Size = UDim2.new(0, 480, 0, 320)
MainFrame.Position = UDim2.new(0.5, -240, 0.5, -160)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(60, 60, 70)
UIStroke.Thickness = 1
UIStroke.Parent = MainFrame

-- Título
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundTransparency = 1
Title.Text = "K akira e filho do asta"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.Parent = MainFrame

-- Botão fechar
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.Parent = MainFrame
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui.Enabled = false
end)

-- Container das abas
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -20, 0, 32)
TabBar.Position = UDim2.new(0, 10, 0, 35)
TabBar.BackgroundTransparency = 1
TabBar.Parent = MainFrame

local TabList = Instance.new("UIListLayout")
TabList.FillDirection = Enum.FillDirection.Horizontal
TabList.Padding = UDim.new(0, 6)
TabList.Parent = TabBar

local TabFrames = {}
local CurrentTab = nil

local function CreateTab(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 100, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.Parent = TabBar
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 1, -80)
    frame.Position = UDim2.new(0, 10, 0, 75)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = MainFrame
    local fcorner = Instance.new("UICorner")
    fcorner.CornerRadius = UDim.new(0, 6)
    fcorner.Parent = frame

    TabFrames[name] = frame

    btn.MouseButton1Click:Connect(function()
        for _, f in pairs(TabFrames) do
            f.Visible = false
        end
        frame.Visible = true
        CurrentTab = name
    end)

    return frame
end

local MemoryTab = CreateTab("Memory")
local VisualsTab = CreateTab("Visuals")
local MiscTab = CreateTab("Misc")

-- helper pra criar toggle
local function AddToggle(parent, text, initial, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 32)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Position = UDim2.new(0, 5, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, 40, 0, 20)
    toggle.Position = UDim2.new(1, -45, 0.5, -10)
    toggle.BackgroundColor3 = initial and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(60, 60, 65)
    toggle.Text = initial and "ON" or "OFF"
    toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggle.Font = Enum.Font.GothamBold
    toggle.TextSize = 10
    toggle.Parent = frame
    local tcorner = Instance.new("UICorner")
    tcorner.CornerRadius = UDim.new(0, 4)
    tcorner.Parent = toggle

    local state = initial
    toggle.MouseButton1Click:Connect(function()
        state = not state
        toggle.BackgroundColor3 = state and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(60, 60, 65)
        toggle.Text = state and "ON" or "OFF"
        callback(state)
    end)
end

-- helper pra slider
local function AddSlider(parent, text, min, max, initial, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 50)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 0, 20)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. tostring(initial)
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -20, 0, 6)
    bar.Position = UDim2.new(0, 5, 0, 30)
    bar.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    bar.BorderSizePixel = 0
    bar.Parent = frame
    local bcorner = Instance.new("UICorner")
    bcorner.CornerRadius = UDim.new(0, 3)
    bcorner.Parent = bar

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((initial - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    fill.BorderSizePixel = 0
    fill.Parent = bar
    local fcorner = Instance.new("UICorner")
    fcorner.CornerRadius = UDim.new(0, 3)
    fcorner.Parent = fill

    local dragging = false
    local function Update(input)
        local pos = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local value = math.floor(min + (max - min) * pos)
        fill.Size = UDim2.new(pos, 0, 1, 0)
        label.Text = text .. ": " .. tostring(value)
        callback(value)
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            Update(input)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            Update(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- ============================================================
-- MEMORY TAB
-- ============================================================
AddSlider(MemoryTab, "WalkSpeed", 0, 1000, 16, function(v)
    Settings.Speed.Value = v
end)
AddToggle(MemoryTab, "Speed Boost (F)", false, function(s)
    Settings.Speed.Enabled = s
end)

AddSlider(MemoryTab, "JumpPower", 0, 1000, 50, function(v)
    Settings.Jump.Value = v
end)
AddToggle(MemoryTab, "Jump Boost (G)", false, function(s)
    Settings.Jump.Enabled = s
end)

AddToggle(MemoryTab, "Fast Attack (H)", false, function(s)
    Settings.FastAttack.Enabled = s
end)

-- ============================================================
-- VISUALS TAB
-- ============================================================
AddToggle(VisualsTab, "Aimbot (Q)", false, function(s)
    Settings.Aimbot.Enabled = s
end)
AddSlider(VisualsTab, "FOV Radius", 20, 600, 120, function(v)
    Settings.Aimbot.FOV = v
end)
AddToggle(VisualsTab, "Silent Aim (Z)", false, function(s)
    Settings.SilentAim.Enabled = s
end)
AddToggle(VisualsTab, "Cam Lock (E)", false, function(s)
    Settings.CamLock.Enabled = s
end)

-- ============================================================
-- MISC TAB
-- ============================================================
AddToggle(MiscTab, "ESP Highlight", false, function(s)
    Settings.ESP.Enabled = s
    if s then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then CreateESP(p) end
        end
    else
        for p, _ in pairs(ESPObjects) do
            RemoveESP(p)
        end
    end
end)

AddToggle(MiscTab, "Show Health", true, function(s)
    Settings.ESP.ShowHealth = s
end)

-- ============================================================
-- INIT
-- ============================================================
MemoryTab.Visible = true
CurrentTab = "Memory"
