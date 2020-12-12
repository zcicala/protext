
-- ctrl + option + command + /   Add current Chrome url to current context
-- ctrl + option + command + ;   Enter a new context and switch to it
-- ctrl + option + command + ''   Use current Chrome tab title as a new context and add the current url to it
-- ctrl + option + command + [   Switch to the previous context

-- "Open" menubar   			 Opens all the urls for that context

protextMenu = hs.menubar.new()
protextMenu:setTitle("Open")



stateFile = "~/.hammerspoon/protextState.json"
state = {
	previousContext = "default",
	currentContext = "default",
	contextData = {},
	urlToContext = {}
}

function Init(  )
	readState(stateFile)
	switchContext(state.currentContext)
	updateUI()
end

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
 	writeState(stateFile)
 	
 	hs.notify.show("Add to context",currentContext, url)
	dump(state)
end

function updateUI()
	--Update menubar
	menudata = {}
	for key,value in pairs(state.contextData) do
		table.insert(menudata, {title = key, fn = function() openUrlsForContext(key) end})	
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

function extractUrlFromWindow(w)
	 w:elementSearch(function (msg, result, count)
  	 	url = result[1].AXValue
  	 	addToCurrentContext(url)
  	 end, function(elem) 
  	 	return elem:matchesCriteria('AXTextField')
  	 end)
end


function openUrlsForContext(contextKey)
	urls = state.contextData[contextKey] 
	for index, url in pairs(urls) do
		print(url)
		hs.urlevent.openURL(url)
	end
end
  
hs.hotkey.bind({"cmd", "alt", "ctrl"}, ";", function()
	dump(contextData)	
	button, newContext = hs.dialog.textPrompt("Switch Context", "Please enter something:")
	switchContext(newContext)
	 
end)

hs.hotkey.bind({"cmd", "alt", "ctrl"}, "[", function()
	switchContext(previousContext)	 
end)

-- Extract title to new context
hs.hotkey.bind({"cmd", "alt", "ctrl"}, "'", function()
  currentApp = hs.application.frontmostApplication() 
  currentAppName = currentApp:name()
  if currentAppName == "Google Chrome" then
  	 w = hs.axuielement.windowElement(currentApp:visibleWindows()[1])
  	 title = w.AXTitle
  	 print(title)
  	 switchContext(title)
  	 extractUrlFromWindow(w)
  end
end)

-- Add URL to Context
hs.hotkey.bind({"cmd", "alt", "ctrl"}, "/", function()
  currentApp = hs.application.frontmostApplication() 
  currentAppName = currentApp:name()
  if currentAppName == "Google Chrome" then
  		w = hs.axuielement.windowElement(currentApp:visibleWindows()[1])
  	 	extractUrlFromWindow(w)
  else
  	dump(hs.axuielement.windowElement(currentApp:visibleWindows()[1]):allAttributeValues())
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