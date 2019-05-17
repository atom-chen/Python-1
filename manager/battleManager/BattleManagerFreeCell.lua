--
-- Author: Huang Hai Long
-- Date: 2016-08-29 16:57:51
--
local BattleManagerFreeCell = class("BattleManagerFreeCell",function()
	return display.newNode()
end)

BattleManagerFreeCell.HEAD_COLUMN_1 = 1		--牌桌
BattleManagerFreeCell.HEAD_COLUMN_2 = 2
BattleManagerFreeCell.HEAD_COLUMN_3 = 3
BattleManagerFreeCell.HEAD_COLUMN_4 = 4
BattleManagerFreeCell.HEAD_COLUMN_5 = 5
BattleManagerFreeCell.HEAD_COLUMN_6 = 6
BattleManagerFreeCell.HEAD_COLUMN_7 = 7
BattleManagerFreeCell.HEAD_COLUMN_MAX = 8

BattleManagerFreeCell.HEAD_COLLECT_1 = 9	--集牌区
BattleManagerFreeCell.HEAD_COLLECT_2 = 10
BattleManagerFreeCell.HEAD_COLLECT_3 = 11
BattleManagerFreeCell.HEAD_COLLECT_MAX = 12

BattleManagerFreeCell.HEAD_CHANGE_1 = 13	--存牌区
BattleManagerFreeCell.HEAD_CHANGE_2 = 14	
BattleManagerFreeCell.HEAD_CHANGE_3 = 15	
BattleManagerFreeCell.HEAD_CHANGE_MAX = 16	


BattleManagerFreeCell.END_ANI_NONE = 0
BattleManagerFreeCell.END_ANI_COLLECTING = 1--收集
BattleManagerFreeCell.END_ANI_STUFF = 2--洗牌
BattleManagerFreeCell.END_ANI_DIALOG = 3--结算窗
BattleManagerFreeCell.END_ANI_END = 4--结束

function BattleManagerFreeCell:ctor(delegate )
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

function BattleManagerFreeCell:onEnter( )
	EventNoticeManager:getInstance():addEventListener(self,Notice.APP_ENTER_BACKGROUND,handler(self, self.gameEnterBackground_))
	EventNoticeManager:getInstance():addEventListener(self,Notice.USER_DATA_CHANGE,handler(self, self.leftModeChanged))
	EventNoticeManager:getInstance():addEventListener(self,Notice.USER_LANGUAGE_CHANGE,handler(self, self.setLocalization_))
    EventNoticeManager:getInstance():addEventListener(self,Notice.USER_CARD_CHANGE,handler(self, self.updataAllCards))
    

end

function BattleManagerFreeCell:setLocalization_( )
	self:setBtnTitle(self.btn_autoCollect, "自动收牌")
end

function BattleManagerFreeCell:onExit( )
	EventNoticeManager:getInstance():removeEventListenerForHandle(self)
end

function BattleManagerFreeCell:getHeadsList()
	return self.headsList_ or {}
end

function BattleManagerFreeCell:updataAllCards(event)
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

function BattleManagerFreeCell:gameEnterBackground_( )
	local sec = GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):getRunningTime()
	GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):changeCacheData({gameTime = sec})

	GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):saveCache()
	GameManager:getUserChallengeData():saveCache()
end

function BattleManagerFreeCell:starNewGame( seed, resetAll )
	GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):cleanData()
	self:clearLight_()
	self:stopAllActions()
	self.card_table:removeAllChildren()
	self.headsList_ = {}
	--是否展示移动动画
	self.showMoveAni_ = true
	self.cardMoving_ = false
	GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):cleanRecordData()
	--初始化牌组
	self:startGame(seed, resetAll)
end

function BattleManagerFreeCell:initView_( )
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
	local root = reader:load("ccb/battleFreeCellView.ccbi","battleFreeCellView",self,displaySize)
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
	for i=BattleManagerFreeCell.HEAD_COLUMN_1,BattleManagerFreeCell.HEAD_COLUMN_MAX do
		if self["column"..i] then
			self["column"..i]:setPositionY(size.height- offsetY)
		end
	end
	offsetY = 150
	if not isPortrait then
		offsetY = 130
	end
	for i=BattleManagerFreeCell.HEAD_COLLECT_1,BattleManagerFreeCell.HEAD_CHANGE_MAX do
		if self["column"..i] then
			self["column"..i]:setPositionY(size.height- offsetY)
		end
	end

end

--设置卡槽以及图标主题
function BattleManagerFreeCell:setCardsSlot(style)
	--槽
    for i=BattleManagerFreeCell.HEAD_COLUMN_1,BattleManagerFreeCell.HEAD_CHANGE_MAX do
        if self["column"..i] and self["column"..i].setTexture then
        	local type_ = "_cardback"
        	if i >= BattleManagerFreeCell.HEAD_COLLECT_1 and i <= BattleManagerFreeCell.HEAD_COLLECT_MAX then
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

function BattleManagerFreeCell:startGame( seed, resetAll )
	local endAniStatus = GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):getEndAniStatus() or BattleManagerFreeCell.END_ANI_NONE
	local list = GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):getCacheCardList_()
	if table.nums(list) <= 0 then
		--没有牌面信息需要判断是否播放结算动画
		if endAniStatus == BattleManagerFreeCell.END_ANI_STUFF then
			self:showStuffAnimation()
		elseif endAniStatus == BattleManagerFreeCell.END_ANI_DIALOG then
			-- self:showWinDialog(true)--胜利弹窗在切屏之后会自动弹出了，这里不处理了
		elseif endAniStatus == BattleManagerFreeCell.END_ANI_END then
			--todo
		else
			GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):resetCacheData(resetAll)
			self:initCard_(seed)
			--发牌
			self:startDealCard(true)
		end
	else
		-- local data = GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):getCacheStepByLast()
		-- if data then
		-- 	self.flipCardRound = data:getProperty("flipCardRound")
		-- else
		-- 	self.flipCardRound = 0
		-- end
		
		self:runReplay()
		--发牌
		self:startDealCard()
		--有牌面信息需要判断是否自动收牌
		if endAniStatus == BattleManagerFreeCell.END_ANI_COLLECTING then
			self:autoCollectCard()
		end
	end

end

function BattleManagerFreeCell:initCard_( _seed )
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
			_seed = userDM:getDealSeed(2)
		else
			isNewPlayer = GameManager:getUserClassicData():isNewPlayer()--就算是随机局也给新玩家使用活局种子
			if isNewPlayer then
				_seed = userDM:getDealSeed(2)
				printf("新手局使用种子：%s",_seed)
			end
		end
	end

	--洗牌
	list, seed_ = DealerController.shuffleCards(list, _seed)

	GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):changeCacheData({seed = seed_, gameState = UserCacheRecordVO.status_playing, isNewPlayer = ((isNewPlayer and 1) or 0)})
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

	for col=BattleManagerFreeCell.HEAD_COLUMN_1,BattleManagerFreeCell.HEAD_COLUMN_MAX do
		local before = nil
		local rowNum_ = 6
		if col < BattleManagerFreeCell.HEAD_COLUMN_5 then
			rowNum_ = 7
		end

		for num=1,rowNum_ do
			local cardVO = list[1]
			table.remove(list, 1)
			linkCard_(before, cardVO, col)
			--发牌结束之后会有翻牌动画，这里就不做处理了
			-- if num >= column then
			-- 	cardVO:setProperty("board", CardVO.BOARD_FACE)
			-- else
			-- 	cardVO:setProperty("board", CardVO.BOARD_BACK)
			-- end
			before = cardVO
		end
	end

	GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):changeCacheStatusByCardList(cacheList)
end

function BattleManagerFreeCell:isPortrait_( )
	return CONFIG_SCREEN_ORIENTATION == "portrait"
end

function BattleManagerFreeCell:getCardOffsetY_( face )
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

function BattleManagerFreeCell:getCardOffsetX_( )
	return 40
end

--左手模式变更了
function BattleManagerFreeCell:leftModeChanged( )
	local left_mode = GameManager:getUserData():getIsLeft()
	local width = self.card_table:getContentSize().width
	local maxCount = BattleManagerFreeCell.HEAD_COLUMN_MAX
	local startOffset_X = 41
	local space_X = 78
	if left_mode > 0 then
		if self.isLeft_ then
			return
		end
		self.isLeft_ = true
		--启用左手模式
		-- for i=BattleManagerFreeCell.HEAD_COLUMN_1,BattleManagerFreeCell.HEAD_COLUMN_MAX do
		-- 	self["column"..i]:setPositionX(width-width/maxCount/2*(2*i-1))
		-- end
		for i=BattleManagerFreeCell.HEAD_COLLECT_1,BattleManagerFreeCell.HEAD_COLLECT_MAX do
			local index = i - maxCount
			self["column"..i]:setPositionX(width-(startOffset_X + space_X*(index-1)))
		end
		for i=BattleManagerFreeCell.HEAD_CHANGE_1,BattleManagerFreeCell.HEAD_CHANGE_MAX do
			local index = i - BattleManagerFreeCell.HEAD_COLLECT_MAX
			self["column"..i]:setPositionX(startOffset_X + space_X*(index-1))
		end
	else
		if not self.isLeft_ then
			return
		end
		self.isLeft_ = false
		--关闭左手模式
		for i=BattleManagerFreeCell.HEAD_COLLECT_1,BattleManagerFreeCell.HEAD_COLLECT_MAX do
			local index = i - maxCount
			self["column"..i]:setPositionX(startOffset_X + space_X*(index-1))
		end

		for i=BattleManagerFreeCell.HEAD_CHANGE_1,BattleManagerFreeCell.HEAD_CHANGE_MAX do
			local index = i - BattleManagerFreeCell.HEAD_COLLECT_MAX
			self["column"..i]:setPositionX(width-(startOffset_X + space_X*(index-1)))
		end
	end
	self:reloadCardsPos()
	self:clearLight_()
end

function BattleManagerFreeCell:reloadCardsPos( )
	--牌桌上的卡牌
	for i=BattleManagerFreeCell.HEAD_COLUMN_1,BattleManagerFreeCell.HEAD_CHANGE_MAX do
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
			if i >= BattleManagerFreeCell.HEAD_COLUMN_1 and i <= BattleManagerFreeCell.HEAD_COLUMN_MAX then
				offset_pos.y = offset_pos.y - self:getCardOffsetY_(card:getProperty("board"))
			else
				offset_pos.y = 0
			end
			card = card:getNextCard()
		end
		self:dealOffsetY(i)
	end
	-- local card = self.headsList_[BattleManagerFreeCell.HEAD_CHANGE_1]
	-- if card then
	-- 	card = DealerController.getQueueEndCardVO(card)
	-- end
	-- local offsetX = 0
	-- while card do
	-- 	local sprite = card:getView()
	-- 	if sprite then
	-- 		sprite:setPosition(ccp(self["column"..BattleManagerFreeCell.HEAD_CHANGE_1]:getPositionX()-offsetX, 
	-- 			self["column"..BattleManagerFreeCell.HEAD_CHANGE_1]:getPositionY()))
	-- 	else
	-- 		printf("no card sprite!")
	-- 	end
	-- 	offsetX = offsetX + self:getCardOffsetX_()
	-- 	if offsetX > 2*self:getCardOffsetX_() then
	-- 		offsetX = 2*self:getCardOffsetX_()
	-- 	end
	-- 	card = card:getBeforeCard()
	-- end
end

function BattleManagerFreeCell:startDealCard( animation )
	self:stopAllActions()
	self.playing = false
	self:leftModeChanged()
	--此时才开始创建卡牌的形象
	if animation then
		self:startMoving()
		local zOrder = 52
		for i=BattleManagerFreeCell.HEAD_COLUMN_1,BattleManagerFreeCell.HEAD_CHANGE_MAX do
			local card = self.headsList_[i]
			while card do
				local sprite = card:getView()
				if sprite then
					sprite:setPosition(ccp(self.card_table:getContentSize().width/2, self.cardPos:getPositionY()-sprite:getContentSize().height))
					if not sprite:getParent() then
						-- printf("-------zOrder-------%s",tostring(zOrder))
						self.card_table:addChild(sprite)
						sprite:setZOrder(zOrder)
						zOrder = zOrder - 1
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
			if headIndex > BattleManagerFreeCell.HEAD_COLUMN_MAX then
				self:endMoving()
				touchNode:removeSelf(true)
				return
			end
			if not card then
				showAni(headIndex+1, self.headsList_[headIndex+1], 0, 0)
			else
				if card:getBeforeCard() then
					offsetX = offsetX + self:getCardOffsetY_(CardVO.BOARD_FACE)
				end
				local move = CCMoveTo:create(0.25, ccp(self["column"..headIndex]:getPositionX(), 
					self["column"..headIndex]:getPositionY() - offsetX))--count*self:getCardOffsetY_()))
				local delay = CCDelayTime:create(0.1)
				local flip = CCCallFunc:create(function ()
					card:changeBoardTo(CardVO.BOARD_FACE)
				end)
				local call = CCCallFunc:create(function ()
					GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):changeCacheStatusByCardVO(card)
				end)
				local callzOrder = CCCallFunc:create(function ()
					card:getView():setZOrder(0)
				end)
				if card:getNextCard() then
					card:getView():runAction(transition.sequence({delay,flip}))
					card:getView():runAction(transition.sequence({move,callzOrder}))
				else
					card:getView():runAction(transition.sequence({delay,flip}))
					card:getView():runAction(transition.sequence({move,callzOrder, call}))
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
		showAni(BattleManagerFreeCell.HEAD_COLUMN_1, self.headsList_[BattleManagerFreeCell.HEAD_COLUMN_1], 0, 0)

	else
		self:reloadCardsPos()
	end

	for i=BattleManagerFreeCell.HEAD_COLUMN_1,BattleManagerFreeCell.HEAD_CHANGE_MAX do
		--设置卡牌的回调
		local card = self.headsList_[i]
		while card do
			-- card:getView():setZOrder(0)
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

function BattleManagerFreeCell:runReplay( )
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
	local list = GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):getCacheCardList_()
	for k,v in pairs(list) do
		if v and #v > 0 then
			local before = nil
			for i=1,#v do
				local cardVO = v[i]
				if cardVO then
					cardVO:clearView()
					linkCard_(before, cardVO, k)
					cardVO:changeBoardTo(CardVO.BOARD_FACE)
					before = cardVO
				end
			end
		end
	end

	self.showMoveAni_ = true
end

function BattleManagerFreeCell:cleanTouchData_( )
	self.pre_x = 0
	self.pre_y = 0
	self.card_pre_x = {}
	self.card_pre_y = {}
	self.click_ = true
end

function BattleManagerFreeCell:cardTouchBegan( cardSp, x, y )
	self:resumeGame(true)
	-- if self.cardMoving_ then
	-- 	return false
	-- end
	if cardSp.data_.headIndex_ >= BattleManagerFreeCell.HEAD_COLLECT_1
		and cardSp.data_.headIndex_ <= BattleManagerFreeCell.HEAD_COLLECT_MAX then
		self.headsList_[cardSp.data_.headIndex_]:getView():shake(true)
		GameManager:getAudioData():playAudio(common.effectSoundList.shake_card)
		return false
	end

	if DealerController.judgePickUp(cardSp.data_) ~= DealerController.PICK_ABLE then
		cardSp:shake(true)
		GameManager:getAudioData():playAudio(common.effectSoundList.shake_card)
		return false
	end

	if cardSp.data_.headIndex_ >= BattleManagerFreeCell.HEAD_CHANGE_1 
		and cardSp.data_.headIndex_ <= BattleManagerFreeCell.HEAD_CHANGE_MAX
		and cardSp.data_.next_ then
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

function BattleManagerFreeCell:cardTouchMoving( cardSp, x, y )
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

local function getEmptyColumns_(list)
	local count_ = 0
	if not list then
		return count_
	end
	for i=BattleManagerFreeCell.HEAD_COLUMN_1,BattleManagerFreeCell.HEAD_COLUMN_MAX do
		if not list[i] then
			count_ = count_ + 1
		end
	end
	return count_
end

local function getEmptyFreeCells_(list)
	local count_ = 0
	if not list then
		return count_
	end
	for i=BattleManagerFreeCell.HEAD_CHANGE_1,BattleManagerFreeCell.HEAD_CHANGE_MAX do
		if not list[i] then
			count_ = count_ + 1
		end
	end
	return count_
end

local function getEmptyColumnsAndCells_(list)
	return getEmptyColumns_(list),getEmptyFreeCells_(list)
end

function BattleManagerFreeCell:cardTouchEnd( cardSp, x, y )
	local startHeadIndex = cardSp.data_.headIndex_
	if self.click_ then
		--点击结束，判断牌桌和集牌区
		local ok, selectCard, headIndex, moveLock = self:findLink_(cardSp.data_,BattleManagerFreeCell.ALL_CON)
		if ok then
			if selectCard then
				selectCard = DealerController.getQueueEndCardVO(selectCard)
			end
			self:linkTwoCard(selectCard, cardSp.data_, headIndex)
		else
			cardSp:shake(true)
			GameManager:getAudioData():playAudio(common.effectSoundList.shake_card)
			if moveLock then
				DisplayManager.showAlertBox("禁止移动提示",1)
			end
		end
	else
		--拖动结束，判断牌桌和集牌区
		local selectCard = nil
		local headIndex = 0
		local areaIndex = 0
		local areaSelectCard = nil
		local areaM_ = 0
		for i=BattleManagerFreeCell.HEAD_COLUMN_1,BattleManagerFreeCell.HEAD_CHANGE_MAX do
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

		--移动长度锁
		local moveLenLock = false
		local eColumns,eFreeCell = getEmptyColumnsAndCells_(self.headsList_)
		if not selectCard and eColumns > 0 then
			eColumns = eColumns - 1
		end
		local maxLen_ = DealerController.getQueueMoveLength(eColumns,eFreeCell)
		local moveLen_ = DealerController.getQueueLenByHead(cardSp.data_)
		-- printf("---eColumns[%d]--eFreeCell[%d]--maxLen_=[%d]--moveLen_[%d]", eColumns, eFreeCell, maxLen_, moveLen_)
		if moveLen_ > maxLen_ then
			moveLenLock = true
			DisplayManager.showAlertBox("禁止移动提示",1)
		end
		if (headIndex >= BattleManagerFreeCell.HEAD_COLUMN_1 and headIndex <= BattleManagerFreeCell.HEAD_COLUMN_MAX and DealerController.judgePutDownFreeCell(selectCard,cardSp.data_) and not moveLenLock) --玩牌区
			or(headIndex >= BattleManagerFreeCell.HEAD_COLLECT_1 and headIndex <= BattleManagerFreeCell.HEAD_COLLECT_MAX and DealerController.judgeCollectCard(selectCard,cardSp.data_)) then --集牌区
		
			if selectCard then
				selectCard = DealerController.getQueueEndCardVO(selectCard)
			end
			--可以插入队列
			self:linkTwoCard(selectCard, cardSp.data_, headIndex)
		elseif headIndex >= BattleManagerFreeCell.HEAD_CHANGE_1 and headIndex <= BattleManagerFreeCell.HEAD_CHANGE_MAX and not cardSp.data_:getNextCard() then --存牌区
			local card = self.headsList_[headIndex]
			if not card then
				self:linkTwoCard(selectCard, cardSp.data_, headIndex)
			end
		else
			--返回原队列
		end
	end
	local card = cardSp.data_

	self:moveCards(card, startHeadIndex)
	self:clearLight_(true)
	self:cleanTouchData_()
end

function BattleManagerFreeCell:moveCards( card,startHeadIndex )
	if not card then
		return
	end
	local headIndex = card.headIndex_

	local pos = ccp(0, 0)
	pos.x, pos.y = self["column"..headIndex]:getPosition()
	if card:getBeforeCard() and headIndex <= BattleManagerFreeCell.HEAD_COLUMN_MAX then
		pos.y = card:getBeforeCard():getView():getPositionY()
	end

	local beginPos = ccp(card:getView():getPosition())

	while card and not tolua.isnull(card:getView()) do
		if card:getBeforeCard() and headIndex <= BattleManagerFreeCell.HEAD_COLUMN_MAX then
			pos.y = pos.y - self:getCardOffsetY_(card:getBeforeCard():getProperty("board"))
		end
		self:startMoving()
		local moveTo = CCEaseSineInOut:create(CCMoveTo:create(0.15, pos))
		local call = CCCallFunc:create(function ( )
			self:endMoving(startHeadIndex, headIndex)
			self:playPartical_(headIndex, startHeadIndex)
			local score = self:checkMoveNeedAddScore(startHeadIndex, headIndex)
			if score > 0 then
				self:playScoreAction(beginPos, pos, score)
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

function BattleManagerFreeCell:cardTouchCancel( cardSp, x, y )
	self:cardTouchEnd(cardSp, x, y)
end

local function judgeCollect_(curCard,list)
	if curCard.headIndex_ >= BattleManagerFreeCell.HEAD_COLLECT_1 and curCard.headIndex_ <= BattleManagerFreeCell.HEAD_COLLECT_MAX then
		--点击的是收集区的卡牌就不在判断是否可收集了
		return false, nil, 0
	end
	--优先判断是否可收集
	if not curCard:getNextCard() then
		--可收集时必定是最后一张牌
		for i=BattleManagerFreeCell.HEAD_COLLECT_1,BattleManagerFreeCell.HEAD_COLLECT_MAX do
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
	local cacheResult_ = false
	local cacheIndex_ = 0
	local moveLenLock_ = false
	for i=BattleManagerFreeCell.HEAD_COLUMN_1,BattleManagerFreeCell.HEAD_COLUMN_MAX do
		if DealerController.judgePickUp(curCard) == DealerController.PICK_ABLE then
			--判断序列是否可被拾取
			if i ~= curCard.headIndex_ then
				local card = list[i]
				if card then
					card = DealerController.getQueueEndCardVO(card)
				end

				local eColumns,eFreeCell = getEmptyColumnsAndCells_(list)
				if not card and eColumns > 0 then
					eColumns = eColumns - 1
				end
				local maxLen_ = DealerController.getQueueMoveLength(eColumns,eFreeCell)
				local moveLen_ = DealerController.getQueueLenByHead(curCard)
				local tempMoveLenLock_ = false
				if maxLen_ < moveLen_ then
					tempMoveLenLock_ = true
					moveLenLock_ = true
				end
				if DealerController.judgePutDownFreeCell(card,curCard) and not tempMoveLenLock_ then
					if card then
						return true, card, i
					else
						cacheResult_ = true
						if cacheIndex_ == 0 then
							cacheIndex_ = i
						end
					end
				end
			end
		end
	end
	return cacheResult_, nil, cacheIndex_ ,moveLenLock_
end

local function judgeChangeMove_(curCard,list)
	local result_,card,cacheIndex_ ,moveLenLock_ = judgeMove_(curCard,list)
	if not card then
		result_ = false
	end
	return result_,card,cacheIndex_ ,moveLenLock_
end

local function judgeChange_(curCard,list)
	if not curCard:getNextCard() then
		--可收集时必定是最后一张牌
		for i=BattleManagerFreeCell.HEAD_CHANGE_1,BattleManagerFreeCell.HEAD_CHANGE_MAX do
			if i ~= curCard.headIndex_ then
				local card = list[i]
				if not card then
					return true, card, i
				end
			end
		end
	end
	return false, nil, 0
end

BattleManagerFreeCell.ALL_CON = 0 --全都判断
BattleManagerFreeCell.ONLY_COLLECT = 1 --只判断收牌
BattleManagerFreeCell.ONLY_MOVE = 2 --只判断移牌
BattleManagerFreeCell.NOT_CHANGE = 3 --不判断存牌
BattleManagerFreeCell.NOT_CHANGE_DOWN = 4 --不判断存牌区的牌落下(提示用)

function BattleManagerFreeCell:findLink_( curCard, condition )
	-- if curCard.headIndex_ >= BattleManagerFreeCell.HEAD_COLLECT_1 and curCard.headIndex_ <= BattleManagerFreeCell.HEAD_COLLECT_MAX then
	-- 	--点击的时候不允许集卡区的牌移动，但可以拖动移动，减少计算量
	-- 	return false, nil, 0
	-- end
	if not curCard then
		return false, nil, 0
	end
	if condition == BattleManagerFreeCell.ONLY_COLLECT then
		return judgeCollect_(curCard,self.headsList_)
	elseif condition == BattleManagerFreeCell.ONLY_MOVE then
		return judgeMove_(curCard,self.headsList_)
	elseif condition == BattleManagerFreeCell.NOT_CHANGE then
		local _b,_c,_i = judgeCollect_(curCard,self.headsList_)
		if _b then
			return _b,_c,_i
		end
		return judgeMove_(curCard,self.headsList_)
	elseif condition == BattleManagerFreeCell.NOT_CHANGE_DOWN then
		local _b,_c,_i = judgeCollect_(curCard,self.headsList_)
		if _b then
			return _b,_c,_i
		end
		return judgeChangeMove_(curCard,self.headsList_)
	
	else
		local _b,_c,_i = judgeCollect_(curCard,self.headsList_)
		if _b then
			return _b,_c,_i
		end
		_b,_c,_i,_m = judgeMove_(curCard,self.headsList_)
		if _b then
			return _b,_c,_i,_m
		end
		_b,_c,_i = judgeChange_(curCard,self.headsList_)
		return _b,_c,_i,_m
	end
	return false, nil, 0
end

function BattleManagerFreeCell:addLightSlot_(node)
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
	node.light:setPosition(ccp(size.width/2, -4))
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

function BattleManagerFreeCell:addLight_( card, node )
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

function BattleManagerFreeCell:clearLight_(openTimeJudge)
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

BattleManagerFreeCell.COLLECT_VALUE = 30 --收一张牌
BattleManagerFreeCell.MOVE_VALUE = -1 --走一步
BattleManagerFreeCell.REVOKE_VALUE = -1 --撤销一步

function BattleManagerFreeCell:calculateScore_(card_before, card_next, headIndex )
	local score = 0
	if headIndex >= BattleManagerFreeCell.HEAD_COLLECT_1 and headIndex <= BattleManagerFreeCell.HEAD_COLLECT_MAX then
		--收牌
		score = score + BattleManagerFreeCell.COLLECT_VALUE
	end

	score = score + BattleManagerFreeCell.MOVE_VALUE

	return score
end


--处理两张卡牌的链接以及头部索引的操作
function BattleManagerFreeCell:linkTwoCard(card_before, card_next, headIndex, notRecordStep )
	if not card_next then
		return
	end
	if card_before and card_before:getNextCard() then
		return
	end


	if card_next.headIndex_ >= BattleManagerFreeCell.HEAD_COLUMN_1 and card_next.headIndex_ <= BattleManagerFreeCell.HEAD_COLUMN_MAX then
		if card_next:getBeforeCard() and card_next:getBeforeCard():getProperty("rank") < card_next:getProperty("rank") then
			self.notNeedAnalysis = false
		end
	end


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
		GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):changeCacheStatusByCardVO(card_before)
	end
	local left_mode = GameManager:getUserData():getIsLeft()
	if headIndex then
		local card = card_next
		while card do
			card:setProperty("headIndex", headIndex)
			-- if headIndex == BattleManagerFreeCell.HEAD_CHANGE_MAX then
			-- 	if left_mode > 0 then
			-- 		card:changeBoardTo(CardVO.BOARD_BACK, CardVO.FLIP_TYPE_LEFT, true)
			-- 	else
			-- 		card:changeBoardTo(CardVO.BOARD_BACK, CardVO.FLIP_TYPE_RIGHT, true)
			-- 	end
			-- elseif headIndex == BattleManagerFreeCell.HEAD_CHANGE_1 then
			-- 	if left_mode > 0 then
			-- 		card:changeBoardTo(CardVO.BOARD_FACE, CardVO.FLIP_TYPE_RIGHT)
			-- 	else
			-- 		card:changeBoardTo(CardVO.BOARD_FACE, CardVO.FLIP_TYPE_LEFT)
			-- 	end
			-- end
			card = card:getNextCard()
		end
		-- --判断是否翻牌
		-- if headIndex == BattleManagerFreeCell.HEAD_CHANGE_MAX or headIndex == BattleManagerFreeCell.HEAD_CHANGE_1 then
		-- else
		-- 	if card_next:getBeforeCard() and card_next:getBeforeCard():getProperty("board") == CardVO.BOARD_BACK then
		-- 		card_next:getBeforeCard():changeBoardTo(CardVO.BOARD_FACE)
		-- 		GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):changeCacheStatusByCardVO(card_next:getBeforeCard())
		-- 		userCacheStepVO:setProperty("beforeIsFlip", 1)
		-- 	end
		-- end
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
	GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):changeCacheStatusByCardVO(card_next)
	--保存步骤信息
	userCacheStepVO:setProperty("stepEnd", card_next:getProperty("headIndex"))
	userCacheStepVO:setProperty("count", DealerController.getQueueLenByHead(card_next))


	if not notRecordStep then
		GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):saveCacheStep(userCacheStepVO)
		GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):addStepCount(1)
		GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):carryOnScore(userCacheStepVO:getProperty("score"))
	end
	local sec = GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):getRunningTime()
	GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):changeCacheData({gameTime = sec})
	self:updateBtnStatus_()
end

function BattleManagerFreeCell:didAddCardToOpen( notReOrder )
	
end

--将开放区的牌回复到锁区
function BattleManagerFreeCell:putCardToLock( count, notRecordStep )
	
end

--将锁区的牌撤销到开放区
function BattleManagerFreeCell:putCardToOpen( count, notRecordStep )

end

function BattleManagerFreeCell:setDelegate( delegate )
	self.delegate_ = delegate
end

function BattleManagerFreeCell:reOrderZOrder_( cardVO, zOrder )
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

function BattleManagerFreeCell:updateBtnStatus_( )
	if self.delegate_ and self.delegate_.setBtn5Enabled then
		local stepData = GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):getCacheStepByLast()
		if stepData then
			self.delegate_:setBtn5Enabled(true)
		else
			self.delegate_:setBtn5Enabled(false)
		end
	end
	EventNoticeManager:getInstance():dispatchEvent({name = Notice.GAME_DATA_CHANGE})
end

function BattleManagerFreeCell:tapChange( )
	-- local isVegasMode = GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):isVegasMode()
	-- -- if self.cardMoving_ then
	-- -- 	return
	-- -- end
	-- self:clearLight_()
	-- local threeMode = GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):getCacheData():getProperty("isDraw3Mode")
	-- local roundLimit = 1--翻牌的轮数限制
	-- local operationCount = 1--操作卡牌的数量
	-- if threeMode > 0 then
	-- 	operationCount = 3
	-- 	roundLimit = 3
	-- end
	-- if self.headsList_[BattleManagerFreeCell.HEAD_CHANGE_MAX] then
	-- 	self.notNeedAnalysis = false
	-- 	--向开放区切牌
	-- 	if isVegasMode then
	-- 		local count = DealerController.getQueueLenByHead(self.headsList_[BattleManagerFreeCell.HEAD_CHANGE_MAX])
	-- 		--切operationCount张牌，不足即为一轮
	-- 		if count <= operationCount then
	-- 			if self.flipCardRound < roundLimit then
	-- 				self.flipCardRound = self.flipCardRound + 1
	-- 				self:putCardToOpen(operationCount)
	-- 			end
	-- 		else
	-- 			self:putCardToOpen(operationCount)
	-- 		end
	-- 	else
	-- 		self:putCardToOpen(operationCount)
	-- 	end
	-- 	self:resumeGame(true)
	-- else
	-- 	--将开放区的牌回复
	-- 	if not self.headsList_[BattleManagerFreeCell.HEAD_CHANGE_1] then
	-- 		--此时换牌区已经无牌
	-- 		return
	-- 	end
	-- 	if isVegasMode and self.flipCardRound >= roundLimit then
	-- 		return
	-- 	end
	-- 	self:resumeGame(true)
	-- 	self:putCardToLock(DealerController.getQueueLenByHead(self.headsList_[BattleManagerFreeCell.HEAD_CHANGE_1]))
	-- end
end

function BattleManagerFreeCell:startMoving( )
	self.cardMoving_ = true
end

function BattleManagerFreeCell:dealOffsetY( headIndex_ )
	if headIndex_ and headIndex_ >= BattleManagerFreeCell.HEAD_COLUMN_1 and headIndex_ <= BattleManagerFreeCell.HEAD_COLUMN_MAX then
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

function BattleManagerFreeCell:endMoving(startHeadIndex, headIndex )
	if startHeadIndex then
		self:dealOffsetY(startHeadIndex)
		if headIndex ~= startHeadIndex then
			self:dealOffsetY(headIndex)
		end
	end
	self.cardMoving_ = false
	self:analysisCollectCard_()
	self:analysisWin_()
end

--暂停游戏
function BattleManagerFreeCell:pauseGame()
	GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):setStartTime(0)
end
--继续游戏
function BattleManagerFreeCell:resumeGame(force)
	local gameState = GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):getCacheData():getProperty("gameState")
	if gameState ~= UserCacheRecordVO.status_playing or not force then
		return
	end
	--此局生效，提交统计数据
	local isRepeat_ = GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):getCacheData():getProperty("isRepeat")
	if isRepeat_ == 0 then
		--快照数据
		GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):changeCacheData({isRepeat = 1})
		--游戏统计数据
		self:saveRecord("newGame")
	end
	GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):changeCacheData({gameState = UserCacheRecordVO.status_playing})
	GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):setStartTime(1)
	EventNoticeManager:getInstance():dispatchEvent({name = Notice.GAME_STATUS_CHANGE})
end

function BattleManagerFreeCell:tapRevoke()
	if self.cardMoving_ then
		return
	end
	local stepData = GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):getCacheStepByLast()
	if not stepData then
		return
	end
	self:resumeGame(true)
	GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):removeCacheStepByLast()
	-- local data = GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):getCacheStepByLast()
	-- if data then
	-- 	self.flipCardRound = data:getProperty("flipCardRound")
	-- else
	-- 	self.flipCardRound = 0
	-- end
	--撤销操作有可能影响到自动收牌
	if self.btn_autoCollect:isVisible() == true then
		self.notNeedAnalysis = false
	end
	
	GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):addStepCount(-1)
	--将增加的分数返还
	GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):carryOnScore(-stepData:getProperty("score"))

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
	GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):carryOnScore(BattleManagerFreeCell.REVOKE_VALUE)

end

function BattleManagerFreeCell:findCardWitchCanCollectByHead_(before,head)
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

function BattleManagerFreeCell:findCardWitchCanCollect_()
	local list_ = {}
	for i=BattleManagerFreeCell.HEAD_COLLECT_1,BattleManagerFreeCell.HEAD_COLLECT_MAX do
		local before = self.headsList_[i]
		if before then
			before = DealerController.getQueueEndCardVO(before)			
			for col=BattleManagerFreeCell.HEAD_COLUMN_1,BattleManagerFreeCell.HEAD_COLUMN_MAX do
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

function BattleManagerFreeCell:tapHint()
	-- self:clearLight_(true)
	self:autoTips(false)
end

function BattleManagerFreeCell:autoTips( isRepeat )
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

	--2存牌区的牌移到集卡区或者玩牌区
	for i=BattleManagerFreeCell.HEAD_CHANGE_1,BattleManagerFreeCell.HEAD_CHANGE_MAX do
		ok, before_card, index = self:findLink_(self.headsList_[i],BattleManagerFreeCell.NOT_CHANGE_DOWN)
		next_card = self.headsList_[i]
		if ok then
			break
		end
	end


	local cache_ok, cache_before_card, cache_index
	local cache_next_card = nil
	--1判断玩牌区 移动整列正面的牌，或者末尾的一张牌去集卡区
	if not ok then
		for i=BattleManagerFreeCell.HEAD_COLUMN_1,BattleManagerFreeCell.HEAD_COLUMN_MAX do
			local card = self.headsList_[i]

			--该队列第一张正面的牌
			card = DealerController.getFirstFaceCardFromHead( card )

			--获取该队列能移动的牌
			card = DealerController.findCanMoveCardByHead(card)
			if card then
				--判断整个队列所有正面的牌弄否移动
				ok, before_card, index = self:findLink_(card,BattleManagerFreeCell.NOT_CHANGE)
				next_card = card
				if card:getBeforeCard() == nil and not before_card then
					--防止k在几个空列来回提示
					ok = false
				end
				if ok then
					if before_card then
						cache_ok = false
						cache_before_card = nil
						cache_index = nil
						cache_next_card = nil
						break
					elseif not cache_ok then
						cache_ok = true
						cache_before_card = before_card
						cache_index = index
						cache_next_card = next_card
					end
					ok = false
				elseif card:getNextCard() then
					--该队列最后一张牌，判断能否移动,此时只判断是否可以收集
					card = DealerController.getQueueEndCardVO(card:getNextCard())
					ok, before_card, index = self:findLink_(card, BattleManagerFreeCell.ONLY_COLLECT)
					next_card = card
					if ok then
						break
					end
				end
			end
		end

		if not ok and cache_ok then
			ok = cache_ok
			before_card = cache_before_card
			index = cache_index
			next_card = cache_next_card
		end
	end

	--2换牌区的牌移到集卡区或者玩牌区
	-- local card = self.headsList_[BattleManagerFreeCell.HEAD_CHANGE_1]
	-- if card then
	-- 	card = DealerController.getQueueEndCardVO(card)
	-- end
	-- if not ok and card then
	-- 	ok, before_card, index = self:findLink_(card,BattleManagerFreeCell.ALL_CON)
	-- 	next_card = card
	-- end

	--5玩牌区移动后可收牌的情况
	if not ok then
		local judgeList_ = self:findCardWitchCanCollect_()
		for i=1,#judgeList_ do
			if judgeList_[i]:getNextCard() then
				ok, before_card, index = self:findLink_(judgeList_[i]:getNextCard(),BattleManagerFreeCell.ONLY_MOVE)
				next_card = judgeList_[i]:getNextCard()
				if ok then
					break
				end
			end
		end
	end

	-- --3换牌区翻牌
	-- local card = self.headsList_[BattleManagerFreeCell.HEAD_CHANGE_MAX]
	-- if not ok and card then
	-- 	ok, before_card, index = true, nil, BattleManagerFreeCell.HEAD_CHANGE_1
	-- 	next_card = DealerController.getQueueEndCardVO(card)
	-- end
	-- --4换牌区回复
	-- local card = self.headsList_[BattleManagerFreeCell.HEAD_CHANGE_1]
	-- if not ok and card then
	-- 	showAni = false
	-- 	ok = true
	-- 	next_card = card
	-- 	node = self["column"..BattleManagerFreeCell.HEAD_CHANGE_MAX]
	-- end

	if not ok then
		for i=BattleManagerFreeCell.HEAD_CHANGE_1,BattleManagerFreeCell.HEAD_CHANGE_MAX do
			if not self.headsList_[i] then
				self.light_ = self:addLightSlot_(self["column"..i])
			end
		end
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
	pos.x, pos.y = self["column"..index]:getPosition()
	if before_card then
		pos.x, pos.y = before_card:getView():getPosition()
		if index <= BattleManagerFreeCell.HEAD_COLUMN_MAX then
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

function BattleManagerFreeCell:tapAutoCollect()
	self.btn_autoCollect:setVisible(false)
	self:autoCollectCard()
end

function BattleManagerFreeCell:analysisCollectCard_( )
	if self.notNeedAnalysis then
		--只有造成牌面翻转之后才需要判断是否可自动收牌以及加分数
		return
	end
	self.notNeedAnalysis = true
	local collect = true
	--牌桌上面还有未翻开的牌不可自动收牌
	for i=BattleManagerFreeCell.HEAD_COLUMN_MAX,BattleManagerFreeCell.HEAD_COLUMN_1, -1 do
		if not DealerController.judgeQueueDescendingByHead(self.headsList_[i]) then
			collect = false
			break
		end
	end
	-- if collect then
	-- 	local threeMode = GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):getCacheData():getProperty("isDraw3Mode")
	-- 	if threeMode > 0 or GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):isVegasMode() then
	-- 		--三张模式时lock区有牌或者开放区多于一张不可自动收牌
	-- 		if self.headsList_[BattleManagerFreeCell.HEAD_CHANGE_MAX] or 
	-- 			DealerController.getQueueLenByHead(self.headsList_[BattleManagerFreeCell.HEAD_CHANGE_1]) > 1 then
	-- 			collect = false
	-- 		end
	-- 	end
	-- end
	if collect then
		--TODO...可以自动收牌了
		-- printf("开始自动收牌")
		local endAniStatus = GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):getEndAniStatus() or BattleManagerFreeCell.END_ANI_NONE
		self.btn_autoCollect:setVisible(endAniStatus == BattleManagerFreeCell.END_ANI_NONE)
	else
		self.btn_autoCollect:setVisible(false)
	end
end

function BattleManagerFreeCell:analysisWin_( )
	local win = true
	--牌桌和换牌区都没有卡牌的时候胜利
	for i=BattleManagerFreeCell.HEAD_COLUMN_1,BattleManagerFreeCell.HEAD_COLUMN_MAX do
		if self.headsList_[i] then
			win = false
			break
		end
	end
	if win then
		for i=BattleManagerFreeCell.HEAD_CHANGE_1,BattleManagerFreeCell.HEAD_CHANGE_MAX do
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
		
		local sec = GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):getRunningTime()
		--计时模式下的奖励分数
		GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):carryOnScore(GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):getFreeCellTimeEndScore())
		EventNoticeManager:getInstance():dispatchEvent({name = Notice.GAME_DATA_CHANGE})
		--提交统计数据
		local isWin_ = GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):getCacheData():getProperty("isWin")
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
		local isDailyChallenge = GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):isDailyChallenge()
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
		for i=BattleManagerFreeCell.HEAD_COLLECT_1,BattleManagerFreeCell.HEAD_COLLECT_MAX do
			local card = self.headsList_[i]
			list[#list + 1] = {suit=card.suit_}
		end
		GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):cacheRecordData(heigh, data, radom_, list,isFirstWin_)
		
		GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):setEndAniStatus(BattleManagerFreeCell.END_ANI_STUFF)
		self:showStuffAnimation()

        -- if DEBUG ~= 1 then
        	GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):cleanData()
        -- end
		GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):changeCacheData({gameState = UserCacheRecordVO.status_end, gameTime = sec, isWin = isWin_})
		EventNoticeManager:getInstance():dispatchEvent({name = Notice.GAME_STATUS_CHANGE})
	end
end

function BattleManagerFreeCell:showWinDialog( )
	local needCoin_ = false
	if GAME_MODE == GAME_MODE_COLLECTION then
		needCoin_ = true
	end
    local viewCtrl = WinViewCtrl.new(needCoin_)
    display.getRunningScene():addChild(viewCtrl:getView())
    GameManager:getUserData():addPraiseWinCount()
end

function BattleManagerFreeCell:showStuffAnimation( )
	
	local list = GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):getProperty("stuffData") or {}
	local index = 1
	for i=BattleManagerFreeCell.HEAD_COLLECT_1,BattleManagerFreeCell.HEAD_COLLECT_MAX do
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

	local radom = GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):getProperty("aniNum") or 1
	self:initSuccesAni_(list,node,radom)
end

function BattleManagerFreeCell:initSuccesAni_(list,node,radom)
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
                GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):setEndAniStatus(BattleManagerFreeCell.END_ANI_DIALOG)
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

function BattleManagerFreeCell:saveRecord(name)
	if name == "newGame" then
		GameManager:getUserClassicData():addFreeCellCount(1)
	elseif name == "win" then
		GameManager:getUserClassicData():addFreeCellWinCount(1)
	elseif name == "record" then
		local high = false
		local step_ = GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):getCacheStepCount()
		local sec_ = GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):getRunningTime()

		local freeCell_cacheData = GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):getCacheData()
        stepCount = freeCell_cacheData:getProperty("move")
        step_ = stepCount

		GameManager:getUserClassicData():addFreeCellFewestMove(step_)
		GameManager:getUserClassicData():addFreeCellFewestTime(sec_)
		--普通模式
		local score_ = GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):getCacheData():getProperty("score")
		score_ = score_ + GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):getTimeScore()
		high = GameManager:getUserClassicData():addFreeCellHighestScore(score_)
		--保存排行榜信息
		local timeTemp = os.time()
		local userClassicRankVO = UserClassicRankVO.new({score=score_, moves = step_, time = sec_, createdTimestamp = timeTemp})
		GameManager:getUserClassicData():saveRankData(userClassicRankVO,UserClassicRankVO.MODE_FREECELL)

		local list = GameManager:getUserClassicData():getProperty("freeCellRankList") or {}
		local totalScore = 0
		local rankMode = GameCenterDefine.getLeaderBoardId().freeCell
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
function BattleManagerFreeCell:uploadSeed()
	local cacheData = GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):getCacheData()
	local isDeal = cacheData:getProperty("isDeal")
	local isNewPlayer = cacheData:getProperty("isNewPlayer")
	-- printf("isDeal == [%s] / isNewPlayer == [%s]",tostring(isDeal),tostring(isNewPlayer))
	if isDeal > 0 or isNewPlayer >0 then
		--活局不用上传种子
		printf("不做胜利种子保存")
		return
	end
	local userDealSeedVO = UserDealSeedVO.new()
	local seed = GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):getCacheData():getProperty("seed") or ""
	local mode = UserCacheRecordVO.mode_freeCell--GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):getCacheData():getProperty("mode")
	userDealSeedVO:setProperty("mode", mode)
	userDealSeedVO:setProperty("seed", seed)

	local needUpload_ = GameManager:getUserSeedData():saveDealSeedByList({userDealSeedVO},UserCacheRecordVO.mode_freeCell)
	if not needUpload_ then
		return
	end
	printf("种子上传")
	local listmode = {}
	local seedList = GameManager:getUserSeedData():getDealSeedByList(UserCacheRecordVO.mode_freeCell) or {}
	for i=1,#seedList do
		listmode[#listmode+1] = seedList[i]:getProperty("seed")
	end
	local param = {}
	if #listmode > 0 then
		param.freeCell = listmode
	end

	GameManager:getNetWork():saveSeed(param)
end

function BattleManagerFreeCell:addTouchLayer_( parent, corlor )
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

function BattleManagerFreeCell:autoCollectCard( )
	self:startMoving()
	GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):setEndAniStatus(BattleManagerFreeCell.END_ANI_COLLECTING)
    local touchNode = self:addTouchLayer_(display.getRunningScene(), ccc4(0, 0, 0, 0))

	function linkCard_( card_before, card_next, headIndex )
		--分数统计
		-- GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):addStepCount(1)
		local score = self:calculateScore_(card_before, card_next, headIndex)
		GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):carryOnScore(score)
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
		GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):changeCacheStatusByCardVO(card_next)
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
		if headIndex < BattleManagerFreeCell.HEAD_COLLECT_1 or headIndex > BattleManagerFreeCell.HEAD_COLLECT_MAX then
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
		for i=BattleManagerFreeCell.HEAD_COLUMN_1,BattleManagerFreeCell.HEAD_COLUMN_MAX do
			local last_card = self.headsList_[i]
			if last_card then
				last_card = DealerController.getQueueEndCardVO(last_card)
				if canCollect_(end_card, last_card, rank, suit, headIndex) then
					return true, last_card, headIndex
				end
			end
		end
		--判断集牌区
		for i=BattleManagerFreeCell.HEAD_CHANGE_1,BattleManagerFreeCell.HEAD_CHANGE_MAX do
			local last_card = self.headsList_[i]
			while last_card do
				if canCollect_(end_card, last_card, rank, suit, headIndex) then
					last_card:changeBoardTo(CardVO.BOARD_FACE, nil, true)
					return true, last_card, headIndex
				end
				last_card = last_card:getNextCard()
			end
		end
		return false
	end

	function collectCard( )
		for i=BattleManagerFreeCell.HEAD_COLLECT_1,BattleManagerFreeCell.HEAD_COLLECT_MAX do
			local ok, card, headIndex = collect(i)
			if ok then
				-- printf("开始自动收牌:%s", card:getCardName())
				local pos = ccp(0, 0)
				pos.x, pos.y = self["column"..i]:getPosition()
				local move = CCMoveTo:create(0.1, pos)
				card:getView():stopAllActions()
				local beginPos = ccp(card:getView():getPosition())
				card:getView():runAction(transition.sequence({CCEaseSineInOut:create(move), CCCallFunc:create(function ()
					self:playPartical_(headIndex, 0)
					local score = self:checkMoveNeedAddScore(0, headIndex)
					if score > 0 then
						self:playScoreAction(beginPos, pos, score)
					end
				end)}))
				self:reOrderZOrder_(card)
				self:palyCollectAudio(i, true)
				break
			end
			if i == BattleManagerFreeCell.HEAD_COLLECT_MAX and ok ~= true then
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
				-- GameManager:getUserGameCacheData(GameManager.MODETYPE_FREECELL):setEndAniStatus(BattleManagerFreeCell.END_ANI_STUFF)
				return
			end
		end
		self:performWithDelay(function ()
			collectCard( )
		end,0.13)
	end

	collectCard()
end

function BattleManagerFreeCell:playPartical_( headIndex, startIndex )
	if headIndex < BattleManagerFreeCell.HEAD_COLLECT_1 or headIndex > BattleManagerFreeCell.HEAD_COLLECT_MAX 
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

function BattleManagerFreeCell:palyCollectAudio( headIndex, collecting )
	if headIndex < BattleManagerFreeCell.HEAD_COLLECT_1 or headIndex > BattleManagerFreeCell.HEAD_COLLECT_MAX then
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

function BattleManagerFreeCell:checkMoveNeedAddScore(startHeadIndex, endHeadIndex)
	local isFishdom = PackageConfigDefine.isSolitaireFishdom()
	if not isFishdom then
		return 0
	end

	if endHeadIndex >= BattleManagerFreeCell.HEAD_COLLECT_1 and endHeadIndex <= BattleManagerFreeCell.HEAD_COLLECT_MAX then
		return BattleManagerFreeCell.COLLECT_VALUE
	elseif startHeadIndex >= BattleManagerFreeCell.HEAD_COLLECT_1 and startHeadIndex <= BattleManagerFreeCell.HEAD_COLLECT_MAX then
		return -BattleManagerFreeCell.COLLECT_VALUE
	end
	return 0
end

function BattleManagerFreeCell:playScoreAction(posBegin, posEnd, scoreNum)
	local isFishdom = PackageConfigDefine.isSolitaireFishdom()
	if not self.card_table or not isFishdom then
		return
	end
	common.scoreAction(self.card_table, posBegin, posEnd, scoreNum)
end

return BattleManagerFreeCell