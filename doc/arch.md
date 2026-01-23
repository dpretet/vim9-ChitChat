# Architecture

## UI

- Can be:
    - In a dedicated buffer
    - In a floating window

- Separation between the input prompt and the discussion
  can be separated horizontally or vertically

- A prompt entry sent to the model and completed is displayed
  into the discussion panel

- The UI indicates the model is completing a request

## UX

- The interface is organized as a chat
    - a place is reserved for the query sent and the model answer
    - a place is reserved for the prompt to write

- The UI indicates the model is completing a request

- A request can be cancelled by ctrl-c

- A function is responsible to send a message to the model

- This function can be associated to a mapping, like shift-<CR>

- The user can mention a buffer to load to the model with a 
  syntax like "/buffer 0"

- The user can mention a file to load to the model with a 
  syntax like "/read ./a\_file/to\_read.md"
  - the user could also be interrested to mention a chapter number

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

- The user can configure the plugin in a vim9 script

- The user can list the chat history

- The user can erase a previous chat history

- The user can reload a previous chat history

- The chat histories are stored in a folder. By default, the folder
  is "~/.llm\_chat"

- The user can enable or disable automatic chat storage



## Configuration

- The user can configure the plugin in a vim9 script, either his 
  vimrc or a separated script file.

- Several variables will be exposed by the plugin

- If the variables are not overriden, the plugin will proposed defaults

- The model engine can be configured with:
    - the model name to use
    - the REST server address/port
    - a default agent prompt tuning

- The UI layout can be configured to be:
    - hoizontally or vertically splitted
    - embedded in a popup or a regular buffer

- The mapping of the plugin functions can be setup. A default mapping 
  is proposed if a variable is setup ("default\_mapping")

- The user can configure the chat history
    - He can configure where the chat history is stored
    - He can enable or disable the chat history storage
    - The chat history storage is disabled by default

