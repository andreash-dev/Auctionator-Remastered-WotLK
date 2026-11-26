local function place(name, relative, point, relativePoint, x, y, width, height)
    local frame = _G[name]
    if not frame or not relative then return end
    frame:ClearAllPoints()
    frame:SetPoint(point, relative, relativePoint, x, y)
    if width then frame:SetWidth(width) end
    if height then frame:SetHeight(height) end
end

-- Stock-only spacing. ElvUI keeps its existing layout and skin-owned anchors.
local function fixNativeSellLayout()
    local skinned=AuctionatorRemastered.UI.UseElvUI() and AuctionFrame and AuctionFrame.backdrop
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
    local bar=scroll.ScrollBar or _G[(scroll:GetName() or "").."ScrollBar"]
    local hasScroll=bar and scroll:IsShown() and bar:IsShown()
    local fillExtra=hasScroll and 2 or 26
    for i=1,20 do
        local row=_G["AuctionatorHEntry"..i]
        if row then
            row:ClearAllPoints();row:SetPoint("TOPLEFT",list,"TOPLEFT",4,-5-(i-1)*step)
            row:SetWidth(width);row:SetHeight(step)
            -- Fill the spare gutter only when the scrollbar is hidden.
            -- Hover and selection must never paint over visible scroll controls.
            for _,texture in ipairs({row:GetHighlightTexture(),row:GetPushedTexture()}) do
                texture:ClearAllPoints()
                texture:SetPoint("TOPLEFT",row,"TOPLEFT",0,0)
                texture:SetPoint("BOTTOMRIGHT",row,"BOTTOMRIGHT",fillExtra,0)
            end
            local label=_G["AuctionatorHEntry"..i.."_EntryText"]
            if label then label:SetWidth(width-4);label:SetHeight(step);label:SetJustifyH("LEFT") end
        end
    end
end

-- A reversible Deals-style shell for all three stock Auctionator panes.
local nativeState={regions={},seen={},backdrops={},stripes={},geometry={}}
local function restoreNativeAuctions()
    if not nativeState.active then return end
    Atr_AnalysisEnd(nativeState.artwork or {})
    for _,saved in ipairs(nativeState.regions) do
        if saved.shown then saved.region:Show() else saved.region:Hide() end
    end
    for frame,saved in pairs(nativeState.backdrops) do
        frame:SetBackdrop(saved.backdrop)
        if saved.color then frame:SetBackdropColor(unpack(saved.color)) end
        if saved.border then frame:SetBackdropBorderColor(unpack(saved.border)) end
    end
    for frame,saved in pairs(nativeState.geometry) do
        frame:ClearAllPoints()
        for _,point in ipairs(saved.points) do frame:SetPoint(unpack(point)) end
        frame:SetWidth(saved.width);frame:SetHeight(saved.height)
    end
    nativeState.geometry={}
    for _,stripe in pairs(nativeState.stripes) do stripe:Hide() end
    nativeState.shell:Hide()
    nativeState.active=false;nativeState.regions={};nativeState.seen={};nativeState.backdrops={}
end
local function syncNativeHeadings()
    if not nativeState.active then return end
    if Atr_HeadingsBar and Atr_HeadingsBar:IsShown() then
        local headings,results=nativeState.shell.headings,nativeState.shell.results
        local left,barLeft=results:GetLeft(),Atr_HeadingsBar:GetLeft()
        if left and barLeft then
            local scale=headings:GetEffectiveScale()
            local offset=(left*results:GetEffectiveScale()-barLeft*Atr_HeadingsBar:GetEffectiveScale())/scale
            headings:ClearAllPoints()
            headings:SetPoint('LEFT',Atr_HeadingsBar,'LEFT',offset,0)
            headings:SetWidth(results:GetWidth()*results:GetEffectiveScale()/scale)
        end
        headings:Show()
    else nativeState.shell.headings:Hide() end
end
local function styleNativeAuctions()
    local skinned=AuctionatorRemastered.UI.UseElvUI() and AuctionFrame and AuctionFrame.backdrop
        and AuctionFrameBrowse and AuctionFrameBrowse.RightBackground
    local active=not skinned and Atr_Main_Panel and Atr_Main_Panel:IsShown()
        and Atr_IsTabSelected and (Atr_IsTabSelected(3) or Atr_IsTabSelected(1) or Atr_IsTabSelected(2))
    if not active then restoreNativeAuctions();return end
    local selling,undercutting=Atr_IsTabSelected(1),Atr_IsTabSelected(2)
    local mode=selling and 1 or (undercutting and 2 or 3)
    if nativeState.active and nativeState.mode~=mode then restoreNativeAuctions() end
    if not Atr_AnalysisBegin or not Atr_AnalysisFit or not Atr_AnalysisBackdrop then return end
    local function hide(region)
        if not region then return end
        if not nativeState.seen[region] then
            nativeState.seen[region]=true
            nativeState.regions[#nativeState.regions+1]={region=region,shown=region:IsShown()}
        end
        region:Hide()
    end
    if not nativeState.shell then
        local shell=CreateFrame('Frame',nil,AuctionFrame)
        shell:SetFrameLevel(AuctionFrame:GetFrameLevel())
        shell:EnableMouse(false)
        nativeState.shell=shell
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
            -- Match the list surface in Buy/Undercuts: -193 from Main,
            -- including the list's 24px scrollbar gutter at its right edge.
            shell.sellSurface:SetPoint('TOPLEFT',Atr_SellControls,'TOPLEFT',-3,-3)
            shell.sellSurface:SetPoint('BOTTOMRIGHT',Atr_SellControls,'BOTTOMRIGHT',1,0)
            Atr_AnalysisBackdrop(shell.sellSurface,1)
        end
    end
    Atr_AnalysisFit(nativeState.shell)
    if not nativeState.active then
        nativeState.artwork=Atr_AnalysisBegin(nativeState.shell)
        nativeState.active=true
        nativeState.mode=mode
    end
    Atr_AnalysisBackdrop(nativeState.shell,1,"shell")
    Atr_AnalysisBackdrop(nativeState.shell.results,1,"body")
    Atr_AnalysisBackdrop(nativeState.shell.headings,1,"heading")
    if nativeState.shell.sellSurface then
        nativeState.shell.sellSurface:SetFrameLevel(Atr_SellControls:GetFrameLevel())
        Atr_AnalysisBackdrop(nativeState.shell.sellSurface,1,"body")
    end
    nativeState.shell:Show()
    if nativeState.shell.sellSurface then
        if selling then nativeState.shell.sellSurface:Show() else nativeState.shell.sellSurface:Hide() end
    end
    if selling and Atr_SellControls then
        if not nativeState.backdrops[Atr_SellControls] then
            nativeState.backdrops[Atr_SellControls]={backdrop=Atr_SellControls:GetBackdrop(),
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
                if not nativeState.geometry[button] then
                    local saved={width=button:GetWidth(),height=button:GetHeight(),points={}}
                    for i=1,button:GetNumPoints() do saved.points[i]={button:GetPoint(i)} end
                    nativeState.geometry[button]=saved
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
            -AuctionFrame:GetBottom()*AuctionFrame:GetEffectiveScale())/nativeState.shell.results:GetEffectiveScale()
    end
    nativeState.shell.results:ClearAllPoints()
    nativeState.shell.results:SetPoint('TOPLEFT',Atr_Main_Panel,'TOPLEFT',0,-75)
    nativeState.shell.results:SetPoint('BOTTOMRIGHT',AuctionFrame,'BOTTOMRIGHT',-12,bottom)
    Atr_StyleEmptyMessage(AuctionatorMessageFrame,nativeState.shell.results)
    Atr_StyleEmptyMessage(AuctionatorMessage2Frame,nativeState.shell.results)
    syncNativeHeadings()
    hide(Atr_HeadingsBarMiddle)
    for index=1,4 do
        local tab=_G['Atr_ListTabsTab'..index]
        if tab then
            if not nativeState.backdrops[tab] then
                nativeState.backdrops[tab]={backdrop=tab:GetBackdrop(),
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
            local stripe=nativeState.stripes[index]
            if not stripe then
                stripe=row:CreateTexture(nil,'BACKGROUND');stripe:SetAllPoints(row)
                stripe:SetTexture(1,1,1,index%2==0 and .035 or 0)
                nativeState.stripes[index]=stripe
            end
            if not AuctionatorRemastered.UI.UseElvUI() then
                stripe:SetTexture(.75,.68,.55,index%2==0 and .065 or 0)
            else
                stripe:SetTexture(1,1,1,index%2==0 and .035 or 0)
            end
            stripe:Show()
        end
    end
end


AuctionatorRemastered.UI.AuctionLayout={
    Place=place,
    FixSell=fixNativeSellLayout,
    StyleSidebar=styleHistoryList,
    Apply=styleNativeAuctions,
    Restore=restoreNativeAuctions,
    SyncHeadings=syncNativeHeadings,
    IsActive=function() return nativeState.active end,
}
