# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Changed
- Switched from RVM to Rbenv to manage Ruby versions.
- Use built-in redis cache for rails view fragments instead of redis-rails gem

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