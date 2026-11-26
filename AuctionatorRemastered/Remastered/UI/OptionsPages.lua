local Options=AuctionatorRemastered.UI.Options
local optionAt=Options.Place
local optionHelp=Options.Help
local attachOptionLabelHelp=Options.BindLabelHelp

function Options.SetupPreferences(panel)
    local UI=AuctionatorRemastered.UI
    local function saved()
        AUCTIONATOR_SAVEDVARS=AUCTIONATOR_SAVEDVARS or {}
        return AUCTIONATOR_SAVEDVARS
    end
    if panel==Atr_BasicOptionsFrame then
        for _,spec in ipairs({
            {"Atr_ScanCompleteMessage","Show Full Scan summary in chat","message","scanCompleteMessage",342},
            {"Atr_ScanCompleteSound","Play a sound when Full Scan completes","sound","scanCompleteSound",378},
        }) do
            local choice=_G[spec[1]]
            if not choice then
                local key=spec[4]
                choice=CreateFrame("CheckButton",spec[1],panel,"UICheckButtonTemplate")
                local label=_G[spec[1].."Text"]
                label:SetText(spec[2]);label:SetTextColor(1,1,1)
                choice:SetScript("OnClick",function(self) saved()[key]=self:GetChecked() and true or false end)
                Options.BindHelp(choice,Options.Help[spec[3]])
                attachOptionLabelHelp(label,panel,Options.Help[spec[3]],choice)
            end
            optionAt(choice,panel,24,spec[5]);choice:SetSize(24,24)
            choice:SetChecked(UI.ScanNotification(spec[3]))
        end
    elseif panel==Atr_TooltipsOptionsFrame then
        local choice=Atr_ProspectingTips
        if not choice then
            choice=CreateFrame("CheckButton","Atr_ProspectingTips",panel,"UICheckButtonTemplate")
            local label=Atr_ProspectingTipsText
            label:SetText("Prospecting: show value / 5 ore");label:SetTextColor(1,1,1)
            choice:SetScript("OnClick",function(self) saved().prospectingTips=self:GetChecked() and true or false end)
            local help={"Prospecting value","Estimated material value from five ore, using each material's latest saved lowest AH price. Choose below when to show possible gems and powders, including drop chances, quantities and lowest unit prices. WotLK estimates may differ from server drop rates; AH fees are excluded."}
            Options.BindHelp(choice,help);attachOptionLabelHelp(label,panel,help,choice)
        end
        optionAt(choice,panel,24,322);choice:SetSize(24,24)
        choice:SetChecked(not AUCTIONATOR_SAVEDVARS or AUCTIONATOR_SAVEDVARS.prospectingTips~=false)
        if not Atr_ProspectingDetails then
            local label=panel:CreateFontString(nil,"ARTWORK","GameFontNormal")
            optionAt(label,panel,24,352);label:SetText("Show prospecting details")
            attachOptionLabelHelp(label,panel,{"Prospecting details","Choose when to show possible materials and their lowest unit prices. This is separate from the estimated value per five ore."})
            local dropdown=CreateFrame("Frame","Atr_ProspectingDetails",panel,"UIDropDownMenuTemplate")
            UIDropDownMenu_Initialize(dropdown,function()
                for _,spec in ipairs({{"shift","when SHIFT is held down"},{"control","when CONTROL is held down"},{"alt","when ALT is held down"},{"never","never"},{"always","always"}}) do
                    local mode,caption=spec[1],spec[2]
                    local info=UIDropDownMenu_CreateInfo()
                    info.text=caption;info.value=mode
                    info.checked=UI.ProspectingDetailsMode()==mode
                    info.func=function()
                        saved().prospectingDetails=mode
                        UIDropDownMenu_SetSelectedValue(dropdown,mode)
                        UIDropDownMenu_SetText(dropdown,caption)
                    end
                    UIDropDownMenu_AddButton(info)
                end
            end)
        end
        local mode=UI.ProspectingDetailsMode()
        local captions={shift="when SHIFT is held down",control="when CONTROL is held down",alt="when ALT is held down",never="never",always="always"}
        UIDropDownMenu_SetSelectedValue(Atr_ProspectingDetails,mode)
        UIDropDownMenu_SetText(Atr_ProspectingDetails,captions[mode])
    elseif panel==Atr_ScanningOptionsFrame then
        if not Atr_OldPriceDays then
            local label=panel:CreateFontString(nil,"ARTWORK","GameFontNormal")
            optionAt(label,panel,24,338);label:SetText("Mark saved prices as old after:")
            attachOptionLabelHelp(label,panel,Options.Help.oldPrices)
            local dropdown=CreateFrame("Frame","Atr_OldPriceDays",panel,"UIDropDownMenuTemplate")
            UIDropDownMenu_Initialize(dropdown,function()
                for _,days in ipairs({0,1,3,7,14,30}) do
                    local value=days
                    local info=UIDropDownMenu_CreateInfo()
                    info.text=days==0 and "Disabled" or days..(days==1 and " day" or " days")
                    info.value=days;info.checked=UI.PriceAgeDays()==days
                    info.func=function()
                        saved().oldPriceDays=value
                        UIDropDownMenu_SetSelectedValue(dropdown,value)
                        UIDropDownMenu_SetText(dropdown,value==0 and "Disabled" or value..(value==1 and " day" or " days"))
                        if UI.RefreshBrowserPriceAge then UI.RefreshBrowserPriceAge() end
                        if UI.RefreshDealsPriceAge then UI.RefreshDealsPriceAge() end
                    end
                    UIDropDownMenu_AddButton(info)
                end
            end)
        end
        local days=UI.PriceAgeDays()
        UIDropDownMenu_SetSelectedValue(Atr_OldPriceDays,days)
        UIDropDownMenu_SetText(Atr_OldPriceDays,days==0 and "Disabled" or days..(days==1 and " day" or " days"))
    end
end

local function normalizeOptionCheckboxes(frame)
    for _,child in ipairs({frame:GetChildren()}) do
        if child:GetObjectType()=="CheckButton" then
            child:SetSize(24,24)
            local label=child:GetName() and (_G[child:GetName().."Text"] or _G[child:GetName().."_Text"])
            if label then
                label:ClearAllPoints();label:SetPoint("LEFT",child,"RIGHT",8,0)
            end
            -- Some newer controls keep their label on the containing page.
            for _,region in ipairs({frame:GetRegions()}) do
                if region:IsObjectType("FontString") then
                    local _,relative=region:GetPoint(1)
                    if relative==child then
                        region:ClearAllPoints();region:SetPoint("LEFT",child,"RIGHT",8,0)
                    end
                end
            end
        end
        if not child.atrOptionsDropdown then normalizeOptionCheckboxes(child) end
    end
end
local function layoutOptionRows(panel)
    local function at(name,x,y)
        local control=_G[name]
        if control then optionAt(control,panel,x,y) end
    end
    local groups=panel==Atr_BasicOptionsFrame and {
        "AuctionatorOption_Enable_Alt","AuctionatorOption_Open_All_Bags","AuctionatorOption_Show_StartingPrice"
    } or panel==Atr_TooltipsOptionsFrame and {"ATR_tipsVendorOpt","ATR_tipsAuctionOpt","ATR_tipsDisenchantOpt"}
    if groups then
        for index,name in ipairs(groups) do
            local group=_G[name]
            if group then
                local y=panel==Atr_TooltipsOptionsFrame and ({92,122,224})[index] or 92+(index-1)*36
                optionAt(group,panel,24,y)
                group:SetWidth(math.max(240,panel:GetWidth()-48));group:SetHeight(32)
                group:EnableMouse(true)
                local choice=_G[name.."_CB"]
                if choice then optionAt(choice,group,0,0) end
            end
        end
    end
    local function dropdown(name,y)
        local control=_G[name]
        if not control then return end
        local function align()
            optionAt(control,panel,4,y) -- Both skins inset the visible box by 20.
            if AuctionatorRemastered.UI.UseElvUI() then
                control:SetWidth(220)
                local label=_G[name.."Text"]
                local button=_G[name.."Button"]
                if label and button then
                    -- HandleDropDownBox initially anchors text to the arrow;
                    -- legacy OnShow later resets justification/width. Set both
                    -- edges explicitly after either path, including first open.
                    label:ClearAllPoints()
                    if control.backdrop then label:SetPoint("LEFT",control.backdrop,"LEFT",8,0)
                    else label:SetPoint("LEFT",control,"LEFT",28,0) end
                    label:SetPoint("RIGHT",button,"LEFT",-6,0)
                    label:SetJustifyH("LEFT")
                end
            else
                UIDropDownMenu_SetWidth(control,188)
                UIDropDownMenu_JustifyText(control,"LEFT")
            end
            if name=="Atr_MarketHistoryDropdown" then
                -- SetSelectedValue may leave a blank caption before its menu
                -- has been populated, or after the skin rebuilds the box.
                UIDropDownMenu_SetText(control,Atr_GetMarketHistoryDays().." days")
            end
        end
        align()
        if not control.atrOptionsAligned then
            control:HookScript("OnShow",align)
            control.atrOptionsAligned=true
        end
    end
    if panel==Atr_BasicOptionsFrame then
        at("AuctionatorOption_Def_Duration_Text",24,200)
        at("AuctionatorOption_Durations",24,220)
        for index,suffix in ipairs({"S","M","L"}) do
            local radio=_G["Atr_RB_"..suffix]
            if radio and AuctionatorOption_Durations then
                optionAt(radio,AuctionatorOption_Durations,(index-1)*100,0)
            end
        end
        at("AuctionatorOption_Deftab_Text",24,256)
        dropdown("AuctionatorOption_Deftab",274)
        at("Atr_BrowseMarketColumnOption",24,306)
        if Atr_RB_N then Atr_RB_N:Hide();Atr_RB_N:SetChecked(false) end
    elseif panel==Atr_TooltipsOptionsFrame then
        for _,region in ipairs({panel:GetRegions()}) do
            if region:IsObjectType("FontString") then
                local text=region:GetText()
                if text=="When SHIFT is down show" then optionAt(region,panel,24,154)
                elseif text=="Show disenchanting details" then optionAt(region,panel,24,254)
                elseif text=="Show prospecting details" then optionAt(region,panel,24,352) end
            end
        end
        dropdown("Atr_tipsShiftDD",170)
        dropdown("Atr_deDetailsDD",270)
        dropdown("Atr_ProspectingDetails",368)
        -- Restore after the legacy first-open spacing pass, like the DE group.
        at("Atr_ProspectingTips",24,322)
        if ATR_tipsDisenchantOpt_CB_Text then ATR_tipsDisenchantOpt_CB_Text:SetText("Disenchanting: show value") end
    elseif panel==Atr_ScanningOptionsFrame then
        dropdown("Atr_scanLevelDD",114)
        -- Help belongs to the heading, not the dropdown's inherited XML hover.
        if Atr_scanLevelDD then
            Atr_scanLevelDD:SetScript("OnEnter",nil);Atr_scanLevelDD:SetScript("OnLeave",nil)
        end
        dropdown("Atr_MarketHistoryDropdown",178)
        dropdown("Atr_OldPriceDays",356)
        if Atr_ScanOpts_MemUsageText then Atr_ScanOpts_MemUsageText:Hide() end
        if Atr_ScanOpts_ItemCntText then Atr_ScanOpts_ItemCntText:Hide() end
        at("Atr_ScanOpts_MaxHistAge",AuctionatorRemastered.UI.UseElvUI() and 24 or 29,300)
    elseif panel==Atr_AppearanceOptions then at("Atr_AllowAuctionMovement",24,92)
    elseif panel==Atr_OfflineBrowserOptions then at("Atr_ShowIncompleteBrowserItems",24,92) end
    normalizeOptionCheckboxes(panel)
end
local function layoutDatabaseText(panel)
    if panel~=Atr_ScanningOptionsFrame then return end
    local function walk(frame)
        for _,label in ipairs({frame:GetRegions()}) do
            if label:IsObjectType("FontString") then
                local text=label:GetText()
                local x,y,help
                if text=="Minimum quality level:" then x,y,help=24,96,optionHelp.quality
                elseif text=="Auctionator memory usage:" then label:Hide()
                elseif text=="Items in the database:" then label:Hide()
                elseif text=="On start-up delete historical prices older than:" then
                    x,y,help=24,270,optionHelp.retention;label:SetWidth(math.max(240,panel:GetWidth()-48));label:SetHeight(32)
                elseif text=="days" and Atr_ScanOpts_MaxHistAge then
                    label:ClearAllPoints()
                    label:SetPoint("LEFT",Atr_ScanOpts_MaxHistAge,"RIGHT",6,0)
                elseif text=="Market % comparison:" then x,y,help=24,160,optionHelp.market
                elseif text and text:find("Median of daily scan medians",1,true)==1 then
                    x,y=24,218;label:SetWidth(math.max(240,panel:GetWidth()-48));label:SetHeight(48)
                    label:SetText("Median of daily scan medians, excluding today.\nOlder days use daily lows.\n* = fewer than 3 history days. Changes apply immediately.")
                end
                if x then optionAt(label,panel,x,y) end
                if help then attachOptionLabelHelp(label,panel,help) end
            end
        end
        for _,child in ipairs({frame:GetChildren()}) do walk(child) end
    end
    walk(panel)
end
local function layoutStackPreferences(panel)
    if panel~=Atr_StackingOptionsFrame or not Atr_Stacking_List then return end
    local list,scroll=Atr_Stacking_List,Atr_Stacking_ScrollFrame
    list:ClearAllPoints()
    list:SetPoint("TOPLEFT",panel,"TOPLEFT",24,-94)
    list:SetPoint("TOPRIGHT",panel,"TOPRIGHT",-44,-94)
    list:SetHeight(156) -- Nine 16px rows plus the existing inner margins.
    if Atr_StackingVisibleRows~=9 then
        Atr_StackingVisibleRows=9
        if Atr_StackingList_Display then Atr_StackingList_Display() end
    end
    Atr_StyleOfflineBrowser(list,true,false)
    if scroll then
        scroll:ClearAllPoints();scroll:SetPoint("TOPLEFT",list,"TOPLEFT",4,-4)
        scroll:SetPoint("BOTTOMRIGHT",list,"BOTTOMRIGHT",-4,4)
        Atr_StyleAnalysisScroll(scroll,list)
    end
    local edit,new=Atr_StackingOptionsFrame_Edit,Atr_StackingOptionsFrame_New
    if not edit or not new then return end
    edit:ClearAllPoints();edit:SetPoint("TOPLEFT",list,"BOTTOMLEFT",0,-10);edit:SetSize(80,24)
    new:ClearAllPoints();new:SetPoint("LEFT",edit,"RIGHT",8,0);new:SetSize(80,24)
    local help=panel.atrStackHelp
    if not help then
        help=CreateFrame("Frame",nil,panel);help:EnableMouse(false)
        help:SetPoint("TOPLEFT",panel,"TOPLEFT",24,-292)
        help:SetPoint("TOPRIGHT",panel,"TOPRIGHT",-44,-292);help:SetHeight(116)
        local title=help:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
        title:SetPoint("TOPLEFT",help,"TOPLEFT",12,-8)
        title:SetText("How stack preferences work")
        local text=help:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        text:SetPoint("TOPLEFT",help,"TOPLEFT",12,-24)
        text:SetPoint("TOPRIGHT",help,"TOPRIGHT",-12,-24)
        text:SetJustifyH("LEFT");text:SetJustifyV("TOP");text:SetHeight(84)
        if text.SetWordWrap then text:SetWordWrap(true) end
        text:SetText("Select a category and click Edit to choose stack size and auction count.\nUse New for a specific item. Values are filled in on Sell and can be changed before posting.\n'default behavior' means no custom rule has been set for that category.")
        panel.atrStackHelp=help
    end
    Atr_StyleOfflineBrowser(help,true,false)
end
function Options.PrepareLayout(panel,width,title,subtitle,chrome)
    -- A little extra room on the dense old pricing/tooltip pages, once only.
    if not panel.atrOptionsSpaced then
        local offset=panel==Atr_UCConfigFrame and 24 or (panel==Atr_TooltipsOptionsFrame and 16 or 0)
        if offset>0 then
            local regions={panel:GetRegions()}
            for _,child in ipairs({panel:GetChildren()}) do regions[#regions+1]=child end
            for _,region in ipairs(regions) do
                if region~=title and region~=subtitle and region~=chrome then
                    local points={}
                    for i=1,region:GetNumPoints() do points[i]={region:GetPoint(i)} end
                    for _,point in ipairs(points) do
                        if point[2]==panel and point[3]:find("TOP") and (point[5] or 0)<=-55 then
                            region:ClearAllPoints()
                            for _,p in ipairs(points) do
                                if p[2]==panel and p[3]:find("TOP") then p[5]=(p[5] or 0)-offset end
                                region:SetPoint(unpack(p))
                            end
                            break
                        end
                    end
                end
            end
        end
        panel.atrOptionsSpaced=true
    end
    -- The new pages had their first checkbox in the title/help area.
    if panel==Atr_OfflineBrowserOptions and Atr_ShowIncompleteBrowserItems then
        optionAt(Atr_ShowIncompleteBrowserItems,panel,24,96)
    end
    if panel==AuctionatorDescriptionFrame and AuctionatorDescriptionHTML then
        optionAt(AuctionatorDescriptionHTML,panel,24,94)
        AuctionatorDescriptionHTML:SetWidth(width)
    end
    if panel==Atr_AppearanceOptions then
        optionAt(Atr_ResetAuctionPosition,panel,24,132)
        optionAt(Atr_ResetDetailsPosition,panel,24,164)
        local label=_G["Atr_AllowAuctionMovementText"]
        if label and label.SetTextColor then label:SetTextColor(1,1,1) end
    end
end

function Options.Layout(panel)
    layoutOptionRows(panel)
    layoutStackPreferences(panel)
    layoutDatabaseText(panel)
end
