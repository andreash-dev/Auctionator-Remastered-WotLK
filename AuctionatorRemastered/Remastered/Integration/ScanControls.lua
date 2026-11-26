-- UI controls only. The Remastered FullScan engine owns queries and processing.
local backup, backupDB, canonicalBackup
local function idle()
    return gAtr_FullScanState == ATR_FS_NULL
end

-- Server readiness normally controls fast scans; an explicit confirmation can
-- attempt one early. The 15-minute timer remains an estimate, not a guarantee.
function Atr_GetFastScanWait()
    if type(AUCTIONATOR_LAST_SCAN_TIME) ~= "number" then return nil end
    local elapsed = time() - AUCTIONATOR_LAST_SCAN_TIME
    if elapsed < 0 then return nil end
    return math.max(0, math.ceil(15 * 60 - elapsed))
end
function Atr_FormatFastScanWait(seconds)
    return string.format("%02dm %02ds", math.floor(seconds / 60), seconds % 60)
end
local function fastReady()
    local _,ready = CanSendAuctionQuery()
    return ready and true or false
end
local function slowSelected()
    return Atr_FullScanSlowMode == true or IsControlKeyDown()
end
local function cooldownDescription()
    local seconds = Atr_GetFastScanWait()
    if not seconds then return "The server has not provided a remaining cooldown time." end
    if seconds == 0 then return "The estimated wait has elapsed, but the server is still blocking fast scans." end
    return "Estimated time remaining: "..Atr_FormatFastScanWait(seconds)
end
local function updateCooldownUI()
    if not idle() then return end
    local ready = fastReady()
    local seconds = Atr_GetFastScanWait()
    local text = ready and "Now" or (seconds and seconds > 0 and
        ("in "..Atr_FormatFastScanWait(seconds).." (estimated)") or "Waiting for server")
    Atr_FullScanNext:SetText(text)
    -- Keep the fast action clickable so it can offer the explicit warning.
    if not slowSelected() then Atr_FullScanStartButton:Enable() end
end
StaticPopupDialogs["ATR_FAST_SCAN_COOLDOWN"] = {
    text = "Fast scan is not ready according to the client.\n\n%s\n\nRunning early may be rejected, stall the scan or disconnect you. Waiting or using Slow scan is recommended.\n\nRun a fast scan anyway?",
    button1 = "Run anyway", button2 = "Cancel",
    OnAccept = function()
        if not idle() or slowSelected() or not Atr_FullScanFrame:IsShown() then return end
        Atr_FullScanFrameIdle()
        Atr_FullScanStart(true)
        updateCooldownUI()
    end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}
Atr_FullScanFrame:HookScript("OnHide",function() StaticPopup_Hide("ATR_FAST_SCAN_COOLDOWN") end)
local startClick = Atr_FullScanStartButton:GetScript("OnClick")
local function guardedStart(self,button)
    if not idle() then return end
    Atr_FullScanFrameIdle() -- Synchronize the existing checkbox/Ctrl mode.
    if not slowSelected() and not fastReady() then
        StaticPopup_Show("ATR_FAST_SCAN_COOLDOWN",cooldownDescription())
        updateCooldownUI()
        return
    end
    -- Refresh the original module's private readiness flag, without querying AH.
    Atr_UpdateFullScanFrame()
    if startClick then startClick(Atr_FullScanStartButton,button) end
    updateCooldownUI()
end
Atr_FullScanStartButton:SetScript("OnClick",guardedStart)
AuctionatorRemastered.Legacy.Hook("Atr_UpdateFullScanFrame",updateCooldownUI)
AuctionatorRemastered.Legacy.Hook("Atr_FullScanFrameIdle",updateCooldownUI)

function Atr_ClearPriceDatabase()
    if not idle() or type(gAtr_ScanDB) ~= "table" then return false end
    backup, backupDB = {}, gAtr_ScanDB
    for name, data in pairs(gAtr_ScanDB) do
        backup[name] = data
        gAtr_ScanDB[name] = nil
    end
    if Atr_DatabaseClearMarket then canonicalBackup=Atr_DatabaseClearMarket()
    elseif Atr_DatabaseSync then Atr_DatabaseSync() end
    -- Keep LAST_SCAN_TIME: clearing local prices must not reset scan cooldowns.
    Atr_UpdateFullScanFrame()
    return true
end

function Atr_UndoClearPriceDatabase()
    if not idle() or not backup or backupDB ~= gAtr_ScanDB then return false end
    -- Preserve any prices acquired since the clear.
    for name, data in pairs(backup) do
        if gAtr_ScanDB[name] == nil then gAtr_ScanDB[name] = data end
    end
    if canonicalBackup and Atr_DatabaseUndoMarket then Atr_DatabaseUndoMarket(canonicalBackup)
    elseif Atr_DatabaseSync then Atr_DatabaseSync() end
    canonicalBackup=nil
    backup, backupDB = nil, nil
    Atr_UpdateFullScanFrame()
    return true
end

StaticPopupDialogs["ATR_CLEAR_PRICE_DATABASE"] = {
    text = "Clear %d saved item prices and their price history for this realm/faction?\n\nShopping lists, selling history and scan cooldowns are kept. Undo is available until logout or reload.",
    button1 = "Clear DB", button2 = "Cancel",
    OnAccept = function() Atr_ClearPriceDatabase() end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}

local slow = CreateFrame("CheckButton", "Atr_SlowScanChoice", Atr_FullScanFrame, "UICheckButtonTemplate")
slow:SetWidth(24); slow:SetHeight(24)
slow:SetPoint("TOPLEFT", Atr_FullScanFrame, "TOPLEFT", 27, -148)
_G[slow:GetName().."Text"]:SetText("Slow scan (page by page)")
slow:SetScript("OnClick", function(self)
    if idle() then
        Atr_FullScanSlowMode = self:GetChecked() and true or false
        Atr_FullScanFrameIdle()
    end
end)
slow:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine("Scan mode")
    GameTooltip:AddLine("Unchecked: existing fast full scan.\nChecked: existing page-by-page scan.\nCtrl also selects slow scan.", 1, 1, 1, true)
    GameTooltip:Show()
end)
slow:SetScript("OnLeave", function() GameTooltip:Hide() end)

local clear = CreateFrame("Button", "Atr_ClearDBButton", Atr_FullScanFrame, "UIPanelButtonTemplate")
clear:SetWidth(100); clear:SetHeight(22)
clear:SetPoint("TOPLEFT", Atr_FullScanFrame, "TOPLEFT", 350, -180)
clear:SetText("Clear DB...")
clear:SetScript("OnClick", function()
    if idle() and type(gAtr_ScanDB) == "table" then
        StaticPopup_Show("ATR_CLEAR_PRICE_DATABASE", Atr_GetDBsize())
    end
end)
local undo = CreateFrame("Button", "Atr_UndoClearDBButton", Atr_FullScanFrame, "UIPanelButtonTemplate")
undo:SetWidth(100); undo:SetHeight(22)
undo:SetPoint("LEFT", clear, "RIGHT", 5, 0)
undo:SetText("Undo clear")
undo:SetScript("OnClick", function() Atr_UndoClearPriceDatabase() end)

local elapsedTotal = 0
local previousReady
Atr_FullScanFrame:HookScript("OnUpdate", function(self, elapsed)
    elapsedTotal = elapsedTotal + elapsed
    if elapsedTotal < 0.2 then return end
    elapsedTotal = 0
    local available = idle()
    if available then slow:Enable(); clear:Enable() else slow:Disable(); clear:Disable() end
    if available and backup and backupDB == gAtr_ScanDB then undo:Enable() else undo:Disable() end
    if available then
        local ready = fastReady()
        if ready ~= previousReady then
            previousReady = ready
            Atr_UpdateFullScanFrame()
            Atr_FullScanFrameIdle()
        end
    end
    updateCooldownUI()
end)

local function scanCountText(name,text,x,y,font)
    local label=Atr_FullScanFrame:CreateFontString(name,"OVERLAY",font)
    label:SetPoint("TOPLEFT",Atr_FullScanFrame,"TOPLEFT",x,y);label:SetText(text)
    return label
end
scanCountText("Atr_FullScanFastCountLabel","Fast scans completed:",20,-104,"GameFontNormal")
scanCountText("Atr_FullScanSlowCountLabel","Slow scans completed:",20,-126,"GameFontNormal")
local fastCount=scanCountText("Atr_FullScanFastCount","0",180,-104,"GameFontHighlight")
local slowCount=scanCountText("Atr_FullScanSlowCount","0",180,-126,"GameFontHighlight")
function Atr_UpdateFullScanCounts()
    local fast,slow=0,0
    if Atr_GetFullScanCounts then fast,slow=Atr_GetFullScanCounts() end
    fastCount:SetText(tostring(fast));slowCount:SetText(tostring(slow))
end

-- The legacy completion UI applies a purple result color after showing it.
-- Restore the shared surface after its final UI update, without changing scans.
local function styleScanResults()
    if Atr_StyleOfflineBrowser then Atr_StyleOfflineBrowser(Atr_FullScanResults,true,false) end
end
AuctionatorRemastered.Legacy.Hook("Atr_UpdateFullScanFrame",function()
    if Atr_FullScanResults:IsShown() then styleScanResults() end
end)

-- Resolve the category on click: status is registered later in the load order.
local databaseStatus=CreateFrame("Button","Atr_FullScanDatabaseStatus",Atr_FullScanFrame,"UIPanelButtonTemplate")
databaseStatus:SetSize(120,22)
databaseStatus:SetPoint("BOTTOMLEFT",Atr_FullScanFrame,"BOTTOMLEFT",20,12)
databaseStatus:SetText("Database status")
databaseStatus:SetScript("OnClick",function()
    if not idle() or not Atr_DatabaseStatusOptions then return end
    Atr_FullScanFrame:Hide()
    InterfaceOptionsFrame_OpenToCategory(Atr_DatabaseStatusOptions)
end)

-- One action row and a separate bottom Close/Done row.
function Atr_StyleFullScanDialog()
    -- These shared styling helpers are loaded after this module. Resolve them
    -- when the dialog opens, without involving the scan engine or its updates.
    if not Atr_StyleOfflineBrowser or not Atr_AnalysisSkin then return end
    Atr_FullScanFrame:ClearAllPoints()
    Atr_FullScanFrame:SetSize(500,410)
    Atr_FullScanFrame:SetPoint("CENTER",(AuctionFrame and AuctionFrame:IsShown()) and AuctionFrame or UIParent,"CENTER",0,0)
    Atr_FullScanFrame:SetClampedToScreen(true)
    if Atr_FullScanFrame.GetRegions then
        for _,region in ipairs({Atr_FullScanFrame:GetRegions()}) do
            if region:GetObjectType()=="Texture" and type(region:GetTexture())=="string"
                and region:GetTexture():find("UI-DialogBox-Header",1,true) then
                region:SetTexture(nil) -- Remove the original stone header plate.
            elseif region:GetObjectType()=="FontString" and region:GetText()=="Full Scan" then
                region:ClearAllPoints();region:SetPoint("TOP",Atr_FullScanFrame,"TOP",0,-12)
            end
        end
    end
    Atr_StyleOfflineBrowser(Atr_FullScanFrame,false,false)
    styleScanResults()
    -- An explicit fill also covers skins that supply a translucent bg texture.
    local fill=Atr_FullScanFrame.atrSolidBackground
    if not fill then
        fill=Atr_FullScanFrame:CreateTexture(nil,"BACKGROUND",nil,-8)
        fill:SetAllPoints(Atr_FullScanFrame)
        fill:SetTexture("Interface\\Buttons\\WHITE8X8")
        Atr_FullScanFrame.atrSolidBackground=fill
    end
    local r,g,b=Atr_FullScanFrame:GetBackdropColor()
    fill:SetVertexColor(r,g,b,1)
    Atr_UpdateFullScanCounts()
    for _,button in ipairs({Atr_FullScanStartButton,Atr_FullScanDone,clear,undo,databaseStatus}) do
        Atr_AnalysisSkin(button,"Button")
    end
    Atr_AnalysisSkin(slow,"CheckBox")
end
Atr_FullScanFrame:HookScript("OnShow",function() Atr_StyleFullScanDialog() end)
local function layoutScanDialog()
    Atr_StyleFullScanDialog()
    local function anchor(frame, point, x, y)
        frame:ClearAllPoints()
        frame:SetPoint(point, Atr_FullScanFrame, point, x, y)
    end
    for i,pair in ipairs({{Atr_FullScanNextLabel,Atr_FullScanNext},{Atr_FullScanDBwhenLabel,Atr_FullScanDBwhen},{Atr_FullScanDBsizeLabel,Atr_FullScanDBsize}}) do
        if pair[1] then anchor(pair[1],"TOPLEFT",20,-38-(i-1)*22) end
        anchor(pair[2],"TOPLEFT",180,-38-(i-1)*22)
    end
    anchor(slow,"TOPLEFT",20,-151)
    anchor(Atr_FullScanStartButton, "TOPLEFT", 20, -183)
    Atr_FullScanStartButton:SetWidth(145)
    anchor(clear,"TOPLEFT",275,-183)
    clear:SetWidth(100);undo:SetWidth(100)
    anchor(Atr_FullScanDone, "BOTTOMRIGHT", -20, 12)
    anchor(Atr_FullScanStatus, "TOPLEFT", 20, -222)
    anchor(Atr_FullScanHTML, "TOPLEFT", 20, -242)
    Atr_FullScanHTML:SetWidth(460);Atr_FullScanHTML:SetHeight(104)
    Atr_FullScanResults:ClearAllPoints()
    Atr_FullScanResults:SetPoint("TOPLEFT", Atr_FullScanFrame, "TOPLEFT", 20, -246)
    Atr_FullScanResults:SetPoint("BOTTOMRIGHT", Atr_FullScanFrame, "BOTTOMRIGHT", -20, 50)
    for i,key in ipairs({"scanned","added","updated","ignored"}) do
        local label=_G["Atr_FSR_"..key.."_text"]
        if label then
            label:ClearAllPoints();label:SetPoint("TOPLEFT",Atr_FullScanResults,"TOPLEFT",18,-12-(i-1)*22)
        end
        local count=_G["Atr_FSR_"..key.."_count"]
        if count then
            count:ClearAllPoints();count:SetPoint("TOPLEFT",Atr_FullScanResults,"TOPLEFT",160,-12-(i-1)*22)
            count:SetJustifyH("LEFT")
        end
    end
    local scan=AuctionatorRemastered.FullScan
    if scan and scan.LayoutProgress then scan.LayoutProgress(scan.running) end
    Atr_FullScanNextLabel:SetText("Fast scan available:")
    Atr_FullScanHTML:SetText("<html><body><p>Fast scan requests all auctions at once.<br/>Slow scan reads page by page.</p><br/><p>Clear DB removes saved prices and history for this realm/faction. Undo clear is available until logout or reload and keeps newly collected prices.</p></body></html>")
end
AuctionatorRemastered.Legacy.Hook("Atr_ShowFullScanFrame", layoutScanDialog)
