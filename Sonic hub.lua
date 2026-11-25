--[[
    SONIC HUB V19 - NEON EDITION
    Arquitetura Modular (Client / Shared / Server Mock)
    Design: Glassmorphism, Neon, Tween Animations.
--]]

-- ============================================================
-- [ SHARED SERVICES ]
-- ============================================================
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
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ============================================================
-- [ CONFIGURAÇÕES GERAIS ]
-- ============================================================
local Config = {
    MenuKey = Enum.KeyCode.RightShift,
    MaxBoxPixels = 800,
    WinW = 720, WinH = 560, TitleH = 50, FooterH = 20,
    Theme = {
        Background = Color3.fromRGB(15, 18, 30),
        Surface = Color3.fromRGB(25, 30, 48),
        SurfaceHover = Color3.fromRGB(35, 42, 65),
        Accent = Color3.fromRGB(0, 200, 255), -- Azul Neon Sonic
        AccentDark = Color3.fromRGB(0, 120, 180),
        Text = Color3.fromRGB(240, 248, 255),
        SubText = Color3.fromRGB(150, 165, 190),
        Success = Color3.fromRGB(0, 255, 150),
        Danger = Color3.fromRGB(255, 60, 80),
        Stroke = Color3.fromRGB(60, 80, 120),
        Shadow = Color3.fromRGB(0, 0, 0)
    }
}

if shared.SonicHubCleanup then pcall(shared.SonicHubCleanup) end
for _, n in ipairs({"SonicHubV19", "SonicHubOverlayV19", "SonicHubLoadingV19"}) do
    local o = PlayerGui:FindFirstChild(n); if o then o:Destroy() end
    local c = CoreGui:FindFirstChild(n); if c then c:Destroy() end
end

-- ============================================================
-- [ MÓDULO 1: UTILITÁRIOS E RENDERIZAÇÃO UI ]
-- ============================================================
local UI = {}
UI.Connections = {}
UI.ActiveSlider = nil

function UI.Create(Class, Props, Parent)
    local Inst = Instance.new(Class)
    for k, v in pairs(Props) do Inst[k] = v end
    if Parent then Inst.Parent = Parent end
    return Inst
end

function UI.Corner(Inst, Radius)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, Radius); c.Parent = Inst; return c
end

function UI.Stroke(Inst, Thickness, Color)
    local s = Instance.new("UIStroke"); s.Thickness = Thickness or 1; s.Color = Color or Config.Theme.Stroke; s.Parent = Inst; return s
end

function UI.Shadow(Inst)
    local s = Instance.new("ImageLabel")
    s.Name = "Shadow"
    s.Image = "rbxassetid://1316045217"
    s.ImageColor3 = Config.Theme.Shadow
    s.ImageTransparency = 0.6
    s.ScaleType = Enum.ScaleType.Slice
    s.SliceCenter = Rect.new(10, 10, 118, 118)
    s.Size = UDim2.new(1, 20, 1, 20)
    s.Position = UDim2.new(0, -10, 0, -10)
    s.ZIndex = 0
    s.Parent = Inst
    return s
end

function UI.Tween(Inst, Props, Time, Style)
    TweenService:Create(Inst, TweenInfo.new(Time or 0.25, Style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out), Props):Play()
end

-- ============================================================
-- [ MÓDULO 2: TELA DE LOADING (Sonic 2D Neon) ]
-- ============================================================
local LoadingGui = UI.Create("ScreenGui", {Name = "SonicHubLoadingV19", DisplayOrder = 999, IgnoreGuiInset = true}, PlayerGui)
local LoadFrame = UI.Create("Frame", {Size = UDim2.fromOffset(450, 250), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Config.Theme.Background, ClipsDescendants = true}, LoadingGui)
UI.Corner(LoadFrame, 16); UI.Stroke(LoadFrame, 3, Config.Theme.Accent); UI.Shadow(LoadFrame)

-- Cenário
local track = UI.Create("Frame", {Size = UDim2.new(1, 0, 0, 80), Position = UDim2.new(0, 0, 1, -80), BackgroundColor3 = Color3.fromRGB(20, 25, 35)}, LoadFrame)
local neonLine = UI.Create("Frame", {Size = UDim2.new(1, 0, 0, 4), Position = UDim2.fromScale(0, 0), BackgroundColor3 = Config.Theme.Accent}, track)

-- Sonic Simplificado
local sonic = UI.Create("Frame", {Size = UDim2.fromOffset(40, 40), Position = UDim2.new(0.2, 0, 1, -120), BackgroundTransparency = 1}, LoadFrame)
local sBody = UI.Create("Frame", {Size = UDim2.fromOffset(30, 30), BackgroundColor3 = Config.Theme.Accent, BorderSizePixel = 0}, sonic); UI.Corner(sBody, 15)
local sShoe = UI.Create("Frame", {Size = UDim2.fromOffset(20, 10), Position = UDim2.fromOffset(-5, 28), BackgroundColor3 = Config.Theme.Danger}, sonic); UI.Corner(sShoe, 5)

-- Rastro Neon
local trail = UI.Create("Frame", {Size = UDim2.fromOffset(80, 20), Position = UDim2.fromOffset(-70, 15), BackgroundColor3 = Config.Theme.Accent, BackgroundTransparency = 0.5}, sonic)
UI.Corner(trail, 10)
local trailGrad = UI.Create("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.5)})}, trail)

-- Textos e Barra
local loadText = UI.Create("TextLabel", {Size = UDim2.new(1, 0, 0, 30), Position = UDim2.new(0, 0, 0.2, 0), Text = "TREX HUB V19 - INICIANDO...", Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = Config.Theme.Text, BackgroundTransparency = 1}, LoadFrame)
local barBg = UI.Create("Frame", {Size = UDim2.fromOffset(300, 8), Position = UDim2.new(0.5, 0, 0.85, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Config.Theme.Surface}, LoadFrame)
UI.Corner(barBg, 4)
local barFill = UI.Create("Frame", {Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Config.Theme.Accent}, barBg)
UI.Corner(barFill, 4)

-- Loop de Load
local progress = 0
local isRunning = true
task.spawn(function()
    while isRunning do
        local dt = task.wait(0.03)
        sonic.Position = UDim2.new(0.2, 0, 1, -120 + math.sin(os.clock() * 10) * 5)
        trail.Size = UDim2.fromOffset(80 + math.sin(os.clock() * 8) * 10, 20)
    end
end)

task.spawn(function()
    while progress < 100 do
        progress = math.min(progress + math.random(2, 6), 100)
        UI.Tween(barFill, {Size = UDim2.new(progress / 100, 0, 1, 0)})
        task.wait(0.05)
    end
    isRunning = false
    task.wait(0.3)
    UI.Tween(LoadFrame, {BackgroundTransparency = 1}, 0.4)
    for _, v in ipairs(LoadFrame:GetDescendants()) do
        pcall(function() 
            if v:IsA("GuiObject") then UI.Tween(v, {BackgroundTransparency = 1}, 0.4) end
            if v:IsA("TextLabel") then UI.Tween(v, {TextTransparency = 1}, 0.4) end
        end)
    end
    task.wait(0.5)
    LoadingGui:Destroy()
end)

-- ============================================================
-- [ MÓDULO 3: INTERFACE PRINCIPAL (Neon Glass) ]
-- ============================================================
local GUI = UI.Create("ScreenGui", {Name = "SonicHubV19", ResetOnSpawn = false, DisplayOrder = 10, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Enabled = false}, PlayerGui)
local Overlay = UI.Create("ScreenGui", {Name = "SonicHubOverlayV19", ResetOnSpawn = false, DisplayOrder = 5, IgnoreGuiInset = true}, PlayerGui)

local Main = UI.Create("Frame", {Name = "Main", Size = UDim2.fromOffset(Config.WinW, Config.WinH), Position = UDim2.new(0.5, -Config.WinW / 2, 0.5, -Config.WinH / 2), BackgroundColor3 = Config.Theme.Background, ClipsDescendants = true}, GUI)
UI.Corner(Main, 14); UI.Stroke(Main, 2, Config.Theme.Stroke); UI.Shadow(Main)
local UIScale = UI.Create("UIScale", {Scale = 1}, Main)

-- Top Bar (Glass)
local TopBar = UI.Create("Frame", {Size = UDim2.new(1, 0, 0, Config.TitleH), BackgroundColor3 = Config.Theme.Surface, BorderSizePixel = 0}, Main)
UI.Corner(TopBar, 14)
UI.Create("Frame", {Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0, 0, 1, -14), BackgroundColor3 = Config.Theme.Surface, BorderSizePixel = 0}, TopBar)
UI.Create("Frame", {Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, -2), BackgroundColor3 = Config.Theme.Accent, BorderSizePixel = 0}, TopBar)

local titleLabel = UI.Create("TextLabel", {Size = UDim2.fromOffset(200, Config.TitleH), Position = UDim2.fromOffset(20, 0), Text = "SONIC HUB V19", Font = Enum.Font.GothamBlack, TextSize = 20, TextColor3 = Config.Theme.Text, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left}, TopBar)
local closeBtn = UI.Create("TextButton", {Size = UDim2.fromOffset(30, 30), Position = UDim2.new(1, -40, 0.5, -15), BackgroundColor3 = Config.Theme.Danger, Text = "x", TextColor3 = Config.Theme.Text, Font = Enum.Font.GothamBlack, TextSize = 16, AutoButtonColor = false}, TopBar)
UI.Corner(closeBtn, 8)
closeBtn.MouseButton1Click:Connect(function() GUI:Destroy() end)

-- Body
local Body = UI.Create("Frame", {Position = UDim2.fromOffset(0, Config.TitleH), Size = UDim2.fromOffset(Config.WinW, Config.WinH - Config.TitleH), BackgroundTransparency = 1}, Main)
local Sidebar = UI.Create("Frame", {Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(170, Config.WinH - Config.TitleH - 20), BackgroundColor3 = Config.Theme.Surface, BorderSizePixel = 0}, Body)
UI.Corner(Sidebar, 10); UI.Stroke(Sidebar, 1, Config.Theme.Stroke)
local NavList = UI.Create("ScrollingFrame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y}, Sidebar)
local navLayout = UI.Create("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, NavList)
UI.Create("UIPadding", {PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}, NavList)

local Content = UI.Create("Frame", {Position = UDim2.fromOffset(190, 10), Size = UDim2.fromOffset(Config.WinW - 200, Config.WinH - Config.TitleH - 20), BackgroundTransparency = 1}, Body)
local PageTitle = UI.Create("TextLabel", {Size = UDim2.new(1, 0, 0, 30), Text = "AIMBOT", Font = Enum.Font.GothamBlack, TextSize = 22, TextColor3 = Config.Theme.Text, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left}, Content)
local ScrollArea = UI.Create("ScrollingFrame", {Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, 0, 1, -40), BackgroundTransparency = 1, ScrollBarThickness = 4, ScrollBarImageColor3 = Config.Theme.Accent, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y}, Content)
local areaLayout = UI.Create("UIListLayout", {Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder}, ScrollArea)

-- ============================================================
-- [ MÓDULO 4: COMPONENTES UI (Toggles, Sliders, Botões) ]
-- ============================================================
local Preferences = {}
local UI_Updates = {}
local captureBind = nil

local function CreateToggle(parent, Name, Key, BindKey, Default)
    Preferences[Key] = Preferences[Key] or Default
    
    local Frame = UI.Create("Frame", {Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Config.Theme.Surface, BorderSizePixel = 0}, parent)
    UI.Corner(Frame, 8)
    UI.Create("TextLabel", {Size = UDim2.new(1, -120, 1, 0), Position = UDim2.fromOffset(12, 0), Text = Name, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Config.Theme.Text, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left}, Frame)
    
    local switchBg = UI.Create("TextButton", {Size = UDim2.fromOffset(44, 22), Position = UDim2.new(1, -60, 0.5, -11), BackgroundColor3 = Config.Theme.Stroke, Text = "", AutoButtonColor = false}, Frame)
    UI.Corner(switchBg, 11)
    local knob = UI.Create("Frame", {Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = Config.Theme.Text, BorderSizePixel = 0}, switchBg)
    UI.Corner(knob, 8)
    
    local isOn = Preferences[Key]
    local function Render()
        if isOn == Preferences[Key] then return end
        isOn = Preferences[Key]
        UI.Tween(switchBg, {BackgroundColor3 = isOn and Config.Theme.Success or Config.Theme.Stroke})
        UI.Tween(knob, {Position = isOn and UDim2.fromOffset(25, 3) or UDim2.fromOffset(3, 3)})
    end
    UI_Updates[Key] = Render
    
    switchBg.MouseButton1Click:Connect(function()
        Preferences[Key] = not Preferences[Key]
        Render()
    end)
    
    if BindKey then
        local bindBtn = UI.Create("TextButton", {Size = UDim2.fromOffset(50, 22), Position = UDim2.new(1, -118, 0.5, -11), BackgroundColor3 = Config.Theme.Background, Text = Preferences[BindKey] or "None", Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = Config.Theme.Accent, AutoButtonColor = false}, Frame)
        UI.Corner(bindBtn, 6); UI.Stroke(bindBtn, 1, Config.Theme.Stroke)
        bindBtn.MouseButton1Click:Connect(function()
            bindBtn.Text = "..."
            captureBind = {key = BindKey, button = bindBtn}
        end)
    end
    Render()
end

local function CreateSlider(parent, Name, Key, Min, Max, Default, Suffix)
    Preferences[Key] = Preferences[Key] or Default
    
    local Frame = UI.Create("Frame", {Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = Config.Theme.Surface, BorderSizePixel = 0}, parent)
    UI.Corner(Frame, 8)
    UI.Create("TextLabel", {Size = UDim2.new(1, -60, 0, 20), Position = UDim2.fromOffset(12, 8), Text = Name, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Config.Theme.Text, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left}, Frame)
    local valLabel = UI.Create("TextLabel", {Size = UDim2.fromOffset(60, 20), Position = UDim2.new(1, -72, 0, 8), Text = tostring(Preferences[Key]) .. (Suffix or ""), Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Config.Theme.Accent, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Right}, Frame)
    
    local track = UI.Create("Frame", {Size = UDim2.new(1, -24, 0, 6), Position = UDim2.fromOffset(12, 32), BackgroundColor3 = Config.Theme.Stroke, BorderSizePixel = 0}, Frame)
    UI.Corner(track, 3)
    local fill = UI.Create("Frame", {Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Config.Theme.Accent, BorderSizePixel = 0}, track)
    UI.Corner(fill, 3)
    local knob = UI.Create("Frame", {Size = UDim2.fromOffset(14, 14), Position = UDim2.fromScale(0, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Config.Theme.Text, BorderSizePixel = 0}, track)
    UI.Corner(knob, 7)
    
    local function Render()
        local pct = (Preferences[Key] - Min) / (Max - Min)
        UI.Tween(fill, {Size = UDim2.new(pct, 0, 1, 0)}, 0.1)
        UI.Tween(knob, {Position = UDim2.new(pct, 0, 0.5, 0)}, 0.1)
        valLabel.Text = tostring(Preferences[Key]) .. (Suffix or "")
    end
    
    local function HandleInput(input)
        local pct = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        Preferences[Key] = math.floor(Min + pct * (Max - Min) + 0.5)
        Render()
    end
    
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            UI.ActiveSlider = {Render = Render, HandleInput = HandleInput, Track = track}
            HandleInput(input)
        end
    end)
    Render()
end

local function CreateButton(parent, Name, Callback)
    local btn = UI.Create("TextButton", {Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Config.Theme.Accent, Text = Name, Font = Enum.Font.GothamBlack, TextSize = 14, TextColor3 = Config.Theme.Background, AutoButtonColor = false}, parent)
    UI.Corner(btn, 8)
    btn.MouseEnter:Connect(function() UI.Tween(btn, {BackgroundColor3 = Config.Theme.AccentDark}) end)
    btn.MouseLeave:Connect(function() UI.Tween(btn, {BackgroundColor3 = Config.Theme.Accent}) end)
    btn.MouseButton1Click:Connect(Callback)
end

-- ============================================================
-- [ MÓDULO 5: CONSTRUÇÃO DAS PÁGINAS (Client / Server) ]
-- ============================================================
local Pages = {}
local navButtons = {}
local activePage = ""

local function SwitchPage(name)
    activePage = name
    PageTitle.Text = name:upper()
    for _, v in ipairs(ScrollArea:GetChildren()) do if v:IsA("GuiObject") then v:Destroy() end end
    
    for n, btn in pairs(navButtons) do
        local sel = (n == name)
        UI.Tween(btn, {BackgroundColor3 = sel and Config.Theme.Accent or Config.Theme.Background})
        btn.TextColor3 = sel and Config.Theme.Background or Config.Theme.Text
    end
    
    if Pages[name] then Pages[name]() end
end

local function AddNav(name)
    local btn = UI.Create("TextButton", {Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = Config.Theme.Background, Text = "  " .. name, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Config.Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false}, NavList)
    UI.Corner(btn, 8)
    navButtons[name] = btn
    btn.MouseButton1Click:Connect(function() SwitchPage(name) end)
end

-- MOCK DE SERVER-SIDE (Para jogos que você tem acesso ao servidor)
local ServerMocks = {}
local function FireServer(eventName, ...)
    local ev = ServerMocks[eventName]
    if ev then
        ev:FireServer(...)
    else
        warn("[Sonic Hub] RemoteEvent " .. eventName .. " não encontrado (Modo Client-Side puro ativo).")
    end
end

-- PÁGINAS
Pages["Main"] = function()
    CreateButton(ScrollArea, "Ativar/Desativar Server Scripts (Backdoor)", function()
        -- Tenta achar o RemoteEvent mock
        local ev = game:GetService("ReplicatedStorage"):FindFirstChild("SonicServerEvent")
        if ev then
            ServerMocks["SonicServerEvent"] = ev
            FireServer("SonicServerEvent", "ActivateScripts")
        else
            warn("Evento de servidor não encontrado.")
        end
    end)
    CreateButton(ScrollArea, "Rejoin Server", function() game:GetService("TeleportService"):Teleport(game.PlaceId) end)
end

Pages["Aimbot"] = function()
    CreateToggle(ScrollArea, "Enable Aimbot", "aim_enabled", "aim_bind", false)
    CreateSlider(ScrollArea, "Smoothness", "aim_smooth", 1, 20, 5)
    CreateSlider(ScrollArea, "FOV", "aim_fov", 10, 600, 150, "px")
end

Pages["Silent Aim"] = function()
    CreateToggle(ScrollArea, "Enable Silent Aim", "sil_enabled", "sil_bind", false)
    CreateSlider(ScrollArea, "Hit Chance", "sil_hit", 0, 100, 95, "%")
    CreateSlider(ScrollArea, "Headshot Chance", "sil_head", 0, 100, 100, "%")
end

Pages["Visuals"] = function()
    CreateToggle(ScrollArea, "Enable ESP", "esp_enabled", nil, false)
    CreateToggle(ScrollArea, "Box ESP", "esp_box", nil, true)
    CreateToggle(ScrollArea, "Name ESP", "esp_name", nil, true)
    CreateToggle(ScrollArea, "Health Bar", "esp_health", nil, true)
    CreateToggle(ScrollArea, "Skeleton", "esp_skeleton", nil, false)
    CreateToggle(ScrollArea, "Tracer Lines", "esp_tracer", nil, false)
    CreateSlider(ScrollArea, "Max Distance", "esp_dist", 100, 5000, 2000, "m")
end

Pages["Server (Mock)"] = function()
    CreateButton(ScrollArea, "Dar Arma (Server Mock)", function()
        FireServer("SonicServerEvent", "GiveTool", "ClassicSword")
    end)
    CreateButton(ScrollArea, "Kickar Todos (Server Mock)", function()
        FireServer("SonicServerEvent", "KickAll")
    end)
    CreateButton(ScrollArea, "Speed Hack (Server Sync)", function()
        FireServer("SonicServerEvent", "SpeedHack", 100)
    end)
end

-- Inicializar UI
AddNav("Main")
AddNav("Aimbot")
AddNav("Silent Aim")
AddNav("Visuals")
AddNav("Server (Mock)")
SwitchPage("Main")

-- ============================================================
-- [ MÓDULO 6: LÓGICA CLIENT-SIDE (Combat & Visuals) ]
-- ============================================================
local Camera = Workspace.CurrentCamera
local localPlayer = Players.LocalPlayer

local function IsVisible(char)
    if not char then return false end
    local origin = Camera.CFrame.Position
    local target = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
    if not target then return false end
    
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {localPlayer.Character, char}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    
    local result = Workspace:Raycast(origin, target.Position - origin, rayParams)
    return result == nil
end

local function GetTarget()
    local closest = nil
    local dist = math.huge
    local fov = Preferences["aim_fov"] or 150
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= localPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            local screenPos, onScreen = Camera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
            if onScreen then
                local mousePos = UserInputService:GetMouseLocation()
                local pixelDist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                if pixelDist < fov and pixelDist < dist then
                    closest = p.Character
                    dist = pixelDist
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    -- Aimbot Logic
    if Preferences["aim_enabled"] and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = GetTarget()
        if target then
            local head = target:FindFirstChild("Head")
            if head then
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, head.Position), 0.15)
            end
        end
    end
end)

-- ============================================================
-- [ MÓDULO 7: INPUT SYSTEM & CLEANUP ]
-- ============================================================
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if captureBind then
        local key = input.KeyCode.Name
        if input.UserInputType == Enum.UserInputType.MouseButton1 then key = "MB1"
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then key = "MB2" end
        if key then
            Preferences[captureBind.key] = key
            captureBind.button.Text = key
            captureBind = nil
        end
        return
    end
    if input.KeyCode == Config.MenuKey then
        GUI.Enabled = not GUI.Enabled
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if UI.ActiveSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        UI.ActiveSlider.HandleInput(input)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        UI.ActiveSlider = nil
    end
end)

local function Cleanup()
    if shared.SonicHubCleanup then
        shared.SonicHubCleanup()
    end
    shared.SonicHubCleanup = function() end
    if GUI then GUI:Destroy() end
    if Overlay then Overlay:Destroy() end
    if LoadingGui then LoadingGui:Destroy() end
end
shared.SonicHubCleanup = Cleanup

GUI.Enabled = true
print("[Sonic Hub V19] Carregado com sucesso. Design Neon e Arquitetura Modular.")
