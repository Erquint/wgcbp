# encoding: BINARY
Encoding.default_external = Encoding::BINARY
Encoding.default_internal = Encoding::BINARY
Dir.chdir(__dir__)

require 'pathname'

class Hash
  alias_method :original_merge, :merge
  alias_method :original_merge!, :merge!

  def merge(other_hash, recurse = false)
    return original_merge(other_hash) unless recurse
    return dup.merge!(other_hash, true)
  end

  def merge!(other_hash, recurse = false)
    return original_merge!(other_hash) unless recurse
    
    other_hash.each do |key, other_value|
      if self[key].is_a?(Hash) && other_value.is_a?(Hash) then
        self[key].merge!(other_value, true)
      else
        self[key] = other_value
      end
    end
    
    return self
  end
end

usage_hint = 'Usage: ruby main.rb <SPEC_DIR> <CONFIGS_DIR>'

abort usage_hint unless ARGV.size == 2

spec_path = Pathname.new(ARGV[0]).cleanpath
configs_path = Pathname.new(ARGV[1]).cleanpath
enriched_path = configs_path.join('./enriched/').cleanpath
Dir.mkdir(enriched_path) rescue Errno::EEXIST
configs_path_glob = configs_path.join('./*.conf').cleanpath
client_args = Hash.new
spec_order = Array.new

File.open(spec_path, ?r) do |file|
  current_client = nil
  current_section = nil
  
  until (line = file.readline(chomp: true)) == '###' do
    if match_data = line.match(/!(\w+)!/) then
      current_client = match_data.captures[0]
      client_args[current_client] ||= Hash.new
    elsif match_data = line.match(/\[(\w+)\]/) then
      current_section = match_data.captures[0]
      client_args[current_client][current_section] ||= Hash.new
    elsif match_data = line.match(/(\w+) ?= ?(.+)/) then
      parameter, argument = match_data.captures
      client_args[current_client][current_section][parameter] = argument
    end
  end
  
  spec_order = file.each_line.map(&:chomp).to_a
end

Dir.glob(configs_path_glob) do |file_path|
  File.open(file_path, ?r) do |file|
    pre_config_string = String.new
    config_hash = Hash.new
    current_section = nil
    
    file.each_line(chomp: true) do |line|
      if section_match_data = line.match(/\[(\w+)\]/) then
        section_title = section_match_data.captures[0]
        config_hash[section_title] ||= Hash.new
        current_section = section_title
      elsif parameter_match_data = line.match(/(\w+) ?= ?(.+)/) then
        abort "Malformed input #{file_path}: parameter outside of sections!" unless current_section
        parameter, argument = parameter_match_data.captures
        config_hash[current_section][parameter] = argument
      elsif current_section.nil? then
        pre_config_string << "#{line}\n"
      end
    end
    
    client_args.keys.each do |client|
      config_hash.merge!(client_args[client], true)
      config_string = pre_config_string.dup
      
      spec_order.each do |line|
        if section_match_data = line.match(/\[(\w+)\]/) then
          current_section = section_match_data.captures[0]
          config_string << "[#{current_section}]\n"
        elsif line.empty? then
          config_string << ?\n
        else
          argument = config_hash[current_section][line]
          abort "Spec order references undefined parameter: #{current_section}.#{line}" unless argument
          config_string << "#{line} = #{argument}\n"
        end
      end
      
      enriched_client_path = enriched_path.join(client).cleanpath
      Dir.mkdir(enriched_client_path) rescue Errno::EEXIST
      enriched_filename = enriched_client_path.join(File.basename(file_path)).cleanpath
      File.binwrite(enriched_filename, config_string)
      puts("Wrote #{enriched_filename}")
    end
    
  end
end
