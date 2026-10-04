# Minimal starter markup for newly created HTML files in the site editor.
require "cgi"

module HtmlSkeleton
  module_function

  def for_filename(file_name)
    base = File.basename(file_name.to_s)
    title = base.sub(/\.(html|htm)\z/i, "").tr("-_", " ").squeeze(" ").strip
    title = "Untitled" if title.blank?
    title = title.split.map(&:capitalize).join(" ")
    safe_title = CGI.escapeHTML(title)

    <<~HTML
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>#{safe_title}</title>
        <link rel="stylesheet" href="style.css">
      </head>
      <body>
        <main>
          <h1>#{safe_title}</h1>
          <p>Start editing this page.</p>
        </main>
        <script src="script.js"></script>
      </body>
      </html>
    HTML
  end

  def html_file?(file_name)
    file_name.to_s.downcase.end_with?(".html", ".htm")
  end
end
