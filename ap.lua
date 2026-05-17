-- [[ 1. ตัวแปรและบริการระบบ ]]
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VIM = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local _G_Farming = false
local _G_Distance = 7

-- [[ 2. ฟังก์ชันจำลองการกดสกิล ]]
local function CastSkill(key)
    pcall(function()
        VIM:SendKeyEvent(true, Enum.KeyCode[key], false, game)
        task.wait(0.05)
        VIM:SendKeyEvent(false, Enum.KeyCode[key], false, game)
    end)
end

-- [[ 3. ลอจิกฟาร์ม V4 (โคตรครอบจักรวาล) ]]
local function StartAutoFarm()
    while _G_Farming do
        task.wait()
        
        local zombiesFolder = Workspace:FindFirstChild("Zombies")
        if not zombiesFolder then continue end

        for _, mob in pairs(zombiesFolder:GetChildren()) do
            if not _G_Farming then break end

            -- ทะลวงหาชิ้นส่วนอะไรก็ได้ในตัวมอนสเตอร์เพื่อใช้เป็นจุดวาป
            local targetPart = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Torso") or mob.PrimaryPart or mob:FindFirstChildWhichIsA("BasePart", true)
            local targetHum = mob:FindFirstChildOfClass("Humanoid")

            -- ฟังก์ชันเช็คว่ามอนตายหรือยัง (รองรับทั้งแมพที่มีเลือดและไม่มีเลือด)
            local function isAlive()
                if not mob or not mob.Parent then return false end -- ถ้าตัวมอนหายไปจากแมพ = ตายแล้ว
                if targetHum then return targetHum.Health > 0 end -- ถ้ามีระบบเลือดมาตรฐาน = เช็คเลือด
                return true -- ถ้าไม่มีระบบเลือดเลย ให้ตีต่อไปจนกว่าโมเดลมันจะสลายไป
            end

            -- ถ้าหาชิ้นส่วนอะไรในตัวมอนไม่ได้เลย (เช่นบั๊ก) ให้ข้ามไปตัวต่อไป
            if not targetPart then continue end 

            -- ลูปตีจนกว่าจะตาย
            while _G_Farming and isAlive() do
                task.wait()
                
                local char = LocalPlayer.Character
                if not char then break end
                local myRoot = char:FindFirstChild("HumanoidRootPart")
                local myHum = char:FindFirstChild("Humanoid")

                if myRoot and myHum and myHum.Health > 0 then
                    -- วาปไปด้านหลังชิ้นส่วนอะไรก็ตามที่หาเจอ
                    myRoot.CFrame = targetPart.CFrame * CFrame.new(0, 0, _G_Distance)
                    task.wait(0.1)

                    -- กดสกิล
                    CastSkill("Z")
                    CastSkill("X")
                    CastSkill("C")

                    task.wait(1)
                else
                    break
                end
            end
        end
    end
end

-- [[ 4. GUI ]]
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
Title.Text = "🌙 LUNA HUB V4 | AUTO FARM"
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

-- [[ 5. เชื่อมต่อระบบ ]]
ToggleBtn.MouseButton1Click:Connect(function()
    _G_Farming = not _G_Farming
    if _G_Farming then
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
        ToggleBtn.Text = "AUTO FARM: ON"
        task.spawn(StartAutoFarm)
    else
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        ToggleBtn.Text = "AUTO FARM: OFF"
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
