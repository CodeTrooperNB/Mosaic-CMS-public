# Monkey patch for older Annotate gem
if Rails.env.development?
  unless File.respond_to?(:exists?)
    def File.exists?(path)
      File.exist?(path)
    end
  end

  unless defined?(Fixnum)
    Fixnum = Integer
  end

  unless defined?(Bignum)
    Bignum = Integer
  end
end