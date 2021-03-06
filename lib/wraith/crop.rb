require "wraith"
require "wraith/helpers/logger"
require "image_size"
require "parallel"
require "shellwords"

class Wraith::CropImages
  include Logging
  attr_reader :wraith

  def initialize(config)
    @wraith = Wraith::Wraith.new(config)
  end

  def crop_images
    files = Dir.glob("#{wraith.directory}/*/*.png").sort

    Parallel.each(files.each_slice(2), :in_processes => Parallel.processor_count) do |base, compare|
      logger.info "cropping images"

      width          = image_dimensions(base)[0]
      base_height    = image_dimensions(base)[1]
      compare_height = image_dimensions(compare)[1]

      if base_height > compare_height
        image_to_crop     = compare
        height_to_crop_to = base_height
      else
        image_to_crop     = base
        height_to_crop_to = compare_height
      end

      crop_task(image_to_crop, height_to_crop_to, width)
    end
  end

  def crop_task(crop, height, width)
    `convert #{crop.shellescape} -background none -extent #{width}x#{height} #{crop.shellescape}`
  end

  def image_dimensions(image)
    ImageSize.new(File.open(image, "rb").read).size
  end
end
