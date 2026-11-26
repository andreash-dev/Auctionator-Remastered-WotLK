local stats=AuctionatorRemastered.DatabaseStats.Get

local status=CreateFrame("Frame","Atr_DatabaseStatusOptions",UIParent)
status.name="Database status";status.parent="Auctionator Remastered"
if InterfaceOptions_AddCategory then InterfaceOptions_AddCategory(status) end
status:Hide()
local cards
local function fontSize(label,size)
    local font,_,flags=label:GetFont()
    label:SetFont(font,size,flags)
end
local function dateDay(day)
    return day and date("%Y-%m-%d",gScanHistDayZero+day*86400) or "--"
end
local function stamp(value)
    return value and date("%m-%d %H:%M",value) or "--"
end
local function createCards()
    cards={}
    for index,title in ipairs({"Your collection","Item quality","Auction activity","Price history"}) do
        local card=CreateFrame("Frame",nil,status)
        local heading=card:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
        heading:SetPoint("TOPLEFT",card,"TOPLEFT",8,-8);heading:SetText(title)
        fontSize(heading,12)
        card.rows={}
        for row=1,7 do
            local label=card:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
            label:SetPoint("TOPLEFT",card,"TOPLEFT",8,-30-(row-1)*13);label:SetJustifyH("LEFT")
            fontSize(label,11);label:SetHeight(13);label:SetWordWrap(false)
            local value=card:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
            value:SetPoint("TOPRIGHT",card,"TOPRIGHT",-8,-30-(row-1)*13);value:SetJustifyH("RIGHT")
            fontSize(value,11);value:SetHeight(13);value:SetWordWrap(false)
            if index==4 and row==5 then
                AuctionatorRemastered.UI.Options.BindLabelHelp(label,card,{
                    "Last complete scan",
                    "The most recent full scan saved with complete auction data for this realm and faction. Cancelled or partial scans do not update this time. -- means no complete scan has been recorded.",
                })
            end
            card.rows[row]={label,value}
        end
        cards[index]=card
    end
    local note=status:CreateFontString(nil,"OVERLAY","GameFontDisableSmall")
    note:SetPoint("TOPLEFT",status,"TOPLEFT",24,-368)
    note:SetJustifyH("LEFT");note:SetHeight(40)
    fontSize(note,10)
    status.atrStatsNote=note
end
local function update()
    if not status:IsShown() then return end
    if not cards then createCards() end
    local record,overview=stats(),Atr_GetDatabaseOverview()
    local days,oldest,newest,samples=Atr_GetDatabaseCoverage()
    local health=Atr_GetDatabaseHealth and Atr_GetDatabaseHealth()
    local q=overview.quality
    local median=Atr_GetFullScanMedianDuration()
    local memory="--"
    if type(GetAddOnMemoryUsage)=="function" then
        if UpdateAddOnMemoryUsage then UpdateAddOnMemoryUsage() end
        local kb=GetAddOnMemoryUsage("AuctionatorRemastered")
        if type(kb)=="number" and kb>=0 then memory=string.format("%.1f MB",kb/1024) end
    end
    local rows={
        {{"Priced variants",overview.total},{"Identified",health and health.identified or "--"},
         {"Unresolved names",health and health.unresolved or "--"},{"Updated in 24h",overview.recent},{"Addon memory",memory}},
        {{"|cff9d9d9dPoor|r",q[0] or 0},{"Common",q[1] or 0},{"|cff1eff00Uncommon|r",q[2] or 0},
         {"|cff0070ddRare|r",q[3] or 0},{"|cffa335eeEpic|r",q[4] or 0},
         {"|cffff8000Legendary+|r",(q[5] or 0)+(q[6] or 0)+(q[7] or 0)},{"Unknown quality",overview.unknownQuality}},
        {{"Searches started",record.searches or 0},{"Full scans",record.scans or 0},
         {"Fast / slow",(record.fast or 0).." / "..(record.slow or 0)},{"Last full scan",stamp(record.last)},
         {"Last scan duration",record.duration and record.duration.." sec" or "--"},
         {"Median scan time",median and string.format("%.1f sec",median) or "--"},{"Last scan auctions",record.auctions or "--"}},
        {{"Days with prices",days},{"Item/day records",samples},{"Oldest price",dateDay(oldest)},
         {"Newest price",dateDay(newest)},{"Last complete",stamp(health and health.lastCompleteScan)}}
    }
    local width=(status:GetWidth()-60)/2
    for index,card in ipairs(cards) do
        card:ClearAllPoints();card:SetPoint("TOPLEFT",status,"TOPLEFT",24+((index-1)%2)*(width+12),-94-math.floor((index-1)/2)*136)
        card:SetSize(width,128)
        Atr_StyleOfflineBrowser(card,true,false)
        for row,fields in ipairs(card.rows) do
            local entry=rows[index][row]
            fields[1]:SetWidth((width-22)*.60);fields[2]:SetWidth((width-22)*.40)
            fields[1]:SetText(entry and entry[1] or "");fields[2]:SetText(entry and tostring(entry[2]) or "")
        end
    end
    status.atrStatsNote:SetWidth(math.max(240,status:GetWidth()-48))
    status.atrStatsNote:SetText("Searches include Buy, Sell and Undercuts.\nItem counts refer to saved price variants, not individual auctions.\nMedian scan time uses up to 100 recorded, completed full scans.")
end
status:HookScript("OnShow",update)
AuctionatorRemastered.Legacy.Hook("Atr_ScanningConfigFrame_Update",update)
