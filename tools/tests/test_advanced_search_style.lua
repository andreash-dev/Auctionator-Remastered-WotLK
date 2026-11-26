dofile('AuctionatorRemastered/Remastered/Core/Bootstrap.lua')
-- Verify presentation keeps the live search controls and their state intact.
local f=assert(io.open('AuctionatorRemastered/Remastered/UI/AuctionDialogs.lua'))
local source=f:read('*a');f:close()
local function widget(name)
 local w={points={},width=80,height=20,shown=true,scripts={},name=name}
 function w:ClearAllPoints() self.points={} end
 function w:SetPoint(...) self.points[#self.points+1]={...} end
 function w:GetPoint(i) return unpack(self.points[i]) end
 function w:GetNumPoints() return #self.points end
 function w:SetWidth(v) self.width=v end
 function w:SetHeight(v) self.height=v end
 function w:SetSize(x,y) self.width=x;self.height=y end
 function w:GetWidth() return self.width end
 function w:GetHeight() return self.height end
 function w:IsShown() return self.shown end
 function w:Hide() self.shown=false end
 function w:SetText(v) self.text=v end
 function w:GetText() return self.text end
 function w:IsObjectType(t) return self.kind==t end
 function w:GetTexture() return self.texture end
 function w:SetClampedToScreen() end
 function w:GetRegions() return unpack(self.regions or {}) end
 function w:HookScript(k,fn) self.scripts[k]=fn end
 _G[name]=w;return w
end
for name in source:gmatch('"(Atr_AS[%w_]+)"') do if not _G[name] then widget(name) end end
for _,name in ipairs({'AuctionFrame','Atr_Mask','Atr_Buy_Confirm_Frame','Atr_Adv_Search_Dialog','Atr_Adv_Search_Button',
 'Atr_Search_Button','Atr_Adv_Search_ResetBut','Atr_Adv_Search_OKBut','Atr_Adv_Search_CancelBut'}) do widget(name) end
Atr_Mask:SetSize(820,475);Atr_Mask:SetPoint('TOPLEFT',nil,'TOPLEFT',10,-116)
local header=widget('header');header.kind='Texture';header.texture='Interface\\DialogFrame\\UI-DialogBox-Header'
local title=widget('title');title.kind='FontString';title.text='Advanced Search'
Atr_Adv_Search_Dialog.regions={header,title}
local actions={}
for _,w in ipairs({Atr_Adv_Search_ResetBut,Atr_Adv_Search_OKBut,Atr_Adv_Search_CancelBut}) do
 w.scripts.OnClick=function() end;actions[w]=w.scripts.OnClick
end
Atr_AS_MinItemlevel.shown=false;Atr_AS_MaxItemlevel.shown=false
local skins=0
function Atr_AnalysisSkin() skins=skins+1;return true end
function Atr_StyleOfflineBrowser(frame) frame.styled=true end
function UIDropDownMenu_SetWidth(frame,width) frame.dropdownWidth=width end
local layoutFile=assert(io.open('AuctionatorRemastered/Remastered/UI/AuctionLayout.lua'))
local layoutSource=layoutFile:read('*a');layoutFile:close()
local place=assert(layoutSource:match('(local function place%b().-\nend)'))
local start=assert(source:find('-- Style the live advanced-search controls',1,true))
local finish=assert(source:find('AuctionatorRemastered.UI.AuctionDialogs=',start,true))
assert(loadstring(place..'\n'..source:sub(start,finish-1)))()
local checks=0
local function check(v,s) checks=checks+1;assert(v,s) end
Atr_Adv_Search_Dialog.scripts.OnShow()
check(Atr_Adv_Search_Dialog.width==520 and Atr_Adv_Search_Dialog.styled,'dialog uses shared theme and compact layout')
check(not header.shown and title.points[1][5]==-16,'old title plate removed and heading inset')
check(Atr_Mask.points[1][2]==AuctionFrame and #Atr_Mask.points==2,'mask fits live auction frame rather than fixed screen bounds')
check(skins==0,'standard UI never calls ElvUI control skins')
check(not Atr_AS_MinItemlevel.shown and not Atr_AS_MaxItemlevel.shown,'conditional item-level inputs stay hidden')
for w,action in pairs(actions) do check(w.scripts.OnClick==action,'existing search/reset/cancel handlers preserved') end
Atr_Adv_Search_Dialog.scripts.OnHide()
check(Atr_Mask.width==820 and #Atr_Mask.points==1 and Atr_Mask.points[1][4]==10,'mask geometry restored for other dialogs')
Atr_Buy_Confirm_Frame.scripts.OnShow()
check(Atr_Mask.points[1][2]==AuctionFrame and #Atr_Mask.points==2,'buy mask follows moved auction window')
Atr_Buy_Confirm_Frame.scripts.OnHide()
check(Atr_Mask.width==820 and #Atr_Mask.points==1,'buy mask restores inherited geometry after closing')
ElvUI={{}}
Atr_Adv_Search_Dialog.scripts.OnShow();local once=skins
Atr_Adv_Search_Dialog.scripts.OnShow()
check(once==11 and skins==once,'all dropdowns, inputs and actions get ElvUI skins once')
Atr_Adv_Search_Dialog.scripts.OnHide()
print('PASS: '..checks..' advanced-search theme, mask lifecycle, control state and ElvUI checks')
-- Real toolbar anchors must not retain the XML's Search -> Options dependency.
for _,name in ipairs({'Atr_Main_Panel','Atr_Search_Box','Atr_FullScanButton','Auctionator1Button'}) do widget(name) end
local toolbar=assert(source:match('(local function styleAdvancedSearchButton%b().-\nend)'))
local styleToolbar=assert(loadstring(place..'\n'..toolbar..'\nreturn styleAdvancedSearchButton'))()
local searchAction=function() end;Atr_Search_Button.scripts.OnClick=searchAction
ElvUI=nil
styleToolbar()
check(Auctionator1Button.points[1][2]==AuctionFrame,'Options anchors independently to the outer window')
for _,pair in ipairs({{Atr_FullScanButton,Auctionator1Button},{Atr_Adv_Search_Button,Atr_FullScanButton},{Atr_Search_Button,Atr_Adv_Search_Button}}) do
 check(pair[1].points[1][2]==pair[2] and pair[1].points[1][4]==-8 and pair[1].width==80,'action buttons have reserved widths and an eight-pixel gap')
end
check(Atr_Search_Box.points[2][2]==Atr_Search_Button and Atr_Search_Box.points[2][4]==-12,'input ends before Search instead of pushing buttons into Full Scan')
check(Atr_Search_Button.scripts.OnClick==searchAction and Atr_Search_Box.atrSearchSkinned==nil,'native layout preserves actions and skips ElvUI skin')
ElvUI={{}};local before=skins;styleToolbar();styleToolbar()
check(Atr_Search_Box.atrSearchSkinned and skins==before+1,'ElvUI edit-box skin applies once to the live search field')
print('PASS: Buy toolbar spacing, input bounds, actions and native/ElvUI styling')
widget('Atr_DropDownSL');widget('Atr_Hlist');Atr_Hlist:SetWidth(172)
local dropdownAction=function() end;Atr_DropDownSL.scripts.OnShow=dropdownAction
before=skins;styleToolbar();styleToolbar()
check(Atr_DropDownSL.atrSearchSkinned and skins==before+1 and Atr_DropDownSL.width==221,'Recent Searches receives ElvUI dropdown styling once and fits its sidebar')
check(Atr_DropDownSL.points[1][5]+3==Atr_Search_Box.points[1][5],'visible dropdown center matches search input center')
check(Atr_DropDownSL.scripts.OnShow==dropdownAction,'shopping-list initialization handler is preserved')
print('PASS: Recent Searches alignment, ElvUI styling and list handler')
