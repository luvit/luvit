






typedef signed char int8_t;
typedef short int int16_t;
typedef int int32_t;



__extension__
typedef long long int int64_t;




typedef unsigned char uint8_t;
typedef unsigned short int uint16_t;

typedef unsigned int uint32_t;





__extension__
typedef unsigned long long int uint64_t;






typedef signed char int_least8_t;
typedef short int int_least16_t;
typedef int int_least32_t;



__extension__
typedef long long int int_least64_t;



typedef unsigned char uint_least8_t;
typedef unsigned short int uint_least16_t;
typedef unsigned int uint_least32_t;



__extension__
typedef unsigned long long int uint_least64_t;






typedef signed char int_fast8_t;





typedef int int_fast16_t;
typedef int int_fast32_t;
__extension__
typedef long long int int_fast64_t;



typedef unsigned char uint_fast8_t;





typedef unsigned int uint_fast16_t;
typedef unsigned int uint_fast32_t;
__extension__
typedef unsigned long long int uint_fast64_t;
typedef int intptr_t;


typedef unsigned int uintptr_t;
__extension__
typedef long long int intmax_t;
__extension__
typedef unsigned long long int uintmax_t;




typedef unsigned char __u_char;
typedef unsigned short int __u_short;
typedef unsigned int __u_int;
typedef unsigned long int __u_long;


typedef signed char __int8_t;
typedef unsigned char __uint8_t;
typedef signed short int __int16_t;
typedef unsigned short int __uint16_t;
typedef signed int __int32_t;
typedef unsigned int __uint32_t;




__extension__ typedef signed long long int __int64_t;
__extension__ typedef unsigned long long int __uint64_t;







__extension__ typedef long long int __quad_t;
__extension__ typedef unsigned long long int __u_quad_t;


__extension__ typedef __u_quad_t __dev_t;
__extension__ typedef unsigned int __uid_t;
__extension__ typedef unsigned int __gid_t;
__extension__ typedef unsigned long int __ino_t;
__extension__ typedef __u_quad_t __ino64_t;
__extension__ typedef unsigned int __mode_t;
__extension__ typedef unsigned int __nlink_t;
__extension__ typedef long int __off_t;
__extension__ typedef __quad_t __off64_t;
__extension__ typedef int __pid_t;
__extension__ typedef struct { int __val[2]; } __fsid_t;
__extension__ typedef long int __clock_t;
__extension__ typedef unsigned long int __rlim_t;
__extension__ typedef __u_quad_t __rlim64_t;
__extension__ typedef unsigned int __id_t;
__extension__ typedef long int __time_t;
__extension__ typedef unsigned int __useconds_t;
__extension__ typedef long int __suseconds_t;

__extension__ typedef int __daddr_t;
__extension__ typedef long int __swblk_t;
__extension__ typedef int __key_t;


__extension__ typedef int __clockid_t;


__extension__ typedef void * __timer_t;


__extension__ typedef long int __blksize_t;




__extension__ typedef long int __blkcnt_t;
__extension__ typedef __quad_t __blkcnt64_t;


__extension__ typedef unsigned long int __fsblkcnt_t;
__extension__ typedef __u_quad_t __fsblkcnt64_t;


__extension__ typedef unsigned long int __fsfilcnt_t;
__extension__ typedef __u_quad_t __fsfilcnt64_t;

__extension__ typedef int __ssize_t;



typedef __off64_t __loff_t;
typedef __quad_t *__qaddr_t;
typedef char *__caddr_t;


__extension__ typedef int __intptr_t;


__extension__ typedef unsigned int __socklen_t;



typedef __u_char u_char;
typedef __u_short u_short;
typedef __u_int u_int;
typedef __u_long u_long;
typedef __quad_t quad_t;
typedef __u_quad_t u_quad_t;
typedef __fsid_t fsid_t;




typedef __loff_t loff_t;



typedef __ino_t ino_t;
typedef __dev_t dev_t;




typedef __gid_t gid_t;




typedef __mode_t mode_t;




typedef __nlink_t nlink_t;




typedef __uid_t uid_t;





typedef __off_t off_t;
typedef __pid_t pid_t;





typedef __id_t id_t;




typedef __ssize_t ssize_t;





typedef __daddr_t daddr_t;
typedef __caddr_t caddr_t;





typedef __key_t key_t;


typedef __clock_t clock_t;





typedef __time_t time_t;



typedef __clockid_t clockid_t;
typedef __timer_t timer_t;
typedef unsigned int size_t;



typedef unsigned long int ulong;
typedef unsigned short int ushort;
typedef unsigned int uint;
typedef unsigned int u_int8_t __attribute__ ((__mode__ (__QI__)));
typedef unsigned int u_int16_t __attribute__ ((__mode__ (__HI__)));
typedef unsigned int u_int32_t __attribute__ ((__mode__ (__SI__)));
typedef unsigned int u_int64_t __attribute__ ((__mode__ (__DI__)));

typedef int register_t __attribute__ ((__mode__ (__word__)));




typedef int __sig_atomic_t;




typedef struct
  {
    unsigned long int __val[(1024 / (8 * sizeof (unsigned long int)))];
  } __sigset_t;



typedef __sigset_t sigset_t;





struct timespec
  {
    __time_t tv_sec;
    long int tv_nsec;
  };

struct timeval
  {
    __time_t tv_sec;
    __suseconds_t tv_usec;
  };


typedef __suseconds_t suseconds_t;





typedef long int __fd_mask;
typedef struct
  {






    __fd_mask __fds_bits[1024 / (8 * (int) sizeof (__fd_mask))];


  } fd_set;






typedef __fd_mask fd_mask;

extern int select (int __nfds, fd_set *__restrict __readfds,
     fd_set *__restrict __writefds,
     fd_set *__restrict __exceptfds,
     struct timeval *__restrict __timeout);
extern int pselect (int __nfds, fd_set *__restrict __readfds,
      fd_set *__restrict __writefds,
      fd_set *__restrict __exceptfds,
      const struct timespec *__restrict __timeout,
      const __sigset_t *__restrict __sigmask);





__extension__
extern unsigned int gnu_dev_major (unsigned long long int __dev)
     __attribute__ ((__nothrow__));
__extension__
extern unsigned int gnu_dev_minor (unsigned long long int __dev)
     __attribute__ ((__nothrow__));
__extension__
extern unsigned long long int gnu_dev_makedev (unsigned int __major,
            unsigned int __minor)
     __attribute__ ((__nothrow__));





typedef __blksize_t blksize_t;






typedef __blkcnt_t blkcnt_t;



typedef __fsblkcnt_t fsblkcnt_t;



typedef __fsfilcnt_t fsfilcnt_t;
typedef unsigned long int pthread_t;


typedef union
{
  char __size[36];
  long int __align;
} pthread_attr_t;
typedef struct __pthread_internal_slist
{
  struct __pthread_internal_slist *__next;
} __pthread_slist_t;





typedef union
{
  struct __pthread_mutex_s
  {
    int __lock;
    unsigned int __count;
    int __owner;





    int __kind;





    unsigned int __nusers;
    __extension__ union
    {
      int __spins;
      __pthread_slist_t __list;
    };

  } __data;
  char __size[24];
  long int __align;
} pthread_mutex_t;

typedef union
{
  char __size[4];
  int __align;
} pthread_mutexattr_t;




typedef union
{
  struct
  {
    int __lock;
    unsigned int __futex;
    __extension__ unsigned long long int __total_seq;
    __extension__ unsigned long long int __wakeup_seq;
    __extension__ unsigned long long int __woken_seq;
    void *__mutex;
    unsigned int __nwaiters;
    unsigned int __broadcast_seq;
  } __data;
  char __size[48];
  __extension__ long long int __align;
} pthread_cond_t;

typedef union
{
  char __size[4];
  int __align;
} pthread_condattr_t;



typedef unsigned int pthread_key_t;



typedef int pthread_once_t;





typedef union
{
  struct
  {
    int __lock;
    unsigned int __nr_readers;
    unsigned int __readers_wakeup;
    unsigned int __writer_wakeup;
    unsigned int __nr_readers_queued;
    unsigned int __nr_writers_queued;


    unsigned char __flags;
    unsigned char __shared;
    unsigned char __pad1;
    unsigned char __pad2;
    int __writer;
  } __data;

  char __size[32];
  long int __align;
} pthread_rwlock_t;

typedef union
{
  char __size[8];
  long int __align;
} pthread_rwlockattr_t;





typedef volatile int pthread_spinlock_t;




typedef union
{
  char __size[20];
  long int __align;
} pthread_barrier_t;

typedef union
{
  char __size[4];
  int __align;
} pthread_barrierattr_t;






struct timezone
  {
    int tz_minuteswest;
    int tz_dsttime;
  };

typedef struct timezone *__restrict __timezone_ptr_t;
extern int gettimeofday (struct timeval *__restrict __tv,
    __timezone_ptr_t __tz) __attribute__ ((__nothrow__)) __attribute__ ((__nonnull__ (1)));




extern int settimeofday (__const struct timeval *__tv,
    __const struct timezone *__tz)
     __attribute__ ((__nothrow__)) __attribute__ ((__nonnull__ (1)));





extern int adjtime (__const struct timeval *__delta,
      struct timeval *__olddelta) __attribute__ ((__nothrow__));




enum __itimer_which
  {

    ITIMER_REAL = 0,


    ITIMER_VIRTUAL = 1,



    ITIMER_PROF = 2

  };



struct itimerval
  {

    struct timeval it_interval;

    struct timeval it_value;
  };






typedef int __itimer_which_t;




extern int getitimer (__itimer_which_t __which,
        struct itimerval *__value) __attribute__ ((__nothrow__));




extern int setitimer (__itimer_which_t __which,
        __const struct itimerval *__restrict __new,
        struct itimerval *__restrict __old) __attribute__ ((__nothrow__));




extern int utimes (__const char *__file, __const struct timeval __tvp[2])
     __attribute__ ((__nothrow__)) __attribute__ ((__nonnull__ (1)));



extern int lutimes (__const char *__file, __const struct timeval __tvp[2])
     __attribute__ ((__nothrow__)) __attribute__ ((__nonnull__ (1)));


extern int futimes (int __fd, __const struct timeval __tvp[2]) __attribute__ ((__nothrow__));







struct iovec
  {
    void *iov_base;
    size_t iov_len;
  };
extern ssize_t readv (int __fd, __const struct iovec *__iovec, int __count)
  ;
extern ssize_t writev (int __fd, __const struct iovec *__iovec, int __count)
  ;
extern ssize_t preadv (int __fd, __const struct iovec *__iovec, int __count,
         __off_t __offset) ;
extern ssize_t pwritev (int __fd, __const struct iovec *__iovec, int __count,
   __off_t __offset) ;







typedef __socklen_t socklen_t;




enum __socket_type
{
  SOCK_STREAM = 1,


  SOCK_DGRAM = 2,


  SOCK_RAW = 3,

  SOCK_RDM = 4,

  SOCK_SEQPACKET = 5,


  SOCK_DCCP = 6,

  SOCK_PACKET = 10,







  SOCK_CLOEXEC = 02000000,


  SOCK_NONBLOCK = 04000


};
typedef unsigned short int sa_family_t;


struct sockaddr
  {
    sa_family_t sa_family;
    char sa_data[14];
  };
struct sockaddr_storage
  {
    sa_family_t ss_family;
    unsigned long int __ss_align;
    char __ss_padding[(128 - (2 * sizeof (unsigned long int)))];
  };



enum
  {
    MSG_OOB = 0x01,

    MSG_PEEK = 0x02,

    MSG_DONTROUTE = 0x04,






    MSG_CTRUNC = 0x08,

    MSG_PROXY = 0x10,

    MSG_TRUNC = 0x20,

    MSG_DONTWAIT = 0x40,

    MSG_EOR = 0x80,

    MSG_WAITALL = 0x100,

    MSG_FIN = 0x200,

    MSG_SYN = 0x400,

    MSG_CONFIRM = 0x800,

    MSG_RST = 0x1000,

    MSG_ERRQUEUE = 0x2000,

    MSG_NOSIGNAL = 0x4000,

    MSG_MORE = 0x8000,

    MSG_WAITFORONE = 0x10000,


    MSG_CMSG_CLOEXEC = 0x40000000



  };




struct msghdr
  {
    void *msg_name;
    socklen_t msg_namelen;

    struct iovec *msg_iov;
    size_t msg_iovlen;

    void *msg_control;
    size_t msg_controllen;




    int msg_flags;
  };
struct cmsghdr
  {
    size_t cmsg_len;




    int cmsg_level;
    int cmsg_type;

    __extension__ unsigned char __cmsg_data [];

  };
extern struct cmsghdr *__cmsg_nxthdr (struct msghdr *__mhdr,
          struct cmsghdr *__cmsg) __attribute__ ((__nothrow__));
enum
  {
    SCM_RIGHTS = 0x01





  };



struct linger
  {
    int l_onoff;
    int l_linger;
  };









extern int recvmmsg (int __fd, struct mmsghdr *__vmessages,
       unsigned int __vlen, int __flags,
       __const struct timespec *__tmo);






struct osockaddr
  {
    unsigned short int sa_family;
    unsigned char sa_data[14];
  };




enum
{
  SHUT_RD = 0,

  SHUT_WR,

  SHUT_RDWR

};
extern int socket (int __domain, int __type, int __protocol) __attribute__ ((__nothrow__));





extern int socketpair (int __domain, int __type, int __protocol,
         int __fds[2]) __attribute__ ((__nothrow__));


extern int bind (int __fd, __const struct sockaddr * __addr, socklen_t __len)
     __attribute__ ((__nothrow__));


extern int getsockname (int __fd, struct sockaddr *__restrict __addr,
   socklen_t *__restrict __len) __attribute__ ((__nothrow__));
extern int connect (int __fd, __const struct sockaddr * __addr, socklen_t __len);



extern int getpeername (int __fd, struct sockaddr *__restrict __addr,
   socklen_t *__restrict __len) __attribute__ ((__nothrow__));






extern ssize_t send (int __fd, __const void *__buf, size_t __n, int __flags);






extern ssize_t recv (int __fd, void *__buf, size_t __n, int __flags);






extern ssize_t sendto (int __fd, __const void *__buf, size_t __n,
         int __flags, __const struct sockaddr * __addr,
         socklen_t __addr_len);
extern ssize_t recvfrom (int __fd, void *__restrict __buf, size_t __n,
    int __flags, struct sockaddr *__restrict __addr,
    socklen_t *__restrict __addr_len);







extern ssize_t sendmsg (int __fd, __const struct msghdr *__message,
   int __flags);






extern ssize_t recvmsg (int __fd, struct msghdr *__message, int __flags);





extern int getsockopt (int __fd, int __level, int __optname,
         void *__restrict __optval,
         socklen_t *__restrict __optlen) __attribute__ ((__nothrow__));




extern int setsockopt (int __fd, int __level, int __optname,
         __const void *__optval, socklen_t __optlen) __attribute__ ((__nothrow__));





extern int listen (int __fd, int __n) __attribute__ ((__nothrow__));
extern int accept (int __fd, struct sockaddr *__restrict __addr,
     socklen_t *__restrict __addr_len);
extern int shutdown (int __fd, int __how) __attribute__ ((__nothrow__));




extern int sockatmark (int __fd) __attribute__ ((__nothrow__));







extern int isfdtype (int __fd, int __fdtype) __attribute__ ((__nothrow__));

typedef int ares_socklen_t;



enum
  {
    IPPROTO_IP = 0,

    IPPROTO_HOPOPTS = 0,

    IPPROTO_ICMP = 1,

    IPPROTO_IGMP = 2,

    IPPROTO_IPIP = 4,

    IPPROTO_TCP = 6,

    IPPROTO_EGP = 8,

    IPPROTO_PUP = 12,

    IPPROTO_UDP = 17,

    IPPROTO_IDP = 22,

    IPPROTO_TP = 29,

    IPPROTO_DCCP = 33,

    IPPROTO_IPV6 = 41,

    IPPROTO_ROUTING = 43,

    IPPROTO_FRAGMENT = 44,

    IPPROTO_RSVP = 46,

    IPPROTO_GRE = 47,

    IPPROTO_ESP = 50,

    IPPROTO_AH = 51,

    IPPROTO_ICMPV6 = 58,

    IPPROTO_NONE = 59,

    IPPROTO_DSTOPTS = 60,

    IPPROTO_MTP = 92,

    IPPROTO_ENCAP = 98,

    IPPROTO_PIM = 103,

    IPPROTO_COMP = 108,

    IPPROTO_SCTP = 132,

    IPPROTO_UDPLITE = 136,

    IPPROTO_RAW = 255,

    IPPROTO_MAX
  };



typedef uint16_t in_port_t;


enum
  {
    IPPORT_ECHO = 7,
    IPPORT_DISCARD = 9,
    IPPORT_SYSTAT = 11,
    IPPORT_DAYTIME = 13,
    IPPORT_NETSTAT = 15,
    IPPORT_FTP = 21,
    IPPORT_TELNET = 23,
    IPPORT_SMTP = 25,
    IPPORT_TIMESERVER = 37,
    IPPORT_NAMESERVER = 42,
    IPPORT_WHOIS = 43,
    IPPORT_MTP = 57,

    IPPORT_TFTP = 69,
    IPPORT_RJE = 77,
    IPPORT_FINGER = 79,
    IPPORT_TTYLINK = 87,
    IPPORT_SUPDUP = 95,


    IPPORT_EXECSERVER = 512,
    IPPORT_LOGINSERVER = 513,
    IPPORT_CMDSERVER = 514,
    IPPORT_EFSSERVER = 520,


    IPPORT_BIFFUDP = 512,
    IPPORT_WHOSERVER = 513,
    IPPORT_ROUTESERVER = 520,


    IPPORT_RESERVED = 1024,


    IPPORT_USERRESERVED = 5000
  };



typedef uint32_t in_addr_t;
struct in_addr
  {
    in_addr_t s_addr;
  };
struct in6_addr
  {
    union
      {
 uint8_t __u6_addr8[16];

 uint16_t __u6_addr16[8];
 uint32_t __u6_addr32[4];

      } __in6_u;





  };

extern const struct in6_addr in6addr_any;
extern const struct in6_addr in6addr_loopback;
struct sockaddr_in
  {
    sa_family_t sin_family;
    in_port_t sin_port;
    struct in_addr sin_addr;


    unsigned char sin_zero[sizeof (struct sockaddr) -
      (sizeof (unsigned short int)) -
      sizeof (in_port_t) -
      sizeof (struct in_addr)];
  };


struct sockaddr_in6
  {
    sa_family_t sin6_family;
    in_port_t sin6_port;
    uint32_t sin6_flowinfo;
    struct in6_addr sin6_addr;
    uint32_t sin6_scope_id;
  };




struct ip_mreq
  {

    struct in_addr imr_multiaddr;


    struct in_addr imr_interface;
  };

struct ip_mreq_source
  {

    struct in_addr imr_multiaddr;


    struct in_addr imr_interface;


    struct in_addr imr_sourceaddr;
  };




struct ipv6_mreq
  {

    struct in6_addr ipv6mr_multiaddr;


    unsigned int ipv6mr_interface;
  };




struct group_req
  {

    uint32_t gr_interface;


    struct sockaddr_storage gr_group;
  };

struct group_source_req
  {

    uint32_t gsr_interface;


    struct sockaddr_storage gsr_group;


    struct sockaddr_storage gsr_source;
  };



struct ip_msfilter
  {

    struct in_addr imsf_multiaddr;


    struct in_addr imsf_interface;


    uint32_t imsf_fmode;


    uint32_t imsf_numsrc;

    struct in_addr imsf_slist[1];
  };





struct group_filter
  {

    uint32_t gf_interface;


    struct sockaddr_storage gf_group;


    uint32_t gf_fmode;


    uint32_t gf_numsrc;

    struct sockaddr_storage gf_slist[1];
};
struct ip_opts
  {
    struct in_addr ip_dst;
    char ip_opts[40];
  };


struct ip_mreqn
  {
    struct in_addr imr_multiaddr;
    struct in_addr imr_address;
    int imr_ifindex;
  };


struct in_pktinfo
  {
    int ipi_ifindex;
    struct in_addr ipi_spec_dst;
    struct in_addr ipi_addr;
  };
extern uint32_t ntohl (uint32_t __netlong) __attribute__ ((__nothrow__)) __attribute__ ((__const__));
extern uint16_t ntohs (uint16_t __netshort)
     __attribute__ ((__nothrow__)) __attribute__ ((__const__));
extern uint32_t htonl (uint32_t __hostlong)
     __attribute__ ((__nothrow__)) __attribute__ ((__const__));
extern uint16_t htons (uint16_t __hostshort)
     __attribute__ ((__nothrow__)) __attribute__ ((__const__));




extern int bindresvport (int __sockfd, struct sockaddr_in *__sock_in) __attribute__ ((__nothrow__));


extern int bindresvport6 (int __sockfd, struct sockaddr_in6 *__sock_in)
     __attribute__ ((__nothrow__));

typedef int ares_socket_t;





typedef void (*ares_sock_state_cb)(void *data,
                                   ares_socket_t socket_fd,
                                   int readable,
                                   int writable);

struct apattern;
struct ares_options {
  int flags;
  int timeout;
  int tries;
  int ndots;
  unsigned short udp_port;
  unsigned short tcp_port;
  int socket_send_buffer_size;
  int socket_receive_buffer_size;
  struct in_addr *servers;
  int nservers;
  char **domains;
  int ndomains;
  char *lookups;
  ares_sock_state_cb sock_state_cb;
  void *sock_state_cb_data;
  struct apattern *sortlist;
  int nsort;
};

struct hostent;
struct timeval;
struct sockaddr;
struct ares_channeldata;

typedef struct ares_channeldata *ares_channel;

typedef void (*ares_callback)(void *arg,
                              int status,
                              int timeouts,
                              unsigned char *abuf,
                              int alen);

typedef void (*ares_host_callback)(void *arg,
                                   int status,
                                   int timeouts,
                                   struct hostent *hostent);

typedef void (*ares_nameinfo_callback)(void *arg,
                                       int status,
                                       int timeouts,
                                       char *node,
                                       char *service);

typedef int (*ares_sock_create_callback)(ares_socket_t socket_fd,
                                          int type,
                                          void *data);

 int ares_library_init(int flags);

 void ares_library_cleanup(void);

 const char *ares_version(int *version);

 int ares_init(ares_channel *channelptr);

 int ares_init_options(ares_channel *channelptr,
                                   struct ares_options *options,
                                   int optmask);

 int ares_save_options(ares_channel channel,
                                   struct ares_options *options,
                                   int *optmask);

 void ares_destroy_options(struct ares_options *options);

 int ares_dup(ares_channel *dest,
                          ares_channel src);

 void ares_destroy(ares_channel channel);

 void ares_cancel(ares_channel channel);





 void ares_set_local_ip4(ares_channel channel, unsigned int local_ip);


 void ares_set_local_ip6(ares_channel channel,
                                     const unsigned char* local_ip6);


 void ares_set_local_dev(ares_channel channel,
                                     const char* local_dev_name);

 void ares_set_socket_callback(ares_channel channel,
                                           ares_sock_create_callback callback,
                                           void *user_data);

 void ares_send(ares_channel channel,
                            const unsigned char *qbuf,
                            int qlen,
                            ares_callback callback,
                            void *arg);

 void ares_query(ares_channel channel,
                             const char *name,
                             int dnsclass,
                             int type,
                             ares_callback callback,
                             void *arg);

 void ares_search(ares_channel channel,
                              const char *name,
                              int dnsclass,
                              int type,
                              ares_callback callback,
                              void *arg);

 void ares_gethostbyname(ares_channel channel,
                                     const char *name,
                                     int family,
                                     ares_host_callback callback,
                                     void *arg);

 int ares_gethostbyname_file(ares_channel channel,
                                         const char *name,
                                         int family,
                                         struct hostent **host);

 void ares_gethostbyaddr(ares_channel channel,
                                     const void *addr,
                                     int addrlen,
                                     int family,
                                     ares_host_callback callback,
                                     void *arg);

 void ares_getnameinfo(ares_channel channel,
                                   const struct sockaddr *sa,
                                   ares_socklen_t salen,
                                   int flags,
                                   ares_nameinfo_callback callback,
                                   void *arg);

 int ares_fds(ares_channel channel,
                          fd_set *read_fds,
                          fd_set *write_fds);

 int ares_getsock(ares_channel channel,
                              ares_socket_t *socks,
                              int numsocks);

 struct timeval *ares_timeout(ares_channel channel,
                                          struct timeval *maxtv,
                                          struct timeval *tv);

 void ares_process(ares_channel channel,
                               fd_set *read_fds,
                               fd_set *write_fds);

 void ares_process_fd(ares_channel channel,
                                  ares_socket_t read_fd,
                                  ares_socket_t write_fd);

 int ares_mkquery(const char *name,
                              int dnsclass,
                              int type,
                              unsigned short id,
                              int rd,
                              unsigned char **buf,
                              int *buflen);

 int ares_expand_name(const unsigned char *encoded,
                                  const unsigned char *abuf,
                                  int alen,
                                  char **s,
                                  long *enclen);

 int ares_expand_string(const unsigned char *encoded,
                                    const unsigned char *abuf,
                                    int alen,
                                    unsigned char **s,
                                    long *enclen);
struct ares_in6_addr {
  union {
    unsigned char _S6_u8[16];
  } _S6_un;
};

struct ares_addrttl {
  struct in_addr ipaddr;
  int ttl;
};

struct ares_addr6ttl {
  struct ares_in6_addr ip6addr;
  int ttl;
};

struct ares_srv_reply {
  struct ares_srv_reply *next;
  char *host;
  unsigned short priority;
  unsigned short weight;
  unsigned short port;
};

struct ares_mx_reply {
  struct ares_mx_reply *next;
  char *host;
  unsigned short priority;
};

struct ares_txt_reply {
  struct ares_txt_reply *next;
  unsigned char *txt;
  size_t length;
};
 int ares_parse_a_reply(const unsigned char *abuf,
                                    int alen,
                                    struct hostent **host,
                                    struct ares_addrttl *addrttls,
                                    int *naddrttls);

 int ares_parse_aaaa_reply(const unsigned char *abuf,
                                       int alen,
                                       struct hostent **host,
                                       struct ares_addr6ttl *addrttls,
                                       int *naddrttls);

 int ares_parse_ptr_reply(const unsigned char *abuf,
                                      int alen,
                                      const void *addr,
                                      int addrlen,
                                      int family,
                                      struct hostent **host);

 int ares_parse_ns_reply(const unsigned char *abuf,
                                     int alen,
                                     struct hostent **host);

 int ares_parse_srv_reply(const unsigned char* abuf,
                                      int alen,
                                      struct ares_srv_reply** srv_out);

 int ares_parse_mx_reply(const unsigned char* abuf,
                                      int alen,
                                      struct ares_mx_reply** mx_out);

 int ares_parse_txt_reply(const unsigned char* abuf,
                                      int alen,
                                      struct ares_txt_reply** txt_out);

 void ares_free_string(void *str);

 void ares_free_hostent(struct hostent *host);

 void ares_free_data(void *dataptr);

 const char *ares_strerror(int code);


struct ares_addr_node {
  struct ares_addr_node *next;
  int family;
  union {
    struct in_addr addr4;
    struct ares_in6_addr addr6;
  } addr;
};

 int ares_set_servers(ares_channel channel,
                                  struct ares_addr_node *servers);


 int ares_set_servers_csv(ares_channel channel,
                                      const char* servers);

 int ares_get_servers(ares_channel channel,
                                  struct ares_addr_node **servers);


typedef intptr_t ssize_t;



typedef struct ngx_queue_s ngx_queue_t;

struct ngx_queue_s {
    ngx_queue_t *prev;
    ngx_queue_t *next;
};


typedef double ev_tstamp;




extern int __sigismember (__const __sigset_t *, int);
extern int __sigaddset (__sigset_t *, int);
extern int __sigdelset (__sigset_t *, int);







typedef __sig_atomic_t sig_atomic_t;










typedef union sigval
  {
    int sival_int;
    void *sival_ptr;
  } sigval_t;
typedef struct siginfo
  {
    int si_signo;
    int si_errno;

    int si_code;

    union
      {
 int _pad[((128 / sizeof (int)) - 3)];


 struct
   {
     __pid_t si_pid;
     __uid_t si_uid;
   } _kill;


 struct
   {
     int si_tid;
     int si_overrun;
     sigval_t si_sigval;
   } _timer;


 struct
   {
     __pid_t si_pid;
     __uid_t si_uid;
     sigval_t si_sigval;
   } _rt;


 struct
   {
     __pid_t si_pid;
     __uid_t si_uid;
     int si_status;
     __clock_t si_utime;
     __clock_t si_stime;
   } _sigchld;


 struct
   {
     void *si_addr;
   } _sigfault;


 struct
   {
     long int si_band;
     int si_fd;
   } _sigpoll;
      } _sifields;
  } siginfo_t;
enum
{
  SI_ASYNCNL = -60,

  SI_TKILL = -6,

  SI_SIGIO,

  SI_ASYNCIO,

  SI_MESGQ,

  SI_TIMER,

  SI_QUEUE,

  SI_USER,

  SI_KERNEL = 0x80

};



enum
{
  ILL_ILLOPC = 1,

  ILL_ILLOPN,

  ILL_ILLADR,

  ILL_ILLTRP,

  ILL_PRVOPC,

  ILL_PRVREG,

  ILL_COPROC,

  ILL_BADSTK

};


enum
{
  FPE_INTDIV = 1,

  FPE_INTOVF,

  FPE_FLTDIV,

  FPE_FLTOVF,

  FPE_FLTUND,

  FPE_FLTRES,

  FPE_FLTINV,

  FPE_FLTSUB

};


enum
{
  SEGV_MAPERR = 1,

  SEGV_ACCERR

};


enum
{
  BUS_ADRALN = 1,

  BUS_ADRERR,

  BUS_OBJERR

};


enum
{
  TRAP_BRKPT = 1,

  TRAP_TRACE

};


enum
{
  CLD_EXITED = 1,

  CLD_KILLED,

  CLD_DUMPED,

  CLD_TRAPPED,

  CLD_STOPPED,

  CLD_CONTINUED

};


enum
{
  POLL_IN = 1,

  POLL_OUT,

  POLL_MSG,

  POLL_ERR,

  POLL_PRI,

  POLL_HUP

};
typedef struct sigevent
  {
    sigval_t sigev_value;
    int sigev_signo;
    int sigev_notify;

    union
      {
 int _pad[((64 / sizeof (int)) - 3)];



 __pid_t _tid;

 struct
   {
     void (*_function) (sigval_t);
     void *_attribute;
   } _sigev_thread;
      } _sigev_un;
  } sigevent_t;






enum
{
  SIGEV_SIGNAL = 0,

  SIGEV_NONE,

  SIGEV_THREAD,


  SIGEV_THREAD_ID = 4

};




typedef void (*__sighandler_t) (int);




extern __sighandler_t __sysv_signal (int __sig, __sighandler_t __handler)
     __attribute__ ((__nothrow__));


extern __sighandler_t signal (int __sig, __sighandler_t __handler)
     __attribute__ ((__nothrow__));

extern int kill (__pid_t __pid, int __sig) __attribute__ ((__nothrow__));






extern int killpg (__pid_t __pgrp, int __sig) __attribute__ ((__nothrow__));




extern int raise (int __sig) __attribute__ ((__nothrow__));




extern __sighandler_t ssignal (int __sig, __sighandler_t __handler)
     __attribute__ ((__nothrow__));
extern int gsignal (int __sig) __attribute__ ((__nothrow__));




extern void psignal (int __sig, __const char *__s);




extern void psiginfo (__const siginfo_t *__pinfo, __const char *__s);
extern int __sigpause (int __sig_or_mask, int __is_sig);
extern int sigblock (int __mask) __attribute__ ((__nothrow__)) __attribute__ ((__deprecated__));


extern int sigsetmask (int __mask) __attribute__ ((__nothrow__)) __attribute__ ((__deprecated__));


extern int siggetmask (void) __attribute__ ((__nothrow__)) __attribute__ ((__deprecated__));
typedef __sighandler_t sig_t;





extern int sigemptyset (sigset_t *__set) __attribute__ ((__nothrow__)) __attribute__ ((__nonnull__ (1)));


extern int sigfillset (sigset_t *__set) __attribute__ ((__nothrow__)) __attribute__ ((__nonnull__ (1)));


extern int sigaddset (sigset_t *__set, int __signo) __attribute__ ((__nothrow__)) __attribute__ ((__nonnull__ (1)));


extern int sigdelset (sigset_t *__set, int __signo) __attribute__ ((__nothrow__)) __attribute__ ((__nonnull__ (1)));


extern int sigismember (__const sigset_t *__set, int __signo)
     __attribute__ ((__nothrow__)) __attribute__ ((__nonnull__ (1)));
struct sigaction
  {


    union
      {

 __sighandler_t sa_handler;

 void (*sa_sigaction) (int, siginfo_t *, void *);
      }
    __sigaction_handler;







    __sigset_t sa_mask;


    int sa_flags;


    void (*sa_restorer) (void);
  };


extern int sigprocmask (int __how, __const sigset_t *__restrict __set,
   sigset_t *__restrict __oset) __attribute__ ((__nothrow__));






extern int sigsuspend (__const sigset_t *__set) __attribute__ ((__nonnull__ (1)));


extern int sigaction (int __sig, __const struct sigaction *__restrict __act,
        struct sigaction *__restrict __oact) __attribute__ ((__nothrow__));


extern int sigpending (sigset_t *__set) __attribute__ ((__nothrow__)) __attribute__ ((__nonnull__ (1)));






extern int sigwait (__const sigset_t *__restrict __set, int *__restrict __sig)
     __attribute__ ((__nonnull__ (1, 2)));






extern int sigwaitinfo (__const sigset_t *__restrict __set,
   siginfo_t *__restrict __info) __attribute__ ((__nonnull__ (1)));






extern int sigtimedwait (__const sigset_t *__restrict __set,
    siginfo_t *__restrict __info,
    __const struct timespec *__restrict __timeout)
     __attribute__ ((__nonnull__ (1)));



extern int sigqueue (__pid_t __pid, int __sig, __const union sigval __val)
     __attribute__ ((__nothrow__));
extern __const char *__const _sys_siglist[65];
extern __const char *__const sys_siglist[65];


struct sigvec
  {
    __sighandler_t sv_handler;
    int sv_mask;

    int sv_flags;

  };
extern int sigvec (int __sig, __const struct sigvec *__vec,
     struct sigvec *__ovec) __attribute__ ((__nothrow__));




struct _fpreg
{
  unsigned short significand[4];
  unsigned short exponent;
};

struct _fpxreg
{
  unsigned short significand[4];
  unsigned short exponent;
  unsigned short padding[3];
};

struct _xmmreg
{
  __uint32_t element[4];
};





struct _fpstate
{

  __uint32_t cw;
  __uint32_t sw;
  __uint32_t tag;
  __uint32_t ipoff;
  __uint32_t cssel;
  __uint32_t dataoff;
  __uint32_t datasel;
  struct _fpreg _st[8];
  unsigned short status;
  unsigned short magic;


  __uint32_t _fxsr_env[6];
  __uint32_t mxcsr;
  __uint32_t reserved;
  struct _fpxreg _fxsr_st[8];
  struct _xmmreg _xmm[8];
  __uint32_t padding[56];
};
struct sigcontext
{
  unsigned short gs, __gsh;
  unsigned short fs, __fsh;
  unsigned short es, __esh;
  unsigned short ds, __dsh;
  unsigned long edi;
  unsigned long esi;
  unsigned long ebp;
  unsigned long esp;
  unsigned long ebx;
  unsigned long edx;
  unsigned long ecx;
  unsigned long eax;
  unsigned long trapno;
  unsigned long err;
  unsigned long eip;
  unsigned short cs, __csh;
  unsigned long eflags;
  unsigned long esp_at_signal;
  unsigned short ss, __ssh;
  struct _fpstate * fpstate;
  unsigned long oldmask;
  unsigned long cr2;
};


extern int sigreturn (struct sigcontext *__scp) __attribute__ ((__nothrow__));










extern int siginterrupt (int __sig, int __interrupt) __attribute__ ((__nothrow__));

struct sigstack
  {
    void *ss_sp;
    int ss_onstack;
  };



enum
{
  SS_ONSTACK = 1,

  SS_DISABLE

};
typedef struct sigaltstack
  {
    void *ss_sp;
    int ss_flags;
    size_t ss_size;
  } stack_t;


typedef int greg_t;





typedef greg_t gregset_t[19];
struct _libc_fpreg
{
  unsigned short int significand[4];
  unsigned short int exponent;
};

struct _libc_fpstate
{
  unsigned long int cw;
  unsigned long int sw;
  unsigned long int tag;
  unsigned long int ipoff;
  unsigned long int cssel;
  unsigned long int dataoff;
  unsigned long int datasel;
  struct _libc_fpreg _st[8];
  unsigned long int status;
};


typedef struct _libc_fpstate *fpregset_t;


typedef struct
  {
    gregset_t gregs;


    fpregset_t fpregs;
    unsigned long int oldmask;
    unsigned long int cr2;
  } mcontext_t;


typedef struct ucontext
  {
    unsigned long int uc_flags;
    struct ucontext *uc_link;
    stack_t uc_stack;
    mcontext_t uc_mcontext;
    __sigset_t uc_sigmask;
    struct _libc_fpstate __fpregs_mem;
  } ucontext_t;





extern int sigstack (struct sigstack *__ss, struct sigstack *__oss)
     __attribute__ ((__nothrow__)) __attribute__ ((__deprecated__));



extern int sigaltstack (__const struct sigaltstack *__restrict __ss,
   struct sigaltstack *__restrict __oss) __attribute__ ((__nothrow__));
extern int pthread_sigmask (int __how,
       __const __sigset_t *__restrict __newmask,
       __sigset_t *__restrict __oldmask)__attribute__ ((__nothrow__));


extern int pthread_kill (pthread_t __threadid, int __signo) __attribute__ ((__nothrow__));






extern int __libc_current_sigrtmin (void) __attribute__ ((__nothrow__));

extern int __libc_current_sigrtmax (void) __attribute__ ((__nothrow__));






struct stat
  {
    __dev_t st_dev;

    unsigned short int __pad1;


    __ino_t st_ino;




    __mode_t st_mode;
    __nlink_t st_nlink;




    __uid_t st_uid;
    __gid_t st_gid;



    __dev_t st_rdev;

    unsigned short int __pad2;


    __off_t st_size;



    __blksize_t st_blksize;

    __blkcnt_t st_blocks;
    struct timespec st_atim;
    struct timespec st_mtim;
    struct timespec st_ctim;
    unsigned long int __unused4;
    unsigned long int __unused5;




  };
extern int stat (__const char *__restrict __file,
   struct stat *__restrict __buf) __attribute__ ((__nothrow__)) __attribute__ ((__nonnull__ (1, 2)));



extern int fstat (int __fd, struct stat *__buf) __attribute__ ((__nothrow__)) __attribute__ ((__nonnull__ (2)));
extern int fstatat (int __fd, __const char *__restrict __file,
      struct stat *__restrict __buf, int __flag)
     __attribute__ ((__nothrow__)) __attribute__ ((__nonnull__ (2, 3)));
extern int lstat (__const char *__restrict __file,
    struct stat *__restrict __buf) __attribute__ ((__nothrow__)) __attribute__ ((__nonnull__ (1, 2)));
extern int chmod (__const char *__file, __mode_t __mode)
     __attribute__ ((__nothrow__)) __attribute__ ((__nonnull__ (1)));





extern int lchmod (__const char *__file, __mode_t __mode)
     __attribute__ ((__nothrow__)) __attribute__ ((__nonnull__ (1)));




extern int fchmod (int __fd, __mode_t __mode) __attribute__ ((__nothrow__));





extern int fchmodat (int __fd, __const char *__file, __mode_t __mode,
       int __flag)
     __attribute__ ((__nothrow__)) __attribute__ ((__nonnull__ (2))) ;






extern __mode_t umask (__mode_t __mask) __attribute__ ((__nothrow__));
extern int mkdir (__const char *__path, __mode_t __mode)
     __attribute__ ((__nothrow__)) __attribute__ ((__nonnull__ (1)));





extern int mkdirat (int __fd, __const char *__path, __mode_t __mode)
     __attribute__ ((__nothrow__)) __attribute__ ((__nonnull__ (2)));






extern int mknod (__const char *__path, __mode_t __mode, __dev_t __dev)
     __attribute__ ((__nothrow__)) __attribute__ ((__nonnull__ (1)));





extern int mknodat (int __fd, __const char *__path, __mode_t __mode,
      __dev_t __dev) __attribute__ ((__nothrow__)) __attribute__ ((__nonnull__ (2)));





extern int mkfifo (__const char *__path, __mode_t __mode)
     __attribute__ ((__nothrow__)) __attribute__ ((__nonnull__ (1)));





extern int mkfifoat (int __fd, __const char *__path, __mode_t __mode)
     __attribute__ ((__nothrow__)) __attribute__ ((__nonnull__ (2)));





extern int utimensat (int __fd, __const char *__path,
        __const struct timespec __times[2],
        int __flags)
     __attribute__ ((__nothrow__)) __attribute__ ((__nonnull__ (2)));




extern int futimens (int __fd, __const struct timespec __times[2]) __attribute__ ((__nothrow__));
extern int __fxstat (int __ver, int __fildes, struct stat *__stat_buf)
     __attribute__ ((__nothrow__)) __attribute__ ((__nonnull__ (3)));
extern int __xstat (int __ver, __const char *__filename,
      struct stat *__stat_buf) __attribute__ ((__nothrow__)) __attribute__ ((__nonnull__ (2, 3)));
extern int __lxstat (int __ver, __const char *__filename,
       struct stat *__stat_buf) __attribute__ ((__nothrow__)) __attribute__ ((__nonnull__ (2, 3)));
extern int __fxstatat (int __ver, int __fildes, __const char *__filename,
         struct stat *__stat_buf, int __flag)
     __attribute__ ((__nothrow__)) __attribute__ ((__nonnull__ (3, 4)));
extern int __xmknod (int __ver, __const char *__path, __mode_t __mode,
       __dev_t *__dev) __attribute__ ((__nothrow__)) __attribute__ ((__nonnull__ (2, 4)));

extern int __xmknodat (int __ver, int __fd, __const char *__path,
         __mode_t __mode, __dev_t *__dev)
     __attribute__ ((__nothrow__)) __attribute__ ((__nonnull__ (3, 5)));





struct ev_loop;
enum {
  EV_UNDEF = -1,
  EV_NONE = 0x00,
  EV_READ = 0x01,
  EV_WRITE = 0x02,
  EV_LIBUV_KQUEUE_HACK = 0x40,
  EV__IOFDSET = 0x80,
  EV_IO = EV_READ,
  EV_TIMER = 0x00000100,

  EV_TIMEOUT = EV_TIMER,

  EV_PERIODIC = 0x00000200,
  EV_SIGNAL = 0x00000400,
  EV_CHILD = 0x00000800,
  EV_STAT = 0x00001000,
  EV_IDLE = 0x00002000,
  EV_PREPARE = 0x00004000,
  EV_CHECK = 0x00008000,
  EV_EMBED = 0x00010000,
  EV_FORK = 0x00020000,
  EV_CLEANUP = 0x00040000,
  EV_ASYNC = 0x00080000,
  EV_CUSTOM = 0x01000000,
  EV_ERROR = (-2147483647 - 1)
};
typedef struct ev_watcher
{
  int active; int pending; int priority; void *data; void (*cb)(struct ev_loop *loop, struct ev_watcher *w, int revents);
} ev_watcher;


typedef struct ev_watcher_list
{
  int active; int pending; int priority; void *data; void (*cb)(struct ev_loop *loop, struct ev_watcher_list *w, int revents); struct ev_watcher_list *next;
} ev_watcher_list;


typedef struct ev_watcher_time
{
  int active; int pending; int priority; void *data; void (*cb)(struct ev_loop *loop, struct ev_watcher_time *w, int revents); ev_tstamp at;
} ev_watcher_time;



typedef struct ev_io
{
  int active; int pending; int priority; void *data; void (*cb)(struct ev_loop *loop, struct ev_io *w, int revents); struct ev_watcher_list *next;

  int fd;
  int events;
} ev_io;



typedef struct ev_timer
{
  int active; int pending; int priority; void *data; void (*cb)(struct ev_loop *loop, struct ev_timer *w, int revents); ev_tstamp at;

  ev_tstamp repeat;
} ev_timer;



typedef struct ev_periodic
{
  int active; int pending; int priority; void *data; void (*cb)(struct ev_loop *loop, struct ev_periodic *w, int revents); ev_tstamp at;

  ev_tstamp offset;
  ev_tstamp interval;
  ev_tstamp (*reschedule_cb)(struct ev_periodic *w, ev_tstamp now);
} ev_periodic;



typedef struct ev_signal
{
  int active; int pending; int priority; void *data; void (*cb)(struct ev_loop *loop, struct ev_signal *w, int revents); struct ev_watcher_list *next;

  int signum;
} ev_signal;




typedef struct ev_child
{
  int active; int pending; int priority; void *data; void (*cb)(struct ev_loop *loop, struct ev_child *w, int revents); struct ev_watcher_list *next;

  int flags;
  int pid;
  int rpid;
  int rstatus;
} ev_child;






typedef struct stat ev_statdata;




typedef struct ev_stat
{
  int active; int pending; int priority; void *data; void (*cb)(struct ev_loop *loop, struct ev_stat *w, int revents); struct ev_watcher_list *next;

  ev_timer timer;
  ev_tstamp interval;
  const char *path;
  ev_statdata prev;
  ev_statdata attr;

  int wd;
} ev_stat;





typedef struct ev_idle
{
  int active; int pending; int priority; void *data; void (*cb)(struct ev_loop *loop, struct ev_idle *w, int revents);
} ev_idle;





typedef struct ev_prepare
{
  int active; int pending; int priority; void *data; void (*cb)(struct ev_loop *loop, struct ev_prepare *w, int revents);
} ev_prepare;



typedef struct ev_check
{
  int active; int pending; int priority; void *data; void (*cb)(struct ev_loop *loop, struct ev_check *w, int revents);
} ev_check;




typedef struct ev_fork
{
  int active; int pending; int priority; void *data; void (*cb)(struct ev_loop *loop, struct ev_fork *w, int revents);
} ev_fork;





typedef struct ev_cleanup
{
  int active; int pending; int priority; void *data; void (*cb)(struct ev_loop *loop, struct ev_cleanup *w, int revents);
} ev_cleanup;





typedef struct ev_embed
{
  int active; int pending; int priority; void *data; void (*cb)(struct ev_loop *loop, struct ev_embed *w, int revents);

  struct ev_loop *other;
  ev_io io;
  ev_prepare prepare;
  ev_check check;
  ev_timer timer;
  ev_periodic periodic;
  ev_idle idle;
  ev_fork fork;

  ev_cleanup cleanup;

} ev_embed;





typedef struct ev_async
{
  int active; int pending; int priority; void *data; void (*cb)(struct ev_loop *loop, struct ev_async *w, int revents);

  sig_atomic_t volatile sent;
} ev_async;





union ev_any_watcher
{
  struct ev_watcher w;
  struct ev_watcher_list wl;

  struct ev_io io;
  struct ev_timer timer;
  struct ev_periodic periodic;
  struct ev_signal signal;
  struct ev_child child;

  struct ev_stat stat;


  struct ev_idle idle;

  struct ev_prepare prepare;
  struct ev_check check;

  struct ev_fork fork;


  struct ev_cleanup cleanup;


  struct ev_embed embed;


  struct ev_async async;

};


enum {

  EVFLAG_AUTO = 0x00000000U,

  EVFLAG_NOENV = 0x01000000U,
  EVFLAG_FORKCHECK = 0x02000000U,

  EVFLAG_NOINOTIFY = 0x00100000U,

  EVFLAG_NOSIGFD = 0,

  EVFLAG_SIGNALFD = 0x00200000U,
  EVFLAG_NOSIGMASK = 0x00400000U
};


enum {
  EVBACKEND_SELECT = 0x00000001U,
  EVBACKEND_POLL = 0x00000002U,
  EVBACKEND_EPOLL = 0x00000004U,
  EVBACKEND_KQUEUE = 0x00000008U,
  EVBACKEND_DEVPOLL = 0x00000010U,
  EVBACKEND_PORT = 0x00000020U,
  EVBACKEND_ALL = 0x0000003FU,
  EVBACKEND_MASK = 0x0000FFFFU
};


int ev_version_major (void);
int ev_version_minor (void);

unsigned int ev_supported_backends (void);
unsigned int ev_recommended_backends (void);
unsigned int ev_embeddable_backends (void);

ev_tstamp ev_time (void);
void ev_sleep (ev_tstamp delay);







void ev_set_allocator (void *(*cb)(void *ptr, long size));





void ev_set_syserr_cb (void (*cb)(const char *msg));





struct ev_loop *ev_default_loop (unsigned int flags );

static struct ev_loop *
__attribute__ ((unused)) ev_default_loop_uc_ (void)
{
  extern struct ev_loop *ev_default_loop_ptr;

  return ev_default_loop_ptr;
}

static int
__attribute__ ((unused)) ev_is_default_loop (struct ev_loop *loop)
{
  return loop == ev_default_loop_uc_ ();
}


struct ev_loop *ev_loop_new (unsigned int flags );

ev_tstamp ev_now (struct ev_loop *loop);
void ev_loop_destroy (struct ev_loop *loop);





void ev_loop_fork (struct ev_loop *loop);

unsigned int ev_backend (struct ev_loop *loop);

void ev_now_update (struct ev_loop *loop);
enum {
  EVRUN_NOWAIT = 1,
  EVRUN_ONCE = 2
};


enum {
  EVBREAK_CANCEL = 0,
  EVBREAK_ONE = 1,
  EVBREAK_ALL = 2
};


void ev_run (struct ev_loop *loop, int flags );
void ev_break (struct ev_loop *loop, int how );






void ev_ref (struct ev_loop *loop);
void ev_unref (struct ev_loop *loop);





void ev_once (struct ev_loop *loop, int fd, int events, ev_tstamp timeout, void (*cb)(int revents, void *arg), void *arg);


unsigned int ev_iteration (struct ev_loop *loop);
unsigned int ev_depth (struct ev_loop *loop);
void ev_verify (struct ev_loop *loop);

void ev_set_io_collect_interval (struct ev_loop *loop, ev_tstamp interval);
void ev_set_timeout_collect_interval (struct ev_loop *loop, ev_tstamp interval);


void ev_set_userdata (struct ev_loop *loop, void *data);
void *ev_userdata (struct ev_loop *loop);
void ev_set_invoke_pending_cb (struct ev_loop *loop, void (*invoke_pending_cb)(struct ev_loop *loop));
void ev_set_loop_release_cb (struct ev_loop *loop, void (*release)(struct ev_loop *loop), void (*acquire)(struct ev_loop *loop));

unsigned int ev_pending_count (struct ev_loop *loop);
void ev_invoke_pending (struct ev_loop *loop);




void ev_suspend (struct ev_loop *loop);
void ev_resume (struct ev_loop *loop);
void ev_feed_event (struct ev_loop *loop, void *w, int revents);
void ev_feed_fd_event (struct ev_loop *loop, int fd, int revents);

void ev_feed_signal (int signum);
void ev_feed_signal_event (struct ev_loop *loop, int signum);

void ev_invoke (struct ev_loop *loop, void *w, int revents);
int ev_clear_pending (struct ev_loop *loop, void *w);

void ev_io_start (struct ev_loop *loop, ev_io *w);
void ev_io_stop (struct ev_loop *loop, ev_io *w);

void ev_timer_start (struct ev_loop *loop, ev_timer *w);
void ev_timer_stop (struct ev_loop *loop, ev_timer *w);

void ev_timer_again (struct ev_loop *loop, ev_timer *w);

ev_tstamp ev_timer_remaining (struct ev_loop *loop, ev_timer *w);


void ev_periodic_start (struct ev_loop *loop, ev_periodic *w);
void ev_periodic_stop (struct ev_loop *loop, ev_periodic *w);
void ev_periodic_again (struct ev_loop *loop, ev_periodic *w);




void ev_signal_start (struct ev_loop *loop, ev_signal *w);
void ev_signal_stop (struct ev_loop *loop, ev_signal *w);




void ev_child_start (struct ev_loop *loop, ev_child *w);
void ev_child_stop (struct ev_loop *loop, ev_child *w);



void ev_stat_start (struct ev_loop *loop, ev_stat *w);
void ev_stat_stop (struct ev_loop *loop, ev_stat *w);
void ev_stat_stat (struct ev_loop *loop, ev_stat *w);



void ev_idle_start (struct ev_loop *loop, ev_idle *w);
void ev_idle_stop (struct ev_loop *loop, ev_idle *w);



void ev_prepare_start (struct ev_loop *loop, ev_prepare *w);
void ev_prepare_stop (struct ev_loop *loop, ev_prepare *w);



void ev_check_start (struct ev_loop *loop, ev_check *w);
void ev_check_stop (struct ev_loop *loop, ev_check *w);



void ev_fork_start (struct ev_loop *loop, ev_fork *w);
void ev_fork_stop (struct ev_loop *loop, ev_fork *w);



void ev_cleanup_start (struct ev_loop *loop, ev_cleanup *w);
void ev_cleanup_stop (struct ev_loop *loop, ev_cleanup *w);




void ev_embed_start (struct ev_loop *loop, ev_embed *w);
void ev_embed_stop (struct ev_loop *loop, ev_embed *w);
void ev_embed_sweep (struct ev_loop *loop, ev_embed *w);



void ev_async_start (struct ev_loop *loop, ev_async *w);
void ev_async_stop (struct ev_loop *loop, ev_async *w);
void ev_async_send (struct ev_loop *loop, ev_async *w);
    static void __attribute__ ((unused)) ev_loop (struct ev_loop *loop, int flags) { ev_run (loop, flags); }
    static void __attribute__ ((unused)) ev_unloop (struct ev_loop *loop, int how ) { ev_break (loop, how ); }
    static void __attribute__ ((unused)) ev_default_destroy (void) { ev_loop_destroy (ev_default_loop (0)); }
    static void __attribute__ ((unused)) ev_default_fork (void) { ev_loop_fork (ev_default_loop (0)); }

      static unsigned int __attribute__ ((unused)) ev_loop_count (struct ev_loop *loop) { return ev_iteration (loop); }
      static unsigned int __attribute__ ((unused)) ev_loop_depth (struct ev_loop *loop) { return ev_depth (loop); }
      static void __attribute__ ((unused)) ev_loop_verify (struct ev_loop *loop) { ev_verify (loop); }

typedef int ptrdiff_t;
typedef int wchar_t;



typedef struct eio_req eio_req;
typedef struct eio_dirent eio_dirent;

typedef int (*eio_cb)(eio_req *req);
  typedef uid_t eio_uid_t;
  typedef gid_t eio_gid_t;
  typedef ssize_t eio_ssize_t;
  typedef ino_t eio_ino_t;
  typedef mode_t eio_mode_t;
enum
{
  EIO_READDIR_DENTS = 0x01,
  EIO_READDIR_DIRS_FIRST = 0x02,
  EIO_READDIR_STAT_ORDER = 0x04,
  EIO_READDIR_FOUND_UNKNOWN = 0x80,

  EIO_READDIR_CUSTOM1 = 0x100,
  EIO_READDIR_CUSTOM2 = 0x200
};


enum eio_dtype
{
  EIO_DT_UNKNOWN = 0,
  EIO_DT_FIFO = 1,
  EIO_DT_CHR = 2,
  EIO_DT_MPC = 3,
  EIO_DT_DIR = 4,
  EIO_DT_NAM = 5,
  EIO_DT_BLK = 6,
  EIO_DT_MPB = 7,
  EIO_DT_REG = 8,
  EIO_DT_NWK = 9,
  EIO_DT_CMP = 9,
  EIO_DT_LNK = 10,

  EIO_DT_SOCK = 12,
  EIO_DT_DOOR = 13,
  EIO_DT_WHT = 14,
  EIO_DT_MAX = 15
};

struct eio_dirent
{
  int nameofs;
  unsigned short namelen;
  unsigned char type;
  signed char score;
  eio_ino_t inode;
};


enum
{
  EIO_MS_ASYNC = 1,
  EIO_MS_INVALIDATE = 2,
  EIO_MS_SYNC = 4
};


enum
{
  EIO_MT_MODIFY = 1
};


enum
{
  EIO_SYNC_FILE_RANGE_WAIT_BEFORE = 1,
  EIO_SYNC_FILE_RANGE_WRITE = 2,
  EIO_SYNC_FILE_RANGE_WAIT_AFTER = 4
};


enum
{
  EIO_FALLOC_FL_KEEP_SIZE = 1
};


typedef double eio_tstamp;


enum
{
  EIO_CUSTOM,
  EIO_OPEN, EIO_CLOSE, EIO_DUP2,
  EIO_READ, EIO_WRITE,
  EIO_READAHEAD, EIO_SENDFILE,
  EIO_STAT, EIO_LSTAT, EIO_FSTAT,
  EIO_STATVFS, EIO_FSTATVFS,
  EIO_TRUNCATE, EIO_FTRUNCATE,
  EIO_UTIME, EIO_FUTIME,
  EIO_CHMOD, EIO_FCHMOD,
  EIO_CHOWN, EIO_FCHOWN,
  EIO_SYNC, EIO_FSYNC, EIO_FDATASYNC, EIO_SYNCFS,
  EIO_MSYNC, EIO_MTOUCH, EIO_SYNC_FILE_RANGE, EIO_FALLOCATE,
  EIO_MLOCK, EIO_MLOCKALL,
  EIO_UNLINK, EIO_RMDIR, EIO_MKDIR, EIO_RENAME,
  EIO_MKNOD, EIO_READDIR,
  EIO_LINK, EIO_SYMLINK, EIO_READLINK, EIO_REALPATH,
  EIO_GROUP, EIO_NOP,
  EIO_BUSY
};


enum
{
  EIO_MCL_CURRENT = 1,
  EIO_MCL_FUTURE = 2
};



enum {
  EIO_PRI_MIN = -4,
  EIO_PRI_MAX = 4,
  EIO_PRI_DEFAULT = 0
};




struct eio_req
{
  eio_req volatile *next;

  eio_ssize_t result;
  off_t offs;
  size_t size;
  void *ptr1;
  void *ptr2;
  eio_tstamp nv1;
  eio_tstamp nv2;

  int type;
  int int1;
  long int2;
  long int3;
  int errorno;


  unsigned char cancelled;




  unsigned char flags;
  signed char pri;

  void *data;
  eio_cb finish;
  void (*destroy)(eio_req *req);
  void (*feed)(eio_req *req);

 

  eio_req *grp, *grp_prev, *grp_next, *grp_first;
};


enum {
  EIO_FLAG_PTR1_FREE = 0x01,
  EIO_FLAG_PTR2_FREE = 0x02,
  EIO_FLAG_GROUPADD = 0x04
};
int eio_init (void (*want_poll)(void), void (*done_poll)(void));



int eio_poll (void);


void eio_set_max_poll_time (eio_tstamp nseconds);

void eio_set_max_poll_reqs (unsigned int nreqs);




void eio_set_min_parallel (unsigned int nthreads);
void eio_set_max_parallel (unsigned int nthreads);
void eio_set_max_idle (unsigned int nthreads);
void eio_set_idle_timeout (unsigned int seconds);

unsigned int eio_nreqs (void);
unsigned int eio_nready (void);
unsigned int eio_npending (void);
unsigned int eio_nthreads (void);





eio_req *eio_nop (int pri, eio_cb cb, void *data);
eio_req *eio_busy (eio_tstamp delay, int pri, eio_cb cb, void *data);
eio_req *eio_sync (int pri, eio_cb cb, void *data);
eio_req *eio_fsync (int fd, int pri, eio_cb cb, void *data);
eio_req *eio_fdatasync (int fd, int pri, eio_cb cb, void *data);
eio_req *eio_syncfs (int fd, int pri, eio_cb cb, void *data);
eio_req *eio_msync (void *addr, size_t length, int flags, int pri, eio_cb cb, void *data);
eio_req *eio_mtouch (void *addr, size_t length, int flags, int pri, eio_cb cb, void *data);
eio_req *eio_mlock (void *addr, size_t length, int pri, eio_cb cb, void *data);
eio_req *eio_mlockall (int flags, int pri, eio_cb cb, void *data);
eio_req *eio_sync_file_range (int fd, off_t offset, size_t nbytes, unsigned int flags, int pri, eio_cb cb, void *data);
eio_req *eio_fallocate (int fd, int mode, off_t offset, size_t len, int pri, eio_cb cb, void *data);
eio_req *eio_close (int fd, int pri, eio_cb cb, void *data);
eio_req *eio_readahead (int fd, off_t offset, size_t length, int pri, eio_cb cb, void *data);
eio_req *eio_read (int fd, void *buf, size_t length, off_t offset, int pri, eio_cb cb, void *data);
eio_req *eio_write (int fd, void *buf, size_t length, off_t offset, int pri, eio_cb cb, void *data);
eio_req *eio_fstat (int fd, int pri, eio_cb cb, void *data);
eio_req *eio_fstatvfs (int fd, int pri, eio_cb cb, void *data);
eio_req *eio_futime (int fd, eio_tstamp atime, eio_tstamp mtime, int pri, eio_cb cb, void *data);
eio_req *eio_ftruncate (int fd, off_t offset, int pri, eio_cb cb, void *data);
eio_req *eio_fchmod (int fd, eio_mode_t mode, int pri, eio_cb cb, void *data);
eio_req *eio_fchown (int fd, eio_uid_t uid, eio_gid_t gid, int pri, eio_cb cb, void *data);
eio_req *eio_dup2 (int fd, int fd2, int pri, eio_cb cb, void *data);
eio_req *eio_sendfile (int out_fd, int in_fd, off_t in_offset, size_t length, int pri, eio_cb cb, void *data);
eio_req *eio_open (const char *path, int flags, eio_mode_t mode, int pri, eio_cb cb, void *data);
eio_req *eio_utime (const char *path, eio_tstamp atime, eio_tstamp mtime, int pri, eio_cb cb, void *data);
eio_req *eio_truncate (const char *path, off_t offset, int pri, eio_cb cb, void *data);
eio_req *eio_chown (const char *path, eio_uid_t uid, eio_gid_t gid, int pri, eio_cb cb, void *data);
eio_req *eio_chmod (const char *path, eio_mode_t mode, int pri, eio_cb cb, void *data);
eio_req *eio_mkdir (const char *path, eio_mode_t mode, int pri, eio_cb cb, void *data);
eio_req *eio_readdir (const char *path, int flags, int pri, eio_cb cb, void *data);
eio_req *eio_rmdir (const char *path, int pri, eio_cb cb, void *data);
eio_req *eio_unlink (const char *path, int pri, eio_cb cb, void *data);
eio_req *eio_readlink (const char *path, int pri, eio_cb cb, void *data);
eio_req *eio_realpath (const char *path, int pri, eio_cb cb, void *data);
eio_req *eio_stat (const char *path, int pri, eio_cb cb, void *data);
eio_req *eio_lstat (const char *path, int pri, eio_cb cb, void *data);
eio_req *eio_statvfs (const char *path, int pri, eio_cb cb, void *data);
eio_req *eio_mknod (const char *path, eio_mode_t mode, dev_t dev, int pri, eio_cb cb, void *data);
eio_req *eio_link (const char *path, const char *new_path, int pri, eio_cb cb, void *data);
eio_req *eio_symlink (const char *path, const char *new_path, int pri, eio_cb cb, void *data);
eio_req *eio_rename (const char *path, const char *new_path, int pri, eio_cb cb, void *data);
eio_req *eio_custom (void (*execute)(eio_req *), int pri, eio_cb cb, void *data);





eio_req *eio_grp (eio_cb cb, void *data);
void eio_grp_feed (eio_req *grp, void (*feed)(eio_req *req), int limit);
void eio_grp_limit (eio_req *grp, int limit);
void eio_grp_add (eio_req *grp, eio_req *req);
void eio_grp_cancel (eio_req *grp);
void eio_submit (eio_req *req);

void eio_cancel (eio_req *req);




eio_ssize_t eio_sendfile_sync (int ofd, int ifd, off_t offset, size_t count);
eio_ssize_t eio__pread (int fd, void *buf, size_t count, off_t offset);
eio_ssize_t eio__pwrite (int fd, void *buf, size_t count, off_t offset);




struct tcphdr
  {
    u_int16_t source;
    u_int16_t dest;
    u_int32_t seq;
    u_int32_t ack_seq;

    u_int16_t res1:4;
    u_int16_t doff:4;
    u_int16_t fin:1;
    u_int16_t syn:1;
    u_int16_t rst:1;
    u_int16_t psh:1;
    u_int16_t ack:1;
    u_int16_t urg:1;
    u_int16_t res2:2;
    u_int16_t window;
    u_int16_t check;
    u_int16_t urg_ptr;
};


enum
{
  TCP_ESTABLISHED = 1,
  TCP_SYN_SENT,
  TCP_SYN_RECV,
  TCP_FIN_WAIT1,
  TCP_FIN_WAIT2,
  TCP_TIME_WAIT,
  TCP_CLOSE,
  TCP_CLOSE_WAIT,
  TCP_LAST_ACK,
  TCP_LISTEN,
  TCP_CLOSING
};
enum tcp_ca_state
{
  TCP_CA_Open = 0,
  TCP_CA_Disorder = 1,
  TCP_CA_CWR = 2,
  TCP_CA_Recovery = 3,
  TCP_CA_Loss = 4
};

struct tcp_info
{
  u_int8_t tcpi_state;
  u_int8_t tcpi_ca_state;
  u_int8_t tcpi_retransmits;
  u_int8_t tcpi_probes;
  u_int8_t tcpi_backoff;
  u_int8_t tcpi_options;
  u_int8_t tcpi_snd_wscale : 4, tcpi_rcv_wscale : 4;

  u_int32_t tcpi_rto;
  u_int32_t tcpi_ato;
  u_int32_t tcpi_snd_mss;
  u_int32_t tcpi_rcv_mss;

  u_int32_t tcpi_unacked;
  u_int32_t tcpi_sacked;
  u_int32_t tcpi_lost;
  u_int32_t tcpi_retrans;
  u_int32_t tcpi_fackets;


  u_int32_t tcpi_last_data_sent;
  u_int32_t tcpi_last_ack_sent;
  u_int32_t tcpi_last_data_recv;
  u_int32_t tcpi_last_ack_recv;


  u_int32_t tcpi_pmtu;
  u_int32_t tcpi_rcv_ssthresh;
  u_int32_t tcpi_rtt;
  u_int32_t tcpi_rttvar;
  u_int32_t tcpi_snd_ssthresh;
  u_int32_t tcpi_snd_cwnd;
  u_int32_t tcpi_advmss;
  u_int32_t tcpi_reordering;

  u_int32_t tcpi_rcv_rtt;
  u_int32_t tcpi_rcv_space;

  u_int32_t tcpi_total_retrans;
};





struct tcp_md5sig
{
  struct sockaddr_storage tcpm_addr;
  u_int16_t __tcpm_pad1;
  u_int16_t tcpm_keylen;
  u_int32_t __tcpm_pad2;
  u_int8_t tcpm_key[80];
};




extern in_addr_t inet_addr (__const char *__cp) __attribute__ ((__nothrow__));


extern in_addr_t inet_lnaof (struct in_addr __in) __attribute__ ((__nothrow__));



extern struct in_addr inet_makeaddr (in_addr_t __net, in_addr_t __host)
     __attribute__ ((__nothrow__));


extern in_addr_t inet_netof (struct in_addr __in) __attribute__ ((__nothrow__));



extern in_addr_t inet_network (__const char *__cp) __attribute__ ((__nothrow__));



extern char *inet_ntoa (struct in_addr __in) __attribute__ ((__nothrow__));




extern int inet_pton (int __af, __const char *__restrict __cp,
        void *__restrict __buf) __attribute__ ((__nothrow__));




extern __const char *inet_ntop (int __af, __const void *__restrict __cp,
    char *__restrict __buf, socklen_t __len)
     __attribute__ ((__nothrow__));






extern int inet_aton (__const char *__cp, struct in_addr *__inp) __attribute__ ((__nothrow__));



extern char *inet_neta (in_addr_t __net, char *__buf, size_t __len) __attribute__ ((__nothrow__));




extern char *inet_net_ntop (int __af, __const void *__cp, int __bits,
       char *__buf, size_t __len) __attribute__ ((__nothrow__));




extern int inet_net_pton (int __af, __const char *__cp,
     void *__buf, size_t __len) __attribute__ ((__nothrow__));




extern unsigned int inet_nsap_addr (__const char *__cp,
        unsigned char *__buf, int __len) __attribute__ ((__nothrow__));



extern char *inet_nsap_ntoa (int __len, __const unsigned char *__cp,
        char *__buf) __attribute__ ((__nothrow__));






struct rpcent
{
  char *r_name;
  char **r_aliases;
  int r_number;
};

extern void setrpcent (int __stayopen) __attribute__ ((__nothrow__));
extern void endrpcent (void) __attribute__ ((__nothrow__));
extern struct rpcent *getrpcbyname (__const char *__name) __attribute__ ((__nothrow__));
extern struct rpcent *getrpcbynumber (int __number) __attribute__ ((__nothrow__));
extern struct rpcent *getrpcent (void) __attribute__ ((__nothrow__));


extern int getrpcbyname_r (__const char *__name, struct rpcent *__result_buf,
      char *__buffer, size_t __buflen,
      struct rpcent **__result) __attribute__ ((__nothrow__));

extern int getrpcbynumber_r (int __number, struct rpcent *__result_buf,
        char *__buffer, size_t __buflen,
        struct rpcent **__result) __attribute__ ((__nothrow__));

extern int getrpcent_r (struct rpcent *__result_buf, char *__buffer,
   size_t __buflen, struct rpcent **__result) __attribute__ ((__nothrow__));



struct netent
{
  char *n_name;
  char **n_aliases;
  int n_addrtype;
  uint32_t n_net;
};








extern int *__h_errno_location (void) __attribute__ ((__nothrow__)) __attribute__ ((__const__));
extern void herror (__const char *__str) __attribute__ ((__nothrow__));


extern __const char *hstrerror (int __err_num) __attribute__ ((__nothrow__));




struct hostent
{
  char *h_name;
  char **h_aliases;
  int h_addrtype;
  int h_length;
  char **h_addr_list;



};






extern void sethostent (int __stay_open);





extern void endhostent (void);






extern struct hostent *gethostent (void);






extern struct hostent *gethostbyaddr (__const void *__addr, __socklen_t __len,
          int __type);





extern struct hostent *gethostbyname (__const char *__name);
extern struct hostent *gethostbyname2 (__const char *__name, int __af);
extern int gethostent_r (struct hostent *__restrict __result_buf,
    char *__restrict __buf, size_t __buflen,
    struct hostent **__restrict __result,
    int *__restrict __h_errnop);

extern int gethostbyaddr_r (__const void *__restrict __addr, __socklen_t __len,
       int __type,
       struct hostent *__restrict __result_buf,
       char *__restrict __buf, size_t __buflen,
       struct hostent **__restrict __result,
       int *__restrict __h_errnop);

extern int gethostbyname_r (__const char *__restrict __name,
       struct hostent *__restrict __result_buf,
       char *__restrict __buf, size_t __buflen,
       struct hostent **__restrict __result,
       int *__restrict __h_errnop);

extern int gethostbyname2_r (__const char *__restrict __name, int __af,
        struct hostent *__restrict __result_buf,
        char *__restrict __buf, size_t __buflen,
        struct hostent **__restrict __result,
        int *__restrict __h_errnop);
extern void setnetent (int __stay_open);





extern void endnetent (void);






extern struct netent *getnetent (void);






extern struct netent *getnetbyaddr (uint32_t __net, int __type);





extern struct netent *getnetbyname (__const char *__name);
extern int getnetent_r (struct netent *__restrict __result_buf,
   char *__restrict __buf, size_t __buflen,
   struct netent **__restrict __result,
   int *__restrict __h_errnop);

extern int getnetbyaddr_r (uint32_t __net, int __type,
      struct netent *__restrict __result_buf,
      char *__restrict __buf, size_t __buflen,
      struct netent **__restrict __result,
      int *__restrict __h_errnop);

extern int getnetbyname_r (__const char *__restrict __name,
      struct netent *__restrict __result_buf,
      char *__restrict __buf, size_t __buflen,
      struct netent **__restrict __result,
      int *__restrict __h_errnop);




struct servent
{
  char *s_name;
  char **s_aliases;
  int s_port;
  char *s_proto;
};






extern void setservent (int __stay_open);





extern void endservent (void);






extern struct servent *getservent (void);






extern struct servent *getservbyname (__const char *__name,
          __const char *__proto);






extern struct servent *getservbyport (int __port, __const char *__proto);
extern int getservent_r (struct servent *__restrict __result_buf,
    char *__restrict __buf, size_t __buflen,
    struct servent **__restrict __result);

extern int getservbyname_r (__const char *__restrict __name,
       __const char *__restrict __proto,
       struct servent *__restrict __result_buf,
       char *__restrict __buf, size_t __buflen,
       struct servent **__restrict __result);

extern int getservbyport_r (int __port, __const char *__restrict __proto,
       struct servent *__restrict __result_buf,
       char *__restrict __buf, size_t __buflen,
       struct servent **__restrict __result);




struct protoent
{
  char *p_name;
  char **p_aliases;
  int p_proto;
};






extern void setprotoent (int __stay_open);





extern void endprotoent (void);






extern struct protoent *getprotoent (void);





extern struct protoent *getprotobyname (__const char *__name);





extern struct protoent *getprotobynumber (int __proto);
extern int getprotoent_r (struct protoent *__restrict __result_buf,
     char *__restrict __buf, size_t __buflen,
     struct protoent **__restrict __result);

extern int getprotobyname_r (__const char *__restrict __name,
        struct protoent *__restrict __result_buf,
        char *__restrict __buf, size_t __buflen,
        struct protoent **__restrict __result);

extern int getprotobynumber_r (int __proto,
          struct protoent *__restrict __result_buf,
          char *__restrict __buf, size_t __buflen,
          struct protoent **__restrict __result);
extern int setnetgrent (__const char *__netgroup);







extern void endnetgrent (void);
extern int getnetgrent (char **__restrict __hostp,
   char **__restrict __userp,
   char **__restrict __domainp);
extern int innetgr (__const char *__netgroup, __const char *__host,
      __const char *__user, __const char *__domain);







extern int getnetgrent_r (char **__restrict __hostp,
     char **__restrict __userp,
     char **__restrict __domainp,
     char *__restrict __buffer, size_t __buflen);
extern int rcmd (char **__restrict __ahost, unsigned short int __rport,
   __const char *__restrict __locuser,
   __const char *__restrict __remuser,
   __const char *__restrict __cmd, int *__restrict __fd2p);
extern int rcmd_af (char **__restrict __ahost, unsigned short int __rport,
      __const char *__restrict __locuser,
      __const char *__restrict __remuser,
      __const char *__restrict __cmd, int *__restrict __fd2p,
      sa_family_t __af);
extern int rexec (char **__restrict __ahost, int __rport,
    __const char *__restrict __name,
    __const char *__restrict __pass,
    __const char *__restrict __cmd, int *__restrict __fd2p);
extern int rexec_af (char **__restrict __ahost, int __rport,
       __const char *__restrict __name,
       __const char *__restrict __pass,
       __const char *__restrict __cmd, int *__restrict __fd2p,
       sa_family_t __af);
extern int ruserok (__const char *__rhost, int __suser,
      __const char *__remuser, __const char *__locuser);
extern int ruserok_af (__const char *__rhost, int __suser,
         __const char *__remuser, __const char *__locuser,
         sa_family_t __af);
extern int iruserok (uint32_t __raddr, int __suser,
       __const char *__remuser, __const char *__locuser);
extern int iruserok_af (__const void *__raddr, int __suser,
   __const char *__remuser, __const char *__locuser,
   sa_family_t __af);
extern int rresvport (int *__alport);
extern int rresvport_af (int *__alport, sa_family_t __af);






struct addrinfo
{
  int ai_flags;
  int ai_family;
  int ai_socktype;
  int ai_protocol;
  socklen_t ai_addrlen;
  struct sockaddr *ai_addr;
  char *ai_canonname;
  struct addrinfo *ai_next;
};
extern int getaddrinfo (__const char *__restrict __name,
   __const char *__restrict __service,
   __const struct addrinfo *__restrict __req,
   struct addrinfo **__restrict __pai);


extern void freeaddrinfo (struct addrinfo *__ai) __attribute__ ((__nothrow__));


extern __const char *gai_strerror (int __ecode) __attribute__ ((__nothrow__));





extern int getnameinfo (__const struct sockaddr *__restrict __sa,
   socklen_t __salen, char *__restrict __host,
   socklen_t __hostlen, char *__restrict __serv,
   socklen_t __servlen, unsigned int __flags);





typedef unsigned char cc_t;
typedef unsigned int speed_t;
typedef unsigned int tcflag_t;


struct termios
  {
    tcflag_t c_iflag;
    tcflag_t c_oflag;
    tcflag_t c_cflag;
    tcflag_t c_lflag;
    cc_t c_line;
    cc_t c_cc[32];
    speed_t c_ispeed;
    speed_t c_ospeed;


  };
extern speed_t cfgetospeed (__const struct termios *__termios_p) __attribute__ ((__nothrow__));


extern speed_t cfgetispeed (__const struct termios *__termios_p) __attribute__ ((__nothrow__));


extern int cfsetospeed (struct termios *__termios_p, speed_t __speed) __attribute__ ((__nothrow__));


extern int cfsetispeed (struct termios *__termios_p, speed_t __speed) __attribute__ ((__nothrow__));



extern int cfsetspeed (struct termios *__termios_p, speed_t __speed) __attribute__ ((__nothrow__));




extern int tcgetattr (int __fd, struct termios *__termios_p) __attribute__ ((__nothrow__));



extern int tcsetattr (int __fd, int __optional_actions,
        __const struct termios *__termios_p) __attribute__ ((__nothrow__));




extern void cfmakeraw (struct termios *__termios_p) __attribute__ ((__nothrow__));



extern int tcsendbreak (int __fd, int __duration) __attribute__ ((__nothrow__));





extern int tcdrain (int __fd);



extern int tcflush (int __fd, int __queue_selector) __attribute__ ((__nothrow__));



extern int tcflow (int __fd, int __action) __attribute__ ((__nothrow__));





typedef struct {
  char* base;
  size_t len;
} uv_buf_t;

typedef int uv_file;


typedef void* uv_lib_t;





typedef enum {
  UV_UNKNOWN = -1,
  UV_OK = 0,
  UV_EOF,
  UV_EADDRINFO,
  UV_EACCESS,
  UV_EAGAIN,
  UV_EADDRINUSE,
  UV_EADDRNOTAVAIL,
  UV_EAFNOSUPPORT,
  UV_EALREADY,
  UV_EBADF,
  UV_EBUSY,
  UV_ECONNABORTED,
  UV_ECONNREFUSED,
  UV_ECONNRESET,
  UV_EDESTADDRREQ,
  UV_EFAULT,
  UV_EHOSTUNREACH,
  UV_EINTR,
  UV_EINVAL,
  UV_EISCONN,
  UV_EMFILE,
  UV_EMSGSIZE,
  UV_ENETDOWN,
  UV_ENETUNREACH,
  UV_ENFILE,
  UV_ENOBUFS,
  UV_ENOMEM,
  UV_ENOTDIR,
  UV_ENONET,
  UV_ENOPROTOOPT,
  UV_ENOTCONN,
  UV_ENOTSOCK,
  UV_ENOTSUP,
  UV_ENOENT,
  UV_ENOSYS,
  UV_EPIPE,
  UV_EPROTO,
  UV_EPROTONOSUPPORT,
  UV_EPROTOTYPE,
  UV_ETIMEDOUT,
  UV_ECHARSET,
  UV_EAIFAMNOSUPPORT,
  UV_EAINONAME,
  UV_EAISERVICE,
  UV_EAISOCKTYPE,
  UV_ESHUTDOWN,
  UV_EEXIST
} uv_err_code;

typedef enum {
  UV_UNKNOWN_HANDLE = 0,
  UV_TCP,
  UV_UDP,
  UV_NAMED_PIPE,
  UV_TTY,
  UV_FILE,
  UV_TIMER,
  UV_PREPARE,
  UV_CHECK,
  UV_IDLE,
  UV_ASYNC,
  UV_ARES_TASK,
  UV_ARES_EVENT,
  UV_PROCESS,
  UV_FS_EVENT
} uv_handle_type;

typedef enum {
  UV_UNKNOWN_REQ = 0,
  UV_CONNECT,
  UV_ACCEPT,
  UV_READ,
  UV_WRITE,
  UV_SHUTDOWN,
  UV_WAKEUP,
  UV_UDP_SEND,
  UV_FS,
  UV_WORK,
  UV_GETADDRINFO,
  UV_REQ_TYPE_PRIVATE
} uv_req_type;



typedef struct uv_loop_s uv_loop_t;
typedef struct uv_ares_task_s uv_ares_task_t;
typedef struct uv_err_s uv_err_t;
typedef struct uv_handle_s uv_handle_t;
typedef struct uv_stream_s uv_stream_t;
typedef struct uv_tcp_s uv_tcp_t;
typedef struct uv_udp_s uv_udp_t;
typedef struct uv_pipe_s uv_pipe_t;
typedef struct uv_tty_s uv_tty_t;
typedef struct uv_timer_s uv_timer_t;
typedef struct uv_prepare_s uv_prepare_t;
typedef struct uv_check_s uv_check_t;
typedef struct uv_idle_s uv_idle_t;
typedef struct uv_async_s uv_async_t;
typedef struct uv_getaddrinfo_s uv_getaddrinfo_t;
typedef struct uv_process_s uv_process_t;
typedef struct uv_counters_s uv_counters_t;

typedef struct uv_req_s uv_req_t;
typedef struct uv_shutdown_s uv_shutdown_t;
typedef struct uv_write_s uv_write_t;
typedef struct uv_connect_s uv_connect_t;
typedef struct uv_udp_send_s uv_udp_send_t;
typedef struct uv_fs_s uv_fs_t;

typedef struct uv_fs_event_s uv_fs_event_t;
typedef struct uv_work_s uv_work_t;
 uv_loop_t* uv_loop_new();
 void uv_loop_delete(uv_loop_t*);





 uv_loop_t* uv_default_loop();





 int uv_run (uv_loop_t*);





 void uv_ref(uv_loop_t*);
 void uv_unref(uv_loop_t*);

 void uv_update_time(uv_loop_t*);
 int64_t uv_now(uv_loop_t*);
typedef uv_buf_t (*uv_alloc_cb)(uv_handle_t* handle, size_t suggested_size);
typedef void (*uv_read_cb)(uv_stream_t* stream, ssize_t nread, uv_buf_t buf);





typedef void (*uv_read2_cb)(uv_pipe_t* pipe, ssize_t nread, uv_buf_t buf,
    uv_handle_type pending);
typedef void (*uv_write_cb)(uv_write_t* req, int status);
typedef void (*uv_connect_cb)(uv_connect_t* req, int status);
typedef void (*uv_shutdown_cb)(uv_shutdown_t* req, int status);
typedef void (*uv_connection_cb)(uv_stream_t* server, int status);
typedef void (*uv_close_cb)(uv_handle_t* handle);
typedef void (*uv_timer_cb)(uv_timer_t* handle, int status);

typedef void (*uv_async_cb)(uv_async_t* handle, int status);
typedef void (*uv_prepare_cb)(uv_prepare_t* handle, int status);
typedef void (*uv_check_cb)(uv_check_t* handle, int status);
typedef void (*uv_idle_cb)(uv_idle_t* handle, int status);
typedef void (*uv_getaddrinfo_cb)(uv_getaddrinfo_t* handle, int status,
    struct addrinfo* res);
typedef void (*uv_exit_cb)(uv_process_t*, int exit_status, int term_signal);
typedef void (*uv_fs_cb)(uv_fs_t* req);
typedef void (*uv_work_cb)(uv_work_t* req);
typedef void (*uv_after_work_cb)(uv_work_t* req);







typedef void (*uv_fs_event_cb)(uv_fs_event_t* handle, const char* filename,
    int events, int status);

typedef enum {
  UV_LEAVE_GROUP = 0,
  UV_JOIN_GROUP
} uv_membership;


struct uv_err_s {

  uv_err_code code;

  int sys_errno_;
};







 uv_err_t uv_last_error(uv_loop_t*);
 const char* uv_strerror(uv_err_t err);
 const char* uv_err_name(uv_err_t err);
struct uv_req_s {
  uv_req_type type; void* data;
};




 int uv_shutdown(uv_shutdown_t* req, uv_stream_t* handle,
    uv_shutdown_cb cb);

struct uv_shutdown_s {
  uv_req_type type; void* data;
  uv_stream_t* handle;
  uv_shutdown_cb cb;
 
};
struct uv_handle_s {
  uv_loop_t* loop; uv_handle_type type; uv_close_cb close_cb; void* data; int fd; int flags; ev_idle next_watcher;
};





 int uv_is_active(uv_handle_t* handle);
 void uv_close(uv_handle_t* handle, uv_close_cb close_cb);
 uv_buf_t uv_buf_init(char* base, size_t len);
struct uv_stream_s {
  uv_loop_t* loop; uv_handle_type type; uv_close_cb close_cb; void* data; int fd; int flags; ev_idle next_watcher;
  size_t write_queue_size; uv_alloc_cb alloc_cb; uv_read_cb read_cb; uv_read2_cb read2_cb; uv_connect_t *connect_req; uv_shutdown_t *shutdown_req; ev_io read_watcher; ev_io write_watcher; ngx_queue_t write_queue; ngx_queue_t write_completed_queue; int delayed_error; uv_connection_cb connection_cb; int accepted_fd; int blocking;
};

 int uv_listen(uv_stream_t* stream, int backlog, uv_connection_cb cb);
 int uv_accept(uv_stream_t* server, uv_stream_t* client);
 int uv_read_start(uv_stream_t*, uv_alloc_cb alloc_cb,
    uv_read_cb read_cb);

 int uv_read_stop(uv_stream_t*);





 int uv_read2_start(uv_stream_t*, uv_alloc_cb alloc_cb,
    uv_read2_cb read_cb);
 int uv_write(uv_write_t* req, uv_stream_t* handle,
    uv_buf_t bufs[], int bufcnt, uv_write_cb cb);

 int uv_write2(uv_write_t* req, uv_stream_t* handle, uv_buf_t bufs[],
    int bufcnt, uv_stream_t* send_handle, uv_write_cb cb);


struct uv_write_s {
  uv_req_type type; void* data;
  uv_write_cb cb;
  uv_stream_t* send_handle;
  uv_stream_t* handle;
  ngx_queue_t queue; int write_index; uv_buf_t* bufs; int bufcnt; int error; uv_buf_t bufsml[(4)];
};
struct uv_tcp_s {
  uv_loop_t* loop; uv_handle_type type; uv_close_cb close_cb; void* data; int fd; int flags; ev_idle next_watcher;
  size_t write_queue_size; uv_alloc_cb alloc_cb; uv_read_cb read_cb; uv_read2_cb read2_cb; uv_connect_t *connect_req; uv_shutdown_t *shutdown_req; ev_io read_watcher; ev_io write_watcher; ngx_queue_t write_queue; ngx_queue_t write_completed_queue; int delayed_error; uv_connection_cb connection_cb; int accepted_fd; int blocking;
 
};

 int uv_tcp_init(uv_loop_t*, uv_tcp_t* handle);


 int uv_tcp_nodelay(uv_tcp_t* handle, int enable);





 int uv_tcp_keepalive(uv_tcp_t* handle, int enable,
    unsigned int delay);

 int uv_tcp_bind(uv_tcp_t* handle, struct sockaddr_in);
 int uv_tcp_bind6(uv_tcp_t* handle, struct sockaddr_in6);
 int uv_tcp_getsockname(uv_tcp_t* handle, struct sockaddr* name,
    int* namelen);
 int uv_tcp_getpeername(uv_tcp_t* handle, struct sockaddr* name,
    int* namelen);







 int uv_tcp_connect(uv_connect_t* req, uv_tcp_t* handle,
    struct sockaddr_in address, uv_connect_cb cb);
 int uv_tcp_connect6(uv_connect_t* req, uv_tcp_t* handle,
    struct sockaddr_in6 address, uv_connect_cb cb);


struct uv_connect_s {
  uv_req_type type; void* data;
  uv_connect_cb cb;
  uv_stream_t* handle;
  ngx_queue_t queue;
};






enum uv_udp_flags {

  UV_UDP_IPV6ONLY = 1,




  UV_UDP_PARTIAL = 2
};





typedef void (*uv_udp_send_cb)(uv_udp_send_t* req, int status);
typedef void (*uv_udp_recv_cb)(uv_udp_t* handle, ssize_t nread, uv_buf_t buf,
    struct sockaddr* addr, unsigned flags);


struct uv_udp_s {
  uv_loop_t* loop; uv_handle_type type; uv_close_cb close_cb; void* data; int fd; int flags; ev_idle next_watcher;
  uv_alloc_cb alloc_cb; uv_udp_recv_cb recv_cb; ev_io read_watcher; ev_io write_watcher; ngx_queue_t write_queue; ngx_queue_t write_completed_queue;
};


struct uv_udp_send_s {
  uv_req_type type; void* data;
  uv_udp_t* handle;
  uv_udp_send_cb cb;
  ngx_queue_t queue; struct sockaddr_storage addr; socklen_t addrlen; uv_buf_t* bufs; int bufcnt; ssize_t status; uv_udp_send_cb send_cb; uv_buf_t bufsml[(4)];
};





 int uv_udp_init(uv_loop_t*, uv_udp_t* handle);
 int uv_udp_bind(uv_udp_t* handle, struct sockaddr_in addr,
    unsigned flags);
 int uv_udp_bind6(uv_udp_t* handle, struct sockaddr_in6 addr,
    unsigned flags);
 int uv_udp_getsockname(uv_udp_t* handle, struct sockaddr* name,
    int* namelen);
 int uv_udp_set_membership(uv_udp_t* handle,
    const char* multicast_addr, const char* interface_addr,
    uv_membership membership);
 int uv_udp_send(uv_udp_send_t* req, uv_udp_t* handle,
    uv_buf_t bufs[], int bufcnt, struct sockaddr_in addr,
    uv_udp_send_cb send_cb);
 int uv_udp_send6(uv_udp_send_t* req, uv_udp_t* handle,
    uv_buf_t bufs[], int bufcnt, struct sockaddr_in6 addr,
    uv_udp_send_cb send_cb);
 int uv_udp_recv_start(uv_udp_t* handle, uv_alloc_cb alloc_cb,
    uv_udp_recv_cb recv_cb);
 int uv_udp_recv_stop(uv_udp_t* handle);







struct uv_tty_s {
  uv_loop_t* loop; uv_handle_type type; uv_close_cb close_cb; void* data; int fd; int flags; ev_idle next_watcher;
  size_t write_queue_size; uv_alloc_cb alloc_cb; uv_read_cb read_cb; uv_read2_cb read2_cb; uv_connect_t *connect_req; uv_shutdown_t *shutdown_req; ev_io read_watcher; ev_io write_watcher; ngx_queue_t write_queue; ngx_queue_t write_completed_queue; int delayed_error; uv_connection_cb connection_cb; int accepted_fd; int blocking;
  struct termios orig_termios; int mode;
};
 int uv_tty_init(uv_loop_t*, uv_tty_t*, uv_file fd, int readable);




 int uv_tty_set_mode(uv_tty_t*, int mode);





 void uv_tty_reset_mode();




 int uv_tty_get_winsize(uv_tty_t*, int* width, int* height);







 uv_handle_type uv_guess_handle(uv_file file);







struct uv_pipe_s {
  uv_loop_t* loop; uv_handle_type type; uv_close_cb close_cb; void* data; int fd; int flags; ev_idle next_watcher;
  size_t write_queue_size; uv_alloc_cb alloc_cb; uv_read_cb read_cb; uv_read2_cb read2_cb; uv_connect_t *connect_req; uv_shutdown_t *shutdown_req; ev_io read_watcher; ev_io write_watcher; ngx_queue_t write_queue; ngx_queue_t write_completed_queue; int delayed_error; uv_connection_cb connection_cb; int accepted_fd; int blocking;
  const char* pipe_fname;
  int ipc;
};





 int uv_pipe_init(uv_loop_t*, uv_pipe_t* handle, int ipc);




 void uv_pipe_open(uv_pipe_t*, uv_file file);

 int uv_pipe_bind(uv_pipe_t* handle, const char* name);

 int uv_pipe_connect(uv_connect_t* req, uv_pipe_t* handle,
    const char* name, uv_connect_cb cb);
struct uv_prepare_s {
  uv_loop_t* loop; uv_handle_type type; uv_close_cb close_cb; void* data; int fd; int flags; ev_idle next_watcher;
  ev_prepare prepare_watcher; uv_prepare_cb prepare_cb;
};

 int uv_prepare_init(uv_loop_t*, uv_prepare_t* prepare);

 int uv_prepare_start(uv_prepare_t* prepare, uv_prepare_cb cb);

 int uv_prepare_stop(uv_prepare_t* prepare);
struct uv_check_s {
  uv_loop_t* loop; uv_handle_type type; uv_close_cb close_cb; void* data; int fd; int flags; ev_idle next_watcher;
  ev_check check_watcher; uv_check_cb check_cb;
};

 int uv_check_init(uv_loop_t*, uv_check_t* check);

 int uv_check_start(uv_check_t* check, uv_check_cb cb);

 int uv_check_stop(uv_check_t* check);
struct uv_idle_s {
  uv_loop_t* loop; uv_handle_type type; uv_close_cb close_cb; void* data; int fd; int flags; ev_idle next_watcher;
  ev_idle idle_watcher; uv_idle_cb idle_cb;
};

 int uv_idle_init(uv_loop_t*, uv_idle_t* idle);

 int uv_idle_start(uv_idle_t* idle, uv_idle_cb cb);

 int uv_idle_stop(uv_idle_t* idle);
struct uv_async_s {
  uv_loop_t* loop; uv_handle_type type; uv_close_cb close_cb; void* data; int fd; int flags; ev_idle next_watcher;
  ev_async async_watcher; uv_async_cb async_cb;
};

 int uv_async_init(uv_loop_t*, uv_async_t* async,
    uv_async_cb async_cb);






 int uv_async_send(uv_async_t* async);
struct uv_timer_s {
  uv_loop_t* loop; uv_handle_type type; uv_close_cb close_cb; void* data; int fd; int flags; ev_idle next_watcher;
  ev_timer timer_watcher; uv_timer_cb timer_cb;
};

 int uv_timer_init(uv_loop_t*, uv_timer_t* timer);

 int uv_timer_start(uv_timer_t* timer, uv_timer_cb cb,
    int64_t timeout, int64_t repeat);

 int uv_timer_stop(uv_timer_t* timer);






 int uv_timer_again(uv_timer_t* timer);







 void uv_timer_set_repeat(uv_timer_t* timer, int64_t repeat);

 int64_t uv_timer_get_repeat(uv_timer_t* timer);



 int uv_ares_init_options(uv_loop_t*,
    ares_channel *channelptr, struct ares_options *options, int optmask);


 void uv_ares_destroy(uv_loop_t*, ares_channel channel);







struct uv_getaddrinfo_s {
  uv_req_type type; void* data;

  uv_loop_t* loop;
  uv_getaddrinfo_cb cb; struct addrinfo* hints; char* hostname; char* service; struct addrinfo* res; int retcode;
};
 int uv_getaddrinfo(uv_loop_t*, uv_getaddrinfo_t* handle,
    uv_getaddrinfo_cb getaddrinfo_cb, const char* node, const char* service,
    const struct addrinfo* hints);

 void uv_freeaddrinfo(struct addrinfo* ai);


typedef struct uv_process_options_s {
  uv_exit_cb exit_cb;
  const char* file;






  char** args;




  char** env;




  char* cwd;




  int windows_verbatim_arguments;






  uv_pipe_t* stdin_stream;
  uv_pipe_t* stdout_stream;
  uv_pipe_t* stderr_stream;
} uv_process_options_t;




struct uv_process_s {
  uv_loop_t* loop; uv_handle_type type; uv_close_cb close_cb; void* data; int fd; int flags; ev_idle next_watcher;
  uv_exit_cb exit_cb;
  int pid;
  ev_child child_watcher;
};


 int uv_spawn(uv_loop_t*, uv_process_t*,
    uv_process_options_t options);





 int uv_process_kill(uv_process_t*, int signum);





struct uv_work_s {
  uv_req_type type; void* data;
  uv_loop_t* loop;
  uv_work_cb work_cb;
  uv_after_work_cb after_work_cb;
  eio_req* eio;
};


 int uv_queue_work(uv_loop_t* loop, uv_work_t* req,
    uv_work_cb work_cb, uv_after_work_cb after_work_cb);
typedef enum {
  UV_FS_UNKNOWN = -1,
  UV_FS_CUSTOM,
  UV_FS_OPEN,
  UV_FS_CLOSE,
  UV_FS_READ,
  UV_FS_WRITE,
  UV_FS_SENDFILE,
  UV_FS_STAT,
  UV_FS_LSTAT,
  UV_FS_FSTAT,
  UV_FS_FTRUNCATE,
  UV_FS_UTIME,
  UV_FS_FUTIME,
  UV_FS_CHMOD,
  UV_FS_FCHMOD,
  UV_FS_FSYNC,
  UV_FS_FDATASYNC,
  UV_FS_UNLINK,
  UV_FS_RMDIR,
  UV_FS_MKDIR,
  UV_FS_RENAME,
  UV_FS_READDIR,
  UV_FS_LINK,
  UV_FS_SYMLINK,
  UV_FS_READLINK,
  UV_FS_CHOWN,
  UV_FS_FCHOWN
} uv_fs_type;


struct uv_fs_s {
  uv_req_type type; void* data;
  uv_loop_t* loop;
  uv_fs_type fs_type;
  uv_fs_cb cb;
  ssize_t result;
  void* ptr;
  char* path;
  int errorno;
  struct stat statbuf; eio_req* eio;
};

 void uv_fs_req_cleanup(uv_fs_t* req);

 int uv_fs_close(uv_loop_t* loop, uv_fs_t* req, uv_file file,
    uv_fs_cb cb);

 int uv_fs_open(uv_loop_t* loop, uv_fs_t* req, const char* path,
    int flags, int mode, uv_fs_cb cb);

 int uv_fs_read(uv_loop_t* loop, uv_fs_t* req, uv_file file,
    void* buf, size_t length, off_t offset, uv_fs_cb cb);

 int uv_fs_unlink(uv_loop_t* loop, uv_fs_t* req, const char* path,
    uv_fs_cb cb);

 int uv_fs_write(uv_loop_t* loop, uv_fs_t* req, uv_file file,
    void* buf, size_t length, off_t offset, uv_fs_cb cb);

 int uv_fs_mkdir(uv_loop_t* loop, uv_fs_t* req, const char* path,
    int mode, uv_fs_cb cb);

 int uv_fs_rmdir(uv_loop_t* loop, uv_fs_t* req, const char* path,
    uv_fs_cb cb);

 int uv_fs_readdir(uv_loop_t* loop, uv_fs_t* req,
    const char* path, int flags, uv_fs_cb cb);

 int uv_fs_stat(uv_loop_t* loop, uv_fs_t* req, const char* path,
    uv_fs_cb cb);

 int uv_fs_fstat(uv_loop_t* loop, uv_fs_t* req, uv_file file,
    uv_fs_cb cb);

 int uv_fs_rename(uv_loop_t* loop, uv_fs_t* req, const char* path,
    const char* new_path, uv_fs_cb cb);

 int uv_fs_fsync(uv_loop_t* loop, uv_fs_t* req, uv_file file,
    uv_fs_cb cb);

 int uv_fs_fdatasync(uv_loop_t* loop, uv_fs_t* req, uv_file file,
    uv_fs_cb cb);

 int uv_fs_ftruncate(uv_loop_t* loop, uv_fs_t* req, uv_file file,
    off_t offset, uv_fs_cb cb);

 int uv_fs_sendfile(uv_loop_t* loop, uv_fs_t* req, uv_file out_fd,
    uv_file in_fd, off_t in_offset, size_t length, uv_fs_cb cb);

 int uv_fs_chmod(uv_loop_t* loop, uv_fs_t* req, const char* path,
    int mode, uv_fs_cb cb);

 int uv_fs_utime(uv_loop_t* loop, uv_fs_t* req, const char* path,
    double atime, double mtime, uv_fs_cb cb);

 int uv_fs_futime(uv_loop_t* loop, uv_fs_t* req, uv_file file,
    double atime, double mtime, uv_fs_cb cb);

 int uv_fs_lstat(uv_loop_t* loop, uv_fs_t* req, const char* path,
    uv_fs_cb cb);

 int uv_fs_link(uv_loop_t* loop, uv_fs_t* req, const char* path,
    const char* new_path, uv_fs_cb cb);







 int uv_fs_symlink(uv_loop_t* loop, uv_fs_t* req, const char* path,
    const char* new_path, int flags, uv_fs_cb cb);

 int uv_fs_readlink(uv_loop_t* loop, uv_fs_t* req, const char* path,
    uv_fs_cb cb);

 int uv_fs_fchmod(uv_loop_t* loop, uv_fs_t* req, uv_file file,
    int mode, uv_fs_cb cb);

 int uv_fs_chown(uv_loop_t* loop, uv_fs_t* req, const char* path,
    int uid, int gid, uv_fs_cb cb);

 int uv_fs_fchown(uv_loop_t* loop, uv_fs_t* req, uv_file file,
    int uid, int gid, uv_fs_cb cb);


enum uv_fs_event {
  UV_RENAME = 1,
  UV_CHANGE = 2
};


struct uv_fs_event_s {
  uv_loop_t* loop; uv_handle_type type; uv_close_cb close_cb; void* data; int fd; int flags; ev_idle next_watcher;
  char* filename;
  ev_io read_watcher; uv_fs_event_cb cb;
};







 void uv_loadavg(double avg[3]);






 int uv_fs_event_init(uv_loop_t* loop, uv_fs_event_t* handle,
    const char* filename, uv_fs_event_cb cb);




 struct sockaddr_in uv_ip4_addr(const char* ip, int port);
 struct sockaddr_in6 uv_ip6_addr(const char* ip, int port);


 int uv_ip4_name(struct sockaddr_in* src, char* dst, size_t size);
 int uv_ip6_name(struct sockaddr_in6* src, char* dst, size_t size);


 int uv_exepath(char* buffer, size_t* size);


 uint64_t uv_get_free_memory(void);
 uint64_t uv_get_total_memory(void);
 extern uint64_t uv_hrtime(void);






 uv_err_t uv_dlopen(const char* filename, uv_lib_t* library);
 uv_err_t uv_dlclose(uv_lib_t library);




 uv_err_t uv_dlsym(uv_lib_t library, const char* name, void** ptr);



union uv_any_handle {
  uv_tcp_t tcp;
  uv_pipe_t pipe;
  uv_prepare_t prepare;
  uv_check_t check;
  uv_idle_t idle;
  uv_async_t async;
  uv_timer_t timer;
  uv_getaddrinfo_t getaddrinfo;
  uv_fs_event_t fs_event;
};

union uv_any_req {
  uv_req_t req;
  uv_write_t write;
  uv_connect_t connect;
  uv_shutdown_t shutdown;
  uv_fs_t fs_req;
  uv_work_t work_req;
};


struct uv_counters_s {
  uint64_t eio_init;
  uint64_t req_init;
  uint64_t handle_init;
  uint64_t stream_init;
  uint64_t tcp_init;
  uint64_t udp_init;
  uint64_t pipe_init;
  uint64_t tty_init;
  uint64_t prepare_init;
  uint64_t check_init;
  uint64_t idle_init;
  uint64_t async_init;
  uint64_t timer_init;
  uint64_t process_init;
  uint64_t fs_event_init;
};


struct uv_loop_s {
  ares_channel channel; ev_timer timer; struct ev_loop* ev;

  uv_ares_task_t* uv_ares_handles_;

  uv_async_t uv_eio_want_poll_notifier;
  uv_async_t uv_eio_done_poll_notifier;
  uv_idle_t uv_eio_poller;

  uv_counters_t counters;

  uv_err_t last_err;

  void* data;
};
typedef struct http_parser http_parser;
typedef struct http_parser_settings http_parser_settings;
typedef struct http_parser_result http_parser_result;
typedef int (*http_data_cb) (http_parser*, const char *at, size_t length);
typedef int (*http_cb) (http_parser*);



enum http_method
  { HTTP_DELETE = 0
  , HTTP_GET
  , HTTP_HEAD
  , HTTP_POST
  , HTTP_PUT

  , HTTP_CONNECT
  , HTTP_OPTIONS
  , HTTP_TRACE

  , HTTP_COPY
  , HTTP_LOCK
  , HTTP_MKCOL
  , HTTP_MOVE
  , HTTP_PROPFIND
  , HTTP_PROPPATCH
  , HTTP_UNLOCK

  , HTTP_REPORT
  , HTTP_MKACTIVITY
  , HTTP_CHECKOUT
  , HTTP_MERGE

  , HTTP_MSEARCH
  , HTTP_NOTIFY
  , HTTP_SUBSCRIBE
  , HTTP_UNSUBSCRIBE

  , HTTP_PATCH
  };


enum http_parser_type { HTTP_REQUEST, HTTP_RESPONSE, HTTP_BOTH };



enum flags
  { F_CHUNKED = 1 << 0
  , F_CONNECTION_KEEP_ALIVE = 1 << 1
  , F_CONNECTION_CLOSE = 1 << 2
  , F_TRAILING = 1 << 3
  , F_UPGRADE = 1 << 4
  , F_SKIPBODY = 1 << 5
  };
enum http_errno {
  HPE_OK, HPE_CB_message_begin, HPE_CB_path, HPE_CB_query_string, HPE_CB_url, HPE_CB_fragment, HPE_CB_header_field, HPE_CB_header_value, HPE_CB_headers_complete, HPE_CB_body, HPE_CB_message_complete, HPE_INVALID_EOF_STATE, HPE_HEADER_OVERFLOW, HPE_CLOSED_CONNECTION, HPE_INVALID_VERSION, HPE_INVALID_STATUS, HPE_INVALID_METHOD, HPE_INVALID_URL, HPE_INVALID_HOST, HPE_INVALID_PORT, HPE_INVALID_PATH, HPE_INVALID_QUERY_STRING, HPE_INVALID_FRAGMENT, HPE_LF_EXPECTED, HPE_INVALID_HEADER_TOKEN, HPE_INVALID_CONTENT_LENGTH, HPE_INVALID_CHUNK_SIZE, HPE_INVALID_CONSTANT, HPE_INVALID_INTERNAL_STATE, HPE_STRICT, HPE_UNKNOWN,
};
struct http_parser {

  unsigned char type : 2;
  unsigned char flags : 6;
  unsigned char state;
  unsigned char header_state;
  unsigned char index;

  uint32_t nread;
  int64_t content_length;


  unsigned short http_major;
  unsigned short http_minor;
  unsigned short status_code;
  unsigned char method;
  unsigned char http_errno : 7;






  unsigned char upgrade : 1;






  void *data;
};


struct http_parser_settings {
  http_cb on_message_begin;
  http_data_cb on_url;
  http_data_cb on_header_field;
  http_data_cb on_header_value;
  http_cb on_headers_complete;
  http_data_cb on_body;
  http_cb on_message_complete;
};


void http_parser_init(http_parser *parser, enum http_parser_type type);


size_t http_parser_execute(http_parser *parser,
                           const http_parser_settings *settings,
                           const char *data,
                           size_t len);
int http_should_keep_alive(http_parser *parser);


const char *http_method_str(enum http_method m);


const char *http_errno_name(enum http_errno err);


const char *http_errno_description(enum http_errno err);
