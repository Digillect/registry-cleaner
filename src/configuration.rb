class Configuration
  def initialize
    @logger = SemanticLogger[Configuration]

    file = open_file

    return unless file

    load_registries(file)
    load_scanners(file)
  end

  attr_reader :scanners

  def registries?
    !@registries.empty?
  end

  def find_registry_by_id(id)
    @registries[id]
  end

  def find_registry_by_image_name(image_name)
    @registries.values.find { |registry| image_name.start_with?(registry.hostname) }
  end

  def scanners?
    !@scanners.empty?
  end

  private

  def open_file
    path = ENV.fetch('CONFIG_FILE', 'config.yaml')

    return nil unless File.exist?(path)

    YAML.load_file(path)
  rescue StandardError => err
    @logger.error("Unable to load configuration from #{path}: #{err}")

    nil
  end

  def load_registries(file)
    @registries = {}

    return unless file['registries']

    file['registries'].each_pair do |hostname, config|
      kind = config['kind'] || 'docker'

      unless kind
        @logger.error("Invalid definition of registry #{hostname}: registry kind is not specified")

        next
      end

      registry = create_registry(kind, hostname, config)

      @registries[hostname] = registry if registry
    end
  end

  def create_registry(kind, hostname, config)
    # noinspection RubyResolve
    require "#{kind.downcase}_registry"

    klass = "#{kind.capitalize}Registry".safe_constantize
    registry = nil

    if klass
      begin
        registry = klass.new(hostname, config)
      rescue StandardError => err
        @logger.error("Unable to create registry #{hostname}: #{err}")
      end
    else
      @logger.error("#{kind.humanize} registry is not supported (yet)")
    end

    registry
  end

  def load_scanners(file)
    @scanners = []

    return unless file['scanners']

    file['scanners'].each do |scanner_config|
      kind = scanner_config['kind']

      unless kind
        @logger.error('Invalid definition of scanner: scanner kind is not specified')

        next
      end

      scanner = create_scanner(kind, scanner_config)

      @scanners << scanner if scanner
    end
  end

  def create_scanner(kind, configuration)
    # noinspection RubyResolve
    require "#{kind.downcase}_scanner"

    klass = "#{kind.capitalize}Scanner".safe_constantize
    scanner = nil

    if klass
      begin
        scanner = klass.new(configuration)
      rescue StandardError => err
        @logger.error("Unable to create #{kind.humanize} scanner: #{err}")
      end
    else
      @logger.error("#{kind.humanize} scanner is not supported (yet)")
    end

    scanner
  end
end
