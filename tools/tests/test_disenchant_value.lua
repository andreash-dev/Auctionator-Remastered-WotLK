-- Run the real valuation/tooltip functions with isolated market/native APIs.
local f=assert(io.open('AuctionatorRemastered/Legacy/AuctionatorHints.lua'));local source=f:read('*a');f:close()
local a=assert(source:find('local UNCOMMON',1,true));local b=assert(source:find('function Atr_STWP_AddVendorInfo',a,true))
tinsert=table.insert
zc={md=function()end,priceToMoneyString=tostring,CopyDeep=function(to,from)
 local function copy(t)local out={};for k,v in pairs(t)do out[k]=type(v)=='table'and copy(v)or v end;return out end
 for k,v in pairs(copy(from))do to[k]=v end
end}
local prices,records={},{}
local calls={}
GetItemInfo=function()return nil end -- All material names deliberately uncached.
Atr_MarketReference=function() error("Material valuation must not use the Market reference") end
Atr_GetAuctionPrice=function(id)assert(type(id)=='number','Material lookup must use ID');calls[id]=(calls[id]or 0)+1;return prices[id]end
Atr_DatabaseRecord=function(id)return records[id]end
Atr_ItemType2AuctionClass=function(t)return t=='Armor'and 2 or (t=='Weapon'and 1 or nil)end
Atr_IsArmorType=function(t)return t=='Armor'end;Atr_IsWeaponType=function(t)return t=='Weapon'end
time=function()return 200000 end;ZT=function(s)return s end
assert(loadstring(source:sub(a,b-1)))();Atr_InitDETable()
local function reset()prices={};records={};calls={}end
local function quote(id,price,age,partial)
 prices[id]=price;records[id]={lastScan=age and time()-age or nil,_partial=partial}
end
-- Unknown branch cannot masquerade as a complete lower estimate.
reset();quote(10940,100,1)
local value,status=Atr_CalcDisenchantPrice('Armor',2,10)
assert(value==nil and not status.complete and #status.missing==1 and status.missing[1]==10938)
quote(10938,200,1);value,status=Atr_CalcDisenchantPrice('Armor',2,10)
assert(value==180 and status.complete and not status.stale and not status.partial)
assert(Atr_CalcDisenchantPrice('Armor',2,500)==nil)
assert(Atr_CalcDisenchantPrice('Armor',7,20)==nil)
assert(Atr_CalcDisenchantPrice('Armor',nil,nil)==nil)
-- Every original-Wrath essence pair works both ways, with one quote or two.
for _,pair in ipairs({{10938,10939},{10998,11082},{11134,11135},{11174,11175},{16202,16203},{22447,22446},{34056,34055}})do
 reset();quote(pair[2],301,1)
 local p,info=Atr_GetAuctionPriceDE(pair[1]);assert(math.abs(p-301/3)<1e-9 and info.converted and info.sourceID==pair[2])
 quote(pair[1],50,1);assert(Atr_GetAuctionPriceDE(pair[1])==50 and Atr_GetAuctionPriceDE(pair[2])==150)
 reset();quote(pair[1],100,1);assert(Atr_GetAuctionPriceDE(pair[2])==300)
end
-- Missing/invalid values never enter arithmetic; very cheap quotes stay fractional.
reset();prices[34056]=0;assert(Atr_GetAuctionPriceDE(34056)==nil)
prices[34056]=0/0;assert(Atr_GetAuctionPriceDE(34056)==nil)
prices[34056]=math.huge;assert(Atr_GetAuctionPriceDE(34056)==nil)
quote(34055,1,1);assert(math.abs(Atr_GetAuctionPriceDE(34056)-1/3)<1e-9)
-- Confidence follows the quote actually used, including converted material prices.
reset();quote(10940,100,90000);quote(10939,300,1,true)
value,status=Atr_CalcDisenchantPrice('Armor',2,10)
assert(value==150 and status.stale and status.partial)
records[10940].lastScan=nil;value,status=Atr_CalcDisenchantPrice('Armor',2,10);assert(status.undated)
-- Inspect actual expanded table rows; normalization covers all quality/level bands.
local data
for i=1,20 do local name,v=debug.getupvalue(Atr_InitDETable,i);if name=='deTable'then data=v;break end end
assert(data)
local count=0
for _,bands in pairs(data)do for _,row in ipairs(bands)do
 local total=0;for x=3,#row,3 do total=total+row[x];assert(row[x]>=0 and row[x+1]>=1 and row[x+2]>0)end
 assert(math.abs(total-100)<.000001,'Probability sum must be 100, got '..total);count=count+1
end end
assert(count>60)
-- Reported 51–65 weapon band has a 3% shard branch, not 5%.
local lines={};Atr_AddDEDetailsToTip({AddLine=function(_,s)lines[#lines+1]=s end,AddDoubleLine=function(_,s)lines[#lines+1]=s end},'Weapon',2,55)
assert(lines[#lines]:find('3 %%')and lines[#lines]:find('Small Brilliant Shard',1,true))
-- Display combines quantity outcomes into one pink row per material, with spacing.
local details={}
local detailTip={AddLine=function(_,text,r,g,b)details[#details+1]={text=text,r=r,g=g,b=b}end}
function detailTip:AddDoubleLine(text,right,r,g,b) self:AddLine(text,r,g,b);details[#details].right=right end
reset();quote(10940,321,1)
Atr_AddDEDetailsToTip(detailTip,'Armor',2,10)
assert(#details==4 and details[1].text==' ' and details[2].text=='Disenchant materials')
assert(details[3].text=='80 % - Strange Dust × 1–2')
assert(details[2].right=='Lowest / item' and details[3].right:find('321',1,true))
assert(details[4].right:find('unknown',1,true))
assert(details[4].text=='20 % - Lesser Magic Essence × 1–2')
for i=2,#details do assert(details[i].r==1 and details[i].g==.45 and details[i].b==.8)end
local before=#details;Atr_AddDEDetailsToTip(detailTip,'Armor',7,10);assert(#details==before)
-- Guard incomplete results even if a later data edit is malformed.
local row=data['1_2'][1];local saved=row[3];row[3]=saved+1
reset();quote(10940,100,1);quote(10938,100,1)
value,status=Atr_CalcDisenchantPrice('Weapon',2,10);assert(value==nil and status.invalidTable);row[3]=saved
-- Real tooltip and stack API preserve confidence and do not fabricate totals.
a=assert(source:find('function Atr_STWP_AddBasicDEInfo',1,true));b=assert(source:find('function Atr_ShowTipWithPricing',a,true))
assert(loadstring(source:sub(a,b-1)))()
AUCTIONATOR_D_TIPS=1;AUCTIONATOR_V_TIPS=0;AUCTIONATOR_A_TIPS=0
local tip={AddDoubleLine=function(_,label,text)lines[#lines+1]=label..' '..text end,AddLine=function(_,s)lines[#lines+1]=s end}
reset();quote(10940,100,1);quote(10938,200,1)
local _,_,stack,stackStatus=Atr_STWP_GetPrices(nil,3,true,nil,nil,'Armor',2,10)
assert(stack==540 and stackStatus.complete)
lines={};Atr_STWP_AddBasicDEInfo(tip,'',nil,{supported=true,complete=false})
assert(#lines==2 and lines[1]:find('unknown',1,true)and lines[2]:find('Missing material prices',1,true))
lines={};Atr_STWP_AddBasicDEInfo(tip,'',180,{complete=true,stale=true})
assert(lines[1]:find('old prices',1,true))
lines={};Atr_STWP_AddBasicDEInfo(tip,'',180,{complete=true,partial=true})
assert(lines[1]:find('partial scan',1,true))
AUCTIONATOR_D_TIPS=0;lines={};Atr_STWP_AddBasicDEInfo(tip,'',180,{complete=true});assert(#lines==0)
print('PASS: DE expected value, missing/invalid prices, ID-only uncached lookup, all 7 bidirectional essence pairs, precision, price confidence, '..count..' normalized probability bands, invalid-table guard, stack value and tooltip states')

print('PASS: material valuation uses saved lowest prices and never reads Market references')
