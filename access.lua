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

-- Function to create scan page
local function create_scan_page(command_config)
    -- Extract scan details for display
    local scan_type = "Document"
    if string.match(ngx.var.uri, "photo") then
        scan_type = "Photo"
    end
    
    local scan_mode = "Color"
    if string.match(ngx.var.uri, "gray") then
        scan_mode = "Grayscale"
    end
    
    local device_id = command_config.data.params.deviceId
    local scanner_id = string.match(device_id, "_(%w+)$") or "Unknown"
    
    local html = [[
<!DOCTYPE html>
<html>
<head>
    <title>Scanning...</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            background-color: #f5f5f5;
        }
        .container {
            text-align: center;
            padding: 20px;
            background-color: white;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            max-width: 400px;
            width: 100%;
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
        <p>Please wait while your ]] .. scan_type .. [[ is being scanned in ]] .. scan_mode .. [[ mode.</p>
        <p>Scanner: ]] .. scanner_id .. [[</p>
    </div>
    <script>
        // Function to execute the scan
        async function executeScan() {
            try {
                const response = await fetch(']] .. command_config.url .. [[', {
                    method: ']] .. (command_config.method or "GET") .. [[',
                    headers: ]] .. cjson.encode(command_config.headers or {}) .. [[,
                    body: JSON.stringify(]] .. (command_config.data and cjson.encode(command_config.data) or "null") .. [[)
                });
                
                if (!response.ok) {
                    throw new Error('Scan failed with status: ' + response.status);
                }
                
                const data = await response.json();
                console.log('Scan response:', data);
                
                // Redirect to success page with scan info
                window.location.href = '/scan-success.html?type=]] .. scan_type .. [[&mode=]] .. scan_mode .. [[&scanner=]] .. scanner_id .. [[';
                
            } catch (error) {
                console.error('Scan error:', error);
                // Redirect to error page with error message
                window.location.href = '/scan-error.html?error=' + encodeURIComponent(error.message);
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

-- Function to create success page
local function create_success_page()
    local html = [[
<!DOCTYPE html>
<html>
<head>
    <title>Scan Complete</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            background-color: #f5f5f5;
        }
        .container {
            text-align: center;
            padding: 20px;
            background-color: white;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            max-width: 400px;
            width: 100%;
        }
        .success-icon {
            color: #2ecc71;
            font-size: 48px;
            margin-bottom: 20px;
        }
        button {
            background-color: #3498db;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 4px;
            cursor: pointer;
            margin-top: 20px;
        }
        button:hover {
            background-color: #2980b9;
        }
        .info {
            margin-top: 20px;
            font-size: 14px;
            color: #777;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="success-icon">✓</div>
        <h2>Scan Complete!</h2>
        <p>Your document has been scanned successfully.</p>
        <div id="scan-info" class="info"></div>
        <button onclick="window.close();">Close Window</button>
    </div>
    <script>
        // Extract scan info from URL parameters
        window.onload = function() {
            const urlParams = new URLSearchParams(window.location.search);
            const type = urlParams.get('type') || 'Document';
            const mode = urlParams.get('mode') || 'Unknown';
            const scanner = urlParams.get('scanner') || 'Unknown';
            
            document.getElementById('scan-info').innerHTML = 
                `Type: ${type}<br>Mode: ${mode}<br>Scanner: ${scanner}`;
        };
    </script>
</body>
</html>
    ]]
    
    return html
end

-- Function to create error page
local function create_error_page()
    local html = [[
<!DOCTYPE html>
<html>
<head>
    <title>Scan Error</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            background-color: #f5f5f5;
        }
        .container {
            text-align: center;
            padding: 20px;
            background-color: white;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            max-width: 400px;
            width: 100%;
        }
        .error-icon {
            color: #e74c3c;
            font-size: 48px;
            margin-bottom: 20px;
        }
        button {
            background-color: #3498db;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 4px;
            cursor: pointer;
            margin-top: 20px;
        }
        button:hover {
            background-color: #2980b9;
        }
        .error-message {
            margin-top: 20px;
            color: #e74c3c;
            padding: 10px;
            border: 1px solid #e74c3c;
            border-radius: 4px;
            font-family: monospace;
            text-align: left;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="error-icon">✗</div>
        <h2>Scan Error</h2>
        <p>There was a problem with your scan request.</p>
        <div id="error-message" class="error-message"></div>
        <button onclick="window.close();">Close Window</button>
    </div>
    <script>
        // Extract error message from URL parameters
        window.onload = function() {
            const urlParams = new URLSearchParams(window.location.search);
            const error = urlParams.get('error') || 'Unknown error';
            document.getElementById('error-message').textContent = error;
        };
    </script>
</body>
</html>
    ]]
    
    return html
end

-- Determine the current execution phase
local function handle_request()
    -- Handle content phase requests for scan result pages
    if ngx.get_phase() == "content" then
        if ngx.var.uri == "/scan-success.html" then
            -- Serve success page
            ngx.header.content_type = "text/html"
            ngx.say(create_success_page())
            return ngx.exit(ngx.OK)
        elseif ngx.var.uri == "/scan-error.html" then
            -- Serve error page
            ngx.header.content_type = "text/html"
            ngx.say(create_error_page())
            return ngx.exit(ngx.OK)
        end
    -- Handle access phase requests
    elseif ngx.get_phase() == "access" then
        if string.match(ngx.var.uri, "%.html$") then
            add_debug("Processing request for: " .. ngx.var.uri)
            
            local config = read_config_file()
            if config and config.commands[ngx.var.uri] then
                local command_config = config.commands[ngx.var.uri]
                add_debug("Found configuration for URI")
                
                -- Generate and serve the scan page
                ngx.header.content_type = "text/html"
                ngx.say(create_scan_page(command_config))
                return ngx.exit(ngx.OK)
            else
                add_debug("No configuration found for this URI")
            end
        end
    -- Other phases don't need special handling for our use case
    end
end

-- Execute the request handler
handle_request()
