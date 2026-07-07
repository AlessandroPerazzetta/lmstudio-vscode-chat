# Debugging API Key Connection Issues

## Common Issue: "Can't reach LM Studio at http://x.x.x.x:1234/v1"

If you're getting this error when trying to connect to a server with an IP address and API key, here are the potential causes and solutions:

### 1. Check Server Reachability First

**Test without the extension:**

```bash
# Test if the server is reachable (replace x.x.x.x with your server IP)
curl -v http://x.x.x.x:1234/v1/models

# If LM Studio requires authentication, try:
curl -v -H "Authorization: Bearer YOUR_API_KEY" http://x.x.x.x:1234/v1/models
```

**Check if the server is actually running on that IP and port:**
- Ensure LM Studio's "Local Server" option is enabled in LM Studio settings
- Verify the IP address is correct (use `ipconfig` on Windows or `ifconfig`/`ip addr` on Linux/macOS)
- Make sure the port (default 1234) isn't blocked by a firewall

### 2. Network Configuration Issues

**Remote server access:**
- LM Studio's local server only binds to localhost (`127.0.0.1`) by default
- To access from another machine, you need to:
  1. Open LM Studio on the remote machine
  2. Go to Settings → Local Server
  3. Check "Allow connections from other devices"
  4. Use the remote machine's actual IP address (not localhost/127.0.0.1)

**Firewall issues:**
- Ensure port 1234 is open on the server machine
- On Linux: `sudo ufw allow 1234/tcp`
- On Windows: Create an inbound rule for port 1234

### 3. API Key Authentication

**LM Studio's authentication behavior:**
- LM Studio does NOT require API keys by default (local installations only)
- If you're connecting to a remote instance, the server might not be configured to accept requests from your IP

**To add API key support to LM Studio itself:**
1. In LM Studio, go to Settings → Local Server
2. You may need to configure authentication through environment variables or a proxy
3. Alternatively, use a reverse proxy (like nginx) to add authentication

### 4. Extension Debugging

The updated extension now includes detailed logging:

**To view the logs:**
1. In VS Code, open Command Palette (Ctrl+Shift+P)
2. Type "Developer: Toggle Developer Tools"
3. Go to the Console tab
4. Click the LM Studio icon in the Activity Bar
5. Try connecting to your server

**Expected log messages:**
```
doInit: server=YourServerName, url=http://x.x.x.x:1234/v1, hasApiKey=true (8 headers)
checkConnection: url=http://x.x.x.x:1234/v1, hasApiKey=true (2 headers)
checkConnection: response status=HTTP 401
checkConnection: non-200 response (401), retrying without auth headers
```

### 5. Common Solutions

**Solution A: Disable API Key**
If the server doesn't require authentication:
1. Edit your server configuration in VS Code
2. Clear the API key field
3. Save and try connecting again

**Solution B: Use Correct IP Address**
If connecting to another machine:
1. Find the server's actual IP address (not localhost)
2. Update the server URL in VS Code with the correct IP
3. Make sure LM Studio on the remote machine allows connections from other devices

**Solution C: Check Port Forwarding**
If using SSH tunneling or port forwarding:
```bash
# Example: tunnel to remote machine
ssh -L 1234:localhost:1234 user@remote-server
```
Then configure VS Code to connect to `http://localhost:1234/v1`

### 6. Testing the Extension Changes

**Verify the API key is being sent:**
The logs will show if the API key header is included:
- `"hasApiKey=true (8 headers)"` means auth headers are being sent
- `"response status=HTTP 401"` or `"response status=HTTP 403"` indicates authentication issue

**If you see network errors:**
- `"network error - ECONNREFUSED"` means the server isn't running or reachable
- `"fetch failed"` usually means CORS or network connectivity issues

### 7. Alternative Approach: Use a Proxy

If LM Studio doesn't support API keys natively, you can use a reverse proxy:

**nginx example:**
```nginx
server {
    listen 8080;
    
    location /v1/ {
        # Add your authentication header
        proxy_set_header Authorization "Bearer YOUR_SECRET_KEY";
        
        # Forward to LM Studio
        proxy_pass http://localhost:1234/v1/;
    }
}
```

Then configure VS Code to connect to `http://your-machine:8080/v1` with the API key `YOUR_SECRET_KEY`.
