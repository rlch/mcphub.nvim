# Why Native MCP Servers?

MCPHub.nvim allows you to create MCP servers directly in Lua without any external processes. This guide explains why you might want to use native MCP servers and how they compare to other approaches.

## The Problem with Plugin-Specific Tools

Many chat plugins like Avante and CodeCompanion provide their own tool systems:

```lua
-- Avante custom tools
require("avante").setup({
    custom_tools = {
        get_weather = {
            name = "get_weather",
            description = "Get weather info",
            schema = { ... },
            func = function() end
        }
    }
})

-- CodeCompanion tools
require("codecompanion").setup({
    chat = {
        tools = {
            get_weather = {
                name = "get_weather",
                description = "Get weather info",
                schema = { ... },
                handler = function() end
            }
        }
    }
})
```

This leads to several limitations:

| Feature | Plugin-Specific Tools | Native MCP Servers |
|---------|---------------------|-------------------|
| Implementation | Need to rewrite for each plugin | Write once, use everywhere |
| API | Different for each plugin | Standard MCP protocol |
| Instructions | Limited by schema | Full system prompt |
| Resources | No standard way | URI-based system |
| Response Types | Usually just text | Text, images, blobs |
| State | Per-plugin management | Centralized lifecycle |
| Updates | May break tools | Plugin-independent |

## Benefits of Native MCP Servers

### 1. Write Once, Use Everywhere
```lua
-- Write once, works in any chat plugin
mcphub.add_tool("weather", {
    name = "get_weather",
    description = "Get weather info",
    handler = function(req, res)
        return res:text("Current weather: ☀️"):send()
    end
})
```

### 2. Rich Response Types
```lua
-- Support multiple response types
function handler(req, res)
    return res
        :text("Here's the weather:")
        :image(generate_chart(), "image/png")
        :text("Additional details...")
        :send()
end
```

### 3. Resource System
Access data through clean URIs:
```lua
mcphub.add_resource_template("weather", {
    uriTemplate = "weather://{city}",
    handler = function(req, res)
        local city = req.params.city
        return res:text(city .. ": ☀️"):send()
    end
})
```

### 4. Deep Editor Integration
Direct access to Neovim's features:
```lua
mcphub.add_tool("buffer", {
    name = "analyze",
    handler = function(req, res)
        -- Access current editor state
        local buf = req.editor_info.last_active
        -- Use LSP features
        local diagnostics = vim.diagnostic.get(buf.bufnr)
        -- Format response
        return res:text("Analysis complete"):send()
    end
})
```

### 5. Plugin-Aware Context
Adapt to different chat plugins:
```lua
mcphub.add_tool("context", {
    name = "analyze",
    handler = function(req, res)
        if req.caller.type == "codecompanion" then
            -- Handle CodeCompanion context
            local chat = req.caller.codecompanion.chat
            return handle_codecompanion(chat)
        elseif req.caller.type == "avante" then
            -- Handle Avante context
            local code = req.caller.avante.code
            return handle_avante(code)
        end
    end
})
```

### 6. Standard Protocol
Following the MCP specification ensures:
- Consistent behavior across plugins
- Future compatibility
- Clear documentation
- Standard error handling

## Real-World Example

Here's a real example from MCPHub's built-in Neovim server that demonstrates these benefits:

```lua
-- LSP diagnostics as a resource
mcphub.add_resource("neovim", {
    name = "Diagnostics: Current File",
    description = "Get diagnostics for current file",
    uri = "neovim://diagnostics/current",
    mimeType = "text/plain",
    handler = function(req, res)
        -- Get editor context
        local buf_info = req.editor_info.last_active
        if not buf_info then
            return res:error("No active buffer")
        end

        -- Use LSP features
        local diagnostics = vim.diagnostic.get(buf_info.bufnr)
        
        -- Format response
        local text = string.format(
            "Diagnostics for: %s\n%s\n",
            buf_info.filename,
            string.rep("-", 40)
        )
        
        for _, diag in ipairs(diagnostics) do
            local severity = vim.diagnostic.severity[diag.severity]
            text = text .. string.format(
                "\n%s: Line %d - %s\n",
                severity,
                diag.lnum + 1,
                diag.message
            )
        end

        return res:text(text):send()
    end
})
```

This example shows how native servers can:
1. Access Neovim APIs directly
2. Use built-in features like LSP
3. Format responses clearly
4. Handle errors properly
5. Work across all chat plugins

The next sections will show you how to create your own native MCP servers, starting with registration methods.