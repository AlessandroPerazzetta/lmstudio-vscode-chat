# API Key Support for LM Studio VS Code Extension

## Overview
This update adds support for API key authentication when connecting to LM Studio servers. This allows you to connect to remote LM Studio instances that require API key authentication.

## Features Added

### 1. Server Configuration with API Keys
- When adding a new server via the UI, you can now enter an optional API key
- The API key is stored securely in VS Code's global storage
- Multiple servers can have different API keys configured

### 2. Authentication Headers
The extension automatically adds authentication headers to all API requests:
- `Authorization: Bearer <API_KEY>` - Standard bearer token authentication
- `X-API-Key: <API_KEY>` - Alternative header for compatibility

### 3. Server Management UI Updates
- Added API key input field (password type) when adding new servers
- Added edit server modal to modify existing server configurations including API keys
- Visual indicator (••••) shows when a server has an API key configured

## Usage

### Adding a New Server with API Key

1. Click the **LM Studio** icon in the VS Code activity bar
2. Click the **Servers** menu button (gear icon)
3. Enter server details:
   - **Name**: Display name for this server (e.g., "Workstation")
   - **URL**: The base URL of your LM Studio instance (must end with /v1)
     - Example: `http://192.168.1.50:1234` or `https://lmstudio.example.com/v1`
   - **API Key**: Your API key for authentication (optional)
4. Click **Add server**

### Editing an Existing Server

1. Open the Servers menu
2. Click the pencil (✏️) icon next to a server entry
3. Modify any fields including the API key
4. Click **Save** to apply changes

### Switching Between Servers

Click on any server in the list to switch your active connection. The extension will automatically use the configured API key for that server.

## Technical Details

### Modified Files

1. `src/connection.ts` - Added `apiKey` field to `LmServer` interface and updated methods
2. `src/shared.ts` - Updated message types to include optional `apiKey`
3. `src/lmstudio/client.ts` - Added API key handling in `LMStudioClient`
4. `src/webview/main.ts` - Updated UI with API key input fields and edit modal
5. `src/opencode/serverManager.ts` - Passes API key to OpenCode provider configuration

### API Request Headers

When an API key is configured, all requests to the LM Studio server include:
```typescript
{
  'Authorization': 'Bearer <API_KEY>',
  'X-API-Key': '<API_KEY>'
}
```

### Server Storage

Server configurations (including API keys) are stored in VS Code's global storage at:
- Linux: `~/.config/Code/User/globalStorage/lmstudio-code/`
- macOS: `~/Library/Application Support/Code/User/globalStorage/lmstudio-code/`
- Windows: `%APPDATA%\Code\User\globalStorage\lmstudio-code\`

## Compatibility

This feature is backward compatible with existing server configurations:
- Servers without API keys continue to work normally
- Existing servers will have their API key field set to `undefined` initially

## Testing

### Prerequisites
- Node.js 20+ (with npm)
- VS Code Extension Manager (`@vscode/vsce`)

### Build and Package Steps

1. **Install dependencies** (first time only):
   ```bash
   npm install
   ```

2. **Bundle the opencode binary**:
   ```bash
   npm run bundle:opencode
   ```
   
   This downloads the platform-specific opencode binary (~142 MB).

3. **Compile TypeScript code**:
   ```bash
   npm run compile
   ```

4. **Package as VSIX**:
   ```bash
   vsce package
   ```
   
   This creates a `.vsix` file in your current directory (approximately 50 MB with bundled binary).

### Installing and Testing

1. **Install the VSIX file in VS Code**:
   - Open VS Code
   - Go to Extensions (Ctrl+Shift+X)
   - Click the three dots (...) in the top-right
   - Select "Install from VSIX..."
   - Choose the generated `.vsix` file

2. **Test the API key functionality**:
   - Add a new server with an API key
   - Try connecting to verify authentication works
   - Edit an existing server and add/remove API keys
   - Check that different servers use their respective API keys

3. **Verify the extension is working**:
   - Open the LM Studio panel in VS Code
   - Click the Servers menu button
   - You should see the new server with your API key indicator (••••)

### Building for Different Platforms

To build for a specific platform target:

```bash
# Linux x64
VSCE_TARGET=linux-x64 npm run package:vsix:bundled

# macOS x64
VSCE_TARGET=darwin-x64 npm run package:vsix:bundled

# Windows x64
VSCE_TARGET=win32-x64 npm run package:vsix:bundled
```

### Using the Extension in Development Mode

For active development with hot-reload:

1. Install [VS Code Extension Manager (vsce)](https://github.com/microsoft/vscode-vsce):
   ```bash
   npm install -g @vscode/vsce
   ```

2. Run the extension in development mode:
   ```bash
   code --extensionDevelopmentPath=/path/to/lmstudio-vscode-chat
   ```

This opens a new VS Code window with your modified extension loaded.

## Example Configuration

### Adding a Local LM Studio Server (No API Key)
- Name: `Local LM Studio`
- URL: `http://localhost:1234/v1`
- API Key: *(leave empty)*

### Adding a Remote LM Studio Server with API Key
- Name: `Remote Workstation`
- URL: `https://lmstudio.workstation.local:1234/v1`
- API Key: `sk-1234567890abcdef`

## Troubleshooting

### Authentication Failed Errors
If you see authentication errors:
1. Verify the API key is correct (check for typos or extra spaces)
2. Check that your LM Studio instance supports API key authentication
3. Some servers may require a specific header format - the extension sends both `Authorization: Bearer` and `X-API-Key`

### Server Not Connecting
If a server with an API key isn't connecting:
1. Verify the URL is correct (should end with `/v1`)
2. Check that the API key was saved correctly (edit the server to verify)
3. Try removing and re-adding the server with the correct credentials

## Future Enhancements

Potential future improvements:
- UI to rotate/regenerate API keys
- Support for different authentication schemes (basic auth, etc.)
- Environment variable substitution in API keys (`${MY_API_KEY}`)
- Per-request token caching for better performance
