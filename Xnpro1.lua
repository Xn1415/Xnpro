-- [[ Xnpro 力量传奇辅助脚本 - 完整功能版 ]]
-- 支持：击杀、头目、宠物、进阶、其他
-- 直接粘贴到注入器执行即可

-- ==================== 服务 ====================
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

-- ==================== 全局配置 ====================
local Config = {
    -- 击杀
    killAll = false,
    killAllStone = false,
    killPersonal = false,
    blacklist = {},
    whitelist = {},
    attackRange = 30,
    attackCooldown = 0.15,

    -- 头目
    autoKillBoss = false,
    bossRebirth = false,
    killHeight = 50,

    -- 宠物
    autoRollCrystal = false,
    crystalType = "沙滩水晶",
    autoEvolveCrystal = false,
    autoBuyPet = false,
    petType = "暗星",
    autoEvolvePet = false,

    -- 进阶
    trainFrequency = 200,
    autoTrain = false,
    autoRebirth = false,
    autoEat = false,
    autoSpin = false,
    reduceLag = false,
    quickDisplay = false,

    -- 其他
    antiAfk = true,
    autoClicker = false,
    teleportMap = "广场",
}

-- ==================== 主题 ====================
local Theme = {
    bg = Color3.fromRGB(0, 0, 0),
    bgDark = Color3.fromRGB(18, 18, 18),
    bgCard = Color3.fromRGB(30, 30, 30),
    bgLight = Color3.fromRGB(42, 42, 42),
    border = Color3.fromRGB(42, 42, 42),
    text = Color3.fromRGB(255, 255, 255),
    textMuted = Color3.fromRGB(136, 136, 136),
    textDim = Color3.fromRGB(170, 170, 170),
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

-- 拖拽
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

-- ==================== 核心：远程事件探测 ====================

-- 缓存所有常见的 Remote 名称
local RemoteCache = {}

-- 通用的 Remote 查找函数，支持关键词匹配
local function findRemote(keywords)
    local allRemotes = {}

    -- 收集 ReplicatedStorage 里所有 Remote
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            table.insert(allRemotes, obj)
        end
    end

    -- 收集玩家角色下的 Remote（某些游戏把工具 Remote 放这里）
    local char = player.Character
    if char then
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                table.insert(allRemotes, obj)
            end
        end
    end

    -- 收集 Backpack 下的 Remote
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, obj in ipairs(backpack:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                table.insert(allRemotes, obj)
            end
        end
    end

    -- 匹配关键词
    for _, remote in ipairs(allRemotes) do
        local name = remote.Name:lower()
        for _, keyword in ipairs(keywords) do
            if name:find(keyword) then
                return remote
            end
        end
    end

    return nil
end

-- 常用 Remote 缓存
local Remotes = {
    attack = nil,
    rebirth = nil,
    train = nil,
    rollCrystal = nil,
    buyPet = nil,
    evolvePet = nil,
    eat = nil,
    spin = nil,
}

-- 初始化 Remote 探测
local function initRemotes()
    Remotes.attack = findRemote({"attack", "kill", "hit", "damage", "punch", "combat", "swing"})
    Remotes.rebirth = findRemote({"rebirth", "reset", "ascend"})
    Remotes.train = findRemote({"train", "workout", "exercise", "lift", "rep"})
    Remotes.rollCrystal = findRemote({"roll", "crystal", "gacha", "spinCrystal", "summon"})
    Remotes.buyPet = findRemote({"buyPet", "petBuy", "purchasePet", "adopt"})
    Remotes.evolvePet = findRemote({"evolve", "evolvePet", "upgradePet"})
    Remotes.eat = findRemote({"eat", "consume", "food", "protein"})
    Remotes.spin = findRemote({"spin", "wheel", "dailySpin", "lucky"})

    print("[Xnpro] Remote 探测结果：")
    for name, remote in pairs(Remotes) do
        if remote then
            print("  " .. name .. " -> " .. remote:GetFullName())
        end
    end
end

-- 安全触发 Remote
local function fireRemote(remote, ...)
    if not remote then return false end
    local args = {...}
    local ok = pcall(function()
        if remote:IsA("RemoteFunction") then
            remote:InvokeServer(unpack(args))
        else
            remote:FireServer(unpack(args))
        end
    end)
    return ok
end

-- ==================== 自动击杀逻辑 ====================

local function isWhitelisted(name)
    for _, n in ipairs(Config.whitelist) do
        if n == name then return true end
    end
    return false
end

local function isBlacklisted(name)
    for _, n in ipairs(Config.blacklist) do
        if n == name then return true end
    end
    return false
end

local function getNearestPlayer()
    local character = player.Character
    if not character then return nil end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end

    local nearest, shortestDist = nil, Config.attackRange
    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= player and other.Character then
            local otherRoot = other.Character:FindFirstChild("HumanoidRootPart")
            local otherHumanoid = other.Character:FindFirstChild("Humanoid")
            if otherRoot and otherHumanoid and otherHumanoid.Health > 0 then
                if not isWhitelisted(other.Name) then
                    local dist = (otherRoot.Position - rootPart.Position).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        nearest = otherRoot
                    end
                end
            end
        end
    end
    return nearest
end

local function getNearestStone()
    local character = player.Character
    if not character then return nil end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end

    local nearest, shortestDist = nil, Config.attackRange
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local name = obj.Name:lower()
            if name:find("stone") or name:find("rock") or name:find("crystal")
            or name:find("ore") or name:find("gem") then
                local dist = (obj.Position - rootPart.Position).Magnitude
                if dist < shortestDist then
                    shortestDist = dist
                    nearest = obj
                end
            end
        end
    end
    return nearest
end

local function attackTarget(target)
    if not target then return end
    local ok = fireRemote(Remotes.attack, target)
    if not ok then
        -- 回退：模拟点击
        local screenPoint, onScreen = camera:WorldToViewportPoint(target.Position)
        if onScreen then
            VirtualInputManager:SendMouseButtonEvent(screenPoint.X, screenPoint.Y, 0, true, game, 0)
            VirtualInputManager:SendMouseButtonEvent(screenPoint.X, screenPoint.Y, 0, false, game, 0)
        end
    end
end

-- ==================== 头目逻辑 ====================

local function findBoss()
    local character = player.Character
    if not character then return nil end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end

    local nearest, shortestDist = nil, 100
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local name = obj.Name:lower()
            if name:find("boss") or name:find("titan") or name:find("giant") then
                local humanoid = obj:FindFirstChildOfClass("Humanoid")
                local objRoot = obj:FindFirstChild("HumanoidRootPart")
                if humanoid and objRoot and humanoid.Health > 0 then
                    local dist = (objRoot.Position - rootPart.Position).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        nearest = objRoot
                    end
                end
            end
        end
    end
    return nearest
end

local function doRebirth()
    if Remotes.rebirth then
        fireRemote(Remotes.rebirth)
    else
        -- 回退：找重生按钮点击
        local gui = playerGui:FindFirstChild("RebirthGui") or playerGui:FindFirstChild("Rebirth")
        if gui then
            for _, btn in ipairs(gui:GetDescendants()) do
                if btn:IsA("TextButton") and btn.Text:lower():find("rebirth") then
                    firetouchinterest(btn, game.Players.LocalPlayer.Character.HumanoidRootPart, 0)
                    firetouchinterest(btn, game.Players.LocalPlayer.Character.HumanoidRootPart, 1)
                end
            end
        end
    end
end

-- ==================== 宠物逻辑 ====================

local crystalMap = {
    ["沙滩水晶"] = "BeachCrystal",
    ["进阶水晶"] = "AdvancedCrystal",
    ["冰霜水晶"] = "FrostCrystal",
    ["神话水晶"] = "MythicCrystal",
    ["永恒水晶"] = "EternalCrystal",
    ["传奇水晶"] = "LegendaryCrystal",
    ["肌肉之王水晶"] = "MuscleKingCrystal",
    ["过载水晶"] = "OverloadCrystal",
}

local function doRollCrystal()
    local target = crystalMap[Config.crystalType] or Config.crystalType
    fireRemote(Remotes.rollCrystal, target)
end

local petMap = {
    ["暗星"] = "DarkStar",
    ["小金人"] = "GoldenMan",
    ["霓虹守护者"] = "NeonGuardian",
    ["巅峰霸主"] = "PeakOverlord",
    ["碎片龙"] = "ShardDragon",
    ["新星凤凰"] = "NovaPhoenix",
}

local function doBuyPet()
    local target = petMap[Config.petType] or Config.petType
    fireRemote(Remotes.buyPet, target)
end

local function doEvolvePet()
    fireRemote(Remotes.evolvePet)
end

-- ==================== 进阶逻辑 ====================

local function doTrain()
    if Remotes.train then
        fireRemote(Remotes.train)
    else
        -- 回退：模拟按键
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end
end

local function doEat()
    fireRemote(Remotes.eat)
end

local function doSpin()
    fireRemote(Remotes.spin)
end

-- 减少卡顿：隐藏不必要的粒子
local function applyReduceLag()
    if Config.reduceLag then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") then
                obj.Enabled = false
            end
        end
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    else
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level10
    end
end

-- 快捷显示：显示 FPS、Ping
local quickDisplayGui = nil
local function toggleQuickDisplay()
    if Config.quickDisplay then
        if not quickDisplayGui then
            quickDisplayGui = Instance.new("ScreenGui")
            quickDisplayGui.Name = "XnproQuickDisplay"
            quickDisplayGui.ResetOnSpawn = false
            quickDisplayGui.Parent = playerGui

            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(0, 150, 0, 60)
            frame.Position = UDim2.new(1, -160, 0, 100)
            frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            frame.BackgroundTransparency = 0.5
            frame.Parent = quickDisplayGui
            applyCorner(frame, 8)

            local fpsLabel = Instance.new("TextLabel")
            fpsLabel.Size = UDim2.new(1, -10, 0, 25)
            fpsLabel.Position = UDim2.new(0, 5, 0, 5)
            fpsLabel.BackgroundTransparency = 1
            fpsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            fpsLabel.TextXAlignment = Enum.TextXAlignment.Left
            fpsLabel.Font = Enum.Font.Gotham
            fpsLabel.TextSize = 12
            fpsLabel.Text = "FPS: --"
            fpsLabel.Parent = frame

            local pingLabel = Instance.new("TextLabel")
            pingLabel.Size = UDim2.new(1, -10, 0, 25)
            pingLabel.Position = UDim2.new(0, 5, 0, 30)
            pingLabel.BackgroundTransparency = 1
            pingLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            pingLabel.TextXAlignment = Enum.TextXAlignment.Left
            pingLabel.Font = Enum.Font.Gotham
            pingLabel.TextSize = 12
            pingLabel.Text = "Ping: --"
            pingLabel.Parent = frame

            task.spawn(function()
                while quickDisplayGui and quickDisplayGui.Parent do
                    local fps = math.floor(1 / RunService.RenderStepped:Wait())
                    local ping = player:GetNetworkPing() * 1000
                    fpsLabel.Text = "FPS: " .. fps
                    pingLabel.Text = "Ping: " .. math.floor(ping) .. " ms"
                end
            end)
        end
        quickDisplayGui.Enabled = true
    else
        if quickDisplayGui then
            quickDisplayGui.Enabled = false
        end
    end
end

-- ==================== 其他逻辑 ====================

-- 防 AFK
task.spawn(function()
    while task.wait(60) do
        if Config.antiAfk then
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.wait(0.1)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        end
    end
end)

-- 连点器
task.spawn(function()
    while task.wait(0.05) do
        if Config.autoClicker then
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        end
    end
end)

-- 传送地图
local mapPositions = {
    ["广场"] = Vector3.new(0, 50, 0),
    ["健身房"] = Vector3.new(100, 50, 100),
    ["沙滩"] = Vector3.new(200, 50, 0),
    ["传奇海滩"] = Vector3.new(300, 50, 300),
}

local function teleportTo(mapName)
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local pos = mapPositions[mapName]
    if pos then
        root.CFrame = CFrame.new(pos)
    end
end

-- ==================== 主循环 ====================

-- 击杀循环
task.spawn(function()
    while task.wait(Config.attackCooldown) do
        if Config.killAll then
            local target = getNearestPlayer()
            if target then attackTarget(target) end
        end

        if Config.killAllStone then
            local target = getNearestPlayer()
            if target then
                attackTarget(target)
            else
                local stone = getNearestStone()
                if stone then attackTarget(stone) end
            end
        end

        if Config.killPersonal then
            local character = player.Character
            if character then
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    for _, other in ipairs(Players:GetPlayers()) do
                        if other ~= player and other.Character and isBlacklisted(other.Name) then
                            local otherRoot = other.Character:FindFirstChild("HumanoidRootPart")
                            local otherHumanoid = other.Character:FindFirstChild("Humanoid")
                            if otherRoot and otherHumanoid and otherHumanoid.Health > 0 then
                                local dist = (otherRoot.Position - rootPart.Position).Magnitude
                                if dist <= Config.attackRange then
                                    attackTarget(otherRoot)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- 头目循环
task.spawn(function()
    while task.wait(0.5) do
        if Config.autoKillBoss then
            local boss = findBoss()
            if boss then attackTarget(boss) end
        end

        if Config.bossRebirth then
            doRebirth()
        end
    end
end)

-- 宠物循环
task.spawn(function()
    while task.wait(1) do
        if Config.autoRollCrystal then
            doRollCrystal()
        end
        if Config.autoEvolveCrystal then
            doEvolvePet()
        end
        if Config.autoBuyPet then
            doBuyPet()
        end
        if Config.autoEvolvePet then
            doEvolvePet()
        end
    end
end)

-- 进阶循环
task.spawn(function()
    while task.wait(Config.trainFrequency / 100) do
        if Config.autoTrain then doTrain() end
    end
end)

task.spawn(function()
    while task.wait(1) do
        if Config.autoRebirth then doRebirth() end
        if Config.autoEat then doEat() end
        if Config.autoSpin then doSpin() end
    end
end)

-- ==================== 创建 UI ====================

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

-- ==================== UI 组件 ====================

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

local function createCollapse(parent, title, contentHeight)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 40)
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

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.Parent = content
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 8)
    padding.Parent = content

    local expanded = false
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

local function createInputCard(parent, label, placeholder, defaultValue, callback)
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

    if callback then
        box.FocusLost:Connect(function()
            callback(box.Text)
        end)
    end
    return card
end

local function createSelectCard(parent, label, options, callback)
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
        if callback then callback(options[currentIdx]) end
    end)
    return card
end

local function createClickCard(parent, label, btnText, callback)
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
        if callback then callback() end
        btn.Text = "✅ 已执行"
        task.wait(1)
        btn.Text = original
    end)
    return card
end

local function createSliderCard(parent, label, defaultValue, callback)
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

    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(1, -60, 0, 6)
    barBg.Position = UDim2.new(0, 10, 0, 30)
    barBg.BackgroundColor3 = Color3.fromRGB(51, 51, 51)
    barBg.Parent = card
    applyCorner(barBg, 3)

    local barFill = Instance.new("Frame")
    barFill.Size = UDim2.new(defaultValue / 100, 0, 1, 0)
    barFill.BackgroundColor3 = Theme.accent
    barFill.Parent = barBg
    applyCorner(barFill, 3)

    local valueLbl = Instance.new("TextLabel")
    valueLbl.Size = UDim2.new(0, 40, 0, 16)
    valueLbl.Position = UDim2.new(1, -50, 0, 26)
    valueLbl.BackgroundTransparency = 1
    valueLbl.Text = tostring(defaultValue)
    valueLbl.TextColor3 = Theme.text
    valueLbl.Font = Enum.Font.GothamBold
    valueLbl.TextSize = 11
    valueLbl.Parent = card

    local dragging = false
    local barBtn = Instance.new("TextButton")
    barBtn.Size = UDim2.new(1, 20, 1, 20)
    barBtn.Position = UDim2.new(0, -10, 0, -10)
    barBtn.BackgroundTransparency = 1
    barBtn.Text = ""
    barBtn.Parent = barBg

    barBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local mouseX = input.Position.X
            local barAbsPos = barBg.AbsolutePosition.X
            local barAbsSize = barBg.AbsoluteSize.X
            local percent = math.clamp((mouseX - barAbsPos) / barAbsSize, 0, 1)
            barFill.Size = UDim2.new(percent, 0, 1, 0)
            valueLbl.Text = tostring(math.floor(percent * 100))
            if callback then callback(math.floor(percent * 100)) end
        end
    end)
    return card
end

-- ==================== 公告面板 ====================
createCard(panels.announcement, "xnpro脚本给你最完美的体验", "目前版本: v1.0")

-- ==================== 击杀面板 ====================
createSwitchRow(panels.kill, "击杀全服", false, function(state)
    Config.killAll = state
end)
createSwitchRow(panels.kill, "击杀全服+石头", false, function(state)
    Config.killAllStone = state
end)

local killCollapse, killContent = createCollapse(panels.kill, "击杀个人", 190)
createSwitchRow(killContent, "启用击杀个人", false, function(state)
    Config.killPersonal = state
end)
createInputCard(killContent, "黑名单（逗号分隔）", "输入要击杀的名字", "", function(text)
    Config.blacklist = {}
    for name in string.gmatch(text, "[^,，]+") do
        local trimmed = name:match("^%s*(.-)%s*$")
        if trimmed ~= "" then
            table.insert(Config.blacklist, trimmed)
        end
    end
end)
createInputCard(killContent, "白名单（逗号分隔）", "输入不击杀的名字", "", function(text)
    Config.whitelist = {}
    for name in string.gmatch(text, "[^,，]+") do
        local trimmed = name:match("^%s*(.-)%s*$")
        if trimmed ~= "" then
            table.insert(Config.whitelist, trimmed)
        end
    end
end)

-- ==================== 头目面板 ====================
createCard(panels.boss, "BOSS时间", "下一次BOSS刷新时间: 146:00")
createCard(panels.boss, "头目状态", "当前地图未检测到BOSS")

local bossCollapse, bossContent = createCollapse(panels.boss, "BOSS选项", 190)
createSwitchRow(bossContent, "击杀BOSS", false, function(state)
    Config.autoKillBoss = state
end)
createSwitchRow(bossContent, "BOSS+重生", false, function(state)
    Config.bossRebirth = state
end)
createSliderCard(bossContent, "击杀高度", 50, function(value)
    Config.killHeight = value
end)

-- ==================== 宠物面板 ====================
local petCrystalCollapse, petCrystalContent = createCollapse(panels.pet, "抽奖水晶", 180)
createSelectCard(petCrystalContent, "选择水晶", {
    "沙滩水晶", "进阶水晶", "冰霜水晶", "神话水晶",
    "永恒水晶", "传奇水晶", "肌肉之王水晶", "过载水晶"
}, function(value)
    Config.crystalType = value
end)
createSwitchRow(petCrystalContent, "自动抽奖", false, function(state)
    Config.autoRollCrystal = state
end)
createSwitchRow(petCrystalContent, "自动进化", false, function(state)
    Config.autoEvolveCrystal = state
end)

local petBuyCollapse, petBuyContent = createCollapse(panels.pet, "购买宠物", 220)
createSelectCard(petBuyContent, "选择宠物", {
    "暗星", "小金人", "霓虹守护者", "巅峰霸主", "碎片龙", "新星凤凰"
}, function(value)
    Config.petType = value
end)
createSwitchRow(petBuyContent, "自动购买", false, function(state)
    Config.autoBuyPet = state
end)
createSwitchRow(petBuyContent, "自动进化", false, function(state)
    Config.autoEvolvePet = state
end)
createClickCard(petBuyContent, "复制宠物", "点击", function()
    -- 尝试直接复制当前装备的宠物
    local char = player.Character
    if char then
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") and tool.Name:lower():find("pet") then
                fireRemote(Remotes.buyPet, tool.Name)
            end
        end
    end
end)

-- ==================== 进阶面板 ====================
local advCollapse, advContent = createCollapse(panels.advanced, "进阶选项", 340)
createInputCard(advContent, "锻炼频率", "输入频率", "200", function(text)
    local num = tonumber(text)
    if num then Config.trainFrequency = num end
end)
createSwitchRow(advContent, "自动锻炼", false, function(state)
    Config.autoTrain = state
end)
createSwitchRow(advContent, "自动重生", false, function(state)
    Config.autoRebirth = state
end)
createSwitchRow(advContent, "自动吃食", false, function(state)
    Config.autoEat = state
end)
createSwitchRow(advContent, "自动转盘", false, function(state)
    Config.autoSpin = state
end)
createClickCard(advContent, "减少卡顿", "点击", function()
    Config.reduceLag = not Config.reduceLag
    applyReduceLag()
end)
createClickCard(advContent, "快捷显示", "点击", function()
    Config.quickDisplay = not Config.quickDisplay
    toggleQuickDisplay()
end)

-- ==================== 其他面板 ====================
createSwitchRow(panels.other, "防AFK", true, function(state)
    Config.antiAfk = state
end)
createSwitchRow(panels.other, "连点器设置", false, function(state)
    Config.autoClicker = state
end)
createSelectCard(panels.other, "传送地图", {
    "广场", "健身房", "沙滩", "传奇海滩"
}, function(value)
    teleportTo(value)
end)

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
        for pName, pFrame in pairs(panels) do
            pFrame.Visible = (pName == cat.target)
        end
    end)

    if i == 1 then
        item.TextColor3 = Theme.text
        activeItem = item
    end
end

-- ==================== 交互 ====================
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

-- ==================== 启动 ====================
initRemotes()
print("[Xnpro] 力量传奇完整功能版已加载")
print("[Xnpro] 按需开启各面板开关即可生效")