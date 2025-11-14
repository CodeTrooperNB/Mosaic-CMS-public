module BunnyImageHelper
  def serve_image_remote_url(blob, resize_spec: nil, dimensions: nil, format: :webp)
    return asset_path("admin/icons/admin/media.svg") if blob.blank?
    if resize_spec == "resize_to_limit"
      variant = blob.variant(resize_to_limit: dimensions, format: format, saver: { quality: 90, strip: true })
      process_variant(variant)
    elsif resize_spec == "resize_to_fill"
      variant = blob.variant(resize_to_fill: dimensions, format: format, saver: { quality: 90, strip: true })
      process_variant(variant)
    else
      "#{Settings.bunny.cdn}/#{blob.key}"
    end
  end

  private

  def process_variant(variant)
    processed_variant = variant.processed
    variant_key = processed_variant.key
    # Direct Bunny CDN URL using Settings.bunny.cdn
    "#{Settings.bunny.cdn}/#{variant_key}"
  end

end
