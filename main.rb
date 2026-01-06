# encoding: BINARY
Encoding.default_external = Encoding::BINARY
Encoding.default_internal = Encoding::BINARY
Dir.chdir(__dir__)

require 'pathname'

spec_path = Pathname.new(ARGV[0]).cleanpath
configs_path = Pathname.new(ARGV[1]).cleanpath
configs_path_glob = (configs_path + './*.conf').cleanpath

Dir.glob(configs_path_glob) do |file_path|
  File.open(file_path, ?r) do |file|
    config_string = String.new
    config_hash = Hash.new
    current_section = nil
    
    until file.eof?
      line = file.readline
      if section_match_data = line.match(/\[(\w+)\]/) then
        section_title = section_match_data.captures[0]
        config_hash[section_title] = Hash.new unless config_hash[section_title]
        current_section = section_title
      elsif parameter_match_data = line.match(/(\w+) ?= ?(.+)/) then
        captures = parameter_match_data.captures
        config_hash[current_section][captures[0]] = captures[1]
      elsif line.strip.size > 0 then
        config_string << "#{line}\n"
      end
    end
    
    config_hash.keys.each do |key|
      config_string << "[#{key}]\n"
      config_hash[key].each_pair do |pair|
        config_string << "#{pair[0]} = #{pair[1]}\n"
      end
      config_string << ?\n
    end
    
    # puts config_hash
    puts config_string
    # exit(0)
  end
end
