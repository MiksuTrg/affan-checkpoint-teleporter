-- AFFAN Checkpoint & Waypoint Teleporter v3.0

--// =========================================================
--// AFFAN Waypoint & Checkpoint Teleporter v3.0
--// © 2026 MiksuTrg - All Rights Reserved
--// Official: github.com/MiksuTrg/affan-checkpoint-teleporter
--// =========================================================

--// ANTI-COPY PROTECTION
local AFFAN_SECURITY = {}
AFFAN_SECURITY.VERSION = "3.0"
AFFAN_SECURITY.BUILD = "20260723"
AFFAN_SECURITY.SIGNATURE = "AFFAN_OFFICIAL_BUILD"

local function _ctpdiugz()
    local HttpService = game:GetService("HttpService")
    
    local success, clientId = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    
    if not success then
        clientId = "UNKNOWN_CLIENT"
    end
    
    local watermark = string.format("%s_%s_%s", 
        AFFAN_SECURITY.SIGNATURE, 
        AFFAN_SECURITY.VERSION, 
        AFFAN_SECURITY.BUILD)
    
    local sourceInfo = debug.info(1, "s")
    if sourceInfo and sourceInfo ~= "[C]" and sourceInfo ~= "" then
        if not sourceInfo:find("affan%-checkpoint%-teleporter") and not sourceInfo:find("MiksuTrg") then
            return false
        end
    end
    
    return true
end

local AFFAN_AUTHORIZED = true  -- Force allow for testing
-- local AFFAN_AUTHORIZED = _ctpdiugz()
if not AFFAN_AUTHORIZED then
    warn("[AFFAN] Protection check failed")
    return
end

--// MAIN SCRIPT STARTS HERE
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local state = {
    running = false,
    paused = false,
    currentIndex = 1,
    checkpoints = {},
    waypoints = {},
    loopEnabled = true,
    delayBetweenTP = 0.5,
    currentMode = "checkpoint",
    selectedFile = nil,
    minimized = false,
}

local UI = {}
local allConnections = {}
local waypointListConnections = {}

local function _hqpt2qw7(conn)
    table.insert(allConnections, conn)
    return conn
end

local function _cs1tpzkj(conn)
    table.insert(waypointListConnections, conn)
    return conn
end

local function _vuzgqxj1()
    for _, conn in ipairs(waypointListConnections) do
        if conn and conn.Connected then
            conn:Disconnect()
        end
    end
    waypointListConnections = {}
end

local function _88y58lcn()
    _vuzgqxj1()
    for _, conn in ipairs(allConnections) do
        if conn and conn.Connected then
            conn:Disconnect()
        end
    end
    allConnections = {}
end

local function _cfuisxds()
    local char = player.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return nil end
    return char, hrp, hum
end

local function _e9mip1i2()
    local cps = {}
    local seen = {}
    local workspace = game:GetService("Workspace")
    
    local checkpointFolder = workspace:FindFirstChild("Checkpoints") 
        or workspace:FindFirstChild("Stages")
        or workspace:FindFirstChild("Parts")
    
    if checkpointFolder then
        for _, child in ipairs(checkpointFolder:GetChildren()) do
            if (child:IsA("BasePart") or child:IsA("Model")) then
                local pos = child:IsA("Model") and child:GetPivot().Position or child.Position
                local key = string.format("%.1f_%.1f_%.1f", pos.X, pos.Y, pos.Z)
                if not seen[key] then
                    table.insert(cps, child)
                    seen[key] = true
                end
            end
        end
    else
        local checked = 0
        local maxChecks = 5000
        
        for _, obj in ipairs(workspace:GetDescendants()) do
            checked = checked + 1
            if checked > maxChecks then
                warn("[AFFAN] Workspace scan limited to 5000 objects")
                break
            end
            
            if obj:IsA("BasePart") then
                local name = obj.Name:lower()
                if name:match("checkpoint") or name:match("stage") or name:match("^%d+$") then
                    local pos = obj.Position
                    local key = string.format("%.1f_%.1f_%.1f", pos.X, pos.Y, pos.Z)
                    if not seen[key] then
                        table.insert(cps, obj)
                        seen[key] = true
                    end
                end
            end
        end
    end
    
    table.sort(cps, function(a, b)
        local aNum = tonumber(a.Name:match("%d+"))
        local bNum = tonumber(b.Name:match("%d+"))
        if aNum and bNum then return aNum < bNum end
        local aPos = a:IsA("Model") and a:GetPivot().Position or a.Position
        local bPos = b:IsA("Model") and b:GetPivot().Position or b.Position
        return aPos.Y < bPos.Y
    end)
    
    return cps
end

local function _sysqem8f(targetPos, offsetY)
    local char, hrp, hum = _cfuisxds()
    if not char or not hrp then return false end
    
    offsetY = offsetY or 3
    
    local rayOrigin = targetPos + Vector3.new(0, offsetY, 0)
    local rayDirection = Vector3.new(0, 5, 0)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {char}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    
    local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    if rayResult then offsetY = math.min(offsetY, 2) end
    
    hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, offsetY, 0))
    
    pcall(function()
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end)
    pcall(function()
        hrp.Velocity = Vector3.zero
        hrp.RotVelocity = Vector3.zero
    end)
    
    return true
end

local function _6d5208mo(cp)
    if not cp or not cp.Parent then return false end
    
    local targetPos
    if cp:IsA("Model") then
        local success, result = pcall(function() return cp:GetPivot() end)
        if success and result then
            targetPos = result.Position
        else
            local primary = cp.PrimaryPart or cp:FindFirstChildWhichIsA("BasePart")
            if not primary then return false end
            targetPos = primary.Position
        end
    else
        targetPos = cp.Position
    end
    
    return _sysqem8f(targetPos)
end

local function _gvhwi8km(text, color)
    if UI.StatusLabel then
        UI.StatusLabel.Text = text
        UI.StatusLabel.TextColor3 = color or Color3.fromRGB(200, 200, 200)
    end
end

local function _9o23w3v4(current, total)
    if UI.ProgressLabel then
        UI.ProgressLabel.Text = string.format("Progress: %d/%d", current, total)
    end
    if UI.ProgressBar then
        local percent = total > 0 and (current / total) or 0
        UI.ProgressBar.Size = UDim2.new(percent, 0, 1, 0)
    end
end

local function _lxukdnn5(name, pos, rot)
    local waypoint = {
        name = name or string.format("Waypoint %d", #state.waypoints + 1),
        pos = pos,
        rot = rot,
        timestamp = os.time(),
    }
    table.insert(state.waypoints, waypoint)
    return waypoint
end

local function _fzqkrrjz()
    local char, hrp, hum = _cfuisxds()
    if not char or not hrp then
        _gvhwi8km("❌ No character", Color3.fromRGB(255, 100, 100))
        return nil
    end
    
    local cam = workspace.CurrentCamera
    local wp = _lxukdnn5(
        string.format("WP_%d", #state.waypoints + 1),
        hrp.Position,
        cam and cam.CFrame or hrp.CFrame
    )
    
    _gvhwi8km(string.format("✅ Marked: %s", wp.name), Color3.fromRGB(80, 255, 120))
    return wp
end

local function _6jwuvp57(index)
    if index > 0 and index <= #state.waypoints then
        local wp = state.waypoints[index]
        table.remove(state.waypoints, index)
        _gvhwi8km(string.format("🗑 Deleted: %s", wp.name), Color3.fromRGB(200, 100, 100))
        return true
    end
    return false
end

local function _nu1cqu43()
    if #state.waypoints == 0 then
        _gvhwi8km("⚠ No waypoints", Color3.fromRGB(255, 200, 50))
        return false
    end
    
    local data = {
        version = "3.3",
        waypoints = {},
        savedAt = os.time(),
        mapName = workspace.Name or "Unknown",
    }
    
    for _, wp in ipairs(state.waypoints) do
        table.insert(data.waypoints, {
            name = wp.name,
            pos = {wp.pos.X, wp.pos.Y, wp.pos.Z},
            rot = wp.rot and {
                wp.rot:GetComponents()
            } or nil,
            timestamp = wp.timestamp,
        })
    end
    
    local json = HttpService:JSONEncode(data)
    
    if setclipboard then
        pcall(function()
            setclipboard(json)
            _gvhwi8km(string.format("📤 Copied: %d waypoints", #state.waypoints), Color3.fromRGB(80, 255, 120))
        end)
    else
        _gvhwi8km("❌ Clipboard unavailable", Color3.fromRGB(255, 100, 100))
    end
    
    return json
end

local function _9gy2bsue()
    if not getclipboard then
        _gvhwi8km("❌ Clipboard unavailable", Color3.fromRGB(255, 100, 100))
        return false
    end
    
    local success, json = pcall(function()
        return getclipboard()
    end)
    
    if not success or not json or json == "" then
        _gvhwi8km("❌ Clipboard empty", Color3.fromRGB(255, 100, 100))
        return false
    end
    
    local ok, data = pcall(function()
        return HttpService:JSONDecode(json)
    end)
    
    if not ok or not data.waypoints then
        _gvhwi8km("❌ Invalid format", Color3.fromRGB(255, 100, 100))
        return false
    end
    
    state.waypoints = {}
    for _, wp in ipairs(data.waypoints or {}) do
        local pos = Vector3.new(wp.pos[1], wp.pos[2], wp.pos[3])
        local rot = nil
        if wp.rot and #wp.rot == 12 then
            rot = CFrame.new(unpack(wp.rot))
        end
        _lxukdnn5(wp.name, pos, rot)
    end
    
    _gvhwi8km(string.format("📥 Imported: %d waypoints", #state.waypoints), Color3.fromRGB(80, 255, 120))
    return true
end

local function _irf3uoii(filename)
    if not writefile then
        _gvhwi8km("❌ writefile unavailable", Color3.fromRGB(255, 100, 100))
        return false
    end
    
    local data = {
        version = "3.0",
        waypoints = {},
        savedAt = os.time(),
        mapName = workspace.Name or "Unknown",
    }
    
    for _, wp in ipairs(state.waypoints) do
        table.insert(data.waypoints, {
            name = wp.name,
            pos = {wp.pos.X, wp.pos.Y, wp.pos.Z},
            rot = wp.rot and {
                wp.rot:GetComponents()
            } or nil,
            timestamp = wp.timestamp,
        })
    end
    
    local json = HttpService:JSONEncode(data)
    local path = "affan_waypoints_" .. filename .. ".json"
    
    pcall(function()
        writefile(path, json)
    end)
    
    _gvhwi8km(string.format("💾 Saved: %s", filename), Color3.fromRGB(80, 255, 120))
    return true
end

local function _h0lspl7d(filename)
    if not readfile then
        _gvhwi8km("❌ readfile unavailable", Color3.fromRGB(255, 100, 100))
        return false
    end
    
    local path = "affan_waypoints_" .. filename .. ".json"
    
    local success, json = pcall(function()
        return readfile(path)
    end)
    
    if not success then
        _gvhwi8km("❌ File not found", Color3.fromRGB(255, 100, 100))
        return false
    end
    
    local data = HttpService:JSONDecode(json)
    
    state.waypoints = {}
    for _, wp in ipairs(data.waypoints or {}) do
        local pos = Vector3.new(wp.pos[1], wp.pos[2], wp.pos[3])
        local rot = nil
        if wp.rot and #wp.rot == 12 then
            rot = CFrame.new(unpack(wp.rot))
        end
        _lxukdnn5(wp.name, pos, rot)
    end
    
    _gvhwi8km(string.format("📂 Loaded: %d waypoints", #state.waypoints), Color3.fromRGB(80, 255, 120))
    return true
end

local function _113obtxo()
    if not listfiles then return {} end
    
    local files = {}
    local success, result = pcall(function() return listfiles() end)
    
    if not success then return files end
    
    for _, path in ipairs(result) do
        local filename = path:match("affan_waypoints_(.+)%.json$")
        if filename then
            table.insert(files, filename)
        end
    end
    
    return files
end

local function _zl0a6cou()
    if state.running then return end
    
    local items = state.currentMode == "checkpoint" and state.checkpoints or state.waypoints
    
    if #items == 0 then
        _gvhwi8km("⚠ No items", Color3.fromRGB(255, 200, 50))
        return
    end
    
    state.running = true
    state.paused = false
    state.currentIndex = 1
    _gvhwi8km("🚀 Teleporting...", Color3.fromRGB(80, 255, 120))
    _9o23w3v4(0, #items)
    
    task.spawn(function()
        while state.running do
            if not state.paused then
                local char, hrp, hum = _cfuisxds()
                if not char or not hrp or not hum then
                    state.running = false
                    state.paused = false
                    _gvhwi8km("❌ Character invalid", Color3.fromRGB(255, 100, 100))
                    if UI.StartBtn then
                        UI.StartBtn.Text = "▶ START"
                        UI.StartBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
                    end
                    break
                end
                
                local item = items[state.currentIndex]
                local success = false
                
                if state.currentMode == "checkpoint" then
                    success = _6d5208mo(item)
                else
                    if item and item.pos then
                        success = _sysqem8f(item.pos)
                    end
                end
                
                if success then
                    _9o23w3v4(state.currentIndex, #items)
                    state.currentIndex = state.currentIndex + 1
                    
                    if state.currentIndex > #items then
                        if state.loopEnabled then
                            _gvhwi8km("🔄 Loop restart", Color3.fromRGB(100, 150, 255))
                            state.currentIndex = 1
                            _9o23w3v4(0, #items)
                            task.wait(state.delayBetweenTP * 2)
                        else
                            state.running = false
                            state.paused = false
                            _gvhwi8km("✅ Complete!", Color3.fromRGB(80, 255, 120))
                            _9o23w3v4(#items, #items)
                            if UI.StartBtn then
                                UI.StartBtn.Text = "▶ START"
                                UI.StartBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
                            end
                            break
                        end
                    else
                        task.wait(state.delayBetweenTP)
                    end
                else
                    state.running = false
                    state.paused = false
                    _gvhwi8km("❌ TP failed", Color3.fromRGB(255, 100, 100))
                    if UI.StartBtn then
                        UI.StartBtn.Text = "▶ START"
                        UI.StartBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
                    end
                    break
                end
            else
                task.wait(0.1)
            end
        end
    end)
end

local function _ad0v1g4w()
    state.running = false
    state.paused = false
    _gvhwi8km("⏹ Stopped", Color3.fromRGB(150, 150, 150))
    
    if UI.StartBtn then
        UI.StartBtn.Text = "▶ START"
        UI.StartBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
    end
    if UI.PauseBtn then
        UI.PauseBtn.Text = "⏸ PAUSE"
    end
end

local function _paulgc2n()
    if not UI.WaypointList then return end
    
    _vuzgqxj1()
    
    for _, child in ipairs(UI.WaypointList:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    for i, wp in ipairs(state.waypoints) do
        local Item = Instance.new("Frame")
        Item.Size = UDim2.new(1, -10, 0, 30)
        Item.Position = UDim2.new(0, 5, 0, (i-1) * 32)
        Item.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
        Item.BorderSizePixel = 0
        Item.Parent = UI.WaypointList
        
        local ItemCorner = Instance.new("UICorner")
        ItemCorner.CornerRadius = UDim.new(0, 4)
        ItemCorner.Parent = Item
        
        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1, -80, 1, 0)
        Label.Position = UDim2.new(0, 8, 0, 0)
        Label.BackgroundTransparency = 1
        Label.Text = string.format("%d. %s", i, wp.name)
        Label.TextColor3 = Color3.fromRGB(220, 220, 220)
        Label.Font = Enum.Font.Gotham
        Label.TextSize = 11
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.TextTruncate = Enum.TextTruncate.AtEnd
        Label.Parent = Item
        
        local TPBtn = Instance.new("TextButton")
        TPBtn.Size = UDim2.new(0, 35, 0, 22)
        TPBtn.Position = UDim2.new(1, -70, 0.5, -11)
        TPBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
        TPBtn.BorderSizePixel = 0
        TPBtn.Text = "TP"
        TPBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        TPBtn.Font = Enum.Font.GothamBold
        TPBtn.TextSize = 10
        TPBtn.Parent = Item
        
        local TPBtnCorner = Instance.new("UICorner")
        TPBtnCorner.CornerRadius = UDim.new(0, 4)
        TPBtnCorner.Parent = TPBtn
        
        _cs1tpzkj(TPBtn.MouseButton1Click:Connect(function()
            _sysqem8f(wp.pos)
            _gvhwi8km(string.format("🚀 TP: %s", wp.name), Color3.fromRGB(80, 255, 120))
        end))
        
        local DelBtn = Instance.new("TextButton")
        DelBtn.Size = UDim2.new(0, 28, 0, 22)
        DelBtn.Position = UDim2.new(1, -32, 0.5, -11)
        DelBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
        DelBtn.BorderSizePixel = 0
        DelBtn.Text = "✕"
        DelBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        DelBtn.Font = Enum.Font.GothamBold
        DelBtn.TextSize = 12
        DelBtn.Parent = Item
        
        local DelBtnCorner = Instance.new("UICorner")
        DelBtnCorner.CornerRadius = UDim.new(0, 4)
        DelBtnCorner.Parent = DelBtn
        
        _cs1tpzkj(DelBtn.MouseButton1Click:Connect(function()
            _6jwuvp57(i)
            _paulgc2n()
            if UI.WaypointListLabel then
                UI.WaypointListLabel.Text = string.format("🎯 Waypoints (%d)", #state.waypoints)
            end
        end))
    end
    
    UI.WaypointList.CanvasSize = UDim2.new(0, 0, 0, #state.waypoints * 32)
    
    if UI.WaypointListLabel then
        UI.WaypointListLabel.Text = string.format("🎯 Waypoints (%d)", #state.waypoints)
    end
end

local function _kv25uvu5()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AffanWaypointTP"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    if syn and syn.protect_gui then
        syn.protect_gui(ScreenGui)
        ScreenGui.Parent = game:GetService("CoreGui")
    else
        ScreenGui.Parent = player:WaitForChild("PlayerGui")
    end
    
    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Size = UDim2.new(0, 650, 0, 280)
    Main.Position = UDim2.new(0.5, -325, 0.5, -140)
    Main.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = true
    Main.Parent = ScreenGui
    
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 8)
    MainCorner.Parent = Main
    
    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 32)
    TitleBar.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = Main
    
    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 8)
    TitleCorner.Parent = TitleBar
    
    local TitleFill = Instance.new("Frame")
    TitleFill.Size = UDim2.new(1, 0, 0, 8)
    TitleFill.Position = UDim2.new(0, 0, 1, -8)
    TitleFill.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
    TitleFill.BorderSizePixel = 0
    TitleFill.Parent = TitleBar
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -35, 1, 0)
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "🎯 AFFAN v3.0 - Mobile"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 13
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TitleBar
    
    local MinBtn = Instance.new("TextButton")
    MinBtn.Size = UDim2.new(0, 28, 0, 28)
    MinBtn.Position = UDim2.new(1, -62, 0, 2)
    MinBtn.BackgroundColor3 = Color3.fromRGB(80, 120, 200)
    MinBtn.BorderSizePixel = 0
    MinBtn.Text = "_"
    MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.TextSize = 16
    MinBtn.Parent = TitleBar
    
    local MinCorner = Instance.new("UICorner")
    MinCorner.CornerRadius = UDim.new(0, 6)
    MinCorner.Parent = MinBtn
    
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 28, 0, 28)
    CloseBtn.Position = UDim2.new(1, -30, 0, 2)
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
    
    _hqpt2qw7(MinBtn.MouseButton1Click:Connect(function()
        state.minimized = not state.minimized
        if state.minimized then
            Main.Size = UDim2.new(0, 200, 0, 32)
            UI.LeftPanel.Visible = false
            UI.CenterPanel.Visible = false
            UI.RightPanel.Visible = false
            UI.Version.Visible = false
            MinBtn.Text = "□"
        else
            Main.Size = UDim2.new(0, 650, 0, 280)
            UI.LeftPanel.Visible = true
            UI.CenterPanel.Visible = true
            UI.RightPanel.Visible = true
            UI.Version.Visible = true
            MinBtn.Text = "_"
        end
    end))
    
    _hqpt2qw7(CloseBtn.MouseButton1Click:Connect(function()
        _ad0v1g4w()
        _88y58lcn()
        ScreenGui:Destroy()
    end))
    
    local LeftPanel = Instance.new("Frame")
    LeftPanel.Name = "LeftPanel"
    LeftPanel.Size = UDim2.new(0, 200, 1, -40)
    LeftPanel.Position = UDim2.new(0, 8, 0, 36)
    LeftPanel.BackgroundTransparency = 1
    LeftPanel.Parent = Main
    UI.LeftPanel = LeftPanel
    
    local function _2xezak85(text, yPos, color, callback, parent)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 28)
        btn.Position = UDim2.new(0, 0, 0, yPos)
        btn.BackgroundColor3 = color
        btn.BorderSizePixel = 0
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 11
        btn.AutoButtonColor = false
        btn.Parent = parent or LeftPanel
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = btn
        
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.1), {
                BackgroundColor3 = Color3.new(
                    math.min(color.R + 0.08, 1),
                    math.min(color.G + 0.08, 1),
                    math.min(color.B + 0.08, 1)
                )
            }):Play()
        end)
        
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.1), {
                BackgroundColor3 = color
            }):Play()
        end)
        
        btn.MouseButton1Click:Connect(callback)
        return btn
    end
    
    local ModeLabel = Instance.new("TextLabel")
    ModeLabel.Size = UDim2.new(1, 0, 0, 16)
    ModeLabel.BackgroundTransparency = 1
    ModeLabel.Text = "Mode"
    ModeLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    ModeLabel.Font = Enum.Font.Gotham
    ModeLabel.TextSize = 10
    ModeLabel.TextXAlignment = Enum.TextXAlignment.Left
    ModeLabel.Parent = LeftPanel
    
    local ModeToggle = Instance.new("TextButton")
    ModeToggle.Size = UDim2.new(1, 0, 0, 28)
    ModeToggle.Position = UDim2.new(0, 0, 0, 18)
    ModeToggle.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
    ModeToggle.BorderSizePixel = 0
    ModeToggle.Text = "📍 Checkpoint"
    ModeToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    ModeToggle.Font = Enum.Font.GothamBold
    ModeToggle.TextSize = 11
    ModeToggle.Parent = LeftPanel
    
    local ModeCorner = Instance.new("UICorner")
    ModeCorner.CornerRadius = UDim.new(0, 6)
    ModeCorner.Parent = ModeToggle
    
    _hqpt2qw7(ModeToggle.MouseButton1Click:Connect(function()
        state.currentMode = state.currentMode == "checkpoint" and "waypoint" or "checkpoint"
        if state.currentMode == "checkpoint" then
            ModeToggle.Text = "📍 Checkpoint"
            ModeToggle.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
        else
            ModeToggle.Text = "🎯 Waypoint"
            ModeToggle.BackgroundColor3 = Color3.fromRGB(200, 100, 180)
        end
    end))
    
    _2xezak85("🔍 SCAN", 52, Color3.fromRGB(60, 120, 200), function()
        state.checkpoints = _e9mip1i2()
        if #state.checkpoints > 0 then
            _gvhwi8km(string.format("✅ %d CPs", #state.checkpoints), Color3.fromRGB(80, 255, 120))
            _9o23w3v4(0, #state.checkpoints)
        else
            _gvhwi8km("⚠ No checkpoints", Color3.fromRGB(255, 200, 50))
        end
    end)
    
    _2xezak85("📌 MARK", 85, Color3.fromRGB(180, 100, 200), function()
        _fzqkrrjz()
        _paulgc2n()
    end)
    
    _2xezak85("💾 SAVE", 118, Color3.fromRGB(0, 150, 80), function()
        if #state.waypoints == 0 then
            _gvhwi8km("⚠ No waypoints", Color3.fromRGB(255, 200, 50))
            return
        end
        local filename = "wp_" .. os.date("%m%d_%H%M")
        _irf3uoii(filename)
        if UI.FileLabel then
            UI.FileLabel.Text = filename
        end
    end)
    
    _2xezak85("📂 LOAD", 151, Color3.fromRGB(200, 140, 0), function()
        local files = _113obtxo()
        if #files == 0 then
            _gvhwi8km("⚠ No files", Color3.fromRGB(255, 200, 50))
            return
        end
        local filename = state.selectedFile or files[1]
        if _h0lspl7d(filename) then
            _paulgc2n()
            if UI.FileLabel then
                UI.FileLabel.Text = filename
            end
        end
    end)
    
    local ExportBtn = Instance.new("TextButton")
    ExportBtn.Size = UDim2.new(0.48, 0, 0, 28)
    ExportBtn.Position = UDim2.new(0, 0, 0, 184)
    ExportBtn.BackgroundColor3 = Color3.fromRGB(100, 150, 200)
    ExportBtn.BorderSizePixel = 0
    ExportBtn.Text = "📤 EXPORT"
    ExportBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ExportBtn.Font = Enum.Font.GothamBold
    ExportBtn.TextSize = 10
    ExportBtn.Parent = LeftPanel
    
    local ExportBtnCorner = Instance.new("UICorner")
    ExportBtnCorner.CornerRadius = UDim.new(0, 6)
    ExportBtnCorner.Parent = ExportBtn
    
    _hqpt2qw7(ExportBtn.MouseButton1Click:Connect(function()
        _nu1cqu43()
    end))
    
    local ImportBtn = Instance.new("TextButton")
    ImportBtn.Size = UDim2.new(0.48, 0, 0, 28)
    ImportBtn.Position = UDim2.new(0.52, 0, 0, 184)
    ImportBtn.BackgroundColor3 = Color3.fromRGB(150, 100, 200)
    ImportBtn.BorderSizePixel = 0
    ImportBtn.Text = "📥 IMPORT"
    ImportBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ImportBtn.Font = Enum.Font.GothamBold
    ImportBtn.TextSize = 10
    ImportBtn.Parent = LeftPanel
    
    local ImportBtnCorner = Instance.new("UICorner")
    ImportBtnCorner.CornerRadius = UDim.new(0, 6)
    ImportBtnCorner.Parent = ImportBtn
    
    _hqpt2qw7(ImportBtn.MouseButton1Click:Connect(function()
        if _9gy2bsue() then
            _paulgc2n()
        end
    end))
    
    local StartBtn = _2xezak85("▶ START", 217, Color3.fromRGB(0, 180, 80), function()
        if state.running then
            _ad0v1g4w()
        else
            _zl0a6cou()
            StartBtn.Text = "⏹ STOP"
            StartBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
        end
    end)
    UI.StartBtn = StartBtn
    
    local LoopLabel = Instance.new("TextLabel")
    LoopLabel.Size = UDim2.new(0, 60, 0, 14)
    LoopLabel.Position = UDim2.new(0, 0, 0, 251)
    LoopLabel.BackgroundTransparency = 1
    LoopLabel.Text = "Loop"
    LoopLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    LoopLabel.Font = Enum.Font.Gotham
    LoopLabel.TextSize = 9
    LoopLabel.TextXAlignment = Enum.TextXAlignment.Left
    LoopLabel.Parent = LeftPanel
    
    local LoopToggle = Instance.new("TextButton")
    LoopToggle.Size = UDim2.new(0, 50, 0, 20)
    LoopToggle.Position = UDim2.new(1, -52, 0, 249)
    LoopToggle.BackgroundColor3 = Color3.fromRGB(0, 150, 70)
    LoopToggle.BorderSizePixel = 0
    LoopToggle.Text = "ON"
    LoopToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    LoopToggle.Font = Enum.Font.GothamBold
    LoopToggle.TextSize = 9
    LoopToggle.Parent = LeftPanel
    
    local LoopCorner = Instance.new("UICorner")
    LoopCorner.CornerRadius = UDim.new(0, 4)
    LoopCorner.Parent = LoopToggle
    
    _hqpt2qw7(LoopToggle.MouseButton1Click:Connect(function()
        state.loopEnabled = not state.loopEnabled
        LoopToggle.Text = state.loopEnabled and "ON" or "OFF"
        LoopToggle.BackgroundColor3 = state.loopEnabled 
            and Color3.fromRGB(0, 150, 70) 
            or Color3.fromRGB(60, 60, 70)
    end))
    
    local CenterPanel = Instance.new("Frame")
    CenterPanel.Name = "CenterPanel"
    CenterPanel.Size = UDim2.new(0, 220, 1, -40)
    CenterPanel.Position = UDim2.new(0, 216, 0, 36)
    CenterPanel.BackgroundTransparency = 1
    CenterPanel.Parent = Main
    UI.CenterPanel = CenterPanel
    
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, 0, 0, 18)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "● Idle"
    StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.TextSize = 10
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.Parent = CenterPanel
    UI.StatusLabel = StatusLabel
    
    local ProgressLabel = Instance.new("TextLabel")
    ProgressLabel.Size = UDim2.new(1, 0, 0, 16)
    ProgressLabel.Position = UDim2.new(0, 0, 0, 22)
    ProgressLabel.BackgroundTransparency = 1
    ProgressLabel.Text = "Progress: 0/0"
    ProgressLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    ProgressLabel.Font = Enum.Font.Gotham
    ProgressLabel.TextSize = 9
    ProgressLabel.TextXAlignment = Enum.TextXAlignment.Left
    ProgressLabel.Parent = CenterPanel
    UI.ProgressLabel = ProgressLabel
    
    local ProgressBG = Instance.new("Frame")
    ProgressBG.Size = UDim2.new(1, 0, 0, 6)
    ProgressBG.Position = UDim2.new(0, 0, 0, 42)
    ProgressBG.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    ProgressBG.BorderSizePixel = 0
    ProgressBG.Parent = CenterPanel
    
    local ProgressBGCorner = Instance.new("UICorner")
    ProgressBGCorner.CornerRadius = UDim.new(1, 0)
    ProgressBGCorner.Parent = ProgressBG
    
    local ProgressBar = Instance.new("Frame")
    ProgressBar.Size = UDim2.new(0, 0, 1, 0)
    ProgressBar.BackgroundColor3 = Color3.fromRGB(80, 150, 255)
    ProgressBar.BorderSizePixel = 0
    ProgressBar.Parent = ProgressBG
    
    local ProgressBarCorner = Instance.new("UICorner")
    ProgressBarCorner.CornerRadius = UDim.new(1, 0)
    ProgressBarCorner.Parent = ProgressBar
    UI.ProgressBar = ProgressBar
    
    local FileLabel = Instance.new("TextLabel")
    FileLabel.Size = UDim2.new(1, 0, 0, 24)
    FileLabel.Position = UDim2.new(0, 0, 0, 56)
    FileLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    FileLabel.BorderSizePixel = 0
    FileLabel.Text = "Auto-named"
    FileLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    FileLabel.Font = Enum.Font.Gotham
    FileLabel.TextSize = 9
    FileLabel.TextXAlignment = Enum.TextXAlignment.Left
    FileLabel.Parent = CenterPanel
    UI.FileLabel = FileLabel
    
    local FileLabelCorner = Instance.new("UICorner")
    FileLabelCorner.CornerRadius = UDim.new(0, 4)
    FileLabelCorner.Parent = FileLabel
    
    local FileLabelPadding = Instance.new("UIPadding")
    FileLabelPadding.PaddingLeft = UDim.new(0, 6)
    FileLabelPadding.Parent = FileLabel
    
    local DelayLabel = Instance.new("TextLabel")
    DelayLabel.Size = UDim2.new(1, 0, 0, 16)
    DelayLabel.Position = UDim2.new(0, 0, 0, 88)
    DelayLabel.BackgroundTransparency = 1
    DelayLabel.Text = string.format("⏱ %.1fs", state.delayBetweenTP)
    DelayLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    DelayLabel.Font = Enum.Font.Gotham
    DelayLabel.TextSize = 9
    DelayLabel.TextXAlignment = Enum.TextXAlignment.Left
    DelayLabel.Parent = CenterPanel
    UI.DelayLabel = DelayLabel
    
    local SliderBG = Instance.new("Frame")
    SliderBG.Size = UDim2.new(1, 0, 0, 6)
    SliderBG.Position = UDim2.new(0, 0, 0, 108)
    SliderBG.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    SliderBG.BorderSizePixel = 0
    SliderBG.Parent = CenterPanel
    
    local SliderBGCorner = Instance.new("UICorner")
    SliderBGCorner.CornerRadius = UDim.new(1, 0)
    SliderBGCorner.Parent = SliderBG
    
    local SliderFill = Instance.new("Frame")
    local initialPos = (state.delayBetweenTP - 0.1) / 2.9
    SliderFill.Size = UDim2.new(initialPos, 0, 1, 0)
    SliderFill.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    SliderFill.BorderSizePixel = 0
    SliderFill.Parent = SliderBG
    
    local SliderFillCorner = Instance.new("UICorner")
    SliderFillCorner.CornerRadius = UDim.new(1, 0)
    SliderFillCorner.Parent = SliderFill
    
    local SliderKnob = Instance.new("Frame")
    SliderKnob.Size = UDim2.new(0, 12, 0, 12)
    SliderKnob.Position = UDim2.new(initialPos, -6, 0.5, -6)
    SliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    SliderKnob.BorderSizePixel = 0
    SliderKnob.Parent = SliderBG
    
    local SliderKnobCorner = Instance.new("UICorner")
    SliderKnobCorner.CornerRadius = UDim.new(1, 0)
    SliderKnobCorner.Parent = SliderKnob
    
    local dragging = false
    
    _hqpt2qw7(SliderBG.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            Main.Draggable = false
        end
    end))
    
    _hqpt2qw7(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                dragging = false
                Main.Draggable = true
            end
        end
    end))
    
    _hqpt2qw7(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
                        input.UserInputType == Enum.UserInputType.Touch) then
            local pos = math.clamp(
                (input.Position.X - SliderBG.AbsolutePosition.X) / SliderBG.AbsoluteSize.X, 
                0, 1
            )
            local delay = 0.1 + (pos * 2.9)
            state.delayBetweenTP = math.floor(delay * 10) / 10
            
            SliderFill.Size = UDim2.new(pos, 0, 1, 0)
            SliderKnob.Position = UDim2.new(pos, -6, 0.5, -6)
            DelayLabel.Text = string.format("⏱ %.1fs", state.delayBetweenTP)
        end
    end))
    
    local RightPanel = Instance.new("Frame")
    RightPanel.Name = "RightPanel"
    RightPanel.Size = UDim2.new(0, 206, 1, -40)
    RightPanel.Position = UDim2.new(1, -214, 0, 36)
    RightPanel.BackgroundTransparency = 1
    RightPanel.Parent = Main
    UI.RightPanel = RightPanel
    
    local WaypointListLabel = Instance.new("TextLabel")
    WaypointListLabel.Size = UDim2.new(1, 0, 0, 16)
    WaypointListLabel.BackgroundTransparency = 1
    WaypointListLabel.Text = "🎯 Waypoints (0)"
    WaypointListLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    WaypointListLabel.Font = Enum.Font.GothamBold
    WaypointListLabel.TextSize = 10
    WaypointListLabel.TextXAlignment = Enum.TextXAlignment.Left
    WaypointListLabel.Parent = RightPanel
    UI.WaypointListLabel = WaypointListLabel
    
    local WaypointListBG = Instance.new("Frame")
    WaypointListBG.Size = UDim2.new(1, 0, 1, -20)
    WaypointListBG.Position = UDim2.new(0, 0, 0, 20)
    WaypointListBG.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    WaypointListBG.BorderSizePixel = 0
    WaypointListBG.Parent = RightPanel
    
    local WaypointListBGCorner = Instance.new("UICorner")
    WaypointListBGCorner.CornerRadius = UDim.new(0, 6)
    WaypointListBGCorner.Parent = WaypointListBG
    
    local WaypointList = Instance.new("ScrollingFrame")
    WaypointList.Size = UDim2.new(1, 0, 1, 0)
    WaypointList.BackgroundTransparency = 1
    WaypointList.BorderSizePixel = 0
    WaypointList.ScrollBarThickness = 3
    WaypointList.CanvasSize = UDim2.new(0, 0, 0, 0)
    WaypointList.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
    WaypointList.Parent = WaypointListBG
    UI.WaypointList = WaypointList
    
    local Version = Instance.new("TextLabel")
    Version.Name = "Version"
    Version.Size = UDim2.new(1, -16, 0, 12)
    Version.Position = UDim2.new(0, 8, 1, -16)
    Version.BackgroundTransparency = 1
    Version.Text = "AFFAN v3.3 Mobile"
    Version.TextColor3 = Color3.fromRGB(100, 100, 100)
    Version.Font = Enum.Font.Gotham
    Version.TextSize = 8
    Version.TextXAlignment = Enum.TextXAlignment.Center
    Version.Parent = Main
    UI.Version = Version
    
    return ScreenGui
end

local gui = _kv25uvu5()
_gvhwi8km("● Idle", Color3.fromRGB(150, 150, 150))

_hqpt2qw7(player.CharacterAdded:Connect(function()
    _ad0v1g4w()
    task.wait(0.5)
    _gvhwi8km("● Character respawned", Color3.fromRGB(200, 200, 80))
end))

pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "AFFAN v3.0",
        Text = "✅ Waypoint System loaded",
        Duration = 4,
    })
end)

print("[AFFAN] v3.0 Waypoint System loaded")
