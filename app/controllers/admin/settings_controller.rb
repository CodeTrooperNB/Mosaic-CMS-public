class Admin::SettingsController < Admin::AdminController
  # This controller displays the application settings loaded by the 'config' gem.
  # It inherits from Admin::AdminController for administrative access control.
  include ::Admin::SettingsHelper

  def index
    # The `Settings` object, provided by the `config` gem, already
    # contains the merged and processed values from settings.yml,
    # environment variables, and any local overrides.
    # We convert it to a plain Ruby hash for easier display in the view.
    @settings = Settings.to_h
  end
end
