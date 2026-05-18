-- [[ 1. ตัวแปรและบริการระบบ ]]
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VIM = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
_G_Farming = true
_G_Magnet = true -- แยกตัวแปรควบคุมแม่เหล็กอิสระ
_G_Distance = 7
_G_SkillDelay = 0.5 

-- [[ 2. ฟังก์ชันดึงชื่อเควสปัจจุบัน (ใช้เช็คการเปลี่ยน Section) ]]
local function GetCurrentObjectiveName()
    local objectives = Workspace:FindFirstChild("Objectives")
    if objectives then
        local child = objectives:GetChildren()[1]
        if child then
            return child.Name
        end
    end
    return ""
end

-- [[ 3. ระบบค้นหาเป้าหมายในโฟลเดอร์ Zombies ]]
local function GetCurrentZombie()
    local folder = Workspace:FindFirstChild("Zombies")
    if not folder then return nil end
    
    for _, mob in pairs(folder:GetChildren()) do
        local root = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Torso") or mob.PrimaryPart or mob:FindFirstChildWhichIsA("BasePart", true)
        local hum = mob:FindFirstChildOfClass("Humanoid")
        
        if root and (not hum or hum.Health > 0) then
            return root, hum
        end
    end
    return nil, nil
end

-- [[ 4. ฟังก์ชันออโต้สกิลชุดเต็ม (Z, X, C, V, E, G) ]]
local skills = {"Z", "X", "C", "V", "E", "G"}
local function CastAllSkills()
    for _, key in pairs(skills) do
        task.spawn(function()
            pcall(function()
                VIM:SendKeyEvent(true, Enum.KeyCode[key], false, game)
                task.wait(0.03)
                VIM:SendKeyEvent(false, Enum.KeyCode[key], false, game)
            end)
        end)
    end
end

-- [[ 5. ลูปอิสระที่ 1: ระบบวาปฟาร์ม + ตัวดักจับเควสเปลี่ยนด่าน ]]
task.spawn(function()
    while true do
        task.wait()
        if _G_Farming then
            local char = LocalPlayer.Character
            local myRoot = char and char:FindFirstChild("HumanoidRootPart")
            
            if myRoot then
                local targetPart, targetHum = GetCurrentZombie()
                if targetPart and targetPart.Parent then
                    
                    -- บันทึกชื่อเควสตอนเริ่มตีมอนตัวนี้
                    local startObjective = GetCurrentObjectiveName()
                    
                    -- ล็อกเป้าตีจนกว่ามอนจะตาย หรือจนกว่าเควสด่านจะเปลี่ยน
                    while _G_Farming and targetPart and targetPart.Parent and (not targetHum or targetHum.Health > 0) do
                        task.wait()
                        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then break end
                        
                        -- 🚨 ฟีเจอร์เด็ด: ถ้าชื่อเควสเปลี่ยนปุ๊บ แปลว่าขึ้น Section ใหม่ ให้สะบัดหลุดลูปเพื่อไปจับมอนด่านใหม่ทันที!
                        if GetCurrentObjectiveName() ~= startObjective then
                            print("Luna Hub: ตรวจพบเควสเปลี่ยนด่าน! รีเซ็ตระบบฟาร์มไป Section ต่อไป")
                            break
                        end
                        
                        myRoot.CFrame = targetPart.CFrame * CFrame.new(0, 0, _G_Distance)
                    end
                end
            end
        end
    end
end)

-- [[ 6. ลูปอิสระที่ 2: ระบบ Auto Skill ]]
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

-- [[ 7. ลูปอิสระที่ 3: ระบบแม่เหล็กดูด TouchInterest แยกฟังก์ชันเด็ดขาด ]]
task.spawn(function()
    while true do
        task.wait(0.15)
        -- ทำงานเมื่อเปิดปุ่ม MAGNET โดยไม่สนว่าเราจะเปิดหรือปิดบอทฟาร์มมอนอยู่
        if _G_Magnet then
            local thrownFolder = Workspace:FindFirstChild("Thrown")
            local char = LocalPlayer.Character
            local myRoot = char and char:FindFirstChild("HumanoidRootPart")
            
            if thrownFolder and myRoot then
                for _, obj in pairs(thrownFolder:GetDescendants()) do
                    if obj.Name == "TouchInterest" or obj:IsA("TouchTransmitter") then
                        local itemHitbox = obj.Parent
                        if itemHitbox and itemHitbox:IsA("BasePart") then
                            pcall(function()
                                itemHitbox.CFrame = myRoot.CFrame
                            end)
                        end
                    end
                end
            end
        end
    end
end)

-- [[ 8. การสร้าง GUI V4.3 (เพิ่มปุ่มควบคุมแบบแยกส่วน UX คลีนๆ) ]]
local UI_Parent = (pcall(function() return game:GetService("CoreGui").Name end) and game:GetService("CoreGui")) or LocalPlayer:WaitForChild("PlayerGui")
if UI_Parent:FindFirstChild("LunaHubV4_3") then UI_Parent.LunaHubV4_3:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LunaHubV4_3"
ScreenGui.Parent = UI_Parent

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 260, 0, 165) -- ปรับขนาดให้พอดีกับปุ่มคู่ขนานด้านบน
MainFrame.Position = UDim2.new(0.5, -125, 0.5, -82)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Text = "Luna Hub | V4.3 Section Watchdog"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 12
Title.Parent = MainFrame

-- ปุ่มที่ 1: เปิด/ปิด ฟาร์ม
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.42, 0, 0, 30)
ToggleBtn.Position = UDim2.new(0.05, 0, 0, 40)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Text = "FARM: ON"
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 11
ToggleBtn.Parent = MainFrame
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 5)

-- ปุ่มที่ 2: เปิด/ปิด แม่เหล็กดูดของ (แยกฟังก์ชันอิสระตามสั่ง)
local MagnetBtn = Instance.new("TextButton")
MagnetBtn.Size = UDim2.new(0.42, 0, 0, 30)
MagnetBtn.Position = UDim2.new(0.53, 0, 0, 40)
MagnetBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
MagnetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MagnetBtn.Text = "MAGNET: ON"
MagnetBtn.Font = Enum.Font.GothamBold
MagnetBtn.TextSize = 11
MagnetBtn.Parent = MainFrame
Instance.new("UICorner", MagnetBtn).CornerRadius = UDim.new(0, 5)

local SliderTitle = Instance.new("TextLabel")
SliderTitle.Size = UDim2.new(1, 0, 0, 20)
SliderTitle.Position = UDim2.new(0, 0, 0, 85)
SliderTitle.BackgroundTransparency = 1
SliderTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
SliderTitle.Text = "Distance: " .. _G_Distance
SliderTitle.Font = Enum.Font.Gotham
SliderTitle.TextSize = 12
SliderTitle.Parent = MainFrame

local SliderBG = Instance.new("TextButton")
SliderBG.Size = UDim2.new(0.8, 0, 0, 10)
SliderBG.Position = UDim2.new(0.1, 0, 0, 110)
SliderBG.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
SliderBG.Text = ""
SliderBG.Parent = MainFrame

local SliderFill = Instance.new("Frame")
SliderFill.Size = UDim2.new(_G_Distance / 20, 0, 1, 0)
SliderFill.BackgroundColor3 = Color3.fromRGB(80, 150, 255)
SliderFill.Parent = SliderBG

-- ลอจิกปุ่มควบคุม GUI
ToggleBtn.MouseButton1Click:Connect(function()
    _G_Farming = not _G_Farming
    ToggleBtn.BackgroundColor3 = _G_Farming and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
    ToggleBtn.Text = "FARM: " .. (_G_Farming and "ON" or "OFF")
end)

MagnetBtn.MouseButton1Click:Connect(function()
    _G_Magnet = not _G_Magnet
    MagnetBtn.BackgroundColor3 = _G_Magnet and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
    MagnetBtn.Text = "MAGNET: " .. (_G_Magnet and "ON" or "OFF")
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
        _G_Distance = math.floor(5 + (percent * 20)) 
        
        SliderFill.Size = UDim2.new(percent, 0, 1, 0)
        SliderTitle.Text = "Distance: " .. _G_Distance
    end
end)
