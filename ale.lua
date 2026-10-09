local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local Remote = ReplicatedStorage.Packages.Networking["RF/Codes/Code"]

local Codes = {
    "1BVISITS",
    "HOTEL",
    "FREE",
    "BACK",
    "GAME",
    "EGGHUNT"
}

local Selected = Codes[1]
local Busy = false

local Gui = Instance.new("ScreenGui")
Gui.Name = "CodesMenu"
Gui.ResetOnSpawn = false
Gui.DisplayOrder = 20
Gui.Parent = Player:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(290, 255)
Main.Position = UDim2.new(0.5, -145, 0.5, -127)
Main.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = Gui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 12)
Corner.Parent = Main

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(58, 58, 65)
Stroke.Thickness = 1
Stroke.Parent = Main

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 58)
Header.BackgroundColor3 = Color3.fromRGB(31, 31, 36)
Header.BorderSizePixel = 0
Header.Active = true
Header.Parent = Main

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 12)
HeaderCorner.Parent = Header

local Fix = Instance.new("Frame")
Fix.Size = UDim2.new(1, 0, 0, 12)
Fix.Position = UDim2.new(0, 0, 1, -12)
Fix.BackgroundColor3 = Header.BackgroundColor3
Fix.BorderSizePixel = 0
Fix.Parent = Header

local Title = Instance.new("TextLabel")
Title.Position = UDim2.fromOffset(16, 8)
Title.Size = UDim2.new(1, -55, 0, 24)
Title.BackgroundTransparency = 1
Title.Text = "Códigos"
Title.TextColor3 = Color3.fromRGB(245, 245, 245)
Title.TextSize = 19
Title.Font = Enum.Font.GothamSemibold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Subtitle = Instance.new("TextLabel")
Subtitle.Position = UDim2.fromOffset(17, 32)
Subtitle.Size = UDim2.new(1, -30, 0, 17)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "Selecciona"
Subtitle.TextColor3 = Color3.fromRGB(155, 155, 165)
Subtitle.TextSize = 11
Subtitle.Font = Enum.Font.Gotham
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = Header

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(30, 30)
Close.Position = UDim2.new(1, -38, 0, 12)
Close.BackgroundColor3 = Color3.fromRGB(48, 48, 54)
Close.Text = "×"
Close.TextColor3 = Color3.fromRGB(225, 225, 225)
Close.TextSize = 23
Close.Font = Enum.Font.Gotham
Close.Parent = Header

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 8)
CloseCorner.Parent = Close

local Label = Instance.new("TextLabel")
Label.Position = UDim2.fromOffset(16, 72)
Label.Size = UDim2.new(1, -32, 0, 18)
Label.BackgroundTransparency = 1
Label.Text = "CÓDIGOS"
Label.TextColor3 = Color3.fromRGB(165, 165, 175)
Label.TextSize = 10
Label.Font = Enum.Font.GothamSemibold
Label.TextXAlignment = Enum.TextXAlignment.Left
Label.Parent = Main

local Select = Instance.new("TextButton")
Select.Position = UDim2.fromOffset(16, 96)
Select.Size = UDim2.new(1, -32, 0, 40)
Select.BackgroundColor3 = Color3.fromRGB(36, 36, 42)
Select.Text = "  " .. Selected .. "                              ▼"
Select.TextColor3 = Color3.fromRGB(240, 240, 245)
Select.TextSize = 14
Select.Font = Enum.Font.GothamMedium
Select.TextXAlignment = Enum.TextXAlignment.Left
Select.Parent = Main

local SelectCorner = Instance.new("UICorner")
SelectCorner.CornerRadius = UDim.new(0, 8)
SelectCorner.Parent = Select

local SelectStroke = Instance.new("UIStroke")
SelectStroke.Color = Color3.fromRGB(58, 58, 66)
SelectStroke.Parent = Select

local Options = Instance.new("ScrollingFrame")
Options.Position = UDim2.fromOffset(16, 140)
Options.Size = UDim2.new(1, -32, 0, 0)
Options.BackgroundColor3 = Color3.fromRGB(32, 32, 37)
Options.BorderSizePixel = 0
Options.ScrollBarThickness = 3
Options.CanvasSize = UDim2.new(0, 0, 0, #Codes * 34)
Options.Visible = false
Options.ZIndex = 10
Options.Parent = Main

local OptionsCorner = Instance.new("UICorner")
OptionsCorner.CornerRadius = UDim.new(0, 8)
OptionsCorner.Parent = Options

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 2)
Layout.Parent = Options

for _, Code in ipairs(Codes) do
    local Option = Instance.new("TextButton")
    Option.Size = UDim2.new(1, -6, 0, 32)
    Option.BackgroundColor3 = Color3.fromRGB(32, 32, 37)
    Option.BorderSizePixel = 0
    Option.Text = "   " .. Code
    Option.TextColor3 = Color3.fromRGB(225, 225, 230)
    Option.TextSize = 13
    Option.Font = Enum.Font.Gotham
    Option.TextXAlignment = Enum.TextXAlignment.Left
    Option.ZIndex = 11
    Option.Parent = Options

    Option.Activated:Connect(function()
        Selected = Code
        Select.Text = "  " .. Code .. "                              ▼"
        Options.Visible = false
        Options.Size = UDim2.new(1, -32, 0, 0)
    end)
end

Select.Activated:Connect(function()
    Options.Visible = not Options.Visible

    if Options.Visible then
        Options.Size = UDim2.new(1, -32, 0, 132)
    else
        Options.Size = UDim2.new(1, -32, 0, 0)
    end
end)

local Claim = Instance.new("TextButton")
Claim.Position = UDim2.fromOffset(16, 153)
Claim.Size = UDim2.new(1, -32, 0, 39)
Claim.BackgroundColor3 = Color3.fromRGB(67, 105, 83)
Claim.Text = "Reclamar código"
Claim.TextColor3 = Color3.fromRGB(255, 255, 255)
Claim.TextSize = 14
Claim.Font = Enum.Font.GothamSemibold
Claim.Parent = Main

local ClaimCorner = Instance.new("UICorner")
ClaimCorner.CornerRadius = UDim.new(0, 8)
ClaimCorner.Parent = Claim

local Status = Instance.new("TextLabel")
Status.Position = UDim2.fromOffset(16, 202)
Status.Size = UDim2.new(1, -32, 0, 30)
Status.BackgroundTransparency = 1
Status.Text = "Listo para reclamar"
Status.TextColor3 = Color3.fromRGB(160, 160, 170)
Status.TextSize = 11
Status.Font = Enum.Font.Gotham
Status.TextWrapped = true
Status.Parent = Main

Claim.Activated:Connect(function()
    if Busy then
        return
    end

    Busy = true
    Claim.Text = "Reclamando..."
    Status.Text = "GGs código..."

    local Ok, Result = pcall(function()
        return Remote:InvokeServer(Selected)
    end)

    if Ok then
        Status.Text = "CodigoEnviado " .. Selected
    else
        Status.Text = "Nosepudoreclamar"
        warn(Result)
    end

    Claim.Text = "Reclamar código"
    Busy = false
end)

Close.Activated:Connect(function()
    Gui:Destroy()
end)

local Dragging = false
local DragStart
local StartPosition
local DragInput

local function UpdatePosition(Input)
    local Delta = Input.Position - DragStart

    Main.Position = UDim2.new(
        StartPosition.X.Scale,
        StartPosition.X.Offset + Delta.X,
        StartPosition.Y.Scale,
        StartPosition.Y.Offset + Delta.Y
    )
end

Header.InputBegan:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton1
        or Input.UserInputType == Enum.UserInputType.Touch then

        Dragging = true
        DragStart = Input.Position
        StartPosition = Main.Position

        Input.Changed:Connect(function()
            if Input.UserInputState == Enum.UserInputState.End then
                Dragging = false
            end
        end)
    end
end)

Header.InputChanged:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseMovement
        or Input.UserInputType == Enum.UserInputType.Touch then
        DragInput = Input
    end
end)

UserInputService.InputChanged:Connect(function(Input)
    if Dragging and (
        Input == DragInput
        or Input.UserInputType == Enum.UserInputType.MouseMovement
    ) then
        UpdatePosition(Input)
    end
end)