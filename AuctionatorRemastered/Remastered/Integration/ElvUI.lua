-- Remastered owns its addon controls. The legacy AddOnSkins callback targets
-- Auctionator 2.6.3 and must not run, regardless of the user's skin checkbox.
-- Standard appearance also skips the AH skin; other ElvUI skins are unchanged.
local function blockLegacyAuctionatorSkin()
    local engine=type(ElvUI)=="table" and ElvUI[1]
    if not engine or type(engine.GetModule)~="function" then return end
    -- ElvUI removes a skin's registration flag before dispatching it. Guard
    -- dispatch as well, including callbacks queued during its initialization.
    local registry=engine.callbacks
    if registry and type(registry.Fire)=="function" and not registry.atrRemasteredSkinGuard then
        local fire=registry.Fire
        registry.Fire=function(self,event,...)
            if event=="Auctionator" then return end
            if event=="Skin_Blizzard_AuctionUI" and AuctionatorRemastered.UI.themeMode=="native" then return end
            return fire(self,event,...)
        end
        registry.atrRemasteredSkinGuard=true
    end
    local ok,skins=pcall(engine.GetModule,engine,"Skins",true)
    if not ok or not skins then return end
    if not skins.atrRemasteredSkinGuard and type(skins.AddCallbackForAddon)=="function" then
        local original=skins.AddCallbackForAddon
        skins.AddCallbackForAddon=function(self,addon,event,...)
            if addon=="Auctionator" and event=="Auctionator" then return end
            if AuctionatorRemastered.UI.themeMode=="native" and addon=="Blizzard_AuctionUI"
                and event=="Skin_Blizzard_AuctionUI" then return end
            return original(self,addon,event,...)
        end
        skins.atrRemasteredSkinGuard=true
    end
    -- AddOnSkins may have registered before Auctionator's files were loaded.
    local callbacks=skins.addonCallbacks and skins.addonCallbacks.Auctionator
    if callbacks and callbacks.Auctionator then
        callbacks.Auctionator=nil
        for i=#(callbacks.CallPriority or {}),1,-1 do
            if callbacks.CallPriority[i]=="Auctionator" then table.remove(callbacks.CallPriority,i) end
        end
    end
    if AuctionatorRemastered.UI.themeMode=="native" then
        local auction=skins.addonCallbacks and skins.addonCallbacks.Blizzard_AuctionUI
        if auction and auction.Skin_Blizzard_AuctionUI then
            auction.Skin_Blizzard_AuctionUI=nil
            for i=#(auction.CallPriority or {}),1,-1 do
                if auction.CallPriority[i]=="Skin_Blizzard_AuctionUI" then table.remove(auction.CallPriority,i) end
            end
        end
    end
end
blockLegacyAuctionatorSkin()
local skinGuardEvents=CreateFrame("Frame")
skinGuardEvents:RegisterEvent("ADDON_LOADED")
skinGuardEvents:RegisterEvent("VARIABLES_LOADED")
skinGuardEvents:RegisterEvent("PLAYER_LOGIN")
skinGuardEvents:SetScript("OnEvent",function() blockLegacyAuctionatorSkin() end)

-- Compatibility geometry for the 3.1.5 layout and ElvUI's AH skin.
local place=AuctionatorRemastered.UI.AuctionLayout.Place

local function fixDropTarget()
    if not AuctionatorRemastered.UI.UseElvUI() or not Atr_Main_Panel or not Atr_Main_Panel:IsShown()
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
    if not AuctionatorRemastered.UI.UseElvUI() then return end
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
    if not AuctionatorRemastered.UI.UseElvUI() then return end
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
local function fixLayout()
    if not AuctionatorRemastered.UI.UseElvUI() or not Atr_Main_Panel or not Atr_Main_Panel:IsShown() then return end
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
        -- Reserve the Per Item row even when hidden, so changing items does
        -- not move Create Auction, the footer or the panel boundary.
        local createY = 174
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
local function restoreMoney()
    if Atr_Main_Panel and not Atr_Main_Panel:IsShown() and moneyOriginal then
        local money = AuctionFrameMoneyFrame
        money:SetParent(moneyOriginal.parent)
        money:ClearAllPoints()
        for _, point in ipairs(moneyOriginal.points) do money:SetPoint(unpack(point)) end
        moneyOriginal = nil
    end
end

AuctionatorRemastered.UI.ElvUI={
    FixLayout=fixLayout,
    FixDropTarget=fixDropTarget,
    SkinTabs=skinAuctionTabs,
    SkinButtons=skinLiveButtons,
    RestoreMoney=restoreMoney,
}
