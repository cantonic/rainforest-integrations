require "active_support/core_ext/string"

describe Rainforest::Integrations::Slack do

  let(:config) do
    {slack_url: "http://example.com/slack"}
  end

  let(:event) { load_event_json("test_failure") }
  let(:response_body) { '{"ok": true}' }
  let(:response) { {body: response_body, status: 200, headers: {"content-type"=>"application/json; charset=utf-8"}} }

  subject(:integration) { described_class.new config }

  it "posts to the Slack API" do
    stub_request(:post, subject.url).to_return(response)
    integration.on_event event
  end

  context "of_text_failure" do
    let(:event) { load_event_json("test_failure") }

    describe "message_text" do
      subject(:text) { integration.message_text(event) }

      it { should include "failed" }

      it "should include the failing test title" do
        expect(text).to include "Switch to a pricing plan"
      end

      it "should include a link to the ui" do
        expect(text).to include event.ui_link
      end
    end

    describe "attachments" do
      subject(:attachments) { integration.attachments(event) }

      it "should have an attachment for each failed step" do
        expect(attachments.size).to eq(1)
      end

      describe "the attachment" do
        subject(:attachment) { attachments.first }

        describe ":text" do
          subject(:text) { attachment[:text] }

          it "should include the step number" do
            expect(text).to include("Step #2")
          end

          it "should include the result" do
            expect(text).to include "failed"
          end

          it "should include the truncated action" do
            expect(text).to include "Locate a pricing plan that..."
          end

          it "should include the truncated expected response" do
            expect(text).to include "Did you get a success message?"
          end
        end

      end

    end
  end

  context "with an error response" do
    let(:response_body) { '{ "ok": false, "error": "not_authed" }' }

    it "should raise a ConfigurationError" do
      stub_request(:post, subject.url).to_return(response)

      expect {
        subject.on_event event
      }.to raise_error(Rainforest::Integrations::ConfigurationError)
    end
  end

  context "with a bogus URI" do
    let(:config) { {slack_url: "bogus.slack.com"} }

    it "shold raise a ConfigurationError" do
      expect {
        subject.on_event event
      }.to raise_error(Rainforest::Integrations::ConfigurationError)
    end

  end

end

