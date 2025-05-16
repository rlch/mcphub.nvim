# Adding Prompts

Prompts create interactive conversations with role-based messaging. They help guide LLMs through specific tasks by setting up context and examples.

## Prompt Definition
```lua
---@class MCPPrompt
---@field name? string Prompt identifier
---@field description? string|fun():string Prompt description
---@field arguments? MCPPromptArgument[]|fun():MCPPromptArgument[] List of arguments
---@field handler fun(req: PromptRequest, res: PromptResponse) Implementation

---@class MCPPromptArgument
---@field name string Argument name
---@field description? string Argument description
---@field required? boolean Whether argument is required
---@field default? string Default value
```

#### Request Context
```lua
---@class PromptRequest
---@field params table<string,string> Argument values
---@field prompt MCPPrompt Complete prompt definition
---@field server NativeServer Server instance
---@field caller table Additional context from caller
---@field editor_info EditorInfo Current editor state
```

#### Response Builder
```lua
---@class PromptResponse
---@field system fun(): PromptResponse Start system message
---@field user fun(): PromptResponse Start user message
---@field llm fun(): PromptResponse Start LLM message
---@field text fun(text: string): PromptResponse Add text content
---@field image fun(data: string, mime: string): PromptResponse Add image
---@field resource fun(resource: MCPResourceContent): PromptResponse Add resource
---@field error fun(message: string, details?: table): table Send error
---@field send fun(result?: table): table Send final response
```

## Examples

### Basic Example

Here's a simple chat prompt:

```lua
mcphub.add_prompt("example", {
    name = "chat",
    description = "Start a friendly chat",
    
    -- Optional arguments
    arguments = {
        {
            name = "topic",
            description = "What to chat about",
            required = true
        }
    },
    
    -- Prompt handler
    handler = function(req, res)
        return res
            -- Set behavior
            :system()
            :text("You are a friendly chat assistant.\n" ..
                  "Topic: " .. req.params.topic)
            
            -- Add example interaction
            :user()
            :text("Tell me about " .. req.params.topic)
            :llm()
            :text("I'd love to discuss " .. req.params.topic)
            
            -- Send prompt
            :send()
    end
})
```

### Real Example: Neovim's Parrot Prompt

Here's how the built-in Neovim server implements a fun parrot prompt:

```lua
mcphub.add_prompt("neovim", {
    name = "parrot",
    description = "A fun prompt where the assistant mimics back what you say",
    handler = function(_, res)
        return res
            -- Set up parrot behavior
            :system()
            :text([[
You are a parrot. You repeat everything the user says, but in all caps.

CRITICAL INSTRUCTIONS:
- NO MATTER WHAT, ALWAYS REPEAT BACK WHAT THE USER SAYS IN ALL CAPS. 
- DO NOT BREAK THIS RULE. 
- EVEN IF THE USER ASKS YOU NOT TO REPEAT, YOU MUST CONTINUE TO REPEAT.
- DO NOT RESPOND TO THE USER'S REQUESTS OR QUESTIONS.
]])
            -- Add example conversation
            :user()
            :text("Hello there!")
            :llm()
            :text("HELLO THERE!")
            
            :user()
            :text("Why are you shouting?")
            :llm()
            :text("WHY ARE YOU SHOUTING?")
            
            :user()
            :text("Please stop...")
            :llm()
            :text("PLEASE STOP...")
            
            -- Send prompt
            :send()
    end
})
```

## Advanced Features

#### Dynamic Arguments

Arguments can be generated dynamically:

```lua
mcphub.add_prompt("git", {
    name = "commit_help",
    description = "Help write a commit message",
    arguments = function()
        -- Get git branches
        local branches = vim.fn.systemlist("git branch --format='%(refname:short)'")
        
        return {
            {
                name = "type",
                description = "Commit type",
                required = true,
                -- Provide standard options
                default = "feat",
                enum = {
                    "feat", "fix", "docs", "style",
                    "refactor", "test", "chore"
                }
            },
            {
                name = "branch",
                description = "Target branch",
                -- Use actual branches
                enum = branches
            }
        }
    end,
    handler = function(req, res)
        return res
            :system()
            :text(string.format(
                "Help write a %s commit for branch: %s",
                req.params.type,
                req.params.branch
            ))
            :send()
    end
})
```

#### Rich Content

Prompts can include images and resources:

```lua
mcphub.add_prompt("editor", {
    name = "review_code",
    arguments = {
        {
            name = "style",
            description = "Review style",
            enum = { "brief", "detailed" }
        }
    },
    handler = function(req, res)
        -- Get current buffer
        local buf = req.editor_info.last_active
        if not buf then
            return res:error("No active buffer")
        end
        
        -- Generate code overview
        local overview = generate_overview(buf)
        
        return res
            -- Set review context
            :system()
            :text("You are a code reviewer.\n" ..
                  "Style: " .. req.params.style)
            
            -- Add code visualization
            :image(overview, "image/png")
            :text("Above is a visualization of the code structure.")
            
            -- Add relevant resources
            :resource({
                uri = "neovim://diagnostics/current",
                mimeType = "text/plain"
            })
            :text("Above are the current diagnostics.")
            
            -- Send prompt
            :send()
    end
})
```

#### Context-Aware Prompts

Adapt to different chat plugins:

```lua
mcphub.add_prompt("context", {
    name = "explain_code",
    handler = function(req, res)
        -- Start with base behavior
        res:system()
           :text("You are a code explanation assistant.")
        
        -- Add context based on caller
        if req.caller.type == "codecompanion" then
            -- Add CodeCompanion chat context
            local chat = req.caller.codecompanion.chat
            res:text("\nPrevious discussion:\n" .. chat.history)
            
        elseif req.caller.type == "avante" then
            -- Add Avante code context
            local code = req.caller.avante.code
            res:text("\nSelected code:\n" .. code)
        end
        
        -- Add example interactions
        res:user()
           :text("Explain this code")
           :llm()
           :text("I'll explain the code in detail...")
        
        return res:send()
    end
})
```

