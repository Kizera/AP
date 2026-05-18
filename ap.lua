-- [[ 1. ตัวแปรและบริการระบบ ]]
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VIM = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local configFileName = "LunaHub_V5_6_Save.json"

-- ค่าเริ่มต้นระบบ
_G_Farming = true
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
                        -- โหลดค่าเดิมและเติม F เข้าไปถ้าไฟล์เซฟเก่าไม่มี
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

-- [[ 6. ลูปอิสระที่ 1: ระบบฟาร์มและ Smart Sweeper (หาเกท/ประตูจบ) ]]
task.spawn(function()
    while true do
        task.wait()
        if _G_Farming then
            local char = LocalPlayer.Character
            local myRoot = char and char:FindFirstChild("HumanoidRootPart")
            
            if myRoot then
                local targetPart, targetHum = GetCurrentZombie()
                
                -- กรณีที่ 1: เจอมอนสเตอร์ -> ฟาร์มปกติ
                if targetPart and targetPart.Parent then
                    local startObjective = GetCurrentObjectiveName()
                    
                    while _G_Farming and targetPart and targetPart.Parent do
                        task.wait()
                        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then break end
                        if targetHum and targetHum.Health <= 0 then break end
                        if GetCurrentObjectiveName() ~= startObjective then break end
                        
                        myRoot.CFrame = targetPart.CFrame * CFrame.new(0, 0, _G_Distance)
                    end
                else
                    -- กรณีที่ 2: มอนหมดแมพ -> ระบบ Smart Sweeper จะทำงาน
                    local mapFolder = Workspace:FindFirstChild("Map")
                    if mapFolder then
                        
                        -- สเต็ป A: มุดหา Hitbox ใน Gates เผื่อต้องเปิดประตูให้มอนเกิด
                        local gatesFolder = mapFolder:FindFirstChild("Gates")
                        if gatesFolder and #gatesFolder:GetChildren() > 0 then
                            for _, gate in pairs(gatesFolder:GetChildren()) do
                                if not _G_Farming then break end
                                local hitbox = gate:FindFirstChild("Hitbox") or gate:FindFirstChildWhichIsA("BasePart", true)
                                if hitbox then
                                    pcall(function()
                                        myRoot.CFrame = hitbox.CFrame
                                        task.wait(0.1) -- แตะเพื่อเปิดเกท
                                    end)
                                end
                            end
                        end
                        
                        -- สเต็ป B: มุดหา portique (ประตูห้องบอส/จบด่าน) แล้วกด E
                        local objFolder = mapFolder:FindFirstChild("Objective")
                        if objFolder then
                            local entries = objFolder:FindFirstChild("Entries")
                            if entries then
                                for _, obj in pairs(entries:GetDescendants()) do
                                    if obj.Name:lower():find("portique") and obj:IsA("BasePart") then
                                        pcall(function()
                                            myRoot.CFrame = obj.CFrame
                                            -- จำลองกดปุ่ม E
                                            VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                                            task.wait(0.1)
                                            VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                                            
                                            -- เสริมความชัวร์: สั่งรัน ProximityPrompt (ถ้ามี)
                                            local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true) or obj.Parent:FindFirstChildWhichIsA("ProximityPrompt", true)
                                            if prompt then fireproximityprompt(prompt) end
                                        end)
                                        break
                                    end
                                end
                            end
                        end
                    end
                    task.wait(0.5) -- หน่วงเวลาป้องกันลูปกระตุกช่วงรอโหลดมอน/ด่าน
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

-- [[ 9. การสร้าง GUI V5.6 ]]
local UI_Parent = (pcall(function() return game:GetService("CoreGui").Name end) and game:GetService("CoreGui")) or LocalPlayer:WaitForChild("PlayerGui")
if UI_Parent:FindFirstChild("LunaHubV5_5") then UI_Parent.LunaHubV5_5:Destroy() end
if UI_Parent:FindFirstChild("LunaHubV5_6") then UI_Parent.LunaHubV5_6:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LunaHubV5_6"
ScreenGui.Parent = UI_Parent

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 260, 0, 215)
MainFrame.Position = UDim2.new(0, 20, 0.5, -107) -- ชิดซ้ายจอ
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Text = "Luna Hub | V5.6 Smart Sweeper"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 12
Title.Parent = MainFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.9, 0, 0, 30)
ToggleBtn.Position = UDim2.new(0.05, 0, 0, 40)
ToggleBtn.BackgroundColor3 = _G_Farming and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Text = "FARM & AUTO START: " .. (_G_Farming and "ON" or "OFF")
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 11
ToggleBtn.Parent = MainFrame
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 5)

-- ปุ่มสกิล 7 ปุ่ม (เพิ่ม F และจัดระยะให้พอดี)
local skillKeys = {"Z", "X", "C", "V", "F", "E", "G"}
for i, key in ipairs(skillKeys) do
    local sBtn = Instance.new("TextButton")
    sBtn.Size = UDim2.new(0.11, 0, 0, 25)
    -- กระจายตำแหน่งให้ 7 ปุ่มอยู่แถวเดียวกันอย่างสมดุล
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

local SliderFill = Instance.new("Frame")
SliderFill.Size = UDim2.new(_G_Distance / 20, 0, 1, 0)
SliderFill.BackgroundColor3 = Color3.fromRGB(80, 150, 255)
SliderFill.Parent = SliderBG

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

-- [[ 10. ระบบควบคุมและคีย์ลัด P ]]
ToggleBtn.MouseButton1Click:Connect(function()
    _G_Farming = not _G_Farming
    ToggleBtn.BackgroundColor3 = _G_Farming and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
    ToggleBtn.Text = "FARM & AUTO START: " .. (_G_Farming and "ON" or "OFF")
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
