-- access.lua
local cjson = require "cjson"

-- Debug information collector
local debug_info = {}
local function add_debug(message)
    table.insert(debug_info, message)
end

-- Function to read and parse the config file
local function read_config_file()
    local config_file = io.open("/usr/local/openresty/nginx/conf/custom/curl_commands.json", "r")
    if not config_file then
        add_debug("ERROR: Failed to open config file")
        return nil
    end
    
    local config_content = config_file:read("*a")
    config_file:close()
    
    local ok, config = pcall(cjson.decode, config_content)
    if not ok then
        add_debug("ERROR: Failed to parse config file: " .. config)
        return nil
    end
    
    add_debug("Successfully loaded configuration file")
    return config
end

-- Function to execute curl command and capture output
local function execute_curl(curl_command)
    add_debug("Executing curl command: " .. curl_command)
    
    local handle = io.popen(curl_command)
    local result = handle:read("*a")
    local success, exit_type, exit_code = handle:close()
    
    if success then
        add_debug("Curl command executed successfully")
        add_debug("Response: " .. result)
    else
        add_debug("Curl command failed with exit code: " .. (exit_code or "unknown"))
    end
    
    return result, success
end

-- Function to inject debug info into HTML
local function inject_debug_info(debug_data)
    -- Capture the original response body
    local response = ngx.arg[1]
    
    -- Create debug HTML
    local debug_html = [[
        <div style="position: fixed; bottom: 0; left: 0; right: 0; 
                    background-color: rgba(0,0,0,0.8); color: #00ff00; 
                    font-family: monospace; padding: 20px; 
                    max-height: 50%; overflow-y: auto; z-index: 10000;">
            <h3>Debug Information:</h3>
            <pre>]] .. table.concat(debug_data, "\n") .. [[</pre>
        </div>
    ]]
    
    -- Insert debug info before closing body tag
    if response then
        response = response:gsub("</body>", debug_html .. "</body>")
        ngx.arg[1] = response
    end
end

-- Main request handling
if string.match(ngx.var.uri, "%.html$") then
    add_debug("Processing request for: " .. ngx.var.uri)
    
    local config = read_config_file()
    if config and config.commands[ngx.var.uri] then
        local command_config = config.commands[ngx.var.uri]
        add_debug("Found configuration for URI")
        add_debug("Configuration: " .. cjson.encode(command_config))
        
        -- Build curl command
        local curl_parts = {"curl -s"}
        
        if command_config.method then
            table.insert(curl_parts, "-X " .. command_config.method)
        end
        
        if command_config.headers then
            for header, value in pairs(command_config.headers) do
                table.insert(curl_parts, string.format("-H '%s: %s'", header, value))
            end
        end
        
        if command_config.data then
            table.insert(curl_parts, "-d '" .. cjson.encode(command_config.data) .. "'")
        end
        
        table.insert(curl_parts, "'" .. command_config.url .. "'")
        local curl_command = table.concat(curl_parts, " ")
        
        -- Execute the command
        local result, success = execute_curl(curl_command)
        
        -- Register a body filter to inject debug info
        ngx.ctx.debug_info = debug_info
    else
        add_debug("No configuration found for this URI")
    end
    
    -- Set up the body filter
    ngx.header.content_type = "text/html"
    ngx.header.content_length = nil  -- Clear content length as we'll modify the body
    
    -- Register the body filter
    ngx.ctx.debug_info = debug_info
end

-- Body filter
if ngx.arg[1] and ngx.ctx.debug_info then
    inject_debug_info(ngx.ctx.debug_info)
end
