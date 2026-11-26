-- Exercise the inherited rendering loop with the smaller Remastered viewport.
local file=assert(io.open('AuctionatorRemastered/Legacy/AuctionatorConfig.lua'))
local source=file:read('*a'):gsub('\r\n','\n');file:close()
local display=assert(source:match('(function Atr_StackingList_Display%b().-\nend)'))
local prefix=[[local kStackList_LinesToDisplay=12
local kStackList_categories={}
local zc={EnableDisable=function() end}
local function plistEntry(key,text,numstacks,stacksize) return {sortkey=key,text=text,numstacks=numstacks,stacksize=stacksize} end
local function plistSort(a,b) return a.sortkey<b.sortkey end
]]
assert(loadstring(prefix..display))()
function ZT(text) return text end
local function widget()
 return {SetID=function(self,v) self.id=v end,SetText=function(self,v) self.text=v end,
 SetButtonState=function() end,Show=function(self) self.shown=true end,Hide=function(self) self.shown=false end}
end
for i=1,12 do
 _G['Atr_StackList'..i]=widget();_G['Atr_StackList'..i..'_text']=widget();_G['Atr_StackList'..i..'_info']=widget()
end
AUCTIONATOR_STACKING_PREFS={}
for i=1,15 do AUCTIONATOR_STACKING_PREFS[string.format('Item %02d',i)]={numstacks=1,stacksize=5} end
Atr_StackingVisibleRows=9;gStackList_SelectedIndex=0
local offset,total,visible,step=0
function FauxScrollFrame_Update(_,a,b,c) total,visible,step=a,b,c end
function FauxScrollFrame_GetOffset() return offset end
Atr_StackingList_Display()
assert(total==15 and visible==9 and step==16,'scroll range uses nine visible rows and the existing scroll step')
assert(Atr_StackList9.shown and not Atr_StackList10.shown and not Atr_StackList12.shown,'extra row frames are hidden outside the viewport')
offset=6;Atr_StackingList_Display()
assert(Atr_StackList1.id==7 and Atr_StackList9.id==15 and Atr_StackList9_text.text=='Item 15','scrolling reaches the last preference with correct selection IDs')
print('PASS: smaller stack viewport, hidden overflow rows, scroll range and last-item access')
