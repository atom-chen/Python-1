--
-- Author: Huang Hai Long
-- Date: 2016-07-25 15:15:34
--
local ClassName_ANDROID = "com/born2play/solitaire/Google"
local ClassName_IOS = "AppPayManager"
local iOSIAP = import(".iOSIAP")

local PayManager = class("PayManager")

function PayManager:ctor()
	self.iapPlugin = nil
	if device.platform == "ios" then
		self.iapPlugin = iOSIAP.new(handler(self,self.payLisenter))
	elseif device.platform == "android" then
		local arg = {handler(self, self.payLisenter)}
		local sig = "(I)V"
		local iosArg = {luaFunctionId = handler(self, self.payLisenter)}
		local ok, ret = PayManager.call_("achive", arg, sig ,iosArg)
	end
end

function PayManager:payLisenter( data )
	local purchaseData_ = data
	if device.platform == "android" then
		-- local result = json.decode(data)
		-- if result.code ~= 0 then
		-- 	return
		-- end
		-- local purchaseData = "{}"
		-- local sign = ""
		-- if result.msg then
		-- 	local data = json.decode(result.msg)
		-- 	purchaseData = data.purchaseData
		-- 	sign = data.sign
		-- end
		purchaseData_ = json.decode(data)
		if not purchaseData_ then
			return
		end
		purchaseData_.productName = purchaseData_.developerPayload
		purchaseData_.orderId = purchaseData_.purchaseTime
	end
	GameManager:getUserChargeData():addChargeData(purchaseData_)
	GameManager:getUserData():saveUserData({noAdsStatus = 1})
	GameManager:getUserChargeData():requestConfirmChargeInfo()
	-- GameManager:getPayManager():consumePurchase(purchaseData_.packageName, purchaseData_.purchaseToken)
	GameManager:getPayManager():consumePurchase(data)
end



function PayManager.call_(method, arg, sig ,iosArg)
	if PackageConfigDefine.isSupportCharge() == false then
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

function PayManager:consumePurchase(_jsonData )
	if device.platform ~= "android" then
		return
	end
	local arg = {_jsonData or ""}
	local sig =  "(Ljava/lang/String;)V"
	local iosArg = {}
	local ok, ret = PayManager.call_("come", arg, sig ,iosArg)
	return ok,ret
end

function PayManager:purchaseProductWithIndentifier(productVO,call)
	if device.platform == "ios" and self.iapPlugin then
		-- print("------------purchaseProductWithIndentifier------------")
		self.iapPlugin:buyProduct(productVO:getProperty("productId"))
		return
	end
	local productInfo = {
		developerPayload = productVO:getProperty("productName"),
		Product_Id = productVO:getProperty("productId"),
	}

	local arg = {json.encode(productInfo)}
	local sig =  "(Ljava/lang/String;)V"
	local iosArg = {
		productId = productVO:getProperty("productId")
	}
	local ok, ret = PayManager.call_("play", arg, sig ,iosArg)
	return ok,ret
end

return PayManager