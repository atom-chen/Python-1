--
-- Author: yang fuchao
-- Date: 2016-04-20 20:50:38
--
local scheduler = require("framework.scheduler")
local BattleManager = class("BattleManager",function()
	return display.newNode()
end)

BattleManager.HEAD_COLUMN_1 = 1		--牌桌
BattleManager.HEAD_COLUMN_2 = 2
BattleManager.HEAD_COLUMN_3 = 3
BattleManager.HEAD_COLUMN_4 = 4
BattleManager.HEAD_COLUMN_5 = 5
BattleManager.HEAD_COLUMN_6 = 6
BattleManager.HEAD_COLUMN_MAX = 7

BattleManager.HEAD_COLLECT_1 = 8	--集牌区
BattleManager.HEAD_COLLECT_2 = 9
BattleManager.HEAD_COLLECT_3 = 10
BattleManager.HEAD_COLLECT_MAX = 11

BattleManager.HEAD_CHANGE_1 = 12	--换牌区,已打开
BattleManager.HEAD_CHANGE_MAX = 13	--换牌区，未打开

BattleManager.RESERVE_NUM = 24 --切牌时预留的张数

BattleManager.END_ANI_NONE = 0
BattleManager.END_ANI_COLLECTING = 1--收集
BattleManager.END_ANI_STUFF = 2--洗牌
BattleManager.END_ANI_DIALOG = 3--结算窗
BattleManager.END_ANI_END = 4--结束

BattleManager.SCORE_COLLECT = 15
BattleManager.COLUMN_TO_COLLECT = 10
BattleManager.SCORE_LOCK_TO_COLUMN = 5
BattleManager.SCORE_FLIP_TO_FACE = 5

function BattleManager:ctor( delegate )
	GameManager:getAudioData():stopAllAudios()
	KMultiLanExtend.extend(self)
	self:initView_()
	self.outOfFlips:setVisible(false)
	self.sp_no:setVisible(false)
	self.btn_autoCollect:setVisible(false)
	self:setDelegate(delegate)
	self.headsList_ = {}
	self.flipCardRound = 0--翻牌的轮数
	self.noTipsNum = 0--提示没有路可走的次数
	--是否展示移动动画
	self.showMoveAni_ = true
	self.cardMoving_ = false
	-- 快速撤销
	self.quickundo = false
	--发牌区点击
	self.qucikClickChange = false
	--初始化牌组
	self:startGame(nil, true)
	
	self:setNodeEventEnabled(true)
	if ISDEBUG_PACKAGE then
		self:test()
	end
end

function BattleManager:test( )
	local params = {
		listener = handler(self, self.setListener_),
		image = "#ui_none.png",
		size = CCSizeMake(360, 40),
		x = 0,--point.x,
		y = -3,--point.y,
	}
	self.messageEd_ = ui.newEditBox(params)
	self.messageEd_:setAnchorPoint(ccp(0, 0.5))
	self:addChild(self.messageEd_)
	self.messageEd_:setPlaceHolder(Localization.string("点击输入种子"))
	self.messageEd_:setPlaceholderFontColor(ccc3(48, 26, 12))
	self.messageEd_:setFontColor(ccc3(48, 26, 12))
	self.messageEd_:setInputFlag(kEditBoxInputFlagSensitive)
	self.messageEd_:setReturnType(kKeyboardReturnTypeDone)
	self.messageEd_:setInputMode(kEditBoxInputModeAny)
	self.messageEd_:setPosition(ccp(0, 200))

			local params_ = {
				font = common.LabelFont,
				size = 40,
			}
			local label = ui.newTTFLabel(params_)
			local normal = display.newScale9Sprite("#B_green.png")
			local pressed = display.newScale9Sprite("#B_green.png")
			local disabled = display.newScale9Sprite("#B_green.png")
			local btn = CCControlButton:create(label, normal)
			btn:setLabelAnchorPoint(ccp(0.5,0.35))
			btn:setPreferredSize(CCSizeMake(200, 80))
			btn:setBackgroundSpriteForState(pressed, CCControlStateHighlighted)
			btn:setBackgroundSpriteForState(disabled, CCControlStateDisabled)
			btn:setZoomOnTouchDown(true)
			btn:addHandleOfControlEvent(function()
					local num = tonumber(self.editSeed_)
					if num then
						self:starNewGame(num, true)
					end
				end,CCControlEventTouchUpInside)
			self:setBtnTitle(btn, "确认")
			self:addChild(btn)
			btn:setPosition(ccp(500, 200))
end
function BattleManager:setListener_(event, editbox)
	if event == "began" then
    elseif event == "ended" then
        self.editSeed_ = editbox:getText()
    elseif event == "returnDone" then
        self.editSeed_ = editbox:getText()
    elseif event == "changed" then
        self.editSeed_ = editbox:getText()
    else
        printf("EditBox event %s", tostring(event))
    end
end

function BattleManager:onEnter( )
	EventNoticeManager:getInstance():addEventListener(self,Notice.APP_ENTER_BACKGROUND,handler(self, self.gameEnterBackground_))
	EventNoticeManager:getInstance():addEventListener(self,Notice.USER_DATA_CHANGE,handler(self, self.leftModeChanged))
	EventNoticeManager:getInstance():addEventListener(self,Notice.USER_LANGUAGE_CHANGE,handler(self, self.setLocalization_))
    EventNoticeManager:getInstance():addEventListener(self,Notice.USER_CARD_CHANGE,handler(self, self.updataAllCards))
    

end

function BattleManager:setLocalization_( )
	if self.speedSchedule then
		self:stopAction(self.speedSchedule)
		self.speedSchedule = nil
	end
	self:setBtnTitle(self.btn_autoCollect, "自动收牌")
end

function BattleManager:onExit( )
	EventNoticeManager:getInstance():removeEventListenerForHandle(self)
end

function BattleManager:getHeadsList()
	return self.headsList_ or {}
end

function BattleManager:updataAllCards(event)
	if not self.headsList_ then
		return
	end
	local faceStyle = GameManager:getUserData():getProperty("pokerFace")
	local backStyle = GameManager:getUserData():getProperty("pokerBack")
	for k,v in pairs(self.headsList_) do
		if v then
			local list_ = DealerController.getListByHead(v)
			for i=1,#list_ do
				if event.face then
					list_[i]:getView():changePokerFaceToStyle(faceStyle)
				end
				if event.back then
					list_[i]:getView():changePokerBackToStyle(backStyle)
				end
			end
		end
	end
	self:clearLight_()
end

function BattleManager:gameEnterBackground_( )
	local sec = GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):getRunningTime()
	GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):changeCacheData({gameTime = sec})

	GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):saveCache()
	GameManager:getUserChallengeData():saveCache()
end

function BattleManager:starNewGame( seed, resetAll )
	local isWin_ = GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):getCacheData():getProperty("isWin")
	--说明当前牌局未完成
	if isWin_ == 0 then
		self:recordCompleteEvent_("abandonBattle")
	end

	GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):cleanData()
	self:clearLight_()
	self:stopAllActions()
	self.card_table:removeAllChildren()
	self.headsList_ = {}
	self.flipCardRound = 0
	self.noTipsNum = 0
	--是否展示移动动画
	self.showMoveAni_ = true
	self.cardMoving_ = false
	self.quickundo = false
	self.qucikClickChange = false
	self.btn_autoCollect:setVisible(false)
	GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):cleanRecordData()
	--初始化牌组
	self:startGame(seed, resetAll)
end

function BattleManager:initView_( )
	--计算视图大小
	local isPortrait = self:isPortrait_()
	local displaySize = CCSizeMake(display.width, display.height)
	if isPortrait then
		displaySize = CCSizeMake(USER_SCREEN_WIDTH, USER_SCREEN_HEIGHT)
	else
		displaySize = CCSizeMake(USER_DESIGN_LENGHT, USER_SCREEN_WIDTH)
	end
	self:setContentSize(displaySize)
	--读取ccb文件
	local reader = CCBReader.new()
	local root = reader:load("ccb/battleView.ccbi","battleView",self,displaySize)
	root = tolua.cast(root,"CCNode")
	self:addChild(root)
	--设置按钮显示文字
	self:setLocalization_()

	--宽屏的缩放
	if isPortrait and display.height < USER_SCREEN_HEIGHT then
		local rate = display.height/USER_SCREEN_HEIGHT
		self:setScale(rate)
		self:setPositionX(640*(1-rate)/2)
	elseif not isPortrait and display.width < USER_DESIGN_LENGHT then
		local rate = display.width/USER_DESIGN_LENGHT
		self:setScale(rate)
		self:setPositionY(640*(1-rate)/2)
	end
	--移到中间
	if isPortrait then
		if display.height-displaySize.height > 0 then
			self:setPositionY((display.height-displaySize.height))
		end
	else
		if display.width-displaySize.width > 0 then
			self:setPositionX((display.width-displaySize.width)/2)
		end
	end

	local size = self.card_table:getContentSize()

	local offsetY = 300
	if not isPortrait then
		offsetY = 270
	end
	for i=BattleManager.HEAD_COLUMN_1,BattleManager.HEAD_COLUMN_MAX do
		if self["column"..i] then
			self["column"..i]:setPositionY(size.height- offsetY)
		end
	end
	offsetY = 150
	if not isPortrait then
		offsetY = 130
	end
	for i=BattleManager.HEAD_COLLECT_1,BattleManager.HEAD_CHANGE_MAX do
		if self["column"..i] then
			self["column"..i]:setPositionY(size.height- offsetY)
		end
	end

end

--设置卡槽以及图标主题
function BattleManager:setCardsSlot(style)
	--槽
    for i=1,13 do
        if self["column"..i] and self["column"..i].setTexture and i ~= 12 then
        	local type_ = "_cardback"
        	if i > 7 and i < 12 then
        		type_ = "_collect"
        	end
        	local fileName_ = "UI_Resources/theme/Theme"..style..type_..".png"
        	local texture = cc.TextureCache:sharedTextureCache():addImage(fileName_)
			if texture then
				self["column"..i]:setTexture(texture)
			end
        end
    end

    function setColor_( color_, sp )
    	if sp then
    		if color_ then
    			sp:setColor(color_)
    			sp:setOpacity(255)
    		else
    			sp:setColor(ccc3(255,255,255))
    			sp:setOpacity(40)
    		end
    	end
    end
    --图标
    local color_ = CardDefine.theme_color[style]
    setColor_(color_, self.sp_go_on)
	setColor_(color_, self.sp_no)
	if self.outOfFlips then
		setColor_(color_, self.outOfFlips_Lb2)
		setColor_(color_, self.outOfFlips_Lb1)
	end
end

function BattleManager:startGame( seed, resetAll )
	self.flipChangeCardsNum_ = 0
	local endAniStatus = GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):getEndAniStatus() or BattleManager.END_ANI_NONE
	local list = GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):getCacheCardList_()

	local cacheData = GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):getCacheData()
	local seed_ai = cacheData:getProperty("seed") or ""
	print("seed---->>>>>",seed,table.nums(list),seed_ai)
	if table.nums(list) <= 0 then
		--没有牌面信息需要判断是否播放结算动画
		if endAniStatus == BattleManager.END_ANI_STUFF then
			self:showStuffAnimation()
		elseif endAniStatus == BattleManager.END_ANI_DIALOG then
			-- self:showWinDialog(true)--胜利弹窗在切屏之后会自动弹出了，这里不处理了
		elseif endAniStatus == BattleManager.END_ANI_END then
			-- todo
		else
			GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):resetCacheData(resetAll)
			self:initCard_(seed)
			--发牌
			self:startDealCard(true)
		end
	else
		local data = GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):getCacheStepByLast()
		if data then
			self.flipCardRound = data:getProperty("flipCardRound")
		else
			self.flipCardRound = 0
		end
		
		self:runReplay()
		--发牌
		self:startDealCard()
		--有牌面信息需要判断是否自动收牌
		if endAniStatus == BattleManager.END_ANI_COLLECTING then
			self:autoCollectCard()
		end
		self:initAISeedGrade(seed_ai)
	end
	
	self.noTipsNum = 0
end

function BattleManager:initAISeedGrade( seed_ai )
	self.aiSeedGrade = SeedGrade.new(seed_ai)
	self.aiSeedGrade:begin()
end

function BattleManager:magicLinkTwoCard_(card_before, card_next, headIndex)
	local userCacheStepVO = UserCacheStepVO.new({
			isMagic = 1
		})
	if not card_next then
		return
	end

	self:retsetJugde_(card_next,headIndex)


	local score = self:calculateScore_(card_before, card_next, headIndex)
	userCacheStepVO:setProperty("score", score)
	userCacheStepVO:setProperty("stepStart", card_next.headIndex_)

	if card_before then
		headIndex = card_before:getProperty("headIndex")
		GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):changeCacheStatusByCardVO(card_before)
	end

  --链接逻辑
  	local card_next_next = card_next:getNextCard()

	if card_next:getBeforeCard() then
		--当card_next不是队首时，需要链接其前后两张
		card_next:getBeforeCard():setNextCard(card_next_next)
	else
		--当card_next是队首时，需要将headlist设置为它的下一张牌
		self.headsList_[card_next.headIndex_] = card_next_next
	end

	if card_next_next then
		card_next_next:setBeforeCard(card_next:getBeforeCard())
		GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):changeCacheStatusByCardVO(card_next_next)
	end
	--链接到新的队列
	card_next:setNextCard(nil)
	card_next:setBeforeCard(nil)

	if card_before then
		card_before:setNextCard(card_next)
		card_next:setBeforeCard(card_before)
	else
		self.headsList_[headIndex] = card_next
	end
	card_next:setProperty("headIndex", headIndex)

	--调整牌面
	card_next:changeBoardTo(CardVO.BOARD_FACE, nil, true)
  --

	--声音
	self:palyCollectAudio(headIndex)

	--保存牌面信息
	GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):changeCacheStatusByCardVO(card_next)
	--保存步骤信息
	userCacheStepVO:setProperty("stepEnd", card_next.headIndex_)
	userCacheStepVO:setProperty("count", 1)
	--此步移动的轮数
	userCacheStepVO:setProperty("flipCardRound", self.flipCardRound)

	GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):saveCacheStep(userCacheStepVO)
	GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):carryOnScore(userCacheStepVO:getProperty("score"))
	GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):addStepCount(1)
	
	local sec = GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):getRunningTime()
	GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):changeCacheData({gameTime = sec})

	self:updateBtnStatus_()
end

--todo 使用魔法棒
function BattleManager:magic()
	local isFishdom = PackageConfigDefine.isSolitaireFishdom()
	if not isFishdom then
		if not GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):judgeMagicNum() then
			DisplayManager.showAlertBox(Localization.string("本局魔法棒使用已达次数上限"))
			return false
		end
	end
	if self.magic_ then
		return false
	end
	self.magic_ = true

	local magic_ = GameManager:getUserData():getMagic()
	if magic_ < 1 then
		self.magic_ = false

		-- local magicShopViewCtrl_ = MagicShopViewCtrl.new()
		-- if magicShopViewCtrl_ then
		-- 	display.getRunningScene():addChild(magicShopViewCtrl_:getView())
		-- end

		--有激励视频填充并还有剩余视频观看次数===水族馆主题的包不用提示
		if not isFishdom then
			local leftCount = GameManager:getUserCache():getLeftRewardVideoShopNum()
			if GameManager:getInstance():hasRewardVideo() and leftCount > 0 then
				local viewCtrl = magicRewardVideoView.new()
	    		display.getRunningScene():addChild(viewCtrl:getView())
				return true
			end
		end

		local shopViewCtrl = ShopViewCtrl.new()
		if shopViewCtrl then
			display.getRunningScene():addChild(shopViewCtrl:getView())
		end
		return false
	end

	local card_,toCard_ = self:findMagicTargetCard_()
	if not card_ then
		DisplayManager.showAlertBox(Localization.string("未找到合适的牌"))
		self.magic_ = false
		return false
	end
	Analytice.onEvent("使用魔法棒(普通)", {})
	GameManager:getUserData():addMagic(-1,true)
	--魔法使用记录
	GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):addMagicNum(1)

	printf("---magic--- %s ----> %d", card_:getCardName(),toCard_.headIndex_-7)

	self:magicAnimation_(card_,toCard_)

	return true
end

function BattleManager:magicAnimation_(card,toCard)

	self:performWithDelay(function ()
			if not card then
				self.magic_ = false
				return
			end
			if not toCard then
				self.magic_ = false
				return
			end
			local fromIndex_ = card.headIndex_
			local toIndex_ = toCard.headIndex_
			local card_before = toCard:getBeforeCard()

			self:reOrderZOrder_( self.headsList_[fromIndex_], 2)
			self:magicLinkTwoCard_(card_before, card, toIndex_)	
			self:moveMagicCards_(card,fromIndex_)
		end,0.5)
	self:performWithDelay(function ( )
		GameManager:getAudioData():playAudio(common.effectSoundList.magicwand)
	end, 0.45)
	local parent_ = card:getView():getParent()
	if not parent_ then
		return
	end
	--动画
	local ani = ArmatureLoader.new("animation/magicwand_hit")
	parent_:addChild(ani,3)
	ani:setPosition(card:getView():getPositionX(), card:getView():getPositionY())
	ani:getAnimation():play("play")
	ani:connectMovementEventSignal(function(__evtType, __moveId)
		if __evtType == 1 and __moveId == "play" then
			ani:removeSelf(true)
		end
	end)

end

function BattleManager:moveMagicCards_(card,fromIndex)
	if not card then
		return
	end
	local headIndex = card.headIndex_
	local pos = ccp(0, 0)
	pos.x, pos.y = self["column"..headIndex]:getPosition()
	local startHeadIndex = fromIndex
	local moveTo = CCEaseSineInOut:create(CCMoveTo:create(0.15, pos))

	local call = CCCallFunc:create(function ( )
		self.magic_ = false
		self:reloadCardsPos()
		self:endMoving(startHeadIndex, headIndex)
		self:playPartical_(headIndex, startHeadIndex)
		self:reOrderZOrder_(self.headsList_[startHeadIndex])
		self:reOrderZOrder_(self.headsList_[headIndex])
		if startHeadIndex == BattleManager.HEAD_CHANGE_1 then
			self:rePosChange1_()
		end
		local beginPos = ccp(card:getView():getPosition())
		self:playScoreAction(beginPos, pos, self:checkMoveNeedAddScore(startHeadIndex, headIndex))
		
	end)
	card:getView():stopAllActions()
	self:startMoving()
	card:getView():runAction(transition.sequence({moveTo,call}))
	
end

function BattleManager:findMagicTargetCard_()
	--所要收的目标牌
	local tList_ = {}
	local nillIndex_ = nil
	for i=BattleManager.HEAD_COLLECT_1,BattleManager.HEAD_COLLECT_MAX do
		local card = self.headsList_[i]
		local eCard_ = DealerController.getQueueEndCardVO(card)
		if eCard_ then
			local rank_ = eCard_.rank_ + 1
			local suit_ = eCard_:getSuit()
			local headIndex_ = eCard_.headIndex_
			local target_ = CardVO.new({
				suit = suit_,
				rank = rank_, 
				headIndex = headIndex_,
				before = eCard_,
				})
			tList_[suit_] = target_
		elseif not nillIndex_ then
			nillIndex_ = i
		end
	end

	for i=CardVO.SUIT_CLUBS,CardVO.SUIT_SPADES do
		if not tList_[i] then
			local target_ = CardVO.new({
				suit = i,
				rank = CardVO.RANK_ACE,
				headIndex = nillIndex_,
				})
			tList_[i] = target_
		end
	end

	--test
	-- for k,v in pairs(tList_) do
	-- 	printf("-----magic----- %s", v:getCardName())
	-- end

	--玩牌区背面的牌
	local bList_ = {}
	for i=BattleManager.HEAD_COLUMN_1,BattleManager.HEAD_COLUMN_MAX do
		if self.headsList_[i] then
			local list_ = DealerController.getListByHead(self.headsList_[i])
			for i=1,#list_ do
				if list_[i].board_ == CardVO.BOARD_BACK then
					bList_[#bList_ + 1] = list_[i]
				end
			end
		end
	end

	for i=#bList_,1,-1 do
		-- printf("--bList_[%d]-:%s",i,bList_[i]:getCardName())
		for k,v in pairs(tList_) do
			if bList_[i].rank_ == v.rank_ and bList_[i]:getSuit() == v:getSuit()  then
				return bList_[i],v
			end
		end
	end

	--切牌区
	local cList_ = {}
	for i=BattleManager.HEAD_CHANGE_MAX,BattleManager.HEAD_CHANGE_1,-1 do
		if self.headsList_[i] then
			local list_ = DealerController.getListByHead(self.headsList_[i])
			for j=1,#list_ do
				cList_[#cList_ + 1] = list_[j]
			end
		end
	end
	-- printf("=======cList_[%d]", #cList_)
	for i=1,#cList_ do
		-- printf("--cList_[%d]-:%s",i,cList_[i]:getCardName())
		for k,v in pairs(tList_) do
			if cList_[i].rank_ == v.rank_ and cList_[i]:getSuit() == v:getSuit()  then
				return cList_[i],v
			end
		end
	end

end

function BattleManager:getEventInfo_()
	local cacheData = GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):getCacheData()
	if not cacheData then
		return 
	end

	local cacheData = GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):getCacheData()
	local seed = cacheData:getProperty("seed") or ""
	local mode = cacheData:getProperty("mode")
	local threeMode = cacheData:getProperty("isDraw3Mode")
	local isDeal = cacheData:getProperty("isDeal")
	local isDailyChallenge = GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):isDailyChallenge()

	local draw_ = "1"
	if tostring(threeMode) == "1" then
		draw_ = "3"
	end

	local gameType_ = "1" --随机局
	if tostring(isDeal) == "1" then --活局
		gameType_ = "2"
	end
	if isDailyChallenge then --每日挑战
		gameType_ = "3"
	end

	local info_ = {
		seed = cacheData:getProperty("seed") or "",
		draw = draw_,
		gameType = gameType_,
	}

	return info_
end

--添加玩法类型累计胜利次数
function BattleManager:saveEnterGameTotalCount(  )
	local cacheData = GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):getCacheData()
	local isDeal = cacheData:getProperty("isDeal")
	local isDailyChallenge = GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):isDailyChallenge()

	local gameType_ = "1" --随机局
	if tostring(isDeal) == "1" then --活局
		gameType_ = "2"
	end
	if isDailyChallenge then --每日挑战
		gameType_ = "3"
	end
	GameManager:getUserClassicData():addEnterGameTotalCount(gameType_,1)
end

function BattleManager:recordBeginEvent_()
	if not self.needRecordBeginEvent_ then
		return
	end

	self:saveEnterGameTotalCount()

	local eventInfo_ = self:getEventInfo_() or {}

	local sumCount = 0
	local m_totalRandom = GameManager:getUserClassicData():getTotalCountByType("totalRandomCount")
    local m_totalWinning = GameManager:getUserClassicData():getTotalCountByType("totalWinningCount")
    local m_totalDaily = GameManager:getUserClassicData():getTotalCountByType("totalDailyCount")
    local m_totalTournament = GameManager:getUserClassicData():getTotalCountByType("totalTournament")

	if eventInfo_.gameType == "1" then
		--随机
		sumCount = m_totalRandom
	elseif eventInfo_.gameType == "2" then
		--活局
		sumCount = m_totalWinning
	elseif eventInfo_.gameType == "3" then
		--每日挑战
		sumCount = m_totalDaily
	end
	eventInfo_.sum = sumCount
	self:recordBeginEventTotal(eventInfo_.gameType,sumCount)
	Analytice.onEventThinkingData("enterBattle", eventInfo_)
	-- dump(eventInfo_,'recordBeginEvent_===>>>')
	self.needRecordBeginEvent_ = false
end

function BattleManager:recordBeginEventTotal( m_type,valueCount )
	local eventInfo_ = {}
	if m_type == "1" then
		--随机
		eventInfo_.sum_enter_random = tostring(valueCount)
		Analytice.onEventuserProperty("sum_enter_random", tostring(valueCount))
	elseif m_type == "2" then
		--活局
		eventInfo_.sum_enter_winning = tostring(valueCount)
		Analytice.onEventuserProperty("sum_enter_winning", tostring(valueCount))
	elseif m_type == "3" then
		--每日挑战
		eventInfo_.sum_enter_daily = tostring(valueCount)
		Analytice.onEventuserProperty("sum_enter_daily", tostring(valueCount))
	end
	-- Analytice.onEventuserProperty("sum_enter_daily", tostring(valueCount))
end

--[[
	--@有类似打点功能，数据结构，参数一致，故改为共有方法
	--@param _type 事件ID
	--@despcription:
]]--
function BattleManager:recordCompleteEvent_(_type)
	local eventInfo_ = self:getEventInfo_() or {}
	local cacheData = GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):getCacheData()
	
	if cacheData then
		eventInfo_.magic = cacheData:getProperty("magicNum")
		eventInfo_.stepCount = cacheData:getProperty("move")
	end
	local score_ = cacheData:getProperty("score") - cacheData:getProperty("scoreDeduct")
	if score_ < 0 then
		score_ = 0
	end
	eventInfo_.score = score_
	local str_VegasAccmulativeMode = "vegas" --是否是维加斯模式
	--需要先判断是否是维加斯模式
	if cacheData:getProperty("isVegasMode") == 0 then
		str_VegasAccmulativeMode = "notVegas" --是否是维加斯模式
	else
		str_VegasAccmulativeMode = (cacheData:getProperty("isVegasAccmulativeMode") == 0) and "vegas" or "vegasCumulative" --是否是维加斯累加模式
	end
	
	local sec = GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):getRunningTime()
	local hintCount = cacheData:getProperty("hintNum")
	local undoCount = cacheData:getProperty("undoNum")
   	eventInfo_.vegas = str_VegasAccmulativeMode
   	eventInfo_.hint = hintCount
   	eventInfo_.undo = undoCount
   	eventInfo_.duration = sec

   	if self.quickundo then
   		eventInfo_.quickundo = "quickundo"
   	end

   	if _type == "completebattle" then
   		local m_winRandom = GameManager:getUserClassicData():getWinCountByType("winRandomCount")
	    local m_winWinning = GameManager:getUserClassicData():getWinCountByType("winWinningCount")
	    local m_winDaily = GameManager:getUserClassicData():getWinCountByType("winDailyCount")
	    local m_winTournament = GameManager:getUserClassicData():getWinCountByType("winTournamentCount")
   		local sumCount = 0
   		if eventInfo_.gameType == "1" then
   			--随机
   			sumCount = m_winRandom
   		elseif eventInfo_.gameType == "2" then
   			--活局
   			sumCount = m_winWinning
   		elseif eventInfo_.gameType == "3" then
   			--每日挑战
   			sumCount = m_winDaily
   		end
   		eventInfo_.sum = sumCount
   	end
	
	dump(eventInfo_,'recordCompleteEvent_====>>>>>')
	Analytice.onEventThinkingData(_type, eventInfo_)
end

 function BattleManager:recordCompleteEventTotalWin( ... )
 	local tabEventInfo = self:getEventInfo_() or {}
 	local eventInfo_ = {}
 	local m_winRandom = GameManager:getUserClassicData():getWinCountByType("winRandomCount")
    local m_winWinning = GameManager:getUserClassicData():getWinCountByType("winWinningCount")
    local m_winDaily = GameManager:getUserClassicData():getWinCountByType("winDailyCount")
    local m_winTournament = GameManager:getUserClassicData():getWinCountByType("winTournamentCount")
    
 	if tabEventInfo.gameType == "1" then
		--随机
		eventInfo_.sum_win_random = tostring(m_winRandom)
		Analytice.onEventuserProperty("sum_win_random", tostring(m_winRandom))
	elseif tabEventInfo.gameType == "2" then
		--活局
		eventInfo_.sum_win_winning = tostring(m_winWinning)
		Analytice.onEventuserProperty("sum_win_winning", tostring(m_winWinning))
	elseif tabEventInfo.gameType == "3" then
		--每日挑战
		eventInfo_.sum_win_daily = tostring(m_winDaily)
		Analytice.onEventuserProperty("sum_win_daily", tostring(m_winDaily))
	end
	-- Analytice.onEventuserProperty("", eventInfo_)
end

function BattleManager:judgeIsNewUser( ... )
	local m_winRandom = GameManager:getUserClassicData():getWinCountByType("winRandomCount")
    local m_winWinning = GameManager:getUserClassicData():getWinCountByType("winWinningCount")
    local isNewPlayer = GameManager:getUserClassicData():isNewPlayer()--就算是随机局也给新玩家使用活局种子
    -- print("新手isNewPlayer===>>>>",isNewPlayer,m_winRandom,m_winWinning)
    local isNewUser = false
    if (m_winRandom < 1 and m_winWinning < 1) and isNewPlayer then
    	isNewUser = true
    end
    return isNewUser
end

function BattleManager:initCard_( _seed )
	--获取牌组
	local list = DealerController.initCards()
	local seed_ = ""
	local isNewPlayer = false
	local isNewUser = false
	--如果不是重玩本局
	if not _seed then
		--判断是否是活局
		local userDM = GameManager:getUserData()
		local isSolvedMode = userDM:isSolvedMode() --是否是活局
		local isDraw3 = (userDM:getProperty("isDraw3Mode") ~= 0) --是否是摸3张牌
		

		local isVegasMode = (userDM:getProperty("isVegasMode") ~= 0) --是否是维加斯模式
		isNewPlayer = GameManager:getUserClassicData():isNewPlayer()--就算是随机局也给新玩家使用活局种子
		isNewUser = self:judgeIsNewUser()
		isNewUser = (isNewUser and not isDraw3 and not isVegasMode)
		if isNewUser then
			_seed = common.getSeedRandomWithNewPlayer()
			print("新手局使用种子：",_seed)
		else
			if isSolvedMode then
				local draw = (isDraw3 and 3) or 1
				_seed = userDM:getDealSeed(draw)
			else
				local isVegasMode = (userDM:getProperty("isVegasMode") ~= 0) --是否是维加斯模式
				isNewPlayer = GameManager:getUserClassicData():isNewPlayer()--就算是随机局也给新玩家使用活局种子
				isNewPlayer = (isNewPlayer and not isDraw3 and not isVegasMode)
				if isNewPlayer then
					_seed = userDM:getDealSeed(1)
					printf("新手局使用种子：%s",_seed)
				end
			end
		end
	end

	--洗牌
	list, seed_ = DealerController.shuffleCards(list, _seed)
	print("=== seed [] ",tostring(seed_))
	self:initAISeedGrade(seed_)

	GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):changeCacheData({seed = seed_, gameState = UserCacheRecordVO.status_playing, isNewPlayer = ((isNewPlayer and 1) or 0)})
	EventNoticeManager:getInstance():dispatchEvent({name = Notice.GAME_STATUS_CHANGE})
	local cacheList = {}

	function linkCard_( before, cardVO, headIndex )
		cardVO:setBeforeCard(before)
		cardVO:setProperty("headIndex", headIndex)
		if before == nil then
			self.headsList_[headIndex] = cardVO
		else
			before:setNextCard(cardVO)
		end
		cacheList[#cacheList+1] = cardVO
	end

	local backCardList_ = {}
	local isDailyChallenge = GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):isDailyChallenge()
	local isVegasMode = GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):isVegasMode()
	local isLite = GameManager:getInstance():judgeIsLiteVersion()
	local needFlipCoin_ = (not isDailyChallenge) and (not isVegasMode) and (not isLite)

	for column=1,7 do
		local before = nil
		for num=1,column do
			local cardVO = list[1]
			table.remove(list, 1)
			linkCard_(before, cardVO, column)

			if num < column and needFlipCoin_ then
				backCardList_[#backCardList_ + 1] = cardVO
			end
			before = cardVO
		end
	end

	if needFlipCoin_ then
		self:randomFlipCoin_(backCardList_)
	end

	--剩余的牌在换牌区
	local before = nil
	for i=1,#list do
		local cardVO = list[i]
		linkCard_(before, cardVO, BattleManager.HEAD_CHANGE_MAX)
		cardVO:setProperty("board", CardVO.BOARD_BACK)
		before = cardVO
	end

	GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):changeCacheStatusByCardList(cacheList)

	self.needRecordBeginEvent_ = true
end

function BattleManager:randomFlipCoin_(list)
	local numMin_ = GameManager:getUserCache():getProperty("flipNumMin")
	local numMax_ = GameManager:getUserCache():getProperty("flipNumMax")
	math.randomseed(string.reverse(tostring(os.time())))
	local flipNum_ = math.random(numMin_,numMax_)
	for i=1,flipNum_ do
		local max_ = #list
		local index_ = math.random(1,max_)
		index_ = math.floor(index_)
		if list[index_] then
			list[index_].isFlipReward_ = 1
			table.remove(list,index_)
		end
	end
end

function BattleManager:judgeCardFlipCoin(cardVO)
	if cardVO.isFlipReward_ == 0 then
		return
	end
	local view_ = cardVO:getView()
	local wPos_ = view_:convertToWorldSpaceAR(view_:getAnchorPoint())

	if not self.delegate_ then
		return
	end
	if self.delegate_.popCoinNode then
		self.delegate_:popCoinNode()
	end

	local wEndPos_ = self.delegate_.coinNodePos:convertToWorldSpaceAR(self.delegate_.coinNodePos:getAnchorPoint())
    local toPos_ = ccp(30, wEndPos_.y)

    local midPos_ = ccp(wPos_.x+math.random(-150,150), wPos_.y+math.random(-150,-250))
    
    local num_ = 1
    for i=1,num_ do
    	local delay_ = i*0.1

    	local dropRewardVO_ = DropRewardVO.new({
		    	index = i,--索引
				speedX = spX_,--X轴速度
				speedY = spY_,--Y轴速度
				x = wPos_.x,--X坐标
				y = wPos_.y,--Y坐标
				toPosX = toPos_.x,
				toPosY = toPos_.y,
	    	})
		dropRewardVO_:setCallBack(handler(self, self.flyEndCall_))

		local dropView_ = dropRewardVO_:getView()
		dropView_:setVisible(false)
		self.delegate_.view_:addChild(dropView_,num_ - i + 1)
		local index_ = i
		local seq = transition.sequence({
					CCDelayTime:create(delay_),
	                CCCallFunc:create(function()
	                	if index_ == 1 then
	                		GameManager:getAudioData():playAudio(common.effectSoundList.goldcoin_out)
	                	end
	                	dropRewardVO_:getView():setVisible(true)
		    			dropRewardVO_:playflyAction(midPos_,nil,0.4,0.7)
		            end),
	            })
		dropView_:runAction(seq)
    end
	cardVO.isFlipReward_ = 0

end

function BattleManager:flyEndCall_(dropRewardVO)
	dropRewardVO:clean()
	if dropRewardVO.index_ ~= 1 then
		return
	end
	if self.delegate_.addCoin then
		self.delegate_:addCoin(GameManager:getUserCache():getProperty("flipCoin"))
	end
end

function BattleManager:isPortrait_( )
	return CONFIG_SCREEN_ORIENTATION == "portrait"
end

function BattleManager:getCardOffsetY_( face )
	local isPortrait = self:isPortrait_()
	if face == CardVO.BOARD_BACK then
		return 10
	end
	if isPortrait then
		return 40
	else
		return 40
	end
end

function BattleManager:getCardOffsetX_( )
	return 40
end

--左手模式变更了
function BattleManager:leftModeChanged( )
	local left_mode = GameManager:getUserData():getIsLeft()
	local width = self.card_table:getContentSize().width
	local maxCount = BattleManager.HEAD_COLUMN_MAX
	if left_mode > 0 then
		if self.isLeft_ then
			return
		end
		self.isLeft_ = true
		--启用左手模式
		-- for i=BattleManager.HEAD_COLUMN_1,BattleManager.HEAD_COLUMN_MAX do
		-- 	self["column"..i]:setPositionX(width-width/maxCount/2*(2*i-1))
		-- end
		for i=BattleManager.HEAD_COLLECT_1,BattleManager.HEAD_COLLECT_MAX do
			local index = i - maxCount
			self["column"..i]:setPositionX(width-width/maxCount/2*(2*index-1))
		end
		self["column"..BattleManager.HEAD_CHANGE_MAX]:setPositionX(width/maxCount/2)
		self["column"..BattleManager.HEAD_CHANGE_1]:setPositionX(width/maxCount/2*3+self:getCardOffsetX_()*2)
	else
		if not self.isLeft_ then
			return
		end
		self.isLeft_ = false
		--关闭左手模式
		-- for i=BattleManager.HEAD_COLUMN_1,BattleManager.HEAD_COLUMN_MAX do
		-- 	self["column"..i]:setPositionX(width/maxCount/2*(2*i-1))
		-- end
		for i=BattleManager.HEAD_COLLECT_1,BattleManager.HEAD_COLLECT_MAX do
			local index = i - maxCount
			self["column"..i]:setPositionX(width/maxCount/2*(2*index-1))
		end
		self["column"..BattleManager.HEAD_CHANGE_MAX]:setPositionX(width-width/maxCount/2)
		self["column"..BattleManager.HEAD_CHANGE_1]:setPositionX(width-width/maxCount/2*3)
	end
	self:reloadCardsPos()
	self:clearLight_()
end

function BattleManager:reloadCardsPos( )
	--牌桌上的卡牌
	for i=BattleManager.HEAD_COLUMN_1,BattleManager.HEAD_CHANGE_MAX do
		local card = self.headsList_[i]
		local offset_pos = ccp(0, 0)
		while card do
			local sprite = card:getView()
			if sprite then
				sprite:setPosition(ccp(self["column"..i]:getPositionX() + offset_pos.x,
					self["column"..i]:getPositionY() + offset_pos.y))
				if not sprite:getParent() then
					self.card_table:addChild(sprite)
				end
			else
				printf("no card sprite!")
			end
			if i >= BattleManager.HEAD_COLUMN_1 and i <= BattleManager.HEAD_COLUMN_MAX then
				offset_pos.y = offset_pos.y - self:getCardOffsetY_(card:getProperty("board"))
			else
				offset_pos.y = 0
			end
			card = card:getNextCard()
		end
		self:dealOffsetY(i)
	end

	self:rePosChange1_()
end

function BattleManager:rePosChange1_()
	local card = self.headsList_[BattleManager.HEAD_CHANGE_1]
	if card then
		card = DealerController.getQueueEndCardVO(card)
	end
	local offsetX = 0
	while card do
		local sprite = card:getView()
		if sprite then
			sprite:setPosition(ccp(self["column"..BattleManager.HEAD_CHANGE_1]:getPositionX()-offsetX, 
				self["column"..BattleManager.HEAD_CHANGE_1]:getPositionY()))
		else
			printf("no card sprite!")
		end
		offsetX = offsetX + self:getCardOffsetX_()
		if offsetX > 2*self:getCardOffsetX_() then
			offsetX = 2*self:getCardOffsetX_()
		end
		card = card:getBeforeCard()
	end
end

function BattleManager:startDealCard( animation )
	self:stopAllActions()
	self.playing = false
	self:leftModeChanged()
	--此时才开始创建卡牌的形象
	if animation then
		self:startMoving()
		for i=BattleManager.HEAD_COLUMN_1,BattleManager.HEAD_CHANGE_MAX do
			local card = self.headsList_[i]
			while card do
				local sprite = card:getView()
				if sprite then
					sprite:setPosition(ccp(self["column"..BattleManager.HEAD_CHANGE_MAX]:getPositionX(), 
						self["column"..BattleManager.HEAD_CHANGE_MAX]:getPositionY()))
					if not sprite:getParent() then
						self.card_table:addChild(sprite)
					end
				else
					printf("no card sprite!")
				end
				card = card:getNextCard()
			end
		end
		--屏蔽触摸和按钮
	    local touchNode = self:addTouchLayer_(display.getRunningScene(), ccc4(0, 0, 0, 0))

		function showAni( headIndex, card, count, offsetX )
			if headIndex > BattleManager.HEAD_COLUMN_MAX then
				self:endMoving()
				touchNode:removeSelf(true)
				return
			end
			if not card then
				showAni(headIndex+1, self.headsList_[headIndex+1], 0, 0)
			else
				if card:getBeforeCard() then
					offsetX = offsetX + self:getCardOffsetY_(card:getBeforeCard():getProperty("board"))
				end
				local move = CCMoveTo:create(0.25, ccp(self["column"..headIndex]:getPositionX(), 
					self["column"..headIndex]:getPositionY() - offsetX))--count*self:getCardOffsetY_()))
				local call = CCCallFunc:create(function ()
					GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):changeCacheStatusByCardVO(card)
				end)
				if card:getNextCard() then
					card:getView():runAction(move)
				else
					card:changeBoardTo(CardVO.BOARD_FACE)
					card:getView():runAction(transition.sequence({move, call}))
				end

				self:performWithDelay(function ()
					showAni(headIndex, card:getNextCard(), count + 1, offsetX)
				end,0.02)
			end
			if not self.playing then
				self.playing = true
				self:performWithDelay(function ()
						self.playing = false
					end,0.05)
				GameManager:getAudioData():playAudio(common.effectSoundList.tableau)
			end

		end
		showAni(BattleManager.HEAD_COLUMN_1, self.headsList_[BattleManager.HEAD_COLUMN_1], 0, 0)

	else
		self:reloadCardsPos()
	end

	for i=BattleManager.HEAD_COLUMN_1,BattleManager.HEAD_CHANGE_MAX do
		--设置卡牌的回调
		local card = self.headsList_[i]
		while card do
			card:getView():setZOrder(0)
			card:getView():setTouchBegin(handler(self, self.cardTouchBegan))
			card:getView():setTouchMoving(handler(self, self.cardTouchMoving))
			card:getView():setTouchEnd(handler(self, self.cardTouchEnd))
			card:getView():setTouchCancel(handler(self, self.cardTouchCancel))
			card = card:getNextCard()
		end

	end
	self:analysisCollectCard_()
	self.btn_autoCollect:setOpacity(255*0.95)
	self:updateBtnStatus_()
end

function BattleManager:runReplay( )
	self.showMoveAni_ = false
	--根据配置信息复盘
	function linkCard_( before, cardVO, headIndex )
		cardVO:setBeforeCard(before)
		cardVO:setProperty("headIndex", headIndex)
		if before == nil then
			self.headsList_[headIndex] = cardVO
		else
			before:setNextCard(cardVO)
		end
	end
	local list = GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):getCacheCardList_()
	for k,v in pairs(list) do
		if v and #v > 0 then
			local before = nil
			for i=1,#v do
				local cardVO = v[i]
				if cardVO then
					cardVO:clearView()
					linkCard_(before, cardVO, k)
					if i == #v and k >= BattleManager.HEAD_COLUMN_1 and k <= BattleManager.HEAD_COLUMN_MAX then
						--保证最后一张牌一定是正面的
						cardVO:changeBoardTo(CardVO.BOARD_FACE)
					end
					if k >= BattleManager.HEAD_COLLECT_1 and k <= BattleManager.HEAD_COLLECT_MAX then
						--保证集卡区的牌一定是正面
						cardVO:changeBoardTo(CardVO.BOARD_FACE)
					end
					before = cardVO
				end
			end
		end
	end

	self.showMoveAni_ = true
end

function BattleManager:cleanTouchData_( )
	self.pre_x = 0
	self.pre_y = 0
	self.card_pre_x = {}
	self.card_pre_y = {}
	self.click_ = true
end

function BattleManager:getCollectionEndCardVO( _headindex )
	local suitRank = {}
	suitRank.suit = 0
	suitRank.rank = 0
	suitRank.color = 0
	suitRank.ZeroValue = 0
	local end_card = self.headsList_[_headindex]
	if end_card then
		end_card = DealerController.getQueueEndCardVO(end_card)
		local suit = end_card:getProperty("suit")
		local rank = end_card:getProperty("rank")
		local colorCard = end_card:getCardColor()
		suitRank.suit = suit
		suitRank.rank = rank
		suitRank.color = colorCard
	end
	return suitRank
end

function BattleManager:MaxMinWithValue( valueTable )
	local m_max = {}
	local m_min = {}
	local temp = {}
	if valueTable[1].rank >= valueTable[2].rank then
		table.merge(m_max,valueTable[1])
		table.merge(m_min,valueTable[2])
	else
		table.merge(m_max,valueTable[2])
		table.merge(m_min,valueTable[1])
	end
	return m_max,m_min
end

--[[
--@param不可收集牌类型的集合
]]
function BattleManager:autoSpeedCollection( cardSp )
	
	local m_tabCollectRed = {}
	local m_tabCollectBlack = {}
	local m_tabCollect = {}
	local m_tabCollectEmpty = {}
	--不可快速集牌数组
	local m_notFastCollect = {}
	--判断集牌区
	for i=BattleManager.HEAD_COLLECT_1,BattleManager.HEAD_COLLECT_MAX do
		local m_tabCard = self:getCollectionEndCardVO(i)
		m_tabCollect[i-7] = m_tabCard
		if m_tabCard.color == 1 then
			--红色系
			table.insert(m_tabCollectRed,m_tabCard)
		elseif m_tabCard.color == 2 then
			--黑色系
			table.insert(m_tabCollectBlack,m_tabCard)
		else
			table.insert(m_tabCollectEmpty,m_tabCard)
		end
	end
	for i,v in ipairs(m_tabCollectEmpty) do
		if #m_tabCollectRed < 2 then
			table.insert(m_tabCollectRed,v)
		else
			table.insert(m_tabCollectBlack,v)
		end
	end
	local red_max,red_min = self:MaxMinWithValue(m_tabCollectRed)
	local black_max,black_min = self:MaxMinWithValue(m_tabCollectBlack)
	if ( red_max.rank - black_min.rank ) >= 2 then
		table.insert(m_notFastCollect,red_max)
	end
	if ( black_max.rank - red_min.rank ) >= 2 then
		table.insert(m_notFastCollect,black_max)
	end 
	if red_min.rank == red_max.rank and ( red_max.rank - black_min.rank ) >= 2 then
		table.insert(m_notFastCollect,red_min)
	end

	if black_min.rank == black_max.rank and ( black_max.rank - red_min.rank ) >= 2 then
		table.insert(m_notFastCollect,black_min)
	end

	for i,v in ipairs(m_notFastCollect) do
		if v.color == cardSp:getCardColor() and v.suit == cardSp:getProperty("suit") then
			return false
		end
	end
	return true
end

function BattleManager:speedAutoCollection( ... )
	--[0:表示未开启快速收牌 1:表示开启快速收牌]
	local isQuickCollect = GameManager:getUserCache():getProperty("QuickPlay")
	if isQuickCollect == 0 then
		return
	end
	local is_autoCollection = GameManager:getUserData():getProperty("isOpenSpeedCollection")
	if is_autoCollection == 1 then
		self.clickHeadIndex = 1
		function speedLinkCard( card_before, card_next, headIndex )
			--分数统计
			GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):addStepCount(1)
			local score = self:calculateScore_(card_before, card_next, headIndex)
			GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):carryOnScore(score)
			EventNoticeManager:getInstance():dispatchEvent({name = Notice.GAME_DATA_CHANGE})
			--保持原链接的完整性
			if card_next:getBeforeCard() then
				--当card_next不是队首时，需要链接其前后两张
				card_next:getBeforeCard():setNextCard(card_next:getNextCard())
			else
				--当card_next是队首时，需要将headlist设置为它的下一张牌
				self.headsList_[card_next:getProperty("headIndex")] = card_next:getNextCard()
			end
			if card_next:getNextCard() then
				card_next:getNextCard():setBeforeCard(card_next:getBeforeCard())
			end
			GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):changeCacheStatusByCardVO(card_next:getNextCard())
			--链接到新的队列
			card_next:setNextCard(nil)
			card_next:setBeforeCard(nil)
			if card_before then
				card_before:setNextCard(card_next)
				card_next:setBeforeCard(card_before)
			else
				self.headsList_[headIndex] = card_next
			end
			card_next:setProperty("headIndex", headIndex)
			--保存牌面信息
			GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):changeCacheStatusByCardVO(card_next)
		end
		function speedCanCollect( card_before, card_next, rank, suit, headIndex )
			local m_isCollect = self:autoSpeedCollection(card_next)
			if (rank == 0 or card_next:getProperty("suit") == suit) and card_next:getProperty("rank") == rank + 1 and m_isCollect then
				self:linkTwoCard(card_before, card_next, headIndex)
				self:didAddCardToOpen()
				return true
			end
			return false
		end
		function speedCollect( headIndex )
			if headIndex < BattleManager.HEAD_COLLECT_1 or headIndex > BattleManager.HEAD_COLLECT_MAX then
				return false
			end
			local suit = 0--花色
			local rank = 0--点数
			local end_card = self.headsList_[headIndex]
			if end_card then
				end_card = DealerController.getQueueEndCardVO(end_card)
				suit = end_card:getProperty("suit")
				rank = end_card:getProperty("rank")
			end
			--判断牌桌上的
			for i=BattleManager.HEAD_COLUMN_1,BattleManager.HEAD_COLUMN_MAX do
				local last_card = self.headsList_[i]

				if last_card then
					last_card = DealerController.getQueueEndCardVO(last_card)
					-- print("牌桌上的卡牌 =====>>>>>>",last_card:getProperty("suit"),last_card:getProperty("rank"))
					if speedCanCollect(end_card, last_card, rank, suit, headIndex) then
						last_card:changeBoardTo(CardVO.BOARD_FACE, nil, true)
						return true, last_card, headIndex, i
					end
				end
			end

			--判断集牌区
			if self.qucikClickChange then
				for i=BattleManager.HEAD_CHANGE_1,BattleManager.HEAD_CHANGE_1 do
					local last_card = self.headsList_[i]
					
					while last_card do
						last_card = DealerController.getQueueEndCardVO(last_card)
						-- print("lastCard===>>>",last_card:getProperty("suit"),last_card:getProperty("rank"))
						if speedCanCollect(end_card, last_card, rank, suit, headIndex) then
							last_card:changeBoardTo(CardVO.BOARD_FACE, nil, true)
							return true, last_card, headIndex, i
						end
						last_card = last_card:getNextCard()
					end
				end
			end
			
			return false
		end
		function speedCollectCard( ... )
			--开始判断
			for i=BattleManager.HEAD_COLLECT_1,BattleManager.HEAD_COLLECT_MAX do
				local ok, card, headIndex, lastHeadIndex = speedCollect(i)
				if ok then
					printf("开始自动收牌:%s", card:getCardName())
					local pos = ccp(0, 0)
					pos.x, pos.y = self["column"..i]:getPosition()
					local beginPos = ccp(card:getView():getPosition())
					local move = CCMoveTo:create(0.1, pos)
					card:getView():stopAllActions()
					card:getView():runAction(transition.sequence({CCEaseSineInOut:create(move), CCCallFunc:create(function ()
						self:analysisCollectCard_()
						self:playPartical_(headIndex, 0)
						self:playScoreAction(beginPos, pos, self:checkMoveNeedAddScore(lastHeadIndex, i))
					end)}))
					self:reOrderZOrder_(card)
					self:palyCollectAudio(i, true)
					break
				end
				-- print("======>>>>>>",i,BattleManager.HEAD_COLLECT_MAX,ok)
				if i == BattleManager.HEAD_COLLECT_MAX and ok == false then
					if self.speedSchedule then
						self:stopAction(self.speedSchedule)
						self.speedSchedule = nil
					end
				end
			end
			self.speedSchedule = self:performWithDelay(function ()
				speedCollectCard( )
			end,0.2)
		end
		speedCollectCard()
		
	end
end

function BattleManager:cardTouchBegan( cardSp, x, y )
	self:resumeGame(true)

	if self.speedSchedule then
		self:stopAction(self.speedSchedule)
		self.speedSchedule = nil
	end
	
	-- if self.cardMoving_ then
	-- 	return false
	-- end
	if self.magic_ then
		return false
	end
	-- print("cardSp.data_.headIndex_===>>>",cardSp.data_.headIndex_)

	
	if DealerController.judgePickUp(cardSp.data_) ~= DealerController.PICK_ABLE then
		return false
	end
	if cardSp.data_.headIndex_ == BattleManager.HEAD_CHANGE_1 and cardSp.data_.next_ then
		return false
	end
	-- print("cardSp.data_.headIndex===>>>>>",cardSp.data_.headIndex_,BattleManager.HEAD_CHANGE_1)
	self.clickHeadIndex = cardSp.data_.headIndex_

	self:cleanTouchData_()
	self.pre_x = x
	self.pre_y = y
	local card = cardSp.data_
	self:reOrderZOrder_(card, 1)
	local count = 0
	-- self.lightContenSizeOffsetY_ = 0
	while card do
		-- self.lightContenSizeOffsetY_ = -count*5
		local cardSp = card:getView()
		self.card_pre_x[card] = cardSp:getPositionX()
		self.card_pre_y[card] = cardSp:getPositionY()
		-- self.card_pre_y[card] = cardSp:getPositionY() + count*5
		card = card:getNextCard()
		count = count + 1
	end
	cardSp.data_:changeBoardTo(CardVO.BOARD_FACE, nil, true)
	self:clearLight_()
	if cardSp.data_.headIndex_ ~= BattleManager.HEAD_CHANGE_1 then
		self.light_ = self:addLight_(cardSp.data_)
	end
	return true
end

function BattleManager:cardTouchMoving( cardSp, x, y )
	if tolua.isnull(cardSp) then
		return
	end
	if not x then
		return
	end
	if not y then
		return
	end
	local card = cardSp.data_
	while card and not tolua.isnull(card:getView()) do
		if math.abs(x - self.pre_x)/self:getScaleX() > 20 or math.abs(y - self.pre_y)/self:getScaleY() > 20 then
			self.click_ = false
		end
		local cardSp = card:getView()
		if self.card_pre_x[card] ~= nil and self.card_pre_y[card] ~= nil then
			cardSp:setPosition(ccp(self.card_pre_x[card] + (x - self.pre_x)/self:getScaleX(),
				self.card_pre_y[card] + (y - self.pre_y)/self:getScaleY()))
		end
		card = card:getNextCard()
	end
	-- if self.lightContenSizeOffsetY_ and self.lightContenSizeOffsetY_ ~= 0 then
	-- 	local size = self.light_:getContentSize()
	-- 	self.light_:setContentSize(CCSizeMake(size.width, size.height+self.lightContenSizeOffsetY_))
	-- 	self.lightContenSizeOffsetY_ = 0
	-- end
end

function BattleManager:cardTouchEnd( cardSp, x, y )
	local startHeadIndex = cardSp.data_.headIndex_
	if self.click_ then
		--点击结束，判断牌桌和集牌区
		local ok, selectCard, headIndex= self:findLink_(cardSp.data_,BattleManager.ALL_CON)
		if ok then
			if selectCard then
				selectCard = DealerController.getQueueEndCardVO(selectCard)
			end
			self:linkTwoCard(selectCard, cardSp.data_, headIndex)
		else
			cardSp:shake(true)
			GameManager:getAudioData():playAudio(common.effectSoundList.shake_card)
		end
	else
		--拖动结束，判断牌桌和集牌区
		local selectCard = nil
		local headIndex = 0
		local areaIndex = 0
		local areaSelectCard = nil
		local areaM_ = 0
		for i=BattleManager.HEAD_COLUMN_1,BattleManager.HEAD_COLLECT_MAX do
			if cardSp.data_.headIndex_ ~= i then
				local card = self.headsList_[i]
				if not card then
					--手指点与底座判断
					if common.judgeTouchInNode(ccp(x, y),self["column"..i]) then
						headIndex = i
						break
					end
					--手牌与底座的相交面积判断
					local area_ = common.judgeNodeInNode(cardSp:getAreaNode(),self["column"..i])
					if areaM_ < area_ then
						areaM_ = area_
						areaIndex = i
					end
				end
				while card do
					--手指点与牌判断
					if common.judgeTouchInNode(ccp(x, y),card:getView()) then
						selectCard = card
						headIndex = i
						break
					end
					--手牌与牌的相交面积判断
					local area_ = common.judgeNodeInNode(cardSp:getAreaNode(),card:getView():getAreaNode())
					if areaM_ < area_ then
						areaSelectCard = card
						areaM_ = area_
						areaIndex = i
					end
					card = card:getNextCard()
				end
			end
			if selectCard or headIndex > 0 then
				break
			end
		end
		-- printf("headIndex [%s] / areaIndex[%s]",tostring(headIndex),tostring(areaIndex))
		if headIndex == 0 then
			headIndex = areaIndex
			selectCard = areaSelectCard
		end
		if headIndex > 0 and headIndex <= BattleManager.HEAD_COLUMN_MAX and DealerController.judgePutDown(selectCard,cardSp.data_) or
			(headIndex >= BattleManager.HEAD_COLLECT_1 and headIndex <= BattleManager.HEAD_COLLECT_MAX 
				and DealerController.judgeCollectCard(selectCard,cardSp.data_)) then
			if selectCard then
				selectCard = DealerController.getQueueEndCardVO(selectCard)
			end
			--可以插入队列
			self:linkTwoCard(selectCard, cardSp.data_, headIndex)
			
		else
			--返回原队列
		end
	end
	local card = cardSp.data_

	self:moveCards(card, startHeadIndex,true)
	self:clearLight_(true)
	self:cleanTouchData_()

end

function BattleManager:moveCards( card,startHeadIndex ,m_foor)
	self.m_foor = m_foor
	if startHeadIndex == BattleManager.HEAD_CHANGE_1 then
		self:didAddCardToOpen()
	end
	if not card then
		return
	end
	local headIndex = card.headIndex_
	if headIndex == BattleManager.HEAD_CHANGE_1 then
		return
	end

	if startHeadIndex >= 8 and startHeadIndex <= 11 then
		if self.speedSchedule then
			self:stopAction(self.speedSchedule)
			self.speedSchedule = nil
		end
	end
	
	local pos = ccp(0, 0)
	pos.x, pos.y = self["column"..headIndex]:getPosition()
	if card:getBeforeCard() and headIndex <= BattleManager.HEAD_COLUMN_MAX then
		pos.y = card:getBeforeCard():getView():getPositionY()
	end

	local beginPos = ccp(card:getView():getPosition())

	while card and not tolua.isnull(card:getView()) do
		if card:getBeforeCard() and headIndex <= BattleManager.HEAD_COLUMN_MAX then
			pos.y = pos.y - self:getCardOffsetY_(card:getBeforeCard():getProperty("board"))
		end
		self:startMoving()
		local moveTo = CCEaseSineInOut:create(CCMoveTo:create(0.15, pos))
		card:getView():stopAllActions()
		if card:getNextCard() then
			local score = self:checkMoveNeedAddScore(startHeadIndex, headIndex)
			local call = CCCallFunc:create(function ( )
				self:playScoreAction(beginPos, pos, score)
			end)
			card:getView():runAction(transition.sequence({moveTo, call}))
		else
			local call = CCCallFunc:create(function ( )
				self:endMoving(startHeadIndex, headIndex,m_foor)
				self:playPartical_(headIndex, startHeadIndex)
				local score = self:checkMoveNeedAddScore(startHeadIndex, headIndex)
				if score > 0 then
					self:playScoreAction(beginPos, pos, score)
				end
			end)
			card:getView():runAction(transition.sequence({moveTo, call}))
		end
		card = card:getNextCard()
	end

	self:reOrderZOrder_(self.headsList_[headIndex])
end

function BattleManager:cardTouchCancel( cardSp, x, y )
	self:cardTouchEnd(cardSp, x, y)
end

local function judgeCollect_(curCard,list)
	if curCard.headIndex_ >= BattleManager.HEAD_COLLECT_1 and curCard.headIndex_ <= BattleManager.HEAD_COLLECT_MAX then
		--点击的是收集区的卡牌就不在判断是否可收集了
		return false, nil, 0
	end
	--优先判断是否可收集
	if not curCard:getNextCard() then
		--可收集时必定是最后一张牌
		for i=BattleManager.HEAD_COLLECT_1,BattleManager.HEAD_COLLECT_MAX do
			if i ~= curCard.headIndex_ then
				local card = list[i]
				if card then
					card = DealerController.getQueueEndCardVO(card)
				end
				if DealerController.judgeCollectCard(card,curCard) then
					return true, card, i
				end
			end
		end
	end
	return false, nil, 0
end

local function judgeMove_(curCard,list)
	for i=BattleManager.HEAD_COLUMN_1,BattleManager.HEAD_COLUMN_MAX do
		if DealerController.judgePickUp(curCard) == DealerController.PICK_ABLE then
			--判断序列是否可被拾取
			if i ~= curCard.headIndex_ then
				local card = list[i]
				if card then
					card = DealerController.getQueueEndCardVO(card)
				end
				if DealerController.judgePutDown(card,curCard) then
					return true, card, i
				end
			end
		end
	end
	return false, nil, 0
end

BattleManager.ALL_CON = 0 --全都判断
BattleManager.ONLY_COLLECT = 1 --只判断收牌
BattleManager.ONLY_MOVE = 2 --只判断移牌

function BattleManager:findLink_( curCard, condition )
	-- if curCard.headIndex_ >= BattleManager.HEAD_COLLECT_1 and curCard.headIndex_ <= BattleManager.HEAD_COLLECT_MAX then
	-- 	--点击的时候不允许集卡区的牌移动，但可以拖动移动，减少计算量
	-- 	return false, nil, 0
	-- end

	if condition == BattleManager.ONLY_COLLECT then
		return judgeCollect_(curCard,self.headsList_)
	elseif condition == BattleManager.ONLY_MOVE then
		return judgeMove_(curCard,self.headsList_)
	else		
		local _b,_c,_i = judgeCollect_(curCard,self.headsList_)
		if _b then
			return _b,_c,_i
		end
		return judgeMove_(curCard,self.headsList_)
	end
	return false, nil, 0
end

function BattleManager:addLight_( card, node )
	if not card then
		return
	end
	local count = DealerController.getQueueLenByHead(card) - 1
	local offsetY = card:getView():getPositionY()
	card = DealerController.getQueueEndCardVO(card)
	offsetY = offsetY - card:getView():getPositionY()
	if node then
		offsetY = 0
	else
		node = card:getView()
	end
	local size = card:getView():getContentSize()
	local rect = CCRectMake(20, 20, 5, 4)
	size.height = size.height + offsetY
	local light = display.newScale9Sprite("#poker_shine.png", 0, 0, CCSizeMake(size.width+16, size.height+14), rect)
	light:setAnchorPoint(ccp(0.5, 0))
	light:setPosition(ccp(size.width/2, -4))
	node:addChild(light, 5)
	local fadeOut = CCFadeOut:create(0.5)
	local fadeIn = CCFadeIn:create(0.5)
	local action = CCRepeatForever:create(transition.sequence({fadeOut, fadeIn}))
	light:runAction(action)
	return light
end

function BattleManager:clearLight_(openTimeJudge)
	if self.light_ then
		self.light_:removeSelf()
		self.light_ = nil
	end
	if openTimeJudge then
		--15秒之后自动提示
		if self.schedulerHandle then
			self:stopAction(self.schedulerHandle)
			self.schedulerHandle = nil
		end
		local openHint = GameManager:getUserData():getOpenHint()
		if openHint > 0 then
			self.schedulerHandle = self:performWithDelay(function ()
				self:autoTips(true)
			end,15)
		end
	end
	if tolua.isnull(self.tipsNode_) then
		self.tipsNode_ = nil
	end
	if self.tipsNode_ then
		self.tipsNode_:stopAllActions()
		self.tipsNode_:removeSelf()
		self.tipsNode_ = nil
	end
end

function BattleManager:calculateScore_(card_before, card_next, headIndex )
	local score = 0
	if GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):isVegasMode() then
		if headIndex >= BattleManager.HEAD_COLLECT_1 and headIndex <= BattleManager.HEAD_COLLECT_MAX then
			--收集卡牌
			score = score + 5
		end
		if card_next.headIndex_ >= BattleManager.HEAD_COLLECT_1 and card_next.headIndex_ <= BattleManager.HEAD_COLLECT_MAX then
			--从收集区拿出
			score = score - 5
		end
		self.notNeedAnalysis = false
		return score
	end

	local threeMode = GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):getCacheData():getProperty("isDraw3Mode")
	if (card_next.headIndex_ == BattleManager.HEAD_CHANGE_1 or card_next.headIndex_ == BattleManager.HEAD_CHANGE_MAX) and 
	 headIndex >= BattleManager.HEAD_COLLECT_1 and headIndex <= BattleManager.HEAD_COLLECT_MAX then
	 	--从发牌区到集牌区
		score = score + 15
		if threeMode > 0 then
			self.notNeedAnalysis = false
		end
	end
	if card_next.headIndex_ == BattleManager.HEAD_CHANGE_1 and
	 headIndex >= BattleManager.HEAD_COLUMN_1 and headIndex <= BattleManager.HEAD_COLUMN_MAX then
	 	--发牌
		score = score + 5
		if threeMode > 0 then
			self.notNeedAnalysis = false
		end
	end
	if card_next.headIndex_ >= BattleManager.HEAD_COLLECT_1 and card_next.headIndex_ <= BattleManager.HEAD_COLLECT_MAX then
		if headIndex >= BattleManager.HEAD_COLUMN_1 and headIndex <= BattleManager.HEAD_COLUMN_MAX then
			score = score + -10
		end
	end
	if card_next.headIndex_ >= BattleManager.HEAD_COLUMN_1 and card_next.headIndex_ <= BattleManager.HEAD_COLUMN_MAX then
		if headIndex >= BattleManager.HEAD_COLLECT_1 and headIndex <= BattleManager.HEAD_COLLECT_MAX then
			--收牌
			score = score + 10
		end
		if card_next:getBeforeCard() then
			if card_next:getBeforeCard():getProperty("board") == CardVO.BOARD_BACK then
				--当前牌上一张是背面
				--只有造成牌面翻转之后才需要判断是否可自动收牌以及加分数
				score = score + 5
				self.notNeedAnalysis = false
			end
		end
	end

	if card_next:getProperty("board") == CardVO.BOARD_BACK then
		self.notNeedAnalysis = false
	end

	return score
end

function BattleManager:retsetJugde_(card_next,headIndex)
	local threeMode = GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):getCacheData():getProperty("isDraw3Mode")
	local step_ = (threeMode > 0) and 3 or 1
	if card_next:getProperty("headIndex") == BattleManager.HEAD_CHANGE_MAX and headIndex == BattleManager.HEAD_CHANGE_1 then
		self.flipChangeCardsNum_ = self.flipChangeCardsNum_ + step_
	elseif card_next:getProperty("headIndex") == BattleManager.HEAD_CHANGE_1 and headIndex == BattleManager.HEAD_CHANGE_MAX then
		self.flipChangeCardsNum_ = self.flipChangeCardsNum_ - step_
		if self.flipChangeCardsNum_ < 0 then
			self.flipChangeCardsNum_ = 0
		end
	else
		self.flipChangeCardsNum_ = 0
	end
end

--处理两张卡牌的链接以及头部索引的操作
function BattleManager:linkTwoCard(card_before, card_next, headIndex, notRecordStep )
	local userCacheStepVO = UserCacheStepVO.new()
	if not card_next then
		return
	end
	-----------分析翻牌次数,无牌可走提示------------
	self:retsetJugde_(card_next,headIndex)
	--------------------------------------------
	local score = self:calculateScore_(card_before, card_next, headIndex)
	userCacheStepVO:setProperty("score", score)
	userCacheStepVO:setProperty("stepStart", card_next:getProperty("headIndex"))

	if card_next then
		local endIndex = headIndex
		local startIndex = card_next:getProperty("headIndex")
		local beginPos = ccp(card_next:getView():getPosition())
		local checkScore = self:checkMoveNeedAddScore(startIndex, endIndex)
		if checkScore < 0 then
			self:playScoreAction(beginPos, beginPos, checkScore)
		end
	end

	if not card_next:getBeforeCard() then
		--将原有的头置空
		self.headsList_[card_next:getProperty("headIndex")] = nil
	end
	if card_before then
		headIndex = card_before:getProperty("headIndex")
		GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):changeCacheStatusByCardVO(card_before)
	end
	local left_mode = GameManager:getUserData():getIsLeft()
	if headIndex then
		local card = card_next
		while card do
			card:setProperty("headIndex", headIndex)
			if headIndex == BattleManager.HEAD_CHANGE_MAX then
				if left_mode > 0 then
					card:changeBoardTo(CardVO.BOARD_BACK, CardVO.FLIP_TYPE_LEFT, true)
				else
					card:changeBoardTo(CardVO.BOARD_BACK, CardVO.FLIP_TYPE_RIGHT, true)
				end
			elseif headIndex == BattleManager.HEAD_CHANGE_1 then
				if left_mode > 0 then
					card:changeBoardTo(CardVO.BOARD_FACE, CardVO.FLIP_TYPE_RIGHT)
				else
					card:changeBoardTo(CardVO.BOARD_FACE, CardVO.FLIP_TYPE_LEFT)
				end
			end
			card = card:getNextCard()
		end
		--判断是否翻牌
		if headIndex == BattleManager.HEAD_CHANGE_MAX or headIndex == BattleManager.HEAD_CHANGE_1 then
		else
			if card_next:getBeforeCard() and card_next:getBeforeCard():getProperty("board") == CardVO.BOARD_BACK then
				card_next:getBeforeCard():changeBoardTo(CardVO.BOARD_FACE)
				local pos = ccp(card_next:getView():getPosition())
				--self:playScoreAction(pos, pos, BattleManager.SCORE_FLIP_TO_FACE)
				self:playFlipCardScore(pos, BattleManager.SCORE_FLIP_TO_FACE)
				self:judgeCardFlipCoin(card_next:getBeforeCard())
				GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):changeCacheStatusByCardVO(card_next:getBeforeCard())
				userCacheStepVO:setProperty("beforeIsFlip", 1)
			end
		end
	end
	--音效
	if headIndex == BattleManager.HEAD_CHANGE_1 then
		GameManager:getAudioData():playAudio(common.effectSoundList.waste)
	else
		GameManager:getAudioData():playAudio(common.effectSoundList.success)
	end
	self:palyCollectAudio(headIndex)

	DealerController.linkTwoCard(card_before, card_next)
	if not card_next:getBeforeCard() then
		--重置头
		self.headsList_[card_next:getProperty("headIndex")] = card_next
	end
	--保存牌面信息
	GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):changeCacheStatusByCardVO(card_next)
	--保存步骤信息
	userCacheStepVO:setProperty("stepEnd", card_next:getProperty("headIndex"))
	userCacheStepVO:setProperty("count", DealerController.getQueueLenByHead(card_next))
	--此步移动的轮数
	userCacheStepVO:setProperty("flipCardRound", self.flipCardRound)

	if not notRecordStep then
		GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):saveCacheStep(userCacheStepVO)
		GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):addStepCount(1)
		GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):carryOnScore(userCacheStepVO:getProperty("score"))
	end
	local sec = GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):getRunningTime()
	GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):changeCacheData({gameTime = sec})
	self:updateBtnStatus_()
end

function BattleManager:didAddCardToOpen( notReOrder )
	if not notReOrder then
		self:reOrderZOrder_(self.headsList_[BattleManager.HEAD_CHANGE_MAX])
		self:reOrderZOrder_(self.headsList_[BattleManager.HEAD_CHANGE_1])
	end
	local card_last = self.headsList_[BattleManager.HEAD_CHANGE_1]
	if card_last then
		card_last = DealerController.getQueueEndCardVO(card_last)
	end
	if not card_last then
		return
	end
	local offsetX = 0
	if self.showMoveAni_ then
		while card_last do
			local moveTo = CCMoveTo:create(0.1, ccp(self["column"..BattleManager.HEAD_CHANGE_1]:getPositionX()-offsetX,
				self["column"..BattleManager.HEAD_CHANGE_1]:getPositionY()))
			local call = CCCallFunc:create(function ( )
				self:endMoving()
			end)
			self:startMoving()
			card_last:getView():stopAllActions()
			if card_last:getBeforeCard() then
				card_last:getView():runAction(moveTo)
			else
				card_last:getView():runAction(transition.sequence({moveTo, call}))
			end
			card_last = card_last:getBeforeCard()
			offsetX = offsetX + self:getCardOffsetX_()
			if offsetX > 80 then
				offsetX = 80
			end
		end
	else
		while card_last do
			card_last:getView():setPositionX(self["column"..BattleManager.HEAD_CHANGE_1]:getPositionX()-offsetX)
			local before = card_last:getBeforeCard()
			if before then
				card_last = before
			else
				break
			end
			offsetX = offsetX + self:getCardOffsetX_()
			if offsetX > 80 then
				offsetX = 80
			end
		end
	end

	
end

--将开放区的牌回复到锁区
function BattleManager:putCardToLock( count, notRecordStep )
	if count < 1 then
		return
	end
	--锁区的最后一张
	local card_before = self.headsList_[BattleManager.HEAD_CHANGE_MAX]
	if card_before then
		card_before = DealerController.getQueueEndCardVO(card_before)
	end
	local card_next = self.headsList_[BattleManager.HEAD_CHANGE_1]
	if card_next then
		card_next = DealerController.getQueueEndCardVO(card_next)
		card_next = DealerController.getCardByCountFromBottom(card_next,count)
		--开放区逆向之后的第一张
		card_next = DealerController.reverseQueueByCardVO(card_next)
	else
		return
	end
	self:linkTwoCard(card_before, card_next, BattleManager.HEAD_CHANGE_MAX, notRecordStep)
	self:reOrderZOrder_(card_next)
	if self.showMoveAni_ then
		--TODO...需要添加动画
		while card_next do
			card_next:getView():stopAllActions()
			local move = CCMoveTo:create(0.1, ccp(self["column"..BattleManager.HEAD_CHANGE_MAX]:getPositionX(), 
				self["column"..BattleManager.HEAD_CHANGE_MAX]:getPositionY()))
			card_next:getView():runAction(CCEaseSineInOut:create(move))

			card_next = card_next:getNextCard()
		end
	else
		while card_next do
			card_next:getView():setPosition(ccp(self["column"..BattleManager.HEAD_CHANGE_MAX]:getPositionX(), 
				self["column"..BattleManager.HEAD_CHANGE_MAX]:getPositionY()))

			card_next = card_next:getNextCard()
		end
	end
	self:didAddCardToOpen(true)
end

--将锁区的牌撤销到开放区
function BattleManager:putCardToOpen( count, notRecordStep )
	if count < 1 then
		return
	end
	--锁区的最后一张
	local card_before = self.headsList_[BattleManager.HEAD_CHANGE_1]
	if card_before then
		card_before = DealerController.getQueueEndCardVO(card_before)
	end
	local card_next = self.headsList_[BattleManager.HEAD_CHANGE_MAX]
	if card_next then
		card_next = DealerController.getQueueEndCardVO(card_next)
		card_next = DealerController.getCardByCountFromBottom(card_next,count)
		--开放区逆向之后的第一张
		card_next = DealerController.reverseQueueByCardVO(card_next)
	else
		return
	end
	self:linkTwoCard(card_before, card_next, BattleManager.HEAD_CHANGE_1, notRecordStep)
	if self.showMoveAni_ then
		--TODO...需要添加动画
	end
	self:didAddCardToOpen()
end

function BattleManager:setDelegate( delegate )
	self.delegate_ = delegate
end

function BattleManager:reOrderZOrder_( cardVO, zOrder )
	if not cardVO then
		return
	end
	if not zOrder then
		zOrder = 0
	end
	while cardVO do
		cardVO:getView():setZOrder(zOrder)
		cardVO = cardVO:getNextCard()
	end
end

function BattleManager:updateBtnStatus_( )
	local isVegasMode = GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):isVegasMode()
	local threeMode = GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):getCacheData():getProperty("isDraw3Mode")
	local roundLimit = 1--翻牌的轮数限制
	if threeMode > 0 then
		roundLimit = 3
	end
	if self.headsList_[BattleManager.HEAD_CHANGE_1] or self.headsList_[BattleManager.HEAD_CHANGE_MAX] then
		self.sp_go_on:setVisible(true)
		self.sp_no:setVisible(false)
	else
		self.sp_go_on:setVisible(false)
		self.sp_no:setVisible(true)
	end
	if isVegasMode and self.flipCardRound >= roundLimit then
		self.outOfFlips:setVisible(true)
		self.sp_go_on:setVisible(false)
		self.sp_no:setVisible(true)
	else
		self.outOfFlips:setVisible(false)
	end
	if self.delegate_ and self.delegate_.setBtn5Enabled then
		local stepData = GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):getCacheStepByLast()
		if stepData then
			if stepData.isMagic_ > 0 then --如果上一步是魔法
				self.delegate_:setBtn5Enabled(false)
			else --如果上一步不是魔法
				self.delegate_:setBtn5Enabled(true)
			end
		else
			self.delegate_:setBtn5Enabled(false)
		end
	end
	EventNoticeManager:getInstance():dispatchEvent({name = Notice.GAME_DATA_CHANGE})
end

function BattleManager:tapChange( )
	if self.magic_ then
		return
	end
	if self.speedSchedule then
		self:stopAction(self.speedSchedule)
		self.speedSchedule = nil
	end
	local isVegasMode = GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):isVegasMode()
	-- if self.cardMoving_ then
	-- 	return
	-- end
	self:clearLight_(true)
	local threeMode = GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):getCacheData():getProperty("isDraw3Mode")
	local roundLimit = 1--翻牌的轮数限制
	local operationCount = 1--操作卡牌的数量
	if threeMode > 0 then
		operationCount = 3
		roundLimit = 3
	end
	if self.headsList_[BattleManager.HEAD_CHANGE_MAX] then
		self.notNeedAnalysis = false
		--向开放区切牌
		if isVegasMode then
			local count = DealerController.getQueueLenByHead(self.headsList_[BattleManager.HEAD_CHANGE_MAX])
			--切operationCount张牌，不足即为一轮
			if count <= operationCount then
				if self.flipCardRound < roundLimit then
					self.flipCardRound = self.flipCardRound + 1
					self:putCardToOpen(operationCount)
				end
			else
				self:putCardToOpen(operationCount)
			end
		else
			self:putCardToOpen(operationCount)
		end
		self:resumeGame(true)
	else
		--将开放区的牌回复
		if not self.headsList_[BattleManager.HEAD_CHANGE_1] then
			--此时换牌区已经无牌
			return
		end
		if isVegasMode and self.flipCardRound >= roundLimit then
			return
		end
		self:resumeGame(true)
		self:putCardToLock(DealerController.getQueueLenByHead(self.headsList_[BattleManager.HEAD_CHANGE_1]))
	end
end

function BattleManager:startMoving( )
	self.cardMoving_ = true
end

function BattleManager:dealOffsetY( headIndex_ )
	if headIndex_ and headIndex_ >= BattleManager.HEAD_COLUMN_1 and headIndex_ <= BattleManager.HEAD_COLUMN_MAX then
		local lenght = 0
		local height = 0
		local card = self.headsList_[headIndex_]
		while card do
			height = card:getView():getContentSize().height
			lenght = lenght + self:getCardOffsetY_(card.board_)
			card = card:getNextCard()
		end
		local posY = self["column"..headIndex_]:getPositionY()
		local scal = 1
		if posY + 20 < lenght + height/2 then
			scal = (posY + 20)/(lenght + height/2)
		end
		--缩进队列
		local card = self.headsList_[headIndex_]
		while card do
			card:getView():setPositionY(posY)
			if card.board_ == CardVO.BOARD_FACE then
				posY = posY - self:getCardOffsetY_(card.board_)*scal
			else
				posY = posY - self:getCardOffsetY_(card.board_)
			end
			card = card:getNextCard()
		end
	end
end

function BattleManager:endMoving(startHeadIndex, headIndex ,m_foor)
	if startHeadIndex then
		self:dealOffsetY(startHeadIndex)
		if headIndex ~= startHeadIndex then
			self:dealOffsetY(headIndex)
		end
	end
	if startHeadIndex == 12 and (headIndex >= 8 and headIndex <= 11) then
		self.qucikClickChange = true
	end
	if m_foor and (headIndex >= 8 and headIndex <= 11) and (startHeadIndex < 8 or startHeadIndex > 11) then
		self:speedAutoCollection()
	end
	self.cardMoving_ = false
	self:analysisCollectCard_()
	local isWin_ = self:analysisWin_()
	if not isWin_ then
		-- self:judgeEnd()
	end
end

--暂停游戏
function BattleManager:pauseGame()
	GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):setStartTime(0)
end
--继续游戏
function BattleManager:resumeGame(force)
	local gameState = GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):getCacheData():getProperty("gameState")
	if gameState ~= UserCacheRecordVO.status_playing or not force then
		return
	end
	--此局生效，提交统计数据
	local isRepeat_ = GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):getCacheData():getProperty("isRepeat")
	if isRepeat_ == 0 then
		--快照数据
		GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):changeCacheData({isRepeat = 1})
		--游戏统计数据
		self:saveRecord("newGame")
	end
	GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):changeCacheData({gameState = UserCacheRecordVO.status_playing})
	GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):setStartTime(1)
	EventNoticeManager:getInstance():dispatchEvent({name = Notice.GAME_STATUS_CHANGE})
	
	--种子开始打点
	self:recordBeginEvent_()

end

function BattleManager:endGame()
	GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):cleanData()
	self:clearLight_()
	self:stopAllActions()
	self.card_table:removeAllChildren()
	self.headsList_ = {}
	self.flipCardRound = 0
	self.noTipsNum = 0
	--是否展示移动动画
	self.showMoveAni_ = true
	self.cardMoving_ = false
	self.btn_autoCollect:setVisible(false)

	if GAME_MODE == GAME_MODE_COLLECTION then
		if self.delegate_ and self.delegate_.tapCMenu then
			self.delegate_:tapCMenu()
		end
	else
		if self.delegate_ and self.delegate_.tapGame then
			self.delegate_:tapGame()
		end
	end
end

--todo 撤销
function BattleManager:tapRevokeState()
	self.quickundo = true
end

function BattleManager:tapRevoke()
	if self.cardMoving_ then
		-- return --todo 临时撤销
	end
	if self.magic_ then
		return
	end
	local stepData = GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):getCacheStepByLast()
	-- dump(stepData,'stepData====>>>>>>>>')
	if not stepData then
		return
	end

	if self.speedSchedule then
		self:stopAction(self.speedSchedule)
		self.speedSchedule = nil
	end

	self:resumeGame(true)
	GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):removeCacheStepByLast()
	local data = GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):getCacheStepByLast()
	if data then
		self.flipCardRound = data:getProperty("flipCardRound")
	else
		self.flipCardRound = 0
	end
	--撤销操作有可能影响到自动收牌
	if self.btn_autoCollect:isVisible() == true then
		self.notNeedAnalysis = false
	end
	
	--添加撤销次数计数
	GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):addUndoNum(1)
	GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):addStepCount(-1)

	--将增加的分数返还
	GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):carryOnScore(-stepData:getProperty("score"))
	if stepData:getProperty("stepStart") == BattleManager.HEAD_CHANGE_1 and 
		stepData:getProperty("stepEnd") == BattleManager.HEAD_CHANGE_MAX then
		--锁区向开放区回退
		self:putCardToOpen(stepData:getProperty("count"), true)
		self:clearLight_(true)
		return
	elseif stepData:getProperty("stepStart") == BattleManager.HEAD_CHANGE_MAX and 
		stepData:getProperty("stepEnd") == BattleManager.HEAD_CHANGE_1 then
		--开放区向锁区回退
		self:putCardToLock(stepData:getProperty("count"), true)
		self:clearLight_(true)
		return
	end
	local card_before = self.headsList_[stepData:getProperty("stepStart")]
	if card_before then
		card_before = DealerController.getQueueEndCardVO(card_before)
	end
	local card_next = self.headsList_[stepData:getProperty("stepEnd")]
	if card_next then
		card_next = DealerController.getQueueEndCardVO(card_next)
	end
	card_next = DealerController.getCardByCountFromBottom(card_next,stepData:getProperty("count"))
	if stepData:getProperty("beforeIsFlip") == 1 and card_before then
		card_before:changeBoardTo(CardVO.BOARD_BACK, nil, true)
		local pos = ccp(card_before:getView():getPosition())
		--self:playScoreAction(pos, pos, -BattleManager.SCORE_FLIP_TO_FACE)
		self:playFlipCardScore(pos, -BattleManager.SCORE_FLIP_TO_FACE)
	end
	self:linkTwoCard(card_before, card_next, stepData:getProperty("stepStart"), true)

	if stepData:getProperty("stepStart") == BattleManager.HEAD_CHANGE_1 then
		self:moveCards(card_next, stepData:getProperty("stepStart"))
		self:dealOffsetY(stepData:getProperty("stepEnd"))
	else
		self:moveCards(card_next, stepData:getProperty("stepEnd"))
	end
	
	self:clearLight_(true)

	self.noTipsNum = 0
end

function BattleManager:findCardWitchCanCollectByHead_(before,head)
	if not head then
		return
	end
	if head:getProperty("board") == CardVO.BOARD_FACE then
		if DealerController.judgeCollectCard(before,head,true) then
			return head
		end
	end
	
	head = head:getNextCard()
	return self:findCardWitchCanCollectByHead_(before,head)
end

function BattleManager:findCardWitchCanCollect_()
	local list_ = {}
	for i=BattleManager.HEAD_COLLECT_1,BattleManager.HEAD_COLLECT_MAX do
		local before = self.headsList_[i]
		if before then
			before = DealerController.getQueueEndCardVO(before)			
			for col=BattleManager.HEAD_COLUMN_1,BattleManager.HEAD_COLUMN_MAX do
				local card = self.headsList_[col]
				if card then
					local result_ = self:findCardWitchCanCollectByHead_(before,card)
					if result_ then
						list_[#list_ + 1] = result_
						break
					end
				end
			end
		end
	end
	return list_
end

--分析换牌区的牌是否可以连接
function BattleManager:analysisChangeCards( )
	local threeMode = GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):getCacheData():getProperty("isDraw3Mode")
	local step_ = (threeMode > 0) and 3 or 1

	local list1_ = DealerController.getListByHead(self.headsList_[BattleManager.HEAD_CHANGE_1])
	local listMax_ = DealerController.getListByHead(self.headsList_[BattleManager.HEAD_CHANGE_MAX])
	for i=#listMax_,1,-1 do
		list1_[#list1_ + 1] = listMax_[i]
	end

	local list_ = {}
	local len_ = #list1_
	for i=1,len_ do
		if i%step_ == 0 then
			list_[#list_ + 1] = list1_[i]
		end
	end

	if len_%step_ ~= 0 then
		list_[#list_ + 1] = list1_[len_]
	end

	for i=1,#list_ do
		local card = list_[i]
		for j=BattleManager.HEAD_COLUMN_1,BattleManager.HEAD_COLUMN_MAX do
			local endCard = DealerController.getQueueEndCardVO(self.headsList_[j])
			if DealerController.judgeLinking(endCard, card) then
				return true
			end
		end
		for j=BattleManager.HEAD_COLLECT_1,BattleManager.HEAD_COLLECT_MAX do
			local endCard = DealerController.getQueueEndCardVO(self.headsList_[j])
			if DealerController.judgeCollectCard(endCard,card) then
				return true
			end
		end
	end

	return false
end

function BattleManager:tapHint()
	-- self:clearLight_(true)
	self:autoTips(false)
end

function BattleManager:judgeEnd()
	local ok, before_card
	-- 提示
	--1判断玩牌区 移动整列正面的牌，或者末尾的一张牌去集卡区
	for i=BattleManager.HEAD_COLUMN_1,BattleManager.HEAD_COLUMN_MAX do
		local card = self.headsList_[i]
		--该队列第一张正面的牌
		card = DealerController.getFirstFaceCardFromHead( card )
		if card then
			--判断整个队列所有正面的牌弄否移动
			ok, before_card = self:findLink_(card,BattleManager.ALL_CON)
			if DealerController.judgeRankEquiK(card) and card:getBeforeCard() == nil and not before_card then
				--防止k在几个空列来回提示
				ok = false
			end
			if ok then
				break
			elseif card:getNextCard() then
				--该队列最后一张牌，判断能否移动,此时只判断是否可以收集
				card = DealerController.getQueueEndCardVO(card:getNextCard())
				ok = self:findLink_(card, BattleManager.ONLY_COLLECT)
				if ok then
					break
				end
			end
		end
	end
	--2换牌区的牌移到集卡区或者玩牌区
	local card = self.headsList_[BattleManager.HEAD_CHANGE_1]
	if card then
		card = DealerController.getQueueEndCardVO(card)
	end
	if not ok and card then
		ok = self:findLink_(card,BattleManager.ALL_CON)
	end
	--5玩牌区移动后可收牌的情况
	if not ok then
		local judgeList_ = self:findCardWitchCanCollect_()
		for i=1,#judgeList_ do
			if judgeList_[i]:getNextCard() then
				ok = self:findLink_(judgeList_[i]:getNextCard(),BattleManager.ONLY_MOVE)
				if ok then
					break
				end
			end
		end
	end
	--分析是否无牌可走
	if not ok then
		local count = DealerController.getQueueLenByHead(self.headsList_[BattleManager.HEAD_CHANGE_MAX])
		count = count + DealerController.getQueueLenByHead(self.headsList_[BattleManager.HEAD_CHANGE_1])
		if self.flipChangeCardsNum_ >= count or count == 0 then
			--查看当前换牌区中有没有可以走的牌
			if not self:analysisChangeCards() then
				local canMagic_ = GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):judgeMagicNum()
				GameManager:getInstance():popNoWayAlert(canMagic_)
				self.flipChangeCardsNum_ = 0
				return true
			end
		end
	end
	return false
end

--todo 提示
function BattleManager:autoTips( isRepeat )
	if GameManager:getInstance():supportTips() == false then
		return
	end
	if self.light_ or self.tipsNode_ then
		return
	end
	local ok, before_card, index
	local next_card = nil
	local node = nil
	-- 提示
	--1判断玩牌区 移动整列正面的牌，或者末尾的一张牌去集卡区
	for i=BattleManager.HEAD_COLUMN_1,BattleManager.HEAD_COLUMN_MAX do
		local card = self.headsList_[i]
		--该队列第一张正面的牌
		card = DealerController.getFirstFaceCardFromHead( card )
		if card then
			--判断整个队列所有正面的牌弄否移动
			ok, before_card, index = self:findLink_(card,BattleManager.ALL_CON)
			next_card = card
			if DealerController.judgeRankEquiK(card) and card:getBeforeCard() == nil and not before_card then
				--防止k在几个空列来回提示
				ok = false
			end
			if ok then
				break
			elseif card:getNextCard() then
				--该队列最后一张牌，判断能否移动,此时只判断是否可以收集
				card = DealerController.getQueueEndCardVO(card:getNextCard())
				ok, before_card, index = self:findLink_(card, BattleManager.ONLY_COLLECT)
				next_card = card
				if ok then
					break
				end
			end
		end
	end
	--2换牌区的牌移到集卡区或者玩牌区
	local card = self.headsList_[BattleManager.HEAD_CHANGE_1]
	if card then
		card = DealerController.getQueueEndCardVO(card)
	end
	if not ok and card then
		ok, before_card, index = self:findLink_(card,BattleManager.ALL_CON)
		next_card = card
	end
	--5玩牌区移动后可收牌的情况
	if not ok then
		local judgeList_ = self:findCardWitchCanCollect_()
		for i=1,#judgeList_ do
			if judgeList_[i]:getNextCard() then
				ok, before_card, index = self:findLink_(judgeList_[i]:getNextCard(),BattleManager.ONLY_MOVE)
				next_card = judgeList_[i]:getNextCard()
				if ok then
					break
				end
			end
		end
	end
	--分析是否无牌可走
	-- local isDailyChallenge = GameManager:getUserGameCacheData():isDailyChallenge()
	-- local isSolvedMode = GameManager:getUserData():isSolvedMode() --是否是活局

	local cardNum_ = 0
	for i=BattleManager.HEAD_COLUMN_1,BattleManager.HEAD_COLUMN_MAX do
		cardNum_ = cardNum_ + DealerController.getQueueLenByHead(self.headsList_[i])
	end
	cardNum_ = cardNum_ + DealerController.getQueueLenByHead(self.headsList_[BattleManager.HEAD_CHANGE_1])
	cardNum_ = cardNum_ + DealerController.getQueueLenByHead(self.headsList_[BattleManager.HEAD_CHANGE_MAX])

	if cardNum_ == 0 then
		return
	end

	if not ok and not isRepeat then
		local count = DealerController.getQueueLenByHead(self.headsList_[BattleManager.HEAD_CHANGE_MAX])
		count = count + DealerController.getQueueLenByHead(self.headsList_[BattleManager.HEAD_CHANGE_1])
		if self.flipChangeCardsNum_ >= count or count == 0 then
			--查看当前换牌区中有没有可以走的牌
			if not self:analysisChangeCards() then
				local isFishdom = PackageConfigDefine.isSolitaireFishdom()
				if self.noTipsNum <= 0 and isFishdom then
					EventNoticeManager:getInstance():dispatchEvent({name = Notice.FIRST_NO_HINT})
				else
					local canMagic_ = GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):judgeMagicNum()
					GameManager:getInstance():popNoWayAlert(canMagic_)
					self.flipChangeCardsNum_ = 0
				end
				self.noTipsNum = self.noTipsNum + 1
				return
			end
		end
	end

	--3换牌区翻牌
	local card = self.headsList_[BattleManager.HEAD_CHANGE_MAX]
	if not ok and card then
		ok, before_card, index = true, nil, BattleManager.HEAD_CHANGE_1
		next_card = DealerController.getQueueEndCardVO(card)
	end

    if not ok and not card then
    	if GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):isVegasMode() then
			GameManager:getInstance():popNoWayAlert(false)
			return
		end
    end

	--4换牌区回复
	local card = self.headsList_[BattleManager.HEAD_CHANGE_1]
	if not ok and card then
		ok = true
		next_card = card
		node = self["column"..BattleManager.HEAD_CHANGE_MAX]
		self.light_ = self:addLight_(next_card, node)
		return
	end

	if not ok then
		return
	end
	GameManager:getAudioData():playAudio(common.effectSoundList.success)
	
	--移动提示
	self.tipsNode_ = display.newNode()
	self.card_table:addChild(self.tipsNode_)
	self.tipsNode_:setPosition(next_card:getView():getPosition())
	local offsetY = 0
	local movingCard = nil
	--拷贝可移动的卡牌
	while next_card do
		local card = CardVO.new({
			deck = next_card.deck_,
			suit = next_card.suit_, --花色
			rank = next_card.rank_, --点数
			board = next_card.board_, --正反
			})
		self.tipsNode_:addChild(card:getView())
		card:getView():setTouchEnabled(false)
		card:getView():setPositionY(offsetY)
		card:setBeforeCard(movingCard)
		if movingCard then
			movingCard:setNextCard(card)
		end
		movingCard = card
		offsetY = offsetY - self:getCardOffsetY_(next_card.board_)
		next_card = next_card:getNextCard()
	end
	self:addLight_(DealerController.getCardByCountFromBottom(movingCard,52))
	--开始移动
	local pos = ccp(0, 0)
	if not self["column"..index] then
		return
	end
	pos.x, pos.y = self["column"..index]:getPosition()
	if before_card then
		pos.x, pos.y = before_card:getView():getPosition()
		if index <= BattleManager.HEAD_COLUMN_MAX then
			pos.y = before_card:getView():getPositionY() - self:getCardOffsetY_(before_card.board_)
		end
	end
	local delay1 = CCDelayTime:create(0.1)
	local moveAction = CCMoveTo:create(0.4, pos)
	local delay2 = CCDelayTime:create(0.3)
	local beginPos_ = ccp(self.tipsNode_:getPositionX(), self.tipsNode_:getPositionY())

	local seq_ = nil
	if isRepeat then
		local resetCall = CCCallFunc:create(function ()
			self.tipsNode_:setPosition(ccp(beginPos_.x, beginPos_.y))
			self.tipsNode_:setVisible(false)
		end)

		local delay3 = CCDelayTime:create(2)
		local viewCall = CCCallFunc:create(function ()
			self.tipsNode_:setVisible(true)
		end)
		seq_ = CCRepeatForever:create(transition.sequence({delay1, CCEaseSineInOut:create(moveAction), delay2, resetCall, delay3, viewCall}))
	else
		local call = CCCallFunc:create(function ()
			self:clearLight_()
		end)
		seq_ = transition.sequence({delay1, CCEaseSineInOut:create(moveAction), delay2, call})
	end
	-- 添加提示次数计数
	if not isRepeat then
		GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):addHintNum(1)
	end
	
	
	self.tipsNode_:runAction(seq_)
end

function BattleManager:tapAutoCollect()
	self.btn_autoCollect:setVisible(false)
	self:autoCollectCard()
end

function BattleManager:analysisCollectCard_( )
	if self.notNeedAnalysis then
		--只有造成牌面翻转之后才需要判断是否可自动收牌以及加分数
		return
	end
	self.notNeedAnalysis = true
	local collect = true
	--牌桌上面还有未翻开的牌不可自动收牌
	for i=BattleManager.HEAD_COLUMN_MAX,BattleManager.HEAD_COLUMN_1, -1 do
		if self.headsList_[i] and self.headsList_[i]:getProperty("board") == CardVO.BOARD_BACK then
			collect = false
			break
		end
	end
	if collect then
		local threeMode = GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):getCacheData():getProperty("isDraw3Mode")
		if threeMode > 0 or GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):isVegasMode() then
			--三张模式时lock区有牌或者开放区多于一张不可自动收牌
			if self.headsList_[BattleManager.HEAD_CHANGE_MAX] or 
				DealerController.getQueueLenByHead(self.headsList_[BattleManager.HEAD_CHANGE_1]) > 1 then
				collect = false
			end
		end
	end
	if collect then
		--TODO...可以自动收牌了
		-- printf("开始自动收牌")
		local endAniStatus = GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):getEndAniStatus() or BattleManager.END_ANI_NONE
		
		local is_autoCollection = GameManager:getUserData():getProperty("isOpenSpeedCollection")
		if is_autoCollection == 1 then
			if endAniStatus == BattleManager.END_ANI_NONE then
				if self.speedSchedule then
					self:stopAction(self.speedSchedule)
					self.speedSchedule = nil
				end
				self.btn_autoCollect:setVisible(false)
				self:autoCollectCard()
			end
		else
			self.btn_autoCollect:setVisible(endAniStatus == BattleManager.END_ANI_NONE)
		end
	else
		self.btn_autoCollect:setVisible(false)
	end
end

function BattleManager:analysisWin_( )
	local win = true
	--牌桌和换牌区都没有卡牌的时候胜利
	for i=BattleManager.HEAD_COLUMN_1,BattleManager.HEAD_COLUMN_MAX do
		if self.headsList_[i] then
			win = false
			break
		end
	end
	if win then
		if self.headsList_[BattleManager.HEAD_CHANGE_1] or self.headsList_[BattleManager.HEAD_CHANGE_MAX] then
			win = false
		end
	end
	if win then
		printf("恭喜，获得胜利")
		self.btn_autoCollect:setVisible(false)
		self:pauseGame()
		self:uploadSeed()
		
		local sec = GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):getRunningTime()
		--计时模式下的奖励分数
		GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):carryOnScore(GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):getTimeEndScore())
		EventNoticeManager:getInstance():dispatchEvent({name = Notice.GAME_DATA_CHANGE})
		--提交统计数据
		local isWin_ = GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):getCacheData():getProperty("isWin")
		local isFirstWin_ = 0
		if isWin_ == 0 then
			isFirstWin_ = 1
			--快照数据
			isWin_ = 1
			--游戏统计数据
			self:saveRecord("win")
		end
		local heigh, data = self:saveRecord("record")
		--是否是每日挑战
		local isDailyChallenge = GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):isDailyChallenge()
		if isDailyChallenge then
			GameManager:getUserChallengeData():requestFinishDailyChallenge(data)
			--上传皇冠数到排行榜
			local totalCrown = GameManager:getUserChallengeData():getTotalCrownNum() or 0
			GameManager:getNativeManager():submitScore(totalCrown,GameCenterDefine.getLeaderBoardId().totalCrown)
			--成就判断
			AchievementsManager.crownAchievement(totalCrown)
		end
		local radom_ = math.random(1,3)
		local list = {}
		for i=BattleManager.HEAD_COLLECT_1,BattleManager.HEAD_COLLECT_MAX do
			local card = self.headsList_[i]
			list[#list + 1] = {suit=card.suit_}
		end
		GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):cacheRecordData(heigh, data, radom_, list, isFirstWin_)
		
		GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):setEndAniStatus(BattleManager.END_ANI_STUFF)
		self:showStuffAnimation()

		self:saveWinGameType()
        -- if DEBUG ~= 1 then
        	GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):cleanData()
        -- end
        local move_ = 0
        if data.move then
        	move_ = tonumber(data.move)
        end
		GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):changeCacheData({gameState = UserCacheRecordVO.status_end, gameTime = sec, isWin = isWin_})
		--种子完成打点
		self:recordCompleteEvent_("completeBattle")
		self:recordCompleteEventTotalWin()
		EventNoticeManager:getInstance():dispatchEvent({name = Notice.GAME_STATUS_CHANGE})
	end
	return win
end

function BattleManager:showWinDialog( )
    local viewCtrl = WinViewCtrl.new(true)
    display.getRunningScene():addChild(viewCtrl:getView())
    GameManager:getUserData():addPraiseWinCount()
end


--todo win游戏结束 completeBattle 牌局类型，维加斯，游戏类型，用时，得分，步数
--todo dailyChallenge 每日挑战 win 
function BattleManager:showStuffAnimation( )
	
	local list = GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):getProperty("stuffData") or {}
	local index = 1
	for i=BattleManager.HEAD_COLLECT_1,BattleManager.HEAD_COLLECT_MAX do
		-- local card = self.headsList_[i]
		list[index].pos = ccp(self["column"..i]:getPosition())
		index = index + 1
	end
	--洗牌动画的载体节点
	local node = display.newNode()
	node:setContentSize(self.card_table:getContentSize())
	node:setPosition(self:getPosition())
	node:setScale(self:getScale())
	display.getRunningScene():addChild(node)

	local radom = GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):getProperty("aniNum") or 1
	self:initSuccesAni_(list,node,radom)
end

function BattleManager:initSuccesAni_(list,node,radom)
	--屏蔽触摸和按钮
    local touchNode = self:addTouchLayer_(display.getRunningScene(), ccc4(0, 0, 0, 0))

	--洗牌动画播放完毕之后的结算动画
	function endCallBack_( node )
		self.headsList_ = {}
		if GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):getEndAniStatus() == BattleManager.END_ANI_DIALOG then
			node:removeSelf(true)
			touchNode:removeSelf(true)
			return
		end
		node:removeSelf(true)
		touchNode:removeSelf(true)
        local grayLayer = self:addTouchLayer_(display.getRunningScene(), ccc4(0, 0, 0, 255*0.65))
        GameManager:getAudioData():playAudio(common.effectSoundList.all_clear_classic)
        --成功动画
        grayLayer:runAction(transition.sequence({CCDelayTime:create(0.25),CCCallFunc:create(function ()
            local partical = CCParticleSystemQuad:create("animation/particle_allcleared.plist")
            grayLayer:addChild(partical)
            partical:setPosition(ccp(display.width/2, display.height/2+100))
        end)}))
        local ani = ArmatureLoader.new("animation/eff_allcleared")
        grayLayer:addChild(ani)
        ani:setPosition(ccp(display.width/2, display.height/2+20))
        ani:getAnimation():play("play")

        ani:connectMovementEventSignal(function(evtType, moveId)
            if evtType == 1 then
                grayLayer:removeSelf()
                ani:disconnectMovementEventSignal()
                self:showWinDialog()
                GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):setEndAniStatus(BattleManager.END_ANI_DIALOG)
            end
        end)
	end

	self:performWithDelay(function ()
		if touchNode and not tolua.isnull(touchNode) then
			touchNode:setTouchEnabled(true)
		    touchNode:addNodeEventListener(cc.NODE_TOUCH_EVENT, function ( event )
		    	local name = event.name
		    	if name == "began" then
		    		endCallBack_(node)
		    	end
		    end)
		end
	end,0.5)

	local ok = false
    if radom == 1 then
        ok = AnimationDefine.winAnimation1(list,node,function ( )
			endCallBack_(node)
		end)
    elseif radom == 2 then
        ok = AnimationDefine.winAnimation2(list,node,function ( )
			endCallBack_(node)
		end)
    elseif radom == 3 then
        ok = AnimationDefine.winAnimation3(list,node,function ( )
			endCallBack_(node)
		end)
    end

	if not ok then
		endCallBack_(node)
		self:clearLight_()
		self.card_table:removeAllChildren()
	else
		self:performWithDelay(function ()
			self:clearLight_()
			self.card_table:removeAllChildren()
		end,0.02)
	end
end

--添加玩法类型累计胜利次数
function BattleManager:saveWinGameType( ... )
	local cacheData = GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):getCacheData()
	local isDeal = cacheData:getProperty("isDeal")
	local isDailyChallenge = GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):isDailyChallenge()

	local gameType_ = "1" --随机局
	if tostring(isDeal) == "1" then --活局
		gameType_ = "2"
	end
	if isDailyChallenge then --每日挑战
		gameType_ = "3"
	end
	GameManager:getUserClassicData():addRandomWinCount(gameType_,1)
end

function BattleManager:saveRecord(name)
	local threeMode = GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):getCacheData():getProperty("isDraw3Mode")
	if name == "newGame" then
		GameManager:getUserClassicData():addClassicCount(threeMode,1)
	elseif name == "win" then
		GameManager:getUserClassicData():addClassicWinCount(threeMode,1)
	elseif name == "record" then
		local high = false
		-- local step_ = GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):getCacheStepCount()
		local cacheData = GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):getCacheData()
		local step_ = cacheData:getProperty("move")
		

		local sec_ = GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):getRunningTime()
		GameManager:getUserClassicData():addClassicFewestMove(threeMode,step_)
		GameManager:getUserClassicData():addClassicFewestTime(threeMode,sec_)
		if GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):isVegasMode() then
			--维加斯模式
			local score_ = GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):getCacheData():getProperty("vegasScore")
			return false, {score=score_, move = step_, time = sec_}
		else
			--普通模式
			local score_ = GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):getCacheData():getProperty("score")
			score_ = score_ + GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):getTimeScore()
			high = GameManager:getUserClassicData():addClassicHighestScore(threeMode,score_)
			--保存排行榜信息
			local timeTemp = os.time()
			local userClassicRankVO = UserClassicRankVO.new({score=score_, moves = step_, time = sec_, createdTimestamp = timeTemp})
			local mode_ = UserClassicRankVO.MODE_1DRAW
			if threeMode == 1 then
				mode_ = UserClassicRankVO.MODE_3DRAW
			end
			GameManager:getUserClassicData():saveRankData(userClassicRankVO,mode_)

			local list = GameManager:getUserClassicData():getProperty("classicRankList") or {}
			local totalScore = 0
			local rankMode = GameCenterDefine.getLeaderBoardId().oneCard
			if threeMode == 1 then
				rankMode = GameCenterDefine.getLeaderBoardId().threeCards
				list = GameManager:getUserClassicData():getProperty("classicRankList3") or {}	
			end
			local newRecord = false
			for i=1,#list do
				totalScore = totalScore + list[i]:getProperty("score") or 0
				local time_ = list[i]:getProperty("createdTimestamp") or 0
				if time_ == timeTemp then
					newRecord = true
				end
			end
			--新纪录产生时上传排行榜总分数
			if newRecord then
				GameManager:getNativeManager():submitScore(totalScore,rankMode)
			end

			return high, {score=score_, move = step_, time = sec_}
		end

	end
end

--保存活局种子
function BattleManager:uploadSeed()
	local cacheData = GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):getCacheData()
	if not cacheData then
		return
	end

	local magicNum_ = cacheData:getProperty("magicNum")
	if magicNum_ > 0 then
		--使用过魔法不上传种子
		printf("使用过魔法不做胜利种子保存")
		return
	end
	local isDeal = cacheData:getProperty("isDeal")
	local isNewPlayer = cacheData:getProperty("isNewPlayer")
	if isDeal > 0 or isNewPlayer >0 then
		--活局不用上传种子
		printf("不做胜利种子保存")
		return
	end
	local userDealSeedVO = UserDealSeedVO.new()
	local seed = cacheData:getProperty("seed") or ""
	local mode = cacheData:getProperty("mode")
	local threeMode = cacheData:getProperty("isDraw3Mode")
	userDealSeedVO:setProperty("mode", mode)
	userDealSeedVO:setProperty("seed", seed)
	userDealSeedVO:setProperty("isDraw3Mode", threeMode)
	local needUpload_ = GameManager:getUserSeedData():saveDealSeedByList({userDealSeedVO},UserCacheRecordVO.mode_classic)
	if not needUpload_ then
		return
	end
	printf("种子上传")
	local list1mode = {}
	local list3mode = {}
	local seedList = GameManager:getUserSeedData():getDealSeedByList(UserCacheRecordVO.mode_classic) or {}
	for i=1,#seedList do
		if seedList[i]:getProperty("isDraw3Mode") > 0 then
			--每次翻三张模式
			list3mode[#list3mode+1] = seedList[i]:getProperty("seed")
		else
			--每次翻一张
			list1mode[#list1mode+1] = seedList[i]:getProperty("seed")
		end
	end
	local param = {}
	if #list1mode > 0 then
		param.draw1 = list1mode
	end
	if #list3mode > 0 then
		param.draw3 = list3mode
	end
	GameManager:getNetWork():saveSeed(param)
end

function BattleManager:addTouchLayer_( parent, corlor )
	if not parent then
		parent = display.getRunningScene()
	end
	parent:removeChildByTag(999, true)
	if not corlor then
		corlor = ccc4(0, 0, 0, 0)
	end
    local touchNode = display.newColorLayer(corlor)
    parent:addChild(touchNode, 10, 999)
    touchNode:setTouchEnabled(true)
    touchNode:addNodeEventListener(cc.NODE_TOUCH_EVENT,function(event)
        if event.name == "began" then
            return true
        elseif event.name == "moved" then
        elseif event.name == "ended" then
        end
    end)
    return touchNode
end

--todo 
function BattleManager:autoCollectCard( )
	self:startMoving()
	GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):setEndAniStatus(BattleManager.END_ANI_COLLECTING)
    local touchNode = self:addTouchLayer_(display.getRunningScene(), ccc4(0, 0, 0, 0))

	function linkCard_( card_before, card_next, headIndex )
		--分数统计
		-- GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):addStepCount(1)
		local score = self:calculateScore_(card_before, card_next, headIndex)
		GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):carryOnScore(score)
		EventNoticeManager:getInstance():dispatchEvent({name = Notice.GAME_DATA_CHANGE})
		--保持原链接的完整性
		if card_next:getBeforeCard() then
			--当card_next不是队首时，需要链接其前后两张
			card_next:getBeforeCard():setNextCard(card_next:getNextCard())
		else
			--当card_next是队首时，需要将headlist设置为它的下一张牌
			self.headsList_[card_next:getProperty("headIndex")] = card_next:getNextCard()
		end
		if card_next:getNextCard() then
			card_next:getNextCard():setBeforeCard(card_next:getBeforeCard())
		end
		GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):changeCacheStatusByCardVO(card_next:getNextCard())
		--链接到新的队列
		card_next:setNextCard(nil)
		card_next:setBeforeCard(nil)
		if card_before then
			card_before:setNextCard(card_next)
			card_next:setBeforeCard(card_before)
		else
			self.headsList_[headIndex] = card_next
		end
		card_next:setProperty("headIndex", headIndex)
		--保存牌面信息
		GameManager:getUserGameCacheData(GameManager.MODETYPE_SOLITAIRE):changeCacheStatusByCardVO(card_next)
	end
	function canCollect_(card_before, card_next, rank, suit, headIndex )
		if (rank == 0 or card_next:getProperty("suit") == suit) and card_next:getProperty("rank") == rank + 1 then
			linkCard_(card_before, card_next, headIndex)
			return true
		end
		return false
	end
	--寻找单个集卡区的牌
	function collect( headIndex )
		if headIndex < BattleManager.HEAD_COLLECT_1 or headIndex > BattleManager.HEAD_COLLECT_MAX then
			return false
		end
		local suit = 0--花色
		local rank = 0--点数
		local end_card = self.headsList_[headIndex]
		if end_card then
			end_card = DealerController.getQueueEndCardVO(end_card)
			suit = end_card:getProperty("suit")
			rank = end_card:getProperty("rank")
		end
		--判断牌桌上的
		for i=BattleManager.HEAD_COLUMN_1,BattleManager.HEAD_COLUMN_MAX do
			local last_card = self.headsList_[i]
			if last_card then
				last_card = DealerController.getQueueEndCardVO(last_card)
				if canCollect_(end_card, last_card, rank, suit, headIndex) then
					return true, last_card, headIndex, i
				end
			end
		end
		--判断集牌区
		for i=BattleManager.HEAD_CHANGE_1,BattleManager.HEAD_CHANGE_MAX do
			local last_card = self.headsList_[i]
			while last_card do
				if canCollect_(end_card, last_card, rank, suit, headIndex) then
					last_card:changeBoardTo(CardVO.BOARD_FACE, nil, true)
					return true, last_card, headIndex, i
				end
				last_card = last_card:getNextCard()
			end
		end
		return false
	end

	function collectCard( )
		for i=BattleManager.HEAD_COLLECT_1,BattleManager.HEAD_COLLECT_MAX do
			local ok, card, headIndex, lastHeadIndex = collect(i)
			if ok then
				-- printf("开始自动收牌:%s", card:getCardName())
				local pos = ccp(0, 0)
				pos.x, pos.y = self["column"..i]:getPosition()
				local beginPos = ccp(card:getView():getPosition())
				local move = CCMoveTo:create(0.1, pos)
				card:getView():stopAllActions()
				card:getView():runAction(transition.sequence({CCEaseSineInOut:create(move), CCCallFunc:create(function ()
					self:playPartical_(headIndex, 0)
					self:playScoreAction(beginPos, pos, self:checkMoveNeedAddScore(lastHeadIndex, i))
				end)}))
				self:reOrderZOrder_(card)
				self:palyCollectAudio(i, true)
				break
			end
			if i == BattleManager.HEAD_COLLECT_MAX and ok ~= true then
				touchNode:removeSelf()
				--结束的时候初始化相关数据
				if self.schedulerAudioHandle then
					self:stopAction(self.schedulerAudioHandle)
					self.schedulerAudioHandle = nil
				end
				self.comboCount_ = 0
				if DEBUG_PROFI == 2 then
					self.ProFi = require("app.common.ProFi")
					self.ProFi:start()
				end
				self:analysisWin_()
				if DEBUG_PROFI == 2 then
					self.ProFi:stop()
					self.ProFi:writeReport(device.writablePath.."born2play/Solitaire/statistics/MyProfilingReport.txt" )
				end
				return
			end
		end
		self:performWithDelay(function ()
			collectCard( )
		end,0.13)
	end

	collectCard()
end

function BattleManager:playPartical_( headIndex, startIndex )
	if headIndex < BattleManager.HEAD_COLLECT_1 or headIndex > BattleManager.HEAD_COLLECT_MAX 
		or headIndex == startIndex then
		return
	end
	local node = self["column"..headIndex]
	if not node then
		return
	end
	local pos = ccp(0, 0)
	pos.x, pos.y = node:getPosition() --node:getContentSize().width/2, node:getContentSize().height/2
    local partical = CCParticleSystemQuad:create("animation/particle_shoupai.plist")
    self.card_table:addChild(partical, -1)
    partical:setPosition(pos)
    partical:runAction(transition.sequence({CCDelayTime:create(1.2),
    	CCCallFunc:create(function ( )
    		partical:removeSelf()
    	end)}))
end

function BattleManager:palyCollectAudio( headIndex, collecting )
	if headIndex < BattleManager.HEAD_COLLECT_1 or headIndex > BattleManager.HEAD_COLLECT_MAX then
		return
	end
	if self.playing then
		return
	end
	self.playing = true
	self:performWithDelay(function ()
			self.playing = false
		end,0.18)
	if self.schedulerAudioHandle then
		self:stopAction(self.schedulerAudioHandle)
		self.schedulerAudioHandle = nil
	end
	if not self.comboCount_ then
		self.comboCount_ = 0
	end
	self.comboCount_ = self.comboCount_ + 1
	if not collecting then
		if self.comboCount_ > 10 then
			self.comboCount_ = 10
		end
		GameManager:getAudioData():playAudio(common.effectSoundList["collect_score"..self.comboCount_],nil,nil,true)
		self.schedulerAudioHandle = self:performWithDelay(function ()
				self.schedulerAudioHandle = nil
				self.comboCount_ = 0
			end,8)
	else
		if self.comboCount_ <= 10 then
			GameManager:getAudioData():playAudio(common.effectSoundList["collect_score"..self.comboCount_],nil,nil,true)
		elseif self.comboCount_ == 11 then
			GameManager:getAudioData():playAudio(common.effectSoundList.collect_score11,nil,nil,true)
		end
	end

end

function BattleManager:checkMoveNeedAddScore(startHeadIndex, endHeadIndex)
	local isFishdom = PackageConfigDefine.isSolitaireFishdom()
	if not isFishdom then
		return 0
	end

	local userDM = GameManager:getUserData()
	local isVegasMode = (userDM:getProperty("isVegasMode") ~= 0) 
	if isVegasMode then
		if (startHeadIndex <= BattleManager.HEAD_COLLECT_MAX and startHeadIndex > BattleManager.HEAD_COLUMN_MAX) 
			and (endHeadIndex <= BattleManager.HEAD_COLUMN_MAX or endHeadIndex > BattleManager.HEAD_COLLECT_MAX) then
			return -BattleManager.SCORE_LOCK_TO_COLUMN
		elseif (endHeadIndex <= BattleManager.HEAD_COLLECT_MAX and endHeadIndex > BattleManager.HEAD_COLUMN_MAX) 
			and (startHeadIndex <= BattleManager.HEAD_COLUMN_MAX or startHeadIndex > BattleManager.HEAD_COLLECT_MAX) then
			return BattleManager.SCORE_LOCK_TO_COLUMN
		end
	else
		if startHeadIndex > BattleManager.HEAD_COLLECT_MAX and endHeadIndex <= BattleManager.HEAD_COLUMN_MAX then
			return BattleManager.SCORE_LOCK_TO_COLUMN
		elseif (startHeadIndex <= BattleManager.HEAD_COLLECT_MAX and startHeadIndex > BattleManager.HEAD_COLUMN_MAX) then
			if endHeadIndex <= BattleManager.HEAD_COLUMN_MAX then
				return -BattleManager.COLUMN_TO_COLLECT
			elseif endHeadIndex > BattleManager.HEAD_COLLECT_MAX then
				return -BattleManager.SCORE_COLLECT
			end
		elseif (endHeadIndex <= BattleManager.HEAD_COLLECT_MAX and endHeadIndex > BattleManager.HEAD_COLUMN_MAX) then
			if startHeadIndex <= BattleManager.HEAD_COLUMN_MAX then
				return BattleManager.COLUMN_TO_COLLECT
			elseif startHeadIndex > BattleManager.HEAD_COLLECT_MAX then
				return BattleManager.SCORE_COLLECT
			end
		elseif endHeadIndex > BattleManager.HEAD_COLLECT_MAX and startHeadIndex <= BattleManager.HEAD_COLUMN_MAX then
			return -BattleManager.SCORE_LOCK_TO_COLUMN
		end
	end
	return 0
end

function BattleManager:playScoreAction(posBegin, posEnd, scoreNum)
	local isFishdom = PackageConfigDefine.isSolitaireFishdom()
	if not self.card_table or not isFishdom then
		return
	end
	common.scoreAction(self.card_table, posBegin, posEnd, scoreNum)
end

function BattleManager:playFlipCardScore(pos, scoreNum)
	local userDM = GameManager:getUserData()
	local isVegasMode = (userDM:getProperty("isVegasMode") ~= 0) 
	if not isVegasMode then
		self:playScoreAction(pos, pos, scoreNum)
	end
end

return BattleManager