-- access.lua
local cjson = require "cjson"

-- Updated config file path
local CONFIG_FILE_PATH = "/usr/local/openresty/nginx/conf/custom/curl_commands.json"

-- Shared dictionary to store config
local config_cache = ngx.shared.config_cache
local CONFIG_KEY = "curl_commands"
local CONFIG_TIMESTAMP_KEY = "config_timestamp"
local CONFIG_CHECK_INTERVAL = 10  -- seconds

-- Function to read and parse the config file
local function read_config_file()
    local config_file = io.open(CONFIG_FILE_PATH, "r")
    if not config_file then
        ngx.log(ngx.ERR, "Failed to open config file: " .. CONFIG_FILE_PATH)
        return nil
    end
    
    local config_content = config_file:read("*a")
    config_file:close()
    
    local ok, config = pcall(cjson.decode, config_content)
    if not ok then
        ngx.log(ngx.ERR, "Failed to parse config file: " .. config)
        return nil
    end
    
    return config
end

-- Function to get file modification time
local function get_file_mtime()
    local handle = io.popen("stat -c %Y " .. CONFIG_FILE_PATH)
    local mtime = handle:read("*n")
    handle:close()
    return mtime
end

-- Rest of the Lua script remains the same as in the previous version
-- ... (keep all other functions and logic unchanged)
