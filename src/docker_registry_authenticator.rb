class DockerRegistryAuthenticator
  def initialize(username, password, widen_scope)
    @username = username
    @password = password
    @widen_scope = widen_scope

    @tokens = {}

    @token = nil

    @logger = SemanticLogger[DockerRegistryAuthenticator]
  end

  attr_reader :token

  def authenticated?
    @token.present?
  end

  def authenticate(www_authenticate)
    @token = nil

    @logger.debug("WWW Authenticate: #{www_authenticate}")

    realm, service, scope = parse_authentication_header(www_authenticate)

    return unless realm

    scope = scope.gsub(/:[a-zA-z,]+$/, ':*') unless scope.end_with?(':*') || !@widen_scope

    if @tokens.key?(scope)
      @token = @tokens[scope]

      return @token
    end

    @logger.debug("Performing authentication with #{realm}, scope #{scope}")

    url = authentication_url(realm, service, scope)

    begin
      conn = Faraday.new(url) do |c|
        c.response(:json, content_type: /\bjson$/, parser_options: { symbolize_names: true })

        c.basic_auth(@username, @password)

        c.adapter(Faraday.default_adapter)
      end

      response = conn.get

      @token = response.body[:token]
    rescue StandardError => e
      raise "Unable to authenticate at #{realm}: #{e}"
    end

    @tokens[scope] = @token

    @token
  end

  private

  REALM_REGEXP = /realm="([^"]+)"/.freeze
  SERVICE_REGEXP = /service="([^"]+)"/.freeze
  SCOPE_REGEXP = /scope="([^"]+)"/.freeze

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
    scope = extract(SCOPE_REGEXP, www_authenticate) || ':*'

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
