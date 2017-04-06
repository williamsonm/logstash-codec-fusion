# encoding: utf-8
require "logstash/codecs/base"
require "logstash/util/charset"
require "logstash/util/buftok"
require "logstash/json"

class LogStash::Codecs::Fusion < LogStash::Codecs::Base
  config_name "fusion"

  config :charset, :validate => ::Encoding.name_list, :default => "UTF-8"

  def register
    @converter = LogStash::Util::Charset.new(@charset)
    @converter.logger = @logger
  end

  def decode(data, &block)
    parse(@converter.convert(line), &block)
  end

  def encode(event)
    @on_event.call(event, event.to_json)
  end

  private

  def from_json_parse(json, &block)
    LogStash::Event.from_json(json).each { |event| yield event }
  rescue LogStash::Json::ParserError => e
    @logger.error("JSON parse error, original data now in message field", :error => e, :data => json)
    yield LogStash::Event.new("message" => json, "tags" => ["_jsonparsefailure"])
  end

  def legacy_parse(json, &block)
    decoded = LogStash::Json.load(json)

    case decoded
    when Array
      decoded.each {|item| yield(LogStash::Event.new(item)) }
    when Hash
      yield LogStash::Event.new(decoded)
    else
      @logger.error("JSON codec is expecting array or object/map", :data => json)
      yield LogStash::Event.new("message" => json, "tags" => ["_jsonparsefailure"])
    end
  rescue LogStash::Json::ParserError => e
    @logger.info("JSON parse failure. Falling back to plain-text", :error => e, :data => json)
    yield LogStash::Event.new("message" => json, "tags" => ["_jsonparsefailure"])
  rescue StandardError => e
    # This should NEVER happen. But hubris has been the cause of many pipeline breaking things
    # If something bad should happen we just don't want to crash logstash here.
    @logger.warn(
      "An unexpected error occurred parsing JSON data",
      :data => json,
      :message => e.message,
      :class => e.class.name,
      :backtrace => e.backtrace
    )
  end

  # keep compatibility with all v2.x distributions. only in 2.3 will the Event#from_json method be introduced
  # and we need to keep compatibility for all v2 releases.
  alias_method :parse, LogStash::Event.respond_to?(:from_json) ? :from_json_parse : :legacy_parse
end
