-- local formatDecimal = function(value, count)
--     count = count or 0
--     count = math.floor(count)
--     if count < 0 then
--         count = 0
--     end
--     local nDecimal = math.pow(10, count)
--     local nTemp = math.floor(value * nDecimal)
--     local nRet = nTemp / nDecimal
--     return nRet
-- end
-- print("xm_test=>formatDecimal",formatDecimal(10, 1))


-- local formatByCount4 = function (num, maxLen, decimal,isRoundDown)
--     local string_len_list = {}

--     -- 只加逗号
--     local num_len = string.len(string.format("%d",tonumber(num)))

--     string_len_list[1] = {type = 1, value = num_len + (num_len % 3 == 0 and (math.floor(num_len / 3) - 1) or (math.floor(num_len / 3)))}

--     -- 逗号+K
--     string_len_list[2] = {type = 2, value = (num_len > 3 and (string_len_list[1].value - 3) or 999)}

--     -- 逗号+M
--     string_len_list[3] = {type = 3, value = (num_len > 6 and (string_len_list[1].value - 7) or 999)}

--     -- 逗号+B
--     string_len_list[4] = {type = 4, value = (num_len > 9 and (string_len_list[1].value - 11) or 999)}

--     -- 逗号+T
--     string_len_list[7] = {type = 7, value = (num_len > 12 and (string_len_list[1].value - 15) or 999)}

--     -- 逗号+Q
--     string_len_list[8] = {type = 8, value = (num_len > 15 and (string_len_list[1].value - 19) or 999)}

--     if decimal then
--         -- 带一位小数的KMB
--         string_len_list[5] = {type = 5, value = (num_len > 3 and ((num_len%3 == 0 and 6 or (num_len % 3 + 3))) or num_len)}

--         -- 带两位小数的KMB
--         string_len_list[6] = {type = 6, value = (num_len > 3 and ((num_len%3 == 0 and 7 or (num_len % 3 + 4))) or num_len)}
--     else
--         -- 带一位小数的KMB
--         string_len_list[5] = {type = 5, value = 999}

--         -- 带两位小数的KMB
--         string_len_list[6] = {type = 6, value = 999}
--     end

--     table.sort( string_len_list, function (a, b) return a.value>b.value end)
--     local format_type = 1
--     for i=1, #string_len_list do
--         if string_len_list[i].value <= maxLen then
--             format_type = string_len_list[i].type
--             break
--         end
--     end

--     local format_string
--     if format_type == 1 then
--         format_string = FONTS.format(num, true)

--     elseif format_type == 2 then
--         local temp_num = num / 1000
--         format_string = FONTS.format(temp_num, true).."K"

--     elseif format_type == 3 then
--         local temp_num = num / 1000000
--         format_string = FONTS.format(temp_num, true).."M"

--     elseif format_type == 4 then
--         local temp_num = num / 1000000000
--         format_string = FONTS.format(temp_num, true).."B"
--     elseif format_type == 7 then
--         local temp_num = num / 1000000000000
--         format_string = FONTS.format(temp_num, true).."T"
--     elseif format_type == 8 then
--         local temp_num = num / 1000000000000000
--         format_string = FONTS.format(temp_num, true).."Q"

--     elseif format_type == 5 then
--         format_string = FONTS.format(num, false, false)
-- 		if string.len(format_string)>maxLen then
-- 			local str1 = 	string.match(format_string, "%d+.%d+")
-- 			local str2 =    string.match(format_string, "[^$0-9%.]")
-- 			if not isRoundDown then
-- 				str1 = string.format("%0.1f",str1)
-- 				if math.floor(str1)-str1 == 0 then -- 如果小数位只有0 则只显示整数位
-- 					str1 = math.floor(str1)
-- 				end
-- 			else
-- 				if math.floor(str1)-str1 == 0 then -- 如果小数位只有0 则只显示整数位
-- 					str1 = math.floor(str1)
-- 				else
-- 					str1 =  (str1 -str1 %0.1) -- 小数向下区取整
-- 					if math.floor(str1)-str1 == 0 then
-- 						 math.floor(str1)
-- 					end
-- 				end
-- 			end
-- 			format_string = str1..str2

-- 		end
--     elseif format_type == 6 then
--         format_string = FONTS.format(num, false, false)
--     end
--     return format_string
-- end

-- local a = "1000"
-- -- print("xm_test=>formatByCount4", formatByCount4(1000000, 4, true, true))
-- print("xm_test=>formatByCount4", a:sub(2, 3))

-- if 200 > nil then
-- end

-- xm_test=>updateLabelCount col val   1   3441831683.1683
-- 04-24 11:48:57.502 15927 16009 D cocos2d-x debug info: [LUA-print] xm_test=>fnt     0T
-- 04-24 11:48:57.503 15927 16009 D cocos2d-x debug info: [LUA-print] xm_test=>updateLabelCount col val    2   2294554455.4455
-- 04-24 11:48:57.504 15927 16009 D cocos2d-x debug info: [LUA-print] xm_test=>fnt     0T
-- 04-24 11:48:57.504 15927 16009 D cocos2d-x debug info: [LUA-print] xm_test=>updateLabelCount col val    3   2753465346.5347
-- 04-24 11:48:57.508 15927 16009 D cocos2d-x debug info: [LUA-print] xm_test=>fnt     0T
-- 04-24 11:48:57.512 15927 16009 D cocos2d-x debug info: [LUA-print] xm_test=>updateLabelCount col val    4   3441831683.1683
-- 04-24 11:48:57.513 15927 16009 D cocos2d-x debug info: [LUA-print] xm_test=>fnt     0T
-- 04-24 11:48:57.514 15927 16009 D cocos2d-x debug info: [LUA-print] xm_test=>updateLabelCount col val    5   3212376237.6238
-- 04-24 11:48:57.514 15927 16009 D cocos2d-x debug info: [LUA-print] xm_test=>fnt     0T
-- 04-24 11:48:57.536 15927 16009 D cocos2d-x debug info: [LUA-print] xm_test=>updateLabelCount col val    1   3441831683.1683
-- 04-24 11:48:57.538 15927 16009 D cocos2d-x debug info: [LUA-print] xm_test=>fnt     0T
-- 04-24 11:48:57.539 15927 16009 D cocos2d-x debug info: [LUA-print] xm_test=>updateLabelCount col val    2   2294554455.4455
-- 04-24 11:48:57.539 15927 16009 D cocos2d-x debug info: [LUA-print] xm_test=>fnt     0T
-- 04-24 11:48:57.540 15927 16009 D cocos2d-x debug info: [LUA-print] xm_test=>updateLabelCount col val    3   2753465346.5347
-- 04-24 11:48:57.540 15927 16009 D cocos2d-x debug info: [LUA-print] xm_test=>fnt     0T
-- 04-24 11:48:57.541 15927 16009 D cocos2d-x debug info: [LUA-print] xm_test=>updateLabelCount col val    4   3441831683.1683
-- 04-24 11:48:57.541 15927 16009 D cocos2d-x debug info: [LUA-print] xm_test=>fnt     0T
-- 04-24 11:48:57.543 15927 16009 D cocos2d-x debug info: [LUA-print] xm_test=>updateLabelCount col val    5   3212376237.6238
-- 04-24 11:48:57.543 15927 16009 D cocos2d-x debug info: [LUA-print] xm_test=>fnt     0T

-- local num_len = string.len(string.format("%d",tonumber(num)))
-- print("num_len", num_len(2294554455.4455))


-- local table1 = {}
-- local table2 = {}
-- local key = 1
-- local endKey = 10000000
-- return true

-- do return true
-- end

-- local socket = require("socket")
-- print(socket.gettime()*1000)
-- local startT = os.time()
-- for i = key, endKey do 
--     -- table1[#table1 + 1] = i
--     table.insert(table1, i)
-- end
-- local endT = os.time()
-- print("endT - startT", endT - startT)
-- local unlock = true
-- local lock_anim = {
--         lock = "animation1",
--         lock_loop = "animation2",
--         unlock = "animation3",
--     }
-- local unlockLoop = lock_anim.unlock_loop
-- local lockLoop = lock_anim.lock_loop
-- local aniName = unlock and unlockLoop or lockLoop
-- print("aniName", aniName)


-- function getDataCol(col)
--     local boardIndex = math.ceil(col / 15)
--     local deCol = (boardIndex - 1) * 15
--     local boardCol = col - deCol
--     local posRow = math.ceil(boardCol / 5)
--     local posCol = (boardCol - 1) % 5 + 1
--     local dataCol = posRow + (posCol - 1) * 3 + deCol
--     return dataCol
-- end

-- print("getDataCol", getDataCol(10))

local data = {}
data[2] = {}
data[2].from = {{1,2,3},{3,4,5}}
data[2].to = {12,13}
data[3] = {}
data[3].from = {{11,21,31},{31,41,51}}
data[3].to = {121,131}

for key, val in pairs(data) do
    for index, posinfo in ipairs(val.from) do
        print("xm_test", key, index)
    end
end







