local clock,money,page,queries,bids,ack,eventHandler,errors,subtractions,totalRows
local hooks={}
local hardware=false
function hooksecurefunc(name,callback)
 local original=_G[name]
 _G[name]=function(...)local result={original(...)};callback(...);return unpack(result)end
end
local function widget()
 return {shown=true,value=1,text='',Show=function(s)s.shown=true end,Hide=function(s)s.shown=false end,
 IsShown=function(s)return s.shown end,SetText=function(s,t)s.text=t end,SetNumber=function(s,v)s.value=v end,
 GetNumber=function(s)return s.value end,Enable=function(s)s.enabled=true end,Disable=function(s)s.enabled=false end,
 SetFocus=function()end,HighlightText=function()end}
end
for _,name in ipairs({'Atr_Buy_Confirm_ItemPriceText','Atr_Buy_Confirm_ItemPrice','Atr_Buy_Confirm_Item_Total','Atr_Buy_Confirm_Max_Text',
 'Atr_Buy_Confirm_ItemName','Atr_Buy_Confirm_Numstacks','Atr_Buy_Part1','Atr_Buy_Part2','Atr_Buy_NumAvail_Text','Atr_Buy_Continue_Text',
 'Atr_Buy_Confirm_OKBut','Atr_Buy_Confirm_CancelBut','Atr_Buy_Confirm_Frame','Atr_Buy_Confirm_Text2','Atr_Buy_Confirm_TotalPrice','Atr_Error_Text','Atr_Error_Frame'})do _G[name]=widget()end
function CreateFrame()return {RegisterEvent=function()end,SetScript=function(_,_,fn)eventHandler=fn end}end
function GetTime()return clock end;time=GetTime
function GetMoney()return money end
function UnitName()return 'Me'end
function ZT(s)return s end
function MoneyFrame_Update()end
function CanSendAuctionQuery()return true end
function QueryAuctionItems(...)queries[#queries+1]={...}end
function GetNumAuctionItems()return #page,totalRows or #page end
function GetAuctionItemInfo(_,i)
 local r=page[i];if not r then return end
 return r.name or 'Linen Cloth',nil,r.count or 10,1,true,1,0,0,r.price or 100,r.bid or 0,r.highBidder,r.unknownOwner and '' or r.owner or 'Alice',0
end
function GetAuctionItemLink(_,i)return page[i]and not page[i].unknownLink and (page[i].link or 'item:2589:0')end
function PlaceAuctionBid(_,i,price)assert(hardware,'Protected buy attempted outside user input');bids[#bids+1]={index=i,price=price};ack=i end
function AuctionatorSubtractFromScan(_,_,_,count)subtractions=subtractions+count end
function Atr_Error_Display(s)if s then errors[#errors+1]=s end end
function Atr_IsSelectedTab_Current()return true end
local pane
function Atr_GetCurrentPane()return pane end
function Atr_Onclick_Back()end
function Atr_NewQuery()return {IsLastPage=function()return true end,CheckForDuplicatePage=function()return false end}end
AuctionatorRemastered={Models={},Legacy={}}
dofile('AuctionatorRemastered/Remastered/Models/ItemIdentity.lua')
local zc={md=function()end,StringSame=function(a,b)return a==b end,round=function(v)return math.floor(v+.5)end,UTF8_Truncate=function(v)return v end}
gAtrZC=zc
assert(loadfile('AuctionatorRemastered/Legacy/AuctionatorBuy.lua'))('AuctionatorRemastered',{zc=zc})
dofile('AuctionatorRemastered/Remastered/Integration/BuyBatch.lua')
ERR_AUCTION_BID_PLACED='Bid accepted'
local function reset(rows,maximum)
 Atr_ClearBuyState();clock=100;money=10000;page=rows;queries={};bids={};errors={};subtractions=0;ack=nil;totalRows=nil
 pane={currIndex=1,activeScan={searchText='Linen Cloth',itemName='Linen Cloth',itemLink='item:2589:0',
 sortedData={{buyoutPrice=100,stackSize=10,itemPrice=10,count=maximum or #rows,minpage=0,sellerName='Alice'}}}}
end
local function click()hardware=true;Atr_Buy_Confirm_OK();hardware=false end
local function settle()clock=clock+0.7;Atr_Buy_Idle()end
local function open(target)
 Atr_Buy1_Onclick();Atr_Buy_Confirm_Numstacks:SetNumber(target)
 Atr_Buy_Idle();assert(#queries==1 and #bids==0)
 Atr_Buy_OnAuctionUpdate();settle();assert(Atr_Buy_Confirm_OKBut.enabled)
 click()
end
local function refresh()
 Atr_Buy_Idle();Atr_Buy_Idle();Atr_Buy_OnAuctionUpdate();settle()
end
local function confirmed(listFirst)
 local index=ack;assert(index);ack=nil
 if listFirst then table.remove(page,index);Atr_Buy_OnAuctionUpdate()end
 money=money-100;eventHandler(nil,'CHAT_MSG_SYSTEM',ERR_AUCTION_BID_PLACED)
 if not listFirst then table.remove(page,index);Atr_Buy_OnAuctionUpdate()end
 if AuctionatorRemastered.BuyBatch.Active()then refresh()end
end
reset({{},{},{},{},{}});open(5)
assert(#bids==1 and subtractions==0,'Never count attempted buys as completed')
for i=1,5 do
 assert(#bids==i,'Exactly one request in flight')
 confirmed(i%2==0)
 assert(#bids==i,'Server events must not buy the next stack')
 if i<5 then assert(Atr_Buy_Confirm_OKBut.text=='Buy next');click()end
end
assert(#queries==5 and #bids==5 and subtractions==5 and not AuctionatorRemastered.BuyBatch.Active())
assert(Atr_Buy_Continue_Text.text=='5 of 5 bought so far')
-- Seller, item ID/variant, quantity, exact price and own auctions are constrained.
reset({{owner='Bob'},{owner='Me'},{count=20},{price=101},{link='item:2589:-1'},{name='Other cloth'},{},{}} ,8)
open(2);confirmed(false);click();confirmed(true)
assert(#bids==2 and #queries==2 and #page==6)
for _,row in ipairs(page)do assert(row.owner or row.count or row.price or row.link or row.name)end
-- Native updates may change matching counts without invalidating bought indices.
-- No next buy is enabled until an explicit query response has replaced that list.
reset({{},{},{}});open(3)
eventHandler(nil,'CHAT_MSG_SYSTEM',ERR_AUCTION_BID_PLACED)
page[1].owner='Me' -- unrelated count change; purchased row is still present
Atr_Buy_OnAuctionUpdate();click()
assert(#bids==1 and subtractions==1 and not Atr_Buy_Confirm_OKBut.enabled)
page={{},{}};ack=nil;refresh();assert(#queries==2 and #bids==1)
click();confirmed(false);click();confirmed(false)
assert(#bids==3 and subtractions==3 and #queries==3)
-- Explicit missing-item failures refresh the same page and preserve target/price.
reset({{},{},{}});open(3);confirmed(false);click()
eventHandler(nil,'UI_ERROR_MESSAGE','The item was not found.')
assert(AuctionatorRemastered.BuyBatch.Active()and subtractions==1 and #errors==0)
refresh();assert(#bids==2 and Atr_Buy_Confirm_OKBut.text=='Buy next')
click();confirmed(false);click();confirmed(false)
assert(#bids==4 and subtractions==3 and not AuctionatorRemastered.BuyBatch.Active())
-- Replay unchanged snapshots after success and failure: each index only once.
reset({{},{},{}},5);totalRows=231;open(5)
assert(bids[1].index==3)
eventHandler(nil,'CHAT_MSG_SYSTEM',ERR_AUCTION_BID_PLACED);refresh();click()
assert(bids[2].index==2)
eventHandler(nil,'CHAT_MSG_SYSTEM',ERR_AUCTION_BID_PLACED);refresh();click()
assert(bids[3].index==1)
eventHandler(nil,'UI_ERROR_MESSAGE','The item was not found.');refresh()
assert(not Atr_Buy_Confirm_OKBut.enabled and AuctionatorRemastered.BuyBatch.Active())
for i=1,3 do
 click();clock=clock+1.1;refresh()
 assert(#bids==3 and subtractions==2 and #errors==0,'Unchanged stale rows must not become buyable again')
end
-- As in the trace, total count can change even with identical matching rows.
totalRows=228;clock=clock+1.1;refresh();assert(Atr_Buy_Confirm_OKBut.enabled)
assert(#bids==3);click();assert(#bids==4)
-- Unrelated row changes must not release already attempted matching rows.
reset({{name='Other item',owner='Bob'}, {},{}},4);open(4)
eventHandler(nil,'CHAT_MSG_SYSTEM',ERR_AUCTION_BID_PLACED)
page[1].owner='Carol';page[1].bid=20;refresh();click()
assert(bids[2].index==2,'Unrelated metadata must not reset used index 3')
eventHandler(nil,'UI_ERROR_MESSAGE','The item was not found.')
page[1].bid=30;page[2].highBidder=false;page[3].highBidder=false
refresh();assert(not Atr_Buy_Confirm_OKBut.enabled and #bids==2)
-- Cosmetic link differences preserve canonical identity and eligibility.
page[3].link='|Hitem:2589:0:0:0:0:0:0:0:80|h[Linen Cloth]|h'
clock=clock+1.1;refresh();assert(not Atr_Buy_Confirm_OKBut.enabled)
-- A matching seller/eligibility change does count as a changed candidate set.
page[2].owner='Different seller';clock=clock+1.1;refresh()
assert(Atr_Buy_Confirm_OKBut.enabled);click();assert(bids[3].index==3)
-- One stale candidate waits, then pauses polling without dropping the target.
reset({{}},2);open(2)
eventHandler(nil,'UI_ERROR_MESSAGE','The item was not found.');refresh();click()
assert(#bids==1 and not Atr_Buy_Confirm_OKBut.enabled and #errors==0)
clock=clock+21;Atr_Buy_Idle()
assert(Atr_Buy_Confirm_OKBut.enabled and Atr_Buy_Confirm_OKBut.text=='Refresh')
local queryCount=#queries;Atr_Buy_Idle();assert(#queries==queryCount,'Paused polling is bounded')
click();assert(#bids==1);refresh()
assert(not Atr_Buy_Confirm_OKBut.enabled and #bids==1)
-- A genuinely changed row becomes usable, still requiring a hardware click.
page={{},{}};clock=clock+1.1;refresh();assert(Atr_Buy_Confirm_OKBut.enabled)
click();assert(#bids==2)
-- Partial responses and bursts must not expose an active Buy button early.
reset({{unknownOwner=true,unknownLink=true},{unknownOwner=true}},2)
Atr_Buy1_Onclick();Atr_Buy_Confirm_Numstacks:SetNumber(2);Atr_Buy_Idle()
Atr_Buy_OnAuctionUpdate();settle()
assert(AuctionatorRemastered.BuyBatch.Active()and not Atr_Buy_Confirm_OKBut.enabled and #errors==0)
page[1].unknownOwner=nil;page[1].unknownLink=nil;page[2].unknownOwner=nil
Atr_Buy_Idle();assert(Atr_Buy_Confirm_OKBut.enabled,'Poll metadata even without another list event')
-- A late update disables a previously ready button until the list settles.
Atr_Buy_OnAuctionUpdate();click();assert(#bids==0 and not Atr_Buy_Confirm_OKBut.enabled)
clock=clock+0.2;Atr_Buy_OnAuctionUpdate();clock=clock+0.1;Atr_Buy_Idle()
assert(not Atr_Buy_Confirm_OKBut.enabled)
settle();click();assert(#bids==1);confirmed(false)
-- Duplicate rejection/unrelated errors after a request was resolved must not close it.
eventHandler(nil,'UI_ERROR_MESSAGE','The item was not found.')
assert(AuctionatorRemastered.BuyBatch.Active());click();confirmed(false)
assert(subtractions==2)
-- Error/cancel/timeout stops rather than blindly retrying uncertain purchases.
reset({{},{} });open(2);eventHandler(nil,'UI_ERROR_MESSAGE','Auction unavailable');Atr_Buy_Idle()
assert(#bids==1 and subtractions==0 and not AuctionatorRemastered.BuyBatch.Active())
reset({{},{} });open(2);Atr_Buy_Cancel();confirmed(false);Atr_Buy_Idle();assert(#bids==1 and subtractions==0)
reset({{},{} });open(2);clock=clock+13;Atr_Buy_Idle();assert(#bids==1 and subtractions==0 and #errors==1)
reset({{},{} });open(2);Atr_Buy_Confirm_Frame:Hide();confirmed(false);assert(#bids==1 and not AuctionatorRemastered.BuyBatch.Active())
-- A different query or bid invalidates the shared list/ack ownership.
reset({{},{} });open(2);QueryAuctionItems('Other item');assert(not AuctionatorRemastered.BuyBatch.Active())
reset({{},{} });open(2);hardware=true;PlaceAuctionBid('list',1,100);hardware=false;assert(not AuctionatorRemastered.BuyBatch.Active())
reset({{},{} });open(2);money=0;confirmed(false);click();assert(#bids==1 and not AuctionatorRemastered.BuyBatch.Active())
-- Missing matching stock terminates after one same-page refresh, not an endless rescan.
reset({{},{} },5);open(5);confirmed(false);click();confirmed(false);click()
Atr_Buy_Idle();Atr_Buy_OnAuctionUpdate();settle();assert(#queries==3)
assert(not AuctionatorRemastered.BuyBatch.Active()and #bids==2 and #errors==1)
reset({{},{} });open(2);eventHandler(nil,'ADDON_ACTION_BLOCKED','AuctionatorRemastered','PlaceAuctionBid()');assert(not AuctionatorRemastered.BuyBatch.Active() and subtractions==0)
-- Diagnostic output preserves raw fields and both server list counts.
reset({{},{} });open(2);eventHandler(nil,'UI_ERROR_MESSAGE','The item was not found.')
local messages={};local nativePrint=print
print=function(message)messages[#messages+1]=message end
AuctionatorRemastered.BuyBatch.Debug();print=nativePrint
local joined=table.concat(messages,'\n')
assert(joined:find('indices=',1,true)and joined:find('seller=Alice',1,true)and joined:find('rejected after',1,true))
print('PASS: five stacks / five hardware clicks / fresh page per purchase; serial server acknowledgements in either event order; seller/identity/price/quantity locks; stale native indices; user-driven missing-auction recovery; errors/cancel/timeouts; foreign queries/bids; money and exhausted-stock bounds')
