title: Spring에서 JSON에 XSS 방지 처리 하기
date: 2016-11-21 23:32:08
categories:
  - Technique
tags:
  - XSS
  - Spring
  - JSON
  - lucy-xss-servlet-filter
  - Cross Site Scripting
  - MessageConverter
  - 스프링
  - 보안
  - 크로스 사이트 스크립팅
thumbnailImage: http://3.bp.blogspot.com/-8YJnx44aAwY/UOMgSLC4m1I/AAAAAAAAAMg/oNY_An21FxU/s1600/XSS+Vulnerability+Tutorial+BreakTheSec.png
coverImage: coverImage-XSS-JSON-Spring.jpg
---

# Spring에서 JSON에 XSS 방지 처리 하기

## 고마운 lucy-xss-servlet-filter의 한계

XSS(Cross Site Scripting) 방지를 위해 널리 쓰이는 훌륭한 [lucy-xss-servlet-filter](https://github.com/naver/lucy-xss-servlet-filter)는 Servlet Filter 단에서 `<` 등의 특수 문자를 `&lt;` 등으로 변환해주며, 여러 가지 관련 설정을 편리하게 지정할 수 있어 정말 좋다.

그런데 그 처리가 **form-data에 대해서만 적용되고 Request Raw Body로 넘어가는 JSON에 대해서는 처리해주지 않는다**는 단점이 있다. 그래서 JSON을 주고 받는 API 서버의 경우에는 직접 처리를 해줘야 한다.

`lucy-xss-servlet-filter`를 수정해서 JSON도 처리하도록 만드는 방법도 있겠지만, 여기에서는 Response를 클라이언트로 내보내는 단계에서 처리하는 방법을 알아본다.


## HandlerInterceptor

Response 쪽에서 공통적으로 처리해줘야할 일이 있다면 금방 떠오르는 것이 `HanderInterceptor`의 `postHandle()`이다. 이 메서드의 파라미터는 `HttpServletRequest request`, `HttpServletResponse response`, `Object handler`, `ModelAndView modelAndView`이고, `response`에서 Response Body를 꺼내서, `<` => `&lt;` 등의 변환 처리를 하고 다시 `response`에 넣어주면 될 것 같다.

하지만 `response`에서 Response Body를 끄집어 내는 것도 쉽지 않고, 그 내용을 바꿔서 다시 집어넣는 것도 여의치 않다. 다른 방법이 필요하다.

## MessageConverter

다음으로 생각나는 것은 `MessageConverter`다. 어차피 결국에는 Jackson 같은 Mapper를 통해 JSON 문자열로 Response에 담겨지므로, **Mapper가 JSON 문자열을 생성할 때 XSS 방지 처리**를 해주면 될 것 같다.

찾아보니 역시나 http://stackoverflow.com/questions/25403676/initbinder-with-requestbody-escaping-xss-in-spring-3-2-4 이런 자료가 있다. 좀 오래된 버전이고 군더더기도 있어서 Jackson 2.#, SpringBoot 1.# 버전 기준으로 깔끔하게, 그리고 **커스터마이징 할 수 있는 부분을 추가**해서 정리해봤다.

큰 흐름은 다음과 같다.

>1. 처리할 특수 문자 지정
>1. 특수 문자 인코딩 값 지정
>1. ObjectMapper에 특수 문자 처리 기능 적용
>1. MessageConverter에 ObjectMapper 설정
>1. WebMvcConfigurerAdapter에 MessageConverter 추가

### 처리할 특수 문자 지정

XSS 방지 처리할 특수 문자를 다음과 같이 `CharacterEscapes`를 상속한 클래스를 직접 만들어서 지정해준다.

```java
import com.fasterxml.jackson.core.SerializableString;
import com.fasterxml.jackson.core.io.CharacterEscapes;
import com.fasterxml.jackson.core.io.SerializedString;
import org.apache.commons.lang3.text.translate.AggregateTranslator;
import org.apache.commons.lang3.text.translate.CharSequenceTranslator;
import org.apache.commons.lang3.text.translate.EntityArrays;
import org.apache.commons.lang3.text.translate.LookupTranslator;

public class HTMLCharacterEscapes extends CharacterEscapes {

    private final int[] asciiEscapes;

    private final CharSequenceTranslator translator;

    public HTMLCharacterEscapes() {

        // 1. XSS 방지 처리할 특수 문자 지정
        asciiEscapes = CharacterEscapes.standardAsciiEscapesForJSON();
        asciiEscapes['<'] = CharacterEscapes.ESCAPE_CUSTOM;
        asciiEscapes['>'] = CharacterEscapes.ESCAPE_CUSTOM;
        asciiEscapes['&'] = CharacterEscapes.ESCAPE_CUSTOM;
        asciiEscapes['\"'] = CharacterEscapes.ESCAPE_CUSTOM;
        asciiEscapes['('] = CharacterEscapes.ESCAPE_CUSTOM;
        asciiEscapes[')'] = CharacterEscapes.ESCAPE_CUSTOM;
        asciiEscapes['#'] = CharacterEscapes.ESCAPE_CUSTOM;
        asciiEscapes['\''] = CharacterEscapes.ESCAPE_CUSTOM;

        // 2. XSS 방지 처리 특수 문자 인코딩 값 지정
        translator = new AggregateTranslator(
            new LookupTranslator(EntityArrays.BASIC_ESCAPE()),  // <, >, &, " 는 여기에 포함됨
            new LookupTranslator(EntityArrays.ISO8859_1_ESCAPE()),
            new LookupTranslator(EntityArrays.HTML40_EXTENDED_ESCAPE()),
            // 여기에서 커스터마이징 가능
            new LookupTranslator(
                new String[][]{
                    {"(",  "&#40;"},
                    {")",  "&#41;"},
                    {"#",  "&#35;"},
                    {"\'", "&#39;"}
                }
            )
        );
    }

    @Override
    public int[] getEscapeCodesForAscii() {
        return asciiEscapes;
    }

    @Override
    public SerializableString getEscapeSequence(int ch) {
        return new SerializedString(translator.translate(Character.toString((char) ch)));

        // 참고 - 커스터마이징이 필요없다면 아래와 같이 Apache Commons Lang3에서 제공하는 메서드를 써도 된다.
        // return new SerializedString(StringEscapeUtils.escapeHtml4(Character.toString((char) ch)));
    }
}

```

### ObjectMapper에 특수 문자 처리 기능 적용 후 MessageConverter 등록

```java
@Bean
public WebMvcConfigurerAdapter controlTowerWebConfigurerAdapter() {
    return new WebMvcConfigurerAdapter() {

        @Override
        public void configureMessageConverters(List<HttpMessageConverter<?>> converters) {
            super.configureMessageConverters(converters);

            // 5. WebMvcConfigurerAdapter에 MessageConverter 추가
            converters.add(htmlEscapingConveter());
        }

        private HttpMessageConverter<?> htmlEscapingConveter() {
            ObjectMapper objectMapper = new ObjectMapper();
            // 3. ObjectMapper에 특수 문자 처리 기능 적용
            objectMapper.getFactory().setCharacterEscapes(new HTMLCharacterEscapes());

            // 4. MessageConverter에 ObjectMapper 설정
            MappingJackson2HttpMessageConverter htmlEscapingConverter =
                    new MappingJackson2HttpMessageConverter();
            htmlEscapingConverter.setObjectMapper(objectMapper);

            return htmlEscapingConverter;
        }
    };
}
```

## 정리

>`lucy-xss-servlet-filter`는 JSON에 대한 XSS는 처리해주지 않는다.
>
>- 따라서, JSON에 대한 XSS가 필요하다면
>- Jackson의 `com.fasterxml.jackson.core.io.CharacterEscapes`를 상속하는 클래스 A를 직접 만들어서 처리해야 할 특수문자를 지정하고,
>- `ObjectMapper`에 `A`를 설정하고,
>- `ObjectMapper`를 MessageConverter에 등록해서 Response가 클라이언트에 나가기 전에 XSS 방지 처리 해준다.

