# encoding: BINARY
# frozen_string_literal: true
Encoding.default_external = Encoding::BINARY
Encoding.default_internal = Encoding::BINARY

require 'pathname'
require 'zlib'
require 'rubygems/package'

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

abort 'Usage: ruby main.rb <SPEC_DIR> <CONFIGS_DIR>' unless ARGV.size == 2
SPEC_PATH = Pathname.new(ARGV[0]).cleanpath.freeze
abort "File #{SPEC_PATH} not found!" unless SPEC_PATH.exist?
CONFIGS_PATH = Pathname.new(ARGV[1]).cleanpath.freeze
abort "Directory #{CONFIGS_PATH} not found!" unless CONFIGS_PATH.exist?
PROCESSED_PATH = CONFIGS_PATH.join('./processed/').cleanpath.freeze
PROCESSED_PATH.mkdir rescue Errno::EEXIST
CLIENT_ARGS = Hash.new
SPEC_ORDER = Array.new

SPEC_PATH.open('rb') do |spec_file|
  current_client = nil
  current_section = nil
  
  spec_file.each_line(chomp: true) do |client_spec_line|
    if match_data = client_spec_line.match(/\[Client:(\w+)\]/) then
      current_client = match_data.captures[0]
      break if current_client == 'All'
      CLIENT_ARGS[current_client] ||= Hash.new
    elsif match_data = client_spec_line.match(/\[(\w+)\]/) then
      current_section = match_data.captures[0]
      CLIENT_ARGS[current_client][current_section] ||= Hash.new
    elsif match_data = client_spec_line.match(/(\w+) ?= ?(.+)/) then
      parameter, argument = match_data.captures
      CLIENT_ARGS[current_client][current_section][parameter.strip.downcase] = argument
    end
  end
  
  SPEC_ORDER.concat(spec_file.each_line.map(&:chomp))
end

CONFIGS_PATH.glob('./*.conf') do |config_file_path|
  config_file_path.open('rb') do |config_file|
    pre_config_string = String.new
    config_hash = Hash.new
    current_section = nil
    
    config_file.each_line(chomp: true) do |config_line|
      if section_match_data = config_line.match(/\[(\w+)\]/) then
        section_title = section_match_data.captures[0]
        config_hash[section_title] ||= Hash.new
        current_section = section_title
      elsif parameter_match_data = config_line.match(/(\w+) ?= ?(.+)/) then
        abort "Malformed input #{config_file_path}: parameter outside of sections!" unless current_section
        parameter, argument = parameter_match_data.captures
        config_hash[current_section][parameter.strip.downcase] = argument
      elsif current_section.nil? then
        pre_config_string << "#{config_line}\n"
      end
    end
    
    CLIENT_ARGS.keys.each do |client_title|
      config_hash.merge!(CLIENT_ARGS[client_title], true)
      config_string = pre_config_string.dup
      
      SPEC_ORDER.each do |order_spec_line|
        if section_match_data = order_spec_line.match(/\[(\w+)\]/) then
          current_section = section_match_data.captures[0]
          config_string << "[#{current_section}]\n"
        elsif order_spec_line.empty? then
          config_string << ?\n
        else
          next nil unless argument = config_hash[current_section][order_spec_line.strip.downcase]
          config_string << "#{order_spec_line} = #{argument}\n".gsub(/,\s*/, ', ')
        end
      end
      
      processed_client_path = PROCESSED_PATH.join(client_title).cleanpath
      processed_client_path.mkdir rescue Errno::EEXIST
      config_filename = config_file_path.basename('.conf').to_path[...32].concat('.conf')
      processed_filename = processed_client_path.join(config_filename).cleanpath
      processed_filename.binwrite(config_string)
      puts("Wrote #{processed_filename}")
    end
  end
end

CLIENT_ARGS.keys.each do |client_title|
  client_dir = PROCESSED_PATH.join(client_title).cleanpath
  archive_path = PROCESSED_PATH.join("#{client_title}.tar.gz").cleanpath
  
  File.open(archive_path, 'wb') do |archive_file|
    Zlib::GzipWriter.wrap(archive_file, Zlib::BEST_COMPRESSION, Zlib::DEFAULT_STRATEGY) do |gz|
      Gem::Package::TarWriter.new(gz) do |tar|
        client_dir.glob('./*.conf').each do |path|
          content = path.binread
          tar.add_file_simple(path.basename.to_s, 0o444, content.bytesize) do |io|
            io.write(content)
          end
        end
      end
    end
  end
  
  puts("Wrote #{archive_path}")
end
