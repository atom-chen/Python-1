local scheduler = require("framework.scheduler")
local SeedGrade = class("SeedGrade")


SeedGrade.HEAD_COLUMN_1 = 1		--牌桌
SeedGrade.HEAD_COLUMN_2 = 2
SeedGrade.HEAD_COLUMN_3 = 3
SeedGrade.HEAD_COLUMN_4 = 4
SeedGrade.HEAD_COLUMN_5 = 5
SeedGrade.HEAD_COLUMN_6 = 6
SeedGrade.HEAD_COLUMN_MAX = 7

SeedGrade.HEAD_COLLECT_1 = 8	--集牌区
SeedGrade.HEAD_COLLECT_2 = 9
SeedGrade.HEAD_COLLECT_3 = 10
SeedGrade.HEAD_COLLECT_MAX = 11

SeedGrade.HEAD_CHANGE_1 = 12	--换牌区,已打开
SeedGrade.HEAD_CHANGE_MAX = 13	--换牌区，未打开

SeedGrade.RESERVE_NUM = 24 --切牌时预留的张数

SeedGrade.AI_STATUS_INIT = 1 --初始化
SeedGrade.AI_STATUS_PLAYING = 2 --游戏中
SeedGrade.AI_STATUS_END = 3 --结束

SeedGrade.FIRST_COLLECT_SCORE = 2
SeedGrade.COLLECT_SCORE = 1
SeedGrade.PASS_COLLECT_SCORE = 50

SeedGrade.delayEndCd = 120 --延迟结束时间

SeedGrade.AI_EASY = "easy" --简单难度
SeedGrade.AI_NORMAL = "normal" --中等难度
SeedGrade.AI_HARD = "hard" --困难难度

--AI逻辑cd
SeedGrade.JUDGE_AI_CD = {
	easy = {2,3},
	normal = {1,2},
	hard = {0,1}
}

--收牌逻辑cd
SeedGrade.JUDGE_COLLECT_CD = {
	easy = {1,2},
	normal = {0.5,1},
	hard = {0,0.5}
}

--延迟结束
SeedGrade.DELAY_END_TIME = {
	easy = {10,20},
	normal = {20,30},
	hard = {30,40}
}

--收牌逻辑cd加速度
SeedGrade.JUDGE_COLLECT_CD_RATE = 1

function SeedGrade:ctor( _seed )
	self.headsList_ = {}
	
	self.seed_ = _seed
	self.recordList_ = {}
	self.delayTime_ = nil

	self.isNeedEmptyCol_ = true

	self.aiStatus_ = SeedGrade.AI_STATUS_INIT
	self.aiLevel_ = SeedGrade.AI_NORMAL

	self.isQuick = true

	self:startGame(_seed)
end

function SeedGrade:getRandomBy_( a,b )
	if not a or not b then
		return 0
	end

	local begin_ = a * 10
	local end_ = b * 10

	local result_ = math.random(begin_,end_)

	return result_ / 10
end

function SeedGrade:setDelayEnd( ... )
	self.delayTime_ = self:getRandomBy_(SeedGrade.DELAY_END_TIME[self.aiLevel_][1], SeedGrade.DELAY_END_TIME[self.aiLevel_][2])
end

function SeedGrade:getCollectRandomBy_( a,b )
	local min_ = a
	local max_ = b

end

function SeedGrade:startGame( _seed )
	self:initCardBySeed(_seed)
end

function SeedGrade:jidgeCollectListExistCard( card )
	for i=SeedGrade.HEAD_COLLECT_1,SeedGrade.HEAD_COLLECT_MAX do
		local cList_ = DealerController.getListByHead(self.headsList_[i])
		for j=1,#cList_ do
			if card.rank_ == cList_[j].rank_  --点数相同
				and card.suit_ == cList_[j].suit_ then --花色相同
				return true
			end
		end
	end
	return false
end

function SeedGrade:getAICollectList( ... )
	local list_ = {}
	for i=SeedGrade.HEAD_COLLECT_1,SeedGrade.HEAD_COLLECT_MAX do
		local cList_ = DealerController.getListByHead(self.headsList_[i])
		if #cList_ > 0 then
			list_[i] = cList_
		end
	end
	return list_
end

function SeedGrade:getAIStatus( ... )
	return self.aiStatus_
end

function SeedGrade:ending( ... )
	self.aiStatus_ = SeedGrade.AI_STATUS_END
end

function SeedGrade:aiEnd(isWin)
	self:ending()
	print('---->>>:结束')
	if self.scheduleHandle then
        scheduler.unscheduleGlobal(self.scheduleHandle)
        self.scheduleHandle = nil
    end
end

function SeedGrade:begin( ... )
	self.aiStatus_ = SeedGrade.AI_STATUS_PLAYING
	self.scheduleHandle = scheduler.scheduleUpdateGlobal(function ( dt )
		self:update(dt)
		self:aiQucikCollect_(dt)
	end,1)
	
end

function SeedGrade:update( t )
	if self.aiStatus_ ~= SeedGrade.AI_STATUS_PLAYING then
		return
	end
	if self.delayTime_ then
		self.delayTime_ = self.delayTime_ - t
		if self.delayTime_ <= 0 then
			self.delayTime_ = nil
			self:aiEnd(false)
			return
		end
	end
	-- print("==========",self.isQuick)
	if not self.isQuick then
		-- self:doAiLogic()
	end
end

function SeedGrade:copyCard_(card)
	local result = CardVO.new({
				deck = card.deck_,
				suit = card.suit_, --花色
				rank = card.rank_, --点数
				board = card.board_, 
				before = card.before_, --上一张牌
				next = card.next_, --上一张牌
				headIndex = card.headIndex_,--所属队列的索引
			})

	return result
end

function SeedGrade:initCardBySeed( seed )
	if not seed then
		return
	end
	--获取牌组
	local list = DealerController.initCards()
	local seed_ = seed

	list,seed_ = DealerController.shuffleCards(list,seed_)
	self.seed_ = seed_

	function linkCard_( before,cardVO,headIndex )
		cardVO:setBeforeCard(before)
		cardVO:setProperty("headIndex",headIndex)
		if before == nil then
			self.headsList_[headIndex] = cardVO
		else
			before:setNextCard(cardVO)
		end
	end
	-- print('--list count',#list)

	local cacheList = {}
	local backCardsList = {}
	for column = 1,7 do
		local before = nil
		for num = 1,column do
			local cardVO = list[1]
			table.remove(list,1)
			linkCard_(before,cardVO,column)
			-- print('=====>>>>>>>',column,num)
			if num >= column then
				cardVO:setProperty("board", CardVO.BOARD_FACE)
			else
				cardVO:setProperty("board", CardVO.BOARD_BACK)
			end
			before = cardVO
		end
	end

	--发牌区域的牌全部显示
	local before = nil
	for i = 1,#list do
		-- print('--->>>>>#list',i)
		local cardVO =list[i]
		linkCard_(before,cardVO,SeedGrade.HEAD_CHANGE_1)
		cardVO:setProperty("board",CardVO.BOARD_FACE)
		before = cardVO
	end
end

function checkGradeColumn(  )
	local tabColumn = {}
	for i = SeedGrade.HEAD_COLUMN_1,SeedGrade.HEAD_COLUMN_MAX do
		tabColumn[i] = {}
		local lastCard = self.headsList_[i]
		if lastCard then
		else
			-- tabColumn[i]
		end
	end
end

function SeedGrade:startDealCard( seed )
	-- body
end

--执行AI逻辑(一步)
function SeedGrade:doAiLogic()

	if self.isQuick then
		return
	end

	self:judgeNeedEmptyCol_()
	
	--判断是否有牌可以收
	local b = self:aiCollect_()
	if b then
		self.emptyChangeNum_ = 0 --空切牌数(用于判断是否无操作可做)
		-- self.aiCd_ = self:getCollectRandomBy_(SeedGrade.JUDGE_COLLECT_CD[self.aiLevel_][1],SeedGrade.JUDGE_COLLECT_CD[self.aiLevel_][2])
		return
	end

	--重置AI cd
	-- self.aiCd_ = self:getRandomBy_(SeedGrade.JUDGE_AI_CD[self.aiLevel_][1],SeedGrade.JUDGE_AI_CD[self.aiLevel_][2])
	--判断玩牌区是否可以有效移动
	
	local aiMoveVO_ = self:move_()
	if aiMoveVO_ then
		self.emptyChangeNum_ = 0 --空切牌数(用于判断是否无操作可做)
		printf("[AI] -- :玩牌区移动")
		local call_ = nil
		if self.aiAutoCollect_ then
			call_ = handler(self, self.autoCollect_)
		end
		self:doMoveLogic_(aiMoveVO_,call_)
		return
	end
	
	--判断切牌区是否可以有效移动(落牌)
	local aiMoveVO_ = self:changePut_()
	if aiMoveVO_ then
		self.emptyChangeNum_ = 0 --空切牌数(用于判断是否无操作可做)
		printf("[AI] -- :切牌区落下")
		local call_ = nil
		if self.aiAutoCollect_ then
			call_ = handler(self, self.autoCollect_)
		end
		self:doMoveLogic_(aiMoveVO_,call_)
		return
	end
	
	--切牌
	if self:change_() then
		printf("[AI] -- :切牌")
		self.emptyChangeNum_ = self.emptyChangeNum_ + 1
		--是否还有操作可做
		local emptyRound_ = self:getEmptyRound_()
		if emptyRound_ > 1 then
			printf("[AI] -- : 无操作可做!")
			self:aiEnd(false)
		end
		return
	end

	if self:judgeWin_() then
		printf("[AI] -- : AI通关了!")
		-- self:passScoreLogic_()
		self:aiEnd(true)
	else
		--无操作可做
		printf("[AI] -- : 无操作可做!")
		self:aiEnd(false)
	end
end

--空切的轮数
function SeedGrade:getEmptyRound_()
	local changeLen_ = DealerController.getQueueLenByHead(self.headsList_[SeedGrade.HEAD_CHANGE_1])
	local changeMaxLen_ = DealerController.getQueueLenByHead(self.headsList_[SeedGrade.HEAD_CHANGE_MAX])
	local result_ = 0
	if self.emptyChangeNum_ > changeLen_ + changeMaxLen_ then
		result_ = 1
	end
	if self.emptyChangeNum_ > (changeLen_ + changeMaxLen_)*2 + 2 then
		result_ = 2
	end
	return result_
end

function SeedGrade:judgeWin_()
	local win = true
	--牌桌和换牌区都没有卡牌的时候胜利
	for i=SeedGrade.HEAD_COLUMN_1,SeedGrade.HEAD_COLUMN_MAX do
		if self.headsList_[i] then
			win = false
			break
		end
	end
	if win then
		if self.headsList_[SeedGrade.HEAD_CHANGE_1] or self.headsList_[SeedGrade.HEAD_CHANGE_MAX] then
			win = false
		end
	end
	return win
end

--玩牌区是否有牌可以落到curCard上(有效移动)
function SeedGrade:judgePut_(curCard,list)
	if not curCard then
		return false
	end
	for i=SeedGrade.HEAD_COLUMN_1,SeedGrade.HEAD_COLUMN_MAX do
		if i ~= curCard.headIndex_ then
			local card = list[i]
			--该队列第一张正面的牌
			card = DealerController.getFirstFaceCardFromHead(card)
			if card then
				if self.isNeedEmptyCol_  --如果AI需要空列
					or (not self.isNeedEmptyCol_ and card:getBeforeCard()) then --如果AI不需要空列，且card不是头牌
					local b = DealerController.judgePutDown(curCard,card)
					if b then
						return true
					end
				end
			end	
		end
	end
	return false
end

--切牌区是否有牌可以落到curCard
function SeedGrade:judgeCanChangePutOn_(curCard,list)
	if not curCard then
		return false
	end
	--如果点数小于3则不考虑
	if curCard.rank_ < CardVO.RANK_THREE then
		return false
	end

	local color_ = curCard:getCardColor()
	if color_ == CardVO.COLOR_RED then
		color_ = CardVO.COLOR_BLACK
	elseif color_ == CardVO.COLOR_BLACK then
		color_ = CardVO.COLOR_RED
	end

	--是否能在切牌区找到 点数小1，色系不同的牌
	local list_ = self:getChangeCardBy_(list,curCard.rank_ - 1,color_)
	if #list_ > 0 then
		return true
	end
	return false
end

--玩牌区是否有同色系同点数的牌存在 [-1:有，但是可以通过收牌来消除 / 0:没有 / 1:有，且暂时无法消除]
SeedGrade.sameCard_yes_can_collect = 1 --有，但是可以通过收牌来消除
SeedGrade.sameCard_no = 2 --没有
SeedGrade.sameCard_yes = 3 --有，且暂时无法消除

function SeedGrade:judgeSameCard_(curCard,list)
	if not curCard then
		return SeedGrade.sameCard_yes
	end

	--符合条件的牌
	local sameCard_ = nil
	for i=SeedGrade.HEAD_COLUMN_1,SeedGrade.HEAD_COLUMN_MAX do
		local card = list[i]
		--该队列第一张正面的牌
		card = DealerController.getFirstFaceCardFromHead(card)
		while card do
			if card.rank_ == curCard.rank_  --点数相同
				and card:getCardColor() == curCard:getCardColor() then --色系相同
				sameCard_ = card
				break --跳出 while 循环
			end
			card = card:getNextCard()
		end
		if sameCard_ then 
			break --跳出 for 循环
		end
	end

	--有符合条件的牌
	if sameCard_ then
		if sameCard_:getNextCard() then --不是列尾
			local copySameCard_ = self:copyFaceCard_(sameCard_)
			--可被收
			local isCanCollect_ = self:judgeCollect_(copySameCard_,list)
			if isCanCollect_ then
				return SeedGrade.sameCard_yes_can_collect
			else
				return SeedGrade.sameCard_yes
			end
		else --是列尾
			return SeedGrade.sameCard_yes
		end
	end

	return SeedGrade.sameCard_no
end

--玩牌区是否有不是头牌的K
function SeedGrade:judgeNotHeadKCard_(list)
	for i=SeedGrade.HEAD_COLUMN_1,SeedGrade.HEAD_COLUMN_MAX do
		local card = list[i]
		--该队列第一张正面的牌
		card = DealerController.getFirstFaceCardFromHead(card)
		if card --不是空列
			and card:getBeforeCard() --不是头牌
			and card.rank_ == CardVO.RANK_KING then --点数为K
			return true,card
		end	
	end
	return false
end

--获取切牌区 点数为rank色系为color(不传就不考虑色系条件) 的牌
function SeedGrade:getChangeCardBy_(list,rank,color)
	local list_ = {}

	--切牌区(打开)
	local changeHead_ = self.headsList_[SeedGrade.HEAD_CHANGE_1]
	while changeHead_ do
		if changeHead_.rank_ == rank then
			if not color 
				or color == changeHead_:getCardColor() then
				list_[#list_ + 1] = changeHead_				
			end
		end
		changeHead_ = changeHead_:getNextCard()
	end

	--切牌区(未打开)
	local changeMaxHead_ = self.headsList_[SeedGrade.HEAD_CHANGE_MAX]
	while changeMaxHead_ do
		if changeMaxHead_.rank_ == rank then
			if not color 
				or color == changeMaxHead_:getCardColor() then
				list_[#list_ + 1] = changeMaxHead_				
			end
		end
		changeMaxHead_ = changeMaxHead_:getNextCard()
	end

	return list_
end

function SeedGrade:judgeCollect_(curCard,list)
	if curCard and not curCard:getNextCard() then --可收集时必定是最后一张牌
		--如果有牌可以落，则不考虑收这张牌
		if self:judgePut_(curCard,list) then
			-- printf(" judgeCollect == %s 有牌可以落，所以不考虑是否能收取！",curCard:getCardName())
			return
		end
		
		for i=SeedGrade.HEAD_COLLECT_1,SeedGrade.HEAD_COLLECT_MAX do
			if i ~= curCard.headIndex_ then
				local mCard = list[i]
				if mCard then
					mCard = DealerController.getQueueEndCardVO(mCard)
				end
				if DealerController.judgeCollectCard(mCard,curCard) then
					local aiMoveVO_ = AIMoveVO.new({
						card = curCard,
						toIndex = i,
					})
					return aiMoveVO_
				end
			end
		end
	end
end

function SeedGrade:autoCollect_()
	local aiMoveVO_ = self:collect_()
	if not aiMoveVO_ then
		return
	end
	printf("[AUTO_AI] -- :收取 %s",aiMoveVO_.card_:getCardName())
	self:doMoveLogic_(aiMoveVO_,handler(self, self.autoCollect_))
end

function SeedGrade:aiCollect_()
	local aiMoveVO_ = self:collect_()
	if not aiMoveVO_ then
		return false
	end

	printf("[AI] -- :收取 %s",aiMoveVO_.card_:getCardName())

	self:doMoveLogic_(aiMoveVO_)
	return true
end

function SeedGrade:collect_()
	--玩牌区
	for i=SeedGrade.HEAD_COLUMN_1,SeedGrade.HEAD_COLUMN_MAX do 
		local card = DealerController.getQueueEndCardVO(self.headsList_[i])
		
		if card then
			local aiMoveVO_ = self:judgeCollect_(card,self.headsList_)
			if aiMoveVO_ then
				return aiMoveVO_
			end
		end
	end

	for i = SeedGrade.HEAD_CHANGE_1,SeedGrade.HEAD_CHANGE_MAX do
		local card = DealerController.getQueueEndCardVO(self.headsList_[i])
		if card then
			local aiMoveVO_ = self:judgeCollect_(card,self.headsList_)
			if aiMoveVO_ then
				return aiMoveVO_
			end
		end
	end
end

--头牌是K
function SeedGrade:isHeadK_(card)
	if not card:getBeforeCard() and card.rank_ == CardVO.RANK_KING then
		return true
	end
	return false
end

function SeedGrade:judgeMove_(curCard,list,ignoreCol)
	if not curCard then
		return
	end
	
	--如果属于玩牌区,则走一下逻辑
	if curCard.headIndex_ >= SeedGrade.HEAD_COLUMN_1 and curCard.headIndex_ <= SeedGrade.HEAD_COLUMN_MAX then
		--如果curCard是K,且为头牌,则不考虑移动
		if self:isHeadK_(curCard) then
			return
		end
		--如果AI不需要空列,且curCard为头牌,则不考虑移动
		if not self.isNeedEmptyCol_ and not curCard:getBeforeCard() then 
			return
		end
	end
	
	for i=SeedGrade.HEAD_COLUMN_1,SeedGrade.HEAD_COLUMN_MAX do
		if DealerController.judgePickUp(curCard) == DealerController.PICK_ABLE then
			--判断序列是否可被拾取
			if i ~= curCard.headIndex_ and i ~= ignoreCol then
				local card = list[i]
				if card then
					card = DealerController.getQueueEndCardVO(card)
				end
				if DealerController.judgePutDown(card,curCard) then
					local aiMoveVO_ = AIMoveVO.new({
						card = curCard,
						toIndex = i,
					})
					return aiMoveVO_
				end
			end
		end
	end
end

--判断AI是否需要空列
function SeedGrade:judgeNeedEmptyCol_()
	local emptyColNum_ = 0 --空列数
	local headKColNum_ = 0 --打头是K的列数
	for i=SeedGrade.HEAD_COLUMN_1,SeedGrade.HEAD_COLUMN_MAX do
		local card = self.headsList_[i]
		--该队列第一张正面的牌
		card = DealerController.getFirstFaceCardFromHead(card)
		if card then
			if self:isHeadK_(card) then
				headKColNum_ = headKColNum_ + 1
			end
		else
			emptyColNum_ = emptyColNum_ + 1
		end
	end
	if emptyColNum_ + headKColNum_ < 4 then
		self.isNeedEmptyCol_ = true --空列需求
	else
		self.isNeedEmptyCol_ = false --空列不需求
	end
end

--切牌 返回有无牌可切
function SeedGrade:change_()
	local operationCount = 1--操作卡牌的数量
	if self.isDraw3_ then
		operationCount = 3
	end
	--切牌区(未打开)处有牌
	if self.headsList_[SeedGrade.HEAD_CHANGE_MAX] then
		self:putCardToChangeBy_(operationCount,SeedGrade.HEAD_CHANGE_1)
	else --切牌区(未打开)处没牌
		--将开放区的牌回复
		if not self.headsList_[SeedGrade.HEAD_CHANGE_1] then
			--此时换牌区已经无牌
			return false
		end
		--切牌区(已打开)的牌数
		operationCount = DealerController.getQueueLenByHead(self.headsList_[SeedGrade.HEAD_CHANGE_1])
		self:putCardToChangeBy_(operationCount,SeedGrade.HEAD_CHANGE_MAX)
	end
	return true
end

--切牌区切牌逻辑
--count:数量
--toIndex:区分 已打开 和 未打开
function SeedGrade:putCardToChangeBy_(count,toIndex)
	if count < 1 then
		return
	end

	--根据 to区的(已打开或未打开) 来定义 from区的(已打开或未打开)
	local fromIndex = SeedGrade.HEAD_CHANGE_MAX
	if toIndex == SeedGrade.HEAD_CHANGE_MAX then
		fromIndex = SeedGrade.HEAD_CHANGE_1
	end
	local card_ = self.headsList_[fromIndex]
	if card_ then
		--from区的最后一张
		card_ = DealerController.getQueueEndCardVO(card_)
		--from区的倒数count张的头牌
		card_ = DealerController.getCardByCountFromBottom(card_,count)
		--from区的倒数count张逆向的头牌
		card_ = DealerController.reverseQueueByCardVO(card_)
	else
		return
	end

	local aiMoveVO_ = AIMoveVO.new({
		card = card_,
		toIndex = toIndex,
	})
	local call_ = nil
	if self.aiAutoCollect_ then
		call_ = handler(self, self.autoCollect_)
	end
	if toIndex == SeedGrade.HEAD_CHANGE_MAX then --如果是往切牌区(未打开)落牌，则不考虑自动收牌
		call_ = nil
	end
	self:doMoveLogic_(aiMoveVO_,call_)	
end

-- 判断 beforeCard 和 nextCard 可不可能为一列
function SeedGrade:judgeCanBeSameCol_(beforeCard,nextCard)
	if not beforeCard then
		return false
	end
	if not nextCard then
		return false
	end
	local offRank_ = beforeCard.rank_ - nextCard.rank_
	if offRank_ <= 0 then
		return false
	end
	if offRank_%2 == 0 then
		if beforeCard:getCardColor() ~= nextCard:getCardColor() then
			return false
		end
	else
		if beforeCard:getCardColor() == nextCard:getCardColor() then
			return false
		end
	end

	return true
end

-- 切牌区放入玩牌区策略
function SeedGrade:judgeChangePut_(aiMoveVO)
	if not aiMoveVO then
		return
	end
	local moveCard_ = aiMoveVO.card_
	if self.isDraw3_ then -- 三张牌切牌区放入玩牌区策略

		return aiMoveVO
	else -- 一张牌切牌区放入玩牌区策略
		if moveCard_.rank_ < CardVO.RANK_THREE then --点数小于3
			return
		end
		if moveCard_.rank_ == CardVO.RANK_KING then --点数等于K
			--如果不缺空列，则直接落下K
			if not self.isNeedEmptyCol_ then
				return aiMoveVO
			end
			--如果缺空列，则进行以下逻辑
			--如果玩牌区有可以落在上面的Q，则落下K，否则不落下K
			for i=SeedGrade.HEAD_COLUMN_1,SeedGrade.HEAD_COLUMN_MAX do
				local card = self.headsList_[i]
				--该队列第一张正面的牌
				card = DealerController.getFirstFaceCardFromHead(card)
				if card then
					local b = DealerController.judgePutDown(moveCard_,card)
					if b then
						return aiMoveVO
					end
				end
			end
			local emptyRound_ = self:getEmptyRound_()
			if emptyRound_ > 0 then
				return aiMoveVO
			end
			return
		end

		local possible_ = false
		for i=SeedGrade.HEAD_COLUMN_1,SeedGrade.HEAD_COLUMN_MAX do
			if i ~= aiMoveVO.toIndex_ then -- 不考虑目标列
				local card = self.headsList_[i]
				--该队列最后一张牌
				local endCard_ = DealerController.getQueueEndCardVO(card) 
				if endCard_ --不为空列
					and endCard_.rank_ == moveCard_.rank_  --点数相同
					and endCard_:getCardColor() == moveCard_:getCardColor() then --色系相同
					--说明玩牌区已有该类型(同点同色系)的牌可用(在列尾),所以就不用落下
					return
				end
				--该队列第一张正面的牌
				local headFaceCard_ = DealerController.getFirstFaceCardFromHead(card)
				if headFaceCard_ then
					-- 如果玩牌区有一张 headFaceCard_ 可以和 moveCard_ 在同一列则就考虑可以落下 moveCard_
					local b = self:judgeCanBeSameCol_(moveCard_,headFaceCard_)
					if b then
						possible_ = true
					end
				end
			end
		end
		if possible_ then
			return aiMoveVO
		end
	end
end

--判断切牌区是否有牌可落在玩牌区
function SeedGrade:changePut_()
	local card = DealerController.getQueueEndCardVO(self.headsList_[SeedGrade.HEAD_CHANGE_1])
	if card then
		local aiMoveVO_ = self:judgeMove_(card,self.headsList_)
		return self:judgeChangePut_(aiMoveVO_)
	end
end

function SeedGrade:findCardWitchCanCollectByHead_(before,head)
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

function SeedGrade:findCardWitchCanCollect_()
	local list_ = {}
	for i=SeedGrade.HEAD_COLLECT_1,SeedGrade.HEAD_COLLECT_MAX do
		local before = self.headsList_[i]
		if before then
			before = DealerController.getQueueEndCardVO(before)			
			for col=SeedGrade.HEAD_COLUMN_1,SeedGrade.HEAD_COLUMN_MAX do
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

--判断玩牌区是否可以有效移动
function SeedGrade:move_()
	local aiMoveList_ = {}

	--移动可翻牌或者空出一列的情况
	for i=SeedGrade.HEAD_COLUMN_1,SeedGrade.HEAD_COLUMN_MAX do
		local card = self.headsList_[i]
		--该队列第一张正面的牌
		card = DealerController.getFirstFaceCardFromHead(card)
		if card then
			local aiMoveVO_ = self:judgeMove_(card,self.headsList_)
			if aiMoveVO_ then
				if not self:isEndlessLoop_(aiMoveVO_) then
					aiMoveList_[#aiMoveList_ + 1] = aiMoveVO_
				end
			end
		end
	end

	--玩牌区移动后可收牌的情况
	local judgeList_ = self:findCardWitchCanCollect_()
	for i=1,#judgeList_ do
		if judgeList_[i]:getNextCard() then
			local aiMoveVO_ = self:judgeMove_(judgeList_[i]:getNextCard(),self.headsList_)
			if aiMoveVO_ then
				if not self:isEndlessLoop_(aiMoveVO_) then
					aiMoveList_[#aiMoveList_ + 1] = aiMoveVO_
				end
			end
		end
	end

	if #aiMoveList_ < 1 then --没有可以移动的步骤
		return
	elseif #aiMoveList_ == 1 then --只有一种步骤
		return aiMoveList_[1]
	end

	local toIndex_ = aiMoveList_[1].toIndex_
	local selList_ = {}
	selList_[1] = aiMoveList_[1]
	for i=2,#aiMoveList_ do
		if toIndex_ == aiMoveList_[i].toIndex_ then
			selList_[#selList_ + 1] = aiMoveList_[i]
		end
	end

	if #selList_ == 1 then -- 没有两列同时往一列移动的情况
		return selList_[1]
	end
	print("··list-->>>·",#selList_)
	-- self:selectAiMove2_(selList_)
	local aiMoveVO_ = self:selectAiMove_(selList_)
	return aiMoveVO_
end

function SeedGrade:copyFaceCard_(card)
	local result = CardVO.new({
				deck = card.deck_,
				suit = card.suit_, --花色
				rank = card.rank_, --点数
				board = CardVO.BOARD_FACE, 
				before = card.before_, --上一张牌
				headIndex = card.headIndex_,--所属队列的索引
			})

	return result
end

function SeedGrade:selectAiMove_( aiMoveList )
	local resultAiMoveList2_ = {}
	-- dump(aiMoveList,'aiMoveList===>>>.')
	for i = 1,#aiMoveList do 
		local card_ = aiMoveList[i].card_
		local toindecxx = aiMoveList[i].toIndex_
		local head_index = card_:getProperty("headIndex")
		local beforeCard_ = card_:getBeforeCard()
		
		if beforeCard_ then
			local m_index = 0
			local last_card = self.headsList_[head_index]
			-- dump(last_card)
			print("paishu ==>>suit",card_:getProperty("suit") .. " rank",card_:getProperty("rank") .. " toindecxx-->>>",toindecxx .. "  head_index-->>",head_index .. "  card",last_card)
			while last_card do
				last_card = last_card:getNextCard()
				m_index = m_index + 1
			end
			print('--->>>>>>深度为：',m_index,last_card,beforeCard_)
			aiMoveList[i].weight_ = aiMoveList[i].weight_ + m_index
		else
			if self.isNeedEmptyCol_ then --需要空列
				--是否有不是头牌的K
				local haveNotHeadKCard_ = self:judgeNotHeadKCard_(self.headsList_)
				if haveNotHeadKCard_ then --如果有不是头牌的K    权重+0.9
					aiMoveList[i].weight_ = aiMoveList[i].weight_ + 1
				end

				--切牌区有K
				local changeCardList_ = self:getChangeCardBy_(self.headsList_,CardVO.RANK_KING)
				if #changeCardList_ > 0 then --切牌区有K    权重+0.5
					aiMoveList[i].weight_ = aiMoveList[i].weight_ + 0.5
				end
				-- dump(changeCardList_,'===>>>')
			end
		end

		if #resultAiMoveList2_ < 1 then
			resultAiMoveList2_[1] = aiMoveList[i]
		elseif resultAiMoveList2_[1].weight_ == aiMoveList[i].weight_ then
			resultAiMoveList2_[#resultAiMoveList2_ + 1] = aiMoveList[i]
		elseif resultAiMoveList2_[1].weight_ < aiMoveList[i].weight_ then
			resultAiMoveList2_ = {}
			resultAiMoveList2_[1] = aiMoveList[i]
		end
	end

	if #resultAiMoveList2_ < 1 then
		return
	elseif #resultAiMoveList2_ == 1 then
		return resultAiMoveList2_[1]
	end

	local len_ = #resultAiMoveList2_
	local random_ = math.random(1,len_)
	return resultAiMoveList2_[random_]
end

function SeedGrade:juadeQIn( KList )
	local tableQ = {}
	for i=SeedGrade.HEAD_COLUMN_1,SeedGrade.HEAD_COLUMN_MAX do
		local cardQ = self.headsList_[i]
		while cardQ do
			if cardQ:getProperty("rank") == CardVO.RANK_QUEEN then
				tableQ[#tableQ] = cardQ
			end
			cardQ = cardQ:getNextCard()
		end
	end

	for i = 1,#KList do
		local card = KList[i]
		local suit = card:getCardColor()
		for i,v in ipairs(tableQ) do
			if v:getCardColor() == suit then
				break
			end
		end
	end
end

function SeedGrade:selectAiMove2_(aiMoveList)
	local resultAiMoveList_ = {}
	for i=1,#aiMoveList do
		local card_ = aiMoveList[i].card_
		local beforeCard_ = card_:getBeforeCard()

		if beforeCard_ then --不是头牌
			--复制一个正面，且没有next的牌出来
			local copyCard_ = self:copyFaceCard_(beforeCard_)
			--可被收
			local isCanCollect_ = self:judgeCollect_(copyCard_,self.headsList_)
			if isCanCollect_ then --如果可以收    
				if beforeCard_.board_ == CardVO.BOARD_BACK then  --beforeCard_是背面   权重+1.1
					aiMoveList[i].weight_ = aiMoveList[i].weight_ + 1.1
				end
			end
			-- printf("---isCanCollect_-------->%s",tostring(isCanCollect_))
			--可被移动
			local isCanMove_ = self:judgeMove_(copyCard_,self.headsList_,aiMoveList[i].toIndex_)
			if not isCanCollect_ and isCanMove_ then --如果可以移动    权重+1
				aiMoveList[i].weight_ = aiMoveList[i].weight_ + 1
			end
			-- printf("---isCanMove_-------->%s",tostring(isCanMove_))
			--可在上面落牌（玩牌区）
			local isCanPut_ = self:judgePut_(copyCard_,self.headsList_)
			if isCanPut_ then --如果可以落牌(玩牌区)    权重+1
				aiMoveList[i].weight_ = aiMoveList[i].weight_ + 1
			end
			-- printf("---isCanPut_-------->%s",tostring(isCanPut_))
			--可在上面落牌（切牌区）
			local isCanPutChange_ = self:judgeCanChangePutOn_(copyCard_,self.headsList_)
			if isCanPutChange_ then --如果可以落牌(切牌区)    权重+0.5
				aiMoveList[i].weight_ = aiMoveList[i].weight_ + 0.5
			end
			-- printf("---isCanPutChange_-------->%s",tostring(isCanPutChange_))
			--是否有相同色系的同点数的牌已存在
			local isSameCard_ = self:judgeSameCard_(copyCard_,self.headsList_)
			if isSameCard_ == SeedGrade.sameCard_no then --没有    权重+0.3
				aiMoveList[i].weight_ = aiMoveList[i].weight_ + 0.3
			elseif isSameCard_ == SeedGrade.sameCard_yes_can_collect then --有,但是可以消掉   权重+0.8
				aiMoveList[i].weight_ = aiMoveList[i].weight_ + 0.8
			end
			-- printf("---isSameCard_-------->%s",tostring(isSameCard_))
		else --是头牌
			if self.isNeedEmptyCol_ then --需要空列
				--是否有不是头牌的K
				local haveNotHeadKCard_ = self:judgeNotHeadKCard_(self.headsList_)
				if haveNotHeadKCard_ then --如果有不是头牌的K    权重+0.9
					aiMoveList[i].weight_ = aiMoveList[i].weight_ + 0.9
				end

				--切牌区有K
				local changeCardList_ = self:getChangeCardBy_(self.headsList_,CardVO.RANK_KING)
				if #changeCardList_ > 0 then --切牌区有K    权重+0.5
					aiMoveList[i].weight_ = aiMoveList[i].weight_ + 0.5
				end
			end
		end
		--记录最高权重的步骤
		if #resultAiMoveList_ < 1 then
			resultAiMoveList_[1] = aiMoveList[i]
		elseif resultAiMoveList_[1].weight_ == aiMoveList[i].weight_ then
			resultAiMoveList_[#resultAiMoveList_ + 1] = aiMoveList[i]
		elseif resultAiMoveList_[1].weight_ < aiMoveList[i].weight_ then
			resultAiMoveList_ = {}
			resultAiMoveList_[1] = aiMoveList[i]
		end
	end

	if #resultAiMoveList_ < 1 then
		return
	elseif #resultAiMoveList_ == 1 then
		return resultAiMoveList_[1]
	end
	--如果有多个步骤都是最高权重,则随机一个步骤
	local len_ = #resultAiMoveList_
	local random_ = math.random(1,len_)

	return resultAiMoveList_[random_]
end

function SeedGrade:isEndlessLoop_(aiMoveVO)
	local key_ = self:createKeyByAiMoveVO_(aiMoveVO)
	if not key_ then
		return false
	end
	if not self.recordList_ then
		return false
	end
	if not self.recordList_[key_] then
		return false
	end
	if self.recordList_[key_] < 5 then
		return false
	end
	printf("SeedGrade:isEndlessLoop == [%s]", tostring(key_))
	return true
end

function SeedGrade:createKeyByAiMoveVO_(aiMoveVO)
	local toIndex_ = aiMoveVO.toIndex_
	if not toIndex_ then
		return
	end
	local card = aiMoveVO.card_
	if not card then
		return
	end
	local key_ = tostring(card.deck_).."_"..tostring(card.suit_).."_"..tostring(card.rank_).."_"..tostring(card.headIndex_).."_"..tostring(toIndex_)
	return key_
end

function SeedGrade:recordMoveStep_(aiMoveVO)
	local toIndex_ = aiMoveVO.toIndex_
	if toIndex_ >= SeedGrade.HEAD_CHANGE_1 or toIndex_ <= SeedGrade.HEAD_CHANGE_MAX then
		return
	end
	local key_ = self:createKeyByAiMoveVO_(aiMoveVO)
	if not key_ then
		return
	end
	if not self.recordList_ then
		self.recordList_ = {}
	end
	
	if not self.recordList_[key_] then
		self.recordList_[key_] = 0
	end
	self.recordList_[key_] = self.recordList_[key_] + 1
end

function SeedGrade:doMoveLogic_(aiMoveVO,call)
	if not aiMoveVO then
		return
	end
	local card = aiMoveVO.card_
	if not card then
		return
	end

	--防死循环处理
	self:recordMoveStep_(aiMoveVO)

	local before_ = card:getBeforeCard()
	if before_ then
		before_:setNextCard(nil)
		--如果是属于玩牌区的移动，且有before_，则要把before_翻成正面
		if card.headIndex_ >= SeedGrade.HEAD_COLUMN_1 and card.headIndex_ <= SeedGrade.HEAD_COLUMN_MAX then
			before_:setProperty("board", CardVO.BOARD_FACE)
		end
	else
		self.headsList_[card.headIndex_] = nil
	end

	local toIndex_ = aiMoveVO.toIndex_
	local temCard = card
	while temCard do
		temCard:setProperty("headIndex", toIndex_)
		if toIndex_ == SeedGrade.HEAD_CHANGE_1 then --如果是往切牌区(已打开)放牌，则把牌翻正
			temCard:setProperty("board", CardVO.BOARD_FACE)
		elseif toIndex_ == SeedGrade.HEAD_CHANGE_MAX then --如果是往切牌区(未打开)放牌，则把牌翻背
			temCard:setProperty("board", CardVO.BOARD_FACE) --todo
		elseif toIndex_ >= SeedGrade.HEAD_COLLECT_1 and toIndex_ <= SeedGrade.HEAD_COLLECT_MAX then --如果是往集牌区放牌，则把牌翻正
			temCard:setProperty("board", CardVO.BOARD_FACE)
		end
		temCard = temCard:getNextCard()
	end

	local to_ = self.headsList_[toIndex_]
	local toEnd_ = DealerController.getQueueEndCardVO(to_)

	card:setBeforeCard(toEnd_)
	if toEnd_ then
		toEnd_:setNextCard(card)
	else
		self.headsList_[toIndex_] = card
	end

	if toIndex_ >= SeedGrade.HEAD_COLLECT_1 and toIndex_ <= SeedGrade.HEAD_COLLECT_MAX  then
		-- EventNoticeManager:getInstance():dispatchEvent({name = Notice.USER_AIDATA_CHANGE})
	end

	if call then
		call()
	end
end

--打印AI牌局
function SeedGrade:printCol()
	printf(" ================================ ")
	printf(" ------[集牌区]------  --[切牌区]--")
	local arr_ = {}
	for i=SeedGrade.HEAD_COLLECT_1,SeedGrade.HEAD_COLLECT_MAX do
		local name_ = "    |"
		if self.headsList_[i] then
			local card = DealerController.getQueueEndCardVO(self.headsList_[i])
			if card then
				local ss_ = " |"
				if card.rank_ == CardVO.RANK_TEN then
					ss_ = "|"
				end
				name_ = card:getCardName()..ss_
			end
		end
		arr_[#arr_ + 1] = name_
	end
	for i=SeedGrade.HEAD_CHANGE_1,SeedGrade.HEAD_CHANGE_MAX do
		local name_ = "    |"
		if i == SeedGrade.HEAD_CHANGE_1 then
			if self.headsList_[i] then
				local card = DealerController.getQueueEndCardVO(self.headsList_[i])
				if card then
					local ss_ = " |"
					if card.rank_ == CardVO.RANK_TEN then
						ss_ = "|"
					end
					name_ = card:getCardName()..ss_
				end
			end
		else
			if self.headsList_[i] then
				name_ = "  ? |"
			end
		end
		arr_[#arr_ + 1] = name_
	end
	printf("  |%s%s%s%s====|%s%s", arr_[1], arr_[2], arr_[3], arr_[4], arr_[5], arr_[6])
	printf(" -------------[玩牌区]------------- ")
	local arrList_ = {}
	local len_ = 7
	for i=SeedGrade.HEAD_COLUMN_1,SeedGrade.HEAD_COLUMN_MAX do
		local list_ = DealerController.getListByHead(self.headsList_[i])
		if len_ < #list_ then
			len_ = #list_
		end
		arrList_[i] = list_
	end

	for i=1,len_ do
		-- 第1列
		local str1_ = "    |"
		local card1_ = arrList_[1][i]
		if card1_ then
			if card1_.board_ == CardVO.BOARD_BACK then
				str1_ = "  ? |"
			else
				local ss_ = " |"
				if card1_.rank_ == CardVO.RANK_TEN then
					ss_ = "|"
				end
				str1_ = card1_:getCardName()..ss_
			end
		end
		-- 第2列
		local str2_ = "    |"
		local card2_ = arrList_[2][i]
		if card2_ then
			if card2_.board_ == CardVO.BOARD_BACK then
				str2_ = "  ? |"
			else
				local ss_ = " |"
				if card2_.rank_ == CardVO.RANK_TEN then
					ss_ = "|"
				end
				str2_ = card2_:getCardName()..ss_
			end
		end
		-- 第3列
		local str3_ = "    |"
		local card3_ = arrList_[3][i]
		if card3_ then
			if card3_.board_ == CardVO.BOARD_BACK then
				str3_ = "  ? |"
			else
				local ss_ = " |"
				if card3_.rank_ == CardVO.RANK_TEN then
					ss_ = "|"
				end
				str3_ = card3_:getCardName()..ss_
			end
		end
		-- 第4列
		local str4_ = "    |"
		local card4_ = arrList_[4][i]
		if card4_ then
			if card4_.board_ == CardVO.BOARD_BACK then
				str4_ = "  ? |"
			else
				local ss_ = " |"
				if card4_.rank_ == CardVO.RANK_TEN then
					ss_ = "|"
				end
				str4_ = card4_:getCardName()..ss_
			end
		end
		-- 第5列
		local str5_ = "    |"
		local card5_ = arrList_[5][i]
		if card5_ then
			if card5_.board_ == CardVO.BOARD_BACK then
				str5_ = "  ? |"
			else
				local ss_ = " |"
				if card5_.rank_ == CardVO.RANK_TEN then
					ss_ = "|"
				end
				str5_ = card5_:getCardName()..ss_
			end
		end
		-- 第6列
		local str6_ = "    |"
		local card6_ = arrList_[6][i]
		if card6_ then
			if card6_.board_ == CardVO.BOARD_BACK then
				str6_ = "  ? |"
			else
				local ss_ = " |"
				if card6_.rank_ == CardVO.RANK_TEN then
					ss_ = "|"
				end
				str6_ = card6_:getCardName()..ss_
			end
		end
		-- 第7列
		local str7_ = "    |"
		local card7_ = arrList_[7][i]
		if card7_ then
			if card7_.board_ == CardVO.BOARD_BACK then
				str7_ = "  ? |"
			else
				local ss_ = " |"
				if card7_.rank_ == CardVO.RANK_TEN then
					ss_ = "|"
				end
				str7_ = card7_:getCardName()..ss_
			end
		end

		printf("  |%s%s%s%s%s%s%s", str1_, str2_, str3_, str4_, str5_, str6_, str7_)
	end
end

function SeedGrade:getCollectionEndCardVO( _headindex )
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

function SeedGrade:MaxMinWithValue( valueTable )
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

function SeedGrade:JudgeQuickCollection( cardSp )
	local m_tabCollectRed = {}
	local m_tabCollectBlack = {}
	local m_tabCollect = {}
	local m_tabCollectEmpty = {}
	--不可快速集牌数组
	local m_notFastCollect = {}
	--判断集牌区
	for i=SeedGrade.HEAD_COLLECT_1,SeedGrade.HEAD_COLLECT_MAX do
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

function SeedGrade:autoQuickCollection()
	function collect( headIndex )
		if headIndex < SeedGrade.HEAD_COLLECT_1 or headIndex > SeedGrade.HEAD_COLLECT_MAX then
			return false
		end
		local suit = 0
		local rank = 0
		local end_card = self.headsList_[headIndex]
		if end_card then
			end_card = DealerController.getQueueEndCardVO(end_card)
			suit = end_card:getProperty("suit")
			rank = end_card:getProperty("rank") 
		end
		-- --玩牌区
		-- for i=SeedGrade.HEAD_COLUMN_1,SeedGrade.HEAD_COLUMN_MAX do 
		-- 	local calast_cardrd = self.headsList_[i]
		-- 	if last_card then
		-- 		last_card = DealerController.getQueueEndCardVO(last_card)
		-- 		local aiMoveVO_ = self:judgeCollect1_(end_card, last_card, rank, suit, headIndex)
		-- 		if aiMoveVO_ then
		-- 			-- return true,aiMoveVO_
		-- 		end
		-- 	end
		-- end

		for i = SeedGrade.HEAD_CHANGE_1,SeedGrade.HEAD_CHANGE_MAX do
			local last_card = self.headsList_[i]
			print('change_max--->>>',i)
			while last_card do
				-- last_card = DealerController.getQueueEndCardVO(last_card)
				printf("名字 %s--->>>>%s",last_card:getCardName(),last_card:getNextCard())
				local aiMoveVO_ = self:judgeCollect1_(end_card, last_card, rank, suit, headIndex)
				if aiMoveVO_ then
					return true,aiMoveVO_
				end
				last_card = last_card:getNextCard()
			end
		end
		return false
	end
	function collectCard( ... )
		for i = SeedGrade.HEAD_COLLECT_1,SeedGrade.HEAD_COLLECT_MAX do
			local ok,aiMoveVO_ = collect(i)
			print("--->>>>>>",i,ok,aiMoveVO_)
			-- dump(aiMoveVO_)
			if ok  and aiMoveVO_ then
				printf("[AI] -- :快速收取 %s",aiMoveVO_.card_:getCardName())
				self.isQuick = true
				self:doMoveLogic1_(aiMoveVO_)
			end
			if i == SeedGrade.HEAD_COLLECT_MAX and ok == false then
				self.isQuick = false
				if self.scheduleHandle then
			        scheduler.unscheduleGlobal(self.scheduleHandle)
			        self.scheduleHandle = nil
			    end
			end
		end
	end
	collectCard()
end

function SeedGrade:doMoveLogic1_(aiMoveVO,call)
	if not aiMoveVO then
		return
	end
	local card = aiMoveVO.card_
	if not card then
		return
	end

	--防死循环处理
	self:recordMoveStep_(aiMoveVO)

	local before_ = card:getBeforeCard()
	if before_ then
		before_:setNextCard(nil)
		--如果是属于玩牌区的移动，且有before_，则要把before_翻成正面
		if card.headIndex_ >= SeedGrade.HEAD_COLUMN_1 and card.headIndex_ <= SeedGrade.HEAD_COLUMN_MAX then
			before_:setProperty("board", CardVO.BOARD_FACE)
		end
	else
		self.headsList_[card.headIndex_] = nil
		if card.headIndex >= SeedGrade.HEAD_CHANGE_1 and card.headIndex <= SeedGrade.HEAD_CHANGE_MAX then
			--保持原链接的完整性
			if card:getBeforeCard() then
				--当card_next不是队首时，需要链接其前后两张
				card:getBeforeCard():setNextCard(card:getNextCard())
			else
				--当card_next是队首时，需要将headlist设置为它的下一张牌
				self.headsList_[card:getProperty("headIndex")] = card:getNextCard()
			end
			if card:getNextCard() then
				card:getNextCard():setBeforeCard(card:getBeforeCard())
			end
		end
	end

	local toIndex_ = aiMoveVO.toIndex_
	local temCard = card
	while temCard do
		temCard:setProperty("headIndex", toIndex_)
		if toIndex_ == BattleAI.HEAD_CHANGE_1 then --如果是往切牌区(已打开)放牌，则把牌翻正
			temCard:setProperty("board", CardVO.BOARD_FACE)
		elseif toIndex_ == BattleAI.HEAD_CHANGE_MAX then --如果是往切牌区(未打开)放牌，则把牌翻背
			temCard:setProperty("board", CardVO.BOARD_BACK)
		elseif toIndex_ >= BattleAI.HEAD_COLLECT_1 and toIndex_ <= BattleAI.HEAD_COLLECT_MAX then --如果是往集牌区放牌，则把牌翻正
			temCard:setProperty("board", CardVO.BOARD_FACE)
		end
		temCard = temCard:getNextCard()
	end

	local to_ = self.headsList_[toIndex_]
	local toEnd_ = DealerController.getQueueEndCardVO(to_)

	card:setBeforeCard(toEnd_)
	if toEnd_ then
		toEnd_:setNextCard(card)
	else
		self.headsList_[toIndex_] = card
	end

end

function SeedGrade:judgeCollect1_(card_before, card_next, rank, suit, headIndex)
	local m_isCollect = self:JudgeQuickCollection(card_next)
	if (rank == 0 or card_next:getProperty("suit") == suit) and card_next:getProperty("rank") == rank + 1 and m_isCollect then
		local aiMoveVO_ = AIMoveVO.new({
			card = card_next,
			toIndex = headIndex,
		})
		return aiMoveVO_
	end
end

function SeedGrade:aiQucikCollect_()
	local aiMoveVO_ = self:autoQuickCollection()
end

return SeedGrade