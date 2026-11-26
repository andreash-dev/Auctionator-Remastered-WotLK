-- Actual defaults and legacy first-open dropdown handlers, with no saved profile.
local function read(path)local f=assert(io.open(path));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local main=read('AuctionatorRemastered/Legacy/Auctionator.lua')
for _,key in ipairs({'V_TIPS','A_TIPS','D_TIPS','SHIFT_TIPS','DE_DETAILS_TIPS'}) do
 assert(loadstring(assert(main:match('(AUCTIONATOR_'..key..'%s*=%s*[^;]+;)'))))()
end
local config=read('AuctionatorRemastered/Legacy/AuctionatorConfig.lua')
local function definition(name)return assert(config:match('(function '..name..'%s*%b().-\nend)'))end
zc={NumToBool=function(v)return v==1 end};ZT=function(s)return s end
local function choice()return {SetChecked=function(self,v)self.checked=v end}end
ATR_tipsVendorOpt_CB=choice();ATR_tipsAuctionOpt_CB=choice();ATR_tipsDisenchantOpt_CB=choice()
function UIDropDownMenu_Initialize(self,fn)fn(self)end
function UIDropDownMenu_SetSelectedValue(self,value)self.selected=value end
function UIDropDownMenu_SetText(self,text)self.text=text end
function UIDropDownMenu_JustifyText()end
function UIDropDownMenu_SetWidth()end
function Atr_Dropdown_AddPick(self,text,value)self.choices[value]=text end
for _,name in ipairs({'Atr_SetupTooltipsOptionsFrame','Atr_tipsShiftDD_Initialize','Atr_deDetailsDD_Initialize','Atr_Opt_TipsShift_OnShow','Atr_Opt_deDetails_OnShow'})do assert(loadstring(definition(name)))()end
Atr_SetupTooltipsOptionsFrame()
assert(ATR_tipsVendorOpt_CB.checked and ATR_tipsAuctionOpt_CB.checked and ATR_tipsDisenchantOpt_CB.checked)
local shift,de={choices={}},{choices={}}
Atr_Opt_TipsShift_OnShow(shift);Atr_Opt_deDetails_OnShow(de)
assert(shift.selected==1 and shift.text=='stack price')
assert(de.selected==1 and de.text=='when SHIFT is held down')
-- Existing users keep their own display choices and get matching captions.
AUCTIONATOR_SHIFT_TIPS=2;AUCTIONATOR_DE_DETAILS_TIPS=4
Atr_Opt_TipsShift_OnShow(shift);Atr_Opt_deDetails_OnShow(de)
assert(shift.text=='per item price' and de.text=='never')
dofile('AuctionatorRemastered/Remastered/Core/Bootstrap.lua')
assert(AuctionatorRemastered.UI.ProspectingDetailsMode()=='shift')
AUCTIONATOR_SAVEDVARS={prospectingDetails='always',prospectingTips=false}
assert(AuctionatorRemastered.UI.ProspectingDetailsMode()=='always')
print('PASS: Tooltips cold-start defaults, first-open captions and existing user detail choices')
