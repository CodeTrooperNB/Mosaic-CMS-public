# frozen_string_literal: true

require "net/http"
require "json"
require "securerandom"

module Medicus
  # Lightweight GraphQL HTTP client tailored for the Medicus Hub
  # Reads configuration from Settings.medicus (config/settings.yml)
  # and follows the CLIENT_APP_INTEGRATION_GUIDE contract.
  class GraphqlClient
    DEFAULT_PATH = "/graphql"

    class HttpError < StandardError
      attr_reader :status, :body, :correlation_id

      def initialize(message, status:, body:, correlation_id: nil)
        super(message)
        @status = status
        @body = body
        @correlation_id = correlation_id
      end
    end

    def initialize(host: Settings.medicus.brand_host, path: DEFAULT_PATH)
      @host, @port = normalize_host_and_port(host)
      @path = path
      @client_id = Settings.medicus.client_id
      @api_key = Settings.medicus.api_key
      @timeouts = Settings.medicus.timeouts || OpenStruct.new(open_timeout: 5, read_timeout: 15)
      @retries = Settings.medicus.retries || OpenStruct.new(attempts: 2, base_backoff_seconds: 2)
      @extra_headers = (Settings.medicus.extra_headers&.all || {}).transform_keys(&:to_s)
    end

    # Execute a single GraphQL operation.
    #
    # Params:
    # - query: String (required)
    # - variables: Hash or nil
    # - operation_name: String or nil
    # - token: Optional JWT string for Authorization header
    # - correlation_id: Optional correlation id for tracing; generated if nil
    # Returns parsed JSON (Hash) with keys "data" and optional "errors"
    def execute(query:, variables: nil, operation_name: nil, token: nil, correlation_id: nil)
      payload = { "query" => query }
      payload["variables"] = variables if variables
      payload["operationName"] = operation_name if operation_name

      puts response = request(payload, token: token, correlation_id: correlation_id)
      response
    end

    # Execute a batched set of operations (array payload)
    # Each item: { query:, variables:, operationName: }
    # Returns parsed JSON Array of results in order
    def batch(operations, token: nil, correlation_id: nil)
      shaped = operations.map do |op|
        h = { "query" => op[:query] || op["query"] }
        vars = op[:variables] || op["variables"]
        opn  = op[:operation_name] || op[:operationName] || op["operationName"]
        h["variables"] = vars if vars
        h["operationName"] = opn if opn
        h
      end
      request(shaped, token: token, correlation_id: correlation_id)
    end

    private

    def request(body_obj, token:, correlation_id: nil)
      raise ArgumentError, "Medicus client_id is missing (Settings.medicus.client_id)" if blank?(@client_id)
      raise ArgumentError, "Medicus api_key is missing (Settings.medicus.api_key)" if blank?(@api_key)
      raise ArgumentError, "Medicus brand_host is missing (Settings.medicus.brand_host)" if blank?(@host)

      uri = if @port
        URI::HTTP.build(host: @host, port: @port, path: @path)
      else
        URI::HTTPS.build(host: @host, path: @path)
      end
      Rails.logger.info "Medicus GraphQL request: #{uri.to_s}"

      json = JSON.generate(body_obj)
      corr = correlation_id.presence || SecureRandom.uuid

      Rails.logger.info "Medicus GraphQL request: #{json}"
      Rails.logger.info "Medicus GraphQL correlation id: #{corr}"

      attempt = 0
      begin
        attempt += 1
        res = perform_http_post(uri, json, token: token, correlation_id: corr)
        Rails.logger.info "Medicus GraphQL response: #{res.inspect}"
        unless res.is_a?(Net::HTTPSuccess)
          raise HttpError.new("GraphQL HTTP error #{res.code}", status: res.code.to_i, body: res.body.to_s, correlation_id: corr)
        end
        parse_response(res.body)
      rescue HttpError => e
        raise e if attempt > @retries.attempts.to_i
        sleep(backoff_for(attempt))
        retry
      rescue Timeout::Error, Errno::ETIMEDOUT, Errno::ECONNRESET, IOError, SocketError, OpenSSL::SSL::SSLError => e
        raise HttpError.new("GraphQL request failed: #{e.class}: #{e.message}", status: 0, body: "", correlation_id: corr) if attempt > @retries.attempts.to_i
        sleep(backoff_for(attempt))
        retry
      end
    end

    def perform_http_post(uri, json, token:, correlation_id:)
      http = Net::HTTP.new(uri.host, uri.port)
      # Honor the URI scheme: only enable TLS when using HTTPS
      http.use_ssl = (uri.scheme == "https")

      http.open_timeout = @timeouts.open_timeout.to_i if @timeouts.respond_to?(:open_timeout)
      http.read_timeout = @timeouts.read_timeout.to_i if @timeouts.respond_to?(:read_timeout)

      req = Net::HTTP::Post.new(uri.request_uri)
      req["Content-Type"] = "application/json"
      req["X-Client-Id"] = @client_id.to_s
      req["X-API-Key"] = @api_key.to_s
      req["X-Correlation-ID"] = correlation_id.to_s
      @extra_headers&.each { |k, v| req[k] = v }
      bearer = token.presence || Settings.medicus.default_customer_jwt.presence
      req["Authorization"] = "Bearer #{bearer}" if bearer
      req.body = json

      http.request(req)
    end

    def parse_response(body)
      JSON.parse(body)
    rescue JSON::ParserError => e
      raise HttpError.new("Invalid JSON response: #{e.message}", status: 200, body: body, correlation_id: nil)
    end

    def backoff_for(attempt)
      base = @retries.base_backoff_seconds.to_i
      base * (2 ** (attempt - 1))
    end

    # Normalize host and optional port when MEDICUS_BRAND_HOST includes a port (e.g., "peak.localhost:3000").
    def normalize_host_and_port(host)
      h = host.to_s.strip
      return [nil, nil] if h.empty?
      # If scheme is present, use URI to parse
      if h.start_with?("http://", "https://")
        u = URI.parse(h)
        return [u.host, u.port]
      end
      if h.include?(":") && !h.start_with?("[")
        name, port = h.split(":", 2)
        return [name, Integer(port)]
      end
      [h, nil]
    rescue
      [h, nil]
    end

    # ActiveSupport-like .blank? via simplified checks to avoid dependency here
    def blank?(value)
      value.nil? || (value.respond_to?(:empty?) && value.empty?)
    end
  end

  # Simple accessor to a singleton client
  module GQL
    module_function

    def client
      @client ||= Medicus::GraphqlClient.new
    end

    def reset!
      @client = nil
    end
  end
end
