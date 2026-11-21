dofile("AuctionatorRemastered/Remastered/Core/Bootstrap.lua")
dofile("AuctionatorRemastered/Remastered/Integration/LegacyBridge.lua")
-- lua5.1 tools/tests/test_deals.lua
local function read(path) local f=assert(io.open(path));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local checks=0
local function check(v,message) checks=checks+1;assert(v,message) end
local today,now=100,1000000
function Atr_GetScanDay_Today() return today end
function time() return now end
local market=read('AuctionatorRemastered/Remastered/Models/MarketHistory.lua')
function hooksecurefunc() end
assert(loadstring(market))()
local hooks={}
function hooksecurefunc(name,fn) hooks[name]=hooks[name] or {};table.insert(hooks[name],fn) end
dofile('AuctionatorRemastered/Remastered/Models/Deals.lua')
dofile('AuctionatorRemastered/Remastered/UI/Theme.lua')
dofile('AuctionatorRemastered/Remastered/UI/Appearance.lua')
assert(loadfile('AuctionatorRemastered/Remastered/Features/Deals.lua'))()
local opts={maxMarket=70,minProfit=1,maxAge=24,minDays=3,resale=95,cut=5}
local function item(buy,age,days)
 local d={mr=buy,lastScan=now-(age or 1)*3600}
 for i=1,(days or 3) do d['M'..(today-i)]=100000 end
 return d
end
local db={Good=item(50000),Better=item(30000),Expensive=item(80000),Stale=item(20000,25),New=item(10000,1,0)}
local records,priced,eligible=Atr_BuildDeals(opts,'','profit',db,now)
check(#records==2 and records[1].name=='Better','filters and descending per-item profit')
check(priced==5 and eligible==3,'coverage includes items rejected only by discount/profit')
local good=records[2]
check(good.reference==100000 and good.market==50,'existing historical median used')
check(good.resale==95000 and good.fee==4750 and good.net==90250 and good.profit==40250,'gold estimate after commission')
check(good.days==3 and not good.preliminary,'mature history')
check(#Atr_BuildDeals(opts,'GOOD','profit',db,now)==1,'literal case-insensitive filter')
check(#Atr_BuildDeals(opts,'[','profit',db,now)==0,'search is not a Lua pattern')
opts.maxMarket=90
check(#Atr_BuildDeals(opts,'','profit',db,now)==3,'maximum market filter editable')
opts.minProfit=2
check(#Atr_BuildDeals(opts,'','profit',db,now)==2,'minimum profit is gold, not copper')
opts=Atr_DealsOptions(nil)
check(opts.maxMarket==70 and opts.minDays==3 and opts.resale==95 and opts.cut==5,'sensible defaults')
opts.minDays=0
records=Atr_BuildDeals(opts,'','profit',{NoPrior={mr=10000,lastScan=now},OneDay=item(30000,1,1)},now)
check(#records==1 and records[1].name=='OneDay' and records[1].preliminary,'preliminary can be included; latest-only fallback is not invented discount')
local bad={NoStamp={mr=100},Future={mr=100,lastScan=now+1},Zero=item(0),Negative=item(-1),Infinite=item(math.huge),NaN=item(0/0),Scalar=1}
check(#Atr_BuildDeals(opts,'','profit',bad,now)==0,'invalid prices and unknown/future timestamps excluded')
opts.maxAge=24
check(#Atr_BuildDeals(opts,'','profit',{Boundary=item(1000,24)},now)==1,'age boundary inclusive')
opts.minDays=3;AUCTIONATOR_MARKET_HISTORY_DAYS=3
local short=item(1000,1,2);short.M96=100000
check(#Atr_BuildDeals(opts,'','profit',{Short=short},now)==0,'history outside selected reference window not counted')
AUCTIONATOR_MARKET_HISTORY_DAYS=14
local before=db.Good.mr
Atr_BuildDeals(opts,'','market',db,now)
check(db.Good.mr==before and db.Good.M99==100000,'read-only price/history calculation')
local clean=Atr_DealsOptions({cut=200,maxAge=-1,minDays=4.9,resale=0,minProfit=0/0,maxMarket='not a number'})
check(clean.cut==100 and clean.maxAge==0 and clean.minDays==4 and clean.resale==1 and clean.minProfit==1 and clean.maxMarket==70,'input validation and bounded values')
opts.minProfit=0;opts.cut=100
check(#Atr_BuildDeals(opts,'','profit',db,now)==0,'100 percent commission never gives positive deals')
opts.cut=0;opts.resale=100
records=Atr_BuildDeals(opts,'','market',{B=item(40000),A=item(40000),C=item(20000)},now)
check(records[1].name=='C' and records[2].name=='A','market sort and deterministic tie order')
check(#Atr_BuildDeals(opts,'','profit',{},now)==0,'empty database')
-- Fractional copper at the commission boundary is rounded conservatively.
records=Atr_BuildDeals({maxMarket=1000,minProfit=0,minDays=0,resale=100,cut=5},'',nil,{Tiny={mr=19,lastScan=now,M99=21}},now)
check(#records==1 and records[1].fee==2 and records[1].profit==0,'commission rounded up rather than overstating profit')

-- Exercise real UI constructors and callbacks with a minimal 3.3.5 frame fixture.
local widgets={}
local function widget(name,parent)
 local w={name=name,parent=parent,shown=true,scripts={},height=450,points={}}
 widgets[#widgets+1]=w;if name then _G[name]=w end
 function w:SetScript(k,v) self.scripts[k]=v end
 function w:GetScript(k) return self.scripts[k] end
 function w:SetScale(v) self.scale=v end
 function w:GetNumPoints() return #self.points end
 function w:GetPoint(i) return unpack(self.points[i]) end
 function w:HookScript(key,fn) local old=self.scripts[key];self.scripts[key]=function(...) if old then old(...) end;fn(...) end end
 function w:SetChecked(v) self.checked=v end
 function w:EnableMouse(v) self.mouse=v end
 function w:SetMovable(v) self.movable=v end
 function w:Show() local change=not self.shown;self.shown=true;if change and self.scripts.OnShow then self.scripts.OnShow(self) end end
 function w:Hide() local change=self.shown;self.shown=false;if change and self.scripts.OnHide then self.scripts.OnHide(self) end end
 function w:IsShown() return self.shown end
 function w:GetName() return self.name end
 function w:SetText(s) self.text=tostring(s);if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self) end end
 function w:GetText() return self.text or '' end
 function w:GetFontString() if not self.font then self.font=widget(nil,self) end;return self.font end
 function w:SetID(n) self.id=n end
 function w:GetID() return self.id end
 function w:SetPoint(...) self.points[#self.points+1]={...} end
 function w:ClearAllPoints() self.points={} end
 function w:GetHeight() return self.height end
 function w:GetWidth() return self.width or 800 end
 function w:GetLeft() return 0 end
 function w:GetRight() return 832 end
 function w:GetFrameLevel() return self.level or 1 end
 function w:SetFrameLevel(level) self.level=level end
 function w:GetEffectiveScale() return self.scale or 1 end
 function w:GetBottom() return 10 end
 function w:GetTop() return 15 end
 function w:GetRegions() return end
 function w:SetSize(width,height) self.width=width;self.height=height end
 function w:SetWidth(width) self.width=width end
 function w:SetHeight(height) self.height=height end
 function w:CreateFontString() return widget(nil,self) end
 function w:CreateTexture() return widget(nil,self) end
 function w:ClearFocus() end
 function w:SetBackdrop(value) self.backdrop=value end
 function w:SetVerticalScroll(n) self.offset=n end
 function w:GetChecked() return self.checked end
 function w:IsObjectType() return false end
 for _,method in ipairs({'SetFrameStrata','SetClampedToScreen','RegisterForDrag','StartMoving','StopMovingOrSizing','RegisterForClicks','LockHighlight','UnlockHighlight','SetHighlightFontObject','SetTexCoord','SetBackdropBorderColor','SetBackdropColor','SetAutoFocus','SetMaxLetters','SetNormalFontObject','SetHighlightTexture','SetAllPoints','SetTexture','SetJustifyH','SetOwner','AddLine'}) do w[method]=function() end end
 return w
end
function CreateFrame(kind,name,parent,template)
 local w=widget(name,parent)
 if kind=='CheckButton' and name then widget(name..'Text',w) end
 if template=='FauxScrollFrameTemplate' and name then
  local bar=widget(name..'ScrollBar',w)
  widget(name..'ScrollBarScrollUpButton',bar);widget(name..'ScrollBarScrollDownButton',bar)
 end
 return w
end
function FauxScrollFrame_Update(w,count,visible) w.count=count;w.visible=visible end
function FauxScrollFrame_GetOffset(w) return w.offset or 0 end
function FauxScrollFrame_SetOffset(w,n) w.offset=n end
function FauxScrollFrame_OnVerticalScroll(w,n,step,fn) w.offset=math.floor(n/step);fn() end
function PanelTemplates_SetNumTabs(w,n) w.numTabs=n end
function PanelTemplates_TabResize(w) w.width=#(w.text or "")*7+32 end
function PanelTemplates_EnableTab() end
local appearanceCategory
function InterfaceOptions_AddCategory(frame) appearanceCategory=frame end
function PanelTemplates_SetTab(w,n) w.selected=n end
function GetItemInfo() end
function GetRealmName() return 'Realm' end
function UnitFactionGroup() return 'Alliance' end
function UnitName() return 'Nisho' end
function date(_,stamp) return tostring(stamp) end
function IsShiftKeyDown() return false end
local chartItem
function Atr_ShowPriceChart(name,price) chartItem={name,price} end
function HideUIPanel(w) w:Hide() end
gAtrZC={priceToMoneyString=function(n) return tostring(n) end}
UIParent=widget('UIParent');UIParent.width=1920
GameTooltip=widget()
function GameTooltip:SetHyperlink(link) self.hyperlink=link;self.item=link end
function GameTooltip:GetItem() return self.item end
function GameTooltip:ClearLines() self.item=nil;self.hyperlink=nil;self.lines={} end
function GameTooltip:SetOwner() self:ClearLines() end
function GameTooltip:AddLine(text) self.lines=self.lines or {};table.insert(self.lines,text) end
AuctionFrame=widget('AuctionFrame');AuctionFrame.numTabs=6
AuctionFrameMoneyFrame=widget('AuctionFrameMoneyFrame')
for i=1,6 do widget('AuctionFrameTab'..i) end
for _,name in ipairs({'AuctionFrameBrowse','AuctionFrameBid','AuctionFrameAuctions','Atr_Main_Panel','AuctionFrameTitleText'}) do widget(name) end
local atlas,originallyHidden=widget(),widget()
function atlas:IsObjectType(kind) return kind=='Texture' end
function originallyHidden:IsObjectType(kind) return kind=='Texture' end
originallyHidden:Hide()
function AuctionFrame:GetRegions() return atlas,originallyHidden end
AuctionFramePortrait=widget('AuctionFramePortrait')
AuctionFrameCloseButton=widget('AuctionFrameCloseButton')

function Atr_AuctionFrameTab_OnClick()
 -- The actual core's pre-transition hide must precede destination visibility.
 if Atr_DealsPanel then Atr_DealsPanel:Hide() end
 if Atr_TradingLogs then Atr_TradingLogs:Hide() end
 AuctionFrameMoneyFrame:Show()
end
check(read('AuctionatorRemastered/Legacy/Auctionator.lua'):find('if Atr_DealsPanel then Atr_DealsPanel:Hide(); end',1,true)~=nil,'core hides overlay before ordinary tab visibility')
AUCTIONATOR_SAVEDVARS={};gAtr_ScanDB=db
-- Use the same real category/filter implementation as the offline browser.
AuctionatorRemastered.Browser.Settings=function() return AUCTIONATOR_BROWSER_SETTINGS or {} end
dofile('AuctionatorRemastered/Remastered/Models/BrowserCategories.lua')
function Atr_IsBrowserFavorite(name) return name=='Better' end
local metadata={Better={class='Unclassified',link='item:123:0:0:0:0:0:-45:0'}}
function Atr_GetBrowserItemMetadata(name) return metadata[name] or {class='Unclassified'} end

-- Load Logs after Deals, in the actual TOC order.
dofile('AuctionatorRemastered/Remastered/Models/TradingLogs.lua')
assert(loadfile('AuctionatorRemastered/Remastered/Features/TradingLogs.lua'))()
for _,fn in ipairs(hooks.Atr_Init) do fn() end
check(AuctionFrameTab7.text=='Deals' and AuctionFrameTab8.text=='Logs','Deals placed between Undercuts and Logs')
check(not Atr_DealsPanel:IsShown() and not Atr_TradingLogs:IsShown(),'both panels initially hidden')
AuctionFrameTab7.scripts.OnClick()
check(Atr_DealsPanel:IsShown() and not AuctionFrameMoneyFrame:IsShown(),'Deals opens opaque independent panel with money hidden')
check(Atr_DealsPanel.points[2][5]==1,'native panel bottom covers transparent tab artwork padding')
check(AuctionFrameTab7:GetFrameLevel()>Atr_DealsPanel:GetFrameLevel(),'selected tab artwork stays above new bottom edge')
check(Atr_DealsScroll.count==2 and Atr_DealsScroll.visible==14,'results rendered within header/footer limits')
local row
for _,w in ipairs(widgets) do if w.data and w.data.name=='Better' and w.fields and w.icon then row=w end end
check(row~=nil,'deal row with missing icon still rendered')
check(Atr_DealsDetails.parent==UIParent and Atr_DealsDetails:IsShown() and Atr_DealsDetails.points[1][2]==Atr_DealsPanel and Atr_DealsDetails.points[2][3]=='BOTTOMRIGHT' and Atr_DealsDetails.height==Atr_DealsPanel.height,'independent details window matches AH height and follows both AH edges by default')
row.scripts.OnEnter(row)
check(GameTooltip.hyperlink=='item:123:0:0:0:0:0:-45:0','hover renders original item tooltip with exact suffix link')
check(Atr_DealsDetails.item.text=='Better' and Atr_DealsDetails.values[1].text=='30000','hover automatically updates the separate price details')
check(#GameTooltip.lines==0,'deal calculations are no longer appended to the item tooltip')
row.scripts.OnLeave(row)
check(Atr_DealsDetails:IsShown() and Atr_DealsDetails.item.text=='Better','details remain readable after leaving a row')
local uncached
for _,w in ipairs(widgets) do if w.fields and w.icon and w.data and w.data.name=='Good' then uncached=w end end
uncached.scripts.OnEnter(uncached)
check(GameTooltip.lines[1]=='Good' and GameTooltip.lines[2]:find('not cached',1,true),'uncached item shows truthful fallback instead of fabricated stats')
check(Atr_DealsDetails.item.text=='Good','uncached items retain complete saved deal details')
row.scripts.OnEnter(row)
Atr_DealsDetails.scripts.OnDragStop(Atr_DealsDetails)
check(AUCTIONATOR_SAVEDVARS.dealsDetailPosition.x==0 and AUCTIONATOR_SAVEDVARS.dealsDetailPosition.y==10,'dragged details position is saved separately from deal filters')

row.scripts.OnClick(row);check(chartItem and chartItem[1]=='Better' and chartItem[2]==30000,'row opens existing chart with saved current price')
AuctionFrameTab8.scripts.OnClick()
check(not Atr_DealsDetails:IsShown(),'details closes when leaving Deals')
check(not Atr_DealsPanel:IsShown() and Atr_TradingLogs:IsShown() and not AuctionFrameMoneyFrame:IsShown(),'Deals to Logs restores then hides money correctly')
AuctionFrameTab7.scripts.OnClick()
check(Atr_DealsDetails.points[1][1]=='BOTTOMLEFT' and Atr_DealsDetails.points[1][5]==10,'saved independent details position is restored')
Atr_DealsDetailsReset.scripts.OnClick()
check(not AUCTIONATOR_SAVEDVARS.dealsDetailPosition and Atr_DealsDetails.points[1][2]==Atr_DealsPanel and Atr_DealsDetails.points[2][3]=='BOTTOMRIGHT','reset clears detached position and restores height-matched following anchors')
local moves,stops=0,0
function AuctionFrame:StartMoving() moves=moves+1 end
function AuctionFrame:StopMovingOrSizing() stops=stops+1 end
Atr_AuctionFrameMover.scripts.OnDragStart()
Atr_AuctionFrameMover.scripts.OnDragStop()
check(moves==1 and stops==1 and Atr_AuctionFrameMover.parent==AuctionFrame,'header dragging moves the AH rather than its controls or details')
check(Atr_DealsDetails.points[1][2]==Atr_DealsPanel,'details follows the moved auction frame through its relative anchor')
check(appearanceCategory==Atr_AppearanceOptions and appearanceCategory.name=='Appearance' and appearanceCategory.parent=='Auctionator','Appearance is registered under Auctionator options')
check(AUCTIONATOR_SAVEDVARS.auctionFramePosition.y==10,'AH drag saves its placement')
AuctionFrame:Hide();AuctionFrame:Show()
check(Atr_AuctionPositionRestore:IsShown(),'opening AH schedules restoration after native layout handlers')
Atr_AuctionPositionRestore.scripts.OnUpdate(Atr_AuctionPositionRestore)
check(AuctionFrame.points[1][1]=='BOTTOMLEFT' and AuctionFrame.points[1][5]==10,'AH position survives close and reopen')
AUCTIONATOR_SAVEDVARS.auctionFramePosition={x=600,y=200};AuctionFrame.scale=2
AuctionFrame:Hide()
AUCTIONATOR_SAVEDVARS.auctionFramePosition={x=600,y=200}
AuctionFrame:Show();Atr_AuctionPositionRestore.scripts.OnUpdate(Atr_AuctionPositionRestore)
check(AuctionFrame.points[1][4]==300 and AuctionFrame.points[1][5]==100,'saved AH placement restores correctly at a different scale')
AuctionFrame.scale=nil
Atr_AllowAuctionMovement:SetChecked(false);Atr_AllowAuctionMovement.scripts.OnClick(Atr_AllowAuctionMovement)
local beforeMoves=moves
Atr_AuctionFrameMover.scripts.OnDragStart()
check(AUCTIONATOR_SAVEDVARS.moveAuctionFrame==false and not Atr_AuctionFrameMover.mouse and moves==beforeMoves,'Appearance lock disables the mover and guards drag starts')
Atr_AllowAuctionMovement:SetChecked(true);Atr_AllowAuctionMovement.scripts.OnClick(Atr_AllowAuctionMovement)
check(Atr_AuctionFrameMover.mouse and AUCTIONATOR_SAVEDVARS.moveAuctionFrame,'Appearance allows movement again')
AUCTIONATOR_SAVEDVARS.dealsDetailPosition={x=900,y=100}
Atr_ResetAuctionPosition.scripts.OnClick()
check(not AUCTIONATOR_SAVEDVARS.auctionFramePosition and AuctionFrame.points[1][1]=='TOPLEFT' and AUCTIONATOR_SAVEDVARS.dealsDetailPosition.x==900,'AH reset restores default independently of the detached side panel')
Atr_ResetDetailsPosition.scripts.OnClick()
check(not AUCTIONATOR_SAVEDVARS.dealsDetailPosition and Atr_DealsDetails.points[1][2]==Atr_DealsPanel,'Appearance side-panel reset restores following beside AH')


check(Atr_DealsPanel:IsShown() and not Atr_TradingLogs:IsShown() and not AuctionFrameMoneyFrame:IsShown(),'Logs to Deals hides previous overlay')
Atr_AuctionFrameTab_OnClick()
check(not Atr_DealsPanel:IsShown() and AuctionFrameMoneyFrame:IsShown(),'return to ordinary tabs restores visibility')
check(AuctionFrameTab7:GetFrameLevel()==1 and AuctionFrameTab8:GetFrameLevel()==1,'ordinary tabs recover original draw order')
local toc=read('AuctionatorRemastered/AuctionatorRemastered.toc')
check(toc:find('Features\\Deals.lua',1,true)<toc:find('Features\\TradingLogs.lua',1,true),'TOC registration order preserved')
-- Log sorting operates on all matching records, not just the visible rows.
local ledgerRows={
 {kind='Listed',name='zebra',quantity=100,unit=30,total=3000,character='Alt',when=now-3},
 {kind='Bought',name='Apple',quantity=2,unit=50,total=100,character='Nisho',when=now-1},
 {kind='Bought',name='banana',quantity=10,unit=20,total=200,character='Other',when=now-2},
}
for _,key in ipairs({'kind','name','quantity','unit','total','character','when'}) do
 local sorted={unpack(ledgerRows)}
 Atr_SortTradingLogs(sorted,key,false)
 local low,high=sorted[1][key],sorted[#sorted][key]
 check(type(low)=='number' and low<=high or type(low)=='string' and low:lower()<=high:lower(),'ascending '..key)
 Atr_SortTradingLogs(sorted,key,true)
 check(sorted[1][key]==high and sorted[#sorted][key]==low,'descending '..key)
end
check(ledgerRows[1].name=='zebra','display sorting does not reorder source ledger')
local tied={{name='Same',quantity=2},{name='same',quantity=4}}
Atr_SortTradingLogs(tied,'name',false)
check(tied[1].quantity==2,'equal keys preserve original date order')
local key='Realm_Alliance'
AUCTIONATOR_PURCHASES={[key]={records={}}};AUCTIONATOR_OWN_AUCTIONS={[key]={records={}}}
for i=1,20 do
 local record={name='Item '..i,stackSize=i,stacks=1,stackPrice=i*100,when=now-i,character='Nisho'}
 table.insert(i%2==0 and AUCTIONATOR_PURCHASES[key].records or AUCTIONATOR_OWN_AUCTIONS[key].records,record)
end
AuctionFrameTab8.scripts.OnClick()
check(Atr_LogsScroll.count==20 and Atr_LogsScroll.visible==13,'all log results retained behind scroll')
local function visibleLogs()
 local result={}
 for _,w in ipairs(widgets) do if w.parent==Atr_TradingLogs and w.fields and w.shown and w.data then result[#result+1]=w end end
 return result
end
check(visibleLogs()[1].data.quantity==1,'default newest-first order')
Atr_LogsScroll.offset=8
Atr_LogsSort_quantity.scripts.OnClick()
check(Atr_LogsScroll.offset==0 and visibleLogs()[1].data.quantity==1,'quantity click resets scroll and sorts numerically ascending')
Atr_LogsSort_quantity.scripts.OnClick()
check(visibleLogs()[1].data.quantity==20,'second quantity click reverses sort')
Atr_LogsSort_kind.scripts.OnClick()
check(visibleLogs()[1].data.kind=='Bought','action header sorts purchases first')
Atr_LogsSort_kind.scripts.OnClick()
check(visibleLogs()[1].data.kind=='Listed','action header reverses')
Atr_LogsSort_name.scripts.OnClick()
check(visibleLogs()[1].data.name=='Item 1','item header sorts names')
Atr_LogsSearch:SetText('Item 2')
check(Atr_LogsScroll.count==2,'search filters remain usable after sorting')
check(AUCTIONATOR_PURCHASES[key].records[1].name=='Item 2','header clicks do not mutate persistent purchases')
local _,spent,listed,bought,offered=Atr_GetTradingLogs('All','',30,nil)
check(spent==11000 and listed==10000 and bought==110 and offered==100,'filtered totals and quantities retain original meaning after sorting')
Atr_LogsClearSearch.scripts.OnClick()
check(Atr_LogsScroll.count==20,'clear search restores matching history')
check(Atr_TradingLogs.results.points[1][4]==10 and Atr_TradingLogs.results.points[1][5]==-106,'Logs list spans full width below top filters')
check(not Atr_TradingLogs.sidebar,'Logs does not reserve a cramped sidebar')
check(Atr_TradingLogs.backdrop~=nil,'vanilla receives a clean opaque replacement backdrop')
check(not atlas:IsShown() and not AuctionFramePortrait:IsShown(),'vanilla atlas and actual portrait hidden on Logs')
check(AuctionFrameCloseButton:IsShown(),'native header close button remains usable')
check(AuctionFrameCloseButton.points[1][2]==Atr_TradingLogs and AuctionFrameCloseButton.points[1][4]==-2 and AuctionFrameCloseButton.points[1][5]==-2,'stock close X follows Logs upper-right corner')
check(AuctionFrameCloseButton:GetFrameLevel()>Atr_TradingLogs:GetFrameLevel(),'close X is above overlay content')
check(Atr_LogsCloseButton.text=='Close','single custom close control is a footer button, not a second header X')
local logRow=visibleLogs()[1]
check(logRow.fields[4].width>=110 and logRow.fields[5].width>=118,'full-size numeric price columns')
local bg={bgFile='native-background',edgeFile='native-border'}
Atr_AuctionFrameTab_OnClick()
check(atlas:IsShown() and AuctionFramePortrait:IsShown() and not originallyHidden:IsShown(),'vanilla decoration restores exactly on ordinary tabs')
check(AuctionFrameCloseButton:GetFrameLevel()==1 and #AuctionFrameCloseButton.points==0,'close X original layer and anchors restored on ordinary tabs')
AuctionFrameBrowse.RightBackground={GetBackdrop=function() return bg end,GetBackdropColor=function() return .1,.1,.1,.8 end}
AuctionFrame.backdrop=widget()
Atr_AuctionFrameTab_OnClick();AuctionFrameTab8.scripts.OnClick()
check(Atr_TradingLogs.results.backdrop==bg,'Logs reuses the active Browse result backdrop')
check(Atr_TradingLogs.backdrop==nil and atlas:IsShown(),'skinned shell keeps its background without stacking an opaque overlay')
check(Atr_TradingLogs.points[1][2]==AuctionFrame.backdrop,'Logs aligns to actual visible ElvUI shell')
check(not AuctionFrameTitleText:IsShown(),'native title hidden while replacement title is displayed')
Atr_AuctionFrameTab_OnClick()
check(AuctionFrameTitleText:IsShown(),'native title visibility restored after leaving Logs')
AuctionFrameTab7.scripts.OnClick()
check(Atr_DealsPanel.backdrop==nil and Atr_DealsPanel.sidebar,'Deals keeps the themed shell and category sidebar')
check(Atr_DealsPanel.results.backdrop==bg,'Deals reuses the same native Browse background as Logs')
check(Atr_DealsPanel.points[1][2]==AuctionFrame.backdrop,'Deals aligns to actual visible ElvUI shell')
for _,frame in ipairs({Atr_DealsPanel.results,Atr_TradingLogs.results}) do
 check(frame.points[1][4]==(frame==Atr_DealsPanel.results and 178 or 10) and frame.points[2][4]==-28,'list reserves a right gutter for the scrollbar')
end
check(Atr_DealsCloseButton.text=='Close','Deals close control stays in footer')
for _,key in ipairs({'maxMarket','minProfit','maxAge','minDays','resale','cut'}) do
 local input=_G['Atr_DealsFilter_'..key]
 check(input.parent==((key=='maxMarket' or key=='minProfit') and Atr_DealsPanel or Atr_DealsAdvanced),'main/advanced filter placement '..key)
end
local dealRow
for _,w in ipairs(widgets) do if w.parent==Atr_DealsPanel and w.fields and w.icon and w.shown then dealRow=w;break end end
check(dealRow.fields[2].width>=110 and dealRow.fields[3].width>=118 and #dealRow.fields==5,'five readable columns preserve full numeric prices')
Atr_DealsFilter_minProfit:SetText('2');Atr_DealsFilter_minProfit.scripts.OnEditFocusLost(Atr_DealsFilter_minProfit)
check(AUCTIONATOR_SAVEDVARS.deals.minProfit==2 and Atr_DealsScroll.count==2,'relocated filter still saves and refreshes results')
Atr_DealsPanel.height=390
Atr_DealsScroll.scripts.OnVerticalScroll(Atr_DealsScroll,0)
check(Atr_DealsScroll.visible==11,'shorter window keeps final row above footer')
Atr_DealsPanel.height=450
Atr_AuctionFrameTab_OnClick()
check(AuctionFrameTitleText:IsShown(),'Deals restores native title after leaving tab')
AuctionFrameBrowse.RightBackground=nil;AuctionFrame.backdrop=nil
AuctionFrameTab7.scripts.OnClick()
check(Atr_DealsPanel.backdrop~=nil and not atlas:IsShown() and not AuctionFramePortrait:IsShown(),'Deals also replaces vanilla dividers, money recess and portrait')
check(Atr_DealsPanel.points[1][2]==AuctionFrame,'vanilla aligns to the original native frame')
AuctionFrameTab8.scripts.OnClick();Atr_AuctionFrameTab_OnClick()
check(atlas:IsShown() and AuctionFramePortrait:IsShown() and not originallyHidden:IsShown(),'restoration survives Deals to Logs to Browse')
-- Real tab coordinates may lie below the old frame bottom, and skins can
-- give tabs a different scale. Negative insets must not be clamped away.
local probe=widget()
local savedBottom,savedTop=AuctionFrame.GetBottom,AuctionFrameTab1.GetTop
AuctionFrame.GetBottom=function() return 100 end
AuctionFrameTab1.GetTop=function() return 90 end
Atr_AnalysisFit(probe)
check(probe.points[2][5]==-14,'native overlap bridges tabs below the frame bottom')
AuctionFrameTab1.scale=2;probe.scale=.5
Atr_AnalysisFit(probe)
check(probe.points[2][5]==152,'native tab seam converts distinct effective scales with artwork overlap')
AuctionFrame.GetBottom=savedBottom;AuctionFrameTab1.GetTop=savedTop;AuctionFrameTab1.scale=nil
-- ElvUI skins are optional and protected; runtime errors never break a panel.
local skinned={}
ElvUI={{GetModule=function() return {HandleButton=function(_,control) skinned[control]=true end} end}}
local b=widget();Atr_AnalysisSkin(b,'Button');check(skinned[b],'uses installed ElvUI button handler')
ElvUI={{GetModule=function() error('disabled') end}}
check(pcall(Atr_AnalysisSkin,b,'Button'),'missing/disabled skin handled safely')
ElvUI=nil
check(pcall(Atr_AnalysisSkin,b,'Button'),'standard UI requires no ElvUI')
for _,spec in ipairs({{Atr_DealsScroll,Atr_DealsPanel.results},{Atr_LogsScroll,Atr_TradingLogs.results}}) do
 local viewport,content=spec[1],spec[2]
 local bar=_G[viewport:GetName()..'ScrollBar']
 check(bar.points[1][2]==content and bar.points[1][3]=='TOPRIGHT' and bar.points[1][4]==3,'track is anchored outside the content border')
 check(bar.points[1][5]==-19 and bar.points[2][5]==19 and bar.width==18,'track reserves arrow height inside top and bottom borders')
 local up=_G[bar:GetName()..'ScrollUpButton'];local down=_G[bar:GetName()..'ScrollDownButton']
 check(up.width==18 and down.width==18 and up.points[1][3]=='TOP' and down.points[1][3]=='BOTTOM','arrows stay compact and attached to track')
end
local scrollbarSkins=0
ElvUI={{GetModule=function() return {HandleScrollBar=function(_,bar) scrollbarSkins=scrollbarSkins+1;bar:ClearAllPoints();bar:SetPoint('CENTER') end} end}}
Atr_StyleAnalysisScroll(Atr_DealsScroll,Atr_DealsPanel.results)
check(scrollbarSkins==1 and #Atr_DealsScrollScrollBar.points==2,'uses native ElvUI scrollbar skin then reapplies safe anchors')
ElvUI=nil
-- Category navigation, column sorting and explicit live Buy handoff.
AuctionFrameTab7.scripts.OnClick()
check(not Atr_DealsAdvanced:IsShown(),'advanced settings starts closed')
Atr_DealsSettings.scripts.OnClick()
check(Atr_DealsAdvanced:IsShown() and Atr_DealsAdvanced.backdrop,'advanced settings opens a solid dialog')
Atr_DealsFilter_maxAge:SetText('12');Atr_DealsFilter_maxAge.scripts.OnEditFocusLost(Atr_DealsFilter_maxAge)
check(AUCTIONATOR_SAVEDVARS.deals.maxAge==12,'advanced age setting persists')
AuctionFrameTab8.scripts.OnClick()
check(not Atr_DealsAdvanced:IsShown(),'advanced dialog closes when leaving Deals')
AuctionFrameTab7.scripts.OnClick()
local function visibleDeals()
 local result={}
 for _,w in ipairs(widgets) do if w.parent==Atr_DealsPanel and w.fields and w.icon and w.shown and w.data then result[#result+1]=w end end
 return result
end
local function category(class,subclass,slot)
 for i=1,24 do
  local b=_G['Atr_DealsCategory'..i];local n=b.node
  if b.shown and n and n.class==class and n.subclass==subclass and n.slot==slot then return b end
 end
end
local function selectCategory(class,subclass,slot)
 local b=assert(category(class,subclass,slot),'missing category '..tostring(class)..' '..tostring(subclass)..' '..tostring(slot))
 b.scripts.OnClick(b)
end
-- More results than the viewport to ensure sorting covers hidden rows, too.
local originalDB=gAtr_ScanDB
local large={}
for i=1,30 do
 local name=string.format('Deal %02d',i)
 large[name]=item(i*1500,1+i/10,3)
 metadata[name]={class='Armor',subclass=i<=20 and 'Cloth' or 'Leather',equipLoc=i%2==0 and 'INVTYPE_HEAD' or 'INVTYPE_CHEST',link='item:'..i}
end
large.Unclassified=item(1000)
gAtr_ScanDB=large
for _,fn in ipairs(hooks.Atr_Broadcast_DBupdated) do fn() end
Atr_DealsPanel.scripts.OnUpdate(Atr_DealsPanel,1)
check(Atr_DealsScroll.count==31 and #visibleDeals()==14,'database notifications refresh the full result set automatically')
check(category(nil).text=='All deals (31)','tree counts only matching opportunities')
selectCategory('Armor')
check(Atr_DealsScroll.count==30,'Armor filters all matching armor deals')
selectCategory('Armor','Cloth')
check(Atr_DealsScroll.count==20,'Cloth filters the selected armor family')
selectCategory('Armor','Cloth','Head')
check(Atr_DealsScroll.count==10,'Head filters equipment slots inside Cloth')
for _,r in ipairs(visibleDeals()) do check(r.data.equipLoc=='INVTYPE_HEAD' and r.data.subclass=='Cloth','every selected result matches class, family and slot') end
selectCategory(nil)
for _,key in ipairs({'name','buy','profit','market','when'}) do
 Atr_DealsScroll.offset=17
 _G['Atr_DealsSort_'..key].scripts.OnClick()
 check(Atr_DealsScroll.offset==0,'sorting '..key..' resets the result scroll')
 check(_G['Atr_DealsSort_'..key].arrow:IsShown(),'active sort arrow shown for '..key)
 local first=visibleDeals()[1].data[key]
 _G['Atr_DealsSort_'..key].scripts.OnClick()
 local reversed=visibleDeals()[1].data[key]
 check(first~=reversed,'header '..key..' reverses all results, including offscreen extremes')
end
selectCategory('Armor');selectCategory('Armor','Cloth');selectCategory('Armor','Cloth','Head')
Atr_DealsSearch:SetText('02')
check(Atr_DealsScroll.count==1 and visibleDeals()[1].data.name=='Deal 02','name search composes with nested categories')
Atr_DealsClearSearch.scripts.OnClick()
check(Atr_DealsScroll.count==10,'clear search preserves selected category')
large['Deal 02'].lastScan=now-20*3600
Atr_DealsPanel.scripts.OnUpdate(Atr_DealsPanel,60)
check(Atr_DealsScroll.count==9,'periodic refresh expires old prices without a Refresh button')
check(category('Armor','Cloth','Head')~=nil,'automatic refresh preserves expanded tree and selected slot')
local purchaseRequests=0
function PlaceAuctionBid() purchaseRequests=purchaseRequests+1 end
local selectedPane,searchText,searchRequests=nil,nil,0
function Atr_SelectPane(id) selectedPane=id;Atr_AuctionFrameTab_OnClick() end
function Atr_SetSearchText(value) searchText=value end
function Atr_Search_Onclick() searchRequests=searchRequests+1 end
local buyRow=visibleDeals()[1]
local expectedName=buyRow.data.name
buyRow.scripts.OnEnter(buyRow)
gAtr_ScanDB[expectedName].mr=gAtr_ScanDB[expectedName].mr+100
for _,fn in ipairs(hooks.Atr_Broadcast_DBupdated) do fn() end
Atr_DealsPanel.scripts.OnUpdate(Atr_DealsPanel,1)
check(Atr_DealsDetails.item.text==expectedName and Atr_DealsDetails.values[1].text==tostring(gAtr_ScanDB[expectedName].mr),'inspected deal details refresh automatically with saved prices')
ATR_FS_NULL=0;gAtr_FullScanState=1
buyRow.scripts.OnClick(buyRow,'RightButton')
check(searchRequests==0 and Atr_DealsPanel:IsShown(),'right-click waits while a full scan is active')
gAtr_FullScanState=0
buyRow.scripts.OnClick(buyRow,'RightButton')
check(selectedPane==3 and searchText=='"'..expectedName..'"' and searchRequests==1,'right-click selects the real Buy pane and starts an exact-item search')
check(not Atr_DealsPanel:IsShown() and purchaseRequests==0,'handoff closes Deals without making a purchase')
check(gAtr_ScanDB['Deal 04'].mr==6000,'navigation and sorting never change saved prices')
gAtr_ScanDB=originalDB
print('PASS: '..checks..' Deals math, filters, history, read-only, tab order, log sorting, skins and overlay lifecycle checks')
