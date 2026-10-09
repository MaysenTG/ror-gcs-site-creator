require "rails_helper"

RSpec.describe "Internal access", type: :request do
  before { ensure_plans! }

  it "blocks guests from /internal" do
    get "/internal"
    expect(response).to redirect_to(root_path).or redirect_to(new_account_session_path)
  end

  it "blocks non-admin accounts" do
    account = create_account!
    sign_in account
    get "/internal"
    expect(response).to redirect_to(root_path)
    expect(flash[:alert]).to match(/do not have access/i)
  end

  it "allows admin accounts into the ops dashboard and plans" do
    admin = create_account!
    admin.update!(admin: true)
    sign_in admin

    get "/internal"
    expect(response).to have_http_status(:ok)

    get "/internal/plans"
    expect(response).to have_http_status(:ok)

    get "/internal/accounts"
    expect(response).to have_http_status(:ok)
  end

  it "shows an account detail page for admins" do
    admin = create_account!(email: "admin-#{SecureRandom.hex(3)}@example.com")
    admin.update!(admin: true)
    member = create_account!(email: "member-#{SecureRandom.hex(3)}@example.com")
    create_site!(account: member, name: "mem-#{SecureRandom.hex(2)}")
    sign_in admin

    get "/internal/accounts/#{member.id}"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(member.email)
  end
end
