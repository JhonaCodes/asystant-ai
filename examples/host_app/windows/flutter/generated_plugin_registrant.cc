//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <flutter_local_db/flutter_local_db_plugin.h>
#include <flutter_secure_storage_windows/flutter_secure_storage_windows_plugin.h>
#include <url_launcher_windows/url_launcher_windows.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  FlutterLocalDbPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FlutterLocalDbPlugin"));
  FlutterSecureStorageWindowsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FlutterSecureStorageWindowsPlugin"));
  UrlLauncherWindowsRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("UrlLauncherWindows"));
}
