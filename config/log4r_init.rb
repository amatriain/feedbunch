require 'log4r'
require 'log4r/yamlconfigurator'
require 'log4r/outputter/fileoutputter'
require 'log4r/outputter/datefileoutputter'

log4r_config = YAML.load_file(File.join(File.dirname(__FILE__), 'log4r.yml'))
Log4r::YamlConfigurator.decode_yaml(log4r_config['log4r_config'])
Openreader::Application.config.logger = Log4r::Logger[Rails.env]