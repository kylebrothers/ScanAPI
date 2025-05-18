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
    
    -- Define Dropbox URLs with the correct folder path
    local dropbox_web_url = "https://www.dropbox.com/home/scans"
    local dropbox_app_url = "dbx://folder/scans" -- Deep link format
    
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
        #countdown {
            font-weight: bold;
            color: #3498db;
        }
    </style>
</head>
<body>
    <div class="container">
        <h2>Initiating Scan...</h2>
        <div class="spinner"></div>
        <p>Please wait while your ]] .. scan_type .. [[ is being scanned in ]] .. scan_mode .. [[ mode.</p>
        <p>Scanner: ]] .. scanner_id .. [[</p>
        <p id="status-message">Connecting to scanner...</p>
        <p>Redirecting to Dropbox in <span id="countdown">5</span> seconds...</p>
    </div>
    <script>
        // Function to open Dropbox (trying app first, fallback to web)
        function openDropbox() {
            try {
                // First try to open the Dropbox app
                const appWindow = window.open(']] .. dropbox_app_url .. [[', '_blank');
                
                // Set a fallback in case the app isn't installed
                setTimeout(() => {
                    // If app window was blocked or didn't load, open web version
                    window.location.href = ']] .. dropbox_web_url .. [[';
                }, 1000);
            } catch (error) {
                // Direct fallback if any errors with the app URL
                window.location.href = ']] .. dropbox_web_url .. [[';
            }
        }
        
        // Update the status message
        function updateStatus(message) {
            document.getElementById('status-message').textContent = message;
        }
        
        // Countdown timer
        function startCountdown(seconds, callback) {
            const countdownElement = document.getElementById('countdown');
            countdownElement.textContent = seconds;
            
            const interval = setInterval(() => {
                seconds--;
                countdownElement.textContent = seconds;
                
                if (seconds <= 0) {
                    clearInterval(interval);
                    callback();
                }
            }, 1000);
        }
        
        // Function to execute the scan
        async function executeScan() {
            try {
                updateStatus("Sending scan request...");
                
                const response = await fetch(']] .. command_config.url .. [[', {
                    method: ']] .. (command_config.method or "GET") .. [[',
                    headers: ]] .. cjson.encode(command_config.headers or {}) .. [[,
                    body: JSON.stringify(]] .. (command_config.data and cjson.encode(command_config.data) or "null") .. [[)
                });
                
                if (!response.ok) {
                    throw new Error('Scan request failed with status: ' + response.status);
                }
                
                updateStatus("Scan started successfully! Redirecting to Dropbox...");
                
                // Start countdown then redirect
                startCountdown(5, openDropbox);
                
            } catch (error) {
                console.error('Scan error:', error);
                updateStatus("Error: " + error.message + ". Redirecting to Dropbox anyway...");
                
                // Still redirect to Dropbox after a shorter delay
                startCountdown(3, openDropbox);
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

-- Function to create success page (we're keeping this for backward compatibility)
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
        .file-info {
            margin-top: 10px;
            font-size: 14px;
            color: #777;
            text-align: left;
            padding: 10px;
            background-color: #f9f9f9;
            border-radius: 4px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="success-icon">✓</div>
        <h2>Scan Complete!</h2>
        <p>Your document has been scanned successfully.</p>
        <div id="file-info" class="file-info">Loading scan information...</div>
        <button onclick="window.close();">Close Window</button>
    </div>
    <script>
        window.onload = function() {
            // Retrieve scan result from localStorage
            const resultData = localStorage.getItem('scanResult');
            if (resultData) {
                try {
                    const result = JSON.parse(resultData);
                    if (result.file) {
                        document.getElementById('file-info').innerHTML = `
                            <strong>Document Type:</strong> ${result.scanType}<br>
                            <strong>Mode:</strong> ${result.scanMode}<br>
                            <strong>Scanner:</strong> ${result.scannerId}<br>
                            <strong>File:</strong> ${result.file.name}<br>
                            <strong>Size:</strong> ${result.file.sizeString}<br>
                            <strong>Date:</strong> ${new Date(result.file.lastModified).toLocaleString()}<br>
                            <strong>Path:</strong> ${result.file.path}/${result.file.name}
                        `;
                    } else {
                        document.getElementById('file-info').textContent = 'Scan completed, but no file details available.';
                    }
                    
                    // Clear the localStorage after retrieving data
                    localStorage.removeItem('scanResult');
                } catch (e) {
                    document.getElementById('file-info').textContent = 'Error retrieving scan details.';
                }
            } else {
                document.getElementById('file-info').textContent = 'No scan information available.';
            }
        };
    </script>
</body>
</html>
    ]]
    
    return html
end

-- Function to create error page (we're keeping this for backward compatibility)
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
            margin-top: 10px;
            color: #e74c3c;
            padding: 10px;
            border: 1px solid #e74c3c;
            border-radius: 4px;
            font-family: monospace;
            text-align: left;
        }
        .scan-info {
            margin-top: 10px;
            font-size: 14px;
            color: #777;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="error-icon">✗</div>
        <h2>Scan Error</h2>
        <p>There was a problem with your scan request.</p>
        <div id="error-message" class="error-message">Loading error details...</div>
        <div id="scan-info" class="scan-info"></div>
        <button onclick="window.close();">Close Window</button>
    </div>
    <script>
        window.onload = function() {
            // Retrieve scan result from localStorage
            const resultData = localStorage.getItem('scanResult');
            if (resultData) {
                try {
                    const result = JSON.parse(resultData);
                    document.getElementById('error-message').textContent = result.error || 'Unknown error';
                    
                    document.getElementById('scan-info').innerHTML = `
                        <strong>Document Type:</strong> ${result.scanType}<br>
                        <strong>Mode:</strong> ${result.scanMode}<br>
                        <strong>Scanner:</strong> ${result.scannerId}
                    `;
                    
                    // Clear the localStorage after retrieving data
                    localStorage.removeItem('scanResult');
                } catch (e) {
                    document.getElementById('error-message').textContent = 'Error retrieving error details.';
                }
            } else {
                document.getElementById('error-message').textContent = 'No error information available.';
            }
        };
    </script>
</body>
</html>
    ]]
    
    return html
end

-- Main request handling
if ngx.var.uri == "/scan-success" then
    -- Serve success page
    ngx.header.content_type = "text/html"
    ngx.say(create_success_page())
    return ngx.exit(ngx.OK)
elseif ngx.var.uri == "/scan-error" then
    -- Serve error page
    ngx.header.content_type = "text/html"
    ngx.say(create_error_page())
    return ngx.exit(ngx.OK)
elseif string.match(ngx.var.uri, "%.html$") then
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
