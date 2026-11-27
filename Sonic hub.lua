-- Eclypse V27 (base: Eclypse V26) | tela de carregamento, cartao Finalsher/Discord, fundo preto configuravel, correcoes de desempenho (mouse do menu, HUD, profiler)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local Debris = game:GetService("Debris")
local TextService = game:GetService("TextService")
local GuiService = game:GetService("GuiService")
local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")

if shared.DrxCleanup then pcall(shared.DrxCleanup) end
for _, n in ipairs({"DrxHub", "DrxOverlay", "DrxMouseModal", "EclypseLoading"}) do
    local a = PlayerGui:FindFirstChild(n); if a then a:Destroy() end
    local b = game:GetService("CoreGui"):FindFirstChild(n); if b then b:Destroy() end
end

local Prefs, Labels, BindNames, Conns, Warned = {}, {}, {}, {}, {}
local Booted, notify = false, nil
local EX = {perfLast = {}}
local function set(k, v)
    local old = Prefs[k]; Prefs[k] = v
    if Booted and type(v) == "boolean" and old ~= v and Labels[k] then notify(Labels[k], v and "enabled" or "disabled") end
    if old ~= v and EX.prefHook then EX.prefHook(k) end
end
local function get(k, d) local v = Prefs[k]; if v == nil then return d end; return v end
local function getNum(k, d) local v = tonumber(get(k, d)); if not v or v ~= v then return d end; return v end

local Theme = {
    bg = Color3.fromRGB(0, 0, 0), panel = Color3.fromRGB(10, 10, 10), card = Color3.fromRGB(18, 18, 18),
    text = Color3.fromRGB(255, 255, 255), sub = Color3.fromRGB(150, 150, 160), accent = Color3.fromRGB(255, 40, 60),
    stroke = Color3.fromRGB(44, 44, 44), track = Color3.fromRGB(32, 32, 32),
}
EX.Brand = {name = "Eclypse", author = "Finalsher", discord = "discord.gg/YyV2WkWTKc", invite = "https://discord.gg/YyV2WkWTKc"}
EX.Palette = {bg = Theme.bg, panel = Theme.panel, card = Theme.card, track = Theme.track, stroke = Theme.stroke}
EX.Themed = setmetatable({}, {__mode = "k"})
function EX.roleOf(c) for role, col in pairs(EX.Palette) do if col == c then return role end end end
local function new(cls, props, parent)
    local i = Instance.new(cls); for k, v in pairs(props) do i[k] = v end
    local c = props.BackgroundColor3; if c then local r = EX.roleOf(c); if r then EX.Themed[i] = {prop = "BackgroundColor3", role = r} end end
    if cls == "UIStroke" and props.Color then local r = EX.roleOf(props.Color); if r then EX.Themed[i] = {prop = "Color", role = r} end end
    if parent then i.Parent = parent end; return i
end
-- cor de fundo configuravel (Configuracoes): recalcula a paleta e recolore so o que ainda esta na cor antiga do seu papel
function EX.derive(r, g, b)
    local function up(d) return Color3.fromRGB(math.clamp(r + d, 0, 255), math.clamp(g + d, 0, 255), math.clamp(b + d, 0, 255)) end
    return {bg = up(0), panel = up(10), card = up(18), track = up(32), stroke = up(44)}
end
function EX.applyBackground()
    local np = EX.derive(getNum("set_bg_r", 0), getNum("set_bg_g", 0), getNum("set_bg_b", 0))
    for inst, info in pairs(EX.Themed) do
        if inst.Parent and inst[info.prop] == EX.Palette[info.role] then inst[info.prop] = np[info.role] end
    end
    for role, col in pairs(np) do EX.Palette[role] = col; Theme[role] = col end
end
EX.prefHook = function(k)
    if (k == "set_bg_r" or k == "set_bg_g" or k == "set_bg_b") and not EX.bgPending then
        EX.bgPending = true
        task.delay(0.05, function() EX.bgPending = false; pcall(EX.applyBackground) end)
    end
end
function EX.timed(name, fn, ...)
    local t0 = os.clock(); fn(...)
    local dt = os.clock() - t0
    if dt > 0.016 then local now = os.clock(); if now - (EX.perfLast[name] or 0) > 1 then EX.perfLast[name] = now; print(string.format("[Eclypse perf] %s levou %.1f ms", name, dt * 1000)) end end
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

-- ===== ECLYPSE: logo + tela de carregamento =====
EX.LOGO_B64 = "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"
do
    local map = {}; local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    for i = 1, 64 do map[string.byte(alphabet, i)] = i - 1 end
    function EX.b64decode(s)
        local out, n, bits, acc = {}, 0, 0, 0
        for i = 1, #s do
            local v = map[string.byte(s, i)]
            if v then
                acc = acc * 64 + v; bits = bits + 6
                if bits >= 8 then bits = bits - 8; local pw = 2 ^ bits; local byte = math.floor(acc / pw); acc = acc - byte * pw; n = n + 1; out[n] = string.char(byte) end
            end
        end
        return table.concat(out)
    end
    function EX.logoAsset()
        local gca = getcustomasset or getsynasset
        if not (writefile and gca) then return nil end
        local ok, res = pcall(function()
            local name = "eclypse_logo_v1.png"
            if not (isfile and isfile(name)) then writefile(name, EX.b64decode(EX.LOGO_B64)) end
            return gca(name)
        end)
        if ok and type(res) == "string" and res ~= "" then return res end
        return nil
    end
end
function EX.makeLogo(parent, h, props)
    props = props or {}
    local z = props.ZIndex or 1
    local w = math.floor(h * 208 / 178 + 0.5)
    local box = new("Frame", {Name = "EclypseLogo", Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1, AnchorPoint = props.AnchorPoint or Vector2.new(0, 0), Position = props.Position or UDim2.fromOffset(0, 0), ZIndex = z}, parent)
    if EX.asset then
        new("ImageLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = EX.asset, ScaleType = Enum.ScaleType.Fit, ZIndex = z}, box)
    else
        local sq = new("Frame", {Size = UDim2.fromOffset(h, h), Position = UDim2.fromOffset((w - h) / 2, 0), BackgroundTransparency = 1, ZIndex = z}, box)
        local moon = new("Frame", {Size = UDim2.fromScale(0.78, 0.78), Position = UDim2.fromScale(0.06, 0.11), BackgroundColor3 = Color3.fromRGB(214, 218, 228), BorderSizePixel = 0, ZIndex = z}, sq)
        new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, moon)
        new("UIGradient", {Rotation = 40, Color = ColorSequence.new(Color3.fromRGB(240, 242, 248), Color3.fromRGB(110, 116, 130))}, moon)
        local cut = new("Frame", {Size = UDim2.fromScale(0.7, 0.7), Position = UDim2.fromScale(0.2, 0.07), BackgroundColor3 = props.cut or Color3.fromRGB(8, 4, 10), BorderSizePixel = 0, ZIndex = z + 1}, sq)
        new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, cut)
        for _, s in ipairs({{0.035, 0.46, 0}, {0.46, 0.035, 0}, {0.03, 0.24, 45}, {0.03, 0.24, -45}}) do
            new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.6, 0.5), Size = UDim2.fromScale(s[1], s[2]), Rotation = s[3], BackgroundColor3 = Color3.fromRGB(245, 246, 250), BorderSizePixel = 0, ZIndex = z + 2}, sq)
        end
    end
    return box
end
EX.Load = {active = true, shown = 0, target = 0, t0 = os.clock(), text = "Preparing environment...", ready = false}
function EX.step(p, text) local L = EX.Load; L.target = p; if text then L.text = text end; task.wait() end
function EX.destroyLoading()
    local L = EX.Load
    if L.conn then L.conn:Disconnect(); L.conn = nil end
    if L.gui then L.gui:Destroy(); L.gui = nil end
end
function EX.buildLoading()
    local L = EX.Load
    local acc = Theme.accent
    local sg = new("ScreenGui", {Name = "EclypseLoading", ResetOnSpawn = false, DisplayOrder = 10000, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, PlayerGui)
    L.gui = sg
    local root = new("CanvasGroup", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, GroupTransparency = 1}, sg)
    L.root = root
    new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(4, 2, 6), BackgroundTransparency = 0.06, BorderSizePixel = 0}, root)
    local cx, cy = 0.5, 0.46
    L.glows = {}
    for i = 1, 8 do
        local d = 1100 - (i - 1) * 110
        local g = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(cx, cy), Size = UDim2.fromOffset(d, d), BackgroundColor3 = Color3.fromRGB(150, 14, 50), BackgroundTransparency = 0.975 - i * 0.012, BorderSizePixel = 0}, root)
        new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, g)
        L.glows[i] = g
    end
    local rng = Random.new(7)
    L.parts = {}
    for i = 1, 70 do
        local sz = (rng:NextNumber() < 0.2) and 3 or 2
        local f = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(sz, sz), BackgroundColor3 = (rng:NextNumber() < 0.35) and Color3.fromRGB(255, 80, 120) or Color3.fromRGB(235, 235, 245), BorderSizePixel = 0}, root)
        L.parts[i] = {f = f, a = rng:NextNumber() * 6.283, r = 90 + rng:NextNumber() * 300, s = (rng:NextNumber() - 0.5) * 0.25, ph = rng:NextNumber() * 6.283}
    end
    L.ring = {}
    for i = 1, 56 do
        local f = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(3, 3), BackgroundColor3 = Color3.fromRGB(255, 120, 150), BackgroundTransparency = 0.45, BorderSizePixel = 0}, root)
        new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, f)
        L.ring[i] = f
    end
    local halo = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(cx, 0, cy, -34), Size = UDim2.fromOffset(210, 210), BackgroundTransparency = 1}, root)
    new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, halo)
    new("UIStroke", {Color = Color3.fromRGB(255, 90, 130), Thickness = 1.2, Transparency = 0.55}, halo)
    L.logoH = 150
    L.logo = EX.makeLogo(root, L.logoH, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(cx, 0, cy, -34), cut = Color3.fromRGB(8, 4, 10)})
    L.logoW = L.logo.Size.X.Offset
    label(root, {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(cx, 0, cy, 70), Size = UDim2.fromOffset(400, 16), Text = "L O A D I N G    I N T E R F A C E", Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = Color3.fromRGB(255, 70, 110), TextXAlignment = Enum.TextXAlignment.Center})
    local barW = 380
    local track = new("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(cx, 0, cy, 104), Size = UDim2.fromOffset(barW, 4), BackgroundColor3 = Color3.fromRGB(40, 22, 30), BorderSizePixel = 0}, root)
    new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, track)
    local fill = new("Frame", {Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = acc, BorderSizePixel = 0}, track)
    new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, fill)
    new("UIGradient", {Color = ColorSequence.new(Color3.fromRGB(190, 20, 50), Color3.fromRGB(255, 150, 180))}, fill)
    local knobHalo = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(22, 22), BackgroundColor3 = acc, BackgroundTransparency = 0.8, BorderSizePixel = 0}, track)
    new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, knobHalo)
    local knob = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(9, 9), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0}, track)
    new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, knob)
    local statusLbl = label(root, {AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(cx, -barW / 2, cy, 118), Size = UDim2.fromOffset(barW * 0.7, 16), Text = L.text, TextSize = 11, TextColor3 = Color3.fromRGB(170, 160, 170)})
    local pctLbl = label(root, {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(cx, barW / 2, cy, 118), Size = UDim2.fromOffset(80, 16), Text = "0%", TextSize = 12, Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(255, 70, 110), TextXAlignment = Enum.TextXAlignment.Right})
    label(root, {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -22), Size = UDim2.fromOffset(500, 14), Text = EX.Brand.name:upper() .. "  |  UNIVERSAL  |  by " .. EX.Brand.author, TextSize = 10, TextColor3 = Color3.fromRGB(120, 110, 120), TextXAlignment = Enum.TextXAlignment.Center})
    local pill = new("Frame", {Position = UDim2.fromOffset(14, 14), Size = UDim2.fromOffset(118, 26), BackgroundColor3 = Color3.fromRGB(24, 10, 18), BackgroundTransparency = 0.2, BorderSizePixel = 0}, root)
    new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, pill)
    new("UIStroke", {Color = Color3.fromRGB(255, 70, 110), Thickness = 1, Transparency = 0.6}, pill)
    local dot = new("Frame", {Position = UDim2.fromOffset(10, 9), Size = UDim2.fromOffset(8, 8), BackgroundColor3 = acc, BorderSizePixel = 0}, pill)
    new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, dot)
    label(pill, {Position = UDim2.fromOffset(26, 0), Size = UDim2.new(1, -30, 1, 0), Text = EX.Brand.author, TextSize = 11, Font = Enum.Font.GothamBold})
    local t = 0
    L.conn = RunService.RenderStepped:Connect(function(dt)
        t = t + dt
        local el = os.clock() - L.t0
        local goal = math.min(L.target, math.clamp(el / 2.6, 0, 1) * 100)
        L.shown = L.shown + (goal - L.shown) * math.min(1, dt * 7)
        if L.target >= 100 and L.shown >= 99.4 then L.shown = 100; L.ready = true end
        local pct = L.shown / 100
        fill.Size = UDim2.new(pct, 0, 1, 0); knob.Position = UDim2.new(pct, 0, 0.5, 0); knobHalo.Position = knob.Position
        pctLbl.Text = string.format("%d%%", math.floor(L.shown + 0.5)); statusLbl.Text = L.text
        local pulse = (math.sin(t * 2) + 1) / 2
        for i, g in ipairs(L.glows) do g.BackgroundTransparency = (0.975 - i * 0.012) - pulse * 0.01 end
        for _, q in ipairs(L.parts) do
            q.a = q.a + q.s * dt
            q.f.Position = UDim2.new(cx, math.cos(q.a) * (q.r + math.sin(t * 0.7 + q.ph) * 6), cy, math.sin(q.a) * (q.r + math.sin(t * 0.7 + q.ph) * 6) * 0.9)
            q.f.BackgroundTransparency = 0.25 + 0.55 * (math.sin(t * 2.4 + q.ph) + 1) / 2
        end
        local ra = t * 0.18
        for i, f in ipairs(L.ring) do local a = ra + (i / #L.ring) * 6.2832; f.Position = UDim2.new(cx, math.cos(a) * 250, cy, math.sin(a) * 250 * 0.9) end
        local sc = 1 + 0.015 * math.sin(t * 2.2)
        L.logo.Size = UDim2.fromOffset(L.logoW * sc, L.logoH * sc)
    end)
    TweenService:Create(root, TweenInfo.new(0.4), {GroupTransparency = 0}):Play()
end
EX.asset = EX.logoAsset()
EX.buildLoading()
EX.step(10, "Preparing environment...")

local GUI = new("ScreenGui", {Name = "DrxHub", ResetOnSpawn = false, DisplayOrder = 100, ZIndexBehavior = Enum.ZIndexBehavior.Global, Enabled = false}, PlayerGui)
local Overlay = new("ScreenGui", {Name = "DrxOverlay", ResetOnSpawn = false, DisplayOrder = 999, IgnoreGuiInset = true}, PlayerGui)

-- UI MOUSE FIX
local UiMouse = {open = false, saved = nil, wanted = nil, wantedIcon = nil, modal = nil, alive = true, hooked = false, hbConn = nil}
do
    local ACTION_SINK, STEP_NAME = "DrxUiMouseSink", "DrxUiMouseUnlock"
    local function sink() return Enum.ContextActionResult.Sink end
    local function enforce()
        local mb = UserInputService.MouseBehavior
        if mb ~= Enum.MouseBehavior.Default then UiMouse.wanted = mb; UserInputService.MouseBehavior = Enum.MouseBehavior.Default end
        if not UserInputService.MouseIconEnabled then UserInputService.MouseIconEnabled = true end
    end
    if hookmetamethod and checkcaller then
        local old
        local function hook(self, k, v)
            if UiMouse.alive and UiMouse.open and self == UserInputService and not checkcaller() then
                if k == "MouseBehavior" then UiMouse.wanted = v; return end
                if k == "MouseIconEnabled" then UiMouse.wantedIcon = v; return end
            end
            return old(self, k, v)
        end
        local ok = pcall(function() old = hookmetamethod(game, "__newindex", newcclosure and newcclosure(hook) or hook) end)
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
Conns[#Conns + 1] = GUI:GetPropertyChangedSignal("Enabled"):Connect(function() if EX.Load.active and GUI.Enabled then GUI.Enabled = false; return end; UiMouse.setOpen(GUI.Enabled) end)

-- UI V19
local Main = new("Frame", {Size = UDim2.fromOffset(820, 580), Position = UDim2.new(0.5, -410, 0.5, -290), BackgroundColor3 = Theme.bg, Active = true}, GUI)
corner(Main, 12); outline(Main, 2, Theme.accent)
local TopBar = new("Frame", {Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = Theme.panel}, Main)
corner(TopBar, 12)
new("Frame", {Size = UDim2.new(1, 0, 0, 15), Position = UDim2.new(0, 0, 1, -15), BackgroundColor3 = Theme.panel}, TopBar)
new("Frame", {Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, -2), BackgroundColor3 = Theme.accent}, TopBar)
label(TopBar, {Size = UDim2.fromOffset(200, 50), Position = UDim2.fromOffset(20, 0), Text = "Eclypse", Font = Enum.Font.GothamBlack, TextSize = 22, TextColor3 = Theme.accent})
label(TopBar, {Size = UDim2.fromOffset(200, 50), Position = UDim2.fromOffset(140, 0), Text = "ENTERPRISE", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.sub})
local closeBtn = new("TextButton", {Size = UDim2.fromOffset(30, 30), Position = UDim2.new(1, -45, 0.5, -15), BackgroundTransparency = 1, Text = "x", Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = Theme.sub}, TopBar)
closeBtn.MouseEnter:Connect(function() tween(closeBtn, {TextColor3 = Theme.accent}) end)
closeBtn.MouseLeave:Connect(function() tween(closeBtn, {TextColor3 = Theme.sub}) end)
local doUnload
local Confirm = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.4, Active = true, Visible = false, ZIndex = 3000}, Main); corner(Confirm, 12)
local cbox = new("Frame", {Size = UDim2.fromOffset(360, 160), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = Theme.panel, ZIndex = 3001}, Confirm); corner(cbox, 10); outline(cbox, 2, Theme.accent)
label(cbox, {Size = UDim2.new(1, -30, 0, 26), Position = UDim2.fromOffset(15, 16), Text = "Remover o Eclypse?", Font = Enum.Font.GothamBold, TextSize = 17, ZIndex = 3002})
label(cbox, {Size = UDim2.new(1, -30, 0, 44), Position = UDim2.fromOffset(15, 48), Text = "Isso fecha o menu e desliga todas as funções agora. Para só esconder o menu, use a tecla do menu.", TextSize = 12, TextColor3 = Theme.sub, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 3002})
local yesBtn = new("TextButton", {Size = UDim2.fromOffset(150, 34), Position = UDim2.new(0, 15, 1, -50), BackgroundColor3 = Theme.accent, Text = "Sim, remover", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Theme.text, AutoButtonColor = false, ZIndex = 3002}, cbox); corner(yesBtn, 8)
local noBtn = new("TextButton", {Size = UDim2.fromOffset(150, 34), Position = UDim2.new(1, -165, 1, -50), BackgroundColor3 = Theme.card, Text = "Cancelar", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Theme.text, AutoButtonColor = false, ZIndex = 3002}, cbox); corner(noBtn, 8); outline(noBtn, 1, Theme.stroke)
yesBtn.MouseButton1Click:Connect(function() if doUnload then doUnload() end end)
noBtn.MouseButton1Click:Connect(function() Confirm.Visible = false end)
closeBtn.MouseButton1Click:Connect(function() Confirm.Visible = true end)


-- Cartao pequeno acima do hub (nome, Discord, autor); aparece depois do carregamento
do
    local B = EX.Brand
    local card = new("CanvasGroup", {Name = "EclypseInfo", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0, 44), Size = UDim2.fromOffset(340, 50), BackgroundColor3 = Theme.panel, GroupTransparency = 1, Visible = false, ZIndex = 60}, Main)
    corner(card, 10); outline(card, 1, Theme.accent)
    EX.makeLogo(card, 34, {Position = UDim2.fromOffset(10, 8), cut = Theme.panel})
    label(card, {Size = UDim2.fromOffset(66, 18), Position = UDim2.fromOffset(56, 7), Text = B.name, Font = Enum.Font.GothamBlack, TextSize = 14})
    label(card, {Size = UDim2.fromOffset(110, 14), Position = UDim2.fromOffset(124, 9), Text = "by " .. B.author, TextSize = 11, TextColor3 = Theme.accent, Font = Enum.Font.GothamBold})
    label(card, {Size = UDim2.fromOffset(190, 14), Position = UDim2.fromOffset(56, 27), Text = B.discord, TextSize = 11, TextColor3 = Theme.sub})
    local copy = new("TextButton", {Size = UDim2.fromOffset(62, 24), Position = UDim2.new(1, -72, 0.5, -12), BackgroundColor3 = Theme.accent, Text = "Copiar", Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = Theme.text, AutoButtonColor = false}, card)
    corner(copy, 8)
    copy.MouseButton1Click:Connect(function()
        local ok = pcall(function() setclipboard(B.invite) end)
        copy.Text = ok and "Copiado!" or "Sem clip"
        if not ok and notify then notify(B.name, B.invite) end
        task.delay(1.4, function() if copy.Parent then copy.Text = "Copiar" end end)
    end)
    function EX.revealCard()
        card.Visible = true
        TweenService:Create(card, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0, 10)}):Play()
        TweenService:Create(card, TweenInfo.new(0.4), {GroupTransparency = 0}):Play()
    end
end

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
    local function render() local on = get(key); tween(sw, {BackgroundColor3 = on and Theme.accent or Theme.track}); tween(knob, {Position = on and UDim2.fromOffset(19, 3) or UDim2.fromOffset(3, 3), BackgroundColor3 = on and Theme.text or Theme.sub}) end
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
    local function update(pct) local v = math.floor(min + pct * (max - min) + 0.5); set(key, v); pct = (v - min) / math.max(max - min, 1); fill.Size = UDim2.new(pct, 0, 1, 0); knob.Position = UDim2.new(pct, 0, 0.5, 0); valLbl.Text = tostring(v) end
    update((getNum(key, default) - min) / math.max(max - min, 1))
    btn.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then activeSlider = {update = update, track = track}; if track.AbsoluteSize.X > 0 then update(math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)) end end end)
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
    btnMode.MouseButton1Click:Connect(function() local modes = {"Always", "Hold", "Toggle"}; local curr = get(key).Mode; local nextMode = modes[1]; for i, m in ipairs(modes) do if m == curr then nextMode = modes[(i % #modes) + 1] break end end; set(key, {Key = get(key).Key, Mode = nextMode}); btnMode.Text = nextMode end)
    btnKey.MouseButton1Click:Connect(function() btnKey.Text = "..."; local conn; conn = UserInputService.InputBegan:Connect(function(input, processed) if processed then return end; local kName = nil; if input.UserInputType == Enum.UserInputType.Keyboard then kName = input.KeyCode.Name elseif input.UserInputType == Enum.UserInputType.MouseButton1 then kName = "LMB" elseif input.UserInputType == Enum.UserInputType.MouseButton2 then kName = "RMB" elseif input.UserInputType == Enum.UserInputType.MouseButton3 then kName = "MMB" end; if kName then set(key, {Key = kName, Mode = get(key).Mode}); btnKey.Text = kName; conn:Disconnect() end end) end)
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
    for n, b in pairs(NavButtons) do local sel = (n == name); tween(b.bg, {BackgroundColor3 = sel and Theme.accent or Theme.panel}); tween(b.txt, {TextColor3 = sel and Theme.text or Theme.sub}) end
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
    local g1 = CreateGroup(c1, "Ragebot"); CreateToggle(g1, "Ragebot", "rage_on", false); CreateKeybind(g1, "Ragebot Key", "rage_key", "Always", "Always"); CreateToggle(g1, "Wallbang", "rage_wall", false); CreateSlider(g1, "FOV", "rage_fov", 10, 360, 120); CreateSlider(g1, "FOV Size", "rage_fovsize", 10, 800, 720); CreateKeybind(g1, "Auto Shoot", "rage_autoshoot", "Always", "Always"); CreateToggle(g1, "Team Check", "rage_team", true)
    local g3 = CreateGroup(c1, "Kill All"); CreateToggle(g3, "Kill All", "ra_kill", false); CreateKeybind(g3, "Kill All Key", "ra_kill_key", "Always", "Always"); CreateToggle(g3, "Use Gun", "ra_kill_gun", true)
    local g2 = CreateGroup(c2, "Weapon Mods"); CreateToggle(g2, "Rapid Fire", "wpn_rapid", false); CreateToggle(g2, "No Recoil", "wpn_recoil", false); CreateToggle(g2, "No Spread", "wpn_spread", false); CreateToggle(g2, "Instant Reload", "wpn_reload", false); CreateToggle(g2, "Infinite Magazine", "wpn_ammo", false); CreateToggle(g2, "Custom Fire Cooldown", "wpn_cd", false); CreateSlider(g2, "Fire Cooldown (ms)", "wpn_cdval", 0, 1000, 500)
    local g4 = CreateGroup(c2, "Player"); CreateToggle(g4, "Auto Respawn", "ply_respawn", false)
end)
AddPage("Legit", function(c1, c2)
    local g1 = CreateGroup(c1, "Silent Aim"); CreateToggle(g1, "Silent Aim", "sil_on", false); CreateKeybind(g1, "Silent Key", "sil_key", "Always", "Always"); CreateSlider(g1, "Smooth", "sil_smooth", 1, 20, 5); CreateToggle(g1, "Visible Only", "sil_vis", false); CreateDropdown(g1, "Bone", "sil_bone", {"Head", "Torso", "Root"}, "Head"); CreateToggle(g1, "Team Check", "sil_team", true); CreateToggle(g1, "Anywhere (360°)", "sil_any", false); CreateToggle(g1, "Show Target", "sil_show", true); CreateToggle(g1, "Only While Shooting", "sil_gate", false)
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
    local g1 = CreateGroup(c1, "ESP"); CreateToggle(g1, "Enabled", "esp_on", true); CreateDropdown(g1, "Renderer", "esp_render", {"Full", "Lite"}, "Full"); CreateToggle(g1, "Box ESP", "esp_box", false); CreateToggle(g1, "ESP Name", "esp_name", false); CreateToggle(g1, "Skeleton", "esp_skel", false); CreateToggle(g1, "Weapon ESP", "esp_wpn", false); CreateToggle(g1, "ESP Team Check", "esp_team", true); CreateToggle(g1, "Health Bar", "esp_health", false); CreateToggle(g1, "Include NPCs", "esp_npc", true); CreateSlider(g1, "Max Distance", "esp_dist", 50, 2000, 1000); CreateToggle(g1, "Fade With Distance", "esp_fade", false); CreateToggle(g1, "Intro Animation", "esp_intro", false); CreateToggle(g1, "Distance", "esp_distance", false); CreateToggle(g1, "Head Dot", "esp_head", false); CreateToggle(g1, "Tracers", "esp_tracers", false); CreateDropdown(g1, "Tracer Origin", "esp_torigin", {"Bottom", "Center", "Mouse", "Top"}, "Bottom"); CreateToggle(g1, "Path Prediction", "esp_path", false); CreateSlider(g1, "Prediction Time (x0.1s)", "esp_ptime", 1, 50, 50); CreateSlider(g1, "Color (Hue)", "esp_hue", 0, 100, 99); CreateToggle(g1, "Rainbow", "esp_rainbow", false); CreateToggle(g1, "Team Color", "esp_teamcolor", false)
    local g4 = CreateGroup(c1, "Box"); CreateDropdown(g4, "Style", "esp_style", {"Full", "Corners", "Rounded", "3D"}, "Corners"); CreateSlider(g4, "Thickness", "esp_thick", 1, 6, 2); CreateSlider(g4, "Rounding", "esp_round", 0, 20, 6); CreateSlider(g4, "Fill %", "esp_fill", 0, 100, 50); CreateToggle(g4, "Outline", "esp_outline", false); CreateSlider(g4, "Size Smoothing %", "esp_smooth", 0, 100, 25)
    local g5 = CreateGroup(c1, "Health"); CreateToggle(g5, "Damage Ghost", "esp_ghost", false); CreateToggle(g5, "Damage Numbers", "esp_dmgnum", false); CreateToggle(g5, "Health Value", "esp_hpval", false); CreateSlider(g5, "Width", "esp_hpwidth", 1, 6, 4)
    local g6 = CreateGroup(c1, "Labels"); CreateToggle(g6, "Name Pill", "esp_pill", false); CreateSlider(g6, "Name Size", "esp_namesize", 8, 30, 14)
    local g2 = CreateGroup(c2, "Highlight"); CreateToggle(g2, "Enable Highlight", "hl_on", false); CreateToggle(g2, "Highlight Team Check", "hl_team", true); CreateToggle(g2, "Highlight Color", "hl_color", false); CreateToggle(g2, "Show Name", "hl_name", false)
    local g3 = CreateGroup(c2, "Tracers"); CreateToggle(g3, "Enable Tracers", "trc_on", false); CreateSlider(g3, "Tracer Width", "trc_width", 1, 10, 2); CreateSlider(g3, "Tracer Lifetime", "trc_life", 1, 10, 5)
end)
AddPage("World", function(c1, c2) local g1 = CreateGroup(c1, "Ambiente"); label(g1, {Size = UDim2.new(1, 0, 0, 20), Text = "Em breve...", TextSize = 14, TextColor3 = Theme.sub}) end)
AddPage("Configurações", function(c1, c2)
    local g1 = CreateGroup(c1, "Universal Settings"); CreateToggle(g1, "Dynamic Island", "set_island", false); CreateToggle(g1, "Watermark HUD", "set_watermark", true); CreateToggle(g1, "Quick Access Keybind", "set_qaccess", false); CreateToggle(g1, "Mobile Toggle Button", "set_mobile", false); CreateKeybind(g1, "Menu Keybind", "misc_menukey", "RightShift", "Toggle")
    local g2 = CreateGroup(c2, "Screen Ambience"); CreateSlider(g2, "Ambience Opacity", "set_opacity", 10, 100, 50); CreateToggle(g2, "Show Only When UI...", "set_showonly", false)
    local g3 = CreateGroup(c2, "Cor do Fundo (RGB)"); CreateSlider(g3, "Fundo - Vermelho", "set_bg_r", 0, 160, 0); CreateSlider(g3, "Fundo - Verde", "set_bg_g", 0, 160, 0); CreateSlider(g3, "Fundo - Azul", "set_bg_b", 0, 160, 0)
end)
AddNav("Rage"); AddNav("Legit"); AddNav("Misc"); AddNav("Inventory Changer"); AddNav("Visuals"); AddNav("World"); AddNav("Configurações"); SwitchPage("Rage")
EX.step(52, "Loading modules...")

-- ================== ENGINE V21 ==================
local function guard(name, fn) return function(...)
    local t0 = os.clock()
    local ok, err = pcall(fn, ...)
    local dt = os.clock() - t0
    if dt > 0.016 then local now = os.clock(); if now - (EX.perfLast[name] or 0) > 1 then EX.perfLast[name] = now; print(string.format("[Eclypse perf] %s levou %.1f ms", name, dt * 1000)) end end
    if not ok and not Warned[name] then Warned[name] = true; warn("[Eclypse] " .. name .. ": " .. tostring(err)) end
end end
local Cap = {mousemoverel = mousemoverel, mouse1click = mouse1click, hookmetamethod = hookmetamethod, newcclosure = newcclosure, checkcaller = checkcaller, getnamecallmethod = getnamecallmethod, setnamecallmethod = setnamecallmethod, getloadedmodules = getloadedmodules, require = require}
local GameConfig = {Build = "UNSET", Debug = true, Probe = true, Weapon = {ToolModule = nil, Fields = {NoRecoil = nil, NoSpread = nil, InstantReload = nil, InfiniteMagazine = nil, FireCooldown = nil}}, SpectateProbe = nil}
local Fire = {last = 0}
local function clickFire() Fire.last = os.clock(); if type(Cap.mouse1click) == "function" then local ok = pcall(Cap.mouse1click); if ok then return end end; pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton1(Vector2.new()) end) end
local function activateTool() Fire.last = os.clock(); local c = LP.Character; local t = c and c:FindFirstChildOfClass("Tool"); if t then pcall(function() t:Activate() end) end end

-- GetMouseDelta (aimbot sem mousemoverel) e Mouse.Hit/Target (silent) usam UM hook de __index, instalado so quando necessario
local MouseDeltaHook = {installed = false, alive = true, pending = Vector2.new(0, 0)}
local ensureIndexHook -- definido junto do silent; instala um unico hook de __index sob demanda

local BindState = {}
local function inputDown(keyName) if keyName == "LMB" then return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) elseif keyName == "RMB" then return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) elseif keyName == "MMB" then return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton3) end; local ok, kc = pcall(function() return Enum.KeyCode[keyName] end); if ok and kc then return UserInputService:IsKeyDown(kc) end; return false end
local function pollBinds()
    local typing = UserInputService:GetFocusedTextBox() ~= nil
    for k, v in pairs(Prefs) do
        if type(v) == "table" and v.Key and v.Mode and k ~= "misc_menukey" then
            local st = BindState[k]; if not st then st = {on = false, prev = false}; BindState[k] = st end
            if v.Mode == "Always" or v.Key == "None" then st.on = true
            else local down = (not typing) and inputDown(v.Key); if v.Mode == "Hold" then st.on = down elseif down and not st.prev then st.on = not st.on end; st.prev = down end
        end
    end
end
local function bindActive(k) local st = BindState[k]; return st ~= nil and st.on end

local FrameNo, NPCs, NPCInit = 0, {}, false
local function initNPCs()
    if NPCInit then return end; NPCInit = true
    local function consider(inst) if inst.ClassName == "Humanoid" then local m = inst.Parent; if m and m:IsA("Model") and m ~= LP.Character and not Players:GetPlayerFromCharacter(m) then NPCs[m] = true end end end
    Conns[#Conns + 1] = Workspace.DescendantAdded:Connect(consider)
    Conns[#Conns + 1] = Workspace.DescendantRemoving:Connect(function(d) if d.ClassName == "Humanoid" and d.Parent then NPCs[d.Parent] = nil end end)
    task.spawn(function()
        local stack, n = {Workspace}, 0
        while #stack > 0 do
            local inst = table.remove(stack)
            for _, c in ipairs(inst:GetChildren()) do
                pcall(consider, c); stack[#stack + 1] = c; n = n + 1
                if n % 1500 == 0 then task.wait(); if not UiMouse.alive then return end end
            end
        end
    end)
end
local function isEnemyPlayer(plr) if plr.Neutral or plr.Team == nil or LP.Team == nil then return true end; return plr.Team ~= LP.Team end
local function buildEntity(char, plr) local hum = char:FindFirstChildOfClass("Humanoid"); local hrp = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("Head"); if not hum or not hrp or hum.Health <= 0 then return nil end; return {char = char, hum = hum, hrp = hrp, plr = plr, name = plr and plr.Name or char.Name} end
-- Heurística (assumida): NPC com atributo/valor "Team"/"TeamName" igual ao nome do meu time é aliado; sem informação = inimigo.
local function npcEnemy(m)
    local mine = LP.Team; if not mine then return true end
    local v = m:GetAttribute("Team"); if v == nil then v = m:GetAttribute("TeamName") end
    if v == nil then local c = m:FindFirstChild("Team") or m:FindFirstChild("TeamName"); if c and c:IsA("ValueBase") then v = c.Value end end
    if v == nil then return true end
    if typeof(v) == "Instance" or typeof(v) == "BrickColor" then v = v.Name end
    return tostring(v) ~= mine.Name
end
local EntCache = {frame = -1, list = {}, byChar = {}}
local function entities()
    if EntCache.frame == FrameNo then return EntCache.list end
    local list, by = {}, {}
    for _, plr in ipairs(Players:GetPlayers()) do if plr ~= LP and plr.Character then local e = buildEntity(plr.Character, plr); if e then e.enemy = isEnemyPlayer(plr); list[#list + 1] = e; by[e.char] = e end end end
    if NPCInit then for m in pairs(NPCs) do if m.Parent and not Players:GetPlayerFromCharacter(m) then local e = buildEntity(m, nil); if e then e.enemy = npcEnemy(m); e.npc = true; list[#list + 1] = e; by[m] = e end else NPCs[m] = nil end end end
    EntCache.frame = FrameNo; EntCache.list = list; EntCache.byChar = by; return list
end
local Track = {}
local function trackEntities() local now, alive = os.clock(), {}; for _, e in ipairs(entities()) do local t = Track[e.char]; if not t then t = {}; Track[e.char] = t end; t[#t + 1] = {now, e.hrp.Position}; while #t > 2 and now - t[1][1] > 0.6 do table.remove(t, 1) end; alive[e.char] = true end; for c in pairs(Track) do if not alive[c] then Track[c] = nil end end end
local function velocityOf(char, windowMs) local t = Track[char]; if not t or #t < 2 then return Vector3.new(0, 0, 0) end; local last = t[#t]; local first = last; for i = #t - 1, 1, -1 do if last[1] - t[i][1] <= windowMs / 1000 then first = t[i] else break end end; local dt = last[1] - first[1]; if dt < 1e-3 then return Vector3.new(0, 0, 0) end; return (last[2] - first[2]) / dt end

local RayP = RaycastParams.new(); RayP.FilterType = Enum.RaycastFilterType.Exclude
local function setFilter(extra) local f = {}; if LP.Character then f[#f + 1] = LP.Character end; if extra then f[#f + 1] = extra end; RayP.FilterDescendantsInstances = f end
local WallP = RaycastParams.new(); WallP.FilterType = Enum.RaycastFilterType.Exclude; WallP.RespectCanCollide = true
local function lineClear(cam, pos, char) local f = {}; if LP.Character then f[#f + 1] = LP.Character end; if char then f[#f + 1] = char end; WallP.FilterDescendantsInstances = f; return Workspace:Raycast(cam.CFrame.Position, pos - cam.CFrame.Position, WallP) == nil end
local function getPart(char, which) if which == "Head" then return char:FindFirstChild("Head") elseif which == "Torso" then return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") end; return char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") end
local Jitter = setmetatable({}, {__mode = "k"})
local function jitterFor(char, size) local j, now = Jitter[char], os.clock(); if not j or now - j.t > 0.25 then j = {t = now, v = Vector3.new(math.random() * 2 - 1, math.random() * 2 - 1, math.random() * 2 - 1) * size}; Jitter[char] = j end; return j.v end

local function pickTarget(o)
    local cam = Workspace.CurrentCamera; if not cam then return nil end
    local vs = cam.ViewportSize; local center = Vector2.new(vs.X / 2, vs.Y / 2); local camPos, look = cam.CFrame.Position, cam.CFrame.LookVector
    local pxPerDeg = vs.Y / math.max(cam.FieldOfView, 1); local ref = (o.radius < 1e5) and o.radius or vs.Y / 2; local best, bestScore
    for _, e in ipairs(entities()) do
        if (not o.teamCheck) or e.enemy then
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
    local v, on = cam:WorldToViewportPoint(target.pos); local vs = cam.ViewportSize
    if on and type(Cap.mousemoverel) == "function" then
        local dx, dy = (v.X - vs.X / 2) * alpha, (v.Y - vs.Y / 2) * alpha; local mag = math.sqrt(dx * dx + dy * dy); if mag > 80 then dx, dy = dx / mag * 80, dy / mag * 80 end
        if pcall(Cap.mousemoverel, dx, dy) then return end
    end
    local a = alpha
    if on and not MouseDeltaHook.installed and ensureIndexHook then ensureIndexHook() end
    if on and MouseDeltaHook.installed then
        local p = MouseDeltaHook.pending + Vector2.new((v.X - vs.X / 2) * alpha * 0.5, (v.Y - vs.Y / 2) * alpha * 0.5)
        if p.Magnitude > 150 then p = p.Unit * 150 end
        MouseDeltaHook.pending = p; a = alpha * 0.5
    end
    cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, target.pos), a)
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

local Silent = {target = nil, hooked = false, alive = true, shooting = false, lmb = false, clickAt = 0}
local ProbeSeen = {}
local function shotWindow() return Silent.shooting or Silent.lmb or (os.clock() - Silent.clickAt) < 0.35 or (os.clock() - Fire.last) < 0.3 end
local function redirectOK() return shotWindow() or not get("sil_gate", false) end
Conns[#Conns + 1] = UserInputService.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then Silent.lmb = true; Silent.clickAt = os.clock() end end)
Conns[#Conns + 1] = UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then Silent.lmb = false; Silent.clickAt = os.clock() end end)
local SilentHooks, IndexHook = {done = false}, {done = false}
local function installSilentHooks()
    if SilentHooks.done then return end; SilentHooks.done = true
    if not (Cap.hookmetamethod and Cap.getnamecallmethod and Cap.checkcaller) then return end
    local oldNC
    local setNC = Cap.setnamecallmethod
    -- Caminho rapido primeiro (sem alvo = uma leitura e retorno). Nenhuma chamada com ":" antes de oldNC: ela troca o metodo de namecall que o original le.
    local function hooked(self, ...)
        local st = Silent.target
        if not (st and Silent.alive) then return oldNC(self, ...) end
        local method = Cap.getnamecallmethod()
        if Cap.checkcaller() then return oldNC(self, ...) end
        local n = select("#", ...); local a = {...}
        if self == Workspace and method == "Raycast" and redirectOK() and typeof(a[1]) == "Vector3" then
            local to = st.pos - a[1]
            if to.Magnitude > 0.01 then
                a[2] = to.Unit * math.max(typeof(a[2]) == "Vector3" and a[2].Magnitude or 1000, to.Magnitude + 1)
                if setNC then pcall(setNC, method) end
                return oldNC(self, table.unpack(a, 1, n))
            end
        elseif (method == "ViewportPointToRay" or method == "ScreenPointToRay") and redirectOK() and st.vp and type(a[1]) == "number" and typeof(self) == "Instance" and self == Workspace.CurrentCamera then
            local x, y = st.vp.X, st.vp.Y
            if method == "ScreenPointToRay" then x, y = x + st.inX, y + st.inY end
            if setNC then pcall(setNC, method) end
            if a[3] ~= nil then return oldNC(self, x, y, a[3]) end
            return oldNC(self, x, y)
        elseif (method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist") and redirectOK() and typeof(a[1]) == "Ray" then
            local to = st.pos - a[1].Origin
            if to.Magnitude > 0.01 then
                a[1] = Ray.new(a[1].Origin, to.Unit * math.max(a[1].Direction.Magnitude, to.Magnitude + 1))
                if setNC then pcall(setNC, method) end
                return oldNC(self, table.unpack(a, 1, n))
            end
        elseif (method == "FireServer" or method == "InvokeServer") and shotWindow() and typeof(self) == "Instance" then
            local cn = self.ClassName
            if cn == "RemoteEvent" or cn == "RemoteFunction" or cn == "UnreliableRemoteEvent" then
                if GameConfig.Probe and not ProbeSeen[self.Name] then
                    ProbeSeen[self.Name] = true
                    local ts = {}; for i = 1, n do ts[i] = typeof(a[i]) end
                    print("[Eclypse probe] remote durante disparo: " .. self.Name .. " [" .. cn .. "] (" .. table.concat(ts, ", ") .. ")")
                end
                local cam = Workspace.CurrentCamera; local changed = false
                if cam then
                    for i = 1, n do
                        local arg = a[i]
                        if typeof(arg) == "CFrame" then a[i] = CFrame.lookAt(arg.Position, st.pos); changed = true
                        elseif typeof(arg) == "Vector3" and math.abs(arg.Magnitude - 1) < 0.02 then a[i] = (st.pos - cam.CFrame.Position).Unit; changed = true
                        elseif typeof(arg) == "Ray" then a[i] = Ray.new(arg.Origin, (st.pos - arg.Origin).Unit * math.max(arg.Direction.Magnitude, 1)); changed = true end
                    end
                end
                if changed then
                    if setNC then pcall(setNC, method) end
                    return oldNC(self, table.unpack(a, 1, n))
                end
            end
        end
        return oldNC(self, ...)
    end
    local ok = pcall(function() oldNC = Cap.hookmetamethod(game, "__namecall", Cap.newcclosure and Cap.newcclosure(hooked) or hooked) end)
    Silent.hooked = ok and oldNC ~= nil
    print("[Eclypse] hook de namecall do Silent: " .. tostring(Silent.hooked))
end
ensureIndexHook = function()
    if IndexHook.done then return end; IndexHook.done = true
    if not (Cap.hookmetamethod and Cap.newcclosure and Cap.checkcaller) then return end
    local mouse = LP:GetMouse(); local oldIndex
    local function indexHook(self, key)
        if key == "Hit" or key == "Target" or key == "UnitRay" then
            local st = Silent.target
            if st and Silent.alive and self == mouse and redirectOK() and not Cap.checkcaller() then
                if key == "Hit" then return CFrame.new(st.pos) end
                if key == "Target" then return st.char end
                local cam = Workspace.CurrentCamera; if cam then return Ray.new(cam.CFrame.Position, (st.pos - cam.CFrame.Position).Unit) end
            end
        elseif key == "GetMouseDelta" and MouseDeltaHook.alive and self == UserInputService and not Cap.checkcaller() then
            local real = oldIndex(self, key)
            return function(s) local d = real(s); local p = MouseDeltaHook.pending; if p.X ~= 0 or p.Y ~= 0 then MouseDeltaHook.pending = Vector2.new(0, 0) end; return d + p end
        end
        return oldIndex(self, key)
    end
    local ok = pcall(function() oldIndex = Cap.hookmetamethod(mouse, "__index", Cap.newcclosure(indexHook)) end)
    MouseDeltaHook.installed = ok and oldIndex ~= nil
end
local function runSilent(cam, dt)
    if get("sil_on") then installSilentHooks(); ensureIndexHook() end
    Silent.target = nil; Silent.shooting = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1); if not (get("sil_on") and bindActive("sil_key")) then return end
    local any = get("sil_any", false); local bone = ({Head = "Head", Torso = "Torso", Root = "Root"})[get("sil_bone", "Head")] or "Head"
    local t = pickTarget({part = bone, radius = any and math.huge or getNum("sil_fov", 120), maxDist = 2000, wall = get("sil_vis", false), prio = any and "Distance" or "Cursor", wc = 1, wd = 0, wf = 0, offscreen = any, predict = false, sample = 90, jitter = 0, teamCheck = get("sil_team", true)})
    if not t then return end
    -- viewport/inset calculados aqui: dentro do hook nao pode haver chamada com ":" (corromperia o namecall)
    local v = cam:WorldToViewportPoint(t.pos); local ins = GuiService:GetGuiInset()
    Silent.target = {pos = t.pos, char = t.ent.char, vp = (v.Z > 0) and Vector2.new(v.X, v.Y) or nil, inX = ins.X, inY = ins.Y}
    if not Silent.hooked then aimStep(t, stepAlpha(1 / math.max(getNum("sil_smooth", 5), 1), dt)) end
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
local function castThrough(origin, dir)
    setFilter(nil); local filt = RayP.FilterDescendantsInstances
    for _ = 1, 8 do
        local res = Workspace:Raycast(origin, dir, RayP); if not res then return nil end
        local inst = res.Instance
        if entityFromPart(inst) or (inst.CanCollide and inst.Transparency < 0.95) then return res end
        filt[#filt + 1] = inst; RayP.FilterDescendantsInstances = filt
    end
    return nil
end
local function runTrigger(cam, dt)
    if not (get("trg_on") and bindActive("trg_key")) then Trig.since = nil; return end; entities()
    local maxD, zone, teamOn = getNum("trg_dist", 1000), get("trg_zone", "Whole body"), get("trg_team", true); local hitDist; local vs = cam.ViewportSize
    if get("trg_fovonly") then
        local center, rad = Vector2.new(vs.X / 2, vs.Y / 2), getNum("sil_fov", 120); local which = (zone == "Head") and "Head" or (zone == "Upper body" and "Torso" or "Root")
        for _, e in ipairs(EntCache.list) do if (not teamOn) or e.enemy then local part = getPart(e.char, which); if part then local v, on = cam:WorldToViewportPoint(part.Position); local d = (part.Position - cam.CFrame.Position).Magnitude; if on and d <= maxD and (Vector2.new(v.X, v.Y) - center).Magnitude <= rad then hitDist = d; break end end end end
    else
        local m = UserInputService:GetMouseLocation(); local ray = cam:ScreenPointToRay(m.X, m.Y)
        local res = castThrough(ray.Origin, ray.Direction * maxD)
        if res then local e = entityFromPart(res.Instance); if e and ((not teamOn) or e.enemy) and zoneOK(res.Instance, zone) then hitDist = res.Distance end end
    end
    if not hitDist then Trig.since = nil; return end; local now = os.clock(); if not Trig.since then Trig.since = now end
    local react = getNum("trg_react", 60); if get("trg_autoreact") then react = react * (0.5 + hitDist / math.max(maxD, 1)) end
    if (now - Trig.since) * 1000 < react then return end; if (now - Trig.last) * 1000 < getNum("trg_delay", 50) then return end; Trig.last = now
    local chance = getNum("trg_chance", 100); if get("trg_autochance") then chance = chance * math.clamp(1.1 - 0.6 * hitDist / math.max(maxD, 1), 0.3, 1) end
    if math.random() * 100 > chance then return end; if get("trg_gun", true) then clickFire() else activateTool() end
end

local Patched, WeaponWarned = {}, {}
local AutoW = {list = {}, seen = setmetatable({}, {__mode = "k"}), mods = {}, last = 0, lmLast = 0, n = 0, t0 = 0, mask = "", modDone = setmetatable({}, {__mode = "k"}), scans = 0, found = {}, warned = {}}
-- Regras HEURÍSTICAS por nome de campo (lido do jogo em runtime; nada é hardcoded de build). Valores aplicados: 0 / 999 / slider.
local WEAPON_RULES = {
    {pref = "wpn_recoil", label = "No Recoil", test = function(k) return k:find("recoil") ~= nil end, value = function() return 0 end},
    {pref = "wpn_spread", label = "No Spread", test = function(k) return k:find("spread") ~= nil or k:find("inaccura") ~= nil or k:find("bloom") ~= nil end, value = function() return 0 end},
    {pref = "wpn_reload", label = "Instant Reload", test = function(k) return k:find("reload") ~= nil and (k:find("time") ~= nil or k:find("duration") ~= nil or k:find("delay") ~= nil or k == "reload") end, value = function() return 0 end},
    {pref = "wpn_ammo", label = "Infinite Magazine", test = function(k) return (k:find("ammo") ~= nil or k:find("clip") ~= nil or k:find("magazine") ~= nil) and k:find("max") == nil end, value = function() return 999 end},
    {pref = "wpn_cd", label = "Custom Fire Cooldown", test = function(k) return k:find("cooldown") ~= nil or k:find("firedelay") ~= nil or k:find("fire_delay") ~= nil or k:find("shootdelay") ~= nil or k:find("shotdelay") ~= nil or k:find("firetime") ~= nil or k:find("timebetween") ~= nil or k:find("fireinterval") ~= nil or k:find("shootinterval") ~= nil or k:find("attackdelay") ~= nil or k == "delay" or k == "cd" end,
        value = function(orig) local ms = getNum("wpn_cdval", 500); if type(orig) == "number" and orig >= 10 then return ms end; return ms / 1000 end},
}
local RuleKeys, RuleKeysN = {}, 0
local function ruleFor(name)
    local k = tostring(name):lower()
    local hits = RuleKeys[k]
    if hits == nil then
        hits = {}; for _, r in ipairs(WEAPON_RULES) do if r.test(k) then hits[#hits + 1] = r end end
        if RuleKeysN < 20000 then RuleKeys[k] = hits; RuleKeysN = RuleKeysN + 1 end
    end
    for i = 1, #hits do if get(hits[i].pref, false) then return hits[i] end end
end
local function readRef(e) if e.kind == "attr" then return e.ref:GetAttribute(e.key) elseif e.kind == "val" then return e.ref.Value end; return e.ref[e.key] end
local function writeRef(e, v) if e.kind == "attr" then e.ref:SetAttribute(e.key, v) elseif e.kind == "val" then e.ref.Value = v else e.ref[e.key] = v end end
local function addEntry(kind, ref, key, rule, path)
    local s = AutoW.seen[ref]; if not s then s = {}; AutoW.seen[ref] = s end
    if s[key] then return end
    local e = {kind = kind, ref = ref, key = key, rule = rule, path = path}
    local ok, orig = pcall(readRef, e); if not ok or type(orig) ~= "number" then return end
    s[key] = true; e.orig = orig; AutoW.list[#AutoW.list + 1] = e; AutoW.found[rule.pref] = true
end
local function scanTable(tbl, depth, visited, path)
    if visited[tbl] then return end; visited[tbl] = true
    local cnt = 0
    for k, v in pairs(tbl) do
        cnt = cnt + 1; if cnt > 3000 then break end
        AutoW.n = AutoW.n + 1; if AutoW.n % 200 == 0 and os.clock() - AutoW.t0 > 0.003 then task.wait(); AutoW.t0 = os.clock() end
        if type(k) == "string" then
            if type(v) == "number" then local r = ruleFor(k); if r then addEntry("tbl", tbl, k, r, path .. "." .. k) end
            elseif type(v) == "table" and depth < 2 then scanTable(v, depth + 1, visited, path .. "." .. k) end
        end
    end
end
local function scanInstance(root, limit)
    local n = 0
    local function visit(inst)
        for name, val in pairs(inst:GetAttributes()) do if type(val) == "number" then local r = ruleFor(name); if r then addEntry("attr", inst, name, r, inst:GetFullName() .. "@" .. name) end end end
        if inst:IsA("NumberValue") or inst:IsA("IntValue") then local r = ruleFor(inst.Name); if r then addEntry("val", inst, "Value", r, inst:GetFullName()) end
        elseif inst:IsA("ModuleScript") and type(Cap.require) == "function" and (AutoW.loadedSet == nil or AutoW.loadedSet[inst]) then
            local ok, t = pcall(Cap.require, inst); if ok and type(t) == "table" then pcall(scanTable, t, 0, {}, inst:GetFullName()) end
        end
    end
    visit(root)
    for _, d in ipairs(root:GetDescendants()) do n = n + 1; if n > limit then break end; visit(d) end
end
local function modulesNamed(name)
    local key = name:lower()
    if AutoW.byName then return AutoW.byName[key] or {} end
    local c = AutoW.mods[key]; if c then return c end
    c = {}; AutoW.mods[key] = c
    for _, d in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do if d:IsA("ModuleScript") and d.Name:lower() == key then c[#c + 1] = d end end
    return c
end
local WEAPON_MOD_HINT = {"weapon", "gun", "firearm", "tool", "arsenal", "loadout", "shoot", "combat", "fire", "item", "stat", "config", "setting", "data", "viewmodel", "ammo", "bullet", "projectile", "recoil"}
local WEAPON_MOD_SKIP = {"shop", "store", "price", "currency", "quest", "mission", "chat", "leaderboard", "sound", "audio", "anim", "emote", "menu"}
local function weaponishModule(m)
    local own = m.Name:lower()
    for _, s in ipairs(WEAPON_MOD_SKIP) do if string.find(own, s, 1, true) then return false end end
    local full = m:GetFullName():lower()
    for _, h in ipairs(WEAPON_MOD_HINT) do if string.find(full, h, 1, true) then return true end end
    return false
end
local DUMP_PAT = {"fire", "shoot", "shot", "rate", "rpm", "delay", "cool", "interval", "recoil", "spread", "reload", "ammo", "clip", "kick", "bloom"}
local function dumpWeaponCandidates(tool)
    print("[Eclypse] Nada achado automaticamente. Campos numericos candidatos nos modulos ja carregados pelo jogo (cole estas linhas para fixar GameConfig.Weapon):")
    local shown = 0
    local function consider(path, tbl, depth, visited)
        if visited[tbl] or shown >= 120 then return end; visited[tbl] = true
        for k, v in pairs(tbl) do
            AutoW.n = AutoW.n + 1; if AutoW.n % 200 == 0 and os.clock() - AutoW.t0 > 0.003 then task.wait(); AutoW.t0 = os.clock() end
            if type(k) == "string" and shown < 120 then
                if type(v) == "number" then
                    local lk = k:lower()
                    for _, pt in ipairs(DUMP_PAT) do if string.find(lk, pt, 1, true) then shown = shown + 1; print("  " .. path .. "." .. k .. " = " .. tostring(v)); break end end
                elseif type(v) == "table" and depth < 2 then consider(path .. "." .. k, v, depth + 1, visited) end
            end
        end
    end
    if type(Cap.getloadedmodules) == "function" and type(Cap.require) == "function" then
        local ok, mods = pcall(Cap.getloadedmodules)
        if ok and type(mods) == "table" then
            for mi, m in ipairs(mods) do
                if shown >= 120 then break end; if mi % 8 == 0 then task.wait() end
                if typeof(m) == "Instance" and m:IsA("ModuleScript") then
                    local ok2, t = pcall(Cap.require, m)
                    if ok2 and type(t) == "table" then pcall(consider, m:GetFullName(), t, 0, {}) end
                end
            end
        end
    else print("  executor sem getloadedmodules: abra o Dex e me envie o ModuleScript da arma equipada") end
    local cam = Workspace.CurrentCamera
    if cam then for _, c in ipairs(cam:GetChildren()) do print("  filho da camera: " .. c:GetFullName() .. " (" .. c.ClassName .. ")") end end
    print("  Tool equipada: " .. (tool and tool:GetFullName() or "nenhuma"))
end
local function restoreWeapon()
    for tbl, keys in pairs(Patched) do for k, v in pairs(keys) do pcall(function() tbl[k] = v.orig end) end end; Patched = {}
    for _, e in ipairs(AutoW.list) do pcall(writeRef, e, e.orig) end; AutoW.list = {}
end
local function weaponScanJob(tool, char)
    AutoW.scans = AutoW.scans + 1; AutoW.t0 = os.clock()
    AutoW.loadedSet, AutoW.byName = nil, nil
    local loaded
    if type(Cap.getloadedmodules) == "function" then
        local ok, mods = pcall(Cap.getloadedmodules)
        if ok and type(mods) == "table" then
            loaded = mods; local s, bn = {}, {}
            for _, m in ipairs(mods) do
                if typeof(m) == "Instance" then s[m] = true; local k = m.Name:lower(); local l = bn[k]; if not l then l = {}; bn[k] = l end; l[#l + 1] = m end
            end
            AutoW.loadedSet, AutoW.byName = s, bn
        end
    end
    local mask = ""; for _, r in ipairs(WEAPON_RULES) do if get(r.pref, false) then mask = mask .. r.pref end end
    if AutoW.mask ~= mask then AutoW.mask = mask; AutoW.modDone = setmetatable({}, {__mode = "k"}) end
    local roots = {}
    if tool then roots[#roots + 1] = tool; for _, m in ipairs(modulesNamed(tool.Name)) do roots[#roots + 1] = m end end
    if char then roots[#roots + 1] = char end
    local cam = Workspace.CurrentCamera
    if cam then for _, c in ipairs(cam:GetChildren()) do if c:IsA("Model") then roots[#roots + 1] = c; for _, m in ipairs(modulesNamed(c.Name)) do roots[#roots + 1] = m end end end end
    for _, r in ipairs(roots) do
        if not UiMouse.alive then return end
        pcall(scanInstance, r, 400); task.wait(); AutoW.t0 = os.clock()
    end
    if loaded and type(Cap.require) == "function" then
        for i, m in ipairs(loaded) do
            if not UiMouse.alive then return end
            if typeof(m) == "Instance" and not AutoW.modDone[m] then
                AutoW.modDone[m] = true
                if weaponishModule(m) then
                    local ok2, t = pcall(Cap.require, m)
                    if ok2 and type(t) == "table" then pcall(scanTable, t, 0, {}, m:GetFullName()) end
                end
            end
            if i % 40 == 0 and os.clock() - AutoW.t0 > 0.003 then task.wait(); AutoW.t0 = os.clock() end
        end
    end
    for _, rule in ipairs(WEAPON_RULES) do
        if get(rule.pref, false) and AutoW.scans >= 2 and not AutoW.found[rule.pref] and not AutoW.warned[rule.pref] then
            AutoW.warned[rule.pref] = true; warn("[Eclypse] " .. rule.label .. ": nenhum campo correspondente achado (arma equipada: " .. (tool and tool.Name or "nenhuma/Tool") .. ")")
            notify(rule.label, "nada encontrado - veja o console")
            if not AutoW.dumped then AutoW.dumped = true; dumpWeaponCandidates(tool) end
        end
    end
end
local function weaponPatchTick()
    local W = GameConfig.Weapon; local char = LP.Character; local tool = char and char:FindFirstChildOfClass("Tool")
    -- 1) caminho explícito (GameConfig.Weapon preenchido pelo usuário)
    if W.ToolModule and tool and type(Cap.require) == "function" then
        local MAP = {NoRecoil = "wpn_recoil", NoSpread = "wpn_spread", InstantReload = "wpn_reload", InfiniteMagazine = "wpn_ammo", FireCooldown = "wpn_cd"}
        for field, pref in pairs(MAP) do
            local spec = W.Fields[field]; local wanted = get(pref, false)
            if spec then
                local mod = W.ToolModule(tool)
                if mod then local ok, tbl = pcall(Cap.require, mod); if ok and type(tbl) == "table" then for _, key in ipairs(spec.keys) do if tbl[key] ~= nil then
                    Patched[tbl] = Patched[tbl] or {}
                    if wanted then if Patched[tbl][key] == nil then Patched[tbl][key] = {orig = tbl[key]} end; local val = spec.value; if type(val) == "function" then val = val(Prefs) end; tbl[key] = val
                    elseif Patched[tbl][key] ~= nil then tbl[key] = Patched[tbl][key].orig; Patched[tbl][key] = nil end
                end end end end
            end
        end
    end
    -- 2) descoberta automática por nome de campo (em thread separada: nunca varre no frame do Heartbeat)
    local anyOn = false; for _, r in ipairs(WEAPON_RULES) do if get(r.pref, false) then anyOn = true end end
    if anyOn and not AutoW.busy and os.clock() - AutoW.last > 5 then
        AutoW.busy = true
        task.spawn(function()
            local okc, errc = pcall(weaponScanJob, tool, char)
            AutoW.last = os.clock(); AutoW.busy = false
            if not okc and not AutoW.warned.job then AutoW.warned.job = true; warn("[Eclypse] varredura de armas: " .. tostring(errc)) end
        end)
    end
    for i = #AutoW.list, 1, -1 do
        local e = AutoW.list[i]; local on = get(e.rule.pref, false)
        local ok = pcall(function() local want = on and e.rule.value(e.orig) or e.orig; if readRef(e) ~= want then writeRef(e, want) end end)
        if on and ok and not e.logged then e.logged = true; AutoW.nlog = (AutoW.nlog or 0) + 1; if AutoW.nlog <= 15 then print("[Eclypse] " .. e.rule.label .. ": " .. e.path .. "  " .. tostring(e.orig) .. " -> " .. tostring(e.rule.value(e.orig)) .. "  (se nada mudar, troque de arma 1/2/3: o jogo pode copiar o valor ao equipar)") end end
        if (not ok) or (not on) then table.remove(AutoW.list, i); local sn = AutoW.seen[e.ref]; if sn then sn[e.key] = nil end end
    end
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
    Hud.island = new("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 8), Size = UDim2.fromOffset(150, 28), BackgroundColor3 = Color3.new(0, 0, 0), Visible = false}, Overlay); corner(Hud.island, 14); Hud.islandText = label(Hud.island, {Size = UDim2.fromScale(1, 1), Text = "Eclypse", TextSize = 12, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Center}); Hud.islandBusy = 0
    Hud.mobile = new("TextButton", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.fromOffset(44, 44), BackgroundColor3 = Theme.panel, Text = "D", Font = Enum.Font.GothamBlack, TextSize = 18, TextColor3 = Theme.accent, AutoButtonColor = false, Visible = false}, Overlay); corner(Hud.mobile, 22); outline(Hud.mobile, 2, Theme.accent); Hud.mobile.MouseButton1Click:Connect(function() GUI.Enabled = not GUI.Enabled end)
    Hud.amb = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.accent, BorderSizePixel = 0, ZIndex = 0, Visible = false}, Overlay); Hud.ambGrad = new("UIGradient", {Rotation = 90}, Hud.amb)
end
notify = function(title, sub)
    if get("set_island") then
        local text = title .. (sub and (": " .. sub) or ""); Hud.islandText.Text = text; local w = TextService:GetTextSize(text, 12, Enum.Font.GothamBold, Vector2.new(600, 30)).X + 30; tween(Hud.island, {Size = UDim2.fromOffset(math.max(w, 150), 28)}); Hud.islandBusy = os.clock() + 2; Hud.lastIsl = nil
    else
        Hud.toastN = Hud.toastN + 1; local f = new("Frame", {Size = UDim2.fromOffset(210, 40), BackgroundColor3 = Theme.panel, LayoutOrder = Hud.toastN}, Hud.toasts); corner(f, 8); outline(f, 1, Theme.stroke); new("Frame", {Size = UDim2.fromOffset(3, 24), Position = UDim2.fromOffset(8, 8), BackgroundColor3 = Theme.accent, BorderSizePixel = 0}, f); label(f, {Size = UDim2.new(1, -24, 0, 18), Position = UDim2.fromOffset(18, 4), Text = title, TextSize = 12, Font = Enum.Font.GothamBold}); label(f, {Size = UDim2.new(1, -24, 0, 14), Position = UDim2.fromOffset(18, 22), Text = sub or "", TextSize = 11, TextColor3 = Theme.sub}); Debris:AddItem(f, 2.2)
    end
end

local Features = {}
local function updateHud(fps)
    Hud.mark.Visible = get("set_watermark", true) and true or false; if Hud.mark.Visible then local mt = string.format("Eclypse  |  %d fps  |  %d players  |  %s", math.floor(fps + 0.5), #Players:GetPlayers(), os.date("%H:%M")); if Hud.lastMark ~= mt then Hud.lastMark = mt; Hud.markText.Text = mt end end
    local showList = get("set_qaccess") and true or false; Hud.list.Visible = showList
    if showList then
        local n = 0; for _, ft in ipairs(Features) do if ft.on() then n = n + 1; local l = Hud.lines[n]; if not l then l = label(Hud.list, {Size = UDim2.fromOffset(0, 14), AutomaticSize = Enum.AutomaticSize.X, Text = "", TextSize = 11, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Right, LayoutOrder = n}); Hud.lines[n] = l end; local txt = ft.name; if ft.bind and Prefs[ft.bind] then local b = Prefs[ft.bind]; if b.Mode ~= "Always" then txt = txt .. "  [" .. tostring(b.Key) .. "]" end; if bindActive(ft.bind) then txt = txt .. "  ENABLED" end end; l.Text = txt; l.LayoutOrder = n; l.Visible = true end end; for i = n + 1, #Hud.lines do Hud.lines[i].Visible = false end
    end
    Hud.island.Visible = get("set_island") and true or false; if Hud.island.Visible and os.clock() > Hud.islandBusy then local n = 0; for _, ft in ipairs(Features) do if ft.on() then n = n + 1 end end; if Hud.lastIsl ~= n then Hud.lastIsl = n; Hud.islandText.Text = "Eclypse  |  " .. tostring(n) .. " active"; tween(Hud.island, {Size = UDim2.fromOffset(150, 28)}) end end
    Hud.mobile.Visible = get("set_mobile") and true or false; local op = getNum("set_opacity", 50) / 100; local t = 1 - op * 0.45; if Hud.lastT ~= t then Hud.lastT = t; Hud.ambGrad.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, t), NumberSequenceKeypoint.new(0.3, 1), NumberSequenceKeypoint.new(0.7, 1), NumberSequenceKeypoint.new(1, t)}) end; Hud.amb.Visible = (not get("set_showonly")) or GUI.Enabled
end
do
    local function esp_any() return get("esp_on", true) and (get("esp_box") or get("esp_name") or get("esp_skel") or get("esp_wpn") or get("esp_health") or get("esp_distance") or get("esp_head") or get("esp_tracers") or get("esp_path")) end
    local function f(name, fn, bind) Features[#Features + 1] = {name = name, on = fn, bind = bind} end
    f("Aimbot", function() return get("aim_on") end, "aim_key"); f("Silent Aim", function() return get("sil_on") end, "sil_key"); f("Triggerbot", function() return get("trg_on") end, "trg_key"); f("Ragebot", function() return get("rage_on") end, "rage_key"); f("Kill All", function() return get("ra_kill") end, "ra_kill_key"); f("Speed", function() return get("mv_speed") end, "mv_speed_key"); f("Fly", function() return get("mv_fly") end, "mv_fly_key"); f("Third Person", function() return get("cam_third") end, "cam_key"); f("Bhop", function() return get("misc_bhop") end); f("ESP", esp_any); f("Anti AFK", function() return get("misc_afk") end); f("No Recoil", function() return get("wpn_recoil") end); f("Instant Reload", function() return get("wpn_reload") end); f("Infinite Magazine", function() return get("wpn_ammo") end); f("Custom Fire Cooldown", function() return get("wpn_cd") end)
end

local currentSpectators
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
    if HB.slow >= 0.5 then HB.slow = 0; EX.timed("weaponPatchTick", weaponPatchTick); local want = get("misc_spect") or get("misc_antispect"); local specs = want and currentSpectators() or {}; if get("misc_spect") and #specs > 0 then Hud.spec.Text = "Spectators\n" .. table.concat(specs, "\n"); Hud.spec.Visible = true else Hud.spec.Visible = false end; local pause = get("misc_antispect") and #specs > 0; if pause ~= HB.paused then HB.paused = pause; notify("Anti Spectate", pause and "features paused" or "features resumed") end end
    if HB.hud >= 0.2 then HB.hud = 0; EX.timed("updateHud", updateHud, fpsAvg) end
end

local function makeCircle() local f = new("Frame", {Size = UDim2.fromOffset(100, 100), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Visible = false}, Overlay); new("UICorner", {CornerRadius = UDim.new(1, 0)}, f); new("UIStroke", {Thickness = 1, Color = Theme.accent}, f); return f end
local fovCircle, aimCircle = makeCircle(), makeCircle()
local silMark = new("Frame", {Size = UDim2.fromOffset(10, 10), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Theme.accent, Visible = false}, Overlay); corner(silMark, 5)
local function updateCircles(cam) local vs = cam.ViewportSize; local c = UDim2.fromOffset(vs.X / 2, vs.Y / 2); local show = get("sil_fovcircle"); local sOn = show and get("sil_on") and not get("sil_any"); fovCircle.Visible = sOn and true or false; if sOn then local d = getNum("sil_fov", 120) * 2; fovCircle.Position = c; fovCircle.Size = UDim2.fromOffset(d, d) end; local aOn = show and get("aim_on"); aimCircle.Visible = aOn and true or false; if aOn then local d = getNum("aim_radius", 120) * 2; aimCircle.Position = c; aimCircle.Size = UDim2.fromOffset(d, d) end; if get("sil_show") and Silent.target then local v, on = cam:WorldToViewportPoint(Silent.target.pos); silMark.Visible = on; if on then silMark.Position = UDim2.fromOffset(v.X, v.Y) end else silMark.Visible = false end end

currentSpectators = function() local probe, out = GameConfig.SpectateProbe or function(plr) local function refs(v) return v == LP or v == LP.Character or v == LP.Name or v == LP.DisplayName or v == LP.UserId end; for k, v in pairs(plr:GetAttributes()) do if tostring(k):lower():find("spect") and refs(v) then return true end end; for _, d in ipairs(plr:GetDescendants()) do if (d:IsA("ObjectValue") or d:IsA("StringValue") or d:IsA("IntValue")) and d.Name:lower():find("spect") and refs(d.Value) then return true end end; return false end, {}; for _, plr in ipairs(Players:GetPlayers()) do if plr ~= LP then local ok, r = pcall(probe, plr); if ok and r then out[#out + 1] = plr.Name end end end; return out end

local gPoll, gTrack, gCircles, gAim, gSilent, gRage, gKill, gTrig, gESP = guard("binds", pollBinds), guard("track", trackEntities), guard("circles", updateCircles), guard("aimbot", runAimbot), guard("silent", runSilent), guard("ragebot", runRage), guard("killall", runKillAll), guard("trigger", runTrigger), guard("esp", renderESP)
local gHB = guard("heartbeat", onHeartbeat)
local gNPC = guard("npc", initNPCs)
local rapidLast, bulletLast = 0, 0
local gRapid = guard("rapid", function() if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then return end; if UserInputService:GetFocusedTextBox() or GUI.Enabled then return end; local now = os.clock(); if get("wpn_rapid") and now - rapidLast > 0.04 then rapidLast = now; clickFire() end; if get("trc_on") and now - bulletLast > 0.1 then bulletLast = now; spawnBulletTracer() end end)

-- Mira só roda em partida: menu fechado, sem caixa de texto, personagem vivo e mouse travado no centro (cursor livre = lobby/menu do jogo)
local function aimAllowed()
    if GUI.Enabled or Confirm.Visible then return false end
    if UserInputService:GetFocusedTextBox() then return false end
    local c = LP.Character; local h = c and c:FindFirstChildOfClass("Humanoid")
    if not h or h.Health <= 0 then return false end
    if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then return true end
    local cam, head = Workspace.CurrentCamera, c:FindFirstChild("Head")
    return cam ~= nil and head ~= nil and (cam.CFrame.Position - head.Position).Magnitude < 2
end
pcall(function() RunService:UnbindFromRenderStep("DrxMain") end)
RunService:BindToRenderStep("DrxMain", Enum.RenderPriority.Camera.Value + 1, function(dt) FrameNo = FrameNo + 1; fpsAvg = fpsAvg + (1 / math.max(dt, 1e-4) - fpsAvg) * 0.05; gPoll(); local cam = Workspace.CurrentCamera; if not cam then return end; if get("aim_on") or get("sil_on") or get("rage_on") or get("trg_on") then gNPC() end; gTrack(); gCircles(cam); if HB.paused or not aimAllowed() then Silent.target = nil; Silent.shooting = false else gAim(cam, dt); gSilent(cam, dt); gRage(cam, dt); gKill(cam, dt); gTrig(cam, dt) end; gESP(cam, dt); gRapid() end)
Conns[#Conns + 1] = RunService.Heartbeat:Connect(function(dt) gHB(dt) end)
Conns[#Conns + 1] = LP.Idled:Connect(function() if get("misc_afk") then pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end) end end)

local dragging, dragStart, startPos = false, nil, nil
local function menuMatch(input, mk) return (input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == mk.Key) or (input.UserInputType == Enum.UserInputType.MouseButton1 and mk.Key == "LMB") or (input.UserInputType == Enum.UserInputType.MouseButton2 and mk.Key == "RMB") or (input.UserInputType == Enum.UserInputType.MouseButton3 and mk.Key == "MMB") end
Conns[#Conns + 1] = UserInputService.InputBegan:Connect(function(input, processed) if input.UserInputType == Enum.UserInputType.MouseButton1 and (not processed) and get("trc_on") and not GUI.Enabled then bulletLast = os.clock(); pcall(spawnBulletTracer) end; if processed then return end; local mk = get("misc_menukey", {Key = "RightShift", Mode = "Toggle"}); local match = menuMatch(input, mk); if mk.Mode == "Toggle" and match then GUI.Enabled = not GUI.Enabled elseif mk.Mode == "Hold" and match then GUI.Enabled = true end end)
Conns[#Conns + 1] = UserInputService.InputEnded:Connect(function(input) local mk = get("misc_menukey", {Key = "RightShift", Mode = "Toggle"}); if mk.Mode == "Hold" and menuMatch(input, mk) then GUI.Enabled = false end; if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false; activeSlider = nil end end)
TopBar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; dragStart = input.Position; startPos = Main.Position end end)
Conns[#Conns + 1] = UserInputService.InputChanged:Connect(function(input) if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then local d = input.Position - dragStart; Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y) end; if activeSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then if activeSlider.track and activeSlider.track.Parent then local pct = math.clamp((input.Position.X - activeSlider.track.AbsolutePosition.X) / math.max(activeSlider.track.AbsoluteSize.X, 1), 0, 1); activeSlider.update(pct) else activeSlider = nil end end end)

EX.step(88, "Finalizing...")
local cleaned = false
local function cleanup()
    if cleaned then return end; cleaned = true; if shared.DrxCleanup == cleanup then shared.DrxCleanup = nil end; Booted = false; if EX.destroyLoading then pcall(EX.destroyLoading) end; Silent.alive = false; Silent.target = nil; MouseDeltaHook.alive = false; pcall(function() RunService:UnbindFromRenderStep("DrxMain") end); for _, c in ipairs(Conns) do pcall(function() c:Disconnect() end) end; UiMouse.setOpen(false); UiMouse.alive = false; stopFly(); restoreWeapon(); for k, e in pairs(ESP) do destroyESP(e); ESP[k] = nil end; if HB.tp then pcall(function() LP.CameraMaxZoomDistance = 128; LP.CameraMinZoomDistance = 0.5 end) end; Overlay:Destroy(); if GUI.Parent then GUI:Destroy() end
end
shared.DrxCleanup = cleanup
doUnload = cleanup
GUI.Destroying:Connect(cleanup)
UiMouse.setOpen(GUI.Enabled)
Booted = true
print("[Eclypse V27] pronto | silent-hook=" .. (SilentHooks.done and tostring(Silent.hooked) or "instala ao ligar o Silent") .. " | Build=" .. GameConfig.Build)
do
    local L = EX.Load
    L.target = 100; L.text = "Ready"
    local waited = 0
    while not L.ready and waited < 8 do waited = waited + task.wait() end
    task.wait(0.2)
    if L.root then pcall(function() TweenService:Create(L.root, TweenInfo.new(0.5), {GroupTransparency = 1}):Play() end) end
    task.wait(0.55)
    pcall(EX.destroyLoading)
    L.active = false
    pcall(function() GUI.Enabled = true end)
    task.wait(0.25)
    if EX.revealCard then pcall(EX.revealCard) end
end
