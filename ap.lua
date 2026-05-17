-- [[ 1. ตัวแปรและบริการระบบ ]]
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VIM = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local Camera = Workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer

-- ค่าเริ่มต้น (รองรับ Autoexec ย้ายแมพเปิดทันที)
_G_Farming = true
_G_AutoSkill = true
_G_BringMobs = true 
_G_MagnetItems = true -- ฟีเจอร์ใหม่: เปิดแม่เหล็กดูดของอัตโนมัติ
_G_Distance = 12       
_G_SkillDelay = 0.5   

-- [[ 2. ฟังก์ชันระบบคีย์บอร์ด & เมาส์ระดับโปร ]]
local function PressKey(key)
    pcall(function()
        VIM:SendKeyEvent(true, Enum.KeyCode[key], false, game)
        task.wait(0.02)
        VIM:SendKeyEvent(false, Enum.KeyCode[key], false, game)
    end)
end

local function ClickCenterScreen()
    pcall(function()
        -- คำนวณจุดกึ่งกลางหน้าจอแบบเรียลไทม์เพื่อให้คลิกติด 100%
        local screenSize = Camera.ViewportSize
        local centerX = screenSize.X / 2
        local centerY = screenSize.Y / 2
        VIM:SendMouseButtonEvent(centerX, centerY, 0, true, game, 0)
        task.wait(0.01)
        VIM:SendMouseButtonEvent(centerX, centerY, 0, false, game, 0)
    end)
end

-- [[ 3. ลูปอิสระที่ 1: ระบบฟาร์มมอนสเตอร์ และ สร้างห้อง ]]
task.spawn(function()
    while true do
        task.wait()
        if _G_Farming then
            local char = LocalPlayer.Character
            local myRoot = char and char:FindFirstChild("HumanoidRootPart")
            
            -- ตรวจสอบหน้า Lobby
            local zones = Workspace:FindFirstChild("Zones")
            if zones and zones:FindFirstChild("RaidShop") then
                pcall(function()
                    local platform = Workspace:WaitForChild("Platforms", 2):WaitForChild("Platform", 2)
                    local remote = ReplicatedStorage:WaitForChild("Assets", 2):WaitForChild("Remotes", 2):WaitForChild("Interact", 2)
                    if platform and remote then
                        remote:FireServer("CreateMatch", platform, {
                            IsTaken = true, Difficulty = "Gravewalker", Map = "Shibuya",
                            Mode = "Survival", FriendsOnly = true, MaxPlayers = 1
                        })
                    end
                end)
                task.wait(5)
                continue
            end

            -- ตรวจสอบโฟลเดอร์มอนสเตอร์
            local zombiesFolder = Workspace:FindFirstChild("Zombies")
            if zombiesFolder and myRoot then
                if _G_BringMobs then
                    -- โหมดรวบมอนสเตอร์มากองตรงหน้า
                    for _, mob in pairs(zombiesFolder:GetChildren()) do
                        local targetPart = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Torso") or mob.PrimaryPart or mob:FindFirstChildWhichIsA("BasePart", true)
                        local targetHum = mob:FindFirstChildOfClass("Humanoid")

                        if targetPart and targetHum and targetHum.Health > 0 then
                            targetPart.CFrame = myRoot.CFrame * CFrame.new(0, 0, -_G_Distance)
                            targetPart.Velocity = Vector3.new(0,0,0)
                        end
                    end
                else
                    -- โหมดวาปไปหาทีละตัว (กรณีปิดรวบมอน)
                    for _, mob in pairs(zombiesFolder:GetChildren()) do
                        if not _G_Farming or _G_BringMobs then break end
                        local targetPart = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Torso") or mob:FindFirstChildWhichIsA("BasePart", true)
                        local targetHum = mob:FindFirstChildOfClass("Humanoid")

                        while _G_Farming and not _G_BringMobs and targetPart and targetHum and targetHum.Health > 0 do
                            task.wait()
                            if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then break end
                            myRoot.CFrame = targetPart.CFrame * CFrame.new(0, 0, _G_Distance)
                        end
                    end
                end
            end
        end
    end
end)

-- [[ 4. ลูปอิสระที่ 2: ระบบ Auto Click & Auto Skill (ไม่ผูกกับมอนสเตอร์) ]]
task.spawn(function()
    while true do
        task.wait()
        if _G_Farming then
            -- ตรวจสอบว่ามีมอนสเตอร์อยู่ในแมพไหม ถึงจะเริ่มโจมตี (กันกดมั่วหน้าล็อบบี้)
            local zombiesFolder = Workspace:FindFirstChild("Zombies")
            if zombiesFolder and #zombiesFolder:GetChildren() > 0 then
                
                -- สั่งคลิกซ้ายรัวๆ เป็นหลัก
                ClickCenterScreen()
                
                -- สั่งกดสกิลตามรอบการหน่วงเวลา
                if _G_AutoSkill then
                    task.spawn(function() PressKey("E") end)
                    task.spawn(function() PressKey("Z") end)
                    task.spawn(function() PressKey("X") end)
                    task.spawn(function() PressKey("C") end)
                    task.wait(_G_SkillDelay)
                end
            end
        end
    end
end)

-- [[ 5. ลูปอิสระที่ 3: ระบบแม่เหล็กดูดของ (workspace.Thrown) ]]
task.spawn(function()
    while true do
        task.wait(0.1) -- เช็คไอเทมทุกๆ 0.1 วินาที (รวดเร็วแต่ไม่กินสเปคคอม)
        if _G_Farming and _G_MagnetItems then
            local thrownFolder = Workspace:FindFirstChild("Thrown")
            local char = LocalPlayer.Character
            local myRoot = char and char:FindFirstChild("HumanoidRootPart")
            
            if thrownFolder and myRoot then
                for _, item in pairs(thrownFolder:GetChildren()) do
                    -- หาชิ้นส่วนที่เป็น Part ในไอเทมนั้นๆ ไม่ว่าโครงสร้างจะเป็นแบบไหน
                    local itemPart = item:IsA("BasePart") and item or item:FindFirstChildWhichIsA("BasePart", true)
                    if itemPart then
                        -- ดูดไอเทมมาที่ตำแหน่งตัวเราทันที
                        itemPart.CFrame = myRoot.CFrame
                    end
                end
            end
        end
    end
end)

-- [[ 6. การสร้าง GUI เน้นความง่าย สไตล์คลีน ]]
local UI_Parent = (pcall(function() return game:GetService("CoreGui").Name end) and game:GetService("CoreGui")) or LocalPlayer:WaitForChild("PlayerGui")
if UI_Parent:FindFirstChild("LunaHubV9") then UI_Parent.LunaHubV9:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LunaHubV9"
ScreenGui.Parent = UI_Parent

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 280, 0, 340) -- ปรับขนาดรองรับปุ่มแม่เหล็ก
MainFrame.Position = UDim2.new(0.5, -140, 0.5, -170)
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
Title.Text = "🌙 LUNA HUB V9 | MASTER"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.Parent = MainFrame
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 10)

-- ปุ่มฟาร์มหลัก
local FarmBtn = Instance.new("TextButton")
FarmBtn.Size = UDim2.new(0.9, 0, 0, 30)
FarmBtn.Position = UDim2.new(0.05, 0, 0, 45)
FarmBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
FarmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FarmBtn.Text = "1. MAIN FARM: ON"
FarmBtn.Font = Enum.Font.GothamBold
FarmBtn.TextSize = 11
FarmBtn.Parent = MainFrame
Instance.new("UICorner", FarmBtn).CornerRadius = UDim.new(0, 6)

-- ปุ่มออโต้สกิล
local SkillBtn = Instance.new("TextButton")
SkillBtn.Size = UDim2.new(0.9, 0, 0, 30)
SkillBtn.Position = UDim2.new(0.05, 0, 0, 80)
SkillBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
SkillBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SkillBtn.Text = "2. AUTO SKILL (E,Z,X,C): ON"
SkillBtn.Font = Enum.Font.GothamBold
SkillBtn.TextSize = 11
SkillBtn.Parent = MainFrame
Instance.new("UICorner", SkillBtn).CornerRadius = UDim.new(0, 6)

-- ปุ่มรวบมอน
local BringBtn = Instance.new("TextButton")
BringBtn.Size = UDim2.new(0.9, 0, 0, 30)
BringBtn.Position = UDim2.new(0.05, 0, 0, 115)
BringBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 180)
BringBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
BringBtn.Text = "3. BRING MOBS: ON"
BringBtn.Font = Enum.Font.GothamBold
BringBtn.TextSize = 11
BringBtn.Parent = MainFrame
Instance.new("UICorner", BringBtn).CornerRadius = UDim.new(0, 6)

-- ปุ่มแม่เหล็กดูดของ (Magnet Thrown)
local MagnetBtn = Instance.new("TextButton")
MagnetBtn.Size = UDim2.new(0.9, 0, 0, 30)
MagnetBtn.Position = UDim2.new(0.05, 0, 0, 150)
MagnetBtn.BackgroundColor3 = Color3.fromRGB(0, 130, 200) -- สีฟ้าครามแม่เหล็ก
MagnetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MagnetBtn.Text = "4. MAGNET THROWN (ดูดของ): ON"
MagnetBtn.Font = Enum.Font.GothamBold
MagnetBtn.TextSize = 11
MagnetBtn.Parent = MainFrame
Instance.new("UICorner", MagnetBtn).CornerRadius = UDim.new(0, 6)

-- Slider 1: Distance
local DistLabel = Instance.new("TextLabel")
DistLabel.Size = UDim2.new(0.9, 0, 0, 20)
DistLabel.Position = UDim2.new(0.05, 0, 0, 190)
DistLabel.BackgroundTransparency = 1
DistLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
DistLabel.Text = "Mob Distance: " .. _G_Distance .. " Studs"
DistLabel.Font = Enum.Font.Gotham
DistLabel.TextSize = 11
DistLabel.TextXAlignment = Enum.TextXAlignment.Left
DistLabel.Parent = MainFrame

local DistBG = Instance.new("TextButton")
DistBG.Size = UDim2.new(0.9, 0, 0, 8)
DistBG.Position = UDim2.new(0.05, 0, 0, 215)
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
DelayLabel.Position = UDim2.new(0.05, 0, 0, 235)
DelayLabel.BackgroundTransparency = 1
DelayLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
DelayLabel.Text = "Skill Cooldown Delay: " .. string.format("%.1f", _G_SkillDelay) .. "s"
DelayLabel.Font = Enum.Font.Gotham
DelayLabel.TextSize = 11
DelayLabel.TextXAlignment = Enum.TextXAlignment.Left
DelayLabel.Parent = MainFrame

local DelayBG = Instance.new("TextButton")
DelayBG.Size = UDim2.new(0.9, 0, 0, 8)
DelayBG.Position = UDim2.new(0.05, 0, 0, 260)
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

-- [[ 7. ระบบควบคุมการกดปุ่ม GUI ]]
FarmBtn.MouseButton1Click:Connect(function()
    _G_Farming = not _G_Farming
    FarmBtn.BackgroundColor3 = _G_Farming and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(180, 40, 40)
    FarmBtn.Text = "1. MAIN FARM: " .. (_G_Farming and "ON" or "OFF")
end)

SkillBtn.MouseButton1Click:Connect(function()
    _G_AutoSkill = not _G_AutoSkill
    SkillBtn.BackgroundColor3 = _G_AutoSkill and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(180, 40, 40)
    SkillBtn.Text = "2. AUTO SKILL (E,Z,X,C): " .. (_G_AutoSkill and "ON" or "OFF")
end)

BringBtn.MouseButton1Click:Connect(function()
    _G_BringMobs = not _G_BringMobs
    BringBtn.BackgroundColor3 = _G_BringMobs and Color3.fromRGB(150, 40, 180) or Color3.fromRGB(180, 40, 40)
    BringBtn.Text = "3. BRING MOBS: " .. (_G_BringMobs and "ON" or "OFF")
end)

MagnetBtn.MouseButton1Click:Connect(function()
    _G_MagnetItems = not _G_MagnetItems
    MagnetBtn.BackgroundColor3 = _G_MagnetItems and Color3.fromRGB(0, 130, 200) or Color3.fromRGB(180, 40, 40)
    MagnetBtn.Text = "4. MAGNET THROWN (ดูดของ): " .. (_G_MagnetItems and "ON" or "OFF")
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
            DelayLabel.Text = "Skill Cooldown Delay: " .. string.format("%.1f", _G_SkillDelay) .. "s"
        end
    end
end)
