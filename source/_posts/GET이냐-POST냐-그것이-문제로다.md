title: GET이냐 POST냐 그것이 문제로다
date: 2019-12-25 12:04:39
categories:
  - Concepts
tags:
  - HTTP
  - HTTP API
  - HTTP Method
  - Safe Method
  - Idempotence
  - GET
  - POST
  - Information Hiding
  - 정보 숨김
  - 정보 감춤
  - 멱등  
thumbnailImage: https://i.imgur.com/EDxqw7u.jpg
coverImage: coverImage-get-or-post.jpg
---
# GET이냐 POST냐 그것이 문제로다

며칠 전에 [페이스북에 올렸던 질문](https://www.facebook.com/hanmomhanda/posts/10221495156952479)에 여러분께서 시간 내서 좋은 의견 나눠주셔서, 나만 꿀꺽하고 넘어가면 도리가 아닌 것 같아 다시 정리해본다.

먼저 이 글은 **나름의 결론이 있기는 하지만, 그것이 정답이라고 단정할 수는 없다.**  
또한 REST와는 아무런 관계가 없으며, 오직 HTTP Method에 대한 얘기다.

# 문제

보통 클라이언트 쪽에서 Contents를 제공하면서 새로운 Resource의 생성을 요청할 때는, 그 Contents를 포함시켜서 POST로 요청을 보내면 된다. 여기에는 별다른 이견이 없다.

그런데 클라이언트 쪽에서 아무런 Contents를 제공하지 않으면서, 그저 서버로부터 어떤 Resource를 반환받으려 하는데, 실제로 서버에서는 새 Resource를 생성해서 반환해야 하는 경우라면, GET을 써야 하나 아니면 POST를 써야 하나?

예를 들어 클라이언트가 아무 내용 없이 그냥 '퀴즈를 내다오'라고 서버에게 요청하면,  
즉, 반환되는 퀴즈가 새로 만든 건지 기존에 만들어져 있던 걸 반환하는지 클라이언트는 관심 가질 필요가 없는 상황이라면,

- GET .../quizzes/new 로 보낸다. (GET이지만 서버는 알아서 새 퀴즈를 생성해서 반환)
- POST (내용없이) .../quizzes 로 보낸다. (POST지만 서버는 새로 생성된 퀴즈를 반환)

GET, POST 둘 중 어느 쪽이 더 환영받는 방법인가? 또는 어느 쪽이 욕을 덜 먹는 방법인가? 또는 다른 더 나은 방안이 있다면 어떤게 있을까?

의견을 모아서 정리해봤다. 거의 원문에 가깝고 괄호 안은 임의로 추가.

# POST라는 의견

>멱등성이 유지될 수 있으면 GET, 없으면 POST 라는 기본 전제를 두고 생각합니다. 그래서 (새 퀴즈가 생성된다면 멱등이 아니므로) POST로 할 것 같습니다.

>명시적으로 URI는 자원에 대한 것이어야 하는데 없는 자원을 내놓으라면 404를 반환하는 게 맞을 것 같습니다. (새 자원을 만들어 반환해야 하므로 POST로 할 것 같습니다.)

>디비 상태에 변화를 주는 건 GET을 쓰지 않고 있어요. GET을 사용할 때는 순수함수처럼 같은 인풋은 같은 아웃풋을 내줘야 한다고 생각합니다.

>http 1.0이후 생겨난 POST, PUT, DELETE...는 서버 내에 있는 자원에 관련된 조작이기 때문에 전 DB의 변화가 있으면 무조건 상태 변경과 관련된 메서드를 사용합니다.(리소스란 측면에서 DB는 일부...) http 프로토콜에서 method 영역을 클라이언트 입장이냐 서버 입장이냐로 다들 관점이 다르게 바라볼수 있겠지만 http 역사를 생각해보면 메서드는 자원과 관련이 크고 자원을 소유한 서버측 관점에 무게를 싣고 있습니다.

>POST로 하고 생성된 자원에 대한 GET 경로를 Location 헤더에 넣어서 201로 응답하는 게 맞을 것 같습니다.

# GET이라는 의견

>클라이언트는 퀴즈를 원할 뿐 새로 생성되든 기존에 있던 거든 신경 쓸필요가 없다고 하니, 조회의 의미만 존재한다고 생각해요.

>클라이언트는 이게 새로 만들어진건지 기존에 있던건지 모르지만 일단 원하는 행위가 퀴즈라는 것을 얻기 위함이기에 GET 이 맞는거 같습니다.  
>빵집을 예로 들어 빵을 산다라는 행위에서 이게 기존에 만들어진것을 사가든 주문과 동시에 만들어진 빵을 사가든 같은 행위지만(GET)  
>이런 빵을 사가려는데 만들어주세요 혹은 이런빵을 만들어주시면 사러 가겠습니다 (POST)는 다른 목적이고 빵집에서도 이에 따라 다른 행동을 취해야 하니까요

# 둘 다 아니라는 의견

>API는 행위 중심이어야지 상태 중심이면 안 된다는 것이 OOP와 DDD를 통한 배움이었습니다.


# 중간 정리

이 말도 맞는 것 같고 저 말도 맞는 것 같고, 멱등성(idempotence)이라는 어려운 용어도 나오고 아 현기증나..

하지만 정신차리고 추려보면 결국 아래와 같이 요약할 수 있다.

>- 요청자인 클라이언트의 의도를 중요하게 보는 입장에서는 GET을 선호  
>- HTTP는 결국 자원을 다루는 것이므로 자원을 중요하게 보는 입장에서는 POST를 선호

# 스펙은 뭐라더냐?

이쯤되면 그다지 보고 싶지 않은 스펙을 보지 않을 수 없다. 관련 스펙은 [Hypertext Transfer Protocol (HTTP/1.1): Semantics and Content](https://tools.ietf.org/html/rfc7231)이며 그 중에서 HTTP Method 관련 내용은 [여기](https://tools.ietf.org/html/rfc7231#section-4)에 있다.

POST를 지지하는 의견은 한 마디로 요약하면 다음과 같다.

>자원 변경이 수반되면 POST여야 한다.

그런데 정말 스펙에서도 '자원 변경이 수반되면 POST여야 한다'고 규정하고 있을까?

## Safe Methods

스펙 내용 중에 [Safe Methods](https://tools.ietf.org/html/rfc7231#section-4.2.1) 라는 단원이 있다.

>Request methods are considered "safe" if their defined semantics are  
>essentially read-only; i.e., the client does not request, and does  
>not expect, any state change on the origin server as a result of  
>applying a safe method to a target resource.  Likewise, reasonable  
>use of a safe method is not expected to cause any harm, loss of  
>property, or unusual burden on the origin server.

짧게 옮겨 보면 다음과 같다.

>클라이언트가 서버 상태의 변경을 요청하지도, 기대하지도 않는 읽기 전용 요청은 Safe하다고 볼 수 있다. 그래서 Safe Method를 바르게 사용하면 서버에게 어떤 해악이나 손실, 일반적이지 않은 부담을 발생시키지 않는다.

여기까지만 보면 자원 변경이 수반되면 GET을 쓰면 안 될 것 같다.

그런데 바로 다음 문단에는 살짝 결이 다른 내용이 나온다.

>This definition of safe methods does not prevent an implementation
>from including behavior that is potentially harmful, that is not
>entirely read-only, or that causes side effects while invoking a safe
>method.  What is important, however, is that the client did not
>request that additional behavior and cannot be held accountable for
>it.  For example, most servers append request information to access
>log files at the completion of every response, regardless of the
>method, and that is considered safe even though the log storage might
>become full and crash the server.  Likewise, a safe request initiated
>by selecting an advertisement on the Web will often have the side
>effect of charging an advertising account.

역시나 짧게 옮겨 보면,

>**Safe Method라고해서 사이드 이펙트나 잠재적으로 해가 될 수 있는 동작을 포함해서 구현하는 것을 배제하지는 않는다. 중요한 것은 그 동작을 클라이언트가 요청한 게 아니라는 점이고, 그 동작에 대한 책임을 클라이언트가 부담하지 않는다는 점이다.** 예를 들어 서버는 (Safe든 아니든) 메서드 종류에 관계 없이 모든 요청에 대해 액세스 로그를 기록하는데, 액세스 로그로 하드가 꽉 차서 서버가 깨질 수도 있지만, (로그 기록은 클라이언트가 요청한 것이 아니므로) 이런 호출도 Safe하다고 본다.(이하 광고 사례 생략)

이 외에도 GET, POST를 직접적으로 설명하는 부분도 있지만, 이 글 내용에 크게 영향을 미치는 내용은 없어 보여서 굳이 다루지 않는다.

# 그래서 결론은?

앞에서도 말했지만 이 글은 나름의 주관적인 결론은 있지만 그게 정답은 아니다.

이미 꽤 길어졌으니 결론부터 말하면 **GET을 써도 좋겠다**이다.

이유는,
- API라는 게 결국 쌍방간의 계약이고,  
- 클라이언트는 본질적으로 어떤 자원을 얻기를 바랄 뿐 굳이 자원 생성 여부를 알 필요가 없다면,  
- 즉, 클라이언트의 본질적인 요구가 '생성'이 아니라 '획득'이라면,  
- 클라이언트의 요청 처리 내부 과정에 '생성'이라는 비멱등 과정이 포함된다고 하더라도,  
- 서버의 처리 과정보다는 클라이언트의 '획득'이라는 요구 본질에 무게를 두어도,
- 스펙에 어긋남이 없기 때문이다.

게다가 다음 같은 상황을 가정해보면 GET을 써도 좋겠다 정도가 아니라 **GET이 더 낫다**라는 생각도 든다.

퀴즈를 처음에는 클라이언트 요청에 그때그때 생성해서 반환하기로 하고 이건 자원 생성을 유발하니 POST로 하자.. 로 시작했는데,
나중에 퀴즈 서비스가 흥해서 클라이언트가 엄청 많아지고 성능이든 뭐든 여타 이유로 '가만 퀴즈를 꼭 생성해서 반환할 필요 없지 않아? 미리 왕창 만들어 놓고 임의로 걍 조회만 해서 반환하는 게 나을 것 같은데?'라는 판단이 든다. 그럼 이제 자원 생성이 발생하지 않으므로 GET을 써야 한다.

클라이언트의 요구는 '퀴즈의 획득'으로 변한 게 없는데, 서버의 처리 과정이 신규 자원 생성에서 기존 자원 조회로 바뀌었다고 해서 API를 POST에서 GET으로 바꿔야되나? 수많은 클라이언트에게 GET으로 바꿔달라고 모두 설득할 수 있나?

애초에 자원 생성과 무관하게 오로지 '획득'이었던 클라이언트의 요청 본질에 충실하게 GET으로 시작했다면 이런 큰 변경을 피할 수 있었을 것이다.

이렇게 보면 HTTP Method의 사용에서도 '비멱등이면 POST'와 같은 원칙보다는, Information Hiding(정보 감춤/숨김) 같은 더 일반적인 상위 차원의 설계 원칙이 유연한 시스템을 구축하는 데 더 중요한 것 같다.
