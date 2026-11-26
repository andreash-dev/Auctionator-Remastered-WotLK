local Options=AuctionatorRemastered.UI.Options

local optionHelp={
    oldPrices={"Old saved prices","Mark the Updated time in orange when a saved price reaches this age in Offline Browser and Deals. The default is 1 day. Disabled hides the warning. Prices are never hidden or deleted by this setting. Changes apply immediately."},
    message={"Full Scan chat summary","Show the scan summary in chat after a completed fast or slow Full Scan. The results window remains available when this is off. Partial-scan warnings are still shown."},
    sound={"Full Scan completion sound","Play the ready-check sound after a fast or slow Full Scan finishes saving successfully. Cancelled, failed and partial scans do not play this sound. Off by default."},
    ATR_tipsVendorOpt={"Vendor prices","Show the amount an NPC vendor pays for the item. This is the sell-to-vendor value, not the price to buy it from a vendor."},
    ATR_tipsAuctionOpt={"Auction house prices","Show the item's saved auction-house price in its tooltip. Prices come from your collected auction data and may differ from current live listings."},
    ATR_tipsDisenchantOpt={"Disenchant value","Show the estimated gross value of disenchant materials using their latest saved lowest AH prices. Missing material prices show unknown. Prices older than 24 hours or from partial scans are marked. Actual results vary; auction fees are not deducted."},
    Atr_tipsShiftDD={"Prices while holding Shift","Choose whether holding Shift shows the total stack price or the price per item. Releasing Shift shows the other view. Stack totals require a known stack quantity."},
    Atr_deDetailsDD={"Disenchanting details","Choose when to show the material breakdown for equipment that can be disenchanted: while holding Shift, Control or Alt, always, or never. This controls the breakdown separately from the estimated-value checkbox."},
    theme={"Interface style","Standard WoW uses Auctionator Remastered's native theme, even when ElvUI is installed. ElvUI is available only when that addon is present. Use Reload UI after changing the style. Other ElvUI windows are unaffected."},
    browserBackground={"Offline Browser background","Use a translucent background in the Offline Browser. Turn this off for an opaque background. Text and item icons remain fully visible."},
    shoppingBackground={"Shopping planner background","Use a translucent background in the shopping planner. This setting is independent of the Offline Browser and applies immediately."},
    movement={"Move the auction window","Allow dragging the auction-house title to move the window. Its position is saved automatically. Turn this off to lock it in place. The Deal details window can also be dragged to detach it."},
    resetAuction={"Reset auction window","Return the auction window to its original position and remove its saved position. Prices, history and shopping lists are kept."},
    resetDetails={"Reset Deal details","Return the detached Deal details window beside the auction house and make it follow the auction window again. No auction data is removed."},
    quality={"Minimum quality level","Choose the lowest item quality included in saved full-scan prices. Higher qualities are included too. Poor (all) includes every quality. This changes which prices are collected, not which auctions exist on the auction house."},
    retention={"Price-history retention","Choose how many days of historical prices to keep (1–3650). Reducing this value requires confirmation when saving. Older history is permanently removed during the next startup or UI reload. Raising the value cannot restore deleted history."},
    market={"Market % comparison","Choose how many past days are used for the reference price behind Market %. The reference is the median of daily scan medians, excluding today; older history may use daily lows. An asterisk means fewer than three history days are available. This choice applies immediately."},
    Atr_ShowIncompleteBrowserItems={"Show incomplete items","Include saved items whose category or equipment slot is not yet known in the Offline Browser. Turning this off only hides those entries; their prices and history are kept, and shopping lists are unaffected."},
}
local function attachOptionHelp(control,help,owner)
    if not control or control.atrOptionHelp then return end
    control.atrOptionHelp=true
    control:EnableMouse(true)
    control:HookScript("OnEnter",function(self)
        GameTooltip:SetOwner(owner or self,"ANCHOR_LEFT")
        GameTooltip:SetText(help[1],.9,1,1)
        GameTooltip:AddLine(help[2],.5,.5,1,true)
        GameTooltip:Show()
    end)
    control:HookScript("OnLeave",function() GameTooltip:Hide() end)
end
local function attachOptionLabelHelp(label,panel,help,owner)
    if not label or label.atrHelpArea then return end
    local area=CreateFrame("Frame",nil,panel)
    area:SetAllPoints(label)
    attachOptionHelp(area,help,owner)
    label.atrHelpArea=area
end
Options.Help=optionHelp
Options.BindHelp=attachOptionHelp
Options.BindLabelHelp=attachOptionLabelHelp

function Options.SetupHelp(panel)
    if panel==Atr_TooltipsOptionsFrame then
        for _,name in ipairs({"ATR_tipsVendorOpt","ATR_tipsAuctionOpt","ATR_tipsDisenchantOpt"}) do
            local group,choice=_G[name],_G[name.."_CB"]
            -- The old row spans the page and extends below its checkbox. Only
            -- the actual checkbox and its text should receive mouse hover.
            if group then group:EnableMouse(false) end
            attachOptionHelp(choice,optionHelp[name])
            attachOptionLabelHelp(_G[name.."_CB_Text"],panel,optionHelp[name],choice)
        end
        for _,label in ipairs({panel:GetRegions()}) do
            if label:IsObjectType("FontString") then
                if label:GetText()=="When SHIFT is down show" then attachOptionLabelHelp(label,panel,optionHelp.Atr_tipsShiftDD)
                elseif label:GetText()=="Show disenchanting details" then attachOptionLabelHelp(label,panel,optionHelp.Atr_deDetailsDD) end
            end
        end
    elseif panel==Atr_AppearanceOptions then
        attachOptionHelp(Atr_AllowAuctionMovement,optionHelp.movement)
        attachOptionLabelHelp(_G["Atr_AllowAuctionMovementText"],panel,optionHelp.movement,Atr_AllowAuctionMovement)
        attachOptionHelp(Atr_ResetAuctionPosition,optionHelp.resetAuction)
        attachOptionHelp(Atr_ResetDetailsPosition,optionHelp.resetDetails)
        for _,entry in ipairs({{Atr_ThemeNative,optionHelp.theme},{Atr_ThemeElvUI,optionHelp.theme},
            {Atr_AppearanceBrowserTransparent,optionHelp.browserBackground},
            {Atr_AppearanceShoppingTransparent,optionHelp.shoppingBackground}}) do
            local control,help=entry[1],entry[2]
            attachOptionHelp(control,help)
            if control then attachOptionLabelHelp(_G[control:GetName().."Text"],panel,help,control) end
        end
    elseif panel==Atr_OfflineBrowserOptions then
        attachOptionHelp(Atr_ShowIncompleteBrowserItems,optionHelp.Atr_ShowIncompleteBrowserItems)
        attachOptionLabelHelp(_G["Atr_ShowIncompleteBrowserItemsText"],panel,optionHelp.Atr_ShowIncompleteBrowserItems,Atr_ShowIncompleteBrowserItems)
    end
end
