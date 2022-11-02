--[[
    橡皮擦
]]
-- 擦出类型
local Enum = {}
Enum.EraserType = {
    RECTANGULAR = 1,
    CIRCLE = 2,
}
-- 擦出状态
Enum.EraserSatus = {
    DEFAULT = 0,
    INIT = 1,
    ERASERING = 2,
    PAUSE = 3,
    STOP = 4
}
-- 记录状态
Enum.RecordEraserType = {
    DEFAULT = 0,
    START = 1,
    PAUSE = 2,
    STOP = 3,
}
-- 橡皮擦的半径大小
local ERASER_R = 30
--[[
    橡皮擦
]]
-- 代码示例
--[[
     local eraser = Eraser.new({
        bg_sp_path = "lobby_img02.png" , -- 背景图
        front_sp_path = "lobby_img03.png" , -- 涂层
        point_sp_path = "kong.png" , -- 擦出点 透明图片，目前支持矩形，其它形状的计算误差会大一些
        erase_window_rect = cc.rect(0 , 150 , nil , 200) -- 指定涂层有效擦出窗口（不一定要全擦出才算做完成）
    })
    eraser:setPosition(cc.p(307 / 2 + 200, 474 / 2)) -- 
    eraser:registerEraseCallback(function (pro) -- 注册擦出回调 pro是擦出的百分比
        if pro > 0.8 then
            eraser:pause()
            -- 完成擦出
        end
    end)
    node:addChild(eraser)
]]
local Eraser = class("class" , function ()
    return cc.Node:create()
end)

Eraser.Enum = Enum

function Eraser:ctor(data)
    data = data or {}
    -- 背景图片路径
    self._bg_sp_path = data.bg_sp_path
    -- 前景图片路径
    self._front_sp_path = data.front_sp_path
    -- 擦出点图片路径
    self._point_sp_path = data.point_sp_path
    -- 擦出点半径
    self._point_radius = data.point_radius or ERASER_R
    --背景节点
    self._sp_bg = nil
    --前景节点
    self._sp_front = nil
    --擦出点节点
    self._sp_point = nil 
    --回调函数
    self._erase_callback = nil
    -- draw Node
    self._draw_node = nil
    -- 事件层
    self._layer_event = nil
    --事件监听器
    self._layerEventListener = nil
    --像素映射表
    self._pixel_maps = {}
    --擦出类型
    self._eraser_type = Enum.EraserType.RECTANGULAR
    --擦出窗口的大小和位置
    self._erase_window_rect = data.erase_window_rect
    -- 擦出状态
    self._status = Enum.EraserSatus.DEFAULT
    -- 之前的状态
    self._last_status = Enum.EraserSatus.DEFAULT
    -- 错误信息
    self._error_msg = nil 
    -- 累计擦除像素
    self._total_eraser_pixel_num = 0
    -- 更新节点 （循环动画）
    self._anim_node_forever = nil
    -- 触碰节点集合
    self._move_pos_list = {}
    -- 是否更新擦除节点位置中
    self._updating_meraser_point_pos = false
    -- 更新擦除节点的开始坐标和结束坐标
    self._udpating_meraser_start_pos = nil
    self._udpating_meraser_end_pos = nil
    -- 触碰状态
    self._touch_status = nil

    -- 记录擦出操作
    self._record_eraser_log = {}
    -- 当前帧操作
    self._record_log_frame = {}
    -- 记录状态
    self._record_status = Enum.RecordEraserType.DEFAULT
    -- 记录回调函数
    self._record_callback = nil
    -- 记录节点
    self._record_node = nil

    self._error_msg = self:_init()
end
-- 初始化
function Eraser:_init()
    if self:getStatus() >= Enum.EraserSatus.INIT then return end
    self:_setStatus(Enum.EraserSatus.INIT)
    -- 创建背景图片
    if cc.FileUtils:getInstance():isFileExist(self._bg_sp_path) then 
        self._sp_bg = cc.Sprite:create(self._bg_sp_path)
        self:addChild(self._sp_bg)
    end
    -- 创建前景图片
    if not cc.FileUtils:getInstance():isFileExist(self._front_sp_path) then
        return "is not found " .. (self._front_sp_path or "")
    else
        self._sp_front = cc.Sprite:create(self._front_sp_path)
        self._sp_front:setVisible(false)
        self:addChild(self._sp_front)
    end
    -- 创建事件层
    self._error_msg = self:_initLayer()
    if self._error_msg then
        return self._error_msg
    end
    -- 映射表
    self._error_msg = self:_buildPixelMaps()
    if self._error_msg then
        return self._error_msg
    end
    -- 初始化环境
    self._error_msg = self:_initEnv()
    if self._error_msg then
        return self._error_msg
    end

    self._anim_node_forever = cc.Node:create()
    self:addChild(self._anim_node_forever)

    self:_setStatus(Enum.EraserSatus.ERASERING)
end
--设置状态
function Eraser:_setStatus(status)
    self._last_status = self._status
    self._status = status
    if status == Enum.EraserSatus.ERASERING then
        self:_onErasering()
    elseif status == Enum.EraserSatus.STOP then
        self:_onStop()
    end
end
function Eraser:_onStop()
    if type( self._erase_callback) == "function" then
        self._erase_callback("stop" , self:getProgress() , 0)
    end
end
-- 
function Eraser:_onErasering()
    self:_runUpdate()
end
--获取状态
function Eraser:getStatus(status)
    return self._status 
end
-- 重置状态
function Eraser:reset()
    self:_setStatus(Enum.EraserSatus.INIT)
    self._error_msg = nil 
    self._move_pos_list = {}
    self._updating_meraser_point_pos = false
    if self._record_node then
        self._record_node:removeFromParent()
        self._record_node = nil
    end
    -- 重新构建像素数据
    self:_buildPixelMaps()
    self:_drawCoat()
    self:_setStatus(Enum.EraserSatus.ERASERING)
end
--暂停
function Eraser:pause()
    self:_setStatus(Enum.EraserSatus.PAUSE)
end
--停止
function Eraser:stop()
    self:_setStatus(Enum.EraserSatus.STOP)
end
-- 恢复
function Eraser:resume()
    if self._last_status == self._status or not self._last_status or self._status == Enum.EraserSatus.STOP then return end 
    self:_setStatus(self._last_status)
    self._last_status = nil
end

-- 获取错误信息
function Eraser:getErr()
    return self._error_msg
end

-- 初始化事件层
function Eraser:_initLayer()
    if not self._sp_front then 
        return "sp_front is null"
    end
    local sp_front_size = self._sp_front:getContentSize()

	local layer_event = cc.LayerColor:create( cc.c4b(0, 0, 0, 0))
    -- layer_event:setAnchorPoint(cc.p(0.5 , 0.5))
    layer_event:setPosition(cc.p(-sp_front_size.width / 2 , -sp_front_size.height / 2))
    layer_event:setContentSize(sp_front_size)
    layer_event:setTouchEnabled(true)

    if not self._erase_window_rect then
        self._erase_window_rect = cc.rect(0 , 0 , sp_front_size.width , sp_front_size.height)
    else
        if not self._erase_window_rect.x then
            self._erase_window_rect.x = 0
        end
        if not self._erase_window_rect.y then
            self._erase_window_rect.y = 0
        end
        if not self._erase_window_rect.width then
            self._erase_window_rect.width = sp_front_size.width
        end
        if not self._erase_window_rect.height then
            self._erase_window_rect.height = sp_front_size.height
        end
    end

    -- 去零
    self._erase_window_rect.x = math.floor(self._erase_window_rect.x)
    self._erase_window_rect.y = math.floor(self._erase_window_rect.y)
    self._erase_window_rect.width = math.floor(self._erase_window_rect.width)
    self._erase_window_rect.height = math.floor(self._erase_window_rect.height)


    self:addChild(layer_event , 1)
    self._layer_event = layer_event

    -- 初始化层事件
    self:_initLayerEvent()
end

function Eraser:onTouchBegan(touch , event)
    -- print("onTouchBegan") 
    if self:getStatus() == Enum.EraserSatus.ERASERING then
        if type( self._erase_callback) == "function" then
            self._erase_callback("start" , self:getProgress() , 0)
        end
        self._touch_status = cc.Handler.EVENT_TOUCH_BEGAN
        return true
    end
    return false
end
function Eraser:onTouchMoved(touch , event)
    if self:getStatus() ~= Enum.EraserSatus.ERASERING then return end
    -- print("onTouchMoved")

    self._touch_status  = cc.Handler.EVENT_TOUCH_MOVED
    local touch_pos     = touch:getLocation()
    local layer_event   = self._layer_event
    local wps           = self:convertToWorldSpace(cc.p(self._layer_event:getPosition()))
    local pixelPos      = self._layer_event:convertToNodeSpace(touch_pos)
    -- print("onTouchMoved" , touch_pos.x , touch_pos.y , npos.x , npos.y) 

    -- 停止播放擦除记录
    self:stopPlayRecord()
    -- 插入坐标
    self:_insertMovePos(pixelPos)

    -- self:_doEraser(pixelPos)
end
-- 擦出指定位置
--[[
    npos 像素位置
    point_pos 擦出点位置
]]
function Eraser:_doEraser(pixelPos)
    if not self._sp_point then return end

    if type(self._record_callback) == "function" then
        self._record_callback(pixelPos)
    end

    local sp_point = self._sp_point
    sp_point:setPosition(pixelPos)
    sp_point:setVisible(true)
    self._rt:begin()
    sp_point:visit()
    self._rt:endToLua()
    sp_point:setVisible(false)
    local point_size = sp_point:getEraseSize()

    -- 计算擦出
    local eraser_pixel_num = self:_dealEraserCalculate(pixelPos , point_size)

    self._total_eraser_pixel_num = self._total_eraser_pixel_num + eraser_pixel_num

    if type( self._erase_callback) == "function" then
        self._erase_callback("move" , self:getProgress() , eraser_pixel_num)
    end
end

function Eraser:onTouchEnded(touch , event)
    if type( self._erase_callback) == "function" then
        self._erase_callback("end" , self:getProgress(true) , 0)
    end
    self._touch_status  = cc.Handler.EVENT_TOUCH_ENDED
end
function Eraser:onTouchCancelled(touch , event)
    if type( self._erase_callback) == "function" then
        self._erase_callback("end" , self:getProgress(true) , 0)
    end
    self._touch_status  = cc.Handler.EVENT_TOUCH_CANCELLED
end
-- 初始化点击事件
function Eraser:_initLayerEvent()
	local layer_event = self._layer_event
	local function  onTouchBegan( touch, event ) 
        return self:onTouchBegan(touch, event ) 
	end
	local function  onTouchMoved( touch, event )  
        return self:onTouchMoved(touch, event ) 
	end
	local function  onTouchCancelled( touch, event ) 
        return self:onTouchCancelled(touch, event ) 
	end
	local function  onTouchEnded( touch, event )  
        return self:onTouchEnded(touch, event ) 
	end
	local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(true)
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
    listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
    listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
   	listener:registerScriptHandler(onTouchCancelled,cc.Handler.EVENT_TOUCH_CANCELLED )
    local eventDispatcher = layer_event:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, layer_event)
    self._layerEventListener = listener

end
-- 插入一个移动坐标
function Eraser:_insertMovePos(pos)
    table.insert(self._move_pos_list , pos)
end
-- 获取移动列表
function Eraser:_getMovePosList()
    return self._move_pos_list or {}
end
-- 获取移动列表数量
function Eraser:_getMovePosListLength()
    return #self:_getMovePosList()
end
-- 获取移动坐标
function Eraser:_getMovePosByIndex(index)
    return self._move_pos_list[index]
end
-- 弹出坐标
function Eraser:_popMovePos()
    local pos = self._move_pos_list[1]
    table.remove(self._move_pos_list , 1)
    return pos
end
-- 更新擦除点的位置 
function Eraser:_updateEraserPoint()
    local start_pos = self._udpating_meraser_start_pos
    local end_pos = self._udpating_meraser_end_pos

    if not self._updating_meraser_point_pos then
        local pos_num = self:_getMovePosListLength()
        if pos_num == 1 and start_pos then 
            end_pos = self:_popMovePos()
        elseif pos_num > 1 then
            -- print("_updateEraserPoint pos_num" , pos_num)
            start_pos = self:_popMovePos()
            end_pos = self:_getMovePosByIndex(1)
        end
    end

    if not start_pos or not end_pos then return end
    self._udpating_meraser_end_pos = end_pos
    self._updating_meraser_point_pos = true


    -- 移动的步长
    local d_dis = self._point_radius / 3
    -- 计算方向
    local sub_p = cc.pSub(end_pos , start_pos)
    local dir_p = cc.p(sub_p.x / math.abs(sub_p.x == 0 and 1 or sub_p.x) , sub_p.y / math.abs(sub_p.y == 0 and 1 or sub_p.y))

    local cur_pos = cc.pAdd(start_pos , cc.p(d_dis * dir_p.x , d_dis * dir_p.y))
    
    -- 如果移动位置超过结束位置，改次更新移动结束  (如果 dir_cur_p 和 dir_p 方向相同则是超过了)
    local sub_cur_p = cc.pSub(cur_pos , end_pos)
    local dir_cur_p = cc.p(sub_cur_p.x / math.abs(sub_cur_p.x == 0 and 1 or sub_cur_p.x) , sub_cur_p.y / math.abs(sub_cur_p.y == 0 and 1 or sub_cur_p.y))
    
    if dir_cur_p.x * dir_p.x >= 0 and dir_cur_p.y * dir_p.y >= 0 then
        cur_pos = end_pos
        self._updating_meraser_point_pos = false
        self._udpating_meraser_end_pos = nil 
    end

    -- print("start_pos" , start_pos.x , start_pos.y)
    -- print("end_pos" , end_pos.x , end_pos.y)
    -- print("sub_p" , sub_p.x , sub_p.y)
    -- print("dir_p" , dir_p.x , dir_p.y)
    -- print("cur_pos" , cur_pos.x , cur_pos.y)

    if self:_getMovePosListLength() == 0 and not self._updating_meraser_point_pos then
        self._udpating_meraser_start_pos = nil
    else
        self._udpating_meraser_start_pos = cur_pos
    end

    self:_doEraser(cur_pos)
    
end

-- 开启更新
function Eraser:_runUpdate()
    if not self._anim_node_forever then return end

    self._anim_node_forever:runAction(cc.RepeatForever:create(cc.Sequence:create(
        cc.DelayTime:create(0.00),
        cc.CallFunc:create(function ()  
            self:_updateEraserPoint()
        end)
    )))

end

-- 停止更新
function Eraser:_stopUpdate()
    if not self._anim_node_forever then return end
    self._anim_node_forever:stopAllActions()
end

-- 初始化绘画环境
function Eraser:_initEnv() 
    if not self._layer_event then 
        return "layer_event is null"
    end
    local layer_event = self._layer_event
    local layer_event_size = layer_event:getContentSize()
    -- 创建擦出点图片
    if cc.FileUtils:getInstance():isFileExist(self._point_sp_path) then
        local nd = cc.Node:create()

        local r = self._point_radius

        local ori_r = 13
        for x = -ori_r, ori_r, 1 do
            local sqrt_y = math.sqrt(ori_r * ori_r - x * x)
            for y = -sqrt_y, sqrt_y, 1 do
                local sp = cc.Sprite:create(self._point_sp_path)
                local func = cc.blendFunc(gl.ONE , gl.ZERO)
                sp:setBlendFunc(func) 
                sp:setPosition(cc.p(x , y))
                nd:addChild(sp)
            end
        end
        
        nd:setScale(r / ori_r)
        -- nd:setScaleX(r / ori_r * 1.5)
        nd:setVisible(false)    
        layer_event:addChild(nd , 3)
        nd.getEraseSize = function(this)
            return cc.size(2 * r , 2 * r)
        end
        self._sp_point = nd 
    else
        -- local drawNode = cc.DrawNode:create()
        -- local func = cc.blendFunc(0.5 , 0.5)
        -- drawNode:setBlendFunc(func)
		-- drawNode:setBlendFunc(gl.ONE , gl.ZERO)
        -- self._draw_node = drawNode
        -- layer_event:addChild(drawNode , 3)
    end  

    local rt = cc.RenderTexture:create(layer_event_size.width ,  layer_event_size.height)
    rt:setPosition(cc.p(layer_event_size.width / 2 , layer_event_size.height / 2))
    layer_event:addChild(rt)
    self._rt = rt

    self:_drawCoat()
    -- 将前景渲染到事件层
end
-- 绘制涂层
function Eraser:_drawCoat()
    if not self._layer_event then 
        return "layer_event is null"
    end

    local layer_event = self._layer_event
    local layer_event_size = layer_event:getContentSize()
    local sp_front = self._sp_front
    sp_front:setVisible(true)
    sp_front:setPosition(cc.p(layer_event_size.width / 2, layer_event_size.height / 2))

    self._rt:begin()
    sp_front:visit()
    self._rt:endToLua()

    sp_front:setVisible(false)
end

-- 构建像素映射表
function Eraser:_buildPixelMaps()
    if not self._layer_event then 
        return "layer_event is null"
    end
    local layer_event = self._layer_event
    local layer_event_size = layer_event:getContentSize()
    self._pixel_maps = {}
    for i = 1, layer_event_size.width, 1 do
        local tw = {}
        for j = 1, layer_event_size.height, 1 do
            tw[j] = 0
        end
        self._pixel_maps[i] = tw
    end
end
--默认矩形擦出
function Eraser:_dealEraserCalculate(pos , size)
    if not size then
        size = self._layer_event:getContentSize()
    end
    if Enum.EraserType.RECTANGULAR == self._eraser_type then
        return self:_rectangular(pos , size)
    elseif Enum.EraserType.CIRCLE == self._eraser_type then
        return self:_circle(pos , size)
    end 
    return 0
end
-- 计算矩形擦出
function Eraser:_rectangular(pos , size)
    local start_x = math.floor(pos.x)
    local start_y = math.floor(pos.y)
    local end_x = start_x + size.width
    local end_y = start_y + size.height
    -- 擦出像素数
    local sum_pixel = 0

    local max_size = self._layer_event:getContentSize()
    if end_x > max_size.width then
        end_x = max_size.width
    end
    if end_y > max_size.height then
        end_y = max_size.height
    end
    local pixel_maps = self._pixel_maps
    for i = start_x, end_x, 1 do
        local tw = pixel_maps[i]
        if tw then
            for j = start_y, end_y, 1 do
                tw[j] = 1
                sum_pixel = sum_pixel + 1
            end
        end
    end
    return sum_pixel
end

-- 计算圆形擦出
function Eraser:_circle(pos , size)
    local start_x = math.floor(pos.x - size.width / 2)
    local start_y = math.floor(pos.y)
    local end_x = math.floor(start_x + size.width / 2)
    -- 当前有效的擦除像素数
    local sum_pixel = 0
    -- 圆心坐标
    local circle_ori_p = cc.p(math.floor(pos.x) , start_y)
    local circle_a = circle_ori_p.x
    local circle_b = circle_ori_p.y
    --半径
    local circle_r = size.width / 2 

    local max_size = self._layer_event:getContentSize()
    if end_x > max_size.width then
        end_x = max_size.width
    end 


    local win_rect = self:getEraseWindowRect()
    local win_startx = win_rect.x
    local win_endx = win_rect.x + win_rect.width
    local win_starty = win_rect.y
    local win_endy = win_rect.y + win_rect.height

    local pixel_maps = self._pixel_maps
    -- print("_circle start_x" , start_x , end_x)
    for x = start_x, end_x, 1 do
        local tw = pixel_maps[x]
        if tw then
            -- 开根号(正数)
            local sqrt1 = math.floor(math.sqrt(circle_r * circle_r - math.pow(x- circle_a , 2)))
            -- 求y坐标
            local y1 = sqrt1 + circle_b
            local y2 = -sqrt1 + circle_b
            local tw_value = 0
            -- print("_circle" , y1 , y2 , circle_b , sqrt1 , x , circle_a)
            for y = y2, y1, 1 do 
                tw_value = tw[y]
                -- 只有擦除的像素在有效的窗口内才累计像素数
                if tw_value == 0 and (win_startx < x and x < win_endx and y < win_endy and y > win_starty) then
                    sum_pixel = sum_pixel + 1
                end
                tw[y] = 1 
            end
        end
    end
    return sum_pixel
end
--获取擦出进度
function Eraser:getProgress(is_refresh) 
    local max_size = self._layer_event:getContentSize()
    local win_rect = self:getEraseWindowRect()
    local total = win_rect.width * win_rect.height

    -- 如果不刷新，则用当前累计的擦除像素做被除数
    if not is_refresh and self._total_eraser_pixel_num then 
        return self._total_eraser_pixel_num / total
    end

    local start_x = win_rect.x
    local start_y = win_rect.y
    local end_x = start_x + win_rect.width
    local end_y = start_y + win_rect.height
    local sum = 0

    if start_x > max_size.width or start_x < 1 then
        start_x = 1
    end
    if start_y > max_size.height or start_y < 1 then
        start_y = 1
    end

    if end_x > max_size.width or end_x < 0 then
        end_x = max_size.width
    end

    if end_y > max_size.height or end_x < 0 then
        end_y = max_size.height
    end
    
    local pixel_maps = self._pixel_maps
    for i = start_x, end_x, 1 do
        local tw = pixel_maps[i]
        if tw then
            for j = start_y, end_y, 1 do
                if tw[j] == 1 then
                    sum = sum + 1
                end
            end
        end
    end

    self._total_eraser_pixel_num = sum
    -- print("getProgress 1" , start_x , end_x , start_y , end_y , #pixel_maps)
    -- print("getProgress 2" , win_rect.x , win_rect.y , win_rect.width , win_rect.height , sum , total)

    return sum / total
end
--获取擦出窗口
function Eraser:getEraseWindowRect()
    return self._erase_window_rect
end
-- 注册擦出回调
function Eraser:registerEraseCallback(v)
    self._erase_callback = v
end
-- 注销擦出回调
function Eraser:unregisterEraseCallback()
    self._erase_callback = nil
end
-- 设置擦出类型
function Eraser:setEarserType(v)
    self._eraser_type = v
end
-- 销毁
function Eraser:destory()
    self:removeFromParent()
end
-- 更新混合的精灵
function Eraser:updateBlendSprite(sp_all_path)
    if not sp_all_path then return end
    

    local layer_event = self._layer_event
    local layer_event_size = layer_event:getContentSize()

    local sp_all = cc.Sprite:create(sp_all_path)
    sp_all:setContentSize(layer_event_size)
    layer_event:addChild(sp_all , 3)
    sp_all:setPosition(cc.p(layer_event_size.width / 2, layer_event_size.height / 2))

    local func = cc.blendFunc(gl.ZERO , gl.SRC_ALPHA)
    sp_all:setBlendFunc(func)

    sp_all:setVisible(true)
    self._rt:begin()

    sp_all:visit()

    self._rt:endToLua()
    sp_all:setVisible(false)
    sp_all:removeFromParent()

end











-- 插入一条记录
function Eraser:insertEraserLog(pixelPos, time)
    local d = {}
    d.pixelPos = pixelPos 
    d.time = time
    table.insert(self._record_eraser_log , d)
end
-- 获取擦出记录
function Eraser:getRecordEraserLog()
    return self._record_eraser_log
end

--开始记录
function Eraser:startRecord()
    self:_setRecordStatus(Enum.RecordEraserType.START)
end
-- 停止记录
function Eraser:stopRecord()
    self:_setRecordStatus(Enum.RecordEraserType.STOP)
end
-- 恢复记录
function Eraser:resumeRecord() 
    self._record_status = Enum.RecordEraserType.START
    self:resume()
end

--设置状态
function Eraser:_setRecordStatus(status)
    self._record_status = status
    if status ==  Enum.RecordEraserType.START then
        self:_onStartRecordMraser()
    elseif status ==  Enum.RecordEraserType.PAUSE then
        self:_onPauseRecordMraser()
    elseif status ==  Enum.RecordEraserType.STOP then
        self:_onStopRecordMraser()
    end
end
--获取状态
function Eraser:getRecordStatus(status)
    return self._record_status 
end
-- 开始记录
function Eraser:_onStartRecordMraser()
    if self._record_node then return end
    local record_node = cc.Node:create()
    self._record_node = record_node

    local last_num = 0
    local curr_num = 0
    local start = false
    local interval = cc.Director:getInstance():getAnimationInterval()
    local record_time = 4
    -- 累计时间
    local sum_time = 0
    record_node:runAction(cc.RepeatForever:create(cc.Sequence:create(
        cc.CallFunc:create(function () 
            if self:getRecordStatus() == Enum.RecordEraserType.START then
                if start then
                    curr_num = curr_num + 1
                    sum_time = sum_time + interval
                    -- 如果超出时间 结束
                    -- if sum_time >= record_time then
                    --     self:_setRecordStatus(Enum.RecordEraserType.STOP)
                    --     return
                    -- end
                end
    
                if #self._record_log_frame > 0 then 
                    start = true
                    local dt = interval * (curr_num - last_num)
                    for i, v in ipairs(self._record_log_frame) do
                        self:insertEraserLog(v[1] , dt)
                    end
                    last_num = curr_num
                    self._record_log_frame = {}
                end
                
            end
        end),
        cc.DelayTime:create(0.0)
    ))) 

    self:addChild(record_node)

    self._record_callback = function(pixelPos)
        if self:getRecordStatus() == Enum.RecordEraserType.START then
            table.insert(self._record_log_frame , {
                pixelPos
            })
        end
    end
    
end

-- 暂停记录
function Eraser:_onPauseRecordMraser()
    self:_setStatus(Enum.EraserSatus.PAUSE)
end

function Eraser:clearRecordMarser()
    self._record_eraser_log = {}
end

-- 停止记录
function Eraser:_onStopRecordMraser()

    if self._record_node then
        self._record_node:stopAllActions()
    end

    -- dump(self._record_eraser_log , "操作记录")
    local record_eraser_log = self._record_eraser_log
    -- 停止擦除
    self:_setStatus(Enum.EraserSatus.STOP)

    local jsonstr = tool.lua_to_json(record_eraser_log)

    local rootDir = cc.FileUtils:getInstance():getWritablePath() .. "eraser"

    cc.FileUtils:getInstance():removeDirectory(rootDir)
    cc.FileUtils:getInstance():createDirectory(rootDir)
    local path = rootDir .. "/eraser_log.json"
    local file = io.open(path , "w+")

    if file then
        print("创建文件成功！" , path)
    end


    if cc.FileUtils:getInstance():isFileExist(path) then
        io.close(file)
        cc.FileUtils:getInstance():writeStringToFile(jsonstr , path)
        print("完成数据写入")
    else
        print(path , "文件不存在，创建失败！")
    end
end

-- 停止播放
function Eraser:stopPlayRecord()
    if self._record_node then
        self._record_node:stopAllActions()
    end
end

-- 播放记录
function Eraser:playRecordMraser(record_log , callback)
    if not record_log then return end
    local record_node = self._record_node
    if not record_node then
        record_node = cc.Node:create()
        self:addChild(record_node)
    end
    if record_node then
        record_node:stopAllActions()
    end
    self._record_node = record_node
    local play_action = nil
    play_action = function (index)
        local d = record_log[index]
        if not d then
            if callback then
                callback()
            end
            return
        end 
        record_node:runAction(cc.Sequence:create(
            cc.DelayTime:create(d.time),
            cc.CallFunc:create(function ()  
                self:_doEraser(d.pixelPos)
                play_action(index + 1)
            end)
        ))
    end

    play_action(1)
end

return Eraser