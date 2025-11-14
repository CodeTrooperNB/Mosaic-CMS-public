# app/controllers/enquiries_controller.rb
class EnquiriesController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create], if: -> { request.format.json? }

  def create
    @enquiry = Enquiry.new(enquiry_params)

    if @enquiry.save
      # Send emails
      EnquiryMailer.thank_you(@enquiry).deliver_later
      EnquiryMailer.admin_notification(@enquiry).deliver_later

      respond_to do |format|
        format.html { redirect_to root_path, notice: "Thank you for your enquiry. We'll be in touch soon!" }
        format.json { render json: { success: true, message: "Enquiry submitted successfully." }, status: :created }
      end
    else
      respond_to do |format|
        format.html { redirect_to root_path, alert: "There was an error submitting your enquiry. Please try again." }
        format.json { render json: { success: false, errors: @enquiry.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  private

  def enquiry_params
    # Extract name and email as top-level attributes
    # Store everything else in form_data JSONB
    {
      name: params.dig(:enquiry, :name),
      email: params.dig(:enquiry, :email),
      form_data: extract_form_data
    }
  end

  def extract_form_data
    permitted_keys = [:message, :subject, :phone, :company]
    data = {}

    permitted_keys.each do |key|
      value = params.dig(:enquiry, key)
      data[key.to_s] = value if value.present?
    end

    # Add any additional custom fields if they exist
    if params[:enquiry].is_a?(ActionController::Parameters)
      params[:enquiry].except(:name, :email, *permitted_keys).each do |key, value|
        data[key.to_s] = value if value.present?
      end
    end

    data
  end
end
