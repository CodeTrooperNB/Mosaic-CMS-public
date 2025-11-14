# frozen_string_literal: true

module Admin
  class ImageAttachmentsController < Admin::AdminController
    def show
      attachment_key = params[:key]
      variant_type = params[:variant] || "preview" # Default to preview variant

      Rails.logger.info "Looking for attachment with key: #{attachment_key}, variant: #{variant_type}"

      # Find the attachment directly by its key (which is now the name)
      # Filter to only Pod attachments to avoid conflicts with other models
      attachment = ActiveStorage::Attachment.find_by(
        name: attachment_key,
        record_type: "Pod"
      )

      Rails.logger.info "Found attachment: #{attachment&.id} with blob: #{attachment&.blob&.id}"

      if attachment&.blob
        # Generate appropriate variant based on request
        variant_url = case variant_type
                      when "preview"
                        # Small preview for form display
                        serve_image_remote_url(attachment.blob, resize_spec: "resize_to_limit", dimensions: [400, 300])
                      when "thumbnail"
                        # Even smaller thumbnail
                        serve_image_remote_url(attachment.blob, resize_spec: "resize_to_limit", dimensions: [150, 150])
                      when "medium"
                        # Medium size for content display
                        serve_image_remote_url(attachment.blob, resize_spec: "resize_to_limit", dimensions: [800, 600])
                      when "original"
                        # Full size original
                        serve_image_remote_url(attachment.blob)
                      else
                        # Default to preview
                        serve_image_remote_url(attachment.blob, resize_spec: "resize_to_limit", dimensions: [400, 300])
                      end

        render json: {
          success: true,
          url: variant_url,
          variant: variant_type,
          metadata: {
            filename: attachment.blob.filename,
            content_type: attachment.blob.content_type,
            byte_size: attachment.blob.byte_size,
            original_url: rails_blob_path(attachment.blob, only_path: false)
          }
        }
      else
        render json: { success: false, error: "Attachment not found" }, status: :not_found
      end
    end
  end
end