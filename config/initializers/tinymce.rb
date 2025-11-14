# frozen_string_literal: true

# TinyMCE Rails configuration
Rails.application.config.tinymce.default_script_attributes = {
  'data-turbo-track': 'reload',
  defer: true
}

# Configure TinyMCE settings
Rails.application.config.tinymce = ActiveSupport::OrderedOptions.new
Rails.application.config.tinymce.base = '/assets/tinymce'
Rails.application.config.tinymce.default_script_attributes = {
  'data-turbo-track': 'reload',
  defer: true
}