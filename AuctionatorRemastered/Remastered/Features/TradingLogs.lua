-- Trading log view; ledger filtering and sorting live in Models/TradingLogs.lua.
local panel, scroll, summary, empty, search, characterMenu, logTab
local moneyWasShown
local hiddenArtwork = {}
local function hideAHArtwork()
    hiddenArtwork=Atr_AnalysisBegin(panel)
end
local function restoreAHArtwork()
    Atr_AnalysisEnd(hiddenArtwork)
    hiddenArtwork={}
end
local rows, filters, ranges = {}, {}, {}
local kind, days, records = "All", 30, {}
local characters,fromDate,untilDate,dateFrom,dateTo,dateError
local updatingFilters=false
local function characterCaption()
    if not characters then return "All characters" end
    local count,name=0
    for character,selected in pairs(characters) do if selected then count=count+1;name=character end end
    return count==0 and "No characters" or count==1 and name or count.." selected"
end
local sortKey, descending, headings = "when", true, {}
local colors = {Bought = "66ccff", Listed = "ffcc66"}
local function money(value)
    return gAtrZC.priceToMoneyString(math.floor(value + 0.5))
end
local function render()
    local visibleRows = math.min(13, math.max(1, math.floor((panel:GetHeight() - 208) / 20)))
    FauxScrollFrame_Update(scroll, #records, visibleRows, 20)
    local offset = FauxScrollFrame_GetOffset(scroll)
    for i, row in ipairs(rows) do
        local data = records[offset + i]
        row.data = data
        if data and i <= visibleRows then
            local values = {
                "|cff"..colors[data.kind]..data.kind.."|r", data.name,
                tostring(data.quantity), money(data.unit), money(data.total),
                data.character or "--", date("%Y-%m-%d %H:%M", data.when),
            }
            for col, value in ipairs(values) do row.fields[col]:SetText(value) end
            row:Show()
        else row:Hide() end
    end
end
local function refresh(reset)
    if not panel or updatingFilters then return end
    local spent, listed, bought, offered
    records, spent, listed, bought, offered = Atr_GetTradingLogs(kind, search:GetText(), type(days)=="number" and days or nil,
        characters,fromDate,untilDate)
    Atr_SortTradingLogs(records,sortKey,descending)
    for key,button in pairs(headings) do
        if key==sortKey then
            button.arrow:SetTexCoord(0,1,descending and 0 or 1,descending and 1 or 0)
            button.arrow:Show()
        else button.arrow:Hide() end
    end
    if reset then FauxScrollFrame_SetOffset(scroll, 0); scroll:SetVerticalScroll(0) end
    summary:SetText("|cff66ccffSpent:|r "..money(spent).."  ("..bought.." items)    |cffffcc66Listed value:|r "..money(listed).."  ("..offered.." items)")
    empty:SetText(#records == 0 and "No purchases or listings found.\nTry another item, activity type or time range." or "")
    for name, button in pairs(filters) do button:SetText(kind == name and "|cffffffff"..name.."|r" or name) end
    UIDropDownMenu_SetText(characterMenu,characterCaption())
    for name, button in pairs(ranges) do
        local active = days=="Today" and name=="Today" or not fromDate and not untilDate and ((name=="All time" and not days) or name==tostring(days).." days")
        button:SetText(active and "|cffffffff"..name.."|r" or name)
    end
    render()
end

local function fitPanelAboveTabs()
    Atr_AnalysisFit(panel)
end

local function makePanel()
    panel = CreateFrame("Frame", "Atr_TradingLogs", AuctionFrame)
    panel:SetPoint("TOPLEFT", AuctionFrame, "TOPLEFT", 0, 0)
    panel:SetPoint("BOTTOMRIGHT", AuctionFrame, "BOTTOMRIGHT", 0, 8)
    panel:SetFrameLevel(AuctionFrame:GetFrameLevel() + 30)
    panel:SetBackdrop(nil)
    -- No mouse-enabled full-window overlay: the real AH close button remains usable.
    local function text(label, x, y, template)
        local font = panel:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
        font:SetPoint("TOPLEFT", panel, "TOPLEFT", x, y); font:SetText(label)
        return font
    end
    local title=text("Trading logs",0,0,"GameFontNormal")
    title:ClearAllPoints();title:SetPoint("TOP",panel,"TOP",0,-10)
    panel.results=CreateFrame("Frame",nil,panel)
    panel.results:SetFrameLevel(panel:GetFrameLevel())
    panel.results:SetPoint("TOPLEFT",panel,"TOPLEFT",10,-160)
    panel.results:SetPoint("BOTTOMRIGHT",panel,"BOTTOMRIGHT",-28,40)
    -- Use the actual skinned Browse result background when available.
    local function resultStyle()
        local source=AuctionatorRemastered.UI.UseElvUI() and AuctionFrameBrowse and AuctionFrameBrowse.RightBackground
        if source and source.GetBackdrop and source:GetBackdrop() then
            panel.results:SetBackdrop(source:GetBackdrop())
            panel.results:SetBackdropColor(source:GetBackdropColor())
            if source.GetBackdropBorderColor then panel.results:SetBackdropBorderColor(source:GetBackdropBorderColor()) end
        else Atr_AnalysisBackdrop(panel.results,1) end
    end
    panel.resultStyle=resultStyle
    resultStyle()
    text("Activity",281,-32,"GameFontNormalSmall")
    text("Characters",489,-32,"GameFontNormalSmall")
    local function filterButton(label,x,width,callback,y,name)
        local button=CreateFrame("Button",name,panel,"UIPanelButtonTemplate")
        Atr_AnalysisSkin(button,"Button")
        button:SetSize(width,22);button:SetPoint("TOPLEFT",panel,"TOPLEFT",x,-(y or 49))
        button:SetText(label);button:SetScript("OnClick",callback)
        return button
    end
    for i,name in ipairs({"All","Bought","Listed"}) do
        local selected=name
        filters[name]=filterButton(name,281+(i-1)*63,60,function() kind=selected;refresh(true) end)
    end
    text("Time range",20,-86,"GameFontNormalSmall")
    for i,range in ipairs({"Today",7,30,false}) do
        local value=range
        local label=range=="Today" and "Today" or range and range.." days" or "All time"
        ranges[label]=filterButton(label,20+(i-1)*66,63,function()
            days=value or nil;fromDate=nil;untilDate=nil
            if value=="Today" then
                local today=date("%Y-%m-%d")
                fromDate,untilDate=Atr_ParseTradingLogDate(today)
            end
            dateFrom:SetText("");dateTo:SetText("");dateError:SetText("")
            dateFrom:ClearFocus();dateTo:ClearFocus();refresh(true)
        end,103)
    end
    search = CreateFrame("EditBox", "Atr_LogsSearch", panel, "InputBoxTemplate")
    Atr_AnalysisSkin(search,"EditBox")
    search:SetSize(198,22);search:SetPoint("TOPLEFT",panel,"TOPLEFT",24,-49)
    search:SetAutoFocus(false)
    search:SetScript("OnTextChanged", function() refresh(true) end)
    search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    search:SetScript("OnEnterPressed",function(self) self:ClearFocus() end)
    text("Name",20,-32,"GameFontNormalSmall")
    local clear=CreateFrame("Button","Atr_LogsClearSearch",panel,"UIPanelButtonTemplate")
    Atr_AnalysisSkin(clear,"Button");clear:SetSize(42,22);clear:SetPoint("TOPLEFT",panel,"TOPLEFT",229,-49)
    clear:SetText("Clear");clear:SetScript("OnClick",function() search:SetText("");search:ClearFocus() end)
    characterMenu=CreateFrame("Frame","Atr_LogsCharacters",panel,"UIDropDownMenuTemplate")
    characterMenu:SetPoint("TOPLEFT",panel,"TOPLEFT",469,-47)
    UIDropDownMenu_SetWidth(characterMenu,170)
    Atr_AnalysisSkin(characterMenu,"DropDownBox")
    if AuctionatorRemastered.UI.UseElvUI() then characterMenu:SetWidth(210) end
    UIDropDownMenu_JustifyText(characterMenu,"LEFT")
    UIDropDownMenu_Initialize(characterMenu,function()
        local function action(label,callback)
            local info=UIDropDownMenu_CreateInfo()
            info.text=label;info.notCheckable=true;info.func=callback
            UIDropDownMenu_AddButton(info)
        end
        action("All characters",function() characters=nil;CloseDropDownMenus();refresh(true) end)
        action("Only this character",function() characters={[UnitName("player")]=true};CloseDropDownMenus();refresh(true) end)
        local names=Atr_GetTradingLogCharacters()
        for _,name in ipairs(names) do
            local selectedName=name
            local info=UIDropDownMenu_CreateInfo()
            info.text=name;info.isNotRadio=true;info.keepShownOnClick=true
            info.checked=function() return not characters or characters[selectedName]==true end
            info.func=function()
                if not characters then
                    characters={}
                    for _,character in ipairs(names) do characters[character]=true end
                end
                characters[selectedName]=not characters[selectedName] or nil
                refresh(true)
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    dateError=text("",642,-103,"GameFontHighlightSmall")
    dateError:SetWidth(156);dateError:SetHeight(26);dateError:SetTextColor(1,.35,.35)
    local function applyDates()
        local first,_,firstError=Atr_ParseTradingLogDate(dateFrom:GetText())
        local _,last,lastError=Atr_ParseTradingLogDate(dateTo:GetText())
        if firstError or lastError or first and last and first>=last then
            dateError:SetText(firstError or lastError or "From must not be after To.")
            return
        end
        days=nil;fromDate=first;untilDate=last;dateError:SetText("")
        dateFrom:ClearFocus();dateTo:ClearFocus();refresh(true)
    end
    local function dateField(name,label,x)
        local heading=text(label.." (YYYY-MM-DD)",x,-86,"GameFontNormalSmall")
        heading:SetWidth(120);heading:SetHeight(14)
        local field=CreateFrame("EditBox",name,panel,"InputBoxTemplate")
        Atr_AnalysisSkin(field,"EditBox");field:SetSize(96,22)
        field:SetPoint("TOPLEFT",panel,"TOPLEFT",x+(AuctionatorRemastered.UI.UseElvUI() and 0 or 5),-103)
        field:SetAutoFocus(false);field:SetMaxLetters(10)
        field:SetScript("OnEnterPressed",applyDates)
        field:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
        local function help(self)
            GameTooltip:SetOwner(self,"ANCHOR_LEFT")
            GameTooltip:SetText(label.." date",.9,1,1)
            GameTooltip:AddLine("Use YYYY-MM-DD. Leave blank for no limit. The To date includes the whole day. Press Enter or Apply to filter.",.5,.5,1,true)
            GameTooltip:Show()
        end
        local area=CreateFrame("Frame",nil,panel);area:SetAllPoints(heading);area:EnableMouse(true)
        area:SetScript("OnEnter",help);area:SetScript("OnLeave",function() GameTooltip:Hide() end)
        return field
    end
    dateFrom=dateField("Atr_LogsDateFrom","From",310)
    dateTo=dateField("Atr_LogsDateTo","To",440)
    filterButton("Apply",560,70,applyDates,103,"Atr_LogsApplyDates")
    filterButton("Reset filters",696,104,function()
        updatingFilters=true
        kind="All";days=30;characters=nil;fromDate=nil;untilDate=nil
        search:SetText("");dateFrom:SetText("");dateTo:SetText("");dateError:SetText("")
        search:ClearFocus();dateFrom:ClearFocus();dateTo:ClearFocus()
        updatingFilters=false;refresh(true)
    end,49,"Atr_LogsResetFilters")
    summary=text("",198,0,"GameFontHighlightSmall")
    summary:ClearAllPoints();summary:SetPoint("BOTTOMLEFT",panel,"BOTTOMLEFT",20,14)
    summary:SetWidth(690);summary:SetHeight(18);summary:SetJustifyH("LEFT")
    local specs={{"Action",18,52,"kind"},{"Item",76,178,"name"},{"Qty",260,40,"quantity"},
        {"Price / item",308,124,"unit"},{"Total",438,130,"total"},{"Character",574,83,"character"},{"Date / time",663,117,"when"}}
    for _,spec in ipairs(specs) do
        local key=spec[4]
        local button=CreateFrame("Button","Atr_LogsSort_"..key,panel)
        button:SetPoint("TOPLEFT",panel,"TOPLEFT",spec[2],-139);button:SetSize(spec[3],20)
        button:SetNormalFontObject(GameFontNormalSmall);button:SetHighlightFontObject(GameFontHighlightSmall)
        button:SetText(spec[1])
        local font=button:GetFontString()
        if font then font:SetJustifyH("LEFT");font:ClearAllPoints();font:SetPoint("LEFT",button,"LEFT",0,0);font:SetWidth(spec[3]-10) end
        button.arrow=button:CreateTexture(nil,"OVERLAY")
        button.arrow:SetTexture("Interface\\Buttons\\UI-SortArrow");button.arrow:SetSize(8,8)
        button.arrow:SetPoint("RIGHT",button,"RIGHT",0,0);button.arrow:Hide()
        button:SetScript("OnClick",function()
            if sortKey==key then descending=not descending else sortKey=key;descending=key=="when" end
            refresh(true)
        end)
        headings[key]=button
    end
    scroll = CreateFrame("ScrollFrame", "Atr_LogsScroll", panel, "FauxScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -164)
    scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -32, 44)
    Atr_StyleAnalysisScroll(scroll,panel.results)
    scroll:SetScript("OnVerticalScroll", function(self, offset) FauxScrollFrame_OnVerticalScroll(self, offset, 20, render) end)
    for i = 1, 13 do
        local row = CreateFrame("Button", nil, panel)
        row:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -164 - (i-1)*20)
        row:SetPoint("RIGHT", panel, "RIGHT", -32, 0); row:SetHeight(20)
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        local stripe=row:CreateTexture(nil,"BACKGROUND")
        stripe:SetAllPoints();stripe:SetTexture(1,1,1,i%2==0 and .035 or 0)
        row.fields = {}
        for col, spec in ipairs(specs) do
            local font = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            font:SetPoint("LEFT", row, "LEFT", spec[2]-14, 0)
            font:SetWidth(spec[3]);font:SetHeight(18); font:SetJustifyH("LEFT")
            row.fields[col] = font
        end
        row:SetScript("OnEnter", function(self)
            local data = self.data
            if not data then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(data.name, 1, 0.82, 0)
            GameTooltip:AddLine(data.kind.." by "..(data.character or "--"), 1, 1, 1)
            GameTooltip:AddLine("Quantity: "..data.quantity.." ("..data.stacks.." x "..data.size..")", 1, 1, 1)
            GameTooltip:AddLine("Price / item: "..money(data.unit), 1, 1, 1)
            GameTooltip:AddLine("Total: "..money(data.total), 1, 1, 1)
            GameTooltip:AddLine(date("%Y-%m-%d %H:%M:%S", data.when), 0.8, 0.8, 0.8)
            if data.seller then GameTooltip:AddLine("Seller: "..data.seller, 1, 1, 1) end
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
        rows[i] = row
    end
    empty=text("",0,0,"GameFontNormal")
    Atr_StyleEmptyMessage(empty,panel.results)
    local close=CreateFrame("Button","Atr_LogsCloseButton",panel,"UIPanelButtonTemplate")
    Atr_AnalysisSkin(close,"Button");close:SetSize(80,22)
    close:SetPoint("BOTTOMRIGHT",panel,"BOTTOMRIGHT",-12,10);close:SetText("Close")
    close:SetScript("OnClick",function() HideUIPanel(AuctionFrame) end)
    panel:SetScript("OnShow", function()
        fitPanelAboveTabs()
        hideAHArtwork()
        panel.resultStyle()
        Atr_StyleAnalysisScroll(scroll,panel.results)
        if AuctionFrameMoneyFrame then
            moneyWasShown = AuctionFrameMoneyFrame:IsShown()
            AuctionFrameMoneyFrame:Hide()
        end
        refresh(true)
    end)
    panel:SetScript("OnHide", function()
        restoreAHArtwork()
        if moneyWasShown and AuctionFrameMoneyFrame then AuctionFrameMoneyFrame:Show() end
        moneyWasShown = nil
        search:ClearFocus();dateFrom:ClearFocus();dateTo:ClearFocus();CloseDropDownMenus();GameTooltip:Hide()
    end)
    panel:Hide()
end

AuctionatorRemastered.Legacy.Hook("Atr_AuctionFrameTab_OnClick", function()
    if panel then panel:Hide() end
end)
AuctionatorRemastered.Legacy.Hook("Atr_Init", function()
    makePanel()
    local n = AuctionFrame.numTabs + 1
    logTab = CreateFrame("Button", "AuctionFrameTab"..n, AuctionFrame, "AuctionTabTemplate")
    logTab:SetID(n); logTab:SetText("Logs")
    logTab:SetNormalFontObject(AtrFontOrange)
    PanelTemplates_TabResize(logTab,0)
    logTab:SetPoint("LEFT", _G["AuctionFrameTab"..(n-1)], "RIGHT", -8, 0)
    PanelTemplates_SetNumTabs(AuctionFrame, n); PanelTemplates_EnableTab(AuctionFrame, n)
    logTab:SetScript("OnClick", function()
        -- Use the normal Browse transition to cleanly leave Auctionator panes,
        -- then show only our independent, read-only log panel.
        Atr_AuctionFrameTab_OnClick(AuctionFrameTab1, 1)
        AuctionFrameBrowse:Hide(); AuctionFrameBid:Hide(); AuctionFrameAuctions:Hide()
        Atr_Main_Panel:Hide()
        PanelTemplates_SetTab(AuctionFrame, n)
        if AuctionFrameTitleText then AuctionFrameTitleText:SetText("Auctionator - Logs") end
        panel:Show()
    end)
end)
