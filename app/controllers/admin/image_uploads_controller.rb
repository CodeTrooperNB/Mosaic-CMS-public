# frozen_string_literal: true

module Admin
  class ImageUploadsController < Admin::AdminController

    def create
      @upload = process_upload

      if @upload[:success]
        render json: {
          success: true,
          image_data: @upload[:image_data],
          url: @upload[:url],
          thumbnail_url: @upload[:thumbnail_url], # Add thumbnail URL
          metadata: @upload[:metadata]
        }
      else
        render json: {
          success: false,
          error: @upload[:error]
        }, status: :unprocessable_entity
      end
    rescue => e
      Rails.logger.error "Image upload error: #{e.message}"
      render json: {
        success: false,
        error: "Upload failed: #{e.message}"
      }, status: :internal_server_error
    end

    private

    def process_upload
      unless params[:image].present?
        return { success: false, error: "No image file provided" }
      end

      file = params[:image]
      field_name = params[:field_name].presence || "image"
      alt_text = params[:alt_text].presence || ""

      # Validate file
      validation_result = validate_image_file(file)
      return validation_result unless validation_result[:success]

      # Generate unique attachment key
      attachment_key = generate_attachment_key(field_name)

      # Create Active Storage attachment
      blob = create_blob(file)

      # Create structured image data for JSONB storage
      image_data = {
        attachment_key: attachment_key,
        alt_text: alt_text,
        filename: file.original_filename,
        content_type: file.content_type,
        byte_size: blob.byte_size,
        uploaded_at: Time.current.iso8601
      }

      # Store metadata for session tracking
      session_metadata = {
        blob_id: blob.id,
        field_name: field_name,
        image_data: image_data,
        uploaded_by: current_admin_user.id
      }

      # Store in session for form processing
      session[:pending_attachments] ||= {}
      session[:pending_attachments][attachment_key] = session_metadata

      # Generate thumbnail URL for immediate preview
      thumbnail_url =  serve_image_remote_url(blob, resize_spec: "resize_to_limit", dimensions: [150, 150])
      original_url = serve_image_remote_url(blob)

      {
        success: true,
        image_data: image_data,
        url: original_url,
        thumbnail_url: thumbnail_url,
        metadata: session_metadata
      }
    end

    def validate_image_file(file)
      # Check file size (default 10MB)
      max_size = params[:max_size]&.to_i || 10.megabytes
      if file.size > max_size
        return {
          success: false,
          error: "File too large. Maximum size is #{max_size / 1.megabyte}MB"
        }
      end

      # Check file type
      allowed_types = %w[image/jpeg image/jpg image/png image/webp image/gif]
      unless allowed_types.include?(file.content_type)
        return {
          success: false,
          error: "Invalid file type. Allowed: #{allowed_types.join(', ')}"
        }
      end

      { success: true }
    end

    def create_blob(file)
      ActiveStorage::Blob.create_and_upload!(
        io: file.tempfile,
        filename: file.original_filename,
        content_type: file.content_type,
        metadata: {
          analyzed: false
        }
      )
    end

    def generate_attachment_key(field_name)
      "#{field_name}_#{SecureRandom.hex(8)}_#{Time.current.to_i}"
    end
  end
end