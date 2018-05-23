class ImagesCleaner
  def initialize(configuration, collected_images)
    @configuration = configuration
    @collected_images = collected_images
    @dry_run = ENV.fetch('DRY_RUN', 'false') == 'true'
    @logger = SemanticLogger[ImagesCleaner]
  end

  def clean
    @collected_images.each do |registry_id, repositories|
      registry = @configuration.find_registry_by_id(registry_id)

      begin
        clean_registry(registry, repositories)
      rescue StandardError => err
        @logger.error("Unable to clean registry #{registry_id}: #{err}")

        return false
      end
    end

    true
  end

  private

  def clean_registry(registry, repositories)
    @logger.info("Cleaning registry #{registry.id}")

    name_prefixes = image_name_prefixes(repositories)
    images_deleted = 0

    images = registry.load_images

    return unless images

    images = images.sort_by { |image| [image.name, image.tag] }

    images.each do |image|
      next if should_keep_image?(repositories, name_prefixes, image)

      images_deleted += delete_image(image)
    end

    @logger.info("Deleted #{images_deleted} " + 'image'.pluralize(images_deleted))
  end

  def delete_image(image)
    if @dry_run
      @logger.info("Pretending to delete image #{image.name}:#{image.tag}")

      return 0
    end

    @logger.info("Deleting #{image.name}:#{image.tag}")

    begin
      registry.delete_image(image) unless @dry_run

      1
    rescue StandardError => err
      @logger.error("Unable to delete image #{image.name}:#{image.tag} - #{err}")
    end

    0
  end

  def image_name_prefixes(repositories)
    repositories
      .keys
      .map { |name| name.split('/').first }
      .uniq
  end

  def should_keep_image?(repositories, name_prefixes, image)
    prefix, suffix = image.name.split('/')

    return true if suffix.nil?
    return true unless name_prefixes.include?(prefix)
    return false unless repositories.key?(image.name)

    repositories[image.name].include?(image.tag)
  end
end
