-- Persist scan summaries separately from prices. Observe existing completion
-- notifications; never modify scan queries, timing, processing, or cooldowns.
local function stats()
    if type(AUCTIONATOR_DATABASE_STATS) ~= "table" then AUCTIONATOR_DATABASE_STATS = {} end
    local key = GetRealmName().."_"..UnitFactionGroup("player")
    local root = AUCTIONATOR_DATABASE_STATS
    if type(root[key]) ~= "table" then root[key] = {since = time(), scans = 0, fast = 0, slow = 0} end
    local record=root[key]
    if type(record.durations)~="table" then
        record.durations={}
        -- The previous version retained only its last timing; preserve that
        -- one real sample without inventing timings for older scan totals.
        if type(record.duration)=="number" and record.duration>=0 and record.duration<math.huge then
            record.durations[1]=record.duration
        end
    end
    return record
end

function Atr_GetFullScanCounts()
    local record=stats()
    return tonumber(record.fast) or 0,tonumber(record.slow) or 0
end

local Model=AuctionatorRemastered.Models.DatabaseStats
local function rows()
    if Atr_DatabaseRows then return Atr_DatabaseRows(gAtr_ScanDB) end
    return pairs(type(gAtr_ScanDB)=="table" and gAtr_ScanDB or {})
end
function Atr_GetFullScanMedianDuration()
    return Model.Median(stats().durations)
end
function Atr_GetDatabaseCoverage()
    return Model.Coverage(rows())
end
function Atr_GetDatabaseOverview()
    local iterate,state,seed=rows()
    return Model.Overview(iterate,state,seed,time())
end

local scanStart, scanMode
AuctionatorRemastered.Legacy.Hook("Atr_FullScanStart", function()
    if gAtr_FullScanState ~= ATR_FS_NULL then
        scanStart = time()
        scanMode = (Atr_FullScanSlowMode or IsControlKeyDown()) and "slow" or "fast"
    end
end)
AuctionatorRemastered.Legacy.Hook("Atr_Broadcast_DBupdated", function(num, kind)
    if kind ~= "fullscan" then return end
    local health=Atr_GetDatabaseHealth and Atr_GetDatabaseHealth()
    if health and health.lastScan and not health.lastScan.complete then scanStart,scanMode=nil,nil;return end
    local record = stats()
    record.scans = (record.scans or 0) + 1
    if scanMode then record[scanMode] = (record[scanMode] or 0) + 1 end
    record.last = time()
    record.duration = scanStart and math.max(0, time() - scanStart) or nil
    if record.duration then
        record.durations[#record.durations+1]=record.duration
        while #record.durations>100 do table.remove(record.durations,1) end
    end
    record.items = num
    record.auctions = Atr_FSR_scanned_count and tonumber(Atr_FSR_scanned_count:GetText()) or nil
    scanStart, scanMode = nil, nil
    if Atr_UpdateFullScanCounts then Atr_UpdateFullScanCounts() end
end)

AuctionatorRemastered.Legacy.Hook("Atr_Init", function()
    stats()
    -- Adopt the requested new default once, preserving explicit non-7-day choices.
    if not AUCTIONATOR_DATABASE_STATS.default14Applied then
        if AUCTIONATOR_MARKET_HISTORY_DAYS == nil or tonumber(AUCTIONATOR_MARKET_HISTORY_DAYS) == 7 then
            AUCTIONATOR_MARKET_HISTORY_DAYS = 14
        end
        AUCTIONATOR_DATABASE_STATS.default14Applied = true
    end
end)

-- Count actual search objects, not auction-query pages or retries. Existing
-- scan totals stay intact; search tracking starts with this update.
AuctionatorRemastered.Legacy.Hook("Atr_NewSearch",function()
    local record=stats()
    record.searches=(tonumber(record.searches) or 0)+1
    record.searchesSince=record.searchesSince or time()
end)

AuctionatorRemastered.DatabaseStats={Get=stats}
