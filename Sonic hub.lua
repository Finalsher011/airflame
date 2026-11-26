-- Drx Hub V14 (Aimbot/Silent via Mouse Lock - Zero Hooks, Zero Erros de Câmera)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

if shared.DrxCleanup then pcall(shared.DrxCleanup) end
for _, name in ipairs({"DrxHub", "DrxOverlay"}) do
    local a = PlayerGui:FindFirstChild(name); if a then a:Destroy() end
    local b = game:GetService("CoreGui"):FindFirstChild(name); if b then b:Destroy() end
end

local Prefs = {}
local function set(k, v) Prefs[k] = v end
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
closeBtn.MouseButton1Click:Connect(function() GUI:Destroy() end)

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
    label(head, {Size = UDim2.new(1, -10, 1, 0), Position = UDim2.fromOffset(10, 0), Text = title, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Theme.accent}, nil)
    local body = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 2}, g)
    new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, body)
    return body
end

local function CreateToggle(parent, name, key, default)
    Prefs[key] = Prefs[key] or default
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = Theme.card}, parent)
    corner(row, 8); outline(row, 1, Theme.stroke)
    label(row, {Size = UDim2.new(1, -60, 1, 0), Position = UDim2.fromOffset(12, 0), Text = name, TextSize = 13, Font = Enum.Font.GothamBold}, nil)
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
    label(row, {Size = UDim2.new(1, -80, 0, 20), Position = UDim2.fromOffset(12, 8), Text = name, TextSize = 13, Font = Enum.Font.GothamBold}, nil)
    local minus = new("TextButton", {Size = UDim2.fromOffset(20, 20), Position = UDim2.new(1, -80, 0, 8), BackgroundColor3 = Theme.panel, Text = "-", TextColor3 = Theme.text, TextSize = 14, AutoButtonColor = false}, row); corner(minus, 4)
    local valLbl = label(row, {Size = UDim2.fromOffset(40, 20), Position = UDim2.new(1, -55, 0, 8), Text = tostring(get(key)), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Center}, nil)
    local plus = new("TextButton", {Size = UDim2.fromOffset(20, 20), Position = UDim2.new(1, -20, 0, 8), BackgroundColor3 = Theme.panel, Text = "+", TextColor3 = Theme.text, TextSize = 14, AutoButtonColor = false}, row); corner(plus, 4)
    local btn = new("TextButton", {Size = UDim2.new(1, -24, 0, 15), Position = UDim2.fromOffset(12, 30), BackgroundTransparency = 1, Text = ""}, row)
    local track = new("Frame", {Size = UDim2.new(1, 0, 0, 4), Position = UDim2.fromOffset(0, 6), BackgroundColor3 = Theme.track}, btn); corner(track, 2)
    local fill = new("Frame", {Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Theme.accent}, track); corner(fill, 2)
    local knob = new("Frame", {Size = UDim2.fromOffset(12, 12), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Theme.accent}, track); corner(knob, 6)
    local function update(pct)
        local v = math.floor(min + pct * (max - min) + 0.5)
        set(key, v); pct = (v - min) / math.max(max - min, 1)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        knob.Position = UDim2.new(pct, 0, 0.5, 0)
        valLbl.Text = tostring(v)
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
    label(row, {Size = UDim2.new(1, -60, 1, 0), Position = UDim2.fromOffset(12, 0), Text = name, TextSize = 13, Font = Enum.Font.GothamBold}, nil)
    local btn = new("TextButton", {Size = UDim2.new(0, 100, 0, 24), Position = UDim2.new(1, -112, 0.5, -12), BackgroundColor3 = Theme.panel, Text = "", AutoButtonColor = false}, row)
    corner(btn, 6); outline(btn, 1, Theme.stroke)
    local txt = label(btn, {Size = UDim2.new(1, -20, 1, 0), Position = UDim2.fromOffset(8, 0), Text = tostring(get(key)), TextSize = 12}, nil)
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
    Prefs[key] = Prefs[key] or {Key = defaultKey, Mode = defaultMode}
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = Theme.card}, parent)
    corner(row, 8); outline(row, 1, Theme.stroke)
    label(row, {Size = UDim2.new(1, -120, 1, 0), Position = UDim2.fromOffset(12, 0), Text = name, TextSize = 13, Font = Enum.Font.GothamBold}, nil)
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
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then kName = "RMB" end
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
    local txt = label(btn, {Size = UDim2.new(1, -30, 1, 0), Position = UDim2.fromOffset(30, 0), Text = name, TextSize = 14, TextColor3 = Theme.sub, Font = Enum.Font.GothamBold}, nil)
    local ind = new("Frame", {Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(10, 12), BackgroundColor3 = Theme.sub}, btn); corner(ind, 4)
    btn.MouseEnter:Connect(function() if Pages[name] and not Pages[name].Visible then tween(btn, {BackgroundColor3 = Theme.card}) end end)
    btn.MouseLeave:Connect(function() if Pages[name] and not Pages[name].Visible then tween(btn, {BackgroundColor3 = Theme.panel}) end end)
    NavButtons[name] = {bg = btn, txt = txt, ind = ind}
    btn.MouseButton1Click:Connect(function() SwitchPage(name) end)
end

AddPage("Aimbot", function(c1, c2)
    local g1 = CreateGroup(c1, "Aimbot")
    CreateToggle(g1, "Enabled", "aim_on", false)
    CreateKeybind(g1, "Aim Key", "aim_key", "E", "Hold")
    CreateSlider(g1, "FOV", "aim_fov", 10, 360, 120)
    CreateSlider(g1, "Smooth", "aim_smooth", 1, 20, 3)
    CreateDropdown(g1, "Bone", "aim_bone", {"Head", "Torso"}, "Head")
    CreateToggle(g1, "Team Check", "aim_team", true)
    
    local g2 = CreateGroup(c2, "Silent Aim (Mouse)")
    CreateToggle(g2, "Enabled", "sil_on", false)
    CreateKeybind(g2, "Silent Key", "sil_key", "Always", "Always")
    CreateSlider(g2, "FOV", "sil_fov", 10, 360, 150)
end)

AddPage("Visuals", function(c1, c2)
    local g1 = CreateGroup(c1, "ESP")
    CreateToggle(g1, "Box ESP", "esp_box", false)
    CreateToggle(g1, "ESP Name", "esp_name", false)
    CreateToggle(g1, "Team Check", "esp_team", true)
end)

AddPage("Settings", function(c1, c2)
    local g1 = CreateGroup(c1, "Menu Settings")
    CreateKeybind(g1, "Menu Keybind", "misc_menukey", "RightShift", "Toggle")
end)

AddNav("Aimbot"); AddNav("Visuals"); AddNav("Settings")
SwitchPage("Aimbot")

-- LÓGICA BLINDADA
local function isKeybindActive(data)
    if not data then return false end
    if data.Mode == "Always" or data.Key == "None" then return true end
    local isDown = false
    if data.Key == "LMB" then isDown = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    elseif data.Key == "RMB" then isDown = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    elseif data.Key == "MMB" then isDown = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton3)
    else local success, kc = pcall(function() return Enum.KeyCode[data.Key] end); if success and kc then isDown = UserInputService:IsKeyDown(kc) end end
    if data.Mode == "Hold" then return isDown end
    if data.Mode == "Toggle" then
        local sk = "tgl_" .. tostring(data.Key)
        if isDown and not Prefs[sk .. "_prev"] then Prefs[sk] = not Prefs[sk] end
        Prefs[sk .. "_prev"] = isDown
        return Prefs[sk]
    end
    return false
end

local function findTarget(fov, bone, teamCheck)
    local cam = Workspace.CurrentCamera
    if not cam then return nil end
    local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
    local closest, closestDist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Players.LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
            if not teamCheck or plr.Team ~= Players.LocalPlayer.Team then
                local part = plr.Character:FindFirstChild(bone) or plr.Character.HumanoidRootPart
                local sp, onScreen = cam:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if dist < fov and dist < closestDist then
                        closestDist = dist; closest = {char = plr.Character, part = part, screenPos = Vector2.new(sp.X, sp.Y)}
                    end
                end
            end
        end
    end
    return closest
end

-- AIMBOT E SILENT (MÉTODO SEGURO VIA MOUSE)
task.spawn(function()
    while task.wait(0.01) do
        if not GUI.Parent then break end
        pcall(function()
            local cam = Workspace.CurrentCamera
            if not cam then return end

            -- Aimbot
            if get("aim_on") and isKeybindActive(get("aim_key", {Key="E", Mode="Hold"})) then
                local target = findTarget(getNum("aim_fov", 120), get("aim_bone", "Head"), get("aim_team", true))
                if target then
                    local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
                    local delta = target.screenPos - center
                    local smooth = getNum("aim_smooth", 3)
                    pcall(function() mousemoverel(delta.X / smooth, delta.Y / smooth) end)
                end
            end

            -- Silent Aim (Simulado via Mouse)
            if get("sil_on") and isKeybindActive(get("sil_key", {Key="Always", Mode="Always"})) then
                local target = findTarget(getNum("sil_fov", 150), "Head", true)
                if target then
                    local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
                    local delta = target.screenPos - center
                    -- Puxa o mouse instantaneamente para o alvo antes do tiro
                    pcall(function() mousemoverel(delta.X, delta.Y) end)
                end
            end
        end)
    end
end)

-- ESP
local ESP = {}
local function destroyESP(e)
    if e.Box then e.Box:Destroy() end
    if e.Label then e.Label:Destroy() end
end

task.spawn(function()
    while task.wait(0.03) do
        if not GUI.Parent then break end
        pcall(function()
            if not get("esp_box") and not get("esp_name") then
                for k,e in pairs(ESP) do destroyESP(e); ESP[k] = nil end
                return
            end
            local cam = Workspace.CurrentCamera
            if not cam then return end
            local seen = {}
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= Players.LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
                    if not get("esp_team") or plr.Team ~= Players.LocalPlayer.Team then
                        local char = plr.Character
                        local hrp = char.HumanoidRootPart
                        local dist = (hrp.Position - cam.CFrame.Position).Magnitude
                        if dist <= 1000 then
                            seen[char] = true
                            local e = ESP[char]
                            if not e then
                                e = {}
                                e.Box = new("Frame", {BackgroundTransparency = 1, Visible = false}, Overlay)
                                e.Stroke = new("UIStroke", {Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = Theme.accent}, e.Box)
                                e.Label = new("TextLabel", {BackgroundTransparency = 1, Size = UDim2.fromOffset(200,20), AnchorPoint = Vector2.new(0.5,1), Font = Enum.Font.Gotham, TextStrokeTransparency = 0.5, Visible = false, TextColor3 = Theme.accent}, Overlay)
                                ESP[char] = e
                            end
                            local sp, onScreen = cam:WorldToViewportPoint(hrp.Position)
                            if onScreen then
                                local h = math.abs(cam:WorldToViewportPoint(hrp.Position + Vector3.new(0,3,0)).Y - cam:WorldToViewportPoint(hrp.Position - Vector3.new(0,3,0)).Y)
                                local w = h * 0.65
                                local tlX, tlY = sp.X - w/2, sp.Y - h/2
                                if get("esp_box") then e.Box.Position = UDim2.fromOffset(tlX, tlY); e.Box.Size = UDim2.fromOffset(w, h); e.Box.Visible = true
                                else e.Box.Visible = false end
                                if get("esp_name") then e.Label.Text = plr.Name; e.Label.Position = UDim2.fromOffset(sp.X, tlY - 4); e.Label.Visible = true
                                else e.Label.Visible = false end
                            else
                                e.Box.Visible = false; e.Label.Visible = false
                            end
                        else
                            if e then e.Box.Visible = false; e.Label.Visible = false end
                        end
                    end
                end
            end
            for k,e in pairs(ESP) do if not seen[k] then destroyESP(e); ESP[k] = nil end end
        end)
    end
end)

-- INPUTS
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    local mk = get("misc_menukey", {Key="RightShift", Mode="Toggle"})
    local match = (input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == mk.Key) or (input.UserInputType == Enum.UserInputType.MouseButton1 and mk.Key == "LMB") or (input.UserInputType == Enum.UserInputType.MouseButton2 and mk.Key == "RMB")
    if mk.Mode == "Toggle" and match then GUI.Enabled = not GUI.Enabled
    elseif mk.Mode == "Hold" and match then GUI.Enabled = true end
end)

UserInputService.InputEnded:Connect(function(input)
    local mk = get("misc_menukey", {Key="RightShift", Mode="Toggle"})
    local match = (input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == mk.Key) or (input.UserInputType == Enum.UserInputType.MouseButton1 and mk.Key == "LMB") or (input.UserInputType == Enum.UserInputType.MouseButton2 and mk.Key == "RMB")
    if mk.Mode == "Hold" and match then GUI.Enabled = false end
end)

local dragging, dragStart, startPos = false, nil, nil
TopBar.InputBegan:Connect(function(input)
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
        if activeSlider.track and activeSlider.track.Parent then
            local pct = math.clamp((input.Position.X - activeSlider.track.AbsolutePosition.X) / math.max(activeSlider.track.AbsoluteSize.X, 1), 0, 1)
            activeSlider.update(pct)
        else activeSlider = nil end
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false; activeSlider = nil end
end)

local cleaned = false
local function cleanup()
    if cleaned then return end; cleaned = true
    if shared.DrxCleanup == cleanup then shared.DrxCleanup = nil end
    for k,e in pairs(ESP) do destroyESP(e); ESP[k]=nil end
    Overlay:Destroy(); if GUI.Parent then GUI:Destroy() end
end
shared.DrxCleanup = cleanup
GUI.Destroying:Connect(cleanup)

print("[Drx Hub V14] Carregado. Aimbot/Silent via Mouse.")
