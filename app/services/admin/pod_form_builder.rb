module Admin
  class PodFormBuilder
    attr_reader :schema, :supported_fields

    def initialize(schema:)
      @schema = schema || {}
      @supported_fields = build_supported_fields
    end

    def build_supported_fields
      return [] unless @schema["schema"].is_a?(Hash)

      @schema["schema"].map do |field_name, field_config|
        {
          name: field_name,
          type: field_config["type"],
          label: field_config["label"] || field_name.humanize,
          placeholder: field_config["placeholder"],
          help: field_config["help"],
          required: field_config["required"] == true,
          options: field_config["options"],
          min_items: field_config["min_items"],
          max_items: field_config["max_items"],
          item_schema: field_config["item_schema"],
          schema: field_config["schema"],
          crop_ratios: field_config["crop_ratios"],
          accept: field_config["accept"],
          max_size: field_config["max_size"],
          condition: field_config["condition"]
        }
      end
    end

    def coerce_value(value, type)
      return value if value.nil?

      case type.to_s.downcase
      when "boolean"
        ["1", "true", true].include?(value)
      when "number", "integer"
        value.to_i
      when "array"
        value.is_a?(Array) ? value : []
      when "object"
        value.is_a?(Hash) ? value : {}
      else
        value.to_s
      end
    end

    def array_field?(field_name)
      field = supported_fields.find { |f| f[:name] == field_name }
      field&.dig(:type) == "array"
    end

    def object_field?(field_name)
      field = supported_fields.find { |f| f[:name] == field_name }
      field&.dig(:type) == "object"
    end

    def get_array_item_schema(field_name)
      field = supported_fields.find { |f| f[:name] == field_name }
      field&.dig(:item_schema) || {}
    end

    def get_object_schema(field_name)
      field = supported_fields.find { |f| f[:name] == field_name }
      field&.dig(:schema) || {}
    end

    def get_field_config(field_name)
      supported_fields.find { |f| f[:name] == field_name }
    end
  end
end