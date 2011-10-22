// This is a port of https://github.com/creationix/topcube to luvit

#include <gtk/gtk.h>
#include <webkit/webkitwebview.h>

#include "topcube.h"

static GtkWidget* window;
static GtkWidget* scrolled_window;
static GtkWidget* web_view;

static void destroy(void) {
  gtk_main_quit ();
}

static void title_change(void) {
  gtk_window_set_title(GTK_WINDOW (window), webkit_web_view_get_title(WEBKIT_WEB_VIEW (web_view)));
}

static int topcube_create_window(lua_State* L) {

  const char* url = luaL_checkstring(L, 1);
  int width = luaL_checkint(L, 2);
  int height = luaL_checkint(L, 3);

  gtk_init (NULL, NULL);

  window = gtk_window_new (GTK_WINDOW_TOPLEVEL);
  scrolled_window = gtk_scrolled_window_new (NULL, NULL);
  web_view = webkit_web_view_new ();

  g_signal_connect (window, "destroy", destroy, NULL);
  g_signal_connect (web_view, "title-changed", title_change, NULL);

  gtk_container_add (GTK_CONTAINER (scrolled_window), web_view);
  gtk_container_add (GTK_CONTAINER (window), scrolled_window);
  
  webkit_web_view_load_uri (WEBKIT_WEB_VIEW (web_view), url);

  gtk_window_set_default_size (GTK_WINDOW (window), width, height);
  gtk_widget_show_all (window);

  // TODO: find a way to not block the event loop
  gtk_main ();

  return 0;
}

static const luaL_reg topcube_f[] = {
  {"create_window", topcube_create_window},
  {NULL, NULL}
};

LUALIB_API int luaopen_topcube(lua_State *L) {
  lua_newtable (L);
  luaL_register(L, NULL, topcube_f);
  return 1;
}

