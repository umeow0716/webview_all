#include "plugin/webview_all_linux_plugin_private.h"
#include "plugin/host_compatibility.h"
#include "common/method_channel_utils.h"

#include <gio/gio.h>
#include <libsoup/soup.h>

#include <cstring>

static void add_cookie_finished_cb(GObject* object,
                                   GAsyncResult* result,
                                   gpointer user_data) {
  FlMethodCall* method_call = FL_METHOD_CALL(user_data);
  GError* error = nullptr;
  webkit_cookie_manager_add_cookie_finish(WEBKIT_COOKIE_MANAGER(object), result,
                                          &error);
  if (error != nullptr) {
    respond(method_call, error_response("cookie_error", error->message));
    g_clear_error(&error);
  } else {
    respond(method_call, success_response());
  }
  g_object_unref(method_call);
}

static void clear_cookies_finished_cb(GObject* object,
                                      GAsyncResult* result,
                                      gpointer user_data) {
  FlMethodCall* method_call = FL_METHOD_CALL(user_data);
  GError* error = nullptr;
  webkit_website_data_manager_clear_finish(
      WEBKIT_WEBSITE_DATA_MANAGER(object), result, &error);
  if (error != nullptr) {
    respond(method_call, error_response("cookie_error", error->message));
    g_clear_error(&error);
  } else {
    respond(method_call, success_response(fl_value_new_bool(true)));
  }
  g_object_unref(method_call);
}

static void clear_website_data_finished_cb(GObject* object,
                                           GAsyncResult* result,
                                           gpointer user_data) {
  FlMethodCall* method_call = FL_METHOD_CALL(user_data);
  GError* error = nullptr;
  webkit_website_data_manager_clear_finish(
      WEBKIT_WEBSITE_DATA_MANAGER(object), result, &error);
  if (error != nullptr) {
    respond(method_call,
            error_response("website_data_error", error->message));
    g_clear_error(&error);
  } else {
    respond(method_call, success_response());
  }
  g_object_unref(method_call);
}


static GPtrArray* proxy_ignore_hosts_from_value(FlValue* value) {
  GPtrArray* ignore_hosts = g_ptr_array_new_with_free_func(g_free);
  if (value != nullptr && fl_value_get_type(value) == FL_VALUE_TYPE_LIST) {
    const size_t length = fl_value_get_length(value);
    for (size_t i = 0; i < length; ++i) {
      FlValue* item = fl_value_get_list_value(value, i);
      if (item != nullptr && fl_value_get_type(item) == FL_VALUE_TYPE_STRING) {
        g_ptr_array_add(ignore_hosts,
                        g_strdup(fl_value_get_string(item)));
      }
    }
  }
  g_ptr_array_add(ignore_hosts, nullptr);
  return ignore_hosts;
}

static WebKitNetworkProxySettings* proxy_settings_from_value(
    FlValue* value, GError** error) {
  FlValue* proxy_rules = map_lookup(value, "proxyRules");
  if (proxy_rules == nullptr ||
      fl_value_get_type(proxy_rules) != FL_VALUE_TYPE_LIST ||
      fl_value_get_length(proxy_rules) == 0) {
    g_set_error_literal(error, G_IO_ERROR, G_IO_ERROR_INVALID_ARGUMENT,
                        "At least one proxy rule is required.");
    return nullptr;
  }

  GPtrArray* ignore_hosts =
      proxy_ignore_hosts_from_value(map_lookup(value, "bypassRules"));
  const gchar* default_proxy_uri = nullptr;
  GPtrArray* scheme_rules = g_ptr_array_new();

  const size_t length = fl_value_get_length(proxy_rules);
  for (size_t i = 0; i < length; ++i) {
    FlValue* rule = fl_value_get_list_value(proxy_rules, i);
    if (rule == nullptr || fl_value_get_type(rule) != FL_VALUE_TYPE_MAP) {
      continue;
    }

    const gchar* proxy_uri = map_lookup_string(rule, "url");
    if (proxy_uri == nullptr || strlen(proxy_uri) == 0) {
      g_set_error_literal(error, G_IO_ERROR, G_IO_ERROR_INVALID_ARGUMENT,
                          "Proxy rule URL must not be empty.");
      g_ptr_array_unref(ignore_hosts);
      g_ptr_array_unref(scheme_rules);
      return nullptr;
    }

    const gchar* scheme_filter = map_lookup_string(rule, "schemeFilter");
    if (scheme_filter == nullptr || strcmp(scheme_filter, "*") == 0) {
      if (default_proxy_uri == nullptr) {
        default_proxy_uri = proxy_uri;
      }
      continue;
    }

    if (strcmp(scheme_filter, "http") != 0 &&
        strcmp(scheme_filter, "https") != 0) {
      g_set_error(error, G_IO_ERROR, G_IO_ERROR_INVALID_ARGUMENT,
                  "Unsupported proxy scheme filter: %s", scheme_filter);
      g_ptr_array_unref(ignore_hosts);
      g_ptr_array_unref(scheme_rules);
      return nullptr;
    }

    g_ptr_array_add(scheme_rules, rule);
  }

  WebKitNetworkProxySettings* settings = webkit_network_proxy_settings_new(
      default_proxy_uri,
      reinterpret_cast<const gchar* const*>(ignore_hosts->pdata));

  for (guint i = 0; i < scheme_rules->len; ++i) {
    FlValue* rule = static_cast<FlValue*>(g_ptr_array_index(scheme_rules, i));
    const gchar* scheme_filter = map_lookup_string(rule, "schemeFilter");
    const gchar* proxy_uri = map_lookup_string(rule, "url");
    webkit_network_proxy_settings_add_proxy_for_scheme(settings, scheme_filter,
                                                       proxy_uri);
  }

  g_ptr_array_unref(ignore_hosts);
  g_ptr_array_unref(scheme_rules);
  return settings;
}

static void get_cookies_finished_cb(GObject* object,
                                    GAsyncResult* result,
                                    gpointer user_data) {
  FlMethodCall* method_call = FL_METHOD_CALL(user_data);
  GError* error = nullptr;
  GList* cookies = webkit_cookie_manager_get_cookies_finish(
      WEBKIT_COOKIE_MANAGER(object), result, &error);
  if (error != nullptr) {
    respond(method_call, error_response("cookie_error", error->message));
    g_clear_error(&error);
    g_object_unref(method_call);
    return;
  }

  FlValue* list = fl_value_new_list();
  for (GList* item = cookies; item != nullptr; item = item->next) {
    SoupCookie* cookie = static_cast<SoupCookie*>(item->data);
    FlValue* map = fl_value_new_map();
    fl_value_set_string_take(
        map, "name",
        fl_value_new_string(soup_cookie_get_name(cookie) != nullptr
                                ? soup_cookie_get_name(cookie)
                                : ""));
    fl_value_set_string_take(
        map, "value",
        fl_value_new_string(soup_cookie_get_value(cookie) != nullptr
                                ? soup_cookie_get_value(cookie)
                                : ""));
    fl_value_set_string_take(
        map, "domain",
        fl_value_new_string(soup_cookie_get_domain(cookie) != nullptr
                                ? soup_cookie_get_domain(cookie)
                                : ""));
    fl_value_set_string_take(
        map, "path",
        fl_value_new_string(soup_cookie_get_path(cookie) != nullptr
                                ? soup_cookie_get_path(cookie)
                                : "/"));
    fl_value_append_take(list, map);
  }

  g_list_free_full(cookies, reinterpret_cast<GDestroyNotify>(soup_cookie_free));
  respond(method_call, success_response(list));
  g_object_unref(method_call);
}

void root_method_call_cb(FlMethodChannel* channel,
                                FlMethodCall* method_call,
                                gpointer user_data) {
  WebviewAllLinuxPlugin* self = static_cast<WebviewAllLinuxPlugin*>(user_data);
  const gchar* method = fl_method_call_get_name(method_call);
  FlValue* args = fl_method_call_get_args(method_call);

  if (strcmp(method, "getHostCompatibility") == 0) {
    const LinuxHostCompatibilityInfo info = get_linux_host_compatibility();
    FlValue* value = fl_value_new_map();
    fl_value_set_string_take(value, "webKitGtkMajor",
                             fl_value_new_int(info.webkit_major));
    fl_value_set_string_take(value, "webKitGtkMinor",
                             fl_value_new_int(info.webkit_minor));
    fl_value_set_string_take(value, "webKitGtkMicro",
                             fl_value_new_int(info.webkit_micro));
    fl_value_set_string_take(
        value, "nvidiaProprietaryDriverDetected",
        fl_value_new_bool(info.nvidia_proprietary_driver_detected));
    fl_value_set_string_take(
        value, "legacyDisableDmabufRendererRequested",
        fl_value_new_bool(info.legacy_disable_dmabuf_renderer_requested));
    fl_value_set_string_take(
        value, "requiresEarlyRendererWorkaround",
        fl_value_new_bool(info.requires_early_renderer_workaround));
    fl_value_set_string_take(
        value, "earlyRendererWorkaroundActive",
        fl_value_new_bool(info.early_renderer_workaround_active));
    respond(method_call, success_response(value));
    return;
  }

  if (strcmp(method, "createWebView") == 0) {
    LinuxWebView* webview = create_linux_webview(self);
    if (webview == nullptr) {
      respond(method_call, error_response("creation_error",
                                          "Unable to create Linux WebView."));
      return;
    }
    respond(method_call, success_response(fl_value_new_int(webview->id)));
    return;
  }

  WebKitWebContext* context = webkit_web_context_get_default();
  WebKitCookieManager* cookie_manager =
      webkit_web_context_get_cookie_manager(context);
  WebKitWebsiteDataManager* website_data_manager =
      webkit_web_context_get_website_data_manager(context);


  if (strcmp(method, "setProxyOverride") == 0) {
    GError* error = nullptr;
    WebKitNetworkProxySettings* proxy_settings =
        proxy_settings_from_value(args, &error);
    if (error != nullptr) {
      respond(method_call, error_response("invalid_proxy_settings",
                                          error->message));
      g_clear_error(&error);
      return;
    }

    webkit_website_data_manager_set_network_proxy_settings(
        website_data_manager, WEBKIT_NETWORK_PROXY_MODE_CUSTOM, proxy_settings);
    webkit_network_proxy_settings_free(proxy_settings);
    respond(method_call, success_response());
    return;
  }

  if (strcmp(method, "clearProxyOverride") == 0) {
    webkit_website_data_manager_set_network_proxy_settings(
        website_data_manager, WEBKIT_NETWORK_PROXY_MODE_DEFAULT, nullptr);
    respond(method_call, success_response());
    return;
  }

  if (strcmp(method, "clearCookies") == 0) {
    g_object_ref(method_call);
    webkit_website_data_manager_clear(
        website_data_manager, WEBKIT_WEBSITE_DATA_COOKIES, 0, nullptr,
        clear_cookies_finished_cb, method_call);
    return;
  }

  if (strcmp(method, "clearAllWebsiteData") == 0) {
    g_object_ref(method_call);
    webkit_website_data_manager_clear(
        website_data_manager, WEBKIT_WEBSITE_DATA_ALL, 0, nullptr,
        clear_website_data_finished_cb, method_call);
    return;
  }

  if (strcmp(method, "setCookie") == 0) {
    const gchar* name = map_lookup_string(args, "name");
    const gchar* value = map_lookup_string(args, "value");
    const gchar* domain = map_lookup_string(args, "domain");
    const gchar* path = map_lookup_string(args, "path");
    if (name == nullptr || strlen(name) == 0 || value == nullptr ||
        domain == nullptr || strlen(domain) == 0) {
      respond(method_call,
              error_response("invalid_cookie",
                             "Cookie name, value, and domain are required."));
      return;
    }

    SoupCookie* cookie =
        soup_cookie_new(name, value, domain, path != nullptr ? path : "/", -1);
    g_object_ref(method_call);
    webkit_cookie_manager_add_cookie(cookie_manager, cookie, nullptr,
                                     add_cookie_finished_cb, method_call);
    soup_cookie_free(cookie);
    return;
  }

  if (strcmp(method, "getCookies") == 0) {
    const gchar* url = map_lookup_string(args, "url");
    if (url == nullptr || strlen(url) == 0) {
      respond(method_call,
              error_response("invalid_url", "A non-empty URL is required."));
      return;
    }

    g_object_ref(method_call);
    webkit_cookie_manager_get_cookies(cookie_manager, url, nullptr,
                                      get_cookies_finished_cb, method_call);
    return;
  }

  respond(method_call,
          FL_METHOD_RESPONSE(fl_method_not_implemented_response_new()));
}
