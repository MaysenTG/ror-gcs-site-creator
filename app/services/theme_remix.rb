# Apply a starter theme and/or CSS token palette onto an existing site.
class ThemeRemix
  PALETTES = {
    "forest" => {
      label: "Forest",
      vars: {
        "ink" => "#12231a",
        "muted" => "#4d6356",
        "paper" => "#f3efe6",
        "card" => "#fffdf8",
        "line" => "#d7d0c2",
        "accent" => "#0f6a4f"
      },
      font: '"Iowan Old Style", "Palatino Linotype", Palatino, Georgia, serif'
    },
    "ink" => {
      label: "Ink",
      vars: {
        "ink" => "#12202c",
        "muted" => "#3a4a59",
        "paper" => "#f7f9fa",
        "card" => "#ffffff",
        "line" => "#d5dde4",
        "accent" => "#0d7a6c"
      },
      font: '"Manrope", "Segoe UI", sans-serif'
    },
    "dusk" => {
      label: "Dusk",
      vars: {
        "ink" => "#1c1424",
        "muted" => "#5a4d66",
        "paper" => "#f6f1f8",
        "card" => "#fffbfe",
        "line" => "#ddd0e4",
        "accent" => "#7a3e9d"
      },
      font: '"Fraunces", Georgia, serif'
    },
    "coast" => {
      label: "Coast",
      vars: {
        "ink" => "#102433",
        "muted" => "#4a6270",
        "paper" => "#eef5f7",
        "card" => "#ffffff",
        "line" => "#c9d8df",
        "accent" => "#1f6f8b"
      },
      font: '"IBM Plex Sans", "Segoe UI", sans-serif'
    }
  }.freeze

  def initialize(site:, storage: SiteStorage.instance)
    @site = site
    @storage = storage
  end

  def apply_theme!(theme_type)
    bucket = bucket!
    SiteStorage.apply_theme!(bucket, theme_type)
    @site.touch
    true
  end

  def apply_palette!(palette_id)
    palette = PALETTES[palette_id.to_s]
    raise ArgumentError, "Unknown palette" unless palette

    bucket = bucket!
    css_file = bucket.file("style.css")
    css =
      if css_file
        css_file.download.read.force_encoding("ASCII-8BIT").encode("UTF-8", undef: :replace, replace: "")
      else
        "/* theme remix */\n"
      end

    css = ensure_root_block(css)
    palette[:vars].each do |key, value|
      css = upsert_css_var(css, key, value)
    end
    css = upsert_body_font(css, palette[:font])

    bucket.create_file StringIO.new(css), "style.css", cache_control: "no-store", content_type: "text/css; charset=utf-8"
    @site.touch
    true
  end

  private

  def bucket!
    bucket = @storage.bucket(@site.storage_prefix, skip_lookup: true)
    raise ActiveRecord::RecordNotFound, "Site storage missing" if bucket.nil?

    bucket
  end

  def ensure_root_block(css)
    return css if css.match?(/:root\s*\{/)

    <<~CSS + css
      :root {
        --ink: #12202c;
        --muted: #3a4a59;
        --paper: #f7f9fa;
        --card: #ffffff;
        --line: #d5dde4;
        --accent: #0d7a6c;
      }

    CSS
  end

  def upsert_css_var(css, key, value)
    pattern = /(--#{Regexp.escape(key)}\s*:\s*)([^;]+)(;)/
    if css.match?(pattern)
      css.sub(pattern, "\\1#{value}\\3")
    else
      css.sub(/:root\s*\{/) { |m| "#{m}\n  --#{key}: #{value};" }
    end
  end

  def upsert_body_font(css, font)
    if css.match?(/body\s*\{[^}]*font-family\s*:/m)
      css.sub(/(body\s*\{[^}]*font-family\s*:\s*)([^;]+)(;)/m, "\\1#{font}\\3")
    elsif css.match?(/body\s*\{/)
      css.sub(/body\s*\{/) { |m| "#{m}\n  font-family: #{font};" }
    else
      css + "\nbody { font-family: #{font}; }\n"
    end
  end
end
