-- Observe buyout requests and the server's accepted-bid message.
-- No extra auction queries, purchases, bids, or mail actions are issued.
local function ledger()
    if type(AUCTIONATOR_PURCHASES) ~= "table" then AUCTIONATOR_PURCHASES = {} end
    local key = GetRealmName().."_"..UnitFactionGroup("player")
    if not AUCTIONATOR_PURCHASES[key] then AUCTIONATOR_PURCHASES[key] = {since = time(), records = {}} end
    return AUCTIONATOR_PURCHASES[key]
end
local pending = {}
local visitID,visitActive,visitItems = 0,false,{}
local updateVisitUI = function() end
local function startVisit()
    if visitActive then return end
    visitID=visitID+1;visitActive=true;visitItems={}
end
function Atr_GetVisitPurchases(itemName)
    local record=visitItems[itemName]
    return record and record.quantity or 0,record and record.spent or 0
end
local function expire()
    while pending[1] and pending[1].expires < time() do table.remove(pending, 1) end
end
hooksecurefunc("PlaceAuctionBid", function(kind, index, amount)
    expire()
    if not visitActive and AuctionFrame and AuctionFrame:IsShown() then startVisit() end
    local candidate = {expires = time() + 30,visit=visitActive and visitID or nil}
    -- Track non-buyout bid requests too, to consume their acknowledgements
    -- without accidentally attributing them to a later buyout.
    if kind == "list" then
        local name, _, count, _, _, _, _, _, buyout, _, _, seller = GetAuctionItemInfo(kind, index)
        if name and count and count > 0 and buyout and buyout > 0 and amount == buyout then
            local ok,link
            if GetAuctionItemLink then ok,link=pcall(GetAuctionItemLink,kind,index) end
            if not ok then link=nil end
            local identity=AuctionatorRemastered.Models.ItemIdentity
            candidate.record = {
                name = name, link=link, itemKey=identity and identity.Parse(link), when = time(), stackSize = count, stackPrice = buyout,
                stacks = 1, character = UnitName("player"), seller = seller,
            }
        end
    end
    pending[#pending + 1] = candidate
end)
local events = CreateFrame("Frame")
events:RegisterEvent("CHAT_MSG_SYSTEM")
events:RegisterEvent("UI_ERROR_MESSAGE")
events:RegisterEvent("ADDON_ACTION_BLOCKED")
events:RegisterEvent("ADDON_ACTION_FORBIDDEN")
events:RegisterEvent("AUCTION_HOUSE_SHOW")
events:RegisterEvent("AUCTION_HOUSE_CLOSED")
events:SetScript("OnEvent", function(self, event, message, action)
    expire()
    if event=="ADDON_ACTION_BLOCKED" or event=="ADDON_ACTION_FORBIDDEN" then
        if (type(message)=="string" and message:find("AuctionatorRemastered",1,true)) or
            (type(action)=="string" and action:find("PlaceAuctionBid",1,true)) then pending={} end
        return
    end
    if event=="AUCTION_HOUSE_SHOW" then startVisit();updateVisitUI();return end
    if event=="AUCTION_HOUSE_CLOSED" then visitActive=false;updateVisitUI();return end
    if event == "UI_ERROR_MESSAGE" then
        -- Conservative: do not report uncertain requests as completed buys.
        pending = {}
        return
    end
    if message ~= ERR_AUCTION_BID_PLACED or not ERR_AUCTION_BID_PLACED then return end
    local request = table.remove(pending, 1)
    if not request or not request.record then return end
    local log = ledger()
    log.records[#log.records + 1] = request.record
    if visitActive and request.visit==visitID then
        local record=request.record
        local sum=visitItems[record.name] or {quantity=0,spent=0}
        sum.quantity=sum.quantity+record.stackSize*record.stacks
        sum.spent=sum.spent+record.stackPrice*record.stacks
        visitItems[record.name]=sum
    end
    while #log.records > 5000 or (#log.records > 0 and log.records[1].when < time() - 180 * 86400) do
        table.remove(log.records, 1)
    end
    local pane = Atr_GetCurrentPane()
    if pane then pane.sortedHist = nil; pane.UINeedsUpdate = true end
    updateVisitUI()
end)

-- Separate visit-wide counters: the original buy progress still describes only
-- the currently selected purchase batch. Never infer bought units from that UI.
local popupItem,visitCount,visitSpent,headerCount
local function currentItem()
    local pane=Atr_GetCurrentPane()
    return pane and pane.activeScan and pane.activeScan.itemName
end
local function quantityText(name)
    local quantity,spent=Atr_GetVisitPurchases(name)
    local _,_,_,_,_,_,_,stackSize=GetItemInfo(name)
    local text=quantity..(quantity==1 and " item" or " items")
    if type(stackSize)=="number" and stackSize>1 and quantity>=stackSize then
        local stacks=math.floor(quantity/stackSize)
        local remainder=quantity%stackSize
        text=stacks..(stacks==1 and " stack" or " stacks")..
            (remainder>0 and " + "..remainder or "").." ("..quantity.." items)"
    end
    return "|cff66ccffThis visit:|r "..text,spent
end
updateVisitUI=function()
    if visitCount and visitSpent then
        if visitActive and popupItem and Atr_Buy_Confirm_Frame:IsShown() then
            local text,spent=quantityText(popupItem)
            visitCount:SetText(text)
            visitSpent:SetText("Spent on this item: "..(spent==0 and "0c" or gAtrZC.priceToMoneyString(spent)))
            visitCount:Show();visitSpent:Show()
        else visitCount:Hide();visitSpent:Hide() end
    end
    if not headerCount and Atr_Main_Panel and Atr_Recommend_Text then
        headerCount=Atr_Main_Panel:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        headerCount:SetPoint("TOPLEFT",Atr_Recommend_Text,"BOTTOMLEFT",0,-5)
        headerCount:SetWidth(260);headerCount:SetJustifyH("LEFT")
    end
    if headerCount then
        local name=currentItem()
        local pane=Atr_GetCurrentPane()
        local scan=pane and pane.activeScan
        if visitActive and name and scan.whenScanned and scan.whenScanned>0
            and Atr_Main_Panel:IsShown() and Atr_IsTabSelected(3) and not Atr_ShowingSearchSummary() then
            headerCount:SetText((quantityText(name)));headerCount:Show()
        else headerCount:Hide() end
    end
end
Atr_Buy_Confirm_Frame:HookScript("OnShow",function(self)
    if not visitActive and AuctionFrame and AuctionFrame:IsShown() then startVisit() end
    popupItem=currentItem()
    -- Preserve the original content area's size; reserve a new strip underneath
    -- it for the visit total, above the existing bottom-anchored action buttons.
    self:SetHeight(230)
    for _,part in ipairs({Atr_Buy_Part1,Atr_Buy_Part2}) do
        part:ClearAllPoints();part:SetPoint("TOPLEFT",self,"TOPLEFT",0,0)
        part:SetPoint("BOTTOMRIGHT",self,"BOTTOMRIGHT",0,90)
    end
    if not visitCount then
        visitCount=self:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        visitCount:SetPoint("TOPLEFT",self,"TOPLEFT",30,-127);visitCount:SetWidth(330);visitCount:SetJustifyH("LEFT")
        visitSpent=self:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        visitSpent:SetPoint("TOPLEFT",self,"TOPLEFT",30,-145);visitSpent:SetWidth(330);visitSpent:SetJustifyH("LEFT")
    end
    self.atrVisitCount,self.atrVisitSpent=visitCount,visitSpent
    if Atr_StyleBuyConfirmDialog then Atr_StyleBuyConfirmDialog() end
    updateVisitUI()
end)
AuctionatorRemastered.Legacy.Hook("Atr_Buy1_Onclick",function()
    if Atr_Buy_Confirm_Frame:IsShown() then popupItem=currentItem();updateVisitUI() end
end)
AuctionatorRemastered.Legacy.Hook("Atr_UpdateUI",updateVisitUI)

function Atr_BuildPurchaseRows(itemName)
    local rows = {}
    for _, record in ipairs(ledger().records) do
        if record.name == itemName then
            rows[#rows + 1] = {
                when = record.when, itemPrice = record.stackPrice / record.stackSize,
                stackSize = record.stackSize, stacks = record.stacks,
                quantity = record.stackSize * record.stacks,
                total = record.stackPrice * record.stacks,
                character = record.character, seller = record.seller,
                yours = true, type = "hx", ownLedger = true, purchase = true,
                status = "Bought", whenText = date("%Y-%m-%d %H:%M:%S", record.when),
            }
        end
    end
    table.sort(rows, function(a,b) return a.when > b.when end)
    return rows
end

AuctionatorRemastered.Legacy.Hook("Atr_Init", function()
    ledger()
    local fourth, third = Atr_ListTabsTab4, Atr_ListTabsTab3
    if not fourth or not third then return end
    fourth:SetText("My Purchases")
    -- Keep the same TabButtonTemplate styling as the existing tabs.
    -- HandleButton turned this into an ordinary rectangular button.
    local order = {Atr_ListTabsTab3, Atr_ListTabsTab4, Atr_ListTabsTab2, Atr_ListTabsTab1}
    for i, tab in ipairs(order) do
        tab:SetWidth(tab:GetFontString():GetStringWidth() + 28)
        tab:ClearAllPoints()
        if i == 1 then
            tab:SetPoint("BOTTOMRIGHT", Atr_ListTabs, "BOTTOMRIGHT", -8, 0)
        else
            tab:SetPoint("RIGHT", order[i - 1], "LEFT", -3, 0)
        end
    end
end)
