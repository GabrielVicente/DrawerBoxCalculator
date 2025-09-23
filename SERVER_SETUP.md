# Hardware Data Server Setup

This guide explains how to set up a server to host your drawer hardware data remotely, allowing you to update the data without submitting new app versions.

## Server Requirements

Your server needs to host two JSON endpoints:

1. **Version Check Endpoint**: `/api/hardware/version`
2. **Hardware Data Endpoint**: `/api/hardware/data`

## Hosting Options

### Option 1: Static File Hosting (Recommended for Simple Setup)

**GitHub Pages / Netlify / Vercel:**
1. Create a repository with your JSON files
2. Host `version.json` and `server_data.json` 
3. Update `AppConfig.swift` with your URLs

**Example URLs:**
```
https://your-username.github.io/hardware-data/version.json
https://your-username.github.io/hardware-data/data.json
```

### Option 2: Simple Node.js Server

```javascript
const express = require('express');
const app = express();
const port = 3000;

// Enable CORS for your app
app.use((req, res, next) => {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Headers', 'Content-Type');
    next();
});

// Version endpoint
app.get('/api/hardware/version', (req, res) => {
    res.json({
        version: "1.0",
        lastUpdated: "2025-09-22T20:00:00Z",
        minAppVersion: "1.0",
        forceUpdate: false
    });
});

// Hardware data endpoint
app.get('/api/hardware/data', (req, res) => {
    // Load and return your server_data.json file
    const fs = require('fs');
    const data = JSON.parse(fs.readFileSync('./server_data.json', 'utf8'));
    res.json(data);
});

app.listen(port, () => {
    console.log(`Hardware data server running at http://localhost:${port}`);
});
```

### Option 3: Cloud Functions (AWS Lambda, Google Cloud Functions, etc.)

Deploy serverless functions that return your JSON data.

## File Structure

Your server should serve these files:

```
/api/hardware/
├── version.json          # Version information
└── data.json            # Complete hardware data
```

## JSON File Formats

### version.json
```json
{
  "version": "1.0",
  "lastUpdated": "2025-09-22T20:00:00Z",
  "minAppVersion": "1.0",
  "forceUpdate": false
}
```

### server_data.json
Contains the complete hardware data in the nested structure (see the generated file).

## App Configuration

Update `AppConfig.swift` with your server URLs:

```swift
#if DEBUG
static let baseURL = "https://your-dev-server.com/api/hardware"
#else
static let baseURL = "https://your-production-server.com/api/hardware"
#endif
```

## How It Works

1. **App Launch**: App tries to load cached data, falls back to bundled plist if needed
2. **Background Check**: Periodically checks version endpoint for updates
3. **Data Download**: If new version available, downloads updated hardware data
4. **Caching**: Downloaded data is cached locally for offline use
5. **Fallback**: Always falls back to bundled plist if server is unavailable

## Updating Hardware Data

To add new hardware:

1. Update your `server_data.json` file with new entries
2. Increment the version number in `version.json`
3. Update the `lastUpdated` timestamp
4. Deploy the updated files to your server

Example new entry:
```json
"Grass": {
  "NewProductLine": [
    {
      "partNumber": "NEW123",
      "standardDeductionMM": 20.0,
      "maxMaterialThicknessMM": 18.0
    }
  ]
}
```

## Security Considerations

1. **HTTPS Only**: Always use HTTPS for your server endpoints
2. **Rate Limiting**: Implement rate limiting to prevent abuse
3. **Content Validation**: Validate JSON structure server-side
4. **CDN**: Consider using a CDN for better performance and reliability

## Testing

1. **Local Testing**: Test with localhost server first
2. **Staging**: Use separate staging URLs for testing
3. **Rollback**: Keep previous versions available in case of issues
4. **Monitoring**: Monitor server logs for errors and usage patterns

## Deployment Checklist

- [ ] Server endpoints are accessible via HTTPS
- [ ] JSON files are properly formatted and valid
- [ ] CORS headers are configured correctly
- [ ] AppConfig.swift is updated with correct URLs
- [ ] Test with staging/development URLs first
- [ ] Monitor app behavior after deployment

## Troubleshooting

**Common Issues:**
- **CORS Errors**: Ensure your server sends proper CORS headers
- **JSON Format**: Validate JSON structure matches expected format
- **SSL/TLS**: Make sure HTTPS is properly configured
- **Caching**: Consider cache headers to control how long data is cached by CDNs

**App Behavior:**
- App always falls back to bundled plist if server is unreachable
- Updates are checked in background, not blocking the UI
- Failed downloads don't affect app functionality