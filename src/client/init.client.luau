local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("GachaRemotes")
local summonResult = remotes:WaitForChild("SummonResult")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SummonHubUI"
screenGui.Parent = playerGui

local messageLabel = Instance.new("TextLabel")
messageLabel.Size = UDim2.fromOffset(380, 80)
messageLabel.Position = UDim2.new(0.5, -190, 0.05, 0)
messageLabel.BackgroundTransparency = 0.4
messageLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
messageLabel.BorderSizePixel = 0
messageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
messageLabel.TextStrokeTransparency = 0.5
messageLabel.TextScaled = true
messageLabel.Font = Enum.Font.GothamMedium
messageLabel.Text = "Use the button to summon your next anime character!"
messageLabel.Parent = screenGui
messageLabel.Visible = false

local summonButton = Instance.new("TextButton")
summonButton.Name = "SummonButton"
summonButton.Size = UDim2.fromOffset(170, 52)
summonButton.Position = UDim2.new(0.5, -85, 0.88, 0)
summonButton.AnchorPoint = Vector2.new(0.5, 0)
summonButton.BackgroundColor3 = Color3.fromRGB(45, 110, 220)
summonButton.BorderSizePixel = 0
summonButton.TextColor3 = Color3.fromRGB(255, 255, 255)
summonButton.Font = Enum.Font.GothamBold
summonButton.TextScaled = true
summonButton.Text = "Summon"
summonButton.Parent = screenGui

local function showMessage(text)
	messageLabel.Text = text
	messageLabel.Visible = true
	delay(4, function()
		if messageLabel and messageLabel.Parent then
			messageLabel.Visible = false
		end
	end)
end

local summonRequest = remotes:WaitForChild("SummonRequest")

summonButton.MouseButton1Click:Connect(function()
	summonButton.Active = false
	summonButton.Text = "Summoning..."
	local success, result = pcall(function()
		return summonRequest:InvokeServer()
	end)

	if success and result then
		showMessage("Summoned: " .. result.DisplayName)
	else
		showMessage("Summon failed. Try again.")
	end

	summonButton.Text = "Summon"
	summonButton.Active = true
end)

summonResult.OnClientEvent:Connect(function(result)
	if result then
		showMessage("Fountain summoned: " .. result.DisplayName)
	end
end)
