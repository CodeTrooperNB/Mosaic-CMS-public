# frozen_string_literal: true

module SeoHelper
  # Build an SEO title string.
  #
  # Priority:
  # 1. provided resource (resource.try(:seo_title) || resource.try(:title))
  # 2. page.title
  # 3. Settings.cms.site_name
  #
  # Adds Settings.cms.seo.meta_title_suffix if present and not already included.
  #
  # Options:
  # - :page - Page object (defaults to @page)
  # - :resource - alternate object with SEO methods
  # - :fallback - fallback title if none found (defaults to Settings.cms.site_name)
  def seo_title(page: nil, resource: nil, fallback: nil)
    page ||= defined?(page) && page
    fallback ||= Settings.cms.site_name rescue "Site"

    candidate =
      if resource
        resource.try(:seo_title).presence || resource.try(:title).presence || resource.try(:name).presence
      elsif page
        page.try(:menu_title).presence || page.try(:title).presence || page.try(:name).presence
      end

    title = (candidate.presence || fallback).to_s

    suffix = (Settings.cms.seo.meta_title_suffix.presence rescue nil)
    if suffix.present? && !title.end_with?(suffix)
      title = "#{title}#{suffix}"
    end

    title
  end

  # Build an SEO meta description.
  #
  # Priority:
  # 1. resource.try(:seo_description) || resource.try(:meta_description)
  # 2. page.meta_description
  # 3. Settings.cms.seo.default_meta_description
  #
  # Options:
  # - :page - Page object (defaults to @page)
  # - :resource - alternate object with SEO methods
  # - :truncate_to - integer for maximum length (optional)
  def seo_description(page: nil, resource: nil, truncate_to: 160)
    page ||= defined?(page) && page

    candidate =
      if resource
        resource.try(:seo_description).presence || resource.try(:meta_description).presence || resource.try(:description).presence
      elsif page
        page.try(:meta_description).presence || page.try(:summary).presence || page.try(:excerpt).presence
      end

    desc = (candidate.presence || (Settings.cms.seo.default_meta_description.presence rescue nil) || "").to_s

    if truncate_to && truncate_to > 0
      desc = desc.truncate(truncate_to, separator: " ")
    end

    desc
  end

  # Render the canonical link and common meta tags (title + description + robots)
  #
  # Usage in layout:
  #   <%= render_seo_tags(page: @page, resource: @product) %>
  #
  # Options:
  # - :page - Page object (defaults to @page)
  # - :resource - alternate object to source title/description
  # - :canonical - override canonical url (defaults to Settings.cms.seo.canonical_host + request.path)
  # - :robots - boolean override for indexing (defaults to Settings.cms.seo.robots_index)
  def render_seo_tags(page: nil, resource: nil, canonical: nil, robots: nil)
    page ||= defined?(@page) && @page
    title = seo_title(page: page, resource: resource)
    description = seo_description(page: page, resource: resource)

    canonical_host = (Settings.cms.seo.canonical_host.presence rescue nil)
    canonical ||= begin
                    if canonical_host.present?
                      uri = URI.parse(canonical_host) rescue nil
                      host = uri ? uri.host : canonical_host
                      "#{canonical_host.chomp('/')}#{request.path}"
                    else
                      "#{request.base_url}#{request.path}"
                    end
                  end

    robots_flag = robots.nil? ? (Settings.cms.seo.robots_index == true rescue true) : robots

    tags = []
    tags << tag.title(title)
    tags << tag.meta(name: "description", content: description) if description.present?
    tags << tag.link(rel: "canonical", href: canonical)
    tags << tag.meta(name: "robots", content: (robots_flag ? "index,follow" : "noindex,nofollow"))

    safe_join(tags, "\n")
  end
end