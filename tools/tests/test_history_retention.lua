dofile('AuctionatorRemastered/Remastered/Core/Bootstrap.lua')
function hooksecurefunc() end
StaticPopupDialogs={}
local popup,saves,errors=nil,0,0
function StaticPopup_Hide()
    if popup then StaticPopupDialogs.ATR_CONFIRM_HISTORY_RETENTION.OnCancel();popup=nil end
end
function StaticPopup_Show(id,old,days,data)
    popup={id=id,old=old,days=days,data=data}
    return popup
end
UIErrorsFrame={AddMessage=function() errors=errors+1 end}
Atr_ScanOpts_MaxHistAge={text='30'}
function Atr_ScanOpts_MaxHistAge:GetText() return self.text end
function Atr_ScanOpts_MaxHistAge:GetNumber() return tonumber(self.text) or 0 end
function Atr_ScanOpts_MaxHistAge:SetText(value) self.text=tostring(value) end
Atr_ScanningOptionsFrame={atr_hasBeenShown=true,GetName=function() return 'Atr_ScanningOptionsFrame' end,HookScript=function() end}
function Atr_ScanningOptionsFrame_Save()
    saves=saves+1
    AUCTIONATOR_DB_MAXHIST_DAYS=Atr_ScanOpts_MaxHistAge:GetNumber()
end
Atr_ScanningOptionsFrame.okay=Atr_ScanningOptionsFrame_Save
AUCTIONATOR_DB_MAXHIST_DAYS=30
dofile('AuctionatorRemastered/Remastered/UI/Options.lua')
local function save(value)
    Atr_ScanOpts_MaxHistAge:SetText(value)
    Atr_ScanningOptionsFrame.okay(Atr_ScanningOptionsFrame)
end
save(14)
assert(saves==1 and AUCTIONATOR_DB_MAXHIST_DAYS==30 and popup.days==14 and popup.old==30,'lower limit remains unsaved while awaiting confirmation')
assert(StaticPopupDialogs[popup.id].hideOnEscape and StaticPopupDialogs[popup.id].timeout==0,'Escape cancels and confirmation cannot expire into acceptance')
StaticPopup_Hide()
assert(AUCTIONATOR_DB_MAXHIST_DAYS==30 and Atr_ScanOpts_MaxHistAge:GetText()=='30','cancel preserves and displays old value')
save(14)
local dialog=popup;popup=nil
StaticPopupDialogs[dialog.id].OnAccept(dialog,dialog.data)
assert(AUCTIONATOR_DB_MAXHIST_DAYS==14 and Atr_ScanOpts_MaxHistAge:GetText()=='14','explicit confirmation saves the lower limit')
save(30)
assert(not popup and AUCTIONATOR_DB_MAXHIST_DAYS==30,'increasing retention is immediate and needs no confirmation')
save(30);assert(not popup,'unchanged limit needs no confirmation')
local before=saves
for _,value in ipairs({'',0,-1,'1.5',3651,'bad'}) do save(value) end
assert(saves==before and errors==6 and AUCTIONATOR_DB_MAXHIST_DAYS==30,'invalid input cannot lower the cleanup limit')
save(10);dialog=popup;popup=nil
AUCTIONATOR_DB_MAXHIST_DAYS=60
StaticPopupDialogs[dialog.id].OnAccept(dialog)
assert(AUCTIONATOR_DB_MAXHIST_DAYS==60,'stale confirmation cannot overwrite a newer setting')
Atr_ScanningOptionsFrame.atr_hasBeenShown=false
before=saves;save(5)
assert(saves==before and not popup,'unvisited page does not save or prompt')
print('PASS: retention confirmation, cancel/Escape, bounds, safe increases, stale dialogs and settings callback')
