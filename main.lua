-- [[ HANSEN HYBRID V2: INDEPENDENT CONFIG PER MODE ]] --

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- [[ 1. KONFIGURASI TERPISAH ]]
local Settings = {
    -- Konfigurasi untuk FAST MODE (Rod ID 257 / Element / Aurora)
    FAST = {
        RodID = 257,           -- ID Rod pemicu mode Fast
        StartDelay = 1.2,     -- Mulai sangat cepat
        AddStep = 0.05,        -- Nambah dikit-dikit biar presisi
        FailThreshold = 2,     -- Gagal 2x baru nambah
        SuccessThreshold = 3,  -- Sukses 3x baru Lock
    },
    
    -- Konfigurasi untuk NORMAL MODE (Rod Biasa / Fivola / King / dll)
    NORMAL = {
        StartDelay = 0.6,      -- Mulai dari angka aman
        AddStep = 0.1,         -- Nambah wajar
        FailThreshold = 2,     -- Gagal 2x baru nambah
        SuccessThreshold = 3,  -- Sukses 3x baru Lock
    }
}

-- [[ 2. VARIABEL STATE ]]
local CurrentMode = "None"     -- "FAST" atau "NORMAL"
local CurrentDelay = 1.0
local ActiveStep = 0.1
local ActiveFailThresh = 2
local ActiveSuccessThresh = 3

local IsLocked = false
local FishReceived = false
local FailStreak = 0
local SuccessStreak = 0

-- [[ 3. SETUP DATA & REMOTE ]]
local Packages = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index")
local Replion = require(ReplicatedStorage.Packages.Replion)
local NetFolder = nil

-- Auto Detect Network Folder
for _, folder in pairs(Packages:GetChildren()) do
    if folder.Name:match("sleitnick_net") then
        NetFolder = folder
        break
    end
end

if not NetFolder then 
    return warn("❌ Script Berhenti: Folder Network tidak ditemukan!") 
end

local Net = NetFolder:WaitForChild("net")
local RF_Cancel = Net:WaitForChild("RF/CancelFishingInputs")
local RF_Charge = Net:WaitForChild("RF/ChargeFishingRod")
local RF_Start  = Net:WaitForChild("RF/RequestFishingMinigameStarted")
local RE_Finish = Net:WaitForChild("RE/FishingCompleted")
local RE_Caught = Net:WaitForChild("RE/ObtainedNewFishNotification")

-- [[ 4. FUNGSI CEK ROD ]]
local function CheckFishingMode()
    local Data = Replion.Client:GetReplion("Data")
    if not Data then return "NORMAL" end 
    
    local EquippedUUID = Data:Get("EquippedId")
    local InventoryRods = Data:Get({"Inventory", "Fishing Rods"})
    
    if EquippedUUID and InventoryRods then
        for _, rod in pairs(InventoryRods) do
            if rod.UUID == EquippedUUID then
                if rod.Id == Settings.FAST.RodID then
                    return "FAST"
                else
                    return "NORMAL"
                end
            end
        end
    end
    return "NORMAL"
end

-- [[ 5. LISTENER (Handler Hadiah) ]]
RE_Caught.OnClientEvent:Connect(function()
    FishReceived = true
    FailStreak = 0 
    
    if not IsLocked then
        SuccessStreak = SuccessStreak + 1
        print("✅ ["..CurrentMode.."] Streak: " .. SuccessStreak .. "/" .. ActiveSuccessThresh .. " (Speed: " .. CurrentDelay .. "s)")
        
        if SuccessStreak >= ActiveSuccessThresh then
            IsLocked = true
            -- Margin tipis untuk Fast, agak tebal untuk Normal
            local margin = (CurrentMode == "FAST") and 0.02 or 0.05
            local FinalDelay = math.floor((CurrentDelay + margin) * 1000)/1000
            print("💎 ["..CurrentMode.."] DELAY LOCKED: " .. FinalDelay .. "s")
            CurrentDelay = FinalDelay
        end
    end
end)

print("🎣 HYBRID V2 AKTIF: Menunggu Rod...")

-- [[ 6. LOOP UTAMA ]]
while true do
    FishReceived = false
    local timex = workspace:GetServerTimeNow()
    
    -- A. DETEKSI MODE & LOAD CONFIG
    local DetectedMode = CheckFishingMode()
    
    if DetectedMode ~= CurrentMode then
        print("🔄 Switching Config: " .. CurrentMode .. " -> " .. DetectedMode)
        CurrentMode = DetectedMode
        
        -- Load Config dari Tabel di atas
        local Cfg = Settings[CurrentMode]
        CurrentDelay = Cfg.StartDelay
        ActiveStep = Cfg.AddStep
        ActiveFailThresh = Cfg.FailThreshold
        ActiveSuccessThresh = Cfg.SuccessThreshold
        
        -- Reset Calibration Counter
        IsLocked = false
        FailStreak = 0
        SuccessStreak = 0
        
        print("⚙️ Loaded " .. CurrentMode .. " Settings: Start="..CurrentDelay.."s | Step="..ActiveStep.."s")
        task.wait(0.2)
    end

    -- B. EKSEKUSI MANCING
    if CurrentMode == "FAST" then
        -- [[ LOGIKA FAST (FIRE & FORGET) ]]
        task.spawn(function()
            pcall(function()
                RF_Cancel:InvokeServer()
                task.wait(0.1) -- Jeda wajib 257
                RF_Charge:InvokeServer(timex)
                RF_Start:InvokeServer(-1.233184814453125, 0.998 + (1.0 - 0.998) * math.random(), timex)
            end)
        end)
    else
        -- [[ LOGIKA NORMAL (WAIT RESPONSE) ]]
        pcall(function() RF_Cancel:InvokeServer() end)
        
        local chargeSuccess = pcall(function() RF_Charge:InvokeServer(timex) end)
        if not chargeSuccess then
            warn("⚠️ Charge Gagal (Normal Mode), Retrying...")
            task.wait(0.5)
            continue
        end
        
        task.wait(0.1)
        
        local startSuccess = pcall(function()
            RF_Start:InvokeServer(-1.233184814453125, 0.998 + (1.0 - 0.998) * math.random(), timex)
        end)
        if not startSuccess then
            warn("⚠️ Start Gagal (Normal Mode), Retrying...")
            task.wait(0.5)
            continue
        end
    end

    -- C. TUNGGU HASIL KALIBRASI
    task.wait(CurrentDelay)

    -- D. FINISH
    pcall(function()
        RE_Finish:FireServer()
    end)
    
    -- E. JEDA VALIDASI
    task.wait(0.4) 

    -- F. LOGIKA KALIBRASI (DINAMIS SESUAI CONFIG)
    if not IsLocked then
        if FishReceived then
            -- Handled by Listener
        else
            if SuccessStreak > 0 then
                warn("⚠️ Streak Putus! Reset ke 0.")
                SuccessStreak = 0 
            end

            FailStreak = FailStreak + 1
            if FailStreak >= ActiveFailThresh then
                CurrentDelay = CurrentDelay + ActiveStep
                FailStreak = 0 
                warn("❌ ["..CurrentMode.."] Gagal "..ActiveFailThresh.."x. Nambah Delay -> " .. math.floor(CurrentDelay*1000)/1000 .. "s")
            else
                warn("⚠️ ["..CurrentMode.."] Gagal ke-"..FailStreak.." (Retrying...)")
            end
        end
    end
end
