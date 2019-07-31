class NexusRegistry < Registry
  def initialize(hostname, config)
    super(hostname, config)

    # TODO: add config validation
    url = config_value(config, 'url')
    username = config_value(config, 'username')
    password = config_value(config, 'password')

    @nexus_client = NexusClient.new(url, username, password)
    @repository = config_value(config, 'repository')

    @logger = SemanticLogger[NexusRegistry]
  end

  def load_images(namespaces)
    images = []

    @logger.debug("Loading components from repository #{@repository}")

    @nexus_client.components(@repository) do |item|
      name = item[:name]

      next unless namespaces.any? { |ns| name.start_with?(ns) }

      tag = item[:version] || 'latest'
      assets = item[:assets]&.map { |asset| asset[:id] }

      next if assets.blank?
      next if should_ignore_image?("#{name}:#{tag}")

      images << Image.new(name, tag, assets: assets)
    end

    images
  end

  def delete_image(image)
    image.data[:assets].each do |asset_id|
      @logger.debug("Deleting asset #{asset_id}")

      @nexus_client.delete_asset(asset_id)
    end
  end
end
