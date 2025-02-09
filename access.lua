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

-- Function to create auto-close HTML page
local function create_auto_close_page(command_config)
    local html = [[
<!DOCTYPE html>
<html>
<head>
    <title>Scanning...</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            background-color: #f0f0f0;
        }
        .container {
            text-align: center;
            padding: 20px;
            background-color: white;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .spinner {
            border: 4px solid #f3f3f3;
            border-top: 4px solid #3498db;
            border-radius: 50%;
            width: 40px;
            height: 40px;
            animation: spin 1s linear infinite;
            margin: 20px auto;
        }
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
    </style>
</head>
<body>
    <div class="container">
        <h2>Initiating Scan...</h2>
        <div class="spinner"></div>
        <p>The page will close automatically when complete.</p>
    </div>
    <script>
        // Function to execute the curl command via fetch
        async function executeScan() {
            try {
                const response = await fetch(']] .. command_config.url .. [[', {
                    method: ']] .. (command_config.method or "GET") .. [[',
                    headers: ]] .. cjson.encode(command_config.headers or {}) .. [[,
                    body: ]] .. (command_config.data and cjson.encode(command_config.data) or "null") .. [[
                });
                
                const data = await response.json();
                console.log('Scan response:', data);
                
                // Wait a moment to ensure the scan has started
                setTimeout(() => {
                    window.close();
                }, 2000);
            } catch (error) {
                console.error('Scan error:', error);
                document.querySelector('.container').innerHTML += `
                    <p style="color: red">Error: ${error.message}</p>
                    <button onclick="window.close()">Close Window</button>
                `;
            }
        }

        // Execute scan when page loads
        window.onload = executeScan;
    </script>
</body>
</html>
    ]]
    
    return html
end

-- Main request handling
if string.match(ngx.var.uri, "%.html$") then
    add_debug("Processing request for: " .. ngx.var.uri)
    
    local config = read_config_file()
    if config and config.commands[ngx.var.uri] then
        local command_config = config.commands[ngx.var.uri]
        add_debug("Found configuration for URI")
        
        -- Generate and serve the auto-close page
        ngx.header.content_type = "text/html"
        ngx.say(create_auto_close_page(command_config))
        return ngx.exit(ngx.OK)
    else
        add_debug("No configuration found for this URI")
    end
end
