-- [[ 1. ตัวแปรและบริการระบบ ]]
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VIM = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local configFileName = "LunaHub_V5_3_Save.json" -- ใช้ไฟล์เซฟเดิมต่อเนื่องได้เลย

-- ค่าเริ่มต้นระบบ
_G_Farming = true
_G_Distance = 7
_G_SkillDelay = 0.5 

_G_SkillStates = {
    Z = true, X = true, C = true, 
    V = true, E = true, G = true
}

-- [[ 2. ระบบ Save / Load ]]
local function SaveSettings()
    if type(writefile) == "function" then
        pcall(function()
            local data = {
                Farming = _G_Farming,
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
                    _G_Distance = result.Distance or 7
                    _G_SkillDelay = result.SkillDelay or 0.5
                    if result.SkillStates then
                        _G_SkillStates = result.SkillStates
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

-- [[ 4. ระบบ Global Scanner ]]
local function GetCurrentZombie()
    local folder = Workspace:FindFirstChild("Zombies")
    if not folder then return nil, nil end
    
    for _, part in pairs(folder:GetDescendants()) do
        if (part.Name == "HumanoidRootPart" or part.Name == "Torso") and part:IsA("BasePart") then
            local mob = part.Parent
            local hum = mob:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health > 0 then
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

-- [[ 6. ลูปอิสระที่ 1: ระบบวาปฟาร์มมอนสเตอร์ ]]
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
                    
                    while _G_Farming and targetPart and targetPart.Parent do
                        task.wait()
                        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then break end
                        if targetHum and targetHum.Health <= 0 then break end
                        if GetCurrentObjectiveName() ~= startObjective then break end
                        
                        myRoot.CFrame = targetPart.CFrame * CFrame.new(0, 0, _G_Distance)
                    end
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

-- [[ 8. ลูปอิสระที่ 3: ระบบ Auto Start & Auto Retry ]]
task.spawn(function()
    while true do
        task.wait(3) 
        if _G_Farming then
            pcall(function()
                local interactRemote = ReplicatedStorage:WaitForChild("Assets", 3):WaitForChild("Remotes", 3):WaitForChild("Interact", 3)
                if interactRemote then
                    interactRemote:FireServer("VoteSkipRaid")
                    interactRemote:FireServer("PlayAgain")
                end
            end)
        end
    end
end)

-- [[ 9. การสร้าง GUI V5.4 ]]
local UI_Parent = (pcall(function() return game:GetService("CoreGui").Name end) and game:GetService("CoreGui")) or LocalPlayer:WaitForChild("PlayerGui")
if UI_Parent:FindFirstChild("LunaHubV5_3") then UI_Parent.LunaHubV5_3:Destroy() end
if UI_Parent:FindFirstChild("LunaHubV5_4") then UI_Parent.LunaHubV5_4:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LunaHubV5_4"
ScreenGui.Parent = UI_Parent

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 260, 0, 215)
-- 🚨 ปรับพิกัดใหม่ให้ชิดซ้าย (X = 20 พิกเซลจากขอบจอ, Y = กึ่งกลางจอ)
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
Title.Text = "Luna Hub | V5.4 Left Aligned"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 12
Title.Parent = MainFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.9, 0, 0, 30)
ToggleBtn.Position = UDim2.new(0.05, 0, 0, 40)
ToggleBtn.BackgroundColor3 = _G_Farming and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Text = "FARM & AUTO MATCH: " .. (_G_Farming and "ON" or "OFF")
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 11
ToggleBtn.Parent = MainFrame
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 5)

-- ปุ่มสกิล
local skillKeys = {"Z", "X", "C", "V", "E", "G"}
for i, key in ipairs(skillKeys) do
    local sBtn = Instance.new("TextButton")
    sBtn.Size = UDim2.new(0.13, 0, 0, 25)
    sBtn.Position = UDim2.new(0.05 + ((i - 1) * 0.15), 0, 0, 80)
    sBtn.BackgroundColor3 = _G_SkillStates[key] and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
    sBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    sBtn.Text = key
    sBtn.Font = Enum.Font.GothamBold
    sBtn.TextSize = 11
    sBtn.Parent = MainFrame
    Instance.new("UICorner", sBtn).CornerRadius = UDim.new(0, 4)
    
    sBtn.MouseButton1Click:Connect(function()
        _G_SkillStates[key] = not _G_SkillStates[key]
        sBtn.BackgroundColor3 = _G_SkillStates[key] and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
        SaveSettings()
    end)
end

-- สไลเดอร์ 1: ระยะห่าง
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

-- สไลเดอร์ 2: เวลาหน่วงสกิล
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

-- [[ 10. ระบบผูกปุ่มและการลากสไลเดอร์ ]]
ToggleBtn.MouseButton1Click:Connect(function()
    _G_Farming = not _G_Farming
    ToggleBtn.BackgroundColor3 = _G_Farming and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
    ToggleBtn.Text = "FARM & AUTO MATCH: " .. (_G_Farming and "ON" or "OFF")
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
