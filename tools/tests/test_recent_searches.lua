-- Exercise the real list rendering and pane search entry point together.
local checks=0
local function check(value,message)checks=checks+1;assert(value,message)end
local current,offset,starts,draws=nil,0,0,0
StaticPopupDialogs={}
local zc={md=function()end,StringSame=function(a,b)return a and b and a:lower()==b:lower()end}
function Atr_GetCurrentPane()return current end
function ZT(s)return s end
function UIDropDownMenu_SetSelectedValue()end
function UIDropDownMenu_SetText()end
function Atr_ClearBuyState()end
function Atr_ClearAll()end
function Atr_ClearHistory()end
function Atr_FindScan()return nil end
function Atr_SetUINeedsUpdate()end
function Atr_IsShoppingListSearch()return false end
function Atr_AbbrevItemName(s)return s end
function Atr_GetShoppingListFromSearchText()return nil end
local function widget()
 return {SetText=function(s,t)s.text=t end,GetText=function(s)return s.text end,ClearFocus=function()end,
 SetID=function(s,id)s.id=id end,GetID=function(s)return s.id end,
 SetTextColor=function()end,SetButtonState=function(s,state)s.state=state end,
 Show=function(s)s.shown=true end,Hide=function(s)s.shown=false end,Enable=function()end,Disable=function()end}
end
for _,name in ipairs({'Atr_Search_Box','Atr_Search_Button','Atr_Adv_Search_Button','Atr_Buy1_Button',
 'Atr_AddToSListButton','Atr_RemFromSListButton','Atr_DropDownSL'})do _G[name]=widget()end
for i=1,15 do _G['AuctionatorHEntry'..i]=widget();_G['AuctionatorHEntry'..i..'_EntryText']=widget()end
Atr_Hlist_ScrollFrame={SetVerticalScroll=function(_,value)offset=value/16 end}
function FauxScrollFrame_SetOffset(_,value)offset=value end
function FauxScrollFrame_GetOffset()return offset end
function FauxScrollFrame_Update()draws=draws+1 end
function Atr_NewSearch(text)
 return {origSearchText=text or '',searchText=text or '',Start=function()starts=starts+1 end}
end
assert(loadfile('AuctionatorRemastered/Legacy/AuctionatorShop.lua'))('AuctionatorRemastered',{zc=zc})
assert(loadfile('AuctionatorRemastered/Legacy/AuctionatorPane.lua'))('AuctionatorRemastered',{zc=zc})
gShopPane=AtrPane.create();current=gShopPane
local recent=setmetatable({isRecents=true,name='Recent Searches',items={}},Atr_SList)
local custom=setmetatable({name='Cloth',items={'Linen Cloth','Wool Cloth'}},Atr_SList)
AUCTIONATOR_SHOPPING_LISTS={recent,custom};Atr_ShpList_SetToRecents()
for i=1,50 do recent.items[i]='Item '..i end
recent.items[3]='Linen Cloth';recent.items[20]='linen cloth'
offset=25;current.hlistScrollOffset=25
Atr_Search_Box:SetText('Linen Cloth');Atr_Search_Onclick()
check(recent.items[1]=='Linen Cloth','a visible existing item moves to first')
local duplicates=0;for _,item in ipairs(recent.items)do if zc.StringSame(item,'Linen Cloth')then duplicates=duplicates+1 end end
check(duplicates==1,'old case-variant duplicates removed')
check(offset==0 and current.hlistScrollOffset==0,'both scroll offsets reset at search start')
check(AuctionatorHEntry1.state=='PUSHED' and AuctionatorHEntry1_EntryText.text=='Linen Cloth','first row painted and highlighted before scan completes')
check(starts==1,'UI update starts no extra searches')
offset=8;current.activeScan={sortedData={}}
Atr_Shop_OnFinishScan()
check(offset==8,'scan completion preserves manual scroll')
current:DoSearch('Wool Cloth')
check(recent.items[1]=='Wool Cloth' and offset==0 and AuctionatorHEntry1.state=='PUSHED','direct/API search path uses same immediate history update')
current:DoSearch('Linen Cloth')
check(recent.items[1]=='Linen Cloth' and recent.items[2]=='Wool Cloth','repeat searches always follow most-recent order')
for i=1,55 do Atr_AddToRecents('Fresh '..i)end
check(#recent.items==50 and recent.items[1]=='Fresh 55' and recent.items[50]=='Fresh 6','history capped at newest 50')
local top=recent.items[1];Atr_AddToRecents('   ');Atr_AddToRecents(nil);current:ClearSearch()
check(recent.items[1]==top and #recent.items==50,'blank/clear searches never enter history')
Atr_DropDownSL_OnClick({owner=Atr_DropDownSL,value=2});offset=4
local original=table.concat(custom.items,'|');current:DoSearch('Wool Cloth')
check(offset==4 and table.concat(custom.items,'|')==original,'custom list and its scroll are preserved')
check(recent.items[1]=='Wool Cloth','search still recorded while a custom list is shown')
local other=AtrPane.create();other:DoSearch('Sell item')
check(recent.items[1]=='Wool Cloth','other panes do not change Buy history')
check(QueryAuctionItems==nil and PlaceAuctionBid==nil,'history repaint performs no auction actions')
print('PASS: '..checks..' recent-search ordering, immediate highlight, scroll, completion, duplicate and pane-isolation checks')
