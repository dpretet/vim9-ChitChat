vim9script

# Default configurations
if !exists('g:chit_chat_model')
    g:chit_chat_model = 'qwen2.5-coder:3b' # 'ministral-3:3b'
endif
if !exists('g:chit_chat_width')
    g:chit_chat_width = 50
endif
if !exists('g:chit_chat_split')
    g:chit_chat_split = 'vertical'
endif

if !exists('g:chit_chat_agent')
    g:chit_chat_agent = ''
endif

if !exists('g:chit_chat_temperature')
    g:chit_chat_temperature = 0.2 # deterministic
    # g:chit_chat_temperature = 0.7 # standard / chat
    # g:chit_chat_temperature = 1.0 # brainstorming
endif

if !exists('g:chit_chat_url')
    # ollama URL
    g:chit_chat_api_url = 'http://localhost:11434/v1/chat/completions'
endif

if !exists('g:chit_chat_api_key')
    # Ollama n'a pas besoin de clé, mais on met une string vide ou 'ollama'
    g:chit_chat_api_key = 'ollama'
endif

# User Commands
command ChitChatOpen call chit_chat#OpenChat()
command ChitChatToggle call chit_chat#ToggleChat()
command ChitChatClose call chit_chat#CloseChat()
command ChitChatAsk call chit_chat#Ask()
command! -nargs=? ChitChatAddBuffer call chit_chat#AddBuffer(<f-args>)
command! -nargs=1 -complete=file ChitChatAddFile call chit_chat#AddFile(<f-args>)
command ChitChatShowContext call chit_chat#ShowContext()
command! -nargs=? -complete=file ChitChatForget call chit_chat#Forget(<f-args>)
command ChitChatForgetAll call chit_chat#ForgetAll()

