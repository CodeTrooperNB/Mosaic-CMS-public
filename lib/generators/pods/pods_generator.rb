require "yaml"
require "rails/generators"


# run - rails generate pods
class PodsGenerator < Rails::Generators::Base
  source_root File.expand_path("templates", __dir__)

  def create_pod_partials
    pods_definition = YAML.load_file(Rails.root.join("config/pod_definitions.yml"))
    pods = pods_definition["pod_definitions"] || {}

    empty_directory "app/views/pods/shared"

    pods.each do |pod_key, pod_def|
      @pod_key = pod_key
      @pod_def = pod_def
      @schema = pod_def["schema"] || {}

      target_file = Rails.root.join("app/views/pods/shared/_#{pod_key}.html.erb")

      if File.exist?(target_file)
        say_status :skipped, "#{target_file} already exists, skipping", :yellow
      else
        create_dynamic_template(target_file)
        say_status :create, "Generated template for #{pod_key}", :green
      end
    end
  end

  private

  def create_dynamic_template(target_file)
    content = generate_template_content
    File.write(target_file, content)
  end

  def generate_template_content
    erb_content = []

    # Add header comment
    erb_content << generate_header_comment
    erb_content << ""

    # Generate main container with CSS classes
    erb_content << generate_main_container_start
    erb_content << ""

    # Process each schema field
    @schema.each do |field_name, field_config|
      erb_content << generate_field_template(field_name, field_config, 2)
      erb_content << ""
    end

    # Close main container
    erb_content << "</div>"

    erb_content.join("\n")
  end

  def generate_header_comment
    <<~COMMENT.chomp
      <%# 
        Pod: #{@pod_def['name']}
        Description: #{@pod_def['description']}
        Category: #{@pod_def['category']}
        Generated from pod_definitions.yml
      %>
    COMMENT
  end

  def generate_main_container_start
    css_classes = ["pod-#{@pod_key.underscore.dasherize}"]
    css_classes << "pod-category-#{@pod_def['category']&.dasherize}" if @pod_def["category"]

    %(<div class="#{css_classes.join(' ')}">)
  end

  def generate_field_template(field_name, field_config, indent_level = 0)
    indent = "  " * indent_level
    field_type = field_config["type"]&.downcase

    case field_type
    when "array"
      generate_array_field(field_name, field_config, indent_level)
    when "object"
      generate_object_field(field_name, field_config, indent_level)
    else
      generate_simple_field(field_name, field_config, indent_level)
    end
  end

  def generate_simple_field(field_name, field_config, indent_level)
    indent = "  " * indent_level
    field_type = field_config["type"]&.downcase
    is_required = field_config["required"] == true

    lines = []

    # Generate conditional check
    condition_check = is_required ? "present?" : "present?"
    lines << "#{indent}<% if data['#{field_name}'].#{condition_check} %>"

    # Generate wrapper div with semantic class
    wrapper_class = "#{@pod_key.underscore.dasherize}-#{field_name.underscore.dasherize}"
    lines << "#{indent}  <div class=\"#{wrapper_class}\">"

    # Generate field-specific content
    case field_type
    when "image"
      lines << generate_image_field_content(field_name, field_config, indent_level + 2)
    when "rich_text"
      lines << generate_rich_text_field_content(field_name, field_config, indent_level + 2)
    when "text"
      lines << generate_text_field_content(field_name, field_config, indent_level + 2)
    when "url"
      lines << generate_url_field_content(field_name, field_config, indent_level + 2)
    when "select"
      lines << generate_select_field_content(field_name, field_config, indent_level + 2)
    when "boolean"
      lines << generate_boolean_field_content(field_name, field_config, indent_level + 2)
    when "number"
      lines << generate_number_field_content(field_name, field_config, indent_level + 2)
    when "date"
      lines << generate_date_field_content(field_name, field_config, indent_level + 2)
    when "email"
      lines << generate_email_field_content(field_name, field_config, indent_level + 2)
    else
      lines << generate_generic_field_content(field_name, field_config, indent_level + 2)
    end

    lines << "#{indent}  </div>"
    lines << "#{indent}<% end %>"

    lines.join("\n")
  end

  def generate_image_field_content(field_name, field_config, indent_level)
    indent = "  " * indent_level

    lines = []
    lines << "#{indent}<div class=\"image-field\">"
    lines << "#{indent}  <%= pod_image_tag(data, :#{field_name}, variant: \"desktop\", class: \"img-responsive\") %>"
    lines << "#{indent}</div>"

    lines.join("\n")
  end

  def generate_rich_text_field_content(field_name, field_config, indent_level)
    indent = "  " * indent_level

    lines = []
    lines << "#{indent}<div class=\"rich-text-content\">"
    lines << "#{indent}  <%= raw data['#{field_name}'] %>"
    lines << "#{indent}</div>"

    lines.join("\n")
  end

  def generate_text_field_content(field_name, field_config, indent_level)
    indent = "  " * indent_level

    # Determine appropriate HTML tag based on field name and context
    tag = determine_text_tag(field_name, field_config)
    css_class = "#{field_name.underscore.dasherize}"

    "#{indent}<#{tag} class=\"#{css_class}\"><%= data['#{field_name}'] %></#{tag}>"
  end

  def generate_url_field_content(field_name, field_config, indent_level)
    indent = "  " * indent_level

    # Check if this is likely a button/CTA field
    if field_name.include?("button") || field_name.include?("cta") || field_name.include?("url")
      # Look for associated text field
      text_field = find_associated_text_field(field_name)
      if text_field
        lines = []
        lines << "#{indent}<% if data['#{text_field}'].present? %>"
        lines << "#{indent}  <%= link_to data['#{text_field}'], data['#{field_name}'], "
        lines << "#{indent}              class: \"btn btn-primary\" %>"
        lines << "#{indent}<% end %>"
        lines.join("\n")
      else
        "#{indent}<%= link_to data['#{field_name}'], data['#{field_name}'], class: \"link\" %>"
      end
    else
      "#{indent}<%= link_to data['#{field_name}'], data['#{field_name}'], class: \"link\" %>"
    end
  end

  def generate_select_field_content(field_name, field_config, indent_level)
    indent = "  " * indent_level
    css_class = "#{field_name.underscore.dasherize}"

    # Apply the select value as a CSS class modifier
    "#{indent}<div class=\"#{css_class} #{css_class}-<%= data['#{field_name}'] %>\">" +
      "\n#{indent}  <!-- Content styled based on selection: <%= data['#{field_name}'] %> -->" +
      "\n#{indent}</div>"
  end

  def generate_boolean_field_content(field_name, field_config, indent_level)
    indent = "  " * indent_level

    lines = []
    lines << "#{indent}<% if data['#{field_name}'] == true %>"
    lines << "#{indent}  <div class=\"#{field_name.underscore.dasherize}-enabled\">"
    lines << "#{indent}    <!-- #{field_config['label'] || field_name.humanize} is enabled -->"
    lines << "#{indent}  </div>"
    lines << "#{indent}<% end %>"

    lines.join("\n")
  end

  def generate_number_field_content(field_name, field_config, indent_level)
    indent = "  " * indent_level
    css_class = "#{field_name.underscore.dasherize}"

    "#{indent}<span class=\"#{css_class}\"><%= data['#{field_name}'] %></span>"
  end

  def generate_date_field_content(field_name, field_config, indent_level)
    indent = "  " * indent_level
    css_class = "#{field_name.underscore.dasherize}"

    "#{indent}<time class=\"#{css_class}\" datetime=\"<%= data['#{field_name}'] %>\">" +
      "\n#{indent}  <%= data['#{field_name}'] %>" +
      "\n#{indent}</time>"
  end

  def generate_email_field_content(field_name, field_config, indent_level)
    indent = "  " * indent_level
    css_class = "#{field_name.underscore.dasherize}"

    "#{indent}<%= mail_to data['#{field_name}'], data['#{field_name}'], class: \"#{css_class}\" %>"
  end

  def generate_generic_field_content(field_name, field_config, indent_level)
    indent = "  " * indent_level
    css_class = "#{field_name.underscore.dasherize}"

    "#{indent}<div class=\"#{css_class}\"><%= data['#{field_name}'] %></div>"
  end

  def generate_array_field(field_name, field_config, indent_level)
    indent = "  " * indent_level
    item_schema = field_config["item_schema"] || {}

    lines = []
    lines << "#{indent}<% if data['#{field_name}'].present? && data['#{field_name}'].is_a?(Array) %>"
    lines << "#{indent}  <div class=\"#{field_name.underscore.dasherize}-collection\">"

    # Add collection header if there's a title
    if field_config["label"]
      lines << "#{indent}    <div class=\"collection-header\">"
      lines << "#{indent}      <h3 class=\"collection-title\">#{field_config['label']}</h3>"
      lines << "#{indent}    </div>"
    end

    lines << "#{indent}    <% data['#{field_name}'].each_with_index do |item, index| %>"
    lines << "#{indent}      <div class=\"#{field_name.underscore.dasherize}-item item-<%= index %>\">"

    # Process each field in the item schema
    item_schema.each do |item_field_name, item_field_config|
      lines << generate_array_item_field(item_field_name, item_field_config, indent_level + 4)
    end

    lines << "#{indent}      </div>"
    lines << "#{indent}    <% end %>"
    lines << "#{indent}  </div>"
    lines << "#{indent}<% end %>"

    lines.join("\n")
  end

  def generate_array_item_field(field_name, field_config, indent_level)
    indent = "  " * indent_level
    field_type = field_config["type"]&.downcase

    lines = []
    lines << "#{indent}<% if item['#{field_name}'].present? %>"
    lines << "#{indent}  <div class=\"item-#{field_name.underscore.dasherize}\">"

    case field_type
    when "image"
      lines << "#{indent}    <%= pod_image_tag(item, :#{field_name}, variant: \"desktop\", class: \"img-responsive\") %>"
    when "rich_text"
      lines << "#{indent}    <%= raw item['#{field_name}'] %>"
    when "url"
      # Check for associated text field
      text_field = find_associated_text_field_in_schema(field_name, field_config)
      if text_field
        lines << "#{indent}    <% if item['#{text_field}'].present? %>"
        lines << "#{indent}      <%= link_to item['#{text_field}'], item['#{field_name}'], class: \"item-link\" %>"
        lines << "#{indent}    <% end %>"
      else
        lines << "#{indent}    <%= link_to item['#{field_name}'], item['#{field_name}'], class: \"item-link\" %>"
      end
    when "boolean"
      lines << "#{indent}    <% if item['#{field_name}'] == true %>"
      lines << "#{indent}      <span class=\"item-#{field_name.underscore.dasherize}-enabled\">✓</span>"
      lines << "#{indent}    <% end %>"
    else
      tag = determine_text_tag(field_name, field_config)
      lines << "#{indent}    <#{tag} class=\"item-#{field_name.underscore.dasherize}\"><%= item['#{field_name}'] %></#{tag}>"
    end

    lines << "#{indent}  </div>"
    lines << "#{indent}<% end %>"

    lines.join("\n")
  end

  def generate_object_field(field_name, field_config, indent_level)
    indent = "  " * indent_level
    object_schema = field_config["schema"] || {}

    lines = []
    lines << "#{indent}<% if data['#{field_name}'].present? && data['#{field_name}'].is_a?(Hash) %>"
    lines << "#{indent}  <% #{field_name}_data = data['#{field_name}'] %>"
    lines << "#{indent}  <div class=\"#{field_name.underscore.dasherize}-object\">"

    # Add object header if there's a title
    if field_config["label"]
      lines << "#{indent}    <div class=\"object-header\">"
      lines << "#{indent}      <h3 class=\"object-title\">#{field_config['label']}</h3>"
      lines << "#{indent}    </div>"
    end

    lines << "#{indent}    <div class=\"object-content\">"

    # Process each field in the object schema
    object_schema.each do |obj_field_name, obj_field_config|
      lines << generate_object_field_content(field_name, obj_field_name, obj_field_config, indent_level + 3)
    end

    lines << "#{indent}    </div>"
    lines << "#{indent}  </div>"
    lines << "#{indent}<% end %>"

    lines.join("\n")
  end

  def generate_object_field_content(parent_field_name, field_name, field_config, indent_level)
    indent = "  " * indent_level
    field_type = field_config["type"]&.downcase

    lines = []
    lines << "#{indent}<% if #{parent_field_name}_data['#{field_name}'].present? %>"
    lines << "#{indent}  <div class=\"object-#{field_name.underscore.dasherize}\">"

    case field_type
    when "image"
      lines << "#{indent}    <%= image_tag #{parent_field_name}_data['#{field_name}'], "
      lines << "#{indent}                    alt: (#{parent_field_name}_data['#{field_name}_alt'] || '#{field_config['label'] || field_name.humanize}'), "
      lines << "#{indent}                    class: \"object-image\" %>"
    when "rich_text"
      lines << "#{indent}    <%= raw #{parent_field_name}_data['#{field_name}'] %>"
    when "url"
      # Look for associated text field in the same object
      text_field = find_associated_text_field_in_object(field_name, parent_field_name)
      if text_field
        lines << "#{indent}    <% if #{parent_field_name}_data['#{text_field}'].present? %>"
        lines << "#{indent}      <%= link_to #{parent_field_name}_data['#{text_field}'], #{parent_field_name}_data['#{field_name}'], "
        lines << "#{indent}                  class: \"btn object-btn\" %>"
        lines << "#{indent}    <% end %>"
      else
        lines << "#{indent}    <%= link_to #{parent_field_name}_data['#{field_name}'], #{parent_field_name}_data['#{field_name}'], class: \"object-link\" %>"
      end
    when "boolean"
      lines << "#{indent}    <% if #{parent_field_name}_data['#{field_name}'] == true %>"
      lines << "#{indent}      <span class=\"object-#{field_name.underscore.dasherize}-enabled\">✓</span>"
      lines << "#{indent}    <% end %>"
    else
      tag = determine_text_tag(field_name, field_config)
      lines << "#{indent}    <#{tag} class=\"object-#{field_name.underscore.dasherize}\"><%= #{parent_field_name}_data['#{field_name}'] %></#{tag}>"
    end

    lines << "#{indent}  </div>"
    lines << "#{indent}<% end %>"

    lines.join("\n")
  end

  # Helper methods for intelligent field detection
  def determine_text_tag(field_name, field_config)
    field_name_lower = field_name.to_s.downcase

    case field_name_lower
    when /title|heading|name$/
      if field_name_lower.include?("sub")
        "h3"
      elsif field_name_lower.include?("main") || field_name_lower == "title"
        "h2"
      else
        "h3"
      end
    when /description|content|text|message/
      "p"
    when /label|caption/
      "span"
    else
      "div"
    end
  end

  def find_associated_text_field(url_field_name)
    url_field_lower = url_field_name.to_s.downcase

    # Look for common patterns
    possible_text_fields = []

    if url_field_lower.include?("button")
      base_name = url_field_lower.gsub(/_?url$/, "").gsub(/url_?/, "")
      possible_text_fields = ["#{base_name}_text", "#{base_name}text", "button_text"]
    elsif url_field_lower.include?("cta")
      base_name = url_field_lower.gsub(/_?url$/, "").gsub(/url_?/, "")
      possible_text_fields = ["#{base_name}_text", "#{base_name}text", "cta_text"]
    elsif url_field_lower.include?("link")
      base_name = url_field_lower.gsub(/_?url$/, "").gsub(/url_?/, "")
      possible_text_fields = ["#{base_name}_text", "#{base_name}text", "link_text"]
    end

    # Check if any of these fields exist in the schema
    possible_text_fields.each do |text_field|
      return text_field if @schema[text_field]
    end

    nil
  end

  def find_associated_text_field_in_schema(url_field_name, parent_schema)
    # Similar logic but for array item schemas
    url_field_lower = url_field_name.to_s.downcase

    possible_text_fields = []

    if url_field_lower.include?("url")
      base_name = url_field_lower.gsub(/_?url$/, "").gsub(/url_?/, "")
      possible_text_fields = ["#{base_name}_text", "#{base_name}text", "text", "title", "label"]
    end

    # Check parent schema for these fields
    possible_text_fields.each do |text_field|
      return text_field if parent_schema && parent_schema[text_field]
    end

    nil
  end

  def find_associated_text_field_in_object(url_field_name, parent_field_name)
    url_field_lower = url_field_name.to_s.downcase

    possible_text_fields = []

    if url_field_lower.include?("url")
      base_name = url_field_lower.gsub(/_?url$/, "").gsub(/url_?/, "")
      possible_text_fields = ["#{base_name}_text", "text", "title", "label"]
    end

    # Check the object schema for these fields
    object_schema = @schema.dig(parent_field_name, "schema")
    return nil unless object_schema

    possible_text_fields.each do |text_field|
      return text_field if object_schema[text_field]
    end

    nil
  end
end