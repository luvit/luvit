return {

response = ([[
HTTP/1.1 200 OK
Content-Type: text/plain
Content-Length: 13

hello world
]]):gsub("\n", "\r\n"),

request = ([[
POST /documentation/apache/ HTTP/1.0
Connection: Keep-Alive
User-Agent: Mozilla/4.01 [en] (Win95; I)
Host: hal.etc.com.au
Accept: image/gif, image/x-xbitmap, image/jpeg, image/pjpeg, */*
Accept-Language: en
Accept-Charset: iso-8859-1,*,utf-8
Content-Length: 13

Hello World
]]):gsub("\n","\r\n")

}
