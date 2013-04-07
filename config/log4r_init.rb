require 'log4r'
require 'log4r/yamlconfigurator'
require 'log4r/outputter/fileoutputter'
require 'log4r/outputter/datefileoutputter'

##
# Log4r configuration is written in YAML.
#
# We want to have the following outputs depending on the Rails environment:
#
# - testing outputs to a single file, truncated on startup
# - development outputs to stdout and also to a single file truncated on startup
# - staging outputs to a daily rolling file
# - production outputs to a daily rolling file
#
# However this causes some problems. It seems that Log4r creates the files as soon as the outputters are instantiated,
# despite never writing to some of them (e.g. production and staging daily files are created every time the development
# environment is started, despite always staying at size zero).
#
# The problem is even worse in the Travis-CI environment. In Travis the "log" directory is not writable, and the build
# immediately fails.
#
# The desired solution is to have some outputters instanced depending on the Rails environment. Sadly, Log4r has no support
# for this behaviour.
#
# Therefore we've opted for making the Log4r config an ERB file. We use Ruby code inside the config file to make some
# sections of the file optional depending on the Rails environment. This means that first we load the file through the
# ERB class and the result is passed to the YML parser before being handed to Log4r. The final config only has those
# outputters that make sense for the current environment, because ERB does not output those that belong to other
# environments.

config_file = File.read File.join(File.dirname(__FILE__), 'log4r.yml.erb')
log4r_config = YAML.load(ERB.new(config_file).result)
Log4r::YamlConfigurator.decode_yaml(log4r_config['log4r_config'])
Openreader::Application.config.logger = Log4r::Logger[Rails.env]