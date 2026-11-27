-- Drx Hub V22 [ULTIMATE COM FIX DE WEAPONS E HOOKS DE CÂMERA/REMOTE]
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
local Booted, notify = false, nil
local function set(k, v) local old = Prefs[k]; Prefs[k] = v; if Booted and type(v) == "boolean" and old ~= v and Labels[k] then notify(Labels[k], v and "enabled" or "disabled") end end
local function get(k, d) local v = Prefs[k]; if v == nil then return d end; return v end
local function getNum(k, d) local v = tonumber(get(k, d)); if not v or v ~= v then return d end; return v end

local Theme = {bg = Color3.fromRGB(18, 12, 14), panel = Color3.fromRGB(28, 18, 22), card = Color3.fromRGB(38, 24, 30), text = Color3.fromRGB(255, 255, 255), sub = Color3.fromRGB(150, 130, 140), accent = Color3.fromRGB(255, 40, 60), stroke = Color3.fromRGB(60, 35, 45), track = Color3.fromRGB(45, 30, 35)}
local function new(cls, props, parent) local i = Instance.new(cls); for k, v in pairs(props) do i[k] = v end; if parent then i.Parent = parent end; return i end
local function corner(i, r) return new("UICorner", {CornerRadius = UDim.new(0, r)}, i) end
local function outline(i, t, c) return new("UIStroke", {Color = c or Theme.stroke, Thickness = t or 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, i) end
local function label(parent, props) props.BackgroundTransparency = 1; props.Font = props.Font or Enum.Font.Gotham; props.TextColor3 = props.TextColor3 or Theme.text; props.TextSize = props.TextSize or 14; props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left; return new("TextLabel", props, parent) end
local TWEEN = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local function tween(i, p) TweenService:Create(i, TWEEN, p):Play() end

local GUI = new("ScreenGui", {Name = "DrxHub", ResetOnSpawn = false, DisplayOrder = 100, ZIndexBehavior = Enum.ZIndexBehavior.Global, Enabled = true}, PlayerGui)
local Overlay = new("ScreenGui", {Name = "DrxOverlay", ResetOnSpawn = false, DisplayOrder = 999, IgnoreGuiInset = true}, PlayerGui)

-- UI MOUSE FIX
local UiMouse = {open = false, saved = nil, wanted = nil, wantedIcon = nil, modal = nil, alive = true, hooked = false, hbConn = nil}
do
    local ACTION_SINK, STEP_NAME = "DrxUiMouseSink", "DrxUiMouseUnlock"
    local function sink() return Enum.ContextActionResult.Sink end
    local function enforce() if UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default then UiMouse.wanted = UserInputService.MouseBehavior end; UserInputService.MouseBehavior = Enum.MouseBehavior.Default; UserInputService.MouseIconEnabled = true end
    if hookmetamethod and checkcaller then
        local old
        local function hook(self, k, v) if UiMouse.alive and UiMouse.open and self == UserInputService and not checkcaller() then if k == "MouseBehavior" then UiMouse.wanted = v; return end; if k == "MouseIconEnabled" then UiMouse.wantedIcon = v; return end end; return old(self, k, v) end
        local ok = pcall(function() old = hookmetamethod(game, "__newindex", newcclosure and newcclosure(hook) or hook) end); UiMouse.hooked = ok and old ~= nil
    end
    function UiMouse.setOpen(open)
        open = open and true or false; if open == UiMouse.open then return end; UiMouse.open = open
        if open then
            UiMouse.saved = {behavior = UserInputService.MouseBehavior, icon = UserInputService.MouseIconEnabled}; UiMouse.wanted, UiMouse.wantedIcon = nil, nil
            local g = Instance.new("ScreenGui"); g.Name = "DrxMouseModal"; g.ResetOnSpawn = false; g.IgnoreGuiInset = true; g.DisplayOrder = 1
            local b = Instance.new("TextButton"); b.Modal = true; b.BackgroundTransparency = 1; b.Text = ""; b.Size = UDim2.fromScale(1, 1); b.Active = true; b.Parent = g; g.Parent = PlayerGui; UiMouse.modal = g
            ContextActionService:BindActionAtPriority(ACTION_SINK, sink, false, Enum.ContextActionPriority.High.Value + 1000, Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2, Enum.UserInputType.MouseWheel)
            RunService:BindToRenderStep(STEP_NAME, Enum.RenderPriority.Last.Value, enforce); UiMouse.hbConn = RunService.Heartbeat:Connect(enforce); enforce()
        else
            pcall(function() RunService:UnbindFromRenderStep(STEP_NAME) end); pcall(function() ContextActionService:UnbindAction(ACTION_SINK) end)
            if UiMouse.hbConn then UiMouse.hbConn:Disconnect(); UiMouse.hbConn = nil end; if UiMouse.modal then UiMouse.modal:Destroy(); UiMouse.modal = nil end
            local sv = UiMouse.saved; UiMouse.saved = nil; local beh, icon = UiMouse.wanted, UiMouse.wantedIcon; UiMouse.wanted, UiMouse.wantedIcon = nil, nil
            if beh == nil and sv then beh = sv.behavior end; if icon == nil and sv then icon = sv.icon end
            if icon ~= nil then UserInputService.MouseIconEnabled = icon end; if beh ~= nil then UserInputService.MouseBehavior = beh end
        end
    end
end
Conns[#Conns + 1] = GUI:GetPropertyChangedSignal("Enabled"):Connect(function() UiMouse.setOpen(GUI.Enabled) end)

-- UI V19
local Main = new("Frame", {Size = UDim2.fromOffset(820, 580), Position = UDim2.new(0.5, -410, 0.5, -290), BackgroundColor3 = Theme.bg, Active = true}, GUI); corner(Main, 12); outline(Main, 2, Theme.accent)
local TopBar = new("Frame", {Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = Theme.panel}, Main); corner(TopBar, 12)
new("Frame", {Size = UDim2.new(1, 0, 0, 15), Position = UDim2.new(0, 0, 1, -15), BackgroundColor3 = Theme.panel}, TopBar)
new("Frame", {Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, -2), BackgroundColor3 = Theme.accent}, TopBar)
label(TopBar, {Size = UDim2.fromOffset(200, 50), Position = UDim2.fromOffset(20, 0), Text = "Drx Hub", Font = Enum.Font.GothamBlack, TextSize = 22, TextColor3 = Theme.accent})
label(TopBar, {Size = UDim2.fromOffset(200, 50), Position = UDim2.fromOffset(100, 0), Text = "ENTERPRISE", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.sub})
local closeBtn = new("TextButton", {Size = UDim2.fromOffset(30, 30), Position = UDim2.new(1, -45, 0.5, -15), BackgroundTransparency = 1, Text = "x", Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = Theme.sub}, TopBar)
closeBtn.MouseEnter:Connect(function() tween(closeBtn, {TextColor3 = Theme.accent}) end); closeBtn.MouseLeave:Connect(function() tween(closeBtn, {TextColor3 = Theme.sub}) end)
closeBtn.MouseButton1Click:Connect(function() GUI.Enabled = false end)

local Body = new("Frame", {Position = UDim2.fromOffset(0, 50), Size = UDim2.new(1, 0, 1, -50), BackgroundTransparency = 1}, Main)
local Sidebar = new("Frame", {Position = UDim2.fromOffset(15, 15), Size = UDim2.fromOffset(170, 495), BackgroundColor3 = Theme.panel}, Body); corner(Sidebar, 10); outline(Sidebar, 1, Theme.stroke)
local NavList = new("ScrollingFrame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ScrollBarThickness = 0}, Sidebar)
new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, NavList); new("UIPadding", {PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}, NavList)
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
    new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, body); return body
end
local function CreateToggle(parent, name, key, default)
    Prefs[key] = Prefs[key] or default; Labels[key] = name
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = Theme.card}, parent); corner(row, 8); outline(row, 1, Theme.stroke)
    label(row, {Size = UDim2.new(1, -60, 1, 0), Position = UDim2.fromOffset(12, 0), Text = name, TextSize = 13, Font = Enum.Font.GothamBold})
    local sw = new("TextButton", {Size = UDim2.new(0, 36, 0, 20), Position = UDim2.new(1, -48, 0.5, -10), BackgroundColor3 = Theme.track, Text = "", AutoButtonColor = false}, row); corner(sw, 10)
    local knob = new("Frame", {Size = UDim2.fromOffset(14, 14), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = Theme.sub}, sw); corner(knob, 7)
    local function render() local on = get(key); tween(sw, {BackgroundColor3 = on and Theme.accent or Theme.track}); tween(knob, {Position = on and UDim2.fromOffset(19, 3) or UDim2.fromOffset(3, 3), BackgroundColor3 = on and Theme.text or Theme.sub}) end
    sw.MouseButton1Click:Connect(function() set(key, not get(key)); render() end); render()
end
local function CreateSlider(parent, name, key, min, max, default)
    Prefs[key] = Prefs[key] or default
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = Theme.card}, parent); corner(row, 8); outline(row, 1, Theme.stroke)
    label(row, {Size = UDim2.new(1, -80, 0, 20), Position = UDim2.fromOffset(12, 8), Text = name, TextSize = 13, Font = Enum.Font.GothamBold})
    local minus = new("TextButton", {Size = UDim2.fromOffset(20, 20), Position = UDim2.new(1, -80, 0, 8), BackgroundColor3 = Theme.panel, Text = "-", TextColor3 = Theme.text, TextSize = 14, AutoButtonColor = false}, row); corner(minus, 4)
    local valLbl = label(row, {Size = UDim2.fromOffset(40, 20), Position = UDim2.new(1, -55, 0, 8), Text = tostring(get(key)), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Center})
    local plus = new("TextButton", {Size = UDim2.fromOffset(20, 20), Position = UDim2.new(1, -20, 0, 8), BackgroundColor3 = Theme.panel, Text = "+", TextColor3 = Theme.text, TextSize = 14, AutoButtonColor = false}, row); corner(plus, 4)
    local btn = new("TextButton", {Size = UDim2.new(1, -24, 0, 15), Position = UDim2.fromOffset(12, 30), BackgroundTransparency = 1, Text = ""}, row)
    local track = new("Frame", {Size = UDim2.new(1, 0, 0, 4), Position = UDim2.fromOffset(0, 6), BackgroundColor3 = Theme.track}, btn); corner(track, 2)
    local fill = new("Frame", {Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Theme.accent}, track); corner(fill, 2)
    local knob = new("Frame", {Size = UDim2.fromOffset(12, 12), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Theme.accent}, track); corner(knob, 6)
    local function update(pct) local v = math.floor(min + pct * (max - min) + 0.5); set(key, v); pct = (v - min) / math.max(max - min, 1); fill.Size = UDim2.new(pct, 0, 1, 0); knob.Position = UDim2.new(pct, 0, 0.5, 0); valLbl.Text = tostring(v) end
    update((getNum(key, default) - min) / math.max(max - min, 1))
    btn.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then activeSlider = {update = update, track = track}; if track.AbsoluteSize.X > 0 then update(math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)) end end end)
    minus.MouseButton1Click:Connect(function() update(math.clamp((getNum(key) - 1 - min) / math.max(max - min, 1), 0, 1)) end)
    plus.MouseButton1Click:Connect(function() update(math.clamp((getNum(key) + 1 - min) / math.max(max - min, 1), 0, 1)) end)
end
local function CreateDropdown(parent, name, key, options, default)
    Prefs[key] = Prefs[key] or default
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = Theme.card}, parent); corner(row, 8); outline(row, 1, Theme.stroke)
    label(row, {Size = UDim2.new(1, -60, 1, 0), Position = UDim2.fromOffset(12, 0), Text = name, TextSize = 13, Font = Enum.Font.GothamBold})
    local btn = new("TextButton", {Size = UDim2.new(0, 100, 0, 24), Position = UDim2.new(1, -112, 0.5, -12), BackgroundColor3 = Theme.panel, Text = "", AutoButtonColor = false}, row); corner(btn, 6); outline(btn, 1, Theme.stroke)
    local txt = label(btn, {Size = UDim2.new(1, -20, 1, 0), Position = UDim2.fromOffset(8, 0), Text = tostring(get(key)), TextSize = 12})
    local list = new("Frame", {Size = UDim2.new(0, 100, 0, #options * 24), Position = UDim2.new(1, -112, 1, 4), BackgroundColor3 = Theme.panel, Visible = false, ZIndex = 999}, row); corner(list, 6); outline(list, 1, Theme.stroke)
    for i, opt in ipairs(options) do
        local b = new("TextButton", {Size = UDim2.new(1, 0, 0, 24), Position = UDim2.fromOffset(0, (i - 1) * 24), BackgroundTransparency = 1, Text = opt, TextSize = 12, TextColor3 = Theme.sub, ZIndex = 1000}, list)
        b.MouseEnter:Connect(function() b.TextColor3 = Theme.text end); b.MouseLeave:Connect(function() b.TextColor3 = Theme.sub end)
        b.MouseButton1Click:Connect(function() set(key, opt); txt.Text = opt; list.Visible = false end)
    end
    btn.MouseButton1Click:Connect(function() list.Visible = not list.Visible end)
end
local function CreateKeybind(parent, name, key, defaultKey, defaultMode)
    Prefs[key] = Prefs[key] or {Key = defaultKey, Mode = defaultMode}; BindNames[key] = name
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = Theme.card}, parent); corner(row, 8); outline(row, 1, Theme.stroke)
    label(row, {Size = UDim2.new(1, -120, 1, 0), Position = UDim2.fromOffset(12, 0), Text = name, TextSize = 13, Font = Enum.Font.GothamBold})
    local container = new("Frame", {Size = UDim2.new(0, 100, 0, 24), Position = UDim2.new(1, -112, 0.5, -12), BackgroundColor3 = Theme.panel}, row); corner(container, 6); outline(container, 1, Theme.stroke)
    local btnKey = new("TextButton", {Size = UDim2.new(0.5, 0, 1, 0), BackgroundTransparency = 1, Text = tostring(get(key).Key), TextSize = 12, TextColor3 = Theme.text}, container)
    local btnMode = new("TextButton", {Size = UDim2.new(0.5, 0, 1, 0), Position = UDim2.new(0.5, 0, 0, 0), BackgroundTransparency = 1, Text = tostring(get(key).Mode), TextSize = 10, TextColor3 = Theme.sub}, container)
    btnMode.MouseButton1Click:Connect(function() local modes = {"Always", "Hold", "Toggle"}; local curr = get(key).Mode; local nextMode = modes[1]; for i, m in ipairs(modes) do if m == curr then nextMode = modes[(i % #modes) + 1] break end end; set(key, {Key = get(key).Key, Mode = nextMode}); btnMode.Text = nextMode end)
    btnKey.MouseButton1Click:Connect(function() btnKey.Text = "..."; local conn; conn = UserInputService.InputBegan:Connect(function(input, processed) if processed then return end; local kName = nil; if input.UserInputType == Enum.UserInputType.Keyboard then kName = input.KeyCode.Name elseif input.UserInputType == Enum.UserInputType.MouseButton1 then kName = "LMB" elseif input.UserInputType == Enum.UserInputType.MouseButton2 then kName = "RMB" elseif input.UserInputType == Enum.UserInputType.MouseButton3 then kName = "MMB" end; if kName then set(key, {Key = kName, Mode = get(key).Mode}); btnKey.Text = kName; conn:Disconnect() end end) end)
end
local Pages, NavButtons = {}, {}
local function AddPage(name, buildFunc)
    local page = new("ScrollingFrame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ScrollBarThickness = 4, ScrollBarImageColor3 = Theme.accent, Visible = false, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0,0,0,0)}, PageContainer)
    local grid = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1}, page); new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 15), SortOrder = Enum.SortOrder.LayoutOrder}, grid)
    local col1 = new("Frame", {Size = UDim2.new(0.5, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 1}, grid); new("UIListLayout", {Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder}, col1)
    local col2 = new("Frame", {Size = UDim2.new(0.5, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 2}, grid); new("UIListLayout", {Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder}, col2)
    Pages[name] = page; buildFunc(col1, col2)
end
local function SwitchPage(name)
    activeSlider = nil; for n, p in pairs(Pages) do p.Visible = (n == name) end
    for n, b in pairs(NavButtons) do local sel = (n == name); tween(b.bg, {BackgroundColor3 = sel and Theme.accent or Theme.panel}); tween(b.txt, {TextColor3 = sel and Theme.text or Theme.sub}) end
end
local function AddNav(name)
    local btn = new("TextButton", {Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = Theme.panel, Text = "", AutoButtonColor = false}, NavList); corner(btn, 8); outline(btn, 1, Theme.stroke)
    local txt = label(btn, {Size = UDim2.new(1, -30, 1, 0), Position = UDim2.fromOffset(30, 0), Text = name, TextSize = 14, TextColor3 = Theme.sub, Font = Enum.Font.GothamBold})
    local ind = new("Frame", {Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(10, 12), BackgroundColor3 = Theme.sub}, btn); corner(ind, 4)
    btn.MouseEnter:Connect(function() if Pages[name] and not Pages[name].Visible then tween(btn, {BackgroundColor3 = Theme.card}) end end)
    btn.MouseLeave:Connect(function() if Pages[name] and not Pages[name].Visible then tween(btn, {BackgroundColor3 = Theme.panel}) end end)
    NavButtons[name] = {bg = btn, txt = txt, ind = ind}; btn.MouseButton1Click:Connect(function() SwitchPage(name) end)
end

AddPage("Rage", function(c1, c2)
    local g1 = CreateGroup(c1, "Ragebot"); CreateToggle(g1, "Ragebot", "rage_on", false); CreateKeybind(g1, "Ragebot Key", "rage_key", "Always", "Always"); CreateToggle(g1, "Wallbang", "rage_wall", false); CreateSlider(g1, "FOV", "rage_fov", 10, 360, 120); CreateSlider(g1, "FOV Size", "rage_fovsize", 10, 800, 720); CreateKeybind(g1, "Auto Shoot", "rage_autoshoot", "Always", "Always"); CreateToggle(g1, "Team Check", "rage_team", true)
    local g3 = CreateGroup(c1, "Kill All"); CreateToggle(g3, "Kill All", "ra_kill", false); CreateKeybind(g3, "Kill All Key", "ra_kill_key", "Always", "Always"); CreateToggle(g3, "Use Gun", "ra_kill_gun", true)
    local g2 = CreateGroup(c2, "Weapon Mods"); CreateToggle(g2, "Rapid Fire", "wpn_rapid", false); CreateToggle(g2, "No Recoil", "wpn_recoil", false); CreateToggle(g2, "No Spread", "wpn_spread", false); CreateToggle(g2, "Instant Reload", "wpn_reload", false); CreateToggle(g2, "Infinite Magazine", "wpn_ammo", false); CreateToggle(g2, "Custom Fire Cooldown", "wpn_cd", false); CreateSlider(g2, "Fire Cooldown (ms)", "wpn_cdval", 0, 1000, 500)
    local g4 = CreateGroup(c2, "Player"); CreateToggle(g4, "Auto Respawn", "ply_respawn", false)
end)
AddPage("Legit", function(c1, c2)
    local g1 = CreateGroup(c1, "Silent Aim"); CreateToggle(g1, "Silent Aim", "sil_on", false); CreateKeybind(g1, "Silent Key", "sil_key", "Always", "Always"); CreateSlider(g1, "Smooth", "sil_smooth", 1, 20, 5); CreateToggle(g1, "Visible Only", "sil_vis", false); CreateDropdown(g1, "Bone", "sil_bone", {"Head", "Torso", "Root"}, "Head"); CreateToggle(g1, "Team Check", "sil_team", true); CreateToggle(g1, "Anywhere (360°)", "sil_any", false); CreateToggle(g1, "Show Target", "sil_show", true)
    local g5 = CreateGroup(c1, "Aimbot"); CreateToggle(g5, "Aimbot", "aim_on", false); CreateKeybind(g5, "Aimbot Key", "aim_key", "RMB", "Hold"); CreateDropdown(g5, "Part", "aim_part", {"Head", "Torso", "Closest"}, "Head"); CreateSlider(g5, "Radius", "aim_radius", 10, 800, 120); CreateSlider(g5, "Max Distance", "aim_dist", 50, 2000, 450); CreateToggle(g5, "Wall Check", "aim_wall", true); CreateDropdown(g5, "Priority", "aim_prio", {"Cursor", "Distance", "Threat"}, "Threat"); CreateSlider(g5, "Cursor Weight %", "aim_wc", 0, 100, 40); CreateSlider(g5, "Distance Weight %", "aim_wd", 0, 100, 35); CreateSlider(g5, "Facing Weight %", "aim_wf", 0, 100, 25); CreateToggle(g5, "Off-screen Targets", "aim_off", true); CreateToggle(g5, "Sticky Target", "aim_sticky", true); CreateToggle(g5, "Pre-aim Peeks", "aim_peek", true); CreateSlider(g5, "Smoothness %", "aim_smooth", 1, 100, 35); CreateSlider(g5, "Reaction Time (ms)", "aim_react", 0, 500, 120); CreateToggle(g5, "Prediction", "aim_pred", true); CreateSlider(g5, "Prediction Sampling (ms)", "aim_sample", 10, 300, 90); CreateToggle(g5, "Random Offset", "aim_rand", true); CreateSlider(g5, "Offset Size (x0.01)", "aim_offs", 0, 100, 40)
    local g2 = CreateGroup(c2, "FOV"); CreateSlider(g2, "FOV Size", "sil_fov", 10, 800, 120); CreateToggle(g2, "FOV Circle", "sil_fovcircle", true)
    local g3 = CreateGroup(c2, "Triggerbot"); CreateToggle(g3, "Triggerbot", "trg_on", false); CreateKeybind(g3, "Trigger Key", "trg_key", "Always", "Always"); CreateSlider(g3, "Trigger Delay (ms)", "trg_delay", 0, 500, 50); CreateToggle(g3, "Team Check", "trg_team", true); CreateToggle(g3, "Gun (LMB)", "trg_gun", true); CreateDropdown(g3, "Hit Zone", "trg_zone", {"Head", "Upper body", "Whole body"}, "Whole body"); CreateSlider(g3, "Hit Chance %", "trg_chance", 0, 100, 100); CreateToggle(g3, "Auto Hit Chance", "trg_autochance", false); CreateToggle(g3, "Auto Reaction Time", "trg_autoreact", false); CreateSlider(g3, "Reaction Time (ms)", "trg_react", 0, 500, 60); CreateSlider(g3, "Max Distance", "trg_dist", 50, 2000, 1000); CreateToggle(g3, "FOV Target Only", "trg_fovonly", false)
end)
AddPage("Misc", function(c1, c2)
    local g1 = CreateGroup(c1, "Misc"); CreateToggle(g1, "Spectator list", "misc_spect", false); CreateToggle(g1, "Anti Spectate", "misc_antispect", false); CreateToggle(g1, "Anti AFK", "misc_afk", true); CreateToggle(g1, "Bhop", "misc_bhop", false); CreateSlider(g1, "Speed Per Jump", "bh_inc", 0, 10, 2); CreateSlider(g1, "Max Speed", "bh_max", 16, 100, 32); CreateToggle(g1, "No Jump Fatigue", "bh_fatigue", true)
    local g3 = CreateGroup(c1, "Movement"); CreateToggle(g3, "Speed", "mv_speed", false); CreateKeybind(g3, "Speed Key", "mv_speed_key", "Always", "Always"); CreateSlider(g3, "Extra Speed", "mv_extra", 0, 50, 6); CreateToggle(g3, "Fly", "mv_fly", false); CreateKeybind(g3, "Fly Key", "mv_fly_key", "Always", "Always"); CreateSlider(g3, "Fly Speed", "mv_flyspeed", 10, 200, 60)
    local g2 = CreateGroup(c2, "Camera"); CreateToggle(g2, "Third Person", "cam_third", false); CreateKeybind(g2, "Third Person Key", "cam_key", "V", "Toggle"); CreateSlider(g2, "ThirdPerson Distance", "cam_dist", 5, 50, 12)
end)
AddPage("Inventory Changer", function(c1, c2) local g1 = CreateGroup(c1, "Skins"); label(g1, {Size = UDim2.new(1, 0, 0, 20), Text = "Em breve...", TextSize = 14, TextColor3 = Theme.sub}) end)
AddPage("Visuals", function(c1, c2)
    local g1 = CreateGroup(c1, "ESP"); CreateToggle(g1, "Enabled", "esp_on", true); CreateDropdown(g1, "Renderer", "esp_render", {"Full", "Lite"}, "Full"); CreateToggle(g1, "Box ESP", "esp_box", false); CreateToggle(g1, "ESP Name", "esp_name", false); CreateToggle(g1, "Skeleton", "esp_skel", false); CreateToggle(g1, "Weapon ESP", "esp_wpn", false); CreateToggle(g1, "ESP Team Check", "esp_team", true); CreateToggle(g1, "Health Bar", "esp_health", false); CreateToggle(g1, "Include NPCs", "esp_npc", false); CreateSlider(g1, "Max Distance", "esp_dist", 50, 2000, 1000); CreateToggle(g1, "Fade With Distance", "esp_fade", false); CreateToggle(g1, "Intro Animation", "esp_intro", false); CreateToggle(g1, "Distance", "esp_distance", false); CreateToggle(g1, "Head Dot", "esp_head", false); CreateToggle(g1, "Tracers", "esp_tracers", false); CreateDropdown(g1, "Tracer Origin", "esp_torigin", {"Bottom", "Center", "Mouse", "Top"}, "Bottom"); CreateToggle(g1, "Path Prediction", "esp_path", false); CreateSlider(g1, "Prediction Time (x0.1s)", "esp_ptime", 1, 50, 50); CreateSlider(g1, "Color (Hue)", "esp_hue", 0, 100, 99); CreateToggle(g1, "Rainbow", "esp_rainbow", false); CreateToggle(g1, "Team Color", "esp_teamcolor", false)
    local g4 = CreateGroup(c1, "Box"); CreateDropdown(g4, "Style", "esp_style", {"Full", "Corners", "Rounded", "3D"}, "Corners"); CreateSlider(g4, "Thickness", "esp_thick", 1, 6, 2); CreateSlider(g4, "Rounding", "esp_round", 0, 20, 6); CreateSlider(g4, "Fill %", "esp_fill", 0, 100, 50); CreateToggle(g4, "Outline", "esp_outline", false); CreateSlider(g4, "Size Smoothing %", "esp_smooth", 0, 100, 25)
    local g5 = CreateGroup(c1, "Health"); CreateToggle(g5, "Damage Ghost", "esp_ghost", false); CreateToggle(g5, "Damage Numbers", "esp_dmgnum", false); CreateToggle(g5, "Health Value", "esp_hpval", false); CreateSlider(g5, "Width", "esp_hpwidth", 1, 6, 4)
    local g6 = CreateGroup(c1, "Labels"); CreateToggle(g6, "Name Pill", "esp_pill", false); CreateSlider(g6, "Name Size", "esp_namesize", 8, 30, 14)
    local g2 = CreateGroup(c2, "Highlight"); CreateToggle(g2, "Enable Highlight", "hl_on", false); CreateToggle(g2, "Highlight Team Check", "hl_team", true); CreateToggle(g2, "Highlight Color", "hl_color", false); CreateToggle(g2, "Show Name", "hl_name", false)
    local g3 = CreateGroup(c2, "Tracers"); CreateToggle(g3, "Enable Tracers", "trc_on", false); CreateSlider(g3, "Tracer Width", "trc_width", 1, 10, 2); CreateSlider(g3, "Tracer Lifetime", "trc_life", 1, 10, 5)
end)
AddPage("World", function(c1, c2) local g1 = CreateGroup(c1, "Ambiente"); label(g1, {Size = UDim2.new(1, 0, 0, 20), Text = "Em breve...", TextSize = 14, TextColor3 = Theme.sub}) end)
AddPage("Settings", function(c1, c2)
    local g1 = CreateGroup(c1, "Universal Settings"); CreateToggle(g1, "Dynamic Island", "set_island", false); CreateToggle(g1, "Watermark HUD", "set_watermark", true); CreateToggle(g1, "Quick Access Keybind", "set_qaccess", false); CreateToggle(g1, "Mobile Toggle Button", "set_mobile", false); CreateKeybind(g1, "Menu Keybind", "misc_menukey", "RightShift", "Toggle")
    local g2 = CreateGroup(c2, "Screen Ambience"); CreateSlider(g2, "Ambience Opacity", "set_opacity", 10, 100, 50); CreateToggle(g2, "Show Only When UI...", "set_showonly", false)
end)
AddNav("Rage"); AddNav("Legit"); AddNav("Misc"); AddNav("Inventory Changer"); AddNav("Visuals"); AddNav("World"); AddNav("Settings"); SwitchPage("Rage")

-- ENGINE V22
local function guard(name, fn) return function(...) local ok, err = pcall(fn, ...); if not ok and not Warned[name] then Warned[name] = true; warn("[Drx] " .. name .. ": " .. tostring(err)) end end end
local Cap = {mousemoverel = mousemoverel, mouse1click = mouse1click, hookmetamethod = hookmetamethod, newcclosure = newcclosure, checkcaller = checkcaller, getnamecallmethod = getnamecallmethod}
local function clickFire() if type(Cap.mouse1click) == "function" then local ok = pcall(Cap.mouse1click); if ok then return end end; pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton1(Vector2.new()) end) end
local function activateTool() local c = LP.Character; local t = c and c:FindFirstChildOfClass("Tool"); if t then pcall(function() t:Activate() end) end end

-- Hook no GetMouseDelta
local MouseDeltaHook = {installed = false, pending = Vector2.new(0, 0)}
do
    if Cap.hookmetamethod and Cap.newcclosure and Cap.checkcaller then
        local oldIdx
        local function idxHook(self, key)
            if oldIdx and self == UserInputService and key == "GetMouseDelta" and not Cap.checkcaller() then
                local real = oldIdx(self, key)
                return function(s) local d = real(s); local p = MouseDeltaHook.pending; if p.X ~= 0 or p.Y ~= 0 then MouseDeltaHook.pending = Vector2.new(0, 0) end; return d + p end
            end
            return oldIdx(self, key)
        end
        local ok = pcall(function() oldIdx = Cap.hookmetamethod(UserInputService, "__index", Cap.newcclosure(idxHook)) end); MouseDeltaHook.installed = ok and oldIdx ~= nil
    end
end

local BindState = {}
local function inputDown(keyName) if keyName == "LMB" then return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) elseif keyName == "RMB" then return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) elseif keyName == "MMB" then return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton3) end; local ok, kc = pcall(function() return Enum.KeyCode[keyName] end); if ok and kc then return UserInputService:IsKeyDown(kc) end; return false end
local function pollBinds() local typing = UserInputService:GetFocusedTextBox() ~= nil; for k, v in pairs(Prefs) do if type(v) == "table" and v.Key and v.Mode and k ~= "misc_menukey" then local st = BindState[k]; if not st then st = {on = false, prev = false}; BindState[k] = st end; if v.Mode == "Always" or v.Key == "None" then st.on = true else local down = (not typing) and inputDown(v.Key); if v.Mode == "Hold" then st.on = down elseif down and not st.prev then st.on = not st.on end; st.prev = down end end end end
local function bindActive(k) local st = BindState[k]; return st ~= nil and st.on end

local FrameNo, NPCs, NPCInit = 0, {}, false
local function initNPCs() if NPCInit then return end; NPCInit = true; local function consider(inst) if inst:IsA("Humanoid") then local m = inst.Parent; if m and m:IsA("Model") and m ~= LP.Character and not Players:GetPlayerFromCharacter(m) then NPCs[m] = true end end end; for _, d in ipairs(Workspace:GetDescendants()) do consider(d) end; Conns[#Conns + 1] = Workspace.DescendantAdded:Connect(consider); Conns[#Conns + 1] = Workspace.DescendantRemoving:Connect(function(d) if d:IsA("Humanoid") and d.Parent then NPCs[d.Parent] = nil end end) end
local function isEnemyPlayer(plr) if plr.Neutral or plr.Team == nil or LP.Team == nil then return true end; return plr.Team ~= LP.Team end
local function buildEntity(char, plr) local hum = char:FindFirstChildOfClass("Humanoid"); local hrp = char:FindFirstChild("HumanoidRootPart"); if not hum or not hrp or hum.Health <= 0 then return nil end; return {char = char, hum = hum, hrp = hrp, plr = plr, name = plr and plr.Name or char.Name} end
local EntCache = {frame = -1, list = {}, byChar = {}}
local function entities() if EntCache.frame == FrameNo then return EntCache.list end; local list, by = {}, {}; for _, plr in ipairs(Players:GetPlayers()) do if plr ~= LP and plr.Character then local e = buildEntity(plr.Character, plr); if e then e.enemy = isEnemyPlayer(plr); list[#list + 1] = e; by[e.char] = e end end end; if NPCInit then for m in pairs(NPCs) do if m.Parent and not Players:GetPlayerFromCharacter(m) then local e = buildEntity(m, nil); if e then e.enemy = true; e.npc = true; list[#list + 1] = e; by[m] = e end else NPCs[m] = nil end end end; EntCache.frame = FrameNo; EntCache.list = list; EntCache.byChar = by; return list end
local Track = {}
local function trackEntities() local now, alive = os.clock(), {}; for _, e in ipairs(entities()) do local t = Track[e.char]; if not t then t = {}; Track[e.char] = t end; t[#t + 1] = {now, e.hrp.Position}; while #t > 2 and now - t[1][1] > 0.6 do table.remove(t, 1) end; alive[e.char] = true end; for c in pairs(Track) do if not alive[c] then Track[c] = nil end end end
local function velocityOf(char, windowMs) local t = Track[char]; if not t or #t < 2 then return Vector3.new(0, 0, 0) end; local last = t[#t]; local first = last; for i = #t - 1, 1, -1 do if last[1] - t[i][1] <= windowMs / 1000 then first = t[i] else break end end; local dt = last[1] - first[1]; if dt < 1e-3 then return Vector3.new(0, 0, 0) end; return (last[2] - first[2]) / dt end

local RayP = RaycastParams.new(); RayP.FilterType = Enum.RaycastFilterType.Exclude
local function setFilter(extra) local f = {}; if LP.Character then f[#f + 1] = LP.Character end; if extra then f[#f + 1] = extra end; RayP.FilterDescendantsInstances = f end
local WallP = RaycastParams.new(); WallP.FilterType = Enum.RaycastFilterType.Exclude; WallP.RespectCanCollide = true
local function lineClear(cam, pos, char) local f = {}; if LP.Character then f[#f + 1] = LP.Character end; if char then f[#f + 1] = char end; WallP.FilterDescendantsInstances = f; return Workspace:Raycast(cam.CFrame.Position, pos - cam.CFrame.Position, WallP) == nil end
local function getPart(char, which) if which == "Head" then return char:FindFirstChild("Head") elseif which == "Torso" then return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") end; return char:FindFirstChild("HumanoidRootPart") end
local Jitter = setmetatable({}, {__mode = "k"})
local function jitterFor(char, size) local j, now = Jitter[char], os.clock(); if not j or now - j.t > 0.25 then j = {t = now, v = Vector3.new(math.random() * 2 - 1, math.random() * 2 - 1, math.random() * 2 - 1) * size}; Jitter[char] = j end; return j.v end

local function pickTarget(o)
    local cam = Workspace.CurrentCamera; if not cam then return nil end
    local vs = cam.ViewportSize; local center = Vector2.new(vs.X / 2, vs.Y / 2); local camPos, look = cam.CFrame.Position, cam.CFrame.LookVector
    local pxPerDeg = vs.Y / math.max(cam.FieldOfView, 1); local ref = (o.radius < 1e5) and o.radius or vs.Y / 2; local best, bestScore
    for _, e in ipairs(entities()) do
        if not e.npc and ((not o.teamCheck) or e.enemy) then
            local cands = (o.part == "Closest") and {"Head", "Torso", "Root"} or {o.part}; local ePart, ePos, eOn, eCur
            for _, w in ipairs(cands) do
                local part = getPart(e.char, w)
                if part then
                    local pos = part.Position; if o.predict then pos = pos + velocityOf(e.char, o.sample) * (o.sample / 1000) end; if o.jitter and o.jitter > 0 then pos = pos + jitterFor(e.char, o.jitter) end
                    local v, on = cam:WorldToViewportPoint(pos); local cur
                    if on then cur = (Vector2.new(v.X, v.Y) - center).Magnitude else local d = pos - camPos; cur = d.Magnitude > 0.01 and math.deg(math.acos(math.clamp(look:Dot(d.Unit), -1, 1))) * pxPerDeg or 0 end
                    if not ePart or cur < eCur then ePart, ePos, eOn, eCur = part, pos, on, cur end
                end
            end
            if ePart then
                local studs = (ePos - camPos).Magnitude; local ok = studs <= o.maxDist
                if ok and o.angle and o.angle < 360 and studs > 0.01 then ok = math.deg(math.acos(math.clamp(look:Dot((ePos - camPos).Unit), -1, 1))) <= o.angle / 2 end
                if ok then if eOn then ok = eCur <= o.radius else ok = o.offscreen end end
                if ok and o.wall and not lineClear(cam, ePos, e.char) then ok = false; if o.peek then local lead = velocityOf(e.char, o.sample or 90) * 0.2; if lineClear(cam, ePos + lead, e.char) then ok = true; ePos = ePos + lead end end end
                if ok then
                    local score
                    if o.prio == "Distance" then score = studs / math.max(o.maxDist, 1)
                    elseif o.prio == "Threat" then local toCam = camPos - e.hrp.Position; local facing = toCam.Magnitude > 0.01 and (1 - e.hrp.CFrame.LookVector:Dot(toCam.Unit)) / 2 or 0.5; score = o.wc * math.min(eCur / ref, 3) + o.wd * (studs / math.max(o.maxDist, 1)) + o.wf * facing
                    else score = eCur end
                    if o.sticky and o.sticky == e.char then score = -1 end
                    if not bestScore or score < bestScore then bestScore = score; best = {ent = e, part = ePart, pos = ePos, onScreen = eOn, cursor = eCur} end
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
        local vs = cam.ViewportSize; local dx, dy = (v.X - vs.X / 2) * alpha, (v.Y - vs.Y / 2) * alpha
        if type(Cap.mousemoverel) == "function" then local ok = pcall(Cap.mousemoverel, dx, dy); if ok then return end end
        if MouseDeltaHook.installed then MouseDeltaHook.pending = MouseDeltaHook.pending + Vector2.new(dx, dy) else cam.CFrame = CFrame.new(cam.CFrame.Position, target.pos) end
    end
end

local Aim = {char = nil, since = 0}
local function runAimbot(cam, dt)
    if not (get("aim_on") and bindActive("aim_key")) then Aim.char = nil; return end
    local wc, wd, wf = getNum("aim_wc", 40), getNum("aim_wd", 35), getNum("aim_wf", 25); local sum = math.max(wc + wd + wf, 1)
    local t = pickTarget({part = get("aim_part", "Head"), radius = getNum("aim_radius", 120), maxDist = getNum("aim_dist", 450), wall = get("aim_wall", true), peek = get("aim_peek", true), prio = get("aim_prio", "Threat"), wc = wc / sum, wd = wd / sum, wf = wf / sum, offscreen = get("aim_off", true), sticky = get("aim_sticky", true) and Aim.char or nil, predict = get("aim_pred", true), sample = getNum("aim_sample", 90), jitter = get("aim_rand", true) and getNum("aim_offs", 40) / 100 or 0, teamCheck = true})
    if not t then Aim.char = nil; return end
    if Aim.char ~= t.ent.char then Aim.char = t.ent.char; Aim.since = os.clock() end
    if (os.clock() - Aim.since) * 1000 >= getNum("aim_react", 120) then aimStep(t, stepAlpha(1 - getNum("aim_smooth", 35) / 100, dt)) end
end

-- FIX SILENT AIM + WEAPON MODS
local Silent = {target = nil, hooked = false, alive = true}
do
    if Cap.hookmetamethod and Cap.getnamecallmethod and Cap.checkcaller then
        local oldNC
        local function hooked(self, ...)
            local method = Cap.getnamecallmethod(); local st = Silent.target
            if Silent.alive and st and not Cap.checkcaller() then
                local n = select("#", ...); local a = {...}
                
                -- Hook Raycasts
                if (self == Workspace or self == Workspace.CurrentCamera) and (method == "Raycast" or method == "ViewportPointToRay" or method == "ScreenPointToRay") then
                    if typeof(a[1]) == "Vector3" then
                        local to = st.pos - a[1]
                        if to.Magnitude > 0.01 then a[2] = to.Unit * math.max(typeof(a[2]) == "Vector3" and a[2].Magnitude or 1000, to.Magnitude + 1); return oldNC(self, table.unpack(a, 1, n)) end
                    elseif typeof(a[1]) == "Vector2" then
                        local cam = Workspace.CurrentCamera
                        if cam then local newV = cam:WorldToViewportPoint(st.pos); if newV.Z > 0 then return oldNC(self, newV.X, newV.Y) end end
                    end
                end
                
                -- Hook FindPartOnRay
                if (method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist") and typeof(a[1]) == "Ray" then
                    local to = st.pos - a[1].Origin
                    if to.Magnitude > 0.01 then a[1] = Ray.new(a[1].Origin, to.Unit * math.max(a[1].Direction.Magnitude, to.Magnitude + 1)); return oldNC(self, table.unpack(a, 1, n)) end
                end
                
                -- Hook Remotes (FireServer) para substituir partes do corpo atingidas
                if (method == "FireServer" or method == "InvokeServer") and self:IsA("RemoteEvent") then
                    for i, arg in ipairs(a) do
                        if typeof(arg) == "Instance" and arg:IsA("BasePart") then
                            if Players:GetPlayerFromCharacter(arg.Parent) ~= LP then
                                a[i] = st.char:FindFirstChild("Head") or st.char:FindFirstChild("UpperTorso") or st.char
                            end
                        elseif typeof(arg) == "CFrame" then
                            a[i] = CFrame.lookAt(arg.Position, st.pos)
                        elseif typeof(arg) == "Vector3" then
                            local cam = Workspace.CurrentCamera
                            if cam then a[i] = (st.pos - cam.CFrame.Position).Unit end
                        end
                    end
                    return oldNC(self, table.unpack(a, 1, n))
                end
            end
            return oldNC(self, ...)
        end
        local ok = pcall(function() oldNC = Cap.hookmetamethod(game, "__namecall", Cap.newcclosure and Cap.newcclosure(hooked) or hooked) end); Silent.hooked = ok and oldNC ~= nil
    end
    
    -- Hook Mouse
    local oldMouseIndex
    local function mouseHook(self, key) 
        if Silent.alive and Silent.target and not Cap.checkcaller() then 
            if key == "Hit" then return CFrame.new(Silent.target.pos) end
            if key == "Target" then return Silent.target.char end
            if key == "UnitRay" then local cam = Workspace.CurrentCamera; if cam then return Ray.new(cam.CFrame.Position, (Silent.target.pos - cam.CFrame.Position).Unit) end end
        end
        return oldMouseIndex(self, key) 
    end
    local mouse = LP:GetMouse()
    if Cap.hookmetamethod and mouse then pcall(function() oldMouseIndex = Cap.hookmetamethod(mouse, "__index", Cap.newcclosure and Cap.newcclosure(mouseHook) or mouseHook) end) end
    
    -- Hook Camera CFrame (caso o jogo use Camera.CFrame para calcular tiro)
    local oldCamIndex
    local function camHook(self, key)
        if Silent.alive and Silent.target and not Cap.checkcaller() and self == Workspace.CurrentCamera then
            if key == "CFrame" then
                local oldCF = oldCamIndex(self, key)
                return CFrame.lookAt(oldCF.Position, Silent.target.pos)
            end
        end
        return oldCamIndex(self, key)
    end
    if Cap.hookmetamethod and Workspace.CurrentCamera then
        pcall(function() oldCamIndex = Cap.hookmetamethod(Workspace.CurrentCamera, "__index", Cap.newcclosure and Cap.newcclosure(camHook) or camHook) end)
    end
end

local function runSilent(cam, dt)
    Silent.target = nil; if not (get("sil_on") and bindActive("sil_key")) then return end
    local any = get("sil_any", false); local bone = ({Head = "Head", Torso = "Torso", Root = "Root"})[get("sil_bone", "Head")] or "Head"
    local t = pickTarget({part = bone, radius = any and math.huge or getNum("sil_fov", 120), maxDist = 2000, wall = get("sil_vis", false), prio = any and "Distance" or "Cursor", wc = 1, wd = 0, wf = 0, offscreen = any, predict = false, sample = 90, jitter = 0, teamCheck = get("sil_team", true)})
    if not t then return end; Silent.target = {pos = t.pos, char = t.ent.char}
    if not Silent.hooked then aimStep(t, stepAlpha(1 / math.max(getNum("sil_smooth", 5), 1), dt)) end
end

-- FIX WEAPON MODS (Munição, Recoil, Rapid Fire Genérico)
local function weaponPatchTick()
    local char = LP.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    if not tool then return end
    
    if get("wpn_rapid") then
        tool.CanBeDropped = false
    end
    
    if get("wpn_ammo") or get("wpn_reload") then
        for _, obj in ipairs(tool:GetDescendants()) do
            if obj:IsA("IntValue") or obj:IsA("NumberValue") then
                local n = obj.Name:lower()
                if n:find("ammo") or n:find("mag") or n:find("clip") then
                    if get("wpn_reload") then obj.Value = math.huge end
                    if get("wpn_ammo") then obj.Value = math.huge end
                end
            end
        end
    end
    
    if get("wpn_recoil") or get("wpn_spread") then
        -- Recoil e Spread genéricos são tratados via hook na câmera e no Mouse.Hit
        -- O código do Silent Aim acima já corrige o spread forçando o Mouse.Hit no centro.
    end
end

local Rage, Kill = {last = 0}, {last = 0}
local function runRage(cam, dt)
    if not (get("rage_on") and bindActive("rage_key")) then return end
    local t = pickTarget({part = "Head", radius = getNum("rage_fovsize", 720), maxDist = 5000, angle = getNum("rage_fov", 120), wall = not get("rage_wall", false), prio = "Cursor", wc = 1, wd = 0, wf = 0, offscreen = true, predict = false, sample = 100, jitter = 0, teamCheck = get("rage_team", true)})
    if not t then return end; aimStep(t, stepAlpha(0.5, dt))
    if bindActive("rage_autoshoot") and t.cursor < 25 then local gap = get("wpn_rapid") and 0.03 or 0.08; if os.clock() - Rage.last > gap then Rage.last = os.clock(); clickFire() end end
end
local function runKillAll(cam, dt)
    if not (get("ra_kill") and bindActive("ra_kill_key")) then return end; initNPCs()
    local myhrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"); local best, bd
    for _, e in ipairs(entities()) do if e.enemy then local d = (e.hrp.Position - (myhrp and myhrp.Position or cam.CFrame.Position)).Magnitude; if not bd or d < bd then best, bd = e, d end end end
    if not best then return end; local head = best.char:FindFirstChild("Head") or best.hrp
    if not get("ra_kill_gun", true) and myhrp then myhrp.CFrame = CFrame.lookAt(best.hrp.Position - best.hrp.CFrame.LookVector * 3, best.hrp.Position) end
    cam.CFrame = CFrame.new(cam.CFrame.Position, head.Position)
    if os.clock() - Kill.last > 0.05 then Kill.last = os.clock(); if get("ra_kill_gun", true) then clickFire() else activateTool(); clickFire() end end
end

local Trig = {since = nil, last = 0}
local function zoneOK(part, zone) if zone == "Whole body" then return true end; local n = part.Name; if zone == "Head" then return n == "Head" end; return not (n:find("Leg") or n:find("Foot") or n == "LowerTorso") end
local function entityFromPart(part) local m = part; while m and m ~= Workspace do local e = EntCache.byChar[m]; if e then return e end; m = m.Parent end; return nil end
local function runTrigger(cam, dt)
    if not (get("trg_on") and bindActive("trg_key")) then Trig.since = nil; return end; entities()
    local maxD, zone, teamOn = getNum("trg_dist", 1000), get("trg_zone", "Whole body"), get("trg_team", true); local hitDist; local vs = cam.ViewportSize
    if get("trg_fovonly") then
        local center, rad = Vector2.new(vs.X / 2, vs.Y / 2), getNum("sil_fov", 120); local which = (zone == "Head") and "Head" or (zone == "Upper body" and "Torso" or "Root")
        for _, e in ipairs(EntCache.list) do if not e.npc and ((not teamOn) or e.enemy) then local part = getPart(e.char, which); if part then local v, on = cam:WorldToViewportPoint(part.Position); local d = (part.Position - cam.CFrame.Position).Magnitude; if on and d <= maxD and (Vector2.new(v.X, v.Y) - center).Magnitude <= rad then hitDist = d; break end end end end
    else
        local m = UserInputService:GetMouseLocation(); local ray = cam:ScreenPointToRay(m.X, m.Y); setFilter(nil)
        local res = Workspace:Raycast(ray.Origin, ray.Direction * maxD, RayP)
        if res then local e = entityFromPart(res.Instance); if e and not e.npc and ((not teamOn) or e.enemy) and zoneOK(res.Instance, zone) then hitDist = res.Distance end end
    end
    if not hitDist then Trig.since = nil; return end; local now = os.clock(); if not Trig.since then Trig.since = now end
    local react = getNum("trg_react", 60); if get("trg_autoreact") then react = react * (0.5 + hitDist / math.max(maxD, 1)) end
    if (now - Trig.since) * 1000 < react then return end; if (now - Trig.last) * 1000 < getNum("trg_delay", 50) then return end; Trig.last = now
    local chance = getNum("trg_chance", 100); if get("trg_autochance") then chance = chance * math.clamp(1.1 - 0.6 * hitDist / math.max(maxD, 1), 0.3, 1) end
    if math.random() * 100 > chance then return end; if get("trg_gun", true) then clickFire() else activateTool() end
end

local ESP, BONES15, BONES6, EDGES = {}, {{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"}}, {{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"}}, {{1,2},{3,4},{5,6},{7,8},{1,3},{2,4},{5,7},{6,8},{1,5},{2,6},{3,7},{4,8}}
local function mk(e, cls, props) local i = new(cls, props, Overlay); e.All[#e.All + 1] = i; return i end
local function lineAt(e, list, i) local l = list[i]; if not l then l = mk(e, "Frame", {AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, Visible = false}); list[i] = l end; return l end
local function drawLine(l, a, b, thick, color, transp, z) local d = b - a; l.Size = UDim2.fromOffset(d.Magnitude, thick); l.Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2); l.Rotation = math.deg(math.atan2(d.Y, d.X)); l.BackgroundColor3 = color; l.BackgroundTransparency = transp; l.ZIndex = z or 1; l.Visible = true end
local function hideList(list, from) for i = from or 1, #list do list[i].Visible = false end end
local function destroyESP(e) for _, i in ipairs(e.All) do pcall(function() i:Destroy() end) end end
local function makeESP()
    local e = {All = {}, Born = os.clock(), Box = {}, Bones = {}, Tr = {}, Pa = {}, Ghost = 1}
    e.Outline = mk(e, "Frame", {BackgroundTransparency = 1, Visible = false}); e.OutStroke = new("UIStroke", {ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = Color3.new(0, 0, 0), Thickness = 3}, e.Outline); e.OutCorner = new("UICorner", {}, e.Outline)
    e.Fill = mk(e, "Frame", {BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false}); e.Stroke = new("UIStroke", {ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Thickness = 1, Color = Theme.accent}, e.Fill); e.Corner = new("UICorner", {}, e.Fill)
    e.HpBack = mk(e, "Frame", {BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, BorderSizePixel = 0, Visible = false}); e.HpGhost = mk(e, "Frame", {BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 1), Visible = false}); e.HpFill = mk(e, "Frame", {BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 1), Visible = false})
    e.HpText = mk(e, "TextLabel", {BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = Color3.new(1, 1, 1), TextStrokeTransparency = 0.5, AnchorPoint = Vector2.new(1, 0.5), Size = UDim2.fromOffset(30, 12), TextXAlignment = Enum.TextXAlignment.Right, Visible = false})
    e.Name = mk(e, "TextLabel", {BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.fromOffset(0, 0), Font = Enum.Font.GothamBold, TextStrokeTransparency = 0.5, AnchorPoint = Vector2.new(0.5, 1), Visible = false}); new("UICorner", {CornerRadius = UDim.new(0, 6)}, e.Name); new("UIPadding", {PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 1), PaddingBottom = UDim.new(0, 1)}, e.Name)
    e.Info = mk(e, "TextLabel", {BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.fromOffset(0, 0), Font = Enum.Font.Gotham, TextColor3 = Color3.new(1, 1, 1), TextStrokeTransparency = 0.5, AnchorPoint = Vector2.new(0.5, 0), Visible = false})
    e.HeadDot = mk(e, "Frame", {Size = UDim2.fromOffset(6, 6), AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, Visible = false}); new("UICorner", {CornerRadius = UDim.new(1, 0)}, e.HeadDot)
    e.Highlight = mk(e, "Highlight", {FillTransparency = 0.6, Enabled = false}); return e
end
local function hideESP(e) e.Outline.Visible = false; e.Fill.Visible = false; e.HpBack.Visible = false; e.HpGhost.Visible = false; e.HpFill.Visible = false; e.HpText.Visible = false; e.Name.Visible = false; e.Info.Visible = false; e.HeadDot.Visible = false; hideList(e.Box); hideList(e.Bones); hideList(e.Tr); hideList(e.Pa) end
local function espColor(ent) if get("esp_rainbow") then return Color3.fromHSV((os.clock() * 0.2) % 1, 0.8, 1) end; if get("esp_teamcolor") and ent.plr and ent.plr.Team then return ent.plr.TeamColor.Color end; return Color3.fromHSV(math.clamp(getNum("esp_hue", 99), 0, 100) / 100, 0.85, 1) end
local function spawnDamage(amount, x, y, color) local l = new("TextLabel", {BackgroundTransparency = 1, Text = "-" .. tostring(amount), Font = Enum.Font.GothamBlack, TextSize = 16, TextColor3 = color, TextStrokeTransparency = 0.3, AnchorPoint = Vector2.new(0.5, 1), Size = UDim2.fromOffset(60, 18), Position = UDim2.fromOffset(x, y)}, Overlay); TweenService:Create(l, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(x, y - 40), TextTransparency = 1, TextStrokeTransparency = 1}):Play(); Debris:AddItem(l, 0.9) end

local function drawEntity(ent, e, cam, dt, now, dist, color, lite, maxD, vs, hlOK, espOK)
    local hrp, hum = ent.hrp, ent.hum; local fadeMul = 1; if get("esp_fade") then fadeMul = fadeMul * math.clamp(1 - 0.65 * dist / math.max(maxD, 1), 0.25, 1) end; if get("esp_intro") then fadeMul = fadeMul * math.clamp((now - e.Born) / 0.35, 0, 1) end
    local function tr(base) return 1 - (1 - base) * fadeMul end
    if not espOK then hideESP(e); local tp, on = cam:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0)); if on then e.Name.Text = ent.name; e.Name.TextSize = getNum("esp_namesize", 14); e.Name.TextColor3 = color; e.Name.TextTransparency = tr(0); e.Name.BackgroundTransparency = 1; e.Name.Position = UDim2.fromOffset(tp.X, tp.Y - 3); e.Name.Visible = true end; return end
    local sp, onScreen = cam:WorldToViewportPoint(hrp.Position); if not onScreen then hideESP(e); return end
    local top = cam:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0)); local bot = cam:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
    local h = math.abs(top.Y - bot.Y); local w = h * 0.65; local cx, cy = sp.X, (top.Y + bot.Y) / 2; local sm = getNum("esp_smooth", 25)
    if not e.cx or sm <= 0 then e.cx, e.cy, e.w, e.h = cx, cy, w, h else local a = math.clamp(1 - sm / 100, 0.05, 1); e.cx = e.cx + (cx - e.cx) * a; e.cy = e.cy + (cy - e.cy) * a; e.w = e.w + (w - e.w) * a; e.h = e.h + (h - e.h) * a end
    local x0, y0, x1, y1 = e.cx - e.w / 2, e.cy - e.h / 2, e.cx + e.w / 2, e.cy + e.h / 2
    local style = lite and "Full" or get("esp_style", "Corners"); local thick = getNum("esp_thick", 2); local fillA = getNum("esp_fill", 50) / 100
    if get("esp_box") then
        if style == "3D" then
            e.Fill.Visible = false; e.Outline.Visible = false; local cf, pts, okAll = hrp.CFrame, {}, true
            for i = 0, 7 do local off = Vector3.new((i % 2 == 0) and -2 or 2, (math.floor(i / 2) % 2 == 0) and -3 or 3, (math.floor(i / 4) % 2 == 0) and -1 or 1); local v = cam:WorldToViewportPoint(cf:PointToWorldSpace(off)); if v.Z <= 0 then okAll = false end; pts[i + 1] = Vector2.new(v.X, v.Y) end
            if okAll then for i, ed in ipairs(EDGES) do drawLine(lineAt(e, e.Box, i), pts[ed[1]], pts[ed[2]], thick, color, tr(0), 2) end; hideList(e.Box, #EDGES + 1) else hideList(e.Box) end
        elseif style == "Corners" then
            e.Outline.Visible = false; e.Stroke.Enabled = false; e.Corner.CornerRadius = UDim.new(0, 0); e.Fill.Position = UDim2.fromOffset(x0, y0); e.Fill.Size = UDim2.fromOffset(e.w, e.h); e.Fill.BackgroundColor3 = color; e.Fill.BackgroundTransparency = tr(1 - fillA); e.Fill.Visible = fillA > 0
            local len = math.min(e.w, e.h) * 0.28; local segs = {{x0,y0,x0+len,y0},{x0,y0,x0,y0+len},{x1-len,y0,x1,y0},{x1,y0,x1,y0+len},{x0,y1,x0+len,y1},{x0,y1-len,x0,y1},{x1-len,y1,x1,y1},{x1,y1-len,x1,y1}}; local n = 0
            if get("esp_outline") then for i, s in ipairs(segs) do drawLine(lineAt(e, e.Box, i), Vector2.new(s[1], s[2]), Vector2.new(s[3], s[4]), thick + 2, Color3.new(0, 0, 0), tr(0.2), 1) end; n = 8 end
            for i, s in ipairs(segs) do drawLine(lineAt(e, e.Box, n + i), Vector2.new(s[1], s[2]), Vector2.new(s[3], s[4]), thick, color, tr(0), 2) end; hideList(e.Box, n + 9)
        else
            hideList(e.Box); local r = (style == "Rounded") and getNum("esp_round", 6) or 0; e.Fill.Position = UDim2.fromOffset(x0, y0); e.Fill.Size = UDim2.fromOffset(e.w, e.h); e.Fill.BackgroundColor3 = color; e.Fill.BackgroundTransparency = tr(1 - fillA); e.Fill.Visible = true; e.Corner.CornerRadius = UDim.new(0, r); e.Stroke.Enabled = true; e.Stroke.Color = color; e.Stroke.Thickness = thick; e.Stroke.Transparency = tr(0)
            if get("esp_outline") then e.Outline.Position = UDim2.fromOffset(x0, y0); e.Outline.Size = UDim2.fromOffset(e.w, e.h); e.OutCorner.CornerRadius = UDim.new(0, r); e.OutStroke.Thickness = thick + 2; e.OutStroke.Transparency = tr(0.2); e.Outline.Visible = true else e.Outline.Visible = false end
        end
    else e.Fill.Visible = false; e.Outline.Visible = false; hideList(e.Box) end
    local frac = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
    if get("esp_health") then
        local bw = getNum("esp_hpwidth", 4); local bx = x0 - bw - 3; e.HpBack.Position = UDim2.fromOffset(bx, y0); e.HpBack.Size = UDim2.fromOffset(bw, e.h); e.HpBack.Visible = true; e.HpFill.Position = UDim2.fromOffset(bx, y1); e.HpFill.Size = UDim2.fromOffset(bw, e.h * frac); e.HpFill.BackgroundColor3 = Color3.fromRGB(255, 50, 50):Lerp(Color3.fromRGB(80, 255, 80), frac); e.HpFill.BackgroundTransparency = tr(0); e.HpFill.Visible = true
        if get("esp_ghost") and not lite then if e.Ghost > frac then e.Ghost = math.max(frac, e.Ghost - dt * 0.5) else e.Ghost = frac end; e.HpGhost.Position = UDim2.fromOffset(bx, y1); e.HpGhost.Size = UDim2.fromOffset(bw, e.h * e.Ghost); e.HpGhost.BackgroundTransparency = tr(0.4); e.HpGhost.Visible = true else e.Ghost = frac; e.HpGhost.Visible = false end
        if get("esp_hpval") and not lite then e.HpText.Text = tostring(math.floor(hum.Health + 0.5)); e.HpText.Position = UDim2.fromOffset(bx - 2, y1 - e.h * frac); e.HpText.Visible = true else e.HpText.Visible = false end
    else e.HpBack.Visible = false; e.HpGhost.Visible = false; e.HpFill.Visible = false; e.HpText.Visible = false end
    if e.LastHp and hum.Health < e.LastHp - 0.5 and get("esp_dmgnum") and not lite then spawnDamage(math.floor(e.LastHp - hum.Health + 0.5), e.cx, y0, color) end; e.LastHp = hum.Health
    local nameSize = getNum("esp_namesize", 14)
    if get("esp_name") or (get("hl_name") and hlOK) then e.Name.Text = ent.name; e.Name.TextSize = nameSize; e.Name.TextColor3 = color; e.Name.TextTransparency = tr(0); e.Name.TextStrokeTransparency = tr(0.5); e.Name.BackgroundColor3 = Color3.new(0, 0, 0); e.Name.BackgroundTransparency = (get("esp_pill") and not lite) and tr(0.5) or 1; e.Name.Position = UDim2.fromOffset(e.cx, y0 - 3); e.Name.Visible = true else e.Name.Visible = false end
    local parts = {}; if get("esp_distance") and not lite then parts[#parts + 1] = tostring(math.floor(dist * 0.28 + 0.5)) .. "m" end; if get("esp_wpn") then local t = ent.char:FindFirstChildOfClass("Tool"); if t then parts[#parts + 1] = t.Name end end
    if #parts > 0 then e.Info.Text = table.concat(parts, "  "); e.Info.TextSize = math.max(9, nameSize - 3); e.Info.TextTransparency = tr(0); e.Info.Position = UDim2.fromOffset(e.cx, y1 + 2); e.Info.Visible = true else e.Info.Visible = false end
    if lite then e.HeadDot.Visible = false; hideList(e.Bones); hideList(e.Tr); hideList(e.Pa); return end
    local headPart = ent.char:FindFirstChild("Head")
    if get("esp_head") and headPart then local v, on = cam:WorldToViewportPoint(headPart.Position); e.HeadDot.Visible = on; if on then e.HeadDot.Position = UDim2.fromOffset(v.X, v.Y); e.HeadDot.BackgroundColor3 = color; e.HeadDot.BackgroundTransparency = tr(0) end else e.HeadDot.Visible = false end
    if get("esp_skel") then local bones = ent.char:FindFirstChild("UpperTorso") and BONES15 or BONES6; for i, pair in ipairs(bones) do local a, b = ent.char:FindFirstChild(pair[1]), ent.char:FindFirstChild(pair[2]); local l = lineAt(e, e.Bones, i); if a and b then local va, oa = cam:WorldToViewportPoint(a.Position); local vb, ob = cam:WorldToViewportPoint(b.Position); if oa and ob then drawLine(l, Vector2.new(va.X, va.Y), Vector2.new(vb.X, vb.Y), 1, color, tr(0), 2) else l.Visible = false end else l.Visible = false end end; hideList(e.Bones, #bones + 1) else hideList(e.Bones) end
    if get("esp_tracers") then local o = get("esp_torigin", "Bottom"); local origin; if o == "Center" then origin = Vector2.new(vs.X / 2, vs.Y / 2) elseif o == "Top" then origin = Vector2.new(vs.X / 2, 0) elseif o == "Mouse" then local m = UserInputService:GetMouseLocation(); origin = Vector2.new(m.X, m.Y) else origin = Vector2.new(vs.X / 2, vs.Y) end; drawLine(lineAt(e, e.Tr, 1), origin, Vector2.new(e.cx, y1), 1, color, tr(0.3), 1) else hideList(e.Tr) end
    if get("esp_path") then local vel = velocityOf(ent.char, 100); local fut = hrp.Position + vel * (getNum("esp_ptime", 50) / 10); local v, on = cam:WorldToViewportPoint(fut); if on then drawLine(lineAt(e, e.Pa, 1), Vector2.new(sp.X, sp.Y), Vector2.new(v.X, v.Y), 1, color, tr(0.2), 1) else hideList(e.Pa) end else hideList(e.Pa) end
end

local function renderESP(cam, dt)
    local any = get("esp_on", true) and (get("esp_box") or get("esp_name") or get("esp_skel") or get("esp_wpn") or get("esp_health") or get("esp_distance") or get("esp_head") or get("esp_tracers") or get("esp_path")); local anyHL = get("hl_on")
    if not any and not anyHL then for k, e in pairs(ESP) do destroyESP(e); ESP[k] = nil end; return end; if get("esp_npc") then initNPCs() end
    local now, vs = os.clock(), cam.ViewportSize; local maxD, lite = getNum("esp_dist", 1000), get("esp_render", "Full") == "Lite"; local seen = {}
    for _, ent in ipairs(entities()) do
        if (not ent.npc) or get("esp_npc") then
            local espOK = any and ((not ent.plr) or (not get("esp_team")) or ent.enemy); local hlOK = anyHL and ((not ent.plr) or (not get("hl_team")) or ent.enemy); local dist = (ent.hrp.Position - cam.CFrame.Position).Magnitude
            if (espOK or hlOK) and dist <= maxD then
                seen[ent.char] = true; local e = ESP[ent.char]; if not e then e = makeESP(); ESP[ent.char] = e end; local color = espColor(ent)
                if hlOK then local hc = get("hl_color") and color or Theme.accent; e.Highlight.Adornee = ent.char; e.Highlight.FillColor = hc; e.Highlight.OutlineColor = hc; e.Highlight.Enabled = true else e.Highlight.Enabled = false end
                if espOK or (hlOK and get("hl_name")) then drawEntity(ent, e, cam, dt, now, dist, color, lite, maxD, vs, hlOK, espOK) else hideESP(e) end
            end
        end
    end
    for k, e in pairs(ESP) do if not seen[k] then destroyESP(e); ESP[k] = nil end end
end

local function spawnBulletTracer()
    local cam = Workspace.CurrentCamera; if not cam then return end; local cf = cam.CFrame; local origin = cf.Position + cf.RightVector * 0.6 - cf.UpVector * 0.5 + cf.LookVector * 1.5; setFilter(nil)
    local res = Workspace:Raycast(cf.Position, cf.LookVector * 1000, RayP); local hit = res and res.Position or (cf.Position + cf.LookVector * 1000); local len = (hit - origin).Magnitude; if len < 1 then return end
    local life = getNum("trc_life", 5) * 0.2; local p = Instance.new("Part"); p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.Material = Enum.Material.Neon; p.Color = Theme.accent; p.Transparency = 0.15; p.Size = Vector3.new(getNum("trc_width", 2) * 0.03, getNum("trc_width", 2) * 0.03, len); p.CFrame = CFrame.lookAt(origin, hit) * CFrame.new(0, 0, -len / 2); p.Parent = cam; TweenService:Create(p, TweenInfo.new(life), {Transparency = 1}):Play(); Debris:AddItem(p, life + 0.1)
end

local Hud = {}
do
    Hud.mark = new("Frame", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10), Size = UDim2.fromOffset(0, 22), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = Theme.bg, BackgroundTransparency = 0.1, Visible = false}, Overlay); corner(Hud.mark, 6); outline(Hud.mark, 1, Theme.stroke); new("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)}, Hud.mark); Hud.markText = label(Hud.mark, {Size = UDim2.fromOffset(0, 22), AutomaticSize = Enum.AutomaticSize.X, Text = "", TextSize = 12, Font = Enum.Font.GothamBold})
    Hud.list = new("Frame", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 38), Size = UDim2.fromOffset(0, 0), AutomaticSize = Enum.AutomaticSize.XY, BackgroundTransparency = 1, Visible = false}, Overlay); new("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Right}, Hud.list); Hud.lines = {}
    Hud.spec = new("TextLabel", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.4, 0), Size = UDim2.fromOffset(0, 0), AutomaticSize = Enum.AutomaticSize.XY, BackgroundColor3 = Theme.bg, BackgroundTransparency = 0.15, Text = "", TextSize = 12, Font = Enum.Font.GothamBold, TextColor3 = Theme.text, TextXAlignment = Enum.TextXAlignment.Left, Visible = false}, Overlay); corner(Hud.spec, 6); new("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4)}, Hud.spec)
    Hud.toasts = new("Frame", {AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -14, 1, -14), Size = UDim2.fromOffset(210, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1}, Overlay); new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom}, Hud.toasts); Hud.toastN = 0
    Hud.island = new("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 8), Size = UDim2.fromOffset(150, 28), BackgroundColor3 = Color3.new(0, 0, 0), Visible = false}, Overlay); corner(Hud.island, 14); Hud.islandText = label(Hud.island, {Size = UDim2.fromScale(1, 1), Text = "Drx Hub", TextSize = 12, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Center}); Hud.islandBusy = 0
    Hud.mobile = new("TextButton", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.fromOffset(44, 44), BackgroundColor3 = Theme.panel, Text = "D", Font = Enum.Font.GothamBlack, TextSize = 18, TextColor3 = Theme.accent, AutoButtonColor = false, Visible = false}, Overlay); corner(Hud.mobile, 22); outline(Hud.mobile, 2, Theme.accent); Hud.mobile.MouseButton1Click:Connect(function() GUI.Enabled = not GUI.Enabled end)
    Hud.amb = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.accent, BorderSizePixel = 0, ZIndex = 0, Visible = false}, Overlay); Hud.ambGrad = new("UIGradient", {Rotation = 90}, Hud.amb)
end
notify = function(title, sub)
    if get("set_island") then
        local text = title .. (sub and (": " .. sub) or ""); Hud.islandText.Text = text; local w = TextService:GetTextSize(text, 12, Enum.Font.GothamBold, Vector2.new(600, 30)).X + 30; tween(Hud.island, {Size = UDim2.fromOffset(math.max(w, 150), 28)}); Hud.islandBusy = os.clock() + 2
    else
        Hud.toastN = Hud.toastN + 1; local f = new("Frame", {Size = UDim2.fromOffset(210, 40), BackgroundColor3 = Theme.panel, LayoutOrder = Hud.toastN}, Hud.toasts); corner(f, 8); outline(f, 1, Theme.stroke); new("Frame", {Size = UDim2.fromOffset(3, 24), Position = UDim2.fromOffset(8, 8), BackgroundColor3 = Theme.accent, BorderSizePixel = 0}, f); label(f, {Size = UDim2.new(1, -24, 0, 18), Position = UDim2.fromOffset(18, 4), Text = title, TextSize = 12, Font = Enum.Font.GothamBold}); label(f, {Size = UDim2.new(1, -24, 0, 14), Position = UDim2.fromOffset(18, 22), Text = sub or "", TextSize = 11, TextColor3 = Theme.sub}); Debris:AddItem(f, 2.2)
    end
end

local function updateHud(fps)
    Hud.mark.Visible = get("set_watermark", true) and true or false; if Hud.mark.Visible then Hud.markText.Text = string.format("Drx Hub  |  %d fps  |  %d players  |  %s", math.floor(fps + 0.5), #Players:GetPlayers(), os.date("%H:%M")) end
    local showList = get("set_qaccess") and true or false; Hud.list.Visible = showList
    if showList then
        local n = 0; for _, ft in ipairs(Features) do if ft.on() then n = n + 1; local l = Hud.lines[n]; if not l then l = label(Hud.list, {Size = UDim2.fromOffset(0, 14), AutomaticSize = Enum.AutomaticSize.X, Text = "", TextSize = 11, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Right, LayoutOrder = n}); Hud.lines[n] = l end; local txt = ft.name; if ft.bind and Prefs[ft.bind] then local b = Prefs[ft.bind]; if b.Mode ~= "Always" then txt = txt .. "  [" .. tostring(b.Key) .. "]" end; if bindActive(ft.bind) then txt = txt .. "  ENABLED" end end; l.Text = txt; l.LayoutOrder = n; l.Visible = true end end; for i = n + 1, #Hud.lines do Hud.lines[i].Visible = false end
    end
    Hud.island.Visible = get("set_island") and true or false; if Hud.island.Visible and os.clock() > Hud.islandBusy then local n = 0; for _, ft in ipairs(Features) do if ft.on() then n = n + 1 end end; Hud.islandText.Text = "Drx Hub  |  " .. tostring(n) .. " active"; tween(Hud.island, {Size = UDim2.fromOffset(150, 28)}) end
    Hud.mobile.Visible = get("set_mobile") and true or false; local op = getNum("set_opacity", 50) / 100; local t = 1 - op * 0.45; Hud.ambGrad.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, t), NumberSequenceKeypoint.new(0.3, 1), NumberSequenceKeypoint.new(0.7, 1), NumberSequenceKeypoint.new(1, t)}); Hud.amb.Visible = (not get("set_showonly")) or GUI.Enabled
end
local Features = {}
do
    local function esp_any() return get("esp_on", true) and (get("esp_box") or get("esp_name") or get("esp_skel") or get("esp_wpn") or get("esp_health") or get("esp_distance") or get("esp_head") or get("esp_tracers") or get("esp_path")) end
    local function f(name, fn, bind) Features[#Features + 1] = {name = name, on = fn, bind = bind} end
    f("Aimbot", function() return get("aim_on") end, "aim_key"); f("Silent Aim", function() return get("sil_on") end, "sil_key"); f("Triggerbot", function() return get("trg_on") end, "trg_key"); f("Ragebot", function() return get("rage_on") end, "rage_key"); f("Kill All", function() return get("ra_kill") end, "ra_kill_key"); f("Speed", function() return get("mv_speed") end, "mv_speed_key"); f("Fly", function() return get("mv_fly") end, "mv_fly_key"); f("Third Person", function() return get("cam_third") end, "cam_key"); f("Bhop", function() return get("misc_bhop") end); f("ESP", esp_any); f("Anti AFK", function() return get("misc_afk") end); f("No Recoil", function() return get("wpn_recoil") end); f("Instant Reload", function() return get("wpn_reload") end); f("Infinite Magazine", function() return get("wpn_ammo") end); f("Custom Fire Cooldown", function() return get("wpn_cd") end)
end

local HB = {slow = 0, mid = 0, hud = 0, boost = 0, lastHop = 0, tp = false, respawn = 0, bv = nil, paused = false, jump = setmetatable({}, {__mode = "k"}), vim = nil}
local fpsAvg = 60
local function stopFly() if HB.bv then pcall(function() HB.bv:Destroy() end); HB.bv = nil end end
local function onHeartbeat(dt)
    local char = LP.Character; local hum = char and char:FindFirstChildOfClass("Humanoid"); local hrp = char and char:FindFirstChild("HumanoidRootPart"); local cam = Workspace.CurrentCamera
    HB.slow = HB.slow + dt; HB.mid = HB.mid + dt; HB.hud = HB.hud + dt
    if get("ply_respawn") and (not hum or hum.Health <= 0) and os.clock() - HB.respawn > 0.3 then HB.respawn = os.clock(); pcall(function() HB.vim = HB.vim or game:GetService("VirtualInputManager"); HB.vim:SendKeyEvent(true, Enum.KeyCode.Space, false, game); task.delay(0.05, function() pcall(function() HB.vim:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end) end) end) end
    if hum and hrp and hum.Health > 0 and cam then
        local b = HB.jump[hum]; if not b then b = {jp = hum.JumpPower, jh = hum.JumpHeight}; HB.jump[hum] = b end; local typing = UserInputService:GetFocusedTextBox() ~= nil
        if not HB.paused then
            if get("bh_fatigue") then if hum.UseJumpPower then if hum.JumpPower < b.jp then hum.JumpPower = b.jp end elseif hum.JumpHeight < b.jh then hum.JumpHeight = b.jh end end
            if get("mv_speed") and bindActive("mv_speed_key") and hum.MoveDirection.Magnitude > 0.1 then hrp.CFrame = hrp.CFrame + hum.MoveDirection * getNum("mv_extra", 6) * dt end
            if get("misc_bhop") and (not typing) and UserInputService:IsKeyDown(Enum.KeyCode.Space) then if hum.FloorMaterial ~= Enum.Material.Air and os.clock() - HB.lastHop > 0.15 then HB.lastHop = os.clock(); hum.Jump = true; hum:ChangeState(Enum.HumanoidStateType.Jumping); HB.boost = math.min(HB.boost + getNum("bh_inc", 2), math.max(getNum("bh_max", 32) - hum.WalkSpeed, 0)) end; if hum.MoveDirection.Magnitude > 0.1 then hrp.CFrame = hrp.CFrame + hum.MoveDirection * HB.boost * dt end else HB.boost = 0 end
            if get("mv_fly") and bindActive("mv_fly_key") then
                if not HB.bv or HB.bv.Parent ~= hrp then stopFly(); local bv = Instance.new("BodyVelocity"); bv.Name = "DrxFly"; bv.MaxForce = Vector3.new(1e9, 1e9, 1e9); bv.Velocity = Vector3.new(0, 0, 0); bv.Parent = hrp; HB.bv = bv end
                local dir = Vector3.new(0, 0, 0); if not typing then local U, cf = UserInputService, cam.CFrame; if U:IsKeyDown(Enum.KeyCode.W) then dir = dir + cf.LookVector end; if U:IsKeyDown(Enum.KeyCode.S) then dir = dir - cf.LookVector end; if U:IsKeyDown(Enum.KeyCode.D) then dir = dir + cf.RightVector end; if U:IsKeyDown(Enum.KeyCode.A) then dir = dir - cf.RightVector end; if U:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end; if U:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end end
                HB.bv.Velocity = (dir.Magnitude > 0) and dir.Unit * getNum("mv_flyspeed", 60) or Vector3.new(0, 0, 0)
            else stopFly() end
        else stopFly() end
    else stopFly() end
    if HB.mid >= 0.1 then HB.mid = 0; local active = get("cam_third") and bindActive("cam_key"); if active then local d = getNum("cam_dist", 12); LP.CameraMode = Enum.CameraMode.Classic; LP.CameraMaxZoomDistance = d; LP.CameraMinZoomDistance = d; HB.tp = true elseif HB.tp then HB.tp = false; LP.CameraMaxZoomDistance = 128; LP.CameraMinZoomDistance = 0.5 end end
    if HB.slow >= 0.5 then HB.slow = 0; weaponPatchTick(); local want = get("misc_spect") or get("misc_antispect"); local specs = want and currentSpectators() or {}; if get("misc_spect") and #specs > 0 then Hud.spec.Text = "Spectators\n" .. table.concat(specs, "\n"); Hud.spec.Visible = true else Hud.spec.Visible = false end; local pause = get("misc_antispect") and #specs > 0; if pause ~= HB.paused then HB.paused = pause; notify("Anti Spectate", pause and "features paused" or "features resumed") end end
    if HB.hud >= 0.2 then HB.hud = 0; updateHud(fpsAvg) end
end

local function makeCircle() local f = new("Frame", {Size = UDim2.fromOffset(100, 100), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Visible = false}, Overlay); new("UICorner", {CornerRadius = UDim.new(1, 0)}, f); new("UIStroke", {Thickness = 1, Color = Theme.accent}, f); return f end
local fovCircle, aimCircle = makeCircle(), makeCircle()
local silMark = new("Frame", {Size = UDim2.fromOffset(10, 10), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Theme.accent, Visible = false}, Overlay); corner(silMark, 5)
local function updateCircles(cam) local vs = cam.ViewportSize; local c = UDim2.fromOffset(vs.X / 2, vs.Y / 2); local show = get("sil_fovcircle"); local sOn = show and get("sil_on") and not get("sil_any"); fovCircle.Visible = sOn and true or false; if sOn then local d = getNum("sil_fov", 120) * 2; fovCircle.Position = c; fovCircle.Size = UDim2.fromOffset(d, d) end; local aOn = show and get("aim_on"); aimCircle.Visible = aOn and true or false; if aOn then local d = getNum("aim_radius", 120) * 2; aimCircle.Position = c; aimCircle.Size = UDim2.fromOffset(d, d) end; if get("sil_show") and Silent.target then local v, on = cam:WorldToViewportPoint(Silent.target.pos); silMark.Visible = on; if on then silMark.Position = UDim2.fromOffset(v.X, v.Y) end else silMark.Visible = false end end

local function currentSpectators() local probe, out = GameConfig.SpectateProbe or function(plr) local function refs(v) return v == LP or v == LP.Character or v == LP.Name or v == LP.DisplayName or v == LP.UserId end; for k, v in pairs(plr:GetAttributes()) do if tostring(k):lower():find("spect") and refs(v) then return true end end; for _, d in ipairs(plr:GetDescendants()) do if (d:IsA("ObjectValue") or d:IsA("StringValue") or d:IsA("IntValue")) and d.Name:lower():find("spect") and refs(d.Value) then return true end end; return false end, {}; for _, plr in ipairs(Players:GetPlayers()) do if plr ~= LP then local ok, r = pcall(probe, plr); if ok and r then out[#out + 1] = plr.Name end end end; return out end

local gPoll, gTrack, gCircles, gAim, gSilent, gRage, gKill, gTrig, gESP = guard("binds", pollBinds), guard("track", trackEntities), guard("circles", updateCircles), guard("aimbot", runAimbot), guard("silent", runSilent), guard("ragebot", runRage), guard("killall", runKillAll), guard("trigger", runTrigger), guard("esp", renderESP)
local gHB = guard("heartbeat", onHeartbeat)
local rapidLast, bulletLast = 0, 0
local gRapid = guard("rapid", function() if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then return end; if UserInputService:GetFocusedTextBox() or GUI.Enabled then return end; local now = os.clock(); if get("wpn_rapid") and now - rapidLast > 0.04 then rapidLast = now; clickFire() end; if get("trc_on") and now - bulletLast > 0.1 then bulletLast = now; spawnBulletTracer() end end)

pcall(function() RunService:UnbindFromRenderStep("DrxMain") end)
RunService:BindToRenderStep("DrxMain", Enum.RenderPriority.Camera.Value + 1, function(dt) FrameNo = FrameNo + 1; fpsAvg = fpsAvg + (1 / math.max(dt, 1e-4) - fpsAvg) * 0.05; gPoll(); local cam = Workspace.CurrentCamera; if not cam then return end; gTrack(); gCircles(cam); if HB.paused then Silent.target = nil else gAim(cam, dt); gSilent(cam, dt); gRage(cam, dt); gKill(cam, dt); gTrig(cam, dt) end; gESP(cam, dt); gRapid() end)
Conns[#Conns + 1] = RunService.Heartbeat:Connect(function(dt) gHB(dt) end)
Conns[#Conns + 1] = LP.Idled:Connect(function() if get("misc_afk") then pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end) end end)

local dragging, dragStart, startPos = false, nil, nil
local function menuMatch(input, mk) return (input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == mk.Key) or (input.UserInputType == Enum.UserInputType.MouseButton1 and mk.Key == "LMB") or (input.UserInputType == Enum.UserInputType.MouseButton2 and mk.Key == "RMB") or (input.UserInputType == Enum.UserInputType.MouseButton3 and mk.Key == "MMB") end
Conns[#Conns + 1] = UserInputService.InputBegan:Connect(function(input, processed) if input.UserInputType == Enum.UserInputType.MouseButton1 and (not processed) and get("trc_on") and not GUI.Enabled then bulletLast = os.clock(); pcall(spawnBulletTracer) end; if processed then return end; local mk = get("misc_menukey", {Key = "RightShift", Mode = "Toggle"}); local match = menuMatch(input, mk); if mk.Mode == "Toggle" and match then GUI.Enabled = not GUI.Enabled elseif mk.Mode == "Hold" and match then GUI.Enabled = true end end)
Conns[#Conns + 1] = UserInputService.InputEnded:Connect(function(input) local mk = get("misc_menukey", {Key = "RightShift", Mode = "Toggle"}); if mk.Mode == "Hold" and menuMatch(input, mk) then GUI.Enabled = false end; if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false; activeSlider = nil end end)
TopBar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; dragStart = input.Position; startPos = Main.Position end end)
Conns[#Conns + 1] = UserInputService.InputChanged:Connect(function(input) if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then local d = input.Position - dragStart; Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y) end; if activeSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then if activeSlider.track and activeSlider.track.Parent then local pct = math.clamp((input.Position.X - activeSlider.track.AbsolutePosition.X) / math.max(activeSlider.track.AbsoluteSize.X, 1), 0, 1); activeSlider.update(pct) else activeSlider = nil end end end)

local cleaned = false
local function cleanup()
    if cleaned then return end; cleaned = true; if shared.DrxCleanup == cleanup then shared.DrxCleanup = nil end; Silent.alive = false; Silent.target = nil; pcall(function() RunService:UnbindFromRenderStep("DrxMain") end); for _, c in ipairs(Conns) do pcall(function() c:Disconnect() end) end; UiMouse.setOpen(false); UiMouse.alive = false; stopFly(); for k, e in pairs(ESP) do destroyESP(e); ESP[k] = nil end; if HB.tp then pcall(function() LP.CameraMaxZoomDistance = 128; LP.CameraMinZoomDistance = 0.5 end) end; Overlay:Destroy(); if GUI.Parent then GUI:Destroy() end
end
shared.DrxCleanup = cleanup
GUI.Destroying:Connect(cleanup)
UiMouse.setOpen(GUI.Enabled)
Booted = true
print("[Drx Hub V22] pronto | silent-hook=" .. tostring(Silent.hooked) .. " | Build=" .. GameConfig.Build)-- Drx Hub V22 [ULTIMATE COM FIX DE WEAPONS E HOOKS DE CÂMERA/REMOTE]
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
local Booted, notify = false, nil
local function set(k, v) local old = Prefs[k]; Prefs[k] = v; if Booted and type(v) == "boolean" and old ~= v and Labels[k] then notify(Labels[k], v and "enabled" or "disabled") end end
local function get(k, d) local v = Prefs[k]; if v == nil then return d end; return v end
local function getNum(k, d) local v = tonumber(get(k, d)); if not v or v ~= v then return d end; return v end

local Theme = {bg = Color3.fromRGB(18, 12, 14), panel = Color3.fromRGB(28, 18, 22), card = Color3.fromRGB(38, 24, 30), text = Color3.fromRGB(255, 255, 255), sub = Color3.fromRGB(150, 130, 140), accent = Color3.fromRGB(255, 40, 60), stroke = Color3.fromRGB(60, 35, 45), track = Color3.fromRGB(45, 30, 35)}
local function new(cls, props, parent) local i = Instance.new(cls); for k, v in pairs(props) do i[k] = v end; if parent then i.Parent = parent end; return i end
local function corner(i, r) return new("UICorner", {CornerRadius = UDim.new(0, r)}, i) end
local function outline(i, t, c) return new("UIStroke", {Color = c or Theme.stroke, Thickness = t or 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, i) end
local function label(parent, props) props.BackgroundTransparency = 1; props.Font = props.Font or Enum.Font.Gotham; props.TextColor3 = props.TextColor3 or Theme.text; props.TextSize = props.TextSize or 14; props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left; return new("TextLabel", props, parent) end
local TWEEN = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local function tween(i, p) TweenService:Create(i, TWEEN, p):Play() end

local GUI = new("ScreenGui", {Name = "DrxHub", ResetOnSpawn = false, DisplayOrder = 100, ZIndexBehavior = Enum.ZIndexBehavior.Global, Enabled = true}, PlayerGui)
local Overlay = new("ScreenGui", {Name = "DrxOverlay", ResetOnSpawn = false, DisplayOrder = 999, IgnoreGuiInset = true}, PlayerGui)

-- UI MOUSE FIX
local UiMouse = {open = false, saved = nil, wanted = nil, wantedIcon = nil, modal = nil, alive = true, hooked = false, hbConn = nil}
do
    local ACTION_SINK, STEP_NAME = "DrxUiMouseSink", "DrxUiMouseUnlock"
    local function sink() return Enum.ContextActionResult.Sink end
    local function enforce() if UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default then UiMouse.wanted = UserInputService.MouseBehavior end; UserInputService.MouseBehavior = Enum.MouseBehavior.Default; UserInputService.MouseIconEnabled = true end
    if hookmetamethod and checkcaller then
        local old
        local function hook(self, k, v) if UiMouse.alive and UiMouse.open and self == UserInputService and not checkcaller() then if k == "MouseBehavior" then UiMouse.wanted = v; return end; if k == "MouseIconEnabled" then UiMouse.wantedIcon = v; return end end; return old(self, k, v) end
        local ok = pcall(function() old = hookmetamethod(game, "__newindex", newcclosure and newcclosure(hook) or hook) end); UiMouse.hooked = ok and old ~= nil
    end
    function UiMouse.setOpen(open)
        open = open and true or false; if open == UiMouse.open then return end; UiMouse.open = open
        if open then
            UiMouse.saved = {behavior = UserInputService.MouseBehavior, icon = UserInputService.MouseIconEnabled}; UiMouse.wanted, UiMouse.wantedIcon = nil, nil
            local g = Instance.new("ScreenGui"); g.Name = "DrxMouseModal"; g.ResetOnSpawn = false; g.IgnoreGuiInset = true; g.DisplayOrder = 1
            local b = Instance.new("TextButton"); b.Modal = true; b.BackgroundTransparency = 1; b.Text = ""; b.Size = UDim2.fromScale(1, 1); b.Active = true; b.Parent = g; g.Parent = PlayerGui; UiMouse.modal = g
            ContextActionService:BindActionAtPriority(ACTION_SINK, sink, false, Enum.ContextActionPriority.High.Value + 1000, Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2, Enum.UserInputType.MouseWheel)
            RunService:BindToRenderStep(STEP_NAME, Enum.RenderPriority.Last.Value, enforce); UiMouse.hbConn = RunService.Heartbeat:Connect(enforce); enforce()
        else
            pcall(function() RunService:UnbindFromRenderStep(STEP_NAME) end); pcall(function() ContextActionService:UnbindAction(ACTION_SINK) end)
            if UiMouse.hbConn then UiMouse.hbConn:Disconnect(); UiMouse.hbConn = nil end; if UiMouse.modal then UiMouse.modal:Destroy(); UiMouse.modal = nil end
            local sv = UiMouse.saved; UiMouse.saved = nil; local beh, icon = UiMouse.wanted, UiMouse.wantedIcon; UiMouse.wanted, UiMouse.wantedIcon = nil, nil
            if beh == nil and sv then beh = sv.behavior end; if icon == nil and sv then icon = sv.icon end
            if icon ~= nil then UserInputService.MouseIconEnabled = icon end; if beh ~= nil then UserInputService.MouseBehavior = beh end
        end
    end
end
Conns[#Conns + 1] = GUI:GetPropertyChangedSignal("Enabled"):Connect(function() UiMouse.setOpen(GUI.Enabled) end)

-- UI V19
local Main = new("Frame", {Size = UDim2.fromOffset(820, 580), Position = UDim2.new(0.5, -410, 0.5, -290), BackgroundColor3 = Theme.bg, Active = true}, GUI); corner(Main, 12); outline(Main, 2, Theme.accent)
local TopBar = new("Frame", {Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = Theme.panel}, Main); corner(TopBar, 12)
new("Frame", {Size = UDim2.new(1, 0, 0, 15), Position = UDim2.new(0, 0, 1, -15), BackgroundColor3 = Theme.panel}, TopBar)
new("Frame", {Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, -2), BackgroundColor3 = Theme.accent}, TopBar)
label(TopBar, {Size = UDim2.fromOffset(200, 50), Position = UDim2.fromOffset(20, 0), Text = "Drx Hub", Font = Enum.Font.GothamBlack, TextSize = 22, TextColor3 = Theme.accent})
label(TopBar, {Size = UDim2.fromOffset(200, 50), Position = UDim2.fromOffset(100, 0), Text = "ENTERPRISE", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.sub})
local closeBtn = new("TextButton", {Size = UDim2.fromOffset(30, 30), Position = UDim2.new(1, -45, 0.5, -15), BackgroundTransparency = 1, Text = "x", Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = Theme.sub}, TopBar)
closeBtn.MouseEnter:Connect(function() tween(closeBtn, {TextColor3 = Theme.accent}) end); closeBtn.MouseLeave:Connect(function() tween(closeBtn, {TextColor3 = Theme.sub}) end)
closeBtn.MouseButton1Click:Connect(function() GUI.Enabled = false end)

local Body = new("Frame", {Position = UDim2.fromOffset(0, 50), Size = UDim2.new(1, 0, 1, -50), BackgroundTransparency = 1}, Main)
local Sidebar = new("Frame", {Position = UDim2.fromOffset(15, 15), Size = UDim2.fromOffset(170, 495), BackgroundColor3 = Theme.panel}, Body); corner(Sidebar, 10); outline(Sidebar, 1, Theme.stroke)
local NavList = new("ScrollingFrame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ScrollBarThickness = 0}, Sidebar)
new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, NavList); new("UIPadding", {PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}, NavList)
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
    new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, body); return body
end
local function CreateToggle(parent, name, key, default)
    Prefs[key] = Prefs[key] or default; Labels[key] = name
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = Theme.card}, parent); corner(row, 8); outline(row, 1, Theme.stroke)
    label(row, {Size = UDim2.new(1, -60, 1, 0), Position = UDim2.fromOffset(12, 0), Text = name, TextSize = 13, Font = Enum.Font.GothamBold})
    local sw = new("TextButton", {Size = UDim2.new(0, 36, 0, 20), Position = UDim2.new(1, -48, 0.5, -10), BackgroundColor3 = Theme.track, Text = "", AutoButtonColor = false}, row); corner(sw, 10)
    local knob = new("Frame", {Size = UDim2.fromOffset(14, 14), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = Theme.sub}, sw); corner(knob, 7)
    local function render() local on = get(key); tween(sw, {BackgroundColor3 = on and Theme.accent or Theme.track}); tween(knob, {Position = on and UDim2.fromOffset(19, 3) or UDim2.fromOffset(3, 3), BackgroundColor3 = on and Theme.text or Theme.sub}) end
    sw.MouseButton1Click:Connect(function() set(key, not get(key)); render() end); render()
end
local function CreateSlider(parent, name, key, min, max, default)
    Prefs[key] = Prefs[key] or default
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = Theme.card}, parent); corner(row, 8); outline(row, 1, Theme.stroke)
    label(row, {Size = UDim2.new(1, -80, 0, 20), Position = UDim2.fromOffset(12, 8), Text = name, TextSize = 13, Font = Enum.Font.GothamBold})
    local minus = new("TextButton", {Size = UDim2.fromOffset(20, 20), Position = UDim2.new(1, -80, 0, 8), BackgroundColor3 = Theme.panel, Text = "-", TextColor3 = Theme.text, TextSize = 14, AutoButtonColor = false}, row); corner(minus, 4)
    local valLbl = label(row, {Size = UDim2.fromOffset(40, 20), Position = UDim2.new(1, -55, 0, 8), Text = tostring(get(key)), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Center})
    local plus = new("TextButton", {Size = UDim2.fromOffset(20, 20), Position = UDim2.new(1, -20, 0, 8), BackgroundColor3 = Theme.panel, Text = "+", TextColor3 = Theme.text, TextSize = 14, AutoButtonColor = false}, row); corner(plus, 4)
    local btn = new("TextButton", {Size = UDim2.new(1, -24, 0, 15), Position = UDim2.fromOffset(12, 30), BackgroundTransparency = 1, Text = ""}, row)
    local track = new("Frame", {Size = UDim2.new(1, 0, 0, 4), Position = UDim2.fromOffset(0, 6), BackgroundColor3 = Theme.track}, btn); corner(track, 2)
    local fill = new("Frame", {Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Theme.accent}, track); corner(fill, 2)
    local knob = new("Frame", {Size = UDim2.fromOffset(12, 12), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Theme.accent}, track); corner(knob, 6)
    local function update(pct) local v = math.floor(min + pct * (max - min) + 0.5); set(key, v); pct = (v - min) / math.max(max - min, 1); fill.Size = UDim2.new(pct, 0, 1, 0); knob.Position = UDim2.new(pct, 0, 0.5, 0); valLbl.Text = tostring(v) end
    update((getNum(key, default) - min) / math.max(max - min, 1))
    btn.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then activeSlider = {update = update, track = track}; if track.AbsoluteSize.X > 0 then update(math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)) end end end)
    minus.MouseButton1Click:Connect(function() update(math.clamp((getNum(key) - 1 - min) / math.max(max - min, 1), 0, 1)) end)
    plus.MouseButton1Click:Connect(function() update(math.clamp((getNum(key) + 1 - min) / math.max(max - min, 1), 0, 1)) end)
end
local function CreateDropdown(parent, name, key, options, default)
    Prefs[key] = Prefs[key] or default
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = Theme.card}, parent); corner(row, 8); outline(row, 1, Theme.stroke)
    label(row, {Size = UDim2.new(1, -60, 1, 0), Position = UDim2.fromOffset(12, 0), Text = name, TextSize = 13, Font = Enum.Font.GothamBold})
    local btn = new("TextButton", {Size = UDim2.new(0, 100, 0, 24), Position = UDim2.new(1, -112, 0.5, -12), BackgroundColor3 = Theme.panel, Text = "", AutoButtonColor = false}, row); corner(btn, 6); outline(btn, 1, Theme.stroke)
    local txt = label(btn, {Size = UDim2.new(1, -20, 1, 0), Position = UDim2.fromOffset(8, 0), Text = tostring(get(key)), TextSize = 12})
    local list = new("Frame", {Size = UDim2.new(0, 100, 0, #options * 24), Position = UDim2.new(1, -112, 1, 4), BackgroundColor3 = Theme.panel, Visible = false, ZIndex = 999}, row); corner(list, 6); outline(list, 1, Theme.stroke)
    for i, opt in ipairs(options) do
        local b = new("TextButton", {Size = UDim2.new(1, 0, 0, 24), Position = UDim2.fromOffset(0, (i - 1) * 24), BackgroundTransparency = 1, Text = opt, TextSize = 12, TextColor3 = Theme.sub, ZIndex = 1000}, list)
        b.MouseEnter:Connect(function() b.TextColor3 = Theme.text end); b.MouseLeave:Connect(function() b.TextColor3 = Theme.sub end)
        b.MouseButton1Click:Connect(function() set(key, opt); txt.Text = opt; list.Visible = false end)
    end
    btn.MouseButton1Click:Connect(function() list.Visible = not list.Visible end)
end
local function CreateKeybind(parent, name, key, defaultKey, defaultMode)
    Prefs[key] = Prefs[key] or {Key = defaultKey, Mode = defaultMode}; BindNames[key] = name
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = Theme.card}, parent); corner(row, 8); outline(row, 1, Theme.stroke)
    label(row, {Size = UDim2.new(1, -120, 1, 0), Position = UDim2.fromOffset(12, 0), Text = name, TextSize = 13, Font = Enum.Font.GothamBold})
    local container = new("Frame", {Size = UDim2.new(0, 100, 0, 24), Position = UDim2.new(1, -112, 0.5, -12), BackgroundColor3 = Theme.panel}, row); corner(container, 6); outline(container, 1, Theme.stroke)
    local btnKey = new("TextButton", {Size = UDim2.new(0.5, 0, 1, 0), BackgroundTransparency = 1, Text = tostring(get(key).Key), TextSize = 12, TextColor3 = Theme.text}, container)
    local btnMode = new("TextButton", {Size = UDim2.new(0.5, 0, 1, 0), Position = UDim2.new(0.5, 0, 0, 0), BackgroundTransparency = 1, Text = tostring(get(key).Mode), TextSize = 10, TextColor3 = Theme.sub}, container)
    btnMode.MouseButton1Click:Connect(function() local modes = {"Always", "Hold", "Toggle"}; local curr = get(key).Mode; local nextMode = modes[1]; for i, m in ipairs(modes) do if m == curr then nextMode = modes[(i % #modes) + 1] break end end; set(key, {Key = get(key).Key, Mode = nextMode}); btnMode.Text = nextMode end)
    btnKey.MouseButton1Click:Connect(function() btnKey.Text = "..."; local conn; conn = UserInputService.InputBegan:Connect(function(input, processed) if processed then return end; local kName = nil; if input.UserInputType == Enum.UserInputType.Keyboard then kName = input.KeyCode.Name elseif input.UserInputType == Enum.UserInputType.MouseButton1 then kName = "LMB" elseif input.UserInputType == Enum.UserInputType.MouseButton2 then kName = "RMB" elseif input.UserInputType == Enum.UserInputType.MouseButton3 then kName = "MMB" end; if kName then set(key, {Key = kName, Mode = get(key).Mode}); btnKey.Text = kName; conn:Disconnect() end end) end)
end
local Pages, NavButtons = {}, {}
local function AddPage(name, buildFunc)
    local page = new("ScrollingFrame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ScrollBarThickness = 4, ScrollBarImageColor3 = Theme.accent, Visible = false, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0,0,0,0)}, PageContainer)
    local grid = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1}, page); new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 15), SortOrder = Enum.SortOrder.LayoutOrder}, grid)
    local col1 = new("Frame", {Size = UDim2.new(0.5, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 1}, grid); new("UIListLayout", {Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder}, col1)
    local col2 = new("Frame", {Size = UDim2.new(0.5, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 2}, grid); new("UIListLayout", {Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder}, col2)
    Pages[name] = page; buildFunc(col1, col2)
end
local function SwitchPage(name)
    activeSlider = nil; for n, p in pairs(Pages) do p.Visible = (n == name) end
    for n, b in pairs(NavButtons) do local sel = (n == name); tween(b.bg, {BackgroundColor3 = sel and Theme.accent or Theme.panel}); tween(b.txt, {TextColor3 = sel and Theme.text or Theme.sub}) end
end
local function AddNav(name)
    local btn = new("TextButton", {Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = Theme.panel, Text = "", AutoButtonColor = false}, NavList); corner(btn, 8); outline(btn, 1, Theme.stroke)
    local txt = label(btn, {Size = UDim2.new(1, -30, 1, 0), Position = UDim2.fromOffset(30, 0), Text = name, TextSize = 14, TextColor3 = Theme.sub, Font = Enum.Font.GothamBold})
    local ind = new("Frame", {Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(10, 12), BackgroundColor3 = Theme.sub}, btn); corner(ind, 4)
    btn.MouseEnter:Connect(function() if Pages[name] and not Pages[name].Visible then tween(btn, {BackgroundColor3 = Theme.card}) end end)
    btn.MouseLeave:Connect(function() if Pages[name] and not Pages[name].Visible then tween(btn, {BackgroundColor3 = Theme.panel}) end end)
    NavButtons[name] = {bg = btn, txt = txt, ind = ind}; btn.MouseButton1Click:Connect(function() SwitchPage(name) end)
end

AddPage("Rage", function(c1, c2)
    local g1 = CreateGroup(c1, "Ragebot"); CreateToggle(g1, "Ragebot", "rage_on", false); CreateKeybind(g1, "Ragebot Key", "rage_key", "Always", "Always"); CreateToggle(g1, "Wallbang", "rage_wall", false); CreateSlider(g1, "FOV", "rage_fov", 10, 360, 120); CreateSlider(g1, "FOV Size", "rage_fovsize", 10, 800, 720); CreateKeybind(g1, "Auto Shoot", "rage_autoshoot", "Always", "Always"); CreateToggle(g1, "Team Check", "rage_team", true)
    local g3 = CreateGroup(c1, "Kill All"); CreateToggle(g3, "Kill All", "ra_kill", false); CreateKeybind(g3, "Kill All Key", "ra_kill_key", "Always", "Always"); CreateToggle(g3, "Use Gun", "ra_kill_gun", true)
    local g2 = CreateGroup(c2, "Weapon Mods"); CreateToggle(g2, "Rapid Fire", "wpn_rapid", false); CreateToggle(g2, "No Recoil", "wpn_recoil", false); CreateToggle(g2, "No Spread", "wpn_spread", false); CreateToggle(g2, "Instant Reload", "wpn_reload", false); CreateToggle(g2, "Infinite Magazine", "wpn_ammo", false); CreateToggle(g2, "Custom Fire Cooldown", "wpn_cd", false); CreateSlider(g2, "Fire Cooldown (ms)", "wpn_cdval", 0, 1000, 500)
    local g4 = CreateGroup(c2, "Player"); CreateToggle(g4, "Auto Respawn", "ply_respawn", false)
end)
AddPage("Legit", function(c1, c2)
    local g1 = CreateGroup(c1, "Silent Aim"); CreateToggle(g1, "Silent Aim", "sil_on", false); CreateKeybind(g1, "Silent Key", "sil_key", "Always", "Always"); CreateSlider(g1, "Smooth", "sil_smooth", 1, 20, 5); CreateToggle(g1, "Visible Only", "sil_vis", false); CreateDropdown(g1, "Bone", "sil_bone", {"Head", "Torso", "Root"}, "Head"); CreateToggle(g1, "Team Check", "sil_team", true); CreateToggle(g1, "Anywhere (360°)", "sil_any", false); CreateToggle(g1, "Show Target", "sil_show", true)
    local g5 = CreateGroup(c1, "Aimbot"); CreateToggle(g5, "Aimbot", "aim_on", false); CreateKeybind(g5, "Aimbot Key", "aim_key", "RMB", "Hold"); CreateDropdown(g5, "Part", "aim_part", {"Head", "Torso", "Closest"}, "Head"); CreateSlider(g5, "Radius", "aim_radius", 10, 800, 120); CreateSlider(g5, "Max Distance", "aim_dist", 50, 2000, 450); CreateToggle(g5, "Wall Check", "aim_wall", true); CreateDropdown(g5, "Priority", "aim_prio", {"Cursor", "Distance", "Threat"}, "Threat"); CreateSlider(g5, "Cursor Weight %", "aim_wc", 0, 100, 40); CreateSlider(g5, "Distance Weight %", "aim_wd", 0, 100, 35); CreateSlider(g5, "Facing Weight %", "aim_wf", 0, 100, 25); CreateToggle(g5, "Off-screen Targets", "aim_off", true); CreateToggle(g5, "Sticky Target", "aim_sticky", true); CreateToggle(g5, "Pre-aim Peeks", "aim_peek", true); CreateSlider(g5, "Smoothness %", "aim_smooth", 1, 100, 35); CreateSlider(g5, "Reaction Time (ms)", "aim_react", 0, 500, 120); CreateToggle(g5, "Prediction", "aim_pred", true); CreateSlider(g5, "Prediction Sampling (ms)", "aim_sample", 10, 300, 90); CreateToggle(g5, "Random Offset", "aim_rand", true); CreateSlider(g5, "Offset Size (x0.01)", "aim_offs", 0, 100, 40)
    local g2 = CreateGroup(c2, "FOV"); CreateSlider(g2, "FOV Size", "sil_fov", 10, 800, 120); CreateToggle(g2, "FOV Circle", "sil_fovcircle", true)
    local g3 = CreateGroup(c2, "Triggerbot"); CreateToggle(g3, "Triggerbot", "trg_on", false); CreateKeybind(g3, "Trigger Key", "trg_key", "Always", "Always"); CreateSlider(g3, "Trigger Delay (ms)", "trg_delay", 0, 500, 50); CreateToggle(g3, "Team Check", "trg_team", true); CreateToggle(g3, "Gun (LMB)", "trg_gun", true); CreateDropdown(g3, "Hit Zone", "trg_zone", {"Head", "Upper body", "Whole body"}, "Whole body"); CreateSlider(g3, "Hit Chance %", "trg_chance", 0, 100, 100); CreateToggle(g3, "Auto Hit Chance", "trg_autochance", false); CreateToggle(g3, "Auto Reaction Time", "trg_autoreact", false); CreateSlider(g3, "Reaction Time (ms)", "trg_react", 0, 500, 60); CreateSlider(g3, "Max Distance", "trg_dist", 50, 2000, 1000); CreateToggle(g3, "FOV Target Only", "trg_fovonly", false)
end)
AddPage("Misc", function(c1, c2)
    local g1 = CreateGroup(c1, "Misc"); CreateToggle(g1, "Spectator list", "misc_spect", false); CreateToggle(g1, "Anti Spectate", "misc_antispect", false); CreateToggle(g1, "Anti AFK", "misc_afk", true); CreateToggle(g1, "Bhop", "misc_bhop", false); CreateSlider(g1, "Speed Per Jump", "bh_inc", 0, 10, 2); CreateSlider(g1, "Max Speed", "bh_max", 16, 100, 32); CreateToggle(g1, "No Jump Fatigue", "bh_fatigue", true)
    local g3 = CreateGroup(c1, "Movement"); CreateToggle(g3, "Speed", "mv_speed", false); CreateKeybind(g3, "Speed Key", "mv_speed_key", "Always", "Always"); CreateSlider(g3, "Extra Speed", "mv_extra", 0, 50, 6); CreateToggle(g3, "Fly", "mv_fly", false); CreateKeybind(g3, "Fly Key", "mv_fly_key", "Always", "Always"); CreateSlider(g3, "Fly Speed", "mv_flyspeed", 10, 200, 60)
    local g2 = CreateGroup(c2, "Camera"); CreateToggle(g2, "Third Person", "cam_third", false); CreateKeybind(g2, "Third Person Key", "cam_key", "V", "Toggle"); CreateSlider(g2, "ThirdPerson Distance", "cam_dist", 5, 50, 12)
end)
AddPage("Inventory Changer", function(c1, c2) local g1 = CreateGroup(c1, "Skins"); label(g1, {Size = UDim2.new(1, 0, 0, 20), Text = "Em breve...", TextSize = 14, TextColor3 = Theme.sub}) end)
AddPage("Visuals", function(c1, c2)
    local g1 = CreateGroup(c1, "ESP"); CreateToggle(g1, "Enabled", "esp_on", true); CreateDropdown(g1, "Renderer", "esp_render", {"Full", "Lite"}, "Full"); CreateToggle(g1, "Box ESP", "esp_box", false); CreateToggle(g1, "ESP Name", "esp_name", false); CreateToggle(g1, "Skeleton", "esp_skel", false); CreateToggle(g1, "Weapon ESP", "esp_wpn", false); CreateToggle(g1, "ESP Team Check", "esp_team", true); CreateToggle(g1, "Health Bar", "esp_health", false); CreateToggle(g1, "Include NPCs", "esp_npc", false); CreateSlider(g1, "Max Distance", "esp_dist", 50, 2000, 1000); CreateToggle(g1, "Fade With Distance", "esp_fade", false); CreateToggle(g1, "Intro Animation", "esp_intro", false); CreateToggle(g1, "Distance", "esp_distance", false); CreateToggle(g1, "Head Dot", "esp_head", false); CreateToggle(g1, "Tracers", "esp_tracers", false); CreateDropdown(g1, "Tracer Origin", "esp_torigin", {"Bottom", "Center", "Mouse", "Top"}, "Bottom"); CreateToggle(g1, "Path Prediction", "esp_path", false); CreateSlider(g1, "Prediction Time (x0.1s)", "esp_ptime", 1, 50, 50); CreateSlider(g1, "Color (Hue)", "esp_hue", 0, 100, 99); CreateToggle(g1, "Rainbow", "esp_rainbow", false); CreateToggle(g1, "Team Color", "esp_teamcolor", false)
    local g4 = CreateGroup(c1, "Box"); CreateDropdown(g4, "Style", "esp_style", {"Full", "Corners", "Rounded", "3D"}, "Corners"); CreateSlider(g4, "Thickness", "esp_thick", 1, 6, 2); CreateSlider(g4, "Rounding", "esp_round", 0, 20, 6); CreateSlider(g4, "Fill %", "esp_fill", 0, 100, 50); CreateToggle(g4, "Outline", "esp_outline", false); CreateSlider(g4, "Size Smoothing %", "esp_smooth", 0, 100, 25)
    local g5 = CreateGroup(c1, "Health"); CreateToggle(g5, "Damage Ghost", "esp_ghost", false); CreateToggle(g5, "Damage Numbers", "esp_dmgnum", false); CreateToggle(g5, "Health Value", "esp_hpval", false); CreateSlider(g5, "Width", "esp_hpwidth", 1, 6, 4)
    local g6 = CreateGroup(c1, "Labels"); CreateToggle(g6, "Name Pill", "esp_pill", false); CreateSlider(g6, "Name Size", "esp_namesize", 8, 30, 14)
    local g2 = CreateGroup(c2, "Highlight"); CreateToggle(g2, "Enable Highlight", "hl_on", false); CreateToggle(g2, "Highlight Team Check", "hl_team", true); CreateToggle(g2, "Highlight Color", "hl_color", false); CreateToggle(g2, "Show Name", "hl_name", false)
    local g3 = CreateGroup(c2, "Tracers"); CreateToggle(g3, "Enable Tracers", "trc_on", false); CreateSlider(g3, "Tracer Width", "trc_width", 1, 10, 2); CreateSlider(g3, "Tracer Lifetime", "trc_life", 1, 10, 5)
end)
AddPage("World", function(c1, c2) local g1 = CreateGroup(c1, "Ambiente"); label(g1, {Size = UDim2.new(1, 0, 0, 20), Text = "Em breve...", TextSize = 14, TextColor3 = Theme.sub}) end)
AddPage("Settings", function(c1, c2)
    local g1 = CreateGroup(c1, "Universal Settings"); CreateToggle(g1, "Dynamic Island", "set_island", false); CreateToggle(g1, "Watermark HUD", "set_watermark", true); CreateToggle(g1, "Quick Access Keybind", "set_qaccess", false); CreateToggle(g1, "Mobile Toggle Button", "set_mobile", false); CreateKeybind(g1, "Menu Keybind", "misc_menukey", "RightShift", "Toggle")
    local g2 = CreateGroup(c2, "Screen Ambience"); CreateSlider(g2, "Ambience Opacity", "set_opacity", 10, 100, 50); CreateToggle(g2, "Show Only When UI...", "set_showonly", false)
end)
AddNav("Rage"); AddNav("Legit"); AddNav("Misc"); AddNav("Inventory Changer"); AddNav("Visuals"); AddNav("World"); AddNav("Settings"); SwitchPage("Rage")

-- ENGINE V22
local function guard(name, fn) return function(...) local ok, err = pcall(fn, ...); if not ok and not Warned[name] then Warned[name] = true; warn("[Drx] " .. name .. ": " .. tostring(err)) end end end
local Cap = {mousemoverel = mousemoverel, mouse1click = mouse1click, hookmetamethod = hookmetamethod, newcclosure = newcclosure, checkcaller = checkcaller, getnamecallmethod = getnamecallmethod}
local function clickFire() if type(Cap.mouse1click) == "function" then local ok = pcall(Cap.mouse1click); if ok then return end end; pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton1(Vector2.new()) end) end
local function activateTool() local c = LP.Character; local t = c and c:FindFirstChildOfClass("Tool"); if t then pcall(function() t:Activate() end) end end

-- Hook no GetMouseDelta
local MouseDeltaHook = {installed = false, pending = Vector2.new(0, 0)}
do
    if Cap.hookmetamethod and Cap.newcclosure and Cap.checkcaller then
        local oldIdx
        local function idxHook(self, key)
            if oldIdx and self == UserInputService and key == "GetMouseDelta" and not Cap.checkcaller() then
                local real = oldIdx(self, key)
                return function(s) local d = real(s); local p = MouseDeltaHook.pending; if p.X ~= 0 or p.Y ~= 0 then MouseDeltaHook.pending = Vector2.new(0, 0) end; return d + p end
            end
            return oldIdx(self, key)
        end
        local ok = pcall(function() oldIdx = Cap.hookmetamethod(UserInputService, "__index", Cap.newcclosure(idxHook)) end); MouseDeltaHook.installed = ok and oldIdx ~= nil
    end
end

local BindState = {}
local function inputDown(keyName) if keyName == "LMB" then return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) elseif keyName == "RMB" then return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) elseif keyName == "MMB" then return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton3) end; local ok, kc = pcall(function() return Enum.KeyCode[keyName] end); if ok and kc then return UserInputService:IsKeyDown(kc) end; return false end
local function pollBinds() local typing = UserInputService:GetFocusedTextBox() ~= nil; for k, v in pairs(Prefs) do if type(v) == "table" and v.Key and v.Mode and k ~= "misc_menukey" then local st = BindState[k]; if not st then st = {on = false, prev = false}; BindState[k] = st end; if v.Mode == "Always" or v.Key == "None" then st.on = true else local down = (not typing) and inputDown(v.Key); if v.Mode == "Hold" then st.on = down elseif down and not st.prev then st.on = not st.on end; st.prev = down end end end end
local function bindActive(k) local st = BindState[k]; return st ~= nil and st.on end

local FrameNo, NPCs, NPCInit = 0, {}, false
local function initNPCs() if NPCInit then return end; NPCInit = true; local function consider(inst) if inst:IsA("Humanoid") then local m = inst.Parent; if m and m:IsA("Model") and m ~= LP.Character and not Players:GetPlayerFromCharacter(m) then NPCs[m] = true end end end; for _, d in ipairs(Workspace:GetDescendants()) do consider(d) end; Conns[#Conns + 1] = Workspace.DescendantAdded:Connect(consider); Conns[#Conns + 1] = Workspace.DescendantRemoving:Connect(function(d) if d:IsA("Humanoid") and d.Parent then NPCs[d.Parent] = nil end end) end
local function isEnemyPlayer(plr) if plr.Neutral or plr.Team == nil or LP.Team == nil then return true end; return plr.Team ~= LP.Team end
local function buildEntity(char, plr) local hum = char:FindFirstChildOfClass("Humanoid"); local hrp = char:FindFirstChild("HumanoidRootPart"); if not hum or not hrp or hum.Health <= 0 then return nil end; return {char = char, hum = hum, hrp = hrp, plr = plr, name = plr and plr.Name or char.Name} end
local EntCache = {frame = -1, list = {}, byChar = {}}
local function entities() if EntCache.frame == FrameNo then return EntCache.list end; local list, by = {}, {}; for _, plr in ipairs(Players:GetPlayers()) do if plr ~= LP and plr.Character then local e = buildEntity(plr.Character, plr); if e then e.enemy = isEnemyPlayer(plr); list[#list + 1] = e; by[e.char] = e end end end; if NPCInit then for m in pairs(NPCs) do if m.Parent and not Players:GetPlayerFromCharacter(m) then local e = buildEntity(m, nil); if e then e.enemy = true; e.npc = true; list[#list + 1] = e; by[m] = e end else NPCs[m] = nil end end end; EntCache.frame = FrameNo; EntCache.list = list; EntCache.byChar = by; return list end
local Track = {}
local function trackEntities() local now, alive = os.clock(), {}; for _, e in ipairs(entities()) do local t = Track[e.char]; if not t then t = {}; Track[e.char] = t end; t[#t + 1] = {now, e.hrp.Position}; while #t > 2 and now - t[1][1] > 0.6 do table.remove(t, 1) end; alive[e.char] = true end; for c in pairs(Track) do if not alive[c] then Track[c] = nil end end end
local function velocityOf(char, windowMs) local t = Track[char]; if not t or #t < 2 then return Vector3.new(0, 0, 0) end; local last = t[#t]; local first = last; for i = #t - 1, 1, -1 do if last[1] - t[i][1] <= windowMs / 1000 then first = t[i] else break end end; local dt = last[1] - first[1]; if dt < 1e-3 then return Vector3.new(0, 0, 0) end; return (last[2] - first[2]) / dt end

local RayP = RaycastParams.new(); RayP.FilterType = Enum.RaycastFilterType.Exclude
local function setFilter(extra) local f = {}; if LP.Character then f[#f + 1] = LP.Character end; if extra then f[#f + 1] = extra end; RayP.FilterDescendantsInstances = f end
local WallP = RaycastParams.new(); WallP.FilterType = Enum.RaycastFilterType.Exclude; WallP.RespectCanCollide = true
local function lineClear(cam, pos, char) local f = {}; if LP.Character then f[#f + 1] = LP.Character end; if char then f[#f + 1] = char end; WallP.FilterDescendantsInstances = f; return Workspace:Raycast(cam.CFrame.Position, pos - cam.CFrame.Position, WallP) == nil end
local function getPart(char, which) if which == "Head" then return char:FindFirstChild("Head") elseif which == "Torso" then return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") end; return char:FindFirstChild("HumanoidRootPart") end
local Jitter = setmetatable({}, {__mode = "k"})
local function jitterFor(char, size) local j, now = Jitter[char], os.clock(); if not j or now - j.t > 0.25 then j = {t = now, v = Vector3.new(math.random() * 2 - 1, math.random() * 2 - 1, math.random() * 2 - 1) * size}; Jitter[char] = j end; return j.v end

local function pickTarget(o)
    local cam = Workspace.CurrentCamera; if not cam then return nil end
    local vs = cam.ViewportSize; local center = Vector2.new(vs.X / 2, vs.Y / 2); local camPos, look = cam.CFrame.Position, cam.CFrame.LookVector
    local pxPerDeg = vs.Y / math.max(cam.FieldOfView, 1); local ref = (o.radius < 1e5) and o.radius or vs.Y / 2; local best, bestScore
    for _, e in ipairs(entities()) do
        if not e.npc and ((not o.teamCheck) or e.enemy) then
            local cands = (o.part == "Closest") and {"Head", "Torso", "Root"} or {o.part}; local ePart, ePos, eOn, eCur
            for _, w in ipairs(cands) do
                local part = getPart(e.char, w)
                if part then
                    local pos = part.Position; if o.predict then pos = pos + velocityOf(e.char, o.sample) * (o.sample / 1000) end; if o.jitter and o.jitter > 0 then pos = pos + jitterFor(e.char, o.jitter) end
                    local v, on = cam:WorldToViewportPoint(pos); local cur
                    if on then cur = (Vector2.new(v.X, v.Y) - center).Magnitude else local d = pos - camPos; cur = d.Magnitude > 0.01 and math.deg(math.acos(math.clamp(look:Dot(d.Unit), -1, 1))) * pxPerDeg or 0 end
                    if not ePart or cur < eCur then ePart, ePos, eOn, eCur = part, pos, on, cur end
                end
            end
            if ePart then
                local studs = (ePos - camPos).Magnitude; local ok = studs <= o.maxDist
                if ok and o.angle and o.angle < 360 and studs > 0.01 then ok = math.deg(math.acos(math.clamp(look:Dot((ePos - camPos).Unit), -1, 1))) <= o.angle / 2 end
                if ok then if eOn then ok = eCur <= o.radius else ok = o.offscreen end end
                if ok and o.wall and not lineClear(cam, ePos, e.char) then ok = false; if o.peek then local lead = velocityOf(e.char, o.sample or 90) * 0.2; if lineClear(cam, ePos + lead, e.char) then ok = true; ePos = ePos + lead end end end
                if ok then
                    local score
                    if o.prio == "Distance" then score = studs / math.max(o.maxDist, 1)
                    elseif o.prio == "Threat" then local toCam = camPos - e.hrp.Position; local facing = toCam.Magnitude > 0.01 and (1 - e.hrp.CFrame.LookVector:Dot(toCam.Unit)) / 2 or 0.5; score = o.wc * math.min(eCur / ref, 3) + o.wd * (studs / math.max(o.maxDist, 1)) + o.wf * facing
                    else score = eCur end
                    if o.sticky and o.sticky == e.char then score = -1 end
                    if not bestScore or score < bestScore then bestScore = score; best = {ent = e, part = ePart, pos = ePos, onScreen = eOn, cursor = eCur} end
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
        local vs = cam.ViewportSize; local dx, dy = (v.X - vs.X / 2) * alpha, (v.Y - vs.Y / 2) * alpha
        if type(Cap.mousemoverel) == "function" then local ok = pcall(Cap.mousemoverel, dx, dy); if ok then return end end
        if MouseDeltaHook.installed then MouseDeltaHook.pending = MouseDeltaHook.pending + Vector2.new(dx, dy) else cam.CFrame = CFrame.new(cam.CFrame.Position, target.pos) end
    end
end

local Aim = {char = nil, since = 0}
local function runAimbot(cam, dt)
    if not (get("aim_on") and bindActive("aim_key")) then Aim.char = nil; return end
    local wc, wd, wf = getNum("aim_wc", 40), getNum("aim_wd", 35), getNum("aim_wf", 25); local sum = math.max(wc + wd + wf, 1)
    local t = pickTarget({part = get("aim_part", "Head"), radius = getNum("aim_radius", 120), maxDist = getNum("aim_dist", 450), wall = get("aim_wall", true), peek = get("aim_peek", true), prio = get("aim_prio", "Threat"), wc = wc / sum, wd = wd / sum, wf = wf / sum, offscreen = get("aim_off", true), sticky = get("aim_sticky", true) and Aim.char or nil, predict = get("aim_pred", true), sample = getNum("aim_sample", 90), jitter = get("aim_rand", true) and getNum("aim_offs", 40) / 100 or 0, teamCheck = true})
    if not t then Aim.char = nil; return end
    if Aim.char ~= t.ent.char then Aim.char = t.ent.char; Aim.since = os.clock() end
    if (os.clock() - Aim.since) * 1000 >= getNum("aim_react", 120) then aimStep(t, stepAlpha(1 - getNum("aim_smooth", 35) / 100, dt)) end
end

-- FIX SILENT AIM + WEAPON MODS
local Silent = {target = nil, hooked = false, alive = true}
do
    if Cap.hookmetamethod and Cap.getnamecallmethod and Cap.checkcaller then
        local oldNC
        local function hooked(self, ...)
            local method = Cap.getnamecallmethod(); local st = Silent.target
            if Silent.alive and st and not Cap.checkcaller() then
                local n = select("#", ...); local a = {...}
                
                -- Hook Raycasts
                if (self == Workspace or self == Workspace.CurrentCamera) and (method == "Raycast" or method == "ViewportPointToRay" or method == "ScreenPointToRay") then
                    if typeof(a[1]) == "Vector3" then
                        local to = st.pos - a[1]
                        if to.Magnitude > 0.01 then a[2] = to.Unit * math.max(typeof(a[2]) == "Vector3" and a[2].Magnitude or 1000, to.Magnitude + 1); return oldNC(self, table.unpack(a, 1, n)) end
                    elseif typeof(a[1]) == "Vector2" then
                        local cam = Workspace.CurrentCamera
                        if cam then local newV = cam:WorldToViewportPoint(st.pos); if newV.Z > 0 then return oldNC(self, newV.X, newV.Y) end end
                    end
                end
                
                -- Hook FindPartOnRay
                if (method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist") and typeof(a[1]) == "Ray" then
                    local to = st.pos - a[1].Origin
                    if to.Magnitude > 0.01 then a[1] = Ray.new(a[1].Origin, to.Unit * math.max(a[1].Direction.Magnitude, to.Magnitude + 1)); return oldNC(self, table.unpack(a, 1, n)) end
                end
                
                -- Hook Remotes (FireServer) para substituir partes do corpo atingidas
                if (method == "FireServer" or method == "InvokeServer") and self:IsA("RemoteEvent") then
                    for i, arg in ipairs(a) do
                        if typeof(arg) == "Instance" and arg:IsA("BasePart") then
                            if Players:GetPlayerFromCharacter(arg.Parent) ~= LP then
                                a[i] = st.char:FindFirstChild("Head") or st.char:FindFirstChild("UpperTorso") or st.char
                            end
                        elseif typeof(arg) == "CFrame" then
                            a[i] = CFrame.lookAt(arg.Position, st.pos)
                        elseif typeof(arg) == "Vector3" then
                            local cam = Workspace.CurrentCamera
                            if cam then a[i] = (st.pos - cam.CFrame.Position).Unit end
                        end
                    end
                    return oldNC(self, table.unpack(a, 1, n))
                end
            end
            return oldNC(self, ...)
        end
        local ok = pcall(function() oldNC = Cap.hookmetamethod(game, "__namecall", Cap.newcclosure and Cap.newcclosure(hooked) or hooked) end); Silent.hooked = ok and oldNC ~= nil
    end
    
    -- Hook Mouse
    local oldMouseIndex
    local function mouseHook(self, key) 
        if Silent.alive and Silent.target and not Cap.checkcaller() then 
            if key == "Hit" then return CFrame.new(Silent.target.pos) end
            if key == "Target" then return Silent.target.char end
            if key == "UnitRay" then local cam = Workspace.CurrentCamera; if cam then return Ray.new(cam.CFrame.Position, (Silent.target.pos - cam.CFrame.Position).Unit) end end
        end
        return oldMouseIndex(self, key) 
    end
    local mouse = LP:GetMouse()
    if Cap.hookmetamethod and mouse then pcall(function() oldMouseIndex = Cap.hookmetamethod(mouse, "__index", Cap.newcclosure and Cap.newcclosure(mouseHook) or mouseHook) end) end
    
    -- Hook Camera CFrame (caso o jogo use Camera.CFrame para calcular tiro)
    local oldCamIndex
    local function camHook(self, key)
        if Silent.alive and Silent.target and not Cap.checkcaller() and self == Workspace.CurrentCamera then
            if key == "CFrame" then
                local oldCF = oldCamIndex(self, key)
                return CFrame.lookAt(oldCF.Position, Silent.target.pos)
            end
        end
        return oldCamIndex(self, key)
    end
    if Cap.hookmetamethod and Workspace.CurrentCamera then
        pcall(function() oldCamIndex = Cap.hookmetamethod(Workspace.CurrentCamera, "__index", Cap.newcclosure and Cap.newcclosure(camHook) or camHook) end)
    end
end

local function runSilent(cam, dt)
    Silent.target = nil; if not (get("sil_on") and bindActive("sil_key")) then return end
    local any = get("sil_any", false); local bone = ({Head = "Head", Torso = "Torso", Root = "Root"})[get("sil_bone", "Head")] or "Head"
    local t = pickTarget({part = bone, radius = any and math.huge or getNum("sil_fov", 120), maxDist = 2000, wall = get("sil_vis", false), prio = any and "Distance" or "Cursor", wc = 1, wd = 0, wf = 0, offscreen = any, predict = false, sample = 90, jitter = 0, teamCheck = get("sil_team", true)})
    if not t then return end; Silent.target = {pos = t.pos, char = t.ent.char}
    if not Silent.hooked then aimStep(t, stepAlpha(1 / math.max(getNum("sil_smooth", 5), 1), dt)) end
end

-- FIX WEAPON MODS (Munição, Recoil, Rapid Fire Genérico)
local function weaponPatchTick()
    local char = LP.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    if not tool then return end
    
    if get("wpn_rapid") then
        tool.CanBeDropped = false
    end
    
    if get("wpn_ammo") or get("wpn_reload") then
        for _, obj in ipairs(tool:GetDescendants()) do
            if obj:IsA("IntValue") or obj:IsA("NumberValue") then
                local n = obj.Name:lower()
                if n:find("ammo") or n:find("mag") or n:find("clip") then
                    if get("wpn_reload") then obj.Value = math.huge end
                    if get("wpn_ammo") then obj.Value = math.huge end
                end
            end
        end
    end
    
    if get("wpn_recoil") or get("wpn_spread") then
        -- Recoil e Spread genéricos são tratados via hook na câmera e no Mouse.Hit
        -- O código do Silent Aim acima já corrige o spread forçando o Mouse.Hit no centro.
    end
end

local Rage, Kill = {last = 0}, {last = 0}
local function runRage(cam, dt)
    if not (get("rage_on") and bindActive("rage_key")) then return end
    local t = pickTarget({part = "Head", radius = getNum("rage_fovsize", 720), maxDist = 5000, angle = getNum("rage_fov", 120), wall = not get("rage_wall", false), prio = "Cursor", wc = 1, wd = 0, wf = 0, offscreen = true, predict = false, sample = 100, jitter = 0, teamCheck = get("rage_team", true)})
    if not t then return end; aimStep(t, stepAlpha(0.5, dt))
    if bindActive("rage_autoshoot") and t.cursor < 25 then local gap = get("wpn_rapid") and 0.03 or 0.08; if os.clock() - Rage.last > gap then Rage.last = os.clock(); clickFire() end end
end
local function runKillAll(cam, dt)
    if not (get("ra_kill") and bindActive("ra_kill_key")) then return end; initNPCs()
    local myhrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"); local best, bd
    for _, e in ipairs(entities()) do if e.enemy then local d = (e.hrp.Position - (myhrp and myhrp.Position or cam.CFrame.Position)).Magnitude; if not bd or d < bd then best, bd = e, d end end end
    if not best then return end; local head = best.char:FindFirstChild("Head") or best.hrp
    if not get("ra_kill_gun", true) and myhrp then myhrp.CFrame = CFrame.lookAt(best.hrp.Position - best.hrp.CFrame.LookVector * 3, best.hrp.Position) end
    cam.CFrame = CFrame.new(cam.CFrame.Position, head.Position)
    if os.clock() - Kill.last > 0.05 then Kill.last = os.clock(); if get("ra_kill_gun", true) then clickFire() else activateTool(); clickFire() end end
end

local Trig = {since = nil, last = 0}
local function zoneOK(part, zone) if zone == "Whole body" then return true end; local n = part.Name; if zone == "Head" then return n == "Head" end; return not (n:find("Leg") or n:find("Foot") or n == "LowerTorso") end
local function entityFromPart(part) local m = part; while m and m ~= Workspace do local e = EntCache.byChar[m]; if e then return e end; m = m.Parent end; return nil end
local function runTrigger(cam, dt)
    if not (get("trg_on") and bindActive("trg_key")) then Trig.since = nil; return end; entities()
    local maxD, zone, teamOn = getNum("trg_dist", 1000), get("trg_zone", "Whole body"), get("trg_team", true); local hitDist; local vs = cam.ViewportSize
    if get("trg_fovonly") then
        local center, rad = Vector2.new(vs.X / 2, vs.Y / 2), getNum("sil_fov", 120); local which = (zone == "Head") and "Head" or (zone == "Upper body" and "Torso" or "Root")
        for _, e in ipairs(EntCache.list) do if not e.npc and ((not teamOn) or e.enemy) then local part = getPart(e.char, which); if part then local v, on = cam:WorldToViewportPoint(part.Position); local d = (part.Position - cam.CFrame.Position).Magnitude; if on and d <= maxD and (Vector2.new(v.X, v.Y) - center).Magnitude <= rad then hitDist = d; break end end end end
    else
        local m = UserInputService:GetMouseLocation(); local ray = cam:ScreenPointToRay(m.X, m.Y); setFilter(nil)
        local res = Workspace:Raycast(ray.Origin, ray.Direction * maxD, RayP)
        if res then local e = entityFromPart(res.Instance); if e and not e.npc and ((not teamOn) or e.enemy) and zoneOK(res.Instance, zone) then hitDist = res.Distance end end
    end
    if not hitDist then Trig.since = nil; return end; local now = os.clock(); if not Trig.since then Trig.since = now end
    local react = getNum("trg_react", 60); if get("trg_autoreact") then react = react * (0.5 + hitDist / math.max(maxD, 1)) end
    if (now - Trig.since) * 1000 < react then return end; if (now - Trig.last) * 1000 < getNum("trg_delay", 50) then return end; Trig.last = now
    local chance = getNum("trg_chance", 100); if get("trg_autochance") then chance = chance * math.clamp(1.1 - 0.6 * hitDist / math.max(maxD, 1), 0.3, 1) end
    if math.random() * 100 > chance then return end; if get("trg_gun", true) then clickFire() else activateTool() end
end

local ESP, BONES15, BONES6, EDGES = {}, {{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"}}, {{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"}}, {{1,2},{3,4},{5,6},{7,8},{1,3},{2,4},{5,7},{6,8},{1,5},{2,6},{3,7},{4,8}}
local function mk(e, cls, props) local i = new(cls, props, Overlay); e.All[#e.All + 1] = i; return i end
local function lineAt(e, list, i) local l = list[i]; if not l then l = mk(e, "Frame", {AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, Visible = false}); list[i] = l end; return l end
local function drawLine(l, a, b, thick, color, transp, z) local d = b - a; l.Size = UDim2.fromOffset(d.Magnitude, thick); l.Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2); l.Rotation = math.deg(math.atan2(d.Y, d.X)); l.BackgroundColor3 = color; l.BackgroundTransparency = transp; l.ZIndex = z or 1; l.Visible = true end
local function hideList(list, from) for i = from or 1, #list do list[i].Visible = false end end
local function destroyESP(e) for _, i in ipairs(e.All) do pcall(function() i:Destroy() end) end end
local function makeESP()
    local e = {All = {}, Born = os.clock(), Box = {}, Bones = {}, Tr = {}, Pa = {}, Ghost = 1}
    e.Outline = mk(e, "Frame", {BackgroundTransparency = 1, Visible = false}); e.OutStroke = new("UIStroke", {ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = Color3.new(0, 0, 0), Thickness = 3}, e.Outline); e.OutCorner = new("UICorner", {}, e.Outline)
    e.Fill = mk(e, "Frame", {BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false}); e.Stroke = new("UIStroke", {ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Thickness = 1, Color = Theme.accent}, e.Fill); e.Corner = new("UICorner", {}, e.Fill)
    e.HpBack = mk(e, "Frame", {BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, BorderSizePixel = 0, Visible = false}); e.HpGhost = mk(e, "Frame", {BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 1), Visible = false}); e.HpFill = mk(e, "Frame", {BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 1), Visible = false})
    e.HpText = mk(e, "TextLabel", {BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = Color3.new(1, 1, 1), TextStrokeTransparency = 0.5, AnchorPoint = Vector2.new(1, 0.5), Size = UDim2.fromOffset(30, 12), TextXAlignment = Enum.TextXAlignment.Right, Visible = false})
    e.Name = mk(e, "TextLabel", {BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.fromOffset(0, 0), Font = Enum.Font.GothamBold, TextStrokeTransparency = 0.5, AnchorPoint = Vector2.new(0.5, 1), Visible = false}); new("UICorner", {CornerRadius = UDim.new(0, 6)}, e.Name); new("UIPadding", {PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 1), PaddingBottom = UDim.new(0, 1)}, e.Name)
    e.Info = mk(e, "TextLabel", {BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.fromOffset(0, 0), Font = Enum.Font.Gotham, TextColor3 = Color3.new(1, 1, 1), TextStrokeTransparency = 0.5, AnchorPoint = Vector2.new(0.5, 0), Visible = false})
    e.HeadDot = mk(e, "Frame", {Size = UDim2.fromOffset(6, 6), AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, Visible = false}); new("UICorner", {CornerRadius = UDim.new(1, 0)}, e.HeadDot)
    e.Highlight = mk(e, "Highlight", {FillTransparency = 0.6, Enabled = false}); return e
end
local function hideESP(e) e.Outline.Visible = false; e.Fill.Visible = false; e.HpBack.Visible = false; e.HpGhost.Visible = false; e.HpFill.Visible = false; e.HpText.Visible = false; e.Name.Visible = false; e.Info.Visible = false; e.HeadDot.Visible = false; hideList(e.Box); hideList(e.Bones); hideList(e.Tr); hideList(e.Pa) end
local function espColor(ent) if get("esp_rainbow") then return Color3.fromHSV((os.clock() * 0.2) % 1, 0.8, 1) end; if get("esp_teamcolor") and ent.plr and ent.plr.Team then return ent.plr.TeamColor.Color end; return Color3.fromHSV(math.clamp(getNum("esp_hue", 99), 0, 100) / 100, 0.85, 1) end
local function spawnDamage(amount, x, y, color) local l = new("TextLabel", {BackgroundTransparency = 1, Text = "-" .. tostring(amount), Font = Enum.Font.GothamBlack, TextSize = 16, TextColor3 = color, TextStrokeTransparency = 0.3, AnchorPoint = Vector2.new(0.5, 1), Size = UDim2.fromOffset(60, 18), Position = UDim2.fromOffset(x, y)}, Overlay); TweenService:Create(l, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(x, y - 40), TextTransparency = 1, TextStrokeTransparency = 1}):Play(); Debris:AddItem(l, 0.9) end

local function drawEntity(ent, e, cam, dt, now, dist, color, lite, maxD, vs, hlOK, espOK)
    local hrp, hum = ent.hrp, ent.hum; local fadeMul = 1; if get("esp_fade") then fadeMul = fadeMul * math.clamp(1 - 0.65 * dist / math.max(maxD, 1), 0.25, 1) end; if get("esp_intro") then fadeMul = fadeMul * math.clamp((now - e.Born) / 0.35, 0, 1) end
    local function tr(base) return 1 - (1 - base) * fadeMul end
    if not espOK then hideESP(e); local tp, on = cam:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0)); if on then e.Name.Text = ent.name; e.Name.TextSize = getNum("esp_namesize", 14); e.Name.TextColor3 = color; e.Name.TextTransparency = tr(0); e.Name.BackgroundTransparency = 1; e.Name.Position = UDim2.fromOffset(tp.X, tp.Y - 3); e.Name.Visible = true end; return end
    local sp, onScreen = cam:WorldToViewportPoint(hrp.Position); if not onScreen then hideESP(e); return end
    local top = cam:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0)); local bot = cam:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
    local h = math.abs(top.Y - bot.Y); local w = h * 0.65; local cx, cy = sp.X, (top.Y + bot.Y) / 2; local sm = getNum("esp_smooth", 25)
    if not e.cx or sm <= 0 then e.cx, e.cy, e.w, e.h = cx, cy, w, h else local a = math.clamp(1 - sm / 100, 0.05, 1); e.cx = e.cx + (cx - e.cx) * a; e.cy = e.cy + (cy - e.cy) * a; e.w = e.w + (w - e.w) * a; e.h = e.h + (h - e.h) * a end
    local x0, y0, x1, y1 = e.cx - e.w / 2, e.cy - e.h / 2, e.cx + e.w / 2, e.cy + e.h / 2
    local style = lite and "Full" or get("esp_style", "Corners"); local thick = getNum("esp_thick", 2); local fillA = getNum("esp_fill", 50) / 100
    if get("esp_box") then
        if style == "3D" then
            e.Fill.Visible = false; e.Outline.Visible = false; local cf, pts, okAll = hrp.CFrame, {}, true
            for i = 0, 7 do local off = Vector3.new((i % 2 == 0) and -2 or 2, (math.floor(i / 2) % 2 == 0) and -3 or 3, (math.floor(i / 4) % 2 == 0) and -1 or 1); local v = cam:WorldToViewportPoint(cf:PointToWorldSpace(off)); if v.Z <= 0 then okAll = false end; pts[i + 1] = Vector2.new(v.X, v.Y) end
            if okAll then for i, ed in ipairs(EDGES) do drawLine(lineAt(e, e.Box, i), pts[ed[1]], pts[ed[2]], thick, color, tr(0), 2) end; hideList(e.Box, #EDGES + 1) else hideList(e.Box) end
        elseif style == "Corners" then
            e.Outline.Visible = false; e.Stroke.Enabled = false; e.Corner.CornerRadius = UDim.new(0, 0); e.Fill.Position = UDim2.fromOffset(x0, y0); e.Fill.Size = UDim2.fromOffset(e.w, e.h); e.Fill.BackgroundColor3 = color; e.Fill.BackgroundTransparency = tr(1 - fillA); e.Fill.Visible = fillA > 0
            local len = math.min(e.w, e.h) * 0.28; local segs = {{x0,y0,x0+len,y0},{x0,y0,x0,y0+len},{x1-len,y0,x1,y0},{x1,y0,x1,y0+len},{x0,y1,x0+len,y1},{x0,y1-len,x0,y1},{x1-len,y1,x1,y1},{x1,y1-len,x1,y1}}; local n = 0
            if get("esp_outline") then for i, s in ipairs(segs) do drawLine(lineAt(e, e.Box, i), Vector2.new(s[1], s[2]), Vector2.new(s[3], s[4]), thick + 2, Color3.new(0, 0, 0), tr(0.2), 1) end; n = 8 end
            for i, s in ipairs(segs) do drawLine(lineAt(e, e.Box, n + i), Vector2.new(s[1], s[2]), Vector2.new(s[3], s[4]), thick, color, tr(0), 2) end; hideList(e.Box, n + 9)
        else
            hideList(e.Box); local r = (style == "Rounded") and getNum("esp_round", 6) or 0; e.Fill.Position = UDim2.fromOffset(x0, y0); e.Fill.Size = UDim2.fromOffset(e.w, e.h); e.Fill.BackgroundColor3 = color; e.Fill.BackgroundTransparency = tr(1 - fillA); e.Fill.Visible = true; e.Corner.CornerRadius = UDim.new(0, r); e.Stroke.Enabled = true; e.Stroke.Color = color; e.Stroke.Thickness = thick; e.Stroke.Transparency = tr(0)
            if get("esp_outline") then e.Outline.Position = UDim2.fromOffset(x0, y0); e.Outline.Size = UDim2.fromOffset(e.w, e.h); e.OutCorner.CornerRadius = UDim.new(0, r); e.OutStroke.Thickness = thick + 2; e.OutStroke.Transparency = tr(0.2); e.Outline.Visible = true else e.Outline.Visible = false end
        end
    else e.Fill.Visible = false; e.Outline.Visible = false; hideList(e.Box) end
    local frac = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
    if get("esp_health") then
        local bw = getNum("esp_hpwidth", 4); local bx = x0 - bw - 3; e.HpBack.Position = UDim2.fromOffset(bx, y0); e.HpBack.Size = UDim2.fromOffset(bw, e.h); e.HpBack.Visible = true; e.HpFill.Position = UDim2.fromOffset(bx, y1); e.HpFill.Size = UDim2.fromOffset(bw, e.h * frac); e.HpFill.BackgroundColor3 = Color3.fromRGB(255, 50, 50):Lerp(Color3.fromRGB(80, 255, 80), frac); e.HpFill.BackgroundTransparency = tr(0); e.HpFill.Visible = true
        if get("esp_ghost") and not lite then if e.Ghost > frac then e.Ghost = math.max(frac, e.Ghost - dt * 0.5) else e.Ghost = frac end; e.HpGhost.Position = UDim2.fromOffset(bx, y1); e.HpGhost.Size = UDim2.fromOffset(bw, e.h * e.Ghost); e.HpGhost.BackgroundTransparency = tr(0.4); e.HpGhost.Visible = true else e.Ghost = frac; e.HpGhost.Visible = false end
        if get("esp_hpval") and not lite then e.HpText.Text = tostring(math.floor(hum.Health + 0.5)); e.HpText.Position = UDim2.fromOffset(bx - 2, y1 - e.h * frac); e.HpText.Visible = true else e.HpText.Visible = false end
    else e.HpBack.Visible = false; e.HpGhost.Visible = false; e.HpFill.Visible = false; e.HpText.Visible = false end
    if e.LastHp and hum.Health < e.LastHp - 0.5 and get("esp_dmgnum") and not lite then spawnDamage(math.floor(e.LastHp - hum.Health + 0.5), e.cx, y0, color) end; e.LastHp = hum.Health
    local nameSize = getNum("esp_namesize", 14)
    if get("esp_name") or (get("hl_name") and hlOK) then e.Name.Text = ent.name; e.Name.TextSize = nameSize; e.Name.TextColor3 = color; e.Name.TextTransparency = tr(0); e.Name.TextStrokeTransparency = tr(0.5); e.Name.BackgroundColor3 = Color3.new(0, 0, 0); e.Name.BackgroundTransparency = (get("esp_pill") and not lite) and tr(0.5) or 1; e.Name.Position = UDim2.fromOffset(e.cx, y0 - 3); e.Name.Visible = true else e.Name.Visible = false end
    local parts = {}; if get("esp_distance") and not lite then parts[#parts + 1] = tostring(math.floor(dist * 0.28 + 0.5)) .. "m" end; if get("esp_wpn") then local t = ent.char:FindFirstChildOfClass("Tool"); if t then parts[#parts + 1] = t.Name end end
    if #parts > 0 then e.Info.Text = table.concat(parts, "  "); e.Info.TextSize = math.max(9, nameSize - 3); e.Info.TextTransparency = tr(0); e.Info.Position = UDim2.fromOffset(e.cx, y1 + 2); e.Info.Visible = true else e.Info.Visible = false end
    if lite then e.HeadDot.Visible = false; hideList(e.Bones); hideList(e.Tr); hideList(e.Pa); return end
    local headPart = ent.char:FindFirstChild("Head")
    if get("esp_head") and headPart then local v, on = cam:WorldToViewportPoint(headPart.Position); e.HeadDot.Visible = on; if on then e.HeadDot.Position = UDim2.fromOffset(v.X, v.Y); e.HeadDot.BackgroundColor3 = color; e.HeadDot.BackgroundTransparency = tr(0) end else e.HeadDot.Visible = false end
    if get("esp_skel") then local bones = ent.char:FindFirstChild("UpperTorso") and BONES15 or BONES6; for i, pair in ipairs(bones) do local a, b = ent.char:FindFirstChild(pair[1]), ent.char:FindFirstChild(pair[2]); local l = lineAt(e, e.Bones, i); if a and b then local va, oa = cam:WorldToViewportPoint(a.Position); local vb, ob = cam:WorldToViewportPoint(b.Position); if oa and ob then drawLine(l, Vector2.new(va.X, va.Y), Vector2.new(vb.X, vb.Y), 1, color, tr(0), 2) else l.Visible = false end else l.Visible = false end end; hideList(e.Bones, #bones + 1) else hideList(e.Bones) end
    if get("esp_tracers") then local o = get("esp_torigin", "Bottom"); local origin; if o == "Center" then origin = Vector2.new(vs.X / 2, vs.Y / 2) elseif o == "Top" then origin = Vector2.new(vs.X / 2, 0) elseif o == "Mouse" then local m = UserInputService:GetMouseLocation(); origin = Vector2.new(m.X, m.Y) else origin = Vector2.new(vs.X / 2, vs.Y) end; drawLine(lineAt(e, e.Tr, 1), origin, Vector2.new(e.cx, y1), 1, color, tr(0.3), 1) else hideList(e.Tr) end
    if get("esp_path") then local vel = velocityOf(ent.char, 100); local fut = hrp.Position + vel * (getNum("esp_ptime", 50) / 10); local v, on = cam:WorldToViewportPoint(fut); if on then drawLine(lineAt(e, e.Pa, 1), Vector2.new(sp.X, sp.Y), Vector2.new(v.X, v.Y), 1, color, tr(0.2), 1) else hideList(e.Pa) end else hideList(e.Pa) end
end

local function renderESP(cam, dt)
    local any = get("esp_on", true) and (get("esp_box") or get("esp_name") or get("esp_skel") or get("esp_wpn") or get("esp_health") or get("esp_distance") or get("esp_head") or get("esp_tracers") or get("esp_path")); local anyHL = get("hl_on")
    if not any and not anyHL then for k, e in pairs(ESP) do destroyESP(e); ESP[k] = nil end; return end; if get("esp_npc") then initNPCs() end
    local now, vs = os.clock(), cam.ViewportSize; local maxD, lite = getNum("esp_dist", 1000), get("esp_render", "Full") == "Lite"; local seen = {}
    for _, ent in ipairs(entities()) do
        if (not ent.npc) or get("esp_npc") then
            local espOK = any and ((not ent.plr) or (not get("esp_team")) or ent.enemy); local hlOK = anyHL and ((not ent.plr) or (not get("hl_team")) or ent.enemy); local dist = (ent.hrp.Position - cam.CFrame.Position).Magnitude
            if (espOK or hlOK) and dist <= maxD then
                seen[ent.char] = true; local e = ESP[ent.char]; if not e then e = makeESP(); ESP[ent.char] = e end; local color = espColor(ent)
                if hlOK then local hc = get("hl_color") and color or Theme.accent; e.Highlight.Adornee = ent.char; e.Highlight.FillColor = hc; e.Highlight.OutlineColor = hc; e.Highlight.Enabled = true else e.Highlight.Enabled = false end
                if espOK or (hlOK and get("hl_name")) then drawEntity(ent, e, cam, dt, now, dist, color, lite, maxD, vs, hlOK, espOK) else hideESP(e) end
            end
        end
    end
    for k, e in pairs(ESP) do if not seen[k] then destroyESP(e); ESP[k] = nil end end
end

local function spawnBulletTracer()
    local cam = Workspace.CurrentCamera; if not cam then return end; local cf = cam.CFrame; local origin = cf.Position + cf.RightVector * 0.6 - cf.UpVector * 0.5 + cf.LookVector * 1.5; setFilter(nil)
    local res = Workspace:Raycast(cf.Position, cf.LookVector * 1000, RayP); local hit = res and res.Position or (cf.Position + cf.LookVector * 1000); local len = (hit - origin).Magnitude; if len < 1 then return end
    local life = getNum("trc_life", 5) * 0.2; local p = Instance.new("Part"); p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.Material = Enum.Material.Neon; p.Color = Theme.accent; p.Transparency = 0.15; p.Size = Vector3.new(getNum("trc_width", 2) * 0.03, getNum("trc_width", 2) * 0.03, len); p.CFrame = CFrame.lookAt(origin, hit) * CFrame.new(0, 0, -len / 2); p.Parent = cam; TweenService:Create(p, TweenInfo.new(life), {Transparency = 1}):Play(); Debris:AddItem(p, life + 0.1)
end

local Hud = {}
do
    Hud.mark = new("Frame", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10), Size = UDim2.fromOffset(0, 22), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = Theme.bg, BackgroundTransparency = 0.1, Visible = false}, Overlay); corner(Hud.mark, 6); outline(Hud.mark, 1, Theme.stroke); new("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)}, Hud.mark); Hud.markText = label(Hud.mark, {Size = UDim2.fromOffset(0, 22), AutomaticSize = Enum.AutomaticSize.X, Text = "", TextSize = 12, Font = Enum.Font.GothamBold})
    Hud.list = new("Frame", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 38), Size = UDim2.fromOffset(0, 0), AutomaticSize = Enum.AutomaticSize.XY, BackgroundTransparency = 1, Visible = false}, Overlay); new("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Right}, Hud.list); Hud.lines = {}
    Hud.spec = new("TextLabel", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.4, 0), Size = UDim2.fromOffset(0, 0), AutomaticSize = Enum.AutomaticSize.XY, BackgroundColor3 = Theme.bg, BackgroundTransparency = 0.15, Text = "", TextSize = 12, Font = Enum.Font.GothamBold, TextColor3 = Theme.text, TextXAlignment = Enum.TextXAlignment.Left, Visible = false}, Overlay); corner(Hud.spec, 6); new("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4)}, Hud.spec)
    Hud.toasts = new("Frame", {AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -14, 1, -14), Size = UDim2.fromOffset(210, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1}, Overlay); new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom}, Hud.toasts); Hud.toastN = 0
    Hud.island = new("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 8), Size = UDim2.fromOffset(150, 28), BackgroundColor3 = Color3.new(0, 0, 0), Visible = false}, Overlay); corner(Hud.island, 14); Hud.islandText = label(Hud.island, {Size = UDim2.fromScale(1, 1), Text = "Drx Hub", TextSize = 12, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Center}); Hud.islandBusy = 0
    Hud.mobile = new("TextButton", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.fromOffset(44, 44), BackgroundColor3 = Theme.panel, Text = "D", Font = Enum.Font.GothamBlack, TextSize = 18, TextColor3 = Theme.accent, AutoButtonColor = false, Visible = false}, Overlay); corner(Hud.mobile, 22); outline(Hud.mobile, 2, Theme.accent); Hud.mobile.MouseButton1Click:Connect(function() GUI.Enabled = not GUI.Enabled end)
    Hud.amb = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.accent, BorderSizePixel = 0, ZIndex = 0, Visible = false}, Overlay); Hud.ambGrad = new("UIGradient", {Rotation = 90}, Hud.amb)
end
notify = function(title, sub)
    if get("set_island") then
        local text = title .. (sub and (": " .. sub) or ""); Hud.islandText.Text = text; local w = TextService:GetTextSize(text, 12, Enum.Font.GothamBold, Vector2.new(600, 30)).X + 30; tween(Hud.island, {Size = UDim2.fromOffset(math.max(w, 150), 28)}); Hud.islandBusy = os.clock() + 2
    else
        Hud.toastN = Hud.toastN + 1; local f = new("Frame", {Size = UDim2.fromOffset(210, 40), BackgroundColor3 = Theme.panel, LayoutOrder = Hud.toastN}, Hud.toasts); corner(f, 8); outline(f, 1, Theme.stroke); new("Frame", {Size = UDim2.fromOffset(3, 24), Position = UDim2.fromOffset(8, 8), BackgroundColor3 = Theme.accent, BorderSizePixel = 0}, f); label(f, {Size = UDim2.new(1, -24, 0, 18), Position = UDim2.fromOffset(18, 4), Text = title, TextSize = 12, Font = Enum.Font.GothamBold}); label(f, {Size = UDim2.new(1, -24, 0, 14), Position = UDim2.fromOffset(18, 22), Text = sub or "", TextSize = 11, TextColor3 = Theme.sub}); Debris:AddItem(f, 2.2)
    end
end

local function updateHud(fps)
    Hud.mark.Visible = get("set_watermark", true) and true or false; if Hud.mark.Visible then Hud.markText.Text = string.format("Drx Hub  |  %d fps  |  %d players  |  %s", math.floor(fps + 0.5), #Players:GetPlayers(), os.date("%H:%M")) end
    local showList = get("set_qaccess") and true or false; Hud.list.Visible = showList
    if showList then
        local n = 0; for _, ft in ipairs(Features) do if ft.on() then n = n + 1; local l = Hud.lines[n]; if not l then l = label(Hud.list, {Size = UDim2.fromOffset(0, 14), AutomaticSize = Enum.AutomaticSize.X, Text = "", TextSize = 11, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Right, LayoutOrder = n}); Hud.lines[n] = l end; local txt = ft.name; if ft.bind and Prefs[ft.bind] then local b = Prefs[ft.bind]; if b.Mode ~= "Always" then txt = txt .. "  [" .. tostring(b.Key) .. "]" end; if bindActive(ft.bind) then txt = txt .. "  ENABLED" end end; l.Text = txt; l.LayoutOrder = n; l.Visible = true end end; for i = n + 1, #Hud.lines do Hud.lines[i].Visible = false end
    end
    Hud.island.Visible = get("set_island") and true or false; if Hud.island.Visible and os.clock() > Hud.islandBusy then local n = 0; for _, ft in ipairs(Features) do if ft.on() then n = n + 1 end end; Hud.islandText.Text = "Drx Hub  |  " .. tostring(n) .. " active"; tween(Hud.island, {Size = UDim2.fromOffset(150, 28)}) end
    Hud.mobile.Visible = get("set_mobile") and true or false; local op = getNum("set_opacity", 50) / 100; local t = 1 - op * 0.45; Hud.ambGrad.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, t), NumberSequenceKeypoint.new(0.3, 1), NumberSequenceKeypoint.new(0.7, 1), NumberSequenceKeypoint.new(1, t)}); Hud.amb.Visible = (not get("set_showonly")) or GUI.Enabled
end
local Features = {}
do
    local function esp_any() return get("esp_on", true) and (get("esp_box") or get("esp_name") or get("esp_skel") or get("esp_wpn") or get("esp_health") or get("esp_distance") or get("esp_head") or get("esp_tracers") or get("esp_path")) end
    local function f(name, fn, bind) Features[#Features + 1] = {name = name, on = fn, bind = bind} end
    f("Aimbot", function() return get("aim_on") end, "aim_key"); f("Silent Aim", function() return get("sil_on") end, "sil_key"); f("Triggerbot", function() return get("trg_on") end, "trg_key"); f("Ragebot", function() return get("rage_on") end, "rage_key"); f("Kill All", function() return get("ra_kill") end, "ra_kill_key"); f("Speed", function() return get("mv_speed") end, "mv_speed_key"); f("Fly", function() return get("mv_fly") end, "mv_fly_key"); f("Third Person", function() return get("cam_third") end, "cam_key"); f("Bhop", function() return get("misc_bhop") end); f("ESP", esp_any); f("Anti AFK", function() return get("misc_afk") end); f("No Recoil", function() return get("wpn_recoil") end); f("Instant Reload", function() return get("wpn_reload") end); f("Infinite Magazine", function() return get("wpn_ammo") end); f("Custom Fire Cooldown", function() return get("wpn_cd") end)
end

local HB = {slow = 0, mid = 0, hud = 0, boost = 0, lastHop = 0, tp = false, respawn = 0, bv = nil, paused = false, jump = setmetatable({}, {__mode = "k"}), vim = nil}
local fpsAvg = 60
local function stopFly() if HB.bv then pcall(function() HB.bv:Destroy() end); HB.bv = nil end end
local function onHeartbeat(dt)
    local char = LP.Character; local hum = char and char:FindFirstChildOfClass("Humanoid"); local hrp = char and char:FindFirstChild("HumanoidRootPart"); local cam = Workspace.CurrentCamera
    HB.slow = HB.slow + dt; HB.mid = HB.mid + dt; HB.hud = HB.hud + dt
    if get("ply_respawn") and (not hum or hum.Health <= 0) and os.clock() - HB.respawn > 0.3 then HB.respawn = os.clock(); pcall(function() HB.vim = HB.vim or game:GetService("VirtualInputManager"); HB.vim:SendKeyEvent(true, Enum.KeyCode.Space, false, game); task.delay(0.05, function() pcall(function() HB.vim:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end) end) end) end
    if hum and hrp and hum.Health > 0 and cam then
        local b = HB.jump[hum]; if not b then b = {jp = hum.JumpPower, jh = hum.JumpHeight}; HB.jump[hum] = b end; local typing = UserInputService:GetFocusedTextBox() ~= nil
        if not HB.paused then
            if get("bh_fatigue") then if hum.UseJumpPower then if hum.JumpPower < b.jp then hum.JumpPower = b.jp end elseif hum.JumpHeight < b.jh then hum.JumpHeight = b.jh end end
            if get("mv_speed") and bindActive("mv_speed_key") and hum.MoveDirection.Magnitude > 0.1 then hrp.CFrame = hrp.CFrame + hum.MoveDirection * getNum("mv_extra", 6) * dt end
            if get("misc_bhop") and (not typing) and UserInputService:IsKeyDown(Enum.KeyCode.Space) then if hum.FloorMaterial ~= Enum.Material.Air and os.clock() - HB.lastHop > 0.15 then HB.lastHop = os.clock(); hum.Jump = true; hum:ChangeState(Enum.HumanoidStateType.Jumping); HB.boost = math.min(HB.boost + getNum("bh_inc", 2), math.max(getNum("bh_max", 32) - hum.WalkSpeed, 0)) end; if hum.MoveDirection.Magnitude > 0.1 then hrp.CFrame = hrp.CFrame + hum.MoveDirection * HB.boost * dt end else HB.boost = 0 end
            if get("mv_fly") and bindActive("mv_fly_key") then
                if not HB.bv or HB.bv.Parent ~= hrp then stopFly(); local bv = Instance.new("BodyVelocity"); bv.Name = "DrxFly"; bv.MaxForce = Vector3.new(1e9, 1e9, 1e9); bv.Velocity = Vector3.new(0, 0, 0); bv.Parent = hrp; HB.bv = bv end
                local dir = Vector3.new(0, 0, 0); if not typing then local U, cf = UserInputService, cam.CFrame; if U:IsKeyDown(Enum.KeyCode.W) then dir = dir + cf.LookVector end; if U:IsKeyDown(Enum.KeyCode.S) then dir = dir - cf.LookVector end; if U:IsKeyDown(Enum.KeyCode.D) then dir = dir + cf.RightVector end; if U:IsKeyDown(Enum.KeyCode.A) then dir = dir - cf.RightVector end; if U:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end; if U:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end end
                HB.bv.Velocity = (dir.Magnitude > 0) and dir.Unit * getNum("mv_flyspeed", 60) or Vector3.new(0, 0, 0)
            else stopFly() end
        else stopFly() end
    else stopFly() end
    if HB.mid >= 0.1 then HB.mid = 0; local active = get("cam_third") and bindActive("cam_key"); if active then local d = getNum("cam_dist", 12); LP.CameraMode = Enum.CameraMode.Classic; LP.CameraMaxZoomDistance = d; LP.CameraMinZoomDistance = d; HB.tp = true elseif HB.tp then HB.tp = false; LP.CameraMaxZoomDistance = 128; LP.CameraMinZoomDistance = 0.5 end end
    if HB.slow >= 0.5 then HB.slow = 0; weaponPatchTick(); local want = get("misc_spect") or get("misc_antispect"); local specs = want and currentSpectators() or {}; if get("misc_spect") and #specs > 0 then Hud.spec.Text = "Spectators\n" .. table.concat(specs, "\n"); Hud.spec.Visible = true else Hud.spec.Visible = false end; local pause = get("misc_antispect") and #specs > 0; if pause ~= HB.paused then HB.paused = pause; notify("Anti Spectate", pause and "features paused" or "features resumed") end end
    if HB.hud >= 0.2 then HB.hud = 0; updateHud(fpsAvg) end
end

local function makeCircle() local f = new("Frame", {Size = UDim2.fromOffset(100, 100), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Visible = false}, Overlay); new("UICorner", {CornerRadius = UDim.new(1, 0)}, f); new("UIStroke", {Thickness = 1, Color = Theme.accent}, f); return f end
local fovCircle, aimCircle = makeCircle(), makeCircle()
local silMark = new("Frame", {Size = UDim2.fromOffset(10, 10), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Theme.accent, Visible = false}, Overlay); corner(silMark, 5)
local function updateCircles(cam) local vs = cam.ViewportSize; local c = UDim2.fromOffset(vs.X / 2, vs.Y / 2); local show = get("sil_fovcircle"); local sOn = show and get("sil_on") and not get("sil_any"); fovCircle.Visible = sOn and true or false; if sOn then local d = getNum("sil_fov", 120) * 2; fovCircle.Position = c; fovCircle.Size = UDim2.fromOffset(d, d) end; local aOn = show and get("aim_on"); aimCircle.Visible = aOn and true or false; if aOn then local d = getNum("aim_radius", 120) * 2; aimCircle.Position = c; aimCircle.Size = UDim2.fromOffset(d, d) end; if get("sil_show") and Silent.target then local v, on = cam:WorldToViewportPoint(Silent.target.pos); silMark.Visible = on; if on then silMark.Position = UDim2.fromOffset(v.X, v.Y) end else silMark.Visible = false end end

local function currentSpectators() local probe, out = GameConfig.SpectateProbe or function(plr) local function refs(v) return v == LP or v == LP.Character or v == LP.Name or v == LP.DisplayName or v == LP.UserId end; for k, v in pairs(plr:GetAttributes()) do if tostring(k):lower():find("spect") and refs(v) then return true end end; for _, d in ipairs(plr:GetDescendants()) do if (d:IsA("ObjectValue") or d:IsA("StringValue") or d:IsA("IntValue")) and d.Name:lower():find("spect") and refs(d.Value) then return true end end; return false end, {}; for _, plr in ipairs(Players:GetPlayers()) do if plr ~= LP then local ok, r = pcall(probe, plr); if ok and r then out[#out + 1] = plr.Name end end end; return out end

local gPoll, gTrack, gCircles, gAim, gSilent, gRage, gKill, gTrig, gESP = guard("binds", pollBinds), guard("track", trackEntities), guard("circles", updateCircles), guard("aimbot", runAimbot), guard("silent", runSilent), guard("ragebot", runRage), guard("killall", runKillAll), guard("trigger", runTrigger), guard("esp", renderESP)
local gHB = guard("heartbeat", onHeartbeat)
local rapidLast, bulletLast = 0, 0
local gRapid = guard("rapid", function() if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then return end; if UserInputService:GetFocusedTextBox() or GUI.Enabled then return end; local now = os.clock(); if get("wpn_rapid") and now - rapidLast > 0.04 then rapidLast = now; clickFire() end; if get("trc_on") and now - bulletLast > 0.1 then bulletLast = now; spawnBulletTracer() end end)

pcall(function() RunService:UnbindFromRenderStep("DrxMain") end)
RunService:BindToRenderStep("DrxMain", Enum.RenderPriority.Camera.Value + 1, function(dt) FrameNo = FrameNo + 1; fpsAvg = fpsAvg + (1 / math.max(dt, 1e-4) - fpsAvg) * 0.05; gPoll(); local cam = Workspace.CurrentCamera; if not cam then return end; gTrack(); gCircles(cam); if HB.paused then Silent.target = nil else gAim(cam, dt); gSilent(cam, dt); gRage(cam, dt); gKill(cam, dt); gTrig(cam, dt) end; gESP(cam, dt); gRapid() end)
Conns[#Conns + 1] = RunService.Heartbeat:Connect(function(dt) gHB(dt) end)
Conns[#Conns + 1] = LP.Idled:Connect(function() if get("misc_afk") then pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end) end end)

local dragging, dragStart, startPos = false, nil, nil
local function menuMatch(input, mk) return (input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == mk.Key) or (input.UserInputType == Enum.UserInputType.MouseButton1 and mk.Key == "LMB") or (input.UserInputType == Enum.UserInputType.MouseButton2 and mk.Key == "RMB") or (input.UserInputType == Enum.UserInputType.MouseButton3 and mk.Key == "MMB") end
Conns[#Conns + 1] = UserInputService.InputBegan:Connect(function(input, processed) if input.UserInputType == Enum.UserInputType.MouseButton1 and (not processed) and get("trc_on") and not GUI.Enabled then bulletLast = os.clock(); pcall(spawnBulletTracer) end; if processed then return end; local mk = get("misc_menukey", {Key = "RightShift", Mode = "Toggle"}); local match = menuMatch(input, mk); if mk.Mode == "Toggle" and match then GUI.Enabled = not GUI.Enabled elseif mk.Mode == "Hold" and match then GUI.Enabled = true end end)
Conns[#Conns + 1] = UserInputService.InputEnded:Connect(function(input) local mk = get("misc_menukey", {Key = "RightShift", Mode = "Toggle"}); if mk.Mode == "Hold" and menuMatch(input, mk) then GUI.Enabled = false end; if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false; activeSlider = nil end end)
TopBar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; dragStart = input.Position; startPos = Main.Position end end)
Conns[#Conns + 1] = UserInputService.InputChanged:Connect(function(input) if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then local d = input.Position - dragStart; Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y) end; if activeSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then if activeSlider.track and activeSlider.track.Parent then local pct = math.clamp((input.Position.X - activeSlider.track.AbsolutePosition.X) / math.max(activeSlider.track.AbsoluteSize.X, 1), 0, 1); activeSlider.update(pct) else activeSlider = nil end end end)

local cleaned = false
local function cleanup()
    if cleaned then return end; cleaned = true; if shared.DrxCleanup == cleanup then shared.DrxCleanup = nil end; Silent.alive = false; Silent.target = nil; pcall(function() RunService:UnbindFromRenderStep("DrxMain") end); for _, c in ipairs(Conns) do pcall(function() c:Disconnect() end) end; UiMouse.setOpen(false); UiMouse.alive = false; stopFly(); for k, e in pairs(ESP) do destroyESP(e); ESP[k] = nil end; if HB.tp then pcall(function() LP.CameraMaxZoomDistance = 128; LP.CameraMinZoomDistance = 0.5 end) end; Overlay:Destroy(); if GUI.Parent then GUI:Destroy() end
end
shared.DrxCleanup = cleanup
GUI.Destroying:Connect(cleanup)
UiMouse.setOpen(GUI.Enabled)
Booted = true
print("[Drx Hub V22] pronto | silent-hook=" .. tostring(Silent.hooked) .. " | Build=" .. GameConfig.Build)
