class DockerRegistry < Registry
  def initialize(hostname, config)
    super(hostname, config)

    @url = config_value(config, 'url')

    username = config_value(config, 'username')
    password = config_value(config, 'password')
    widen_scope = config['widen_scope']
    ssl_verify_peer = config['ssl_verify_peer']

    @client = DockerRegistryClient.new(username, password, widen_scope, ssl_verify_peer)

    @logger = SemanticLogger[DockerRegistry]
  end

  def load_images(namespaces)
    images = []

    repositories.each do |repository|
      next unless namespaces.any? { |ns| repository.start_with?(ns) }

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
  rescue StandardError => err
    @logger.error("Unable to load images: #{err}")
  end

  def delete_image(image)
    digest = tag_digest(image.namespaced_name, image.tag)

    @client.execute("#{@url}/v2/#{image.namespaced_name}/manifests/#{digest}", :delete)
  end

  private

  def repositories
    @logger.info("Getting list of repositories from #{id}")

    repositories = []

    @client.paged_get("#{@url}/v2/_catalog") do |json|
      repositories.concat(json[:repositories]) if json[:repositories]
    end

    repositories
  end

  def tags(repository)
    @logger.debug("Getting list of tags for repository #{hostname}#{repository}")

    tags = []

    @client.paged_get("#{@url}/v2/#{repository}/tags/list") do |json|
      tags.concat(json[:tags]) if json[:tags]
    end

    tags
  rescue RestClient::Unauthorized
    @logger.error("Unable to get list of tags for repository #{hostname}#{repository}")

    []
  end

  def tag_digest(repository, tag)
    response = @client.get("#{@url}/v2/#{repository}/manifests/#{tag}", accept: 'application/vnd.docker.distribution.manifest.v2+json')

    response.headers[:docker_content_digest]
  end
end
