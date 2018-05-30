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

    return default unless value

    value.gsub(/\$\{[A-Za-z_][A-Za-z0-9_\.]*\}/) { |var| ENV.fetch(var[2..-2], '').rstrip }
  end
end
