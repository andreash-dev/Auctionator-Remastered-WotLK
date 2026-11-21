-- Exercise the actual placement code and its stock/skin/tab gates.
local f=assert(io.open('AuctionatorRemastered/Remastered/Integration/ElvUI.lua'))
local source=f:read('*a');f:close()
local function definition(name)
 return assert(source:match('(local function '..name..'%b().-\nend)'),name)
end
local layout=assert(loadstring(definition('place')..'\n'..definition('fixNativeSellLayout')..'\nreturn fixNativeSellLayout'))()
local moves=0
local function frame()
 return {IsShown=function() return true end,
 ClearAllPoints=function(self) self.points={} end,
 SetPoint=function(self,...) self.points={...};moves=moves+1 end,
 SetWidth=function(self,value) self.width=value end,
 SetHeight=function(self,value) self.height=value end,
 SetJustifyH=function(self,value) self.justify=value end}
end
Atr_Main_Panel=frame();Atr_SellControls=frame();AuctionFrame={};AuctionFrameBrowse={}
for _,name in ipairs({'Atr_StackPriceText','Atr_StackPrice','Atr_ItemPriceText','Atr_ItemPrice',
 'Atr_ItemsOwned_Text','Atr_Batch_Stacksize_Text','Atr_Batch_NumAuctions','Atr_Batch_Stacksize',
 'Atr_Batch_MaxAuctions_Text','Atr_Batch_MaxStacksize_Text','Atr_CreateAuctionButton'}) do _G[name]=frame() end
local selected=1
function Atr_IsTabSelected(tab) return tab==selected end
local checks=0
local function check(value,label) checks=checks+1;assert(value,label) end
layout()
check(moves>0 and Atr_CreateAuctionButton.points[5]==-214,'Sell pane ID 1 receives stock placement')
check(Atr_Batch_NumAuctions.points[5]==-176 and Atr_Batch_MaxAuctions_Text.points[5]==-198,'stack fields and max labels placed above Create Auction')
local before=moves;selected=3;layout();check(moves==before,'Buy placement remains unchanged')
selected=2;layout();check(moves==before,'Undercuts placement remains unchanged')
selected=1;ElvUI={};layout();check(moves>before,'loaded ElvUI without AH skin still permits stock placement')
before=moves;AuctionFrame.backdrop={};AuctionFrameBrowse.RightBackground={};layout()
check(moves==before,'active ElvUI auction skin prevents all native changes')
ElvUI=nil;AuctionFrame.backdrop=nil;AuctionFrameBrowse.RightBackground=nil
Atr_SellControls.IsShown=function() return false end
layout();check(moves==before,'hidden Sell controls are untouched')
print('PASS: '..checks..' native Sell tab, geometry, loaded-vs-active ElvUI and hidden-pane checks')
