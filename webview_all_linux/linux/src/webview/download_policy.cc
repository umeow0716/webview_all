#include "webview/download_policy.h"

#include "plugin/webview_all_linux_plugin_private.h"
#include "webview/webview_internal.h"

DownloadPolicy::DownloadPolicy(LinuxWebView *webview) : webview_(webview) {
  signal_id_ = g_signal_connect(webkit_web_view_get_context(webview_->web_view),
                                "download-started",
                                G_CALLBACK(OnDownloadStarted), this);
}

DownloadPolicy::~DownloadPolicy() {
  g_signal_handler_disconnect(webkit_web_view_get_context(webview_->web_view),
                              signal_id_);
}

static gchar *download_uri(WebKitDownload *download) {
  WebKitURIRequest *request = webkit_download_get_request(download);
  if (request == nullptr) {
    return g_strdup("");
  }
  const gchar *uri = webkit_uri_request_get_uri(request);
  return g_strdup(uri == nullptr ? "" : uri);
}

static void emit_download_start(LinuxWebView *webview, WebKitDownload *download,
                                const gchar *suggested_filename) {
  FlValue *event = fl_value_new_map();
  fl_value_set_string_take(event, "type", fl_value_new_string("downloadStart"));
  gchar *uri = download_uri(download);
  fl_value_set_string_take(event, "url", fl_value_new_string(uri));
  g_free(uri);
  if (suggested_filename != nullptr) {
    fl_value_set_string_take(event, "suggestedFilename",
                             fl_value_new_string(suggested_filename));
  }
  send_event(webview, event);
}

void DownloadPolicy::OnDownloadStarted(WebKitWebContext *context,
                                       WebKitDownload *download,
                                       gpointer user_data) {
  auto *policy = static_cast<DownloadPolicy *>(user_data);
  if (webkit_download_get_web_view(download) != policy->webview_->web_view) {
    return;
  }
  if (!policy->enabled_) {
    webkit_download_cancel(download);
    return;
  }

  g_signal_connect(download, "decide-destination",
                   G_CALLBACK(OnDecideDestination), policy);
}

gboolean DownloadPolicy::OnDecideDestination(WebKitDownload *download,
                                             const gchar *suggested_filename,
                                             gpointer user_data) {
  auto *policy = static_cast<DownloadPolicy *>(user_data);
  if (webkit_download_get_web_view(download) != policy->webview_->web_view) {
    return FALSE;
  }
  emit_download_start(policy->webview_, download, suggested_filename);
  return FALSE;
}
