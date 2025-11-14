# frozen_string_literal: true

# Helpers for rendering pod images from JSONB definitions.
# Image fields are stored as objects like:
#   { "attachment_key": "hero_image_123", "alt_text": "Alt", "dimension_desktop": "[]", "dimension_mobile": "[]", "caption": "..." }
# or occasionally just a URL string.
module PodImageHelper
  # Normalize an image value into a consistent hash.
  # Accepts either:
  # - data (Hash) and a field (Symbol/String) to extract
  # - the image value itself (Hash with attachment_key/url or String URL)
  def pod_image_info(data_or_value, field = nil)
    value = if field
      safe_dig(data_or_value, field)
    else
      data_or_value
    end

    value = JSON.parse(value) if value.is_a?(String) && value.start_with?("{")

    Rails.logger.info("VALUE: " + value.inspect)

    case value
    when String
      { url: value, alt: nil, attachment_key: nil, caption: nil, dimension_desktop: nil, dimension_mobile: nil }
    when Hash
      {
        attachment_key: value["attachment_key"] || value[:attachment_key],
        url: value["url"] || value[:url],
        alt: value["alt_text"] || value[:alt_text] || value["alt"] || value[:alt],
        dimension_desktop: value["dimension_desktop"] || value[:dimension_desktop],
        dimension_mobile: value["dimension_mobile"] || value[:dimension_mobile],
        caption: value["caption"] || value[:caption]
      }
    else
      { url: nil, alt: nil, attachment_key: nil, caption: nil, dimension_desktop: nil, dimension_mobile: nil }
    end
  end

  # Returns true if an image is renderable (either attachment_key or url present)
  def pod_image_present?(data_or_value, field = nil)
    info = pod_image_info(data_or_value, field)
    info[:attachment_key].present? || info[:url].present?
  end

  # Build a URL to the image (variant if attachment_key; direct if url provided)
  # variant can be: "original", "preview", "thumbnail", "medium", or any custom string
  def pod_image_url(data_or_value, field = nil, variant: "desktop")
    info = pod_image_info(data_or_value, field)
    if info[:attachment_key].present?
      key = ERB::Util.url_encode(info[:attachment_key])
      attachment = ActiveStorage::Attachment.find_by(
        name: key,
        record_type: "Pod"
      )
      if variant.to_s.presence == "desktop" && !info[:dimension_desktop].presence
        variant_type = "original"
      elsif variant.to_s.presence == "mobile" && !info[:dimension_mobile].presence
        variant_type = "original"
      else
        variant_type = variant.to_s
      end

      dimension_desktop = info[:dimension_desktop].presence || ""
      dimension_mobile = info[:dimension_mobile].presence || ""

      Rails.logger.info("VARIANT: " + variant_type.inspect)

      if attachment&.blob
        # Generate appropriate variant based on request
        case variant_type
        when "desktop"
          # Desktop dimensions
          serve_image_remote_url(attachment.blob, resize_spec: "resize_to_limit", dimensions: eval("[#{dimension_desktop}]"))
        when "mobile"
          # Mobile dimensions
          serve_image_remote_url(attachment.blob, resize_spec: "resize_to_fill", dimensions: eval("[#{dimension_mobile}]"))
        else
          # Full size original
          serve_image_remote_url(attachment.blob)
        end
      end
    else
      info[:url]
    end
  end

  # Render an <img> tag. You can pass either the whole pod data and the field name,
  # or the field's value/hash directly.
  # Options:
  # - variant: which variant to request for attachment_key (default: "medium")
  # - alt: override alt text (falls back to alt_text in data, then empty string)
  # - class: CSS classes
  # - any other HTML options for image_tag
  def pod_image_tag(data_or_value, field = nil, variant: "desktop", alt: nil, **options)
    Rails.logger.info("DATA: " + data_or_value.inspect)

    info = pod_image_info(data_or_value, field)

    Rails.logger.info("INFO: " + info.inspect)
    return "".html_safe unless info[:attachment_key].present? || info[:url].present?

    url = pod_image_url(info, nil, variant: variant)
    resolved_alt = alt.nil? ? (info[:alt].presence || "") : alt

    image_tag(url, { alt: resolved_alt }.merge(options))
  end

  private

  def safe_dig(hash, key)
    return nil unless hash.respond_to?(:[]) || hash.is_a?(Hash)
    hash[key.to_s] || hash[key.to_sym]
  end
end
