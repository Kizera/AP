-- [[ 1. ตัวแปรและบริการระบบ ]]
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VIM = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local configFileName = "LunaHub_CoreSave.json"

-- บังคับเปิดระบบฟาร์มและสกิลทันทีเมื่อย้ายมิติ (Autoexec)
_G_Farming = true
_G_AutoSkill = true

-- ค่าเริ่มต้นของสไลเดอร์ (จะดึงจากไฟล์เซฟถ้าเคยรูดไว้)
_G_Distance = 7        
_G_SkillDelay = 0.5   

-- [[ 2. ระบบ Save / Load จำเฉพาะค่าสไลเดอร์ ]]
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

-- [[ 4. ฟังก์ชันตรวจสอบหน้าต่าง UI จบเกมจริงๆ เพื่อความเสถียร ]]
local function IsMatchReallyOver()
    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not playerGui then return false end
    local isOver = false
    pcall(function()
        for _, v in pairs(playerGui:GetDescendants()) do
            if v:IsA("TextLabel") or v:IsA("TextButton") then
                local t = v.Text:lower()
                if t:find("again") or t:find("replay") or t:find("victory") or t:find("defeat") or t:find("reward") or t:find("retry") then
                    if v.Visible then isOver = true break end
                end
            end
        end
    end)
    return isOver
end

-- [[ 5. ลูปหลัก: เจาะจงโฟลเดอร์ Zombies อย่างเดียว + ระบบ Replay ]]
task.spawn(function()
    while true do
        task.wait()
        if _G_Farming then
            local char = LocalPlayer.Character
            local myRoot = char and char:FindFirstChild("HumanoidRootPart")
            local zombiesFolder = Workspace:FindFirstChild("Zombies")

            if zombiesFolder and myRoot then
                local mobs = zombiesFolder:GetChildren()

                if #mobs > 0 then
                    -- โฟกัสกวาดเป้าหมายที่ดรอปเข้ามาอยู่ในโฟลเดอร์ Zombies เท่านั้น
                    for _, mob in pairs(mobs) do
                        if not _G_Farming then break end
                        
                        -- ค้นหาชิ้นส่วนและระบบเลือดของมอนสเตอร์ตัวนั้นๆ
                        local targetPart = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Torso") or mob.PrimaryPart or mob:FindFirstChildWhichIsA("BasePart", true)
                        local targetHum = mob:FindFirstChildOfClass("Humanoid")

                        local function isAlive()
                            if not mob or not mob.Parent then return false end
                            if targetHum then return targetHum.Health > 0 end
                            return true
                        end

                        -- วาร์ปเกาะติดด้านหลังเพื่อโจมตีจนกว่ามอนสเตอร์จะตาย
                        while _G_Farming and targetPart and isAlive() do
                            task.wait()
                            if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then break end
                            myRoot.CFrame = targetPart.CFrame * CFrame.new(0, 0, _G_Distance)
                        end
                    end
                else
                    -- ถ้าโฟลเดอร์ Zombies ว่างเปล่า และระบบขึ้นหน้าต่างจบด่าน -> กดเริ่มใหม่ทันที
                    if IsMatchReallyOver() then
                        pcall(function()
                            local remote = ReplicatedStorage:WaitForChild("Assets", 2):WaitForChild("Remotes", 2):WaitForChild("Interact", 2)
                            if remote then remote:FireServer("PlayAgain") end
                        end)
                        task.wait(5) -- คูลดาวน์หน่วงเวลากันส่งรีโมทซ้ำซ้อน
                    end
                end
            end
        end
    end
end)

-- [[ 6. ลูปที่ 2: ระบบ Auto Skill จะทำงานเมื่อตรวจพบมอนสเตอร์ในโฟลเดอร์ Zombies เท่านั้น ]]
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

-- [[ 7. การสร้าง GUI V20 ]]
local UI_Parent = (pcall(function() return game:GetService("CoreGui").Name end) and game:GetService("CoreGui")) or LocalPlayer:WaitForChild("PlayerGui")
if UI_Parent:FindFirstChild("LunaHubV20") then UI_Parent.LunaHubV20:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LunaHubV20"
ScreenGui.Parent = UI_Parent

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 280, 0, 185)
MainFrame.Position = UDim2.new(0.5, -140, 0.5, -92)
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
Title.Text = "🌙 LUNA HUB V20 | ZOMBIES ONLY"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.Parent = MainFrame
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 10)

local FarmBtn = Instance.new("TextButton")
FarmBtn.Size = UDim2.new(0.42, 0, 0, 30)
FarmBtn.Position = UDim2.new(0.05, 0, 0, 45)
FarmBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
FarmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FarmBtn.Text = "FARM: ON"
FarmBtn.Font = Enum.Font.GothamBold
FarmBtn.TextSize = 11
FarmBtn.Parent = MainFrame
Instance.new("UICorner", FarmBtn).CornerRadius = UDim.new(0, 6)

local SkillBtn = Instance.new("TextButton")
SkillBtn.Size = UDim2.new(0.42, 0, 0, 30)
SkillBtn.Position = UDim2.new(0.53, 0, 0, 45)
SkillBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
SkillBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SkillBtn.Text = "SKILL: ON"
SkillBtn.Font = Enum.Font.GothamBold
SkillBtn.TextSize = 11
SkillBtn.Parent = MainFrame
Instance.new("UICorner", SkillBtn).CornerRadius = UDim.new(0, 6)

-- สไลเดอร์ระยะห่าง
local DistLabel = Instance.new("TextLabel")
DistLabel.Size = UDim2.new(0.9, 0, 0, 20)
DistLabel.Position = UDim2.new(0.05, 0, 0, 85)
DistLabel.BackgroundTransparency = 1
DistLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
DistLabel.Text = "Back-TP Distance: " .. _G_Distance .. " Studs"
DistLabel.Font = Enum.Font.Gotham
DistLabel.TextSize = 11
DistLabel.TextXAlignment = Enum.TextXAlignment.Left
DistLabel.Parent = MainFrame

local DistBG = Instance.new("TextButton")
DistBG.Size = UDim2.new(0.9, 0, 0, 8)
DistBG.Position = UDim2.new(0.05, 0, 0, 105)
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

-- สไลเดอร์หน่วงเวลาสกิล
local DelayLabel = Instance.new("TextLabel")
DelayLabel.Size = UDim2.new(0.9, 0, 0, 20)
DelayLabel.Position = UDim2.new(0.05, 0, 0, 125)
DelayLabel.BackgroundTransparency = 1
DelayLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
DelayLabel.Text = "Skill Loop Delay: " .. string.format("%.1f", _G_SkillDelay) .. "s"
DelayLabel.Font = Enum.Font.Gotham
DelayLabel.TextSize = 11
DelayLabel.TextXAlignment = Enum.TextXAlignment.Left
DelayLabel.Parent = MainFrame

local DelayBG = Instance.new("TextButton")
DelayBG.Size = UDim2.new(0.9, 0, 0, 8)
DelayBG.Position = UDim2.new(0.05, 0, 0, 145)
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

-- ระบบผูกปุ่มและการเซฟ
FarmBtn.MouseButton1Click:Connect(function()
    _G_Farming = not _G_Farming
    FarmBtn.BackgroundColor3 = _G_Farming and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(180, 40, 40)
    FarmBtn.Text = "FARM: " .. (_G_Farming and "ON" or "OFF")
end)

SkillBtn.MouseButton1Click:Connect(function()
    _G_AutoSkill = not _G_AutoSkill
    SkillBtn.BackgroundColor3 = _G_AutoSkill and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(180, 40, 40)
    SkillBtn.Text = "SKILL: " .. (_G_AutoSkill and "ON" or "OFF")
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
