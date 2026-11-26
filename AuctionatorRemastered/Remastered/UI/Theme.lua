-- Shared Browse-style presentation. Both panels retain their own data/actions.
function Atr_AnalysisSkin(control, kind)
    if not AuctionatorRemastered.UI.UseElvUI() then return false end
    local engine = type(ElvUI)=='table' and ElvUI[1]
    if not engine or type(engine.GetModule)~='function' then return false end
    local ok, skins = pcall(engine.GetModule,engine,'Skins',true)
    local method = ok and skins and skins['Handle'..kind]
    if type(method)=='function' then return pcall(method,skins,control) end
    return false
end
-- Native-only palette; ElvUI keeps its existing backdrops and colours.
function Atr_NativeSurface(frame,role,alpha)
    if AuctionatorRemastered.UI.UseElvUI() then return false end
    local colors={shell={.075,.070,.065},body={.105,.100,.090},
        sidebar={.135,.125,.110},heading={.17,.155,.13},tab={.16,.145,.12}}
    local color=colors[role] or colors.body
    frame:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',
        edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=2,
        insets={left=2,right=2,top=2,bottom=2}})
    frame:SetBackdropColor(color[1],color[2],color[3],alpha or 1)
    -- Native analysis surfaces can acquire their first backdrop on tab OnShow,
    -- after the deferred AH discovery pass. Register them when styled too.
    local register=AuctionatorRemastered.UI.RegisterAuctionBackground
    if register then register(frame) end
    if frame.SetBackdropBorderColor then frame:SetBackdropBorderColor(.30,.28,.24,1) end
    return true
end
function Atr_AnalysisBackdrop(frame, alpha,role)
    if Atr_NativeSurface(frame,role,alpha) then return end
    frame:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',tile=false,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
    frame:SetBackdropColor(.025,.025,.025,alpha or 1)
    if frame.SetBackdropBorderColor then frame:SetBackdropBorderColor(.18,.18,.18,1) end
end
function Atr_StyleEmptyMessage(label,content)
    if not label or not content then return end
    label:ClearAllPoints()
    label:SetPoint("TOPLEFT",content,"TOPLEFT",16,-16)
    label:SetPoint("BOTTOMRIGHT",content,"BOTTOMRIGHT",-16,16)
    label:SetJustifyH("CENTER");label:SetJustifyV("MIDDLE")
    label:SetTextColor(1,.5,.25)
end

-- Put arrows and track in a dedicated gutter, outside the content border.
-- FauxScrollFrame retains all range, offset and visibility handling.
function Atr_StyleAnalysisScroll(scroll,content)
    local name=scroll:GetName()
    local bar=scroll.ScrollBar or (name and _G[name.."ScrollBar"])
    if not bar then return end
    Atr_AnalysisSkin(bar,"ScrollBar")
    bar:ClearAllPoints();bar:SetWidth(18)
    bar:SetPoint("TOPLEFT",content,"TOPRIGHT",3,-19)
    bar:SetPoint("BOTTOMLEFT",content,"BOTTOMRIGHT",3,19)
    local barName=bar:GetName()
    local up=barName and (_G[barName.."ScrollUpButton"] or _G[barName.."UpButton"])
    local down=barName and (_G[barName.."ScrollDownButton"] or _G[barName.."DownButton"])
    if up then
        up:ClearAllPoints();up:SetSize(18,18);up:SetPoint("BOTTOM",bar,"TOP",0,1)
    end
    if down then
        down:ClearAllPoints();down:SetSize(18,18);down:SetPoint("TOP",bar,"BOTTOM",0,-1)
    end
end

-- Fit to the visible ElvUI shell, whose left/bottom insets differ from the
-- original AuctionFrame. All inner list margins then share one coordinate space.
function Atr_AnalysisFit(panel)
    local skinned=AuctionatorRemastered.UI.UseElvUI() and AuctionFrameBrowse and AuctionFrameBrowse.RightBackground and AuctionFrame.backdrop
    local base=skinned or AuctionFrame
    local inset=0
    if AuctionFrameTab1 then
        local bottom,top=base:GetBottom(),AuctionFrameTab1:GetTop()
        if bottom and top then
            local scale=base:GetEffectiveScale()
            -- Native tab artwork has transparent padding above its visible rim.
            -- Cover that seam without changing the already aligned ElvUI edge.
            local overlap=skinned and 1 or 4
            inset=(top*AuctionFrameTab1:GetEffectiveScale()-bottom*scale-overlap)/panel:GetEffectiveScale()
        end
    end
    panel:ClearAllPoints()
    panel:SetPoint('TOPLEFT',base,'TOPLEFT',0,0)
    panel:SetPoint('BOTTOMRIGHT',base,'BOTTOMRIGHT',0,inset)
end
function Atr_AnalysisBegin(panel)
    local hidden,seen={},{}
    local function hide(region)
        if region and not seen[region] then
            seen[region]=true;hidden[#hidden+1]={region=region,shown=region:IsShown()};region:Hide()
        end
    end
    local skinned=AuctionatorRemastered.UI.UseElvUI() and AuctionFrameBrowse and AuctionFrameBrowse.RightBackground and AuctionFrame.backdrop
    if skinned then panel:SetBackdrop(nil)
    else
        -- The vanilla atlas includes a permanent left divider and money recess.
        -- Replace that artwork only while an analysis tab is open.
        for _,region in ipairs({AuctionFrame:GetRegions()}) do
            if region:IsObjectType('Texture') then hide(region) end
        end
        for _,suffix in ipairs({'TopLeft','BotLeft','Top','TopRight','Bot','BotRight'}) do hide(_G['AuctionFrame'..suffix]) end
        Atr_AnalysisBackdrop(panel,1,"shell")
        -- Reuse the real AH close action, above all three stock overlay panels.
        local close=AuctionFrameCloseButton
        if close then
            local saved={region=close,level=close:GetFrameLevel(),shown=close:IsShown(),points={}}
            for i=1,close:GetNumPoints() do saved.points[i]={close:GetPoint(i)} end
            hidden[#hidden+1]=saved
            close:ClearAllPoints();close:SetPoint('TOPRIGHT',panel,'TOPRIGHT',-2,-2)
            close:SetFrameLevel(math.max(close:GetFrameLevel(),panel:GetFrameLevel()+5))
            close:Show()
        end
    end
    hide(AuctionFrameTitleText)
    hide(AuctionPortraitTexture);hide(AuctionFramePortrait);hide(AuctionFramePortraitTexture)
    -- Selected vanilla tabs project slightly above the normal tabs. Let their
    -- artwork overlap the panel edge rather than covering it with the backdrop.
    for i=1,(AuctionFrame.numTabs or 0) do
        local tab=_G['AuctionFrameTab'..i]
        if tab then
            hidden[#hidden+1]={region=tab,level=tab:GetFrameLevel()}
            tab:SetFrameLevel(math.max(tab:GetFrameLevel(),panel:GetFrameLevel()+1))
        end
    end
    return hidden
end
function Atr_AnalysisEnd(hidden)
    for _,saved in ipairs(hidden or {}) do
        if saved.points then
            saved.region:ClearAllPoints()
            for _,point in ipairs(saved.points) do saved.region:SetPoint(unpack(point)) end
        end
        if saved.level then saved.region:SetFrameLevel(saved.level) end
        if saved.shown~=nil then
            if saved.shown then saved.region:Show() else saved.region:Hide() end
        end
    end
end

-- Use the same live shell/result colors as Logs, including before the first
-- AH visit when only ElvUI's theme colors are available.
function Atr_StyleOfflineBrowser(frame,body,transparent)
    if Atr_NativeSurface(frame,body and "body" or "shell",transparent and .8 or 1) then return end
    local source=body and AuctionFrameBrowse and AuctionFrameBrowse.RightBackground or (AuctionFrame and AuctionFrame.backdrop)
    local r,g,b,alpha=.025,.025,.025,1
    if source and source.GetBackdrop and source:GetBackdrop() then
        frame:SetBackdrop(source:GetBackdrop());r,g,b,alpha=source:GetBackdropColor()
        if source.GetBackdropBorderColor then frame:SetBackdropBorderColor(source:GetBackdropBorderColor()) end
    else
        Atr_AnalysisBackdrop(frame,1)
        local engine=AuctionatorRemastered.UI.UseElvUI() and ElvUI[1]
        local color=engine and engine.media and engine.media.backdropfadecolor
        if type(color)=="table" and color[1] then r,g,b,alpha=color[1],color[2],color[3],color[4] or .8 end
    end
    -- Change only the background opacity, never the text, icons or controls.
    if transparent~=nil then alpha=transparent and .8 or 1 end
    frame:SetBackdropColor(r,g,b,alpha)
end
-- Keep native AH tabs at their inactive height: the selected template otherwise
-- projects through the bottom border. Indicate selection with its blue highlight.
local function styleNativeAuctionTabs(frame)
    if frame~=AuctionFrame or AuctionatorRemastered.UI.UseElvUI() then return end
    local selected=PanelTemplates_GetSelectedTab(frame)
    for i=1,(frame.numTabs or 0) do
        local tab=_G["AuctionFrameTab"..i]
        if tab then
            if i==selected then
                PanelTemplates_DeselectTab(tab)
                tab:LockHighlight()
            else
                tab:UnlockHighlight()
            end
        end
    end
end
hooksecurefunc("PanelTemplates_UpdateTabs",styleNativeAuctionTabs)

-- One AH background preference shared by Standard and ElvUI. Never fade whole
-- frames: text, item icons, buttons and borders retain their own opacity.
do
 local UI=AuctionatorRemastered.UI
 local surfaces=setmetatable({},{__mode='k'})
 local artwork=setmetatable({},{__mode='k'})
 local applying=false
 -- Original 3.3.5 returns nominal alpha=1 as about .999997803. Treat that
 -- readback as opaque, not a skin-selected transparent level to preserve.
 local function translucent(alpha) return type(alpha)=='number' and alpha<1-.0001 end
 local function preference()
  local settings=AUCTIONATOR_BROWSER_SETTINGS
  if type(settings)=='table' then return settings.auctionTransparent end
  return nil
 end
 local function backdrop(frame)
  return frame and frame.GetBackdrop and frame:GetBackdrop()
 end
 local function apply(frame,state)
  local enabled=preference()
  local data=backdrop(frame)
  if type(enabled)~='boolean' or not data or not data.bgFile then return end
  applying=true
  frame:SetBackdropColor(state.r,state.g,state.b,enabled and state.transparent or 1)
  applying=false
 end
 local function register(frame)
  if not frame or not frame.GetBackdropColor or not frame.SetBackdropColor then return end
  local data=backdrop(frame)
  if not data or not data.bgFile then return end
  local state=surfaces[frame]
  if not state then
   local r,g,b,a=frame:GetBackdropColor()
   if type(a)~='number' or a<=0 then return end
   -- .8 is the existing shared transparent-surface value, not a new slider.
   -- Preserve a skin's actual alpha whenever it already supplies transparency.
   state={r=r,g=g,b=b,original=a,transparent=translucent(a) and a or .8}
   surfaces[frame]=state
   if hooksecurefunc then hooksecurefunc(frame,'SetBackdropColor',function(_,red,green,blue,alpha)
    if applying then return end
    state.r,state.g,state.b=red,green,blue
    if type(alpha)=='number' and alpha>0 and translucent(alpha) then state.transparent=alpha end
    apply(frame,state)
   end) end
  end
  apply(frame,state)
 end
 function UI.RegisterAuctionBackground(frame)
  if not AuctionFrame then return end
  local parent=frame
  local seen={}
  while parent and not seen[parent] do
   if parent==AuctionFrame then register(frame);return end
   seen[parent]=true
   parent=parent.GetParent and parent:GetParent()
  end
 end
 function UI.AuctionDefaultTransparent()
  local main=AuctionFrame and (AuctionFrame.backdrop or AuctionFrame)
  local state=main and surfaces[main]
  if state then return translucent(state.original) end
  if main and main.GetBackdropColor and backdrop(main) then
   local _,_,_,alpha=main:GetBackdropColor()
   if type(alpha)=='number' and alpha>0 then return translucent(alpha) end
  end
  return UI.UseElvUI()
 end
 function UI.RefreshAuctionBackgrounds()
  if not AuctionFrame then return end
  local seen={}
  local function walk(frame,insideControl)
   if seen[frame] then return end;seen[frame]=true
   local kind=frame.GetObjectType and frame:GetObjectType()
   local control=insideControl or (kind and kind~='Frame' and kind~='ScrollFrame')
   if not control then register(frame) end
   if frame.GetChildren then for _,child in ipairs({frame:GetChildren()})do walk(child,control) end end
  end
  walk(AuctionFrame,false)
  -- Stock atlas pieces do not have a backdrop; adjust only these known pieces,
  -- never the portrait, item icons or other regions on the window.
  for _,suffix in ipairs({'TopLeft','BotLeft','Top','TopRight','Bot','BotRight'})do
   local texture=_G['AuctionFrame'..suffix]
   if texture and texture.GetAlpha and texture.SetAlpha then
    if not artwork[texture]then
     local alpha=texture:GetAlpha();artwork[texture]={transparent=translucent(alpha) and alpha or .8}
    end
    local enabled=preference()
    if type(enabled)=='boolean' then texture:SetAlpha(enabled and artwork[texture].transparent or 1) end
   end
  end
 end
end
