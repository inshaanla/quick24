local _M = {}

local operations = {"+", "-", "*", "/"}

local function get_value(ta)
    if type(ta) == 'table' then
        return ta[1]
    end
    return ta
end

local function get_trace(ta)
    if type(ta) == 'table' then
        return ta[2]
    end
    return ta
end

local function do_operation(ta, op, tb)
    local value
    local a, b = get_value(ta), get_value(tb)
    if op == "+" then
        value = a + b
    elseif op == "-" then
        value = a - b
    elseif op == "*" then
        value = a * b
    elseif op == "/" then
        if b == 0 then
            return nil
        end
        value = a / b
    end
    if (op == "*" or op == "+")  and a > b then
        return {value, table.concat({"(", get_trace(tb), op, get_trace(ta), ")"})}
    end
    return {value, table.concat({"(", get_trace(ta), op, get_trace(tb), ")"})}
end

local function is_valid_nums(nums)
    if #nums ~= 4 then
        return false
    end
    for i = 1, 4 do
        local num = nums[i]
        if not num or num < 1 then
            return false
        end
        if math.floor(num) ~= num then
            return false
        end
    end
    return true
end

local function get_answers(answer_list)
    local list = {}
    for _, one_answer in pairs(answer_list) do
        local trace = get_trace(one_answer[1])
        trace = string.sub(trace, 2, #trace-1)
        table.insert(list, trace)
    end
    return list
end

local function get_barcket_pair_list(str)
    local barcket_pair_list = {}
    local stack = {}
    for i = 1, #str do
        local char = string.sub(str, i, i)
        if char == '(' then
            table.insert(stack, {'(', i})
        elseif char == ')' then
            local barcket_pair = stack[#stack]
            table.insert(barcket_pair_list, {barcket_pair[2], i})
            table.remove(stack)
        end
    end
    return barcket_pair_list
end

local opcode_div = 11
local opcode_mul = 10
local opcode_default = 0
local op_value_define = {
    ['+'] = opcode_default,
    ['-'] = opcode_default,
    ['*'] = opcode_mul,
    ['/'] = opcode_div,
}

local function get_op_value(op)
    if not op then return opcode_default end
    return op_value_define[op] or opcode_default
end

local function is_lower_priority_op(opa, opb)
    if get_op_value(opb) == opcode_div then
        return true
    end
    return get_op_value(opa) < get_op_value(opb)
end

local function remove_barcket(src_str)
    local str = string.sub(src_str, 1, -1)
    local real_op_pattern = '[%+%-%*/%(%)]'
    local barcket_pair_list = get_barcket_pair_list(str)
    for _, one_pair in pairs(barcket_pair_list) do
        local barcket_idx_left = one_pair[1]
        local barcket_idx_right = one_pair[2]
        local mid_str = string.sub(str, barcket_idx_left + 1, barcket_idx_right - 1)
        repeat
            local op_code_left = get_op_value(string.sub(str, barcket_idx_left -1, barcket_idx_left -1))
            local op_code_right = get_op_value(string.sub(str, barcket_idx_right +1, barcket_idx_right +1))
            local included_min_op_code = opcode_div
            local op_idx = string.find(mid_str, real_op_pattern)
            while op_idx do
                local code = get_op_value(string.sub(mid_str, op_idx, op_idx))
                if code < included_min_op_code then
                    included_min_op_code = code
                end
                op_idx = string.find(mid_str, real_op_pattern, op_idx + 1)
            end
            if op_code_left == opcode_div then
                break
            end
            if op_code_left > included_min_op_code then
                break
            end
            if included_min_op_code < opcode_mul and op_code_right > included_min_op_code then
                break
            end

            str = table.concat({string.sub(str, 1, barcket_idx_left-1) or "",  " ", string.sub(str, barcket_idx_left+1, barcket_idx_right - 1) or "",  " ", string.sub(str, barcket_idx_right+1, -1) or ""})
        until true
    end
    str = string.gsub(str, " ", "")
    return str
end

local function calc_value(str)
    local op_stack = {}
    local num_stack = {}
    local last_idx = 1

    local do_one_op = function(op_stack, num_stack)
        local b = num_stack[#num_stack]
        local a = num_stack[#num_stack - 1]
        local temp_op = op_stack[#op_stack]
        local temp_value = 0
        if temp_op == "+" then
            temp_value = a + b
        elseif temp_op == "-" then
            temp_value = a - b
        elseif temp_op == "*" then
            temp_value = a * b
        elseif temp_op == "/" then
            temp_value = a / b
        end
        table.remove(num_stack)
        table.remove(num_stack)
        table.insert(num_stack, temp_value)
        table.remove(op_stack)
    end

    local op_pattern = '[%+%-%*/%(%)]'
    local idx = string.find(str, op_pattern, last_idx)
    while idx do
        local op = string.sub(str, idx, idx)
        local num_str
        local num
        if idx > last_idx then
            num_str = string.sub(str, last_idx, idx - 1)
            num = tonumber(num_str)
        end

        if num then
            table.insert(num_stack, num)
        end
        if op == ')' then
            local temp_idx = #op_stack
            while temp_idx > 0 do
                local temp_op = op_stack[temp_idx]
                if temp_op == '(' then
                    table.remove(op_stack)
                    break
                else
                    do_one_op(op_stack, num_stack)
                end
                temp_idx = #op_stack
            end
        else
            if op ~= "(" and next(op_stack) and op_stack[#op_stack] ~= "(" and is_lower_priority_op(op, op_stack[#op_stack]) then
                do_one_op(op_stack, num_stack)
            end
            table.insert(op_stack, op)
        end
        last_idx = idx + 1
        idx = string.find(str, op_pattern, last_idx)
        if not idx then
            num_str = string.sub(str, last_idx, -1)
            num = tonumber(num_str)
            if num then
                table.insert(num_stack, num)
            end
        end
    end

    local idx = #op_stack
    while idx > 0 do
        do_one_op(op_stack, num_stack)
        idx = #op_stack
    end
    return num_stack[1]
end

local function filter(result_list)
    local function resort(str, left, right)
        local op_pattern = '[%+%-%*/%(%)]'
        local op
        local sub_str = string.sub(str, left, right)
        local idx = string.find(sub_str, op_pattern)
        local num_list = {}
        local last_idx = 0
        while idx do
            if idx - 1 >= last_idx then
                local num = tonumber(string.sub(sub_str, last_idx + 1, idx - 1))
                table.insert(num_list, num)
            end
            local temp_op = string.sub(sub_str, idx, idx)
            if op and op ~= temp_op then
                return false
            end
            op = temp_op
            last_idx = idx
            idx = string.find(sub_str, op_pattern, idx + 1)
            if not idx and last_idx + 1 <= #sub_str then
                local num = tonumber(string.sub(sub_str, last_idx + 1, -1))
                table.insert(num_list, num)
            end
        end

        if op == "+" or op == '*' then
            table.sort(num_list)
        elseif op == "/" then
            local first = num_list[1]
            table.remove(num_list, 1)
            table.sort(num_list)
            table.insert(num_list, 1, first)
        else
            return false
        end
        return true, table.concat(num_list, op)
    end

    local function do_hash(str)
        local barcket_pair_list = get_barcket_pair_list(str)
        if barcket_pair_list[1] then
            local left = barcket_pair_list[1][1]
            local right = barcket_pair_list[1][2]
            local ret, resort_str = resort(str, left + 1, right - 1)
            if ret then
                resort_str = table.concat({
                    string.sub(str, 1, left),
                    resort_str,
                    string.sub(str, right, -1)
                })
                return resort_str
            end
        else
            local ret, resort_str = resort(str, 1, #str)
            if ret then
                return resort_str
            end
        end
        return str
    end

    local exist_map = {}
    local real_result = {}
    for _, one_test in pairs(result_list) do
        if calc_value(one_test) == 24 then
            local hashed = do_hash(remove_barcket(one_test))
            if not exist_map[hashed] then
                exist_map[hashed] = true
                table.insert(real_result, hashed)
            end
        end
    end
    return real_result
end

function _M.quick24(nums, do_filter)
    do_filter = do_filter or true
    if not is_valid_nums(nums) then
        return nil, "数字有误"
    end

    local function step(nums_list)
        local exist_map = {}
        local function exist_same(new_nums)
            local nums_str = {}
            for _, v in pairs(new_nums) do
                table.insert(nums_str, get_trace(v))
            end
            local hash = table.concat(nums_str)
            if exist_map[hash] then
                return true
            end
            exist_map[hash] = true
        end

        local list_step = {}
        for _, op in ipairs(operations) do
            for _, nums in pairs(nums_list) do
                for i = 1, #nums do
                    local a = nums[i]
                    for j = 1, #nums do
                        if i ~= j then
                            local b = nums[j]
                            local c, d
                            for k = 1, #nums do
                                if k ~= i and k ~= j then
                                    if not c then
                                        c = nums[k]
                                    else
                                        d = nums[k]
                                    end
                                end
                            end
                            local ret = do_operation(a,op,b)
                            if ret then
                                local new_nums
                                if c and d then
                                    new_nums = {ret, c, d}
                                elseif c then
                                    new_nums = {ret, c}
                                else
                                    if get_value(ret) == 24 then
                                        new_nums = {ret}
                                    end
                                end
                                if new_nums and not exist_same(new_nums) then
                                    table.insert(list_step, new_nums)
                                end
                            end
                        end
                    end
                end
            end
        end
        return list_step
    end
    local result_list = get_answers(step(step(step({nums}))))
    if do_filter then
        result_list = filter(result_list)
    end
    if not next(result_list) then
        return false, "无法得出24"
    end
    return true, nil, result_list
end


return _M
