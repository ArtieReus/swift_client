
require File.expand_path("../test_helper", __FILE__)

class SwiftClientTest < MiniTest::Test
  def setup
    stub_request(:get, "https://example.com/auth/v1.0").with(:headers => { "X-Auth-Key" => "secret", "X-Auth-User" => "account:username" }).to_return(:status => 200, :body => "", :headers => { "X-Auth-Token" => "Token", "X-Storage-Url" => "https://example.com/v1/AUTH_account" })

    @swift_client = SwiftClient.new(:auth_url => "https://example.com/auth/v1.0", :username => "account:username", :api_key => "secret", :temp_url_key => "Temp url key")

    assert_equal "Token", @swift_client.auth_token
    assert_equal "https://example.com/v1/AUTH_account", @swift_client.storage_url
  end

  def test_storage_url
    stub_request(:get, "https://example.com/auth/v1.0").with(:headers => { "X-Auth-Key" => "secret", "X-Auth-User" => "account:username" }).to_return(:status => 200, :body => "", :headers => { "X-Auth-Token" => "Token", "X-Storage-Url" => "https://example.com/v1/AUTH_account" })

    @swift_client = SwiftClient.new(:auth_url => "https://example.com/auth/v1.0", :username => "account:username", :api_key => "secret", :storage_url => "https://storage-url.com/path")

    assert_equal "Token", @swift_client.auth_token
    assert_equal "https://storage-url.com/path", @swift_client.storage_url
  end

  def test_post_account
    stub_request(:post, "https://example.com/v1/AUTH_account/").with(:headers => { "Accept" => "application/json", "X-Auth-Token" => "Token", "X-Account-Meta-Test" => "Test" }).to_return(:status => 204, :body => "", :headers => { "Content-Type" => "application/json" })

    assert_equal 204, @swift_client.post_account("X-Account-Meta-Test" => "Test").code
  end

  def test_get_containers
    containers = [
      { "count" => 1, "bytes" => 1, "name" => "container-1" },
      { "count" => 1, "bytes" => 1, "name" => "container-2" }
    ]

    stub_request(:get, "https://example.com/v1/AUTH_account/").with(:headers => { "Accept" => "application/json", "X-Auth-Token" => "Token" }).to_return(:status => 200, :body => JSON.dump(containers), :headers => { "Content-Type" => "application/json" })

    assert_equal containers, @swift_client.get_containers.parsed_response
  end

  def test_get_container
    objects = [
      { "hash" => "Hash", "last_modified" => "Last modified", "bytes" => 1, "name" => "object-2", "content_type" => "Content type" },
      { "hash" => "Hash", "last_modified" => "Last modified", "bytes" => 1, "name" => "object-3", "content_type" => "Content type" }
    ]

    stub_request(:get, "https://example.com/v1/AUTH_account/container-1?limit=2&marker=object-2").with(:headers => { "Accept" => "application/json", "X-Auth-Token" => "Token" }).to_return(:status => 200, :body => JSON.dump(objects), :headers => { "Content-Type" => "application/json" })

    assert_equal objects, @swift_client.get_container("container-1", :limit => 2, :marker => "object-2").parsed_response
  end

  def test_head_container
    stub_request(:head, "https://example.com/v1/AUTH_account/container-1").with(:headers => { "Accept" => "application/json", "X-Auth-Token" => "Token" }).to_return(:status => 204, :body => "", :headers => { "Content-Type" => "application/json" })

    assert 204, @swift_client.head_container("container-1").code
  end

  def test_put_container
    stub_request(:put, "https://example.com/v1/AUTH_account/container").with(:headers => { "Accept" => "application/json", "X-Auth-Token" => "Token", "X-Container-Read" => ".r:*" }).to_return(:status => 201, :body => "", :headers => {})

    assert_equal 201, @swift_client.put_container("container", "X-Container-Read" => ".r:*").code
  end

  def test_post_container
    stub_request(:post, "https://example.com/v1/AUTH_account/container").with(:headers => { "Accept" => "application/json", "X-Auth-Token" => "Token", "X-Container-Read" => ".r:*" }).to_return(:status => 204, :body => "", :headers => {})

    assert_equal 204, @swift_client.post_container("container", "X-Container-Read" => ".r:*").code
  end

  def test_delete_container
    stub_request(:delete, "https://example.com/v1/AUTH_account/container").with(:headers => { "Accept" => "application/json", "X-Auth-Token" => "Token" }).to_return(:status => 204, :body => "", :headers => {})

    assert_equal 204, @swift_client.delete_container("container").code
  end

  def test_put_object
    stub_request(:put, "https://example.com/v1/AUTH_account/container/object").with(:body => "data", :headers => { "Accept" => "application/json", "X-Auth-Token" => "Token", "X-Object-Meta-Test" => "Test" }).to_return(:status => 201, :body => "", :headers => {})

    assert_equal 201, @swift_client.put_object("object", "data", "container", "X-Object-Meta-Test" => "Test").code
  end

  def test_put_object_with_io
    stub_request(:put, "https://example.com/v1/AUTH_account/container/object").with(:body => "data", :headers => { "Accept" => "application/json", "X-Auth-Token" => "Token", "X-Object-Meta-Test" => "Test" }).to_return(:status => 201, :body => "", :headers => {})

    assert_equal 201, @swift_client.put_object("object", StringIO.new("data"), "container", "X-Object-Meta-Test" => "Test").code
  end

  def test_post_object
    stub_request(:post, "https://example.com/v1/AUTH_account/container/object").with(:headers => { "Accept" => "application/json", "X-Auth-Token" => "Token", "X-Object-Meta-Test" => "Test" }).to_return(:status => 201, :body => "", :headers => {})

    assert_equal 201, @swift_client.post_object("object", "container", "X-Object-Meta-Test" => "Test").code
  end

  def test_get_object
    stub_request(:get, "https://example.com/v1/AUTH_account/container/object").with(:headers => { "Accept" => "application/json", "X-Auth-Token" => "Token" }).to_return(:status => 200, :body => "Body", :headers => {})

    assert_equal "Body", @swift_client.get_object("object", "container").body
  end

  def test_head_object
    stub_request(:head, "https://example.com/v1/AUTH_account/container/object").with(:headers => { "Accept" => "application/json", "X-Auth-Token" => "Token" }).to_return(:status => 200, :body => "", :headers => {})

    assert_equal 200, @swift_client.head_object("object", "container").code
  end

  def test_delete_object
    stub_request(:delete, "https://example.com/v1/AUTH_account/container/object").with(:headers => { "Accept" => "application/json", "X-Auth-Token" => "Token" }).to_return(:status => 204, :body => "", :headers => {})

    assert_equal 204, @swift_client.delete_object("object", "container").code
  end

  def test_get_objects
    objects = [
      { "hash" => "Hash", "last_modified" => "Last modified", "bytes" => 1, "name" => "object-2", "content_type" => "Content type" },
      { "hash" => "Hash", "last_modified" => "Last modified", "bytes" => 1, "name" => "object-3", "content_type" => "Content type" }
    ]

    stub_request(:get, "https://example.com/v1/AUTH_account/container-1?limit=2&marker=object-2").with(:headers => { "Accept" => "application/json", "X-Auth-Token" => "Token" }).to_return(:status => 200, :body => JSON.dump(objects), :headers => { "Content-Type" => "application/json" })

    assert_equal objects, @swift_client.get_container("container-1", :limit => 2, :marker => "object-2").parsed_response
  end

  def test_not_found
    stub_request(:get, "https://example.com/v1/AUTH_account/container/object").with(:headers => { "Accept" => "application/json", "X-Auth-Token" => "Token" }).to_return(:status => [404, "Not Found"], :body => "", :headers => { "Content-Type" => "application/json" })

    begin
      @swift_client.get_object("object", "container")
    rescue SwiftClient::ResponseError => e
      assert_equal 404, e.code
      assert_equal "Not Found", e.message
    end
  end

  def test_public_url
    assert_equal "https://example.com/v1/AUTH_account/container/object", @swift_client.public_url("object", "container")
  end

  def test_temp_url
    assert @swift_client.temp_url("object", "container", :expires_in => 3600) =~ %r{https://example.com/v1/AUTH_account/container/object\?temp_url_sig=[a-f0-9]{40}&temp_url_expires=[0-9]+}
  end
end

