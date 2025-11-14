# frozen_string_literal: true

require "yaml"

module Admin
  class PodSchemas
    class LoadError < StandardError; end
    class ValidationError < StandardError; end

    CONFIG_PATH = Rails.root.join("config", "pod_definitions.yml").freeze
    FALLBACK_DOCS_PATH = Rails.root.join("docs", "pod_definitions.yml").freeze

    # Singleton
    def self.instance
      @instance ||= new
    end

    def self.reload!
      instance.send(:load!)
    end

    def self.validate!
      instance.validate!
    end

    def self.available_types
      instance.available_types
    end

    def self.schema_for(type)
      instance.schema_for(type)
    end

    def self.categories
      instance.categories
    end

    def initialize
      load!
    end

    def available_types
      pod_definitions.keys
    end

    def schema_for(type)
      pod_definitions[type.to_s]
    end

    def categories
      raw["categories"] || {}
    end

    def validate!
      raise ValidationError, "No pod definitions loaded" if pod_definitions.empty?

      pod_definitions.each do |type, spec|
        unless spec.is_a?(Hash)
          raise ValidationError, "Pod type '#{type}' must map to a Hash"
        end
        %w[name category schema].each do |key|
          raise ValidationError, "Pod '#{type}' missing '#{key}'" unless spec.key?(key)
        end
        schema = spec["schema"]
        unless schema.is_a?(Hash)
          raise ValidationError, "Pod '#{type}' schema must be a Hash"
        end
        schema.each do |field, cfg|
          unless cfg.is_a?(Hash) && cfg["type"].is_a?(String)
            raise ValidationError, "Field '#{field}' in pod '#{type}' must have a 'type'"
          end
        end
      end

      true
    end

    private

    attr_reader :raw, :pod_definitions

    def load!
      path = if File.exist?(CONFIG_PATH)
        CONFIG_PATH
      elsif File.exist?(FALLBACK_DOCS_PATH)
        FALLBACK_DOCS_PATH
      else
        raise LoadError, "pod_definitions.yml not found in config/ or docs/"
      end

      @raw = YAML.load_file(path)

      unless @raw.is_a?(Hash)
        raise LoadError, "pod_definitions.yml must parse to a Hash"
      end

      pods_hash = @raw["pod_definitions"] || @raw["pods"]
      unless pods_hash.is_a?(Hash)
        raise LoadError, "pod_definitions.yml must have a 'pod_definitions' Hash"
      end

      @pod_definitions = pods_hash

      self
    end
  end
end
