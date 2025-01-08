local swayPitch = 0
local breathTimer = GetConVar("sv_sws_maxbreath"):GetInt()
local hurtTimer = 0

local randomSwaySpeed = 0.5
local breathSwayAmount = 0.003
local swayAmount = 0.05
local breathSwaySpeed
local crouchingSwayAmount
local movementSwayAmount

local function CalculatePitchSway()
    local breathCycle = (math.sin(CurTime() * breathSwaySpeed) + 1) / 2
    local inhaleExhaleCycle = math.sin(breathCycle * math.pi)
    local randomFactor = math.Rand(-0.02, 0.02)
    return breathSwayAmount * 2 * ((inhaleExhaleCycle * 2 - 1) + randomFactor)
end

local lastSwayDirection = 0
local function CalculateYawSway()
    local breathCycle = (math.sin(CurTime() * breathSwaySpeed) + 1) / 2
    local inhaleExhaleCycle = math.sin(breathCycle * math.pi)
    local targetDirection = math.sin(CurTime() * breathSwaySpeed * 0.5)
    lastSwayDirection = Lerp(0.1, lastSwayDirection, targetDirection)
    local baseSway = breathSwayAmount * 3 * (inhaleExhaleCycle * 2 - 1)
    local randomOffset = math.Rand(-0.01, 0.01)
    return (baseSway * lastSwayDirection) + randomOffset
end

net.Receive("SWSHurtTimer", function()
    local hurtTime = net.ReadFloat()
    hurtTimer = hurtTimer + hurtTime
end)

net.Receive("SWSResetTimers", function()
    breathTimer = GetConVar("sv_sws_maxbreath"):GetInt()
    hurtTimer = 0
end)

hook.Add("CreateMove", "SWSWeaponSway", function(cmd)
    if not IsValid(LocalPlayer()) or not LocalPlayer():Alive() or LocalPlayer():GetMoveType() == MOVETYPE_NOCLIP or LocalPlayer():InVehicle() then return end
    if LocalPlayer():KeyDown(IN_ATTACK2) then
        local velocity = LocalPlayer():GetVelocity():Length()
        local weapon = LocalPlayer():GetActiveWeapon()
        if LocalPlayer():KeyDown(IN_DUCK) then 
            crouchingSwayAmount = 0.4 
        else 
            crouchingSwayAmount = 1 
        end
        if velocity > 100 then
            movementSwayAmount = 2
            if hurtTimer <= 0 then
                breathSwaySpeed = 1
            end
        else
            movementSwayAmount = 1
            if hurtTimer <= 0 then
                breathSwaySpeed = 0.5
            end
        end
        if IsValid(weapon) and (string.sub(weapon:GetClass(), 1, 3) == "mg_" or string.sub(weapon:GetClass(), 1, 3) == "cw_" or string.sub(weapon:GetClass(), 1, 4) == "tfa_" or string.sub(weapon:GetClass(), 1, 7) == "weapon_" or string.sub(weapon:GetClass(), 1, 5) == "arc9_") then
            local randomPitch = math.Rand(-swayAmount, swayAmount)

            swayPitch = math.Approach(swayPitch, randomPitch, randomSwaySpeed * FrameTime()) * 0.5
            
            local swayPitchBreathing = CalculatePitchSway()
            local swayYawBreathing = CalculateYawSway()

            if LocalPlayer():KeyDown(IN_SPEED) and breathTimer > 0 and hurtTimer <= 0 then
                breathTimer = math.max(0, breathTimer - FrameTime() * 0.5)
                swayPitch = swayPitch * 0.1
                swayPitchBreathing = swayPitchBreathing * 0.1
                swayYawBreathing = swayYawBreathing * 0.1
            end

            if hurtTimer > 0 then
                swayPitch = swayPitch * 1.5
                swayPitchBreathing = swayPitchBreathing * 1.5
                swayYawBreathing = swayYawBreathing * 1.5
                if velocity > 100 then
                    breathSwaySpeed = 2.5
                else
                    breathSwaySpeed = 1.5
                end
            end

            cmd:SetViewAngles(Angle(
                cmd:GetViewAngles().pitch - (swayPitch + swayPitchBreathing) * crouchingSwayAmount * movementSwayAmount,
                cmd:GetViewAngles().yaw + swayYawBreathing  * crouchingSwayAmount * movementSwayAmount,
                cmd:GetViewAngles().roll
            ))
        end
    end
end)

local vignette = Material("vignette.png")
local vignetteIntensity = 0
local transitionSpeed = 0.01

hook.Add("RenderScreenspaceEffects", "SWSVignette", function()
    if GetConVar("cl_sws_enable_vignette"):GetBool() == false then return end

    if LocalPlayer():KeyDown(IN_SPEED) and LocalPlayer():KeyDown(IN_ATTACK2) then
        vignetteIntensity = math.Approach(vignetteIntensity, 1 - (breathTimer / (GetConVar("sv_sws_maxbreath"):GetInt() / 2)), 0.01)
    else
        vignetteIntensity = math.Approach(vignetteIntensity, 0, 0.01)
    end

    vignetteIntensity = math.Approach(vignetteIntensity, vignetteIntensity, transitionSpeed)

    render.SetMaterial(vignette)
    vignette:SetFloat("$alpha", vignetteIntensity)
    for i = 1, 2 do
        render.DrawScreenQuad()
    end
end)

timer.Create("SWSBreathTimer", 0.5, 0, function ()
    if not LocalPlayer():KeyDown(IN_SPEED) and breathTimer <= GetConVar("sv_sws_maxbreath"):GetInt() then
        breathTimer = math.min(GetConVar("sv_sws_maxbreath"):GetInt(), breathTimer + 0.2)
    end
end)

timer.Create("SWSHurtTimer", 1, 0, function ()
    if hurtTimer > 0 then
        hurtTimer = math.max(0, hurtTimer - 1)
    end
end)