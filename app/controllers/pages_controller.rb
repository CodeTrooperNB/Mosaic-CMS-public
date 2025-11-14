# app/controllers/pages_controller.rb
class PagesController < ApplicationController
  before_action :find_page, only: [:show]

  def home
    @page = Page.find_by(slug: "home") || Page.first
    handle_page_request
  end

  def show
    handle_page_request
  end

  private

  def find_page
    requested_path = params[:path] || params[:id]
    @page = Page.published.find_by(slug: requested_path)
    if @page.nil? && requested_path.include?("/")
      base_slug = requested_path.split("/").first
      @page = Page.published.find_by(slug: base_slug)
    end
  rescue ActiveRecord::RecordNotFound
    render file: "#{Rails.root}/public/404.html", status: :not_found
  end

  def handle_page_request
    return unless @page

    # Handle redirects first
    if @page.redirect_path.present?
      handle_redirect
    else
      render_cms_page
    end
  end

  def handle_redirect
    redirect_path = @page&.redirect_path&.strip
    return unless redirect_path.present?

    # Now expecting redirect_path to be a path template like:
    # "/hello_world" or "hello_world/:id" or "hello_world/:category/:id"
    # Normalize: strip leading slash for template processing
    template = redirect_path.start_with?("/") ? redirect_path[1..] : redirect_path

    # Collect placeholders like :id, :category
    placeholders = template.scan(/:([a-zA-Z_]\w*)/).flatten.map(&:to_sym)

    # Resolve placeholder values with request params:
    values = {}
    placeholders.each do |ph|
      if params.key?(ph)
        values[ph] = params[ph]
      end
    end

    # Build path segments and substitute placeholders.
    segments = template.split("/")
    base = segments.first

    built_segments = segments.map.with_index do |seg, idx|
      if seg.start_with?(":")
        key = seg[1..].to_sym
        if values[key].present?
          CGI.escape(values[key].to_s)
        else
          Rails.logger.error "Missing value for placeholder :#{key} in redirect_path #{@page.redirect_path.inspect}"
          render_cms_page and return
        end
      else
        idx == 0 ? base : seg
      end
    end

    path = "/" + built_segments.join("/")

    # Any request params not consumed by placeholders become query params
    remaining_query = params.permit.reject { |k, _| placeholders.include?(k) }
    if remaining_query.present?
      path += "?" + remaining_query.to_query
    end

    # Perform a proper HTTP redirect so routing and Turbo behave normally
    redirect_to path
  end

  def render_cms_page
    # Determine template
    template = determine_template

    render template: "pages/#{template}"
  end

  def determine_template
    return @page.view_template if @page.view_template.present?
    return "home" if @page.slug == "home"
    "show" # default template
  end
end