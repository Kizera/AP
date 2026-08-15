-- [[ 1. ตัวแปรและบริการระบบ ]]
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VIM = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local configFileName = "LunaHub_V5_8_Save.json"

-- ค่าเริ่มต้นระบบ
_G_Farming = true
_G_AutoClick = true
_G_BossLock = false 
_G_Distance = 7
_G_SkillDelay = 0.5 

-- เพิ่ม F เข้ามาในระบบ
_G_SkillStates = {
    Z = true, X = true, C = true, 
    V = true, F = true, E = true, G = true
}

-- [[ 2. ระบบ Save / Load ]]
local function SaveSettings()
    if type(writefile) == "function" then
        pcall(function()
            local data = {
                Farming = _G_Farming,
                AutoClick = _G_AutoClick,
                BossLock = _G_BossLock,
                Distance = _G_Distance,
                SkillDelay = _G_SkillDelay,
                SkillStates = _G_SkillStates
            }
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
                    _G_Farming = result.Farming ~= nil and result.Farming or true
                    _G_AutoClick = result.AutoClick ~= nil and result.AutoClick or true
                    _G_BossLock = result.BossLock ~= nil and result.BossLock or false
                    _G_Distance = result.Distance or 7
                    _G_SkillDelay = result.SkillDelay or 0.5
                    if result.SkillStates then
                        for k, v in pairs(result.SkillStates) do _G_SkillStates[k] = v end
                    end
                end
            end
        end)
    end
end

LoadSettings()

-- [[ 3. ฟังก์ชันดึงชื่อเควสปัจจุบัน ]]
local function GetCurrentObjectiveName()
    local objectives = Workspace:FindFirstChild("Objectives")
    if objectives then
        local child = objectives:GetChildren()[1]
        if child then return child.Name end
    end
    return ""
end

-- [[ 4. ระบบ Global Scanner (สแกนลำดับความสำคัญ) ]]
local function GetCurrentZombie()
    local folder = Workspace:FindFirstChild("Zombies")
    if not folder then return nil, nil end
    
    -- 🔥 เช็ค Boss Lock: ลำดับ 1 คือ Pucci ต้องตายก่อน, ลำดับ 2 คือ DIO
    if _G_BossLock then
        local targetBosses = {"Pucci", "Dio Over Heaven"}
        for _, bossName in ipairs(targetBosses) do
            local boss = folder:FindFirstChild(bossName)
            if boss then
                local hum = boss:FindFirstChildOfClass("Humanoid")
                local root = boss:FindFirstChild("HumanoidRootPart") or boss:FindFirstChild("Torso")
                if hum and hum.Health > 0 and root then
                    return root, hum -- ถ้าเจอ Pucci จะรีเทิร์นไปหาทันที ไม่สนใจ DIO
                end
            end
        end
    end
    
    -- ถ้าไม่เจอบอส ค่อยตีลูกน้องปกติ
    for _, part in pairs(folder:GetDescendants()) do
        if (part.Name == "HumanoidRootPart" or part.Name == "Torso") and part:IsA("BasePart") then
            local mob = part.Parent
            local hum = mob:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                return part, hum
            end
        end
    end
    return nil, nil
end

-- [[ 5. ฟังก์ชันออโต้สกิล ]]
local function CastAllSkills()
    for key, isEnabled in pairs(_G_SkillStates) do
        if isEnabled then
            task.spawn(function()
                pcall(function()
                    VIM:SendKeyEvent(true, Enum.KeyCode[key], false, game)
                    task.wait(0.02)
                    VIM:SendKeyEvent(false, Enum.KeyCode[key], false, game)
                end)
            end)
        end
    end
end

-- [[ 6. ลูปอิสระที่ 1: ระบบฟาร์มและ Smart Sweeper (🔥 แก้บัคสลับเป้าหมาย) ]]
task.spawn(function()
    while true do
        task.wait()
        if _G_Farming then
            local char = LocalPlayer.Character
            local myRoot = char and char:FindFirstChild("HumanoidRootPart")
            
            if myRoot then
                -- ลองหาเป้าหมายดูก่อนว่ามีไหม
                local initTargetPart, initTargetHum = GetCurrentZombie()
                
                if initTargetPart and initTargetPart.Parent then
                    local startObjective = GetCurrentObjectiveName()
                    
                    -- 🔥 เปลี่ยนมาใช้ลูปเช็คเป้าหมายแบบ Real-time ตลอดเวลา
                    while _G_Farming do
                        task.wait()
                        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then break end
                        if GetCurrentObjectiveName() ~= startObjective then break end
                        
                        -- ดึงข้อมูลเป้าหมายใหม่ล่าสุดทุกเสี้ยววินาที (ถ้า Pucci เกิด มันจะเปลี่ยนเป้าทันที)
                        local currentTargetPart, currentTargetHum = GetCurrentZombie()
                        
                        -- ถ้ายกแมพไม่มีมอนสเตอร์เหลือเลย ให้ออกลูปไปเตรียมเปิดเกท
                        if not currentTargetPart or not currentTargetPart.Parent or currentTargetHum.Health <= 0 then 
                            break 
                        end
                        
                        -- พุ่งไปเป้าหมายล่าสุด
                        myRoot.CFrame = currentTargetPart.CFrame * CFrame.new(0, 0, _G_Distance)
                    end
                else
                    -- ระบบเปิดเกท/เข้าห้องบอส
                    local mapFolder = Workspace:FindFirstChild("Map")
                    if mapFolder then
                        local gatesFolder = mapFolder:FindFirstChild("Gates")
                        if gatesFolder and #gatesFolder:GetChildren() > 0 then
                            for _, gate in pairs(gatesFolder:GetChildren()) do
                                if not _G_Farming then break end
                                local hitbox = gate:FindFirstChild("Hitbox") or gate:FindFirstChildWhichIsA("BasePart", true)
                                if hitbox then
                                    pcall(function()
                                        myRoot.CFrame = hitbox.CFrame
                                        task.wait(0.1)
                                    end)
                                end
                            end
                        end
                        
                        local objFolder = mapFolder:FindFirstChild("Objective")
                        if objFolder then
                            local entries = objFolder:FindFirstChild("Entries")
                            if entries then
                                for _, obj in pairs(entries:GetDescendants()) do
                                    if obj.Name:lower():find("portique") and obj:IsA("BasePart") then
                                        pcall(function()
                                            myRoot.CFrame = obj.CFrame
                                            VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                                            task.wait(0.1)
                                            VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                                            
                                            local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true) or obj.Parent:FindFirstChildWhichIsA("ProximityPrompt", true)
                                            if prompt then fireproximityprompt(prompt) end
                                        end)
                                        break
                                    end
                                end
                            end
                        end
                    end
                    task.wait(0.5) 
                end
            end
        end
    end
end)

-- [[ 7. ลูปอิสระที่ 2: ระบบ Auto Skill ตามระยะเวลาสไลเดอร์ ]]
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

-- [[ 8. ลูปอิสระที่ 3: ระบบ Auto Start (VoteSkipRaid) ]]
task.spawn(function()
    while true do
        task.wait(3) 
        if _G_Farming then
            pcall(function()
                local interactRemote = ReplicatedStorage:WaitForChild("Assets", 3):WaitForChild("Remotes", 3):WaitForChild("Interact", 3)
                if interactRemote then
                    interactRemote:FireServer("VoteSkipRaid")
                end
            end)
        end
    end
end)

-- [[ 8.5 ลูปอิสระที่ 4: ระบบ Auto Click (LMB) ]]
task.spawn(function()
    while task.wait(0.1) do
        if _G_Farming and _G_AutoClick then
            local char = LocalPlayer.Character
            if char then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then
                    pcall(function() tool:Activate() end)
                end
                
                pcall(function()
                    local cam = workspace.CurrentCamera
                    if cam then
                        VIM:SendMouseButtonEvent(cam.ViewportSize.X/2, cam.ViewportSize.Y/2, 0, true, game, 1)
                        task.wait(0.01)
                        VIM:SendMouseButtonEvent(cam.ViewportSize.X/2, cam.ViewportSize.Y/2, 0, false, game, 1)
                    end
                end)
            end
        end
    end
end)

-- [[ 9. การสร้าง GUI V5.8 ]]
local UI_Parent = (pcall(function() return game:GetService("CoreGui").Name end) and game:GetService("CoreGui")) or LocalPlayer:WaitForChild("PlayerGui")
if UI_Parent:FindFirstChild("LunaHubV5_5") then UI_Parent.LunaHubV5_5:Destroy() end
if UI_Parent:FindFirstChild("LunaHubV5_6") then UI_Parent.LunaHubV5_6:Destroy() end
if UI_Parent:FindFirstChild("LunaHubV5_7") then UI_Parent.LunaHubV5_7:Destroy() end
if UI_Parent:FindFirstChild("LunaHubV5_8") then UI_Parent.LunaHubV5_8:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LunaHubV5_8"
ScreenGui.Parent = UI_Parent

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 260, 0, 215)
MainFrame.Position = UDim2.new(0, 20, 0.5, -107) 
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Text = "Luna Hub | V5.8 Dynamic Boss Lock"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 11
Title.Parent = MainFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.28, 0, 0, 30)
ToggleBtn.Position = UDim2.new(0.04, 0, 0, 40)
ToggleBtn.BackgroundColor3 = _G_Farming and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Text = "FARM: " .. (_G_Farming and "ON" or "OFF")
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 10
ToggleBtn.Parent = MainFrame
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 5)

local ClickBtn = Instance.new("TextButton")
ClickBtn.Size = UDim2.new(0.28, 0, 0, 30)
ClickBtn.Position = UDim2.new(0.36, 0, 0, 40)
ClickBtn.BackgroundColor3 = _G_AutoClick and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
ClickBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ClickBtn.Text = "LMB: " .. (_G_AutoClick and "ON" or "OFF")
ClickBtn.Font = Enum.Font.GothamBold
ClickBtn.TextSize = 10
ClickBtn.Parent = MainFrame
Instance.new("UICorner", ClickBtn).CornerRadius = UDim.new(0, 5)

local BossBtn = Instance.new("TextButton")
BossBtn.Size = UDim2.new(0.28, 0, 0, 30)
BossBtn.Position = UDim2.new(0.68, 0, 0, 40)
BossBtn.BackgroundColor3 = _G_BossLock and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
BossBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
BossBtn.Text = "BOSS: " .. (_G_BossLock and "ON" or "OFF")
BossBtn.Font = Enum.Font.GothamBold
BossBtn.TextSize = 10
BossBtn.Parent = MainFrame
Instance.new("UICorner", BossBtn).CornerRadius = UDim.new(0, 5)

local skillKeys = {"Z", "X", "C", "V", "F", "E", "G"}
for i, key in ipairs(skillKeys) do
    local sBtn = Instance.new("TextButton")
    sBtn.Size = UDim2.new(0.11, 0, 0, 25)
    sBtn.Position = UDim2.new(0.04 + ((i - 1) * 0.13), 0, 0, 80)
    sBtn.BackgroundColor3 = _G_SkillStates[key] and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
    sBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    sBtn.Text = key
    sBtn.Font = Enum.Font.GothamBold
    sBtn.TextSize = 10
    sBtn.Parent = MainFrame
    Instance.new("UICorner", sBtn).CornerRadius = UDim.new(0, 4)
    
    sBtn.MouseButton1Click:Connect(function()
        _G_SkillStates[key] = not _G_SkillStates[key]
        sBtn.BackgroundColor3 = _G_SkillStates[key] and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
        SaveSettings()
    end)
end

local DistTitle = Instance.new("TextLabel")
DistTitle.Size = UDim2.new(1, 0, 0, 20)
DistTitle.Position = UDim2.new(0, 0, 0, 115)
DistTitle.BackgroundTransparency = 1
DistTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
DistTitle.Text = "Distance: " .. _G_Distance
DistTitle.Font = Enum.Font.Gotham
DistTitle.TextSize = 12
DistTitle.Parent = MainFrame

local DistBG = Instance.new("TextButton")
DistBG.Size = UDim2.new(0.8, 0, 0, 10)
DistBG.Position = UDim2.new(0.1, 0, 0, 140)
DistBG.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
DistBG.Text = ""
DistBG.Parent = MainFrame

local DistFill = Instance.new("Frame")
DistFill.Size = UDim2.new(_G_Distance / 20, 0, 1, 0)
DistFill.BackgroundColor3 = Color3.fromRGB(80, 150, 255)
DistFill.Parent = DistBG

local DelayTitle = Instance.new("TextLabel")
DelayTitle.Size = UDim2.new(1, 0, 0, 20)
DelayTitle.Position = UDim2.new(0, 0, 0, 160)
DelayTitle.BackgroundTransparency = 1
DelayTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
DelayTitle.Text = "Skill Delay: " .. string.format("%.1f", _G_SkillDelay) .. "s"
DelayTitle.Font = Enum.Font.Gotham
DelayTitle.TextSize = 12
DelayTitle.Parent = MainFrame

local DelayBG = Instance.new("TextButton")
DelayBG.Size = UDim2.new(0.8, 0, 0, 10)
DelayBG.Position = UDim2.new(0.1, 0, 0, 185)
DelayBG.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
DelayBG.Text = ""
DelayBG.Parent = MainFrame

local DelayFill = Instance.new("Frame")
local minD, maxD = 0.1, 5.0
DelayFill.Size = UDim2.new((_G_SkillDelay - minD) / (maxD - minD), 0, 1, 0)
DelayFill.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
DelayFill.Parent = DelayBG

ToggleBtn.MouseButton1Click:Connect(function()
    _G_Farming = not _G_Farming
    ToggleBtn.BackgroundColor3 = _G_Farming and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
    ToggleBtn.Text = "FARM: " .. (_G_Farming and "ON" or "OFF")
    SaveSettings()
end)

ClickBtn.MouseButton1Click:Connect(function()
    _G_AutoClick = not _G_AutoClick
    ClickBtn.BackgroundColor3 = _G_AutoClick and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
    ClickBtn.Text = "LMB: " .. (_G_AutoClick and "ON" or "OFF")
    SaveSettings()
end)

BossBtn.MouseButton1Click:Connect(function()
    _G_BossLock = not _G_BossLock
    BossBtn.BackgroundColor3 = _G_BossLock and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
    BossBtn.Text = "BOSS: " .. (_G_BossLock and "ON" or "OFF")
    SaveSettings()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.P then
        MainFrame.Visible = not MainFrame.Visible
    end
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
        local mousePos = UserInputService:GetMouseLocation().X
        
        if dragDist then
            local p = math.clamp((mousePos - DistBG.AbsolutePosition.X) / DistBG.AbsoluteSize.X, 0, 1)
            _G_Distance = math.floor(5 + (p * 20)) 
            DistFill.Size = UDim2.new(p, 0, 1, 0)
            DistTitle.Text = "Distance: " .. _G_Distance
        end
        
        if dragDelay then
            local p = math.clamp((mousePos - DelayBG.AbsolutePosition.X) / DelayBG.AbsoluteSize.X, 0, 1)
            _G_SkillDelay = minD + (p * (maxD - minD))
            DelayFill.Size = UDim2.new(p, 0, 1, 0)
            DelayTitle.Text = "Skill Delay: " .. string.format("%.1f", _G_SkillDelay) .. "s"
        end
    end
end)
