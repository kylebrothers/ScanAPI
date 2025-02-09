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
        .success {
            color: #2ecc71;
            display: none;
        }
        .error {
            color: #e74c3c;
            display: none;
        }
        button {
            background-color: #3498db;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 4px;
            cursor: pointer;
            margin-top: 10px;
        }
        button:hover {
            background-color: #2980b9;
        }
    </style>
</head>
<body>
    <div class="container">
        <div id="scanning">
            <h2>Initiating Scan...</h2>
            <div class="spinner"></div>
            <p>Please wait while your document is being scanned.</p>
        </div>
        <div id="success" class="success">
            <h2>Scan Complete!</h2>
            <p>Your document has been scanned successfully.</p>
            <button onclick="window.close(); window.location.href='about:blank';">Close Window</button>
        </div>
        <div id="error" class="error">
            <h2>Scan Error</h2>
            <p id="errorMessage"></p>
            <button onclick="window.close(); window.location.href='about:blank';">Close Window</button>
        </div>
    </div>
    <script>
        // Function to show a specific section and hide others
        function showSection(sectionId) {
            ['scanning', 'success', 'error'].forEach(id => {
                document.getElementById(id).style.display = id === sectionId ? 'block' : 'none';
            });
        }

        // Function to execute the scan
        async function executeScan() {
            try {
                const response = await fetch(']] .. command_config.url .. [[', {
                    method: ']] .. (command_config.method or "GET") .. [[',
                    headers: ]] .. cjson.encode(command_config.headers or {}) .. [[,
                    body: ]] .. (command_config.data and cjson.encode(command_config.data) or "null") .. [[
                });
                
                const data = await response.json();
                console.log('Scan response:', data);
                
                // Show success message
                showSection('success');
                
                // If the window doesn't close automatically, at least we show a nice message
                setTimeout(() => {
                    if (!window.closed) {
                        document.querySelector('.success p').innerHTML += '<br><small>You can now close this window.</small>';
                    }
                }, 2000);
                
            } catch (error) {
                console.error('Scan error:', error);
                document.getElementById('errorMessage').textContent = error.message;
                showSection('error');
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
        
        -- Generate and serve the scan page
        ngx.header.content_type = "text/html"
        ngx.say(create_scan_page(command_config))
        return ngx.exit(ngx.OK)
    else
        add_debug("No configuration found for this URI")
    end
end
