class DockerRegistry < Registry
  def initialize(hostname, config)
    super(hostname, config)

    @url = config_value(config, 'url')

    username = config_value(config, 'username')
    password = config_value(config, 'password')

    @client = DockerRegistryClient.new(username, password)

    @logger = SemanticLogger[DockerRegistry]
  end

  def load_images
    images = []

    repositories.each do |repository|
      @logger.debug("Processing repository #{repository}")

      tags(repository).each do |tag|
        @logger.debug("Processing tag #{tag}")

        image_name = "#{repository}:#{tag}"

        next if should_ignore_image?(image_name)

        @logger.debug("Recording image #{image_name}")

        images << Image.new(repository, tag)
      end
    end

    images
  end

  def delete_image(image)
    digest = tag_digest(image.name, image.tag)

    @client.execute("#{@url}/v2/#{image.name}/manifests/#{digest}", :delete)
  end

  private

  def repositories
    @logger.info("Getting list of repositories from #{id}")

    repositories = []

    @client.paged_get("#{@url}/v2/_catalog") do |json|
      repositories.concat(json[:repositories])
    end

    repositories
  end

  def tags(repository)
    @logger.debug("Getting list of tags for repository #{hostname}#{repository}")

    tags = []

    @client.paged_get("#{@url}/v2/#{repository}/tags/list") do |json|
      tags.concat(json[:tags])
    end

    tags
  end

  def tag_digest(repository, tag)
    response = @client.get("#{@url}/v2/#{repository}/manifests/#{tag}", accept: 'application/vnd.docker.distribution.manifest.v2+json')

    response.headers[:docker_content_digest]
  end
end
