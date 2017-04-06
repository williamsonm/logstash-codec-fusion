require "logstash/devutils/rspec/spec_helper"
require "logstash/codecs/fusion"
require "logstash/codecs/json"
require "logstash/event"
require "logstash/json"
require "insist"

describe LogStash::Codecs::Fusion do
  subject do
    LogStash::Codecs::Fusion.new
  end

  shared_examples :codec do

    context "#decode" do
      it "format json for fusion" do
        data = {"foo" => "bar", "baz" => {"bah" => ["a","b","c"]}}
        subject.decode(LogStash::Json.dump(data)) do |event|
          insist { event.is_a? LogStash::Event }
          insist { event.get("foo") } == data["foo"]
          insist { event.get("baz") } == data["baz"]
          insist { event.get("bah") } == data["bah"]
        end
      end
    end

    context "#encode" do
      it "should return json for a fusion add command" do
        data = {
          "id" => "whatever",
          "foo" => "bar",
          "baz" => {"bah" => ["a","b","c"]}
        }
        event = LogStash::Event.new(data)
        got_event = false
        subject.on_event do |e, d|
          json = LogStash::Json.load(d)
          insist { json["id"] } == data["id"]
          insist { json["commands"]["name"] } == "add"
          insist { json["fields"]["foo"] } == data["foo"]
          got_event = true
        end
        subject.encode(event)
        insist { got_event }
      end
    end
  end

  context "forcing legacy parsing" do
    it_behaves_like :codec do
      before(:each) do
        # stub codec parse method to force use of the legacy parser.
        # this is very implementation specific but I am not sure how
        # this can be tested otherwise.
        allow(subject).to receive(:parse) do |data, &block|
          subject.send(:legacy_parse, data, &block)
        end
      end
    end
  end

  context "default parser choice" do
    # here we cannot force the use of the Event#from_json since if this test is run in the
    # legacy context (no Java Event) it will fail but if in the new context, it will be picked up.
    it_behaves_like :codec do
      # do nothing
    end
  end

end
