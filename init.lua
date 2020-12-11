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

protextMenu = hs.menubar.new()
protextMenu:setTitle("Open")


previousContext = "default"
contextData = {
}

urlToContext = {
}


function addToCurrentContext(url)
	print(currentContext)
 	
 	table.insert(contextData[currentContext], url)
 	urlToContext[url] = currentContext
 	dump(contextData)

 	hs.notify.show("Add to context",currentContext, url)
	
end

function switchContext(newContext)
	if contextData[newContext] == nil then
		contextData[newContext] = {}

		--Update menubar
		menudata ={}
		for key,value in pairs(contextData) do
			table.insert(menudata, {title = key, fn = function() openUrlsForContext(key) end})	
		end	
		protextMenu:setMenu(menudata)

	end

	previousContext = currentContext
	currentContext = newContext



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
	urls = contextData[contextKey] 
	for index, url in pairs(urls) do
		print(url)
		hs.urlevent.openURL(url)
	end
end
  
hs.hotkey.bind({"cmd", "alt", "ctrl"}, "'", function()
	dump(contextData)	
	button, newContext = hs.dialog.textPrompt("Switch Context", "Please enter something:")
	switchContext(newContext)
	 
end)

hs.hotkey.bind({"cmd", "alt", "ctrl"}, "[", function()
	switchContext(previousContext)	 
end)

-- Extract title to new context
hs.hotkey.bind({"cmd", "alt", "ctrl"}, ";", function()
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
  end
end)


--Init state

switchContext("default")