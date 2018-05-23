class KubernetesScanner
  def initialize(configuration)
    @resource_kinds_to_ignore = configuration['ignore'] || []
    @logger = SemanticLogger[KubernetesScanner]

    @client_factory = KubernetesClientFactory.new(configuration)
  end

  def scan(&block)
    RESOURCE_DEFINITIONS.each do |kind, api_versions, *paths|
      next if @resource_kinds_to_ignore.include?(kind)

      resources = resources_of_kind(kind, api_versions)

      yield_images_of_resources(resources, paths, &block)
    end

    yield_keep_alive_images(&block)
  end

  private

  RESOURCE_DEFINITIONS = [
    [
      'CronJob', %w[batch/v1beta1 batch/v2alpha1],
      %i[spec jobTemplate spec template spec containers], %i[spec jobTemplate spec template spec initContainers]
    ],
    [
      'DaemonSet', %w[apps/v1 apps/v1beta2 extensions/v1beta1],
      %i[spec template spec containers], %i[spec template spec initContainers]
    ],
    [
      'Deployment', %w[apps/v1 apps/v1beta2 apps/v1beta1 extensions/v1beta1],
      %i[spec template spec containers], %i[spec template spec initContainers]
    ],
    [
      'Pod', %w[v1],
      %i[spec containers], %i[spec initContainers]
    ],
    [
      'ReplicaSet', %w[apps/v1 apps/v1beta2 extensions/v1beta1],
      %i[spec template spec containers], %i[spec template spec initContainers]
    ],
    [
      'ReplicationController', %w[v1],
      %i[spec template spec containers], %i[spec template spec initContainers]
    ],
    [
      'StatefulSet', %w[apps/v1 apps/v1beta2 apps/v1beta1],
      %i[spec template spec containers], %i[spec template spec initContainers]
    ]
  ].freeze

  def resources_of_kind(kind, api_versions)
    kind = kind.underscore

    api_versions.each do |api_version|
      resources = resources_of_api_version(kind, api_version)

      next unless resources

      @logger.info("Fetched #{resources.length} #{human_kind(kind, resources.length)} from #{api_version}")

      return resources
    end
  end

  def resources_of_api_version(kind, api_version)
    group, version = api_version.split('/')

    if version.nil?
      version = group
      group = nil
    end

    client = @client_factory.create_client(group, version)

    begin
      return client.send("get_#{kind.pluralize}".to_sym)
    rescue Kubeclient::ResourceNotFoundError
      @logger.debug("API version #{api_version} is not supported for #{human_kind(kind)}")
    rescue StandardError => err
      @logger.error("Unable to fetch #{human_kind(kind)} using apiVersion #{api_version}: #{err}")
    end

    nil
  end

  def human_kind(kind, count = nil)
    kind.pluralize(count).humanize.capitalize
  end

  def yield_images_of_resources(resources, paths)
    resources.each do |resource|
      paths.each do |path|
        containers = path.reduce(resource) { |node, path_part| node[path_part] }

        containers&.each do |container|
          yield container[:image] if block_given?
        end
      end
    end
  end

  def yield_keep_alive_images
    client = @client_factory.create_client
    count = 0

    config_maps = client.get_config_maps(label_selector: 'registry-cleaner == keep-alive')

    config_maps&.each do |config_map|
      config_map[:data].to_h.each_value do |images|
        images.split.each do |image|
          next if image.blank?

          count += 1

          yield image if block_given?
        end
      end
    end

    @logger.info("Fetched #{count} #{'image'.pluralize(count)} to keep alive")
  end
end
