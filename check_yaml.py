import requests
import json

api_key = "6b684c27-140a-4ff1-be4b-c3f61b7ea738"
base_url = "https://us2.api.insight.rapid7.com/vm/v4/integration/assets"
headers = {
    "X-Api-Key": api_key,
    "Content-Type": "application/json",
    "Accept": "application/json"
}

body = {
    "asset": None,
    "vulnerability": None
}

# First page
response = requests.post(
    f"{base_url}?size=100&page=0",
    headers=headers,
    json=body
)

print(f"Status: {response.status_code}")

try:
    data = response.json()
    
    # If error response, print it
    if response.status_code >= 400:
        print(f"\nError response:")
        print(json.dumps(data, indent=2))
    else:
        # Print full response structure to understand pagination
        print(f"\nResponse keys: {list(data.keys())}")
        
        # Check pagination metadata
        if "metadata" in data:
            print(f"\nPagination metadata:")
            print(json.dumps(data["metadata"], indent=2))
            print(f"Page number: {data['metadata'].get('number')}")
            print(f"Total pages: {data['metadata'].get('totalPages')}")
            print(f"Total assets: {data['metadata'].get('totalResources')}")
            print(f"Page size: {data['metadata'].get('size')}")
        else:
            print("\nNo 'metadata' key found in response")
            print("Full response structure (first level):")
            for key, value in data.items():
                if isinstance(value, (list, dict)):
                    print(f"  {key}: {type(value).__name__} with {len(value) if hasattr(value, '__len__') else 'N/A'} items")
                else:
                    print(f"  {key}: {value}")

        # Preview first asset
        if "data" in data and len(data["data"]) > 0:
            print(f"\nTotal assets in response: {len(data['data'])}")
            print(f"\nFirst asset sample:")
            print(json.dumps(data["data"][0], indent=2))
except json.JSONDecodeError:
    print(f"\nResponse text (not JSON):")
    print(response.text)
