AddCSLuaFile()

if CLIENT then
    include("client/cl_sway.lua")
    CreateClientConVar("cl_sws_enable_vignette", "1", true, false)
end

if SERVER then
    AddCSLuaFile("client/cl_sway.lua")
    CreateConVar("sv_sws_maxbreath", '10', {FCVAR_ARCHIVE, FCVAR_REPLICATED} , "", 1, 100 )
end

hook.Add("PopulateToolMenu", "SwaySettingsMenu", function()
    spawnmenu.AddToolMenuOption("Options", "Simple Weapon Sway", "Sway Settings", "Settings", "", "", function(panel)
        local isAdmin = LocalPlayer():IsAdmin()
        panel:CheckBox("Enable Vignette Effect", "cl_sws_enable_vignette")
        if isAdmin then
            local maxBreathSlider = panel:NumSlider("Max Breath time", "sv_sws_maxbreath", 1, 100, 0)
            maxBreathSlider:SetDecimals(0)
        end
    end)
end)