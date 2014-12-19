
require "swift_client/version"

require "httparty"
require "mime-types"
require "openssl"

class SwiftClient
  class AuthenticationError < StandardError; end
  class OptionError < StandardError; end
  class EmptyNameError < StandardError; end
  class TempUrlKeyMissing < StandardError; end

  class ResponseError < StandardError
    attr_accessor :code, :message

    def initialize(code, message)
      self.code = code
      self.message = message
    end

    def to_s
      "#{code} #{message}"
    end
  end

  attr_accessor :options, :auth_token, :storage_url

  def initialize(options = {})
    [:auth_url, :username, :api_key].each do |key|
      raise(OptionError, "#{key} is missing") unless options.key?(key)
    end

    self.options = options

    authenticate
  end

  def post_account(headers = {})
    request :post, "/", :headers => headers
  end

  def get_containers(query = {})
    request :get, "/", :query => query
  end

  def get_container(container, query = {})
    raise(EmptyNameError) if container.empty?

    request :get, "/#{container}", :query => query
  end

  def head_container(container)
    raise(EmptyNameError) if container.empty?

    request :head, "/#{container}"
  end

  def put_container(container, headers = {})
    raise(EmptyNameError) if container.empty?

    request :put, "/#{container}", :headers => headers
  end

  def post_container(container, headers = {})
    raise(EmptyNameError) if container.empty?

    request :post, "/#{container}", :headers => headers
  end

  def delete_container(container)
    raise(EmptyNameError) if container.empty?

    request :delete, "/#{container}"
  end

  def put_object(object, data_or_io, container, headers = {})
    raise(EmptyNameError) if object.empty? || container.empty?

    mime_type = MIME::Types.of(object).first

    extended_headers = headers.dup
    extended_headers["Content-Type"] ||= mime_type.content_type if mime_type

    request :put, "/#{container}/#{object}", :body => data_or_io.respond_to?(:read) ? data_or_io.read : data_or_io, :headers => extended_headers
  end

  def post_object(object, container, headers = {})
    raise(EmptyNameError) if object.empty? || container.empty?

    request :post, "/#{container}/#{object}", :headers => headers
  end

  def get_object(object, container)
    raise(EmptyNameError) if object.empty? || container.empty?

    request :get, "/#{container}/#{object}"
  end

  def head_object(object, container)
    raise(EmptyNameError) if object.empty? || container.empty?

    request :head, "/#{container}/#{object}"
  end

  def delete_object(object, container)
    raise(EmptyNameError) if object.empty? || container.empty?

    request :delete, "/#{container}/#{object}"
  end

  def get_objects(container, query = {})
    raise(EmptyNameError) if container.empty?

    request :get, "/#{container}", :query => query
  end

  def public_url(object, container)
    raise(EmptyNameError) if object.empty? || container.empty?

    "#{storage_url}/#{container}/#{object}"
  end

  def temp_url(object, container, opts = {})
    raise(EmptyNameError) if object.empty? || container.empty?
    raise(TempUrlKeyMissing) unless options[:temp_url_key]

    expires = (Time.now + (options[:expires_in] || 3600).to_i).to_i
    path = "/#{container}/#{object}"

    signature = OpenSSL::HMAC.hexdigest("sha1", options[:temp_url_key], "GET\n#{expires}\n#{path}")

    "#{storage_url}#{path}?temp_url_sig=#{signature}&temp_url_expires=#{expires}"
  end

  private

  def request(method, path, opts = {})
    opts[:headers] ||= {}
    opts[:headers]["X-Auth-Token"] = auth_token
    opts[:headers]["Accept"] = "application/json"

    response = HTTParty.send(method, "#{storage_url}#{path}", opts)

    if response.code == 401
      authenticate

      return request(method, path, opts)
    end

    raise(ResponseError.new(response.code, response.message)) unless response.success?

    response
  end

  def authenticate
    response = HTTParty.get(options[:auth_url], :headers => { "X-Auth-User" => options[:username], "X-Auth-Key" => options[:api_key] })

    raise(AuthenticationError, "#{response.code}: #{response.message}") unless response.success?

    self.auth_token = response.headers["X-Auth-Token"]
    self.storage_url = options[:storage_url] || response.headers["X-Storage-Url"]
  end
end

