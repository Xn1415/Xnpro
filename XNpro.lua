-- [[ Xnpro - 主要分类：自动重生 / 自动锻炼 / 自动锻炼2 / 自动转盘 ]]
-- 直接粘贴到注入器执行即可

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ==================== 全局配置 ====================
local Config = {
    autoRebirth = false,
    autoTrain = false,
    autoTrain2 = false,
    autoSpin = false,
    trainInterval = 0.15,
    train2Interval = 0.5,
    rebirthInterval = 2,
    spinInterval = 3,      -- 转盘间隔（秒）
}

-- 常量
local MUSCLE_KING_BENCH = "Muscle King Bench"
local MACHINES_FOLDER = "machinesFolder"
local FORTUNE_WHEEL_NAME = "Fortune Wheel"

-- ==================== 主题 ====================
local Theme = {
    bg = Color3.fromRGB(0, 0, 0),
    bgDark = Color3.fromRGB(18, 18, 18),
    bgCard = Color3.fromRGB(30, 30, 30),
    bgLight = Color3.fromRGB(42, 42, 42),
    border = Color3.fromRGB(42, 42, 42),
    text = Color3.fromRGB(255, 255, 255),
    textMuted = Color3.fromRGB(136, 136, 136),
    accent = Color3.fromRGB(255, 255, 255),
}

-- 清理旧 GUI
local oldGui = playerGui:FindFirstChild("XnproMenu")
if oldGui then oldGui:Destroy() end

-- ==================== 辅助函数 ====================
local function applyCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
    return corner
end

local function applyStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Theme.border
    stroke.Thickness = thickness or 1
    stroke.Parent = parent
    return stroke
end

local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragStart, startPos
    local moved = false

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            moved = false
            dragStart = input.Position
            startPos = frame.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            if math.abs(delta.X) > 3 or math.abs(delta.Y) > 3 then
                moved = true
            end
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    return function() return moved end
end

-- ==================== 核心功能 ====================

-- 自动锻炼
local function doTrain()
    if not player.Character then return end
    local muscleEvent = player:FindFirstChild("muscleEvent")
    if not muscleEvent then return end

    pcall(function()
        muscleEvent:FireServer("rep")
    end)
end

-- 自动锻炼2（肌肉之王健身房器械）
local function doTrain2()
    local rEvents = ReplicatedStorage:FindFirstChild("rEvents")
    if not rEvents then return end

    local machineRemote = rEvents:FindFirstChild("machineInteractRemote")
    if not machineRemote then return end

    local machinesFolder = workspace:FindFirstChild(MACHINES_FOLDER)
    if not machinesFolder then return end

    local bench = machinesFolder:FindFirstChild(MUSCLE_KING_BENCH)
    if not bench then return end

    local interactSeat = bench:FindFirstChild("interactSeat")
    if not interactSeat then return end

    pcall(function()
        if machineRemote:IsA("RemoteFunction") then
            machineRemote:InvokeServer("useMachine", interactSeat)
        else
            machineRemote:FireServer("useMachine", interactSeat)
        end
    end)
end

-- 自动重生
local function doRebirth()
    local rEvents = ReplicatedStorage:FindFirstChild("rEvents")
    if not rEvents then return end

    local rebirthRemote = rEvents:FindFirstChild("rebirthRemote")
    if not rebirthRemote then return end

    pcall(function()
        if rebirthRemote:IsA("RemoteFunction") then
            rebirthRemote:InvokeServer("rebirthRequest")
        else
            rebirthRemote:FireServer("rebirthRequest")
        end
    end)
end

-- 自动转盘
local function doSpin()
    local rEvents = ReplicatedStorage:FindFirstChild("rEvents")
    if not rEvents then return end

    local spinRemote = rEvents:FindFirstChild("openFortuneWheelRemote")
    if not spinRemote then return end

    -- 从 shared.catalogs.fortuneWheelChances 取转盘数据
    local sharedFolder = ReplicatedStorage:FindFirstChild("shared")
    if not sharedFolder then return end

    local catalogs = sharedFolder:FindFirstChild("catalogs")
    if not catalogs then return end

    local chances = catalogs:FindFirstChild("fortuneWheelChances")
    if not chances then return end

    local wheelData = chances:FindFirstChild(FORTUNE_WHEEL_NAME)
    if not wheelData then return end

    pcall(function()
        if spinRemote:IsA("RemoteFunction") then
            spinRemote:InvokeServer("openFortuneWheel", wheelData)
        else
            spinRemote:FireServer("openFortuneWheel", wheelData)
        end
    end)
end

-- ==================== 主循环 ====================

task.spawn(function()
    while task.wait(Config.trainInterval) do
        if Config.autoTrain then doTrain() end
    end
end)

task.spawn(function()
    while task.wait(Config.train2Interval) do
        if Config.autoTrain2 then doTrain2() end
    end
end)

task.spawn(function()
    while task.wait(Config.rebirthInterval) do
        if Config.autoRebirth then doRebirth() end
    end
end)

task.spawn(function()
    while task.wait(Config.spinInterval) do
        if Config.autoSpin then doSpin() end
    end
end)

-- ==================== 创建 ScreenGui ====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "XnproMenu"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- 悬浮岛
local island = Instance.new("TextButton")
island.Name = "Island"
island.Size = UDim2.new(0, 120, 0, 38)
island.Position = UDim2.new(0.5, -60, 0.5, -19)
island.BackgroundColor3 = Theme.bg
island.Text = "👑 Xnpro"
island.TextColor3 = Theme.text
island.Font = Enum.Font.GothamBold
island.TextSize = 13
island.AutoButtonColor = false
island.Parent = screenGui
applyCorner(island, 19)
applyStroke(island, Color3.fromRGB(60, 60, 60), 1)

-- 菜单面板
local menuPanel = Instance.new("Frame")
menuPanel.Name = "MenuPanel"
menuPanel.Size = UDim2.new(0, 300, 0, 380)
menuPanel.Position = UDim2.new(0.5, -150, 0.5, -190)
menuPanel.BackgroundColor3 = Theme.bg
menuPanel.Visible = false
menuPanel.Parent = screenGui
applyCorner(menuPanel, 14)
applyStroke(menuPanel, Color3.fromRGB(60, 60, 60), 1)

-- 顶部标题栏
local topHeader = Instance.new("Frame")
topHeader.Size = UDim2.new(1, 0, 0, 36)
topHeader.BackgroundColor3 = Theme.bgDark
topHeader.Parent = menuPanel
applyCorner(topHeader, 14)

local headerCut = Instance.new("Frame")
headerCut.Size = UDim2.new(1, 0, 0, 14)
headerCut.Position = UDim2.new(0, 0, 1, -14)
headerCut.BackgroundColor3 = Theme.bgDark
headerCut.BorderSizePixel = 0
headerCut.Parent = topHeader

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -60, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "👑 Xnpro"
titleLabel.TextColor3 = Theme.text
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 13
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = topHeader

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 20, 0, 20)
minBtn.Position = UDim2.new(1, -52, 0.5, -10)
minBtn.BackgroundColor3 = Theme.bgLight
minBtn.Text = "—"
minBtn.TextColor3 = Theme.textMuted
minBtn.TextSize = 12
minBtn.AutoButtonColor = false
minBtn.Parent = topHeader
applyCorner(minBtn, 10)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 20, 0, 20)
closeBtn.Position = UDim2.new(1, -26, 0.5, -10)
closeBtn.BackgroundColor3 = Theme.bgLight
closeBtn.Text = "✕"
closeBtn.TextColor3 = Theme.textMuted
closeBtn.TextSize = 12
closeBtn.AutoButtonColor = false
closeBtn.Parent = topHeader
applyCorner(closeBtn, 10)

-- 主体区域
local body = Instance.new("Frame")
body.Size = UDim2.new(1, 0, 1, -36)
body.Position = UDim2.new(0, 0, 0, 36)
body.BackgroundTransparency = 1
body.Parent = menuPanel

-- 侧边栏
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 85, 1, 0)
sidebar.BackgroundColor3 = Theme.bgDark
sidebar.Parent = body
applyCorner(sidebar, 14)

local sbCut = Instance.new("Frame")
sbCut.Size = UDim2.new(0, 85, 0, 14)
sbCut.Position = UDim2.new(0, 0, 0, 0)
sbCut.BackgroundColor3 = Theme.bgDark
sbCut.BorderSizePixel = 0
sbCut.Parent = sidebar

-- 内容区
local contentScroll = Instance.new("ScrollingFrame")
contentScroll.Size = UDim2.new(1, -85, 1, 0)
contentScroll.Position = UDim2.new(0, 85, 0, 0)
contentScroll.BackgroundColor3 = Theme.bg
contentScroll.BorderSizePixel = 0
contentScroll.ScrollBarThickness = 0
contentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
contentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
contentScroll.Parent = body
applyCorner(contentScroll, 14)

local csPadding = Instance.new("UIPadding")
csPadding.PaddingTop = UDim.new(0, 10)
csPadding.PaddingBottom = UDim.new(0, 10)
csPadding.PaddingLeft = UDim.new(0, 10)
csPadding.PaddingRight = UDim.new(0, 10)
csPadding.Parent = contentScroll

local csLayout = Instance.new("UIListLayout")
csLayout.Padding = UDim.new(0, 8)
csLayout.Parent = contentScroll

-- ==================== 内容面板（只保留"主要"） ====================
local mainPanel = Instance.new("Frame")
mainPanel.Name = "main"
mainPanel.Size = UDim2.new(1, 0, 0, 0)
mainPanel.AutomaticSize = Enum.AutomaticSize.Y
mainPanel.BackgroundTransparency = 1
mainPanel.Visible = true
mainPanel.Parent = contentScroll

local mainLayout = Instance.new("UIListLayout")
mainLayout.Padding = UDim.new(0, 8)
mainLayout.Parent = mainPanel

-- ==================== 组件函数 ====================

local function createSwitchRow(parent, label, defaultOn, callback)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 40)
    card.BackgroundColor3 = Theme.bgCard
    card.Parent = parent
    applyCorner(card, 8)
    applyStroke(card, Theme.border, 1)

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -60, 1, 0)
    titleLbl.Position = UDim2.new(0, 10, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = label
    titleLbl.TextColor3 = Theme.text
    titleLbl.Font = Enum.Font.GothamMedium
    titleLbl.TextSize = 12
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = card

    local switchBg = Instance.new("Frame")
    switchBg.Size = UDim2.new(0, 36, 0, 20)
    switchBg.Position = UDim2.new(1, -46, 0.5, -10)
    switchBg.BackgroundColor3 = defaultOn and Theme.accent or Color3.fromRGB(51, 51, 51)
    switchBg.Parent = card
    applyCorner(switchBg, 10)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = defaultOn and UDim2.new(0, 19, 0, 3) or UDim2.new(0, 3, 0, 3)
    knob.BackgroundColor3 = defaultOn and Theme.bg or Theme.accent
    knob.Parent = switchBg
    applyCorner(knob, 7)

    local switchBtn = Instance.new("TextButton")
    switchBtn.Size = UDim2.new(1, 0, 1, 0)
    switchBtn.BackgroundTransparency = 1
    switchBtn.Text = ""
    switchBtn.Parent = switchBg

    local state = defaultOn
    switchBtn.MouseButton1Click:Connect(function()
        state = not state
        if state then
            switchBg.BackgroundColor3 = Theme.accent
            knob.BackgroundColor3 = Theme.bg
            knob.Position = UDim2.new(0, 19, 0, 3)
        else
            switchBg.BackgroundColor3 = Color3.fromRGB(51, 51, 51)
            knob.BackgroundColor3 = Theme.accent
            knob.Position = UDim2.new(0, 3, 0, 3)
        end
        if callback then callback(state) end
    end)
    return card
end

-- ==================== 主要面板内容 ====================
createSwitchRow(mainPanel, "自动重生", false, function(state)
    Config.autoRebirth = state
    print("[Xnpro] 自动重生:", state and "开启" or "关闭")
end)

createSwitchRow(mainPanel, "自动锻炼", false, function(state)
    Config.autoTrain = state
    print("[Xnpro] 自动锻炼:", state and "开启" or "关闭")
end)

createSwitchRow(mainPanel, "自动锻炼2", false, function(state)
    Config.autoTrain2 = state
    print("[Xnpro] 自动锻炼2:", state and "开启" or "关闭")
end)

createSwitchRow(mainPanel, "自动转盘", false, function(state)
    Config.autoSpin = state
    print("[Xnpro] 自动转盘:", state and "开启" or "关闭")
end)

-- ==================== 侧边栏菜单项（只保留"主要"） ====================
local menuCategories = {
    { name = "主要", target = "main" },
}

for i, cat in ipairs(menuCategories) do
    local item = Instance.new("TextButton")
    item.Name = cat.target
    item.Size = UDim2.new(1, 0, 0, 34)
    item.Position = UDim2.new(0, 0, 0, (i - 1) * 34 + 5)
    item.BackgroundTransparency = 1
    item.Text = cat.name
    item.TextColor3 = Theme.text
    item.Font = Enum.Font.Gotham
    item.TextSize = 11
    item.TextXAlignment = Enum.TextXAlignment.Left
    item.Parent = sidebar

    local itemPadding = Instance.new("UIPadding")
    itemPadding.PaddingLeft = UDim.new(0, 10)
    itemPadding.Parent = item
end

-- ==================== 交互 ====================
local isMoved = makeDraggable(island)

island.MouseButton1Click:Connect(function()
    if isMoved() then return end
    island.Visible = false
    menuPanel.Visible = true
end)

makeDraggable(menuPanel, topHeader)

minBtn.MouseButton1Click:Connect(function()
    menuPanel.Visible = false
    island.Visible = true
end)

closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- ==================== 启动 ====================
print("[Xnpro] 已加载 - 主要分类：自动重生 / 自动锻炼 / 自动锻炼2 / 自动转盘")