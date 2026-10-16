--[[
    Dungdx Grand Piano 3D — Premium responsive UI (mobile + PC)
    DUNGDX GRAND PIANO BUILD: a larger black-lacquer 3D case, raised brass-trimmed
    controls, crisp ivory/ebony keys, a draggable master-volume slider, and five
    independent playback-speed presets. The visible keyboard spans A0-B6 (75 keys) with horizontal scrolling.
    Features:
      - Draggable piano window with tap-to-play keys
      - Manual keyboard input (PC)
      - Typed note sequences, chord playback, and sequence editor
      - Record manually played notes with timing, then play/replay the take
      - Play / pause / stop, tempo, loop playback, master-volume slider, and speed presets
      - Sustain, sostenuto, and soft pedals; dynamics levels; semitone transposition; room reverb
      - Metronome and multi-key keyboard input
      - Separate buttons to hide controls, hide the entire piano, restore it, and close it
      - Classic lacquer-and-ivory instrument styling with a horizontally scrollable keyboard

    AUDIO SETUP:
    Keeps the 37 original Roblox audio asset IDs supplied by the user for C3-C6.
    The visible keyboard spans A0-B6 (75 keys). The original sample bank is C3-C6;
    notes outside that range use a pitch-shifted sample approximation, not authentic
    per-note recordings. C7-C8 are omitted because they were sounding too similar. Roblox asset permissions still depend on the target experience.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
if not player then
    warn("[VirtualPiano] Initialization stopped: Players.LocalPlayer is unavailable.")
    return
end

local playerGui = player:WaitForChild("PlayerGui", 10)
if not playerGui then
    warn("[VirtualPiano] Initialization stopped: PlayerGui was not available after 10 seconds.")
    return
end

local GUI_NAME = "DungdxVirtualPiano"

-- Tear down old instances wherever previous executor builds may have parented them.
-- Delta scripts sometimes parent UIs to PlayerGui, CoreGui, or gethui(); checking only
-- PlayerGui can leave a second oversized frame visible behind the current instrument.
local cleanupRoots = {}
local seenCleanupRoots = {}
local function addCleanupRoot(root)
    if root and not seenCleanupRoots[root] then
        seenCleanupRoots[root] = true
        table.insert(cleanupRoots, root)
    end
end
addCleanupRoot(playerGui)
pcall(function() addCleanupRoot(game:GetService("CoreGui")) end)
if type(gethui) == "function" then
    local ok, hiddenUi = pcall(gethui)
    if ok then addCleanupRoot(hiddenUi) end
end

local function looksLikeOldPiano(candidate)
    if not candidate:IsA("ScreenGui") then return false end
    local lowerName = string.lower(candidate.Name)
    if string.find(lowerName, "piano", 1, true)
        or string.find(lowerName, "dungdxvirtual", 1, true) then
        return true
    end
    local keySignature = 0
    for _, descendant in ipairs(candidate:GetDescendants()) do
        if descendant.Name == "FullRange37KeyCanvas"
            or descendant.Name == "RGBNeonKeyboardDeck"
            or descendant.Name == "PianoCaseShadow"
            or descendant.Name == "VirtualPianoMain"
            or descendant.Name == "VirtualPianoWindow" then
            return true
        end
        -- Older variants used different frame names but kept pitch-named buttons.
        if descendant.Name == "C3" or descendant.Name == "C4"
            or descendant.Name == "C5" or descendant.Name == "C6" then
            keySignature += 1
        end
    end
    return keySignature >= 3
end

for _, root in ipairs(cleanupRoots) do
    local ok, children = pcall(function() return root:GetChildren() end)
    if ok then
        for _, candidate in ipairs(children) do
            if candidate:IsA("ScreenGui") then
                local shouldRemove = candidate.Name == GUI_NAME
                if not shouldRemove then
                    local checkOk, result = pcall(looksLikeOldPiano, candidate)
                    shouldRemove = checkOk and result == true
                end
                if shouldRemove then
                    pcall(function() candidate:Destroy() end)
                end
            end
        end
    end
end
for _, child in ipairs(SoundService:GetChildren()) do
    if child:IsA("Sound") and (child.Name:match("^PianoSample_%d+_%d+$") or child.Name:match("^DungdxVP_PianoSample_%d+_%d+$") or child.Name == "DungdxVP_MetronomeClick") then
        pcall(function()
            child:Stop()
            child:Destroy()
        end)
    end
end

-- Individual note assets supplied by the user. Index 0 = C3 and index 36 = C6.
-- IDs are kept exactly as provided; an available exact sample plays at normal pitch.
local NOTE_AUDIO_IDS = {
    [0] = "rbxassetid://153723146",   -- C3
    [1] = "rbxassetid://153723157",   -- C#3
    [2] = "rbxassetid://153723173",   -- D3
    [3] = "rbxassetid://153723190",   -- D#3
    [4] = "rbxassetid://153723204",   -- E3
    [5] = "rbxassetid://153723219",   -- F3
    [6] = "rbxassetid://153723237",   -- F#3
    [7] = "rbxassetid://153723253",   -- G3
    [8] = "rbxassetid://153723267",   -- G#3
    [9] = "rbxassetid://153723284",   -- A3
    [10] = "rbxassetid://153723300",  -- A#3
    [11] = "rbxassetid://153723312",  -- B3
    [12] = "rbxassetid://584691395",  -- C4
    [13] = "rbxassetid://153723326",  -- C#4
    [14] = "rbxassetid://153723340",  -- D4
    [15] = "rbxassetid://153723353",  -- D#4
    [16] = "rbxassetid://153723363",  -- E4
    [17] = "rbxassetid://153723377",  -- F4
    [18] = "rbxassetid://153723388",  -- F#4
    [19] = "rbxassetid://153723403",  -- G4
    [20] = "rbxassetid://153723417",  -- G#4
    [21] = "rbxassetid://153723428",  -- A4
    [22] = "rbxassetid://153723444",  -- A#4
    [23] = "rbxassetid://153723456",  -- B4
    [24] = "rbxassetid://153723471",  -- C5
    [25] = "rbxassetid://153723485",  -- C#5
    [26] = "rbxassetid://153723497",  -- D5
    [27] = "rbxassetid://153723512",  -- D#5
    [28] = "rbxassetid://153723525",  -- E5
    [29] = "rbxassetid://153723544",  -- F5
    [30] = "rbxassetid://153723562",  -- F#5
    [31] = "rbxassetid://153723578",  -- G5
    [32] = "rbxassetid://153723592",  -- G#5
    [33] = "rbxassetid://153723605",  -- A5
    [34] = "rbxassetid://153723617",  -- A#5
    [35] = "rbxassetid://153723631",  -- B5
    [36] = "rbxassetid://153723647",  -- C6
}

local COLORS = {
    -- Classic piano palette: lacquer black, warm ivory, ebony and muted brass.
    bg = Color3.fromRGB(8, 9, 10),
    panel = Color3.fromRGB(18, 18, 18),
    panel2 = Color3.fromRGB(35, 32, 28),
    accent = Color3.fromRGB(177, 137, 73),
    accent2 = Color3.fromRGB(232, 218, 188),
    text = Color3.fromRGB(246, 244, 237),
    muted = Color3.fromRGB(166, 160, 147),
    blackKey = Color3.fromRGB(12, 12, 13),
    whiteKey = Color3.fromRGB(252, 251, 248),
    whiteKeyText = Color3.fromRGB(74, 72, 66),
    red = Color3.fromRGB(153, 58, 48),
    green = Color3.fromRGB(104, 132, 91),
    cyan = Color3.fromRGB(218, 184, 113), -- retained identifier; now the brass highlight color
    steel = Color3.fromRGB(88, 77, 61),
    deep = Color3.fromRGB(5, 5, 5),
}

local gui = Instance.new("ScreenGui")
gui.Name = GUI_NAME
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

-- Connections tied to global services must be disconnected when this GUI closes
-- or is replaced by another execution.
local lifetimeConnections = {}
local function trackLifetimeConnection(connection)
    table.insert(lifetimeConnections, connection)
    return connection
end

local function corner(parent, radius)
    local ok, result = pcall(function()
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, radius or 10)
        c.Parent = parent
        return c
    end)
    if not ok then warn("[VirtualPiano] Optional corner styling skipped: " .. tostring(result)) end
    return ok and result or nil
end

local function stroke(parent, color, thickness, transparency)
    local ok, result = pcall(function()
        local s = Instance.new("UIStroke")
        s.Color = color or COLORS.accent
        s.Thickness = thickness or 1
        s.Transparency = transparency or 0
        s.Parent = parent
        return s
    end)
    if not ok then warn("[VirtualPiano] Optional border styling skipped: " .. tostring(result)) end
    return ok and result or nil
end

-- Animated RGB trim: a rainbow gradient rotates continuously around UIStroke
-- outlines. Tweens are tracked and stopped during cleanup.
local rgbBorderTweens = {}
local RGB_SEQUENCE = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 45, 95)),
    ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 142, 50)),
    ColorSequenceKeypoint.new(0.32, Color3.fromRGB(240, 255, 65)),
    ColorSequenceKeypoint.new(0.48, Color3.fromRGB(45, 255, 145)),
    ColorSequenceKeypoint.new(0.64, Color3.fromRGB(40, 220, 255)),
    ColorSequenceKeypoint.new(0.80, Color3.fromRGB(105, 90, 255)),
    ColorSequenceKeypoint.new(0.92, Color3.fromRGB(235, 65, 255)),
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 45, 95)),
})

local function rainbowStroke(parent, thickness, transparency, duration, startRotation)
    local uiStroke = stroke(parent, Color3.new(1, 1, 1), thickness or 2, transparency or 0)
    if not uiStroke then return nil end
    local ok, gradient = pcall(function()
        local g = Instance.new("UIGradient")
        g.Name = "AnimatedRGBGradient"
        g.Color = RGB_SEQUENCE
        g.Rotation = startRotation or 0
        g.Parent = uiStroke
        return g
    end)
    if not ok or not gradient then
        uiStroke.Color = COLORS.accent2
        return uiStroke
    end

    local fromRotation = startRotation or 0
    local tween = TweenService:Create(
        gradient,
        TweenInfo.new(duration or 4, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false),
        { Rotation = fromRotation + 360 }
    )
    table.insert(rgbBorderTweens, tween)
    tween:Play()
    return uiStroke
end

local function addGradient(parent, colors, rotation, label)
    local ok, result = pcall(function()
        local gradient = Instance.new("UIGradient")
        gradient.Color = colors
        gradient.Rotation = rotation or 90
        gradient.Parent = parent
        return gradient
    end)
    if not ok then warn("[VirtualPiano] Optional gradient skipped (" .. tostring(label) .. "): " .. tostring(result)) end
    return ok and result or nil
end

local function makeLabel(parent, text, size, pos, font, textSize, color)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = text
    l.Size = size
    l.Position = pos
    l.Font = font or Enum.Font.Gotham
    l.TextSize = textSize or 14
    l:SetAttribute("PianoBaseTextSize", l.TextSize)
    l.TextColor3 = color or COLORS.text
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.Parent = parent
    return l
end

local PianoUI = { buttonBaseColors = {}, buttonLayouts = {}, buttonShadows = {} }
PianoUI.mobilePortraitLayout = false

function PianoUI.setButtonBaseColor(button, color)
    PianoUI.buttonBaseColors[button] = color
    button.BackgroundColor3 = color
end

local function makeButton(parent, text, size, pos, bg, fg, textSize)
    local b = Instance.new("TextButton")
    b.Size = size
    b.Position = pos
    b.BackgroundColor3 = bg or COLORS.panel2
    b.TextColor3 = fg or COLORS.text
    b.TextTransparency = 0
    b.TextStrokeColor3 = Color3.fromRGB(3, 3, 4)
    b.TextStrokeTransparency = 0.72 -- subtle dark edge keeps small labels crisp
    b.Text = text
    b.Font = Enum.Font.GothamBold
    b.TextSize = math.max(textSize or 13, 10) -- baseline; PianoUI.fitToScreen compensates on compact layouts
    b:SetAttribute("PianoBaseTextSize", b.TextSize)
    b.TextWrapped = false
    b.AutoButtonColor = false
    b.Active = true
    b.Selectable = true
    b.ZIndex = (parent and parent:IsA("GuiObject") and parent.ZIndex or 1) + 2
    b.BorderSizePixel = 0
    b.ClipsDescendants = true
    b.Parent = parent
    corner(b, 8)
    b.BackgroundTransparency = 0
    local baseColor = b.BackgroundColor3
    PianoUI.buttonBaseColors[b] = baseColor

    -- Offset shadow + thin upper glint make each control look like a raised keycap.
    local depthShadow = Instance.new("Frame")
    depthShadow.Name = "ButtonDepthShadow"
    depthShadow.Size = size
    depthShadow.Position = UDim2.new(pos.X.Scale, pos.X.Offset, pos.Y.Scale, pos.Y.Offset + 2)
    depthShadow.BackgroundColor3 = Color3.fromRGB(3, 3, 4)
    depthShadow.BackgroundTransparency = 0.24
    depthShadow.BorderSizePixel = 0
    depthShadow.ZIndex = math.max(1, b.ZIndex - 1)
    depthShadow.Active = false
    depthShadow.Parent = parent
    corner(depthShadow, 8)
    depthShadow:SetAttribute("PianoDecorative", true)
    local layoutRecord = { position = pos, size = size, defaultPosition = pos, defaultSize = size }
    PianoUI.buttonLayouts[b] = layoutRecord
    PianoUI.buttonShadows[b] = depthShadow

    local topGlint = Instance.new("Frame")
    topGlint.Name = "ButtonTopGlint"
    topGlint.Position = UDim2.new(0, 5, 0, 3)
    topGlint.Size = UDim2.new(1, -10, 0, 2)
    topGlint.BackgroundColor3 = Color3.fromRGB(255, 239, 199)
    topGlint.BackgroundTransparency = 0.84
    topGlint.BorderSizePixel = 0
    topGlint.ZIndex = b.ZIndex + 1
    topGlint.Active = false
    topGlint.Parent = b
    corner(topGlint, 2)

    stroke(b, baseColor:Lerp(COLORS.cyan, 0.34), 0.9, 0.24)
    -- Do not apply UIGradient to the whole button: it muddies text contrast.
    local activeTween
    local function moveButton(offset, color, duration)
        if activeTween then pcall(function() activeTween:Cancel() end) end
        local originalPosition = layoutRecord.position
        activeTween = TweenService:Create(b, TweenInfo.new(duration or 0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(originalPosition.X.Scale, originalPosition.X.Offset, originalPosition.Y.Scale, originalPosition.Y.Offset + offset),
            BackgroundColor3 = color,
        })
        layoutRecord.activeTween = activeTween
        activeTween:Play()
    end
    b.MouseEnter:Connect(function()
        local currentBase = PianoUI.buttonBaseColors[b] or baseColor
        moveButton(0, currentBase:Lerp(COLORS.cyan, 0.045), 0.10)
    end)
    b.MouseLeave:Connect(function()
        moveButton(0, PianoUI.buttonBaseColors[b] or baseColor, 0.10)
    end)
    b.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local currentBase = PianoUI.buttonBaseColors[b] or baseColor
            moveButton(1, currentBase:Lerp(COLORS.cyan, 0.09), 0.045)
        end
    end)
    b.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            moveButton(0, PianoUI.buttonBaseColors[b] or baseColor, 0.09)
        end
    end)
    return b
end

-- Relayout a button and its decorative shadow together. This is used by the mobile
-- portrait layout so reflow never leaves orphaned shadows behind other controls.
PianoUI.setButtonLayout = function(button, position, size)
    if not button or not button.Parent then return end
    local layout = PianoUI.buttonLayouts[button]
    if layout and layout.activeTween then
        pcall(function() layout.activeTween:Cancel() end)
        layout.activeTween = nil
    end
    button.Position = position
    button.Size = size
    if layout then
        layout.position = position
        layout.size = size
    end
    local shadow = PianoUI.buttonShadows[button]
    if shadow and shadow.Parent then
        shadow.Position = UDim2.new(position.X.Scale, position.X.Offset, position.Y.Scale, position.Y.Offset + 2)
        shadow.Size = size
    end
end

PianoUI.restoreButtonLayouts = function()
    for button, layout in pairs(PianoUI.buttonLayouts) do
        if button and button.Parent and layout then
            PianoUI.setButtonLayout(button, layout.defaultPosition, layout.defaultSize)
        end
    end
end

-- Deep cast shadow makes the instrument read as a physical floating case.
local mainShadow = Instance.new("Frame")
mainShadow.Name = "PianoCaseShadow"
mainShadow.Visible = true -- a soft offset shadow grounds the case against the game world
mainShadow.Size = UDim2.new(0, 798, 0, 438)
mainShadow.AnchorPoint = Vector2.new(0.5, 0.5)
mainShadow.Position = UDim2.new(0.5, -4, 0.5, 9)
mainShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
mainShadow.BackgroundTransparency = 0.24
mainShadow.BorderSizePixel = 0
mainShadow.ZIndex = 1
mainShadow.Parent = gui
corner(mainShadow, 17)
local shadowRim = stroke(mainShadow, Color3.fromRGB(111, 82, 43), 1.5, 0.66)

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, 790, 0, 430)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Position = UDim2.new(0.5, 0, 0.5, 0)
main.BackgroundColor3 = COLORS.bg
main.BorderSizePixel = 0
main.Parent = gui
main.Visible = true
corner(main, 20)
stroke(main, Color3.fromRGB(139, 105, 55), 1.5, 0.08)
addGradient(main, ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(34, 27, 21)),
    ColorSequenceKeypoint.new(0.48, Color3.fromRGB(10, 10, 10)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(27, 20, 14)),
}), 90, "classic lacquer piano body")

-- Nested metal bevels: layered outlines catch light without using image assets.
local outerBezel = Instance.new("Frame")
outerBezel.Name = "OuterBezel"
outerBezel.Position = UDim2.new(0, 3, 0, 3)
outerBezel.Size = UDim2.new(1, -6, 1, -6)
outerBezel.BackgroundTransparency = 1
outerBezel.BorderSizePixel = 0
outerBezel.ZIndex = 1
outerBezel.Parent = main
corner(outerBezel, 17)
stroke(outerBezel, Color3.fromRGB(111, 86, 48), 1.0, 0.30)

local lowerBevel = Instance.new("Frame")
lowerBevel.Name = "LowerBevel"
lowerBevel.AnchorPoint = Vector2.new(0, 1)
lowerBevel.Position = UDim2.new(0, 13, 1, -4)
lowerBevel.Size = UDim2.new(1, -26, 0, 2)
lowerBevel.BackgroundColor3 = COLORS.cyan
lowerBevel.BackgroundTransparency = 0.78
lowerBevel.BorderSizePixel = 0
lowerBevel.ZIndex = 1
lowerBevel.Active = false
lowerBevel.Parent = main
corner(lowerBevel, 1)

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MinSize = Vector2.new(280, 320)
sizeConstraint.MaxSize = Vector2.new(4096, 2160)
sizeConstraint.Parent = main

local scale = Instance.new("UIScale")
scale.Scale = 1
scale.Parent = main
local shadowScale = Instance.new("UIScale")
shadowScale.Scale = scale.Scale
shadowScale.Parent = mainShadow
trackLifetimeConnection(main:GetPropertyChangedSignal("Position"):Connect(function()
    mainShadow.Position = UDim2.new(
        main.Position.X.Scale, main.Position.X.Offset - 4,
        main.Position.Y.Scale, main.Position.Y.Offset + 9
    )
end))

-- Drag window by its header. Touch and mouse are supported.
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 50)
header.BackgroundColor3 = COLORS.panel
header.BorderSizePixel = 0
header.Parent = main
corner(header, 18)

local headerCover = Instance.new("Frame")
headerCover.Size = UDim2.new(1, 0, 0, 14)
headerCover.Position = UDim2.new(0, 0, 1, -14)
headerCover.BackgroundColor3 = COLORS.panel
headerCover.BorderSizePixel = 0
headerCover.Parent = header

local headerSeparator = Instance.new("Frame")
headerSeparator.Name = "GoldSeparator"
headerSeparator.Position = UDim2.new(0, 12, 0, 50)
headerSeparator.Size = UDim2.new(1, -24, 0, 1)
headerSeparator.BackgroundColor3 = COLORS.accent
headerSeparator.BackgroundTransparency = 0.48
headerSeparator.BorderSizePixel = 0
headerSeparator.Parent = main

local headerGlow = Instance.new("Frame")
headerGlow.Name = "HeaderLightEdge"
headerGlow.Position = UDim2.new(0, 12, 0, 51)
headerGlow.Size = UDim2.new(0.34, 0, 0, 1)
headerGlow.BackgroundColor3 = COLORS.cyan
headerGlow.BackgroundTransparency = 0.40
headerGlow.BorderSizePixel = 0
headerGlow.Active = false
headerGlow.Parent = main

local title = makeLabel(header, "♬  Dungdx", UDim2.new(0, 142, 1, 0), UDim2.new(0, 15, 0, 0), Enum.Font.GothamBlack, 17, COLORS.accent2)
title.Name = "DungdxBrandTitle"
local subtitle = makeLabel(header, "GRAND PIANO  •  75 KEYS  •  A0–B6", UDim2.new(0, 400, 1, 0), UDim2.new(0, 162, 0, 0), Enum.Font.GothamSemibold, 10, COLORS.text)
subtitle.Name = "PianoModelSubtitle"
subtitle.TextXAlignment = Enum.TextXAlignment.Left

-- Small live meter gives playback a subtle instrument-console feel.
local spectrumBars = {}
for i = 1, 6 do
    local bar = Instance.new("Frame")
    bar.Name = "LiveMeter" .. tostring(i)
    bar.AnchorPoint = Vector2.new(0, 1)
    bar.Position = UDim2.new(0.70, (i - 1) * 7, 0.5, 7)
    bar.Size = UDim2.new(0, 3, 0, 3)
    bar.BackgroundColor3 = COLORS.cyan
    bar.BackgroundTransparency = 0.55
    bar.BorderSizePixel = 0
    bar.Active = false
    bar.Visible = false -- uncluttered branding area; playback state remains in the status line
    bar.ZIndex = 2
    bar.Parent = header
    corner(bar, 2)
    table.insert(spectrumBars, bar)
end
local spectrumToken = 0
local function pulseSpectrum(semi)
    -- The meter is intentionally hidden in this layout. Skip its animation work
    -- entirely rather than allocating tweens for invisible objects on every note.
    if #spectrumBars == 0 or not spectrumBars[1].Visible then return end
    spectrumToken += 1
    local myToken = spectrumToken
    for i, bar in ipairs(spectrumBars) do
        local height = 4 + ((math.abs(semi or 0) * (i + 1) + i * 5) % 12)
        TweenService:Create(bar, TweenInfo.new(0.055, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 3, 0, height),
            BackgroundTransparency = 0.12,
        }):Play()
    end
    task.delay(0.16, function()
        if myToken ~= spectrumToken or not gui.Parent then return end
        for _, bar in ipairs(spectrumBars) do
            TweenService:Create(bar, TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 3, 0, 3),
                BackgroundTransparency = 0.55,
            }):Play()
        end
    end)
end

local minimize = makeButton(header, "ẨN NÚT", UDim2.new(0, 70, 0, 28), UDim2.new(1, -198, 0, 7), Color3.fromRGB(63, 49, 32), Color3.fromRGB(246,241,229), 10)
local hidePianoBtn = makeButton(header, "ẨN ĐÀN", UDim2.new(0, 76, 0, 28), UDim2.new(1, -120, 0, 7), Color3.fromRGB(113, 82, 39), Color3.fromRGB(255,248,229), 10)
local close = makeButton(header, "×", UDim2.new(0, 29, 0, 28), UDim2.new(1, -35, 0, 7), COLORS.red, Color3.new(1,1,1), 17)

-- Floating restore control lives outside Main, so it remains clickable when the
-- entire piano window is hidden. This is different from the ẨN NÚT control.
local restorePianoBtn = makeButton(gui, "🎹  MỞ ĐÀN PIANO", UDim2.new(0, 176, 0, 42), UDim2.new(0.5, -88, 1, -58), Color3.fromRGB(91, 66, 34), Color3.fromRGB(255,248,229), 12)
restorePianoBtn.Name = "RestoreVirtualPianoButton"
restorePianoBtn.AnchorPoint = Vector2.new(0, 0)
restorePianoBtn.Visible = false
restorePianoBtn.ZIndex = 200
restorePianoBtn.Position = UDim2.new(0.5, -88, 1, -58)


PianoUI.dragging, PianoUI.dragStart, PianoUI.startPos = false, nil, nil
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        PianoUI.dragging = true
        PianoUI.dragStart = input.Position
        PianoUI.startPos = main.Position
        local endConnection
        endConnection = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                PianoUI.dragging = false
                if endConnection then endConnection:Disconnect() end
            end
        end)
    end
end)
trackLifetimeConnection(UserInputService.InputChanged:Connect(function(input)
    if PianoUI.dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - PianoUI.dragStart
        local screenSize = gui.AbsoluteSize
        local windowSize = main.AbsoluteSize
        if screenSize.X > 0 and screenSize.Y > 0 then
            local centerX = PianoUI.startPos.X.Scale * screenSize.X + PianoUI.startPos.X.Offset + delta.X
            local centerY = PianoUI.startPos.Y.Scale * screenSize.Y + PianoUI.startPos.Y.Offset + delta.Y
            local halfW = math.min(windowSize.X * 0.5, screenSize.X * 0.5)
            local halfH = math.min(windowSize.Y * 0.5, screenSize.Y * 0.5)
            centerX = math.clamp(centerX, halfW, screenSize.X - halfW)
            centerY = math.clamp(centerY, halfH, screenSize.Y - halfH)
            main.Position = UDim2.new(0, centerX, 0, centerY)
        end
    end
end))

local content = Instance.new("Frame")
content.BackgroundTransparency = 1
content.Position = UDim2.new(0, 14, 0, 58)
content.Size = UDim2.new(1, -28, 1, -72)
content.Parent = main

local status = makeLabel(content, "SẴN SÀNG  •  75 PHÍM  •  CHẠM ĐỂ ĐÀN", UDim2.new(0, 350, 0, 23), UDim2.new(0, 0, 0, 0), Enum.Font.GothamSemibold, 11, COLORS.text)
status.TextWrapped = false
pcall(function() status.TextTruncate = Enum.TextTruncate.AtEnd end)
local volumeLabel = makeLabel(content, "ÂM LƯỢNG 70%", UDim2.new(0, 105, 0, 23), UDim2.new(1, -246, 0, 0), Enum.Font.GothamBold, 11, COLORS.accent2)
volumeLabel.TextXAlignment = Enum.TextXAlignment.Right

PianoUI.volumeSliderTrack = Instance.new("Frame")
PianoUI.volumeSliderTrack.Name = "MasterVolumeSliderTrack"
PianoUI.volumeSliderTrack.Position = UDim2.new(1, -136, 0, 9)
PianoUI.volumeSliderTrack.Size = UDim2.new(0, 120, 0, 6)
PianoUI.volumeSliderTrack.BackgroundColor3 = Color3.fromRGB(57, 50, 39)
PianoUI.volumeSliderTrack.BorderSizePixel = 0
PianoUI.volumeSliderTrack.ZIndex = 20
PianoUI.volumeSliderTrack.Active = true
PianoUI.volumeSliderTrack.Parent = content
corner(PianoUI.volumeSliderTrack, 4)
stroke(PianoUI.volumeSliderTrack, Color3.fromRGB(112, 86, 48), 1, 0.1)
PianoUI.volumeSliderFill = Instance.new("Frame")
PianoUI.volumeSliderFill.Name = "VolumeLevelFill"
PianoUI.volumeSliderFill.Size = UDim2.new(0.7, 0, 1, 0)
PianoUI.volumeSliderFill.BackgroundColor3 = Color3.fromRGB(235, 190, 107)
PianoUI.volumeSliderFill.BorderSizePixel = 0
PianoUI.volumeSliderFill.ZIndex = 21
PianoUI.volumeSliderFill.Active = false
PianoUI.volumeSliderFill.Parent = PianoUI.volumeSliderTrack
corner(PianoUI.volumeSliderFill, 4)
PianoUI.volumeSliderKnob = Instance.new("Frame")
PianoUI.volumeSliderKnob.Name = "VolumeSliderKnob"
PianoUI.volumeSliderKnob.AnchorPoint = Vector2.new(0.5, 0.5)
PianoUI.volumeSliderKnob.Position = UDim2.new(0.7, -2.8, 0.5, 0)
PianoUI.volumeSliderKnob.Size = UDim2.new(0, 14, 0, 14)
PianoUI.volumeSliderKnob.BackgroundColor3 = Color3.fromRGB(255, 226, 164)
PianoUI.volumeSliderKnob.BorderSizePixel = 0
PianoUI.volumeSliderKnob.ZIndex = 22
PianoUI.volumeSliderKnob.Active = true
PianoUI.volumeSliderKnob.Parent = PianoUI.volumeSliderTrack
corner(PianoUI.volumeSliderKnob, 8)
stroke(PianoUI.volumeSliderKnob, Color3.fromRGB(132, 91, 38), 1.2, 0)

-- Two persistent navigation tabs: Classic piano and playable mini-games.
local classicTab = makeButton(content, "CỔ ĐIỂN", UDim2.new(0, 62, 0, 22), UDim2.new(0.385, 0, 0, 0), COLORS.accent, Color3.new(1, 1, 1), 9)
local gamesTab = makeButton(content, "TRÒ CHƠI", UDim2.new(0, 76, 0, 22), UDim2.new(0.50, 0, 0, 0), COLORS.panel2, COLORS.text, 9)
-- Keep navigation above decorative frames so touch taps reliably reach it.
classicTab.ZIndex = 50
gamesTab.ZIndex = 50
classicTab.Active = false
classicTab.Visible = false
gamesTab.Active = false
gamesTab.Visible = false

local controls = Instance.new("Frame")
controls.BackgroundTransparency = 1
controls.Position = UDim2.new(0, 0, 0, 26)
controls.Size = UDim2.new(1, 0, 0, 34)
controls.Parent = content

local playBtn = makeButton(controls, "▶ PHÁT", UDim2.new(0, 72, 1, 0), UDim2.new(0, 0, 0, 0), Color3.fromRGB(157, 106, 34), Color3.fromRGB(255,248,229), 11)
local pauseBtn = makeButton(controls, "Ⅱ TẠM DỪNG", UDim2.new(0, 91, 1, 0), UDim2.new(0, 77, 0, 0), Color3.fromRGB(52, 43, 31), Color3.fromRGB(246,241,229), 11)
local stopBtn = makeButton(controls, "■ DỪNG", UDim2.new(0, 69, 1, 0), UDim2.new(0, 172, 0, 0), Color3.fromRGB(86, 42, 34), Color3.fromRGB(255,248,229), 11)
local recordBtn = makeButton(controls, "● THU", UDim2.new(0, 66, 1, 0), UDim2.new(0, 245, 0, 0), Color3.fromRGB(112, 40, 42), Color3.fromRGB(255, 231, 218), 11)
local replayBtn = makeButton(controls, "↻ PHÁT LẠI", UDim2.new(0, 91, 1, 0), UDim2.new(0, 315, 0, 0), Color3.fromRGB(39, 75, 54), Color3.fromRGB(237, 255, 239), 11)
local speedLabel = makeLabel(controls, "TỐC ĐỘ", UDim2.new(0, 48, 1, 0), UDim2.new(0, 410, 0, 0), Enum.Font.GothamBold, 10, COLORS.accent2)
speedLabel.TextXAlignment = Enum.TextXAlignment.Center
PianoUI.SPEED_OPTIONS = {0.5, 0.75, 1.0, 1.25, 1.5}
PianoUI.SPEED_LABELS = {"0.5×", "0.75×", "1.0×", "1.25×", "1.5×"}
PianoUI.speedBtn = makeButton(controls, PianoUI.SPEED_LABELS[1], UDim2.new(0, 54, 1, 0), UDim2.new(0, 464, 0, 0), COLORS.panel2, COLORS.text, 10)
PianoUI.speedBtn.Name = "SpeedOption_1"
PianoUI.speedButtons = {PianoUI.speedBtn}
for speedIndex, speedText in ipairs(PianoUI.SPEED_LABELS) do
    if speedIndex > 1 then
        local button = makeButton(controls, speedText, UDim2.new(0, 54, 1, 0), UDim2.new(0, 464 + (speedIndex - 1) * 55, 0, 0), COLORS.panel2, COLORS.text, 10)
        button.Name = "SpeedOption_" .. tostring(speedIndex)
        table.insert(PianoUI.speedButtons, button)
    end
end

local keyboardDeck = Instance.new("Frame")
keyboardDeck.Name = "RGBNeonKeyboardDeck"
keyboardDeck.Position = UDim2.new(0, -2, 1, -208)
keyboardDeck.Size = UDim2.new(1, 4, 0, 205)
keyboardDeck.BackgroundColor3 = Color3.fromRGB(32, 24, 17)
keyboardDeck.BorderSizePixel = 0
keyboardDeck.ZIndex = 1
keyboardDeck.Parent = content
corner(keyboardDeck, 7)
stroke(keyboardDeck, Color3.fromRGB(139, 105, 55), 1.5, 0.12)
addGradient(keyboardDeck, ColorSequence.new(Color3.fromRGB(55, 39, 26), Color3.fromRGB(15, 12, 10)), 90, "polished dark-wood keybed")

local keyboardFrame = Instance.new("Frame")
keyboardFrame.Name = "Keyboard"
keyboardFrame.Position = UDim2.new(0, 0, 1, -204)
keyboardFrame.Size = UDim2.new(1, 0, 0, 201)
keyboardFrame.BackgroundColor3 = Color3.fromRGB(25, 19, 14)
keyboardFrame.BorderSizePixel = 0
keyboardFrame.ClipsDescendants = true
keyboardFrame.Parent = content
corner(keyboardFrame, 5)
stroke(keyboardFrame, Color3.fromRGB(98, 74, 43), 1.0, 0.12)
addGradient(keyboardFrame, ColorSequence.new(Color3.fromRGB(35, 26, 19), Color3.fromRGB(12, 10, 9)), 90, "ebony keyboard surround")

local keyArea = Instance.new("ScrollingFrame")
keyArea.Name = "Range75KeyCanvas"
keyArea.BackgroundTransparency = 1
keyArea.BorderSizePixel = 0
keyArea.Position = UDim2.new(0, 5, 0, 4)
keyArea.Size = UDim2.new(1, -10, 1, -8)
keyArea.CanvasSize = UDim2.new(0, 1056, 0, 0) -- recalculated below after note count is known
keyArea.ScrollBarThickness = 3
keyArea.ScrollBarImageColor3 = Color3.fromRGB(164, 127, 70)
keyArea.ScrollBarImageTransparency = 0.20
keyArea.ScrollingDirection = Enum.ScrollingDirection.X
keyArea.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
keyArea.Active = true
keyArea.ClipsDescendants = true
keyArea.Parent = keyboardFrame

local SOLFEGE_NAMES = {
    [0] = "Đô", [1] = "Đô#", [2] = "Rê", [3] = "Rê#",
    [4] = "Mi", [5] = "Fa", [6] = "Fa#", [7] = "Sol",
    [8] = "Sol#", [9] = "La", [10] = "La#", [11] = "Si",
}
local SOLFEGE_ASCII = {
    [0] = "DO", [1] = "DO#", [2] = "RE", [3] = "RE#",
    [4] = "MI", [5] = "FA", [6] = "FA#", [7] = "SOL",
    [8] = "SOL#", [9] = "LA", [10] = "LA#", [11] = "SI",
}
local CHROMATIC_NAMES = {
    "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"
}
local PC_KEYS = {
    ["C4"] = "A", ["D4"] = "S", ["E4"] = "D", ["F4"] = "F",
    ["G4"] = "G", ["A4"] = "H", ["B4"] = "J", ["C5"] = "K",
    ["D5"] = "L", ["E5"] = ";", ["F5"] = "'",
}
local function displayNoteName(note)
    -- Show standard international pitch names in the UI: C4, C#4, D4, etc.
    return note.pitchName .. tostring(note.octave)
end

-- Build A0 through B6 (75 keys). C7-C8 are omitted because the available sample
-- bank made the upper range sound too similar for this build.
local notes = {}
PianoUI.notesBySemi = {}
for semi = -27, 47 do
    local pitchClass = ((semi % 12) + 12) % 12
    local octave = 3 + math.floor(semi / 12)
    local pitchName = CHROMATIC_NAMES[pitchClass + 1]
    local name = pitchName .. tostring(octave)
    local note = {
        name = name,
        semi = semi,
        pitchClass = pitchClass,
        pitchName = pitchName,
        octave = octave,
        key = PC_KEYS[name] or "",
        black = (pitchClass == 1 or pitchClass == 3 or pitchClass == 6 or pitchClass == 8 or pitchClass == 10),
    }
    table.insert(notes, note)
    PianoUI.notesBySemi[semi] = note
end
for _, n in ipairs(notes) do
    n.displayName = displayNoteName(n)
end

local whiteNotes = {}
for _, n in ipairs(notes) do
    if not n.black then table.insert(whiteNotes, n) end
end

local sounds = {} -- All active audio voices; used for volume updates and cleanup.
local whiteButtons, blackButtons = {}, {}
local keyBaseColors, keyPulseTokens, keyVisuals = {}, {}, {}
local shuttingDown = false
local volume = 0.7
local baseSpeed = 1.0
local sustainEnabled = false
PianoUI.sostenutoEnabled = false
PianoUI.roomEnabled = true
local softEnabled = false
local transposeSemitones = 0
local tempoBpm = 100
local loopPlayback = false
local metronomeEnabled = false
local dynamicsOptions = {
    {label = "Rất nhẹ", multiplier = 0.30},
    {label = "Nhẹ", multiplier = 0.50},
    {label = "Vừa", multiplier = 0.72},
    {label = "Mạnh", multiplier = 1.00},
}
local dynamicsIndex = 3
local playing = false
local paused = false
local sequenceToken = 0
local currentPlaybackMode = nil
local autoSequence = "C4 D4 E4 C4 C4 D4 E4 C4 E4 F4 G4 E4 F4 G4"
local autoBox

-- A bounded recording take stores each manually played note and its relative time.
-- Play uses the just-recorded take after Stop; editing the note setting switches
-- Play back to the explicitly typed sequence. TAKE can replay the saved take again.
local MAX_RECORD_NOTES = 500
local MAX_RECORDED_GAP = 30
local isRecording = false
local recordStartedAt = 0
local recordBuffer = {}
local recordedTake = {}
local preferRecordedTake = false
local finishRecording
local activeInputVoices = {}
local activeKeyboardVoices = {}
local sustainedVoices = {}
PianoUI.sostenutoVoices = {}
local voiceReleaseTokens = {}
local voiceState = {
    fadeTweens = {},
    velocities = {},
    startedAt = {},
    semitones = {}, -- Actual target pitch for note-dependent release decay.
    recordedEvents = {},
    heldKeyCounts = {},
    manualHeld = {}, -- physically-held manual keys that may need a sustain loop
    pendingRequests = {}, -- manual presses waiting briefly for a sample to load
}
local metronomeToken = 0
local metronomeLoopGeneration = 0

local function effectiveVoiceVolume(velocityOverride, semitoneOverride)
    local dynamics = velocityOverride or dynamicsOptions[dynamicsIndex].multiplier
    local pitch = tonumber(semitoneOverride)
    local bassCompensation = 1
    if pitch then
        -- Low register needs a modest gain lift because the supplied samples have
        -- lower perceived loudness. C4 and above keep the original gain.
        local lowRegister = math.clamp((12 - pitch) / 39, 0, 1)
        bassCompensation = 1 + (2.0 * lowRegister)
    end
    return math.clamp(volume * dynamics * (softEnabled and 0.58 or 1) * bassCompensation, 0, 3.0)
end

-- Four alternating voices per source pitch improve repeated notes and chord polyphony.
local SAMPLE_VOICES = 4
local samplePools = {}
local sampleReady = {}
local preloadDeadlineReached = false
local preloadFinished = false
local voiceCursor = {}

PianoUI.soundGroup = Instance.new("SoundGroup")
PianoUI.soundGroup.Name = "DungdxGrandPianoSoundGroup"
PianoUI.soundGroup.Volume = 1
PianoUI.soundGroup.Parent = SoundService
PianoUI.roomReverb = Instance.new("ReverbSoundEffect")
PianoUI.roomReverb.Name = "PianoRoomAmbience"
PianoUI.roomReverb.DecayTime = 1.45
PianoUI.roomReverb.Density = 0.62
PianoUI.roomReverb.Diffusion = 0.68
PianoUI.roomReverb.DryLevel = 0
PianoUI.roomReverb.WetLevel = -15
PianoUI.roomReverb.Enabled = PianoUI.roomEnabled
PianoUI.roomReverb.Parent = PianoUI.soundGroup

for semi, soundId in pairs(NOTE_AUDIO_IDS) do
    local pool = {}
    samplePools[semi] = pool
    voiceCursor[semi] = 0
    for i = 1, SAMPLE_VOICES do
        local snd = Instance.new("Sound")
        snd.Name = "DungdxVP_PianoSample_" .. tostring(semi) .. "_" .. tostring(i)
        snd.SoundId = soundId
        snd.Volume = volume
        snd.PlaybackSpeed = 1
        snd.Parent = SoundService
        snd.SoundGroup = PianoUI.soundGroup
        -- Let the source play its natural attack/decay once. If the player is still
        -- holding the key when that sample ends, loop a later region (when Roblox
        -- playback-region support is available) rather than repeating the attack.
        snd.Ended:Connect(function()
            -- Also keep a short release tail alive while its volume tween is fading.
            -- This avoids ending a short sample before its release envelope can be heard.
            local physicallyHeld = voiceState.manualHeld[snd] == true
            local isReleasing = voiceState.fadeTweens[snd] ~= nil
            if shuttingDown or (not physicallyHeld and not isReleasing) or not snd.Parent or not snd.IsLoaded then
                return
            end
            local length = tonumber(snd.TimeLength) or 0
            if length < 0.22 then return end
            local loopStart = math.clamp(length * 0.18, 0.08, 0.32)
            local loopEnd = length - math.max(0.03, length * 0.04)
            if loopEnd - loopStart < 0.10 then return end
            local ok = pcall(function()
                snd.PlaybackRegion = NumberRange.new(loopStart, loopEnd)
                snd.PlaybackRegionsEnabled = true
                snd.Looped = true
                snd.TimePosition = loopStart
                snd:Play()
            end)
            if not ok then
                -- If loop regions are unavailable in this client, keep the sample
                -- one-shot rather than repeating its attack in a visibly artificial way.
                pcall(function()
                    snd.Looped = false
                    snd.PlaybackRegionsEnabled = false
                end)
            end
        end)
        table.insert(pool, snd)
        table.insert(sounds, snd)
    end
end

local metronomeSound = Instance.new("Sound")
metronomeSound.Name = "DungdxVP_MetronomeClick"
metronomeSound.SoundId = NOTE_AUDIO_IDS[36]
metronomeSound.Volume = volume * 0.22
metronomeSound.PlaybackSpeed = 3.0
metronomeSound.Parent = SoundService
table.insert(sounds, metronomeSound)

local function flashKey(noteName, semi)
    local visual = keyVisuals[noteName]
    local key = visual and visual.button or whiteButtons[noteName] or blackButtons[noteName]
    if not key or not key.Parent then return end

    keyPulseTokens[noteName] = (keyPulseTokens[noteName] or 0) + 1
    local token = keyPulseTokens[noteName]
    if visual then
        if visual.pressTween then pcall(function() visual.pressTween:Cancel() end) end
        if visual.releaseTween then pcall(function() visual.releaseTween:Cancel() end) end
        if visual.glowTween then pcall(function() visual.glowTween:Cancel() end) end
        if visual.highlightTween then pcall(function() visual.highlightTween:Cancel() end) end
    end

    local isBlack = visual and visual.isBlack or blackButtons[noteName] ~= nil
    local pressedColor = isBlack and Color3.fromRGB(42, 41, 38) or Color3.fromRGB(229, 230, 224)
    if visual then
        local basePos = visual.basePosition
        local baseSize = visual.baseSize
        local yPress = isBlack and 3 or 2
        local pressedPosition = UDim2.new(basePos.X.Scale, basePos.X.Offset, basePos.Y.Scale, basePos.Y.Offset + yPress)
        local pressedSize = UDim2.new(baseSize.X.Scale, baseSize.X.Offset, baseSize.Y.Scale, baseSize.Y.Offset - yPress)
        visual.pressTween = TweenService:Create(key, TweenInfo.new(0.045, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = pressedPosition,
            Size = pressedSize,
            BackgroundColor3 = pressedColor,
        })
        visual.pressTween:Play()
        if visual.glow then
            visual.glowTween = TweenService:Create(visual.glow, TweenInfo.new(0.04, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.12})
            visual.glowTween:Play()
        end
        if visual.highlight then
            visual.highlightTween = TweenService:Create(visual.highlight, TweenInfo.new(0.05), {BackgroundTransparency = 0.04})
            visual.highlightTween:Play()
        end
    else
        key.BackgroundColor3 = pressedColor
    end
    -- Audio is triggered before this visual animation by playNote(). Keep this
    -- function visual-only so tweens cannot delay the start of a piano sample.

    if (voiceState.heldKeyCounts[noteName] or 0) <= 0 then
        task.delay(0.105, function()
            if not key.Parent or keyPulseTokens[noteName] ~= token
                or (voiceState.heldKeyCounts[noteName] or 0) > 0 then return end
            if visual then
                visual.releaseTween = TweenService:Create(key, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                    Position = visual.basePosition,
                    Size = visual.baseSize,
                    BackgroundColor3 = keyBaseColors[noteName] or (isBlack and COLORS.blackKey or COLORS.whiteKey),
                })
                visual.releaseTween:Play()
                if visual.glow then
                    visual.glowTween = TweenService:Create(visual.glow, TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
                    visual.glowTween:Play()
                end
                if visual.highlight then
                    visual.highlightTween = TweenService:Create(visual.highlight, TweenInfo.new(0.18), {BackgroundTransparency = visual.isBlack and 0.68 or 0.48})
                    visual.highlightTween:Play()
                end
            else
                key.BackgroundColor3 = keyBaseColors[noteName] or (isBlack and COLORS.blackKey or COLORS.whiteKey)
            end
        end)
    end
end

local handleMiniGameInput -- assigned after game UI and note aliases have been created

local FALLBACK_SEMITONE = 12 -- C4 is the supplied sample known to work for the user.

local function nearestLoadedSample(semi)
    -- Never map a press to an unloaded Sound. Doing so made keys flash as if they
    -- played even though Sound:Play() had no ready audio asset behind it.
    local exactPool = samplePools[semi]
    if exactPool then
        for _, sound in ipairs(exactPool) do
            if sound and sound.Parent and sound.IsLoaded then
                sampleReady[semi] = true
                return semi
            end
        end
    end

    -- During startup and when an exact asset is inaccessible, use the closest
    -- source that has actually loaded. A pitch-shifted loaded sample is preferable
    -- to falsely playing a silent, unloaded source.
    local bestSemi, bestDistance = nil, math.huge
    for candidateSemi, pool in pairs(samplePools) do
        local candidateLoaded = false
        for _, sound in ipairs(pool) do
            if sound and sound.Parent and sound.IsLoaded then
                candidateLoaded = true
                break
            end
        end
        if candidateLoaded then
            local distance = math.abs(candidateSemi - semi)
            if distance < bestDistance then
                bestSemi, bestDistance = candidateSemi, distance
            end
        end
    end
    return bestSemi
end

local function nearestAvailableSample(semi)
    -- If no source has finished loading yet, queue against the closest note asset
    -- to avoid stretching C4 across several octaves during the loading window.
    local bestSemi, bestDistance = nil, math.huge
    for candidateSemi, pool in pairs(samplePools) do
        if pool and #pool > 0 then
            local distance = math.abs(candidateSemi - semi)
            if distance < bestDistance then bestSemi, bestDistance = candidateSemi, distance end
        end
    end
    return bestSemi or FALLBACK_SEMITONE
end

local function finishNoteStart(snd, note, source, takeVelocity, takeTranspose, targetSemi, pressTime, pendingRequest)
    -- A queued manual tap may be released before its source has loaded. It still
    -- plays one natural sample after load, but does not leave a key visually held.
    local physicallyHeld = source == "manual" and voiceState.manualHeld[snd] == true
    if isRecording and source == "manual" and #recordBuffer < MAX_RECORD_NOTES then
        local recordedEvent = {
            name = note.name,
            t = math.max(0, pressTime - recordStartedAt),
            velocity = takeVelocity,
            transpose = takeTranspose,
            duration = 0.18,
        }
        if pendingRequest and pendingRequest.releasedAt then
            local releaseElapsed = pendingRequest.releasedAt - (recordStartedAt + recordedEvent.t)
            recordedEvent.duration = math.clamp(releaseElapsed, 0.04, MAX_RECORDED_GAP)
            recordedEvent._closed = true
        end
        table.insert(recordBuffer, recordedEvent)
        if not recordedEvent._closed then
            voiceState.recordedEvents[snd] = recordedEvent
        end
    end

    if physicallyHeld then
        voiceState.heldKeyCounts[note.name] = (voiceState.heldKeyCounts[note.name] or 0) + 1
    end
    flashKey(note.name, note.semi)
    if source == "manual" and handleMiniGameInput then
        task.defer(handleMiniGameInput, note)
    end
    pulseSpectrum(targetSemi)

    if isRecording and source == "manual" then
        status.Text = "● ĐANG THU  •  " .. tostring(#recordBuffer) .. " NỐT"
        status.TextColor3 = COLORS.red
        if #recordBuffer >= MAX_RECORD_NOTES and finishRecording then finishRecording() end
    else
        local transposeText = takeTranspose == 0 and "" or string.format("  •  DỊCH ÂM %+d", takeTranspose)
        status.Text = "ĐANG PHÁT  •  " .. note.displayName .. transposeText
        status.TextColor3 = COLORS.green
    end
end

local function playNote(note, source, velocityOverride, transposeOverride)
    source = source or "manual"
    local pressTime = os.clock()
    local takeVelocity = velocityOverride or dynamicsOptions[dynamicsIndex].multiplier
    local takeTranspose = transposeOverride
    if takeTranspose == nil then takeTranspose = transposeSemitones end

    -- C7-C8 are intentionally outside this instrument's playable range. Clamp
    -- transposition too, so a +transpose cannot silently recreate the removed keys.
    local targetSemi = math.clamp(note.semi + takeTranspose, -27, 47)
    takeTranspose = targetSemi - note.semi

    local sourceSemi = nearestLoadedSample(targetSemi)
    if sourceSemi == nil then
        if source ~= "manual" then
            status.Text = "ĐANG TẢI MẪU ÂM THANH  •  " .. note.displayName
            status.TextColor3 = COLORS.accent2
            return nil
        end
        sourceSemi = nearestAvailableSample(targetSemi)
    end

    local pool = samplePools[sourceSemi]
    if not pool or #pool == 0 then
        status.Text = "KHÔNG CÓ MẪU ÂM THANH  •  " .. note.displayName
        status.TextColor3 = COLORS.red
        return nil
    end

    -- Prefer a ready idle voice, then an unused cold voice. Recycle a busy or
    -- pending voice only as the last resort so chords and loading notes don't
    -- cancel one another unnecessarily.
    local loadedFree, loadedBusy, coldVoices, pendingVoices = {}, {}, {}, {}
    for _, candidate in ipairs(pool) do
        if candidate and candidate.Parent then
            local pending = voiceState.pendingRequests[candidate]
            if candidate.IsLoaded then
                if not candidate.IsPlaying and not sustainedVoices[candidate] and not pending then
                    table.insert(loadedFree, candidate)
                else
                    table.insert(loadedBusy, candidate)
                end
            elseif not pending then
                table.insert(coldVoices, candidate)
            else
                table.insert(pendingVoices, candidate)
            end
        end
    end

    local snd
    if #loadedFree > 0 then
        voiceCursor[sourceSemi] = (voiceCursor[sourceSemi] or 0) % #loadedFree + 1
        snd = loadedFree[voiceCursor[sourceSemi]]
    elseif #loadedBusy > 0 then
        -- Prefer a loaded voice over a cold voice so repeated taps stay responsive.
        -- Recycle the oldest only when every ready voice for this source is busy.
        snd = loadedBusy[1]
        local oldestStart = voiceState.startedAt[snd] or 0
        for _, candidate in ipairs(loadedBusy) do
            local candidateStart = voiceState.startedAt[candidate] or 0
            if candidateStart < oldestStart then
                snd = candidate
                oldestStart = candidateStart
            end
        end
    elseif #coldVoices > 0 then
        voiceCursor[sourceSemi] = (voiceCursor[sourceSemi] or 0) % #coldVoices + 1
        snd = coldVoices[voiceCursor[sourceSemi]]
    elseif #pendingVoices > 0 then
        -- Only replace a still-loading voice when all other voices are occupied.
        snd = pendingVoices[1]
        local oldestStart = voiceState.startedAt[snd] or 0
        for _, candidate in ipairs(pendingVoices) do
            local candidateStart = voiceState.startedAt[candidate] or 0
            if candidateStart < oldestStart then
                snd = candidate
                oldestStart = candidateStart
            end
        end
    end

    if not snd then
        status.Text = "LỖI ÂM THANH  •  Không có giọng đàn khả dụng"
        status.TextColor3 = COLORS.red
        return nil
    end

    local previousPending = voiceState.pendingRequests[snd]
    if previousPending then
        previousPending.cancelled = true
        voiceState.pendingRequests[snd] = nil
    end
    local previousRecordedEvent = voiceState.recordedEvents[snd]
    if previousRecordedEvent and not previousRecordedEvent._closed then
        previousRecordedEvent.duration = math.clamp(
            (pressTime - recordStartedAt) - (tonumber(previousRecordedEvent.t) or 0),
            0.04,
            MAX_RECORDED_GAP
        )
        previousRecordedEvent._closed = true
        voiceState.recordedEvents[snd] = nil
    end

    local oldFade = voiceState.fadeTweens[snd]
    if oldFade then
        pcall(function() oldFade:Cancel() end)
        voiceState.fadeTweens[snd] = nil
    end
    voiceReleaseTokens[snd] = (voiceReleaseTokens[snd] or 0) + 1
    sustainedVoices[snd] = nil
    PianoUI.sostenutoVoices[snd] = nil
    pcall(function() if snd.IsPlaying then snd:Stop() end end)
    voiceState.velocities[snd] = takeVelocity
    voiceState.startedAt[snd] = pressTime
    voiceState.semitones[snd] = targetSemi
    voiceState.manualHeld[snd] = (source == "manual") and true or nil

    local pitchSpeed = math.clamp(2 ^ ((targetSemi - sourceSemi) / 12), 0.125, 8)
    local function startReadySound()
        local ok, playbackError = pcall(function()
            snd.Looped = false
            snd.PlaybackRegionsEnabled = false
            snd.Volume = effectiveVoiceVolume(takeVelocity, targetSemi)
            snd.PlaybackSpeed = pitchSpeed
            snd.TimePosition = 0
            snd:Play()
            if not snd.IsPlaying then error("Audio source did not enter playback") end
        end)
        return ok, playbackError
    end

    if not snd.IsLoaded then
        if source ~= "manual" then
            voiceState.manualHeld[snd] = nil
            status.Text = "ĐANG TẢI MẪU ÂM THANH  •  " .. note.displayName
            status.TextColor3 = COLORS.accent2
            return nil
        end

        local request = {
            note = note,
            source = source,
            velocity = takeVelocity,
            transpose = takeTranspose,
            targetSemi = targetSemi,
            pressTime = pressTime,
            releasedAt = nil,
            cancelled = false,
        }
        voiceState.pendingRequests[snd] = request
        status.Text = "ĐANG CHUẨN BỊ ÂM THANH  •  " .. note.displayName
        status.TextColor3 = COLORS.accent2
        task.spawn(function()
            local deadline = os.clock() + 10
            while not shuttingDown and snd.Parent and voiceState.pendingRequests[snd] == request
                and not request.cancelled and not snd.IsLoaded and os.clock() < deadline do
                task.wait(0.04)
            end
            if shuttingDown or not snd.Parent or request.cancelled
                or voiceState.pendingRequests[snd] ~= request then return end
            if not snd.IsLoaded then
                voiceState.pendingRequests[snd] = nil
                voiceState.manualHeld[snd] = nil
                status.Text = "ÂM THANH KHÔNG TẢI ĐƯỢC  •  Kiểm tra quyền truy cập asset"
                status.TextColor3 = COLORS.red
                return
            end
            -- Ignore a very stale quick tap rather than making it sound seconds later.
            if request.releasedAt and os.clock() - request.releasedAt > 2.0 and not sustainedVoices[snd] then
                voiceState.pendingRequests[snd] = nil
                voiceState.manualHeld[snd] = nil
                return
            end
            voiceState.pendingRequests[snd] = nil
            local ok, playbackError = startReadySound()
            if not ok then
                voiceState.manualHeld[snd] = nil
                warn("[VirtualPiano] Delayed playback failed for " .. tostring(note.name) .. ": " .. tostring(playbackError))
                status.Text = "LỖI ÂM THANH  •  " .. note.displayName
                status.TextColor3 = COLORS.red
                return
            end
            voiceState.startedAt[snd] = os.clock()
            finishNoteStart(snd, note, source, takeVelocity, takeTranspose, targetSemi, pressTime, request)
        end)
        return snd
    end

    local ok, playbackError = startReadySound()
    if not ok then
        voiceState.manualHeld[snd] = nil
        warn("[VirtualPiano] Note playback failed for " .. tostring(note.name) .. ": " .. tostring(playbackError))
        status.Text = "LỖI ÂM THANH  •  " .. note.displayName
        status.TextColor3 = COLORS.red
        return nil
    end

    voiceState.pendingRequests[snd] = nil
    voiceState.startedAt[snd] = os.clock()
    finishNoteStart(snd, note, source, takeVelocity, takeTranspose, targetSemi, pressTime)
    return snd
end

-- A piano note is not cut off as soon as the key is released. Let its audio
-- tail fade gradually; lower notes get a longer release than higher notes.
-- While the key is held, this release envelope is not started at all.
local function naturalReleaseDuration(snd)
    local semi = tonumber(voiceState.semitones[snd])
    if not semi then return 1.2 end
    local pitchInRange = math.clamp(semi, -27, 47) -- visible range A0-B6
    local normalizedPitch = (pitchInRange + 27) / 74
    return 2.1 - (normalizedPitch * 1.2) -- low notes: 2.10s; high notes: 0.90s
end

local function stopVoiceWithRelease(snd, releaseSeconds)
    if not snd or not snd.Parent then return end
    local pending = voiceState.pendingRequests[snd]
    if pending and not snd.IsPlaying then
        pending.cancelled = true
        voiceState.pendingRequests[snd] = nil
        voiceState.manualHeld[snd] = nil
        sustainedVoices[snd] = nil
        return
    end
    voiceReleaseTokens[snd] = (voiceReleaseTokens[snd] or 0) + 1
    local token = voiceReleaseTokens[snd]
    sustainedVoices[snd] = nil
    voiceState.manualHeld[snd] = nil
    pcall(function() snd.Looped = false end)
    local oldFade = voiceState.fadeTweens[snd]
    if oldFade then pcall(function() oldFade:Cancel() end) end
    local fadeDuration = releaseSeconds or naturalReleaseDuration(snd)
    local ok, tween = pcall(function()
        return TweenService:Create(snd, TweenInfo.new(fadeDuration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {Volume = 0})
    end)
    if ok and tween then
        voiceState.fadeTweens[snd] = tween
        tween:Play()
    end
    task.delay(fadeDuration + 0.025, function()
        if snd and snd.Parent and voiceReleaseTokens[snd] == token then
            if voiceState.fadeTweens[snd] == tween then voiceState.fadeTweens[snd] = nil end
            pcall(function()
                snd:Stop()
                snd.Looped = false
                snd.PlaybackRegionsEnabled = false
                snd.Volume = effectiveVoiceVolume(voiceState.velocities[snd], voiceState.semitones[snd])
            end)
        end
    end)
end

local function releaseManualVoice(record)
    if not record then return end

    if record.note then
        local noteName = record.note.name
        local heldCount = math.max(0, (voiceState.heldKeyCounts[noteName] or 0) - 1)
        voiceState.heldKeyCounts[noteName] = heldCount
        if heldCount == 0 then
            voiceState.heldKeyCounts[noteName] = nil
            local visual = keyVisuals[noteName]
            local key = visual and visual.button or whiteButtons[noteName] or blackButtons[noteName]
            if key and key.Parent then
                keyPulseTokens[noteName] = (keyPulseTokens[noteName] or 0) + 1
                if visual then
                    for _, tweenKey in ipairs({"pressTween", "releaseTween", "glowTween", "highlightTween"}) do
                        local activeTween = visual[tweenKey]
                        if activeTween then pcall(function() activeTween:Cancel() end) end
                    end
                    visual.releaseTween = TweenService:Create(key, TweenInfo.new(0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Position = visual.basePosition,
                        Size = visual.baseSize,
                        BackgroundColor3 = keyBaseColors[noteName] or (visual.isBlack and COLORS.blackKey or COLORS.whiteKey),
                    })
                    visual.releaseTween:Play()
                    if visual.glow then
                        visual.glowTween = TweenService:Create(visual.glow, TweenInfo.new(0.18), {BackgroundTransparency = 1})
                        visual.glowTween:Play()
                    end
                    if visual.highlight then
                        visual.highlightTween = TweenService:Create(visual.highlight, TweenInfo.new(0.18), {BackgroundTransparency = visual.isBlack and 0.68 or 0.48})
                        visual.highlightTween:Play()
                    end
                else
                    key.BackgroundColor3 = keyBaseColors[noteName] or COLORS.whiteKey
                end
            end
        end
    end

    if not record.sound then return end

    -- The first tap can arrive before Roblox finishes loading the sample. Let a
    -- recently released tap start once loaded (up to two seconds later) instead
    -- of dropping it silently; it will play one-shot and will not remain held.
    local pendingRequest = voiceState.pendingRequests[record.sound]
    if pendingRequest and not record.sound.IsPlaying then
        voiceState.manualHeld[record.sound] = nil
        pendingRequest.releasedAt = os.clock()
        pendingRequest.sustainRequested = sustainEnabled
        if sustainEnabled then sustainedVoices[record.sound] = true end
        return
    end

    -- Stop the held-note loop as soon as the physical key comes up. The current
    -- sustain segment may finish while the release envelope fades it out.
    voiceState.manualHeld[record.sound] = nil
    pcall(function() record.sound.Looped = false end)

    -- A recorded note includes both key-down time and key-up duration. The same
    -- event object is kept on the active input so voice reuse cannot corrupt it.
    local recordedEvent = record.recordEvent or voiceState.recordedEvents[record.sound]
    if recordedEvent and not recordedEvent._closed then
        local elapsed = (os.clock() - recordStartedAt) - (tonumber(recordedEvent.t) or 0)
        recordedEvent.duration = math.clamp(elapsed, 0.04, MAX_RECORDED_GAP)
        recordedEvent._closed = true
        if voiceState.recordedEvents[record.sound] == recordedEvent then
            voiceState.recordedEvents[record.sound] = nil
        end
    end

    if sustainEnabled or (PianoUI.sostenutoEnabled and PianoUI.sostenutoVoices[record.sound]) then
        sustainedVoices[record.sound] = true
    else
        -- Do not stop instantly: let the note tail decay naturally after key-up.
        stopVoiceWithRelease(record.sound)
    end
end

local function dampSustainedVoices()
    local pending = {}
    for snd in pairs(sustainedVoices) do
        if not sustainEnabled and not (PianoUI.sostenutoEnabled and PianoUI.sostenutoVoices[snd]) then
            table.insert(pending, snd)
        end
    end
    for _, snd in ipairs(pending) do stopVoiceWithRelease(snd) end
end

local function bindPianoKey(button, note)
    button.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        local snd = playNote(note, "manual")
        activeInputVoices[input] = {note = note, sound = snd, recordEvent = snd and voiceState.recordedEvents[snd]}
    end)
    button.InputEnded:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        local record = activeInputVoices[input]
        if record then
            activeInputVoices[input] = nil
            releaseManualVoice(record)
        end
    end)
end

local function playMetronomeTick(beatIndex)
    if not metronomeEnabled or shuttingDown or not metronomeSound or not metronomeSound.Parent then return end
    metronomeToken += 1
    local myToken = metronomeToken
    pulseSpectrum(36)
    pcall(function()
        metronomeSound:Stop()
        metronomeSound.TimePosition = 0
        metronomeSound.PlaybackSpeed = 3.0
        metronomeSound.Volume = volume * (beatIndex and beatIndex % 4 == 1 and 0.28 or 0.16)
        metronomeSound:Play()
    end)
    -- A short high sample makes a metronome-like plink. A visual beat marker
    -- remains useful even when Roblox cannot load the sample in this experience.
    task.delay(0.065, function()
        if myToken == metronomeToken and metronomeSound and metronomeSound.Parent then
            pcall(function() metronomeSound:Stop() end)
        end
    end)
end

-- Load the complete set asynchronously in one request. This avoids waiting for
-- all sample assets one by one while keeping the GUI interactive.
local function refreshSampleReadiness()
    local loadedCount = 0
    for semi, pool in pairs(samplePools) do
        local loaded = false
        for _, snd in ipairs(pool) do
            if snd and snd.IsLoaded then loaded = true break end
        end
        sampleReady[semi] = loaded
        if loaded then loadedCount += 1 end
    end
    return loadedCount
end

local function updateAudioStatus()
    if shuttingDown or not gui.Parent or isRecording or playing then return end
    -- An asynchronous preload completion must not overwrite an unrelated status
    -- such as a played note, a parser error, or a mini-game prompt.
    local text = status.Text
    local isLoadingStatus = string.find(text, "ĐANG TẢI ÂM THANH", 1, true)
        or string.find(text, "ĐANG CHỜ ÂM THANH", 1, true)
        or string.find(text, "ÂM THANH CHƯA ĐỦ", 1, true)
        or string.find(text, "SẴN SÀNG  •  75 PHÍM", 1, true)
    if not isLoadingStatus then return end

    local loadedCount = refreshSampleReadiness()
    if loadedCount == 37 then
        status.Text = "ÂM THANH SẴN SÀNG  •  Đã tải đủ 37 nốt"
        status.TextColor3 = COLORS.green
    elseif not preloadFinished and not (preloadDeadlineReached and loadedCount == 0) then
        status.Text = "ĐANG TẢI ÂM THANH  •  " .. tostring(loadedCount) .. "/37 nốt sẵn sàng"
        status.TextColor3 = COLORS.accent2
    elseif loadedCount > 0 then
        status.Text = "ÂM THANH CHƯA ĐỦ  •  " .. tostring(loadedCount) .. "/37 nốt sẵn sàng"
        status.TextColor3 = COLORS.accent2
    elseif preloadDeadlineReached then
        status.Text = "ĐANG CHỜ ÂM THANH  •  Kiểm tra quyền truy cập âm thanh"
        status.TextColor3 = COLORS.red
    else
        status.Text = "ĐANG TẢI ÂM THANH  •  Chuẩn bị 37 nốt"
        status.TextColor3 = COLORS.accent2
    end
end

task.delay(12, function()
    if not preloadFinished and not shuttingDown then
        preloadDeadlineReached = true
        warn("[VirtualPiano] Full-range audio preload exceeded 12 seconds; interface remains responsive.")
        updateAudioStatus()
    end
end)

task.spawn(function()
    if not shuttingDown and gui.Parent then
        status.Text = "ĐANG TẢI ÂM THANH  •  Chuẩn bị toàn bộ dải nốt"
        status.TextColor3 = COLORS.accent2
    end

    -- Preload one voice for every supplied note asset first, so high and low
    -- registers can also answer the first touch promptly. Then warm up the other
    -- voices for the frequently played C4-C5 range; remaining duplicate voices
    -- continue loading in the background.
    local prioritySounds = {}
    local prioritySet = {}
    for semi, pool in pairs(samplePools) do
        local firstVoice = pool and pool[1]
        if firstVoice then
            table.insert(prioritySounds, firstVoice)
            prioritySet[firstVoice] = true
        end
    end
    for semi = 12, 24 do
        local pool = samplePools[semi]
        if pool then
            for i = 2, #pool do
                local snd = pool[i]
                table.insert(prioritySounds, snd)
                prioritySet[snd] = true
            end
        end
    end

    local priorityOk, priorityError = pcall(function()
        ContentProvider:PreloadAsync(prioritySounds)
    end)
    refreshSampleReadiness()
    if not shuttingDown then updateAudioStatus() end

    local remainingSounds = {}
    for _, snd in ipairs(sounds) do
        if snd ~= metronomeSound and not prioritySet[snd] then
            table.insert(remainingSounds, snd)
        end
    end
    local remainingOk, remainingError = pcall(function()
        ContentProvider:PreloadAsync(remainingSounds)
    end)

    local loadedCount = refreshSampleReadiness()
    preloadFinished = true
    if not priorityOk then
        warn("[VirtualPiano] Priority audio preload reported an error: " .. tostring(priorityError))
    end
    if not remainingOk then
        warn("[VirtualPiano] Full-range audio preload reported an error: " .. tostring(remainingError))
    end
    if not shuttingDown then
        updateAudioStatus()
        if loadedCount < 37 then
            warn("[VirtualPiano] Only " .. tostring(loadedCount) .. "/" .. tostring(37) .. " individual note samples are loaded. Check asset permissions in this experience.")
        end
    end
end)

-- Realistic key proportions: use a consistent physical width instead of squeezing
-- all 37 notes into the viewport. On mobile the player swipes horizontally through
-- the three-octave range; desktop users usually see most or all keys at once.
-- Touch devices use wider, finger-friendly keys in both portrait and landscape.
-- Desktop uses medium-width keys; the 75-note A0-B6 range remains horizontally scrollable.
PianoUI.initialCamera = workspace.CurrentCamera
PianoUI.initialViewport = PianoUI.initialCamera and PianoUI.initialCamera.ViewportSize or Vector2.new(420, 840)
-- Detect touch devices independently of orientation. Phones are often played in
-- landscape, where a portrait-only test incorrectly selected tiny desktop keys.
PianoUI.touchDevice = UserInputService.TouchEnabled
PianoUI.initialMobilePortrait = PianoUI.initialViewport.X < 600 and PianoUI.initialViewport.Y > PianoUI.initialViewport.X
local WHITE_KEY_PIXEL_WIDTH = PianoUI.touchDevice and 58 or 34
local BLACK_KEY_PIXEL_WIDTH = PianoUI.touchDevice and 35 or 22
local KEYBOARD_CANVAS_WIDTH = (#whiteNotes * WHITE_KEY_PIXEL_WIDTH) + 4
keyArea.CanvasSize = UDim2.new(0, KEYBOARD_CANVAS_WIDTH, 0, 0)
keyArea.ScrollingEnabled = true
keyArea.ScrollBarThickness = 3
keyArea.ScrollingDirection = Enum.ScrollingDirection.X
keyArea.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
keyArea.Active = true

for i, note in ipairs(whiteNotes) do
    local whiteShadow = Instance.new("Frame")
    whiteShadow.Name = note.name .. "DepthShadow"
    whiteShadow.Size = UDim2.new(0, WHITE_KEY_PIXEL_WIDTH - 1, 1, -2)
    whiteShadow.Position = UDim2.new(0, ((i - 1) * WHITE_KEY_PIXEL_WIDTH) + 2, 0, 3)
    whiteShadow.BackgroundColor3 = Color3.fromRGB(7, 6, 5)
    whiteShadow.BorderSizePixel = 0
    whiteShadow.ZIndex = 1
    whiteShadow.Active = false
    whiteShadow.Parent = keyArea
    corner(whiteShadow, 4)

    local key = Instance.new("TextButton")
    key.Name = note.name
    key.Size = UDim2.new(0, WHITE_KEY_PIXEL_WIDTH - 2, 1, -2)
    key.Position = UDim2.new(0, ((i - 1) * WHITE_KEY_PIXEL_WIDTH) + 1, 0, 0)
    key.BackgroundColor3 = COLORS.whiteKey
    key.ZIndex = 1
    -- Keep the key surface clean; small octave markers are added separately below.
    key.Text = ""
    key.TextColor3 = COLORS.whiteKeyText
    key.TextSize = 8
    key.TextScaled = false
    key.TextWrapped = false
    key.Font = Enum.Font.GothamBold
    key.TextYAlignment = Enum.TextYAlignment.Bottom
    key.TextXAlignment = Enum.TextXAlignment.Center
    key.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
    key.TextStrokeTransparency = 1
    key.AutoButtonColor = false
    key.Parent = keyArea
    corner(key, 3)
    stroke(key, Color3.fromRGB(178, 168, 147), 0.7, 0.18)
    addGradient(key, ColorSequence.new(Color3.fromRGB(255, 255, 253), Color3.fromRGB(248, 248, 245)), 90, note.name .. " neutral ivory key")
    if note.pitchName == "C" then
        local octaveMarker = Instance.new("TextLabel")
        octaveMarker.Name = "OctaveMarker"
        octaveMarker.BackgroundTransparency = 1
        octaveMarker.BorderSizePixel = 0
        octaveMarker.Position = UDim2.new(0, 0, 1, -15)
        octaveMarker.Size = UDim2.new(1, 0, 0, 11)
        octaveMarker.Text = "C" .. tostring(note.octave)
        octaveMarker.TextColor3 = COLORS.whiteKeyText
        octaveMarker.TextTransparency = 0.12
        octaveMarker.TextSize = 8
        octaveMarker:SetAttribute("PianoBaseTextSize", octaveMarker.TextSize)
        octaveMarker.Font = Enum.Font.GothamBold
        octaveMarker.TextXAlignment = Enum.TextXAlignment.Center
        octaveMarker.TextYAlignment = Enum.TextYAlignment.Center
        octaveMarker.Active = false
        octaveMarker.ZIndex = 4
        octaveMarker.Parent = key
    end
    local topHighlight = Instance.new("Frame")
    topHighlight.Name = "TopHighlight"
    topHighlight.Position = UDim2.new(0, 3, 0, 3)
    topHighlight.Size = UDim2.new(1, -6, 0, 4)
    topHighlight.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    topHighlight.BackgroundTransparency = 0.48
    topHighlight.BorderSizePixel = 0
    topHighlight.Active = false
    topHighlight.ZIndex = 2
    topHighlight.Parent = key
    corner(topHighlight, 2)
    local lowerShade = Instance.new("Frame")
    lowerShade.Name = "LowerShade"
    lowerShade.AnchorPoint = Vector2.new(0, 1)
    lowerShade.Position = UDim2.new(0, 1, 1, -1)
    lowerShade.Size = UDim2.new(1, -2, 0, 7)
    lowerShade.BackgroundColor3 = Color3.fromRGB(105, 94, 74)
    lowerShade.BackgroundTransparency = 0.74
    lowerShade.BorderSizePixel = 0
    lowerShade.Active = false
    lowerShade.ZIndex = 2
    lowerShade.Parent = key
    corner(lowerShade, 3)
    local keyGlow = Instance.new("Frame")
    keyGlow.Name = "ReactiveSideGlow"
    keyGlow.Position = UDim2.new(0, 2, 0, 19)
    keyGlow.Size = UDim2.new(0, 3, 0, 26)
    keyGlow.BackgroundColor3 = COLORS.cyan
    keyGlow.BackgroundTransparency = 1
    keyGlow.BorderSizePixel = 0
    keyGlow.Active = false
    keyGlow.ZIndex = 3
    keyGlow.Parent = key
    corner(keyGlow, 2)
    keyBaseColors[note.name] = COLORS.whiteKey
    keyVisuals[note.name] = {
        button = key,
        basePosition = key.Position,
        baseSize = key.Size,
        isBlack = false,
        glow = keyGlow,
        highlight = topHighlight,
        shadow = whiteShadow,
    }
    bindPianoKey(key, note)
    whiteButtons[note.name] = key
end

for _, note in ipairs(notes) do
    if note.black then
        local prevWhiteCount = 0
        for _, w in ipairs(whiteNotes) do
            if w.semi < note.semi then prevWhiteCount += 1 end
        end
        local key = Instance.new("TextButton")
        key.Name = note.name
        key.AnchorPoint = Vector2.new(0.5, 0)
        key.Size = UDim2.new(0, BLACK_KEY_PIXEL_WIDTH, 0.62, 0)
        key.Position = UDim2.new(0, prevWhiteCount * WHITE_KEY_PIXEL_WIDTH, 0, 0)
        key.BackgroundColor3 = COLORS.blackKey
        key.Text = ""
        key.TextColor3 = Color3.fromRGB(235, 214, 171)
        key.TextStrokeTransparency = 1
        key.TextSize = 8
        key.TextScaled = false
        key.TextWrapped = false
        key.Font = Enum.Font.GothamBold
        key.TextStrokeColor3 = Color3.new(0, 0, 0)
        key.TextStrokeTransparency = 1
        key.ZIndex = 3
        key.AutoButtonColor = false
        local keyShadow = Instance.new("Frame")
        keyShadow.Name = note.name .. "Shadow"
        keyShadow.AnchorPoint = key.AnchorPoint
        keyShadow.Size = key.Size
        keyShadow.Position = UDim2.new(0, key.Position.X.Offset, key.Position.Y.Scale, key.Position.Y.Offset + 3)
        keyShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        keyShadow.BorderSizePixel = 0
        keyShadow.ZIndex = 2
        keyShadow.Active = false
        keyShadow.Parent = keyArea
        corner(keyShadow, 2)
        key.Parent = keyArea
        corner(key, 2)
        stroke(key, Color3.fromRGB(52, 45, 34), 0.8, 0.08)
        -- A restrained gloss creates the polished ebony look without neon gradients.
        key.BackgroundColor3 = Color3.fromRGB(11, 11, 12)
        local blackHighlight = Instance.new("Frame")
        blackHighlight.Name = "GlossHighlight"
        blackHighlight.Position = UDim2.new(0, 4, 0, 3)
        blackHighlight.Size = UDim2.new(1, -8, 0, 4)
        blackHighlight.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        blackHighlight.BackgroundTransparency = 0.68
        blackHighlight.BorderSizePixel = 0
        blackHighlight.Active = false
        blackHighlight.ZIndex = 4
        blackHighlight.Parent = key
        corner(blackHighlight, 2)
        local blackGlow = Instance.new("Frame")
        blackGlow.Name = "ReactiveSideGlow"
        blackGlow.Position = UDim2.new(0, 3, 0, 13)
        blackGlow.Size = UDim2.new(0, 3, 0, 21)
        blackGlow.BackgroundColor3 = COLORS.cyan
        blackGlow.BackgroundTransparency = 1
        blackGlow.BorderSizePixel = 0
        blackGlow.Active = false
        blackGlow.ZIndex = 5
        blackGlow.Parent = key
        corner(blackGlow, 2)
        keyBaseColors[note.name] = COLORS.blackKey
        keyVisuals[note.name] = {
            button = key,
            basePosition = key.Position,
            baseSize = key.Size,
            isBlack = true,
            glow = blackGlow,
            highlight = blackHighlight,
            shadow = keyShadow,
        }
        bindPianoKey(key, note)
        blackButtons[note.name] = key
    end
end

PianoUI.whiteKeysBeforeC3 = 0
for _, note in ipairs(whiteNotes) do
    if note.semi < 0 then PianoUI.whiteKeysBeforeC3 += 1 end
end
keyArea.CanvasPosition = Vector2.new(PianoUI.whiteKeysBeforeC3 * WHITE_KEY_PIXEL_WIDTH, 0)
task.defer(function()
    if keyArea and keyArea.Parent then
        pcall(function() keyArea.CanvasPosition = Vector2.new(PianoUI.whiteKeysBeforeC3 * WHITE_KEY_PIXEL_WIDTH, 0) end)
    end
end)

local instrumentControls = Instance.new("Frame")
instrumentControls.Name = "InstrumentControls"
instrumentControls.BackgroundTransparency = 1
instrumentControls.Position = UDim2.new(0, 0, 0, 67)
instrumentControls.Size = UDim2.new(1, 0, 0, 25)
instrumentControls.Parent = content

local sustainBtn = makeButton(instrumentControls, "GIỮ TẮT", UDim2.new(0, 64, 1, 0), UDim2.new(0, 0, 0, 0), Color3.fromRGB(61, 49, 34), Color3.fromRGB(241, 225, 191), 10)
local softBtn = makeButton(instrumentControls, "ÊM TẮT", UDim2.new(0, 62, 1, 0), UDim2.new(0, 68, 0, 0), Color3.fromRGB(61, 49, 34), Color3.fromRGB(241, 225, 191), 10)
local dynamicsBtn = makeButton(instrumentControls, "LỰC 3/4", UDim2.new(0, 50, 1, 0), UDim2.new(0, 134, 0, 0), Color3.fromRGB(52, 43, 31), Color3.fromRGB(246,241,229), 10)
local transposeDownBtn = makeButton(instrumentControls, "ÂM −", UDim2.new(0, 42, 1, 0), UDim2.new(0, 188, 0, 0), Color3.fromRGB(52, 43, 31), Color3.fromRGB(246,241,229), 10)
local transposeLabel = makeButton(instrumentControls, "0 BÁN", UDim2.new(0, 44, 1, 0), UDim2.new(0, 234, 0, 0), Color3.fromRGB(61, 49, 34), Color3.fromRGB(241, 225, 191), 10)
local transposeUpBtn = makeButton(instrumentControls, "ÂM +", UDim2.new(0, 42, 1, 0), UDim2.new(0, 282, 0, 0), Color3.fromRGB(52, 43, 31), Color3.fromRGB(246,241,229), 10)
local tempoBtn = makeButton(instrumentControls, "NHỊP 100", UDim2.new(0, 60, 1, 0), UDim2.new(0, 328, 0, 0), Color3.fromRGB(52, 43, 31), Color3.fromRGB(246,241,229), 10)
local metronomeBtn = makeButton(instrumentControls, "GÕ TẮT", UDim2.new(0, 62, 1, 0), UDim2.new(0, 392, 0, 0), Color3.fromRGB(61, 49, 34), Color3.fromRGB(241, 225, 191), 10)
local loopBtn = makeButton(instrumentControls, "LẶP TẮT", UDim2.new(0, 60, 1, 0), UDim2.new(0, 458, 0, 0), Color3.fromRGB(52, 43, 31), Color3.fromRGB(246,241,229), 10)
local copyTakeBtn = makeButton(instrumentControls, "CHÉP BẢN", UDim2.new(0, 62, 1, 0), UDim2.new(0, 522, 0, 0), Color3.fromRGB(61, 49, 34), Color3.fromRGB(241, 225, 191), 10)
PianoUI.sostenutoBtn = makeButton(instrumentControls, "SOS TẮT", UDim2.new(0, 62, 1, 0), UDim2.new(0, 588, 0, 0), Color3.fromRGB(61, 49, 34), Color3.fromRGB(241, 225, 191), 10)
PianoUI.roomBtn = makeButton(instrumentControls, "PHÒNG BẬT", UDim2.new(0, 72, 1, 0), UDim2.new(0, 654, 0, 0), Color3.fromRGB(61, 49, 34), Color3.fromRGB(241, 225, 191), 10)

local autoPanel = Instance.new("Frame")
autoPanel.Name = "SequencePanel"
autoPanel.BackgroundTransparency = 1
autoPanel.Position = UDim2.new(0, 0, 0, 96)
autoPanel.Size = UDim2.new(1, 0, 0, 39)
autoPanel.ClipsDescendants = true
autoPanel.Parent = content

local sequenceLabel = makeLabel(autoPanel, "GIAI ĐIỆU", UDim2.new(0, 70, 0, 18), UDim2.new(0, 0, 0, 0), Enum.Font.GothamBold, 10, COLORS.accent2)
sequenceLabel.TextWrapped = false

-- A dedicated clipping frame prevents multi-line pasted sequences from drawing
-- across the keyboard. The sequence remains editable and accepts spaces/newlines.
local sequenceClip = Instance.new("Frame")
sequenceClip.Name = "SequenceClip"
sequenceClip.Position = UDim2.new(0, 76, 0, 0)
sequenceClip.Size = UDim2.new(1, -76, 0, 36)
sequenceClip.BackgroundColor3 = COLORS.panel2
sequenceClip.BorderSizePixel = 0
sequenceClip.ClipsDescendants = true
sequenceClip.Parent = autoPanel
corner(sequenceClip, 10)

local sequenceStroke = stroke(sequenceClip, COLORS.accent, 0.7, 0.8)

autoBox = Instance.new("TextBox")
autoBox.Name = "SequenceInput"
autoBox.ClearTextOnFocus = false
autoBox.MultiLine = true
autoBox.TextWrapped = true
autoBox.TextYAlignment = Enum.TextYAlignment.Center
autoBox.Text = autoSequence
autoBox.PlaceholderText = "Nhập nốt: C4 D4 E4  •  Hợp âm: F4+A4+C5"
autoBox.Font = Enum.Font.Code
autoBox.TextSize = 11
autoBox:SetAttribute("PianoBaseTextSize", autoBox.TextSize)
autoBox.TextColor3 = COLORS.text
autoBox.PlaceholderColor3 = COLORS.muted
autoBox.BackgroundTransparency = 1
autoBox.BorderSizePixel = 0
autoBox.Position = UDim2.new(0, 0, 0, 0)
autoBox.Size = UDim2.new(1, 0, 1, 0)
autoBox.TextXAlignment = Enum.TextXAlignment.Left
autoBox.Parent = sequenceClip
local boxPadding = Instance.new("UIPadding")
boxPadding.PaddingLeft = UDim.new(0, 8)
boxPadding.PaddingRight = UDim.new(0, 8)
boxPadding.PaddingTop = UDim.new(0, 2)
boxPadding.PaddingBottom = UDim.new(0, 2)
boxPadding.Parent = autoBox

local hint = makeLabel(content, "75 phím A0–B6  •  Vuốt ngang để đổi quãng  •  PC: Z–M / Q–U / I–P", UDim2.new(1, 0, 0, 16), UDim2.new(0, 0, 1, -16), Enum.Font.Gotham, 9, COLORS.muted)
hint.TextXAlignment = Enum.TextXAlignment.Center
hint.TextWrapped = false
hint.Visible = false

-- Quiet context strip fills the workspace between tabs and the keybed without
-- putting controls on top of the keys. Song/chord tabs use the sequence editor here.
local workspaceHintPanel = Instance.new("Frame")
workspaceHintPanel.Name = "WorkspaceHintPanel"
workspaceHintPanel.BackgroundColor3 = COLORS.panel
workspaceHintPanel.BackgroundTransparency = 0.12
workspaceHintPanel.BorderSizePixel = 0
workspaceHintPanel.Visible = false
workspaceHintPanel.Parent = content
corner(workspaceHintPanel, 10)
stroke(workspaceHintPanel, COLORS.accent, 0.8, 0.78)
local workspaceHintLabel = makeLabel(workspaceHintPanel, "CHẠM PHÍM ĐỂ CHƠI  •  VUỐT NGANG ĐỂ ĐỔI QUÃNG", UDim2.new(1, -20, 1, 0), UDim2.new(0, 10, 0, 0), Enum.Font.GothamSemibold, 10, COLORS.muted)
workspaceHintLabel.TextXAlignment = Enum.TextXAlignment.Center
workspaceHintLabel.TextWrapped = true

-- Responsive workspace navigation: the same clean tab row is used on mobile and PC.
PianoUI.mobilePage = "CHƠI"
PianoUI.mobileNav = Instance.new("Frame")
PianoUI.mobileNav.Name = "PianoWorkspaceTabs"
PianoUI.mobileNav.BackgroundTransparency = 1
PianoUI.mobileNav.Position = UDim2.new(0, 0, 0, 0)
PianoUI.mobileNav.Size = UDim2.new(1, 0, 0, 32)
PianoUI.mobileNav.Visible = false
PianoUI.mobileNav.ZIndex = 40
PianoUI.mobileNav.Parent = content
PianoUI.mobilePlayTab = makeButton(PianoUI.mobileNav, "CHƠI", UDim2.new(0, 100, 0, 32), UDim2.new(0, 0, 0, 0), COLORS.accent, Color3.new(1, 1, 1), 10)
PianoUI.mobileSongTab = makeButton(PianoUI.mobileNav, "BẢN NHẠC", UDim2.new(0, 100, 0, 32), UDim2.new(0, 104, 0, 0), COLORS.panel2, COLORS.text, 10)
PianoUI.mobileChordTab = makeButton(PianoUI.mobileNav, "HỢP ÂM", UDim2.new(0, 100, 0, 32), UDim2.new(0, 208, 0, 0), COLORS.panel2, COLORS.text, 10)
PianoUI.mobileMetronomeTab = makeButton(PianoUI.mobileNav, "METRONOME", UDim2.new(0, 100, 0, 32), UDim2.new(0, 312, 0, 0), COLORS.panel2, COLORS.text, 10)
PianoUI.mobileRecordTab = makeButton(PianoUI.mobileNav, "THU ÂM", UDim2.new(0, 100, 0, 32), UDim2.new(0, 416, 0, 0), COLORS.panel2, COLORS.text, 10)
PianoUI.mobileGameTab = makeButton(PianoUI.mobileNav, "LUYỆN TẬP", UDim2.new(0, 100, 0, 32), UDim2.new(0, 520, 0, 0), COLORS.panel2, COLORS.text, 10)

-- Mini-game controls use the same physical keyboard and the original 37 source samples.
-- The classic controls are hidden while a mini-game is selected, not destroyed.
local gameControls = Instance.new("Frame")
gameControls.Name = "MiniGameControls"
gameControls.BackgroundTransparency = 1
gameControls.Position = UDim2.new(0, 0, 0, 27)
gameControls.Size = UDim2.new(1, 0, 0, 34)
gameControls.Visible = false
gameControls.Parent = content

local backToClassicBtn = makeButton(gameControls, "‹ QUAY LẠI", UDim2.new(0, 68, 1, 0), UDim2.new(0, 0, 0, 0), COLORS.panel2, COLORS.text, 10)
local gameModeBtn = makeButton(gameControls, "TÌM NỐT ▾", UDim2.new(0, 126, 1, 0), UDim2.new(0, 74, 0, 0), COLORS.panel2, COLORS.accent2, 10)
local startGameBtn = makeButton(gameControls, "▶ BẮT ĐẦU", UDim2.new(0, 84, 1, 0), UDim2.new(1, -84, 0, 0), COLORS.accent, Color3.new(1, 1, 1), 10)
local gameScoreLabel = makeLabel(gameControls, "ĐIỂM 0", UDim2.new(0, 105, 1, 0), UDim2.new(1, -190, 0, 0), Enum.Font.GothamBold, 10, COLORS.cyan)
gameScoreLabel.TextXAlignment = Enum.TextXAlignment.Right

local gamePanel = Instance.new("Frame")
gamePanel.Name = "MiniGameStatusPanel"
gamePanel.Position = UDim2.new(0, 0, 0, 82)
gamePanel.Size = UDim2.new(1, 0, 0, 62)
gamePanel.BackgroundColor3 = COLORS.panel
gamePanel.BorderSizePixel = 0
gamePanel.Visible = false
gamePanel.Parent = content
corner(gamePanel, 8)
stroke(gamePanel, COLORS.cyan, 0.8, 0.65)
local gamePrompt = makeLabel(gamePanel, "TRÒ CHƠI", UDim2.new(1, -18, 0, 27), UDim2.new(0, 9, 0, 3), Enum.Font.GothamBold, 14, COLORS.accent2)
gamePrompt.TextXAlignment = Enum.TextXAlignment.Center
local gameSubPrompt = makeLabel(gamePanel, "Chọn chế độ, bấm BẮT ĐẦU rồi chạm phím đàn.", UDim2.new(1, -18, 0, 22), UDim2.new(0, 9, 0, 32), Enum.Font.Gotham, 10, COLORS.muted)
gameSubPrompt.TextXAlignment = Enum.TextXAlignment.Center

autoBox:GetPropertyChangedSignal("Text"):Connect(function()
    -- Editing sequence should only affect Classic playback.
    preferRecordedTake = false
end)

local noteByName = {}
local function addNoteAlias(alias, note)
    if alias and alias ~= "" then
        noteByName[string.upper(alias)] = note
    end
end

local FLAT_ALIASES = {
    ["C#"] = "DB", ["D#"] = "EB", ["F#"] = "GB",
    ["G#"] = "AB", ["A#"] = "BB",
}
for _, n in ipairs(notes) do
    addNoteAlias(n.name, n)
    addNoteAlias(SOLFEGE_ASCII[n.pitchClass] .. tostring(n.octave), n)
    addNoteAlias(SOLFEGE_NAMES[n.pitchClass] .. tostring(n.octave), n)
    local flat = FLAT_ALIASES[n.pitchName]
    if flat then addNoteAlias(flat .. tostring(n.octave), n) end
    if n.pitchName == "D#" then
        addNoteAlias("MIB" .. tostring(n.octave), n)
        addNoteAlias("Eb" .. tostring(n.octave), n)
    end
    if n.pitchName == "A#" then
        addNoteAlias("SIB" .. tostring(n.octave), n)
        addNoteAlias("Bb" .. tostring(n.octave), n)
    end
end

local function normalizeSequenceToken(token)
    -- Accept international note names (C4, F#4, Bb4), plus legacy Vietnamese aliases.
    local replacements = {
        {"Mib", "MIB"}, {"mib", "MIB"}, {"MIB", "MIB"},
        {"Sib", "SIB"}, {"sib", "SIB"}, {"SIB", "SIB"},
        {"Đô", "DO"}, {"đô", "DO"}, {"ĐÔ", "DO"}, {"Đo", "DO"}, {"đo", "DO"},
        {"Rê", "RE"}, {"rê", "RE"}, {"RÊ", "RE"}, {"Re", "RE"}, {"re", "RE"},
        {"Fa", "FA"}, {"fa", "FA"}, {"Sol", "SOL"}, {"sol", "SOL"},
        {"La", "LA"}, {"la", "LA"}, {"Si", "SI"}, {"si", "SI"},
    }
    for _, replacement in ipairs(replacements) do
        token = token:gsub(replacement[1], replacement[2])
    end
    token = token:gsub("♭", "B"):gsub("♯", "#")
    token = string.upper(token)
    token = token:gsub("^MIB", "RE#")
    token = token:gsub("^SIB", "LA#")
    token = token:gsub("^DO", "DO")
    token = token:gsub("^RE", "RE")
    token = token:gsub("%-%s*", "#")
    return token
end

local function parseSequence()
    -- One token is one timed event. Use + to trigger a chord simultaneously:
    -- F4+A4+C5. A regular token such as F4 remains a single note.
    local result, invalid = {}, {}
    for token in string.gmatch(autoBox.Text, "[^%s,]+") do
        local eventNotes = {}
        local tokenInvalid = false
        for part in string.gmatch(token, "[^+]+") do
            local normalized = normalizeSequenceToken(part)
            local note = noteByName[normalized]
            if note then
                table.insert(eventNotes, note)
            else
                tokenInvalid = true
                table.insert(invalid, part)
            end
        end
        if not tokenInvalid and #eventNotes > 0 then
            table.insert(result, {notes = eventNotes})
        end
    end
    return result, invalid
end

-- Normalize note names without destroying chord separators.
-- International notation is displayed and accepted, e.g. F4+A4+C5.
-- Vietnamese solfege aliases remain accepted for compatibility.
autoBox.FocusLost:Connect(function()
    local formatted = {}
    for token in string.gmatch(autoBox.Text, "[^%s,]+") do
        local formattedParts = {}
        for part in string.gmatch(token, "[^+]+") do
            local note = noteByName[normalizeSequenceToken(part)]
            table.insert(formattedParts, note and note.displayName or part)
        end
        table.insert(formatted, table.concat(formattedParts, "+"))
    end
    autoBox.Text = table.concat(formatted, " ")
end)

local function stopPlayback(showStatus)
    sequenceToken += 1
    playing = false
    paused = false
    currentPlaybackMode = nil
    pauseBtn.Text = PianoUI.mobilePortraitLayout and "Ⅱ" or (scale.Scale < 0.62 and "Ⅱ" or "Ⅱ TẠM DỪNG")
    -- STOP means immediate silence for piano voices; the metronome is controlled separately.
    for _, pool in pairs(samplePools) do
        for _, snd in ipairs(pool) do
            if snd and snd.Parent then
                voiceReleaseTokens[snd] = (voiceReleaseTokens[snd] or 0) + 1
                sustainedVoices[snd] = nil
                PianoUI.sostenutoVoices[snd] = nil
                local fade = voiceState.fadeTweens[snd]
                if fade then pcall(function() fade:Cancel() end); voiceState.fadeTweens[snd] = nil end
                pcall(function() snd:Stop(); snd.Volume = effectiveVoiceVolume(voiceState.velocities[snd], voiceState.semitones[snd]) end)
            end
        end
    end
    if showStatus ~= false then
        status.Text = "ĐÃ DỪNG  •  Sẵn sàng"
        status.TextColor3 = COLORS.muted
    end
end

-- MINI-GAME ENGINE ---------------------------------------------------------
-- 1) Note Hunt: identify and tap the prompted note (10 rounds).
-- 2) Memory Melody: listen to a short sequence, then repeat it (3 rounds).
-- 3) Chord Challenge: tap every note listed in the target chord (5 rounds).
local GAME_MODES = {"TÌM NỐT", "NHỚ GIAI ĐIỆU", "THỬ THÁCH HỢP ÂM"}
local gameModeIndex = 1
local viewMode = "classic"
local controlPanelVisible = true
local gameRunning = false
local gameCanInput = false
local gameScore = 0
local gameRound = 0
local gameToken = 0
local gameTarget = nil
local gameExpected = {}
local gameInputIndex = 1
local gamePending = {}
local gamePendingCount = 0
local runMemoryRound

local function updateGameScore()
    gameScoreLabel.Text = "ĐIỂM " .. tostring(gameScore)
end

local function updateGameModeButton()
    gameModeBtn.Text = scale.Scale < 0.62
        and ({"TÌM NỐT", "NHỚ NỐT", "HỢP ÂM"})[gameModeIndex]
        or (GAME_MODES[gameModeIndex] .. " ▾")
end

local function cancelMiniGame()
    gameToken += 1
    gameRunning = false
    gameCanInput = false
    gameTarget = nil
    gameExpected = {}
    gamePending = {}
    gamePendingCount = 0
    startGameBtn.Text = scale.Scale < 0.62 and "▶" or "▶ BẮT ĐẦU"
end

local function finishMiniGame(message)
    gameRunning = false
    gameCanInput = false
    gamePrompt.Text = message or "HOÀN THÀNH LƯỢT"
    gameSubPrompt.Text = "Tổng điểm: " .. tostring(gameScore) .. "  •  Bấm BẮT ĐẦU để chơi lại."
    startGameBtn.Text = scale.Scale < 0.62 and "↻" or "↻ CHƠI LẠI"
    status.Text = "ĐÃ KẾT THÚC TRÒ CHƠI  •  " .. tostring(gameScore) .. " ĐIỂM"
    status.TextColor3 = COLORS.accent2
end

local function randomMiddleNote()
    -- C4 through C5: a practical 13-note range visible in the default piano area.
    return PianoUI.notesBySemi[math.random(12, 24)]
end

local function chooseNextHuntTarget()
    gameTarget = randomMiddleNote()
    gameCanInput = true
    gamePrompt.Text = "TÌM NỐT  •  " .. gameTarget.displayName
    gameSubPrompt.Text = "Chạm phím khớp  •  Lượt " .. gameRound .. "/10"
end

local function chooseChord()
    local chordChoices = {
        {12, 16, 19}, -- C major
        {17, 21, 24}, -- F major
        {19, 23, 26}, -- G major
        {14, 17, 21}, -- D minor
        {16, 19, 23}, -- E minor
    }
    local sourceChord = chordChoices[math.random(1, #chordChoices)]
    local picked = {}
    for _, semi in ipairs(sourceChord) do table.insert(picked, PianoUI.notesBySemi[semi]) end
    return picked
end

local function beginChordRound()
    gamePending = {}
    gamePendingCount = 0
    local chord = chooseChord()
    local names = {}
    for _, note in ipairs(chord) do
        gamePending[note.semi] = true
        gamePendingCount += 1
        table.insert(names, note.displayName)
    end
    gameCanInput = true
    gamePrompt.Text = "HỢP ÂM  •  " .. table.concat(names, " + ")
    gameSubPrompt.Text = "Chạm đủ 3 nốt theo thứ tự bất kỳ  •  Lượt " .. gameRound .. "/5"
end

runMemoryRound = function(token)
    if token ~= gameToken or not gameRunning then return end
    local sequenceLength = gameRound + 2
    gameExpected = {}
    for _ = 1, sequenceLength do
        table.insert(gameExpected, randomMiddleNote())
    end
    gameInputIndex = 1
    gameCanInput = false
    gamePrompt.Text = "NGHE KỸ  •  LƯỢT " .. gameRound .. "/3"
    gameSubPrompt.Text = "Hãy ghi nhớ " .. tostring(sequenceLength) .. " nốt..."
    task.spawn(function()
        for _, note in ipairs(gameExpected) do
            if token ~= gameToken or not gameRunning then return end
            playNote(note, "game")
            task.wait(0.58)
        end
        if token ~= gameToken or not gameRunning then return end
        gameCanInput = true
        gamePrompt.Text = "LẶP LẠI GIAI ĐIỆU"
        gameSubPrompt.Text = "Chạm nốt 1 / " .. tostring(#gameExpected)
    end)
end

local function startMiniGame()
    if isRecording then finishRecording() end
    stopPlayback(false)
    cancelMiniGame()
    gameToken += 1
    local token = gameToken
    gameRunning = true
    gameCanInput = false
    gameScore = 0
    gameRound = 1
    gameTarget = nil
    gameExpected = {}
    gameInputIndex = 1
    gamePending = {}
    gamePendingCount = 0
    updateGameScore()
    startGameBtn.Text = scale.Scale < 0.62 and "↻" or "↻ CHƠI LẠI"
    status.Text = "TRÒ CHƠI  •  " .. GAME_MODES[gameModeIndex]
    status.TextColor3 = COLORS.cyan

    if gameModeIndex == 1 then
        chooseNextHuntTarget()
    elseif gameModeIndex == 2 then
        runMemoryRound(token)
    else
        beginChordRound()
    end
end

handleMiniGameInput = function(note)
    if viewMode ~= "games" or not gameRunning or not gameCanInput or not note then return end

    if gameModeIndex == 1 then
        if gameTarget and note.semi == gameTarget.semi then
            gameScore += 10
            gameRound += 1
            updateGameScore()
            if gameRound > 10 then
                finishMiniGame("TỐT LẮM!  •  ĐÃ TÌM ĐỦ NỐT")
            else
                chooseNextHuntTarget()
            end
        else
            gameScore = math.max(0, gameScore - 2)
            updateGameScore()
            gameSubPrompt.Text = "Chưa đúng — nốt cần tìm là " .. (gameTarget and gameTarget.displayName or "?") .. "  •  −2 điểm"
        end

    elseif gameModeIndex == 2 then
        local expectedNote = gameExpected[gameInputIndex]
        if not expectedNote then return end
        if note.semi == expectedNote.semi then
            gameInputIndex += 1
            if gameInputIndex > #gameExpected then
                gameScore += 15 * gameRound
                updateGameScore()
                if gameRound >= 3 then
                    finishMiniGame("TRÍ NHỚ TUYỆT VỜI!  •  HOÀN THÀNH GIAI ĐIỆU")
                else
                    gameRound += 1
                    gamePrompt.Text = "CHÍNH XÁC!  •  LƯỢT " .. gameRound .. "/3"
                    gameSubPrompt.Text = "Giai điệu tiếp theo sẽ dài hơn..."
                    local token = gameToken
                    task.delay(0.65, function()
                        if token == gameToken and gameRunning then runMemoryRound(token) end
                    end)
                end
            else
                gameSubPrompt.Text = "Đúng rồi  •  Nốt " .. gameInputIndex .. " / " .. #gameExpected
            end
        else
            gameScore = math.max(0, gameScore - 2)
            updateGameScore()
            gameInputIndex = 1
            gameCanInput = false
            gameSubPrompt.Text = "Sai nốt (−2). Hãy nghe lại..."
            local token = gameToken
            task.delay(0.75, function()
                if token == gameToken and gameRunning then runMemoryRound(token) end
            end)
        end

    elseif gameModeIndex == 3 then
        if gamePending[note.semi] then
            gamePending[note.semi] = nil
            gamePendingCount -= 1
            gameScore += 3
            updateGameScore()
            if gamePendingCount <= 0 then
                gameRound += 1
                if gameRound > 5 then
                    finishMiniGame("BẬC THẦY HỢP ÂM!  •  HOÀN THÀNH THỬ THÁCH")
                else
                    gamePrompt.Text = "ĐÃ CHƠI ĐÚNG HỢP ÂM!"
                    gameSubPrompt.Text = "Chuẩn bị hợp âm tiếp theo...  •  Lượt " .. gameRound .. "/5"
                    local token = gameToken
                    task.delay(0.55, function()
                        if token == gameToken and gameRunning then beginChordRound() end
                    end)
                end
            else
                gameSubPrompt.Text = tostring(gamePendingCount) .. " nốt hợp âm còn lại"
            end
        else
            gameScore = math.max(0, gameScore - 1)
            updateGameScore()
            gameSubPrompt.Text = "Nốt đó không thuộc hợp âm này  •  −1 điểm"
        end
    end
end

local function setViewMode(nextMode)
    if nextMode ~= "classic" and nextMode ~= "games" then return end
    if nextMode ~= viewMode then
        cancelMiniGame()
        stopPlayback(false)
    end
    viewMode = nextMode
    local classic = viewMode == "classic"
    controls.Visible = classic and controlPanelVisible
    instrumentControls.Visible = classic and controlPanelVisible
    autoPanel.Visible = classic and controlPanelVisible
    status.Visible = controlPanelVisible
    volumeLabel.Visible = controlPanelVisible
    PianoUI.volumeSliderTrack.Visible = controlPanelVisible
    gameControls.Visible = not classic
    gamePanel.Visible = not classic
    classicTab.BackgroundColor3 = classic and COLORS.accent or COLORS.panel2
    classicTab.TextColor3 = classic and Color3.new(1, 1, 1) or COLORS.text
    gamesTab.BackgroundColor3 = (not classic) and COLORS.cyan or COLORS.panel2
    gamesTab.TextColor3 = (not classic) and COLORS.deep or COLORS.text
    hint.Text = classic
        and "PC: Z–M / Q–U / I–P  •  Giữ âm, lực phím, dịch âm, nhịp và máy đếm nhịp"
        or "TRÒ CHƠI  •  Chạm các phím bên dưới  •  QUAY LẠI để về đàn"
    hint.TextColor3 = classic and COLORS.muted or COLORS.cyan
    if classic then
        status.Text = "CỔ ĐIỂN  •  Chạm phím để đàn"
        status.TextColor3 = COLORS.muted
    else
        cancelMiniGame()
        gamePrompt.Text = "TRÒ CHƠI"
        gameSubPrompt.Text = "Chọn chế độ, bấm BẮT ĐẦU rồi chạm phím đàn."
        updateGameModeButton()
        updateGameScore()
        status.Text = "CHỌN TRÒ CHƠI  •  Có ba chế độ"
        status.TextColor3 = COLORS.cyan
    end
    if PianoUI.fitToScreen then PianoUI.fitToScreen() end
end

local function goClassic()
    if viewMode ~= "classic" then setViewMode("classic") end
end
local function goGames()
    if viewMode ~= "games" then setViewMode("games") end
end
classicTab.Activated:Connect(goClassic)
gamesTab.Activated:Connect(goGames)
backToClassicBtn.Activated:Connect(goClassic)
PianoUI.mobileGameTab.Activated:Connect(goGames)
-- Some executor/mobile UI layers occasionally fail to forward Activated;
-- MouseButton1Click is a safe secondary route, guarded against duplicate effects.
gameModeBtn.Activated:Connect(function()
    cancelMiniGame()
    gameModeIndex = gameModeIndex % #GAME_MODES + 1
    updateGameModeButton()
    gamePrompt.Text = GAME_MODES[gameModeIndex]
    if gameModeIndex == 1 then
        gameSubPrompt.Text = "Tìm đúng nốt được yêu cầu. 10 lượt; đúng được +10 điểm."
    elseif gameModeIndex == 2 then
        gameSubPrompt.Text = "Nghe giai điệu rồi chơi lại bằng trí nhớ."
    else
        gameSubPrompt.Text = "Chạm đủ ba nốt của hợp âm theo thứ tự bất kỳ."
    end
    startGameBtn.Text = scale.Scale < 0.62 and "▶" or "▶ BẮT ĐẦU"
end)
startGameBtn.Activated:Connect(startMiniGame)

finishRecording = function()
    if not isRecording then return false end
    -- A held key ends at the moment recording stops; do not let it gain extra
    -- duration because the player keeps holding it after pressing Stop.
    local stopElapsed = math.max(0, os.clock() - recordStartedAt)
    for snd, recordedEvent in pairs(voiceState.recordedEvents) do
        if recordedEvent and not recordedEvent._closed then
            recordedEvent.duration = math.clamp(
                stopElapsed - (tonumber(recordedEvent.t) or 0),
                0.04,
                MAX_RECORDED_GAP
            )
            recordedEvent._closed = true
        end
        voiceState.recordedEvents[snd] = nil
    end
    isRecording = false
    recordBtn.Text = PianoUI.mobilePortraitLayout and "● REC" or (scale.Scale < 0.62 and "●" or "● THU")
    recordBtn.BackgroundColor3 = COLORS.panel2
    recordBtn.TextColor3 = COLORS.red

    recordedTake = recordBuffer
    recordBuffer = {}
    preferRecordedTake = #recordedTake > 0

    if #recordedTake > 0 then
        status.Text = "ĐÃ LƯU BẢN THU  •  " .. tostring(#recordedTake) .. " NỐT — BẤM PHÁT ĐỂ NGHE"
        status.TextColor3 = COLORS.accent2
    else
        status.Text = "BẢN THU TRỐNG  •  Hãy đàn vài nốt rồi bấm DỪNG"
        status.TextColor3 = COLORS.muted
    end
    return true
end

local function startRecording()
    stopPlayback(false)
    recordBuffer = {}
    table.clear(voiceState.recordedEvents)
    recordStartedAt = os.clock()
    isRecording = true
    preferRecordedTake = false
    recordBtn.Text = PianoUI.mobilePortraitLayout and "● REC" or (scale.Scale < 0.62 and "● REC" or "● ĐANG THU...")
    recordBtn.BackgroundColor3 = Color3.fromRGB(183, 45, 57)
    recordBtn.TextColor3 = Color3.new(1, 1, 1)
    status.Text = "● ĐANG THU  •  Chạm các phím đàn"
    status.TextColor3 = COLORS.red
end

local function waitPlaybackTime(duration, token)
    local remaining = math.max(0, duration)
    while remaining > 0 and playing and sequenceToken == token do
        if paused then
            task.wait(0.05)
        else
            local step = math.min(0.04, remaining)
            local before = os.clock()
            task.wait(step)
            local elapsed = os.clock() - before
            -- Do not consume the remaining note gap while a pause is active.
            if not paused then
                remaining = remaining - math.max(0, elapsed)
            end
        end
    end
end

local function scheduleRecordedRelease(snd, duration, playbackToken)
    if not snd or not duration then return end
    local voiceToken = voiceReleaseTokens[snd] or 0
    local remaining = math.clamp(tonumber(duration) or 0.18, 0.04, MAX_RECORDED_GAP) / math.max(baseSpeed, 0.1)
    task.spawn(function()
        while remaining > 0 and sequenceToken == playbackToken do
            if paused then
                task.wait(0.04)
            else
                local step = math.min(0.03, remaining)
                local before = os.clock()
                task.wait(step)
                if not paused then remaining -= math.max(0, os.clock() - before) end
            end
        end
        if remaining <= 0 and sequenceToken == playbackToken
            and (voiceReleaseTokens[snd] or 0) == voiceToken then
            releaseManualVoice({sound = snd})
        end
    end)
end

local function startPlayback(events, mode)
    stopPlayback(false)
    sequenceToken += 1
    local myToken = sequenceToken
    playing = true
    paused = false
    currentPlaybackMode = mode
    pauseBtn.Text = PianoUI.mobilePortraitLayout and "Ⅱ" or (scale.Scale < 0.62 and "Ⅱ" or "Ⅱ TẠM DỪNG")

    task.spawn(function()
        repeat
        for index, event in ipairs(events) do
            if not playing or sequenceToken ~= myToken then break end
            while paused and playing and sequenceToken == myToken do
                task.wait(0.05)
            end
            if not playing or sequenceToken ~= myToken then break end

            -- Chord events contain several notes and trigger their audio voices
            -- in the same scheduler step; old single-note events remain supported.
            if event.notes then
                for _, chordNote in ipairs(event.notes) do
                    local chordSound = playNote(chordNote, mode == "recorded" and "recorded" or "sequence", event.velocity, event.transpose)
                    if mode == "recorded" then scheduleRecordedRelease(chordSound, event.duration, myToken) end
                end
            elseif event.note then
                local playedSound = playNote(event.note, mode == "recorded" and "recorded" or "sequence", event.velocity, event.transpose)
                if mode == "recorded" then scheduleRecordedRelease(playedSound, event.duration, myToken) end
            end

            if index < #events then
                local gap
                if mode == "recorded" then
                    local currentTime = tonumber(event.t) or 0
                    local nextTime = tonumber(events[index + 1].t) or currentTime
                    gap = math.clamp(nextTime - currentTime, 0.04, MAX_RECORDED_GAP)
                else
                    gap = 60 / math.max(tempoBpm, 40)
                end
                waitPlaybackTime(gap / math.max(baseSpeed, 0.1), myToken)
            end
        end
        until not loopPlayback or not playing or sequenceToken ~= myToken

        if sequenceToken == myToken then
            playing = false
            paused = false
            currentPlaybackMode = nil
            pauseBtn.Text = PianoUI.mobilePortraitLayout and "Ⅱ" or (scale.Scale < 0.62 and "Ⅱ" or "Ⅱ TẠM DỪNG")
            if mode == "recorded" then
                status.Text = "HOÀN TẤT  •  Đã thu xong bản nhạc"
            else
                status.Text = "HOÀN TẤT  •  Phát tự động xong"
            end
            status.TextColor3 = COLORS.accent2
        end
    end)
end

playBtn.Activated:Connect(function()
    if playing and paused then
        paused = false
        pauseBtn.Text = PianoUI.mobilePortraitLayout and "Ⅱ" or (scale.Scale < 0.62 and "Ⅱ" or "Ⅱ TẠM DỪNG")
        status.Text = "TIẾP TỤC  •  Đang phát nhạc"
        status.TextColor3 = COLORS.green
        return
    end
    if isRecording then
        status.Text = "ĐANG THU  •  Bấm DỪNG để lưu bản thu"
        status.TextColor3 = COLORS.red
        return
    end

    if preferRecordedTake and #recordedTake > 0 then
        local events = {}
        for _, saved in ipairs(recordedTake) do
            local note = noteByName[saved.name]
            if note then
                table.insert(events, {note = note, t = saved.t, velocity = saved.velocity, transpose = saved.transpose, duration = saved.duration})
            end
        end
        if #events > 0 then
            startPlayback(events, "recorded")
            return
        end
    end

    local seq, invalid = parseSequence()
    if #invalid > 0 then
        local shown = {}
        for i = 1, math.min(3, #invalid) do table.insert(shown, invalid[i]) end
        status.Text = "NỐT KHÔNG HỢP LỆ  •  " .. table.concat(shown, ", ")
        status.TextColor3 = COLORS.red
        return
    end
    if #seq == 0 then
        status.Text = "NHẬP NỐT  •  Ví dụ: C4 D4 E4  |  Hợp âm: F4+A4+C5"
        status.TextColor3 = COLORS.red
        return
    end

    local events = {}
    for _, event in ipairs(seq) do
        table.insert(events, {notes = event.notes, t = 0})
    end
    startPlayback(events, "auto")
end)

pauseBtn.Activated:Connect(function()
    if playing then
        paused = not paused
        pauseBtn.Text = PianoUI.mobilePortraitLayout and (paused and "▶" or "Ⅱ") or (scale.Scale < 0.62 and (paused and "▶" or "Ⅱ") or (paused and "▶ TIẾP TỤC" or "Ⅱ TẠM DỪNG"))
        status.Text = paused and "ĐÃ TẠM DỪNG  •  Bản nhạc" or "ĐANG PHÁT  •  Bản nhạc"
        status.TextColor3 = paused and COLORS.accent2 or COLORS.green
    end
end)

stopBtn.Activated:Connect(function()
    stopPlayback(false)
    if isRecording then
        finishRecording()
    else
        status.Text = "ĐÃ DỪNG  •  Sẵn sàng"
        status.TextColor3 = COLORS.muted
    end
end)

recordBtn.Activated:Connect(function()
    if isRecording then
        finishRecording()
    else
        startRecording()
    end
end)

replayBtn.Activated:Connect(function()
    if isRecording then
        status.Text = "ĐANG THU  •  Bấm DỪNG trước khi phát lại"
        status.TextColor3 = COLORS.red
        return
    end
    if #recordedTake == 0 then
        status.Text = "CHƯA CÓ BẢN THU  •  Bấm THU rồi chơi vài nốt"
        status.TextColor3 = COLORS.muted
        return
    end
    local events = {}
    for _, saved in ipairs(recordedTake) do
        local note = noteByName[saved.name]
        if note then table.insert(events, {note = note, t = saved.t, velocity = saved.velocity, transpose = saved.transpose, duration = saved.duration}) end
    end
    if #events > 0 then startPlayback(events, "recorded") end
end)

sustainBtn.Activated:Connect(function()
    sustainEnabled = not sustainEnabled
    sustainBtn.Text = PianoUI.mobilePortraitLayout and (sustainEnabled and "SUS ✓" or "SUS") or (scale.Scale < 0.62 and (sustainEnabled and "GIỮ✓" or "GIỮ") or (sustainEnabled and "GIỮ BẬT" or "GIỮ TẮT"))
    sustainBtn.TextColor3 = sustainEnabled and COLORS.cyan or COLORS.accent2
    PianoUI.setButtonBaseColor(sustainBtn, sustainEnabled and Color3.fromRGB(64, 91, 60) or Color3.fromRGB(61, 49, 34))
    if not sustainEnabled then dampSustainedVoices() end
    status.Text = sustainEnabled and "BÀN ĐẠP GIỮ ÂM  •  BẬT" or "BÀN ĐẠP GIỮ ÂM  •  TẮT"
    status.TextColor3 = COLORS.accent2
end)

PianoUI.sostenutoBtn.Activated:Connect(function()
    PianoUI.sostenutoEnabled = not PianoUI.sostenutoEnabled
    if PianoUI.sostenutoEnabled then
        table.clear(PianoUI.sostenutoVoices)
        -- Sostenuto captures only notes physically held at the instant it is pressed.
        for _, record in pairs(activeInputVoices) do
            if record and record.sound and record.sound.Parent and record.sound.IsPlaying then
                PianoUI.sostenutoVoices[record.sound] = true
            end
        end
        for _, record in pairs(activeKeyboardVoices) do
            if record and record.sound and record.sound.Parent and record.sound.IsPlaying then
                PianoUI.sostenutoVoices[record.sound] = true
            end
        end
    else
        table.clear(PianoUI.sostenutoVoices)
        if not sustainEnabled then dampSustainedVoices() end
    end
    PianoUI.sostenutoBtn.Text = PianoUI.mobilePortraitLayout and (PianoUI.sostenutoEnabled and "SOS ✓" or "SOS") or (PianoUI.sostenutoEnabled and "SOS BẬT" or "SOS TẮT")
    PianoUI.sostenutoBtn.TextColor3 = PianoUI.sostenutoEnabled and COLORS.cyan or COLORS.accent2
    PianoUI.setButtonBaseColor(PianoUI.sostenutoBtn, PianoUI.sostenutoEnabled and Color3.fromRGB(64, 91, 60) or Color3.fromRGB(61, 49, 34))
    status.Text = PianoUI.sostenutoEnabled and "SOSTENUTO  •  ĐANG GIỮ CÁC NỐT ĐÃ CHỌN" or "SOSTENUTO  •  TẮT"
    status.TextColor3 = COLORS.accent2
end)

PianoUI.roomBtn.Activated:Connect(function()
    PianoUI.roomEnabled = not PianoUI.roomEnabled
    PianoUI.roomReverb.Enabled = PianoUI.roomEnabled
    PianoUI.roomBtn.Text = PianoUI.mobilePortraitLayout and (PianoUI.roomEnabled and "ROOM ✓" or "ROOM") or (PianoUI.roomEnabled and "PHÒNG BẬT" or "PHÒNG TẮT")
    PianoUI.roomBtn.TextColor3 = PianoUI.roomEnabled and COLORS.cyan or COLORS.accent2
    PianoUI.setButtonBaseColor(PianoUI.roomBtn, PianoUI.roomEnabled and Color3.fromRGB(64, 91, 60) or Color3.fromRGB(61, 49, 34))
    status.Text = PianoUI.roomEnabled and "CỘNG HƯỞNG PHÒNG  •  BẬT" or "CỘNG HƯỞNG PHÒNG  •  TẮT"
    status.TextColor3 = COLORS.accent2
end)

softBtn.Activated:Connect(function()
    softEnabled = not softEnabled
    softBtn.Text = PianoUI.mobilePortraitLayout and (softEnabled and "SOFT ✓" or "SOFT") or (scale.Scale < 0.62 and (softEnabled and "ÊM✓" or "ÊM") or (softEnabled and "ÊM BẬT" or "ÊM TẮT"))
    softBtn.TextColor3 = softEnabled and COLORS.cyan or COLORS.accent2
    for _, snd in ipairs(sounds) do
        if snd and snd.Parent and snd ~= metronomeSound then
            pcall(function() snd.Volume = effectiveVoiceVolume(voiceState.velocities[snd], voiceState.semitones[snd]) end)
        end
    end
    status.Text = softEnabled and "BÀN ĐẠP ÊM  •  BẬT" or "BÀN ĐẠP ÊM  •  TẮT"
    status.TextColor3 = COLORS.accent2
end)

dynamicsBtn.Activated:Connect(function()
    dynamicsIndex = dynamicsIndex % #dynamicsOptions + 1
    dynamicsBtn.Text = PianoUI.mobilePortraitLayout and ("VEL " .. tostring(dynamicsIndex)) or (scale.Scale < 0.62 and ("L" .. tostring(dynamicsIndex)) or ("LỰC " .. tostring(dynamicsIndex) .. "/4"))
    for _, snd in ipairs(sounds) do
        if snd and snd.Parent and snd ~= metronomeSound then
            pcall(function() snd.Volume = effectiveVoiceVolume(voiceState.velocities[snd], voiceState.semitones[snd]) end)
        end
    end
    status.Text = "LỰC PHÍM  •  " .. dynamicsOptions[dynamicsIndex].label
    status.TextColor3 = COLORS.accent2
end)

local function updateTransposeLabel()
    transposeLabel.Text = PianoUI.mobilePortraitLayout and string.format("%+d", transposeSemitones) or (scale.Scale < 0.62 and string.format("%+d", transposeSemitones) or string.format("%+d BT", transposeSemitones))
    status.Text = "DỊCH TÔNG  •  " .. string.format("%+d bán âm", transposeSemitones)
    status.TextColor3 = COLORS.accent2
end
transposeDownBtn.Activated:Connect(function()
    transposeSemitones = math.max(-12, transposeSemitones - 1)
    updateTransposeLabel()
end)
transposeUpBtn.Activated:Connect(function()
    transposeSemitones = math.min(12, transposeSemitones + 1)
    updateTransposeLabel()
end)
transposeLabel.Activated:Connect(function()
    transposeSemitones = 0
    updateTransposeLabel()
end)

PianoUI.tempoOptions = {60, 72, 80, 90, 100, 110, 120, 132, 144, 160, 180}
PianoUI.tempoIndex = 5
tempoBtn.Activated:Connect(function()
    PianoUI.tempoIndex = PianoUI.tempoIndex % #PianoUI.tempoOptions + 1
    tempoBpm = PianoUI.tempoOptions[PianoUI.tempoIndex]
    tempoBtn.Text = PianoUI.mobilePortraitLayout and ("BPM " .. tostring(tempoBpm)) or (scale.Scale < 0.62 and tostring(tempoBpm) or ("NHỊP " .. tostring(tempoBpm)))
end)

metronomeBtn.Activated:Connect(function()
    metronomeEnabled = not metronomeEnabled
    metronomeBtn.Text = PianoUI.mobilePortraitLayout and (metronomeEnabled and "MET ✓" or "MET") or (scale.Scale < 0.62 and (metronomeEnabled and "GÕ✓" or "GÕ") or (metronomeEnabled and "GÕ BẬT" or "GÕ TẮT"))
    metronomeBtn.TextColor3 = metronomeEnabled and COLORS.cyan or COLORS.accent2
    metronomeLoopGeneration += 1
    local myToken = metronomeLoopGeneration
    if metronomeEnabled then
        task.spawn(function()
            local beat = 0
            while metronomeEnabled and not shuttingDown and gui.Parent and metronomeLoopGeneration == myToken do
                beat += 1
                playMetronomeTick(beat)
                task.wait(60 / math.max(tempoBpm, 40))
            end
        end)
        status.Text = "MÁY ĐẾM NHỊP  •  " .. tostring(tempoBpm) .. " nhịp/phút"
        status.TextColor3 = COLORS.accent2
    else
        pcall(function() metronomeSound:Stop() end)
        status.Text = "MÁY ĐẾM NHỊP  •  TẮT"
        status.TextColor3 = COLORS.muted
    end
end)

loopBtn.Activated:Connect(function()
    loopPlayback = not loopPlayback
    loopBtn.Text = PianoUI.mobilePortraitLayout and (loopPlayback and "LOOP ✓" or "LOOP") or (scale.Scale < 0.62 and (loopPlayback and "LẶP✓" or "LẶP") or (loopPlayback and "LẶP BẬT" or "LẶP TẮT"))
    loopBtn.TextColor3 = loopPlayback and COLORS.cyan or COLORS.text
    status.Text = loopPlayback and "LẶP BẢN PHÁT  •  BẬT" or "LẶP BẢN PHÁT  •  TẮT"
    status.TextColor3 = COLORS.accent2
end)

copyTakeBtn.Activated:Connect(function()
    if #recordedTake == 0 then
        status.Text = "CHƯA CÓ BẢN THU  •  Hãy thu một đoạn trước"
        status.TextColor3 = COLORS.muted
        return
    end
    local exported = {}
    for _, saved in ipairs(recordedTake) do
        local note = noteByName[saved.name]
        if note then table.insert(exported, note.displayName) end
    end
    local takeText = table.concat(exported, " ")
    local copied = false
    if type(setclipboard) == "function" then copied = pcall(setclipboard, takeText) end
    if copied then
        status.Text = "ĐÃ CHÉP BẢN THU  •  Dán vào ô GIAI ĐIỆU"
        status.TextColor3 = COLORS.green
    else
        autoBox.Text = takeText
        preferRecordedTake = false
        status.Text = "ĐÃ ĐƯA BẢN THU VÀO GIAI ĐIỆU  •  Chọn và sao chép văn bản"
        status.TextColor3 = COLORS.accent2
    end
end)

PianoUI.speeds = PianoUI.SPEED_OPTIONS
PianoUI.speedIndex = 3
function PianoUI.updateSpeedSelection(nextIndex)
    PianoUI.speedIndex = math.clamp(nextIndex, 1, #PianoUI.speeds)
    baseSpeed = PianoUI.speeds[PianoUI.speedIndex]
    for index, button in ipairs(PianoUI.speedButtons) do
        local selected = index == PianoUI.speedIndex
        PianoUI.setButtonBaseColor(button, selected and Color3.fromRGB(153, 105, 36) or COLORS.panel2)
        button.TextColor3 = selected and Color3.fromRGB(255, 239, 198) or COLORS.text
        local outline = button:FindFirstChildOfClass("UIStroke")
        if outline then
            outline.Color = selected and Color3.fromRGB(255, 208, 112) or Color3.fromRGB(128, 100, 60)
            outline.Thickness = selected and 1.8 or 1.1
        end
    end
end
for index, button in ipairs(PianoUI.speedButtons) do
    button.Activated:Connect(function()
        PianoUI.updateSpeedSelection(index)
    end)
end
PianoUI.updateSpeedSelection(3)

PianoUI.volumeSliderDragging = false
function PianoUI.updateVolumeSliderVisuals()
    volume = math.clamp(volume, 0, 1)
    local volumePrefix = PianoUI.mobilePortraitLayout and "VOL " or (scale.Scale < 0.62 and "VOL " or "ÂM LƯỢNG ")
    volumeLabel.Text = volumePrefix .. tostring(math.floor(volume * 100 + 0.5)) .. "%"
    PianoUI.volumeSliderFill.Size = UDim2.new(volume, 0, 1, 0)
    -- Keep the knob fully inside the track at both 0% and 100%.
    PianoUI.volumeSliderKnob.Position = UDim2.new(volume, 7 - (14 * volume), 0.5, 0)
end
function PianoUI.applyMasterVolume()
    PianoUI.updateVolumeSliderVisuals()
    for _, snd in pairs(sounds) do
        if snd and snd.Parent then
            if snd == metronomeSound then
                snd.Volume = volume * 0.22
            else
                snd.Volume = effectiveVoiceVolume(voiceState.velocities[snd], voiceState.semitones[snd])
            end
        end
    end
end
function PianoUI.setVolumeFromPointer(pointerX)
    local width = PianoUI.volumeSliderTrack.AbsoluteSize.X
    if width <= 0 then return end
    local left = PianoUI.volumeSliderTrack.AbsolutePosition.X
    local inset = math.min(7, width * 0.08)
    volume = math.clamp((pointerX - left - inset) / math.max(width - (inset * 2), 1), 0, 1)
    volume = math.floor(volume * 100 + 0.5) / 100
    PianoUI.applyMasterVolume()
end
function PianoUI.beginVolumeDrag(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end
    PianoUI.volumeSliderDragging = true
    PianoUI.setVolumeFromPointer(input.Position.X)
end
PianoUI.volumeSliderTrack.InputBegan:Connect(PianoUI.beginVolumeDrag)
PianoUI.volumeSliderKnob.InputBegan:Connect(PianoUI.beginVolumeDrag)
trackLifetimeConnection(UserInputService.InputChanged:Connect(function(input)
    if PianoUI.volumeSliderDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        PianoUI.setVolumeFromPointer(input.Position.X)
    end
end))
trackLifetimeConnection(UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        PianoUI.volumeSliderDragging = false
    end
end))
PianoUI.updateVolumeSliderVisuals()

PianoUI.controlsHidden = false
minimize.Activated:Connect(function()
    PianoUI.controlsHidden = not PianoUI.controlsHidden
    controlPanelVisible = not PianoUI.controlsHidden
    local showControls = not PianoUI.controlsHidden
    controls.Visible = showControls and viewMode == "classic"
    instrumentControls.Visible = showControls and viewMode == "classic"
    autoPanel.Visible = showControls and viewMode == "classic"
    status.Visible = showControls
    volumeLabel.Visible = showControls
    PianoUI.volumeSliderTrack.Visible = showControls
    if PianoUI.fitToScreen then PianoUI.fitToScreen() end
    minimize.Text = PianoUI.mobilePortraitLayout and (PianoUI.controlsHidden and "NÚT+" or "NÚT") or (scale.Scale < 0.62 and (PianoUI.controlsHidden and "NÚT+" or "NÚT") or (PianoUI.controlsHidden and "HIỆN NÚT" or "ẨN NÚT"))
    minimize.BackgroundColor3 = PianoUI.controlsHidden and Color3.fromRGB(113, 82, 39) or Color3.fromRGB(63, 49, 32)
end)

hidePianoBtn.Activated:Connect(function()
    -- Hide the full instrument case and its shadow. Audio playback is retained.
    main.Visible = false
    mainShadow.Visible = false
    restorePianoBtn.Visible = true
end)

restorePianoBtn.Activated:Connect(function()
    main.Visible = true
    mainShadow.Visible = true
    restorePianoBtn.Visible = false
end)

close.Activated:Connect(function()
    stopPlayback(false)
    isRecording = false
    metronomeEnabled = false
    metronomeToken += 1
    metronomeLoopGeneration += 1
    for _, record in pairs(activeInputVoices) do if record then releaseManualVoice(record) end end
    for _, record in pairs(activeKeyboardVoices) do if record then releaseManualVoice(record) end end
    gui:Destroy()
end)

PianoUI.keyToNote = {}
PianoUI.keyboardCodeLayout = {
    "Z", "S", "X", "D", "C", "V", "G", "B", "H", "N", "J", "M",
    "Q", "Two", "W", "Three", "E", "R", "Five", "T", "Six", "Y", "Seven", "U",
    "I", "Nine", "O", "Zero", "P", "One", "A", "Four", "F", "Eight", "K", "L", "Minus",
}
for index, codeName in ipairs(PianoUI.keyboardCodeLayout) do
    local note = PianoUI.notesBySemi[index - 1] -- PC bindings stay on C3-C6 for familiarity.
    if codeName and note then PianoUI.keyToNote[codeName] = note end
end

trackLifetimeConnection(UserInputService.InputBegan:Connect(function(input, processed)
    if processed or not gui.Parent or not main.Visible then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if autoBox and autoBox:IsFocused() then return end
        local codeName = input.KeyCode.Name
        local note = PianoUI.keyToNote[codeName]
        if note and not activeKeyboardVoices[codeName] then
            local snd = playNote(note, "manual")
            activeKeyboardVoices[codeName] = {note = note, sound = snd, recordEvent = snd and voiceState.recordedEvents[snd]}
        end
    end
end))

trackLifetimeConnection(UserInputService.InputEnded:Connect(function(input)
    local touchRecord = activeInputVoices[input]
    if touchRecord then
        activeInputVoices[input] = nil
        releaseManualVoice(touchRecord)
    end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        local codeName = input.KeyCode.Name
        local record = activeKeyboardVoices[codeName]
        if record then
            activeKeyboardVoices[codeName] = nil
            releaseManualVoice(record)
        end
    end
end))

-- Responsive full-screen grand-piano layout. The keybed is anchored to the bottom
-- edge and always keeps its own lane; controls reflow above it rather than overlap.
PianoUI.camera = nil
PianoUI.cameraConnection = nil
PianoUI.setMobilePage = function(page)
    local valid = { ["CHƠI"] = true, ["BẢN NHẠC"] = true, ["HỢP ÂM"] = true, ["METRONOME"] = true, ["THU ÂM"] = true }
    if not valid[page] then return end
    PianoUI.mobilePage = page
    if PianoUI.fitToScreen then PianoUI.fitToScreen() end
end
PianoUI.mobilePlayTab.Activated:Connect(function() PianoUI.setMobilePage("CHƠI") end)
PianoUI.mobileSongTab.Activated:Connect(function() PianoUI.setMobilePage("BẢN NHẠC") end)
PianoUI.mobileChordTab.Activated:Connect(function() PianoUI.setMobilePage("HỢP ÂM") end)
PianoUI.mobileMetronomeTab.Activated:Connect(function() PianoUI.setMobilePage("METRONOME") end)
PianoUI.mobileRecordTab.Activated:Connect(function() PianoUI.setMobilePage("THU ÂM") end)

PianoUI.fitToScreen = function()
    local viewport
    if PianoUI.camera then
        viewport = PianoUI.camera.ViewportSize
    else
        viewport = gui.AbsoluteSize
    end
    if not viewport or viewport.X <= 0 or viewport.Y <= 0 then return end

    local touch = UserInputService.TouchEnabled
    local portrait = touch and viewport.Y > viewport.X
    local aspectRatio = viewport.Y > 0 and viewport.X / viewport.Y or 1
    local compactLandscape = (not portrait) and aspectRatio >= 1.85
    local compactPortrait = portrait
    local mobileLandscape = touch and not portrait
    PianoUI.mobilePortraitLayout = portrait or compactLandscape
    local screenW, screenH = viewport.X, viewport.Y
    local mainW = math.max(280, screenW - 12)
    local mainH = math.max(320, screenH - 12)
    local cw = math.max(250, mainW - 28)

    sizeConstraint.MinSize = Vector2.new(math.min(280, mainW), math.min(320, mainH))
    sizeConstraint.MaxSize = Vector2.new(4096, 2160)
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.Position = UDim2.new(0.5, 0, 0.5, 0)
    main.Size = UDim2.new(1, -12, 1, -12)
    scale.Scale = 1
    shadowScale.Scale = 1
    mainShadow.AnchorPoint = Vector2.new(0.5, 0.5)
    mainShadow.Size = UDim2.new(1, -4, 1, -4)
    mainShadow.Position = UDim2.new(0.5, -4, 0.5, 9)

    header.Size = UDim2.new(1, 0, 0, 50)
    headerCover.Position = UDim2.new(0, 0, 1, -14)
    headerCover.Size = UDim2.new(1, 0, 0, 14)
    headerSeparator.Position = UDim2.new(0, 12, 0, 50)
    headerSeparator.Size = UDim2.new(1, -24, 0, 1)
    headerGlow.Position = UDim2.new(0, 12, 0, 51)
    headerGlow.Size = UDim2.new(0.34, 0, 0, 1)

    content.Position = UDim2.new(0, 14, 0, 58)
    content.Size = UDim2.new(1, -28, 1, -72)

    -- Brand strip and window actions. On landscape phones, leave the Roblox top-left
    -- system controls clear instead of drawing our brand underneath them.
    local brandX = mobileLandscape and math.min(430, math.max(250, math.floor(screenW * 0.30))) or (compactPortrait and 14 or 17)
    title.Visible = not (mobileLandscape and screenW < 1000)
    title.Text = "♬  DUNGDX"
    title.Position = UDim2.new(0, brandX, 0, 0)
    title.Size = UDim2.new(0, mobileLandscape and 145 or (compactPortrait and 120 or 176), 1, 0)
    title.TextSize = mobileLandscape and 14 or (compactPortrait and 14 or 17)
    subtitle.Visible = not compactPortrait and screenW > 1000
    local subtitleX = mobileLandscape and (brandX + 148) or 204
    subtitle.Position = UDim2.new(0, compactPortrait and 126 or subtitleX, 0, 0)
    subtitle.Size = UDim2.new(1, -(subtitleX + 285), 1, 0)
    subtitle.Text = "GRAND PIANO  •  75 KEYS  •  A0–B6"
    subtitle.TextSize = screenW > 1100 and 10 or 9
    local actionY = 8
    if compactPortrait then
        PianoUI.setButtonLayout(minimize, UDim2.new(1, -143, 0, actionY), UDim2.new(0, 42, 0, 31))
        PianoUI.setButtonLayout(hidePianoBtn, UDim2.new(1, -94, 0, actionY), UDim2.new(0, 44, 0, 31))
        PianoUI.setButtonLayout(close, UDim2.new(1, -43, 0, actionY), UDim2.new(0, 34, 0, 31))
        minimize.Text, hidePianoBtn.Text = "NÚT", "ẨN"
    elseif mobileLandscape then
        PianoUI.setButtonLayout(minimize, UDim2.new(1, -218, 0, actionY), UDim2.new(0, 66, 0, 30))
        PianoUI.setButtonLayout(hidePianoBtn, UDim2.new(1, -144, 0, actionY), UDim2.new(0, 66, 0, 30))
        PianoUI.setButtonLayout(close, UDim2.new(1, -50, 0, actionY), UDim2.new(0, 36, 0, 30))
        minimize.Text = PianoUI.controlsHidden and "NÚT +" or "NÚT"
        hidePianoBtn.Text = "ĐÀN"
    else
        PianoUI.setButtonLayout(minimize, UDim2.new(1, -260, 0, actionY), UDim2.new(0, 91, 0, 32))
        PianoUI.setButtonLayout(hidePianoBtn, UDim2.new(1, -158, 0, actionY), UDim2.new(0, 91, 0, 32))
        PianoUI.setButtonLayout(close, UDim2.new(1, -51, 0, actionY), UDim2.new(0, 39, 0, 32))
        minimize.Text = PianoUI.controlsHidden and "HIỆN NÚT" or "ẨN NÚT"
        hidePianoBtn.Text = "ẨN ĐÀN"
    end

    local wide = not compactPortrait and cw >= 760
    local hidden = PianoUI.controlsHidden
    local classic = viewMode == "classic"
    local showUi = not hidden and classic
    local statusY = 0
    status.Position = UDim2.new(0, 0, 0, statusY)
    status.Size = UDim2.new(1, wide and -350 or -176, 0, 23)
    status.TextXAlignment = compactPortrait and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left
    status.TextSize = compactPortrait and 9 or 11
    status.Visible = not hidden

    local volumeLabelWidth = compactPortrait and 65 or 108
    local sliderWidth = compactPortrait and math.max(64, math.min(100, cw * 0.26)) or math.max(92, math.min(150, cw * 0.14))
    local rightReserve = volumeLabelWidth + sliderWidth + 20
    volumeLabel.Position = UDim2.new(1, -rightReserve, 0, 0)
    volumeLabel.Size = UDim2.new(0, volumeLabelWidth, 0, 23)
    volumeLabel.Text = (compactPortrait and "VOL " or "ÂM LƯỢNG ") .. tostring(math.floor(volume * 100 + 0.5)) .. "%"
    volumeLabel.TextXAlignment = Enum.TextXAlignment.Right
    volumeLabel.TextSize = compactPortrait and 9 or 11
    volumeLabel.Visible = not hidden
    PianoUI.volumeSliderTrack.Position = UDim2.new(1, -sliderWidth, 0, 9)
    PianoUI.volumeSliderTrack.Size = UDim2.new(0, sliderWidth - 8, 0, 6)
    PianoUI.volumeSliderKnob.Size = UDim2.new(0, compactPortrait and 13 or 16, 0, compactPortrait and 13 or 16)
    PianoUI.volumeSliderTrack.Visible = not hidden
    if PianoUI.updateVolumeSliderVisuals then PianoUI.updateVolumeSliderVisuals() end

    -- Playback row; compact portrait gets a second speed row so labels remain tappable.
    controls.Position = UDim2.new(0, 0, 0, 27)
    local playbackButtons = {playBtn, pauseBtn, stopBtn, recordBtn, replayBtn}
    local playbackHeight = compactPortrait and 29 or (mobileLandscape and 29 or 33)
    controls.Size = UDim2.new(1, 0, 0, compactPortrait and 59 or (mobileLandscape and 30 or 33))
    local playbackGap = compactPortrait and 3 or 6
    local speedGapWide = 4
    local speedWWide = math.max(42, math.min(92, math.floor((cw * 0.42 - 58 - speedGapWide * 4) / 5)))
    local speedGroupWWide = 54 + speedGapWide + speedWWide * 5 + speedGapWide * 4
    -- Give playback buttons the remaining lane beside the speed selector. The old
    -- 43%-width cap forced landscape-mobile buttons down to icon-only labels.
    local playbackAreaW = compactPortrait and cw or math.min(cw * 0.58, math.max(240, cw - speedGroupWWide - 18))
    local playbackW = math.floor((playbackAreaW - playbackGap * (#playbackButtons - 1)) / #playbackButtons)
    for i, button in ipairs(playbackButtons) do
        PianoUI.setButtonLayout(button, UDim2.new(0, (i - 1) * (playbackW + playbackGap), 0, 0), UDim2.new(0, playbackW, 0, playbackHeight))
        button.TextSize = compactPortrait and 10 or (playbackW >= 100 and 11 or 9)
    end
    if compactPortrait then
        playBtn.Text = "▶ PHÁT"
        pauseBtn.Text = paused and "▶ TIẾP" or "Ⅱ DỪNG"
        stopBtn.Text = "■"
        recordBtn.Text = isRecording and "● REC" or "● THU"
        replayBtn.Text = "↻ LẠI"
        speedLabel.Position = UDim2.new(0, 0, 0, 34)
        speedLabel.Size = UDim2.new(0, 45, 0, 25)
        speedLabel.Text = "TỐC ĐỘ"
        speedLabel.TextSize = 9
        local speedGap = 4
        local speedW = math.max(37, math.min(52, math.floor((cw - 60 - speedGap * 4) / 5)))
        local speedGroupW = speedW * 5 + speedGap * 4
        local speedStart = math.max(50, (cw - speedGroupW) * 0.5 + 21)
        for i, button in ipairs(PianoUI.speedButtons) do
            PianoUI.setButtonLayout(button, UDim2.new(0, speedStart + (i - 1) * (speedW + speedGap), 0, 34), UDim2.new(0, speedW, 0, 25))
            button.Text = ({"0.5×", "0.75×", "1×", "1.25×", "1.5×"})[i]
            button.TextSize = 9
        end
    else
        local labelsAllowed = playbackW >= 88
        playBtn.Text = labelsAllowed and "▶ PHÁT" or "▶"
        pauseBtn.Text = labelsAllowed and (paused and "▶ TIẾP TỤC" or "Ⅱ TẠM DỪNG") or (paused and "▶" or "Ⅱ")
        stopBtn.Text = labelsAllowed and "■ DỪNG" or "■"
        recordBtn.Text = labelsAllowed and (isRecording and "● ĐANG THU" or "● THU ÂM") or (isRecording and "● REC" or "●")
        replayBtn.Text = labelsAllowed and "↻ PHÁT LẠI" or "↻"
        speedLabel.Visible = showUi
        speedLabel.Text = "TỐC ĐỘ"
        speedLabel.TextSize = 10
        local speedGap = speedGapWide
        local speedW = speedWWide
        local groupW = speedGroupWWide
        local speedStart = cw - groupW
        local speedControlHeight = mobileLandscape and 29 or 34
        speedLabel.Position = UDim2.new(0, speedStart, 0, 0)
        speedLabel.Size = UDim2.new(0, 50, 0, speedControlHeight)
        for i, button in ipairs(PianoUI.speedButtons) do
            PianoUI.setButtonLayout(button, UDim2.new(0, speedStart + 54 + (i - 1) * (speedW + speedGap), 0, 0), UDim2.new(0, speedW, 0, speedControlHeight))
            button.Text = PianoUI.SPEED_LABELS[i]
            button.TextSize = 10
        end
    end
    controls.Visible = showUi
    for _, button in ipairs(PianoUI.speedButtons) do button.Visible = showUi end

    -- The tab row is a real workspace selector on touch and desktop, not just a portrait workaround.
    -- Keep the tab bar above the keybed. The previous y=139 layout placed the
    -- navigation row on top of the keyboard on landscape phones with a scaled viewport.
    local navY = compactPortrait and 128 or (mobileLandscape and 94 or 99)
    local navHeight = compactPortrait and 29 or (mobileLandscape and 25 or 27)
    PianoUI.mobileNav.Position = UDim2.new(0, 0, 0, navY)
    PianoUI.mobileNav.Size = UDim2.new(1, 0, 0, navHeight)
    PianoUI.mobileNav.Visible = showUi
    local tabs = {
        {PianoUI.mobilePlayTab, "CHƠI", "CHƠI"},
        {PianoUI.mobileSongTab, "BẢN NHẠC", compactPortrait and "NHẠC" or "BẢN NHẠC"},
        {PianoUI.mobileChordTab, "HỢP ÂM", "HỢP ÂM"},
        {PianoUI.mobileMetronomeTab, "METRONOME", compactPortrait and "NHỊP" or "METRONOME"},
        {PianoUI.mobileRecordTab, "THU ÂM", compactPortrait and "THU" or "THU ÂM"},
        {PianoUI.mobileGameTab, "LUYỆN TẬP", compactPortrait and "LUYỆN" or "LUYỆN TẬP"},
    }
    local tabGap = compactPortrait and 3 or 5
    local tabW = math.floor((cw - tabGap * (#tabs - 1)) / #tabs)
    for i, item in ipairs(tabs) do
        local button, page, label = item[1], item[2], item[3]
        local selected = (page == PianoUI.mobilePage and classic) or (page == "LUYỆN TẬP" and not classic)
        PianoUI.setButtonLayout(button, UDim2.new(0, (i - 1) * (tabW + tabGap), 0, 0), UDim2.new(0, tabW, 0, navHeight))
        button.Text = label
        button.TextSize = compactPortrait and 8 or (tabW < 90 and 8 or 9)
        PianoUI.setButtonBaseColor(button, selected and COLORS.accent or COLORS.panel2)
        button.TextColor3 = selected and Color3.new(1, 1, 1) or COLORS.text
        button.Visible = true
    end

    -- Settings row: all controls fit in landscape; portrait filters to the current workspace tab.
    local settingsY = compactPortrait and 91 or (mobileLandscape and 61 or 64)
    instrumentControls.Position = UDim2.new(0, 0, 0, settingsY)
    instrumentControls.Size = UDim2.new(1, 0, 0, mobileLandscape and 26 or 29)
    instrumentControls.Visible = showUi
    local allSettingButtons = {sustainBtn, softBtn, dynamicsBtn, transposeDownBtn, transposeLabel, transposeUpBtn, tempoBtn, metronomeBtn, loopBtn, copyTakeBtn, PianoUI.sostenutoBtn, PianoUI.roomBtn}
    local wideSettingsLabels = {
        sustainEnabled and "GIỮ ÂM ✓" or "GIỮ ÂM",
        softEnabled and "ÊM ✓" or "ÊM",
        "LỰC " .. tostring(dynamicsIndex) .. "/4",
        "ÂM −", string.format("%+d BT", transposeSemitones), "ÂM +",
        "NHỊP " .. tostring(tempoBpm), metronomeEnabled and "GÕ BẬT" or "GÕ TẮT",
        loopPlayback and "LẶP BẬT" or "LẶP TẮT", "CHÉP BẢN",
        PianoUI.sostenutoEnabled and "SOS BẬT" or "SOS TẮT",
        PianoUI.roomEnabled and "PHÒNG BẬT" or "PHÒNG TẮT",
    }
    -- Keep the settings row calm on every screen: only show controls relevant to the active tab.
    -- This avoids a crowded 12-button strip on PCs that report TouchEnabled=false on mobile emulators.
    local settingsByPage = {
        ["CHƠI"] = {sustainBtn, softBtn, dynamicsBtn, transposeDownBtn, transposeLabel, transposeUpBtn, PianoUI.sostenutoBtn},
        ["BẢN NHẠC"] = {tempoBtn, loopBtn, copyTakeBtn, dynamicsBtn},
        ["HỢP ÂM"] = {sustainBtn, softBtn, dynamicsBtn, transposeDownBtn, transposeLabel, transposeUpBtn},
        ["METRONOME"] = {tempoBtn, metronomeBtn, loopBtn, PianoUI.roomBtn},
        ["THU ÂM"] = {copyTakeBtn, loopBtn, metronomeBtn, PianoUI.roomBtn},
    }
    local visibleButtons = settingsByPage[PianoUI.mobilePage] or settingsByPage["CHƠI"]
    for _, button in ipairs(allSettingButtons) do button.Visible = false end
    local gap = mobileLandscape and 6 or 4
    local count = #visibleButtons
    local availableItemW = math.floor((cw - gap * (count - 1)) / math.max(count, 1))
    -- Compact, centered control group: the piano should feel like an instrument
    -- console, not a screen full of stretched pill buttons.
    local itemW = mobileLandscape and math.min(104, availableItemW) or availableItemW
    local settingsGroupW = count * itemW + gap * math.max(0, count - 1)
    local settingsStart = mobileLandscape and math.max(0, math.floor((cw - settingsGroupW) * 0.5)) or 0
    local labels = {
        [sustainBtn] = sustainEnabled and "GIỮ ✓" or "GIỮ ÂM",
        [softBtn] = softEnabled and "ÊM ✓" or "ÊM",
        [dynamicsBtn] = "LỰC " .. tostring(dynamicsIndex),
        [transposeDownBtn] = "−",
        [transposeLabel] = string.format("%+d", transposeSemitones),
        [transposeUpBtn] = "+",
        [tempoBtn] = tostring(tempoBpm) .. " BPM",
        [metronomeBtn] = metronomeEnabled and "GÕ ✓" or "GÕ TẮT",
        [loopBtn] = loopPlayback and "LẶP ✓" or "LẶP TẮT",
        [copyTakeBtn] = "CHÉP",
        [PianoUI.sostenutoBtn] = PianoUI.sostenutoEnabled and "SOS ✓" or "SOS",
        [PianoUI.roomBtn] = PianoUI.roomEnabled and "PHÒNG ✓" or "PHÒNG",
    }
    for i, button in ipairs(visibleButtons) do
        PianoUI.setButtonLayout(button, UDim2.new(0, settingsStart + (i - 1) * (itemW + gap), 0, 0), UDim2.new(0, itemW, 0, mobileLandscape and 25 or 29))
        button.Text = labels[button] or button.Text
        button.TextSize = itemW < 48 and 8 or (itemW < 68 and 9 or 10)
        button.Visible = showUi
    end

    -- Sequence editor is a dedicated panel for songs and chord syntax (e.g. C4+E4+G4).
    local workspaceY = compactPortrait and 163 or (mobileLandscape and 130 or 133)
    local workspaceHeight = compactPortrait and 42 or 27
    autoPanel.Position = UDim2.new(0, 0, 0, workspaceY)
    autoPanel.Size = UDim2.new(1, 0, 0, workspaceHeight)
    sequenceLabel.Position = UDim2.new(0, 0, 0, 0)
    sequenceLabel.Size = UDim2.new(0, compactPortrait and 54 or 86, 0, 19)
    sequenceLabel.TextSize = compactPortrait and 9 or 9
    sequenceClip.Position = UDim2.new(0, compactPortrait and 58 or 92, 0, 0)
    sequenceClip.Size = UDim2.new(1, compactPortrait and -58 or -92, 0, compactPortrait and 42 or 27)
    autoBox.TextSize = compactPortrait and 11 or 10
    if PianoUI.mobilePage == "HỢP ÂM" then
        sequenceLabel.Text = "HỢP ÂM"
        autoBox.PlaceholderText = "Nhập hợp âm: C4+E4+G4  •  hoặc F4+A4+C5"
    else
        sequenceLabel.Text = "BẢN NHẠC"
        autoBox.PlaceholderText = "Nhập nốt: C4 D4 E4  •  dùng dấu + để ghép hợp âm"
    end
    local sequencePage = PianoUI.mobilePage == "BẢN NHẠC" or PianoUI.mobilePage == "HỢP ÂM"
    autoPanel.Visible = showUi and sequencePage
    workspaceHintPanel.Position = UDim2.new(0, 0, 0, workspaceY)
    workspaceHintPanel.Size = UDim2.new(1, 0, 0, workspaceHeight)
    workspaceHintPanel.Visible = showUi and not sequencePage and PianoUI.mobilePage ~= "CHƠI"
    workspaceHintLabel.TextSize = compactPortrait and 9 or 9
    if PianoUI.mobilePage == "METRONOME" then
        workspaceHintLabel.Text = "CHỈNH BPM VÀ BẬT GÕ ĐỂ GIỮ NHỊP"
    elseif PianoUI.mobilePage == "THU ÂM" then
        workspaceHintLabel.Text = "BẤM THU ÂM ĐỂ GHI  •  PHÁT LẠI ĐỂ NGHE BẢN THU"
    else
        workspaceHintLabel.Text = "CHẠM PHÍM ĐỂ CHƠI  •  VUỐT NGANG ĐỂ ĐỔI QUÃNG"
    end

    -- Mini-game view retains all original game logic, while the keyboard remains docked at the bottom.
    gameControls.Position = UDim2.new(0, 0, 0, compactPortrait and 97 or 68)
    gameControls.Size = UDim2.new(1, 0, 0, 34)
    gamePanel.Position = UDim2.new(0, 0, 0, compactPortrait and 137 or 108)
    gamePanel.Size = UDim2.new(1, 0, 0, 61)
    gameControls.Visible = not classic and not hidden
    gamePanel.Visible = not classic and not hidden
    if not classic or hidden then workspaceHintPanel.Visible = false end
    hint.Visible = not hidden and not compactLandscape and not touch
    hint.Position = UDim2.new(0, 0, 1, -15)
    hint.Size = UDim2.new(1, 0, 0, 14)
    hint.Text = touch and "‹  VUỐT NGANG ĐỂ CHUYỂN QUÃNG ĐÀN  ›" or "VUỐT/ CUỘN ĐỂ ĐỔI QUÃNG  •  PC: Z–M / Q–U / I–P"
    hint.TextSize = compactPortrait and 8 or 9
    hint.TextColor3 = COLORS.muted
    hint.TextXAlignment = Enum.TextXAlignment.Center

    -- Fit the keybed into the space remaining after controls, tabs and the context
    -- strip. The old fixed 52% ratio ignored that reserved area and let the keys
    -- rise behind the tabs/hint on landscape phones.
    local contentAbsH = math.max(240, screenH - 84)
    local reservedFooter = (mobileLandscape or compactLandscape) and 17 or 22
    local clearTopY
    local needsWorkspace = PianoUI.mobilePage ~= "CHƠI"
    if hidden then
        clearTopY = 8
    elseif compactPortrait then
        clearTopY = 222 -- keep the sequence editor/game panel clear in portrait
    elseif not classic then
        clearTopY = 178 -- mini-game prompt stays above the keys
    elseif mobileLandscape and needsWorkspace then
        clearTopY = 166 -- sequence/metronome/record context panel remains unobstructed
    elseif mobileLandscape then
        clearTopY = 138 -- Play page: close the gap between tabs and keys
    elseif needsWorkspace then
        clearTopY = 174
    else
        clearTopY = 158
    end
    -- Dock the keys immediately below the active workspace. This uses the screen
    -- height instead of leaving a dead-black band between the tabs and the keybed.
    local deckRatio = hidden and (portrait and 0.48 or 0.50)
        or (portrait and 0.34 or (mobileLandscape and 0.34 or (compactLandscape and 0.36 or 0.46)))
    local desiredDeckHeight = math.floor((mobileLandscape or compactLandscape) and (screenH * deckRatio) or (contentAbsH * deckRatio))
    local maxDeckHeight = math.max(72, contentAbsH - clearTopY - reservedFooter)
    local deckHeight = math.clamp(desiredDeckHeight, math.min(72, maxDeckHeight), maxDeckHeight)
    keyboardDeck.Position = UDim2.new(0, -2, 1, -(deckHeight + reservedFooter))
    keyboardDeck.Size = UDim2.new(1, 4, 0, deckHeight + 3)
    keyboardFrame.Position = UDim2.new(0, 0, 1, -(deckHeight + reservedFooter - 1))
    keyboardFrame.Size = UDim2.new(1, 0, 0, deckHeight)
    keyArea.Position = UDim2.new(0, 5, 0, 4)
    keyArea.Size = UDim2.new(1, -10, 1, -8)
    keyArea.ScrollBarThickness = touch and 4 or 3
    keyArea.ScrollBarImageTransparency = 0.35
    keyArea.ScrollingEnabled = true

    -- In page layouts with hidden controls, don't leave their input targets layered over the keyboard.
    classicTab.Visible = false
    gamesTab.Visible = false
    volumeLabel.Visible = not hidden
    PianoUI.volumeSliderTrack.Visible = not hidden
end

local function bindCamera(nextCamera)
    if PianoUI.cameraConnection then
        PianoUI.cameraConnection:Disconnect()
        PianoUI.cameraConnection = nil
    end
    PianoUI.camera = nextCamera
    if PianoUI.camera then
        PianoUI.cameraConnection = PianoUI.camera:GetPropertyChangedSignal("ViewportSize"):Connect(PianoUI.fitToScreen)
    end
    PianoUI.fitToScreen()
end
bindCamera(workspace.CurrentCamera)
trackLifetimeConnection(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    bindCamera(workspace.CurrentCamera)
end))

-- Lifecycle cleanup also runs when this file is executed again and replaces the GUI.
PianoUI.cleanupComplete = false
gui.Destroying:Connect(function()
    if PianoUI.cleanupComplete then return end
    PianoUI.cleanupComplete = true
    shuttingDown = true
    for _, tween in ipairs(rgbBorderTweens) do
        pcall(function() tween:Cancel() end)
    end
    table.clear(rgbBorderTweens)
    sequenceToken += 1
    gameToken += 1
    gameRunning = false
    gameCanInput = false
    playing = false
    paused = false
    isRecording = false
    currentPlaybackMode = nil
    if PianoUI.cameraConnection then
        PianoUI.cameraConnection:Disconnect()
        PianoUI.cameraConnection = nil
    end
    for _, connection in ipairs(lifetimeConnections) do
        pcall(function() connection:Disconnect() end)
    end
    metronomeEnabled = false
    metronomeToken += 1
    metronomeLoopGeneration += 1
    for _, tween in ipairs(rgbBorderTweens) do pcall(function() tween:Cancel() end) end
    for _, snd in ipairs(sounds) do
        if snd and snd.Parent then
            local fade = voiceState.fadeTweens[snd]
            if fade then pcall(function() fade:Cancel() end); voiceState.fadeTweens[snd] = nil end
            pcall(function()
                snd:Stop()
                snd:Destroy()
            end)
        end
    end
    if PianoUI.soundGroup and PianoUI.soundGroup.Parent then
        pcall(function() PianoUI.soundGroup:Destroy() end)
    end
end)