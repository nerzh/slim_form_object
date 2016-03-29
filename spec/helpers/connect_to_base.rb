def dbconfig
  YAML::load(File.open(File.join(File.dirname(__FILE__), '../db/database.yml')))
end