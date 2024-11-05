# EOM
A binder table to represent set of data stream flow event with benefited of luau type.

# Exmaple
```lua
local EOM = require(script.EOM)
local ObjectModel = EOM.hydrate({
	Visible = true,
})

local Subscription = ObjectModel:Subscribe("Counter", function(RecentValue, PreviousValue) 
	print(RecentValue, "|", PreviousValue)
	do
		-- ProcessLogic...
	end
end) -- 0 | nil, Defer execution initial state.

ObjectModel.Counter = 0 -- Initial state
ObjectModel.Counter += 1 -- 1 | 0
ObjectModel.Counter += 1 --  2 | 1

task.delay(1, function()
	ObjectModel.Counter += 1 -- 3 | 2
	Subscription:Unsubscribe() -- same as Subscription:Destroy()
	ObjectModel.Counter += 1 -- no listener
end)

print(getmetatable(ObjectModel)) -- table exist
task.delay(3, function()
	ObjectModel:Dehydrate() -- same as EOM.dehydrate(ObjectModel)
	print(getmetatable(ObjectModel))
end)
```
