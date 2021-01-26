# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Changed 
- Removed all functionality related to sharing in social networks. Integration with social networks is now considered
out of scope for this project.

## [1.3.24] - 2021-01-24
### Fixed
- Correct path to connect to remote browser.

## [1.3.23] - 2021-01-24
### Fixed
- When opening selenium connection to a remote browser, set the uri scheme after setting the uri host, otherwise
an error is raised.

## [1.3.22] - 2021-01-24
### Changed
- FeedBunch can use a remote browser instance that is listening for Selenium connections instead of a local
Chromium instance. A full browser is used for fetching certain feeds that cannot be fetched with a simple HTTP
client. This behavior is controlled by the HEADLESS_BROWSER_LOCATION env variable: if "local" (the default) a 
local Chromium instance is used, if "remote" a remote browser is used instead. If using a remote browser the
HEADLESS_BROWSER_HOST ("127.0.0.1" by default) and HEADLESS_BROWSER_PORT (4444 by default) can be used to set
the host/port where the browser is listening for remote Selenium connections. 

## [1.3.21] - 2021-01-24
### Changed
- Removed monkeypatch that disable advisory locking in postgresql during migrations. This was necessary when
connecting to postgresql through pgbouncer, but it's no longer necessary in a dockerized environment.
- Removed travis-ci config file.
- Removed capistrano (and its config) from the app. Deployments will no longer be managed with capistrano 
but with docker commands instead.

## [1.3.20] - 2021-01-24
### Changed
- Removed all usage of NewRelic

## [1.3.19] - 2021-01-24
### Changed
- Removed distinction between "free" and "paid" users. Users have never had to pay.
### Fixed
- Rails env is not unconditionally set to production by the devise initializer anymore.

## [1.3.18] - 2021-01-22
### Changed 
- Removed the unused "staging" environment.
- Removed blacklisted hosts. The capability for FeedBunch to blacklist hosts, keeping users from 
subscribing to feeds in those hosts, is still implemented, but the list is empty in the default
installation.

## [1.3.17] - 2021-01-22
### Changed 
- Public signup of new users can be enabled or disabled with the SIGNUPS_ENABLED environment variable.
They are enabled by default.
- Removed the message about FeedBunch being an open beta.

## [1.3.16] - 2021-01-22
### Changed
- Email used to send admin emails (OPML import/export failure notifications, Devise emails...) is parametrizable
with the ADMIN_EMAIL env var. It takes the value admin@feedbunch.com by default.

## [1.3.15] - 2021-01-22
### Fixed
- Fixed a bug that crashed the app when displaying certain pages if the demo user was disabled.

## [1.3.14] - 2021-01-21
### Changed
- The DEMO_USER_ENABLED env variable controls whether the demo user is enabled or not. Enabled by default.
- The demo user is fully configured only if it's actually enabled.
- The ResetDemoUserWorker sidekiq worker is scheduled to run hourly only if the demo user is enabled. If
it's disabled it's never scheduled.

## [1.3.13] - 2021-01-21
### Fixed
- Fixed setting default scheme and host for links inside emails sent by the app with the EMAIL_LINKS_URL
env variable. 

## [1.3.12] - 2021-01-21
### Changed
- The EMAIL_LINKS_URL env variable can be used to control base URL in links inside emails sent by the app.
By default it takes the value "https://www.feedbunch.com".

## [1.3.11] - 2021-01-17
### Fixed
- Disable sending a confirmation email when a user is created non-interactively with script/create_user.rb
The right way to do it is the .skip_confirmation! method, not trying to disable ActiveMailer email delivery.

## [1.3.10] - 2021-01-17
### Changed
- Add script in script/create_user.rb to create users non-interactively. Can be used e.g. to populate the first 
admin user in a new installation.

## [1.3.9] - 2021-01-14
### Fixed
- Allow Sidekiq server to connect to a Redis instance in a different host/port than localhost/6379. The
problem was that two invocations to Sidekiq.configure_server were made (once to set Redis host and port, and
a second time to configure Cron jobs), and it seems Sidekiqs resets all server config to its default values
every time configure_server is invoked, discarding the changes in the first invokation.

## [1.3.8] - 2021-01-06
### Changed
- Removed facebook app ID from configuration, it's not been used for years.
- Make uploads behavior parametrizable through env variables; either store uploads locally, or use
an AWS S3 bucket.

## [1.3.7] - 2021-01-04
### Changed
- The port and authentication method of the external SMTP server used to send emails is parametrizable
with the ```smtp_port``` and  ```smtp_authentication``` values in ```secrets.yml```.

## [1.3.6] - 2020-11-24
### Changed
- The FEEDBUNCH_LOG_LEVEL env variable can be used to control the log level in production. By default
it takes the value "warn".

## [1.3.5] - 2020-11-18
### Changed
- Use FORCE_SECURE env variable instead of FORCE_SSL. It not only controls forcing SSL, but also forcing
the use of secure cookies and HSTS.

## [1.3.4] - 2020-11-15
### Changed
- The FORCE_SSL env variable can be used to control the force_ssl rails flag, forcing connections, 
cookies etc to use secure connections only. This behavior is enabled by default.

## [1.3.3] - 2020-11-12
### Changed
- If the PORT env variable is set, FeedBunch binds to that TCP port in all network interfaces. 
If it's not set, FeedBunch binds to a local unix socket and will need a webserver frontend (e.g. nginx) to 
accept requests.

## [1.3.2] - 2020-11-10
### Changed
- Allow the log file where Puma writes to be configured via the STDOUT_FILE and STDERR_FILE env variables. 
The default is the same path as before.

## [1.3.1] - 2020-11-10
### Changed
- Allow the release path used by Puma to be configured via the APP_DIR env variable. 
The default is the same path as before.

## [1.3.0] - 2020-10-08
### Changed
- Updated ruby version to 2.7.2
- Updated rails to 6.0.3.2

## [1.2.1] - 2020-06-09
### Changed
- Updated rails to 6.0.3

## [1.2.0] - 2020-04-15
### Changed
- Updated ruby version to 2.7.1
- Updated rails to 6.0.2.2

## [1.1.4] - 2020-01-26
### Fixed
- Intermittent error (undefined method 'headers' for Array) when subscribing to a feed.

## [1.1.3] - 2020-01-23
### Fixed
- Error when fetching special feeds (String was used instead of the actual class).

## [1.1.2] - 2020-01-12
### Changed
- Upgraded to Rails 6.0.2.1.
- Removed warnings during app initialization related to Zeitwerk.

## [1.1.1] - 2020-01-06
### Changed
- Updated config files to align with Rails 6 defaults.

## [1.1.0] - 2020-01-06
### Changed
- Updated Rails to 6.0.0.

## [1.0.3] - 2020-01-02
### Changed
- Use built-in redis cache store, instead of redis-rails gem.

## [1.0.2] - 2020-01-02
### Changed
- Use rbenv instead of rvm to manage project rubies.
- Updated Rails to 5.2.4.1.

## [1.0.1] - 2019-12-31
### Changed
- Updated gem dependencies.
- Ruby version updated to 2.7.

### Fixed
- Fixed errors caused by behavior changes in Feedjira 3.1.0.
- Removed deprecation warnings after update to Ruby 2.7.
- Removed deprecation warnings from Capistrano.

## [1.0] - 2019-11-12
First stable version.

Project is hosted in [gitlab](https://gitlab.com/amatriain/feedbunch), 
with a [github](https://github.com/amatriain/feedbunch) repo as a read-only mirror.
