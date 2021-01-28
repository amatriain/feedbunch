# Configure headless browser that will be used when fetching certain feeds that cannot be fetched with a basic
# HTTP client.

# The HEADLESS_BROWSER_LOCATION environment variable controls where the headless browser is running. It accepts
# the values "local" (the default) and "remote".
# If "local", FeedBunch tries to start a headless chromium instance in the same machine it runs. Chromium and
# its Selenium WebDriver must be installed locally.
# If "remote", FeedBunch connects to a remote Chrome instance awaiting Selenium commands. The easiest way to run
# a remote Chrome instance is the selenium/standalone-chrome Docker image.
#
# If using a remote browser, the HEADLESS_BROWSER_HOST and HEADLESS_BROWSER_PORT environment variables control the
# host and port where the browser is listening for Selenium commands, respectively. They default to host 127.0.0.1 and
# port 4444.

headless_browser_location = ENV.fetch("HEADLESS_BROWSER_LOCATION") { "local" }
if headless_browser_location == 'remote'
  Feedbunch::Application.config.headless_browser_location = 'remote'

  browser_host = ENV.fetch("HEADLESS_BROWSER_HOST") { "127.0.0.1" }
  Feedbunch::Application.config.headless_browser_host = browser_host

  browser_port = ENV.fetch("HEADLESS_BROWSER_PORT") { "4444" }
  Feedbunch::Application.config.headless_browser_port = browser_port
else
  Feedbunch::Application.config.headless_browser_location = 'local'
end
