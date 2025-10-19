local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local GuiClickOutside = {}

export type CloseType = "default" | "animate_up" | "animate_down" | "fade_out" | "scale_down" | "slide_left" | "slide_right" | "instant"
export type CloseHandler = (screenGui: ScreenGui) -> ()

type RegisteredGuis = {[ScreenGui]: CloseType | string}
type CloseHandlers = {[string]: CloseHandler}

local registeredGuis: RegisteredGuis = {}

local function isClickInsideGui(screenGui: ScreenGui, position: Vector3): boolean
    local guis = Players.LocalPlayer.PlayerGui:GetGuiObjectsAtPosition(position.X, position.Y)
    for _, gui in ipairs(guis) do
        if gui:IsDescendantOf(screenGui) then
            return true
        end
    end
    return false
end

local closeHandlers: CloseHandlers = {
    default = function(screenGui: ScreenGui)
        screenGui.Enabled = false
    end,
    
    animate_up = function(screenGui: ScreenGui)
        local mainFrame = screenGui:FindFirstChildWhichIsA("Frame")
        if mainFrame then
            local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
            local tween = TweenService:Create(mainFrame, tweenInfo, {
                Position = UDim2.new(mainFrame.Position.X.Scale, mainFrame.Position.X.Offset, -0.5, 0)
            })
            tween:Play()
            tween.Completed:Connect(function()
                screenGui.Enabled = false
            end)
        else
            screenGui.Enabled = false
        end
    end,
    
    animate_down = function(screenGui: ScreenGui)
        local mainFrame = screenGui:FindFirstChildWhichIsA("Frame")
        if mainFrame then
            local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
            local tween = TweenService:Create(mainFrame, tweenInfo, {
                Position = UDim2.new(mainFrame.Position.X.Scale, mainFrame.Position.X.Offset, 1.5, 0)
            })
            tween:Play()
            tween.Completed:Connect(function()
                screenGui.Enabled = false
            end)
        else
            screenGui.Enabled = false
        end
    end,
    
    fade_out = function(screenGui: ScreenGui)
        local mainFrame = screenGui:FindFirstChildWhichIsA("Frame")
        if mainFrame then
            local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local tween = TweenService:Create(mainFrame, tweenInfo, {
                BackgroundTransparency = 1
            })
            tween:Play()
            
            for _, descendant in ipairs(mainFrame:GetDescendants()) do
                if descendant:IsA("GuiObject") then
                    TweenService:Create(descendant, tweenInfo, {
                        BackgroundTransparency = 1,
                        TextTransparency = 1
                    }):Play()
                elseif descendant:IsA("ImageLabel") or descendant:IsA("ImageButton") then
                    TweenService:Create(descendant, tweenInfo, {
                        ImageTransparency = 1
                    }):Play()
                end
            end
            
            tween.Completed:Connect(function()
                screenGui.Enabled = false
            end)
        else
            screenGui.Enabled = false
        end
    end,
    
    scale_down = function(screenGui: ScreenGui)
        local mainFrame = screenGui:FindFirstChildWhichIsA("Frame")
        if mainFrame then
            local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In)
            local tween = TweenService:Create(mainFrame, tweenInfo, {
                Size = UDim2.new(0, 0, 0, 0)
            })
            tween:Play()
            tween.Completed:Connect(function()
                screenGui.Enabled = false
            end)
        else
            screenGui.Enabled = false
        end
    end,
    
    slide_left = function(screenGui: ScreenGui)
        local mainFrame = screenGui:FindFirstChildWhichIsA("Frame")
        if mainFrame then
            local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            local tween = TweenService:Create(mainFrame, tweenInfo, {
                Position = UDim2.new(-0.5, 0, mainFrame.Position.Y.Scale, mainFrame.Position.Y.Offset)
            })
            tween:Play()
            tween.Completed:Connect(function()
                screenGui.Enabled = false
            end)
        else
            screenGui.Enabled = false
        end
    end,
    
    slide_right = function(screenGui: ScreenGui)
        local mainFrame = screenGui:FindFirstChildWhichIsA("Frame")
        if mainFrame then
            local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            local tween = TweenService:Create(mainFrame, tweenInfo, {
                Position = UDim2.new(1.5, 0, mainFrame.Position.Y.Scale, mainFrame.Position.Y.Offset)
            })
            tween:Play()
            tween.Completed:Connect(function()
                screenGui.Enabled = false
            end)
        else
            screenGui.Enabled = false
        end
    end,
    
    instant = function(screenGui: ScreenGui)
        screenGui.Enabled = false
    end
}

function GuiClickOutside.register(screenGui: ScreenGui, closeType: CloseType?): ()
    if registeredGuis[screenGui] then
        return
    end
    
    closeType = closeType or "default"
    registeredGuis[screenGui] = closeType
end

function GuiClickOutside.unregister(screenGui: ScreenGui): ()
    registeredGuis[screenGui] = nil
end

function GuiClickOutside.addCustomHandler(name: string, handler: CloseHandler): ()
    closeHandlers[name] = handler
end

UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and not processed then
        for screenGui, closeType in pairs(registeredGuis) do
            if screenGui.Enabled and not isClickInsideGui(screenGui, input.Position) then
                local handler = closeHandlers[closeType] or closeHandlers.default
                handler(screenGui)
            end
        end
    end
end)

return GuiClickOutside