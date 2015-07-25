title: This is this
date: 2015-07-25 00:06:19
categories:
  - JavaScript
tags:
  - JavaScript
  - this
thumbnailImage: http://www.weareey.com/oldsite/this-shit.gif
coverImage: cover-this.png
---
# this is thisgusting

물론 thisgusting이라는 단어는 없다. 그냥 역겨운이라는 뜻의 disgusting이라는 단어에서 따왔다.

Java에 익숙한 사람들에게 JavaScript에서의 **this**는.. 좀 그렇다..
이유는 Java에서의 this는 언제나 this가 사용된 함수를 멤버 메서드로 가지는 객체 자신을 의미하는데 비해,
**JavaScript에서의 this는 this가 사용된 함수의 호출 방식에 따라 그 때 그 때 달라요~** 이기 때문이다.

이미 this가 익숙한 사람들은 굳이 볼 필요 없고, this가 아직은 thisgusting하다고 생각하는 사람들에게는 조금이나마 도움이 될 것이다.


# 사자성어를 통해 배우는 this

일단 보는 사람들의 시간 절약을 위해 결론부터 풀어 놓는 것이 좋겠다.


### 원칙

> **this**의 값은 **this가 사용되고 있는 함수가 호출되는 방식에 따라 결정된다.**

그렇다면 함수가 호출되는 방식에는 어떤 것들이 있나?


### 세 가지 호출 방식

함수가 호출되는 방식은 여러 가지가 있지만 종합해보면 크게 세 가지로 나눌 수 있다.

> 1. 앞에 new를 붙여서 `new 함수()` 형식으로 호출
> 2. `객체.함수()` 형식으로 호출
> 3. `함수.call(객체, arg0, arg1, ...)` 또는 `함수.apply(객체, [arg0, arg2, ...])` 형식으로 호출


### 그래서 this는 뭘 가리킨다?

**this**는
> 1. `new` 로 생성되는 객체로 바인딩 된다.
> 2. `쩜(.)` 앞에 있는 객체로 바인딩 된다.
> 3. `call()`, `apply()`의 첫번째 인자로 바인딩 된다.


### 사자성어로 배워보는 this

세 가지를 좀 쉽게 외워보자. 예전에 학교 다닐 때 자주 쓰던 머리글자 따기로..

> `뉴쩜콜라` - new . call() apply()

**this**는 이 사자성어 `뉴쩜콜라`만 외우면 된다.

`뉴쩜콜라`,
`뉴쩜콜라`, `뉴쩜콜라`,
`뉴쩜콜라`, `뉴쩜콜라`, `뉴쩜콜라`,
`뉴쩜콜라`, `뉴쩜콜라`,
`뉴쩜콜라`,
`뉴쩜콜라`, `뉴쩜콜라`,
`뉴쩜콜라`, `뉴쩜콜라`, `뉴쩜콜라`,
`뉴쩜콜라`, `뉴쩜콜라`, `뉴쩜콜라`, `뉴쩜콜라`,
`뉴쩜콜라`, `뉴쩜콜라`, `뉴쩜콜라`,
`뉴쩜콜라`, `뉴쩜콜라`,
`뉴쩜콜라`,
`뉴쩜콜라`, `뉴쩜콜라`,
`뉴쩜콜라`, `뉴쩜콜라`, `뉴쩜콜라`,
`뉴쩜콜라`, `뉴쩜콜라`,
`뉴쩜콜라`,

오오~~ 뭔가 프랙탈스러운 것이 현란하기 짝이 없다.. 이 정도면 외워지겠지.

그럼 이제부터 `뉴쩜콜라`에 대해 차근차근 알아보자.

---

# 1. this는 new를 통해 생성되는 객체로 바인딩 된다.

Java에서는 `new 생성자()`의 형식으로 객체를 생성하고, `new 생성자()`는 새로 생성된 객체를 반환한다.
그리고 생성자 안에서 사용되는 **this**는 그 생성자에 의해 새로 생성될 객체를 가리킨다.

JavaScript에서도 마찬가지다. **생성자 함수 안에서 사용되는 this는 그 생성자 함수에 의해 생성되는 객체를 가리킨다.**

이 방식은 그리 낯설지 않으므로 긴 설명이 필요없다.

{% codeblock lang:javascript new 호출되는 함수 안의 this %}
function Country(name) {
    this.name = name;
}

var korea = new Country('대한민국');
var ukraine = new Country('우크라이나');

console.log(korea.name);    // 대한민국
console.log(ukraine.name);  // 우크라이나
{% endcodeblock %}

여담이지만 실제 객체 클래스나 객체 생성 메커니즘은 Java와 JavaScript가 같지 않지 않음에도 불구하고, 이질감을 줄이기 위해 Java의 문법을 그냥 그대로 쓸 수 있도록 가져왔다고 한다.

---

# 2. this는 쩜(.) 앞에 있는 객체로 바인딩 된다.

이 문장은 한 개 지만, 실제로는 4가지 호출 방식을 설명해 줄 수 있다.
하나하나 살펴보자.


### 2.1 객체 안에서 메서드로 사용된 함수 내의 this

Java에 익숙한 사람에게는 가장 직관적으로 이해할 수 있는 방식이다.

{% codeblock lang:javascript 객체의 메서드 안의 this %}
var obj = {
    prop1: 'objProp1',
    method1: function() {
        return this.prop1;
    }
}
var prop1 = 'globalProp1';

console.log(obj.method1());    // objProp1
{% endcodeblock %}

`method1`으로 참조되는 함수 안에서 사용된 **this**는 `method1`을 메서드로 가지는, 다시 말해, **쩜 앞에 있는 객체 `obj`를 가리킨다.**
따라서 `obj.method1() === obj.prop1`는 true.


### 2.2 쩜 없이도 호출할 수 있는 전역 함수 안의 this

쩜 앞에 있는 객체로 바인딩 된다는 얘기를 하면서 쩜 없이 호출한다니.. 뭔 소린가..

전역 스코프에서 선언된 전역 함수는 쩜 없이도 호출할 수 있다. 이 부분을 아주 정확히 설명하려면 조금 깊숙히 들어가서 `실행 컨텍스트(Execution Context)`라는 개념을 알아봐야하지만, 이 글은 **this**와 친해지는 것이 원래 목적이므로, 목적에 맞게 단순하게 설명하면 **전역 함수는 쩜 없이 호출해도 앞에 `global.`이 자동으로 붙는다**고 생각하면 된다. 다음의 코드를 보면 실제로도 그렇다는 걸 알 수 있다.

```javascript
function a() {
    console.log('a() === window.a()');
}

console.log(a === window.a);    // true
a();        // a() === window.a()
window.a(); // a() === window.a()
```

이렇게 생각하면 앞에서 설명한  `2.1 객체 안에서 메서드로 사용한 함수 내의 this`와 같은 맥락이다.

{% codeblock lang:javascript 전역 함수 안의 this %}
function globalFunc() {
    return this === window;
}

console.log(globalFunc());    // true
{% endcodeblock %}

**전역 함수 안의 this는 (생략되었지만 쩜 앞에 있는 객체인) 전역 객체를 가리킨다.**


### 2.3 prototype 객체의 메서드로 정의되는 함수 안의 this

`prototype` 자체도 조금 생소할 수 있고, 그래서 예제를 보면 더 복잡해 보이지만 맨 마지막 줄에 있는 호출 방식만 집중해서 보면 결국 `obj.funcName()`의 형식으로 호출 된다는 것을 알 수 있다. 따라서 **`prototype` 객체의 메서드로 정의되는 함수 안의 this 역시, 쩜 앞에 있는 객체를 가리킨다.**

{% codeblock lang:javascript prototype 객체의 메서드 안의 this %}
function Person(fullName) {
    this.fullName = fullName;
}

Person.prototype.getFullName = function() {
    return this.fullName;
}

var kim = new Person('Kim Tae Hee');
console.log(kim.getFullName());    // Kim Tae Hee
{% endcodeblock %}

**prototype 객체의 메서드로 정의된 getFullName 함수 안의 this는, getFullName를 호출할 때 앞에 있는 쩜 앞에 있는 객체를 가리킨다.**


### 2.4 함수 안에 중첩된 함수 안의 this

{% codeblock lang:javascript prototype 객체의 메서드 안의 this %}
var obj = {
    name: 'Plain Object',
    method1: function outerFunc() {
        console.log('in outerFunc, this : ', this);

        function innerFunc() {
            console.log('in innerFunc, this : ', this);

            function innerInnerFunc() {
                console.log('in innerInnerFunc, this : ', this);
            }
            innerInnerFunc();
        }
        innerFunc();
    }
}

obj.method1();
{% endcodeblock %}

`obj`라는 객체 안에 `method1`이라는 이름으로 `outerFunc` 함수를 정의했다. this가 여러번 쓰였는데 어찌 됐든 `obj` 객체 안에서 사용된 거니까 모두 `obj`를 가리키겠지..는 Java 스러운 생각이다. 앞에서 언급했듯이 **JavaScript에서의 this는 어디에서 사용되었느냐가 아니라 어떤 방식으로 호출되었느냐에 따라 값이 결정된다.**

출력 결과는 다음과 같다.

{% codeblock lang:javascript obj.method1() 출력 결과 %}

in outerFunc, this : Object {name: "Plain Object"}
in innerFunc, this : Window {top: Window, ...}
in innerInnerFunc, this : Window {top: Window, ...}
{% endcodeblock %}

먼저 `outerFunc`의 경우 Java스럽게 생각한 것과 똑같이 작동하므로 생략. 문제는 `innerFunc`와 `innerInnerFunc`가 왜 `obj`가 아니라 `window` 객체를 반환하느냐 인데, 이 역시도 호출 부분을 보면 이해할 수 있다.

둘 모두 `innerFunc()`, `innerInnerFunc()`와 같이 쩜도 없고 쩜 앞에도 아무것도 없이 마치 전역 함수를 호출하듯이 호출하고 있다. **즉, 생김새는 중첩 함수이지만, 호출 방식은 전역 함수 호출 방식과 같다.** this는 함수의 생김새가 아니라 호출 방식에 따라 결정되므로, **중첩 함수 안의 this는 전역 함수 호출할 때와 마찬가지로 전역 객체를 가리킨다.**

여기서 잠깐.
그렇다고 `innerFunc`와 `innerFunc`가 진짜 전역 함수처럼 전역 객체의 메서드로 정의되는거냐 하면 그건 또 아니다.

{% codeblock lang:javascript 중첩 함수는 전역 함수는 아니다 %}
console.log(window.innerFunc);       // undefined
console.log(window.innerInnferFunc); // undefined
{% endcodeblock %}

**중첩 함수는 전역 함수는 아니지만 전역 함수처럼 호출되므로 this에는 전역 객체가 바인딩 된다.**

---

# 3. this는 call(), apply()의 첫번째 인자로 바인딩 된다.

Java에서는 모든 함수가 어떤 객체의 메서드로 존재한다. 하지만 JavaScript에서는 함수 자체가 스스로 하나의 객체이며, 어떤 객체의 메서드가 아니라도 스스로 객체로서 존재할 수 있다.

따라서 JavaScript의 함수는 `객체A.함수B()`처럼 객체에 종속된 방식으로 호출되는 방식 말고도, `함수B.call(객체A)` 또는 `함수B.apply(객체A)` 같은 형식으로, 다시 말해 **객체의 메서드로서 호출되는 것이 아니라, 객체를 주입받는 형식으로도 호출될 수 있다.**

이렇게 호출되면 **this에는 call이나 apply의 첫번째 인자로 주입된 객체가 바인딩 된다.**
이 방식은 개념적으로는 이질감이 있어 금방 와 닿지 않지만, this에 무엇을 바인딩 할 지를 완전히 명시적으로 나타내기 때문에 this가 무엇을 가리키는 지 아는 것에만 집중한다면 쉽고 명백하며, 간편하기까지 하다.

참고로 call과 apply의 차이는 함수에 전달할 파라미터를 쉼표로 나열해서 전달하느냐, 배열로 묶어서 전달하느냐 밖에 없다.

{% codeblock lang:javascript call이나 apply로 호출되는 함수 안의 this %}
var plainObj = {};

var aFunction = function(param0, param1) {
    this.prop0 = param0;
    this.prop1 = param1;
}

aFunction.call(plainObj, '파라미터0', '파라미터1');

console.log(plainObj);
// Object {prop0: "파라미터0", prop1: "파라미터1"}
{% endcodeblock %}

**call이나 apply로 호출되는 함수의 this는, call이나 apply의 첫번째 인자로 주입된 객체를 가리킨다.**

---

# 정리

JavaScript의 **this**는 기초적인 내용이지만, 다른 데서 다른 방식으로 쓰고 있는 **this**에 익숙해져 있는 사람들에게는 대단히 불편한 걸림돌로 작용한다.

케이스별로 접근하면 머리에도 잘 안 들어오고, 그렇다보니 현업에서 늘 **this**를 애용하는 사람이 아니라면, 가끔 **this**를 접할 때마다 이게 도대체 뭘 가리키는 거냐.. 하면서 코드를 디스해버리고 싶은 마음이 샘솟는다.

앞으로 JavaScript의 **this**를 만나면 thisgusting하다면서 디스하지 말고 뭘 떠올린다?

`뉴쩜콜라`,
`뉴쩜콜라`, `뉴쩜콜라`,
`뉴쩜콜라`, `뉴쩜콜라`, `뉴쩜콜라`,
`뉴쩜콜라`, `뉴쩜콜라`,
`뉴쩜콜라`,
`뉴쩜콜라`, `뉴쩜콜라`,
`뉴쩜콜라`, `뉴쩜콜라`, `뉴쩜콜라`,
`뉴쩜콜라`, `뉴쩜콜라`, `뉴쩜콜라`, `뉴쩜콜라`,
`뉴쩜콜라`, `뉴쩜콜라`, `뉴쩜콜라`,
`뉴쩜콜라`, `뉴쩜콜라`,
`뉴쩜콜라`,
`뉴쩜콜라`, `뉴쩜콜라`,
`뉴쩜콜라`, `뉴쩜콜라`, `뉴쩜콜라`,
`뉴쩜콜라`, `뉴쩜콜라`,
`뉴쩜콜라`

오오~~ 다시 봐도 아득하고 현란하다.

**this는**
> **new 로 생성되는 객체로 바인딩 된다.**
> **쩜(.) 앞에 있는 객체로 바인딩 된다.**
> **call(), apply()의 첫번째 인자로 바인딩 된다.**


# 더 읽을거리

JavaScript Enlightenment - http://www.javascriptenlightenment.com/
MDN 문서 - https://developer.mozilla.org/ko/docs/Web/JavaScript/Reference/Operators/this
Nextree 블로그- http://www.nextree.co.kr/p7522/
