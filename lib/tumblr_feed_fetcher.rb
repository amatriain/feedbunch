# frozen_string_literal: true

require 'rest_client'

##
# This class fetches Tumblr feeds. It gets around the interstitial GDPR compliance page that since May 2018
# keeps Tumblr feeds from being fetched with RestClient, by using a full-featured headless browser to download
# it and click on the "Ok" button to access the actual feed.

class TumblrFeedFetcher

  ##
  # Fetch a Tumblr URL. Attempts to fetch it with a full headless browser, and if the response is an interstitial
  # GDPR compliance page, click on the "OK" button to access the actual feed or website.
  #
  # Receives as argument the url to fetch.
  #
  # Returns an object compatible with RestClient::Response object containing the response, which may be the feed XML or
  # an HTML document that will be handled by other methods.

  def self.fetch_feed(url)
    Rails.logger.info "URL #{url} belongs to a Tumblr domain possibly with a GDPR interstitial page, using a full browser to fetch it"
    opts = Selenium::WebDriver::Chrome::Options.new
    opts.add_argument '--headless'
    browser = Selenium::WebDriver.for :chrome, options: opts
    browser.get url

    # Check if we've fetched the GDPR interstitial page
    begin
      #  Look for the div that tells us this is the GDPR interstitial page. If it isn't present,
      # #find_element raises a NoSuchElementError and we don't have to do anything more with the response
      browser.find_element :xpath, '//div[@data-view="guce-gdpr"]//div[@class="guce-consent-form"]'

      # Click on the OK button to access the actual content
      interstitial_url = browser.current_url
      browser.find_element(:xpath, '//div[@class="final-btn-consent"]//button[@class="btn yes"]').click

      wait = Selenium::WebDriver::Wait.new timeout: 20
      wait.until {
        # Wait until actual content is loaded, or a timeout happens
        browser.current_url != interstitial_url
      }
    rescue Selenium::WebDriver::Error::NoSuchElementError => e
      # Tumblr didn't send us the GDPR interstitial page, return whatever they've sent us
      Rails.logger.info "Tumblr URL #{url} has returned the actual content, not the GDPR interstitial page"
    end

    feed_response = browser.page_source
    # some methods necessary later, to emulate a RestClient response
    feed_response.define_singleton_method :headers do
      return []
    end

    return feed_response
  rescue Selenium::WebDriver::Error::TimeOutError => eTimeout
    Rails.logger.info "Cannot access Tumblr URL #{url} even using a full browser to get around the interstitial GDPR page"
    # if after all the full browser cannot get the feed, raise a RestClient error
    raise RestClient::ServiceUnavailable.new
  ensure
    # close browser explicitly, otherwise it stays running even after worker stops
    browser.quit
  end
end