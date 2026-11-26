-- Local calendar dates and scoped, non-destructive ledger filters.
time=os.time;date=os.date
function GetRealmName() return 'Realm' end
function UnitFactionGroup() return 'Alliance' end
dofile('AuctionatorRemastered/Remastered/Models/TradingLogs.lua')
local start,finish,err=Atr_ParseTradingLogDate('2026-11-20')
assert(start and finish>start and not err)
assert(date('%Y-%m-%d %H:%M:%S',start)=='2026-11-20 00:00:00')
assert(date('%Y-%m-%d %H:%M:%S',finish)=='2026-11-21 00:00:00')
for _,bad in ipairs({'2026-02-30','2025-02-29','2026-13-01','2026-00-01','2026-01-00','2026-1-01','oops'}) do
 local a,b,errorText=Atr_ParseTradingLogDate(bad);assert(not a and not b and errorText,bad)
end
assert(Atr_ParseTradingLogDate('2024-02-29'),'leap day')
assert(Atr_ParseTradingLogDate('')==nil,'empty date is unbounded')
local dst,nextDay=Atr_ParseTradingLogDate('2026-03-29')
assert(date('%Y-%m-%d',nextDay)=='2026-03-30','calendar end includes DST transition')
local function row(when,character,price,size) return {name='Iron Ore',when=when,character=character,stackPrice=price,stackSize=size} end
local purchases={row(start-1,'A',10,1),row(start,'A',20,2),row(finish-1,'B',30,3),row(finish,'C',40,4)}
local postings={row(start+100,'B',50,5)}
AUCTIONATOR_PURCHASES={Realm_Alliance={records=purchases},Other_Alliance={records={row(start,'OtherRealm',1,1)}}}
AUCTIONATOR_OWN_AUCTIONS={Realm_Alliance={records=postings}}
local names=Atr_GetTradingLogCharacters()
assert(table.concat(names,',')=='A,B,C','characters are distinct and realm/faction scoped')
local records,spent,listed,bought,offered=Atr_GetTradingLogs('All','iron',nil,{A=true,B=true},start,finish)
assert(#records==3 and spent==50 and listed==50 and bought==5 and offered==5,'inclusive end date, multi-character filter and filtered totals')
assert(#Atr_GetTradingLogs('Bought','',nil,{A=true,B=true},start,finish)==2,'activity intersects custom dates and characters')
assert(#Atr_GetTradingLogs('All','',nil,{})==0,'empty selection means no characters')
assert(#Atr_GetTradingLogs('All','',nil,'A')==2,'old single-character API still works')
assert(#Atr_GetTradingLogs('All','missing',nil,nil,start,finish)==0,'name filter intersects dates')
assert(#Atr_GetTradingLogs('All','',nil,nil,nil,finish)==4,'open-ended From')
assert(#Atr_GetTradingLogs('All','',nil,nil,start,nil)==4,'open-ended To')
assert(#purchases==4 and purchases[1].when==start-1 and purchases[4].when==finish,'filtering does not mutate saved ledgers')
print('PASS: calendar validation, inclusive dates, DST, multi-character/scoped filtering, totals and read-only ledgers')
