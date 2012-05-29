Capistrano::Configuration.instance(:must_exist).load do
  Dir.glob(File.join(File.dirname(__FILE__), "..", "..",  "recipes", "*.rb")).each do |file|
    load file
  end
end