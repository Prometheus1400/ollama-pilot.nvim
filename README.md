# ollama-pilot.nvim

### LLM Integration into Neovim with 0 of the privacy concerns.
#### Supports 3 main features currently:
1. Ollama explain: the ability to have ollama explain a visually selected chunk of code to you.
2. Autocomplete: this is very primitive as Ollama only has the context of your file to work with (local models have small contexts). This gets triggered when you pause in insert mode.
3. Chat: opens up a chat window where you can talk to the model (and easily yank text from its output) this does not have a memory of the conversation yet.

### Installation
Install like you usually would with your favorite package manager. Example using Packer.
```
use "prometheus1400/ollama-pilot.nvim"
```
And setup by doing
```
require("ollama-pilot").setup({})
```

### Configuration
This is the default config that you can override in setup.
```
{
    model = "llama3",
    token_delay = 50,
    ollama_port = "11434",
    ollama_path = nil,
    ollama_lazy_startup = false,
    popup = {
        relative = 'cursor',
        row = 1,
        col = 0,
        width = 120,
        height = 20,
        style = 'minimal',
    },
    chat = {
    },
    autocomplete = {
        -- how many lines to grab above AND below the current position to add as context to autocomplete request
        context_line_size = 100,
    }
}
```

### Commands
Built-in commands:
* OllamaStart
* OllamaStop

API that you can map/remap
* explain_selection()
* chat()
accessible via 
```
require("ollama-pilot.api")
```

By default the `explain_selection()` command is mapped to `<leader>oe` for visual mode
