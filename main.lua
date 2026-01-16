function LowSetting()
    local Lighting = game:GetService("Lighting")
    local Terrain = workspace:FindFirstChildOfClass("Terrain")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    
    print("🚀 Mengaktifkan LowSetting (Environment, Skins, Animation)...")

    -- [BAGIAN 1] Optimasi Environment (Lighting & Terrain)
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    Lighting.Brightness = 0
    
    if Terrain then
        Terrain.WaterWaveSize = 0
        Terrain.WaterWaveSpeed = 0
        Terrain.WaterReflectance = 0
        Terrain.WaterTransparency = 0
    end

    pcall(function()
        settings().Rendering.QualityLevel = "Level01"
    end)

    -- Matikan Efek Post-Processing
    for _, v in pairs(Lighting:GetChildren()) do
        if v:IsA("PostEffect") then v.Enabled = false end
    end

    -- [BAGIAN 2] Optimasi Objek Map (Partikel & Tekstur) - One Time Scan
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and not v:IsA("MeshPart") then
            v.Material = Enum.Material.SmoothPlastic
            v.Reflectance = 0
            v.CastShadow = false
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = 1
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then
            v.Enabled = false
        end
    end

    -- [BAGIAN 3] Disable Skins (Rod & Character) - Saat Ini
    local function clearSkins(parent)
        for _, v in pairs(parent:GetDescendants()) do
            if v:IsA("MeshPart") then v.TextureID = "" 
            elseif v:IsA("Decal") or v:IsA("Texture") then v.Transparency = 1
            elseif v:IsA("SpecialMesh") then v.TextureId = "" end
        end
    end
    
    if LocalPlayer.Character then clearSkins(LocalPlayer.Character) end
    if LocalPlayer.Backpack then clearSkins(LocalPlayer.Backpack) end

    -- [BAGIAN 4] Disable Fishing Animation (Permanen via Connection)
    local Char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local Humanoid = Char:WaitForChild("Humanoid")
    local Animator = Humanoid:WaitForChild("Animator")

    -- Stop animasi yang sedang jalan
    for _, track in ipairs(Animator:GetPlayingAnimationTracks()) do
        local name = track.Animation.Name:lower()
        if name:find("fish") or name:find("rod") or name:find("cast") or name:find("throw") then
            track:Stop()
        end
    end

    -- Cegah animasi baru
    Animator.AnimationPlayed:Connect(function(track)
        local name = track.Animation.Name:lower()
        if name:find("fish") or name:find("rod") or name:find("cast") or name:find("throw") or name:find("reel") then
            track:Stop()
        end
    end)
    
    print("✅ LowSetting Full Applied!")
end
