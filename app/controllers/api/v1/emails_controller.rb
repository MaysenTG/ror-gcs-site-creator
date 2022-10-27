class Api::V1::EmailsController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  def send_bulk
    # Get the params
    subject = "New mail"
    content = params[:emailContent]
    all_emails = params[:currentRecipients]
    
    
    all_emails.each do |email|
      BulkMailer.bulk_send(email, subject, content).deliver_now
    end
    # Send the emails
    #BulkMailer.bulk_send("Maysen", email, subject, content).deliver_now
    
    render json: {status: "success"}
  end
end
