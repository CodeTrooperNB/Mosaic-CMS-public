module Admin
  module SettingsHelper
    # Recursively renders a hash structure (like application settings) into an HTML unordered list.
    # It handles nested hashes and arrays for a clean, hierarchical display with Tailwind styling.
    # Includes dark mode compatibility for text colors and hierarchical text sizing.
    def render_settings_hash(settings_hash, level = 0)
      # Apply distinct styling for different levels of nesting
      ul_classes = if level == 0
                     "list-none space-y-3" # More vertical space for top-level items
                   else
                     "list-none ml-6 space-y-2" # Indent and slightly less space for nested items
                   end

      # Determine text size class based on level for hierarchical display
      key_text_size_class = case level
                            when 0 then "text-base" # Main keys are slightly larger
                            when 1 then "text-sm"   # First level nested keys
                            else "text-sm"          # Deeper nested keys, same size as list item but bold
                            end

      content_tag(:ul, class: ul_classes) do
        settings_hash.map do |key, value|
          # Base styling for each list item, with dark mode text color
          content_tag(:li, class: "text-gray-700 dark:text-gray-300 text-sm") do
            if value.is_a?(Hash)
              # For hashes, display the key with stronger emphasis and recursively render its content
              # Dark mode for key text color
              content_tag(:strong, "#{key.to_s.humanize}:", class: "font-medium #{key_text_size_class} text-gray-900 dark:text-white") +
                render_settings_hash(value, level + 1)
            elsif value.is_a?(Array)
              # For arrays, display the key and then list array items with further indentation
              # Dark mode for key text color and array item text color
              content_tag(:strong, "#{key.to_s.humanize}:", class: "font-medium #{key_text_size_class} text-gray-900 dark:text-white") +
                content_tag(:ul, class: "list-disc ml-8 space-y-0.5 text-gray-600 dark:text-gray-400") do # Specific styling for array lists
                  value.map { |item| content_tag(:li, item.to_s) }.join.html_safe
                end
            else
              # For simple key-value pairs, display key with emphasis and value
              # Dark mode for key text color
              content_tag(:strong, "#{key.to_s.humanize}: ", class: "font-medium #{key_text_size_class} text-gray-900 dark:text-white") + value.to_s
            end
          end
        end.join.html_safe # Join all <li> elements
      end
    end
  end
end