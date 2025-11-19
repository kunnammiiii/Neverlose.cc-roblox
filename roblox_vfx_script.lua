-- NEVERLOSE VFX MEGA PACK
-- Полный набор безопасных визуальных эффектов для локального использования (SELF-ONLY)
-- Интегрируется с Neverlose UI (SourceClude NerverLoseLibEdited)
-- Не содержит ESP/aimbot/прочих чит-функций. Все эффекты локальные или относятся к миру.

-- == ЗАГРУЗКА БИБЛИОТЕКИ ==
local ok, lib = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/CludeHub/SourceCludeLib/refs/heads/main/NerverLoseLibEdited.lua"))()
end)
if not ok or not lib then
    warn("[VFX PACK] Не удалось загрузить Neverlose UI. Проверь подключение или URL.")
    return
end
getgenv().Neverlose_Main = lib

-- == СЕРВИСЫ ==
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- == ОКНО UI ==
local Win = getgenv().Neverlose_Main:AddWindow("VFX MEGA PACK", "Visual Enhancement System", "neon")

-- ==================================================================================
--                          GLOBAL SETTINGS / STATE
-- ==================================================================================
local STATE = {
    -- Night mode
    NightMode = false,
    NightTint = Color3.fromRGB(24,28,40),
    NightBrightness = 1,

    -- Weather
    Weather = "Clear", -- Clear, Rain, Fog, Snow, CyberRain, Sandstorm
    WeatherObjects = {},

    -- Air particles
    AirParticles = {
        Enabled = false,
        Density = 15,
        Object = nil,
        Texture = "rbxassetid://2581284631"
    },

    -- Self outline
    Outline = {
        Enabled = false,
        Color = Color3.fromRGB(0,170,255),
        Thickness = 2,
        Instance = nil
    },

    -- Player FX modules
    FX = {
        Aura = {Enabled = false, Color = Color3.fromRGB(120,0,255), Radius = 8},
        Tron = {Enabled = false},
        Sparks = {Enabled = false},
        FireFeet = {Enabled = false}
    },

    -- World filters
    Filters = {Enabled = false, Name = "Cyber", Object = nil},

    -- Camera effects
    Camera = {MotionBlur = false, Bloom = false, Chromatic = false, Grain = false},

    -- Misc
    Enabled = true,
}

-- ==================================================================================
--                                  HELPERS
-- ==================================================================================
local function safeDestroy(inst)
    if inst and inst.Parent then
        pcall(function() inst:Destroy() end)
    end
end

local function findOrCreate(parent, className, props)
    local existing = parent:FindFirstChild(props and props.Name or (className.."_Auto"))
    if existing and existing:IsA(className) then
        return existing
    end
    local inst = Instance.new(className)
    if props then
        for k,v in pairs(props) do
            pcall(function() inst[k] = v end)
        end
    end
    inst.Parent = parent
    return inst
end

-- ==================================================================================
--                              NIGHT MODE
-- ==================================================================================
local function ApplyNightMode()
    if STATE.NightMode then
        Lighting.ClockTime = 0
        Lighting.Brightness = STATE.NightBrightness
        Lighting.Ambient = STATE.NightTint
        Lighting.OutdoorAmbient = STATE.NightTint
    else
        Lighting.ClockTime = 14
        Lighting.Brightness = 2
        Lighting.Ambient = Color3.fromRGB(255,255,255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255)
    end
end

-- ==================================================================================
--                              WEATHER SYSTEM
-- ==================================================================================
-- Для достижения безопасности мы создаём объекты погоды локально (Parent workspace) и удаляем старые
local function ClearWeather()
    for _,obj in pairs(STATE.WeatherObjects) do
        safeDestroy(obj)
    end
    STATE.WeatherObjects = {}
    Lighting.FogEnd = 100000
    Lighting.FogStart = 0
    Lighting.FogColor = Lighting.FogColor or Color3.new(1,1,1)
end

local function CreateRain(maxRate)
    maxRate = maxRate or 400
    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "VFX_Rain"
    emitter.Texture = "rbxassetid://4800242077"
    emitter.Rate = maxRate
    emitter.Lifetime = NumberRange.new(0.9,1.3)
    emitter.Speed = NumberRange.new(40,60)
    emitter.VelocitySpread = 20
    emitter.Rotation = NumberRange.new(0,0)
    emitter.LightEmission = 0
    emitter.Parent = workspace.Terrain
    table.insert(STATE.WeatherObjects, emitter)
    return emitter
end

local function CreateSnow(rate)
    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "VFX_Snow"
    emitter.Texture = "rbxassetid://26356434"
    emitter.Rate = rate
    emitter.Lifetime = NumberRange.new(4,6)
    emitter.Speed = NumberRange.new(1,3)
    emitter.Rotation = NumberRange.new(0,360)
    emitter.Size = NumberSequence.new(0.8)
    emitter.Parent = workspace.Terrain
    table.insert(STATE.WeatherObjects, emitter)
    return emitter
end

local function CreateFog(color, density)
    Lighting.FogColor = color or Color3.fromRGB(180,180,190)
    Lighting.FogStart = 0
    Lighting.FogEnd = density or 120
end

local function CreateSandstorm(rate)
    local p = Instance.new("ParticleEmitter")
    p.Name = "VFX_Sand"
    p.Texture = "rbxassetid://2581284631"
    p.Rate = rate
    p.Lifetime = NumberRange.new(2,4)
    p.Speed = NumberRange.new(6,12)
    p.Size = NumberSequence.new(1)
    p.Parent = workspace.Terrain
    table.insert(STATE.WeatherObjects, p)
    return p
end

local function CreateCyberRain()
    -- neon drops falling and glowing when hitting ground (approximation)
    local p = Instance.new("ParticleEmitter")
    p.Name = "VFX_CyberRain"
    p.Texture = "rbxassetid://241594314" -- soft glow
    p.Rate = 300
    p.Lifetime = NumberRange.new(0.8,1.2)
    p.Speed = NumberRange.new(30,45)
    p.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.12), NumberSequenceKeypoint.new(1,0.05)})
    p.LightEmission = 1
    p.Parent = workspace.Terrain
    table.insert(STATE.WeatherObjects, p)
    return p
end

local function ApplyWeather(mode)
    mode = mode or STATE.Weather
    ClearWeather()
    if mode == "Clear" then
        -- reset
    elseif mode == "Rain" then
        CreateRain(500)
        CreateFog(Color3.fromRGB(150,150,170), 200)
    elseif mode == "Snow" then
        CreateSnow(140)
        CreateFog(Color3.fromRGB(210,220,230), 300)
    elseif mode == "Fog" then
        CreateFog(Color3.fromRGB(180,180,190), 100)
    elseif mode == "Sandstorm" then
        CreateSandstorm(300)
        CreateFog(Color3.fromRGB(200,180,150), 200)
    elseif mode == "CyberRain" then
        CreateCyberRain()
        CreateFog(Color3.fromRGB(80,90,120), 220)
    end
end

-- ==================================================================================
--                              AIR PARTICLES
-- ==================================================================================
local function ToggleAirParticles(state)
    if state and not STATE.AirParticles.Object then
        local p = Instance.new("ParticleEmitter")
        p.Name = "VFX_AirDust"
        p.Texture = STATE.AirParticles.Texture
        p.Rate = STATE.AirParticles.Density
        p.Speed = NumberRange.new(0.3, 0.9)
        p.Lifetime = NumberRange.new(4,7)
        p.Rotation = NumberRange.new(0,360)
        p.Transparency = NumberSequence.new(0.6, 1)
        p.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.2), NumberSequenceKeypoint.new(1,0.6)})
        p.Parent = workspace.Terrain
        STATE.AirParticles.Object = p
    elseif not state and STATE.AirParticles.Object then
        safeDestroy(STATE.AirParticles.Object)
        STATE.AirParticles.Object = nil
    elseif state and STATE.AirParticles.Object then
        STATE.AirParticles.Object.Rate = STATE.AirParticles.Density
    end
end

-- ==================================================================================
--                              SELF OUTLINE (HIGHLIGHT)
-- ==================================================================================
local function EnsureOutline()
    local char = LocalPlayer.Character
    if not char then return end
    local hl = char:FindFirstChild("VFX_Outline")
    if not hl then
        hl = Instance.new("Highlight")
        hl.Name = "VFX_Outline"
        hl.FillTransparency = 1
        hl.DepthMode = Enum.HighlightDepthMode.Occluded -- important: not visible through walls
        hl.Parent = char
    end
    return hl
end

local function ApplyOutlineSettings()
    local hl = EnsureOutline()
    if not hl then return end
    hl.Enabled = STATE.Outline.Enabled
    hl.OutlineColor = STATE.Outline.Color
    hl.OutlineThickness = STATE.Outline.Thickness
end

-- ==================================================================================
--                              PLAYER FX: AURA / TRON / SPARKS / FIRE FEET
-- ==================================================================================
-- Aura: PointLight attached to HumanoidRootPart + subtle particle ring
local function CreateOrUpdateAura()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart")
    if not hrp then return end

    local light = hrp:FindFirstChild("VFX_AuraLight")
    if not light then
        light = Instance.new("PointLight")
        light.Name = "VFX_AuraLight"
        light.Range = 12
        light.Parent = hrp
    end
    light.Color = STATE.FX.Aura.Color
    light.Brightness = STATE.FX.Aura.Enabled and 2 or 0

    -- particle ring
    local ring = hrp:FindFirstChild("VFX_AuraRing")
    if STATE.FX.Aura.Enabled and not ring then
        ring = Instance.new("ParticleEmitter")
        ring.Name = "VFX_AuraRing"
        ring.Texture = "rbxassetid://241594314"
        ring.Rate = 30
        ring.Lifetime = NumberRange.new(0.8,1.6)
        ring.Speed = NumberRange.new(0.2,0.6)
        ring.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.5), NumberSequenceKeypoint.new(1,0.2)})
        ring.LightEmission = 1
        ring.Parent = hrp
    elseif not STATE.FX.Aura.Enabled and ring then
        safeDestroy(ring)
    end
end

-- Tron Lines: decorative beams along accessories or limbs (approximation using neon parts)
local function ApplyTron(state)
    local char = LocalPlayer.Character
    if not char then return end
    -- cleanup existing tron parts
    for _,c in pairs(char:GetChildren()) do
        if c:IsA("BasePart") and c.Name:match("VFX_Tron") then
            c:Destroy()
        end
    end
    if not state then return end

    -- create thin neon parts parented to limbs
    local function makeLine(part)
        local line = Instance.new("Part")
        line.Name = "VFX_TronLine"
        line.Size = Vector3.new(0.08, part.Size.Y * 1.05, 0.08)
        line.Anchored = false
        line.CanCollide = false
        line.Material = Enum.Material.Neon
        line.Color = Color3.fromRGB(80,200,255)
        line.Transparency = 0
        line.Parent = char

        local weld = Instance.new("WeldConstraint")
        weld.Part0 = part
        weld.Part1 = line
        weld.Parent = line

        -- position line on side of part
        line.CFrame = part.CFrame * CFrame.new(part.Size.X/2 + 0.04, 0, 0)
        return line
    end

    for _,part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" and part.Size.Magnitude > 0.5 then
            pcall(function() makeLine(part) end)
        end
    end
end

-- Sparks: small electric sparks near torso
local function ToggleSparks(state)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart")
    if not hrp then return end
    local existing = hrp:FindFirstChild("VFX_Sparks")
    if state and not existing then
        local p = Instance.new("ParticleEmitter")
        p.Name = "VFX_Sparks"
        p.Texture = "rbxassetid://252907615"
        p.Rate = 20
        p.Lifetime = NumberRange.new(0.2,0.6)
        p.Speed = NumberRange.new(1,3)
        p.Size = NumberSequence.new(0.05)
        p.Parent = hrp
    elseif not state and existing then
        safeDestroy(existing)
    end
end

-- Fire feet: add small flame particle emitters under feet
local function ToggleFireFeet(state)
    local char = LocalPlayer.Character
    if not char then return end
    local function applyToFoot(footName)
        local foot = char:FindFirstChild(footName)
        if not foot or not foot:IsA("BasePart") then return end
        local existing = foot:FindFirstChild("VFX_Fire")
        if state and not existing then
            local p = Instance.new("ParticleEmitter")
            p.Name = "VFX_Fire"
            p.Texture = "rbxassetid://241594314"
            p.Rate = 40
            p.Lifetime = NumberRange.new(0.4,0.9)
            p.Speed = NumberRange.new(0.5,1.2)
            p.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.2), NumberSequenceKeypoint.new(1,0.6)})
            p.LightEmission = 1
            p.Parent = foot
        elseif not state and existing then
            safeDestroy(existing)
        end
    end
    applyToFoot("LeftFoot")
    applyToFoot("RightFoot")
end

-- ==================================================================================
--                              WORLD COLOR FILTERS
-- ==================================================================================
local function ApplyColorFilter(name)
    -- Remove existing
    if STATE.Filters.Object then
        safeDestroy(STATE.Filters.Object)
        STATE.Filters.Object = nil
    end
    if not STATE.Filters.Enabled then return end

    local cc = Instance.new("ColorCorrectionEffect")
    cc.Name = "VFX_ColorFilter"
    cc.Parent = Lighting

    local bloom = Instance.new("BloomEffect")
    bloom.Name = "VFX_Bloom"
    bloom.Parent = Lighting

    -- presets
    if name == "Cyber" then
        cc.Contrast = 0.2
        cc.Saturation = 0.5
        cc.TintColor = Color3.fromRGB(160,200,255)
        bloom.Intensity = 2
        bloom.Size = 56
    elseif name == "NeonPink" then
        cc.Contrast = 0.08
        cc.Saturation = 0.6
        cc.TintColor = Color3.fromRGB(255,120,200)
        bloom.Intensity = 1.5
        bloom.Size = 48
    elseif name == "Vaporwave" then
        cc.Contrast = 0.12
        cc.Saturation = 0.8
        cc.TintColor = Color3.fromRGB(200,160,255)
        bloom.Intensity = 1.8
        bloom.Size = 60
    elseif name == "ColdBlue" then
        cc.Contrast = 0.1
        cc.Saturation = 0.2
        cc.TintColor = Color3.fromRGB(120,160,255)
        bloom.Intensity = 1.2
        bloom.Size = 40
    else
        -- default subtle
        cc.Contrast = 0.05
        cc.Saturation = 0.3
        cc.TintColor = Color3.fromRGB(170,200,255)
        bloom.Intensity = 1.3
        bloom.Size = 48
    end
    STATE.Filters.Object = cc
end

-- ==================================================================================
--                              CAMERA EFFECTS
-- ==================================================================================
local CameraEffects = {}

function CameraEffects.ToggleMotionBlur(state)
    -- Roblox doesn't have a native motion blur effect; emulate with DoF + tweening camera FOV changes
    -- We'll implement a mild pseudo-motion effect
    STATE.Camera.MotionBlur = state
end

function CameraEffects.ToggleChromatic(state)
    STATE.Camera.Chromatic = state
    local cham = Lighting:FindFirstChild("VFX_Chromatic")
    if state and not cham then
        local effect = Instance.new("ColorCorrectionEffect")
        effect.Name = "VFX_Chromatic"
        effect.Parent = Lighting
        effect.Saturation = 0.15
    elseif not state and cham then
        safeDestroy(cham)
    end
end

function CameraEffects.ToggleGrain(state)
    STATE.Camera.Grain = state
    local grain = Lighting:FindFirstChild("VFX_Grain")
    if state and not grain then
        local g = Instance.new("ColorCorrectionEffect")
        g.Name = "VFX_Grain"
        g.Parent = Lighting
        g.Contrast = 0.02
    elseif not state and grain then
        safeDestroy(grain)
    end
end

function CameraEffects.ToggleBloom(state)
    STATE.Camera.Bloom = state
    local bloom = Lighting:FindFirstChild("VFX_BloomEffect")
    if state and not bloom then
        local b = Instance.new("BloomEffect")
        b.Name = "VFX_BloomEffect"
        b.Intensity = 1.8
        b.Size = 56
        b.Parent = Lighting
    elseif not state and bloom then
        safeDestroy(bloom)
    end
end

-- ==================================================================================
--                              UI: BUILD TABS & CONTROLS
-- ==================================================================================

-- Helper: create section UI quickly
local function addSection(tab, name, side)
    local section = tab:AddSection(name, side)
    return section
end

-- WORLD TAB
local TabWorld = Win:AddTab("World FX", "earth")
local WorldLeft = addSection(TabWorld, "Environment", "left")
local WorldRight = addSection(TabWorld, "Weather", "right")

WorldLeft:AddToggle("Enable Night Mode", false, function(v)
    STATE.NightMode = v
    ApplyNightMode()
end)
WorldLeft:AddColorpicker("Night Tint", STATE.NightTint, function(c)
    STATE.NightTint = c
    if STATE.NightMode then ApplyNightMode() end
end)
WorldLeft:AddSlider("Night Brightness", 0, 3, STATE.NightBrightness, function(v)
    STATE.NightBrightness = v
    if STATE.NightMode then ApplyNightMode() end
end)

WorldRight:AddDropdown("Weather", {"Clear","Rain","Fog","Snow","Sandstorm","CyberRain"}, function(opt)
    STATE.Weather = opt
    ApplyWeather(opt)
end)
WorldRight:AddButton("Clear Weather", function()
    STATE.Weather = "Clear"
    ClearWeather()
end)
WorldRight:AddSlider("Rain Intensity", 0, 800, 400, function(v)
    -- soft control: recreate rain with new intensity if rain active
    if STATE.Weather == "Rain" then
        ApplyWeather("Rain")
    end
end)

-- ATMOSPHERE TAB
local TabAtmos = Win:AddTab("Atmosphere", "cosmetics")
local AtmLeft = addSection(TabAtmos, "Particles", "left")
local AtmRight = addSection(TabAtmos, "Ambient", "right")

AtmLeft:AddToggle("Air Particles", false, function(v)
    STATE.AirParticles.Enabled = v
    ToggleAirParticles(v)
end)
AtmLeft:AddSlider("Air Density", 0, 60, STATE.AirParticles.Density, function(v)
    STATE.AirParticles.Density = v
    if STATE.AirParticles.Enabled then ToggleAirParticles(true) end
end)
AtmRight:AddDropdown("Air Texture", {"Default","Soft Glow","Dust"}, function(opt)
    if opt == "Default" then
        STATE.AirParticles.Texture = "rbxassetid://2581284631"
    elseif opt == "Soft Glow" then
        STATE.AirParticles.Texture = "rbxassetid://241594314"
    elseif opt == "Dust" then
        STATE.AirParticles.Texture = "rbxassetid://2558574132"
    end
    if STATE.AirParticles.Enabled then ToggleAirParticles(true) end
end)

-- PLAYER FX TAB
local TabPlayer = Win:AddTab("Player FX", "user")
local PlLeft = addSection(TabPlayer, "Self Visuals", "left")
local PlRight = addSection(TabPlayer, "Advanced", "right")

PlLeft:AddToggle("Neon Outline", false, function(v)
    STATE.Outline.Enabled = v
    ApplyOutlineSettings()
end)
PlRight:AddColorpicker("Outline Color", STATE.Outline.Color, function(c)
    STATE.Outline.Color = c
    ApplyOutlineSettings()
end)
PlRight:AddSlider("Outline Thickness", 1, 6, STATE.Outline.Thickness, function(v)
    STATE.Outline.Thickness = math.floor(v)
    ApplyOutlineSettings()
end)

PlLeft:AddToggle("Aura Glow", false, function(v)
    STATE.FX.Aura.Enabled = v
    CreateOrUpdateAura()
end)
PlLeft:AddColorpicker("Aura Color", STATE.FX.Aura.Color, function(c)
    STATE.FX.Aura.Color = c
    CreateOrUpdateAura()
end)
PlRight:AddToggle("Tron Lines", false, function(v)
    STATE.FX.Tron.Enabled = v
    ApplyTron(v)
end)
PlRight:AddToggle("Sparks", false, function(v)
    STATE.FX.Sparks.Enabled = v
    ToggleSparks(v)
end)
PlRight:AddToggle("Fire Feet", false, function(v)
    STATE.FX.FireFeet.Enabled = v
    ToggleFireFeet(v)
end)

-- FILTERS TAB
local TabFilter = Win:AddTab("Filters", "camera")
local FlLeft = addSection(TabFilter, "Color Filters", "left")
local FlRight = addSection(TabFilter, "Bloom/DoF", "right")

FlLeft:AddToggle("Enable Color Filter", false, function(v)
    STATE.Filters.Enabled = v
    ApplyColorFilter(STATE.Filters.Name)
end)
FlLeft:AddDropdown("Filter Preset", {"Default","Cyber","NeonPink","Vaporwave","ColdBlue"}, function(opt)
    STATE.Filters.Name = opt
    if STATE.Filters.Enabled then ApplyColorFilter(opt) end
end)

FlRight:AddToggle("Enable Bloom", false, function(v)
    CameraEffects.ToggleBloom(v)
end)
FlRight:AddToggle("Film Grain", false, function(v)
    CameraEffects.ToggleGrain(v)
end)

-- CAMERA TAB
local TabCamera = Win:AddTab("Camera FX", "camera")
local CamLeft = addSection(TabCamera, "Effects", "left")
local CamRight = addSection(TabCamera, "Settings", "right")

CamLeft:AddToggle("Motion Blur (soft)", false, function(v)
    CameraEffects.ToggleMotionBlur(v)
end)
CamLeft:AddToggle("Chromatic Aberration", false, function(v)
    CameraEffects.ToggleChromatic(v)
end)
CamLeft:AddToggle("Grain", false, function(v)
    CameraEffects.ToggleGrain(v)
end)
CamRight:AddSlider("Pseudo-Motion Strength", 0, 1, 0.35, function(v)
    -- used by Run loop if motion blur enabled
    STATE.Camera.MotionStrength = v
end)

-- SPECIAL FX TAB (Mega features)
local TabSpecial = Win:AddTab("Special FX", "cosmetics")
local SpLeft = addSection(TabSpecial, "Mega FX", "left")
local SpRight = addSection(TabSpecial, "Extras", "right")

SpLeft:AddButton("Spawn Celebration (Confetti)", function()
    -- lightweight confetti around player
    local root = LocalPlayer.Character and (LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or LocalPlayer.Character:FindFirstChildWhichIsA("BasePart"))
    if not root then return end
    local p = Instance.new("ParticleEmitter")
    p.Name = "VFX_Confetti"
    p.Texture = "rbxassetid://283133242"
    p.Rate = 200
    p.Lifetime = NumberRange.new(1.5,2.8)
    p.Speed = NumberRange.new(6,12)
    p.Size = NumberSequence.new(0.2)
    p.Parent = root
    task.delay(3, function() safeDestroy(p) end)
end)

SpLeft:AddButton("Starfall Aura", function()
    -- spawn a few falling star particles above world
    local p = Instance.new("ParticleEmitter")
    p.Name = "VFX_Starfall"
    p.Texture = "rbxassetid://241594314"
    p.Rate = 80
    p.Lifetime = NumberRange.new(2,4)
    p.Speed = NumberRange.new(6,10)
    p.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.2), NumberSequenceKeypoint.new(1,0.05)})
    p.Parent = workspace.Terrain
    task.delay(6, function() safeDestroy(p) end)
end)

SpRight:AddToggle("Enable Warp Sprint FX", false, function(v)
    STATE.FX.WarpSprint = v
end)

SpRight:AddToggle("Enable AntiGravity FX", false, function(v)
    STATE.FX.AntiGravity = v
end)

-- MISC TAB: utility and debug
local TabMisc = Win:AddTab("Misc VFX", "gear")
local McLeft = addSection(TabMisc, "Utilities", "left")
local McRight = addSection(TabMisc, "Debug", "right")

McLeft:AddButton("Reset All VFX", function()
    -- reset many states and destroy created objects
    STATE.NightMode = false
    STATE.Weather = "Clear"
    STATE.AirParticles.Enabled = false
    STATE.Outline.Enabled = false
    STATE.FX = {Aura={Enabled=false,Color=Color3.fromRGB(120,0,255),Radius=8}, Tron={Enabled=false}, Sparks={Enabled=false}, FireFeet={Enabled=false}}
    STATE.Filters.Enabled = false
    CameraEffects.ToggleBloom(false)
    CameraEffects.ToggleChromatic(false)
    CameraEffects.ToggleGrain(false)
    -- apply resets
    ApplyNightMode()
    ClearWeather()
    ToggleAirParticles(false)
    ApplyOutlineSettings()
    CreateOrUpdateAura()
    ApplyTron(false)
    ToggleSparks(false)
    ToggleFireFeet(false)
    ApplyColorFilter()
    -- remove temporary world effects
    warn("[VFX PACK] All VFX reset.")
end)

McRight:AddButton("Test All Effects (One-shot)", function()
    -- quick demo: spawn small burst of many fx
    local root = LocalPlayer.Character and (LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or LocalPlayer.Character:FindFirstChildWhichIsA("BasePart"))
    if not root then return end
    -- confetti
    local conf = Instance.new("ParticleEmitter")
    conf.Texture = "rbxassetid://283133242"
    conf.Rate = 200
    conf.Lifetime = NumberRange.new(1.2,2.2)
    conf.Parent = root
    -- sparks
    local s = Instance.new("ParticleEmitter")
    s.Texture = "rbxassetid://252907615"
    s.Rate = 60
    s.Lifetime = NumberRange.new(0.2,0.6)
    s.Parent = root
    task.delay(3, function() safeDestroy(conf); safeDestroy(s) end)
end)

-- ==================================================================================
--                              RUNTIME UPDATE LOOP
-- ==================================================================================
-- This loop handles motion blur emulation, warp sprint detection, and dynamic updates

local lastPos = nil
local sprinting = false

RunService.RenderStepped:Connect(function(dt)
    -- Aura updates
    if STATE.FX.Aura.Enabled then
        pcall(CreateOrUpdateAura)
    end

    -- Outline ensure
    if STATE.Outline.Enabled then
        pcall(ApplyOutlineSettings)
    end

    -- Tron animate: slowly pulse neon color
    if STATE.FX.Tron.Enabled then
        pcall(function()
            local char = LocalPlayer.Character
            if not char then return end
            for _,part in pairs(char:GetChildren()) do
                if part:IsA("Part") and part.Name == "VFX_TronLine" then
                    -- pulse transparency
                    part.Transparency = 0.2 + (math.sin(tick()*2)+1)/10
                end
            end
        end)
    end

    -- Motion blur emulation: if enabled and camera speed high
    if STATE.Camera.MotionBlur and STATE.Camera.MotionStrength then
        local cam = workspace.CurrentCamera
        local vel = cam and cam.Focus and (cam.Focus.p - (lastPos or cam.Focus.p)).magnitude/dt or 0
        -- apply small FOV tween to fake blur
        if vel > 7 then
            if not workspace.CurrentCamera:GetAttribute("VFX_MotionActive") then
                workspace.CurrentCamera:SetAttribute("VFX_MotionActive", true)
                local s = TweenService:Create(workspace.CurrentCamera, TweenInfo.new(0.25), {FieldOfView = math.clamp(70 + STATE.Camera.MotionStrength*20, 70, 110)})
                s:Play()
            end
        else
            if workspace.CurrentCamera:GetAttribute("VFX_MotionActive") then
                workspace.CurrentCamera:SetAttribute("VFX_MotionActive", nil)
                local s = TweenService:Create(workspace.CurrentCamera, TweenInfo.new(0.45), {FieldOfView = 70})
                s:Play()
            end
        end
    end

    -- Warp sprint: create trail while moving fast
    if STATE.FX.WarpSprint then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local hrp = char.HumanoidRootPart
            local vel = hrp.Velocity.magnitude
            if vel > 32 then
                -- spawn small trail parts
                local trail = Instance.new("Part")
                trail.Size = Vector3.new(0.2,0.2,0.2)
                trail.Anchored = true
                trail.CanCollide = false
                trail.CFrame = hrp.CFrame * CFrame.new(0, -2, 0)
                trail.Transparency = 0.2
                trail.Material = Enum.Material.Neon
                trail.Color = Color3.fromRGB(80,200,255)
                trail.Parent = workspace.Terrain
                game:GetService("Debris"):AddItem(trail, 0.5)
            end
        end
    end

    -- AntiGravity FX: slow floating particles around player
    if STATE.FX.AntiGravity then
        -- spawn occasional glowing particles
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            if math.random() < 0.02 then
                local part = Instance.new("Part")
                part.Size = Vector3.new(0.1,0.1,0.1)
                part.Anchored = true
                part.CanCollide = false
                local hrp = char.HumanoidRootPart
                part.CFrame = hrp.CFrame * CFrame.new(math.random(-4,4), math.random(-2,4), math.random(-4,4))
                part.Material = Enum.Material.Neon
                part.Color = Color3.fromRGB(200,200,255)
                part.Parent = workspace.Terrain
                game:GetService("Debris"):AddItem(part, 2)
            end
        end
    end

    lastPos = workspace.CurrentCamera and workspace.CurrentCamera.Focus and workspace.CurrentCamera.Focus.p or lastPos
end)

-- ==================================================================================
--                              CHARACTER/RESPAWN HOOKS
-- ==================================================================================

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    -- reapply persistent effects
    if STATE.Outline.Enabled then ApplyOutlineSettings() end
    if STATE.FX.Aura.Enabled then CreateOrUpdateAura() end
    if STATE.FX.Sparks.Enabled then ToggleSparks(true) end
    if STATE.FX.FireFeet.Enabled then ToggleFireFeet(true) end
    if STATE.FX.Tron.Enabled then ApplyTron(true) end
end)

-- ==================================================================================
--                              FINAL NOTES & READY
-- ==================================================================================

print("[VFX MEGA PACK] Loaded. UI created in Neverlose window. Use RightShift (or your UI hotkey) to open.")

-- End of file
