# app/mailers/enquiry_mailer.rb
class EnquiryMailer < ApplicationMailer
  default from: -> { Settings.mailer.from_email }

  def thank_you(enquiry)
    @enquiry = enquiry
    @site_name = Settings.cms.site_name

    mail(
      to: @enquiry.email,
      subject: "Thank you for contacting #{@site_name}"
    )
  end

  def admin_notification(enquiry)
    @enquiry = enquiry
    @site_name = Settings.cms.site_name

    # Get admin emails from settings (comma-separated)
    admin_emails = Settings.mailer.intercept_emails_to
    admin_emails = admin_emails.split(",").map(&:strip) if admin_emails.is_a?(String)

    # Fallback to CMS admin email if intercept_emails_to is not set
    admin_emails = [Settings.cms.admin_email] if admin_emails.blank? || (admin_emails.is_a?(Array) && admin_emails.empty?)

    mail(
      to: admin_emails,
      subject: "[#{@site_name}] New Enquiry from #{@enquiry.name}"
    )
  end
end
