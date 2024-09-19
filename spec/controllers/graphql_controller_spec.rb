require "rails_helper"

# Useful resource: http://graphql.org/learn/serving-over-http/

def parser_error_raised?(response)
  data_is_empty = response["data"].nil?
  error_is_present = (JSON.parse(response.body)["errors"].first["message"] =~ /^Parse error on/)
  data_is_empty && error_is_present
end

describe GraphqlController, type: :request do
  let(:proposal) { create(:proposal) }

  describe "handles GET request" do
    specify "with query string inside query params" do
      get "/graphql", params: { query: "{ proposal(id: #{proposal.id}) { title } }" }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["proposal"]["title"]).to eq(proposal.title)
    end

    specify "with malformed query string" do
      get "/graphql", params: { query: "Malformed query string" }

      expect(response).to have_http_status(:ok)
      expect(parser_error_raised?(response)).to be_truthy
    end

    specify "without query string" do
      get "/graphql"

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body["message"]).to eq("Query string not present")
    end
  end

  describe "handles POST request" do
    let(:json_headers) { { "CONTENT_TYPE" => "application/json" } }

    specify "with json-encoded query string inside body" do
      post "/graphql", params: { query: "{ proposal(id: #{proposal.id}) { title } }" }.to_json,
                       headers: json_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["proposal"]["title"]).to eq(proposal.title)
    end

    specify "with raw query string inside body" do
      graphql_headers = { "CONTENT_TYPE" => "application/graphql" }
      post "/graphql", params: "{ proposal(id: #{proposal.id}) { title } }",
                       headers: graphql_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["proposal"]["title"]).to eq(proposal.title)
    end

    specify "with malformed query string" do
      post "/graphql", params: { query: "Malformed query string" }.to_json, headers: json_headers

      expect(response).to have_http_status(:ok)
      expect(parser_error_raised?(response)).to be_truthy
    end

    it "without query string" do
      post "/graphql", headers: json_headers

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body["message"]).to eq("Query string not present")
    end
  end

  describe "correctly parses query variables" do
    let(:query_string) { "{ proposal(id: #{proposal.id}) { title } }" }

    specify "when absent" do
      get "/graphql", params: { query: query_string }

      expect(response).to have_http_status(:ok)
    end

    specify "when specified as the 'null' string" do
      get "/graphql", params: { query: query_string, variables: "null" }

      expect(response).to have_http_status(:ok)
    end

    specify "when specified as an empty string" do
      get "/graphql", params: { query: query_string, variables: "" }

      expect(response).to have_http_status(:ok)
    end
  end

  context "feature flag is set to false" do
    before { Setting["feature.graphql_api"] = false }

    it "is disabled" do
      expect { get "/graphql" }.to raise_exception(FeatureFlags::FeatureDisabled)
      expect { post "/graphql" }.to raise_exception(FeatureFlags::FeatureDisabled)
    end
  end
end
