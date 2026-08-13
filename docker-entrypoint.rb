#!/usr/bin/env ruby
# frozen_string_literal: true

ENV_FILE = "/root/.clacky/.env"
ENV_KEY = /\A[A-Za-z_][A-Za-z0-9_]*\z/

def decode_double_quoted(value)
  value.gsub(/\\([\\"nrt])/) do
    case Regexp.last_match(1)
    when "n" then "\n"
    when "r" then "\r"
    when "t" then "\t"
    else Regexp.last_match(1)
    end
  end
end

def parse_value(raw, line_number)
  value = raw.strip
  return "" if value.empty?

  if value.start_with?("'")
    match = value.match(/\A'([^']*)'\s*(?:#.*)?\z/)
    raise "invalid single-quoted value on line #{line_number}" unless match

    return match[1]
  end

  if value.start_with?('"')
    match = value.match(/\A"((?:\\.|[^"])*)"\s*(?:#.*)?\z/)
    raise "invalid double-quoted value on line #{line_number}" unless match

    return decode_double_quoted(match[1])
  end

  value.sub(/\s+#.*\z/, "").rstrip
end

def load_env_file(path)
  return unless File.file?(path)

  inherited_keys = ENV.keys.to_h { |key| [key, true] }
  loaded = {}

  File.foreach(path).with_index(1) do |line, line_number|
    line = line.delete_suffix("\n").delete_suffix("\r").strip
    next if line.empty? || line.start_with?("#")

    line = line.sub(/\Aexport\s+/, "")
    key, raw_value = line.split("=", 2)
    key = key&.strip

    unless key&.match?(ENV_KEY) && !raw_value.nil?
      raise "invalid environment assignment on line #{line_number}"
    end

    loaded[key] = parse_value(raw_value, line_number)
  end

  loaded.each do |key, value|
    ENV[key] = value unless inherited_keys.key?(key)
  end
rescue StandardError => e
  warn "openclacky-entrypoint: failed to load #{path}: #{e.message}"
  exit 1
end

load_env_file(ENV_FILE)
exec("openclacky", *ARGV)
