# Architecture

## UI

✅ Input prompt is diplayed in a dedicated buffer

✅ Separation between the input prompt and the discussion
   is horizontally

✅ A prompt entry sent to the model and completed is displayed
   into the discussion panel

✅ The UI indicates the model is completing a request

- Different styles can be selected to render the conversation

## UX

✅ The interface is organized as a chat
    - a place is reserved for the query sent and the model answer
    - a place is reserved for the prompt to write

✅ The UI indicates the model is completing a request

- A request can be cancelled by ctrl-c

✅ A function is responsible to send a message to the model

✅ This function can be associated to a mapping, like shift-<CR>

- The user can mention a buffer to load to the model with a
  syntax like "/buffer 0" or /buffer program.py"

- The user can mention a file to load to the model with a
  syntax like "/read ./a\_file/to\_read.md"

- The user can select a buffer portion and call the LLM.
    - The selected buffer portion will be included in the
      prompt entry
    - The buffer type will be used to qualify the text with the right lang
    - The code included will be highlighted in the prompt as a regular
      code source in a buffer

- The plugin can access the file system

- The plugin can execute some actions
    - vim built-in command
    - vim functions
    - shell command

✅ The user can configure the plugin in a vim9 script

- The user can list the chat history

- The user can erase a previous chat history

- The user can reload a previous chat history

- The chat histories are stored in a folder. By default, the folder
  is "~/.llm\_chat"

- The user can enable or disable automatic chat storage



## Configuration

✅ The user can configure the plugin in a vim9 script, either his
  vimrc or a separated script file.

✅ Several variables will be exposed by the plugin

- The model engine can be configured with:
    ✅ the model name to use
    - the REST server address/port
    - a default agent prompt tuning
    - the context length

- The UI layout can be configured to be:
    ✅ splitted hoizontally or vertically
    - render the conversation with different styles

✅ The mapping of the plugin functions can be setup. 

✅ A default mapping is proposed if a variable is set ("default\_mapping")

- The user can configure the chat history
    - He can configure where the chat history is stored
    - He can enable or disable the chat history storage
    - The chat history storage is disabled by default

✅  If the variables are not overriden, the plugin will proposed defaults

## User Function

### ChitChatOpen()

Open the ChitChat buffer.
If it's loaded for the first time, propose to select an agent if some are setup
If loaded from history, restore the conversation selected
If a conversation is loaded, displays the hidden Chitchat buffer

### ChitChatClose()

Hide the Chitchat buffer but not the conversation.

### ChitChatToggle()

If the Chitchat buffer is opened, call ChitChatClose(), else call ChitChatOpen()

### ChitChatExit()

Call ChitChatClose()
If history is configured, save the conversation.

### ChitChatHistory()

Displays the chat history and propose to the user to recall one conversation
Setup internal conversation variable
Call ChitChatOpen()

### ChitChatAsk()

Open a popup to let user fill a query to the model
Call internals to update the conversation, render the ChitChat buffer and query the
model API


