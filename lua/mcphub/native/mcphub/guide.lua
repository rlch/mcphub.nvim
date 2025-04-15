local mcphub = require("mcphub")
local prompt_utils = require("mcphub.utils.prompt")

mcphub.add_tool("mcphub", {
    name = "toggle_mcp_server",
    description = "Start or stop an MCP server. You can only start a server from one of the disabled servers.",
    inputSchema = {
        type = "object",
        properties = {
            server_name = {
                type = "string",
                description = "Name of the MCP server to toggle",
            },
            action = {
                type = "string",
                description = "Action to perform. One of 'start' or 'stop'",
                enum = { "start", "stop" },
            },
        },
        required = { "server_name", "action" },
    },
    handler = function(req, res)
        local hub = mcphub.get_hub_instance()
        if not hub or not hub:is_ready() then
            return res:error("Hub is not ready")
        end

        local server_name = req.params.server_name
        local action = req.params.action
        if not server_name or not action then
            return res:error("Missing required parameters: server_name and action")
        end

        -- Check if server exists in current state
        local found = false
        for _, server in ipairs(hub:get_servers(true)) do
            if server.name == server_name then
                found = true
                break
            end
        end

        if not found then
            return res:error(string.format("Server '%s' not found in active servers", server_name))
        end

        --INFO: via_curl_request: because we can wait for the server to start or stop and send the correct status to llm rather than sse event based on file wathing which is more appropriate for UI
        if action == "start" then
            hub:start_mcp_server(server_name, {
                via_curl_request = true,
                callback = function(response, err)
                    if err then
                        return res:error(string.format("Failed to start MCP server: %s", err))
                    end
                    local server = response and response.server
                    return res
                        :text(
                            string.format("Started MCP server: %s\n%s", server_name, hub:convert_server_to_text(server))
                        )
                        :send()
                end,
            })
        elseif action == "stop" then
            hub:stop_mcp_server(server_name, true, {
                via_curl_request = true,
                callback = function(_, err)
                    if err then
                        return res:error(string.format("Failed to stop MCP server: %s", err))
                    end
                    return res:text(string.format("Stopped MCP server: %s.", server_name)):send()
                end,
            })
        else
            return res:error(string.format("Invalid action '%s'. Use 'start' or 'stop'", action))
        end
    end,
})

mcphub.add_resource("mcphub", {
    name = "MCPHub Plugin Docs",
    mimeType = "text/plain",
    uri = "mcphub://docs",
    description = [[Documentation for the mcphub.nvim plugin for Neovim.]],
    handler = function(_, res)
        local guide = prompt_utils.get_plugin_docs()
        if not guide then
            return res:error("Plugin docs not available")
        end
        return res:text(guide):send()
    end,
})

mcphub.add_resource("mcphub", {
    name = "MCPHub Native Server Guide",
    mimeType = "text/plain",
    uri = "mcphub://native_server_guide",
    description = [[Documentation on how to create Lua Native MCP servers for mcphub.nvim plugin.
This guide is intended for Large language models to help users create their own native servers for mcphub.nvim plugin.
Access this guide whenever you need information on how to create a native server for mcphub.nvim plugin.]],
    handler = function(_, res)
        local guide = prompt_utils.get_native_server_prompt()
        if not guide then
            return res:error("Native server guide not available")
        end
        return res:text(guide):send()
    end,
})

mcphub.add_resource("mcphub", {
    name = "MCPHub Changelog",
    mimeType = "text/plain",
    uri = "mcphub://changelog",
    description = [[Changelog for the mcphub.nvim plugin for Neovim.]],
    handler = function(_, res)
        local guide = prompt_utils.get_plugin_changelog()
        if not guide then
            return res:error("Plugin changelog not available")
        end
        return res:text(guide):send()
    end,
})
