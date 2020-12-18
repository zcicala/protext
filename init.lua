
local obj = {}
obj.__index = obj


-- Metadata
obj.name = 'Protext'
obj.version = '0.1'
obj.author = 'Zac Cicala <zcicala@gmail.com>'
obj.license = 'MIT - https://opensource.org/licenses/MIT'

obj.protextMenu = nil


obj.maxRecentEntries=10
obj.enableUI = true
obj.enableStateWrite = true
obj.stateFile = "~/.hammerspoon/protextState.json"
obj.state = {
}

function obj:init(  )
end

function obj:start()
	self.state = {
		currentContextPosition = 1,
		recentSize = 1,
		currentContext = "default",
		contextData = {default = {}},
		urlToContext = {},
		recentContexts = {"default"},
	}
	self.protextMenu = hs.menubar.new()
	self:readState(self.stateFile)
	self:switchContext(self.state.currentContext)
	self:updateUI()
end


obj.handlers = {
	["Google Chrome"] = {
		extractURL = function(window, callback ) 
			window:elementSearch(function (msg, result, count)
		  	 	url = result[1].AXValue
		  	 	callback(url)
		  	 end, function(elem) 
		  	 	return elem:matchesCriteria('AXTextField')
		  	 end)
		end,
		extractContext = function(window, callback )
			print("Extract context")
			local context = nil
			-- e = hs.uielement.focusedElement()
			-- context = e:selectedText()
			
			if context == nil then
				context = window.AXTitle
			end
			callback(context)

			
		end
	},
	-- ["Firefox"] = {
	-- 	extractURL = function(window, callback ) 
	-- 		window:elementSearch(function (msg, result, count)
	-- 	  	 	url = result[1].AXValue
	-- 	  	 	callback(url)
	-- 	  	 end, function(elem) 
	-- 	  	 	dump(elem:allAttributeValues())
	-- 	  	 	return elem:matchesCriteria('AXTextField')
	-- 	  	 end)
	-- 	end,
	-- 	extractContext = function(window, callback )
	-- 		title = window.AXTitle
	-- 		callback(title)
	-- 	end
	-- },
	["Code"] = {		
		extractURL = function(window, callback )
			path = string.gsub(window.AXDocument, "file://","vscode://file")
			callback(path)
		end,
		extractContext = function(window, callback )
			context = window:selectedText()
			if context == nil then
				title = window.AXTitle
			end
			callback(context)
		end
	}
}

function obj:readState(file)
	local readState = hs.json.read(file)
	if readState ~= nil then
		self.state = readState
	end

end

function obj:writeState(file) 
	if self.enableStateWrite then
		hs.json.write(self.state, file, true, true)
	end
end

function obj:addToCurrentContext(url)
	local currentContext = self.state.currentContext
 	
 	table.insert(self.state.contextData[currentContext], url)
 	self.state.urlToContext[url] = currentContext
 	
	if self.updateUI then hs.notify.show("Add to context",currentContext, url) end
	self:addRecentContext(currentContext) 
 	self:writeState(self.stateFile)
	self:updateUI()
end

function obj:shiftRecentContextPosition(diff)
	self.state.currentContextPosition = self.state.currentContextPosition + diff
	if self.state.currentContextPosition < 1 then
		self.state.currentContextPosition = 1
	end

	if self.state.currentContextPosition > self.state.recentSize then
		self.state.currentContextPosition = self.state.recentSize
	end

	self:switchContext(self.state.recentContexts[self.state.currentContextPosition])
end

function obj:addRecentContext(context)
	-- Is this context already the most recent item?
	if self.state.recentContexts[self.state.recentSize]  == context then
		return;
	end

	-- This is basically an LRU Cache, which I don't feel like implementing
	
	-- Remove this context if its already in the list
	local indexToRemove = -1
	for index, val in pairs(self.state.recentContexts) do
		if val == context then
			indexToRemove = index
			break
		end
	end


	if indexToRemove > -1 then
		table.remove(self.state.recentContexts, indexToRemove)
		self.state.recentSize = self.state.recentSize -1
	end
	
	table.insert(self.state.recentContexts, context)
	self.state.recentSize = self.state.recentSize + 1

	-- if the table is too big then lets remove the first element
	if self.state.recentSize > self.maxRecentEntries then
		table.remove(self.state.recentContexts, 1)
		self.state.recentSize = self.state.recentSize - 1
	end

	--Position of currentContext has shifted	
	self.state.currentContextPosition = self.state.recentSize
	self:updateUI()
end

function obj:removeFromRecent(indexToRemove)
	if indexToRemove > -1 then
		table.remove(self.state.recentContexts, indexToRemove)
		self.state.recentSize = self.state.recentSize - 1
		
		--print(hs.inspect(self.state))
		-- if we're trying to remove the currennt context then mmove to the next most recent context
		if self.state.currentContextPosition == indexToRemove then
			self.state.currentContextPosition = self.state.currentContextPosition - 1
			local newContext = self.state.recentContexts[self.state.currentContextPosition]	
			
			self:switchContext(newContext)
		elseif self.state.currentContextPosition > indexToRemove then
			self.state.currentContextPosition = self.state.currentContextPosition - 1
			self:writeState(self.stateFile)
		end
	end

	self:updateUI()
end	

function obj:updateUI()

	--add a flag for not updating the UI for testing
	if self.enableUI == false then
		return
	end

	--Update menubar
	local menudata = {}	
	--Reverse iterate
	for i = #self.state.recentContexts, 1, -1 do
		local key = self.state.recentContexts[i]
		local uris = {
			-- {title ="Switch", fn = function() self:switchContext(key) end},
			{title = "Open All", fn = function() self:openUrlsForContext(key) end}, 
			{title = "Remove", fn = function() self:removeFromRecent(i) end},
		}
		for i,uri in pairs(self.state.contextData[key]) do
			table.insert(uris, {title = uri, fn = function() hs.urlevent.openURL(uri) end})	
		end

	
		table.insert(menudata, {title = string.sub(key,1,32), menu = uris})	
	end	
	self.protextMenu:setMenu(menudata)
end

function obj:switchContext(newContext)
	if self.state.contextData[newContext] == nil then
		self.state.contextData[newContext] = {}
		self:updateUI()
	end

	--Update current context to new context, but don't add it to recent until an entry is actually inserted
	self.state.currentContext = newContext
	self:writeState(self.stateFile)

	if self.enableUI then self.protextMenu:setTitle(string.sub(newContext,1,16)) end
end


function obj:openUrlsForContext(contextKey)
	local urls = self.state.contextData[contextKey] 
	for index, url in pairs(urls) do
		print(url)
		hs.urlevent.openURL(url)
	end
end



function obj:handleExtractURI()
	local currentApp = hs.application.frontmostApplication() 
	local currentAppName = currentApp:name() 
	local w = hs.axuielement.windowElement(currentApp:visibleWindows()[1])
  
	local handler = self.handlers[currentAppName]
  
	if handler ~= nil then
			handler.extractURL(w, function(url )
				self:addToCurrentContext(url)
			end)  		
	else
		print(currentAppName)
		-- w:elementSearch(function (msg, result, count)
		-- 	print(result)
		-- end, function(elem)
		-- 	print(elem) 
		-- 	self:dump(elem:allAttributeValues())
		-- 	return false
		-- end)
		self:dump(currentApp)
		self:dump(hs.axuielement.windowElement(currentApp:visibleWindows()[1]):allAttributeValues())
		hs.axuielement.windowElement(currentApp:visibleWindows()[1]):allDescendantElements(function(elem)
			self:dump(elem)
			if elem.allAttributeValues ~= nil then
				self:dump(elem:allAttributeValues())
			end
		end)
	end
end


-- Extract title to new context
-- If there is already a context associate with the current URI it will switch to that
function obj:handleExtractContext()
	local currentApp = hs.application.frontmostApplication() 
	local currentAppName = currentApp:name() --string.gsub(currentApp:name(), " ", "")
	local w = hs.axuielement.windowElement(currentApp:visibleWindows()[1])
  
	local handler = self.handlers[currentAppName]
  
	if handler ~= nil then
		handler.extractURL(w, function(uri )
			local lookup = self.state.urlToContext[uri]
			if lookup ~= nil then
				-- There is already a context associated with the current URI
				self:switchContext(lookup)
			else
				--We need to create a new context
				handler.extractContext(w, function(title)
					print(title)
					self:switchContext(title)
					self:addToCurrentContext(uri)
				  end)
			end
		end)  						
	end  
  end

function obj:bindHotkeys(keys)
	--Extract URI from current window
	--Default: {"cmd", "alt", "ctrl"}, "/"
    hs.hotkey.bindSpec(
        keys['add_from_window'],
        'Extract App URI from current window and add to current context',
        function()
            self:handleExtractURI()
        end
	)
	
	--URI from Clipboard
	--Default: {"cmd", "alt", "ctrl"}, "."
	hs.hotkey.bindSpec(
        keys['add_from_clipboard'],
        'Add clipboard contents to current context',
        function()
            local clipboard = hs.pasteboard.readString()
			if string.find(clipboard, "://") ~= nil then
				self:addToCurrentContext(clipboard)
			end
        end
	)
	
	--Extract context from window
	--Default: {"cmd", "alt", "ctrl"}, "'"
	hs.hotkey.bindSpec(
        keys['context_from_window'],
        'Extract context from the current window and switch to new context',
        function()
            self:handleExtractContext()
        end
	)

	--Extract context from window
	--Default: {"cmd", "alt", "ctrl"}, "'"
	hs.hotkey.bindSpec(
        keys['context_from_window'],
        'Extract context from the current window and switch to new context',
        function()
            self:handleExtractContext()
        end
	)

	--Extract context from clipboard
	--Default: {"cmd", "alt", "ctrl"}, ";"
	hs.hotkey.bindSpec(
        keys['context_from_clipboard'],
        'Extract context from URI in the clipboard',
        function()
            local clipboard = hs.pasteboard.readString()
			if string.find(clipboard, "://") ~= nil then
				local lookup = self.state.urlToContext[clipboard]
				if lookup ~= nil then
					-- There is already a context associated with the current URI
					self:switchContext(lookup)
				end
			end
        end
	)
	--Type in new context
	--Default: {"cmd", "alt", "ctrl"}, "\"
	hs.hotkey.bindSpec(
        keys['context_from_text_input'],
        'Type in new context',
        function()
            local button, newContext = hs.dialog.textPrompt("Switch Context", "Type in new context")
			self:switchContext(newContext)
        end
	)
	

	--Previous Context
	--Default: {"cmd", "alt", "ctrl"}, "["
	hs.hotkey.bindSpec(
        keys['previous_context'],
        'Shift to previous context',
        function()
			self:shiftRecentContextPosition(-1) 
        end
	)

	--Next Context
	--Default: {"cmd", "alt", "ctrl"}, "="
	hs.hotkey.bindSpec(
        keys['next_context'],
        'Shift to next context',
        function()
			self:shiftRecentContextPosition(1) 
        end
	)
end


function obj:dump(o, prefix)
	-- print(hs.inspect.inspect(o,{depth = 10, metatables = true, process = function(item, path) 
		

	-- 	return true;
	-- end}))

	if prefix == nil then
		prefix = " "
	end

	if o == nil then
		return
	end

	print(prefix.."----", type(o), "------")
	if type(o) == 'string' then
		print(prefix..o)
	elseif type(o) == 'table' then
	  for key,value in pairs(o) do
		local typeVal = type(value)
		if(typeVal == 'table') then
      		print(prefix..key.." -->")
			self:dump(value, "    " ..prefix)
		elseif typeVal == 'userdata' then
		  	print(prefix..key.." -->")
		  	self:dump(getmetatable(value), "    " ..prefix)
			
      	else
    		print(prefix..key, "["..typeVal.."]", value)
    	end
	  end

	  
   else
	print("---getmetatable-----")
    for key,value in pairs(getmetatable(o)) do
    	print(prefix..key, value)
	end
   end

end

function obj:runTests()
	self.enableStateWrite = false
	self.enableUI = false
	for testName,test in pairs(self.tests) do
		print("Running ", testName)
		test(self)
	end
	self.enableStateWrite = true
	self.enableUI = true

end

obj.tests = {
	testRecentReorder = function(self)
		self.state = {
			currentContextPosition = 4,
			recentSize = 4,
			currentContext = "four",
			contextData = {one = {}, two = {}, three = {}, four = {}, },
			urlToContext = {},
			recentContexts = {"one", "two", "three", "four"},
		}
		
		self:addRecentContext("four")
		assert(self.state.recentSize == 4 , "Adding an existing context in the right position shouldn't change anything")
		assert(self.state.currentContextPosition == 4 , "Adding an existing context in the right position shouldn't change anything")
		assert(self.state.recentContexts[1] == "one" and  self.state.recentContexts[4] == "four", "Adding an existing context in the right position shouldn't change anything")

		self:addRecentContext("five")
		assert(self.state.recentSize == 5 , "Adding a new element should increment recent size list")
		assert(self.state.recentContexts[1] == "one", "Adding a new recent context shouldn't change the begining of the list")
		assert(self.state.recentContexts[5] == "five", "Adding a new recent context should add a new element to the end")


		self:addRecentContext("one")
		assert(self.state.recentSize == 5 , "Size should be the same")
		assert(self.state.recentContexts[1] == "two", "'two' should be elementt #1")
		assert(self.state.recentContexts[2] == "three", "'three' should be elementt #2")
		assert(self.state.recentContexts[3] == "four", "'four' should be elementt #3")
		assert(self.state.recentContexts[4] == "five", "'five' should be elementt #4")
		assert(self.state.recentContexts[5] == "one", "'one' should be elementt #5")
	end,
	testtRecentListEvict = function(self)
		self.state = {
			currentContextPosition = 9,
			recentSize = 9,
			currentContext = "nine",
			contextData = {one = {}, two = {}, three = {}, four = {}, five = {}, six = {}, seven = {}, eight = {}, nine = {}, },
			urlToContext = {},
			recentContexts = {"one", "two", "three", "four", "five", "six", "seven", "eight", "nine"},
		}
		
		self:addRecentContext("ten")
		assert(self.state.recentSize == 10 , "After adding an item to a list of length nine the list should be a length of ten")
		assert(self.state.recentContexts[1] == "one", "First element should be 'one'")
		
		self:addRecentContext("eleven")		
		assert(self.state.recentSize == 10 , "After adding an item to a list of length ten the list should sttill be a length of ten")
		assert(self.state.recentContexts[1] == "two", "First element should be 'two' after an evictions")
	end,
	testtRemovingElement= function(self)
		self.state = {
			currentContextPosition = 9,
			recentSize = 9,
			currentContext = "nine",
			contextData = {one = {}, two = {}, three = {}, four = {}, five = {}, six = {}, seven = {}, eight = {}, nine = {}, },
			urlToContext = {},
			recentContexts = {"one", "two", "three", "four", "five", "six", "seven", "eight", "nine"},
		}
		
		self:removeFromRecent(5)
		assert(self.state.recentSize == 8 , "After removing an item to a list of length nine the list should be a length of 8")
		assert(self.state.recentContexts[1] == "one", "First element should be 'one'")
		assert(self.state.recentContexts[8] == "nine", "Eight element should be 'nine'")
		assert(self.state.currentContextPosition == 8 , "After removing an item from a list the currentContextPosition should shift down ")
		
		self:removeFromRecent(8)	
		assert(self.state.recentSize == 7 , "After adding an item to a list of length ten the list should sttill be a length of ten")
		assert(self.state.recentContexts[1] == "one", "First element should remain 'one' ")
		assert(self.state.recentContexts[7] == "eight", " The last element should be eight since nine was removed")
		assert(self.state.currentContextPosition == 7 , "After removing an item from a list the currentContextPosition should shift down")
		assert(self.state.currentContext == "eight" , "After removing an item from a list the currentContextPosition should shift down and currentContext updated")
	end
}





return obj