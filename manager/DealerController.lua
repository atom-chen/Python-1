--
-- Author: Huang Hai Long
-- Date: 2016-04-20 17:54:19
--

local DealerController = {}
local isSupportSocket, socket = pcall(function()
	return require("socket")
end)
--生成牌组
function DealerController.initCards(deckNum, suitNum)
	local cardList_ = {}
	local deckNum_ = deckNum or 1--几副牌
	local suitNum_ = suitNum or 4--几种花色
	-- for _deck=1,deckNum_ do
	-- 	for _suit=1,4 do
	-- 		for _rank=1,13 do
	-- 			local cardVO_ = CardVO.new({
	-- 				deck = _deck, --第几副牌
	-- 				suit = _suit, --花色
	-- 				rank = _rank, --点数
	-- 				})
	-- 			cardList_[#cardList_ + 1] = cardVO_
	-- 		end
	-- 	end
	-- end

	for i=1,deckNum_ * 4 do
		local _deck = math.floor((i-1) / suitNum_) + 1
		local _suit = (i-1) % suitNum_ + 1
		for _rank=1,13 do
			local cardVO_ = CardVO.new({
				deck = _deck, --第几副牌
				suit = _suit, --花色
				rank = _rank, --点数
				})
			cardList_[#cardList_ + 1] = cardVO_
		end
	end
	
	return cardList_
end

--洗牌
function DealerController.shuffleCards(list, seed)
	local seed_
	if seed then
		seed_ = seed
	elseif isSupportSocket then
		seed_ = string.reverse(string.format("%.0f",socket.gettime()*1000))
		printf("使用随机种子：%s",seed_)
	else
		seed_ = string.reverse(tostring(os.time()))
	end
	math.randomseed(seed_)

	local shuffleList_ = {}
	for i=#list,1,-1 do
		local random_ = math.random(#list)
		shuffleList_[#shuffleList_ + 1] = list[random_]
		table.remove(list,random_)
	end
	return shuffleList_,seed_
end

--判断点数是否为K
function DealerController.judgeRankEquiK(cardVO)
	return cardVO:getProperty("rank") == CardVO.RANK_KING
end

--判断点数是否为A
function DealerController.judgeRankEquiA(cardVO)
	return cardVO:getProperty("rank") == CardVO.RANK_ACE
end

--判断花色是否相同
function DealerController.judgeSuit(cardVO_before,cardVO_next)
	if not cardVO_before then
		return false
	end
	if not cardVO_next then
		return false
	end
	return cardVO_before:getProperty("suit") == cardVO_next:getProperty("suit")
end

--判断点数是否可以链接
function DealerController.judgeRankLink(cardVO_before,cardVO_next)
	if not cardVO_before then
		return false
	end
	if not cardVO_next then
		return false
	end
	return (cardVO_before:getProperty("rank") - 1) == cardVO_next:getProperty("rank")
end

--判断色系是否相同
function DealerController.judgeColor(cardVO_before,cardVO_next)
	if not cardVO_before then
		return false
	end
	if not cardVO_next then
		return false
	end
	return cardVO_before:getCardColor() == cardVO_next:getCardColor()
end

--连牌判断
function DealerController.judgeLinking(cardVO_before,cardVO_next)
	if GAME_MODE == GAME_MODE_SPIDER 
		or GameManager:getModeType() == GameManager.MODETYPE_SPIDER then
		--连牌判断Spider --注意spider可连牌不一定可拾取，点数相同就可以连
		if not cardVO_before then --这是另起一列的情况
			return true
		end
		if not DealerController.judgeRankLink(cardVO_before,cardVO_next) then --点数不可连接
			return false
		end
	else
		if not cardVO_before then --这是另起一列的情况
			return DealerController.judgeRankEquiK(cardVO_next) --判断牌头是否是K
		end
		if DealerController.judgeColor(cardVO_before,cardVO_next) then --色系相同
			return false
		end
		if not DealerController.judgeRankLink(cardVO_before,cardVO_next) then --点数不可连接
			return false
		end
	end

	return true
end

--连牌判断FreeCell
function DealerController.judgeLinkingFreeCell(cardVO_before,cardVO_next)
	if not cardVO_before then --这是另起一列的情况
		return true
	end
	if DealerController.judgeColor(cardVO_before,cardVO_next) then --色系相同
		return false
	end
	if not DealerController.judgeRankLink(cardVO_before,cardVO_next) then --点数不可连接
		return false
	end

	return true
end

--通过头牌获取链表长度
function DealerController.getQueueLenByHead(cardVO)
	local len = 0
	local head_ = cardVO
	if not head_ then
		return len
	end
	len = len + 1
	while head_:getProperty("next") do
		len = len + 1
		head_ = head_:getProperty("next")
	end
	return len
end

--通过头牌获取list
function DealerController.getListByHead(cardVO)
	local list_ = {}
	local head_ = cardVO
	if not head_ then
		return list_
	end
	list_[1] = head_
	while head_:getProperty("next") do
		list_[#list_ + 1] = head_:getProperty("next")
		head_ = head_:getProperty("next")
	end
	return list_
end	

--通过尾牌索引卡牌
function DealerController.getCardByCountFromBottom(cardVO,count)
	if cardVO and cardVO:getProperty("before") and count > 1 then
		return DealerController.getCardByCountFromBottom(cardVO:getProperty("before"),count-1)
	else
		return cardVO
	end
end

--索引出该列的第一张正面的卡牌
function DealerController.getFirstFaceCardFromHead( card )
	if not card then
		return nil
	end
	if card:getProperty("board") == CardVO.BOARD_FACE then
		return card
	else
		return DealerController.getFirstFaceCardFromHead( card:getNextCard() )
	end
end

--通过尾牌获取链表长度
function DealerController.getQueueLenByBottom(cardVO)
	local len = 0
	local bottom_ = cardVO
	if not bottom_ then
		return len
	end
	len = len + 1
	while bottom_:getProperty("before") do
		len = len + 1
		bottom_ = bottom_:getProperty("before")
	end
	return len
end

--获取链表最末尾的一张牌
function DealerController.getQueueEndCardVO(cardVO)
	if not cardVO then
		return
	end
	local end_ = cardVO
	while end_:getProperty("next") do
		end_ = end_:getProperty("next")
	end
	return end_
end

--落牌判断
function DealerController.judgePutDown(cardVO_before,cardVO_next)
	if cardVO_before then
		cardVO_before = DealerController.getQueueEndCardVO(cardVO_before)
	end
	return DealerController.judgeLinking(cardVO_before,cardVO_next)
end

--落牌判断FreeCell
function DealerController.judgePutDownFreeCell(cardVO_before,cardVO_next)
	if cardVO_before then
		cardVO_before = DealerController.getQueueEndCardVO(cardVO_before)
	end
	return DealerController.judgeLinkingFreeCell(cardVO_before,cardVO_next)
end

--拾牌判断
DealerController.PICK_NULL = 0 --无牌
DealerController.PICK_BACK = 1 --牌背
DealerController.PICK_LOCK = 2 --被压住
DealerController.PICK_ABLE = 3 --可以拾起
function DealerController.judgePickUp(cardVO)
	if not cardVO then
		return DealerController.PICK_NULL
	end
	if cardVO:getProperty("board") == CardVO.BOARD_BACK then
		return DealerController.PICK_BACK
	end
	local cardVO_next = cardVO:getProperty("next")
	if not cardVO_next then
		return DealerController.PICK_ABLE --如果他没有下一张，说明可拾取
	end

	if GAME_MODE == GAME_MODE_SPIDER 
		or GameManager:getModeType() == GameManager.MODETYPE_SPIDER then
		--前后两张牌颜色需相同
		if not DealerController.judgeSuit(cardVO,cardVO_next) then
			return DealerController.PICK_LOCK
		end
		--前后两张点数需相连
		if not DealerController.judgeRankLink(cardVO,cardVO_next) then
			return DealerController.PICK_LOCK
		end
	else
		--判断当前牌和他的下一张是否连接
		if not DealerController.judgeLinking(cardVO,cardVO_next) then
			return DealerController.PICK_LOCK
		end
	end

	return DealerController.judgePickUp(cardVO_next) --如果当前牌可连接，那判断他的下一张
end

--根据牌头找出该列可移动的牌
function DealerController.findCanMoveCardByHead(cardVO)
	local result_ = DealerController.judgePickUp(cardVO)
	if result_ == DealerController.PICK_NULL then
		return
	end
	if result_ == DealerController.PICK_ABLE then
		return cardVO
	end
	return DealerController.findCanMoveCardByHead(cardVO:getProperty("next"))
end

--链接
function DealerController.linkTwoCard(cardVO_before,cardVO_next)
	if not cardVO_next then
		return
	end
	--先把cardVO_next的原父节点(如果存在)的next置空
	local oldBefor_ = cardVO_next:getProperty("before")
	if oldBefor_ then
		oldBefor_:setNextCard(nil)
	end
	--把现在的父节点设置为cardVO_before
	cardVO_next:setBeforeCard(cardVO_before)
	if not cardVO_before then --如果cardVO_before为空说明是另起一列的情况
		return
	end
	--把cardVO_before的子节点设置为cardVO_next
	cardVO_before:setNextCard(cardVO_next)
end

--判断点数是否可以回收
function DealerController.judgeRankCollect(cardVO_before,cardVO_next)
	if not cardVO_before then
		return false
	end
	if not cardVO_next then
		return false
	end
	return (cardVO_before:getProperty("rank") + 1) == cardVO_next:getProperty("rank")
end

--判断是否可回收card_next这张牌
function DealerController.judgeCollectCard(cardVO_before,cardVO_next,ignoreLast)
	if cardVO_before then
		cardVO_before = DealerController.getQueueEndCardVO(cardVO_before)
	end
	if not ignoreLast then
		if cardVO_next:getNextCard() then
			--判断收集是必须是最后一张
			return false
		end
	end
	
	if not cardVO_before then
		return DealerController.judgeRankEquiA(cardVO_next)
	end
	if not DealerController.judgeSuit(cardVO_before,cardVO_next) then --花色不相同
		return false
	end
	if not DealerController.judgeRankCollect(cardVO_before,cardVO_next) then --点数不可回收
		return false
	end
	return true
end

--通过队头将该队列逆向然后返回新队头 (head必须为队头)
function DealerController.reverseQueueByCardVO(head)
	local dataList_ = DealerController.getListByHead(head)
	if #dataList_ < 2  then
		return head
	end
	local headBefore_ = head:getProperty("before")
	local bottomNext_ = dataList_[#dataList_]:getProperty("next")
	for i=1,#dataList_ do
		local before_ = dataList_[i]:getProperty("next")
		local next_ = dataList_[i]:getProperty("before")
		if i == 1 then
			next_ = bottomNext_
		end
		if i == #dataList_ then
			before_ = headBefore_
		end
		dataList_[i]:setBeforeCard(before_)
		dataList_[i]:setNextCard(next_)
	end
	return dataList_[#dataList_]
end

--判断队列牌点数是否为降序(FreeCell收牌用)
function DealerController.judgeQueueDescendingByHead(head)
	if not head then
		return true
	end
	local valueBefore_ = head:getProperty("rank")
	local valueNext_ = 0
	local next_ = head:getNextCard()
	if next_ then
		valueNext_ = next_:getProperty("rank")
	end
	if valueNext_ <= valueBefore_ then
		return DealerController.judgeQueueDescendingByHead(next_)
	end
	return false
end

--根据空列和空位得出可移动的队列最大长度(FreeCell)
function DealerController.getQueueMoveLength(eColumns,eFreeCell)
	local len_ = 0
	if not eColumns or not eFreeCell then
		return len_
	end
	if eColumns > 2 then
		eColumns = 2
	end
	len_ = (eFreeCell + 1)*math.pow(2,eColumns)
	-- len_ = 52
	return len_
end

--判断是否可收(tripeaks)
function DealerController.tripeaksCanCollect(card1,card2)
	local rank1_ = card1:getProperty("rank")
	local rank2_ = card2:getProperty("rank")
	local dValue = math.abs(rank1_ - rank2_)
	if dValue == 1 then
		return true
	end
	if rank1_ == CardVO.RANK_ACE and rank2_ == CardVO.RANK_KING then
		return true
	end
	if rank1_ == CardVO.RANK_KING and rank2_ == CardVO.RANK_ACE then
		return true
	end
	return false
end

--判断相关联子节点(tripeaks)
function DealerController.tripeaksGetChildrenByPos(index)
	local children = BattleManagerTriPeaks.POS_CHILDREN[index] or {}
	return children
end

--判断相关联父节点(tripeaks)
function DealerController.tripeaksGetParentsByPos(index)
	local parents = {}
	for k,v in pairs(BattleManagerTriPeaks.POS_CHILDREN) do
		for i=1,#v do
			if index == v[i] then
				parents[#parents + 1] = k
				break
			end
		end
	end
	return parents
end

--判断相关联子节点(pyramid)
function DealerController.pyramidGetChildrenByPos(index)
	local children = BattleManagerPyramid.POS_CHILDREN[index] or {}
	return children
end

--判断是否可收(pyramid)
function DealerController.pyramidCanCollect(card1,card2)
	local rank1_ = 0
	if card1 then
		rank1_ = card1:getProperty("rank")
	end
	local rank2_ = 0
	if card2 then
		rank2_ = card2:getProperty("rank")
	end
	local dValue = rank1_ + rank2_
	if dValue == 13 then
		return true
	end
	return false
end

return DealerController
