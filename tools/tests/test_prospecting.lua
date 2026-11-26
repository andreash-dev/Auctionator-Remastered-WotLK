dofile("AuctionatorRemastered/Remastered/Core/Bootstrap.lua")
dofile('AuctionatorRemastered/Remastered/Models/Prospecting.lua')
local P=AuctionatorRemastered.Models.Prospecting
local function close(a,b) assert(math.abs(a-b)<.00001,tostring(a)..' ~= '..b) end
local function quote() return 100,{} end
assert(P.Evaluate(2775,quote)==nil,'Silver cannot be prospected')
close(P.Evaluate(2770,quote),110)
close(P.Evaluate(23425,quote),309) -- 308.5 rounded once, including powder
close(P.Evaluate(36910,quote),358) -- 357.5, including tradable Titanium Powder
local count=0
for ore,rows in pairs(P.ores) do
 count=count+1
 local ids={}
 for _,r in ipairs(rows) do
  assert(not ids[r.id]);ids[r.id]=true
  assert(r.chance>0 and r.chance<=1 and r.expected>0)
  assert(r.minimum>=1 and r.maximum>=r.minimum)
 end
 local value,status=P.Evaluate(ore,function(id) if id~=rows[1].id then return 100 end end)
 assert(value==nil and not status.complete and #status.missing==1)
end
assert(count==10)
local _,status=P.Evaluate(2770,function() return 100,{stale=true,partial=true,undated=true} end)
assert(status.stale and status.partial and status.undated)
for _,bad in ipairs({0,-1,math.huge,0/0,'100'}) do
 local value,s=P.Evaluate(2770,function() return bad end)
 assert(not value and not s.complete)
end
local copper=P.ores[2770];assert(copper[1].id==774)
local saronite=P.ores[36912][1]
close(saronite.chance,1-(1-.85/6)*(1-.15))
close(saronite.expected,(.85/6+.15)*1.5)
assert(saronite.maximum==4,'two rolls can yield the same gem')
local hook
function AuctionatorRemastered.Legacy.Hook(_,fn) hook=fn end
function GetItemInfo() return nil end
local shifted,controlled,alted=false,false,false
function IsControlKeyDown() return controlled end
function IsAltKeyDown() return alted end
function IsShiftKeyDown() return shifted end
Atr_GetAuctionPriceDE=quote
Atr_GetAuctionPrice=function(id) if id~=46849 then return 321 end end
-- Legacy utilities are exposed as gAtrZC; zc is private to legacy chunks.
zc=nil
gAtrZC={priceToMoneyString=function(v) return tostring(v) end}
dofile('AuctionatorRemastered/Remastered/Integration/Prospecting.lua')
local tip={lines={},scripts={}}
function tip:HookScript(event,fn) self.scripts[event]=fn end
function tip:NumLines() return #self.lines end
function tip:AddLine(text) self.lines[#self.lines+1]=text end
function tip:AddDoubleLine(a,b) self:AddLine(a..' '..b) end
function tip:Show() self.shown=true end
local function clear() tip.lines={};if tip.scripts.OnTooltipCleared then tip.scripts.OnTooltipCleared(tip) end end
hook(tip,'item:2770',20)
assert(tip.shown and tip.lines[2]=='Prospecting / 5 ore |cFFFFFFFF110|r')
local n=#tip.lines;hook(tip,'item:2770',20);assert(#tip.lines==n,'no duplicate additions')
clear();shifted=true;hook(tip,'item:36910',1)
assert(table.concat(tip.lines,'\n'):find('Titanium Powder',1,true),'uncached names and powder shown')
assert(table.concat(tip.lines,'\n'):find('Possible materials / 5 ore',1,true))
assert(table.concat(tip.lines,'\n'):find('Lowest / item',1,true))
assert(table.concat(tip.lines,'\n'):find('321|r',1,true))
assert(table.concat(tip.lines,'\n'):find('Titanium Powder × 1 |cFFAAAAAAunknown|r',1,true))
assert(not table.concat(tip.lines,'\n'):find('WotLK estimate',1,true),'explanation belongs in settings help')
clear();shifted=false;AUCTIONATOR_SAVEDVARS={prospectingTips=false};hook(tip,'item:2770');assert(#tip.lines==0)
AUCTIONATOR_SAVEDVARS=nil;hook(tip,'item:2775');assert(#tip.lines==0)
Atr_GetAuctionPriceDE=function() return nil end
hook(tip,'item:2770');assert(table.concat(tip.lines,'\n'):find('unknown',1,true))
print('PASS: 10 prospectable ores, independent rolls, expected batch values, missing/invalid prices, confidence flags, tooltip toggle, Shift details and deduplication')

Atr_GetAuctionPriceDE=quote
local function hasDetails() return table.concat(tip.lines,'\n'):find('Possible materials / 5 ore',1,true)~=nil end
for _,mode in ipairs({'shift','control','alt','never','always'}) do
 AUCTIONATOR_SAVEDVARS={prospectingDetails=mode}
 shifted=false;controlled=false;alted=false;clear();hook(tip,'item:2770')
 assert(hasDetails()==(mode=='always'))
 shifted=mode=='shift';controlled=mode=='control';alted=mode=='alt'
 clear();hook(tip,'item:2770');assert(hasDetails()==(mode~='never'))
end
AUCTIONATOR_SAVEDVARS={prospectingTips=false,prospectingDetails='always'}
clear();hook(tip,'item:2770');assert(hasDetails() and not table.concat(tip.lines,'\n'):find('Prospecting / 5 ore',1,true),'details can be shown independently of value')
AUCTIONATOR_SAVEDVARS={prospectingDetails='invalid'}
assert(AuctionatorRemastered.UI.ProspectingDetailsMode()=='shift')
print('PASS: all five JC detail modes, independent value checkbox and invalid-setting fallback')
