-- [[ 1. ตัวแปรและบริการระบบ ]]
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VIM = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
_G_Farming = true
_G_Magnet = true 
_G_Distance = 7
_G_SkillDelay = 0.5 

-- [[ 2. ระบบทำลายอนิเมชั่นสกิล (Fast Attack / No Cast Time) ]]
task.spawn(function()
    pcall(function()
        local animsFolder = ReplicatedStorage:WaitForChild("Assets", 5)
        if animsFolder then
            animsFolder = animsFolder:WaitForChild("Anims", 5)
        end
        
        if animsFolder then
            -- 1. กวาดลบ ID อนิเมชั่นที่มีอยู่แล้วทั้งหมด
            for _, anim in pairs(animsFolder:GetDescendants()) do
                if anim:IsA("Animation") then
                    anim.AnimationId = "" 
                end
            end
            
            -- 2. ดักจับอนิเมชั่นใหม่ที่อาจจะเกิดตอนขึ้นด่านใหม่ แล้วลบทิ้งทันที
            animsFolder.DescendantAdded:Connect(function(anim)
                if anim:IsA("Animation") then
                    anim.AnimationId = ""
                end
            end)
            print("Luna Hub: ทำลายระบบอนิเมชั่นร่ายสกิลสำเร็จ (Fast Attack Ready)")
        end
    end)
end)

-- [[ 3. ฟังก์ชันดึงชื่อเควสปัจจุบัน ]]
local function GetCurrentObjectiveName()
    local objectives = Workspace:FindFirstChild("Objectives")
    if objectives then
        local child = objectives:GetChildren()[1]
        if child then return child.Name end
    end
    return ""
end

-- [[ 4. ระบบค้นหาเป้าหมาย (มุดหาแบบ Deep Scan ทะลวง Model) ]]
local function GetCurrentZombie()
    local folder = Workspace:FindFirstChild("Zombies")
    if not folder then return nil, nil end
    
    -- ใช้ GetDescendants() เพื่อมุดหา Model ที่ซ้อนอยู่ข้างในให้เจอ
    for _, obj in pairs(folder:GetDescendants()) do
        if obj:IsA("Model") then
            local root = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso") or obj.PrimaryPart
            local hum = obj:FindFirstChildOfClass("Humanoid")
            
            if root and hum and hum.Health > 0 then
                return root, hum
            end
        end
    end
    return nil, nil
end

-- [[ 5. ฟังก์ชันออโต้สกิลชุดเต็ม (Z, X, C, V, E, G) ]]
local skills = {"Z", "X", "C", "V", "E", "G"}
local function CastAllSkills()
    for _, key in pairs(skills) do
        task.spawn(function()
            pcall(function()
                VIM:SendKeyEvent(true, Enum.KeyCode[key], false, game)
                task.wait(0.02)
                VIM:SendKeyEvent(false, Enum.KeyCode[key], false, game)
            end)
        end)
    end
end

-- [[ 6. ลูปอิสระที่ 1: ระบบวาปฟาร์ม + ตัวดักจับเควส ]]
task.spawn(function()
    while true do
        task.wait()
        if _G_Farming then
            local char = LocalPlayer.Character
            local myRoot = char and char:FindFirstChild("HumanoidRootPart")
            
            if myRoot then
                local targetPart, targetHum = GetCurrentZombie()
                if targetPart and targetPart.Parent then
                    
                    local startObjective = GetCurrentObjectiveName()
                    
                    while _G_Farming and targetPart and targetPart.Parent and (targetHum and targetHum.Health > 0) do
                        task.wait()
                        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then break end
                        
                        -- รีเซ็ตล็อคเป้าทันทีที่ Section เควสเปลี่ยน
                        if GetCurrentObjectiveName() ~= startObjective then break end
                        
                        myRoot.CFrame = targetPart.CFrame * CFrame.new(0, 0, _G_Distance)
                    end
                end
            end
        end
    end
end)

-- [[ 7. ลูปอิสระที่ 2: ระบบ Auto Skill ]]
task.spawn(function()
    while true do
        task.wait(0.1)
        if _G_Farming then
            local targetPart = GetCurrentZombie()
            if targetPart then
                CastAllSkills()
                task.wait(_G_SkillDelay)
            end
        end
    end
end)

-- [[ 8. ลูปอิสระที่ 3: ระบบแม่เหล็กดูด TouchInterest ]]
task.spawn(function()
    while true do
        task.wait(0.15)
        if _G_Magnet then
            local thrownFolder = Workspace:FindFirstChild("Thrown")
            local char = LocalPlayer.Character
            local myRoot = char and char:FindFirstChild("HumanoidRootPart")
            
            if thrownFolder and myRoot then
                for _, obj in pairs(thrownFolder:GetDescendants()) do
                    if obj.Name == "TouchInterest" or obj:IsA("TouchTransmitter") then
                        local itemHitbox = obj.Parent
                        if itemHitbox and itemHitbox:IsA("BasePart") then
                            pcall(function()
                                itemHitbox.CFrame = myRoot.CFrame
                            end)
                        end
                    end
                end
            end
        end
    end
end)

-- [[ 9. การสร้าง GUI V4.4 ]]
local UI_Parent = (pcall(function() return game:GetService("CoreGui").Name end) and game:GetService("CoreGui")) or LocalPlayer:WaitForChild("PlayerGui")
if UI_Parent:FindFirstChild("LunaHubV4_4") then UI_Parent.LunaHubV4_4:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LunaHubV4_4"
ScreenGui.Parent = UI_Parent

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 260, 0, 165)
MainFrame.Position = UDim2.new(0.5, -125, 0.5, -82)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Text = "Luna Hub | V4.4 Deep Scan"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 12
Title.Parent = MainFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.42, 0, 0, 30)
ToggleBtn.Position = UDim2.new(0.05, 0, 0, 40)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Text = "FARM: ON"
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 11
ToggleBtn.Parent = MainFrame
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 5)

local MagnetBtn = Instance.new("TextButton")
MagnetBtn.Size = UDim2.new(0.42, 0, 0, 30)
MagnetBtn.Position = UDim2.new(0.53, 0, 0, 40)
MagnetBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
MagnetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MagnetBtn.Text = "MAGNET: ON"
MagnetBtn.Font = Enum.Font.GothamBold
MagnetBtn.TextSize = 11
MagnetBtn.Parent = MainFrame
Instance.new("UICorner", MagnetBtn).CornerRadius = UDim.new(0, 5)

local SliderTitle = Instance.new("TextLabel")
SliderTitle.Size = UDim2.new(1, 0, 0, 20)
SliderTitle.Position = UDim2.new(0, 0, 0, 85)
SliderTitle.BackgroundTransparency = 1
SliderTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
SliderTitle.Text = "Distance: " .. _G_Distance
SliderTitle.Font = Enum.Font.Gotham
SliderTitle.TextSize = 12
SliderTitle.Parent = MainFrame

local SliderBG = Instance.new("TextButton")
SliderBG.Size = UDim2.new(0.8, 0, 0, 10)
SliderBG.Position = UDim2.new(0.1, 0, 0, 110)
SliderBG.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
SliderBG.Text = ""
SliderBG.Parent = MainFrame

local SliderFill = Instance.new("Frame")
SliderFill.Size = UDim2.new(_G_Distance / 20, 0, 1, 0)
SliderFill.BackgroundColor3 = Color3.fromRGB(80, 150, 255)
SliderFill.Parent = SliderBG

-- ผูกปุ่ม
ToggleBtn.MouseButton1Click:Connect(function()
    _G_Farming = not _G_Farming
    ToggleBtn.BackgroundColor3 = _G_Farming and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
    ToggleBtn.Text = "FARM: " .. (_G_Farming and "ON" or "OFF")
end)

MagnetBtn.MouseButton1Click:Connect(function()
    _G_Magnet = not _G_Magnet
    MagnetBtn.BackgroundColor3 = _G_Magnet and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
    MagnetBtn.Text = "MAGNET: " .. (_G_Magnet and "ON" or "OFF")
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
        _G_Distance = math.floor(5 + (percent * 20)) 
        
        SliderFill.Size = UDim2.new(percent, 0, 1, 0)
        SliderTitle.Text = "Distance: " .. _G_Distance
    end
end)
