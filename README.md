# Playvalve Security Checker API

A Ruby on Rails 7 API-only application for fraud detection and user security validation. This system performs multi-layered security checks to determine if users should be banned based on geographic location, device security, and network anonymization detection.

## Key Features
- Country-based access control with Redis whitelist
- Rooted/jailbroken device detection
- VPN/Proxy/Tor/Relay detection via VPNAPI.io
- 24-hour caching for performance optimization

## Prerequisites
- ruby 3.2.2
- Rails 7.1.3
- PostgreSQL 12+
- Redis 6+
- VPNAPI.io API key (get from https://vpnapi.io/)

# Setup Instructions

## Environment Variables

Create a `.env` file in the root directory with the following variable:

```bash
# VPNAPI.io Configuration
# Get your API key from: https://vpnapi.io/
VPNAPI_KEY=
```

## Setup Steps

1. **Install dependencies:**
   ```bash
   bundle install
   ```

2. **Setup database:**
   ```bash
   rails db:create
   rails db:migrate
   ```

3. **Setup Redis country whitelist:**
   ```bash
   rails redis:setup_country_whitelist
   ```

4. **Start the server:**
   ```bash
   rails server
   ```

## Testing

Run the test suite:
```bash
bundle exec rspec
```

## API Usage

Test the endpoint with the provided Postman collection or:

```bash
curl -X POST http://localhost:3000/v1/user/check_status \
  -H "Content-Type: application/json" \
  -H "CF-IPCountry: US" \
  -d '{"idfa": "8264148c-be95-4b2b-b260-6ee98dd53bf6", "rooted_device": false}'
```

## Future Improvements
- Enhanced Test Coverage
  - I would like to expand the test suite with additional scenarios including edge cases for malformed API responses, network timeouts and Redis failures
- Code Quality with RuboCop
  - Adding RuboCop would improve code consistency and maintainability by enforcing Ruby style guidelines and catching potential bugs automatically.
- JSON Rendering with Jbuilder
  - While I considered using Jbuilder, the current simple API responses ({"ban_status": "banned"}) made direct JSON rendering more appropriate. For future endpoints with complex nested data structures, Jbuilder would provide better organization and maintainability of JSON templates.
- VCR for External API Testing
  - I would prefer implementing VCR for testing external API interactions instead of relying heavily on mocks, as I've worked with it before. -> [https://github.com/vcr/vcr]


