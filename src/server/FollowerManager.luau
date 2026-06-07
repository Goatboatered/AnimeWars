local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local FollowerManager = {}
local playerFollowers = {}

local MAX_FOLLOWERS = 3
local MOVE_SPEED = 12
local TICK = 0.1

local NOOB_YELLOW = Color3.fromRGB(245, 205, 48)
local NOOB_GREEN  = Color3.fromRGB(75, 151, 75)

local SHIRT_COLORS = {
	Water   = Color3.fromRGB(40, 120, 220),
	Fire    = Color3.fromRGB(210, 55, 40),
	Wind    = Color3.fromRGB(240, 210, 50),
	Light   = Color3.fromRGB(240, 240, 240),
	Dark    = Color3.fromRGB(130, 60, 200),
	Neutral = Color3.fromRGB(120, 120, 130),
}

local SLOT_OFFSETS = { -2, 0, 2 }

local ANIM_WALK = "rbxassetid://180426354"
local ANIM_IDLE = "rbxassetid://180435571"

local function buildAvatar(spawnCF, shirtColor, unitName)
	local desc = Instance.new("HumanoidDescription")
	desc.HeadColor = NOOB_YELLOW
	desc.TorsoColor = shirtColor or SHIRT_COLORS.Neutral
	desc.LeftArmColor = NOOB_YELLOW
	desc.RightArmColor = NOOB_YELLOW
	desc.LeftLegColor = NOOB_GREEN
	desc.RightLegColor = NOOB_GREEN

	local ok, model = pcall(Players.CreateHumanoidModelFromDescription, Players, desc, Enum.HumanoidRigType.R6)
	if not ok or not model then
		warn("[FollowerManager] buildAvatar failed:", model)
		return nil, nil, nil
	end

	model.Name = unitName or "UnitFollower"
	local hrp = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
	if hrp then
		model.PrimaryPart = hrp
		model:PivotTo(spawnCF + Vector3.new(0, 3, 0))
		hrp.Anchored = false
	else
		warn("[FollowerManager] generated avatar has no HumanoidRootPart")
		model:Destroy()
		return nil, nil, nil
	end

	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
		end
	end

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayName = unitName or "UnitFollower"
		humanoid.WalkSpeed = MOVE_SPEED
		humanoid.JumpPower = 25
		humanoid.MaxHealth = math.huge
		humanoid.Health = math.huge
	end

	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if humanoid and not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	return model, humanoid, animator
end

local function loadTrack(animator, id, looped)
	local anim = Instance.new("Animation")
	anim.AnimationId = id
	local track = animator:LoadAnimation(anim)
	track.Looped = looped
	return track
end

function FollowerManager.SpawnFollower(player, unitType, displayName, unitId)
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
	if unitId then
		for _, follower in ipairs(followers) do
			if follower:GetAttribute("UnitId") == unitId then
				return
			end
		end
	end
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

	local shortName = displayName and (displayName:match("^(.-)%s*%[") or displayName) or nil
	local follower, fHumanoid, fAnimator = buildAvatar(spawnCF, SHIRT_COLORS[unitType] or SHIRT_COLORS.Neutral, shortName)
	if not follower or not fHumanoid or not fAnimator then
		return
	end
	if unitId then
		follower:SetAttribute("UnitId", unitId)
	end
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

function FollowerManager.RemoveFollower(player, unitId)
	local followers = playerFollowers[player.UserId]
	if not followers then return end
	for i, f in ipairs(followers) do
		if f:GetAttribute("UnitId") == unitId then
			if f.Parent then
				f:Destroy()
			end
			table.remove(followers, i)
			return
		end
	end
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
