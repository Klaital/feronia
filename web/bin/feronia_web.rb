require 'sinatra'
require 'time'
require 'json'
require 'logger'
require_relative '../lib/service.rb'

set :bind, '0.0.0.0'

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

  get '/ServiceRequest/:environment/:slug' do
    # Load the API data
    s = Service.load_from_file(settings.service_config_path, params[:slug], params[:environment])
    s.logger = $logger

    # Format the request
    uri, http_req = s.generate_request(params)
    $logger.debug("Got HTTP request: #{http_req}")

    payload = {} # this is the response object
    begin
      # Execute the API call
      request_start_time = Time.now
      res = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(http_req)
      end
      request_turnaround_millis = ((Time.now - request_start_time) * 1000).round

      $logger.debug("Got HTTP response: #{res}")
      $logger.debug("Response from server #{res.code} #{res.message} in #{request_turnaround_millis}")

      # Format and render the response
      status 200
      payload = {'response'=>{}}
      payload['response']['code'] = res.code
      payload['response']['message'] = res.message
      payload['response']['body'] = res.read_body
      payload['response']['time'] = request_turnaround_millis
    rescue => e
      status 503
      payload['error'] = "Caught Exception: #{e.class} #{e.message}"
      payload['backtrace'] = e.backtrace
    end

    body JSON.pretty_generate(payload)
  end

  get '/ServiceCall/:environment/:slug' do
    s = Service.load_from_file(settings.service_config_path, params[:slug], params[:environment])
    s.logger = $logger
    response_body =<<BODY
  <html>
  <head>
    <title>Feronia | #{s.name}, #{s.environment}</title>
    <script>
var request = new XMLHttpRequest();
var uri = "#{request.url.gsub('/ServiceCall/', '/ServiceRequest/')}";

request.onreadystatechange = function() {
    if (request.readyState == 4 && request.status == 200) {
        var data = JSON.parse(request.responseText);
        display_response(data);
    }
};

request.open("#{s.verb.upcase}", uri, true);
request.send();


function display_response(data) {
  document.getElementById("responsepayload").innerHTML = JSON.stringify(JSON.parse(data.response.body), null, 2);
  document.getElementById("response-time").innerHTML = data.response.time + ' ms';
  document.getElementById("response-status").innerHTML = data.response.code + ' ' + data.response.message;

var script = document.createElement('script');
script.src = "https://cdn.rawgit.com/google/code-prettify/master/loader/run_prettify.js";
document.getElementsByTagName('head')[0].appendChild(script);

}
</script>
  </head>
  <body>
    <div id="request-info">
      <h3>Request Data</h3>
      <table border="1">
        <tr><td>URL</td><td>#{s.verb} #{s.hostname}#{s.endpoint}</td></tr>
      </table>

    </div>
    <div id="response-info">
      <h3>Response Data</h3>
      <table border="1">
        <tr><td>Response Time</td><td id="response-time"></td></tr>
        <tr><td>Status</td><td id="response-status"></td></tr>
      </table>
      <pre id="responsepayload" class="prettyprint"></pre>
    </div>
  </body>
  </html>
BODY
      body response_body

  end
