-- [[ 1. ตัวแปรและบริการระบบ ]]
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VIM = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
_G_Farming = true
_G_Distance = 7
_G_SkillDelay = 0.5 

-- [[ 2. ระบบค้นหาเป้าหมาย (ฟาร์มเฉพาะโฟลเดอร์ Zombies) ]]
local function GetCurrentZombie()
    local folder = Workspace:FindFirstChild("Zombies")
    if not folder then return nil end
    
    for _, mob in pairs(folder:GetChildren()) do
        local root = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Torso") or mob.PrimaryPart or mob:FindFirstChildWhichIsA("BasePart", true)
        local hum = mob:FindFirstChildOfClass("Humanoid")
        
        if root and (not hum or hum.Health > 0) then
            return root
        end
    end
    return nil
end

-- [[ 3. ฟังก์ชันจำลองการกดสกิล (Z, X, C, V, E, G) ]]
local skills = {"Z", "X", "C", "V", "E", "G"}
local function CastAllSkills()
    for _, key in pairs(skills) do
        task.spawn(function()
            pcall(function()
                VIM:SendKeyEvent(true, Enum.KeyCode[key], false, game)
                task.wait(0.03)
                VIM:SendKeyEvent(false, Enum.KeyCode[key], false, game)
            end)
        end)
    end
end

-- [[ 4. ลูปที่ 1: ระบบวาปฟาร์มเป้าหมาย ]]
task.spawn(function()
    while true do
        task.wait()
        if _G_Farming then
            local char = LocalPlayer.Character
            local myRoot = char and char:FindFirstChild("HumanoidRootPart")
            
            if myRoot then
                local targetPart = GetCurrentZombie()
                if targetPart and targetPart.Parent then
                    myRoot.CFrame = targetPart.CFrame * CFrame.new(0, 0, _G_Distance)
                end
            end
        end
    end
end)

-- [[ 5. ลูปที่ 2: ระบบ Auto Skill ]]
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

-- [[ 6. ลูปที่ 3: ระบบแม่เหล็กดึงเฉพาะ TouchInterest (ฟีเจอร์เด็ด!) ]]
task.spawn(function()
    while true do
        task.wait(0.15) -- สแกนไวขึ้นนิดนึงเพื่อให้ดึงของเข้าตัวทันที
        if _G_Farming then
            local thrownFolder = Workspace:FindFirstChild("Thrown")
            local char = LocalPlayer.Character
            local myRoot = char and char:FindFirstChild("HumanoidRootPart")
            
            if thrownFolder and myRoot then
                -- ใช้ GetDescendants() เพื่อมุดทะลวงเข้าไปหา TouchInterest ที่ซ่อนอยู่ลึกๆ (เช่นใน CoinDrop.Hitbox)
                for _, obj in pairs(thrownFolder:GetDescendants()) do
                    if obj.Name == "TouchInterest" or obj:IsA("TouchTransmitter") then
                        local itemHitbox = obj.Parent -- ดึงชิ้นส่วนที่ครอบ TouchInterest อยู่ (เช่น Hitbox)
                        if itemHitbox and itemHitbox:IsA("BasePart") then
                            pcall(function()
                                -- วาร์ปกล่อง Hitbox นั้นมาที่ตัวเรา
                                itemHitbox.CFrame = myRoot.CFrame
                            end)
                        end
                    end
                end
            end
        end
    end
end)

-- [[ 7. การสร้าง GUI V4.2 ]]
local UI_Parent = (pcall(function() return game:GetService("CoreGui").Name end) and game:GetService("CoreGui")) or LocalPlayer:WaitForChild("PlayerGui")
if UI_Parent:FindFirstChild("LunaHubV4_2") then UI_Parent.LunaHubV4_2:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LunaHubV4_2"
ScreenGui.Parent = UI_Parent

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 260, 0, 150)
MainFrame.Position = UDim2.new(0.5, -125, 0.5, -75)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Text = "Luna Hub | V4.2 Touch Magnet"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.Parent = MainFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.8, 0, 0, 35)
ToggleBtn.Position = UDim2.new(0.1, 0, 0, 45)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Text = "FARM: ON"
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 14
ToggleBtn.Parent = MainFrame

local SliderTitle = Instance.new("TextLabel")
SliderTitle.Size = UDim2.new(1, 0, 0, 20)
SliderTitle.Position = UDim2.new(0, 0, 0, 90)
SliderTitle.BackgroundTransparency = 1
SliderTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
SliderTitle.Text = "Distance: " .. _G_Distance
SliderTitle.Font = Enum.Font.Gotham
SliderTitle.TextSize = 12
SliderTitle.Parent = MainFrame

local SliderBG = Instance.new("TextButton")
SliderBG.Size = UDim2.new(0.8, 0, 0, 10)
SliderBG.Position = UDim2.new(0.1, 0, 0, 115)
SliderBG.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
SliderBG.Text = ""
SliderBG.Parent = MainFrame

local SliderFill = Instance.new("Frame")
SliderFill.Size = UDim2.new(_G_Distance / 20, 0, 1, 0)
SliderFill.BackgroundColor3 = Color3.fromRGB(80, 150, 255)
SliderFill.Parent = SliderBG

-- ระบบผูกปุ่ม
ToggleBtn.MouseButton1Click:Connect(function()
    _G_Farming = not _G_Farming
    if _G_Farming then
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        ToggleBtn.Text = "FARM: ON"
    else
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        ToggleBtn.Text = "FARM: OFF"
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
        _G_Distance = math.floor(5 + (percent * 20)) 
        
        SliderFill.Size = UDim2.new(percent, 0, 1, 0)
        SliderTitle.Text = "Distance: " .. _G_Distance
    end
end)
