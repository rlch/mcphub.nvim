# CopilotChat Integration <Badge type="warning" text="Draft"/>

[CopilotChat.nvim](https://github.com/CopilotC-Nvim/CopilotChat.nvim) supports function calling which is currently in [draft](https://github.com/CopilotC-Nvim/CopilotChat.nvim/pull/1029). To integrate MCP Hub with CopilotChat we need to use the `tools` branch of CopilotChat as shown below:

> [!WARNING]
> Please note that CopilotChat function-calling support is available as a [Draft PR](https://github.com/CopilotC-Nvim/CopilotChat.nvim/pull/1029). 

## Install CopilotChat

```lua
{
    "deathbeam/CopilotChat.nvim",
    dependencies = {
        { "zbirenbaum/copilot.lua" },
        { "nvim-lua/plenary.nvim", branch = "master" }, -- for curl, log and async functions
    },
    branch = "tools",
    build = "make tiktoken", -- Only on MacOS or Linux
}
```

## Integrate MCP Hub

After the `setup()` of CopilotChat is called, add the following code. Please see the [draft PR](https://github.com/CopilotC-Nvim/CopilotChat.nvim/pull/1029) for more information.

```lua
local chat = require("CopilotChat")
chat.setup()

local mcp = require("mcphub")
mcp.on({ "servers_updated", "tool_list_changed", "resource_list_changed" }, function()
	local hub = mcp.get_hub_instance()
	if not hub then
		return
	end

	local async = require("plenary.async")
	local call_tool = async.wrap(function(server, tool, input, callback)
		hub:call_tool(server, tool, input, {
			callback = function(res, err)
				callback(res, err)
			end,
		})
	end, 4)

	local access_resource = async.wrap(function(server, uri, callback)
		hub:access_resource(server, uri, {
			callback = function(res, err)
				callback(res, err)
			end,
		})
	end, 3)

	for name, tool in pairs(chat.config.functions) do
		if tool.id and tool.id:sub(1, 3) == "mcp" then
			chat.config.functions[name] = nil
		end
	end
	local resources = hub:get_resources()
	for _, resource in ipairs(resources) do
		local name = resource.name:lower():gsub(" ", "_"):gsub(":", "")
		chat.config.functions[name] = {
			id = "mcp:" .. resource.server_name .. ":" .. name,
			uri = resource.uri,
			description = type(resource.description) == "string" and resource.description or "",
			resolve = function()
				local res, err = access_resource(resource.server_name, resource.uri)
				if err then
					error(err)
				end

				res = res or {}
				local result = res.result or {}
				local content = result.contents or {}
				local out = {}

				for _, message in ipairs(content) do
					if message.text then
						table.insert(out, {
							uri = message.uri,
							data = message.text,
							mimetype = message.mimeType,
						})
					end
				end

				return out
			end,
		}
	end

	local tools = hub:get_tools()
	for _, tool in ipairs(tools) do
		chat.config.functions[tool.name] = {
			id = "mcp:" .. tool.server_name .. ":" .. tool.name,
			group = tool.server_name,
			description = tool.description,
			schema = tool.inputSchema,
			resolve = function(input)
				local res, err = call_tool(tool.server_name, tool.name, input)
				if err then
					error(err)
				end

				res = res or {}
				local result = res.result or {}
				local content = result.content or {}
				local out = {}

				for _, message in ipairs(content) do
					if message.type == "text" then
						table.insert(out, {
							data = message.text,
						})
					elseif message.type == "resource" and message.resource and message.resource.text then
						table.insert(out, {
							uri = message.resource.uri,
							data = message.resource.text,
							mimetype = message.resource.mimeType,
						})
					end
				end

				return out
			end,
		}
	end
end)
```

## Usage

#### MCP Servers As Tools

You can type `@` in the chat to see all the available tools in CopilotChat. CopilotChat allows us to add all the tools of a MCP server as a tool group as well as the individual tools. For e.g `> @neovim` will add all the tools of Neovim MCP server to the chat. The `>` at the start makes it sticky which means the tools will be sent with all user prompts. You can also just add a specific tool from Neovim server by selecting from the group.

![Image](https://github.com/user-attachments/assets/7c16bc7e-a9df-4afc-9736-2ee6a39919a9)

![Image](https://github.com/user-attachments/assets/adc556bb-7d5f-4d22-820a-a7daeb0ac72c)

#### MCP Resources As Variables

Resources from MCP servers will also be available as CopilotChat variables `#`.

![Image](https://github.com/user-attachments/assets/7f77bf1e-12b7-4745-a87b-40181a619733)


