--
-- Author: zen.zhao88@gmail.com
-- Date: 2014-07-24 12:16:11
--
local EventNoticeManager = class("EventNoticeManager")
function EventNoticeManager:getInstance()
	local o = _G.eventNoticeManager_
	if o then
		return o
	end
	o = EventNoticeManager.new()
	_G.eventNoticeManager_ = o
	return o
end

function EventNoticeManager:clean()
	_G.eventNoticeManager_ = false
end

function EventNoticeManager:ctor()
    self.listeners_ = {}
    self.listenerHandleIndex_ = 0
    -- self.debug_ = (DEBUG==2 )
end

function EventNoticeManager:addEventListener(handle, eventName, listener, data)
    assert(type(eventName) == "string" and eventName ~= "",
        "EventNoticeManager:addEventListener() - invalid eventName")
    eventName = string.upper(eventName)
    if self.listeners_[eventName] == nil then
        self.listeners_[eventName] = {}
    end

    -- self.listenerHandleIndex_ = self.listenerHandleIndex_ + 1
    handle = tostring(handle)
    self.listeners_[eventName][handle] = {listener, data}

    if self.debug_ then
        if data then
            echoInfo("EventNoticeManager:addEventListener() - add listener [%s] %s:%s for event %s", handle, tostring(data), tostring(listener), eventName)
        else
            echoInfo("EventNoticeManager:addEventListener() - add listener [%s] %s for event %s", handle, tostring(listener), eventName)
        end
    end

    return handle
end

function EventNoticeManager:dispatchEvent(event)
    event.name = string.upper(event.name)
    local eventName = event.name
    if self.debug_ then
        echoInfo("EventNoticeManager:dispatchEvent() - dispatching event %s", eventName)
    end

    if self.listeners_[eventName] == nil then return end
    event.target = self.target_
    for handle, listener in pairs(self.listeners_[eventName]) do
        if self.debug_ then
            echoInfo("EventNoticeManager:dispatchEvent() - dispatching event %s to listener [%s]", eventName, handle)
        end
        local ret
        if listener[2] then
            ret = listener[1](listener[2], event)
        else
            ret = listener[1](event)
        end
        if ret == false then
            if self.debug_ then
                echoInfo("EventNoticeManager:dispatchEvent() - break dispatching for event %s", eventName)
            end
            break
        end
    end
    return self
end

function EventNoticeManager:removeEventListener(key1,eventName,key2)
    eventName = string.upper(eventName)
    if self.listeners_[eventName] == nil then return end

    for handle, listener in pairs(self.listeners_[eventName]) do
        if tostring(key1) == handle or (key1 == listener[1] and key2 == listener[2]) then
            self.listeners_[eventName][handle] = nil
            if self.debug_ then
                echoInfo("EventNoticeManager:removeEventListener() - remove listener [%s] for event %s", handle, eventName)
            end
            return handle
        end
    end
    return self
end

function EventNoticeManager:removeAllEventListenersForEvent(eventName)
    self.listeners_[string.upper(eventName)] = nil
    if self.debug_ then
        echoInfo("EventNoticeManager:removeAllEventListenersForEvent() - remove all listeners for event %s", eventName)
    end
    return self
end

function EventNoticeManager:removeAllEventListeners()
    self.listeners_ = {}
    if self.debug_ then
        echoInfo("EventNoticeManager:removeAllEventListeners() - remove all listeners")
    end
    return self
end

function EventNoticeManager:removeEventListenerForHandle(handle)
	handle = tostring(handle)
	for eventName,v in pairs(self.listeners_) do
		for key,value in pairs(v) do
			if key == handle then
				v[key] = nil
			end
		end
	end
end

function EventNoticeManager:dumpAllEventListeners()
    --printf("---- EventNoticeManager:dumpAllEventListeners() ----")
    for name, listeners in pairs(self.listeners_) do
        printf("-- event: %s", name)
        for handle, listener in pairs(listeners) do
            printf("--     handle: %s, %s", tostring(handle), tostring(listener))
        end
    end
    return self
end

function EventNoticeManager:setDebugEnabled(enabled)
    self.debug_ = enabled
    return self
end

return EventNoticeManager