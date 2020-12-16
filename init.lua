
local obj = {}
obj.__index = obj

-- Metadata
obj.name = 'Protext'
obj.version = '0.1'
obj.author = 'Zac Cicala <zcicala@gmail.com>'
obj.license = 'MIT - https://opensource.org/licenses/MIT'

obj.protextMenu = nil


obj.maxRecentEntries=10

obj.stateFile = "~/.hammerspoon/protextState.json"
obj.state = {
	currentContextPosition = 1,
	recentSize = 1,
	currentContext = "default",
	contextData = {default = {}},
	urlToContext = {},
	recentContexts = {"default"},
}

function obj:init(  )
end

function obj:start()
	self:readState(self.stateFile)
	self:switchContext(self.state.currentContext)
	self.protextMenu = hs.menubar.new()
	self.protextMenu:setTitle("Protext")
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
			context = nil
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
	hs.json.write(self.state, file, true, true)
end

function obj:addToCurrentContext(url)
	local currentContext = self.state.currentContext
 	
 	table.insert(self.state.contextData[currentContext], url)
 	self.state.urlToContext[url] = currentContext
 	
	hs.notify.show("Add to context",currentContext, url)
	self:addRecentContext(currentContext) 
 	self:writeState(self.stateFile)
	--dump(state)
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
	indexToRemove = -1
	for index, val in pairs(self.state.recentContexts) do
		if val == context then
			print(index, val)
			indexToRemove = index
			break
		end
	end

	if indexToRemove > -1 then
		tables.remove(self.state.recentContexts, indexToRemove)
		self.state.recentSize = self.state.recentSize -1
	end
	
	table.insert(self.state.recentContexts, context)
	self.state.recentSize = self.state.recentSize + 1

	-- if the table is too big then lets remove the first element
	if self.state.recentSize > self.maxRecentEntries then
		table.remove(self.state.recentContexts, 1)
	end

	--Position of currentContext has shifted
	self.state.currentContextPosition = self.state.recentSize
	self:updateUI()
end

function obj:updateUI()
	--Update menubar
	local menudata = {}
	--for key, value in pairs(state.contextData) do
	for index, key in pairs(self.state.recentContexts) do
		table.insert(menudata, {title = key, menu = {
				{title ="Open", fn = function() self:openUrlsForContext(key) end}, 
				{title ="Switch", fn = function() self:switchContext(key) end}
		}})	
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

	hs.notify.show("Switch context", "switch to", newContext)
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
		self:dump(currentApp)
		self:dump(hs.axuielement.windowElement(currentApp:visibleWindows()[1]):allAttributeValues())
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

	--Type in new context
	--Default: {"cmd", "alt", "ctrl"}, ";"
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
	if prefix == nil then
		prefix = " "
	end

	if o == nil then
		return
	end

	print(prefix.."----", type(o), "------")
	if type(o) == 'string' then
		printf(prefix..o)
	elseif type(o) == 'table' then
      for key,value in pairs(o) do
      	if(type(value) == 'table') then
      		print(prefix..key.." -->")
      		self:dump(value, "    " ..prefix)
      	else
    		print(prefix..key, value)
    	end
	  end
   else
    for key,value in pairs(getmetatable(o)) do
    	print(prefix..key, value)
	end
   end

end

return obj