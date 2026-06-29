local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local Storage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")

local localPlayer = Players.LocalPlayer
local DISCORD_INVITE = "https://discord.gg/s2DXVF2V8"

local function resolveExecutorName()
    if type(identifyexecutor) ~= "function" then
        return "Unknown"
    end

    local ok, result = pcall(identifyexecutor)
    if not ok or result == nil then
        return "Unknown"
    end

    local name = tostring(result)
    if name == "" then
        return "Unknown"
    end

    return name
end

local EXECUTOR_NAME = resolveExecutorName()

local UI_LIBRARY_URLS = {
    "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/Library.lua",
    "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua",
    "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/master/Library.lua",
}
local UI_LIBRARY_CACHE_FILE = "PLunderHub_ObsidianLibrary.lua"

local function loadUiLibrary()
    local function fetchRemoteUiSource()
        for _, url in ipairs(UI_LIBRARY_URLS) do
            local okFetch, source = pcall(function()
                return game:HttpGet(url)
            end)

            if okFetch and type(source) == "string" and source ~= "" then
                return source
            end
        end

        return nil
    end

    local function compileAndRun(source)
        if type(source) ~= "string" or source == "" then
            return nil
        end

        local okChunk, chunk = pcall(loadstring, source)
        if not okChunk or type(chunk) ~= "function" then
            return nil
        end

        local okLibrary, library = pcall(chunk)
        if not okLibrary then
            return nil
        end

        return library
    end

    local cachedSource = nil
    if isfile and readfile then
        local okCached, data = pcall(readfile, UI_LIBRARY_CACHE_FILE)
        if okCached and type(data) == "string" and data ~= "" then
            cachedSource = data
            local cachedLibrary = compileAndRun(cachedSource)
            if cachedLibrary then
                task.defer(function()
                    local latestSource = fetchRemoteUiSource()

                    if type(latestSource) == "string"
                        and latestSource ~= ""
                        and latestSource ~= cachedSource
                        and writefile
                    then
                        pcall(function()
                            writefile(UI_LIBRARY_CACHE_FILE, latestSource)
                        end)
                    end
                end)

                return cachedLibrary
            end
        end
    end

    local remoteSource = fetchRemoteUiSource()
    if type(remoteSource) ~= "string" or remoteSource == "" then
        return nil
    end

    if writefile then
        pcall(function()
            writefile(UI_LIBRARY_CACHE_FILE, remoteSource)
        end)
    end

    return compileAndRun(remoteSource)
end

local Library = loadUiLibrary()
if not Library then
    error("PLunder Hub: failed to load UI library", 0)
end

local UiTheme = {
    Background = Color3.fromRGB(24, 8, 10),
    Panel = Color3.fromRGB(37, 12, 15),
    Accent = Color3.fromRGB(201, 42, 62),
    AccentSoft = Color3.fromRGB(236, 95, 112),
    TextMain = Color3.fromRGB(255, 235, 238),
    TextSoft = Color3.fromRGB(232, 170, 178),
    TextMuted = Color3.fromRGB(177, 112, 121),
    AccentText = Color3.fromRGB(36, 3, 8),
    Error = Color3.fromRGB(255, 120, 130),
}

if Library and Library.Scheme then
    Library.Scheme.BackgroundColor = UiTheme.Background
    Library.Scheme.MainColor = UiTheme.Panel
    Library.Scheme.AccentColor = UiTheme.Accent
    Library.Scheme.OutlineColor = UiTheme.AccentSoft
    Library.Scheme.FontColor = UiTheme.TextMain
    Library.Scheme.RedColor = UiTheme.Error
    Library.Scheme.DestructiveColor = UiTheme.Accent
    Library.Scheme.DarkColor = UiTheme.AccentText
    Library.Scheme.WhiteColor = UiTheme.TextMain

    pcall(function()
        Library:UpdateColorsUsingRegistry()
    end)
end

local function cfgPath(tag)
    return ("PLunderHub_RIVALS_%s_%s.json"):format((localPlayer.Name or "u"):gsub("[^%w]", ""), tag)
end

local function saveCfg(tag, data)
    if not writefile then
        return
    end

    pcall(function()
        writefile(cfgPath(tag), HttpService:JSONEncode(data))
    end)
end

local function loadCfg(tag, defaults)
    if not isfile or not isfile(cfgPath(tag)) then
        return defaults
    end

    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(readfile(cfgPath(tag)))
    end)

    if not ok or type(decoded) ~= "table" then
        return defaults
    end

    for k, v in pairs(defaults) do
        if decoded[k] == nil then
            decoded[k] = v
        end
    end

    return decoded
end

local function loadBuilds()
    if not isfile or not isfile(cfgPath("builds")) then
        return {}
    end

    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(readfile(cfgPath("builds")))
    end)

    return (ok and type(decoded) == "table") and decoded or {}
end

local function saveBuilds(builds)
    if not writefile then
        return
    end

    pcall(function()
        writefile(cfgPath("builds"), HttpService:JSONEncode(builds))
    end)
end

local function getAutoLoad()
    if not isfile or not isfile(cfgPath("autoload")) then
        return nil
    end

    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(readfile(cfgPath("autoload")))
    end)

    return (ok and type(decoded) == "table") and decoded.buildName or nil
end

local function setAutoLoad(name)
    if name then
        saveCfg("autoload", { buildName = name })
        return
    end

    if delfile then
        pcall(function()
            delfile(cfgPath("autoload"))
        end)
    end
end

local function notify(text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "PLunder Hub",
            Text = text,
            Duration = duration or 3,
        })
    end)
end

local function trim(text)
    return (text or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local ON = loadCfg("toggles", {
    aimbot = false,
    esp = false,
    chams = false,
    tracers = false,
    skeletonesp = false,
    nameesp = false,
    wallcheck = false,
    showfov = false,
    norecoil = false,
    triggerbot = false,
    antiafk = false,
})

local STARTUP_SAFE_COMBAT_KEYS = { "triggerbot", "norecoil" }

local function enforceSafeStartupToggles()
    local changed = false

    for _, key in ipairs(STARTUP_SAFE_COMBAT_KEYS) do
        if ON[key] == true then
            ON[key] = false
            changed = true
        end
    end

    if changed then
        saveCfg("toggles", ON)
    end

    return changed
end

enforceSafeStartupToggles()

local Cfg = loadCfg("cfg", {
    fovRadius = 150,
    smoothing = 0.25,
    maxDist = 800,
    aimbotFovRadius = 150,
    aimbotMaxDistance = 800,
    aimbotTargetPart = "Head",
    aimbotStickyTarget = true,
    aimbotSnap = true,
    aimbotPrediction = 0.1,
    aimbotPriority = "Crosshair",
    aimbotProjectileSpeed = 2200,
    aimbotRetainFovScale = 1.35,
    aimbotSwitchDelay = 0.14,
    aimbotDeadzone = 2,
    aimbotAdaptiveSmoothing = true,
    aimbotSmoothMin = 0.08,
    aimbotSmoothMax = 0.92,
    aimbotResponseCurve = 1.2,
    aimbotVelocityLead = 1,
    aimbotAccelerationLead = 0.35,
    aimbotPredictionBlend = 0.6,
    aimbotSwitchScoreGap = 3.5,
    aimbotLockPersistence = 0.16,
    aimbotMaxTurnRate = 1080,
    triggerbotCooldown = 0.08,
    triggerbotMaxDistance = 1400,
    nameEspMaxDistance = 2000,
    nameEspTextSize = 13,
    tracerThickness = 1.5,
    skeletonThickness = 1.3,
})

local Keybinds = loadCfg("keybinds", {
    aimbot = "None",
    esp = "H",
    chams = "J",
    tracers = "None",
    skeletonesp = "None",
    nameesp = "None",
    wallcheck = "K",
    showfov = "B",
    norecoil = "None",
    triggerbot = "None",
    antiafk = "None",
    togglehub = "L",
})

local connections = {}
local scriptAlive = true
local espBoxes = {}
local chamsMap = {}
local tracerLines = {}
local skeletonLines = {}
local nameEspTexts = {}
local activeLoadedBuild = nil
local DRAWING_AVAILABLE = type(Drawing) == "table" and type(Drawing.new) == "function"

local uiRefs = {
    FeatureToggles = {},
    KeybindDropdowns = {},
    BuildDropdown = nil,
    TargetLabel = nil,
    AutoLoadLabel = nil,
    FovSlider = nil,
    SmoothSlider = nil,
    MaxDistSlider = nil,
    AimbotPartDropdown = nil,
    AimbotStickyToggle = nil,
    AimbotSnapToggle = nil,
    AimbotPredictionSlider = nil,
    AimbotPriorityDropdown = nil,
    AimbotProjectileSlider = nil,
    AimbotRetainFovSlider = nil,
    AimbotSwitchDelaySlider = nil,
    AimbotDeadzoneSlider = nil,
    AimbotAdaptiveSmoothingToggle = nil,
    AimbotSmoothMinSlider = nil,
    AimbotSmoothMaxSlider = nil,
    AimbotResponseCurveSlider = nil,
    AimbotVelocityLeadSlider = nil,
    AimbotAccelerationLeadSlider = nil,
    AimbotMaxTurnRateSlider = nil,
    TriggerbotCooldownSlider = nil,
    TriggerbotDistanceSlider = nil,
    NameEspDistanceSlider = nil,
    NameEspTextSizeSlider = nil,
    TracerThicknessSlider = nil,
    SkeletonThicknessSlider = nil,
}

local function keyOrNone(value)
    if type(value) ~= "string" or value == "" then
        return "None"
    end
    return value
end

local function getKeyOptions()
    local keys = { "None" }

    for _, enumItem in ipairs(Enum.KeyCode:GetEnumItems()) do
        local name = enumItem.Name
        local blocked = name == "Unknown"
            or name:match("^Button")
            or name:match("^DPad")
            or name:match("^Thumbstick")
            or name:match("^World")

        if not blocked then
            table.insert(keys, name)
        end
    end

    table.sort(keys, function(a, b)
        if a == "None" then
            return true
        end
        if b == "None" then
            return false
        end
        return a < b
    end)

    return keys
end

local function indexOf(values, value)
    for idx, item in ipairs(values) do
        if item == value then
            return idx
        end
    end
    return 1
end

local KEY_OPTIONS = getKeyOptions()
local AIMBOT_PART_OPTIONS = { "Head", "HumanoidRootPart", "UpperTorso", "Torso" }
local AIMBOT_PRIORITY_OPTIONS = { "Crosshair", "Distance", "Health" }
local SKELETON_SEGMENTS = {
    { from = { "Head" }, to = { "UpperTorso", "Torso" } },
    { from = { "UpperTorso" }, to = { "LowerTorso" } },
    { from = { "UpperTorso", "Torso" }, to = { "LeftUpperArm", "Left Arm" } },
    { from = { "LeftUpperArm" }, to = { "LeftLowerArm" } },
    { from = { "LeftLowerArm" }, to = { "LeftHand" } },
    { from = { "UpperTorso", "Torso" }, to = { "RightUpperArm", "Right Arm" } },
    { from = { "RightUpperArm" }, to = { "RightLowerArm" } },
    { from = { "RightLowerArm" }, to = { "RightHand" } },
    { from = { "LowerTorso", "Torso" }, to = { "LeftUpperLeg", "Left Leg" } },
    { from = { "LeftUpperLeg" }, to = { "LeftLowerLeg" } },
    { from = { "LeftLowerLeg" }, to = { "LeftFoot" } },
    { from = { "LowerTorso", "Torso" }, to = { "RightUpperLeg", "Right Leg" } },
    { from = { "RightUpperLeg" }, to = { "RightLowerLeg" } },
    { from = { "RightLowerLeg" }, to = { "RightFoot" } },
}

if not table.find(AIMBOT_PART_OPTIONS, Cfg.aimbotTargetPart) then
    Cfg.aimbotTargetPart = "Head"
end

if Cfg.aimbotStickyTarget == nil then
    Cfg.aimbotStickyTarget = true
end

if Cfg.aimbotSnap == nil then
    Cfg.aimbotSnap = true
end

if not table.find(AIMBOT_PRIORITY_OPTIONS, Cfg.aimbotPriority) then
    Cfg.aimbotPriority = "Crosshair"
end

local aimbotFovRadius = tonumber(Cfg.aimbotFovRadius)
if not aimbotFovRadius or aimbotFovRadius <= 0 then
    aimbotFovRadius = tonumber(Cfg.fovRadius) or 150
end

Cfg.aimbotFovRadius = math.clamp(aimbotFovRadius, 50, 500)
Cfg.fovRadius = Cfg.aimbotFovRadius

local aimbotMaxDistance = tonumber(Cfg.aimbotMaxDistance)
if not aimbotMaxDistance or aimbotMaxDistance <= 0 then
    aimbotMaxDistance = tonumber(Cfg.maxDist) or 800
end

Cfg.aimbotMaxDistance = math.clamp(aimbotMaxDistance, 100, 3000)
Cfg.maxDist = Cfg.aimbotMaxDistance

Cfg.aimbotPrediction = math.clamp(tonumber(Cfg.aimbotPrediction) or 0.1, 0, 0.45)
Cfg.aimbotProjectileSpeed = math.clamp(tonumber(Cfg.aimbotProjectileSpeed) or 2200, 0, 6000)
Cfg.aimbotRetainFovScale = math.clamp(tonumber(Cfg.aimbotRetainFovScale) or 1.35, 1, 3)
Cfg.aimbotSwitchDelay = math.clamp(tonumber(Cfg.aimbotSwitchDelay) or 0.14, 0, 1)
Cfg.aimbotDeadzone = math.clamp(tonumber(Cfg.aimbotDeadzone) or 2, 0, 35)

local function normalizeAimbotAdvancedCfg()
    Cfg.aimbotAdaptiveSmoothing = Cfg.aimbotAdaptiveSmoothing ~= false
    Cfg.aimbotSmoothMin = math.clamp(tonumber(Cfg.aimbotSmoothMin) or 0.08, 0.01, 0.95)
    Cfg.aimbotSmoothMax = math.clamp(tonumber(Cfg.aimbotSmoothMax) or 0.92, Cfg.aimbotSmoothMin + 0.01, 0.995)
    Cfg.aimbotResponseCurve = math.clamp(tonumber(Cfg.aimbotResponseCurve) or 1.2, 0.5, 3)
    Cfg.aimbotVelocityLead = math.clamp(tonumber(Cfg.aimbotVelocityLead) or 1, 0, 2.5)
    Cfg.aimbotAccelerationLead = math.clamp(tonumber(Cfg.aimbotAccelerationLead) or 0.35, 0, 2)
    Cfg.aimbotPredictionBlend = math.clamp(tonumber(Cfg.aimbotPredictionBlend) or 0.6, 0, 1)
    Cfg.aimbotSwitchScoreGap = math.clamp(tonumber(Cfg.aimbotSwitchScoreGap) or 3.5, 0, 20)
    Cfg.aimbotLockPersistence = math.clamp(tonumber(Cfg.aimbotLockPersistence) or 0.16, 0, 0.6)
    Cfg.aimbotMaxTurnRate = math.clamp(tonumber(Cfg.aimbotMaxTurnRate) or 1080, 240, 3000)
end

normalizeAimbotAdvancedCfg()
Cfg.triggerbotCooldown = math.clamp(tonumber(Cfg.triggerbotCooldown) or 0.08, 0.02, 1)
Cfg.triggerbotMaxDistance = math.clamp(tonumber(Cfg.triggerbotMaxDistance) or 1400, 200, 5000)
Cfg.nameEspMaxDistance = math.clamp(tonumber(Cfg.nameEspMaxDistance) or 2000, 200, 5000)
Cfg.nameEspTextSize = math.clamp(tonumber(Cfg.nameEspTextSize) or 13, 11, 24)
Cfg.tracerThickness = math.clamp(tonumber(Cfg.tracerThickness) or 1.5, 1, 6)
Cfg.skeletonThickness = math.clamp(tonumber(Cfg.skeletonThickness) or 1.3, 1, 6)

local triggerbotLastShotAt = 0
local aimbotLastSwitchAt = 0
local aimbotLockedTarget = nil
local aimbotLockedPart = nil
local aimbotLockedScore = nil
local aimbotLockAcquiredAt = 0
local antiAfkConnection = nil

local function destroyDrawingObject(obj)
    if not obj then
        return
    end

    pcall(function()
        obj.Visible = false
    end)

    pcall(function()
        obj:Remove()
    end)
end

local function createDrawingLine(color, thickness, transparency)
    if not DRAWING_AVAILABLE then
        return nil
    end

    local ok, line = pcall(Drawing.new, "Line")
    if not ok or not line then
        return nil
    end

    line.Visible = false
    line.Color = color or UiTheme.AccentSoft
    line.Thickness = thickness or 1.5
    line.Transparency = transparency or 1
    return line
end

local function createDrawingText(color, size, center)
    if not DRAWING_AVAILABLE then
        return nil
    end

    local ok, textObj = pcall(Drawing.new, "Text")
    if not ok or not textObj then
        return nil
    end

    textObj.Visible = false
    textObj.Color = color or UiTheme.TextMain
    textObj.Size = size or 13
    textObj.Center = center ~= false
    textObj.Outline = true
    textObj.OutlineColor = Color3.fromRGB(0, 0, 0)
    textObj.Font = 2
    return textObj
end

local function clearTracerLines()
    for model, line in pairs(tracerLines) do
        destroyDrawingObject(line)
        tracerLines[model] = nil
    end
end

local function clearSkeletonLines()
    for model, lines in pairs(skeletonLines) do
        for _, line in ipairs(lines) do
            destroyDrawingObject(line)
        end
        skeletonLines[model] = nil
    end
end

local function clearNameEspTexts()
    for model, textObj in pairs(nameEspTexts) do
        destroyDrawingObject(textObj)
        nameEspTexts[model] = nil
    end
end

local function getPartByNames(model, names)
    if not model or not names then
        return nil
    end

    for _, name in ipairs(names) do
        local part = model:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            return part
        end
    end

    return nil
end

local function worldToScreenVector(worldPos)
    local currentCamera = Workspace.CurrentCamera
    if not currentCamera then
        return nil, false
    end

    local screenPos, onScreen = currentCamera:WorldToViewportPoint(worldPos)
    if not onScreen or screenPos.Z <= 0 then
        return nil, false
    end

    return Vector2.new(screenPos.X, screenPos.Y), true
end

local function isFiniteNumber(value)
    return type(value) == "number"
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
end

local function isFiniteVector3(value)
    return value
        and isFiniteNumber(value.X)
        and isFiniteNumber(value.Y)
        and isFiniteNumber(value.Z)
end

local function setAntiAfkEnabled(enabled)
    if antiAfkConnection then
        antiAfkConnection:Disconnect()
        antiAfkConnection = nil
    end

    if not enabled then
        return
    end

    antiAfkConnection = localPlayer.Idled:Connect(function()
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0))
        end)
    end)
end

local function getPredictedAimPosition(part, myRoot, predictionValue, projectileSpeedValue, preferHeadPart)
    if not part or not part:IsA("BasePart") then
        return nil
    end

    local basePos = part.Position
    local velocity = part.AssemblyLinearVelocity or part.Velocity
    if not isFiniteVector3(velocity) then
        velocity = Vector3.new(0, 0, 0)
    end

    local wantsHeadOffset = preferHeadPart
    if wantsHeadOffset == nil then
        wantsHeadOffset = Cfg.aimbotTargetPart == "Head"
    end
    local headLikePart = part.Name == "Head" or wantsHeadOffset == true

    local predict = tonumber(predictionValue)
    if not predict then
        predict = Cfg.aimbotPrediction or 0
    end

    local projectileSpeed = tonumber(projectileSpeedValue)
    if not projectileSpeed then
        projectileSpeed = Cfg.aimbotProjectileSpeed or 0
    end

    if projectileSpeed > 0 and myRoot then
        local distance = (basePos - myRoot.Position).Magnitude
        local travelTime = distance / projectileSpeed
        predict = math.max(predict, travelTime)
    end

    predict = math.clamp(predict, 0, headLikePart and 0.45 or 0.32)

    if predict > 0 then
        local velocityLead = math.clamp(tonumber(Cfg.aimbotVelocityLead) or 1, 0, 2)
        local accelerationBoost = math.clamp(tonumber(Cfg.aimbotAccelerationLead) or 0.35, 0, 2)
        local leadScale = velocityLead * (1 + (accelerationBoost * 0.18))
        if not headLikePart then
            leadScale = leadScale * 0.82
        end

        local leadOffset = velocity * (predict * leadScale)

        if isFiniteVector3(leadOffset) then
            local maxLeadCap = headLikePart and 900 or 650
            local maxLead = maxLeadCap
            if myRoot then
                local distance = (part.Position - myRoot.Position).Magnitude
                if headLikePart then
                    maxLead = math.clamp(distance * 0.6, 30, maxLeadCap)
                else
                    maxLead = math.clamp(distance * 0.45, 18, maxLeadCap)
                end
            end

            local offsetMagnitude = leadOffset.Magnitude
            if isFiniteNumber(offsetMagnitude) and offsetMagnitude > maxLead and offsetMagnitude > 0 then
                leadOffset = leadOffset.Unit * maxLead
            end

            basePos = basePos + leadOffset
        end
    end

    local yOffset = 0
    if headLikePart then
        yOffset = 0.04
    elseif part.Name == "HumanoidRootPart" then
        yOffset = 0
    elseif part.Name == "UpperTorso" then
        yOffset = 0.02
    elseif part.Name == "Torso" then
        yOffset = 0.015
    elseif part.Name == "LowerTorso" then
        yOffset = -0.01
    else
        yOffset = math.clamp((part.Size.Y * 0.1), -0.02, 0.05)
    end

    local predicted = basePos + Vector3.new(0, yOffset, 0)
    if not isFiniteVector3(predicted) then
        return part.Position + Vector3.new(0, yOffset, 0)
    end

    return predicted
end

local function ensureSkeletonLines(model)
    if not model then
        return nil
    end

    local lines = skeletonLines[model]
    if lines then
        return lines
    end

    lines = {}
    for i = 1, #SKELETON_SEGMENTS do
        local line = createDrawingLine(UiTheme.Accent, Cfg.skeletonThickness or 1.3, 0.95)
        if not line then
            for _, created in ipairs(lines) do
                destroyDrawingObject(created)
            end
            return nil
        end
        lines[i] = line
    end

    skeletonLines[model] = lines
    return lines
end

local function getEntitiesFolder()
    return Workspace:FindFirstChild("Entities")
end

local function getMyCharacter()
    return localPlayer.Character
end

local function getMyRoot()
    local character = getMyCharacter()
    if not character then
        return nil
    end

    local root = character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("Torso")
        or character.PrimaryPart

    if root and root:IsA("BasePart") then
        return root
    end

    return nil
end

local TEAM_TOKEN_KEYS = { "Team", "team", "TeamId", "TeamID", "Faction", "faction", "Side", "side" }
local NEUTRAL_TEAM_TOKENS = {
    [""] = true,
    ["0"] = true,
    ["none"] = true,
    ["neutral"] = true,
    ["nil"] = true,
    ["default"] = true,
    ["player"] = true,
    ["players"] = true,
}

local function normalizeTeamToken(raw)
    return tostring(raw or ""):lower():gsub("%s+", "")
end

local function hasConfiguredTeams()
    return #Teams:GetChildren() > 0
end

local function isMyCharacterModel(model)
    if not model then
        return false
    end

    if model == getMyCharacter() then
        return true
    end

    local owner = Players:GetPlayerFromCharacter(model)
    return owner == localPlayer
end

local function getModelTeamToken(model)
    if not model then
        return nil, nil
    end

    for _, key in ipairs(TEAM_TOKEN_KEYS) do
        local attr = model:GetAttribute(key)
        if attr ~= nil then
            local token = normalizeTeamToken(attr)
            if token ~= "" then
                return key, token
            end
        end

        local child = model:FindFirstChild(key)
        if child then
            if child:IsA("ObjectValue") and child.Value then
                local token = normalizeTeamToken(child.Value.Name or tostring(child.Value))
                if token ~= "" then
                    return key, token
                end
            elseif child:IsA("StringValue") or child:IsA("IntValue") or child:IsA("NumberValue") then
                local token = normalizeTeamToken(child.Value)
                if token ~= "" then
                    return key, token
                end
            end
        end
    end

    return nil, nil
end

local function isTeammateModel(model)
    if not model then
        return false
    end

    local owner = Players:GetPlayerFromCharacter(model)
    if owner then
        if localPlayer.Team and owner.Team then
            return owner.Team == localPlayer.Team
        end

        if hasConfiguredTeams()
            and localPlayer.Neutral == false
            and owner.Neutral == false
            and localPlayer.TeamColor
            and owner.TeamColor
        then
            return owner.TeamColor == localPlayer.TeamColor
        end
    end

    local myChar = getMyCharacter()
    if not myChar then
        return false
    end

    local myKey, myToken = getModelTeamToken(myChar)
    local otherKey, otherToken = getModelTeamToken(model)

    if not myKey or not otherKey or myKey ~= otherKey then
        return false
    end

    if NEUTRAL_TEAM_TOKENS[myToken] or NEUTRAL_TEAM_TOKENS[otherToken] then
        return false
    end

    return myToken == otherToken
end

local function isEnemy(model)
    if isMyCharacterModel(model) then
        return false
    end

    if isTeammateModel(model) then
        return false
    end

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function getEnemies()
    local seen = {}
    local enemyList = {}

    local function tryAdd(model)
        if not model or seen[model] or isMyCharacterModel(model) then
            return
        end

        local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
        if root and isEnemy(model) then
            seen[model] = true
            enemyList[#enemyList + 1] = { model = model, root = root }
        end
    end

    local entitiesFolder = getEntitiesFolder()
    if entitiesFolder then
        for _, entity in ipairs(entitiesFolder:GetChildren()) do
            tryAdd(entity)
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character then
            tryAdd(player.Character)
        end
    end

    return enemyList
end

local function hasLOS(enemyRoot, ignoreModel)
    local myRoot = getMyRoot()
    if not myRoot then
        return true
    end

    local origin = myRoot.Position
    local direction = enemyRoot.Position - origin

    local rayParams = RaycastParams.new()
    local filter = { getMyCharacter() }
    local entitiesFolder = getEntitiesFolder()

    if entitiesFolder then
        table.insert(filter, entitiesFolder)
    end

    if ignoreModel then
        table.insert(filter, ignoreModel)
    end

    rayParams.FilterDescendantsInstances = filter
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    return Workspace:Raycast(origin, direction, rayParams) == nil
end

local function getNearestEnemyInFov(fovRadius)
    local currentCamera = Workspace.CurrentCamera
    if not currentCamera then
        return nil
    end

    local radius = math.max(1, tonumber(fovRadius) or Cfg.aimbotFovRadius or Cfg.fovRadius)
    local center = currentCamera.ViewportSize / 2
    local best = nil
    local bestScreenDist = math.huge

    for _, enemy in ipairs(getEnemies()) do
        local head = enemy.model:FindFirstChild("Head") or enemy.root
        local pos, visible = currentCamera:WorldToViewportPoint(head.Position)
        if visible and pos.Z > 0 then
            local screenDist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
            if screenDist <= radius and screenDist < bestScreenDist then
                best = enemy
                bestScreenDist = screenDist
            end
        end
    end

    return best
end

local function getAimbotPart(model)
    if not model then
        return nil
    end

    local preferred = Cfg.aimbotTargetPart
    local preferredCandidates = nil
    if preferred == "Head" then
        preferredCandidates = { "Head", "UpperTorso", "Torso", "HumanoidRootPart" }
    elseif preferred == "HumanoidRootPart" then
        preferredCandidates = { "HumanoidRootPart", "UpperTorso", "Torso", "Head" }
    elseif preferred == "UpperTorso" then
        preferredCandidates = { "UpperTorso", "Torso", "LowerTorso", "HumanoidRootPart", "Head" }
    elseif preferred == "Torso" then
        preferredCandidates = { "Torso", "UpperTorso", "LowerTorso", "HumanoidRootPart", "Head" }
    end

    if preferredCandidates then
        for _, partName in ipairs(preferredCandidates) do
            local preferredPart = model:FindFirstChild(partName)
            if preferredPart and preferredPart:IsA("BasePart") then
                return preferredPart
            end
        end
    end

    for _, fallbackName in ipairs({ "Head", "HumanoidRootPart", "UpperTorso", "Torso", "LowerTorso" }) do
        local fallbackPart = model:FindFirstChild(fallbackName)
        if fallbackPart and fallbackPart:IsA("BasePart") then
            return fallbackPart
        end
    end

    if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then
        return model.PrimaryPart
    end

    return nil
end

local function scoreAimbotTarget(screenDistance, worldDistance, health, velocityMagnitude, alignment)
    local mode = Cfg.aimbotPriority
    local velocityPenalty = math.clamp((velocityMagnitude or 0) * 0.006, 0, 20)
    local alignmentBonus = math.clamp((alignment or 0) * 30, -30, 30)

    if mode == "Distance" then
        return (worldDistance * 0.95) + (screenDistance * 1.05) + velocityPenalty - alignmentBonus
    end

    if mode == "Health" then
        return (math.max(health, 0) * 4.2)
            + (screenDistance * 0.95)
            + (worldDistance * 0.02)
            + velocityPenalty
            - (alignmentBonus * 0.65)
    end

    return (screenDistance * 1.35)
        + (worldDistance * 0.025)
        + (math.max(health, 0) * 0.015)
        + velocityPenalty
        - alignmentBonus
end

local function getAimbotFovRadius()
    local radius = tonumber(Cfg.aimbotFovRadius) or tonumber(Cfg.fovRadius) or 150
    if radius <= 0 then
        radius = 150
    end

    return math.clamp(radius, 50, 500)
end

local function getRedlinerAimPosition(part)
    if not part or not part:IsA("BasePart") then
        return nil
    end

    local yOffset = 0
    if part.Name == "Head" then
        yOffset = 0.25
    elseif part.Name == "UpperTorso" then
        yOffset = 0.1
    elseif part.Name == "Torso" then
        yOffset = 0.08
    elseif part.Name == "HumanoidRootPart" then
        yOffset = 0.04
    else
        yOffset = math.clamp((part.Size.Y * 0.2), 0, 0.16)
    end

    local aimPos = part.Position + Vector3.new(0, yOffset, 0)
    if not isFiniteVector3(aimPos) then
        return part.Position
    end

    return aimPos
end

local function getAimbotAimPosition(part, myRoot)
    if not part or not part:IsA("BasePart") then
        return nil
    end

    local direct = getRedlinerAimPosition(part)
    if direct and isFiniteVector3(direct) then
        return direct
    end

    return part.Position
end

local function evaluateAimbotModel(currentCamera, myRoot, model, fovLimit)
    if not currentCamera or not model or not model.Parent or not isEnemy(model) then
        return nil
    end

    local part = getAimbotPart(model)
    if not part or not part:IsA("BasePart") then
        return nil
    end

    local predictedPos = getAimbotAimPosition(part, myRoot) or part.Position

    if not isFiniteVector3(predictedPos) then
        predictedPos = part.Position
    end

    local viewportPoint, visible = currentCamera:WorldToViewportPoint(predictedPos)
    if not visible or viewportPoint.Z <= 0 then
        return nil
    end

    local center = currentCamera.ViewportSize / 2
    local screenDistance = (Vector2.new(viewportPoint.X, viewportPoint.Y) - center).Magnitude
    if fovLimit and screenDistance > fovLimit then
        return nil
    end

    local worldDistance = myRoot and (predictedPos - myRoot.Position).Magnitude or math.huge
    if worldDistance > Cfg.aimbotMaxDistance then
        return nil
    end

    local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart or part
    if ON.wallcheck and part and part:IsA("BasePart") and not hasLOS(part, model) then
        return nil
    end

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local health = humanoid and humanoid.Health or 100

    local velocityMagnitude = 0
    local velocity = part.AssemblyLinearVelocity or part.Velocity
    if isFiniteVector3(velocity) then
        velocityMagnitude = velocity.Magnitude
    end

    local alignment = 0
    local aimDirection = predictedPos - currentCamera.CFrame.Position
    if isFiniteVector3(aimDirection) then
        local magnitude = aimDirection.Magnitude
        if isFiniteNumber(magnitude) and magnitude > 0.0001 then
            alignment = currentCamera.CFrame.LookVector:Dot(aimDirection / magnitude)
        end
    end

    local score = scoreAimbotTarget(screenDistance, worldDistance, health, velocityMagnitude, alignment)

    return {
        model = model,
        part = part,
        root = root,
        predictedPos = predictedPos,
        screenDistance = screenDistance,
        worldDistance = worldDistance,
        health = health,
        velocityMagnitude = velocityMagnitude,
        alignment = alignment,
        score = score,
    }
end

local function acquireBestAimbotTarget(currentCamera, myRoot, fovLimit, ignoreModel)
    currentCamera = currentCamera or Workspace.CurrentCamera
    if not currentCamera then
        return nil
    end

    local bestData = nil
    local bestScore = math.huge

    for _, enemy in ipairs(getEnemies()) do
        local model = enemy.model
        if model ~= ignoreModel then
            local candidate = evaluateAimbotModel(currentCamera, myRoot, model, fovLimit)
            if candidate and candidate.score < bestScore then
                bestData = candidate
                bestScore = candidate.score
            end
        end
    end

    return bestData
end

local function resolveAimbotTarget(myRoot, currentCamera)
    currentCamera = currentCamera or Workspace.CurrentCamera
    if not currentCamera then
        aimbotLockedTarget = nil
        aimbotLockedPart = nil
        aimbotLockedScore = nil
        aimbotLockAcquiredAt = 0
        return nil
    end

    local nearestData = nil
    local nearestWorldDist = math.huge
    local originPos = (myRoot and myRoot.Position) or currentCamera.CFrame.Position

    for _, enemy in ipairs(getEnemies()) do
        local model = enemy.model
        local part = getAimbotPart(model) or enemy.root

        if part and part:IsA("BasePart") then
            local worldDist = (part.Position - originPos).Magnitude
            if worldDist <= (Cfg.aimbotMaxDistance or 800) and worldDist < nearestWorldDist then
                local canUse = true
                if ON.wallcheck and not hasLOS(part, model) then
                    canUse = false
                end

                if canUse then
                    local targetPos = getRedlinerAimPosition(part) or part.Position
                    if isFiniteVector3(targetPos) then
                        local screenDistance = math.huge
                        local viewportPoint, visible = currentCamera:WorldToViewportPoint(targetPos)
                        if visible and viewportPoint.Z > 0 then
                            local center = currentCamera.ViewportSize / 2
                            screenDistance = (Vector2.new(viewportPoint.X, viewportPoint.Y) - center).Magnitude
                        end

                        nearestWorldDist = worldDist
                        nearestData = {
                            model = model,
                            part = part,
                            root = enemy.root,
                            predictedPos = targetPos,
                            screenDistance = screenDistance,
                            worldDistance = worldDist,
                            health = 100,
                            velocityMagnitude = 0,
                            alignment = 1,
                            score = worldDist,
                        }
                    end
                end
            end
        end
    end

    if not nearestData then
        aimbotLockedTarget = nil
        aimbotLockedPart = nil
        aimbotLockedScore = nil
        aimbotLastSwitchAt = 0
        aimbotLockAcquiredAt = 0
        return nil
    end

    local now = os.clock()
    if aimbotLockedTarget ~= nearestData.model then
        aimbotLastSwitchAt = now
        aimbotLockAcquiredAt = now
    elseif aimbotLockAcquiredAt <= 0 then
        aimbotLockAcquiredAt = now
    end

    aimbotLockedTarget = nearestData.model
    aimbotLockedPart = nearestData.part
    aimbotLockedScore = nearestData.score

    return nearestData
end

local function getCenterRayHit(maxDistance)
    local currentCamera = Workspace.CurrentCamera
    if not currentCamera then
        return nil, nil
    end

    local viewport = currentCamera.ViewportSize
    local ray = currentCamera:ViewportPointToRay(viewport.X * 0.5, viewport.Y * 0.5)

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = { getMyCharacter() }

    local result = Workspace:Raycast(ray.Origin, ray.Direction * (maxDistance or 1500), rayParams)
    return result and result.Instance or nil, result
end

local function fireTriggerShot()
    if mouse1click then
        pcall(mouse1click)
        return true
    end

    if mouse1press and mouse1release then
        pcall(mouse1press)
        task.delay(0.02, function()
            pcall(mouse1release)
        end)
        return true
    end

    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:Button1Down(Vector2.new(0, 0), Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame)
        task.delay(0.02, function()
            pcall(function()
                VirtualUser:Button1Up(Vector2.new(0, 0), Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame)
            end)
        end)
    end)
    return true
end

local function shouldTriggerShoot()
    local hitPart = getCenterRayHit(Cfg.triggerbotMaxDistance)
    if not hitPart then
        return false
    end

    local model = hitPart:FindFirstAncestorOfClass("Model")
    if not model or not isEnemy(model) then
        return false
    end

    if ON.wallcheck then
        local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
        if root and not hasLOS(root, model) then
            return false
        end
    end

    return true
end

aimbotLockedTarget = nil
aimbotLockedPart = nil
aimbotLockedScore = nil
aimbotLastSwitchAt = 0
local aimbotCameraErrorCount = 0
local noRecoilApplyTimer = 0
local noRecoilPatched = false
local noRecoilItemsCache = nil
local noRecoilOriginalValues = {}
local NO_RECOIL_SPREAD_VALUE = 0.0001
local NO_RECOIL_ACCURACY_VALUE = 0.0001
local NO_RECOIL_KICK_VALUE = 0

local NO_RECOIL_EXCEPTIONS = {
    Sniper = true,
    Crossbow = true,
    Bow = true,
    RPG = true,
}

local function getNoRecoilItems()
    if type(noRecoilItemsCache) == "table" then
        return noRecoilItemsCache
    end

    local modules = Storage:FindFirstChild("Modules")
    local itemLibraryModule = modules and modules:FindFirstChild("ItemLibrary")
    if not itemLibraryModule then
        return nil
    end

    local ok, libraryData = pcall(require, itemLibraryModule)
    if not ok or type(libraryData) ~= "table" then
        return nil
    end

    local items = libraryData.Items
    if type(items) ~= "table" then
        return nil
    end

    noRecoilItemsCache = items
    return items
end

local function applyNoRecoilPatch()
    local ok = pcall(function()
        local items = getNoRecoilItems()
        if type(items) ~= "table" then
            noRecoilItemsCache = nil
            return
        end

        for name, data in pairs(items) do
            if type(data) == "table" and not NO_RECOIL_EXCEPTIONS[name] then
                local hasNumericField = type(data.ShootSpread) == "number"
                    or type(data.ShootAccuracy) == "number"
                    or type(data.ShootRecoil) == "number"

                if hasNumericField then
                    local original = noRecoilOriginalValues[data]
                    if not original then
                        noRecoilOriginalValues[data] = {
                            ShootSpread = data.ShootSpread,
                            ShootAccuracy = data.ShootAccuracy,
                            ShootRecoil = data.ShootRecoil,
                        }
                    end

                    if type(data.ShootSpread) == "number" then
                        data.ShootSpread = NO_RECOIL_SPREAD_VALUE
                    end
                    if type(data.ShootAccuracy) == "number" then
                        data.ShootAccuracy = NO_RECOIL_ACCURACY_VALUE
                    end
                    if type(data.ShootRecoil) == "number" then
                        data.ShootRecoil = NO_RECOIL_KICK_VALUE
                    end
                end
            end
        end

        noRecoilPatched = true
    end)

    if not ok then
        noRecoilItemsCache = nil
    end

    return ok
end

local function restoreNoRecoilPatch()
    local ok = pcall(function()
        for data, original in pairs(noRecoilOriginalValues) do
            if type(data) == "table" and type(original) == "table" then
                data.ShootSpread = original.ShootSpread
                data.ShootAccuracy = original.ShootAccuracy
                data.ShootRecoil = original.ShootRecoil
            end
            noRecoilOriginalValues[data] = nil
        end

        noRecoilPatched = false
        noRecoilItemsCache = nil
    end)

    if not ok then
        noRecoilPatched = false
        noRecoilItemsCache = nil
    end

    return ok
end

local function setNoRecoilEnabled(enabled)
    noRecoilApplyTimer = 0

    if enabled then
        noRecoilItemsCache = nil
        applyNoRecoilPatch()
        return
    end

    restoreNoRecoilPatch()
end

local function clearAimbotLock()
    aimbotLockedTarget = nil
    aimbotLockedPart = nil
    aimbotLockedScore = nil
    aimbotLastSwitchAt = 0
    aimbotLockAcquiredAt = 0
end

RunService:BindToRenderStep("PLunderRivalsAimbot", Enum.RenderPriority.Last.Value, function(dt)
    if not scriptAlive or not ON.aimbot then
        clearAimbotLock()
        aimbotCameraErrorCount = 0
        return
    end

    local camera = Workspace.CurrentCamera
    local myRoot = getMyRoot()
    if not camera then
        clearAimbotLock()
        aimbotCameraErrorCount = 0
        return
    end

    local targetData = resolveAimbotTarget(myRoot, camera)

    if not targetData then
        return
    end

    local targetPos = targetData.predictedPos
    if not targetPos or not isFiniteVector3(targetPos) then
        return
    end

    local cameraPos = camera.CFrame.Position
    local toTarget = targetPos - cameraPos
    if not isFiniteVector3(toTarget) or toTarget.Magnitude <= 0.0005 then
        return
    end

    local okApply = pcall(function()
        camera.CFrame = CFrame.new(cameraPos, targetPos)
    end)

    if okApply then
        aimbotCameraErrorCount = 0
        return
    end

    aimbotCameraErrorCount = aimbotCameraErrorCount + 1
    if aimbotCameraErrorCount == 10 then
        notify("Aimbot camera blocked: toggle POV or re-toggle aimbot", 4)
    elseif aimbotCameraErrorCount > 20 then
        aimbotCameraErrorCount = 10
    end
end)

table.insert(connections, RunService.Heartbeat:Connect(function()
    if not scriptAlive or not ON.triggerbot then
        return
    end

    local now = os.clock()
    if (now - triggerbotLastShotAt) < Cfg.triggerbotCooldown then
        return
    end

    if shouldTriggerShoot() then
        if fireTriggerShot() then
            triggerbotLastShotAt = now
        end
    end
end))

table.insert(connections, {
    Disconnect = function()
        pcall(function()
            RunService:UnbindFromRenderStep("PLunderRivalsAimbot")
        end)
    end,
})

table.insert(connections, RunService.Heartbeat:Connect(function()
    if not scriptAlive then
        return
    end

    if not ON.esp then
        for _, box in pairs(espBoxes) do
            pcall(function()
                box:Destroy()
            end)
        end
        espBoxes = {}
        return
    end

    for model, box in pairs(espBoxes) do
        if not model or not model.Parent then
            pcall(function()
                box:Destroy()
            end)
            espBoxes[model] = nil
        end
    end

    for _, enemy in ipairs(getEnemies()) do
        if not espBoxes[enemy.model] then
            local box = Instance.new("SelectionBox")
            box.Adornee = enemy.model
            box.Color3 = UiTheme.AccentSoft
            box.SurfaceTransparency = 1
            box.LineThickness = 0.06
            box.Parent = Workspace
            espBoxes[enemy.model] = box
        end
    end
end))

table.insert(connections, RunService.Heartbeat:Connect(function(dt)
    if not scriptAlive then
        noRecoilApplyTimer = 0
        return
    end

    if not ON.norecoil then
        if noRecoilPatched then
            restoreNoRecoilPatch()
        end
        noRecoilApplyTimer = 0
        return
    end

    noRecoilApplyTimer = noRecoilApplyTimer + dt
    if (not noRecoilPatched) or noRecoilApplyTimer >= 8 then
        noRecoilApplyTimer = 0
        applyNoRecoilPatch()
    end
end))

table.insert(connections, RunService.Heartbeat:Connect(function()
    if not scriptAlive then
        return
    end

    if not ON.chams then
        for _, highlight in pairs(chamsMap) do
            pcall(function()
                highlight:Destroy()
            end)
        end
        chamsMap = {}
        return
    end

    for model, highlight in pairs(chamsMap) do
        if not model or not model.Parent then
            pcall(function()
                highlight:Destroy()
            end)
            chamsMap[model] = nil
        end
    end

    for _, enemy in ipairs(getEnemies()) do
        if not chamsMap[enemy.model] then
            local highlight = Instance.new("Highlight")
            highlight.Adornee = enemy.model
            highlight.FillColor = UiTheme.Accent
            highlight.OutlineColor = UiTheme.AccentSoft
            highlight.FillTransparency = 0.4
            highlight.OutlineTransparency = 0
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Parent = enemy.model
            chamsMap[enemy.model] = highlight
        end
    end
end))

local fovGui = Instance.new("ScreenGui")
fovGui.Name = "RivalsFOV"
fovGui.ResetOnSpawn = false
fovGui.IgnoreGuiInset = true
fovGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
fovGui.Parent = localPlayer:WaitForChild("PlayerGui")

local fovRing = Instance.new("Frame")
fovRing.Name = "Ring"
fovRing.BackgroundTransparency = 1
fovRing.AnchorPoint = Vector2.new(0.5, 0.5)
fovRing.Position = UDim2.new(0.5, 0, 0.5, 0)
fovRing.Visible = false
fovRing.Parent = fovGui

local fovRingCorner = Instance.new("UICorner")
fovRingCorner.CornerRadius = UDim.new(1, 0)
fovRingCorner.Parent = fovRing

local fovRingStroke = Instance.new("UIStroke")
fovRingStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
fovRingStroke.Color = UiTheme.AccentSoft
fovRingStroke.Thickness = 2
fovRingStroke.Transparency = 0.2
fovRingStroke.Parent = fovRing

table.insert(connections, RunService.RenderStepped:Connect(function()
    if not scriptAlive then
        return
    end

    local currentCamera = Workspace.CurrentCamera

    fovRing.Visible = ON.showfov == true
    if fovRing.Visible then
        local ringRadius = getAimbotFovRadius()
        local ringColor = UiTheme.AccentSoft

        if currentCamera then
            local center = currentCamera.ViewportSize / 2
            local ringX, ringY = center.X, center.Y

            local hasLockedTarget = ON.aimbot
                and aimbotLockedTarget
                and aimbotLockedTarget.Parent
                and isEnemy(aimbotLockedTarget)

            if hasLockedTarget then
                local lockPart = aimbotLockedPart
                if (not lockPart) or (not lockPart.Parent) then
                    lockPart = getAimbotPart(aimbotLockedTarget)
                end

                local myRoot = getMyRoot()
                local lockPos = lockPart and getAimbotAimPosition(
                    lockPart,
                    myRoot
                )
                local screenPos, onScreen = lockPos and worldToScreenVector(lockPos)

                if onScreen and screenPos then
                    ringX = screenPos.X
                    ringY = screenPos.Y
                end

                ringRadius = getAimbotFovRadius() * (Cfg.aimbotRetainFovScale or 1.35)
                ringColor = UiTheme.Accent
            end

            fovRing.Position = UDim2.fromOffset(math.floor(ringX + 0.5), math.floor(ringY + 0.5))
        else
            fovRing.Position = UDim2.new(0.5, 0, 0.5, 0)
        end

        local diameter = math.max(2, math.floor((ringRadius * 2) + 0.5))
        fovRing.Size = UDim2.new(0, diameter, 0, diameter)
        fovRingStroke.Thickness = math.clamp(math.floor(ringRadius / 55), 2, 5)
        fovRingStroke.Color = ringColor
    end

    if not DRAWING_AVAILABLE then
        return
    end

    if not currentCamera then
        clearTracerLines()
        clearSkeletonLines()
        clearNameEspTexts()
        return
    end

    local enemies = getEnemies()

    if ON.tracers then
        local seen = {}
        local from = Vector2.new(currentCamera.ViewportSize.X * 0.5, currentCamera.ViewportSize.Y - 12)

        for _, enemy in ipairs(enemies) do
            local model = enemy.model
            seen[model] = true

            local line = tracerLines[model]
            if not line then
                line = createDrawingLine(UiTheme.AccentSoft, 1.5, 0.95)
                tracerLines[model] = line
            end

            if line then
                line.Thickness = Cfg.tracerThickness or 1.5
                line.Color = UiTheme.AccentSoft

                local targetPart = enemy.model:FindFirstChild("HumanoidRootPart")
                    or enemy.model:FindFirstChild("UpperTorso")
                    or enemy.model:FindFirstChild("Torso")
                    or enemy.model:FindFirstChild("Head")
                    or enemy.root

                if targetPart then
                    local to, visible = worldToScreenVector(targetPart.Position)
                    if visible then
                        line.From = from
                        line.To = to
                        line.Visible = true
                    else
                        line.Visible = false
                    end
                else
                    line.Visible = false
                end
            end
        end

        for model, line in pairs(tracerLines) do
            if not seen[model] then
                destroyDrawingObject(line)
                tracerLines[model] = nil
            end
        end
    else
        clearTracerLines()
    end

    if ON.skeletonesp then
        local seen = {}

        for _, enemy in ipairs(enemies) do
            local model = enemy.model
            seen[model] = true

            local lines = ensureSkeletonLines(model)
            if lines then
                for i, segment in ipairs(SKELETON_SEGMENTS) do
                    local line = lines[i]
                    if line then
                        line.Thickness = Cfg.skeletonThickness or 1.3
                        line.Color = UiTheme.Accent

                        local fromPart = getPartByNames(model, segment.from)
                        local toPart = getPartByNames(model, segment.to)

                        if fromPart and toPart and fromPart ~= toPart then
                            local fromPos, fromVisible = worldToScreenVector(fromPart.Position)
                            local toPos, toVisible = worldToScreenVector(toPart.Position)

                            if fromVisible and toVisible then
                                line.From = fromPos
                                line.To = toPos
                                line.Visible = true
                            else
                                line.Visible = false
                            end
                        else
                            line.Visible = false
                        end
                    end
                end
            end
        end

        for model, lines in pairs(skeletonLines) do
            if not seen[model] then
                for _, line in ipairs(lines) do
                    destroyDrawingObject(line)
                end
                skeletonLines[model] = nil
            end
        end
    else
        clearSkeletonLines()
    end

    if ON.nameesp then
        local seen = {}
        local myRoot = getMyRoot()

        for _, enemy in ipairs(enemies) do
            local model = enemy.model
            seen[model] = true

            local textObj = nameEspTexts[model]
            if not textObj then
                textObj = createDrawingText(UiTheme.TextMain, Cfg.nameEspTextSize, true)
                nameEspTexts[model] = textObj
            end

            if textObj then
                local head = model:FindFirstChild("Head")
                    or model:FindFirstChild("UpperTorso")
                    or model:FindFirstChild("HumanoidRootPart")
                    or enemy.root

                if head then
                    local distance = myRoot and (head.Position - myRoot.Position).Magnitude or 0
                    if (not myRoot) or distance <= Cfg.nameEspMaxDistance then
                        local textPos, visible = worldToScreenVector(head.Position + Vector3.new(0, 1.6, 0))
                        if visible then
                            local hum = model:FindFirstChildOfClass("Humanoid")
                            local hp = hum and math.floor(hum.Health + 0.5) or 0
                            textObj.Size = Cfg.nameEspTextSize
                            textObj.Color = UiTheme.TextMain
                            textObj.Text = string.format("%s [%d] | %dhp", model.Name, math.floor(distance + 0.5), hp)
                            textObj.Position = textPos
                            textObj.Visible = true
                        else
                            textObj.Visible = false
                        end
                    else
                        textObj.Visible = false
                    end
                else
                    textObj.Visible = false
                end
            end
        end

        for model, textObj in pairs(nameEspTexts) do
            if not seen[model] then
                destroyDrawingObject(textObj)
                nameEspTexts[model] = nil
            end
        end
    else
        clearNameEspTexts()
    end
end))

local function snapshot()
    return {
        name = "",
        on = {
            aimbot = ON.aimbot,
            esp = ON.esp,
            chams = ON.chams,
            tracers = ON.tracers,
            skeletonesp = ON.skeletonesp,
            nameesp = ON.nameesp,
            wallcheck = ON.wallcheck,
            showfov = ON.showfov,
            norecoil = ON.norecoil,
            triggerbot = ON.triggerbot,
            antiafk = ON.antiafk,
        },
        cfg = {
            fovRadius = Cfg.aimbotFovRadius,
            aimbotFovRadius = Cfg.aimbotFovRadius,
            smoothing = Cfg.smoothing,
            maxDist = Cfg.aimbotMaxDistance,
            aimbotMaxDistance = Cfg.aimbotMaxDistance,
            aimbotTargetPart = Cfg.aimbotTargetPart,
            aimbotStickyTarget = Cfg.aimbotStickyTarget,
            aimbotSnap = Cfg.aimbotSnap,
            aimbotPrediction = Cfg.aimbotPrediction,
            aimbotPriority = Cfg.aimbotPriority,
            aimbotProjectileSpeed = Cfg.aimbotProjectileSpeed,
            aimbotRetainFovScale = Cfg.aimbotRetainFovScale,
            aimbotSwitchDelay = Cfg.aimbotSwitchDelay,
            aimbotDeadzone = Cfg.aimbotDeadzone,
            aimbotAdaptiveSmoothing = Cfg.aimbotAdaptiveSmoothing,
            aimbotSmoothMin = Cfg.aimbotSmoothMin,
            aimbotSmoothMax = Cfg.aimbotSmoothMax,
            aimbotResponseCurve = Cfg.aimbotResponseCurve,
            aimbotVelocityLead = Cfg.aimbotVelocityLead,
            aimbotAccelerationLead = Cfg.aimbotAccelerationLead,
            aimbotPredictionBlend = Cfg.aimbotPredictionBlend,
            aimbotSwitchScoreGap = Cfg.aimbotSwitchScoreGap,
            aimbotLockPersistence = Cfg.aimbotLockPersistence,
            aimbotMaxTurnRate = Cfg.aimbotMaxTurnRate,
            triggerbotCooldown = Cfg.triggerbotCooldown,
            triggerbotMaxDistance = Cfg.triggerbotMaxDistance,
            nameEspMaxDistance = Cfg.nameEspMaxDistance,
            nameEspTextSize = Cfg.nameEspTextSize,
            tracerThickness = Cfg.tracerThickness,
            skeletonThickness = Cfg.skeletonThickness,
        },
        keybinds = Keybinds,
    }
end

local function applyBuild(build, activateRuntime)
    if activateRuntime == nil then
        activateRuntime = true
    end

    if build.on then
        for k, v in pairs(build.on) do
            if ON[k] ~= nil then
                ON[k] = v
            end
        end
    end

    if build.cfg then
        for k, v in pairs(build.cfg) do
            if Cfg[k] ~= nil then
                Cfg[k] = v
            end
        end
    end

    if not table.find(AIMBOT_PART_OPTIONS, Cfg.aimbotTargetPart) then
        Cfg.aimbotTargetPart = "Head"
    end
    if not table.find(AIMBOT_PRIORITY_OPTIONS, Cfg.aimbotPriority) then
        Cfg.aimbotPriority = "Crosshair"
    end

    local buildAimbotFov = tonumber(Cfg.aimbotFovRadius)
    if not buildAimbotFov or buildAimbotFov <= 0 then
        buildAimbotFov = tonumber(Cfg.fovRadius) or 150
    end

    Cfg.aimbotFovRadius = math.clamp(buildAimbotFov, 50, 500)
    Cfg.fovRadius = Cfg.aimbotFovRadius

    local buildAimbotMaxDistance = tonumber(Cfg.aimbotMaxDistance)
    if not buildAimbotMaxDistance or buildAimbotMaxDistance <= 0 then
        buildAimbotMaxDistance = tonumber(Cfg.maxDist) or 800
    end

    Cfg.aimbotMaxDistance = math.clamp(buildAimbotMaxDistance, 100, 3000)
    Cfg.maxDist = Cfg.aimbotMaxDistance

    Cfg.aimbotStickyTarget = Cfg.aimbotStickyTarget == true
    Cfg.aimbotSnap = Cfg.aimbotSnap ~= false
    Cfg.aimbotPrediction = math.clamp(tonumber(Cfg.aimbotPrediction) or 0.1, 0, 0.45)
    Cfg.aimbotProjectileSpeed = math.clamp(tonumber(Cfg.aimbotProjectileSpeed) or 2200, 0, 6000)
    Cfg.aimbotRetainFovScale = math.clamp(tonumber(Cfg.aimbotRetainFovScale) or 1.35, 1, 3)
    Cfg.aimbotSwitchDelay = math.clamp(tonumber(Cfg.aimbotSwitchDelay) or 0.14, 0, 1)
    Cfg.aimbotDeadzone = math.clamp(tonumber(Cfg.aimbotDeadzone) or 2, 0, 35)
    normalizeAimbotAdvancedCfg()
    Cfg.triggerbotCooldown = math.clamp(tonumber(Cfg.triggerbotCooldown) or 0.08, 0.02, 1)
    Cfg.triggerbotMaxDistance = math.clamp(tonumber(Cfg.triggerbotMaxDistance) or 1400, 200, 5000)
    Cfg.nameEspMaxDistance = math.clamp(tonumber(Cfg.nameEspMaxDistance) or 2000, 200, 5000)
    Cfg.nameEspTextSize = math.clamp(tonumber(Cfg.nameEspTextSize) or 13, 11, 24)
    Cfg.tracerThickness = math.clamp(tonumber(Cfg.tracerThickness) or 1.5, 1, 6)
    Cfg.skeletonThickness = math.clamp(tonumber(Cfg.skeletonThickness) or 1.3, 1, 6)

    if build.keybinds then
        for k, v in pairs(build.keybinds) do
            if Keybinds[k] ~= nil then
                Keybinds[k] = v
            end
        end
    end

    saveCfg("toggles", ON)
    saveCfg("cfg", Cfg)
    saveCfg("keybinds", Keybinds)

    for feature, toggleRef in pairs(uiRefs.FeatureToggles) do
        if toggleRef and toggleRef.SetValue then
            pcall(function()
                toggleRef:SetValue(ON[feature] == true)
            end)
        end
    end

    for feature, dropdownRef in pairs(uiRefs.KeybindDropdowns) do
        if dropdownRef and dropdownRef.SetValue then
            pcall(function()
                dropdownRef:SetValue(KEY_OPTIONS[indexOf(KEY_OPTIONS, keyOrNone(Keybinds[feature]))])
            end)
        end
    end

    if uiRefs.FovSlider and uiRefs.FovSlider.SetValue then
        pcall(function()
            uiRefs.FovSlider:SetValue(Cfg.aimbotFovRadius)
        end)
    end

    if uiRefs.SmoothSlider and uiRefs.SmoothSlider.SetValue then
        pcall(function()
            uiRefs.SmoothSlider:SetValue(Cfg.smoothing)
        end)
    end

    if uiRefs.MaxDistSlider and uiRefs.MaxDistSlider.SetValue then
        pcall(function()
            uiRefs.MaxDistSlider:SetValue(Cfg.aimbotMaxDistance)
        end)
    end

    if uiRefs.AimbotPartDropdown and uiRefs.AimbotPartDropdown.SetValue then
        pcall(function()
            uiRefs.AimbotPartDropdown:SetValue(Cfg.aimbotTargetPart)
        end)
    end

    if uiRefs.AimbotStickyToggle and uiRefs.AimbotStickyToggle.SetValue then
        pcall(function()
            uiRefs.AimbotStickyToggle:SetValue(Cfg.aimbotStickyTarget == true)
        end)
    end

    if uiRefs.AimbotSnapToggle and uiRefs.AimbotSnapToggle.SetValue then
        pcall(function()
            uiRefs.AimbotSnapToggle:SetValue(Cfg.aimbotSnap == true)
        end)
    end

    if uiRefs.AimbotPredictionSlider and uiRefs.AimbotPredictionSlider.SetValue then
        pcall(function()
            uiRefs.AimbotPredictionSlider:SetValue(Cfg.aimbotPrediction)
        end)
    end

    if uiRefs.AimbotPriorityDropdown and uiRefs.AimbotPriorityDropdown.SetValue then
        pcall(function()
            uiRefs.AimbotPriorityDropdown:SetValue(Cfg.aimbotPriority)
        end)
    end

    if uiRefs.AimbotProjectileSlider and uiRefs.AimbotProjectileSlider.SetValue then
        pcall(function()
            uiRefs.AimbotProjectileSlider:SetValue(Cfg.aimbotProjectileSpeed)
        end)
    end

    if uiRefs.AimbotRetainFovSlider and uiRefs.AimbotRetainFovSlider.SetValue then
        pcall(function()
            uiRefs.AimbotRetainFovSlider:SetValue(Cfg.aimbotRetainFovScale)
        end)
    end

    if uiRefs.AimbotSwitchDelaySlider and uiRefs.AimbotSwitchDelaySlider.SetValue then
        pcall(function()
            uiRefs.AimbotSwitchDelaySlider:SetValue(Cfg.aimbotSwitchDelay)
        end)
    end

    if uiRefs.AimbotDeadzoneSlider and uiRefs.AimbotDeadzoneSlider.SetValue then
        pcall(function()
            uiRefs.AimbotDeadzoneSlider:SetValue(Cfg.aimbotDeadzone)
        end)
    end

    if uiRefs.AimbotAdaptiveSmoothingToggle and uiRefs.AimbotAdaptiveSmoothingToggle.SetValue then
        pcall(function()
            uiRefs.AimbotAdaptiveSmoothingToggle:SetValue(Cfg.aimbotAdaptiveSmoothing == true)
        end)
    end

    if uiRefs.AimbotSmoothMinSlider and uiRefs.AimbotSmoothMinSlider.SetValue then
        pcall(function()
            uiRefs.AimbotSmoothMinSlider:SetValue(Cfg.aimbotSmoothMin)
        end)
    end

    if uiRefs.AimbotSmoothMaxSlider and uiRefs.AimbotSmoothMaxSlider.SetValue then
        pcall(function()
            uiRefs.AimbotSmoothMaxSlider:SetValue(Cfg.aimbotSmoothMax)
        end)
    end

    if uiRefs.AimbotResponseCurveSlider and uiRefs.AimbotResponseCurveSlider.SetValue then
        pcall(function()
            uiRefs.AimbotResponseCurveSlider:SetValue(Cfg.aimbotResponseCurve)
        end)
    end

    if uiRefs.AimbotVelocityLeadSlider and uiRefs.AimbotVelocityLeadSlider.SetValue then
        pcall(function()
            uiRefs.AimbotVelocityLeadSlider:SetValue(Cfg.aimbotVelocityLead)
        end)
    end

    if uiRefs.AimbotAccelerationLeadSlider and uiRefs.AimbotAccelerationLeadSlider.SetValue then
        pcall(function()
            uiRefs.AimbotAccelerationLeadSlider:SetValue(Cfg.aimbotAccelerationLead)
        end)
    end

    if uiRefs.AimbotMaxTurnRateSlider and uiRefs.AimbotMaxTurnRateSlider.SetValue then
        pcall(function()
            uiRefs.AimbotMaxTurnRateSlider:SetValue(Cfg.aimbotMaxTurnRate)
        end)
    end

    if uiRefs.TriggerbotCooldownSlider and uiRefs.TriggerbotCooldownSlider.SetValue then
        pcall(function()
            uiRefs.TriggerbotCooldownSlider:SetValue(Cfg.triggerbotCooldown)
        end)
    end

    if uiRefs.TriggerbotDistanceSlider and uiRefs.TriggerbotDistanceSlider.SetValue then
        pcall(function()
            uiRefs.TriggerbotDistanceSlider:SetValue(Cfg.triggerbotMaxDistance)
        end)
    end

    if uiRefs.NameEspDistanceSlider and uiRefs.NameEspDistanceSlider.SetValue then
        pcall(function()
            uiRefs.NameEspDistanceSlider:SetValue(Cfg.nameEspMaxDistance)
        end)
    end

    if uiRefs.NameEspTextSizeSlider and uiRefs.NameEspTextSizeSlider.SetValue then
        pcall(function()
            uiRefs.NameEspTextSizeSlider:SetValue(Cfg.nameEspTextSize)
        end)
    end

    if uiRefs.TracerThicknessSlider and uiRefs.TracerThicknessSlider.SetValue then
        pcall(function()
            uiRefs.TracerThicknessSlider:SetValue(Cfg.tracerThickness)
        end)
    end

    if uiRefs.SkeletonThicknessSlider and uiRefs.SkeletonThicknessSlider.SetValue then
        pcall(function()
            uiRefs.SkeletonThicknessSlider:SetValue(Cfg.skeletonThickness)
        end)
    end

    if not activateRuntime then
        for _, key in ipairs(STARTUP_SAFE_COMBAT_KEYS) do
            ON[key] = false
        end
        saveCfg("toggles", ON)

        for _, feature in ipairs(STARTUP_SAFE_COMBAT_KEYS) do
            local toggleRef = uiRefs.FeatureToggles[feature]
            if toggleRef and toggleRef.SetValue then
                pcall(function()
                    toggleRef:SetValue(false)
                end)
            end
        end
    end

    setAntiAfkEnabled(ON.antiafk == true)
    setNoRecoilEnabled(activateRuntime and ON.norecoil == true)

    if uiRefs.AutoLoadLabel and uiRefs.AutoLoadLabel.SetText then
        local autoLoadName = getAutoLoad()
        uiRefs.AutoLoadLabel:SetText(autoLoadName and ("Auto-load: " .. autoLoadName) or "Auto-load: -")
    end
end

task.defer(function()
    local name = getAutoLoad()
    if not name then
        return
    end

    local builds = loadBuilds()
    for _, build in ipairs(builds) do
        if build.name == name then
            applyBuild(build, false)
            activeLoadedBuild = name
            notify("Auto-build loaded in safe mode: " .. name, 4)
            return
        end
    end
end)

local defaultWindowIcon = 95816097006870
local defaultWindowIconSource = "rbxassetid://" .. tostring(defaultWindowIcon)
local uploadedMaskAssetId = nil
local uploadedMaskSource = (type(uploadedMaskAssetId) == "number") and ("rbxassetid://" .. tostring(uploadedMaskAssetId)) or nil
local maskImagePaths = {
    "C:/Users/User/Desktop/image-removebg-preview_1.png",
    "C:\\Users\\User\\Desktop\\image-removebg-preview_1.png",
    "C:/Users/User/Pictures/image-removebg-preview_1.png",
    "C:\\Users\\User\\Pictures\\image-removebg-preview_1.png",
    "image-removebg-preview_1.png",
    "./image-removebg-preview_1.png",
}

local function isUsableIconSource(iconValue)
    if iconValue == nil then
        return false
    end

    local okIcon, parsed = pcall(function()
        return Library:GetCustomIcon(iconValue)
    end)

    return okIcon and parsed ~= nil
end

local function resolveMaskImageSource()
    for _, path in ipairs(maskImagePaths) do
        for _, resolver in ipairs({ getcustomasset, getsynasset }) do
            if type(resolver) == "function" then
                local okAsset, assetPath = pcall(resolver, path)
                if okAsset and type(assetPath) == "string" and assetPath ~= "" then
                    return assetPath
                end
            end
        end

        if type(isfile) == "function" then
            local okExists, exists = pcall(isfile, path)
            if okExists and exists then
                return "content://" .. path:gsub("\\", "/")
            end
        end
    end

    return nil
end

local resolvedMaskImage = uploadedMaskSource or resolveMaskImageSource()
local resolvedWindowIcon = isUsableIconSource(resolvedMaskImage) and resolvedMaskImage or defaultWindowIcon
local resolvedMainBannerImage = resolvedMaskImage or defaultWindowIconSource

local function tryInjectCornerMaskIcon(imageSource)
    if type(imageSource) ~= "string" or imageSource == "" then
        return false
    end

    local screenGui = Library and Library.ScreenGui
    if not screenGui then
        return false
    end

    for _, node in ipairs(screenGui:GetDescendants()) do
        if node:IsA("TextLabel") and node.Text == "PLunder Hub" then
            local titleHolder = node.Parent
            if titleHolder then
                local iconImage = titleHolder:FindFirstChild("PLunderCornerIcon")

                if not (iconImage and iconImage:IsA("ImageLabel")) then
                    for _, child in ipairs(titleHolder:GetChildren()) do
                        if child:IsA("ImageLabel") then
                            iconImage = child
                            break
                        end
                    end
                end

                if not (iconImage and iconImage:IsA("ImageLabel")) then
                    iconImage = Instance.new("ImageLabel")
                    iconImage.Name = "PLunderCornerIcon"
                    iconImage.BackgroundTransparency = 1
                    iconImage.LayoutOrder = -1
                    iconImage.Size = UDim2.fromOffset(38, 52)
                    iconImage.Parent = titleHolder
                end

                iconImage.Image = imageSource
                iconImage.ImageRectOffset = Vector2.zero
                iconImage.ImageRectSize = Vector2.zero
                iconImage.Visible = true
                return true
            end
        end
    end

    return false
end

local function queueCornerMaskInjection(imageSource)
    if type(imageSource) ~= "string" or imageSource == "" then
        return
    end

    task.defer(function()
        for _ = 1, 30 do
            local okInject, injected = pcall(tryInjectCornerMaskIcon, imageSource)
            if okInject and injected then
                return
            end

            task.wait(0.1)
        end
    end)
end

local function createWindowSafely()
    local okMain, window = pcall(function()
        return Library:CreateWindow({
            Title = "PLunder Hub",
            Footer = "Rivals Edition",
            Icon = resolvedWindowIcon,
            IconSize = UDim2.fromOffset(38, 52),
            Center = true,
            AutoShow = true,
        })
    end)

    if okMain and window then
        return window
    end

    warn("PLunder Hub: advanced window options failed, retrying basic window")

    local okFallback, fallbackWindow = pcall(function()
        return Library:CreateWindow({
            Title = "PLunder Hub",
            Footer = "Rivals Edition",
            Center = true,
            AutoShow = true,
        })
    end)

    if okFallback and fallbackWindow then
        notify("UI fallback mode active", 3)
        return fallbackWindow
    end

    error("PLunder Hub: failed to create window", 0)
end

local function addTabSafely(window, title, icon)
    local okMain, tab = pcall(function()
        return window:AddTab(title, icon)
    end)

    if okMain and tab then
        return tab
    end

    local okFallback, fallbackTab = pcall(function()
        return window:AddTab(title)
    end)

    if okFallback and fallbackTab then
        return fallbackTab
    end

    error("PLunder Hub: failed to add tab " .. tostring(title), 0)
end

local Window = createWindowSafely()

pcall(function()
    Library:Toggle(true)
end)

queueCornerMaskInjection(resolvedMaskImage)

local MainTab = addTabSafely(Window, "Main", "home")
local AimbotTab = addTabSafely(Window, "Aimbot", "crosshair")
local VisualsTab = addTabSafely(Window, "Visuals", "eye")
local KeybindsTab = addTabSafely(Window, "Keybinds", "keyboard")
local SettingsTab = addTabSafely(Window, "Settings", "settings")

local menuInfoGroup = MainTab:AddLeftGroupbox("Menu Info")
local clientInfoGroup = MainTab:AddRightGroupbox("Client Info")
local discordInfoGroup = MainTab:AddRightGroupbox("Plunder Discord")

local combatGroup = AimbotTab:AddLeftGroupbox("Combat")
local aimbotValuesGroup = AimbotTab:AddRightGroupbox("Aimbot Tuning")
local assistValuesGroup = AimbotTab:AddRightGroupbox("Assist Settings")

local visualGroup = VisualsTab:AddLeftGroupbox("Visuals")
local visualValuesGroup = VisualsTab:AddRightGroupbox("Visual Tuning")

local keybindsGroup = KeybindsTab:AddLeftGroupbox("Keybinds")

local utilityGroup = SettingsTab:AddLeftGroupbox("Utility")
local buildsGroup = SettingsTab:AddLeftGroupbox("Build Manager")
local quickActionsGroup = SettingsTab:AddRightGroupbox("Quick Actions")
local safetyActionsGroup = SettingsTab:AddRightGroupbox("Safety")

local function bindFeatureToggle(targetGroup, featureKey, label, onChanged)
    local toggle = targetGroup:AddToggle("Feat_" .. featureKey, {
        Text = label,
        Default = ON[featureKey] == true,
        Callback = function(value)
            ON[featureKey] = value
            saveCfg("toggles", ON)
            if onChanged then
                onChanged(value)
            end
        end,
    })
    uiRefs.FeatureToggles[featureKey] = toggle

    local keyDropdown = keybindsGroup:AddDropdown("Key_" .. featureKey, {
        Values = KEY_OPTIONS,
        Default = indexOf(KEY_OPTIONS, keyOrNone(Keybinds[featureKey])),
        Text = label,
        Callback = function(value)
            Keybinds[featureKey] = keyOrNone(value)
            saveCfg("keybinds", Keybinds)
        end,
    })
    uiRefs.KeybindDropdowns[featureKey] = keyDropdown
end

bindFeatureToggle(combatGroup, "aimbot", "Aimbot Lock")
bindFeatureToggle(combatGroup, "triggerbot", "Triggerbot")
bindFeatureToggle(combatGroup, "wallcheck", "Wall Check")
bindFeatureToggle(combatGroup, "norecoil", "No Recoil / No Spread", function(value)
    setNoRecoilEnabled(value == true)
end)

bindFeatureToggle(visualGroup, "esp", "ESP Boxes")
bindFeatureToggle(visualGroup, "chams", "Chams ESP")
bindFeatureToggle(visualGroup, "tracers", "Enemy Tracers", function(value)
    if value and not DRAWING_AVAILABLE then
        notify("Tracer ESP needs Drawing API support", 3)
    end
end)
bindFeatureToggle(visualGroup, "skeletonesp", "Skeleton ESP", function(value)
    if value and not DRAWING_AVAILABLE then
        notify("Skeleton ESP needs Drawing API support", 3)
    end
end)
bindFeatureToggle(visualGroup, "nameesp", "Name ESP", function(value)
    if value and not DRAWING_AVAILABLE then
        notify("Name ESP needs Drawing API support", 3)
    end
end)
bindFeatureToggle(visualGroup, "showfov", "Show FOV")

bindFeatureToggle(utilityGroup, "antiafk", "Anti AFK", function(value)
    setAntiAfkEnabled(value)
end)

uiRefs.FovSlider = aimbotValuesGroup:AddSlider("CfgFovRadius", {
    Text = "Aimbot FOV Radius",
    Default = Cfg.aimbotFovRadius,
    Min = 50,
    Max = 500,
    Rounding = 0,
    Callback = function(v)
        Cfg.aimbotFovRadius = v
        Cfg.fovRadius = v
        saveCfg("cfg", Cfg)
    end,
})

uiRefs.SmoothSlider = aimbotValuesGroup:AddSlider("CfgSmoothing", {
    Text = "Aim Smoothing",
    Default = Cfg.smoothing,
    Min = 0.01,
    Max = 1,
    Rounding = 2,
    Callback = function(v)
        Cfg.smoothing = v
        saveCfg("cfg", Cfg)
    end,
})

uiRefs.MaxDistSlider = aimbotValuesGroup:AddSlider("CfgMaxDistance", {
    Text = "Aimbot Max Distance",
    Default = Cfg.aimbotMaxDistance,
    Min = 100,
    Max = 3000,
    Rounding = 0,
    Suffix = " studs",
    Callback = function(v)
        Cfg.aimbotMaxDistance = v
        Cfg.maxDist = v
        saveCfg("cfg", Cfg)
    end,
})

uiRefs.AimbotSnapToggle = aimbotValuesGroup:AddToggle("CfgAimbotSnap", {
    Text = "Snap To Head",
    Default = Cfg.aimbotSnap == true,
    Callback = function(value)
        Cfg.aimbotSnap = value == true
        saveCfg("cfg", Cfg)
    end,
})

uiRefs.AimbotPredictionSlider = aimbotValuesGroup:AddSlider("CfgAimbotPrediction", {
    Text = "Prediction Lead",
    Default = Cfg.aimbotPrediction,
    Min = 0,
    Max = 0.45,
    Rounding = 2,
    Callback = function(v)
        Cfg.aimbotPrediction = v
        saveCfg("cfg", Cfg)
    end,
})

uiRefs.AimbotPriorityDropdown = aimbotValuesGroup:AddDropdown("CfgAimbotPriority", {
    Values = AIMBOT_PRIORITY_OPTIONS,
    Default = indexOf(AIMBOT_PRIORITY_OPTIONS, Cfg.aimbotPriority),
    Text = "Target Priority",
    Callback = function(value)
        if table.find(AIMBOT_PRIORITY_OPTIONS, value) then
            Cfg.aimbotPriority = value
        else
            Cfg.aimbotPriority = "Crosshair"
        end
        clearAimbotLock()
        saveCfg("cfg", Cfg)
    end,
})

uiRefs.AimbotProjectileSlider = aimbotValuesGroup:AddSlider("CfgAimbotProjectileSpeed", {
    Text = "Projectile Speed",
    Default = Cfg.aimbotProjectileSpeed,
    Min = 0,
    Max = 6000,
    Rounding = 0,
    Suffix = " studs/s",
    Callback = function(v)
        Cfg.aimbotProjectileSpeed = v
        saveCfg("cfg", Cfg)
    end,
})

uiRefs.AimbotRetainFovSlider = aimbotValuesGroup:AddSlider("CfgAimbotRetainFovScale", {
    Text = "Lock Retain FOV",
    Default = Cfg.aimbotRetainFovScale,
    Min = 1,
    Max = 3,
    Rounding = 2,
    Callback = function(v)
        Cfg.aimbotRetainFovScale = v
        saveCfg("cfg", Cfg)
    end,
})

uiRefs.AimbotSwitchDelaySlider = aimbotValuesGroup:AddSlider("CfgAimbotSwitchDelay", {
    Text = "Target Switch Delay",
    Default = Cfg.aimbotSwitchDelay,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Suffix = "s",
    Callback = function(v)
        Cfg.aimbotSwitchDelay = v
        saveCfg("cfg", Cfg)
    end,
})

uiRefs.AimbotDeadzoneSlider = aimbotValuesGroup:AddSlider("CfgAimbotDeadzone", {
    Text = "Crosshair Deadzone",
    Default = Cfg.aimbotDeadzone,
    Min = 0,
    Max = 35,
    Rounding = 0,
    Callback = function(v)
        Cfg.aimbotDeadzone = v
        saveCfg("cfg", Cfg)
    end,
})

local updatingAdvancedSmoothingUi = false

uiRefs.AimbotAdaptiveSmoothingToggle = aimbotValuesGroup:AddToggle("CfgAimbotAdaptiveSmoothing", {
    Text = "Adaptive Smoothing",
    Default = Cfg.aimbotAdaptiveSmoothing == true,
    Callback = function(value)
        Cfg.aimbotAdaptiveSmoothing = value == true
        saveCfg("cfg", Cfg)
    end,
})

uiRefs.AimbotSmoothMinSlider = aimbotValuesGroup:AddSlider("CfgAimbotSmoothMin", {
    Text = "Min Smooth Alpha",
    Default = Cfg.aimbotSmoothMin,
    Min = 0.01,
    Max = 0.95,
    Rounding = 2,
    Callback = function(v)
        if updatingAdvancedSmoothingUi then
            return
        end

        updatingAdvancedSmoothingUi = true
        Cfg.aimbotSmoothMin = math.clamp(v, 0.01, 0.95)
        if Cfg.aimbotSmoothMax <= Cfg.aimbotSmoothMin then
            Cfg.aimbotSmoothMax = math.clamp(Cfg.aimbotSmoothMin + 0.01, 0.02, 0.995)
            if uiRefs.AimbotSmoothMaxSlider and uiRefs.AimbotSmoothMaxSlider.SetValue then
                pcall(function()
                    uiRefs.AimbotSmoothMaxSlider:SetValue(Cfg.aimbotSmoothMax)
                end)
            end
        end
        updatingAdvancedSmoothingUi = false

        saveCfg("cfg", Cfg)
    end,
})

uiRefs.AimbotSmoothMaxSlider = aimbotValuesGroup:AddSlider("CfgAimbotSmoothMax", {
    Text = "Max Smooth Alpha",
    Default = Cfg.aimbotSmoothMax,
    Min = 0.05,
    Max = 0.99,
    Rounding = 2,
    Callback = function(v)
        if updatingAdvancedSmoothingUi then
            return
        end

        updatingAdvancedSmoothingUi = true
        Cfg.aimbotSmoothMax = math.clamp(v, 0.05, 0.995)
        if Cfg.aimbotSmoothMax <= Cfg.aimbotSmoothMin then
            Cfg.aimbotSmoothMin = math.clamp(Cfg.aimbotSmoothMax - 0.01, 0.01, 0.95)
            if uiRefs.AimbotSmoothMinSlider and uiRefs.AimbotSmoothMinSlider.SetValue then
                pcall(function()
                    uiRefs.AimbotSmoothMinSlider:SetValue(Cfg.aimbotSmoothMin)
                end)
            end
        end
        updatingAdvancedSmoothingUi = false

        saveCfg("cfg", Cfg)
    end,
})

uiRefs.AimbotResponseCurveSlider = aimbotValuesGroup:AddSlider("CfgAimbotResponseCurve", {
    Text = "Response Curve",
    Default = Cfg.aimbotResponseCurve,
    Min = 0.5,
    Max = 3,
    Rounding = 2,
    Callback = function(v)
        Cfg.aimbotResponseCurve = math.clamp(v, 0.5, 3)
        saveCfg("cfg", Cfg)
    end,
})

uiRefs.AimbotVelocityLeadSlider = aimbotValuesGroup:AddSlider("CfgAimbotVelocityLead", {
    Text = "Velocity Lead",
    Default = Cfg.aimbotVelocityLead,
    Min = 0,
    Max = 2.5,
    Rounding = 2,
    Callback = function(v)
        Cfg.aimbotVelocityLead = math.clamp(v, 0, 2.5)
        saveCfg("cfg", Cfg)
    end,
})

uiRefs.AimbotAccelerationLeadSlider = aimbotValuesGroup:AddSlider("CfgAimbotAccelerationLead", {
    Text = "Acceleration Lead",
    Default = Cfg.aimbotAccelerationLead,
    Min = 0,
    Max = 2,
    Rounding = 2,
    Callback = function(v)
        Cfg.aimbotAccelerationLead = math.clamp(v, 0, 2)
        saveCfg("cfg", Cfg)
    end,
})

uiRefs.AimbotMaxTurnRateSlider = aimbotValuesGroup:AddSlider("CfgAimbotMaxTurnRate", {
    Text = "Max Turn Rate",
    Default = Cfg.aimbotMaxTurnRate,
    Min = 240,
    Max = 3000,
    Rounding = 0,
    Suffix = " deg/s",
    Callback = function(v)
        Cfg.aimbotMaxTurnRate = math.clamp(v, 240, 3000)
        saveCfg("cfg", Cfg)
    end,
})

uiRefs.AimbotPartDropdown = aimbotValuesGroup:AddDropdown("CfgAimbotTargetPart", {
    Values = AIMBOT_PART_OPTIONS,
    Default = indexOf(AIMBOT_PART_OPTIONS, Cfg.aimbotTargetPart),
    Text = "Preferred Aim Part",
    Callback = function(value)
        if table.find(AIMBOT_PART_OPTIONS, value) then
            Cfg.aimbotTargetPart = value
        else
            Cfg.aimbotTargetPart = "Head"
        end
        clearAimbotLock()
        saveCfg("cfg", Cfg)
    end,
})

uiRefs.AimbotStickyToggle = aimbotValuesGroup:AddToggle("CfgAimbotStickyTarget", {
    Text = "Sticky Target Lock",
    Default = Cfg.aimbotStickyTarget == true,
    Callback = function(value)
        Cfg.aimbotStickyTarget = value == true
        if not Cfg.aimbotStickyTarget then
            clearAimbotLock()
        end
        saveCfg("cfg", Cfg)
    end,
})

uiRefs.TriggerbotCooldownSlider = assistValuesGroup:AddSlider("CfgTriggerbotCooldown", {
    Text = "Triggerbot Cooldown",
    Default = Cfg.triggerbotCooldown,
    Min = 0.02,
    Max = 1,
    Rounding = 2,
    Suffix = "s",
    Callback = function(v)
        Cfg.triggerbotCooldown = v
        saveCfg("cfg", Cfg)
    end,
})

uiRefs.TriggerbotDistanceSlider = assistValuesGroup:AddSlider("CfgTriggerbotMaxDistance", {
    Text = "Triggerbot Max Distance",
    Default = Cfg.triggerbotMaxDistance,
    Min = 200,
    Max = 5000,
    Rounding = 0,
    Suffix = " studs",
    Callback = function(v)
        Cfg.triggerbotMaxDistance = v
        saveCfg("cfg", Cfg)
    end,
})

uiRefs.NameEspDistanceSlider = visualValuesGroup:AddSlider("CfgNameEspDistance", {
    Text = "Name ESP Distance",
    Default = Cfg.nameEspMaxDistance,
    Min = 200,
    Max = 5000,
    Rounding = 0,
    Suffix = " studs",
    Callback = function(v)
        Cfg.nameEspMaxDistance = v
        saveCfg("cfg", Cfg)
    end,
})

uiRefs.NameEspTextSizeSlider = visualValuesGroup:AddSlider("CfgNameEspTextSize", {
    Text = "Name ESP Text Size",
    Default = Cfg.nameEspTextSize,
    Min = 11,
    Max = 24,
    Rounding = 0,
    Callback = function(v)
        Cfg.nameEspTextSize = v
        saveCfg("cfg", Cfg)
    end,
})

uiRefs.TracerThicknessSlider = visualValuesGroup:AddSlider("CfgTracerThickness", {
    Text = "Tracer Thickness",
    Default = Cfg.tracerThickness,
    Min = 1,
    Max = 6,
    Rounding = 1,
    Callback = function(v)
        Cfg.tracerThickness = v
        saveCfg("cfg", Cfg)
    end,
})

uiRefs.SkeletonThicknessSlider = visualValuesGroup:AddSlider("CfgSkeletonThickness", {
    Text = "Skeleton Thickness",
    Default = Cfg.skeletonThickness,
    Min = 1,
    Max = 6,
    Rounding = 1,
    Callback = function(v)
        Cfg.skeletonThickness = v
        saveCfg("cfg", Cfg)
    end,
})

local function addMainBanner(group, iconValue)
    local imageSource = iconValue
    if type(imageSource) == "number" then
        imageSource = "rbxassetid://" .. tostring(imageSource)
    end

    if type(imageSource) == "string" and imageSource ~= "" then
        local okPassthrough = pcall(function()
            local holder = Instance.new("Frame")
            holder.Name = "MainBannerHolder"
            holder.BackgroundTransparency = 1
            holder.Size = UDim2.fromScale(1, 1)

            local imageLabel = Instance.new("ImageLabel")
            imageLabel.Name = "MainBannerImage"
            imageLabel.BackgroundTransparency = 1
            imageLabel.Size = UDim2.fromScale(1, 1)
            imageLabel.Image = imageSource
            imageLabel.ScaleType = Enum.ScaleType.Fit
            imageLabel.Parent = holder

            group:AddUIPassthrough("MainBannerRaw", {
                Instance = holder,
                Height = 82,
            })
        end)

        if okPassthrough then
            return
        end
    end

    local ok = pcall(function()
        group:AddImage("MainBanner", {
            Image = imageSource,
            Height = 82,
            ScaleType = Enum.ScaleType.Fit,
        })
    end)

    if ok then
        return
    end

    pcall(function()
        group:AddImage("MainBanner", {
            Image = defaultWindowIconSource,
            Height = 82,
            ScaleType = Enum.ScaleType.Fit,
        })
    end)
end

addMainBanner(menuInfoGroup, resolvedMainBannerImage)
menuInfoGroup:AddLabel("PLunder Hub")
menuInfoGroup:AddLabel("Rivals Edition")
menuInfoGroup:AddLabel("Main Menu")

clientInfoGroup:AddLabel("Owner: Sebass")
clientInfoGroup:AddLabel("Player: " .. localPlayer.Name)
clientInfoGroup:AddLabel("Executor: " .. EXECUTOR_NAME)
clientInfoGroup:AddLabel("Game: Rivals")
uiRefs.TargetLabel = clientInfoGroup:AddLabel("Target: -")
uiRefs.AutoLoadLabel = clientInfoGroup:AddLabel("Auto-load: -")

discordInfoGroup:AddLabel("Join the PLunder Hub community")
discordInfoGroup:AddLabel("News, support, and script updates")
discordInfoGroup:AddLabel("Invite: " .. DISCORD_INVITE, true)
discordInfoGroup:AddButton({
    Text = "Copy Discord Invite",
    Func = function()
        if setclipboard then
            setclipboard(DISCORD_INVITE)
            notify("Discord link copied", 2)
        else
            notify("Clipboard not supported", 2)
        end
    end,
})

local buildNameInput = buildsGroup:AddInput("BuildNameInput", {
    Text = "Build Name",
    Default = "",
    Placeholder = "Build name...",
    Finished = true,
    Callback = function()
    end,
})

local function getBuildNames()
    local builds = loadBuilds()
    local names = {}

    for _, build in ipairs(builds) do
        names[#names + 1] = build.name
    end

    if #names == 0 then
        names = { "None" }
    end

    return names
end

uiRefs.BuildDropdown = buildsGroup:AddDropdown("BuildSelect", {
    Values = getBuildNames(),
    Default = 1,
    Text = "Saved Builds",
    Callback = function()
    end,
})

local function refreshBuildDropdown(targetName)
    if not uiRefs.BuildDropdown then
        return
    end

    local names = getBuildNames()
    uiRefs.BuildDropdown:SetValues(names)

    local selected = targetName
    if not selected or not table.find(names, selected) then
        selected = names[1]
    end

    uiRefs.BuildDropdown:SetValue(selected)

    if uiRefs.AutoLoadLabel and uiRefs.AutoLoadLabel.SetText then
        local autoLoadName = getAutoLoad()
        uiRefs.AutoLoadLabel:SetText(autoLoadName and ("Auto-load: " .. autoLoadName) or "Auto-load: -")
    end
end

buildsGroup:AddButton({
    Text = "Save New Build",
    Func = function()
        local name = trim(buildNameInput.Value)
        if name == "" then
            name = "Build " .. tostring(#loadBuilds() + 1)
        end

        local builds = loadBuilds()
        local state = snapshot()
        state.name = name
        builds[#builds + 1] = state

        saveBuilds(builds)
        refreshBuildDropdown(name)
        notify("Saved build: " .. name, 2)
    end,
})

buildsGroup:AddButton({
    Text = "Load Selected Build",
    Func = function()
        if not uiRefs.BuildDropdown then
            return
        end

        local selected = uiRefs.BuildDropdown.Value
        if not selected or selected == "None" then
            notify("No build selected", 2)
            return
        end

        local builds = loadBuilds()
        for _, build in ipairs(builds) do
            if build.name == selected then
                applyBuild(build)
                activeLoadedBuild = build.name
                notify("Loaded build: " .. build.name, 2)
                return
            end
        end

        notify("Build not found", 2)
    end,
})

buildsGroup:AddButton({
    Text = "Save Current to Selected",
    Func = function()
        if not uiRefs.BuildDropdown then
            return
        end

        local selected = uiRefs.BuildDropdown.Value
        if not selected or selected == "None" then
            notify("No build selected", 2)
            return
        end

        local builds = loadBuilds()
        for idx, build in ipairs(builds) do
            if build.name == selected then
                local state = snapshot()
                state.name = build.name
                builds[idx] = state

                saveBuilds(builds)
                activeLoadedBuild = build.name
                refreshBuildDropdown(build.name)
                notify("Updated build: " .. build.name, 2)
                return
            end
        end

        notify("Build not found", 2)
    end,
})

buildsGroup:AddButton({
    Text = "Delete Selected Build",
    Func = function()
        if not uiRefs.BuildDropdown then
            return
        end

        local selected = uiRefs.BuildDropdown.Value
        if not selected or selected == "None" then
            notify("No build selected", 2)
            return
        end

        local builds = loadBuilds()
        local removed = false
        for i = #builds, 1, -1 do
            if builds[i].name == selected then
                table.remove(builds, i)
                removed = true
            end
        end

        if not removed then
            notify("Build not found", 2)
            return
        end

        if getAutoLoad() == selected then
            setAutoLoad(nil)
        end

        if activeLoadedBuild == selected then
            activeLoadedBuild = nil
        end

        saveBuilds(builds)
        refreshBuildDropdown(nil)
        notify("Deleted build: " .. selected, 2)
    end,
})

buildsGroup:AddButton({
    Text = "Set Selected Auto-Load",
    Func = function()
        if not uiRefs.BuildDropdown then
            return
        end

        local selected = uiRefs.BuildDropdown.Value
        if not selected or selected == "None" then
            notify("No build selected", 2)
            return
        end

        setAutoLoad(selected)
        refreshBuildDropdown(selected)
        notify("Auto-load set: " .. selected, 2)
    end,
})

buildsGroup:AddButton({
    Text = "Clear Auto-Load",
    Func = function()
        setAutoLoad(nil)
        refreshBuildDropdown(nil)
        notify("Auto-load cleared", 2)
    end,
})

keybindsGroup:AddDropdown("ToggleHubKey", {
    Values = KEY_OPTIONS,
    Default = indexOf(KEY_OPTIONS, keyOrNone(Keybinds.togglehub)),
    Text = "Toggle Menu",
    Callback = function(value)
        Keybinds.togglehub = keyOrNone(value)
        saveCfg("keybinds", Keybinds)
    end,
})

quickActionsGroup:AddButton({
    Text = "Copy Discord Invite",
    Func = function()
        if setclipboard then
            setclipboard(DISCORD_INVITE)
            notify("Discord link copied", 2)
        else
            notify("Clipboard not supported", 2)
        end
    end,
})

quickActionsGroup:AddButton({
    Text = "Apply No Recoil Patch",
    Func = function()
        if not ON.norecoil then
            notify("Enable No Recoil first", 2)
            return
        end

        applyNoRecoilPatch()
        notify("No recoil patch refreshed", 2)
    end,
})

quickActionsGroup:AddButton({
    Text = "Clear Aimbot Lock",
    Func = function()
        clearAimbotLock()
        notify("Aimbot lock cleared", 2)
    end,
})

safetyActionsGroup:AddButton({
    Text = "Panic: Disable Combat",
    Func = function()
        ON.aimbot = false
        ON.triggerbot = false
        ON.norecoil = false
        clearAimbotLock()

        setNoRecoilEnabled(false)
        saveCfg("toggles", ON)

        for _, feature in ipairs({ "aimbot", "triggerbot", "norecoil" }) do
            local toggleRef = uiRefs.FeatureToggles[feature]
            if toggleRef and toggleRef.SetValue then
                pcall(function()
                    toggleRef:SetValue(false)
                end)
            end
        end

        notify("Combat features disabled", 2)
    end,
})

safetyActionsGroup:AddButton({
    Text = "Clear Visual ESP",
    Func = function()
        clearTracerLines()
        clearSkeletonLines()
        clearNameEspTexts()
        notify("Visual ESP cleared", 2)
    end,
})

safetyActionsGroup:AddButton({
    Text = "Unload Hub",
    Func = function()
        scriptAlive = false
        clearAimbotLock()

        for _, box in pairs(espBoxes) do
            pcall(function()
                box:Destroy()
            end)
        end
        espBoxes = {}

        for _, highlight in pairs(chamsMap) do
            pcall(function()
                highlight:Destroy()
            end)
        end
        chamsMap = {}

        clearTracerLines()
        clearSkeletonLines()
        clearNameEspTexts()

        setNoRecoilEnabled(false)
        setAntiAfkEnabled(false)

        for _, conn in ipairs(connections) do
            pcall(function()
                conn:Disconnect()
            end)
        end

        if fovGui then
            pcall(function()
                fovGui:Destroy()
            end)
        end

        pcall(function()
            Library:Unload()
        end)
    end,
})

refreshBuildDropdown(getAutoLoad())
setAntiAfkEnabled(ON.antiafk == true)
setNoRecoilEnabled(ON.norecoil == true)

local function isMenuToggleKey(keyCode)
    if keyCode == Enum.KeyCode.L or keyCode == Enum.KeyCode.RightShift then
        return true
    end

    local configured = keyOrNone(Keybinds.togglehub)
    if configured == "None" then
        return false
    end

    return keyCode.Name == configured
end

table.insert(connections, UserInputService.InputBegan:Connect(function(input, processed)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then
        return
    end

    local keyCode = input.KeyCode

    if isMenuToggleKey(keyCode) then
        pcall(function()
            Library:Toggle()
        end)
        return
    end

    if processed then
        return
    end

    for feature, keyName in pairs(Keybinds) do
        if feature ~= "togglehub" and keyName and keyName ~= "None" and keyName ~= "" and keyCode.Name == keyName then
            ON[feature] = not ON[feature]
            saveCfg("toggles", ON)

            if feature == "norecoil" then
                setNoRecoilEnabled(ON[feature])
            elseif feature == "antiafk" then
                setAntiAfkEnabled(ON[feature])
            end

            local toggleRef = uiRefs.FeatureToggles[feature]
            if toggleRef and toggleRef.SetValue then
                pcall(function()
                    toggleRef:SetValue(ON[feature])
                end)
            end
        end
    end
end))

local uiUpdateTimer = 0
table.insert(connections, RunService.Heartbeat:Connect(function(dt)
    if not scriptAlive then
        return
    end

    uiUpdateTimer = uiUpdateTimer + dt
    if uiUpdateTimer < 0.25 then
        return
    end
    uiUpdateTimer = 0

    if uiRefs.TargetLabel and uiRefs.TargetLabel.SetText then
        local locked = aimbotLockedTarget

        if ON.aimbot and locked and locked.Parent and isEnemy(locked) then
            uiRefs.TargetLabel:SetText("Locked: " .. locked.Name)
        else
            local target = getNearestEnemyInFov(getAimbotFovRadius())
            uiRefs.TargetLabel:SetText(target and ("Target: " .. target.model.Name) or "Target: -")
        end
    end

    if uiRefs.AutoLoadLabel and uiRefs.AutoLoadLabel.SetText then
        local autoLoadName = getAutoLoad()
        uiRefs.AutoLoadLabel:SetText(autoLoadName and ("Auto-load: " .. autoLoadName) or "Auto-load: -")
    end
end))

notify("PLunder Hub Rivals loaded | L / RightShift / RightCtrl = toggle", 4)
