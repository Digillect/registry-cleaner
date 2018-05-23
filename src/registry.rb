class Registry
  def initialize(hostname, config)
    @id = hostname
    @hostname = hostname + '/'
    @images_to_ignore = (config['ignore'] || []).map { |pattern| Regexp.new(pattern) }
  end

  attr_reader :id, :hostname, :images_to_ignore

  def should_ignore_image?(image_name)
    images_to_ignore.any? { |regex| regex =~ image_name }
  end

  protected

  def config_value(config, name, default = nil)
    value = config[name]

    return value if value

    value = config["#{name}From"]

    return default unless value

    ENV.fetch(value, default)&.rstrip
  end
end
