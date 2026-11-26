local checks=0
local function check(v,label) checks=checks+1;assert(v,label) end
local function boot() dofile('AuctionatorRemastered/Remastered/Core/Bootstrap.lua') end
AUCTIONATOR_REMASTERED_THEME=nil;ElvUI=nil;boot()
local UI=AuctionatorRemastered.UI
check(not UI.UseElvUI() and UI.RequestedTheme()=='native','without ElvUI the native theme is selected')
check(not UI.SetThemePreference('elvui') and AUCTIONATOR_REMASTERED_THEME==nil,'ElvUI cannot be enabled when absent')
local skins={HandleButton=function() end}
local engine={GetModule=function() return skins end}
ElvUI={engine};boot()
check(UI.HasElvUI() and UI.UseElvUI(),'existing ElvUI users retain automatic integration')
check(UI.SetThemePreference('native') and UI.UseElvUI(),'saving native mode does not partially restyle the current session')
boot()
check(not UI.UseElvUI() and UI.RequestedTheme()=='native','native override is applied on next load')
function hooksecurefunc() end
dofile('AuctionatorRemastered/Remastered/UI/Theme.lua')
local frame={SetBackdrop=function(self,v) self.backdrop=v end,SetBackdropColor=function(self,...) self.color={...} end,SetBackdropBorderColor=function() end}
check(Atr_NativeSurface(frame,'shell') and frame.color[1]==.075,'native palette wins even with ElvUI loaded')
check(not Atr_AnalysisSkin({},'Button'),'native mode never calls ElvUI widget skins')
check(UI.SetThemePreference('elvui') and not UI.UseElvUI(),'switching back also waits for reload')
boot()
check(UI.UseElvUI() and Atr_AnalysisSkin({},'Button'),'ElvUI integration resumes after loading the saved choice')
AUCTIONATOR_BROWSER_SETTINGS=nil
check(UI.BackgroundTransparent('browser') and not UI.BackgroundTransparent('shopping'),'existing independent opacity defaults are preserved')
local browser,shopping=0,0
UI.RefreshBrowserBackgrounds=function() browser=browser+1 end
UI.RefreshShoppingBackgrounds=function() shopping=shopping+1 end
UI.SetBackgroundTransparent('browser',false)
check(not UI.BackgroundTransparent('browser') and browser==1 and shopping==0,'browser changes refresh only browser surfaces')
UI.SetBackgroundTransparent('shopping',true)
check(UI.BackgroundTransparent('shopping') and browser==1 and shopping==1,'planner opacity is independent and refreshes immediately')
UI.RefreshBrowserBackgrounds=nil;UI.SetBackgroundTransparent('browser',true)
check(shopping==1,'an unopened browser does not refresh the planner instead')
check(not UI.SetThemePreference('invalid') and not UI.SetBackgroundTransparent('invalid',true),'unknown choices are rejected')
-- The explicit native mode suppresses only the AH skin, not other ElvUI skins.
UI.themeMode='native'
local calls,removed=0,{}
local fired={}
engine.callbacks={Fire=function(_,event) fired[#fired+1]=event;return 'dispatched' end}
local auction={Skin_Blizzard_AuctionUI=true,OtherAH=true,CallPriority={'OtherAH','Skin_Blizzard_AuctionUI'}}
skins.addonCallbacks={Blizzard_AuctionUI=auction}
function skins:AddCallbackForAddon() calls=calls+1;return 'allowed' end
function engine.UnregisterCallback() error('the callback target cannot unregister itself') end
function CreateFrame() return {RegisterEvent=function() end,SetScript=function() end} end
local f=assert(io.open('AuctionatorRemastered/Remastered/Integration/ElvUI.lua'));local source=f:read('*a');f:close()
local guard=source:sub(1,assert(source:find('-- Compatibility geometry',1,true))-1)
assert(loadstring(guard))()
check(not auction.Skin_Blizzard_AuctionUI and auction.OtherAH and #auction.CallPriority==1,'only the registered AH skin callback is removed')
skins:AddCallbackForAddon('Blizzard_AuctionUI','Skin_Blizzard_AuctionUI')
check(calls==0,'native mode rejects later AH skin registrations')
check(engine.callbacks:Fire('Skin_Blizzard_AuctionUI')==nil and #fired==0,'AH dispatch is blocked even after ElvUI clears its registration flags')
check(engine.callbacks:Fire('Auctionator')==nil and #fired==0,'old Auctionator skin dispatch is blocked independently of registration')
check(engine.callbacks:Fire('Skin_Mail')=='dispatched' and fired[1]=='Skin_Mail','unrelated callback dispatch remains intact')
check(skins:AddCallbackForAddon('Blizzard_AuctionUI','OtherAH')=='allowed' and skins:AddCallbackForAddon('Blizzard_MailUI','Skin_Mail')=='allowed' and calls==2,'other AH hooks and other ElvUI windows are preserved')
UI.themeMode='automatic'
check(skins:AddCallbackForAddon('Blizzard_AuctionUI','Skin_Blizzard_AuctionUI')=='allowed','automatic mode permits the original AH skin')
check(engine.callbacks:Fire('Skin_Blizzard_AuctionUI')=='dispatched','ElvUI mode permits AH skin dispatch')
print('PASS: '..checks..' theme availability, reload, opacity and ElvUI callback isolation checks')

-- Approved release defaults with no saved appearance overrides or open AH.
AUCTIONATOR_BROWSER_SETTINGS=nil;AUCTIONATOR_SAVEDVARS=nil;AuctionFrame=nil
AUCTIONATOR_REMASTERED_THEME=nil;ElvUI=nil;boot()
check(UI.RequestedTheme()=='native' and not UI.BackgroundTransparent('auction') and not UI.BackgroundTransparent('browser') and not UI.BackgroundTransparent('shopping'),'stock first-load appearance matches approved defaults')
ElvUI={engine};boot()
check(UI.RequestedTheme()=='elvui' and UI.BackgroundTransparent('auction') and UI.BackgroundTransparent('browser') and not UI.BackgroundTransparent('shopping'),'ElvUI first-load appearance matches approved defaults')
AUCTIONATOR_REMASTERED_THEME='native';boot()
check(not UI.BackgroundTransparent('browser'),'native override keeps the stock default even when ElvUI is loaded')
AUCTIONATOR_BROWSER_SETTINGS={browserTransparent=true,auctionTransparent=true,shoppingTransparent=true}
check(UI.BackgroundTransparent('browser') and UI.BackgroundTransparent('auction') and UI.BackgroundTransparent('shopping'),'saved native opacity choices are retained')
AUCTIONATOR_REMASTERED_THEME='elvui';boot()
AUCTIONATOR_BROWSER_SETTINGS={browserTransparent=false,auctionTransparent=false,shoppingTransparent=false}
check(not UI.BackgroundTransparent('browser') and not UI.BackgroundTransparent('auction') and not UI.BackgroundTransparent('shopping'),'saved ElvUI opacity choices are retained')
print('PASS: approved native/ElvUI release appearance defaults and explicit saved overrides')
