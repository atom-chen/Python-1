--
-- Author: ZhaoTianze
-- Date: 2016-04-12 12:17:56
--
local iOSIAP = class("iOSIAP")
-- cc.sdk.pay
local Store = require("framework.api.Store")
function iOSIAP:ctor(callback)
	Store.init(handler(self,self.storeCallback))
	--存放等待商品信息请求完毕需要购买的商品ID
	self.needBuyProductId_ = nil
	--存放支付完成，但是还没跟服务器验证完成的订单信息
	-- self.completedTransaction = {}
	self.completedTransactionCb_ = callback
end

function iOSIAP:loadProducts(productId)
	local products = {productId}

	Store.loadProducts(products,handler(self,self.loadProductsCallback))
end

function iOSIAP:buyProduct(productId)
	-- self:loadProducts(productId)
	local result = Store.purchase(productId)
	if not result then --没有请求过商品信息
		self:loadProducts(productId)
		self.needBuyProductId_ = productId
	end
end

function iOSIAP:storeCallback(transaction)
	local state = transaction.transaction.state
	if state == "purchased" then --完成的订单
		-- self.completedTransaction[transaction.transaction.transactionIdentifier] = transaction
    	self:disposeCompletedTransaction_(transaction) --处理完成的订单
    	Store.finishTransaction(transaction.transaction)
    elseif state == "cancelled" then --取消的订单
    	if DisplayManager then
			local btnParams = {
				{
					colorTemplate = AlertView.orangeButtonParams, --颜色模板
					title = Localization.string("是"), --按钮字
				 	callback = function()
				 	end,--按钮响应
				},
			}
			DisplayManager.showAlertView(nil,Localization.string("购买已取消"),btnParams)
		end
    	Store.finishTransaction(transaction.transaction)
    elseif state == "failed" then --失败的订单
    	if DisplayManager then
			local btnParams = {
				{
					colorTemplate = AlertView.orangeButtonParams, --颜色模板
					title = Localization.string("是"), --按钮字
				 	callback = function()
				 	end,--按钮响应
				},
			}
			DisplayManager.showAlertView(nil,Localization.string("购买失败"),btnParams)
		end
    	Store.finishTransaction(transaction.transaction)
    elseif state == "restored" then
    	-- 对于已购商品，处理恢复购买的逻辑
    	Store.finishTransaction(transaction.transaction)
	end
end

function iOSIAP:loadProductsCallback(products)
	-- print("-------------------------")
	-- dump(products, "allProduct",nil)
	if self.needBuyProductId_ then
		local result = Store.purchase(self.needBuyProductId_)
		if not result then --没有请求过商品信息
			if DisplayManager then
				local btnParams = {
					{
						colorTemplate = AlertView.orangeButtonParams, --颜色模板
						title = Localization.string("是"), --按钮字
					 	callback = function()
					 	end,--按钮响应
					},
				}
				DisplayManager.showAlertView(nil,Localization.string("获取商品信息失败"),btnParams)
			end
		end
		self.needBuyProductId_ = nil
	end
end

-- function iOSIAP:beginDisposeTransaction()
-- 	--检测是否有需要处理的订单
-- 	for orderId, transaction in pairs(self.completedTransaction) do
-- 		self:disposeCompletedTransaction_(transaction)
-- 		return
-- 	end
-- end

function iOSIAP:disposeCompletedTransaction_(transaction)
	--组装需要发送给服务器的数据
	-- local userData = GameManager:getUserData()
	-- local userId = userData:getProperty("id")
	-- local serverId = userData:getProperty("serverId")
	-- local userName = userData:getProperty("name")
	-- if not userId or userId == 0 or not serverId or serverId == 0 then --说明还没有登陆成功,等待成功登陆后再发起请求。
	-- 	return
	-- end
	-- local systemConfigMode = SystemConfigModel:getInstance()
	
	-- local rechargeVO = systemConfigMode:findRechargeInfoByProduct_Id(productIdentifier)
	-- if not rechargeVO then --不存在的账号信息
	-- 	printError("购买了不存在的商品:%s",productIdentifier)
	-- 	Store.finishTransaction(transaction.transaction)
	-- 	self.completedTransaction[myOrderId] = nil
	-- 	return
	-- end
	-- local price = rechargeVO:getProperty("price")
	-- local name = rechargeVO:getProperty("name")
	-- transaction.channel_order_id = myOrderId
	-- transaction.pay_status = "1"--购买状态
	-- transaction.amount = price
	-- transaction.product_id = productIdentifier
	-- transaction.user_name = userName--角色名字
	-- transaction.game_user_id = userId--角色ID
	-- transaction.server_id = serverId--服务器ID
	-- transaction.product_name = name --商品名称
	-- transaction.private_data = myOrderId --私有订单
	-- dump(transaction, "构建完需要发送的数据可以发送给服务器")
	-- self:gameServerCallback_(myOrderId)
	-- print("=======-------========")
	-- dump(transaction)
	-- print("-----------=========---------")
	local tran = {}

	tran.orderId = transaction.transaction.transactionIdentifier
	tran.productId = transaction.transaction.productIdentifier
	tran.purchaseTime = tonumber(transaction.transaction.date)
	tran.purchaseToken = transaction.transaction.receipt

	if transaction.transaction.originalTransaction then
		if transaction.transaction.originalTransaction.transactionIdentifier then
			tran.orderId = transaction.transaction.originalTransaction.transactionIdentifier
		end
		if transaction.transaction.originalTransaction.productIdentifier then
			tran.productId = transaction.transaction.originalTransaction.productIdentifier
		end
		if transaction.transaction.originalTransaction.date then
			tran.purchaseTime = tonumber(transaction.transaction.originalTransaction.date)
		end
	end

	local productList = GameManager:getUserData():getProperty("productInfos") or {}
	for k,v in pairs(productList) do
		if v.productId_ == tran.productId then
			tran.productName = v.productName_
		end
	end

	if self.completedTransactionCb_ then
		self.completedTransactionCb_(tran)
	end
end

-- --完成服务端返回成功接受的订单号
-- function iOSIAP:gameServerCallback_(orderId)
-- 	if orderId then
-- 		local transaction = self.completedTransaction[orderId]
-- 		if transaction then
-- 			Store.finishTransaction(transaction.transaction)
-- 			self.completedTransaction[orderId] = nil
-- 		end
-- 		self:beginDisposeTransaction()
-- 	end
-- end

-- function iOSIAP:finishTransaction(data,transaction)
-- 	if data == "ok" and transaction and transaction.private_data then
-- 		self:gameServerCallback_(transaction.private_data)
-- 	end
-- end

return iOSIAP