local q = require("service.quick24.package_quick24")
local print = ngx.say

local function quick24_str_to_nums(str)
    local pattern = "[_,]"
    local nums = {}
    local idx = string.find(str, pattern)
    local last_idx = 1
    while idx do
        if idx > last_idx then
            local num = tonumber(string.sub(str, last_idx, idx - 1))
            table.insert(nums, num)
        end
        last_idx = idx + 1
        idx = string.find(str, pattern, last_idx)
        if not idx then
            if last_idx <= #str then
                local num = tonumber(string.sub(str, last_idx, -1))
                table.insert(nums, num)
            end
        end
    end
    return nums
end

local args = ngx.req.get_uri_args()
local quick24_str = args.quick24
if not quick24_str then
    quick24_str = '5,5,5,1'
    print('---quick24 demo---')
end
local nums = quick24_str_to_nums(quick24_str)
local ret, errmsg, list = q.quick24(nums)
if not ret then
    print(table.concat(nums, " "), errmsg)
else
    print(table.concat(nums, " "), " 计算如下("..#list..'种)', table.concat(list, " "))
end
