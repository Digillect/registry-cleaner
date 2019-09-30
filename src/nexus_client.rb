class NexusClient
  def initialize(uri, login, password, ssl_verify_peer)
    options = {}

    unless ssl_verify_peer.nil?
      options[:ssl] = {
        verify: ssl_verify_peer
      }
    end

    @conn = Faraday.new("#{uri}/service/rest/v1", options) do |conn|
      conn.response(:json, content_type: /\bjson$/, parser_options: { symbolize_names: true })
      conn.response(:raise_error)

      conn.basic_auth(login, password)

      conn.adapter(Faraday.default_adapter)
    end

    @logger = SemanticLogger[NexusClient]
  end

  def components(repository_id)
    continuation_token = nil

    @logger.debug("Getting list of components for repository '#{repository_id}'")

    loop do
      params = {
        repository: repository_id
      }

      params[:continuationToken] = continuation_token if continuation_token

      response = @conn.get('components', params)
      json = response.body

      json[:items].each do |item|
        yield item if block_given?
      end

      continuation_token = json[:continuationToken]

      break unless continuation_token
    end
  end

  def delete_component(id)
    @logger.debug("Deleting component #{id}")

    @conn.delete("components/#{id}")
  end

  def delete_asset(id)
    @logger.debug("Deleting asset #{id}")

    @conn.delete("assets/#{id}")
  end
end
