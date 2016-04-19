# service.rb
# Data structure representing a single Web Service that Feronia supports calls to.

require 'json'
require 'net/http'

class Service
	
	attr_accessor :slug, :name, :consumers, :environment
	attr_accessor :protocol, :port, :hostname, :endpoint, :verb
	attr_accessor :payload_template, :headers
	attr_accessor :cert_path, :key_path, :passwd

	def initialize(config={})
		@slug = config[:slug] || config['slug']
		@name = config[:name] || config['name']
		@consumers = config[:consumers] || config['consumers']
		@environment = config[:environment] || config['environment']
		@protocol = config[:protocol] || config['protocol']
		@port     = (config[:port] || config['port']).to_i
		@hostname = config[:hostname] || config['hostname']
		@endpoint = config[:endpoint] || config['endpoint']
		@verb     = config[:verb] || config['verb']
		@payload_template_path = config[:payload_template] || config['payload_template']
		@headers = config[:headers] || config['headers']
		@cert_path = config[:cert] || config['cert']
		@key_path  = config[:key]  || config['key']
		@passwd    = config[:passwd] || config['passwd']
	end

	def self.load_all_from_mongo(mongo_config={})
		# TODO: implement mongo CRUD functions
		return nil
	end

	def self.load_all_from_file(path)
		config = JSON.load(File.read(path))
		services = {}

		
		config.each do |service_parent|
			
			# Top-level config settings
			slug = service_parent['slug']
			name = service_parent['name']
			consumers = service_parent['consumers']

			# Merge the various env-level service configs with the top-level data for each Service object
			service_parent['services'].each_pair do |env,service|
#				puts "#{slug} . #{env}: #{service}"
				services[slug] = {} unless services.has_key?(slug)
				services[slug][env] = Service.new(service)
				services[slug][env].environment = env
				services[slug][env].slug = slug
				services[slug][env].name = name
				services[slug][env].consumers = consumers
			end
			
		end

		return services
	end

	def self.load_from_file(json_path, slug, env)
		all_services = self.load_all_from_file(json_path)
		return all_services[slug][env]
	end

	def to_s
		"#{@slug}.#{@environment}: #{@verb} #{@protocol}://#{@hostname}:#{@port}#{@endpoint}"
	end

	
end


#####################################
##### MAIN - For simple testing #####
#####################################

if __FILE__ == $0
	require 'optparse'

	file_path = nil
	slug      = nil
	env       = nil

	OptionParser.new do |opt|
		opt.banner = "Test the Service class functions. Usage: ruby #{__FILE__} [-f json_file]"
		opt.on('-f', '--file PATH', 'Local JSON file containin the service specifications.') do |p|
			file_path = p
		end

		opt.on('--slug SLUG', 'Load the values only for this slug') do |s|
			slug = s
		end
		opt.on('--env ENVIRONMENT', 'Load the values only for this environment') do |e|
			env = e
		end

		opt.on_tail('-h', '--help', 'Display this message') do 
			puts opt
			exit
		end
	end.parse!

	unless file_path.nil?
		if slug.nil? || env.nil?
			services = Service.load_all_from_file(file_path)
	
			services.each_pair do |service_name, environments|
				environments.each_pair do |env, service_config|
					puts service_config.to_s
				end
			end	
		else
			puts "> Searching for a service matching Slug=#{slug}, Env=#{env}..."
			s = Service.load_from_file(file_path, slug, env)
			puts s.to_s
		end
	end
end

