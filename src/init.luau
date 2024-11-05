--!native
--!optimize 2

--[[
	@Dev_Bas
	EventObjectModel v1.0.0:
	A binder table to represent set of data stream flow event with benefited of luau type.
]]--

local EventObjectModel = {}

--[[
	Normalize EOM to be normal table.

	<strong>- Parameters -</strong>
	<strong>@tbl</strong>: table <em>--Intellisense</em>
]]--
function EventObjectModel.dehydrate <T> (tbl: T)
	local EOM = getmetatable(tbl)
	if (EOM) then
		table.clear(EOM)
	end
	return setmetatable(tbl, nil)
end

--[[
	Allow turn table into event object model driven (EOM).
	Key that aren't allowed to edit once turn into EOM:
	tbl[<strong>(_G | _Subscriber | Subscribe | Publish | Replace | Dehydrate)</strong>: string = x: any

	<strong>- Parameters -</strong>
	<strong>@tbl</strong>: table <em>--Intellisense</em>
]]--
function EventObjectModel.hydrate <T> (tbl: T)
	local EOM = {
		_G = tbl,
		_Subscriber = {},
	}

	type ListKeys = keyof<typeof(tbl)>
	type ListValues = T & {ListValues}

	--[[
		Produce a subscription stream in the group with given key.

		<strong>- Parameters -</strong>
		<strong>@Key</strong>: string <em>--Intellisense</em>
		<strong>@Callback</strong>: (<strong>@RecentValue</strong>: any, <strong>@PreviousValue</strong>: any) -> () <em></em>
	]]--
	function EOM:Subscribe(Key: ListKeys, Callback: (RecentValue: ListValues, PreviousValue: ListValues) -> ())
		self._Subscriber[Key] = self._Subscriber[Key] or {}
		local Id = #self._Subscriber[Key] + 1
		self._Subscriber[Key][Id] = Callback
		if (self[Key] ~= nil) then
			self:Publish(Key, self[Key])
		end
		local _Self = self
		local SubscribeStream = {}
		function SubscribeStream:Destroy() -- Maid: auto-discconect
			task.defer(function()
				_Self._Subscriber[Key][Id] = nil
				table.clear(SubscribeStream)
			end)
		end
		function SubscribeStream:Unsubscribe()
			SubscribeStream:Destroy()
		end
		return SubscribeStream
	end
	--[[
		Publish a value into subscription stream group with given key.

		<strong>- Parameters -</strong>
		<strong>@Key</strong>: string <em>--Intellisense</em>
		<strong>@NewValue</strong>: any?
		<strong>@PreviousValue</strong>: any?
	]]--
	function EOM:Publish(Key: ListKeys, NewValue: ListValues?, PreviousValue: ListValues?)
		task.defer(function()
			local SubscribeStream = self._Subscriber[Key]
			if (SubscribeStream) then
				NewValue = (NewValue == nil) and self._G[Key] or NewValue
				for _, Task in SubscribeStream do
					Task(NewValue, PreviousValue)
				end
			end
		end)
	end
	--[[
		Replace a value into subscription stream but silent mode.
		Normally tbl[key] = value, will automatic trigger.

		<strong>- Parameters -</strong>
		<strong>@Key</strong>: string <em>--Intellisense</em>
		<strong>@NewValue</strong>: any
	]]--
	function EOM:Replace(Key: ListKeys, NewValue: ListValues)
		self._G[Key] = NewValue
	end
	--[[
		Normalize self EOM state to be normal table.
	]]--
	function EOM:Dehydrate()
		return EventObjectModel.dehydrate(tbl)
	end

	return setmetatable({} :: T, {
		__index = function(_, Key)
			return EOM._G[Key] or EOM[Key]
		end :: typeof(EOM),
		__newindex = function(_, Key, RecentValue)
			-- @EventProducer
			local PreviousValue = EOM._G[Key]
			rawset(EOM._G, Key, RecentValue)
			if (EOM[Key]) then
				warn(`EOM: "{Key}" index was locked (readonly index)`)
				rawset(EOM._G, Key, PreviousValue)
			elseif (EOM._G[Key] ~= nil) then
				EOM:Publish(Key, RecentValue, PreviousValue)
			end
		end,
	})
end

return EventObjectModel