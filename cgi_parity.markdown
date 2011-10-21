# CGi Parity

We need to make sure that all features provided by these CGI variables are available to HTTP response handlers

## Server specific variables:

 - `SERVER_SOFTWARE` — name/version of HTTP server.
   process.server_software = "Luvit"
   process.version = "v0.1.0"

 - `SERVER_NAME` — host name of the server, may be dot-decimal IP address.
   depends on which interface the server is bound to and from who's point of view.
   ???  This is very useful though.  The "Host" header in the request usually has this too

 - `GATEWAY_INTERFACE` — CGI/version.
   not needed, this is not CGI

## Request specific variables:

 - `SERVER_PROTOCOL` — HTTP/version.
   `req.version_major`, `req.version_minor`

 - `SERVER_PORT` — TCP port (decimal).
   ?

 - `REQUEST_METHOD` — name of HTTP method (see above).
   req.method

 - `PATH_INFO` — path suffix, if appended to URL after program name and a slash.

 - `PATH_TRANSLATED` — corresponding full path as supposed by server, if `PATH_INFO` is present.

 - `SCRIPT_NAME` — relative path to the program, like /cgi-bin/script.cgi.

 - `QUERY_STRING` — the part of URL after ? character. May be composed of *name=value pairs separated with ampersands (such as var1=val1&var2=val2…) when used to submit form data transferred via GET method as defined by HTML `application/x-www-form-urlencoded`.

 - `REMOTE_HOST` — host name of the client, unset if server did not perform such lookup.
   will not implement, use dns library on request:getpeername().address

 - `REMOTE_ADDR` — IP address of the client (dot-decimal).
   request:getpeername().address

 - `AUTH_TYPE` — identification type, if applicable.

 - `REMOTE_USER` used for certain `AUTH_TYPE`s.

 - `REMOTE_IDENT` — see ident, only if server performed such lookup.

 - `CONTENT_TYPE` — MIME type of input data if PUT or POST method are used, as provided via HTTP header.
   NA, see headers

 - `CONTENT_LENGTH` — similarly, size of input data (decimal, in octets) if provided via HTTP header.
   NA, see headers

 - Variables passed by user agent (`HTTP_ACCEPT`, `HTTP_ACCEPT_LANGUAGE`, `HTTP_USER_AGENT`, `HTTP_COOKIE` and possibly others) contain values of corresponding HTTP headers and therefore have the same sense.
   req.headers
