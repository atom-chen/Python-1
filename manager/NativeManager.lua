--
-- Author: yang fu chao
-- Date: 2015-06-17 17:04:03
--
--处理与底层的交互

local ClassName_ANDROID = "com/born2play/solitaire/Solitaire"
local ClassName_IOS = "LuaCAPI"

local NativeManager = class("NativeManager")

function NativeManager:ctor(handle)
	local arg = {handle}
	local sig = "(I)V"
	local iosArg = {luaFunctionId = handle}
	local ok, ret = NativeManager.call_("setNativeCall", arg, sig ,iosArg)
end

function NativeManager.call_(method, arg, sig ,iosArg)
	local ok, ret = false, nil
	if device.platform == "android" and arg and sig then
		ok, ret = luaj.callStaticMethod(ClassName_ANDROID, method, arg, sig)
	elseif device.platform == "ios" then
		if iosArg then
			ok, ret = luaoc.callStaticMethod(ClassName_IOS, method, iosArg)
		else
			ok, ret = luaoc.callStaticMethod(ClassName_IOS, method)
		end
	end
	return ok, ret
end

function NativeManager:getBattery( )
	local arg = {}
	local sig = "()I"
	local iosArg = nil
	local ok, ret = NativeManager.call_("getBattery", arg, sig ,iosArg)
	if ok then
		return ok, ret
	else
		return true, 0
	end
end

function NativeManager:sendMail(title, alertTitle, alertMessage, alertBtnTitle)
	local ok, version = NativeManager.getStringVersionCode()
	local message = "UserId: "..common.getOpenUDID().."\nPlatform: "..device.platform.."\nVersion: "..tostring(version).."\nPackageName: "..NativeManager.getPackageName()
	local userId_ = "\n###########################\n"..message.."\n###########################\n"
	--test数据
	local emailAdress = PackageConfigDefine.getEmailAdress()
	local arg = {emailAdress, title, userId_}
	local sig = "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V"
	local iosArg = {
		address = emailAdress, 
		title = title,
		userId = userId_,
		alertTitle = alertTitle, 
		alertMessage = alertMessage, 
		alertBtnTitle = alertBtnTitle
	}
	local ok, ret = NativeManager.call_("sendMail", arg, sig ,iosArg)
	return ok,ret
end

function NativeManager:everyDayLocalNotification(message,tag,fireTime)
	local arg = {message, tostring(tag), fireTime}
	local sig = "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V"
	local iosArg = {
		message = message,
		tag = tag,
		fireTime = fireTime,
	}
	local ok, ret = NativeManager.call_("everyDayLocalNotification", arg, sig ,iosArg)
	return ok,ret
end

function NativeManager.deleteTheme(key)
	local arg = {tostring(key)}
	local sig = "(Ljava/lang/String;)V"
	local iosArg = nil
	local ok, ret = NativeManager.call_("deleteTheme", arg, sig ,iosArg)
	return ok,ret
end

function NativeManager.getStringVersionCode()
	local arg = {}
	local sig = "()Ljava/lang/String;"
	local iosArg = nil
	local ok, ret = NativeManager.call_("getStringVersionCode", arg, sig ,iosArg)
	return ok,ret
end

function NativeManager.getVersionType()
	local arg = {}
	local sig = "()Ljava/lang/String;"
	local iosArg = nil
	local ok, ret = NativeManager.call_("getVersionType", arg, sig ,iosArg)
	return ok,ret
end

function NativeManager:openMoreGame(condition)
	local arg = {"market://search?q=pub:"..tostring(condition)}
	local sig = "(Ljava/lang/String;)V"
	local iosArg = nil
	local ok, ret = NativeManager.call_("openMoreGame", arg, sig ,iosArg)
	return ok,ret
end

--交叉推广
function NativeManager:openCrossPromotion(lan, exit)
	local arg = {tostring(lan), tostring(exit)}
	local sig = "(Ljava/lang/String;Ljava/lang/String;)V"
	local iosArg = nil
	local ok, ret = NativeManager.call_("openCrossPromotion", arg, sig ,iosArg)
	return ok,ret
end

--是否允许屏幕自动旋转
function NativeManager:setScreenAutoRotation( isOpen , orientation)
	local open = "false"
	isOpen = isOpen or false
	if isOpen then
		open = "true"
	end
	local orientation_ = orientation or CONFIG_SCREEN_ORIENTATION
	local arg = {open, orientation_}
	local sig = "(Ljava/lang/String;Ljava/lang/String;)V"
	local iosArg = {shouldAutorotate = isOpen,supportedOrientation = orientation_}
	local ok, ret = NativeManager.call_("setScreenAutoRotation", arg, sig ,iosArg)
	return ok,ret
end

function NativeManager.showNativeInterstitial()
	local arg = {}
	local sig = "()V"
	local iosArg = nil
	NativeManager.call_("showNativeInterstitial", arg, sig ,iosArg)
end

function NativeManager.getPackageName()
	if not NativeManager.packgeName then
		local arg = {}
		local sig = "()Ljava/lang/String;"
		local iosArg = nil
		local ok, ret = NativeManager.call_("getAppPackageName", arg, sig ,iosArg)
		if not ok then
			ret = ""
		else
			NativeManager.packgeName = ret
		end
	end
	return NativeManager.packgeName or ""
end

function NativeManager.getADPackageName()
	local arg = {}
	local sig = "()Ljava/lang/String;"
	local iosArg = nil
	local ok, ret = NativeManager.call_("getADPackageName", arg, sig ,iosArg)
	if not ok then
		ret = ""
	end
	return ret
end

function NativeManager.supportCharge()
	if device.platform == "ios" then
		return "false"
	end
	local arg = {}
	local sig = "()Ljava/lang/String;"
	local iosArg = nil
	local ok, ret = NativeManager.call_("supportCharge", arg, sig ,iosArg)
	if not ok then
		ret = "false"
	end
	return ret
end

function NativeManager.getAppName()
	-- local arg = {}
	-- local sig = "()Ljava/lang/String;"
	-- local iosArg = nil
	-- local ok, ret = NativeManager.call_("getAppName", arg, sig ,iosArg)
	-- if not ok then
	-- 	ret = ""
	-- end
	-- return ret
	return Localization.string(PackageConfigDefine.getAppNameKey())
end

function NativeManager:getBasicAppPackageName()
	local name = GameManager:getUserCache():getProperty("mainAppPackageName") or ""
	-- if device.platform == "android" then
	-- 	name = MAIN_APP_PACKAGENAME_ANDROID
	-- end
	return name
end

function NativeManager:getBasicVersionURL()
	local url_ = PRAISE_URL_IOS
	if device.platform == "android" then
		url_ = PRAISE_URL_ANDROID..self:getBasicAppPackageName()
	end
	return url_
end

function NativeManager:getPraiseURL( )
	local url_ = ""
	if device.platform == "android" then
		url_ = PRAISE_URL_ANDROID..NativeManager.getPackageName()
	elseif device.platform == "ios" then
		url_ = GameCenterDefine.getPraiseURL(NativeManager.getPackageName())
	end
	return url_
end

function NativeManager:getSecondsFromGMT()
	local arg = {}
	local sig = "()I"
	local iosArg = nil
	local ok, ret = NativeManager.call_("getSecondsFromGMT", arg, sig ,iosArg)
	if not ok then
		ret = 8*60*60
	end
	return tonumber(ret)
end

function NativeManager:shareToFriends(url, title, dialogTitle, imgFile)
	local name = NativeManager.getAppName()
	if device.platform == "ios" then
		title = Localization.string("一个好玩的纸牌游戏{NAME}{URL}",{URL="", NAME = name})
	else
		url = Localization.string("一个好玩的纸牌游戏{NAME}{URL}",{URL=url, NAME = name})
	end
	local arg = {url, title, dialogTitle}
	local sig = "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V"
	local iosArg = {url = url, txt = title ,imageFile = imgFile,dialogTitle = dialogTitle}
	local ok, ret = NativeManager.call_("shareToFriends", arg, sig ,iosArg)
	return ok,ret
end

function NativeManager:getInstalledThemeName( )
	local arg = {}
	local sig = "()Ljava/lang/String;"
	local iosArg = nil
	local ok, ret = NativeManager.call_("getInstalledThemeName", arg, sig ,iosArg)
	if not ok then
		ret = ""
	end
	return ret
end

function NativeManager:getAssetsFilesNameList(fodlerPath, type )
	local list = {}
	local ok, ret
	if device.platform == "android" then
		local arg = {fodlerPath or "", type or ""}
		local sig = "(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;"
		ok, ret = luaj.callStaticMethod(ClassName_ANDROID, "getAssetsFilesNameList", arg, sig)
		if not ok then
			ret = "{}"
		end
		list = json.decode(ret)
	end
	return list
end
function NativeManager:getFileJasonList(fodlerPath, type )
	local list_ = {}
	local type_ = type or ".json"
	if device.platform == "android" then
		fodlerPath = "res/"..fodlerPath
		local nameList = self:getAssetsFilesNameList(fodlerPath, type_)
		for i,v in ipairs(nameList) do
			local path_ = CCFileUtils:sharedFileUtils():fullPathForFilename(fodlerPath.."/"..v)
			local data = CCFileUtils:sharedFileUtils():getFileData(path_)
			if data then
				list_[#list_ + 1] = json.decode(data)
			end
		end
	else
		local path_ = CCFileUtils:sharedFileUtils():fullPathForFilename(fodlerPath)
		list_ = tools.readFileJasonList(path_, type_)
	end
	return list_
end

function NativeManager:isInstalled( packageName )
	local arg = {packageName}
	local sig = "(Ljava/lang/String;)Ljava/lang/String;"
	local iosArg = nil
	local ok, ret = NativeManager.call_("isInstalled", arg, sig ,iosArg)
	if not ok then
		ret = "false"
	end
	return ret
end

function NativeManager:openApp( url, packageName )
	local arg = {url, packageName}
	local sig = "(Ljava/lang/String;Ljava/lang/String;)V"
	local iosArg = nil
	local ok, ret = NativeManager.call_("openApp", arg, sig ,iosArg)
	return ok, ret
end

function NativeManager:getNoticeStatus()
	local arg = {}
	local sig = "()Ljava/lang/String;"
	local iosArg = nil
	local ok, ret = NativeManager.call_("getNoticeStatus", arg, sig ,iosArg)
	if not ok then
		ret = ""
	end
	return ret
end

function NativeManager:setPushStatus(value)
	local valeStr_ = "false"
	if value == 1 then
		valeStr_ = "true"
	end
	local channel_ = GAME_MODE
	local arg = {valeStr_}
	local sig = "(Ljava/lang/String;)V"
	local iosArg = {status = valeStr_ ,channel = channel_, language = Localization.getGameLanguage()}
	local ok, ret = NativeManager.call_("setPushStatus", arg, sig ,iosArg)
	return ok,ret
end

function NativeManager:setPushLanguage(lan)
	local arg = {lan}
	local sig =  "(Ljava/lang/String;)V"
	local iosArg = {
		language = lan
	}
	local ok, ret = NativeManager.call_("setPushLanguage", arg, sig ,iosArg)
	return ok,ret
end

function NativeManager:saveInstallation()
	local arg = {}
	local sig = "()V"
	local iosArg = nil
	local ok, ret = NativeManager.call_("saveInstallation", arg, sig ,iosArg)
	if not ok then
		ret = ""
	end
	return ret
end
--设置锁屏变量并展示
function NativeManager:setShowLockScreen(openLockScreenAds)
	-- local arg = {openLockScreenAds} --是否打开锁屏广告[0:关、1:开]
	-- local sig = "(Z)V"
	-- local iosArg = nil
	-- local ok, ret = NativeManager.call_("setShowLockScreen", arg, sig ,iosArg)
	-- if not ok then
	-- 	ret = false
	-- end
	-- return ret
end
--得到锁屏变量值 -- 返回 true/false
function NativeManager:canShowLockScreen()
	-- local arg = {}
	-- local sig = "()Z"
	-- local iosArg = nil
	-- local ok, ret = NativeManager.call_("canShowLockScreen", arg, sig ,iosArg)
	-- if not ok then
	-- 	ret = false
	-- end
	-- return ret
	return false
end
--新手引导控制锁屏node
function NativeManager:isLockScreenExist()
	-- local arg = {}
	-- local sig = "()Z"
	-- local iosArg = nil
	-- local ok, ret = NativeManager.call_("isLockScreenExist", arg, sig ,iosArg)
	-- if not ok then
	-- 	ret = false
	-- end
	-- return ret
	return false
end
--得到第一次打开游戏的时间戳
function NativeManager:getMilliSecondForFOT()
	-- local arg = {}
	-- local sig = "()Ljava/lang/String;"
	-- local iosArg = nil
	-- local ok, ret = NativeManager.call_("getFirstOpenTime", arg, sig ,iosArg)
	-- if not ok then
	-- 	ret = "0"
	-- end
	-- return tonumber(ret)
	return "0"
end

function NativeManager:getLockScreenCfg()
	-- local arg = {}
	-- local sig = "()Ljava/lang/String;"
	-- local iosArg = nil
	-- local ok, ret = NativeManager.call_("getLockScreenCfg", arg, sig ,iosArg)
	-- if not ok then
	-- 	ret = "{}"
	-- end
	-- -- {
	-- -- 	isOpen:true,
	-- -- 	openTime:13235
	-- -- }
	-- ret = json.decode(ret)
	-- -- ret.openTime = 50
	-- -- ret.isOpen = true
	return "{}"
end

function NativeManager:submitScore( score , leaderboardId)
	if GAME_MODE == GAME_MODE_COLLECTION or (not GameCenterDefine.isLeaderBoardAvailableByPackageName()) then -- 增加不支持排行榜包名判断
		return
	end
	local score_ = tonumber(score) or 0
	local arg = {score_,leaderboardId}
	local sig = "(ILjava/lang/String;)V"
	local iosArg = {score = score, leaderboardId = leaderboardId}
	local ok, ret = NativeManager.call_("submitScore", arg, sig ,iosArg)
end
--"CgkI5Jfs6_8NEAIQAA"
function NativeManager:openRankBoard(leaderboardId)
	if GAME_MODE == GAME_MODE_COLLECTION or (not GameCenterDefine.isLeaderBoardAvailableByPackageName()) then -- 增加不支持排行榜包名判断
		return
	end
	local arg = {leaderboardId}
	local sig = "(Ljava/lang/String;)V"
	local iosArg = {leaderboardId = leaderboardId}
	local ok, ret = NativeManager.call_("openRankBoard", arg, sig ,iosArg)
end

--添加push推送标示
function NativeManager.getLocalPushTag( ... )
	local arg = {}
	local sig = "()Ljava/lang/String;"
	local iosArg = nil
	local ok, ret = NativeManager.call_("getLocalPushTag", arg, sig ,iosArg)
	print("java push tag===>>>>>",ok, type(ret))

	if ok then
		return ret
	else
		return 0
	end
end

--添加hook
function NativeManager:isHook(  )
	local arg = {}
	local sig = "()Z"
	local iosArg = nil
	local ok, ret = NativeManager.call_("isHook", arg, sig ,iosArg)
	-- print("获取的hook======>>>>>>",ok, ret)
	if not ok then
		ret = false
	end
	return ret
end

--获取签名
function NativeManager:getSignature(  )

	local arg = {}
	local sig = "()Ljava/lang/String;"
	local iosArg = nil
	local ok, ret = NativeManager.call_("getSignPackageName", arg, sig ,iosArg)
	-- print("获取的签名======>>>>>>",ok, ret)
	if not ok then
		ret = ""
	end
	return ret
end

return NativeManager