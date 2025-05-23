--[[
*MCP Servers Tool*
This tool can be used to call tools and resources from the MCP Servers.
M.mcp_tool() will return a use_mcp_tool and access_mcp_resource function schemas.

M.use_mcp_tool() will return schema for calling tools on MCP servers.
M.access_mcp_resource() will return schema for accessing resources on MCP servers.
--]]
local M = {}
local shared = require("mcphub.extensions.shared")

local tool_schemas = {
    use_mcp_tool = {
        name = "use_mcp_tool",
        description = "Calls tools on MCP servers.",
        param = {
            type = "table",
            fields = {
                {
                    name = "server_name",
                    description = "Name of the server to call the tool on. Must be from one of the available servers.",
                    type = "string",
                },
                {
                    name = "tool_name",
                    description = "Name of the tool to call.",
                    type = "string",
                },
                {
                    name = "tool_input",
                    description = "Input for the tool call",
                    type = "object",
                },
            },
        },
    },

    access_mcp_resource = {
        name = "access_mcp_resource",
        description = "Get resources on MCP servers.",
        param = {
            type = "table",
            fields = {
                {
                    name = "server_name",
                    description = "Name of the server to call the resource on. Must be from one of the available servers.",
                    type = "string",
                },
                {
                    name = "uri",
                    description = "URI of the resource to access.",
                    type = "string",
                },
            },
        },
    },
}

---@return table,table
function M.mcp_tool()
    for action_name, schema in pairs(tool_schemas) do
        schema.func = function(args, on_log, on_complete)
            local hub = require("mcphub").get_hub_instance()
            if not hub then
                return nil, "MCP Hub not initialized"
            end
            local params = shared.parse_params(args, action_name)
            if #params.errors > 0 then
                return nil, table.concat(params.errors, "\n")
            end
            local auto_approve = vim.g.mcphub_auto_approve == true
            if not auto_approve then
                local confirmed = shared.show_mcp_tool_prompt({
                    action = params.action,
                    server_name = params.server_name,
                    tool_name = params.tool_name,
                    uri = params.uri,
                    arguments = params.arguments,
                })
                if not confirmed then
                    return nil, "User cancelled the operation"
                end
            end
            local sidebar = require("avante").get()
            if params.action == "access_mcp_resource" then
                hub:access_resource(params.server_name, params.uri, {
                    parse_response = true,
                    caller = {
                        type = "avante",
                        avante = sidebar,
                    },
                    callback = function(result, err)
                        --result has .text and .images [{mimeType, data}]
                        local text = result and result.text or ""
                        if not text or text == "" then
                            local empty_response =
                                string.format("`%s` successful. `%s` returned no text.", params.action, params.uri)
                            text = empty_response
                        end
                        on_complete(text, err)
                    end,
                })
            elseif params.action == "use_mcp_tool" then
                hub:call_tool(params.server_name, params.tool_name, params.arguments, {
                    parse_response = true,
                    caller = {
                        type = "avante",
                        avante = sidebar,
                    },
                    callback = function(result, err)
                        if result.error then
                            on_complete(nil, result.error)
                        else
                            local text = result and result.text or ""
                            if not text or text == "" then
                                local empty_response = string.format(
                                    "`%s` successful. `%s` returned no text.",
                                    params.action,
                                    params.tool_name
                                )
                                text = empty_response
                            end
                            on_complete(text, err)
                        end
                    end,
                })
            else
                return nil, "Invalid action type"
            end
        end
        schema.returns = {
            {
                name = "result",
                description = string.format("The `%s` call returned the following text:\n", action_name),
                type = "string",
            },
            {
                name = "error",
                description = string.format("The `%s` call failed with the following error:\n", action_name),
                type = "string",
                optional = true,
            },
        }
        M[action_name] = schema
    end
    ---@diagnostic disable-next-line: redundant-return-value
    return unpack(vim.tbl_values(tool_schemas))
end

return M
