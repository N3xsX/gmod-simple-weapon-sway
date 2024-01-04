local breathInSound = Sound("breathin.mp3")
local breathOutSound = Sound("breathout.mp3")

local swayAmount = GetConVar("sws_swayamount"):GetFloat()
local randomSwaySpeed = GetConVar("sws_swayspeed"):GetFloat()
local swayPitch, swayYaw = 0, 0
local breathSwayAmount = GetConVar("sws_breathswayamount"):GetFloat()
local breathSwaySpeed = GetConVar("sws_breathswayspeed"):GetFloat()

local breathTime = 10
local maxBreathTime = GetConVar("sws_maxbreath"):GetInt()
local breathTimer = breathTime
local crouchingSwayAmount
local movementSwayAmount
local lastHealth = 0
local lastDamageTime = 0
local damageCooldown = GetConVar("sws_damagecooldown"):GetInt()

local function UpdateConvars()
    swayAmount = GetConVar("sws_swayamount"):GetFloat()
    randomSwaySpeed = GetConVar("sws_swayspeed"):GetFloat()
    maxBreathTime = GetConVar("sws_maxbreath"):GetInt()
    breathSwayAmount = GetConVar("sws_breathswayamount"):GetFloat()
    randomSwaySpeed = GetConVar("sws_breathswayspeed"):GetFloat()
    damageCooldown = GetConVar("sws_damagecooldown"):GetInt()
    print("[SWS] ConVars Updated")
end

concommand.Add("sws_update_convars", UpdateConvars)

local function HasTakenDamage()
    local player = LocalPlayer()

    if IsValid(player) and player:Health() < lastHealth then
        lastHealth = player:Health()

        lastDamageTime = CurTime()

        return true
    end

    return CurTime() - lastDamageTime <= damageCooldown
end

hook.Add( "Think", "ControlSway", function()
	if LocalPlayer():GetVelocity():Length() > 100 then movementSwayAmount = 1.6 else movementSwayAmount = 1 end
    if LocalPlayer():KeyDown(IN_DUCK) then crouchingSwayAmount = 0.4 else crouchingSwayAmount = 1 end
    if not LocalPlayer():KeyDown(IN_SPEED) and breathTimer <= maxBreathTime then breathTimer = math.max(0, breathTimer + FrameTime()) end

    /*if LocalPlayer():KeyDown(IN_SPEED) and not LocalPlayer():KeyDownLast(IN_SPEED) and LocalPlayer():KeyDown(IN_ATTACK2) then
        surface.PlaySound(breathInSound)
    end

    if LocalPlayer():KeyDownLast(IN_SPEED) and not LocalPlayer():KeyDown(IN_SPEED) and LocalPlayer():KeyDown(IN_ATTACK2) or breathTime == 0 then
        surface.PlaySound(breathOutSound)
    end*/
end )

hook.Add("CreateMove", "WeaponSway", function(cmd)

    if not LocalPlayer():KeyDown(IN_ATTACK2) or LocalPlayer():GetMoveType() == MOVETYPE_NOCLIP or LocalPlayer():InVehicle() then
        return
    end

    if not HasTakenDamage() then
        lastHealth = LocalPlayer():Health()
        return
    end

    local weapon = LocalPlayer():GetActiveWeapon()

    if IsValid(weapon) and (string.sub(weapon:GetClass(), 1, 3) == "mg_" or string.sub(weapon:GetClass(), 1, 3) == "cw_" or string.sub(weapon:GetClass(), 1, 4) == "tfa_" or string.sub(weapon:GetClass(), 1, 7) == "weapon_" or string.sub(weapon:GetClass(), 1, 5) == "arc9_")  then
        local randomPitch = math.Rand(-swayAmount, swayAmount)
        local randomYaw = math.Rand(-swayAmount, swayAmount)

        swayPitch = math.Approach(swayPitch, randomPitch, randomSwaySpeed * FrameTime())
        swayYaw = math.Approach(swayYaw, randomYaw, randomSwaySpeed * FrameTime())

        if LocalPlayer():KeyDown(IN_SPEED) and LocalPlayer():KeyDown(IN_ATTACK2) then
            if breathTimer > 0 then
                swayPitch, swayYaw = swayPitch * 0.8, swayYaw * 0.8
            end
        end

        cmd:SetViewAngles(Angle(cmd:GetViewAngles().pitch + crouchingSwayAmount * swayPitch * movementSwayAmount, cmd:GetViewAngles().yaw + crouchingSwayAmount * swayYaw, cmd:GetViewAngles().roll))

        swayPitch, swayYaw = swayPitch, swayYaw
    end
end)

local testbreathTimer = 0

local function CalculateBreathingSway()
    local breathCycle = (math.sin(CurTime() * breathSwaySpeed) + 1) / 2

    local inhaleExhaleCycle = math.sin(breathCycle * math.pi)

    return breathSwayAmount * (inhaleExhaleCycle * 2 - 1)
end

hook.Add("CreateMove", "BreathingSway", function(cmd)
    local player = LocalPlayer()

    if not IsValid(player) or not player:Alive() or player:Health() <= 0 then
        return
    end

    local swaySpeed = breathSwaySpeed

    if player:KeyDown(IN_SPEED) then
        swaySpeed = swaySpeed * 0.5
    end

    if player:KeyDown(IN_ATTACK2) and not player:InVehicle() then
        testbreathTimer = testbreathTimer + FrameTime()

        local weapon = player:GetActiveWeapon()

        if IsValid(weapon) and (string.sub(weapon:GetClass(), 1, 3) == "mg_" or string.sub(weapon:GetClass(), 1, 3) == "cw_" or string.sub(weapon:GetClass(), 1, 4) == "tfa_" or string.sub(weapon:GetClass(), 1, 7) == "weapon_" or string.sub(weapon:GetClass(), 1, 5) == "arc9_") then
            local randomYaw = math.Rand(-breathSwayAmount, breathSwayAmount)
            local swayYaw = math.Approach(0, randomYaw, swaySpeed * FrameTime())

            local swayPitch = CalculateBreathingSway()

            if player:KeyDown(IN_SPEED) then
                if breathTimer > 0 then
                    breathTimer = math.max(0, breathTimer - FrameTime())
                    swayPitch, swayYaw = swayPitch * 0.2, swayYaw * 0.2
                end
            end

            cmd:SetViewAngles(Angle(cmd:GetViewAngles().pitch - swayPitch * crouchingSwayAmount * movementSwayAmount, cmd:GetViewAngles().yaw + swayYaw * crouchingSwayAmount * movementSwayAmount, cmd:GetViewAngles().roll))
        end
    else
        testbreathTimer = math.max(0, testbreathTimer - FrameTime())
    end
end)