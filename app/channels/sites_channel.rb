class SitesChannel < ApplicationCable::Channel
  def subscribed
    stream_from "sites_channel"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end