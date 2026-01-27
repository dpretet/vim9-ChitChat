vim9script

#-----------------------------------------------
# Default configuration
#-----------------------------------------------
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

#-----------------------------------------------
# Local variable for the chat buffer number
#-----------------------------------------------
var chat_bufnr = 0

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
export def ChitChatAsk()

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

    # 1. Append the user request
    AppendMessage('user', message)
    g:chit_chat_history += [{role: 'user', content: message}]
    redraw

    # 2. Add a temporary sandglass to the chat panel
    var num_lines = AppendMessage('assistant', '⏳ ...')
    redraw

    # 3. Call the model and wait for the completion
    var response = CallModel(g:chit_chat_history)

    # 4. Delete the last lines, the ones displaying the sandglass
    for _ in range(num_lines)
        var loading_line = line('$')
        deletebufline(chat_bufnr, loading_line)
    endfor

    # 5. Append the model response to the chat panel
    AppendMessage('assistant', response)
    g:chit_chat_history += [{role: 'assistant', content: response}]
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
# Call the model wait for the completion
# @Returns the completion in Json formatting
#---------------------------------------------------
def CallModel(messages: list<dict<any>>): string
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


