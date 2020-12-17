# Protext
##Problem
With Protext I am trying to solve a problemm of multi tasking. Throughout a normal day, I am often working on multiple tasks or projects of various scope. Some of these tasks are long lived, but vast majority are on the scale of 3 hours to three days. For any size task I probably have many web tabs open and likely a code editor or terminal. Because many of these tasks are done in parallel I frequently end up in a state where I have a bunch of task relevant tabs open for several days. I don't want to close the tabs, because the task isn't done yet and I don't really want to bookmark them, because they won't be relevant once the task is done. Over the course of a week this can proliferate to a state where I have 10 wiindows with 30 tabs a piece. At this point I often declare bankruptcy and just close everything and start from scratch with the hopes that my recent browser history will save me.

Protext attempts to solve this by introducing the concept of *contexts* which are a tool for aggregating application links. Protext assumes that, at any given moment, you are working on specific task with an assoicated *context*. As you are working and opening webpages or applications you can add them to the current context with a simple keypress. 

## Concepts

*Contexts*: Contexts are the main abstraction in Protext. They can be thoguht of as a topic under which you aggregate URIs. They are just simple text strings. 
*URIs*: URIs are a consistent reference to a documment or app. They can be basic web URLs (https://www.google.com) or application specific deeplinks (vscode://file/~/code/protext/init.lua). URIs are aggregated into contexts

## How to use Protext



##
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
