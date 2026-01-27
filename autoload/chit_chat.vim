vim9script

# Configuration par défaut
if !exists('g:chit_chat_history')
    g:chit_chat_history = []
endif
if !exists('g:chit_chat_model')
    g:chit_chat_model = 'ministral-3b'
endif
if !exists('g:chit_chat_width')
    g:chit_chat_width = 50
endif
if !exists('g:chit_chat_split')
    g:chit_chat_split = 'vertical'
endif

# Variable locale
var chat_bufnr = 0

export def OpenChat()
    if chat_bufnr != 0 && bufexists(chat_bufnr)
        ToggleChat()
        return
    endif

    if g:chit_chat_split == 'vertical'
        vsplit
    else
        split
    endif
    wincmd w
    enew

    setlocal buftype=nofile
    setlocal bufhidden=hide
    setlocal noswapfile
    setlocal filetype=chit_chat
    setlocal nonumber
    setlocal norelativenumber
    setlocal wrap
    setlocal linebreak

    if g:chit_chat_split == 'vertical'
        execute 'vertical resize ' .. g:chit_chat_width
    endif

    chat_bufnr = bufnr('')

    AppendMessage('system', 'Chat initialisé. Appuyez sur <Entrée> pour écrire.')

    # Mapping Entrée pour ouvrir la zone de saisie
    nnoremap <buffer> <CR> <ScriptCmd>ChitChatAsk()<CR>
enddef

export def ToggleChat()
    if chat_bufnr == 0 || !bufexists(chat_bufnr)
        OpenChat()
        return
    endif

    var winnr = bufwinnr(chat_bufnr)
    if winnr != -1
        # Si visible, on ferme la fenêtre en utilisant son ID (plus sûr que execute)
        var winid = win_getid(winnr)
        win_execute(winid, 'close')
    else
        # Si caché, on réouvre
        if g:chit_chat_split == 'vertical'
            vsplit
        else
            split
        endif
        execute 'buffer ' .. chat_bufnr
    endif
enddef

export def CloseChat()
    if chat_bufnr != 0 && bufexists(chat_bufnr)
        execute 'bdelete! ' .. chat_bufnr
        chat_bufnr = 0
    endif
enddef

################################################################################
# Gestion de la saisie (Input)
################################################################################

export def ChitChatAsk()
    # Création du split en deux temps pour éviter les erreurs de range
    botright new
    resize 5

    setlocal buftype=nofile
    setlocal bufhidden=wipe
    setlocal noswapfile
    setlocal filetype=markdown
    setlocal nonumber
    setlocal signcolumn=no

    b:StatusLineInput = ' ✍️  Ecrivez votre message (Ctrl+Entrée pour envoyer, Echap pour annuler)'
    setlocal statusline=%!b:StatusLineInput

    # Mappings
    nnoremap <buffer> <C-CR> <ScriptCmd>SubmitInput()<CR>
    inoremap <buffer> <C-CR> <Esc><ScriptCmd>SubmitInput()<CR>
    nnoremap <buffer> <Esc> <ScriptCmd>close<CR>

    startinsert
enddef

def SubmitInput()
    var lines = getline(1, '$')
    var message = join(lines, "\n")

    # Si le message est vide, on ferme juste
    if trim(message) == ''
        close
        return
    endif

    # Fermer la fenêtre de saisie
    close

    # Retourner au buffer de chat de manière sécurisée
    if chat_bufnr == 0 || !bufexists(chat_bufnr)
        OpenChat()
    else
        var winnr = bufwinnr(chat_bufnr)
        if winnr != -1
            # CORRECTION : Utilisation de win_gotoid au lieu de execute wincmd
            win_gotoid(win_getid(winnr))
        else
            OpenChat()
        endif
    endif

    # 1. Affichage User
    AppendMessage('user', message)
    g:chit_chat_history += [{role: 'user', content: message}]
    redraw

    # 2. Appel LLM
    AppendMessage('system', '⏳ ...')
    var loading_line = line('$')
    redraw

    var response = CallLLM(g:chit_chat_history)

    # Suppression message d'attente
    # On utilise deletebufline pour être sûr de cibler le bon buffer sans erreur de contexte
    deletebufline(chat_bufnr, loading_line)

    # 3. Affichage Réponse
    AppendMessage('assistant', response)
    g:chit_chat_history += [{role: 'assistant', content: response}]
enddef

################################################################################
# Utils
################################################################################

def AppendMessage(role: string, content: string)
    # Vérification de sécurité
    if !bufexists(chat_bufnr)
        return
    endif

    var timestamp = strftime("%H:%M")
    var prefix = ''
    var bubble_char = ''

    if role == 'user'
        prefix = '👤 Vous'
        bubble_char = '›'
    elseif role == 'assistant'
        prefix = '🤖 Assistant'
        bubble_char = '»'
    else
        prefix = '⚙️ Système'
        bubble_char = '#'
    endif

    # On prépare les lignes à ajouter
    var lines_to_add = []
    add(lines_to_add, '') # Saut de ligne
    add(lines_to_add, printf(' [%s] %s', timestamp, prefix))

    for l in split(content, '\n')
        add(lines_to_add, printf(' %s %s', bubble_char, l))
    endfor

    # appendbufline fonctionne même si on n'est pas dans la fenêtre active
    appendbufline(chat_bufnr, '$', lines_to_add)

    # Scroll automatique si la fenêtre est visible
    var winnr = bufwinnr(chat_bufnr)
    if winnr != -1
        var winid = win_getid(winnr)
        win_execute(winid, 'normal! G')
    endif
enddef

def CallLLM(messages: list<dict<any>>): string
    try
        var data = {
            model: g:chit_chat_model,
            messages: messages,
            stream: false
        }

        var tmpfile = tempname()
        writefile([json_encode(data)], tmpfile)

        var cmd = 'curl -s -H "Content-Type: application/json" http://localhost:11434/api/chat -d @' .. tmpfile
        var response = system(cmd)
        delete(tmpfile)

        if empty(response)
            return "Erreur: Aucune réponse."
        endif

        var json = json_decode(response)

        if type(json) != v:t_dict || !has_key(json, 'message')
            return "Erreur API: " .. response
        endif

        return json.message.content
    catch
        return "Exception: " .. v:exception
    endtry
enddef


