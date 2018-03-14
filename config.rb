# Modify the feed parameters here
Feeds = [
  "https://forum.revolutionarygamesstudio.com/posts.rss"
]

# Time to wait after parsing feeds is complete before doing again
UpdateEveryNSeconds = 120

CustomUserName = nil

# Don't touch these settings
WebhookURL = ENV["WEBHOOK_URL"]

if WebhookURL
  match = WebhookURL.match(/.*\/webhooks\/(\d+)\/.*$/i)
else
  match = nil
end

if !WebhookURL || !match
  abort "No webhook url (WEBHOOK_URL) environment variable set"
end

# Extract what probably is the important parameter in it
WebhookMajorParameter = match.captures[0]
