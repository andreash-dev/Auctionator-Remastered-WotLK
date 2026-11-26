-- WotLK estimates from AzerothCore prospecting_loot_template / reference_loot_template.
-- https://github.com/azerothcore/azerothcore-wotlk/tree/master/data/sql/base/db_world
-- Each batch consumes five ore. Independent rolls combine expected quantities,
-- while mutually exclusive groups are expanded with their source weights.
local P={ores={},names={}}
AuctionatorRemastered.Models.Prospecting=P
local function add(ore,id,name,p,low,high)
    P.names[id]=name
    local list=P.ores[ore] or {};P.ores[ore]=list
    for _,row in ipairs(list) do
        if row.id==id then
            row.chance=1-(1-row.chance)*(1-p)
            row.expected=row.expected+p*(low+high)/2
            row.maximum=row.maximum+high
            row.minimum=math.min(row.minimum,low)
            return
        end
    end
    list[#list+1]={id=id,chance=p,minimum=low,maximum=high,expected=p*(low+high)/2}
end
local commonBC={{21929,"Flame Spessarite"},{23077,"Blood Garnet"},{23079,"Deep Peridot"},{23107,"Shadow Draenite"},{23112,"Golden Draenite"},{23117,"Azure Moonstone"}}
local rareBC={{23436,"Living Ruby"},{23437,"Talasite"},{23438,"Star of Elune"},{23439,"Noble Topaz"},{23440,"Dawnstone"},{23441,"Nightseye"}}
local commonLK={{36917,"Bloodstone"},{36920,"Sun Crystal"},{36923,"Chalcedony"},{36926,"Shadow Crystal"},{36929,"Huge Citrine"},{36932,"Dark Jade"}}
local rareLK={{36918,"Scarlet Ruby"},{36921,"Autumn's Glow"},{36924,"Sky Sapphire"},{36927,"Twilight Opal"},{36930,"Monarch Topaz"},{36933,"Forest Emerald"}}
local epicLK={{36919,"Cardinal Ruby"},{36922,"King's Amber"},{36925,"Majestic Zircon"},{36928,"Dreadstone"},{36931,"Ametrine"},{36934,"Eye of Zul"}}
local function group(ore,items,trigger,low,high,weights)
    for i,item in ipairs(items) do add(ore,item[1],item[2],trigger*(weights and weights[i] or 1/#items),low,high) end
end
add(2770,774,"Malachite",.5,1,1);add(2770,818,"Tigerseye",.5,1,1);add(2770,1210,"Shadowgem",.1,1,1)
group(2771,{{1206,"Moss Agate"},{1210,"Shadowgem"},{1705,"Lesser Moonstone"}},1,1,2)
group(2771,{{1529,"Jade"},{3864,"Citrine"},{7909,"Aquamarine"}},.1,1,1)
add(2772,1529,"Jade",.3,1,2);add(2772,1705,"Lesser Moonstone",.3,1,2);add(2772,3864,"Citrine",.3,1,2)
add(2772,7909,"Aquamarine",.05,1,1);add(2772,7910,"Star Ruby",.05,1,1)
group(3858,{{3864,"Citrine"},{7909,"Aquamarine"},{7910,"Star Ruby"}},.9,1,2)
local classics={{12361,"Blue Sapphire"},{12364,"Huge Emerald"},{12799,"Large Opal"},{12800,"Azerothian Diamond"}}
group(3858,classics,.1,1,1)
add(10620,7910,"Star Ruby",.3,1,2);group(10620,classics,.6,1,2);group(10620,commonBC,.1,1,2)
group(23424,commonBC,1,1,2);group(23424,rareBC,.24,1,1)
group(23425,commonBC,1,1,2);group(23425,rareBC,.24,1,2);group(23425,commonBC,.15,1,2)
add(23425,24243,"Adamantite Powder",1,1,1)
group(36909,commonLK,1,1,2,{.16,.16,.16,.16,.15,.15});group(36909,rareLK,.06,1,2)
group(36912,commonLK,.85,1,2);group(36912,commonLK,1,1,2,{.15,.15,.14,.14,.14,.14})
group(36912,rareLK,1,1,2,{.03,.03,.02,.02,.02,.02})
group(36910,epicLK,.2,1,1);group(36910,commonLK,.75,1,2);group(36910,commonLK,.75,1,2)
group(36910,rareLK,1,1,2,{.05,.04,.04,.04,.04,.04});add(36910,46849,"Titanium Powder",.75,1,1)
function P.Evaluate(ore,quote)
    local rows=P.ores[tonumber(ore)]
    if not rows then return nil end
    local status={complete=true,missing={},stale=false,partial=false,undated=false}
    local value=0
    for _,row in ipairs(rows) do
        local price,info=quote(row.id)
        if type(price)~="number" or price~=price or price<=0 or price==math.huge then
            status.complete=false;status.missing[#status.missing+1]=row.id
        else
            value=value+row.expected*price
            for _,flag in ipairs({"stale","partial","undated"}) do status[flag]=status[flag] or (info and info[flag]) or false end
        end
    end
    return status.complete and math.floor(value+.5) or nil,status
end
