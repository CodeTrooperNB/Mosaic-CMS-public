# app/controllers/admin/pods_controller.rb
class Admin::PodsController < Admin::AdminController
  def index
    @stats = {
      total_pods: Pod.count,
      reusable_pods: Pod.where(reusable: true).count,
      in_use_pods: Pod.where("usage_count > 0").count
    }

    @pods = Pod.includes(:pages).order(created_at: :desc).map do |pod|
      {
        id: pod.id,
        title: pod.title,
        description: pod.description,
        icon: "pods",
        time: helpers.time_ago_in_words(pod.created_at),
        pages: pod.pages.published.ordered # Include the associated pages
      }
    end
  end

  def new
    @pod_type = params[:pod_type]
    @pod = Pod.new(pod_type: @pod_type)
    @schema = @pod_type.present? ? Admin::PodSchemas.schema_for(@pod_type) : nil

    # Clear any stale attachment data from session
    session[:pending_attachments] = nil
  end

  def create
    permitted = permit_pod_params_flexible
    pod_type = permitted[:pod_type]

    Rails.logger.debug "Permitted params: #{permitted.inspect}"

    definition = build_definition_from_fields(permitted, pod_type)

    Rails.logger.debug "Built definition: #{definition.inspect}"

    @pod = Pod.new(name: permitted[:name], pod_type: pod_type, definition: definition)

    if @pod.save
      Rails.logger.info "Pod saved successfully: #{@pod.id}"
      # Process attachments AFTER the pod is saved
      process_attachments_into_definition
      redirect_to admin_pods_path, notice: "Pod created."
    else
      Rails.logger.error "Pod save failed: #{@pod.errors.full_messages}"
      @pod_type = pod_type
      @schema = Admin::PodSchemas.schema_for(@pod_type)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @pod = Pod.find(params[:id])
    @schema = Admin::PodSchemas.schema_for(@pod.pod_type)

    # Clear any stale attachment data from session
    session[:pending_attachments] = nil
  end

  def update
    @pod = Pod.find(params[:id])
    pod_type = @pod.pod_type

    permitted = permit_pod_params_flexible

    Rails.logger.debug "Permitted params: #{permitted.inspect}"

    definition = build_definition_from_fields(permitted, pod_type, @pod)

    Rails.logger.debug "Built definition: #{definition.inspect}"

    if @pod.update(name: permitted[:name], definition: definition)
      Rails.logger.info "Pod updated successfully: #{@pod.id}"
      # Process any new attachments AFTER the update
      process_attachments_into_definition
      redirect_to admin_pods_path, notice: "Pod updated."
    else
      Rails.logger.error "Pod update failed: #{@pod.errors.full_messages}"
      @schema = Admin::PodSchemas.schema_for(@pod.pod_type)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    pod = Pod.find(params[:id])
    pod.destroy!
    redirect_to admin_pods_path, notice: "Pod deleted."
  end

  def array_item_form
    field_name = params[:field_name]
    item_index = params[:item_index].to_i
    item_schema = params[:item_schema] || {}

    render partial: "admin/pods/array_item",
           locals: {
             field_name: field_name,
             item_schema: item_schema,
             item_data: {},
             item_index: item_index
           }
  end

  # POST /admin/pods/preview
  # Builds a pod definition from the posted form data and renders the matching
  # pods/shared partial as an HTML fragment (no layout). Intended for AJAX/Stimulus use.
  def preview
    # Handle JSON requests differently
    if request.content_type&.include?("application/json")
      # Parse JSON body
      json_params = JSON.parse(request.body.read)
      permitted = json_params.with_indifferent_access

      # Try multiple ways to find pod_type
      pod_type = permitted[:pod_type] ||
                 permitted.dig(:pod, :pod_type) ||
                 params[:pod_type] ||
                 request.env["action_dispatch.request.path_parameters"][:pod_type]

      Rails.logger.debug "JSON Preview - permitted: #{permitted.inspect}"
      Rails.logger.debug "JSON Preview - pod_type: #{pod_type.inspect}"
    else
      # Handle regular form data
      permitted = permit_pod_params_flexible
      pod_type = permitted[:pod_type] || params[:pod_type]

      Rails.logger.debug "Form Preview - permitted: #{permitted.inspect}"
      Rails.logger.debug "Form Preview - pod_type: #{pod_type.inspect}"
    end

    unless pod_type.present?
      error_msg = "pod_type is required for preview. Available data: #{permitted.keys.inspect}"
      Rails.logger.warn error_msg
      render html: "<div class='p-4 text-sm text-destructive'>#{error_msg}</div>".html_safe, status: :unprocessable_entity and return
    end

    # Rest of the method stays the same...
    begin
      if request.content_type&.include?("application/json")
        definition = build_definition_from_json(permitted, pod_type)
      else
        definition = build_definition_from_fields(permitted, pod_type)
      end
    rescue JSON::ParserError
      render html: "<div class='p-4 text-sm text-destructive'>Invalid JSON in advanced definition</div>".html_safe, status: :unprocessable_entity and return
    end

    partial_path = "pods/shared/#{pod_type}"

    begin
      html = render_to_string(partial: partial_path, locals: { data: definition })
      render html: html.html_safe
    rescue ActionView::MissingTemplate
      placeholder = <<~HTML
      <div class="p-6 border border-dashed border-border rounded-md bg-muted/20 text-sm text-muted-foreground">
        No preview available for pod_type: <strong>#{ERB::Util.html_escape(pod_type)}</strong>.<br/>
        Create the partial at <code>app/views/pods/shared/_#{ERB::Util.html_escape(pod_type)}.html.erb</code>.
      </div>
    HTML
      render html: placeholder.html_safe, status: :ok
    end
  end

  private

  # Add this new method to handle JSON data
  def build_definition_from_json(json_data, pod_type)
    # For JSON preview, we can be more direct
    # Extract the fields from the JSON structure
    fields = json_data.dig(:pod, :fields) || json_data[:fields] || {}
    alt_texts = json_data.dig(:pod, :alt_texts) || json_data[:alt_texts] || {}
    dimension_desktops = json_data.dig(:pod, :dimension_desktops) || json_data[:dimension_desktops] || {}
    dimension_mobiles = json_data.dig(:pod, :dimension_mobiles) || json_data[:dimension_mobiles] || {}
    definition_json = json_data.dig(:pod, :definition) || json_data[:definition]

    definition = {}

    # Start with advanced definition if provided
    if definition_json.present? && definition_json != "{}"
      begin
        definition = JSON.parse(definition_json) if definition_json.is_a?(String)
        definition = definition_json if definition_json.is_a?(Hash)
      rescue JSON::ParserError => e
        Rails.logger.error "JSON parse error: #{e.message}"
        raise e
      end
    end

    # Process the fields similar to the original method but simplified for JSON
    schema = Admin::PodSchemas.schema_for(pod_type)
    builder = Admin::PodFormBuilder.new(schema: schema)

    fields.each do |name, raw_val|
      field = builder.supported_fields.find { |f| f[:name] == name }
      next unless field

      case field[:type]
      when "array"
        # Handle array fields - simplified for preview
        definition[name] = raw_val.is_a?(Hash) ? raw_val.values : (raw_val || [])
      when "object"
        # Handle object fields - simplified for preview
        if raw_val.is_a?(Hash)
          processed_object = {}
          object_schema = field[:schema] || {}

          object_schema.each do |sub_field_name, sub_field_config|
            sub_field_type = sub_field_config["type"]&.downcase
            sub_val = raw_val[sub_field_name]

            if sub_field_type == "image" && sub_val.present?
              alt_text = alt_texts&.dig(name, sub_field_name) || ""
              dimension_desktop = dimension_desktops&.dig(name, sub_field_name) || ""
              dimension_mobile = dimension_mobiles&.dig(name, sub_field_name) || ""

              if sub_val.is_a?(String)
                begin
                  parsed_data = JSON.parse(sub_val)
                  processed_object[sub_field_name] = parsed_data.merge("alt_text" => alt_text, "dimension_desktop" => dimension_desktop, "dimension_mobile" => dimension_mobile) if parsed_data.is_a?(Hash)
                rescue JSON::ParserError
                  processed_object[sub_field_name] = { "attachment_key" => sub_val, "alt_text" => alt_text, "dimension_desktop" => dimension_desktop, "dimension_mobile" => dimension_mobile }
                end
              else
                processed_object[sub_field_name] = sub_val.merge("alt_text" => alt_text, "dimension_desktop" => dimension_desktop, "dimension_mobile" => dimension_mobile) if sub_val.is_a?(Hash)
              end
            elsif sub_field_type == "boolean"
              processed_object[sub_field_name] = ["1", "true", true].include?(sub_val)
            elsif sub_field_type == "number" || sub_field_type == "integer"
              processed_object[sub_field_name] = sub_val.to_i if sub_val.present?
            elsif sub_val.present?
              processed_object[sub_field_name] = sub_val
            end
          end

          definition[name] = processed_object
        end
      when "image"
        # Handle image fields
        alt_text = alt_texts[name] || ""
        dimension_desktop = dimension_desktops[name] || ""
        dimension_mobile = dimension_mobiles[name] || ""
        if raw_val.present?
          if raw_val.is_a?(String)
            begin
              parsed_data = JSON.parse(raw_val)
              definition[name] = parsed_data.merge("alt_text" => alt_text, "dimension_desktop" => dimension_desktop, "dimension_mobile" => dimension_mobile) if parsed_data.is_a?(Hash)
            rescue JSON::ParserError
              definition[name] = { "attachment_key" => raw_val,
                                   "alt_text" => alt_text,
                                   "dimension_desktop" => dimension_desktop,
                                   "dimension_mobile" => dimension_mobile}
            end
          else
            definition[name] = raw_val.merge("alt_text" => alt_text, "dimension_desktop" => dimension_desktop, "dimension_mobile" => dimension_mobile)
          end
        end
      else
        # Handle other field types
        coerced = builder.coerce_value(raw_val, field[:type])
        if coerced.present? || field[:type] == "boolean"
          definition[name] = coerced
        end
      end
    end

    definition
  end

  def permit_pod_params_flexible
    # Use a flexible approach that handles nested parameters
    raw_params = params.require(:pod).permit!.to_h.with_indifferent_access

    # Only allow the fields we expect for security
    permitted_params = raw_params.slice(:pod_type, :name, :definition, :fields, :alt_texts, :dimension_desktops, :dimension_mobiles)

    Rails.logger.debug "Raw pod params: #{raw_params.inspect}"
    Rails.logger.debug "Permitted pod params: #{permitted_params.inspect}"

    permitted_params
  end

  def build_definition_from_fields(permitted, pod_type, existing_pod = nil)
    schema = Admin::PodSchemas.schema_for(pod_type)
    builder = Admin::PodFormBuilder.new(schema: schema)

    definition = {}

    # Start with advanced definition if provided
    if permitted[:definition].present? && permitted[:definition] != "{}"
      begin
        definition = JSON.parse(permitted[:definition])
        Rails.logger.debug "Using advanced definition: #{definition.inspect}"
      rescue JSON::ParserError => e
        Rails.logger.error "JSON parse error: #{e.message}"
        flash[:alert] = "Invalid JSON provided for definition: #{e.message}"
        raise e
      end
    elsif existing_pod
      # Use existing pod definition as base for updates
      definition = (existing_pod.definition || {}).deep_dup
      Rails.logger.debug "Using existing pod definition as base: #{definition.inspect}"
    end

    # Process form fields
    (permitted[:fields] || {}).each do |name, raw_val|
      Rails.logger.debug "Processing field: #{name} with value: #{raw_val.inspect}"

      field = builder.supported_fields.find { |f| f[:name] == name }
      unless field
        Rails.logger.warn "Field #{name} not found in schema, skipping"
        next
      end

      if field[:type] == "array"
        Rails.logger.debug "Processing array field: #{name}"
        # Handle array fields
        processed_array = process_array_field(raw_val, field, permitted[:alt_texts], permitted[:dimension_desktops], permitted[:dimension_mobiles], existing_pod)
        definition[name] = processed_array
        Rails.logger.debug "Processed array result: #{processed_array.inspect}"
      elsif field[:type] == "object"
        Rails.logger.debug "Processing object field: #{name}"
        # Handle object fields
        processed_object = process_object_field(raw_val, field, permitted[:alt_texts], permitted[:dimension_desktops], permitted[:dimension_mobiles], existing_pod)
        definition[name] = processed_object
        Rails.logger.debug "Processed object result: #{processed_object.inspect}"
      elsif field[:type] == "image"
        Rails.logger.debug "Processing image field: #{name}"
        # Handle image fields
        process_image_field(definition, name, raw_val, permitted[:alt_texts], permitted[:dimension_desktops], permitted[:dimension_mobiles], existing_pod)
      else
        Rails.logger.debug "Processing regular field: #{name}, type: #{field[:type]}"
        # Handle other field types normally
        raw_val = "0" if field[:type] == "boolean" && raw_val.nil?
        coerced = builder.coerce_value(raw_val, field[:type])

        if %w[text select rich_text url].include?(field[:type]) && coerced.is_a?(String) && coerced.strip == ""
          coerced = nil
        end

        present = field[:type] == "boolean" ? coerced == true : coerced.present?
        if present || field[:type] == "boolean"
          definition[name] = coerced
          Rails.logger.debug "Set field #{name} to: #{coerced.inspect}"
        end
      end
    end

    Rails.logger.debug "Final definition: #{definition.inspect}"
    definition
  end

  def process_object_field(object_data, field_config, alt_texts, dimension_desktops, dimension_mobiles, existing_pod)
    Rails.logger.debug "Processing object field with data: #{object_data.inspect}"

    return {} unless object_data.is_a?(Hash)

    object_schema = field_config[:schema] || {}
    processed_object = {}

    object_schema.each do |sub_field_name, sub_field_config|
      sub_field_type = sub_field_config["type"]&.downcase
      raw_value = object_data[sub_field_name]

      Rails.logger.debug "Processing object sub-field #{sub_field_name} (#{sub_field_type}): #{raw_value.inspect}"

      if sub_field_type == "image"
        # Handle image fields within object
        field_name = field_config[:name]
        alt_text = alt_texts&.dig(field_name, sub_field_name) || ""
        dimension_desktop = dimension_desktops&.dig(field_name, sub_field_name) || ""
        dimension_mobile = dimension_mobiles&.dig(field_name, sub_field_name) || ""

        if raw_value.present?
          begin
            parsed_data = JSON.parse(raw_value)
            if parsed_data.is_a?(Hash) && parsed_data["attachment_key"].present?
              processed_object[sub_field_name] = {
                "attachment_key" => parsed_data["attachment_key"],
                "alt_text" => alt_text.present? ? alt_text : parsed_data["alt_text"],
                "dimension_desktop" => dimension_desktop.present? ? dimension_desktop : parsed_data["dimension_desktop"],
                "dimension_mobile" => dimension_mobile.present? ? dimension_mobile : parsed_data["dimension_mobile"],
                "filename" => parsed_data["filename"],
                "content_type" => parsed_data["content_type"],
                "byte_size" => parsed_data["byte_size"],
                "uploaded_at" => parsed_data["uploaded_at"]
              }
            end
          rescue JSON::ParserError
            processed_object[sub_field_name] = {
              "attachment_key" => raw_value,
              "alt_text" => alt_text,
              "dimension_desktop" => dimension_desktop,
              "dimension_mobile" => dimension_mobile
            }
          end
        end
      elsif sub_field_type == "boolean"
        processed_object[sub_field_name] = ["1", "true", true].include?(raw_value)
      elsif sub_field_type == "number" || sub_field_type == "integer"
        processed_object[sub_field_name] = raw_value.to_i if raw_value.present?
      elsif sub_field_type == "rich_text"
        processed_object[sub_field_name] = raw_value if raw_value.present?
      else
        # Handle text, select, url, etc.
        if raw_value.present? && raw_value.to_s.strip != ""
          processed_object[sub_field_name] = raw_value
        end
      end
    end

    Rails.logger.debug "Final processed object: #{processed_object.inspect}"
    processed_object
  end

  def process_array_field(array_data, field_config, alt_texts, dimension_desktops, dimension_mobiles, existing_pod)
    Rails.logger.debug "Processing array field with data: #{array_data.inspect}"

    return [] unless array_data.is_a?(Hash)

    item_schema = field_config[:item_schema] || {}
    processed_items = []

    # Sort by index to maintain order
    sorted_indices = array_data.keys.map(&:to_i).sort
    Rails.logger.debug "Sorted array indices: #{sorted_indices.inspect}"

    sorted_indices.each do |index|
      item_data = array_data[index.to_s] || {}
      Rails.logger.debug "Processing array item #{index}: #{item_data.inspect}"

      processed_item = {}

      item_schema.each do |sub_field_name, sub_field_config|
        sub_field_type = sub_field_config["type"]&.downcase
        raw_value = item_data[sub_field_name]

        Rails.logger.debug "Processing sub-field #{sub_field_name} (#{sub_field_type}): #{raw_value.inspect}"

        if sub_field_type == "image"
          # Handle image fields within array items
          alt_text_key = "#{field_config[:name]}_#{index}_#{sub_field_name}"
          alt_text = alt_texts&.dig(field_config[:name], index.to_s, sub_field_name) || ""
          dimension_desktop = dimension_desktops&.dig(field_config[:name], index.to_s, sub_field_name) || ""
          dimension_mobile = dimension_mobiles&.dig(field_config[:name], index.to_s, sub_field_name) || ""

          if raw_value.present?
            begin
              parsed_data = JSON.parse(raw_value)
              if parsed_data.is_a?(Hash) && parsed_data["attachment_key"].present?
                processed_item[sub_field_name] = {
                  "attachment_key" => parsed_data["attachment_key"],
                  "alt_text" => alt_text.present? ? alt_text : parsed_data["alt_text"],
                  "dimension_desktop" => dimension_desktop.present? ? dimension_desktop : parsed_data["dimension_desktop"],
                  "dimension_mobile" => dimension_mobile.present? ? dimension_mobile : parsed_data["dimension_mobile"],
                  "filename" => parsed_data["filename"],
                  "content_type" => parsed_data["content_type"],
                  "byte_size" => parsed_data["byte_size"],
                  "uploaded_at" => parsed_data["uploaded_at"]
                }
              end
            rescue JSON::ParserError
              processed_item[sub_field_name] = {
                "attachment_key" => raw_value,
                "alt_text" => alt_text,
                "dimension_desktop" => dimension_desktop,
                "dimension_mobile" => dimension_mobile
              }
            end
          end
        elsif sub_field_type == "boolean"
          processed_item[sub_field_name] = ["1", "true", true].include?(raw_value)
        elsif sub_field_type == "number"
          processed_item[sub_field_name] = raw_value.to_i if raw_value.present?
        else
          # Handle text, rich_text, select, url, etc.
          if raw_value.present?
            processed_item[sub_field_name] = raw_value
          end
        end
      end

      Rails.logger.debug "Processed array item: #{processed_item.inspect}"
      processed_items << processed_item unless processed_item.empty?
    end

    Rails.logger.debug "Final processed array: #{processed_items.inspect}"
    processed_items
  end

  def process_image_field(definition, field_name, attachment_value, alt_texts, dimension_desktops, dimension_mobiles, existing_pod)
    alt_text = alt_texts&.dig(field_name) || ""
    dimension_desktop = dimension_desktops&.dig(field_name) || ""
    dimension_mobile = dimension_mobiles&.dig(field_name) || ""

    if attachment_value.present?
      # Try to parse as JSON first (from form submission)
      begin
        parsed_data = JSON.parse(attachment_value)
        if parsed_data.is_a?(Hash) && parsed_data["attachment_key"].present?
          # It's already structured data from the upload - use it directly
          definition[field_name] = {
            "attachment_key" => parsed_data["attachment_key"],
            "alt_text" => alt_text.present? ? alt_text : parsed_data["alt_text"],
            "dimension_desktop" => dimension_desktop.present? ? dimension_desktop : parsed_data["dimension_desktop"],
            "dimension_mobile" => dimension_mobile.present? ? dimension_mobile : parsed_data["dimension_mobile"],
            "filename" => parsed_data["filename"],
            "content_type" => parsed_data["content_type"],
            "byte_size" => parsed_data["byte_size"],
            "uploaded_at" => parsed_data["uploaded_at"]
          }
          return
        end
      rescue JSON::ParserError
        # Not JSON, treat as attachment key string
      end

      # If we get here, it's a plain attachment key
      definition[field_name] = {
        "attachment_key" => attachment_value,
        "alt_text" => alt_text,
        "dimension_desktop" => dimension_desktop,
        "dimension_mobile" => dimension_mobile
      }
    elsif existing_pod&.definition&.dig(field_name).present?
      # Existing image - update alt text only
      existing_image = existing_pod.definition[field_name]

      if existing_image.is_a?(Hash)
        # Already structured data - update alt text
        definition[field_name] = existing_image.merge("alt_text" => alt_text)
      elsif existing_image.is_a?(String)
        # Legacy attachment key - convert to structured data
        definition[field_name] = {
          "attachment_key" => existing_image,
          "alt_text" => alt_text
        }
      end
    else
      # No image data
      definition.delete(field_name) if alt_text.blank?
    end
  end

  def process_attachments_into_definition
    return unless session[:pending_attachments].present? && @pod.present?

    pending = session[:pending_attachments] || {}
    processed_keys = []

    # Recursively scan the pod.definition for any attachment_key values.
    # Returns an array of attachment_key strings found in the JSON structure.
    scan_for_attachment_keys = lambda do |obj, found|
      case obj
      when Array
        obj.each { |el| scan_for_attachment_keys.call(el, found) }
      when Hash
        obj.each do |k, v|
          if v.is_a?(Hash) && v["attachment_key"].present?
            found << v["attachment_key"]
          else
            scan_for_attachment_keys.call(v, found)
          end
        end
      end
      found
    end

    attachment_keys_in_definition = scan_for_attachment_keys.call(@pod.definition, [])

    Rails.logger.debug "[PodsController] Found attachment keys in definition: #{attachment_keys_in_definition.inspect}"

    attachment_keys_in_definition.uniq.each do |attachment_key|
      next if processed_keys.include?(attachment_key)

      pending_data = pending[attachment_key]
      unless pending_data.present?
        Rails.logger.debug "[PodsController] No pending attachment data for key #{attachment_key}, skipping"
        next
      end

      blob = ActiveStorage::Blob.find_by(id: pending_data["blob_id"])
      unless blob
        Rails.logger.warn "[PodsController] Pending attachment blob not found for key #{attachment_key}, blob_id: #{pending_data['blob_id']}"
        next
      end

      # Ensure we don't create duplicate attachments with same name
      existing = ActiveStorage::Attachment.find_by(record: @pod, name: attachment_key, blob_id: blob.id)
      if existing
        Rails.logger.info "[PodsController] Attachment already exists for pod=#{@pod.id} name=#{attachment_key} blob=#{blob.id}"
        processed_keys << attachment_key
        next
      end

      ActiveStorage::Attachment.create!(
        record: @pod,
        name: attachment_key,
        blob: blob
      )
      Rails.logger.info "[PodsController] Created attachment for pod=#{@pod.id} name=#{attachment_key} blob=#{blob.id}"
      processed_keys << attachment_key
    end

    # Clear processed entries from session (remove only processed keys to be safe)
    processed_keys.each { |k| pending.delete(k) }
    session[:pending_attachments] = pending.present? ? pending : nil
    Rails.logger.info "[PodsController] process_attachments_into_definition finished; processed: #{processed_keys.inspect}"
  end
end
