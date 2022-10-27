# Preview all emails at http://localhost:3000/rails/mailers/bulk_mailer
class BulkMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/bulk_mailer/bulk_send
  def bulk_send
    
    unless params[:emailContent].nil?
      html_content = params[:emailContent]
    else
      html_content = 
    '<!DOCTYPE>
    <html>
      <head>
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
        <style>/* Email styles need to be inline */</style>
      </head>
      <body>
        <h1>This is my template! Hi {{name}}</h1>
      </body>
    </html>'
    end
    
    
    BulkMailer.bulk_send("greenwood.maysen@gmail.com", "Hello", html_content)
  end

end
