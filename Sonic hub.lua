-- Sonic Hub V26 (Elegant Midnight UI + Full Fixes)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local GuiService = game:GetService("GuiService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- LIMPEZA
if shared.SonicHubCleanup then pcall(shared.SonicHubCleanup) end
for _, name in ipairs({"SonicHub", "SonicHubOverlay"}) do
    local a = PlayerGui:FindFirstChild(name); if a then a:Destroy() end
    local b = game:GetService("CoreGui"):FindFirstChild(name); if b then b:Destroy() end
end

-- CONFIG E PREFS
local Prefs = {}
local function set(k, v) Prefs[k] = v end
local function get(k, d) local v = Prefs[k]; if v == nil then return d end; return v end
local function getNum(k, d) local v = tonumber(get(k, d)); if not v or v ~= v then return d end; return v end

-- PALETA E FONTES
local P = {
    bg = Color3.fromRGB(12, 12, 16), 
    panel = Color3.fromRGB(20, 20, 26),
    panelHead = Color3.fromRGB(28, 28, 36),
    stroke = Color3.fromRGB(45, 45, 55),
    text = Color3.fromRGB(255, 255, 255), 
    sub = Color3.fromRGB(150, 150, 165),
    accent = Color3.fromRGB(0, 229, 255), -- Cyan
    red = Color3.fromRGB(255, 60, 90),
    track = Color3.fromRGB(35, 35, 45), 
    ink = Color3.fromRGB(12, 12, 16),
    font = Enum.Font.Gotham,
    fontBold = Enum.Font.GothamBold,
    fontMono = Enum.Font.RobotoMono
}

-- UI HELPERS
local function new(cls, props, parent)
    local i = Instance.new(cls); for k, v in pairs(props) do i[k] = v end
    if parent then i.Parent = parent end; return i
end
local function corner(i, r) return new("UICorner", {CornerRadius = UDim.new(0, r)}, i) end
local function outline(i, t, c) return new("UIStroke", {Color = c or P.stroke, Thickness = t or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, i) end
local function label(parent, props)
    props.BackgroundTransparency = 1; props.Font = props.Font or P.font
    props.TextColor3 = props.TextColor3 or P.text; props.TextSize = props.TextSize or 14
    props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
    return new("TextLabel", props, parent)
end
local TWEEN = TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local function tween(i, p) TweenService:Create(i, TWEEN, p):Play() end

-- GUI PRINCIPAL
local GUI = new("ScreenGui", {Name = "SonicHub", ResetOnSpawn = false, DisplayOrder = 100, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Enabled = false}, PlayerGui)
local Overlay = new("ScreenGui", {Name = "SonicHubOverlay", ResetOnSpawn = false, DisplayOrder = 999, IgnoreGuiInset = false}, PlayerGui)

local Main = new("Frame", {Size = UDim2.fromOffset(760, 560), Position = UDim2.new(0.5, -380, 0.5, -280), BackgroundColor3 = P.bg, ClipsDescendants = true}, GUI)
corner(Main, 10); outline(Main, 1.5, P.stroke)

-- Title Bar
local TitleBar = new("Frame", {Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = P.panelHead}, Main)
corner(TitleBar, 10)
new("Frame", {Size = UDim2.new(1, 0, 0, 15), Position = UDim2.new(0, 0, 1, -15), BackgroundColor3 = P.panelHead}, TitleBar)
new("Frame", {Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = P.accent}, TitleBar)
label(TitleBar, {Size = UDim2.fromOffset(220, 50), Position = UDim2.fromOffset(20, 0), Text = "SONIC HUB V26", Font = P.fontBold, TextSize = 20, TextColor3 = P.accent})

local closeBtn = new("TextButton", {Size = UDim2.fromOffset(30, 30), Position = UDim2.new(1, -40, 0.5, -15), BackgroundColor3 = P.panel, Text = "x", Font = P.fontBold, TextSize = 16, TextColor3 = P.red, AutoButtonColor = false}, TitleBar)
corner(closeBtn, 6)
closeBtn.MouseButton1Click:Connect(function() GUI:Destroy() end)

-- Body & Sidebar
local Body = new("Frame", {Position = UDim2.fromOffset(0, 50), Size = UDim2.new(1, 0, 1, -50), BackgroundTransparency = 1}, Main)
local Sidebar = new("Frame", {Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(160, 490), BackgroundColor3 = P.panel}, Body)
corner(Sidebar, 8); outline(Sidebar, 1, P.stroke)
local NavList = new("ScrollingFrame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ScrollBarThickness = 0}, Sidebar)
new("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, NavList)
new("UIPadding", {PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)}, NavList)

-- Content
local Content = new("Frame", {Position = UDim2.fromOffset(180, 10), Size = UDim2.fromOffset(570, 490), BackgroundTransparency = 1}, Body)
local PageTitle = label(Content, {Size = UDim2.new(1, 0, 0, 30), Text = "", Font = P.fontBold, TextSize = 22})
local PageSub = label(Content, {Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(2, 30), Text = "", TextSize = 13, TextColor3 = P.sub})
local Scroll = new("ScrollingFrame", {Position = UDim2.fromOffset(0, 60), Size = UDim2.new(1, 0, 1, -60), BackgroundTransparency = 1, ScrollBarThickness = 4, ScrollBarImageColor3 = P.accent}, Content)
new("UIListLayout", {Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder}, Scroll)
new("UIPadding", {PaddingRight = UDim.new(0, 10)}, Scroll)

-- WIDGETS
local renderers = {}
local activeSlider = nil

local function CreateGroup(parent, title)
    local g = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = P.panel}, parent)
    corner(g, 8); outline(g, 1, P.stroke)
    new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}, g)
    local head = new("TextButton", {Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, Text = "", LayoutOrder = 1}, g)
    label(head, {Size = UDim2.new(1, -25, 1, 0), Position = UDim2.fromOffset(12, 0), Text = title, Font = P.fontBold, TextSize = 13, TextColor3 = P.text})
    local chev = label(head, {Size = UDim2.fromOffset(18, 32), Position = UDim2.new(1, -22, 0, 0), Text = "v", TextColor3 = P.sub, Font = P.fontBold})
    local body = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 2}, g)
    new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, body)
    new("UIPadding", {PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12)}, body)
    head.MouseButton1Click:Connect(function() body.Visible = not body.Visible; tween(chev, {Rotation = body.Visible and 0 or -90}) end)
    return body
end

local function CreateToggle(parent, name, key, default)
    Prefs[key] = Prefs[key] or default
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1}, parent)
    label(row, {Size = UDim2.new(0.8, 0, 1, 0), Text = name, TextSize = 13})
    local sw = new("TextButton", {Size = UDim2.fromOffset(36, 20), Position = UDim2.new(1, -36, 0.5, -10), BackgroundColor3 = P.track, Text = "", AutoButtonColor = false}, row)
    corner(sw, 10); outline(sw, 1, P.stroke)
    local knob = new("Frame", {Size = UDim2.fromOffset(14, 14), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = P.sub}, sw); corner(knob, 7)
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
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1}, parent)
    label(row, {Size = UDim2.new(0.7, 0, 0, 18), Text = name, TextSize = 13})
    local valLbl = label(row, {Size = UDim2.new(0.3, 0, 0, 18), Position = UDim2.new(0.7, 0, 0, 0), Text = tostring(get(key)) .. (suffix or ""), TextSize = 12, TextColor3 = P.accent, Font = P.fontMono, TextXAlignment = Enum.TextXAlignment.Right})
    
    local btn = new("TextButton", {Size = UDim2.new(1, 0, 0, 22), Position = UDim2.fromOffset(0, 18), BackgroundTransparency = 1, Text = ""}, row)
    local track = new("Frame", {Size = UDim2.new(1, 0, 0, 4), Position = UDim2.fromOffset(0, 9), BackgroundColor3 = P.track}, btn); corner(track, 2)
    local fill = new("Frame", {Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = P.accent}, track); corner(fill, 2)
    local knob = new("Frame", {Size = UDim2.fromOffset(12, 12), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = P.text}, track); corner(knob, 6)
    
    local function update(pct)
        local v = math.floor(min + pct * (max - min) + 0.5)
        set(key, v)
        pct = (v - min) / math.max(max - min, 1)
        tween(fill, {Size = UDim2.new(pct, 0, 1, 0)}); tween(knob, {Position = UDim2.new(pct, 0, 0.5, 0)})
        valLbl.Text = tostring(v) .. (suffix or "")
    end
    
    renderers[key] = function() update((getNum(key, default) - min) / math.max(max - min, 1)) end
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            activeSlider = {btn = btn, min = min, max = max, update = update}
            local pct = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            update(pct)
        end
    end)
    renderers[key]()
end

local function CreateDropdown(parent, name, key, options, default)
    Prefs[key] = Prefs[key] or default
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1}, parent)
    label(row, {Size = UDim2.new(1, 0, 0, 18), Text = name, TextSize = 13})
    
    local btn = new("TextButton", {Size = UDim2.new(1, 0, 0, 24), Position = UDim2.fromOffset(0, 20), BackgroundColor3 = P.track, Text = "", AutoButtonColor = false}, row); corner(btn, 6)
    local txt = label(btn, {Size = UDim2.new(1, -10, 1, 0), Position = UDim2.fromOffset(10, 0), Text = tostring(get(key)), TextSize = 12})
    local arrow = label(btn, {Size = UDim2.fromOffset(18, 24), Position = UDim2.new(1, -20, 0, 0), Text = "v", TextColor3 = P.sub, Font = P.fontBold})
    
    local list = new("Frame", {Size = UDim2.new(1, 0, 0, #options * 22), Position = UDim2.fromOffset(0, 46), BackgroundColor3 = P.panelHead, Visible = false, ZIndex = 10}, row)
    corner(list, 6); outline(list, 1, P.stroke)
    for i, opt in ipairs(options) do
        local b = new("TextButton", {Size = UDim2.new(1, 0, 0, 22), Position = UDim2.fromOffset(0, (i - 1) * 22), BackgroundTransparency = 1, Text = opt, TextSize = 12, ZIndex = 11}, list)
        b.MouseButton1Click:Connect(function()
            set(key, opt); txt.Text = opt; list.Visible = false; tween(arrow, {Rotation = 0})
            if renderers[key] then renderers[key]() end
        end)
    end
    btn.MouseButton1Click:Connect(function()
        list.Visible = not list.Visible
        tween(arrow, {Rotation = list.Visible and 180 or 0})
    end)
end

-- PÁGINAS
local Pages, NavButtons, ActivePage = {}, {}, ""
local function SwitchPage(name)
    ActivePage = name; PageTitle.Text = name
    for _, v in ipairs(Scroll:GetChildren()) do if v:IsA("GuiObject") then v:Destroy() end end
    for n, b in pairs(NavButtons) do
        local sel = (n == name)
        tween(b.bg, {BackgroundColor3 = sel and P.panelHead or P.panel})
        tween(b.txt, {TextColor3 = sel and P.accent or P.sub})
        tween(b.line, {Size = sel and UDim2.new(0, 3, 0.6, 0) or UDim2.new(0, 3, 0, 0)})
    end
    if Pages[name] then Pages[name]() end
end

local function AddNav(name)
    local btn = new("TextButton", {Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = P.panel, Text = "", AutoButtonColor = false}, NavList); corner(btn, 6)
    local line = new("Frame", {Size = UDim2.new(0, 3, 0, 0), Position = UDim2.new(0, 0, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = P.accent}, btn); corner(line, 2)
    local txt = label(btn, {Size = UDim2.new(1, -15, 1, 0), Position = UDim2.fromOffset(15, 0), Text = name, TextSize = 13, TextColor3 = P.sub})
    NavButtons[name] = {bg = btn, txt = txt, line = line}
    btn.MouseButton1Click:Connect(function() SwitchPage(name) end)
end

Pages["AIMBOT"] = function()
    PageSub.Text = "target locking & silent aim"
    local g1 = CreateGroup(Scroll, "Aimbot")
    CreateToggle(g1, "Enabled", "aim_on", false)
    CreateDropdown(g1, "Method", "aim_method", {"Camera Lock", "Mouse Lock"}, "Camera Lock")
    CreateDropdown(g1, "Bone", "aim_bone", {"Head", "UpperTorso", "HumanoidRootPart"}, "Head")
    CreateSlider(g1, "FOV", "aim_fov", 10, 600, 120)
    CreateSlider(g1, "Smoothness", "aim_smooth", 1, 20, 5)
    CreateToggle(g1, "Visible Only", "aim_visible", false)

    local g2 = CreateGroup(Scroll, "Silent Aim")
    CreateToggle(g2, "Enabled", "sil_on", false)
    CreateSlider(g2, "Hit Chance", "sil_hit", 0, 100, 95)
    CreateSlider(g2, "FOV", "sil_fov", 10, 600, 200)
end

Pages["VISUALS"] = function()
    PageSub.Text = "esp, chams & fov circle"
    local g1 = CreateGroup(Scroll, "ESP")
    CreateToggle(g1, "Enabled", "esp_on", false)
    CreateToggle(g1, "Team Check", "esp_team", true)
    CreateToggle(g1, "Include NPCs", "esp_npc", true)
    CreateSlider(g1, "Max Distance", "esp_dist", 100, 3000, 1000)
    CreateToggle(g1, "Box", "esp_box", true)
    CreateToggle(g1, "Name", "esp_name", true)
    CreateToggle(g1, "Distance", "esp_distlabel", true)
    CreateToggle(g1, "Health Bar", "esp_health", true)
    CreateToggle(g1, "Skeleton", "esp_skel", false)
    CreateToggle(g1, "Tracer", "esp_tracer", false)
    
    local g2 = CreateGroup(Scroll, "Extras")
    CreateToggle(g2, "Chams (Highlight)", "esp_chams", false)
    CreateToggle(g2, "FOV Circle", "vis_fovcircle", true)
    CreateToggle(g2, "Fullbright", "vis_fullbright", false)
end

Pages["PLAYER"] = function()
    PageSub.Text = "local character mods"
    local g1 = CreateGroup(Scroll, "Movement")
    CreateSlider(g1, "Walkspeed", "plr_speed", 16, 200, 16)
    CreateSlider(g1, "JumpPower", "plr_jump", 50, 200, 50)
    CreateToggle(g1, "Infinite Jump", "plr_infjump", false)
    CreateToggle(g1, "Noclip", "plr_noclip", false)
    CreateToggle(g1, "Fly", "plr_fly", false)
    CreateSlider(g1, "Fly Speed", "plr_flyspeed", 10, 200, 50)
end

Pages["MISC"] = function()
    PageSub.Text = "weapon & server mods"
    local g1 = CreateGroup(Scroll, "Weapon")
    CreateToggle(g1, "No Recoil", "wpn_recoil", false)
    CreateToggle(g1, "Auto Reload", "wpn_reload", false)

    local g2 = CreateGroup(Scroll, "Trigger Bot")
    CreateToggle(g2, "Enabled", "trg_on", false)
    CreateDropdown(g2, "Mode", "trg_mode", {"Hold", "Toggle"}, "Hold")
    CreateDropdown(g2, "Hotkey", "trg_key", {"RMB", "E", "X", "Shift"}, "E")
    CreateSlider(g2, "Delay (ms)", "trg_delay", 0, 500, 50)
end

AddNav("AIMBOT"); AddNav("VISUALS"); AddNav("PLAYER"); AddNav("MISC")
SwitchPage("AIMBOT")

-- LÓGICA E LOOP (TARGETING)
local viewportMouse = function()
    local m = UserInputService:GetMouseLocation()
    local inset = Vector2.new(0, 36)
    pcall(function() local i = GuiService:GetGuiInset(); if typeof(i) == "Vector2" then inset = i end end)
    return m - inset
end

local function isVisible(char, part)
    local cam = Workspace.CurrentCamera
    if not cam or not LocalPlayer.Character then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character, char}
    local result = Workspace:Raycast(cam.CFrame.Position, part.Position - cam.CFrame.Position, params)
    return result == nil
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
                            closestDist = dist
                            closest = {char = plr.Character, part = part}
                        end
                    end
                end
            end
        end
    end
    return closest
end

-- FOV CIRCLE
local fovCircle = new("Frame", {Size = UDim2.fromOffset(100, 100), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Visible = false}, Overlay)
new("UICorner", {CornerRadius = UDim.new(1, 0)}, fovCircle)
local fovStroke = new("UIStroke", {Color = P.accent, Thickness = 1.5}, fovCircle)

RunService.RenderStepped:Connect(function()
    pcall(function()
        if get("vis_fovcircle") and get("aim_on") then
            local fov = getNum("aim_fov", 120) * 2
            fovCircle.Position = UDim2.fromOffset(Workspace.CurrentCamera.ViewportSize.X / 2, Workspace.CurrentCamera.ViewportSize.Y / 2)
            fovCircle.Size = UDim2.fromOffset(fov, fov)
            fovCircle.Visible = true
        else
            fovCircle.Visible = false
        end
    end)
end)

-- AIMBOT LOOP
RunService.RenderStepped:Connect(function()
    pcall(function()
        if not get("aim_on") then return end
        local target = findTarget(getNum("aim_fov", 120), get("aim_bone", "Head"), get("aim_team", true), get("aim_visible", false))
        if target then
            local cam = Workspace.CurrentCamera
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
    end)
end)

-- SILENT AIM & TRIGGER BOT & WEAPON
local trgPrev, trgToggled, lastFire = false, false, 0
RunService.RenderStepped:Connect(function()
    pcall(function()
        -- Trigger Bot
        if get("trg_on") then
            local keyDown = false
            local key = get("trg_key", "E")
            if key == "RMB" then keyDown = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
            elseif key == "E" then keyDown = UserInputService:IsKeyDown(Enum.KeyCode.E)
            elseif key == "X" then keyDown = UserInputService:IsKeyDown(Enum.KeyCode.X)
            elseif key == "Shift" then keyDown = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) end
            
            local shouldFire
            if get("trg_mode", "Hold") == "Toggle" then
                if keyDown and not trgPrev then trgToggled = not trgToggled end
                trgPrev = keyDown
                shouldFire = trgToggled
            else
                shouldFire = keyDown
            end

            if shouldFire and (os.clock() - lastFire) > (getNum("trg_delay", 50) / 1000) then
                local target = findTarget(60, "Head", true, false)
                if target then
                    lastFire = os.clock()
                    pcall(function()
                        VirtualUser:CaptureController()
                        VirtualUser:Button1Down(Vector2.new(0,0))
                        VirtualUser:Button1Up(Vector2.new(0,0))
                    end)
                end
            end
        end

        -- Weapon Mods
        local char = LocalPlayer.Character
        if char then
            for _, tool in ipairs(char:GetChildren()) do
                if tool:IsA("Tool") then
                    if get("wpn_recoil") then
                        for _, v in ipairs(tool:GetDescendants()) do
                            if v:IsA("NumberValue") and v.Name:lower():find("recoil") then v.Value = 0 end
                        end
                    end
                    if get("wpn_reload") then
                        for _, v in ipairs(tool:GetDescendants()) do
                            if v:IsA("NumberValue") and (v.Name:lower():find("reload") or v.Name:lower():find("cooldown")) then v.Value = 0 end
                        end
                    end
                end
            end
        end
    end)
end)

-- SILENT AIM HOOK
local silentOk = false
local silentPart = nil
RunService.RenderStepped:Connect(function()
    pcall(function()
        if not get("sil_on") then silentPart = nil; return end
        local t = findTarget(getNum("sil_fov", 200), "Head", true, false)
        silentPart = t and t.part or nil
    end)
end)

pcall(function()
    if type(hookmetamethod) ~= "function" or type(getnamecallmethod) ~= "function" then return end
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if not checkcaller() and get("sil_on") and silentPart and silentPart.Parent then
            if math.random(1, 100) <= getNum("sil_hit", 95) then
                local args = {...}
                if method == "Raycast" and self == Workspace then
                    local origin = args[1]
                    if typeof(origin) == "Vector3" then
                        args[2] = (silentPart.Position - origin).Unit * 1000
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

-- ESP (REESCRITO USANDO PROJEÇÃO MANUAL)
local ESP_ENTRIES = {}
local BONES_R15 = {{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"}}
local BONES_R6 = {{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"}}

local function createESP()
    local e = {Bones = {}}
    e.Box = new("Frame", {BackgroundTransparency = 1, Visible = false}, Overlay)
    e.Stroke = new("UIStroke", {Color = P.accent, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, e.Box)
    e.Label = new("TextLabel", {BackgroundTransparency = 1, Size = UDim2.fromOffset(200,20), AnchorPoint = Vector2.new(0.5,1), Font = P.fontBold, TextStrokeTransparency = 0.5, Visible = false}, Overlay)
    e.HealthBack = new("Frame", {BackgroundColor3 = Color3.fromRGB(20,20,20), Visible = false}, Overlay); corner(e.HealthBack, 2)
    e.HealthFill = new("Frame", {AnchorPoint = Vector2.new(0,1), Position = UDim2.new(0,0,1,0), Visible = false}, e.HealthBack); corner(e.HealthFill, 2)
    e.Tracer = new("Frame", {AnchorPoint = Vector2.new(0.5,0.5), Visible = false}, Overlay)
    return e
end

local function hideESP(e)
    e.Box.Visible=false; e.Label.Visible=false; e.HealthBack.Visible=false; e.Tracer.Visible=false
    for _,b in ipairs(e.Bones) do b.Visible=false end
end
local function destroyESP(e)
    e.Box:Destroy(); e.Label:Destroy(); e.HealthBack:Destroy(); e.Tracer:Destroy()
    for _,b in ipairs(e.Bones) do b:Destroy() end
end

local function drawLine(f, p1, p2, color)
    local d = p2 - p1; local len = d.Magnitude
    if len < 0.5 or len > 3000 then f.Visible=false; return end
    f.Size = UDim2.fromOffset(len, 1)
    f.Position = UDim2.fromOffset((p1.X+p2.X)/2, (p1.Y+p2.Y)/2)
    f.Rotation = math.deg(math.atan2(d.Y, d.X))
    f.BackgroundColor3 = color; f.Visible = true
end

RunService.RenderStepped:Connect(function()
    pcall(function()
        if not get("esp_on") then
            for k,e in pairs(ESP_ENTRIES) do destroyESP(e); ESP_ENTRIES[k]=nil end
            return
        end
        local cam = Workspace.CurrentCamera
        if not cam then return end
        local maxd = getNum("esp_dist", 1000)
        local seen = {}

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
                if not get("esp_team") or plr.Team ~= LocalPlayer.Team then
                    local char = plr.Character
                    local hrp = char.HumanoidRootPart
                    local head = char:FindFirstChild("Head") or hrp
                    local dist = (hrp.Position - cam.CFrame.Position).Magnitude
                    
                    if dist <= maxd then
                        seen[char] = true
                        local e = ESP_ENTRIES[char] or createESP(); ESP_ENTRIES[char] = e
                        
                        -- Cálculo de projeção manual (mais seguro que GetBoundingBox)
                        local topPos = head.Position + Vector3.new(0, 0.5, 0)
                        local botPos = hrp.Position - Vector3.new(0, 3, 0)
                        local spTop, onTop = cam:WorldToViewportPoint(topPos)
                        local spBot, onBot = cam:WorldToViewportPoint(botPos)
                        
                        if onTop and onBot then
                            local h = spBot.Y - spTop.Y
                            local w = h * 0.6 -- proporção aproximada
                            local x = spTop.X - w/2
                            local y = spTop.Y
                            
                            if get("esp_box") then
                                e.Box.Position = UDim2.fromOffset(x, y); e.Box.Size = UDim2.fromOffset(w, h); e.Box.Visible = true
                            else e.Box.Visible = false end
                            
                            local parts = {}
                            if get("esp_name") then table.insert(parts, plr.Name) end
                            if get("esp_distlabel") then table.insert(parts, string.format("[%d]", dist)) end
                            if #parts > 0 then
                                e.Label.Text = table.concat(parts, " "); e.Label.TextSize = 13; e.Label.TextColor3 = P.accent
                                e.Label.Position = UDim2.fromOffset(spTop.X, y - 2); e.Label.Visible = true
                            else e.Label.Visible = false end
                            
                            if get("esp_health") then
                                local hum = char.Humanoid; local frac = math.clamp(hum.Health/math.max(hum.MaxHealth,1),0,1)
                                e.HealthBack.Position = UDim2.fromOffset(x-5, y); e.HealthBack.Size = UDim2.fromOffset(4, h)
                                e.HealthFill.Size = UDim2.new(1,0,frac,0); e.HealthFill.BackgroundColor3 = Color3.fromRGB(255,60,60):Lerp(Color3.fromRGB(60,235,90),frac)
                                e.HealthBack.Visible = true
                            else e.HealthBack.Visible = false end
                            
                            if get("esp_tracer") then
                                local origin = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y)
                                drawLine(e.Tracer, origin, Vector2.new(spTop.X, spBot.Y), P.accent)
                            else e.Tracer.Visible = false end
                            
                            if get("esp_skel") then
                                local rig = char.Humanoid.RigType
                                local bones = rig == Enum.HumanoidRigType.R15 and BONES_R15 or BONES_R6
                                for i,pair in ipairs(bones) do
                                    local line = e.Bones[i]
                                    if not line then line = new("Frame", {AnchorPoint = Vector2.new(0.5,0.5), Visible=false}, Overlay); e.Bones[i]=line end
                                    local a = char:FindFirstChild(pair[1]); local b = char:FindFirstChild(pair[2])
                                    if a and b and a:IsA("BasePart") and b:IsA("BasePart") then
                                        local sa, oa = cam:WorldToViewportPoint(a.Position); local sb, ob = cam:WorldToViewportPoint(b.Position)
                                        if oa and ob then drawLine(line, Vector2.new(sa.X,sa.Y), Vector2.new(sb.X,sb.Y), P.accent) else line.Visible=false end
                                    else line.Visible=false end
                                end
                            else for _,b in ipairs(e.Bones) do b.Visible=false end end
                            
                        else hideESP(e) end
                        
                        -- Chams
                        if get("esp_chams") then
                            if not e.Highlight then
                                e.Highlight = Instance.new("Highlight"); e.Highlight.FillTransparency = 0.5; e.Highlight.Parent = Overlay
                            end
                            e.Highlight.Adornee = char; e.Highlight.Enabled = true
                        elseif e.Highlight then e.Highlight.Enabled = false end
                        
                    else hideESP(e) end
                end
            end
        end
        for k,e in pairs(ESP_ENTRIES) do
            if not seen[k] then destroyESP(e); ESP_ENTRIES[k]=nil end
        end
    end)
end)

-- PLAYER MODS & NOCLIP & FLY & FULLBRIGHT
local flyBodyVel, flyBodyGyro = nil, nil
RunService.Stepped:Connect(function()
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChild("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp then return end
        
        hum.WalkSpeed = getNum("plr_speed", 16)
        hum.JumpPower = getNum("plr_jump", 50)
        
        if get("plr_infjump") and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
        
        if get("plr_noclip") then
            for _, v in ipairs(char:GetDescendants()) do
                if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end
            end
        end
        
        -- Fly Logic
        if get("plr_fly") then
            if not flyBodyVel then
                flyBodyVel = Instance.new("BodyVelocity", hrp); flyBodyVel.MaxForce = Vector3.new(1e5, 1e5, 1e5); flyBodyVel.Velocity = Vector3.zero
                flyBodyGyro = Instance.new("BodyGyro", hrp); flyBodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5); flyBodyGyro.P = 1000
            end
            local cam = Workspace.CurrentCamera
            local moveDir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir -= Vector3.new(0,1,0) end
            
            if moveDir.Magnitude > 0 then
                flyBodyVel.Velocity = moveDir.Unit * getNum("plr_flyspeed", 50)
            else
                flyBodyVel.Velocity = Vector3.zero
            end
            flyBodyGyro.CFrame = cam.CFrame
        else
            if flyBodyVel then flyBodyVel:Destroy(); flyBodyVel = nil end
            if flyBodyGyro then flyBodyGyro:Destroy(); flyBodyGyro = nil end
        end
        
        -- Fullbright
        local lighting = game:GetService("Lighting")
        if get("vis_fullbright") then
            lighting.Ambient = Color3.fromRGB(255,255,255)
            lighting.OutdoorAmbient = Color3.fromRGB(255,255,255)
            lighting.Brightness = 2
        else
            lighting.Ambient = Color3.fromRGB(70,70,70)
            lighting.OutdoorAmbient = Color3.fromRGB(128,128,128)
            lighting.Brightness = 1
        end
    end)
end)

-- DRAG & SLIDER INPUT
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
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false; activeSlider = nil
    end
end)
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then GUI.Enabled = not GUI.Enabled end
end)

-- CLEANUP
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
print("[Sonic Hub V26] Interface elegante carregada. Hook:", silentOk and "OK" or "OFF")
