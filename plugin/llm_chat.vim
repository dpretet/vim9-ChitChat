vim9script

# Configuration par défaut
g:llm_chat_model = 'ministral-3:3b'
g:llm_chat_split = 'vertical'
g:llm_chat_width = 50
g:llm_chat_history = []


# Commandes utilisateur
command LLMChatOpen call llm_chat#OpenChat()
command LLMChatSend call llm_chat#SendMessage()
command LLMChatIncludeBuffer call llm_chat#IncludeBuffer()
command LLMChatApplyChanges call llm_chat#ApplyChanges()

