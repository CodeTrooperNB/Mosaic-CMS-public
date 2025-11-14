# app/helpers/admin/svg_helper.rb
module Admin::SvgHelper
  # Render an inline SVG with mosaic-specific styling and options
  def admin_svg(filename, options = {})
    default_options = {
      class: "inline-svg",
      role: "img"
    }

    merged_options = default_options.merge(options)

    # Add accessibility attributes if not present
    unless merged_options[:title] || merged_options["aria-label"] || merged_options["aria-labelledby"]
      merged_options["aria-hidden"] = "true"
    end

    inline_svg_tag(filename, merged_options)
  end

  # Render an icon SVG with consistent sizing and styling
  # Accepts either a bare icon name (e.g., "home") or a full asset path (e.g., "admin/icons/admin/home.svg").
  def admin_icon(name, options = {})
    icon_options = {
      class: "inline-svg icon #{options.delete(:size) || 'icon-md'}",
      role: "img",
      'aria-hidden': "true"
    }

    if name.to_s.include?("/")
      # Assume full path provided
      admin_svg(name, icon_options.merge(options))
    else
      icon_name = "admin/icons/admin/#{name}.svg"
      admin_svg(icon_name, icon_options.merge(options))
    end
  end

  # Render a logo SVG with brand-specific styling
  def mosaic_logo(filename, options = {})
    logo_options = {
      class: "inline-svg logo",
      role: "img",
      title: "Mosaic CMS Logo"
    }

    logo_name = "admin/logos/#{filename}.svg"

    admin_svg(logo_name, logo_options.merge(options))
  end

  # Helper for status icons with semantic colors
  def status_icon(status, options = {})
    icon_name = "admin/icons/status/#{status}.svg"

    status_class = "status-#{status}"
    options[:class] = "#{options[:class]} #{status_class}".strip

    # Pass through the full path to admin_icon (supported) or directly to admin_svg
    admin_icon(icon_name, options)
  end

  # Helper for action icons (edit, delete, view, etc.)
  def action_icon(action, options = {})
    icon_name = "admin/icons/actions/#{action}.svg"

    action_class = "action-#{action}"
    options[:class] = "#{options[:class]} #{action_class}".strip

    # Pass through the full path to admin_icon (supported) or directly to admin_svg
    admin_icon(icon_name, options)
  end
end