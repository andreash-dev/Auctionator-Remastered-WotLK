dofile("AuctionatorRemastered/Remastered/Core/Bootstrap.lua")
dofile("AuctionatorRemastered/Remastered/Integration/LegacyBridge.lua")
-- lua5.1 tools/tests/test_database_stats.lua
local hooks={}
function hooksecurefunc(name,fn) hooks[name]=fn end
local realm='Realm'
function GetRealmName() return realm end
function UnitFactionGroup() return 'Alliance' end
local now=100
function time() return now end
function IsControlKeyDown() return false end
local info={SetPoint=function() end,SetWidth=function() end,SetJustifyH=function() end,SetSpacing=function() end,SetText=function() end}
Atr_ScanningOptionsFrame={CreateFontString=function() return info end,HookScript=function() end}
local frames={}
local function widget(name)
 local w={name=name,shown=true,scripts={},width=600}
 function w:CreateFontString() return widget() end
 function w:HookScript(event,fn) self.scripts[event]=fn end
 function w:SetText(v) self.text=v end
 function w:SetWidth(v) self.width=v end
 function w:GetWidth() return self.width end
 function w:GetFont() return 'test-font',12,'' end
 function w:SetFont(font,size,flags) self.fontSize=size end
 function w:SetPoint(...) self.point={...} end
 function w:SetHeight(value) self.height=value end
 function w:SetSize(width,height) self.width,self.height=width,height end
 function w:IsShown() return self.shown end
 function w:Hide() self.shown=false end
 setmetatable(w,{__index=function(_,key) if key:match('^Set') or key=='ClearAllPoints' then return function() end end end})
 if name then _G[name]=w end
 frames[#frames+1]=w
 return w
end
function CreateFrame(_,name) return widget(name) end
function Atr_StyleOfflineBrowser(frame) frame.styled=true end
function date() return 'date' end
gScanHistDayZero=0
local redraws=0
function Atr_UpdateFullScanCounts() redraws=redraws+1 end
ATR_FS_NULL=0;gAtr_FullScanState=0
AUCTIONATOR_DATABASE_STATS={Realm_Alliance={since=1,scans=6,fast=4,slow=2}}
dofile('AuctionatorRemastered/Remastered/Models/DatabaseStats.lua')
assert(loadfile('AuctionatorRemastered/Remastered/Data/DatabaseStats.lua'))()
local checks=0
local function check(ok,message) checks=checks+1;assert(ok,message) end
local fast,slow=Atr_GetFullScanCounts()
check(fast==4 and slow==2,'reuse existing saved counters')
hooks.Atr_FullScanStart();hooks.Atr_Broadcast_DBupdated(1,'search')
fast,slow=Atr_GetFullScanCounts()
check(fast==4 and slow==2 and redraws==0,'searches and rejected starts do not add completed scans')
gAtr_FullScanState=1;Atr_FullScanSlowMode=false
hooks.Atr_FullScanStart();now=120;hooks.Atr_Broadcast_DBupdated(100,'fullscan')
fast,slow=Atr_GetFullScanCounts()
check(fast==5 and slow==2 and redraws==1,'completed fast scan updates saved total and dialog')
Atr_FullScanSlowMode=true;hooks.Atr_FullScanStart();now=150
hooks.Atr_Broadcast_DBupdated(100,'page')
fast,slow=Atr_GetFullScanCounts()
check(fast==5 and slow==2,'individual slow pages are not completed scans')
hooks.Atr_Broadcast_DBupdated(150,'fullscan')
fast,slow=Atr_GetFullScanCounts()
check(fast==5 and slow==3 and redraws==2,'completed slow scan increments once')
check(AUCTIONATOR_DATABASE_STATS.Realm_Alliance.scans==8,'existing aggregate totals preserved')
assert(loadfile('AuctionatorRemastered/Remastered/Data/DatabaseStats.lua'))()
fast,slow=Atr_GetFullScanCounts()
check(fast==5 and slow==3,'counts survive module reload')
realm='Other';fast,slow=Atr_GetFullScanCounts()
check(fast==0 and slow==0,'realm/faction counters are isolated')
check(QueryAuctionItems==nil,'statistics require no auction queries')
realm='Realm'
gAtr_ScanDB={Rare={mr=100,quality=3,lastScan=now,H10=100,M10=110,M11=100},
 Epic={mr=200,quality=4,lastScan=now-90000},Unknown={mr=80},NoPrice={mr=0,quality=3}}
local overview=Atr_GetDatabaseOverview()
check(overview.total==3 and overview.quality[3]==1 and overview.quality[4]==1 and overview.unknownQuality==1,'rarity totals include priced variants only, preserving unknown quality')
check(overview.recent==1,'recent prices use a bounded 24-hour window')
local days,oldest,newest,samples=Atr_GetDatabaseCoverage()
check(days==2 and oldest==10 and newest==11 and samples==2,'median and low on the same day are one item/day observation')
hooks.Atr_NewSearch();hooks.Atr_NewSearch()
check(AUCTIONATOR_DATABASE_STATS.Realm_Alliance.searches==2 and AUCTIONATOR_DATABASE_STATS.Realm_Alliance.scans==8,'search counter is independent of persisted completed scans')
AuctionatorRemastered.UI.Options={BindLabelHelp=function(label,parent,help) label.help=help end}
dofile('AuctionatorRemastered/Remastered/UI/DatabaseStatus.lua')
Atr_DatabaseStatusOptions.shown=true
Atr_DatabaseStatusOptions.scripts.OnShow()
local styled=0
for _,frame in ipairs(frames) do if frame.styled then styled=styled+1 end end
check(styled==4 and Atr_DatabaseStatusOptions.atrStatsNote.text:find('Searches include Buy, Sell and Undercuts.',1,true),'status renders four themed cards with clear counter explanations')
local median,count=Atr_GetFullScanMedianDuration()
check(median==25 and count==2,'median averages the middle of two measured completed scans')
gAtr_FullScanState=1;hooks.Atr_FullScanStart();now=now+10000;hooks.Atr_Broadcast_DBupdated(50,'fullscan')
median,count=Atr_GetFullScanMedianDuration()
check(median==30 and count==3,'an unusually slow scan does not dominate median timing')
for i=1,105 do hooks.Atr_FullScanStart();now=now+6;hooks.Atr_Broadcast_DBupdated(50,'fullscan') end
median,count=Atr_GetFullScanMedianDuration()
check(median==6 and count==100,'timing history is bounded to the latest 100 measured completions')
-- Canonical variants can intentionally disappear from the name view when
-- two item IDs share a name. Their history must still count exactly once.
dofile('AuctionatorRemastered/Remastered/Models/ItemIdentity.lua')
dofile('AuctionatorRemastered/Remastered/Models/Database.lua')
local model=AuctionatorRemastered.Models.Database
local handle=assert(model.Open(model.New(),'Realm_Alliance','enUS'))
model.Write(handle,'Shared name',100,1000,10,'item:100:0')
model.Write(handle,'Shared name',200,1000,11,'item:200:0')
gAtr_ScanDB=handle.view
function Atr_DatabaseRows() return model.Rows(handle) end
local covered,first,last,observations=Atr_GetDatabaseCoverage()
check(next(gAtr_ScanDB)==nil and covered==2 and first==10 and last==11 and observations==2,'ambiguous-name variants retain their full canonical history coverage')
model.Bind(handle,'Another name','item:100:0')
covered,first,last,observations=Atr_GetDatabaseCoverage()
check(observations==2,'additional aliases do not duplicate canonical item/day records')
Atr_DatabaseRows=nil
local same={H10=100,M10=110};gAtr_ScanDB={Alias1=same,Alias2=same}
covered,first,last,observations=Atr_GetDatabaseCoverage()
check(covered==1 and observations==1,'legacy name-view fallback also deduplicates shared record references')
print('PASS: '..checks..' persisted full-scan counter checks')
Atr_DatabaseStatusOptions:SetWidth(416)
Atr_DatabaseStatusOptions.scripts.OnShow()
local count,fields=0,0
for _,card in ipairs(frames) do
 if card.rows then
  count=count+1
  assert(card.width==178 and card.height==128,'two cards fit stock width without a minimum-width overflow')
  assert(card.point[4]+card.width<=392 and -card.point[5]+card.height<=358,'cards remain inside stock content bounds')
  for _,pair in ipairs(card.rows) do
   assert(pair[1].height==13 and pair[1].fontSize==11 and pair[2].height==13,'single-line rows use compact readable metrics')
   if pair[1].text~='' then fields=fields+1 end
  end
 end
end
assert(count==4 and fields==24,'all four groups and all 24 statistics are retained')
assert(-Atr_DatabaseStatusOptions.atrStatsNote.point[5]+Atr_DatabaseStatusOptions.atrStatsNote.height<=408,'all explanatory notes fit inside the panel')
print('PASS: original-window database cards, row bounds, footer and all retained statistics')

local completeLabel
for _,card in ipairs(frames) do if card.rows and card.rows[5][1].text=='Last complete' then completeLabel=card.rows[5][1] end end
assert(completeLabel and completeLabel.help[1]=='Last complete scan' and completeLabel.help[2]:find('partial scans',1,true),'compact complete-scan label retains full explanation in hover help')
print('PASS: complete-scan caption and heading hover help')
