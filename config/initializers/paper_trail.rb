PaperTrail.config.enabled = true
PaperTrail.config.has_paper_trail_defaults = {
  on: %i[create update destroy],
  ignore: [:updated_at, :created_at, :id]
}
PaperTrail.config.version_limit = 5

# Use JSON serializer to avoid YAML deserialization of Ruby objects (e.g. ActiveSupport::TimeWithZone)
# This prevents Psych::DisallowedClass errors when reifying versions that include time objects.
PaperTrail.config.serializer = PaperTrail::Serializers::JSON
