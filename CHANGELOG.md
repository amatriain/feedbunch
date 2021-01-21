# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Changed 
Nothing yet

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
