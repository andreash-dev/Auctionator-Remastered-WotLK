-- Remastered owns its addon controls. The legacy AddOnSkins callback targets
-- Auctionator 2.6.3 and must not run, regardless of the user's skin checkbox.
-- Leave Blizzard_AuctionUI and all unrelated addon callbacks untouched.
local function blockLegacyAuctionatorSkin()
    local engine=type(ElvUI)=="table" and ElvUI[1]
    if not engine or type(engine.GetModule)~="function" then return end
    local ok,skins=pcall(engine.GetModule,engine,"Skins",true)
    if not ok or not skins then return end
    if not skins.atrRemasteredSkinGuard and type(skins.AddCallbackForAddon)=="function" then
        local original=skins.AddCallbackForAddon
        skins.AddCallbackForAddon=function(self,addon,event,...)
            if addon=="Auctionator" and event=="Auctionator" then return end
            return original(self,addon,event,...)
        end
        skins.atrRemasteredSkinGuard=true
    end
    -- AddOnSkins may have registered before Auctionator's files were loaded.
    local callbacks=skins.addonCallbacks and skins.addonCallbacks.Auctionator
    if callbacks and callbacks.Auctionator and type(engine.UnregisterCallback)=="function" then
        engine.UnregisterCallback(engine,"Auctionator")
        callbacks.Auctionator=nil
        for i=#(callbacks.CallPriority or {}),1,-1 do
            if callbacks.CallPriority[i]=="Auctionator" then table.remove(callbacks.CallPriority,i) end
        end
    end
end
blockLegacyAuctionatorSkin()
local skinGuardEvents=CreateFrame("Frame")
skinGuardEvents:RegisterEvent("ADDON_LOADED")
skinGuardEvents:SetScript("OnEvent",function() blockLegacyAuctionatorSkin() end)

-- Compatibility geometry for the 3.1.5 layout and ElvUI's auction-house shell.
-- No auction queries, pricing or transaction handlers are changed here.
local function place(name, relative, point, relativePoint, x, y, width, height)
    local frame = _G[name]
    if not frame or not relative then return end
    frame:ClearAllPoints()
    frame:SetPoint(point, relative, relativePoint, x, y)
    if width then frame:SetWidth(width) end
    if height then frame:SetHeight(height) end
end

local function fixDropTarget()
    if not ElvUI or not Atr_Main_Panel or not Atr_Main_Panel:IsShown()
        or not Atr_Hlist or not Atr_Hlist.SetTemplate or not Atr_Hilite1 then return end
    local panel=Atr_Main_Panel
    local height=Atr_Hilite1:GetHeight()>200 and 300 or 116
    local width=610
    -- ElvUI's panel width does not describe its visible right-hand column.
    -- Bound both the outline and mouse target by the outer window instead.
    if AuctionFrame and AuctionFrame:GetRight() and panel:GetLeft() then
        local outerScale=AuctionFrame:GetEffectiveScale()
        local targetScale=Atr_Hilite1:GetEffectiveScale()
        local left=panel:GetLeft()*panel:GetEffectiveScale()+5*targetScale
        local available=(AuctionFrame:GetRight()*outerScale-left)/targetScale-16
        if available>0 then width=available end
    end
    place("Atr_Hilite1",panel,"TOPLEFT","TOPLEFT",5,-75,width,height)
    place("Atr_Hilite1_btn",Atr_Hilite1,"TOPLEFT","TOPLEFT",0,0,width,height)
end

local moneyOriginal
-- Older AddOnSkins releases stop partway through their Auctionator callback
-- when they encounter controls removed in later versions. Skin the live action
-- buttons independently, without replacing controls or their click handlers.
local skinnedButtons=setmetatable({},{__mode="k"})
local skinnedTabs=setmetatable({},{__mode="k"})
local function skinAuctionTabs()
    local engine=type(ElvUI)=="table" and ElvUI[1]
    if not engine or type(engine.GetModule)~="function" or not AuctionFrame then return end
    local ok,skins=pcall(engine.GetModule,engine,"Skins",true)
    if not ok or not skins or type(skins.HandleTab)~="function" then return end
    for i=1,(AuctionFrame.numTabs or 0) do
        local tab=_G["AuctionFrameTab"..i]
        if tab and not skinnedTabs[tab] and pcall(skins.HandleTab,skins,tab) then
            skinnedTabs[tab]=true
            -- Match ElvUI's tab backdrop insets; preserve the first tab anchor.
            local previous=_G["AuctionFrameTab"..(i-1)]
            if previous then
                tab:ClearAllPoints()
                tab:SetPoint("TOPLEFT",previous,"TOPRIGHT",-15,0)
            end
        end
    end
end
local function skinLiveButtons()
    local engine=type(ElvUI)=="table" and ElvUI[1]
    if not engine or type(engine.GetModule)~="function" then return end
    local ok,skins=pcall(engine.GetModule,engine,"Skins",true)
    if not ok or not skins or type(skins.HandleButton)~="function" then return end
    for _,name in ipairs({
        "Atr_FullScanButton","Auctionator1Button",
        "AuctionatorCloseButton","Atr_CancelSelectionButton","Atr_Buy1_Button",
        "Atr_Search_Button","Atr_Adv_Search_Button","Atr_Back_Button",
        "Atr_AddToSListButton","Atr_RemFromSListButton","Atr_SrchSListButton",
        "Atr_MngSListsButton","Atr_NewSListButton","Atr_SaveThisList_Button",
        "Atr_CreateAuctionButton","Atr_CheckActiveButton",
    }) do
        local button=_G[name]
        if button and not skinnedButtons[button] then
            if button.isSkinned or pcall(skins.HandleButton,skins,button) then
                skinnedButtons[button]=true
            end
        end
    end
end
-- Stock-only spacing. ElvUI keeps its existing layout and skin-owned anchors.
local function fixNativeSellLayout()
    local skinned=ElvUI and AuctionFrame and AuctionFrame.backdrop
        and AuctionFrameBrowse and AuctionFrameBrowse.RightBackground
    if skinned or not Atr_Main_Panel or not Atr_Main_Panel:IsShown()
        or not Atr_IsTabSelected or not Atr_IsTabSelected(1)
        or not Atr_SellControls or not Atr_SellControls:IsShown() then return end
    local controls=Atr_SellControls
    local function at(name,x,y,width,height)
        place(name,controls,'TOPLEFT','TOPLEFT',x,-y,width,height)
    end
    at('Atr_StackPriceText',10,76)
    at('Atr_StackPrice',14,90)
    at('Atr_ItemPriceText',10,118)
    at('Atr_ItemPrice',14,132)
    at('Atr_ItemsOwned_Text',10,156,170,14)
    if Atr_ItemsOwned_Text then Atr_ItemsOwned_Text:SetJustifyH('CENTER') end
    at('Atr_Batch_Stacksize_Text',55,176,78,20)
    at('Atr_Batch_NumAuctions',12,176,40,20)
    at('Atr_Batch_Stacksize',137,176,40,20)
    at('Atr_Batch_MaxAuctions_Text',12,198,60,12)
    at('Atr_Batch_MaxStacksize_Text',117,198,60,12)
    if Atr_Batch_MaxStacksize_Text then Atr_Batch_MaxStacksize_Text:SetJustifyH('RIGHT') end
    at('Atr_CreateAuctionButton',12,214,166,26)
end

local function fixLayout()
    if not ElvUI or not Atr_Main_Panel or not Atr_Main_Panel:IsShown() then return end
    -- Only correct a skinned panel; leave the unskinned UI alone.
    if not Atr_Hlist or not Atr_Hlist.SetTemplate then return end
    local panel = Atr_Main_Panel
    local function left(name, x, y, width, height)
        place(name, panel, "TOPLEFT", "TOPLEFT", x, y, width, height)
    end
    left("Atr_Hlist", -191, -75, 172)
    left("Atr_Hlist_ScrollFrame", -191, -75, 172)
    -- Two small buttons share a row; three full-width rows fit below them.
    left("Atr_AddToSListButton", -191, -329, 95, 20)
    left("Atr_RemFromSListButton", -93, -329, 95, 20)
    left("Atr_SrchSListButton", -191, -351, 193, 20)
    left("Atr_MngSListsButton", -191, -373, 193, 20)
    left("Atr_NewSListButton", -191, -395, 193, 20)
    left("Atr_CheckActiveButton", -191, -395, 193, 20)
    local buying = Atr_IsTabSelected(3) -- Auctionator's Buy pane ID
    Atr_Hlist:SetHeight(buying and 252 or 314)
    Atr_Hlist_ScrollFrame:SetHeight(buying and 252 or 314)
    -- Anchor the footer to the actual outer frame, not the old skin's panel width.
    place("AuctionatorCloseButton", AuctionFrame, "BOTTOMRIGHT", "BOTTOMRIGHT", -16, 30, 80, 22)
    local close = AuctionatorCloseButton
    place("Atr_CancelSelectionButton", close, "RIGHT", "LEFT", -8, 0, 113, 22)
    place("Atr_Buy1_Button", Atr_CancelSelectionButton, "RIGHT", "LEFT", -8, 0, 90, 22)
    local money = AuctionFrameMoneyFrame
    if money then
        if not moneyOriginal then
            moneyOriginal = {parent = money:GetParent(), points = {}}
            for i = 1, money:GetNumPoints() do
                moneyOriginal.points[i] = {money:GetPoint(i)}
            end
        end
        money:SetParent(panel)
        place("AuctionFrameMoneyFrame", AuctionFrame, "BOTTOMLEFT", "BOTTOMLEFT", 230, 30)
        money:SetFrameLevel(panel:GetFrameLevel() + 10)
        MoneyFrame_Update("AuctionFrameMoneyFrame", GetMoney())
        if Atr_IsTabSelected(2) then money:Hide() else money:Show() end
    end
    -- Keep the sell footer inside its panel, including skins that lock Duration:SetPoint.
    if Atr_SellControls and Atr_Deposit_Text and Atr_Duration_Text then
        local perItem = Atr_ItemPrice and Atr_ItemPrice:IsShown()
        local createY = perItem and 174 or 132
        local controls = Atr_SellControls
        local function sellPlace(name, x, y, width, height)
            place(name, controls, "TOPLEFT", "TOPLEFT", x, -y, width, height)
        end
        sellPlace("Atr_CreateAuctionButton", 12, createY, 166, 26)
        sellPlace("Atr_Batch_Stacksize_Text", 55, createY + 48)
        sellPlace("Atr_StartingPriceText", 10, createY + 82)
        sellPlace("Atr_StartingPriceDiscountText", 10, createY + 86)
        -- Starting-price inputs retain their anchor below their label.
        local durationY = createY + (AUCTIONATOR_SHOW_ST_PRICE == 1 and 122 or 110)
        Atr_Duration_Text:ClearAllPoints()
        Atr_Deposit_Text.SetPoint(Atr_Duration_Text, "TOPLEFT", controls, "TOPLEFT", 10, -durationY)
        sellPlace("Atr_Duration", 55, durationY - 8)
        sellPlace("Atr_Deposit_Text", 10, durationY + 26)
        controls:SetHeight(durationY + 50)
    end
    -- Twelve 16px rows need room above the footer, including the last row.
    -- Keep the existing row count and scroll offsets; move the viewport only.
    place("Atr_HeadingsBar", panel, "TOPLEFT", "TOPLEFT", 6, -152)
    place("AuctionatorScrollFrame", panel, "TOPLEFT", "TOPLEFT", 5, -198, nil, 192)
    -- The XML's first row starts 15px above the viewport; the old skin may
    -- never reach its correction. Explicitly anchor all twelve rows inside it.
    for i = 1, 12 do
        place("AuctionatorEntry"..i, AuctionatorScrollFrame, "TOPLEFT", "TOPLEFT", 1, -1 - (i - 1) * 16, nil, 16)
    end
    if AuctionatorScrollFrameScrollBar then
        AuctionatorScrollFrameScrollBar:ClearAllPoints()
        AuctionatorScrollFrameScrollBar:SetPoint("TOPLEFT", AuctionatorScrollFrame, "TOPRIGHT", 3, -19)
        AuctionatorScrollFrameScrollBar:SetPoint("BOTTOMLEFT", AuctionatorScrollFrame, "BOTTOMRIGHT", 3, 19)
    end
    -- Auctionator restores its original artwork on tab switches after skinning.
    for _, suffix in ipairs({"TopLeft", "BotLeft", "Top", "TopRight", "Bot", "BotRight"}) do
        local texture = _G["AuctionFrame"..suffix]
        if texture then texture:SetTexture(nil) end
    end
    fixDropTarget()
end

-- Buy and Undercuts share the original history-list controls. Keep their
-- existing scroll callbacks/ranges, but replace the negative-inset background
-- and the XML's thin tooltip-border strip with a clean surface and gutter.
local legacyDividerRemoved=false
local function styleHistoryList()
    local list,scroll=Atr_Hlist,Atr_Hlist_ScrollFrame
    if not list or not scroll or not list:IsShown() or not Atr_Main_Panel:IsShown()
        or not Atr_StyleOfflineBrowser or not Atr_StyleAnalysisScroll then return end
    if not legacyDividerRemoved then
        for _,region in ipairs({list:GetRegions()}) do
            if region:GetObjectType()=="Texture" then
                local texture=region:GetTexture()
                if type(texture)=="string" and texture:find("UI-Tooltip-Border",1,true) then
                    -- XML declares 5px, but its two horizontal anchors stretch
                    -- the region. Match the original asset, not runtime width.
                    region:SetTexture(nil)
                    region:Hide()
                end
            end
        end
        legacyDividerRemoved=true
    end
    -- One outer surface encloses both content and gutter. Keeping a backdrop
    -- on the content frame would draw a second vertical border between them.
    local surface=list.atrListSurface
    if not surface then
        surface=CreateFrame("Frame",nil,list)
        surface:SetPoint("TOPLEFT",list,"TOPLEFT",0,0)
        surface:SetPoint("BOTTOMRIGHT",list,"BOTTOMRIGHT",24,0)
        surface:SetFrameLevel(list:GetFrameLevel())
        surface:EnableMouse(false)
        list.atrListSurface=surface
    end
    Atr_StyleOfflineBrowser(surface,true,false)
    list:SetBackdrop(nil)
    -- Remove the separate fill from earlier layouts, if already present.
    if list.atrScrollBackground then list.atrScrollBackground:Hide() end
    scroll:ClearAllPoints()
    scroll:SetPoint("TOPLEFT",list,"TOPLEFT",0,0)
    scroll:SetPoint("BOTTOMRIGHT",list,"BOTTOMRIGHT",0,0)
    Atr_StyleAnalysisScroll(scroll,list)
    -- All 20 active-item rows must fit above Check for Undercuts even in the
    -- shorter ElvUI viewport. The original 16px scroll step stays unchanged.
    local count=Atr_IsTabSelected(3) and 15 or 20
    local step=math.min(16,math.floor((list:GetHeight()-10)/count))
    local width=list:GetWidth()-8
    for i=1,20 do
        local row=_G["AuctionatorHEntry"..i]
        if row then
            row:ClearAllPoints();row:SetPoint("TOPLEFT",list,"TOPLEFT",4,-5-(i-1)*step)
            row:SetWidth(width);row:SetHeight(step)
            local label=_G["AuctionatorHEntry"..i.."_EntryText"]
            if label then label:SetWidth(width-4);label:SetHeight(step);label:SetJustifyH("LEFT") end
        end
    end
end

-- Presentation only: keep the original quantity, validation, progress and
-- purchase handlers on the existing controls.
local function updateBuyDialogLabels()
    local pane=Atr_GetCurrentPane and Atr_GetCurrentPane()
    local scan=pane and pane.activeScan
    local data=scan and scan.sortedData and scan.sortedData[pane.currIndex]
    local stackSize=data and data.stackSize
    Atr_Buy_Confirm_Text1:SetText(stackSize and stackSize>1 and "Stacks" or "Quantity")
    Atr_Buy_Confirm_Text2:SetText("Total cost")
    Atr_Buy_Confirm_ItemPriceText:SetText("Price per item")
    if stackSize==1 and type(data.buyoutPrice)=="number" then
        Atr_Buy_Confirm_ItemPriceText:Show();Atr_Buy_Confirm_ItemPrice:Show()
        MoneyFrame_Update("Atr_Buy_Confirm_ItemPrice",data.buyoutPrice)
    end
end
function Atr_StyleBuyConfirmDialog()
    local frame=Atr_Buy_Confirm_Frame
    if not frame or not Atr_StyleOfflineBrowser or not Atr_AnalysisSkin then return end
    frame:ClearAllPoints();frame:SetSize(440,290)
    frame:SetPoint("CENTER",(AuctionFrame and AuctionFrame:IsShown()) and AuctionFrame or UIParent,"CENTER",0,0)
    frame:SetClampedToScreen(true)
    Atr_StyleOfflineBrowser(frame,false,false)
    local fill=frame.atrSolidBackground
    if not fill then
        fill=frame:CreateTexture(nil,"BACKGROUND",nil,-8)
        fill:SetAllPoints(frame);fill:SetTexture("Interface\\Buttons\\WHITE8X8")
        frame.atrSolidBackground=fill
    end
    local r,g,b=frame:GetBackdropColor();fill:SetVertexColor(r,g,b,1)
    if not frame.atrTitle then
        frame.atrTitle=frame:CreateFontString(nil,"OVERLAY","GameFontNormal")
        frame.atrTitle:SetPoint("TOP",frame,"TOP",0,-12);frame.atrTitle:SetText("Buy item")
    end
    local function at(control,x,y,width,height)
        control:ClearAllPoints();control:SetPoint("TOPLEFT",frame,"TOPLEFT",x,-y)
        if width then control:SetWidth(width) end
        if height then control:SetHeight(height) end
    end
    at(Atr_Buy_Confirm_ItemName,20,40,400,32);Atr_Buy_Confirm_ItemName:SetJustifyH("LEFT")
    at(Atr_Buy_Confirm_ItemPriceText,20,82);Atr_Buy_Confirm_ItemPriceText:SetJustifyH("LEFT")
    Atr_Buy_Confirm_ItemPrice:ClearAllPoints();Atr_Buy_Confirm_ItemPrice:SetPoint("TOPLEFT",frame,"TOPLEFT",140,-80)
    for _,part in ipairs({Atr_Buy_Part1,Atr_Buy_Part2}) do
        part:ClearAllPoints();part:SetPoint("TOPLEFT",frame,"TOPLEFT",0,0)
        part:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",0,98)
    end
    Atr_AnalysisSkin(Atr_Buy_Confirm_Numstacks,"EditBox")
    at(Atr_Buy_Confirm_Text1,20,111,110,22)
    Atr_Buy_Confirm_Text1:SetJustifyH("LEFT");Atr_Buy_Confirm_Text1:SetJustifyV("MIDDLE")
    at(Atr_Buy_Confirm_Numstacks,140,111,50,22)
    Atr_Buy_Confirm_Max_Text:ClearAllPoints()
    Atr_Buy_Confirm_Max_Text:SetPoint("LEFT",Atr_Buy_Confirm_Numstacks,"RIGHT",12,0)
    Atr_Buy_Confirm_Max_Text:SetWidth(210);Atr_Buy_Confirm_Max_Text:SetHeight(22)
    Atr_Buy_Confirm_Max_Text:SetFontObject(GameFontHighlightSmall)
    Atr_Buy_Confirm_Max_Text:SetJustifyH("LEFT");Atr_Buy_Confirm_Max_Text:SetJustifyV("MIDDLE")
    Atr_Buy_Confirm_Max_Text:SetTextColor(.8,.8,.8,1)
    at(Atr_Buy_Confirm_Text2,20,150)
    Atr_Buy_Confirm_TotalPrice:ClearAllPoints();Atr_Buy_Confirm_TotalPrice:SetPoint("TOPLEFT",frame,"TOPLEFT",140,-148)
    at(Atr_Buy_Confirm_Item_Total,140,172,280,16)
    Atr_Buy_Confirm_Item_Total:SetFontObject(GameFontHighlightSmall)
    Atr_Buy_Confirm_Item_Total:SetTextColor(.8,.8,.8,1);Atr_Buy_Confirm_Item_Total:SetJustifyH("LEFT")
    at(Atr_Buy_NumAvail_Text,20,116,400,20);Atr_Buy_NumAvail_Text:SetJustifyH("LEFT")
    at(Atr_Buy_Continue_Text,20,150,400,20);Atr_Buy_Continue_Text:SetJustifyH("LEFT")
    if frame.atrVisitCount then at(frame.atrVisitCount,20,202,400,16) end
    if frame.atrVisitSpent then at(frame.atrVisitSpent,20,220,400,16) end
    for _,button in ipairs({Atr_Buy_Confirm_OKBut,Atr_Buy_Confirm_CancelBut}) do
        Atr_AnalysisSkin(button,"Button");button:SetSize(110,24);button:ClearAllPoints()
    end
    Atr_Buy_Confirm_CancelBut:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-20,14)
    Atr_Buy_Confirm_OKBut:SetPoint("RIGHT",Atr_Buy_Confirm_CancelBut,"LEFT",-10,0)
    updateBuyDialogLabels()
end
AuctionatorRemastered.Legacy.Hook("Atr_Buy_Confirm_Update",function()
    if Atr_Buy_Confirm_Frame and Atr_Buy_Confirm_Frame:IsShown() then updateBuyDialogLabels() end
end)

-- A reversible Deals-style shell for all three stock Auctionator panes.
local nativeBuy={regions={},seen={},backdrops={},stripes={},geometry={}}
local function restoreNativeBuy()
    if not nativeBuy.active then return end
    Atr_AnalysisEnd(nativeBuy.artwork or {})
    for _,saved in ipairs(nativeBuy.regions) do
        if saved.shown then saved.region:Show() else saved.region:Hide() end
    end
    for frame,saved in pairs(nativeBuy.backdrops) do
        frame:SetBackdrop(saved.backdrop)
        if saved.color then frame:SetBackdropColor(unpack(saved.color)) end
        if saved.border then frame:SetBackdropBorderColor(unpack(saved.border)) end
    end
    for frame,saved in pairs(nativeBuy.geometry) do
        frame:ClearAllPoints()
        for _,point in ipairs(saved.points) do frame:SetPoint(unpack(point)) end
        frame:SetWidth(saved.width);frame:SetHeight(saved.height)
    end
    nativeBuy.geometry={}
    for _,stripe in pairs(nativeBuy.stripes) do stripe:Hide() end
    nativeBuy.shell:Hide()
    nativeBuy.active=false;nativeBuy.regions={};nativeBuy.seen={};nativeBuy.backdrops={}
end
local function syncNativeBuyHeadings()
    if not nativeBuy.active then return end
    if Atr_HeadingsBar and Atr_HeadingsBar:IsShown() then nativeBuy.shell.headings:Show()
    else nativeBuy.shell.headings:Hide() end
end
local function styleNativeBuy()
    local skinned=ElvUI and AuctionFrame and AuctionFrame.backdrop
        and AuctionFrameBrowse and AuctionFrameBrowse.RightBackground
    local active=not skinned and Atr_Main_Panel and Atr_Main_Panel:IsShown()
        and Atr_IsTabSelected and (Atr_IsTabSelected(3) or Atr_IsTabSelected(1) or Atr_IsTabSelected(2))
    if not active then restoreNativeBuy();return end
    local selling,undercutting=Atr_IsTabSelected(1),Atr_IsTabSelected(2)
    local mode=selling and 1 or (undercutting and 2 or 3)
    if nativeBuy.active and nativeBuy.mode~=mode then restoreNativeBuy() end
    if not Atr_AnalysisBegin or not Atr_AnalysisFit or not Atr_AnalysisBackdrop then return end
    local function hide(region)
        if not region then return end
        if not nativeBuy.seen[region] then
            nativeBuy.seen[region]=true
            nativeBuy.regions[#nativeBuy.regions+1]={region=region,shown=region:IsShown()}
        end
        region:Hide()
    end
    if not nativeBuy.shell then
        local shell=CreateFrame('Frame',nil,AuctionFrame)
        shell:SetFrameLevel(AuctionFrame:GetFrameLevel())
        shell:EnableMouse(false)
        nativeBuy.shell=shell
        shell.results=CreateFrame('Frame',nil,shell)
        shell.results:SetFrameLevel(shell:GetFrameLevel())
        shell.results:SetPoint('TOPLEFT',Atr_Main_Panel,'TOPLEFT',0,-75)
        shell.results:SetPoint('BOTTOMRIGHT',AuctionFrame,'BOTTOMRIGHT',-12,48)
        Atr_AnalysisBackdrop(shell.results,1)
        shell.headings=CreateFrame('Frame',nil,shell)
        shell.headings:SetFrameLevel(shell:GetFrameLevel())
        shell.headings:SetPoint('LEFT',Atr_HeadingsBar,'LEFT',0,0)
        shell.headings:SetPoint('RIGHT',Atr_HeadingsBar,'RIGHT',0,0)
        shell.headings:SetHeight(20)
        Atr_AnalysisBackdrop(shell.headings,1)
        if Atr_SellControls then
            shell.sellSurface=CreateFrame('Frame',nil,shell)
            shell.sellSurface:SetFrameLevel(shell:GetFrameLevel())
            shell.sellSurface:SetPoint('TOPLEFT',Atr_SellControls,'TOPLEFT',0,-3)
            shell.sellSurface:SetPoint('BOTTOMRIGHT',Atr_SellControls,'BOTTOMRIGHT',0,0)
            Atr_AnalysisBackdrop(shell.sellSurface,1)
        end
    end
    Atr_AnalysisFit(nativeBuy.shell)
    if not nativeBuy.active then
        nativeBuy.artwork=Atr_AnalysisBegin(nativeBuy.shell)
        nativeBuy.active=true
        nativeBuy.mode=mode
    end
    Atr_AnalysisBackdrop(nativeBuy.shell,1,"shell")
    Atr_AnalysisBackdrop(nativeBuy.shell.results,1,"body")
    Atr_AnalysisBackdrop(nativeBuy.shell.headings,1,"heading")
    if nativeBuy.shell.sellSurface then
        Atr_AnalysisBackdrop(nativeBuy.shell.sellSurface,1,"sidebar")
    end
    nativeBuy.shell:Show()
    if nativeBuy.shell.sellSurface then
        if selling then nativeBuy.shell.sellSurface:Show() else nativeBuy.shell.sellSurface:Hide() end
    end
    if selling and Atr_SellControls then
        if not nativeBuy.backdrops[Atr_SellControls] then
            nativeBuy.backdrops[Atr_SellControls]={backdrop=Atr_SellControls:GetBackdrop(),
                color={Atr_SellControls:GetBackdropColor()},border={Atr_SellControls:GetBackdropBorderColor()}}
        end
        Atr_SellControls:SetBackdrop(nil)
    end
    -- Match the pair's outer edges to the full-width shopping-list buttons.
    local full=not selling and not undercutting and Atr_SrchSListButton
    if full then
        for _,spec in ipairs({{'Atr_AddToSListButton','BOTTOMLEFT','TOPLEFT'},
            {'Atr_RemFromSListButton','BOTTOMRIGHT','TOPRIGHT'}}) do
            local button=_G[spec[1]]
            if button then
                if not nativeBuy.geometry[button] then
                    local saved={width=button:GetWidth(),height=button:GetHeight(),points={}}
                    for i=1,button:GetNumPoints() do saved.points[i]={button:GetPoint(i)} end
                    nativeBuy.geometry[button]=saved
                end
                -- UIPanelButton artwork has transparent end padding. Match its
                -- visible ends, and overlap the padding between the two buttons.
                local inset,overlap=2,2
                local x=spec[2]=='BOTTOMLEFT' and inset or -inset
                button:ClearAllPoints();button:SetPoint(spec[2],full,spec[3],x,0)
                button:SetWidth((full:GetWidth()-inset*2+overlap)/2)
            end
        end
    end
    -- Align to the live button edge, including differing effective UI scales.
    local bottom=38
    local bottomControl=selling and Atr_SellControls or (undercutting and Atr_Hlist or Atr_NewSListButton)
    if bottomControl and bottomControl:GetBottom() and AuctionFrame:GetBottom() then
        bottom=(bottomControl:GetBottom()*bottomControl:GetEffectiveScale()
            -AuctionFrame:GetBottom()*AuctionFrame:GetEffectiveScale())/nativeBuy.shell.results:GetEffectiveScale()
    end
    nativeBuy.shell.results:ClearAllPoints()
    nativeBuy.shell.results:SetPoint('TOPLEFT',Atr_Main_Panel,'TOPLEFT',0,-75)
    nativeBuy.shell.results:SetPoint('BOTTOMRIGHT',AuctionFrame,'BOTTOMRIGHT',-12,bottom)
    syncNativeBuyHeadings()
    hide(Atr_HeadingsBarMiddle)
    for index=1,4 do
        local tab=_G['Atr_ListTabsTab'..index]
        if tab then
            if not nativeBuy.backdrops[tab] then
                nativeBuy.backdrops[tab]={backdrop=tab:GetBackdrop(),
                    color=tab.GetBackdropColor and {tab:GetBackdropColor()},
                    border=tab.GetBackdropBorderColor and {tab:GetBackdropBorderColor()}}
            end
            for _,region in ipairs({tab:GetRegions()}) do
                if region:IsObjectType('Texture') then hide(region) end
            end
            Atr_AnalysisBackdrop(tab,1,"tab")
        end
    end
    for index=1,12 do
        local row=_G['AuctionatorEntry'..index]
        if row then
            local stripe=nativeBuy.stripes[index]
            if not stripe then
                stripe=row:CreateTexture(nil,'BACKGROUND');stripe:SetAllPoints(row)
                stripe:SetTexture(1,1,1,index%2==0 and .035 or 0)
                nativeBuy.stripes[index]=stripe
            end
            if type(ElvUI)~='table' then
                stripe:SetTexture(.75,.68,.55,index%2==0 and .065 or 0)
            else
                stripe:SetTexture(1,1,1,index%2==0 and .035 or 0)
            end
            stripe:Show()
        end
    end
end

-- Defer until all tab/skin hooks have finished; never replace their handlers.
local pending = CreateFrame("Frame")
pending:Hide()
local function schedule()
    pending:Show()
end
pending:SetScript("OnUpdate", function(self)
    self:Hide()
    skinAuctionTabs()
    skinLiveButtons()
    if Atr_FullScanFrame and Atr_FullScanFrame:IsShown() and Atr_StyleFullScanDialog then
        Atr_StyleFullScanDialog()
    end
    if Atr_Buy_Confirm_Frame and Atr_Buy_Confirm_Frame:IsShown() then Atr_StyleBuyConfirmDialog() end
    fixLayout()
    fixNativeSellLayout()
    styleHistoryList()
    styleNativeBuy()
end)
AuctionatorRemastered.Legacy.Hook("Atr_AuctionFrameTab_OnClick", function()
    if nativeBuy.active and not (Atr_IsTabSelected(3) or Atr_IsTabSelected(1) or Atr_IsTabSelected(2)) then restoreNativeBuy() end
    if Atr_Main_Panel and not Atr_Main_Panel:IsShown() and moneyOriginal then
        local money = AuctionFrameMoneyFrame
        money:SetParent(moneyOriginal.parent)
        money:ClearAllPoints()
        for _, point in ipairs(moneyOriginal.points) do money:SetPoint(unpack(point)) end
        moneyOriginal = nil
    end
    schedule()
end)
local lastPerItem
AuctionatorRemastered.Legacy.Hook("Atr_UpdateUI", function()
    -- The core restores 805x341 on ordinary empty-Sell updates, not just tab
    -- switches. Correct it after every update, including when perItem is stable.
    fixDropTarget()
    syncNativeBuyHeadings()
    local perItem = Atr_ItemPrice and Atr_ItemPrice:IsShown() or false
    if perItem ~= lastPerItem then
        lastPerItem = perItem
        schedule()
    end
end)
AuctionatorRemastered.Legacy.Hook("Atr_ListTabOnClick", schedule)
AuctionatorRemastered.Legacy.Hook("Atr_ShowCurrentAuctions", schedule)
AuctionatorRemastered.Legacy.Hook("Atr_ShowHistory", schedule)
AuctionatorRemastered.Legacy.Hook("Atr_ShowSearchSummary", schedule)
AuctionatorRemastered.Legacy.Hook("Atr_ShowHide_StartingPrice", schedule)
AuctionatorRemastered.Legacy.Hook("Atr_ShowFullScanFrame",schedule)
AuctionatorRemastered.Legacy.Hook("Atr_Buy1_Onclick",schedule)
AuctionatorRemastered.Legacy.Hook("Atr_Init", function()
    if Atr_Main_Panel then
        Atr_Main_Panel:HookScript("OnShow", schedule)
        Atr_Main_Panel:HookScript("OnHide", restoreNativeBuy)
    end
    if AuctionFrame then AuctionFrame:HookScript("OnHide", restoreNativeBuy) end
    schedule()
end)
