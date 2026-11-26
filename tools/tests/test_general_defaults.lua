-- Check actual cold-start assignments and real General setup against release choices.
local function read(path)local f=assert(io.open(path));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local main=read('AuctionatorRemastered/Legacy/Auctionator.lua')
for _,key in ipairs({'ENABLE_ALT','OPEN_ALL_BAGS','SHOW_ST_PRICE','DEF_DURATION','DEFTAB'}) do
 local assignment=assert(main:match('(AUCTIONATOR_'..key..'%s*=%s*[^;]+;)'))
 assert(loadstring(assignment))()
end
local source=read('AuctionatorRemastered/Legacy/AuctionatorConfig.lua')
local function definition(name)return assert(source:match('(function '..name..'%s*%b().-\nend)'))end
local function widget()return {SetChecked=function(self,v)self.checked=v end,Hide=function()end,SetText=function(self,v)self.text=v end}end
zc={NumToBool=function(v)return v==1 end,StringEndsWith=function(s,last)return s:sub(-#last)==last end}
ZT=function(s)return s end;UnitName=function()return 'New character'end
for _,name in ipairs({'AuctionatorOption_Enable_Alt_CB','AuctionatorOption_Open_All_Bags_CB','AuctionatorOption_Show_StartingPrice_CB','Atr_RB_S','Atr_RB_M','Atr_RB_L','Atr_BasicOptionsFrame_BTitle'})do _G[name]=widget()end
function UIDropDownMenu_Initialize(self,fn)fn(self)end
function UIDropDownMenu_SetSelectedValue(self,value)self.selected=value end
function UIDropDownMenu_SetText(self,text)self.text=text end
function UIDropDownMenu_JustifyText()end
function Atr_Dropdown_AddPick(self,text,value)self.choices[value]=text end
assert(loadstring(definition('Atr_SetDurationOptionRB')..'\n'..definition('Atr_SetupBasicOptionsFrame')..'\n'..definition('Atr_Opt_Deftab_Initialize')..'\n'..definition('Atr_Opt_Deftab_OnShow')))()
Atr_SetupBasicOptionsFrame()
assert(AuctionatorOption_Enable_Alt_CB.checked and AuctionatorOption_Open_All_Bags_CB.checked)
assert(not AuctionatorOption_Show_StartingPrice_CB.checked)
assert(Atr_RB_S.checked and not Atr_RB_M.checked and not Atr_RB_L.checked)
local dropdown={choices={}};Atr_Opt_Deftab_OnShow(dropdown)
assert(AUCTIONATOR_DEFTAB==0 and dropdown.selected==0 and dropdown.text=='None')
-- Reopening respects the existing user's choice, including a stale/blank caption.
AUCTIONATOR_DEFTAB=2;dropdown.text='';Atr_Opt_Deftab_OnShow(dropdown)
assert(dropdown.selected==2 and dropdown.text=='Buy')
AUCTIONATOR_ENABLE_ALT=0;AUCTIONATOR_OPEN_ALL_BAGS=0;AUCTIONATOR_SHOW_ST_PRICE=1;AUCTIONATOR_DEF_DURATION='L'
Atr_SetupBasicOptionsFrame()
assert(not AuctionatorOption_Enable_Alt_CB.checked and not AuctionatorOption_Open_All_Bags_CB.checked and AuctionatorOption_Show_StartingPrice_CB.checked)
assert(Atr_RB_L.checked and not Atr_RB_S.checked)
dofile('AuctionatorRemastered/Remastered/Core/Bootstrap.lua')
assert(AuctionatorRemastered.UI.ScanNotification('message') and not AuctionatorRemastered.UI.ScanNotification('sound'))
local market=read('AuctionatorRemastered/Remastered/Integration/MarketPercent.lua')
assert(loadstring(assert(market:match('(local function browseConfig%b().-\nend)'))..'\n'..assert(market:match('(function Atr_BrowseMarketColumnEnabled%b().-end)'))))()
assert(Atr_BrowseMarketColumnEnabled())
AUCTIONATOR_SAVEDVARS={browseMarketPercent=false,scanCompleteMessage=false,scanCompleteSound=true}
assert(not Atr_BrowseMarketColumnEnabled() and not AuctionatorRemastered.UI.ScanNotification('message') and AuctionatorRemastered.UI.ScanNotification('sound'))
print('PASS: all eight General release defaults, first-open field values, dropdown caption and existing user choices')
