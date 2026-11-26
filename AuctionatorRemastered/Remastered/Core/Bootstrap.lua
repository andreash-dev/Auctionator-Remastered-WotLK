-- Runtime namespace only. SavedVariables and public Atr_* entry points retain
-- their original names for existing data, XML handlers and addon integrations.
AuctionatorRemastered = AuctionatorRemastered or {}
local R = AuctionatorRemastered
R.Models = R.Models or {}
R.UI = R.UI or {}
R.Browser = R.Browser or {}
R.Legacy = R.Legacy or {}

-- Startup owns this preference so it is available before the main UI is built.
R.UI.themeMode=AUCTIONATOR_REMASTERED_THEME or "automatic"
function R.UI.UseElvUI()
    return R.UI.themeMode~="native" and type(ElvUI)=="table"
end
function R.UI.HasElvUI()
    return type(ElvUI)=="table" and type(ElvUI[1])=="table"
end
function R.UI.RequestedTheme()
    if AUCTIONATOR_REMASTERED_THEME=="native" or not R.UI.HasElvUI() then return "native" end
    return "elvui"
end
function R.UI.SetThemePreference(mode)
    if mode~="native" and (mode~="elvui" or not R.UI.HasElvUI()) then return false end
    AUCTIONATOR_REMASTERED_THEME=mode
    return true
end

local backgroundKeys={browser="browserTransparent",shopping="shoppingTransparent",auction="auctionTransparent"}
local function preferences()
    if type(AUCTIONATOR_SAVEDVARS)~="table" then AUCTIONATOR_SAVEDVARS={} end
    return AUCTIONATOR_SAVEDVARS
end
function R.UI.PriceAgeDays()
    local days=tonumber(preferences().oldPriceDays)
    for _,allowed in ipairs({0,1,3,7,14,30}) do
        if days==allowed then return days end
    end
    return 1
end
function R.UI.MarkPriceAge(text,timestamp,now)
    local days=R.UI.PriceAgeDays()
    if days>0 and type(timestamp)=="number" and timestamp>0 and (now or time())-timestamp>=days*86400 then
        return "|cffff9933"..text.." (old)|r"
    end
    return text
end
function R.UI.ScanNotification(kind)
    if kind=="message" then return preferences().scanCompleteMessage~=false end
    return kind=="sound" and preferences().scanCompleteSound==true
end
function R.UI.BackgroundTransparent(kind)
    local settings=type(AUCTIONATOR_BROWSER_SETTINGS)=="table" and AUCTIONATOR_BROWSER_SETTINGS or {}
    if kind=="auction" then
        if type(settings.auctionTransparent)=="boolean" then return settings.auctionTransparent end
        if R.UI.AuctionDefaultTransparent then return R.UI.AuctionDefaultTransparent() end
        return R.UI.UseElvUI()
    end
    if kind=="browser" then
        if type(settings.browserTransparent)=="boolean" then return settings.browserTransparent end
        return R.UI.UseElvUI()
    end
    return kind=="shopping" and settings.shoppingTransparent==true
end
function R.UI.SetBackgroundTransparent(kind,checked)
    local key=backgroundKeys[kind]
    if not key then return false end
    if type(AUCTIONATOR_BROWSER_SETTINGS)~="table" then AUCTIONATOR_BROWSER_SETTINGS={} end
    AUCTIONATOR_BROWSER_SETTINGS[key]=checked and true or false
    local refresh
    if kind=="auction" then refresh=R.UI.RefreshAuctionBackgrounds
    elseif kind=="browser" then refresh=R.UI.RefreshBrowserBackgrounds
    else refresh=R.UI.RefreshShoppingBackgrounds end
    if refresh then refresh() end
    return true
end

-- Material breakdown preference is independent of the estimated-value checkbox.
function R.UI.ProspectingDetailsMode()
    local mode=AUCTIONATOR_SAVEDVARS and AUCTIONATOR_SAVEDVARS.prospectingDetails
    if mode=="control" or mode=="alt" or mode=="never" or mode=="always" then return mode end
    return "shift"
end
