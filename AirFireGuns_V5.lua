-- AIRFIREGUNS | V5 (single LocalScript)
-- Hub-style panel (sidebar sections, two-column cards, search, dropdowns, sliders)
-- + Aimbot + Silent Aim + ESP.
-- Targets are NPC models only: tagged AFG_NPC, or every non-player model with a Humanoid.
-- Player characters are never targeted. RightShift hides/shows the panel.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Stats = game:GetService("Stats")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Config = {
    NpcTag = "AFG_NPC",
    MainStepName = "AFG_Main",
    RestoreStepName = "AFG_Restore",
    MenuKey = Enum.KeyCode.RightShift,
    MaxLeadSeconds = 0.25,   -- UNCALIBRATED: Prediction/Lead 100% = this much lead
    MaxBoxPixels = 20000,
    WinW = 640, WinH = 420, TitleH = 40, FooterH = 14,
}

---------------------------------------------------------------------------
-- Re-run safety
---------------------------------------------------------------------------
if shared.AFG_Cleanup then pcall(shared.AFG_Cleanup) end
for _, n in ipairs({"AirFireGuns", "AirFireGunsOverlay"}) do
    local o = PlayerGui:FindFirstChild(n)
    if o then o:Destroy() end
end
pcall(function() RunService:UnbindFromRenderStep(Config.MainStepName) end)
pcall(function() RunService:UnbindFromRenderStep(Config.RestoreStepName) end)

local connections = {}
local function connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(connections, c)
    return c
end

---------------------------------------------------------------------------
-- Preferences
---------------------------------------------------------------------------
local preferences = {}
local onChange = {}

local function setPref(key, value)
    preferences[key] = value
    if onChange[key] then onChange[key](value) end
end
local function pref(key, default)
    local v = preferences[key]
    if v == nil then return default end
    return v
end
local function prefNumber(key, default)
    local v = tonumber(pref(key, default))
    if v == nil or v ~= v or v == math.huge or v == -math.huge then return default end
    return v
end

---------------------------------------------------------------------------
-- Palette / helpers
---------------------------------------------------------------------------
local P = {
    frame = Color3.fromRGB(43, 53, 82),
    title = Color3.fromRGB(112, 148, 214),
    side = Color3.fromRGB(158, 80, 58),
    sideDark = Color3.fromRGB(128, 62, 44),
    sideText = Color3.fromRGB(232, 196, 176),
    content = Color3.fromRGB(205, 224, 240),
    card = Color3.fromRGB(246, 240, 224),
    cardHead = Color3.fromRGB(236, 226, 200),
    ink = Color3.fromRGB(58, 42, 34),
    sub = Color3.fromRGB(138, 127, 112),
    red = Color3.fromRGB(200, 50, 60),
    yellow = Color3.fromRGB(242, 182, 50),
    green = Color3.fromRGB(86, 176, 70),
    track = Color3.fromRGB(224, 214, 190),
    white = Color3.fromRGB(255, 255, 255),
    brick = Color3.fromRGB(181, 83, 60),
    blue = Color3.fromRGB(70, 120, 210),
}

local function new(class, props, parent)
    local i = Instance.new(class)
    for k, v in pairs(props) do i[k] = v end
    if parent then i.Parent = parent end
    return i
end
local function corner(i, r) return new("UICorner", {CornerRadius = UDim.new(0, r)}, i) end
local function outline(i, thick, color)
    return new("UIStroke", {Color = color or P.frame, Thickness = thick or 1.5}, i)
end
local function tween(inst, props, t)
    if preferences["ui.anim"] then
        TweenService:Create(inst, TweenInfo.new(t or 0.15, Enum.EasingStyle.Quad), props):Play()
    else
        for k, v in pairs(props) do inst[k] = v end
    end
end
local function label(parent, props)
    props.BackgroundTransparency = 1
    props.Font = props.Font or Enum.Font.GothamBold
    props.TextColor3 = props.TextColor3 or P.ink
    props.TextSize = props.TextSize or 12
    props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
    return new("TextLabel", props, parent)
end

---------------------------------------------------------------------------
-- Forward-declared runtime state used by the UI
---------------------------------------------------------------------------
local targetCount = 0
local fps = 60
local startClock = os.clock()

---------------------------------------------------------------------------
-- Root GUIs
---------------------------------------------------------------------------
local GUI = new("ScreenGui", {
    Name = "AirFireGuns", ResetOnSpawn = false, DisplayOrder = 10,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, PlayerGui)

local Overlay = new("ScreenGui", {
    Name = "AirFireGunsOverlay", ResetOnSpawn = false, DisplayOrder = 0,
    IgnoreGuiInset = true, -- WorldToViewportPoint coordinates match 1:1
}, PlayerGui)

local Main = new("Frame", {
    Name = "Main",
    Size = UDim2.fromOffset(Config.WinW, Config.WinH),
    Position = UDim2.new(0.5, -Config.WinW / 2, 0.5, -Config.WinH / 2),
    BackgroundColor3 = P.content, BorderSizePixel = 0, ClipsDescendants = true,
}, GUI)
corner(Main, 12)
outline(Main, 2)

---------------------------------------------------------------------------
-- Title bar
---------------------------------------------------------------------------
local TitleBar = new("Frame", {
    Size = UDim2.new(1, 0, 0, Config.TitleH), BackgroundColor3 = P.title, BorderSizePixel = 0,
}, Main)
corner(TitleBar, 10)
new("Frame", { -- squares the lower corners
    Size = UDim2.new(1, 0, 0, 10), Position = UDim2.new(0, 0, 1, -10),
    BackgroundColor3 = P.title, BorderSizePixel = 0,
}, TitleBar)
new("Frame", { -- bottom divider
    Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, -2),
    BackgroundColor3 = P.frame, BorderSizePixel = 0,
}, TitleBar)

local function cloud(x, y, w)
    local c = new("Frame", {
        Size = UDim2.fromOffset(w, 12), Position = UDim2.fromOffset(x, y),
        BackgroundColor3 = P.white, BackgroundTransparency = 0.25, BorderSizePixel = 0,
    }, TitleBar)
    corner(c, 6)
end
cloud(400, 8, 40); cloud(440, 18, 26)

local logo = new("Frame", {
    Size = UDim2.fromOffset(26, 26), Position = UDim2.fromOffset(10, 7), BackgroundColor3 = P.red,
}, TitleBar)
corner(logo, 13)
outline(logo, 1.5)
label(logo, {Size = UDim2.new(1, 0, 1, 0), Text = "A", TextColor3 = P.white, TextSize = 15,
    TextXAlignment = Enum.TextXAlignment.Center})

local titleText = label(TitleBar, {
    Size = UDim2.fromOffset(150, Config.TitleH), Position = UDim2.fromOffset(42, 0),
    Text = "AIRFIREGUNS", Font = Enum.Font.FredokaOne, TextSize = 20, TextColor3 = P.white,
})
titleText.TextStrokeColor3 = P.frame
titleText.TextStrokeTransparency = 0
new("UIGradient", {Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 90, 80)),
    ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 210, 70)),
    ColorSequenceKeypoint.new(0.7, Color3.fromRGB(110, 220, 110)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(110, 180, 255)),
})}, titleText)

local versionChip = new("Frame", {
    Size = UDim2.fromOffset(92, 18), Position = UDim2.fromOffset(196, 11),
    BackgroundColor3 = Color3.fromRGB(92, 124, 188),
}, TitleBar)
corner(versionChip, 9)
label(versionChip, {Size = UDim2.new(1, 0, 1, 0), Text = "v5 · NPC mode", TextSize = 10,
    TextColor3 = P.white, TextXAlignment = Enum.TextXAlignment.Center})

local function titleButton(text, color, x, onClick)
    local b = new("TextButton", {
        Size = UDim2.fromOffset(24, 24), Position = UDim2.new(1, x, 0.5, -12),
        BackgroundColor3 = color, Text = text, TextColor3 = P.white,
        Font = Enum.Font.GothamBold, TextSize = 14, AutoButtonColor = false,
    }, TitleBar)
    corner(b, 6)
    outline(b, 1.5)
    b.MouseButton1Click:Connect(onClick)
    return b
end

local Body = new("Frame", {
    Position = UDim2.fromOffset(0, Config.TitleH),
    Size = UDim2.fromOffset(Config.WinW, Config.WinH - Config.TitleH),
    BackgroundTransparency = 1,
}, Main)

local minimized = false
local function setMinimized(state)
    minimized = state
    local target = state and Config.TitleH or Config.WinH
    if state then
        if preferences["ui.anim"] then
            TweenService:Create(Main, TweenInfo.new(0.2, Enum.EasingStyle.Quad),
                {Size = UDim2.fromOffset(Config.WinW, target)}):Play()
            task.delay(0.21, function() if minimized then Body.Visible = false end end)
        else
            Main.Size = UDim2.fromOffset(Config.WinW, target)
            Body.Visible = false
        end
    else
        Body.Visible = true
        if preferences["ui.anim"] then
            TweenService:Create(Main, TweenInfo.new(0.2, Enum.EasingStyle.Quad),
                {Size = UDim2.fromOffset(Config.WinW, target)}):Play()
        else
            Main.Size = UDim2.fromOffset(Config.WinW, target)
        end
    end
end

titleButton("-", P.yellow, -58, function() setMinimized(not minimized) end)
titleButton("x", P.red, -30, function() GUI:Destroy() end)

-- Drag (title bar) and slider drag share one InputChanged / InputEnded handler
local dragging, dragStart, startPos = false, nil, nil
local activeSlider = nil

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
end)
connect(UserInputService.InputChanged, function(input)
    local t = input.UserInputType
    if t ~= Enum.UserInputType.MouseMovement and t ~= Enum.UserInputType.Touch then return end
    if dragging then
        local d = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
            startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
    if activeSlider then activeSlider(input) end
end)
connect(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
        activeSlider = nil
    end
end)

---------------------------------------------------------------------------
-- Footer (brick strip)
---------------------------------------------------------------------------
local bodyH = Config.WinH - Config.TitleH
local Footer = new("Frame", {
    Size = UDim2.new(1, 0, 0, Config.FooterH), Position = UDim2.new(0, 0, 1, -Config.FooterH),
    BackgroundColor3 = P.brick, BorderSizePixel = 0, ClipsDescendants = true,
}, Body)
new("Frame", {Size = UDim2.new(1, 0, 0, 3), BackgroundColor3 = P.green, BorderSizePixel = 0}, Footer)
for row = 0, 1 do
    new("Frame", {
        Size = UDim2.new(1, 0, 0, 1), Position = UDim2.fromOffset(0, 4 + row * 5 + 5),
        BackgroundColor3 = Color3.fromRGB(120, 50, 36), BorderSizePixel = 0,
    }, Footer)
    for x = (row == 0 and 0 or 15), Config.WinW, 30 do
        new("Frame", {
            Size = UDim2.fromOffset(1, 5), Position = UDim2.fromOffset(x, 4 + row * 5),
            BackgroundColor3 = Color3.fromRGB(120, 50, 36), BorderSizePixel = 0,
        }, Footer)
    end
end

local usableH = bodyH - Config.FooterH - 12

---------------------------------------------------------------------------
-- Sidebar
---------------------------------------------------------------------------
local Sidebar = new("Frame", {
    Position = UDim2.fromOffset(6, 6), Size = UDim2.fromOffset(150, usableH),
    BackgroundColor3 = P.side, BorderSizePixel = 0,
}, Body)
corner(Sidebar, 8)
outline(Sidebar, 1.5)

local NavList = new("ScrollingFrame", {
    Size = UDim2.new(1, 0, 1, -46), BackgroundTransparency = 1, BorderSizePixel = 0,
    ScrollBarThickness = 3, ScrollBarImageColor3 = P.sideText,
    CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, Sidebar)
new("UIListLayout", {Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder}, NavList)
new("UIPadding", {PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 8)}, NavList)

local UserChip = new("Frame", {
    Size = UDim2.new(1, -12, 0, 38), Position = UDim2.new(0, 6, 1, -42),
    BackgroundColor3 = P.sideDark, BorderSizePixel = 0,
}, Sidebar)
corner(UserChip, 8)
local avatar = new("ImageLabel", {
    Size = UDim2.fromOffset(28, 28), Position = UDim2.fromOffset(5, 5),
    BackgroundColor3 = P.card, BorderSizePixel = 0,
}, UserChip)
corner(avatar, 14)
label(UserChip, {Size = UDim2.new(1, -42, 0, 16), Position = UDim2.fromOffset(38, 4),
    Text = Player.DisplayName, TextColor3 = P.white, TextSize = 11, TextTruncate = Enum.TextTruncate.AtEnd})
label(UserChip, {Size = UDim2.new(1, -42, 0, 14), Position = UDim2.fromOffset(38, 20),
    Text = "@" .. Player.Name, TextColor3 = P.sideText, TextSize = 9, Font = Enum.Font.Gotham,
    TextTruncate = Enum.TextTruncate.AtEnd})
task.spawn(function()
    local ok, url = pcall(function()
        return Players:GetUserThumbnailAsync(Player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size60x60)
    end)
    if ok and url then avatar.Image = url end
end)

---------------------------------------------------------------------------
-- Content area: page header + search + scrolling cards
---------------------------------------------------------------------------
local ContentArea = new("Frame", {
    Position = UDim2.fromOffset(164, 6), Size = UDim2.fromOffset(Config.WinW - 170, usableH),
    BackgroundTransparency = 1,
}, Body)

local PageTitle = label(ContentArea, {
    Size = UDim2.new(0.55, 0, 0, 24), Position = UDim2.fromOffset(6, 2),
    Text = "", Font = Enum.Font.FredokaOne, TextSize = 20,
})
local PageSub = label(ContentArea, {
    Size = UDim2.new(0.55, 0, 0, 16), Position = UDim2.fromOffset(6, 26),
    Text = "", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = P.sub,
})

local SearchBox = new("TextBox", {
    Size = UDim2.fromOffset(180, 28), Position = UDim2.new(1, -184, 0, 8),
    BackgroundColor3 = P.white, PlaceholderText = "Search...", PlaceholderColor3 = P.sub,
    Text = "", TextColor3 = P.ink, Font = Enum.Font.GothamMedium, TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false,
}, ContentArea)
corner(SearchBox, 14)
outline(SearchBox, 1.5)
new("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 8)}, SearchBox)

local Scroll = new("ScrollingFrame", {
    Position = UDim2.fromOffset(0, 48), Size = UDim2.new(1, 0, 1, -48),
    BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
    ScrollBarImageColor3 = P.red, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, ContentArea)
new("UIPadding", {PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 6),
    PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 10)}, Scroll)

---------------------------------------------------------------------------
-- Key binds (parsing / capture)
---------------------------------------------------------------------------
local function parseBind(name)
    if name == nil or name == "None" then return nil end
    if name == "MouseButton1" or name == "MouseButton2" or name == "MouseButton3" then
        return {mouse = Enum.UserInputType[name]}
    end
    local ok, kc = pcall(function() return Enum.KeyCode[name] end)
    if ok and kc then return {key = kc} end
    return nil
end

local function bindDisplay(name)
    if name == nil or name == "None" then return "None" end
    if name == "MouseButton1" then return "LMB" end
    if name == "MouseButton2" then return "RMB" end
    if name == "MouseButton3" then return "MMB" end
    return (tostring(name):gsub("Left", "L"):gsub("Right", "R"))
end

local captureTarget = nil -- {key = prefKey, button = TextButton}

connect(UserInputService.InputBegan, function(input, processed)
    if not captureTarget or processed then return end
    local name
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == Enum.KeyCode.Escape then name = "None"
        elseif input.KeyCode ~= Enum.KeyCode.Unknown then name = input.KeyCode.Name end
    elseif input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.MouseButton2
        or input.UserInputType == Enum.UserInputType.MouseButton3 then
        name = input.UserInputType.Name
    end
    if not name then return end
    local t = captureTarget
    captureTarget = nil
    setPref(t.key, name)
    if t.button.Parent then t.button.Text = bindDisplay(name) end
end)

---------------------------------------------------------------------------
-- Row builders
---------------------------------------------------------------------------
local registry = {}   -- {row, text, card}
local infoRows = {}   -- {label, get}
local cardRows = {}   -- [card] = {row entries}
local currentCard = nil

local function register(row, item)
    local entry = {row = row, text = ((item.label or "") .. " " .. (item.desc or "")):lower(), card = currentCard}
    table.insert(registry, entry)
    cardRows[currentCard] = cardRows[currentCard] or {}
    table.insert(cardRows[currentCard], entry)
end

local function newRow(parent, minH)
    return new("Frame", {
        Size = UDim2.new(1, 0, 0, minH or 28), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
    }, parent)
end

local function textBlock(parent, item, widthScale)
    local blk = new("Frame", {
        Size = UDim2.new(widthScale, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
    }, parent)
    new("UIListLayout", {Padding = UDim.new(0, 1), SortOrder = Enum.SortOrder.LayoutOrder}, blk)
    label(blk, {Size = UDim2.new(1, 0, 0, 16), Text = item.label, TextSize = 12, LayoutOrder = 1})
    if item.desc then
        label(blk, {
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = item.desc,
            Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = P.sub, TextWrapped = true,
            TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = 2,
        })
    end
    return blk
end

local function makeSwitch(parent, key, anchorPos)
    local pill = new("TextButton", {
        Size = UDim2.fromOffset(40, 20), AnchorPoint = Vector2.new(1, 0.5), Position = anchorPos,
        BackgroundColor3 = P.card, Text = "", AutoButtonColor = false,
    }, parent)
    corner(pill, 10)
    outline(pill, 1.5)
    local knob = new("Frame", {
        Size = UDim2.fromOffset(12, 12), Position = UDim2.fromOffset(3, 3),
        BackgroundColor3 = P.ink, BorderSizePixel = 0,
    }, pill)
    corner(knob, 6)
    local function render()
        local on = preferences[key] == true
        tween(pill, {BackgroundColor3 = on and P.green or P.card})
        tween(knob, {Position = on and UDim2.fromOffset(25, 3) or UDim2.fromOffset(3, 3),
            BackgroundColor3 = on and P.white or P.ink})
    end
    pill.MouseButton1Click:Connect(function()
        setPref(key, not (preferences[key] == true))
        render()
    end)
    render()
    return pill
end

local function rowToggle(body, item)
    local row = newRow(body, 30)
    textBlock(row, item, item.bindKey and 0.5 or 0.7)
    makeSwitch(row, item.key, UDim2.new(1, 0, 0.5, 0))
    if item.bindKey then
        local chip = new("TextButton", {
            Size = UDim2.fromOffset(38, 22), AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -48, 0.5, 0), BackgroundColor3 = P.card,
            Text = bindDisplay(preferences[item.bindKey]), TextColor3 = P.ink,
            Font = Enum.Font.GothamBold, TextSize = 10, AutoButtonColor = false,
        }, row)
        corner(chip, 6)
        outline(chip, 1.5)
        chip.MouseButton1Click:Connect(function()
            chip.Text = "..."
            captureTarget = {key = item.bindKey, button = chip}
        end)
    end
    register(row, item)
end

local function rowCheck(body, item)
    local row = newRow(body, 26)
    textBlock(row, item, 0.78)
    local box = new("TextButton", {
        Size = UDim2.fromOffset(22, 22), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
        BackgroundColor3 = P.white, Text = "", AutoButtonColor = false,
    }, row)
    corner(box, 5)
    outline(box, 1.5)
    local mark = new("Frame", {
        Size = UDim2.fromOffset(10, 10), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        BackgroundColor3 = P.ink, BorderSizePixel = 0,
    }, box)
    corner(mark, 3)
    local function render()
        local on = preferences[item.key] == true
        box.BackgroundColor3 = on and P.yellow or P.white
        mark.Visible = on
    end
    box.MouseButton1Click:Connect(function()
        setPref(item.key, not (preferences[item.key] == true))
        render()
    end)
    render()
    register(row, item)
end

local function rowDropdown(body, item)
    local row = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
    }, body)
    new("UIListLayout", {Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder}, row)
    local blk = textBlock(row, item, 1)
    blk.LayoutOrder = 1

    local box = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = P.white, Text = "", AutoButtonColor = false,
        LayoutOrder = 2,
    }, row)
    corner(box, 6)
    outline(box, 1.5)
    local valueLabel = label(box, {
        Size = UDim2.new(1, -36, 1, 0), Position = UDim2.fromOffset(8, 0),
        Text = tostring(preferences[item.key]), TextSize = 12,
    })
    local arrow = new("Frame", {
        Size = UDim2.fromOffset(20, 20), Position = UDim2.new(1, -24, 0.5, -10),
        BackgroundColor3 = P.red, BorderSizePixel = 0,
    }, box)
    corner(arrow, 4)
    outline(arrow, 1.2)
    label(arrow, {Size = UDim2.new(1, 0, 1, 0), Text = "v", TextColor3 = P.white, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Center})

    local list = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = P.white, Visible = false, LayoutOrder = 3,
    }, row)
    corner(list, 6)
    outline(list, 1.5)
    new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}, list)

    local optionButtons = {}
    local function render()
        valueLabel.Text = tostring(preferences[item.key])
        for opt, b in pairs(optionButtons) do
            b.TextColor3 = preferences[item.key] == opt and P.red or P.ink
        end
    end
    for i, opt in ipairs(item.options) do
        local b = new("TextButton", {
            Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Text = "  " .. opt,
            Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false, LayoutOrder = i,
        }, list)
        optionButtons[opt] = b
        b.MouseButton1Click:Connect(function()
            setPref(item.key, opt)
            list.Visible = false
            render()
        end)
    end
    box.MouseButton1Click:Connect(function() list.Visible = not list.Visible end)
    render()
    register(row, item)
end

local function rowSlider(body, item)
    local row = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
    }, body)
    new("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}, row)

    local top = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, LayoutOrder = 1,
    }, row)
    textBlock(top, item, 0.72)
    local valueLabel = label(top, {
        Size = UDim2.fromOffset(70, 16), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0),
        TextColor3 = P.red, TextXAlignment = Enum.TextXAlignment.Right,
    })

    local holder = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = "", LayoutOrder = 2,
    }, row)
    local track = new("Frame", {
        Size = UDim2.new(1, -12, 0, 8), Position = UDim2.new(0, 6, 0.5, -4),
        BackgroundColor3 = P.track, BorderSizePixel = 0,
    }, holder)
    corner(track, 4)
    outline(track, 1.2)
    local fill = new("Frame", {Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = P.red, BorderSizePixel = 0}, track)
    corner(fill, 4)
    local knob = new("Frame", {
        Size = UDim2.fromOffset(16, 16), AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = P.yellow, BorderSizePixel = 0,
    }, track)
    corner(knob, 8)
    outline(knob, 1.5)
    label(knob, {Size = UDim2.new(1, 0, 1, 0), Text = "!", TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Center})

    local function render()
        local v = prefNumber(item.key, item.value)
        local a = (v - item.min) / (item.max - item.min)
        fill.Size = UDim2.new(a, 0, 1, 0)
        knob.Position = UDim2.new(a, 0, 0.5, 0)
        valueLabel.Text = tostring(v) .. (item.suffix or "")
    end
    local function fromInput(input)
        local w = track.AbsoluteSize.X
        if w <= 0 then return end
        local a = math.clamp((input.Position.X - track.AbsolutePosition.X) / w, 0, 1)
        setPref(item.key, math.clamp(math.floor(item.min + a * (item.max - item.min) + 0.5), item.min, item.max))
        render()
    end
    holder.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            activeSlider = fromInput
            fromInput(input)
        end
    end)
    render()
    register(row, item)
end

local function rowNote(body, item)
    local row = label(body, {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = item.text,
        Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = P.sub, TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top,
    })
    register(row, {label = item.text})
end

local function rowInfo(body, item)
    local row = newRow(body, 20)
    label(row, {Size = UDim2.new(0.6, 0, 1, 0), Text = item.label, TextSize = 12})
    local value = label(row, {
        Size = UDim2.new(0.4, 0, 1, 0), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0),
        Text = item.get(), TextColor3 = P.red, TextXAlignment = Enum.TextXAlignment.Right,
    })
    table.insert(infoRows, {label = value, get = item.get})
    register(row, item)
end

local builders = {
    toggle = rowToggle, check = rowCheck, dropdown = rowDropdown,
    slider = rowSlider, note = rowNote, info = rowInfo,
}

local function makeCard(parent, spec)
    local card = new("Frame", {
        Size = UDim2.new(0.5, -5, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = P.card, BorderSizePixel = 0,
    }, parent)
    corner(card, 8)
    outline(card, 1.5)
    new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}, card)

    local head = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = P.cardHead, Text = "",
        AutoButtonColor = false, LayoutOrder = 1,
    }, card)
    corner(head, 8)
    local icon = new("Frame", {
        Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(8, 7),
        BackgroundColor3 = spec.icon or P.red, BorderSizePixel = 0,
    }, head)
    corner(icon, 8)
    outline(icon, 1.2)
    label(head, {Size = UDim2.new(1, -60, 1, 0), Position = UDim2.fromOffset(30, 0), Text = spec.title, TextSize = 13})
    local chevron = label(head, {Size = UDim2.fromOffset(20, 30), Position = UDim2.new(1, -24, 0, 0),
        Text = "v", TextColor3 = P.sub, TextXAlignment = Enum.TextXAlignment.Center})

    local body = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, LayoutOrder = 2,
    }, card)
    new("UIListLayout", {Padding = UDim.new(0, 9), SortOrder = Enum.SortOrder.LayoutOrder}, body)
    new("UIPadding", {PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}, body)

    head.MouseButton1Click:Connect(function()
        body.Visible = not body.Visible
        chevron.Text = body.Visible and "v" or ">"
    end)

    currentCard = card
    for _, item in ipairs(spec.rows) do builders[item.type](body, item) end
    return card
end

---------------------------------------------------------------------------
-- Pages
---------------------------------------------------------------------------
local AIM_PARTS = {Head = {"Head"}, Torso = {"UpperTorso", "Torso"}, Root = {"HumanoidRootPart"}}
local ESP_COLORS = {
    Cyan = Color3.fromRGB(0, 190, 220), Red = Color3.fromRGB(255, 70, 70),
    Green = Color3.fromRGB(70, 230, 110), Yellow = Color3.fromRGB(255, 220, 60),
    White = Color3.fromRGB(245, 245, 245), Magenta = Color3.fromRGB(255, 80, 220),
}
local NOT_WIRED = {type = "note", text = "Not connected to game logic yet. These options are saved but do nothing."}
local PRIORITIES = {"Crosshair", "Distance", "Health"}

local pages = {
    ["Main"] = {
        title = "MAIN", sub = "Overview and interface",
        left = {{title = "Overview", icon = P.red, rows = {
            {type = "info", label = "Targets found", get = function() return tostring(targetCount) end},
            {type = "dropdown", key = "tgt.source", label = "Target source",
                desc = "Tagged = models carrying the AFG_NPC tag. All humanoids = every non-player model with a Humanoid.",
                options = {"Tagged", "All humanoids"}, value = "Tagged"},
            {type = "note", text = "Only NPC models are targeted. Player characters are always skipped, so Targets stays at 0 in a match against other players."},
        }}},
        right = {{title = "Interface", icon = P.yellow, rows = {
            {type = "check", key = "ui.hud", label = "Show HUD", desc = "FPS, ping, time and targets", value = true},
            {type = "check", key = "ui.anim", label = "Interface animation", value = true},
            {type = "note", text = "RightShift hides or shows the panel."},
        }}},
    },
    ["Aimbot"] = {
        title = "AIMBOT", sub = "Locks your camera onto targets",
        left = {{title = "Aimbot", icon = P.red, rows = {
            {type = "toggle", key = "aim.enabled", label = "Aimbot", desc = "Locks your view onto the target in the FOV",
                bindKey = "aim.bind", bindValue = "MouseButton2", value = false},
            {type = "dropdown", key = "aim.mode", label = "Key mode", options = {"Hold", "Toggle"}, value = "Hold"},
            {type = "slider", key = "aim.smooth", label = "Smoothness", desc = "1 = instant snap", min = 1, max = 20, value = 5},
            {type = "check", key = "aim.sticky", label = "Sticky target", desc = "Keeps the same target until it is lost", value = false},
        }}},
        right = {{title = "Aimbot Targeting", icon = P.blue, rows = {
            {type = "dropdown", key = "aim.part", label = "Aim part", options = {"Head", "Torso", "Root"}, value = "Head"},
            {type = "dropdown", key = "aim.priority", label = "Priority", options = PRIORITIES, value = "Crosshair"},
            {type = "check", key = "aim.visible", label = "Visible only", value = false},
            {type = "slider", key = "aim.fov", label = "FOV", min = 10, max = 500, value = 150, suffix = "px"},
            {type = "toggle", key = "aim.circle", label = "Show FOV circle", value = false},
            {type = "slider", key = "aim.dist", label = "Max distance", min = 50, max = 5000, value = 1500, suffix = " st"},
            {type = "slider", key = "aim.lead", label = "Prediction", desc = "0 = off", min = 0, max = 100, value = 0, suffix = "%"},
        }}},
    },
    ["Silent Aim"] = {
        title = "SILENT AIM", sub = "Your shots find the target for you",
        left = {{title = "Silent Aim", icon = P.ink, rows = {
            {type = "toggle", key = "sil.enabled", label = "Silent aim", desc = "Shots you fire go to the target in the FOV",
                bindKey = "sil.bind", bindValue = "None", value = false},
            {type = "dropdown", key = "sil.method", label = "Method",
                desc = "Shot redirect briefly points the camera at the target on each click. API only exposes shared.AFG_SilentAim() for your own fire code.",
                options = {"Shot redirect", "API only"}, value = "Shot redirect"},
            {type = "slider", key = "sil.hit", label = "Hit chance", desc = "Lower looks more legit", min = 0, max = 100, value = 95, suffix = "%"},
            {type = "slider", key = "sil.head", label = "Headshot chance", desc = "The rest go to the body", min = 0, max = 100, value = 100, suffix = "%"},
        }}},
        right = {{title = "Silent Targeting", icon = P.blue, rows = {
            {type = "dropdown", key = "sil.priority", label = "Priority", options = PRIORITIES, value = "Crosshair"},
            {type = "check", key = "sil.visible", label = "Visible only", desc = "Off = also through walls", value = false},
            {type = "slider", key = "sil.fov", label = "FOV", min = 10, max = 500, value = 220, suffix = "px"},
            {type = "toggle", key = "sil.circle", label = "Show FOV circle", value = false},
            {type = "slider", key = "sil.dist", label = "Max distance", min = 50, max = 5000, value = 2000, suffix = " st"},
            {type = "check", key = "sil.lead", label = "Lead moving targets", value = false},
        }}},
    },
    ["Trigger & Rage"] = {
        title = "TRIGGER & RAGE", sub = "Automatic firing options",
        left = {{title = "Trigger", icon = P.yellow, rows = {
            NOT_WIRED,
            {type = "dropdown", key = "trg.mode", label = "Key mode", options = {"Hold", "Toggle"}, value = "Hold"},
            {type = "slider", key = "trg.delay", label = "Reaction delay", min = 0, max = 1000, value = 100, suffix = " ms"},
            {type = "slider", key = "trg.chance", label = "Fire chance", min = 0, max = 100, value = 100, suffix = "%"},
        }}},
        right = {},
    },
    ["Gun Mods"] = {
        title = "GUN MODS", sub = "Weapon tweaks",
        left = {{title = "Weapon", icon = P.ink, rows = {
            NOT_WIRED,
            {type = "check", key = "gun.recoil", label = "No recoil", value = false},
            {type = "check", key = "gun.spread", label = "No spread", value = false},
        }}},
        right = {},
    },
    ["Visuals"] = {
        title = "VISUALS", sub = "Draw information over targets",
        left = {{title = "ESP", icon = P.green, rows = {
            {type = "toggle", key = "esp.box", label = "Box", value = false},
            {type = "toggle", key = "esp.skel", label = "Skeleton", value = false},
            {type = "toggle", key = "esp.line", label = "Tracer line", value = false},
            {type = "toggle", key = "esp.name", label = "Name", value = false},
            {type = "toggle", key = "esp.dist", label = "Distance", value = false},
            {type = "toggle", key = "esp.health", label = "Health bar", value = false},
        }}},
        right = {{title = "ESP Style", icon = P.blue, rows = {
            {type = "dropdown", key = "esp.color", label = "Color",
                options = {"Cyan", "Red", "Green", "Yellow", "White", "Magenta"}, value = "Cyan"},
            {type = "slider", key = "esp.maxdist", label = "Max distance", min = 100, max = 5000, value = 1000, suffix = " st"},
            {type = "slider", key = "esp.thick", label = "Thickness", min = 1, max = 5, value = 2, suffix = "px"},
            {type = "slider", key = "esp.text", label = "Text size", min = 10, max = 24, value = 14},
        }}},
    },
    ["World"] = {
        title = "WORLD", sub = "Environment options",
        left = {{title = "World", icon = P.green, rows = {
            NOT_WIRED,
            {type = "check", key = "world.flash", label = "No flashbang", value = false},
            {type = "check", key = "world.smoke", label = "No smoke", value = false},
        }}},
        right = {},
    },
    ["Skins"] = {
        title = "SKINS", sub = "Character appearance",
        left = {{title = "Skins", icon = P.yellow, rows = {
            NOT_WIRED,
            {type = "dropdown", key = "skin.config", label = "Skin config", options = {"Default", "Custom"}, value = "Default"},
        }}},
        right = {},
    },
    ["Gun Skins"] = {
        title = "GUN SKINS", sub = "Weapon appearance",
        left = {{title = "Gun skins", icon = P.red, rows = {
            NOT_WIRED,
            {type = "dropdown", key = "gunskin.config", label = "Weapon skin", options = {"Default", "Custom"}, value = "Default"},
        }}},
        right = {},
    },
}

local navLayout = {
    {section = "MAIN", items = {"Main"}},
    {section = "COMBAT", items = {"Aimbot", "Silent Aim", "Trigger & Rage", "Gun Mods"}},
    {section = "VISUALS", items = {"Visuals", "World", "Skins", "Gun Skins"}},
}
local navIcons = {
    ["Main"] = P.red, ["Aimbot"] = P.red, ["Silent Aim"] = P.ink, ["Trigger & Rage"] = P.yellow,
    ["Gun Mods"] = P.blue, ["Visuals"] = P.card, ["World"] = P.green, ["Skins"] = P.yellow, ["Gun Skins"] = P.red,
}

-- defaults must exist before any row is built or any step reads them
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

---------------------------------------------------------------------------
-- Navigation + search
---------------------------------------------------------------------------
local navButtons = {}
local activeTab = nil

local function updateInfos()
    for i = #infoRows, 1, -1 do
        local r = infoRows[i]
        if r.label.Parent then r.label.Text = r.get() else table.remove(infoRows, i) end
    end
end

local function applySearch()
    local q = (SearchBox.Text:gsub("^%s+", ""):gsub("%s+$", "")):lower()
    for _, e in ipairs(registry) do
        e.row.Visible = q == "" or e.text:find(q, 1, true) ~= nil
    end
    for card, rows in pairs(cardRows) do
        if card.Parent then
            local any = q == ""
            for _, e in ipairs(rows) do if e.row.Visible then any = true break end end
            card.Visible = any
        end
    end
end
connect(SearchBox:GetPropertyChangedSignal("Text"), applySearch)

local function showPage(name)
    local page = pages[name]
    if not page then return end
    activeTab = name
    activeSlider = nil
    captureTarget = nil

    for _, c in ipairs(Scroll:GetChildren()) do
        if c:IsA("GuiObject") then c:Destroy() end
    end
    registry, cardRows, infoRows = {}, {}, {}

    PageTitle.Text = page.title
    PageSub.Text = page.sub

    local cols = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
    }, Scroll)
    new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10),
        VerticalAlignment = Enum.VerticalAlignment.Top, SortOrder = Enum.SortOrder.LayoutOrder,
    }, cols)

    for order, side in ipairs({"left", "right"}) do
        local col = new("Frame", {
            Size = UDim2.new(0.5, -5, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1, LayoutOrder = order,
        }, cols)
        new("UIListLayout", {Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder}, col)
        for _, spec in ipairs(page[side]) do
            local card = makeCard(col, spec)
            card.Size = UDim2.new(1, 0, 0, 0)
        end
    end

    for tabName, t in pairs(navButtons) do
        local sel = tabName == name
        t.btn.BackgroundTransparency = sel and 0 or 1
        t.btn.TextColor3 = sel and P.red or P.white
    end
    Scroll.CanvasPosition = Vector2.new(0, 0)
    applySearch()
    updateInfos()
end

do
    local order = 0
    for _, group in ipairs(navLayout) do
        order += 1
        label(NavList, {
            Size = UDim2.new(1, 0, 0, 18), Text = group.section, TextSize = 9,
            TextColor3 = P.sideText, LayoutOrder = order,
        })
        for _, name in ipairs(group.items) do
            order += 1
            local btn = new("TextButton", {
                Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = P.card, BackgroundTransparency = 1,
                Text = "      " .. name, TextColor3 = P.white, Font = Enum.Font.GothamBold, TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false, LayoutOrder = order,
            }, NavList)
            corner(btn, 8)
            local icon = new("Frame", {
                Size = UDim2.fromOffset(14, 14), Position = UDim2.fromOffset(7, 7),
                BackgroundColor3 = navIcons[name] or P.red, BorderSizePixel = 0,
            }, btn)
            corner(icon, 7)
            outline(icon, 1.2)
            navButtons[name] = {btn = btn}
            btn.MouseButton1Click:Connect(function() showPage(name) end)
        end
    end
end

---------------------------------------------------------------------------
-- Pure helpers (checkable without the game)
---------------------------------------------------------------------------
local function finiteVec(v)
    local lim = 1e6
    return v.X == v.X and v.Y == v.Y and v.Z == v.Z
        and math.abs(v.X) < lim and math.abs(v.Y) < lim and math.abs(v.Z) < lim
end

local function smoothAlpha(smoothness, dt) -- frame-rate independent; 1 = instant
    local base = 1 / math.max(smoothness, 1)
    return 1 - (1 - base) ^ (math.clamp(dt, 0, 0.1) * 60)
end

local function leadPoint(pos, velocity, seconds)
    local p = pos + velocity * seconds
    if finiteVec(p) then return p end
    return pos
end

local function rotationBetween(a, b) -- rotation about the origin taking unit a onto unit b
    local axis = a:Cross(b)
    if axis.Magnitude < 1e-6 then return CFrame.new() end
    return CFrame.fromAxisAngle(axis.Unit, math.acos(math.clamp(a:Dot(b), -1, 1)))
end

---------------------------------------------------------------------------
-- Targets (NPC models only)
---------------------------------------------------------------------------
local taggedModels, humanoidModels = {}, {}
local scanned = false

local function addTagged(inst)
    if inst:IsA("Model") then taggedModels[inst] = true end
end
connect(CollectionService:GetInstanceAddedSignal(Config.NpcTag), addTagged)
connect(CollectionService:GetInstanceRemovedSignal(Config.NpcTag), function(inst) taggedModels[inst] = nil end)
for _, inst in ipairs(CollectionService:GetTagged(Config.NpcTag)) do addTagged(inst) end

local function addHumanoid(inst)
    if inst:IsA("Humanoid") then
        local m = inst.Parent
        if m and m:IsA("Model") then humanoidModels[m] = true end
    end
end
local function ensureScan()
    if scanned then return end
    scanned = true
    for _, inst in ipairs(Workspace:GetDescendants()) do addHumanoid(inst) end
    connect(Workspace.DescendantAdded, addHumanoid)
    connect(Workspace.DescendantRemoving, function(inst)
        if inst:IsA("Humanoid") and inst.Parent then humanoidModels[inst.Parent] = nil end
    end)
end
local function targetSet()
    if pref("tgt.source", "Tagged") == "All humanoids" then
        ensureScan()
        return humanoidModels
    end
    return taggedModels
end

local function readNpc(model)
    if not model.Parent then return nil end
    if Players:GetPlayerFromCharacter(model) then return nil end -- NPCs only
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return nil end
    local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
    if not root or not root:IsA("BasePart") then return nil end
    if not finiteVec(root.Position) then return nil end
    return {Model = model, Humanoid = hum, Root = root}
end

local function resolvePart(npc, names)
    for _, n in ipairs(names) do
        local p = npc.Model:FindFirstChild(n)
        if p and p:IsA("BasePart") then return p end
    end
    return npc.Root
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
local function isVisible(camPos, part, model)
    local ignore = {model}
    if Player.Character then table.insert(ignore, Player.Character) end
    rayParams.FilterDescendantsInstances = ignore
    return Workspace:Raycast(camPos, part.Position - camPos, rayParams) == nil
end

local function evaluate(cam, camPos, mouse, model, o)
    local npc = readNpc(model)
    if not npc then return nil end
    local part = resolvePart(npc, o.names)
    local pos = part.Position
    if not finiteVec(pos) then return nil end
    local dist = (pos - camPos).Magnitude
    if dist > o.maxDist then return nil end
    local sp = cam:WorldToViewportPoint(pos)
    if sp.Z <= 0 then return nil end
    local px = (Vector2.new(sp.X, sp.Y) - mouse).Magnitude
    if px > o.fov then return nil end
    if o.visible and not isVisible(camPos, part, model) then return nil end
    local score = px
    if o.priority == "Distance" then score = dist
    elseif o.priority == "Health" then score = npc.Humanoid.Health end
    return {Part = part, Model = model, Position = pos, Score = score}
end

local function pickTarget(cam, o, sticky)
    local camPos = cam.CFrame.Position
    local mouse = UserInputService:GetMouseLocation()
    if sticky then
        local c = evaluate(cam, camPos, mouse, sticky, o)
        if c then return c end
    end
    local best
    for model in pairs(targetSet()) do
        local c = evaluate(cam, camPos, mouse, model, o)
        if c and (best == nil or c.Score < best.Score) then best = c end
    end
    return best
end

---------------------------------------------------------------------------
-- Input gate (Hold / Toggle)
---------------------------------------------------------------------------
local windowFocused = true
local KeyState = {}
connect(UserInputService.WindowFocused, function() windowFocused = true end)
connect(UserInputService.WindowFocusReleased, function()
    windowFocused = false
    for _, s in pairs(KeyState) do s.down = false; s.on = false end
end)

local function keyActive(id, bindName, modeName)
    local s = KeyState[id]
    if not s then s = {down = false, on = false}; KeyState[id] = s end
    local bind = parseBind(bindName)
    if not bind or not windowFocused or UserInputService:GetFocusedTextBox() then
        s.down = false; s.on = false
        return false
    end
    local down
    if bind.mouse then down = UserInputService:IsMouseButtonPressed(bind.mouse)
    else down = UserInputService:IsKeyDown(bind.key) end
    local result
    if modeName == "Toggle" then
        if down and not s.down then s.on = not s.on end
        result = s.on
    else
        s.on = false
        result = down
    end
    s.down = down
    return result
end

local function gate(id, bindName, modeName)
    if bindName == nil or bindName == "None" then
        return windowFocused and not UserInputService:GetFocusedTextBox()
    end
    return keyActive(id, bindName, modeName)
end

---------------------------------------------------------------------------
-- Aimbot
---------------------------------------------------------------------------
local aimSticky = nil

local function aimbotStep(dt)
    if not pref("aim.enabled", false) then aimSticky = nil; return end
    if not gate("aim", pref("aim.bind", "MouseButton2"), pref("aim.mode", "Hold")) then
        aimSticky = nil
        return
    end
    local cam = Workspace.CurrentCamera
    if not cam then return end

    local names = {}
    for _, n in ipairs(AIM_PARTS[pref("aim.part", "Head")] or AIM_PARTS.Head) do table.insert(names, n) end
    table.insert(names, "Head")

    local target = pickTarget(cam, {
        names = names, fov = prefNumber("aim.fov", 150), maxDist = prefNumber("aim.dist", 1500),
        visible = pref("aim.visible", false) == true, priority = pref("aim.priority", "Crosshair"),
    }, pref("aim.sticky", false) and aimSticky or nil)

    if not target then aimSticky = nil; return end
    aimSticky = target.Model

    local lead = prefNumber("aim.lead", 0) / 100 * Config.MaxLeadSeconds
    local aimPos = leadPoint(target.Position, target.Part.AssemblyLinearVelocity, lead)
    local camPos = cam.CFrame.Position
    if (aimPos - camPos).Magnitude < 1e-3 then return end
    cam.CFrame = cam.CFrame:Lerp(CFrame.lookAt(camPos, aimPos), smoothAlpha(prefNumber("aim.smooth", 5), dt))
end

---------------------------------------------------------------------------
-- Silent Aim
---------------------------------------------------------------------------
local function silentAim()
    if not pref("sil.enabled", false) then return nil end
    local cam = Workspace.CurrentCamera
    if not cam then return nil end
    if math.random() * 100 >= prefNumber("sil.hit", 95) then return nil end
    local headshot = math.random() * 100 < prefNumber("sil.head", 100)
    local target = pickTarget(cam, {
        names = headshot and {"Head"} or {"UpperTorso", "Torso"},
        fov = prefNumber("sil.fov", 220), maxDist = prefNumber("sil.dist", 2000),
        visible = pref("sil.visible", false) == true, priority = pref("sil.priority", "Crosshair"),
    }, nil)
    if not target then return nil end
    local pos = target.Position
    if pref("sil.lead", false) then
        pos = leadPoint(pos, target.Part.AssemblyLinearVelocity, Config.MaxLeadSeconds * 0.5)
    end
    return {Position = pos, Part = target.Part, Model = target.Model, Headshot = headshot}
end
shared.AFG_SilentAim = silentAim

-- Shot redirect: rotate the camera so the ray through the cursor hits the target for this click,
-- restored at the start of the next frame.
local pendingRestore = nil
connect(UserInputService.InputBegan, function(input, processed)
    if processed or captureTarget then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    if not pref("sil.enabled", false) or pref("sil.method", "Shot redirect") ~= "Shot redirect" then return end
    if not gate("sil", pref("sil.bind", "None"), "Hold") then return end

    local cam = Workspace.CurrentCamera
    if not cam then return end
    local hit = silentAim()
    if not hit then return end

    local camPos = cam.CFrame.Position
    local toTarget = hit.Position - camPos
    if toTarget.Magnitude < 1e-3 then return end

    local mouse = UserInputService:GetMouseLocation()
    local ray = cam:ViewportPointToRay(mouse.X, mouse.Y)
    local rot = rotationBetween(ray.Direction.Unit, toTarget.Unit)
    local originalCF = cam.CFrame
    pendingRestore = originalCF
    cam.CFrame = CFrame.new(camPos) * rot * (originalCF - camPos)
end)

---------------------------------------------------------------------------
-- ESP
---------------------------------------------------------------------------
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
local entries = {}

local function newLine()
    return new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, Visible = false}, Overlay)
end
local function placeLine(f, a, b, thickness, color)
    local delta = b - a
    local len = delta.Magnitude
    if len ~= len or len < 0.5 or len > Config.MaxBoxPixels then f.Visible = false; return end
    f.Size = UDim2.fromOffset(len, thickness)
    f.Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2)
    f.Rotation = math.deg(math.atan2(delta.Y, delta.X))
    f.BackgroundColor3 = color
    f.Visible = true
end

local function createEntry()
    local e = {Bones = {}}
    e.Box = new("Frame", {BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false}, Overlay)
    e.Stroke = new("UIStroke", {}, e.Box)
    e.Label = new("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.fromOffset(240, 20), AnchorPoint = Vector2.new(0.5, 1),
        Font = Enum.Font.GothamMedium, TextStrokeTransparency = 0.4, Visible = false,
    }, Overlay)
    e.HealthBack = new("Frame", {
        BackgroundColor3 = Color3.fromRGB(15, 20, 28), BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0), Visible = false,
    }, Overlay)
    e.HealthFill = new("Frame", {
        BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0),
    }, e.HealthBack)
    e.Tracer = newLine()
    return e
end
local function hideEntry(e)
    e.Box.Visible = false; e.Label.Visible = false; e.HealthBack.Visible = false; e.Tracer.Visible = false
    for _, b in ipairs(e.Bones) do b.Visible = false end
end
local function destroyEntry(e)
    e.Box:Destroy(); e.Label:Destroy(); e.HealthBack:Destroy(); e.Tracer:Destroy()
    for _, b in ipairs(e.Bones) do b:Destroy() end
end

local function projectBox(cam, cf, size)
    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    local any = false
    for ix = -1, 1, 2 do
        for iy = -1, 1, 2 do
            for iz = -1, 1, 2 do
                local c3 = cf:PointToWorldSpace(Vector3.new(ix * size.X / 2, iy * size.Y / 2, iz * size.Z / 2))
                local sp = cam:WorldToViewportPoint(c3)
                if sp.Z > 0 then
                    any = true
                    minX = math.min(minX, sp.X); maxX = math.max(maxX, sp.X)
                    minY = math.min(minY, sp.Y); maxY = math.max(maxY, sp.Y)
                end
            end
        end
    end
    if not any then return nil end
    if (maxX - minX) > Config.MaxBoxPixels or (maxY - minY) > Config.MaxBoxPixels then return nil end
    return Vector2.new(minX, minY), Vector2.new(maxX, maxY)
end

local function updateEntry(e, cam, npc, dist, o)
    local cf, size = npc.Model:GetBoundingBox()
    local tl, br = projectBox(cam, cf, size)
    if not tl then hideEntry(e); return end
    local w, h = br.X - tl.X, br.Y - tl.Y

    if o.box then
        e.Box.Position = UDim2.fromOffset(tl.X, tl.Y)
        e.Box.Size = UDim2.fromOffset(w, h)
        e.Stroke.Color = o.color
        e.Stroke.Thickness = o.thick
        e.Box.Visible = true
    else
        e.Box.Visible = false
    end

    local parts = {}
    if o.name then table.insert(parts, npc.Model.Name) end
    if o.distance then table.insert(parts, string.format("[%d st]", dist)) end
    if #parts > 0 then
        e.Label.Text = table.concat(parts, " ")
        e.Label.TextSize = o.textSize
        e.Label.TextColor3 = o.color
        e.Label.Position = UDim2.fromOffset((tl.X + br.X) / 2, tl.Y - 2)
        e.Label.Visible = true
    else
        e.Label.Visible = false
    end

    if o.health and npc.Humanoid.MaxHealth > 0 then
        local frac = math.clamp(npc.Humanoid.Health / npc.Humanoid.MaxHealth, 0, 1)
        e.HealthBack.Position = UDim2.fromOffset(tl.X - 4, tl.Y)
        e.HealthBack.Size = UDim2.fromOffset(o.thick + 1, h)
        e.HealthFill.Size = UDim2.new(1, 0, frac, 0)
        e.HealthFill.BackgroundColor3 = Color3.fromRGB(255, 0, 0):Lerp(Color3.fromRGB(0, 255, 0), frac)
        e.HealthBack.Visible = true
    else
        e.HealthBack.Visible = false
    end

    if o.tracer then
        placeLine(e.Tracer, Vector2.new(o.viewport.X / 2, o.viewport.Y),
            Vector2.new((tl.X + br.X) / 2, br.Y), o.thick, o.color)
    else
        e.Tracer.Visible = false
    end

    local bones = npc.Humanoid.RigType == Enum.HumanoidRigType.R15 and BONES_R15 or BONES_R6
    for i, pair in ipairs(bones) do
        local line = e.Bones[i]
        if not line then line = newLine(); e.Bones[i] = line end
        local drawn = false
        if o.skeleton then
            local a = npc.Model:FindFirstChild(pair[1])
            local b = npc.Model:FindFirstChild(pair[2])
            if a and b and a:IsA("BasePart") and b:IsA("BasePart") then
                local sa = cam:WorldToViewportPoint(a.Position)
                local sb = cam:WorldToViewportPoint(b.Position)
                if sa.Z > 0 and sb.Z > 0 then
                    placeLine(line, Vector2.new(sa.X, sa.Y), Vector2.new(sb.X, sb.Y), o.thick, o.color)
                    drawn = true
                end
            end
        end
        if not drawn then line.Visible = false end
    end
end

local function espStep()
    local cam = Workspace.CurrentCamera
    local o = {
        box = pref("esp.box", false) == true,
        skeleton = pref("esp.skel", false) == true,
        tracer = pref("esp.line", false) == true,
        name = pref("esp.name", false) == true,
        distance = pref("esp.dist", false) == true,
        health = pref("esp.health", false) == true,
        thick = math.clamp(prefNumber("esp.thick", 2), 1, 5),
        textSize = math.clamp(math.floor(prefNumber("esp.text", 14)), 10, 24),
        color = ESP_COLORS[pref("esp.color", "Cyan")] or ESP_COLORS.Cyan,
    }
    local anyOn = o.box or o.skeleton or o.tracer or o.name or o.distance or o.health
    local set = targetSet()

    local seen = {}
    if cam and anyOn then
        o.viewport = cam.ViewportSize
        local camPos = cam.CFrame.Position
        local maxDist = prefNumber("esp.maxdist", 1000)
        for model in pairs(set) do
            local npc = readNpc(model)
            if npc then
                local dist = (npc.Root.Position - camPos).Magnitude
                if dist <= maxDist and cam:WorldToViewportPoint(npc.Root.Position).Z > 0 then
                    seen[model] = true
                    local e = entries[model]
                    if not e then e = createEntry(); entries[model] = e end
                    updateEntry(e, cam, npc, dist, o)
                end
            end
        end
    end
    for model, e in pairs(entries) do
        if not set[model] or not model.Parent then
            destroyEntry(e); entries[model] = nil
        elseif not seen[model] then
            hideEntry(e)
        end
    end
end

---------------------------------------------------------------------------
-- FOV circles + HUD chip
---------------------------------------------------------------------------
local function makeCircle(color)
    local f = new("Frame", {
        BackgroundTransparency = 1, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Visible = false,
    }, Overlay)
    corner(f, 9999)
    new("UIStroke", {Color = color, Thickness = 1.2}, f)
    return f
end
local aimCircle = makeCircle(P.red)
local silentCircle = makeCircle(P.yellow)

local function circleStep()
    local mouse = UserInputService:GetMouseLocation()
    local function apply(circle, show, radius)
        if show and radius > 0 then
            circle.Size = UDim2.fromOffset(radius * 2, radius * 2)
            circle.Position = UDim2.fromOffset(mouse.X, mouse.Y)
            circle.Visible = true
        else
            circle.Visible = false
        end
    end
    apply(aimCircle, pref("aim.enabled", false) and pref("aim.circle", false), prefNumber("aim.fov", 150))
    apply(silentCircle, pref("sil.enabled", false) and pref("sil.circle", false), prefNumber("sil.fov", 220))
end

local Hud = new("Frame", {
    AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 6),
    Size = UDim2.fromOffset(0, 24), AutomaticSize = Enum.AutomaticSize.X,
    BackgroundColor3 = Color3.fromRGB(86, 104, 150), BorderSizePixel = 0,
}, GUI)
corner(Hud, 12)
outline(Hud, 1.5)
new("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12)}, Hud)
local HudText = label(Hud, {
    Size = UDim2.fromOffset(0, 24), AutomaticSize = Enum.AutomaticSize.X, Text = "",
    TextColor3 = P.white, TextSize = 11,
})

local function readPing()
    local ok, v = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
    if ok and typeof(v) == "number" then return math.floor(v + 0.5) end
    return nil
end

local statusTimer = 0
local function statusStep(dt)
    statusTimer += dt
    if statusTimer < 0.5 then return end
    statusTimer = 0
    local n = 0
    for model in pairs(targetSet()) do
        if readNpc(model) then n += 1 end
    end
    targetCount = n
    updateInfos()

    Hud.Visible = pref("ui.hud", true) == true
    if Hud.Visible then
        local t = math.floor(os.clock() - startClock)
        local ping = readPing()
        HudText.Text = string.format("AIRFIREGUNS   FPS %d   PING %s   TIME %02d:%02d   TARGETS %d",
            math.floor(fps + 0.5), ping and (ping .. "ms") or "-", math.floor(t / 60), t % 60, n)
    end
end

---------------------------------------------------------------------------
-- Menu key, cleanup, loop
---------------------------------------------------------------------------
connect(UserInputService.InputBegan, function(input, processed)
    if processed then return end
    if input.KeyCode == Config.MenuKey then GUI.Enabled = not GUI.Enabled end
end)

local cleaned = false
local function cleanup()
    if cleaned then return end
    cleaned = true
    pcall(function() RunService:UnbindFromRenderStep(Config.MainStepName) end)
    pcall(function() RunService:UnbindFromRenderStep(Config.RestoreStepName) end)
    for _, c in ipairs(connections) do c:Disconnect() end
    for model, e in pairs(entries) do destroyEntry(e); entries[model] = nil end
    if shared.AFG_SilentAim == silentAim then shared.AFG_SilentAim = nil end
    if shared.AFG_Cleanup == cleanup then shared.AFG_Cleanup = nil end
    Overlay:Destroy()
    if GUI.Parent then GUI:Destroy() end
end
shared.AFG_Cleanup = cleanup
connect(GUI.Destroying, cleanup)

local reported = {}
local function guarded(tag, fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok and not reported[tag] then
        reported[tag] = true
        warn("[AirFireGuns] " .. tag .. " error: " .. tostring(err))
    end
end

RunService:BindToRenderStep(Config.RestoreStepName, Enum.RenderPriority.First.Value, function()
    if pendingRestore then
        local cam = Workspace.CurrentCamera
        if cam then cam.CFrame = pendingRestore end
        pendingRestore = nil
    end
end)

RunService:BindToRenderStep(Config.MainStepName, Enum.RenderPriority.Camera.Value + 1, function(dt)
    if not GUI.Parent then cleanup(); return end
    fps = fps * 0.9 + (1 / math.max(dt, 1e-4)) * 0.1
    guarded("aimbot", aimbotStep, dt)
    guarded("esp", espStep)
    guarded("circles", circleStep)
    guarded("status", statusStep, dt)
end)

showPage("Aimbot")
print("[AirFireGuns] V5 carregado. RightShift esconde/mostra o painel.")
