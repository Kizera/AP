-- [[ 1. ตัวแปรระบบ ]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VIM = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local _G_Farming = false
local _G_Distance = 7

-- [[ 2. ฟังก์ชันจำลองการกดคีย์บอร์ด ]]
local function PressSkill(key)
    -- ใช้ pcall ดัก error เผื่อ Executor บางตัวไม่รองรับ VIM 100%
    pcall(function()
        VIM:SendKeyEvent(true, Enum.KeyCode[key], false, game)
        task.wait(0.05)
        VIM:SendKeyEvent(false, Enum.KeyCode[key], false, game)
    end)
end

-- [[ 3. ลอจิกฟาร์มแบบ ล็อกเป้าจนตาย ]]
local function AutoFarm()
    while _G_Farming do
        task.wait()
        
        local zombiesFolder = Workspace:FindFirstChild("Zombies")
        if not zombiesFolder then continue end

        for _, zombie in pairs(zombiesFolder:GetChildren()) do
            if not _G_Farming then break end
            if not zombie:IsA("Model") then continue end
            
            -- รองรับมอนสเตอร์ทั้งแบบ R6 (Torso) และ R15 (HumanoidRootPart)
            local zRoot = zombie:FindFirstChild("HumanoidRootPart") or zombie:FindFirstChild("Torso")
            local zHum = zombie:FindFirstChild("Humanoid")
            
            -- ลูปตีมอนสเตอร์ตัวนี้จนกว่าเลือดจะหมด
            while _G_Farming and zRoot and zHum and zHum.Health > 0 do
                task.wait()
                
                -- รีเฟรชตัวละครเราตลอดเวลา ป้องกันสคริปต์พังตอนเราตาย
                local char = LocalPlayer.Character
                if not char then break end
                local myRoot = char:FindFirstChild("HumanoidRootPart")
                local myHum = char:FindFirstChild("Humanoid")
                
                if not myRoot or not myHum or myHum.Health <= 0 then break end

                -- วาปไปด้านหลังมอนสเตอร์
                myRoot.CFrame = zRoot.CFrame * CFrame.new(0, 0, _G_Distance)
                
                -- กดสกิล
                PressSkill("Z")
                PressSkill("X")
                PressSkill("C")
                
                -- หน่วงเวลา 1 วินาที
                task.wait(1)
            end
        end
    end
end

-- [[ 4. GUI (ป้องกันจอดำ/ดึงเข้า PlayerGui ถ้า CoreGui โดนบล็อก) ]]
local UI_Parent = (pcall(function() return game:GetService("CoreGui").Name end) and game:GetService("CoreGui")) or LocalPlayer:WaitForChild("PlayerGui")

if UI_Parent:FindFirstChild("LunaAutoFarmV2") then
    UI_Parent.LunaAutoFarmV2:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LunaAutoFarmV2"
ScreenGui.Parent = UI_Parent

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 250, 0, 150)
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
Title.Text = "Luna Hub | Farm V2"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.Parent = MainFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.8, 0, 0, 35)
ToggleBtn.Position = UDim2.new(0.1, 0, 0, 45)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Text = "OFF"
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

-- [[ 5. ผูกปุ่ม ]]
ToggleBtn.MouseButton1Click:Connect(function()
    _G_Farming = not _G_Farming
    if _G_Farming then
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        ToggleBtn.Text = "ON"
        task.spawn(AutoFarm)
    else
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        ToggleBtn.Text = "OFF"
    end
end)

local UserInputService = game:GetService("UserInputService")
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
        _G_Distance = math.floor(percent * 20) 
        
        SliderFill.Size = UDim2.new(percent, 0, 1, 0)
        SliderTitle.Text = "Distance: " .. _G_Distance
    end
end)
