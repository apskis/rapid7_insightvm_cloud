# Rapid7 InsightVM Cloud Integration for ThreatQ

This integration enables ThreatQ to automatically ingest vulnerability data from Rapid7 InsightVM Cloud (formerly Nexpose), creating Asset objects with associated CVE indicators.

## Version Information

- **Integration Version**: 1.3.0
- **ThreatQ Compatibility**: 5.10.0+
- **Last Updated**: 2025-10-15
- **Type**: Commercial Integration (CDF)

## Overview

The Rapid7 InsightVM Cloud integration connects ThreatQ to Rapid7's Cloud Platform API to retrieve:

- **Assets** (hosts/devices) with detailed vulnerability information
- **CVE Indicators** linked to affected assets
- **Tags and Attributes** from Rapid7 (site tags, asset tags, custom tags)
- **Scan History** including last scan times and vulnerability counts
- **Risk Scores** and severity classifications

## Requirements

### Rapid7 Requirements

1. **Rapid7 Platform API Key** (Organization or User Key)
   - Generate at: https://insight.rapid7.com/platform#/apiKeyManagement
   - Must have **"Read"** permissions for InsightVM

2. **API Base URL** for your Rapid7 region:
   - US: `https://us.api.insight.rapid7.com/vm/v4`
   - US2: `https://us2.api.insight.rapid7.com/vm/v4`
   - EU: `https://eu.api.insight.rapid7.com/vm/v4`
   - Canada: `https://ca.api.insight.rapid7.com/vm/v4`
   - Australia: `https://au.api.insight.rapid7.com/vm/v4`
   - Japan: `https://ap.api.insight.rapid7.com/vm/v4`

   **To find your API base URL:**
   1. Check your login URL: `https://<region>.insight.rapid7.com`
   2. Your API base URL is: `https://<region>.api.insight.rapid7.com/vm/v4`

### ThreatQ Requirements

- ThreatQ Platform version 5.10.0 or higher
- Root/sudo access to ThreatQ server (for Asset custom object installation)
- Administrator privileges in ThreatQ UI

## Installation

### Step 1: Install the Asset Custom Object

The integration requires a custom "Asset" object type in ThreatQ. This must be installed **before** uploading the integration YAML.

#### For ThreatQ 5.x (Automated Installation)

1. Upload all files to your ThreatQ server:
   ```bash
   # Create directory
   mkdir -p /tmp/rapid7-integration
   cd /tmp/rapid7-integration
   
   # Upload files (via SCP, SFTP, or copy/paste)
   # - install.sh
   # - asset.json
   # - images/asset.svg
   ```

2. Make the installation script executable:
   ```bash
   chmod +x install.sh
   ```

3. Run the installation script:
   ```bash
   sudo ./install.sh
   ```

   The script will:
   - Check if Asset object already exists (skips if found)
   - Enter maintenance mode
   - Copy files to ThreatQ directories
   - Install the custom object
   - Configure the icon
   - Update permissions
   - Restart services
   - Exit maintenance mode

4. Verify installation:
   - Log into ThreatQ (refresh browser if already logged in)
   - Check that "Asset" appears in object type dropdowns

#### For ThreatQ 6.x (Manual Installation)

ThreatQ 6.x requires manual custom object creation through the UI:

1. Log into ThreatQ as an administrator
2. Navigate to **System Configuration > Object Management > Custom Objects**
3. Click **Add Custom Object**
4. Fill in the following details:
   - **Code**: `asset`
   - **Name**: `Assets`
   - **Description**: `An object defining an asset of an organization. Assets represent IT infrastructure such as servers, workstations, network devices, and other systems that may have vulnerabilities.`
   - **Foreground Color**: `#ffffff`
   - **Background Color**: `#db4e4e`
5. Add fields:
   - Field 1:
     - **Name**: Title
     - **Type**: varchar(255)
     - **Required**: Yes
   - Field 2:
     - **Name**: Description
     - **Type**: text
     - **Required**: No
6. Upload the icon: `images/asset.svg`
7. Click **Save**

### Step 2: Install the Integration

1. **Download the integration YAML file**: `rapid7_insightvm_cloud.yaml`

2. **Navigate to Integrations Management** in ThreatQ:
   - Go to **Integrations > Integration Management**

3. **Upload the integration**:
   - Click **Add New Integration**
   - Drag and drop the YAML file or click to browse
   - ThreatQ will parse and validate the integration
   - Click **Install** when prompted

4. **Locate the integration**:
   - Filter by Category: **Commercial**
   - The integration will appear under the **Disabled** tab

### Step 3: Configure the Integration

1. Click on **Rapid7 insightVM Cloud - Assets** to open details

2. Go to the **Configuration** tab

3. Enter the following parameters:

   | Parameter | Description | Required | Default |
   |-----------|-------------|----------|---------|
   | **Rapid7 API Base URL** | Your full API base URL with region and version | Yes | `https://us.api.insight.rapid7.com/vm/v4` |
   | **Rapid7 Platform API Key** | Your Organization or User API key | Yes | *(none - must be entered)* |
   | **Only Ingest Vulnerable Assets** | Track only assets with vulnerabilities | No | `True` |
   | **Minimum Risk Score Threshold** | Minimum risk score required to ingest an asset | Yes | `0` |
   | **Include Unchanged Vulnerabilities** | Include CVEs that haven't changed since last scan | No | `False` |
   | **Verify SSL Certificate** | Enable SSL certificate verification | No | `True` |
   | **Disable Proxies** | Bypass proxy settings configured in ThreatQ | No | `False` |

4. Review **Additional Settings** (optional):
   - Schedule (default: runs on a recurring schedule)
   - Timeout settings
   - Retry settings

5. Click **Save**

### Step 4: Enable the Integration

1. Toggle the switch at the top of the integration details page to **Enabled**

2. The integration will begin ingesting data on its next scheduled run

3. You can manually run the integration by clicking **Run Integration** button

## Data Mapping

### Assets Created

Each asset from Rapid7 creates an **Asset** object in ThreatQ with:

- **Title**: Hostname (if available) or IP address
- **Description**: HTML-formatted vulnerability overview with counts
- **Attributes**:
  - IP Address
  - Hostname
  - Asset ID
  - insightVM Link (direct link to asset in Rapid7)
  - Operating System (full description)
  - OS Family
  - OS Vendor
  - Installed Services (aggregated)
  - Asset Type
  - Total Vulnerabilities
  - Critical Vulnerabilities count
  - Severe Vulnerabilities count
  - Moderate Vulnerabilities count
  - Exploits count
  - Malware Kits count
  - Risk Score
  - Assessed for Policies (True/False)
  - Assessed for Vulnerabilities (True/False)
  - Last Scan Start
  - Last Scan End
  - MAC Address (if available)
- **Tags**: Site tags and asset tags from Rapid7
- **Related Indicators**: CVE indicators (extracted from vulnerability data)

### CVE Indicators

CVEs discovered on assets are created as **CVE** type indicators and linked to their respective assets.

### Reports

For each asset, a report is created with:
- Title: `Rapid7 insightVM Cloud Asset Report: [Asset Name]`
- Published Date: Last scan end time
- Related Assets and Indicators

## Filtering Options

### Only Ingest Vulnerable Assets

When enabled (default), only assets with at least one vulnerability are ingested. This reduces noise from clean systems.

### Risk Score Threshold

Set a minimum risk score (0-100000+) to filter assets. Only assets meeting or exceeding this score are ingested.

### Include Unchanged Vulnerabilities

- **False** (default): Only ingests new vulnerabilities discovered since last scan
- **True**: Includes all vulnerabilities (new + existing + remediated)

## Troubleshooting

### Integration Errors

1. **401 Unauthorized**
   - Verify API key is correct and active
   - Ensure API key has "Read" permissions for InsightVM

2. **404 Not Found**
   - Verify API base URL is correct for your region
   - Check if you're using the correct API version (v4 vs v3)

3. **Asset Object Not Found**
   - Ensure Asset custom object was installed successfully
   - Check that object code is exactly `asset` (lowercase)

4. **No Assets Ingested**
   - Check "Only Ingest Vulnerable Assets" setting
   - Verify Risk Score Threshold isn't too high
   - Confirm assets exist in Rapid7 with vulnerabilities

### Logs

- **Integration Logs**: Available in ThreatQ UI under integration details
- **Installation Logs**: `/var/log/threatq/asset_object_install_[timestamp].log`

### Re-running Installation

The installation script is idempotent:
- Safe to run multiple times
- Automatically detects existing Asset object
- Skips installation if object already exists

## API Endpoints Used

This integration uses the following Rapid7 InsightVM Integration API v4 endpoints:

- `POST /vm/v4/integration/assets` - Retrieves asset data with pagination (POST with no body)
  - Includes vulnerability counts and details
  - Returns tags, services, and system information
  - Provides new, same, and remediated vulnerability arrays
  - Requires API key with "InsightVM Integration API" permissions

## Maintenance

### Updating the Integration

1. Download the latest YAML file
2. Navigate to **Integrations > Integration Management**
3. Click **Add New Integration**
4. Upload the new YAML file
5. ThreatQ will detect the existing integration and prompt for upgrade
6. Review configuration changes (if any)
7. Click **Update**

### Monitoring

- Check integration run status in **Integration Management**
- Review object counts (Assets created, Indicators created)
- Monitor for API rate limits or errors
- Review Rapid7 API usage in InsightVM console

## Security Notes

- **API Key Storage**: API keys are masked in the UI and stored encrypted
- **No Default Credentials**: Installation files contain NO hardcoded credentials
- **SSL Verification**: Enabled by default for secure API connections
- **Least Privilege**: Use Organization or User keys with minimal required permissions

## Support

For issues with:
- **Rapid7 API**: Contact Rapid7 support or consult https://help.rapid7.com/insightvm/
- **ThreatQ Integration**: Contact ThreatQ support or check https://helpcenter.threatq.com/
- **This Integration**: Review logs and verify configuration matches documentation

## File Structure

```
rapid7-insightvm-integration/
├── README.md                           # This file
├── rapid7_insightvm_cloud.yaml         # Integration definition
├── asset.json                          # Custom object definition
├── install.sh                          # Installation script (ThreatQ 5.x)
└── images/
    └── asset.svg                       # Asset object icon
```

## Changelog

### Version 1.0.9 (2025-12-02)
- Fixed pagination size parameter to use !expr tag for template_value reference
- Fixed POST request body to use body field with !json tag instead of params field
- Corrected pagination and request body configuration per ThreatQ documentation

### Version 1.0.8 (2025-12-02)
- Fixed pagination to use template_values and prev_request_params for proper page tracking
- Removed timeout from request_vars (not supported in all ThreatQ versions)
- Removed hardcoded query parameters from URL (now handled by pagination)

### Version 1.0.7 (2025-12-02)
- Fixed bug where site_names extraction referenced site_tags in the same set block
- Split site_tags and site_names into separate set operations to fix variable reference issue

### Version 1.0.6 (2025-12-02)
- Fixed pagination to fetch all assets (not just first page)
- Added Site attribute extraction from SITE-type tags (per Rapid7 API documentation)
- Sites are now properly extracted as attributes from asset tags where type="SITE"
- Updated to follow Rapid7 API v4 documentation for site handling
- Improved site attribute handling for single and multiple sites

### Version 1.3.0 (2025-10-15)
- Fixed HTTP method from POST to GET for assets endpoint
- Fixed pagination to use `totalPages` instead of `total_pages`
- Removed non-existent Site-based endpoints
- Simplified to direct asset ingestion (aligned with Rapid7 API v4)
- Added support for ThreatQ 6.x detection in install script
- Enhanced error handling and data processing
- Added `include_same_vulnerabilities` configuration option
- Improved CVE extraction from vulnerability arrays
- Enhanced attribute mapping with additional OS fields

### Version 1.2.0 (2025-10-14)
- Initial release with Site-based structure

## License

This integration is provided as a community contribution. Use at your own discretion and test thoroughly in a non-production environment before deploying.

## Author

Community Contribution