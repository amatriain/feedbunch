# Load blacklisted URLs from the YAML config file.
# If the config file changes the server must be restarted to pick up changes.

list = YAML.load_file 'config/url_blacklist.yml'
Rails.application.config.url_blacklist = list['aede_urls']
