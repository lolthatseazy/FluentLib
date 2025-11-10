-- I have no idea who made this but i aint the owner of this script

local DesyncLib = {
	ServerPos = CFrame.new(0,0,0)
	Enabled = false,
}

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local Character = Player.Character
local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")
local Head = Character and Character:FindFirstChild("Head")

local Desync = {
	Real = {},
	Fake = { CFrame = CFrame.new() },
	Sent = CFrame.new()
}

if RootPart and DesyncLib.Enabled then
	Desync.Fake.CFrame = RootPart.CFrame
	Desync.Fake.Velocity = RootPart.Velocity
	Desync.Fake.RotVelocity = RootPart.RotVelocity
elseif RootPart then
	RootPart.CFrame = Desync.Real.CFrame or RootPart.CFrame
	RootPart.Velocity = Desync.Real.Velocity or Vector3.zero
	RootPart.RotVelocity = Desync.Real.RotVelocity or Vector3.zero
end

RunService:BindToRenderStep("Desync", Enum.RenderPriority.First.Value, function()
	if not DesyncLib.Enabled or not RootPart or not Head then return end

	if Desync.Sent.Position ~= RootPart.Position then
		Desync.Real.CFrame = RootPart.CFrame
	end

	RootPart.CFrame = Desync.Real.CFrame or RootPart.CFrame
	RootPart.Velocity = Desync.Real.Velocity or RootPart.Velocity
	RootPart.RotVelocity = Desync.Real.RotVelocity or RootPart.RotVelocity
	
	Desync.Fake.CFrame = DesyncLib.ServerPos -- UPDATES HERE
end)

RunService.Heartbeat:Connect(function()
	Character = Player.Character
	RootPart = Character and Character:FindFirstChild("HumanoidRootPart")
	Head = Character and Character:FindFirstChild("Head")
	if not RootPart then return end

	Desync.Real.CFrame = RootPart.CFrame
	Desync.Real.Velocity = RootPart.Velocity
	Desync.Real.RotVelocity = RootPart.RotVelocity

	if DesyncLib.Enabled then
		RootPart.CFrame = Desync.Fake.CFrame or RootPart.CFrame
		RootPart.Velocity = Desync.Fake.Velocity or RootPart.Velocity
		RootPart.RotVelocity = Desync.Fake.RotVelocity or RootPart.RotVelocity

		Desync.Sent = RootPart.CFrame
	end
end)

function DesyncLib:SetServerPos(Position)
	if not Position then
		return false, "No pos"
	end
	
	if typeof(Position) == "Vector3" then
		Position = CFrame.new(Position)
	end
	
	DesyncLib.ServerPos = Position
	
	return true, "Success"
end

function DesyncLib:Set(Value)
	if typeof(Value) ~= "boolean" then
		Value = false
	end
	
	DesyncLib.Enabled = Value
end

return DesyncLib
