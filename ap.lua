-- [[ 1. ตัวแปรและบริการระบบ ]]
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VIM = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local configFileName = "LunaHub_V5_2_Save.json"

-- ค่าเริ่มต้นระบบ (จะถูกทับถ้ามีไฟล์เซฟ)
_G_Farming = true
_G_TPGates = false       
_G_IsGoingToGate = false 
_G_Distance = 7
_G_SkillDelay = 0.5 

_G_SkillStates = {
    Z = true, X = true, C = true, 
    V = true, E = true, G = true
}

-- [[ 2. ระบบ Save / Load แบบสมบูรณ์ (จดจำทุกการตั้งค่าข้ามเซิร์ฟ) ]]
local function SaveSettings()
    if type(writefile) == "function" then
        pcall(function()
            local data = {
                Farming = _G_Farming,
                TPGates = _G_TPGates,
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
                    _G_TPGates = result.TPGates ~= nil and result.TPGates or false
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

-- [[ 3. ฟังก์ชันดึงชื่อเควสปัจจุบัน (ล็อกสูตรเสถียร V4.7) ]]
local function GetCurrentObjectiveName()
    local objectives = Workspace:FindFirstChild("Objectives")
    if objectives then
        local child = objectives:GetChildren()[1]
        if child then return child.Name end
    end
    return ""
end

-- [[ 4. ระบบ Global Scanner: สแกนหาพิกัดมอนสเตอร์ (ล็อกสูตรเสถียร V4.7) ]]
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

-- [[ 6. ลูปอิสระที่ 1: ระบบวาปฟาร์มมอนสเตอร์ดักจับข้าม Section ]]
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
                        
                        -- หยุดพุ่งชั่วคราวถ้าเปิดโหมดวิ่งไปเคลียร์เกทประตู
                        if not _G_IsGoingToGate then
                            myRoot.CFrame = targetPart.CFrame * CFrame.new(0, 0, _G_Distance)
                        end
                    end
                end
            end
        end
    end
end)

-- [[ 7. ลูปอิสระที่ 2: ระบบ Auto Skill ]]
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

-- [[ 8. ลูปอิสระที่ 3: ระบบสแกนพุ่งแตะ Hitbox ประตูเกทอัตโนมัติ ]]
task.spawn(function()
    while true do
        task.wait(0.1)
        if _G_TPGates then
            local mapFolder = Workspace:FindFirstChild("Map")
            local gatesFolder = mapFolder and mapFolder:FindFirstChild("Gates")
            local char = LocalPlayer.Character
            local myRoot = char and char:FindFirstChild("HumanoidRootPart")

            if gatesFolder and myRoot then
                local gates = gatesFolder:GetChildren()
                if #gates > 0 then
                    for _, gate in pairs(gates) do
                        if not _G_TPGates then break end
                        
                        local hitbox = gate:FindFirstChild("Hitbox")
                        if hitbox and hitbox:IsA("BasePart") then
                            pcall(function()
                                _G_IsGoingToGate = true 
                                myRoot.CFrame = hitbox.CFrame 
                                task.wait(0.15) 
                            end)
                        end
                    end
                else
                    _G_IsGoingToGate = false
                end
            else
                _G_IsGoingToGate = false
            end
        else
            _G_IsGoingToGate = false
        end
    end
end)

-- [[ 9. การสร้าง GUI V5.2 (สัดส่วนกระชับขึ้นหลังถอดระบบแม่เหล็ก) ]]
local UI_Parent = (pcall(function() return game:GetService("CoreGui").Name end) and game:GetService("CoreGui")) or LocalPlayer:WaitForChild("PlayerGui")
if UI_Parent:FindFirstChild("LunaHubV5_2") then UI_Parent.LunaHubV5_2:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LunaHubV5_2"
ScreenGui.Parent = UI_Parent

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 260, 0, 180) -- ปรับขนาดสั้นกระชับ สวยงามพอดีจอ
MainFrame.Position = UDim2.new(0.5, -125, 0.5, -90)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Text = "Luna Hub | V5.2 Pure Core [P]"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 12
Title.Parent = MainFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.42, 0, 0, 30)
ToggleBtn.Position = UDim2.new(0.05, 0, 0, 40)
ToggleBtn.BackgroundColor3 = _G_Farming and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Text = "FARM: " .. (_G_Farming and "ON" or "OFF")
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 11
ToggleBtn.Parent = MainFrame
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 5)

local GateBtn = Instance.new("TextButton")
GateBtn.Size = UDim2.new(0.42, 0, 0, 30)
GateBtn.Position = UDim2.new(0.53, 0, 0, 40)
GateBtn.BackgroundColor3 = _G_TPGates and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 150, 50)
GateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
GateBtn.Text = "AUTO GATE: " .. (_G_TPGates and "ON" or "OFF")
GateBtn.Font = Enum.Font.GothamBold
GateBtn.TextSize = 10
GateBtn.Parent = MainFrame
Instance.new("UICorner", GateBtn).CornerRadius = UDim.new(0, 5)

-- ปุ่มเลือกสกิลยึดพิกัดเดิมตามไฟล์เซฟ
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

local SliderTitle = Instance.new("TextLabel")
SliderTitle.Size = UDim2.new(1, 0, 0, 20)
SliderTitle.Position = UDim2.new(0, 0, 0, 115)
SliderTitle.BackgroundTransparency = 1
SliderTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
SliderTitle.Text = "Distance: " .. _G_Distance
SliderTitle.Font = Enum.Font.Gotham
SliderTitle.TextSize = 12
SliderTitle.Parent = MainFrame

local SliderBG = Instance.new("TextButton")
SliderBG.Size = UDim2.new(0.8, 0, 0, 10)
SliderBG.Position = UDim2.new(0.1, 0, 0, 140)
SliderBG.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
SliderBG.Text = ""
SliderBG.Parent = MainFrame

local SliderFill = Instance.new("Frame")
SliderFill.Size = UDim2.new(_G_Distance / 20, 0, 1, 0)
SliderFill.BackgroundColor3 = Color3.fromRGB(80, 150, 255)
SliderFill.Parent = SliderBG

-- [[ 10. ระบบผูกปุ่มคีย์บอร์ดและเมาส์ ]]
ToggleBtn.MouseButton1Click:Connect(function()
    _G_Farming = not _G_Farming
    ToggleBtn.BackgroundColor3 = _G_Farming and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
    ToggleBtn.Text = "FARM: " .. (_G_Farming and "ON" or "OFF")
    SaveSettings()
end)

GateBtn.MouseButton1Click:Connect(function()
    _G_TPGates = not _G_TPGates
    GateBtn.BackgroundColor3 = _G_TPGates and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 150, 50)
    GateBtn.Text = "AUTO GATE: " .. (_G_TPGates and "ON" or "OFF")
    SaveSettings()
end)

-- 🚨 ฟังก์ชันคีย์ลัด ปุ่ม P สำหรับย่อ/เปิดหน้าต่าง GUI อัตโนมัติ
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.P then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

local dragging = false
SliderBG.MouseButton1Down:Connect(function() dragging = true end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then 
        if dragging then SaveSettings() end
        dragging = false 
    end
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
