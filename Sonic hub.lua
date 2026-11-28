-- Eclypse V30 (base: V29) | novo: animacoes (toast, troca de aba, hover, dropdown), abas Hitbox/Bots/Safety, configuracoes completas, menos carga por frame. Historico V29: | logo da foto do usuario (PNG transparente, 3 niveis de carregamento), cor do menu configuravel, efeitos ao abrir, otimizacoes de desempenho (cache de visibilidade, mira a 30Hz, ESP a 100Hz, profiler)
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
local EX = {perfLast = {}, prof = {}, profT = os.clock()}
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
EX.AccentPresets = {Vermelho = Color3.fromRGB(255, 40, 60), Azul = Color3.fromRGB(60, 140, 255), Roxo = Color3.fromRGB(150, 90, 255), Verde = Color3.fromRGB(50, 220, 120), Ciano = Color3.fromRGB(40, 210, 230), Laranja = Color3.fromRGB(255, 140, 40), Rosa = Color3.fromRGB(255, 80, 170), Branco = Color3.fromRGB(235, 235, 245)}
EX.AccentColor = Theme.accent
function EX.applyAccent()
    local preset = get("set_acc_preset", "Personalizado")
    local c = EX.AccentPresets[preset] or Color3.fromRGB(getNum("set_acc_r", 255), getNum("set_acc_g", 40), getNum("set_acc_b", 60))
    local old = EX.AccentColor
    if old == c then return end
    EX.AccentColor = c; Theme.accent = c
    local function sweep(root)
        if not root then return end
        for _, d in ipairs(root:GetDescendants()) do
            if d:IsA("GuiObject") then
                if d.BackgroundColor3 == old then d.BackgroundColor3 = c end
                if (d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox")) and d.TextColor3 == old then d.TextColor3 = c end
                if (d:IsA("ImageLabel") or d:IsA("ImageButton")) and d.ImageColor3 == old then d.ImageColor3 = c end
                if d:IsA("ScrollingFrame") and d.ScrollBarImageColor3 == old then d.ScrollBarImageColor3 = c end
            elseif d:IsA("UIStroke") then if d.Color == old then d.Color = c end
            elseif d:IsA("UIGradient") then
                local ks, ch, nk = d.Color.Keypoints, false, {}
                for i, k in ipairs(ks) do if k.Value == old then nk[i] = ColorSequenceKeypoint.new(k.Time, c); ch = true else nk[i] = k end end
                if ch then d.Color = ColorSequence.new(nk) end
            end
        end
    end
    sweep(PlayerGui:FindFirstChild("DrxHub")); sweep(PlayerGui:FindFirstChild("DrxOverlay"))
end
EX.prefHook = function(k)
    if EX.styleToggle and type(k) == "string" and k:sub(1, 7) == "set_tgl" then EX.styleToggle() end
    if (k == "set_acc_preset" or k == "set_acc_r" or k == "set_acc_g" or k == "set_acc_b") and not EX.accPending then
        EX.accPending = true
        task.delay(0.12, function() EX.accPending = false; pcall(EX.applyAccent) end)
    end
    if (k == "set_bg_r" or k == "set_bg_g" or k == "set_bg_b") and not EX.bgPending then
        EX.bgPending = true
        task.delay(0.05, function() EX.bgPending = false; pcall(EX.applyBackground) end)
    end
    if k == "set_visual_theme" and not EX.themePending then
        EX.themePending = true
        task.delay(0.06, function()
            EX.themePending = false
            pcall(EX.applyVisualTheme, get("set_visual_theme", "Halloween"))
        end)
    end
end
function EX.timed(name, fn, ...)
    local t0 = os.clock(); fn(...)
    local dt = os.clock() - t0
    local pf = EX.prof[name]; if not pf then pf = {t = 0, n = 0}; EX.prof[name] = pf end; pf.t = pf.t + dt; pf.n = pf.n + 1
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

-- ===== V30: helpers de animacao / refresh de widgets =====
EX.Refresh = {}
EX.ddTok = setmetatable({}, {__mode = "k"})
function EX.ddToggle(list, n, open)
    local tok = (EX.ddTok[list] or 0) + 1; EX.ddTok[list] = tok
    local w = list.Size.X
    if open then
        list.ClipsDescendants = true; list.Size = UDim2.new(w.Scale, w.Offset, 0, 0); list.Visible = true
        TweenService:Create(list, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(w.Scale, w.Offset, 0, n * 24)}):Play()
    else
        local tw = TweenService:Create(list, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(w.Scale, w.Offset, 0, 0)})
        tw:Play(); tw.Completed:Connect(function() if EX.ddTok[list] == tok then list.Visible = false end end)
    end
end
-- hover nas linhas (cartao clareia + borda puxa a cor do menu)
function EX.decorate(root)
    local ti = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    for _, d in ipairs(root:GetDescendants()) do
        if d:IsA("Frame") and d.BackgroundColor3 == Theme.card then
            local st = d:FindFirstChildOfClass("UIStroke")
            if st and not d:GetAttribute("hov") then
                d:SetAttribute("hov", true)
                d.MouseEnter:Connect(function()
                    local c = Theme.card
                    TweenService:Create(d, ti, {BackgroundColor3 = Color3.new(math.min(c.R + 0.045, 1), math.min(c.G + 0.03, 1), math.min(c.B + 0.03, 1))}):Play()
                    TweenService:Create(st, ti, {Color = Theme.accent:Lerp(Theme.stroke, 0.55)}):Play()
                end)
                d.MouseLeave:Connect(function()
                    TweenService:Create(d, ti, {BackgroundColor3 = Theme.card}):Play()
                    TweenService:Create(st, ti, {Color = Theme.stroke}):Play()
                end)
            end
        end
    end
end

-- ===== ECLYPSE: logo + tela de carregamento =====
EX.LOGO_B64 = "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"
EX.LOGO_SM_B64 = "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"
EX.LOGO_ASPECT = 1.627907
EX.LOGO_RLE_W, EX.LOGO_RLE_H = 400, 245
EX.LOGO_RLE = "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EBMXGiEoMT9QXHjD///29vX19PT09fb29/f/z392eXVuaJd5CwABAwA8AQABHUkAAQIA/wAfAgIDBggJCw8RFRogJSoyQVBeluf/+fj49/b29fX09fb19vy+fHx5dGxxolcAAgIAPQEAAR9QAAECAP8AHgIDBAUGCQsOEhYcJCsyO0hUabL5/Pb3+Pf29/f29vX18vXyq3p/enVqe6I4AAECAQA+AQABIVUAAQIA/wAdAQMEBQYICw4RFRskLjZDVF+A1P/29Pb39/b29vb39vbz9eyif4Z/e22LnCIAAQQAQAEAASNcAAECAP8AHQIEBQcJDA8RFBkhKzdFVWOc7//29vb39vf29vb29vf1+eyiiY6JhXaclBMAAQMAQQEAASZnAAECAP8AGwECAwUGCAwPEhQZHycxQlNlrvv89/j39/f39/b19vb39fzuqpaYko+EqooIAAECAEIBAAEocgABAgD/ABsBAQMFBwoOEhYbIigwQFBowf/69/n4+Pj49/f39vf29v3trqKim5eLs3oAAgIAQwIAASp+AAECAP8AGgECAwQGCQ0RFxwjLDVET3HS//X1+Pj3+Pj4+Pj49/f1++mxqKihnJG1dQABAQEARAIAASuEAAECAP8AGQEDBAQFCAoOExkhKzhKVHve//T09vf29vf3+Pn5+Pj2++uyqamkoJS4bAABAgEARQIAAS+LAAECAP8AGQIEBQUHCgwQFh4nNUhTie3/8/T29vb29vf29vf4+fj78LuvrailmrptAAECAQBGAgABMpEAAQIA/wAZAgQFCAoNERUbIy9BTJH0/PT39vb19fb29vb29vf3+vXHuriyrqTBdgABAgEARwIAATeYAAECAP8AFwEBBAcICg0RFRsjLDtBj/n79Pb29vX29vb19vf29vb49c7Bw765r8iDAAECAQBIAgABP6IAAQIA/wAXAQMEBgoMEBUdJS48QZT69vDz9PX19vb39/f39vb29fbUwsTCwbbMjAMCAQBJAgABR64AAQIA/wAWAQEDBAcLDxUdJjE/RZr98uvu8fL09fb29vf4+Pf39vfcx8fEw73NlQUBAQBKAwABTbQAAQIA/wAWAQMEBgkNEhokMD5Fof/v6ezt8PHz9PX19vf39/f3+uXOzsrIw8+qCwABAgBLAwABUbsAAQIA/wAVAQIDBgkMEBUeKzpCpP/x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AQD/AI0OIwABAQDKAQEBAQEBAQEBAQICAgICAQEBAQEBAQEBADQBAwICAQEBAQEBAgICAgIBAQEBAgMBADEBAgIBACsFCgAVAgECAQARAQIBAQAyAQEBAQEBAQECAgICAQEBAQEBAQIDAgAzAQMDAgEBAQICAgICAgEBAQEBAgICAgBYAgAWAQB0AwAFAQAPAQAFBABGAQEAMAIAIQIAAVGqoqSmqKeop6alpKWnqauur6+vrq2tqBgAAQEALwIAARprk6Wura2trKqpp6eqrK6xsLSeVQcAAQEALQEAAXmvtGcAAQIAPQEKkbKwrBwAAQIADQIAAQ+iubumFAABAQArAQABHbC1tLKysbCvrayrrK6wsbKzsLCojkIAAgEALgEAARRqmquxr66sqainqKqur7Gxrquqp4gEAAoDAAFu5NXi7O7x9Pb4+Pj7/f////////////4kAAECAC4CAAFJ2PLz/f////////7+///////////+tA4BAQAsAQABsf//lQABAwA9AgABN+3//8YOAgIACwECA63//flHAAECACwCAAEg8v//////////////////////////+5YGAgEALAIAATbW+//////////////////////////iDAABAQAIAwABZc/JsIeKio2Njo2MjY6PkJSXmpucmpqSFAABAQAtAgABI97h3Nefk5SVlJOTk5OVl5eanJ6m2O7/aAABAwAsAQABpfb4iQABAwA+AgABMefw/aMAAQIBAAoDAAGU/+7wRQABAgAtAQABGuDx66idn5+fn56dnJycnZ+goZ699e3/dAABAwArAQENzvTp3aCZmZiWlZORkZGRlJaXmZTR9MkKAAEBAAgDAAFmztN1AEQDAAF+6tnTMwAQU/P6iAABAwAsAgABovX1hwABAwA/BAABOuvv/IIAAQMACQQAAYD/7vdQAAEEAC4BAAEb4vLiEwAPA3/28MwIAAEBACoDAAFA8+beMQAQtv/SBwABAQAIAwABaM/PegIEAgICAgICAgICAgICAgICAgICADACAAGd5e2AAAEFAgICAwMCAgICAgICAgYCO/7/kwABAwAsAgABnPHzhAABAwBABAABQOvt/XgAAQMABwMAAWz/7fteAAEEAC8BAAEb4/LiHwIEAgICAgICAgICAgICBAABDNTv3x0AAQIAKgMAAU3t7bIAAQQCAgMDAgICAgICAgIDBAN/p4QGAAEBAAgDAAFnzc15AAECAEICAAGZ5u5wAgQADQEAAR6IllIAAQIALAIAAZrw84YAAQMAQQQAAU3y7v5mAAEEAAUEAAFV+u/+bAABBAAwAQABGuHz5B0AAQIADAEBDMny3x8AAQIAKgMAAUbm6bMCAB4DAAFjycx7AAECAEICAAGb5ex3AAEEAEECAAGd8vWJAAEDAEIEAAFg+/P3SAABBAADAwABRPPt/3kAAQMAMQEAARfd8uYfAAECAAwBAAEQ0vXiIAABAgAqAwABR+PltAIAEAECAgALAwABXcPIfAIEAgICAgICAgICAgICAgIBADMCAAGY4Oh1AAEEAA8BAwMBAC4BAAGh8/aIAAEDAEMEAAFv/PDoMQABAwABAwABM+rv/ooAAQMBADEBAAEY3PHmHwABAgAMAQABE9j45iQAAQIAKgMAAUnl5bEDAgICAgICAgICAgICAgICAgEADQIAAVm9xHkARAIAAZDY4XEAAQQAQQEAAaLw8oUAAQMARAQAAXr38t4oAAEFAAEi4PT/nwABAwEAMgEAARrf8eYfAAECAAwBAAEU2PrnJgABAgAqAwABS+PftgASAwEACwIAAVe5u4kkKSkqKiorKysrKikpKSUrFAABAQAxAQABitDYawABAwBBAQABn+rtggABAwBEAQMAAYL28tEdAAEVy/X9sQgBAQAzAQABHOLx4iADBQMDAwMDAwMDAwMDAwQCD9z35iMAAQIAKgIAASva0NVtJCUlJSUlJSYmJicoKCksKgwAAgEACgIAAVW4rLSzub/DyM3Q09XW1tTT0dLOKAABAgAxAQABh8rSZgABAwBBAQABmuXpgAABAwBFAQIAAZb59r8lsvb4uQwAAQEANAEAARvh798RABBf8e7aEQABAQArAgABiuPS1svM0NHT1dbX2NjY2dvd3dzHgg8AAQEACQIAAVW3qrG4u8DEzNHV1tjY2NfY1uJSAAEDADIBAAGDw8xjAAEDAEECAAGW4eeBAAEDAEYBAgal/O3a6PbCDwABAgA1AQABF9rr4V1HTE5PT1BRUlJTVFZXWF2V5977mAABAgAsAQEKecPa3t/h4+Pm6Ojn5eTk5unq7eb3sQwBAQAIAgABVbSyhjM1MzQ1Nzc2NDMzMzQ2MQABAQAzAQABgsDIYQABAwBBAgABleHnggABAwBHAQABCazx5e7NGgABAgA2AQABFNfp5/f5+vr5+Pn5+vz+/v79+/j37vjCGQECADAXQEdGRkZGRkdHR0ZEREVKSYDj3flaAAEDAAgCAAFXtLZzAEQBAAGEv8VgAAEDAEECAAGV4uWBAAEDAEgCAAEg4ufwOAABAwA3AQABFtjr6ePh4N7c2tnZ297i4+Xl5eTbvHMNAAEBAC8BAgASlO3yhgABAwAIAgABVrO3fAIEAgICAgICAgICAgICAgA1AQABhr7EYAABAwAQAgIBAC4BAAGU3uGAAAEDAEgBARvV5uYnAQIANwEAARnd7uk7GR4bGhoZGRobHB4gICIiFwIAAgEAMgEDAwMDAwMDAwMDAwMDAwMGAnju7YIAAQMACAIAAVGvtXoAAQIAQgEAAYS6wWAAAQMAQQEAAY/X23wAAQIASAEAARvR3+EnAAECADcBAAEc4O/pHgARAwEAMAEDAwIADwMAAX/s6X4AAQMACAIAAU+rsXoAAQIAQgEAAX+2v2AAAQMADQEBBy41IAABAQAsAQABidHUdwABAgBIAQABGs3c3CUAAQIANwEAARve7eciAQQCAgEBAQECAgICAgICAQEARQMAAX/q6X8AAQMACAIAAVCrr3kCBAICAgICAgICAgICAgICAgICAgAwAQABfLC5WAIFAgICAgICAgICAgICAgQDJuP7iwABAwAsAQABh83QdQIEAgICAgICAgICAgICAgICAgIANwEAARnO398mAAECADcBAAEZ2OnjIAABAgA/AQABHG1zUAIDAgICAgICAgICAgICAgUCdujpfgABAwAIAgABUaqtbwBEAQABcqerawARNePtggABAwAsAQABic7OcABKAQABGc/i4igAAQIANwEAARfV598fAAECAD8CAAE72eCiABGG4uN9AAEDAAgCAAFQpqaBLzY0NDEvLy4uMDI0NTU1NTY3NzYHAAEBAC0CAAFJopOaWi8oJycnJykqKywtLS0tKUen0uJ3AAEDACwBAAGKzcuGKi8tLCwsKyopKSkqLC4wMjQ2MAQANgEAARnQ4OApAAECADcBAAEZ1+beHwABAgA/AgABM8PFqDUzMTEwLi0tLCssLS4wMDNw0MzjVwABAwAIAgABTKGWpK20uLq7vsPIzNHV2+Dk5+nq6eXhJQABAgAtAQAB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"
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
    function EX.logoAsset(b64, name)
        local gca = getcustomasset or getsynasset
        if not (writefile and gca) then return nil end
        local ok, res = pcall(function()
            if not (isfile and isfile(name)) then writefile(name, EX.b64decode(b64)) end
            return gca(name)
        end)
        if ok and type(res) == "string" and res ~= "" then return res end
        return nil
    end
end
function EX.makeLogo(parent, h, props)
    props = props or {}
    local z = props.ZIndex or 1
    local usePng = (EX.asset or EX.editable) ~= nil
    local w = math.floor(h * (usePng and EX.LOGO_ASPECT or (208 / 178)) + 0.5)
    local box = new("Frame", {Name = "EclypseLogo", Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1, AnchorPoint = props.AnchorPoint or Vector2.new(0, 0), Position = props.Position or UDim2.fromOffset(0, 0), ZIndex = z}, parent)
    if usePng then
        local il = new("ImageLabel", {Name = "EclypseLogoImage", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, ZIndex = z}, box)
        if EX.asset then il.Image = (h <= 80 and EX.assetSmall) or EX.asset else pcall(function() il.ImageContent = Content.fromObject(EX.editable) end) end
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
    L.logoH = 160
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
    label(root, {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -22), Size = UDim2.fromOffset(500, 14), Text = EX.Brand.name:upper() .. "  |  UNIVERSAL  |  by " .. EX.Brand.author .. "  |  V29", TextSize = 10, TextColor3 = Color3.fromRGB(120, 110, 120), TextXAlignment = Enum.TextXAlignment.Center})
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
        local hs = halo:FindFirstChildOfClass("UIStroke"); if hs then hs.Transparency = 0.5 + 0.3 * (1 - pulse) end
        local vs = root.AbsoluteSize
        L.logo.AnchorPoint = Vector2.new(0, 0); L.logo.Position = UDim2.fromOffset(math.floor(vs.X * cx - L.logoW / 2 + 0.5), math.floor(vs.Y * cy - 34 - L.logoH / 2 + 0.5))
    end)
    TweenService:Create(root, TweenInfo.new(0.4), {GroupTransparency = 0}):Play()
end
EX.asset = EX.logoAsset(EX.LOGO_B64, "eclypse_logo_v3.png")
EX.assetSmall = EX.logoAsset(EX.LOGO_SM_B64, "eclypse_logo_v3_s.png")
-- nivel 2 (sem writefile/getcustomasset): EditableImage montado a partir do mapa de alfa embutido (RLE)
function EX.logoEditable()
    local ok, res = pcall(function()
        local w, h = EX.LOGO_RLE_W, EX.LOGO_RLE_H
        local img = game:GetService("AssetService"):CreateEditableImage({Size = Vector2.new(w, h)})
        local raw = EX.b64decode(EX.LOGO_RLE); local n = w * h
        local buf = buffer.create(n * 4); local p, o, len = 1, 0, #raw
        while p <= len and o < n do
            local b = string.byte(raw, p)
            if b == 0 then
                local c = string.byte(raw, p + 1); p = p + 2
                for _ = 1, c do if o < n then buffer.writeu32(buf, o * 4, 0x00FFFFFF); o = o + 1 end end
            else buffer.writeu32(buf, o * 4, 0xFFFFFF + b * 16777216); o = o + 1; p = p + 1 end
            if o % 25000 == 0 then task.wait() end
        end
        img:WritePixelsBuffer(Vector2.new(0, 0), Vector2.new(w, h), buf)
        return img
    end)
    if ok and res then return res end
    return nil
end
if not EX.asset then EX.editable = EX.logoEditable() end
print("[Eclypse] logo: " .. (EX.asset and "PNG alta resolucao (getcustomasset)" or (EX.editable and "EditableImage" or "vetor simples (sem writefile/getcustomasset e sem EditableImage)")))
EX.buildLoading()
EX.step(10, "Preparing environment...")

local GUI = new("ScreenGui", {Name = "DrxHub", ResetOnSpawn = false, DisplayOrder = 100, ZIndexBehavior = Enum.ZIndexBehavior.Global, Enabled = false}, PlayerGui)
local Overlay = new("ScreenGui", {Name = "DrxOverlay", ResetOnSpawn = false, DisplayOrder = 999, IgnoreGuiInset = true}, PlayerGui)

-- UI MOUSE FIX
local UiMouse = {open = false, saved = nil, wanted = nil, wantedIcon = nil, guess = nil, modal = nil, alive = true, hooked = false, hbConn = nil}
do
    local ACTION_SINK, STEP_NAME = "DrxUiMouseSink", "DrxUiMouseUnlock"
    local function sink() return Enum.ContextActionResult.Sink end
    -- "em partida" = personagem vivo com a camera na cabeca (primeira pessoa). Fora disso (lobby) nunca se restaura trava do mouse.
    function UiMouse.inMatch()
        local c = LP.Character; local h = c and c:FindFirstChildOfClass("Humanoid"); local head = c and c:FindFirstChild("Head"); local cam = Workspace.CurrentCamera
        if not (h and h.Health > 0 and head and cam) then return false end
        return (cam.CFrame.Position - head.Position).Magnitude < 2.5
    end
    local function enforce()
        local mb = UserInputService.MouseBehavior
        if mb ~= Enum.MouseBehavior.Default then if not UiMouse.hooked then UiMouse.guess = mb end; UserInputService.MouseBehavior = Enum.MouseBehavior.Default end
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
            UiMouse.wanted, UiMouse.wantedIcon, UiMouse.guess = nil, nil, nil
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
            local guess = UiMouse.guess; UiMouse.wanted, UiMouse.wantedIcon, UiMouse.guess = nil, nil, nil
            local match = UiMouse.inMatch()
            if beh == nil then
                beh = guess or (sv and sv.behavior)
                if beh == Enum.MouseBehavior.LockCenter and not match then beh = Enum.MouseBehavior.Default end
            end
            if icon == nil and sv then icon = sv.icon end
            if icon == false and not match then icon = true end
            if icon ~= nil then UserInputService.MouseIconEnabled = icon end
            if beh ~= nil then UserInputService.MouseBehavior = beh end
        end
    end
end
Conns[#Conns + 1] = GUI:GetPropertyChangedSignal("Enabled"):Connect(function() if EX.Load.active and GUI.Enabled then GUI.Enabled = false; return end; UiMouse.setOpen(GUI.Enabled); if GUI.Enabled and EX.openFX then task.spawn(EX.openFX) end end)

-- UI V19
local Main = new("Frame", {Size = UDim2.fromOffset(820, 580), Position = UDim2.new(0.5, -410, 0.5, -290), BackgroundColor3 = Theme.bg, Active = true}, GUI)
corner(Main, 12); outline(Main, 2, Theme.accent)
local TopBar = new("Frame", {Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = Theme.panel}, Main)
corner(TopBar, 12)
new("Frame", {Size = UDim2.new(1, 0, 0, 15), Position = UDim2.new(0, 0, 1, -15), BackgroundColor3 = Theme.panel}, TopBar)
new("Frame", {Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, -2), BackgroundColor3 = Theme.accent}, TopBar)
EX.makeLogo(TopBar, 44, {Position = UDim2.fromOffset(12, 3), cut = Theme.panel, ZIndex = 2})
label(TopBar, {Size = UDim2.fromOffset(200, 50), Position = UDim2.fromOffset(96, 0), Text = "ENTERPRISE  V30", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.sub})
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
    EX.makeLogo(card, 34, {Position = UDim2.fromOffset(10, 8), cut = Theme.panel, ZIndex = 61})
    label(card, {ZIndex = 61, Size = UDim2.fromOffset(66, 18), Position = UDim2.fromOffset(56, 7), Text = B.name, Font = Enum.Font.GothamBlack, TextSize = 14})
    label(card, {ZIndex = 61, Size = UDim2.fromOffset(110, 14), Position = UDim2.fromOffset(124, 9), Text = "by " .. B.author, TextSize = 11, TextColor3 = Theme.accent, Font = Enum.Font.GothamBold})
    label(card, {ZIndex = 61, Size = UDim2.fromOffset(190, 14), Position = UDim2.fromOffset(56, 27), Text = B.discord, TextSize = 11, TextColor3 = Theme.sub})
    local copy = new("TextButton", {ZIndex = 61, Size = UDim2.fromOffset(62, 24), Position = UDim2.new(1, -72, 0.5, -12), BackgroundColor3 = Theme.accent, Text = "Copiar", Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = Theme.text, AutoButtonColor = false}, card)
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

do
    local last = 0
    function EX.openFX()
        if not Main or not Main.Parent then return end
        local now = os.clock(); if now - last < 0.3 then return end; last = now
        pcall(function()
            local acc = Theme.accent; local rng = Random.new()
            local function tw(i, t, p, st, dr) local tr = TweenService:Create(i, TweenInfo.new(t, st or Enum.EasingStyle.Quad, dr or Enum.EasingDirection.Out), p); tr:Play(); return tr end
            -- 1) entrada: desliza e clareia
            local base = Main.Position
            Main.Position = base + UDim2.fromOffset(0, 26)
            tw(Main, 0.42, {Position = base}, Enum.EasingStyle.Back)
            local cover = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.35, BorderSizePixel = 0, ZIndex = 2300}, Main); corner(cover, 12)
            tw(cover, 0.4, {BackgroundTransparency = 1}); Debris:AddItem(cover, 0.5)
            -- 2) anel de energia
            local ring = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(820, 580), BackgroundTransparency = 1, ZIndex = 2500}, Main); corner(ring, 14)
            local rs = new("UIStroke", {Color = acc, Thickness = 3, Transparency = 0.1}, ring)
            tw(ring, 0.7, {Size = UDim2.fromOffset(930, 690)}); tw(rs, 0.7, {Transparency = 1, Thickness = 1}); Debris:AddItem(ring, 0.8)
            -- 3) feixe de luz atravessando o menu
            local clip = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 2400}, Main); corner(clip, 12)
            local bar = new("Frame", {Size = UDim2.fromOffset(150, 760), Position = UDim2.fromOffset(-260, -90), Rotation = 16, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0, BorderSizePixel = 0, ZIndex = 2400}, clip)
            new("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.82), NumberSequenceKeypoint.new(1, 1)})}, bar)
            tw(bar, 0.85, {Position = UDim2.fromOffset(960, -90)}, Enum.EasingStyle.Sine); Debris:AddItem(clip, 1)
            -- 4) fagulhas subindo
            for i = 1, 18 do
                task.delay(i * 0.025, function()
                    if not Main.Parent then return end
                    local sx, sy = rng:NextInteger(20, 800), rng:NextInteger(6, 70)
                    local sz = rng:NextInteger(4, 7)
                    local f = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(sx, sy), Size = UDim2.fromOffset(sz, sz), Rotation = 45, BackgroundColor3 = (i % 3 == 0) and Color3.fromRGB(255, 255, 255) or acc, BorderSizePixel = 0, ZIndex = 2500}, Main)
                    local life = 0.7 + rng:NextNumber() * 0.5
                    tw(f, life, {Position = UDim2.fromOffset(sx + rng:NextInteger(-40, 40), sy - rng:NextInteger(40, 110)), BackgroundTransparency = 1, Size = UDim2.fromOffset(0, 0)})
                    Debris:AddItem(f, life + 0.1)
                end)
            end
            -- 5) brilho do logo
            local box = TopBar:FindFirstChild("EclypseLogo"); local li = box and box:FindFirstChild("EclypseLogoImage")
            if li then li.ImageColor3 = acc; tw(li, 0.8, {ImageColor3 = Color3.new(1, 1, 1)}) end
        end)
    end
end

local Body = new("Frame", {Position = UDim2.fromOffset(0, 50), Size = UDim2.new(1, 0, 1, -50), BackgroundTransparency = 1}, Main)
local Sidebar = new("Frame", {Position = UDim2.fromOffset(15, 15), Size = UDim2.fromOffset(170, 495), BackgroundColor3 = Theme.panel}, Body)
corner(Sidebar, 10); outline(Sidebar, 1, Theme.stroke)
local NavList = new("ScrollingFrame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ScrollBarThickness = 0, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new()}, Sidebar)
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
    local function render() local on = get(key); tween(sw, {BackgroundColor3 = on and Theme.accent or Theme.track}); TweenService:Create(knob, TweenInfo.new(0.26, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = on and UDim2.fromOffset(19, 3) or UDim2.fromOffset(3, 3), BackgroundColor3 = on and Theme.text or Theme.sub}):Play() end
    sw.MouseButton1Click:Connect(function() set(key, not get(key)); render() end)
    render()
    EX.Refresh[key] = render
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
    EX.Refresh[key] = function() update((getNum(key, default) - min) / math.max(max - min, 1)) end
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
        b.MouseButton1Click:Connect(function() set(key, opt); txt.Text = opt; EX.ddToggle(list, #options, false) end)
    end
    btn.MouseButton1Click:Connect(function() EX.ddToggle(list, #options, not list.Visible) end)
    EX.Refresh[key] = function() txt.Text = tostring(get(key)) end
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
    EX.Refresh[key] = function() btnKey.Text = tostring(get(key).Key); btnMode.Text = tostring(get(key).Mode) end
    btnMode.MouseButton1Click:Connect(function() local modes = {"Always", "Hold", "Toggle"}; local curr = get(key).Mode; local nextMode = modes[1]; for i, m in ipairs(modes) do if m == curr then nextMode = modes[(i % #modes) + 1] break end end; set(key, {Key = get(key).Key, Mode = nextMode}); btnMode.Text = nextMode end)
    btnKey.MouseButton1Click:Connect(function() btnKey.Text = "..."; local conn; conn = UserInputService.InputBegan:Connect(function(input, processed) if processed then return end; local kName = nil; if input.UserInputType == Enum.UserInputType.Keyboard then kName = input.KeyCode.Name elseif input.UserInputType == Enum.UserInputType.MouseButton1 then kName = "LMB" elseif input.UserInputType == Enum.UserInputType.MouseButton2 then kName = "RMB" elseif input.UserInputType == Enum.UserInputType.MouseButton3 then kName = "MMB" end; if kName then set(key, {Key = kName, Mode = get(key).Mode}); btnKey.Text = kName; conn:Disconnect() end end) end)
end
-- ===== V30: widgets novos (botao, caixa de texto, cartao de info, dropdown dinamico) =====
function EX.Btn(parent, name, desc, fn)
    local h = desc and 48 or 40
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = Theme.card}, parent)
    corner(row, 8); outline(row, 1, Theme.stroke)
    label(row, {Size = UDim2.new(1, -110, 0, 18), Position = UDim2.fromOffset(12, desc and 6 or 11), Text = name, TextSize = 13, Font = Enum.Font.GothamBold})
    if desc then label(row, {Size = UDim2.new(1, -110, 0, 14), Position = UDim2.fromOffset(12, 25), Text = desc, TextSize = 10, TextColor3 = Theme.sub, TextTruncate = Enum.TextTruncate.AtEnd}) end
    local b = new("TextButton", {Size = UDim2.fromOffset(80, 24), Position = UDim2.new(1, -92, 0.5, -12), BackgroundColor3 = Theme.panel, Text = "Run", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Theme.text, AutoButtonColor = false}, row)
    corner(b, 6); outline(b, 1, Theme.stroke)
    b.MouseButton1Click:Connect(function()
        b.BackgroundColor3 = Theme.accent
        TweenService:Create(b, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {BackgroundColor3 = Theme.panel}):Play()
        local ok, err = pcall(fn); if not ok then warn("[Eclypse] " .. tostring(name) .. ": " .. tostring(err)) end
    end)
    return row
end
function EX.TextBox(parent, name, key, placeholder, default, width)
    Prefs[key] = Prefs[key] or default or ""
    local w = width or 130
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = Theme.card}, parent)
    corner(row, 8); outline(row, 1, Theme.stroke)
    label(row, {Size = UDim2.new(1, -(w + 24), 1, 0), Position = UDim2.fromOffset(12, 0), Text = name, TextSize = 13, Font = Enum.Font.GothamBold})
    local tb = new("TextBox", {Size = UDim2.fromOffset(w, 24), Position = UDim2.new(1, -(w + 12), 0.5, -12), BackgroundColor3 = Theme.panel, Text = tostring(get(key)), PlaceholderText = placeholder or "", PlaceholderColor3 = Theme.sub, TextColor3 = Theme.text, Font = Enum.Font.Gotham, TextSize = 12, ClearTextOnFocus = false, TextTruncate = Enum.TextTruncate.AtEnd}, row)
    corner(tb, 6); outline(tb, 1, Theme.stroke)
    tb.FocusLost:Connect(function() set(key, tb.Text) end)
    EX.Refresh[key] = function() tb.Text = tostring(get(key)) end
    return tb
end
function EX.Info(parent, title, text)
    local card = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Theme.card}, parent)
    corner(card, 8); outline(card, 1, Theme.stroke)
    new("UIPadding", {PaddingLeft = UDim.new(0, 20), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8)}, card)
    new("Frame", {Size = UDim2.new(0, 3, 1, 0), Position = UDim2.fromOffset(-12, 0), BackgroundColor3 = Theme.accent, BorderSizePixel = 0}, card)
    local body = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1}, card)
    new("UIListLayout", {Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder}, body)
    label(body, {Size = UDim2.new(1, 0, 0, 16), Text = title, TextSize = 13, Font = Enum.Font.GothamBold, LayoutOrder = 1})
    label(body, {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = text, TextSize = 11, TextColor3 = Theme.sub, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = 2})
    return card
end
function EX.DynDD(parent, name, key, placeholder)
    Prefs[key] = Prefs[key] or ""
    local function shown() local v = get(key); return (v ~= nil and v ~= "") and tostring(v) or (placeholder or "None") end
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = Theme.card}, parent)
    corner(row, 8); outline(row, 1, Theme.stroke)
    label(row, {Size = UDim2.new(1, -140, 1, 0), Position = UDim2.fromOffset(12, 0), Text = name, TextSize = 13, Font = Enum.Font.GothamBold})
    local btn = new("TextButton", {Size = UDim2.fromOffset(120, 24), Position = UDim2.new(1, -132, 0.5, -12), BackgroundColor3 = Theme.panel, Text = "", AutoButtonColor = false}, row)
    corner(btn, 6); outline(btn, 1, Theme.stroke)
    local txt = label(btn, {Size = UDim2.new(1, -16, 1, 0), Position = UDim2.fromOffset(8, 0), Text = shown(), TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd})
    local list = new("ScrollingFrame", {Size = UDim2.fromOffset(120, 0), Position = UDim2.new(1, -132, 1, 4), BackgroundColor3 = Theme.panel, Visible = false, ZIndex = 999, ScrollBarThickness = 2, BorderSizePixel = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y}, row)
    corner(list, 6); outline(list, 1, Theme.stroke)
    new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}, list)
    local obj, count = {}, 0
    function obj.setOptions(opts)
        for _, c in ipairs(list:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
        count = math.min(#opts, 5)
        local found = false
        for i, o in ipairs(opts) do
            if o == get(key) then found = true end
            local b = new("TextButton", {Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Text = o, TextSize = 12, TextColor3 = Theme.sub, ZIndex = 1000, LayoutOrder = i, Font = Enum.Font.Gotham, AutoButtonColor = false}, list)
            b.MouseEnter:Connect(function() b.TextColor3 = Theme.text end)
            b.MouseLeave:Connect(function() b.TextColor3 = Theme.sub end)
            b.MouseButton1Click:Connect(function() set(key, o); txt.Text = o; EX.ddToggle(list, count, false) end)
        end
        if not found and get(key) ~= "" then Prefs[key] = ""; txt.Text = shown() end
        if count == 0 then list.Visible = false end
    end
    btn.MouseButton1Click:Connect(function() if count > 0 then EX.ddToggle(list, count, not list.Visible) end end)
    EX.Refresh[key] = function() txt.Text = shown() end
    return obj
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
    EX.decorate(page)
end
EX.tabCover = new("Frame", {Name = "TabCover", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.bg, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 400}, PageContainer)
local function SwitchPage(name)
    activeSlider = nil
    local prev = EX.curPage; EX.curPage = name
    for n, p in pairs(Pages) do p.Visible = (n == name) end
    for n, b in pairs(NavButtons) do local sel = (n == name); tween(b.bg, {BackgroundColor3 = sel and Theme.accent or Theme.panel}); tween(b.txt, {TextColor3 = sel and Theme.text or Theme.sub}); tween(b.ind, {BackgroundColor3 = sel and Theme.text or Theme.sub}) end
    local pg = Pages[name]
    if pg and prev and prev ~= name then
        pg.Position = UDim2.fromOffset(0, 16)
        TweenService:Create(pg, TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(0, 0)}):Play()
        local cv = EX.tabCover
        if cv then cv.BackgroundTransparency = 0.55; TweenService:Create(cv, TweenInfo.new(0.28, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play() end
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

-- ===== ECLYPSE THEME ENGINE: temas completos + efeitos animados =====
EX.ThemePresets = {
    Halloween = {bg=Color3.fromRGB(8,5,12), panel=Color3.fromRGB(18,10,24), card=Color3.fromRGB(29,16,35), track=Color3.fromRGB(48,27,54), stroke=Color3.fromRGB(83,43,74), accent=Color3.fromRGB(255,112,24), secondary=Color3.fromRGB(171,55,255)},
    Midnight = {bg=Color3.fromRGB(5,8,18), panel=Color3.fromRGB(10,16,32), card=Color3.fromRGB(17,27,48), track=Color3.fromRGB(29,43,69), stroke=Color3.fromRGB(48,67,101), accent=Color3.fromRGB(91,125,255), secondary=Color3.fromRGB(46,220,255)},
    Cyberpunk = {bg=Color3.fromRGB(8,5,18), panel=Color3.fromRGB(19,9,35), card=Color3.fromRGB(31,14,48), track=Color3.fromRGB(53,22,72), stroke=Color3.fromRGB(91,35,105), accent=Color3.fromRGB(255,45,190), secondary=Color3.fromRGB(30,245,255)},
    Ocean = {bg=Color3.fromRGB(3,12,18), panel=Color3.fromRGB(6,24,34), card=Color3.fromRGB(10,39,52), track=Color3.fromRGB(18,58,73), stroke=Color3.fromRGB(30,83,98), accent=Color3.fromRGB(30,205,220), secondary=Color3.fromRGB(66,130,255)},
    Sakura = {bg=Color3.fromRGB(18,8,16), panel=Color3.fromRGB(32,14,27), card=Color3.fromRGB(48,21,39), track=Color3.fromRGB(72,34,57), stroke=Color3.fromRGB(105,52,79), accent=Color3.fromRGB(255,112,177), secondary=Color3.fromRGB(255,205,225)},
    Emerald = {bg=Color3.fromRGB(4,13,10), panel=Color3.fromRGB(8,25,18), card=Color3.fromRGB(14,39,27), track=Color3.fromRGB(24,58,39), stroke=Color3.fromRGB(40,86,57), accent=Color3.fromRGB(45,220,130), secondary=Color3.fromRGB(190,255,105)},
    Crimson = {bg=Color3.fromRGB(14,4,7), panel=Color3.fromRGB(29,7,13), card=Color3.fromRGB(43,12,19), track=Color3.fromRGB(65,19,28), stroke=Color3.fromRGB(100,34,44), accent=Color3.fromRGB(255,42,67), secondary=Color3.fromRGB(255,145,70)},
    Arctic = {bg=Color3.fromRGB(8,14,22), panel=Color3.fromRGB(15,27,39), card=Color3.fromRGB(24,42,57), track=Color3.fromRGB(37,61,78), stroke=Color3.fromRGB(59,91,111), accent=Color3.fromRGB(115,215,255), secondary=Color3.fromRGB(225,250,255)},
    Sunset = {bg=Color3.fromRGB(17,7,12), panel=Color3.fromRGB(34,13,19), card=Color3.fromRGB(51,20,25), track=Color3.fromRGB(75,29,31), stroke=Color3.fromRGB(111,45,42), accent=Color3.fromRGB(255,105,65), secondary=Color3.fromRGB(255,205,75)}
}
EX.ThemeFX = nil
function EX.applyVisualTheme(themeName)
    local cfg = EX.ThemePresets[themeName]
    if not cfg or not GUI or not GUI.Parent then return end
    local old = {bg=Theme.bg, panel=Theme.panel, card=Theme.card, track=Theme.track, stroke=Theme.stroke, accent=Theme.accent}
    local roots = {GUI, PlayerGui:FindFirstChild("DrxOverlay")}
    for _, root in ipairs(roots) do
        if root then
            for _, d in ipairs(root:GetDescendants()) do
                if d:IsA("GuiObject") then
                    if d.BackgroundColor3 == old.bg then d.BackgroundColor3 = cfg.bg
                    elseif d.BackgroundColor3 == old.panel then d.BackgroundColor3 = cfg.panel
                    elseif d.BackgroundColor3 == old.card then d.BackgroundColor3 = cfg.card
                    elseif d.BackgroundColor3 == old.track then d.BackgroundColor3 = cfg.track
                    elseif d.BackgroundColor3 == old.accent then d.BackgroundColor3 = cfg.accent end
                    if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
                        if d.TextColor3 == old.accent then d.TextColor3 = cfg.accent end
                    end
                    if d:IsA("ScrollingFrame") and d.ScrollBarImageColor3 == old.accent then d.ScrollBarImageColor3 = cfg.accent end
                    if d:IsA("ImageLabel") or d:IsA("ImageButton") then
                        if d.ImageColor3 == old.accent then d.ImageColor3 = cfg.accent end
                    end
                elseif d:IsA("UIStroke") then
                    if d.Color == old.stroke then d.Color = cfg.stroke
                    elseif d.Color == old.accent then d.Color = cfg.accent end
                end
            end
        end
    end
    Theme.bg, Theme.panel, Theme.card, Theme.track, Theme.stroke, Theme.accent =
        cfg.bg, cfg.panel, cfg.card, cfg.track, cfg.stroke, cfg.accent
    EX.Palette.bg, EX.Palette.panel, EX.Palette.card, EX.Palette.track, EX.Palette.stroke =
        cfg.bg, cfg.panel, cfg.card, cfg.track, cfg.stroke
    EX.AccentColor = cfg.accent
    Prefs.set_acc_preset = "Personalizado"
    Prefs.set_acc_r, Prefs.set_acc_g, Prefs.set_acc_b = math.floor(cfg.accent.R*255), math.floor(cfg.accent.G*255), math.floor(cfg.accent.B*255)

    if EX.ThemeFX and EX.ThemeFX.Parent then EX.ThemeFX:Destroy() end
    local fx = Instance.new("Folder")
    fx.Name = "EclypseThemeFX"
    fx.Parent = TopBar
    EX.ThemeFX = fx

    local line = Instance.new("Frame")
    line.Name = "AnimatedThemeLine"
    line.BorderSizePixel = 0
    line.BackgroundColor3 = cfg.accent
    line.Position = UDim2.new(0, 0, 1, -3)
    line.Size = UDim2.new(1, 0, 0, 3)
    line.ZIndex = 30
    line.Parent = fx
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, cfg.accent),
        ColorSequenceKeypoint.new(0.5, cfg.secondary),
        ColorSequenceKeypoint.new(1, cfg.accent)
    })
    grad.Offset = Vector2.new(-1, 0)
    grad.Parent = line
    TweenService:Create(grad, TweenInfo.new(2.8, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false), {Offset=Vector2.new(1,0)}):Play()

    local border = Main:FindFirstChildOfClass("UIStroke")
    if border then
        local bg = border:FindFirstChild("ThemeGradient")
        if bg then bg:Destroy() end
        local borderGrad = Instance.new("UIGradient")
        borderGrad.Name = "ThemeGradient"
        borderGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, cfg.accent),
            ColorSequenceKeypoint.new(0.5, cfg.secondary),
            ColorSequenceKeypoint.new(1, cfg.accent)
        })
        borderGrad.Parent = border
        TweenService:Create(borderGrad, TweenInfo.new(5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false), {Rotation=360}):Play()
    end

    -- Particulas discretas na barra: poucos objetos, sem loop por frame.
    local rng = Random.new()
    for i=1,7 do
        local dot = Instance.new("Frame")
        dot.Name = "ThemeSpark"..i
        dot.BorderSizePixel = 0
        dot.Size = UDim2.fromOffset(rng:NextInteger(2,4), rng:NextInteger(2,4))
        dot.Position = UDim2.new(rng:NextNumber(0.05,0.95), 0, rng:NextNumber(0.15,0.8), 0)
        dot.BackgroundColor3 = (i%2==0) and cfg.secondary or cfg.accent
        dot.BackgroundTransparency = 0.15
        dot.ZIndex = 25
        dot.Parent = fx
        local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(1,0); cr.Parent = dot
        local tw = TweenService:Create(dot, TweenInfo.new(rng:NextNumber(1.8,3.2), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
            Position = dot.Position + UDim2.fromOffset(rng:NextInteger(-12,12), rng:NextInteger(-9,9)),
            BackgroundTransparency = 0.75
        })
        tw:Play()
    end
    local deco = Instance.new("Frame")
    deco.Name = "ThemeHalloweenDecor"; deco.BackgroundTransparency = 1
    deco.ClipsDescendants = true; deco.Size = UDim2.new(1, 0, 1, 0)
    deco.ZIndex = 29; deco.Parent = TopBar
    local symbols = {"🦇", "🎃", "🦇", "🎃"}
    local rng = Random.new()
    for i, symbol in ipairs(symbols) do
        local item = Instance.new("TextLabel")
        item.Name = "ThemeDecor" .. i; item.BackgroundTransparency = 1
        item.Text = symbol; item.TextSize = (i % 2 == 0) and 17 or 14
        item.TextTransparency = 0.12; item.Size = UDim2.fromOffset(26, 24)
        item.Position = UDim2.new(rng:NextNumber(0.12, 0.88), 0, rng:NextNumber(0.05, 0.65), 0)
        item.Rotation = rng:NextInteger(-15, 15); item.ZIndex = 30; item.Parent = deco
        local drift = UDim2.new(rng:NextNumber(-0.08, 0.08), 0, rng:NextNumber(-0.12, 0.12), 0)
        TweenService:Create(item, TweenInfo.new(rng:NextNumber(2.4, 4.2), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
            Position = item.Position + drift, Rotation = item.Rotation + rng:NextInteger(-18, 18),
            TextTransparency = 0.48
        }):Play()
    end
    if EX.decorate then pcall(EX.decorate, GUI) end
end
-- ===== END THEME ENGINE =====

AddPage("Configurações", function(c1, c2)
    local g1 = CreateGroup(c1, "Universal Settings"); CreateToggle(g1, "Dynamic Island", "set_island", false); CreateToggle(g1, "Watermark HUD", "set_watermark", true); CreateToggle(g1, "Quick Access Keybind", "set_qaccess", false); CreateToggle(g1, "Mobile Toggle Button", "set_mobile", false); CreateKeybind(g1, "Menu Keybind", "misc_menukey", "RightShift", "Toggle")
    local g2 = CreateGroup(c2, "Screen Ambience"); CreateSlider(g2, "Ambience Opacity", "set_opacity", 10, 100, 50); CreateToggle(g2, "Show Only When UI...", "set_showonly", true)
    local g3 = CreateGroup(c2, "Cor do Fundo (RGB)"); CreateSlider(g3, "Fundo - Vermelho", "set_bg_r", 0, 160, 0); CreateSlider(g3, "Fundo - Verde", "set_bg_g", 0, 160, 0); CreateSlider(g3, "Fundo - Azul", "set_bg_b", 0, 160, 0)
    local gAcc = CreateGroup(c2, "Temas Animados"); CreateDropdown(gAcc, "Tema Visual", "set_visual_theme", {"Halloween", "Midnight", "Cyberpunk", "Ocean", "Sakura", "Emerald", "Crimson", "Arctic", "Sunset"}, "Halloween"); CreateDropdown(gAcc, "Cor do Destaque", "set_acc_preset", {"Personalizado", "Vermelho", "Azul", "Roxo", "Verde", "Ciano", "Laranja", "Rosa", "Branco"}, "Personalizado"); CreateSlider(gAcc, "Menu - Vermelho", "set_acc_r", 0, 255, 255); CreateSlider(gAcc, "Menu - Verde", "set_acc_g", 0, 255, 40); CreateSlider(gAcc, "Menu - Azul", "set_acc_b", 0, 255, 60)
    local gHud = CreateGroup(c1, "HUD & Janela")
    CreateSlider(gHud, "Toggle Size", "set_tglsize", 30, 90, 44); CreateSlider(gHud, "Toggle Rounding %", "set_tglround", 0, 100, 100); CreateSlider(gHud, "Toggle Background %", "set_tglbg", 0, 100, 0)
    CreateToggle(gHud, "Toggle Glow", "set_tglglow", true); CreateSlider(gHud, "Glow Intensity", "set_tglglowi", 0, 100, 60); CreateToggle(gHud, "Lock Toggle Position", "set_tgllock", false)
    EX.Btn(gHud, "Reset Toggle Position", nil, function() EX.resetToggle() end)
    local gCfg = CreateGroup(c1, "Configs")
    EX.cfgPick = EX.DynDD(gCfg, "Saved Configs", "cfg_pick", "None")
    EX.TextBox(gCfg, "Config Name", "cfg_name", "my config", "")
    EX.Btn(gCfg, "Save Config", nil, function() EX.cfgSave() end)
    EX.Btn(gCfg, "Load Config", nil, function() EX.cfgLoad() end)
    EX.Btn(gCfg, "Delete Config", nil, function() EX.cfgDelete() end)
    EX.Btn(gCfg, "Refresh Configs", nil, function() EX.cfgRefresh() end)
    EX.Btn(gCfg, "Export Config (copy)", nil, function() EX.cfgExport() end)
    EX.TextBox(gCfg, "Import Code", "cfg_code", "paste here", "")
    EX.Btn(gCfg, "Import Config", nil, function() EX.cfgImport() end)
    local gCom = CreateGroup(c2, "Comunidade & Fechar")
    EX.Btn(gCom, "Join Discord (copy link)", nil, function() EX.copyInvite() end)
    EX.Btn(gCom, "Reset All Settings", nil, function() EX.resetAll() end)
    EX.Btn(gCom, "Close Menu", nil, function() GUI.Enabled = false end)
    EX.Btn(gCom, "Unload Eclypse", nil, function() Confirm.Visible = true end)
    local gMenu = CreateGroup(c2, "Menu & Desempenho")
    CreateToggle(gMenu, "Click Sounds", "set_clicksnd", false); CreateSlider(gMenu, "ESP Rate (FPS)", "set_espfps", 15, 144, 60)
end)
pcall(EX.applyVisualTheme, get("set_visual_theme", "Halloween"))
AddPage("Hitbox", function(c1, c2)
    local g1 = CreateGroup(c1, "Hitbox Expander")
    EX.Info(g1, "How Hitboxes Work", "Turn on Hide Hitbox so big boxes don't block your screen. Higher See-Through fades the box out.")
    CreateToggle(g1, "Hitbox Expander", "hb_on", false); CreateKeybind(g1, "Hitbox Key", "hb_key", "Always", "Always")
    CreateToggle(g1, "Hide Hitbox", "hb_hide", false); CreateSlider(g1, "Hitbox Size", "hb_size", 2, 60, 10); CreateSlider(g1, "Hitbox See-Through", "hb_see", 0, 100, 75)
    CreateDropdown(g1, "Part", "hb_part", {"Root", "Head", "Torso"}, "Root")
    CreateDropdown(g1, "Hitbox Color", "hb_color", {"Accent", "Vermelho", "Azul", "Roxo", "Verde", "Ciano", "Laranja", "Rosa", "Branco"}, "Accent")
    local g2 = CreateGroup(c2, "Targets")
    CreateToggle(g2, "Hitbox Team Check", "hb_team", true); CreateToggle(g2, "Hitbox Skip Friends", "hb_friends", true); CreateToggle(g2, "Expand NPC Hitboxes", "hb_npc", false); CreateSlider(g2, "Min Hitbox Range", "hb_min", 0, 100, 0)
    local g3 = CreateGroup(c2, "Reach")
    CreateToggle(g3, "Sword Reach", "rc_on", false); CreateSlider(g3, "Reach Size", "rc_size", 5, 80, 25)
end)
AddPage("Bots", function(c1, c2)
    local g1 = CreateGroup(c1, "Spawn Bots")
    EX.Info(g1, "Your Bot Squad", "Spawns avatar clones that follow you around. Only you can see them in-game.")
    CreateDropdown(g1, "Avatar", "bot_avatar", {"My Avatar", "Random Player"}, "My Avatar")
    CreateSlider(g1, "How Many Bots", "bot_count", 1, 10, 3)
    EX.Btn(g1, "Spawn Bots", nil, function() EX.botSpawn() end)
    EX.Btn(g1, "Bring Bots to Me", nil, function() EX.botBring() end)
    EX.Btn(g1, "Remove Bots", nil, function() EX.botClear() end)
    local g2 = CreateGroup(c2, "Control Bots")
    CreateDropdown(g2, "Mode", "bot_mode", {"Follow Me", "Orbit Me", "Stay", "Line Up"}, "Follow Me")
    CreateSlider(g2, "Bot Speed", "bot_speed", 8, 60, 16)
    CreateSlider(g2, "Follow Distance", "bot_dist", 3, 30, 6)
    CreateSlider(g2, "Orbit Circle Size", "bot_orbit", 3, 30, 8)
end)
AddPage("Safety", function(c1, c2)
    local g1 = CreateGroup(c1, "Anti-Troll & Defense")
    CreateToggle(g1, "Anti-Fling", "sf_fling", false); CreateToggle(g1, "Anti-Bang", "sf_bang", false); CreateToggle(g1, "Anti-Sit", "sf_sit", false); CreateToggle(g1, "Anti-Ragdoll", "sf_ragdoll", false)
    local g2 = CreateGroup(c2, "Position Guard")
    CreateToggle(g2, "Anti-Teleport", "sf_tp", false); CreateSlider(g2, "Teleport Distance", "sf_tpdist", 20, 500, 80)
    CreateToggle(g2, "Anti-Void", "sf_void", false); CreateSlider(g2, "Void Height", "sf_voidy", -500, 0, -100)
end)
AddNav("Rage"); AddNav("Legit"); AddNav("Hitbox"); AddNav("Misc"); AddNav("Bots"); AddNav("Safety"); AddNav("Inventory Changer"); AddNav("Visuals"); AddNav("World"); AddNav("Configurações"); SwitchPage("Rage")
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
    local _t = os.clock(); if EntCache.t and _t - EntCache.t < 0.033 then return EntCache.list end; EntCache.t = _t
    local list, by = {}, {}
    for _, plr in ipairs(Players:GetPlayers()) do if plr ~= LP and plr.Character then local e = buildEntity(plr.Character, plr); if e then e.enemy = isEnemyPlayer(plr); list[#list + 1] = e; by[e.char] = e end end end
    if NPCInit then for m in pairs(NPCs) do if m.Parent and not Players:GetPlayerFromCharacter(m) then local e = buildEntity(m, nil); if e then e.enemy = npcEnemy(m); e.npc = true; list[#list + 1] = e; by[m] = e end else NPCs[m] = nil end end end
    EntCache.frame = FrameNo; EntCache.list = list; EntCache.byChar = by; return list
end
local Track = {}
EX.trackLast = 0
local function trackEntities() local now, alive = os.clock(), {}; if now - EX.trackLast < 0.033 then return end; EX.trackLast = now; for _, e in ipairs(entities()) do local t = Track[e.char]; if not t then t = {}; Track[e.char] = t end; t[#t + 1] = {now, e.hrp.Position}; while #t > 2 and now - t[1][1] > 0.6 do table.remove(t, 1) end; alive[e.char] = true end; for c in pairs(Track) do if not alive[c] then Track[c] = nil end end end
local function velocityOf(char, windowMs) local t = Track[char]; if not t or #t < 2 then return Vector3.new(0, 0, 0) end; local last = t[#t]; local first = last; for i = #t - 1, 1, -1 do if last[1] - t[i][1] <= windowMs / 1000 then first = t[i] else break end end; local dt = last[1] - first[1]; if dt < 1e-3 then return Vector3.new(0, 0, 0) end; return (last[2] - first[2]) / dt end

local RayP = RaycastParams.new(); RayP.FilterType = Enum.RaycastFilterType.Exclude
local function setFilter(extra) local f = {}; if LP.Character then f[#f + 1] = LP.Character end; if extra then f[#f + 1] = extra end; RayP.FilterDescendantsInstances = f end
local WallP = RaycastParams.new(); WallP.FilterType = Enum.RaycastFilterType.Exclude; WallP.RespectCanCollide = true
EX.visCache = setmetatable({}, {__mode = "k"})
local function lineClear(cam, pos, char)
    local now = os.clock(); local c = char and EX.visCache[char]
    if c and now - c.t < 0.1 then return c.v end
    local f = {}; if LP.Character then f[#f + 1] = LP.Character end; if char then f[#f + 1] = char end; WallP.FilterDescendantsInstances = f
    local v = Workspace:Raycast(cam.CFrame.Position, pos - cam.CFrame.Position, WallP) == nil
    if char then EX.visCache[char] = {t = now, v = v} end
    return v
end
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

function EX.profReport()
    local el = os.clock() - EX.profT; EX.profT = os.clock(); if el < 1 then return end
    local lines = {}
    for name, pf in pairs(EX.prof) do
        local perCall = pf.n > 0 and pf.t / pf.n * 1000 or 0; local perSec = pf.t / el * 1000
        if perCall > 0.5 or perSec > 30 then lines[#lines + 1] = string.format("%s %.2f ms/chamada (%.0f ms/s)", name, perCall, perSec) end
        pf.t, pf.n = 0, 0
    end
    if #lines > 0 then print("[Eclypse perf] ultimos " .. math.floor(el) .. "s: " .. table.concat(lines, " | ")) end
end
-- mira: escolhe o alvo a 30 Hz (raycasts de parede) e so atualiza a posicao nos quadros intermediarios
EX.pickCache = {}
function EX.pickTargetCached(key, o)
    local now = os.clock(); local c = EX.pickCache[key]
    if c and now - c.t < 0.034 then
        local r = c.r
        if r == false then return nil end
        if r.part.Parent and r.ent.hum.Health > 0 then
            local pos = r.part.Position
            if o.predict then pos = pos + velocityOf(r.ent.char, o.sample) * (o.sample / 1000) end
            if o.jitter and o.jitter > 0 then pos = pos + jitterFor(r.ent.char, o.jitter) end
            r.pos = pos
            local cam = Workspace.CurrentCamera
            if cam then local v, on = cam:WorldToViewportPoint(pos); r.onScreen = on; if on then local vs = cam.ViewportSize; r.cursor = (Vector2.new(v.X, v.Y) - Vector2.new(vs.X / 2, vs.Y / 2)).Magnitude end end
            return r
        end
    end
    local r = pickTarget(o); EX.pickCache[key] = {t = now, r = r or false}; return r
end
local function stepAlpha(a60, dt) return 1 - (1 - math.clamp(a60, 0, 1)) ^ (math.clamp(dt, 0, 0.1) * 60) end
local function aimStep(target, alpha, dt)
    local cam = Workspace.CurrentCamera
    if not cam or type(Cap.mousemoverel) ~= "function" then return end
    local v, on = cam:WorldToViewportPoint(target.pos)
    if not on then return end
    local vs = cam.ViewportSize
    local dx = (v.X - vs.X * 0.5) * math.clamp(alpha, 0, 1)
    local dy = (v.Y - vs.Y * 0.5) * math.clamp(alpha, 0, 1)
    local frameScale = math.clamp((dt or 1/60) * 60, 0, 1.5)
    local mag = math.sqrt(dx * dx + dy * dy)
    local maxStep = 10 * frameScale
    if mag > maxStep and mag > 0 then dx, dy = dx / mag * maxStep, dy / mag * maxStep end
    if math.abs(dx) + math.abs(dy) > 0.01 then pcall(Cap.mousemoverel, dx, dy) end
end

local Aim = {char = nil, since = 0}
local function runAimbot(cam, dt)
    if not (get("aim_on") and bindActive("aim_key")) then Aim.char = nil; return end
    local wc, wd, wf = getNum("aim_wc", 40), getNum("aim_wd", 35), getNum("aim_wf", 25); local sum = math.max(wc + wd + wf, 1)
    local t = EX.pickTargetCached("aim", {part = get("aim_part", "Head"), radius = getNum("aim_radius", 120), maxDist = getNum("aim_dist", 450), wall = get("aim_wall", true), peek = get("aim_peek", true), prio = get("aim_prio", "Threat"), wc = wc / sum, wd = wd / sum, wf = wf / sum, offscreen = get("aim_off", true), sticky = get("aim_sticky", true) and Aim.char or nil, predict = get("aim_pred", true), sample = getNum("aim_sample", 90), jitter = get("aim_rand", true) and getNum("aim_offs", 40) / 100 or 0, teamCheck = true})
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
    local t = EX.pickTargetCached("sil", {part = bone, radius = any and math.huge or getNum("sil_fov", 120), maxDist = 2000, wall = get("sil_vis", false), prio = any and "Distance" or "Cursor", wc = 1, wd = 0, wf = 0, offscreen = any, predict = false, sample = 90, jitter = 0, teamCheck = get("sil_team", true)})
    if not t then return end
    -- viewport/inset calculados aqui: dentro do hook nao pode haver chamada com ":" (corromperia o namecall)
    local v = cam:WorldToViewportPoint(t.pos); local ins = GuiService:GetGuiInset()
    Silent.target = {pos = t.pos, char = t.ent.char, vp = (v.Z > 0) and Vector2.new(v.X, v.Y) or nil, inX = ins.X, inY = ins.Y}
    if not Silent.hooked then aimStep(t, stepAlpha(1 / math.max(getNum("sil_smooth", 5), 1), dt)) end
end

local Rage, Kill = {last = 0}, {last = 0}
local function runRage(cam, dt)
    if not (get("rage_on") and bindActive("rage_key")) then return end
    local t = EX.pickTargetCached("rage", {part = "Head", radius = getNum("rage_fovsize", 720), maxDist = 5000, angle = getNum("rage_fov", 120), wall = not get("rage_wall", false), prio = "Cursor", wc = 1, wd = 0, wf = 0, offscreen = true, predict = false, sample = 100, jitter = 0, teamCheck = get("rage_team", true)})
    if not t then return end; aimStep(t, stepAlpha(0.5, dt), dt)
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
    -- Scanner global desativado: varrer/require modulos de todo o jogo causa picos de CPU.
    -- O caminho explicito GameConfig.Weapon permanece disponivel para mapeamento validado.
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

EX.espAcc = 0
local function renderESP(cam, dt)
    EX.espAcc = EX.espAcc + dt; if EX.espAcc < 1 / math.max(getNum("set_espfps", 60), 10) then return end; dt = EX.espAcc; EX.espAcc = 0
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
    Hud.toasts = new("Frame", {AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -14, 1, -14), Size = UDim2.fromOffset(280, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1}, Overlay); new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom}, Hud.toasts); Hud.toastN = 0
    Hud.island = new("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 8), Size = UDim2.fromOffset(150, 28), BackgroundColor3 = Color3.new(0, 0, 0), Visible = false}, Overlay); corner(Hud.island, 14); Hud.islandText = label(Hud.island, {Size = UDim2.fromScale(1, 1), Text = "Eclypse", TextSize = 12, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Center}); Hud.islandBusy = 0
    Hud.mobile = new("TextButton", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.fromOffset(44, 44), BackgroundColor3 = Theme.panel, Text = "D", Font = Enum.Font.GothamBlack, TextSize = 18, TextColor3 = Theme.accent, AutoButtonColor = false, Visible = false}, Overlay); corner(Hud.mobile, 22); outline(Hud.mobile, 2, Theme.accent); Hud.mobile.MouseButton1Click:Connect(function() if EX.tglMoved then return end; GUI.Enabled = not GUI.Enabled end)
    Hud.amb = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.accent, BorderSizePixel = 0, ZIndex = 0, Visible = false}, Overlay); Hud.ambGrad = new("UIGradient", {Rotation = 90}, Hud.amb)
end
function EX.toast(title, sub)
    Hud.toastN = Hud.toastN + 1
    local W, H, life = 280, 54, 3
    local wrap = new("Frame", {Size = UDim2.fromOffset(W, H), BackgroundTransparency = 1, LayoutOrder = Hud.toastN}, Hud.toasts)
    local f = new("Frame", {Size = UDim2.fromOffset(W, H), Position = UDim2.fromOffset(W + 40, 0), BackgroundColor3 = Theme.panel, BackgroundTransparency = 0.05, ClipsDescendants = true}, wrap)
    corner(f, 10); outline(f, 1, Theme.accent)
    new("Frame", {Size = UDim2.fromOffset(3, H - 18), Position = UDim2.fromOffset(8, 9), BackgroundColor3 = Theme.accent, BorderSizePixel = 0}, f)
    label(f, {Size = UDim2.new(1, -60, 0, 18), Position = UDim2.fromOffset(20, 8), Text = tostring(title), TextSize = 13, Font = Enum.Font.GothamBold})
    label(f, {Size = UDim2.new(1, -60, 0, 16), Position = UDim2.fromOffset(20, 27), Text = tostring(sub or ""), TextSize = 11, TextColor3 = Theme.sub, TextTruncate = Enum.TextTruncate.AtEnd})
    local x = new("TextButton", {Size = UDim2.fromOffset(22, 22), Position = UDim2.new(1, -30, 0, 6), BackgroundTransparency = 1, Text = "x", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Theme.sub, AutoButtonColor = false}, f)
    local bar = new("Frame", {Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, -2), BackgroundColor3 = Theme.accent, BorderSizePixel = 0}, f)
    TweenService:Create(f, TweenInfo.new(0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(0, 0)}):Play()
    TweenService:Create(bar, TweenInfo.new(life, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 2)}):Play()
    local gone = false
    local function dismiss()
        if gone then return end; gone = true
        local t1 = TweenService:Create(f, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = UDim2.fromOffset(W + 40, 0)})
        t1:Play()
        t1.Completed:Connect(function()
            local t2 = TweenService:Create(wrap, TweenInfo.new(0.15), {Size = UDim2.fromOffset(W, 0)})
            t2:Play(); t2.Completed:Connect(function() wrap:Destroy() end)
        end)
    end
    x.MouseButton1Click:Connect(dismiss)
    x.MouseEnter:Connect(function() x.TextColor3 = Theme.accent end)
    x.MouseLeave:Connect(function() x.TextColor3 = Theme.sub end)
    task.delay(life, dismiss)
end
notify = function(title, sub)
    if get("set_island") then
        local text = title .. (sub and (": " .. sub) or ""); Hud.islandText.Text = text; local w = TextService:GetTextSize(text, 12, Enum.Font.GothamBold, Vector2.new(600, 30)).X + 30; tween(Hud.island, {Size = UDim2.fromOffset(math.max(w, 150), 28)}); Hud.islandBusy = os.clock() + 2; Hud.lastIsl = nil
    else
        EX.toast(title, sub)
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
    if HB.slow >= 0.5 then HB.slow = 0; local want = get("misc_spect") or get("misc_antispect"); if want and os.clock() - (HB.specAt or 0) > 1.5 then HB.specAt = os.clock(); HB.specs = currentSpectators() end; local specs = want and (HB.specs or {}) or {}; if get("misc_spect") and #specs > 0 then Hud.spec.Text = "Spectators\n" .. table.concat(specs, "\n"); Hud.spec.Visible = true else Hud.spec.Visible = false end; local pause = get("misc_antispect") and #specs > 0; if pause ~= HB.paused then HB.paused = pause; notify("Anti Spectate", pause and "features paused" or "features resumed") end end
    if HB.hud >= 0.2 then HB.hud = 0; EX.timed("updateHud", updateHud, fpsAvg) end
end

local function makeCircle() local f = new("Frame", {Size = UDim2.fromOffset(100, 100), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Visible = false}, Overlay); new("UICorner", {CornerRadius = UDim.new(1, 0)}, f); new("UIStroke", {Thickness = 1, Color = Theme.accent}, f); return f end
local fovCircle, aimCircle = makeCircle(), makeCircle()
local silMark = new("Frame", {Size = UDim2.fromOffset(10, 10), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Theme.accent, Visible = false}, Overlay); corner(silMark, 5)
local function updateCircles(cam) local vs = cam.ViewportSize; local c = UDim2.fromOffset(vs.X / 2, vs.Y / 2); local show = get("sil_fovcircle"); local sOn = show and get("sil_on") and not get("sil_any"); fovCircle.Visible = sOn and true or false; if sOn then local d = getNum("sil_fov", 120) * 2; fovCircle.Position = c; fovCircle.Size = UDim2.fromOffset(d, d) end; local aOn = show and get("aim_on"); aimCircle.Visible = aOn and true or false; if aOn then local d = getNum("aim_radius", 120) * 2; aimCircle.Position = c; aimCircle.Size = UDim2.fromOffset(d, d) end; if get("sil_show") and Silent.target then local v, on = cam:WorldToViewportPoint(Silent.target.pos); silMark.Visible = on; if on then silMark.Position = UDim2.fromOffset(v.X, v.Y) end else silMark.Visible = false end end

currentSpectators = function() local probe, out = GameConfig.SpectateProbe or function(plr) local function refs(v) return v == LP or v == LP.Character or v == LP.Name or v == LP.DisplayName or v == LP.UserId end; for k, v in pairs(plr:GetAttributes()) do if tostring(k):lower():find("spect") and refs(v) then return true end end; for _, d in ipairs(plr:GetDescendants()) do if (d:IsA("ObjectValue") or d:IsA("StringValue") or d:IsA("IntValue")) and d.Name:lower():find("spect") and refs(d.Value) then return true end end; return false end, {}; for _, plr in ipairs(Players:GetPlayers()) do if plr ~= LP then local ok, r = pcall(probe, plr); if ok and r then out[#out + 1] = plr.Name end end end; return out end

-- ===== V30: configs, botao flutuante, hitbox, reach, bots, safety =====
do
    local HttpService = game:GetService("HttpService")
    local function safe(name, fn, ...)
        local ok, err = pcall(fn, ...)
        if not ok and not Warned[name] then Warned[name] = true; warn("[Eclypse] " .. name .. ": " .. tostring(err)) end
    end
    EX.Defaults = {}
    for k, v in pairs(Prefs) do EX.Defaults[k] = (type(v) == "table") and {Key = v.Key, Mode = v.Mode} or v end

    -- ---------- configs ----------
    local CFG_DIR = "Eclypse/configs"
    local hasFS = type(writefile) == "function" and type(readfile) == "function" and type(listfiles) == "function" and type(isfolder) == "function" and type(makefolder) == "function"
    local MemCfg = shared.EclypseCfgMem or {}; shared.EclypseCfgMem = MemCfg
    local MODES = {Always = true, Hold = true, Toggle = true}
    local function cfgClean(n) local s = tostring(n or ""):gsub("[^%w%-%_ ]", ""); s = s:gsub("^%s+", ""):gsub("%s+$", ""); return s end
    local function cfgSnapshot()
        local out = {}
        for k, v in pairs(Prefs) do
            if type(k) == "string" and k:sub(1, 4) ~= "cfg_" then
                local t = type(v)
                if t == "boolean" or t == "number" or t == "string" then out[k] = v
                elseif t == "table" and v.Key ~= nil then out[k] = {Key = tostring(v.Key), Mode = tostring(v.Mode)} end
            end
        end
        return out
    end
    local function cfgApply(tbl)
        local n = 0
        for k, v in pairs(tbl) do
            local cur = Prefs[k]
            if type(k) == "string" and k:sub(1, 4) ~= "cfg_" and cur ~= nil and type(v) == type(cur) then
                if type(v) == "table" then
                    if type(v.Key) == "string" and MODES[v.Mode] then Prefs[k] = {Key = v.Key, Mode = v.Mode}; n = n + 1 end
                elseif type(v) == "number" then
                    if v == v then Prefs[k] = v; n = n + 1 end
                else Prefs[k] = v; n = n + 1 end
            end
        end
        for _, fn in pairs(EX.Refresh) do pcall(fn) end
        pcall(EX.applyBackground); pcall(EX.applyAccent); pcall(EX.styleToggle)
        return n
    end
    local function cfgNames()
        local names = {}
        if hasFS then
            pcall(function() if not isfolder("Eclypse") then makefolder("Eclypse") end; if not isfolder(CFG_DIR) then makefolder(CFG_DIR) end end)
            local ok, files = pcall(listfiles, CFG_DIR)
            if ok and type(files) == "table" then for _, f in ipairs(files) do local n = tostring(f):match("([^/\\]+)%.json$"); if n then names[#names + 1] = n end end end
        else for n in pairs(MemCfg) do names[#names + 1] = n end end
        table.sort(names); return names
    end
    function EX.cfgRefresh() if EX.cfgPick then EX.cfgPick.setOptions(cfgNames()) end end
    function EX.cfgSave()
        local name = cfgClean(get("cfg_name", "")); if name == "" then name = cfgClean(get("cfg_pick", "")) end
        if name == "" then notify("Config", "type a name first"); return end
        local json = HttpService:JSONEncode(cfgSnapshot())
        if hasFS then
            local ok = pcall(function() if not isfolder("Eclypse") then makefolder("Eclypse") end; if not isfolder(CFG_DIR) then makefolder(CFG_DIR) end; writefile(CFG_DIR .. "/" .. name .. ".json", json) end)
            if not ok then notify("Config", "could not write file"); return end
        else MemCfg[name] = json end
        EX.cfgRefresh(); Prefs.cfg_pick = name; if EX.Refresh.cfg_pick then EX.Refresh.cfg_pick() end
        notify("Config", "saved: " .. name)
    end
    function EX.cfgLoad()
        local name = cfgClean(get("cfg_pick", "")); if name == "" then notify("Config", "pick a config first"); return end
        local json
        if hasFS then local ok, res = pcall(readfile, CFG_DIR .. "/" .. name .. ".json"); if ok then json = res end else json = MemCfg[name] end
        if not json then notify("Config", "not found"); return end
        local ok, tbl = pcall(function() return HttpService:JSONDecode(json) end)
        if not ok or type(tbl) ~= "table" then notify("Config", "invalid file"); return end
        notify("Config", "loaded " .. name .. " (" .. tostring(cfgApply(tbl)) .. " options)")
    end
    function EX.cfgDelete()
        local name = cfgClean(get("cfg_pick", "")); if name == "" then notify("Config", "pick a config first"); return end
        if hasFS then pcall(function() delfile(CFG_DIR .. "/" .. name .. ".json") end) else MemCfg[name] = nil end
        Prefs.cfg_pick = ""; EX.cfgRefresh(); if EX.Refresh.cfg_pick then EX.Refresh.cfg_pick() end
        notify("Config", "deleted: " .. name)
    end
    function EX.cfgExport()
        local json = HttpService:JSONEncode(cfgSnapshot())
        local ok = pcall(function() setclipboard(json) end)
        if ok then notify("Config", "copied to clipboard") else Prefs.cfg_code = json; if EX.Refresh.cfg_code then EX.Refresh.cfg_code() end; notify("Config", "code placed in Import Code box") end
    end
    function EX.cfgImport()
        local code = tostring(get("cfg_code", "")); if code == "" then notify("Config", "paste a code first"); return end
        local ok, tbl = pcall(function() return HttpService:JSONDecode(code) end)
        if not ok or type(tbl) ~= "table" then notify("Config", "invalid code"); return end
        notify("Config", "imported (" .. tostring(cfgApply(tbl)) .. " options)")
    end
    function EX.resetAll()
        for k, v in pairs(EX.Defaults) do if type(v) == "table" then Prefs[k] = {Key = v.Key, Mode = v.Mode} else Prefs[k] = v end end
        for _, fn in pairs(EX.Refresh) do pcall(fn) end
        pcall(EX.applyBackground); pcall(EX.applyAccent); pcall(EX.styleToggle)
        notify("Settings", "reset to defaults")
    end
    function EX.copyInvite() local B = EX.Brand; local ok = pcall(function() setclipboard(B.invite) end); notify("Discord", ok and "invite copied" or B.invite) end
    EX.cfgRefresh()

    -- ---------- botao flutuante do menu ----------
    function EX.styleToggle()
        local m = Hud.mobile; if not m then return end
        local s = getNum("set_tglsize", 44); m.Size = UDim2.fromOffset(s, s)
        local cr = m:FindFirstChildOfClass("UICorner"); if cr then cr.CornerRadius = UDim.new(0, s * math.clamp(getNum("set_tglround", 100), 0, 100) / 200) end
        m.BackgroundTransparency = math.clamp(getNum("set_tglbg", 0), 0, 100) / 100
        local st = m:FindFirstChildOfClass("UIStroke"); if st then st.Thickness = get("set_tglglow", true) and (2 + 4 * getNum("set_tglglowi", 60) / 100) or 2 end
    end
    function EX.resetToggle() Hud.mobile.Position = UDim2.new(0, 10, 0.5, 0) end
    do
        local m = Hud.mobile
        local okLogo = false
        if EX.asset or EX.editable then
            okLogo = pcall(function()
                m.Text = ""
                local box = EX.makeLogo(m, 30, {ZIndex = 2})
                box.AnchorPoint = Vector2.new(0.5, 0.5); box.Position = UDim2.fromScale(0.5, 0.5); box.Size = UDim2.fromScale(0.78, 0.78)
            end)
        end
        if not okLogo then m.Text = "E" end
        local dragging, ds, sp = false, nil, nil
        m.InputBegan:Connect(function(i)
            if (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
                EX.tglMoved = false
                if not get("set_tgllock") then dragging = true; ds = i.Position; sp = m.Position end
            end
        end)
        Conns[#Conns + 1] = UserInputService.InputChanged:Connect(function(i)
            if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                local d = i.Position - ds
                if d.Magnitude > 5 then EX.tglMoved = true end
                if EX.tglMoved then m.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y) end
            end
        end)
        Conns[#Conns + 1] = UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
        end)
    end
    EX.styleToggle()

    -- som de clique (o ID do som pode ser trocado em EX.ClickSoundId)
    EX.ClickSoundId = "rbxassetid://6895079853"
    local clickSnd
    Conns[#Conns + 1] = UserInputService.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 and GUI.Enabled and get("set_clicksnd") then
            if not clickSnd then clickSnd = Instance.new("Sound"); clickSnd.SoundId = EX.ClickSoundId; clickSnd.Volume = 0.35; clickSnd.Parent = Overlay end
            clickSnd:Play()
        end
    end)

    -- ---------- hitbox ----------
    local HB2 = {orig = setmetatable({}, {__mode = "k"}), friends = {}, reach = nil}
    function HB2.isFriend(plr)
        local c = HB2.friends[plr.UserId]
        if c == nil then
            HB2.friends[plr.UserId] = false
            task.spawn(function() local ok, r = pcall(function() return LP:IsFriendsWith(plr.UserId) end); if ok then HB2.friends[plr.UserId] = r and true or false end end)
            return false
        end
        return c
    end
    local function hbPart(char)
        local w = get("hb_part", "Root")
        if w == "Head" then return char:FindFirstChild("Head") elseif w == "Torso" then return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") end
        return char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
    end
    local function hbRestore(part)
        local o = HB2.orig[part]; if not o then return end; HB2.orig[part] = nil
        if part.Parent then pcall(function() part.Size = o.size; part.Transparency = o.tr; part.CanCollide = o.cc; part.Massless = o.ms; part.Color = o.col; part.Material = o.mat end) end
    end
    local function hbTick()
        local on = get("hb_on") and bindActive("hb_key")
        if not on and next(HB2.orig) == nil then return end
        local want = {}
        if on then
            if get("hb_npc") then initNPCs() end
            local myhrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            local size = getNum("hb_size", 10); local tsize = Vector3.new(size, size, size)
            local ttr = get("hb_hide") and 1 or (getNum("hb_see", 75) / 100)
            local minR = getNum("hb_min", 0); local col = EX.AccentPresets[get("hb_color", "Accent")] or Theme.accent
            for _, ent in ipairs(entities()) do
                local ok = true
                if ent.npc then ok = get("hb_npc") and true or false end
                if ok and ent.plr then
                    if get("hb_team", true) and not ent.enemy then ok = false end
                    if ok and get("hb_friends", true) and HB2.isFriend(ent.plr) then ok = false end
                end
                if ok and minR > 0 and myhrp and (ent.hrp.Position - myhrp.Position).Magnitude < minR then ok = false end
                if ok then
                    local p = hbPart(ent.char)
                    if p and p:IsA("BasePart") then
                        want[p] = true
                        if not HB2.orig[p] then HB2.orig[p] = {size = p.Size, tr = p.Transparency, cc = p.CanCollide, ms = p.Massless, col = p.Color, mat = p.Material} end
                        if p.Size ~= tsize then p.Size = tsize end
                        if p.Transparency ~= ttr then p.Transparency = ttr end
                        if p.CanCollide then p.CanCollide = false end
                        if not p.Massless then p.Massless = true end
                        if p.Color ~= col then p.Color = col end
                        if p.Material ~= Enum.Material.Neon then p.Material = Enum.Material.Neon end
                    end
                end
            end
        end
        for p in pairs(HB2.orig) do if not want[p] then hbRestore(p) end end
    end
    local function reachRestore()
        local r = HB2.reach; HB2.reach = nil
        if r and r.part.Parent then pcall(function() r.part.Size = r.size; r.part.Massless = r.ms; r.part.CanCollide = r.cc end) end
    end
    local function reachTick()
        local on = get("rc_on")
        if not on and not HB2.reach then return end
        local char = LP.Character; local tool = char and char:FindFirstChildOfClass("Tool"); local h = tool and tool:FindFirstChild("Handle")
        if HB2.reach and (not on or HB2.reach.part ~= h) then reachRestore() end
        if on and h and h:IsA("BasePart") then
            if not HB2.reach then HB2.reach = {part = h, size = h.Size, ms = h.Massless, cc = h.CanCollide} end
            local s = getNum("rc_size", 25); local t = Vector3.new(s, s, s)
            if h.Size ~= t then h.Size = t end
            if not h.Massless then h.Massless = true end
            if h.CanCollide then h.CanCollide = false end
        end
    end

    -- ---------- bots (clones locais, so voce ve) ----------
    local Bots = {list = {}}
    local ANIM = {R15 = {idle = "rbxassetid://507766666", walk = "rbxassetid://507777826"}, R6 = {idle = "rbxassetid://180435571", walk = "rbxassetid://180426354"}}
    function EX.botClear()
        for _, b in ipairs(Bots.list) do pcall(function() b.model:Destroy() end) end
        Bots.list = {}
    end
    local function botSource()
        if get("bot_avatar", "My Avatar") == "Random Player" then
            local c = {}
            for _, p in ipairs(Players:GetPlayers()) do if p ~= LP and p.Character and p.Character:FindFirstChildOfClass("Humanoid") then c[#c + 1] = p.Character end end
            if #c > 0 then return c[math.random(#c)] end
        end
        return LP.Character
    end
    function EX.botSpawn()
        local me = LP.Character; local hrp = me and me:FindFirstChild("HumanoidRootPart")
        if not hrp then notify("Bots", "no character yet"); return end
        local n = math.clamp(getNum("bot_count", 3), 1, 10)
        if #Bots.list + n > 25 then n = 25 - #Bots.list end
        if n <= 0 then notify("Bots", "limit of 25 reached"); return end
        local spawned = 0
        for i = 1, n do
            local src = botSource()
            if src then
                local was = src.Archivable; src.Archivable = true
                local ok, clone = pcall(function() return src:Clone() end)
                src.Archivable = was
                if ok and clone then
                    for _, d in ipairs(clone:GetDescendants()) do
                        if d:IsA("LuaSourceContainer") then d:Destroy() elseif d:IsA("BasePart") then d.CanCollide = false end
                    end
                    local hum = clone:FindFirstChildOfClass("Humanoid"); local chrp = clone:FindFirstChild("HumanoidRootPart")
                    if hum and chrp then
                        local idx = #Bots.list + 1
                        clone.Name = "EclypseBot" .. idx; hum.DisplayName = "Bot " .. idx; hum.WalkSpeed = getNum("bot_speed", 16)
                        clone.Parent = Workspace
                        clone:PivotTo(hrp.CFrame * CFrame.new((i - (n + 1) / 2) * 3, 0, 4))
                        local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
                        local ids = ANIM[hum.RigType == Enum.HumanoidRigType.R15 and "R15" or "R6"]
                        local tracks = {}
                        for nm, id in pairs(ids) do
                            local a = Instance.new("Animation"); a.AnimationId = id
                            local okT, tr = pcall(function() return animator:LoadAnimation(a) end)
                            if okT and tr then tracks[nm] = tr end
                        end
                        if tracks.idle then tracks.idle.Looped = true; tracks.idle:Play() end
                        Bots.list[idx] = {model = clone, hum = hum, hrp = chrp, tracks = tracks, moving = false}
                        spawned = spawned + 1
                    else clone:Destroy() end
                end
            end
        end
        notify("Bots", "Spawned " .. spawned .. " bots")
    end
    function EX.botBring()
        local me = LP.Character; local hrp = me and me:FindFirstChild("HumanoidRootPart"); if not hrp then return end
        local n = #Bots.list
        for i, b in ipairs(Bots.list) do if b.model.Parent then b.model:PivotTo(hrp.CFrame * CFrame.new((i - (n + 1) / 2) * 3, 0, 4)) end end
        if n > 0 then notify("Bots", "brought " .. n .. " bots") end
    end
    local function botsTick()
        local me = LP.Character; local hrp = me and me:FindFirstChild("HumanoidRootPart"); if not hrp then return end
        local mode = get("bot_mode", "Follow Me"); local spd = getNum("bot_speed", 16); local dist = getNum("bot_dist", 6); local orb = getNum("bot_orbit", 8)
        local n, t = #Bots.list, os.clock()
        for i = n, 1, -1 do
            local b = Bots.list[i]
            if not b.model.Parent or not b.hrp.Parent then table.remove(Bots.list, i)
            else
                b.hum.WalkSpeed = spd
                local target
                if mode == "Follow Me" then local a = (i / n) * math.pi * 2; target = hrp.Position + Vector3.new(math.cos(a), 0, math.sin(a)) * dist
                elseif mode == "Orbit Me" then local a = t * 0.9 + (i / n) * math.pi * 2; target = hrp.Position + Vector3.new(math.cos(a), 0, math.sin(a)) * orb
                elseif mode == "Line Up" then target = (hrp.CFrame * CFrame.new((i - (n + 1) / 2) * 3.5, 0, dist)).Position end
                if (b.hrp.Position - hrp.Position).Magnitude > 120 then b.model:PivotTo(hrp.CFrame * CFrame.new(0, 0, 5)) end
                local moving = false
                if target then
                    local flat = (target - b.hrp.Position) * Vector3.new(1, 0, 1)
                    if flat.Magnitude > 2 then b.hum:MoveTo(target); moving = true end
                end
                if b.tracks.walk then
                    if moving and not b.moving then b.tracks.walk:Play(0.15) elseif (not moving) and b.moving then b.tracks.walk:Stop(0.15) end
                end
                b.moving = moving
            end
        end
    end

    -- ---------- safety ----------
    local SF = {char = nil, last = nil, spawnT = 0, safe = nil, bangT = 0, dirty = false, n = 0, nT = 0}
    local function sfAny() return get("sf_fling") or get("sf_bang") or get("sf_sit") or get("sf_ragdoll") or get("sf_tp") or get("sf_void") end
    local function sfNotify(msg) if os.clock() - SF.nT > 2 then SF.nT = os.clock(); notify("Safety", msg) end end
    local function safety10()
        local any = sfAny()
        if not any and not SF.dirty then return end
        local char = LP.Character; local hum = char and char:FindFirstChildOfClass("Humanoid"); local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not (hum and hrp) then return end
        if SF.char ~= char then SF.char = char; SF.last = nil; SF.safe = nil; SF.spawnT = os.clock() end
        pcall(function()
            hum:SetStateEnabled(Enum.HumanoidStateType.Seated, not get("sf_sit"))
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, not get("sf_ragdoll"))
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, not get("sf_ragdoll"))
        end)
        if not any then SF.dirty = false; return end
        SF.dirty = true
        if hum.Health <= 0 then return end
        local now, pos = os.clock(), hrp.Position
        if get("sf_sit") and hum.Sit then hum.Sit = false end
        if get("sf_ragdoll") then
            local st = hum:GetState()
            if st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.FallingDown then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
            if hum.PlatformStand then hum.PlatformStand = false end
        end
        if get("sf_fling") then
            SF.n = SF.n + 1
            if SF.n % 3 == 0 then
                for _, plr in ipairs(Players:GetPlayers()) do
                    local c = plr ~= LP and plr.Character
                    if c then for _, p in ipairs(c:GetChildren()) do if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end end end
                end
            end
        end
        if get("sf_tp") and SF.last and now - SF.spawnT > 1.5 and (pos - SF.last).Magnitude > getNum("sf_tpdist", 80) then
            hrp.CFrame = CFrame.new(SF.last) * (hrp.CFrame - hrp.CFrame.Position); hrp.AssemblyLinearVelocity = Vector3.zero
            pos = SF.last; sfNotify("teleport blocked")
        end
        SF.last = pos
        local voidY = getNum("sf_voidy", -100)
        if hum.FloorMaterial ~= Enum.Material.Air and pos.Y > voidY + 20 then SF.safe = pos end
        if get("sf_void") and SF.safe and pos.Y < voidY then
            hrp.CFrame = CFrame.new(SF.safe + Vector3.new(0, 4, 0)); hrp.AssemblyLinearVelocity = Vector3.zero; sfNotify("saved from the void")
        end
        if get("sf_bang") then
            local near
            for _, plr in ipairs(Players:GetPlayers()) do
                local c = plr ~= LP and plr.Character; local r = c and c:FindFirstChild("HumanoidRootPart")
                if r and (r.Position - pos).Magnitude < 2.6 then near = r; break end
            end
            if near then
                SF.bangT = SF.bangT + 0.1
                if SF.bangT >= 0.8 then
                    SF.bangT = 0
                    local away = (pos - near.Position) * Vector3.new(1, 0, 1)
                    away = away.Magnitude > 0.1 and away.Unit or Vector3.new(0, 0, -1)
                    hrp.CFrame = hrp.CFrame + away * 25; sfNotify("moved away from a player")
                end
            else SF.bangT = 0 end
        end
    end
    local function flingTick()
        if not get("sf_fling") then return end
        local char = LP.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
        local v = hrp.AssemblyLinearVelocity; local hv = Vector3.new(v.X, 0, v.Z)
        local thr = 140
        if get("mv_fly") then thr = thr + getNum("mv_flyspeed", 60) * 1.2 end
        if get("mv_speed") or get("misc_bhop") then thr = thr + 80 end
        if hv.Magnitude > thr then hrp.AssemblyLinearVelocity = Vector3.new(0, v.Y, 0) end
        if hrp.AssemblyAngularVelocity.Magnitude > 60 then hrp.AssemblyAngularVelocity = Vector3.zero end
    end

    -- ---------- loop unico dos modulos novos ----------
    local acc10, acc20 = 0, 0
    Conns[#Conns + 1] = RunService.Heartbeat:Connect(function(dt)
        acc10 = acc10 + dt; acc20 = acc20 + dt
        if acc10 >= 0.1 then acc10 = 0; safe("hitbox", hbTick); safe("reach", reachTick); safe("safety", safety10) end
        if acc20 >= 0.05 then acc20 = 0; if #Bots.list > 0 then safe("bots", botsTick) end end
        if get("sf_fling") then safe("antifling", flingTick) end
    end)

    function EX.featureCleanup()
        for p in pairs(HB2.orig) do hbRestore(p) end
        reachRestore(); EX.botClear()
        local char = LP.Character; local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true); hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true); hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true) end) end
    end
end

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
RunService:BindToRenderStep("DrxMain", Enum.RenderPriority.Camera.Value + 1, function(dt) FrameNo = FrameNo + 1; fpsAvg = fpsAvg + (1 / math.max(dt, 1e-4) - fpsAvg) * 0.05; gPoll(); local cam = Workspace.CurrentCamera; if not cam then return end; if get("aim_on") or get("sil_on") or get("rage_on") or get("trg_on") then gNPC() end; if get("aim_on") or get("sil_on") or get("rage_on") or get("trg_on") or get("ra_kill") or get("esp_path") then gTrack() end; gCircles(cam); if HB.paused or not aimAllowed() then Silent.target = nil; Silent.shooting = false else gAim(cam, dt); gSilent(cam, dt); gRage(cam, dt); gKill(cam, dt); gTrig(cam, dt) end; gESP(cam, dt); gRapid(); if os.clock() - EX.profT > 15 then EX.profReport() end end)
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
    if cleaned then return end; cleaned = true; if shared.DrxCleanup == cleanup then shared.DrxCleanup = nil end; Booted = false; if EX.destroyLoading then pcall(EX.destroyLoading) end; Silent.alive = false; Silent.target = nil; MouseDeltaHook.alive = false; pcall(function() RunService:UnbindFromRenderStep("DrxMain") end); for _, c in ipairs(Conns) do pcall(function() c:Disconnect() end) end; UiMouse.setOpen(false); UiMouse.alive = false; stopFly(); restoreWeapon(); pcall(EX.featureCleanup); for k, e in pairs(ESP) do destroyESP(e); ESP[k] = nil end; if HB.tp then pcall(function() LP.CameraMaxZoomDistance = 128; LP.CameraMinZoomDistance = 0.5 end) end; Overlay:Destroy(); if GUI.Parent then GUI:Destroy() end
end
shared.DrxCleanup = cleanup
doUnload = cleanup
GUI.Destroying:Connect(cleanup)
UiMouse.setOpen(GUI.Enabled)
Booted = true
print("[Eclypse V30] pronto | silent-hook=" .. (SilentHooks.done and tostring(Silent.hooked) or "instala ao ligar o Silent") .. " | Build=" .. GameConfig.Build)
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
                                                                                                                                                                         
