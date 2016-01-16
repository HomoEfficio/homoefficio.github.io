title: JavaScript 식별자 찾기 대모험
date: 2016-01-16 21:22:14
categories:
  - JavaScript
tags:
  - JavaScript
  - 자바스크립트
  - Scope Chain
  - 스코프 체인
  - Prototype Chain
  - 프로토타입 체인
  - JavaScript internal  
  - ES6
thumbnailImage: https://camo.githubusercontent.com/e1a1948f0bcfa095d54793afd3ab96af97731773/687474703a2f2f64336a732e6f72672f65782f636c75737465722e706e67
coverImage: cover-static-analysis.png

---
# Quiz

아래 코드를 실행하면 1이 출력된다.

```javascript
function f1() {
    console.log(a);
}
Object.prototype.a = 1;
f1();
```
왜 그럴까?
얼핏 생각하면 금방 답이 나오지만, 조금 더 생각해보면 아래와 같은 질문이 떠오른다.

>**변수 찾으려면 스코프 체인을 뒤지고 없으면 에러를 내야지, 왜 프로토타입 체인까지 뒤지는걸까?**
 

# 스코프 체인

스코프 체인(Scope Chain)은 식별자 중에서도 어떤 객체(전역 객체가 아닌)의 속성(propety)이 아닌 식별자를 찾아내는 메커니즘이다. 코드를 보는게 더 금방 감이 올 것이다.

```javascript
function A() {
    var a = 1;
    function B() {
        function C() {
            // 함수 C 안에서 a를 선언한 적이 없지만,
            // 스코프 체인을 따라 위로 찾아 올라가서, 
            // 함수 A 안에서 선언된 a에 접근할 수 있다.
            console.log(a);  // 1이 출력된다.
        }
        C();
    }
    B();
}
A();        
```
스코프 체인은 주로 함수의 중첩 및 변수와 관련이 있다고 볼 수 있다.

# 프로토타입 체인
  
프로토타입 체인(Prototype Chain)은 식별자 중에서도 어떤 객체의 속성(property)을 찾아내는 메커니즘이다. 역시 코드를 보자.

```javascript
var obj = {
    prop1: 'value1',
    prop2: 'value2'
};
// obj에 hasOwnProperty라는 메서드를 정의한 적 없지만,
// 프로토타입 체인을 따라 상속 체계 위로 찾아 올라가서,
// Object.prototype.hasOwnProperty에 접근할 수 있다. 
console.log(obj.hasOwnProperty('prop1'));  // true 가 출력된다.
```
프로토타입 체인은 주로 객체의 상속 및 속성과 관련이 있다고 볼 수 있다.

# 둘의 관계

스코프 체인은 주로 함수의 중첩 및 변수와 관련이 있고, 프로토타입 체인은 주로 객체의 상속 및 속성과 관련이 있으니, 둘은 뭔가 위로 찾아간다는 공통점이 있다는 것 외에는 다루는 대상이 확연히 달라서 별로 관계가 없을 것 같다.

하지만 둘은 **식별자를 찾기 위해 함께 협업하는 관계**다. 위의 두 예제를 섞어보자.

```javascript
function A() {
    var a = {
        prop1: 'value1',
        prop2: 'value2'
    };
    function B() {
        function C() {
            console.log(a.hasOwnProperty('prop1'));  // true 출력
            console.log(a['hasOwnProperty']('prop1'));  // true 출력
        }
        C();
    }
    B();
}
A();  
```
`a`를 찾을 때까지는 스코프 체인이 사용되고, `a`를 찾은 후 `a.hasOwnProperty`나 `a['hasOwnProperty']`와 같이 `.`이나 `[]`를 이용해서 속성을 찾을 때는 프로토타입 체인이 사용된다.

그럼 스코프 체인에서 `a`를 못찾으면 어떻게 될까?

```javascript
function A() {
    function B() {
        function C() {
            console.log(a.hasOwnProperty('prop1'));  // true 출력
            console.log(a['hasOwnProperty']('prop1'));  // true 출력
        }
        C();
    }
    B();
}
A();  
// Uncaught ReferenceError: a is not defined(…)
```
에러가 발생한다. **스코프 체인에서 식별자를 찾지 못하면, 그 다음의 프로토타입 체인은 작동하지 못한다.**

# 퀴즈 다시 보기

```javascript
function f1() {
    console.log(a);
}
Object.prototype.a = 1;
f1();
```
`a`는 전역 공간에서조차 선언한 적이 없다. 즉, 스코프 체인에 없다. 그럼 위에서 본 것처럼 스코프 체인에서 식별자를 찾지 못하면, 프로토타입 체인이 작동하지 못하고 에러가 발생해야 되는 것 아닌가? 그런데 왜 에러가 발생하지 않고 Object.prototype에 정의한 값이 찍히는걸까?

# 스코프 체인 들여다보기

이제부터 ES6 스펙 속으로 들어가보자.

흔히 스코프 체인이라고 하는 것은 ES3에서는 스펙에 정식으로 존재했던 용어인데, ES6에서는 스코프 체인이라는 용어는 존재하지 않는다. 정식 용어라고까지 할 수는 없겠지만, ES6에서는 스코프 체인 대신에 Lexical nesting이라는 표현을 쓴다. 체인 보다는 중첩에 더 의미를 두려는 것 같다. 어차피 정식 용어가 없으므로 여기서는 편의상 스코프 체인이라는 용어를 그대로 쓰기로 한다.

스코프 체인은 `Lexical Environment`를 원소로 하는 단방향 링크드 리스트다. 아래의 그림에서 파란색 선으로 이어진 것이 스코프 체인이다.

![](http://i.imgur.com/n4nqzCd.png)

스코프 체인의 원소인 `Lexical Environment`는 함수 선언, 블록문, catch절 같은 코드가 평가될 때 생성된다. 이 중에서 함수로 대상을 좁혀보면, 함수가 호출될 때 생성되는 것이 아니라, 그에 앞서 함수 선언 코드가 평가될 때 `Lexical Environment`가 생성된다는 점을 기억하자. 바로 이 점이 `closure`가 성립할 수 있는 열쇠다. 

`Lexical Environment`는 `environment record`와 `outer`를 포함하고 있다. 
`environment record`는 `Environment Record`객체를 가리키는데 이는 ES3에서의 변수 객체(Variable Object)와 비슷하다. `HasBinding`이라는 추상 메서드를 가지고 있다는 점을 기억해두자.
`outer`는 자신을 감싸고 있는, 즉, 중첩 구조에서 상위에 있는 다른 `Lexical Environment`를 가리킨다. 이 `outer`를 통해 스코프 체인이 형성된다. 스코프 체인은 `outer` 값이 `null`로 설정되는 `Global Environment`를 만날때까지 이어진다.


## 식별자를 찾는 과정 - 1
 
이제 식별자 찾기가 스코프 체인 내에서 구체적으로 어떻게 동작하는지 알아보자.

어떤 함수 내에서 식별자를 찾는 일은 그 함수가 호출되어 실행될 때 일어나는 일이다. 그리고 함수가 호출되면 실행 컨텍스트(Execution Context)가 생성된다는 것은 ES3에서와 같다. 따라서 식별자를 찾는 일은 실행 컨텍스트가 존재하는 상황에서 수행된다.

`v1`이라는 식별자를 찾으려면 가장 먼저 `ResolveBinding('v1', [env])`와 같은 형식([env]는 배열을 의미하는 것이 아니라 옵션임을 의미)으로 `ResolveBinding` 함수가 호출되는데, 이 함수는 현재 실행 컨텍스트에 있는 `Lexical Environment`에서 `v1`이라는 식별자를 찾는다.

`ResolveBinding`은 내부적으로 `GetIdentifierReference(env, 'v1', strict)`와 같은 형식으로 `GetIdentifierReference` 함수를 호출하고, 이 함수가 반환하는 값을 결과값으로 반환한다.(스펙 8.3.1)

`GetIdentifierReference`는 인자로 받은 `env`가 null이면, 즉, `global environment`까지 뒤졌는데도 찾지 못하면 ReferenceError를 유발하게 하는 참조값을 반환한다. 
`env`가 null이 아니면 `env`의 environment record(줄여서 `envRec`라 한다)의 메서드인 `HasBinding`을 `envRec.HasBinding('v1')`와 같은 형식으로 호출한다. `envRec.HasBinding('v1')`은 `envRec` 내에 `v1`이 있는지 확인해서 있으면 true를 반환하고 `v1`에 해당하는 참조(Reference)를 반환한다. `envRec.HasBinding('v1')`가 false를 반환하면 `GetIdentifierReference(env.outer, 'v1', strict)`와 같은 형식으로 `outer`를 인자로 해서 재귀 호출하는 방식으로 스코프 체인을 따라 올라가면서 계속 `env.HasBinding('v1')`을 실행한다.(스펙 8.1.2.1)

여기까지 슈도 코드로 정리해보면 아래와 같다.

```javascript
ResolveBinding('v1', env)    
    return GetIdentifierReference(env, 'v1', strict)

GetIdentifierReference(env, 'v1', strict)
    if (env == null)
        return referenceToTriggerReferenceError
    exist = env.envRec.HasBinding('v1')
    if (exist == true)
        return referenceToV1
    GetIdentifierReference(env.outer, 'v1', strict)
```  
중첩 함수들 사이에서의 식별자 찾기는 여기까지의 과정에서 모두 찾아진다. 이제 중첩 함수의 범위를 넘어서 스코프 체인의 마지막인 `Global Environment`에 도달했을때 어떤 일이 벌어지는지 알아보자.

## 식별자를 찾는 과정 - 2

사실 앞에서 보여준 스코프 체인 그림에는 잘못된 점이 하나 있다. 바로 `Global Environment`의 `environment record`가 가리키는 부분이다. 올바르게 그리면 아래와 같다.

![](http://i.imgur.com/Ittr4GG.png)

`Global Environment Record`에서의 식별자 찾기 함수 호출 내용을 알아보기 전에, 먼저 `Global Environment Record`의 구성 요소를 먼저 알아보자.

### Declarative Environment Record

- `Declarative Environment Record`는 ECMAScript 언어로 표현되는 값들과 식별자를 직접적으로 연결해주는 함수 선언, 변수 선언, catch절과 같은 문법 요소의 효과를 정의하기 위해 사용된다. 
- 쉽게 말하면 함수 선언, 변수 선언, catch절에서 사용되는 식별자 정보를 가지고 있다고 보면 된다.
- `Declarative Environment Record`도 `HasBinding` 메서드를 가지고 있다.
- `Global Environment Record`에 있는 `declarative Environment Record`는 `Declarative Environment Record`의 인스턴스다.

### Object Environment Record

- `Object Environment Record`는 with문과 같이 식별자를 어떤 특정 객체 A의 속성으로 취급할 때 사용되며, 이를 위해 `binding object`라는 속성으로 A를 가리킨다.
- 쉽게 말하면 with문의 효과를 정의하기 위해 사용된다.
- `Object Environment Record`도 `HasBinding` 메서드를 가지고 있다.
- `Object Environment Record`의 `HasBinding` 메서드는 내부적으로 `HasProperty(binding_object, id)`와 같은 형식으로 `HasProperty` 함수를 호출한다.
    - **`HasProperty` 함수는 프로토타입 체인을 뒤져서 식별자를 찾아낸다. 바로 이 함수가 문제 해결의 실마리를 가지고 있다!!**
- `Global Environment Record`에 있는 `object Environment Record`는 `Object Environment Record`의 인스턴스다.

### Global Environment Record의 object Environment Record

- `object Environment Record`(소문자 object로 시작하는 것은 Global Environment Record의 object Environment Record를 의미)는 `binding object`가 전역 객체를 가리킨다. 
- 따라서 일반적인 `Object Environment Record`와는 다르게 Object, Array, Function, parseInt, Infinity 같은 모든 built-in global과 전역 코드에서의 함수 선언, 제너레이터 선언, 변수 선언에 의해 생성된 모든 식별자 정보를 `binding object`를 통해 찾을 수 있다. 
- `binding object`가 전역 객체를 가리키는 바람에, `declarative Environment Record`와 역할이 바뀐 것 같은 모양새가 되었다.

### Global Environment Record의 declarative Environment Record 

- `declarative Environment Record`(소문자 declarative로 시작하는 것은 Global Environment Record의 declarative Environment Record를 의미)도 일반적인 `Declarative Environment Record`와 다르게 전역 코드에서 `object Environment Record`에 포함되지 않은 식별자 정보만 보유한다. 
- `Declarative Environment Record`의 역할을 `object Environment Record`가 가져가버렸기 때문에 역할이 바뀐 것 같은 모양새가 되었다.

### Global Environment와 꼬붕들

식별자를 찾다가 스코프 체인의 끝인  `Global Environment`에 도달했을때 식별자를 찾는데 동원되는 꼬붕들은 다음과 같다. 

![](http://i.imgur.com/9MnRZsT.png)

전역 객체까지 나오니 이제 좀 실마리가 보이는 것도 같다.

- `Global Environment`에서 `Global Environment Record`를 통해 식별자를 찾으면, 
- 결국 `object Environment Record`에서 찾게 되고, 
- 결국 `binding object`가 가리키는 전역 객체에서 찾게 된다.

### 식별자를 찾는 함수 호출 과정

이제 앞의 '식별자를 찾는 함수 호출 과정 - 1'에서 정리했던 슈도 코드에 `Global Environment`에 관한 내용을 추가해보자.

```javascript
ResolveBinding('v1', env)    
    return GetIdentifierReference(env, 'v1', strict)

GetIdentifierReference(env, 'v1', strict)
    if (env == null)
        return referenceToTriggerReferenceError
    exist = env.envRec.HasBinding('v1')  // 여기에서 env가 `Global Environment`일때 아래 '여기부터 추가'로 이동
    if (exist == true)
        return referenceToV1
    GetIdentifierReference(env.outer, 'v1', strict)

//여기부터 추가
// 스펙 8.1.1.4.1
globalEnv.globalEnvRec.HasBinding('v1')
    if (declarativeEnvRec.HasBinding('v1'))
        return true
    return objectEnvRec.HasBinding('v1')

// 스펙 8.1.1.2.1
objectEnvRec.HasBinding('v1')
    return HasProperty(global_object, 'v1')
    // 원래 objectEnvRec는 with문 관련 처리 내용이 있으나
    // 여기에서는 생략

// 스펙 7.3.10
HasProperty(global_object, 'v1')
    global_object.HasProperty('v1')

// 스펙 9.1.7, 9.1.7.1
global_object.HasProperty('v1')
    global_object의 프로토타입 체인을 뒤져서 찾아서 있으면 true, 없으면 false 반환
```

# 결론

스코프 체인을 뒤지다가 왜 프로토타입 체인까지 뒤지는가? 에 대한 결론은 다음과 같다.

> - **스코프 체인을 뒤지다가 안 나오면 전역 객체에서 찾게 되고,** 
> - **전역 객체에서 찾을 때는 프로토타입 체인이 동원 된다.**

아, 아직 완전히 끝은 아니다. 전역 객체의 프로토타입 체인에 Object.prototype가 반드시 존재해야 하는가?

# 전역 객체의 [[Prototype]]

전역 객체의 [[Prototype]]은 스펙에서 정한 내용이 없고, ECMAScript 구현체에 달려있다고 명시되어 있다.(스펙 18)

구현체를 확인해보면,

- 크롬

    ![](http://i.imgur.com/hidyqCU.png)

    전역 객체의 증조 할아버지가 Object.prototype이다.

- node.js

    ![](http://i.imgur.com/kH311d9.png)
    ![](http://i.imgur.com/xDbqxBw.png)
 
    node.js에서는 전역 객체의 할아버지가 Object.prototype이다.

# 정리

>- 스코프 체인과 프로토타입 체인은 식별자를 찾기 위해 협업하는 관계다.
>- 식별자를 찾을 때는 먼저 스코프 체인을 따라서 찾고,
>    - 식별자와 바인딩 된 값이 객체라면,
>        - 그 객체의 프로토타입 체인을 따라서 속성을 찾는다.
>- 스코프 체인에서 식별자를 찾지 못하면, 전역 객체에서 찾게 되고,
>- 전역 객체에서 찾을 때는 프로토타입 체인이 동원된다.

어쩌다보니 스펙을 파고 결론까지 찾아내기는 했지만,
그다지 직접적인 쓸모는 별로 없는 뻘짓인 것 같다.. ㅠㅜ

하지만, ES6의 Execution Context, Lexical Environment, Global Object와 여러가지 Environment Record의 관계를 한 번 훑어봤다는 점에 나름 의미를 두기로..
