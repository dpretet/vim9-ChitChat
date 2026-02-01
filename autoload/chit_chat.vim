vim9script

#-----------------------------------------------
# Local variables for the chat buffer number
#-----------------------------------------------
var chat_bufnr = 0
var chat_history: list<dict<any>> = []
var chat_context: dict<any> = {}

#-----------------------------------------------
# Open the chat buffer and launch the discussion
#-----------------------------------------------
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

    AppendMessage('assistant', 'Hello! Hit enter to write')

    # Mapping Entrée pour ouvrir la zone de saisie
    nnoremap <buffer> <CR> <ScriptCmd>ChitChatAsk()<CR>
enddef

#-----------------------------------------------
# Toggle chat panel, open if closed, close if
# open. Handles also if the chat has never
# been opened.
#-----------------------------------------------
export def ToggleChat()
    if chat_bufnr == 0 || !bufexists(chat_bufnr)
        OpenChat()
        return
    endif

    var winnr = bufwinnr(chat_bufnr)
    # If visible, close the chat panel
    if winnr != -1
        var winid = win_getid(winnr)
        win_execute(winid, 'close')
    else
        # Else if hidden, open it
        if g:chit_chat_split == 'vertical'
            vsplit
        else
            split
        endif
        execute 'buffer ' .. chat_bufnr
    endif
enddef

#-----------------------------------------------
# Close the chat panel and delete the buffer
#-----------------------------------------------
export def CloseChat()
    if chat_bufnr != 0 && bufexists(chat_bufnr)
        execute 'bdelete! ' .. chat_bufnr
        chat_bufnr = 0
    endif
enddef


#-----------------------------------------------
# Function to call to query the model.
# Will be closed if the user hits ctrl
# ctrl-enter or escape
#-----------------------------------------------
export def Ask()

    # Create a panel to enter the user request
    botright new
    resize 5

    setlocal buftype=nofile
    setlocal bufhidden=wipe
    setlocal noswapfile
    setlocal filetype=markdown
    setlocal nonumber
    setlocal signcolumn=no

    b:StatusLineInput = ' Write your message here (Ctrl/Shift+Enter to send, Escape to cancel)'
    setlocal statusline=%!b:StatusLineInput

    # Mappings to send the request with control-enter
    nnoremap <buffer> <C-CR> <ScriptCmd>SubmitInput()<CR>
    inoremap <buffer> <C-CR> <Esc><ScriptCmd>SubmitInput()<CR>
    # Mappings to send the request with shift-enter
    nnoremap <buffer> <S-CR> <ScriptCmd>SubmitInput()<CR>
    inoremap <buffer> <S-CR> <Esc><ScriptCmd>SubmitInput()<CR>
    # Mapping to cancel the entry
    nnoremap <buffer> <Esc> <ScriptCmd>close<CR>

enddef


#---------------------------------------------------
# Add a buffer to the chat context
# If no argument or if argument is '%', the function
# loads the current buffer if is saved in a file.
#---------------------------------------------------
export def AddBuffer(target: string = '')
    var bnr: number

    # 1. Résolution de la cible (Vide, %, ou Numéro)
    if target == '' || target == '%'
        bnr = bufnr('%')
    elseif target =~ '^\d\+$' # Si l'argument ne contient que des chiffres
        bnr = str2nr(target)
    else
        echoerr "Argument invalide : " .. target .. " (attendu: vide, % ou numéro)"
        return
    endif

    # 2. Vérification que le buffer existe
    if !bufexists(bnr)
        echoerr "Le buffer numéro " .. bnr .. " n'existe pas."
        return
    endif

    # 3. Récupération du nom (indispensable pour le contexte)
    var raw_name = bufname(bnr)
    if empty(raw_name)
        echoerr "Le buffer " .. bnr .. " n'a pas de nom de fichier associé."
        return
    endif

    # 4. Chemin absolu
    var fullpath = fnamemodify(raw_name, ':p')
    AddFile(fullpath)
enddef

#-----------------------------------------------------------
# Add a file to the context
#-----------------------------------------------------------
export def AddFile(path: string)
    if empty(path)
        echoerr "Erreur : Chemin de fichier manquant."
        return
    endif

    # 1. Obtenir le chemin absolu (gère les chemins relatifs et les ~)
    var fullpath = expand(path)
    fullpath = fnamemodify(fullpath, ':p')

    # 2. Vérification sur le disque
    if !filereadable(fullpath)
        echoerr "Erreur : Impossible de lire le fichier (n'existe pas ?) : " .. fullpath
        return
    endif

    # 3. Lecture du fichier (renvoie une liste de strings)
    var content = readfile(fullpath)

    var ext = DetectFiletypeInvisible(fullpath)
    echo ext

    # 4. Stockage
    StoreContext(fullpath, content, ext)
enddef

# Détecte le filetype sans ouvrir de fenêtre visible
def DetectFiletypeInvisible(path: string): string
    var abspath = fnamemodify(path, ':p')
    var nr = bufnr(abspath)
    var exists_already = (nr != -1)

    # Si le fichier n'est pas déjà chargé dans Vim
    if !exists_already
        # 1. On crée le buffer en mode "caché"
        nr = bufadd(abspath)

        # 2. On charge le contenu (nécessaire pour les détections basées sur le contenu)
        call bufload(nr)

        # 3. On évite qu'il apparaisse dans la liste (:ls) pour ne pas polluer
        call setbufvar(nr, '&buflisted', 0)

        # 4. On force Vim à déclencher la détection de type pour ce fichier
        # On utilise 'silent!' pour éviter des messages d'erreur si le fichier est bizarre
        execute 'silent! doautocmd filetypedetect BufRead ' .. fnameescape(abspath)
    endif

    # 5. On récupère le type détecté
    var ft = getbufvar(nr, '&filetype')

    # 6. NETTOYAGE : Si on l'a ouvert nous-mêmes, on le détruit complètement
    if !exists_already
        execute 'silent! bwipeout ' .. nr
    endif

    # Fallback si Vim ne trouve rien
    if empty(ft)
        return 'text'
    endif

    return ft
enddef

#-----------------------------------------------------------
# Save a file and its content in a dict, pushed later
# in the context
#-----------------------------------------------------------
def StoreContext(path: string, content: list<string>, extension: string)
    chat_context[path] = {'content': join(content, "\n"),
                          "lang": extension
                         }
    echo "✅ Ajouté au contexte : " .. fnamemodify(path, ':t')
enddef

#----------------------------------------------------
# Print the list of files added in the context
#----------------------------------------------------
export def ShowContext()
    if empty(chat_context)
        echo "📭 Le contexte est vide."
        return
    endif

    var context = "# Files present in context: \n"
    for [path, data] in items(chat_context)
        context = context .. "- " .. path .. "\n"
    endfor
    echo context
enddef

#-----------------------------------------------------------------------
# Get the files content to add to the context when send to the model
#-----------------------------------------------------------------------
def GetContextString(): string
    if empty(chat_context)
        return ""
    endif

    for [path, content] in items(chat_context)
        var fname = fnamemodify(path, ':t') # Juste le nom du fichier
        full_text = full_text .. "--- DÉBUT FICHIER : " .. fname .. " ---\n"
        full_text = full_text .. content .. "\n"
        full_text = full_text .. "--- FIN FICHIER : " .. fname .. " ---\n\n"
    endfor

    return full_text
enddef

#-----------------------------------------------------------------------
# Wipe out the context
#-----------------------------------------------------------------------
export def ForgetAll()
    chat_context = {}
    echo "Context has been erased."
enddef

#-----------------------------------------------------------------------
# Forget a specific file
#-----------------------------------------------------------------------
export def Forget(path: string = '')
    var target: string

    # 1. Déterminer quel fichier on veut oublier
    if empty(path)
        # Si aucun argument, on prend le chemin absolu du buffer courant
        target = expand('%:p')
    else
        # Sinon, on normalise le chemin passé en argument
        target = fnamemodify(path, ':p')
    endif

    # 2. Vérifier si la clé existe dans le dictionnaire
    if has_key(chat_context, target)
        remove(chat_context, target)
        echo "🗑️ Retiré du contexte : " .. fnamemodify(target, ':t')
    else
        echo "⚠️ Ce fichier n'était pas dans le contexte : " .. fnamemodify(target, ':t')
    endif
enddef


#---------------------------------------------------
# Submit the request to the model:
# 1. Open the panel if never opened or move to
#    the panel
# 2. Add the user message in the panel
# 3. Print a sandglass while waiting a completion
# 4. Call the model
# 5. Update the chat panel with the model response
#---------------------------------------------------
def SubmitInput()
    var lines = getline(1, '$')
    var message = join(lines, "\n")

    # If no message, we just close and return.
    if trim(message) == ''
        close
        return
    endif

    # Close the window
    close

    # Open the panel if never opened
    if chat_bufnr == 0 || !bufexists(chat_bufnr)
        OpenChat()
    else
        var winnr = bufwinnr(chat_bufnr)
        # Go back to the panel
        if winnr != -1
            win_gotoid(win_getid(winnr))
        # Open the panel if closed
        else
            OpenChat()
        endif
    endif

    # 1. Append the user request and build the context
    AppendMessage('user', message)
    chat_history += [{role: 'user', content: message}]
    var system_content = BuildContext()
    redraw

    # 2. Add a temporary sandglass to the chat panel
    var num_lines = AppendMessage('assistant', '⏳ ...')
    redraw

    # 3. Call the model and wait for the completion
    var response = CallModel(chat_history, system_content)

    # 4. Delete the last lines, the ones displaying the sandglass
    for _ in range(num_lines)
        var loading_line = line('$')
        deletebufline(chat_bufnr, loading_line)
    endfor

    # 5. Append the model response to the chat panel
    AppendMessage('assistant', response)
    chat_history += [{role: 'assistant', content: response}]
enddef


#---------------------------------------------------
# Append a message to the chat panel, prepending
# timestang and the role printing
# @Returns the number of lines happened, after the
# timestamp line
#---------------------------------------------------
def AppendMessage(role: string, content: string): number

    # Be sure the chanel buffer exists to avoid crashing
    if !bufexists(chat_bufnr)
        return 0
    endif

    var timestamp = strftime("%H:%M")
    var prefix = ''

    if role == 'user'
        prefix = '👤 You'
    else
        prefix = '💬 LLM'
    endif

    # Build a list of strings for each line to print
    var lines_to_add = []
    add(lines_to_add, '') # new line
    add(lines_to_add, printf(' [%s] %s', timestamp, prefix))
    add(lines_to_add, '') # new line

    for l in split(content, '\n')
        add(lines_to_add, printf(' %s', l))
    endfor

    # Append all lines to the chat buffer
    appendbufline(chat_bufnr, '$', lines_to_add)

    # Move to the bottom of the chat buffer
    var winnr = bufwinnr(chat_bufnr)
    if winnr != -1
        var winid = win_getid(winnr)
        win_execute(winid, 'normal! G')
    endif

    # Returns the number of lines
    return len(lines_to_add)
enddef

#---------------------------------------------------
# Build the message sent to the model
#---------------------------------------------------
def BuildContext(): list<dict<any>>

    var msg = ""
    var ctx: list<dict<any>> = []

    if !empty(g:chit_chat_agent)
        msg = msg .. "# Your Role\n"
        msg = msg .. g:chit_chat_agent
        msg = msg .. "\n"
    endif

    if !empty(chat_context)

        msg = msg .. "# Context File\n"
        msg = msg .. "Use the following files as context to answer the user request,\n"
        msg = msg .. "enclosed in code block with the appropriate file type\n\n"

        for [path, data] in items(chat_context)
            var filename = fnamemodify(path, ':t')
            var lang = data['lang']

            msg = msg .. "## " .. filename .. "\n"
            msg = msg .. "```" .. lang .. "\n"
            msg = msg .. data['content']
            msg = msg .. "```" .. "\n\n"

        endfor
    endif

    add(ctx, { 'role': 'system', 'content': msg })
    return ctx

enddef

#---------------------------------------------------
# Call the model wait for the completion
# @Returns the completion in Json formatting
#---------------------------------------------------
def CallModel(messages: list<dict<any>>, system: list<dict<any>>): string
    try
        var data = {
            model: g:chit_chat_model,
            messages: messages,
            system: system,
            temperature: g:chit_chat_temperature,
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

