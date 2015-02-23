set :application,     "relay"
 set :repository,      'https://github.com/Arie/relay.git'
set :main_server,     "fakkelbrigade.eu"
set :user,            "tf2"
set :deploy_to,       '/home/tf2/relay/'
set :deploy_via,      :copy
set :use_sudo,        false
set :thin_config,     'config/thin.yml'
set :branch,          'master'
set :rvm_ruby_string, '2.0'
set :rvm_type,        :system
set :keep_releases,   5

set :scm, :git

server "#{main_server}", :web, :app, :db, :primary => true

namespace :rvm do
  task :trust_rvmrc do
    run "cd #{release_path}; rvm rvmrc trust #{release_path}"
  end
end

namespace :deploy do
  desc "Restart the servers"
  task :restart do
    run "cd #{release_path}; bundle exec thin -C config/thin.yml stop"
    run "cd #{release_path}; bundle exec thin -C config/thin.yml start"
  end

end

after "deploy:update_code", "rvm:trust_rvmrc"
after "deploy:update_code", "relay:link_config"
after "deploy:update_code", "thin:link_config"
after "deploy", "deploy:cleanup"
