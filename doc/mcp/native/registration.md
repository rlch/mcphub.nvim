# Registration Methods

There are two ways to register native MCP servers in MCPHub. But first, let's understand the core types involved.

## Core Types

### Server Definition
```lua
---@class NativeServerDef
---@field name? string Name of the server
---@field displayName? string Display name of the server
---@field capabilities? MCPCapabilities List of server capabilities

---@class MCPCapabilities
---@field tools? MCPTool[] List of tools
---@field resources? MCPResource[] List of resources
---@field resourceTemplates? MCPResourceTemplate[] List of templates
---@field prompts? MCPPrompt[] List of prompts
```

## Registration Methods

### 1. Configuration-Based (Setup)

Register your complete server through MCPHub's setup:

```lua
require("mcphub").setup({
    native_servers = {
        -- Define your server
        example = {
            -- Required: Server name
            name = "example",
            
            -- Optional: Display name
            displayName = "Example Server",
            
            -- Required: Server capabilities
            capabilities = {
                tools = { ... },
                resources = { ... },
                resourceTemplates = { ... },
                prompts = { ... }
            }
        }
    }
})
```

### 2. API-Based (Dynamic)

Add capabilities incrementally using the API:

```lua
local mcphub = require("mcphub")

-- Create or get a server
mcphub.add_server("example", {
    displayName = "Example Server"
})

-- Or automatically create server when adding capabilities
mcphub.add_tool("example", {...})      -- Creates server if needed
mcphub.add_resource("example", {...})  -- Creates server if needed
```

#### add_server
```lua
---@param server_name string Name of the server
---@param def? NativeServerDef Optional server definition
---@return NativeServer|nil server Server instance or nil on error
mcphub.add_server("example", {
    name = "example",
    displayName = "Example Server",
    capabilities = { ... }
})
```

#### add_tool
```lua
---@param server_name string Name of the server
---@param tool_def MCPTool Tool definition
---@return NativeServer|nil server Server instance or nil on error
mcphub.add_tool("example", {
    -- Required: Tool name
    name = "greeting",
    
    -- Optional: Description (string or function)
    description = "Greet a user",
    
    -- Optional: Input validation schema
    inputSchema = {
        type = "object",
        properties = {
            name = {
                type = "string",
                description = "Name to greet"
            }
        }
    },
    
    -- Required: Tool implementation
    ---@param req ToolRequest Request context
    ---@param res ToolResponse Response builder
    handler = function(req, res)
        return res:text("Hello " .. req.params.name):send()
    end
})
```

#### add_resource
```lua
---@param server_name string Name of the server
---@param resource_def MCPResource Resource definition
---@return NativeServer|nil server Server instance or nil on error
mcphub.add_resource("example", {
    -- Optional: Resource name
    name = "Welcome",
    
    -- Required: Static URI
    uri = "example://welcome",
    
    -- Optional: Description
    description = "Welcome message",
    
    -- Optional: MIME type
    mimeType = "text/plain",
    
    -- Required: Resource handler
    ---@param req ResourceRequest Request context
    ---@param res ResourceResponse Response builder
    handler = function(req, res)
        return res:text("Welcome!"):send()
    end
})
```

#### add_resource_template
```lua
---@param server_name string Name of the server
---@param template_def MCPResourceTemplate Template definition
---@return NativeServer|nil server Server instance or nil on error
mcphub.add_resource_template("example", {
    -- Optional: Template name
    name = "UserInfo",
    
    -- Required: URI template with parameters
    uriTemplate = "example://user/{id}",
    
    -- Optional: Description
    description = "Get user information",
    
    -- Optional: Default MIME type
    mimeType = "text/plain",
    
    -- Required: Template handler
    ---@param req ResourceRequest Request with params
    ---@param res ResourceResponse Response builder
    handler = function(req, res)
        -- Access template parameters
        local id = req.params.id
        return res:text("User " .. id):send()
    end
})
```

#### add_prompt
```lua
---@param server_name string Name of the server
---@param prompt_def MCPPrompt Prompt definition
---@return NativeServer|nil server Server instance or nil on error
mcphub.add_prompt("example", {
    -- Optional: Prompt name
    name = "chat",
    
    -- Optional: Description
    description = "Start a chat",
    
    -- Optional: Prompt arguments
    arguments = {
        {
            name = "topic",
            description = "Chat topic",
            required = true
        }
    },
    
    -- Required: Prompt handler
    ---@param req PromptRequest Request with arguments
    ---@param res PromptResponse Response builder
    handler = function(req, res)
        return res
            :system()
            :text("Chat about: " .. req.params.topic)
            :user()
            :text("Tell me about " .. req.params.topic)
            :llm()
            :text("I'd be happy to discuss " .. req.params.topic)
            :send()
    end
})
```

## Next Steps

Now that you understand server registration, dive into:
1. [Adding Tools](./tools) - Implement tool capabilities
2. [Adding Resources](./resources) - Create resources and templates
3. [Adding Prompts](./prompts) - Create interactive prompts

Each capability type has its own request/response types and patterns for success.
