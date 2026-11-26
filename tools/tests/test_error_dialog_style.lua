-- Execute the actual error-dialog presentation with both theme choices. Existing
-- frame scripts own mask cleanup and acknowledgement; styling cannot replace them.
local f=assert(io.open('AuctionatorRemastered/Remastered/UI/AuctionDialogs.lua'))
local source=f:read('*a');f:close()
local start=assert(source:find('function Atr_StyleErrorDialog()',1,true))
local function widget()
 local w={scripts={}}
 function w:ClearAllPoints()self.points={}end
 function w:SetPoint(...)self.points={...}end
 function w:SetWidth(v)self.width=v end
 function w:SetHeight(v)self.height=v end
 function w:SetSize(x,y)self.width=x;self.height=y end
 function w:SetClampedToScreen()end
 function w:SetFontObject()end
 function w:SetJustifyH()end
 function w:SetJustifyV()end
 function w:SetWordWrap(v)self.wrap=v end
 function w:GetStringHeight()return self.measured or 40 end
 function w:GetChildren()return self.button end
 function w:IsObjectType(t)return t=='Button'end
 function w:IsShown()return self.shown end
 function w:HookScript(event,fn) self.hooks=self.hooks or {};self.hooks[event]=fn end
 return w
end
UIParent=widget();AuctionFrame=widget();AuctionFrame.shown=true
Atr_Error_Frame=widget();Atr_Error_Text=widget();local button=widget();Atr_Error_Frame.button=button
local acknowledge=function()end;button.scripts.OnClick=acknowledge
local show,hide=function()end,function()end
Atr_Error_Frame.scripts.OnShow=show;Atr_Error_Frame.scripts.OnHide=hide
local elv=false
function Atr_StyleOfflineBrowser(frame,body,transparent)frame.theme=elv and 'elvui' or 'native';assert(not body and not transparent)end
function Atr_AnalysisSkin(control,kind)assert(control==button and kind=='Button');return elv end
assert(loadstring(source:sub(start)))()
for _,mode in ipairs({false,true}) do
 elv=mode;Atr_Error_Frame.hooks.OnShow()
 assert(Atr_Error_Frame.theme==(mode and 'elvui' or 'native'))
 assert(Atr_Error_Frame.points[2]==AuctionFrame and Atr_Error_Frame.width==440)
 assert(button.width==110 and button.scripts.OnClick==acknowledge)
 assert(Atr_Error_Frame.scripts.OnShow==show and Atr_Error_Frame.scripts.OnHide==hide)
end
Atr_Error_Text.measured=240;AuctionFrame.shown=false;Atr_Error_Frame.hooks.OnShow()
assert(Atr_Error_Frame.height==322 and Atr_Error_Text.height==240 and Atr_Error_Text.wrap)
assert(Atr_Error_Frame.points[2]==UIParent)
print('PASS: error popup theme, long-message bounds, AH/UIParent centering and preserved mask/button handlers')
