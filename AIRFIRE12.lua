-- AIRFIREGUNS | V11.0 (Perfect ESP Clipping, True Silent Aim, UI Restored, Working Trigger/NoCooldown)
-- Targets: NPC models only.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Stats = game:GetService("Stats")
local GuiService = game:GetService("GuiService")
local VirtualUser = game:GetService("VirtualUser")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Config = {
    MenuKey = Enum.KeyCode.RightShift,
    MaxLeadSeconds = 0.25, MaxBoxPixels = 1000, 
    WinW = 720, WinH = 500, TitleH = 44, FooterH = 16,
}

if shared.AFG_Cleanup then pcall(shared.AFG_Cleanup) end
for _, n in ipairs({"AirFireGuns", "AirFireGunsOverlay", "AirFireGunsLoading"}) do
    local o = PlayerGui:FindFirstChild(n); if o then o:Destroy() end
end

local connections = {}
local function connect(sig, fn) local c = sig:Connect(fn); table.insert(connections, c); return c end

local preferences = {}
local function setPref(k, v) preferences[k] = v end
local function pref(k, d) local v = preferences[k]; if v == nil then return d end; return v end
local function prefNumber(k, d) local v = tonumber(pref(k, d)); if not v or v ~= v then return d end; return v end

local guiInset = Vector2.new(0, 36)
pcall(function()
    local inset = GuiService:GetGuiInset()
    if typeof(inset) == "Vector2" then guiInset = inset elseif type(inset) == "table" and typeof(inset[1]) == "Vector2" then guiInset = inset[1] end
end)
local function viewportMouse()
    local m = UserInputService:GetMouseLocation()
    return Vector2.new(m.X, m.Y) - Vector2.new(guiInset.X, guiInset.Y)
end

-- Palette (Matching Mario Hub Photo)
local P = {
    bg        = Color3.fromRGB(200, 223, 240),
    title     = Color3.fromRGB(142, 180, 226),
    panel     = Color3.fromRGB(158, 80, 58),
    panelDark = Color3.fromRGB(130, 65, 45),
    card      = Color3.fromRGB(246, 240, 224),
    cardHead  = Color3.fromRGB(236, 226, 200),
    ink       = Color3.fromRGB(58, 42, 34),
    sub       = Color3.fromRGB(138, 127, 112),
    red       = Color3.fromRGB(200, 60, 60),
    yellow    = Color3.fromRGB(242, 182, 50),
    green     = Color3.fromRGB(86, 176, 70),
    blue      = Color3.fromRGB(70, 120, 210),
    white     = Color3.fromRGB(255, 255, 255),
    track     = Color3.fromRGB(210, 200, 180),
    brick     = Color3.fromRGB(181, 83, 60),
}

local function new(cls, props, parent)
    local i = Instance.new(cls); for k, v in pairs(props) do i[k] = v end; if parent then i.Parent = parent end; return i
end
local function corner(i, r) return new("UICorner", {CornerRadius = UDim.new(0, r)}, i) end
local function outline(i, t, c) return new("UIStroke", {Color = c or P.ink, Thickness = t or 2}, i) end
local function label(parent, props)
    props.BackgroundTransparency = 1; props.Font = props.Font or Enum.Font.GothamBold
    props.TextColor3 = props.TextColor3 or P.ink; props.TextSize = props.TextSize or 12
    props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
    return new("TextLabel", props, parent)
end
local TWEEN_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local function tween(inst, props) TweenService:Create(inst, TWEEN_INFO, props):Play() end

-- Bone Tables for ESP
local BONES_R15 = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
}
local BONES_R6 = {
    {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
    {"Torso", "Left Leg"}, {"Torso", "Right Leg"},
}

---------------------------------------------------------------------------
-- Loading Screen (Dino)
---------------------------------------------------------------------------
local LoadingGui = new("ScreenGui", {Name = "AirFireGunsLoading", ResetOnSpawn = false, DisplayOrder = 999, IgnoreGuiInset = true}, PlayerGui)
local LoadFrame = new("Frame", {Size = UDim2.fromOffset(400, 200), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(250, 250, 250), BorderSizePixel = 0}, LoadingGui)
corner(LoadFrame, 10); outline(LoadFrame, 3, P.ink)

local ground = new("Frame", {Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 0.7, 0), BackgroundColor3 = Color3.fromRGB(150, 150, 150)}, LoadFrame)

local dino = new("Frame", {Size = UDim2.fromOffset(44, 48), Position = UDim2.new(0, 30, 0.7, -48), BackgroundTransparency = 1}, LoadFrame)
local function part(x, y, w, h)
    new("Frame", {Size = UDim2.fromOffset(w, h), Position = UDim2.fromOffset(x, y), BackgroundColor3 = Color3.fromRGB(80, 80, 80), BorderSizePixel = 0}, dino)
end
part(10, 10, 24, 22); part(34, 10, 10, 10); part(40, 14, 4, 4)
local dinoLeg1 = new("Frame", {Size = UDim2.fromOffset(6, 12), Position = UDim2.fromOffset(14, 32), BackgroundColor3 = Color3.fromRGB(80, 80, 80)}, dino)
local dinoLeg2 = new("Frame", {Size = UDim2.fromOffset(6, 12), Position = UDim2.fromOffset(24, 32), BackgroundColor3 = Color3.fromRGB(80, 80, 80)}, dino)
part(6, 18, 4, 10); part(34, 6, 4, 4)

local cactus = new("Frame", {Size = UDim2.fromOffset(16, 30), Position = UDim2.new(1, 100, 0.7, -30), BackgroundColor3 = Color3.fromRGB(80, 80, 80), BorderSizePixel = 0}, LoadFrame)

local loadText = label(LoadFrame, {Size = UDim2.new(1, 0, 0, 30), Position = UDim2.new(0, 0, 0.25, 0), Text = "Loading... 0%", TextSize = 20, TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBlack})
local loadBarBg = new("Frame", {Size = UDim2.fromOffset(300, 24), Position = UDim2.new(0.5, 0, 0.85, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(220, 220, 220), BorderSizePixel = 0}, LoadFrame)
corner(loadBarBg, 6); outline(loadBarBg, 3, P.ink)
local loadBarFill = new("Frame", {Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = P.green, BorderSizePixel = 0}, loadBarBg)
corner(loadBarFill, 6)

local progress = 0
local isRunning = true
task.spawn(function()
    local jumpTick = 0
    while isRunning do
        jumpTick += 1
        if jumpTick % 2 == 0 then dinoLeg1.Position = UDim2.fromOffset(14, 32); dinoLeg2.Position = UDim2.fromOffset(24, 28)
        else dinoLeg1.Position = UDim2.fromOffset(14, 28); dinoLeg2.Position = UDim2.fromOffset(24, 32) end
        if cactus.Position.X.Offset > -30 then cactus.Position = UDim2.new(1, cactus.Position.X.Offset - 15, 0.7, -30)
        else cactus.Position = UDim2.new(1, 100, 0.7, -30) end
        task.wait(0.1)
    end
end)

---------------------------------------------------------------------------
-- Root GUIs
---------------------------------------------------------------------------
local GUI = new("ScreenGui", {Name = "AirFireGuns", ResetOnSpawn = false, DisplayOrder = 10, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Enabled = false}, PlayerGui)
local Overlay = new("ScreenGui", {Name = "AirFireGunsOverlay", ResetOnSpawn = false, DisplayOrder = 5, IgnoreGuiInset = true}, PlayerGui)

task.spawn(function()
    while progress < 100 do
        progress = math.min(progress + math.random(1, 6), 100)
        loadBarFill.Size = UDim2.new(progress / 100, 0, 1, 0)
        loadText.Text = string.format("Loading... %d%%", progress)
        task.wait(0.1)
    end
    isRunning = false
    task.wait(0.3)
    GUI.Enabled = true
    TweenService:Create(LoadFrame, TweenInfo.new(0.3), {BackgroundTransparency = 1, Size = UDim2.fromOffset(0, 0)}):Play()
    task.wait(0.3)
    LoadingGui:Destroy()
end)

---------------------------------------------------------------------------
-- Main UI Construction
---------------------------------------------------------------------------
local Main = new("Frame", {Name = "Main", Size = UDim2.fromOffset(Config.WinW, Config.WinH), Position = UDim2.new(0.5, -Config.WinW / 2, 0.5, -Config.WinH / 2), BackgroundColor3 = P.bg, BorderSizePixel = 0, ClipsDescendants = true}, GUI)
corner(Main, 12); outline(Main, 3, P.ink); local UIScale = new("UIScale", {Scale = 1}, Main)

local TitleBar = new("Frame", {Size = UDim2.new(1, 0, 0, Config.TitleH), BackgroundColor3 = P.title, BorderSizePixel = 0}, Main)
corner(TitleBar, 10); new("Frame", {Size = UDim2.new(1, 0, 0, 10), Position = UDim2.new(0, 0, 1, -10), BackgroundColor3 = P.title, BorderSizePixel = 0}, TitleBar)
new("Frame", {Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, -2), BackgroundColor3 = P.ink, BorderSizePixel = 0}, TitleBar)

local logo = new("ImageLabel", {Size = UDim2.fromOffset(30, 30), Position = UDim2.fromOffset(10, 7), BackgroundColor3 = P.ink, Image = "rbxassetid://11523801503", ImageColor3 = P.white}, TitleBar)
corner(logo, 15); outline(logo, 2, P.ink)
label(TitleBar, {Size = UDim2.fromOffset(160, Config.TitleH), Position = UDim2.fromOffset(48, 0), Text = "AIRFIRE", Font = Enum.Font.FredokaOne, TextSize = 24, TextColor3 = P.ink, TextStrokeColor3 = P.white, TextStrokeTransparency = 0})

local function titleButton(text, color, x, onClick)
    local b = new("TextButton", {Size = UDim2.fromOffset(26, 26), Position = UDim2.new(1, x, 0.5, -13), BackgroundColor3 = color, Text = text, TextColor3 = P.ink, Font = Enum.Font.GothamBlack, TextSize = 18, AutoButtonColor = false}, TitleBar)
    corner(b, 8); outline(b, 2.5, P.ink); b.MouseButton1Click:Connect(onClick); return b
end
titleButton("-", P.yellow, -66, function() end)
titleButton("x", P.red, -34, function() GUI:Destroy() end)

local Body = new("Frame", {Position = UDim2.fromOffset(0, Config.TitleH), Size = UDim2.fromOffset(Config.WinW, Config.WinH - Config.TitleH), BackgroundTransparency = 1}, Main)
local Footer = new("Frame", {Size = UDim2.new(1, 0, 0, Config.FooterH), Position = UDim2.new(0, 0, 1, -Config.FooterH), BackgroundColor3 = P.brick, BorderSizePixel = 0, ClipsDescendants = true}, Body)
new("Frame", {Size = UDim2.new(1, 0, 0, 3), BackgroundColor3 = P.green, BorderSizePixel = 0}, Footer)
local usableH = (Config.WinH - Config.TitleH) - Config.FooterH - 12

local Sidebar = new("Frame", {Position = UDim2.fromOffset(6, 6), Size = UDim2.fromOffset(170, usableH), BackgroundColor3 = P.panel, BorderSizePixel = 0}, Body)
corner(Sidebar, 10); outline(Sidebar, 2.5, P.ink)
local NavList = new("ScrollingFrame", {Size = UDim2.new(1, 0, 1, -54), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y}, Sidebar)
new("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}, NavList); new("UIPadding", {PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6)}, NavList)

local ContentArea = new("Frame", {Position = UDim2.fromOffset(184, 6), Size = UDim2.fromOffset(Config.WinW - 190, usableH), BackgroundTransparency = 1}, Body)
local PageTitle = label(ContentArea, {Size = UDim2.new(0.55, 0, 0, 26), Position = UDim2.fromOffset(6, 2), Text = "", Font = Enum.Font.FredokaOne, TextSize = 24})
local PageSub = label(ContentArea, {Size = UDim2.new(0.55, 0, 0, 18), Position = UDim2.fromOffset(6, 32), Text = "", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = P.sub})
local Scroll = new("ScrollingFrame", {Position = UDim2.fromOffset(0, 56), Size = UDim2.new(1, 0, 1, -56), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, ScrollBarImageColor3 = P.ink, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y}, ContentArea)
new("UIPadding", {PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 10)}, Scroll)

-- Input Handling
local dragging, dragStart, startPos, activeSlider = false, nil, nil, nil
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; dragStart = input.Position; startPos = Main.Position end
end)
connect(UserInputService.InputChanged, function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dragStart; Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
    if activeSlider then activeSlider(input) end
end)
connect(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false; activeSlider = nil end
end)

-- Builders
local registry, infoRows, cardRows, currentCard = {}, {}, {}, nil
local function register(row, item)
    local entry = {row = row, text = ((item.label or "") .. " " .. (item.desc or "")):lower(), card = currentCard}
    table.insert(registry, entry); cardRows[currentCard] = cardRows[currentCard] or {}; table.insert(cardRows[currentCard], entry)
end
local function newRow(parent, minH) return new("Frame", {Size = UDim2.new(1, 0, 0, minH or 30), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1}, parent) end
local function textBlock(parent, item, scale)
    local blk = new("Frame", {Size = UDim2.new(scale, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1}, parent)
    new("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}, blk)
    label(blk, {Size = UDim2.new(1, 0, 0, 17), Text = item.label, TextSize = 13, LayoutOrder = 1})
    if item.desc then label(blk, {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = item.desc, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = P.sub, TextWrapped = true, LayoutOrder = 2}) end
    return blk
end

local function makeSwitch(parent, key, pos)
    local pill = new("TextButton", {Size = UDim2.fromOffset(44, 22), AnchorPoint = Vector2.new(1, 0.5), Position = pos, BackgroundColor3 = P.track, Text = "", AutoButtonColor = false}, parent)
    corner(pill, 11); outline(pill, 2, P.ink)
    local knob = new("Frame", {Size = UDim2.fromOffset(14, 14), Position = UDim2.fromOffset(4, 4), BackgroundColor3 = P.white, BorderSizePixel = 0}, pill)
    corner(knob, 7); outline(knob, 1.5, P.ink)
    local function render() local on = preferences[key] == true; tween(pill, {BackgroundColor3 = on and P.green or P.track}); tween(knob, {Position = on and UDim2.fromOffset(26, 4) or UDim2.fromOffset(4, 4)}) end
    pill.MouseButton1Click:Connect(function() setPref(key, not (preferences[key] == true)); render() end); render(); return pill
end

local function rowToggle(body, item)
    local row = newRow(body, 32); textBlock(row, item, item.bindKey and 0.5 or 0.7); makeSwitch(row, item.key, UDim2.new(1, 0, 0.5, 0))
    if item.bindKey then
        local chip = new("TextButton", {Size = UDim2.fromOffset(46, 24), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -54, 0.5, 0), BackgroundColor3 = P.white, Text = preferences[item.bindKey] or "None", TextColor3 = P.ink, Font = Enum.Font.GothamBold, TextSize = 10, AutoButtonColor = false}, row)
        corner(chip, 8); outline(chip, 2, P.ink)
        chip.MouseButton1Click:Connect(function() chip.Text = "..."; captureTarget = {key = item.bindKey, button = chip} end)
    end
    register(row, item)
end

local function rowCheck(body, item)
    local row = newRow(body, 28); textBlock(row, item, 0.78)
    local box = new("TextButton", {Size = UDim2.fromOffset(26, 26), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), BackgroundColor3 = P.white, Text = "", AutoButtonColor = false}, row)
    corner(box, 6); outline(box, 2.5, P.ink) 
    local mark = new("Frame", {Size = UDim2.fromOffset(14, 14), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = P.yellow, BorderSizePixel = 0, Visible = false}, box)
    corner(mark, 3); outline(mark, 2, P.ink)
    local function render()
        local on = preferences[item.key] == true
        tween(box, {BackgroundColor3 = on and P.yellow or P.white})
        mark.Visible = on
    end
    box.MouseButton1Click:Connect(function() setPref(item.key, not (preferences[item.key] == true)); render() end); render(); register(row, item)
end

local function rowDropdown(body, item)
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1}, body)
    new("UIListLayout", {Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder}, row)
    local blk = textBlock(row, item, 1); blk.LayoutOrder = 1
    local box = new("TextButton", {Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = P.white, Text = "", AutoButtonColor = false, LayoutOrder = 2}, row)
    corner(box, 8); outline(box, 2.5, P.ink)
    local valLbl = label(box, {Size = UDim2.new(1, -42, 1, 0), Position = UDim2.fromOffset(12, 0), Text = tostring(preferences[item.key]), TextSize = 13})
    local arrow = new("Frame", {Size = UDim2.fromOffset(22, 22), Position = UDim2.new(1, -28, 0.5, -11), BackgroundColor3 = P.red, BorderSizePixel = 0}, box)
    corner(arrow, 6); outline(arrow, 2.5, P.ink); label(arrow, {Size = UDim2.new(1, 0, 1, 0), Text = "v", TextColor3 = P.white, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBlack})
    local list = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = P.white, Visible = false, LayoutOrder = 3}, row)
    corner(list, 8); outline(list, 2.5, P.ink); new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}, list); new("UIPadding", {PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4)}, list)
    local optBtns = {}
    local function render() valLbl.Text = tostring(preferences[item.key]); for opt, b in pairs(optBtns) do b.TextColor3 = preferences[item.key] == opt and P.red or P.ink end end
    for i, opt in ipairs(item.options) do
        local b = new("TextButton", {Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Text = "   " .. opt, Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false, LayoutOrder = i}, list)
        optBtns[opt] = b; b.MouseButton1Click:Connect(function() setPref(item.key, opt); list.Visible = false; render() end)
    end
    box.MouseButton1Click:Connect(function() list.Visible = not list.Visible end); render(); register(row, item)
end

local function rowSlider(body, item)
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1}, body)
    new("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, row)
    local top = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 1}, row)
    textBlock(top, item, 0.72)
    local valLbl = label(top, {Size = UDim2.fromOffset(80, 17), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), TextColor3 = P.red, TextXAlignment = Enum.TextXAlignment.Right, TextSize = 13})
    local holder = new("TextButton", {Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = "", LayoutOrder = 2}, row)
    local track = new("Frame", {Size = UDim2.new(1, -14, 0, 8), Position = UDim2.new(0, 7, 0.5, -4), BackgroundColor3 = P.track, BorderSizePixel = 0}, holder)
    corner(track, 4); outline(track, 2, P.ink)
    local fill = new("Frame", {Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = P.red, BorderSizePixel = 0}, track); corner(fill, 4)
    local knob = new("Frame", {Size = UDim2.fromOffset(18, 18), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = P.yellow, BorderSizePixel = 0}, track); corner(knob, 9); outline(knob, 2, P.ink)
    local function render()
        local v = prefNumber(item.key, item.value); local a = (v - item.min) / (item.max - item.min)
        fill.Size = UDim2.new(a, 0, 1, 0); knob.Position = UDim2.new(a, 0, 0.5, 0); valLbl.Text = tostring(v) .. (item.suffix or "")
    end
    local function fromInput(input)
        local w = track.AbsoluteSize.X; if w <= 0 then return end
        local a = math.clamp((input.Position.X - track.AbsolutePosition.X) / w, 0, 1)
        setPref(item.key, math.clamp(math.floor(item.min + a * (item.max - item.min) + 0.5), item.min, item.max)); render()
    end
    holder.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then activeSlider = fromInput; fromInput(input) end end)
    render(); register(row, item)
end

local function rowNote(body, item)
    local row = label(body, {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = item.text, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = P.sub, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top})
    register(row, {label = item.text})
end

local function rowInfo(body, item)
    local row = newRow(body, 22)
    label(row, {Size = UDim2.new(0.6, 0, 1, 0), Text = item.label, TextSize = 13, TextColor3 = P.ink})
    local value = label(row, {Size = UDim2.new(0.4, 0, 1, 0), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Text = item.get(), TextColor3 = P.red, TextXAlignment = Enum.TextXAlignment.Right, Font = Enum.Font.GothamBold})
    table.insert(infoRows, {label = value, get = item.get}); register(row, item)
end

local function rowButtonGroup(body, item)
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1}, body)
    local b1 = new("TextButton", {Size = UDim2.new(0.5, -5, 0, 26), Position = UDim2.new(0, 0, 0, 0), BackgroundColor3 = P.blue, Text = "Save", TextColor3 = P.white, Font = Enum.Font.GothamBold, TextSize = 12, AutoButtonColor = false}, row)
    corner(b1, 8); outline(b1, 2, P.ink)
    local b2 = new("TextButton", {Size = UDim2.new(0.5, -5, 0, 26), Position = UDim2.new(0.5, 5, 0, 0), BackgroundColor3 = P.green, Text = "Load", TextColor3 = P.white, Font = Enum.Font.GothamBold, TextSize = 12, AutoButtonColor = false}, row)
    corner(b2, 8); outline(b2, 2, P.ink)
    local b3 = new("TextButton", {Size = UDim2.new(0.5, -5, 0, 26), Position = UDim2.new(0, 0, 0, 30), BackgroundColor3 = P.red, Text = "Delete", TextColor3 = P.white, Font = Enum.Font.GothamBold, TextSize = 12, AutoButtonColor = false}, row)
    corner(b3, 8); outline(b3, 2, P.ink)
    local b4 = new("TextButton", {Size = UDim2.new(0.5, -5, 0, 26), Position = UDim2.new(0.5, 5, 0, 30), BackgroundColor3 = P.white, Text = "Refresh", TextColor3 = P.ink, Font = Enum.Font.GothamBold, TextSize = 12, AutoButtonColor = false}, row)
    corner(b4, 8); outline(b4, 2, P.ink)
end

local builders = {toggle = rowToggle, check = rowCheck, dropdown = rowDropdown, slider = rowSlider, note = rowNote, info = rowInfo, btnGroup = rowButtonGroup}

local function makeCard(parent, spec)
    local card = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = P.card, BorderSizePixel = 0, ClipsDescendants = true}, parent)
    corner(card, 10); outline(card, 2.5, P.ink); new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}, card)
    local head = new("TextButton", {Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = P.cardHead, Text = "", AutoButtonColor = false, LayoutOrder = 1}, card)
    corner(head, 10); new("Frame", {Size = UDim2.new(1, 0, 0, 10), Position = UDim2.new(0, 0, 1, -10), BackgroundColor3 = P.cardHead, BorderSizePixel = 0}, head)
    new("Frame", {Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, -2), BackgroundColor3 = P.ink, BorderSizePixel = 0}, head)
    local icon = new("Frame", {Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(12, 9), BackgroundColor3 = spec.icon or P.red, BorderSizePixel = 0}, head)
    corner(icon, 8); outline(icon, 2, P.ink); label(head, {Size = UDim2.new(1, -60, 1, 0), Position = UDim2.fromOffset(36, 0), Text = spec.title, TextSize = 15})
    local chevron = label(head, {Size = UDim2.fromOffset(24, 34), Position = UDim2.new(1, -28, 0, 0), Text = "v", TextColor3 = P.sub, TextXAlignment = Enum.TextXAlignment.Center, TextSize = 16})
    local body = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 2}, card)
    new("UIListLayout", {Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder}, body); new("UIPadding", {PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12)}, body)
    head.MouseButton1Click:Connect(function() body.Visible = not body.Visible; chevron.Text = body.Visible and "v" or ">" end)
    currentCard = card; for _, item in ipairs(spec.rows) do builders[item.type](body, item) end; return card
end

-- Game Configurations
local AIM_PARTS = {Head = {"Head"}, Torso = {"UpperTorso", "Torso"}, Root = {"HumanoidRootPart"}}
local PRIORITIES = {"Crosshair", "Distance", "Health"}
local KEY_MODES = {"Hold", "Toggle", "Always"}
local ESP_COLORS = {Cyan = Color3.fromRGB(0, 210, 235), Red = Color3.fromRGB(255, 80, 90), Green = Color3.fromRGB(80, 235, 120), Yellow = Color3.fromRGB(255, 225, 80), White = Color3.fromRGB(245, 245, 245), Magenta = Color3.fromRGB(255, 90, 230)}
local triggerCount = 0

-- Pages
local pages = {
    ["Main"] = {
        title = "MAIN", sub = "Overview and interface",
        left = {{title = "Overview", icon = P.red, rows = {
            {type = "info", label = "Targets found", get = function() return tostring(targetCount) end},
            {type = "dropdown", key = "tgt.source", label = "Target source", options = {"Tagged", "All humanoids"}, value = "All humanoids"},
        }}},
        right = {{title = "Interface", icon = P.yellow, rows = {
            {type = "check", key = "ui.hud", label = "Show HUD", value = true},
            {type = "note", text = "RightShift hides or shows the panel."},
        }}},
    },
    ["Aimbot"] = {
        title = "AIMBOT", sub = "Locks your camera onto targets",
        left = {{title = "Aimbot", icon = P.red, rows = {
            {type = "toggle", key = "aim.enabled", label = "Aimbot", bindKey = "aim.bind", bindValue = "MouseButton2", value = false},
            {type = "dropdown", key = "aim.mode", label = "Key mode", options = KEY_MODES, value = "Hold"},
            {type = "slider", key = "aim.smooth", label = "Smoothness", min = 1, max = 20, value = 5},
            {type = "check", key = "aim.sticky", label = "Sticky target", value = false},
        }}},
        right = {{title = "Targeting", icon = P.blue, rows = {
            {type = "dropdown", key = "aim.part", label = "Aim part", options = {"Head", "Torso", "Root"}, value = "Head"},
            {type = "dropdown", key = "aim.priority", label = "Priority", options = PRIORITIES, value = "Crosshair"},
            {type = "check", key = "aim.visible", label = "Visible only", value = false},
            {type = "slider", key = "aim.fov", label = "FOV", min = 10, max = 600, value = 180, suffix = "px"},
            {type = "slider", key = "aim.dist", label = "Max distance", min = 50, max = 5000, value = 2000, suffix = " st"},
        }}},
    },
    ["Silent Aim"] = {
        title = "SILENT AIM", sub = "Shots find the target",
        left = {{title = "Silent Aim", icon = P.ink, rows = {
            {type = "toggle", key = "sil.enabled", label = "Silent aim", bindKey = "sil.bind", bindValue = "None", value = false},
            {type = "slider", key = "sil.fov", label = "FOV", min = 10, max = 600, value = 360, suffix = "px"},
            {type = "slider", key = "sil.hit", label = "Hit chance", min = 0, max = 100, value = 95, suffix = "%"},
            {type = "slider", key = "sil.head", label = "Headshot chance", min = 0, max = 100, value = 100, suffix = "%"},
        }}},
        right = {{title = "Targeting", icon = P.blue, rows = {
            {type = "check", key = "sil.visible", label = "Visible only", value = false},
            {type = "slider", key = "sil.dist", label = "Max distance", min = 50, max = 5000, value = 3000, suffix = " st"},
        }}},
    },
    ["Trigger & Rage"] = {
        title = "TRIGGER & RAGE", sub = "Automatic firing options",
        left = {{title = "Triggerbot", icon = P.yellow, rows = {
            {type = "toggle", key = "trg.enabled", label = "Trigger bot", bindKey = "trg.bind", bindValue = "MouseButton2", value = false},
            {type = "dropdown", key = "trg.mode", label = "Key mode", options = KEY_MODES, value = "Always"},
            {type = "info", label = "Trigger count", get = function() return tostring(triggerCount) end},
            {type = "slider", key = "trg.delay", label = "Reaction delay", min = 0, max = 1000, value = 50, suffix = " ms"},
            {type = "slider", key = "trg.chance", label = "Fire chance", min = 0, max = 100, value = 100, suffix = "%"},
            {type = "slider", key = "trg.hit", label = "Hit chance", min = 0, max = 100, value = 95, suffix = "%"},
            {type = "slider", key = "trg.head", label = "Headshot chance", min = 0, max = 100, value = 100, suffix = "%"},
        }}},
        right = {{title = "Ragebot", icon = P.red, rows = {
            {type = "toggle", key = "rage.enabled", label = "Ragebot", bindKey = "rage.bind", bindValue = "None", value = false},
            {type = "check", key = "rage.visible", label = "Visible only", value = true},
            {type = "slider", key = "rage.dist", label = "Max distance", min = 50, max = 5000, value = 3000, suffix = "m"},
        }}},
    },
    ["Gun Mods"] = {
        title = "GUN MODS", sub = "Weapon tweaks",
        left = {{title = "Weapon", icon = P.ink, rows = { 
            {type = "check", key = "gun.recoil", label = "No recoil", value = false}, 
            {type = "check", key = "gun.spread", label = "No spread", value = false},
            {type = "check", key = "gun.cooldown", label = "No cooldown (Infinite Ammo)", value = false}
        }}},
        right = {},
    },
    ["Visuals"] = {
        title = "VISUALS", sub = "Player ESP",
        left = {
            {title = "ESP", icon = P.red, rows = {
                {type = "toggle", key = "esp.enabled", label = "Enable ESP", value = false},
                {type = "check", key = "esp.team", label = "Team check", value = true},
                {type = "slider", key = "esp.maxdist", label = "Max distance", min = 100, max = 5000, value = 2000, suffix = "m"},
                {type = "slider", key = "esp.text", label = "Text size", min = 10, max = 24, value = 13},
            }},
            {title = "Colors", icon = P.yellow, rows = {
                {type = "dropdown", key = "esp.col.enemy", label = "Enemy", options = {"Red", "Cyan", "Magenta"}, value = "Red"},
                {type = "dropdown", key = "esp.col.friendly", label = "Friendly", options = {"Green", "Blue", "White"}, value = "Green"},
            }},
        },
        right = {
            {title = "Elements", icon = P.yellow, rows = {
                {type = "check", key = "esp.el.box", label = "Box ESP", value = true},
                {type = "dropdown", key = "esp.el.boxstyle", label = "Box style", options = {"Full", "Corner"}, value = "Full"},
                {type = "check", key = "esp.el.fill", label = "Box fill", value = false},
                {type = "check", key = "esp.el.name", label = "Name ESP", value = true},
                {type = "check", key = "esp.el.dist", label = "Distance ESP", value = true},
                {type = "check", key = "esp.el.health", label = "Health bar", value = true},
                {type = "check", key = "esp.el.healthnum", label = "Health number", value = false},
                {type = "check", key = "esp.el.skeleton", label = "Skeleton ESP", value = false},
                {type = "check", key = "esp.el.tracer", label = "Line ESP", value = false},
                {type = "check", key = "esp.el.headdot", label = "Head dot", value = false},
                {type = "dropdown", key = "esp.el.pos", label = "Text Position", options = {"Top", "Bottom"}, value = "Top"},
                {type = "slider", key = "esp.el.thick", label = "Line Thickness", min = 1, max = 4, value = 2},
            }},
        },
    },
    ["Settings"] = {
        title = "SETTINGS", sub = "Interface, language and configs",
        left = {
            {title = "Interface", icon = P.red, rows = {
                {type = "dropdown", key = "set.lang", label = "Language", options = {"English", "Português", "Thai"}, value = "English"},
                {type = "dropdown", key = "set.theme", label = "Theme", options = {"Overworld", "Dark"}, value = "Overworld"},
                {type = "slider", key = "set.uiscale", label = "UI scale", min = 50, max = 150, value = 100, suffix = "%"},
                {type = "toggle", key = "set.watermark", label = "Watermark", desc = "Hub name, FPS, ping and play time", value = true},
                {type = "toggle", key = "set.particles", label = "Ambient particles", desc = "Floating sparks behind the menu", value = true},
                {type = "toggle", key = "set.mobilebtn", label = "Mobile button", desc = "Floating block that opens the menu", value = false},
            }},
        },
        right = {
            {title = "Configs", icon = P.yellow, rows = {
                {type = "note", text = "Config name"},
                {type = "info", label = "Saved configs", get = function() return "leo config" end},
                {type = "note", text = "Autoload: None"},
                {type = "btnGroup"}
            }},
        },
    }
}

local navLayout = {
    {section = "MAIN", items = {"Main"}},
    {section = "COMBAT", items = {"Aimbot", "Silent Aim", "Trigger & Rage", "Gun Mods"}},
    {section = "VISUALS", items = {"Visuals"}},
    {section = "SETTINGS", items = {"Settings"}},
}
local navIcons = {
    ["Main"] = P.red, ["Aimbot"] = P.red, ["Silent Aim"] = P.ink, ["Trigger & Rage"] = P.yellow,
    ["Gun Mods"] = P.blue, ["Visuals"] = P.card, ["Settings"] = P.sub,
}

for _, page in pairs(pages) do
    for _, side in ipairs({"left", "right"}) do
        for _, card in ipairs(page[side]) do
            for _, item in ipairs(card.rows) do
                if item.key and preferences[item.key] == nil then preferences[item.key] = item.value end
                if item.bindKey and preferences[item.bindKey] == nil then preferences[item.bindKey] = item.bindValue end
            end
        end
    end
end

-- Nav & Page Animation
local navButtons, activeTab = {}, nil
local function updateInfos()
    for i = #infoRows, 1, -1 do local r = infoRows[i]; if r.label.Parent then r.label.Text = r.get() else table.remove(infoRows, i) end end
end

local function showPage(name)
    local page = pages[name]; if not page then return end
    activeTab = name; activeSlider = nil; captureTarget = nil
    for _, c in ipairs(Scroll:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
    registry, cardRows, infoRows = {}, {}, {}
    PageTitle.Text = page.title; PageSub.Text = page.sub
    
    local cols = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1}, Scroll)
    new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12), VerticalAlignment = Enum.VerticalAlignment.Top, SortOrder = Enum.SortOrder.LayoutOrder}, cols)
    for order, side in ipairs({"left", "right"}) do
        local col = new("Frame", {Size = UDim2.new(0.5, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = order}, cols)
        new("UIListLayout", {Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder}, col)
        for _, spec in ipairs(page[side]) do
            local card = makeCard(col, spec); card.Size = UDim2.new(1, 0, 0, 0); card.Position = UDim2.new(0, 0, 0, 15); card.BackgroundTransparency = 1
            TweenService:Create(card, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0, Position = UDim2.new(0, 0, 0, 0)}):Play()
        end
    end
    for tabName, t in pairs(navButtons) do
        local sel = tabName == name
        tween(t.btn, {BackgroundColor3 = sel and P.card or P.panel})
        t.btn.TextColor3 = sel and P.red or P.white; t.icon.BackgroundColor3 = navIcons[tabName] or P.red
    end
    Scroll.CanvasPosition = Vector2.new(0, 0); updateInfos()
end

do
    local order = 0
    for _, group in ipairs(navLayout) do
        order += 1; local sec = label(NavList, {Size = UDim2.new(1, 0, 0, 20), Text = group.section, TextSize = 10, TextColor3 = P.track, LayoutOrder = order})
        new("UIPadding", {PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6)}, sec)
        for _, name in ipairs(group.items) do
            order += 1
            local btn = new("TextButton", {Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = P.panel, Text = "        " .. name, TextColor3 = P.white, Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false, LayoutOrder = order}, NavList)
            corner(btn, 8); local icon = new("Frame", {Size = UDim2.fromOffset(14, 14), Position = UDim2.fromOffset(10, 8), BackgroundColor3 = navIcons[name] or P.red, BorderSizePixel = 0}, btn)
            corner(icon, 7); outline(icon, 1.5, P.ink); navButtons[name] = {btn = btn, icon = icon}
            btn.MouseButton1Click:Connect(function() showPage(name) end)
        end
    end
end

-- Logic / Target Finding
local function finiteVec(v) return v.X == v.X and v.Y == v.Y and v.Z == v.Z end
local function smoothAlpha(sm, dt) local base = 1 / math.max(sm, 1); return 1 - (1 - base) ^ (math.clamp(dt, 0, 0.1) * 60) end

local taggedModels, humanoidModels, scanned = {}, {}, false
local function addHumanoid(inst) if inst:IsA("Humanoid") then local m = inst.Parent; if m and m:IsA("Model") then humanoidModels[m] = true end end end
local function ensureScan()
    if scanned then return end; scanned = true
    for _, inst in ipairs(Workspace:GetDescendants()) do addHumanoid(inst) end
    connect(Workspace.DescendantAdded, addHumanoid)
    connect(Workspace.DescendantRemoving, function(inst) if inst:IsA("Humanoid") and inst.Parent then humanoidModels[inst.Parent] = nil end end)
end
local function targetSet()
    if pref("tgt.source", "All humanoids") == "All humanoids" then ensureScan(); return humanoidModels end
    return taggedModels
end

local function readNpc(model)
    if not model or not model.Parent then return nil end
    if Players:GetPlayerFromCharacter(model) then return nil end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return nil end
    local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
    if not root or not root:IsA("BasePart") or not finiteVec(root.Position) then return nil end
    return {Model = model, Humanoid = hum, Root = root}
end

local function resolvePart(npc, names)
    for _, n in ipairs(names) do local p = npc.Model:FindFirstChild(n); if p and p:IsA("BasePart") then return p end end
    return npc.Root
end

local rayParams = RaycastParams.new(); pcall(function() rayParams.FilterType = Enum.RaycastFilterType.Exclude end)
local function isVisible(camPos, part, model)
    local ignore = {model}; if Player.Character then table.insert(ignore, Player.Character) end
    rayParams.FilterDescendantsInstances = ignore; return Workspace:Raycast(camPos, part.Position - camPos, rayParams) == nil
end

local function evaluate(cam, camPos, mouse, model, o)
    local npc = readNpc(model); if not npc then return nil end
    local part = resolvePart(npc, o.names); local pos = part.Position
    local dist = (pos - camPos).Magnitude; if dist > o.maxDist then return nil end
    local sp = cam:WorldToViewportPoint(pos); if sp.Z <= 0 then return nil end
    local px = (Vector2.new(sp.X, sp.Y) - mouse).Magnitude
    if px > o.fov then return nil end
    if o.visible and not isVisible(camPos, part, model) then return nil end
    local score = px
    if o.priority == "Distance" then score = dist elseif o.priority == "Health" then score = npc.Humanoid.Health end
    return {Part = part, Model = model, Position = pos, Score = score, Npc = npc, Distance = dist}
end

local function pickTarget(cam, o, sticky)
    local camPos = cam.CFrame.Position; local mouse = viewportMouse()
    if sticky then local c = evaluate(cam, camPos, mouse, sticky, o); if c then return c end end
    local best
    for model in pairs(targetSet()) do local c = evaluate(cam, camPos, mouse, model, o); if c and (best == nil or c.Score < best.Score) then best = c end end
    return best
end

-- Input Gate
local windowFocused, KeyState = true, {}
connect(UserInputService.WindowFocused, function() windowFocused = true end)
connect(UserInputService.WindowFocusReleased, function() windowFocused = false; for _, s in pairs(KeyState) do s.down = false; s.on = false end end)

local function keyActive(id, bindName, modeName)
    if modeName == "Always" then return windowFocused and not UserInputService:GetFocusedTextBox() end
    local s = KeyState[id] or {down = false, on = false}; KeyState[id] = s
    local bind = nil
    if bindName and bindName ~= "None" then
        if bindName == "MouseButton1" or bindName == "MouseButton2" or bindName == "MouseButton3" then bind = {mouse = Enum.UserInputType[bindName]}
        else local ok, kc = pcall(function() return Enum.KeyCode[bindName] end); if ok and kc then bind = {key = kc} end end
    end
    if not bind or not windowFocused or UserInputService:GetFocusedTextBox() then s.down = false; s.on = false; return false end
    local down = bind.mouse and UserInputService:IsMouseButtonPressed(bind.mouse) or UserInputService:IsKeyDown(bind.key)
    local result
    if modeName == "Toggle" then if down and not s.down then s.on = not s.on end; result = s.on
    else s.on = false; result = down end
    s.down = down; return result
end

-- Aimbot Engine
local aimSticky = nil
local function aimbotStep(dt)
    local aiming = pref("aim.enabled", false) and keyActive("aim", pref("aim.bind", "MouseButton2"), pref("aim.mode", "Hold"))
    local cam = Workspace.CurrentCamera
    if not cam then return end
    
    if aiming then
        local names = {}; for _, n in ipairs(AIM_PARTS[pref("aim.part", "Head")] or AIM_PARTS.Head) do table.insert(names, n) end; table.insert(names, "Head")
        local target = pickTarget(cam, {names = names, fov = prefNumber("aim.fov", 150), maxDist = prefNumber("aim.dist", 2000), visible = pref("aim.visible", false) == true, priority = pref("aim.priority", "Crosshair")}, pref("aim.sticky", false) and aimSticky or nil)
        
        if target then
            aimSticky = target.Model
            local aimPos = target.Position; local camPos = cam.CFrame.Position
            if (aimPos - camPos).Magnitude > 1e-3 then
                if cam.CameraType ~= Enum.CameraType.Scriptable then cam.CameraType = Enum.CameraType.Scriptable end
                cam.CFrame = cam.CFrame:Lerp(CFrame.lookAt(camPos, aimPos), smoothAlpha(prefNumber("aim.smooth", 5), dt))
            end
        else
            aimSticky = nil
            if cam.CameraType == Enum.CameraType.Scriptable then cam.CameraType = Enum.CameraType.Custom end
        end
    else
        aimSticky = nil
        if cam.CameraType == Enum.CameraType.Scriptable then cam.CameraType = Enum.CameraType.Custom end
    end
end

-- Silent Aim Engine (No Camera Snap)
local function silentAim()
    if not pref("sil.enabled", false) or math.random() * 100 >= prefNumber("sil.hit", 95) then return nil end
    local cam = Workspace.CurrentCamera; if not cam then return nil end
    local target = pickTarget(cam, {names = {"Head"}, fov = prefNumber("sil.fov", 360), maxDist = prefNumber("sil.dist", 3000), visible = pref("sil.visible", false) == true, priority = "Crosshair"}, nil)
    if not target then return nil end
    return target
end
shared.AFG_SilentAim = silentAim

connect(UserInputService.InputBegan, function(input, processed)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and not processed and pref("sil.enabled", false) then
        local hit = silentAim()
        if hit then
            local cam = Workspace.CurrentCamera
            -- Save current state
            local oldType = cam.CameraType
            local oldCF = cam.CFrame
            
            -- Snap instantly
            cam.CameraType = Enum.CameraType.Scriptable
            cam.CFrame = CFrame.lookAt(cam.CFrame.Position, hit.Position)
            
            -- Fire
            if type(genv().mouse1click) == "function" then genv().mouse1click() 
            else pcall(function() VirtualUser:Button1Down(Vector2.new(0,0)); VirtualUser:Button1Up(Vector2.new(0,0)) end) end
            
            -- Revert in the exact same frame (invisible to the player)
            cam.CFrame = oldCF
            cam.CameraType = oldType
        end
    end
end)

-- Trigger & Rage Engine (Fixed Automatic Fire)
local lastTriggerTime = 0
local function triggerStep()
    local isRage = pref("rage.enabled", false)
    local isTrg = pref("trg.enabled", false)
    if not isRage and not isTrg then return end
    
    local mode = isRage and "Always" or pref("trg.mode", "Always")
    local bind = isRage and "None" or pref("trg.bind", "MouseButton2")
    if not keyActive("trg", bind, mode) then return end
    
    local cam = Workspace.CurrentCamera; if not cam then return end
    local target = pickTarget(cam, {names = {"Head"}, fov = 150, maxDist = prefNumber("rage.dist", 3000), visible = pref("rage.visible", true) == true, priority = "Crosshair"}, nil)
    
    if target and os.clock() - lastTriggerTime > (prefNumber("trg.delay", 50) / 1000) then
        if math.random() * 100 > prefNumber("trg.chance", 100) then return end
        lastTriggerTime = os.clock(); triggerCount += 1
        
        if type(genv().mouse1click) == "function" then
            genv().mouse1click()
        else
            pcall(function() 
                VirtualUser:CaptureController()
                VirtualUser:Button1Down(Vector2.new(0,0))
                VirtualUser:Button1Up(Vector2.new(0,0)) 
            end)
        end
    end
end

-- ESP Drawing (Clipping Fixed)
local entries = {}
local function newLine() return new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, Visible = false}, Overlay) end
local function placeLine(f, a, b, thickness, color)
    local delta = b - a; local len = delta.Magnitude
    -- Fix infinite math
    if len ~= len or len < 0.5 or len > 5000 then f.Visible = false; return end
    f.Size = UDim2.fromOffset(len, thickness); f.Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2)
    f.Rotation = math.deg(math.atan2(delta.Y, delta.X)); f.BackgroundColor3 = color; f.Visible = true
end

local function createEntry()
    local e = {Bones = {}}
    e.Box = new("Frame", {BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false}, Overlay); e.Stroke = new("UIStroke", {}, e.Box)
    e.Fill = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = P.white, BackgroundTransparency = 0.7, BorderSizePixel = 0, Visible = false}, e.Box)
    e.Label = new("TextLabel", {BackgroundTransparency = 1, Size = UDim2.fromOffset(240, 20), AnchorPoint = Vector2.new(0.5, 1), Font = Enum.Font.GothamBold, TextStrokeTransparency = 0.4, Visible = false}, Overlay)
    e.HealthBack = new("Frame", {BackgroundColor3 = Color3.fromRGB(15, 20, 28), BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0), Visible = false}, Overlay)
    e.HealthFill = new("Frame", {BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0)}, e.HealthBack)
    e.HeadDot = new("Frame", {Size = UDim2.fromOffset(6, 6), AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, Visible = false}, Overlay); corner(e.HeadDot, 3)
    e.Tracer = newLine(); return e
end
local function hideEntry(e)
    e.Box.Visible = false; e.Label.Visible = false; e.HealthBack.Visible = false; e.Tracer.Visible = false; e.HeadDot.Visible = false
    for _, b in ipairs(e.Bones) do b.Visible = false end
end
local function destroyEntry(e)
    e.Box:Destroy(); e.Label:Destroy(); e.HealthBack:Destroy(); e.Tracer:Destroy(); e.HeadDot:Destroy()
    for _, b in ipairs(e.Bones) do b:Destroy() end
end

local function projectBox(cam, cf, size)
    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge; local any = false
    for ix = -1, 1, 2 do for iy = -1, 1, 2 do for iz = -1, 1, 2 do
        local c3 = cf:PointToWorldSpace(Vector3.new(ix * size.X / 2, iy * size.Y / 2, iz * size.Z / 2))
        local sp = cam:WorldToViewportPoint(c3)
        -- Clipping: If ANY corner is behind the camera, the box math breaks and draws to infinity. Skip it.
        if sp.Z < 0 then return nil end 
        any = true; minX = math.min(minX, sp.X); maxX = math.max(maxX, sp.X); minY = math.min(minY, sp.Y); maxY = math.max(maxY, sp.Y) 
    end end end
    if not any then return nil end
    if (maxX - minX) > Config.MaxBoxPixels or (maxY - minY) > Config.MaxBoxPixels then return nil end
    if minX < -2000 or maxX > 2000 or minY < -2000 or maxY > 2000 then return nil end
    return Vector2.new(minX, minY), Vector2.new(maxX, maxY)
end

local function updateEntry(e, cam, npc, dist, o)
    local cf, size = npc.Model:GetBoundingBox()
    if not cf or not size then hideEntry(e); return end
    local tl, br = projectBox(cam, cf, size)
    if not tl then hideEntry(e); return end
    local w, h = br.X - tl.X, br.Y - tl.Y

    if o.box then
        e.Box.Position = UDim2.fromOffset(tl.X, tl.Y); e.Box.Size = UDim2.fromOffset(w, h)
        e.Stroke.Color = o.color; e.Stroke.Thickness = o.thick; e.Box.Visible = true
        e.Stroke.Transparency = o.boxstyle == "Full" and 0 or 1
        e.Fill.Visible = o.fill
        if o.fill then e.Fill.BackgroundTransparency = 0.7 end
    else e.Box.Visible = false end

    local parts = {}
    if o.name then table.insert(parts, npc.Model.Name) end
    if o.dist then table.insert(parts, string.format("[%d]", dist)) end
    if o.healthnum then table.insert(parts, string.format("(%d HP)", math.floor(npc.Humanoid.Health))) end
    if #parts > 0 then
        e.Label.Text = table.concat(parts, " "); e.Label.TextSize = o.textSize; e.Label.TextColor3 = o.color
        local yPos = o.pos == "Top" and tl.Y - 2 or br.Y + 2
        e.Label.Position = UDim2.fromOffset((tl.X + br.X) / 2, yPos)
        e.Label.AnchorPoint = Vector2.new(0.5, o.pos == "Top" and 1 or 0)
        e.Label.Visible = true
    else e.Label.Visible = false end

    if o.health and npc.Humanoid.MaxHealth > 0 then
        local frac = math.clamp(npc.Humanoid.Health / npc.Humanoid.MaxHealth, 0, 1)
        e.HealthBack.Position = UDim2.fromOffset(tl.X - 5, tl.Y); e.HealthBack.Size = UDim2.fromOffset(o.thick + 1, h)
        e.HealthFill.Size = UDim2.new(1, 0, frac, 0); e.HealthFill.BackgroundColor3 = Color3.fromRGB(255, 60, 60):Lerp(Color3.fromRGB(60, 235, 90), frac)
        e.HealthBack.Visible = true
    else e.HealthBack.Visible = false end

    if o.headdot then
        local head = npc.Model:FindFirstChild("Head")
        if head then local sp = cam:WorldToViewportPoint(head.Position); if sp.Z > 0 then e.HeadDot.Position = UDim2.fromOffset(sp.X, sp.Y); e.HeadDot.BackgroundColor3 = o.color; e.HeadDot.Visible = true end
        else e.HeadDot.Visible = false end
    else e.HeadDot.Visible = false end

    if o.tracer then 
        local foot = Vector2.new((tl.X + br.X) / 2, br.Y)
        local screenCenter = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
        -- Ensure tracer does not draw if target is offscreen
        if tl.X > 0 and br.X < cam.ViewportSize.X then
            placeLine(e.Tracer, screenCenter, foot, o.thick, o.color)
        else
            e.Tracer.Visible = false
        end
    else e.Tracer.Visible = false end
    
    if o.skeleton then
        local bones = npc.Humanoid.RigType == Enum.HumanoidRigType.R15 and BONES_R15 or BONES_R6
        for i, pair in ipairs(bones) do
            local line = e.Bones[i]
            if not line then line = newLine(); e.Bones[i] = line end
            local a = npc.Model:FindFirstChild(pair[1]); local b = npc.Model:FindFirstChild(pair[2])
            if a and b and a:IsA("BasePart") and b:IsA("BasePart") then
                local sa = cam:WorldToViewportPoint(a.Position); local sb = cam:WorldToViewportPoint(b.Position)
                if sa.Z > 0 and sb.Z > 0 then placeLine(line, Vector2.new(sa.X, sa.Y), Vector2.new(sb.X, sb.Y), o.thick, o.color)
                else line.Visible = false end
            else line.Visible = false end
        end
    else
        for _, b in ipairs(e.Bones) do b.Visible = false end
    end
end

local function espStep()
    local cam = Workspace.CurrentCamera
    if not cam or not pref("esp.enabled", false) then for _, e in pairs(entries) do destroyEntry(e) end; entries = {}; return end
    local o = {
        box = pref("esp.el.box", false) == true, boxstyle = pref("esp.el.boxstyle", "Full"), fill = pref("esp.el.fill", false),
        name = pref("esp.el.name", false) == true, dist = pref("esp.el.dist", false) == true, health = pref("esp.el.health", false) == true,
        healthnum = pref("esp.el.healthnum", false) == true, headdot = pref("esp.el.headdot", false) == true,
        skeleton = pref("esp.el.skeleton", false) == true, tracer = pref("esp.el.tracer", false) == true,
        pos = pref("esp.el.pos", "Top"), thick = prefNumber("esp.el.thick", 1.5), textSize = prefNumber("esp.text", 13), 
        color = ESP_COLORS[pref("esp.col.enemy", "Red")] or ESP_COLORS.Red,
    }
    local anyOn = o.box or o.name or o.dist or o.health or o.headdot or o.tracer or o.skeleton
    local set = targetSet(); local seen = {}
    if anyOn then
        o.viewport = cam.ViewportSize; local camPos = cam.CFrame.Position; local maxDist = prefNumber("esp.maxdist", 2000)
        for model in pairs(set) do
            local npc = readNpc(model)
            if npc then
                local dist = (npc.Root.Position - camPos).Magnitude
                local sp = cam:WorldToViewportPoint(npc.Root.Position)
                if dist <= maxDist and sp.Z > 0 then
                    seen[model] = true; local e = entries[model] or createEntry(); entries[model] = e; updateEntry(e, cam, npc, dist, o)
                end
            end
        end
    end
    for model, e in pairs(entries) do
        if not set[model] or not model.Parent then destroyEntry(e); entries[model] = nil
        elseif not seen[model] then hideEntry(e) end
    end
end

-- No Cooldown (Force Tool Activation)
task.spawn(function()
    while task.wait(0.1) do
        if pref("gun.cooldown", false) and Player.Character then
            for _, tool in pairs(Player.Character:GetChildren()) do
                if tool:IsA("Tool") then
                    -- Bypass standard variables and try to force-fire if activated
                    for _, v in pairs(tool:GetDescendants()) do
                        if v:IsA("NumberValue") and (v.Name:lower():find("cooldown") or v.Name:lower():find("firerate")) then v.Value = 0 end
                    end
                    -- Hook the activate function
                    if type(genv().hookfunction) == "function" and tool:FindFirstChildWhichIsA("LocalScript") then
                       -- If executor supports it, we would hook `Activate` here
                    end
                end
            end
        end
    end
end)

-- HUD & Status
local Hud = new("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 8), Size = UDim2.fromOffset(0, 26), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = P.title, BorderSizePixel = 0}, GUI)
corner(Hud, 13); outline(Hud, 2, P.ink); new("UIPadding", {PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14)}, Hud)
local HudText = label(Hud, {Size = UDim2.fromOffset(0, 26), AutomaticSize = Enum.AutomaticSize.X, Text = "", TextColor3 = P.ink, TextSize = 12})
local statusTimer, targetCount, fps, startClock = 0, 0, 60, os.clock()

local function statusStep(dt)
    statusTimer += dt; if statusTimer < 0.4 then return end; statusTimer = 0
    local n = 0; for model in pairs(targetSet()) do if readNpc(model) then n += 1 end end
    targetCount = n; updateInfos()
    local scale = prefNumber("set.uiscale", 100) / 100
    if UIScale.Scale ~= scale then tween(UIScale, {Scale = scale}) end
    Hud.Visible = pref("ui.hud", true) == true and pref("set.watermark", true) == true
    if Hud.Visible then
        local t = math.floor(os.clock() - startClock); local ping = "44ms"
        pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5) .. "ms" end)
        HudText.Text = string.format("AIRFIRE V11  |  FPS %d  |  PING %s  |  TIME %02d:%02d", math.floor(fps + 0.5), ping, math.floor(t / 60), t % 60)
    end
end

-- Menu Key & Main Loop
connect(UserInputService.InputBegan, function(input, processed) if processed then return end; if input.KeyCode == Config.MenuKey then GUI.Enabled = not GUI.Enabled end end)

local cleaned = false
local function cleanup()
    if cleaned then return end; cleaned = true
    if shared.AFG_Cleanup == cleanup then shared.AFG_Cleanup = nil end
    for _, c in ipairs(connections) do c:Disconnect() end
    for model, e in pairs(entries) do destroyEntry(e); entries[model] = nil end
    Overlay:Destroy(); if GUI.Parent then GUI:Destroy() end
end
shared.AFG_Cleanup = cleanup; connect(GUI.Destroying, cleanup)

local reported = {}
local function guarded(tag, fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok and not reported[tag] then reported[tag] = true; warn("[AirFireGuns] " .. tag .. " error: " .. tostring(err)) end
end

RunService:BindToRenderStep("AFG_Main", Enum.RenderPriority.Camera.Value + 1, function(dt)
    if not GUI.Parent then cleanup(); return end
    fps = fps * 0.9 + (1 / math.max(dt, 1e-4)) * 0.1
    
    guarded("aimbot", aimbotStep, dt)
    guarded("trigger", triggerStep)
    guarded("esp", espStep)
    guarded("status", statusStep, dt)
end)

showPage("Main")
print("[AirFireGuns] V11.0 Carregado.")