dofile("AuctionatorRemastered/Remastered/Core/Bootstrap.lua")
dofile("AuctionatorRemastered/Remastered/Integration/LegacyBridge.lua")
-- Run from the repository root: lua5.1 tools/tests/test_purchase_visit.lua
local frames,hooks={},{}
local function widget(name)
    local f={scripts={},events={},shown=true,height=180,labels={}}
    function f:SetScript(event,fn) self.scripts[event]=fn end
    function f:HookScript(event,fn)
        local original=self.scripts[event]
        self.scripts[event]=function(...)if original then original(...)end;fn(...)end
    end
    function f:RegisterEvent(event) self.events[event]=true end
    function f:IsShown() return self.shown end
    function f:Hide() self.shown=false end
    function f:Show() self.shown=true;if self.scripts.OnShow then self.scripts.OnShow(self) end end
    function f:SetText(value) self.text=value end
    function f:SetHeight(value) self.height=value end
    function f:SetPoint(...) self.point={...} end
    function f:CreateFontString() local label=widget();self.labels[#self.labels+1]=label;return label end
    setmetatable(f,{__index=function(_,key) if key:find('^Set') or key=='ClearAllPoints' then return function() end end end})
    frames[#frames+1]=f;if name then _G[name]=f end;return f
end
function CreateFrame() return widget() end
function hooksecurefunc(name,callback) hooks[name]=callback end
local now=1000
function time() return now end
function date() return 'date' end
function GetRealmName() return 'Realm' end
function UnitFactionGroup() return 'Alliance' end
function UnitName() return 'Main' end
local pane={activeScan={itemName='Linen Cloth',whenScanned=1}}
function Atr_GetCurrentPane() return pane end
local buyTab,summary=true,false
function Atr_IsTabSelected(index) return index==3 and buyTab end
function Atr_ShowingSearchSummary() return summary end
local auction
local stackSizes={['Linen Cloth']=20,Herb=1}
function GetItemInfo(name) return name,nil,nil,nil,nil,nil,nil,stackSizes[name] end
function GetAuctionItemInfo()
    return auction.name,nil,auction.count,nil,nil,nil,nil,nil,auction.price,nil,nil,auction.seller
end
ERR_AUCTION_BID_PLACED='Bid accepted'
gAtrZC={priceToMoneyString=function(value) return value==0 and '' or tostring(value) end}
AuctionFrame=widget('AuctionFrame');Atr_Main_Panel=widget('Atr_Main_Panel');Atr_Recommend_Text=widget('Atr_Recommend_Text')
Atr_Buy_Confirm_Frame=widget('Atr_Buy_Confirm_Frame');Atr_Buy_Confirm_Frame:Hide()
Atr_Buy_Part1=widget();Atr_Buy_Part2=widget()
assert(loadfile('AuctionatorRemastered/Remastered/Data/Purchases.lua'))()
local events
for _,frame in ipairs(frames) do if frame.events.CHAT_MSG_SYSTEM then events=frame end end
local checks=0
local function check(ok,message) checks=checks+1;assert(ok,message) end
local function event(name,message) events.scripts.OnEvent(events,name,message) end
local function request(name,count,price,seller,amount)
    auction={name=name,count=count,price=price,seller=seller}
    hooks.PlaceAuctionBid('list',1,amount or price)
end
local function ack() event('CHAT_MSG_SYSTEM',ERR_AUCTION_BID_PLACED) end
local function total(name,quantity,spent,message)
    local actualQuantity,actualSpent=Atr_GetVisitPurchases(name)
    check(actualQuantity==quantity and actualSpent==spent,message)
end
event('AUCTION_HOUSE_SHOW');Atr_Buy_Confirm_Frame:Show()
request('Linen Cloth',20,999,'Blocked')
event('ADDON_ACTION_BLOCKED','AuctionatorRemastered');ack()
total('Linen Cloth',0,0,'blocked request must not remain pending for a later acknowledgement')
check(Atr_Buy_Confirm_Frame.height==230,'popup reserves extra space')
check(Atr_Buy_Part1.point[5]==90 and Atr_Buy_Part2.point[5]==90,'original buy content keeps its original height')
check(Atr_Buy_Confirm_Frame.labels[1].text:find('0 items',1,true),'popup starts with zero bought')
check(Atr_Buy_Confirm_Frame.labels[2].text=='Spent on this item: 0c','zero spend remains readable')
request('Linen Cloth',7,700,'Seller A')
total('Linen Cloth',0,0,'requests alone do not increment counts')
ack();total('Linen Cloth',7,700,'first seven single items counted')
check(Atr_Buy_Confirm_Frame.labels[1].text:find('7 items',1,true),'popup refreshes after acknowledgement')
Atr_Buy_Confirm_Frame:Hide();Atr_Buy_Confirm_Frame:Show();hooks.Atr_Buy1_Onclick()
request('Linen Cloth',20,1800,'Seller B');ack()
total('Linen Cloth',27,2500,'new row and seller add to previous purchases')
check(Atr_Buy_Confirm_Frame.labels[1].text:find('27 items',1,true),'reopened popup retains visit total')
check(Atr_Buy_Confirm_Frame.labels[1].text:find('1 stack + 7 (27 items)',1,true),'stack equivalents use item max size rather than auctions bought')
check(Atr_Main_Panel.labels[1].text:find('27 items',1,true),'main Buy shows same total')
request('Linen Cloth',20,2000,'Seller C');request('Linen Cloth',20,2100,'Seller D');ack();ack()
total('Linen Cloth',67,6600,'multiple queued stacks counted as individual items')
check(Atr_Buy_Confirm_Frame.labels[1].text:find('3 stacks + 7 (67 items)',1,true),'compact full stacks plus remainder')
pane.activeScan.itemName='Herb';Atr_Buy_Confirm_Frame:Hide();Atr_Buy_Confirm_Frame:Show()
request('Herb',2,300,'Other seller');ack();total('Herb',2,300,'another item is isolated')
check(not Atr_Buy_Confirm_Frame.labels[1].text:find('stack',1,true),'non-stackable items keep item count')
pane.activeScan.itemName='Linen Cloth';Atr_Buy_Confirm_Frame:Hide();Atr_Buy_Confirm_Frame:Show()
check(Atr_Buy_Confirm_Frame.labels[1].text:find('67 items',1,true),'returning to original item restores total')
request('Linen Cloth',20,2000,'Bid only',100);ack()
total('Linen Cloth',67,6600,'ordinary bids excluded')
request('Linen Cloth',20,2000,'Failed');event('UI_ERROR_MESSAGE','Not enough money');ack()
total('Linen Cloth',67,6600,'failed requests excluded')
request('Linen Cloth',20,2000,'Expired');now=now+31;ack()
total('Linen Cloth',67,6600,'expired requests excluded')
event('CHAT_MSG_SYSTEM','Unrelated message');ack()
total('Linen Cloth',67,6600,'unrelated/duplicate messages excluded')
request('Linen Cloth',20,2000,'Late acknowledgement')
event('AUCTION_HOUSE_CLOSED');event('AUCTION_HOUSE_SHOW')
total('Linen Cloth',0,0,'new AH visit resets counter')
ack();total('Linen Cloth',0,0,'previous visit pending acknowledgement cannot leak into new total')
request('Linen Cloth',4,400,'New visit');ack();total('Linen Cloth',4,400,'new visit counts fresh purchases')
event('AUCTION_HOUSE_SHOW');total('Linen Cloth',4,400,'duplicate show event does not reset active visit')
buyTab=false;hooks.Atr_UpdateUI();check(not Atr_Main_Panel.labels[1]:IsShown(),'main label hidden outside Buy')
buyTab=true;summary=true;hooks.Atr_UpdateUI();check(not Atr_Main_Panel.labels[1]:IsShown(),'summary hides item-specific counter')
summary=false;hooks.Atr_UpdateUI();check(Atr_Main_Panel.labels[1]:IsShown(),'item view restores counter')
event('AUCTION_HOUSE_CLOSED');check(not Atr_Buy_Confirm_Frame.labels[1]:IsShown(),'closed visit hides popup counter')
check(#AUCTIONATOR_PURCHASES.Realm_Alliance.records==7,'persistent purchase ledger retains confirmed records across visits')
check(PlaceAuctionBid==nil and QueryAuctionItems==nil,'observer sends no extra bids or queries')
event('AUCTION_HOUSE_SHOW');pane.activeScan.itemName='Linen Cloth'
Atr_Buy_Confirm_Frame:Hide();Atr_Buy_Confirm_Frame:Show()
request('Linen Cloth',20,2000,'Seller');ack()
check(Atr_Buy_Confirm_Frame.labels[1].text:find('1 stack (20 items)',1,true),'full stack without redundant zero remainder')
request('Linen Cloth',20,2000,'Seller');ack()
request('Linen Cloth',20,2000,'Seller');ack()
request('Linen Cloth',15,1500,'Seller');ack()
check(Atr_Buy_Confirm_Frame.labels[1].text:find('3 stacks + 15 (75 items)',1,true),'75 cloth displayed as three full stacks plus fifteen')
stackSizes['Linen Cloth']=nil;hooks.Atr_UpdateUI()
check(Atr_Buy_Confirm_Frame.labels[1].text:find('75 items',1,true) and not Atr_Buy_Confirm_Frame.labels[1].text:find('stack',1,true),'unknown stack size falls back to accurate item total')
-- Real popup layout integration, including the original quantity update.
local function read(path) local f=assert(io.open(path));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
dofile('AuctionatorRemastered/Remastered/UI/Theme.lua')

-- Add real visual/value operations to the existing lightweight frame fixture.
local function enhance(f)
 function f:SetSize(x,y) self.width=x;self.height=y end
 function f:SetWidth(x) self.width=x end
 function f:SetBackdrop(value) self.backdrop=value end
 function f:SetBackdropColor(...) self.color={...} end
 function f:GetBackdropColor() return unpack(self.color or {.025,.025,.025,1}) end
 function f:SetVertexColor(...) self.vertex={...} end
 function f:SetTextColor(...) self.textColor={...} end
 function f:SetTexture(value) self.texture=value end
 function f:SetAllPoints(other) self.allPoints=other end
 function f:CreateTexture() local texture=widget();enhance(texture);return texture end
 function f:GetScript(key) return self.scripts[key] end
 function f:GetNumber() return self.number or 1 end
 function f:SetNumber(n) self.number=n end
end
for _,f in ipairs(frames) do enhance(f) end
for _,name in ipairs({'Atr_Buy_Confirm_ItemName','Atr_Buy_Confirm_ItemPriceText','Atr_Buy_Confirm_ItemPrice','Atr_Buy_Confirm_Text1','Atr_Buy_Confirm_Numstacks','Atr_Buy_Confirm_Max_Text','Atr_Buy_Confirm_Text2','Atr_Buy_Confirm_TotalPrice','Atr_Buy_Confirm_Item_Total','Atr_Buy_NumAvail_Text','Atr_Buy_Continue_Text','Atr_Buy_Confirm_OKBut','Atr_Buy_Confirm_CancelBut'}) do enhance(widget(name)) end
local actions=0
local buyClick=function() actions=actions+1 end
local enter=function() actions=actions+1 end
Atr_Buy_Confirm_OKBut:SetScript('OnClick',buyClick)
Atr_Buy_Confirm_Numstacks:SetScript('OnEnterPressed',enter)
Atr_Buy_Confirm_OKBut:SetText('Scanning...');Atr_Buy_Confirm_OKBut.enabled=false
local moneyUpdates={}
function MoneyFrame_Update(name,value) moneyUpdates[name]=value end
local buy=read('AuctionatorRemastered/Legacy/AuctionatorBuy.lua')
assert(loadstring('local FocusTime=0;\n'..assert(buy:match('(function Atr_Buy_Confirm_Update %b().-\nend)'))))()
function ZT(text) return text end
dofile('AuctionatorRemastered/Remastered/UI/AuctionLayout.lua')
dofile('AuctionatorRemastered/Remastered/UI/AuctionDialogs.lua')
dofile('AuctionatorRemastered/Remastered/UI/AuctionLayout.lua')
dofile('AuctionatorRemastered/Remastered/UI/AuctionDialogs.lua')
dofile('AuctionatorRemastered/Remastered/Integration/ElvUI.lua')
dofile('AuctionatorRemastered/Remastered/Integration/AuctionUI.lua')
dofile('AuctionatorRemastered/Remastered/Integration/AuctionUI.lua')
gAtr_Buy_StackSize=20;gAtr_Buy_BuyoutPrice=1950000;gAtr_Buy_MaxCanBuy=3
pane.currIndex=1;pane.activeScan.sortedData={{stackSize=20,buyoutPrice=1950000}}
ElvUI=nil;Atr_Buy_Confirm_Frame:Hide();Atr_Buy_Confirm_Frame:Show()
check(Atr_Buy_Confirm_Frame.width==440 and Atr_Buy_Confirm_Frame.height==290,'compact grouped Buy layout applied when popup opens')
check(Atr_Buy_Confirm_Frame.color[4]==1 and Atr_Buy_Confirm_Frame.atrSolidBackground.vertex[4]==1,'Buy uses shared opaque background and solid fill')
check(Atr_Buy_Confirm_ItemName.width==400 and Atr_Buy_Confirm_ItemName.height==32,'long item names have a dedicated two-line header')
check(Atr_Buy_Confirm_Numstacks.point[4]==140 and Atr_Buy_Confirm_Numstacks.point[5]==-111,'quantity has a separate aligned row')
check(Atr_Buy_Confirm_TotalPrice.point[1]=='TOPLEFT' and Atr_Buy_Confirm_ItemPrice.point[1]=='TOPLEFT' and Atr_Buy_Confirm_TotalPrice.point[4]==140 and Atr_Buy_Confirm_ItemPrice.point[4]==140,'unit price and total share a compact value column beside their labels')
check(Atr_Buy_Confirm_Frame.atrVisitCount.point[5]==-202 and Atr_Buy_Confirm_Frame.atrVisitSpent.point[5]==-220,'confirmed visit totals have their own strip above footer')
check(Atr_Buy_Confirm_OKBut:GetScript('OnClick')==buyClick and Atr_Buy_Confirm_Numstacks:GetScript('OnEnterPressed')==enter and not Atr_Buy_Confirm_OKBut.enabled,'layout preserves buy/Enter handlers and disabled state')
Atr_Buy_Confirm_Numstacks:SetNumber(99);Atr_Buy_Confirm_Update();hooks.Atr_Buy_Confirm_Update()
check(Atr_Buy_Confirm_Numstacks:GetNumber()==3 and Atr_Buy_Confirm_Item_Total.text=='60 items in total' and moneyUpdates.Atr_Buy_Confirm_TotalPrice==5850000,'original maximum validation and quantity/total calculations preserved')
check(Atr_Buy_Confirm_Text1.text=='Stacks' and Atr_Buy_Confirm_Text2.text=='Total cost','legacy sentence is replaced by clear row labels after quantity changes')
Atr_Buy_Part1:Hide();Atr_Buy_Part2:Show();Atr_StyleBuyConfirmDialog()
check(not Atr_Buy_Part1:IsShown() and Atr_Buy_Part2:IsShown() and Atr_Buy_NumAvail_Text.point[5]==-116 and Atr_Buy_Continue_Text.point[5]==-150,'batch progress remains visible in its separate phase')
local skinCalls=0
ElvUI={{media={backdropfadecolor={.1,.12,.14,.6}},GetModule=function() return {HandleButton=function() skinCalls=skinCalls+1 end,HandleEditBox=function() skinCalls=skinCalls+1 end} end}}
Atr_StyleBuyConfirmDialog()
check(skinCalls==3 and Atr_Buy_Confirm_Frame.color[1]==.1 and Atr_Buy_Confirm_Frame.color[4]==1,'ElvUI native button/input styles and opaque theme colors applied')
gAtr_Buy_StackSize=1;pane.activeScan.sortedData[1].stackSize=1;Atr_Buy_Confirm_ItemPrice:Hide();Atr_StyleBuyConfirmDialog()
check(Atr_Buy_Confirm_Text1.text=='Quantity' and Atr_Buy_Confirm_ItemPrice:IsShown() and moneyUpdates.Atr_Buy_Confirm_ItemPrice==1950000,'single items use Quantity and show their unit price')
check(Atr_Buy_Confirm_Max_Text.point[1]=='LEFT' and Atr_Buy_Confirm_Max_Text.point[2]==Atr_Buy_Confirm_Numstacks and Atr_Buy_Confirm_Max_Text.point[3]=='RIGHT' and Atr_Buy_Confirm_Max_Text.point[5]==0,'maximum hint centers directly on the quantity input')
check(Atr_Buy_Confirm_Max_Text.textColor[1]==.8 and Atr_Buy_Confirm_Item_Total.textColor[1]==.8 and Atr_Buy_Confirm_Item_Total.point[4]==140,'readable hints and total quantity align with the value column')
-- Buy engine state is private: presentation must read the selected scan row.
gAtr_Buy_StackSize=nil;gAtr_Buy_BuyoutPrice=nil
pane.activeScan.sortedData[1]={stackSize=9,buyoutPrice=160200}
Atr_StyleBuyConfirmDialog()
check(Atr_Buy_Confirm_Text1.text=='Stacks','stack label uses selected row metadata, independent of private Buy locals')
pane.activeScan.sortedData[1]={stackSize=1,buyoutPrice=17800}
Atr_StyleBuyConfirmDialog()
check(moneyUpdates.Atr_Buy_Confirm_ItemPrice==17800,'single-item price comes from the selected row without exposing Buy state')
check(actions==0,'styling and quantity changes never execute purchase or Enter actions')
ElvUI=nil
print('PASS: '..checks..' visit-purchase and popup/UI checks')
