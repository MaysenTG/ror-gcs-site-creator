require "rails_helper"

RSpec.describe SitesChannel, type: :channel do
  let(:account) { create_account! }

  before { stub_connection current_account: account }

  it "streams for the current account" do
    subscribe
    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_for(account)
  end
end
