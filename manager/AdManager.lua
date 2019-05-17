--
-- Author: ZhaoTianze
-- Date: 2016-04-28 19:52:27
--
local AdManager = class("AdManager")

local ClassName_IOS = "Ad_Manager"
local ClassName_ANDROID = "com/born2play/solitaire/Firebase"

function AdManager:ctor(adDataModel)
	self.adDataModel_ = adDataModel	
end

function AdManager:getAdDataModel_()
	if self.adDataModel_ then
		return self.adDataModel_
	end
	if _G.gameManager_ then
		self.adDataModel_ = _G.gameManager_.adDM_
	end
	return self.adDataModel_
end

function AdManager:callMethod_(name,args,sig,iosArgs,isSkipJudge)
	if not self:canShowAds(isSkipJudge) then
		return false, nil
	end
	local ok, ret = nil,nil
	if device.platform == "android" then
		ok, ret = luaj.callStaticMethod(ClassName_ANDROID, name, args, sig)
	elseif device.platform == "ios" then
		ok, ret = luaoc.callStaticMethod(ClassName_IOS, name, iosArgs)
	end
	return ok, ret
end


function AdManager:showBottomBannar(type_)
	if self:judgeNoAds() == true then
		return
	end

	local args = {type_ or common.BannerAdPos.BOTTOM}
	local sig = "(Ljava/lang/String;)V"
	local iosArgs = {adPos = type_ or common.BannerAdPos.BOTTOM}
	self:callMethod_("log1", args, sig, iosArgs)
end

function AdManager:hiddenBottomBannar()
	local args = {}
	local sig = "()V"
	self:callMethod_("log2", args, sig, nil, true)
end

--广告触发统计
function AdManager:analyticeRecord_(adType)
	local eventName = nil
	if adType == UserADInfoVO.AD_TYPE_INTERSTITIAL then
		eventName = "弹窗广告触发"
	end
	if not eventName then
		return
	end
	Analytice.onEvent(eventName, {})

	local eventInfo_ = {}
	eventInfo_.action = "play"
	Analytice.onEventThinkingData("intervalAds", eventInfo_)
end

function AdManager:isRewardVideoReady() -- UserADInfoVO.AD_TYPE_REWAEDVIDEO true
	local args = {}
	local sig = "()Z"
	local iosArgs = nil
	local ok, ret = self:callMethod_("log10", args, sig, iosArgs)
	return tostring(ret) == "true"
end

function AdManager:isNativeBannerReady()
	local args = {}
	local sig = "()Z"
	local iosArgs = nil
	local ok, ret = self:callMethod_("log9", args, sig, iosArgs)
	return ret
end

function AdManager:isBannerReady()
	local args = {}
	local sig = "()Z"
	local iosArgs = nil
	local ok, ret = self:callMethod_("log11", args, sig, iosArgs)
	return ret
end

function AdManager:isInterstitialReady()
	local args = {}
	local sig = "()Z"
	local iosArgs = nil
	local ok, ret = self:callMethod_("log12", args, sig, iosArgs)
	return ret
end

function AdManager:showInterstitialAD()
	if self:judgeNoAds() == true then
		return
	end
	self:analyticeRecord_(UserADInfoVO.AD_TYPE_INTERSTITIAL)
	local args = {}
	local sig = "()V"
	local iosArgs = nil
	self:callMethod_("log", args, sig, iosArgs)
end

function AdManager:showNativeBannar(type_)
	if self:judgeNoAds() == true then
		return
	end
	self.showNativeBanner_ = true
	local posType = type_ or common.BannerAdPos.BOTTOM
	--先判断是否有banner广告
	local ret = self:isNativeBannerReady()
	if tostring(ret) ~= "true" then
		local openNativeBannerAddition = GameManager:getUserCache():getProperty("openNativeBannerAddition")
		if openNativeBannerAddition > 0 then
			self:showBottomBannar(posType)
			self.showNativeBanner_ = false
		end
		return
	end

	local args = {posType}
	local sig = "(Ljava/lang/String;)V"
	local iosArgs = {adPos = posType}
	self:callMethod_("log3", args, sig, iosArgs)
end

function AdManager:hiddenNativeBannar()
	if not self.showNativeBanner_ then
		self:hiddenBottomBannar()
	else
		local args = {}
		local sig = "()V" 
		self:callMethod_("log4", args, sig)
	end
	self.showNativeBanner_ = false
end

function AdManager:showNativeMenuAd(rate)
	if self:judgeNoAds() == true then
		return
	end
	local args = {rate or 0}
	local sig = "(F)V"
	local iosArgs = {height = rate or 0}
	self:callMethod_("log5", args, sig, iosArgs)
end


function AdManager:hiddenNativeMenuAd()
	local args = {}
	local sig = "()V" 
	self:callMethod_("log6", args, sig)
end

function AdManager:hiddenAllAds( )
	local args = {}
	local sig = "()V" 
	self:callMethod_("log7", args, sig)
end


--todo 这里是点击激励视频
function AdManager:showRewardVideoAd(_id,_adPlatform,luaFunctionId)
	luaFunctionId = luaFunctionId or -1
	local args = {luaFunctionId}
	local sig = "(I)V"
	local iosArgs = {luaFunctionId = luaFunctionId}
	self:callMethod_("log8", args, sig, iosArgs, true)
	Analytice.onEvent("点击激励视频", {})
end

function AdManager:judgeNoAds( )
	if _G.gameManager_ 
		and _G.gameManager_:judgeNoAds()  then
		return true
	end
	return false
end

function AdManager:canShowAds(isSkipJudge)
	if isSkipJudge then
		return true
	end
	if _G.gameManager_ 
		and not _G.gameManager_:judgeCanAds()  then
		return false
	end
	return true
end

return AdManager