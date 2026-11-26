local entries={}
function UIDropDownMenu_SetWidth(control,width) control:SetWidth(width) end
function UIDropDownMenu_JustifyText() end
function UIDropDownMenu_Initialize(_,fn) fn() end
function UIDropDownMenu_CreateInfo() return {} end
function UIDropDownMenu_AddButton(info) entries[#entries+1]=info end
function UIDropDownMenu_SetSelectedValue(control,value) control.selected=value end
function UIDropDownMenu_SetText(control,text) control.caption=text end
dofile('AuctionatorRemastered/Remastered/Core/Bootstrap.lua')
local registered,skinCalls={},0
function hooksecurefunc(name,fn) registered[name]=fn end
local function widget(name,parent,kind)
 local w={id=name,name=name,parent=parent,kind=kind or 'Frame',children={},regions={},points={},width=600,level=1,scripts={}}
 if name then _G[name]=w end
 if parent then table.insert(parent.children,w) end
 function w:GetName() return self.id end
 function w:GetWidth() return self.width end
 function w:SetSize(x,y) self.width=x;self.height=y end
 function w:GetChecked() return self.checked end
 function w:SetChecked(v) self.checked=v end
 function w:GetObjectType() return self.kind end
 function w:IsObjectType(k) return self.kind==k end
 function w:GetChildren() return unpack(self.children) end
 function w:GetRegions() return unpack(self.regions) end
 function w:ClearAllPoints() self.points={} end
 function w:SetPoint(...) self.points[#self.points+1]={...} end
 function w:GetPoint(i) return unpack(self.points[i]) end
 function w:GetNumPoints() return #self.points end
 function w:SetWidth(v) self.width=v end
 function w:SetHeight(v) self.height=v end
 function w:Hide() self.hidden=true;if self.scripts.OnHide then self.scripts.OnHide() end end
 function w:Show() self.hidden=false end
 function w:SetAllPoints() end
 function w:SetFrameStrata() end
 function w:SetClampedToScreen() end
 function w:SetAutoFocus() end
 function w:SetFocus() self.focused=true end
 function w:ClearFocus() self.focused=false end
 function w:HighlightText() self.highlighted=true end
 function w:SetScript(event,fn) self.scripts[event]=fn end
 function w:SetTextColor(...) self.textColor={...} end
 function w:SetJustifyH() end
 function w:SetJustifyV() end
 function w:SetText(v) self.text=v end
 function w:GetText() return self.text end
 function w:GetFrameLevel() return self.level end
 function w:SetFrameLevel(v) self.level=v end
 function w:EnableMouse() end
 function w:Enable() self.enabled=true end
 function w:Disable() self.enabled=false end
 function w:HookScript(k,fn) self.scripts[k]=fn end
 function w:CreateFontString()
  local font=widget(nil,nil,'FontString');self.regions[#self.regions+1]=font;return font
 end
 return w
end
function CreateFrame(kind,name,parent,template)
 local frame=widget(name,parent,kind)
 if kind=='CheckButton' and name then widget(name..'Text',nil,'FontString') end
 if template=='UIDropDownMenuTemplate' and name then widget(name..'Button',frame,'Button');widget(name..'Text',nil,'FontString') end
 return frame
end
function InterfaceOptions_AddCategory() end
function Atr_StyleOfflineBrowser(frame,body) frame.body=body;frame.styled=true end
function Atr_AnalysisSkin() if type(ElvUI)=="table" then skinCalls=skinCalls+1;return true end end
local basic=widget('Atr_BasicOptionsFrame');basic.parent='Auctionator Remastered'
local tips=widget('Atr_TooltipsOptionsFrame');tips.parent='Auctionator Remastered'
local option=widget('testChoice',tips,'CheckButton');option.checked=true
option:SetPoint('TOPLEFT',tips,'TOPLEFT',20,-70)
local click=function() end;option.scripts.OnClick=click
local save,cancel=function() end,function() end;tips.okay=save;tips.cancel=cancel
local other=widget('OtherAddonOptions')
dofile('AuctionatorRemastered/Remastered/UI/Options.lua')
dofile('AuctionatorRemastered/Remastered/UI/OptionsHelp.lua')
dofile('AuctionatorRemastered/Remastered/UI/OptionsPages.lua')
dofile('AuctionatorRemastered/Remastered/UI/AboutLinks.lua')
dofile('AuctionatorRemastered/Remastered/UI/Appearance.lua')
local checks=0
local function check(v,s) checks=checks+1;assert(v,s) end
check(basic.name=='General' and tips.name=='Tooltips','existing categories get clear names without changing parent IDs')
tips.scripts.OnShow(tips)
check(tips.styled and tips.atrOptionsChrome.body,'shared shell and content theme applied')
check(option.points[1][5]==-86,'dense tooltip controls clear the heading area')
tips.scripts.OnShow(tips)
check(option.points[1][5]==-86,'reopening never accumulates layout offsets')
check(tips.okay==save and tips.cancel==cancel and option.scripts.OnClick==click and option.checked,'save, cancel, actions and values preserved')
check(skinCalls==0,'native pages do not call ElvUI handlers')
check(Atr_ProspectingTips.points[1][5]==-322,'JC checkbox first-open position survives legacy spacing')
local firstJcHeading
for _,region in ipairs({tips:GetRegions()})do if region:GetText()=='Show prospecting details' then firstJcHeading=region end end
check(firstJcHeading and firstJcHeading.points[1][5]==-352,'JC heading has a full 30px separation from checkbox on first open')
ElvUI={{}};tips.scripts.OnShow(tips);local once=skinCalls;tips.scripts.OnShow(tips)
check(once==3 and skinCalls==once,'ElvUI styles each tooltip checkbox only once')
registered.InterfaceOptions_AddCategory(other)
check(other.scripts.OnShow==nil and not other.styled,'unrelated addon pages untouched')
local appearance=assert(Atr_AppearanceOptions,'Appearance exists before any auction frame is initialized')
registered.InterfaceOptions_AddCategory(appearance)
check(appearance.atrOptionsHooked and appearance.name=='Appearance','late-created categories get the same styling')
check(QueryAuctionItems==nil and AUCTIONATOR_SAVEDVARS==nil,'presentation does not query auctions or write settings')
-- Both actual pages share a 36px row pitch and dropdown visible left edge.
for _,name in ipairs({'AuctionatorOption_Enable_Alt','AuctionatorOption_Open_All_Bags','AuctionatorOption_Show_StartingPrice'}) do
 local group=widget(name,basic);widget(name..'_CB',group,'CheckButton')
end
for _,name in ipairs({'ATR_tipsVendorOpt','ATR_tipsAuctionOpt','ATR_tipsDisenchantOpt'}) do
 local group=widget(name,tips);widget(name..'_CB',group,'CheckButton')
end
for _,name in ipairs({'Atr_tipsShiftDD','Atr_deDetailsDD'}) do
 local dropdown=widget(name,tips)
 widget(name..'Button',dropdown,'Button');widget(name..'Text',nil,'FontString')
end
for _,suffix in ipairs({'N','S','M','L'}) do widget('Atr_RB_'..suffix,basic,'CheckButton') end
basic.scripts.OnShow(basic);tips.scripts.OnShow(tips)
check(AuctionatorOption_Open_All_Bags.points[1][5]-AuctionatorOption_Enable_Alt.points[1][5]==-36
 and ATR_tipsAuctionOpt.points[1][5]-ATR_tipsVendorOpt.points[1][5]==-30,'General keeps its spacing and common tooltip prices form one compact group')
check(ATR_tipsVendorOpt_CB.width==24 and AuctionatorOption_Enable_Alt_CB.width==24,'checkbox sizes match across settings')
check(Atr_tipsShiftDD.points[1][4]==4 and Atr_tipsShiftDD.points[1][5]==-170
 and Atr_deDetailsDD.points[1][4]==4 and Atr_deDetailsDD.points[1][5]==-270,'dropdowns sit directly below their headings')
check(Atr_tipsShiftDDText.points[1][1]=='LEFT' and Atr_tipsShiftDDText.points[2][2]==Atr_tipsShiftDDButton,'dropdown text is aligned on the very first styled open')
Atr_tipsShiftDD:SetWidth(175);Atr_tipsShiftDDText:ClearAllPoints()
Atr_tipsShiftDDText:SetPoint('RIGHT',Atr_tipsShiftDDButton,'LEFT',-2,0)
Atr_tipsShiftDD.scripts.OnShow()
check(Atr_tipsShiftDD.width==220 and Atr_tipsShiftDDText.points[1][1]=='LEFT'
 and Atr_tipsShiftDDText.points[1][4]==28,'child OnShow initialization cannot undo dropdown width or text placement')
check(Atr_RB_N.hidden and not Atr_RB_N.checked,'None is hidden and never selected')
Atr_RB_S.checked=true;basic.scripts.OnShow(basic)
check(Atr_RB_S.checked and not Atr_RB_N.checked,'pending duration selection survives layout and skinning')
local about=widget('AuctionatorDescriptionFrame');about.parent='Auctionator Remastered'
registered.InterfaceOptions_AddCategory(about);about.scripts.OnShow(about)
check(#about.atrProjectLinks==2,'About exposes GitHub and Warperia text links')
about.atrProjectLinks[2].scripts.OnClick()
check(Atr_AboutLinkURL.text=='https://warperia.com/addon-wotlk/auctionator-remastered/' and Atr_AboutLinkURL.highlighted,'Warperia opens a selected, copyable URL')
about.atrProjectLinks[1].scripts.OnClick()
check(Atr_AboutLinkURL.text=='https://github.com/andreash-dev/Auctionator-Remastered-WotLK','GitHub link reuses the dialog with the correct URL')
about.scripts.OnShow(about)
check(#about.atrProjectLinks==2 and about.atrProjectLinks[1].atrOptionsSkinned,'reopening preserves blue text links without duplicated buttons')
-- Exercise the real skin adapter: unavailable/failed handlers must remain
-- retryable, and a later success must not skin the control twice.
local testSurface=Atr_StyleOfflineBrowser
dofile('AuctionatorRemastered/Remastered/UI/Theme.lua')
Atr_StyleOfflineBrowser=testSurface
local late=widget('LateSkinCheckbox',tips,'CheckButton');late.checked=true
ElvUI={{}}
tips.scripts.OnShow(tips)
check(not late.atrOptionsSkinned and late.checked,'missing ElvUI skin module does not mark controls done or change their value')
ElvUI[1].GetModule=function() return {HandleCheckBox=function() error('not ready') end} end
tips.scripts.OnShow(tips)
check(not late.atrOptionsSkinned and late.checked,'failed handler also remains retryable')
local successes=0
ElvUI[1].GetModule=function() return {HandleCheckBox=function() successes=successes+1 end} end
tips.scripts.OnShow(tips);tips.scripts.OnShow(tips)
check(late.atrOptionsSkinned and successes==1 and late.checked,'late-ready skin applies once and preserves the checkbox state')
ElvUI=nil
Atr_ThemeElvUI.scripts.OnClick()
check(Atr_ThemeElvUI.enabled==false and Atr_ThemeNative.checked and AUCTIONATOR_REMASTERED_THEME==nil,'Appearance does not offer usable ElvUI controls when it is absent')
ElvUI={{}}
Atr_ThemeNative.scripts.OnClick()
check(AUCTIONATOR_REMASTERED_THEME=='native' and Atr_ApplyThemeReload.enabled and AuctionatorRemastered.UI.UseElvUI(),'Appearance saves theme choice and offers reload without changing active widgets')
Atr_AppearanceBrowserTransparent.checked=false;Atr_AppearanceBrowserTransparent.scripts.OnClick(Atr_AppearanceBrowserTransparent)
Atr_AppearanceShoppingTransparent.checked=true;Atr_AppearanceShoppingTransparent.scripts.OnClick(Atr_AppearanceShoppingTransparent)
check(AUCTIONATOR_BROWSER_SETTINGS.browserTransparent==false and AUCTIONATOR_BROWSER_SETTINGS.shoppingTransparent==true,'Appearance has separate browser and planner background controls')
print('PASS: '..checks..' options theme, layout, registration and callback preservation checks')
-- Preference controls use explicit first-open captions and persist independently.
check(Atr_ScanCompleteSound.points[1][5]-Atr_ScanCompleteMessage.points[1][5]==-36,'scan notification checkboxes share 36px spacing')
check(Atr_ScanCompleteMessage:GetChecked() and not Atr_ScanCompleteSound:GetChecked(),'scan notification defaults')
Atr_ScanCompleteSound:SetChecked(true);Atr_ScanCompleteSound.scripts.OnClick(Atr_ScanCompleteSound)
check(AuctionatorRemastered.UI.ScanNotification('sound'),'sound choice persists')
entries={}
local database=widget('Atr_ScanningOptionsFrame')
AuctionatorRemastered.UI.Options.SetupPreferences(database)
check(Atr_OldPriceDays.selected==1 and Atr_OldPriceDays.caption=='1 day','age dropdown is populated on first open')
local browserRefresh,dealsRefresh=0,0
AuctionatorRemastered.UI.RefreshBrowserPriceAge=function() browserRefresh=browserRefresh+1 end
AuctionatorRemastered.UI.RefreshDealsPriceAge=function() dealsRefresh=dealsRefresh+1 end
entries[1].func()
check(AuctionatorRemastered.UI.PriceAgeDays()==0 and Atr_OldPriceDays.caption=='Disabled' and browserRefresh==1 and dealsRefresh==1,'disabled choice refreshes both views immediately')
print('PASS: scan notification spacing/persistence and price-age first-open caption/live refresh')
local market=widget('Atr_MarketHistoryDropdown',database)
widget('Atr_MarketHistoryDropdownButton',market,'Button');widget('Atr_MarketHistoryDropdownText',nil,'FontString')
function Atr_GetMarketHistoryDays() return tonumber(AUCTIONATOR_MARKET_HISTORY_DAYS) or 14 end
AuctionatorRemastered.UI.Options.Layout(database)
check(market.caption=='14 days','Market comparison caption is restored after first layout without opening its menu')
AUCTIONATOR_MARKET_HISTORY_DAYS=7;market.caption=''
market.scripts.OnShow()
check(market.caption=='7 days','Market comparison caption preserves saved choice on later shows')
print('PASS: Market comparison caption after styling and saved choice on reopen')
check(Atr_ApplyThemeReload.points[1][1]=='TOPRIGHT' and Atr_ApplyThemeReload.points[1][4]==-24,'Reload button stays inside narrow Appearance pages')
check(-Atr_AppearanceShoppingTransparent.points[1][5]+24<=408,'last Appearance checkbox fits the stock-height content area')
check(Atr_AppearanceShoppingTransparent.points[1][5]-Atr_AppearanceBrowserTransparent.points[1][5]==-36,'compact Appearance retains checkbox spacing')
print('PASS: compact Appearance bounds and right-aligned Reload action')

check(-Atr_ScanCompleteSound.points[1][5]+24<=408,'General sound option fits the stock-height content area')
print('PASS: General fits the original Interface options window')
local retention=database:CreateFontString();retention:SetText('On start-up delete historical prices older than:')
local unit=database:CreateFontString();unit:SetText('days')
widget('Atr_ScanOpts_MaxHistAge',database,'EditBox')
AuctionatorRemastered.UI.Options.Layout(database)
check(Atr_ScanOpts_MaxHistAge.points[1][4]==24 and Atr_ScanOpts_MaxHistAge.points[1][5]==-300 and unit.points[1][2]==Atr_ScanOpts_MaxHistAge and unit.points[1][4]==6,'retention field uses its own aligned row below the label')
check(Atr_OldPriceDays.points[1][5]==-356,'last Database dropdown leaves room above the stock panel bottom')
local stacks=widget('Atr_StackingOptionsFrame')
widget('Atr_Stacking_List',stacks)
widget('Atr_StackingOptionsFrame_Edit',stacks,'Button');widget('Atr_StackingOptionsFrame_New',stacks,'Button')
Atr_StyleOfflineBrowser=function() end
AuctionatorRemastered.UI.Options.Layout(stacks)
check(Atr_Stacking_List.height==156 and Atr_StackingVisibleRows==9,'nine stack rows fit the smaller scrolling viewport')
check(-stacks.atrStackHelp.points[1][5]+stacks.atrStackHelp.height<=408,'stack guidance fits inside the original content area')
check(stacks.atrStackHelp.regions[2].height==84,'full guide has room for wrapped lines')
print('PASS: Database field alignment and stock-size stack list/help bounds')

check(Atr_ProspectingTips.points[1][5]==-322 and Atr_ProspectingDetails.points[1][5]==-368,'JC value and details fit the original panel')
check(ATR_tipsDisenchantOpt.points[1][5]==-224 and Atr_deDetailsDD.points[1][5]==-270,'DE value and details stay together')
check(Atr_ProspectingDetails.caption=='when SHIFT is held down','JC defaults to Shift')
entries={};AuctionatorRemastered.UI.Options.SetupPreferences(tips)
-- Reopen initialization as the actual dropdown does when it builds its menu.
-- Capture initialization explicitly for the new dropdown below.
Atr_ProspectingDetails=nil
entries={};AuctionatorRemastered.UI.Options.SetupPreferences(tips)
check(#entries==5,'JC menu contains all five modes')
entries[3].func()
check(AUCTIONATOR_SAVEDVARS.prospectingDetails=='alt' and AuctionatorRemastered.UI.ProspectingDetailsMode()=='alt','JC selected modifier persists')
AuctionatorRemastered.UI.Options.SetupPreferences(tips)
check(Atr_ProspectingDetails.caption=='when ALT is held down','JC caption survives reopening')
print('PASS: grouped material settings fit stock panel and JC detail modes persist')

local jcHeading
for _,region in ipairs({tips:GetRegions()})do if region:GetText()=='Show prospecting details' then jcHeading=region end end
check(jcHeading and jcHeading.points[1][5]==-352,'JC heading is restored above the dropdown after shared first-open spacing')
