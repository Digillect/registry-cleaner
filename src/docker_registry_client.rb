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
      response = execute(url, :get, headers)

      json = JSON.parse(response.body, symbolize_names: true)

      yield(json) if block_given?

      url = next_page_url(response)
    end
  end

  def execute(url, method, payload = nil, headers = nil)
    headers = setup_headers(headers)

    begin
      return RestClient::Request.execute(method: method, url: url, payload: payload, headers: headers)
    rescue RestClient::Unauthorized => err
      www_authenticate = err.http_headers[:www_authenticate]
    end

    return unless @authenticator.authenticate(www_authenticate)

    headers = setup_headers(headers)

    RestClient::Request.execute(method: method, url: url, payload: payload, headers: headers)
  end

  private

  LINK_REGEXP = /^<(.+)>;\s*rel="next"$/
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
