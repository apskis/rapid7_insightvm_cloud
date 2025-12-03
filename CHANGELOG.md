# Changelog

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
