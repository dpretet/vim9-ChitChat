# vim9-ChitChat

ChitChat is a lightweight Vim9 plugin that brings a chat interface directly into your editor. It is
designed to work seamlessly with local LLMs running via Ollama.
Conversations happen in a dedicated buffer, keeping your workflow uninterrupted and your data private.

<p align="center">
  <img width="300" height="300" src="./doc/screenshot.jpg">
</p>

## ✨ Features

- 100% Local: Designed for Ollama. No API keys sent to the cloud.
- Vim-Native: Uses Vim buffers and windows. No external Python or Node.js dependencies (just curl).
- Distraction-Free: Simple "Chat" and "Input" split view.
- Context-Aware: (Optional) Can read your current buffer context or a file.

## 📋 Prerequisites

1. **Vim 9.0+** (Required for Vim9 script support).
2. **[Ollama](https://ollama.com/)** installed and running.
3. **curl** command available in your path.

## 📦 Installation

Using vim-plug:

```vim
Plug 'dpretet/vim9-ChitChat'
```

or any other plugin manager

## ⚙️  Configuration

Add these variables to your .vimrc to configure the connection to Ollama.

```vim
" Default model to use (must be pulled in Ollama)
g:chitchat_model = 'qwen2.5-coder:3b'

" Model creativity:
" - 0.2: very deterministic, good for coding
" - 0.7: standard / conversation
" - 1: brainstorming, creativity
g:chit_chat_temperature = 0.2

" Ollama API endpoint (default is usually correct)
g:chitchat_url = 'http://localhost:11434/api/chat'

" API key if use a web service like OpenAI, Anthropic, Grok...
g:chit_chat_api_key = ''
```

## 🚀 Usage

1. Open any file in Vim.
2. Run the command to open the chat interface:

```vim
:ChitChatAsk
```
3. Type your query in the bottom panel and use `shift+return` or `ctrl+return`

Files can be added in the convesration context:

```vim
ChitChatAddFile ./my/source.c
```

Buffers can also be added:

```vim
ChitChatAddBuffer       # Add current buffer
ChitChatAddBuffer %     # Add current buffer
ChitChatAddBuffer 5     # Add buffer 5
```

Context can be viewed:

```vim
ChitChatShowContext
```

And context can be clean-up:

```vim
ChitChatForget ./my/source.c
ChitChatForgetAll
```

ChitChat conversation buffer can be opened, closed, toggled and be quit:

```vim
ChitChatOpen
ChitChatClose
ChitChatToggle
ChitChatExit
```

### Key Mappings (Input Window)

| Mapping | Action |
| :--- | :--- |
| **`Shift + Enter`** | **Send message** |
| **`Ctrl + Enter`** | **Send message** (Alternative) |
| **`Esc`** | Close the input window |


## 🛠️ Troubleshooting

Nothing happens when I press Shift+Enter?

Make sure Ollama is running (ollama serve in a terminal).
Verify you have pulled the model defined in your config (e.g., ollama pull mistral).
Some terminals do not distinguish Shift+Enter from Enter. Try using Ctrl+Enter instead.

## 📜 License

MIT license
