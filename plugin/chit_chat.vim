vim9script

# Configuration par défaut
# g:chit_chat_model = 'ministral-3:3b'
g:chit_chat_model = 'qwen2.5-coder:3b'
g:chit_chat_split = 'vertical'
g:chit_chat_width = 50
g:chit_chat_history = []


# Commandes utilisateur
command ChitChatOpen call chit_chat#OpenChat()
command ChitChatToggle call chit_chat#ToggleChat()
command ChitChatClose call chit_chat#CloseChat()
command ChitChatAsk call chit_chat#ChitChatAsk()

