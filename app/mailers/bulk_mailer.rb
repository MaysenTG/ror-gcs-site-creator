class BulkMailer < ApplicationMailer
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.bulk_mailer.bulk_send.subject
  #
  def bulk_send(user_email, subject, content)
    @greeting = "Hi"
    @user_email = user_email
    @content = content
    @subject = subject
    
    mail(to: @user_email, subject: @subject)
  end
end
