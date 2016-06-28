title: for-loop 를 Stream.forEach() 로 바꾸지 말아야 할 3가지 이유
date: 2016-06-26 09:00:59
categories:
  - Technique
  - 번역
tags:
  - Java
  - Java8
  - for loop
  - Stream API
  - performance
  - readability
  - 자바
  - 자바8
  - for 반복문 
  - 스트림 API
  - 가독성
thumbnailImage: http://2.bp.blogspot.com/-S8doo3jjcGE/VbEDpARtd6I/AAAAAAAADc0/qgQefN-cBNU/s1600/Java%2B8%2BFeatures.jpg
coverImage: coverImage-java8-stream-api.jpg
---
# `for-loop`를 `Stream.forEach()`로 바꾸지 말아야 할 3가지 이유

>원문 : https://blog.jooq.org/2015/12/08/3-reasons-why-you-shouldnt-replace-your-for-loops-by-stream-foreach/

간디작살! 소스 코드를 Java8로 바꾸자. 뭐든지 함수를 써서 해결하자. 디자인 패턴 따위는 내던져 버리고, 객체 지향도 없애버리자. 좋아! 달려!!

# 저기.. 이보게 젊은이..

Java8이 나온지 2년도 넘었고, 그때의 전율도 이젠 일상이 되어버렸다.

baeldung.com 에서 [2015년 5월에 실시한 조사](http://www.baeldung.com/java-8-spring-4-and-spring-boot-adoption)에 따르면, baeldung.com 독자들 중 38%가 Java8을 도입했다고 한다. [2014년 10월에 Typesafe에서 실시한 조사](https://www.lightbend.com/company/news/survey-of-more-than-3000-developers-reveals-java-8-adoption-ahead-of-previous-forecasts)에서는 27%가 Java8을 도입했다고 한다.

# Java8의 도입은 여러분의 코드에 어떤 의미일까?

Java7 -> Java8 마이그레이션(migration)의 일부는 그다지 결정하기 어려운 일이 아니다. 예를 들어 아래와 같이 `Callable` 익명 객체를 `ExecutorService`에 전달할 때는:

```java
ExecutorService s = ...
 
// Java 7 - 어...
Future<String> f = s.submit(
    new Callable<String>() {
        @Override
        public String call() {
            return "Hello World";
        }
    }
);
 
// Java 8 - 이게 좋겠다!
Future<String> f = s.submit(() -> "Hello World");
```

익명 클래스 스타일은 코드량만 많을 뿐 별다른 의미가 없으므로, 당연히 Java8 스타일을 사용하는 것이 낫다.

하지만 실제로는 이처럼 Java8을 사용하는 것이 확연히 좋은 경우와는 다르게, 어느 쪽을 사용하는 것이 좋은지 좀 애매한 상황도 있다. 예를 들면 [외부 이터레이터와 내부 이터레이터](http://stackoverflow.com/questions/224648/external-iterator-vs-internal-iterator) 중 어느 것을 쓰는 것이 좋을까? 와 같은 상황이다. 오래도록 회자되는 이 주제에 대해 [Neil Gafter가 2007년에 작성한 재미있는 글](http://gafter.blogspot.kr/2007/07/internal-versus-external-iterators.html)도 읽어볼만 할 것이다.

본론으로 돌아와서, 아래의 코드를 보자. 

```java
List<Integer> list = Arrays.asList(1, 2, 3);
 
// Old school
for (Integer i : list)
    System.out.println(i);
 
// "Modern"
list.forEach(System.out::println);
```


둘 다 똑같은 결과가 나오지만, "modern" 스타일은 아주 조심해서 써야 한다고 주장하고 싶다. 다시 말해, Stream의 `map()`이나 `flatMap()` 같은 메서드들을 체이닝(chaining)을 통해 조합해서 사용해야할 때처럼 내부적, 함수적 반복이 확실히 유리할 때만 "modern" 스타일을 쓰는 것이 좋다는 얘기다.

"modern" 스타일을 아주 조심해서 써야한다는 주장에 대한 몇 가지 근거는 다음과 같다.

# 1. 성능 - 떨어진다.

[Angelika Langer가 컨퍼런스에서 발표한 글](https://jaxenter.com/java-performance-tutorial-how-fast-are-the-java-8-streams-118830.html)에는 Stream의 성능에 대한 내용이 아주 잘 나와있다.

성능에 치명적인 영향을 미치는 코드는 많지 않으며, 그래서 성급한 최적화는 해서는 안된다. "아니 장난해? 그렇다면 성능 얘기는 뭐하러 꺼낸거야?"라고 말할 수도 있을텐데, 일반적으로 `Stream.forEach()`를 사용하면 전통적인 `for-loop`를 사용할 때보다 오버헤드가 훨씬 심각하게 발생하기 때문에, 모든 `for-loop`를 `Stream.forEach()`로 대체하면, 애플리케이션 전체에 걸쳐 누적되는 CPU 싸이클 낭비는 무시하지 못할 수준이 될 수 있다. 단순히 반복문 처리 스타일의 선택만으로 CPU 소모량이 10%~20% 정도 더 많아진다면, 그 선택은 근본적으로 잘못된 것이다. 반복문 각각을 놓고 보면 큰 차이가 없지만, 시스템 전체로 보면 피하는 것이 좋다.

아래는 Boxing된 int 배열에서 최대값을 찾는 아주 일상적인 반복문에 대한 Angelika’s benchmark의 벤치마크 결과이다.

```
ArrayList, for-loop : 6.55 ms
ArrayList, seq. stream: 8.33 ms
```

원시 데이터(primitive data type)를 반복문으로 처리할 때는 **절대적으로** 전통적인 `for-loop`를 써야한다(`collections`보다 배열의 경우에는 특히 더).

아래는 int 배열에사 최대값을 찾는 Angelika’s benchmark의 벤치마크 결과이다.

```
int-array, for-loop : 0.36 ms
int-array, seq. stream: 5.35 ms
```

성급한 최적화는 좋지 않다. 하지만 성급한 최적화라도 무조건 회피하는 것은 훨씬 더 좋지 않다. 어떤 상황(context)인지 잘 숙고해서 바른 결정을 내리는 것이 중요하다. 성능에 대해서는 [Top 10 Easy Performance Optimisazions in Java](https://blog.jooq.org/2015/02/05/top-10-easy-performance-optimisations-in-java/)를 참고하자. 

# 2. 가독성 - 적어도 대부분의 사람들에게는..

SW 엔지니어인 우리는 코드 스타일을 아주 중요한 것으로 여기며, 때로 이런 주제로 [토론](https://blog.jooq.org/2014/07/25/top-10-very-very-very-important-topics-to-discuss/)을 하기도 한다.

왜냐하면 SW는 유지관리하기가 어렵기 때문이다. 특히나 다른 사람이 작성한 코드는 더욱 그렇다. 그 다른 사람이 Java로 전향하기 전에 오로지 C로만 코딩해온 사람이라면..

물론 지금까지 예를 들었던 코드에서는 가독성 문제가 있다고 할만한 것은 없었다. 아래의 두 코드는 가독성 면에서 별로 다를 것이 없다:

```java
List<Integer> list = Arrays.asList(1, 2, 3);
 
// Old school
for (Integer i : list)
    System.out.println(i);
 
// "Modern"
list.forEach(System.out::println);
```

하지만, 이건 어떨까:
```java
List<Integer> list = Arrays.asList(1, 2, 3);
 
// Old school
for (Integer i : list)
    for (int j = 0; j < i; j++)
        System.out.println(i * j);
 
// "Modern"
list.forEach(i -> {
    IntStream.range(0, i).forEach(j -> {
        System.out.println(i * j);
    });
});
```

오호~ 뭔가 조금 더 재미있어지는데? 더 나빠졌다는 소리는 하지 않았다. 사실 이런 건 연습이나 습관의 문제다. 그래서 이런 문제에는 좋다/나쁘다 같은 답은 없다. 하지만 코드의 다른 부분이 절차형으로 작성되어있다면(아마도 그럴 가능성이 높다), `range`와 `forEach()`, 람다(lamda)를 중첩시키는 건 그다지 익숙한 풍경이라고 할 순 없겠고, 팀내에서도 인지적 마찰([cognitie friction](https://www.linkedin.com/pulse/20140801230851-205508682-what-the-heck-is-cognitive-friction))이 빚어질 가능성이 높다.

위와는 반대로 절차적 접근이 더 불편해보이는 예제도 만들 수 있다:

![](https://pbs.twimg.com/media/B_AmQW7WwAE_Akt.jpg)
[](https://twitter.com/mariofusco/status/571999216039542784/photo/1)

하지만 함수형 방식이 관심사의 분리를 적용하기 쉬워서 좋다는 위의 주장은 대부분의 경우 사실이 아니다. 절차형 방식으로 비교적 작성하기 쉬운 것도 함수형 방식으로 작성하면 꽤 어렵다(그리고 비효율적이다). 이에 대해서는 [이 블로그의 예전 글](https://blog.jooq.org/2015/09/09/how-to-use-java-8-functional-programming-to-generate-an-alphabetic-sequence/)을 참고하자.

위에서 말한 글에서는 엑셀의 컬럼 이름 같은 문자열 시퀀스를 생성하는데,
```
A, B, ..., Z, AA, AB, ..., ZZ, AAA
```

절차형 방식으로는 아래와 같이 작성할 수 있다(Stack Overflow의 익명의 사용자가 작성).
```java
import static java.lang.Math.*;
  
private static String getString(int n) {
    char[] buf = new char[(int) floor(log(25 * (n + 1)) / log(26))];
    for (int i = buf.length - 1; i >= 0; i--) {
        n--;
        buf[i] = (char) ('A' + n % 26);
        n /= 26;
    }
    return new String(buf);
}
```

함수형 방식으로는 아래와 같다.
```java
import java.util.List;
  
import org.jooq.lambda.Seq;
  
public class Test {
    public static void main(String[] args) {
        int max = 3;
  
        List<String> alphabet = Seq
            .rangeClosed('A', 'Z')
            .map(Object::toString)
            .toList();
  
        Seq.rangeClosed(1, max)
           .flatMap(length ->
               Seq.rangeClosed(1, length - 1)
                  .foldLeft(Seq.seq(alphabet), (s, i) -> 
                      s.crossJoin(Seq.seq(alphabet))
                       .map(t -> t.v1 + t.v2)))
           .forEach(System.out::println);
    }
}
```

위의 함수형 방식 사례에서는 일반적인 Stream API 외에도 함수형 방식을 더 단순하게 쓸 수 있게 해주는 [jOOλ](https://github.com/jOOQ/jOOL)마저 적용되어 있음에도, 절차형 방식이 훨씬 깔끔하다.

# 3. 디버깅

앞에서 다루었던 예제를 살짝 바꿔서 다시 한 번 살펴보자. 이번에는 곱하기 대신 나누기다.

```java
List<Integer> list = Arrays.asList(1, 2, 3);
 
// Old school
for (Integer i : list)
    for (int j = 0; j < i; j++)
        System.out.println(i / j);
 
// "Modern"
list.forEach(i -> {
    IntStream.range(0, i).forEach(j -> {
        System.out.println(i / j);
    });
});
```

빤히 에러가 나올 것 같은 코드이다. 실제로 실행해보면 아래와 같이 에러가 발생한다.

### Old school

```java
Exception in thread "main" java.lang.ArithmeticException: / by zero
	at Test.main(Test.java:13)
```

### Modern

```java
Exception in thread "main" java.lang.ArithmeticException: / by zero
	at Test.lambda$1(Test.java:18)
	at java.util.stream.Streams$RangeIntSpliterator.forEachRemaining(Streams.java:110)
	at java.util.stream.IntPipeline$Head.forEach(IntPipeline.java:557)
	at Test.lambda$0(Test.java:17)
	at java.util.Arrays$ArrayList.forEach(Arrays.java:3880)
	at Test.main(Test.java:16)
```

뭐야, 우리가 지금 뭐 한거지? *1. 성능 - 떨어진다* 에서 얘기한 것처럼 modern 방식에 성능 이슈가 존재하는 이유가 여기에서 직접적으로 드러난다. 내부 반복(Internal iteration)을 사용하면 겉으로는 드러나지 않지만, 내부적으로 JVM과 라이브러리가 할 일이 많아진다. 위 예제와 같이 상당히 단순한 케이스에서도 modern 방식을 쓰면 복잡한 호출구조가 존재하는데, 하물며 *2. 가독성 - 적어도 대부분의 사람들에게는..* 에서 다뤘던 AA, AB, ..., ZZ 시퀀스 생성 예제처럼 복잡한 케이스에서는 어떨까..

유지관리 관점에서보자면, 함수형 프로그래밍 스타일은 절차형 프로그래밍에 비해 훨씬 어렵다. 특히 레거시 코드에서 이 두 스타일을 분별없이 혼용하고 있다면 더욱 어렵다.


# 결론

사실 이 블로그는 함수형 프로그래밍과 선언형 프로그래밍에 대해 일반적으로 찬성하는 편이다. 우리는 람다를 사랑하고, SQL을 애정한다. 둘을 잘 조합해서 쓰면 기적을 만들어낼 수 있다.

하지만 Java8로 마이그레이션하고, 코드에 함수형 스타일을 더 많이 써보고자 한다면, 여러가지 이유로 인해 함수형 프로그래밍이 언제나 더 나은 답은 아니라는 것을 알 필요가 있다. 사실상 결코 더 나은 답이 될 수 없다. 함수형 프로그래밍은 단지 좀 다른 방식일 뿐이고, 문제를 다른 관점에서 추론해 볼 수 있게 해줄 뿐이다.

Java 개발자는 많은 연습을 통해 언제 함수형 프로그래밍을 쓰는 것이 좋은지, 어떨때 객체지향/절차형 방식을 고수하는 것이 좋은지 직관적으로 이해할 수 있어야 한다. 충분한 양의 연습이 동반된다면, 두 가지를 잘 혼용해서 우리가 만드는 SW를 개선할 수 있을 것이다.

엉클 밥의 얘기를 빌리자면:

>정작 중요한 점은 이것이다. 
>뭔지 잘 알고 있다면 객체지향 프로그래밍은 좋다. 
>뭔지 잘 알고 있다면 함수형 프로그래밍은 좋다. 
>뭔지 잘 알고 있다면 함수형 객체지향 프로그래밍은 좋다.
>http://blog.cleancoder.com/uncle-bob/2014/11/24/FPvsOO.html

