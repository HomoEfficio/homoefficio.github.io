title: HexoTest
date: 2015-07-12 14:54:29
tags:
  - Hexo
  - Blog
thumbnailImage: https://pbs.twimg.com/profile_images/476729162707644418/mQZOTo9f.png
---
# Hexo 첫 블로깅

원래 연초에 블로그나 하나 해보기로 맘먹고는 `Octopress`에 만들었었다.

{% link Octopress-블로그 http://hanmomhanda.github.io/blog/2015/01/04/octopress-github-blog-01/ %}

허나 다음과 같이 몇가지 이유가 있어서 `Octopress` 블로그에 `Octopress`의 사용법만 올려놓고는 사실상 안 썼다.

- `Octopress`를 사용해봤는데 아래 그림에서처럼 말머리표가 삐져나오는 것이 싫었다.

    {% asset_img octopress-글머리표삐져나옴.png %}

- 약간 복잡하다.

- 게을렀다.

`Hexo`는 여러가지 테스트해보니 다음과 같은 점이 괜찮았다.

- 일단 말머리표 삐져나옴이 없다.

- Code Snippet이 비교적 이쁘게 렌더링 된다.

- `asset_folder`를 이용한 이미지 첨부에 조금 애를 먹기는 했지만 전반적으로 `Octopress`에 비해 사용하기 쉬운 편이다.

테마를 찾아보니 대부분(최소 80% 이상) 중국 개발자들이 만든 걸로 봐서 중국에서 많이 쓰는 모양이다.
`Hueman`이라는 나름 깔쌈한 테마도 있고 해서 Hexo로 결정! 하려다가 `Hueman`은 들여쓰기가 적용되지 않아 더 나은 `Tranquilpeak`라는 테마로 결정.


## Quote 테스트

인용은 그냥 많이 쓰는 Github Markdown에서 하는 그대로 렌더링 했으면 좋았을텐데..
난데 없는 가운데 정렬에 좌측에 수직 막대가 없어서 모양새가 영 별로.. 였으나!
`Tranquilpeak`에서는 잘 나온다. 다만 수직 막대가 너무 얇은게 아쉽다.

- 마크다운 인용

> 이것은 마크다운 인용입니다.

- hexo blockquote

{% blockquote %}
이것은 hexo 기본 인용입니다.
{% endblockquote %}

- hexo blockquote from a book

    {% blockquote 저자이름, 책이름 %}
    이것은 hexo 책 인용입니다.
    {% endblockquote %}

- hexo blockquote from a twit

    {% blockquote @DevDocs https://twitter.com/devdocs/status/356095192085962752 %}
    트윗 가져오기 http://hanmomhanda.github.io
    {% endblockquote %}

- hexo blockquote from a link

    {% blockquote hanmomhanda https://github.com/hanmomhanda/WebGL-Study WebGL 기초 %}
    `mat#()`나 `vec#()`와 같은 셰이더의 함수를 통해 행렬이나 벡터를 구성하는 방법은 다르다!!
    {% endblockquote %}

## Code Block

### 마크다운 기본

``` java
public class TestClass {
    public static void main(String[] args) {
        System.out.println("Hello Hexo");
    }
}
```

- 마크다운 들여쓰기

    - 들여쓰기

        ``` java
        public class TestClass {
            public static void main(String[] args) {
                System.out.println("Hello Hexo");
            }
        }
        ```

- 마크다운 들여쓰기 버그?

    ``` java
    public class TestClass {
        public static void main(String[] args) {
            System.out.println("Hello Hexo");
        }
    }
    ```

    - 1단계 들여쓰기

        ``` java
        public class TestClass {
            public static void main(String[] args) {
                System.out.println("Hello Hexo");
            }
        }
        ```

        - 2단계 들여쓰기

            ``` java
            public class TestClass {
                public static void main(String[] args) {
                    System.out.println("Hello Hexo");
                }
            }
            ```

들여쓰기를 해도 코드 블록에는 들여쓰기가 제대로 안 먹고 다 같은 들여쓰기 수준인 것처럼 렌더링 된다. 나중에 테스트 해보니 이건 테마 문제인 듯.. 기본 테마인 `landscape`에서는 들여쓰기가 수준이 작성한대로 렌더링 되는데, `hueman` 테마에서는 들여쓰기가 먹지 않는다.

하지만, `Tranquilpeak`에서는 잘 먹는다.

### Hexo

{% codeblock lang:java %}
public class TestClass {
    public static void main(String[] args) {
        System.out.println("Hello Hexo");
    }
}
{% endcodeblock %}

- Hexo 들여쓰기

    - 들여쓰기

        {% codeblock lang:java %}
        public class TestClass {
            public static void main(String[] args) {
                System.out.println("Hello Hexo");
            }
        }
        {% endcodeblock %}

들여쓰기를 해도 코드 블록에는 들여쓰기가 제대로 안 먹고 다 같은 들여쓰기 수준인 것처럼 렌더링 된다. 나중에 테스트 해보니 이건 테마 문제인 듯.. 기본 테마인 `landscape`에서는 들여쓰기가 수준이 작성한대로 렌더링 되는데, `hueman` 테마에서는 들여쓰기가 먹지 않는다.

하지만, `Tranquilpeak`에서는 잘 먹는다.

- Hexo 코드 블록 캡션

    - 아래와 같이 캡션을 줄 수도 있고

        {% codeblock lang:java TestClass.java %}
        public class TestClass {
            public static void main(String[] args) {
                System.out.println("Hello Hexo");
            }
        }
        {% endcodeblock %}

- Hexo 코드 블록 캡션과 URL

    - 캡션과 URL을 함께 줄수도 있다.

        {% codeblock _.compact http://underscorejs.org/#compact Underscore.js %}
        _.compact([0, 1, false, 2, '', 3]);
        => [1, 2, 3]
        {% endcodeblock %}

## Pull Quote

- 풀 쿼트는 뭔가

    {% pullquote 오명운 오명운의 무엇 %}
    이것 저것
    this and that
    {% endpullquote %}

## jsFiddle

- 별거 다 되네

    {% jsfiddle hanmomhanda/9rGjP %}

## Gist

- Gist 까정.. 근데 살짝 이상하네.. ㅋㅋ

    {% gist hanmomhanda/6361207 %}

## IFrame

- 오홋 iframe 도

    {% iframe http://hanmomhanda.github.io/WebGL-Study/src/03-playground/Dragging-a-Regular-Polygon.html %}

## Image

- 이미지

    {% img https://avatars1.githubusercontent.com/u/355249?v=3&s=460 %}

## Link

- 그냥 텍스트

    https://github.com/hanmomhanda

- 마크다운 링크

    [한몸한다 깃허브](https://github.com/hanmomhanda)

- Hexo 링크

    {% link Hexo-링크 https://github.com/hanmomhanda external 제목 %}

## Include Code

- 파일 전체 코드 가져오기 - 이건 잘 안되네.

    {% include_code 헬로-Hexo lang:html Include_code_test.html %}


## video

비디오도 비교적 쉽게 가져올 수 있다.

- Youtube

    {% youtube y8MrCD1-0FY %}

- Vimeo

    {% vimeo 132695239 %}

## Include Posts

- 다른 포스트 가져오기

    이건 그냥 링크만 가져오는건가..

    {% post_link hello-world 헬로-Hexo %}

# 결론

- Node.js 환경도 생소하지만, Ruby on Rails 환경보다는 덜 생소하다.
- 넘쳐나는 중국산 테마를 제끼고 {% link Tranquilpeak https://github.com/LouisBarranqueiro/tranquilpeak-hexo-theme %}라는 괜찮은 테마를 찾았다.
- Node.js 환경도 Sass 환경도 잘 모르는 상태에서 폰트 바꾸기는 좀 어려웠다.
- 폰트 바꾸면서 커스터마이징 감을 잡았으니 맘에 안 드는 건 바꿔가면서 잘 쓰자. ^^