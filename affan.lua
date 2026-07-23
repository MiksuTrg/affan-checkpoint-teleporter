-- AFFAN Checkpoint Teleporter v2
-- Auto teleport ke setiap checkpoint sampai summit
-- No external dependencies - pure Roblox UI

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- State
local state = {
    running = false,
    paused = false,
    currentIndex = 1,
    checkpoints = {},
    loopEnabled = true,
    delayBetweenTP = 0.5,
}

-- UI references
local UI = {}

-- Helper functions
local function getCharacter()
    local char = player.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not hrp or not hum then return nil end
    return char, hrp, hum
end

-- Scan checkpoints
local function scanCheckpoints()
    local cps = {}
    local seen = {}
    local workspace = game:GetService("Workspace")
    
    -- Pattern 1: Folder "Checkpoints" / "Stages" / "Parts"
    local checkpointFolder = workspace:FindFirstChild("Checkpoints") 
        or workspace:FindFirstChild("Stages")
        or workspace:FindFirstChild("Parts")
    
    if checkpointFolder then
        for _, child in ipairs(checkpointFolder:GetChildren()) do
            if (child:IsA("BasePart") or child:IsA("Model")) and not seen[child] then
                table.insert(cps, child)
                seen[child] = true
            end
        end
    else
        -- Pattern 2: Scan part names
        local checked = 0
        local maxChecks = 5000
        
        for _, obj in ipairs(workspace:GetDescendants()) do
            checked = checked + 1
            if checked > maxChecks then
                warn("[AFFAN] Workspace scan limited to 5000 objects")
                break
            end
            
            if obj:IsA("BasePart") and not seen[obj] then
                local name = obj.Name:lower()
                if name:match("checkpoint") or name:match("stage") or name:match("^%d+$") then
                    table.insert(cps, obj)
                    seen[obj] = true
                end
            end
        end
    end
    
    -- Sort by number or Y position
    table.sort(cps, function(a, b)
        local aNum = tonumber(a.Name:match("%d+"))
        local bNum = tonumber(b.Name:match("%d+"))
        if aNum and bNum then
            return aNum < bNum
        end
        local aPos = a:IsA("Model") and a:GetPivot().Position or a.Position
        local bPos = b:IsA("Model") and b:GetPivot().Position or b.Position
        return aPos.Y < bPos.Y
    end)
    
    return cps
end

-- Teleport to checkpoint
local function teleportToCP(cp)
    local char, hrp, hum = getCharacter()
    if not char or not hrp then 
        return false
    end
    
    if not cp or not cp.Parent then
        warn("[AFFAN] Checkpoint not found")
        return false
    end
    
    local targetPos
    if cp:IsA("Model") then
        targetPos = cp:GetPivot().Position
    else
        targetPos = cp.Position
    end
    
    -- Teleport slightly above
    hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 5, 0))
    
    -- Reset velocity
    if hrp:FindFirstChild("AssemblyLinearVelocity") then
        hrp.AssemblyLinearVelocity = Vector3.zero
    end
    hrp.Velocity = Vector3.zero
    hrp.RotVelocity = Vector3.zero
    
    return true
end

-- Update UI status
local function updateStatus(text, color)
    if UI.StatusLabel then
        UI.StatusLabel.Text = text
        UI.StatusLabel.TextColor3 = color or Color3.fromRGB(200, 200, 200)
    end
end

local function updateProgress(current, total)
    if UI.ProgressLabel then
        UI.ProgressLabel.Text = string.format("Progress: %d/%d", current, total)
    end
    if UI.ProgressBar then
        local percent = total > 0 and (current / total) or 0
        UI.ProgressBar.Size = UDim2.new(percent, 0, 1, 0)
    end
end

-- Main teleport loop
local function startTeleporting()
    if state.running then return end
    if #state.checkpoints == 0 then
        updateStatus("⚠ No checkpoints found", Color3.fromRGB(255, 200, 50))
        return
    end
    
    state.running = true
    state.currentIndex = 1
    updateStatus("🚀 Teleporting...", Color3.fromRGB(80, 255, 120))
    
    task.spawn(function()
        while state.running do
            if not state.paused then
                local cp = state.checkpoints[state.currentIndex]
                
                if cp and cp.Parent then
                    local success = teleportToCP(cp)
                    
                    if success then
                        updateProgress(state.currentIndex, #state.checkpoints)
                        
                        state.currentIndex = state.currentIndex + 1
                        
                        -- Reached summit
                        if state.currentIndex > #state.checkpoints then
                            if state.loopEnabled then
                                updateStatus("🔄 Loop: Restarting...", Color3.fromRGB(100, 150, 255))
                                state.currentIndex = 1
                                task.wait(state.delayBetweenTP * 2)
                            else
                                state.running = false
                                updateStatus("✅ Summit reached!", Color3.fromRGB(80, 255, 120))
                                updateProgress(#state.checkpoints, #state.checkpoints)
                                break
                            end
                        else
                            task.wait(state.delayBetweenTP)
                        end
                    else
                        updateStatus("❌ Teleport failed", Color3.fromRGB(255, 100, 100))
                        state.running = false
                        break
                    end
                else
                    updateStatus("❌ Checkpoint invalid", Color3.fromRGB(255, 100, 100))
                    state.running = false
                    break
                end
            else
                updateStatus("⏸ Paused", Color3.fromRGB(255, 200, 80))
                task.wait(0.1)
            end
        end
    end)
end

local function stopTeleporting()
    state.running = false
    state.paused = false
    updateStatus("⏹ Stopped", Color3.fromRGB(150, 150, 150))
end

-- Create UI
local function createUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AffanCheckpointTP"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Protect from anti-cheat
    if syn and syn.protect_gui then
        syn.protect_gui(ScreenGui)
        ScreenGui.Parent = game:GetService("CoreGui")
    else
        ScreenGui.Parent = player:WaitForChild("PlayerGui")
    end
    
    -- Main Frame
    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Size = UDim2.new(0, 320, 0, 400)
    Main.Position = UDim2.new(0.5, -160, 0.2, 0)
    Main.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = true
    Main.Parent = ScreenGui
    
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 10)
    MainCorner.Parent = Main
    
    -- Title Bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 40)
    TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = Main
    
    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 10)
    TitleCorner.Parent = TitleBar
    
    local TitleFill = Instance.new("Frame")
    TitleFill.Size = UDim2.new(1, 0, 0, 10)
    TitleFill.Position = UDim2.new(0, 0, 1, -10)
    TitleFill.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
    TitleFill.BorderSizePixel = 0
    TitleFill.Parent = TitleBar
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -50, 1, 0)
    Title.Position = UDim2.new(0, 15, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "🎯 AFFAN Checkpoint TP"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 16
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TitleBar
    
    -- Close Button
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -35, 0, 5)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 14
    CloseBtn.Parent = TitleBar
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 6)
    CloseCorner.Parent = CloseBtn
    
    CloseBtn.MouseButton1Click:Connect(function()
        stopTeleporting()
        ScreenGui:Destroy()
    end)
    
    -- Status Label
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, -30, 0, 25)
    StatusLabel.Position = UDim2.new(0, 15, 0, 50)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "● Idle"
    StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.TextSize = 13
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.Parent = Main
    UI.StatusLabel = StatusLabel
    
    -- Progress Label
    local ProgressLabel = Instance.new("TextLabel")
    ProgressLabel.Size = UDim2.new(1, -30, 0, 20)
    ProgressLabel.Position = UDim2.new(0, 15, 0, 78)
    ProgressLabel.BackgroundTransparency = 1
    ProgressLabel.Text = "Progress: 0/0"
    ProgressLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    ProgressLabel.Font = Enum.Font.Gotham
    ProgressLabel.TextSize = 12
    ProgressLabel.TextXAlignment = Enum.TextXAlignment.Left
    ProgressLabel.Parent = Main
    UI.ProgressLabel = ProgressLabel
    
    -- Progress Bar Background
    local ProgressBG = Instance.new("Frame")
    ProgressBG.Size = UDim2.new(1, -30, 0, 8)
    ProgressBG.Position = UDim2.new(0, 15, 0, 102)
    ProgressBG.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
    ProgressBG.BorderSizePixel = 0
    ProgressBG.Parent = Main
    
    local ProgressBGCorner = Instance.new("UICorner")
    ProgressBGCorner.CornerRadius = UDim.new(1, 0)
    ProgressBGCorner.Parent = ProgressBG
    
    -- Progress Bar Fill
    local ProgressBar = Instance.new("Frame")
    ProgressBar.Size = UDim2.new(0, 0, 1, 0)
    ProgressBar.BackgroundColor3 = Color3.fromRGB(80, 150, 255)
    ProgressBar.BorderSizePixel = 0
    ProgressBar.Parent = ProgressBG
    
    local ProgressBarCorner = Instance.new("UICorner")
    ProgressBarCorner.CornerRadius = UDim.new(1, 0)
    ProgressBarCorner.Parent = ProgressBar
    UI.ProgressBar = ProgressBar
    
    -- Button Helper
    local function createButton(text, yPos, color, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -30, 0, 40)
        btn.Position = UDim2.new(0, 15, 0, yPos)
        btn.BackgroundColor3 = color
        btn.BorderSizePixel = 0
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        btn.AutoButtonColor = false
        btn.Parent = Main
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = btn
        
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {
                BackgroundColor3 = Color3.new(
                    math.min(color.R + 0.1, 1),
                    math.min(color.G + 0.1, 1),
                    math.min(color.B + 0.1, 1)
                )
            }):Play()
        end)
        
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {
                BackgroundColor3 = color
            }):Play()
        end)
        
        btn.MouseButton1Click:Connect(callback)
        return btn
    end
    
    -- Scan Button
    createButton("🔍 SCAN CHECKPOINTS", 125, Color3.fromRGB(60, 120, 200), function()
        state.checkpoints = scanCheckpoints()
        if #state.checkpoints > 0 then
            updateStatus(string.format("✅ Found %d checkpoints", #state.checkpoints), Color3.fromRGB(80, 255, 120))
            updateProgress(0, #state.checkpoints)
        else
            updateStatus("⚠ No checkpoints found", Color3.fromRGB(255, 200, 50))
        end
    end)
    
    -- Start/Stop Button
    local StartBtn = createButton("▶ START TELEPORT", 175, Color3.fromRGB(0, 180, 80), function()
        if state.running then
            stopTeleporting()
            StartBtn.Text = "▶ START TELEPORT"
            StartBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
        else
            startTeleporting()
            StartBtn.Text = "⏹ STOP"
            StartBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
        end
    end)
    UI.StartBtn = StartBtn
    
    -- Pause Button
    local PauseBtn = createButton("⏸ PAUSE", 225, Color3.fromRGB(200, 140, 0), function()
        if state.running then
            state.paused = not state.paused
            if state.paused then
                PauseBtn.Text = "▶ RESUME"
                updateStatus("⏸ Paused", Color3.fromRGB(255, 200, 80))
            else
                PauseBtn.Text = "⏸ PAUSE"
                updateStatus("🚀 Teleporting...", Color3.fromRGB(80, 255, 120))
            end
        end
    end)
    UI.PauseBtn = PauseBtn
    
    -- Loop Toggle
    local LoopLabel = Instance.new("TextLabel")
    LoopLabel.Size = UDim2.new(0, 150, 0, 20)
    LoopLabel.Position = UDim2.new(0, 15, 0, 280)
    LoopLabel.BackgroundTransparency = 1
    LoopLabel.Text = "🔄 Loop Mode:"
    LoopLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    LoopLabel.Font = Enum.Font.Gotham
    LoopLabel.TextSize = 12
    LoopLabel.TextXAlignment = Enum.TextXAlignment.Left
    LoopLabel.Parent = Main
    
    local LoopToggle = Instance.new("TextButton")
    LoopToggle.Size = UDim2.new(0, 80, 0, 28)
    LoopToggle.Position = UDim2.new(1, -95, 0, 276)
    LoopToggle.BackgroundColor3 = Color3.fromRGB(0, 150, 70)
    LoopToggle.BorderSizePixel = 0
    LoopToggle.Text = "ON"
    LoopToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    LoopToggle.Font = Enum.Font.GothamBold
    LoopToggle.TextSize = 12
    LoopToggle.Parent = Main
    
    local LoopToggleCorner = Instance.new("UICorner")
    LoopToggleCorner.CornerRadius = UDim.new(0, 6)
    LoopToggleCorner.Parent = LoopToggle
    
    LoopToggle.MouseButton1Click:Connect(function()
        state.loopEnabled = not state.loopEnabled
        LoopToggle.Text = state.loopEnabled and "ON" or "OFF"
        LoopToggle.BackgroundColor3 = state.loopEnabled and Color3.fromRGB(0, 150, 70) or Color3.fromRGB(60, 60, 70)
    end)
    
    -- Delay Label
    local DelayLabel = Instance.new("TextLabel")
    DelayLabel.Size = UDim2.new(1, -30, 0, 20)
    DelayLabel.Position = UDim2.new(0, 15, 0, 315)
    DelayLabel.BackgroundTransparency = 1
    DelayLabel.Text = string.format("⏱ Delay Between TP: %.1fs", state.delayBetweenTP)
    DelayLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    DelayLabel.Font = Enum.Font.Gotham
    DelayLabel.TextSize = 12
    DelayLabel.TextXAlignment = Enum.TextXAlignment.Left
    DelayLabel.Parent = Main
    UI.DelayLabel = DelayLabel
    
    -- Delay Slider Background
    local SliderBG = Instance.new("Frame")
    SliderBG.Size = UDim2.new(1, -30, 0, 8)
    SliderBG.Position = UDim2.new(0, 15, 0, 340)
    SliderBG.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
    SliderBG.BorderSizePixel = 0
    SliderBG.Parent = Main
    
    local SliderBGCorner = Instance.new("UICorner")
    SliderBGCorner.CornerRadius = UDim.new(1, 0)
    SliderBGCorner.Parent = SliderBG
    
    -- Delay Slider Fill
    local SliderFill = Instance.new("Frame")
    SliderFill.Size = UDim2.new(0.15, 0, 1, 0)
    SliderFill.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    SliderFill.BorderSizePixel = 0
    SliderFill.Parent = SliderBG
    
    local SliderFillCorner = Instance.new("UICorner")
    SliderFillCorner.CornerRadius = UDim.new(1, 0)
    SliderFillCorner.Parent = SliderFill
    
    -- Slider Knob
    local SliderKnob = Instance.new("Frame")
    SliderKnob.Size = UDim2.new(0, 16, 0, 16)
    SliderKnob.Position = UDim2.new(0.15, -8, 0.5, -8)
    SliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    SliderKnob.BorderSizePixel = 0
    SliderKnob.Parent = SliderBG
    
    local SliderKnobCorner = Instance.new("UICorner")
    SliderKnobCorner.CornerRadius = UDim.new(1, 0)
    SliderKnobCorner.Parent = SliderKnob
    
    local dragging = false
    SliderBG.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    
    game:GetService("UserInputService").InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local pos = math.clamp((input.Position.X - SliderBG.AbsolutePosition.X) / SliderBG.AbsoluteSize.X, 0, 1)
            local delay = 0.1 + (pos * 2.9)
            state.delayBetweenTP = math.floor(delay * 10) / 10
            
            SliderFill.Size = UDim2.new(pos, 0, 1, 0)
            SliderKnob.Position = UDim2.new(pos, -8, 0.5, -8)
            DelayLabel.Text = string.format("⏱ Delay Between TP: %.1fs", state.delayBetweenTP)
        end
    end)
    
    -- Version Label
    local Version = Instance.new("TextLabel")
    Version.Size = UDim2.new(1, -30, 0, 18)
    Version.Position = UDim2.new(0, 15, 1, -25)
    Version.BackgroundTransparency = 1
    Version.Text = "AFFAN v2.0 | No WindUI"
    Version.TextColor3 = Color3.fromRGB(100, 100, 100)
    Version.Font = Enum.Font.Gotham
    Version.TextSize = 10
    Version.TextXAlignment = Enum.TextXAlignment.Center
    Version.Parent = Main
    
    return ScreenGui
end

-- Initialize
local gui = createUI()
updateStatus("● Idle", Color3.fromRGB(150, 150, 150))

-- Character respawn handling
player.CharacterAdded:Connect(function()
    stopTeleporting()
    task.wait(1)
    updateStatus("● Character respawned", Color3.fromRGB(200, 200, 80))
end)

-- Notification
pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "AFFAN Checkpoint TP",
        Text = "✅ v2.0 loaded | Click SCAN to start",
        Duration = 4,
    })
end)

print("[AFFAN] Checkpoint Teleporter v2.0 loaded")
