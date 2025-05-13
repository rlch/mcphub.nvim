local M = {}

---@class MCPHUB.OS_INFO
---@field os_name string
---@field arch string
---@field hostname string
---@field cpu_info uv.cpu_info.cpu[]?
---@field memory {total :number, free :number}
---@field cwd string
---@field env {shell :string, term :string, user :string, home :string}

---@return MCPHUB.OS_INFO
function M.get_os_info()
    local os_info = {
        os_name = jit.os,
        arch = jit.arch,
        hostname = vim.loop.os_gethostname(),
        cpu_info = vim.loop.cpu_info(),
        memory = {
            total = vim.loop.get_total_memory(),
            free = vim.loop.get_free_memory(),
        },
        cwd = vim.fn.getcwd(),
        env = {
            shell = os.getenv("SHELL"),
            term = os.getenv("TERM"),
            user = os.getenv("USER"),
            home = os.getenv("HOME"),
        },
    }
    return os_info
end
return M
