class ImagesCleaner
  def initialize(configuration, collected_images)
    @configuration = configuration
    @collected_images = collected_images
    @dry_run = ENV.fetch('DRY_RUN', 'false') == 'true'
    @logger = SemanticLogger[ImagesCleaner]
  end

  def clean
    @collected_images.each do |registry_id, namespaces|
      registry = @configuration.find_registry_by_id(registry_id)

      begin
        clean_registry(registry, namespaces)
      rescue StandardError => err
        @logger.error("Unable to clean registry #{registry_id}: #{err}")

        return false
      end
    end

    true
  end

  private

  def clean_registry(registry, namespaces)
    @logger.info("Cleaning registry #{registry.id}")

    images_deleted = 0

    images = registry.load_images(namespaces.keys)

    return unless images

    images = images.sort_by { |image| [image.namespaced_name, image.tag] }

    images.each do |image|
      next if should_keep_image?(namespaces, image)

      images_deleted += delete_image(image)
    end

    @logger.info("Deleted #{images_deleted} " + 'image'.pluralize(images_deleted))
  end

  def delete_image(image)
    if @dry_run
      @logger.info("Pretending to delete image #{image.namespaced_name_with_tag}")

      return 0
    end

    @logger.info("Deleting #{image.namespaced_name_with_tag}")

    begin
      registry.delete_image(image) unless @dry_run

      1
    rescue StandardError => err
      @logger.error("Unable to delete image #{image.namespaced_name_with_tag} - #{err}")
    end

    0
  end

  def should_keep_image?(namespaces, image)
    return true if image.namespace.nil?
    return true unless namespaces.key?(image.namespace)

    namespace = namespaces[image.namespace]

    return false unless namespace.key?(image.name)

    namespace[image.name].include?(image.tag)
  end
end
