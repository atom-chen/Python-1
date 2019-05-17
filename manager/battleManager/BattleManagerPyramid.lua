--GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):getEndAniStatus()
-- Author: Huang Hai Long
-- Date: 2017-04-17 18:05:17
--
local BattleManagerPyramid = class("BattleManagerPyramid",function()
	return display.newNode()
end)

BattleManagerPyramid.POS_BEGIN = 1 --pos开始点
BattleManagerPyramid.POS_PLAY_MAX = 28 --玩牌区posMax
BattleManagerPyramid.POS_MAX = 30 --pos点数量
-- BattleManagerPyramid.BEGIN_BACK_POS = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18}--开局时，牌背朝上的位置
-- BattleManagerPyramid.BEGIN_FACE_POS = {19,20,21,22,23,24,25,26,27,28,29}--开局时，牌面朝上的位置
BattleManagerPyramid.POS_CHANGE_1 = 29 --切牌pos1 
BattleManagerPyramid.POS_CHANGE_2 = 30 --切牌pos2 

BattleManagerPyramid.POS_COLLECT_1 = 31 --收牌pos1 
BattleManagerPyramid.POS_COLLECT_2 = 32 --收牌pos2 

--pos子节点映射表
BattleManagerPyramid.POS_CHILDREN = {
	[1] = {2,3},
	[2] = {4,5},
	[3] = {5,6},
	[4] = {7,8},
	[5] = {8,9},
	[6] = {9,10},
	[7] = {11,12},
	[8] = {12,13},
	[9] = {13,14},
	[10] = {14,15},
	[11] = {16,17},
	[12] = {17,18},
	[13] = {18,19},
	[14] = {19,20},
	[15] = {20,21},
	[16] = {22,23},
	[17] = {23,24},
	[18] = {24,25},
	[19] = {25,26},
	[20] = {26,27},
	[21] = {27,28},
}

BattleManagerPyramid.ROW_CHILDREN = {
	[1] = {1},
	[2] = {2,3},
	[3] = {4,5,6},
	[4] = {7,8,9,10},
	[5] = {11,12,13,14,15},
	[6] = {16,17,18,19,20,21},
	[7] = {22,23,24,25,26,27,28}
}

BattleManagerPyramid.ROW_SCORE = {
	[1] = 10000,
	[2] = 5000,
	[3] = 3000,
	[4] = 2000,
	[5] = 1500,
	[6] = 1000,
	[7] = 500
}


BattleManagerPyramid.END_ANI_NONE = 0
BattleManagerPyramid.END_ANI_COLLECTING = 1--收集
BattleManagerPyramid.END_ANI_STUFF = 2--洗牌
BattleManagerPyramid.END_ANI_DIALOG = 3--结算窗
BattleManagerPyramid.END_ANI_END = 4--结束

function BattleManagerPyramid:ctor(delegate)
	GameManager:getAudioData():stopAllAudios()
	KMultiLanExtend.extend(self)
	self:initView_()

	self.changeOffsetX_ = self:isPortrait_() and 7 or 10

	self.headsList_ = {}

	self:setDelegate(delegate)
	-- self.flipCardRound = 0
	self.cardMoving_ = false
	self.comboCount_ = 0
	self.isWinning_ = false
	self.isTiping_ = false
	self:updataFlipCardRound(0) --翻牌的轮数
	--初始化牌组
	self:startGame(nil, true)
	self:setNodeEventEnabled(true)

	
end

function BattleManagerPyramid:updataFlipCardRound(value)
	self.flipCardRound = value or 0
	local roundLimit = GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):getCacheData():getPyramidRoundLimit()
	local reRound_ = roundLimit - 1 - self.flipCardRound
	local endAniStatus = GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):getEndAniStatus() or BattleManagerPyramid.END_ANI_NONE
	if endAniStatus == BattleManagerPyramid.END_ANI_STUFF 
		or endAniStatus == BattleManagerPyramid.END_ANI_DIALOG 
		or endAniStatus == BattleManagerPyramid.END_ANI_END then
		reRound_ = 0
	end

	if self.resetNode then
		self.resetNode:setVisible(reRound_ > 0)
	end
	if self.emptyNode then
		self.emptyNode:setVisible(reRound_ < 1)
	end

	if self.roundCount then
		self.roundCount:setString(tostring(reRound_))
	end
end

function BattleManagerPyramid:onEnter( )
	EventNoticeManager:getInstance():addEventListener(self,Notice.APP_ENTER_BACKGROUND,handler(self, self.gameEnterBackground_))
	-- EventNoticeManager:getInstance():addEventListener(self,Notice.USER_DATA_CHANGE,handler(self, self.leftModeChanged))
	EventNoticeManager:getInstance():addEventListener(self,Notice.USER_LANGUAGE_CHANGE,handler(self, self.setLocalization_))
    EventNoticeManager:getInstance():addEventListener(self,Notice.USER_CARD_CHANGE,handler(self, self.updataAllCards))
    
    EventNoticeManager:getInstance():addEventListener(self,Notice.USER_HINT_DATA_CHANGE,handler(self, self.updataHintLogic_))
    EventNoticeManager:getInstance():addEventListener(self,Notice.GAME_DATA_CHANGE,function ()
    	self:updataFlipCardRound(self.flipCardRound)
    end)

    
end

function BattleManagerPyramid:setLocalization_( )
	if self.btn_change then
		self:setBtnTitle(self.btn_change, "翻牌")
	end
end

function BattleManagerPyramid:onExit( )
	EventNoticeManager:getInstance():removeEventListenerForHandle(self)
end

function BattleManagerPyramid:getHeadsList()
	return self.headsList_ or {}
end

function BattleManagerPyramid:updataAllCards(event)
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

function BattleManagerPyramid:gameEnterBackground_( )
	local sec = GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):getRunningTime()
	GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):changeCacheData({gameTime = sec})

	GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):saveCache()
	GameManager:getUserChallengeData():saveCache()
end

function BattleManagerPyramid:starNewGame( seed, resetAll )
	GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):cleanData()
	-- self:clearLight_()
	self:stopAllActions()
	self:hideHelpLabel()
	self.card_table:removeAllChildren()
	self.headsList_ = {}
	
	-- self.flipCardRound = 0
	self.cardMoving_ = false
	self.comboCount_ = 0
	self.isWinning_ = false
	self.isTiping_ = false

	GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):cleanRecordData()
	--初始化牌组
	self:startGame(seed, resetAll)

	self:updataFlipCardRound(0)
end

function BattleManagerPyramid:initView_( )
	--计算视图大小
	local isPortrait = self:isPortrait_()
	local displaySize = CCSizeMake(display.width, display.height)
	if isPortrait then
		displaySize = CCSizeMake(USER_SCREEN_WIDTH, USER_SCREEN_HEIGHT)
	else
		displaySize = CCSizeMake(USER_SCREEN_HEIGHT, USER_SCREEN_WIDTH)
	end
	self:setContentSize(displaySize)

	local ccbName = isPortrait and "battlePyramidView" or "battlePyramidView_landscape"
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

	-- printf("height[%s] /// USER_SCREEN_HEIGHT[%s]",tostring(display.height),tostring(USER_SCREEN_HEIGHT))
	if isPortrait and display.height > USER_SCREEN_HEIGHT then
		local offy_ = (display.height - USER_SCREEN_HEIGHT)/2

		for i=BattleManagerPyramid.POS_CHANGE_1,BattleManagerPyramid.POS_CHANGE_2 do
			if self["pos"..i] then
				self["pos"..i]:setPositionY(self["pos"..i]:getPositionY() - offy_/2)
			end
		end

		for i=BattleManagerPyramid.POS_COLLECT_1,BattleManagerPyramid.POS_COLLECT_2 do
			if self["pos"..i] then
				self["pos"..i]:setPositionY(self["pos"..i]:getPositionY() - 2*offy_)
			end
		end
		
		if self.cardPos then
			self.cardPos:setPositionY(self.cardPos:getPositionY() - 2*offy_)
		end

		if self.btn_change then
			self.btn_change:setPositionY(self.btn_change:getPositionY() - offy_)
		end
		if self.arrow_sp then
			self.arrow_sp:setPositionY(self.arrow_sp:getPositionY() - offy_/2)
		end
	end

end

--设置卡槽以及图标主题
function BattleManagerPyramid:setCardsSlot(style)

end

function BattleManagerPyramid:startGame( seed, resetAll )
	local endAniStatus = GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):getEndAniStatus() or BattleManagerPyramid.END_ANI_NONE
	local list = GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):getCacheCardList_()
	if table.nums(list) <= 0 then
		--没有牌面信息需要判断是否播放结算动画
		if endAniStatus == BattleManagerPyramid.END_ANI_STUFF then
			self:showStuffAnimation()
		elseif endAniStatus == BattleManagerPyramid.END_ANI_DIALOG then
			-- self:showWinDialog(true)--胜利弹窗在切屏之后会自动弹出了，这里不处理了
		elseif endAniStatus == BattleManagerPyramid.END_ANI_END then
			--todo
		else
			GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):resetCacheData(resetAll)
			self:initCard_(seed)
			--发牌
			self:startDealCard(true)
		end
		self:updateBtnStatus_()
		self:updataFlipCardRound(0)
	else
		local data = GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):getCacheStepByLast()
		if data then
			self:updataFlipCardRound(data:getProperty("flipCardRound"))
			-- self.flipCardRound = data:getProperty("flipCardRound")
		else
			self:updataFlipCardRound(0)
			-- self.flipCardRound = 0
		end
		self:runReplay(list)
		--发牌
		self:startDealCard()
	end
	self:openAutoTips_()
end

function BattleManagerPyramid:optimizeCard_( list )
	local keyList_ = {}
	local handList_ = {}
	for i=#list,1,-1 do
		local rank_ = list[i].rank_
		if not keyList_[rank_] and rank_ ~= CardVO.RANK_KING then
			keyList_[rank_] = "true"
			handList_[#handList_ + 1] = list[i]
			table.remove(list, i)
		end
	end
	for i=#handList_,1,-1 do
		list[#list + 1] = handList_[i]
	end
end

function BattleManagerPyramid:initCard_( _seed )
	--获取牌组
	local list = DealerController.initCards()
	local seed_ = ""
	local isNewPlayer = false
	local roundMode = GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):getCacheData():getProperty("roundMode") or 1

	--如果不是重玩本局
	if not _seed then
		--判断是否是活局
		local userDM = GameManager:getUserData()
		local isSolvedMode = userDM:isSolvedMode() --是否是活局
		if isSolvedMode then
			_seed = userDM:getDealSeed(4+roundMode)
		else
			isNewPlayer = GameManager:getUserClassicData():isNewPlayer()--就算是随机局也给新玩家使用活局种子
			if isNewPlayer then
				local isDeal = false
				_seed,isDeal = userDM:getDealSeed(4+roundMode)
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
	-- for i=1,#list do
	-- 	printf("----[%d]--%s",i,tostring(list[i]:getCardName()))
	-- end
	self:optimizeCard_( list )
	-- for i=1,#list do
	-- 	printf("-optimize---[%d]--%s",i,tostring(list[i]:getCardName()))
	-- end
	GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):changeCacheData({seed = seed_, gameState = UserCacheRecordVO.status_playing, isNewPlayer = ((isNewPlayer and 1) or 0)})
	EventNoticeManager:getInstance():dispatchEvent({name = Notice.GAME_STATUS_CHANGE})
	local cacheList = {}

	for i=BattleManagerPyramid.POS_BEGIN,BattleManagerPyramid.POS_PLAY_MAX do
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
				self.headsList_[BattleManagerPyramid.POS_CHANGE_2] = currCard_
			end
			currCard_:setProperty("headIndex", BattleManagerPyramid.POS_CHANGE_2)
			cacheList[#cacheList+1] = currCard_
		end
	end

	GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):changeCacheStatusByCardList(cacheList)
end

function BattleManagerPyramid:runReplay(list)
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

function BattleManagerPyramid:isPortrait_( )
	return CONFIG_SCREEN_ORIENTATION == "portrait"
end

--左手模式变更了
function BattleManagerPyramid:leftModeChanged( )
	
end

function BattleManagerPyramid:reloadCardsPosBy(index)
	local card = self.headsList_[index]
	local len_ = DealerController.getQueueLenByHead(self.headsList_[index])
	local offset_pos = ccp(0, 0)
	-- if index == BattleManagerPyramid.POS_CHANGE_2 then
	-- 	offset_pos = ccp(-self.changeOffsetX_*(len_-1), 0)
	-- end
	
	while card do
		local sprite = card:getView()
		-- if index == BattleManagerPyramid.POS_CHANGE_2 then
		-- 	offset_pos = ccp(offset_pos.x+self.changeOffsetX_, offset_pos.y)
		-- end
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

	-- if index == BattleManagerPyramid.POS_CHANGE_2 then
	-- 	self:reOrderZOrder_( self.headsList_[index], 0 ,true)
	-- end
end

function BattleManagerPyramid:reloadCardsPos( )
	--牌桌上的卡牌
	for i=BattleManagerPyramid.POS_BEGIN,BattleManagerPyramid.POS_COLLECT_2 do
		self:reloadCardsPosBy(i)
	end
end

function BattleManagerPyramid:reOrderZOrder_( cardVO, zOrder )
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

function BattleManagerPyramid:isFindInList( list,value )
	for k,v in pairs(list) do
		if value == v then
			return k
		end
	end
	return nil
end

function BattleManagerPyramid:startDealCard( animation )
	self:stopAllActions()
	self.playing = false
	--此时才开始创建卡牌的形象
	if animation then
		self:startMoving()
		local zOrder = 52

		for i=BattleManagerPyramid.POS_BEGIN,BattleManagerPyramid.POS_MAX do
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

			if headIndex > BattleManagerPyramid.POS_MAX then
				self.headsList_[BattleManagerPyramid.POS_CHANGE_2] = DealerController.reverseQueueByCardVO(self.headsList_[BattleManagerPyramid.POS_CHANGE_2])
				
				local list_ = DealerController.getListByHead(self.headsList_[BattleManagerPyramid.POS_CHANGE_2])
				GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):changeCacheStatusByCardList(list_)
				-- local status_ = self.headsList_[BattleManagerPyramid.POS_CHANGE_2]
				-- while status_ do
				-- 	GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):changeCacheStatusByCardVO(status_)
				-- 	status_ = status_:getNextCard()
				-- end

				-- self:testPrintLink(BattleManagerPyramid.POS_CHANGE_2)
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
				-- if headIndex == BattleManagerPyramid.POS_CHANGE_2 then
				-- 	local len_ = DealerController.getQueueLenByBottom(card)
				-- 	mX_ = mX_ - self.changeOffsetX_*(len_-1)
				-- 	card:getView():setPosition(ccp(self["pos"..headIndex]:getPositionX(), self["pos"..headIndex]:getPositionY()))
				-- 	durationM_ = 0.05
				-- end
				local move = CCMoveTo:create(durationM_, ccp(mX_,mY_))--count*self:getCardOffsetY_()))
				local delay = CCDelayTime:create(0.2)
				local flip = CCCallFunc:create(function ()
					card:changeBoardTo(CardVO.BOARD_FACE)
				end)
				local call = CCCallFunc:create(function ()
					GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):changeCacheStatusByCardVO(card)
				end)
				local callzOrder = CCCallFunc:create(function ()
					if headIndex ~= BattleManagerPyramid.POS_CHANGE_2 then
						card:getView():setZOrder(0)
					end
				end)

				card:getView():runAction(transition.sequence({move,callzOrder}))
				if headIndex <= BattleManagerPyramid.POS_PLAY_MAX then
					card:getView():runAction(transition.sequence({delay,flip,CCDelayTime:create(0.02),call}))					
				end

				if headIndex == BattleManagerPyramid.POS_CHANGE_2 then
					showAni(headIndex, card:getNextCard())
				else
					self:performWithDelay(function ()
						showAni(headIndex, card:getNextCard())
					end,0.03)
				end
				
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

	--test
	-- for i=1,BattleManagerPyramid.POS_COLLECT_2 do
	-- 	if self.headsList_[i] then
	-- 		self:testPrintLink(i)
	-- 	end
	-- end
	--

	for i=BattleManagerPyramid.POS_BEGIN,BattleManagerPyramid.POS_COLLECT_2 do
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

function BattleManagerPyramid:cleanTouchData_( )
	self.pre_x = 0
	self.pre_y = 0
	self.card_pre_x = {}
	self.card_pre_y = {}
	-- self.card_pre_x = 0
	-- self.card_pre_y = 0
	self.click_ = true
	self.selectCard = nil
	self.selectIndex_ = -1
	self.noChildrenCardList_ = nil
end

function BattleManagerPyramid:getNoChildrenCardList_()
	local list_ = {}

	for i = BattleManagerPyramid.POS_PLAY_MAX , BattleManagerPyramid.POS_BEGIN , -1 do
		local cardVO_ = self.headsList_[i]
		if cardVO_ then
			if not self:judgeHasChildren_(cardVO_.headIndex_) then
				list_[#list_ + 1] = cardVO_
			end
		end
	end
	for i=BattleManagerPyramid.POS_CHANGE_2,BattleManagerPyramid.POS_CHANGE_1 , -1 do
		local cardVO_ = DealerController.getQueueEndCardVO(self.headsList_[i])
		if cardVO_ then
			if not self:judgeHasChildren_(cardVO_.headIndex_) then
				list_[#list_ + 1] = cardVO_
			end
		end
	end
	return list_
end

function BattleManagerPyramid:judgeHasChildren_(index)
	local children_ = DealerController.pyramidGetChildrenByPos(index)
	for i=1,#children_ do
		if self.headsList_[children_[i]] then
			return true
		end
	end
	return false
end

function BattleManagerPyramid:cardTouchBegan( cardSp, x, y )
	self:resumeGame(true)
	-- local headIndex = cardSp.data_.headIndex_
	-- if not (headIndex >= BattleManagerPyramid.POS_BEGIN and headIndex <= BattleManagerPyramid.POS_PLAY_MAX) and headIndex ~= BattleManagerPyramid.POS_CHANGE_2 then
	-- 	return false
	-- end
	-- print("--------cardTouchBegan------")
	
	if (cardSp.data_.headIndex_ == BattleManagerPyramid.POS_COLLECT_1) or (cardSp.data_.headIndex_ == BattleManagerPyramid.POS_COLLECT_2) then
		return false -- 防止 消牌 飞牌时时点击
	end
	if self:judgeHasChildren_(cardSp.data_.headIndex_) then -- 只判断玩牌区的[0--21]
		return false
	end
	if cardSp.data_:getNextCard() then
		return false
	end

	--card 无子节点 -- 可拖动
	self:cleanTouchData_()
	self.pre_x = x
	self.pre_y = y
	local card = cardSp.data_
	self:reOrderZOrder_(card, 53)

	local cardSp = card:getView()
	self.card_pre_x[card] = cardSp:getPositionX()
	self.card_pre_y[card] = cardSp:getPositionY()

	return true
end

function BattleManagerPyramid:cardTouchMoving( cardSp, x, y )
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
	-- while card and not tolua.isnull(card:getView()) do
	-- 	if math.abs(x - self.pre_x)/self:getScaleX() > 20 or math.abs(y - self.pre_y)/self:getScaleY() > 20 then
	-- 		self.click_ = false
	-- 	end
	-- 	local cardSp = card:getView()
	-- 	if self.card_pre_x[card] ~= nil and self.card_pre_y[card] ~= nil then
	-- 		cardSp:setPosition(ccp(self.card_pre_x[card] + (x - self.pre_x)/self:getScaleX(),
	-- 			self.card_pre_y[card] + (y - self.pre_y)/self:getScaleY()))
	-- 	end
	-- 	card = card:getNextCard()
	-- end
	if card and not tolua.isnull(card:getView()) then
		if math.abs(x - self.pre_x)/self:getScaleX() > 20 or math.abs(y - self.pre_y)/self:getScaleY() > 20 then
			self.click_ = false -- 移动距离大时为click_=false
		end
		local cardSp = card:getView()
		if self.card_pre_x[card] ~= nil and self.card_pre_y[card] ~= nil then
			cardSp:setPosition(ccp(self.card_pre_x[card] + (x - self.pre_x)/self:getScaleX(),
				self.card_pre_y[card] + (y - self.pre_y)/self:getScaleY()))
		end
	end

	--拖动
	if self.click_ then
		return 
	end
	if not self.noChildrenCardList_  then
		self.noChildrenCardList_ = self:getNoChildrenCardList_() -- 无孩子list
	end
	-- if not self.selectIndex_ then
	-- 	self.selectIndex_ = -1
	-- end
	local crossCards = {} 
	local crossArea = {}
	local cardAreaMax = 0
	local previousIndex = self.selectIndex_
	local previouscard = self.selectCard
	for i=1,#self.noChildrenCardList_ do -- 遍历noChildrenCards
		if self.noChildrenCardList_[i].headIndex_ ~= card.headIndex_ then -- 不是拖动的这张
			local area_ = common.judgeNodeInNode(cardSp:getAreaNode(),self.noChildrenCardList_[i]:getView():getAreaNode())
			if area_ > 0 then -- 相交
				crossArea[#crossArea+1] = area_ --只能相交两个
				crossCards[#crossCards+1] = self.noChildrenCardList_[i]
				if #crossArea >= 3 then
					break
				end
			end
		end
	end
	function changeIndexLight(cardRemove,cardAdd)
		if cardRemove and cardRemove:getView() and cardRemove:getView():getChildByTag(1) then
			cardRemove:getView():getChildByTag(1):removeSelf(true)
		end
		if cardAdd and cardAdd:getView() and not cardAdd:getView():getChildByTag(1) then
			self:addLight_(cardAdd:getView(), false, true)
		end
	end
	if #crossCards == 0 then
		changeIndexLight(self.selectCard)
		self.selectIndex_ = -1
		self.selectCard = nil
	end
	for i=1,#crossCards do
		if crossArea[i] > cardAreaMax then
			cardAreaMax = crossArea[i]
			self.selectCard = crossCards[i]
			self.selectIndex_ = self.selectCard.headIndex_
		end
		if i == #crossCards then -- 比到最后
			if previousIndex ~= self.selectIndex_ then -- cardindex hua le
				changeIndexLight(previouscard,self.selectCard)
			end
		end
	end
end

-- function BattleManagerPyramid:linkCollectCard_( card , index )
-- 	local cardBefore_ = DealerController.getQueueEndCardVO(self.headsList_[index])
-- 	self:linkTwoCard(cardBefore_, card, index)

-- end

function BattleManagerPyramid:cardTouchEnd( cardSp, x, y )
	local startHeadIndex = cardSp.data_.headIndex_
	if not self.click_ then -- 拖动
		if not self.selectCard then
			self:MoveToPreviousPos(cardSp.data_:getView())
			return
		end
		if self.selectCard and self.selectCard:getView() and self.selectCard:getView():getChildByTag(1) then
			self.selectCard:getView():getChildByTag(1):removeSelf(true)
		end
		if DealerController.pyramidCanCollect(cardSp.data_,self.selectCard) then --CanCollect
			self:collectLinkTwoCard_(cardSp.data_, self.selectCard)
			self:collectMoveCards( cardSp.data_,startHeadIndex, self.selectCard,self.selectCard.headIndex_ )
		else -- 不能收集
			self.selectCard:getView():shake(true)
			GameManager:getAudioData():playAudio(common.effectSoundList.shake_card)
			self:MoveToPreviousPos(cardSp.data_:getView())
			return
		end
	else -- 点击
		if startHeadIndex == BattleManagerPyramid.POS_COLLECT_1 or startHeadIndex == BattleManagerPyramid.POS_COLLECT_2 then
			return
		end
		local startHeadIndex2 = 0

		local isClick_ = common.judgeTouchInNode(ccp(x, y),cardSp)

		local isCanCollect_ = false
		local cardBefore_ = nil
		
		if isClick_ then
			isCanCollect_,cardBefore_ = self:judgeCardCanCollect(cardSp.data_)
		else
			-- cardSp:shake(true)
			GameManager:getAudioData():playAudio(common.effectSoundList.shake_card)
		end

		if isCanCollect_ then
			-- print("-----cardTouchEnd-----")
			-- self:linkTwoCard(cardBefore_, cardSp.data_, BattleManagerPyramid.POS_CHANGE_1)
			-- self:moveCards(cardSp.data_, startHeadIndex)
			if cardBefore_ then
				startHeadIndex2 = cardBefore_.headIndex_
			end
			self:collectLinkTwoCard_(cardSp.data_, cardBefore_)
			self:collectMoveCards( cardSp.data_,startHeadIndex, cardBefore_,startHeadIndex2 )
			
			-- self:linkCollectCard_( cardSp.data_ , BattleManagerPyramid.POS_COLLECT_1 )
			-- if cardBefore_ then
			-- 	self:linkCollectCard_( cardBefore_ , BattleManagerPyramid.POS_COLLECT_2 )
			-- end
		else
			self:MoveToPreviousPos(cardSp)
			cardSp:shake(true)
			GameManager:getAudioData():playAudio(common.effectSoundList.shake_card)
			-- if self:analysisFail_() then
			-- 	GameManager:getInstance():popNoWayAlert(false)
			-- end
		end
		
	end
	self:cleanTouchData_()
end

function BattleManagerPyramid:analysisCollectCards_(ignoreChangesPos)
	local list_ = self:getNoChildrenCardList_()
	local result_ = {}
	for i=1,#list_ do
		local isCanCollect_ = self:judgeCardCanCollect( list_[i] , ignoreChangesPos)
		if isCanCollect_ then
			result_[#result_ + 1] = list_[i]
		end
	end
	return result_
end


function BattleManagerPyramid:judgeCardCanCollect( card,ignoreChangesPos )
	--判断是否是K
	local result_ = DealerController.pyramidCanCollect(card,nil)
	if result_ then
		return result_,nil
	end

	local list_ = self:getNoChildrenCardList_()
	if ignoreChangesPos then -- 优化后:change1 change2 匹配时不返回
		for i = 1, #list_ do
			result_ = DealerController.pyramidCanCollect(card,list_[i])
			if result_ then -- 有匹配的,在判断card1 card2 是否都是changePos
				if (card:getProperty("headIndex") + list_[i]:getProperty("headIndex")) ~= BattleManagerPyramid.POS_CHANGE_1+BattleManagerPyramid.POS_CHANGE_2 then
					return result_,list_[i]
				end
			end
		end
	else -- 优化前:只要有匹配就返回
		for i = 1, #list_ do
			result_ = DealerController.pyramidCanCollect(card,list_[i])
			if result_ then
				return result_,list_[i]
			end
		end
	end
	return false,nil
end
function BattleManagerPyramid:MoveToPreviousPos( node )
	local headIndex = node.data_.headIndex_
	local perviousPos = ccp(self["pos".. headIndex]:getPositionX(), self["pos".. headIndex]:getPositionY())

	local action1 = CCCallFunc:create(function() node:setTouchEnabled(false) end)
	local action2 = CCEaseSineInOut:create(CCMoveTo:create(0.2, perviousPos))
	local action3 = CCCallFunc:create(function() node:setTouchEnabled(true) end)
	node:runAction(transition.sequence({action1,action2,action3}))
	self:performWithDelay(function (  )
		node:setTouchEnabled(true)
	end, 0.2)
end

function BattleManagerPyramid:judgeFilpCards()
	local changeList_ = {}

	for i=BattleManagerPyramid.POS_BEGIN,BattleManagerPyramid.POS_PLAY_MAX do
		if self.headsList_[i] then
			if self.headsList_[i]:getProperty("board") == CardVO.BOARD_BACK then
				self.headsList_[i]:changeBoardTo(CardVO.BOARD_FACE)
				changeList_[#changeList_ + 1] = self.headsList_[i]
			end
		end
	end

	for i=BattleManagerPyramid.POS_CHANGE_1,BattleManagerPyramid.POS_CHANGE_2 do
		if self.headsList_[i] then
			local list_ = DealerController.getListByHead(self.headsList_[i])
			local len_ = #list_
			for j=1,len_ do
				if i == BattleManagerPyramid.POS_CHANGE_2 then
					if j == len_ then
						if list_[j]:getProperty("board") == CardVO.BOARD_BACK then
							list_[j]:changeBoardTo(CardVO.BOARD_FACE)
							changeList_[#changeList_ + 1] = list_[j]
						end
					else
						if list_[j]:getProperty("board") == CardVO.BOARD_FACE then
							list_[j]:changeBoardTo(CardVO.BOARD_BACK)
							changeList_[#changeList_ + 1] = list_[j]
						end
					end
				elseif i == BattleManagerPyramid.POS_CHANGE_1 then
					if list_[j]:getProperty("board") == CardVO.BOARD_BACK then
						list_[j]:changeBoardTo(CardVO.BOARD_FACE)
						changeList_[#changeList_ + 1] = list_[j]
					end
				end
			end
		end
	end

	if #changeList_ > 0 then
		GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):changeCacheStatusByCardList(changeList_)
	end
	
end

function BattleManagerPyramid:collectMoveCardsStep2( card,startHeadIndex,collectIndex,endCall )
	card:getView():setScale(1)
	card:getView():setRotation(0)
	card:getView():setZOrder(53)
	card:getView():stopAllActions()

	local beginPos = ccp(card:getView():getPositionX(), card:getView():getPositionY())
	local endPos = ccp(self["pos"..collectIndex]:getPositionX(), self["pos"..collectIndex]:getPositionY())

	local score = self:checkMoveNeedAddScore(startHeadIndex, collectIndex)
	self:playScoreAction(beginPos, beginPos, score)
	
	local direction =  (collectIndex == BattleManagerPyramid.POS_COLLECT_1 and -1) or 1
	AnimationDefine.parabolaAnimation(card:getView(),beginPos,endPos,function ( )
		-- endCall()
		if endCall then
			endCall()
		end
		
	end,function()
		-- soundCall()
	end,direction,true)
end

function BattleManagerPyramid:collectMoveCards( card1,startHeadIndex1, card2,startHeadIndex2 )
	if card1 and card2 then
		local pos_ = ccp(card2:getView():getPositionX(),card2:getView():getPositionY())
		local moveTo = CCEaseSineInOut:create(CCMoveTo:create(0.15, pos_))

		local callsound = CCCallFunc:create(function ( )
			self:palyCollectAudio( startHeadIndex1,startHeadIndex2 )
		end)
		local delay = CCDelayTime:create(0.1)
		local call = CCCallFunc:create(function ( )
			self:collectMoveCardsStep2( card1,startHeadIndex1,BattleManagerPyramid.POS_COLLECT_1 )
			self:collectMoveCardsStep2( card2,startHeadIndex2,BattleManagerPyramid.POS_COLLECT_2 )
			self:endMoving(startHeadIndex1)
		end)
		card1:getView():setScale(1)
		card1:getView():setRotation(0)
		card1:getView():setZOrder(53)
		card1:getView():stopAllActions()

		self:startMoving()
		card1:getView():runAction(transition.sequence({moveTo,callsound, delay, call}))
		self:hideHelpLabel()
		return

	elseif card1 then
		self:palyCollectAudio( startHeadIndex1,startHeadIndex2 )
		self:collectMoveCardsStep2( card1,startHeadIndex1,BattleManagerPyramid.POS_COLLECT_1 )
		self:endMoving(startHeadIndex1)
		self:hideHelpLabel()
	elseif card2 then
		self:palyCollectAudio( startHeadIndex1,startHeadIndex2 )
		self:collectMoveCardsStep2( card2,startHeadIndex2,BattleManagerPyramid.POS_COLLECT_2 )
		self:endMoving(startHeadIndex2)
		self:hideHelpLabel()
	end
end

function BattleManagerPyramid:moveCards( card, startHeadIndex )
	-- printf("card -- [%s]  // startHeadIndex -- [%s]",tostring(card),tostring(startHeadIndex))
	if not card then
		return
	end

	local headIndex = card.headIndex_
	local pos = ccp(0, 0)
	pos.x, pos.y = self["pos"..headIndex]:getPosition()

	if headIndex and headIndex <= BattleManagerPyramid.POS_PLAY_MAX then
		self:judgeFilpCards()
	end

	function soundCall()
		self:palyCollectAudio( startHeadIndex,headIndex )
	end

	function endCall()
		self:endMoving(startHeadIndex)
		if startHeadIndex == BattleManagerPyramid.POS_CHANGE_2 
			or headIndex == BattleManagerPyramid.POS_CHANGE_2 then
			self:reloadCardsPosBy(BattleManagerPyramid.POS_CHANGE_2)
		end
		-- self:playPartical_(headIndex, startHeadIndex)
		local score = self:checkMoveNeedAddScore(startHeadIndex, headIndex)
		self:playScoreAction(pos, pos, score)
	end

	-- local isCollecte_ = false
	-- if startHeadIndex >= BattleManagerPyramid.POS_BEGIN 
	-- 	and startHeadIndex <= BattleManagerPyramid.POS_PLAY_MAX 
	-- 	and headIndex == BattleManagerPyramid.POS_CHANGE_1 then
	-- 	isCollecte_ = true
	-- end

	while card and not tolua.isnull(card:getView()) do
		self:startMoving()

		card:getView():setScale(1)
		card:getView():setRotation(0)
		card:getView():setZOrder(53)
		card:getView():stopAllActions()

		-- printf("-------moveCards---->1 [%s][%s][%s]",tostring(pos.x),tostring(pos.y),tostring(card:getCardName()))
		
		local moveTo = CCEaseSineInOut:create(CCMoveTo:create(0.15, pos))
		local call = CCCallFunc:create(function ( )
			endCall()
		end)
		
		if card:getNextCard() then
			card:getView():runAction(moveTo)
		else
			card:getView():runAction(transition.sequence({moveTo, call}))
		end
		
		card = card:getNextCard()
	end

	-- if headIndex == BattleManagerPyramid.POS_CHANGE_2 then
	-- 	self:reOrderZOrder_( self.headsList_[headIndex], 0 ,true)
	-- else
	-- 	self:reOrderZOrder_(self.headsList_[headIndex])
	-- end
	self:hideHelpLabel()
end

function BattleManagerPyramid:cardTouchCancel( cardSp, x, y )
	self:cardTouchEnd(cardSp, x, y)
end


BattleManagerPyramid.COLLECT_VALUE = 50 --收一张牌
-- BattleManagerPyramid.MOVE_VALUE = -1 --走一步
-- BattleManagerPyramid.REVOKE_VALUE = -1 --撤销一步

function BattleManagerPyramid:calculateScore_(card_before, card_next, headIndex )
	local score = 0
	if card_next and (headIndex == BattleManagerPyramid.POS_COLLECT_1 or headIndex == BattleManagerPyramid.POS_COLLECT_2) then
		--收牌
		score = score + BattleManagerPyramid.COLLECT_VALUE
	end

	return score
end

function BattleManagerPyramid:testPrintLink(index)
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

-- BattleManagerPyramid.ROW_CHILDREN = {
-- 	[1] = {1},
-- 	[2] = {2,3},
-- 	[3] = {4,5,6},
-- 	[4] = {7,8,9,10},
-- 	[5] = {11,12,13,14,15},
-- 	[6] = {16,17,18,19,20,21},
-- 	[7] = {22,23,24,25,26,27,28}
-- }

-- BattleManagerPyramid.ROW_SCORE = {
-- 	[1] = 10000,
-- 	[2] = 5000,
-- 	[3] = 3000,
-- 	[4] = 2000,
-- 	[5] = 1500,
-- 	[6] = 1000,
-- 	[7] = 500
-- }

function BattleManagerPyramid:getRow_(headIndex)
	for i=1,#BattleManagerPyramid.ROW_CHILDREN do
		local list_ = BattleManagerPyramid.ROW_CHILDREN[i]
		for j=1,#list_ do
			if list_[j] == headIndex then
				return i
			end
		end
	end
end

function BattleManagerPyramid:judgeRowAllClear_(card1,oldIndex1, card2,oldIndex2)
	local row1 = nil
	local row2 = nil
	if card1 then
		row1 = self:getRow_(oldIndex1)
	end
	if card2 then
		row2 = self:getRow_(oldIndex2)
	end
	local row_ = nil
	if row1 then
		row_ = row1
	end
	if not row_ or (row2 and row2 > row_) then
		row_ = row2
	end
	if not row_ then
		return
	end
	local list_ = BattleManagerPyramid.ROW_CHILDREN[row_]
	if not list_ then
		return
	end
	local isClear = true
	for i=1,#list_ do
		if self.headsList_[list_[i]] then
			isClear = false
			break
		end
	end
	if isClear then
		return row_
	end
end

function BattleManagerPyramid:createRowClearLayer()
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
			end
		end)
	return layer_
end

function BattleManagerPyramid:clearRowClearLayer_()
	if self.rowClearLayer_ then
		self.rowClearLayer_:removeSelf(true)
		self.rowClearLayer_ = nil
	end
end

function BattleManagerPyramid:playRowClearAni_(row)
	GameManager:getAudioData():playAudio(common.effectSoundList.crownLight2)
	local posList_ = BattleManagerPyramid.ROW_CHILDREN[row]
	if not posList_ then
		return
	end
	if not posList_[1] then
		return
	end
	local posNode_ = self["pos"..posList_[1]]
	if not posNode_ then
		return
	end
	local pos_ = ccp(self.card_table:getContentSize().width/2,posNode_:getPositionY())
	self:clearRowClearLayer_()
	self.rowClearLayer_ = self:createRowClearLayer()
	
	AnimationDefine.playRowClearAnimation(self.rowClearLayer_,pos_,tostring(row),function()
			self:clearRowClearLayer_()
			if self.isLocalWin_ then
				self:showStuffAnimation()
				self.isLocalWin_ = false
			end
		end)
end

function BattleManagerPyramid:collectLinkTwoCard_(card1, card2, notRecordStep )
	local userCacheStepVO = UserCacheStepVO.new()
	local score = self:calculateScore_(nil, card1, BattleManagerPyramid.POS_COLLECT_1)
	GameManager:getAudioData():playAudio(common.effectSoundList.success)
	if card1 then
		userCacheStepVO:setProperty("stepStart", card1:getProperty("headIndex"))
		if not card1:getBeforeCard() then
			--将原有的头置空
			self.headsList_[card1:getProperty("headIndex")] = nil
		end
		card1:setProperty("headIndex", BattleManagerPyramid.POS_COLLECT_1)

		local before_ = DealerController.getQueueEndCardVO(self.headsList_[BattleManagerPyramid.POS_COLLECT_1])
		DealerController.linkTwoCard(before_, card1)

		if not card1:getBeforeCard() then
			--重置头
			self.headsList_[card1:getProperty("headIndex")] = card1
		end

		--保存牌面信息
		GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):changeCacheStatusByCardVO(card1)

		userCacheStepVO:setProperty("stepEnd", BattleManagerPyramid.POS_COLLECT_1)
	end
	
	if card2 then
		userCacheStepVO:setProperty("stepStart2", card2:getProperty("headIndex"))
		if not card2:getBeforeCard() then
			--将原有的头置空
			self.headsList_[card2:getProperty("headIndex")] = nil
		end

		card2:setProperty("headIndex", BattleManagerPyramid.POS_COLLECT_2)

		local before_ = DealerController.getQueueEndCardVO(self.headsList_[BattleManagerPyramid.POS_COLLECT_2])
		DealerController.linkTwoCard(before_, card2)

		if not card2:getBeforeCard() then
			--重置头
			self.headsList_[card2:getProperty("headIndex")] = card2
		end

		--保存牌面信息
		GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):changeCacheStatusByCardVO(card2)

		userCacheStepVO:setProperty("stepEnd2", BattleManagerPyramid.POS_COLLECT_2)
	end
	
	local clearRow_ = self:judgeRowAllClear_(card1,userCacheStepVO:getProperty("stepStart"), card2,userCacheStepVO:getProperty("stepStart2"))
	if clearRow_ then
		score = score + (BattleManagerPyramid.ROW_SCORE[clearRow_] or 0)
		self:performWithDelay(function ()
			self:playRowClearAni_(clearRow_)
		end,0.5)
	end
	userCacheStepVO:setProperty("score", score)
	userCacheStepVO:setProperty("count", 1)

	--此步移动的轮数
	userCacheStepVO:setProperty("flipCardRound", self.flipCardRound)
	
	if not notRecordStep then
		GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):saveCacheStep(userCacheStepVO)
		GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):addStepCount(1)
		GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):carryOnScore(userCacheStepVO:getProperty("score"))
	end
	local sec = GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):getRunningTime()
	GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):changeCacheData({gameTime = sec})
	self:updateBtnStatus_()

end

--处理两张卡牌的链接以及头部索引的操作
function BattleManagerPyramid:linkTwoCard(card_before, card_next, headIndex, notRecordStep )
	if not card_next then
		return
	end
	-- if headIndex == BattleManagerPyramid.POS_CHANGE_2 then
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
		-- GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):changeCacheStatusByCardVO(card_before)
	end

	if headIndex then
		-- card_next:setProperty("headIndex", headIndex)

		local card = card_next
		while card do
			card:setProperty("headIndex", headIndex)
			-- if headIndex == BattleManagerPyramid.POS_CHANGE_2 then
			-- 	card:changeBoardTo(CardVO.BOARD_BACK, CardVO.FLIP_TYPE_RIGHT, true)
			-- end
			card = card:getNextCard()
		end

	end
	--音效
	GameManager:getAudioData():playAudio(common.effectSoundList.success)
	-- self:palyCollectAudio(oldIndex_,headIndex)

	DealerController.linkTwoCard(card_before, card_next)

	-- if oldIndex_ == BattleManagerPyramid.POS_CHANGE_2 and headIndex == BattleManagerPyramid.POS_CHANGE_1 then
	-- 	card_next:changeBoardTo(CardVO.BOARD_FACE, CardVO.FLIP_TYPE_LEFT, true)
	if headIndex == BattleManagerPyramid.POS_CHANGE_2 then --and oldIndex_ == BattleManagerPyramid.POS_CHANGE_1
		if card_before then
			card_before:changeBoardTo(CardVO.BOARD_BACK,nil,true)
			GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):changeCacheStatusByCardVO(card_before)
		end
	end
	
	if not card_next:getBeforeCard() then
		--重置头
		self.headsList_[card_next:getProperty("headIndex")] = card_next
	end

	--保存牌面信息
	GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):changeCacheStatusByCardVO(card_next)
	--保存步骤信息
	userCacheStepVO:setProperty("stepEnd", card_next:getProperty("headIndex"))
	userCacheStepVO:setProperty("count", DealerController.getQueueLenByHead(card_next))

	--此步移动的轮数
	userCacheStepVO:setProperty("flipCardRound", self.flipCardRound)

	if not notRecordStep then
		GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):saveCacheStep(userCacheStepVO)
		GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):addStepCount(1)
		GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):carryOnScore(userCacheStepVO:getProperty("score"))
	end
	local sec = GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):getRunningTime()
	GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):changeCacheData({gameTime = sec})
	self:updateBtnStatus_()
end

function BattleManagerPyramid:judgeMistake_()
	local openHint = GameManager:getUserData():getOpenHint()
	if GameManager:getInstance():supportTips() == false or openHint == 0 then
		return
	end
	--震动
	local list_ = self:analysisCollectCards_(true)
	for i=1,#list_ do
		list_[i]:getView():shake(true)
	end
end

function BattleManagerPyramid:didPutCardToLock()
	self.isFlipAni_ = true
	local currCard_ = self.headsList_[BattleManagerPyramid.POS_CHANGE_2]
	local pos1x_ = (self["pos"..BattleManagerPyramid.POS_CHANGE_1]:getPositionX() - self["pos"..BattleManagerPyramid.POS_CHANGE_2]:getPositionX())/2 + self["pos"..BattleManagerPyramid.POS_CHANGE_2]:getPositionX()
	local pos1_ = ccp(pos1x_,self["pos"..BattleManagerPyramid.POS_CHANGE_2]:getPositionY())
	local pos2_ = ccp(self["pos"..BattleManagerPyramid.POS_CHANGE_2]:getPositionX(),self["pos"..BattleManagerPyramid.POS_CHANGE_2]:getPositionY())
	local flipCardsAudio = GameManager:getAudioData():playAudio(common.effectSoundList.filp_cards)
	function showAni(cardVO)
		if not cardVO then
			self:performWithDelay(function (  )
				audio.stopSound(flipCardsAudio)
			end, 0.2)
			return
		end
		local node_ = cardVO:getView()
		local rowIndex = DealerController.getQueueLenByBottom(cardVO)
		
		AnimationDefine.playFlipMoveAnimation(node_,pos1_,function()
				local zOrder_ = rowIndex - 52
				node_:setZOrder(zOrder_)
				cardVO:changeBoardTo(CardVO.BOARD_BACK, nil, true)
			-- printf("didPutCardToLockAnimation --- %s",tostring(node_:getZOrder()))
			end,pos2_,function() 
				if not cardVO:getNextCard() then
					self.isFlipAni_ = false
					self:reOrderZOrder_(self.headsList_[BattleManagerPyramid.POS_CHANGE_2])
					self:judgeFilpCards()
				end
			end)
		self:performWithDelay(function ()
			showAni(cardVO:getNextCard())
		end,0.0166)
	end

	showAni(currCard_)
end

-- function BattleManagerPyramid:didPutCardToLock()
-- 	self:didPutCardToLockAnimation()
-- 	-- local currCard_ = self.headsList_[BattleManagerPyramid.POS_CHANGE_2]
-- 	-- local pos_ = ccp(self["pos"..BattleManagerPyramid.POS_CHANGE_2]:getPositionX(),self["pos"..BattleManagerPyramid.POS_CHANGE_2]:getPositionY())
-- 	-- local delayTime_ = 0
-- 	-- while currCard_ do
-- 	-- 	local card_ = currCard_
-- 	-- 	local delay_ = CCDelayTime:create(delayTime_)
-- 	-- 	local filp_ = CCCallFunc:create(function()
-- 	-- 						card_:changeBoardTo(CardVO.BOARD_BACK, CardVO.FLIP_TYPE_RIGHT, true)
-- 	-- 					end)
-- 	-- 	local move_ = CCMoveTo:create(0.03, pos_)
-- 	-- 	local seq_ = {delay_,filp_,move_}

-- 	-- 	if not card_:getNextCard() then
-- 	-- 		local call_ = CCCallFunc:create(function()
-- 	-- 						self:reOrderZOrder_(self.headsList_[BattleManagerPyramid.POS_CHANGE_2])
-- 	-- 						self:judgeFilpCards()
-- 	-- 					end)
-- 	-- 		seq_[#seq_ + 1] = call_
-- 	-- 	end

-- 	-- 	card_:getView():runAction(transition.sequence(seq_))
-- 	-- 	currCard_ = card_:getNextCard()
-- 	-- end

-- end

function BattleManagerPyramid:putCardToLock(count,notRecordStep)
	if count < 1 then
		return
	end
	local card_before = self.headsList_[BattleManagerPyramid.POS_CHANGE_2]
	if card_before then
		card_before = DealerController.getQueueEndCardVO(card_before)
	end

	local card_next = self.headsList_[BattleManagerPyramid.POS_CHANGE_1]
	if card_next then
		card_next = DealerController.getQueueEndCardVO(card_next)
		card_next = DealerController.getCardByCountFromBottom(card_next,count)
		--开放区逆向之后的第一张
		card_next = DealerController.reverseQueueByCardVO(card_next)
	else
		return
	end
	
	self:linkTwoCard(card_before, card_next, BattleManagerPyramid.POS_CHANGE_2, notRecordStep)
	self:didPutCardToLock()

	-- self:testPrintLink(BattleManagerPyramid.POS_CHANGE_1)
	-- self:testPrintLink(BattleManagerPyramid.POS_CHANGE_2)
end

function BattleManagerPyramid:didPutCardToOpen()
	local currCard_ = self.headsList_[BattleManagerPyramid.POS_CHANGE_1]
	local pos_ = ccp(self["pos"..BattleManagerPyramid.POS_CHANGE_1]:getPositionX(),self["pos"..BattleManagerPyramid.POS_CHANGE_1]:getPositionY())
	local delayTime_ = 0
	while currCard_ do
		local card_ = currCard_
		local delay_ = CCDelayTime:create(delayTime_)
		local filp_ = CCCallFunc:create(function()
							card_:changeBoardTo(CardVO.BOARD_BACK, CardVO.FLIP_TYPE_LEFT, true)
						end)
		local move_ = CCMoveTo:create(0.03, pos_)
		local seq_ = {delay_,filp_,move_}

		if not card_:getNextCard() then
			local call_ = CCCallFunc:create(function()
							self:reOrderZOrder_(self.headsList_[BattleManagerPyramid.POS_CHANGE_1])
							self:judgeFilpCards()
						end)
			seq_[#seq_ + 1] = call_
		end

		card_:getView():runAction(transition.sequence(seq_))
		currCard_ = card_:getNextCard()
	end

end

function BattleManagerPyramid:putCardToOpen(count,notRecordStep)

	if count < 1 then
		return
	end
	--锁区的最后一张
	local card_before = self.headsList_[BattleManagerPyramid.POS_CHANGE_1]
	if card_before then
		card_before = DealerController.getQueueEndCardVO(card_before)
	end
	local card_next = self.headsList_[BattleManagerPyramid.POS_CHANGE_2]
	if card_next then
		card_next = DealerController.getQueueEndCardVO(card_next)
		card_next = DealerController.getCardByCountFromBottom(card_next,count)
		--开放区逆向之后的第一张
		card_next = DealerController.reverseQueueByCardVO(card_next)
	else
		return
	end

	self:linkTwoCard(card_before, card_next, BattleManagerPyramid.POS_CHANGE_1, notRecordStep)
	self:didPutCardToOpen()
end

function BattleManagerPyramid:tapChange()
	if self.isFlipAni_ then
		return 
	end
	local nextCard_ = DealerController.getQueueEndCardVO(self.headsList_[BattleManagerPyramid.POS_CHANGE_2])
	local beforeCard_ = DealerController.getQueueEndCardVO(self.headsList_[BattleManagerPyramid.POS_CHANGE_1])
	local roundLimit = GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):getCacheData():getPyramidRoundLimit()
	
	self:resumeGame(true)
	if not nextCard_ then
		if self.flipCardRound < roundLimit - 1 then
			self:updataFlipCardRound(self.flipCardRound + 1)
			-- self.flipCardRound = self.flipCardRound + 1
			self:putCardToLock(DealerController.getQueueLenByHead(self.headsList_[BattleManagerPyramid.POS_CHANGE_1]))
		end

		return
	end
	self:judgeMistake_()
	self:linkTwoCard(beforeCard_, nextCard_, BattleManagerPyramid.POS_CHANGE_1)
	self:moveCards(nextCard_, BattleManagerPyramid.POS_CHANGE_2)

end

function BattleManagerPyramid:setDelegate( delegate )
	self.delegate_ = delegate
end

function BattleManagerPyramid:judgeCanDraw_()
	local nextCard_ = DealerController.getQueueEndCardVO(self.headsList_[BattleManagerPyramid.POS_CHANGE_2])
	local beforeCard_ = DealerController.getQueueEndCardVO(self.headsList_[BattleManagerPyramid.POS_CHANGE_1])
	local roundLimit = GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):getCacheData():getPyramidRoundLimit()
	if not nextCard_ then
		if not beforeCard_ then
			return false
		end

		if self.flipCardRound >= roundLimit - 1 then
			return false
		end
	end
	return true
end

function BattleManagerPyramid:updateBtnStatus_( )
	if self.delegate_ and self.delegate_.setBtn5Enabled then
		local stepData = GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):getCacheStepByLast()
		if stepData then
			self.delegate_:setBtn5Enabled(true)
		else
			self.delegate_:setBtn5Enabled(false)
		end
	end
	EventNoticeManager:getInstance():dispatchEvent({name = Notice.GAME_DATA_CHANGE})

	local endAniStatus = GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):getEndAniStatus() or BattleManagerPyramid.END_ANI_NONE
	local isEnd_ = false
	if endAniStatus == BattleManagerPyramid.END_ANI_STUFF 
	or endAniStatus == BattleManagerPyramid.END_ANI_DIALOG 
	or endAniStatus == BattleManagerPyramid.END_ANI_END then
		isEnd_ = true
	end

	if isEnd_ or self:judgeWin_() then
		self.btn_change:setEnabled(false)
		self.btn_change:setOpacity(100)
		return
	end

	local canDraw_ = self:judgeCanDraw_()
	local opacity_ = 255
	if not canDraw_ then
		opacity_ = 100
	end
	if self.btn_change then
		self.btn_change:setEnabled(canDraw_)
		self.btn_change:setOpacity(opacity_)
	end
end

function BattleManagerPyramid:startMoving( )
	self.cardMoving_ = true
end

function BattleManagerPyramid:endMoving(startHeadIndex)
	-- if startHeadIndex and startHeadIndex <= BattleManagerPyramid.POS_PLAY_MAX then
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
	-- if not isWin_ then
	-- 	if self:analysisFail_() then
	-- 		GameManager:getInstance():popNoWayAlert(false)
	-- 	end
	-- end
end

--暂停游戏
function BattleManagerPyramid:pauseGame()
	GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):setStartTime(0)
end
--继续游戏
function BattleManagerPyramid:resumeGame(force)
	local gameState = GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):getCacheData():getProperty("gameState")
	if gameState ~= UserCacheRecordVO.status_playing or not force then
		return
	end
	--此局生效，提交统计数据
	local isRepeat_ = GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):getCacheData():getProperty("isRepeat")
	if isRepeat_ == 0 then
		--快照数据
		GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):changeCacheData({isRepeat = 1})
		--游戏统计数据
		self:saveRecord("newGame")
	end
	GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):changeCacheData({gameState = UserCacheRecordVO.status_playing})
	GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):setStartTime(1)
	EventNoticeManager:getInstance():dispatchEvent({name = Notice.GAME_STATUS_CHANGE})

end

function BattleManagerPyramid:tapRevoke()
	if self.cardMoving_ then
		return
	end
	if self.isFlipAni_ then
		return
	end
	local stepData = GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):getCacheStepByLast()
	if not stepData then
		return
	end
	--如果有tipslayer-->remove
	local layer_ = self.card_table:getChildByTag(111)
	if layer_ then
		layer_:removeSelf(true)
		self.isTiping_ = false
	end
	self:resumeGame(true)
	GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):removeCacheStepByLast()
	local data = GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):getCacheStepByLast()
	if data then
		self:updataFlipCardRound(data:getProperty("flipCardRound"))
		-- self.flipCardRound = data:getProperty("flipCardRound")
	else
		self:updataFlipCardRound(0)
		-- self.flipCardRound = 0
	end

	GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):addStepCount(-1)
	--将增加的分数返还
	GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):carryOnScore(-stepData:getProperty("score"))
	if stepData:getProperty("stepStart") > 0 and stepData:getProperty("stepEnd") > 0 then
		if stepData:getProperty("stepStart") == BattleManagerPyramid.POS_CHANGE_1 and stepData:getProperty("stepEnd") == BattleManagerPyramid.POS_CHANGE_2 then
			-- self:putCardToLock(DealerController.getQueueLenByHead(self.headsList_[BattleManagerPyramid.POS_CHANGE_1]))
			self:putCardToOpen(DealerController.getQueueLenByHead(self.headsList_[BattleManagerPyramid.POS_CHANGE_2]),true)
			-- printf("===tapRevoke===")
		else
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
		end
	end
	
	if stepData:getProperty("stepStart2") > 0 and stepData:getProperty("stepEnd2") > 0 then
		local card_before = self.headsList_[stepData:getProperty("stepStart2")]
		if card_before then
			card_before = DealerController.getQueueEndCardVO(card_before)
		end
		local card_next = self.headsList_[stepData:getProperty("stepEnd2")]
		if card_next then
			card_next = DealerController.getQueueEndCardVO(card_next)
		end
		card_next = DealerController.getCardByCountFromBottom(card_next,stepData:getProperty("count"))
		-- if stepData:getProperty("beforeIsFlip") == 1 and card_before then
		-- 	card_before:changeBoardTo(CardVO.BOARD_BACK, nil, true)
		-- end
		self:linkTwoCard(card_before, card_next, stepData:getProperty("stepStart2"), true)
		self:moveCards(card_next, stepData:getProperty("stepEnd2"))
	end
	-- GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):carryOnScore(BattleManagerPyramid.REVOKE_VALUE)
end

function BattleManagerPyramid:tapHint()
	self:clearLight_(true)
	self:autoTips(false)
end

-- function BattleManagerPyramid:analysisCollectCards_()
-- 	local list_ = {}
-- 	for i=BattleManagerPyramid.POS_BEGIN,BattleManagerPyramid.POS_PLAY_MAX do
-- 		if self.headsList_[i] 
-- 			and self.headsList_[i]:getProperty("board") == CardVO.BOARD_FACE then
-- 			local isCanCollect_ = self:judgeCardCanCollect(self.headsList_[i])
-- 			if isCanCollect_ then
-- 				list_[#list_ + 1] = self.headsList_[i]
-- 			end
-- 		end
-- 	end
-- 	return list_
-- end

function BattleManagerPyramid:createTipsLayer()
	self.isTiping_ = true
	local layer_ = display.newNode()--display.newColorLayer(ccc4(0, 0, 0, 255*0.65))
	layer_:setContentSize(self.card_table:getContentSize())
	layer_:setScale(self:getScale())
	layer_:setTag(111)
	self.card_table:addChild(layer_,100)

	layer_:setTouchEnabled(true)
	layer_:setTouchSwallowEnabled(false)
	layer_:addNodeEventListener(cc.NODE_TOUCH_EVENT,function(event)
			if event.name == "began" then
				layer_:removeSelf(true)
				self.isTiping_ = false
				return true
			elseif event.name == "moved" then
			elseif event.name == "ended" then
				
			end
		end)
	return layer_
end

function BattleManagerPyramid:updataHintLogic_()
	local openHint = GameManager:getUserData():getOpenHint()
	if openHint > 0 then
		self:openAutoTips_()
	else
		self:hideHelpLabel()
	end
end

function BattleManagerPyramid:openAutoTips_()
	self:closeAutoTips_()
	if self.isWinning_ then return end
	local openHint = GameManager:getUserData():getOpenHint()
	if openHint > 0 then
		self.schedulerHandle = self:performWithDelay(function ()
			self:autoTips(true)
		end,15)
	end
end

function BattleManagerPyramid:closeAutoTips_()
	if self.schedulerHandle then
		self:stopAction(self.schedulerHandle)
		self.schedulerHandle = nil
	end
end

function BattleManagerPyramid:hideHelpLabel()
	self:openAutoTips_()
	self:clearLight_()
end

function BattleManagerPyramid:clearLight_()
	if not self.lights_ then
		return
	end
	for i=1,#self.lights_ do
		self.lights_[i]:removeSelf(true) 
	end
	self.lights_ = {}
end

function BattleManagerPyramid:addLight_( node , isRepeat ,noBlick)
	local size = node:getContentSize()
	local rect = CCRectMake(20, 20, 5, 4)
	local light = display.newScale9Sprite("#poker_shine.png", 0, 0, CCSizeMake(size.width+16, size.height+14), rect)
	light:setAnchorPoint(ccp(0.5, 0))
	light:setPosition(ccp(size.width/2, -7))
	node:addChild(light)
	-- local __mb = ccBlendFunc()
	-- __mb.src = GL_ONE
	-- __mb.dst = GL_ONE
	-- light:setBlendFunc(__mb)
	if noBlick then
		light:setTag(1)
		light:setZOrder(-1)
		return light
	end
	if isRepeat then
		local fadeOut = CCFadeOut:create(0.5)
		local fadeIn = CCFadeIn:create(0.5)
		local action = CCRepeatForever:create(transition.sequence({fadeIn,fadeOut}))
		light:runAction(action)
	else
		
		local fadeIn1 = CCFadeIn:create(0.5)
		local fadeOut1 = CCFadeOut:create(0.5)
		
		local fadeIn2 = CCFadeIn:create(0.5)
		local fadeOut2 = CCFadeOut:create(0.5)
		
		local fadeIn3 = CCFadeIn:create(0.5)
		local fadeOut3 = CCFadeOut:create(0.5)

		local action = transition.sequence({fadeIn1,fadeOut1,fadeIn2,fadeOut2,fadeIn3,fadeOut3})--, fadeIn1, fadeOut2, fadeIn2, fadeOut3, fadeIn3
		light:runAction(action)
	end
	
	return light
end

function BattleManagerPyramid:changeBtn_addLight_( node , isRepeat )
	local isclickEnabled = self.btn_change:isEnabled()
	if not isclickEnabled then
		-- return
		GameManager:getInstance():popNoWayAlert(false)
	end
	local size = node:getContentSize()
	local rect = CCRectMake(20, 20, 5, 4)
	local light = display.newScale9Sprite("#B_green0.png", 0, 0, CCSizeMake(size.width, size.height), rect)
	light:setAnchorPoint(ccp(0.5, 0))
	light:setPosition(ccp(size.width/2,0))
	node:addChild(light)
	local __mb = ccBlendFunc()
	__mb.src = GL_ONE
	__mb.dst = GL_ONE
	light:setBlendFunc(__mb)
	light:setOpacity(0)

	if isRepeat then
		local fadeOut = CCFadeTo:create(0.3,0)
		local fadeIn = CCFadeTo:create(0.3,75)
		local delay = CCDelayTime:create(0.5)
		local action = CCRepeatForever:create(transition.sequence({fadeIn,fadeOut,delay}))
		light:runAction(action)
	else
		
		local fadeIn1 = CCFadeTo:create(0.3,75)
		local fadeOut1 = CCFadeTo:create(0.3,0)
		
		local fadeIn2 = CCFadeTo:create(0.3,75)
		local fadeOut2 = CCFadeTo:create(0.3,0)
		
		local fadeIn3 = CCFadeTo:create(0.3,75)
		local fadeOut3 = CCFadeTo:create(0.3,0)

		local action = transition.sequence({fadeIn1,fadeOut1,fadeIn2,fadeOut2,fadeIn3,fadeOut3})--, fadeIn1, fadeOut2, fadeIn2, fadeOut3, fadeIn3
		-- local action = transition.sequence({fadeIn1,fadeOut1})
		light:runAction(action)
	end
	
	return light
end


function BattleManagerPyramid:autoTips( isRepeat )
	if GameManager:getInstance():supportTips() == false then
		return
	end
	if self:judgeWin_() then
		return
	end
	if self:analysisFail_() then
		GameManager:getInstance():popNoWayAlert(false)
		self:closeAutoTips_()
		return
	end
	-- if self.isTiping_ then
	-- 	return
	-- end
	self:clearLight_()
	if not self.lights_ then self.lights_ = {} end
	self:moveTipsDeckList_(isRepeat)
	
end


--添加tips MoveCards
--得到cancollect牌组list
function BattleManagerPyramid:getCanCollectDeckList( )
	local canCollectList_ = self:analysisCollectCards_()
	local deckList_ = {}
	for i = #canCollectList_,1,-1 do -- card1
		local card1 = canCollectList_[i]
		-- card1是否是KING
		local isKING = DealerController.pyramidCanCollect(card1,nil)
		if isKING then -- 第i张card是K
			local deckList_index = {}
			deckList_index[1] = card1
			deckList_[#deckList_+1] = deckList_index
		else -- 第i张card不是K
			for j=i-1,1,-1 do
				local deckList_index = {}
				local card2 = canCollectList_[j]
				local bothChangePos = (card1:getProperty("headIndex") + card2:getProperty("headIndex")) == BattleManagerPyramid.POS_CHANGE_1+BattleManagerPyramid.POS_CHANGE_2
				if not bothChangePos then
					if DealerController.pyramidCanCollect(card1,card2) then
						deckList_index[1] = card1
						deckList_index[2] = card2
						deckList_[#deckList_+1] = deckList_index
					end
				end
			end
		end		
	end
	-- dump(deckList_)
	return deckList_
end
function BattleManagerPyramid:moveTipsDeckList_( isRepeat )
	if GameManager:getInstance():supportTips() == false then
		return
	end
	if self.isTiping_ then
		return
	end
	
	self.moveDeckList_ = self:getCanCollectDeckList() --得到cancollect牌组list(各种牌组合)
	
	if #self.moveDeckList_ < 1 then
		--添加功能：显示“翻拍”按钮提醒
		self.lights_[1] = self:changeBtn_addLight_(self.btn_change,isRepeat)
		self.isTiping_ = false
		return
	end
	local tipsLayer_ = self:createTipsLayer()
	tipsLayer_:setTouchSwallowEnabled(false)
	function showTipAni( node, index )
		if  not node or tolua.isnull(node)  then
			return
		end
		if #self.moveDeckList_ < index then
			if isRepeat then
				index = 1
				self:performWithDelay(function()
					showTipAni( node, index )
     			end, 0.5)	
			else
				node:removeSelf(true)
				self.isTiping_ = false
			end
			return
		end
		--判断是否是K
		if self.moveDeckList_[index][1]:getProperty("rank") == CardVO.RANK_KING then
			local sp_ = self.moveDeckList_[index][1]:getView()
			local from = ccp(sp_:getPositionX(), sp_:getPositionY())
			local to = from
			AnimationDefine.tipAnimation(self.moveDeckList_[index][1],node,from,to,function()
				showTipAni(node, index + 1)
			end,true)
		else -- card1 + card2 == K
			local sp_1 = self.moveDeckList_[index][1]:getView()
			local sp_2 = self.moveDeckList_[index][2]:getView()
			local from = ccp(sp_1:getPositionX(), sp_1:getPositionY())
			local to = ccp(sp_2:getPositionX(), sp_2:getPositionY() - 45)
			AnimationDefine.tipAnimation(self.moveDeckList_[index][1],node,from,to,function()
				showTipAni(node, index + 1)
			end)
		end
	end
	showTipAni(tipsLayer_, 1)
end

function BattleManagerPyramid:judgeWin_()
	local win_ = true
	for i=BattleManagerPyramid.POS_BEGIN,BattleManagerPyramid.POS_PLAY_MAX do
		if self.headsList_[i] then
			win_ = false 
			break
		end
	end
	return win_
end

function BattleManagerPyramid:analysisWin_()
	if self.isWinning_ then
		return
	end
	local win_ = self:judgeWin_()
	if win_ then
		self.isWinning_ = true
		self:closeAutoTips_()
		self:pauseGame()
		self:uploadSeed()
		self:updateBtnStatus_()
		local sec = GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):getRunningTime()
		--计时模式下的奖励分数
		GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):carryOnScore(GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):getPyramidTimeEndScore())
		EventNoticeManager:getInstance():dispatchEvent({name = Notice.GAME_DATA_CHANGE})
		--提交统计数据
		local isWin_ = GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):getCacheData():getProperty("isWin")
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
		local isDailyChallenge = GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):isDailyChallenge()
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
		GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):cacheRecordData(heigh, data, radom_, list,isFirstWin_)
		
		GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):setEndAniStatus(BattleManagerPyramid.END_ANI_STUFF)
		-- self:showStuffAnimation()
		self.isLocalWin_ = true -- 等待播放

        -- if DEBUG ~= 2 then
        	GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):cleanData()
        -- end
		GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):changeCacheData({gameState = UserCacheRecordVO.status_end, gameTime = sec, isWin = isWin_})
		EventNoticeManager:getInstance():dispatchEvent({name = Notice.GAME_STATUS_CHANGE})
	end

	return win_
end

function BattleManagerPyramid:analysisFail_()
	if self.isWinning_ then
		return false
	end
	if self:judgeWin_() then
		return false
	end
	if self.headsList_[BattleManagerPyramid.POS_CHANGE_2] then
		return false
	end
	
	local list_ = self:analysisCollectCards_()
	if #list_ > 0 then
		return false
	end
	if self.btn_change then
		if self.btn_change:isEnabled() then
			return false
		end
	end
	-- for i=BattleManagerPyramid.POS_BEGIN,BattleManagerPyramid.POS_PLAY_MAX do
	-- 	if self.headsList_[i] 
	-- 		and self.headsList_[i]:getProperty("board") == CardVO.BOARD_FACE then
	-- 		local isCanCollect_ = self:judgeCardCanCollect(self.headsList_[i])
	-- 		if isCanCollect_ then
	-- 			return false
	-- 		end
	-- 	end
	-- end

	return true
end


function BattleManagerPyramid:showWinDialog( )
	local needCoin_ = false
	if GAME_MODE == GAME_MODE_COLLECTION then
		needCoin_ = true
	end
    local viewCtrl = WinViewCtrl.new(needCoin_)
    display.getRunningScene():addChild(viewCtrl:getView())
    GameManager:getUserData():addPraiseWinCount()
end

function BattleManagerPyramid:showStuffAnimation( )
	local list = GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):getProperty("stuffData") or {}
	local index = 1
	for i=1,#list do
		local index_ = BattleManagerPyramid.POS_COLLECT_1
		if i%2 == 0 then
			index_ = BattleManagerPyramid.POS_COLLECT_2
		end
		list[i].pos = ccp(self["pos"..index_]:getPosition())
	end
	--洗牌动画的载体节点
	local node = display.newNode()
	node:setContentSize(self.card_table:getContentSize())
	node:setPosition(self:getPosition())
	node:setScale(self:getScale())
	display.getRunningScene():addChild(node)

	local radom = GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):getProperty("aniNum") or 1
	self:initSuccesAni_(list,node,radom)
end

function BattleManagerPyramid:initSuccesAni_(list,node,radom)
	--屏蔽触摸和按钮
    local touchNode = self:addTouchLayer_(display.getRunningScene(), ccc4(0, 0, 0, 0))

	--洗牌动画播放完毕之后的结算动画
	function endCallBack_( node )
		self.headsList_ = {}
		if GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):getEndAniStatus() == BattleManager.END_ANI_DIALOG then
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
                GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):setEndAniStatus(BattleManager.END_ANI_DIALOG)
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

function BattleManagerPyramid:saveRecord(name)
	local roundMode = GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):getCacheData():getProperty("roundMode") or 1
	if name == "newGame" then
		GameManager:getUserClassicData():addPyramidCount(1, roundMode)
	elseif name == "win" then
		GameManager:getUserClassicData():addPyramidWinCount(1, roundMode)
	elseif name == "record" then
		local high = false
		local step_ = GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):getCacheStepCount()
		local sec_ = GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):getRunningTime()

		local pyramid_cacheData = GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):getCacheData()
        stepCount = pyramid_cacheData:getProperty("move")
        step_ = stepCount

		GameManager:getUserClassicData():addPyramidFewestMove(step_,roundMode)
		GameManager:getUserClassicData():addPyramidFewestTime(sec_,roundMode)
		--普通模式
		local score_ = GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):getCacheData():getProperty("score")
		score_ = score_ + GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):getTimeScore()
		high = GameManager:getUserClassicData():addPyramidHighestScore(score_,roundMode)
		--保存排行榜信息
		local timeTemp = os.time()
		local userClassicRankVO = UserClassicRankVO.new({score=score_, moves = step_, time = sec_, createdTimestamp = timeTemp})
		GameManager:getUserClassicData():saveRankData(userClassicRankVO,UserClassicRankVO["MODE_PYRAMID"..roundMode])

		local list = GameManager:getUserClassicData():getProperty("pyramidRankList"..roundMode) or {}
		local totalScore = 0
		local rankMode = GameCenterDefine.getLeaderBoardId()["pyramid"..roundMode]
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
function BattleManagerPyramid:uploadSeed()
	local cacheData = GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):getCacheData()
	local roundMode = 1
	if self.flipCardRound <= 0 then
		roundMode = 1
	elseif self.flipCardRound > 0 and self.flipCardRound < 3 then
		roundMode = 2
	else
		roundMode = 3
	end

	local isDeal = cacheData:getProperty("isDeal")
	local isNewPlayer = cacheData:getProperty("isNewPlayer")
	if isDeal > 0 or isNewPlayer >0 then
		--活局不用上传种子
		printf("不做胜利种子保存")
		return
	end
	local userDealSeedVO = UserDealSeedVO.new()
	local seed = GameManager:getUserGameCacheData(GameManager.MODETYPE_PYRAMID):getCacheData():getProperty("seed") or ""
	local mode = UserCacheRecordVO["mode_pyramid"..roundMode]
	userDealSeedVO:setProperty("mode", mode)
	userDealSeedVO:setProperty("seed", seed)

	local needUpload_ = GameManager:getUserSeedData():saveDealSeedByList({userDealSeedVO},mode)
	if not needUpload_ then
		return
	end
	printf("种子上传")
	local param = {}
	local seedList = GameManager:getUserSeedData():getDealSeedByList(mode) or {}
	for i=1,#seedList do
		local mode = seedList[i]:getProperty("mode")
		local keyName
		if mode == UserCacheRecordVO.mode_pyramid2 then
			keyName = "pyramid2"
		elseif mode == UserCacheRecordVO.mode_pyramid3 then
			keyName = "pyramid3"
		else
			keyName = "pyramid1"
		end
		if not param[keyName] then
			param[keyName] = {}
		end
		local len = #param[keyName]+1
		param[keyName][len] = seedList[i]:getProperty("seed")
	end

	GameManager:getNetWork():saveSeed(param)
end

function BattleManagerPyramid:addTouchLayer_( parent, corlor )
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

function BattleManagerPyramid:playPartical_( headIndex, startIndex )
	-- if headIndex < BattleManagerPyramid.HEAD_COLLECT_1 or headIndex > BattleManagerPyramid.HEAD_COLLECT_MAX 
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

function BattleManagerPyramid:palyCollectAudio( oldIndex,headIndex )
	-- if oldIndex > BattleManagerPyramid.POS_PLAY_MAX or headIndex ~= BattleManagerPyramid.POS_CHANGE_1 then
	-- 	return
	-- end
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

function BattleManagerPyramid:checkMoveNeedAddScore(startHeadIndex, endHeadIndex)
	local isFishdom = PackageConfigDefine.isSolitaireFishdom()
	if not isFishdom then
		return 0
	end
	if (endHeadIndex == BattleManagerPyramid.POS_COLLECT_1 or endHeadIndex == BattleManagerPyramid.POS_COLLECT_2) then
		--收牌
		return BattleManagerPyramid.COLLECT_VALUE
	elseif (startHeadIndex == BattleManagerPyramid.POS_COLLECT_1 or startHeadIndex == BattleManagerPyramid.POS_COLLECT_2) then
		return -BattleManagerPyramid.COLLECT_VALUE
	end

	return 0
end

function BattleManagerPyramid:playScoreAction(posBegin, posEnd, scoreNum)
	local isFishdom = PackageConfigDefine.isSolitaireFishdom()
	if not self.card_table or not isFishdom then
		return
	end
	common.scoreAction(self.card_table, posBegin, posEnd, scoreNum)
end

return BattleManagerPyramid