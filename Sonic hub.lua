-- Sonic Hub · V18 (Loading Screen 2D Épica + UI Fixes)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Stats = game:GetService("Stats")
local GuiService = game:GetService("GuiService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Config = {
    MenuKey = Enum.KeyCode.RightShift,
    MaxBoxPixels = 800,
    WinW = 700, WinH = 540, TitleH = 48, FooterH = 16,
}

if shared.AFG_Cleanup then pcall(shared.AFG_Cleanup) end
for _, n in ipairs({"SonicHub", "SonicHubOverlay", "SonicHubLoading"}) do
    local o = PlayerGui:FindFirstChild(n); if o then o:Destroy() end
    local c = CoreGui:FindFirstChild(n); if c then c:Destroy() end
end

local connections = {}
local function connect(sig, fn) local c = sig:Connect(fn); table.insert(connections, c); return c end

local preferences = {}
local uiRenderers = {} 
local activeSlider = nil

local function setPref(k, v) preferences[k] = v end
local function pref(k, d) local v = preferences[k]; if v == nil then return d end; return v end
local function prefNum(k, d) local v = tonumber(pref(k, d)); if not v or v ~= v then return d end; return v end

local guiInset = Vector2.new(0, 36)
pcall(function()
    local inset = GuiService:GetGuiInset()
    if typeof(inset) == "Vector2" then guiInset = inset elseif type(inset) == "table" and typeof(inset[1]) == "Vector2" then guiInset = inset[1] end
end)
local function viewportMouse()
    local m = UserInputService:GetMouseLocation()
    return Vector2.new(m.X, m.Y) - guiInset
end

local function formatBind(val)
    if not val or val == "None" then return "NONE" end
    if val == "MouseButton1" then return "MB1" end
    if val == "MouseButton2" then return "MB2" end
    if val == "MouseButton3" then return "MB3" end
    return val:upper()
end

-- ============================================================
-- PALETA SONIC
-- ============================================================
local P = {
    bg        = Color3.fromRGB(12, 16, 28),
    title     = Color3.fromRGB(0, 110, 220),
    panel     = Color3.fromRGB(20, 30, 55),
    panelDark = Color3.fromRGB(15, 22, 40),
    card      = Color3.fromRGB(28, 45, 80),
    cardHead  = Color3.fromRGB(38, 65, 115),
    ink       = Color3.fromRGB(15, 15, 20),
    text      = Color3.fromRGB(240, 248, 255),
    sub       = Color3.fromRGB(150, 180, 220),
    red       = Color3.fromRGB(230, 50, 60),
    yellow    = Color3.fromRGB(255, 200, 0),
    green     = Color3.fromRGB(40, 200, 100),
    blue      = Color3.fromRGB(0, 140, 255),
    white     = Color3.fromRGB(255, 255, 255),
    track     = Color3.fromRGB(45, 65, 100),
    brick     = Color3.fromRGB(10, 15, 25),
}

local function new(cls, props, parent)
    local i = Instance.new(cls)
    for k, v in pairs(props) do i[k] = v end
    if parent then i.Parent = parent end
    return i
end
local function corner(i, r) return new("UICorner", {CornerRadius = UDim.new(0, r)}, i) end
local function outline(i, t, c) return new("UIStroke", {Color = c or P.text, Thickness = t or 2}, i) end
local function label(parent, props)
    props.BackgroundTransparency = 1
    props.Font = props.Font or Enum.Font.GothamBold
    props.TextColor3 = props.TextColor3 or P.text
    props.TextSize = props.TextSize or 13
    props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
    return new("TextLabel", props, parent)
end
local TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local function tween(inst, props) TweenService:Create(inst, TWEEN_INFO, props):Play() end

-- ============================================================
-- TELA DE LOADING (Arte 2D Sonic, Tails e Knuckles)
-- ============================================================
local LoadingGui = new("ScreenGui", {Name = "SonicHubLoading", ResetOnSpawn = false, DisplayOrder = 999, IgnoreGuiInset = true}, PlayerGui)
local LoadFrame = new("Frame", {Size = UDim2.fromOffset(500, 250), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(30, 60, 130), BorderSizePixel = 0, ClipsDescendants = true}, LoadingGui)
corner(LoadFrame, 12); outline(LoadFrame, 4, P.yellow)

-- Céu (Gradiente)
local skyGrad = new("UIGradient", {Color = ColorSequence.new(Color3.fromRGB(80, 160, 255), Color3.fromRGB(200, 230, 255))}, LoadFrame)
skyGrad.Rotation = 90

-- Nuvens
for i = 1, 4 do
    local cloud = new("Frame", {Size = UDim2.fromOffset(60, 20), Position = UDim2.fromOffset(i * 120 - 40, 20 + math.random(10, 30)), BackgroundColor3 = P.white, BackgroundTransparency = 0.3, BorderSizePixel = 0}, LoadFrame)
    corner(cloud, 10)
    new("Frame", {Size = UDim2.fromOffset(40, 20), Position = UDim2.fromOffset(10, -10), BackgroundColor3 = P.white, BackgroundTransparency = 0.3, BorderSizePixel = 0}, cloud); corner(cloud:GetChildren()[1], 10)
end

-- Chão de Grama
local grassTop = new("Frame", {Size = UDim2.new(1, 0, 0, 12), Position = UDim2.new(0, 0, 1, -80), BackgroundColor3 = Color3.fromRGB(90, 220, 80), BorderSizePixel = 0}, LoadFrame)
local grassDirt = new("Frame", {Size = UDim2.new(1, 0, 0, 68), Position = UDim2.new(0, 0, 1, -68), BackgroundColor3 = Color3.fromRGB(160, 100, 60), BorderSizePixel = 0}, LoadFrame)
for i = 1, 15 do
    new("Frame", {Size = UDim2.fromOffset(10, 6), Position = UDim2.fromOffset(i * 35, -4), BackgroundColor3 = Color3.fromRGB(70, 190, 60), BorderSizePixel = 0, Rotation = -15}, grassTop)
end

-- Animais
local runOffset = 0
local isRunning = true
local timeTracker = 0

-- Função para desenhar o Sonic
local sonicHolder = new("Frame", {Size = UDim2.fromOffset(60, 80), Position = UDim2.new(0.3, 0, 1, -140), BackgroundTransparency = 1}, LoadFrame)
-- Rastro Azul
local trail = new("Frame", {Size = UDim2.fromOffset(100, 30), Position = UDim2.fromOffset(-80, 30), BackgroundColor3 = P.blue, BackgroundTransparency = 0.5, BorderSizePixel = 0}, sonicHolder); corner(trail, 15)
local trailGrad = new("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.5)})}, trail)
-- Corpo
local sBody = new("Frame", {Size = UDim2.fromOffset(26, 30), Position = UDim2.fromOffset(17, 30), BackgroundColor3 = P.blue, BorderSizePixel = 0}, sonicHolder); corner(sBody, 13)
local sBelly = new("Frame", {Size = UDim2.fromOffset(16, 18), Position = UDim2.fromOffset(5, 12), BackgroundColor3 = Color3.fromRGB(255, 205, 160), BorderSizePixel = 0}, sBody); corner(sBelly, 8)
-- Cabeça
local sHead = new("Frame", {Size = UDim2.fromOffset(36, 34), Position = UDim2.fromOffset(12, 5), BackgroundColor3 = P.blue, BorderSizePixel = 0}, sonicHolder); corner(sHead, 17)
-- Espinhos
new("Frame", {Size = UDim2.fromOffset(20, 10), Position = UDim2.fromOffset(-15, 10), BackgroundColor3 = P.blue, BorderSizePixel = 0, Rotation = 20}, sHead); corner(sHead:GetChildren()[1], 5)
new("Frame", {Size = UDim2.fromOffset(18, 10), Position = UDim2.fromOffset(-12, 20), BackgroundColor3 = P.blue, BorderSizePixel = 0, Rotation = -10}, sHead); corner(sHead:GetChildren()[2], 5)
-- Olhos e Focinho
local sEye = new("Frame", {Size = UDim2.fromOffset(10, 14), Position = UDim2.fromOffset(22, 8), BackgroundColor3 = P.white, BorderSizePixel = 0}, sHead); corner(sEye, 5)
new("Frame", {Size = UDim2.fromOffset(4, 6), Position = UDim2.fromOffset(4, 4), BackgroundColor3 = P.ink, BorderSizePixel = 0}, sEye); corner(sEye:GetChildren()[1], 2)
local sMuzzle = new("Frame", {Size = UDim2.fromOffset(18, 12), Position = UDim2.fromOffset(22, 18), BackgroundColor3 = Color3.fromRGB(255, 205, 160), BorderSizePixel = 0}, sHead); corner(sMuzzle, 6)
new("Frame", {Size = UDim2.fromOffset(6, 4), Position = UDim2.fromOffset(10, 2), BackgroundColor3 = P.ink, BorderSizePixel = 0}, sMuzzle); corner(sMuzzle:GetChildren()[1], 2)
-- Braço e Luva
new("Frame", {Size = UDim2.fromOffset(8, 16), Position = UDim2.fromOffset(12, 45), BackgroundColor3 = Color3.fromRGB(255, 205, 160), BorderSizePixel = 0}, sonicHolder); corner(sonicHolder:GetChildren()[6], 4)
local sGlove = new("Frame", {Size = UDim2.fromOffset(12, 12), Position = UDim2.fromOffset(8, 55), BackgroundColor3 = P.white, BorderSizePixel = 0}, sonicHolder); corner(sGlove, 6)
-- Pernas e Sapatos
local sLeg1 = new("Frame", {Size = UDim2.fromOffset(8, 18), Position = UDim2.fromOffset(22, 58), BackgroundColor3 = P.blue, BorderSizePixel = 0}, sonicHolder); corner(sLeg1, 4)
local sShoe1 = new("Frame", {Size = UDim2.fromOffset(18, 10), Position = UDim2.fromOffset(16, 74), BackgroundColor3 = P.red, BorderSizePixel = 0}, sonicHolder); corner(sShoe1, 5)
new("Frame", {Size = UDim2.fromOffset(18, 3), Position = UDim2.fromOffset(0, 3), BackgroundColor3 = P.white, BorderSizePixel = 0}, sShoe1)
local sLeg2 = new("Frame", {Size = UDim2.fromOffset(8, 18), Position = UDim2.fromOffset(34, 58), BackgroundColor3 = P.blue, BorderSizePixel = 0}, sonicHolder); corner(sLeg2, 4)
local sShoe2 = new("Frame", {Size = UDim2.fromOffset(18, 10), Position = UDim2.fromOffset(30, 74), BackgroundColor3 = P.red, BorderSizePixel = 0}, sonicHolder); corner(sShoe2, 5)
new("Frame", {Size = UDim2.fromOffset(18, 3), Position = UDim2.fromOffset(0, 3), BackgroundColor3 = P.white, BorderSizePixel = 0}, sShoe2)


-- Função para desenhar o Tails
local tailsHolder = new("Frame", {Size = UDim2.fromOffset(50, 70), Position = UDim2.new(0.5, 0, 1, -180), BackgroundTransparency = 1}, LoadFrame)
-- Rabos (Girando)
local tailBase = new("Frame", {Size = UDim2.fromOffset(20, 20), Position = UDim2.fromOffset(0, 30), BackgroundTransparency = 1}, tailsHolder)
local t1 = new("Frame", {Size = UDim2.fromOffset(24, 12), Position = UDim2.fromOffset(-18, 4), BackgroundColor3 = Color3.fromRGB(255, 140, 0), BorderSizePixel = 0, Rotation = 30}, tailBase); corner(t1, 6)
new("Frame", {Size = UDim2.fromOffset(10, 8), Position = UDim2.fromOffset(14, 2), BackgroundColor3 = P.white, BorderSizePixel = 0}, t1); corner(t1:GetChildren()[1], 4)
local t2 = new("Frame", {Size = UDim2.fromOffset(24, 12), Position = UDim2.fromOffset(-18, 4), BackgroundColor3 = Color3.fromRGB(255, 140, 0), BorderSizePixel = 0, Rotation = -30}, tailBase); corner(t2, 6)
new("Frame", {Size = UDim2.fromOffset(10, 8), Position = UDim2.fromOffset(14, 2), BackgroundColor3 = P.white, BorderSizePixel = 0}, t2); corner(t2:GetChildren()[1], 4)
-- Corpo
local tBody = new("Frame", {Size = UDim2.fromOffset(22, 26), Position = UDim2.fromOffset(18, 28), BackgroundColor3 = Color3.fromRGB(255, 140, 0), BorderSizePixel = 0}, tailsHolder); corner(tBody, 11)
new("Frame", {Size = UDim2.fromOffset(14, 16), Position = UDim2.fromOffset(4, 8), BackgroundColor3 = P.white, BorderSizePixel = 0}, tBody); corner(tBody:GetChildren()[1], 7)
-- Cabeça
local tHead = new("Frame", {Size = UDim2.fromOffset(32, 30), Position = UDim2.fromOffset(12, 5), BackgroundColor3 = Color3.fromRGB(255, 140, 0), BorderSizePixel = 0}, tailsHolder); corner(tHead, 15)
new("Frame", {Size = UDim2.fromOffset(14, 10), Position = UDim2.fromOffset(-10, 0), BackgroundColor3 = Color3.fromRGB(255, 140, 0), BorderSizePixel = 0, Rotation = -30}, tHead); corner(tHead:GetChildren()[1], 5)
new("Frame", {Size = UDim2.fromOffset(12, 10), Position = UDim2.fromOffset(-8, 14), BackgroundColor3 = Color3.fromRGB(255, 140, 0), BorderSizePixel = 0, Rotation = 30}, tHead); corner(tHead:GetChildren()[2], 5)
local tEye = new("Frame", {Size = UDim2.fromOffset(8, 12), Position = UDim2.fromOffset(16, 8), BackgroundColor3 = P.white, BorderSizePixel = 0}, tHead); corner(tEye, 4)
new("Frame", {Size = UDim2.fromOffset(4, 5), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = P.ink, BorderSizePixel = 0}, tEye); corner(tEye:GetChildren()[1], 2)
local tMuzzle = new("Frame", {Size = UDim2.fromOffset(16, 10), Position = UDim2.fromOffset(16, 16), BackgroundColor3 = P.white, BorderSizePixel = 0}, tHead); corner(tMuzzle, 5)
new("Frame", {Size = UDim2.fromOffset(4, 4), Position = UDim2.fromOffset(10, 2), BackgroundColor3 = P.ink, BorderSizePixel = 0}, tMuzzle); corner(tMuzzle:GetChildren()[1], 2)
-- Luvas e Sapatos
new("Frame", {Size = UDim2.fromOffset(10, 10), Position = UDim2.fromOffset(10, 38), BackgroundColor3 = P.white, BorderSizePixel = 0}, tailsHolder); corner(tailsHolder:GetChildren()[8], 5)
new("Frame", {Size = UDim2.fromOffset(10, 10), Position = UDim2.fromOffset(38, 38), BackgroundColor3 = P.white, BorderSizePixel = 0}, tailsHolder); corner(tailsHolder:GetChildren()[9], 5)
local tShoe = new("Frame", {Size = UDim2.fromOffset(14, 8), Position = UDim2.fromOffset(18, 62), BackgroundColor3 = P.red, BorderSizePixel = 0}, tailsHolder); corner(tShoe, 4)
new("Frame", {Size = UDim2.fromOffset(14, 3), Position = UDim2.fromOffset(0, 2), BackgroundColor3 = P.white, BorderSizePixel = 0}, tShoe)


-- Função para desenhar o Knuckles
local knuxHolder = new("Frame", {Size = UDim2.fromOffset(60, 80), Position = UDim2.new(0.7, 0, 1, -140), BackgroundTransparency = 1}, LoadFrame)
-- Espinhos (Dreads)
new("Frame", {Size = UDim2.fromOffset(12, 30), Position = UDim2.fromOffset(8, 15), BackgroundColor3 = P.red, BorderSizePixel = 0, Rotation = 30}, knuxHolder); corner(knuxHolder:GetChildren()[1], 6)
new("Frame", {Size = UDim2.fromOffset(12, 30), Position = UDim2.fromOffset(40, 15), BackgroundColor3 = P.red, BorderSizePixel = 0, Rotation = -30}, knuxHolder); corner(knuxHolder:GetChildren()[2], 6)
-- Corpo
local kBody = new("Frame", {Size = UDim2.fromOffset(28, 30), Position = UDim2.fromOffset(16, 30), BackgroundColor3 = P.red, BorderSizePixel = 0}, knuxHolder); corner(kBody, 14)
new("Frame", {Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(6, 10), BackgroundColor3 = P.white, BorderSizePixel = 0}, kBody); corner(kBody:GetChildren()[1], 8)
-- Cabeça
local kHead = new("Frame", {Size = UDim2.fromOffset(34, 32), Position = UDim2.fromOffset(13, 5), BackgroundColor3 = P.red, BorderSizePixel = 0}, knuxHolder); corner(kHead, 16)
local kEye = new("Frame", {Size = UDim2.fromOffset(10, 12), Position = UDim2.fromOffset(18, 8), BackgroundColor3 = P.white, BorderSizePixel = 0}, kHead); corner(kEye, 5)
new("Frame", {Size = UDim2.fromOffset(4, 5), Position = UDim2.fromOffset(4, 3), BackgroundColor3 = P.ink, BorderSizePixel = 0}, kEye); corner(kEye:GetChildren()[1], 2)
local kMuzzle = new("Frame", {Size = UDim2.fromOffset(16, 10), Position = UDim2.fromOffset(18, 16), BackgroundColor3 = Color3.fromRGB(255, 205, 160), BorderSizePixel = 0}, kHead); corner(kMuzzle, 5)
new("Frame", {Size = UDim2.fromOffset(4, 4), Position = UDim2.fromOffset(10, 2), BackgroundColor3 = P.ink, BorderSizePixel = 0}, kMuzzle); corner(kMuzzle:GetChildren()[1], 2)
-- Braços e Luvas (Espinhos nas mãos)
new("Frame", {Size = UDim2.fromOffset(14, 14), Position = UDim2.fromOffset(0, 40), BackgroundColor3 = P.white, BorderSizePixel = 0}, knuxHolder); corner(knuxHolder:GetChildren()[8], 7)
new("Frame", {Size = UDim2.fromOffset(14, 14), Position = UDim2.fromOffset(46, 40), BackgroundColor3 = P.white, BorderSizePixel = 0}, knuxHolder); corner(knuxHolder:GetChildren()[9], 7)
-- Pernas e Sapatos
new("Frame", {Size = UDim2.fromOffset(20, 10), Position = UDim2.fromOffset(12, 74), BackgroundColor3 = P.red, BorderSizePixel = 0}, knuxHolder); corner(knuxHolder:GetChildren()[10], 5)
new("Frame", {Size = UDim2.fromOffset(20, 10), Position = UDim2.fromOffset(28, 74), BackgroundColor3 = P.red, BorderSizePixel = 0}, knuxHolder); corner(knuxHolder:GetChildren()[11], 5)
new("Frame", {Size = UDim2.fromOffset(20, 4), Position = UDim2.fromOffset(0, 3), BackgroundColor3 = Color3.fromRGB(90, 200, 80), BorderSizePixel = 0}, knuxHolder:GetChildren()[10])
new("Frame", {Size = UDim2.fromOffset(20, 4), Position = UDim2.fromOffset(0, 3), BackgroundColor3 = Color3.fromRGB(90, 200, 80), BorderSizePixel = 0}, knuxHolder:GetChildren()[11])


-- Loop de animação da tela de load
local progress = 0
task.spawn(function()
    while isRunning do
        local dt = task.wait(0.03)
        timeTracker = timeTracker + dt
        
        -- Move a grama para dar sensação de corrida
        runOffset = (runOffset + dt * 200) % 40
        grassTop.Position = UDim2.new(0, -runOffset, 1, -80)
        grassDirt.Position = UDim2.new(0, -runOffset, 1, -68)
        
        -- Animação das pernas do Sonic
        local sStep = math.sin(timeTracker * 15)
        sLeg1.Rotation = sStep * 30
        sShoe1.Rotation = sStep * 30
        sLeg2.Rotation = -sStep * 30
        sShoe2.Rotation = -sStep * 30
        
        -- Animação das pernas do Knuckles
        local kStep = math.sin(timeTracker * 15 + math.pi) 
        knuxHolder:GetChildren()[10].Rotation = kStep * 25
        knuxHolder:GetChildren()[11].Rotation = -kStep * 25
        
        -- Animação do Tails (Girar rabos e flutuar)
        tailBase.Rotation = tailBase.Rotation + dt * 600
        tailsHolder.Position = UDim2.new(0.5, 0, 1, -180 + math.sin(timeTracker * 5) * 10)
        
        -- Rastro do Sonic
        trail.Size = UDim2.fromOffset(100 + math.sin(timeTracker * 10) * 20, 30)
    end
end)

-- Barra de Progresso
local barBg = new("Frame", {Size = UDim2.fromOffset(350, 16), Position = UDim2.new(0.5, 0, 1, -30), AnchorPoint = Vector2.new(0.5, 1), BackgroundColor3 = P.panelDark, BorderSizePixel = 0}, LoadFrame)
corner(barBg, 8); outline(barBg, 3, P.ink)
local barFill = new("Frame", {Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = P.yellow, BorderSizePixel = 0}, barBg)
corner(barFill, 8)
local loadText = label(barBg, {Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 0.5, -10), Text = "Carregando... 0%", TextSize = 14, TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.FredokaOne, TextColor3 = P.ink})

task.spawn(function()
    while progress < 100 do
        progress = math.min(progress + math.random(1, 4), 100)
        tween(barFill, {Size = UDim2.new(progress / 100, 0, 1, 0)})
        loadText.Text = string.format("Carregando... %d%%", progress)
        task.wait(0.05)
    end
    isRunning = false
    TweenService:Create(LoadFrame, TweenInfo.new(0.4), {BackgroundTransparency = 1, Size = UDim2.fromOffset(0, 0)}):Play()
    for _, v in ipairs(LoadFrame:GetDescendants()) do
        pcall(function() 
            if v:IsA("GuiObject") then TweenService:Create(v, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play() end
            if v:IsA("TextLabel") then TweenService:Create(v, TweenInfo.new(0.4), {TextTransparency = 1}):Play() end
        end)
    end
    task.wait(0.45)
    LoadingGui:Destroy()
end)

-- ============================================================
-- UI PRINCIPAL
-- ============================================================
local GUI = new("ScreenGui", {Name = "SonicHub", ResetOnSpawn = false, DisplayOrder = 10, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Enabled = false}, PlayerGui)
local Overlay = new("ScreenGui", {Name = "SonicHubOverlay", ResetOnSpawn = false, DisplayOrder = 5, IgnoreGuiInset = true}, PlayerGui)

local Main = new("Frame", {Name = "Main", Size = UDim2.fromOffset(Config.WinW, Config.WinH), Position = UDim2.new(0.5, -Config.WinW / 2, 0.5, -Config.WinH / 2), BackgroundColor3 = P.bg, BorderSizePixel = 0, ClipsDescendants = true}, GUI)
corner(Main, 12); outline(Main, 3, P.text); local UIScale = new("UIScale", {Scale = 1}, Main)

local TitleBar = new("Frame", {Size = UDim2.new(1, 0, 0, Config.TitleH), BackgroundColor3 = P.title, BorderSizePixel = 0, ClipsDescendants = true}, Main)
corner(TitleBar, 10)
local checkered = new("Frame", {Size = UDim2.new(1, 0, 0, Config.TitleH), BackgroundTransparency = 0.85}, TitleBar)
for i = 0, 20 do
    for j = 0, 3 do
        if (i + j) % 2 == 0 then
            new("Frame", {Size = UDim2.fromOffset(20, 20), Position = UDim2.fromOffset(i * 20, j * 20), BackgroundColor3 = P.ink, BorderSizePixel = 0}, checkered)
        end
    end
end
new("Frame", {Size = UDim2.new(1, 0, 0, 10), Position = UDim2.new(0, 0, 1, -10), BackgroundColor3 = P.title, BorderSizePixel = 0}, TitleBar)
new("Frame", {Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, -2), BackgroundColor3 = P.ink, BorderSizePixel = 0}, TitleBar)
label(TitleBar, {Size = UDim2.fromOffset(200, Config.TitleH), Position = UDim2.fromOffset(14, 0), Text = "SONIC HUB", Font = Enum.Font.FredokaOne, TextSize = 26, TextColor3 = P.white, TextStrokeColor3 = P.ink, TextStrokeTransparency = 0})

local function titleButton(text, color, x, onClick)
    local b = new("TextButton", {Size = UDim2.fromOffset(26, 26), Position = UDim2.new(1, x, 0.5, -13), BackgroundColor3 = color, Text = text, TextColor3 = P.ink, Font = Enum.Font.GothamBlack, TextSize = 18, AutoButtonColor = false}, TitleBar)
    corner(b, 8); outline(b, 2.5, P.text); b.MouseButton1Click:Connect(onClick); return b
end
titleButton("-", P.yellow, -66, function() end)
titleButton("x", P.red, -34, function() GUI:Destroy() end)

local Body = new("Frame", {Position = UDim2.fromOffset(0, Config.TitleH), Size = UDim2.fromOffset(Config.WinW, Config.WinH - Config.TitleH), BackgroundTransparency = 1}, Main)
local Footer = new("Frame", {Size = UDim2.new(1, 0, 0, Config.FooterH), Position = UDim2.new(0, 0, 1, -Config.FooterH), BackgroundColor3 = P.brick, BorderSizePixel = 0, ClipsDescendants = true}, Body)
new("Frame", {Size = UDim2.new(1, 0, 0, 3), BackgroundColor3 = P.green, BorderSizePixel = 0}, Footer)
local usableH = (Config.WinH - Config.TitleH) - Config.FooterH - 12

local Sidebar = new("Frame", {Position = UDim2.fromOffset(6, 6), Size = UDim2.fromOffset(180, usableH), BackgroundColor3 = P.panel, BorderSizePixel = 0}, Body)
corner(Sidebar, 10); outline(Sidebar, 2.5, P.text)
local NavList = new("ScrollingFrame", {Size = UDim2.new(1, 0, 1, -10), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y}, Sidebar)
new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, NavList); new("UIPadding", {PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6)}, NavList)

local ContentArea = new("Frame", {Position = UDim2.fromOffset(194, 6), Size = UDim2.fromOffset(Config.WinW - 200, usableH), BackgroundTransparency = 1}, Body)
local PageTitle = label(ContentArea, {Size = UDim2.new(0.55, 0, 0, 26), Position = UDim2.fromOffset(6, 2), Text = "", Font = Enum.Font.FredokaOne, TextSize = 24})
local PageSub = label(ContentArea, {Size = UDim2.new(0.55, 0, 0, 18), Position = UDim2.fromOffset(6, 32), Text = "", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = P.sub})
local Scroll = new("ScrollingFrame", {Position = UDim2.fromOffset(0, 56), Size = UDim2.new(1, 0, 1, -56), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, ScrollBarImageColor3 = P.yellow, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y}, ContentArea)
new("UIPadding", {PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 10)}, Scroll)

-- ============================================================
-- BUILDERS (UI Consertada)
-- ============================================================
local infoRows, currentCard = {}, nil
local captureTarget = nil

local function newRow(parent, minH) return new("Frame", {Size = UDim2.new(1, 0, 0, minH or 30), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1}, parent) end
local function textBlock(parent, item, scale)
    local blk = new("Frame", {Size = UDim2.new(scale, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1}, parent)
    new("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}, blk)
    label(blk, {Size = UDim2.new(1, 0, 0, 17), Text = item.label, TextSize = 14, LayoutOrder = 1})
    if item.desc then label(blk, {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = item.desc, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = P.sub, TextWrapped = true, LayoutOrder = 2}) end
    return blk
end

local function makeSwitch(parent, key, pos)
    local pill = new("TextButton", {Size = UDim2.fromOffset(46, 24), AnchorPoint = Vector2.new(1, 0.5), Position = pos, BackgroundColor3 = P.track, Text = "", AutoButtonColor = false}, parent)
    corner(pill, 12); outline(pill, 2, P.ink)
    local knob = new("Frame", {Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(4, 4), BackgroundColor3 = P.white, BorderSizePixel = 0}, pill)
    corner(knob, 8); outline(knob, 1.5, P.ink)
    
    local isOn = preferences[key] == true
    local function render()
        local newOn = preferences[key] == true
        if isOn == newOn then return end
        isOn = newOn
        tween(pill, {BackgroundColor3 = isOn and P.green or P.track})
        tween(knob, {Position = isOn and UDim2.fromOffset(26, 4) or UDim2.fromOffset(4, 4)})
    end
    uiRenderers[key] = render
    
    pill.MouseButton1Click:Connect(function() 
        setPref(key, not (preferences[key] == true)); 
        render() 
    end)
    render()
    return pill
end

local function rowToggle(body, item)
    local row = newRow(body, 32)
    textBlock(row, item, item.bindKey and 0.5 or 0.75)
    makeSwitch(row, item.key, UDim2.new(1, 0, 0.5, 0))
    
    if item.bindKey then
        local chip = new("TextButton", {Size = UDim2.fromOffset(80, 24), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -54, 0.5, 0), BackgroundColor3 = P.panelDark, Text = formatBind(preferences[item.bindKey]), TextColor3 = P.yellow, Font = Enum.Font.GothamBold, TextSize = 12, AutoButtonColor = false}, row)
        corner(chip, 6); outline(chip, 1.5, P.yellow)
        
        chip.MouseButton1Click:Connect(function() 
            chip.Text = "..." 
            captureTarget = {key = item.bindKey, button = chip} 
        end)
    end
end

local function rowCheck(body, item)
    local row = newRow(body, 28); textBlock(row, item, 0.8)
    local box = new("TextButton", {Size = UDim2.fromOffset(26, 26), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), BackgroundColor3 = P.white, Text = "", AutoButtonColor = false}, row)
    corner(box, 6); outline(box, 2.5, P.ink)
    local mark = new("Frame", {Size = UDim2.fromOffset(14, 14), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = P.yellow, BorderSizePixel = 0, Visible = false}, box)
    corner(mark, 3); outline(mark, 2, P.ink)
    
    local isOn = preferences[item.key] == true
    local function render()
        local newOn = preferences[item.key] == true
        if isOn == newOn then return end
        isOn = newOn
        tween(box, {BackgroundColor3 = isOn and P.yellow or P.white})
        mark.Visible = isOn
    end
    uiRenderers[item.key] = render
    
    box.MouseButton1Click:Connect(function() setPref(item.key, not (preferences[item.key] == true)); render() end)
    render()
end

local function rowDropdown(body, item)
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1}, body)
    new("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, row)
    local blk = textBlock(row, item, 1); blk.LayoutOrder = 1
    local box = new("TextButton", {Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = P.white, Text = "", AutoButtonColor = false, LayoutOrder = 2}, row)
    corner(box, 8); outline(box, 2.5, P.ink)
    local valLbl = label(box, {Size = UDim2.new(1, -42, 1, 0), Position = UDim2.fromOffset(12, 0), Text = tostring(preferences[item.key]), TextSize = 13, TextColor3 = P.ink})
    local arrow = new("Frame", {Size = UDim2.fromOffset(22, 22), Position = UDim2.new(1, -28, 0.5, -11), BackgroundColor3 = P.red, BorderSizePixel = 0}, box)
    corner(arrow, 6); outline(arrow, 2.5, P.ink); label(arrow, {Size = UDim2.new(1, 0, 1, 0), Text = "v", TextColor3 = P.white, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBlack})
    local list = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = P.white, Visible = false, LayoutOrder = 3}, row)
    corner(list, 8); outline(list, 2.5, P.ink); new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}, list); new("UIPadding", {PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4)}, list)
    local optBtns = {}
    local function render() valLbl.Text = tostring(preferences[item.key]); for opt, b in pairs(optBtns) do b.TextColor3 = preferences[item.key] == opt and P.red or P.ink end end
    for i, opt in ipairs(item.options) do
        local b = new("TextButton", {Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Text = "   " .. opt, Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false, LayoutOrder = i, TextColor3 = P.ink}, list)
        optBtns[opt] = b; b.MouseButton1Click:Connect(function() setPref(item.key, opt); list.Visible = false; render() end)
    end
    box.MouseButton1Click:Connect(function() list.Visible = not list.Visible end); render()
end

local function rowSlider(body, item)
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1}, body)
    new("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, row)
    local top = new("Frame", {Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, LayoutOrder = 1}, row)
    textBlock(top, item, 0.72)
    local valLbl = label(top, {Size = UDim2.fromOffset(80, 17), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), TextColor3 = P.yellow, TextXAlignment = Enum.TextXAlignment.Right, TextSize = 13})
    
    local holder = new("TextButton", {Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = "", LayoutOrder = 2}, row)
    local track = new("Frame", {Size = UDim2.new(1, -14, 0, 8), Position = UDim2.new(0, 7, 0.5, -4), BackgroundColor3 = P.track, BorderSizePixel = 0}, holder)
    corner(track, 4); outline(track, 2, P.ink)
    local fill = new("Frame", {Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = P.yellow, BorderSizePixel = 0}, track); corner(fill, 4)
    local knob = new("Frame", {Size = UDim2.fromOffset(18, 18), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = P.white, BorderSizePixel = 0}, track); corner(knob, 9); outline(knob, 2, P.ink)
    
    local function render() 
        local v = prefNum(item.key, item.value)
        local a = (v - item.min) / (item.max - item.min)
        fill.Size = UDim2.new(a, 0, 1, 0)
        knob.Position = UDim2.new(a, 0, 0.5, 0)
        valLbl.Text = tostring(v) .. (item.suffix or "") 
    end
    
    holder.InputBegan:Connect(function(input) 
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
            activeSlider = { key = item.key, item = item, track = track, render = render }
            local w = track.AbsoluteSize.X
            if w > 0 then
                local a = math.clamp((input.Position.X - track.AbsolutePosition.X) / w, 0, 1)
                local val = math.floor(item.min + a * (item.max - item.min) + 0.5)
                setPref(item.key, val)
                render()
            end
        end 
    end)
    render()
end

local function rowInfo(body, item)
    local row = newRow(body, 22)
    label(row, {Size = UDim2.new(0.6, 0, 1, 0), Text = item.label, TextSize = 13, TextColor3 = P.text})
    local value = label(row, {Size = UDim2.new(0.4, 0, 1, 0), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Text = item.get(), TextColor3 = P.yellow, TextXAlignment = Enum.TextXAlignment.Right, Font = Enum.Font.GothamBold})
    table.insert(infoRows, {label = value, get = item.get})
end

local configFolder = "SonicHubConfigs"
if type(makefolder) == "function" and type(isfolder) == "function" then
    if not isfolder(configFolder) then makefolder(configFolder) end
end
local function getConfigs()
    local list = {}
    if type(listfiles) == "function" and isfolder(configFolder) then
        for _, file in ipairs(listfiles(configFolder)) do
            if file:sub(-5) == ".json" then table.insert(list, file:sub(#configFolder + 2, -6)) end
        end
    end
    return list
end

local function rowConfig(body, item)
    local listFrame = new("ScrollingFrame", {Size = UDim2.new(1, 0, 0, 120), BackgroundColor3 = P.panelDark, BorderSizePixel = 0, ScrollBarThickness = 3}, body)
    corner(listFrame, 6); outline(listFrame, 2, P.ink)
    new("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, listFrame)
    
    local input = new("TextBox", {Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = P.white, Text = "", PlaceholderText = "Nome do config...", TextColor3 = P.ink, Font = Enum.Font.Gotham, TextSize = 12, LayoutOrder = 1}, listFrame)
    corner(input, 6); outline(input, 2, P.ink); new("UIPadding", {PaddingLeft = UDim.new(0, 6)}, input)
    
    local saveBtn = new("TextButton", {Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = P.blue, Text = "Salvar Novo Config", TextColor3 = P.white, Font = Enum.Font.GothamBold, TextSize = 12, AutoButtonColor = false, LayoutOrder = 2}, listFrame)
    corner(saveBtn, 6); outline(saveBtn, 2, P.ink)
    saveBtn.MouseButton1Click:Connect(function()
        if input.Text ~= "" and type(writefile) == "function" then
            local ok, data = pcall(function() return HttpService:JSONEncode(preferences) end)
            if ok then writefile(configFolder .. "/" .. input.Text .. ".json", data); input.Text = ""; showPage("Configs") end
        end
    end)

    for i, cfgName in ipairs(getConfigs()) do
        local itemRow = new("Frame", {Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = P.cardHead, LayoutOrder = i + 2}, listFrame)
        corner(itemRow, 6)
        label(itemRow, {Size = UDim2.new(0.5, 0, 1, 0), Position = UDim2.fromOffset(6, 0), Text = cfgName, TextSize = 12, TextColor3 = P.text})
        
        local loadBtn = new("TextButton", {Size = UDim2.fromOffset(40, 20), Position = UDim2.new(1, -90, 0.5, -10), BackgroundColor3 = P.green, Text = "Load", TextColor3 = P.white, Font = Enum.Font.GothamBold, TextSize = 10, AutoButtonColor = false}, itemRow)
        corner(loadBtn, 4); outline(loadBtn, 1.5, P.ink)
        loadBtn.MouseButton1Click:Connect(function()
            if type(readfile) == "function" and isfile(configFolder .. "/" .. cfgName .. ".json") then
                local ok, data = pcall(function() return HttpService:JSONDecode(readfile(configFolder .. "/" .. cfgName .. ".json")) end)
                if ok and type(data) == "table" then for k, v in pairs(data) do preferences[k] = v end; showPage("Configs") end
            end
        end)

        local delBtn = new("TextButton", {Size = UDim2.fromOffset(40, 20), Position = UDim2.new(1, -45, 0.5, -10), BackgroundColor3 = P.red, Text = "Del", TextColor3 = P.white, Font = Enum.Font.GothamBold, TextSize = 10, AutoButtonColor = false}, itemRow)
        corner(delBtn, 4); outline(delBtn, 1.5, P.ink)
        delBtn.MouseButton1Click:Connect(function()
            if type(delfile) == "function" and isfile(configFolder .. "/" .. cfgName .. ".json") then delfile(configFolder .. "/" .. cfgName .. ".json"); showPage("Configs") end
        end)
    end
end

local builders = {toggle = rowToggle, check = rowCheck, dropdown = rowDropdown, slider = rowSlider, info = rowInfo, config = rowConfig}

local function makeCard(parent, spec)
    local card = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = P.card, BorderSizePixel = 0, ClipsDescendants = true}, parent)
    corner(card, 10); outline(card, 2.5, P.text); new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}, card)
    local head = new("TextButton", {Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = P.cardHead, Text = "", AutoButtonColor = false, LayoutOrder = 1}, card)
    corner(head, 10); new("Frame", {Size = UDim2.new(1, 0, 0, 10), Position = UDim2.new(0, 0, 1, -10), BackgroundColor3 = P.cardHead, BorderSizePixel = 0}, head)
    new("Frame", {Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, -2), BackgroundColor3 = P.ink, BorderSizePixel = 0}, head)
    local icon = new("Frame", {Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(12, 9), BackgroundColor3 = spec.icon or P.red, BorderSizePixel = 0}, head)
    corner(icon, 8); outline(icon, 2, P.ink); label(head, {Size = UDim2.new(1, -60, 1, 0), Position = UDim2.fromOffset(36, 0), Text = spec.title, TextSize = 15})
    local chevron = label(head, {Size = UDim2.fromOffset(24, 34), Position = UDim2.new(1, -28, 0, 0), Text = "v", TextColor3 = P.sub, TextXAlignment = Enum.TextXAlignment.Center, TextSize = 16})
    local body = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 2}, card)
    new("UIListLayout", {Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder}, body); new("UIPadding", {PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12)}, body)
    head.MouseButton1Click:Connect(function() body.Visible = not body.Visible; chevron.Text = body.Visible and "v" or ">" end)
    currentCard = card; for _, item in ipairs(spec.rows) do builders[item.type](body, item) end; return card
end

-- ============================================================
-- PÁGINAS
-- ============================================================
local AIM_PARTS = {Head = {"Head"}, Torso = {"UpperTorso", "Torso"}, Root = {"HumanoidRootPart"}}
local PRIORITIES = {"Crosshair", "Distance", "Health"}
local KEY_MODES = {"Hold", "Toggle", "Always"}
local ESP_COLORS = {Cyan = Color3.fromRGB(0, 210, 235), Red = Color3.fromRGB(255, 80, 90), Green = Color3.fromRGB(80, 235, 120), Yellow = Color3.fromRGB(255, 225, 80), White = Color3.fromRGB(245, 245, 245), Magenta = Color3.fromRGB(255, 90, 230)}
local triggerCount = 0
local targetCount = 0

local pages = {
    ["Main"] = {
        title = "MAIN", sub = "Overview",
        left = {{title = "Overview", icon = P.red, rows = {
            {type = "info", label = "Targets found", get = function() return tostring(targetCount) end},
            {type = "dropdown", key = "tgt.source", label = "Target source", options = {"Tagged", "All humanoids"}, value = "All humanoids"},
        }}},
        right = {{title = "Interface", icon = P.yellow, rows = {
            {type = "check", key = "ui.hud", label = "Show HUD", value = true},
        }}},
    },
    ["Aimbot"] = {
        title = "AIMBOT", sub = "Locks your camera",
        left = {{title = "Aimbot", icon = P.red, rows = {
            {type = "toggle", key = "aim.enabled", label = "Aimbot", bindKey = "aim.bind", bindValue = "MouseButton2", value = false},
            {type = "dropdown", key = "aim.mode", label = "Key mode", options = KEY_MODES, value = "Hold"},
            {type = "slider", key = "aim.smooth", label = "Smoothness", min = 1, max = 20, value = 5},
            {type = "check", key = "aim.sticky", label = "Sticky target", value = false},
        }}},
        right = {{title = "Targeting", icon = P.blue, rows = {
            {type = "dropdown", key = "aim.part", label = "Aim part", options = {"Head", "Torso", "Root"}, value = "Head"},
            {type = "dropdown", key = "aim.priority", label = "Priority", options = PRIORITIES, value = "Crosshair"},
            {type = "check", key = "aim.visible", label = "Visible only", value = false},
            {type = "slider", key = "aim.fov", label = "FOV", min = 10, max = 600, value = 180, suffix = "px"},
            {type = "slider", key = "aim.dist", label = "Max distance", min = 50, max = 5000, value = 2000, suffix = " st"},
        }}},
    },
    ["Silent Aim"] = {
        title = "SILENT AIM", sub = "Shots find the target",
        left = {{title = "Silent Aim", icon = P.text, rows = {
            {type = "toggle", key = "sil.enabled", label = "Silent aim", bindKey = "sil.bind", bindValue = "None", value = false},
            {type = "dropdown", key = "sil.part", label = "Aim part", options = {"Head", "Torso", "Root"}, value = "Head"},
            {type = "slider", key = "sil.fov", label = "FOV", min = 10, max = 600, value = 360, suffix = "px"},
            {type = "slider", key = "sil.hit", label = "Hit chance", min = 0, max = 100, value = 95, suffix = "%"},
            {type = "slider", key = "sil.head", label = "Headshot chance", min = 0, max = 100, value = 100, suffix = "%"},
        }}},
        right = {{title = "Targeting", icon = P.blue, rows = {
            {type = "check", key = "sil.visible", label = "Visible only", value = false},
            {type = "slider", key = "sil.dist", label = "Max distance", min = 50, max = 5000, value = 3000, suffix = " st"},
        }}},
    },
    ["Trigger & Rage"] = {
        title = "TRIGGER & RAGE", sub = "Automatic firing",
        left = {{title = "Triggerbot", icon = P.yellow, rows = {
            {type = "toggle", key = "trg.enabled", label = "Trigger bot", bindKey = "trg.bind", bindValue = "MouseButton2", value = false},
            {type = "dropdown", key = "trg.mode", label = "Key mode", options = KEY_MODES, value = "Always"},
            {type = "info", label = "Trigger count", get = function() return tostring(triggerCount) end},
            {type = "slider", key = "trg.fov", label = "Trigger FOV", min = 1, max = 50, value = 15, suffix = "px"},
            {type = "slider", key = "trg.delay", label = "Reaction delay", min = 0, max = 1000, value = 50, suffix = " ms"},
            {type = "slider", key = "trg.chance", label = "Fire chance", min = 0, max = 100, value = 100, suffix = "%"},
            {type = "slider", key = "trg.hit", label = "Hit chance", min = 0, max = 100, value = 95, suffix = "%"},
            {type = "slider", key = "trg.head", label = "Headshot chance", min = 0, max = 100, value = 100, suffix = "%"},
        }}},
        right = {{title = "Ragebot", icon = P.red, rows = {
            {type = "toggle", key = "rage.enabled", label = "Ragebot", bindKey = "rage.bind", bindValue = "None", value = false},
            {type = "check", key = "rage.visible", label = "Visible only", value = true},
            {type = "slider", key = "rage.dist", label = "Max distance", min = 50, max = 5000, value = 3000, suffix = "m"},
        }}},
    },
    ["Gun Mods"] = {
        title = "GUN MODS", sub = "Weapon tweaks",
        left = {{title = "Weapon", icon = P.text, rows = {
            {type = "check", key = "gun.recoil", label = "No recoil", value = false},
            {type = "check", key = "gun.spread", label = "No spread", value = false},
            {type = "check", key = "gun.cooldown", label = "No cooldown", value = false}
        }}},
        right = {},
    },
    ["Visuals"] = {
        title = "VISUALS", sub = "Player ESP",
        left = {
            {title = "ESP", icon = P.red, rows = {
                {type = "toggle", key = "esp.enabled", label = "Enable ESP", value = false},
                {type = "check", key = "esp.team", label = "Team check", value = true},
                {type = "slider", key = "esp.maxdist", label = "Max distance", min = 100, max = 5000, value = 2000, suffix = "m"},
                {type = "slider", key = "esp.text", label = "Text size", min = 10, max = 24, value = 13},
            }},
            {title = "Colors", icon = P.yellow, rows = {
                {type = "dropdown", key = "esp.col.enemy", label = "Enemy", options = {"Red", "Cyan", "Magenta"}, value = "Red"},
                {type = "dropdown", key = "esp.col.friendly", label = "Friendly", options = {"Green", "Blue", "White"}, value = "Green"},
            }},
        },
        right = {
            {title = "Elements", icon = P.yellow, rows = {
                {type = "check", key = "esp.el.box", label = "Box ESP", value = true},
                {type = "dropdown", key = "esp.el.boxstyle", label = "Box style", options = {"Full", "Corner"}, value = "Full"},
                {type = "check", key = "esp.el.fill", label = "Box fill", value = false},
                {type = "check", key = "esp.el.name", label = "Name ESP", value = true},
                {type = "check", key = "esp.el.dist", label = "Distance ESP", value = true},
                {type = "check", key = "esp.el.health", label = "Health bar", value = true},
                {type = "check", key = "esp.el.healthnum", label = "Health number", value = false},
                {type = "check", key = "esp.el.skeleton", label = "Skeleton ESP", value = false},
                {type = "check", key = "esp.el.tracer", label = "Line ESP", value = false},
                {type = "check", key = "esp.el.headdot", label = "Head dot", value = false},
                {type = "dropdown", key = "esp.el.pos", label = "Text Position", options = {"Top", "Bottom"}, value = "Top"},
                {type = "slider", key = "esp.el.thick", label = "Line Thickness", min = 1, max = 4, value = 2},
            }},
        },
    },
    ["Settings"] = {
        title = "SETTINGS", sub = "Interface and configs",
        left = {
            {title = "Interface", icon = P.red, rows = {
                {type = "dropdown", key = "set.lang", label = "Language", options = {"English", "Português"}, value = "Português"},
                {type = "slider", key = "set.uiscale", label = "UI scale", min = 50, max = 150, value = 100, suffix = "%"},
                {type = "check", key = "set.watermark", label = "Watermark", value = true},
                {type = "check", key = "set.particles", label = "Ambient particles", value = true},
                {type = "check", key = "set.mobilebtn", label = "Mobile button", value = false},
            }},
        },
        right = {
            {title = "Configs", icon = P.yellow, rows = {
                {type = "config"}
            }},
        },
    }
}

local navLayout = {
    {section = "MAIN", items = {"Main"}},
    {section = "COMBAT", items = {"Aimbot", "Silent Aim", "Trigger & Rage", "Gun Mods"}},
    {section = "VISUALS", items = {"Visuals"}},
    {section = "SETTINGS", items = {"Settings"}},
}

local navSprites = {
    ["Main"] = "sonic", ["Aimbot"] = "shoe", ["Silent Aim"] = "emerald",
    ["Trigger & Rage"] = "ring", ["Gun Mods"] = "knuckles", ["Visuals"] = "tails", ["Settings"] = "ring",
}

local bindToToggle = {}

for _, page in pairs(pages) do
    for _, side in ipairs({"left", "right"}) do
        for _, card in ipairs(page[side]) do
            for _, item in ipairs(card.rows) do
                if item.key and preferences[item.key] == nil then preferences[item.key] = item.value end
                if item.bindKey then
                    if preferences[item.bindKey] == nil then preferences[item.bindKey] = item.bindValue end
                    bindToToggle[item.bindKey] = item.key
                end
            end
        end
    end
end

-- ============================================================
-- NAVEGAÇÃO
-- ============================================================
local navButtons = {}
local function updateInfos()
    for i = #infoRows, 1, -1 do
        local r = infoRows[i]
        if r.label.Parent then r.label.Text = r.get() else table.remove(infoRows, i) end
    end
end

local function showPage(name)
    local page = pages[name]; if not page then return end
    activeSlider = nil

    for _, c in ipairs(Scroll:GetChildren()) do
        if c:IsA("GuiObject") then
            TweenService:Create(c, TweenInfo.new(0.15), {BackgroundTransparency = 1}):Play()
            task.delay(0.15, function() if c.Parent then c:Destroy() end end)
        end
    end

    infoRows = {}
    PageTitle.Text = page.title; PageSub.Text = page.sub

    local cols = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1}, Scroll)
    new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12), VerticalAlignment = Enum.VerticalAlignment.Top, SortOrder = Enum.SortOrder.LayoutOrder}, cols)
    for order, side in ipairs({"left", "right"}) do
        local col = new("Frame", {Size = UDim2.new(0.5, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = order}, cols)
        new("UIListLayout", {Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder}, col)
        for _, spec in ipairs(page[side]) do
            local card = makeCard(col, spec); card.Size = UDim2.new(1, 0, 0, 0); card.Position = UDim2.new(0, 0, 0, 15); card.BackgroundTransparency = 1
            TweenService:Create(card, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0, Position = UDim2.new(0, 0, 0, 0)}):Play()
        end
    end
    for tabName, t in pairs(navButtons) do
        local sel = tabName == name
        tween(t.btn, {BackgroundColor3 = sel and P.card or P.panel})
        t.btn.TextColor3 = sel and P.yellow or P.text
    end
    Scroll.CanvasPosition = Vector2.new(0, 0); updateInfos()
end

do
    local order = 0
    for _, group in ipairs(navLayout) do
        order += 1
        local sec = label(NavList, {Size = UDim2.new(1, 0, 0, 20), Text = group.section, TextSize = 11, TextColor3 = P.sub, LayoutOrder = order})
        new("UIPadding", {PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6)}, sec)
        for _, name in ipairs(group.items) do
            order += 1
            local btn = new("TextButton", {Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = P.panel, Text = "          " .. name, TextColor3 = P.text, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false, LayoutOrder = order}, NavList)
            corner(btn, 8)
            -- Ícone da sidebar recriado em forma de bloco
            local icon = new("Frame", {Size = UDim2.fromOffset(14, 14), Position = UDim2.fromOffset(10, 11), BackgroundColor3 = P.blue, BorderSizePixel = 0}, btn)
            corner(icon, 4)
            navButtons[name] = {btn = btn, icon = icon}
            btn.MouseButton1Click:Connect(function() showPage(name) end)
        end
    end
end

-- ============================================================
-- LÓGICA DO JOGO
-- ============================================================
local function finiteVec(v) return v.X == v.X and v.Y == v.Y and v.Z == v.Z end
local function smoothAlpha(sm, dt) local base = 1 / math.max(sm, 1); return 1 - (1 - base) ^ (math.clamp(dt, 0, 0.1) * 60) end

local taggedModels, humanoidModels, scanned = {}, {}, false
local function addHumanoid(inst) if inst:IsA("Humanoid") then local m = inst.Parent; if m and m:IsA("Model") then humanoidModels[m] = true end end end
local function ensureScan()
    if scanned then return end; scanned = true
    for _, inst in ipairs(Workspace:GetDescendants()) do addHumanoid(inst) end
    connect(Workspace.DescendantAdded, addHumanoid)
    connect(Workspace.DescendantRemoving, function(inst) if inst:IsA("Humanoid") and inst.Parent then humanoidModels[inst.Parent] = nil end end)
end
local function targetSet()
    if pref("tgt.source", "All humanoids") == "All humanoids" then ensureScan(); return humanoidModels end
    return taggedModels
end

local function readNpc(model)
    if not model or not model.Parent then return nil end
    if Players:GetPlayerFromCharacter(model) == Player then return nil end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return nil end
    local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
    if not root or not root:IsA("BasePart") or not finiteVec(root.Position) then return nil end
    return {Model = model, Humanoid = hum, Root = root}
end

local function resolvePart(npc, names)
    for _, n in ipairs(names) do local p = npc.Model:FindFirstChild(n); if p and p:IsA("BasePart") then return p end end
    return npc.Root
end

local rayParams = RaycastParams.new(); pcall(function() rayParams.FilterType = Enum.RaycastFilterType.Exclude end)
local function isVisible(camPos, part, model)
    local ignore = {model}; if Player.Character then table.insert(ignore, Player.Character) end
    rayParams.FilterDescendantsInstances = ignore; return Workspace:Raycast(camPos, part.Position - camPos, rayParams) == nil
end

local function evaluate(cam, camPos, mouse, model, o)
    local npc = readNpc(model); if not npc then return nil end
    local part = resolvePart(npc, o.names); local pos = part.Position
    local dist = (pos - camPos).Magnitude; if dist > o.maxDist then return nil end
    local sp = cam:WorldToViewportPoint(pos); if sp.Z <= 0 then return nil end
    local px = (Vector2.new(sp.X, sp.Y) - mouse).Magnitude
    if px > o.fov then return nil end
    if o.visible and not isVisible(camPos, part, model) then return nil end
    local score = px
    if o.priority == "Distance" then score = dist elseif o.priority == "Health" then score = npc.Humanoid.Health end
    return {Part = part, Model = model, Position = pos, Score = score, Npc = npc, Distance = dist}
end

local function pickTarget(cam, o, sticky, useCenter)
    local camPos = cam.CFrame.Position
    local mouse = useCenter and Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2) or viewportMouse()
    if sticky then local c = evaluate(cam, camPos, mouse, sticky, o); if c then return c end end
    local best
    for model in pairs(targetSet()) do local c = evaluate(cam, camPos, mouse, model, o); if c and (best == nil or c.Score < best.Score) then best = c end end
    return best
end

-- INPUT SYSTEM
local windowFocused, KeyState = true, {}
connect(UserInputService.WindowFocused, function() windowFocused = true end)
connect(UserInputService.WindowFocusReleased, function() windowFocused = false; for _, s in pairs(KeyState) do s.down = false; s.on = false end end)

connect(UserInputService.InputBegan, function(input, processed)
    if processed then return end
    
    if captureTarget then
        local keyName = nil
        if input.UserInputType == Enum.UserInputType.Keyboard then
            keyName = input.KeyCode.Name
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then keyName = "MouseButton1"
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then keyName = "MouseButton2"
        elseif input.UserInputType == Enum.UserInputType.MouseButton3 then keyName = "MouseButton3"
        end
        if keyName then
            setPref(captureTarget.key, keyName)
            captureTarget.button.Text = formatBind(keyName)
            captureTarget = nil
        end
        return
    end
    
    for bindKey, toggleKey in pairs(bindToToggle) do
        local val = pref(bindKey)
        if val and val ~= "None" then
            local matches = false
            if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == val then matches = true
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 and val == "MouseButton1" then matches = true
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 and val == "MouseButton2" then matches = true
            elseif input.UserInputType == Enum.UserInputType.MouseButton3 and val == "MouseButton3" then matches = true
            end

            if matches then
                local modeKey = bindKey:gsub("%.bind$", ".mode")
                if pref(modeKey, "Hold") == "Toggle" then
                    setPref(toggleKey, not pref(toggleKey))
                    if uiRenderers[toggleKey] then uiRenderers[toggleKey]() end
                end
            end
        end
    end

    if input.KeyCode == Config.MenuKey then GUI.Enabled = not GUI.Enabled end
end)

connect(UserInputService.InputChanged, function(input)
    if activeSlider then
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local w = activeSlider.track.AbsoluteSize.X
            if w > 0 then
                local a = math.clamp((input.Position.X - activeSlider.track.AbsolutePosition.X) / w, 0, 1)
                local val = math.floor(activeSlider.item.min + a * (activeSlider.item.max - activeSlider.item.min) + 0.5)
                setPref(activeSlider.key, val)
                activeSlider.render()
            end
        end
    end
end)

connect(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        activeSlider = nil
    end
end)

local function keyActive(id, bindName, modeName)
    if modeName == "Always" then return windowFocused and not UserInputService:GetFocusedTextBox() end
    if modeName == "Toggle" then return pref(id .. ".enabled", false) end
    
    if not pref(id .. ".enabled", false) then return false end
    local bindType, bindVal = nil, nil
    if bindName and bindName ~= "None" then
        if bindName:find("MouseButton") then bindType = "mouse"; bindVal = Enum.UserInputType[bindName]
        else local ok, kc = pcall(function() return Enum.KeyCode[bindName] end); if ok and kc then bindType = "key"; bindVal = kc end end
    end
    if not bindType or not windowFocused or UserInputService:GetFocusedTextBox() then return false end
    local down = false
    if bindType == "mouse" then down = UserInputService:IsMouseButtonPressed(bindVal)
    else down = UserInputService:IsKeyDown(bindVal) end
    return down
end

-- Aimbot
local aimSticky = nil
local function aimbotStep(dt)
    local aiming = keyActive("aim", pref("aim.bind", "MouseButton2"), pref("aim.mode", "Hold"))
    local cam = Workspace.CurrentCamera
    if not cam then return end
    if aiming then
        local names = {}; for _, n in ipairs(AIM_PARTS[pref("aim.part", "Head")] or AIM_PARTS.Head) do table.insert(names, n) end; table.insert(names, "Head")
        local target = pickTarget(cam, {names = names, fov = prefNum("aim.fov", 150), maxDist = prefNum("aim.dist", 2000), visible = pref("aim.visible", false) == true, priority = pref("aim.priority", "Crosshair")}, pref("aim.sticky", false) and aimSticky or nil, false)
        if target then
            aimSticky = target.Model
            local aimPos = target.Position
            local camPos = cam.CFrame.Position
            if (aimPos - camPos).Magnitude > 1e-3 then
                if cam.CameraType ~= Enum.CameraType.Scriptable then cam.CameraType = Enum.CameraType.Scriptable end
                local char = Player.Character
                local head = char and (char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart"))
                if head then camPos = head.Position end
                local targetCF = CFrame.lookAt(camPos, aimPos)
                cam.CFrame = cam.CFrame:Lerp(targetCF, smoothAlpha(prefNum("aim.smooth", 5), dt))
            end
        else
            aimSticky = nil
            if cam.CameraType == Enum.CameraType.Scriptable then cam.CameraType = Enum.CameraType.Custom end
        end
    else
        aimSticky = nil
        if cam.CameraType == Enum.CameraType.Scriptable then cam.CameraType = Enum.CameraType.Custom end
    end
end

-- Silent Aim
local function silentAim()
    if not pref("sil.enabled", false) or math.random() * 100 >= prefNum("sil.hit", 95) then return nil end
    local cam = Workspace.CurrentCamera; if not cam then return nil end
    local names = {}; for _, n in ipairs(AIM_PARTS[pref("sil.part", "Head")] or AIM_PARTS.Head) do table.insert(names, n) end
    local target = pickTarget(cam, {names = names, fov = prefNum("sil.fov", 360), maxDist = prefNum("sil.dist", 3000), visible = pref("sil.visible", false) == true, priority = "Crosshair"}, nil, false)
    if not target then return nil end
    return target
end

-- TRIGGERBOT / RAGEBOT
local lastTriggerTime = 0
local function triggerStep()
    local isRage = pref("rage.enabled", false)
    local isTrg = pref("trg.enabled", false)
    if not isRage and not isTrg then return end
    
    local id = isRage and "rage" or "trg"
    local mode = isRage and "Always" or pref("trg.mode", "Always")
    local bind = isRage and "None" or pref("trg.bind", "MouseButton2")
    
    if not keyActive(id, bind, mode) then return end
    
    local cam = Workspace.CurrentCamera; if not cam then return end
    
    local target = pickTarget(cam, {
        names = {"Head", "UpperTorso", "Torso"}, 
        fov = prefNum("trg.fov", 15), 
        maxDist = prefNum("rage.dist", 3000), 
        visible = pref("rage.visible", true) == true, 
        priority = "Crosshair"
    }, nil, true)
    
    if target and os.clock() - lastTriggerTime > (prefNum("trg.delay", 50) / 1000) then
        if math.random() * 100 > prefNum("trg.chance", 100) then return end
        lastTriggerTime = os.clock(); triggerCount = triggerCount + 1
        pcall(function()
            if type(genv().mouse1click) == "function" then genv().mouse1click()
            else VirtualUser:CaptureController(); VirtualUser:Button1Down(Vector2.new(0,0)); VirtualUser:Button1Up(Vector2.new(0,0)) end
        end)
    end
end

-- ============================================================
-- ESP TOTAL DO ZERO
-- ============================================================
local entries = {}
local function placeLine(f, p1, p2, thickness, color)
    local delta = p2 - p1; local len = delta.Magnitude
    if len < 0.5 or len > 3000 then f.Visible = false; return end
    f.Size = UDim2.fromOffset(len, thickness); f.Position = UDim2.fromOffset((p1.X + p2.X) / 2, (p1.Y + p2.Y) / 2)
    f.Rotation = math.deg(math.atan2(delta.Y, delta.X)); f.BackgroundColor3 = color; f.Visible = true
end
local function createEntry()
    local e = { Bones = {} }
    e.Box = new("Frame", { BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false }, Overlay); e.Stroke = new("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, e.Box)
    e.Fill = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 0.7, BorderSizePixel = 0, Visible = false }, e.Box)
    e.Label = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(240, 20), AnchorPoint = Vector2.new(0.5, 1), Font = Enum.Font.GothamBold, TextStrokeTransparency = 0.4, Visible = false }, Overlay)
    e.HealthBack = new("Frame", { BackgroundColor3 = Color3.fromRGB(15, 20, 28), BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0), Visible = false }, Overlay); corner(e.HealthBack, 2)
    e.HealthFill = new("Frame", { BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Visible = false }, e.HealthBack); corner(e.HealthFill, 2)
    e.HeadDot = new("Frame", { Size = UDim2.fromOffset(6, 6), AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, Visible = false }, Overlay); corner(e.HeadDot, 3)
    e.Tracer = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, Visible = false }, Overlay)
    return e
end
local function hideEntry(e)
    e.Box.Visible = false; e.Label.Visible = false; e.HealthBack.Visible = false; e.Tracer.Visible = false; e.HeadDot.Visible = false
    for _, b in ipairs(e.Bones) do b.Visible = false end
end
local function destroyEntry(e)
    e.Box:Destroy(); e.Label:Destroy(); e.HealthBack:Destroy(); e.Tracer:Destroy(); e.HeadDot:Destroy()
    for _, b in ipairs(e.Bones) do b:Destroy() end
end

local function projectBox(cam, cf, size)
    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge; local any = false
    for ix = -1, 1, 2 do for iy = -1, 1, 2 do for iz = -1, 1, 2 do
        local c3 = cf:PointToWorldSpace(Vector3.new(ix * size.X / 2, iy * size.Y / 2, iz * size.Z / 2))
        local sp = cam:WorldToViewportPoint(c3)
        if sp.Z > 0 then any = true; minX = math.min(minX, sp.X); maxX = math.max(maxX, sp.X); minY = math.min(minY, sp.Y); maxY = math.max(maxY, sp.Y) end
    end end end
    if not any then return nil end
    local w, h = maxX - minX, maxY - minY
    if w > 800 or h > 800 or w <= 0 or h <= 0 then return nil end
    if minX < -1000 or maxX > 1000 or minY < -1000 or maxY > 1000 then return nil end
    return Vector2.new(minX, minY), Vector2.new(maxX, maxY)
end

local BONES_R15 = {{"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"}, {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"}, {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"}, {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"}, {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}}
local BONES_R6 = {{"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"}, {"Torso", "Left Leg"}, {"Torso", "Right Leg"}}

local function updateEntry(e, cam, npc, dist, o)
    local cf, size = npc.Model:GetBoundingBox()
    if not cf or not size then hideEntry(e); return end
    local tl, br = projectBox(cam, cf, size)
    if not tl then hideEntry(e); return end
    local w, h = br.X - tl.X, br.Y - tl.Y
    local isEnemy = true 
    local modelTeam = npc.Model:FindFirstChild("Team")
    local playerObj = Players:GetPlayerFromCharacter(npc.Model)
    local targetTeam = (playerObj and playerObj.Team) or (modelTeam and modelTeam.Value)
    if targetTeam and Player.Team and targetTeam == Player.Team then isEnemy = false end
    local color = isEnemy and o.colorEnemy or o.colorFriendly
    if not isEnemy and o.teamCheck then hideEntry(e); return end

    if o.box then
        e.Box.Position = UDim2.fromOffset(tl.X, tl.Y); e.Box.Size = UDim2.fromOffset(w, h)
        e.Stroke.Color = color; e.Stroke.Thickness = o.thickness; e.Box.Visible = true
        e.Stroke.Transparency = o.boxStyle == "Full" and 0 or 1
        e.Fill.Visible = o.fill
        if o.fill then e.Fill.BackgroundColor3 = color; e.Fill.BackgroundTransparency = 0.7 end
    else e.Box.Visible = false end

    local parts = {}
    if o.name then table.insert(parts, npc.Model.Name) end
    if o.dist then table.insert(parts, string.format("[%d]", dist)) end
    if o.healthnum then table.insert(parts, string.format("(%d HP)", math.floor(npc.Humanoid.Health))) end
    if #parts > 0 then
        e.Label.Text = table.concat(parts, " "); e.Label.TextSize = o.textSize; e.Label.TextColor3 = color
        local yPos = o.pos == "Top" and tl.Y - 2 or br.Y + 2
        e.Label.Position = UDim2.fromOffset((tl.X + br.X) / 2, yPos); e.Label.AnchorPoint = Vector2.new(0.5, o.pos == "Top" and 1 or 0); e.Label.Visible = true
    else e.Label.Visible = false end

    if o.health and npc.Humanoid.MaxHealth > 0 then
        local frac = math.clamp(npc.Humanoid.Health / npc.Humanoid.MaxHealth, 0, 1)
        e.HealthBack.Position = UDim2.fromOffset(tl.X - 5, tl.Y); e.HealthBack.Size = UDim2.fromOffset(o.thickness + 1, h)
        e.HealthFill.Size = UDim2.new(1, 0, frac, 0); e.HealthFill.BackgroundColor3 = Color3.fromRGB(255, 60, 60):Lerp(Color3.fromRGB(60, 235, 90), frac)
        e.HealthBack.Visible = true; e.HealthFill.Visible = true
    else e.HealthBack.Visible = false end

    if o.headdot then
        local head = npc.Model:FindFirstChild("Head")
        if head then local sp = cam:WorldToViewportPoint(head.Position); if sp.Z > 0 then e.HeadDot.Position = UDim2.fromOffset(sp.X, sp.Y); e.HeadDot.BackgroundColor3 = color; e.HeadDot.Visible = true end else e.HeadDot.Visible = false end
    else e.HeadDot.Visible = false end

    if o.tracer then
        local foot = Vector2.new((tl.X + br.X) / 2, br.Y); local screenCenter = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
        if tl.X > 0 and br.X < cam.ViewportSize.X and tl.Y > 0 and br.Y < cam.ViewportSize.Y then placeLine(e.Tracer, screenCenter, foot, o.thickness, color) else e.Tracer.Visible = false end
    else e.Tracer.Visible = false end

    if o.skeleton then
        local bones = npc.Humanoid.RigType == Enum.HumanoidRigType.R15 and BONES_R15 or BONES_R6
        for i, pair in ipairs(bones) do
            local line = e.Bones[i]
            if not line then line = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, Visible = false }, Overlay); e.Bones[i] = line end
            local a = npc.Model:FindFirstChild(pair[1]); local b = npc.Model:FindFirstChild(pair[2])
            if a and b and a:IsA("BasePart") and b:IsA("BasePart") then
                local sa = cam:WorldToViewportPoint(a.Position); local sb = cam:WorldToViewportPoint(b.Position)
                if sa.Z > 0 and sb.Z > 0 then placeLine(line, Vector2.new(sa.X, sa.Y), Vector2.new(sb.X, sb.Y), o.thickness, color) else line.Visible = false end
            else line.Visible = false end
        end
    else for _, b in ipairs(e.Bones) do b.Visible = false end end
end

local function espStep()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    if not pref("esp.enabled", false) then for _, e in pairs(entries) do destroyEntry(e) end; entries = {}; return end
    local o = {
        box = pref("esp.el.box", false) == true, boxStyle = pref("esp.el.boxstyle", "Full"), fill = pref("esp.el.fill", false) == true,
        name = pref("esp.el.name", false) == true, dist = pref("esp.el.dist", false) == true, health = pref("esp.el.health", false) == true,
        healthnum = pref("esp.el.healthnum", false) == true, headdot = pref("esp.el.headdot", false) == true,
        skeleton = pref("esp.el.skeleton", false) == true, tracer = pref("esp.el.tracer", false) == true,
        pos = pref("esp.el.pos", "Top"), thickness = prefNum("esp.el.thick", 1.5), textSize = prefNum("esp.text", 13),
        teamCheck = pref("esp.team", true) == true, colorEnemy = ESP_COLORS[pref("esp.col.enemy", "Red")] or ESP_COLORS.Red, colorFriendly = ESP_COLORS[pref("esp.col.friendly", "Green")] or ESP_COLORS.Green,
    }
    local anyOn = o.box or o.name or o.dist or o.health or o.headdot or o.tracer or o.skeleton
    local set = targetSet(); local seen = {}
    if anyOn then
        local camPos = cam.CFrame.Position; local maxDist = prefNum("esp.maxdist", 2000)
        for model in pairs(set) do
            local npc = readNpc(model)
            if npc then
                local dist = (npc.Root.Position - camPos).Magnitude
                local sp = cam:WorldToViewportPoint(npc.Root.Position)
                if dist <= maxDist and sp.Z > 0 then seen[model] = true; local e = entries[model] or createEntry(); entries[model] = e; updateEntry(e, cam, npc, dist, o) end
            end
        end
    end
    for model, e in pairs(entries) do
        if not set[model] or not model.Parent then destroyEntry(e); entries[model] = nil
        elseif not seen[model] then hideEntry(e) end
    end
end

-- No Cooldown
task.spawn(function()
    while task.wait(0.1) do
        if pref("gun.cooldown", false) and Player.Character then
            for _, tool in pairs(Player.Character:GetChildren()) do
                if tool:IsA("Tool") then
                    for _, v in pairs(tool:GetDescendants()) do
                        if v:IsA("NumberValue") and (v.Name:lower():find("cooldown") or v.Name:lower():find("firerate") or v.Name:lower():find("delay")) then v.Value = 0 end
                    end
                end
            end
        end
    end
end)

-- HUD
local Hud = new("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 8), Size = UDim2.fromOffset(0, 26), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = P.title, BorderSizePixel = 0}, GUI)
corner(Hud, 13); outline(Hud, 2, P.text); new("UIPadding", {PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14)}, Hud)
local HudText = label(Hud, {Size = UDim2.fromOffset(0, 26), AutomaticSize = Enum.AutomaticSize.X, Text = "", TextColor3 = P.white, TextSize = 12})
local statusTimer, fps, startClock = 0, 60, os.clock()

local function statusStep(dt)
    statusTimer += dt; if statusTimer < 0.4 then return end; statusTimer = 0
    local n = 0; for model in pairs(targetSet()) do if readNpc(model) then n += 1 end end
    targetCount = n; updateInfos()
    local scale = prefNum("set.uiscale", 100) / 100
    if UIScale.Scale ~= scale then tween(UIScale, {Scale = scale}) end
    Hud.Visible = pref("ui.hud", true) == true and pref("set.watermark", true) == true
    if Hud.Visible then
        local t = math.floor(os.clock() - startClock); local ping = "44ms"
        pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5) .. "ms" end)
        HudText.Text = string.format("SONIC HUB  |  FPS %d  |  PING %s  |  TIME %02d:%02d", math.floor(fps + 0.5), ping, math.floor(t / 60), t % 60)
    end
end

-- ============================================================
-- SILENT AIM HOOK & CLEANUP & LOOP
-- ============================================================
connect(UserInputService.InputBegan, function(input, processed)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and not processed and pref("sil.enabled", false) then
        local hit = silentAim()
        if hit then
            local cam = Workspace.CurrentCamera
            local oldType, oldCF = cam.CameraType, cam.CFrame
            cam.CameraType = Enum.CameraType.Scriptable
            cam.CFrame = CFrame.lookAt(cam.CFrame.Position, hit.Position)
            pcall(function()
                if type(genv().mouse1click) == "function" then genv().mouse1click()
                else VirtualUser:CaptureController(); VirtualUser:Button1Down(Vector2.new(0,0)); VirtualUser:Button1Up(Vector2.new(0,0)) end
            end)
            cam.CFrame = oldCF; cam.CameraType = oldType
        end
    end
end)

local cleaned = false
local function cleanup()
    if cleaned then return end; cleaned = true
    if shared.AFG_Cleanup == cleanup then shared.AFG_Cleanup = nil end
    for _, c in ipairs(connections) do c:Disconnect() end
    for model, e in pairs(entries) do destroyEntry(e); entries[model] = nil end
    Overlay:Destroy(); if GUI.Parent then GUI:Destroy() end
end
shared.AFG_Cleanup = cleanup; connect(GUI.Destroying, cleanup)

local reported = {}
local function guarded(tag, fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok and not reported[tag] then reported[tag] = true; warn("[Sonic Hub] " .. tag .. " error: " .. tostring(err)) end
end

RunService:BindToRenderStep("AFG_Main", Enum.RenderPriority.Camera.Value + 1, function(dt)
    if not GUI.Parent then cleanup(); return end
    fps = fps * 0.9 + (1 / math.max(dt, 1e-4)) * 0.1
    guarded("aimbot", aimbotStep, dt)
    guarded("trigger", triggerStep)
    guarded("esp", espStep)
    guarded("status", statusStep, dt)
end)

GUI.Enabled = true
task.wait(0.4)
showPage("Main")
print("[Sonic Hub] V18 Carregado. Tela de load animada e UI consertada.")
