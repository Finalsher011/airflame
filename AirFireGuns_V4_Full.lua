-- AIRFIREGUNS | V3
-- Painel unificado + sliders + configurações locais.
-- ESP destinado a NPCs do próprio jogo, identificados pela tag AFG_NPC.
-- (Inclui o addon Aimbot / Silent Aim / NPC ESP no final do arquivo.)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local old = PlayerGui:FindFirstChild("AirFireGuns")
if old then old:Destroy() end

local GUI = Instance.new("ScreenGui")
GUI.Name = "AirFireGuns"
GUI.ResetOnSpawn = false
GUI.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(680, 450)
Main.Position = UDim2.new(0.5, -340, 0.5, -225)
Main.BackgroundColor3 = Color3.fromRGB(13, 16, 23)
Main.BorderSizePixel = 0
Main.Parent = GUI
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke", Main)
stroke.Color = Color3.fromRGB(0, 190, 220)
stroke.Thickness = 1.3

local accent = Color3.fromRGB(0, 190, 220)
local preferences = {}
local callbacks = {}
local pages = {}
local tabs = {}
local minimized = false
local activeTab

local Top = Instance.new("Frame")
Top.Size = UDim2.new(1, 0, 0, 48)
Top.BackgroundColor3 = Color3.fromRGB(19, 24, 33)
Top.BorderSizePixel = 0
Top.Parent = Main
Instance.new("UICorner", Top).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -110, 1, 0)
Title.Position = UDim2.fromOffset(16, 0)
Title.BackgroundTransparency = 1
Title.Text = "AIRFIREGUNS"
Title.TextColor3 = Color3.fromRGB(0, 210, 235)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 17
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Top

local function topButton(text, x, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(35, 30)
    b.Position = UDim2.new(1, x, 0, 9)
    b.BackgroundColor3 = Color3.fromRGB(35, 43, 55)
    b.Text = text
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 15
    b.Parent = Top
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    b.MouseButton1Click:Connect(callback)
end

topButton("—", -82, function()
    minimized = not minimized
    local target = minimized
        and UDim2.fromOffset(680, 48)
        or UDim2.fromOffset(680, 450)
    TweenService:Create(Main, TweenInfo.new(0.2), {
        Size = target
    }):Play()
end)

topButton("X", -42, function()
    GUI:Destroy()
end)

-- Arrastar painel
local dragging = false
local dragStart, startPosition

Top.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPosition = Main.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

local Sidebar = Instance.new("Frame")
Sidebar.Position = UDim2.fromOffset(10, 58)
Sidebar.Size = UDim2.fromOffset(155, 382)
Sidebar.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 8)

local SideList = Instance.new("UIListLayout", Sidebar)
SideList.Padding = UDim.new(0, 5)
SideList.SortOrder = Enum.SortOrder.LayoutOrder

local sidePadding = Instance.new("UIPadding", Sidebar)
sidePadding.PaddingTop = UDim.new(0, 8)
sidePadding.PaddingLeft = UDim.new(0, 7)
sidePadding.PaddingRight = UDim.new(0, 7)

local Content = Instance.new("ScrollingFrame")
Content.Position = UDim2.fromOffset(175, 58)
Content.Size = UDim2.fromOffset(495, 382)
Content.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 4
Content.ScrollBarImageColor3 = accent
Content.CanvasSize = UDim2.new()
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.Parent = Main
Instance.new("UICorner", Content).CornerRadius = UDim.new(0, 8)

local ContentList = Instance.new("UIListLayout", Content)
ContentList.Padding = UDim.new(0, 8)

local contentPadding = Instance.new("UIPadding", Content)
contentPadding.PaddingTop = UDim.new(0, 12)
contentPadding.PaddingLeft = UDim.new(0, 12)
contentPadding.PaddingRight = UDim.new(0, 12)
contentPadding.PaddingBottom = UDim.new(0, 12)

local function clearContent()
    for _, child in ipairs(Content:GetChildren()) do
        if child:IsA("GuiObject")
            and child ~= ContentList
            and child ~= contentPadding then
            child:Destroy()
        end
    end
end

local function addHeader(name)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -8, 0, 30)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = accent
    label.Font = Enum.Font.GothamBold
    label.TextSize = 17
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = Content
end

local function addToggle(name, initial)
    local enabled = initial == true

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -8, 0, 38)
    button.BackgroundColor3 = Color3.fromRGB(29, 35, 46)
    button.TextColor3 = Color3.fromRGB(220, 225, 235)
    button.Font = Enum.Font.Gotham
    button.TextSize = 13
    button.Parent = Content
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)

    local function refresh()
        button.Text = name .. (enabled
            and "                         ON"
            or "                         OFF")

        button.TextColor3 = enabled
            and Color3.fromRGB(0, 220, 235)
            or Color3.fromRGB(220, 225, 235)

        preferences[name] = enabled

        if callbacks[name] then
            callbacks[name](enabled)
        end
    end

    button.MouseButton1Click:Connect(function()
        enabled = not enabled
        refresh()
    end)

    refresh()
end

local function addSetting(name, default)
    local box = Instance.new("Frame")
    box.Size = UDim2.new(1, -8, 0, 48)
    box.BackgroundColor3 = Color3.fromRGB(29, 35, 46)
    box.Parent = Content
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.58, 0, 1, 0)
    label.Position = UDim2.fromOffset(10, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(225, 230, 240)
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = box

    local value = Instance.new("TextBox")
    value.Size = UDim2.fromOffset(155, 29)
    value.Position = UDim2.new(1, -165, 0.5, -14)
    value.BackgroundColor3 = Color3.fromRGB(15, 20, 28)
    value.TextColor3 = accent
    value.Text = tostring(preferences[name] or default)
    value.Font = Enum.Font.Gotham
    value.TextSize = 12
    value.ClearTextOnFocus = false
    value.Parent = box
    Instance.new("UICorner", value).CornerRadius = UDim.new(0, 5)

    value.FocusLost:Connect(function()
        preferences[name] = value.Text
        if callbacks[name] then
            callbacks[name](value.Text)
        end
    end)
end

local function addSlider(name, minValue, maxValue, defaultValue)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, -8, 0, 62)
    holder.BackgroundColor3 = Color3.fromRGB(29, 35, 46)
    holder.Parent = Content
    Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 6)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -25, 0, 24)
    label.Position = UDim2.fromOffset(10, 3)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(225, 230, 240)
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = holder

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -25, 0, 6)
    bar.Position = UDim2.fromOffset(12, 43)
    bar.BackgroundColor3 = Color3.fromRGB(15, 20, 28)
    bar.Parent = holder
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = accent
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.Parent = bar
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("TextButton")
    knob.Size = UDim2.fromOffset(14, 14)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.Text = ""
    knob.Parent = bar
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local current = math.clamp(
        preferences[name] or defaultValue,
        minValue,
        maxValue
    )
    local sliderDragging = false

    local function update(value)
        current = math.clamp(
            math.floor(value + 0.5),
            minValue,
            maxValue
        )

        local alpha = (current - minValue) / (maxValue - minValue)
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        knob.Position = UDim2.new(alpha, 0, 0.5, 0)
        label.Text = name .. ": " .. current
        preferences[name] = current

        if callbacks[name] then
            callbacks[name](current)
        end
    end

    local function updateFromInput(input)
        local alpha = math.clamp(
            (input.Position.X - bar.AbsolutePosition.X)
                / bar.AbsoluteSize.X,
            0,
            1
        )
        update(minValue + alpha * (maxValue - minValue))
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            sliderDragging = true
            updateFromInput(input)
        end
    end)

    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            sliderDragging = true
            updateFromInput(input)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if sliderDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateFromInput(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            sliderDragging = false
        end
    end)

    update(current)
end

local function showPage(name)
    local controls = pages[name]
    if not controls then return end

    activeTab = name
    clearContent()
    addHeader(name)

    for _, item in ipairs(controls) do
        if item.type == "toggle" then
            addToggle(item.name, preferences[item.name] or item.value)
        elseif item.type == "setting" then
            addSetting(item.name, item.value)
        elseif item.type == "slider" then
            addSlider(item.name, item.min, item.max, item.value)
        end
    end

    for tabName, tab in pairs(tabs) do
        tab.BackgroundColor3 = tabName == name
            and Color3.fromRGB(0, 105, 125)
            or Color3.fromRGB(29, 35, 46)
    end

    Content.CanvasPosition = Vector2.new(0, 0)
end

local function addPage(name, controls)
    pages[name] = controls

    local tab = Instance.new("TextButton")
    tab.Size = UDim2.new(1, 0, 0, 32)
    tab.BackgroundColor3 = Color3.fromRGB(29, 35, 46)
    tab.Text = name
    tab.TextColor3 = Color3.fromRGB(220, 225, 235)
    tab.Font = Enum.Font.GothamMedium
    tab.TextSize = 12
    tab.Parent = Sidebar
    Instance.new("UICorner", tab).CornerRadius = UDim.new(0, 5)

    tabs[name] = tab

    tab.MouseButton1Click:Connect(function()
        showPage(name)
    end)
end

-- PÁGINAS

addPage("Aimbot", {
    {type="setting", name="Key Mode", value="Hold"},
    {type="slider", name="Smoothness", min=1, max=20, value=5},
    {type="setting", name="Aim Part", value="Head"},
    {type="slider", name="FOV", min=10, max=500, value=100}
})

addPage("Silent Aim", {
    {type="slider", name="Hit Chance", min=0, max=100, value=100},
    {type="slider", name="Headshot Chance", min=0, max=100, value=50}
})

addPage("Trigger & Rage", {
    {type="setting", name="Key Mode", value="Hold"},
    {type="slider", name="Reaction Delay", min=0, max=1000, value=100},
    {type="slider", name="Fire Chance", min=0, max=100, value=100}
})

addPage("Gun Mods", {
    {type="toggle", name="No Recoil"},
    {type="toggle", name="No Spread"}
})

addPage("Visuais", {
    {type="toggle", name="Box ESP"},
    {type="toggle", name="Skeleton ESP"},
    {type="toggle", name="Line ESP"},
    {type="toggle", name="Name ESP"},
    {type="toggle", name="Distance"},
    {type="toggle", name="Health Bar"},
    {type="slider", name="Max Distance", min=100, max=5000, value=1000},
    {type="slider", name="Esp Thickness", min=1, max=5, value=2},
    {type="slider", name="Text Size", min=10, max=24, value=14}
})

addPage("World", {
    {type="toggle", name="No Flashbang"},
    {type="toggle", name="No Smoke"}
})

addPage("Skins", {
    {type="setting", name="Skin Config", value="Default"}
})

addPage("Gun Skins", {
    {type="setting", name="Weapon Skin", value="Default"}
})

addPage("Misc", {
    {type="toggle", name="Show FPS"},
    {type="toggle", name="Show Status"}
})

addPage("Settings", {
    {type="toggle", name="Interface Animation", value=true},
    {type="toggle", name="Save Preferences"},
    {type="setting", name="Theme", value="Cyan"}
})

-- Inicializa a primeira página
showPage("Aimbot")

print("[AirFireGuns] V3 carregado.")

-- ===================== AFG ADDON: Aimbot / Silent Aim / NPC ESP =====================

local Workspace = game:GetService("Workspace")

local Config = {
    NpcTag = "AFG_NPC",              -- source: your script header
    RenderStepName = "AFG_Addon",    -- my choice
    DefaultAimKey = "MouseButton2",  -- my choice
    MaxLeadSeconds = 0.25,           -- my choice, UNCALIBRATED (Prediction 100% = this lead)
    MaxBoxPixels = 20000,            -- sanity bound for projected boxes
}

-- Standard Roblox rig part names (R15 / R6). Custom rigs will show no skeleton.
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
-- Pure helpers (checkable without the game)
---------------------------------------------------------------------------
local function finiteVec(v)
    local lim = 1e6
    return v.X == v.X and v.Y == v.Y and v.Z == v.Z
        and math.abs(v.X) < lim and math.abs(v.Y) < lim and math.abs(v.Z) < lim
end

local function trim(s)
    return tostring(s):match("^%s*(.-)%s*$")
end

local function pref(name, default)
    local v = preferences[name]
    if v == nil then return default end
    return v
end

local function prefNumber(name, default)
    local v = tonumber(pref(name, default))
    if v == nil or v ~= v or v == math.huge or v == -math.huge then return default end
    return v
end

local function parseColor(text, fallback)
    if typeof(text) ~= "string" then return fallback end
    local r, g, b = text:match("^%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*$")
    if not r then return fallback end
    r, g, b = tonumber(r), tonumber(g), tonumber(b)
    if r > 255 or g > 255 or b > 255 then return fallback end
    return Color3.fromRGB(r, g, b)
end

-- "MouseButton2" -> {mouse=...}, "E" / "LeftShift" -> {key=...}, anything else -> nil
local function parseBind(text)
    local name = trim(text)
    if name == "MouseButton1" or name == "MouseButton2" or name == "MouseButton3" then
        return {mouse = Enum.UserInputType[name]}
    end
    local ok, kc = pcall(function() return Enum.KeyCode[name] end)
    if ok and kc then return {key = kc} end
    return nil
end

-- smoothness 1 = instant; frame-rate independent
local function smoothAlpha(smoothness, dt)
    local base = 1 / math.max(smoothness, 1)
    return 1 - (1 - base) ^ (math.clamp(dt, 0, 0.1) * 60)
end

local function leadPoint(pos, velocity, seconds)
    local p = pos + velocity * seconds
    if finiteVec(p) then return p end
    return pos
end

---------------------------------------------------------------------------
-- Cleanup bookkeeping
---------------------------------------------------------------------------
pcall(function() RunService:UnbindFromRenderStep(Config.RenderStepName) end)
local oldOverlay = PlayerGui:FindFirstChild("AirFireGunsOverlay")
if oldOverlay then oldOverlay:Destroy() end

local connections = {}
local entries = {}      -- [Model] = ESP entry
local cleaned = false
local windowFocused = true
local KeyState = {}

local Overlay = Instance.new("ScreenGui")
Overlay.Name = "AirFireGunsOverlay"
Overlay.ResetOnSpawn = false
Overlay.IgnoreGuiInset = true   -- so WorldToViewportPoint coordinates match 1:1
Overlay.DisplayOrder = -1       -- below the panel
Overlay.Parent = PlayerGui

---------------------------------------------------------------------------
-- NPC tracking (tag AFG_NPC, Model with Humanoid)
---------------------------------------------------------------------------
local tracked = {}
local function track(inst)
    if inst:IsA("Model") then tracked[inst] = true end
end
table.insert(connections, CollectionService:GetInstanceAddedSignal(Config.NpcTag):Connect(track))
table.insert(connections, CollectionService:GetInstanceRemovedSignal(Config.NpcTag):Connect(function(inst)
    tracked[inst] = nil
end))
for _, inst in ipairs(CollectionService:GetTagged(Config.NpcTag)) do track(inst) end

local function readNpc(model)
    if not model.Parent then return nil end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return nil end
    local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
    if not root or not root:IsA("BasePart") then return nil end
    if not finiteVec(root.Position) then return nil end
    return {Model = model, Humanoid = hum, Root = root}
end

local function resolvePart(npc, names)
    for _, n in ipairs(names) do
        if n ~= "" then
            local p = npc.Model:FindFirstChild(n)
            if p and p:IsA("BasePart") then return p end
        end
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

-- Closest-to-cursor target inside an FOV circle (pixels)
local function pickTarget(cam, fovPx, maxDist, names, needVisible)
    local camPos = cam.CFrame.Position
    local mouse = UserInputService:GetMouseLocation()
    local myChar = Player.Character
    local bestPart, bestModel, bestScore

    for model in pairs(tracked) do
        if model ~= myChar then
            local npc = readNpc(model)
            if npc then
                local part = resolvePart(npc, names)
                local pos = part.Position
                if finiteVec(pos) and (pos - camPos).Magnitude <= maxDist then
                    local sp = cam:WorldToViewportPoint(pos)
                    if sp.Z > 0 then
                        local d = (Vector2.new(sp.X, sp.Y) - mouse).Magnitude
                        if d <= fovPx and (bestScore == nil or d < bestScore) then
                            if not needVisible or isVisible(camPos, part, model) then
                                bestPart, bestModel, bestScore = part, model, d
                            end
                        end
                    end
                end
            end
        end
    end

    if not bestPart then return nil end
    return {Part = bestPart, Model = bestModel, Position = bestPart.Position}
end

---------------------------------------------------------------------------
-- Key handling (Hold / Toggle), released on focus loss or text box focus
---------------------------------------------------------------------------
table.insert(connections, UserInputService.WindowFocused:Connect(function() windowFocused = true end))
table.insert(connections, UserInputService.WindowFocusReleased:Connect(function()
    windowFocused = false
    for _, s in pairs(KeyState) do s.down = false; s.on = false end
end))

local function keyActive(id, bindText, modeText)
    local s = KeyState[id]
    if not s then s = {down = false, on = false}; KeyState[id] = s end
    local bind = parseBind(bindText)
    if not bind or not windowFocused or UserInputService:GetFocusedTextBox() then
        s.down = false; s.on = false
        return false
    end
    local down
    if bind.mouse then
        down = UserInputService:IsMouseButtonPressed(bind.mouse)
    else
        down = UserInputService:IsKeyDown(bind.key)
    end
    local result
    if trim(modeText):lower() == "toggle" then
        if down and not s.down then s.on = not s.on end
        result = s.on
    else
        s.on = false
        result = down
    end
    s.down = down
    return result
end

---------------------------------------------------------------------------
-- Aimbot (camera-based)
---------------------------------------------------------------------------
local function aimbotStep(dt)
    if not pref("Aimbot Enabled", false) then
        KeyState.aim = nil
        return
    end
    if not keyActive("aim", pref("Aim Key", Config.DefaultAimKey), pref("Key Mode", "Hold")) then return end

    local cam = Workspace.CurrentCamera
    if not cam then return end

    local partName = trim(pref("Aim Part", "Head"))
    local target = pickTarget(
        cam,
        prefNumber("FOV", 100),
        prefNumber("Target Distance", 1000),
        {partName, "Head"},
        pref("Visible Check", false) == true
    )
    if not target then return end

    local lead = prefNumber("Prediction", 0) / 100 * Config.MaxLeadSeconds
    local aimPos = leadPoint(target.Position, target.Part.AssemblyLinearVelocity, lead)

    local camPos = cam.CFrame.Position
    if (aimPos - camPos).Magnitude < 1e-3 then return end

    local desired = CFrame.lookAt(camPos, aimPos)
    cam.CFrame = cam.CFrame:Lerp(desired, smoothAlpha(prefNumber("Smoothness", 5), dt))
end

---------------------------------------------------------------------------
-- Silent Aim resolver: rolls Hit Chance and Headshot Chance per call (per shot)
---------------------------------------------------------------------------
local function silentAim()
    if not pref("Silent Aim Enabled", false) then return nil end
    local cam = Workspace.CurrentCamera
    if not cam then return nil end

    if math.random() * 100 >= prefNumber("Hit Chance", 100) then return nil end
    local headshot = math.random() * 100 < prefNumber("Headshot Chance", 50)
    local names = headshot and {"Head"} or {"UpperTorso", "Torso"}

    local target = pickTarget(
        cam,
        prefNumber("Silent FOV", 150),
        prefNumber("Silent Distance", 1000),
        names,
        pref("Silent Visible Check", false) == true
    )
    if not target then return nil end
    return {Position = target.Position, Part = target.Part, Model = target.Model, Headshot = headshot}
end
shared.AFG_SilentAim = silentAim

---------------------------------------------------------------------------
-- ESP
---------------------------------------------------------------------------
local function newLine()
    local f = Instance.new("Frame")
    f.AnchorPoint = Vector2.new(0.5, 0.5)
    f.BorderSizePixel = 0
    f.Visible = false
    f.Parent = Overlay
    return f
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

    local box = Instance.new("Frame")
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Visible = false
    box.Parent = Overlay
    local boxStroke = Instance.new("UIStroke")
    boxStroke.Parent = box
    e.Box, e.Stroke = box, boxStroke

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromOffset(240, 20)
    label.AnchorPoint = Vector2.new(0.5, 1)
    label.Font = Enum.Font.GothamMedium
    label.TextStrokeTransparency = 0.4
    label.Visible = false
    label.Parent = Overlay
    e.Label = label

    local back = Instance.new("Frame")
    back.BackgroundColor3 = Color3.fromRGB(15, 20, 28)
    back.BorderSizePixel = 0
    back.AnchorPoint = Vector2.new(1, 0)
    back.Visible = false
    back.Parent = Overlay
    local fill = Instance.new("Frame")
    fill.BorderSizePixel = 0
    fill.AnchorPoint = Vector2.new(0, 1)
    fill.Position = UDim2.new(0, 0, 1, 0)
    fill.Parent = back
    e.HealthBack, e.HealthFill = back, fill

    e.Tracer = newLine()
    return e
end

local function hideEntry(e)
    e.Box.Visible = false
    e.Label.Visible = false
    e.HealthBack.Visible = false
    e.Tracer.Visible = false
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
                local corner = cf:PointToWorldSpace(Vector3.new(ix * size.X / 2, iy * size.Y / 2, iz * size.Z / 2))
                local sp = cam:WorldToViewportPoint(corner)
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
        placeLine(e.Tracer, Vector2.new(o.viewport.X / 2, o.viewport.Y), Vector2.new((tl.X + br.X) / 2, br.Y), o.thick, o.color)
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
        box = pref("Box ESP", false) == true,
        skeleton = pref("Skeleton ESP", false) == true,
        tracer = pref("Line ESP", false) == true,
        name = pref("Name ESP", false) == true,
        distance = pref("Distance", false) == true,
        health = pref("Health Bar", false) == true,
        thick = math.clamp(prefNumber("Esp Thickness", 2), 1, 5),
        textSize = math.clamp(math.floor(prefNumber("Text Size", 14)), 10, 24),
        color = parseColor(pref("ESP Color", ""), accent),
    }
    local anyOn = o.box or o.skeleton or o.tracer or o.name or o.distance or o.health

    local seen = {}
    if cam and anyOn then
        o.viewport = cam.ViewportSize
        local camPos = cam.CFrame.Position
        local maxDist = prefNumber("Max Distance", 1000)
        local myChar = Player.Character
        for model in pairs(tracked) do
            if model ~= myChar then
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
    end

    for model, e in pairs(entries) do
        if not tracked[model] or not model.Parent then
            destroyEntry(e)
            entries[model] = nil
        elseif not seen[model] then
            hideEntry(e)
        end
    end
end

---------------------------------------------------------------------------
-- FOV circles
---------------------------------------------------------------------------
local function makeCircle(color)
    local f = Instance.new("Frame")
    f.BackgroundTransparency = 1
    f.BorderSizePixel = 0
    f.AnchorPoint = Vector2.new(0.5, 0.5)
    f.Visible = false
    f.Parent = Overlay
    Instance.new("UICorner", f).CornerRadius = UDim.new(1, 0)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = 1.2
    s.Parent = f
    return f
end
local aimCircle = makeCircle(accent)
local silentCircle = makeCircle(Color3.fromRGB(255, 170, 0))

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
    apply(aimCircle, pref("Aimbot Enabled", false) and pref("Draw FOV Circle", false), prefNumber("FOV", 100))
    apply(silentCircle, pref("Silent Aim Enabled", false) and pref("Draw Silent FOV", false), prefNumber("Silent FOV", 150))
end

---------------------------------------------------------------------------
-- Single cleanup path (panel X, re-run, normal shutdown)
---------------------------------------------------------------------------
local function cleanup()
    if cleaned then return end
    cleaned = true
    pcall(function() RunService:UnbindFromRenderStep(Config.RenderStepName) end)
    for _, c in ipairs(connections) do c:Disconnect() end
    for model, e in pairs(entries) do destroyEntry(e); entries[model] = nil end
    if shared.AFG_SilentAim == silentAim then shared.AFG_SilentAim = nil end
    Overlay:Destroy()
end
table.insert(connections, GUI.Destroying:Connect(cleanup))

local reported = {}
local function guarded(tag, fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok and not reported[tag] then
        reported[tag] = true
        warn("[AirFireGuns] " .. tag .. " error: " .. tostring(err))
    end
end

RunService:BindToRenderStep(Config.RenderStepName, Enum.RenderPriority.Camera.Value + 1, function(dt)
    if not GUI.Parent then cleanup(); return end
    guarded("aimbot", aimbotStep, dt)
    guarded("esp", espStep)
    guarded("circles", circleStep)
end)

---------------------------------------------------------------------------
-- Extra controls added to the existing pages (existing entries untouched)
---------------------------------------------------------------------------
local function prepend(pageName, items)
    local page = pages[pageName]
    for i = #items, 1, -1 do table.insert(page, 1, items[i]) end
end
local function append(pageName, items)
    local page = pages[pageName]
    for _, item in ipairs(items) do table.insert(page, item) end
end

prepend("Aimbot", {
    {type = "toggle",  name = "Aimbot Enabled", value = false},
    {type = "setting", name = "Aim Key", value = Config.DefaultAimKey},
})
append("Aimbot", {
    {type = "slider", name = "Prediction", min = 0, max = 100, value = 0},
    {type = "slider", name = "Target Distance", min = 50, max = 5000, value = 1000},
    {type = "toggle", name = "Visible Check", value = false},
    {type = "toggle", name = "Draw FOV Circle", value = false},
})

prepend("Silent Aim", {
    {type = "toggle", name = "Silent Aim Enabled", value = false},
})
append("Silent Aim", {
    {type = "slider", name = "Silent FOV", min = 10, max = 500, value = 150},
    {type = "slider", name = "Silent Distance", min = 50, max = 5000, value = 1000},
    {type = "toggle", name = "Silent Visible Check", value = false},
    {type = "toggle", name = "Draw Silent FOV", value = false},
})

append("Visuais", {
    {type = "setting", name = "ESP Color", value = "0,190,220"},
})

showPage(activeTab or "Aimbot")  -- re-render so the new controls appear
print("[AirFireGuns] Addon (Aimbot / Silent Aim / ESP) carregado.")
