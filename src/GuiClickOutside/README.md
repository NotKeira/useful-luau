# GuiClickOutside Module

A comprehensive GUI interaction library for automatically closing Roblox ScreenGuis when clicking outside their bounds.

## 🎯 Features

- **Multiple Close Animations** - 8 built-in close animations including slides, fades, and scales
- **Custom Handler Support** - Add custom close behaviours for specific requirements
- **Type-Safe API** - Full Luau type annotations for enhanced development experience
- **Automatic Click Detection** - Detects clicks outside registered GUIs automatically
- **Multi-GUI Support** - Register multiple GUIs with different close behaviours simultaneously
- **Zero Configuration** - Works immediately with sensible defaults
- **Performance Optimised** - Efficient click detection with minimal overhead

## 🚀 Quick Start

### Basic Usage

```luau
local GuiClickOutside = require(game.StarterPlayer.StarterPlayerScripts.GuiClickOutside)
local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")

-- Register a GUI with instant close
local settingsGui = PlayerGui:WaitForChild("Settings")
GuiClickOutside.register(settingsGui, "default")

-- Register with animation
local storeGui = PlayerGui:WaitForChild("Store")
GuiClickOutside.register(storeGui, "animate_up")
```

### Fade Out Animation

```luau
local notificationGui = PlayerGui:WaitForChild("Notification")
GuiClickOutside.register(notificationGui, "fade_out")
```

### Unregistering GUIs

```luau
-- Prevent outside clicks from closing a GUI
GuiClickOutside.unregister(settingsGui)
```

## 📖 API Reference

### Types

#### `CloseType`

```luau
export type CloseType = "default" | "animate_up" | "animate_down" | "fade_out" | "scale_down" | "slide_left" | "slide_right" | "instant"
```

Built-in close animation types.

#### `CloseHandler`

```luau
export type CloseHandler = (screenGui: ScreenGui) -> ()
```

Function signature for custom close handlers.

### Functions

#### `register(screenGui: ScreenGui, closeType: CloseType?) -> ()`

Registers a ScreenGui to be monitored for outside clicks.

**Parameters:**
- `screenGui` - The ScreenGui to monitor
- `closeType` - Close animation type (defaults to `"default"`)

**Example:**
```luau
GuiClickOutside.register(myGui, "fade_out")
```

#### `unregister(screenGui: ScreenGui) -> ()`

Removes a ScreenGui from monitoring, preventing outside clicks from closing it.

**Parameters:**
- `screenGui` - The ScreenGui to stop monitoring

**Example:**
```luau
GuiClickOutside.unregister(myGui)
```

#### `addCustomHandler(name: string, handler: CloseHandler) -> ()`

Registers a custom close handler that can be used with any ScreenGui.

**Parameters:**
- `name` - Unique identifier for the handler
- `handler` - Function that handles closing the GUI

**Example:**
```luau
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

GuiClickOutside.register(myGui, "rotate_out")
```

## 🎨 Built-in Close Types

### `default` / `instant`

Immediately disables the ScreenGui without animation.

**Use Cases:**
- Settings menus
- Simple dialogs
- Non-critical notifications

**Duration:** Instant

---

### `animate_up`

Slides the first Frame child upwards off screen with a back easing effect.

**Use Cases:**
- Bottom-anchored menus
- Modal dialogs
- Shop interfaces

**Duration:** 0.3 seconds  
**Easing:** Back In

---

### `animate_down`

Slides the first Frame child downwards off screen with a back easing effect.

**Use Cases:**
- Top-anchored notifications
- Drop-down menus
- Header panels

**Duration:** 0.3 seconds  
**Easing:** Back In

---

### `fade_out`

Fades all GUI elements to complete transparency, including text and images.

**Use Cases:**
- Overlay screens
- Tutorial popups
- Subtle notifications

**Duration:** 0.25 seconds  
**Easing:** Quad Out

---

### `scale_down`

Shrinks the first Frame child to zero size with a back easing effect.

**Use Cases:**
- Popup windows
- Confirmation dialogs
- Achievement notifications

**Duration:** 0.2 seconds  
**Easing:** Back In

---

### `slide_left`

Slides the first Frame child off screen to the left.

**Use Cases:**
- Right-side menus
- Navigation panels
- Side inventories

**Duration:** 0.3 seconds  
**Easing:** Quad In

---

### `slide_right`

Slides the first Frame child off screen to the right.

**Use Cases:**
- Left-side menus
- Character panels
- Quest logs

**Duration:** 0.3 seconds  
**Easing:** Quad In

---

## 🧪 Examples

### Basic Registration

```luau
local GuiClickOutside = require(script.Parent.GuiClickOutside)
local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")

-- Simple instant close
local settingsGui = PlayerGui:WaitForChild("Settings")
GuiClickOutside.register(settingsGui, "default")
```

### Multiple GUIs with Different Animations

```luau
local GuiClickOutside = require(script.Parent.GuiClickOutside)
local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")

local guis = {
    {gui = PlayerGui:WaitForChild("Inventory"), closeType = "slide_right"},
    {gui = PlayerGui:WaitForChild("Map"), closeType = "fade_out"},
    {gui = PlayerGui:WaitForChild("Quest"), closeType = "animate_down"},
    {gui = PlayerGui:WaitForChild("Store"), closeType = "scale_down"},
}

for _, data in ipairs(guis) do
    GuiClickOutside.register(data.gui, data.closeType)
end
```

### Custom Handler Example

```luau
local GuiClickOutside = require(script.Parent.GuiClickOutside)
local TweenService = game:GetService("TweenService")
local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")

-- Register custom spin-out animation
GuiClickOutside.addCustomHandler("spin_out", function(screenGui: ScreenGui)
    local mainFrame = screenGui:FindFirstChildWhichIsA("Frame")
    if mainFrame then
        local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.In)
        local tween = TweenService:Create(mainFrame, tweenInfo, {
            Rotation = 360,
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 0, 0, 0)
        })
        tween:Play()
        tween.Completed:Connect(function()
            screenGui.Enabled = false
            mainFrame.Rotation = 0
            mainFrame.BackgroundTransparency = 0
        end)
    else
        screenGui.Enabled = false
    end
end)

local specialGui = PlayerGui:WaitForChild("Special")
GuiClickOutside.register(specialGui, "spin_out")
```

### Toggle Protection

```luau
local GuiClickOutside = require(script.Parent.GuiClickOutside)
local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
local importantGui = PlayerGui:WaitForChild("Important")

-- Function to toggle whether outside clicks close the GUI
local function setGuiProtection(protected: boolean)
    if protected then
        GuiClickOutside.unregister(importantGui)
        print("GUI is now protected from outside clicks")
    else
        GuiClickOutside.register(importantGui, "fade_out")
        print("GUI can now be closed by outside clicks")
    end
end

-- Example: Protect during important operations
local function performCriticalAction()
    setGuiProtection(true)
    -- Do important work
    task.wait(5)
    setGuiProtection(false)
end
```

### Integration with Open Buttons

```luau
local GuiClickOutside = require(script.Parent.GuiClickOutside)
local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")

local inventoryGui = PlayerGui:WaitForChild("Inventory")
local openButton = PlayerGui:WaitForChild("OpenButton"):WaitForChild("TextButton")

-- Register with slide animation
GuiClickOutside.register(inventoryGui, "slide_right")

-- Open button toggles the GUI
openButton.MouseButton1Click:Connect(function()
    inventoryGui.Enabled = not inventoryGui.Enabled
end)
```

## 🔧 Implementation Details

### Click Detection

The module uses `GetGuiObjectsAtPosition` to detect whether a click intersects with any GUI elements within the registered ScreenGui. This ensures accurate detection even with complex nested GUI structures.

### Animation Behaviour

All animations operate on the first `Frame` child found within the ScreenGui using `FindFirstChildWhichIsA("Frame")`. If no Frame is found, the ScreenGui is disabled instantly without animation.

### Event Handling

The module listens to `UserInputService.InputBegan` with `MouseButton1` input type. The `processed` parameter is respected to avoid interfering with other UI systems (e.g., text input fields).

### State Management

Each registered ScreenGui is stored in an internal table with its associated close type. When a ScreenGui is unregistered, it's removed from monitoring but remains in PlayerGui.

## 📋 Installation

1. Create a ModuleScript in `StarterPlayer.StarterPlayerScripts`
2. Name it `GuiClickOutside`
3. Paste the module code
4. Require it from any LocalScript in StarterPlayerScripts

```luau
local GuiClickOutside = require(script.Parent.GuiClickOutside)
```

## ⚠️ Best Practices

### Structure Requirements

- ScreenGuis should contain at least one `Frame` as a direct child for animations to work
- Ensure Frames are properly anchored before using slide animations
- Test animations with your specific GUI layouts

### Performance Considerations

- Unregister GUIs that are no longer in use
- Avoid registering GUIs that should never be closed by outside clicks
- Use `"instant"` for non-critical GUIs to reduce tween overhead

### Common Pitfalls

- **Missing Frame**: If your ScreenGui has no Frame child, animations fall back to instant close
- **Z-Index Issues**: Ensure your GUIs have proper z-index ordering to prevent click detection issues
- **Multiple Registrations**: Attempting to register the same GUI twice has no effect (first registration is preserved)

### Animation Selection Guide

| Use Case | Recommended Type |
|----------|------------------|
| Settings menu | `default` or `fade_out` |
| Shop/Store | `animate_up` or `scale_down` |
| Side inventory | `slide_left` or `slide_right` |
| Notifications | `fade_out` or `animate_down` |
| Popup dialogs | `scale_down` |
| Full-screen overlays | `fade_out` |

## 🏗️ Architecture

```
GuiClickOutside.luau
├── Type Definitions
│   ├── CloseType (union type)
│   ├── CloseHandler (function signature)
│   └── Internal tables
├── Click Detection
│   └── GetGuiObjectsAtPosition integration
├── Close Handlers
│   ├── default / instant
│   ├── animate_up / animate_down
│   ├── fade_out
│   ├── scale_down
│   └── slide_left / slide_right
├── Public API
│   ├── register()
│   ├── unregister()
│   └── addCustomHandler()
└── Event System
    └── UserInputService integration
```

## 🔍 Troubleshooting

### GUI Not Closing

1. Verify the GUI is properly registered: `GuiClickOutside.register(myGui, "default")`
2. Check that `myGui.Enabled` is `true` when clicking outside
3. Ensure no other scripts are interfering with click detection
4. Verify the GUI is a `ScreenGui` instance

### Animation Not Playing

1. Confirm the ScreenGui contains a `Frame` child
2. Check the Frame isn't already animating
3. Verify TweenService is accessible
4. Try using `"instant"` to test if close logic works

### Clicks Not Detected

1. Check if `processed` parameter is being set by other UI elements
2. Verify UserInputService is enabled
3. Ensure the ScreenGui is in PlayerGui
4. Check if GUI elements have proper `Active` and `AutoButtonColor` properties

## 📜 Licence

Licenced under the MIT Licence - see the main repository LICENCE file for details.

## 👤 Author

**Keira Hopkins**
- GitHub: [@NotKeira](https://github.com/NotKeira)

---

_Built for seamless user experience with type safety in mind_ 🎯