M = {}

local os_sep = require("plenary.path").path.sep

M.OLLAMA = "ollama"
M.OLLAMA_REPO_URL = "https://github.com/ollama/ollama"
M.OLLAMA_INSTALL_DIR = vim.fn.stdpath("data")
M.OLLAMA_REPO_PATH = M.OLLAMA_INSTALL_DIR .. os_sep .. M.OLLAMA
M.OLLAMA_EXE_PATH = M.OLLAMA_REPO_PATH .. os_sep .. M.OLLAMA
M.OLLAMA_LOG_PATH = vim.fn.stdpath('log') .. "/ollama.log"

return M
