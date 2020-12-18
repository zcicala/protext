# Protext
## Problem
With Protext I am trying to solve a problemm of multi tasking. Throughout a normal day, I am often working on multiple tasks or projects of various scope. Some of these tasks are long lived, but vast majority are on the scale of 3 hours to three days. For any size task I probably have many web tabs open and likely a code editor or terminal. Because many of these tasks are done in parallel I frequently end up in a state where I have a bunch of task relevant tabs open for several days. I don't want to close the tabs, because the task isn't done yet and I don't really want to bookmark them, because they won't be relevant once the task is done. Over the course of a week this can proliferate to a state where I have 10 wiindows with 30 tabs a piece. At this point I often declare bankruptcy and just close everything and start from scratch with the hopes that my recent browser history will save me.

Protext attempts to solve this by introducing the concept of *contexts* which are a tool for aggregating application links. Protext assumes that, at any given moment, you are working on specific task with an assoicated *context*. As you are working and opening webpages or applications you can add them to the current context with a simple keypress. With the relevant URIs recorded you can feel safe closing out everything in your browser and being able to quickly re-open everything later. 

## Concepts

* **Contexts**: Contexts are the main abstraction in Protext. They can be thoguht of as a topic under which you aggregate URIs. They are just simple text strings. 
    * **Extracted Contexts** For supported apps Protext will try to automatically extract the context of the current app/window. This is often just the the title of the window
    * **Manual Contexts** Protext also supports the option to manually enter a context in a textbox (In thte future you'll also be able to use selected text)
    * **Context reverse reference**  Protext maintains a mapping from context to a list of URIs and also a reference from URIs to contexts. This allows the app to switch to the context for a specifc URI.
* **URIs** URIs are a consistent reference to a documment or app. They can be basic web URLs (https://www.google.com) or application specific deeplinks (vscode://file/~/code/protext/init.lua). URIs are aggregated into contexts
    * **Extraced URIs** Protext will attempt to extract the URI of the current window. This only works for apps that support app specific deep linking and that the need data is erxtactable
    * **URI from Clipboard** Many apps support app specific deep linking, but its difficult for Protext to build those links. In this case you can use the App supplied "copy link" feature. Protext can read that link from the clipboard.
    

## How to use Protext
### Creating Contexts
Contexts can be created in two different ways. *Note* this section references hotkeynammes demo'd at the bottomm of this doc
1. `context_from_window` This hotkey will examine the currentt window you are using and attempt to extract a context string from it. If the app is support it will create a new context AND add the current URI to the new context. If the current app URI already exists, Protext will switch to that context instead of creating a new context
1. `context_from_text_input` This hotkey will bring up a new dialog box that allows you to enter a new context. It will not add anything to this new conetxt.

### Navigating Contexts
You can navigate between contexts in a few differentt ways. The name of the context will be shown in the menubar. 

1. `previous_context` and `next_context` These hotkeys will allow you to navigate quickly around the ten most recently used contexts.
1. `context_from_window` This hotkey will, if possible, lookup the current app URI. If this URI is associated with an existing context, then Protext will switch to that context, otherwise it will createt a new context.
1. `context_from_clipboard` This hotkey will use a URI from the clipboard. It will attempt to lookup the context associated with this URI. If a context exists, Protext will switch to that URI, otherwise it will do nothing.

### Adding to Contexts
1. `add_from_window` This hotkey will, if possible, lookup the current app URI. If it is possible to extract the URI it will be added to the current contextt
1. `add_from_clipboard` This hotkey will examine the clipboard, if it is a URI, it will be added to the current context.

### Menubar 
Protext adds an entry to the Mac menubar. The text of the menu will be the current context.
Each recent context (up to 10) will have an entry in this menu. 
1. `Open All` will open every URI for this context
1. `Remove` will remove the context from the recent context list and fromm the menu.
1. All other entries are invidual URIs that will open when clicked

## How to Install

### Install Hammerspoon
https://www.hammerspoon.org/

### Import this Spoon
1. Download contents of this repo into `~/.hammerspoon/Spoons/protext`
1. Import and configure this spoon in `~/.hammerspoon/init.lua`

My config looks like
```
hs.loadSpoon("protext")
spoon.protext:bindHotkeys({
    add_from_window          = {{"cmd", "alt", "ctrl"}, "/"},
    add_from_clipboard       = {{"cmd", "alt", "ctrl"}, "."},
    context_from_window      = {{"cmd", "alt", "ctrl"}, "'"},
    context_from_clipboard   = {{"cmd", "alt", "ctrl"}, ";"},
    context_from_text_input  = {{"cmd", "alt", "ctrl"}, "\\"},
    previous_context         = {{"cmd", "alt", "ctrl"}, "["},
    next_context             = {{"cmd", "alt", "ctrl"}, "]"},

})
spoon.protext:start()

```

## Future Features
1. Use Selected Text for context when create new context
1. Support Omnifocus?
1. Support Firefox?
1. Support item2?
1. Better management of state history
