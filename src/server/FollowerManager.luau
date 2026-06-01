local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local FollowerManager = {}
local playerFollowers = {}

local MAX_FOLLOWERS = 3
local SCALE = 0.5
local MOVE_SPEED = 12
local TICK = 0.1
local HIP_HEIGHT = 2.0 * SCALE  -- 1.0: bottom of HRP sits 1 stud above floor

local SKIN  = Color3.fromRGB(255, 220, 185)
local SHIRT = Color3.fromRGB(0, 120, 220)
local PANTS = Color3.fromRGB(30, 50, 110)

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

local function buildR6(spawnCF)
    local S = SCALE
    local model = Instance.new("Model")
    model.Name = "UnitFollower"

    local hrp = makePart(model, "HumanoidRootPart", Vector3.new(2*S, 2*S, S), Color3.new(1,1,1), false)
    hrp.Transparency = 1
    hrp.Anchored = false
    hrp.CFrame = spawnCF
    model.PrimaryPart = hrp

    local humanoid = Instance.new("Humanoid")
    humanoid.WalkSpeed = MOVE_SPEED
    humanoid.JumpPower = 0
    humanoid.HipHeight = HIP_HEIGHT
    humanoid.MaxHealth = math.huge
    humanoid.Health = math.huge
    humanoid.Parent = model

    local animator = Instance.new("Animator")
    animator.Parent = humanoid

    local torso    = makePart(model, "Torso",     Vector3.new(2*S, 2*S, S),   SHIRT, true)
    local head     = makePart(model, "Head",      Vector3.new(2*S, S,   S),   SKIN,  false)
    local leftArm  = makePart(model, "Left Arm",  Vector3.new(S,   2*S, S),   SKIN,  false)
    local rightArm = makePart(model, "Right Arm", Vector3.new(S,   2*S, S),   SKIN,  false)
    local leftLeg  = makePart(model, "Left Leg",  Vector3.new(S,   2*S, S),   PANTS, true)
    local rightLeg = makePart(model, "Right Leg", Vector3.new(S,   2*S, S),   PANTS, true)

    makeMotor(hrp,   "RootJoint",      hrp,   torso,
        CFrame.new(0, -S, 0, -1,0,0, 0,0,1, 0,1,0),
        CFrame.new(0, -S, 0, -1,0,0, 0,0,1, 0,1,0))

    makeMotor(torso, "Neck",           torso, head,
        CFrame.new(0, S, 0, -1,0,0, 0,0,1, 0,1,0),
        CFrame.new(0, -0.5*S, 0, -1,0,0, 0,0,1, 0,1,0))

    makeMotor(torso, "Right Shoulder", torso, rightArm,
        CFrame.new(S, 0.5*S, 0, 0,0,1, 0,1,0, -1,0,0),
        CFrame.new(-0.5*S, 0.5*S, 0, 0,0,1, 0,1,0, -1,0,0))

    makeMotor(torso, "Left Shoulder",  torso, leftArm,
        CFrame.new(-S, 0.5*S, 0, 0,0,-1, 0,1,0, 1,0,0),
        CFrame.new(0.5*S, 0.5*S, 0, 0,0,-1, 0,1,0, 1,0,0))

    makeMotor(torso, "Right Hip",      torso, rightLeg,
        CFrame.new(S, -S, 0, 0,0,1, 0,1,0, -1,0,0),
        CFrame.new(0.5*S, S, 0, 0,0,1, 0,1,0, -1,0,0))

    makeMotor(torso, "Left Hip",       torso, leftLeg,
        CFrame.new(-S, -S, 0, 0,0,-1, 0,1,0, 1,0,0),
        CFrame.new(-0.5*S, S, 0, 0,0,-1, 0,1,0, 1,0,0))

    return model, humanoid, animator
end

local function loadTrack(animator, id, looped)
    local anim = Instance.new("Animation")
    anim.AnimationId = id
    local track = animator:LoadAnimation(anim)
    track.Looped = looped
    return track
end

function FollowerManager.SpawnFollower(player)
    local character = player.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if not playerFollowers[player.UserId] then
        playerFollowers[player.UserId] = {}
    end
    local followers = playerFollowers[player.UserId]
    if #followers >= MAX_FOLLOWERS then return end

    local slot = #followers + 1
    local sideOffset = SLOT_OFFSETS[slot] or 0

    local spawnCF = hrp.CFrame * CFrame.new(sideOffset, 0, 3)

    local follower, fHumanoid, fAnimator = buildR6(spawnCF)
    follower.Parent = Workspace
    table.insert(followers, follower)

    task.defer(function()
        if not follower.Parent then return end

        local moveParams = RaycastParams.new()
        moveParams.FilterType = Enum.RaycastFilterType.Exclude
        moveParams.FilterDescendantsInstances = {character, follower}

        local walkTrack = loadTrack(fAnimator, ANIM_WALK, true)
        local idleTrack = loadTrack(fAnimator, ANIM_IDLE, true)
        idleTrack:Play()
        local isWalking = false

        while follower.Parent and player:IsDescendantOf(game) do
            local char = player.Character
            if char then
                local charHRP = char:FindFirstChild("HumanoidRootPart")
                if charHRP then
                    local fHRP = follower.PrimaryPart
                    if fHRP then
                        local targetCF = charHRP.CFrame * CFrame.new(sideOffset, 0, 2.5)
                        local tx, tz = targetCF.Position.X, targetCF.Position.Z

                        local gr = Workspace:Raycast(
                            Vector3.new(tx, charHRP.Position.Y + 10, tz),
                            Vector3.new(0, -60, 0),
                            moveParams
                        )
                        local groundY = gr and gr.Position.Y or fHRP.Position.Y
                        fHumanoid:MoveTo(Vector3.new(tx, groundY + HIP_HEIGHT, tz))

                        local xzDist = Vector3.new(tx - fHRP.Position.X, 0, tz - fHRP.Position.Z).Magnitude
                        local moving = xzDist > 1
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
    if not followers then return end
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
