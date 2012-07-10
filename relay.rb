require 'rubygems'
require 'sinatra'
require 'rack-flash'


class Relay < Sinatra::Base

  set :root,          File.dirname(__FILE__)
  set :config,        YAML.load(File.read(settings.root + "/config/relay.yml"))['server']
  set :runner_config, YAML.load(File.read(settings.root + "/config/relay.yml"))['runner']


  DEPLOYMENT_DIR = settings.root

  use Rack::Auth::Basic do |username, password|
    [username, password] == [settings.config['username'], settings.config['password']]
  end

  enable :sessions
  use Rack::Flash, :sweep => true

  get '/' do
    @relays = statuslines_to_array(`#{DEPLOYMENT_DIR}/relaysrunning.rb`.lines.to_a)
    haml :index
  end

  get '/help' do
    haml :help
  end

  get '/kill/:id' do
    `#{DEPLOYMENT_DIR}/relaykill.rb #{params[:id].to_i}`
    flash[:success] = "Relay stopped"
    redirect '/'
  end

  post '/' do
    unless params[:address].empty?
      address     = Escape.shell_single_word(params[:address])
      password    = Escape.shell_single_word(params[:password])
      relay_dir   = Escape.shell_single_word(settings.runner_config['installation_dir'])
      relay_ip    = Escape.shell_single_word(settings.runner_config['ip'])
      relay_port  = Escape.shell_single_word(settings.runner_config['start_port'])
      `#{DEPLOYMENT_DIR}/webrelay #{relay_dir} #{address} #{password} #{relay_port} #{relay_ip}`
       flash[:success] = "Relay started"
     else
       flash[:error] = "You forgot something"
     end
    redirect '/'
  end

  get '/status/:id' do
    id = params[:id].to_i
    `#{DEPLOYMENT_DIR}/relaystatus.rb #{id}`
    f = File.new("/tmp/#{id}.status")
    @lines = f.lines
    haml :status
  end


  get '/stylesheet.css' do
    content_type 'text/css', :charset => 'utf-8'
    sass :stylesheet
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
          yank_date_string = line.split(" ")[1].strip.split("/")
          date_string = "#{yank_date_string[1]}-#{yank_date_string[0]}-#{yank_date_string[2]}"
          time_string = line.split(" ")[2..3].join('').strip

          datetime  = DateTime.parse("#{date_string} #{time_string}")
          date = "#{datetime.year}-#{datetime.month}-#{datetime.day}"
          time = "#{sprintf("%02d", datetime.hour)}:#{sprintf("%02d", datetime.minute)}:#{sprintf("%02d", datetime.second)}"

          { :pid => pid, :date_time => "#{date} #{time}" }
        end
      end
    end
  end

end
