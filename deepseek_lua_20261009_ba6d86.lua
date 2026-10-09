-- [[ Xnpro 菜单复刻版 - Roblox 注入脚本（完整版） ]]
-- 直接在注入器中粘贴执行即可
-- 功能：悬浮岛 -> 点击展开菜单 -> 拖拽移动 -> 切换侧边栏 -> 右侧功能面板完整显示

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ==================== 全局样式 ====================
local Theme = {
    bg = Color3.fromRGB(0, 0, 0),
    bgDark = Color3.fromRGB(18, 18, 18),
    bgCard = Color3.fromRGB(30, 30, 30),
    bgLight = Color3.fromRGB(42, 42, 42),
    border = Color3.fromRGB(42, 42, 42),
    text = Color3.fromRGB(255, 255, 255),
    textMuted = Color3.fromRGB(136, 136, 136),
    textDim = Color3.fromRGB(170, 170, 170),
}

-- 清理旧实例
local oldGui = playerGui:FindFirstChild("XnproMenu")
if oldGui then oldGui:Destroy() end

-- ==================== 创建 ScreenGui ====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "XnproMenu"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

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

-- 拖拽函数
local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragInput, dragStart, startPos
    local moved = false

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            moved = false
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            if math.abs(delta.X) > 3 or math.abs(delta.Y) > 3 then
                moved = true
            end
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    return function() return moved end
end

-- 创建卡片（普通卡片）
local function createCard(parent, title, subtitle)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 44)
    card.BackgroundColor3 = Theme.bgCard
    card.Parent = parent
    applyCorner(card, 8)
    applyStroke(card, Theme.border, 1)

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -20, 0, 18)
    titleLbl.Position = UDim2.new(0, 10, 0, 6)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = title or ""
    titleLbl.TextColor3 = Theme.text
    titleLbl.Font = Enum.Font.GothamMedium
    titleLbl.TextSize = 12
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = card

    if subtitle then
        local subLbl = Instance.new("TextLabel")
        subLbl.Size = UDim2.new(1, -20, 0, 14)
        subLbl.Position = UDim2.new(0, 10, 0, 24)
        subLbl.BackgroundTransparency = 1
        subLbl.Text = subtitle
        subLbl.TextColor3 = Theme.textMuted
        subLbl.Font = Enum.Font.Gotham
        subLbl.TextSize = 10
        subLbl.TextXAlignment = Enum.TextXAlignment.Left
        subLbl.Parent = card
    end
    return card
end

-- 创建开关行
local function createSwitchRow(parent, label, defaultOn)
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

    -- 开关背景
    local switchBg = Instance.new("Frame")
    switchBg.Size = UDim2.new(0, 36, 0, 20)
    switchBg.Position = UDim2.new(1, -46, 0.5, -10)
    switchBg.BackgroundColor3 = defaultOn and Theme.accent or Color3.fromRGB(51, 51, 51)
    switchBg.Parent = card
    applyCorner(switchBg, 10)

    -- 滑块
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = defaultOn and UDim2.new(0, 19, 0, 3) or UDim2.new(0, 3, 0, 3)
    knob.BackgroundColor3 = defaultOn and Theme.bg or Theme.accent
    knob.Parent = switchBg
    applyCorner(knob, 7)

    -- 点击切换
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
    end)
    return card
end

-- 创建折叠面板
local function createCollapse(parent, title, contentHeight)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 40 + (contentHeight or 0))
    container.BackgroundTransparency = 1
    container.Parent = parent
    container.ClipsDescendants = true

    local header = Instance.new("TextButton")
    header.Size = UDim2.new(1, 0, 0, 40)
    header.BackgroundColor3 = Theme.bgCard
    header.Text = ""
    header.AutoButtonColor = false
    header.Parent = container
    applyCorner(header, 8)
    applyStroke(header, Theme.border, 1)

    local headerLbl = Instance.new("TextLabel")
    headerLbl.Size = UDim2.new(1, -40, 1, 0)
    headerLbl.Position = UDim2.new(0, 10, 0, 0)
    headerLbl.BackgroundTransparency = 1
    headerLbl.Text = title
    headerLbl.TextColor3 = Theme.text
    headerLbl.Font = Enum.Font.GothamMedium
    headerLbl.TextSize = 12
    headerLbl.TextXAlignment = Enum.TextXAlignment.Left
    headerLbl.Parent = header

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 20, 0, 20)
    arrow.Position = UDim2.new(1, -28, 0.5, -10)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▼"
    arrow.TextColor3 = Theme.textMuted
    arrow.Font = Enum.Font.Gotham
    arrow.TextSize = 10
    arrow.Parent = header

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, 0, 0, contentHeight or 0)
    content.Position = UDim2.new(0, 0, 0, 40)
    content.BackgroundTransparency = 1
    content.Parent = container

    -- 内容区布局
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.Parent = content
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 8)
    padding.PaddingLeft = UDim.new(0, 0)
    padding.PaddingRight = UDim.new(0, 0)
    padding.Parent = content

    local expanded = false
    local originalHeight = container.Size
    header.MouseButton1Click:Connect(function()
        expanded = not expanded
        if expanded then
            container.Size = UDim2.new(1, 0, 0, 40 + (contentHeight or 0))
            arrow.Text = "▲"
        else
            container.Size = UDim2.new(1, 0, 0, 40)
            arrow.Text = "▼"
        end
    end)
    return container, content
end

-- 创建输入框卡片
local function createInputCard(parent, label, placeholder, defaultValue)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 60)
    card.BackgroundColor3 = Theme.bgCard
    card.Parent = parent
    applyCorner(card, 8)
    applyStroke(card, Theme.border, 1)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -20, 0, 16)
    lbl.Position = UDim2.new(0, 10, 0, 6)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Theme.textDim
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = card

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -20, 0, 24)
    box.Position = UDim2.new(0, 10, 0, 26)
    box.BackgroundColor3 = Theme.bgLight
    box.Text = defaultValue or ""
    box.PlaceholderText = placeholder or ""
    box.TextColor3 = Theme.textDim
    box.Font = Enum.Font.Gotham
    box.TextSize = 11
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.ClearTextOnFocus = false
    box.Parent = card
    applyCorner(box, 6)
    applyStroke(box, Color3.fromRGB(58, 58, 58), 1)

    local boxPadding = Instance.new("UIPadding")
    boxPadding.PaddingLeft = UDim.new(0, 8)
    boxPadding.Parent = box
    return card
end

-- 创建下拉选择卡片
local function createSelectCard(parent, label, options)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 60)
    card.BackgroundColor3 = Theme.bgCard
    card.Parent = parent
    applyCorner(card, 8)
    applyStroke(card, Theme.border, 1)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -20, 0, 16)
    lbl.Position = UDim2.new(0, 10, 0, 6)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Theme.textDim
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = card

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 24)
    btn.Position = UDim2.new(0, 10, 0, 26)
    btn.BackgroundColor3 = Theme.bgLight
    btn.Text = options[1]
    btn.TextColor3 = Theme.textDim
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 11
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = card
    applyCorner(btn, 6)
    applyStroke(btn, Color3.fromRGB(58, 58, 58), 1)

    local btnPadding = Instance.new("UIPadding")
    btnPadding.PaddingLeft = UDim.new(0, 8)
    btnPadding.Parent = btn

    local currentIdx = 1
    btn.MouseButton1Click:Connect(function()
        currentIdx = currentIdx % #options + 1
        btn.Text = options[currentIdx]
    end)
    return card
end

-- 创建点击按钮卡片
local function createClickCard(parent, label, btnText)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 40)
    card.BackgroundColor3 = Theme.bgCard
    card.Parent = parent
    applyCorner(card, 8)
    applyStroke(card, Theme.border, 1)

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -90, 1, 0)
    titleLbl.Position = UDim2.new(0, 10, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = label
    titleLbl.TextColor3 = Theme.text
    titleLbl.Font = Enum.Font.GothamMedium
    titleLbl.TextSize = 12
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = card

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 70, 0, 24)
    btn.Position = UDim2.new(1, -78, 0.5, -12)
    btn.BackgroundColor3 = Theme.bgLight
    btn.Text = btnText or "点击"
    btn.TextColor3 = Theme.textDim
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 11
    btn.AutoButtonColor = false
    btn.Parent = card
    applyCorner(btn, 6)
    applyStroke(btn, Color3.fromRGB(58, 58, 58), 1)

    local original = btn.Text
    btn.MouseButton1Click:Connect(function()
        btn.Text = "✅ 已启用"
        task.wait(1)
        btn.Text = original
    end)
    return card
end

-- 创建进度条卡片
local function createSliderCard(parent, label, defaultValue)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 56)
    card.BackgroundColor3 = Theme.bgCard
    card.Parent = parent
    applyCorner(card, 8)
    applyStroke(card, Theme.border, 1)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -20, 0, 16)
    lbl.Position = UDim2.new(0, 10, 0, 6)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Theme.textDim
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = card

    -- 进度条背景
    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(1, -60, 0, 6)
    barBg.Position = UDim2.new(0, 10, 0, 30)
    barBg.BackgroundColor3 = Color3.fromRGB(51, 51, 51)
    barBg.Parent = card
    applyCorner(barBg, 3)

    -- 进度条填充
    local barFill = Instance.new("Frame")
    barFill.Size = UDim2.new(defaultValue / 100, 0, 1, 0)
    barFill.BackgroundColor3 = Theme.accent
    barFill.Parent = barBg
    applyCorner(barFill, 3)

    -- 数值
    local valueLbl = Instance.new("TextLabel")
    valueLbl.Size = UDim2.new(0, 40, 0, 16)
    valueLbl.Position = UDim2.new(1, -50, 0, 26)
    valueLbl.BackgroundTransparency = 1
    valueLbl.Text = tostring(defaultValue)
    valueLbl.TextColor3 = Theme.text
    valueLbl.Font = Enum.Font.GothamBold
    valueLbl.TextSize = 11
    valueLbl.Parent = card

    -- 拖拽逻辑
    local dragging = false
    local barBtn = Instance.new("TextButton")
    barBtn.Size = UDim2.new(1, 20, 1, 20)
    barBtn.Position = UDim2.new(0, -10, 0, -10)
    barBtn.BackgroundTransparency = 1
    barBtn.Text = ""
    barBtn.Parent = barBg

    barBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local mouseX = input.Position.X
            local barAbsPos = barBg.AbsolutePosition.X
            local barAbsSize = barBg.AbsoluteSize.X
            local percent = math.clamp((mouseX - barAbsPos) / barAbsSize, 0, 1)
            barFill.Size = UDim2.new(percent, 0, 1, 0)
            valueLbl.Text = tostring(math.floor(percent * 100))
        end
    end)
    return card
end

-- ==================== 构建菜单 ====================
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
local sbCorner = Instance.new("UICorner")
sbCorner.CornerRadius = UDim.new(0, 14)
sbCorner.Parent = sidebar
local sbCut = Instance.new("Frame")
sbCut.Size = UDim2.new(0, 85, 0, 14)
sbCut.Position = UDim2.new(0, 0, 0, 0)
sbCut.BackgroundColor3 = sidebar.BackgroundColor3
sbCut.BorderSizePixel = 0
sbCut.Parent = sidebar

-- 内容区（带滚动）
local contentScroll = Instance.new("ScrollingFrame")
contentScroll.Size = UDim2.new(1, -85, 1, 0)
contentScroll.Position = UDim2.new(0, 85, 0, 0)
contentScroll.BackgroundColor3 = Theme.bg
contentScroll.BorderSizePixel = 0
contentScroll.ScrollBarThickness = 0
contentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
contentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
contentScroll.Parent = body
local csCorner = Instance.new("UICorner")
csCorner.CornerRadius = UDim.new(0, 14)
csCorner.Parent = contentScroll

local csPadding = Instance.new("UIPadding")
csPadding.PaddingTop = UDim.new(0, 10)
csPadding.PaddingBottom = UDim.new(0, 10)
csPadding.PaddingLeft = UDim.new(0, 10)
csPadding.PaddingRight = UDim.new(0, 10)
csPadding.Parent = contentScroll

local csLayout = Instance.new("UIListLayout")
csLayout.Padding = UDim.new(0, 8)
csLayout.Parent = contentScroll

-- ==================== 内容面板容器 ====================
local panels = {}
local panelOrder = {"announcement", "kill", "boss", "pet", "advanced", "other"}

for _, name in ipairs(panelOrder) do
    local panel = Instance.new("Frame")
    panel.Name = name
    panel.Size = UDim2.new(1, 0, 0, 0)
    panel.AutomaticSize = Enum.AutomaticSize.Y
    panel.BackgroundTransparency = 1
    panel.Visible = (name == "announcement")
    panel.Parent = contentScroll

    local pLayout = Instance.new("UIListLayout")
    pLayout.Padding = UDim.new(0, 8)
    pLayout.Parent = panel

    panels[name] = panel
end

-- ==================== 公告面板 ====================
createCard(panels.announcement, "xnpro脚本给你最完美的体验", "目前版本: v1.0")

-- ==================== 击杀面板 ====================
createSwitchRow(panels.kill, "击杀全服", false)
createSwitchRow(panels.kill, "击杀全服+石头", false)

local killCollapse, killContent = createCollapse(panels.kill, "击杀个人", 120)
createInputCard(killContent, "黑名单（输入名字）", "输入要击杀的名字")
createInputCard(killContent, "白名单（输入名字）", "输入不击杀的名字")

-- ==================== 头目面板 ====================
createCard(panels.boss, "BOSS时间", "下一次BOSS刷新时间: 146:00")
createCard(panels.boss, "头目状态", "当前地图未检测到BOSS")

local bossCollapse, bossContent = createCollapse(panels.boss, "BOSS选项", 190)
createSwitchRow(bossContent, "击杀BOSS", false)
createSwitchRow(bossContent, "BOSS+重生", false)
createSliderCard(bossContent, "击杀高度", 50)

-- ==================== 宠物面板 ====================
local petCrystalCollapse, petCrystalContent = createCollapse(panels.pet, "抽奖水晶", 170)
createSelectCard(petCrystalContent, "选择水晶", {
    "沙滩水晶", "进阶水晶", "冰霜水晶", "神话水晶",
    "永恒水晶", "传奇水晶", "肌肉之王水晶", "过载水晶"
})
createSwitchRow(petCrystalContent, "自动抽奖", false)
createSwitchRow(petCrystalContent, "自动进化", false)

local petBuyCollapse, petBuyContent = createCollapse(panels.pet, "购买宠物", 220)
createSelectCard(petBuyContent, "选择宠物", {
    "暗星", "小金人", "霓虹守护者", "巅峰霸主", "碎片龙", "新星凤凰"
})
createSwitchRow(petBuyContent, "自动购买", false)
createSwitchRow(petBuyContent, "自动进化", false)
createClickCard(petBuyContent, "复制宠物", "点击")

-- ==================== 进阶面板 ====================
local advCollapse, advContent = createCollapse(panels.advanced, "进阶选项", 340)
createInputCard(advContent, "锻炼频率", "输入频率", "200")
createSwitchRow(advContent, "自动锻炼", false)
createSwitchRow(advContent, "自动重生", false)
createSwitchRow(advContent, "自动吃食", false)
createSwitchRow(advContent, "自动转盘", false)
createClickCard(advContent, "减少卡顿", "点击")
createClickCard(advContent, "快捷显示", "点击")

-- ==================== 其他面板 ====================
createSwitchRow(panels.other, "防AFK", true)
createSwitchRow(panels.other, "连点器设置", false)
createCard(panels.other, "传送地图", "广场 | 健身房 | 沙滩 | 传奇海滩")

-- ==================== 侧边栏菜单项 ====================
local menuCategories = {
    { name = "公告", target = "announcement" },
    { name = "击杀", target = "kill" },
    { name = "头目", target = "boss" },
    { name = "宠物", target = "pet" },
    { name = "进阶", target = "advanced" },
    { name = "其他", target = "other" },
}

local activeItem = nil
for i, cat in ipairs(menuCategories) do
    local item = Instance.new("TextButton")
    item.Name = cat.target
    item.Size = UDim2.new(1, 0, 0, 34)
    item.Position = UDim2.new(0, 0, 0, (i - 1) * 34 + 5)
    item.BackgroundTransparency = 1
    item.Text = cat.name
    item.TextColor3 = Theme.textMuted
    item.Font = Enum.Font.Gotham
    item.TextSize = 11
    item.TextXAlignment = Enum.TextXAlignment.Left
    item.Parent = sidebar

    local itemPadding = Instance.new("UIPadding")
    itemPadding.PaddingLeft = UDim.new(0, 10)
    itemPadding.Parent = item

    item.MouseEnter:Connect(function()
        item.TextColor3 = Theme.text
    end)
    item.MouseLeave:Connect(function()
        if activeItem ~= item then item.TextColor3 = Theme.textMuted end
    end)

    item.MouseButton1Click:Connect(function()
        for _, other in ipairs(sidebar:GetChildren()) do
            if other:IsA("TextButton") then
                other.TextColor3 = Theme.textMuted
            end
        end
        item.TextColor3 = Theme.text
        activeItem = item
        -- 切换面板
        for pName, pFrame in pairs(panels) do
            pFrame.Visible = (pName == cat.target)
        end
    end)

    if i == 1 then
        item.TextColor3 = Theme.text
        activeItem = item
    end
end

-- ==================== 交互逻辑 ====================
local isMoved = makeDraggable(island)

island.MouseButton1Click:Connect(function()
    if isMoved() then return end
    island.Visible = false
    menuPanel.Visible = true
end)

local menuMoved = makeDraggable(menuPanel, topHeader)
minBtn.MouseButton1Click:Connect(function()
    menuPanel.Visible = false
    island.Visible = true
end)

closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

print("[Xnpro] 完整菜单已加载")