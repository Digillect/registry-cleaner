class Image
  def initialize(name, tag, data = {})
    @name = name
    @tag = tag
    @data = data
  end

  attr_reader :name, :tag, :data
end
