local TableViewScissor = class("TableViewScissor")
local exports = {}

local createTableView = function (parent, size, pos, direction, scroll_func, zoom_func, size_func, spawn_func, nums_func)
	local table_view
	if parent then
        scroll_func = scroll_func or function (view) end
        zoom_func   = zoom_func or function (view) end
		size_func   = size_func or function (table,idx) return 0, 0 end
		spawn_func  = spawn_func or function (table, idx) return nil end
        nums_func   = nums_func or function (table) return 0 end

        table_view = cc.TableView:create(size)
        if table_view then
	        table_view:setDirection(direction)
	        table_view:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
	        table_view:setPosition(pos)
	        table_view:setDelegate()
	        parent:addChild(table_view, 2)

	        table_view:registerScriptHandler(nums_func,   cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  
	        table_view:registerScriptHandler(scroll_func, cc.SCROLLVIEW_SCRIPT_SCROLL)
	        table_view:registerScriptHandler(zoom_func,   cc.SCROLLVIEW_SCRIPT_ZOOM)
	        table_view:registerScriptHandler(size_func,   cc.TABLECELL_SIZE_FOR_INDEX)
	        table_view:registerScriptHandler(spawn_func,  cc.TABLECELL_SIZE_AT_INDEX)
	        table_view:reloadData()
	    end
    end
    return table_view
end

function TableViewScissor:ctor() 

end

function TableViewScissor:run(parent)


    local data = {
        {},
        {},
        {},
        {},
        {},
        {},
        {},
        {},
    }

	local function scrollViewDidScroll(view)

        local pos = view:getContentOffset() 
		print("scrollViewDidScroll" , pos.y)
    end

    local function cellSizeForTable(table, idx) 
        return 200 , 270
    end
 
    local function updateTableCellAtIndex(table, idx)
        local activityIndex = idx + 1 
		local cell  = table:dequeueCell()
		if nil == cell then
			cell = cc.TableViewCell:new()
        end
        if not cell.node then
            local node = exports.TableViewItembNode.new() 
            local toPos = cc.p(0, 0)
            node:setPosition(toPos)
            cell:addChild(node)
            cell.node = node
        end

        cell.node:update()


        return cell
        -- print("tableCellAtIndex" , idx , self.showActivityIndex , self.ctl:getActivityCountByTabIndex(showTabIndex))
    end 
    -- print("configLeftTabNode" , self.showTabIndex , self.ctl:getActivityCountByTabIndex(self.showTabIndex))

    local function numberOfCellsInTableView(table)
        return #data
    end

    local tableView = createTableView(parent , cc.size(200 , 500) , cc.p(200 , 50) , cc.SCROLLVIEW_DIRECTION_VERTICAL,
    scrollViewDidScroll , nil,cellSizeForTable , updateTableCellAtIndex ,numberOfCellsInTableView)
    tableView:setScale(0.5)
    tableView:setRotationClipping(false)

    -- tableView:setClippingToBounds(false)
    local btnMarkList = {}
    for i = 1, 4, 1 do
        local btn = ccui.Button:create ("end01.png", "end01.png", "end01.png")
        btn:setPosition(cc.p(0 , 0))
        parent:addChild(btn)
        btnMarkList[i] = btn
    end


    local function updateTableViewRect()
        local size = cc.size(200 , 500)
        local posList = {}
        posList[1] = tableView:convertToWorldSpace(cc.p(0 , 0))
        posList[2] = tableView:convertToWorldSpace(cc.p(size.width , 0))
        posList[3] = tableView:convertToWorldSpace(cc.p(size.width , size.height))
        posList[4] = tableView:convertToWorldSpace(cc.p(0 , size.height))
        for i, v in ipairs(btnMarkList) do
            v:setPosition(posList[i])
        end
    end
    local oriRotation = 0
    local btn = ccui.Button:create ("end01.png", "end01.png", "end01.png")
    btn:addTouchEventListener(function (sender , eventType)
        if eventType == ccui.TouchEventType.ended then
            oriRotation = oriRotation + 5
            tableView:setRotation(oriRotation)
            local rect = updateTableViewRect()
        end
    end)
    btn:setPosition(cc.p(900 , 400))
    parent:addChild(btn)

 
    local btn = ccui.Button:create ("end01.png", "end01.png", "end01.png")
    btn:addTouchEventListener(function (sender , eventType)
        if eventType == ccui.TouchEventType.ended then
            oriRotation = oriRotation - 5
            tableView:setRotation(oriRotation)
            local rect = updateTableViewRect()
        end
    end)
    btn:setPosition(cc.p(1000 , 400))
    parent:addChild(btn)

 
    local btn3 = ccui.Button:create ("end01.png", "end01.png", "end01.png")
    btn3:addTouchEventListener(function (sender , eventType)
        if eventType == ccui.TouchEventType.ended then
            oriRotation = 0
            tableView:setRotation(0)
        end
    end)
    btn3:setPosition(cc.p(1100 , 400))
    parent:addChild(btn3)

end

local TableViewItembNode = class("TableViewItembNode" , function ()
    return cc.Node:create()
end)
exports.TableViewItembNode = TableViewItembNode
function TableViewItembNode:ctor()
    display.newSprite("HelloWorld.png")
        :move(cc.p(100 , 270 / 2))
        :addTo(self)
end

function TableViewItembNode:update()
    
end

return TableViewScissor
 