-- [[ 1. SERVICES ]]
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VIM = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- [[ GLOBAL ]]
_G_Farming = false
_G_Distance = 7
_G.AutoCollect = true

-- [[ 2. SKILL ]]
local function CastSkill(key)
    pcall(function()
        VIM:SendKeyEvent(true, Enum.KeyCode[key], false, game)
        task.wait(0.05)
        VIM:SendKeyEvent(false, Enum.KeyCode[key], false, game)
    end)
end

-- [[ 3. FIND MOB ]]
local function GetClosestMob()
    local zombiesFolder = Workspace:FindFirstChild("Zombies")
    if not zombiesFolder then return nil end

    local char = LocalPlayer.Character
    if not char then return nil end

    local myRoot = char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    local closest = nil
    local shortest = math.huge

    for _, mob in pairs(zombiesFolder:GetChildren()) do
        local hum = mob:FindFirstChildOfClass("Humanoid")
        local part = mob:FindFirstChild("HumanoidRootPart") or mob.PrimaryPart

        if part and hum and hum.Health > 0 then
            local dist = (part.Position - myRoot.Position).Magnitude
            if dist < shortest then
                shortest = dist
                closest = mob
            end
        end
    end

    return closest
end

-- [[ 4. AUTO FARM ]]
local function StartAutoFarm()
    while _G_Farming do
        task.wait()

        local mob = GetClosestMob()
        if not mob then
            task.wait(0.5)
            continue
        end

        local targetPart = mob:FindFirstChild("HumanoidRootPart") or mob.PrimaryPart
        local targetHum = mob:FindFirstChildOfClass("Humanoid")

        while _G_Farming and targetHum and targetHum.Health > 0 do
            task.wait()

            local char = LocalPlayer.Character
            if not char then break end

            local myRoot = char:FindFirstChild("HumanoidRootPart")
            local myHum = char:FindFirstChild("Humanoid")

            if myRoot and myHum and myHum.Health > 0 then
                myRoot.CFrame = targetPart.CFrame * CFrame.new(0, 0, _G_Distance)

                CastSkill("Z")
                CastSkill("X")
                CastSkill("C")

                task.wait(0.3)
            else
                break
            end
        end
    end
end

-- [[ 5. ITEM MAGNET ]]
local function StartItemMagnet()
    while _G_Farming and _G.AutoCollect do
        task.wait(0.2)

        local char = LocalPlayer.Character
        if not char then continue end

        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then continue end

        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("Tool") or v.Name:lower():find("drop") or v.Name:lower():find("coin") then
                local part = v:FindFirstChild("Handle") or v:FindFirstChildWhichIsA("BasePart")
                
                if part then
                    part.CFrame = root.CFrame
                end
            end
        end
    end
end

-- [[ 6. GUI ]]
local UI_Parent = (pcall(function() return game:GetService("CoreGui").Name end) and game:GetService("CoreGui")) or LocalPlayer:WaitForChild("PlayerGui")
if UI_Parent:FindFirstChild("LunaHubV4") then UI_Parent.LunaHubV4:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LunaHubV4"
ScreenGui.Parent = UI_Parent

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 260, 0, 180)
MainFrame.Position = UDim2.new(0.5, -130, 0.5, -90)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Text = "🌙 LUNA HUB V5 | AUTO FARM"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.Parent = MainFrame
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 10)

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.85, 0, 0, 40)
ToggleBtn.Position = UDim2.new(0.075, 0, 0, 50)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Text = "AUTO FARM: OFF"
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 14
ToggleBtn.Parent = MainFrame
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 8)

local SliderLabel = Instance.new("TextLabel")
SliderLabel.Size = UDim2.new(1, 0, 0, 30)
SliderLabel.Position = UDim2.new(0, 0, 0, 100)
SliderLabel.BackgroundTransparency = 1
SliderLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
SliderLabel.Text = "TP Distance: " .. _G_Distance
SliderLabel.Font = Enum.Font.Gotham
SliderLabel.TextSize = 13
SliderLabel.Parent = MainFrame

local SliderBG = Instance.new("TextButton")
SliderBG.Size = UDim2.new(0.85, 0, 0, 12)
SliderBG.Position = UDim2.new(0.075, 0, 0, 135)
SliderBG.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
SliderBG.Text = ""
SliderBG.Parent = MainFrame
Instance.new("UICorner", SliderBG).CornerRadius = UDim.new(0, 5)

local SliderFill = Instance.new("Frame")
SliderFill.Size = UDim2.new(_G_Distance / 25, 0, 1, 0)
SliderFill.BackgroundColor3 = Color3.fromRGB(0, 160, 255)
SliderFill.BorderSizePixel = 0
SliderFill.Parent = SliderBG
Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(0, 5)

-- [[ 7. EVENTS ]]
ToggleBtn.MouseButton1Click:Connect(function()
    _G_Farming = not _G_Farming

    if _G_Farming then
        _G.AutoCollect = true

        ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
        ToggleBtn.Text = "AUTO FARM: ON"

        task.spawn(StartAutoFarm)
        task.spawn(StartItemMagnet)
    else
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        ToggleBtn.Text = "AUTO FARM: OFF"

        _G.AutoCollect = false
    end
end)

local dragging = false
SliderBG.MouseButton1Down:Connect(function() dragging = true end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local mousePos = UserInputService:GetMouseLocation().X
        local sliderPos = SliderBG.AbsolutePosition.X
        local sliderSize = SliderBG.AbsoluteSize.X
        
        local percent = math.clamp((mousePos - sliderPos) / sliderSize, 0, 1)
        _G_Distance = math.floor(percent * 25)

        SliderFill.Size = UDim2.new(percent, 0, 1, 0)
        SliderLabel.Text = "TP Distance: " .. _G_Distance
    end
end)
