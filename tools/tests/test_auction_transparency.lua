local function boot()dofile('AuctionatorRemastered/Remastered/Core/Bootstrap.lua')end
AUCTIONATOR_REMASTERED_THEME='native';AUCTIONATOR_BROWSER_SETTINGS=nil;ElvUI=nil
boot();local UI=AuctionatorRemastered.UI
function hooksecurefunc(frame,name,callback)
 if type(frame)~='table' then return end
 local original=frame[name];frame[name]=function(self,...)local results={original(self,...)};callback(self,...);return unpack(results)end
end
dofile('AuctionatorRemastered/Remastered/UI/Theme.lua')
local function frame(kind,alpha,children)
 return {kind=kind or 'Frame',alpha=alpha,color={.1,.2,.3,alpha},children=children or {},
 GetObjectType=function(self)return self.kind end,
 GetChildren=function(self)return unpack(self.children)end,
 GetBackdrop=function()return {bgFile='background'}end,
 GetBackdropColor=function(self)return unpack(self.color)end,
 SetBackdropColor=function(self,r,g,b,a)self.color={r,g,b,a or 1}end,
 SetAlpha=function()error('Do not fade entire frames')end}
end
local buttonBackdrop=frame('Frame',.6)
local button=frame('Button',1,{buttonBackdrop})
local body=frame('Frame',.8)
AuctionFrame=frame('Frame',1,{body,button})
local icon={alpha=1};AuctionPortraitTexture=icon
AuctionFrameTopLeft={alpha=1,GetAlpha=function(self)return self.alpha end,SetAlpha=function(self,a)self.alpha=a end}
UI.RefreshAuctionBackgrounds()
assert(AuctionFrame.color[4]==1 and body.color[4]==.8,'No preference must preserve current native/skin appearance')
assert(not UI.BackgroundTransparent('auction'))
assert(UI.SetBackgroundTransparent('auction',true))
assert(AuctionFrame.color[4]==.8 and body.color[4]==.8 and AuctionFrameTopLeft.alpha==.8)
assert(button.color[4]==1 and buttonBackdrop.color[4]==.6 and icon.alpha==1)
UI.SetBackgroundTransparent('auction',false)
assert(AuctionFrame.color[4]==1 and body.color[4]==1 and AuctionFrameTopLeft.alpha==1)
body:SetBackdropColor(.3,.4,.5,.8)
assert(body.color[4]==1 and body.color[1]==.3,'Tab/skin reapplication must honor opaque preference without replacing RGB')
UI.SetBackgroundTransparent('auction',true);assert(body.color[4]==.8)
-- Native panels initially have no backdrop and gain it only on first OnShow.
-- Style-time registration must work without another global discovery pass.
UI.themeMode='native'
local logs=frame('Frame',1)
logs.parent=AuctionFrame
logs.GetParent=function(self)return self.parent end
logs.SetBackdrop=function(self,data)self.backdrop=data end
logs.GetBackdrop=function(self)return self.backdrop end
assert(not logs:GetBackdrop())
UI.SetBackgroundTransparent('auction',true)
Atr_NativeSurface(logs,'shell',1)
assert(logs.color[4]==.8,'Late native Logs/Deals shell must register while styled')
local results=frame('Frame',1)
results.parent=logs;results.GetParent=logs.GetParent
results.SetBackdrop=logs.SetBackdrop;results.GetBackdrop=logs.GetBackdrop
Atr_NativeSurface(results,'body',1)
assert(results.color[4]==.8,'Nested native result surface obeys saved transparency immediately')
UI.SetBackgroundTransparent('auction',false)
Atr_NativeSurface(logs,'shell',1);Atr_NativeSurface(results,'body',1)
assert(logs.color[4]==1 and results.color[4]==1)
UI.SetBackgroundTransparent('auction',true)
Atr_NativeSurface(logs,'shell',1);Atr_NativeSurface(results,'body',1)
assert(logs.color[4]==.8 and results.color[4]==.8,'Native tab restyling must retain the shared option')
local outside=frame('Frame',1);outside.SetBackdrop=logs.SetBackdrop;outside.GetParent=function()return nil end
Atr_NativeSurface(outside,'body',1)
assert(outside.color[4]==1,'Offline/native settings surfaces must not inherit the AH setting')
-- Actual original-client readback from the user's Logs panel: opaque alpha
-- is .99999780301005, not exactly 1. It must not become the stored "on" level.
local nativeAlpha=.99999780301005
local quantized=frame('Frame',nativeAlpha)
AuctionFrame.children[#AuctionFrame.children+1]=quantized
UI.SetBackgroundTransparent('auction',true)
assert(quantized.color[4]==.8,'Quantized opaque native alpha must use existing transparent alpha')
quantized:SetBackdropColor(.074509640224278,.070588080212474,.06666652020067,nativeAlpha)
assert(quantized.color[4]==.8,'Restyling with quantized opaque readback must not replace transparent alpha')
UI.SetBackgroundTransparent('auction',false);assert(quantized.color[4]==1)
UI.SetBackgroundTransparent('auction',true);assert(quantized.color[4]==.8)
local original=AuctionFrame
AuctionFrame=frame('Frame',nativeAlpha)
AUCTIONATOR_BROWSER_SETTINGS.auctionTransparent=nil
UI.RefreshAuctionBackgrounds()
assert(not UI.AuctionDefaultTransparent(),'Default checkbox must not label quantized opaque backgrounds transparent')
assert(AuctionFrame.color[4]==nativeAlpha,'Unset preference must still leave the original readback unchanged')
AuctionFrame=original
UI.SetBackgroundTransparent('auction',true)
-- The very same persisted boolean applies to ElvUI, preserving its original alpha.
ElvUI={{}};UI.themeMode='automatic'
AuctionFrame=frame('Frame',1)
AuctionFrame.backdrop=frame('Frame',.63)
AuctionFrame.children={AuctionFrame.backdrop}
UI.RefreshAuctionBackgrounds();assert(AuctionFrame.backdrop.color[4]==.63)
UI.SetBackgroundTransparent('auction',false);assert(AuctionFrame.backdrop.color[4]==1)
UI.SetBackgroundTransparent('auction',true);assert(AuctionFrame.backdrop.color[4]==.63)
local late=frame('Frame',.47);AuctionFrame.children[#AuctionFrame.children+1]=late
UI.SetBackgroundTransparent('auction',false);assert(late.color[4]==1)
UI.SetBackgroundTransparent('auction',true);assert(late.color[4]==.47)
assert(AUCTIONATOR_BROWSER_SETTINGS.auctionTransparent==true)
local beforeBrowser,beforeShopping=UI.BackgroundTransparent('browser'),UI.BackgroundTransparent('shopping')
local refresh=UI.RefreshAuctionBackgrounds;local count=0;UI.RefreshAuctionBackgrounds=function()count=count+1;refresh()end
UI.SetBackgroundTransparent('auction',false)
assert(count==1 and UI.BackgroundTransparent('browser')==beforeBrowser and UI.BackgroundTransparent('shopping')==beforeShopping)
-- Persist through namespace/bootstrap reinitialization and an unopened auction UI.
AuctionFrame=nil;boot();assert(not UI.BackgroundTransparent('auction'))
UI.SetBackgroundTransparent('auction',true);assert(UI.BackgroundTransparent('auction'))
-- One option, not separate native/ElvUI keys or controls.
local f=assert(io.open('AuctionatorRemastered/Remastered/UI/Appearance.lua'));local source=f:read('*a');f:close()
assert(source:find("{'auction','Auction house'}",1,true)and source:find('Atr_AppearanceAuctionTransparent',1,true))
print('PASS: shared native/ElvUI AH toggle, untouched initial opacity, original skin alpha restoration, opaque enforcement after restyle, late frames, background-only rendering, stock art, independent other preferences and persistence')
