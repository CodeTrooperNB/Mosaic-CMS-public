# frozen_string_literal: true

module Pages
  module Finder
    extend ActiveSupport::Concern

    def find_all_pages
      Page.published.all
    end

    # Find a Page by resolving the route pattern for the current controller/action.
    # This inspects Rails routes to find a matching route pattern for the given
    # action (defaults to the calling controller's action name) and then looks up
    # a Page whose redirect_path matches that pattern (or common normalized variants).
    #
    # Usage in a controller:
    #   include Pages::Finder
    #   before_action :resolve_page_from_route_pattern
    #
    # The method will raise ActiveRecord::RecordNotFound if no page is found.
    def find_page_by_path!(action_name = nil)
      action_name ||= __getobj__ ? __getobj__ : action_name_from_controller
      action_name = action_name.to_s

      # try to find the route pattern matching this controller and action
      route_pattern = route_pattern_for(self.class.controller_path, action_name)

      # if we couldn't determine a route pattern, fall back to default path lookup
      if route_pattern.blank?
        return find_page_by_simple_path!
      end

      # Normalize the route pattern to a template string without leading slash and without format
      template = normalize_route_pattern(route_pattern) # e.g. "hello_world/:id" or "hello_world/:category/:id"

      # Build a set of variants to try when matching against Page.redirect_path or Page.slug
      variants = build_template_variants(template)

      # Try to find a page whose redirect_path matches any of the variants
      page = nil
      variants.each do |v|
        page ||= Page.published.find_by(redirect_path: v)
        page ||= Page.published.find_by(slug: v)
      end

      # fallback: home page
      page ||= Page.published.find_by(slug: "home")

      raise ActiveRecord::RecordNotFound unless page

      page
    end

    private

    # Extracts action name from the caller controller if possible.
    def action_name_from_controller
      return params[:action].to_s if defined?(params) && params[:action]
      nil
    end

    # Look up the first route pattern for a controller#action.
    # Returns the raw route path string (including :params), or nil if not found.
    def route_pattern_for(controller_path, action_name)
      routes = Rails.application.routes.routes

      routes.each do |r|
        defaults = r.defaults || {}
        next unless defaults[:controller].to_s == controller_path.to_s
        next unless defaults[:action].to_s == action_name.to_s

        # r.path.spec may include (.:format) — strip that
        spec = r.path.spec.to_s
        spec = spec.gsub(/\(\.:format\)$/, "")
        return spec
      end

      nil
    end

    # Normalize a route path like "/hello_world/:id(.:format)" to "hello_world/:id"
    def normalize_route_pattern(pattern)
      return nil if pattern.blank?
      p = pattern.dup
      p = p.sub(/\A\//, "")            # remove leading slash
      p = p.gsub(/\(\.:format\)$/, "") # remove optional format
      p
    end

    # Produce a small set of templates/variants to try when matching stored redirect_path
    def build_template_variants(template)
      return [] if template.blank?

      variants = []
      variants << template                    # "hello_world/:id"
      variants << "/#{template}"              # "/hello_world/:id"
      variants << template.tr("_", "-")       # "hello-world/:id"
      variants << "/#{template.tr("_", "-")}" # "/hello-world/:id"
      # Also try removing placeholders (for index-like pages) and only the base
      base = template.split("/").first
      variants << base
      variants << base.tr("_", "-")
      variants.uniq
    end

    # Fallback simple lookup when no route pattern could be determined.
    def find_page_by_simple_path!
      requested_path = params[:path] || params[:id] || request.path.sub(/\A\//, "")
      raise ActiveRecord::RecordNotFound if requested_path.blank?

      page ||= Page.published.find_by(redirect_path: requested_path)
      page ||= Page.published.find_by(slug: requested_path)
      if page.nil? && requested_path.include?("/")
        base_slug = requested_path.split("/").first
        page ||= Page.published.find_by(redirect_path: base_slug)
        page ||= Page.published.find_by(slug: base_slug)
      end

      page ||= Page.published.find_by(slug: "home")
      raise ActiveRecord::RecordNotFound unless page
      page
    end
  end
end