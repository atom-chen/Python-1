--
-- Author: ZhaoTianze
-- Date: 2016-08-19 16:25:32
--
local AchievementsManager = class("AchievementsManager")

local ClassName_ANDROID = "com/born2play/solitaire/Solitaire"
local ClassName_IOS = "LuaCAPI"

function AchievementsManager.call_(method, arg, sig ,iosArg)
	if GAME_MODE == GAME_MODE_COLLECTION then
		return
	end
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

function AchievementsManager.checkAchievementsAvailable(  )
	return GameCenterDefine.isAchievementsAvailableByPackageName()
end

function AchievementsManager.checkAchievement()
	if not AchievementsManager.checkAchievementsAvailable(  ) then
		return
	end
	local arg = {}
	local sig = "()V"
	local iosArg = nil
	local ok, ret = AchievementsManager.call_("checkAchievement", arg, sig ,iosArg)
end

function AchievementsManager.crownAchievement(count)
	if not AchievementsManager.checkAchievementsAvailable(  ) then
		return
	end
	for key,achievementId in pairs(GameCenterDefine.getAchievements()) do
		if count >= key then
			local arg = {achievementId}
			local sig = "(Ljava/lang/String;)V"
			local iosArg = {achievementId = achievementId}
			local ok, ret = AchievementsManager.call_("unlockAchievement", arg, sig, iosArg)
		end
	end
end

function AchievementsManager.openAchievement(leaderboardId)
	if not AchievementsManager.checkAchievementsAvailable(  ) then
		return
	end
	local arg = {}
	local sig = "()V"
	local iosArg = {leaderboardId = leaderboardId}
	local ok, ret = AchievementsManager.call_("openAchievement", arg, sig ,iosArg)
end



return AchievementsManager