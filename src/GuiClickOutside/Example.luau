-- Example usage in a LocalScript in StarterPlayerScripts

local GuiClickOutside = require(script.Parent.GuiClickOutside)
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- Basic registration with default close (instant disable)
local settingsGui = PlayerGui:WaitForChild("Settings")
GuiClickOutside.register(settingsGui, "default")

-- Animate upwards when closing
local storeGui = PlayerGui:WaitForChild("Store")
GuiClickOutside.register(storeGui, "animate_up")

-- Fade out effect
local notificationGui = PlayerGui:WaitForChild("Notification")
GuiClickOutside.register(notificationGui, "fade_out")

-- Scale down animation
local popupGui = PlayerGui:WaitForChild("Popup")
GuiClickOutside.register(popupGui, "scale_down")

-- Slide animations
local leftMenuGui = PlayerGui:WaitForChild("LeftMenu")
GuiClickOutside.register(leftMenuGui, "slide_left")

local rightMenuGui = PlayerGui:WaitForChild("RightMenu")
GuiClickOutside.register(rightMenuGui, "slide_right")

-- Custom handler example
GuiClickOutside.addCustomHandler("rotate_out", function(screenGui: ScreenGui)
    local mainFrame = screenGui:FindFirstChildWhichIsA("Frame")
    if mainFrame then
        local TweenService = game:GetService("TweenService")
        local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        local tween = TweenService:Create(mainFrame, tweenInfo, {
            Rotation = 180,
            Size = UDim2.new(0, 0, 0, 0)
        })
        tween:Play()
        tween.Completed:Connect(function()
            screenGui.Enabled = false
        end)
    else
        screenGui.Enabled = false
    end
end)

local specialGui = PlayerGui:WaitForChild("Special")
GuiClickOutside.register(specialGui, "rotate_out")

-- Unregister example (if you want to prevent outside clicks from closing)
local function toggleGuiProtection(gui: ScreenGui, protected: boolean)
    if protected then
        GuiClickOutside.unregister(gui)
    else
        GuiClickOutside.register(gui, "fade_out")
    end
end

-- Usage with a button that opens the GUI
local openButton = PlayerGui:WaitForChild("OpenButton"):WaitForChild("TextButton")
openButton.MouseButton1Click:Connect(function()
    storeGui.Enabled = true
end)

-- Multiple GUIs with different behaviours
local guis = {
    {gui = PlayerGui:WaitForChild("Inventory"), closeType = "slide_right"},
    {gui = PlayerGui:WaitForChild("Map"), closeType = "fade_out"},
    {gui = PlayerGui:WaitForChild("Quest"), closeType = "animate_down"},
}

for _, data in ipairs(guis) do
    GuiClickOutside.register(data.gui, data.closeType)
end