-- Exercise the real legacy addon-message handlers with isolated transports.
local f=assert(io.open('AuctionatorRemastered/Legacy/Auctionator.lua'))
local s=f:read('*a'):gsub('\r\n','\n');f:close()
local start=assert(s:find('local checkVerString',1,true))
local finish=assert(s:find('function Atr_OnChatMsgAddon (...)',start,true))
finish=assert(s:find('\nend',finish,true))+4
local sent,scheduled,notices,shared={},{},{},{}
zc={StringSame=function(a,b)return a==b end,StringStartsWith=function(a,b)return a:sub(1,#b)==b end,
 msg_anm=function(text)notices[#notices+1]=text end,AddDeferredCall=function(...)scheduled[#scheduled+1]={...}end}
zz=function()end;time=function()return 100 end
SendAddonMessage=function(...)sent[#sent+1]={...}end
Atr_OnChatMsgAddon_ShoppingListCmds=function(...)shared[#shared+1]={...}end
AuctionatorVersion='1.0.9'
assert(loadstring(s:sub(start,finish)))()
Atr_SendAddon_VREQ('GUILD')
assert(sent[1][1]=='ATR_RM' and sent[1][2]=='VREQ_1.0.9')
Atr_OnChatMsgAddon('ATR','V_3.1.5','WHISPER','Original')
Atr_OnChatMsgAddon('ATR','VREQ_3.1.5','GUILD','Original')
assert(#sent==1 and #scheduled==0,'original protocol neither compared nor answered with Remastered version')
Atr_OnChatMsgAddon('ATR_RM','VREQ_1.0.8','GUILD','Remastered')
assert(sent[2][1]=='ATR_RM' and sent[2][2]=='V_1.0.9')
for _,version in ipairs({'1.0.8','1.0.9','1.0.10-beta.1','nonsense','1.0','0.99.99'})do
 Atr_OnChatMsgAddon('ATR_RM','V_'..version,'WHISPER','Peer')
end
assert(#scheduled==0)
Atr_OnChatMsgAddon('ATR_RM','V_1.0.10','WHISPER','Peer');assert(#scheduled==1)
Atr_OnChatMsgAddon('ATR_RM','V_1.0.9','WHISPER','Peer');assert(#scheduled==1)
Atr_VersionReminder();Atr_VersionReminder()
assert(#notices==1 and notices[1]:find('Auctionator Remastered: 1.0.10',1,true))
Atr_OnChatMsgAddon('ATR','SREQ_test','WHISPER','Original')
assert(shared[#shared][1]=='ATR' and shared[#shared][2]=='SREQ_test','legacy list messages still forwarded unchanged')
print('PASS: isolated original/Remastered version channels, numeric comparison, invalid values, one reminder and unchanged shopping-list forwarding')
