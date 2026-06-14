local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local FollowerManager = {}
local playerFollowers = {}        -- [userId] = array of unit follower models
local playerAvatarFollowers = {}  -- [userId] = player-avatar model

local MAX_FOLLOWERS = 3
local UNIT_SCALE    = 0.75  -- unit followers are 75% normal size
local MOVE_SPEED    = 12
local TICK          = 0.1

local PLAYER_AVATAR_OFFSET = -4  -- side offset for the player's own avatar follower
local SLOT_OFFSETS = { -2, 0, 2 }

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

local ANIM_WALK = "rbxassetid://180426354"
local ANIM_IDLE = "rbxassetid://180435571"

local function loadTrack(animator, id, looped)
	local anim = Instance.new("Animation")
	anim.AnimationId = id
	local track = animator:LoadAnimation(anim)
	track.Looped = looped
	return track
end

-- Builds a noob-style unit avatar with optional body scale.
local function buildUnitAvatar(spawnCF, shirtColor, unitName)
	local desc = Instance.new("HumanoidDescription")
	desc.HeadColor      = NOOB_YELLOW
	desc.TorsoColor     = shirtColor or SHIRT_COLORS.Neutral
	desc.LeftArmColor   = NOOB_YELLOW
	desc.RightArmColor  = NOOB_YELLOW
	desc.LeftLegColor   = NOOB_GREEN
	desc.RightLegColor  = NOOB_GREEN
	desc.BodyHeightScale = UNIT_SCALE
	desc.BodyWidthScale  = UNIT_SCALE
	desc.BodyDepthScale  = UNIT_SCALE
	desc.HeadScale       = UNIT_SCALE

	local ok, model = pcall(Players.CreateHumanoidModelFromDescription, Players, desc, Enum.HumanoidRigType.R6)
	if not ok or not model then
		warn("[FollowerManager] buildUnitAvatar failed:", model)
		return nil, nil, nil
	end

	model.Name = unitName or "UnitFollower"
	local hrp = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
	if not hrp then
		warn("[FollowerManager] unit avatar has no HumanoidRootPart")
		model:Destroy()
		return nil, nil, nil
	end
	model.PrimaryPart = hrp
	model:PivotTo(spawnCF + Vector3.new(0, 3, 0))
	hrp.Anchored = false

	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
		end
	end

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayName        = unitName or "Unit"
		humanoid.WalkSpeed          = MOVE_SPEED
		humanoid.JumpPower          = 25
		humanoid.MaxHealth          = math.huge
		humanoid.Health             = math.huge
	end

	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if humanoid and not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	return model, humanoid, animator
end

-- Builds a follower using the player's actual Roblox avatar appearance.
local function buildPlayerAvatar(player, spawnCF)
	local ok, desc = pcall(function()
		return Players:GetHumanoidDescriptionFromUserId(player.UserId)
	end)
	if not ok or not desc then
		warn("[FollowerManager] Could not fetch avatar description for", player.Name)
		return nil, nil, nil
	end

	local ok2, model = pcall(Players.CreateHumanoidModelFromDescription, Players, desc, Enum.HumanoidRigType.R6)
	if not ok2 or not model then
		warn("[FollowerManager] Could not create player avatar model:", model)
		return nil, nil, nil
	end

	model.Name = player.Name .. "_PlayerFollower"
	local hrp = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
	if not hrp then
		model:Destroy()
		return nil, nil, nil
	end
	model.PrimaryPart = hrp
	model:PivotTo(spawnCF + Vector3.new(0, 3, 0))
	hrp.Anchored = false

	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
		end
	end

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayName = player.DisplayName or player.Name
		humanoid.WalkSpeed   = MOVE_SPEED
		humanoid.JumpPower   = 25
		humanoid.MaxHealth   = math.huge
		humanoid.Health      = math.huge
	end

	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if humanoid and not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	return model, humanoid, animator
end

-- Starts the follow loop for any follower model.
local function startFollowLoop(player, followerModel, fHumanoid, fAnimator, sideOffset)
	task.defer(function()
		if not followerModel.Parent then return end

		local character = player.Character
		if not character then return end

		local moveParams = RaycastParams.new()
		moveParams.FilterType = Enum.RaycastFilterType.Exclude
		moveParams.FilterDescendantsInstances = { character }

		local walkTrack = loadTrack(fAnimator, ANIM_WALK, true)
		local idleTrack = loadTrack(fAnimator, ANIM_IDLE, true)
		idleTrack:Play()
		local isWalking   = false
		local lastJumpTime = 0
		local JUMP_COOLDOWN = 0.3

		local playerHumanoid = character:FindFirstChild("Humanoid")
		if playerHumanoid then
			playerHumanoid.StateChanged:Connect(function(_, newState)
				if newState == Enum.HumanoidStateType.Jumping and followerModel.Parent then
					local now = tick()
					if (now - lastJumpTime) >= JUMP_COOLDOWN then
						fHumanoid.Jump = true
						lastJumpTime = now
					end
				end
			end)
		end

		while followerModel.Parent and player:IsDescendantOf(game) do
			local char = player.Character
			if char then
				local charHRP = char:FindFirstChild("HumanoidRootPart")
				if charHRP then
					local fHRP = followerModel.PrimaryPart
					if fHRP then
						local targetHorizontal = charHRP.CFrame * CFrame.new(sideOffset, 0, 2.5)
						local tx, tz = targetHorizontal.Position.X, targetHorizontal.Position.Z

						local xzDist = Vector3.new(tx - fHRP.Position.X, 0, tz - fHRP.Position.Z).Magnitude
						local moving = xzDist > 1.5

						local rayOrigin    = Vector3.new(tx, 100, tz)
						local rayDirection = Vector3.new(0, -200, 0)
						local rayResult    = Workspace:Raycast(rayOrigin, rayDirection, moveParams)
						local groundY      = rayResult and rayResult.Position.Y or fHRP.Position.Y

						fHumanoid:MoveTo(Vector3.new(tx, groundY, tz))

						local heightDiff = groundY - fHRP.Position.Y
						local now = tick()
						if moving and heightDiff > 0.8 and (now - lastJumpTime) >= JUMP_COOLDOWN then
							fHumanoid.Jump = true
							lastJumpTime = now
						end

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

function FollowerManager.SpawnFollower(player, unitType, displayName, unitId)
	local character = player.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	if not playerFollowers[player.UserId] then
		playerFollowers[player.UserId] = {}
	end
	local followers = playerFollowers[player.UserId]

	-- Deduplicate
	if unitId then
		for _, f in ipairs(followers) do
			if f:GetAttribute("UnitId") == unitId then return end
		end
	end
	if #followers >= MAX_FOLLOWERS then return end

	local slot = #followers + 1
	local sideOffset = SLOT_OFFSETS[slot] or 0

	-- Raycast to find ground at spawn position
	local spawnH   = hrp.CFrame * CFrame.new(sideOffset, 0, 3)
	local sx, sz   = spawnH.Position.X, spawnH.Position.Z
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { character }
	local rayResult = Workspace:Raycast(Vector3.new(sx, 100, sz), Vector3.new(0, -200, 0), rayParams)
	local spawnCF   = CFrame.new(sx, rayResult and rayResult.Position.Y or 0, sz)

	-- Spawn the (small) unit follower
	local shortName = displayName and (displayName:match("^(.-)%s*%[") or displayName) or nil
	local follower, fHumanoid, fAnimator = buildUnitAvatar(spawnCF, SHIRT_COLORS[unitType] or SHIRT_COLORS.Neutral, shortName)
	if not follower then return end
	if unitId then
		follower:SetAttribute("UnitId", unitId)
	end
	follower.Parent = Workspace
	table.insert(followers, follower)
	startFollowLoop(player, follower, fHumanoid, fAnimator, sideOffset)

	-- Spawn the player's own avatar follower on the first display
	if not playerAvatarFollowers[player.UserId] then
		task.spawn(function()
			-- Compute spawn position for player avatar
			local avH = hrp.CFrame * CFrame.new(PLAYER_AVATAR_OFFSET, 0, 3)
			local ax, az = avH.Position.X, avH.Position.Z
			local avRay = Workspace:Raycast(Vector3.new(ax, 100, az), Vector3.new(0, -200, 0), rayParams)
			local avCF  = CFrame.new(ax, avRay and avRay.Position.Y or 0, az)

			local avModel, avHumanoid, avAnimator = buildPlayerAvatar(player, avCF)
			if not avModel then return end
			avModel.Parent = Workspace
			playerAvatarFollowers[player.UserId] = avModel
			startFollowLoop(player, avModel, avHumanoid, avAnimator, PLAYER_AVATAR_OFFSET)
		end)
	end
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
			break
		end
	end

	-- Remove player avatar once all unit followers are gone
	if #followers == 0 then
		local av = playerAvatarFollowers[player.UserId]
		if av and av.Parent then
			av:Destroy()
		end
		playerAvatarFollowers[player.UserId] = nil
	end
end

function FollowerManager.ClearFollowers(player)
	local followers = playerFollowers[player.UserId]
	if followers then
		for _, f in ipairs(followers) do
			if f and f.Parent then
				f:Destroy()
			end
		end
	end
	playerFollowers[player.UserId] = nil

	local av = playerAvatarFollowers[player.UserId]
	if av and av.Parent then
		av:Destroy()
	end
	playerAvatarFollowers[player.UserId] = nil
end

Players.PlayerRemoving:Connect(function(player)
	FollowerManager.ClearFollowers(player)
end)

return FollowerManager
