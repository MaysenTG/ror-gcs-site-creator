# Shopify-style owner toolbar injected into published HTML when the viewer owns the site.
class OwnerBar
  def self.inject(html, site:, app_origin:)
    new(site: site, app_origin: app_origin).inject(html)
  end

  def initialize(site:, app_origin:)
    @site = site
    @app_origin = app_origin.to_s.chomp("/")
  end

  def inject(html)
    body = html.to_s.dup
    markup = render

    if body.match?(/<\/body>/i)
      body.sub!(/<\/body>/i, "#{markup}</body>")
    else
      body << markup
    end

    body
  end

  private

  def render
    edit_url = "#{@app_origin}/admin/sites/#{@site.name}?filename=index.html"
    dashboard_url = "#{@app_origin}/admin/sites/#{@site.name}/dashboards"

    <<~HTML
      <style id="gc-owner-bar-styles">
        #gc-owner-bar, #gc-owner-bar * { box-sizing: border-box; }
        #gc-owner-bar {
          position: fixed;
          left: 0;
          right: 0;
          bottom: 0;
          z-index: 2147483646;
          display: flex;
          align-items: center;
          justify-content: space-between;
          gap: 0.75rem;
          min-height: 3.1rem;
          padding: 0.55rem 0.9rem;
          background: #12202c;
          color: #f7f9fa;
          font-family: Manrope, "Segoe UI", sans-serif;
          font-size: 0.92rem;
          border-top: 1px solid rgba(255,255,255,0.08);
          box-shadow: 0 -8px 28px rgba(0,0,0,0.22);
        }
        #gc-owner-bar a, #gc-owner-bar button {
          font: inherit;
          color: inherit;
        }
        #gc-owner-bar__brand {
          display: inline-flex;
          align-items: center;
          gap: 0.55rem;
          min-width: 0;
          font-weight: 700;
          letter-spacing: -0.01em;
          text-decoration: none;
        }
        #gc-owner-bar__pill {
          display: inline-flex;
          align-items: center;
          padding: 0.15rem 0.45rem;
          border-radius: 999px;
          background: rgba(13,122,108,0.28);
          color: #9fe3d6;
          font-size: 0.72rem;
          font-weight: 700;
          text-transform: uppercase;
          letter-spacing: 0.04em;
        }
        #gc-owner-bar__name {
          overflow: hidden;
          text-overflow: ellipsis;
          white-space: nowrap;
        }
        #gc-owner-bar__actions {
          display: inline-flex;
          align-items: center;
          gap: 0.4rem;
          flex-wrap: wrap;
          justify-content: flex-end;
        }
        #gc-owner-bar__actions a,
        #gc-owner-bar__actions button {
          appearance: none;
          border: 1px solid rgba(255,255,255,0.14);
          background: rgba(255,255,255,0.06);
          color: #f7f9fa;
          text-decoration: none;
          border-radius: 0.45rem;
          padding: 0.35rem 0.7rem;
          font-weight: 600;
          font-size: 0.84rem;
          cursor: pointer;
          line-height: 1.2;
        }
        #gc-owner-bar__actions a:hover,
        #gc-owner-bar__actions button:hover {
          background: rgba(13,122,108,0.45);
          border-color: rgba(13,122,108,0.7);
        }
        #gc-owner-bar__actions a.is-primary {
          background: #0d7a6c;
          border-color: #0d7a6c;
        }
        #gc-owner-bar__actions a.is-primary:hover {
          background: #0a5f54;
        }
        body { padding-bottom: 3.6rem !important; }
      </style>
      <div id="gc-owner-bar" role="navigation" aria-label="Site owner toolbar">
        <div id="gc-owner-bar__brand">
          <span id="gc-owner-bar__pill">Owner</span>
          <span id="gc-owner-bar__name">#{ERB::Util.html_escape(@site.name)}</span>
        </div>
        <div id="gc-owner-bar__actions">
          <a class="is-primary" href="#{edit_url}" target="_blank" rel="noopener">Edit site</a>
          <a href="#{dashboard_url}" target="_blank" rel="noopener">Dashboard</a>
          <button type="button" id="gc-owner-bar-hide" title="Hide for today">Hide</button>
        </div>
      </div>
      <script>
        (function () {
          var btn = document.getElementById("gc-owner-bar-hide");
          if (!btn) return;
          btn.addEventListener("click", function () {
            var bar = document.getElementById("gc-owner-bar");
            var styles = document.getElementById("gc-owner-bar-styles");
            if (bar) bar.remove();
            if (styles) styles.remove();
            document.body.style.paddingBottom = "";
            var secure = location.protocol === "https:" ? "; Secure" : "";
            var host = location.hostname;
            var domain = "";
            if (host === "localhost" || host.endsWith(".localhost")) domain = "; Domain=.localhost";
            else if (host === "lvh.me" || host.endsWith(".lvh.me")) domain = "; Domain=.lvh.me";
            else if (host.endsWith(".maysengreenwood.com") || host === "maysengreenwood.com") domain = "; Domain=.maysengreenwood.com";
            document.cookie = "gc_owner_bar_hide=1; Path=/; Max-Age=86400; SameSite=Lax" + domain + secure;
          });
        })();
      </script>
    HTML
  end
end
