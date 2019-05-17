--
-- Author: Huang Hai Long
-- Date: 2015-01-26 14:50:24
--
local UserDataModel = import("..model.UserDataModel")
local UserCacheModel = import("..model.UserCacheModel")
local UserClassicDataModel = import("..model.UserClassicDataModel")
local UserGameCacheDataModel = import("..model.UserGameCacheDataModel")
local UserSeedDataModel = import("..model.UserSeedDataModel")
local UserChallengeDataModel = import("..model.UserChallengeDataModel")
local UserAudioDataModel = import("..model.UserAudioDataModel")
local UserADDataModel = import("..model.UserADDataModel")
local UserChargeDataModel = import("..model.UserChargeDataModel")
local UserCompitionDataModel = import("..model.UserCompitionDataModel")
local UserDayDataModel = import("..model.UserDayDataModel")
local UserCompitionRankDataModel = import("..model.UserCompitionRankDataModel")
local UserThemeDataModel = import("..model.UserThemeDataModel")
local UserStoreDataModel = import("..model.UserStoreDataModel")


local CacheDataModel = import("..model.CacheDataModel")

local NetworkErrorManager = import(".NetworkErrorManager")

local AdManager = import(".AdManager")
local PayManager = import(".PayManager")


local LCClient = import("..LeanCloud.LCClient")

local GameManager = class("GameManager")
--[[
类方法
]]

function GameManager:getInstance()
	local o = _G.gameManager_
	if o then
		return o
	end

	o = GameManager.new()
	_G.gameManager_ = o
	
	return o
end

function GameManager:clean()
	if EventNoticeManager then
		EventNoticeManager:getInstance():removeEventListenerForHandle(self)
	end
	app:removeEventListener(Notice.APP_ENTER_BACKGROUND,self)
	app:removeEventListener(Notice.APP_ENTER_FOREGROUND,self)
	tools.closeUserDB()
	_G.gameManager_ = false
end

-- GameManager.MODETYPE_HALL = "hall"

--此处必须与GAME_MODE保持同一字符串，否则一些判断会有问题 例：ChallengeSelectViewCtrl:tapGame 中的判断
GameManager.MODETYPE_SOLITAIRE = GAME_MODE_SOLITAIRE--"classic"
GameManager.MODETYPE_FREECELL = GAME_MODE_FREECELL--"freeCell"
GameManager.MODETYPE_SPIDER = GAME_MODE_SPIDER--"spider"
GameManager.MODETYPE_TRIPEAKS = GAME_MODE_TRIPEAKS--"tripeaks"
GameManager.MODETYPE_PYRAMID = GAME_MODE_PYRAMID--"pyramid"

GameManager.DIFFTIME = 30*60*1000--毫秒--第一次打开游戏时间间隔打开锁屏广告cell

function GameManager:setModeType(modeType)
	local o = GameManager:getInstance()
	o.modeType_ = modeType
end
function GameManager:getModeType()
	if GAME_MODE == GAME_MODE_SOLITAIRE then
		return GameManager.MODETYPE_SOLITAIRE
	end
	if GAME_MODE == GAME_MODE_FREECELL then
		return GameManager.MODETYPE_FREECELL
	end
	if GAME_MODE == GAME_MODE_SPIDER then
		return GameManager.MODETYPE_SPIDER
	end
	if GAME_MODE == GAME_MODE_PYRAMID then
		return GameManager.MODETYPE_PYRAMID
	end
	if GAME_MODE == GAME_MODE_TRIPEAKS then
		return GameManager.MODETYPE_TRIPEAKS
	end
	local o = GameManager:getInstance()
	return o.modeType_
end

function GameManager:getUserData()
	local o = GameManager:getInstance()
	return o.userDM_
end

function GameManager:getUserCache()
	local o = GameManager:getInstance()
	return o.userCache_
end

function GameManager:getUserCompitionData()
	local o = GameManager:getInstance()
	return o.userCompitionDM_
end

function GameManager:getUserDayData()
	local o = GameManager:getInstance()
	return o.userDayDataDM_
end

function GameManager:getUserThemeData()
	local o = GameManager:getInstance()
	return o.userThemeDataDM_
end

function GameManager:getUserStoreData()
	local o = GameManager:getInstance()
	return o.userStoreDataDM_
end

function GameManager:getUserClassicData()
	local o = GameManager:getInstance()
	return o.classicDM_
end

function GameManager:getUserGameCacheData(modeType)
	local o = GameManager:getInstance()
	modeType = modeType or o.modeType_
	if GAME_MODE == GAME_MODE_COLLECTION then
		if modeType == GameManager.MODETYPE_SOLITAIRE then
			return o.gameCacheSolitaireDM_
		elseif modeType == GameManager.MODETYPE_FREECELL then
			return o.gameCacheFreeCellDM_
		elseif modeType == GameManager.MODETYPE_SPIDER then
			return o.gameCacheSpiderDM_
		elseif modeType == GameManager.MODETYPE_TRIPEAKS then
			return o.gameCacheTriPeaksDM_
		elseif modeType == GameManager.MODETYPE_PYRAMID then
			return o.gameCachePyramidDM_
		end
	end
	return o.gameCacheDM_
end

function GameManager:getUserSeedData()
	local o = GameManager:getInstance()
	return o.seedDM_
end

function GameManager:getUserChallengeData(modeType)
	local o = GameManager:getInstance()
	modeType = modeType or o.modeType_
	if GAME_MODE == GAME_MODE_COLLECTION then
		if modeType == GameManager.MODETYPE_SOLITAIRE then
			return o.challengeSolitaireDM_
		elseif modeType == GameManager.MODETYPE_FREECELL then
			return o.challengeFreeCellDM_
		elseif modeType == GameManager.MODETYPE_SPIDER then
			return o.challengeSpiderDM_
		elseif modeType == GameManager.MODETYPE_TRIPEAKS then
			return o.challengeTriPeaksDM_
		elseif modeType == GameManager.MODETYPE_PYRAMID then
			return o.challengePyramidDM_
		end
	end
	return o.challengeDM_
end

function GameManager:getUserChargeData( )
	local o = GameManager:getInstance()
	return o.chargeDM_
end

function GameManager:getCacheData( )
	local o = GameManager:getInstance()
	return o.cacheDataM_
end

function GameManager:getUserADData()
	local o = GameManager:getInstance()
	return o.adDM_
end

function GameManager:getAdManager()
	local o = GameManager:getInstance()
	return o.adManager_
end

function GameManager:getPayManager()
	local o = GameManager:getInstance()
	return o.payManager_
end

function GameManager:getNetImageManager()
	local o = GameManager:getInstance()
	return o.netImageManager_
end

function GameManager:getAudioData()
	local o = GameManager:getInstance()
	return o.audioDM_
end

function GameManager:getCompitionRankData()
	local o = GameManager:getInstance()
	return o.compitionRankDM_
end

function GameManager:getRedNoticeManager()
	local o = GameManager:getInstance()
	return o.redNoticeManager_
end

function GameManager:getInstalledThemeKey( )
	local o = GameManager:getInstance()
	return o.installedThemeKey_
end

function GameManager:getDailyType( )
	local o = GameManager:getInstance()
	if GAME_MODE == GAME_MODE_COLLECTION then
		return o.modeType_
	end
	return GAME_MODE
end

--[[
实例方法
]]

function GameManager:ctor()
	--重连次数
	self.reconnection_ = 0 
	self.popViewStack_ = {}
	--
	--初始化游戏类型
		printf("======================================================================================================" .. GAME_MODE)
		printf("======================================================================================================" .. GAME_MODE_FREECELL)

	GAME_MODE = ResManager.getGameMode() or GAME_MODE
	if GAME_MODE == GAME_MODE_SOLITAIRE then
		self.modeType_ = GameManager.MODETYPE_SOLITAIRE
	elseif GAME_MODE == GAME_MODE_FREECELL then
		self.modeType_ = GameManager.MODETYPE_FREECELL
	elseif GAME_MODE == GAME_MODE_SPIDER then
		self.modeType_ = GameManager.MODETYPE_SPIDER
	elseif GAME_MODE == GAME_MODE_TRIPEAKS then
		self.modeType_ = GameManager.MODETYPE_TRIPEAKS
	elseif GAME_MODE == GAME_MODE_PYRAMID then
		self.modeType_ = GameManager.MODETYPE_PYRAMID
	elseif GAME_MODE == GAME_MODE_COLLECTION then
		self.modeType_ = GameManager.MODETYPE_SOLITAIRE
	end

	-- GameManager.MODETYPE_HALL
	-- GameManager.MODETYPE_SOLITAIRE 
	-- GameManager.MODETYPE_FREECELL
	-- GameManager.MODETYPE_SPIDER
	if self:judgeIsLiteVersion() then
		GAME_MODE = GAME_MODE_SOLITAIRE
	end

	self:addEventListen_()
	self:initDataModel_()

	self:initNetWork_()

	self:initPayManager_()

	self.nativeManager_ = NativeManager.new(handler(self, self.nativeCallBack_))
	self:initNetImageManager_()
	
	self:createUpdataTimer()
	self:startTimer()

	-- self:addAdTestValue( )
end

function GameManager:addAdTestValue( )
    self.adTestLb_ = ui.newTTFLabel({size = 20,text = "0000"})
    self.adTestLb_:setPosition(display.cx, 200)
    display.getRunningScene():addChild(self.adTestLb_,99999999)
end

function GameManager:updateAdTestValue( )
	if not self.adTestLb_ then
		return
	end
	local isRewardVideoReady_ = GameManager:getAdManager():isRewardVideoReady()
	local isNativeBannerReady_ = GameManager:getAdManager():isNativeBannerReady()
	local isBannerReady_ = GameManager:getAdManager():isBannerReady()
	local isInterstitialReady_ = GameManager:getAdManager():isInterstitialReady()
	local str_ = "reward:" .. tostring(isRewardVideoReady_) .. "\nnativebanner:" .. tostring(isNativeBannerReady_) .. "\ninterstitial:" .. tostring(isInterstitialReady_) .. "\nbanner:" .. tostring(isBannerReady_)
	self.adTestLb_:setString(str_)
	local fontSize_ = self.adTestLb_:getFontSize()
	fontSize_ = fontSize_ + 1
	if fontSize_ > 30 then
		fontSize_ = 20
	end
	self.adTestLb_:setFontSize(fontSize_)
end

GameManager.JUDGE_ADINFO_CD = 60*60*2 --2小时

function GameManager:judgeAdInfo()
	-- if not self.netWork_ then
	-- 	return
	-- end
	-- if not self.adDM_ then
	-- 	return
	-- end
	-- -- if not self.nativeManager_ then
	-- -- 	return
	-- -- end
	-- local timestamp_ = self.adDM_:getProperty("timestamp")
	-- local duration_ = os.time() - timestamp_
	-- if duration_ < GameManager.JUDGE_ADINFO_CD then
	-- 	return
	-- end

	-- local packageName_ = NativeManager.getADPackageName()
	-- local platform_ = device.platform
	-- if DEBUG ~= 0 then
	-- 	packageName_ = "com.cardgame.solitaire.basic1"
	-- 	platform_ = "android"
	-- end
	
	-- self.netWork_:adControlInfo({packageName = packageName_,platform = platform_})
end

function GameManager:initAdManager()
	self.adManager_ = AdManager.new(self.adDM_)
	EventNoticeManager:getInstance():addEventListener(self,Notice.USER_AD_DATA_CHANGE,function()
			if self.adManager_ then
				-- self.adManager_:preLoadInterstitialAD()
				-- self.adManager_:preLoadBannerAD()
				-- self.adManager_:preLoadAllNativeAD()
				-- self.adManager_:setConfigConst()
				-- self.adManager_:setNativeAdTemplate()
			end
		end)
	self:judgeAdInfo()
end


function GameManager:initNetImageManager_()
	self.netImageManager_ = NetImageManager.new(UserDB)
end

function GameManager:initPayManager_()
	self.payManager_ = PayManager.new()
end

function GameManager:pushViewToStack( viewName )
	self.popViewStack_[#self.popViewStack_ + 1] = viewName
end

function GameManager:popViewOutStack( viewName )
	if self.popViewStackLock_ then
		return
	end
	if self.popViewStack_[#self.popViewStack_] == viewName then
		self.popViewStack_[#self.popViewStack_] = nil
	end
end

function GameManager:nativeCallBack_( data )
	if not data then
		return
	end
	
	if data and type(data) == "string" then
		data = json.decode(data)
	end


	if data.main == "installedTheme" then
		--安装新主题
		self.installedThemeKey_ = tostring(data.themeName)
		ResManager:readInstalledTheme()
		EventNoticeManager:getInstance():dispatchEvent({name = Notice.USER_INSTALLEDNEWTHEME})
	elseif data.main == "exitGame" then
		--从交叉推广退出游戏
		EventNoticeManager:getInstance():dispatchEvent({name = Notice.APP_ENTER_BACKGROUND})
		app.exit()
	elseif data.main == "configConstant" then
		--收到配置表

		local configData = json.decode(data.config)
		if configData and self.userDM_ and self.userCache_ then
			local data_ = {}
			data_.ConfigConstant = configData
			self.userDM_:parseData(data_)

			self.userCache_:parseData(data_)

			if data_.ConfigConstant and data_.ConfigConstant.weightGroup then
				common.onUserProperty("user_group",data_.ConfigConstant.weightGroup)
			end
		end
	elseif data.main == "CPRedPoint" then
		--交叉推广红点数值
		local version = data.version or 0
		local showIcon = data.showIcon or 0
		local countLimit = data.countLimit or 0
		if self.userDM_ then
			self.userDM_:updateCPRedPointVer(version)
		end
		if self.cacheDataM_ then
			self.cacheDataM_:setCPVisible(showIcon, countLimit)
		end
	elseif data.main == "orientationChange" then
		--游戏旋转屏
		local changeTo_ = tostring(data.orientation)
		if CONFIG_SCREEN_ORIENTATION == changeTo_ then
			return
		end
		local gView = CCDirector:sharedDirector():getOpenGLView()
		local size = gView:getFrameSize()
		if changeTo_ == "landscape" then
			gView:setFrameSize(size.height, size.width)

			self:screenChange(size.height, size.width, USER_SCREEN_HEIGHT, USER_SCREEN_WIDTH, "FIXED_HEIGHT")
		elseif changeTo_ == "portrait" then
			gView:setFrameSize(size.height, size.width)

			self:screenChange(size.height, size.width, USER_SCREEN_WIDTH, USER_SCREEN_HEIGHT, "FIXED_WIDTH")
		end
	-- elseif data.main == "native_ad" then
	-- 	local state = data.state
	-- 	if state == "ad_info_hide" then
	-- 		EventNoticeManager:getInstance():dispatchEvent({name = Notice.USER_NATIVE_AD_STATE_CHANGE, adShow = false})
	-- 	elseif state == "ad_info_show" then
	-- 		EventNoticeManager:getInstance():dispatchEvent({name = Notice.USER_NATIVE_AD_STATE_CHANGE, adShow = true})
	-- 	end
	elseif data.main == "googleApiClientOnConnected" or data.main == "gameCenterAuthenticated" then
		--googleApiClient登陆成功通知
		self.userDM_:saveUserData({isGoogleApiClientLogined = 1})
	elseif data.main == "shareGame" then
		if data.completed and data.completed == "true" then
			if self.userDM_ and self.userDM_:getProperty("isShare") == 0 then
				self.userDM_:saveUserData({isShare = 1})
				local btnParams = {
					{
						colorTemplate = AlertView.orangeButtonParams, --颜色模板
						title = Localization.string("是"), --按钮字
					 	callback = function()
					 	end,--按钮响应
					},
				}
				DisplayManager.showAlertView(nil,Localization.string("解锁卡背提示"),btnParams)
			end
		end
	elseif data.main == "memoryWarning" then --当收到底层的内存警告时
		if self.netImageManager_ then
			self.netImageManager_:cleanUnusedImage()
		end
	elseif data.main == "receiveLocalNotification" then
		--todo
		common.pushEnterGameDot()
	end

end

function GameManager:screenChange( w, h, des_w, des_h, des_mode )
	local scaleX, scaleY
    if type(CONFIG_SCREEN_AUTOSCALE_CALLBACK) == "function" then
        scaleX, scaleY = CONFIG_SCREEN_AUTOSCALE_CALLBACK(w, h, device.model)
    end

    if not scaleX or not scaleY then
        scaleX, scaleY = w / des_w, h / des_h
    end

    if des_mode == "FIXED_WIDTH" then
        scale = scaleX
        des_h = h / scale
    elseif des_mode == "FIXED_HEIGHT" then
        scale = scaleY
        des_w = w / scale
    else
        scale = 1.0
        printError(string.format("display - invalid CONFIG_SCREEN_AUTOSCALE \"%s\"", CONFIG_SCREEN_AUTOSCALE))
    end

    local gView = CCDirector:sharedDirector():getOpenGLView()
    gView:setDesignResolutionSize(des_w, des_h, kResolutionNoBorder)

	local winSize = CCDirector:sharedDirector():getWinSize()
	display.contentScaleFactor = scale
	display.size               = {width = winSize.width, height = winSize.height}
	display.width              = display.size.width
	display.height             = display.size.height
	display.cx                 = display.width / 2
	display.cy                 = display.height / 2
	display.c_left             = -display.width / 2
	display.c_right            = display.width / 2
	display.c_top              = display.height / 2
	display.c_bottom           = -display.height / 2
	display.left               = 0
	display.right              = display.width
	display.top                = display.height
	display.bottom             = 0
	display.sizeInPixels = {width = w, height = h}
	display.widthInPixels      = display.sizeInPixels.width
	display.heightInPixels     = display.sizeInPixels.height

	self:resetAllView()
end

function GameManager:resetAllView( )
	self.popViewStackLock_ = true
	if self.audioDM_ then
		self.audioDM_:setPlayEffectEnable(false)
	end
	EventNoticeManager:getInstance():dispatchEvent({name = Notice.USER_SCREEN_CHANGE})
end

-- 设置定时器
--[[--
_time: 总倒计时
_name: 事件名称
_handle: 响应事件
_interval:响应间隙
]]
function GameManager:createTimerEvent(_time,_name,_handle,_interval)
	self.timer_ = nil
	local Timer = require("framework.api.Timer")
	self.timer_ = Timer.new()
	-- 注册事件
    self.timer_:addEventListener(_name, _handle)
    -- 每 1 秒更新一次界面显示
    self.timer_:addCountdown(_name, _time, _interval)
end

-- 创建更新活力定时器
function GameManager:createUpdataTimer()
    self:createTimerEvent(99999,Notice.MANAGER_TIME_UPDATA,handler(self, self.onUpdataTimer),1)
end

function GameManager:startTimer()
	self.timeIsStop_ = false
	if self.timer_ then
		self.timer_:start()
	end
end

function GameManager:stopTimer()
	self.timeIsStop_ = true
	if self.timer_ then
		self.timer_:stop()
	end
end

function GameManager:startTiming()
	self.timeIsStop_ = false
end

function GameManager:stopTiming()
	self.timeIsStop_ = true
end

-- 响应 UPDATA_TIMER 事件
function GameManager:onUpdataTimer(event)
	-- printf("onUpdataTimer")
	EventNoticeManager:getInstance():dispatchEvent({name = Notice.MANAGER_TIME_UPDATA})
    if event.countdown > 0 then
       
        if self.timeIsStop_ then
        	return
        end

        if self.audioDM_ then
        	self.audioDM_:onUpdataTimer()
        end

        if self.netImageManager_ then
        	self.netImageManager_:onUpdataTimer()
        end

        if self.redNoticeManager_ then
        	self.redNoticeManager_:onUpdateTimer()
        end

        if self.userCache_ then
        	self.userCache_:onUpdateTimer()
        end

        -- self:updateAdTestValue()
    else
    	-- 倒计时已经结束
    	self:createUpdataTimer()
    	self:startTimer()
    end
end

function GameManager:setMainSceneHandle(scene)
	local o = GameManager:getInstance()
	o.mainScene_ = scene
end

function GameManager:getBattleManager()
	--不建议使用此方法调用BattleManager的函数
	--使用callBattleManagerMethod
	return self.battleManager_
end

function GameManager:getNativeManager( )
	local o = GameManager:getInstance()
	return o.nativeManager_
end

function GameManager:getMainViewCtrl()
	return self.viewCtrl
end

function GameManager:supportTips( )
    local isDailyChallenge = GameManager:getUserGameCacheData():isDailyChallenge()
    if isDailyChallenge then
    	local challengingData = GameManager:getUserChallengeData():getProperty("challengingData")
    	if challengingData and challengingData:isTips() == false then
    		return false
    	end
    end
    return true
end

--todo
function GameManager:callBattleManagerMethod( method, ... )
	local args = {...}
	if not method or method == "" then
		return
	end
	if method == "starNewGame" then
		GameManager:getInstance():addInterstitialAD(1)
	end
	if self.battleManager_ and self.battleManager_[method] then
		return self.battleManager_[method](self.battleManager_, ...)
	end
end

function GameManager:requestOpenDailyChallenge( addCrown )
	if (FREECELL_BASIC and GAME_MODE == GAME_MODE_FREECELL) or 
		(SPIDER_BASIC and GAME_MODE == GAME_MODE_SPIDER) or
		(TRIPEAKS_BASIC and GAME_MODE == GAME_MODE_TRIPEAKS) or
		(PYRAMID_BASIC and GAME_MODE == GAME_MODE_PYRAMID) then
		return
	end
    local temp = os.date("*t", os.time())
    local modle = GameManager:getUserChallengeData()
    if modle:getMonthData(modle.curYear_, modle.curMonth_) 
    	and modle.curYear_ == temp.year and modle.curMonth_ == temp.month and modle.curDay_ == temp.day then
        EventNoticeManager:getInstance():dispatchEvent({name = Notice.USER_COMPLETE_DAILYCHALLENGE,add = addCrown})
    else
        local senconds = GameManager:getNativeManager():getSecondsFromGMT()
        GameManager:getUserChallengeData():requestDailyChallenge({secondsFromGMT = senconds})
    end
end

GameManager.BATTLE_SINGLE = 1 --单人游戏
GameManager.BATTLE_AI = 2 --人机游戏

function GameManager:changeBattleManagerBy(battleType,compitionVO,list,call)
	local scene = nil
	if self.viewCtrl and self.viewCtrl:getView() then
		scene = self.viewCtrl:getView():getParent()
		self.viewCtrl:getView():removeSelf(true)
	else
		scene = display.getRunningScene()
	end
	if not scene then
		return
	end

	--改变卡牌缩放比
	if battleType == GameManager.BATTLE_AI then
		CardDefine.scaleRate = 0.86
		GameManager:getNativeManager():setScreenAutoRotation(false)
	else
		CardDefine.scaleRate = 1
	end
	
	self:initMainViewCtrl_(battleType)
	scene:addChild(self.viewCtrl:getView())

	if GAME_MODE == GAME_MODE_COLLECTION then
		if battleType == GameManager.BATTLE_AI then
			self:changeMode(self.modeType_,battleType,compitionVO,list)
		else
			self:backToHall()
		end
	else
		self:initBattleManager_(battleType,compitionVO,list)
		self.viewCtrl.battle_node:addChild(self.battleManager_)

		--设置主题
		self.viewCtrl:setTheme()
		self.viewCtrl:setParticle()
	end
	
	

	if call then
		call(compitionVO)
	end
end

function GameManager:initMainViewCtrl_(battleType)
	if battleType == GameManager.BATTLE_AI then
		self.viewCtrl = BattleMainViewCtrl.new(CONFIG_SCREEN_ORIENTATION == "portrait")
	else
		self.viewCtrl = MainViewCtrl.new()
	end
end

--todo 
function GameManager:initBattleManager_(battleType,compitionVO,list,modeType)
	if battleType == GameManager.BATTLE_AI then
		self.modeType_ = GameManager.MODETYPE_SOLITAIRE
		self.battleManager_ = BattleManagerAI.new(self.viewCtrl,compitionVO,list)
	else
		if GAME_MODE == GAME_MODE_FREECELL 
			or (GAME_MODE == GAME_MODE_COLLECTION and modeType == GameManager.MODETYPE_FREECELL) then
			self.modeType_ = GameManager.MODETYPE_FREECELL
			self.battleManager_ = BattleManagerFreeCell.new(self.viewCtrl)
		elseif GAME_MODE == GAME_MODE_SPIDER 
			or (GAME_MODE == GAME_MODE_COLLECTION and modeType == GameManager.MODETYPE_SPIDER) then
			self.modeType_ = GameManager.MODETYPE_SPIDER
			self.battleManager_ = BattleManagerSpider.new(self.viewCtrl)
		elseif GAME_MODE == GAME_MODE_TRIPEAKS 
			or (GAME_MODE == GAME_MODE_COLLECTION and modeType == GameManager.MODETYPE_TRIPEAKS) then
			self.modeType_ = GameManager.MODETYPE_TRIPEAKS
			self.battleManager_ = BattleManagerTriPeaks.new(self.viewCtrl)
		elseif GAME_MODE == GAME_MODE_PYRAMID 
			or (GAME_MODE == GAME_MODE_COLLECTION and modeType == GameManager.MODETYPE_PYRAMID) then
			self.modeType_ = GameManager.MODETYPE_PYRAMID
			self.battleManager_ = BattleManagerPyramid.new(self.viewCtrl)
		elseif GAME_MODE == GAME_MODE_SOLITAIRE 
			or (GAME_MODE == GAME_MODE_COLLECTION and modeType == GameManager.MODETYPE_SOLITAIRE) then
			self.modeType_ = GameManager.MODETYPE_SOLITAIRE
			self.battleManager_ = BattleManager.new(self.viewCtrl)
		end

		--新手引导
	    if GameManager:getUserData():getIsGuide() == 0 then
	        local viewCtrl = GuideViewCtrl.new()
	        display.getRunningScene():addChild(viewCtrl:getView())
	    end
	end
end

function GameManager:backToHall()
	if GAME_MODE ~= GAME_MODE_COLLECTION then
		return
	end
	if self.battleManager_ then
		if self.battleManager_.gameEnterBackground_ then
			self.battleManager_.gameEnterBackground_()
		end

		self.battleManager_:removeSelf(true)
		self.battleManager_ = nil
	end
	if self.viewCtrl.setViewType then
		self.viewCtrl:setViewType(MainViewCtrl.VT_HALL)
	end
end

function GameManager:changeMode(modeType,battleType,compitionVO,list)
	if GAME_MODE ~= GAME_MODE_COLLECTION then
		return
	end
	battleType = battleType or GameManager.BATTLE_SINGLE

	if self.battleManager_ then
		self.battleManager_:removeSelf(true)
		self.battleManager_ = nil
	end

	self:initBattleManager_(battleType,compitionVO,list,modeType)
	if self.viewCtrl.setViewType then
		self.viewCtrl:setViewType(MainViewCtrl.VT_GAME)
	end
	
	self.viewCtrl.battle_node:addChild(self.battleManager_)
	--设置主题
	self.viewCtrl:setTheme()
	self.viewCtrl:setParticle()

	local audio_ = GameManager:getAudioData()
    if audio_ then
        audio_:playAudio(common.effectSoundList.ui_open)
    end
end

function GameManager:createBattleNode_()
	if GAME_MODE == GAME_MODE_COLLECTION then
		if self.battleManager_ then
			self:changeMode(self.modeType_)
		else
			self:backToHall()
		end
		return
	end

	self:initBattleManager_(GameManager.BATTLE_SINGLE,nil,nil,self.modeType_)
	self.viewCtrl.battle_node:addChild(self.battleManager_)
	--设置主题
	self.viewCtrl:setTheme()
	self.viewCtrl:setParticle()
end

function GameManager:addViewsTo(scene, recover)
	local list = common.clone(self.popViewStack_)
	self.popViewStack_ = {}
	self.popViewStackLock_ = false
	self:initMainViewCtrl_(GameManager.BATTLE_SINGLE)
	scene:addChild(self.viewCtrl:getView())
	--NETWORK LOADING
	local networkLoading = NETLoadingViewCtrl.new()
	scene:addChild(networkLoading:getView(), 999)

	self:createBattleNode_()
	-- self:initBattleManager_(GameManager.BATTLE_SINGLE)
	-- self.viewCtrl.battle_node:addChild(self.battleManager_)
	-- --设置主题
	-- self.viewCtrl:setTheme()
	-- self.viewCtrl:setParticle()

	if recover then
		--恢复弹窗
		for i=1,#list do
			local viewCtrl = _G[list[i]].new()
			if viewCtrl.setBanPopAnimation then
				viewCtrl:setBanPopAnimation(true)
			end
			scene:addChild(viewCtrl:getView())
		end
	end
	if self.audioDM_ then
		self.audioDM_:setPlayEffectEnable(true)
	end
end

function GameManager:addEventListen_()
	app:addEventListener(Notice.APP_ENTER_BACKGROUND,handler(self,self.gameEnterBackground_))
	app:addEventListener(Notice.APP_ENTER_FOREGROUND,handler(self,self.gameEnterForeground_))
end

function GameManager:initDataModel_()

    tools.initUserDB()
    self.userCache_ = UserCacheModel.new(UserDB)
	self.userDM_ = UserDataModel.new(UserDB)
	self.classicDM_ = UserClassicDataModel.new(UserDB, self.userDM_)
	self.seedDM_ = UserSeedDataModel.new(UserDB)

	if GAME_MODE == GAME_MODE_COLLECTION then
		self.gameCacheSolitaireDM_ = UserGameCacheDataModel.new(UserDB, self.userDM_,GameManager.MODETYPE_SOLITAIRE)
		self.gameCacheFreeCellDM_ = UserGameCacheDataModel.new(UserDB, self.userDM_,GameManager.MODETYPE_FREECELL)
		self.gameCacheSpiderDM_ = UserGameCacheDataModel.new(UserDB, self.userDM_,GameManager.MODETYPE_SPIDER)
		if PackageConfigDefine.isCollectFlat() then
			self.gameCacheTriPeaksDM_ = UserGameCacheDataModel.new(UserDB, self.userDM_,GameManager.MODETYPE_TRIPEAKS)
			self.gameCachePyramidDM_ = UserGameCacheDataModel.new(UserDB, self.userDM_,GameManager.MODETYPE_PYRAMID)
		end


    	self.challengeSolitaireDM_ = UserChallengeDataModel.new(UserDB, GameManager.MODETYPE_SOLITAIRE)
		self.challengeFreeCellDM_ = UserChallengeDataModel.new(UserDB, GameManager.MODETYPE_FREECELL)
		self.challengeSpiderDM_ = UserChallengeDataModel.new(UserDB, GameManager.MODETYPE_SPIDER)
		if PackageConfigDefine.isCollectFlat() then
			self.challengeTriPeaksDM_ = UserChallengeDataModel.new(UserDB, GameManager.MODETYPE_TRIPEAKS)
			self.challengePyramidDM_ = UserChallengeDataModel.new(UserDB, GameManager.MODETYPE_PYRAMID)
		end
	else
		self.challengeDM_ = UserChallengeDataModel.new(UserDB)
    end

    self.gameCacheDM_ = UserGameCacheDataModel.new(UserDB, self.userDM_)
	self.adDM_ = UserADDataModel.new(UserDB)
	self.chargeDM_ = UserChargeDataModel.new(UserDB)
    self.userCompitionDM_ = UserCompitionDataModel.new(UserDB)
    self.userDayDataDM_ = UserDayDataModel.new(UserDB)
    self.userThemeDataDM_ = UserThemeDataModel.new(UserDB)
    self.userStoreDataDM_ = UserStoreDataModel.new(UserDB)



    self.compitionRankDM_ = UserCompitionRankDataModel.new()
    

	self.audioDM_ = UserAudioDataModel.new(UserDB)
	self.cacheDataM_ = CacheDataModel.new()
	self.redNoticeManager_ = RedNoticeManager.new()
end

function GameManager:gameEnterBackground_()
	printf("游戏进入后台")
	if self.netImageManager_ then
		self.netImageManager_:saveCacheListToDB(true)
	end
	EventNoticeManager:getInstance():dispatchEvent({name = Notice.APP_ENTER_BACKGROUND})
	tools.closeUserDB()
	self.gameEnterBackgroundTimeTemp_ = os.time()
end

function GameManager:gameEnterForeground_()
	printf("游戏进入前台")
	tools.openUserDB()
end

--初始化网络模块
function GameManager:initNetWork_()--LOCAL_SERVER	CN_SERVER	US_SERVER US_STG_SERVER
	local packageInfo = {}
	packageInfo.name = NativeManager.getPackageName()
	packageInfo.platform = device.platform
	if GAME_MODE == GAME_MODE_COLLECTION then
		packageInfo.isCollection = "true"
	end
	if DEBUG == 2 and device.platform == "mac" then
		packageInfo.name = 'com.queensgame.solitaire'
	end

	--test
	-- packageInfo.platform = "android"
	-- packageInfo.name = 'com.queensgame.collection'
	--

	--HTTP网络请求入口
	local server = LCClient.US_SERVER
	if DEBUG == 0 and ResManager.useUsServer() then
		server = LCClient.US_SERVER
	elseif DEBUG == 1 then
		server = LCClient.US_STG_SERVER
	else
		server = LCClient.CN_SERVER
	end
	self.netWork_ = LCClient.new(handler(self,self.networkBeganCallback_),handler(self, self.networkCallback_),server,GAME_MODE,packageInfo)
	--设置已经存在的token信息
	local currentToken = self.userCache_:getToken()
	self.netWork_:setSessionToken(currentToken)
end


function GameManager:getNetWork( )
	local o = GameManager:getInstance()
	return o.netWork_
end

--网络请求开始的回调
function GameManager:networkBeganCallback_()
	EventNoticeManager:getInstance():dispatchEvent({name = Notice.NETWORK_BEGIN})
end
local scheduler = require("framework.scheduler")

function GameManager:retryRequest_(request)
	if DEBUG == 0 then
		Analytice.onEvent("网络超时", {})
	end
	self.reconnection_ = self.reconnection_ + 1
	-- self.reconnection_ = math.min(self.reconnection_, common.Network.REQUEST_RETRY)
	if self.reconnection_ > common.Network.REQUEST_RETRY then
		self.reconnection_ = 0
		--超过了重试次数
		return false
	end
	-- DisplayManager.showNetworkLoading()
	printf(request.path.."网络请求超时准备尝试重试")
	scheduler.performWithDelayGlobal(function()
		printf('_cloudApiVersion:'..tostring(request.parameters._cloudApiVersion))
		self:request_(request)
		end, self.reconnection_)
	return true
end

function GameManager:request_(request)
	local newRequest = self.netWork_:interface({
		method = request.method, 
		path = request.path,
		wait = request.wait,
		version = request.parameters._cloudApiVersion,
		token = request.needToken},request.id)
	newRequest(self.netWork_,request.parameters)
end

function GameManager:gameForbidden()

	local btnParams = {
		{
			colorTemplate = AlertView.green1ButtonParams, --颜色模板
			title = "免费下载_按钮", --按钮字
		 	callback = function()
		 		local url_ = GameManager:getNativeManager():getBasicVersionURL()
				local name = GameManager:getNativeManager():getBasicAppPackageName()
				GameManager:getNativeManager():openApp(url_, name)
		 		app.exit()
		 	end,--按钮响应
		 	size = CCSizeMake(230, 96),
		},
	}
	local message_ = Localization.string("lite跳转Basic版本提示")
	DisplayManager.showAlertView(nil,message_,btnParams)

end

--网络请求的回调
function GameManager:networkCallback_(status, data, request)
	EventNoticeManager:getInstance():dispatchEvent({name = Notice.NETWORK_COMPLETE})
	local apiName = {"NOREQUEST"}
	if request then
		apiName = string.split(request.path, "/")
	else
		printf("GameManager:networkCallback_request=nil")
		return
	end
	if status == common.Network.REQUEST_SUCCESS then
		self.reconnection_ = 0
		local var = common.vardump(data, "result",5)
		local var2 = string.format("NETWORK_COMPLETE_%s",string.upper(apiName[#apiName]))
		printf("code = %d\n%s\nNotificationName=%s\n", status,var,var2)
		local notificationName = string.format("NETWORK_COMPLETE_%s",string.upper(apiName[#apiName]))
		--各个数据模块进行相关解析
		self:dataParse_(data,request)
		--请求完成的通知
		EventNoticeManager:getInstance():dispatchEvent({name = notificationName,netWorkData = data})
	elseif status == common.Network.GAME_FORBIDDEN then --禁用 关闭游戏且跳转应用商店 
		self:gameForbidden()
	elseif tostring(apiName[#apiName]) == "endBattle" then --如果是结算请求
		printf("结算失败:%s", tostring(status))
		local btnParams = {
			{
				colorTemplate = AlertView.orangeButtonParams, --颜色模板
				title = "否", --按钮字
			 	callback = function()
			 		EventNoticeManager:getInstance():dispatchEvent({name = Notice.NETWORK_COMPLETE_ENDBATTLE_ERROR})
			 	end,--按钮响应
			 	size = CCSizeMake(230, 96),
			},
			{
				colorTemplate = AlertView.green1ButtonParams, --颜色模板
				title = "是", --按钮字
			 	callback = function()
			 		self:request_(request)
			 	end,--按钮响应
			 	size = CCSizeMake(230, 96),
			},
		}
		local message_ = Localization.string("TID_结算失败提示")
		DisplayManager.showAlertView(nil,message_,btnParams)
	elseif status == common.Network.TIMEOUT_ERROR then --超时
		printf("网络请求超时~~~")
		local b = false
		if request.wait == false then
			b = self:retryRequest_(request)
		end
		if not b then
			--TODO 提示用户
			NetworkErrorManager.parseError(status,request)
		end
	elseif status == common.Network.No_User_From_Session then
		printf('使用session直接登录失败')
		self.netWork_:setSessionToken(nil)
		self.userCache_:setToken(nil)
		printf('开始尝试使用账号密码登录')
		self.netWork_:loginWithDeviceId({username = common.getOpenUDID(),password = "123456"})
	elseif status == 2511 then
		local btnParams = {
	        {
	            colorTemplate = AlertView.orangeButtonParams, --颜色模板
	            title = Localization.string("完成"), --按钮字
	            callback = function()end,--按钮响应
	        },
	    }
	    DisplayManager.showAlertView(nil,Localization.string("该主题需要在主题商店购买后才可使用"),btnParams)
	elseif status == 2510 then	
		local btnParams = {
	        {
	            colorTemplate = AlertView.orangeButtonParams, --颜色模板
	            title = Localization.string("完成"), --按钮字
	            callback = function()end,--按钮响应
	        },
	    }
	    DisplayManager.showAlertView(nil,Localization.string("购买失败"),btnParams)
	elseif tonumber(status) and tonumber(status) < 100 then
		printf("网络请求报错~~~status:"..status)
		local b = false
		if request.wait == false then
			b = self:retryRequest_(request)
		end
		if not b  then
			--todo 提示用户
			NetworkErrorManager.parseError(status,request)
		end
	else --网络请求报错
		printf("网络请求报错~~~:"..status)
		NetworkErrorManager.parseError(status,request)
	end
end

function GameManager:dataParse_(data,request)
	if not data then
		return
	end
	if self.userCache_ then self.userCache_:parseData(data,request) end
	if self.userDM_ then self.userDM_:parseData(data,request) end
	if self.classicDM_ then self.classicDM_:parseData(data,request) end
	if self.gameCacheDM_ then self.gameCacheDM_:parseData(data,request) end
	if self.gameCacheSolitaireDM_ then self.gameCacheSolitaireDM_:parseData(data,request) end
	if self.gameCacheFreeCellDM_ then self.gameCacheFreeCellDM_:parseData(data,request) end
	if self.gameCacheSpiderDM_ then self.gameCacheSpiderDM_:parseData(data,request) end
	if PackageConfigDefine.isCollectFlat() then
		if self.gameCachePyramidDM_ then self.gameCachePyramidDM_:parseData(data,request) end
		if self.gameCacheTriPeaksDM_ then self.gameCacheTriPeaksDM_:parseData(data,request) end
	end

	if self.seedDM_ then self.seedDM_:parseData(data,request) end
	if self.challengeDM_ then self.challengeDM_:parseData(data,request) end
	if self.challengeSolitaireDM_ then self.challengeSolitaireDM_:parseData(data,request) end
	if self.challengeFreeCellDM_ then self.challengeFreeCellDM_:parseData(data,request) end
	if self.challengeSpiderDM_ then self.challengeSpiderDM_:parseData(data,request) end
	if PackageConfigDefine.isCollectFlat() then
		if self.challengePyramidDM_ then self.challengePyramidDM_:parseData(data,request) end
		if self.challengeTriPeaksDM_ then self.challengeTriPeaksDM_:parseData(data,request) end
	end
	
	if self.adDM_ then self.adDM_:parseData(data,request) end
	if self.audioDM_ then self.audioDM_:parseData(data,request)	end
	if self.chargeDM_ then self.chargeDM_:parseData(data,request) end
	if self.userCompitionDM_ then self.userCompitionDM_:parseData(data,request) end
	if self.userDayDataDM_ then self.userDayDataDM_:parseData(data,request) end
	if self.userThemeDataDM_ then self.userThemeDataDM_:parseData(data,request) end
	if self.userStoreDataDM_ then self.userStoreDataDM_:parseData(data,request) end
	if self.cacheDataM_ then self.cacheDataM_:parseData(data,request) end
	if self.compitionRankDM_ then self.compitionRankDM_:parseData(data,request) end
	if self.redNoticeManager_ then self.redNoticeManager_:parseData(data,request) end

end

--todo 这里貌似广告触发的地方
function GameManager:addInterstitialAD(add,immediately)
	if not self.adManager_ then
		return
	end
	if immediately and device.platform == 'ios' then
		--ios 的插屏如果弹出过慢可能打断玩家点击事件从而引起屏幕卡死
		self.adManager_:showInterstitialAD()
	else
		if GameManager:getUserCache():getProperty("gameConfig001") == 1 then
			local delay_1 = math.random()
			local delay_ = delay_1 + 0.3
			self.mainScene_:performWithDelay(function()
				self.adManager_:showInterstitialAD()
				end, delay_)
		else
			self.adManager_:showInterstitialAD()
		end
	end
	-- if not self.userDM_ or not self.userCache_ or not self.cacheDataM_ then
	-- 	return
	-- end
	-- local count_ = self.userDM_:getProperty("adInterstitialCount")
	-- count_ = count_ + add
	-- local MAX_ = self.userCache_:getProperty("interstitialCD")
	-- if count_ >= MAX_ and self.mainScene_ then
	-- 	--判断展示间隔时间
	-- 	local interstitialTimeTemp = self.cacheDataM_:getAdTimeTemp(UserADInfoVO.AD_TYPE_INTERSTITIAL)
	-- 	local interstitialTimeCD = self.userCache_:getProperty("interstitialTimeCD") or 0
	-- 	local currentTime = os.time()
	-- 	if currentTime - interstitialTimeTemp >= interstitialTimeCD then
	-- 		if immediately and device.platform == 'ios' then
	-- 			--ios 的插屏如果弹出过慢可能打断玩家点击事件从而引起屏幕卡死
	-- 			self.adManager_:showInterstitialAD()
	-- 		else
	-- 			local delay_1 = math.random()
	-- 			local delay_ = delay_1 + 0.3
	-- 			self.mainScene_:performWithDelay(function()
	-- 				self.adManager_:showInterstitialAD()
	-- 				end, delay_)
	-- 		end
	-- 		count_ = 0--清除计数
	-- 		self.cacheDataM_:resetAdTimeTemp(UserADInfoVO.AD_TYPE_INTERSTITIAL, currentTime)--清除cd
	-- 	end
	-- end
	-- self.userDM_:saveUserData({adInterstitialCount = count_})
end

function GameManager:judgeCrossPromotion( )
	if GameManager:getInstance():judgeNoAds() == true then
		return false
	end
	local showIcon = GameManager:getCacheData():getProperty("showCPIcon")
    local countLimit = GameManager:getCacheData():getProperty("cpCountLimit")
    local totalCount = GameManager:getUserClassicData():getTotalWinCount(true)
    if device.platform == "ios" or showIcon == 0 or countLimit > totalCount then
    	return false
    end
    return true
end

--是否是Lite版本
function GameManager:judgeIsLiteVersion()
	if not self.verType_ then
		local _,verType_ = NativeManager.getVersionType()
		self.verType_ = verType_
	end
	return self.verType_ == "lite"
end

--Lite版本跳转Basic弹窗判断
function GameManager:judgeIsGotoBasicVersion()
	local b = self:judgeIsLiteVersion()
	if b then
		local isInstalled = GameManager:getNativeManager():isInstalled(GameManager:getNativeManager():getBasicAppPackageName())
		if isInstalled == "false" then
			local viewCtrl = LiteAlertViewCtrl.new()
		    display.getRunningScene():addChild(viewCtrl:getView())
		else
			local url_ = GameManager:getNativeManager():getBasicVersionURL()
			local name = GameManager:getNativeManager():getBasicAppPackageName()
			GameManager:getNativeManager():openApp(url_, name)
		end
	end
	return b
end

--判断是否可展示去广告按钮
function GameManager:judgeShowNoAdsBtn( )
	if not PackageConfigDefine.isSupportCharge() then
		return false
	end
	if self:judgeNoAds() == true or not self:judgeCanAds() then
		return false
	end
	return true
end

--请求支付
function GameManager:requestPayForProduct( )
	--是否存在计费点信息
	local productList = GameManager:getUserData():getProperty("productInfos") or {}
	local productVO = productList["removeAD"]
	local eventInfo_ = {}
	
	eventInfo_.action = "clickRemoveAds"
	eventInfo_.id = "NotFound"
	if productVO then
		eventInfo_.id = productId
	end
	Analytice.onEventThinkingData("shop", eventInfo_)
	if not productVO then
		--向服务器拉取订单信息
		GameManager:getNetWork():inAppProductInfo({
			platform = device.platform,
			packageName = NativeManager.getPackageName()
			})
		return
	end
	print("====有计费信息")

	--有计费信息
	self:requestProductIdSuccess()
end
--获取商品信息成功，继续支付
function GameManager:requestProductIdSuccess( )
	--判断是否可买
	if GameManager:getInstance():judgeNoAds() == true then
		return
	end
	local productList = GameManager:getUserData():getProperty("productInfos") or {}
	local productVO = productList["removeAD"]
	if not productVO then
		return
	end
	GameManager:getPayManager():purchaseProductWithIndentifier(productVO)
end

function GameManager:judgeNoAds( )
	if not self.userDM_ then
		return false
	end
	local time_ = self.userDM_:getRemoveAdTime()
	if self.userDM_.noAdsStatus_ ~= 0 or time_ > 0 then
		return true
	end

	return false
end

function GameManager:judgeCanAds()
	if not self.classicDM_ then
		return false
	end
	if not self.userDM_ then
		return false
	end
	if not self.userCache_ then
		return false
	end
	local condition = self.userDM_:getProperty("adCondition") or 0
	local count_ = self.classicDM_:getTotalCount(true)
	count_ = count_ + self.userCache_:getProperty("compitionCount") or 0
	if condition > count_ then
		return false
	end
	return true
end

GameManager.NO_WAY_ALERT_TAG = 9527
function GameManager:popNoWayAlert(canMagic)
	local view_ = display.getRunningScene():getChildByTag(GameManager.NO_WAY_ALERT_TAG)
	if view_ then --说明界面上已经有这个弹窗了
		return
	end
	canMagic = canMagic or false

	if self:judgeIsLiteVersion() then
		canMagic = false
	end

	local viewCtrl = NoHintsViewCtrl.new(canMagic)
	viewCtrl:setCall1(function()
			return self:callBattleManagerMethod("magic")
		end)
	viewCtrl:setCall2(function()
			-- self:callBattleManagerMethod("tapRevoke")
			self:callBattleManagerMethod("starNewGame",nil, true)
		end)
	viewCtrl:setCall3(function()
			-- self:callBattleManagerMethod("endGame")
			-- local seed = GameManager:getUserGameCacheData():getCacheData():getProperty("seed")
			-- self:callBattleManagerMethod("starNewGame",seed)
			self:replayLogic()
		end)
	viewCtrl:getView():setTag(GameManager.NO_WAY_ALERT_TAG)
	display.getRunningScene():addChild(viewCtrl:getView())
	

	-- local btnParams = {
	-- 	{
	-- 		colorTemplate = AlertView.orangeButtonParams, --颜色模板
	-- 		title = "重玩本局_弹窗", --按钮字
	-- 			size = CCSizeMake(230, 90),
	-- 	 	callback = function()
	-- 		 	local seed = GameManager:getUserGameCacheData():getCacheData():getProperty("seed")
	-- 		 	GameManager:getInstance():callBattleManagerMethod("starNewGame",seed)
	-- 	 	end,--按钮响应
	-- 	},
	-- 	{
	-- 		colorTemplate = AlertView.green1ButtonParams, --颜色模板
	-- 		title = "重开一局_弹窗", --按钮字
	-- 			size = CCSizeMake(230, 90),
	-- 	 	callback = function()
	-- 	 		GameManager:getInstance():callBattleManagerMethod("starNewGame",nil, true)
	-- 	 	end,--按钮响应
	-- 	},
	-- }
	-- DisplayManager.showAlertView(nil,Localization.string("无牌可走提示！"),btnParams,nil,true)
end

function GameManager:replayLogic()
	local seed = GameManager:getUserGameCacheData():getCacheData():getProperty("seed")
	local isDailyChallenge = GameManager:getUserGameCacheData():isDailyChallenge()
	local challengingData = GameManager:getUserChallengeData():getProperty("challengingData")
	self:callBattleManagerMethod("starNewGame",seed)
	if isDailyChallenge and challengingData then
		local params = {
			isDailyChallenge = 1,
			isVegasMode = 0,	--关闭维加斯
			isVegasAccmulativeMode = 0,--关闭维加斯累计
			isDeal = 1,		--是活局，不上报种子
			-- isRepeat = 1,	--不计入局数统计信息
			-- isWin = 1,		--不计入胜利统计信息
		}
		local modeType = GameManager:getDailyType()
		local typeList = UserDayTaskDataVO.type(modeType)
		if modeType == GAME_MODE_SPIDER then
			local count = 1
			for i=1,#typeList do
				local find, __ = string.find(challengingData.type_, "spider"..i)
				if find then
					count = i
					break
				end
			end
			params.suitCount = count	--花色数
		elseif modeType == GAME_MODE_SOLITAIRE then
			params.isDraw3Mode = challengingData.type_ == typeList[3] and 1 or 0	--单张牌
		elseif modeType == GAME_MODE_PYRAMID then
			params.roundMode = 3
		end
		GameManager:getUserGameCacheData():customMadeCacheData(params)
		DisplayManager.showChallengeTips("接受每日挑战{year}-{month}-{day}",{year=challengingData.year_,month=challengingData.month_,day=challengingData.day_})
	    -- DisplayManager.showChallengeTips(Localization.string("接受每日挑战{year}-{month}-{day}",{year=challengingData.year_,month=challengingData.month_,day=challengingData.day_}))
	end
end

function GameManager:isNewCrossPromotion( )
	if not self.userDM_ then
		return false
	end
	local dbVer = self.userDM_:getProperty("dbCPRedPointVer") or 0
	local netVer = self.userDM_:getProperty("netCPRedPointVer") or 0
	if netVer > dbVer then
		return true
	end
	return false
end

function GameManager:popUnlockDialog( )
	if self.popedDialog_ then
		return
	end
	self.popedDialog_ = true
	local btnParams = {
		{
			colorTemplate = AlertView.orangeButtonParams, --颜色模板
			title = Localization.string("是"), --按钮字
		 	callback = function()
		 		self.popedDialog_ = false
		 	end,--按钮响应
		},
	}
	DisplayManager.showAlertView(nil,Localization.string("解锁卡背提示"),btnParams, function ()
		self.popedDialog_ = false
	end)
end

function GameManager:getCollectionSettingList_()
	local list_ = {}
	local isVegasMode_ = (GameManager:getUserData():getProperty("isVegasMode") == 1)
	local isGame_ = self:getBattleManager() and true or false
	local isDailyChallenge_ = GameManager:getUserGameCacheData():isCollectionDaily()
	local isClassic_ = (GameManager:getModeType() == GameManager.MODETYPE_SOLITAIRE)
	local isSpider_ = (GameManager:getModeType() == GameManager.MODETYPE_SPIDER)
	local isPyramid_ = (GameManager:getModeType() == GameManager.MODETYPE_PYRAMID)
	local isTripeaks_ = (GameManager:getModeType() == GameManager.MODETYPE_TRIPEAKS)
	local isQuickCollect = GameManager:getUserCache():getProperty("QuickPlay")

	--去广告
	if GameManager:getInstance():judgeShowNoAdsBtn() then
		local settingVO = SettingVO.new({
			name = ("去广告_设置"), --名字
			key = "去广告",
			})
		list_[#list_ + 1] = settingVO
	end

	if not isGame_ then --大厅里
		--音效
		local settingVO = SettingVO.new({
			name = ("音效"), --名字
			key = "isSound",
			value = GameManager:getUserData():getProperty("isSound"),--对应值	
			isToggle = 1,--是否是开关[0:否/1:是]
			isLock = 0,--是否是锁住[0:否/1:是]
			})
		list_[#list_ + 1] = settingVO

		if PackageConfigDefine.haveMusic() then
			--音乐
			local settingVO = SettingVO.new({
				name = ("音乐"), --名字
				key = "isMusic",
				value = GameManager:getUserData():getProperty("isMusic"),--对应值	
				isToggle = 1,--是否是开关[0:否/1:是]
				isLock = 0,--是否是锁住[0:否/1:是]
				})
			list_[#list_ + 1] = settingVO
		end

		--语言
		local settingVO = SettingVO.new({
			name = ("语言"), --名字
			key = "language",
			value = GameManager:getUserData():getProperty("language"),--对应值	
			isToggle = 0,--是否是开关[0:否/1:是]
			isLock = 0,--是否是锁住[0:否/1:是]
			})
		list_[#list_ + 1] = settingVO

		--推送
		local settingVO = SettingVO.new({
			name = ("推送"), --名字
			key = "openNotice",
			value = GameManager:getUserData():getProperty("openNotice"),--对应值	
			isToggle = 1,--是否是开关[0:否/1:是]
			isLock = 0,--是否是锁住[0:否/1:是]
			})
		list_[#list_ + 1] = settingVO

		--联系我们
		local settingVO = SettingVO.new({
			name = ("联系我们"), --名字
			key = "联系我们",
			ignoreButton = 1,--是否忽略按钮[0:否/1:是]
			})
		list_[#list_ + 1] = settingVO

		--锁屏广告
		if GameManager:isShowLockScreenCellServerTime() then
			local settingVO = SettingVO.new({
				name = ("锁屏控制"), --名字
				key = "openLockScreenAds",
				value = GameManager:getNativeManager():canShowLockScreen() and 1 or 0,
				isToggle = 1,--是否是开关[0:否/1:是]
				isLock = 0,--是否是锁住[0:否/1:是]
				})
			list_[#list_ + 1] = settingVO
		end
	end

	--经典玩法
	if isGame_ and isClassic_ then
		if not isDailyChallenge_ then
			--3张牌
			local settingVO = SettingVO.new({
				name = ("翻3张牌"), --名字
				key = "isDraw3Mode",
				value = GameManager:getUserData():getProperty("isDraw3Mode"),--对应值	
				isToggle = 1,--是否是开关[0:否/1:是]
				isLock = 0,--是否是锁住[0:否/1:是]
				})
			list_[#list_ + 1] = settingVO
			--维加斯模式
			local settingVO = SettingVO.new({
				name = ("维加斯模式"), --名字
				key = "isVegasMode",
				value = GameManager:getUserData():getProperty("isVegasMode"),--对应值	
				isToggle = 1,--是否是开关[0:否/1:是]
				isLock = 0,--是否是锁住[0:否/1:是]
				})
			list_[#list_ + 1] = settingVO
			--维加斯累计
			local settingVO = SettingVO.new({
				name = ("维加斯累计"), --名字
				key = "isVegasAccmulativeMode",
				value = GameManager:getUserData():getProperty("isVegasAccmulativeMode"),--对应值	
				isToggle = 1,--是否是开关[0:否/1:是]
				isLock = ((not isVegasMode_) and 1) or 0,--是否是锁住[0:否/1:是]
				})
			list_[#list_ + 1] = settingVO
		end
		--快速收牌
		if isQuickCollect == 1 then
			local settingVO = SettingVO.new({
				name = ("快速收牌"), --名字
				key = "isOpenSpeedCollection",
				value = GameManager:getUserData():getProperty("isOpenSpeedCollection"),--对应值	
				isToggle = 1,--是否是开关[0:否/1:是]
				isLock = 0,--是否是锁住[0:否/1:是]
				})
			list_[#list_ + 1] = settingVO
		end
		
	end

	--蜘蛛玩法
	if isGame_ and isSpider_ then
		if not isDailyChallenge_ then
			local settingVO = SettingVO.new({
				name = ("无限制发牌"), --名字
				key = "unlimitedDeal",
				value = GameManager:getUserData():getProperty("unlimitedDeal"),--对应值	
				isToggle = 1,--是否是开关[0:否/1:是]
				isLock = 0,--是否是锁住[0:否/1:是]
				})
			list_[#list_ + 1] = settingVO

			local settingVO = SettingVO.new({
				name = ("花色个数"), --名字
				key = "suitCount",
				value = GameManager:getUserData():getProperty("suitCount"),--对应值	
				isToggle = 0,--是否是开关[0:否/1:是]
				isLock = 0,--是否是锁住[0:否/1:是]
				})
			list_[#list_ + 1] = settingVO
		end
	end

	--金字塔玩法
	if isGame_ and isPyramid_ then
		if not isDailyChallenge_ then
			local settingVO = SettingVO.new({
				name = ("轮数"), --名字
				key = "roundMode",
				value = GameManager:getUserData():getProperty("roundMode"),--对应值	
				isToggle = 0,--是否是开关[0:否/1:是]
				isLock = 0,--是否是锁住[0:否/1:是]
				})
			list_[#list_ + 1] = settingVO
		end
	end

	--游戏内通用
	if isGame_ then
		if not isDailyChallenge_  then
			--时间模式
			local settingVO = SettingVO.new({
				name = ("时间模式"), --名字
				key = "isOpenTimer",
				value = GameManager:getUserData():getIsOpenTimer(),--对应值	
				isToggle = 1,--是否是开关[0:否/1:是]
				isLock = 0,--是否是锁住[0:否/1:是]
				})
			list_[#list_ + 1] = settingVO

			--自动提示
			local settingVO = SettingVO.new({
				name = ("自动提示"), --名字
				key = "openHint",
				value = GameManager:getUserData():getOpenHint(),--对应值	
				isToggle = 1,--是否是开关[0:否/1:是]
				isLock = 0,--是否是锁住[0:否/1:是]
				})
			list_[#list_ + 1] = settingVO
		end
		if not isPyramid_ and not isTripeaks_ then
			--左手模式
			local settingVO = SettingVO.new({
				name = ("左手模式"), --名字
				key = "isLeft",
				value = GameManager:getUserData():getIsLeft(),--对应值	
				isToggle = 1,--是否是开关[0:否/1:是]
				isLock = 0,--是否是锁住[0:否/1:是]
				})
			list_[#list_ + 1] = settingVO
		end
		
		--玩法介绍
		local settingVO = SettingVO.new({
			name = ("玩法介绍_Title"), --名字
			key = "玩法介绍",
			ignoreButton = 1,--是否忽略按钮[0:否/1:是]
			})
		list_[#list_ + 1] = settingVO
	end

	if list_[#list_] then
		list_[#list_].isLast_ = 1
	end
	
	return list_
end

function GameManager:getSettingList()
	if GAME_MODE == GAME_MODE_COLLECTION then
		return self:getCollectionSettingList_()
	end
	local list_ = {}
	local isVegasMode_ = (GameManager:getUserData():getProperty("isVegasMode") == 1)
	local isDailyChallenge = GameManager:getUserGameCacheData():isDailyChallenge()
	local isLiteVersion_ = self:judgeIsLiteVersion()
	local isClassic_ = (GAME_MODE == GAME_MODE_SOLITAIRE)
	local isSpider = (GAME_MODE == GAME_MODE_SPIDER)
	local isTriPeaks = (GAME_MODE == GAME_MODE_TRIPEAKS)
	local isPyramid = (GAME_MODE == GAME_MODE_PYRAMID)
	local isQuickCollect = GameManager:getUserCache():getProperty("QuickPlay")
	-- isQuickCollect = 1

	if GameManager:getInstance():judgeShowNoAdsBtn() then
		--去广告
		local settingVO = SettingVO.new({
			name = ("去广告_设置"), --名字
			key = "去广告",
			})
		list_[#list_ + 1] = settingVO
	end
	if not isDailyChallenge then
		if isClassic_ then
			--3张牌
			local settingVO = SettingVO.new({
				name = ("翻3张牌"), --名字
				key = "isDraw3Mode",
				value = GameManager:getUserData():getProperty("isDraw3Mode"),--对应值	
				isToggle = 1,--是否是开关[0:否/1:是]
				isLock = 0,--是否是锁住[0:否/1:是]
				})
			list_[#list_ + 1] = settingVO
			--维加斯模式
			local settingVO = SettingVO.new({
				name = ("维加斯模式"), --名字
				key = "isVegasMode",
				value = GameManager:getUserData():getProperty("isVegasMode"),--对应值	
				isToggle = 1,--是否是开关[0:否/1:是]
				isLock = 0,--是否是锁住[0:否/1:是]
				})
			list_[#list_ + 1] = settingVO
			--维加斯累计
			local settingVO = SettingVO.new({
				name = ("维加斯累计"), --名字
				key = "isVegasAccmulativeMode",
				value = GameManager:getUserData():getProperty("isVegasAccmulativeMode"),--对应值	
				isToggle = 1,--是否是开关[0:否/1:是]
				isLock = ((not isVegasMode_) and 1) or 0,--是否是锁住[0:否/1:是]
				})
			list_[#list_ + 1] = settingVO
			
		end

		if isSpider then
			local settingVO = SettingVO.new({
				name = ("无限制发牌"), --名字
				key = "unlimitedDeal",
				value = GameManager:getUserData():getProperty("unlimitedDeal"),--对应值	
				isToggle = 1,--是否是开关[0:否/1:是]
				isLock = 0,--是否是锁住[0:否/1:是]
				})
			list_[#list_ + 1] = settingVO

			local settingVO = SettingVO.new({
				name = ("花色个数"), --名字
				key = "suitCount",
				value = GameManager:getUserData():getProperty("suitCount"),--对应值	
				isToggle = 0,--是否是开关[0:否/1:是]
				isLock = 0,--是否是锁住[0:否/1:是]
				})
			list_[#list_ + 1] = settingVO
		end
		
		--时间模式
		local settingVO = SettingVO.new({
			name = ("时间模式"), --名字
			key = "isOpenTimer",
			value = GameManager:getUserData():getIsOpenTimer(),--对应值	
			isToggle = 1,--是否是开关[0:否/1:是]
			isLock = 0,--是否是锁住[0:否/1:是]
			})
		list_[#list_ + 1] = settingVO

		--金字塔玩法
		if isPyramid then
			local settingVO = SettingVO.new({
				name = ("轮数"), --名字
				key = "roundMode",
				value = GameManager:getUserData():getProperty("roundMode"),--对应值	
				isToggle = 0,--是否是开关[0:否/1:是]
				isLock = 0,--是否是锁住[0:否/1:是]
				})
			list_[#list_ + 1] = settingVO
		end
	end
	
	if not isTriPeaks and not isPyramid then
		--左手模式
		local settingVO = SettingVO.new({
			name = ("左手模式"), --名字
			key = "isLeft",
			value = GameManager:getUserData():getIsLeft(),--对应值	
			isToggle = 1,--是否是开关[0:否/1:是]
			isLock = 0,--是否是锁住[0:否/1:是]
			})
		list_[#list_ + 1] = settingVO
	end

	if isClassic_ and isQuickCollect == 1 then
		--快速收牌
		local settingVO = SettingVO.new({
			name = ("快速收牌"), --名字
			key = "isOpenSpeedCollection",
			value = GameManager:getUserData():getProperty("isOpenSpeedCollection"),--对应值	
			isToggle = 1,--是否是开关[0:否/1:是]
			isLock = 0,--是否是锁住[0:否/1:是]
			})
		list_[#list_ + 1] = settingVO
	end
	
	--音效
	local settingVO = SettingVO.new({
		name = ("音效"), --名字
		key = "isSound",
		value = GameManager:getUserData():getProperty("isSound"),--对应值	
		isToggle = 1,--是否是开关[0:否/1:是]
		isLock = 0,--是否是锁住[0:否/1:是]
		})
	list_[#list_ + 1] = settingVO

	if not isLiteVersion_ and PackageConfigDefine.haveMusic() then
		--音乐
		local settingVO = SettingVO.new({
			name = ("音乐"), --名字
			key = "isMusic",
			value = GameManager:getUserData():getProperty("isMusic"),--对应值	
			isToggle = 1,--是否是开关[0:否/1:是]
			isLock = 0,--是否是锁住[0:否/1:是]
			})
		list_[#list_ + 1] = settingVO
	end
	
	
	--永久活局
	-- local isVegasMode_ = (GameManager:getUserData():getProperty("isVegasMode") == 1)
	-- local settingVO = SettingVO.new({
	-- 	name = ("永久活局"), --名字
	-- 	key = "isSolvedMode",
	-- 	value = GameManager:getUserData():getProperty("isSolvedMode"),--对应值
	-- 	isToggle = 1,--是否是开关[0:否/1:是]
	-- 	isLock = (isVegasMode_ and 1) or 0,--是否是锁住[0:否/1:是]
	-- 	})
	-- list_[#list_ + 1] = settingVO
	-- --牌面款式
	-- local settingVO = SettingVO.new({
	-- 	name = ("牌面款式"), --名字
	-- 	key = "pokerFace",
	-- 	value = GameManager:getUserData():getProperty("pokerFace"),--对应值	
	-- 	isToggle = 0,--是否是开关[0:否/1:是]
	-- 	isLock = 0,--是否是锁住[0:否/1:是]
	-- 	})
	-- list_[#list_ + 1] = settingVO
	-- --牌背款式
	-- local settingVO = SettingVO.new({
	-- 	name = ("牌背款式"), --名字
	-- 	key = "pokerBack",
	-- 	value = GameManager:getUserData():getProperty("pokerBack"),--对应值	
	-- 	isToggle = 0,--是否是开关[0:否/1:是]
	-- 	isLock = 0,--是否是锁住[0:否/1:是]
	-- 	})
	-- list_[#list_ + 1] = settingVO
	-- --主题
	-- local settingVO = SettingVO.new({
	-- 	name = ("主题"), --名字
	-- 	key = "theme",
	-- 	value = GameManager:getUserData():getProperty("theme"),--对应值	
	-- 	isToggle = 0,--是否是开关[0:否/1:是]
	-- 	isLock = 0,--是否是锁住[0:否/1:是]
	-- 	})
	-- list_[#list_ + 1] = settingVO
	--语言
	local settingVO = SettingVO.new({
		name = ("语言"), --名字
		key = "language",
		value = GameManager:getUserData():getProperty("language"),--对应值	
		isToggle = 0,--是否是开关[0:否/1:是]
		isLock = 0,--是否是锁住[0:否/1:是]
		})
	list_[#list_ + 1] = settingVO
	--自动提示
	local settingVO = SettingVO.new({
		name = ("自动提示"), --名字
		key = "openHint",
		value = GameManager:getUserData():getOpenHint(),--对应值	
		isToggle = 1,--是否是开关[0:否/1:是]
		isLock = 0,--是否是锁住[0:否/1:是]
		})
	list_[#list_ + 1] = settingVO
	if not isLiteVersion_ then
		--推送
		local settingVO = SettingVO.new({
			name = ("推送"), --名字
			key = "openNotice",
			value = GameManager:getUserData():getProperty("openNotice"),--对应值	
			isToggle = 1,--是否是开关[0:否/1:是]
			isLock = 0,--是否是锁住[0:否/1:是]
			})
		list_[#list_ + 1] = settingVO
	end
	--玩法介绍
	local settingVO = SettingVO.new({
		name = ("玩法介绍_Title"), --名字
		key = "玩法介绍",
		ignoreButton = 1,--是否忽略按钮[0:否/1:是]
		})
	list_[#list_ + 1] = settingVO
	--联系我们
	local settingVO = SettingVO.new({
		name = ("联系我们"), --名字
		key = "联系我们",
		ignoreButton = 1,--是否忽略按钮[0:否/1:是]
		})
	list_[#list_ + 1] = settingVO

	--锁屏广告
	if GameManager:isShowLockScreenCellServerTime() then
		local settingVO = SettingVO.new({
			name = ("锁屏控制"), --名字
			key = "openLockScreenAds",
			value = GameManager:getNativeManager():canShowLockScreen() and 1 or 0,
			isToggle = 1,--是否是开关[0:否/1:是]
			isLock = 0,--是否是锁住[0:否/1:是]
			})
		list_[#list_ + 1] = settingVO
	end
	
	if list_[#list_] then
		list_[#list_].isLast_ = 1
	end
	return list_
end
-- function GameManager:isShowLockScreenCell()
-- 	local isShowLockScreenCell = false
-- 	if GameManager:isShowLockScreenCellServerTime() then
-- 		isShowLockScreenCell = true
-- 	end
-- 	return isShowLockScreenCell
-- end
-- function GameManager:isShowLockScreenCellServer()--服务器控制
-- 	return GameManager:getUserData():getProperty("isShowLockscreenCellServer")
-- end
function GameManager:isShowLockScreenCellServerTime()--server控制/是否打开、打开时间
	local isShowLockScreenCell = false
	local NativeData_ = GameManager:getNativeManager():getLockScreenCfg()
	if not NativeData_.isOpen or not NativeData_.openTime then
		return false
	end
	local timeTamp = GameManager:getNativeManager():getMilliSecondForFOT()--得到第一次打开-秒
	if timeTamp > 0 then -- 成功获取
		local time_ = os.time()
		if time_ - timeTamp > NativeData_.openTime then
			isShowLockScreenCell = true
		end
	end
	return isShowLockScreenCell
end

GameManager.RES_TYPE_COIN = "coin" --金币
GameManager.RES_TYPE_DIAMOND = "diamond" --钻石
GameManager.RES_TYPE_MAGIC = "magic" --魔法棒

function GameManager:judgeResIsEnough(resType,price,needAlert,popFreeCoinAlert,delegate)
	if not self.userDM_ then
		return false
	end
	local num_ = 0
	local str_ = "金币不足！"
	if resType == GameManager.RES_TYPE_COIN then
		num_ = self.userDM_:getCoin()
		str_ = "金币不足！"
	elseif resType == GameManager.RES_TYPE_DIAMOND then
		num_ = self.userDM_:getProperty("diamond")
		str_ = "钻石不足！"
	elseif resType == GameManager.RES_TYPE_MAGIC then
		num_ = self.userDM_:getMagic()
		str_ = "购买魔法提示"
	end

	if price > num_ then
		if needAlert then
			--判断有无激励视频填充
			local leftCount = GameManager:getUserCache():getLeftRewardVideoNumOfFreeCoin()
			if GameManager:getInstance():hasRewardVideo() and str_ == "金币不足！" and leftCount > 0 and popFreeCoinAlert then
				local viewCtrl = coinRewardVideoView.new(delegate)
    			display.getRunningScene():addChild(viewCtrl:getView())
			else
				DisplayManager.showAlertBox(Localization.string(str_))
			end
		end
		return false
	end
	return true
end
function GameManager:hasRewardVideo()
	if self.adManager_ then
		local hasAd = self.adManager_:isRewardVideoReady() -- UserADInfoVO.AD_TYPE_REWAEDVIDEO true
		if hasAd then
			return true
		end
	end
	return false
end

function GameManager:popAchieveUnlcokView(data)
	local acheiveView = AchieveUnlockViewCtrl.new(data)
	display.getRunningScene():addChild(acheiveView:getView())
end

function GameManager:popGiftMagicView()
	local isFishdom = PackageConfigDefine.isSolitaireFishdom()
	if isFishdom then
		local giftView = GiftMagicViewCtrl.new()
		display.getRunningScene():addChild(giftView:getView())
	end
end

return GameManager