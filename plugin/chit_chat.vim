vim9script

# Default configuration
g:chit_chat_model = 'qwen2.5-coder:3b' # 'ministral-3:3b'
g:chit_chat_split = 'vertical'
g:chit_chat_width = 50

# Uesr Command
command ChitChatOpen call chit_chat#OpenChat()
command ChitChatToggle call chit_chat#ToggleChat()
command ChitChatClose call chit_chat#CloseChat()
command ChitChatAsk call chit_chat#Ask()
command! -nargs=? ChitChatAddBuffer call chit_chat#AddBuffer(<f-args>)
command! -nargs=1 -complete=file ChitChatAddFile call chit_chat#AddFile(<f-args>)
command ChitChatShowContext call chit_chat#ShowContext()
command! -nargs=? -complete=file ChitChatForget call chit_chat#Forget(<f-args>)
command ChitChatForgetAll call chit_chat#ForgetAll()

