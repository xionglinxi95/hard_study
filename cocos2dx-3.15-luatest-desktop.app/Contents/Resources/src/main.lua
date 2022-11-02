
cc.FileUtils:getInstance():setPopupNotify(false)
CC_DISABLE_GLOBAL = false
require "config"
require "cocos.init"

local function main()
    -- require("app.MyApp"):create():run()
    require("testResource")
    require("controller")
end

local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
    print(msg)
end
