local mcphub = require("mcphub")

-- Create base mcphub server
mcphub.add_server("mcphub", {
    displayName = "MCPHub",
    description = "MCPHub server provides tools and resources to manage the mcphub.nvim neovim plugin. It has tools to toggle any MCP Server along with resources like docs, guides.",
})
require("mcphub.native.mcphub.guide")
