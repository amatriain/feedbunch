# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
Nothing so far.

## [1.1.1] - 2020-01-12
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