vim9script

export def OpenChat()
    if g:llm_chat_split == 'vertical'
        vsplit
    else
        split
    endif
    wincmd w
    enew
    setlocal buftype=nofile
    setlocal bufhidden=hide
    setlocal noswapfile
    setlocal filetype=llm_chat
    setlocal nonumber
    setlocal norelativenumber
    setlocal wrap
    setlocal linebreak
    execute 'setlocal winwidth=' .. g:llm_chat_width
    AppendMessage('system', 'Bonjour')
enddef


export def SendMessage()
    # Récupérer le dernier message de l'utilisateur
    var user_message = join(getline(1, '$'), '\n')
    if empty(user_message)
        echohl ErrorMsg | echo "Aucun message à envoyer." | echohl None
        return
    endif

    # Ajouter à l'historique
    g:llm_chat_history += [{role: 'user', content: user_message}]

    # Envoyer au LLM
    var response = CallLLM(g:llm_chat_history)

    # Afficher la réponse
    AppendMessage('assistant', response)

    # Ajouter la réponse à l'historique
    g:llm_chat_history += [{role: 'assistant', content: response}]
enddef

export def IncludeBuffer()
    # Inclure le contenu du buffer courant dans le contexte
    var buffer_content = join(getline(1, '$'), '\n')
    var context_message = "Voici le contenu du buffer actuel:\n\n" .. buffer_content

    # Ajouter au contexte
    g:llm_chat_history += [{role: 'system', content: context_message}]

    echohl WarningMsg | echo "Buffer inclus dans le contexte." | echohl None
enddef

export def ApplyChanges()
    # Récupérer les dernières lignes du chat (supposées être des modifications)
    var last_lines = getline(line('$') - 10, '$')
    var changes = join(last_lines, '\n')

    # Extraire les blocs de code (ex: ```python ... ```)
    var code_blocks = matchlist(changes, '```\\w*\\n\$ .\\{-}\ $ \\n```')

    if empty(code_blocks)
        echohl ErrorMsg | echo "Aucun bloc de code détecté." | echohl None
        return
    endif

    # Appliquer les modifications au buffer courant
    var new_content = code_blocks[1]
    setline(1, split(new_content, '\n'))
    echohl WarningMsg | echo "Modifications appliquées." | echohl None
enddef

def AppendMessage(role: string, content: string)
    var lines = split(content, '\n')
    for line in lines
        append(line('$'), role == 'user' ? '👤 ' .. line : '🤖 ' .. line)
    endfor
    normal! G
enddef

def CallLLM(messages: list<dict<any>>): string
    try
        # Préparer les données
        var data = {
            model: g:llm_chat_model,
            messages: messages,
            stream: false
        }

        # Créer un fichier temporaire
        var tmpfile = tempname()
        writefile([json_encode(data)], tmpfile)

        # Construire et exécuter la commande curl
        var cmd = 'curl -s -H "Content-Type: application/json" http://localhost:11434/api/chat -d @' .. tmpfile
        var response = system(cmd)

        # Nettoyer
        delete(tmpfile)

        if empty(string(response))
            return "Erreur: Aucune réponse reçue\n"
        endif

        # Parser la réponse
        var json = json_decode(response)
        if json == v:null || !has_key(json, 'message')
            return "Erreur: Réponse invalide du serveur: " .. response
        endif

        return json.message.content
    catch /.*/
        return "Erreur technique: " .. v:exception
    endtry

    return "Out of try/catch"

enddef



