require 'sinatra/base'
require 'time'
require 'json'
require 'logger'
require_relative '../lib/service.rb'

class FeroniaWebApp < Sinatra::Base

	configure do
		set :logging, true
		set :service_config_path, File.join(__dir__,'..','config','services.json')
		$logger = Logger.new('/var/log/feronia/feronia_web_app.log', 'daily')
		$logger.level = Logger::DEBUG
	end

	get '/GetServiceStatus' do
		status 200
		# TODO: check latency to the auth and mongo servers
		body "{\"logging\":#{settings.logging}}"
	end

	get '/ServiceConfig/:slug/:environment' do
		s = Service.load_from_file(settings.service_config_path, params[:slug], params[:environment])
		if s.nil?
			status 404
			body "{\"error_message\":\"Invalid slug and/or environment\"}"
		else
			status 200
			body s.to_s
		end
	end
end
