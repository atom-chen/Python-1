--
-- Author: Huang Hai Long
-- Date: 2016-10-17 11:17:22
--
local BattleManagerAI = class("BattleManagerAI",function()
	return display.newNode()
end)

BattleManagerAI.HEAD_COLUMN_1 = 1		--牌桌
BattleManagerAI.HEAD_COLUMN_2 = 2
BattleManagerAI.HEAD_COLUMN_3 = 3
BattleManagerAI.HEAD_COLUMN_4 = 4
BattleManagerAI.HEAD_COLUMN_5 = 5
BattleManagerAI.HEAD_COLUMN_6 = 6
BattleManagerAI.HEAD_COLUMN_MAX = 7

BattleManagerAI.HEAD_COLLECT_1 = 8	--集牌区
BattleManagerAI.HEAD_COLLECT_2 = 9
BattleManagerAI.HEAD_COLLECT_3 = 10
BattleManagerAI.HEAD_COLLECT_MAX = 11

BattleManagerAI.HEAD_CHANGE_1 = 12	--换牌区,已打开
BattleManagerAI.HEAD_CHANGE_MAX = 13	--换牌区，未打开

BattleManagerAI.RESERVE_NUM = 24 --切牌时预留的张数

BattleManagerAI.END_ANI_NONE = 0
BattleManagerAI.END_ANI_COLLECTING = 1--收集
BattleManagerAI.END_ANI_STUFF = 2--洗牌
BattleManagerAI.END_ANI_DIALOG = 3--结算窗
BattleManagerAI.END_ANI_END = 4--结束

BattleManagerAI.FIRST_COLLECT_SCORE = 2
BattleManagerAI.COLLECT_SCORE = 1
BattleManagerAI.PASS_COLLECT_SCORE = 50

BattleManagerAI.delayEndCd = 120 --延迟结束时间

function BattleManagerAI.test(_type)
	local list_ = {}
	local compitionVO_ = CompitionVO.new({
			isDraw3Mode = (_type>2 and 1) or 0,--是否是三张牌
		})

	local len_ = 1
	if _type%2 == 0 then
		len_ = 3
	end
	for i=1,len_ do
		local level_ = "normal"
		-- if i == 2 then
		-- 	level_ = "normal"
		-- elseif i == 3 then
		-- 	level_ = "easy"
		-- end
		local playerInfoVO = PlayerInfoVO.new({
				playername = "player"..i,--玩家名称
				avatarname = "avatar_"..(i+1)..".png",--玩家头像
				level = level_,--难度
			})
		list_[#list_ + 1] = playerInfoVO
	end
	return list_ ,compitionVO_
end

function BattleManagerAI:ctor( delegate ,compitionVO, list)
	GameManager:getAudioData():stopAllAudios()
	KMultiLanExtend.extend(self)
	-- local _list,_compitionVO = BattleManagerAI.test(2)
	assert(compitionVO, "BattleManagerAI:比赛数据不能为nil!")
	assert(list, "BattleManagerAI:比赛成员列表不能为nil!")
	self.players_ = list --or _list
	self.compitionVO_ = compitionVO --or _compitionVO
	self:setDelegate(delegate)

	self:initView_()
	self.outOfFlips:setVisible(false)
	self.sp_no:setVisible(false)
	self.btn_autoCollect:setVisible(false)
	self.headsList_ = {}
	self.flipCardRound = 0--翻牌的轮数
	self.score_ = 0 --分数
	self.scoreNum_ = 0
	self.magicNum_ = 0
	self.undo_ = 0
	self.seed_ = "0"
	self.playerNum_ = #self.players_
	self.delayTime_ = nil
	self.isDraw3_ = (self.compitionVO_.isDraw3Mode_ == 1)
	--是否展示移动动画
	self.showMoveAni_ = true
	self.cardMoving_ = false
	self.ending_ = false

	self.over_ = false

	GameManager:getUserClassicData():addEnterGameTotalCount("4",1)

	--初始化牌组
	self:startGame(nil)

	self:setNodeEventEnabled(true)
	-- self:test()

	self:hideNotice_()
	self:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT,handler(self, self.updateAI_))
	self:scheduleUpdate_()
	--添加AI定时刷新逻辑
	-- self:scheduleUpdate(function(t)
	-- 	self:updateAI_(t)
	-- 	end)
	
	self.totalNum_ = self.playerNum_+1
	--统计 开局
	local analytice_ = string.format("%s张牌_%s人:开局",((self.isDraw3_ and 3) or 1),tostring(self.totalNum_))
	Analytice.onEvent(analytice_, {})
	-- printf("Analytice == %s",tostring(analytice_))
end

--添加打点数据
function BattleManagerAI:getEventInfo_()
	if not self.compitionVO_ then
		return 
	end

	local seed = self.seed_ or ""
	local threeMode = self.compitionVO_.isDraw3Mode_

	local draw_ = "1"
	if tostring(threeMode) == "1" then
		draw_ = "3"
	end
	local str_player = ""
	
	if self.totalNum_ == 2 then
		str_player = "in2"
	elseif self.totalNum_ == 4 then
		str_player = "in4"
	end

	local m_playerNumber = #self.players_ + 1
	str_player = m_playerNumber .. str_player

	local info_ = {
		seed = self.seed_ or "",
		draw = draw_,
		player = str_player,
	}

	return info_
end

function BattleManagerAI:enteBattleDot( ... )
	local eventInfo_ = self:getEventInfo_() or {}
	eventInfo_.action = "play"
	local m_totalTournament = GameManager:getUserClassicData():getTotalCountByType("totalTournament")
	eventInfo_.sum = m_totalTournament
	self:addTotalCountEvent_(m_totalTournament)
	Analytice.onEventThinkingData("tournament", eventInfo_)
end

function BattleManagerAI:addTotalCountEvent_( value )
	local eventInfo_ = {}
	eventInfo_.sum_enter_tournament = tostring(value)
	Analytice.onEventuserProperty("sum_enter_tournament", tostring(value))
end

function BattleManagerAI:completeBattleDot( _type )
	local eventInfo_ = self:getEventInfo_()
	local score_ = self.score_
	eventInfo_.score = score_
	eventInfo_.magic = self.magicNum_
	eventInfo_.undo = self.undo_
	Analytice.onEventThinkingData("completeBattle", eventInfo_)

end

function BattleManagerAI:setOver()
	self.over_ = true
	if self.delegate_ and self.delegate_.setEndBtnVisible then
		self.delegate_:setEndBtnVisible(false)
	end
	self:setDelayEnd_()
	self:updataTopView_(UserAIPlayerInfoVO.me)
	self:judgeAllOver_()
end

function BattleManagerAI:setDelayEnd_()
	if not self.aiList_ then
		return
	end
	for i=1,#self.aiList_ do
		self.aiList_[i]:setDelayEnd()
	end
end

function BattleManagerAI:reset()
	self:starNewGame( nil , #self.players_)
	--开启AI
	self:beginAI_()
end

function BattleManagerAI:addScore_(add)
	if add == 0 then
		return
	end

	self.score_ = self.score_ + add
	if self.score_ < 0 then
		self.score_ = 0
	end

	self:updataTopView_(UserAIPlayerInfoVO.me)	
end

-- function BattleManagerAI:test( )
-- 	local params = {
-- 		listener = handler(self, self.setListener_),
-- 		image = "#ui_none.png",
-- 		size = CCSizeMake(360, 40),
-- 		x = 0,--point.x,
-- 		y = -3,--point.y,
-- 	}
-- 	self.messageEd_ = ui.newEditBox(params)
-- 	self.messageEd_:setAnchorPoint(ccp(0, 0.5))
-- 	self:addChild(self.messageEd_)
-- 	self.messageEd_:setPlaceHolder(Localization.string("点击输入种子"))
-- 	self.messageEd_:setPlaceholderFontColor(ccc3(48, 26, 12))
-- 	self.messageEd_:setFontColor(ccc3(48, 26, 12))
-- 	self.messageEd_:setInputFlag(kEditBoxInputFlagSensitive)
-- 	self.messageEd_:setReturnType(kKeyboardReturnTypeDone)
-- 	self.messageEd_:setInputMode(kEditBoxInputModeAny)
-- 	self.messageEd_:setPosition(ccp(0, 200))

-- 			local params_ = {
-- 				font = common.LabelFont,
-- 				size = 40,
-- 			}
-- 			local label = ui.newTTFLabel(params_)
-- 			local normal = display.newScale9Sprite("#B_green.png")
-- 			local pressed = display.newScale9Sprite("#B_green.png")
-- 			local disabled = display.newScale9Sprite("#B_green.png")
-- 			local btn = CCControlButton:create(label, normal)
-- 			btn:setLabelAnchorPoint(ccp(0.5,0.35))
-- 			btn:setPreferredSize(CCSizeMake(200, 80))
-- 			btn:setBackgroundSpriteForState(pressed, CCControlStateHighlighted)
-- 			btn:setBackgroundSpriteForState(disabled, CCControlStateDisabled)
-- 			btn:setZoomOnTouchDown(true)
-- 			btn:addHandleOfControlEvent(function()
-- 					local num = tonumber(self.editSeed_)
-- 					if num then
-- 						self:starNewGame(num)
-- 					end
-- 				end,CCControlEventTouchUpInside)
-- 			self:setBtnTitle(btn, "确认")
-- 			self:addChild(btn)
-- 			btn:setPosition(ccp(500, 200))
-- end

function BattleManagerAI:setListener_(event, editbox)
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

function BattleManagerAI:onEnter( )
	EventNoticeManager:getInstance():addEventListener(self,Notice.APP_ENTER_BACKGROUND,handler(self, self.gameEnterBackground_))
	EventNoticeManager:getInstance():addEventListener(self,Notice.USER_DATA_CHANGE,handler(self, self.leftModeChanged))
	EventNoticeManager:getInstance():addEventListener(self,Notice.USER_LANGUAGE_CHANGE,handler(self, self.setLocalization_))
    EventNoticeManager:getInstance():addEventListener(self,Notice.USER_CARD_CHANGE,handler(self, self.updataAllCards))
    
    EventNoticeManager:getInstance():addEventListener(self,Notice.USER_AILOGIC_END,handler(self, self.aiLogicEnd_))
    EventNoticeManager:getInstance():addEventListener(self,Notice.USER_AIDATA_CHANGE,handler(self, self.aiDataChange_))

    EventNoticeManager:getInstance():addEventListener(self,Notice.MANAGER_TIME_UPDATA,handler(self, self.timeUpdata_))
   	
   	EventNoticeManager:getInstance():addEventListener(self,Notice.NETWORK_COMPLETE_ENDBATTLE,handler(self, self.successEndBattle_))
   	EventNoticeManager:getInstance():addEventListener(self,Notice.NETWORK_COMPLETE_ENDBATTLE_ERROR,handler(self, self.failEndBattle_))
    --开启AI
	self:beginAI_()

	if self.isPortrait_() then
		--底部广告
		GameManager:getAdManager():showBottomBannar(common.BannerAdPos.BOTTOM)
	end
end

function BattleManagerAI:setLocalization_( )
	self:setBtnTitle(self.btn_autoCollect, "自动收牌")
end

function BattleManagerAI:onExit( )
	EventNoticeManager:getInstance():removeEventListenerForHandle(self)
	GameManager:getAdManager():hiddenBottomBannar()
end

function BattleManagerAI:getHeadsList()
	return self.headsList_ or {}
end

function BattleManagerAI:isAIAllOver_()
	local over_ = true
	if not self.aiList_ then
		return over_
	end
	for i=1,#self.aiList_ do
		if self.aiList_[i]:getAIStatus() ~= BattleAI.AI_STATUS_END then
			over_ = false
			break
		end
	end
	return over_
end

function BattleManagerAI:judgeAllOver_()
	if not self.over_ then
		return
	end
	local aiAllOver_ = self:isAIAllOver_()
	if not aiAllOver_ then
		return 
	end
	self:endLogic_()
end

function BattleManagerAI:aiLogicEnd_(event)
	-- printf("------aiLogicEnd-----")
	self:updataTopView_(UserAIPlayerInfoVO.opponent)

	--AI 通关 被迫结束
	if event.win then
		self:endLogic_()
		return
	end
	self:judgeAllOver_()
	
end

function BattleManagerAI:aiDataChange_(event)
	self:updataTopView_(UserAIPlayerInfoVO.opponent)	
end

function BattleManagerAI:updataAllCards(event)
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

function BattleManagerAI:gameEnterBackground_( )
end


function BattleManagerAI:starNewGame( seed , num)
	GameManager:getUserGameCacheData():cleanBattleStepList()
	self:clearLight_()
	self:stopAllActions()
	self.card_table:removeAllChildren()
	self.headsList_ = {}
	self.flipCardRound = 0
	self.score_ = 0
	self.scoreNum_ = 0
	self.playerNum_ = num
	self.over_ = false
	self.ending_ = false
	self.delayTime_ = nil
	--是否展示移动动画
	self.showMoveAni_ = true
	self.cardMoving_ = false
	self:hideNotice_()
	--初始化牌组
	self:startGame(seed)
end

function BattleManagerAI:updataTopView_(playerType)
	self:updataPlayerList_(playerType)
	self:createSortPlayerList_()
	if playerType == UserAIPlayerInfoVO.me then
		-- self:updataHeadNode_(self.playerList_[1])
	end
	if self.battleTopInfoViewCtrl_ then
		self.battleTopInfoViewCtrl_:updataViewByData(self.sortPlayerList_)
	end
end

function BattleManagerAI:initTopInfoView_(node)
	if not node then
		return
	end
	if self.battleTopInfoViewCtrl_ then
		self.battleTopInfoViewCtrl_:getView():removeSelf(true)
		self.battleTopInfoViewCtrl_ = nil
	end

	local size = node:getContentSize()
	self.battleTopInfoViewCtrl_ = BattleTopInfoViewCtrl.new(size,self:isPortrait_())
	node:addChild(self.battleTopInfoViewCtrl_:getView())
	self.battleTopInfoViewCtrl_:updataViewByData(self.sortPlayerList_)
	self:updataHeadNode_(self.playerList_[1])
end

function BattleManagerAI:updataHeadNode_(userAIPlayerInfo)
	if not userAIPlayerInfo then
		return
	end
	if not self.headPos then
		return
	end
	self.headPos:setVisible(self.playerNum_ ~= 1)

	if not self.headIcon then
		self.headIcon = display.newSprite("#"..tostring(userAIPlayerInfo.avatarName_))
		self.headIcon:setPositionY(20-15)
		self.headIcon:setScale(0.58)
		self.headPos:addChild(self.headIcon)
	end

	if not self.scoreBg then
		self.scoreBg = display.newSprite("#ui_battleScoreBg.png")
		self.scoreBg:setPositionY(-35-15)
		self.headPos:addChild(self.scoreBg)
	end

	if not self.scoreLb then
		local params = {
			text = tostring(userAIPlayerInfo.score_),
			color = ccc3(255, 210, 0),
			font = common.NumberFont,
			size = 33,
		}
		self.scoreLb = ui.newTTFLabel(params)
		self.scoreLb:setPosition(ccp(self.scoreBg:getContentSize().width/2, self.scoreBg:getContentSize().height/2))
		self.scoreBg:addChild(self.scoreLb)
	end
	self.scoreLb:setString(tostring(userAIPlayerInfo.score_))
end

function BattleManagerAI:initView_( )

	--计算视图大小
	local isPortrait = self:isPortrait_()
	local displaySize = CCSizeMake(display.width, display.height)
	local ccbName_ = "ccb/battleAIView.ccbi"
	if isPortrait then
		ccbName_ = "ccb/battleAIView.ccbi"
		displaySize = CCSizeMake(USER_SCREEN_WIDTH, USER_SCREEN_HEIGHT)
	else
		ccbName_ = "ccb/battleAIView_landscape.ccbi"
		displaySize = CCSizeMake(display.width, display.height)--CCSizeMake(USER_DESIGN_LENGHT, USER_SCREEN_WIDTH)
	end
	self:setContentSize(displaySize)
	-- printf("initView === w:%s // h:%s", tostring(displaySize.width) , tostring(displaySize.height))
	--读取ccb文件
	local reader = CCBReader.new()
	local root = reader:load(ccbName_,"battleAIView",self,displaySize)
	root = tolua.cast(root,"CCNode")
	self:addChild(root)
	--设置按钮显示文字
	self:setLocalization_()

	if isPortrait then
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

		local offsetY = 205+18
		if not isPortrait then
			offsetY = 155+16
		end
		for i=BattleManagerAI.HEAD_COLUMN_1,BattleManagerAI.HEAD_COLUMN_MAX do
			if self["column"..i] then
				self["column"..i]:setPositionY(size.height- offsetY)
			end
		end
		offsetY = 83+15
		if not isPortrait then
			offsetY = 55+13
		end

		for i=BattleManagerAI.HEAD_COLLECT_1,BattleManagerAI.HEAD_CHANGE_MAX do
			if self["column"..i] then
				self["column"..i]:setPositionY(size.height- offsetY)
			end
		end
	else
		local offX_ = (display.width - 960)/2
		for i=BattleManagerAI.HEAD_COLUMN_1,BattleManagerAI.HEAD_COLUMN_MAX do
			if self["column"..i] then
				self["column"..i]:setPositionX(self["column"..i]:getPositionX()+offX_)
			end
		end
		-- if self.headPos then
		-- 	self.headPos:setPositionX(self.headPos:getPositionX()+offX_)
		-- end
	end
	
	self.tablePos_ = self.card_table:convertToWorldSpaceAR(self.card_table:getAnchorPoint())
	self.headBeginX_ = self.headPos:getPositionX()
	self.collectBeginX_ = self["column"..BattleManagerAI.HEAD_COLLECT_1]:getPositionX()
	
end

--设置卡槽以及图标主题
function BattleManagerAI:setCardsSlot(style)
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

function BattleManagerAI:startGame( seed )
	--初始化AI
	self:initAI_(self.playerNum_)
	self:updataCollectColumn_()
	self:initCard_(seed)
	--发牌
	self:startDealCard(true)
	--隐藏end按钮
	if self.delegate_ and self.delegate_.setEndBtnVisible then
		self.delegate_:setEndBtnVisible(false)
	end
	GameManager:getUserCache():addCompitionCount(1)
end

function BattleManagerAI:updataCollectColumn_()
	for i=BattleManagerAI.HEAD_COLLECT_1,BattleManagerAI.HEAD_COLLECT_MAX do
		self["column"..i]:setVisible(self.playerNum_ ~= 1)
	end
end

--获得AI的收牌状态
function BattleManagerAI:getAICollectStatus_(index)
	if not self.aiList_ then
		return
	end
	local list_ = self.aiList_[index]:getAICollectList()
	local result_ = {}
	for i=BattleManagerAI.HEAD_COLLECT_1,BattleManagerAI.HEAD_COLLECT_MAX do
		if list_[i] then
			local len_ = #list_[i]
			result_[i-BattleManagerAI.HEAD_COLLECT_1+1] = list_[i][len_]
		end
	end
	return result_
end

function BattleManagerAI:judgeCollectListExistCard_(card)
	for i=BattleManagerAI.HEAD_COLLECT_1,BattleManagerAI.HEAD_COLLECT_MAX do
		local cList_ = DealerController.getListByHead(self.headsList_[i])
		for j=1,#cList_ do
			if card.rank_ == cList_[j].rank_  --点数相同
				and card.suit_ == cList_[j].suit_ then --花色相同
				return true
			end
		end
	end

	for i=1,#self.aiList_ do
		if self.aiList_[i]:judgeCollectListExistCard(card) then
			return true
		end
	end

	return false
end

function BattleManagerAI:getAddScore(card)
	local add_ = BattleManagerAI.FIRST_COLLECT_SCORE
	if self:judgeCollectListExistCard_(card) then
		add_ = BattleManagerAI.COLLECT_SCORE
	end
	return add_
end

function BattleManagerAI:updataPlayerList_(pType)
	if not self.playerList_ then
		self.playerList_ = {}
	end

	--自己
	if pType == UserAIPlayerInfoVO.me then
		if self.playerList_[1] then
			self.playerList_[1].score_ = self.score_
			self.playerList_[1].isEnd_ = (self.over_ and 1) or 0
		else
			self.playerList_[1] = UserAIPlayerInfoVO.new({
					id = 1, --唯一标识
					pType = UserAIPlayerInfoVO.me,
					name = GameManager:getUserCompitionData():getProperty("username"),
					avatarName = GameManager:getUserCompitionData():getProperty("headImage"), --头像名字
					score = self.score_, --分
					cardList = {}, --收牌的状态
					isEnd = (self.over_ and 1) or 0
				})
		end
	elseif pType == UserAIPlayerInfoVO.opponent then --ai
		if not self.aiList_ then
			return
		end
		for i=1,#self.aiList_ do
			if self.playerList_[i+1] then
				self.playerList_[i+1].score_ = self.aiList_[i]:getScore()
				self.playerList_[i+1].cardList_ = self:getAICollectStatus_(i)
				self.playerList_[i+1].isEnd_ = (self.aiList_[i]:getAIStatus() == BattleAI.AI_STATUS_END and 1) or 0
			else
				local name_ = ""
				local avatarName_ = ""
				local level_ = ""
				if self.players_[i] then
					name_ = self.players_[i].playername_
					avatarName_ = self.players_[i].avatarname_
					level_ = self.players_[i].level_
				end
				
				self.playerList_[i+1] = UserAIPlayerInfoVO.new({
					id = i+1, --唯一标识
					pType = UserAIPlayerInfoVO.opponent,
					name = name_,
					avatarName = avatarName_, --头像名字
					level = level_,
					score = self.aiList_[i]:getScore(), --分
					cardList = self:getAICollectStatus_(i), --收牌的状态
					isEnd = (self.aiList_[i]:getAIStatus() == BattleAI.AI_STATUS_END and 1) or 0
				})
			end
		end
	end
end

function BattleManagerAI:sortList_(list)
	local sortList_ = {}
	for i=1,#list do
		local isInsert_ = false
		for j=1,#sortList_ do
			if list[i].score_ > sortList_[j].score_ then
				table.insert(sortList_,j,list[i])
				isInsert_ = true
				break
			end
		end
		if not isInsert_ then
			sortList_[#sortList_ + 1] = list[i]
		end
	end
	return sortList_
end

function BattleManagerAI:createSortPlayerList_()
	if not self.sortPlayerList_ or #self.sortPlayerList_ < 1 then
		self.sortPlayerList_ = {}
		for i=1,#self.playerList_ do
			self.sortPlayerList_[i] = self.playerList_[i]
		end
	end

	--如果长度超过2则进行排序
	local len_ = #self.sortPlayerList_
	if len_ <= 2 then
		return
	end
	self.sortPlayerList_ = self:sortList_(self.sortPlayerList_)
	-- table.sort(self.sortPlayerList_, function ( obja, objb )
	-- 	if tonumber(obja.score_) > tonumber(objb.score_) then
	-- 		return true
	-- 	else
	-- 		return false
	-- 	end
	-- end)
end

function BattleManagerAI:initAI_(num)
	self.aiList_ = {}
	if not num or num < 1 then
		return
	end

	for i=1,num do
		self.aiList_[i] = BattleAI.new(self)
		if self.players_[i] then
			local level_ = BattleAI.AI_NORMAL
			if self.players_[i].level_ == "easy" then
				level_ = BattleAI.AI_EASY
			elseif self.players_[i].level_ == "normal" then
				level_ = BattleAI.AI_NORMAL
			elseif self.players_[i].level_ == "hard" then
				level_ = BattleAI.AI_HARD
			end
			self.aiList_[i]:setLevel(level_)
		end
		self.aiList_[i]:setIs3Draw(self.isDraw3_)
		self.aiList_[i]:setDelegate(self)
	end


	self.playerList_ = {}
	self.sortPlayerList_ = {}
	self:updataPlayerList_(UserAIPlayerInfoVO.me)
	self:updataPlayerList_(UserAIPlayerInfoVO.opponent)
	self:createSortPlayerList_()
	self:initTopInfoView_(self.topNode)
end

function BattleManagerAI:initAICardsBySeed_(seed)
	if not self.aiList_ then
		return
	end
	for i=1,#self.aiList_ do
		self.aiList_[i]:initCardBySeed(seed)
	end
end

function BattleManagerAI:initAICardsByList_(list)
	if not self.aiList_ then
		return
	end
	for i=1,#self.aiList_ do
		self.aiList_[i]:initCardByList(list)
	end
end

function BattleManagerAI:beginAI_()
	if not self.aiList_ then
		return
	end
	for i=1,#self.aiList_ do
		self.aiList_[i]:begin()
	end
end

function BattleManagerAI:judgeAnyOneOver_()
	local playerType_ = self:isAnyOneOver_()
	if not playerType_ then
		return
	end
	if not self.delayTime_ then
		self.delayTime_ = BattleManagerAI.delayEndCd
		GameManager:getAudioData():playAudio(common.effectSoundList.endgame)
	end

	--静态提示
	if self.delegate_ and self.delegate_.setNotice then
		self.delegate_:setNotice(self.delayTime_,playerType_)
	end
	--

	--滚动提示
	if self.delegate_ and self.delegate_.playTimeNotice then
		self.delegate_:playTimeNotice(self.delayTime_)
	end
end

function BattleManagerAI:isAnyOneOver_()
	if self.over_ then
		return UserAIPlayerInfoVO.me
	end

	if self.aiList_ then
		for i=1,#self.aiList_ do
			if self.aiList_[i]:getAIStatus() == BattleAI.AI_STATUS_END then
				return UserAIPlayerInfoVO.opponent
			end
		end
	end
end

function BattleManagerAI:timeUpdata_()
	if self.ending_ then
		return
	end
	self:judgeAnyOneOver_()
	if self.delayTime_ then
		self.delayTime_ = self.delayTime_ - 1 
		if self.delayTime_ <= 0 then
			self:hideNotice_()
			self:endLogic_()
			return
		end
	end
end

function BattleManagerAI:updateAI_(t)
	if not self.aiList_ then
		return
	end
	for i=1,#self.aiList_ do
		self.aiList_[i]:update(t)
	end
end

function BattleManagerAI:tapAIPrint()
	if not self.aiList_ then
		return
	end
	for i=1,#self.aiList_ do
		self.aiList_[i]:printCol()
	end
end

function BattleManagerAI:tapAILogic()
	if not self.aiList_ then
		return
	end
	for i=1,#self.aiList_ do
		self.aiList_[i]:doAiLogic()
	end
end

function BattleManagerAI:magicLinkTwoCard_(card_before, card_next, headIndex)
	local userCacheStepVO = UserCacheStepVO.new({
			isMagic = 1
		})
	if not card_next then
		return
	end
	local score = self:calculateScore_(card_before, card_next, headIndex)
	userCacheStepVO:setProperty("score", score)
	userCacheStepVO:setProperty("stepStart", card_next.headIndex_)

	if card_before then
		headIndex = card_before:getProperty("headIndex")
		-- GameManager:getUserGameCacheData():changeCacheStatusByCardVO(card_before)
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
		-- GameManager:getUserGameCacheData():changeCacheStatusByCardVO(card_next_next)
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
	-- GameManager:getUserGameCacheData():changeCacheStatusByCardVO(card_next)
	--保存步骤信息
	userCacheStepVO:setProperty("stepEnd", card_next.headIndex_)
	userCacheStepVO:setProperty("count", 1)
	--此步移动的轮数
	userCacheStepVO:setProperty("flipCardRound", self.flipCardRound)

	GameManager:getUserGameCacheData():saveCacheStep(userCacheStepVO)
	self:addScore_(userCacheStepVO:getProperty("score"))
	-- GameManager:getUserGameCacheData():carryOnScore(userCacheStepVO:getProperty("score"))

	self:updateBtnStatus_()
end

function BattleManagerAI:magic()
	local maxNum_ = GameManager:getUserCache():getProperty("battleMagicNum")
	if maxNum_ >= 0 and self.magicNum_ >= maxNum_ then
		DisplayManager.showAlertBox(Localization.string("本局魔法棒使用已达次数上限"))
		return
	end
	if self.magic_ then
		return
	end
	self.magic_ = true

	local magic_ = GameManager:getUserData():getMagic()
	if magic_ < 1 then
		self.magic_ = false

		-- local magicShopViewCtrl_ = MagicShopViewCtrl.new()
		-- if magicShopViewCtrl_ then
		-- 	display.getRunningScene():addChild(magicShopViewCtrl_:getView())
		-- end
		local shopViewCtrl = ShopViewCtrl.new()
		if shopViewCtrl then
			display.getRunningScene():addChild(shopViewCtrl:getView())
		end
		return
	end

	local card_,toCard_ = self:findMagicTargetCard_()
	if not card_ then
		DisplayManager.showAlertBox(Localization.string("未找到合适的牌"))
		self.magic_ = false
		return
	end
	-- printf("---magic--- %s ----> %d", card_:getCardName(),toCard_.headIndex_-7)
	Analytice.onEvent("使用魔法棒(比赛)", {})
	GameManager:getUserData():addMagic(-1,true)

	self.magicNum_ = self.magicNum_ + 1

	self:magicAnimation_(card_,toCard_)

	if self.delegate_ and self.delegate_.setCanMagic and maxNum_ >= 0 then
		-- printf("magicNum == %s // maxNum_ == %s",tostring(self.magicNum_),tostring(maxNum_))
		self.delegate_:setCanMagic(self.magicNum_ < maxNum_)
	end
	
end

function BattleManagerAI:magicAnimation_(card,toCard)

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

function BattleManagerAI:moveMagicCards_(card,fromIndex)
	if not card then
		return
	end
	local headIndex = card.headIndex_
	local pos = self:getPosByColumnIndex_(headIndex)
	-- pos.x, pos.y = self["column"..headIndex]:getPosition()
	local startHeadIndex = fromIndex
	local moveTo = CCEaseSineInOut:create(CCMoveTo:create(0.15, pos))

	local call = CCCallFunc:create(function ( )
		self.magic_ = false
		self:reloadCardsPos()
		self:endMoving(startHeadIndex, headIndex)
		self:playPartical_(headIndex, startHeadIndex)
		self:reOrderZOrder_(self.headsList_[startHeadIndex])
		self:reOrderZOrder_(self.headsList_[headIndex])
		if startHeadIndex == BattleManagerAI.HEAD_CHANGE_1 then
			self:rePosChange1_()
		end
	end)
	card:getView():stopAllActions()
	self:playAddScoreAnimation1_(headIndex, startHeadIndex, card)
	self:startMoving()
	card:getView():runAction(transition.sequence({moveTo,call}))
	
end

function BattleManagerAI:findMagicTargetCard_()
	--所要收的目标牌
	local tList_ = {}
	local nillIndex_ = nil
	for i=BattleManagerAI.HEAD_COLLECT_1,BattleManagerAI.HEAD_COLLECT_MAX do
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
	for i=BattleManagerAI.HEAD_COLUMN_1,BattleManagerAI.HEAD_COLUMN_MAX do
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
	for i=BattleManagerAI.HEAD_CHANGE_MAX,BattleManagerAI.HEAD_CHANGE_1,-1 do
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

function BattleManagerAI:initCard_( _seed )
	local list, seed_ = DealerController.shuffleCards(DealerController.initCards(), _seed)

	self.seed_ = seed_
	function linkCard_( before, cardVO, headIndex )
		cardVO:setBeforeCard(before)
		cardVO:setProperty("headIndex", headIndex)
		if before == nil then
			self.headsList_[headIndex] = cardVO
		else
			before:setNextCard(cardVO)
		end
	end

	for column=1,7 do
		local before = nil
		for num=1,column do
			local cardVO = list[1]
			table.remove(list, 1)
			linkCard_(before, cardVO, column)
			--发牌结束之后会有翻牌动画，这里就不做处理了
			-- if num >= column then
			-- 	cardVO:setProperty("board", CardVO.BOARD_FACE)
			-- else
			-- 	cardVO:setProperty("board", CardVO.BOARD_BACK)
			-- end
			before = cardVO
		end
	end
	--剩余的牌在换牌区
	local before = nil
	for i=1,#list do
		local cardVO = list[i]
		linkCard_(before, cardVO, BattleManagerAI.HEAD_CHANGE_MAX)
		cardVO:setProperty("board", CardVO.BOARD_BACK)
		before = cardVO
	end
	-- 种子打点
	self:enteBattleDot()
	--初始化AI的牌局
	self:initAICardsBySeed_(seed_)
end

function BattleManagerAI:isPortrait_()
	return CONFIG_SCREEN_ORIENTATION == "portrait"
end

function BattleManagerAI:getCardOffsetY_( face )
	local isPortrait = self:isPortrait_()
	if face == CardVO.BOARD_BACK then
		return 10*CardDefine.scaleRate
	end
	if isPortrait then
		return 40*CardDefine.scaleRate
	else
		return 40*CardDefine.scaleRate
	end
end

function BattleManagerAI:getCardOffsetX_( )
	return 30*CardDefine.scaleRate
end

--左手模式变更了
function BattleManagerAI:leftModeChanged( )
	local left_mode = GameManager:getUserData():getIsLeft()
	local width = self.card_table:getContentSize().width
	local maxCount = BattleManagerAI.HEAD_COLUMN_MAX


	if left_mode > 0 then
		if self.isLeft_ then
			return
		end
		self.isLeft_ = true
		--启用左手模式
		-- for i=BattleManagerAI.HEAD_COLUMN_1,BattleManagerAI.HEAD_COLUMN_MAX do
		-- 	self["column"..i]:setPositionX(width-width/maxCount/2*(2*i-1))
		-- end
		local off_x = width - self["column"..BattleManagerAI.HEAD_COLLECT_1]:getPositionX() - self["column"..BattleManagerAI.HEAD_COLLECT_MAX]:getPositionX()
		for i=BattleManagerAI.HEAD_COLLECT_1,BattleManagerAI.HEAD_COLLECT_MAX do
			self["column"..i]:setPositionX(self["column"..i]:getPositionX()+off_x)
		end
		self["column"..BattleManagerAI.HEAD_CHANGE_MAX]:setPositionX(width/maxCount/2)
		if self:isPortrait_() then
			self["column"..BattleManagerAI.HEAD_CHANGE_1]:setPositionX(width/maxCount/2*3+self:getCardOffsetX_()*2)
		else
			self["column"..BattleManagerAI.HEAD_CHANGE_1]:setPositionX(width/maxCount/2+self:getCardOffsetX_()*2)
		end
		
		local hOff_x = width - self.headBeginX_
		self.headPos:setPositionX(hOff_x)

	else
		if not self.isLeft_ then
			return
		end
		self.isLeft_ = false
		--关闭左手模式
		-- for i=BattleManagerAI.HEAD_COLUMN_1,BattleManagerAI.HEAD_COLUMN_MAX do
		-- 	self["column"..i]:setPositionX(width/maxCount/2*(2*i-1))
		-- end
		local off_x = self.collectBeginX_ - self["column"..BattleManagerAI.HEAD_COLLECT_1]:getPositionX()
		for i=BattleManagerAI.HEAD_COLLECT_1,BattleManagerAI.HEAD_COLLECT_MAX do
			self["column"..i]:setPositionX(self["column"..i]:getPositionX()+off_x)
		end
		self["column"..BattleManagerAI.HEAD_CHANGE_MAX]:setPositionX(width-width/maxCount/2)
		self["column"..BattleManagerAI.HEAD_CHANGE_1]:setPositionX(width-width/maxCount/2*3)

		self.headPos:setPositionX(self.headBeginX_)
	end
	self:reloadCardsPos()
end

function BattleManagerAI:getNodeByColumn_(index)
	--如果是1v1切，是收牌列
	if self.playerNum_ == 1 and (index >= BattleManagerAI.HEAD_COLLECT_1 and index <= BattleManagerAI.HEAD_COLLECT_MAX) then
		if not self.battleTopInfoViewCtrl_ then
			return
		end
		local index_ = index - BattleManagerAI.HEAD_COLLECT_1 + 1
		return self.battleTopInfoViewCtrl_["rightColumn"..index_]
	end

	return self["column"..index]
end

function BattleManagerAI:getPosByColumnIndex_(index)
	--如果是1v1切，是收牌列
	if self.playerNum_ == 1 and (index >= BattleManagerAI.HEAD_COLLECT_1 and index <= BattleManagerAI.HEAD_COLLECT_MAX) then
		local node_ = self:getNodeByColumn_(index)
		if not node_ then
			return ccp(0, 0)
		end
		local wPos = node_:convertToWorldSpaceAR(node_:getAnchorPoint())
		local nPos = self.card_table:convertToNodeSpace(wPos)
		
		return ccp(nPos.x, nPos.y - node_:getContentSize().height/2)
	end
	if not self["column"..index] then
		return ccp(0, 0)
	end

	return ccp(self["column"..index]:getPositionX(), self["column"..index]:getPositionY())
end

function BattleManagerAI:reloadCardsPos( )
	--牌桌上的卡牌
	for i=BattleManagerAI.HEAD_COLUMN_1,BattleManagerAI.HEAD_CHANGE_MAX do
		local card = self.headsList_[i]
		local offset_pos = ccp(0, 0)
		while card do
			local sprite = card:getView()
			if sprite then
				local pos_ = self:getPosByColumnIndex_(i)
				sprite:setPosition(ccp(pos_.x + offset_pos.x, pos_.y + offset_pos.y))
				if not sprite:getParent() then
					self.card_table:addChild(sprite)
				end
			else
				printf("no card sprite!")
			end
			if i >= BattleManagerAI.HEAD_COLUMN_1 and i <= BattleManagerAI.HEAD_COLUMN_MAX then
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

function BattleManagerAI:rePosChange1_()
	local card = self.headsList_[BattleManagerAI.HEAD_CHANGE_1]
	if card then
		card = DealerController.getQueueEndCardVO(card)
	end
	local offsetX = 0
	while card do
		local sprite = card:getView()
		if sprite then
			local pos_ = self:getPosByColumnIndex_(BattleManagerAI.HEAD_CHANGE_1)
			sprite:setPosition(ccp(pos_.x-offsetX, pos_.y))
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

function BattleManagerAI:startDealCard( animation )
	self:stopAllActions()
	self.playing = false
	self:leftModeChanged()
	--此时才开始创建卡牌的形象
	if animation then
		self:startMoving()
		for i=BattleManagerAI.HEAD_COLUMN_1,BattleManagerAI.HEAD_CHANGE_MAX do
			local card = self.headsList_[i]
			while card do
				local sprite = card:getView()
				if sprite then
					local pos_ = self:getPosByColumnIndex_(BattleManagerAI.HEAD_CHANGE_MAX)
					sprite:setPosition(ccp(pos_.x, pos_.y))
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
			if headIndex > BattleManagerAI.HEAD_COLUMN_MAX then
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
				local pos_ = self:getPosByColumnIndex_(headIndex)
				local move = CCMoveTo:create(0.25, ccp(pos_.x, pos_.y - offsetX))--count*self:getCardOffsetY_()))
				local call = CCCallFunc:create(function ()
					-- GameManager:getUserGameCacheData():changeCacheStatusByCardVO(card)
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
		showAni(BattleManagerAI.HEAD_COLUMN_1, self.headsList_[BattleManagerAI.HEAD_COLUMN_1], 0, 0)

	else
		self:reloadCardsPos()
	end

	for i=BattleManagerAI.HEAD_COLUMN_1,BattleManagerAI.HEAD_CHANGE_MAX do
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

function BattleManagerAI:cleanTouchData_( )
	self.pre_x = 0
	self.pre_y = 0
	self.card_pre_x = {}
	self.card_pre_y = {}
	self.click_ = true
end

function BattleManagerAI:cardTouchBegan( cardSp, x, y )
	self:resumeGame(true)
	-- if self.cardMoving_ then
	-- 	return false
	-- end
	if self.magic_ then
		return false
	end
	if DealerController.judgePickUp(cardSp.data_) ~= DealerController.PICK_ABLE then
		-- printf("Not PickUp ------ [%s]", cardSp.data_:getCardName())
		return false
	end
	if cardSp.data_.headIndex_ == BattleManagerAI.HEAD_CHANGE_1 and cardSp.data_.next_ then
		-- printf("Not Next ------ [%s]", cardSp.data_:getCardName())
		return false
	end
	if cardSp.data_.headIndex_ >= BattleManagerAI.HEAD_COLLECT_1 and cardSp.data_.headIndex_ <= BattleManagerAI.HEAD_COLLECT_MAX then
		-- printf("Not Collect ------ [%s]", cardSp.data_:getCardName())
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
		local cardSp_ = card:getView()
		self.card_pre_x[card] = cardSp_:getPositionX()
		self.card_pre_y[card] = cardSp_:getPositionY()
		-- self.card_pre_y[card] = cardSp:getPositionY() + count*5
		card = card:getNextCard()
		count = count + 1
	end
	cardSp.data_:changeBoardTo(CardVO.BOARD_FACE, nil, true)
	self:clearLight_()
	if cardSp.data_.headIndex_ ~= BattleManagerAI.HEAD_CHANGE_1 then
		self.light_ = self:addLight_(cardSp.data_)
	end
	
	return true
end

function BattleManagerAI:cardTouchMoving( cardSp, x, y )
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

function BattleManagerAI:cardTouchEnd( cardSp, x, y )
	local startHeadIndex = cardSp.data_.headIndex_
	if self.click_ then
		--点击结束，判断牌桌和集牌区
		local ok, selectCard, headIndex= self:findLink_(cardSp.data_,BattleManagerAI.ALL_CON)
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
		for i=BattleManagerAI.HEAD_COLUMN_1,BattleManagerAI.HEAD_COLLECT_MAX do
			if cardSp.data_.headIndex_ ~= i then
				local card = self.headsList_[i]
				if not card then
					--手指点与底座判断
					local node_ = self:getNodeByColumn_(i)
					if common.judgeTouchInNode(ccp(x, y),node_) then
						headIndex = i
						break
					end
					--手牌与底座的相交面积判断
					local area_ = common.judgeNodeInNode(cardSp:getAreaNode(),node_)
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
		if headIndex > 0 and headIndex <= BattleManagerAI.HEAD_COLUMN_MAX and DealerController.judgePutDown(selectCard,cardSp.data_) or
			(headIndex >= BattleManagerAI.HEAD_COLLECT_1 and headIndex <= BattleManagerAI.HEAD_COLLECT_MAX 
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

	self:moveCards(card, startHeadIndex)
	self:clearLight_(true)
	self:cleanTouchData_()
end

function BattleManagerAI:moveCards( card,startHeadIndex )
	if startHeadIndex == BattleManagerAI.HEAD_CHANGE_1 then
		self:didAddCardToOpen()
	end
	if not card then
		return
	end
	local headIndex = card.headIndex_
	if headIndex == BattleManagerAI.HEAD_CHANGE_1 then
		return
	end
	local pos = self:getPosByColumnIndex_(headIndex)
	if card:getBeforeCard() and headIndex <= BattleManagerAI.HEAD_COLUMN_MAX then
		pos.y = card:getBeforeCard():getView():getPositionY()
	end

	while card and not tolua.isnull(card:getView()) do
		if card:getBeforeCard() and headIndex <= BattleManagerAI.HEAD_COLUMN_MAX then
			pos.y = pos.y - self:getCardOffsetY_(card:getBeforeCard():getProperty("board"))
		end
		self:playAddScoreAnimation1_(headIndex, startHeadIndex, card)
		self:startMoving()
		local moveTo = CCEaseSineInOut:create(CCMoveTo:create(0.15, pos))
		local call = CCCallFunc:create(function ( )
			self:endMoving(startHeadIndex, headIndex)
			self:playPartical_(headIndex, startHeadIndex)
		end)
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

function BattleManagerAI:cardTouchCancel( cardSp, x, y )
	self:cardTouchEnd(cardSp, x, y)
end

local function judgeCollect_(curCard,list)
	if curCard.headIndex_ >= BattleManagerAI.HEAD_COLLECT_1 and curCard.headIndex_ <= BattleManagerAI.HEAD_COLLECT_MAX then
		--点击的是收集区的卡牌就不在判断是否可收集了
		return false, nil, 0
	end
	--优先判断是否可收集
	if not curCard:getNextCard() then
		--可收集时必定是最后一张牌
		for i=BattleManagerAI.HEAD_COLLECT_1,BattleManagerAI.HEAD_COLLECT_MAX do
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
	for i=BattleManagerAI.HEAD_COLUMN_1,BattleManagerAI.HEAD_COLUMN_MAX do
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

BattleManagerAI.ALL_CON = 0 --全都判断
BattleManagerAI.ONLY_COLLECT = 1 --只判断收牌
BattleManagerAI.ONLY_MOVE = 2 --只判断移牌

function BattleManagerAI:findLink_( curCard, condition )
	-- if curCard.headIndex_ >= BattleManagerAI.HEAD_COLLECT_1 and curCard.headIndex_ <= BattleManagerAI.HEAD_COLLECT_MAX then
	-- 	--点击的时候不允许集卡区的牌移动，但可以拖动移动，减少计算量
	-- 	return false, nil, 0
	-- end

	if condition == BattleManagerAI.ONLY_COLLECT then
		return judgeCollect_(curCard,self.headsList_)
	elseif condition == BattleManagerAI.ONLY_MOVE then
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

function BattleManagerAI:addLight_( card, node )
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

function BattleManagerAI:clearLight_(openTimeJudge)
	if self.light_ then
		self.light_:removeSelf()
		self.light_ = nil
	end
	-- if openTimeJudge then
	-- 	--15秒之后自动提示
	-- 	if self.schedulerHandle then
	-- 		self:stopAction(self.schedulerHandle)
	-- 		self.schedulerHandle = nil
	-- 	end
	-- 	local openHint = GameManager:getUserData():getOpenHint()
	-- 	if openHint > 0 then
	-- 		self.schedulerHandle = self:performWithDelay(function ()
	-- 			self:autoTips(true)
	-- 		end,15)
	-- 	end
	-- end
	if tolua.isnull(self.tipsNode_) then
		self.tipsNode_ = nil
	end
	if self.tipsNode_ then
		self.tipsNode_:stopAllActions()
		self.tipsNode_:removeSelf()
		self.tipsNode_ = nil
	end
end

function BattleManagerAI:calculateScore_(card_before, card_next, headIndex )
	local score = 0
	if headIndex >= BattleManagerAI.HEAD_COLLECT_1 and headIndex <= BattleManagerAI.HEAD_COLLECT_MAX then
		--收牌
		score = self:getAddScore(card_next)
		card_next.score = score
	end

	return score
end


--处理两张卡牌的链接以及头部索引的操作
function BattleManagerAI:linkTwoCard(card_before, card_next, headIndex, notRecordStep )
	local userCacheStepVO = UserCacheStepVO.new()
	if not card_next then
		return
	end
	local score = self:calculateScore_(card_before, card_next, headIndex)
	userCacheStepVO:setProperty("score", score)
	userCacheStepVO:setProperty("stepStart", card_next:getProperty("headIndex"))
	if not card_next:getBeforeCard() then
		--将原有的头置空
		self.headsList_[card_next:getProperty("headIndex")] = nil
	end
	if card_before then
		headIndex = card_before:getProperty("headIndex")
		-- GameManager:getUserGameCacheData():changeCacheStatusByCardVO(card_before)
	end
	local left_mode = GameManager:getUserData():getIsLeft()
	if headIndex then
		local card = card_next
		while card do
			card:setProperty("headIndex", headIndex)
			if headIndex == BattleManagerAI.HEAD_CHANGE_MAX then
				if left_mode > 0 then
					card:changeBoardTo(CardVO.BOARD_BACK, CardVO.FLIP_TYPE_LEFT, true)
				else
					card:changeBoardTo(CardVO.BOARD_BACK, CardVO.FLIP_TYPE_RIGHT, true)
				end
			elseif headIndex == BattleManagerAI.HEAD_CHANGE_1 then
				local isNoAni_ = true
				if self:isPortrait_() then
					isNoAni_ = false
				end
				if left_mode > 0 then
					card:changeBoardTo(CardVO.BOARD_FACE, CardVO.FLIP_TYPE_RIGHT, isNoAni_)
				else
					card:changeBoardTo(CardVO.BOARD_FACE, CardVO.FLIP_TYPE_LEFT, isNoAni_)
				end
			end
			card = card:getNextCard()
		end
		--判断是否翻牌
		if headIndex == BattleManagerAI.HEAD_CHANGE_MAX or headIndex == BattleManagerAI.HEAD_CHANGE_1 then
		else
			if card_next:getBeforeCard() and card_next:getBeforeCard():getProperty("board") == CardVO.BOARD_BACK then
				card_next:getBeforeCard():changeBoardTo(CardVO.BOARD_FACE)
				-- GameManager:getUserGameCacheData():changeCacheStatusByCardVO(card_next:getBeforeCard())
				userCacheStepVO:setProperty("beforeIsFlip", 1)
			end
		end
	end
	--音效
	if headIndex == BattleManagerAI.HEAD_CHANGE_1 then
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
	-- GameManager:getUserGameCacheData():changeCacheStatusByCardVO(card_next)
	--保存步骤信息
	userCacheStepVO:setProperty("stepEnd", card_next:getProperty("headIndex"))
	userCacheStepVO:setProperty("count", DealerController.getQueueLenByHead(card_next))
	--此步移动的轮数
	userCacheStepVO:setProperty("flipCardRound", self.flipCardRound)

	if not notRecordStep then
		GameManager:getUserGameCacheData():saveBattleStep(userCacheStepVO)
		self:addScore_(userCacheStepVO:getProperty("score"))
	end
	-- local sec = GameManager:getUserGameCacheData():getRunningTime()
	-- GameManager:getUserGameCacheData():changeCacheData({gameTime = sec})
	self:updateBtnStatus_()
end

function BattleManagerAI:didAddCardToOpen( notReOrder )
	if not notReOrder then
		self:reOrderZOrder_(self.headsList_[BattleManagerAI.HEAD_CHANGE_MAX])
		self:reOrderZOrder_(self.headsList_[BattleManagerAI.HEAD_CHANGE_1])
	end
	local card_last = self.headsList_[BattleManagerAI.HEAD_CHANGE_1]
	if card_last then
		card_last = DealerController.getQueueEndCardVO(card_last)
	end
	if not card_last then
		return
	end
	local offsetX = 0
	if self.showMoveAni_ then
		while card_last do
			local pos = self:getPosByColumnIndex_(BattleManagerAI.HEAD_CHANGE_1)
			local moveTo = CCMoveTo:create(0.1, ccp(pos.x-offsetX, pos.y))
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
			if offsetX > 2*self:getCardOffsetX_() then
				offsetX = 2*self:getCardOffsetX_()
			end
		end
	else
		while card_last do
			local pos = self:getPosByColumnIndex_(BattleManagerAI.HEAD_CHANGE_1)
			card_last:getView():setPositionX(pos.x-offsetX)
			local before = card_last:getBeforeCard()
			if before then
				card_last = before
			else
				break
			end
			offsetX = offsetX + self:getCardOffsetX_()
			if offsetX > 2*self:getCardOffsetX_() then
				offsetX = 2*self:getCardOffsetX_()
			end
		end
	end
end

--将开放区的牌回复到锁区
function BattleManagerAI:putCardToLock( count, notRecordStep )
	if count < 1 then
		return
	end
	--锁区的最后一张
	local card_before = self.headsList_[BattleManagerAI.HEAD_CHANGE_MAX]
	if card_before then
		card_before = DealerController.getQueueEndCardVO(card_before)
	end
	local card_next = self.headsList_[BattleManagerAI.HEAD_CHANGE_1]
	if card_next then
		card_next = DealerController.getQueueEndCardVO(card_next)
		card_next = DealerController.getCardByCountFromBottom(card_next,count)
		--开放区逆向之后的第一张
		card_next = DealerController.reverseQueueByCardVO(card_next)
	else
		return
	end
	self:linkTwoCard(card_before, card_next, BattleManagerAI.HEAD_CHANGE_MAX, notRecordStep)
	self:reOrderZOrder_(card_next)
	if self.showMoveAni_ then
		--TODO...需要添加动画
		while card_next do
			card_next:getView():stopAllActions()
			local pos = self:getPosByColumnIndex_(BattleManagerAI.HEAD_CHANGE_MAX)
			local move = CCMoveTo:create(0.1, ccp(pos.x,pos.y))
			card_next:getView():runAction(CCEaseSineInOut:create(move))

			card_next = card_next:getNextCard()
		end
	else
		while card_next do
			local pos = self:getPosByColumnIndex_(BattleManagerAI.HEAD_CHANGE_MAX)
			card_next:getView():setPosition(ccp(pos.x, pos.y))

			card_next = card_next:getNextCard()
		end
	end
	self:didAddCardToOpen(true)
end

--将锁区的牌撤销到开放区
function BattleManagerAI:putCardToOpen( count, notRecordStep )
	if count < 1 then
		return
	end
	--锁区的最后一张
	local card_before = self.headsList_[BattleManagerAI.HEAD_CHANGE_1]
	if card_before then
		card_before = DealerController.getQueueEndCardVO(card_before)
	end
	local card_next = self.headsList_[BattleManagerAI.HEAD_CHANGE_MAX]
	if card_next then
		card_next = DealerController.getQueueEndCardVO(card_next)
		card_next = DealerController.getCardByCountFromBottom(card_next,count)
		--开放区逆向之后的第一张
		card_next = DealerController.reverseQueueByCardVO(card_next)
	else
		return
	end
	self:linkTwoCard(card_before, card_next, BattleManagerAI.HEAD_CHANGE_1, notRecordStep)
	if self.showMoveAni_ then
		--TODO...需要添加动画
	end
	self:didAddCardToOpen()
end

function BattleManagerAI:setDelegate( delegate )
	self.delegate_ = delegate
end

function BattleManagerAI:hideNotice_()
	if not self.delegate_ then
		return
	end
	if not self.delegate_.hideNotice then
		return
	end
	self.delegate_:hideNotice()
end

function BattleManagerAI:reOrderZOrder_( cardVO, zOrder )
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

function BattleManagerAI:updateBtnStatus_( )
	if self.headsList_[BattleManagerAI.HEAD_CHANGE_1] or self.headsList_[BattleManagerAI.HEAD_CHANGE_MAX] then
		self.sp_go_on:setVisible(true)
		self.sp_no:setVisible(false)
	else
		self.sp_go_on:setVisible(false)
		self.sp_no:setVisible(true)
	end

	self.outOfFlips:setVisible(false)

	if self.delegate_ and self.delegate_.setBtn5Enabled then
		local stepData = GameManager:getUserGameCacheData():getBattleStepByLast()
		if stepData then --如果有上一步
			if stepData.isMagic_ > 0 
			or (stepData.stepEnd_ >= BattleManagerAI.HEAD_COLLECT_1 and stepData.stepEnd_ <= BattleManagerAI.HEAD_COLLECT_MAX) then --如果上一步是收牌
				self.delegate_:setBtn5Enabled(false)
			else --如果上一步不是收牌
				self.delegate_:setBtn5Enabled(true)
			end
		else --如果没有上一步
			self.delegate_:setBtn5Enabled(false)
		end
	end
end

function BattleManagerAI:tapChange( )
	-- if self.cardMoving_ then
	-- 	return
	-- end
	if self.magic_ then
		return
	end
	self:clearLight_(true)
	local operationCount = 1--操作卡牌的数量
	if self.isDraw3_ then
		operationCount = 3
	end
	if self.headsList_[BattleManagerAI.HEAD_CHANGE_MAX] then
		self.notNeedAnalysis = false
		--向开放区切牌
		self:putCardToOpen(operationCount)
		self:resumeGame(true)
	else
		--将开放区的牌回复
		if not self.headsList_[BattleManagerAI.HEAD_CHANGE_1] then
			--此时换牌区已经无牌
			return
		end
		self:resumeGame(true)
		self:putCardToLock(DealerController.getQueueLenByHead(self.headsList_[BattleManagerAI.HEAD_CHANGE_1]))
		--显示end按钮
		if self.delegate_ and self.delegate_.setEndBtnVisible and not self.over_ then
			self.delegate_:setEndBtnVisible(true)
		end
	end
end

function BattleManagerAI:startMoving( )
	self.cardMoving_ = true
end

function BattleManagerAI:dealOffsetY( headIndex_ )
	if headIndex_ and headIndex_ >= BattleManagerAI.HEAD_COLUMN_1 and headIndex_ <= BattleManagerAI.HEAD_COLUMN_MAX then
		local lenght = 0
		local height = 0
		local card = self.headsList_[headIndex_]
		while card do
			height = card:getView():getContentSize().height
			lenght = lenght + self:getCardOffsetY_(card.board_)
			card = card:getNextCard()
		end
		local pos_ = self:getPosByColumnIndex_(headIndex_)
		local posY = pos_.y
		local scal = 1

		local offHeight_ = 90
		if self:isPortrait_() then
			offHeight_ = 160
		end
		if posY - offHeight_ + self.tablePos_.y < lenght + height/2 then
			scal = (posY - offHeight_ + self.tablePos_.y)/(lenght + height/2)
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

function BattleManagerAI:endMoving(startHeadIndex, headIndex )
	-- printf("---------startHeadIndex[%s] ---- headIndex[%s]", tostring(startHeadIndex),tostring(headIndex))
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
function BattleManagerAI:pauseGame()
	self.pause_ = true
end

--继续游戏
function BattleManagerAI:resumeGame()
	self.pause_ = false
end

function BattleManagerAI:tapRevoke()
	if self.cardMoving_ then
		return
	end
	if self.magic_ then
		return
	end
	local stepData = GameManager:getUserGameCacheData():getBattleStepByLast()
	if not stepData then
		return
	end
	self:resumeGame(true)
	GameManager:getUserGameCacheData():removeBattleStepByLast()
	local data = GameManager:getUserGameCacheData():getBattleStepByLast()
	if data then
		self.flipCardRound = data:getProperty("flipCardRound")
	else
		self.flipCardRound = 0
	end
	--撤销操作有可能影响到自动收牌
	if self.btn_autoCollect:isVisible() == true then
		self.notNeedAnalysis = false
	end
	self.undo_ = self.undo_ + 1
	--将增加的分数返还
	self:addScore_(-stepData:getProperty("score"))
	if stepData:getProperty("stepStart") == BattleManagerAI.HEAD_CHANGE_1 and 
		stepData:getProperty("stepEnd") == BattleManagerAI.HEAD_CHANGE_MAX then
		--锁区向开放区回退
		self:putCardToOpen(stepData:getProperty("count"), true)
		self:clearLight_(true)
		return
	elseif stepData:getProperty("stepStart") == BattleManagerAI.HEAD_CHANGE_MAX and 
		stepData:getProperty("stepEnd") == BattleManagerAI.HEAD_CHANGE_1 then
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
	end
	self:linkTwoCard(card_before, card_next, stepData:getProperty("stepStart"), true)
	-- printf("----tapRevoke--[%s]---[%s]", tostring(stepData:getProperty("stepStart")),tostring(stepData:getProperty("stepEnd")))
	
	if stepData:getProperty("stepStart") == BattleManagerAI.HEAD_CHANGE_1 then
		self:moveCards(card_next, stepData:getProperty("stepStart"))
		self:dealOffsetY(stepData:getProperty("stepEnd"))
	else
		self:moveCards(card_next, stepData:getProperty("stepEnd"))
	end
	
	self:clearLight_(true)
end

function BattleManagerAI:findCardWitchCanCollectByHead_(before,head)
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

function BattleManagerAI:findCardWitchCanCollect_()
	local list_ = {}
	for i=BattleManagerAI.HEAD_COLLECT_1,BattleManagerAI.HEAD_COLLECT_MAX do
		local before = self.headsList_[i]
		if before then
			before = DealerController.getQueueEndCardVO(before)			
			for col=BattleManagerAI.HEAD_COLUMN_1,BattleManagerAI.HEAD_COLUMN_MAX do
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

function BattleManagerAI:openCompitionView_(compitionVO)
	--dot
	self:compitionWinOrLoseDot(compitionVO)
    local viewCtrl = CompitionViewCtrl.new()
    display.getRunningScene():addChild(viewCtrl:getView())
    if compitionVO then
    	viewCtrl:openEndsView(compitionVO,compitionVO.status)
    end
end

function BattleManagerAI:giveUp_()
	--统计 结果
	local analytice_ = string.format("%s张牌_%s人:输",((self.isDraw3_ and 3) or 1),tostring(self.totalNum_))
	-- printf("Analytice == %s",tostring(analytice_))
	Analytice.onEvent(analytice_, {})
	if self.compitionVO_ then
		self.compitionVO_.status = -1
	end
	GameManager:getInstance():changeBattleManagerBy(GameManager.BATTLE_SINGLE,self.compitionVO_,nil,handler(self, self.openCompitionView_))
end

function BattleManagerAI:compitionWinOrLoseDot( compitionVO_,_isRise )
	local eventInfo_ = self:getEventInfo_() or {}
	if _isRise then
		compitionVO_.status = 1
	end
	if compitionVO_.status == 0 then
		--平局
		eventInfo_.action = "draw"
	elseif compitionVO_.status == 1 then
		--赢了
		eventInfo_.action = "win"
	elseif compitionVO_.status == -1 then
		--输了
		eventInfo_.action = "lose"
	end
	
	Analytice.onEventThinkingData("tournament", eventInfo_)
end

function BattleManagerAI:tapHome()
	local btnParams = {
        {
            colorTemplate = AlertView.orangeButtonParams, --颜色模板
            title = Localization.string("是"), --按钮字
            callback = handler(self, self.giveUp_),--按钮响应
        },
        {
            colorTemplate = AlertView.green1ButtonParams, --颜色模板
            title = Localization.string("否"), --按钮字
            callback = function()end,--按钮响应
        },
    }
    DisplayManager.showAlertView(Localization.string("AI_点击Home标题"),Localization.string("AI_点击Home"),btnParams)
end

function BattleManagerAI:tapNew()
	if self.over_ then
		return
	end
	local btnParams = {
        {
            colorTemplate = AlertView.orangeButtonParams, --颜色模板
            title = Localization.string("是"), --按钮字
            callback = handler(self, self.setOver),--按钮响应
            -- callback = function()
            --     self:setOver()
            -- end,--按钮响应
        },
        {
            colorTemplate = AlertView.green1ButtonParams, --颜色模板
            title = Localization.string("否"), --按钮字
            callback = function()end,--按钮响应
        },
    }
    DisplayManager.showAlertView(Localization.string("AI_点击NewGame标题"),Localization.string("AI_点击NewGame{value}", {value=common.secConvertTimerWithMin(BattleManagerAI.delayEndCd)}),btnParams)
end

function BattleManagerAI:tapHint()
	-- self:clearLight_(true)
	self:autoTips(false)
end

function BattleManagerAI:autoTips( isRepeat )
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
	for i=BattleManagerAI.HEAD_COLUMN_1,BattleManagerAI.HEAD_COLUMN_MAX do
		local card = self.headsList_[i]
		--该队列第一张正面的牌
		card = DealerController.getFirstFaceCardFromHead( card )
		if card then
			--判断整个队列所有正面的牌能否移动
			ok, before_card, index = self:findLink_(card,BattleManagerAI.ALL_CON)
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
				ok, before_card, index = self:findLink_(card, BattleManagerAI.ONLY_COLLECT)
				next_card = card
				if ok then
					break
				end
			end
		end
	end
	--2换牌区的牌移到集卡区或者玩牌区
	local card = self.headsList_[BattleManagerAI.HEAD_CHANGE_1]
	if card then
		card = DealerController.getQueueEndCardVO(card)
	end
	if not ok and card then
		ok, before_card, index = self:findLink_(card,BattleManagerAI.ALL_CON)
		next_card = card
	end
	--5玩牌区移动后可收牌的情况
	if not ok then
		local judgeList_ = self:findCardWitchCanCollect_()
		for i=1,#judgeList_ do
			if judgeList_[i]:getNextCard() then
				ok, before_card, index = self:findLink_(judgeList_[i]:getNextCard(),BattleManagerAI.ONLY_MOVE)
				next_card = judgeList_[i]:getNextCard()
				if ok then
					break
				end
			end
		end
	end

	--3换牌区翻牌
	local card = self.headsList_[BattleManagerAI.HEAD_CHANGE_MAX]
	if not ok and card then
		ok, before_card, index = true, nil, BattleManagerAI.HEAD_CHANGE_1
		next_card = DealerController.getQueueEndCardVO(card)
	end
	--4换牌区回复
	local card = self.headsList_[BattleManagerAI.HEAD_CHANGE_1]
	if not ok and card then
		ok = true
		next_card = card
		local node = self:getNodeByColumn_(BattleManagerAI.HEAD_CHANGE_MAX)
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
	if not self["column"..index] then
		return
	end
	local pos = self:getPosByColumnIndex_(index)
	if before_card then
		pos.x, pos.y = before_card:getView():getPosition()
		if index <= BattleManagerAI.HEAD_COLUMN_MAX then
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

function BattleManagerAI:tapAutoCollect()
	self.btn_autoCollect:setVisible(false)
	self:autoCollectCard()
end

function BattleManagerAI:analysisCollectCard_( )
end

function BattleManagerAI:analysisWin_( )
	local win = true
	--牌桌和换牌区都没有卡牌的时候胜利
	for i=BattleManagerAI.HEAD_COLUMN_1,BattleManagerAI.HEAD_COLUMN_MAX do
		if self.headsList_[i] then
			win = false
			break
		end
	end
	if win then
		if self.headsList_[BattleManagerAI.HEAD_CHANGE_1] or self.headsList_[BattleManagerAI.HEAD_CHANGE_MAX] then
			win = false
		end
	end
	if not win then
		return
	end
	printf("恭喜，获得胜利")
	self.btn_autoCollect:setVisible(false)
	GameManager:getUserClassicData():addRandomWinCount("4",1)
	--通关奖励的分数
	self:addScore_(BattleManagerAI.PASS_COLLECT_SCORE)
	self:addTotalWinEvent_()
	self:endLogic_()

end

--添加获胜累计用户属性打点数据
function BattleManagerAI:addTotalWinEvent_( ... )
	local eventInfo_ = {}
	local m_winTournament = GameManager:getUserClassicData():getWinCountByType("winTournamentCount")
	eventInfo_.sum_win_tournament = tostring(m_winTournament)
	Analytice.onEventuserProperty("sum_win_tournament", tostring(m_winTournament))
end

function BattleManagerAI:endLogic_()
	if self.ending_ then
		return
	end
	self.ending_ = true
	self:pauseGame()
	for i=1,#self.aiList_ do
		self.aiList_[i]:ending()
	end
	self:correctionScoreLb_()

	self:performWithDelay(handler(self, self.showWinDialog), 1)
	
	-- self:showWinDialog()
end

-- status [-1:输、0:平、1:赢]
function BattleManagerAI:quit_(status)
	-- printf(" BattleManagerAI:quit ===== [%s]", tostring(self.compitionVO_))
	local status_ = nil
	if status == -1 then
		status_ = "输"
	elseif status == 0 then
		status_ = "平"
	elseif status == 1 then
		status_ = "赢"
	end
	--统计 结果
	local analytice_ = string.format("%s张牌_%s人:%s",((self.isDraw3_ and 3) or 1),tostring(self.totalNum_),tostring(status_))
	Analytice.onEvent(analytice_, {})
	self.compitionVO_.status = status

	self.isEndRequest_ = true
	if status == 1 then
		local pType_ = self.compitionVO_.pType_
		if pType_ == "type_1" then
			pType_ = "type1"
		elseif pType_ == "type_2" then
			pType_ = "type2"
		elseif pType_ == "type_3" then
			pType_ = "type3"
		elseif pType_ == "type_4" then
			pType_ = "type4"
		end
		GameManager:getNetWork():endBattle({battleType = pType_})
	else
		self:successEndBattle_()
	end
end

function BattleManagerAI:successEndBattle_()
	if not self.isEndRequest_ then
		return
	end
	GameManager:getInstance():changeBattleManagerBy(GameManager.BATTLE_SINGLE,self.compitionVO_,nil,handler(self, self.openCompitionView_))
end

function BattleManagerAI:failEndBattle_()
	if not self.isEndRequest_ then
		return
	end
	print("====>>>失败")
	GameManager:getInstance():changeBattleManagerBy(GameManager.BATTLE_SINGLE,self.compitionVO_,nil,function()
			local viewCtrl = CompitionViewCtrl.new()
	    	display.getRunningScene():addChild(viewCtrl:getView())
		end)
end

function BattleManagerAI:eliminateLogic_(userAIPlayerInfoVO)
	if userAIPlayerInfoVO then
		if userAIPlayerInfoVO.pType_ == UserAIPlayerInfoVO.me then
			self:quit_(-1)
			return
		end
		--去掉最后一名的数据
		for i=1,#self.players_ do
			local player_ = self.players_[i]
			if self.players_[i].playername_ == userAIPlayerInfoVO.name_
				and self.players_[i].avatarname_ == userAIPlayerInfoVO.avatarName_
				and self.players_[i].level_ == userAIPlayerInfoVO.level_ then
					table.remove(self.players_,i)
				break
			end
		end
	end
	
	--重新开始
	self:reset()
end

function BattleManagerAI:showWinDialog( )
	if #self.playerList_ < 3 then
		local me_ = self.sortPlayerList_[1]
		local opponent_ = self.sortPlayerList_[2]
		if me_.score_ == opponent_.score_ then
			self:quit_(0)
		elseif me_.score_ > opponent_.score_ then
			self:quit_(1)
		elseif me_.score_ < opponent_.score_ then
			self:quit_(-1)
		end
		return
	end
	--晋级赛胜利打点数据 
	self:compitionWinOrLoseDot(self.compitionVO_, true)

	CompitionViewCtrl.openEliminatedView( self.sortPlayerList_,self.isPortrait_(),handler(self, self.eliminateLogic_))
end

function BattleManagerAI:showStuffAnimation( )
end

function BattleManagerAI:saveRecord()
end
 
--保存活局种子
-- function BattleManagerAI:uploadSeed()
-- 	local userDealSeedVO = UserDealSeedVO.new()
-- 	local seed = GameManager:getUserGameCacheData():getCacheData():getProperty("seed") or ""
-- 	local mode = GameManager:getUserGameCacheData():getCacheData():getProperty("mode")
-- 	local threeMode = GameManager:getUserGameCacheData():getCacheData():getProperty("isDraw3Mode")
-- 	userDealSeedVO:setProperty("mode", mode)
-- 	userDealSeedVO:setProperty("seed", seed)
-- 	userDealSeedVO:setProperty("isDraw3Mode", threeMode)
-- 	local needUpload_ = GameManager:getUserSeedData():saveDealSeedByList({userDealSeedVO})
-- 	if not needUpload_ then
-- 		return
-- 	end
-- 	printf("种子上传")
-- 	local list1mode = {}
-- 	local list3mode = {}
-- 	local seedList = GameManager:getUserSeedData():getProperty("dealSeedList") or {}
-- 	for i=1,#seedList do
-- 		if seedList[i]:getProperty("isDraw3Mode") > 0 then
-- 			--每次翻三张模式
-- 			list3mode[#list3mode+1] = seedList[i]:getProperty("seed")
-- 		else
-- 			--每次翻一张
-- 			list1mode[#list1mode+1] = seedList[i]:getProperty("seed")
-- 		end
-- 	end
-- 	local param = {}
-- 	if #list1mode > 0 then
-- 		param.draw1 = list1mode
-- 	end
-- 	if #list3mode > 0 then
-- 		param.draw3 = list3mode
-- 	end
-- 	GameManager:getNetWork():saveSeed(param)
-- end

function BattleManagerAI:addTouchLayer_( parent, corlor )
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

function BattleManagerAI:autoCollectCard( )
	self:startMoving()
	-- GameManager:getUserGameCacheData():setEndAniStatus(BattleManagerAI.END_ANI_COLLECTING)
    local touchNode = self:addTouchLayer_(display.getRunningScene(), ccc4(0, 0, 0, 0))

	function linkCard_( card_before, card_next, headIndex )
		--分数统计
		local score = self:calculateScore_(card_before, card_next, headIndex)
		self:addScore_(score)
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
		-- GameManager:getUserGameCacheData():changeCacheStatusByCardVO(card_next)
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
		if headIndex < BattleManagerAI.HEAD_COLLECT_1 or headIndex > BattleManagerAI.HEAD_COLLECT_MAX then
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
		for i=BattleManagerAI.HEAD_COLUMN_1,BattleManagerAI.HEAD_COLUMN_MAX do
			local last_card = self.headsList_[i]
			if last_card then
				last_card = DealerController.getQueueEndCardVO(last_card)
				if canCollect_(end_card, last_card, rank, suit, headIndex) then
					return true, last_card, headIndex
				end
			end
		end
		--判断集牌区
		for i=BattleManagerAI.HEAD_CHANGE_1,BattleManagerAI.HEAD_CHANGE_MAX do
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
		for i=BattleManagerAI.HEAD_COLLECT_1,BattleManagerAI.HEAD_COLLECT_MAX do
			local ok, card, headIndex = collect(i)
			if ok then
				-- printf("开始自动收牌:%s", card:getCardName())
				local pos = self:getPosByColumnIndex_(i)
				local move = CCMoveTo:create(0.1, pos)
				card:getView():stopAllActions()
				card:getView():runAction(transition.sequence({CCEaseSineInOut:create(move), CCCallFunc:create(function ()
					self:playPartical_(headIndex, 0)
				end)}))
				self:reOrderZOrder_(card)
				self:palyCollectAudio(i, true)
				break
			end
			if i == BattleManagerAI.HEAD_COLLECT_MAX and ok ~= true then
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
				-- GameManager:getUserGameCacheData():setEndAniStatus(BattleManagerAI.END_ANI_STUFF)
				return
			end
		end
		self:performWithDelay(function ()
			collectCard( )
		end,0.13)
	end

	collectCard()
end

function BattleManagerAI:getFlyToLabel_()
	if self.playerNum_ == 1 then
		if self.battleTopInfoViewCtrl_ and self.battleTopInfoViewCtrl_.rightScoreLb then
			return self.battleTopInfoViewCtrl_.rightScoreLb
		end
	end

	return self.scoreLb
end

function BattleManagerAI:playAddScoreAnimation1_( headIndex, startIndex ,card)
	if not card then
		return
	end
	local score = card.score
	if not score then
		return
	end

	if headIndex < BattleManagerAI.HEAD_COLLECT_1 or headIndex > BattleManagerAI.HEAD_COLLECT_MAX 
		or headIndex == startIndex then
		return
	end
	-- if not self["column"..headIndex] then
	-- 	return
	-- end
	local wPos = card:getView():convertToWorldSpaceAR(card:getView():getAnchorPoint())
	local pos = self.card_table:convertToNodeSpace(wPos)

	-- local params = {
	-- 	text = "+"..tostring(score),
	-- 	color = ccc3(255, 210, 0),
	-- 	font = common.NumberFont,
	-- 	size = 33,
	-- }
	-- local scoreLb = ui.newTTFLabel(params)
	-- self.card_table:addChild(scoreLb,2)


	-- scoreLb:setPosition(ccp(pos.x, pos.y))
	-- scoreLb:setScale(0.5)

	local partical = CCParticleSystemQuad:create("particle/particle_tail.plist")
	partical:setPosition(ccp(pos.x, pos.y))
	partical:setAutoRemoveOnFinish(true)
	self.card_table:addChild(partical,2)
    -- scoreLb:addChild(partical)


	local toLb_ = self:getFlyToLabel_()
	local toNode_ = toLb_ or self.headPos
	local wPos_ = toNode_:convertToWorldSpaceAR(toNode_:getAnchorPoint())
	local toPos_ = self.card_table:convertToNodeSpace(wPos_)

	local distanceX_ = math.abs(toPos_.x-pos.x)
	local distanceY_ = math.abs(toPos_.y-pos.y)
	-- local distance_ = math.sqrt(distanceX_*distanceX_ + distanceY_*distanceY_)
	-- local speed_ = 1000
	local duration_ = 0.5--distance_/speed_

	local bezier = ccBezierConfig()
	bezier.controlPoint_1 = ccp(pos.x,pos.y)
	local rX_ = distanceY_*0.7
	local rY_ = distanceX_*0.7
	local x_off = math.random(-rX_,rX_)
	local y_off = math.random(-rY_,rY_)



	printf("x_off [%s] // y_off [%s] ",tostring(x_off),tostring(y_off))
	bezier.controlPoint_2 = ccp(pos.x+x_off,pos.y+y_off)
	bezier.endPosition = ccp(toPos_.x,toPos_.y)

	local seq = transition.sequence({
			CCBezierTo:create(duration_, bezier),
			-- CCEaseSineInOut:create(CCBezierTo:create(duration_, bezier)),
			-- CCScaleTo:create(0.1, 1),
			CCCallFunc:create(function()
					-- scoreLb:removeSelf(true)
					self:playAddScoreAnimation2_(score)
				end)
		})
	partical:runAction(seq)
end

function BattleManagerAI:playAddScoreAnimation2_(score)
	local toLb_ = self:getFlyToLabel_()
	if not toLb_ then
		return
	end
	if self.scoreNum_ >= self.score_ then
		return
	end
	self.scoreNum_ = self.scoreNum_ + score
	toLb_:setScale(1.2)
	toLb_:setString(tostring(self.scoreNum_))
	local seq = transition.sequence({
			CCScaleTo:create(0.05, 1)
		})
	toLb_:runAction(seq)

	local partical_ = CCParticleSystemQuad:create("particle/particle_score.plist")
	partical_:setPosition(ccp(toLb_:getContentSize().width/2, toLb_:getContentSize().height/2))
	partical_:setAutoRemoveOnFinish(true)
	toLb_:addChild(partical_)
end

function BattleManagerAI:correctionScoreLb_()
	local toLb_ = self:getFlyToLabel_()
	if not toLb_ then
		return
	end
	self.scoreNum_ = self.score_
	toLb_:setString(tostring(self.scoreNum_))
end

function BattleManagerAI:playPartical_( headIndex, startIndex )
	if headIndex < BattleManagerAI.HEAD_COLLECT_1 or headIndex > BattleManagerAI.HEAD_COLLECT_MAX 
		or headIndex == startIndex then
		return
	end
	if not self["column"..headIndex] then
		return
	end
	local pos = self:getPosByColumnIndex_(headIndex)
    local partical = CCParticleSystemQuad:create("animation/particle_shoupai.plist")
    self.card_table:addChild(partical, -1)
    partical:setPosition(pos)
    partical:runAction(transition.sequence({CCDelayTime:create(1.2),
    	CCCallFunc:create(function ( )
    		partical:removeSelf()
    	end)}))
end

function BattleManagerAI:palyCollectAudio( headIndex, collecting )
	if headIndex < BattleManagerAI.HEAD_COLLECT_1 or headIndex > BattleManagerAI.HEAD_COLLECT_MAX then
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

return BattleManagerAI