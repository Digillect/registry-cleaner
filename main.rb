$LOAD_PATH.unshift(__dir__, File.join(__dir__, 'src'))

require 'rubygems'
require 'bundler/setup'

Bundler.require(:default)

require 'active_support'
require 'active_support/dependencies'

ActiveSupport::Dependencies.autoload_paths += %w[src]

SemanticLogger.default_level = ENV.fetch('LOG_LEVEL', 'info')
SemanticLogger.add_appender(io: STDOUT, formatter: ENV.fetch('LOG_FORMATTER', nil)&.to_sym)

Thread.current.name = 'main'

logger = SemanticLogger['Main']
configuration = Configuration.new

unless configuration.registries?
  logger.info('No registries to clean has been defined in configuration file')

  exit(0)
end

unless configuration.scanners?
  logger.info('No scanners to scan has been defined in configuration file')

  exit(0)
end

images_scanner = ImagesScanner.new(configuration)

images_to_keep = images_scanner.scan

images_cleaner = ImagesCleaner.new(configuration, images_to_keep)

exit(images_cleaner.clean ? 0 : 1)
