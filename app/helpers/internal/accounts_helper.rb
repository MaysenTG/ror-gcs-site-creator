module Internal::AccountsHelper
  def internal_account_sites_label(account)
    used = account.sites.size
    max = account.current_plan&.max_sites
    max.present? ? "#{used}/#{max}" : used.to_s
  end
end
