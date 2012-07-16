namespace :thin do

  desc "Makes a symbolic link to the shared thin.yml"
  task :link_config, :except => { :no_release => true } do
    run "ln -sf #{shared_path}/thin.yml #{release_path}/config/thin.yml"
  end

end
