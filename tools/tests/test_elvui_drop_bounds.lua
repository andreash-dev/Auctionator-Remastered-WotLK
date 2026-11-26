dofile("AuctionatorRemastered/Remastered/Core/Bootstrap.lua")
dofile("AuctionatorRemastered/Remastered/Integration/LegacyBridge.lua")
-- Geometry regression: the original empty-Sell update restores 805x341 after
-- skinning, even when no tab or per-item visibility changed.
local hooks,pending={},nil
function hooksecurefunc(name,callback) hooks[name]=callback end
local function widget(width,height,left,right,scale)
    local frame={width=width,height=height,left=left,right=right,scale=scale or 1,shown=true}
    function frame:ClearAllPoints() self.points={} end
    function frame:SetPoint(...) self.points=self.points or {};self.points[#self.points+1]={...} end
    function frame:SetWidth(value) self.width=value end
    function frame:SetHeight(value) self.height=value end
    function frame:GetWidth() return self.width end
    function frame:GetHeight() return self.height end
    function frame:GetLeft() return self.left end
    function frame:GetRight() return self.right end
    function frame:GetEffectiveScale() return self.scale end
    function frame:Show() self.shown=true end
    function frame:Hide() self.shown=false end
    function frame:IsShown() return self.shown end
    function frame:RegisterEvent() end
    function frame:SetScript(event,callback) self[event]=callback end
    return frame
end
function CreateFrame() pending=widget();return pending end
AuctionFrame=widget(832,447,0,832)
Atr_Main_Panel=widget(412,424,210,622)
Atr_Hlist=widget(172,252)
Atr_Hlist.SetTemplate=function() end
Atr_Hilite1=widget(805,341)
Atr_Hilite1_btn=widget(805,341)
function Atr_IsTabSelected() return false end
ElvUI={}
dofile('AuctionatorRemastered/Remastered/UI/AuctionLayout.lua')
dofile('AuctionatorRemastered/Remastered/UI/AuctionDialogs.lua')
dofile('AuctionatorRemastered/Remastered/UI/AuctionLayout.lua')
dofile('AuctionatorRemastered/Remastered/UI/AuctionDialogs.lua')
dofile('AuctionatorRemastered/Remastered/Integration/ElvUI.lua')
dofile('AuctionatorRemastered/Remastered/Integration/AuctionUI.lua')
dofile('AuctionatorRemastered/Remastered/Integration/AuctionUI.lua')
local n=0
local function check(ok,msg) n=n+1;assert(ok,msg) end
hooks.Atr_UpdateUI()
check(Atr_Hilite1.width==601 and Atr_Hilite1.height==300,'expanded outline fits the visible outer window')
check(Atr_Hilite1_btn.width==601 and Atr_Hilite1_btn.height==300,'clickable drop target matches outline')
check(Atr_Hilite1.points[1][2]==Atr_Main_Panel and Atr_Hilite1_btn.points[1][2]==Atr_Hilite1,'outline and drop target share the same anchored bounds')
for i=1,5 do
    Atr_Hilite1:SetWidth(805);Atr_Hilite1:SetHeight(341)
    Atr_Hilite1_btn:SetWidth(805);Atr_Hilite1_btn:SetHeight(341)
    hooks.Atr_UpdateUI()
    check(Atr_Hilite1.width==601 and Atr_Hilite1_btn.width==601,'ordinary update cannot re-expand empty Sell target '..i)
end
Atr_Hilite1:SetHeight(116);hooks.Atr_UpdateUI()
check(Atr_Hilite1.height==116 and Atr_Hilite1_btn.height==116,'compact target for a selected item is retained')
AuctionFrame.right=900;hooks.Atr_UpdateUI()
check(Atr_Hilite1.width==669,'target follows visible outer width rather than fixed panel width')
AuctionFrame.scale=1;Atr_Main_Panel.scale=.8;Atr_Hilite1.scale=.8;AuctionFrame.right=832
hooks.Atr_UpdateUI()
check(math.abs(Atr_Hilite1.width-809)<.001,'effective scales accounted for when bounding the target')
ElvUI=nil;Atr_Hilite1.width=805;Atr_Hilite1_btn.width=805;hooks.Atr_UpdateUI()
check(Atr_Hilite1.width==805 and Atr_Hilite1_btn.width==805,'vanilla layout is untouched')
ElvUI={};Atr_Main_Panel.shown=false;hooks.Atr_UpdateUI()
check(Atr_Hilite1.width==805,'hidden Auctionator panel is untouched')
-- The live-button fallback must work even when the legacy addon skin stopped
-- before reaching Sell/Undercuts, without changing action behavior or geometry.
local names={"Atr_FullScanButton","Auctionator1Button","AuctionatorCloseButton","Atr_CancelSelectionButton","Atr_Buy1_Button","Atr_Search_Button","Atr_Adv_Search_Button","Atr_Back_Button","Atr_AddToSListButton","Atr_RemFromSListButton","Atr_SrchSListButton","Atr_MngSListsButton","Atr_NewSListButton","Atr_SaveThisList_Button","Atr_CreateAuctionButton","Atr_CheckActiveButton"}
local clicks=0
for _,name in ipairs(names) do
    local b=widget(90,22);b.text=name;b.enabled=false
    b.OnClick=function() clicks=clicks+1 end
    b:SetPoint("TOPLEFT",Atr_Main_Panel,"TOPLEFT",12,-34)
    _G[name]=b
end
ElvUI=nil;pending.OnUpdate(pending)
check(not Atr_CheckActiveButton.skinCalls,'standard UI buttons remain native')
local skins={HandleButton=function(self,b) b.skinCalls=(b.skinCalls or 0)+1;b.isSkinned=true end}
ElvUI={{GetModule=function(self,name) assert(name=="Skins");return skins end}}
pending.OnUpdate(pending)
for _,name in ipairs(names) do
    local b=_G[name]
    check(b.skinCalls==1 and b.text==name and not b.enabled,'skin preserves text and disabled state: '..name)
    check(b.width==90 and b.height==22 and b.points[1][4]==12 and b.points[1][5]==-34,'skin preserves button bounds: '..name)
    b.OnClick()
end
check(clicks==#names,'all existing click handlers survive skinning')
pending.OnUpdate(pending)
check(Atr_CheckActiveButton.skinCalls==1,'repeated tab/show updates do not add duplicate skins')
ElvUI={{GetModule=function() error("missing module") end}}
check(pcall(pending.OnUpdate,pending),'missing ElvUI skin module is harmless')
print('PASS: '..n..' ElvUI button skin and drop-target compatibility checks')
