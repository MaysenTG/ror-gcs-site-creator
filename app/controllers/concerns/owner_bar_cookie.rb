# Shared signed cookie so published sites (incl. subdomains) can detect a logged-in owner.
module OwnerBarCookie
  extend ActiveSupport::Concern

  COOKIE_NAME = :gc_owner_bar
  HIDE_COOKIE = :gc_owner_bar_hide

  included do
    helper_method :owner_bar_app_origin if respond_to?(:helper_method)
  end

  def refresh_owner_bar_cookie
    return unless respond_to?(:account_signed_in?) && account_signed_in?
    return if cookies.signed[COOKIE_NAME].to_i == current_account.id

    set_owner_bar_cookie(current_account)
  end

  def set_owner_bar_cookie(account)
    cookies.signed[COOKIE_NAME] = {
      value: account.id,
      httponly: true,
      same_site: :lax,
      secure: Rails.env.production?,
      expires: 2.weeks.from_now,
      domain: owner_bar_cookie_domain
    }.compact
  end

  def clear_owner_bar_cookie
    cookies.delete(COOKIE_NAME, domain: owner_bar_cookie_domain)
    cookies.delete(COOKIE_NAME)
    cookies.delete(HIDE_COOKIE, domain: owner_bar_cookie_domain)
    cookies.delete(HIDE_COOKIE)
  end

  def owner_bar_account_id
    return current_account.id if respond_to?(:current_account) && current_account

    value = cookies.signed[COOKIE_NAME]
    value.presence&.to_i
  end

  def owner_bar_hidden?
    cookies[HIDE_COOKIE].present?
  end

  def owner_bar_cookie_domain
    host = request.host.to_s
    if host == "localhost" || host.end_with?(".localhost")
      ".localhost"
    elsif host == "lvh.me" || host.end_with?(".lvh.me")
      ".lvh.me"
    elsif host == SiteStorage::DOMAIN_NAME || host.end_with?(".#{SiteStorage::DOMAIN_NAME}")
      ".#{SiteStorage::DOMAIN_NAME}"
    end
  end

  def owner_bar_app_origin
    return ENV["APP_ORIGIN"].to_s.chomp("/") if ENV["APP_ORIGIN"].present?

    if request.subdomains.present? && %w[localhost lvh.me maysengreenwood.com].include?(request.domain.to_s)
      "#{request.scheme}://#{request.domain}#{request.port_string}"
    else
      request.base_url
    end
  end
end
