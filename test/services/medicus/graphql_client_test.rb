# frozen_string_literal: true

require "test_helper"
require "json"

class MedicusGraphqlClientTest < ActiveSupport::TestCase
  setup do
    # Stub Settings values for test
    Settings.medicus.client_id = ENV["MEDICUS_CLIENT_ID"]
    Settings.medicus.api_key = ENV["MEDICUS_API_KEY"]
    Settings.medicus.brand_host = ENV["MEDICUS_BRAND_HOST"]
    Settings.medicus.timeouts.open_timeout = 1
    Settings.medicus.timeouts.read_timeout = 1
    Settings.medicus.retries.attempts = 0
    Settings.medicus.retries.base_backoff_seconds = 0
  end

  def build_response(code: "200", body: { data: { ok: true } }.to_json)
    Struct.new(:code, :body) do
      def is_a?(k)
        # Pretend to be Net::HTTPSuccess when code starts with 2
        if k == Net::HTTPSuccess
          code.to_s.start_with?("2")
        else
          super
        end
      end
    end.new(code, body)
  end

  test "execute builds correct headers and payload" do
    client = Medicus::GraphqlClient.new

    called = false
    test = self
    client.define_singleton_method(:perform_http_post) do |uri, json, token:, correlation_id:|
      called = true
      test.assert_equal "http://peak.localhost:3000/graphql", uri.to_s
      payload = JSON.parse(json)
      test.assert_equal "{ ping }", payload["query"]
      test.assert_equal({ "a" => 1 }, payload["variables"])
      test.assert_equal "Op", payload["operationName"]
      # Return a fake success response
      test.build_response
    end

    res = client.execute(query: "{ ping }", variables: { a: 1 }, operation_name: "Op", token: "jwt.token")
    assert called, "perform_http_post should be called"
    assert_equal({ "data" => { "ok" => true } }, res)
  end

  test "batch wraps operations array" do
    client = Medicus::GraphqlClient.new

    test = self
    client.define_singleton_method(:perform_http_post) do |_uri, json, **_kargs|
      arr = JSON.parse(json)
      test.assert_kind_of Array, arr
      test.assert_equal 2, arr.size
      test.assert_equal "{ a }", arr[0]["query"]
      test.assert_equal "{ b }", arr[1]["query"]
      test.build_response
    end

    client.batch([
      { query: "{ a }" },
      { query: "{ b }", variables: { x: 1 } }
    ])
  end

  test "raises when missing credentials" do
    Settings.medicus.client_id = nil
    client = Medicus::GraphqlClient.new
    assert_raises(ArgumentError) { client.execute(query: "{ ping }") }
  end
end
