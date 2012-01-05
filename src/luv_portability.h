#ifndef LUV_PORTABILITY
#define LUV_PORTABILITY

#if _MSC_VER
#define snprintf _snprintf
#endif

#if defined(__OpenBSD__) || defined(__MINGW32__) || defined(_MSC_VER)
# include <nameser.h>
#else
# include <arpa/nameser.h>
#endif

/* Temporary hack: libuv should provide uv_inet_pton and uv_inet_ntop. */
#if defined(__MINGW32__) || defined(_MSC_VER)
# include <inet_net_pton.h>
# include <inet_ntop.h>
# define uv_inet_pton ares_inet_pton
# define uv_inet_ntop ares_inet_ntop

#else /* __POSIX__ */
# include <arpa/inet.h>
# define uv_inet_pton inet_pton
# define uv_inet_ntop inet_ntop
#endif

#endif
