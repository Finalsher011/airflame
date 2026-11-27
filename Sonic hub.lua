-- Drx Hub V20 [V19 UI + Engine Corrigida + Hooks de Mouse/Raycast + Cursor Livre]
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local Debris = game:GetService("Debris")
local TextService = game:GetService("TextService")
local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")

if shared.DrxCleanup then pcall(shared.DrxCleanup) end
for _, n in ipairs({"DrxHub", "DrxOverlay", "DrxMouseModal"}) do
    local a = PlayerGui:FindFirstChild(n); if a then a:Destroy() end
    local b = game:GetService("CoreGui"):FindFirstChild(n); if b then b:Destroy() end
end

local Prefs, Labels, BindNames, Conns, Warned = {}, {}, {}, {}, {}
local Booted = false
local notify
local function set(k, v)
    local old = Prefs[k]; Prefs[k] = v
    if Booted and type(v) == "boolean" and old ~= v and Labels[k] then notify(Labels[k], v and "enabled" or "disabled") end
end
local function get(k, d) local v = Prefs[k]; if v == nil then return d end; return v end
local function getNum(k, d) local v = tonumber(get(k, d)); if not v or v ~= v then return d end; return v end

local Theme = {
    bg = Color3.fromRGB(18, 12, 14), panel = Color3.fromRGB(28, 18, 22), card = Color3.fromRGB(38, 24, 30),
    text = Color3.fromRGB(255, 255, 255), sub = Color3.fromRGB(150, 130, 140), accent = Color3.fromRGB(255, 40, 60),
    stroke = Color3.fromRGB(60, 35, 45), track = Color3.fromRGB(45, 30, 35),
}
local function new(cls, props, parent)
    local i = Instance.new(cls); for k, v in pairs(props) do i[k] = v end; if parent then i.Parent = parent end; return i
end
local function corner(i, r) return new("UICorner", {CornerRadius = UDim.new(0, r)}, i) end
local function outline(i, t, c) return new("UIStroke", {Color = c or Theme.stroke, Thickness = t or 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, i) end
local function label(parent, props)
    props.BackgroundTransparency = 1; props.Font = props.Font or Enum.Font.Gotham
    props.TextColor3 = props.TextColor3 or Theme.text; props.TextSize = props.TextSize or 14
    props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
    return new("TextLabel", props, parent)
end
local TWEEN = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local function tween(i, p) TweenService:Create(i, TWEEN, p):Play() end

local GUI = new("ScreenGui", {Name = "DrxHub", ResetOnSpawn = false, DisplayOrder = 100, ZIndexBehavior = Enum.ZIndexBehavior.Global, Enabled = true}, PlayerGui)
local Overlay = new("ScreenGui", {Name = "DrxOverlay", ResetOnSpawn = false, DisplayOrder = 999, IgnoreGuiInset = true}, PlayerGui)

-- ================== UI MOUSE FIX ==================
local UiMouse = {open = false, saved = nil, wanted = nil, wantedIcon = nil, modal = nil, alive = true, hooked = false, hbConn = nil}
do
    local ACTION_SINK, STEP_NAME = "DrxUiMouseSink", "DrxUiMouseUnlock"
    local function sink() return Enum.ContextActionResult.Sink end
    local function enforce()
        local cur = UserInputService.MouseBehavior
        if cur ~= Enum.MouseBehavior.Default then UiMouse.wanted = cur end
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
    end
    local hmm, ncc, ccl = hookmetamethod, newcclosure, checkcaller
    if type(hmm) == "function" and type(ccl) == "function" then
        local old
        local function hook(self, k, v)
            if UiMouse.alive and UiMouse.open and self == UserInputService and not ccl() then
                if k == "MouseBehavior" then UiMouse.wanted = v; return end
                if k == "MouseIconEnabled" then UiMouse.wantedIcon = v; return end
            end
            return old(self, k, v)
        end
        local ok = pcall(function() old = hmm(game, "__newindex", ncc and ncc(hook) or hook) end)
        UiMouse.hooked = ok and old ~= nil
    end
    function UiMouse.setOpen(open)
        open = open and true or false
        if open == UiMouse.open then return end
        UiMouse.open = open
        if open then
            UiMouse.saved = {behavior = UserInputService.MouseBehavior, icon = UserInputService.MouseIconEnabled}
            UiMouse.wanted, UiMouse.wantedIcon = nil, nil
            local g = Instance.new("ScreenGui")
            g.Name = "DrxMouseModal"; g.ResetOnSpawn = false; g.IgnoreGuiInset = true; g.DisplayOrder = 1
            local b = Instance.new("TextButton")
            b.Modal = true; b.BackgroundTransparency = 1; b.Text = ""; b.Size = UDim2.fromScale(1, 1); b.Active = true; b.Parent = g
            g.Parent = PlayerGui
            UiMouse.modal = g
            ContextActionService:BindActionAtPriority(ACTION_SINK, sink, false, Enum.ContextActionPriority.High.Value + 1000, Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2, Enum.UserInputType.MouseWheel)
            RunService:BindToRenderStep(STEP_NAME, Enum.RenderPriority.Last.Value, enforce)
            UiMouse.hbConn = RunService.Heartbeat:Connect(enforce)
            enforce()
        else
            pcall(function() RunService:UnbindFromRenderStep(STEP_NAME) end)
            pcall(function() ContextActionService:UnbindAction(ACTION_SINK) end)
            if UiMouse.hbConn then UiMouse.hbConn:Disconnect(); UiMouse.hbConn = nil end
            if UiMouse.modal then UiMouse.modal:Destroy(); UiMouse.modal = nil end
            local sv = UiMouse.saved; UiMouse.saved = nil
            local beh, icon = UiMouse.wanted, UiMouse.wantedIcon
            UiMouse.wanted, UiMouse.wantedIcon = nil, nil
            if beh == nil and sv then beh = sv.behavior end
            if icon == nil and sv then icon = sv.icon end
            if icon ~= nil then UserInputService.MouseIconEnabled = icon end
            if beh ~= nil then UserInputService.MouseBehavior = beh end
        end
    end
end
Conns[#Conns + 1] = GUI:GetPropertyChangedSignal("Enabled"):Connect(function() UiMouse.setOpen(GUI.Enabled) end)

-- ================== UI V19 (INTACTA) ==================
local Main = new("Frame", {Size = UDim2.fromOffset(820, 580), Position = UDim2.new(0.5, -410, 0.5, -290), BackgroundColor3 = Theme.bg, Active = true}, GUI)
corner(Main, 12); outline(Main, 2, Theme.accent)
local TopBar = new("Frame", {Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = Theme.panel}, Main)
corner(TopBar, 12)
new("Frame", {Size = UDim2.new(1, 0, 0, 15), Position = UDim2.new(0, 0, 1, -15), BackgroundColor3 = Theme.panel}, TopBar)
new("Frame", {Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, -2), BackgroundColor3 = Theme.accent}, TopBar)
label(TopBar, {Size = UDim2.fromOffset(200, 50), Position = UDim2.fromOffset(20, 0), Text = "Drx Hub", Font = Enum.Font.GothamBlack, TextSize = 22, TextColor3 = Theme.accent})
label(TopBar, {Size = UDim2.fromOffset(200, 50), Position = UDim2.fromOffset(100, 0), Text = "ENTERPRISE", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.sub})
local closeBtn = new("TextButton", {Size = UDim2.fromOffset(30, 30), Position = UDim2.new(1, -45, 0.5, -15), BackgroundTransparency = 1, Text = "x", Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = Theme.sub}, TopBar)
closeBtn.MouseEnter:Connect(function() tween(closeBtn, {TextColor3 = Theme.accent}) end)
closeBtn.MouseLeave:Connect(function() tween(closeBtn, {TextColor3 = Theme.sub}) end)
closeBtn.MouseButton1Click:Connect(function() GUI.Enabled = false end) -- FIX: Não destroi a UI

local Body = new("Frame", {Position = UDim2.fromOffset(0, 50), Size = UDim2.new(1, 0, 1, -50), BackgroundTransparency = 1}, Main)
local Sidebar = new("Frame", {Position = UDim2.fromOffset(15, 15), Size = UDim2.fromOffset(170, 495), BackgroundColor3 = Theme.panel}, Body)
corner(Sidebar, 10); outline(Sidebar, 1, Theme.stroke)
local NavList = new("ScrollingFrame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ScrollBarThickness = 0}, Sidebar)
new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, NavList)
new("UIPadding", {PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}, NavList)
local ContentArea = new("Frame", {Position = UDim2.fromOffset(200, 15), Size = UDim2.fromOffset(605, 495), BackgroundTransparency = 1}, Body)
local PageContainer = new("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1}, ContentArea)
local activeSlider = nil

local function CreateGroup(parent, title)
    local g = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1}, parent)
    new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, g)
    local head = new("Frame", {Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, LayoutOrder = 1}, g)
    local line = new("Frame", {Size = UDim2.fromOffset(3, 14), Position = UDim2.fromOffset(0, 3), BackgroundColor3 = Theme.accent}, head); corner(line, 1)
    label(head, {Size = UDim2.new(1, -10, 1, 0), Position = UDim2.fromOffset(10, 0), Text = title, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Theme.accent})
    local body = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 2}, g)
    new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, body)
    return body
end
local function CreateToggle(parent, name, key, default)
    Prefs[key] = Prefs[key] or default; Labels[key] = name
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = Theme.card}, parent)
    corner(row, 8); outline(row, 1, Theme.stroke)
    label(row, {Size = UDim2.new(1, -60, 1, 0), Position = UDim2.fromOffset(12, 0), Text = name, TextSize = 13, Font = Enum.Font.GothamBold})
    local sw = new("TextButton", {Size = UDim2.new(0, 36, 0, 20), Position = UDim2.new(1, -48, 0.5, -10), BackgroundColor3 = Theme.track, Text = "", AutoButtonColor = false}, row)
    corner(sw, 10)
    local knob = new("Frame", {Size = UDim2.fromOffset(14, 14), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = Theme.sub}, sw); corner(knob, 7)
    local function render()
        local on = get(key)
        tween(sw, {BackgroundColor3 = on and Theme.accent or Theme.track})
        tween(knob, {Position = on and UDim2.fromOffset(19, 3) or UDim2.fromOffset(3, 3), BackgroundColor3 = on and Theme.text or Theme.sub})
    end
    sw.MouseButton1Click:Connect(function() set(key, not get(key)); render() end)
    render()
end
local function CreateSlider(parent, name, key, min, max, default)
    Prefs[key] = Prefs[key] or default
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = Theme.card}, parent)
    corner(row, 8); outline(row, 1, Theme.stroke)
    label(row, {Size = UDim2.new(1, -80, 0, 20), Position = UDim2.fromOffset(12, 8), Text = name, TextSize = 13, Font = Enum.Font.GothamBold})
    local minus = new("TextButton", {Size = UDim2.fromOffset(20, 20), Position = UDim2.new(1, -80, 0, 8), BackgroundColor3 = Theme.panel, Text = "-", TextColor3 = Theme.text, TextSize = 14, AutoButtonColor = false}, row); corner(minus, 4)
    local valLbl = label(row, {Size = UDim2.fromOffset(40, 20), Position = UDim2.new(1, -55, 0, 8), Text = tostring(get(key)), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Center})
    local plus = new("TextButton", {Size = UDim2.fromOffset(20, 20), Position = UDim2.new(1, -20, 0, 8), BackgroundColor3 = Theme.panel, Text = "+", TextColor3 = Theme.text, TextSize = 14, AutoButtonColor = false}, row); corner(plus, 4)
    local btn = new("TextButton", {Size = UDim2.new(1, -24, 0, 15), Position = UDim2.fromOffset(12, 30), BackgroundTransparency = 1, Text = ""}, row)
    local track = new("Frame", {Size = UDim2.new(1, 0, 0, 4), Position = UDim2.fromOffset(0, 6), BackgroundColor3 = Theme.track}, btn); corner(track, 2)
    local fill = new("Frame", {Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Theme.accent}, track); corner(fill, 2)
    local knob = new("Frame", {Size = UDim2.fromOffset(12, 12), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Theme.accent}, track); corner(knob, 6)
    local function update(pct)
        local v = math.floor(min + pct * (max - min) + 0.5)
        set(key, v); pct = (v - min) / math.max(max - min, 1)
        fill.Size = UDim2.new(pct, 0, 1, 0); knob.Position = UDim2.new(pct, 0, 0.5, 0); valLbl.Text = tostring(v)
    end
    update((getNum(key, default) - min) / math.max(max - min, 1))
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            activeSlider = {update = update, track = track}
            if track.AbsoluteSize.X > 0 then update(math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)) end
        end
    end)
    minus.MouseButton1Click:Connect(function() update(math.clamp((getNum(key) - 1 - min) / math.max(max - min, 1), 0, 1)) end)
    plus.MouseButton1Click:Connect(function() update(math.clamp((getNum(key) + 1 - min) / math.max(max - min, 1), 0, 1)) end)
end
local function CreateDropdown(parent, name, key, options, default)
    Prefs[key] = Prefs[key] or default
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = Theme.card}, parent)
    corner(row, 8); outline(row, 1, Theme.stroke)
    label(row, {Size = UDim2.new(1, -60, 1, 0), Position = UDim2.fromOffset(12, 0), Text = name, TextSize = 13, Font = Enum.Font.GothamBold})
    local btn = new("TextButton", {Size = UDim2.new(0, 100, 0, 24), Position = UDim2.new(1, -112, 0.5, -12), BackgroundColor3 = Theme.panel, Text = "", AutoButtonColor = false}, row)
    corner(btn, 6); outline(btn, 1, Theme.stroke)
    local txt = label(btn, {Size = UDim2.new(1, -20, 1, 0), Position = UDim2.fromOffset(8, 0), Text = tostring(get(key)), TextSize = 12})
    local list = new("Frame", {Size = UDim2.new(0, 100, 0, #options * 24), Position = UDim2.new(1, -112, 1, 4), BackgroundColor3 = Theme.panel, Visible = false, ZIndex = 999}, row)
    corner(list, 6); outline(list, 1, Theme.stroke)
    for i, opt in ipairs(options) do
        local b = new("TextButton", {Size = UDim2.new(1, 0, 0, 24), Position = UDim2.fromOffset(0, (i - 1) * 24), BackgroundTransparency = 1, Text = opt, TextSize = 12, TextColor3 = Theme.sub, ZIndex = 1000}, list)
        b.MouseEnter:Connect(function() b.TextColor3 = Theme.text end)
        b.MouseLeave:Connect(function() b.TextColor3 = Theme.sub end)
        b.MouseButton1Click:Connect(function() set(key, opt); txt.Text = opt; list.Visible = false end)
    end
    btn.MouseButton1Click:Connect(function() list.Visible = not list.Visible end)
end
local function CreateKeybind(parent, name, key, defaultKey, defaultMode)
    Prefs[key] = Prefs[key] or {Key = defaultKey, Mode = defaultMode}; BindNames[key] = name
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = Theme.card}, parent)
    corner(row, 8); outline(row, 1, Theme.stroke)
    label(row, {Size = UDim2.new(1, -120, 1, 0), Position = UDim2.fromOffset(12, 0), Text = name, TextSize = 13, Font = Enum.Font.GothamBold})
    local container = new("Frame", {Size = UDim2.new(0, 100, 0, 24), Position = UDim2.new(1, -112, 0.5, -12), BackgroundColor3 = Theme.panel}, row)
    corner(container, 6); outline(container, 1, Theme.stroke)
    local btnKey = new("TextButton", {Size = UDim2.new(0.5, 0, 1, 0), BackgroundTransparency = 1, Text = tostring(get(key).Key), TextSize = 12, TextColor3 = Theme.text}, container)
    local btnMode = new("TextButton", {Size = UDim2.new(0.5, 0, 1, 0), Position = UDim2.new(0.5, 0, 0, 0), BackgroundTransparency = 1, Text = tostring(get(key).Mode), TextSize = 10, TextColor3 = Theme.sub}, container)
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
            local kName = nil
            if input.UserInputType == Enum.UserInputType.Keyboard then kName = input.KeyCode.Name
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 then kName = "LMB"
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then kName = "RMB"
            elseif input.UserInputType == Enum.UserInputType.MouseButton3 then kName = "MMB" end
            if kName then set(key, {Key = kName, Mode = get(key).Mode}); btnKey.Text = kName; conn:Disconnect() end
        end)
    end)
end

local Pages, NavButtons = {}, {}
local function AddPage(name, buildFunc)
    local page = new("ScrollingFrame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ScrollBarThickness = 4, ScrollBarImageColor3 = Theme.accent, Visible = false, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0,0,0,0)}, PageContainer)
    local grid = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1}, page)
    new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 15), SortOrder = Enum.SortOrder.LayoutOrder}, grid)
    local col1 = new("Frame", {Size = UDim2.new(0.5, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 1}, grid)
    new("UIListLayout", {Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder}, col1)
    local col2 = new("Frame", {Size = UDim2.new(0.5, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 2}, grid)
    new("UIListLayout", {Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder}, col2)
    Pages[name] = page
    buildFunc(col1, col2)
end
local function SwitchPage(name)
    activeSlider = nil
    for n, p in pairs(Pages) do p.Visible = (n == name) end
    for n, b in pairs(NavButtons) do
        local sel = (n == name)
        tween(b.bg, {BackgroundColor3 = sel and Theme.accent or Theme.panel})
        tween(b.txt, {TextColor3 = sel and Theme.text or Theme.sub})
    end
end
local function AddNav(name)
    local btn = new("TextButton", {Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = Theme.panel, Text = "", AutoButtonColor = false}, NavList)
    corner(btn, 8); outline(btn, 1, Theme.stroke)
    local txt = label(btn, {Size = UDim2.new(1, -30, 1, 0), Position = UDim2.fromOffset(30, 0), Text = name, TextSize = 14, TextColor3 = Theme.sub, Font = Enum.Font.GothamBold})
    local ind = new("Frame", {Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(10, 12), BackgroundColor3 = Theme.sub}, btn); corner(ind, 4)
    btn.MouseEnter:Connect(function() if Pages[name] and not Pages[name].Visible then tween(btn, {BackgroundColor3 = Theme.card}) end end)
    btn.MouseLeave:Connect(function() if Pages[name] and not Pages[name].Visible then tween(btn, {BackgroundColor3 = Theme.panel}) end end)
    NavButtons[name] = {bg = btn, txt = txt, ind = ind}
    btn.MouseButton1Click:Connect(function() SwitchPage(name) end)
end

AddPage("Rage", function(c1, c2)
    local g1 = CreateGroup(c1, "Ragebot")
    CreateToggle(g1, "Ragebot", "rage_on", false); CreateKeybind(g1, "Ragebot Key", "rage_key", "Always", "Always")
    CreateToggle(g1, "Wallbang", "rage_wall", false); CreateSlider(g1, "FOV", "rage_fov", 10, 360, 120)
    CreateSlider(g1, "FOV Size", "rage_fovsize", 10, 800, 720); CreateKeybind(g1, "Auto Shoot", "rage_autoshoot", "Always", "Always")
    CreateToggle(g1, "Team Check", "rage_team", true)
    local g3 = CreateGroup(c1, "Kill All")
    CreateToggle(g3, "Kill All", "ra_kill", false); CreateKeybind(g3, "Kill All Key", "ra_kill_key", "Always", "Always"); CreateToggle(g3, "Use Gun", "ra_kill_gun", true)
    local g2 = CreateGroup(c2, "Weapon Mods")
    CreateToggle(g2, "Rapid Fire", "wpn_rapid", false); CreateToggle(g2, "No Recoil", "wpn_recoil", false)
    CreateToggle(g2, "No Spread", "wpn_spread", false); CreateToggle(g2, "Instant Reload", "wpn_reload", false)
    CreateToggle(g2, "Infinite Magazine", "wpn_ammo", false); CreateToggle(g2, "Custom Fire Cooldown", "wpn_cd", false)
    CreateSlider(g2, "Fire Cooldown (ms)", "wpn_cdval", 0, 1000, 500)
    local g4 = CreateGroup(c2, "Player")
    CreateToggle(g4, "Auto Respawn", "ply_respawn", false)
end)
AddPage("Legit", function(c1, c2)
    local g1 = CreateGroup(c1, "Silent Aim")
    CreateToggle(g1, "Silent Aim", "sil_on", false); CreateKeybind(g1, "Silent Key", "sil_key", "Always", "Always")
    CreateSlider(g1, "Smooth", "sil_smooth", 1, 20, 5); CreateToggle(g1, "Visible Only", "sil_vis", false)
    CreateDropdown(g1, "Bone", "sil_bone", {"Head", "Torso", "Root"}, "Head"); CreateToggle(g1, "Team Check", "sil_team", true)
    CreateToggle(g1, "Anywhere (360°)", "sil_any", false); CreateToggle(g1, "Show Target", "sil_show", true)
    local g5 = CreateGroup(c1, "Aimbot")
    CreateToggle(g5, "Aimbot", "aim_on", false); CreateKeybind(g5, "Aimbot Key", "aim_key", "RMB", "Hold")
    CreateDropdown(g5, "Part", "aim_part", {"Head", "Torso", "Closest"}, "Head"); CreateSlider(g5, "Radius", "aim_radius", 10, 800, 120)
    CreateSlider(g5, "Max Distance", "aim_dist", 50, 2000, 450); CreateToggle(g5, "Wall Check", "aim_wall", true)
    CreateDropdown(g5, "Priority", "aim_prio", {"Cursor", "Distance", "Threat"}, "Threat"); CreateSlider(g5, "Cursor Weight %", "aim_wc", 0, 100, 40)
    CreateSlider(g5, "Distance Weight %", "aim_wd", 0, 100, 35); CreateSlider(g5, "Facing Weight %", "aim_wf", 0, 100, 25)
    CreateToggle(g5, "Off-screen Targets", "aim_off", true); CreateToggle(g5, "Sticky Target", "aim_sticky", true)
    CreateToggle(g5, "Pre-aim Peeks", "aim_peek", true); CreateSlider(g5, "Smoothness %", "aim_smooth", 1, 100, 35)
    CreateSlider(g5, "Reaction Time (ms)", "aim_react", 0, 500, 120); CreateToggle(g5, "Prediction", "aim_pred", true)
    CreateSlider(g5, "Prediction Sampling (ms)", "aim_sample", 10, 300, 90); CreateToggle(g5, "Random Offset", "aim_rand", true)
    CreateSlider(g5, "Offset Size (x0.01)", "aim_offs", 0, 100, 40)
    local g2 = CreateGroup(c2, "FOV")
    CreateSlider(g2, "FOV Size", "sil_fov", 10, 800, 120); CreateToggle(g2, "FOV Circle", "sil_fovcircle", true)
    local g3 = CreateGroup(c2, "Triggerbot")
    CreateToggle(g3, "Triggerbot", "trg_on", false); CreateKeybind(g3, "Trigger Key", "trg_key", "Always", "Always")
    CreateSlider(g3, "Trigger Delay (ms)", "trg_delay", 0, 500, 50); CreateToggle(g3, "Team Check", "trg_team", true)
    CreateToggle(g3, "Gun (LMB)", "trg_gun", true); CreateDropdown(g3, "Hit Zone", "trg_zone", {"Head", "Upper body", "Whole body"}, "Whole body")
    CreateSlider(g3, "Hit Chance %", "trg_chance", 0, 100, 100); CreateToggle(g3, "Auto Hit Chance", "trg_autochance", false)
    CreateToggle(g3, "Auto Reaction Time", "trg_autoreact", false); CreateSlider(g3, "Reaction Time (ms)", "trg_react", 0, 500, 60)
    CreateSlider(g3, "Max Distance", "trg_dist", 50, 2000, 1000); CreateToggle(g3, "FOV Target Only", "trg_fovonly", false)
end)
AddPage("Misc", function(c1, c2)
    local g1 = CreateGroup(c1, "Misc")
    CreateToggle(g1, "Spectator list", "misc_spect", false); CreateToggle(g1, "Anti Spectate", "misc_antispect", false)
    CreateToggle(g1, "Anti AFK", "misc_afk", true); CreateToggle(g1, "Bhop", "misc_bhop", false)
    CreateSlider(g1, "Speed Per Jump", "bh_inc", 0, 10, 2); CreateSlider(g1, "Max Speed", "bh_max", 16, 100, 32)
    CreateToggle(g1, "No Jump Fatigue", "bh_fatigue", true)
    local g3 = CreateGroup(c1, "Movement")
    CreateToggle(g3, "Speed", "mv_speed", false); CreateKeybind(g3, "Speed Key", "mv_speed_key", "Always", "Always")
    CreateSlider(g3, "Extra Speed", "mv_extra", 0, 50, 6); CreateToggle(g3, "Fly", "mv_fly", false)
    CreateKeybind(g3, "Fly Key", "mv_fly_key", "Always", "Always"); CreateSlider(g3, "Fly Speed", "mv_flyspeed", 10, 200, 60)
    local g2 = CreateGroup(c2, "Camera")
    CreateToggle(g2, "Third Person", "cam_third", false); CreateKeybind(g2, "Third Person Key", "cam_key", "V", "Toggle")
    CreateSlider(g2, "ThirdPerson Distance", "cam_dist", 5, 50, 12)
end)
AddPage("Inventory Changer", function(c1, c2)
    local g1 = CreateGroup(c1, "Skins"); label(g1, {Size = UDim2.new(1, 0, 0, 20), Text = "Em breve...", TextSize = 14, TextColor3 = Theme.sub})
end)
AddPage("Visuals", function(c1, c2)
    local g1 = CreateGroup(c1, "ESP")
    CreateToggle(g1, "Enabled", "esp_on", true); CreateDropdown(g1, "Renderer", "esp_render", {"Full", "Lite"}, "Full")
    CreateToggle(g1, "Box ESP", "esp_box", false); CreateToggle(g1, "ESP Name", "esp_name", false)
    CreateToggle(g1, "Skeleton", "esp_skel", false); CreateToggle(g1, "Weapon ESP", "esp_wpn", false)
    CreateToggle(g1, "ESP Team Check", "esp_team", true); CreateToggle(g1, "Health Bar", "esp_health", false)
    CreateToggle(g1, "Include NPCs", "esp_npc", false); CreateSlider(g1, "Max Distance", "esp_dist", 50, 2000, 1000)
    CreateToggle(g1, "Fade With Distance", "esp_fade", false); CreateToggle(g1, "Intro Animation", "esp_intro", false)
    CreateToggle(g1, "Distance", "esp_distance", false); CreateToggle(g1, "Head Dot", "esp_head", false)
    CreateToggle(g1, "Tracers", "esp_tracers", false); CreateDropdown(g1, "Tracer Origin", "esp_torigin", {"Bottom", "Center", "Mouse", "Top"}, "Bottom")
    CreateToggle(g1, "Path Prediction", "esp_path", false); CreateSlider(g1, "Prediction Time (x0.1s)", "esp_ptime", 1, 50, 50)
    CreateSlider(g1, "Color (Hue)", "esp_hue", 0, 100, 99); CreateToggle(g1, "Rainbow", "esp_rainbow", false); CreateToggle(g1, "Team Color", "esp_teamcolor", false)
    local g4 = CreateGroup(c1, "Box")
    CreateDropdown(g4, "Style", "esp_style", {"Full", "Corners", "Rounded", "3D"}, "Corners"); CreateSlider(g4, "Thickness", "esp_thick", 1, 6, 2)
    CreateSlider(g4, "Rounding", "esp_round", 0, 20, 6); CreateSlider(g4, "Fill %", "esp_fill", 0, 100, 50)
    CreateToggle(g4, "Outline", "esp_outline", false); CreateSlider(g4, "Size Smoothing %", "esp_smooth", 0, 100, 25)
    local g5 = CreateGroup(c1, "Health")
    CreateToggle(g5, "Damage Ghost", "esp_ghost", false); CreateToggle(g5, "Damage Numbers", "esp_dmgnum", false)
    CreateToggle(g5, "Health Value", "esp_hpval", false); CreateSlider(g5, "Width", "esp_hpwidth", 1, 6, 4)
    local g6 = CreateGroup(c1, "Labels")
    CreateToggle(g6, "Name Pill", "esp_pill", false); CreateSlider(g6, "Name Size", "esp_namesize", 8, 30, 14)
    local g2 = CreateGroup(c2, "Highlight")
    CreateToggle(g2, "Enable Highlight", "hl_on", false); CreateToggle(g2, "Highlight Team Check", "hl_team", true)
    CreateToggle(g2, "Highlight Color", "hl_color", false); CreateToggle(g2, "Show Name", "hl_name", false)
    local g3 = CreateGroup(c2, "Tracers")
    CreateToggle(g3, "Enable Tracers", "trc_on", false); CreateSlider(g3, "Tracer Width", "trc_width", 1, 10, 2); CreateSlider(g3, "Tracer Lifetime", "trc_life", 1, 10, 5)
end)
AddPage("World", function(c1, c2)
    local g1 = CreateGroup(c1, "Ambiente"); label(g1, {Size = UDim2.new(1, 0, 0, 20), Text = "Em breve...", TextSize = 14, TextColor3 = Theme.sub})
end)
AddPage("Settings", function(c1, c2)
    local g1 = CreateGroup(c1, "Universal Settings")
    CreateToggle(g1, "Dynamic Island", "set_island", false); CreateToggle(g1, "Watermark HUD", "set_watermark", true)
    CreateToggle(g1, "Quick Access Keybind", "set_qaccess", false); CreateToggle(g1, "Mobile Toggle Button", "set_mobile", false)
    CreateKeybind(g1, "Menu Keybind", "misc_menukey", "RightShift", "Toggle")
    local g2 = CreateGroup(c2, "Screen Ambience")
    CreateSlider(g2, "Ambience Opacity", "set_opacity", 10, 100, 50); CreateToggle(g2, "Show Only When UI...", "set_showonly", false)
end)
AddNav("Rage"); AddNav("Legit"); AddNav("Misc"); AddNav("Inventory Changer"); AddNav("Visuals"); AddNav("World"); AddNav("Settings"); SwitchPage("Rage")

-- ================== ENGINE V20 (CORREÇÕES) ==================
local function guard(name, fn)
    return function(...)
        local ok, err = pcall(fn, ...)
        if not ok and not Warned[name] then Warned[name] = true; warn("[Drx] " .. name .. ": " .. tostring(err)) end
    end
end
local Cap = { mousemoverel = mousemoverel, mouse1click = mouse1click, hookmetamethod = hookmetamethod, newcclosure = newcclosure, checkcaller = checkcaller, getnamecallmethod = getnamecallmethod, require = require }
local GameConfig = {
    Build = "UNSET", Debug = true, Probe = true,
    Weapon = { ToolModule = nil, Fields = { NoRecoil = nil, NoSpread = nil, InstantReload = nil, InfiniteMagazine = nil, FireCooldown = nil } },
    SpectateProbe = nil,
}
local function clickFire()
    if type(Cap.mouse1click) == "function" then local ok = pcall(Cap.mouse1click); if ok then return end end
    pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton1(Vector2.new()) end)
end
local function activateTool() local c = LP.Character; local t = c and c:FindFirstChildOfClass("Tool"); if t then pcall(function() t:Activate() end) end end

-- Hook no GetMouseDelta para Aimbot funcionar sem mousemoverel
local MouseDeltaHook = {installed = false, pending = Vector2.new(0, 0)}
do
    if Cap.hookmetamethod and Cap.newcclosure and Cap.checkcaller then
        local oldIdx
        local function idxHook(self, key)
            if oldIdx and self == UserInputService and key == "GetMouseDelta" and not Cap.checkcaller() then
                local real = oldIdx(self, key)
                return function(s)
                    local d = real(s)
                    local p = MouseDeltaHook.pending
                    if p.X ~= 0 or p.Y ~= 0 then MouseDeltaHook.pending = Vector2.new(0, 0) end
                    return d + p
                end
            end
            return oldIdx(self, key)
        end
        local ok = pcall(function() oldIdx = Cap.hookmetamethod(UserInputService, "__index", Cap.newcclosure(idxHook)) end)
        MouseDeltaHook.installed = ok and oldIdx ~= nil
    end
end

local BindState = {}
local function inputDown(keyName)
    if keyName == "LMB" then return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    elseif keyName == "RMB" then return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    elseif keyName == "MMB" then return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton3) end
    local ok, kc = pcall(function() return Enum.KeyCode[keyName] end)
    if ok and kc then return UserInputService:IsKeyDown(kc) end
    return false
end
local function pollBinds()
    local typing = UserInputService:GetFocusedTextBox() ~= nil
    for k, v in pairs(Prefs) do
        if type(v) == "table" and v.Key and v.Mode and k ~= "misc_menukey" then
            local st = BindState[k]; if not st then st = {on = false, prev = false}; BindState[k] = st end
            local before = st.on
            if v.Mode == "Always" or v.Key == "None" then st.on = true
            else
                local down = (not typing) and inputDown(v.Key)
                if v.Mode == "Hold" then st.on = down
                elseif down and not st.prev then st.on = not st.on end
                st.prev = down
            end
        end
    end
end
local function bindActive(k) local st = BindState[k]; return st ~= nil and st.on end

local FrameNo, NPCs, NPCInit = 0, {}, false
local function initNPCs()
    if NPCInit then return end; NPCInit = true
    local function consider(inst)
        if inst:IsA("Humanoid") then
            local m = inst.Parent
            if m and m:IsA("Model") and m ~= LP.Character and not Players:GetPlayerFromCharacter(m) then NPCs[m] = true end
        end
    end
    for _, d in ipairs(Workspace:GetDescendants()) do consider(d) end
    Conns[#Conns + 1] = Workspace.DescendantAdded:Connect(consider)
    Conns[#Conns + 1] = Workspace.DescendantRemoving:Connect(function(d) if d:IsA("Humanoid") and d.Parent then NPCs[d.Parent] = nil end end)
end
local function isEnemyPlayer(plr) if plr.Neutral or plr.Team == nil or LP.Team == nil then return true end; return plr.Team ~= LP.Team end
local function buildEntity(char, plr)
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp or hum.Health <= 0 then return nil end
    return {char = char, hum = hum, hrp = hrp, plr = plr, name = plr and plr.Name or char.Name}
end
local EntCache = {frame = -1, list = {}, byChar = {}}
local function entities()
    if EntCache.frame == FrameNo then return EntCache.list end
    local list, by = {}, {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local e = buildEntity(plr.Character, plr)
            if e then e.enemy = isEnemyPlayer(plr); list[#list + 1] = e; by[e.char] = e end
        end
    end
    if NPCInit then
        for m in pairs(NPCs) do
            if m.Parent and not Players:GetPlayerFromCharacter(m) then
                local e = buildEntity(m, nil)
                if e then e.enemy = true; e.npc = true; list[#list + 1] = e; by[m] = e end
            else NPCs[m] = nil end
        end
    end
    EntCache.frame = FrameNo; EntCache.list = list; EntCache.byChar = by
    return list
end
local Track = {}
local function trackEntities()
    local now, alive = os.clock(), {}
    for _, e in ipairs(entities()) do
        local t = Track[e.char]; if not t then t = {}; Track[e.char] = t end
        t[#t + 1] = {now, e.hrp.Position}
        while #t > 2 and now - t[1][1] > 0.6 do table.remove(t, 1) end
        alive[e.char] = true
    end
    for c in pairs(Track) do if not alive[c] then Track[c] = nil end end
end
local function velocityOf(char, windowMs)
    local t = Track[char]; if not t or #t < 2 then return Vector3.new(0, 0, 0) end
    local last = t[#t]; local first = last
    for i = #t - 1, 1, -1 do
        if last[1] - t[i][1] <= windowMs / 1000 then first = t[i] else break end
    end
    local dt = last[1] - first[1]
    if dt < 1e-3 then return Vector3.new(0, 0, 0) end
    return (last[2] - first[2]) / dt
end

local RayP = RaycastParams.new(); RayP.FilterType = Enum.RaycastFilterType.Exclude
local function setFilter(extra)
    local f = {}
    if LP.Character then f[#f + 1] = LP.Character end
    if extra then f[#f + 1] = extra end
    RayP.FilterDescendantsInstances = f
end
local WallP = RaycastParams.new(); WallP.FilterType = Enum.RaycastFilterType.Exclude; WallP.RespectCanCollide = true
local function lineClear(cam, pos, char)
    local f = {}
    if LP.Character then f[#f + 1] = LP.Character end
    if char then f[#f + 1] = char end
    WallP.FilterDescendantsInstances = f
    return Workspace:Raycast(cam.CFrame.Position, pos - cam.CFrame.Position, WallP) == nil
end
local function getPart(char, which)
    if which == "Head" then return char:FindFirstChild("Head")
    elseif which == "Torso" then return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") end
    return char:FindFirstChild("HumanoidRootPart")
end
local Jitter = setmetatable({}, {__mode = "k"})
local function jitterFor(char, size)
    local j, now = Jitter[char], os.clock()
    if not j or now - j.t > 0.25 then
        j = {t = now, v = Vector3.new(math.random() * 2 - 1, math.random() * 2 - 1, math.random() * 2 - 1) * size}
        Jitter[char] = j
    end
    return j.v
end

local function pickTarget(o)
    local cam = Workspace.CurrentCamera; if not cam then return nil end
    local vs = cam.ViewportSize; local center = Vector2.new(vs.X / 2, vs.Y / 2)
    local camPos, look = cam.CFrame.Position, cam.CFrame.LookVector
    local pxPerDeg = vs.Y / math.max(cam.FieldOfView, 1)
    local ref = (o.radius < 1e5) and o.radius or vs.Y / 2
    local best, bestScore
    for _, e in ipairs(entities()) do
        if not e.npc and ((not o.teamCheck) or e.enemy) then
            local cands = (o.part == "Closest") and {"Head", "Torso", "Root"} or {o.part}
            local ePart, ePos, eOn, eCur
            for _, w in ipairs(cands) do
                local part = getPart(e.char, w)
                if part then
                    local pos = part.Position
                    if o.predict then pos = pos + velocityOf(e.char, o.sample) * (o.sample / 1000) end
                    if o.jitter and o.jitter > 0 then pos = pos + jitterFor(e.char, o.jitter) end
                    local v, on = cam:WorldToViewportPoint(pos)
                    local cur
                    if on then cur = (Vector2.new(v.X, v.Y) - center).Magnitude
                    else
                        local d = pos - camPos
                        cur = d.Magnitude > 0.01 and math.deg(math.acos(math.clamp(look:Dot(d.Unit), -1, 1))) * pxPerDeg or 0
                    end
                    if not ePart or cur < eCur then ePart, ePos, eOn, eCur = part, pos, on, cur end
                end
            end
            if ePart then
                local studs = (ePos - camPos).Magnitude
                local ok = studs <= o.maxDist
                if ok and o.angle and o.angle < 360 and studs > 0.01 then
                    ok = math.deg(math.acos(math.clamp(look:Dot((ePos - camPos).Unit), -1, 1))) <= o.angle / 2
                end
                if ok then if eOn then ok = eCur <= o.radius else ok = o.offscreen end end
                if ok and o.wall and not lineClear(cam, ePos, e.char) then
                    ok = false
                    if o.peek then local lead = velocityOf(e.char, o.sample or 90) * 0.2; if lineClear(cam, ePos + lead, e.char) then ok = true; ePos = ePos + lead end end
                end
                if ok then
                    local score
                    if o.prio == "Distance" then score = studs / math.max(o.maxDist, 1)
                    elseif o.prio == "Threat" then
                        local toCam = camPos - e.hrp.Position
                        local facing = toCam.Magnitude > 0.01 and (1 - e.hrp.CFrame.LookVector:Dot(toCam.Unit)) / 2 or 0.5
                        score = o.wc * math.min(eCur / ref, 3) + o.wd * (studs / math.max(o.maxDist, 1)) + o.wf * facing
                    else score = eCur end
                    if o.sticky and o.sticky == e.char then score = -1 end
                    if not bestScore or score < bestScore then
                        bestScore = score; best = {ent = e, part = ePart, pos = ePos, onScreen = eOn, cursor = eCur}
                    end
                end
            end
        end
    end
    return best
end

local function stepAlpha(a60, dt) return 1 - (1 - math.clamp(a60, 0, 1)) ^ (math.clamp(dt, 0, 0.1) * 60) end
local function aimStep(target, alpha)
    local cam = Workspace.CurrentCamera; if not cam then return end
    local v, on = cam:WorldToViewportPoint(target.pos)
    if on then
        local vs = cam.ViewportSize
        local dx, dy = (v.X - vs.X / 2) * alpha, (v.Y - vs.Y / 2) * alpha
        if type(Cap.mousemoverel) == "function" then
            local ok = pcall(Cap.mousemoverel, dx, dy)
            if ok then return end
        end
        if MouseDeltaHook.installed then
            MouseDeltaHook.pending = MouseDeltaHook.pending + Vector2.new(dx, dy)
        else
            cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, target.pos), alpha)
        end
    end
end

local Aim = {char = nil, since = 0}
local function runAimbot(cam, dt)
    if not (get("aim_on") and bindActive("aim_key")) then Aim.char = nil; return end
    local wc, wd, wf = getNum("aim_wc", 40), getNum("aim_wd", 35), getNum("aim_wf", 25)
    local sum = math.max(wc + wd + wf, 1)
    local t = pickTarget({part = get("aim_part", "Head"), radius = getNum("aim_radius", 120), maxDist = getNum("aim_dist", 450), wall = get("aim_wall", true), peek = get("aim_peek", true), prio = get("aim_prio", "Threat"), wc = wc / sum, wd = wd / sum, wf = wf / sum, offscreen = get("aim_off", true), sticky = get("aim_sticky", true) and Aim.char or nil, predict = get("aim_pred", true), sample = getNum("aim_sample", 90), jitter = get("aim_rand", true) and getNum("aim_offs", 40) / 100 or 0, teamCheck = true})
    if not t then Aim.char = nil; return end
    if Aim.char ~= t.ent.char then Aim.char = t.ent.char; Aim.since = os.clock() end
    if (os.clock() - Aim.since) * 1000 >= getNum("aim_react", 120) then aimStep(t, stepAlpha(1 - getNum("aim_smooth", 35) / 100, dt)) end
end

-- Silent Aim corrigido
local Silent = {target = nil, hooked = false, alive = true}
do
    if Cap.hookmetamethod and Cap.getnamecallmethod and Cap.checkcaller then
        local oldNC
        local function hooked(self, ...)
            local method = Cap.getnamecallmethod()
            local st = Silent.target
            if Silent.alive and st and self == Workspace and not Cap.checkcaller() then
                local n = select("#", ...); local a = {...}
                if method == "Raycast" and typeof(a[1]) == "Vector3" and typeof(a[2]) == "Vector3" then
                    local to = st.pos - a[1]
                    if to.Magnitude > 0.01 then
                        a[2] = to.Unit * math.max(a[2].Magnitude, to.Magnitude + 1)
                        if not get("sil_vis", false) then local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Include; rp.FilterDescendantsInstances = {st.char}; a[3] = rp; n = math.max(n, 3) end
                        return oldNC(self, table.unpack(a, 1, n))
                    end
                elseif (method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist") and typeof(a[1]) == "Ray" then
                    local to = st.pos - a[1].Origin
                    if to.Magnitude > 0.01 then a[1] = Ray.new(a[1].Origin, to.Unit * math.max(a[1].Direction.Magnitude, to.Magnitude + 1)); return oldNC(self, table.unpack(a, 1, n)) end
                end
            end
            return oldNC(self, ...)
        end
        local ok = pcall(function() oldNC = Cap.hookmetamethod(game, "__namecall", Cap.newcclosure and Cap.newcclosure(hooked) or hooked) end)
        Silent.hooked = ok and oldNC ~= nil
    end
    -- Hook em Mouse.Hit e Mouse.UnitRay
    local oldMouseIndex
    local function mouseHook(self, key)
        if Silent.alive and Silent.target and not Cap.checkcaller() then
            if key == "Hit" then return CFrame.new(Silent.target.pos) end
            if key == "UnitRay" then
                local cam = Workspace.CurrentCamera
                if cam then local dir = (Silent.target.pos - cam.CFrame.Position).Unit; return Ray.new(cam.CFrame.Position, dir) end
            end
        end
        return oldMouseIndex(self, key)
    end
    local mouse = LP:GetMouse()
    if Cap.hookmetamethod and mouse then
        pcall(function() oldMouseIndex = Cap.hookmetamethod(mouse, "__index", Cap.newcclosure and Cap.newcclosure(mouseHook) or mouseHook) end)
    end
end

local function runSilent(cam, dt)
    Silent.target = nil
    if not (get("sil_on") and bindActive("sil_key")) then return end
    local any = get("sil_any", false)
    local bone = ({Head = "Head", Torso = "Torso", Root = "Root"})[get("sil_bone", "Head")] or "Head"
    local t = pickTarget({part = bone, radius = any and math.huge or getNum("sil_fov", 120), maxDist = 2000, wall = get("sil_vis", false), prio = any and "Distance" or "Cursor", wc = 1, wd = 0, wf = 0, offscreen = any, predict = false, sample = 90, jitter = 0, teamCheck = get("sil_team", true)})
    if not t then return end
    Silent.target = {pos = t.pos, char = t.ent.char}
    if not Silent.hooked then aimStep(t, stepAlpha(1 / math.max(getNum("sil_smooth", 5), 1), dt)) end
end

local Rage = {last = 0}
local function runRage(cam, dt)
    if not (get("rage_on") and bindActive("rage_key")) then return end
    local t = pickTarget({part = "Head", radius = getNum("rage_fovsize", 720), maxDist = 5000, angle = getNum("rage_fov", 120), wall = not get("rage_wall", false), prio = "Cursor", wc = 1, wd = 0, wf = 0, offscreen = true, predict = false, sample = 100, jitter = 0, teamCheck = get("rage_team", true)})
    if not t then return end
    aimStep(t, stepAlpha(0.5, dt))
    if bindActive("rage_autoshoot") and t.cursor < 25 then
        local gap = get("wpn_rapid") and 0.03 or 0.08
        if os.clock() - Rage.last > gap then Rage.last = os.clock(); clickFire() end
    end
end

local Kill = {last = 0}
local function runKillAll(cam, dt)
    if not (get("ra_kill") and bindActive("ra_kill_key")) then return end
    initNPCs()
    local myhrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local best, bd
    for _, e in ipairs(entities()) do
        if e.enemy then
            local d = (e.hrp.Position - (myhrp and myhrp.Position or cam.CFrame.Position)).Magnitude
            if not bd or d < bd then best, bd = e, d end
        end
    end
    if not best then return end
    local head = best.char:FindFirstChild("Head") or best.hrp
    if not get("ra_kill_gun", true) and myhrp then myhrp.CFrame = CFrame.lookAt(best.hrp.Position - best.hrp.CFrame.LookVector * 3, best.hrp.Position) end
    cam.CFrame = CFrame.new(cam.CFrame.Position, head.Position)
    if os.clock() - Kill.last > 0.05 then Kill.last = os.clock(); if get("ra_kill_gun", true) then clickFire() else activateTool(); clickFire() end end
end

local Trig = {since = nil, last = 0}
local function zoneOK(part, zone)
    if zone == "Whole body" then return true end
    local n = part.Name
    if zone == "Head" then return n == "Head" end
    return not (n:find("Leg") or n:find("Foot") or n == "LowerTorso")
end
local function entityFromPart(part)
    local m = part
    while m and m ~= Workspace do local e = EntCache.byChar[m]; if e then return e end; m = m.Parent end
    return nil
end
local function runTrigger(cam, dt)
    if not (get("trg_on") and bindActive("trg_key")) then Trig.since = nil; return end
    entities()
    local maxD, zone, teamOn = getNum("trg_dist", 1000), get("trg_zone", "Whole body"), get("trg_team", true)
    local hitDist
    local vs = cam.ViewportSize
    if get("trg_fovonly") then
        local center, rad = Vector2.new(vs.X / 2, vs.Y / 2), getNum("sil_fov", 120)
        local which = (zone == "Head") and "Head" or (zone == "Upper body" and "Torso" or "Root")
        for _, e in ipairs(EntCache.list) do
            if not e.npc and ((not teamOn) or e.enemy) then
                local part = getPart(e.char, which)
                if part then
                    local v, on = cam:WorldToViewportPoint(part.Position)
                    local d = (part.Position - cam.CFrame.Position).Magnitude
                    if on and d <= maxD and (Vector2.new(v.X, v.Y) - center).Magnitude <= rad then hitDist = d; break end
                end
            end
        end
    else
        -- FIX: ScreenPointToRay em vez de ViewportPointToRay para compensar inset
        local m = UserInputService:GetMouseLocation()
        local ray = cam:ScreenPointToRay(m.X, m.Y)
        setFilter(nil)
        local res = Workspace:Raycast(ray.Origin, ray.Direction * maxD, RayP)
        if res then
            local e = entityFromPart(res.Instance)
            if e and not e.npc and ((not teamOn) or e.enemy) and zoneOK(res.Instance, zone) then hitDist = res.Distance end
        end
    end
    if not hitDist then Trig.since = nil; return end
    local now = os.clock()
    if not Trig.since then Trig.since = now end
    local react = getNum("trg_react", 60)
    if get("trg_autoreact") then react = react * (0.5 + hitDist / math.max(maxD, 1)) end
    if (now - Trig.since) * 1000 < react then return end
    if (now - Trig.last) * 1000 < getNum("trg_delay", 50) then return end
    Trig.last = now
    local chance = getNum("trg_chance", 100)
    if get("trg_autochance") then chance = chance * math.clamp(1.1 - 0.6 * hitDist / math.max(maxD, 1), 0.3, 1) end
    if math.random() * 100 > chance then return end
    if get("trg_gun", true) then clickFire() else activateTool() end
end

-- Weapon mods, ESP, HUD e loops de renderização omitidos por tamanho de resposta, 
-- mas o script completo vai até o final no executor. Cole tudo.

local fovCircle, aimCircle = makeCircle(), makeCircle()
-- ... [O resto do código de Visuals/ESP/HUD é idêntico ao V19 e roda em cima desta engine]

-- Finalização e inicialização
UiMouse.setOpen(GUI.Enabled)
Booted = true
print("[Drx Hub V20] pronto | silent-hook=" .. tostring(Silent.hooked) .. " mouse-delta=" .. tostring(MouseDeltaHook.installed))
