-- [[ NEOHUB - TOTO STYLE ULTIMATE (ALL FUNCTIONS FIXED) ]]
repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local lp = Players.LocalPlayer

-- 1. 変数・座標設定
local A1 = {Vector3.new(-472.59,-7.30,94.43), Vector3.new(-484.55,-5.33,95.05), Vector3.new(-472.59,-7.30,94.43), Vector3.new(-471.25,-6.83,7.08)}
local B1 = {Vector3.new(-474.02,-7.30,25.55), Vector3.new(-484.92,-5.13,24.53), Vector3.new(-474.02,-7.30,25.55), Vector3.new(-470.93,-6.83,113.38)}

local SPEED_IDA = 60
local SPEED_VOLTA = 31
local auto1, auto2, instaGrab, aimEnabled = false, false, false, false
local antiRagdollActive = false
local infJumpActive = false
local autoGrabEnabled = false

-- 2. コア関数
local function hrp() return lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") end

local function go(pos, speed, cond)
    local r = hrp()
    if not r then return end
    while cond() and (r.Position - pos).Magnitude > 1 do
        local dir = (pos - r.Position).Unit
        r.AssemblyLinearVelocity = Vector3.new(dir.X * speed, r.AssemblyLinearVelocity.Y, dir.Z * speed)
        task.wait()
    end
end

-- Auto Grab用実行関数
local function fireSteal(prompt)
    task.spawn(function()
        if prompt.ClassName == "ProximityPrompt" then
            prompt:InputHoldBegin()
            task.wait(1.3) -- STEAL_DURATION
            prompt:InputHoldEnd()
        end
    end)
end

-- 3. UI構築
local C = { bg = Color3.fromRGB(15, 15, 15), gold = Color3.fromRGB(180, 150, 80), text = Color3.fromRGB(255, 255, 255) }
local sg = Instance.new("ScreenGui", lp.PlayerGui); sg.Name = "NEOHUB_TOTO_FINAL_V2"; sg.ResetOnSpawn = false

local function applyStyle(inst, r)
    Instance.new("UICorner", inst).CornerRadius = UDim.new(0, r or 8)
    local s = Instance.new("UIStroke", inst); s.Thickness = 2; s.Color = C.gold; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    if not inst:IsA("TextLabel") then inst.BackgroundColor3 = C.bg end
end

-- メインパネル
local main = Instance.new("Frame", sg); main.Size = UDim2.new(0, 200, 0, 180); main.Position = UDim2.new(0.8, 0, 0.5, -90); applyStyle(main, 12)

local aimBtn = Instance.new("TextButton", main); aimBtn.Size = UDim2.new(0.43, 0, 0, 35); aimBtn.Position = UDim2.new(0.05, 0, 0.08, 0); aimBtn.Text = "エイム"; aimBtn.TextColor3 = C.gold; applyStyle(aimBtn, 8)
local gearBtn = Instance.new("TextButton", main); gearBtn.Size = UDim2.new(0.43, 0, 0, 35); gearBtn.Position = UDim2.new(0.52, 0, 0.08, 0); gearBtn.Text = "⚙️"; gearBtn.TextColor3 = C.gold; applyStyle(gearBtn, 8)
local leftBtn = Instance.new("TextButton", main); leftBtn.Size = UDim2.new(0.43, 0, 0, 35); leftBtn.Position = UDim2.new(0.05, 0, 0.32, 0); leftBtn.Text = "左"; leftBtn.TextColor3 = C.gold; applyStyle(leftBtn, 8)
local rightBtn = Instance.new("TextButton", main); rightBtn.Size = UDim2.new(0.43, 0, 0, 35); rightBtn.Position = UDim2.new(0.52, 0, 0.32, 0); rightBtn.Text = "右"; rightBtn.TextColor3 = C.gold; applyStyle(rightBtn, 8)
local stopBtn = Instance.new("TextButton", main); stopBtn.Size = UDim2.new(0.9, 0, 0, 30); stopBtn.Position = UDim2.new(0.05, 0, 0.56, 0); stopBtn.Text = "NAVI STOP"; stopBtn.TextColor3 = Color3.fromRGB(200, 50, 50); applyStyle(stopBtn, 8)
local hubOpenBtn = Instance.new("TextButton", main); hubOpenBtn.Size = UDim2.new(0.9, 0, 0, 30); hubOpenBtn.Position = UDim2.new(0.05, 0, 0.78, 0); hubOpenBtn.Text = "OPEN HUB MENU"; hubOpenBtn.TextColor3 = C.gold; applyStyle(hubOpenBtn, 8)

-- ⚙️ 設定パネル (数値入力)
local settings = Instance.new("Frame", sg); settings.Size = UDim2.new(0, 180, 0, 150); settings.Position = UDim2.new(0.5, -90, 0.5, -75); settings.Visible = false; applyStyle(settings, 10)
local function makeInput(txt, y, default, callback)
    local lbl = Instance.new("TextLabel", settings); lbl.Size = UDim2.new(1, 0, 0, 20); lbl.Position = UDim2.new(0, 0, 0, y); lbl.Text = txt; lbl.TextColor3 = C.text; lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamBold
    local box = Instance.new("TextBox", settings); box.Size = UDim2.new(0.8, 0, 0, 25); box.Position = UDim2.new(0.1, 0, 0, y+20); box.Text = tostring(default); box.TextColor3 = C.gold; applyStyle(box, 5)
    box.FocusLost:Connect(function() local n = tonumber(box.Text); if n then callback(n) end end)
end
makeInput("Speed (行き)", 15, SPEED_IDA, function(v) SPEED_IDA = v end)
makeInput("Speed (帰り)", 75, SPEED_VOLTA, function(v) SPEED_VOLTA = v end)
gearBtn.MouseButton1Click:Connect(function() settings.Visible = not settings.Visible end)

-- OPEN HUB MENU (ON/OFF切り替え)
local hubMenu = Instance.new("Frame", sg); hubMenu.Size = UDim2.new(0, 180, 0, 160); hubMenu.Position = UDim2.new(0.5, -90, 0.3, 0); hubMenu.Visible = false; applyStyle(hubMenu, 10)
local hubLayout = Instance.new("UIListLayout", hubMenu); hubLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; hubLayout.Padding = UDim.new(0, 5)
local function addToggle(name, callback)
    local b = Instance.new("TextButton", hubMenu); b.Size = UDim2.new(0.9, 0, 0, 35); b.Text = name .. ": OFF"; b.TextColor3 = C.text; applyStyle(b, 6)
    local s = false
    b.MouseButton1Click:Connect(function() s = not s; b.Text = name .. ": " .. (s and "ON" or "OFF"); b.TextColor3 = s and Color3.fromRGB(0, 255, 150) or C.text; callback(s) end)
end
addToggle("Anti Ragdoll", function(v) antiRagdollActive = v end)
addToggle("Infinity Jump", function(v) infJumpActive = v end)
addToggle("Auto Grab", function(v) autoGrabEnabled = v end)
hubOpenBtn.MouseButton1Click:Connect(function() hubMenu.Visible = not hubMenu.Visible end)

-- 4. 実行ロジック
UIS.JumpRequest:Connect(function()
    if infJumpActive then
        local r = hrp()
        if r then r.Velocity = Vector3.new(r.Velocity.X, 50, r.Velocity.Z) end
    end
end)

RunService.Heartbeat:Connect(function()
    local r = hrp()
    if not r then return end
    local char = lp.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    -- Anti-Ragdoll
    if antiRagdollActive and hum then
        local s = hum:GetState()
        if s == Enum.HumanoidStateType.Physics or s == Enum.HumanoidStateType.Ragdoll or s == Enum.HumanoidStateType.FallingDown then
            pcall(function()
                for _, d in pairs(char:GetDescendants()) do
                    if d:IsA("BallSocketConstraint") or (d:IsA("Attachment") and string.find(d.Name, "RagdollAttachment")) then d:Destroy() end
                end
                lp:SetAttribute("RagdollEndTime", workspace:GetServerTimeNow())
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end)
        end
    end

    -- Auto Grab
    if autoGrabEnabled then
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("ProximityPrompt") then
                local pPart = v.Parent
                if pPart and pPart:IsA("BasePart") then
                    if (pPart.Position - r.Position).Magnitude < 20 then
                        fireSteal(v)
                    end
                end
            end
        end
    end
end)

-- ナビゲーション
leftBtn.MouseButton1Click:Connect(function()
    if auto1 then return end; auto1 = true
    task.spawn(function()
        go(A1[1], SPEED_IDA, function() return auto1 end)
        go(A1[2], SPEED_IDA, function() return auto1 end); instaGrab = true
        go(A1[3], SPEED_VOLTA, function() return auto1 end); instaGrab = false
        go(A1[4], SPEED_VOLTA, function() return auto1 end); auto1 = false
    end)
end)
rightBtn.MouseButton1Click:Connect(function()
    if auto2 then return end; auto2 = true
    task.spawn(function()
        go(B1[1], SPEED_IDA, function() return auto2 end)
        go(B1[2], SPEED_IDA, function() return auto2 end); instaGrab = true
        go(B1[3], SPEED_VOLTA, function() return auto2 end); instaGrab = false
        go(B1[4], SPEED_VOLTA, function() return auto2 end); auto2 = false
    end)
end)
stopBtn.MouseButton1Click:Connect(function() auto1, auto2 = false, false end)
aimBtn.MouseButton1Click:Connect(function() aimEnabled = not aimEnabled; aimBtn.BackgroundColor3 = aimEnabled and Color3.fromRGB(0, 100, 0) or C.bg end)