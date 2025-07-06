local InvisLib = {}


local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Ping = game:GetService("Stats").PerformanceStats.Ping

local RagdollEvent = ReplicatedStorage:WaitForChild("FE"):WaitForChild("Ragdoll", 9e9)
local ToggleRagdoll = ReplicatedStorage.FE:WaitForChild("ToggleRagdoll", 9e9)

_G.Invisibility = false

function InvisLib:TurnOn()
	if _G.Invisibility then
		return warn("[ERROR] Invisibility cannot be turned on twice.")
	end

	if not LocalPlayer.Character then
		return warn("[ERROR] No character found!")
	end

	local Character = LocalPlayer.Character
	local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")

	local HumanoidRootPart = Character.PrimaryPart

	local OldCFrame = HumanoidRootPart.CFrame

	HumanoidRootPart.CFrame *= CFrame.new(0, 1e7, 0)

	Humanoid.PlatformStand = true

	task.wait(Ping:GetValue()/1000 + 0.1)

	local OldFunc

	for i,v in pairs(getconnections(RagdollEvent.OnClientEvent)) do
		if v.Function then
			OldFunc = clonefunction(v.Function)
			hookfunction(v.Function, function() end)
		end
	end

	local Response = ToggleRagdoll:InvokeServer()

	if Response ~= "Success" then
		local InvisStart = tick()
		
		while true do
			Response = ToggleRagdoll:InvokeServer()
			if Response == "Success" or tick() - InvisStart > 3 then
				break
			end
		end
		
		if tick() - InvisStart > 3 then
			HumanoidRootPart.CFrame = OldCFrame

			return false, "Timeout"
		end
	end

	while not Character:FindFirstChild("RAGDOLLED") do
		task.wait()
	end

	local Mark = Character.RAGDOLLED
	Mark.Name = "InvisMark"

	task.spawn(function()
		while Mark and Mark:IsDescendantOf(workspace) and Character do
			task.wait()
		end

		_G.Invisibility = false
	end)

	for _,v in pairs(Character:GetDescendants()) do
		if v:IsA("Motor6D") then
			v.Part1 = v.Parent
		end
	end

	task.wait()

	for i,v in pairs(getconnections(RagdollEvent.OnClientEvent)) do
		if v.Function then
			hookfunction(v.Function, OldFunc)
		end
	end

	task.wait(0.5)
	HumanoidRootPart.CFrame = OldCFrame
	Humanoid.PlatformStand = false

	for _, BasePart in ipairs(Character:GetChildren()) do
		if BasePart:IsA("BasePart") and BasePart.Transparency == 0 then
			BasePart.Transparency = 0.6
		end
	end

	_G.Invisibility = true

	return true, "Success"
end

function InvisLib:TurnOff()
	if not _G.Invisibility then
		return warn("[ERROR] Invisibility cannot be turned off while already off")
	end

	if not LocalPlayer.Character then
		return warn("[ERROR] No character found!")
	end

	local Character = LocalPlayer.Character
	local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")

	local HumanoidRootPart = Character.PrimaryPart

	if Character:FindFirstChild("InvisMark") then
		local Response = ToggleRagdoll:InvokeServer()

		if Response ~= "Success" then
			while true do
				Response = ToggleRagdoll:InvokeServer()
				if Response == "Success" then
					break
				end
			end
		end

		for _, BasePart in ipairs(Character:GetChildren()) do
			if BasePart:IsA("BasePart") and BasePart.Transparency >= 0.51 and BasePart.Transparency <= 0.8 then
				BasePart.Transparency = 0
			end
		end

		_G.Invisibility = false

		return true, "Success"
	else
		return false, "Not invisible?"
	end
end

return InvisLib
