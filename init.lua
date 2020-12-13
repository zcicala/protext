
-- ctrl + option + command + /   Add current Chrome url to current context
-- ctrl + option + command + ;   Enter a new context and switch to it
-- ctrl + option + command + ''   Use current Chrome tab title as a new context and add the current url to it
-- ctrl + option + command + [   Switch to the previous context

-- "Open" menubar   			 Opens all the urls for that context

protextMenu = hs.menubar.new()
protextMenu:setTitle("Protext")


MAX_RECENT=10

stateFile = "~/.hammerspoon/protextState.json"
state = {
	currentContextPosition = 1,
	recentSize = 1,
	currentContext = "default",
	contextData = {},
	urlToContext = {},
	recentContexts = {"default"},
}

function Init(  )
	readState(stateFile)
	switchContext(state.currentContext)
	updateUI()
end


handlers = {
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
			context = window.selectedText()
			if context == nil then
				title = window.AXTitle
			end
			callback(context)
		end
	}
}



function readState(file)
	readState = hs.json.read(file)
	if readState ~= nil then
		state = readState
	end

end

function writeState(file) 
	hs.json.write(state, file, true, true)
end

function addToCurrentContext(url)
	currentContext = state.currentContext
 	
 	table.insert(state.contextData[currentContext], url)
 	state.urlToContext[url] = currentContext
 	
	hs.notify.show("Add to context",currentContext, url)
	addRecentContext(currentContext) 
 	writeState(stateFile)
	--dump(state)
end

function shiftRecentContextPosition(diff)
	state.currentContextPosition = state.currentContextPosition + diff
	if state.currentContextPosition < 1 then
		state.currentContextPosition = 1
	end

	if state.currentContextPosition > state.recentSize then
		state.currentContextPosition = state.recentSize
	end

	switchContext(state.recentContexts[state.currentContextPosition])
end

function addRecentContext(context)
	-- Is this context already the most recent item?
	if state.recentContexts[state.recentSize]  == context then
		return;
	end

	-- This is basically an LRU Cache, which I don't feel like implementing
	-- Remove this context if its already in the list
	indexToRemove = -1
	for index, val in pairs(state.recentContexts) do
		if val == context then
			print(index, val)
			indexToRemove = index
			break
		end
	end

	if indexToRemove > -1 then
		tables.remove(state.recentContexts, indexToRemove)
		state.recentSize = state.recentSize -1
	end
	
	table.insert(state.recentContexts, context)
	state.recentSize = state.recentSize + 1

	-- if the table is too big then lets remove the first element
	if state.recentSize > MAX_RECENT then
		table.remove(state.recentContexts, 1)
	end

	--Position of currentContext has shifted
	currentContextPosition = state.recentSize
	updateUI()
end

function updateUI()
	--Update menubar
	menudata = {}
	--for key, value in pairs(state.contextData) do
	for index, key in pairs(state.recentContexts) do
		table.insert(menudata, {title = key, menu = {
				{title ="Open", fn = function() openUrlsForContext(key) end}, 
				{title ="Switch", fn = function() switchContext(key) end}
		}})	
	end	
	protextMenu:setMenu(menudata)
end

function switchContext(newContext)
	if state.contextData[newContext] == nil then
		state.contextData[newContext] = {}
		updateUI()
	end

	state.previousContext = state.currentContext
	state.currentContext = newContext
	writeState(stateFile)

	hs.notify.show("Switch context", "switch to", newContext)
end


function openUrlsForContext(contextKey)
	urls = state.contextData[contextKey] 
	for index, url in pairs(urls) do
		print(url)
		hs.urlevent.openURL(url)
	end
end
  
hs.hotkey.bind({"cmd", "alt", "ctrl"}, ";", function()
	--dump(contextData)	
	button, newContext = hs.dialog.textPrompt("Switch Context", "Please enter something:")
	switchContext(newContext)
	 
end)

hs.hotkey.bind({"cmd", "alt", "ctrl"}, "[", function()
	shiftRecentContextPosition(-1) 
end)

hs.hotkey.bind({"cmd", "alt", "ctrl"}, "]", function()
	shiftRecentContextPosition(1) 
end)

-- Extract title to new context
hs.hotkey.bind({"cmd", "alt", "ctrl"}, "'", function()
  currentApp = hs.application.frontmostApplication() 
  currentAppName = currentApp:name() --string.gsub(currentApp:name(), " ", "")
  w = hs.axuielement.windowElement(currentApp:visibleWindows()[1])

  handler = handlers[currentAppName]

  if handler ~= nil then
  		handler.extractContext(w, function(title)
			print(title)
			switchContext(title)
  		end)
  		handler.extractURL(w, function(url )
  			addToCurrentContext(url)
  		end)  		  		
  end

end)

-- Add URL to Context
hs.hotkey.bind({"cmd", "alt", "ctrl"}, "/", function()
  currentApp = hs.application.frontmostApplication() 
  currentAppName = currentApp:name() 
  w = hs.axuielement.windowElement(currentApp:visibleWindows()[1])

  handler = handlers[currentAppName]

  if handler ~= nil then
  		handler.extractURL(w, function(url )
  			addToCurrentContext(url)
  		end)  		
  else
  	print(currentAppName)
  	dump(currentApp)
  	dump(hs.axuielement.windowElement(currentApp:visibleWindows()[1]):allAttributeValues())
  end
end)

--Add from clipboard
hs.hotkey.bind({"cmd", "alt", "ctrl"}, ".", function()
  clipboard = hs.pasteboard.readString()
  if string.find(clipboard, "://") ~= nil then
  	addToCurrentContext(clipboard)
  end
end)

function dump(o, prefix)
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
      		dump(value, "    " ..prefix)
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

--Init state
Init()