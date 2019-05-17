--
-- Author: yang fuchao
-- Date: 2016-06-20 16:37:58
--

local RedNoticeManager = class("RedNoticeManager",BasicVO)

RedNoticeManager.schema = {
	[Notice.USER_NOTICE_NEW_DAILYCHALLENGE] = {"number",0}, --日常任务
	[Notice.USER_NOTICE_NEW_DAILYCHALLENGE1] = {"number",0}, --日常任务
	[Notice.USER_NOTICE_NEW_THEMEVER] = {"number",0}, --主题库
	[Notice.USER_NOTICE_NEW_CPREDPOINT] = {"number",0}, --交叉推广
	[Notice.USER_NOTICE_NEW_REDPOINT_COMPITION] = {"number",0}, --挑战
	[Notice.USER_NOTICE_NEW_REDPOINT_ENTER_COMPITION] = {"number",0}, --进入过挑战
}

function RedNoticeManager:ctor()
	RedNoticeManager.super.ctor(self)
end

function RedNoticeManager:parseData( data )
	if not data then
		return
	end
	self:judgeCompitionNotice_(data)
end

function RedNoticeManager:onUpdateTimer( )
	if self.canJudgeCompition_ then
		self:postCompitionNotice()
	end
end

function RedNoticeManager:judgeCompitionNotice_( data )
	if data.userInfo then
		if data.userInfo.playername and data.userInfo.avatarname then
			self.canJudgeCompition_ = true
		end
	end
end

function RedNoticeManager:postCompitionNotice( )
	local count = 0
	local typeList = CompitionDefine.getCompitionTypeTable()
	local battleCD_ = GameManager:getUserCache():getProperty("battleCD") or 300
	local curTime = os.time()
	for i=1,#typeList do
		local type_ = typeList[i]
		local key = CompitionDefine.getCDtimeTempKey(type_)
		local temp = GameManager:getUserCache():getProperty(key) or 0
		if curTime - temp >= battleCD_ then
			count = count + 1
		end
	end
	self:setProperty(Notice.USER_NOTICE_NEW_REDPOINT_COMPITION, count)
	self:postRedNotice(Notice.USER_NOTICE_NEW_REDPOINT_COMPITION, true)
end

function RedNoticeManager:postEnterCompitionNotice( )
	local count = 0
	local isEnterNetBattle = GameManager:getUserData():getProperty("isEnterNetBattle")
	if isEnterNetBattle == 0 then
		count = 1
	end
	self:setProperty(Notice.USER_NOTICE_NEW_REDPOINT_ENTER_COMPITION, count)
	self:postRedNotice(Notice.USER_NOTICE_NEW_REDPOINT_ENTER_COMPITION)
end

function RedNoticeManager:postCPRedPointVerNotice()
	local isNewVer_ = GameManager:getInstance():isNewCrossPromotion()
	if isNewVer_ then
		self:setProperty(Notice.USER_NOTICE_NEW_CPREDPOINT, 1)
	else
		self:setProperty(Notice.USER_NOTICE_NEW_CPREDPOINT, 0)
	end
	self:postRedNotice(Notice.USER_NOTICE_NEW_CPREDPOINT)
end

function RedNoticeManager:postThemeVerNotice()
	if GAME_MODE ~= GAME_MODE_SOLITAIRE and GAME_MODE ~= GAME_MODE_COLLECTION then
		return
	end
	local isNewVer_ = GameManager:getUserData():isNewThemeVer()
	if isNewVer_ then
		self:setProperty(Notice.USER_NOTICE_NEW_THEMEVER, 1)
	else
		self:setProperty(Notice.USER_NOTICE_NEW_THEMEVER, 0)
	end
	self:postRedNotice(Notice.USER_NOTICE_NEW_THEMEVER)
end

function RedNoticeManager:postDailyChallengeNotice( )
	if GAME_MODE == GAME_MODE_COLLECTION then
		return
	end
	local passNum, totalNum = 0, 0
	local year = GameManager:getUserChallengeData():getProperty("curYear")
	local month = GameManager:getUserChallengeData():getProperty("curMonth")
	local day = GameManager:getUserChallengeData():getProperty("curDay")
	if year == 0 then
		--用户没有联网,取手机当前的日期
		local temp = os.date("*t", os.time())
		year = temp.year
		month = temp.month
		day = temp.day
	end
	local monthVO = GameManager:getUserChallengeData():getMonthData(year, month)
	if monthVO then
		local dayVO = monthVO.dayDataList_[day]
		if dayVO then
			passNum, totalNum = dayVO:passNums()
		end
	end
	--解析本地缓存数据
	local list = GameManager:getUserChallengeData():getProperty("dayTaskDataCacheList") or {}
	for i=1,#list do
		if list[i].year_ == year and list[i].month_ == month and list[i].day_ == day and list[i]:isPassed() then
			passNum = passNum + 1
		end
	end

	if totalNum > 0 then
		self:setProperty(Notice.USER_NOTICE_NEW_DAILYCHALLENGE1, 1)
		if passNum == 0 then
			self:postRedNotice(Notice.USER_NOTICE_NEW_DAILYCHALLENGE1)
		elseif passNum < totalNum then
			self:postRedNotice(Notice.USER_NOTICE_NEW_DAILYCHALLENGE1, true)
		else
			self:setProperty(Notice.USER_NOTICE_NEW_DAILYCHALLENGE1, 0)
			self:postRedNotice(Notice.USER_NOTICE_NEW_DAILYCHALLENGE1)
		end
	else
		self:setProperty(Notice.USER_NOTICE_NEW_DAILYCHALLENGE1, 0)
		self:postRedNotice(Notice.USER_NOTICE_NEW_DAILYCHALLENGE1)
	end
	if totalNum > 0 and passNum == 0 then
		self:setProperty(Notice.USER_NOTICE_NEW_DAILYCHALLENGE, 1)
	else
		self:setProperty(Notice.USER_NOTICE_NEW_DAILYCHALLENGE, 0)
	end
	self:postRedNotice(Notice.USER_NOTICE_NEW_DAILYCHALLENGE)
end


--如果num不经过网络请求改变则需要手动传值
function RedNoticeManager:postRedNotice(noticeName,isBlue_)
	local num_ = self:getProperty(noticeName)
	EventNoticeManager:getInstance():dispatchEvent({name = noticeName, num = num_ or 0, isBlue = isBlue_})
end

return RedNoticeManager