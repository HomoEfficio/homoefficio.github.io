title: Back to the Essence - Concurrency vs Parallelism
date: 2019-02-02 23:29:47
categories:
  - Concepts
tags:
  - Concurrency
  - Parallelism
  - 동시성
  - 병렬성
  - 병행성
thumbnailImage: https://www.codeproject.com/KB/cs/1267757/8e925d68-4f47-4ef9-8d51-6a39f19c75d2.Jpeg
coverImage: cover-image-01.png
---
# Back to the Essence - Concurrency vs Parallelism

>동시성이 뭐냐?  
>복수의 태스크를 동시에 실행하는 거 아니냐?
>
>병렬성이 뭐냐?  
>복수의 태스크를 동시에 실행하는 거 아니냐?
>
>그럼 동시성과 병렬성이 뭐가 다른 거냐?  
>...

비슷하지만 다른 개념이라는 건 알겠는데, 설명하라면 또 명확하게 답하기가 쉽지 않다.

명확하게 답하기 쉽지 않은 이유는 몇 가지 관점에 따라 다르게 설명되어야 할 필요가 있는 것을 그냥 뭉뚱그려서 얘기해왔기 때문이다. 이제 관점에 따라 나눠서 살펴보자.


## 시간 관점

### Concurrency

일단 **동시성에서 말하는 동시는 물리적으로 완전히 동일한 한 시점만을 말하는 것이 아니라 사실 상 동시라고 간주할 수 있는 시점(virtually at the same time)도 포함**한다. 물리적으로 미세하게 다른 시점일지라도 애플리케이션 관점에서 동시라고 간주할 수 있는 시간 간격에서 복수의 태스크가 수행된다면 동시성이 있다.

그래서 **동시성은 CPU(또는 코어)가 1개인 상황에서도 가능**하다. 시분할 시스템을 통해 사실 상 동시라고 간주해도 무방한 시간에 여러 개의 태스크를 진행시키고 있다면 동시성이 있다.


### Parallelism

**병렬성에서 말하는 동시는 물리적으로 완전히 동일한 시점(physically and literally at the same time)** 이다.

그래서 **CPU(또는 코어)가 1개인 상황에서는 병렬성을 가질 수 없다.**


## 작업 독립성 관점

독립성은 관점에 따라 다르게 해석될 수 있지만, 그런 상대성을 용인하고 바라보면 다음과 같이 비교할 수도 있다.

### Concurrency

**동시성에서는 독립적인 복수 개의 태스크를 순서대로 실행하지 않고 동시에 실행**한다.

1에서 100까지 더하는 태스크와 1에서 100까지 곱하는 태스크를 동시에 실행한다면 이 두 태스크는 독립적이며, 이런 태스크를 동시에 처리한다면 동시성이 있다.


### Parallelism

**병렬성에서는 하나의 태스크를 여러 부분으로 쪼개서 동시에 실행**한다.

1에서 100까지 더하는 하나의 태스크를 1-30, 31-50, 51-70, 71-100 이렇게 4개의 구간합으로 나누고, 이를 4개의 CPU(또는 코어)에서 각각 동시에 실행하면 병렬성이 있다.


## 동시성과 병렬성의 조합

### 동시성이 있으면서 병렬성은 없을 수 있다?

어떤 관점에서든 CPU(또는 코어)가 1개인 상황에서는 병렬성이 있을 수 없으므로, 이건 자명하다.


### 동시성은 없으면서 병렬성은 있을 수 있다?

위에서 다룬 더하기 구간합은 병렬성이 분명히 있지만, 동시성이 있다고 보는 것은 관점에 따라 다르다. 

구간합 자체를 별개의 태스크로 본다면 동시성이 있다고 볼 수 있고,
구간합을 별개의 태스크가 아니라 전체합이라는 하나의 태스크를 나는 것으로만 본다면 동시성이 없다고 볼 수 있다.


### 동시성과 병렬성 모두 있을 수 있다?

1에서 100까지 더하는 하나의 태스크를 1-50, 51-100 이렇게 2개의 구간합으로 나누고, 이를 1, 2번 CPU(또는 코어)에서 각각 동시에 실행하고, 동시에 1에서 100까지 곱하는 하나의 태스크를 1-50, 51-100 이렇게 2개의 구간곱으로 나누고, 이를 3, 4번 CPU(또는 코어)에서 각각 동시에 실행한다면 어떨까?

이럴 때는 더하기와 곱하기라는 독립적인 태스크를 동시에 실행하므로 동시성이 있고,  
더하기라는 하나의 태스크를 구간합으로 나눠서 동시에 실행하고, 곱하기라는 하나의 태스크를 구간곱으로 나눠서 동시에 실행하므로 병렬성도 있다.


## 마무리

자 이렇게 구체적으로 감을 잡았으면 다음과 같이 조금 추상적인 단문 비교로 정리할 수 있겠다.

>동시성은 여러 가지 일을 한 번에 **처리**하는 것을 말하고,  
>병렬성은 여러 가지 일을 한 번에 **수행**하는 것을 말한다.
>
>`Concurrency is about **dealing with** lots of things at once.`  
>`Parallelism is about **doing** lots of things at once.`

간결해서 좋아보이기는 하는데 우리말로 옮겨보면 처리나 수행이나 비슷해져버려서.. 이건 원어민에게는 좋은 비교겠지만, 우리에겐 아쉽게도 그다지..

>동시성은 **구조**에 관한 것이고,  
>병렬성은 **실행**에 관한 것이다.
>
>`Concurrency is about the **structure**.`  
>`Parallelism is about the **execution**.`

오호 이게 더 와닿는 것 같다. 영어든 국어든 글자수까지 똑같아서 아름답기까지 하다..  
이렇게 보면 Parallelism을 병렬성보다는 병행성으로 옮기는 게 더 나은 것 같다.

간단하게는 썸네일로 사용한 이 그림도 괜찮고,

![Imgur](https://i.imgur.com/cDdWLKL.jpg)

(출처: https://www.codeproject.com/Articles/1267757/Concurrency-vs-Parallelism)

다음 그림도 괜찮은 것 같다.

![Imgur](https://i.imgur.com/uIMnkj1.jpg)

(출처: https://twitter.com/ohidxy/status/946110898539659264)


### 참고 자료

- https://howtodoinjava.com/java/multi-threading/concurrency-vs-parallelism/
- https://www.slideshare.net/PramestiHattaK/golang-101-concurrency-vs-parallelism
- http://tutorials.jenkov.com/java-concurrency/concurrency-vs-parallelism.html
- https://www.amazon.com/Reactive-Programming-RxJava-Asynchronous-Applications/dp/1491931655/
