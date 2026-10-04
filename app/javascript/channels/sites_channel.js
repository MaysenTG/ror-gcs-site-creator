import consumer from "channels/consumer"

const accountMeta = document.querySelector('meta[name="current-account-id"]')

if (accountMeta) {
  consumer.subscriptions.create("SitesChannel", {
    received(data) {
      if (!data) return

      const message = data.message || "Site update"
      const type = data.event === "site_failed" ? "error" : "success"
      const timeout = data.event === "site_failed" ? 7000 : 5000

      window.AppToast?.show(message, { type, timeout })
      window.dispatchEvent(new CustomEvent("app:toast", { detail: { message, type, timeout } }))

      if (data.event === "site_ready" && window.location.pathname === "/admin/sites") {
        const frame = document.querySelector("turbo-frame#site_files")
        if (frame) {
          if (typeof frame.reload === "function") frame.reload()
          else frame.src = "/admin/sites/all"
        }
      }
    }
  })
}
