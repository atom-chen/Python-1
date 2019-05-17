--
-- Author: yang fuchao
-- Date: 2016-07-06 12:14:55
--
local ResManager = {}
ResManager.resConfig = nil

ResManager.installedThemeCfg = {}--安装的主题
ResManager.localThemeCfg = {}

function ResManager:readInstalledTheme( )
	ResManager.installedThemeCfg = {}
	if device.platform ~= "android" and device.platform ~= "ios" then
		return
	end
	local exist = lfs.checkDir("UI_Resources")
	if not exist then
		return
	end
	local path_ = lfs.getWritePath("UI_Resources")
	local jasonList_ = tools.readFileJasonList(path_)
	for i=1,#jasonList_ do
		ResManager.installedThemeCfg[#ResManager.installedThemeCfg + 1] = jasonList_[i]
	end

	local jasonList_ = tools.readFileJasonList(path_, ".cardcolor")
	for i=1,#jasonList_ do
		for k,v in pairs(jasonList_[i]) do
			CardDefine.classic_color[tonumber(k)] = v
		end
	end
end

function ResManager:readLocalTheme( )
	ResManager.localThemeCfg = {}
	if GameManager then
		ResManager.localThemeCfg = GameManager:getNativeManager():getFileJasonList("themeData")
	end

	if GameManager then
		local jasonList_ = GameManager:getNativeManager():getFileJasonList("themeData", ".cardcolor")
		for i=1,#jasonList_ do
			for k,v in pairs(jasonList_[i]) do
				CardDefine.classic_color[tonumber(k)] = v
			end
		end
	end
end

function ResManager.isBelongLocalTheme(key)
	for i=1,#ResManager.localThemeCfg do
		if ResManager.localThemeCfg[i].key == key then
			return true
		end
	end
	return false
end

function ResManager.getIOSDataConfig( )
	if ResManager.iosDataConfig and type(ResManager.iosDataConfig) == "table" then
		return ResManager.iosDataConfig
	end
	--打开文件
	local data = CCFileUtils:sharedFileUtils():getFileData("scr/iosData.json")
	if data then
		ResManager.iosDataConfig = json.decode(data) or {}
	else
		ResManager.iosDataConfig = {}
	end
	return ResManager.iosDataConfig
end

function ResManager.getResConfig( )
	if ResManager.resConfig and type(ResManager.resConfig) == "table" then
		return ResManager.resConfig
	end
	local data = PackageResConfig.packageData
	--打开文件
	-- local data = CCFileUtils:sharedFileUtils():getFileData("scr/package.json")
	if data then
		ResManager.resConfig = json.decode(data) or {}
	else
		ResManager.resConfig = {}
	end
	return ResManager.resConfig
end

function ResManager.getResLiteConfig( )
	if ResManager.resLiteConfig and type(ResManager.resLiteConfig) == "table" then
		return ResManager.resLiteConfig
	end
	local data = PackageResConfig.packageLiteData
	--打开文件
	-- local data = CCFileUtils:sharedFileUtils():getFileData("scr/packageLite.json")
	if data then
		ResManager.resLiteConfig = json.decode(data) or {}
	else
		ResManager.resLiteConfig = {}
	end
	return ResManager.resLiteConfig
end

function ResManager.getValue(configTab,versionType, packageName ,key)
	if not configTab then
		return
	end
	if not versionType then
		return
	end
	if not packageName then
		return
	end
	if not configTab[versionType] then
		return
	end
	if not configTab[versionType][packageName] then
		return
	end
	return configTab[versionType][packageName][key]
end

function ResManager.getDefaultResConfig( packageName )
	local configTab = ResManager.getResLiteConfig( )
	if packageName then
		return configTab[packageName] or {}
	end
	return {}
end

function ResManager.getGameMode()
	local configTab = nil
	if device.platform == "android" or device.platform == "mac" then
		configTab = ResManager.getResConfig()
	elseif device.platform == "ios" then
		configTab = ResManager.getIOSDataConfig()
	end
	local versionType = "basic"
	local packageName = NativeManager.getPackageName()
	if configTab and versionType and packageName and configTab[versionType] then
		if configTab[versionType][packageName] then
			local config = configTab[versionType][packageName]
			if config["game_mode"] then
				return config["game_mode"]
			end
		end
	end
	return nil
end

function ResManager.useUsServer()
	local config = {}
	local data = CCFileUtils:sharedFileUtils():getFileData("scr/config.json")
	if data then
		config = json.decode(data) or {}
	end
	--为了保证玩家解包修改server字段之后依然有很大概率连接美国服
	if config.server and config.server == "cn" then
		return false
	else
		return true
	end
end

function ResManager.getDataByKey(key)
	for i=1,#ResManager.localThemeCfg do
		if ResManager.localThemeCfg[i].key == key then
			return ResManager.localThemeCfg[i]
		end
	end
	return nil
end

return ResManager