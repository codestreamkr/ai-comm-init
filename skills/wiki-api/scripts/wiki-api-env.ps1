# Wiki API environment sample.
# Copy or adapt this file in a private location and fill in real values.
# Do not store real tokens in the skill directory.

$env:WIKI_API_BASE_URL = "https://example.atlassian.net/wiki"
$env:WIKI_API_AUTH_TYPE = "bearer"
$env:WIKI_API_TOKEN = "replace-with-issued-token"

$env:WIKI_API_DEFAULT_SPACE = "MSN"
$env:WIKI_API_RAW_DIR = ".wiki/raw/wiki-api"

# Optional. Defaults to "$WIKI_API_BASE_URL/rest/api".
# $env:WIKI_API_ROOT = "https://example.atlassian.net/wiki/rest/api"

# Basic auth fallback.
# $env:WIKI_API_AUTH_TYPE = "basic"
# $env:WIKI_API_USER = "user@example.com"
# $env:WIKI_API_PASSWORD = "replace-with-api-token-or-password"

