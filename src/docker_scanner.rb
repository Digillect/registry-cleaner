class DockerScanner
  def initialize(configuration)
    @configuration = configuration

    @logger = SemanticLogger[DockerScanner]
  end

  def scan
    connect_to_docker

    containers = Docker::Container.all

    containers.each do |container|
      @logger.debug("Container: #{container.id}: #{container.info['Image']}")

      yield container.info['Image'] if block_given?
    end
  end

  private

  def connect_to_docker
    url = @configuration[:url]

    Docker.url = url unless url.nil?
  end
end
