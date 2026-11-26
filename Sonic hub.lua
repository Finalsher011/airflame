-- Sonic Hub V34 (Moondiety UI - Full Rebuild)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

if shared.SonicHubCleanup then pcall(shared.SonicHubCleanup) end
for _, name in ipairs({"SonicHub", "SonicHubOverlay"}) do
    local a = PlayerGui:FindFirstChild(name); if a then a:Destroy() end
    local b = game:GetService("CoreGui"):FindFirstChild(name); if b then b:Destroy() end
end

local Prefs = {}
local function set(k, v) Prefs[k] = v end
local function get(k, d) local v = Prefs[k]; if v == nil then return d end; return v end
local function getNum(k, d) local v = tonumber(get(k, d)); if not v or v ~= v then return d end; return v end

-- ============================================================
-- TEMA MOONDIETY (Dark Minimalista)
-- ============================================================
local Theme = {
    bg = Color3.fromRGB(10, 10, 12),
    panel = Color3.fromRGB(18, 18, 22),
    card = Color3.fromRGB(24, 24, 30),
    text = Color3.fromRGB(255, 255, 255),
    sub = Color3.fromRGB(140, 140, 150),
    accent = Color3.fromRGB(255, 255, 255),
    accentDark = Color3.fromRGB(200, 200, 200),
    stroke = Color3.fromRGB(40, 40, 48),
    track = Color3.fromRGB(35, 35, 42),
}

local ThemeElements = {}
local function regTheme(inst, t) table.insert(ThemeElements, {inst = inst, type = t}) end

local function UpdateUITheme()
    for _, data in ipairs(ThemeElements) do
        local inst, t = data.inst, data.type
        if inst and inst.Parent then
            if t == "bg" then inst.BackgroundColor3 = Theme.bg
            elseif t == "panel" then inst.BackgroundColor3 = Theme.panel
            elseif t == "card" then inst.BackgroundColor3 = Theme.card
            elseif t == "text" then inst.TextColor3 = Theme.text
            elseif t == "sub" then inst.TextColor3 = Theme.sub
            elseif t == "accent" then 
                if inst:IsA("TextLabel") or inst:IsA("TextButton") then inst.TextColor3 = Theme.accent 
                elseif inst:IsA("UIStroke") then inst.Color = Theme.accent
                else inst.BackgroundColor3 = Theme.accent end
            elseif t == "stroke" then inst.Color = Theme.stroke
            elseif t == "track" then inst.BackgroundColor3 = Theme.track
            end
        end
    end
end

local function new(cls, props, parent, themeType)
    local i = Instance.new(cls); for k, v in pairs(props) do i[k] = v end
    if parent then i.Parent = parent end
    if themeType then regTheme(i, themeType) end
    return i
end
local function corner(i, r) return new("UICorner", {CornerRadius = UDim.new(0, r)}, i) end
local function outline(i, t, c, themeType) 
    local s = new("UIStroke", {Color = c or Theme.stroke, Thickness = t or 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, i)
    if themeType then regTheme(s, themeType) end
    return s
end
local function label(parent, props, themeType)
    props.BackgroundTransparency = 1; props.Font = props.Font or Enum.Font.Gotham
    props.TextColor3 = props.TextColor3 or Theme.text; props.TextSize = props.TextSize or 14
    props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
    local lbl = new("TextLabel", props, parent)
    if themeType then regTheme(lbl, themeType) end
    return lbl
end

local TWEEN_FAST = TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TWEEN_SMOOTH = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local function tween(i, p, t) TweenService:Create(i, t or TWEEN_FAST, p):Play() end

-- ============================================================
-- GUI E LAYOUT PRINCIPAL
-- ============================================================
local GUI = new("ScreenGui", {Name = "SonicHub", ResetOnSpawn = false, DisplayOrder = 100, ZIndexBehavior = Enum.ZIndexBehavior.Global, Enabled = false}, PlayerGui)
local Overlay = new("ScreenGui", {Name = "SonicHubOverlay", ResetOnSpawn = false, DisplayOrder = 999, IgnoreGuiInset = true}, PlayerGui)

local Main = new("Frame", {Size = UDim2.fromOffset(750, 520), Position = UDim2.new(0.5, -375, 0.5, -260), BackgroundColor3 = Theme.bg, ClipsDescendants = true}, GUI, "bg")
corner(Main, 16); outline(Main, 1, Theme.stroke, "stroke")

local TitleBar = new("Frame", {Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1}, Main)
label(TitleBar, {Size = UDim2.fromOffset(300, 60), Position = UDim2.fromOffset(24, 0), Text = "Sonic", Font = Enum.Font.GothamBold, TextSize = 20}, "text")
label(TitleBar, {Size = UDim2.fromOffset(300, 60), Position = UDim2.fromOffset(80, 0), Text = "Hub", Font = Enum.Font.Gotham, TextSize = 20, TextColor3 = Theme.sub}, "sub")

local closeBtn = new("TextButton", {Size = UDim2.fromOffset(30, 30), Position = UDim2.new(1, -45, 0.5, -15), BackgroundTransparency = 1, Text = "x", Font = Enum.Font.GothamBold, TextSize = 18}, TitleBar, "sub")
closeBtn.MouseEnter:Connect(function() tween(closeBtn, {TextColor3 = Theme.accent}) end)
closeBtn.MouseLeave:Connect(function() tween(closeBtn, {TextColor3 = Theme.sub}) end)
closeBtn.MouseButton1Click:Connect(function() GUI:Destroy() end)

local Body = new("Frame", {Position = UDim2.fromOffset(0, 60), Size = UDim2.new(1, 0, 1, -60), BackgroundTransparency = 1}, Main)
local Sidebar = new("Frame", {Position = UDim2.fromOffset(20, 0), Size = UDim2.fromOffset(160, 440), BackgroundTransparency = 1}, Body)
local NavList = new("ScrollingFrame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ScrollBarThickness = 0}, Sidebar)
new("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, NavList)

local ContentArea = new("Frame", {Position = UDim2.fromOffset(200, 0), Size = UDim2.fromOffset(530, 440), BackgroundTransparency = 1}, Body)
local PageContainer = new("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1}, ContentArea)

local renderers = {}
local activeSlider = nil
local openDropdown = nil

-- ============================================================
-- COMPONENTES (Estilo Moondiety)
-- ============================================================
local function CreateGroup(parent, title)
    local g = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Theme.card}, parent, "card")
    corner(g, 12)
    new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}, g)
    
    local head = new("Frame", {Size = UDim2.new(1, 0, 0, 45), BackgroundTransparency = 1, LayoutOrder = 1}, g)
    label(head, {Size = UDim2.new(1, -30, 1, 0), Position = UDim2.fromOffset(18, 0), Text = title, Font = Enum.Font.GothamBold, TextSize = 14}, "text")
    
    local body = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 2}, g)
    new("UIListLayout", {Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder}, body)
    new("UIPadding", {PaddingBottom = UDim.new(0, 18), PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18)}, body)
    return body
end

local function CreateToggle(parent, name, key, default)
    Prefs[key] = Prefs[key] or default
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1}, parent)
    label(row, {Size = UDim2.new(0.8, 0, 1, 0), Text = name, TextSize = 13}, "text")
    local sw = new("TextButton", {Size = UDim2.new(0, 36, 0, 20), Position = UDim2.new(1, -36, 0.5, -10), BackgroundColor3 = Theme.track, Text = "", AutoButtonColor = false}, row, "track")
    corner(sw, 10)
    local knob = new("Frame", {Size = UDim2.fromOffset(14, 14), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = Theme.sub}, sw); corner(knob, 7)
    
    local function render()
        local on = get(key)
        tween(sw, {BackgroundColor3 = on and Theme.accent or Theme.track})
        tween(knob, {Position = on and UDim2.fromOffset(19, 3) or UDim2.fromOffset(3, 3), BackgroundColor3 = on and Theme.bg or Theme.sub})
    end
    renderers[key] = render
    sw.MouseButton1Click:Connect(function() set(key, not get(key)); render() end)
    render()
end

local function CreateSlider(parent, name, key, min, max, default)
    Prefs[key] = Prefs[key] or default
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1}, parent)
    label(row, {Size = UDim2.new(0.7, 0, 0, 20), Text = name, TextSize = 13}, "text")
    local valLbl = label(row, {Size = UDim2.new(0.3, 0, 0, 20), Position = UDim2.new(0.7, 0, 0, 0), Text = tostring(get(key)), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right}, "sub")
    local btn = new("TextButton", {Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, 22), BackgroundTransparency = 1, Text = ""}, row)
    local track = new("Frame", {Size = UDim2.new(1, 0, 0, 4), Position = UDim2.fromOffset(0, 8), BackgroundColor3 = Theme.track}, btn, "track"); corner(track, 2)
    local fill = new("Frame", {Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Theme.accent}, track, "accent"); corner(fill, 2)
    local knob = new("Frame", {Size = UDim2.fromOffset(12, 12), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Theme.accent}, track, "accent"); corner(knob, 6)
    
    local function update(pct)
        local v = math.floor(min + pct * (max - min) + 0.5)
        set(key, v); pct = (v - min) / math.max(max - min, 1)
        tween(fill, {Size = UDim2.new(pct, 0, 1, 0)}); tween(knob, {Position = UDim2.new(pct, 0, 0.5, 0)})
        valLbl.Text = tostring(v)
    end
    renderers[key] = function() update((getNum(key, default) - min) / math.max(max - min, 1)) end
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            activeSlider = {btn = btn, min = min, max = max, update = update}
            update(math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1))
        end
    end)
    renderers[key]()
end

local function CreateDropdown(parent, name, key, options, default)
    Prefs[key] = Prefs[key] or default
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 56), BackgroundTransparency = 1}, parent)
    label(row, {Size = UDim2.new(1, 0, 0, 20), Text = name, TextSize = 13}, "text")
    local btn = new("TextButton", {Size = UDim2.new(1, 0, 0, 26), Position = UDim2.fromOffset(0, 22), BackgroundColor3 = Theme.panel, Text = "", AutoButtonColor = false}, row, "panel")
    corner(btn, 6); outline(btn, 1, Theme.stroke, "stroke")
    local txt = label(btn, {Size = UDim2.new(1, -30, 1, 0), Position = UDim2.fromOffset(10, 0), Text = tostring(get(key)), TextSize = 12}, "text")
    local arrow = label(btn, {Size = UDim2.fromOffset(20, 26), Position = UDim2.new(1, -20, 0, 0), Text = "v", TextSize = 12}, "sub")
    
    local list = new("Frame", {Size = UDim2.new(1, 0, 0, #options * 26), Position = UDim2.fromOffset(0, 52), BackgroundColor3 = Theme.panel, Visible = false, ZIndex = 999}, row, "panel")
    corner(list, 6); outline(list, 1, Theme.stroke, "stroke")
    for i, opt in ipairs(options) do
        local b = new("TextButton", {Size = UDim2.new(1, 0, 0, 26), Position = UDim2.fromOffset(0, (i - 1) * 26), BackgroundTransparency = 1, Text = opt, TextSize = 12, ZIndex = 1000}, list, "text")
        b.MouseEnter:Connect(function() b.BackgroundTransparency = 0.9; b.BackgroundColor3 = Theme.stroke end)
        b.MouseLeave:Connect(function() b.BackgroundTransparency = 1 end)
        b.MouseButton1Click:Connect(function()
            set(key, opt); txt.Text = opt; list.Visible = false; tween(arrow, {Rotation = 0})
            if openDropdown == list then openDropdown = nil end
            if renderers[key] then renderers[key]() end
        end)
    end
    btn.MouseButton1Click:Connect(function()
        if openDropdown and openDropdown ~= list then openDropdown.Visible = false end
        list.Visible = not list.Visible; tween(arrow, {Rotation = list.Visible and 180 or 0})
        openDropdown = list.Visible and list or nil
    end)
end

local function CreateKeybind(parent, name, key, defaultKey, defaultMode)
    Prefs[key] = Prefs[key] or {Key = defaultKey, Mode = defaultMode}
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 56), BackgroundTransparency = 1}, parent)
    label(row, {Size = UDim2.new(1, 0, 0, 20), Text = name, TextSize = 13}, "text")
    
    local container = new("Frame", {Size = UDim2.new(1, 0, 0, 26), Position = UDim2.fromOffset(0, 22), BackgroundColor3 = Theme.panel}, row, "panel")
    corner(container, 6); outline(container, 1, Theme.stroke, "stroke")
    
    local btnKey = new("TextButton", {Size = UDim2.new(0.5, -2, 1, 0), BackgroundTransparency = 1, Text = tostring(get(key).Key), TextSize = 12}, container, "text")
    local btnMode = new("TextButton", {Size = UDim2.new(0.5, -2, 1, 0), Position = UDim2.new(0.5, 2, 0, 0), BackgroundColor3 = Theme.card, Text = tostring(get(key).Mode), TextSize = 12}, container, "text"); corner(btnMode, 6)
    
    btnMode.MouseButton1Click:Connect(function()
        local modes = {"Always", "Hold", "Toggle"}
        local curr = get(key).Mode; local nextMode = modes[1]
        for i, m in ipairs(modes) do if m == curr then nextMode = modes[(i % #modes) + 1] break end end
        set(key, {Key = get(key).Key, Mode = nextMode}); btnMode.Text = nextMode
    end)
    
    btnKey.MouseButton1Click:Connect(function()
        btnKey.Text = "..."
        local conn
        conn = UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            if input.UserInputType == Enum.UserInputType.Keyboard or input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
                local keyName = input.KeyCode.Name
                if input.UserInputType == Enum.UserInputType.MouseButton1 then keyName = "LMB" end
                if input.UserInputType == Enum.UserInputType.MouseButton2 then keyName = "RMB" end
                set(key, {Key = keyName, Mode = get(key).Mode}); btnKey.Text = keyName; conn:Disconnect()
            end
        end)
    end)
end

-- ============================================================
-- PÁGINAS
-- ============================================================
local Pages, NavButtons = {}, {}
local function AddPage(name, buildFunc)
    local page = new("ScrollingFrame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.stroke, Visible = false, AutomaticCanvasSize = Enum.AutomaticSize.Y}, PageContainer)
    new("UIListLayout", {Padding = UDim.new(0, 16), SortOrder = Enum.SortOrder.LayoutOrder}, page)
    new("UIPadding", {PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 20)}, page)
    Pages[name] = page
    buildFunc(page)
end

local function SwitchPage(name)
    for n, p in pairs(Pages) do
        p.Visible = (n == name)
        if n == name then p.Position = UDim2.fromOffset(10, 0); tween(p, {Position = UDim2.fromOffset(0, 0)}, TWEEN_SMOOTH) end
    end
    for n, b in pairs(NavButtons) do
        local sel = (n == name)
        tween(b.txt, {TextColor3 = sel and Theme.text or Theme.sub})
        tween(b.ind, {Size = sel and UDim2.new(0, 3, 1, -8) or UDim2.new(0, 3, 0, 0), BackgroundTransparency = sel and 0 or 1})
    end
end

local function AddNav(name)
    local btn = new("TextButton", {Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, Text = "", AutoButtonColor = false}, NavList)
    local ind = new("Frame", {Size = UDim2.new(0, 3, 0, 0), Position = UDim2.new(0, 0, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = Theme.accent, BackgroundTransparency = 1}, btn)
    corner(ind, 1.5)
    local txt = label(btn, {Size = UDim2.new(1, -15, 1, 0), Position = UDim2.fromOffset(15, 0), Text = name, TextSize = 14}, "sub")
    
    btn.MouseEnter:Connect(function() if not Pages[name].Visible then tween(txt, {TextColor3 = Theme.text}) end end)
    btn.MouseLeave:Connect(function() if not Pages[name].Visible then tween(txt, {TextColor3 = Theme.sub}) end end)
    
    NavButtons[name] = {bg = btn, txt = txt, ind = ind}
    btn.MouseButton1Click:Connect(function() SwitchPage(name) end)
end

-- CONTEÚDO DAS PÁGINAS
AddPage("Aimbot", function(p)
    local g1 = CreateGroup(p, "Settings")
    CreateToggle(g1, "Enabled", "aim_on", false)
    CreateDropdown(g1, "Method", "aim_method", {"Camera Lock", "Mouse Lock"}, "Camera Lock")
    CreateDropdown(g1, "Bone", "aim_bone", {"Head", "UpperTorso", "HumanoidRootPart"}, "Head")
    CreateSlider(g1, "FOV", "aim_fov", 10, 600, 120)
    CreateSlider(g1, "Smoothness", "aim_smooth", 1, 20, 5)
    CreateToggle(g1, "Visible Only", "aim_visible", false)
    CreateToggle(g1, "Team Check", "aim_team", true)
    CreateKeybind(g1, "Keybind", "aim_keybind", "RMB", "Hold")
end)

AddPage("Silent Aim", function(p)
    local g1 = CreateGroup(p, "Silent Aim")
    CreateToggle(g1, "Enabled", "sil_on", false)
    CreateDropdown(g1, "Bone", "sil_bone", {"Head", "UpperTorso", "HumanoidRootPart"}, "Head")
    CreateSlider(g1, "Hit Chance (%)", "sil_hit", 0, 100, 100)
    CreateSlider(g1, "FOV", "sil_fov", 10, 600, 200)
    CreateKeybind(g1, "Keybind", "sil_keybind", "Always", "Always")
end)

AddPage("Trigger Bot", function(p)
    local g1 = CreateGroup(p, "Settings")
    CreateToggle(g1, "Enabled", "trg_on", false)
    CreateDropdown(g1, "Hit Zone", "trg_zone", {"Head", "UpperTorso", "HumanoidRootPart"}, "Head")
    CreateSlider(g1, "Delay (ms)", "trg_delay", 0, 500, 10)
    CreateSlider(g1, "Hit Chance (%)", "trg_hit", 0, 100, 100)
    CreateKeybind(g1, "Keybind", "trg_keybind", "E", "Toggle")
end)

AddPage("Visuals", function(p)
    local g1 = CreateGroup(p, "ESP")
    CreateToggle(g1, "Enabled", "esp_on", false)
    CreateSlider(g1, "Max Distance", "esp_dist", 100, 3000, 1000)
    CreateToggle(g1, "Team Check", "esp_team", true)
    CreateToggle(g1, "Box", "esp_box", true)
    CreateToggle(g1, "Name", "esp_name", true)
    CreateToggle(g1, "Distance", "esp_distlabel", true)
    CreateToggle(g1, "Skeleton", "esp_skel", false)
    CreateToggle(g1, "Chams (Highlight)", "esp_chams", false)
    
    local g2 = CreateGroup(p, "World")
    CreateToggle(g2, "FOV Circle", "vis_fovcircle", true)
    CreateToggle(g2, "Fullbright", "vis_fullbright", false)
end)

AddPage("Player", function(p)
    local g1 = CreateGroup(p, "Movement")
    CreateSlider(g1, "Walkspeed", "plr_speed", 16, 200, 16)
    CreateSlider(g1, "JumpPower", "plr_jump", 50, 200, 50)
    CreateToggle(g1, "Infinite Jump", "plr_infjump", false)
    CreateToggle(g1, "Noclip", "plr_noclip", false)
    
    local g2 = CreateGroup(p, "Fly")
    CreateToggle(g2, "Enabled", "plr_fly", false)
    CreateSlider(g2, "Speed", "plr_flyspeed", 10, 300, 50)
    CreateDropdown(g2, "Mode", "plr_flymode", {"Camera", "WASD"}, "Camera")
end)

AddPage("Misc", function(p)
    local g1 = CreateGroup(p, "Weapon")
    CreateToggle(g1, "No Recoil", "wpn_recoil", false)
    CreateToggle(g1, "Instant Reload", "wpn_reload", false)
    
    local g2 = CreateGroup(p, "Utilities")
    CreateToggle(g2, "Anti-AFK", "misc_afk", true)
    CreateKeybind(g2, "Menu Key", "misc_menukey", "RightShift", "Toggle")
end)

AddPage("Configs", function(p)
    local g1 = CreateGroup(p, "Interface Colors")
    CreateSlider(g1, "Background R", "color_bg_r", 0, 255, 10)
    CreateSlider(g1, "Background G", "color_bg_g", 0, 255, 10)
    CreateSlider(g1, "Background B", "color_bg_b", 0, 255, 12)
    
    CreateSlider(g1, "Accent R", "color_ac_r", 0, 255, 255)
    CreateSlider(g1, "Accent G", "color_ac_g", 0, 255, 255)
    CreateSlider(g1, "Accent B", "color_ac_b", 0, 255, 255)
    
    local applyBtn = new("TextButton", {Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Theme.card, Text = "Apply Theme", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Theme.text, AutoButtonColor = false}, p, "card")
    corner(applyBtn, 6)
    applyBtn.MouseButton1Click:Connect(function()
        Theme.bg = Color3.fromRGB(getNum("color_bg_r", 10), getNum("color_bg_g", 10), getNum("color_bg_b", 12))
        Theme.panel = Theme.bg:Lerp(Color3.new(1,1,1), 0.05)
        Theme.card = Theme.bg:Lerp(Color3.new(1,1,1), 0.08)
        Theme.accent = Color3.fromRGB(getNum("color_ac_r", 255), getNum("color_ac_g", 255), getNum("color_ac_b", 255))
        
        if (Theme.bg.R + Theme.bg.G + Theme.bg.B) / 3 < 128 then
            Theme.text = Color3.new(1,1,1); Theme.sub = Color3.fromRGB(140,140,150); Theme.stroke = Color3.fromRGB(40,40,48); Theme.track = Color3.fromRGB(35,35,42)
        else
            Theme.text = Color3.fromRGB(20,20,20); Theme.sub = Color3.fromRGB(100,100,100); Theme.stroke = Color3.fromRGB(200,200,200); Theme.track = Color3.fromRGB(220,220,220)
        end
        UpdateUITheme()
    end)
end)

AddNav("Aimbot"); AddNav("Silent Aim"); AddNav("Trigger Bot"); AddNav("Visuals"); AddNav("Player"); AddNav("Misc"); AddNav("Configs")
SwitchPage("Aimbot")

-- ============================================================
-- LÓGICA CORE
-- ============================================================
local function viewportMouse()
    local m = UserInputService:GetMouseLocation()
    local inset = Vector2.new(0, 36)
    pcall(function() local i = GuiService:GetGuiInset(); if typeof(i) == "Vector2" then inset = i end end)
    return m - inset
end

local function isKeybindActive(data)
    if not data then return false end
    local isDown = false
    if data.Key == "LMB" then isDown = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    elseif data.Key == "RMB" then isDown = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    elseif data.Key == "MMB" then isDown = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton3)
    else local kc = Enum.KeyCode[data.Key]; if kc then isDown = UserInputService:IsKeyDown(kc) end end

    if data.Mode == "Always" then return true end
    if data.Mode == "Hold" then return isDown end
    if data.Mode == "Toggle" then
        local sk = "tgl_" .. tostring(data.Key)
        if isDown and not Prefs[sk .. "_prev"] then Prefs[sk] = not Prefs[sk] end
        Prefs[sk .. "_prev"] = isDown
        return Prefs[sk]
    end
    return false
end

local function isVisible(char, part)
    local cam = Workspace.CurrentCamera
    if not cam or not LocalPlayer.Character then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character, char}
    return Workspace:Raycast(cam.CFrame.Position, part.Position - cam.CFrame.Position, params) == nil
end

local function findTarget(fov, bone, teamCheck, visCheck)
    local cam = Workspace.CurrentCamera
    if not cam then return nil end
    local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
    local closest, closestDist = nil, math.huge

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
            if not teamCheck or plr.Team ~= LocalPlayer.Team then
                local part = plr.Character:FindFirstChild(bone) or plr.Character.HumanoidRootPart
                local sp, onScreen = cam:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if dist < fov and dist < closestDist then
                        if not visCheck or isVisible(plr.Character, part) then
                            closestDist = dist; closest = {char = plr.Character, part = part}
                        end
                    end
                end
            end
        end
    end
    return closest
end

local fovCircle = new("Frame", {Size = UDim2.fromOffset(100, 100), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Visible = false}, Overlay)
new("UICorner", {CornerRadius = UDim.new(1, 0)}, fovCircle)
local fovStroke = new("UIStroke", {Thickness = 1, Color = Theme.accent}, fovCircle)

-- LOOPS PRINCIPAIS
RunService.RenderStepped:Connect(function()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    
    fovStroke.Color = Theme.accent
    
    if get("vis_fovcircle") and get("aim_on") then
        fovCircle.Position = UDim2.fromOffset(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
        fovCircle.Size = UDim2.fromOffset(getNum("aim_fov", 120) * 2, getNum("aim_fov", 120) * 2); fovCircle.Visible = true
    else fovCircle.Visible = false end
    
    -- Aimbot
    if get("aim_on") and isKeybindActive(get("aim_keybind", {Key="RMB", Mode="Hold"})) then
        local target = findTarget(getNum("aim_fov", 120), get("aim_bone", "Head"), get("aim_team", true), get("aim_visible", false))
        if target then
            if get("aim_method", "Camera Lock") == "Camera Lock" then
                local smooth = getNum("aim_smooth", 5)
                cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, target.part.Position), 1 / math.max(smooth, 1))
            else
                local sp, onScreen = cam:WorldToViewportPoint(target.part.Position)
                if onScreen then
                    local delta = (Vector2.new(sp.X, sp.Y) - viewportMouse()) * (1 / math.max(getNum("aim_smooth", 5), 1))
                    pcall(function() mousemoverel(delta.X, delta.Y) end)
                end
            end
        end
    end

    -- Triggerbot
    if get("trg_on") and isKeybindActive(get("trg_keybind", {Key="E", Mode="Toggle"})) then
        local target = findTarget(60, get("trg_zone", "Head"), true, false)
        if target and math.random(1,100) <= getNum("trg_hit", 100) then
            if (os.clock() - (Prefs["trg_lastfire"] or 0)) > (getNum("trg_delay", 10) / 1000) then
                Prefs["trg_lastfire"] = os.clock()
                pcall(function()
                    local g = getgenv()
                    if type(g) == "table" and type(g.mouse1click) == "function" then g.mouse1click()
                    else VirtualUser:CaptureController(); VirtualUser:ClickButton1(Vector2.new()) end
                end)
            end
        end
    end
end)

-- Silent Aim
local silentPart = nil
RunService.RenderStepped:Connect(function()
    if not get("sil_on") or not isKeybindActive(get("sil_keybind", {Key="Always", Mode="Always"})) then silentPart = nil; return end
    local t = findTarget(getNum("sil_fov", 200), get("sil_bone", "Head"), get("sil_team", true), get("sil_visible", false))
    silentPart = t and t.part or nil
end)

pcall(function()
    if type(hookmetamethod) ~= "function" or type(getnamecallmethod) ~= "function" then return end
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if not checkcaller() and get("sil_on") and silentPart and silentPart.Parent and math.random(1, 100) <= getNum("sil_hit", 100) then
            local args = {...}
            if method == "Raycast" and self == Workspace then
                local origin = args[1]
                if typeof(origin) == "Vector3" then args[2] = (silentPart.Position - origin).Unit * 1000; return oldNamecall(self, table.unpack(args)) end
            elseif method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" then
                local ray = args[1]
                if typeof(ray) == "Ray" then args[1] = Ray.new(ray.Origin, (silentPart.Position - ray.Origin).Unit * 1000); return oldNamecall(self, table.unpack(args)) end
            end
        end
        return oldNamecall(self, ...)
    end)
end)

-- ESP
local ESP = {}
local BONES = {{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"}}

local function destroyESP(e)
    if e.Box then e.Box:Destroy() end
    if e.Label then e.Label:Destroy() end
    if e.Highlight then e.Highlight:Destroy() end
    if e.Bones then for _,b in pairs(e.Bones) do b:Destroy() end end
end

local function Get2DBox(cam, char)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local head = char:FindFirstChild("Head") or hrp
    local topPos = head.Position + Vector3.new(0, 0.5, 0)
    local botPos = hrp.Position - Vector3.new(0, 3, 0)
    local spTop, onTop = cam:WorldToViewportPoint(topPos)
    local spBot, onBot = cam:WorldToViewportPoint(botPos)
    if onTop and onBot then
        local h = math.abs(spBot.Y - spTop.Y)
        local w = h * 0.65
        return Vector2.new(spTop.X - w/2, spTop.Y), Vector2.new(spTop.X + w/2, spBot.Y)
    end
    return nil
end

RunService.RenderStepped:Connect(function()
    if not get("esp_on") then
        for k,e in pairs(ESP) do destroyESP(e); ESP[k] = nil end
        return
    end
    
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local seen = {}
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
            if not get("esp_team") or plr.Team ~= LocalPlayer.Team then
                local char = plr.Character
                local hrp = char.HumanoidRootPart
                local dist = (hrp.Position - cam.CFrame.Position).Magnitude
                
                if dist <= getNum("esp_dist", 1000) then
                    seen[char] = true
                    local e = ESP[char]
                    if not e then
                        e = {Bones = {}}
                        e.Box = new("Frame", {BackgroundTransparency = 1, Visible = false}, Overlay)
                        e.Stroke = new("UIStroke", {Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, e.Box)
                        e.Label = new("TextLabel", {BackgroundTransparency = 1, Size = UDim2.fromOffset(200,20), AnchorPoint = Vector2.new(0.5,1), Font = Enum.Font.Gotham, TextStrokeTransparency = 0.5, Visible = false}, Overlay)
                        e.Highlight = Instance.new("Highlight", Overlay)
                        ESP[char] = e
                    end
                    
                    local tl, br = Get2DBox(cam, char)
                    if tl and br then
                        local w, h = br.X - tl.X, br.Y - tl.Y
                        
                        if get("esp_box") then
                            e.Box.Position = UDim2.fromOffset(tl.X, tl.Y); e.Box.Size = UDim2.fromOffset(w, h); e.Box.Visible = true
                            e.Stroke.Color = Theme.accent
                        else e.Box.Visible = false end
                        
                        local parts = {}
                        if get("esp_name") then table.insert(parts, plr.Name) end
                        if get("esp_distlabel") then table.insert(parts, string.format("[%d]", dist)) end
                        if #parts > 0 then
                            e.Label.Text = table.concat(parts, " "); e.Label.TextSize = 13; e.Label.TextColor3 = Theme.accent
                            e.Label.Position = UDim2.fromOffset(tl.X + w/2, tl.Y - 4); e.Label.Visible = true
                        else e.Label.Visible = false end
                        
                        if get("esp_skel") then
                            for i, pair in ipairs(BONES) do
                                local line = e.Bones[i]
                                if not line then line = new("Frame", {AnchorPoint = Vector2.new(0.5,0.5), Visible=false}, Overlay); e.Bones[i] = line end
                                local a, b = char:FindFirstChild(pair[1]), char:FindFirstChild(pair[2])
                                if a and b then
                                    local sa, oa = cam:WorldToViewportPoint(a.Position)
                                    local sb, ob = cam:WorldToViewportPoint(b.Position)
                                    if oa and ob then
                                        local d = Vector2.new(sb.X, sb.Y) - Vector2.new(sa.X, sa.Y)
                                        line.Size = UDim2.fromOffset(d.Magnitude, 1)
                                        line.Position = UDim2.fromOffset((sa.X+sb.X)/2, (sa.Y+sb.Y)/2)
                                        line.Rotation = math.deg(math.atan2(d.Y, d.X))
                                        line.BackgroundColor3 = Theme.accent; line.Visible = true
                                    else line.Visible = false end
                                else line.Visible = false end
                            end
                        else for _,b in pairs(e.Bones) do b.Visible = false end end
                    else
                        e.Box.Visible = false; e.Label.Visible = false
                        for _,b in pairs(e.Bones) do b.Visible = false end
                    end
                    
                    if get("esp_chams") then
                        e.Highlight.Adornee = char; e.Highlight.FillColor = Theme.accent; e.Highlight.Enabled = true
                    else e.Highlight.Enabled = false end
                else
                    e.Box.Visible = false; e.Label.Visible = false; e.Highlight.Enabled = false
                    for _,b in pairs(e.Bones) do b.Visible = false end
                end
            end
        end
    end
    
    for k,e in pairs(ESP) do
        if not seen[k] then destroyESP(e); ESP[k] = nil end
    end
end)

-- PLAYER MODS (Noclip, Fly, Speed)
local flyBodyVel, flyBodyGyro = nil, nil
local noclipActive = false

RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end
    
    hum.WalkSpeed = getNum("plr_speed", 16)
    hum.JumpPower = getNum("plr_jump", 50)
    
    if get("plr_infjump") and UserInputService:IsKeyDown(Enum.KeyCode.Space) then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    
    -- Noclip Consertado
    if get("plr_noclip") then
        for _, v in ipairs(char:GetDescendants()) do 
            if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end 
        end
        noclipActive = true
    else
        if noclipActive then
            for _, v in ipairs(char:GetDescendants()) do 
                if v:IsA("BasePart") then v.CanCollide = true end 
            end
            noclipActive = false
        end
    end
    
    -- Fly
    if get("plr_fly") then
        if not flyBodyVel or flyBodyVel.Parent ~= hrp then
            if flyBodyVel then flyBodyVel:Destroy() end
            if flyBodyGyro then flyBodyGyro:Destroy() end
            flyBodyVel = Instance.new("BodyVelocity", hrp); flyBodyVel.MaxForce = Vector3.new(1e6, 1e6, 1e6)
            flyBodyGyro = Instance.new("BodyGyro", hrp); flyBodyGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6); flyBodyGyro.P = 10000
        end
        local cam = Workspace.CurrentCamera; local moveDir = Vector3.zero
        if get("plr_flymode", "Camera") == "WASD" then
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
        else moveDir = cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0,1,0) end
        
        flyBodyVel.Velocity = moveDir.Magnitude > 0 and (moveDir.Unit * getNum("plr_flyspeed", 50)) or Vector3.zero
        flyBodyGyro.CFrame = cam.CFrame * CFrame.Angles(math.rad(-90), 0, 0)
    else
        if flyBodyVel then flyBodyVel:Destroy(); flyBodyVel = nil end
        if flyBodyGyro then flyBodyGyro:Destroy(); flyBodyGyro = nil end
    end
    
    -- World / Weapon
    if get("vis_fullbright") then Lighting.Ambient = Color3.fromRGB(255,255,255); Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255)
    else Lighting.Ambient = Color3.fromRGB(70,70,70); Lighting.OutdoorAmbient = Color3.fromRGB(128,128,128) end
    
    for _, tool in pairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            if get("wpn_recoil") then
                for _, v in pairs(tool:GetDescendants()) do
                    if v:IsA("NumberValue") and v.Name:lower():find("recoil") then v.Value = 0 end
                end
            end
            if get("wpn_reload") then
                for _, v in pairs(tool:GetDescendants()) do
                    if v:IsA("NumberValue") and (v.Name:lower():find("reload") or v.Name:lower():find("cooldown")) then v.Value = 0 end
                end
            end
        end
    end
end)

LocalPlayer.Idled:Connect(function()
    if get("misc_afk", true) then VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end
end)

-- INPUTS
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    local mk = get("misc_menukey", {Key="RightShift", Mode="Toggle"})
    local match = (input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == mk.Key) or 
                  (input.UserInputType == Enum.UserInputType.MouseButton1 and mk.Key == "LMB") or 
                  (input.UserInputType == Enum.UserInputType.MouseButton2 and mk.Key == "RMB")
    if mk.Mode == "Toggle" and match then GUI.Enabled = not GUI.Enabled
    elseif mk.Mode == "Hold" and match then GUI.Enabled = true end
end)

UserInputService.InputEnded:Connect(function(input)
    local mk = get("misc_menukey", {Key="RightShift", Mode="Toggle"})
    local match = (input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == mk.Key) or 
                  (input.UserInputType == Enum.UserInputType.MouseButton1 and mk.Key == "LMB") or 
                  (input.UserInputType == Enum.UserInputType.MouseButton2 and mk.Key == "RMB")
    if mk.Mode == "Hold" and match then GUI.Enabled = false end
end)

-- DRAG & SLIDER
local dragging, dragStart, startPos = false, nil, nil
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = Main.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
    end
    if activeSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local pct = math.clamp((input.Position.X - activeSlider.btn.AbsolutePosition.X) / activeSlider.btn.AbsoluteSize.X, 0, 1)
        activeSlider.update(pct)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false; activeSlider = nil end
end)

-- CLEANUP
local cleaned = false
local function cleanup()
    if cleaned then return end; cleaned = true
    if shared.SonicHubCleanup == cleanup then shared.SonicHubCleanup = nil end
    for k,e in pairs(ESP) do destroyESP(e); ESP[k]=nil end
    if flyBodyVel then flyBodyVel:Destroy() end
    if flyBodyGyro then flyBodyGyro:Destroy() end
    Overlay:Destroy(); if GUI.Parent then GUI:Destroy() end
end
shared.SonicHubCleanup = cleanup
GUI.Destroying:Connect(cleanup)

GUI.Enabled = true
print("[Sonic Hub V34] Carregado com sucesso.")
