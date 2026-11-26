-- Load every Remastered file in its actual TOC order. Unlike isolated tests,
-- this catches local values accidentally stranded across module boundaries.
local frames,hooks,dropdowns,categories={},{},{},{}
local function noop() end
local function widget(name,parent)
 local w={name=name,parent=parent,scripts={},events={},points={},shown=false,text='',width=832,height=447,level=1}
 if name then _G[name]=w end;frames[#frames+1]=w
 function w:GetName() return self.name end
 function w:SetScript(k,fn) self.scripts[k]=fn end
 function w:GetScript(k) return self.scripts[k] end
 function w:HookScript(k,fn) local old=self.scripts[k];self.scripts[k]=function(...) if old then old(...) end;fn(...) end end
 function w:RegisterEvent(event) self.events[event]=true end
 function w:IsShown() return self.shown end
 function w:Hide() self.shown=false end
 function w:Show() self.shown=true end
 function w:GetFrameLevel() return self.level end
 function w:SetFrameLevel(n) self.level=n end
 function w:SetText(v) self.text=v end
 function w:GetText() return self.text end
 function w:SetPoint(...) self.points[#self.points+1]={...} end
 function w:GetPoint(i) return unpack(self.points[i]) end
 function w:GetNumPoints() return #self.points end
 function w:ClearAllPoints() self.points={} end
 function w:GetWidth() return self.width end
 function w:GetHeight() return self.height end
 function w:GetEffectiveScale() return 1 end
 function w:GetLeft() return 0 end
 function w:GetRight() return self.width end
 function w:GetTop() return 600 end
 function w:GetBottom() return 150 end
 function w:GetRegions() return end
 function w:SetSize(x,y) self.width=x;self.height=y end
 function w:GetChecked() return self.checked end
 function w:SetChecked(v) self.checked=v end
 function w:CreateFontString(n) return widget(n,self) end
 function w:CreateTexture(n) return widget(n,self) end
 function w:GetFontString() self.font=self.font or widget(nil,self);return self.font end
 setmetatable(w,{__index=function(_,key)
  if key:match('^Set') or key:match('^Register') or key:match('^Enable') or key:match('^Disable') or key=='ClearFocus' or key=='Raise' then return noop end
 end})
 return w
end
function CreateFrame(kind,name,parent,template)
 local w=widget(name,parent)
 if kind=='CheckButton' and name then widget(name..'Text',w) end
 return w
end
function hooksecurefunc(name,fn)
 hooks[name]=hooks[name] or {};table.insert(hooks[name],fn)
end
function UIDropDownMenu_Initialize(w,fn) dropdowns[#dropdowns+1]=fn end
function UIDropDownMenu_CreateInfo() return {} end
local choices={}
function UIDropDownMenu_AddButton(info) choices[#choices+1]=info.value end
UIDropDownMenu_SetWidth=noop;UIDropDownMenu_SetSelectedValue=noop;UIDropDownMenu_JustifyText=noop
function InterfaceOptions_AddCategory(w) categories[#categories+1]=w.name end
function PanelTemplates_SetNumTabs(w,n) w.numTabs=n end
function PanelTemplates_TabResize(w) w.width=#(w.text or "")*7+32 end
PanelTemplates_EnableTab=noop
function GetRealmName() return 'Realm' end
function UnitFactionGroup() return 'Alliance' end
function UnitName() return 'Tester' end
function GetItemInfo() end
function IsShiftKeyDown() return false end
function GetTime() return 100 end
function time() return 100 end
function Atr_GetScanDay_Today() return 100 end
function CanSendAuctionQuery() return true,true end
function Atr_IsTabSelected() return false end
function Atr_GetCurrentPane() end
function date() return 'date' end
function Atr_GetNumAuctionItems() return 0,0,0 end
StaticPopupDialogs={};SlashCmdList={};UISpecialFrames={}
UIParent=widget('UIParent')
GameTooltip=widget('GameTooltip')
gAtrZC={priceToMoneyString=tostring}
AUCTIONATOR_SAVEDVARS={};AUCTIONATOR_SHOPPING_LISTS={};gAtr_ScanDB={};gAtr_FullScanState=0;ATR_FS_NULL=0
AuctionFrame=widget('AuctionFrame');AuctionFrame.numTabs=6
for i=1,6 do widget('AuctionFrameTab'..i) end
for _,name in ipairs({'Atr_FullScanFrame','Atr_FullScanStartButton','Atr_FullScanResults','Atr_ScanningOptionsFrame','Atr_BasicOptionsFrame','Atr_Buy_Confirm_Frame','Atr_Main_Panel','AuctionFrameMoneyFrame','Atr_DealsDetailsReset'}) do widget(name) end
local loaded={}
for line in io.lines('AuctionatorRemastered/AuctionatorRemastered.toc') do
 local path=line:gsub('\r',''):gsub('\\','/')
 if path:match('^Remastered/') then
  assert(loadfile('AuctionatorRemastered/'..path))();loaded[#loaded+1]=path
 end
end
-- Login must register offline settings without opening/loading the AH.
for _,frame in ipairs(frames) do
 if frame.events.PLAYER_LOGIN and frame.scripts.OnEvent then frame.scripts.OnEvent(frame,'PLAYER_LOGIN') end
end
assert(Atr_OfflineBrowserOptions and Atr_OfflineBrowserOptions.name=='Offline Browser')
-- Exercise deferred dropdown construction: the window list must cross files.
for _,fn in ipairs(dropdowns) do fn() end
assert(table.concat(choices,',')=='3,5,7,14,30','market window choices survive the module split')
-- Legacy initialization is still responsible for creating our analysis tabs.
for _,fn in ipairs(hooks.Atr_Init or {}) do fn() end
assert(AuctionFrame.numTabs==8 and AuctionFrameTab7.text=='Deals' and AuctionFrameTab8.text=='Logs')
assert(Atr_GetFullScanCounts()==0)
assert(type(Atr_ToggleOfflineBrowser)=='function' and type(Atr_ShowPriceChart)=='function')
assert(type(Atr_BrowserRememberAuctionPage)=='function' and type(Atr_InsertBrowserSearchLink)=='function')
print('PASS: '..#loaded..' modules load in TOC order, dropdown state crosses modules, original initialization creates both tabs')
