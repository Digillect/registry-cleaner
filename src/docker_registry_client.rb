require 'pry'

class DockerRegistryClient
  def initialize(username, password, widen_scope)
    @authenticator = DockerRegistryAuthenticator.new(username, password, widen_scope)

    @logger = SemanticLogger[DockerRegistryClient]
  end

  def get(url, headers = nil)
    execute(url, :get, nil, headers)
  end

  def paged_get(url, headers = nil)
    url = first_page_url(url)

    until url.nil?
      uri = URI.parse(url)

      scheme_and_host = "#{uri.scheme}://#{uri.host}" if scheme_and_host.nil?

      uri = URI.join(scheme_and_host, url) unless uri.absolute?

      response = execute(uri.to_s, :get, headers)
      json = response.body

      yield(json) if block_given?

      url = next_page_url(response)
    end
  end

  def execute(url, method, payload = nil, headers = nil)
    headers = setup_headers(headers)

    conn = Faraday.new(url) do |c|
      c.response(:logger)
      c.response(:json, content_type: /\bjson$/, parser_options: { symbolize_names: true })
      c.response(:raise_error)

      c.basic_auth(@username, @password)

      c.adapter(Faraday.default_adapter)
    end

    begin
      response = conn.run_request(method.to_sym, nil, payload, headers)

      return response
    rescue Faraday::UnauthorizedError => e
      www_authenticate = e.response[:headers]['www-authenticate']
    end

    return unless @authenticator.authenticate(www_authenticate)

    headers = setup_headers(headers)

    conn.run_request(method.to_sym, nil, payload, headers)
  end

  private

  LINK_REGEXP = /^<(.+)>;\s*rel="next"$/.freeze
  PAGE_SIZE = 50

  def first_page_url(url)
    uri = URI.parse(url)

    query = URI.decode_www_form(uri.query || '') << ['n', PAGE_SIZE.to_s]
    uri.query = URI.encode_www_form(query)

    uri.to_s
  end

  def next_page_url(response)
    LINK_REGEXP.match(response.headers[:link]) do |match|
      return match[1]
    end
  end

  def setup_headers(headers)
    headers = headers&.dup || {}

    headers[:Authorization] = "Bearer #{@authenticator.token}" if @authenticator.authenticated?

    headers
  end
end
