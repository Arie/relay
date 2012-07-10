namespace :relay do

  desc "Makes a symbolic link to the shared relay.yml"
  task :link_config, :except => { :no_release => true } do
    run "ln -sf #{shared_path}/relay.yml #{release_path}/config/relay.yml"
  end

end
