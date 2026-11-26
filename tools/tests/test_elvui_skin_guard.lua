dofile("AuctionatorRemastered/Remastered/Core/Bootstrap.lua")
dofile("AuctionatorRemastered/Remastered/Integration/LegacyBridge.lua")
-- Exercise both load orders without running the rest of the layout module.
local f=assert(io.open('AuctionatorRemastered/Remastered/Integration/ElvUI.lua'));local s=f:read('*a');f:close()
local guard=s:sub(1,assert(s:find('-- Compatibility geometry',1,true))-1)
local event,originalCalls,removed= nil,0,0
function CreateFrame() return {RegisterEvent=function() end,SetScript=function(_,_,fn) event=fn end} end
local callbacks={Auctionator=true,Other=true,CallPriority={'Other','Auctionator'}}
local skins={addonCallbacks={Auctionator=callbacks}}
function skins:AddCallbackForAddon(addon,name,fn,force)
 originalCalls=originalCalls+1
 if force then fn() end
 return 'passed through'
end
local original=skins.AddCallbackForAddon
local engine={GetModule=function() return skins end,UnregisterCallback=function() error('the callback target cannot unregister itself') end}
ElvUI={engine}
assert(loadstring(guard))()
assert(removed==0 and not callbacks.Auctionator and callbacks.Other and #callbacks.CallPriority==1)
assert(skins:AddCallbackForAddon('Auctionator','Auctionator',function() error('legacy callback ran') end,true)==nil)
assert(originalCalls==0)
assert(skins:AddCallbackForAddon('Blizzard_AuctionUI','Skin_Blizzard_AuctionUI',function() end,true)=='passed through')
assert(skins:AddCallbackForAddon('Auctionator','Other')=='passed through')
assert(originalCalls==2)
local wrapped=skins.AddCallbackForAddon;event();assert(skins.AddCallbackForAddon==wrapped and removed==0)
ElvUI=nil;assert(loadstring(guard))()
skins.AddCallbackForAddon=original;skins.atrRemasteredSkinGuard=nil
ElvUI={engine};event()
skins:AddCallbackForAddon('Auctionator','Auctionator',function() error('late callback ran') end,true)
assert(originalCalls==2)
print('PASS: legacy skin blocked before/after registration; Blizzard and other callbacks preserved; late ElvUI load and repeat events safe')
