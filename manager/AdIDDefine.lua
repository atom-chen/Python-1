--
-- Author: Huang Hai Long
-- Date: 2016-07-19 17:06:40
--
local AdIDDefine = {}

AdIDDefine.Admob = {
	dbId = 1, --数据库id(本地存储用)
	--bannar广告ID
	bannarId = {
		ios = {
			default = "ca-app-pub-3858810068453121/7087139695"
		},
		android = {
			["com.queensgame.solitaire"] = "ca-app-pub-9240980261558928/8181966698",
			["com.cardgame.solitaire.full"] = "ca-app-pub-9240980261558928/7221657098",
			["com.cardgame.solitaire.lite"] = "ca-app-pub-9240980261558928/7640459496",
			["default"] = "ca-app-pub-9240980261558928/7640459496"
		},
	},
	--全屏弹窗广告ID
	interstitialId = {
		ios = {
			default = "ca-app-pub-9240980261558928/3554899898"
		},
		android = {
			["com.queensgame.solitaire"] = "ca-app-pub-9240980261558928/3554899898",
			["com.cardgame.solitaire.full"] = "ca-app-pub-9240980261558928/3554899898",
			-- ["com.queensgame.solitaire"] = "ca-app-pub-9240980261558928/3612166293",
			-- ["com.cardgame.solitaire.full"] = "ca-app-pub-9240980261558928/5605323096",
			["com.cardgame.solitaire.lite"] = "ca-app-pub-9240980261558928/2931058296",
			["default"] = "ca-app-pub-9240980261558928/2931058296"
		},
	},
}

AdIDDefine.Facebook = {
	dbId = 2, --数据库id(本地存储用)
	--bannar广告ID
	bannarId = {
		ios = {
			default = "814097462057274_856172764516410"
		},
		android = {
			default = "814097462057274_856172764516410"
		},
	},
	--全屏弹窗广告ID
	interstitialId = {
		ios = {
			default = "814097462057274_855733191227034"
		},
		android = {
			default = "814097462057274_855733191227034"
		},
	},
	--natigve广告ID
	natigveId = {
		ios = {
			default = ""
		},
		android = {
			default = "814097462057274_853994041400949"
		},
	},
}



return AdIDDefine