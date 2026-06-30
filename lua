local REQUIRED_KEY = "UvuHubHolyMoly"
local WINDOW_TITLE = "Plunder/Atlas Hub Key System"

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")

local localPlayer = Players.LocalPlayer

local Theme = {
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

local function notify(message, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = WINDOW_TITLE,
            Text = message,
            Duration = duration or 3,
        })
    end)
end

local function verifyKey(key)
    return tostring(key or "") == REQUIRED_KEY
end

local function runProtectedScript()
    local ok, err = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/maddonk1241/Rivals/774a3493b86b04bf5e013b5b9a1b0cd550663a92/Rivals.lua"))()
    end)

    if ok then
        notify("Key accepted. Script loaded.", 3)
        return true
    else
        notify("Failed to load script.", 3)
        warn("PLunder Hub load error: " .. tostring(err))
        return false
    end
end

local function unlockWithKey(inputKey)
    if not verifyKey(inputKey) then
        return false
    end

    return runProtectedScript()
end

local existingGui = localPlayer.PlayerGui:FindFirstChild("PLunderHubKeyGui")
if existingGui then
    existingGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "PLunderHubKeyGui"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = localPlayer:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 420, 0, 220)
main.Position = UDim2.new(0.5, -210, 0.5, -110)
main.BackgroundColor3 = Theme.Background
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = main

local stroke = Instance.new("UIStroke")
stroke.Color = Theme.AccentSoft
stroke.Thickness = 1
stroke.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 30)
title.Position = UDim2.new(0, 10, 0, 10)
title.BackgroundTransparency = 1
title.Text = "PLunder/Atlas-Hub | Key System"
title.TextColor3 = Theme.TextMain
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -20, 0, 18)
subtitle.Position = UDim2.new(0, 10, 0, 40)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Enter key to unlock script access"
subtitle.TextColor3 = Theme.TextSoft
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 12
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = main

local keyBox = Instance.new("TextBox")
keyBox.Size = UDim2.new(1, -20, 0, 40)
keyBox.Position = UDim2.new(0, 10, 0, 72)
keyBox.BackgroundColor3 = Theme.Panel
keyBox.BorderSizePixel = 0
keyBox.ClearTextOnFocus = false
keyBox.PlaceholderText = "Enter key..."
keyBox.Text = ""
keyBox.TextColor3 = Theme.TextMain
keyBox.PlaceholderColor3 = Theme.TextMuted
keyBox.Font = Enum.Font.Code
keyBox.TextSize = 16
keyBox.Parent = main

local keyCorner = Instance.new("UICorner")
keyCorner.CornerRadius = UDim.new(0, 8)
keyCorner.Parent = keyBox

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 28)
statusLabel.Position = UDim2.new(0, 10, 0, 122)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = ""
statusLabel.TextColor3 = Theme.Error
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 12
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = main

local submitButton = Instance.new("TextButton")
submitButton.Size = UDim2.new(1, -20, 0, 42)
submitButton.Position = UDim2.new(0, 10, 1, -52)
submitButton.BackgroundColor3 = Theme.Accent
submitButton.BorderSizePixel = 0
submitButton.Text = "Unlock"
submitButton.TextColor3 = Theme.AccentText
submitButton.Font = Enum.Font.GothamBold
submitButton.TextSize = 16
submitButton.Parent = main

local submitCorner = Instance.new("UICorner")
submitCorner.CornerRadius = UDim.new(0, 8)
submitCorner.Parent = submitButton

local isLoading = false
local hasLoaded = false

local function setLoadingState(loading)
    isLoading = loading
    submitButton.Active = not loading
    submitButton.AutoButtonColor = not loading
    submitButton.Text = loading and "Loading..." or "Unlock"
    keyBox.TextEditable = not loading
end

local function attemptUnlock()
    if hasLoaded or isLoading then
        return
    end

    local enteredKey = keyBox.Text
    if not verifyKey(enteredKey) then
        statusLabel.Text = "Invalid key. Try again."
        notify("Invalid key.", 2)
        return
    end

    statusLabel.Text = ""
    setLoadingState(true)

    if unlockWithKey(enteredKey) then
        hasLoaded = true
        gui:Destroy()
        return
    end

    setLoadingState(false)
    statusLabel.Text = "Load failed. Try again."
end

submitButton.MouseButton1Click:Connect(attemptUnlock)
keyBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        attemptUnlock()
    end
end)
