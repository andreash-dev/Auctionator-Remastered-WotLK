-- AH placement and Interface options; independent of the Deals view.
function AuctionatorRemastered.UI.IsValidPosition(config)
    return type(config)=='table' and type(config.x)=='number' and type(config.y)=='number'
        and config.x==config.x and config.y==config.y and math.abs(config.x)<100000 and math.abs(config.y)<100000
end
-- Register settings independently of the first auction-house visit. The
-- movement/detail actions are bound later when those live frames initialize.
local appearanceActions={}
local function createAppearanceOptions()
    if Atr_AppearanceOptions then return Atr_AppearanceOptions end
    local appearance=CreateFrame('Frame','Atr_AppearanceOptions',UIParent)
    appearance.name='Appearance';appearance.parent='Auctionator Remastered'
    local function text(label,x,y,font,width,height)
        local t=appearance:CreateFontString(nil,'OVERLAY',font)
        t:SetPoint('TOPLEFT',appearance,'TOPLEFT',x,y)
        if width then t:SetWidth(width);t:SetHeight(height);t:SetJustifyH('LEFT') end
        t:SetText(label);return t
    end
    text('Appearance',16,-16,'GameFontNormalLarge')
    text('Window positions are saved automatically when you move or close the auction house.',16,-48,'GameFontHighlightSmall',550,32)
    local choice=CreateFrame('CheckButton','Atr_AllowAuctionMovement',appearance,'UICheckButtonTemplate')
    Atr_AnalysisSkin(choice,'CheckBox');choice:SetSize(24,24);choice:SetPoint('TOPLEFT',appearance,'TOPLEFT',16,-90)
    _G[choice:GetName()..'Text']:SetText('Allow moving the auction window')
    choice:SetScript('OnClick',function(self)
        local enabled=self:GetChecked() and true or false
        if type(AUCTIONATOR_SAVEDVARS)~='table' then Atr_ResetSavedVars() end
        AUCTIONATOR_SAVEDVARS.moveAuctionFrame=enabled
        if AuctionFrame then AuctionFrame:StopMovingOrSizing();AuctionFrame:SetMovable(enabled) end
        if appearanceActions.mover then appearanceActions.mover:EnableMouse(enabled) end
    end)
    local function button(name,label,y,callback)
        local b=CreateFrame('Button',name,appearance,'UIPanelButtonTemplate')
        Atr_AnalysisSkin(b,'Button');b:SetSize(200,24);b:SetPoint('TOPLEFT',appearance,'TOPLEFT',24,y)
        b:SetText(label);b:SetScript('OnClick',callback)
    end
    button('Atr_ResetAuctionPosition','Reset auction window',-180,function()
        if type(AUCTIONATOR_SAVEDVARS)=='table' then AUCTIONATOR_SAVEDVARS.auctionFramePosition=nil end
        if appearanceActions.resetAuction then appearanceActions.resetAuction() end
    end)
    button('Atr_ResetDetailsPosition','Reset Deal details',-260,function()
        if type(AUCTIONATOR_SAVEDVARS)=='table' then AUCTIONATOR_SAVEDVARS.dealsDetailPosition=nil end
        if appearanceActions.resetDetails then appearanceActions.resetDetails() end
    end)
    local UI=AuctionatorRemastered.UI
    text('Interface style',24,-200,'GameFontNormal')
    local native=CreateFrame('CheckButton','Atr_ThemeNative',appearance,'UIRadioButtonTemplate')
    local elv=CreateFrame('CheckButton','Atr_ThemeElvUI',appearance,'UIRadioButtonTemplate')
    for index,radio in ipairs({native,elv}) do
        Atr_AnalysisSkin(radio,'CheckBox');radio:SetSize(24,24)
        radio:SetPoint('TOPLEFT',appearance,'TOPLEFT',24+(index-1)*150,-220)
    end
    Atr_ThemeNativeText:SetText('Standard WoW');Atr_ThemeElvUIText:SetText('ElvUI')
    local reload=CreateFrame('Button','Atr_ApplyThemeReload',appearance,'UIPanelButtonTemplate')
    Atr_AnalysisSkin(reload,'Button');reload:SetSize(110,24)
    reload:SetPoint('TOPRIGHT',appearance,'TOPRIGHT',-24,-220);reload:SetText('Reload UI')
    reload:SetScript('OnClick',function() ReloadUI() end)
    local note=text('',24,-250,'GameFontHighlightSmall',500,28)
    text('Transparent backgrounds',24,-286,'GameFontNormal')
    local backgrounds={}
    for index,spec in ipairs({{'auction','Auction house'},{'browser','Offline Browser'},{'shopping','Shopping planner'}}) do
        local kind=spec[1]
        local name=kind=='auction' and 'Atr_AppearanceAuctionTransparent' or (kind=='browser' and 'Atr_AppearanceBrowserTransparent' or 'Atr_AppearanceShoppingTransparent')
        local control=CreateFrame('CheckButton',name,appearance,'UICheckButtonTemplate')
        Atr_AnalysisSkin(control,'CheckBox');control:SetSize(24,24)
        control:SetPoint('TOPLEFT',appearance,'TOPLEFT',24,-306-(index-1)*36)
        _G[name..'Text']:SetText(spec[2])
        control:SetScript('OnClick',function(self) UI.SetBackgroundTransparent(kind,self:GetChecked()) end)
        backgrounds[kind]=control
    end
    local function refresh()
        choice:SetChecked(type(AUCTIONATOR_SAVEDVARS)~='table' or AUCTIONATOR_SAVEDVARS.moveAuctionFrame~=false)
        local requested=UI.RequestedTheme()
        native:SetChecked(requested=='native');elv:SetChecked(requested=='elvui')
        if UI.HasElvUI() then elv:Enable() else elv:Disable() end
        for _,name in ipairs({'Atr_ThemeNativeText','Atr_AppearanceAuctionTransparentText','Atr_AppearanceBrowserTransparentText','Atr_AppearanceShoppingTransparentText'}) do
            local label=_G[name]
            if label and label.SetTextColor then label:SetTextColor(1,1,1) end
        end
        if Atr_ThemeElvUIText.SetTextColor then
            local shade=UI.HasElvUI() and 1 or .5
            Atr_ThemeElvUIText:SetTextColor(shade,shade,shade)
        end
        local current=UI.UseElvUI() and 'elvui' or 'native'
        if requested~=current then reload:Enable() else reload:Disable() end
        note:SetText(UI.HasElvUI() and 'Style changes apply after Reload UI. Background changes apply immediately.'
            or 'ElvUI is not installed. Standard WoW is used; background changes apply immediately.')
        note:SetWidth(math.max(240,appearance:GetWidth()-48))
        backgrounds.auction:SetChecked(UI.BackgroundTransparent('auction'))
        backgrounds.browser:SetChecked(UI.BackgroundTransparent('browser'))
        backgrounds.shopping:SetChecked(UI.BackgroundTransparent('shopping'))
    end
    native:SetScript('OnClick',function() UI.SetThemePreference('native');refresh() end)
    elv:SetScript('OnClick',function() UI.SetThemePreference('elvui');refresh() end)
    appearance:SetScript('OnShow',refresh)
    if InterfaceOptions_AddCategory then InterfaceOptions_AddCategory(appearance) end
    appearance:Hide()
end
function AuctionatorRemastered.UI.SetupAppearance(mover,positionDetails,settings)
    settings() -- Ensure saved variables exist before any option callbacks.
    local originalPoints={}
    for i=1,AuctionFrame:GetNumPoints() do originalPoints[i]={AuctionFrame:GetPoint(i)} end
    if #originalPoints==0 then originalPoints[1]={'TOPLEFT',UIParent,'TOPLEFT',16,-116} end
    local function saveAuctionPosition()
        local scale=AuctionFrame:GetEffectiveScale()/UIParent:GetEffectiveScale()
        local x,y=AuctionFrame:GetLeft(),AuctionFrame:GetBottom()
        if x and y then AUCTIONATOR_SAVEDVARS.auctionFramePosition={x=x*scale,y=y*scale} end
    end
    local function restoreAuctionPosition()
        local config=AUCTIONATOR_SAVEDVARS.auctionFramePosition
        if not AuctionatorRemastered.UI.IsValidPosition(config) then return end
        local scale=AuctionFrame:GetEffectiveScale()/UIParent:GetEffectiveScale()
        AuctionFrame:ClearAllPoints()
        AuctionFrame:SetPoint('BOTTOMLEFT',UIParent,'BOTTOMLEFT',config.x/scale,config.y/scale)
        AuctionFrame:SetClampedToScreen(true)
    end
    local function resetAuctionPosition()
        AUCTIONATOR_SAVEDVARS.auctionFramePosition=nil
        AuctionFrame:StopMovingOrSizing();AuctionFrame:ClearAllPoints()
        for _,point in ipairs(originalPoints) do AuctionFrame:SetPoint(unpack(point)) end
    end
    local function resetDetailsPosition()
        AUCTIONATOR_SAVEDVARS.dealsDetailPosition=nil
        positionDetails()
    end
    -- Restore after Blizzard/skin OnShow handlers finish positioning the panel.
    local driver=CreateFrame('Frame','Atr_AuctionPositionRestore',UIParent)
    driver:Hide()
    driver:SetScript('OnUpdate',function(self) self:Hide();restoreAuctionPosition() end)
    AuctionFrame:HookScript('OnShow',function() driver:Show() end)
    AuctionFrame:HookScript('OnHide',saveAuctionPosition)
    if AuctionFrame:IsShown() then driver:Show() end
    mover:SetScript('OnDragStart',function()
        if AUCTIONATOR_SAVEDVARS.moveAuctionFrame==false then return end
        AuctionFrame:SetMovable(true);AuctionFrame:SetClampedToScreen(true);AuctionFrame:StartMoving()
    end)
    mover:SetScript('OnDragStop',function() AuctionFrame:StopMovingOrSizing();saveAuctionPosition() end)
    mover:EnableMouse(AUCTIONATOR_SAVEDVARS.moveAuctionFrame~=false)
    Atr_DealsDetailsReset:SetScript('OnClick',resetDetailsPosition)

    appearanceActions.mover=mover
    appearanceActions.resetAuction=resetAuctionPosition
    appearanceActions.resetDetails=resetDetailsPosition
    createAppearanceOptions()
end

if CreateFrame and InterfaceOptions_AddCategory then createAppearanceOptions() end
