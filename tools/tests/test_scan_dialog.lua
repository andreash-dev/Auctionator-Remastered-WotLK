dofile("AuctionatorRemastered/Remastered/Core/Bootstrap.lua")
dofile("AuctionatorRemastered/Remastered/Integration/LegacyBridge.lua")
-- Run from the addon project root: lua5.1 tools/tests/test_scan_dialog.lua
local now,ready,canQuery,ctrl=10000,false,true,false
local queryCount,startClicks,popups=0,0,{}
local objects={}
local function widget(name)
    local w={name=name,scripts={},shown=true,enabled=true,level=1}
    function w:GetName() return self.name end
    function w:GetFrameLevel() return self.level end
    function w:GetText() return self.text end
    function w:GetTexture() return self.texture end
    function w:SetSize(width,height) self.width=width;self.height=height end
    function w:SetPoint(...) self.point={...} end
    function w:SetTexture(value) self.texture=value end
    function w:SetVertexColor(...) self.vertexColor={...} end
    function w:CreateFontString(name) return widget(name) end
    function w:CreateTexture() return widget() end
    function w:SetText(value) self.text=value end
    function w:Enable() self.enabled=true end
    function w:Disable() self.enabled=false end
    function w:Show() self.shown=true end
    function w:Hide() self.shown=false end
    function w:IsShown() return self.shown end
    function w:SetScript(event,fn) self.scripts[event]=fn end
    function w:GetScript(event) return self.scripts[event] end
    function w:HookScript(event,fn) self.scripts[event]=fn end
    function w:GetChecked() return self.checked end
    setmetatable(w,{__index=function(_,key) if key:find('^Set') or key=='ClearAllPoints' then return function() end end end})
    if name then _G[name]=w;objects[name]=w end
    return w
end
function CreateFrame(_,name)
    local w=widget(name)
    if name then widget(name..'Text') end
    return w
end
function time() return now end
function GetTime() return now end
function Atr_DatabaseBeginFullScan() end
function Atr_DatabaseCancelFullScan() end
function date() return 'date' end
function IsControlKeyDown() return ctrl end
function CanSendAuctionQuery() return canQuery,ready end
function ZT(s) return s end
function Atr_GetDBsize() return 100 end
function StaticPopup_Show(name,text) popups[#popups+1]={name,text} end
function StaticPopup_Hide() end
function SortAuctionClearSort() end
function QueryAuctionItems(...) queryCount=queryCount+1 end
function Atr_ShowFullScanFrame() end
function hooksecurefunc(name,callback)
    local original=_G[name]
    _G[name]=function(...) original(...);callback(...) end
end
for _,name in ipairs({'Atr_FullScanFrame','Atr_FullScanStartButton','Atr_FullScanNext','Atr_FullScanDone','Atr_FullScanStatus','Atr_FullScanDBsize','Atr_FullScanDBwhen','Atr_FullScanNextLabel','Atr_FullScanHTML','Atr_FullScanResults'}) do widget(name) end
for _,key in ipairs({'scanned','added','updated','ignored'}) do widget('Atr_FSR_'..key..'_text');widget('Atr_FSR_'..key..'_count') end
StaticPopupDialogs={};GameTooltip={};ATR_FS_NULL=0;ATR_FS_STARTED=1;ATR_FS_SLOW_QUERY_NEEDED=3;gAtr_FullScanState=0
local f=assert(io.open('AuctionatorRemastered/Legacy/AuctionatorScanFull.lua'));local scan=f:read('*a'):gsub('\r\n','\n');f:close()
assert(loadstring(scan))()
function RegisterDummy() end
-- The engine frame listens for close/logout; model those subscriptions here.
local create=CreateFrame
function CreateFrame(...) local w=create(...);w.RegisterEvent=function() end;return w end
assert(loadfile('AuctionatorRemastered/Remastered/Integration/FullScan.lua'))()
Atr_ShowFullScanFrame=function() end
Atr_FullScanStartButton:SetScript('OnClick',function() startClicks=startClicks+1;Atr_FullScanStart() end)
assert(loadfile('AuctionatorRemastered/Remastered/Integration/ScanControls.lua'))()
local checks=0
local function check(value,label) checks=checks+1;assert(value,label) end
AUCTIONATOR_LAST_SCAN_TIME=now-415
Atr_UpdateFullScanFrame();Atr_FullScanFrameIdle()
check(Atr_FullScanNext:GetText()=='in 08m 05s (estimated)','seconds shown')
check(Atr_FullScanStartButton.enabled,'fast scan button stays clickable for warning')
Atr_FullScanStartButton.scripts.OnClick(Atr_FullScanStartButton,'LeftButton')
check(queryCount==0 and startClicks==0 and #popups==1,'blocked click warns without starting')
check(popups[1][2]:find('08m 05s',1,true),'popup includes remaining wait')
now=now+1;Atr_FullScanFrame.scripts.OnUpdate(Atr_FullScanFrame,0.25)
check(Atr_FullScanNext:GetText()=='in 08m 04s (estimated)','live countdown')
-- Server can permit fast scans earlier than the assumed 15 minutes.
ready=true;Atr_FullScanFrame.scripts.OnUpdate(Atr_FullScanFrame,0.25)
check(Atr_FullScanStartButton.enabled and Atr_FullScanNext:GetText()=='Now','server readiness overrides estimate')
Atr_FullScanStartButton.scripts.OnClick(Atr_FullScanStartButton,'LeftButton')
check(queryCount==1 and startClicks==1 and gAtr_FullScanState==ATR_FS_STARTED,'original fast scan start invoked once')
check(not Atr_FullScanStartButton.enabled,'start remains disabled during active scan')
Atr_FullScanStartButton.scripts.OnClick(Atr_FullScanStartButton,'LeftButton')
check(queryCount==1 and startClicks==1,'active scan cannot restart')
-- Expired estimates never bypass a server-side block.
Atr_FullScanCancel();gAtr_FullScanState=0;ready=false;now=AUCTIONATOR_LAST_SCAN_TIME+901
Atr_UpdateFullScanFrame();Atr_FullScanFrameIdle()
check(Atr_FullScanNext:GetText()=='Waiting for server','expired estimate waits for server')
Atr_FullScanStartButton.scripts.OnClick(Atr_FullScanStartButton,'LeftButton')
check(queryCount==1 and popups[#popups][2]:find('server is still blocking',1,true),'expired estimate warns safely')
AUCTIONATOR_LAST_SCAN_TIME=nil;Atr_UpdateFullScanFrame()
check(Atr_FullScanNext:GetText()=='Waiting for server','unknown timer')
AUCTIONATOR_LAST_SCAN_TIME=now+100
check(Atr_GetFastScanWait()==nil,'future timestamp does not invent countdown')
-- Checkbox and Ctrl still select the original slow scan.
Atr_FullScanSlowMode=true;Atr_FullScanFrameIdle()
check(Atr_FullScanStartButton.enabled,'slow scan not blocked by fast cooldown')
Atr_FullScanStartButton.scripts.OnClick(Atr_FullScanStartButton,'LeftButton')
check(gAtr_FullScanState==ATR_FS_SLOW_QUERY_NEEDED and queryCount==1,'original slow path; no getAll query')
Atr_FullScanCancel();gAtr_FullScanState=0;Atr_FullScanSlowMode=false;ctrl=true;Atr_FullScanFrameIdle()
check(Atr_FullScanStartButton.enabled,'Ctrl selects slow path')
Atr_FullScanStartButton.scripts.OnClick(Atr_FullScanStartButton,'LeftButton')
check(gAtr_FullScanState==ATR_FS_SLOW_QUERY_NEEDED and queryCount==1,'Ctrl slow start preserved')
-- The start handler also catches stale readiness before the overlay has refreshed.
Atr_FullScanCancel();gAtr_FullScanState=0;ctrl=false
Atr_FullScanStartButton.scripts.OnClick(Atr_FullScanStartButton,'LeftButton')
check(queryCount==1 and gAtr_FullScanState==0,'stale button readiness cannot bypass guard')
local warning=StaticPopupDialogs.ATR_FAST_SCAN_COOLDOWN
check(warning.button1=='Run anyway' and warning.button2=='Cancel','explicit override and cancel labels')
local before=queryCount
if warning.OnCancel then warning.OnCancel() end
check(queryCount==before,'cancel sends no query')
Atr_FullScanStart()
check(queryCount==before,'default engine entry still respects readiness')
local timestamp=AUCTIONATOR_LAST_SCAN_TIME
warning.OnAccept()
check(queryCount==before+1 and gAtr_FullScanState==ATR_FS_STARTED,'confirmation attempts exactly one fast scan despite readiness block')
check(AUCTIONATOR_LAST_SCAN_TIME==now,'request records its cooldown estimate, even before completion')
warning.OnAccept();check(queryCount==before+1,'duplicate confirmation cannot restart active scan')
Atr_FullScanCancel();gAtr_FullScanState=0;Atr_FullScanFrame:Hide()
warning.OnAccept();check(queryCount==before+1,'closed dialog cannot run stale confirmation')
Atr_FullScanFrame:Show();ctrl=true
warning.OnAccept();check(queryCount==before+1,'confirmation does not override a changed slow mode')
ctrl=false
gAtr_ScanDB={Item={mr=10,M100=12,ms={day=100,values={10,14}}}};local original=gAtr_ScanDB.Item
local last=AUCTIONATOR_LAST_SCAN_TIME
check(Atr_ClearPriceDatabase() and not gAtr_ScanDB.Item,'clear works')
check(Atr_UndoClearPriceDatabase() and gAtr_ScanDB.Item==original and gAtr_ScanDB.Item.M100==12,'undo keeps median history')
check(AUCTIONATOR_LAST_SCAN_TIME==last,'clearing does not reset cooldown')
-- Load the actual shared appearance helpers, then verify style work cannot
-- start a scan or replace any confirmation/database action handlers.
local function read(path) local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
dofile('AuctionatorRemastered/Remastered/UI/Theme.lua')

local header,title=widget(),widget()
function header:GetObjectType() return 'Texture' end
function header:SetTexture(value) self.texture=value end
header.texture='Interface\\DialogFrame\\UI-DialogBox-Header'
function title:GetObjectType() return 'FontString' end
title:SetText('Full Scan')
function title:SetPoint(...) self.point={...} end
function Atr_FullScanNextLabel:GetObjectType() return 'FontString' end
function Atr_FullScanFrame:GetRegions() return header,title,Atr_FullScanNextLabel end
for _,surface in ipairs({Atr_FullScanFrame,Atr_FullScanResults}) do
    function surface:SetBackdrop(value) self.backdrop=value end
    function surface:SetBackdropColor(...) self.color={...} end
    function surface:GetBackdropColor() return unpack(self.color) end
end
local actionButtons={Atr_FullScanStartButton,Atr_FullScanDone,Atr_ClearDBButton,Atr_UndoClearDBButton}
local handlers={}
for i,b in ipairs(actionButtons) do handlers[i]=b:GetScript('OnClick') end
local beforeStyle=queryCount
ElvUI=nil;Atr_ShowFullScanFrame()
check(Atr_FullScanFrame.color[4]==1 and Atr_FullScanResults.color[4]==1,'standard dialog and results use opaque shared backgrounds')
check(header.texture==nil and title.point[1]=='TOP' and title.point[5]==-12,'stone header replaced with centered title')
check(Atr_FullScanFrame.width==500 and Atr_FullScanFrame.height==410,'compact modal dimensions')
check(Atr_FullScanFrame.atrSolidBackground.vertexColor[4]==1,'solid fill remains opaque')
local fill=Atr_FullScanFrame.atrSolidBackground
function fill:GetObjectType() return 'Texture' end
local originalRegions=Atr_FullScanFrame.GetRegions
function Atr_FullScanFrame:GetRegions() return header,title,Atr_FullScanNextLabel,fill end
Atr_StyleFullScanDialog()
check(fill.texture=='Interface\\Buttons\\WHITE8X8','restyling never removes the solid backdrop texture')
Atr_FullScanFrame.GetRegions=originalRegions
Atr_GetFullScanCounts=function() return 7,3 end
Atr_UpdateFullScanCounts()
check(Atr_FullScanFastCount:GetText()=='7' and Atr_FullScanSlowCount:GetText()=='3','existing saved fast and slow counts shown separately')
check(Atr_FullScanNextLabel:GetText()=='Fast scan available:','status labels remain intact')
local skins={HandleButton=function(self,b) b.styled=true end,HandleCheckBox=function(self,b) b.styled=true end}
ElvUI={{media={backdropfadecolor={.1,.12,.14,.6}},GetModule=function() return skins end}}
Atr_StyleFullScanDialog()
check(Atr_FullScanFrame.color[1]==.1 and Atr_FullScanFrame.color[4]==1,'ElvUI theme colors retained with solid dialog')
for i,b in ipairs(actionButtons) do
    check(b.styled and b:GetScript('OnClick')==handlers[i],'ElvUI buttons preserve their original action handlers')
end
check(Atr_SlowScanChoice.styled,'slow mode checkbox receives ElvUI style')
-- Reproduce the original completion presentation in its actual order: Show,
-- legacy purple color, then the final frame update. Initial styling alone fails.
Atr_FullScanHTML:Hide();Atr_FullScanResults:Show()
Atr_UpdateFullScanFrame()
check(Atr_FullScanResults.color[1]==.1 and Atr_FullScanResults.color[2]==.12 and Atr_FullScanResults.color[3]==.14 and Atr_FullScanResults.color[4]==1,'completion keeps the opaque theme instead of restoring legacy purple')
for i,key in ipairs({'scanned','added','updated','ignored'}) do
    local count=_G['Atr_FSR_'..key..'_count']
    check(count.point[1]=='TOPLEFT' and count.point[2]==Atr_FullScanResults and count.point[4]==160 and count.point[5]==-12-(i-1)*22,'result count '..key..' uses a common fixed value column')
end
check(queryCount==beforeStyle and AUCTIONATOR_LAST_SCAN_TIME==last,'styling never queries auctions or changes cooldowns')
ElvUI=nil
local opened
Atr_DatabaseStatusOptions={}
function InterfaceOptionsFrame_OpenToCategory(category) opened=category end
gAtr_FullScanState=ATR_FS_STARTED
Atr_FullScanDatabaseStatus.scripts.OnClick()
check(opened==nil,'database status navigation is blocked during an active scan')
gAtr_FullScanState=ATR_FS_NULL
Atr_FullScanDatabaseStatus.scripts.OnClick()
check(opened==Atr_DatabaseStatusOptions and not Atr_FullScanFrame:IsShown(),'status shortcut closes the idle dialog and opens the actual status category')
print('PASS: '..checks..' scan dialog style, countdown and warning checks')
