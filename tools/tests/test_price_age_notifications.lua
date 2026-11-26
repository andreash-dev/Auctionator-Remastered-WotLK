dofile('AuctionatorRemastered/Remastered/Core/Bootstrap.lua')
local UI=AuctionatorRemastered.UI
local now=10000000
AUCTIONATOR_SAVEDVARS=nil
assert(UI.PriceAgeDays()==1 and UI.ScanNotification('message') and not UI.ScanNotification('sound'),'safe defaults')
assert(UI.MarkPriceAge('1d',now-86400,now):find('(old)',1,true),'boundary is marked')
assert(UI.MarkPriceAge('fresh',now-86400+1,now)=='fresh','younger prices are unchanged')
assert(UI.MarkPriceAge('unknown',nil,now)=='unknown' and UI.MarkPriceAge('future',now+1,now)=='future','unknown and future dates are not stale')
AUCTIONATOR_SAVEDVARS.oldPriceDays=0
assert(UI.MarkPriceAge('old',1,now)=='old','disabled warning')
AUCTIONATOR_SAVEDVARS.oldPriceDays=1
assert(UI.MarkPriceAge('1d',now-86400,now):find('(old)',1,true),'custom threshold')
AUCTIONATOR_SAVEDVARS.oldPriceDays='bad'
assert(UI.PriceAgeDays()==1,'invalid saved setting falls back')
AUCTIONATOR_SAVEDVARS.oldPriceDays=7
assert(UI.PriceAgeDays()==7,'existing custom age is retained')
-- Exercise the actual common completion path for fast and slow scans.
local f=assert(io.open('AuctionatorRemastered/Remastered/Integration/FullScan.lua'));local source=f:read('*a');f:close()
local definition=assert(source:match('(local function finish%b().-\nend)'))
local S={}
local finish=assert(loadstring('local S,reset,status=...\n'..definition..'\nreturn finish'))(S,function() end,function() end)
local label={SetText=function() end}
Atr_FSR_scanned_count=label;Atr_FSR_added_count=label;Atr_FSR_updated_count=label;Atr_FSR_ignored_count=label
Atr_FullScanHTML={Hide=function() end};Atr_FullScanResults={Show=function() end}
function Atr_UpdateFullScanFrame() end
function Atr_Broadcast_DBupdated() end
function CanSendAuctionQuery() return false end
local messages,sounds,cancelled=0,0,0
function Atr_FullScanMoreDetails() messages=messages+1 end
function PlaySound(name) assert(name=='ReadyCheck');sounds=sounds+1 end
function Atr_FullScanCancel() cancelled=cancelled+1 end
local function result(complete,mode) return {complete=complete,mode=mode,auctions=10,added=1,updated=0,ignored=0,identified=1,unresolved=0} end
finish(result(true,'fast'));assert(messages==1 and sounds==0,'default summary without sound')
AUCTIONATOR_SAVEDVARS.scanCompleteMessage=false;AUCTIONATOR_SAVEDVARS.scanCompleteSound=true
finish(result(true,'slow'));assert(messages==1 and sounds==1,'slow completion honors independent preferences')
finish(result(false,'slow'));assert(messages==2 and sounds==1,'partial warning remains, without success sound')
finish(nil);assert(cancelled==1 and sounds==1,'failed completion does not play sound')
print('PASS: price-age boundaries/defaults/disabled state and independent full-scan completion preferences')
