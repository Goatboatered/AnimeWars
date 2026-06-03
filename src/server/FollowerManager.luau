local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local FollowerManager = {}
local playerFollowers = {}

local MAX_FOLLOWERS = 3
local SCALE = 0.5
local MOVE_SPEED = 12
local TICK = 0.1
local HIP_HEIGHT = 0.3 -- Minimal offset above ground surface

local SKIN  = Color3.fromRGB(255, 220, 185)
local SHIRT = Color3.fromRGB(0, 120, 220)
local PANTS = Color3.fromRGB(30, 50, 110)

local SHIRT_COLORS = {
	Water = Color3.fromRGB(40,  120, 220),
	Fire  = Color3.fromRGB(210,  55,  40),
	Wind  = Color3.fromRGB(220, 185,  40),
}

local SLOT_OFFSETS = { -2, 0, 2 }

local ANIM_WALK = "rbxassetid://180426354"
local ANIM_IDLE = "rbxassetid://180435571"

local function makePart(model, name, size, color, canCollide)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.CanCollide = canCollide == true
	p.Parent = model
	return p
end

local function makeMotor(parent, name, p0, p1, c0, c1)
	local m = Instance.new("Motor6D")
	m.Name = name
	m.Part0 = p0
	m.Part1 = p1
	m.C0 = c0
	m.C1 = c1
	m.Parent = parent
end

local function buildR6(spawnCF, shirtColor)
	local S = SCALE
	local model = Instance.new("Model")
	model.Name = "UnitFollower"

	local hrp = makePart(model, "HumanoidRootPart", Vector3.new(2 * S, 2 * S, S), Color3.new(1, 1, 1), false)
	hrp.Transparency = 1
	hrp.Anchored = false
	hrp.CFrame = spawnCF
	model.PrimaryPart = hrp

	local humanoid = Instance.new("Humanoid")
	humanoid.WalkSpeed = MOVE_SPEED
	humanoid.JumpPower = 25
	humanoid.HipHeight = 0.1
	humanoid.MaxHealth = math.huge
	humanoid.Health = math.huge
	humanoid.Parent = model

	local animator = Instance.new("Animator")
	animator.Parent = humanoid

	local torso = makePart(model, "Torso", Vector3.new(2 * S, 2 * S, S), shirtColor or SHIRT, true)
	local head = makePart(model, "Head", Vector3.new(2 * S, S, S), SKIN, false)
	local leftArm = makePart(model, "Left Arm", Vector3.new(S, 2 * S, S), SKIN, false)
	local rightArm = makePart(model, "Right Arm", Vector3.new(S, 2 * S, S), SKIN, false)
	local leftLeg = makePart(model, "Left Leg", Vector3.new(S, 2 * S, S), PANTS, true)
	local rightLeg = makePart(model, "Right Leg", Vector3.new(S, 2 * S, S), PANTS, true)

	makeMotor(
		hrp,
		"RootJoint",
		hrp,
		torso,
		CFrame.new(0, -S, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0),
		CFrame.new(0, -S, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0)
	)

	makeMotor(
		torso,
		"Neck",
		torso,
		head,
		CFrame.new(0, S, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0),
		CFrame.new(0, -0.5 * S, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0)
	)

	makeMotor(
		torso,
		"Right Shoulder",
		torso,
		rightArm,
		CFrame.new(S, 0.5 * S, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0),
		CFrame.new(-0.5 * S, 0.5 * S, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0)
	)

	makeMotor(
		torso,
		"Left Shoulder",
		torso,
		leftArm,
		CFrame.new(-S, 0.5 * S, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0),
		CFrame.new(0.5 * S, 0.5 * S, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0)
	)

	makeMotor(
		torso,
		"Right Hip",
		torso,
		rightLeg,
		CFrame.new(S, -S, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0),
		CFrame.new(0.5 * S, S, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0)
	)

	makeMotor(
		torso,
		"Left Hip",
		torso,
		leftLeg,
		CFrame.new(-S, -S, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0),
		CFrame.new(-0.5 * S, S, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0)
	)

	return model, humanoid, animator
end

local function loadTrack(animator, id, looped)
	local anim = Instance.new("Animation")
	anim.AnimationId = id
	local track = animator:LoadAnimation(anim)
	track.Looped = looped
	return track
end

function FollowerManager.SpawnFollower(player, unitType)
	local character = player.Character
	if not character then
		return
	end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	if not playerFollowers[player.UserId] then
		playerFollowers[player.UserId] = {}
	end
	local followers = playerFollowers[player.UserId]
	if #followers >= MAX_FOLLOWERS then
		return
	end

	local slot = #followers + 1
	local sideOffset = SLOT_OFFSETS[slot] or 0

	-- Calculate spawn position relative to player
	local spawnHorizontal = hrp.CFrame * CFrame.new(sideOffset, 0, 3)
	local sx, sz = spawnHorizontal.Position.X, spawnHorizontal.Position.Z

	-- Raycast to find ground at spawn location
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { character }

	local rayOrigin = Vector3.new(sx, 100, sz)
	local rayResult = Workspace:Raycast(rayOrigin, Vector3.new(0, -200, 0), rayParams)
	local spawnY = rayResult and rayResult.Position.Y or 0

	-- Spawn on ground
	local spawnCF = CFrame.new(sx, spawnY, sz)

	local follower, fHumanoid, fAnimator = buildR6(spawnCF, SHIRT_COLORS[unitType])
	follower.Parent = Workspace
	table.insert(followers, follower)

	task.defer(function()
		if not follower.Parent then
			return
		end

		local moveParams = RaycastParams.new()
		moveParams.FilterType = Enum.RaycastFilterType.Exclude
		moveParams.FilterDescendantsInstances = { character }

		local walkTrack = loadTrack(fAnimator, ANIM_WALK, true)
		local idleTrack = loadTrack(fAnimator, ANIM_IDLE, true)
		idleTrack:Play()
		local isWalking = false
		local lastJumpTime = 0
		local JUMP_COOLDOWN = 0.3

		-- Listen for player jumping to make follower jump too
		local playerHumanoid = character:FindFirstChild("Humanoid")
		if playerHumanoid then
			playerHumanoid.StateChanged:Connect(function(oldState, newState)
				if newState == Enum.HumanoidStateType.Jumping and follower.Parent then
					local currentTime = tick()
					if (currentTime - lastJumpTime) >= JUMP_COOLDOWN then
						fHumanoid.Jump = true
						lastJumpTime = currentTime
					end
				end
			end)
		end

		while follower.Parent and player:IsDescendantOf(game) do
			local char = player.Character
			if char then
				local charHRP = char:FindFirstChild("HumanoidRootPart")
				if charHRP then
					local fHRP = follower.PrimaryPart
					if fHRP then
						-- Calculate target position relative to player
						local targetHorizontal = charHRP.CFrame * CFrame.new(sideOffset, 0, 2.5)
						local tx, tz = targetHorizontal.Position.X, targetHorizontal.Position.Z

						-- Check if close enough to target
						local xzDist = Vector3.new(tx - fHRP.Position.X, 0, tz - fHRP.Position.Z).Magnitude
						local moving = xzDist > 1.5

						-- Raycast from high above to find actual ground
						local rayOrigin = Vector3.new(tx, 100, tz)
						local rayDirection = Vector3.new(0, -200, 0)
						local rayResult = Workspace:Raycast(rayOrigin, rayDirection, moveParams)

						-- Use ground level if found, otherwise use current Y
						local groundY = rayResult and rayResult.Position.Y or fHRP.Position.Y

						-- Move to target position on ground
						fHumanoid:MoveTo(Vector3.new(tx, groundY, tz))

						-- Only try to climb if actively moving toward player and there's a significant height difference
						local heightDiff = groundY - fHRP.Position.Y
						local currentTime = tick()
						if moving and heightDiff > 0.8 and (currentTime - lastJumpTime) >= JUMP_COOLDOWN then
							fHumanoid.Jump = true
							lastJumpTime = currentTime
						end

						-- Switch between walk and idle animations
						if moving and not isWalking then
							idleTrack:Stop()
							walkTrack:Play()
							isWalking = true
						elseif not moving and isWalking then
							walkTrack:Stop()
							idleTrack:Play()
							isWalking = false
						end
					end
				end
			end
			task.wait(TICK)
		end

		walkTrack:Stop()
		idleTrack:Stop()
	end)
end

function FollowerManager.ClearFollowers(player)
	local followers = playerFollowers[player.UserId]
	if not followers then
		return
	end
	for _, f in ipairs(followers) do
		if f and f.Parent then
			f:Destroy()
		end
	end
	playerFollowers[player.UserId] = nil
end

Players.PlayerRemoving:Connect(function(player)
	FollowerManager.ClearFollowers(player)
end)

return FollowerManager
