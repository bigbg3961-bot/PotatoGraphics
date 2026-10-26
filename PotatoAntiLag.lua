--==================================================
-- ULTRA POTATO V4 - EXTREME FPS
-- Roblox Studio / LocalScript
--==================================================

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Enabled = false
local CurrentMode = "EXTREME"
local Processing = false

-- Sauvegarde des propriétés d'origine
local Original = setmetatable({}, {__mode = "k"})

local function saveAndSet(obj, property, value)
    local ok, oldValue = pcall(function()
        return obj[property]
    end)

    if not ok then
        return
    end

    if not Original[obj] then
        Original[obj] = {}
    end

    if Original[obj][property] == nil then
        Original[obj][property] = oldValue
    end

    pcall(function()
        obj[property] = value
    end)
end

--==================================================
-- RESTAURATION
--==================================================

local function restoreAll()
    for obj, properties in pairs(Original) do
        if obj and obj.Parent then
            for property, value in pairs(properties) do
                pcall(function()
                    obj[property] = value
                end)
            end
        end
    end

    table.clear(Original)
end

--==================================================
-- OPTIMISATION DE L'ÉCLAIRAGE
--==================================================

local function optimizeLighting(obj, mode)
    if obj:IsA("PostEffect") then
        saveAndSet(obj, "Enabled", false)
    end

    if obj:IsA("PointLight")
        or obj:IsA("SpotLight")
        or obj:IsA("SurfaceLight") then

        saveAndSet(obj, "Enabled", false)
    end

    if obj:IsA("Atmosphere") and mode ~= "LOW" then
        saveAndSet(obj, "Density", 0)
        saveAndSet(obj, "Haze", 0)
        saveAndSet(obj, "Glare", 0)
    end
end

--==================================================
-- OPTIMISATION DES OBJETS
--==================================================

local function optimizeObject(obj, mode)
    -- Textures et images
    if obj:IsA("Decal") or obj:IsA("Texture") then
        if mode ~= "LOW" then
            saveAndSet(obj, "Transparency", 1)
        end
    end

    -- Textures des modèles 3D
    if mode ~= "LOW" then
        if obj:IsA("MeshPart") then
            saveAndSet(obj, "TextureID", "")
            saveAndSet(
                obj,
                "RenderFidelity",
                Enum.RenderFidelity.Performance
            )
        elseif obj:IsA("SpecialMesh") then
            saveAndSet(obj, "TextureId", "")
        elseif obj:IsA("SurfaceAppearance") then
            saveAndSet(obj, "ColorMap", "")
            saveAndSet(obj, "MetalnessMap", "")
            saveAndSet(obj, "NormalMap", "")
            saveAndSet(obj, "RoughnessMap", "")
        end
    end

    -- Pièces et matériaux
    if obj:IsA("BasePart") then
        saveAndSet(obj, "CastShadow", false)
        saveAndSet(obj, "Reflectance", 0)

        if mode ~= "LOW" then
            saveAndSet(obj, "Material", Enum.Material.Plastic)
            saveAndSet(obj, "MaterialVariant", "")
        end
    end

    -- Particules et effets
    if obj:IsA("ParticleEmitter")
        or obj:IsA("Trail")
        or obj:IsA("Beam")
        or obj:IsA("Fire")
        or obj:IsA("Smoke")
        or obj:IsA("Sparkles") then

        saveAndSet(obj, "Enabled", false)
    end
end

--==================================================
-- APPLICATION DES MODES
--==================================================

local function applyMode(mode)
    if Processing then
        return
    end

    Processing = true
    Enabled = true
    CurrentMode = mode

    -- Réglages généraux
    saveAndSet(Lighting, "GlobalShadows", false)

    if mode == "ULTRA LOW" or mode == "EXTREME" then
        saveAndSet(Lighting, "FogEnd", 1000000)
        saveAndSet(Lighting, "Brightness", 1)
    end

    -- Éclairage
    for _, obj in ipairs(Lighting:GetDescendants()) do
        optimizeLighting(obj, mode)
    end

    -- Terrain
    local terrain = Workspace:FindFirstChildOfClass("Terrain")

    if terrain and mode ~= "LOW" then
        saveAndSet(terrain, "Decoration", false)
        saveAndSet(terrain, "WaterWaveSize", 0)
        saveAndSet(terrain, "WaterWaveSpeed", 0)
        saveAndSet(terrain, "WaterReflectance", 0)
    end

    -- Traiter les objets par lots pour éviter de bloquer
    -- le client pendant un long moment.
    local descendants = Workspace:GetDescendants()

    for i, obj in ipairs(descendants) do
        if not Enabled or CurrentMode ~= mode then
            break
        end

        optimizeObject(obj, mode)

        if i % 300 == 0 then
            task.wait()
        end
    end

    Processing = false
end

--==================================================
-- INTERFACE
--==================================================

local gui = Instance.new("ScreenGui")
gui.Name = "UltraPotatoV4"
gui.ResetOnSpawn = false
gui.Parent = PlayerGui

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = UDim2.fromOffset(310, 315)
frame.Position = UDim2.new(0, 20, 0.5, -157)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
frame.BorderSizePixel = 0
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(90, 255, 100)
stroke.Thickness = 2
stroke.Parent = frame

local function makeLabel(text, position, size, parent)
    local label = Instance.new("TextLabel")
    label.Size = size
    label.Position = position
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.Parent = parent
    return label
end

makeLabel(
    "POTATO GRAPHICS V4",
    UDim2.fromOffset(10, 10),
    UDim2.new(1, -20, 0, 30),
    frame
)

local fpsLabel = makeLabel(
    "FPS : calcul...",
    UDim2.fromOffset(10, 45),
    UDim2.new(1, -20, 0, 25),
    frame
)

local statusLabel = makeLabel(
    "Statut : désactivé",
    UDim2.fromOffset(10, 72),
    UDim2.new(1, -20, 0, 22),
    frame
)

local function makeButton(text, y, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -30, 0, 34)
    button.Position = UDim2.fromOffset(15, y)
    button.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Text = text
    button.Font = Enum.Font.GothamBold
    button.TextSize = 14
    button.BorderSizePixel = 0
    button.Parent = frame

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 7)
    buttonCorner.Parent = button

    button.Activated:Connect(callback)

    return button
end

makeButton("LOW", 103, function()
    if Processing then return end
    restoreAll()
    applyMode("LOW")
    statusLabel.Text = "Statut : LOW"
end)

makeButton("ULTRA LOW", 143, function()
    if Processing then return end
    restoreAll()
    applyMode("ULTRA LOW")
    statusLabel.Text = "Statut : ULTRA LOW"
end)

makeButton("EXTREME POTATO", 183, function()
    if Processing then return end
    restoreAll()
    applyMode("EXTREME")
    statusLabel.Text = "Statut : EXTREME"
end)

makeButton("RESTAURER", 223, function()
    Enabled = false
    CurrentMode = "RESTORE"

    while Processing do
        task.wait()
    end

    restoreAll()
    statusLabel.Text = "Statut : restauré"
end)

makeButton("FERMER L'INTERFACE", 263, function()
    gui.Enabled = false
end)

--==================================================
-- OPTIMISATION DES NOUVEAUX OBJETS
--==================================================

Workspace.DescendantAdded:Connect(function(obj)
    task.defer(function()
        if Enabled and obj.Parent then
            optimizeObject(obj, CurrentMode)
        end
    end)
end)

Lighting.DescendantAdded:Connect(function(obj)
    task.defer(function()
        if Enabled and obj.Parent then
            optimizeLighting(obj, CurrentMode)
        end
    end)
end)

--==================================================
-- COMPTEUR FPS
--==================================================

local frames = 0
local elapsed = 0

RunService.RenderStepped:Connect(function(dt)
    frames += 1
    elapsed += dt

    if elapsed >= 1 then
        local fps = math.floor(frames / elapsed + 0.5)
        fpsLabel.Text = "FPS : " .. fps

        frames = 0
        elapsed = 0
    end
end)

print("ULTRA POTATO V4 chargé.")
