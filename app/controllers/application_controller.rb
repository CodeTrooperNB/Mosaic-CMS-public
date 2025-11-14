class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  include Pages::Finder
  include Admin::SvgHelper
  include BunnyImageHelper
  include PodImageHelper
  include PagePodsHelper
  include SeoHelper
  
  protected

  # E-commerce helper methods
  def current_customer
    return nil unless session[:customer_token]

    @current_customer ||= fetch_customer_from_hub
  end

  def customer_signed_in?
    current_customer.present?
  end

  def authenticate_customer!
    unless customer_signed_in?
      redirect_to new_customer_session_path, alert: "Please sign in to continue."
    end
  end

  private

  def fetch_customer_from_hub
    # TODO: Implement GraphQL call to The Hub to fetch customer data
    # using session[:customer_token]
    nil
  end


end
