-- [[ 1. ตัวแปรและบริการระบบ ]]
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage") -- แก้ไขจุดที่ทำให้ Error แล้ว
local VIM = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local configFileName = "LunaHub_DelaySave.json"

-- บังคับเปิดสถานะเหล่านี้เสมอ
_G_Farming = true
_G_AutoSkill = true
_G_MagnetItems = true 

-- ค่าเริ่มต้น
_G_Distance = 7        
_G_SkillDelay = 0.5   

-- [[ 2. ระบบ Save / Load แบบปลอดภัย 100% ]]
local function SaveSettings()
    if type(writefile) == "function" then
        pcall(function()
            local data = { Distance = _G_Distance, SkillDelay = _G_SkillDelay }
            writefile(configFileName, HttpService:JSONEncode(data))
        end)
    end
end

local function LoadSettings()
    if type(isfile) == "function" and type(readfile) == "function" then
        pcall(function()
            if isfile(configFileName) then
                local result = HttpService:JSONDecode(readfile(configFileName))
                if result then
                    _G_Distance = result.Distance or 7
                    _G_SkillDelay = result.SkillDelay or 0.5
                end
            end
        end)
    end
end

LoadSettings()

-- [[ 3. ฟังก์ชันจำลองคีย์บอร์ด ]]
local function PressKey(key)
    pcall(function()
        VIM:SendKeyEvent(true, Enum.KeyCode[key], false, game)
        task.wait(0.02)
        VIM:SendKeyEvent(false, Enum.KeyCode[key], false, game)
    end)
end

-- [[ 4. ลูปที่ 1: ระบบฟาร์ม, สร้างห้อง และ Auto Replay ]]
task.spawn(function()
    while true do
        task.wait()
        if _G_Farming then
            local char = LocalPlayer.Character
            local myRoot = char and char:FindFirstChild("HumanoidRootPart")
            
            local zones = Workspace:FindFirstChild("Zones")
            local zombiesFolder = Workspace:FindFirstChild("Zombies")

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
            
            elseif not zombiesFolder or #zombiesFolder:GetChildren() == 0 then
                task.wait(2)
                if _G_Farming and (not Workspace:FindFirstChild("Zombies") or #Workspace.Zombies:GetChildren() == 0) and not (Workspace:FindFirstChild("Zones") and Workspace.Zones:FindFirstChild("RaidShop")) then
                    pcall(function()
                        local interactRemote = ReplicatedStorage:WaitForChild("Assets", 2):WaitForChild("Remotes", 2):WaitForChild("Interact", 2)
                        if interactRemote then
                            interactRemote:FireServer("PlayAgain")
                        end
                    end)
                    task.wait(5)
                end

            elseif zombiesFolder and myRoot then
                for _, mob in pairs(zombiesFolder:GetChildren()) do
                    if not _G_Farming then break end
                    local targetPart = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Torso") or mob.PrimaryPart or mob:FindFirstChildWhichIsA("BasePart", true)
                    local targetHum = mob:FindFirstChildOfClass("Humanoid")

                    local function isAlive()
                        if not mob or not mob.Parent then return false end
                        if targetHum then return targetHum.Health > 0 end
                        return true
                    end

                    while _G_Farming and targetPart and isAlive() do
                        task.wait()
                        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then break end
                        myRoot.CFrame = targetPart.CFrame * CFrame.new(0, 0, _G_Distance)
                    end
                end
            end
        end
    end
end)

-- [[ 5. ลูปที่ 2: ระบบ Auto Skill ]]
task.spawn(function()
    while true do
        task.wait()
        if _G_Farming and _G_AutoSkill then
            local zombiesFolder = Workspace:FindFirstChild("Zombies")
            if zombiesFolder and #zombiesFolder:GetChildren() > 0 then
                task.spawn(function() PressKey("E") end)
                task.spawn(function() PressKey("Z") end)
                task.spawn(function() PressKey("X") end)
                task.spawn(function() PressKey("C") end)
                task.wait(_G_SkillDelay)
            end
        end
    end
end)

-- [[ 6. ลูปที่ 3: Smart Magnet ดูดของ ]]
task.spawn(function()
    while true do
        task.wait(0.2)
        if _G_Farming and _G_MagnetItems then
            local thrownFolder = Workspace:FindFirstChild("Thrown")
            local char = LocalPlayer.Character
            local myRoot = char and char:FindFirstChild("HumanoidRootPart")
            
            if thrownFolder and myRoot then
                for _, item in pairs(thrownFolder:GetChildren()) do
                    pcall(function()
                        local itemPart = item:IsA("BasePart") and item or item:FindFirstChildWhichIsA("BasePart", true)
                        if itemPart and itemPart:IsA("BasePart") and not itemPart.Anchored then
                            itemPart.CFrame = myRoot.CFrame
                        end
                    end)
                end
            end
        end
    end
end)

-- [[ 7. GUI ]]
local UI_Parent = (pcall(function() return game:GetService("CoreGui").Name end) and game:GetService("CoreGui")) or LocalPlayer:WaitForChild("PlayerGui")
if UI_Parent:FindFirstChild("LunaHubV13") then UI_Parent.LunaHubV13:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LunaHubV13"
ScreenGui.Parent = UI_Parent

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 280, 0, 255)
MainFrame.Position = UDim2.new(0.5, -140, 0.5, -127)
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
Title.Text = "🌙 LUNA HUB V13.1 | HOTFIX"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.Parent = MainFrame
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 10)

local FarmBtn = Instance.new("TextButton")
FarmBtn.Size = UDim2.new(0.9, 0, 0, 30)
FarmBtn.Position = UDim2.new(0.05, 0, 0, 45)
FarmBtn.BackgroundColor3 = _G_Farming and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(180, 40, 40)
FarmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FarmBtn.Text = "1. MAIN FARM & REPLAY: " .. (_G_Farming and "ON" or "OFF")
FarmBtn.Font = Enum.Font.GothamBold
FarmBtn.TextSize = 11
FarmBtn.Parent = MainFrame
Instance.new("UICorner", FarmBtn).CornerRadius = UDim.new(0, 6)

local SkillBtn = Instance.new("TextButton")
SkillBtn.Size = UDim2.new(0.9, 0, 0, 30)
SkillBtn.Position = UDim2.new(0.05, 0, 0, 80)
SkillBtn.BackgroundColor3 = _G_AutoSkill and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(180, 40, 40)
SkillBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SkillBtn.Text = "2. AUTO SKILL (E,Z,X,C): " .. (_G_AutoSkill and "ON" or "OFF")
SkillBtn.Font = Enum.Font.GothamBold
SkillBtn.TextSize = 11
SkillBtn.Parent = MainFrame
Instance.new("UICorner", SkillBtn).CornerRadius = UDim.new(0, 6)

local MagnetBtn = Instance.new("TextButton")
MagnetBtn.Size = UDim2.new(0.9, 0, 0, 30)
MagnetBtn.Position = UDim2.new(0.05, 0, 0, 115)
MagnetBtn.BackgroundColor3 = _G_MagnetItems and Color3.fromRGB(0, 130, 200) or Color3.fromRGB(180, 40, 40)
MagnetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MagnetBtn.Text = "3. SMART MAGNET (ดูดของ): " .. (_G_MagnetItems and "ON" or "OFF")
MagnetBtn.Font = Enum.Font.GothamBold
MagnetBtn.TextSize = 11
MagnetBtn.Parent = MainFrame
Instance.new("UICorner", MagnetBtn).CornerRadius = UDim.new(0, 6)

local DistLabel = Instance.new("TextLabel")
DistLabel.Size = UDim2.new(0.9, 0, 0, 20)
DistLabel.Position = UDim2.new(0.05, 0, 0, 155)
DistLabel.BackgroundTransparency = 1
DistLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
DistLabel.Text = "Back-TP Distance: " .. _G_Distance .. " Studs"
DistLabel.Font = Enum.Font.Gotham
DistLabel.TextSize = 11
DistLabel.TextXAlignment = Enum.TextXAlignment.Left
DistLabel.Parent = MainFrame

local DistBG = Instance.new("TextButton")
DistBG.Size = UDim2.new(0.9, 0, 0, 8)
DistBG.Position = UDim2.new(0.05, 0, 0, 175)
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

local DelayLabel = Instance.new("TextLabel")
DelayLabel.Size = UDim2.new(0.9, 0, 0, 20)
DelayLabel.Position = UDim2.new(0.05, 0, 0, 195)
DelayLabel.BackgroundTransparency = 1
DelayLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
DelayLabel.Text = "Skill Loop Delay: " .. string.format("%.1f", _G_SkillDelay) .. "s"
DelayLabel.Font = Enum.Font.Gotham
DelayLabel.TextSize = 11
DelayLabel.TextXAlignment = Enum.TextXAlignment.Left
DelayLabel.Parent = MainFrame

local DelayBG = Instance.new("TextButton")
DelayBG.Size = UDim2.new(0.9, 0, 0, 8)
DelayBG.Position = UDim2.new(0.05, 0, 0, 215)
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

FarmBtn.MouseButton1Click:Connect(function()
    _G_Farming = not _G_Farming
    FarmBtn.BackgroundColor3 = _G_Farming and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(180, 40, 40)
    FarmBtn.Text = "1. MAIN FARM & REPLAY: " .. (_G_Farming and "ON" or "OFF")
end)

SkillBtn.MouseButton1Click:Connect(function()
    _G_AutoSkill = not _G_AutoSkill
    SkillBtn.BackgroundColor3 = _G_AutoSkill and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(180, 40, 40)
    SkillBtn.Text = "2. AUTO SKILL (E,Z,X,C): " .. (_G_AutoSkill and "ON" or "OFF")
end)

MagnetBtn.MouseButton1Click:Connect(function()
    _G_MagnetItems = not _G_MagnetItems
    MagnetBtn.BackgroundColor3 = _G_MagnetItems and Color3.fromRGB(0, 130, 200) or Color3.fromRGB(180, 40, 40)
    MagnetBtn.Text = "3. SMART MAGNET (ดูดของ): " .. (_G_MagnetItems and "ON" or "OFF")
end)

local dragDist, dragDelay = false, false
DistBG.MouseButton1Down:Connect(function() dragDist = true end)
DelayBG.MouseButton1Down:Connect(function() dragDelay = true end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then 
        if dragDist or dragDelay then SaveSettings() end
        dragDist, dragDelay = false, false 
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        local mouseX = UserInputService:GetMouseLocation().X
        if dragDist then
            local p = math.clamp((mouseX - DistBG.AbsolutePosition.X) / DistBG.AbsoluteSize.X, 0, 1)
            _G_Distance = math.floor(5 + (p * 25))
            DistFill.Size = UDim2.new(p, 0, 1, 0)
            DistLabel.Text = "Back-TP Distance: " .. _G_Distance .. " Studs"
        end
        if dragDelay then
            local p = math.clamp((mouseX - DelayBG.AbsolutePosition.X) / DelayBG.AbsoluteSize.X, 0, 1)
            _G_SkillDelay = 0.1 + (p * 2.9)
            DelayFill.Size = UDim2.new(p, 0, 1, 0)
            DelayLabel.Text = "Skill Loop Delay: " .. string.format("%.1f", _G_SkillDelay) .. "s"
        end
    end
end)
