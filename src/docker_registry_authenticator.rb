class DockerRegistryAuthenticator
  def initialize(username, password)
    @username = username
    @password = password

    @token = nil

    @logger = SemanticLogger[DockerRegistryAuthenticator]
  end

  attr_reader :token

  def authenticated?
    @token.present?
  end

  def authenticate(www_authenticate)
    @token = nil

    realm, service, scope = parse_authentication_header(www_authenticate)

    return unless realm

    @logger.debug("Performing authentication with #{realm}")

    url = authentication_url(realm, service, scope)

    begin
      response = RestClient::Request.execute(method: :get, url: url, user: @username, password: @password)

      json = JSON.parse(response.body, symbolize_names: true)

      @token = json[:token]
    rescue StandardError => err
      raise "Unable to authenticate at #{realm}: #{err}"
    end

    @token
  end

  private

  REALM_REGEXP = /realm="([^"]+)"/
  SERVICE_REGEXP = /service="([^"]+)"/
  SCOPE_REGEXP = /scope="([^"]+)"/

  def parse_authentication_header(www_authenticate)
    if www_authenticate.blank?
      @logger.error('Header WWW-Authenticate is not set by the registry')

      return nil
    end

    realm = extract(REALM_REGEXP, www_authenticate)

    if realm.blank?
      @logger.error('Unable to find authentication realm from WWW-Authenticate header')

      return nil
    end

    service = extract(SERVICE_REGEXP, www_authenticate)
    scope = extract(SCOPE_REGEXP, www_authenticate)

    [realm, service, scope]
  end

  def authentication_url(realm, service, scope)
    uri = URI.parse(realm)

    query = URI.decode_www_form(uri.query || '')

    query << ['service', service] unless service.blank?
    query << ['scope', scope] unless scope.blank?

    uri.query = URI.encode_www_form(query)

    uri.to_s
  end

  def extract(regexp, text)
    regexp.match(text) do |match_data|
      return match_data[1]
    end
  end
end
