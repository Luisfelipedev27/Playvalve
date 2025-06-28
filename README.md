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

## Flowchart

![Screenshot 2025-06-28 at 02 37 57](https://github.com/user-attachments/assets/0aa3c910-08b3-4927-b01a-9cd45f46d760)

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
## Final Thoughts

I have worked on large projects with millions of users, so I know the challenges very well. I know how to deal with problematic, slow and non-performing endpoints. I know how to work with Redis and Sidekiq, dealing with Jobs running in the background. I also know how to deal very well with microservices, having worked on multiple repositories that often complement each other through http requests. My main skill is not just writing code in Ruby on Rails, but solving real problems.

I thank you in advance for the opportunity.
