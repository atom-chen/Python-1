--
-- Author: zen.zhao88@gmail.com
-- Date: 2014-06-17 17:17:46
--
local scheduler = require("framework.scheduler")
local DisplayManager = class("DisplayManager")

--显示AlertBox
function DisplayManager.showAlertBox(message,delay)
	if not AlertBox then
		return
	end
	local alertBox = AlertBox.new(message)
	if delay then
		alertBox:setDelay(delay)
	end
	display.getRunningScene():addChild(alertBox)
end
-- btnParams = {
-- 	colorTemplate = AlertView.green1ButtonParams, --颜色模板
-- 	title = "", --按钮字
--  callback = function()end,--按钮响应
--  exitCallBack参数主要是应用于弹窗转屏之后任何一个回调都没有响应的情况
-- }
function DisplayManager.showAlertView(title,message,btnParams,exitCallBack,withCloseBtn, closeCallBack)
	local params = {}
	if btnParams then
		for i=1,#btnParams do
			if btnParams[i].colorTemplate then
				local par_ = common.clone(btnParams[i].colorTemplate)
				par_.title = btnParams[i].title
				par_.callback = function ()
					-- if not exitCallBack then
					-- 	GameManager:getAdManager():hiddenNativeMenuAd()
					-- end
					btnParams[i].callback()
				end
				par_.fontSize = btnParams[i].fontSize
				par_.size = btnParams[i].size
				params[#params + 1] = par_
			end
		end
	end
	
	-- GameManager:getAdManager():showNativeMenuAd(0, common.BannerAdPos.NONE)
	local alertView = AlertView.new(title,message,params)
	if exitCallBack then
		alertView:setExitCallBack(function ()
			-- GameManager:getAdManager():hiddenNativeMenuAd()
			exitCallBack()
		end)
	end
	if withCloseBtn then
		alertView:showCloseBtn(closeCallBack)
	end
	display.getRunningScene():addChild(alertView, 10)
end
----
function DisplayManager.showAlertViewWithCoin(title,message,btnParams)
	local params = {}
	if btnParams then
		for i=1,#btnParams do
			if btnParams[i].colorTemplate then
				local par_ = common.clone(btnParams[i].colorTemplate)
				par_.title = btnParams[i].title
				par_.callback = function ()
					-- if not exitCallBack then
					-- 	GameManager:getAdManager():hiddenNativeMenuAd()
					-- end
					btnParams[i].callback()
				end
				par_.fontSize = btnParams[i].fontSize
				par_.size = btnParams[i].size
				params[#params + 1] = par_
			end
		end
	end
	
	-- GameManager:getAdManager():showNativeMenuAd(0, common.BannerAdPos.NONE)
	local alertView = AlertView.new(title,message,params)
	display.getRunningScene():addChild(alertView, 10)
	--添加金币node
	local coinNum_ = GameManager:getUserData():getCoin()
	local node_Coin = display.newNode()
	node_Coin:setPosition(ccp(0, display.height-50))
	alertView:addChild(node_Coin,10)
	local coinBg_ = display.newSprite("#ui_winViewCoinBg.png", 130, 0)
	node_Coin:addChild(coinBg_)
	local coin_ = display.newSprite("#ui_coin.png", 50, 0)
	node_Coin:addChild(coin_)
	node_Coin.LbCoinNum_ = ui.newTTFLabel({text = tostring(coinNum_), size = 30, align = ui.TEXT_ALIGN_CENTER})
        				   :pos(140, 0)
       					   :addTo(node_Coin)
end
----

function DisplayManager.addTouchBackItemAlert()
	if device.platform == "android" then
        -- avoid unmeant back
        -- keypad layer, for android
        local layer = display.newLayer()
         	layer:addKeypadEventListener(function(event)
            -- if event == "back" and not DisplayManager.didShowExit then DisplayManager.showExitGameAlertView() end
            if event == "back" then
            	local open = GameManager:getInstance():judgeCrossPromotion()
            	if open then
			        if DisplayManager.hasCrossPromotion then
			        	return
			        end
			        DisplayManager.delayCrossPromotion()

            		GameManager:getNativeManager():openCrossPromotion(Localization.getGameLanguage(), "true")
            	else
            		DisplayManager.showExitGameAlertView()
            	end
            end
        end)
        layer:setKeypadEnabled(true)
        return layer
    end
    return nil
end

function DisplayManager.showExitGameAlertView()
	if DisplayManager.didShowExit then
		return
	end
	DisplayManager.didShowExit = true

	local btnParams = {
		{
			colorTemplate = AlertView.orangeButtonParams, --颜色模板
			title = Localization.string("是"), --按钮字
		 	callback = function()
		 		EventNoticeManager:getInstance():dispatchEvent({name = Notice.APP_ENTER_BACKGROUND})
			 	app.exit()
		 	end,--按钮响应
		},
		{
			colorTemplate = AlertView.green1ButtonParams, --颜色模板
			title = Localization.string("否"), --按钮字
		 	callback = function() DisplayManager.didShowExit = false end,--按钮响应
		},
	}
	GameManager:getAdManager():hiddenNativeMenuAd()
	DisplayManager.showAlertView(nil,Localization.string("是否退出游戏?"),btnParams,function ()
		DisplayManager.didShowExit = false
	end)
end
---过滤五星评价
function DisplayManager.ignoreFiveStarsPraiseAlertView()
	local btnParams = {
		{
			colorTemplate = AlertView.orangeButtonParams, --颜色模板
			title = Localization.string("否"), --按钮字
		 	callback = function()
		 		DisplayManager.showChallengeTips("谢谢您的反馈",nil,true)
		 		GameManager:getUserData():saveUserData({isDislike = 1})
		 	end,--按钮响应
		},
		{
			colorTemplate = AlertView.green1ButtonParams, --颜色模板
			title = Localization.string("是"), --按钮字
		 	callback = function() 
		 		local viewCtrl = FiveStarsPraiseViewCtrl.new()
   	 			display.getRunningScene():addChild(viewCtrl:getView())
		 	end,--按钮响应
		},
	}
	local title = Localization.string("是否喜欢_标题")
	DisplayManager.showAlertView(title,Localization.string("您是否喜欢我们的游戏_提示"),btnParams,function ()
		DisplayManager.didShowignore = false
	end)
end

function DisplayManager.showChallengeTips( message , args , noIcon)
	if not message or message == "" then
		return
	end
	local fontSize_ = Localization.getLabelFontSize( message )
	local params = {
		size = fontSize_ or 30,
		text = Localization.string(message,args),
	}
	local node = display.newNode()
	local bg = display.newSprite("#tips_bg.png")
	node:addChild(bg)

	local label = ui.newTTFLabel(params)
	node:addChild(label)

	if noIcon then
		local widthLabel = label:getContentSize().width
	else
		local icon = display.newSprite("#icon_calendar2.png")
		node:addChild(icon)

		local widthIcon = icon:getContentSize().width
		local widthLabel = label:getContentSize().width

		icon:setPositionX(-(widthLabel+10)/2)
		label:setPositionX((widthIcon+10)/2)
	end

	display.getRunningScene():addChild(node)
	node:setPosition(ccp(display.width/2, -100))

	local move = CCMoveTo:create(0.3, ccp(display.width/2, 200))
	local delay = CCDelayTime:create(1.7)
	local move1 = CCMoveTo:create(0.3, ccp(display.width/2, -100))
	local call = CCCallFunc:create(function ( )
		node:removeSelf()
	end)
	node:runAction(transition.sequence({
 		CCEaseSineIn:create(move),
 		delay,
 		CCEaseSineIn:create(move1),
 		call,
		}))
end

function DisplayManager.delayCrossPromotion( )
	DisplayManager.hasCrossPromotion = true
	scheduler.performWithDelayGlobal(function ( )
		DisplayManager.hasCrossPromotion = false
	end, 0.5)
end

--显示网络loading页面
-- function DisplayManager.showNetworkLoading()
-- 	local scene = display.getRunningScene()
-- 	if not scene then
-- 		scheduler.performWithDelayGlobal(function()
-- 			DisplayManager.showNetworkLoading()
-- 			end, 1)
-- 		return
-- 	end
-- 	local loadingView = scene:getChildByTag(1003)
-- 	if not loadingView then
-- 		loadingView = NETLoadingView.new()
-- 		scene:addChild(loadingView,999,1003)
-- 	end
-- 	loadingView:setVisible(true)
-- 	loadingView:play()
-- end

--隐藏网络loading页面
-- function DisplayManager.hiddenNetworkLoading()
-- 	local scene = display.getRunningScene()
-- 	if not scene then
-- 		scheduler.performWithDelayGlobal(function()
-- 			DisplayManager.hiddenNetworkLoading()
-- 			end, 1)
-- 		return
-- 	end
-- 	local loadingView = scene:getChildByTag(1003)
-- 	if loadingView then
-- 		loadingView:stop()
-- 		loadingView:setVisible(false)
-- 	end
-- end

return DisplayManager