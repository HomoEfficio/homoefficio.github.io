title: Cross Origin Resource Sharing - CORS
date: 2015-07-21 00:09:44
categories:
  - Network
tags:
  - CORS
  - AJAX
  - Same Origin Policy
thumbnailImage: http://bowdenweb.com/wp/i/cors/cors-mountain-02.png
coverImage: cover-cors.png
---
# 개요

HTTP 요청은 기본적으로 Cross-Site HTTP Requests가 가능하다.

다시 말하면, `<img>` 태그로 다른 도메인의 이미지 파일을 가져오거나, `<link>` 태그로 다른 도메인의 CSS를 가져오거나, `<script>` 태그로 다른 도메인의 JavaScript 라이브러리를 가져오는 것이 모두 가능하다.

하지만 `<script></script>`로 둘러싸여 있는 **스크립트**에서 생성된 Cross-Site HTTP Requests는 [**Same Origin Policy**](https://developer.mozilla.org/ko/docs/Web/Security/Same-origin_policy)를 적용 받기 때문에 Cross-Site HTTP Requests가 불가능하다.

AJAX가 널리 사용되면서 `<script></script>`로 둘러싸여 있는 스크립트에서 생성되는 `XMLHttpRequest`에 대해서도 Cross-Site HTTP Requests가 가능해야 한다는 요구가 늘어나자 W3C에서 CORS라는 이름의 권고안이 나오게 되었다.

# CORS 요청의 종류

CORS 요청은 Simple/Preflight, Credential/Non-Credential의 조합으로 4가지가 존재한다.

브라우저가 요청 내용을 분석하여 4가지 방식 중 해당하는 방식으로 서버에 요청을 날리므로, 프로그래머가 목적에 맞는 방식을 선택하고 그 조건에 맞게 코딩해야 한다.


### Simple Request

아래의 3가지 조건을 모두 만족하면 Simple Request


- GET, HEAD, POST 중의 한 가지 방식을 사용해야 한다.
- POST 방식일 경우 Content-type이 아래 셋 중의 하나여야 한다.
    - application/x-www-form-urlencoded
    - multipart/form-data
    - text/plain
- 커스텀 헤더를 전송하지 말아야 한다.

Simple Request는 서버에 1번 요청하고, 서버도 1번 회신하는 것으로 처리가 종료된다.

{% codeblock lang:http Simple Request %}
GET /resources/public-data/ HTTP/1.1
Host: bar.other
User-Agent: Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; en-US; rv:1.9.1b3pre) Gecko/20081130 Minefield/3.1b3pre
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
Accept-Language: en-us,en;q=0.5
Accept-Encoding: gzip,deflate
Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7
Connection: keep-alive
Referer: http://foo.example/examples/access-control/simpleXSInvocation.html
Origin: http://foo.example


HTTP/1.1 200 OK
Date: Mon, 01 Dec 2008 00:23:53 GMT
Server: Apache/2.0.61
Access-Control-Allow-Origin: *
Keep-Alive: timeout=2, max=100
Connection: Keep-Alive
Transfer-Encoding: chunked
Content-Type: application/xml

[XML Data]
{% endcodeblock %}


### Preflight Request

Simple Request 조건에 해당하지 않으면 브라우저는 Preflight Request 방식으로 요청한다.

따라서, Preflight Request는

- GET, HEAD, POST 외의 다른 방식으로도 요청을 보낼 수 있고,
- application/xml 처럼 다른 Content-type으로 요청을 보낼 수도 있으며,
- 커스텀 헤더도 사용할 수 있다.

이름에서 짐작할 수 있듯, Preflight Request는 예비 요청과 본 요청으로 나뉘어 전송된다.

먼저 서버에 예비 요청(Preflight Request)를 보내고 서버는 예비 요청에 대해 응답하고,
그 다음에 본 요청(Actual Request)을 서버에 보내고, 서버도 본 요청에 응답한다.

**하지만, 예비 요청과 본 요청에 대한 서버단의 응답을 프로그래머가 프로그램 내에서 구분하여 처리하는 것은 아니다.**
프로그래머가 **`Access-Control-`** 계열의 Response Header만 적절히 정해주면,
OPTIONS 요청으로 오는 예비 요청과 GET, POST, HEAD, PUT, DELETE 등으로 오는 본 요청의 처리는 서버가 알아서 처리한다.

아래는 Preflight Requests로 오가는 HEADER를 보여준다.

**다시 강조하지만, 아래 내용에서 프로그래머가 OPTIONS 요청의 처리 로직과 POST 요청의 처리 로직을 구분하여 구현하는 것이 아니다.**


{% codeblock lang:http Preflight Request and Actual Request %}
OPTIONS /resources/post-here/ HTTP/1.1
Host: bar.other
User-Agent: Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; en-US; rv:1.9.1b3pre) Gecko/20081130 Minefield/3.1b3pre
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
Accept-Language: en-us,en;q=0.5
Accept-Encoding: gzip,deflate
Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7
Connection: keep-alive
Origin: http://foo.example
Access-Control-Request-Method: POST
Access-Control-Request-Headers: X-PINGOTHER


HTTP/1.1 200 OK
Date: Mon, 01 Dec 2008 01:15:39 GMT
Server: Apache/2.0.61 (Unix)
Access-Control-Allow-Origin: http://foo.example
Access-Control-Allow-Methods: POST, GET, OPTIONS
Access-Control-Allow-Headers: X-PINGOTHER
Access-Control-Max-Age: 1728000
Vary: Accept-Encoding
Content-Encoding: gzip
Content-Length: 0
Keep-Alive: timeout=2, max=100
Connection: Keep-Alive
Content-Type: text/plain

POST /resources/post-here/ HTTP/1.1
Host: bar.other
User-Agent: Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; en-US; rv:1.9.1b3pre) Gecko/20081130 Minefield/3.1b3pre
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
Accept-Language: en-us,en;q=0.5
Accept-Encoding: gzip,deflate
Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7
Connection: keep-alive
X-PINGOTHER: pingpong
Content-Type: text/xml; charset=UTF-8
Referer: http://foo.example/examples/preflightInvocation.html
Content-Length: 55
Origin: http://foo.example
Pragma: no-cache
Cache-Control: no-cache

<?xml version="1.0"?><person><name>Arun</name></person>


HTTP/1.1 200 OK
Date: Mon, 01 Dec 2008 01:15:40 GMT
Server: Apache/2.0.61 (Unix)
Access-Control-Allow-Origin: http://foo.example
Vary: Accept-Encoding
Content-Encoding: gzip
Content-Length: 235
Keep-Alive: timeout=2, max=99
Connection: Keep-Alive
Content-Type: text/plain

[Some GZIP'd payload]
{% endcodeblock %}


### Request with Credential

HTTP Cookie와 HTTP Authentication 정보를 인식할 수 있게 해주는 요청

{% codeblock lang:javascript Simple Credential Request %}
var invocation = new XMLHttpRequest();
var url = 'http://bar.other/resources/credentialed-content/';

function callOtherDomain(){

  if(invocation) {
    invocation.open('GET', url, true);
    invocation.withCredentials = true;
    invocation.onreadystatechange = handler;
    invocation.send();
  }
  ...
{% endcodeblock %}

요청 시 **`xhr.withCredentials = true`**를 지정해서 Credential 요청을 보낼 수 있고,
서버는 Response Header에 반드시 **`Access-Control-Allow-Credentials: true`**를 포함해야 하고,
**`Access-Control-Allow-Origin`** 헤더의 값에는 **`*`**가 오면 안되고 `http://foo.origin`과 같은 구체적인 도메인이 와야 한다.

{% codeblock lang:http Server Response Header to Simple Request with Credential %}
HTTP/1.1 200 OK
Date: Mon, 01 Dec 2008 01:34:52 GMT
Server: Apache/2.0.61 (Unix) PHP/4.4.7 mod_ssl/2.0.61 OpenSSL/0.9.7e mod_fastcgi/2.4.2 DAV/2 SVN/1.4.2
X-Powered-By: PHP/5.2.6
Access-Control-Allow-Origin: http://foo.example
Access-Control-Allow-Credentials: true
Cache-Control: no-cache
Pragma: no-cache
Set-Cookie: pageAccess=3; expires=Wed, 31-Dec-2008 01:34:53 GMT
Vary: Accept-Encoding
Content-Encoding: gzip
Content-Length: 106
Keep-Alive: timeout=2, max=100
Connection: Keep-Alive
Content-Type: text/plain


[text/plain payload]
{% endcodeblock %}


### Request without Credential

CORS 요청은 기본적으로 Non-Credential 요청이므로,  **`xhr.withCredentials = true`**를 지정하지 않으면 Non-Credential 요청이다.


# CORS 관련 HTTP Response Headers

서버에서 CORS 요청을 처리할 때 지정하는 헤더

### Access-Control-Allow-Origin

Access-Control-Allow-Origin 헤더의 값으로 지정된 도메인으로부터의 요청만 서버의 리소스에 접근할 수 있게 한다.

{% codeblock lang:http Response Header %}
Access-Control-Allow-Origin: <origin> | *
{% endcodeblock %}

`<origin>`에는 요청 도메인의 URI를 지정한다.
모든 도메인으로부터의 서버 리소스 접근을 허용하려면 `*`를 지정한다. Request with Credential의 경우에는 `*`를 사용할 수 없다.

### Access-Control-Expose-Headers

기본적으로 브라우저에게 노출이 되지 않지만, 브라우저 측에서 접근할 수 있게 허용해주는 헤더를 지정한다.

기본적으로 브라우저에게 노출이 되는 HTTP Response Header는 아래의 6가지 밖에 없다.

- Cache-Control
- Content-Language
- Content-Type
- Expires
- Last-Modified
- Pragma

다음과 같이 `Access-Control-Expose-Headers`를 Response Header에 지정하여 회신하면 브라우저 측에서 커스텀 헤더를 포함하여, 기본적으로는 접근할 수 없었던 Content-Length 헤더 정보도 알 수 있게 된다.
{% codeblock lang:http Response Header %}
Access-Control-Expose-Headers: Content-Length, X-My-Custom-Header, X-Another-Custom-Header
{% endcodeblock %}




### Access-Control-Max-Age

Preflight Request의 결과가 캐쉬에 얼마나 오래동안 남아있는지를 나타낸다.

{% codeblock lang:http Response Header %}
Access-Control-Max-Age: <delta-seconds>
{% endcodeblock %}


### Access-Control-Allow-Credentials

Request with Credential 방식이 사용될 수 있는지를 지정한다.

{% codeblock lang:http Response Header %}
Access-Control-Allow-Credentials: true | false
{% endcodeblock %}

예비 요청에 대한 응답에 `Access-Control-Allow-Credentials: false`를 포함하면, 본 요청은 Request with Credential을 보낼 수 없다.

Simple Request에 `withCredentials = true`가 지정되어 있는데, Response Header에 `Access-Control-Allow-Credentials: true`가 명시되어 있지 않다면, 그 Response는 브라우저에 의해 무시된다.


### Access-Control-Allow-Methods

예비 요청에 대한 Response Header에 사용되며, 서버의 리소스에 접근할 수 있는 HTTP Method 방식을 지정한다.

{% codeblock lang:http Response Header %}
Access-Control-Allow-Methods: <method>[, <method>]*
{% endcodeblock %}


### Access-Control-Allow-Headers

예비 요청에 대한 Response Header에 사용되며, 본 요청에서 사용할 수 있는 HTTP Header를 지정한다.

{% codeblock lang:http Response Header %}
Access-Control-Allow-Headers: <field-name>[, <field-name>]*
{% endcodeblock %}



# CORS 관련 HTTP Request Headers

클라이언트가 서버에 CORS 요청을 보낼 때 사용하는 헤더로, 브라우저가 자동으로 지정하며, XMLHttpRequest를 사용하는 프로그래머가 직접 지정해 줄 필요 없다.


### Origin

Cross-site 요청을 날리는 요청 도메인 URI을 나타내며, access control이 적용되는 모든 요청에 `Origin` 헤더는 반드시 포함된다.

{% codeblock lang:http Request Header %}
Origin: <origin>
{% endcodeblock %}

`<origin>`은 서버 이름(포트 포함)만 포함되며 경로 정보는 포함되지 않는다.

`<origin>`은 공백일 수도 있는데, 소스가 data URL일 경우에 유용하다.


### Access-Control-Request-Method

예비 요청을 보낼 때 포함되어, 본 요청에서 어떤 HTTP Method를 사용할 지 서버에게 알려준다.

{% codeblock lang:http Request Header %}
Access-Control-Request-Method: <method>
{% endcodeblock %}


### Access-Control-Request-Headers

예비 요청을 보낼 때 포함되어, 본 요청에서 어떤 HTTP Header를 사용할 지 서버에게 알려준다.

{% codeblock lang:http Request Header %}
Access-Control-Request-Headers: <field-name>[, <field-name>]*
{% endcodeblock %}


# XDomainRequest

`XDomainRequest`(XDR)는 W3C 표준이 아니며, IE 8, 9에서 비동기 CORS 통신을 위해 Microsoft에서 만든 객체다.

- XDR은 `setRequestHeader`가 없다.
- XDR과 XHR을 구분하려면 `obj.contentType`을 사용한다.(XHR에는 이게 없음)
- XDR은 http와 https 프로토콜만 가능


# 결론

- CORS를 쓰면 AJAX를 통해서도 다른 도메인의 자원을 사용할 수 있다.
- CORS를 사용하려면
    - 클라이언트에서 `Access-Control-**` 류의 HTTP Header를 서버에 보내야 하고,
    - 서버도 `Access-Control-**` 류의 HTTP Header를 클라이언트에 회신해야 한다.


# 참고 자료

- http://www.w3.org/TR/cors/
- https://developer.mozilla.org/en-US/docs/Web/HTTP/Access_control_CORS
