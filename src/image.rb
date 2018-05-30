class Image
  def initialize(name, tag = nil, data = {})
    if tag.is_a?(Hash)
      data = tag
      tag = nil
    end

    name = name + ':' + tag if tag
    @data = data

    parse_name(name)
  end

  attr_reader :registry, :namespace, :name, :tag, :literal_tag, :data

  def full_name_without_tag
    @full_name_without_tag ||= [@registry, @namespace, @name].compact.join('/')
  end

  def full_name
    @full_name ||= [full_name_without_tag, @tag].compact.join(':')
  end

  def namespaced_name
    @namespaced_name ||= [@namespace, @name].compact.join('/')
  end

  def namespaced_name_with_tag
    @namespaced_name_with_tag ||= [namespaced_name, @tag].compact.join(':')
  end

  private

  def parse_name(image_name)
    parts = image_name.downcase.split('/')

    if parts.length == 1
      # <name>
      # <name>:<tag>
      @registry = nil
      @namespace = nil

      name_and_tag = parts[0]
    else
      if parts[0].include?('.') || parts[0].include?(':') || parts[0] == 'localhost'
        @registry = parts.shift
      end

      name_and_tag = parts.pop

      @namespace = parts.join('/')
    end

    parts = name_and_tag.split(':')

    @name = parts.shift
    @tag = parts.empty? ? 'latest' : parts[0]
    @literal_tag = parts.empty? ? nil : parts[0]
  end
end
