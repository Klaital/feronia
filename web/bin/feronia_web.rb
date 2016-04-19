require 'sinatra/base'
require 'time'
require 'json'
require 'logger'
require_relative '../lib/service.rb'

class FeroniaWebApp < Sinatra::Base

  configure do
    set :logging, true
    set :service_config_path, File.join(__dir__, '..', 'config', 'services.json')
    $logger = Logger.new('/var/log/feronia/feronia_web_app.log', 'daily')
    $logger.level = Logger::DEBUG
  end

  get '/GetServiceStatus' do
    status 200
    # TODO: check latency to the auth and mongo servers
    body "{\"logging\":#{settings.logging}}"
  end

  get '/ServiceConfig/:environment/:slug' do
    s = Service.load_from_file(settings.service_config_path, params[:slug], params[:environment])
    if s.nil?
      status 404
      body "{\"error_message\":\"Invalid slug and/or environment\"}"
    else
      status 200
      body s.to_s
    end
  end

  get '/ServiceCall/:environment/:slug' do
    # Load the API data
    s = Service.load_from_file(settings.service_config_path, params[:slug], params[:environment])

    # Format the request
    uri, http_req = s.generate_request(params)
    $logger.debug("Got HTTP request: #{http_req}")

    # Execute the API call
    res = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(http_req)
    end
    $logger.debug("Got HTTP response: #{res}")

    # Format and render the response
    status 200
    payload = {}
    payload['code'] = res.code
    payload['body'] = JSON.parse(res.read_body).to_hash

    response_body =<<BODY
<html>
<head>
  <script src=\"https://cdn.rawgit.com/google/code-prettify/master/loader/run_prettify.js\"></script>
</head>
<body>
  <h3>#{uri}</h3><br />
  <h4>#{res.code} #{res.message}</h4><br />
  <pre class=\"prettyprint\">#{JSON.pretty_generate(payload)}</pre>
</body>
</html>
BODY
    body response_body
  end
end
