--
-- Author: Huang Hai Long
-- Date: 2017-03-30 12:17:59
--
local BattleManagerTriPeaks = class("BattleManagerTriPeaks",function()
	return display.newNode()
end)

BattleManagerTriPeaks.POS_BEGIN = 1 --pos开始点
BattleManagerTriPeaks.POS_PLAY_MAX = 28 --玩牌区posMax
BattleManagerTriPeaks.POS_MAX = 30 --pos点数量
BattleManagerTriPeaks.BEGIN_BACK_POS = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18}--开局时，牌背朝上的位置
BattleManagerTriPeaks.BEGIN_FACE_POS = {19,20,21,22,23,24,25,26,27,28,29}--开局时，牌面朝上的位置
BattleManagerTriPeaks.POS_CHANGE_1 = 29 --切牌pos1 (正面)
BattleManagerTriPeaks.POS_CHANGE_2 = 30 --切牌pos2 (背面)


--pos子节点映射表
BattleManagerTriPeaks.POS_CHILDREN = {
	[1] = {4,5},
	[2] = {6,7},
	[3] = {8,9},
	[4] = {10,11},
	[5] = {11,12},
	[6] = {13,14},
	[7] = {14,15},
	[8] = {16,17},
	[9] = {17,18},
	[10] = {19,20},
	[11] = {20,21},
	[12] = {21,22},
	[13] = {22,23},
	[14] = {23,24},
	[15] = {24,25},
	[16] = {25,26},
	[17] = {26,27},
	[18] = {27,28},
}


BattleManagerTriPeaks.END_ANI_NONE = 0
BattleManagerTriPeaks.END_ANI_COLLECTING = 1--收集
BattleManagerTriPeaks.END_ANI_STUFF = 2--洗牌
BattleManagerTriPeaks.END_ANI_DIALOG = 3--结算窗
BattleManagerTriPeaks.END_ANI_END = 4--结束

function BattleManagerTriPeaks:ctor(delegate)
	GameManager:getAudioData():stopAllAudios()
	KMultiLanExtend.extend(self)
	self:initView_()

	self.changeOffsetX_ = self:isPortrait_() and 7 or 10

	self.headsList_ = {}

	self:setDelegate(delegate)
	
	self.cardMoving_ = false
	self.comboCount_ = 0
	self.isWinning_ = false	
	self.isTiping_ = false

	--初始化牌组
	self:startGame(nil, true)
	self:setNodeEventEnabled(true)

end

function BattleManagerTriPeaks:onEnter( )
	EventNoticeManager:getInstance():addEventListener(self,Notice.APP_ENTER_BACKGROUND,handler(self, self.gameEnterBackground_))
	-- EventNoticeManager:getInstance():addEventListener(self,Notice.USER_DATA_CHANGE,handler(self, self.leftModeChanged))
	EventNoticeManager:getInstance():addEventListener(self,Notice.USER_LANGUAGE_CHANGE,handler(self, self.setLocalization_))
    EventNoticeManager:getInstance():addEventListener(self,Notice.USER_CARD_CHANGE,handler(self, self.updataAllCards))
    
    EventNoticeManager:getInstance():addEventListener(self,Notice.USER_HINT_DATA_CHANGE,handler(self, self.updataHintLogic_))
    

end

function BattleManagerTriPeaks:setLocalization_( )
	if self.tipsLabel_ then
		local str = nil
		if self.tipsLabel_.v1 then
			-- str = Localization.string("点击任意{value1}或者{value2}将它放置在{value3}上",{value1 = tostring(self.tipsLabel_.v1),value2 = tostring(self.tipsLabel_.v2),value3 = tostring(self.tipsLabel_.v3)})
			-- self:setLabelString(self.tipsLabel_,str)
			self:setLabelString(self.tipsLabel_, "点击任意{value1}或者{value2}将它放置在{value3}上",{value1 = tostring(self.tipsLabel_.v1),value2 = tostring(self.tipsLabel_.v2),value3 = tostring(self.tipsLabel_.v3)})
		else
			str = Localization.string("切一张新牌")
			self:setLabelString(self.tipsLabel_,str)
		end
	end
	-- self:setBtnTitle(self.btn_autoCollect, "自动收牌")
end

function BattleManagerTriPeaks:onExit( )
	EventNoticeManager:getInstance():removeEventListenerForHandle(self)
end

function BattleManagerTriPeaks:getHeadsList()
	return self.headsList_ or {}
end

function BattleManagerTriPeaks:updataAllCards(event)
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
end

function BattleManagerTriPeaks:gameEnterBackground_( )
	local sec = GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):getRunningTime()
	GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):changeCacheData({gameTime = sec})

	GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):saveCache()
	GameManager:getUserChallengeData():saveCache()
end

function BattleManagerTriPeaks:starNewGame( seed, resetAll )
	GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):cleanData()
	-- self:clearLight_()
	self:stopAllActions()
	self:hideHelpLabel()
	self.card_table:removeAllChildren()
	self.headsList_ = {}
	self.cardMoving_ = false
	self.comboCount_ = 0
	self.isWinning_ = false
	self.isTiping_ = false

	GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):cleanRecordData()
	--初始化牌组
	self:startGame(seed, resetAll)
end

function BattleManagerTriPeaks:initView_( )
	--计算视图大小
	local isPortrait = self:isPortrait_()
	local displaySize = CCSizeMake(display.width, display.height)
	if isPortrait then
		displaySize = CCSizeMake(USER_SCREEN_WIDTH, USER_SCREEN_HEIGHT)
	else
		displaySize = CCSizeMake(USER_SCREEN_HEIGHT, USER_SCREEN_WIDTH)
	end
	self:setContentSize(displaySize)

	local ccbName = isPortrait and "battleTriPeaksView" or "battleTriPeaksView_land"
	--读取ccb文件
	local reader = CCBReader.new()
	local root = reader:load("ccb/"..ccbName..".ccbi",ccbName,self,displaySize)
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

end

--设置卡槽以及图标主题
function BattleManagerTriPeaks:setCardsSlot(style)

end

function BattleManagerTriPeaks:startGame( seed, resetAll )
	local endAniStatus = GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):getEndAniStatus() or BattleManagerTriPeaks.END_ANI_NONE
	local list = GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):getCacheCardList_()

	if table.nums(list) <= 0 then
		--没有牌面信息需要判断是否播放结算动画
		if endAniStatus == BattleManagerTriPeaks.END_ANI_STUFF then
			self:showStuffAnimation()
		elseif endAniStatus == BattleManagerTriPeaks.END_ANI_DIALOG then
			-- self:showWinDialog(true)--胜利弹窗在切屏之后会自动弹出了，这里不处理了
		elseif endAniStatus == BattleManagerTriPeaks.END_ANI_END then
			--todo
		else
			GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):resetCacheData(resetAll)
			self:initCard_(seed)
			--发牌
			self:startDealCard(true)
		end
	else
		self:runReplay(list)
		--发牌
		self:startDealCard()
	end
	self:openAutoTips_()
end

function BattleManagerTriPeaks:initCard_( _seed )
	--获取牌组
	local list = DealerController.initCards()
	local seed_ = ""
	local isNewPlayer = false
	--如果不是重玩本局
	if not _seed then
		--判断是否是活局
		local userDM = GameManager:getUserData()
		local isSolvedMode = userDM:isSolvedMode() --是否是活局
		if isSolvedMode then
			_seed = userDM:getDealSeed(4)
		else
			isNewPlayer = GameManager:getUserClassicData():isNewPlayer()--就算是随机局也给新玩家使用活局种子
			if isNewPlayer then
				local isDeal = false
				_seed,isDeal = userDM:getDealSeed(4)
				if not isDeal then
					isNewPlayer = false
				end
				if isNewPlayer then
					printf("新手局使用种子：%s",_seed)
				else
					printf("随机局使用种子：%s",_seed)
				end
			end
		end
	end

	--洗牌
	list, seed_ = DealerController.shuffleCards(list, _seed)

	GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):changeCacheData({seed = seed_, gameState = UserCacheRecordVO.status_playing, isNewPlayer = ((isNewPlayer and 1) or 0)})
	EventNoticeManager:getInstance():dispatchEvent({name = Notice.GAME_STATUS_CHANGE})
	local cacheList = {}

	for i=BattleManagerTriPeaks.POS_BEGIN,BattleManagerTriPeaks.POS_MAX-1 do
		self.headsList_[i] = list[1]
		table.remove(list, 1)
		self.headsList_[i]:setProperty("headIndex", i)
		cacheList[#cacheList+1] = self.headsList_[i]
	end


	for i=1, #list do
		local currCard_ = list[i]
		if currCard_ then
			local before_ = list[i-1]
			local next_ = list[i+1]
			currCard_:setBeforeCard(before_)
			currCard_:setNextCard(next_)


			if i == 1 then
				self.headsList_[BattleManagerTriPeaks.POS_CHANGE_2] = currCard_
			end
			currCard_:setProperty("headIndex", BattleManagerTriPeaks.POS_CHANGE_2)
			cacheList[#cacheList+1] = currCard_
		end
	end

	GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):changeCacheStatusByCardList(cacheList)
end

function BattleManagerTriPeaks:runReplay(list)
	if not list then
		return
	end
	for k,v in pairs(list) do
		if v and #v > 0 then
			for i=1,#v do
				local cardVO = v[i]
				if cardVO then
					cardVO:clearView()
					local before_ = v[i-1]
					local next_ = v[i+1]
					cardVO:setBeforeCard(before_)
					cardVO:setNextCard(next_)
					if i == 1 then
						self.headsList_[k] = cardVO
					end
				end
			end
		end
	end
end

function BattleManagerTriPeaks:isPortrait_( )
	return CONFIG_SCREEN_ORIENTATION == "portrait"
end

--左手模式变更了
function BattleManagerTriPeaks:leftModeChanged( )
	
end

function BattleManagerTriPeaks:reloadCardsPosBy(index)
	local card = self.headsList_[index]
	local len_ = DealerController.getQueueLenByHead(self.headsList_[index])
	local offset_pos = ccp(0, 0)
	if index == BattleManagerTriPeaks.POS_CHANGE_2 then
		offset_pos = ccp(-self.changeOffsetX_*(len_-1), 0)
	end
	
	while card do
		local sprite = card:getView()
		if index == BattleManagerTriPeaks.POS_CHANGE_2 then
			offset_pos = ccp(offset_pos.x+self.changeOffsetX_, offset_pos.y)
		end
		if sprite then
			sprite:setPosition(ccp(self["pos"..index]:getPositionX() + offset_pos.x,
				self["pos"..index]:getPositionY() + offset_pos.y))
			if not sprite:getParent() then
				self.card_table:addChild(sprite,0)
			end
		else
			printf("no card sprite!")
		end
		card = card:getNextCard()
	end

	-- if index == BattleManagerTriPeaks.POS_CHANGE_2 then
	-- 	self:reOrderZOrder_( self.headsList_[index], 0 ,true)
	-- end
end

function BattleManagerTriPeaks:reloadCardsPos( )
	--牌桌上的卡牌
	for i=1,BattleManagerTriPeaks.POS_MAX do
		self:reloadCardsPosBy(i)
	end
end

function BattleManagerTriPeaks:reOrderZOrder_( cardVO, zOrder ,reverse)
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
	-- if reverse then
	-- 	cardVO = DealerController.getQueueEndCardVO(cardVO)
	-- 	while cardVO do
	-- 		cardVO:getView():setZOrder(zOrder)
	-- 		cardVO = cardVO:getBeforeCard()
	-- 	end
	-- else
	-- 	while cardVO do
	-- 		cardVO:getView():setZOrder(zOrder)
	-- 		cardVO = cardVO:getNextCard()
	-- 	end
	-- end
	
end

function BattleManagerTriPeaks:isFindInList( list,value )
	for k,v in pairs(list) do
		if value == v then
			return k
		end
	end
	return nil
end

function BattleManagerTriPeaks:startDealCard( animation )
	self:stopAllActions()
	self.playing = false
	--此时才开始创建卡牌的形象
	if animation then
		self:startMoving()
		local zOrder = 52

		for i=BattleManagerTriPeaks.POS_BEGIN,BattleManagerTriPeaks.POS_MAX do
			local card = self.headsList_[i]
			while card do
				local sprite = card:getView()
				if sprite then
					sprite:setPosition(ccp(self.cardPos:getPositionX(), self.cardPos:getPositionY()))---500
					if not sprite:getParent() then
						self.card_table:addChild(sprite)
						sprite:setZOrder(zOrder)
						zOrder = zOrder - 1
					end
				end
				card = card:getNextCard()
			end
		end

		--屏蔽触摸和按钮
	    local touchNode = self:addTouchLayer_(display.getRunningScene(), ccc4(0, 0, 0, 0))

		function showAni( headIndex, card )

			if headIndex > BattleManagerTriPeaks.POS_MAX then
				self.headsList_[BattleManagerTriPeaks.POS_CHANGE_2] = DealerController.reverseQueueByCardVO(self.headsList_[BattleManagerTriPeaks.POS_CHANGE_2])
				
				local list_ = DealerController.getListByHead(self.headsList_[BattleManagerTriPeaks.POS_CHANGE_2])
				GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):changeCacheStatusByCardList(list_)
				-- local status_ = self.headsList_[BattleManagerTriPeaks.POS_CHANGE_2]
				-- while status_ do
				-- 	GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):changeCacheStatusByCardVO(status_)
				-- 	status_ = status_:getNextCard()
				-- end

				-- self:testPrintLink(BattleManagerTriPeaks.POS_CHANGE_2)
				self:endMoving()
				touchNode:removeSelf(true)
				return
			end

			if not card then
				showAni(headIndex+1, self.headsList_[headIndex+1])
			else
				local durationM_ = 0.2
				local mX_ = self["pos"..headIndex]:getPositionX()
				local mY_ = self["pos"..headIndex]:getPositionY()
				if headIndex == BattleManagerTriPeaks.POS_CHANGE_2 then
					local len_ = DealerController.getQueueLenByBottom(card)
					mX_ = mX_ - self.changeOffsetX_*(len_-1)
					card:getView():setPosition(ccp(self["pos"..headIndex]:getPositionX(), self["pos"..headIndex]:getPositionY()))
					durationM_ = 0.05
				end
				local move = CCMoveTo:create(durationM_, ccp(mX_,mY_))--count*self:getCardOffsetY_()))
				local delay = CCDelayTime:create(0.2)
				local flip = CCCallFunc:create(function ()
					card:changeBoardTo(CardVO.BOARD_FACE)
				end)
				local call = CCCallFunc:create(function ()
					GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):changeCacheStatusByCardVO(card)
				end)
				local callzOrder = CCCallFunc:create(function ()
					if headIndex ~= BattleManagerTriPeaks.POS_CHANGE_2 then
						card:getView():setZOrder(0)
					end
				end)

				card:getView():runAction(transition.sequence({move,callzOrder}))
				if self:isFindInList(BattleManagerTriPeaks.BEGIN_FACE_POS,headIndex) then
					card:getView():runAction(transition.sequence({delay,flip,CCDelayTime:create(0.02),call}))					
				end

				self:performWithDelay(function ()
					showAni(headIndex, card:getNextCard())
				end,0.03)
			end
			if not self.playing then
				self.playing = true
				self:performWithDelay(function ()
						self.playing = false
					end,0.05)
				GameManager:getAudioData():playAudio(common.effectSoundList.tableau)
			end

		end
		showAni(1, self.headsList_[1])

	else
		self:judgeFilpCards()
		self:reloadCardsPos()
	end

	-- for i=1,BattleManagerTriPeaks.POS_CHANGE_2 do
	-- 	if self.headsList_[i] then
	-- 		self:testPrintLink(i)
	-- 	end
	-- end

	for i=BattleManagerTriPeaks.POS_BEGIN,BattleManagerTriPeaks.POS_MAX do
		--设置卡牌的回调
		local card = self.headsList_[i]
		while card do
			card:getView():setTouchBegin(handler(self, self.cardTouchBegan))
			card:getView():setTouchMoving(handler(self, self.cardTouchMoving))
			card:getView():setTouchEnd(handler(self, self.cardTouchEnd))
			card:getView():setTouchCancel(handler(self, self.cardTouchCancel))
			card = card:getNextCard()
		end
	end

	self:updateBtnStatus_()
end

function BattleManagerTriPeaks:cardTouchBegan( cardSp, x, y )
	self:resumeGame(true)
	local headIndex = cardSp.data_.headIndex_
	if not (headIndex >= BattleManagerTriPeaks.POS_BEGIN and headIndex <= BattleManagerTriPeaks.POS_PLAY_MAX) then
		return false
	end

	return true
end

function BattleManagerTriPeaks:cardTouchMoving( cardSp, x, y )
	
end

function BattleManagerTriPeaks:cardTouchEnd( cardSp, x, y )
	local startHeadIndex = cardSp.data_.headIndex_

	local isClick_ = common.judgeTouchInNode(ccp(x, y),cardSp)
	local isCanCollect_ = false
	local cardBefore_ = nil
	if isClick_ then
		isCanCollect_,cardBefore_ = self:judgeCardCanCollect(cardSp.data_)
	else
		cardSp:shake(true)
		GameManager:getAudioData():playAudio(common.effectSoundList.shake_card)
	end

	if isCanCollect_ then
		self:linkTwoCard(cardBefore_, cardSp.data_, BattleManagerTriPeaks.POS_CHANGE_1)
		self:moveCards(cardSp.data_, startHeadIndex)
	else
		cardSp:shake(true)
		GameManager:getAudioData():playAudio(common.effectSoundList.shake_card)
		if self:analysisFail_() then
			GameManager:getInstance():popNoWayAlert(false)
		end
	end
end

function BattleManagerTriPeaks:judgeCardCanCollect( card )
	local cardEnd_ = DealerController.getQueueEndCardVO(self.headsList_[BattleManagerTriPeaks.POS_CHANGE_1])
	local result_ = DealerController.tripeaksCanCollect(card,cardEnd_)
	return result_,cardEnd_
end

function BattleManagerTriPeaks:judgeFilpCards()
	local changeList_ = {}
	for i=BattleManagerTriPeaks.POS_BEGIN,BattleManagerTriPeaks.POS_PLAY_MAX do
		-- local index_ = BattleManagerTriPeaks.BEGIN_BACK_POS[i]
		if self.headsList_[i] then
			local list_ = DealerController.tripeaksGetChildrenByPos(i)
			local foundChildren_ = false
			for j=1,#list_ do
				if self.headsList_[list_[j]] then
					foundChildren_ = true
					break
				end
			end

			if self.headsList_[i]:getProperty("board") == CardVO.BOARD_BACK and not foundChildren_ then
				self.headsList_[i]:changeBoardTo(CardVO.BOARD_FACE)
				changeList_[#changeList_ + 1] = self.headsList_[i]
				-- GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):changeCacheStatusByCardVO(self.headsList_[i])
			elseif self.headsList_[i]:getProperty("board") == CardVO.BOARD_FACE and foundChildren_ then
				self.headsList_[i]:changeBoardTo(CardVO.BOARD_BACK)
				changeList_[#changeList_ + 1] = self.headsList_[i]
				-- GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):changeCacheStatusByCardVO(self.headsList_[i])
			end
		end
	end

	if self.headsList_[BattleManagerTriPeaks.POS_CHANGE_1] then
		local change1_ = DealerController.getQueueEndCardVO(self.headsList_[BattleManagerTriPeaks.POS_CHANGE_1])
		if change1_ then
			if change1_:getProperty("board") == CardVO.BOARD_BACK then
				change1_:changeBoardTo(CardVO.BOARD_FACE)
				changeList_[#changeList_ + 1] = change1_
			end
		end
	end

	if #changeList_ > 0 then
		GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):changeCacheStatusByCardList(changeList_)
	end
	
end

function BattleManagerTriPeaks:moveCards( card, startHeadIndex )
	if not card then
		return
	end

	local headIndex = card.headIndex_
	local pos = ccp(0, 0)
	pos.x, pos.y = self["pos"..headIndex]:getPosition()

	if headIndex and headIndex <= BattleManagerTriPeaks.POS_PLAY_MAX then
		self:judgeFilpCards()
	end

	function soundCall()
		self:palyCollectAudio( startHeadIndex,headIndex )
	end

	local beginPos = ccp(card:getView():getPosition())
	function endCall()
		self:endMoving(startHeadIndex)
		if startHeadIndex == BattleManagerTriPeaks.POS_CHANGE_2 
			or headIndex == BattleManagerTriPeaks.POS_CHANGE_2 then
			self:reloadCardsPosBy(BattleManagerTriPeaks.POS_CHANGE_2)
		end
		-- self:playPartical_(headIndex, startHeadIndex)
		local score = self:checkMoveNeedAddScore(startHeadIndex, headIndex)
		self:playScoreAction(beginPos, pos, score)
	end

	local isCollecte_ = false
	if startHeadIndex >= BattleManagerTriPeaks.POS_BEGIN 
		and startHeadIndex <= BattleManagerTriPeaks.POS_PLAY_MAX 
		and headIndex == BattleManagerTriPeaks.POS_CHANGE_1 then
		isCollecte_ = true
	end

	while card and not tolua.isnull(card:getView()) do
		self:startMoving()

		card:getView():setScale(1)
		card:getView():setRotation(0)
		card:getView():setZOrder(53)
		card:getView():stopAllActions()

		if isCollecte_ then
			local beginPos = ccp(card:getView():getPositionX(), card:getView():getPositionY())
			local endPos = ccp(self["pos"..BattleManagerTriPeaks.POS_CHANGE_1]:getPositionX(), self["pos"..BattleManagerTriPeaks.POS_CHANGE_1]:getPositionY())
			AnimationDefine.parabolaAnimation(card:getView(),beginPos,endPos,function ( )
				endCall()
			end,function() 
				soundCall()
			end)
		else
			local moveTo = CCEaseSineInOut:create(CCMoveTo:create(0.15, pos))
			local call = CCCallFunc:create(function ( )
				endCall()
			end)
			
			if card:getNextCard() then
				card:getView():runAction(moveTo)
			else
				card:getView():runAction(transition.sequence({moveTo, call}))
			end
		end

		
		card = card:getNextCard()
	end

	-- if headIndex == BattleManagerTriPeaks.POS_CHANGE_2 then
	-- 	self:reOrderZOrder_( self.headsList_[headIndex], 0 ,true)
	-- else
	-- 	self:reOrderZOrder_(self.headsList_[headIndex])
	-- end
	self:hideHelpLabel()
end

function BattleManagerTriPeaks:cardTouchCancel( cardSp, x, y )
	self:cardTouchEnd(cardSp, x, y)
end


BattleManagerTriPeaks.COLLECT_VALUE = 100 --收一张牌
-- BattleManagerTriPeaks.MOVE_VALUE = -1 --走一步
-- BattleManagerTriPeaks.REVOKE_VALUE = -1 --撤销一步

function BattleManagerTriPeaks:calculateScore_(card_before, card_next, headIndex )
	local score = 0
	if card_next and card_next:getProperty("headIndex") <= BattleManagerTriPeaks.POS_PLAY_MAX and headIndex == BattleManagerTriPeaks.POS_CHANGE_1 then
		--收牌
		score = score + BattleManagerTriPeaks.COLLECT_VALUE
	end

	return score
end

function BattleManagerTriPeaks:testPrintLink(index)
	printf("-----------------index:%s",tostring(index))
	local card = self.headsList_[index]
	local len_ = 0
	while card do
		len_ = len_ + 1
		printf("-->%s[%s]",tostring(card:getCardName()),tostring(card:getProperty("board") == CardVO.BOARD_FACE))
		card = card:getNextCard()
	end
	printf("-->len:%s",tostring(len_))
end

--处理两张卡牌的链接以及头部索引的操作
function BattleManagerTriPeaks:linkTwoCard(card_before, card_next, headIndex, notRecordStep )
	if not card_next then
		return
	end
	-- if headIndex == BattleManagerTriPeaks.POS_CHANGE_2 then
	-- 	if card_before then
	-- 		card_before = self.headsList_[headIndex]
	-- 	end
	-- else
	-- 	if card_before and card_before:getNextCard() then
	-- 		return
	-- 	end
	-- end
	if card_before and card_before:getNextCard() then
		return
	end

	local oldIndex_ = card_next:getProperty("headIndex")
	local userCacheStepVO = UserCacheStepVO.new()
	local score = self:calculateScore_(card_before, card_next, headIndex)
	userCacheStepVO:setProperty("score", score)
	userCacheStepVO:setProperty("stepStart", card_next:getProperty("headIndex"))
	if not card_next:getBeforeCard() then
		--将原有的头置空
		self.headsList_[card_next:getProperty("headIndex")] = nil
	end
	if card_before then
		headIndex = card_before:getProperty("headIndex")
		-- GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):changeCacheStatusByCardVO(card_before)
	end

	if headIndex then
		card_next:setProperty("headIndex", headIndex)
	end
	--音效
	GameManager:getAudioData():playAudio(common.effectSoundList.success)
	-- self:palyCollectAudio(oldIndex_,headIndex)

	DealerController.linkTwoCard(card_before, card_next)

	if oldIndex_ == BattleManagerTriPeaks.POS_CHANGE_2 and headIndex == BattleManagerTriPeaks.POS_CHANGE_1 then
		card_next:changeBoardTo(CardVO.BOARD_FACE, CardVO.FLIP_TYPE_LEFT, true)
	elseif headIndex == BattleManagerTriPeaks.POS_CHANGE_2 and oldIndex_ == BattleManagerTriPeaks.POS_CHANGE_1 then
		card_next:changeBoardTo(CardVO.BOARD_BACK, CardVO.FLIP_TYPE_RIGHT, true)
	end
	
	if not card_next:getBeforeCard() then
		--重置头
		self.headsList_[card_next:getProperty("headIndex")] = card_next
	end

	--保存牌面信息
	GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):changeCacheStatusByCardVO(card_next)
	--保存步骤信息
	userCacheStepVO:setProperty("stepEnd", card_next:getProperty("headIndex"))
	userCacheStepVO:setProperty("count", DealerController.getQueueLenByHead(card_next))


	if not notRecordStep then
		GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):saveCacheStep(userCacheStepVO)
		GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):addStepCount(1)
		GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):carryOnScore(userCacheStepVO:getProperty("score"))
	end
	local sec = GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):getRunningTime()
	GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):changeCacheData({gameTime = sec})
	self:updateBtnStatus_()
end

function BattleManagerTriPeaks:judgeMistake_()
	local openHint = GameManager:getUserData():getOpenHint()
	if GameManager:getInstance():supportTips() == false or openHint == 0 then
		return
	end
	--震动
	local list_ = self:analysisCollectCards_()
	for i=1,#list_ do
		list_[i]:getView():shake(true)
	end
end

function BattleManagerTriPeaks:tapChange()
	local nextCard_ = DealerController.getQueueEndCardVO(self.headsList_[BattleManagerTriPeaks.POS_CHANGE_2])
	local beforeCard_ = DealerController.getQueueEndCardVO(self.headsList_[BattleManagerTriPeaks.POS_CHANGE_1])
	if not nextCard_ then
		return
	end
	self:resumeGame(true)
	self:judgeMistake_()
	self:linkTwoCard(beforeCard_, nextCard_, BattleManagerTriPeaks.POS_CHANGE_1)
	self:moveCards(nextCard_, BattleManagerTriPeaks.POS_CHANGE_2)

end

function BattleManagerTriPeaks:didAddCardToOpen( notReOrder )
	
end

--将开放区的牌回复到锁区
function BattleManagerTriPeaks:putCardToLock( count, notRecordStep )
	
end

--将锁区的牌撤销到开放区
function BattleManagerTriPeaks:putCardToOpen( count, notRecordStep )

end

function BattleManagerTriPeaks:setDelegate( delegate )
	self.delegate_ = delegate
end

function BattleManagerTriPeaks:updateBtnStatus_( )
	if self.delegate_ and self.delegate_.setBtn5Enabled then
		local stepData = GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):getCacheStepByLast()
		if stepData then
			self.delegate_:setBtn5Enabled(true)
		else
			self.delegate_:setBtn5Enabled(false)
		end
	end
	EventNoticeManager:getInstance():dispatchEvent({name = Notice.GAME_DATA_CHANGE})
end

function BattleManagerTriPeaks:startMoving( )
	self.cardMoving_ = true
end

function BattleManagerTriPeaks:endMoving(startHeadIndex)
	-- if startHeadIndex and startHeadIndex <= BattleManagerTriPeaks.POS_PLAY_MAX then
	-- end
	self:judgeFilpCards()
	-- if startHeadIndex then
	-- 	self:dealOffsetY(startHeadIndex)
	-- 	if headIndex ~= startHeadIndex then
	-- 		self:dealOffsetY(headIndex)
	-- 	end
	-- end
	self.cardMoving_ = false
	-- self:analysisCollectCard_()
	local isWin_ = self:analysisWin_()
	if not isWin_ then
		if self:analysisFail_() then
			GameManager:getInstance():popNoWayAlert(false)
		end
	end
end

--暂停游戏
function BattleManagerTriPeaks:pauseGame()
	GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):setStartTime(0)
end
--继续游戏
function BattleManagerTriPeaks:resumeGame(force)
	local gameState = GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):getCacheData():getProperty("gameState")
	if gameState ~= UserCacheRecordVO.status_playing or not force then
		return
	end
	--此局生效，提交统计数据
	local isRepeat_ = GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):getCacheData():getProperty("isRepeat")
	if isRepeat_ == 0 then
		--快照数据
		GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):changeCacheData({isRepeat = 1})
		--游戏统计数据
		self:saveRecord("newGame")
	end
	GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):changeCacheData({gameState = UserCacheRecordVO.status_playing})
	GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):setStartTime(1)
	EventNoticeManager:getInstance():dispatchEvent({name = Notice.GAME_STATUS_CHANGE})

end

function BattleManagerTriPeaks:tapRevoke()
	if self.cardMoving_ then
		return
	end
	local stepData = GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):getCacheStepByLast()
	if not stepData then
		return
	end
	self:resumeGame(true)
	GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):removeCacheStepByLast()
	
	GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):addStepCount(-1)
	--将增加的分数返还
	GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):carryOnScore(-stepData:getProperty("score"))

	local card_before = self.headsList_[stepData:getProperty("stepStart")]
	if card_before then
		card_before = DealerController.getQueueEndCardVO(card_before)
	end
	local card_next = self.headsList_[stepData:getProperty("stepEnd")]
	if card_next then
		card_next = DealerController.getQueueEndCardVO(card_next)
	end
	card_next = DealerController.getCardByCountFromBottom(card_next,stepData:getProperty("count"))
	-- if stepData:getProperty("beforeIsFlip") == 1 and card_before then
	-- 	card_before:changeBoardTo(CardVO.BOARD_BACK, nil, true)
	-- end
	self:linkTwoCard(card_before, card_next, stepData:getProperty("stepStart"), true)
	self:moveCards(card_next, stepData:getProperty("stepEnd"))
	-- GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):carryOnScore(BattleManagerTriPeaks.REVOKE_VALUE)

end

function BattleManagerTriPeaks:tapHint()
	-- self:clearLight_(true)
	self:showHelpMove(false)
end

function BattleManagerTriPeaks:analysisCollectCards_()
	local list_ = {}
	for i=BattleManagerTriPeaks.POS_BEGIN,BattleManagerTriPeaks.POS_PLAY_MAX do
		if self.headsList_[i] 
			and self.headsList_[i]:getProperty("board") == CardVO.BOARD_FACE then
			local isCanCollect_ = self:judgeCardCanCollect(self.headsList_[i])
			if isCanCollect_ then
				list_[#list_ + 1] = self.headsList_[i]
			end
		end
	end
	return list_
end

function BattleManagerTriPeaks:createTipsLayer()
	self.isTiping_ = true
	local layer_ = display.newNode()--display.newColorLayer(ccc4(0, 0, 0, 255*0.65))
	layer_:setContentSize(self.card_table:getContentSize())
	layer_:setScale(self:getScale())
	self.card_table:addChild(layer_,100)

	layer_:setTouchEnabled(true)
	layer_:setTouchSwallowEnabled(false)
	layer_:addNodeEventListener(cc.NODE_TOUCH_EVENT,function(event)
			if event.name == "began" then
				return true
			elseif event.name == "moved" then
			elseif event.name == "ended" then
				layer_:removeSelf(true)
				self.isTiping_ = false
			end
		end)
	return layer_
end

function BattleManagerTriPeaks:autoTips()
	if GameManager:getInstance():supportTips() == false then
		return
	end
	local str_ = nil
	local strV1_ = nil
	local strV2_ = nil
	local strV3_ = nil
	local tipsList_ = self:analysisCollectCards_()
	if #tipsList_ > 0 then --操作牌提示
		local cardEnd_ = DealerController.getQueueEndCardVO(self.headsList_[BattleManagerTriPeaks.POS_CHANGE_1])
		if cardEnd_ then

			local value1_ = cardEnd_:getProperty("rank") - 1
			local value2_ = cardEnd_:getProperty("rank") + 1

			if value1_ < CardVO.RANK_ACE then
				value1_ = CardVO.RANK_KING
			elseif value1_ > CardVO.RANK_KING then
				value1_ = CardVO.RANK_ACE
			end

			if value2_ < CardVO.RANK_ACE then
				value2_ = CardVO.RANK_KING
			elseif value2_ > CardVO.RANK_KING then
				value2_ = CardVO.RANK_ACE
			end

			strV1_ = CardVO.RANK_NAME[value1_]
			strV2_ = CardVO.RANK_NAME[value2_]
			strV3_ = CardVO.RANK_NAME[cardEnd_:getProperty("rank")]

			str_ = "点击任意{value1}或者{value2}将它放置在{value3}上"--Localization.string("点击任意{value1}或者{value2}将它放置在{value3}上",{value1 = tostring(strV1_),value2 = tostring(strV2_),value3 = tostring(strV3_)})
		end
	elseif self.headsList_[BattleManagerTriPeaks.POS_CHANGE_2] then --切牌提示
		str_ = "切一张新牌"--Localization.string()
	end

	if not str_ then
		return
	end

	self:showHelpLabel(str_,strV1_,strV2_,strV3_)
end

function BattleManagerTriPeaks:updataHintLogic_()
	local openHint = GameManager:getUserData():getOpenHint()
	if openHint > 0 then
		self:openAutoTips_()
	else
		self:hideHelpLabel()
	end
end

function BattleManagerTriPeaks:openAutoTips_()
	self:closeAutoTips_()
	if self.isWinning_ then return end
	local openHint = GameManager:getUserData():getOpenHint()
	if openHint > 0 then
		self.schedulerHandle = self:performWithDelay(function ()
			self:autoTips()
		end,15)
	end
end

function BattleManagerTriPeaks:closeAutoTips_()
	if self.schedulerHandle then
		self:stopAction(self.schedulerHandle)
		self.schedulerHandle = nil
	end
end

function BattleManagerTriPeaks:hideHelpLabel()
	self:openAutoTips_()
	if not self.tipsLabel_ then
		return
	end
	self.tipsLabel_:removeSelf(true)
	self.tipsLabel_ = nil
end

function BattleManagerTriPeaks:showHelpLabel(str,v1,v2,v3)
	self:closeAutoTips_()
	if self.isWinning_ then return end
	if self.tipsLabel_ then
		-- self.tipsLabel_:setString(str)
		-- self:setLabelString(self.tipsLabel_,str)

		if v1 then
			self:setLabelString(self.tipsLabel_, str,{value1 = tostring(v1),value2 = tostring(v2),value3 = tostring(v3)})
		else
			self:setLabelString(self.tipsLabel_, str)
		end
		

		self.tipsLabel_.v1 = v1
		self.tipsLabel_.v2 = v2
		self.tipsLabel_.v3 = v3
		return
	end
	if not self.tipPos then
		return
	end
		
	local params = {
        text = str,
        size = 32,
        color = ccc3(255, 255, 0)
    }
    self.tipsLabel_ = ui.newTTFLabel(params)
    self.tipsLabel_:setOpacity(0)
    -- self.tipsLabel_:setPosition(ccp(self.tipPos:getPositionX(), self.tipPos:getPositionY()))
    self.tipPos:addChild(self.tipsLabel_)
    self.tipsLabel_.v1 = v1
	self.tipsLabel_.v2 = v2
	self.tipsLabel_.v3 = v3

	-- self:setLabelString(self.tipsLabel_,str)
	if v1 then
		self:setLabelString(self.tipsLabel_, str,{value1 = tostring(v1),value2 = tostring(v2),value3 = tostring(v3)})
	else
		self:setLabelString(self.tipsLabel_, str)
	end

    self.tipsLabel_:runAction(transition.sequence({
		CCFadeIn:create(0.1), --消失效果有问题（只能消失牌底，花色和数字无法消失）
		}))

end


function BattleManagerTriPeaks:showHelpMove( isRepeat )
	if GameManager:getInstance():supportTips() == false then
		return
	end
	if self.isTiping_ then
		return
	end
	
	self.tipsList_ = self:analysisCollectCards_()
	if #self.tipsList_ < 1 then
		if self.headsList_[BattleManagerTriPeaks.POS_CHANGE_2] then
			self.tipsList_ = {DealerController.getQueueEndCardVO(self.headsList_[BattleManagerTriPeaks.POS_CHANGE_2])}
		end
	end
	
	if #self.tipsList_ < 1 then
		return
	end


	local tipsLayer_ = self:createTipsLayer()
	function showTipAni( node, index )
		if not self.tipsList_[index] then
			if isRepeat then
				index = 1
				showTipAni( node, index )
			else
				node:removeSelf(true)
				self.isTiping_ = false
			end
			return
		end
		local sp_ = self.tipsList_[index]:getView()
		local from = ccp(sp_:getPositionX(), sp_:getPositionY())
		local to = ccp(self["pos"..BattleManagerTriPeaks.POS_CHANGE_1]:getPosition())
		AnimationDefine.tipAnimation(self.tipsList_[index],node,from,to,function()
			showTipAni(node, index + 1)
			end)
	end
	self:hideHelpLabel()
	showTipAni(tipsLayer_, 1)
end

function BattleManagerTriPeaks:judgeWin_()
	local win_ = true
	for i=BattleManagerTriPeaks.POS_BEGIN,BattleManagerTriPeaks.POS_PLAY_MAX do
		if self.headsList_[i] then
			win_ = false
			break
		end
	end
	return win_
end

function BattleManagerTriPeaks:analysisWin_()
	if self.isWinning_ then
		return
	end
	local win_ = self:judgeWin_()

	if win_ then
		self.isWinning_ = true
		self:pauseGame()
		self:uploadSeed()

		local sec = GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):getRunningTime()
		--计时模式下的奖励分数
		GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):carryOnScore(GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):getTriPeaksTimeEndScore())
		EventNoticeManager:getInstance():dispatchEvent({name = Notice.GAME_DATA_CHANGE})
		--提交统计数据
		local isWin_ = GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):getCacheData():getProperty("isWin")
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
		local isDailyChallenge = GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):isDailyChallenge()
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
		for i = CardVO.SUIT_CLUBS,CardVO.SUIT_SPADES do
			list[#list + 1] = {suit=i}
		end
		GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):cacheRecordData(heigh, data, radom_, list,isFirstWin_)
		
		GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):setEndAniStatus(BattleManagerTriPeaks.END_ANI_STUFF)
		self:showStuffAnimation()

        -- if DEBUG ~= 2 then
        	GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):cleanData()
        -- end
		GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):changeCacheData({gameState = UserCacheRecordVO.status_end, gameTime = sec, isWin = isWin_})
		EventNoticeManager:getInstance():dispatchEvent({name = Notice.GAME_STATUS_CHANGE})
	end

	return win_
end

function BattleManagerTriPeaks:analysisFail_()
	if self.isWinning_ then
		return false
	end
	if self:judgeWin_() then
		return false
	end
	if self.headsList_[BattleManagerTriPeaks.POS_CHANGE_2] then
		return false
	end
	
	for i=BattleManagerTriPeaks.POS_BEGIN,BattleManagerTriPeaks.POS_PLAY_MAX do
		if self.headsList_[i] 
			and self.headsList_[i]:getProperty("board") == CardVO.BOARD_FACE then
			local isCanCollect_ = self:judgeCardCanCollect(self.headsList_[i])
			if isCanCollect_ then
				return false
			end
		end
	end

	return true
end


function BattleManagerTriPeaks:showWinDialog( )
	local needCoin_ = false
	if GAME_MODE == GAME_MODE_COLLECTION then
		needCoin_ = true
	end
    local viewCtrl = WinViewCtrl.new(needCoin_)
    display.getRunningScene():addChild(viewCtrl:getView())
    GameManager:getUserData():addPraiseWinCount()
end

function BattleManagerTriPeaks:showStuffAnimation( )
	local list = GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):getProperty("stuffData") or {}
	local index = 1
	for i=1,#list do
		list[i].pos = ccp(self["pos"..BattleManagerTriPeaks.POS_CHANGE_1]:getPosition())
	end
	--洗牌动画的载体节点
	local node = display.newNode()
	node:setContentSize(self.card_table:getContentSize())
	node:setPosition(self:getPosition())
	node:setScale(self:getScale())
	display.getRunningScene():addChild(node)

	local radom = GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):getProperty("aniNum") or 1
	self:initSuccesAni_(list,node,radom)
end

function BattleManagerTriPeaks:initSuccesAni_(list,node,radom)
	--屏蔽触摸和按钮
    local touchNode = self:addTouchLayer_(display.getRunningScene(), ccc4(0, 0, 0, 0))

	--洗牌动画播放完毕之后的结算动画
	function endCallBack_( node )
		self.headsList_ = {}
		if GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):getEndAniStatus() == BattleManager.END_ANI_DIALOG then
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
                GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):setEndAniStatus(BattleManager.END_ANI_DIALOG)
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
		-- self:clearLight_()
		self.card_table:removeAllChildren()
	else
		self:performWithDelay(function ()
			-- self:clearLight_()
			self.card_table:removeAllChildren()
		end,0.02)
	end
end

function BattleManagerTriPeaks:saveRecord(name)
	if name == "newGame" then
		GameManager:getUserClassicData():addTriPeaksCount(1)
	elseif name == "win" then
		GameManager:getUserClassicData():addTriPeaksWinCount(1)
	elseif name == "record" then
		local high = false
		local step_ = GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):getCacheStepCount()
		local sec_ = GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):getRunningTime()

		local tripeaks_cacheData = GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):getCacheData()
        stepCount = tripeaks_cacheData:getProperty("move")
        step_ = stepCount

		GameManager:getUserClassicData():addTriPeaksFewestMove(step_)
		GameManager:getUserClassicData():addTriPeaksFewestTime(sec_)
		--普通模式
		local score_ = GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):getCacheData():getProperty("score")
		score_ = score_ + GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):getTimeScore()
		high = GameManager:getUserClassicData():addTriPeaksHighestScore(score_)
		--保存排行榜信息
		local timeTemp = os.time()
		local userClassicRankVO = UserClassicRankVO.new({score=score_, moves = step_, time = sec_, createdTimestamp = timeTemp})
		GameManager:getUserClassicData():saveRankData(userClassicRankVO,UserClassicRankVO.MODE_TRIPEAKS)

		local list = GameManager:getUserClassicData():getProperty("triPeaksRankList") or {}
		local totalScore = 0
		local rankMode = GameCenterDefine.getLeaderBoardId().triPeaks
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

--保存活局种子
function BattleManagerTriPeaks:uploadSeed()
	local cacheData = GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):getCacheData()
	local isDeal = cacheData:getProperty("isDeal")
	local isNewPlayer = cacheData:getProperty("isNewPlayer")
	-- printf("isDeal == [%s] / isNewPlayer == [%s]",tostring(isDeal),tostring(isNewPlayer))
	if isDeal > 0 or isNewPlayer >0 then
		--活局不用上传种子
		printf("不做胜利种子保存")
		return
	end
	local userDealSeedVO = UserDealSeedVO.new()
	local seed = GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):getCacheData():getProperty("seed") or ""
	local mode = UserCacheRecordVO.mode_tripeaks--GameManager:getUserGameCacheData(GameManager.MODETYPE_TRIPEAKS):getCacheData():getProperty("mode")
	userDealSeedVO:setProperty("mode", mode)
	userDealSeedVO:setProperty("seed", seed)

	local needUpload_ = GameManager:getUserSeedData():saveDealSeedByList({userDealSeedVO},UserCacheRecordVO.mode_tripeaks)
	if not needUpload_ then
		return
	end
	printf("种子上传")
	local listmode = {}
	local seedList = GameManager:getUserSeedData():getDealSeedByList(UserCacheRecordVO.mode_tripeaks) or {}
	for i=1,#seedList do
		listmode[#listmode+1] = seedList[i]:getProperty("seed")
	end
	local param = {}
	if #listmode > 0 then
		param.tripeaks = listmode
	end

	GameManager:getNetWork():saveSeed(param)
end

function BattleManagerTriPeaks:addTouchLayer_( parent, corlor )
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

function BattleManagerTriPeaks:playPartical_( headIndex, startIndex )
	-- if headIndex < BattleManagerTriPeaks.HEAD_COLLECT_1 or headIndex > BattleManagerTriPeaks.HEAD_COLLECT_MAX 
	-- 	or headIndex == startIndex then
	-- 	return
	-- end
	-- local node = self["column"..headIndex]
	-- if not node then
	-- 	return
	-- end
	-- local pos = ccp(0, 0)
	-- pos.x, pos.y = node:getPosition() --node:getContentSize().width/2, node:getContentSize().height/2
 --    local partical = CCParticleSystemQuad:create("animation/particle_shoupai.plist")
 --    self.card_table:addChild(partical, -1)
 --    partical:setPosition(pos)
 --    partical:runAction(transition.sequence({CCDelayTime:create(1.2),
 --    	CCCallFunc:create(function ( )
 --    		partical:removeSelf()
 --    	end)}))
end

function BattleManagerTriPeaks:palyCollectAudio( oldIndex,headIndex )
	if oldIndex > BattleManagerTriPeaks.POS_PLAY_MAX or headIndex ~= BattleManagerTriPeaks.POS_CHANGE_1 then
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
	if self.comboCount_ > 10 then
		self.comboCount_ = 10
	end

	GameManager:getAudioData():playAudio(common.effectSoundList["collect_score"..self.comboCount_],nil,nil,true)
	self.schedulerAudioHandle = self:performWithDelay(function ()
			self.schedulerAudioHandle = nil
			self.comboCount_ = 0
		end,3)

end

function BattleManagerTriPeaks:checkMoveNeedAddScore(startHeadIndex, endHeadIndex)
	local isFishdom = PackageConfigDefine.isSolitaireFishdom()
	if not isFishdom then
		return 0
	end
	if startHeadIndex <= BattleManagerTriPeaks.POS_PLAY_MAX and endHeadIndex == BattleManagerTriPeaks.POS_CHANGE_1 then
		return BattleManagerTriPeaks.COLLECT_VALUE
	elseif endHeadIndex <= BattleManagerTriPeaks.POS_PLAY_MAX and startHeadIndex == BattleManagerTriPeaks.POS_CHANGE_1 then
		return -BattleManagerTriPeaks.COLLECT_VALUE
	end

	return 0
end

function BattleManagerTriPeaks:playScoreAction(posBegin, posEnd, scoreNum)
	local isFishdom = PackageConfigDefine.isSolitaireFishdom()
	if not self.card_table or not isFishdom then
		return
	end
	common.scoreAction(self.card_table, posBegin, posEnd, scoreNum)
end

return BattleManagerTriPeaks