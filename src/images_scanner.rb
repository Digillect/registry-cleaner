class ImagesScanner
  def initialize(configuration)
    @configuration = configuration
    @logger = SemanticLogger[ImagesScanner]

    @images = {}
    @images_scanned = 0
    @images_processed = 0
    @images_recorded = 0
  end

  def scan
    @configuration.scanners.each do |scanner|
      scanner.scan do |image_name|
        @images_scanned += 1

        process_image image_name
      end
    end


    @logger.info("#{@images_scanned} #{'image'.pluralize(@images_scanned)} scanned, "\
                 "#{@images_processed} #{'image'.pluralize(@images_processed)} processed, "\
                 "#{@images_recorded} #{'image'.pluralize(@images_recorded)} recorded")

    @images
  end

  def process_image(image_name)
    image_name = image_name.strip.downcase
    image_registry = @configuration.find_registry_by_image_name(image_name)

    return unless image_registry

    @images_processed += 1

    image_repository, image_tag = normalize_image_name(image_registry, image_name)

    record_image(image_registry, image_repository, image_tag)
  end

  private

  def normalize_image_name(image_registry, image_name)
    image_name = image_name[image_registry.hostname.length..-1]
    name_parts = image_name.split(':')

    name_parts << 'latest' if name_parts.length < 2

    name_parts
  end

  def record_image(image_registry, image_repository, image_tag)
    repositories = @images[image_registry.id]

    if repositories.nil?
      repositories = {}

      @images[image_registry.id] = repositories
    end

    tags = repositories[image_repository]

    if tags.nil?
      tags = []

      repositories[image_repository] = tags
    end

    return if tags.include?(image_tag)

    tags << image_tag

    @logger.debug("Recording #{image_repository}:#{image_tag}")

    @images_recorded += 1
  end
end
