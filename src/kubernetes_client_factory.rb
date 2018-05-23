class KubernetesClientFactory
  def initialize(configuration)
    @configuration = configuration
    @logger = SemanticLogger[KubernetesClientFactory]

    if inside_the_cluster?
      setup_options_from_cluster
    else
      read_options_from_config_file
    end

    @clients = {}
  end

  def create_client(endpoint = nil, api_version = nil)
    api_endpoint = @api_endpoint
    api_endpoint = api_endpoint + '/apis/' + endpoint if endpoint
    api_version ||= @api_version

    key = "#{api_endpoint}/#{api_version}"

    if @clients.key?(key)
      client = @clients[key]
    else
      @logger.debug("Creating client with endpoint '#{api_endpoint}', API version '#{api_version}'")

      client = Kubeclient::Client.new(api_endpoint, api_version, @api_options)

      @clients[key] = client
    end

    client
  end

  private

  SERVICE_ACCOUNT_TOKEN_FILE = '/var/run/secrets/kubernetes.io/serviceaccount/token'.freeze
  SERVICE_ACCOUNT_CA_FILE = '/var/run/secrets/kubernetes.io/serviceaccount/ca.crt'.freeze
  CONFIG_FILE_PATH = '~/.kube/config'.freeze

  def inside_the_cluster?
    File.exist?(SERVICE_ACCOUNT_TOKEN_FILE)
  end

  def setup_options_from_cluster
    @logger.debug('Using Kubernetes service files')

    @api_endpoint = 'https://kubernetes.default.svc'
    @api_version = 'v1'
    @api_options = {
      auth_options: {
        bearer_token_file: SERVICE_ACCOUNT_TOKEN_FILE
      },
      ssl_options: File.exist?(SERVICE_ACCOUNT_CA_FILE) ? { ca_file: SERVICE_ACCOUNT_CA_FILE } : {}
    }
  end

  def read_options_from_config_file
    @logger.debug("Reading configuration from file #{CONFIG_FILE_PATH}")

    config = Kubeclient::Config.read(File.expand_path(CONFIG_FILE_PATH))
    context = config.context

    @api_endpoint = context.api_endpoint
    @api_version = context.api_version
    @api_options = {
      auth_options: context.auth_options,
      ssl_options: context.ssl_options
    }
  end
end
