--
-- Author: yang fuchao
-- Date: 2016-09-22 15:59:57
--
local BattleManagerSpider = class("BattleManagerSpider",function()
	return display.newNode()
end)

BattleManagerSpider.HEAD_COLUMN_1 = 1		--牌桌
BattleManagerSpider.HEAD_COLUMN_2 = 2
BattleManagerSpider.HEAD_COLUMN_3 = 3
BattleManagerSpider.HEAD_COLUMN_4 = 4
BattleManagerSpider.HEAD_COLUMN_5 = 5
BattleManagerSpider.HEAD_COLUMN_6 = 6
BattleManagerSpider.HEAD_COLUMN_7 = 7
BattleManagerSpider.HEAD_COLUMN_8 = 8
BattleManagerSpider.HEAD_COLUMN_9 = 9
BattleManagerSpider.HEAD_COLUMN_MAX = 10

BattleManagerSpider.HEAD_COLLECT_1 = 11	--集牌区
BattleManagerSpider.HEAD_COLLECT_2 = 12
BattleManagerSpider.HEAD_COLLECT_3 = 13
BattleManagerSpider.HEAD_COLLECT_4 = 14
BattleManagerSpider.HEAD_COLLECT_5 = 15
BattleManagerSpider.HEAD_COLLECT_6 = 16
BattleManagerSpider.HEAD_COLLECT_7 = 17
BattleManagerSpider.HEAD_COLLECT_MAX = 18

BattleManagerSpider.HEAD_CHANGE_1 = 19	--存牌区
BattleManagerSpider.HEAD_CHANGE_2 = 20	
BattleManagerSpider.HEAD_CHANGE_3 = 21
BattleManagerSpider.HEAD_CHANGE_4 = 22	
BattleManagerSpider.HEAD_CHANGE_MAX = 23

BattleManagerSpider.END_ANI_NONE = 0
BattleManagerSpider.END_ANI_COLLECTING = 1--收集
BattleManagerSpider.END_ANI_STUFF = 2--洗牌
BattleManagerSpider.END_ANI_DIALOG = 3--结算窗
BattleManagerSpider.END_ANI_END = 4--结束

function BattleManagerSpider:ctor(delegate )
	GameManager:getAudioData():stopAllAudios()
	KMultiLanExtend.extend(self)
	self:initView_()

	self.btn_autoCollect:setVisible(false)
	self:setDelegate(delegate)
	self.headsList_ = {}
	--是否展示移动动画
	self.showMoveAni_ = true
	self.cardMoving_ = false
	--初始化牌组
	self:startGame(nil, true)

	self:setNodeEventEnabled(true)
end

function BattleManagerSpider:onEnter( )
	EventNoticeManager:getInstance():addEventListener(self,Notice.APP_ENTER_BACKGROUND,handler(self, self.gameEnterBackground_))
	EventNoticeManager:getInstance():addEventListener(self,Notice.USER_DATA_CHANGE,handler(self, self.leftModeChanged))
	EventNoticeManager:getInstance():addEventListener(self,Notice.USER_LANGUAGE_CHANGE,handler(self, self.setLocalization_))
    EventNoticeManager:getInstance():addEventListener(self,Notice.USER_CARD_CHANGE,handler(self, self.updataAllCards))
    

end

function BattleManagerSpider:setLocalization_( )
	self:setBtnTitle(self.btn_autoCollect, "自动收牌")
end

function BattleManagerSpider:onExit( )
	EventNoticeManager:getInstance():removeEventListenerForHandle(self)
end

function BattleManagerSpider:getHeadsList()
	return self.headsList_ or {}
end

function BattleManagerSpider:updataAllCards(event)
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

function BattleManagerSpider:gameEnterBackground_( )
	local sec = GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):getRunningTime()
	GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):changeCacheData({gameTime = sec})

	GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):saveCache()
	GameManager:getUserChallengeData():saveCache()
end

function BattleManagerSpider:starNewGame( seed, resetAll, suitCount )
	GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):cleanData()
	self:clearLight_()
	self:stopAllActions()
	self.card_table:removeAllChildren()
	self.headsList_ = {}
	--是否展示移动动画
	self.showMoveAni_ = true
	self.cardMoving_ = false
	GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):cleanRecordData()
	--初始化牌组
	self:startGame(seed, resetAll, suitCount)
end

function BattleManagerSpider:initView_( )
	--计算视图大小
	local isPortrait = self:isPortrait_()
	local displaySize = CCSizeMake(display.width, display.height)
	if isPortrait then
		displaySize = CCSizeMake(USER_SCREEN_WIDTH, USER_SCREEN_HEIGHT)
	else
		displaySize = CCSizeMake(960, USER_SCREEN_WIDTH)
	end
	self:setContentSize(displaySize)
	--读取ccb文件
	local ccbName = isPortrait and "battleSpiderView" or "battleSpiderView_land"
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
	elseif not isPortrait and display.width < 960 then
		local rate = display.width/960
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

	if isPortrait then
		local offsetY = 250
		for i=BattleManagerSpider.HEAD_COLUMN_1,BattleManagerSpider.HEAD_COLUMN_MAX do
			if self["column"..i] then
				self["column"..i]:setPositionY(size.height- offsetY)
			end
		end
		offsetY = 130
		for i=BattleManagerSpider.HEAD_COLLECT_1,BattleManagerSpider.HEAD_CHANGE_MAX do
			if self["column"..i] then
				self["column"..i]:setPositionY(size.height- offsetY)
			end
		end
	else
		local offsetY = 134
		for i=BattleManagerSpider.HEAD_COLUMN_1,BattleManagerSpider.HEAD_COLLECT_1 do
			if self["column"..i] then
				self["column"..i]:setPositionY(size.height- offsetY)
			end
		end
		offsetY = 370
		for i=BattleManagerSpider.HEAD_CHANGE_1,BattleManagerSpider.HEAD_CHANGE_MAX do
			if self["column"..i] then
				self["column"..i]:setPositionY(size.height- offsetY)
			end
		end
	end
end

--设置卡槽以及图标主题
function BattleManagerSpider:setCardsSlot(style)
	--槽
    for i=BattleManagerSpider.HEAD_COLUMN_1,BattleManagerSpider.HEAD_CHANGE_MAX do
        if self["column"..i] and self["column"..i].setTexture then
        	local type_ = "_cardback"
        	if i >= BattleManagerSpider.HEAD_COLLECT_1 and i <= BattleManagerSpider.HEAD_COLLECT_MAX then
        		type_ = "_collect"
        	end
        	local fileName_ = "UI_Resources/theme/Theme"..style..type_..".png"
        	local texture = cc.TextureCache:sharedTextureCache():addImage(fileName_)
			if texture then
				self["column"..i]:setTexture(texture)
			end
        end
    end

end

function BattleManagerSpider:startGame( seed, resetAll, suitCount )
	local endAniStatus = GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):getEndAniStatus() or BattleManagerSpider.END_ANI_NONE
	local list = GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):getCacheCardList_()
	if table.nums(list) <= 0 then
		--没有牌面信息需要判断是否播放结算动画
		if endAniStatus == BattleManagerSpider.END_ANI_STUFF then
			self:showStuffAnimation()
		elseif endAniStatus == BattleManagerSpider.END_ANI_DIALOG then
			-- self:showWinDialog(true)--胜利弹窗在切屏之后会自动弹出了，这里不处理了
		elseif endAniStatus == BattleManagerSpider.END_ANI_END then
			--todo
		else
			GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):resetCacheData(resetAll)
			self:initCard_(seed, suitCount)
			--发牌
			self:startDealCard(true)
		end
	else
		-- local data = GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):getCacheStepByLast()
		-- if data then
		-- 	self.flipCardRound = data:getProperty("flipCardRound")
		-- else
		-- 	self.flipCardRound = 0
		-- end
		
		self:runReplay()
		--发牌
		self:startDealCard()
		--有牌面信息需要判断是否自动收牌
		if endAniStatus == BattleManagerSpider.END_ANI_COLLECTING then
			self:autoCollectCard()
		end
	end

end

function BattleManagerSpider:initCard_( _seed, suitCount )
	--获取牌组
	local suitCount_ = GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):getCacheData():getProperty("suitCount") or 1
	local list = DealerController.initCards(2, suitCount or suitCount_)
	local seed_ = ""

	--洗牌
	list, seed_ = DealerController.shuffleCards(list, _seed)

	GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):changeCacheData({seed = seed_, gameState = UserCacheRecordVO.status_playing, isNewPlayer = ((isNewPlayer and 1) or 0)})
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

	for col=BattleManagerSpider.HEAD_COLUMN_1,BattleManagerSpider.HEAD_COLUMN_MAX do
		local before = nil
		local rowNum_ = 5
		if col < BattleManagerSpider.HEAD_COLUMN_5 then
			rowNum_ = 6
		end

		for num=1,rowNum_ do
			local cardVO = list[1]
			table.remove(list, 1)
			linkCard_(before, cardVO, col)
			before = cardVO
		end
	end

	--剩余的牌分成5组在发牌区
	for col=BattleManagerSpider.HEAD_CHANGE_1,BattleManagerSpider.HEAD_CHANGE_MAX do
		local before = nil
		local rowNum_ = 10
		for num=1,rowNum_ do
			local cardVO = list[1]
			table.remove(list, 1)
			linkCard_(before, cardVO, col)
			before = cardVO
		end
	end

	GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):changeCacheStatusByCardList(cacheList)
end

function BattleManagerSpider:isPortrait_( )
	return CONFIG_SCREEN_ORIENTATION == "portrait"
end

function BattleManagerSpider:getCardOffsetY_( face )
	local isPortrait = self:isPortrait_()
	if face == CardVO.BOARD_BACK then
		return 10
	end
	if isPortrait then
		return 30
	else
		return 35
	end
end

function BattleManagerSpider:getCardOffsetX_( )
	--正常模式下从左向右的偏移为正，左手模式下为负
	local left_mode = GameManager:getUserData():getIsLeft()
	if left_mode > 0 then
		return -20
	end
	return 20
end

--左手模式变更了
function BattleManagerSpider:leftModeChanged( )
	local isPortrait = self:isPortrait_()
	local left_mode = GameManager:getUserData():getIsLeft()
	local width = self.card_table:getContentSize().width
	local maxCount = BattleManagerSpider.HEAD_COLUMN_MAX
	if left_mode > 0 then
		if self.isLeft_ then
			return
		end
		self.isLeft_ = true
		--启用左手模式
		if isPortrait then
			if self["column"..BattleManagerSpider.HEAD_COLLECT_1] then
				self["column"..BattleManagerSpider.HEAD_COLLECT_1]:setPositionX(width-62)
			end
			if self["column"..BattleManagerSpider.HEAD_CHANGE_1] then
				self["column"..BattleManagerSpider.HEAD_CHANGE_1]:setPositionX(157)
			end
		else
			for i=BattleManagerSpider.HEAD_COLUMN_1,BattleManagerSpider.HEAD_COLUMN_MAX do
				if self["column"..i] then
					self["column"..i]:setPositionX(152+84*(i-1))
				end
			end
			if self["column"..BattleManagerSpider.HEAD_COLLECT_1] then
				self["column"..BattleManagerSpider.HEAD_COLLECT_1]:setPositionX(54)
			end
			if self["column"..BattleManagerSpider.HEAD_CHANGE_1] then
				self["column"..BattleManagerSpider.HEAD_CHANGE_1]:setPositionX(54)
			end
		end
	else
		if not self.isLeft_ then
			return
		end
		self.isLeft_ = false
		--关闭左手模式
		if isPortrait then
			if self["column"..BattleManagerSpider.HEAD_COLLECT_1] then
				self["column"..BattleManagerSpider.HEAD_COLLECT_1]:setPositionX(62)
			end
			if self["column"..BattleManagerSpider.HEAD_CHANGE_1] then
				self["column"..BattleManagerSpider.HEAD_CHANGE_1]:setPositionX(width-157)
			end
		else
			for i=BattleManagerSpider.HEAD_COLUMN_1,BattleManagerSpider.HEAD_COLUMN_MAX do
				if self["column"..i] then
					self["column"..i]:setPositionX(54+84*(i-1))
				end
			end
			if self["column"..BattleManagerSpider.HEAD_COLLECT_1] then
				self["column"..BattleManagerSpider.HEAD_COLLECT_1]:setPositionX(width-54)
			end
			if self["column"..BattleManagerSpider.HEAD_CHANGE_1] then
				self["column"..BattleManagerSpider.HEAD_CHANGE_1]:setPositionX(width-54)
			end
		end
	end
	self:reloadCardsPos()
	self:clearLight_()
end

function BattleManagerSpider:reloadCardsPos( )
	self.btnDealCard:setPosition(self:getRootPos(BattleManagerSpider.HEAD_CHANGE_3))
	--刷新卡牌的位置
	function reload( headIndex )
		--传入列号，位置节点编号，x方向偏移
		local card = self.headsList_[headIndex]
		local offsetY = 0
		local rootPos = self:getRootPos(headIndex)
		while card do
			local sprite = card:getView()
			if sprite then
				sprite:setPosition(ccp(rootPos.x, rootPos.y + offsetY))
				if not sprite:getParent() then
					self.card_table:addChild(sprite)
				end
			else
				printf("no card sprite!")
			end
			if headIndex >= BattleManagerSpider.HEAD_COLUMN_1 and headIndex <= BattleManagerSpider.HEAD_COLUMN_MAX then
				offsetY = offsetY - self:getCardOffsetY_(card:getProperty("board"))
			end
			card = card:getNextCard()
		end
	end

	for i=BattleManagerSpider.HEAD_COLUMN_1,BattleManagerSpider.HEAD_CHANGE_MAX do
		reload(i)
		if i <= BattleManagerSpider.HEAD_COLUMN_MAX then
			self:dealOffsetY(i)
		end
	end
end

--获取每一列的根坐标
function BattleManagerSpider:getRootPos(headIndex )
	local isPortrait = self:isPortrait_()
	local pos = ccp(0, 0)
	local offset = ccp(0, 0)
	local rootIndex = headIndex
	if headIndex >= BattleManagerSpider.HEAD_COLLECT_1 and headIndex <= BattleManagerSpider.HEAD_COLLECT_MAX then
		rootIndex = BattleManagerSpider.HEAD_COLLECT_1
		if isPortrait then
			offset.x = self:getCardOffsetX_() * (headIndex - rootIndex)
		else
			offset.y = -20 * (headIndex - rootIndex)
		end
	elseif headIndex >= BattleManagerSpider.HEAD_CHANGE_1 and headIndex <= BattleManagerSpider.HEAD_CHANGE_MAX then
		rootIndex = BattleManagerSpider.HEAD_CHANGE_1
		if isPortrait then
			offset.x = self:getCardOffsetX_() * (headIndex - rootIndex)
		else
			offset.y = -15 * (headIndex - rootIndex)
		end
	end
	if self["column"..rootIndex] then
		pos.x, pos.y = self["column"..rootIndex]:getPosition()
	end
	--根据横竖屏和左右手模式计算每一列的最终坐标
	pos.x, pos.y = pos.x + offset.x, pos.y + offset.y
	return pos
end

--这里返回的是发牌区的发牌的牌头
function BattleManagerSpider:getDealCardHead( )
	for i=BattleManagerSpider.HEAD_CHANGE_MAX, BattleManagerSpider.HEAD_CHANGE_1, -1 do
		if self.headsList_[i] then
			return self.headsList_[i]
		end
	end
end

--这里返回的是发牌区的第一个空位
function BattleManagerSpider:getVoidDealIndex( )
	for i=BattleManagerSpider.HEAD_CHANGE_1, BattleManagerSpider.HEAD_CHANGE_MAX do
		if not self.headsList_[i] then
			return i
		end
	end
end

--这里返回的是集牌区第一个空位
function BattleManagerSpider:getVoidCollectIndex( )
	for i=BattleManagerSpider.HEAD_COLLECT_1, BattleManagerSpider.HEAD_COLLECT_MAX do
		if not self.headsList_[i] then
			return i
		end
	end
end

function BattleManagerSpider:startDealCard( animation )
	self:stopAllActions()
	self.playing = false
	self:leftModeChanged()
	--此时才开始创建卡牌的形象
	if animation then
		self:startMoving()
		for i=BattleManagerSpider.HEAD_COLUMN_1,BattleManagerSpider.HEAD_CHANGE_MAX do
			local card = self.headsList_[i]
			while card do
				local sprite = card:getView()
				if sprite then
					sprite:setPosition(ccp(self.card_table:getContentSize().width/2, self.cardPos:getPositionY()-sprite:getContentSize().height))
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
			if headIndex > BattleManagerSpider.HEAD_CHANGE_MAX then
				self:endMoving()
				touchNode:removeSelf(true)
				return
			end
			if not card then
				showAni(headIndex+1, self.headsList_[headIndex+1], 0, 0)
			else
				local rootPos = self:getRootPos(headIndex)
				if card:getBeforeCard() and headIndex <= BattleManagerSpider.HEAD_COLUMN_MAX then
					offsetX = offsetX + self:getCardOffsetY_(card:getProperty("board"))
				end
				local move = CCMoveTo:create(0.2, ccp(rootPos.x, rootPos.y - offsetX))
				local call = CCCallFunc:create(function ()
					GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):changeCacheStatusByCardVO(card)
				end)

				if card:getNextCard() or headIndex > BattleManagerSpider.HEAD_COLUMN_MAX then
					card:getView():runAction(move)
				else
					card:changeBoardTo(CardVO.BOARD_FACE)
					card:getView():runAction(transition.sequence({move, call}))
				end

				self:performWithDelay(function ()
					showAni(headIndex, card:getNextCard(), count + 1, offsetX)
				end,0.001)
			end
			if not self.playing then
				self.playing = true
				self:performWithDelay(function ()
						self.playing = false
					end,0.05)
				GameManager:getAudioData():playAudio(common.effectSoundList.tableau)
			end

		end
		showAni(BattleManagerSpider.HEAD_COLUMN_1, self.headsList_[BattleManagerSpider.HEAD_COLUMN_1], 0, 0)

	else
		self:reloadCardsPos()
	end

	for i=BattleManagerSpider.HEAD_COLUMN_1,BattleManagerSpider.HEAD_CHANGE_MAX do
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
	-- self:analysisCollectCard_()
	-- self.btn_autoCollect:setOpacity(255*0.95)
	self:updateBtnStatus_()
end

function BattleManagerSpider:runReplay( )
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
	local list = GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):getCacheCardList_()
	for k,v in pairs(list) do
		if v and #v > 0 then
			local before = nil
			for i=1,#v do
				local cardVO = v[i]
				if cardVO then
					cardVO:clearView()
					linkCard_(before, cardVO, k)
					if i == #v and k >= BattleManagerSpider.HEAD_COLUMN_1 and k <= BattleManagerSpider.HEAD_COLUMN_MAX then
						--保证最后一张牌一定是正面的
						cardVO:changeBoardTo(CardVO.BOARD_FACE)
					end
					before = cardVO
				end
			end
		end
	end

	self.showMoveAni_ = true
end

function BattleManagerSpider:cleanTouchData_( )
	self.pre_x = 0
	self.pre_y = 0
	self.card_pre_x = {}
	self.card_pre_y = {}
	self.click_ = true
end

function BattleManagerSpider:cardTouchBegan( cardSp, x, y )
	self:resumeGame(true)
	-- if self.cardMoving_ then
	-- 	return false
	-- end
	if cardSp.data_.headIndex_ >= BattleManagerSpider.HEAD_COLLECT_1
		and cardSp.data_.headIndex_ <= BattleManagerSpider.HEAD_CHANGE_MAX then
		--集牌区和发牌区的纸牌不能点击
		return false
	end

	if DealerController.judgePickUp(cardSp.data_) ~= DealerController.PICK_ABLE then
		cardSp:shake(true)
		GameManager:getAudioData():playAudio(common.effectSoundList.shake_card)
		return false
	end

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
	self.light_ = self:addLight_(cardSp.data_)
	return true
end

function BattleManagerSpider:cardTouchMoving( cardSp, x, y )
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

function BattleManagerSpider:cardTouchEnd( cardSp, x, y )
	local startHeadIndex = cardSp.data_.headIndex_
	if self.click_ then
		--点击结束，判断牌桌和集牌区
		local ok, selectCard, headIndex, moveLock = self:findLink_(cardSp.data_)
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
		for i=BattleManagerSpider.HEAD_COLUMN_1,BattleManagerSpider.HEAD_COLUMN_MAX do
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
		if headIndex == 0 then
			headIndex = areaIndex
			selectCard = areaSelectCard
		end
		if headIndex > 0 and headIndex <= BattleManagerSpider.HEAD_COLUMN_MAX and DealerController.judgePutDown(selectCard,cardSp.data_) then
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

	self:moveCards(card, startHeadIndex)
	self:clearLight_(true)
	self:cleanTouchData_()
end

function BattleManagerSpider:moveCards( card,startHeadIndex )
	if not card then
		return
	end
	local headIndex = card.headIndex_

	local pos = self:getRootPos(headIndex)
	if card:getBeforeCard() and headIndex <= BattleManagerSpider.HEAD_COLUMN_MAX then
		pos.y = card:getBeforeCard():getView():getPositionY()
	end

	local beginPos = ccp(card:getView():getPosition())
	local cardBefore = card:getBeforeCard()

	while card and not tolua.isnull(card:getView()) do
		if card:getBeforeCard() and headIndex <= BattleManagerSpider.HEAD_COLUMN_MAX then
			pos.y = pos.y - self:getCardOffsetY_(card:getBeforeCard():getProperty("board"))
		end
		self:startMoving()
		local moveTo = CCEaseSineInOut:create(CCMoveTo:create(0.15, pos))
		local call = CCCallFunc:create(function ( )
			self:endMoving(startHeadIndex, headIndex)
			self:playPartical_(headIndex, startHeadIndex)
			if not cardBefore then
				local score = self:checkMoveNeedAddScore(startHeadIndex, headIndex)
				if score > 0 then
					self:playScoreAction(beginPos, pos, score)
				end
			end
		end)

		local score = self:checkMoveNeedAddScore(startHeadIndex, headIndex)
		if score < 0 then
			self:playScoreAction(beginPos, pos, score)
		end
		
		card:getView():stopAllActions()
		if card:getNextCard() then
			card:getView():runAction(moveTo)
		else
			card:getView():runAction(transition.sequence({moveTo, call}))
		end
		card = card:getNextCard()
	end

	self:reOrderZOrder_(self.headsList_[headIndex])
end

function BattleManagerSpider:cardTouchCancel( cardSp, x, y )
	self:cardTouchEnd(cardSp, x, y)
end

function BattleManagerSpider:judgeCollect_(headIndex)
	if headIndex > BattleManagerSpider.HEAD_COLUMN_MAX then
		--只有牌桌区的卡牌可以收集
		return false, nil
	end
	--spider的可收集是从k到A的同花色，判断list从最后一张向上查到k则可收集
	--1 从头查找本列可移动的牌
	local headCard = DealerController.findCanMoveCardByHead(self.headsList_[headIndex])
	--2 判断该牌是否为K
	if headCard and DealerController.judgeRankEquiK(headCard) then
		--3 获取排尾的牌
		local tailCard = DealerController.getQueueEndCardVO(headCard)
		--4 判断是否是A
		if tailCard and DealerController.judgeRankEquiA(tailCard) then
			--可以收起一列
			return true, headCard
		end
	end
	return false, nil
end

local function judgeMove_(curCard,list)
	if curCard.headIndex_ > BattleManagerSpider.HEAD_COLUMN_MAX then
		--只有牌桌区的卡牌可以收集
		return false, nil, 0
	end
	local cacheResult_ = false
	local cacheCard_ = nil
	local cacheIndex_ = 0
	local cacheLen_ = -1
	for i=BattleManagerSpider.HEAD_COLUMN_1,BattleManagerSpider.HEAD_COLUMN_MAX do
		if DealerController.judgePickUp(curCard) == DealerController.PICK_ABLE then
			--判断序列是否可被拾取
			if i ~= curCard.headIndex_ then
				local card = list[i]
				if card then
					card = DealerController.getQueueEndCardVO(card)
				end
				if DealerController.judgePutDown(card,curCard) then
					cacheResult_ = true
					--优先选择能够长度长的列（可拾取）
					local canMoveCard_ = DealerController.findCanMoveCardByHead(list[i])
					local sameSuit_ = true
					if canMoveCard_ and canMoveCard_:getSuit() ~= curCard:getSuit() then
						sameSuit_ = false
					end
					local len = 0
					if sameSuit_ then
						len = DealerController.getQueueLenByHead(canMoveCard_)
					end
					if len > cacheLen_ then
						cacheCard_ = card
						cacheIndex_ = i
						cacheLen_ = len
					end
				end
			end
		end
	end
	return cacheResult_, cacheCard_, cacheIndex_
end

function BattleManagerSpider:findLink_( curCard )
	-- if curCard.headIndex_ >= BattleManagerSpider.HEAD_COLLECT_1 and curCard.headIndex_ <= BattleManagerSpider.HEAD_COLLECT_MAX then
	-- 	--点击的时候不允许集卡区的牌移动，但可以拖动移动，减少计算量
	-- 	return false, nil, 0
	-- end
	if not curCard then
		return false, nil, 0
	end
	local _b,_c,_i = judgeMove_(curCard,self.headsList_)
	return _b,_c,_i
end

function BattleManagerSpider:addLightSlot_(node)
	if not node then
		return
	end
	if node.light then
		node.light:removeSelf(true)
		node.light = nil
	end
	local size = node:getContentSize()
	local rect = CCRectMake(20, 20, 5, 4)
	node.light = display.newScale9Sprite("#poker_shine.png", 0, 0, CCSizeMake(size.width+16, size.height+14), rect)
	node.light:setAnchorPoint(ccp(0.5, 0))
	node.light:setPosition(ccp(size.width/2, -7))
	node:addChild(node.light, 5)
	node.light:setOpacity(0)
	local fadeOut = CCFadeOut:create(0.5)
	local fadeIn = CCFadeIn:create(0.5)
	local action = CCRepeat:create(transition.sequence({fadeIn, fadeOut}), 2)
	local que = transition.sequence({
				action,
				CCCallFunc:create(function()
							node.light:removeSelf(true)
							node.light = nil
						end),
			})
	node.light:runAction(que)
end

function BattleManagerSpider:addLight_( card, node )
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

function BattleManagerSpider:clearLight_(openTimeJudge)
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
	if self.tipsNode_ then
		self.tipsNode_:stopAllActions()
		self.tipsNode_:removeSelf()
		self.tipsNode_ = nil
	end
end

BattleManagerSpider.COLLECT_VALUE = 100 --收一列牌
BattleManagerSpider.FLIPCARD_VALUE = 0 --造成一次翻牌
BattleManagerSpider.STEP_VALUE = -1 --走一步
BattleManagerSpider.REVOKE_VALUE = -1 --撤销一步
BattleManagerSpider.REVOKE_DEAL_VALUE = 0 --撤销发牌

function BattleManagerSpider:calculateScore_(card_before, card_next, headIndex )
	local score = 0
	if headIndex >= BattleManagerSpider.HEAD_COLLECT_1 and headIndex <= BattleManagerSpider.HEAD_COLLECT_MAX then
		--收牌
		score = score + BattleManagerSpider.COLLECT_VALUE
	end
	if card_next.headIndex_ >= BattleManagerSpider.HEAD_COLUMN_1 and card_next.headIndex_ <= BattleManagerSpider.HEAD_COLUMN_MAX then
		if card_next:getBeforeCard() then
			if card_next:getBeforeCard():getProperty("board") == CardVO.BOARD_BACK then
				--当前牌上一张是背面
				--造成牌面翻转加分数
				score = score + BattleManagerSpider.FLIPCARD_VALUE
			end
		end
		if headIndex >= BattleManagerSpider.HEAD_COLUMN_1 and headIndex <= BattleManagerSpider.HEAD_COLUMN_MAX then
			--走一步的分数
			score = score + BattleManagerSpider.STEP_VALUE
		end
	end

	return score
end

--处理两张卡牌的链接以及头部索引的操作
function BattleManagerSpider:linkTwoCard(card_before, card_next, headIndex, notRecordStep )
	if not card_next then
		return
	end
	if card_before and card_before:getNextCard() then
		return
	end
	local startIndex = card_next:getProperty("headIndex")
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
		GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):changeCacheStatusByCardVO(card_before)
	end
	if headIndex then
		local card = card_next
		while card do
			card:setProperty("headIndex", headIndex)
			card = card:getNextCard()
		end
		--判断是否翻牌
		if startIndex >= BattleManagerSpider.HEAD_COLUMN_1 and startIndex <= BattleManagerSpider.HEAD_COLUMN_MAX then
			if card_next:getBeforeCard() and card_next:getBeforeCard():getProperty("board") == CardVO.BOARD_BACK then
				card_next:getBeforeCard():changeBoardTo(CardVO.BOARD_FACE)
				GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):changeCacheStatusByCardVO(card_next:getBeforeCard())
				userCacheStepVO:setProperty("beforeIsFlip", 1)
			end
		end
	end
	--音效
	GameManager:getAudioData():playAudio(common.effectSoundList.success)
	self:palyCollectAudio(headIndex)

	DealerController.linkTwoCard(card_before, card_next)
	if not card_next:getBeforeCard() then
		--重置头
		self.headsList_[card_next:getProperty("headIndex")] = card_next
	end

	--保存牌面信息
	GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):changeCacheStatusByCardVO(card_next)
	--保存步骤信息
	userCacheStepVO:setProperty("stepEnd", card_next:getProperty("headIndex"))
	userCacheStepVO:setProperty("count", DealerController.getQueueLenByHead(card_next))


	if not notRecordStep then
		GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):saveCacheStep(userCacheStepVO)
		GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):addStepCount(1)
		GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):carryOnScore(userCacheStepVO:getProperty("score"))
	end
	local sec = GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):getRunningTime()
	GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):changeCacheData({gameTime = sec})
	self:updateBtnStatus_()
end

function BattleManagerSpider:didAddCardToOpen( notReOrder )
	
end

--将开放区的牌回复到锁区
function BattleManagerSpider:putCardToLock( count, notRecordStep )
	
end

--将锁区的牌撤销到开放区
function BattleManagerSpider:putCardToOpen( count, notRecordStep )

end

function BattleManagerSpider:setDelegate( delegate )
	self.delegate_ = delegate
end

function BattleManagerSpider:reOrderZOrder_( cardVO, zOrder )
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

function BattleManagerSpider:updateBtnStatus_( )
	if self.delegate_ and self.delegate_.setBtn5Enabled then
		local stepData = GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):getCacheStepByLast()
		if stepData then
			self.delegate_:setBtn5Enabled(true)
		else
			self.delegate_:setBtn5Enabled(false)
		end
	end
	EventNoticeManager:getInstance():dispatchEvent({name = Notice.GAME_DATA_CHANGE})
end

function BattleManagerSpider:tapChange( )
end

function BattleManagerSpider:startMoving( )
	self.cardMoving_ = true
end

function BattleManagerSpider:dealOffsetY( headIndex_ )
	--当一个队列过长的时候回压缩y方向的偏移
	if headIndex_ and headIndex_ >= BattleManagerSpider.HEAD_COLUMN_1 and headIndex_ <= BattleManagerSpider.HEAD_COLUMN_MAX then
		local height = 0
		local lenght_face = 0
		local lenght_back = 0
		local card = self.headsList_[headIndex_]
		while card do
			height = card:getView():getContentSize().height
			if card.board_ == CardVO.BOARD_FACE then
				lenght_face = lenght_face + self:getCardOffsetY_(card.board_)
			else
				lenght_back = lenght_back + self:getCardOffsetY_(card.board_)
			end
			card = card:getNextCard()
		end
		local posY = self:getRootPos(headIndex_).y
		local scal = 1
		if posY - lenght_back - 10 < lenght_face + height/2 then
			scal = (posY - lenght_back - 10)/(lenght_face + height/2)
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
		--刷新遮罩，从最后一张向上遍历，能够连接的则隐藏遮罩
		card = self.headsList_[headIndex_]
		card = DealerController.getQueueEndCardVO(card)
		local result = DealerController.PICK_ABLE
		while card do
			if result == DealerController.PICK_ABLE then
				result = DealerController.judgePickUp(card)
			end
			card:getView():setCardMaskVisible(result ~= DealerController.PICK_ABLE and card:getProperty("board") == CardVO.BOARD_FACE)
			card = card:getBeforeCard()
		end
	end
end

function BattleManagerSpider:endMoving(startHeadIndex, headIndex )
	if startHeadIndex then
		self:dealOffsetY(startHeadIndex)
		if headIndex ~= startHeadIndex then
			self:dealOffsetY(headIndex)
		end
	end
	self.cardMoving_ = false
	if startHeadIndex and startHeadIndex >= BattleManagerSpider.HEAD_COLLECT_1 and startHeadIndex <= BattleManagerSpider.HEAD_COLLECT_MAX then
		--如果起始列是收集区则是撤销操作，不再判断是否能够收集，在执行一次撤销操作
		self:tapRevoke()
	else
		self:analysisCollectCard_(headIndex)
	end
	if headIndex and headIndex >= BattleManagerSpider.HEAD_COLLECT_1 and headIndex <= BattleManagerSpider.HEAD_COLLECT_MAX then
		--只有当收齐了一列牌才会判断是否赢了
		self:analysisWin_()
	end
	-- self:judgeEnd()
end

--暂停游戏
function BattleManagerSpider:pauseGame()
	GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):setStartTime(0)
end
--继续游戏
function BattleManagerSpider:resumeGame(force)
	local gameState = GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):getCacheData():getProperty("gameState")
	if gameState ~= UserCacheRecordVO.status_playing or not force then
		return
	end
	--此局生效，提交统计数据
	local isRepeat_ = GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):getCacheData():getProperty("isRepeat")
	if isRepeat_ == 0 then
		--快照数据
		GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):changeCacheData({isRepeat = 1})
		--游戏统计数据
		self:saveRecord("newGame")
	end
	GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):changeCacheData({gameState = UserCacheRecordVO.status_playing})
	GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):setStartTime(1)
	EventNoticeManager:getInstance():dispatchEvent({name = Notice.GAME_STATUS_CHANGE})
end

function BattleManagerSpider:tapRevoke()
	if self.cardMoving_ then
		return
	end
	local stepData = GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):getCacheStepByLast()
	if not stepData then
		return
	end
	self:resumeGame(true)
	GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):removeCacheStepByLast()
	-- --撤销操作有可能影响到自动收牌
	-- if self.btn_autoCollect:isVisible() == true then
	-- 	self.notNeedAnalysis = false
	-- end
	GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):carryOnScore(BattleManagerSpider.REVOKE_VALUE)
	--判断撤销的是否是发牌操作
	local isDealCard = stepData:getProperty("isDealCard") or 0
	if isDealCard == 1 then
		--需要撤销操作
		self:revokeDealCard()
		self.dealing_ = false
		return
	end

	--点击撤销按钮步数加一
	GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):addStepCount(-1)
	
	--将增加的分数返还
	GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):carryOnScore(-stepData:getProperty("score"))

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
	end
	self:linkTwoCard(card_before, card_next, stepData:getProperty("stepStart"), true)
	self:moveCards(card_next, stepData:getProperty("stepEnd"))
	self:clearLight_(true)
	GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):carryOnScore(BattleManagerSpider.REVOKE_VALUE)

end

function BattleManagerSpider:tapHint()
	-- self:clearLight_(true)
	self:autoTips(false)
end

--发牌去无牌且玩牌区仅剩一列时，视为最后一步
function BattleManagerSpider:judgeLastStep_()
	local isChange_ = false
	for i=BattleManagerSpider.HEAD_CHANGE_1,BattleManagerSpider.HEAD_CHANGE_MAX do
	if self.headsList_[i] then
			isChange_ = true
			break
		end
	end
	if not isChange_ then
		local colNum_ = 0
		for i=BattleManagerSpider.HEAD_COLUMN_1,BattleManagerSpider.HEAD_COLUMN_MAX do
			if self.headsList_[i] then
				colNum_ = colNum_ + 1
			end
		end
		if colNum_ <= 1 then
			return true
		end
	end
	return false
end

function BattleManagerSpider:judgeEnd()
	
	--最后一步，不做无牌可走判断
	if self:judgeLastStep_() then
		return
	end

	local ok, before_card, index
	local next_card = nil
	local node = nil

	local cache_before_card, cache_index, cache_next_card
	local cache_len = -1
	-- 提示
	--1判断玩牌区 spider的提示只有牌桌上的牌移动和发牌区发牌的提示
	for i=BattleManagerSpider.HEAD_COLUMN_1,BattleManagerSpider.HEAD_COLUMN_MAX do
		local card = self.headsList_[i]
		--该队列可移动的牌头
		card = DealerController.findCanMoveCardByHead( card )
		local len = DealerController.getQueueLenByHead(card)
		local cache_ok = false
		while card and not cache_ok do
			--判断整个队列是否可连接到别的队列
			cache_ok, cache_before_card, cache_index = self:findLink_(card)
			cache_next_card = card
			if cache_ok then
				local sameSuit_ = true
				if cache_before_card and cache_before_card:getSuit() ~= card:getSuit() then
					sameSuit_ = false
				end
				--点数相同时判断连牌的长度
				local sub_len = DealerController.getQueueLenByHead(card)
				--目标列可移动牌的长度
				local canMoveCard = DealerController.findCanMoveCardByHead( self.headsList_[cache_index] )
				local target_len = 0
				if sameSuit_ then
					target_len = DealerController.getQueueLenByHead(canMoveCard)
				end
				if target_len + sub_len < len then--组成的新列长度小于原始列
					cache_ok = false
				elseif target_len + sub_len == len then
					--一般移动之后组成的链的长度相等时就不提示了，但是假如目标列是空的(排除在空列来回移动)则还是可以提示
					if card:getBeforeCard() then
						if card:getBeforeCard():getProperty("board") == CardVO.BOARD_FACE and
							card:getBeforeCard():getProperty("rank") == card:getProperty("rank")+1 and 
							cache_before_card then
							cache_ok = false
						end
					else
						if not cache_before_card then
							cache_ok = false
						end
					end
				end

				--遍历所有列，找出组成的最长列
				if cache_ok and cache_len < target_len + sub_len then
					cache_len = target_len + sub_len
					before_card = cache_before_card
					index = cache_index
					next_card = cache_next_card
					ok = cache_ok
				end
			end
			card = card:getNextCard()
		end
	end


	--2 是否有牌可发
	if not ok then
		local card = self:getDealCardHead()
		if card then
			return false
		end
	end

	if not ok then
		GameManager:getInstance():popNoWayAlert(false)
		return true
	end
	return false
end

function BattleManagerSpider:autoTips( isRepeat )
	if GameManager:getInstance():supportTips() == false then
		return
	end
	if self.light_ or self.tipsNode_ then
		return
	end
	local ok, before_card, index
	local next_card = nil
	local node = nil

	local cache_before_card, cache_index, cache_next_card
	local cache_len = -1
	-- 提示
	--1判断玩牌区 spider的提示只有牌桌上的牌移动和发牌区发牌的提示
	for i=BattleManagerSpider.HEAD_COLUMN_1,BattleManagerSpider.HEAD_COLUMN_MAX do
		local card = self.headsList_[i]
		--该队列可移动的牌头
		card = DealerController.findCanMoveCardByHead( card )
		local len = DealerController.getQueueLenByHead(card)
		local cache_ok = false
		while card and not cache_ok do
			--判断整个队列是否可连接到别的队列
			cache_ok, cache_before_card, cache_index = self:findLink_(card)
			cache_next_card = card
			if cache_ok then
				local sameSuit_ = true
				if cache_before_card and cache_before_card:getSuit() ~= card:getSuit() then
					sameSuit_ = false
				end
				--点数相同时判断连牌的长度
				local sub_len = DealerController.getQueueLenByHead(card)
				--目标列可移动牌的长度
				local canMoveCard = DealerController.findCanMoveCardByHead( self.headsList_[cache_index] )
				local target_len = 0
				if sameSuit_ then
					target_len = DealerController.getQueueLenByHead(canMoveCard)
				end
				if target_len + sub_len < len then--组成的新列长度小于原始列
					cache_ok = false
				elseif target_len + sub_len == len then
					--一般移动之后组成的链的长度相等时就不提示了，但是假如目标列是空的(排除在空列来回移动)则还是可以提示
					if card:getBeforeCard() then
						if card:getBeforeCard():getProperty("board") == CardVO.BOARD_FACE and
							card:getBeforeCard():getProperty("rank") == card:getProperty("rank")+1 and 
							cache_before_card then
							cache_ok = false
						end
					else
						if not cache_before_card then
							cache_ok = false
						end
					end
				end

				--遍历所有列，找出组成的最长列
				if cache_ok and cache_len < target_len + sub_len then
					cache_len = target_len + sub_len
					before_card = cache_before_card
					index = cache_index
					next_card = cache_next_card
					ok = cache_ok
				end
			end
			card = card:getNextCard()
		end
	end


	--2 是否有牌可发
	if not ok then
		local card = self:getDealCardHead()
		if card then
			--发牌提示
			card = DealerController.getQueueEndCardVO(card)
			self.light_ = self:addLightSlot_(card:getView())
			return
		end
	end

	local cardNum_ = 0
	for i=BattleManagerSpider.HEAD_COLUMN_1,BattleManagerSpider.HEAD_COLUMN_MAX do
		cardNum_ = cardNum_ + DealerController.getQueueLenByHead(self.headsList_[i])
	end
	if cardNum_ == 0 then
		return
	end

	if not ok then
		if not isRepeat then
			GameManager:getInstance():popNoWayAlert(false)
		end
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
	local pos = self:getRootPos(index)
	if before_card then
		pos.x, pos.y = before_card:getView():getPosition()
		if index <= BattleManagerSpider.HEAD_COLUMN_MAX then
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
	-- 
	
	self.tipsNode_:runAction(seq_)
end

function BattleManagerSpider:tapAutoCollect()
	self.btn_autoCollect:setVisible(false)
	self:autoCollectCard()
end

function BattleManagerSpider:tapDealCard()
	local card = self:getDealCardHead()
	if not card or self.dealing_ then
		return
	end
	local unlimitedDeal = GameManager:getUserData():getProperty("unlimitedDeal") or 0
	if unlimitedDeal == 0 then
		for i=BattleManagerSpider.HEAD_COLUMN_1,BattleManagerSpider.HEAD_COLUMN_MAX do
			if not self.headsList_[i] then
				DisplayManager.showAlertBox("禁止发牌提示",1)
				return
			end
		end
	end

	self:clearLight_()
	local startHeadIndex = card:getProperty("headIndex")
	--组装步骤信息
	local userCacheStepVO = UserCacheStepVO.new()
	userCacheStepVO:setProperty("isDealCard", 1)
	GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):saveCacheStep(userCacheStepVO)
	GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):addStepCount(1)
	--发一轮牌
	self.dealing_ = true
	for i=BattleManagerSpider.HEAD_COLUMN_1,BattleManagerSpider.HEAD_COLUMN_MAX do
		local card_next = DealerController.getQueueEndCardVO(self.headsList_[startHeadIndex])
		local card_before = DealerController.getQueueEndCardVO(self.headsList_[i])
		card_next:changeBoardTo(CardVO.BOARD_FACE)
		self:linkTwoCard(card_before, card_next, i, true)
		card_next:getView():performWithDelay(function ()
			self:moveCards(card_next, startHeadIndex)
			card_next:getView():setZOrder(1)
			card_next:getView():runAction(transition.sequence({
				CCDelayTime:create(0.15),
				CCCallFunc:create(function ( )
					card_next:getView():setZOrder(0)
					if i == BattleManagerSpider.HEAD_COLUMN_MAX then
						self.dealing_ = false
					end
				end)
				}))
		end, 0.02*(i-1))
	end
end

function BattleManagerSpider:revokeDealCard()
	local index = self:getVoidDealIndex()
	if not index then
		return
	end
	GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):addStepCount(-1)
	GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):carryOnScore(BattleManagerSpider.REVOKE_DEAL_VALUE)
	for i=BattleManagerSpider.HEAD_COLUMN_MAX,BattleManagerSpider.HEAD_COLUMN_1, -1 do
		local card_next = DealerController.getQueueEndCardVO(self.headsList_[i])
		local card_before = DealerController.getQueueEndCardVO(self.headsList_[index])
		card_next:changeBoardTo(CardVO.BOARD_BACK)
		self:linkTwoCard(card_before, card_next, index, true)
		self:moveCards(card_next, i)
	end
end

function BattleManagerSpider:analysisCollectCard_( headIndex )
	--spider没有自动收牌功能,这里判断的是能否收起一列
	if not headIndex then
		return
	end
	local collect, collectCard = self:judgeCollect_(headIndex)
	if collect then
		local targetIndex = self:getVoidCollectIndex()
		if targetIndex then
			self:linkTwoCard(nil, collectCard, targetIndex)
			self:moveCards(collectCard, headIndex)
		end
	end
end

function BattleManagerSpider:analysisWin_( )
	local win = true
	--牌桌和换牌区都没有卡牌的时候胜利
	for i=BattleManagerSpider.HEAD_COLUMN_1,BattleManagerSpider.HEAD_COLUMN_MAX do
		if self.headsList_[i] then
			win = false
			break
		end
	end
	if win then
		for i=BattleManagerSpider.HEAD_CHANGE_1,BattleManagerSpider.HEAD_CHANGE_MAX do
		if self.headsList_[i] then
				win = false
				break
			end
		end
	end
	if win then
		printf("恭喜，获得胜利")
		self.btn_autoCollect:setVisible(false)
		self:pauseGame()
		self:uploadSeed()
		
		local sec = GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):getRunningTime()
		--计时模式下的奖励分数
		GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):carryOnScore(GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):getSpiderTimeEndScore())
		EventNoticeManager:getInstance():dispatchEvent({name = Notice.GAME_DATA_CHANGE})
		--提交统计数据
		local isWin_ = GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):getCacheData():getProperty("isWin")
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
		local isDailyChallenge = GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):isDailyChallenge()
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
		for i=BattleManagerSpider.HEAD_COLLECT_1,BattleManagerSpider.HEAD_COLLECT_MAX do
			local card = self.headsList_[i]
			list[#list + 1] = {suit=card.suit_}
		end
		GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):cacheRecordData(heigh, data, radom_, list,isFirstWin_)
		
		self:showStuffAnimation()

        -- if DEBUG ~= 1 then
        	GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):cleanData()
        -- end
		GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):changeCacheData({gameState = UserCacheRecordVO.status_end, gameTime = sec, isWin = isWin_})
		EventNoticeManager:getInstance():dispatchEvent({name = Notice.GAME_STATUS_CHANGE})
	end
end

function BattleManagerSpider:showWinDialog( )
	local needCoin_ = false
	if GAME_MODE == GAME_MODE_COLLECTION then
		needCoin_ = true
	end
    local viewCtrl = WinViewCtrl.new(needCoin_)
    display.getRunningScene():addChild(viewCtrl:getView())
    GameManager:getUserData():addPraiseWinCount()
end

function BattleManagerSpider:showStuffAnimation( )
	
	local list = GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):getProperty("stuffData") or {}
	local index = 1
	for i=BattleManagerSpider.HEAD_COLLECT_1,BattleManagerSpider.HEAD_COLLECT_MAX do
		-- local card = self.headsList_[i]
		list[index].pos = self:getRootPos(i)
		index = index + 1
	end
	--洗牌动画的载体节点
	local node = display.newNode()
	node:setContentSize(self.card_table:getContentSize())
	node:setPosition(self:getPosition())
	node:setScale(self:getScale())
	display.getRunningScene():addChild(node)

	local radom = GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):getProperty("aniNum") or 1
	self:initSuccesAni_(list,node,radom)
end

function BattleManagerSpider:initSuccesAni_(list,node,radom)
	GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):setEndAniStatus(BattleManagerSpider.END_ANI_STUFF)
	--屏蔽触摸和按钮
    local touchNode = self:addTouchLayer_(display.getRunningScene(), ccc4(0, 0, 0, 0))

	--洗牌动画播放完毕之后的结算动画
	function endCallBack_( node )
		self.headsList_ = {}
		
		node:removeSelf()
		touchNode:removeSelf()
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
                GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):setEndAniStatus(BattleManagerSpider.END_ANI_DIALOG)
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

function BattleManagerSpider:saveRecord(name)
	local suitCount = GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):getCacheData():getProperty("suitCount") or 1
	if name == "newGame" then
		GameManager:getUserClassicData():addSpiderCount(1, suitCount)
	elseif name == "win" then
		GameManager:getUserClassicData():addSpiderWinCount(1, suitCount)
	elseif name == "record" then
		local high = false
		local step_ = GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):getCacheStepCount()
		local sec_ = GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):getRunningTime()

		local spider_cacheData = GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):getCacheData()
        stepCount = spider_cacheData:getProperty("move")
        step_ = stepCount

		GameManager:getUserClassicData():addSpiderFewestMove(step_, suitCount)
		GameManager:getUserClassicData():addSpiderFewestTime(sec_, suitCount)
		--普通模式
		local score_ = GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):getCacheData():getProperty("score")
		score_ = score_ + GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):getTimeScore()
		high = GameManager:getUserClassicData():addSpiderHighestScore(score_, suitCount)
		--保存排行榜信息
		local timeTemp = os.time()
		local userClassicRankVO = UserClassicRankVO.new({score=score_, moves = step_, time = sec_, createdTimestamp = timeTemp})
		GameManager:getUserClassicData():saveRankData(userClassicRankVO,UserClassicRankVO["MODE_SPIDER"..suitCount])

		local list = GameManager:getUserClassicData():getProperty("spiderRankList"..suitCount) or {}
		local totalScore = 0
		local rankMode = GameCenterDefine.getLeaderBoardId()["spider"..suitCount]
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
function BattleManagerSpider:uploadSeed()
	local cacheData = GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):getCacheData()
	local suitCount = cacheData:getProperty("suitCount") or 1
	local isDeal = cacheData:getProperty("isDeal")
	local isNewPlayer = cacheData:getProperty("isNewPlayer")
	if isDeal > 0 or isNewPlayer >0 then
		--活局不用上传种子
		printf("不做胜利种子保存")
		return
	end
	local userDealSeedVO = UserDealSeedVO.new()
	local seed = GameManager:getUserGameCacheData(GameManager.MODETYPE_SPIDER):getCacheData():getProperty("seed") or ""
	local mode = UserCacheRecordVO["mode_spider"..suitCount]
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
		if mode == UserCacheRecordVO.mode_spider2 then
			keyName = "spider2"
		elseif mode == UserCacheRecordVO.mode_spider3 then
			keyName = "spider3"
		elseif mode == UserCacheRecordVO.mode_spider4 then
			keyName = "spider4"
		else
			keyName = "spider1"
		end
		if not param[keyName] then
			param[keyName] = {}
		end
		local len = #param[keyName]+1
		param[keyName][len] = seedList[i]:getProperty("seed")
	end

	GameManager:getNetWork():saveSeed(param)
end

function BattleManagerSpider:addTouchLayer_( parent, corlor )
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

function BattleManagerSpider:autoCollectCard( )
end

function BattleManagerSpider:playPartical_( headIndex, startIndex )
	if headIndex < BattleManagerSpider.HEAD_COLLECT_1 or headIndex > BattleManagerSpider.HEAD_COLLECT_MAX 
		or headIndex == startIndex then
		return
	end
	local pos = self:getRootPos(headIndex)
    local partical = CCParticleSystemQuad:create("animation/particle_shoupai.plist")
    self.card_table:addChild(partical, -1)
    partical:setPosition(pos)
    partical:runAction(transition.sequence({CCDelayTime:create(1.2),
    	CCCallFunc:create(function ( )
    		partical:removeSelf()
    	end)}))
end

function BattleManagerSpider:palyCollectAudio( headIndex, collecting )
	if headIndex < BattleManagerSpider.HEAD_COLLECT_1 or headIndex > BattleManagerSpider.HEAD_COLLECT_MAX then
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

function BattleManagerSpider:checkMoveNeedAddScore(startHeadIndex, endHeadIndex)
	local isFishdom = PackageConfigDefine.isSolitaireFishdom()
	if not isFishdom then
		return 0
	end

	if endHeadIndex >= BattleManagerSpider.HEAD_COLLECT_1 and endHeadIndex <= BattleManagerSpider.HEAD_COLLECT_MAX then
		return BattleManagerSpider.COLLECT_VALUE
	elseif startHeadIndex >= BattleManagerSpider.HEAD_COLLECT_1 and startHeadIndex <= BattleManagerSpider.HEAD_COLLECT_MAX then
		return -BattleManagerSpider.COLLECT_VALUE
	end
	return 0
end

function BattleManagerSpider:playScoreAction(posBegin, posEnd, scoreNum)
	local isFishdom = PackageConfigDefine.isSolitaireFishdom()
	if not self.card_table or not isFishdom then
		return
	end
	common.scoreAction(self.card_table, posBegin, posEnd, scoreNum)
end

return BattleManagerSpider