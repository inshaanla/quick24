local q = require("package_quick24")
local nums = {10,9,5,7}
local ret, errmsg, list = q.quick24(nums)
if not ret then
    print(table.concat(nums, " "), errmsg)
else
    print(table.concat(nums, " "), " 计算如下("..#list..'种)', table.concat(list, " "))
end