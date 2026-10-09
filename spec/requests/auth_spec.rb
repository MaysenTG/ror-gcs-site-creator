require "rails_helper"

RSpec.describe "Auth", type: :request do
  before { ensure_plans! }

  it "renders sign in and sign up" do
    get new_account_session_path
    expect(response).to have_http_status(:ok)

    get new_account_registration_path
    expect(response).to have_http_status(:ok)
  end

  it "registers a new account and lands on admin sites" do
    expect {
      post account_registration_path, params: {
        account: {
          name: "New User",
          email: "new-#{SecureRandom.hex(3)}@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    }.to change(Account, :count).by(1)

    expect(response).to redirect_to("/admin/sites")
  end

  it "signs in an existing account" do
    account = create_account!(email: "login-#{SecureRandom.hex(3)}@example.com", password: "password123")
    post account_session_path, params: { account: { email: account.email, password: "password123" } }
    expect(response).to redirect_to("/admin/sites")
  end
end
