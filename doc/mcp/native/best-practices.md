# Best Practices

This guide covers essential patterns and recommendations for creating effective native MCP servers.

## Consistent Naming

```lua
-- Tools: verb_noun format
mcphub.add_tool("git", {
    name = "create_branch",    -- ✅ Clear action
    -- name = "branch_maker",  -- ❌ Unclear action
})

-- Resources: noun/category format
mcphub.add_resource("git", {
    name = "Current Branch",    -- ✅ Clear content
    uri = "git://branch/current"
    -- uri = "git://getcurbr"   -- ❌ Unclear/abbreviated
})
```

## Input Validation

### 1. Tool Arguments
```lua
mcphub.add_tool("files", {
    name = "read_lines",
    inputSchema = {
        type = "object",
        properties = {
            path = {
                type = "string",
                description = "File path",
                examples = ["src/main.lua"]
            },
            start = {
                type = "number",
                minimum = 1,
                description = "Start line (1-based)",
                default = 1
            }
        },
        required = ["path"]
    }
})
```

### 2. Resource Parameters
```lua
mcphub.add_resource_template("git", {
    uriTemplate = "git://log/{count}",
    handler = function(req, res)
        -- Validate numeric parameter
        local count = tonumber(req.params.count)
        if not count or count < 1 then
            return res:error("Invalid count", {
                received = req.params.count,
                expected = "positive number"
            })
        end
    end
})
```

## Error Handling

### 1. Prerequisites
```lua
mcphub.add_tool("git", {
    handler = function(req, res)
        -- Check environment
        if not vim.fn.executable("git") then
            return res:error("Git not installed", {
                install = "https://git-scm.com"
            })
        end
        
        -- Check repository
        if not is_git_repo() then
            return res:error("Not a git repository", {
                cwd = vim.fn.getcwd(),
                action = "Initialize with 'git init'"
            })
        end
    end
})
```

### 2. Operation Errors
```lua
mcphub.add_tool("files", {
    handler = function(req, res)
        -- Handle operation failure
        local ok, result = pcall(function()
            return vim.fn.readfile(req.params.path)
        end)
        
        if not ok then
            return res:error("Failed to read file", {
                error = result,
                path = req.params.path,
                permissions = vim.fn.getfperm(req.params.path)
            })
        end
    end
})
```

These best practices help create robust, maintainable, and user-friendly native MCP servers. Review them regularly as you develop your servers.
