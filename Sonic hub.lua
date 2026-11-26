-- Sonic Hub V31 (Correção Total de Cores, ESP, Aimbot e Silent)
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

-- SISTEMA DE CORES
local Theme = {
    bg = Color3.fromRGB(255, 255, 255),
    panel = Color3.fromRGB(240, 240, 245),
    text = Color3.fromRGB(20, 20, 25),
    sub = Color3.fromRGB(100, 100, 110),
    accent = Color3.fromRGB(220, 50, 50),
    stroke = Color3.fromRGB(200, 200, 210),
    track = Color3.fromRGB(220, 220, 230),
}

local ThemeElements = {} -- Armazena elementos para atualizar cores sem recriar a UI
local function regTheme(inst, type)
    table.insert(ThemeElements, {inst = inst, type = type})
end

local function UpdateUITheme()
    for _, data in ipairs(ThemeElements) do
        local inst, t = data.inst, data.type
        if inst and inst.Parent then
            if t == "bg" then inst.BackgroundColor3 = Theme.bg
            elseif t == "panel" then inst.BackgroundColor3 = Theme.panel
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
    props.BackgroundTransparency = 1; props.Font = props.Font or Enum.Font.GothamBold
    props.TextColor3 = props.TextColor3 or Theme.text; props.TextSize = props.TextSize or 16
    props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
    local lbl = new("TextLabel", props, parent)
    if themeType then regTheme(lbl, themeType) end
    return lbl
end

local TWEEN_QUICK = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TWEEN_SLIDE = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local function tween(i, p, t) TweenService:Create(i, t or TWEEN_QUICK, p):Play() end

local GUI = new("ScreenGui", {Name = "SonicHub", ResetOnSpawn = false, DisplayOrder = 100, ZIndexBehavior = Enum.ZIndexBehavior.Global, Enabled = false}, PlayerGui)
local Overlay = new("ScreenGui", {Name = "SonicHubOverlay", ResetOnSpawn = false, DisplayOrder = 999, IgnoreGuiInset = true}, PlayerGui)

local Main = new("Frame", {Size = UDim2.fromOffset(800, 600), Position = UDim2.new(0.5, -400, 0.5, -300), BackgroundColor3 = Theme.bg, ClipsDescendants = true}, GUI, "bg")
corner(Main, 12); outline(Main, 2, Theme.stroke, "stroke")

local TitleBar = new("Frame", {Size = UDim2.new(1, 0, 0, 60), BackgroundColor3 = Theme.panel}, Main, "panel")
corner(TitleBar, 12)
new("Frame", {Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 1, -20), BackgroundColor3 = Theme.panel}, TitleBar, "panel")
new("Frame", {Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, -2), BackgroundColor3 = Theme.accent}, TitleBar, "accent")
label(TitleBar, {Size = UDim2.fromOffset(300, 60), Position = UDim2.fromOffset(20, 0), Text = "MARIO HUB V31", Font = Enum.Font.GothamBlack, TextSize = 26}, "text")

local closeBtn = new("TextButton", {Size = UDim2.fromOffset(36, 36), Position = UDim2.new(1, -46, 0.5, -18), BackgroundColor3 = Theme.accent, Text = "X", Font = Enum.Font.GothamBlack, TextSize = 18, TextColor3 = Color3.new(1,1,1), AutoButtonColor = false}, TitleBar, "accent")
corner(closeBtn, 8)
closeBtn.MouseButton1Click:Connect(function() GUI:Destroy() end)

local Body = new("Frame", {Position = UDim2.fromOffset(0, 60), Size = UDim2.new(1, 0, 1, -60), BackgroundTransparency = 1}, Main)
local Sidebar = new("Frame", {Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(180, 520), BackgroundColor3 = Theme.panel}, Body, "panel")
corner(Sidebar, 8); outline(Sidebar, 1, Theme.stroke, "stroke")

local NavList = new("ScrollingFrame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ScrollBarThickness = 0}, Sidebar)
new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, NavList)
new("UIPadding", {PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}, NavList)

local PageContainer = new("Frame", {Position = UDim2.fromOffset(200, 10), Size = UDim2.fromOffset(590, 520), BackgroundTransparency = 1}, Body)

local renderers = {}
local activeSlider = nil
local openDropdown = nil

local function CreateGroup(parent, title)
    local g = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Theme.panel}, parent, "panel")
    corner(g, 10); outline(g, 1.5, Theme.stroke, "stroke")
    new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}, g)
    local head = new("TextButton", {Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Text = "", LayoutOrder = 1}, g)
    label(head, {Size = UDim2.new(1, -30, 1, 0), Position = UDim2.fromOffset(16, 0), Text = title, Font = Enum.Font.GothamBlack, TextSize = 16}, "accent")
    local chev = label(head, {Size = UDim2.fromOffset(20, 40), Position = UDim2.new(1, -26, 0, 0), Text = "v", TextSize = 18}, "text")
    local body = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 2}, g)
    new("UIListLayout", {Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder}, body)
    new("UIPadding", {PaddingBottom = UDim.new(0, 16), PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16)}, body)
    head.MouseButton1Click:Connect(function() body.Visible = not body.Visible; tween(chev, {Rotation = body.Visible and 0 or -90}) end)
    return body
end

local function CreateToggle(parent, name, key, default)
    Prefs[key] = Prefs[key] or default
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1}, parent)
    label(row, {Size = UDim2.new(0.8, 0, 1, 0), Text = name}, "text")
    local sw = new("TextButton", {Size = UDim2.new(0, 44, 0, 24), Position = UDim2.new(1, -44, 0.5, -12), BackgroundColor3 = Theme.track, Text = "", AutoButtonColor = false}, row, "track")
    corner(sw, 12); outline(sw, 1, Theme.stroke, "stroke")
    local knob = new("Frame", {Size = UDim2.fromOffset(18, 18), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = Color3.new(1,1,1)}, sw); corner(knob, 9)
    
    local function render()
        local on = get(key)
        tween(sw, {BackgroundColor3 = on and Theme.accent or Theme.track})
        tween(knob, {Position = on and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3)})
    end
    renderers[key] = render
    sw.MouseButton1Click:Connect(function() set(key, not get(key)); render() end)
    render()
end

local function CreateSlider(parent, name, key, min, max, default)
    Prefs[key] = Prefs[key] or default
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 50), BackgroundTransparency = 1}, parent)
    label(row, {Size = UDim2.new(0.7, 0, 0, 20), Text = name}, "text")
    local valLbl = label(row, {Size = UDim2.new(0.3, 0, 0, 20), Position = UDim2.new(0.7, 0, 0, 0), Text = tostring(get(key)), TextXAlignment = Enum.TextXAlignment.Right}, "accent")
    local btn = new("TextButton", {Size = UDim2.new(1, 0, 0, 30), Position = UDim2.fromOffset(0, 22), BackgroundTransparency = 1, Text = ""}, row)
    local track = new("Frame", {Size = UDim2.new(1, 0, 0, 6), Position = UDim2.fromOffset(0, 12), BackgroundColor3 = Theme.track}, btn, "track"); corner(track, 3)
    local fill = new("Frame", {Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Theme.accent}, track); corner(fill, 3)
    local knob = new("Frame", {Size = UDim2.fromOffset(16, 16), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.new(1,1,1)}, track); corner(knob, 8); outline(knob, 1, Theme.stroke, "stroke")
    
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
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1}, parent)
    label(row, {Size = UDim2.new(1, 0, 0, 20), Text = name}, "text")
    local btn = new("TextButton", {Size = UDim2.new(1, 0, 0, 30), Position = UDim2.fromOffset(0, 22), BackgroundColor3 = Theme.bg, Text = "", AutoButtonColor = false}, row, "bg"); corner(btn, 6); outline(btn, 1.5, Theme.stroke, "stroke")
    local txt = label(btn, {Size = UDim2.new(1, -40, 1, 0), Position = UDim2.fromOffset(10, 0), Text = tostring(get(key)), TextSize = 15}, "text")
    local arrow = label(btn, {Size = UDim2.fromOffset(24, 30), Position = UDim2.new(1, -24, 0, 0), Text = "v", Font = Enum.Font.GothamBold}, "text")
    
    local list = new("Frame", {Size = UDim2.new(1, 0, 0, #options * 30), Position = UDim2.fromOffset(0, 56), BackgroundColor3 = Theme.panel, Visible = false, ZIndex = 999}, row, "panel")
    corner(list, 6); outline(list, 2, Theme.accent, "accent")
    for i, opt in ipairs(options) do
        local b = new("TextButton", {Size = UDim2.new(1, 0, 0, 30), Position = UDim2.fromOffset(0, (i - 1) * 30), BackgroundTransparency = 1, Text = opt, TextSize = 15, Font = Enum.Font.GothamBold, ZIndex = 1000}, list, "text")
        b.MouseEnter:Connect(function() b.BackgroundTransparency = 0.8; b.BackgroundColor3 = Theme.accent end)
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
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1}, parent)
    label(row, {Size = UDim2.new(1, 0, 0, 20), Text = name}, "text")
    local container = new("Frame", {Size = UDim2.new(1, 0, 0, 30), Position = UDim2.fromOffset(0, 22), BackgroundColor3 = Theme.bg}, row, "bg"); corner(container, 6); outline(container, 1.5, Theme.stroke, "stroke")
    
    local btnKey = new("TextButton", {Size = UDim2.new(0.5, -2, 1, 0), BackgroundTransparency = 1, Text = tostring(get(key).Key), TextSize = 15, Font = Enum.Font.GothamBold}, container, "text")
    local btnMode = new("TextButton", {Size = UDim2.new(0.5, -2, 1, 0), Position = UDim2.new(0.5, 2, 0, 0), BackgroundColor3 = Theme.track, Text = tostring(get(key).Mode), TextSize = 15, Font = Enum.Font.GothamBold}, container, "accent"); corner(btnMode, 6)
    
    btnMode.MouseButton1Click:Connect(function()
        local modes = {"Always", "Hold", "Toggle"}
        local curr = get(key).Mode; local nextMode = modes[1]
        for i, m in ipairs(modes) do if m == curr then nextMode = modes[(i % #modes) + 1] break end end
        set(key, {Key = get(key).Key, Mode = nextMode}); btnMode.Text = nextMode
    end)
    
    btnKey.MouseButton1Click:Connect(function()
        btnKey.Text = "Aperte..."
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

local Pages, NavButtons = {}, {}
local function AddPage(name, sub, buildFunc)
    local page = new("ScrollingFrame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ScrollBarThickness = 4, Visible = false, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0,0,0,0)}, PageContainer)
    new("UIListLayout", {Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder}, page)
    new("UIPadding", {PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 20)}, page)
    label(page, {Size = UDim2.new(1, 0, 0, 34), Text = name, Font = Enum.Font.GothamBlack, TextSize = 28, LayoutOrder = -2}, "text")
    label(page, {Size = UDim2.new(1, 0, 0, 20), Text = sub, TextSize = 14, LayoutOrder = -1, Font = Enum.Font.Gotham}, "sub")
    Pages[name] = page
    buildFunc(page)
end

local function SwitchPage(name)
    for n, p in pairs(Pages) do
        p.Visible = (n == name)
        if n == name then p.Position = UDim2.fromOffset(30, 0); tween(p, {Position = UDim2.fromOffset(0, 0)}, TWEEN_SLIDE) end
    end
    for n, b in pairs(NavButtons) do
        local sel = (n == name)
        tween(b.bg, {BackgroundColor3 = sel and Theme.accent or Theme.bg})
        tween(b.txt, {TextColor3 = sel and Color3.new(1,1,1) or Theme.text})
    end
end

local function AddNav(name)
    local btn = new("TextButton", {Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = Theme.bg, Text = "", AutoButtonColor = false}, NavList); corner(btn, 8); outline(btn, 1, Theme.stroke, "stroke")
    local txt = label(btn, {Size = UDim2.new(1, 0, 1, 0), Text = name, TextXAlignment = Enum.TextXAlignment.Center}, "text")
    NavButtons[name] = {bg = btn, txt = txt}
    btn.MouseButton1Click:Connect(function() SwitchPage(name) end)
end

AddPage("Settings", "Mude as cores e o visual", function(p)
    local g1 = CreateGroup(p, "Cores do Painel")
    CreateSlider(g1, "Fundo (R)", "color_bg_r", 0, 255, 255)
    CreateSlider(g1, "Fundo (G)", "color_bg_g", 0, 255, 255)
    CreateSlider(g1, "Fundo (B)", "color_bg_b", 0, 255, 255)
    
    local g2 = CreateGroup(p, "Cores de Destaque")
    CreateSlider(g2, "Destaque (R)", "color_ac_r", 0, 255, 220)
    CreateSlider(g2, "Destaque (G)", "color_ac_g", 0, 255, 50)
    CreateSlider(g2, "Destaque (B)", "color_ac_b", 0, 255, 50)
    
    local applyBtn = new("TextButton", {Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = Theme.accent, Text = "APLICAR CORES", Font = Enum.Font.GothamBlack, TextSize = 18, TextColor3 = Color3.new(1,1,1), AutoButtonColor = false}, p, "accent")
    corner(applyBtn, 8)
    applyBtn.MouseButton1Click:Connect(function()
        Theme.bg = Color3.fromRGB(getNum("color_bg_r", 255), getNum("color_bg_g", 255), getNum("color_bg_b", 255))
        Theme.panel = Theme.bg:Lerp(Color3.new(0,0,0), 0.05)
        Theme.accent = Color3.fromRGB(getNum("color_ac_r", 220), getNum("color_ac_g", 50), getNum("color_ac_b", 50))
        
        -- Inverte a cor do texto baseada no fundo para ficar visível
        if (Theme.bg.R + Theme.bg.G + Theme.bg.B) / 3 < 128 then
            Theme.text = Color3.new(1,1,1); Theme.sub = Color3.fromRGB(180,180,180)
            Theme.stroke = Color3.fromRGB(80,80,80); Theme.track = Color3.fromRGB(50,50,50)
        else
            Theme.text = Color3.fromRGB(20,20,20); Theme.sub = Color3.fromRGB(100,100,100)
            Theme.stroke = Color3.fromRGB(200,200,200); Theme.track = Color3.fromRGB(220,220,220)
        end
        
        UpdateUITheme()
    end)
end)

AddPage("Aimbot", "Camera & Mouse lock features", function(p)
    local g1 = CreateGroup(p, "Main Settings")
    CreateToggle(g1, "Enabled", "aim_on", false)
    CreateDropdown(g1, "Method", "aim_method", {"Camera Lock", "Mouse Lock"}, "Camera Lock")
    CreateDropdown(g1, "Bone", "aim_bone", {"Head", "UpperTorso", "HumanoidRootPart"}, "Head")
    CreateSlider(g1, "FOV", "aim_fov", 10, 600, 120)
    CreateSlider(g1, "Smoothness", "aim_smooth", 1, 20, 5)
    local g2 = CreateGroup(p, "Advanced")
    CreateToggle(g2, "Visible Only", "aim_visible", false)
    CreateToggle(g2, "Team Check", "aim_team", true)
    CreateKeybind(g2, "Aim Keybind", "aim_keybind", "RMB", "Hold")
end)

AddPage("Silent Aim", "Invisible target redirection", function(p)
    local g1 = CreateGroup(p, "Silent Aim")
    CreateToggle(g1, "Enabled", "sil_on", false)
    CreateDropdown(g1, "Bone", "sil_bone", {"Head", "UpperTorso", "HumanoidRootPart"}, "Head")
    CreateSlider(g1, "Hit Chance (%)", "sil_hit", 0, 100, 100)
    CreateSlider(g1, "FOV", "sil_fov", 10, 600, 200)
    local g2 = CreateGroup(p, "Extras")
    CreateKeybind(g2, "Silent Keybind", "sil_keybind", "Always", "Always")
end)

AddPage("Trigger Bot", "Auto fire when crosshair is on target", function(p)
    local g1 = CreateGroup(p, "Settings")
    CreateToggle(g1, "Enabled", "trg_on", false)
    CreateDropdown(g1, "Hit Zone", "trg_zone", {"Head", "UpperTorso", "HumanoidRootPart"}, "Head")
    CreateSlider(g1, "Delay (ms)", "trg_delay", 0, 500, 10)
    CreateSlider(g1, "Hit Chance (%)", "trg_hit", 0, 100, 100)
    local g2 = CreateGroup(p, "Keybind")
    CreateKeybind(g2, "Trigger Keybind", "trg_keybind", "E", "Toggle")
end)

AddPage("Visuals", "ESP, Chams & Colors", function(p)
    local g1 = CreateGroup(p, "ESP Settings")
    CreateToggle(g1, "Enabled", "esp_on", false)
    CreateSlider(g1, "Max Distance", "esp_dist", 100, 3000, 1000)
    CreateToggle(g1, "Team Check", "esp_team", true)
    local g2 = CreateGroup(p, "Elements")
    CreateToggle(g2, "Box", "esp_box", true)
    CreateToggle(g2, "Name", "esp_name", true)
    CreateToggle(g2, "Distance", "esp_distlabel", true)
    CreateToggle(g2, "Health Bar", "esp_health", true)
    CreateToggle(g2, "Skeleton", "esp_skel", false)
    CreateToggle(g2, "Tracer", "esp_tracer", false)
    local g3 = CreateGroup(p, "Chams / World")
    CreateToggle(g3, "Chams (Highlight)", "esp_chams", false)
    CreateToggle(g3, "FOV Circle", "vis_fovcircle", true)
    CreateToggle(g3, "Fullbright", "vis_fullbright", false)
end)

AddPage("Player", "Local character modifications", function(p)
    local g1 = CreateGroup(p, "Movement")
    CreateSlider(g1, "Walkspeed", "plr_speed", 16, 200, 16)
    CreateSlider(g1, "JumpPower", "plr_jump", 50, 200, 50)
    CreateToggle(g1, "Infinite Jump", "plr_infjump", false)
    CreateToggle(g1, "Noclip", "plr_noclip", false)
    local g2 = CreateGroup(p, "Fly")
    CreateToggle(g2, "Fly Enabled", "plr_fly", false)
    CreateSlider(g2, "Fly Speed", "plr_flyspeed", 10, 300, 50)
    CreateDropdown(g2, "Fly Mode", "plr_flymode", {"Camera", "WASD"}, "Camera")
end)

AddPage("Misc", "Weapon mods & utilities", function(p)
    local g1 = CreateGroup(p, "Weapon Mods")
    CreateToggle(g1, "No Recoil", "wpn_recoil", false)
    CreateToggle(g1, "Instant Reload", "wpn_reload", false)
    local g2 = CreateGroup(p, "Utilities")
    CreateToggle(g2, "Anti-AFK", "misc_afk", true)
    CreateKeybind(g2, "Menu Toggle Key", "misc_menukey", "RightShift", "Toggle")
end)

AddNav("Aimbot"); AddNav("Silent Aim"); AddNav("Trigger Bot"); AddNav("Visuals"); AddNav("Player"); AddNav("Misc"); AddNav("Settings")
SwitchPage("Aimbot")

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    local mk = get("misc_menukey", {Key="RightShift", Mode="Toggle"})
    local match = (input.KeyCode.Name == mk.Key) or (input.UserInputType == Enum.UserInputType.MouseButton1 and mk.Key == "LMB") or (input.UserInputType == Enum.UserInputType.MouseButton2 and mk.Key == "RMB")
    if mk.Mode == "Toggle" and match then GUI.Enabled = not GUI.Enabled
    elseif mk.Mode == "Hold" and match then GUI.Enabled = true end
end)
UserInputService.InputEnded:Connect(function(input)
    local mk = get("misc_menukey", {Key="RightShift", Mode="Toggle"})
    local match = (input.KeyCode.Name == mk.Key) or (input.UserInputType == Enum.UserInputType.MouseButton1 and mk.Key == "LMB") or (input.UserInputType == Enum.UserInputType.MouseButton2 and mk.Key == "RMB")
    if mk.Mode == "Hold" and match then GUI.Enabled = false end
end)

-- LÓGICA
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
local fovStroke = new("UIStroke", {Thickness = 2}, fovCircle)

RunService.RenderStepped:Connect(function()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    
    fovStroke.Color = Theme.accent
    
    if get("vis_fovcircle") and get("aim_on") then
        fovCircle.Position = UDim2.fromOffset(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
        fovCircle.Size = UDim2.fromOffset(getNum("aim_fov", 120) * 2, getNum("aim_fov", 120) * 2); fovCircle.Visible = true
    else fovCircle.Visible = false end
    
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

-- ESP (Matemática Direta Garantida)
local ESP = {}
local BONES = {{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"}}

local function destroyESP(e)
    if e.Box then e.Box:Destroy() end
    if e.Label then e.Label:Destroy() end
    if e.Highlight then e.Highlight:Destroy() end
    if e.Bones then for _,b in pairs(e.Bones) do b:Destroy() end end
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
                        e.Stroke = new("UIStroke", {Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, e.Box)
                        e.Label = new("TextLabel", {BackgroundTransparency = 1, Size = UDim2.fromOffset(200,20), AnchorPoint = Vector2.new(0.5,1), Font = Enum.Font.GothamBlack, TextStrokeTransparency = 0.5, Visible = false}, Overlay)
                        e.Highlight = Instance.new("Highlight", Overlay)
                        ESP[char] = e
                    end
                    
                    -- Projeção do tamanho
                    local head = char:FindFirstChild("Head") or hrp
                    local topPos = head.Position + Vector3.new(0, 0.5, 0)
                    local botPos = hrp.Position - Vector3.new(0, 3, 0)
                    local spTop, onTop = cam:WorldToViewportPoint(topPos)
                    local spBot, onBot = cam:WorldToViewportPoint(botPos)
                    
                    if onTop and onBot then
                        local h = spBot.Y - spTop.Y
                        local w = h * 0.6
                        local x, y = spTop.X - w/2, spTop.Y
                        
                        if get("esp_box") then
                            e.Box.Position = UDim2.fromOffset(x, y); e.Box.Size = UDim2.fromOffset(w, h); e.Box.Visible = true
                            e.Stroke.Color = Theme.accent
                        else e.Box.Visible = false end
                        
                        local parts = {}
                        if get("esp_name") then table.insert(parts, plr.Name) end
                        if get("esp_distlabel") then table.insert(parts, string.format("[%d]", dist)) end
                        if #parts > 0 then
                            e.Label.Text = table.concat(parts, " "); e.Label.TextSize = 14; e.Label.TextColor3 = Theme.accent
                            e.Label.Position = UDim2.fromOffset(spTop.X, y - 4); e.Label.Visible = true
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
                                        line.Size = UDim2.fromOffset(d.Magnitude, 1.5)
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

-- PLAYER MODS
local flyBodyVel, flyBodyGyro = nil, nil
RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end
    
    hum.WalkSpeed = getNum("plr_speed", 16)
    hum.JumpPower = getNum("plr_jump", 50)
    
    if get("plr_infjump") and UserInputService:IsKeyDown(Enum.KeyCode.Space) then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    if get("plr_noclip") then for _, v in ipairs(char:GetDescendants()) do if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end end end
    
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
    
    if get("vis_fullbright") then Lighting.Ambient = Color3.fromRGB(255,255,255); Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255)
    else Lighting.Ambient = Color3.fromRGB(70,70,70); Lighting.OutdoorAmbient = Color3.fromRGB(128,128,128) end
end)

LocalPlayer.Idled:Connect(function()
    if get("misc_afk", true) then VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end
end)

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
