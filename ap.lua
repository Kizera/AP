-- [[ 1. ตัวแปรและบริการระบบ ]]
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VIM = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- ค่าเริ่มต้น (สำหรับ Autoexec)
_G_Farming = true
_G_AutoSkill = true
_G_BringMobs = true -- ระบบใหม่: รวบมอน
_G_Distance = 15    -- ปรับระยะเริ่มต้นให้ไกลขึ้นนิดนึง เพราะมอนจะมากองรวมกันตรงหน้าเรา (กันเราโดนดาเมจ)
_G_SkillDelay = 0.5 -- ปรับให้สับสกิลไวขึ้น  

-- [[ 2. ฟังก์ชันจำลองปุ่มและเมาส์ ]]
local function PressKey(key)
    pcall(function()
        VIM:SendKeyEvent(true, Enum.KeyCode[key], false, game)
        task.wait(0.02)
        VIM:SendKeyEvent(false, Enum.KeyCode[key], false, game)
    end)
end

local function ClickMouse()
    pcall(function()
        VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.wait(0.01)
        VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end)
end

-- [[ 3. ลอจิกหลัก (Auto Lobby + Bring Mobs) ]]
local function StartAutoFarm()
    while _G_Farming do
        task.wait()
        
        local char = LocalPlayer.Character
        local myRoot = char and char:FindFirstChild("HumanoidRootPart")
        
        -- =======================================
        -- โหมด 1: ตรวจสอบหน้า Lobby และสร้างห้อง
        -- =======================================
        local zones = Workspace:FindFirstChild("Zones")
        if zones and zones:FindFirstChild("RaidShop") then
            pcall(function()
                local platforms = Workspace:WaitForChild("Platforms", 3)
                if not platforms then return end
                local platform = platforms:WaitForChild("Platform", 3)
                
                local interactRemote = ReplicatedStorage:WaitForChild("Assets", 3)
                    :WaitForChild("Remotes", 3)
                    :WaitForChild("Interact", 3)

                if platform and interactRemote then
                    local args = {
                        "CreateMatch",
                        platform,
                        {
                            IsTaken = true,
                            Difficulty = "Gravewalker",
                            Map = "Shibuya",
                            Mode = "Survival",
                            FriendsOnly = true,
                            MaxPlayers = 1
                        }
                    }
                    interactRemote:FireServer(unpack(args))
                end
            end)
            task.wait(5)
            continue 
        end

        -- =======================================
        -- โหมด 2: ระบบฟาร์มมอนสเตอร์ (Bring Mobs / TP)
        -- =======================================
        local zombiesFolder = Workspace:FindFirstChild("Zombies")
        if zombiesFolder and myRoot then
            
            if _G_BringMobs then
                -- ท่าไม้ตาย: ดูดมอนทุกตัวมากองตรงหน้า
                local mobsAlive = false
                
                for _, mob in pairs(zombiesFolder:GetChildren()) do
                    local targetPart = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Torso") or mob.PrimaryPart or mob:FindFirstChildWhichIsA("BasePart", true)
                    local targetHum = mob:FindFirstChildOfClass("Humanoid")

                    if targetPart and targetHum and targetHum.Health > 0 then
                        mobsAlive = true
                        -- วาปมอนสเตอร์มาที่ด้านหน้าของเรา (-Z คือด้านหน้า)
                        targetPart.CFrame = myRoot.CFrame * CFrame.new(0, 0, -_G_Distance)
                        -- ล็อกความเร็วมอนสเตอร์ไม่ให้กระเด็นหรือเดินหนี
                        targetPart.Velocity = Vector3.new(0,0,0)
                        targetPart.RotVelocity = Vector3.new(0,0,0)
                    end
                end
                
                -- ถ้ามีมอนสเตอร์หลงเหลืออยู่ ให้เราสาดสกิลรัวๆ
                if mobsAlive then
                    ClickMouse()
                    if _G_AutoSkill then
                        PressKey("E") PressKey("Z") PressKey("X") PressKey("C")
                    end
                    task.wait(_G_SkillDelay)
                end
                
            else
                -- ลอจิกเดิม: วาปไปตีทีละตัว (กรณีปิดปุ่มดึงมอน)
                for _, mob in pairs(zombiesFolder:GetChildren()) do
                    if not _G_Farming or _G_BringMobs then break end
                    local targetPart = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Torso") or mob:FindFirstChildWhichIsA("BasePart", true)
                    local targetHum = mob:FindFirstChildOfClass("Humanoid")

                    while _G_Farming and not _G_BringMobs and targetPart and targetHum and targetHum.Health > 0 do
                        task.wait()
                        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then break end
                        
                        myRoot.CFrame = targetPart.CFrame * CFrame.new(0, 0, _G_Distance)
                        task.wait(0.05)

                        ClickMouse()
                        if _G_AutoSkill then
                            PressKey("E") PressKey("Z") PressKey("X") PressKey("C")
                        end
                        task.wait(_G_SkillDelay)
                    end
                end
            end
        end
    end
end

-- [[ 4. GUI V8 (เพิ่มปุ่ม Bring Mobs) ]]
local UI_Parent = (pcall(function() return game:GetService("CoreGui").Name end) and game:GetService("CoreGui")) or LocalPlayer:WaitForChild("PlayerGui")
if UI_Parent:FindFirstChild("LunaHubV8") then UI_Parent.LunaHubV8:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LunaHubV8"
ScreenGui.Parent = UI_Parent

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 280, 0, 310) -- ขยายความสูงรองรับปุ่มใหม่
MainFrame.Position = UDim2.new(0.5, -140, 0.5, -155)
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
Title.Text = "🌙 LUNA HUB V8 | BLACK HOLE"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.Parent = MainFrame
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 10)

-- ปุ่ม 1: Farm
local FarmBtn = Instance.new("TextButton")
FarmBtn.Size = UDim2.new(0.9, 0, 0, 30)
FarmBtn.Position = UDim2.new(0.05, 0, 0, 45)
FarmBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
FarmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FarmBtn.Text = "1. AUTO FARM: ON"
FarmBtn.Font = Enum.Font.GothamBold
FarmBtn.TextSize = 12
FarmBtn.Parent = MainFrame
Instance.new("UICorner", FarmBtn).CornerRadius = UDim.new(0, 6)

-- ปุ่ม 2: Skill
local SkillBtn = Instance.new("TextButton")
SkillBtn.Size = UDim2.new(0.9, 0, 0, 30)
SkillBtn.Position = UDim2.new(0.05, 0, 0, 80)
SkillBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
SkillBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SkillBtn.Text = "2. AUTO SKILL (E,Z,X,C): ON"
SkillBtn.Font = Enum.Font.GothamBold
SkillBtn.TextSize = 12
SkillBtn.Parent = MainFrame
Instance.new("UICorner", SkillBtn).CornerRadius = UDim.new(0, 6)

-- ปุ่ม 3: Bring Mobs (รวบมอน)
local BringBtn = Instance.new("TextButton")
BringBtn.Size = UDim2.new(0.9, 0, 0, 30)
BringBtn.Position = UDim2.new(0.05, 0, 0, 115)
BringBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 180) -- สีม่วงหลุมดำ
BringBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
BringBtn.Text = "3. BRING MOBS (รวบมอน): ON"
BringBtn.Font = Enum.Font.GothamBold
BringBtn.TextSize = 12
BringBtn.Parent = MainFrame
Instance.new("UICorner", BringBtn).CornerRadius = UDim.new(0, 6)

-- Slider 1: Distance
local DistLabel = Instance.new("TextLabel")
DistLabel.Size = UDim2.new(0.9, 0, 0, 20)
DistLabel.Position = UDim2.new(0.05, 0, 0, 155)
DistLabel.BackgroundTransparency = 1
DistLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
DistLabel.Text = "Mob Distance: " .. _G_Distance .. " Studs"
DistLabel.Font = Enum.Font.Gotham
DistLabel.TextSize = 12
DistLabel.TextXAlignment = Enum.TextXAlignment.Left
DistLabel.Parent = MainFrame

local DistBG = Instance.new("TextButton")
DistBG.Size = UDim2.new(0.9, 0, 0, 10)
DistBG.Position = UDim2.new(0.05, 0, 0, 180)
DistBG.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
DistBG.Text = ""
DistBG.Parent = MainFrame
Instance.new("UICorner", DistBG).CornerRadius = UDim.new(0, 4)

local DistFill = Instance.new("Frame")
DistFill.Size = UDim2.new((_G_Distance - 5) / 25, 0, 1, 0)
DistFill.BackgroundColor3 = Color3.fromRGB(0, 160, 255)
DistFill.BorderSizePixel = 0
DistFill.Parent = DistBG
Instance.new("UICorner", DistFill).CornerRadius = UDim.new(0, 4)

-- Slider 2: Delay
local DelayLabel = Instance.new("TextLabel")
DelayLabel.Size = UDim2.new(0.9, 0, 0, 20)
DelayLabel.Position = UDim2.new(0.05, 0, 0, 205)
DelayLabel.BackgroundTransparency = 1
DelayLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
DelayLabel.Text = "Skill Delay: " .. string.format("%.1f", _G_SkillDelay) .. "s"
DelayLabel.Font = Enum.Font.Gotham
DelayLabel.TextSize = 12
DelayLabel.TextXAlignment = Enum.TextXAlignment.Left
DelayLabel.Parent = MainFrame

local DelayBG = Instance.new("TextButton")
DelayBG.Size = UDim2.new(0.9, 0, 0, 10)
DelayBG.Position = UDim2.new(0.05, 0, 0, 230)
DelayBG.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
DelayBG.Text = ""
DelayBG.Parent = MainFrame
Instance.new("UICorner", DelayBG).CornerRadius = UDim.new(0, 4)

local DelayFill = Instance.new("Frame")
DelayFill.Size = UDim2.new((_G_SkillDelay - 0.1) / 2.9, 0, 1, 0)
DelayFill.BackgroundColor3 = Color3.fromRGB(255, 160, 0)
DelayFill.BorderSizePixel = 0
DelayFill.Parent = DelayBG
Instance.new("UICorner", DelayFill).CornerRadius = UDim.new(0, 4)

-- คำเตือน
local WarnLabel = Instance.new("TextLabel")
WarnLabel.Size = UDim2.new(0.9, 0, 0, 40)
WarnLabel.Position = UDim2.new(0.05, 0, 0, 255)
WarnLabel.BackgroundTransparency = 1
WarnLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
WarnLabel.Text = "Note: ถ้ารวบมอนแล้วมอนเด้งกลับ แปลว่าเซิร์ฟเวอร์ล็อค Network Ownership ให้ปิดโหมด 3"
WarnLabel.Font = Enum.Font.Gotham
WarnLabel.TextSize = 10
WarnLabel.TextWrapped = true
WarnLabel.Parent = MainFrame

-- [[ 5. ผูกระบบ ]]
FarmBtn.MouseButton1Click:Connect(function()
    _G_Farming = not _G_Farming
    FarmBtn.BackgroundColor3 = _G_Farming and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(180, 40, 40)
    FarmBtn.Text = "1. AUTO FARM: " .. (_G_Farming and "ON" or "OFF")
    if _G_Farming then task.spawn(StartAutoFarm) end
end)

SkillBtn.MouseButton1Click:Connect(function()
    _G_AutoSkill = not _G_AutoSkill
    SkillBtn.BackgroundColor3 = _G_AutoSkill and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(180, 40, 40)
    SkillBtn.Text = "2. AUTO SKILL (E,Z,X,C): " .. (_G_AutoSkill and "ON" or "OFF")
end)

BringBtn.MouseButton1Click:Connect(function()
    _G_BringMobs = not _G_BringMobs
    BringBtn.BackgroundColor3 = _G_BringMobs and Color3.fromRGB(150, 40, 180) or Color3.fromRGB(180, 40, 40)
    BringBtn.Text = "3. BRING MOBS (รวบมอน): " .. (_G_BringMobs and "ON" or "OFF")
end)

local dragDist, dragDelay = false, false
DistBG.MouseButton1Down:Connect(function() dragDist = true end)
DelayBG.MouseButton1Down:Connect(function() dragDelay = true end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragDist, dragDelay = false, false end
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        local mouseX = UserInputService:GetMouseLocation().X
        if dragDist then
            local p = math.clamp((mouseX - DistBG.AbsolutePosition.X) / DistBG.AbsoluteSize.X, 0, 1)
            _G_Distance = math.floor(5 + (p * 25))
            DistFill.Size = UDim2.new(p, 0, 1, 0)
            DistLabel.Text = "Mob Distance: " .. _G_Distance .. " Studs"
        end
        if dragDelay then
            local p = math.clamp((mouseX - DelayBG.AbsolutePosition.X) / DelayBG.AbsoluteSize.X, 0, 1)
            _G_SkillDelay = 0.1 + (p * 2.9)
            DelayFill.Size = UDim2.new(p, 0, 1, 0)
            DelayLabel.Text = "Skill Delay: " .. string.format("%.1f", _G_SkillDelay) .. "s"
        end
    end
end)

task.spawn(StartAutoFarm)
