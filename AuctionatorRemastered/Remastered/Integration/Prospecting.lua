-- Read-only tooltip estimates: reuse saved, ID-based material quotes; never scan.
local P=AuctionatorRemastered.Models.Prospecting
local function name(id) return GetItemInfo(id) or P.names[id] or ("Item "..id) end
AuctionatorRemastered.Legacy.Hook("Atr_ShowTipWithPricing",function(tip,link)
    if not tip or type(link)~="string" then return end
    local id=tonumber(link:match("item:(%d+)"))
    if not P.ores[id] then return end
    if not tip.atrProspectingHook then
        tip:HookScript("OnTooltipCleared",function(self) self.atrProspectingStamp=nil end)
        tip.atrProspectingHook=true
    end
    local mode=AuctionatorRemastered.UI.ProspectingDetailsMode()
    local details=mode=="always" or (mode=="shift" and IsShiftKeyDown())
        or (mode=="control" and IsControlKeyDown()) or (mode=="alt" and IsAltKeyDown())
    local enabled=not AUCTIONATOR_SAVEDVARS or AUCTIONATOR_SAVEDVARS.prospectingTips~=false
    if not enabled and not details then return end
    local shift=IsShiftKeyDown() and true or false
    local stamp=link..tostring(shift)..tostring(details and true or false)..":"..tip:NumLines()
    if tip.atrProspectingStamp==stamp then return end
    tip:AddLine(" ")
    if enabled then
        local value,status=P.Evaluate(id,Atr_GetAuctionPriceDE)
        tip:AddDoubleLine("Prospecting / 5 ore",value and ("|cFFFFFFFF"..gAtrZC.priceToMoneyString(value).."|r") or "|cFFAAAAAAunknown|r",1,.45,.8)
        if not status.complete then tip:AddLine("Missing saved material prices ("..#status.missing..")",1,.6,.2,true) end
        local warnings={}
        if status.partial then warnings[#warnings+1]="partial scan" end
        if status.stale then warnings[#warnings+1]="old prices" end
        if status.undated then warnings[#warnings+1]="undated prices" end
        if #warnings>0 then tip:AddLine(table.concat(warnings,", "),1,.6,.2,true) end
    end
    if details then
        tip:AddDoubleLine("Possible materials / 5 ore","Lowest / item",1,.45,.8,1,.45,.8)
        for _,row in ipairs(P.ores[id]) do
            local qty=tostring(row.minimum)
            if row.maximum~=row.minimum then qty=qty.."–"..row.maximum end
            local price=Atr_GetAuctionPrice(row.id)
            local text="|cFFAAAAAAunknown|r"
            if type(price)=="number" and price==price and price>0 and price<math.huge then
                text="|cFFFFFFFF"..gAtrZC.priceToMoneyString(math.floor(price)).."|r"
            end
            tip:AddDoubleLine(string.format("%.1f%% - %s × %s",row.chance*100,name(row.id),qty),text,1,.45,.8,1,1,1)
        end
    elseif enabled and mode~="never" then
        local key=mode=="control" and "Ctrl" or mode=="alt" and "Alt" or "Shift"
        tip:AddLine("Hold "..key.." for possible materials.",.65,.65,.65)
    end
    tip.atrProspectingStamp=link..tostring(shift)..tostring(details and true or false)..":"..tip:NumLines()
    tip:Show()
end)
