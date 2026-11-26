local Options={}
AuctionatorRemastered.UI.Options=Options

local optionPages={
    Atr_BasicOptionsFrame={"General","Shortcuts, bag behaviour and auction defaults."},
    Atr_AppearanceOptions={"Appearance","Window movement and saved positions."},
    Atr_TooltipsOptionsFrame={"Tooltips","Choose the prices and details shown in item tooltips."},
    Atr_OfflineBrowserOptions={"Offline Browser","Control which saved items appear in the offline browser."},
    Atr_StackingOptionsFrame={"Selling: stacks","Manage remembered stack sizes and auction quantities."},
    Atr_UCConfigFrame={"Selling: prices","Set undercut amounts and the starting-price discount."},
    Atr_ScanningOptionsFrame={"Database","Scan quality, history retention and Market % comparison."},
    Atr_DatabaseStatusOptions={"Database status","Recorded scan activity and price-history coverage."},
    AuctionatorResetsFrame={"Maintenance","Clear selected saved data. Each action requires confirmation."},
    AuctionatorDescriptionFrame={"About","Auctionator Remastered for World of Warcraft 3.3.5a."},
}
local function optionAt(region,panel,x,y)
    region:ClearAllPoints();region:SetPoint("TOPLEFT",panel,"TOPLEFT",x,-y)
end
Options.Place=optionAt

local function skinOptionControls(frame)
    if not AuctionatorRemastered.UI.UseElvUI() then return end
    for _,child in ipairs({frame:GetChildren()}) do
        if not child.atrOptionsSkinned then
            local kind=child:GetObjectType()
            local name=child:GetName()
            local styled
            if kind=="CheckButton" then
                local checked=child:GetChecked()
                styled=Atr_AnalysisSkin(child,"CheckBox")
                child:SetChecked(checked)
            elseif kind=="Button" then styled=Atr_AnalysisSkin(child,"Button")
            elseif kind=="EditBox" then styled=Atr_AnalysisSkin(child,"EditBox")
            elseif kind=="Frame" and name and _G[name.."Button"] and _G[name.."Text"] then
                styled=Atr_AnalysisSkin(child,"DropDownBox")
                child.atrOptionsDropdown=true
            end
            child.atrOptionsSkinned=styled or nil
        end
        if not child.atrOptionsDropdown then skinOptionControls(child) end
    end
end
function Atr_StyleOptionsPanel(panel)
    local spec=optionPages[panel:GetName()]
    if not spec then return end
    local width=math.max(300,panel:GetWidth()-48)
    Atr_StyleOfflineBrowser(panel,false,false)
    local chrome=panel.atrOptionsChrome
    if not chrome then
        chrome=CreateFrame("Frame",nil,panel);chrome:SetFrameLevel(panel:GetFrameLevel())
        chrome:EnableMouse(false)
        chrome:SetPoint("TOPLEFT",panel,"TOPLEFT",12,-76)
        chrome:SetPoint("BOTTOMRIGHT",panel,"BOTTOMRIGHT",-12,12)
        panel.atrOptionsChrome=chrome
    end
    Atr_StyleOfflineBrowser(chrome,true,false)
    local title=_G[panel:GetName().."_ATitle"] or panel.atrOptionsTitle
    local subtitle=_G[panel:GetName().."_BTitle"] or panel.atrOptionsSubtitle
    if not title then
        for _,region in ipairs({panel:GetRegions()}) do
            if region:IsObjectType("FontString") and region:GetText()==spec[1] then title=region;break end
        end
        title=title or panel:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
        panel.atrOptionsTitle=title
    end
    if not subtitle then
        -- Reuse the first help line on the two Lua-created settings pages.
        if panel==Atr_AppearanceOptions or panel==Atr_OfflineBrowserOptions then
            for _,region in ipairs({panel:GetRegions()}) do
                if region~=title and region:IsObjectType("FontString") then subtitle=region;break end
            end
        end
        subtitle=subtitle or panel:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        panel.atrOptionsSubtitle=subtitle
    end
    optionAt(title,panel,24,18);title:SetText(spec[1]);title:SetWidth(width);title:SetJustifyH("LEFT")
    optionAt(subtitle,panel,24,44);subtitle:SetText(spec[2]);subtitle:SetWidth(width)
    subtitle:SetHeight(26);subtitle:SetJustifyH("LEFT");subtitle:SetJustifyV("TOP")
    Options.SetupPreferences(panel)
    Options.PrepareLayout(panel,width,title,subtitle,chrome)
    skinOptionControls(panel)
    Options.Layout(panel)
    Options.SetupHelp(panel)
    Options.SetupAboutLinks(panel)
end
local function registerOptionsStyle(panel)
    if not panel or not optionPages[panel:GetName()] or panel.atrOptionsHooked then return end
    panel.name=optionPages[panel:GetName()][1]
    panel:HookScript("OnShow",Atr_StyleOptionsPanel)
    panel.atrOptionsHooked=true
end
if InterfaceOptions_AddCategory then hooksecurefunc("InterfaceOptions_AddCategory",registerOptionsStyle) end
for name in pairs(optionPages) do registerOptionsStyle(_G[name]) end

local saveScanningOptions=Atr_ScanningOptionsFrame_Save
if type(saveScanningOptions)=="function" then
    local function restoreRetentionField()
        Atr_ScanOpts_MaxHistAge:SetText(AUCTIONATOR_DB_MAXHIST_DAYS)
    end
    StaticPopupDialogs.ATR_CONFIRM_HISTORY_RETENTION={
        text="Reduce price-history retention from %d to %d days?\n\nOlder history will be permanently removed during the next startup or UI reload. Raising this value later cannot restore deleted history.\n\nMarket %% comparison does not delete history.",
        button1="Reduce retention",button2="Keep current",
        timeout=0,whileDead=true,hideOnEscape=true,
        OnAccept=function(self,data)
            data=data or self.data
            -- A pending confirmation must not overwrite a newer preference.
            if data and AUCTIONATOR_DB_MAXHIST_DAYS==data.previous then
                AUCTIONATOR_DB_MAXHIST_DAYS=data.days
            end
            restoreRetentionField()
        end,
        OnCancel=restoreRetentionField,
    }
    function Atr_ScanningOptionsFrame_Save(frame)
        if not frame.atr_hasBeenShown then return end
        local previous=tonumber(AUCTIONATOR_DB_MAXHIST_DAYS) or 30
        local days=tonumber(Atr_ScanOpts_MaxHistAge:GetText())
        StaticPopup_Hide("ATR_CONFIRM_HISTORY_RETENTION")
        if not days or days~=math.floor(days) or days<1 or days>3650 then
            restoreRetentionField()
            if UIErrorsFrame then UIErrorsFrame:AddMessage("Enter a whole number of days between 1 and 3650.",1,.3,.3) end
            return
        end
        if days>=previous then
            Atr_ScanOpts_MaxHistAge:SetText(days)
            return saveScanningOptions(frame)
        end
        -- Save the other database options while retaining the safe old limit.
        Atr_ScanOpts_MaxHistAge:SetText(previous)
        saveScanningOptions(frame)
        StaticPopup_Show("ATR_CONFIRM_HISTORY_RETENTION",previous,days,{previous=AUCTIONATOR_DB_MAXHIST_DAYS,days=days})
    end
    Atr_ScanningOptionsFrame.okay=Atr_ScanningOptionsFrame_Save
end
