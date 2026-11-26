local Elv=AuctionatorRemastered.UI.ElvUI
local Layout=AuctionatorRemastered.UI.AuctionLayout
local Dialogs=AuctionatorRemastered.UI.AuctionDialogs

-- Defer until all tab/skin hooks have finished; never replace their handlers.
local pending = CreateFrame("Frame")
pending:Hide()
local function schedule()
    pending:Show()
end
pending:SetScript("OnUpdate", function(self)
    self:Hide()
    Elv.SkinTabs()
    Elv.SkinButtons()
    Dialogs.StyleAdvancedButton()
    if Atr_FullScanFrame and Atr_FullScanFrame:IsShown() and Atr_StyleFullScanDialog then
        Atr_StyleFullScanDialog()
    end
    if Atr_Buy_Confirm_Frame and Atr_Buy_Confirm_Frame:IsShown() then Atr_StyleBuyConfirmDialog() end
    Elv.FixLayout()
    Layout.FixSell()
    Layout.StyleSidebar()
    Layout.Apply()
    if AuctionatorRemastered.UI.RefreshAuctionBackgrounds then AuctionatorRemastered.UI.RefreshAuctionBackgrounds() end
end)
AuctionatorRemastered.Legacy.Hook("Atr_AuctionFrameTab_OnClick", function()
    if Layout.IsActive() and not (Atr_IsTabSelected(3) or Atr_IsTabSelected(1) or Atr_IsTabSelected(2)) then Layout.Restore() end
    Elv.RestoreMoney()
    schedule()
end)
local lastPerItem
AuctionatorRemastered.Legacy.Hook("Atr_UpdateUI", function()
    -- The core restores 805x341 on ordinary empty-Sell updates, not just tab
    -- switches. Correct it after every update, including when perItem is stable.
    Elv.FixDropTarget()
    Layout.SyncHeadings()
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
        Atr_Main_Panel:HookScript("OnHide", Layout.Restore)
    end
    if AuctionFrame then AuctionFrame:HookScript("OnHide", Layout.Restore) end
    schedule()
end)

-- FauxScrollFrame_Update can change scrollbar visibility without a tab change.
-- Recalculate decorative row bounds after those handlers finish.
local sidebarScroll=Atr_Hlist_ScrollFrame
local sidebarBar=sidebarScroll and (sidebarScroll.ScrollBar or _G[sidebarScroll:GetName().."ScrollBar"])
for _,frame in ipairs({sidebarScroll,sidebarBar}) do
    if not frame.atrSidebarVisibilityWatched then
        frame:HookScript("OnShow",schedule)
        frame:HookScript("OnHide",schedule)
        frame.atrSidebarVisibilityWatched=true
    end
end
