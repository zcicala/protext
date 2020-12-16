# protext

My config looks like
```
hs.loadSpoon("protext")
spoon.protext:bindHotkeys({
    add_from_window          = {{"cmd", "alt", "ctrl"}, "/"},
    add_from_clipboard       = {{"cmd", "alt", "ctrl"}, "."},
    context_from_window      = {{"cmd", "alt", "ctrl"}, "'"},
    context_from_text_input  = {{"cmd", "alt", "ctrl"}, ";"},
    previous_context         = {{"cmd", "alt", "ctrl"}, "["},
    next_context             = {{"cmd", "alt", "ctrl"}, "]"},

})
spoon.protext:start()
```
