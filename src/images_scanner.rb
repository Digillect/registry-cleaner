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
      scanner.scan do |image|
        @images_scanned += 1

        process_image(image) unless image.registry.nil?
      end
    end


    @logger.info("#{@images_scanned} #{'image'.pluralize(@images_scanned)} scanned, "\
                 "#{@images_processed} #{'image'.pluralize(@images_processed)} processed, "\
                 "#{@images_recorded} #{'image'.pluralize(@images_recorded)} recorded")

    @images
  end

  def process_image(image)
    image_registry = @configuration.find_registry_by_id(image.registry)

    return unless image_registry

    @images_processed += 1

    record_image(image)
  end

  private

  def record_image(image)
    namespaces = @images[image.registry]

    if namespaces.nil?
      namespaces = {}

      @images[image.registry] = namespaces
    end

    names = namespaces[image.namespace]

    if names.nil?
      names = {}

      namespaces[image.namespace] = names
    end

    tags = names[image.name]

    if tags.nil?
      tags = []

      names[image.name] = tags
    end

    return if tags.include?(image.tag)

    tags << image.tag

    @logger.debug("Recording #{image.full_name}")

    @images_recorded += 1
  end
end
