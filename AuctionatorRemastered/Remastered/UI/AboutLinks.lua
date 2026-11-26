local Options=AuctionatorRemastered.UI.Options

-- WoW 3.3.5a cannot launch an external browser. Offer a selectable URL
-- rather than an Open button that cannot perform its advertised action.
local aboutLinkDialog
local function showAboutLink(title,url)
    if not aboutLinkDialog then
        local dialog=CreateFrame("Frame","Atr_AboutLinkDialog",UIParent)
        dialog:SetSize(480,164);dialog:SetFrameStrata("FULLSCREEN_DIALOG")
        dialog:SetClampedToScreen(true);dialog:EnableMouse(true)
        local heading=dialog:CreateFontString(nil,"OVERLAY","GameFontNormal")
        heading:SetPoint("TOP",dialog,"TOP",0,-16);dialog.heading=heading
        local help=dialog:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        help:SetPoint("TOPLEFT",dialog,"TOPLEFT",24,-46)
        help:SetText("Press Ctrl+C to copy, then paste into your browser.")
        local input=CreateFrame("EditBox","Atr_AboutLinkURL",dialog,"InputBoxTemplate")
        input:SetAutoFocus(false);input:SetSize(428,24)
        input:SetPoint("TOPLEFT",dialog,"TOPLEFT",28,-72)
        input:SetScript("OnEscapePressed",function() dialog:Hide() end)
        dialog.input=input
        local close=CreateFrame("Button",nil,dialog,"UIPanelButtonTemplate")
        close:SetSize(90,24);close:SetPoint("BOTTOMRIGHT",dialog,"BOTTOMRIGHT",-24,16)
        close:SetText("Close");close:SetScript("OnClick",function() dialog:Hide() end)
        Atr_AnalysisSkin(input,"EditBox");Atr_AnalysisSkin(close,"Button")
        dialog:SetScript("OnHide",function() input:ClearFocus() end)
        if UISpecialFrames then table.insert(UISpecialFrames,"Atr_AboutLinkDialog") end
        aboutLinkDialog=dialog
    end
    local dialog=aboutLinkDialog
    Atr_StyleOfflineBrowser(dialog,false,false)
    dialog:ClearAllPoints()
    dialog:SetPoint("CENTER",InterfaceOptionsFrame or UIParent,"CENTER",0,0)
    dialog.heading:SetText(title);dialog.input:SetText(url)
    dialog:Show();dialog.input:SetFocus();dialog.input:HighlightText()
end
function Options.SetupAboutLinks(panel)
    if panel~=AuctionatorDescriptionFrame then return end
    -- The authors are credited in the main text; keep only the version footer.
    for _,region in ipairs({panel:GetRegions()}) do
        if region:IsObjectType("FontString") and region:GetText()=="Remastered by Nisho  |  Original Auctionator by Zirco" then
            region:Hide()
        end
    end
    if AuctionatorVersionText then
        AuctionatorVersionText:ClearAllPoints()
        AuctionatorVersionText:SetPoint("BOTTOMLEFT",panel,"BOTTOMLEFT",24,20)
    end
    if panel.atrProjectLinks then return end
    panel.atrProjectLinks={}
    for index,entry in ipairs({
        {"GitHub","https://github.com/andreash-dev/Auctionator-Remastered-WotLK"},
        {"Warperia","https://warperia.com/addon-wotlk/auctionator-remastered/"}
    }) do
        local name,url=entry[1],entry[2]
        local link=CreateFrame("Button",nil,panel)
        link.atrOptionsSkinned=true -- Text link, not an ElvUI action button.
        link:SetSize(80,20);link:SetPoint("BOTTOMRIGHT",panel,"BOTTOMRIGHT",-24-(2-index)*92,16)
        local label=link:CreateFontString(nil,"OVERLAY","GameFontHighlight")
        label:SetAllPoints(link);label:SetJustifyH("RIGHT");label:SetText("|cff3399ff"..name.."|r")
        link:SetScript("OnEnter",function() label:SetText("|cff88ccff"..name.."|r") end)
        link:SetScript("OnLeave",function() label:SetText("|cff3399ff"..name.."|r") end)
        link:SetScript("OnClick",function() showAboutLink(name,url) end)
        panel.atrProjectLinks[index]=link
    end
end
