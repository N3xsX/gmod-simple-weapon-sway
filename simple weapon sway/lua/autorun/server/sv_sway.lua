util.AddNetworkString("SWSHurtTimer")
util.AddNetworkString("SWSResetTimers")

hook.Add("EntityTakeDamage", "SWSTrackPlayerDamage", function(victim, dmginfo)
    if victim:IsPlayer() then
        local damage = dmginfo:GetDamage()
        
        net.Start("SWSHurtTimer")
        net.WriteFloat(damage / 2)
        net.Send(victim)
    end
end)

hook.Add("PlayerDeath", "SWSResetTimersOnDeath", function(victim, inflictor, attacker)
    if victim:IsPlayer() then
        net.Start("SWSResetTimers")
        net.Send(victim)
    end
end)