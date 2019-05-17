--
-- Author: Huang Hai Long
-- Date: 2016-09-29 14:55:28
--
local NetImageManager = class("NetImageManager")

function NetImageManager:ctor(db)
	self.path_ = device.writablePath.."netImage/" --获取本地存储目录
	self.cacheList_ = {}
	self.isCacheListChange_ = false
	self.interval_ = 0
	if not io.exists(self.path_) then
		lfs.mkdir(self.path_) --目录不存在，创建此目录
	end
	-- local dataDB_ = {}
	-- if db then
	-- 	dataDB_.cacheList_ = tools.loadDataByDB(db,"netImage",UserNetImageVO)
	-- end
	-- self:parseDataBase(dataDB_)
	-- self:cleanError_()
end

function NetImageManager:retainImage(fileName)
	if not fileName then
		return
	end
	if not self.cacheImageList_ then
		self.cacheImageList_ = {}
	end
	if not self.cacheImageList_[fileName] then
		self.cacheImageList_[fileName] = 0
	end
	self.cacheImageList_[fileName] = self.cacheImageList_[fileName] + 1
end

function NetImageManager:releseImage(fileName)
	if not fileName then
		return
	end
	if not self.cacheImageList_ then
		return
	end
	if not self.cacheImageList_[fileName] then
		return
	end
	self.cacheImageList_[fileName] = self.cacheImageList_[fileName] - 1
	if self.cacheImageList_[fileName] < 0 then 
		self.cacheImageList_[fileName] = 0 
	end
end

function NetImageManager:cleanUnusedImage()
	if not self.cacheImageList_ then
		return
	end
	for k,v in pairs(self.cacheImageList_) do
		if v < 1 then
			CCTextureCache:sharedTextureCache():removeTextureForKey(k)
		end
	end
end

function NetImageManager:parseDataBase(data)
	-- if not data then return end
	-- --活局缓存
	-- if data.cacheList_ then
	-- 	self.cacheList_ = {}
	-- 	for i=1,#data.cacheList_ do
	-- 		local userNetImageVO = self:initNetImage_(data.cacheList_[i])
	-- 		if userNetImageVO then
	-- 			self.cacheList_[#self.cacheList_ + 1] = userNetImageVO
	-- 		end
	-- 	end		
	-- end
end

function NetImageManager:initNetImage_(data)
	local userNetImageVO = UserNetImageVO.new(data)
	return userNetImageVO
end

function NetImageManager:loadImage(url)
	local tempMd5 = crypto.md5(url)
	local isExist,fileName = self:judgeUrl_(url)
	printf("NetImageManager:loadImage ---- [%s]", tostring(isExist))
	if isExist then --如果存在，直接更新纹理
		return true,fileName,tempMd5
		-- self:updateTexture(fileName) 
	else --如果不存在，启动http下载
		if network.getInternetConnectionStatus() == cc.kCCNetworkStatusNotReachable then
			print("NetImageManager: NOT NET!!!")
			return
		end

		local request = network.createHTTPRequest(function(event)
				self:onRequestFinished_(event,fileName,tempMd5)
			end,url, "GET")
			
		request:start()
	end
	return false,fileName,tempMd5
end

function NetImageManager:onRequestFinished_(event,fileName,tempMd5)
	if event.name == "inprogress" then
		return
	end
    local ok = (event.name == "completed")
    local request = event.request
    if not ok then
        -- 请求失败，显示错误代码和错误消息
        EventNoticeManager:getInstance():dispatchEvent({name = Notice.USER_NETWORK_ERROR_NET_IMAGE,md5 = tempMd5,file = fileName})
        print(request:getErrorCode(), request:getErrorMessage())
        return
    end

    local code = request:getResponseStatusCode()
    if code ~= 200 then
    	EventNoticeManager:getInstance():dispatchEvent({name = Notice.USER_NETWORK_ERROR_NET_IMAGE,md5 = tempMd5,file = fileName})
        -- 请求结束，但没有返回 200 响应代码
        return
    end
    
    --保存下载数据到本地文件，如果不成功，重试30次。
    local times = 1 
    while (not request:saveResponseData(fileName)) and times < 30 do
    	times = times + 1
    end
    if times >= 30 then
    	return
    end
    self:saveUrlMd5_(false,tempMd5) --保存md5
    EventNoticeManager:getInstance():dispatchEvent({name = Notice.USER_NETWORK_COMPLETE_NET_IMAGE,md5 = tempMd5,file = fileName})
    -- self:updateTexture(fileName) --更新纹理
end

function NetImageManager:cleanError_()
	-- if not self.cacheList_ then
	-- 	return
	-- end
	-- local errorNum_ = 0
	-- for i=1,#self.cacheList_ do
	-- 	if self.cacheList_[i].urlMd5_ == "error" then
	-- 		errorNum_ = errorNum_ + 1
	-- 	end
	-- end
	-- if errorNum_ < 10 then
	-- 	return
	-- end
	-- local list_ = {}
	-- for i=1,#self.cacheList_ do
	-- 	if self.cacheList_[i].urlMd5_ ~= "error" then
	-- 		list_[#list_+1] = self.cacheList_[i]
	-- 		list_[#list_+1].id_ = #list_+1
	-- 	end
	-- end
	-- self.cacheList_ = list_
	-- tools.deleteAllRecordByTable(UserDB,"netImage")
	-- self:saveCacheListToDB(true)
end

function NetImageManager:removeUrlMd5(md5)
	-- if not md5 then
	-- 	return
	-- end
	-- if not self.cacheList_ then
	-- 	return
	-- end
	-- local isError_ = false
	-- for i=1,#self.cacheList_ do
	-- 	if self.cacheList_[i].urlMd5_ == md5 then
	-- 		self.cacheList_[i]:setProperty("urlMd5", "error")
	-- 		isError_ = true
	-- 	end
	-- end
	-- if isError_ then
	-- 	self.isCacheListChange_ = true
	-- 	self:saveCacheListToDB()
	-- end
end

function NetImageManager:saveUrlMd5_(isOvertime,md5)
	-- if isOvertime then
	-- 	return
	-- end
	-- local len_ = #self.cacheList_
	-- local userNetImageVO = UserNetImageVO.new({
	-- 	id = len_+1,
	-- 	urlMd5 = md5,
	-- 	timestamp = os.time(),
	-- 	})
	-- self.cacheList_[userNetImageVO.id_] = userNetImageVO
	-- self.isCacheListChange_ = true
	-- self:saveCacheListToDB()
end

function NetImageManager:judgeUrl_(url)
	-- local tempMd5 = crypto.md5(url)
	local filename = self:getPath_(url)
	local exist = CCFileUtils:sharedFileUtils():isFileExist(filename)
	return exist, filename
	-- for i=1,#self.cacheList_ do
 --        if self.cacheList_[i]:getProperty("urlMd5") == tempMd5 then
 --        	self.cacheList_[i]:setProperty("timestamp", os.time())
 --        	self.isCacheListChange_ = true
 --        	self:saveCacheListToDB()
 --            return true,self:getPath_(url)
 --        end
 --    end
 --    return false,self:getPath_(url)
end

NetImageManager.SAVE_TIME_CD = 60
function NetImageManager:saveCacheListToDB(force)
	-- if not self.isCacheListChange_ then
	-- 	return
	-- end
	-- if not force and self.interval_ > 0 then
	-- 	return
	-- end
	
	-- self.interval_ = NetImageManager.SAVE_TIME_CD
	-- self.isCacheListChange_ = false
	-- tools.writeSqliteFileByTable(UserDB,"netImage",self.cacheList_)
end

function NetImageManager:onUpdataTimer()
	-- if self.interval_ <= 0 then
	-- 	return
	-- end
	-- self.interval_ = self.interval_ - 1
	-- if self.interval_ <= 0 then
	-- 	self:saveCacheListToDB()
	-- end
end


function NetImageManager:getPath_(url)
	local tempMd5 = crypto.md5(url)
	return self.path_..tempMd5..".png"
end

return NetImageManager