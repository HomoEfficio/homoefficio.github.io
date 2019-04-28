title: Java NIO는 생각만큼 non-blocking 하지 않다
date: 2016-08-06 15:49:16
categories:
  - Technique
tags:
  - Java
  - I/O
  - NIO
  - Stream
  - Channel
  - performance
  - 자바
  - 스트림
  - 채널
  - 성능
thumbnailImage: http://www.allitebooks.com/wp-content/uploads/2016/03/Java-IO-NIO-and-NIO.2.jpg
coverImage: coverImage-blocking.jpg
---
일부러 낚시 냄새가 독하게 풍기는 제목을 지어봤다.

**Java NIO는 New IO의 줄임말**인데, **Non-blocking IO 의 줄임말이라고 알고 있는 개발자도 많은 것 같다.**(나도 그랬다..) 

그만큼 NIO는 Non-blocking이라는 마케팅이 꽤나 열심이었고, 또 그게 잘 먹혔기 때문인지, File I/O를 사용할 때마저 기존의 IO 방식 대신 NIO를 쓰면 Non-blocking이라서 좋다는 글도 많다. 그냥 그런가보다.. 했는데 알고보니 그렇지 않더라는..


# IO : NIO = Stream : Channel

옛날에 적성검사나 카투사 시험에서 다음과 같은 유형의 문제와 자주 맞닥뜨렸던 기억이 있다.

```
고모 : 이모 = 아빠 : ?
```

```
아빠 : 형 = ? : 누나
```
뭐랄까.. 가족계보를 선형대수로 알싸하게 풀어낸, 실로 참신하고 현란하기 그지 없는 문제들이다.

IO와 NIO의 관계도 위와 같은 현란한 비례식으로 생각해보면 머리에 조금이라도 더 남을 수 있을 것만 같다. 특히나 `IO : NIO = Blocking : Non-blocking` 이라는, 조금 섣부른 넘겨집기에서 나온 비례식은 아래와 같이 바꾸는 것이 좋을 것 같다.

>**IO : NIO = Stream : Channel**

잔말이 많았는데, IO와 NIO가 뭐가 다른지 알려면 `Stream`과 `Channel`의 차이점을 먼저 알아야 한다.

# Stream vs Channel

기존의 Stream은 읽을 때와 쓸 때 `InputStream`과 `OutputStream`으로 구분해서 사용했다. Stream을 통해 흘러다니는 데이터는 기본적으로는 `byte` 또는 `byte[]`이고, 읽고 쓰는 작업을 지시한 후에는 그 작업이 끝나야 return 되는 bloking 방식이다.

Channel은 데이터가 흘러다니는 통로라는 점에서 Stream과 역할은 비슷하지만 동작 방식이 다르다. 

단방향인 Stream과는 달리 Channel은 양방향이라서 intput/output을 구분하지 않고 그냥 `ByteChannel`, `FileChannel`를 만들어서 읽을 수도 있고, 쓸 수도 있다.

Channel은 언제나 `Buffer`를 통해서만 데이터를 읽거나 쓸 수 있다. Channel에서 데이터를 읽으면 Buffer에 담아야만 어떤 처리를 할 수 있고, Channel에 데이터를 쓰려면 먼저 Buffer에 담고, Buffer에 담긴 데이터를 Channel에 써야 한다.

Channel은 Non-blocking 방식도 가능하다. 다시 말하지만, **Channel을 사용하는 I/O는 언제나 Non-blocking 방식으로 동작하는 것이 아니라, Non-blocking 방식도 가능하다**는 것이다.

정리하면 아래와 같다.

Stream | Channel
----|----
one-way(InputStream or OutputStream)|two-way(Channel)
구현체에 따라 primitive부터 object까지 가능하나, 기본적으로는 byte 또는 byte[]|Buffer
Blocking|Non-bloking**도 가능** (언제나 Non-blocking인 것이 아니라)


# Files.new\~\~()는 모두 blocking이다.

`java.nio.Files`는 NIO 중에서 File I/O를 담당하는데, 결론부터 말하면,

>파일을 읽는데 사용되는 `Files.newBufferedReader()`, `Files.newInputStream()` 등은 모두 blocking이다.
>
>파일을 쓰는데 사용되는 `Files.newBufferedWriter()`, `Files.newOutputStream()` 등도 모두 blocking이다.

진짜?

위 메서드들은 결국 `Files.newByteChannel()`을 통해 생성되는 `SeekableByteChannel`을 바탕으로 데이터를 읽거나 쓰게 되는데, 이 `SeekableByteChannel`은 `ReadableByteChannel`과 `WritableByteChannel`을 구현하고 있다.

그런데 `ReadableByteChannel`과 `WritableByteChannel`은 모두 **blocking 모드로만 동작하는 Channel**이다.

근거는? Java API에 다음과 같이 적혀 있다.

https://docs.oracle.com/javase/8/docs/api/java/nio/channels/ReadableByteChannel.html

>Interface ReadableByteChannel
>
>Only one read operation upon a readable channel may be in progress at any given time. **If one thread initiates a read operation upon a channel then any other thread that attempts to initiate another read operation will block until the first operation is complete.** Whether or not other kinds of I/O operations may proceed concurrently with a read operation depends upon the type of the channel.

https://docs.oracle.com/javase/8/docs/api/java/nio/channels/WritableByteChannel.html

>Interface WritableByteChannel
>
>A channel that can write bytes.
Only one write operation upon a writable channel may be in progress at any given time. **If one thread initiates a write operation upon a channel then any other thread that attempts to initiate another write operation will block until the first operation is complete.** Whether or not other kinds of I/O operations may proceed concurrently with a write operation depends upon the type of the channel.

결국 NIO 중에서 File I/O에 관련된 것들은 아쉽지만 모두 blocking인 것이다.

`Files.new~~()` 외에 `Files.lines()`, `Files.readAllLines()`, `Files.readAllBytes()`, `Files.write()`도 위에 설명한 것과 마찬가지 이유로 모두 blocking이다.


# 어차피 blocking인데 File I/O에 뭐하러 NIO를 써?

## 성능

File I/O에 사용되는 Channel이 blocking 모드로 동작하기는 하지만, 데이터를 `Buffer`를 통해 이동시키므로써 **기존의 Stream I/O에서 병목을 유발하는 몇가지 레이어를 건너뛸 수 있다**고 한다.(https://docs.oracle.com/javase/tutorial/essential/io/file.html)

더 구체적으로는 `Buffer`를 사용하면 DMA를 활용할 수 있다는 건데, [여기에 한글로](http://eincs.com/2009/08/java-nio-bytebuffer-channel-file/) 아주 설명이 잘 되어있다.

그리고 NIO를 쓰는 게 낫다는 자료는 인터넷에서 쉽게 찾을 수 있다. 

하지만 성능 관련 내용이 이렇게 명백하게 갈릴리가..
참고로 다음과 같은 반론도 있다.

- http://mailinator.blogspot.kr/2008/02/kill-myth-please-nio-is-not-faster-than.html
- http://paultyma.blogspot.kr/2008/03/writing-java-multithreaded-servers.html

## 기능

기존의 java.io.File에는 기능적으로 다음과 같은 단점이 있다고 하니, 당연하지만 NIO를 쓸 수 있다면 쓰는 것이 좋다.(https://docs.oracle.com/javase/tutorial/essential/io/legacy.html#mapping)

- Many methods didn't throw exceptions when they failed, so it was impossible to obtain a useful error message. For example, if a file deletion failed, the program would receive a "delete fail" but wouldn't know if it was because the file didn't exist, the user didn't have permissions, or there was some other problem.
- The rename method didn't work consistently across platforms.
- There was no real support for symbolic links.
- More support for metadata was desired, such as file permissions, file owner, and other security attributes.
- Accessing file metadata was inefficient.
- Many of the File methods didn't scale. Requesting a large directory listing over a server could result in a hang. Large directories could also cause memory resource problems, resulting in a denial of service.
- It was not possible to write reliable code that could recursively walk a file tree and respond appropriately if there were circular symbolic links.

# Non-blocking은 그럼 구라?

아니다. NIO가 생각만큼 Non-blocking하지 않다는 것이지, Non-blocking이 구라라는 소리는 아니다.

## Non File I/O

File I/O가 아닌 것들은 Non-blocking 모드로 동작하는 것들도 많다.
`SelectableChannel`을 상속받거나 구현한 Channel은 Non-blocking 모드로 동작할 수 있다. 예를 들어, `DatagramChannel`, `Pipe.SourceChannel`, `SocketChannel`은 `ReadableByteChannel`과 `SelectableChannel`을 함께 구현하고 있어서 Non-blocking 모드로 읽는 것이 가능하다.


# File I/O에서는 정녕 Non-blocking은 없나?

있다. java 7 부터 도입되어 NIO2라고 불리는 NIO에는 `AsynchronousFileChannel`이 Non-blocking 모드로 동작한다. `AsynchronousFileChannel`은 별도의 글에서 다뤄본다.


# 정리

>- NIO는 Non-blocking IO의 줄임말이 아니다.
>- 특히, File I/O는 NIO에 포함된 `java.nio.Files` 클래스를 사용해도 여전히 blocking모드로 동작한다.
>- NIO에서의 File I/O가 기대와는 달리 blocking 모드로 동작한다고 해도, 기능/성능 상으로 유리한 점이 있으니 가능하다면 NIO를 쓰자(성능은 반론도 있기는 하다).

# 더 읽을거리

- Java NIO : http://www.slideshare.net/allnewangel/java-nio-23150417
- jenkov tutorials : http://tutorials.jenkov.com/java-nio/index.html
- java io tutorials : https://docs.oracle.com/javase/tutorial/essential/io/index.html
- open jdk nio : http://openjdk.java.net/projects/nio/
- [NIO] JAVA NIO의 ByteBuffer와 Channel로 File Handling에서 더 좋은 Perfermance 내기! : http://eincs.com/2009/08/java-nio-bytebuffer-channel-file/

