class SitesChannel < ApplicationCable::Channel
  def subscribed
    stream_for current_account
  end

  def unsubscribed
  end
end
