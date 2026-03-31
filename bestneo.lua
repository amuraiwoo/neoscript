-- [[ NEOHUB - TOTO STYLE ULTIMATE (ANTI-RAGDOLL FIXED) ]]
repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local lp = Players.LocalPlayer

-- ============================================================
-- 1. 変数・座標設定
-- ============================================================
local SPEED_IDA = 60
local SPEED_VOLTA = 31
local stealRadius = 10
local auto1, auto2, instaGrab, aimEnabled = false, false, false, false
local antiRagdollActive = false
local infJumpActive = false
local autoGrabEnabled = false

local A1_P1, A1_P2, A1_P3, A1_P4 = Vector3.new(-472.59,-7.30,94.43), Vector3.new(-484.55,-5.33,95.05), Vector3.new(-472.59,-7.30,94.43), Vector3.new(-471.25,-6.83,7.08)
local B1, B2, B3, B4 = Vector3.new(-474.02,-7.30,25.55), Vector3.new(-484.92,-5.13,24.53), Vector3.new(-474.02,-7.30,25.55), Vector3.new(-470.93,-6.83,113.38)

-- ============================================================
-- 2. コア・ユーティリティ
-- ============================================================
local function hrp() return lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") end

local function go(pos, speed, cond)
    local r = hrp()
    if not r then return end
    while cond() and (r.Position - pos).Magnitude > 1 do
        local dir = (pos - r.Position).Unit
        r.AssemblyLinearVelocity = Vector3.new(dir.X * speed, r.AssemblyLinearVelocity.Y, dir.Z * speed)
        task.wait()
    end
end

-- 自動盗み用
local InternalStealCache = {}
local function buildCallbacks(prompt)
    if InternalStealCache[prompt] then return end
    local data = {hold={}, trigger={}, ready=true}
    local ok1, conns1 = pcall(getconnections, prompt.PromptButtonHoldBegan)
    if ok1 then for _, c in pairs(conns1) do if c.Function then table.insert(data.hold, c.Function) end end end
    local ok2, conns2 = pcall(getconnections, prompt.Triggered)
    if ok2 then for _, c in pairs(conns2) do if c.Function then table.insert(data.trigger, c.Function) end end end
    InternalStealCache[prompt] = data
end

local function runSteal(prompt)
    local data = InternalStealCache[prompt]
    if not data or not data.ready then return end
    data.ready = false
    task.spawn(function()
        for _, fn in pairs(data.hold) do task.spawn(fn) end
        task.wait(0.1)
        for _, fn in pairs(data.trigger) do task.spawn(fn) end
        task.wait(0.1)
        data.ready = true
    end)
end

-- ============================================================
-- 3. UI構築 (変更なし)
-- ============================================================
local C = { bg = Color3.fromRGB(15, 15, 15), gold = Color3.fromRGB(180, 150, 80), text = Color3.fromRGB(255, 255, 255) }
local sg = Instance.new("ScreenGui", lp.PlayerGui); sg.Name = "NEOHUB_TOTO_FINAL_V2"; sg.ResetOnSpawn = false
local function applyStyle(inst, r)
    Instance.new("UICorner", inst).CornerRadius = UDim.new(0, r or 8)
    local s = Instance.new("UIStroke", inst); s.Thickness = 2; s.Color = C.gold; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    if not inst:IsA("TextLabel") then inst.BackgroundColor3 = C.bg end
end

local main = Instance.new("Frame", sg); main.Size = UDim2.new(0, 200, 0, 180); main.Position = UDim2.new(0.8, 0, 0.5, -90); applyStyle(main, 12)
main.Active = true; main.Draggable = true

local aimBtn = Instance.new("TextButton", main); aimBtn.Size = UDim2.new(0.43, 0, 0, 35); aimBtn.Position = UDim2.new(0.05, 0, 0.08, 0); aimBtn.Text = "エイム"; aimBtn.TextColor3 = C.gold; applyStyle(aimBtn, 8)
local gearBtn = Instance.new("TextButton", main); gearBtn.Size = UDim2.new(0.43, 0, 0, 35); gearBtn.Position = UDim2.new(0.52, 0, 0.08, 0); gearBtn.Text = "⚙️"; gearBtn.TextColor3 = C.gold; applyStyle(gearBtn, 8)
local leftBtn = Instance.new("TextButton", main); leftBtn.Size = UDim2.new(0.43, 0, 0, 35); leftBtn.Position = UDim2.new(0.05, 0, 0.32, 0); leftBtn.Text = "左"; leftBtn.TextColor3 = C.gold; applyStyle(leftBtn, 8)
local rightBtn = Instance.new("TextButton", main); rightBtn.Size = UDim2.new(0.43, 0, 0, 35); rightBtn.Position = UDim2.new(0.52, 0, 0.32, 0); rightBtn.Text = "右"; rightBtn.TextColor3 = C.gold; applyStyle(rightBtn, 8)
local stopBtn = Instance.new("TextButton", main); stopBtn.Size = UDim2.new(0.9, 0, 0, 30); stopBtn.Position = UDim2.new(0.05, 0, 0.56, 0); stopBtn.Text = "NAVI STOP"; stopBtn.TextColor3 = Color3.fromRGB(200, 50, 50); applyStyle(stopBtn, 8)
local hubOpenBtn = Instance.new("TextButton", main); hubOpenBtn.Size = UDim2.new(0.9, 0, 0, 30); hubOpenBtn.Position = UDim2.new(0.05, 0, 0.78, 0); hubOpenBtn.Text = "OPEN HUB MENU"; hubOpenBtn.TextColor3 = C.gold; applyStyle(hubOpenBtn, 8)

local hubMenu = Instance.new("Frame", sg); hubMenu.Size = UDim2.new(0, 180, 0, 160); hubMenu.Position = UDim2.new(0.5, -90, 0.3, 0); hubMenu.Visible = false; applyStyle(hubMenu, 10)
local hubLayout = Instance.new("UIListLayout", hubMenu); hubLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; hubLayout.Padding = UDim.new(0, 5)
local function addToggle(name, callback)
    local b = Instance.new("TextButton", hubMenu); b.Size = UDim2.new(0.9, 0, 0, 35); b.Text = name .. ": OFF"; b.TextColor3 = C.text; applyStyle(b, 6)
    local s = false
    b.MouseButton1Click:Connect(function() s = not s; b.Text = name .. ": " .. (s and "ON" or "OFF"); b.TextColor3 = s and Color3.fromRGB(0, 255, 150) or C.text; callback(s) end)
end
addToggle("Anti Ragdoll", function(v) antiRagdollActive = v end)
addToggle("Infinity Jump", function(v) infJumpActive = v end)
addToggle("Auto Grab", function(v) autoGrabEnabled = v end)
hubOpenBtn.MouseButton1Click:Connect(function() hubMenu.Visible = not hubMenu.Visible end)

-- ============================================================
-- 4. 実行ループ (Anti-Ragdoll 改善版)
-- ============================================================
RunService.Heartbeat:Connect(function()
    local char = lp.Character
    local r = hrp()
    if not char or not r then return end

    -- 【改善】Anti-Ragdoll ロジック
    if antiRagdollActive then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            -- 1. 物理的なダウン状態を強制キャンセル
            if hum:GetState() == Enum.HumanoidStateType.Ragdoll or 
               hum:GetState() == Enum.HumanoidStateType.Physics or 
               hum:GetState() == Enum.HumanoidStateType.FallingDown then
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                task.wait()
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end
            
            -- 2. キャラクターの速度をチェック（倒れて動かなくなるのを防ぐ）
            if r.AssemblyAngularVelocity.Magnitude > 20 then
                r.AssemblyAngularVelocity = Vector3.new(0,0,0)
            end

            -- 3. ゲーム独自のRagdoll属性やジョイントを無効化（もしあれば）
            for _, v in pairs(char:GetDescendants()) do
                if v:IsA("BallSocketConstraint") then v.Enabled = false end
            end
        end
    end

    -- 自動盗み監視
    if instaGrab or autoGrabEnabled then
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("ProximityPrompt") then
                local p = v.Parent
                local pos2 = p:IsA("Attachment") and p.WorldPosition or p.Position
                if pos2 and (pos2 - r.Position).Magnitude < stealRadius then
                    buildCallbacks(v)
                    runSteal(v)
                end
            end
        end
    end
end)

-- ナビゲーション
leftBtn.MouseButton1Click:Connect(function()
    if auto1 then return end; auto1 = true
    task.spawn(function()
        go(A1_P1, SPEED_IDA, function() return auto1 end)
        go(A1_P2, SPEED_IDA, function() return auto1 end)
        instaGrab = true
        go(A1_P3, SPEED_VOLTA, function() return auto1 end)
        instaGrab = false
        go(A1_P4, SPEED_VOLTA, function() return auto1 end)
        auto1 = false
    end)
end)

rightBtn.MouseButton1Click:Connect(function()
    if auto2 then return end; auto2 = true
    task.spawn(function()
        go(B1, SPEED_IDA, function() return auto2 end)
        go(B2, SPEED_IDA, function() return auto2 end)
        instaGrab = true
        go(B3, SPEED_VOLTA, function() return auto2 end)
        instaGrab = false
        go(B4, SPEED_VOLTA, function() return auto2 end)
        auto2 = false
    end)
end)

stopBtn.MouseButton1Click:Connect(function() auto1, auto2, instaGrab = false, false, false end)
UIS.JumpRequest:Connect(function() if infJumpActive then local r = hrp() if r then r.Velocity = Vector3.new(r.Velocity.X, 50, r.Velocity.Z) end end end)
