-- ECLYPSE HUB | UI SAFE EDITION
-- Autor: Finalsher
-- Interface visual independente. Nao inclui aimbot, silent aim, triggerbot,
-- weapon hooks, exploits ou alteracoes de movimento em jogos de terceiros.
-- Pode ser usada como base visual em uma experiencia propria/Roblox Studio.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Evita duplicar a interface ao executar novamente.
for _, parent in ipairs({PlayerGui, CoreGui}) do
    local old = parent:FindFirstChild("ECLYPSE")
    if old then old:Destroy() end
end

local ACCENTS = {
    Red = Color3.fromRGB(255, 42, 76),
    Pink = Color3.fromRGB(255, 55, 145),
    Purple = Color3.fromRGB(160, 90, 255),
    Blue = Color3.fromRGB(65, 145, 255),
    Cyan = Color3.fromRGB(50, 220, 220),
    Green = Color3.fromRGB(75, 220, 145),
    Orange = Color3.fromRGB(255, 145, 55),
    White = Color3.fromRGB(235, 235, 245),
}

local Theme = {
    Background = Color3.fromRGB(5, 5, 8),
    Panel = Color3.fromRGB(13, 13, 18),
    Card = Color3.fromRGB(21, 21, 28),
    Stroke = Color3.fromRGB(43, 43, 54),
    Text = Color3.fromRGB(245, 245, 250),
    Muted = Color3.fromRGB(145, 145, 160),
    Accent = ACCENTS.Red,
}

local function make(className, props, parent)
    local obj = Instance.new(className)
    for key, value in pairs(props or {}) do obj[key] = value end
    obj.Parent = parent
    return obj
end

local function round(obj, radius)
    make("UICorner", {CornerRadius = UDim.new(0, radius or 8)}, obj)
end

local function stroke(obj, color, thickness)
    return make("UIStroke", {
        Color = color or Theme.Stroke,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    }, obj)
end

local function label(parent, text, size, position, fontSize, color, font)
    return make("TextLabel", {
        BackgroundTransparency = 1,
        Text = text,
        Size = size,
        Position = position,
        Font = font or Enum.Font.Gotham,
        TextSize = fontSize or 13,
        TextColor3 = color or Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center
    }, parent)
end

local function tween(obj, duration, properties, style)
    local tw = TweenService:Create(obj, TweenInfo.new(
        duration, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out
    ), properties)
    tw:Play()
    return tw
end

local gui = make("ScreenGui", {
    Name = "ECLYPSE",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 500
}, PlayerGui)

-- Loading inspirado no segundo video: tela escura, marca central e brilho pulsante.
local loading = make("Frame", {
    Name = "Loading",
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
    BorderSizePixel = 0
}, gui)

local glow = make("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.46),
    Size = UDim2.fromOffset(170, 170),
    BackgroundColor3 = Theme.Accent,
    BackgroundTransparency = 0.88
}, loading)
round(glow, 100)

local logo = label(loading, "ECLYPSE", UDim2.fromOffset(360, 62),
    UDim2.new(0.5, -180, 0.5, -42), 42, Theme.Text, Enum.Font.GothamBlack)
logo.TextXAlignment = Enum.TextXAlignment.Center
local logoStroke = stroke(logo, Theme.Accent, 1.2)
logoStroke.Transparency = 0.15

local sub = label(loading, "INITIALIZING INTERFACE", UDim2.fromOffset(300, 22),
    UDim2.new(0.5, -150, 0.5, 20), 10, Theme.Muted, Enum.Font.GothamMedium)
sub.TextXAlignment = Enum.TextXAlignment.Center
sub.TextTransparency = 0.15

local barBack = make("Frame", {
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0.5, 65),
    Size = UDim2.fromOffset(190, 3),
    BackgroundColor3 = Color3.fromRGB(35, 35, 42),
    BorderSizePixel = 0
}, loading)
round(barBack, 4)
local barFill = make("Frame", {
    Size = UDim2.fromScale(0, 1),
    BackgroundColor3 = Theme.Accent,
    BorderSizePixel = 0
}, barBack)
round(barFill, 4)

local pulseAlive = true
task.spawn(function()
    while pulseAlive and loading.Parent do
        tween(glow, 1.1, {BackgroundTransparency = 0.94, Size = UDim2.fromOffset(205, 205)})
        tween(logo, 1.1, {TextColor3 = Theme.Accent})
        task.wait(1.1)
        if not pulseAlive then break end
        tween(glow, 1.1, {BackgroundTransparency = 0.84, Size = UDim2.fromOffset(170, 170)})
        tween(logo, 1.1, {TextColor3 = Theme.Text})
        task.wait(1.1)
    end
end)

tween(barFill, 1.65, {Size = UDim2.fromScale(1, 1)}, Enum.EasingStyle.Quad)
task.wait(1.8)
pulseAlive = false
tween(loading, 0.35, {BackgroundTransparency = 1})
for _, child in ipairs(loading:GetChildren()) do
    if child:IsA("GuiObject") then
        pcall(function() tween(child, 0.25, {BackgroundTransparency = 1, TextTransparency = 1}) end)
    end
end
task.wait(0.4)
loading:Destroy()

-- Hub principal
local main = make("Frame", {
    Name = "Main",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.52),
    Size = UDim2.fromOffset(690, 440),
    BackgroundColor3 = Theme.Background,
    BorderSizePixel = 0
}, gui)
round(main, 12)
stroke(main, Theme.Accent, 1.5)

local top = make("Frame", {
    Size = UDim2.new(1, 0, 0, 54),
    BackgroundColor3 = Theme.Panel,
    BorderSizePixel = 0
}, main)
round(top, 12)
make("Frame", {
    Position = UDim2.new(0, 0, 1, -12),
    Size = UDim2.new(1, 0, 0, 12),
    BackgroundColor3 = Theme.Panel,
    BorderSizePixel = 0
}, top)
make("Frame", {
    Position = UDim2.new(0, 18, 1, -2),
    Size = UDim2.new(1, -36, 0, 2),
    BackgroundColor3 = Theme.Accent,
    BorderSizePixel = 0
}, top)

label(top, "ECLYPSE", UDim2.fromOffset(190, 30), UDim2.fromOffset(20, 5),
    21, Theme.Accent, Enum.Font.GothamBlack)
label(top, "HUB  /  FINALSher", UDim2.fromOffset(220, 18),
    UDim2.fromOffset(21, 31), 9, Theme.Muted, Enum.Font.GothamMedium)

local close = make("TextButton", {
    Size = UDim2.fromOffset(30, 30),
    Position = UDim2.new(1, -42, 0, 12),
    BackgroundColor3 = Theme.Card,
    Text = "×",
    TextColor3 = Theme.Muted,
    TextSize = 20,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false
}, top)
round(close, 7)

local minimize = make("TextButton", {
    Size = UDim2.fromOffset(30, 30),
    Position = UDim2.new(1, -80, 0, 12),
    BackgroundColor3 = Theme.Card,
    Text = "—",
    TextColor3 = Theme.Muted,
    TextSize = 17,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false
}, top)
round(minimize, 7)

-- Mini painel sobreposto, mantido acima da janela principal.
local mini = make("Frame", {
    Name = "InfoPill",
    AnchorPoint = Vector2.new(0.5, 1),
    Position = UDim2.new(0.5, 0, 0, -9),
    Size = UDim2.fromOffset(285, 30),
    BackgroundColor3 = Color3.fromRGB(10, 10, 14),
    BorderSizePixel = 0,
    ZIndex = 20
}, main)
round(mini, 8)
stroke(mini, Theme.Accent, 1)
local miniText = label(mini, "ECLYPSE  •  Finalsher  •  Discord: discord.gg/YyV2WkWTKc",
    UDim2.new(1, -16, 1, 0), UDim2.fromOffset(8, 0), 9, Theme.Text, Enum.Font.GothamMedium)
miniText.TextXAlignment = Enum.TextXAlignment.Center
miniText.ZIndex = 21

local sidebar = make("Frame", {
    Position = UDim2.fromOffset(14, 68),
    Size = UDim2.fromOffset(145, 355),
    BackgroundColor3 = Theme.Panel,
    BorderSizePixel = 0
}, main)
round(sidebar, 9)
stroke(sidebar, Theme.Stroke, 1)

local content = make("Frame", {
    Position = UDim2.fromOffset(171, 68),
    Size = UDim2.fromOffset(505, 355),
    BackgroundColor3 = Theme.Panel,
    BorderSizePixel = 0
}, main)
round(content, 9)
stroke(content, Theme.Stroke, 1)

local pageTitle = label(content, "VISUAL", UDim2.new(1, -30, 0, 28),
    UDim2.fromOffset(16, 12), 16, Theme.Accent, Enum.Font.GothamBold)
local pageHint = label(content, "Interface e preferencias do ECLYPSE.",
    UDim2.new(1, -30, 0, 20), UDim2.fromOffset(16, 39), 11, Theme.Muted)

local pageBody = make("Frame", {
    Position = UDim2.fromOffset(16, 72),
    Size = UDim2.new(1, -32, 1, -86),
    BackgroundTransparency = 1
}, content)

local function clearBody()
    for _, child in ipairs(pageBody:GetChildren()) do child:Destroy() end
end

local function makeSection(text)
    return label(pageBody, text, UDim2.new(1, 0, 0, 24),
        UDim2.fromOffset(0, 0), 12, Theme.Text, Enum.Font.GothamBold)
end

local function makeColorButton(name, color, x, y, callback)
    local b = make("TextButton", {
        Position = UDim2.fromOffset(x, y),
        Size = UDim2.fromOffset(105, 34),
        BackgroundColor3 = Theme.Card,
        Text = name,
        TextColor3 = Theme.Text,
        TextSize = 11,
        Font = Enum.Font.GothamMedium,
        AutoButtonColor = false
    }, pageBody)
    round(b, 7)
    local swatch = make("Frame", {
        Position = UDim2.fromOffset(8, 9),
        Size = UDim2.fromOffset(16, 16),
        BackgroundColor3 = color,
        BorderSizePixel = 0
    }, b)
    round(swatch, 5)
    b.TextXAlignment = Enum.TextXAlignment.Center
    b.MouseButton1Click:Connect(function() callback(color) end)
    return b
end

local function applyAccent(color)
    Theme.Accent = color
    logoStroke.Color = color
    glow.BackgroundColor3 = color
    barFill.BackgroundColor3 = color
    stroke(main, color, 1.5)
    -- Atualiza elementos principais existentes.
    for _, obj in ipairs(gui:GetDescendants()) do
        if obj:IsA("UIStroke") and obj.Parent ~= mini then
            if obj.Color == ACCENTS.Red or obj.Color == Theme.Stroke then
                -- Mantem bordas neutras; apenas bordas de destaque sao atualizadas abaixo.
            end
        end
    end
    pageTitle.TextColor3 = color
    mini:FindFirstChildOfClass("UIStroke").Color = color
    top:FindFirstChildWhichIsA("Frame").BackgroundColor3 = Theme.Panel
end

local function showVisualPage()
    pageTitle.Text = "VISUAL"
    pageHint.Text = "Preferencias da interface."
    clearBody()
    makeSection("COR DE DESTAQUE")
    local names = {"Red", "Pink", "Purple", "Blue", "Cyan", "Green", "Orange", "White"}
    for i, name in ipairs(names) do
        local col = (i - 1) % 4
        local row = math.floor((i - 1) / 4)
        makeColorButton(name, ACCENTS[name], col * 116, 34 + row * 44, applyAccent)
    end
    label(pageBody, "O fundo permanece preto; escolha a cor dos detalhes.",
        UDim2.new(1, 0, 0, 24), UDim2.fromOffset(0, 142), 10, Theme.Muted)
end

local function showInfoPage()
    pageTitle.Text = "INFORMACOES"
    pageHint.Text = "Creditos e comunidade."
    clearBody()
    makeSection("ECLYPSE HUB")
    label(pageBody, "Autor: Finalsher", UDim2.new(1, 0, 0, 24),
        UDim2.fromOffset(0, 34), 12, Theme.Text)
    label(pageBody, "Discord: discord.gg/YyV2WkWTKc", UDim2.new(1, 0, 0, 24),
        UDim2.fromOffset(0, 62), 12, Theme.Text)
    local copy = make("TextButton", {
        Position = UDim2.fromOffset(0, 100),
        Size = UDim2.fromOffset(160, 34),
        BackgroundColor3 = Theme.Card,
        Text = "COPIAR CONVITE",
        TextColor3 = Theme.Text,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false
    }, pageBody)
    round(copy, 7)
    copy.MouseButton1Click:Connect(function()
        if setclipboard then
            pcall(setclipboard, "https://discord.gg/YyV2WkWTKc")
            copy.Text = "COPIADO"
        else
            copy.Text = "DISCORD: YyV2WkWTKc"
        end
    end)
end

local pages = {
    {name = "Visuais", build = showVisualPage},
    {name = "Informacoes", build = showInfoPage}
}
local currentPage = 1

local function selectPage(index)
    currentPage = index
    for i, child in ipairs(sidebar:GetChildren()) do
        if child:IsA("TextButton") then
            child.BackgroundColor3 = (i == index) and Theme.Card or Theme.Panel
            child.TextColor3 = (i == index) and Theme.Accent or Theme.Muted
        end
    end
    pages[index].build()
end

for i, page in ipairs(pages) do
    local btn = make("TextButton", {
        Position = UDim2.fromOffset(8, 10 + (i - 1) * 43),
        Size = UDim2.new(1, -16, 0, 35),
        BackgroundColor3 = Theme.Panel,
        Text = "   " .. page.name,
        TextColor3 = Theme.Muted,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false
    }, sidebar)
    round(btn, 7)
    btn.MouseButton1Click:Connect(function() selectPage(i) end)
end

label(main, "ECLYPSE  •  UI BUILD  •  FINALSher",
    UDim2.fromOffset(260, 14), UDim2.new(1, -274, 1, -18),
    8, Theme.Muted, Enum.Font.GothamMedium)

selectPage(1)

-- Arrastar janela pela barra superior.
local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
top.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

top.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

local dragConnection = UserInputService.InputChanged:Connect(function(input)
    if dragging and (input == dragInput or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local minimized = false
local oldSize = main.Size
minimize.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        oldSize = main.Size
        sidebar.Visible = false
        content.Visible = false
        mini.Visible = false
        tween(main, 0.2, {Size = UDim2.fromOffset(250, 54)})
        minimize.Text = "+"
    else
        tween(main, 0.2, {Size = oldSize})
        task.delay(0.21, function()
            if main.Parent then
                sidebar.Visible = true
                content.Visible = true
                mini.Visible = true
            end
        end)
        minimize.Text = "—"
    end
end)

local function cleanup()
    pulseAlive = false
    if dragConnection then dragConnection:Disconnect() end
    if gui then gui:Destroy() end
end

close.MouseButton1Click:Connect(cleanup)

-- Atalho de visibilidade; nao interfere com camera ou controles do jogo.
local keyConnection = UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.RightShift and gui.Parent then
        main.Visible = not main.Visible
    end
end)

gui.Destroying:Connect(function()
    pulseAlive = false
    if dragConnection then dragConnection:Disconnect() end
    if keyConnection then keyConnection:Disconnect() end
end)

print("[ECLYPSE] Interface carregada | Finalsher")
