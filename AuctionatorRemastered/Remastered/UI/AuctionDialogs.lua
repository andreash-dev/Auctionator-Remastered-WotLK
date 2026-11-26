local place=AuctionatorRemastered.UI.AuctionLayout.Place

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

-- Style the live advanced-search controls without replacing their search,
-- dropdown initialization, reset or item-level visibility handlers.
local function styleAdvancedSearchButton()
    if not Atr_Adv_Search_Dialog or not Atr_Adv_Search_Button then return end
    Atr_Adv_Search_Button:SetText("Advanced...")
    Atr_Adv_Search_Button:SetSize(80,22)
    if not AuctionFrame or not Atr_Main_Panel or not Atr_Search_Box
        or not Atr_Search_Button or not Atr_FullScanButton or not Auctionator1Button then return end
    -- Reserve the action buttons from the right; let the input use the rest.
    -- The old Options anchor depended on Search and reserved only a '+' width.
    place("Auctionator1Button",AuctionFrame,"TOPRIGHT","TOPRIGHT",-16,-44,70,22)
    place("Atr_FullScanButton",Auctionator1Button,"RIGHT","LEFT",-8,0,80,22)
    place("Atr_Adv_Search_Button",Atr_FullScanButton,"RIGHT","LEFT",-8,0,80,22)
    place("Atr_Search_Button",Atr_Adv_Search_Button,"RIGHT","LEFT",-8,0,80,22)
    local input=Atr_Search_Box
    input:ClearAllPoints()
    input:SetPoint("LEFT",Atr_Main_Panel,"TOPLEFT",20,-55)
    input:SetPoint("RIGHT",Atr_Search_Button,"LEFT",-12,0)
    input:SetHeight(22)
    if AuctionatorRemastered.UI.UseElvUI() and not input.atrSearchSkinned then
        input.atrSearchSkinned=Atr_AnalysisSkin(input,"EditBox") or nil
    end
    local dropdown=Atr_DropDownSL
    if dropdown and Atr_Hlist then
        if AuctionatorRemastered.UI.UseElvUI() then
            if not dropdown.atrSearchSkinned then
                dropdown.atrSearchSkinned=Atr_AnalysisSkin(dropdown,"DropDownBox") or nil
            end
            dropdown:SetWidth(221)
            local label,arrow=Atr_DropDownSLText,Atr_DropDownSLButton
            if label and arrow and dropdown.backdrop then
                label:ClearAllPoints()
                label:SetPoint("LEFT",dropdown.backdrop,"LEFT",8,0)
                label:SetPoint("RIGHT",arrow,"LEFT",-6,0)
                label:SetJustifyH("LEFT")
            end
        end
        -- Both dropdown templates inset the visible box 20px from the left
        -- and center its artwork 3px above the frame's center.
        dropdown:ClearAllPoints()
        dropdown:SetPoint("LEFT",Atr_Main_Panel,"TOPLEFT",-211,-58)
    end
end
local advancedMaskPoints
local function fitAdvancedMask()
    if not Atr_Mask or not AuctionFrame or not AuctionFrame:IsShown() then return end
    if not advancedMaskPoints then
        advancedMaskPoints={}
        for i=1,Atr_Mask:GetNumPoints() do advancedMaskPoints[i]={Atr_Mask:GetPoint(i)} end
        advancedMaskPoints.width=Atr_Mask:GetWidth();advancedMaskPoints.height=Atr_Mask:GetHeight()
    end
    Atr_Mask:ClearAllPoints()
    Atr_Mask:SetPoint("TOPLEFT",AuctionFrame,"TOPLEFT",0,0)
    Atr_Mask:SetPoint("BOTTOMRIGHT",AuctionFrame,"BOTTOMRIGHT",0,0)
end
local function restoreAdvancedMask()
    if not advancedMaskPoints then return end
    Atr_Mask:ClearAllPoints()
    for _,point in ipairs(advancedMaskPoints) do Atr_Mask:SetPoint(unpack(point)) end
    Atr_Mask:SetSize(advancedMaskPoints.width,advancedMaskPoints.height)
    advancedMaskPoints=nil
end
-- The buy dialog uses the same modal mask as advanced search. Anchor it to
-- the live, movable AH instead of the inherited fixed UIParent rectangle.
if Atr_Buy_Confirm_Frame and Atr_Buy_Confirm_Frame.HookScript then
    Atr_Buy_Confirm_Frame:HookScript("OnShow",fitAdvancedMask)
    Atr_Buy_Confirm_Frame:HookScript("OnHide",restoreAdvancedMask)
end
function Atr_StyleAdvancedSearchDialog()
    local frame=Atr_Adv_Search_Dialog
    if not frame or not Atr_StyleOfflineBrowser then return end
    frame:ClearAllPoints();frame:SetSize(520,286)
    frame:SetPoint("CENTER",(AuctionFrame and AuctionFrame:IsShown()) and AuctionFrame or UIParent,"CENTER",0,0)
    frame:SetClampedToScreen(true)
    Atr_StyleOfflineBrowser(frame,false,false)
    for _,region in ipairs({frame:GetRegions()}) do
        if region:IsObjectType("Texture") and region:GetTexture()=="Interface\\DialogFrame\\UI-DialogBox-Header" then
            region:Hide()
        elseif region:IsObjectType("FontString") and region:GetText()=="Advanced Search" then
            region:ClearAllPoints();region:SetPoint("TOP",frame,"TOP",0,-16)
        end
    end
    local function at(name,x,y,width,height)
        place(name,frame,"TOPLEFT","TOPLEFT",x,-y,width,height)
    end
    at("Atr_AS_Searchtext_Label",24,48)
    at("Atr_AS_Searchtext",28,66,464,22)
    at("Atr_AS_Cat_Label",24,108)
    at("Atr_AS_SubCat_Label",274,108)
    at("Atr_AS_Rarity_Label",24,170)
    at("Atr_AS_LevRange_Label",274,170)
    at("Atr_AS_ILevRange_Label",390,170)
    for _,spec in ipairs({{"Atr_ASDD_Class",8,126},{"Atr_ASDD_Subclass",258,126},{"Atr_ASDD_Rarity",8,188}}) do
        local dropdown=_G[spec[1]]
        -- ElvUI's handler is idempotent only when called once per control.
        if AuctionatorRemastered.UI.UseElvUI() and not dropdown.atrAdvancedSkinned then
            dropdown.atrAdvancedSkinned=Atr_AnalysisSkin(dropdown,"DropDownBox") or nil
        end
        UIDropDownMenu_SetWidth(dropdown,196)
        at(spec[1],spec[2],spec[3])
    end
    for _,spec in ipairs({{"Atr_AS_Minlevel",274},{"Atr_AS_Maxlevel",328},
        {"Atr_AS_MinItemlevel",390},{"Atr_AS_MaxItemlevel",444}}) do
        at(spec[1],spec[2],188,36,22)
    end
    -- The legacy level dash is anonymous; the item-level dash has a name.
    for _,region in ipairs({frame:GetRegions()}) do
        if region:IsObjectType("FontString") and region:GetText()=="-" and region~=Atr_AS_ILevRange_Dash then
            region:ClearAllPoints();region:SetPoint("TOPLEFT",frame,"TOPLEFT",316,-191)
        end
    end
    at("Atr_AS_ILevRange_Dash",432,191)
    for _,name in ipairs({"Atr_AS_Searchtext","Atr_AS_Minlevel","Atr_AS_Maxlevel",
        "Atr_AS_MinItemlevel","Atr_AS_MaxItemlevel"}) do
        local input=_G[name]
        if AuctionatorRemastered.UI.UseElvUI() and not input.atrAdvancedSkinned then
            input.atrAdvancedSkinned=Atr_AnalysisSkin(input,"EditBox") or nil
        end
    end
    for _,name in ipairs({"Atr_Adv_Search_ResetBut","Atr_Adv_Search_OKBut","Atr_Adv_Search_CancelBut"}) do
        local button=_G[name]
        if AuctionatorRemastered.UI.UseElvUI() and not button.atrAdvancedSkinned then
            button.atrAdvancedSkinned=Atr_AnalysisSkin(button,"Button") or nil
        end
        button:SetSize(86,24);button:ClearAllPoints()
    end
    Atr_Adv_Search_ResetBut:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",24,18)
    Atr_Adv_Search_CancelBut:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-24,18)
    Atr_Adv_Search_OKBut:SetPoint("RIGHT",Atr_Adv_Search_CancelBut,"LEFT",-10,0)
    fitAdvancedMask()
end
if Atr_Adv_Search_Dialog then
    Atr_Adv_Search_Dialog:HookScript("OnShow",Atr_StyleAdvancedSearchDialog)
    Atr_Adv_Search_Dialog:HookScript("OnHide",restoreAdvancedMask)
end


AuctionatorRemastered.UI.AuctionDialogs={StyleAdvancedButton=styleAdvancedSearchButton}

-- The legacy error frame is also shown directly by quantity validation and
-- shopping lists. Style its existing OnShow without replacing masks or actions.
function Atr_StyleErrorDialog()
    local frame=Atr_Error_Frame
    if not frame or not Atr_Error_Text or not Atr_StyleOfflineBrowser then return end
    frame:ClearAllPoints()
    frame:SetPoint("CENTER",(AuctionFrame and AuctionFrame:IsShown()) and AuctionFrame or UIParent,"CENTER",0,0)
    frame:SetWidth(440);frame:SetClampedToScreen(true)
    Atr_StyleOfflineBrowser(frame,false,false)
    local text=Atr_Error_Text
    text:ClearAllPoints();text:SetPoint("TOPLEFT",frame,"TOPLEFT",20,-22)
    text:SetWidth(400);text:SetFontObject(GameFontHighlight)
    text:SetJustifyH("CENTER");text:SetJustifyV("TOP");text:SetWordWrap(true)
    local height=math.max(40,text:GetStringHeight())
    text:SetHeight(height);frame:SetHeight(math.max(160,height+82))
    for _,button in ipairs({frame:GetChildren()}) do
        if button:IsObjectType("Button") then
            if not button.atrErrorSkinned then button.atrErrorSkinned=Atr_AnalysisSkin(button,"Button") end
            button:ClearAllPoints();button:SetPoint("BOTTOM",frame,"BOTTOM",0,16)
            button:SetSize(110,24)
        end
    end
end
if Atr_Error_Frame then Atr_Error_Frame:HookScript("OnShow",Atr_StyleErrorDialog) end
