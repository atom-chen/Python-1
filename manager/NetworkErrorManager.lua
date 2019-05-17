--
-- Author: ZhaoTianze
-- Date: 2016-06-18 12:11:32
--
local NetworkErrorManager = {}
local LCCodeConst = import("..LeanCloud.LCCodeConst")
--code:错误码，发送的请求类型
function NetworkErrorManager.parseError(code,request)
	EventNoticeManager:getInstance():dispatchEvent({name = Notice.NETWORK_COMPLETE_ERROR})
	local wait = request.wait --本次请求是否显示了loading页面
	if wait == false then
		return
	end
	local message = nil
	--进行后续的错误处理
	if code == LCCodeConst.RESULT_NO_CHALLENGE_DATA then
		message = "没有对应月份的数据！"
	elseif code == LCCodeConst.RESULT_NO_USER_DATA then
		message = "数据异常，请打开网络重新启动游戏！"
	elseif code == LCCodeConst.RESULT_DATA_ERROR then
		message = "返回数据格式错误"
	else
		message = "网络异常！"
	end

	if message == nil then
		return
	end
	local btnParams = {
		{
			colorTemplate = AlertView.green1ButtonParams, --颜色模板
			title = "确定_按钮文字", --按钮字
		 	callback = function() 	end,--按钮响应
		},
	}
	DisplayManager.showAlertView(nil,Localization.string(message),btnParams)
end

return NetworkErrorManager