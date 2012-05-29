require 'erb'
class Monit
  class MonitoredItem
    attr_accessor :depends_on
    attr_accessor :base_path
    attr_accessor :monit
    attr_accessor :name

    def initialize(name, monit, &block)
      self.name = name
      self.depends_on = []
      self.monit = monit
      instance_eval(&block)
    end  
    
    def each_dependency(&block)
      depends_on.each do |dependency_name|
        yield monitored.detect{|m| m.name == dependency_name}.unique_name
      end
    end
    
    def conf_name
      "#{unique_name}.conf"
    end
    
    def conf_path
      "#{home_dir}/etc/monit.d/#{conf_name}"
    end
    
    def env_path
      "#{home_dir}/etc/environments/#{env_name}"
    end
    
    def env_name
      "#{unique_name}.env"      
    end
    
    def to_monit   
      ERB.new(File.read(template_path)).result(binding)
    end
    
    def unique_name
      "#{application}.#{stage}.#{name}"
    end
    
    def to_environment
      ERB.new(File.read(environment_template_path)).result(binding)
    end  

    def method_missing(method, *args)
      monit.send(method, *args)
    end
    
    def needs_environment?
      false
    end
  end

  class MonitoredFile < MonitoredItem
    attr_accessor :path
    
    def template_path
      File.expand_path("../../templates/file.conf.erb", __FILE__)      
    end
    
    def file_path
      File.join(current_path, path)
    end
  end

  class MonitoredProgram < MonitoredItem
    attr_accessor :command
    attr_accessor :log_file
    attr_accessor :pid_file
    attr_accessor :bundler
    
    def initialize(*args)
      self.bundler = true
      super
    end
    
    def start_command
      %Q{#{monit_rvm_shell_path} #{env_path} start 'cd #{current_path} && #{bundle} #{command}'}
    end
    
    def stop_command
      %Q{#{monit_rvm_shell_path} #{env_path} stop 'cd #{current_path} && #{bundle}'}      
    end
    
    def bundle
      bundler ? "bundle exec" : ""
    end
    
    def pidfile_path
      File.join(current_path, pid_file)
    end
    
    def logfile_path
      File.join(current_path, log_file)      
    end
    
    def gem_base_dir
      capture(%Q{cd #{current_path} && #{bundle} ruby -e 'puts Gem.loaded_specs["capistrano-monit"].gem_dir'}).strip
    end
    
    def monit_rvm_shell_path
      File.join(gem_base_dir, "scripts/rvm-monit-shell")
    end
    
    def program_search_path
      "/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin"
    end
    
    def template_path
      File.expand_path("../../templates/program.conf.erb", __FILE__)
    end
    
    def environment_template_path
      File.expand_path("../../templates/environment.erb", __FILE__)      
    end    
    
    def needs_environment?
      true
    end
    
  end

  TYPES = {
    :file => MonitoredFile,
    :program => MonitoredProgram
  }

  class << self
    def configure(&block)
      new(&block)
    end  
    
    def load_from(file, context)
      self.instance_eval(File.read(file), file).tap do |monit|
        monit.context = context
      end
    end
  end
  
  def template_path
    File.expand_path("../../templates/monit.conf.erb", __FILE__)
  end
  
  def to_monit   
    ERB.new(File.read(template_path)).result(binding)
  end
  
  def monitd_path
    File.join(home_dir, "etc/monit.d")
  end
  
  attr_accessor :port
  attr_accessor :monitored
  attr_accessor :context
  
  def method_missing(method, *args)
    if context && context.respond_to?(method)
      context.send(method, *args)
    else
      super
    end
  end

  def initialize(&block)
    self.monitored = []
    self.port = 1192
    instance_eval(&block)
  end

  def monitors(options, &block)
    type, name = options.first
    self.monitored << TYPES[type].new(name, self, &block)
  end
end