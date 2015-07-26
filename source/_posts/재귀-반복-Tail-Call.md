title: 재귀 반복 Tail Call
date: 2015-07-27 03:07:51
categories:
  - Algorithm
tags:
  - Fibonacci
  - Recursion
  - Iteration
  - Tail Call
  - Tail Recursion
  - 피보나치
  - 재귀
  - 반복
  - 꼬리 호출
  - 꼬리 재귀 호출
thumbnailImage:
coverImage:

---

# fibonacci(피보나치) 수열

잘 알려져 있듯 피보나치 수열은 다음과 같다.

```
0, 1, 1, 2, 3, 5, 8, 13, 21, 34, ...
```

프로그래밍과는 관련 없는 얘기를 살짝 하자면, 이 수열의 이름은 본명은 Leonardo da Pisa이지만 fibonacci로 알려진 12세기 이탈리아 수학자의 이름을 따서 지어졌는데, 사실 이 수열을 가장 먼저 언급한 사람, 즉 가장 먼저 발견한 사람은 피보나치가 아니라 핑갈라라고 하는 기원전 4세기 또는 2세기로 추정되는 인물이라고 한다. [위키 참고](https://en.wikipedia.org/wiki/Fibonacci_number)

암튼 피보나치 수열은 다음과 같이 정의된다.

![](https://upload.wikimedia.org/math/b/e/1/be15d40af5bc02d538b8d9ea7d49d909.png)

위 식의 가장 아래줄을 보면 n번째 피보나치 수열의 숫자를 구하는 방법을 알 수 있다.

위 식을 그대로 JavaScript로 구현하면 다음과 같다.

{% codeblock lang:javascript fibonacci 수를 구하는 가장 직관적인 구현 %}
// n이 음수일 떄의 예외처리는 생략
function fibonacci(n) {
    if (n < 2)
        return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}
{% endcodeblock %}

피보나치 수의 정의 자체가 재귀 관계를 내포하고 있으므로, 구현 역시 재귀 호출을 포함하게 된다.

콘솔에서 fibonacci(0), fibonacci(1), fibonacci(2), fibonacci(3), ... 을 여러 개 실행해보면 맞는 답이 나온다.

그럼 여기서 얘기 끝?

물론 아니다. fibonacci(100)을 실행하면 어떨까?

일단 콘솔이 답을 금방 뱉어내질 않는다. 몇 분을 기다려도 답이 안 나와서 조금 기다리다 이상하다 싶어서 콘솔이나 브라우저 탭을 닫아보면 브라우저가 살짝 맛이 갔다는(실은 속으로 열나게 계산 중) 것을 알 수 있다.

# 함수 호출의 비용, Stack

함수를 호출한 후에 원래 자리로 돌아오려면, 원래 자리를 어딘가에 저장해둬야 하는데, 그 어딘가가 바로 Stack이다. 함수를 한 번 호출하면 Stack 크기가 하나 증가하고, 호출된 함수가 일을 마치고 리턴되면 Stack에서 원래 자리를 빼와서 원래 자리로 돌아가므로, Stack 크기가 하나 줄어 원래 크기로 되돌아 간다.

하지만 호출된 함수가 리턴되기 전에 또 함수를 호출하는 것이 반복되면 Stack 크기는 계속 증가하게 된다. 위와 같이 구현된 fibonacci(100)을 실행하면 함수가 리턴되기 전에 계속 fibonacci 함수를 호출하므로 Stack 크기가 계속 증가하게 되는데, 앞의 fibonacci 함수의 경우 100 정도 입력하면 결국 브라우저가 맛이 가게 된다. 요는 문제는 Stack의 증가에 있다는 것이다.

n까지의 합을 구하는 n + sum(n - 1) 같은 식은 100 정도는 넣어도 금방 답을 반환한다. 하지만, fibonacci는 f(n - 1) + f(n - 2)와 같이 재귀 호출을 2번을 해서 값을 더하므로 n까지의 합을 구하는 것에 비해 계산 과정이 복잡하므로 100 정도만 넣어도 꽤 긴 시간이 소요된다.

그럼 이 성능 좋은 컴퓨터를 가지고 겨우 100번째 피보나치 수열도 못 구한단 말인가?

그럴리가..

문제는 Stack의 증가에 있다고 했다. Stack이 증가하지 않게 하면 되는 것 아닌가?
Stack이 증가하지 않게 하려면 어떻게 해야할까?

크게 두 가지 방법이 있을 것 같다.

- 아예 Stack을 쓰지 말아버리자. 즉, 함수를 호출하지 말자.
- Stack을 쓰되 누적시키지 말고 재사용하자.

# 반복

fibonacci(100)은 결국 자기 자신을 여러번 반복해서 호출하게 된다. 그렇다. 피보나치 정의에 따라 식을 구성하다보니 그냥 재귀 호출을 떠올려버렸지만, 피보나치 수를 구하는 과정은 본질적으로 반복이다.

함수 호출을 하지 말고 알맞은 로직을 반복하면 함수 호출에 의한 Stack 사용은 피할 수 있는 것이다.
그러려면 반복할 때마다 나온 계산 결과를 어딘가에 저장해두고 그 다음 반복에서는 앞 단계에서 저장한 값에 새로운 값을 반영하는 방식으로 구현해야 한다.

이 정도의 힌트를 가지고 반복을 이용한 피보나치 구하기를 직접 구현해보자.
피보나치 수열 구하기는 n까지의 합이나 n의 계승(factorial)을 구하는 것에 비하면 여러모로 까다로운 부분이 있으므로 시간이 좀 걸리더라도 좌절하지 말고 꼭 직접 해 볼것을 권장한다.

재귀 호출 대신 반복을 사용한 방식은 다음과 같다.

{% codeblock lang:javascript 재귀 호출 대신 반복을 사용 %}
function fibonacciLoop(n) {
    var tmp, cached_1 = 1, cached_2 = 0;
    if (n < 2)
        return n;
    for ( var i = 2 ; i <= n ; i++ ) {
        tmp = cached_1;
        cached_1 += cached_2;
        cached_2 = tmp;
    }
    return cached_1;
}
{% endcodeblock%}

이제 finonacciLoop(100)을 실행해보면 금방 답이 나온다.

# Tail Call

앞에서 함수 실행 후 돌아갈 원래 자리를 Stack에 저장한다고 했는데, 원래 자리로 돌아가야 할 이유가 뭘까?

원래 자리로 돌아가는 이유는 원래 자리에서 해야할 일이 남아있기 때문이다.
원래 자리에서 해야할 일이 남아있지 않다면 돌아갈 원래 자리를 Stack에 추가로 저장할 필요가 없다.

그렇다면 원래 자리에서 해야할 일을 남겨두지 않는 방법은 무엇인가?

이미 아무것도 하지 않고 있지만, 더욱 격렬히.. 아무것도 하지 않으면 된다.
이것이 바로 Tail Call이다.

{% codeblock lang:javascript Tail Call %}
function a() {
    var v = 0;
    return b(v);
}
function b(n) {
    return n + 1;
}
a();
{% endcodeblock %}

3라인을 보면 b 함수를 호출하는데, b(v) 실행 값을 반환 받은 후 아~~무일도 하지 않고 바로 반환해버린다.

