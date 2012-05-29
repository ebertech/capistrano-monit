require 'monit'

_cset(:home_dir){ capture("echo $HOME").strip }
_cset(:monit_config_path) { File.join(Dir.pwd, "config", "monit", "#{stage}.rb") }
namespace :monit do

  task :make_directories do
    home_dir = 
    %W{etc/
      etc/monit.d
      etc/environments
      var/
      var/run
      var/log
      var/monit
      /etc/cron.d/reboot/
    }.map do |dir|
      File.join(fetch(:home_dir), dir)
    end.tap{|dirs| run %Q{mkdir -p #{dirs.join(" ")}}}    
  end

  task :upload_config do      
    if File.exists?(monit_config_path)
      ::Monit.load_from(monit_config_path, self).tap do |monit|
        put monit.to_monit, "#{home_dir}/etc/monit.conf"
        run "chmod 600 #{"#{home_dir}/etc/monit.conf"}"        
      end
    end
  end

  task :setup do 
    make_directories
    upload_config  
  end
  
  desc "Tell monit to reread its configuration"
  task :reload do
    run "monit -c #{home_dir}/etc/monit.conf"            
    run "monit -c #{home_dir}/etc/monit.conf reload"    
  end
  
  task :restart do
    run "monit -c #{home_dir}/etc/monit.conf"            
    run "monit -c #{home_dir}/etc/monit.conf restart all"      
  end

  task :deploy do
    if File.exists?(monit_config_path)
      ::Monit.load_from(monit_config_path, self).tap do |monit|
        monit.monitored.each do |monitored_item|
          put monitored_item.to_monit, monitored_item.conf_path
          if monitored_item.needs_environment? 
            put monitored_item.to_environment, monitored_item.env_path
          end
        end
      end
    end
  end
end

after "deploy:setup", "monit:setup"
after "deploy:update_code", "monit:deploy"
after "monit:deploy", "monit:restart"
after "monit:setup", "monit:reload"