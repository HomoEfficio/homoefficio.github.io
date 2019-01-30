title: Back to the Essence - Java 컴파일에서 실행까지 - (2)
date: 2019-01-31 00:20:05
categories:
  - Specification
tags:
  - Java
  - JVM
  - Bytecode
  - Compile
  - JVM Spec
  - JRE
  - JVM Instruction
  - Run-Time Data Area
  - Heap
  - Method Area
  - PC Register
  - JVM Stack
  - Native Method Stack
  - Frame
  - Local Variables
  - Operand Stack
  - Reference to Run-Time Constant Pool
  - Run-Time Constant Pool
  - Link
  - Verification
  - Preparation
  - Initialization
  - Resolution
  - invokespecial
  - invokeinterface
  - invokevirtual
  - 자바
  - 컴파일
  - 바이트코드
  - JVM 명세
  - JVM 스펙
  - JVM 명령어
  - 런타임 데이터 영역
  - 자바 메모리 모델
  - JVM 메모리 모델
  - 힙
  - 메서드 영역
  - PC 레지스터
  - JVM 스택
  - 네이티브 메서드 스택
  - 프레임
  - 로컬 변수 배열
  - 오퍼랜드 스택
  - 런타임 상수 풀
  - 링크
  - 확인
  - 준비
  - 초기화
  - 해석
  - javap
thumbnailImage: https://i.imgur.com/Dw4W7or.png
coverImage: cover-jvm-02.jpg
---
# Back to the Essence - Java 컴파일에서 실행까지 - (2)

Java 11 JVM 스펙을 기준으로 Java 소스 코드가 어떻게 컴파일되고 실행되는지 살짝 깊게 알아보자.

이번엔 2탄 실행 편이다. 1탄 컴파일 편은 [여기](https://homoefficio.github.io/2019/01/31/Back-to-the-Essence-Java-컴파일에서-실행까지-1/)에..


# 실행

자바 애플리케이션은 `java` 명령어로 실행할 수 있다. [오라클의 Tools Reference 문서](https://docs.oracle.com/en/java/javase/11/tools/java.html#GUID-3B1CE181-CD30-4178-9602-230B800D4FAE)에 나오는 `java`에 대한 설명은 다음과 같다.

>`java` 명령어는 자바 애플리케이션을 시작한다.  
>`java` 명령어는 먼저 JRE(Java Runtime Environment)를 시작하고,  
>인자로 지정된 클래스(`public static void main(String[] args)`를 포함하고 있는 클래스)를 로딩하고,  
>`main()` 메서드를 호출한다.

## JDK, JRE, JVM

`java`는 JRE를 시작한다고 하니, JDK, JRE, JVM의 관계를 그림 한 장으로 가볍게 훑고 지나가자.

![Imgur](https://i.imgur.com/wChPQEV.png)

- JDK: 자바 개발 환경 - 컴파일러, 역어셈블러, 디버거, 의존관계분석 등 개발에 필요한 도구 제공
- JRE: 자바 실행 환경 - 자바 실행 명령, 클래스로더와 바이트코드의 실행에 필요한 기본 라이브러리 제공
- JVM: 자바 가상 머신 - 바이트코드 인터프리터, JIT 컴파일러, 링커, 명령어 세트, 가비지 컬렉터, 런타임 데이터 영역(메모리) 등 OS에 독립적으로 실행될 수 있는 추상층 제공

대략 다음과 같이 정리할 수 있다.

>JDK를 사용해서 바이트코드(class 파일)를 만들고, 
>
>JRE를 사용해서 바이트코드를 실행하면,
>
>JVM이 기동되면서 바이트코드의 실질적인 실행(실제 OS에 메모리 할당/회수, 시스템 명령 호출 등 요청)을 담당한다.


## JRE 시작

`java` 명령 실행에 의해 JRE가 시작된다는 것은 결국 `java` 명령어의 인자로 지정된 클래스를 실행하기 위한 자바 실행 환경이 조성됨을 의미한다. 

`java` 명령어의 인자로 지정한 설정 옵션에 맞게 JVM이 실행되고, JVM이 클래스로더를 이용해서 `initial class`를 `create`하고, `initial class`를 `link`하고, `initialize`하고, main 메서드를 호출한다.([JVM 스펙](https://docs.oracle.com/javase/specs/jvms/se11/html/jvms-5.html#jvms-5.2) 참고)

### 용어 정리

몇 가지 용어를 일부러 스펙에 나온 원어 그대로 썼는데 스펙상의 의미는 다음과 같다.

- initial class: JVM 구현에 따라 다를 수 있지만 일반적으로 main 메서드를 포함하는 클래스로서 java 명령어의 인자로 지정되는 클래스 ([JVM 스펙](https://docs.oracle.com/javase/specs/jvms/se11/html/jvms-5.html#jvms-5.2) 참고)
- create (a class or interface): 해당 클래스나 인터페이스의 바이트코드를 로딩해서 JVM이 할당한 메모리(Method Area, 메서드 영역)에 construction하는 것 ([JVM 스펙](https://docs.oracle.com/javase/specs/jvms/se11/html/jvms-5.html#jvms-5.3) 참고)
- link (a class or interface): 해당 클래스나 인터페이스의 바로 위 수퍼클래스나 수퍼인터페이스, 또는 배열일 경우 배열의 원소인 클래스나 인터페이스를 확인(verify)/준비(prepare)하고, 심볼릭 참조를 해석(resolve)해서 JVM에서 실행될 수 있는 상태로 만드는 것 ([JVM 스펙](https://docs.oracle.com/javase/specs/jvms/se11/html/jvms-5.html#jvms-5.4) 참고)
- initialize (a class or interface): 해당 클래스나 인터페이스의 class or interface initialization method를 실행하는 것 ([JVM 스펙](https://docs.oracle.com/javase/specs/jvms/se11/html/jvms-5.html#jvms-5.5) 참고)

위 설명에는 없지만 중요한 용어인 로딩의 스펙상의 의미는 다음과 같다.

- load (a class or interface): 해당 클래스나 인터페이스의 바이너리 표현을 찾아서 그 바이너리 표현으로부터 클래스나 인터페이스를 생성(create)하는 것 ([JVM 스펙](https://docs.oracle.com/javase/specs/jvms/se11/html/jvms-5.html) 참고)

앞으로 **initial class는 시작 클래스**, **create은 생성**, **link는 링크**, **initialize는 초기화**, **load는 로딩**이라고 쓴다. 한 가지 유의할 것은 여기서 말하는 **생성(create)은 JVM의 힙(heap)에 객체를 생성하는 것만을 지칭하는 것이 아니라 JVM의 메모리 어딘가에 자료구조를 생성하는 것을 모두 지칭**한다.


## 런타임 데이터 영역

`java` 명령어로 자바 애플리케이션을 실행하면 JVM이 실행되면서 시작 클래스를 생성, 링크, 초기화하고 main 메서드를 호출한다고 했다. 시작 클래스를 생성한다는 것은 시작 클래스의 바이트코드를 읽어서 JVM의 메모리 어딘가에 쓰는 것을 의미한다. JVM의 메모리는 어떻게 생겼을까?

JVM은 프로그램의 실행에 사용되는 메모리를 런타임 데이터 영역(Runtime Data Area)이라고 부르는 몇 가지 영역으로 나눠서 관리한다. 스펙의 목차로 보면 밋밋하게 다음과 같이 나열되어 있다.

1. PC 레지스터
1. JVM 스택
1. 힙(Heap)
1. 메서드 영역(Method Area)
1. 런타임 상수 풀(Run-Time Constnat Pool)
1. 네이티브 메서드 스택

이렇게 보면 위 6가지가 동등한 최상위 수준에서 분류되는 것처럼 보인다. 하지만, 실제 스펙의 설명을 보면 다음과 같이 약간 입체적으로 구분하는 것이 더 적합하다.

![Imgur](https://i.imgur.com/Mh4DuRB.png)

여기서 '단위'라는 구분 단계를 추가한 이유는 스펙에도 `per-class`, `per-thread` 라는 표현이 나오기 때문인데, 여기에서의 '단위'는 생명 주기와 생성 단위를 의미한다.

JVM 단위에 속하는 **힙과 메서드 영역은 JVM이 시작될 때 생성되고, JVM이 종료될 때 소멸되며, JVM 하나에 힙 하나, 메서드 영역도 하나가 생성** 된다.

마찬가지로 클래스 단위에 속하는 **런타임 상수 풀은 클래스가 생성/소멸될 때 함께 생성/소멸되며, 클래스 하나에 런타임 상수 풀도 하나가 생성** 된다.

스레드 단위에 속하는 **PC 레지스터, JVM 스택, 네이티브 메서드 스택도 스레드가 생성/소멸될 때 함께 생성/소멸되며, 스레드 하나에 PC 레지스터, JVM 스택, 네이티브 메서드 스택도 각 하나씩 생성** 된다.

자. 이제 6가지 영역을 좀 더 자세히 알아보자.

라고 진행하면 너무 뻔한 나열식이라 머리에 잘 안 남는다. 그러니 다음과 같이 간단한 예제 코드 실행 과정과 함께 살펴보자.


## 예제 코드

### 자바 소스 코드

헬로 월드 수준의 단순한 소스 코드다. 힙에서 객체가 생성되는 것을 확인하기 위해 Hello 인스턴스를 만들고 무한루프로 프로그램의 종료를 일부러 막아둔 코드다.

```java
package homo.efficio.jvm.sample;

public class Hello {

    public static void main(String[] args) {
        final Hello hello = new Hello();
        System.out.println(hello.helloMessage());
        while (true) {}
    }

    public String helloMessage() {
        return "Hello, JVM";
    }
}
```

### 컴파일된 바이트코드

컴파일된 바이트코드는 다음과 같다.

>javap -v -p -s homo/efficio/jvm/sample/Hello.class

```java
$ /c/Program\ Files/Java/jdk-11.0.2/bin/javap -v -p -s homo/efficio/jvm/sample/Hello
Classfile /C:/gitrepo/scratchpad/java-jvm-scratchpad/out/production/java-jvm-scratchpad/homo/efficio/jvm/sample/Hello.class
  Last modified 2019. 1. 30.; size 741 bytes
  MD5 checksum 675e63b96993dc5e661d6566467d92d3
  Compiled from "Hello.java"
public class homo.efficio.jvm.sample.Hello
  minor version: 0
  major version: 55
  flags: (0x0021) ACC_PUBLIC, ACC_SUPER
  this_class: #2                          // homo/efficio/jvm/sample/Hello
  super_class: #8                         // java/lang/Object
  interfaces: 0, fields: 0, methods: 3, attributes: 1
Constant pool:
   #1 = Methodref          #8.#26         // java/lang/Object."<init>":()V
   #2 = Class              #27            // homo/efficio/jvm/sample/Hello
   #3 = Methodref          #2.#26         // homo/efficio/jvm/sample/Hello."<init>":()V
   #4 = Fieldref           #28.#29        // java/lang/System.out:Ljava/io/PrintStream;
   #5 = Methodref          #2.#30         // homo/efficio/jvm/sample/Hello.helloMessage:()Ljava/lang/String;
   #6 = Methodref          #31.#32        // java/io/PrintStream.println:(Ljava/lang/String;)V
   #7 = String             #33            // Hello, JVM
   #8 = Class              #34            // java/lang/Object
   #9 = Utf8               <init>
  #10 = Utf8               ()V
  #11 = Utf8               Code
  #12 = Utf8               LineNumberTable
  #13 = Utf8               LocalVariableTable
  #14 = Utf8               this
  #15 = Utf8               Lhomo/efficio/jvm/sample/Hello;
  #16 = Utf8               main
  #17 = Utf8               ([Ljava/lang/String;)V
  #18 = Utf8               args
  #19 = Utf8               [Ljava/lang/String;
  #20 = Utf8               hello
  #21 = Utf8               StackMapTable
  #22 = Utf8               helloMessage
  #23 = Utf8               ()Ljava/lang/String;
  #24 = Utf8               SourceFile
  #25 = Utf8               Hello.java
  #26 = NameAndType        #9:#10         // "<init>":()V
  #27 = Utf8               homo/efficio/jvm/sample/Hello
  #28 = Class              #35            // java/lang/System
  #29 = NameAndType        #36:#37        // out:Ljava/io/PrintStream;
  #30 = NameAndType        #22:#23        // helloMessage:()Ljava/lang/String;
  #31 = Class              #38            // java/io/PrintStream
  #32 = NameAndType        #39:#40        // println:(Ljava/lang/String;)V
  #33 = Utf8               Hello, JVM
  #34 = Utf8               java/lang/Object
  #35 = Utf8               java/lang/System
  #36 = Utf8               out
  #37 = Utf8               Ljava/io/PrintStream;
  #38 = Utf8               java/io/PrintStream
  #39 = Utf8               println
  #40 = Utf8               (Ljava/lang/String;)V
{
  public homo.efficio.jvm.sample.Hello();
    descriptor: ()V
    flags: (0x0001) ACC_PUBLIC
    Code:
      stack=1, locals=1, args_size=1
         0: aload_0
         1: invokespecial #1                  // Method java/lang/Object."<init>":()V
         4: return
      LineNumberTable:
        line 3: 0
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
            0       5     0  this   Lhomo/efficio/jvm/sample/Hello;

  public static void main(java.lang.String[]);
    descriptor: ([Ljava/lang/String;)V
    flags: (0x0009) ACC_PUBLIC, ACC_STATIC
    Code:
      stack=2, locals=2, args_size=1
         0: new           #2                  // class homo/efficio/jvm/sample/Hello
         3: dup
         4: invokespecial #3                  // Method "<init>":()V
         7: astore_1
         8: getstatic     #4                  // Field java/lang/System.out:Ljava/io/PrintStream;
        11: aload_1
        12: invokevirtual #5                  // Method helloMessage:()Ljava/lang/String;
        15: invokevirtual #6                  // Method java/io/PrintStream.println:(Ljava/lang/String;)V
        18: goto          18
      LineNumberTable:
        line 6: 0
        line 7: 8
        line 8: 18
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
            0      21     0  args   [Ljava/lang/String;
            8      13     1 hello   Lhomo/efficio/jvm/sample/Hello;
      StackMapTable: number_of_entries = 1
        frame_type = 252 /* append */
          offset_delta = 18
          locals = [ class homo/efficio/jvm/sample/Hello ]

  public java.lang.String helloMessage();
    descriptor: ()Ljava/lang/String;
    flags: (0x0001) ACC_PUBLIC
    Code:
      stack=1, locals=1, args_size=1
         0: ldc           #7                  // String Hello, JVM
         2: areturn
      LineNumberTable:
        line 12: 0
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
            0       3     0  this   Lhomo/efficio/jvm/sample/Hello;
}
SourceFile: "Hello.java"

```

앞에서 JDK, JRE, JVM 관계로 설명했지만 위와 같은 바이트코드를 만드는 과정까지는 JDK에서 담당한다.

앞에서 자바 프로그램이 실행되면 다음과 같이 전개된다고 설명했다. 

>**JVM이 실행**되고, JVM이 클래스로더를 이용해서 **시작 클래스를 생성**하고, **링크**하고, **초기화**하고, **main 메서드를 호출**한다.

이제 `java homo.efficio.jvm.sample.Hello` 명령을 실행하면 어떻게 진행되는지 차근차근 살펴보자.


## JVM 실행

`java` 명령이 실행되면 JRE가 조성되면서 JVM이 실행된다. JVM이 실행되면 JVM 단위로 생성되는 힙과 메서드 영역이 함께 생성된다.

### 힙

**[힙(Heap)](https://docs.oracle.com/javase/specs/jvms/se11/html/jvms-2.html#jvms-2.5.3)은 인스턴스화 된 모든 클래스 인스턴스와 배열을 저장하는 공간**이며, **모든 JVM 스레드에 공유**된다.

힙에 저장된 객체에 할당된 메모리는 명시적인 방법으로는 절대 회수되지 못하며, 오직 가비지 컬렉터(garbage collector)에 의해서만 회수될 수 있다.

Hello는 이 시점에서는 아직 인스턴스화 되지 않았으므로 힙은 비어있다.

### 메서드 영역

**[메서드 영역(Method Area)](https://docs.oracle.com/javase/specs/jvms/se11/html/jvms-2.html#jvms-2.5.4)은 런타임 상수 풀, 필드와 메서드 데이터, 생성자 및 메서드의 코드 내용을 저장**한다. 저장되는 내용은 위에서 살펴봤던 바이트코드의 내용과 거의 일치한다. 거의라고 얘기하는 이유는 바이트코드에는 런타임 상수 풀이 아니라 그냥 상수 풀(constanta pool)이 포함되어 있기 때문이다. 런타임 상수 풀은 이 상수 풀을 바탕으로 런타임에, 더 구체적으로는 메서드 영역에 저장될 때 만들어진다.

그래서 엄밀히 말하면 정확하지 않지만, **바이트코드 내용이 메서드 영역에 저장된다**라고 이해해도 크게 틀리지는 않다.

Hello는 이 시점에서는 아직 생성되지 않았으므로 메서드 영역도 비어있다.

![Imgur](https://i.imgur.com/KXJsPgs.png)


## 시작 클래스 생성

시작 클래스는 Hello를 지칭하며 시작 클래스를 생성하는 것은 파일시스템에 있는 Hello.class 파일을 JVM의 메서드 영역으로 읽어들이는 것을 의미한다고 했다. 따라서 **이 시점에서 Hello의 바이트코드 내용이 메서드 영역에 저장**된다.

![Imgur](https://i.imgur.com/QBQyTab.png)


### 런타임 상수 풀

클래스가 생성되면 [런타임 상수 풀(Run-Time Constant Pool)](https://docs.oracle.com/javase/specs/jvms/se11/html/jvms-2.html#jvms-2.5.5)도 함께 생성된다고 했다. **런타임 상수 풀에는 컴파일 타임에 이미 알 수 있는 숫자 리터럴 값부터 런타임에 해석되는 메서드와 필드의 참조까지를 포괄하는 여러 종류의 상수가 포함**된다. 런타임 상수 풀은 다른 전통적인 언어에서 말하는 심볼 테이블과 비슷한 기능을 한다고 보면 된다.

![Imgur](https://i.imgur.com/ZtsNYAv.png)


## 링크

**링크는 클래스나 인터페이스의 바로 위 수퍼클래스나 수퍼인터페이스, 또는 배열일 경우 배열의 원소인 클래스나 인터페이스를 확인(verify)/준비(prepare)하고, 심볼릭 참조를 해석(resolve)하는 과정**을 말한다.

그럼 확인, 준비, 해석은 뭘 의미하는 걸까?

### 확인

**[확인(verification)](https://docs.oracle.com/javase/specs/jvms/se11/html/jvms-5.html#jvms-5.4.1)은 클래스나 인터페이스의 바이너리 표현이 구조적으로 올바른지를 보장해주는 과정**이다. 확인 과정은 다른 클래스나 인터페이스의 로딩을 유발할 수도 있지만, 로딩된 다른 클래스나 인터페이스의 확인이나 준비를 필수적으로 유발하지는 않는다.

Hello.class 파일은 JDK에 포함된 공식 컴파일러인 `javac`에 의해 정상적으로 컴파일되었으므로 구조적으로 올바르다고 가정하면, **확인 과정에서 Hello의 부모 클래스인 Object가 로딩**된다.

![Imgur](https://i.imgur.com/8f6zqKP.png)

### 준비

**[준비(preperation)](https://docs.oracle.com/javase/specs/jvms/se11/html/jvms-5.html#jvms-5.4.2)는 클래스나 인터페이스의 정적(static) 필드를 생성하고 기본값으로 초기화하는 과정**이다. 준비 과정에서는 JVM 코드의 실행을 필요로 하지 않으며, **기본값이 아닌 특정값으로 정적 필드를 초기화하는 과정은 준비 과정이 아니라 초기화 과정에서 수행**된다.

스펙에 정의된 [기본형 타입의 기본값](https://docs.oracle.com/javase/specs/jvms/se11/html/jvms-2.html#jvms-2.3)과 [참조형 타입의 기본값](https://docs.oracle.com/javase/specs/jvms/se11/html/jvms-2.html#jvms-2.4)은 다음과 같다.

타입 | 기본값
--- | ---
byte, short, int, long | 0
char | null(`'\u0000'`)
float, double | 0(positive zero)
boolean | false
참조형 | null


Hello에는 정적 필드가 없으므로 이 과정에서 특별히 수행되는 것은 없다.

### 해석

**[해석(resolution)](https://docs.oracle.com/javase/specs/jvms/se11/html/jvms-5.html#jvms-5.4.3)은 런타임 상수 풀에 있는 심볼릭 참조가 구체적인 값을 가리키도록 동적으로 결정하는 과정**이다. 초기 상태의 런타임 상수 풀에 있는 심볼릭 참조는 해석되어져 있지 않다.

### 링크의 조건

JVM 스펙에서는 **링크가 언제 수행되어야 하는지는 규정하지 않고 유연하게 구현될 수 있는 여지**를 주고 있다. 단 다음과 같은 조건을 만족해야 한다.

- 클래스나 인터페이스는 링크되기 전에 먼저 완전히 로딩되어야 한다.
- 클래스나 인스턴스는 초기화되기 전에 먼저 완전히 확인되고 준비되어야 한다.
- 링크 관련 에러는 해당 클래스나 인터페이스에 대한 링크를 필요로 하는 행위가 수행되는 시점에 throw 되어야 한다.
- 동적으로 계산되는(dynamically-computed) 상수 A에 대한 심볼릭 참조는, A를 참조하는 `ldc`, `ldc_w`, `ldc2_w` 명령어가 실행되거나 A를 정적 인자로 참조하는 부트스트랩 메서드가 호출되기 전까지는 해석되지 않는다.
- 동적으로 계산되는(dynamically-computed) call site B에 대한 심볼릭 참조는, B를 정적 인자로 참조하는 부트스트랩 메서드가 호출되기 전까지는 해석되지 않는다.

일반적으로 만족되어야 하는 것은 1, 2, 3번째 조건이고 4, 5번째는 특수한 경우에 대한 조건이다.

해석 시점은 JVM 구현체에 따라 다를 수 있다. **지연(lazy) 링크 전략을 사용하면 클래스나 인터페이스에 포함된 심볼릭 참조는 해당 참조가 실제 사용될 때 개별적으로 해석**된다. 반면에 **즉시(eager) 링크 전략을 사용하면 클래스나 인터페이스가 확인될 때 모든 심볼릭 참조가 한꺼번에 해석**된다. 지연 링크를 사용하면 해석 과정은 클래스나 인터페이스가 초기화 된 후에 실행될 수도 있다.

링크 과정을 정리하면 다음과 같다.

>링크는 **확인, 준비, 해석 단계로 구성된다.**
>
>**클래스나 인터페이스는 완전히 로딩된 후에 확인과 준비가 수행돼야 하고, 완전히 확인되고 준비된 뒤에 초기화되어야 한다.**
>
>**해석은 초기화 이후에 실행될 수도 있다.**

스펙을 보면 해석은 다시 [클래스/인터페이스 해석](https://docs.oracle.com/javase/specs/jvms/se11/html/jvms-5.html#jvms-5.4.3.1), [필드 해석](https://docs.oracle.com/javase/specs/jvms/se11/html/jvms-5.html#jvms-5.4.3.2), [메서드 해석](https://docs.oracle.com/javase/specs/jvms/se11/html/jvms-5.html#jvms-5.4.3.3), [인터페이스 메서드 해석](https://docs.oracle.com/javase/specs/jvms/se11/html/jvms-5.html#jvms-5.4.3.4), [메서드 타입/핸들 해석](https://docs.oracle.com/javase/specs/jvms/se11/html/jvms-5.html#jvms-5.4.3.5), [동적 계산 상수/콜사이트 해석](https://docs.oracle.com/javase/specs/jvms/se11/html/jvms-5.html#jvms-5.4.3.6), 이렇게 6가지로 나눠서 자세한 설명이 나와 있으니 관심있다면 찾아보기로 하고 다시 예제로 돌아와 보자. 

Hello의 상수 풀은 다음과 같았다.

```java
Constant pool:
   #1 = Methodref          #8.#26         // java/lang/Object."<init>":()V
   #2 = Class              #27            // homo/efficio/jvm/sample/Hello
   #3 = Methodref          #2.#26         // homo/efficio/jvm/sample/Hello."<init>":()V
   #4 = Fieldref           #28.#29        // java/lang/System.out:Ljava/io/PrintStream;
   #5 = Methodref          #2.#30         // homo/efficio/jvm/sample/Hello.helloMessage:()Ljava/lang/String;
   #6 = Methodref          #31.#32        // java/io/PrintStream.println:(Ljava/lang/String;)V
   #7 = String             #33            // Hello, JVM
   #8 = Class              #34            // java/lang/Object
   #9 = Utf8               <init>
  #10 = Utf8               ()V
  #11 = Utf8               Code
  #12 = Utf8               LineNumberTable
  #13 = Utf8               LocalVariableTable
  #14 = Utf8               this
  #15 = Utf8               Lhomo/efficio/jvm/sample/Hello;
  #16 = Utf8               main
  #17 = Utf8               ([Ljava/lang/String;)V
  #18 = Utf8               args
  #19 = Utf8               [Ljava/lang/String;
  #20 = Utf8               hello
  #21 = Utf8               StackMapTable
  #22 = Utf8               helloMessage
  #23 = Utf8               ()Ljava/lang/String;
  #24 = Utf8               SourceFile
  #25 = Utf8               Hello.java
  #26 = NameAndType        #9:#10         // "<init>":()V
  #27 = Utf8               homo/efficio/jvm/sample/Hello
  #28 = Class              #35            // java/lang/System
  #29 = NameAndType        #36:#37        // out:Ljava/io/PrintStream;
  #30 = NameAndType        #22:#23        // helloMessage:()Ljava/lang/String;
  #31 = Class              #38            // java/io/PrintStream
  #32 = NameAndType        #39:#40        // println:(Ljava/lang/String;)V
  #33 = Utf8               Hello, JVM
  #34 = Utf8               java/lang/Object
  #35 = Utf8               java/lang/System
  #36 = Utf8               out
  #37 = Utf8               Ljava/io/PrintStream;
  #38 = Utf8               java/io/PrintStream
  #39 = Utf8               println
  #40 = Utf8               (Ljava/lang/String;)V
```

설명의 편의를 위해 즉시 링크 방식으로 해석이 진행된다고 가정하고, 위 상수 풀에서 유도되는 런타임 상수 풀에 있는 심볼릭 참조의 해석 과정을 몇 개만 예로 살펴보자.

`#1 = Methodref          #8.#26         // java/lang/Object."<init>":()V`

Object 클래스가 확인 과정에서 메서드 영역에 로딩되어 있으므로, 메서드 영역에 저장된 Object 클래스의 바이트코드 내용에서 생성자(`<init>`)의 위치를 알아낼 수 있고, 그 위치를 `Methodref java/lang/Object."<init>"`의 값으로 해석할 수 있다.

![Imgur](https://i.imgur.com/MAiWMYz.png)

`#2 = Class              #27            // homo/efficio/jvm/sample/Hello`

Hello 인스턴스를 만들 때 필요한 Hello 클래스 정보는 이미 메서드 영역에 로딩되어 있으므로, 메서드 영역 내에서 Hello 클래스의 위치를 `Class homo/efficio/jvm/sample/Hello`의 값으로 해석할 수 있다.

![Imgur](https://i.imgur.com/y0qP8vW.png)

`#3`은 Hello 생성자를 가리키는 Methodref 항목인데, Methodref의 해석 과정은 앞의 `#1`에서 이미 다뤘으므로 설명은 생략하고 그림만 보자.

![Imgur](https://i.imgur.com/XBMPitk.png)

`#4 = Fieldref           #28.#29        // java/lang/System.out:Ljava/io/PrintStream;`

System 클래스는 아직 로딩되어 있지 않으므로 먼저 로딩하고, 확인 후 준비 과정을 거치면서 System 클래스의 정적 필드인 `out`의 타입인 PrintStream 클래스도 로딩되고 참조형 변수인 `out`은 기본값인 null 로 초기화 된다.

![Imgur](https://i.imgur.com/RJ3ZLvX.png)

대략 이런 식으로 로딩-링크 과정이 연쇄적으로 수행되면서 메서드 영역이 채워지고, 메서드 영역 내에서 클래스 단위로 생성되는 런타임 상수 풀 안에 있는 심볼릭 참조가 가리키는 값들이 결정된다.

하지만 이것도 위에 썼듯이 즉시 링크 방식일 때의 얘기고, **지연 링크를 사용한다면 각 클래스의 초기화가 수행된 이후에 해석 과정이 수행**될 수도 있다.

그럼 이제 초기화를 알아볼 차례다.


## 초기화

초기화(initialization)는 `클래스 또는 인터페이스 초기화 메서드(class or interface initialization method)`를 실행할 때 수행되는 과정이다. 쉽게 말하면 **여기에서 말하는 초기화는 정적 초기화(static initialization)를 말한다**고 볼 수 있다.

그럼 초기화 메서드는 무엇일까?

### 초기화 메서드

초기화 메서드(initialization method)는 두 가지가 있다.

#### 인스턴스 초기화 메서드

[인스턴스 초기화 메서드](https://docs.oracle.com/javase/specs/jvms/se11/html/jvms-2.html#jvms-2.9.1)는 자바 언어로 작성되는 생성자에 해당하며, 클래스는 0개 이상의 인스턴스 초기화 메서드를 가진다. `인스턴스 초기화 메서드`는 다음의 조건을 모두 충족해야 한다.

- (인터페이스가 아니고) 클래스 안에 정의된다.
- (바이트코드 상에서) `<init>`라는 특수한 이름으로 표현된다.
- 반환 타입은 void

`인스턴스 초기화 메서드`는 생성자로서 힙에 인스턴스를 생성하는 역할을 담당하며, 이름에 초기화라는 용어가 들어가지만 여기에서 말하는 초기화와는 좀 다른 개념이고, 실제 스펙에서도 초기화는 (인스턴스 초기화 메서드를 배제하고) `class or interface initialization method(클래스 또는 인터페이스 초기화 메서드)`를 호출한다고 명시되어 있다. ([JVM 스펙](https://docs.oracle.com/javase/specs/jvms/se11/html/jvms-5.html#jvms-5.5)에 [2.9.2](https://docs.oracle.com/javase/specs/jvms/se11/html/jvms-2.html#jvms-2.9.2) 라고 따로 명기)

#### 클래스 초기화 메서드(클래스 또는 인터페이스 초기화 메서드)

앞에서 링크 과정의 준비 단계 설명에 초기화가 잠시 언급된 적이 있다.  
**정적 필드를 기본값으로 초기화 하는 것은 링크의 준비 단계에서 수행**되고, **정적 필드를 특정값으로 초기화 하는 것은 초기화 단계에서 수행**된다고 했는데, 지금 설명하고 있는 이 `클래스 또는 인터페이스 초기화 메서드`가 실행되는 것이 초기화 단계다.

[클래스 또는 인터페이스 초기화 메서드](https://docs.oracle.com/javase/specs/jvms/se11/html/jvms-2.html#jvms-2.9.2)는 클래스나 인터페이스에(클래스나 인터페이스의 바이트코드에) 1개만 존재할 수 있으며, 다음의 조건을 모두 충족해야 한다.

- (바이트코드 상에서) `<clinit>`라는 특수한 이름으로 표현된다.
- 반환 타입은 void
- class 파일 버전 51 이상에서는 `ACC_STATIC` 플래그가 붙는다.

인스턴스 초기화 메서드는 생성자에 해당한다는 명확하고 직관적인 설명이 스펙에 있는데, `클래스 또는 인터페이스 초기화 메서드`는 아쉽게도 뭐에 해당하는지 스펙에는 구체적인 설명이 없다.

그래서 몇 가지 테스트를 해 본 결과 **클래스 초기화 메서드는 쉽게 말해 static 블록(들)의 내용을 하나로 합친 것**이라고 볼 수 있다. 이건 말보다 코드가 훨씬 쉬우니 코드로 살펴보자.

```java
package homo.efficio.jvm.sample;

public class StaticInitSample {

    public final static int i;

    static {
        i = 11;
    }

    private final static int j;

    static {
        j = 22;
    }
}
```

컴파일한 후 `javap -v -p -s homo.efficio.jvm.sample.StaticInitSample` 명령으로 바이트코드를 살펴보면 다음과 같다.

```java
public class homo.efficio.jvm.sample.StaticInitSample
  minor version: 0
  major version: 52
  flags: ACC_PUBLIC, ACC_SUPER
Constant pool:
   #1 = Methodref          #5.#19         // java/lang/Object."<init>":()V
   #2 = Fieldref           #4.#20         // homo/efficio/jvm/sample/StaticInitSample.i:I
   #3 = Fieldref           #4.#21         // homo/efficio/jvm/sample/StaticInitSample.j:I
   #4 = Class              #22            // homo/efficio/jvm/sample/StaticInitSample
   #5 = Class              #23            // java/lang/Object
   #6 = Utf8               i
   #7 = Utf8               I
   #8 = Utf8               j
   #9 = Utf8               <init>
  #10 = Utf8               ()V
  #11 = Utf8               Code
  #12 = Utf8               LineNumberTable
  #13 = Utf8               LocalVariableTable
  #14 = Utf8               this
  #15 = Utf8               Lhomo/efficio/jvm/sample/StaticInitSample;
  #16 = Utf8               <clinit>
  #17 = Utf8               SourceFile
  #18 = Utf8               StaticInitSample.java
  #19 = NameAndType        #9:#10         // "<init>":()V
  #20 = NameAndType        #6:#7          // i:I
  #21 = NameAndType        #8:#7          // j:I
  #22 = Utf8               homo/efficio/jvm/sample/StaticInitSample
  #23 = Utf8               java/lang/Object
{
  public static final int i;
    descriptor: I
    flags: ACC_PUBLIC, ACC_STATIC, ACC_FINAL

  public homo.efficio.jvm.sample.StaticInitSample();
    descriptor: ()V
    flags: ACC_PUBLIC
    Code:
      stack=1, locals=1, args_size=1
         0: aload_0
         1: invokespecial #1                  // Method java/lang/Object."<init>":()V
         4: return
      LineNumberTable:
        line 3: 0
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
            0       5     0  this   Lhomo/efficio/jvm/sample/StaticInitSample;

  static {};
    descriptor: ()V
    flags: ACC_STATIC
    Code:
      stack=1, locals=0, args_size=0
         0: bipush        11
         2: putstatic     #2                  // Field i:I
         5: bipush        22
         7: putstatic     #3                  // Field j:I
        10: return
      LineNumberTable:
        line 8: 0
        line 14: 5
        line 15: 10
}
SourceFile: "StaticInitSample.java"
```

상수 풀의 16번째 항목에 `#16 = Utf8               <clinit>`가 1개 있고, 아래 코드 내용의 `static {};` 아래 부분에 i를 1로, j를 2로 초기화 하는 부분이 소스코드에는 별개의 static 블록에 있었는데 바이트코드에서는 하나로 합쳐저 있음을 확인할 수 있다.

### 초기화 정리

링크 단계 다음에 수행되는 초기화 단계를 정리해보면 다음과 같다.

>**초기화는 바이트코드에서 `<clinit>`으로 표시되는 `클래스 또는 인터페이스 초기화 메서드`(자바 소스 코드의 static 블록을 하나로 합친 것)를 실행하는 것**을 의미한다.
>
>**링크 단계 이후에 수행되는 초기화란 결국 정적 초기화를 의미**한다.

다시 원래의 예제 코드인 Hello로 돌아와보자. Hello에는 정적 필드가 없으므로 초기화 과정에서 따로 수행되는 것은 없다. 초기화 과정까지 마쳤으면 이제 드디어 JVM에 의해 main 메서드가 호출될 차례다.


# main 메서드 호출

앞서 설명한 로딩, 링크, 초기화 과정은 바이트코드 내용 기준, 즉 클래스 단위의 정적인 준비를 다뤘는데, main 메서드 호출부터는 실제 프로그램의 동적인 실행이 일어난다. 프로그램이 실행되려면 프로그램 흐름의 최소 단위인 스레드가 있어야 한다. **JVM이 main 메서드 호출을 위한 main 스레드를 생성**한다. 

## main 스레드 생성

**스레드가 생성되면 PC 레지스터, JVM 스택, 네이티브 메서드 스택이 함께 생성**되고, 런타임 데이터 영역은 대략 다음과 같아진다.

![Imgur](https://i.imgur.com/izWNxMs.png)

## PC Register

[PC 레지스터](https://docs.oracle.com/javase/specs/jvms/se11/html/jvms-2.html#jvms-2.5.1)에는 현재 실행 중인 메서드가 

- 네이티브 메서드가 아니면 **현재 실행 중인 JVM 명령어의 위치가 저장**되고, 
- 네이티브 메서드이면 PC 레지스터에 저장되는 값은 정의되지 않는다(undefined).

## JVM Stack

[JVM 스택](https://docs.oracle.com/javase/specs/jvms/se11/html/jvms-2.html#jvms-2.5.2)은 LIFO(Last In First Out) 방식으로 동작하는 자료구조서 **JVM 스택에는 프레임이 저장**된다.

### Frame

JVM 스택에 쌓이는 정보의 단위가 [프레임(Frame)](https://docs.oracle.com/javase/specs/jvms/se11/html/jvms-2.html#jvms-2.6)이다. 프레임은 데이터나 중간 결과의 저장, 동적 링크, 값 반환, 예외 디스패치에 사용된다.

**메서드 하나가 호출될 때마다 새 프레임이 생성되어 스택에 쌓이고, 메서드 호출이 정상 완료되거나 예외가 던져지면 프레임은 스택에서 빠지면서 소멸된다.**

**프레임은 로컬 변수 배열, 오퍼랜드 스택, 프레임에 해당하는 메서드가 속한 클래스의 런타임 상수 풀에 대한 참조 이렇게 3개의 자료구조로 구성**된다.

![Imgur](https://i.imgur.com/uV7vHx5.png)

#### Local Variables

프레임은 [로컬 변수 배열(Local Variables](https://docs.oracle.com/javase/specs/jvms/se11/html/jvms-2.html#jvms-2.6.1)을 하나 가지고 있다. 로컬 변수 배열의 크기는 컴파일 타임에 결정되며 바이트코드의 `Code` 속성에 `locals`으로 표시된다.

`boolean`, `byte`, `char`, `short`, `int`, `float`, `reference`, `returnAddress`는 배열의 1개의 슬롯에 저장되고, `long`과 `double`은 2개의 슬롯에 걸쳐 저장된다.

메서드가 호출될 때 그 **메서드의 파라미터 값은 로컬 변수 배열을 통해 넘겨진다.**

- 메서드가 **클래스 메서드이면 첫 번째 파라미터는 0번 슬롯에 두 번째 파라미터는 1번 슬롯에 차례대로 저장**되고, 
- 메서드가 **인스턴스 메서드이면 `this`가 0번 슬롯에 먼저 저장되고, 첫 번째 파라미터는 1번 슬롯에, 두 번째 파라미터는 2번 슬롯에 차례대로 저장**된다.

파이썬은 인스턴스 메서드 호출 시 첫 인자로 `self`를 항상 넘겨주는데, 자바에서는 소스 코드에 직접 명시하지 않아도 컴파일러가 바이트코드를 생성할 때 `this`에 대한 심볼릭 참조를 로컬 변수 배열의 0번 슬롯에 넣어준다. 바이트코드의 `Code` 속성으로 표시되는 메서드의 바이트코드를 보면 다음과 같이 `LocalVariableTable`에 `this`에 대한 정보가 표시되는 것을 볼 수 있다.

```java
  public homo.efficio.jvm.sample.Hello();
    descriptor: ()V
    flags: (0x0001) ACC_PUBLIC
    Code:
      stack=1, locals=1, args_size=1
         0: aload_0
         1: invokespecial #1                  // Method java/lang/Object."<init>":()V
         4: return
      LineNumberTable:
        line 3: 0
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
            0       5     0  this   Lhomo/efficio/jvm/sample/Hello;  // <== 여기!!
```

#### Operand Stack

**프레임은 [오퍼랜드 스택(Operand Stack)](https://docs.oracle.com/javase/specs/jvms/se11/html/jvms-2.html#jvms-2.6.2)을 하나 가지고 있다.** 오퍼랜드 스택의 최대 깊이는 컴파일 타임에 결정되며 바이트코드의 `Code` 속성에 `stack`으로 표시된다.

오퍼랜드 스택은 프레임이 생성될 때는 비어있다. 오퍼랜드 스택에 상수, 로컬 변수, 필드를 쌓는 명령어와 오퍼랜드 스택에서 값을 꺼내서 연산을 하고 다시 스택에 넣는 명령어는 JVM 명령어로 제공되며 그 중에서 Hello 예제 코드에 사용된 JVM 명령어에 대한 설명은 앞으로 차차 알아보기로 하자. 

메서드에 전달되는 파라미터를 준비하거나 메서드가 반환해주는 결과값을 받을 때도 오퍼랜드 스택이 사용되며 **단순하게 표현하면 값을 가져오고 넘겨주는 거의 모든 과정에 오퍼랜드 스택이 사용된다고 볼 수 있다.**

#### Reference to Run-Time Constant Pool

런타임 상수 풀에 대한 참조는 말 그대로 **해당 프레임에 대응되는 메서드가 속한 클래스의 런타임 상수 풀에 대한 참조**를 의미한다.  
스펙에서 별도의 항목으로 기술되어 있지는 않고, [프레임의 설명 부분에서 언급](https://docs.oracle.com/javase/specs/jvms/se11/html/jvms-2.html#jvms-2.6)되고 있다.

하나의 스레드에서 여러 인스턴스의 메서드를 실행할 수 있고, 그때마다 프레임이 생성되어 JVM 스택에 쌓이고, **프레임에서 해당 클래스의 런타임 상수 풀에 있는 정보를 사용하려면 이 참조가 있어야 한다.**

위 그림에서는 하나의 예로 Hello 클래스의 런타임 상수 풀을 가리키도록 표현했을 뿐이고, 프레임에 따라 각각 다른 클래스의 런타임 상수 풀을 가리키게 된다.


## Native Method Stack

[네이티브 메서드 스택(Native Method Stack)](https://docs.oracle.com/javase/specs/jvms/se11/html/jvms-2.html#jvms-2.5.6)은 JVM 스택이 아닌 보통 C 스택이라고 부르는 전통적인 스택이며, 자바가 아닌 다른 언어로 작성된 네이티브 메서드를 지원하기 위해 사용되는 스택이다. 네이티브 메서드 스택은 JVM 스택과 마찬가지로 스레드 단위의 자료구조다.

JVM이 반드시 네이티브 메서드를 지원해야 하는 것은 아니므로 네이티브 메서드 스택 역시 필수는 아니다. 

## main 메서드 호출

이제 JVM의 런타임 데이터 영역을 구성하는 요소들에 대한 정적인 설명을 모두 알아봤으므로 실제 main 메서드 호출과 함께 변화 과정을 동적으로 알아보자.

main 메서드의 바이트코드는 다음과 같다.

```java
  public static void main(java.lang.String[]);
    descriptor: ([Ljava/lang/String;)V
    flags: (0x0009) ACC_PUBLIC, ACC_STATIC
    Code:
      stack=2, locals=2, args_size=1
         0: new           #2                  // class homo/efficio/jvm/sample/Hello
         3: dup
         4: invokespecial #3                  // Method "<init>":()V
         7: astore_1
         8: getstatic     #4                  // Field java/lang/System.out:Ljava/io/PrintStream;
        11: aload_1
        12: invokevirtual #5                  // Method helloMessage:()Ljava/lang/String;
        15: invokevirtual #6                  // Method java/io/PrintStream.println:(Ljava/lang/String;)V
        18: goto          18
      LineNumberTable:
        line 6: 0
        line 7: 8
        line 8: 18
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
            0      21     0  args   [Ljava/lang/String;
            8      13     1 hello   Lhomo/efficio/jvm/sample/Hello;
      StackMapTable: number_of_entries = 1
        frame_type = 252 /* append */
          offset_delta = 18
          locals = [ class homo/efficio/jvm/sample/Hello ]
```

오퍼랜드 스택의 최대 크기는 2, 로컬 변수 배열 크기는 2, 인자 갯수는 1이다.

main 메서드가 호출되면 다음과 같이 `main 메서드 프레임`이 생성된다. 오퍼랜드 스택과 로컬 변수 배열은 비어있는 상태이고, 런타임 상수 풀에 대한 참조는 Hello 클래스의 런타임 상수 풀을 가리킨다. 

오퍼랜드 스택은 최대 크기가 2이고 아직 아무 것도 쌓여있지 않은 상태이므로 점선으로 표시했고, 로컬 변수 배열은 안에 값은 없지만 2개의 슬롯이 확정적으로 만들어져있으므로 실선으로 표시했다.

![Imgur](https://i.imgur.com/O7LRpA6.png)

### `0: new #2  // class homo/efficio/jvm/sample/Hello`

[`new`](https://docs.oracle.com/javase/specs/jvms/se11/html/jvms-6.html#jvms-6.5.new)는 인자로 지정된 클래스의 새 인스턴스에 필요한 메모리를 힙 안에 할당하고, 할당된 위치를 가리키는 참조를 오퍼랜드 스택에 쌓는다. 이 때 인스턴스 변수들이 기본값으로 초기화 된다. 참고로 인스턴스 변수가 아닌 정적 변수는 앞서 초기화 과정에서 이미 특정값으로 초기화 되어 있는 상태다.

Hello 클래스의 새 인스턴스에 필요한 메모리를 할당하고 그 위치에 대한 참조를 오퍼랜드 스택에 쌓는다. (파란색 동그라미)

![Imgur](https://i.imgur.com/e6u8VRO.png)

### `3: dup`

[`dup`](https://docs.oracle.com/javase/specs/jvms/se11/html/jvms-6.html#jvms-6.5.dup)은 오퍼랜드 스택 맨 위에 있는 값을 복사해서 오퍼랜드 스택 맨 위에 쌓는다.(초록색 동그라미)

![Imgur](https://i.imgur.com/Ve6moKN.png)

### `4: invokespecial #3  // Method "<init>":()V`

[`invokespecial`](https://docs.oracle.com/javase/specs/jvms/se11/html/jvms-6.html#jvms-6.5.invokespecial)은 다음과 같이 생성자, 현재 클래스, 수퍼클래스의 메서드를 호출한다고 나와 있다. 

>invokespecial
>
>Operation  
>  Invoke instance method; direct invocation of instance initialization methods and methods of the current class and its supertypes

그래서 private 메서드를 호출할 때 `invokespecial`이 사용된다고 써있는 자료도 흔히 볼 수 있는데, 막상 `javac`, `javap`로 확인해보면 현실은 좀 다르다. 대부분 생성자와 수퍼클래스의 생성자를 호출할 때 `invokespecial`이 사용되고, 상속받은 클래스에서 수퍼클래스의 메서드를 호출할 때와, 같은 클래스 내의 다른 private 인스턴스 메서드를 호출할 때는 `invokevirtual`이 사용된다. 

`invokespecial`로 특정 메서드가 호출되면 프레임과 로컬 변수 배열, 오퍼랜드 스택, 런타임 상수 풀에 대한 참조가 생겨난다. 호출하는 쪽의 오퍼랜드 스택에서 호출되는 메서드의 파라미터 갯수 + 1개 만큼 호출하는 쪽의 오퍼랜드 스택에서 값을 꺼내서 호출되는 쪽에 새로 생성된 로컬 변수 배열의 0번 슬롯까지 채워지도록 뒤에서부터 차례로 채운다.

글로는 복잡하니 그림으로 보자. 새로 호출하는 메서드의 파라미터가 2개라면 다음과 같이 진행된다. 먼저 호출하기 전 상태는 다음과 같다.

![Imgur](https://i.imgur.com/jQIe28m.png)

파라미터 2개 있는 메서드를 호출하면 다음과 같이 새로 프레임이 생성되고, 호출하는 쪽의 오퍼랜드 스택에서 2 + 1인 3개의 값이 차례로 꺼내져서, 호출되는 쪽의 로컬 변수 배열의 2, 1, 0번 슬롯에 차례로 저장된다.

![Imgur](https://i.imgur.com/YJBfT4H.png)

파라미터 갯수인 2개 외에 마지막에 추가로 하나 더 꺼내져서 호출되는 프레임의 로컬 변수 배열 0번 슬롯에 저장되는 값(초록색 동그라미)은 스펙에 `objectref`라고 표현되어 있으며 반드시 참조값이어야 한다.

지금 설명한 호출하는 쪽의 프레임의 오퍼랜드 스택에서 값을 꺼내서 호출되는 쪽의 프레임의 로컬 변수 배열에 저장하는 방식은 `invokespecial` 뿐 아니라 [`invokevirtual`](https://docs.oracle.com/javase/specs/jvms/se11/html/jvms-6.html#jvms-6.7.invokevirtual)에도 공히 적용되는 방식이다.

스택 맨 위에 있는 Hello 인스턴스에 대한 참조(초록색 동그라미)를 꺼내서 Hello 클래스의 디폴트 생성자의 첫 번째 인자로 넘기면서 디폴트 생성자를 호출한다. Hello 클래스의 디폴트 생성자에 대한 프레임(`Hello 생성자 프레임`)이 새로 생성되고 JVM 스택의 맨 위(`main 메서드 프레임` 위)에 쌓인다. `Hello 생성자 프레임` 안에 있는 로컬 변수 배열의 0번 슬롯에 새 Hello 인스턴스에 대한 참조가 저장된다. 

![Imgur](https://i.imgur.com/jvvanVL.png)

Hello 생성자의 바이트코드는 다음과 같다.

```java
   public homo.efficio.jvm.sample.Hello();
     descriptor: ()V
     flags: (0x0001) ACC_PUBLIC
     Code:
       stack=1, locals=1, args_size=1
          0: aload_0
          1: invokespecial #1                  // Method java/lang/Object."<init>":()V
          4: return
       LineNumberTable:
         line 3: 0
       LocalVariableTable:
         Start  Length  Slot  Name   Signature
             0       5     0  this   Lhomo/efficio/jvm/sample/Hello;
```

`Code` 속성 바로 아래줄에 `stack=1, locals=1, args_size=1`라고 되어 있는데, `Hello 생성자 프레임`의 오퍼랜드 스택 최대 깊이는 1, 로컬 변수 배열의 크기는 1, 인자의 갯수는 1개로 되어 있다. 오퍼랜드 스택 최대 깊이와 로컬 변수 배열의 크기는 위 그림에 적용되어 있다.

Hello 생성자 프레임이 생성되면 가장 위에 있는 명령어인 `aload_0`이 먼저 실행된다.

#### `0: aload_0`

[`aload_n`](https://docs.oracle.com/javase/specs/jvms/se11/html/jvms-6.html#jvms-6.5.aload_n)은 로컬 변수 배열의 `n`번 슬롯에 저장된 참조값(load 앞에 붙은 `a`가 참조값을 의미)을 오퍼랜드 스택 맨 위에 쌓는다.

`Hello 생성자 프레임`의 로컬 변수 배열의 0번 슬롯에 저장되어 있던 새 Hello 인스턴스에 대한 참조(초록색 동그라미)가 `Hello 생성자 프레임`의 오퍼랜드 스택에 쌓인다.

![Imgur](https://i.imgur.com/zP0BaqB.png)

#### `1: invokespecial #1  // Method java/lang/Object."<init>":()V`

`invokespecial` 명령어에 대한 설명은 앞에서 알아봤으므로 생략한다. 

Object의 생성자를 호출하면 힙에 Object의 새 인스턴스를 위한 메모리가 할당되고, `Object 생성자 프레임`이 생성된다.

`Hello 생성자 프레임`의 오퍼랜드 스택 맨 위에 있던 `this`(초록색 동그라미)가 꺼내지고 새로 생성된 `Object 생성자 프레임`의 로컬 변수 배열의 0번 슬롯에 저장(초록색 동그라미)된다.

![Imgur](https://i.imgur.com/Dw4W7or.png)

Object의 생성자의 바이트코드는 다음과 같다.

>javap -v -p -s java.lang.Object

```java
  public java.lang.Object();
    descriptor: ()V
    flags: (0x0001) ACC_PUBLIC
    Code:
      stack=0, locals=1, args_size=1
         0: return
      LineNumberTable:
        line 50: 0
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
            0       1     0  this   Ljava/lang/Object;
    RuntimeVisibleAnnotations:
      0: #27()
        jdk.internal.HotSpotIntrinsicCandidate
```

설명하는 입장에서 매우 다행스럽게도 그냥 `4: return` 하는 것이 전부다. [`return`](https://docs.oracle.com/javase/specs/jvms/se11/html/jvms-6.html#jvms-6.5.return)은 void를 반환하며, 오퍼랜드 스택에 있던 모든 값이 전부 폐기되고 `Object 생성자 프레임`도 폐기되고, 호출한 메서드의 프레임인 `Hello 생성자 프레임`으로 제어가 넘어간다.

![Imgur](https://i.imgur.com/1XJNvOY.png)

Hello의 디폴트 생성자의 바이트코드에서 남은 것은 `return`뿐이다. 따라서 Hello의 디폴트 생성자 실행이 완료되면 `Hello 생성자 프레임도 폐기`되고 다음과 같이 `main 메서드 프레임`의 오퍼랜드 스택에는 아래와 같이 새로 생성 및 초기화된 Hello 인스턴스에 대한 참조만 남게 된다.

![Imgur](https://i.imgur.com/lEsyaU9.png)

### `7: astore_1`

[`astore_n`](https://docs.oracle.com/javase/specs/jvms/se11/html/jvms-6.html#jvms-6.5.astore_n)은 오퍼랜드 스택의 맨 위에 있는 값을 꺼내서 로컬 변수 배열의 `n` 위치에 저장한다. 

현재 `main 메서드 프레임`의 오퍼랜드 스택 맨 위에 있는 값인 새 Hello 인스턴스에 대한 참조(`this`)를 꺼내서 `main 메서드 프레임`의 로컬 변수 배열의 1번 슬롯에 넣는다.

결국 로컬 변수에 뭔가 저장하는 것인데 자바 소스 코드의 `final Hello hello = new Hello();`에 해당한다.

![Imgur](https://i.imgur.com/ZOUyk7M.png)

### `8: getstatic #4  // Field java/lang/System.out:Ljava/io/PrintStream;`

[`getstatic`](https://docs.oracle.com/javase/specs/jvms/se11/html/jvms-6.html#jvms-6.5.getstatic)은 클래스의 정적(static) 필드 값을 가져와서 오퍼랜드 스택에 쌓는다.

여기에서는 System 클래스의 정적 변수인 out의 값을 System의 런타임 상수 풀에서 읽어서 `main 메서드 프레임`의 오퍼랜드 스택에 쌓는다. (초록색 동그라미)

![Imgur](https://i.imgur.com/guTnj4t.png)

### `11: aload_1`

`aload_1`은 `main 메서드 프레임`의 로컬 변수 배열 1번 슬롯에 있던 값을 `main 메서드 프레임`의 오퍼랜드 스택에 쌓는다. (파란색 동그라미)

![Imgur](https://i.imgur.com/fU90B7m.png)

### `12: invokevirtual #5  // Method helloMessage:()Ljava/lang/String;`

[`invokevirtual`](https://docs.oracle.com/javase/specs/jvms/se11/html/jvms-6.html#jvms-6.5.invokevirtual)은 자바 메서드 호출의 기본 방식이며, 객체 참조(obj.)를 붙여서 호출되는 일반적인 메서드를 호출한다. 해당 메서드가 속한 인스턴스를 가리키는 참조가 첫 번째 파라미터로 넘겨진다. 호출에 의해 새 프레임이 생성되고 로컬 변수 배열의 0번 슬롯에 첫 번째 인자로 넘어온 값인 해당 메서드가 속한 인스턴스를 가리키는 참조가 저장되고 그 이후의 인자도 로컬 변수 배열에 순서대로 저장된다. 앞에서 `invokespecial`에 나왔던 그림 설명을 참고한다.

`helloMessage()`의 바이트코드는 다음과 같다.

```java
   public java.lang.String helloMessage();
     descriptor: ()Ljava/lang/String;
     flags: (0x0001) ACC_PUBLIC
     Code:
       stack=1, locals=1, args_size=1
          0: ldc           #7                  // String Hello, JVM
          2: areturn
       LineNumberTable:
         line 12: 0
       LocalVariableTable:
         Start  Length  Slot  Name   Signature
             0       3     0  this   Lhomo/efficio/jvm/sample/Hello;
```

`helloMessage()`가 호출되면 `helloMessage 메서드 프레임`이 새로 생성되고, `main 메서드 프레임`의 오퍼랜드 스택 맨 위에 있던 값(파란 동그라미)이 꺼내져서 `helloMessage 메서드 프레임`의 로컬 변수 배열 0번 슬롯에 저장된다.

![Imgur](https://i.imgur.com/ZbJ4ISa.png)

#### `0: ldc #7  // String Hello, JVM`

[`ldc`](https://docs.oracle.com/javase/specs/jvms/se11/html/jvms-6.html#jvms-6.5.ldc)는 런타임 상수 풀의 항목 하나를 오퍼랜드 스택의 맨 위에 쌓는다.

Hello 클래스의 런타임 상수 풀의 7번 항목인 문자열 리터럴 `"Hello, JVM"`에 대한 참조를 `helloMessage 메서드 프레임`의 오퍼랜드 스택 맨 위에 쌓는다.

문자열 리터럴이 저장되는 문자열 풀(String pool)은 JVM 스펙을 뒤져봤으나 찾을 수 없었다. http://java-performance.info/string-intern-in-java-6-7-8/ 에 따르면 문자열 풀은 Java 6까지는 힙이 아닌 PermGen 영역에 있었지만, Java 7부터 힙에 존재한다고 한다.

따라서 스펙에서 확인한 내용은 아니지만 Java 11에서도 문자열 풀은 힙에 존재한다고 보면 다음과 같이 표현할 수 있다.

![Imgur](https://i.imgur.com/NCga0nz.png)

#### `2: areturn`

[`areturn`](https://docs.oracle.com/javase/specs/jvms/se11/html/jvms-6.html#jvms-6.5.areturn)은 오퍼랜드 스택 맨 위에 있는 참조값(return 앞에 있는 `a`가 참조값을 의미)을 꺼내서 호출한 메서드 프레임의 오퍼랜드 스택 맨 위에 저장하고, `areturn`이 속한 프레임을 폐기하고 제어를 호출한 메서드 프레임으로 넘겨준다.

`helloMessage 메서드 프레임`의 오퍼랜드 스택 맨 위에 있던 값은 `"Hello, JVM"`에 대한 참조이며 이 값을 `main 메서드 프레임`의 오퍼랜드 스택 맨 위에 쌓는다. 결국 **메서드가 값을 반환한다는 것은 호출된 프레임의 오퍼랜드 스택 맨 위의 값을 꺼내서 호출한 프레임의 오퍼랜드 스택 맨 위에 저장하는 것**을 의미한다.

![Imgur](https://i.imgur.com/vz0uuaf.png)

### `15: invokevirtual #6  // Method java/io/PrintStream.println:(Ljava/lang/String;)V`

PrintStream 클래스의 println(String)의 바이트코드는.. 매우 길다.. 어차피 `invokevirtual`은 앞에서 살펴봤고 그 외에 오퍼랜드 스택이나 로컬 지역 변수의 변화 과정을 앞에서 계속 봐왔으므로, println(String)은 결과만 보자.

`main 메서드 프레임`의 오퍼랜드 스택에 있던 System.out에 대한 참조와 `"Hello, JVM"`에 대한 참조는`invokevirtual`로 System.out.println(String)을 호출하면서 모두 꺼내지고`main 메서드 프레임`의 오퍼랜드 스택은 비워진다. `println 메서드 프레임`이 새로 생성되고 인자로 전달받은 참조를 활용해서 "Hello, JVM"을 화면에 출력하고, `println 메서드 프레임`은 폐기된 후의 모습은 다음과 같다.

![Imgur](https://i.imgur.com/BWa4gBm.png)

### `18: goto 18`

[`goto`](https://docs.oracle.com/javase/specs/jvms/se11/html/jvms-6.html#jvms-6.5.goto)는 오퍼랜드 스택의 변화 없이 특정 행으로 실행 흐름을 이동시킨다.

18행에서 18행으로 계속 이동하면 결국 무한루프다. 자바 소스 코드의 `while(true) {}`가 여기에 해당된다.


# 마무리

여기까지 바이트코드 흐름에 따라 JVM의 런타임 데이터 영역 내의 자료구조들이 어떻게 변화하는지 살펴봤다. 사실 몰라도 일반적인 개발을 하는데 거의 지장이 없다시피한 내용이라서 그림 한땀한땀 그리고 고치고를 반복할 때마다 내가 이 짓을 왜하고 있나.. 이쯤에서 그만두자.. 하는 생각이 든 게 한 두번이 아니었.. ㅠㅜ 

그래도 인터넷 어디를 뒤져봐도 자바 프로그램의 실행 과정에 대해 이보다 친절한 설명은 없으리라..

>JVM에서 실행되는 프로그램(class파일)을 실행하면 JVM이 기동된다.
>
>JVM이 기동되면 힙(Heap)과 메서드 영역(Method Area)가 생성된다.
>
>프로그램 실행에 필요한 시작 클래스의 바이트코드가 클래스로더를 통해 로딩되어 메서드 영역에 저장된다.  
>이 때 바이트코드에 있던 상수 풀의 내용을 바탕으로 런타임 상수 풀이 클래스 단위로 만들어져 메서드 영역에 함께 저장된다.
>
>링크(확인, 준비, 해석)를 통해 Object 등 프로그램 실행에 필요한 다른 클래스들이 로딩되고 필요하다면 정적으로 초기화 된다.
>
>시작 클래스의 main 메서드 실행을 위한 main 스레드가 생성된다.
>
>main 스레드가 생성되면 PC 레지스터, JVM 스택, 네이티브 메서드 스택이 한 개씩 main 스레드에 생성된다.  
>JVM 스택이 생성되면 main 메서드를 위한 main 메서드 프레임이 생성된다.  
>main 메서드 프레임이 생성되면 로컬 변수 배열, 오퍼랜드 스택, 런타임 상수 풀에 대한 참조가 한 개씩 main 메서드 프레임에 생성된다.
>
>main 메서드의 내용에 따라 로컬 변수 배열, 오퍼랜드 스택, 런타임 상수 풀에 대한 참조를 이용해서 필요한 값이나 참조를 연산하고,  
>메서드 호출이 발생하면 해당 메서드를 위한 새 로컬 변수 배열, 오퍼랜드 스택, 런타임 상수 풀에 대한 참조가 포함된 새 프레임이 생성되어 JVM 스택 위에 쌓이고,  
>메서드 호출이 종료되면 해당 프레임이 JVM 스택에서 빠져나가고 제어는 다시 호출한 메서드의 프레임으로 돌아온다.  
>이 때 반환값이 있다면 호출한 메서드의 프레임의 오퍼랜드 스택의 맨 위에 쌓인다.
>
>한 장의 그림으로 보면 다음과 같다.
>
>![Imgur](https://i.imgur.com/So2s54L.png)


## 마지막 쉬운 퀴즈

다음과 같은 코드를 실행하면 HelloNoInstance 인스턴스가 힙에 만들어질까 안 만들어질까?

```java
package homo.efficio.jvm.sample;

public class HelloNoInstance {

    public static void main(String[] args) {
        System.out.println("Hello, JVM");
        while (true) {}
    }
}
```

클래스 이름에 답이 있지만 HelloNoInstance 인스턴스는 힙에 만들어지지 않는다. 아래는 VisualVM으로 힙 덤프를 떠서 확인한 그림이다.

![Imgur](https://i.imgur.com/S0cm4E8.png)

참고로 Java 11 기준으로 간단한 헬로월드 프로그램이 수행되는데 로딩되는 클래스의 수는 몇 개일까? 이건 직접 알아보기로 하자. ^^


