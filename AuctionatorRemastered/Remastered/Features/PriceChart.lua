-- Historical chart only: reads the same saved daily lows as the browser.
function Atr_BuildPriceChartData(itemName, days)
    local today = Atr_GetScanDay_Today()
    local first = today - days + 1
    local points, prices, daily = {}, {}, {}
    local entries = Atr_GetBrowserHistory(itemName)
    for _, entry in ipairs(entries) do
        if type(entry.low) == "number" and entry.low > 0 then daily[entry.day] = entry.low end
    end
    for _, entry in ipairs(entries) do
        if entry.day >= first and entry.day <= today and type(entry.low) == "number" and entry.low > 0 then
            local previous = daily[entry.day - 1]
            points[#points + 1] = {day = entry.day, price = entry.low, previous = previous,
                change = previous and (entry.low / previous - 1) * 100 or nil}
            prices[#prices + 1] = entry.low
        end
    end
    table.sort(points, function(a,b) return a.day < b.day end)
    table.sort(prices)
    local n, median = #prices, nil
    if n > 0 then
        local middle = math.floor((n + 1) / 2)
        median = n % 2 == 1 and prices[middle] or (prices[middle] + prices[middle + 1]) / 2
    end
    return {points=points, first=first, last=today, low=prices[1], high=prices[n], median=median, count=n}
end

local chart, plot, title, latestText, coverage, lowText, highText, medianText, message, changeText
local dates, ylabels, grid, segments, dots, rangeButtons = {}, {}, {}, {}, {}, {}
local itemName, latestPrice, range = nil, nil, 14
local itemKey
local WIDTH, HEIGHT = 636, 240
local function money(value)
    return value and gAtrZC.priceToMoneyString(math.floor(value + 0.5)) or "--"
end
local function changePercent(value)
    if value == nil then return "|cff999999--|r" end
    if math.abs(value) < 0.05 then return "|cffffdd550.0%|r" end
    local color = value < 0 and "55dd55" or "ff5555"
    return "|cff"..color..string.format(value > 0 and "+%.1f%%" or "%.1f%%",value).."|r"
end
local function dayDate(day) return date("%b %d",gScanHistDayZero + day * 86400) end
local function rectangle(parent, color)
    local t=parent:CreateTexture(nil,"ARTWORK")
    t:SetTexture(color[1],color[2],color[3],color[4] or 1)
    return t
end
local usedSegments
local function line(x1,y1,x2,y2)
    -- 3.3.5 has no modern CreateLine API. Pool short solid-texture strokes.
    local dx,dy=x2-x1,y2-y1
    local steps=math.max(1,math.ceil(math.max(math.abs(dx),math.abs(dy))/3))
    for step=0,steps-1 do
        usedSegments=usedSegments+1
        local t=segments[usedSegments]
        if not t then t=rectangle(plot,{0.25,0.8,1});segments[usedSegments]=t end
        t:ClearAllPoints()
        t:SetPoint("CENTER",plot,"BOTTOMLEFT",x1+dx*(step+0.5)/steps,y1+dy*(step+0.5)/steps)
        t:SetSize(math.max(2,math.abs(dx)/steps+1),math.max(2,math.abs(dy)/steps+1))
        t:Show()
    end
end
local function draw()
    if not itemName then return end
    local data=Atr_BuildPriceChartData(itemKey or itemName,range)
    title:SetText(itemName.." - Price history")
    local current=type(gAtr_ScanDB)=="table" and gAtr_ScanDB[itemName]
    if Atr_DatabaseHandles and Atr_DatabaseHandles() then current=Atr_DatabaseRecord(itemKey or itemName) end
    latestText:SetText("Latest saved / item: "..money(current and current.mr or latestPrice))
    coverage:SetText(data.count.." of "..range.." days with data")
    local last = data.points[#data.points]
    changeText:SetText("Latest daily change: "..changePercent(last and last.change))
    lowText:SetText("Lowest: "..money(data.low));highText:SetText("Highest: "..money(data.high))
    medianText:SetText("Chart median: "..money(data.median))
    for days,b in pairs(rangeButtons) do b:SetText(days==range and "|cffffffff"..days.." days|r" or days.." days") end
    for _,t in ipairs(segments) do t:Hide() end
    for _,dot in ipairs(dots) do dot:Hide() end
    usedSegments=0
    local bottom,top=0,1
    if data.low then
        local padding=math.max(1,(data.high-data.low)*0.1,data.high*0.02)
        bottom,top=math.max(0,data.low-padding),data.high+padding
    end
    local function y(price) return (price-bottom)/(top-bottom)*HEIGHT end
    for i,label in ipairs(ylabels) do
        local value=bottom+(top-bottom)*(i-1)/2
        label:SetText(data.count>0 and money(value) or "")
    end
    for i,label in ipairs(dates) do
        label:SetText(dayDate(math.floor(data.first+(range-1)*(i-1)/4+0.5)))
    end
    if data.median then
        grid.median:ClearAllPoints();grid.median:SetPoint("BOTTOMLEFT",plot,"BOTTOMLEFT",0,y(data.median))
        grid.median:SetSize(WIDTH,1);grid.median:Show()
    else grid.median:Hide() end
    local previous
    for i,point in ipairs(data.points) do
        local x=(point.day-data.first)/(range-1)*WIDTH
        local py=y(point.price)
        -- Leave days without a recorded price blank rather than inventing data.
        if previous and point.day==previous.day+1 then line(previous.x,previous.y,x,py) end
        previous={day=point.day,x=x,y=py}
        local dot=dots[i]
        if not dot then
            dot=CreateFrame("Button",nil,plot);dot:SetSize(10,10)
            local texture=rectangle(dot,{0.25,0.85,1});texture:SetAllPoints(dot)
            dot:SetScript("OnEnter",function(self)
                GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
                GameTooltip:AddLine(date("%Y-%m-%d",gScanHistDayZero+self.day*86400),1,0.82,0)
                GameTooltip:AddLine("Daily lowest / item: "..money(self.price),1,1,1)
                GameTooltip:AddLine("Change vs previous day: "..changePercent(self.change),1,1,1)
                if self.previous then GameTooltip:AddLine("Previous day / item: "..money(self.previous),0.8,0.8,0.8) end
                GameTooltip:Show()
            end)
            dot:SetScript("OnLeave",function() GameTooltip:Hide() end)
            dots[i]=dot
        end
        dot.day,dot.price,dot.change,dot.previous=point.day,point.price,point.change,point.previous
        dot:ClearAllPoints();dot:SetPoint("CENTER",plot,"BOTTOMLEFT",x,py);dot:Show()
    end
    if data.count==0 then message:SetText("No price history in this period.")
    elseif data.count==1 then message:SetText("One day recorded. More history needed for a trend.")
    else message:SetText("") end
end
local function createChart()
    chart=CreateFrame("Frame","Atr_PriceChart",UIParent)
    chart:SetSize(780,490);chart:SetPoint("CENTER");chart:SetFrameStrata("DIALOG");chart:SetFrameLevel(100)
    chart:SetClampedToScreen(true);chart:SetMovable(true);chart:EnableMouse(true);chart:RegisterForDrag("LeftButton")
    chart:SetScript("OnDragStart",function(self) self:StartMoving() end)
    chart:SetScript("OnDragStop",function(self) self:StopMovingOrSizing() end)
    -- The tooltip background texture has transparency even with a color alpha of 1.
    -- A solid texture keeps the browser behind this window from bleeding through.
    chart:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=16,edgeSize=24,insets={left=6,right=6,top=6,bottom=6}})
    chart:SetBackdropColor(0.035,0.035,0.035,1)
    if Atr_NativeSurface then Atr_NativeSurface(chart,"shell") end
    local function text(value,x,y,template)
        local label=chart:CreateFontString(nil,"OVERLAY",template or "GameFontHighlightSmall")
        label:SetPoint("TOPLEFT",chart,"TOPLEFT",x,y);label:SetText(value);return label
    end
    title=text("Price history",25,-22,"GameFontNormalLarge");title:SetWidth(690);title:SetJustifyH("LEFT")
    local close=CreateFrame("Button",nil,chart,"UIPanelCloseButton");close:SetPoint("TOPRIGHT",chart,"TOPRIGHT",-5,-5)
    close:SetScript("OnClick",function() chart:Hide() end)
    text("Range",25,-67,"GameFontNormal")
    for i,days in ipairs({7,14,30}) do
        local selectedDays=days
        local b=CreateFrame("Button",nil,chart,"UIPanelButtonTemplate")
        b:SetSize(85,22);b:SetPoint("TOPLEFT",chart,"TOPLEFT",85+(i-1)*92,-62)
        b:SetText(days.." days");b:SetScript("OnClick",function() range=selectedDays;draw() end)
        rangeButtons[days]=b
    end
    changeText=text("",400,-68,"GameFontNormal")
    latestText=text("",25,-104);coverage=text("",470,-104)
    lowText=text("",25,-130);highText=text("",280,-130);medianText=text("",510,-130)
    plot=CreateFrame("Frame",nil,chart);plot:SetSize(WIDTH,HEIGHT);plot:SetPoint("TOPLEFT",chart,"TOPLEFT",110,-170)
    plot:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"});plot:SetBackdropColor(0.06,0.07,0.09,1)
    if Atr_NativeSurface then Atr_NativeSurface(plot,"body") end
    for i=1,3 do
        local t=rectangle(plot,{0.35,0.35,0.4,0.6});t:SetPoint("BOTTOMLEFT",plot,"BOTTOMLEFT",0,(i-1)*HEIGHT/2);t:SetSize(WIDTH,1)
        local label=chart:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        label:SetPoint("RIGHT",plot,"BOTTOMLEFT",-9,(i-1)*HEIGHT/2);label:SetWidth(90);label:SetJustifyH("RIGHT")
        ylabels[i]=label
    end
    grid.median=rectangle(plot,{1,0.8,0.2,0.85})
    for i=1,5 do
        local label=chart:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        label:SetPoint("TOP",plot,"BOTTOMLEFT",(i-1)*WIDTH/4,-10);dates[i]=label
    end
    message=chart:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    message:SetPoint("CENTER",plot,"CENTER",0,0);message:SetWidth(WIDTH-40)
    text("|cff40d9ffDaily lowest / item|r     |cffffcc33Chart median|r     Missing days are left blank.",110,-454)
    chart:SetScript("OnShow",function(self)
        self:SetScale(math.max(0.5,math.min(1,(UIParent:GetWidth()-30)/780,(UIParent:GetHeight()-40)/490)))
    end)
    table.insert(UISpecialFrames,"Atr_PriceChart")
    chart:Hide()
end
function Atr_ShowPriceChart(name,price,key)
    if not chart then createChart() end
    itemName,latestPrice,itemKey=name,price,key
    draw();chart:Show()
end
AuctionatorRemastered.Legacy.Hook("Atr_Broadcast_DBupdated",function()
    if chart and chart:IsShown() then draw() end
end)
