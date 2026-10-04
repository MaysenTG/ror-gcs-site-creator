# Lightweight pre-ship audit for a static site.
class ShipCheck
  LARGE_FILE_BYTES = 500.kilobytes

  Check = Struct.new(:id, :severity, :status, :detail, keyword_init: true)

  def initialize(site:, storage: SiteStorage.new)
    @site = site
    @storage = storage
  end

  def run
    bucket = @storage.bucket(@site.storage_prefix, skip_lookup: true)
    raise ActiveRecord::RecordNotFound, "Site storage missing" if bucket.nil?

    files = bucket.files.reject { |f| f.name.end_with?("/") }
    names = files.map(&:name)
    html_files = files.select { |f| f.name.downcase.end_with?(".html", ".htm") }

    checks = []
    checks << presence_check("index.html", names)
    checks << presence_check("404.html", names)
    checks << presence_check(SiteStorage::PASSWORD_PAGE, names)
    checks << large_files_check(files)
    checks.concat(html_quality_checks(html_files, names))
    checks.concat(seo_checks(html_files))

    score = score_for(checks)
    {
      score: score,
      grade: grade_for(score),
      checks: checks.map { |c| c.to_h },
      summary: "#{checks.count { |c| c.status == "pass" }}/#{checks.size} checks passed"
    }
  end

  private

  def presence_check(name, names)
    ok = names.include?(name)
    Check.new(
      id: "has_#{name.tr('.', '_')}",
      severity: "high",
      status: ok ? "pass" : "fail",
      detail: ok ? "Found #{name}" : "Missing #{name}"
    )
  end

  def large_files_check(files)
    large = files.select { |f| f.size.to_i >= LARGE_FILE_BYTES }
    Check.new(
      id: "large_assets",
      severity: "medium",
      status: large.empty? ? "pass" : "warn",
      detail: if large.empty?
                "No files over 500 KB"
              else
                "#{large.size} large file(s): #{large.first(5).map { |f| "#{f.name} (#{helpers.number_to_human_size(f.size)})" }.join(", ")}"
              end
    )
  end

  def html_quality_checks(html_files, names)
    missing_alt = 0
    broken_links = []

    html_files.first(40).each do |file|
      html = file.download.read.force_encoding("ASCII-8BIT").encode("UTF-8", undef: :replace, replace: "")
      missing_alt += html.scan(/<img\b[^>]*>/i).count { |tag| !tag.match?(/\balt\s*=/i) }

      html.scan(/\b(?:href|src)\s*=\s*["']([^"']+)["']/i).flatten.each do |ref|
        next if ref.start_with?("#", "mailto:", "tel:", "data:", "http://", "https://", "//")

        path = ref.split("#", 2).first.split("?", 2).first.to_s
        next if path.blank? || path.start_with?("/")

        base_dir = File.dirname(file.name)
        base_dir = "" if base_dir == "."
        resolved = base_dir.present? ? "#{base_dir}/#{path}".gsub(%r{/+}, "/") : path
        resolved = resolved.delete_prefix("./")
        unless names.include?(resolved) || names.include?(path)
          broken_links << "#{file.name} → #{ref}"
        end
      end
    end

    broken_links = broken_links.first(8)
    [
      Check.new(
        id: "img_alt",
        severity: "medium",
        status: missing_alt.zero? ? "pass" : "warn",
        detail: missing_alt.zero? ? "All scanned images have alt text" : "#{missing_alt} image tag(s) missing alt"
      ),
      Check.new(
        id: "relative_links",
        severity: "high",
        status: broken_links.empty? ? "pass" : "fail",
        detail: broken_links.empty? ? "Relative links resolve" : "Broken refs: #{broken_links.join("; ")}"
      )
    ]
  end

  def seo_checks(html_files)
    index = html_files.find { |f| f.name == SiteStorage::MAIN_PAGE }
    html = if index
             index.download.read.force_encoding("ASCII-8BIT").encode("UTF-8", undef: :replace, replace: "")
           else
             ""
           end

    has_title = @site.seo_title.present? || html.match?(/<title[^>]*>\s*[^<]+<\/title>/i)
    has_description = @site.seo_description.present? || html.match?(/<meta\s+name=["']description["']/i)

    [
      Check.new(
        id: "seo_title",
        severity: "medium",
        status: has_title ? "pass" : "warn",
        detail: has_title ? "Title is set (page or site SEO settings)" : "Add a <title> or site SEO title"
      ),
      Check.new(
        id: "seo_description",
        severity: "low",
        status: has_description ? "pass" : "warn",
        detail: has_description ? "Meta description present" : "Add a meta description in SEO settings"
      ),
      Check.new(
        id: "robots_index",
        severity: "low",
        status: "pass",
        detail: @site.robots_index? ? "Search indexing allowed (robots.txt Allow)" : "Search indexing blocked (robots.txt Disallow)"
      )
    ]
  end

  def score_for(checks)
    weights = { "pass" => 1.0, "warn" => 0.55, "fail" => 0.0 }
    return 100 if checks.empty?

    ((checks.sum { |c| weights[c.status] || 0 } / checks.size) * 100).round
  end

  def grade_for(score)
    return "A" if score >= 90
    return "B" if score >= 75
    return "C" if score >= 60
    return "D" if score >= 40

    "F"
  end

  def helpers
    @helpers ||= Class.new { include ActionView::Helpers::NumberHelper }.new
  end
end
