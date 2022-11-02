
local MainScene = class("MainScene", cc.load("mvc").ViewBase)
function MainScene:onCreate()
    -- add background image
    display.newSprite("HelloWorld.png")
        :move(display.center)
        :addTo(self)

    -- add HelloWorld label
    cc.Label:createWithSystemFont("Hello World", "Arial", 40)
        :move(display.cx, display.cy + 200)
        :addTo(self)


    local aa = require("app/views/ClientConfig")

    for k, v in pairs(aa) do
        print("MainScene" , k , v)
    end

    -- self:testErase()
    self:testTableView()-- TableViewScissor


    -- local draw = cc.DrawNode:create()

    -- draw:drawDot(display.center , 50 ,  cc.c4f(1 , 1 , 0 , 1))

    -- self:addChild(draw)

end

function MainScene:testTableView()
    local TableViewTest = require("app/views/TableViewTest")
    TableViewTest:run(self)
end

function MainScene:testErase()
    local Eraser = require("app/views/Eraser")
    local eraser = Eraser.new({
        bg_sp_path = "lobby_img02.png" ,
        front_sp_path = "lobby_img03.png" ,
        point_sp_path = "kong.png" ,
        erase_window_rect = cc.rect(0 , 150 , nil , 200)
    })
    eraser:setEarserType(Eraser.Enum.EraserType.CIRCLE)
    eraser:setPosition(cc.p(307 / 2 + 200, 474 / 2))
    eraser:registerEraseCallback(function (ty , pro , pixel_num)
        -- print("registerEraseCallback" , ty , pro , pixel_num) 
        if ty == "stop" then
            eraser:reset()
            eraser:playRecordMraser(eraser:getRecordEraserLog() , function ()
                print("自动擦出结束")
                -- eraser:destory()
                eraser:reset()
                eraser:startRecord()
            end)
        end
    end)
    eraser:startRecord()
    self:addChild(eraser)
end

return MainScene
