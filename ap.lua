-- [[ 1. ตัวแปรและบริการระบบ ]]
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VIM = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local _G_Farming = false
local _G_AutoSkill = false
local _G_Distance = 7       -- ระยะเริ่มต้น (ขั้นต่ำ 5)
local _G_SkillDelay = 1.0   -- เวลาหน่วงเริ่มต้น

-- [[ 2. ฟังก์ชันจำลองการกดสกิล ]]
local function CastSkill(key)
    pcall(function()
        VIM:SendKeyEvent(true, Enum.KeyCode[key], false, game)
        task.wait(0.05)
        VIM:SendKeyEvent(false, Enum.KeyCode[key], false, game)
    end)
end

-- [[ 3. ลอจิกฟาร์ม V5 ]]
local function StartAutoFarm()
    while _G_Farming do
        task.wait()
        
        local zombiesFolder = Workspace:FindFirstChild("Zombies")
        if not zombiesFolder then continue end

        for _, mob in pairs(zombiesFolder:GetChildren()) do
            if not _G_Farming then break end

            local targetPart = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Torso") or mob.PrimaryPart or mob:FindFirstChildWhichIsA("BasePart", true)
            local targetHum = mob:FindFirstChildOfClass("Humanoid")

            local function isAlive()
                if not mob or not mob.Parent then return false end
                if targetHum then return targetHum.Health > 0 end
                return true
            end

            if not targetPart then continue end 

            while _G_Farming and isAlive() do
                task.wait()
                
                local char = LocalPlayer.Character
                if not char then break end
                local myRoot = char:FindFirstChild("HumanoidRootPart")
                local myHum = char:FindFirstChild("Humanoid")

                if myRoot and myHum and myHum.Health > 0 then
                    -- วาปไปด้านหลังตามระยะทางที่ปรับจาก Slider
                    myRoot.CFrame = targetPart.CFrame * CFrame.new(0, 0, _G_Distance)
                    task.wait(0.1) -- ซิงค์ตำแหน่ง

                    -- ตรวจสอบว่าเปิดระบบออโต้สกิลไว้ไหม
                    if _G_AutoSkill then
                        CastSkill("Z")
                        CastSkill("X")
                        CastSkill("C")
                    end

                    -- หน่วงเวลาตามค่าที่รูดปรับจาก Slider
                    task.wait(_G_SkillDelay)
                else
                    break
                end
            end
        end
    end
end

-- [[ 4. การสร้าง GUI เน้น UX ใช้งานง่าย (Clean Dark) ]]
local UI_Parent = (pcall(function() return game:GetService("CoreGui").Name end) and game:GetService("CoreGui")) or LocalPlayer:WaitForChild("PlayerGui")
if UI_Parent:FindFirstChild("LunaHubV5") then UI_Parent.LunaHubV5:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LunaHubV5"
ScreenGui.Parent = UI_Parent

-- หน้าต่างหลัก (ขยายขนาดรองรับปุ่มและ Slider ใหม่)
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 280, 0, 270)
MainFrame.Position = UDim2.new(0.5, -140, 0.5, -135)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

-- หัวข้อ GUI
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Text = "🌙 LUNA HUB V5"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.Parent = MainFrame
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 10)

-- ปุ่มเปิด/ปิดฟาร์ม
local FarmBtn = Instance.new("TextButton")
FarmBtn.Size = UDim2.new(0.9, 0, 0, 35)
FarmBtn.Position = UDim2.new(0.05, 0, 0, 45)
FarmBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
FarmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FarmBtn.Text = "AUTO FARM: OFF"
FarmBtn.Font = Enum.Font.GothamBold
FarmBtn.TextSize = 13
FarmBtn.Parent = MainFrame
Instance.new("UICorner", FarmBtn).CornerRadius = UDim.new(0, 6)

-- ปุ่มเปิด/ปิดสกิล
local SkillBtn = Instance.new("TextButton")
SkillBtn.Size = UDim2.new(0.9, 0, 0, 35)
SkillBtn.Position = UDim2.new(0.05, 0, 0, 90)
SkillBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
SkillBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SkillBtn.Text = "AUTO SKILL (Z,X,C): OFF"
SkillBtn.Font = Enum.Font.GothamBold
SkillBtn.TextSize = 13
SkillBtn.Parent = MainFrame
Instance.new("UICorner", SkillBtn).CornerRadius = UDim.new(0, 6)

-- --- ส่วนของ Slider 1: ระยะห่าง ---
local DistLabel = Instance.new("TextLabel")
DistLabel.Size = UDim2.new(0.9, 0, 0, 20)
DistLabel.Position = UDim2.new(0.05, 0, 0, 135)
DistLabel.BackgroundTransparency = 1
DistLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
DistLabel.Text = "Distance Barrier: " .. _G_Distance .. " Studs"
DistLabel.Font = Enum.Font.Gotham
DistLabel.TextSize = 12
DistLabel.TextXAlignment = Enum.TextXAlignment.Left
DistLabel.Parent = MainFrame

local DistBG = Instance.new("TextButton")
DistBG.Size = UDim2.new(0.9, 0, 0, 10)
DistBG.Position = UDim2.new(0.05, 0, 0, 160)
DistBG.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
DistBG.Text = ""
DistBG.Parent = MainFrame
Instance.new("UICorner", DistBG).CornerRadius = UDim.new(0, 4)

local DistFill = Instance.new("Frame")
DistFill.Size = UDim2.new((_G_Distance - 5) / 25, 0, 1, 0) -- คำนวณสัดส่วนจากช่วง 5 ถึง 30
DistFill.BackgroundColor3 = Color3.fromRGB(0, 160, 255)
DistFill.BorderSizePixel = 0
DistFill.Parent = DistBG
Instance.new("UICorner", DistFill).CornerRadius = UDim.new(0, 4)

-- --- ส่วนของ Slider 2: เวลาหน่วงสกิล ---
local DelayLabel = Instance.new("TextLabel")
DelayLabel.Size = UDim2.new(0.9, 0, 0, 20)
DelayLabel.Position = UDim2.new(0.05, 0, 0, 185)
DelayLabel.BackgroundTransparency = 1
DelayLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
DelayLabel.Text = "Skill Cooldown Delay: " .. string.format("%.1f", _G_SkillDelay) .. "s"
DelayLabel.Font = Enum.Font.Gotham
DelayLabel.TextSize = 12
DelayLabel.TextXAlignment = Enum.TextXAlignment.Left
DelayLabel.Parent = MainFrame

local DelayBG = Instance.new("TextButton")
DelayBG.Size = UDim2.new(0.9, 0, 0, 10)
DelayBG.Position = UDim2.new(0.05, 0, 0, 210)
DelayBG.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
DelayBG.Text = ""
DelayBG.Parent = MainFrame
Instance.new("UICorner", DelayBG).CornerRadius = UDim.new(0, 4)

local DelayFill = Instance.new("Frame")
DelayFill.Size = UDim2.new((_G_SkillDelay - 0.1) / 2.9, 0, 1, 0) -- คำนวณสัดส่วนจากช่วง 0.1 ถึง 3.0
DelayFill.BackgroundColor3 = Color3.fromRGB(255, 160, 0)
DelayFill.BorderSizePixel = 0
DelayFill.Parent = DelayBG
Instance.new("UICorner", DelayFill).CornerRadius = UDim.new(0, 4)


-- [[ 5. ผูกลอจิกปุ่มและการรูด Slider ]]

-- ปุ่ม Farm
FarmBtn.MouseButton1Click:Connect(function()
    _G_Farming = not _G_Farming
    if _G_Farming then
        FarmBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
        FarmBtn.Text = "AUTO FARM: ON"
        task.spawn(StartAutoFarm)
    else
        FarmBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        FarmBtn.Text = "AUTO FARM: OFF"
    end
end)

-- ปุ่ม Skill
SkillBtn.MouseButton1Click:Connect(function()
    _G_AutoSkill = not _G_AutoSkill
    if _G_AutoSkill then
        SkillBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
        SkillBtn.Text = "AUTO SKILL (Z,X,C): ON"
    else
        SkillBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        SkillBtn.Text = "AUTO SKILL (Z,X,C): OFF"
    end
end)

-- ลอจิกการรูด Sliders
local dragDist = false
local dragDelay = false

DistBG.MouseButton1Down:Connect(function() dragDist = true end)
DelayBG.MouseButton1Down:Connect(function() dragDelay = true end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then 
        dragDist = false 
        dragDelay = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        local mouseX = UserInputService:GetMouseLocation().X
        
        -- ควบคุม Slider ระยะห่าง
        if dragDist then
            local relativeX = mouseX - DistBG.AbsolutePosition.X
            local percent = math.clamp(relativeX / DistBG.AbsoluteSize.X, 0, 1)
            _G_Distance = math.floor(5 + (percent * 25)) -- ตั้งค่าระยะห่างได้ตั้งแต่ 5 ถึง 30 Studs
            
            DistFill.Size = UDim2.new(percent, 0, 1, 0)
            DistLabel.Text = "Distance Barrier: " .. _G_Distance .. " Studs"
        end
        
        -- ควบคุม Slider หน่วงเวลาสกิล
        if dragDelay then
            local relativeX = mouseX - DelayBG.AbsolutePosition.X
            local percent = math.clamp(relativeX / DelayBG.AbsoluteSize.X, 0, 1)
            _G_SkillDelay = 0.1 + (percent * 2.9) -- ตั้งค่าหน่วงเวลาได้ตั้งแต่ 0.1 ถึง 3.0 วินาที
            
            DelayFill.Size = UDim2.new(percent, 0, 1, 0)
            DelayLabel.Text = "Skill Cooldown Delay: " .. string.format("%.1f", _G_SkillDelay) .. "s"
        end
    end
end)
