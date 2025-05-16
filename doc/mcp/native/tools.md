# Adding Tools

Tools are functions that LLMs can call with specific parameters. This guide covers how to implement tools with proper typing and best practices.

## Tool Definition

```lua
---@class MCPTool
---@field name string Required: Tool identifier
---@field description string|fun():string Optional: Tool description
---@field inputSchema? table|fun():table Optional: JSON Schema for validation
---@field handler fun(req: ToolRequest, res: ToolResponse): nil|table Required: Implementation
```

#### Request Context

Tool handlers receive a request object with:

```lua
---@class ToolRequest
---@field params table Tool arguments (validated against inputSchema)
---@field tool MCPTool Complete tool definition
---@field server NativeServer Server instance
---@field caller table Additional context from caller
---@field editor_info EditorInfo Current editor state
```

#### Response Builder

Tool handlers use a chainable response builder:

```lua
---@class ToolResponse
---@field text fun(text: string): ToolResponse Add text content
---@field image fun(data: string, mime: string): ToolResponse Add image
---@field audio fun(data: string, mime: string): ToolResponse Add audio
---@field resource fun(resource: MCPResourceContent): ToolResponse Add resource
---@field error fun(message: string, details?: table): table Send error
---@field send fun(result?: table): table Send final response
```

## Examples

### Basic Example

Here's a simple greeting tool:

```lua
mcphub.add_tool("example", {
    name = "greet",
    description = "Greet a user",
    inputSchema = {
        type = "object",
        properties = {
            name = {
                type = "string",
                description = "Name to greet"
            }
        },
        required = { "name" }
    },
    handler = function(req, res)
        return res:text("Hello " .. req.params.name):send()
    end
})
```

### Real Example: File Reading

Here's how the built-in Neovim server implements file reading:

```lua
mcphub.add_tool("neovim", {
    name = "read_file",
    description = "Read contents of a file",
    inputSchema = {
        type = "object",
        properties = {
            path = {
                type = "string",
                description = "Path to the file to read",
            },
            start_line = {
                type = "number",
                description = "Start reading from this line (1-based)",
                default = 1
            },
            end_line = {
                type = "number",
                description = "Read until this line (inclusive)",
                default = -1
            }
        },
        required = { "path" }
    },
    handler = function(req, res)
        local params = req.params
        local p = Path:new(params.path)
        
        -- Validate file exists
        if not p:exists() then
            return res:error("File not found: " .. params.path)
        end

        -- Handle line range reading
        if params.start_line and params.end_line then
            local extracted = {}
            local current_line = 0
            
            for line in p:iter() do
                current_line = current_line + 1
                if current_line >= params.start_line 
                and (params.end_line == -1 or current_line <= params.end_line) then
                    table.insert(extracted, 
                        string.format("%4d │ %s", current_line, line))
                end
                if params.end_line ~= -1 and current_line > params.end_line then
                    break
                end
            end
            return res:text(table.concat(extracted, "\n")):send()
        end

        -- Read entire file
        return res:text(p:read()):send()
    end
})
```

## Advanced Features

#### Dynamic Descriptions

Descriptions can be functions for dynamic content:

```lua
mcphub.add_tool("files", {
    name = "search",
    description = function()
        local count = #vim.api.nvim_list_bufs()
        return string.format("Search %d open buffers", count)
    end,
    handler = function(req, res)
        -- Implementation
    end
})
```

#### Dynamic Schemas

Input schemas can also be dynamic:

```lua
mcphub.add_tool("buffer", {
    name = "edit",
    inputSchema = function()
        -- Get open buffers
        local bufs = vim.api.nvim_list_bufs()
        local options = {}
        for _, bufnr in ipairs(bufs) do
            if vim.api.nvim_buf_is_loaded(bufnr) then
                table.insert(options, tostring(bufnr))
            end
        end
        
        return {
            type = "object",
            properties = {
                buffer = {
                    type = "string",
                    enum = options,
                    description = "Buffer to edit"
                }
            }
        }
    end,
    handler = function(req, res)
        -- Implementation
    end
})
```

#### Rich Responses

Tools can return multiple content types:

```lua
mcphub.add_tool("diagram", {
    name = "generate",
    handler = function(req, res)
        -- Generate diagram image
        local image_data = generate_diagram(req.params)
        
        -- Return both text and image
        return res
            :text("Generated diagram:")
            :image(image_data, "image/png")
            :text("Diagram shows relationship between A and B")
            :send()
    end
})
```

#### Error Handling

Use proper error handling with details:

```lua
mcphub.add_tool("git", {
    name = "commit",
    handler = function(req, res)
        -- Check git repository
        if not is_git_repo() then
            return res:error("Not a git repository", {
                cwd = vim.fn.getcwd(),
                suggestion = "Initialize git with 'git init'"
            })
        end
        
        -- Check for changes
        if git_is_clean() then
            return res:error("No changes to commit", {
                status = vim.fn.system("git status"),
                suggestion = "Make changes before committing"
            })
        end
        
        -- Implementation
    end
})
```

#### Using Editor Context

Access current editor state:

```lua
mcphub.add_tool("buffer", {
    name = "analyze",
    handler = function(req, res)
        -- Get active buffer info
        local buf = req.editor_info.last_active
        if not buf then
            return res:error("No active buffer")
        end
        
        -- Get buffer details
        local details = {
            name = buf.filename,
            type = buf.filetype,
            lines = buf.line_count,
            modified = buf.is_modified
        }
        
        -- Format response
        return res:text(vim.inspect(details)):send()
    end
})
```

#### Caller-Aware Tools

Adapt behavior based on caller:

```lua
mcphub.add_tool("context", {
    name = "get_code",
    handler = function(req, res)
        if req.caller.type == "codecompanion" then
            -- Get context from CodeCompanion chat
            local chat = req.caller.codecompanion.chat
            return handle_codecompanion(chat, res)
        
        elseif req.caller.type == "avante" then
            -- Get context from Avante
            local code = req.caller.avante.code
            return handle_avante(code, res)
            
        else
            -- Default behavior
            return res:text("No special context"):send()
        end
    end
})
```

Next, learn about [Adding Resources](./resources) to provide data through URIs.
