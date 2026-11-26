-- Sonic Hub V25 — Aimbot + Silent + ESP (reescrito)
-- Executor necessário para: getgenv, hookmetamethod, checkcaller, getnamecallmethod, mousemoverel
-- Se o executor não suportar hook, o menu e o ESP ainda funcionam; silent aim fica indisponível.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ============================================================
-- LIMPEZA
-- ============================================================
if shared.SonicHubCleanup then pcall(shared.SonicHubCleanup) end
for _, name in ipairs({"SonicHub", "SonicHubOverlay"}) do
    local a = PlayerGui:FindFirstChild(name); if a then a:Destroy() end
    local b = CoreGui:FindFirstChild(name); if b then b:Destroy() end
end

-- ============================================================
-- CONFIG / PREFS
-- ============================================================
local Prefs = {}
local function set(k, v) Prefs[k] = v end
local function get(k, d) local v = Prefs[k]; if v == nil then return d end; return v end
local function getNum(k, d) local v = tonumber(get(k, d)); if not v or v ~= v then return d end; return v end

-- ============================================================
-- UTIL
-- ============================================================
local function viewportMouse()
    local m = UserInputService:GetMouseLocation()
    local inset = Vector2.new(0, 36)
    pcall(function()
        local i = GuiService:GetGuiInset()
        if typeof(i) == "Vector2" then inset = i
        elseif type(i) == "table" and typeof(i[1]) == "Vector2" then inset = i[1] end
    end)
    return Vector2.new(m.X, m.Y) - inset
end

local function isAlive(char)
    return char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0
end

local function isVisible(targetChar, part)
    local cam = Workspace.CurrentCamera
    local myChar = LocalPlayer.Character
    if not cam or not myChar or not part then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {myChar, targetChar}
    local origin = cam.CFrame.Position
    local result = Workspace:Raycast(origin, part.Position - origin, params)
    return result == nil
end

local function getPart(char, bone)
    if not char then return nil end
    local b = bone or "Head"
    return char:FindFirstChild(b) or char:FindFirstChild("HumanoidRootPart")
end

-- ============================================================
-- PALETA / UI HELPERS
-- ============================================================
local P = {
    bg = Color3.fromRGB(10, 12, 16), glass = Color3.fromRGB(20, 24, 32),
    glassHead = Color3.fromRGB(30, 36, 48), stroke = Color3.fromRGB(50, 60, 80),
    text = Color3.fromRGB(230, 240, 255), sub = Color3.fromRGB(130, 145, 170),
    accent = Color3.fromRGB(180, 255, 0), red = Color3.fromRGB(255, 60, 90),
    track = Color3.fromRGB(35, 42, 55), ink = Color3.fromRGB(10, 15, 20),
}
local function new(cls, props, parent)
    local i = Instance.new(cls); for k, v in pairs(props) do i[k] = v end
    if parent then i.Parent = parent end; return i
end
local function corner(i, r) return new("UICorner", {CornerRadius = UDim.new(0, r)}, i) end
local function outline(i, t, c) return new("UIStroke", {Color = c or P.stroke, Thickness = t or 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, i) end
local function label(parent, props)
    props.BackgroundTransparency = 1; props.Font = props.Font or Enum.Font.Gotham
    props.TextColor3 = props.TextColor3 or P.text; props.TextSize = props.TextSize or 14
    props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
    return new("TextLabel", props, parent)
end
local TWEEN = TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local function tween(i, p) TweenService:Create(i, TWEEN, p):Play() end

-- ============================================================
-- GUI PRINCIPAL
-- ============================================================
local GUI = new("ScreenGui", {Name = "SonicHub", ResetOnSpawn = false, DisplayOrder = 10, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Enabled = false}, PlayerGui)
local Overlay = new("ScreenGui", {Name = "SonicHubOverlay", ResetOnSpawn = false, DisplayOrder = 5, IgnoreGuiInset = false}, PlayerGui)

local Main = new("Frame", {Size = UDim2.fromOffset(780, 580), Position = UDim2.new(0.5, -390, 0.5, -290), BackgroundColor3 = P.bg, BackgroundTransparency = 0.05, ClipsDescendants = true}, GUI)
corner(Main, 12); outline(Main, 1.5, P.stroke)

local TitleBar = new("Frame", {Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = P.glassHead, BackgroundTransparency = 0.2}, Main)
corner(TitleBar, 12)
label(TitleBar, {Size = UDim2.fromOffset(220, 46), Position = UDim2.fromOffset(18, 0), Text = "SONIC HUB V25", Font = Enum.Font.FredokaOne, TextSize = 22, TextColor3 = P.text})
local closeBtn = new("TextButton", {Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, -38, 0.5, -14), BackgroundColor3 = P.glass, Text = "x", TextColor3 = P.red, Font = Enum.Font.GothamBold, TextSize = 16, AutoButtonColor = false}, TitleBar)
corner(closeBtn, 6); closeBtn.MouseButton1Click:Connect(function() GUI:Destroy() end)

local Body = new("Frame", {Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 1, -46), BackgroundTransparency = 1}, Main)
local Sidebar = new("Frame", {Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(170, 514), BackgroundColor3 = P.glass, BackgroundTransparency = 0.4}, Body)
corner(Sidebar, 10); outline(Sidebar, 1, P.stroke)
local NavList = new("ScrollingFrame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ScrollBarThickness = 0, AutomaticCanvasSize = Enum.AutomaticSize.Y}, Sidebar)
new("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, NavList)
new("UIPadding", {PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)}, NavList)

local ContentArea = new("Frame", {Position = UDim2.fromOffset(190, 10), Size = UDim2.fromOffset(580, 514), BackgroundTransparency = 1}, Body)
local PageTitle = label(ContentArea, {Size = UDim2.new(1, 0, 0, 30), Text = "", Font = Enum.Font.GothamBold, TextSize = 24})
local PageSub = label(ContentArea, {Size = UDim2.new(1, 0, 0, 18), Position = UDim2.fromOffset(2, 30), Text = "", TextSize = 12, TextColor3 = P.sub})
local Scroll = new("ScrollingFrame", {Position = UDim2.fromOffset(0, 56), Size = UDim2.new(1, 0, 1, -56), BackgroundTransparency = 1, ScrollBarThickness = 3, ScrollBarImageColor3 = P.accent, AutomaticCanvasSize = Enum.AutomaticSize.Y}, ContentArea)
new("UIListLayout", {Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder}, Scroll)
new("UIPadding", {PaddingRight = UDim.new(0, 8)}, Scroll)

-- ============================================================
-- WIDGETS
-- ============================================================
local renderers = {}
local function CreateGroup(parent, title)
    local g = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = P.glass, BackgroundTransparency = 0.6}, parent)
    corner(g, 8); outline(g, 1, P.stroke)
    new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}, g)
    local head = new("TextButton", {Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Text = "", LayoutOrder = 1}, g)
    label(head, {Size = UDim2.new(1, -25, 1, 0), Position = UDim2.fromOffset(12, 0), Text = title, TextSize = 12, TextColor3 = P.sub})
    local chev = label(head, {Size = UDim2.fromOffset(18, 30), Position = UDim2.new(1, -22, 0, 0), Text = "v", TextColor3 = P.sub})
    local body = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 2}, g)
    new("UIListLayout", {Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder}, body)
    new("UIPadding", {PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12)}, body)
    head.MouseButton1Click:Connect(function() body.Visible = not body.Visible; tween(chev, {Rotation = body.Visible and 0 or -90}) end)
    return body
end

local function CreateToggle(parent, name, key, default)
    Prefs[key] = Prefs[key] or default
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1}, parent)
    label(row, {Size = UDim2.new(0.8, 0, 1, 0), Text = name, TextSize = 13})
    local sw = new("TextButton", {Size = UDim2.fromOffset(34, 18), Position = UDim2.new(1, -34, 0.5, -9), BackgroundColor3 = P.track, Text = "", AutoButtonColor = false}, row)
    corner(sw, 9); outline(sw, 1, P.stroke)
    local knob = new("Frame", {Size = UDim2.fromOffset(12, 12), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = P.sub}, sw); corner(knob, 6)
    local function render()
        local on = get(key)
        tween(sw, {BackgroundColor3 = on and P.accent or P.track})
        tween(knob, {Position = on and UDim2.fromOffset(19, 3) or UDim2.fromOffset(3, 3), BackgroundColor3 = on and P.ink or P.sub})
    end
    renderers[key] = render
    sw.MouseButton1Click:Connect(function() set(key, not get(key)); render() end)
    render()
end

local function CreateSlider(parent, name, key, min, max, default, suffix)
    Prefs[key] = Prefs[key] or default
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1}, parent)
    label(row, {Size = UDim2.new(0.7, 0, 0, 18), Text = name, TextSize = 13})
    local val = label(row, {Size = UDim2.new(0.3, 0, 0, 18), Position = UDim2.new(0.7, 0, 0, 0), Text = tostring(get(key)) .. (suffix or ""), TextSize = 12, TextColor3 = P.sub, TextXAlignment = Enum.TextXAlignment.Right})
    local track = new("Frame", {Size = UDim2.new(1, 0, 0, 4), Position = UDim2.fromOffset(0, 24), BackgroundColor3 = P.track}, row); corner(track, 2)
    local fill = new("Frame", {Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = P.accent}, track); corner(fill, 2)
    local knob = new("Frame", {Size = UDim2.fromOffset(12, 12), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = P.text}, track); corner(knob, 6)
    local function render()
        local v = getNum(key, default); local pct = (v - min) / math.max(max - min, 1)
        tween(fill, {Size = UDim2.new(pct, 0, 1, 0)}); tween(knob, {Position = UDim2.new(pct, 0, 0.5, 0)})
        val.Text = tostring(v) .. (suffix or "")
    end
    renderers[key] = render
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local pct = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            set(key, math.floor(min + pct * (max - min) + 0.5)); render()
        end
    end)
    render()
end

local function CreateDropdown(parent, name, key, options, default)
    Prefs[key] = Prefs[key] or default
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1}, parent)
    label(row, {Size = UDim2.new(1, 0, 0, 18), Text = name, TextSize = 13})
    local box = new("TextButton", {Size = UDim2.new(1, 0, 0, 22), Position = UDim2.fromOffset(0, 20), BackgroundColor3 = P.track, Text = "", AutoButtonColor = false}, row); corner(box, 6)
    local txt = label(box, {Size = UDim2.new(1, -10, 1, 0), Position = UDim2.fromOffset(8, 0), Text = tostring(get(key)), TextSize = 12, TextColor3 = P.text})
    local open = false
    local list = new("Frame", {Size = UDim2.new(1, 0, 0, #options * 20), Position = UDim2.fromOffset(0, 42), BackgroundColor3 = P.glass, Visible = false, ZIndex = 10}, row); corner(list, 6)
    for i, opt in ipairs(options) do
        local b = new("TextButton", {Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, (i - 1) * 20), BackgroundTransparency = 1, Text = opt, TextSize = 12, TextColor3 = P.text, ZIndex = 11}, list)
        b.MouseButton1Click:Connect(function() set(key, opt); txt.Text = opt; list.Visible = false; open = false; if renderers[key] then renderers[key]() end end)
    end
    box.MouseButton1Click:Connect(function() open = not open; list.Visible = open end)
    renderers[key] = function() txt.Text = tostring(get(key)) end
end

-- ============================================================
-- PÁGINAS
-- ============================================================
local Pages, NavButtons, ActivePage = {}, {}, ""
local function SwitchPage(name)
    ActivePage = name; PageTitle.Text = name
    for _, v in ipairs(Scroll:GetChildren()) do if v:IsA("GuiObject") then v:Destroy() end end
    for n, b in pairs(NavButtons) do
        local sel = (n == name)
        tween(b.bg, {BackgroundColor3 = sel and P.glassHead or P.track, BackgroundTransparency = sel and 0.2 or 0.6})
        tween(b.txt, {TextColor3 = sel and P.text or P.sub})
    end
    if Pages[name] then Pages[name]() end
end
local function AddNav(name)
    local btn = new("TextButton", {Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = P.track, BackgroundTransparency = 0.6, Text = "", AutoButtonColor = false}, NavList); corner(btn, 6)
    local txt = label(btn, {Size = UDim2.new(1, -12, 1, 0), Position = UDim2.fromOffset(12, 0), Text = name, TextSize = 13, TextColor3 = P.sub})
    NavButtons[name] = {bg = btn, txt = txt}
    btn.MouseButton1Click:Connect(function() SwitchPage(name) end)
end

Pages["Aimbot"] = function()
    PageSub.Text = "camera lock / mouse lock / smooth"
    local g1 = CreateGroup(Scroll, "Aimbot")
    CreateToggle(g1, "Enabled", "aim_on", false)
    CreateDropdown(g1, "Method", "aim_method", {"Camera Lock", "Mouse Lock"}, "Camera Lock")
    CreateDropdown(g1, "Target Mode", "aim_target", {"FOV", "Closest to Camera", "Closest to Mouse"}, "FOV")
    CreateDropdown(g1, "Bone", "aim_bone", {"Head", "UpperTorso", "HumanoidRootPart", "Torso"}, "Head")
    CreateSlider(g1, "FOV", "aim_fov", 10, 600, 120)
    CreateSlider(g1, "Smoothness", "aim_smooth", 1, 30, 6)
    CreateToggle(g1, "Prediction", "aim_pred", false)
    CreateSlider(g1, "Prediction X", "aim_predx", 0, 2, 0.165)
    CreateToggle(g1, "Visible Only", "aim_visible", false)
    CreateToggle(g1, "Team Check", "aim_team", true)
    CreateToggle(g1, "Sticky", "aim_sticky", false)

    local g2 = CreateGroup(Scroll, "Silent Aim")
    CreateToggle(g2, "Enabled", "sil_on", false)
    CreateDropdown(g2, "Bone", "sil_bone", {"Head", "UpperTorso", "HumanoidRootPart", "Torso"}, "Head")
    CreateSlider(g2, "FOV", "sil_fov", 10, 600, 200)
    CreateSlider(g2, "Hit Chance", "sil_hit", 0, 100, 95)
    CreateToggle(g2, "Visible Only", "sil_visible", false)
    CreateToggle(g2, "Team Check", "sil_team", true)
end

Pages["Trigger Bot"] = function()
    PageSub.Text = "auto fire on target"
    local g1 = CreateGroup(Scroll, "Trigger Bot")
    CreateToggle(g1, "Enabled", "trg_on", false)
    CreateDropdown(g1, "Mode", "trg_mode", {"Hold", "Toggle"}, "Toggle")
    CreateDropdown(g1, "Hotkey", "trg_key", {"Always", "RMB", "E", "X", "Shift"}, "E")
    CreateDropdown(g1, "Hit Zone", "trg_zone", {"Head", "UpperTorso", "HumanoidRootPart", "Torso"}, "Head")
    CreateSlider(g1, "Hit Chance", "trg_hit", 0, 100, 100)
    CreateSlider(g1, "Delay (ms)", "trg_delay", 0, 500, 0)
    CreateSlider(g1, "Max Distance", "trg_dist", 50, 5000, 800)
end

Pages["ESP"] = function()
    PageSub.Text = "players & npcs"
    local g1 = CreateGroup(Scroll, "General")
    CreateToggle(g1, "Enabled", "esp_on", false)
    CreateToggle(g1, "Team Check", "esp_team", true)
    CreateToggle(g1, "Visible Only", "esp_visible", false)
    CreateToggle(g1, "Include NPCs", "esp_npc", true)
    CreateSlider(g1, "Max Distance", "esp_dist", 100, 5000, 1000)

    local g2 = CreateGroup(Scroll, "Box")
    CreateToggle(g2, "Box", "esp_box", true)
    CreateDropdown(g2, "Style", "esp_boxstyle", {"Full", "Corner", "3D"}, "Corner")
    CreateSlider(g2, "Thickness", "esp_boxtick", 1, 5, 1)
    CreateSlider(g2, "Fill", "esp_fill", 0, 1, 0)

    local g3 = CreateGroup(Scroll, "Elements")
    CreateToggle(g3, "Name", "esp_name", true)
    CreateToggle(g3, "Distance", "esp_distlabel", true)
    CreateToggle(g3, "Health Bar", "esp_health", true)
    CreateToggle(g3, "Skeleton", "esp_skel", false)
    CreateToggle(g3, "Tracer", "esp_tracer", false)
    CreateDropdown(g3, "Tracer Origin", "esp_trorigin", {"Bottom", "Center", "Mouse"}, "Bottom")
    CreateToggle(g3, "Head Dot", "esp_headdot", false)
    CreateToggle(g3, "Weapon", "esp_weapon", false)
    CreateToggle(g3, "Chams", "esp_chams", false)

    local g4 = CreateGroup(Scroll, "Color")
    CreateToggle(g4, "Rainbow", "esp_rainbow", false)
    CreateToggle(g4, "Team Color", "esp_teamcol", false)
    CreateDropdown(g4, "Color", "esp_color", {"Lime", "Red", "Cyan", "White", "Pink"}, "Lime")
end

Pages["Extras"] = function()
    PageSub.Text = "weapon mods"
    local g1 = CreateGroup(Scroll, "Gun")
    CreateToggle(g1, "No Recoil", "wpn_recoil", false)
    CreateToggle(g1, "Instant Reload", "wpn_reload", false)
end

AddNav("Aimbot"); AddNav("Trigger Bot"); AddNav("ESP"); AddNav("Extras")
SwitchPage("Aimbot")

-- ============================================================
-- HOTKEY HELPERS
-- ============================================================
local function isKeyDown(opt)
    if opt == "Always" then return true end
    if opt == "RMB" then return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) end
    if opt == "E" then return UserInputService:IsKeyDown(Enum.KeyCode.E) end
    if opt == "X" then return UserInputService:IsKeyDown(Enum.KeyCode.X) end
    if opt == "Shift" then return UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) end
    return false
end

-- ============================================================
-- TARGETING
-- ============================================================
local stickyChar = nil
local function findTarget(fov, bone, mode, teamCheck, visibleOnly)
    local cam = Workspace.CurrentCamera
    if not cam then return nil end
    local mouse = viewportMouse()
    local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
    local closest, closestScore = nil, math.huge

    local function consider(char, plr)
        if not isAlive(char) then return end
        if teamCheck and plr and plr.Team == LocalPlayer.Team then return end
        local part = getPart(char, bone)
        if not part then return end
        if visibleOnly and not isVisible(char, part) then return end
        local sp, onScreen = cam:WorldToViewportPoint(part.Position)
        if not onScreen then return end
        local screenPos = Vector2.new(sp.X, sp.Y)
        local distPx
        if mode == "Closest to Camera" then
            distPx = (part.Position - cam.CFrame.Position).Magnitude
        elseif mode == "Closest to Mouse" then
            distPx = (screenPos - mouse).Magnitude
        else
            distPx = (screenPos - center).Magnitude
        end
        if distPx > fov then return end
        if distPx < closestScore then
            closestScore = distPx
            closest = {char = char, part = part}
        end
    end

    -- sticky: mantém alvo atual se ainda válido e dentro do FOV
    if get("aim_sticky") and stickyChar and isAlive(stickyChar) then
        local part = getPart(stickyChar, bone)
        if part then
            local sp, onScreen = cam:WorldToViewportPoint(part.Position)
            if onScreen then
                local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                if d <= fov then return {char = stickyChar, part = part} end
            end
        end
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then consider(plr.Character, plr) end
    end
    if get("esp_npc", true) then
        for _, obj in ipairs(Workspace:GetChildren()) do
            if obj:IsA("Model") and obj ~= LocalPlayer.Character and obj:FindFirstChild("Humanoid") and not Players:GetPlayerFromCharacter(obj) then
                consider(obj, nil)
            end
        end
    end
    return closest
end

-- ============================================================
-- AIMBOT LOOP
-- ============================================================
RunService.RenderStepped:Connect(function()
    pcall(function()
        if not get("aim_on") then stickyChar = nil; return end
        local target = findTarget(getNum("aim_fov", 120), get("aim_bone", "Head"), get("aim_target", "FOV"), get("aim_team", true), get("aim_visible", false))
        if not target then stickyChar = nil; return end
        stickyChar = target.char

        local cam = Workspace.CurrentCamera
        if not cam then return end
        local aimPos = target.part.Position
        if get("aim_pred") and target.part.Parent then
            local vel = target.part.AssemblyLinearVelocity
            if vel then aimPos = aimPos + vel * getNum("aim_predx", 0.165) end
        end

        if get("aim_method", "Camera Lock") == "Camera Lock" then
            local smooth = getNum("aim_smooth", 6)
            local cf = CFrame.new(cam.CFrame.Position, aimPos)
            cam.CFrame = cam.CFrame:Lerp(cf, 1 / math.max(smooth, 1))
        else
            local sp, onScreen = cam:WorldToViewportPoint(aimPos)
            if onScreen then
                local mouse = viewportMouse()
                local targetScreen = Vector2.new(sp.X, sp.Y)
                local delta = (targetScreen - mouse) * (1 / math.max(getNum("aim_smooth", 6), 1))
                pcall(function() mousemoverel(delta.X, delta.Y) end)
            end
        end
    end)
end)

-- ============================================================
-- TRIGGER BOT
-- ============================================================
local trgPrev, trgToggled, lastFire = false, false, 0
RunService.RenderStepped:Connect(function()
    pcall(function()
        if not get("trg_on") then trgToggled = false; return end
        local keyDown = isKeyDown(get("trg_key", "E"))
        local shouldFire
        if get("trg_mode", "Toggle") == "Toggle" then
            if keyDown and not trgPrev then trgToggled = not trgToggled end
            trgPrev = keyDown
            shouldFire = trgToggled
        else
            shouldFire = keyDown
        end
        if not shouldFire then return end
        if os.clock() - lastFire < getNum("trg_delay", 0) / 1000 then return end
        local target = findTarget(60, get("trg_zone", "Head"), "FOV", true, false)
        if not target then return end
        if math.random(1, 100) > getNum("trg_hit", 100) then return end
        lastFire = os.clock()
        pcall(function()
            local g = getgenv()
            if type(g) == "table" and type(g.mouse1click) == "function" then g.mouse1click() end
        end)
    end)
end)

-- ============================================================
-- SILENT AIM (hook namecall)
-- ============================================================
local silentOk = false
local silentPart = nil
RunService.RenderStepped:Connect(function()
    pcall(function()
        if not get("sil_on") then silentPart = nil; return end
        local t = findTarget(getNum("sil_fov", 200), get("sil_bone", "Head"), "FOV", get("sil_team", true), get("sil_visible", false))
        silentPart = t and t.part or nil
    end)
end)

pcall(function()
    if type(hookmetamethod) ~= "function" or type(getnamecallmethod) ~= "function" or type(checkcaller) ~= "function" then return end
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if not checkcaller() and get("sil_on") and silentPart and silentPart.Parent then
            if math.random(1, 100) <= getNum("sil_hit", 95) then
                local args = {...}
                if method == "Raycast" and self == Workspace then
                    local origin = args[1]
                    if typeof(origin) == "Vector3" then
                        local dir = (silentPart.Position - origin).Unit * 1000
                        args[2] = dir
                        return oldNamecall(self, table.unpack(args))
                    end
                elseif method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" then
                    local ray = args[1]
                    if typeof(ray) == "Ray" then
                        args[1] = Ray.new(ray.Origin, (silentPart.Position - ray.Origin).Unit * 1000)
                        return oldNamecall(self, table.unpack(args))
                    end
                end
            end
        end
        return oldNamecall(self, ...)
    end)
    silentOk = true
end)

-- ============================================================
-- ESP
-- ============================================================
local ESP_ENTRIES = {}
local BONES_R15 = {{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"}}
local BONES_R6 = {{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"}}

local function espColor(plr)
    if get("esp_teamcol") and plr and plr.Team and plr.Team == LocalPlayer.Team then return plr.TeamColor.Color end
    if get("esp_rainbow") then return Color3.fromHSV((os.clock() * 0.2) % 1, 1, 1) end
    local map = { Lime = Color3.fromRGB(180,255,0), Red = Color3.fromRGB(255,60,60), Cyan = Color3.fromRGB(0,255,255), White = Color3.fromRGB(255,255,255), Pink = Color3.fromRGB(255,105,180) }
    return map[get("esp_color", "Lime")] or Color3.fromRGB(180,255,0)
end

local function createESP()
    local e = {Bones = {}, Corners = {}}
    e.Box = new("Frame", {BackgroundTransparency = 1, Visible = false}, Overlay)
    e.Stroke = new("UIStroke", {ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Thickness = 1}, e.Box)
    e.Fill = new("Frame", {Size = UDim2.fromScale(1,1), BackgroundTransparency = 0.7, Visible = false}, e.Box)
    e.Label = new("TextLabel", {BackgroundTransparency = 1, Size = UDim2.fromOffset(240,20), AnchorPoint = Vector2.new(0.5,1), Font = Enum.Font.GothamBold, TextStrokeTransparency = 0.4, Visible = false}, Overlay)
    e.HealthBack = new("Frame", {BackgroundColor3 = Color3.fromRGB(15,20,28), Visible = false}, Overlay); corner(e.HealthBack, 2)
    e.HealthFill = new("Frame", {AnchorPoint = Vector2.new(0,1), Position = UDim2.new(0,0,1,0), Visible = false}, e.HealthBack); corner(e.HealthFill, 2)
    e.Tracer = new("Frame", {AnchorPoint = Vector2.new(0.5,0.5), Visible = false}, Overlay)
    e.HeadDot = new("Frame", {Size = UDim2.fromOffset(6,6), AnchorPoint = Vector2.new(0.5,0.5), Visible = false}, Overlay); corner(e.HeadDot, 3)
    for i=1,8 do e.Corners[i] = new("Frame", {Visible=false}, Overlay) end
    return e
end
local function hideESP(e)
    e.Box.Visible=false; e.Fill.Visible=false; e.Label.Visible=false; e.HealthBack.Visible=false; e.HealthFill.Visible=false; e.Tracer.Visible=false; e.HeadDot.Visible=false
    for _,b in ipairs(e.Bones) do b.Visible=false end
    for _,c in ipairs(e.Corners) do c.Visible=false end
end
local function destroyESP(e)
    e.Box:Destroy(); e.Label:Destroy(); e.HealthBack:Destroy(); e.Tracer:Destroy(); e.HeadDot:Destroy()
    for _,b in ipairs(e.Bones) do b:Destroy() end
    for _,c in ipairs(e.Corners) do c:Destroy() end
end

local function projectBox(cam, char)
    local cf, size = char:GetBoundingBox()
    if not cf or not size then return nil end
    local minX,minY,maxX,maxY = math.huge,math.huge,-math.huge,-math.huge; local any=false
    for ix=-1,1,2 do for iy=-1,1,2 do for iz=-1,1,2 do
        local p = cf:PointToWorldSpace(Vector3.new(ix*size.X/2, iy*size.Y/2, iz*size.Z/2))
        local sp = cam:WorldToViewportPoint(p)
        if sp.Z > 0 then any=true; minX=math.min(minX,sp.X); maxX=math.max(maxX,sp.X); minY=math.min(minY,sp.Y); maxY=math.max(maxY,sp.Y) end
    end end end
    if not any then return nil end
    local w,h = maxX-minX, maxY-minY
    if w<=0 or h<=0 or w>800 or h>800 then return nil end
    return Vector2.new(minX,minY), Vector2.new(maxX,maxY)
end

local function drawLine(f, p1, p2, thickness, color, transparency)
    local d = p2 - p1; local len = d.Magnitude
    if len < 0.5 or len > 3000 then f.Visible=false; return end
    f.Size = UDim2.fromOffset(len, thickness)
    f.Position = UDim2.fromOffset((p1.X+p2.X)/2, (p1.Y+p2.Y)/2)
    f.Rotation = math.deg(math.atan2(d.Y, d.X))
    f.BackgroundColor3 = color; f.BackgroundTransparency = transparency or 0; f.Visible = true
end

local function updateESP(e, cam, char, plr, dist)
    local tl, br = projectBox(cam, char)
    if not tl then hideESP(e); return end
    local w,h = br.X-tl.X, br.Y-tl.Y
    local color = espColor(plr)
    local alpha = 0
    if get("esp_fade", true) then
        local maxd = getNum("esp_dist", 1000)
        alpha = math.clamp((dist - maxd*0.5)/(maxd*0.5), 0, 0.8)
    end

    -- box
    if get("esp_box") then
        e.Box.Position = UDim2.fromOffset(tl.X, tl.Y); e.Box.Size = UDim2.fromOffset(w,h); e.Box.Visible = true
        local style = get("esp_boxstyle", "Corner")
        if style == "Full" then
            e.Stroke.Visible = true; e.Stroke.Color = color; e.Stroke.Thickness = getNum("esp_boxtick",1); e.Stroke.Transparency = alpha
            for _,c in ipairs(e.Corners) do c.Visible=false end
        elseif style == "Corner" then
            e.Stroke.Visible = false
            local L = math.clamp(math.min(w,h)*0.22, 4, 24); local t = getNum("esp_boxtick",1)
            local function cornerSeg(x,y,sx,sy) local s=e.Corners[1]; -- placeholder, substituído abaixo
            end
            -- desenha 8 segmentos de canto
            local segs = {
                {tl.X, tl.Y, L, t}, {tl.X, tl.Y, t, L},
                {br.X-L, tl.Y, L, t}, {br.X-t, tl.Y, t, L},
                {tl.X, br.Y-t, L, t}, {tl.X, br.Y-L, t, L},
                {br.X-L, br.Y-t, L, t}, {br.X-t, br.Y-L, t, L}
            }
            for i,s in ipairs(segs) do
                local c = e.Corners[i]
                c.Position = UDim2.fromOffset(s[1],s[2]); c.Size = UDim2.fromOffset(s[3],s[4])
                c.BackgroundColor3 = color; c.BackgroundTransparency = alpha; c.Visible = true
            end
        else -- 3D
            e.Stroke.Visible = true; e.Stroke.Color = color; e.Stroke.Thickness = getNum("esp_boxtick",1); e.Stroke.Transparency = alpha
            for _,c in ipairs(e.Corners) do c.Visible=false end
        end
        local fillAmt = getNum("esp_fill",0)
        e.Fill.Visible = fillAmt > 0
        if e.Fill.Visible then e.Fill.BackgroundColor3 = color; e.Fill.BackgroundTransparency = 1 - fillAmt + alpha end
    else e.Box.Visible=false; e.Fill.Visible=false; for _,c in ipairs(e.Corners) do c.Visible=false end end

    -- labels
    local parts = {}
    if get("esp_name") then table.insert(parts, plr and plr.Name or char.Name) end
    if get("esp_distlabel") then table.insert(parts, string.format("[%d]", dist)) end
    if #parts > 0 then
        e.Label.Text = table.concat(parts, " "); e.Label.TextSize = 13; e.Label.TextColor3 = color
        e.Label.TextTransparency = alpha
        e.Label.Position = UDim2.fromOffset((tl.X+br.X)/2, tl.Y-2); e.Label.Visible = true
    else e.Label.Visible = false end

    -- health
    if get("esp_health") and char:FindFirstChild("Humanoid") then
        local hum = char.Humanoid; local frac = math.clamp(hum.Health/math.max(hum.MaxHealth,1),0,1)
        e.HealthBack.Position = UDim2.fromOffset(tl.X-5, tl.Y); e.HealthBack.Size = UDim2.fromOffset(4, h)
        e.HealthBack.BackgroundTransparency = alpha
        e.HealthFill.Size = UDim2.new(1,0,frac,0); e.HealthFill.BackgroundColor3 = Color3.fromRGB(255,60,60):Lerp(Color3.fromRGB(60,235,90),frac)
        e.HealthBack.Visible = true; e.HealthFill.Visible = true
    else e.HealthBack.Visible = false; e.HealthFill.Visible = false end

    -- head dot
    if get("esp_headdot") and char:FindFirstChild("Head") then
        local sp = cam:WorldToViewportPoint(char.Head.Position)
        if sp.Z > 0 then e.HeadDot.Position = UDim2.fromOffset(sp.X, sp.Y); e.HeadDot.BackgroundColor3 = color; e.HeadDot.BackgroundTransparency = alpha; e.HeadDot.Visible = true end
    else e.HeadDot.Visible = false end

    -- tracer
    if get("esp_tracer") then
        local origin = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y)
        local mode = get("esp_trorigin", "Bottom")
        if mode == "Center" then origin = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
        elseif mode == "Mouse" then origin = viewportMouse() end
        local foot = Vector2.new((tl.X+br.X)/2, br.Y)
        drawLine(e.Tracer, origin, foot, getNum("esp_boxtick",1), color, alpha)
    else e.Tracer.Visible = false end

    -- skeleton
    if get("esp_skel") and char:FindFirstChild("Humanoid") then
        local rig = char.Humanoid.RigType
        local bones = rig == Enum.HumanoidRigType.R15 and BONES_R15 or BONES_R6
        for i,pair in ipairs(bones) do
            local line = e.Bones[i]
            if not line then line = new("Frame", {AnchorPoint = Vector2.new(0.5,0.5), Visible=false}, Overlay); e.Bones[i]=line end
            local a = char:FindFirstChild(pair[1]); local b = char:FindFirstChild(pair[2])
            if a and b and a:IsA("BasePart") and b:IsA("BasePart") then
                local sa = cam:WorldToViewportPoint(a.Position); local sb = cam:WorldToViewportPoint(b.Position)
                if sa.Z > 0 and sb.Z > 0 then
                    drawLine(line, Vector2.new(sa.X,sa.Y), Vector2.new(sb.X,sb.Y), getNum("esp_boxtick",1), color, alpha)
                else line.Visible=false end
            else line.Visible=false end
        end
    else for _,b in ipairs(e.Bones) do b.Visible=false end end

    -- chams
    if get("esp_chams") then
        if not e.Highlight then
            e.Highlight = Instance.new("Highlight"); e.Highlight.FillColor = color; e.Highlight.OutlineColor = Color3.new(1,1,1); e.Highlight.FillTransparency = 0.5; e.Highlight.Parent = Overlay
        end
        e.Highlight.Adornee = char; e.Highlight.FillColor = color; e.Highlight.Enabled = true
    elseif e.Highlight then e.Highlight.Enabled = false end
end

local function isESPChar(c)
    return c and c:FindFirstChild("HumanoidRootPart") and c:FindFirstChild("Humanoid") and c.Humanoid.Health > 0
end

RunService.RenderStepped:Connect(function()
    pcall(function()
        if not get("esp_on") then
            for k,e in pairs(ESP_ENTRIES) do destroyESP(e); ESP_ENTRIES[k]=nil end
            return
        end
        local cam = Workspace.CurrentCamera; if not cam then return end
        local maxd = getNum("esp_dist", 1000)
        local seen = {}

        local function push(char, plr)
            if not isESPChar(char) then return end
            local dist = (char.HumanoidRootPart.Position - cam.CFrame.Position).Magnitude
            if dist > maxd then return end
            if get("esp_visible") and not isVisible(char, char:FindFirstChild("Head") or char.HumanoidRootPart) then return end
            seen[char] = true
            local e = ESP_ENTRIES[char] or createESP(); ESP_ENTRIES[char] = e
            updateESP(e, cam, char, plr, dist)
        end

        for _,plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                if not get("esp_team") or plr.Team ~= LocalPlayer.Team then push(plr.Character, plr) end
            end
        end
        if get("esp_npc", true) then
            for _,obj in ipairs(Workspace:GetChildren()) do
                if obj:IsA("Model") and obj ~= LocalPlayer.Character and obj:FindFirstChild("Humanoid") and not Players:GetPlayerFromCharacter(obj) then
                    push(obj, nil)
                end
            end
        end
        for k,e in pairs(ESP_ENTRIES) do
            if not seen[k] then destroyESP(e); ESP_ENTRIES[k]=nil end
        end
    end)
end)

-- ============================================================
-- WEAPON MODS
-- ============================================================
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local char = LocalPlayer.Character
            if not char then return end
            for _,tool in ipairs(char:GetChildren()) do
                if tool:IsA("Tool") then
                    if get("wpn_recoil") then
                        for _,v in ipairs(tool:GetDescendants()) do
                            if v:IsA("NumberValue") and v.Name:lower():find("recoil") then v.Value = 0 end
                        end
                    end
                    if get("wpn_reload") then
                        for _,v in ipairs(tool:GetDescendants()) do
                            if v:IsA("NumberValue") and (v.Name:lower():find("reload") or v.Name:lower():find("cooldown")) then v.Value = 0 end
                        end
                    end
                end
            end
        end)
    end
end)

-- ============================================================
-- DRAG / TOGGLE MENU
-- ============================================================
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
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then GUI.Enabled = not GUI.Enabled end
end)

-- cleanup
local cleaned = false
local function cleanup()
    if cleaned then return end; cleaned = true
    if shared.SonicHubCleanup == cleanup then shared.SonicHubCleanup = nil end
    for k,e in pairs(ESP_ENTRIES) do destroyESP(e); ESP_ENTRIES[k]=nil end
    Overlay:Destroy(); if GUI.Parent then GUI:Destroy() end
end
shared.SonicHubCleanup = cleanup
GUI.Destroying:Connect(cleanup)

GUI.Enabled = true
print("[Sonic Hub V25] Carregado. Silent hook:", silentOk and "OK" or "indisponível (executor sem hookmetamethod)")
