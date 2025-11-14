# app/controllers/admin/enquiries_controller.rb
class Admin::EnquiriesController < Admin::AdminController
  before_action :set_enquiry, only: [:show, :destroy, :mark_as_read, :mark_as_resolved, :mark_as_spam, :mark_as_not_spam]

  def index
    authorize Enquiry

    # Determine which collection to show
    @showing_spam = params[:spam] == "true"

    base_scope = @showing_spam ? policy_scope(Enquiry).spam_items : policy_scope(Enquiry).not_spam

    # Calculate stats
    @stats = {
      total: policy_scope(Enquiry).not_spam.count,
      pending: policy_scope(Enquiry).not_spam.status_pending.count,
      read: policy_scope(Enquiry).not_spam.status_read.count,
      resolved: policy_scope(Enquiry).not_spam.status_resolved.count,
      spam: policy_scope(Enquiry).spam_items.count
    }

    # Apply filters
    @enquiries = base_scope
    @enquiries = @enquiries.by_status(params[:status]) if params[:status].present?
    @enquiries = @enquiries.search_by_email(params[:email]) if params[:email].present?
    @enquiries = @enquiries.search_by_name(params[:name]) if params[:name].present?
    @enquiries = @enquiries.recent

    # Pagination (if you're using kaminari or pagy)
    # @enquiries = @enquiries.page(params[:page]).per(25)
  end

  def show
    authorize @enquiry
    @enquiry.mark_as_read! if @enquiry.status_pending?
  end

  def destroy
    authorize @enquiry
    @enquiry.destroy
    redirect_to admin_enquiries_path, notice: "Enquiry deleted successfully."
  end

  def mark_as_read
    authorize @enquiry
    @enquiry.mark_as_read!
    redirect_to admin_enquiry_path(@enquiry), notice: "Enquiry marked as read."
  end

  def mark_as_resolved
    authorize @enquiry
    @enquiry.mark_as_resolved!
    redirect_to admin_enquiry_path(@enquiry), notice: "Enquiry marked as resolved."
  end

  def mark_as_spam
    authorize @enquiry
    @enquiry.mark_as_spam!
    redirect_to admin_enquiries_path, notice: "Enquiry marked as spam."
  end

  def mark_as_not_spam
    authorize @enquiry
    @enquiry.mark_as_not_spam!
    redirect_to admin_enquiries_path(spam: true), notice: "Enquiry removed from spam."
  end

  def clear_spam
    authorize Enquiry, :clear_spam?
    count = Enquiry.spam_items.count
    Enquiry.spam_items.destroy_all
    redirect_to admin_enquiries_path(spam: true), notice: "Cleared #{count} spam enquiries."
  end

  private

  def set_enquiry
    @enquiry = Enquiry.find(params[:id])
  end
end
