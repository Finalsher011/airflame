-- Sonic Hub · V24 (Fixes: genv, silent aim, toggle, corners, inset, sticky, npcs, fade, lite)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Stats = game:GetService("Stats")
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Config = {
    MenuKey = Enum.KeyCode.RightShift,
    MaxBoxPixels = 800,
    WinW = 720, WinH = 560, TitleH = 50,
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

local function viewportMouse()
    local m = UserInputService:GetMouseLocation()
    local inset = Vector2.new(0, 36)
    pcall(function()
        local i = GuiService:GetGuiInset()
        if typeof(i) == "Vector2" then inset = i elseif type(i) == "table" and typeof(i[1]) == "Vector2" then inset = i[1] end
    end)
    return Vector2.new(m.X, m.Y) - inset
end

local function formatBind(val)
    if not val or val == "None" then return "NONE" end
    if val == "MouseButton1" then return "MB1" end
    if val == "MouseButton2" then return "MB2" end
    if val == "MouseButton3" then return "MB3" end
    return val:upper()
end

-- ============================================================
-- PALETA E ESTILOS
-- ============================================================
local P = {
    bg        = Color3.fromRGB(10, 12, 16),
    glass     = Color3.fromRGB(20, 24, 32),
    glassHead = Color3.fromRGB(30, 36, 48),
    stroke    = Color3.fromRGB(50, 60, 80),
    text      = Color3.fromRGB(230, 240, 255),
    sub       = Color3.fromRGB(130, 145, 170),
    accent    = Color3.fromRGB(180, 255, 0),
    red       = Color3.fromRGB(255, 60, 90),
    track     = Color3.fromRGB(35, 42, 55),
    ink       = Color3.fromRGB(10, 15, 20),
}

local function new(cls, props, parent)
    local i = Instance.new(cls)
    for k, v in pairs(props) do i[k] = v end
    if parent then i.Parent = parent end
    return i
end
local function corner(i, r) return new("UICorner", {CornerRadius = UDim.new(0, r)}, i) end
local function outline(i, t, c) return new("UIStroke", {Color = c or P.stroke, Thickness = t or 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, i) end
local function label(parent, props)
    props.BackgroundTransparency = 1
    props.Font = props.Font or Enum.Font.Gotham
    props.TextColor3 = props.TextColor3 or P.text
    props.TextSize = props.TextSize or 14
    props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
    return new("TextLabel", props, parent)
end
local TWEEN_QUICK = TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TWEEN_SMOOTH = TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local function tween(inst, props, info) TweenService:Create(inst, info or TWEEN_QUICK, props):Play() end

local function addGlow(inst, color)
    return new("ImageLabel", {
        Image = "rbxassetid://1316045217", ImageColor3 = color or P.accent, ImageTransparency = 0.6,
        ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(10, 10, 118, 118),
        Size = UDim2.new(1, 12, 1, 12), Position = UDim2.new(0, -6, 0, -6),
        BackgroundTransparency = 1, ZIndex = math.max(inst.ZIndex - 1, 0)
    }, inst)
end

-- ============================================================
-- TELA DE LOADING
-- ============================================================
local LoadingGui = new("ScreenGui", {Name = "SonicHubLoading", DisplayOrder = 999, IgnoreGuiInset = true}, PlayerGui)
local LoadBg = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = P.bg, BorderSizePixel = 0}, LoadingGui)

for i = 1, 20 do
    local ln = new("Frame", {Size = UDim2.fromOffset(math.random(100, 250), 2), Position = UDim2.new(1, 0, math.random(), 0), BackgroundColor3 = P.accent, BackgroundTransparency = math.random(40, 80)/100}, LoadBg)
    task.spawn(function()
        while ln.Parent do
            tween(ln, {Position = UDim2.new(0, -300, ln.Position.Y.Scale, 0)}, TweenInfo.new(math.random(1, 2), Enum.EasingStyle.Linear))
            task.wait(1.5)
        end
    end)
end

local centerFrame = new("Frame", {Size = UDim2.fromOffset(400, 150), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1}, LoadBg)
new("TextLabel", {Size = UDim2.new(1, 0, 0, 60), Text = "SONIC HUB", Font = Enum.Font.FredokaOne, TextSize = 54, TextColor3 = P.accent, BackgroundTransparency = 1}, centerFrame)
new("TextLabel", {Size = UDim2.new(1, 0, 0, 60), Text = "SONIC HUB", Font = Enum.Font.FredokaOne, TextSize = 54, TextColor3 = P.text, BackgroundTransparency = 1}, centerFrame)

local barContainer = new("Frame", {Size = UDim2.fromOffset(300, 6), Position = UDim2.new(0.5, 0, 1, -20), AnchorPoint = Vector2.new(0.5, 1), BackgroundColor3 = P.track}, centerFrame)
corner(barContainer, 3)
local barFill = new("Frame", {Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = P.accent}, barContainer)
corner(barFill, 3); addGlow(barFill, P.accent)

task.spawn(function()
    local progress = 0
    while progress < 100 do
        progress = math.min(progress + math.random(2, 8), 100)
        tween(barFill, {Size = UDim2.new(progress / 100, 0, 1, 0)}, TweenInfo.new(0.1))
        task.wait(0.05)
    end
    tween(centerFrame, {Position = UDim2.new(0.5, 0, 0.4, 0)}, TWEEN_SMOOTH)
    for _, v in ipairs(centerFrame:GetDescendants()) do pcall(function() tween(v, {TextTransparency = 1, BackgroundTransparency = 1}, TWEEN_SMOOTH) end) end
    tween(LoadBg, {BackgroundTransparency = 1}, TWEEN_SMOOTH)
    task.wait(0.5); LoadingGui:Destroy()
end)

-- ============================================================
-- UI PRINCIPAL
-- ============================================================
local GUI = new("ScreenGui", {Name = "SonicHub", ResetOnSpawn = false, DisplayOrder = 10, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Enabled = false}, PlayerGui)
-- IgnoreGuiInset = false para casar com WorldToViewportPoint (evita offset de 36px)
local Overlay = new("ScreenGui", {Name = "SonicHubOverlay", ResetOnSpawn = false, DisplayOrder = 5, IgnoreGuiInset = false}, PlayerGui)

local Main = new("Frame", {Name = "Main", Size = UDim2.fromOffset(Config.WinW, Config.WinH), Position = UDim2.new(0.5, -Config.WinW / 2, 0.5, -Config.WinH / 2), BackgroundColor3 = P.bg, BackgroundTransparency = 0.05, ClipsDescendants = true}, GUI)
corner(Main, 12); outline(Main, 1.5, P.stroke); addGlow(Main, P.stroke)
local UIScale = new("UIScale", {Scale = 1}, Main)

local TitleBar = new("Frame", {Size = UDim2.new(1, 0, 0, Config.TitleH), BackgroundColor3 = P.glassHead, BackgroundTransparency = 0.2, BorderSizePixel = 0}, Main)
corner(TitleBar, 12)
new("Frame", {Size = UDim2.new(1, 0, 0, 12), Position = UDim2.new(0, 0, 1, -12), BackgroundColor3 = P.glassHead, BackgroundTransparency = 0.2, BorderSizePixel = 0}, TitleBar)
new("Frame", {Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, -2), BackgroundColor3 = P.accent, BorderSizePixel = 0}, TitleBar)

label(TitleBar, {Size = UDim2.fromOffset(200, Config.TitleH), Position = UDim2.fromOffset(20, 0), Text = "SONIC HUB V24", Font = Enum.Font.FredokaOne, TextSize = 24, TextColor3 = P.text})

local function titleBtn(text, color, x, cb)
    local b = new("TextButton", {Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, x, 0.5, -14), BackgroundColor3 = P.glass, Text = text, TextColor3 = color, Font = Enum.Font.GothamBold, TextSize = 16, AutoButtonColor = false}, TitleBar)
    corner(b, 6); local st = outline(b, 1.5, P.stroke)
    b.MouseEnter:Connect(function() tween(b, {BackgroundColor3 = color, TextColor3 = P.ink}); tween(st, {Color = color}) end)
    b.MouseLeave:Connect(function() tween(b, {BackgroundColor3 = P.glass, TextColor3 = color}); tween(st, {Color = P.stroke}) end)
    b.MouseButton1Click:Connect(cb)
end
titleBtn("-", P.accent, -70, function() end)
titleBtn("x", P.red, -36, function() GUI:Destroy() end)

local Body = new("Frame", {Position = UDim2.fromOffset(0, Config.TitleH), Size = UDim2.fromOffset(Config.WinW, Config.WinH - Config.TitleH), BackgroundTransparency = 1}, Main)

local Sidebar = new("Frame", {Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(170, Config.WinH - Config.TitleH - 20), BackgroundColor3 = P.glass, BackgroundTransparency = 0.4, BorderSizePixel = 0}, Body)
corner(Sidebar, 10); outline(Sidebar, 1, P.stroke)
local NavList = new("ScrollingFrame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y}, Sidebar)
new("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, NavList); new("UIPadding", {PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)}, NavList)

local ContentArea = new("Frame", {Position = UDim2.fromOffset(190, 10), Size = UDim2.fromOffset(Config.WinW - 200, Config.WinH - Config.TitleH - 20), BackgroundTransparency = 1}, Body)
local PageTitle = label(ContentArea, {Size = UDim2.new(1, 0, 0, 30), Text = "", Font = Enum.Font.GothamBold, TextSize = 26, TextColor3 = P.text})
local PageSub = label(ContentArea, {Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(2, 30), Text = "", Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = P.sub})

local Scroll = new("ScrollingFrame", {Position = UDim2.fromOffset(0, 60), Size = UDim2.new(1, 0, 1, -60), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = P.accent, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y}, ContentArea)
new("UIPadding", {PaddingRight = UDim.new(0, 10)}, Scroll)
new("UIListLayout", {Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder}, Scroll)

-- ============================================================
-- WIDGETS
-- ============================================================
local function CreateGroup(parent, title)
    local group = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = P.glass, BackgroundTransparency = 0.6, BorderSizePixel = 0}, parent)
    corner(group, 8); outline(group, 1, P.stroke)
    new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}, group)

    local header = new("TextButton", {Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, Text = "", LayoutOrder = 1}, group)
    label(header, {Size = UDim2.new(1, -30, 1, 0), Position = UDim2.fromOffset(12, 0), Text = title, TextSize = 13, TextColor3 = P.sub})
    local chevron = label(header, {Size = UDim2.fromOffset(20, 32), Position = UDim2.new(1, -25, 0, 0), Text = "v", TextColor3 = P.sub, TextSize = 14})

    local body = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 2}, group)
    new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, body)
    new("UIPadding", {PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12)}, body)

    header.MouseButton1Click:Connect(function()
        body.Visible = not body.Visible
        tween(chevron, {Rotation = body.Visible and 0 or -90})
    end)
    return body
end

local function CreateToggle(parent, name, key, default)
    preferences[key] = preferences[key] or default
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1}, parent)
    label(row, {Size = UDim2.new(0.8, 0, 1, 0), Text = name, TextSize = 14, TextColor3 = P.text})

    local switchBg = new("TextButton", {Size = UDim2.fromOffset(34, 18), Position = UDim2.new(1, -34, 0.5, -9), BackgroundColor3 = P.track, Text = "", AutoButtonColor = false}, row)
    corner(switchBg, 9); outline(switchBg, 1, P.stroke)
    local knob = new("Frame", {Size = UDim2.fromOffset(12, 12), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = P.sub, BorderSizePixel = 0}, switchBg)
    corner(knob, 6)

    local function render()
        local isOn = pref(key)
        tween(switchBg, {BackgroundColor3 = isOn and P.accent or P.track})
        tween(knob, {Position = isOn and UDim2.fromOffset(19, 3) or UDim2.fromOffset(3, 3), BackgroundColor3 = isOn and P.ink or P.sub})
    end
    uiRenderers[key] = render
    switchBg.MouseButton1Click:Connect(function() setPref(key, not pref(key)); render() end)
    render()
end

local function CreateSlider(parent, name, key, min, max, default, suffix)
    preferences[key] = preferences[key] or default
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1}, parent)
    label(row, {Size = UDim2.new(0.8, 0, 0, 20), Text = name, TextSize = 14, TextColor3 = P.text})
    local valLbl = label(row, {Size = UDim2.new(0.2, 0, 0, 20), Position = UDim2.new(0.8, 0, 0, 0), Text = tostring(pref(key)) .. (suffix or ""), TextSize = 13, TextColor3 = P.sub, TextXAlignment = Enum.TextXAlignment.Right})

    local track = new("Frame", {Size = UDim2.new(1, 0, 0, 4), Position = UDim2.fromOffset(0, 26), BackgroundColor3 = P.track, BorderSizePixel = 0}, row)
    corner(track, 2)
    local fill = new("Frame", {Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = P.accent, BorderSizePixel = 0}, track)
    corner(fill, 2); addGlow(fill, P.accent)
    local knob = new("Frame", {Size = UDim2.fromOffset(12, 12), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = P.text, BorderSizePixel = 0}, track)
    corner(knob, 6)

    local function render()
        local v = prefNum(key, default)
        local pct = (v - min) / (max - min)
        tween(fill, {Size = UDim2.new(pct, 0, 1, 0)}, TweenInfo.new(0.1))
        tween(knob, {Position = UDim2.new(pct, 0, 0.5, 0)}, TweenInfo.new(0.1))
        valLbl.Text = tostring(v) .. (suffix or "")
    end
    uiRenderers[key] = render

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            activeSlider = {key = key, min = min, max = max, track = track, render = render}
            local pct = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            setPref(key, math.floor(min + pct * (max - min) + 0.5))
            render()
        end
    end)
    render()
end

local function CreateSegmented(parent, name, key, options, default)
    preferences[key] = preferences[key] or default
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1}, parent)
    if name and name ~= "" then label(row, {Size = UDim2.new(1, 0, 0, 20), Text = name, TextSize = 14, TextColor3 = P.text}) end

    local container = new("Frame", {Size = UDim2.new(1, 0, 0, 24), Position = UDim2.fromOffset(0, name and 22 or 0), BackgroundColor3 = P.track, BackgroundTransparency = 0.5, BorderSizePixel = 0}, row)
    corner(container, 6)

    local highlight = new("Frame", {BackgroundColor3 = P.accent, BorderSizePixel = 0, ZIndex = 2}, container)
    corner(highlight, 6); addGlow(highlight, P.accent)

    local btns = {}
    local function render()
        local selected = pref(key)
        for i, opt in ipairs(options) do
            local b = btns[opt]
            if opt == selected then
                local w = 1 / #options
                local posX = (i - 1) / #options
                tween(highlight, {Position = UDim2.new(posX, 0, 0, 0), Size = UDim2.new(w, 0, 1, 0), BackgroundTransparency = 0})
                b.TextColor3 = P.ink
            else
                b.TextColor3 = P.sub
            end
        end
    end

    for i, opt in ipairs(options) do
        local w = 1 / #options
        local b = new("TextButton", {
            Size = UDim2.new(w, 0, 1, 0),
            Position = UDim2.new((i - 1) * w, 0, 0, 0),
            BackgroundTransparency = 1, Text = opt, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = P.sub, ZIndex = 3
        }, container)
        btns[opt] = b
        b.MouseButton1Click:Connect(function() setPref(key, opt); render() end)
    end
    render()
end

local function CreateColorPicker(parent, name, key)
    preferences[key] = preferences[key] or Color3.fromRGB(180, 255, 0)
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1}, parent)
    label(row, {Size = UDim2.new(0.8, 0, 0, 20), Text = name, TextSize = 14, TextColor3 = P.text})

    local colorBox = new("Frame", {Size = UDim2.fromOffset(24, 24), Position = UDim2.new(1, -24, 0, 0), BackgroundColor3 = pref(key), BorderSizePixel = 0}, row)
    corner(colorBox, 4); outline(colorBox, 1, P.stroke)

    local track = new("Frame", {Size = UDim2.new(1, 0, 0, 8), Position = UDim2.fromOffset(0, 26), BorderSizePixel = 0}, row)
    corner(track, 4)
    new("UIGradient", {Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)), ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255,255,0)),
        ColorSequenceKeypoint.new(0.4, Color3.fromRGB(0,255,0)), ColorSequenceKeypoint.new(0.6, Color3.fromRGB(0,255,255)),
        ColorSequenceKeypoint.new(0.8, Color3.fromRGB(0,0,255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,255))
    })}, track)

    local knob = new("Frame", {Size = UDim2.fromOffset(14, 14), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = P.text, BorderSizePixel = 0}, track)
    corner(knob, 7); outline(knob, 2, P.ink)

    local function render()
        local c = pref(key)
        local h = select(1, Color3.toHSV(c))
        knob.Position = UDim2.new(h, 0, 0.5, 0)
        colorBox.BackgroundColor3 = c
    end
    uiRenderers[key] = render

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local pct = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            setPref(key, Color3.fromHSV(pct, 1, 1))
            render()
        end
    end)
    render()
end

-- ============================================================
-- PÁGINAS
-- ============================================================
local Pages = {}
local navButtons = {}
local activePage = ""

local function SwitchPage(name)
    activePage = name
    PageTitle.Text = name
    for _, v in ipairs(Scroll:GetChildren()) do if v:IsA("GuiObject") then v:Destroy() end end

    for n, btn in pairs(navButtons) do
        local sel = (n == name)
        tween(btn.bg, {BackgroundColor3 = sel and P.glassHead or P.track, BackgroundTransparency = sel and 0.2 or 0.6})
        tween(btn.text, {TextColor3 = sel and P.text or P.sub})
        tween(btn.ind, {Size = sel and UDim2.new(0, 3, 0.6, 0) or UDim2.new(0, 3, 0, 0), BackgroundTransparency = sel and 0 or 1})
    end
    if Pages[name] then Pages[name]() end
end

local function AddNav(name)
    local btn = new("TextButton", {Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = P.track, BackgroundTransparency = 0.6, Text = "", AutoButtonColor = false}, NavList)
    corner(btn, 6)
    local ind = new("Frame", {Size = UDim2.new(0, 3, 0, 0), Position = UDim2.new(0, 0, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = P.accent, BackgroundTransparency = 1}, btn)
    corner(ind, 1.5)
    local txt = label(btn, {Size = UDim2.new(1, -15, 1, 0), Position = UDim2.fromOffset(15, 0), Text = name, TextSize = 14, TextColor3 = P.sub})

    btn.MouseEnter:Connect(function() if activePage ~= name then tween(txt, {TextColor3 = P.text}) end end)
    btn.MouseLeave:Connect(function() if activePage ~= name then tween(txt, {TextColor3 = P.sub}) end end)
    navButtons[name] = {bg = btn, text = txt, ind = ind}
    btn.MouseButton1Click:Connect(function() SwitchPage(name) end)
end

Pages["Combat"] = function()
    PageSub.Text = "aimbot & silent aim"
    local g1 = CreateGroup(Scroll, "Aimbot")
    CreateToggle(g1, "Enabled", "aim_enabled", false)
    CreateSegmented(g1, "Hotkey", "aim_hotkey", {"RMB", "E", "X", "Shift"}, "RMB")
    CreateSlider(g1, "FOV", "aim_fov", 10, 600, 150)
    CreateSlider(g1, "Smoothness", "aim_smooth", 1, 20, 5)
    CreateToggle(g1, "Sticky Target", "aim_sticky", false)
    CreateToggle(g1, "Visible Only", "aim_visible", false)

    local g2 = CreateGroup(Scroll, "Silent Aim")
    CreateToggle(g2, "Enabled", "sil_enabled", false)
    CreateSlider(g2, "Hit Chance", "sil_hitchance", 0, 100, 95)
    CreateSlider(g2, "Headshot Chance", "sil_headchance", 0, 100, 100)
end

Pages["Trigger Bot"] = function()
    PageSub.Text = "auto click on targets"
    local g1 = CreateGroup(Scroll, "General")
    CreateToggle(g1, "Enabled", "trg_enabled", false)
    CreateSegmented(g1, "Hotkey", "trg_hotkey", {"Always", "RMB", "MMB", "E", "X", "Shift"}, "E")
    CreateSegmented(g1, "Mode", "trg_mode", {"Hold", "Toggle"}, "Toggle")
    CreateToggle(g1, "Gun (LMB)", "trg_gun", true)
    CreateSegmented(g1, "Hit zone", "trg_zone", {"Head", "Upper body", "Whole body"}, "Whole body")

    local g2 = CreateGroup(Scroll, "Timing")
    CreateSlider(g2, "Hit chance", "trg_hitchance", 0, 100, 100)
    CreateToggle(g2, "Auto hit chance", "trg_autohit", false)
    CreateToggle(g2, "Auto reaction time", "trg_autoreact", false)
    CreateSlider(g2, "Reaction time", "trg_react", 0, 500, 60)
    CreateSlider(g2, "Cooldown", "trg_cd", 0, 1000, 0)
    CreateSlider(g2, "Max distance", "trg_dist", 50, 5000, 1000)
end

Pages["Weapon"] = function()
    PageSub.Text = "gun mods & respawn"
    local warnBox = new("Frame", {Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = Color3.fromRGB(30, 45, 20), BorderSizePixel = 0}, Scroll)
    corner(warnBox, 6); outline(warnBox, 1, P.accent)
    new("Frame", {Size = UDim2.fromOffset(3, 16), Position = UDim2.new(0, 10, 0.5, -8), BackgroundColor3 = P.accent, BorderSizePixel = 0}, warnBox)
    label(warnBox, {Size = UDim2.new(1, -25, 1, 0), Position = UDim2.fromOffset(20, 0), Text = "Local changes the game's own code then uses", TextSize = 13, TextColor3 = P.text})

    local g1 = CreateGroup(Scroll, "Gun")
    CreateToggle(g1, "No recoil", "wpn_recoil", false)
    CreateToggle(g1, "Instant reload", "wpn_reload", false)
    CreateToggle(g1, "Infinite magazine", "wpn_mag", false)
    CreateToggle(g1, "Custom fire cooldown", "wpn_customcd", false)
    CreateSlider(g1, "Fire cooldown", "wpn_cd", 0, 1000, 500)

    local g2 = CreateGroup(Scroll, "Player")
    CreateToggle(g2, "Auto respawn", "wpn_respawn", false)
end

Pages["ESP"] = function()
    PageSub.Text = "boxes, labels & health"
    local g1 = CreateGroup(Scroll, "General")
    CreateToggle(g1, "Enabled", "esp_enabled", false)
    CreateSegmented(g1, "Renderer", "esp_renderer", {"Full", "Lite"}, "Full")
    CreateToggle(g1, "Health bar", "esp_healthbar", true)
    CreateToggle(g1, "Include teammates", "esp_teammates", false)
    CreateToggle(g1, "Include NPCs", "esp_npcs", true)
    CreateSlider(g1, "Max distance", "esp_maxdist", 100, 5000, 600)
    CreateToggle(g1, "Fade with distance", "esp_fade", true)

    local g2 = CreateGroup(Scroll, "Box")
    CreateSegmented(g2, "Style", "esp_boxstyle", {"Full", "Corners"}, "Corners")
    CreateSlider(g2, "Thickness", "esp_boxtick", 1, 5, 1)
    CreateSlider(g2, "Fill", "esp_boxfill", 0, 1, 0)
end

Pages["Extras"] = function()
    PageSub.Text = "skeleton, tracers & colors"
    local g1 = CreateGroup(Scroll, "Extras")
    CreateToggle(g1, "Skeleton", "ext_skel", false)
    CreateToggle(g1, "Head dot", "ext_headdot", false)
    CreateToggle(g1, "Tracers", "ext_tracer", false)
    CreateSegmented(g1, "Tracer origin", "ext_trorigin", {"Bottom", "Center", "Mouse"}, "Bottom")

    local g2 = CreateGroup(Scroll, "Color")
    CreateColorPicker(g2, "Color", "ext_color")
    CreateToggle(g2, "Rainbow", "ext_rainbow", false)
    CreateToggle(g2, "Team color", "ext_teamcol", false)

    local g3 = CreateGroup(Scroll, "Labels")
    CreateToggle(g3, "Names", "ext_names", true)
    CreateSlider(g3, "Name size", "ext_nsize", 10, 24, 13)
    CreateToggle(g3, "Distance", "ext_dist", true)
end

AddNav("Combat")
AddNav("Trigger Bot")
AddNav("Weapon")
AddNav("ESP")
AddNav("Extras")
SwitchPage("Combat")

-- ============================================================
-- LÓGICA
-- ============================================================
local function IsHotkeyDown(opt)
    if opt == "Always" then return true end
    if opt == "RMB" then return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) end
    if opt == "MMB" then return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton3) end
    if opt == "E" then return UserInputService:IsKeyDown(Enum.KeyCode.E) end
    if opt == "X" then return UserInputService:IsKeyDown(Enum.KeyCode.X) end
    if opt == "Shift" then return UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) end
    return false
end

local aimSticky = nil

local function GetTarget(fov, maxDist, hitZone)
    local cam = Workspace.CurrentCamera
    if not cam then return nil end
    local closest, closestDist = nil, math.huge
    local mouse = viewportMouse()

    local function consider(char, part)
        if not part then return end
        local sp, onScreen = cam:WorldToViewportPoint(part.Position)
        if onScreen then
            local pxDist = (Vector2.new(sp.X, sp.Y) - mouse).Magnitude
            local worldDist = (part.Position - cam.CFrame.Position).Magnitude
            if pxDist < fov and worldDist < maxDist and worldDist < closestDist then
                closest = {char = char, part = part}
                closestDist = worldDist
            end
        end
    end

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= Player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            local char = p.Character
            local part = char.HumanoidRootPart
            if hitZone == "Head" and char:FindFirstChild("Head") then part = char.Head
            elseif hitZone == "Upper body" and char:FindFirstChild("UpperTorso") then part = char.UpperTorso end
            consider(char, part)
        end
    end

    -- Sticky: se alvo atual ainda válido e no fov, prioriza
    if pref("aim_sticky") and aimSticky and aimSticky.Parent and aimSticky:FindFirstChild("Humanoid") and aimSticky.Humanoid.Health > 0 then
        local part = aimSticky:FindFirstChild("Head") or aimSticky:FindFirstChild("HumanoidRootPart")
        if part then
            local sp, onScreen = cam:WorldToViewportPoint(part.Position)
            if onScreen then
                local px = (Vector2.new(sp.X, sp.Y) - mouse).Magnitude
                if px < fov then return {char = aimSticky, part = part} end
            end
        end
    end
    return closest
end

local isToggled = false
local trgPrev = false
local lastTrigger = 0

RunService.RenderStepped:Connect(function()
    pcall(function()
        -- Aimbot
        if pref("aim_enabled") and IsHotkeyDown(pref("aim_hotkey")) then
            local cam = Workspace.CurrentCamera
            if cam then
                local target = GetTarget(prefNum("aim_fov", 150), 2000, "Head")
                if target then
                    aimSticky = target.char
                    local smooth = prefNum("aim_smooth", 5)
                    local cf = CFrame.new(cam.CFrame.Position, target.part.Position)
                    cam.CFrame = cam.CFrame:Lerp(cf, 1 / math.max(smooth, 1))
                end
            end
        else
            if not pref("aim_sticky") then aimSticky = nil end
        end

        -- Trigger Bot
        if pref("trg_enabled") then
            local hotkeyDown = IsHotkeyDown(pref("trg_hotkey"))
            local shouldFire
            if pref("trg_mode") == "Toggle" then
                if hotkeyDown and not trgPrev then isToggled = not isToggled end
                trgPrev = hotkeyDown
                shouldFire = isToggled
            else
                trgPrev = hotkeyDown
                shouldFire = hotkeyDown
            end

            if shouldFire and (os.clock() - lastTrigger) > (prefNum("trg_cd", 0) / 1000) then
                local target = GetTarget(60, prefNum("trg_dist", 1000), pref("trg_zone", "Whole body"))
                if target and math.random(1, 100) <= prefNum("trg_hitchance", 100) then
                    lastTrigger = os.clock()
                    pcall(function()
                        local g = getgenv()
                        if type(g) == "table" and type(g.mouse1click) == "function" then
                            g.mouse1click()
                        else
                            local VU = game:GetService("VirtualUser")
                            VU:CaptureController()
                            VU:Button1Down(Vector2.new(0, 0))
                            VU:Button1Up(Vector2.new(0, 0))
                        end
                    end)
                end
            end
        end
    end)
end)

-- Silent Aim: hook real de namecall em raycasts (o original hookava game.__index/"Target", nunca disparava)
local silentHookOk = false
pcall(function()
    if type(hookmetamethod) ~= "function" or type(checkcaller) ~= "function" or type(getnamecallmethod) ~= "function" then
        return
    end
    local namecall
    namecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if not checkcaller() and self == Workspace and pref("sil_enabled") and math.random(1, 100) <= prefNum("sil_hitchance", 95) then
            if method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist" or method == "Raycast" then
                local target = GetTarget(360, 3000, "Head")
                if target then
                    local args = { ... }
                    if method == "Raycast" then
                        local origin = args[1]
                        if typeof(origin) == "Vector3" then
                            args[2] = target.part.Position - origin
                            return namecall(self, table.unpack(args))
                        end
                    else
                        local ray = args[1]
                        if typeof(ray) == "Ray" then
                            args[1] = Ray.new(ray.Origin, target.part.Position - ray.Origin)
                            return namecall(self, table.unpack(args))
                        end
                    end
                end
            end
        end
        return namecall(self, ...)
    end)
    silentHookOk = true
end)

-- Weapon Mods
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            if Player.Character then
                for _, tool in pairs(Player.Character:GetChildren()) do
                    if tool:IsA("Tool") then
                        if pref("wpn_recoil") then
                            for _, v in pairs(tool:GetDescendants()) do
                                if v:IsA("NumberValue") and v.Name:lower():find("recoil") then v.Value = 0 end
                            end
                        end
                        if pref("wpn_reload") then
                            for _, v in pairs(tool:GetDescendants()) do
                                if v:IsA("NumberValue") and (v.Name:lower():find("reload") or v.Name:lower():find("cooldown")) then v.Value = 0 end
                            end
                        end
                    end
                end
            end
        end)
    end
end)

-- ============================================================
-- ESP
-- ============================================================
local entries = {}
local BONES_R15 = {{"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"}, {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"}, {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"}, {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"}, {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}}
local BONES_R6 = {{"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"}, {"Torso", "Left Leg"}, {"Torso", "Right Leg"}}

local function placeLine(f, p1, p2, thickness, color)
    local delta = p2 - p1; local len = delta.Magnitude
    if len < 0.5 or len > 3000 then f.Visible = false; return end
    f.Size = UDim2.fromOffset(len, thickness); f.Position = UDim2.fromOffset((p1.X + p2.X) / 2, (p1.Y + p2.Y) / 2)
    f.Rotation = math.deg(math.atan2(delta.Y, delta.X)); f.BackgroundColor3 = color; f.Visible = true
end

local function createEntry()
    local e = { Bones = {}, Corner = {} }
    e.Box = new("Frame", { BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false }, Overlay)
    e.Stroke = new("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, e.Box)
    e.Fill = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 0.7, BorderSizePixel = 0, Visible = false }, e.Box)
    e.Label = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(240, 20), AnchorPoint = Vector2.new(0.5, 1), Font = Enum.Font.GothamBold, TextStrokeTransparency = 0.4, Visible = false }, Overlay)
    e.HealthBack = new("Frame", { BackgroundColor3 = Color3.fromRGB(15, 20, 28), BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0), Visible = false }, Overlay); corner(e.HealthBack, 2)
    e.HealthFill = new("Frame", { BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Visible = false }, e.HealthBack); corner(e.HealthFill, 2)
    e.HeadDot = new("Frame", { Size = UDim2.fromOffset(6, 6), AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, Visible = false }, Overlay); corner(e.HeadDot, 3)
    e.Tracer = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, Visible = false }, Overlay)
    for i = 1, 8 do
        e.Corner[i] = new("Frame", { BorderSizePixel = 0, Visible = false }, Overlay)
    end
    return e
end

local function hideEntry(e)
    e.Box.Visible = false; e.Label.Visible = false; e.HealthBack.Visible = false; e.HealthFill.Visible = false
    e.Tracer.Visible = false; e.HeadDot.Visible = false; e.Fill.Visible = false
    for _, b in ipairs(e.Bones) do b.Visible = false end
    for _, c in ipairs(e.Corner) do c.Visible = false end
end

local function destroyEntry(e)
    e.Box:Destroy(); e.Label:Destroy(); e.HealthBack:Destroy(); e.Tracer:Destroy(); e.HeadDot:Destroy()
    for _, b in ipairs(e.Bones) do b:Destroy() end
    for _, c in ipairs(e.Corner) do c:Destroy() end
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
    if w > Config.MaxBoxPixels or h > Config.MaxBoxPixels or w <= 0 or h <= 0 then return nil end
    if minX < -2000 or maxX > 4000 or minY < -2000 or maxY > 4000 then return nil end
    return Vector2.new(minX, minY), Vector2.new(maxX, maxY)
end

local function GetESPColor(plr)
    if plr and pref("ext_teamcol") and plr.Team and plr.Team == Player.Team then return plr.TeamColor.Color end
    if pref("ext_rainbow") then return Color3.fromHSV((os.clock() * 0.2) % 1, 1, 1) end
    return pref("ext_color", Color3.fromRGB(180, 255, 0))
end

local function setSeg(f, x, y, sx, sy, color, transp)
    f.Position = UDim2.fromOffset(x, y)
    f.Size = UDim2.fromOffset(sx, sy)
    f.BackgroundColor3 = color
    f.BackgroundTransparency = transp
    f.Visible = true
end

local function updateEntry(e, cam, char, plr, dist, o)
    local cf, size = char:GetBoundingBox()
    if not cf or not size then hideEntry(e); return end
    local tl, br = projectBox(cam, cf, size)
    if not tl then hideEntry(e); return end
    local w, h = br.X - tl.X, br.Y - tl.Y

    local color = GetESPColor(plr)
    local alpha = 0
    if o.fade and o.maxdist > 0 then
        alpha = math.clamp((dist - o.maxdist * 0.5) / (o.maxdist * 0.5), 0, 0.85)
    end

    if o.box then
        e.Box.Position = UDim2.fromOffset(tl.X, tl.Y)
        e.Box.Size = UDim2.fromOffset(w, h)
        e.Box.Visible = true
        if o.boxstyle == "Full" then
            e.Stroke.Visible = true
            e.Stroke.Color = color
            e.Stroke.Thickness = o.thickness
            e.Stroke.Transparency = alpha
            for _, c in ipairs(e.Corner) do c.Visible = false end
        else
            e.Stroke.Visible = false
            local L = math.clamp(math.min(w, h) * 0.22, 4, 24)
            local t = o.thickness
            setSeg(e.Corner[1], tl.X, tl.Y, L, t, color, alpha)
            setSeg(e.Corner[2], tl.X, tl.Y, t, L, color, alpha)
            setSeg(e.Corner[3], br.X - L, tl.Y, L, t, color, alpha)
            setSeg(e.Corner[4], br.X - t, tl.Y, t, L, color, alpha)
            setSeg(e.Corner[5], tl.X, br.Y - t, L, t, color, alpha)
            setSeg(e.Corner[6], tl.X, br.Y - L, t, L, color, alpha)
            setSeg(e.Corner[7], br.X - L, br.Y - t, L, t, color, alpha)
            setSeg(e.Corner[8], br.X - t, br.Y - L, t, L, color, alpha)
        end
        e.Fill.Visible = o.fill > 0 and o.renderer ~= "Lite"
        if e.Fill.Visible then e.Fill.BackgroundColor3 = color; e.Fill.BackgroundTransparency = 1 - o.fill + alpha end
    else
        e.Box.Visible = false
        for _, c in ipairs(e.Corner) do c.Visible = false end
    end

    local parts = {}
    if o.name then table.insert(parts, plr and plr.Name or char.Name) end
    if o.dist then table.insert(parts, string.format("[%d]", dist)) end
    if #parts > 0 then
        e.Label.Text = table.concat(parts, " "); e.Label.TextSize = o.nsize; e.Label.TextColor3 = color
        e.Label.TextTransparency = alpha
        e.Label.Position = UDim2.fromOffset((tl.X + br.X) / 2, tl.Y - 2); e.Label.AnchorPoint = Vector2.new(0.5, 1); e.Label.Visible = true
    else e.Label.Visible = false end

    if o.health and o.renderer ~= "Lite" and char:FindFirstChild("Humanoid") then
        local hum = char.Humanoid
        local frac = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
        e.HealthBack.Position = UDim2.fromOffset(tl.X - 5, tl.Y); e.HealthBack.Size = UDim2.fromOffset(o.thickness + 1, h)
        e.HealthBack.BackgroundTransparency = alpha
        e.HealthFill.Size = UDim2.new(1, 0, frac, 0); e.HealthFill.BackgroundColor3 = Color3.fromRGB(255, 60, 60):Lerp(Color3.fromRGB(60, 235, 90), frac)
        e.HealthBack.Visible = true; e.HealthFill.Visible = true
    else e.HealthBack.Visible = false; e.HealthFill.Visible = false end

    if o.headdot and char:FindFirstChild("Head") then
        local sp = cam:WorldToViewportPoint(char.Head.Position)
        if sp.Z > 0 then e.HeadDot.Position = UDim2.fromOffset(sp.X, sp.Y); e.HeadDot.BackgroundColor3 = color; e.HeadDot.BackgroundTransparency = alpha; e.HeadDot.Visible = true end
    else e.HeadDot.Visible = false end

    if o.tracer then
        local origin = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
        if o.trorigin == "Top" then origin = Vector2.new(cam.ViewportSize.X / 2, 0)
        elseif o.trorigin == "Mouse" then origin = viewportMouse()
        elseif o.trorigin == "Center" then origin = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2) end
        local foot = Vector2.new((tl.X + br.X) / 2, br.Y)
        placeLine(e.Tracer, origin, foot, o.thickness, color)
        e.Tracer.BackgroundTransparency = alpha
    else e.Tracer.Visible = false end

    if o.skel and o.renderer ~= "Lite" and char:FindFirstChild("Humanoid") then
        local bones = char.Humanoid.RigType == Enum.HumanoidRigType.R15 and BONES_R15 or BONES_R6
        for i, pair in ipairs(bones) do
            local line = e.Bones[i]
            if not line then line = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, Visible = false }, Overlay); e.Bones[i] = line end
            local a = char:FindFirstChild(pair[1]); local b = char:FindFirstChild(pair[2])
            if a and b and a:IsA("BasePart") and b:IsA("BasePart") then
                local sa = cam:WorldToViewportPoint(a.Position); local sb = cam:WorldToViewportPoint(b.Position)
                if sa.Z > 0 and sb.Z > 0 then
                    placeLine(line, Vector2.new(sa.X, sa.Y), Vector2.new(sb.X, sb.Y), o.thickness, color)
                    line.BackgroundTransparency = alpha
                else line.Visible = false end
            else line.Visible = false end
        end
    else for _, b in ipairs(e.Bones) do b.Visible = false end end
end

local function isValidChar(c)
    return c and c:FindFirstChild("HumanoidRootPart") and c:FindFirstChild("Humanoid") and c.Humanoid.Health > 0
end

RunService.RenderStepped:Connect(function()
    pcall(function()
        if not pref("esp_enabled") then
            for _, e in pairs(entries) do destroyEntry(e) end
            entries = {}
            return
        end
        local cam = Workspace.CurrentCamera; if not cam then return end

        local o = {
            renderer = pref("esp_renderer", "Full"),
            box = true, boxstyle = pref("esp_boxstyle", "Corners"), fill = prefNum("esp_boxfill", 0),
            name = pref("ext_names", true), dist = pref("ext_dist", true), health = pref("esp_healthbar", true),
            headdot = pref("ext_headdot", false), skel = pref("ext_skel", false), tracer = pref("ext_tracer", false),
            trorigin = pref("ext_trorigin", "Bottom"), thickness = prefNum("esp_boxtick", 1.5), nsize = prefNum("ext_nsize", 13),
            fade = pref("esp_fade", true), maxdist = prefNum("esp_maxdist", 600)
        }

        local seen = {}

        local function push(char, plr)
            if not isValidChar(char) then return end
            local dist = (char.HumanoidRootPart.Position - cam.CFrame.Position).Magnitude
            if dist > o.maxdist then return end
            seen[char] = true
            local e = entries[char] or createEntry(); entries[char] = e
            updateEntry(e, cam, char, plr, dist, o)
        end

        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= Player and plr.Character then
                if pref("esp_teammates") or plr.Team ~= Player.Team then
                    push(plr.Character, plr)
                end
            end
        end

        if pref("esp_npcs", true) then
            for _, obj in pairs(Workspace:GetChildren()) do
                if obj:IsA("Model") and obj ~= Player.Character and obj:FindFirstChild("Humanoid") and not Players:GetPlayerFromCharacter(obj) then
                    push(obj, nil)
                end
            end
        end

        for key, e in pairs(entries) do
            if not seen[key] then destroyEntry(e); entries[key] = nil end
        end
    end)
end)

-- ============================================================
-- INPUT & DRAG
-- ============================================================
local dragging, dragStart, startPos = false, nil, nil
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = Main.Position
    end
end)
connect(UserInputService.InputChanged, function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
    if activeSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local track = activeSlider.track
        local pct = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local val = math.floor(activeSlider.min + pct * (activeSlider.max - activeSlider.min) + 0.5)
        setPref(activeSlider.key, val)
        activeSlider.render()
    end
end)
connect(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false; activeSlider = nil
    end
end)

connect(UserInputService.InputBegan, function(input, processed)
    if processed then return end
    if input.KeyCode == Config.MenuKey then GUI.Enabled = not GUI.Enabled end
end)

local cleaned = false
local function cleanup()
    if cleaned then return end; cleaned = true
    if shared.AFG_Cleanup == cleanup then shared.AFG_Cleanup = nil end
    for _, c in ipairs(connections) do c:Disconnect() end
    for key, e in pairs(entries) do destroyEntry(e); entries[key] = nil end
    Overlay:Destroy(); if GUI.Parent then GUI:Destroy() end
end
shared.AFG_Cleanup = cleanup; connect(GUI.Destroying, cleanup)

GUI.Enabled = true
print("[Sonic Hub V24] Módulos carregados.")
print("[Sonic Hub] Silent aim hook:", silentHookOk and "OK" or "indisponível neste executor")
