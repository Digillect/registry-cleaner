class NexusClient
  def initialize(uri, login, password)
    @resource = RestClient::Resource.new("#{uri}/service/rest/beta", login, password)
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
      response = @resource['components'].get(params: params, accept: :json)
      json = JSON.parse(response.body, symbolize_names: true)

      json[:items].each do |item|
        yield item if block_given?
      end

      continuation_token = json[:continuationToken]

      break unless continuation_token
    end
  end

  def delete_component(id)
    @logger.debug("Deleting component #{id}")
    @resource["components/#{id}"].delete
  end

  def delete_asset(id)
    @logger.debug("Deleting asset #{id}")
    @resource["assets/#{id}"].delete
  end
end
