-- Run the new store through real legacy writers, the full-scan analyzer and UI models.
dofile('AuctionatorRemastered/Remastered/Core/Bootstrap.lua')
dofile('AuctionatorRemastered/Remastered/Integration/LegacyBridge.lua')
dofile('AuctionatorRemastered/Remastered/Models/ItemIdentity.lua')
dofile('AuctionatorRemastered/Remastered/Models/Database.lua')
dofile('AuctionatorRemastered/Remastered/Models/ItemMetadata.lua')
local day,stamp=100,100000
function time(value) return value and 0 or stamp end
function GetTime() return stamp end
function GetRealmName() return 'Realm' end
function UnitFactionGroup() return 'Alliance' end
function GetLocale() return 'enUS' end
function Atr_GetScanDay_Today() return day end
function ZT(value) return value end
local function noop() end
local frames={}
local function widget()
 local w={scripts={},text='',shown=true}
 function w:SetText(text) self.text=text end
 function w:GetText() return self.text end
 function w:IsShown() return self.shown end
 function w:SetWidth(value) self.width=value end
 function w:SetHeight(value) self.height=value end
 function w:CreateFontString() return widget() end
 function w:SetScript(name,fn) self.scripts[name]=fn end
 function w:RegisterEvent(name) self[name]=true end
 function w:UnregisterAllEvents() self.stopped=true end
 function w:Hide() self.shown=false end
 function w:Show() self.shown=true end
 function w:HookScript() end
 return setmetatable(w,{__index=function(_,name) if name:match('^Set') or name=='Enable' or name=='Disable' or name=='ClearAllPoints' then return noop end end})
end
function CreateFrame() local f=widget();frames[#frames+1]=f;return f end
StaticPopupDialogs={};local warning
function StaticPopup_Show(_,reason) warning=reason end
Atr_core=widget()
function hooksecurefunc(name,callback)
 local original=assert(_G[name],name..' must exist before hooking')
 _G[name]=function(...) local result={original(...)};callback(...);return unpack(result) end
end
local function source(path)
 local f=assert(io.open('AuctionatorRemastered/'..path,'rb'));local text=f:read('*a'):gsub('\r\n','\n');f:close();return text
end
local legacy=source('Legacy/AuctionatorScan.lua')
for _,name in ipairs({'Atr_GetDBsize','Atr_UpdateScanDBprice','Atr_UpdateScanDBitemID','Atr_UpdateScanDBclassInfo','Atr_PruneScanDB'}) do
 local text=assert(legacy:match('(function '..name..' %b().-\nend)') or legacy:match('(function '..name..'%b().-\nend)'))
 assert(loadstring('local zc={msg_badErr=function() error("unexpected legacy path") end};'..text))()
end
local initCount=0
function Atr_InitScanDB() return Atr_DatabaseInitialize() end
function Atr_OnLoad() initCount=initCount+1;Atr_InitScanDB() end
function Atr_PrunePostDB() end
local broadcasts=0
function Atr_Broadcast_DBupdated() broadcasts=broadcasts+1 end
function Atr_PurgeObsoleteItems() end
AUCTIONATOR_DB_MAXHIST_DAYS=30;AUCTIONATOR_DB_MAXITEM_AGE=180;AUCTIONATOR_SCAN_MINLEVEL=1
AUCTIONATOR_PRICE_DATABASE={__dbversion=4,Realm_Alliance={ForeignOldFormat={mr=1}}}
dofile('AuctionatorRemastered/Remastered/Models/MarketHistory.lua')
dofile('AuctionatorRemastered/Remastered/Integration/MarketHistory.lua')
dofile('AuctionatorRemastered/Remastered/Integration/Database.lua')
local storeFrame=frames[#frames]
Atr_OnLoad()
local checks=0
local function check(ok,message) checks=checks+1;assert(ok,message) end
check(initCount==1 and not gAtr_ScanDB.ForeignOldFormat,'Fresh root ignores the entire old name-keyed database')
local initialView=gAtr_ScanDB
Atr_OnLoad()
check(initCount==1 and gAtr_ScanDB==initialView,'Own-addon and VARIABLES_LOADED notifications initialize core once')
local function link(id,suffix,name) return '|Hitem:'..id..':0:0:0:0:0:'..(suffix or 0)..':0:80|h['..name..']|h' end
local bear=link(100,-5,'Sword of the Bear')
local tiger=link(100,5,'Sword of the Tiger')
Atr_UpdateScanDBitemID('Sword of the Bear',bear)
Atr_UpdateScanDBprice('Sword of the Bear',100)
Atr_UpdateScanDBclassInfo('Sword of the Bear',1,2)
local row=Atr_DatabaseRecord('100:-5')
check(row.mr==100 and row.M100==100 and row.cc==1 and row.id=='100:-5','Original entry points delegate to canonical prices and median sampler')
check(gAtr_ScanDB['Sword of the Bear']==row,'Compatibility view shares the price record, no persistent duplicate')
stamp=stamp+3600;Atr_UpdateScanDBprice('Sword of the Bear',200)
check(row.M100==150 and row.H100==200 and row.L100==100)
local explicit={}
Atr_UpdateScanDBprice('Explicit',5,explicit)
check(explicit.Explicit.mr==5 and not gAtr_ScanDB.Explicit,'Explicit unrelated tables remain isolated')
local originalBuyAPI=source('Legacy/AuctionatorHints.lua'):match('(function Atr_GetAuctionPrice %b().-\nend)')
assert(loadstring('local zc={};'..originalBuyAPI))()
check(Atr_GetAuctionPrice(bear)==200 and Atr_GetAuctionPrice('100:-5')==200)
local priceAPI=source('Legacy/AuctionatorAPI.lua'):match('(function Atr_GetAuctionBuyout %b().-\nend)')
assert(loadstring(priceAPI))()
check(Atr_GetAuctionBuyout(bear)==200 and not Atr_GetAuctionBuyout(link(999,0,'Sword of the Bear')),'An unknown ID never falls back to another item with the same name')
-- Stage observations without modifying prices, then abort.
Atr_DatabaseBeginFullScan();Atr_DatabaseObserveRow('Sword of the Bear',bear,1,1,2)
storeFrame.scripts.OnEvent(storeFrame,'AUCTION_HOUSE_CLOSED')
check(row.mr==200,'Cancelled scan never writes its staged prices')
Atr_DatabaseCommitFullScan(1,true,false)
check(row.mr==200,'Discarded batch cannot commit later')
-- Exercise the original full-scan Start -> Analyze -> UpdateDB path.
local listings={
 {name='Sword of the Bear',link=bear,count=2,buyout=100,quality=2},
 {name='Sword of the Tiger',link=tiger,count=1,buyout=999,quality=2},
 {name='Sword of the Bear',link=bear,count=1,buyout=70,quality=2},
 {name='Shared',link=link(300,0,'Shared'),count=1,buyout=300,quality=1},
 {name='Shared',link=link(301,0,'Shared'),count=1,buyout=301,quality=1},
 {name='Bid only',link=link(400,0,'Bid only'),count=1,buyout=0,quality=1},
 {name='Uncached',link=nil,count=1,buyout=80,quality=1},
}
function GetAuctionItemInfo(_,i) local r=listings[i];return r.name,'Icon',r.count,r.quality,nil,nil,nil,nil,r.buyout,nil,nil,'Seller' end
function GetAuctionItemLink(_,i) return listings[i].link end
function IsControlKeyDown() return false end
function CanSendAuctionQuery() return true,true end
function Atr_GetNumAuctionItems() return #listings,#listings,#listings end
local queries=0
function QueryAuctionItems(...) local args={...};queries=queries+1;if args[10] then check(args[1]=='' and args[7]==0 and args[8]==false and args[9]==-1 and args[10]==true,'Native bulk request arguments unchanged') end end
function SortAuctionClearSort() end
for _,name in ipairs({'Atr_FullScanFrame','Atr_FullScanStatus','Atr_FullScanStartButton','Atr_FullScanDone','Atr_FSR_scanned_count','Atr_FSR_added_count','Atr_FSR_updated_count','Atr_FSR_ignored_count','Atr_FullScanHTML','Atr_FullScanResults'}) do _G[name]=widget() end
local zc={md=noop}
assert(loadfile('AuctionatorRemastered/Legacy/AuctionatorScanFull.lua'))('AuctionatorRemastered',{zc=zc})
Atr_UpdateFullScanFrame=noop;Atr_ClearBrowseListings=noop
dofile('AuctionatorRemastered/Remastered/Integration/FullScan.lua')
local scanDriver=frames[#frames-1]
Atr_Init=noop;Atr_ScanningConfigFrame_Update=noop;Atr_ScanningOptionsFrame=widget()
function Atr_NewSearch() return {} end -- Constructor is outside this staged-scan harness.
dofile('AuctionatorRemastered/Remastered/Models/DatabaseStats.lua')
dofile('AuctionatorRemastered/Remastered/Data/DatabaseStats.lua')
local scan=AuctionatorRemastered.FullScan
local function drainScan() for i=1,1000 do if not scan.running then return end;scan.Tick() end;error('scan did not finish') end
AUCTIONATOR_DC_PAUSE=0
Atr_FullScanStart(true)
check(queries==1 and row.mr==200,'Beginning a real scan does not write staged prices')
check(not Atr_FullScanHTML.shown and scan.timing.shown and scan.help.shown and not Atr_FullScanStartButton.shown,'Active scans replace generic help and controls with a dedicated progress area')
Atr_FullScanAnalyze();drainScan()
row=Atr_DatabaseRecord('100:-5')
check(queries==1 and row.mr==50 and Atr_DatabaseRecord('100:5').mr==999,'Exact variant minima committed without extra queries')
check(Atr_DatabaseRecord(300).mr==300 and Atr_DatabaseRecord(301).mr==301 and not Atr_DatabaseRecord('Shared'),'Full scan separates same-name different-ID prices')
check(Atr_DatabaseRecord('Uncached').mr==80 and not Atr_DatabaseRecord(400),'Missing links remain unresolved, bid-only rows create no fake price')
local market=AuctionatorRemastered.Database.active.market
check(market.lastScan.complete and market.lastCompleteScan==stamp and market.lastScan.unresolved==1)
check(market.lastScan.invalid==0 and market.lastScan.identified==4)
local health=Atr_GetDatabaseHealth()
check(Atr_GetDBsize()==health.identified+health.unresolved,'Database size counts canonical variants plus unresolved records, including shared-name IDs')

Atr_UpdateScanDBprice('Shared',9999,nil,link(300,0,'Shared'))
Atr_UpdateScanDBclassInfo('Shared',1,2,link(300,0,'Shared'))
check(Atr_DatabaseRecord(300).mr==9999 and Atr_DatabaseRecord(301).mr==301 and Atr_DatabaseRecord(300).cc==1,'Normal scan writes remain exact even when name is ambiguous')
Atr_UpdateScanDBprice('Shared',300,nil,link(300,0,'Shared'))
-- A market-sized bulk response stays staged across bounded frame slices.
listings={}
for i=1,52612 do listings[i]={name='Bulk '..i,link=link(1000000+i,0,'Bulk '..i),count=2,buyout=1000+i,quality=1} end
gAtr_FullScanState=ATR_FS_NULL
Atr_FullScanStart(true);Atr_FullScanAnalyze()
check(not Atr_DatabaseRecord(1000001),'First 1000-row chunk stays staged')
Atr_FullScanAnalyze();check(not Atr_DatabaseRecord(1000001),'Second chunk stays staged')
Atr_FullScanAnalyze();drainScan()
check(Atr_DatabaseRecord(1000001).mr==500 and Atr_DatabaseRecord(1052612).mr==26806 and scan.result.auctions==52612 and queries==2,'Final chunk commits all exact item minima, one bulk request')
-- The existing slow-page flow commits only after its terminating empty page.
function IsControlKeyDown() return false end
function CanSendAuctionQuery() return true,true end
Atr_FullScanSlowMode=true;gAtr_FullScanState=ATR_FS_NULL
Atr_FullScanFrameIdle()
listings={{name='Slow item',link=link(15000,0,'Slow item'),count=1,buyout=123,quality=1}}
Atr_FullScanStart();Atr_FullScanAnalyze()
check(not Atr_DatabaseRecord(15000),'Slow pages remain staged before the terminating page')
drainScan()
check(Atr_DatabaseRecord(15000).mr==123 and market.lastScan.mode=='slow' and queries==2,'Slow completion writes once without changing its query scheduling')
-- Invalid input prevents a "complete" freshness claim but never fabricates prices.
Atr_DatabaseBeginFullScan();Atr_DatabaseObserveRow('Broken',link(700,0,'Broken'),0,10,1)
Atr_DatabaseCommitFullScan(1,true,false)
check(not market.lastScan.complete and market.lastScan.invalid==1 and not Atr_DatabaseRecord(700))
local complete=market.lastCompleteScan
stamp=stamp+100
Atr_DatabaseBeginFullScan();Atr_DatabaseObserveRow('New',link(600,0,'New'),1,12,1)
Atr_DatabaseCommitFullScan(1,false,true)
check(not market.lastScan.complete and market.lastCompleteScan==complete and Atr_DatabaseRecord(600).mr==12,'Partial observations do not refresh the last completed scan')
-- Build browser rows and compute references against the real managed view.
function GetItemInfo(value)
 local key=AuctionatorRemastered.Models.ItemIdentity.Parse(value)
 if key=='item:100:-5' then return 'Sword of the Bear',bear,2,80,1,'Weapon','Sword',1,'INVTYPE_WEAPON','BearIcon' end
 if key=='item:100:5' then return 'Sword of the Tiger',tiger,2,80,1,'Weapon','Sword',1,'INVTYPE_WEAPON','TigerIcon' end
end
function Atr_GetBaseItemInfo() return {} end
function Atr_GetBaseItemLink() end
function Atr_GetCurrentPane() end
AUCTIONATOR_BROWSER_ITEMS={};AUCTIONATOR_BROWSER_SETTINGS={}
dofile('AuctionatorRemastered/Remastered/Data/BrowserData.lua')
local snapshot=Atr_BuildBrowserSnapshot()
local names={};for _,r in ipairs(snapshot) do if r.name=='Shared' then names[r.itemKey]=r.price end end
check(names['item:300:0']==300 and names['item:301:0']==301,'Browser exposes both same-name variants with stable row keys')
local handle=AuctionatorRemastered.Database.active
local before=handle.cacheHits
snapshot[1].price=-1
local nextSnapshot=Atr_BuildBrowserSnapshot()
check(handle.cacheHits>before and nextSnapshot[1].price~=-1,'Cached snapshots are reused without exposing mutable cached rows')
row.M99=100;Atr_DatabaseInvalidate()
check(Atr_MarketReference('100:-5')==100)
dofile('AuctionatorRemastered/Remastered/Models/Deals.lua')
Atr_DatabaseRecord(300).M99=1000;Atr_DatabaseRecord(301).M99=2000
Atr_DatabaseRecord('Uncached').M99=10000;Atr_DatabaseInvalidate()
local deals=Atr_BuildDeals({minDays=0,minProfit=0,maxAge=720,maxMarket=1000},'Shared')
local dealByID={};for _,deal in ipairs(deals) do dealByID[deal.itemKey]=deal end
check(dealByID['item:300:0'].reference==1000 and dealByID['item:301:0'].reference==2000,'Deals uses exact references for same-name variants')
local pendingDeals=Atr_BuildDeals({minDays=0,minProfit=0,maxAge=720,maxMarket=1000},'Uncached')
check(#pendingDeals==0,'Unidentified prices cannot generate misleading Deals recommendations')
local hits=handle.cacheHits
check(Atr_MarketReference('100:-5')==100 and handle.cacheHits>hits,'History reference memoized')
AUCTIONATOR_MARKET_HISTORY_DAYS=3;check(Atr_MarketReference('100:-5')==100,'Reference window belongs to cache identity')
day=101;check(Atr_MarketReference('100:-5')==125,'Day rollover invalidates references even without a price write')
check(AUCTIONATOR_REMASTERED_DATABASE.catalog.items['item:100:-5'].texture=='BearIcon','Learned metadata stored under the exact variant key')
check(AUCTIONATOR_REMASTERED_DATABASE.catalog.items['item:100:5'].texture=='TigerIcon','Suffix metadata remains separate')
-- Real clear/sync never leaves a persisted orphan. Full Undo is tested at model level.
gAtr_ScanDB['Sword of the Tiger']=nil;Atr_DatabaseSync()
check(not Atr_DatabaseRecord('100:5'))
local backup=Atr_DatabaseClearMarket()
check(next(market.items)==nil)
Atr_DatabaseUndoMarket(backup)
check(Atr_DatabaseRecord('100:-5').mr==50 and Atr_DatabaseRecord(300).mr==300)
-- Lifecycle regressions: bounded analysis/preparation, atomic cancel, retries,
-- timeouts, exact page boundaries, partial results and external buffer changes.
local clock,advance=0,0
function GetTime() clock=clock+advance;return clock end
Atr_FullScanSlowMode=false
local beforePrice=Atr_DatabaseRecord('100:-5').mr
local beforeMedian=Atr_DatabaseRecord('100:-5').M100
local function single(price) return {{name='Sword of the Bear',link=bear,count=1,buyout=price,quality=2}} end
listings=single(1)
Atr_FullScanStart(true);Atr_FullScanAnalyze()
check(gAtr_FullScanState==ATR_FS_UPDATING_DB and Atr_DatabaseRecord('100:-5').mr==beforePrice,'Analysis never publishes prices')
-- A tiny budget deliberately prepares a row and yields before publication.
Atr_DatabaseFullScanStep(-1)
check(Atr_DatabaseRecord('100:-5').mr==beforePrice,'History preparation stays private')
Atr_FullScanCancel()
check(Atr_DatabaseRecord('100:-5').mr==beforePrice and Atr_DatabaseRecord('100:-5').M100==beforeMedian,'Cancellation discards prepared prices and median samples')
check(not scan.running and gAtr_FullScanState==ATR_FS_NULL,'Cancel restores idle state')
listings=single(1);local beforeQueries=queries
Atr_FullScanStart(true);clock=clock+31;scan.Tick()
check(not scan.running and scan.error:find('30 seconds',1,true) and queries==beforeQueries+1,'Waiting timeout does not automatically repeat a getAll request')
check(Atr_FullScanStatus.width==460 and Atr_FullScanStatus.height==44 and Atr_FullScanStartButton.shown and not scan.timing.shown,'Long errors have a bounded multiline area and restore idle controls')
Atr_FullScanStart(true);
scan.scanned=1399;scan.total=52612;clock=clock+1;scan.Tick()
check(scan.progress:GetText():find('1k / 52.6k',1,true),'Fast scan progress uses whole thousands')
local displayed=scan.progress:GetText()
scan.scanned=1450;clock=clock+.01;scan.Tick()
check(scan.progress:GetText()==displayed,'Presentation updates are throttled independently of scan work')
scan.scanned=2010;clock=clock+.2;scan.Tick()
check(scan.progress:GetText():find('2k / 52.6k',1,true),'Progress advances to the next whole thousand')
scan.slow=true;scan.completedScanned=2700;scan.total=52350;scan.startedAt=clock-87;scan.pausedFor=0
check(math.ceil(scan.EstimatedRemaining()/60)==27,'Observed screenshot rate estimates about 27 minutes remaining')
scan.pausedFor=27
check(scan.EstimatedRemaining()==(52350-2700)*60/2700,'Time spent choosing stop/save does not inflate the estimated scan duration')
scan.completedScanned=200
check(scan.EstimatedRemaining()==nil,'ETA waits for five complete pages before estimating')
scan.slow=false

Atr_FullScanCancel()
check(not scan.progress.shown,'Completion/cancel hides the separate progress line')

listings=single(1);Atr_FullScanStart(true)
QueryAuctionItems('another search')
check(not scan.running and Atr_DatabaseRecord('100:-5').mr==beforePrice,'Other searches abort before their shared result buffer can contaminate prices')
listings=single(1);Atr_FullScanStart(true);gAtr_FullScanState=ATR_FS_ANALYZING
-- Time budget, not just the row-count ceiling, yields to the client.
for i=2,100 do listings[i]={name='Sword of the Bear',link=bear,count=1,buyout=2,quality=2} end
advance=.001;scan.Tick();advance=0
check(scan.scanned>0 and scan.scanned<100,'Analysis yields when the frame time budget is exhausted')
Atr_FullScanCancel()
-- The database commit's counters count ID variants, including shared names.
listings={{name='Shared',link=link(300,0,'Shared'),count=1,buyout=321,quality=1},
 {name='Shared',link=link(301,0,'Shared'),count=1,buyout=322,quality=1}}
Atr_FullScanStart(true);Atr_FullScanAnalyze();drainScan()
check(scan.result.updated==2 and scan.result.totalItems==2,'Results count canonical variants rather than distinct names')
-- Slow scan ends on the reported last page, no extra empty-page query.
Atr_FullScanSlowMode=true
local total=51
function Atr_GetNumAuctionItems() return #listings,total,total end
listings={};for i=1,50 do listings[i]={name='Page '..i,link=link(20000+i,0,'Page '..i),count=1,buyout=i,quality=1} end
beforeQueries=queries;Atr_FullScanStart();scan.Tick();Atr_FullScanAnalyze()
check(gAtr_FullScanState==ATR_FS_SLOW_QUERY_NEEDED and not Atr_DatabaseRecord(20001),'First page remains staged')
local pageStatus=Atr_FullScanStatus:GetText()
check(pageStatus:find('Slow scan: page 1 / 2',1,true) and scan.progress:GetText():find('50 / 51',1,true),'Slow page status and auction count occupy separate stable text lines')

scan.Tick();listings={{name='Page 51',link=link(20051,0,'Page 51'),count=1,buyout=51,quality=1}}
Atr_FullScanAnalyze();drainScan()
check(scan.result.complete and scan.result.auctions==51 and queries==beforeQueries+2,'Slow scan consumes 51 rows across exactly two page queries')
check(Atr_DatabaseRecord(20001).mr==1 and Atr_DatabaseRecord(20051).mr==51,'All slow pages publish together')
local successfulFast,successfulSlow=Atr_GetFullScanCounts()
-- Repeated missing names have a finite retry count and are counted once.
listings={{count=1,buyout=10,quality=1}};total=1
beforeQueries=queries;Atr_FullScanStart()
for i=1,3 do clock=clock+2;scan.Tick();Atr_FullScanAnalyze() end
drainScan()
check(not scan.result.complete and scan.result.invalid==1 and scan.result.auctions==1 and queries==beforeQueries+3,'Two retries then an honest partial result; no duplicate scan counts')
-- Complete marker must not move when a result is partial.
local completeStamp=market.lastCompleteScan
listings={};total=100;Atr_FullScanStart();scan.Tick();Atr_FullScanAnalyze();drainScan()
check(not scan.result.complete and market.lastCompleteScan==completeStamp,'Premature empty slow page cannot advance last-complete timestamp')
-- Fast incomplete responses also remain explicitly partial.
Atr_FullScanSlowMode=false;listings=single(20);total=2
Atr_FullScanStart(true);Atr_FullScanAnalyze();drainScan()
check(not scan.result.complete and market.lastCompleteScan==completeStamp,'Truncated bulk response cannot count as complete')
-- Explicit stop-save publishes completed slow pages, excluding the current
-- half-read page; automatic AH close still discards every pending price.
Atr_FullScanSlowMode=true;total=1000;listings={}
for i=1,50 do listings[i]={name='Stopped '..i,link=link(500000+i,0,'Stopped '..i),count=1,buyout=i,quality=1} end
Atr_FullScanStart();scan.Tick();Atr_FullScanAnalyze()
check(scan.completedScanned==50,'Completed slow page checkpoint advances only after all rows')
scan.Tick();listings={}
for i=51,100 do listings[#listings+1]={name='Stopped '..i,link=link(500000+i,0,'Stopped '..i),count=1,buyout=i,quality=1} end
scan.maxRows=1;Atr_FullScanAnalyze();scan.maxRows=1000
check(scan.scanned==51 and scan.completedScanned==50,'Half-read page does not advance the checkpoint')
Atr_FullScanStopAndSave();drainScan()
check(scan.result.stopped and not scan.result.complete and scan.result.auctions==50,'Stop and save publishes an explicitly incomplete result')
check(Atr_DatabaseRecord(500001).mr==1 and Atr_DatabaseRecord(500050).mr==50 and not Atr_DatabaseRecord(500051),'Only completed pages are saved')
check(Atr_DatabaseRecord(500001)._partial and market.lastCompleteScan==completeStamp,'Stopped observations are marked partial without moving complete timestamp')
local lastSaved=market.lastScan
listings={{name='Stopped 1',link=link(500001,0,'Stopped 1'),count=1,buyout=999,quality=1}}
Atr_FullScanStart();scan.Tick();Atr_FullScanAnalyze()
scanDriver.scripts.OnEvent(scanDriver,'AUCTION_HOUSE_CLOSED')
check(not scan.running and Atr_DatabaseRecord(500001).mr==1 and market.lastScan==lastSaved,'Walking away discards the scan rather than saving partial prices')
Atr_FullScanStart();scan.cancel.scripts.OnClick(scan.cancel)
check(scan.choicePending and StaticPopupDialogs.ATR_STOP_SCAN.button1=='Stop and save' and StaticPopupDialogs.ATR_STOP_SCAN.button3=='Discard scan','Cancel opens explicit save/continue/discard choices')
local beforePromptQueries=queries;scan.Tick()
check(queries==beforePromptQueries,'No new page query is sent while choosing')
StaticPopupDialogs.ATR_STOP_SCAN.OnHide()
check(not scan.choicePending,'Keep scanning or Escape releases the pause')
scan.cancel.scripts.OnClick(scan.cancel);StaticPopupDialogs.ATR_STOP_SCAN.OnAlt()
check(not scan.running and market.lastScan==lastSaved,'Discard choice leaves saved prices untouched')
Atr_FullScanStart();Atr_FullScanStopAndSave()
check(not scan.running and market.lastScan==lastSaved,'Stopping before a completed page does not publish an empty scan')
Atr_UpdateScanDBprice('Stopped 1',2,nil,link(500001,0,'Stopped 1'))
check(not Atr_DatabaseRecord(500001)._partial,'A subsequent normal price observation clears the partial flag')
local fastAfter,slowAfter=Atr_GetFullScanCounts()
check(fastAfter==successfulFast and slowAfter==successfulSlow,'Partial scans do not increment successful fast/slow counters')
function Atr_GetNumAuctionItems() return #listings,#listings,#listings end
-- Schema errors are non-destructive and stop original initialization.
local saved=AUCTIONATOR_REMASTERED_DATABASE
saved.schemaVersion=999
AuctionatorRemastered.Database.active=nil
AuctionatorRemastered.Database.initialized=nil
Atr_OnLoad()
check(warning and saved.schemaVersion==999 and Atr_core.stopped and initCount==1,'Unsupported versions are preserved and do not enter original initialization')
-- A primary initialization error must not leave a false "loaded" marker or
-- turn later AH events into unrelated nil-control failures.
AUCTIONATOR_REMASTERED_DATABASE=nil
Atr_OnLoad=function() AuctionatorLoaded=true;error('fixture initialization failure') end
dofile('AuctionatorRemastered/Remastered/Integration/Database.lua')
local initialized,errorText=pcall(Atr_OnLoad)
check(not initialized and errorText:find('fixture initialization failure',1,true) and AuctionatorLoaded==false,'Primary initialization failure clears the premature loaded flag')
check(not AuctionatorRemastered.Database.initialized and Atr_OnLoad()==false,'Failed initialization is not retried from unrelated UI events')
print('PASS: '..checks..' real writer/API, staged full-scan, query invariance, provenance, unresolved ID, same-name variant, cache, Clear/Undo and schema-failure integration checks')
