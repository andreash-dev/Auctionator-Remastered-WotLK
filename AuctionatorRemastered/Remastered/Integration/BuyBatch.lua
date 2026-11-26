-- A bounded, acknowledged purchase queue behind the inherited Buy dialog.
-- One fixed batch quantity/identity/price/stack and seller when known.
-- Every protected buy is initiated by a fresh user click, never an event/timer.
local R=AuctionatorRemastered
local batch
local originalOpen,originalClear,originalCancel=Atr_Buy1_Onclick,Atr_ClearBuyState,Atr_Buy_Cancel
local originalUpdate,originalIdle=Atr_Buy_OnAuctionUpdate,Atr_Buy_Idle
local sending,querying=false,false
local function now()return GetTime()end
local history={}
local function trace(message)
 history[#history+1]=string.format('%.2f %s %s',now(),batch and batch.state or 'closed',message)
 if #history>60 then table.remove(history,1)end
end
local function rowDetails(index)
 local name,_,count,_,_,_,_,_,price,bid,highBidder,owner,sold=GetAuctionItemInfo('list',index)
 local left=type(GetAuctionItemTimeLeft)=='function' and GetAuctionItemTimeLeft('list',index) or nil
 return string.format('index=%s item=%s stack=%s price=%s bid=%s high=%s seller=%s sold=%s time=%s',
  tostring(index),tostring(name),tostring(count),tostring(price),tostring(bid),
  tostring(highBidder),tostring(owner),tostring(sold),tostring(left))
end
local function progress()
 if not batch then return end
 Atr_Buy_Continue_Text:SetText(string.format(ZT('%d of %d bought so far'),batch.bought,batch.target or 0))
end
local function stop(message)
 trace('stop: '..tostring(message or 'complete'))
 batch=nil
 originalClear()
 originalCancel(message)
end
local function queue(page)
 if not batch then return end
 batch.page=page;batch.state='throttle';batch.since=now();batch.updated=nil
 trace('queue page '..page)
 Atr_Buy_Confirm_OKBut:Disable();Atr_Buy_Confirm_OKBut:SetText(ZT('Scanning...'))
end
R.BuyBatch={Active=function()return batch~=nil end,QueueQuery=queue,
 Debug=function()for _,line in ipairs(history)do print('Buy: '..line)end end}

local function readPage()
 local rows={};local unresolved=false;local count,total=GetNumAuctionItems('list')
 local snapshot={tostring(count),tostring(total)}
 for i=1,(count or 0)do
  local name,_,quantity,_,_,_,_,_,price,bid,highBidder,owner,sold=GetAuctionItemInfo('list',i)
  local link=GetAuctionItemLink('list',i)
  local identity=R.Models.ItemIdentity.Parse(link)
  if not name or (name==batch.name and quantity==batch.stack and price==batch.price
   and (not owner or owner=='' or not identity))then unresolved=true end
  if name==batch.name and quantity==batch.stack and price==batch.price and owner and owner~=''
   and owner~=UnitName('player') and (not batch.seller or owner==batch.seller)
   and identity and identity==batch.identity and not highBidder and (not bid or bid<price)
   and (not sold or sold==0)then
   rows[#rows+1]={index=i,owner=owner,link=link}
   -- Only eligible candidates define this purchase snapshot. Metadata/bids on
   -- unrelated auctions, nil/false flags and cosmetic link variants must not
   -- make previously attempted candidates look new.
   for _,value in ipairs({tostring(i),identity,owner,tostring(quantity),tostring(price)})do
    snapshot[#snapshot+1]=value
   end
  end
 end
 return rows,total or 0,unresolved,table.concat(snapshot,'\031')
end
local function untriedRows(matches,snapshot)
 local page=batch.snapshots[batch.page]
 if not page or page.signature~=snapshot then
  page={signature=snapshot,used={}};batch.snapshots[batch.page]=page
  batch.waitSince=nil
  trace('snapshot changed')
 end
 local result={}
 for _,row in ipairs(matches)do if not page.used[row.index]then result[#result+1]=row end end
 return result,page
end
local function waitForSnapshot()
 batch.waitSince=batch.waitSince or now()
 batch.state='snapshotwait';batch.since=now()
 Atr_Buy_Confirm_OKBut:Disable();Atr_Buy_Confirm_OKBut:SetText('Waiting for update...')
 trace('unchanged snapshot: all matching rows already attempted')
end
local function exhausted()
 local count,total=GetNumAuctionItems('list')
 -- Purchases shift later rows/pages left. Refresh this page once before moving
 -- forward, rather than skipping the newly shifted listings after every buy.
 if batch.target and not batch.refreshed then batch.refreshed=true;queue(batch.page);return end
 if (batch.page+1)*50<(total or 0)then batch.refreshed=false;queue(batch.page+1)
 elseif batch.pass==1 and batch.page>0 then batch.pass=2;batch.refreshed=true;queue(0)
 else
  local message=batch.target and string.format('Bought %d of %d stacks. No more matching auctions are available.',batch.bought,batch.target)or ZT('No matching auctions found.')
  stop(message)
 end
end
local function readyForClick()
 if not batch then return end
 if not Atr_Buy_Confirm_Frame:IsShown()then batch=nil;originalClear();return end
 batch.state='ready'
 trace('ready')
 Atr_Buy_Confirm_OKBut:Enable()
 Atr_Buy_Confirm_OKBut:SetText(batch.target and 'Buy next' or 'Buy')
end
-- Native list notifications can arrive in bursts, before owner/link metadata.
-- Wait for a quiet, complete response instead of interpreting its first event
-- as either ready-to-buy or exhausted stock. Idle also polls delayed metadata.
local function settleResponse()
 if not batch or batch.state~='query' or not batch.updated then return end
 if now()-batch.updated<0.25 or now()-batch.since<0.35 then return end
 local matches,_,unresolved,snapshot=readPage()
 if unresolved then return end
 if #matches==0 then
  if now()-batch.updated<0.6 then return end
  batch.refreshed=batch.queryWasRefresh or false
  exhausted()
 else
  local available=untriedRows(matches,snapshot)
  if #available==0 then waitForSnapshot();return end
  batch.waitSince=nil;batch.refreshed=false
  local indices={}
  for _,row in ipairs(matches)do indices[#indices+1]=row.index end
  local count,total=GetNumAuctionItems('list')
  trace('response matches '..#matches..' rows='..tostring(count)..' total='..tostring(total)..' indices='..table.concat(indices,','))
  readyForClick()
 end
end
local function sendNext()
 if not batch or not batch.target or batch.pending then return end
 if not Atr_Buy_Confirm_Frame:IsShown()then batch=nil;originalClear();return end
 if batch.bought>=batch.target then stop();return end
 if GetMoney()<batch.price then stop(ZT('You do not have enough gold\n\nto make any more purchases.'));return end
 local matches,_,unresolved,snapshot=readPage()
 if unresolved then queue(batch.page);return end
 if #matches==0 then exhausted();return end
 local available,page=untriedRows(matches,snapshot)
 if #available==0 then waitForSnapshot();return end
 -- Re-read the explicitly queried page at click time; never reuse an index
 -- from before an acknowledged purchase.
 local row=available[#available]
 page.used[row.index]=true
 trace('select untried index '..row.index)
 trace('buy index '..row.index..' matches '..#matches)
 trace(rowDetails(row.index))
 batch.pending={since=now(),index=row.index}
 batch.state='ack';batch.since=now()
 Atr_Buy_Confirm_OKBut:Disable();Atr_Buy_Confirm_OKBut:SetText('Buying...')
 sending=true
 local ok,err=pcall(PlaceAuctionBid,'list',row.index,batch.price)
 sending=false
 if not ok then stop(tostring(err))end
end
function Atr_Buy1_Onclick(...)
 if not Atr_IsSelectedTab_Current()then return end
 local pane=Atr_GetCurrentPane();local scan=pane and pane.activeScan
 local row=scan and scan.sortedData and scan.sortedData[pane.currIndex]
 local identity=scan and R.Models.ItemIdentity.Parse(scan.itemLink)
 if not row or not identity or not row.buyoutPrice or row.buyoutPrice<=0 or row.yours then return end
 if batch and batch.pending then return end
 originalClear()
 batch={name=scan.itemName,link=scan.itemLink,identity=identity,stack=row.stackSize,price=row.buyoutPrice,
  seller=not row.multipleSellers and row.sellerName or nil,max=row.count,bought=0,page=0,pass=1,queries=0,refreshed=false,snapshots={}}
 originalOpen(...)
end
function Atr_Buy_Confirm_OK()
 if batch and batch.state=='refresh'then batch.waitSince=nil;queue(batch.page);return end
 if not batch or batch.state~='ready' or batch.pending then return end
 if not batch.target then
  local target=Atr_Buy_Confirm_Numstacks:GetNumber()
  if type(target)~='number' or target%1~=0 or target<1 or target>batch.max then return end
  batch.target=target
  if target>1 then Atr_Buy_Part1:Hide();Atr_Buy_Part2:Show()end
 end
 progress();sendNext()
end
function Atr_Buy_OnAuctionUpdate(...)
 if not batch then return originalUpdate(...)end
 if batch.state=='query'then
  batch.updated=now()
  trace('list event')
 elseif batch.state=='ready'then
  -- A newly changing list invalidates an already enabled button too.
  batch.state='query';batch.updated=now();batch.since=now();batch.queryWasRefresh=false
  Atr_Buy_Confirm_OKBut:Disable();Atr_Buy_Confirm_OKBut:SetText(ZT('Scanning...'))
 end
 return true
end
function Atr_Buy_Idle(...)
 if not batch then return originalIdle(...)end
 if not Atr_Buy_Confirm_Frame:IsShown()then batch=nil;originalClear();return end
 if batch.state=='snapshotwait'then
  if now()-batch.waitSince>=20 then
   batch.state='refresh';Atr_Buy_Confirm_OKBut:Enable();Atr_Buy_Confirm_OKBut:SetText('Refresh')
   trace('snapshot wait paused; refresh requires click')
  elseif now()-batch.since>=1 then batch.refreshed=true;queue(batch.page)end
 elseif batch.state=='throttle'then
  if now()-batch.since>12 then stop(ZT('Auction House timed out'));return end
  if CanSendAuctionQuery()then
   batch.state='query';batch.since=now();batch.queries=batch.queries+1
   batch.queryWasRefresh=batch.refreshed;batch.updated=nil
   trace('send query page '..batch.page)
   querying=true
   local queryString=gAtrZC.UTF8_Truncate(batch.name,63)
   local ok,err=pcall(QueryAuctionItems,queryString,nil,nil,0,0,0,batch.page,false,-1)
   querying=false
   if not ok then stop(tostring(err))end
  end
 elseif batch.state=='query'then
  settleResponse()
  if batch and batch.state=='query' and now()-batch.since>12 then stop(ZT('Auction House timed out'))end
 elseif batch.pending then
  if now()-batch.pending.since>12 then stop('Purchase confirmation timed out. Check purchases before trying again.')end
 end
end
function Atr_ClearBuyState(...)
 batch=nil;return originalClear(...)
end
function Atr_Buy_Cancel(...)
 batch=nil;return originalCancel(...)
end
local events=CreateFrame('Frame')
for _,event in ipairs({'CHAT_MSG_SYSTEM','UI_ERROR_MESSAGE','AUCTION_HOUSE_CLOSED','ADDON_ACTION_BLOCKED','ADDON_ACTION_FORBIDDEN'})do events:RegisterEvent(event)end
events:SetScript('OnEvent',function(_,event,message,action)
 if not batch then return end
 if event=='ADDON_ACTION_BLOCKED' or event=='ADDON_ACTION_FORBIDDEN'then
  if (type(message)=='string' and message:find('AuctionatorRemastered',1,true)) or
   (type(action)=='string' and action:find('PlaceAuctionBid',1,true))then
   stop('Purchase blocked by the client. Check purchases before trying again.')
  end
  return
 end
 if event=='AUCTION_HOUSE_CLOSED'then batch=nil;originalClear();return end
 if event=='UI_ERROR_MESSAGE'then
  trace('UI error: '..tostring(message))
  if batch.pending then trace('rejected after '..string.format('%.2f',now()-batch.pending.since)..'s '..rowDetails(batch.pending.index))end
  if not batch.pending then return end
  -- An explicit missing-auction rejection is safe to search past; an uncertain
  -- timeout or other failure must never automatically retry a purchase.
  local missing=message and (message==ERR_ITEM_NOT_FOUND
   or message=='The item was not found.')
  if missing and batch.pending then
   -- Each rejection follows a fresh user click; one refresh here cannot
   -- create an automatic purchase/retry loop. Keep the dialog and progress.
   batch.pending=nil;batch.refreshed=true;queue(batch.page)
  else stop(message or 'Purchase interrupted.')end
  return
 end
 if message~=ERR_AUCTION_BID_PLACED or not ERR_AUCTION_BID_PLACED or not batch.pending then return end
 trace('accepted')
 batch.pending=nil;batch.bought=batch.bought+1
 -- Remove only this acknowledged purchase, never cumulative attempted buys.
 AuctionatorSubtractFromScan(batch.link,batch.stack,batch.price,1)
 progress()
 if batch.bought>=batch.target then stop();return end
 -- Native purchase updates can leave stale indices even when the matching
 -- count changes. Only an explicit same-page query prepares the next click.
 batch.refreshed=true;queue(batch.page)
end)
hooksecurefunc('PlaceAuctionBid',function()
 if batch and not sending then stop('Another bid interrupted the selected purchase batch.')end
end)
hooksecurefunc('QueryAuctionItems',function()
 if batch and not querying then stop('Another auction search interrupted the selected purchase batch.')end
end)
