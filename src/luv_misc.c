#include <stdlib.h>
#include <assert.h>

#include "luv_misc.h"

#ifndef _WIN32

const char *luv_signo_string(int signo) {
#define SIGNO_CASE(e)  case e: return #e;
  switch (signo) {

#ifdef SIGHUP
  SIGNO_CASE(SIGHUP);
#endif

#ifdef SIGINT
  SIGNO_CASE(SIGINT);
#endif

#ifdef SIGQUIT
  SIGNO_CASE(SIGQUIT);
#endif

#ifdef SIGILL
  SIGNO_CASE(SIGILL);
#endif

#ifdef SIGTRAP
  SIGNO_CASE(SIGTRAP);
#endif

#ifdef SIGABRT
  SIGNO_CASE(SIGABRT);
#endif

#ifdef SIGIOT
# if SIGABRT != SIGIOT
  SIGNO_CASE(SIGIOT);
# endif
#endif

#ifdef SIGBUS
  SIGNO_CASE(SIGBUS);
#endif

#ifdef SIGFPE
  SIGNO_CASE(SIGFPE);
#endif

#ifdef SIGKILL
  SIGNO_CASE(SIGKILL);
#endif

#ifdef SIGUSR1
  SIGNO_CASE(SIGUSR1);
#endif

#ifdef SIGSEGV
  SIGNO_CASE(SIGSEGV);
#endif

#ifdef SIGUSR2
  SIGNO_CASE(SIGUSR2);
#endif

#ifdef SIGPIPE
  SIGNO_CASE(SIGPIPE);
#endif

#ifdef SIGALRM
  SIGNO_CASE(SIGALRM);
#endif

#ifdef SIGTERM
  SIGNO_CASE(SIGTERM);
#endif

#ifdef SIGCHLD
  SIGNO_CASE(SIGCHLD);
#endif

#ifdef SIGSTKFLT
  SIGNO_CASE(SIGSTKFLT);
#endif


#ifdef SIGCONT
  SIGNO_CASE(SIGCONT);
#endif

#ifdef SIGSTOP
  SIGNO_CASE(SIGSTOP);
#endif

#ifdef SIGTSTP
  SIGNO_CASE(SIGTSTP);
#endif

#ifdef SIGTTIN
  SIGNO_CASE(SIGTTIN);
#endif

#ifdef SIGTTOU
  SIGNO_CASE(SIGTTOU);
#endif

#ifdef SIGURG
  SIGNO_CASE(SIGURG);
#endif

#ifdef SIGXCPU
  SIGNO_CASE(SIGXCPU);
#endif

#ifdef SIGXFSZ
  SIGNO_CASE(SIGXFSZ);
#endif

#ifdef SIGVTALRM
  SIGNO_CASE(SIGVTALRM);
#endif

#ifdef SIGPROF
  SIGNO_CASE(SIGPROF);
#endif

#ifdef SIGWINCH
  SIGNO_CASE(SIGWINCH);
#endif

#ifdef SIGIO
  SIGNO_CASE(SIGIO);
#endif

#ifdef SIGPOLL
# if SIGPOLL != SIGIO
  SIGNO_CASE(SIGPOLL);
# endif
#endif

#ifdef SIGLOST
  SIGNO_CASE(SIGLOST);
#endif

#ifdef SIGPWR
# if SIGPWR != SIGLOST
  SIGNO_CASE(SIGPWR);
# endif
#endif

#ifdef SIGSYS
  SIGNO_CASE(SIGSYS);
#endif

  }
  return "";
}


static void luv_on_signal(struct ev_loop *loop, struct ev_signal *w, int revents) {
  assert(uv_default_loop()->ev == loop);
  lua_State* L = (lua_State*)w->data;
  lua_getglobal(L, "process");
  lua_getfield(L, -1, "emit");
  lua_pushvalue(L, -2);
  lua_remove(L, -3);
  lua_pushstring(L, luv_signo_string(w->signum));
  lua_pushinteger(L, revents);
  lua_call(L, 3, 0);
}

#endif

int luv_activate_signal_handler(lua_State* L) {
#ifndef _WIN32
  int signal = luaL_checkint(L, 1);
  struct ev_signal* signal_watcher = (struct ev_signal*)malloc(sizeof(struct ev_signal));
  signal_watcher->data = L;
  ev_signal_init (signal_watcher, luv_on_signal, signal);
  struct ev_loop* loop = uv_default_loop()->ev;
  ev_signal_start (loop, signal_watcher);
#else
  uv_ref(uv_default_loop());
#endif
  return 0;
}


int luv_run(lua_State* L) {
  uv_run(uv_default_loop());
  return 0;
}

int luv_ref (lua_State* L) {
  uv_ref(uv_default_loop());
  return 0;
}

int luv_unref(lua_State* L) {
  uv_unref(uv_default_loop());
  return 0;
}

int luv_update_time(lua_State* L) {
  uv_update_time(uv_default_loop());
  return 0;
}

int luv_now(lua_State* L) {
  int64_t now = uv_now(uv_default_loop());
  lua_pushinteger(L, now);
  return 1;
}

int luv_hrtime(lua_State* L) {
  int64_t now = uv_hrtime();
  lua_pushinteger(L, now);
  return 1;
}

int luv_get_free_memory(lua_State* L) {
  lua_pushnumber(L, uv_get_free_memory());
  return 1;
}

int luv_get_total_memory(lua_State* L) {
  lua_pushnumber(L, uv_get_total_memory());
  return 1;
}

int luv_loadavg(lua_State* L) {
  double avg[3];
  uv_loadavg(avg);
  lua_pushnumber(L, avg[0]);
  lua_pushnumber(L, avg[1]);
  lua_pushnumber(L, avg[2]);
  return 3;
}

#ifndef PATH_MAX
#define PATH_MAX (8096)
#endif

int luv_execpath(lua_State* L) {
  size_t size = 2*PATH_MAX;
  char exec_path[2*PATH_MAX];
  if (uv_exepath(exec_path, &size)) {
    uv_err_t err = uv_last_error(uv_default_loop());
    return luaL_error(L, "uv_exepath: %s", uv_strerror(err));
  }
  lua_pushlstring(L, exec_path, size);
  return 1;
}

int luv_handle_type(lua_State* L) {
  uv_file file = luaL_checkint(L, 1);
  uv_handle_type type = uv_guess_handle(file);
  lua_pushstring(L, luv_handle_type_to_string(type));
  return 1;
}



