local Model={}
AuctionatorRemastered.Models.DatabaseStats=Model

function Model.Median(durations)
    local values={}
    for _,value in ipairs(durations) do
        if type(value)=="number" and value>=0 and value<math.huge then values[#values+1]=value end
    end
    table.sort(values)
    local count=#values
    if count==0 then return nil,0 end
    local middle=math.floor((count+1)/2)
    return count%2==1 and values[middle] or (values[middle]+values[middle+1])/2,count
end

function Model.Coverage(iterate,state,seed)
    local uniqueDays, oldest, newest, samples = {}, nil, nil, 0
    local seen={}
    for _, item in iterate,state,seed do
        if type(item) == "table" and not seen[item] then
            seen[item]=true
            -- Daily history and its median count as one item/day record.
            local itemDays={}
            for key, value in pairs(item) do
                local day = type(key) == "string" and tonumber(key:match("^[HM](%d+)$"))
                if day and not itemDays[day] and type(value) == "number" and value > 0 then
                    itemDays[day]=true
                    uniqueDays[day] = true
                    samples = samples + 1
                    oldest = not oldest and day or math.min(oldest, day)
                    newest = not newest and day or math.max(newest, day)
                end
            end
        end
    end
    local days = 0
    for _ in pairs(uniqueDays) do days = days + 1 end
    return days, oldest, newest, samples
end

function Model.Overview(iterator,state,seed,now)
    local result={total=0,recent=0,quality={},unknownQuality=0}
    local function visit(record)
        if type(record)~="table" or type(record.mr)~="number" or record.mr<=0 or record.mr~=record.mr or record.mr==math.huge then return end
        result.total=result.total+1
        local q=record.quality
        if type(q)=="number" and q>=0 and q<=7 and q==math.floor(q) then
            result.quality[q]=(result.quality[q] or 0)+1
        else result.unknownQuality=result.unknownQuality+1 end
        if type(record.lastScan)=="number" and now-record.lastScan>=0 and now-record.lastScan<=86400 then
            result.recent=result.recent+1
        end
    end
    for _,record in iterator,state,seed do visit(record) end
    return result
end
