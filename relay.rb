require 'rubygems'
require 'rack/cache'
require 'sinatra'
require 'rack-flash'
require 'memoizable'
require 'dalli'

class Relay < Sinatra::Base

  include Memoizable

  set :root,          File.dirname(__FILE__)
  set :config,        YAML.load(File.read(settings.root + "/config/relay.yml"))['server']
  set :runner_config, YAML.load(File.read(settings.root + "/config/relay.yml"))['runner']
  set :dns_names,     YAML.load(File.read(settings.root + "/config/dns_names.yml"))['dns_names']
  set :cache,         Dalli::Client.new('localhost:11211', :expires_in => 5)


  DEPLOYMENT_DIR = settings.root

  enable :sessions
  use Rack::Flash, :sweep => true
  use Rack::Cache

  get '/' do
    statuslines = cache.fetch("statuslines", 1) {`#{DEPLOYMENT_DIR}/relaysrunning.rb`.lines.to_a }
    @relays = statuslines_to_array(statuslines[0..-1])
    haml :index
  end

  get '/help' do
    protected!
    haml :help
  end

  get '/kill/:id' do
    protected!
    `#{DEPLOYMENT_DIR}/relaykill.rb #{params[:id].to_i}`
    flash[:success] = "Relay stopped"
    redirect '/'
  end

  post '/' do
    protected!
    unless params[:address].empty?
      address     = shell_escape(params[:address])
      password    = shell_escape(params[:password])
      relay_dir   = shell_escape(settings.runner_config['installation_dir'])
      relay_ip    = shell_escape(settings.runner_config['ip'])
      relay_port  = shell_escape(settings.runner_config['start_port'])
      `#{DEPLOYMENT_DIR}/webrelay #{relay_dir} #{address} #{password} #{relay_port} #{relay_ip}`
       flash[:success] = "Relay started"
     else
       flash[:error] = "You forgot something"
     end
    redirect '/'
  end

  get '/status/:id' do
    protected!
    @content = status_log(params[:id])
    haml :status
  end

  helpers do

    def statuslines_to_array(statuslines)
      out = []
      statuslines.each do |line|
        out << statusline_to_hash(line)
      end
      out.reject(&:nil?)
    end

    def statusline_to_hash(line)
      if !line.split(" ")[0].nil? && line.split(" ")[0].length > 1
        pid   = line.split(" ")[0].split(".")[0]

        if pid.to_i > 0
          date_time = yank_date_to_euro_date(line)

          status_hash = { :pid            => pid,
                          :date_time      => date_time,
                          :relay_ip_port  => relay_ip_port(pid),
                          :stv_ip_port    => stv_ip_port(pid),
                          :capacity       => capacity(pid),
                          :spectators     => spectators(pid)
          }
        end

      end
    end

    def relay_ip_port(pid)
      cache.fetch("relay_ip_port_#{pid}", 15*60) do
        log = status_log(pid)
        match = log.match(/Local\ IP\ \d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}:.\d{4,6}/)
        if match
          relay_ip_port = match[-1].split(" ")[2].gsub(",", "")
          relay_ip    = relay_ip_port.split(":")[0]
          relay_port  = relay_ip_port.split(":")[1]
          friendly_name = ip_to_dns(relay_ip)
          relay_ip_port = "#{friendly_name}:#{relay_port}"
        end
      end
    end

    def stv_ip_port(pid)
      cache.fetch("stv_ip_port_#{pid}", 15*60) do
        log = status_log(pid)
        match = log.match(/Relay\ .* connect\ to\ \d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}:.\d{4,6}/)
        if match
          stv_ip_port = match[-1].split(", connect to ")[1]
          stv_ip    = stv_ip_port.split(":")[0]
          stv_port  = stv_ip_port.split(":")[1]
          friendly_name = ip_to_dns(stv_ip)
          stv_ip_port = "#{friendly_name}:#{stv_port}"
        end
      end
    end

    def spectators(pid)
      cache.fetch("spectators_#{pid}") do
        log = status_log(pid)
        match = log.match(/Local\ Slots\ \d{1,3}, Spectators\ \d{1,3}/)
        if match
          spectators = match[-1].split(" ")[4]
        end
      end
    end

    def capacity(pid)
      cache.fetch("capacity_#{pid}", 15*60) do
        log = status_log(pid)
        match = log.match(/Local\ Slots\ \d{1,3}, Spectators\ \d{1,3}/)
        if match
          capacity = match[-1].split(" ")[2].gsub(',', '')
        end
      end
    end

    def ip_to_dns(ip)
      if settings.dns_names[ip]
        settings.dns_names[ip]
      else
        ip
      end
    end
    memoize :ip_to_dns

    def yank_date_to_euro_date(yank_date_line)
      yank_date_string = yank_date_line.split(" ")[1].strip.split("/")
      date_string = "#{yank_date_string[1]}-#{yank_date_string[0]}-#{yank_date_string[2]}"
      time_string = yank_date_line.split(" ")[2..3].join('').strip

      datetime  = DateTime.parse("#{date_string} #{time_string}")
      euro_date = "#{datetime.year}-#{datetime.month}-#{datetime.day}"
      euro_time = "#{sprintf("%02d", datetime.hour)}:#{sprintf("%02d", datetime.minute)}:#{sprintf("%02d", datetime.second)}"

      "#{euro_date} #{euro_time}"
    end

    def status_log(pid)
      cache.fetch("status_log_#{pid}") do
        pid = pid.to_i
        `#{DEPLOYMENT_DIR}/relaystatus.rb #{pid}`
        f = File.open("/tmp/#{pid}.status", "r:iso-8859-1")
        f.read
      end
    end

    def shell_escape(string)
      Escape.shell_single_word(string)
    end

    def protected!
      unless authorized?
        response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
        throw(:halt, [401, "Not authorized\n"])
      end
    end

    def authorized?
      @auth ||= Rack::Auth::Basic::Request.new(request.env)
      @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [settings.config['username'], settings.config['password']]
    end

    def cache
      settings.cache
    end

  end


end
