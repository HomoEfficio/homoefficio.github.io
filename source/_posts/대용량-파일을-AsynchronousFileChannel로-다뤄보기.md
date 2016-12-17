title: 대용량 파일을 AsynchronousFileChannel로 다뤄보기
date: 2016-08-13 02:18:37
categories:
  - Technique
tags:
  - Java
  - I/O
  - NIO
  - Stream
  - Channel
  - performance
  - Async
  - Asynchronous
  - AsynchronousFileChannel
  - 자바
  - 비동기
  - 비동기파일채널
  - 스트림
  - 채널
  - 성능
thumbnailImage: https://www.credera.com/wp-content/uploads/2014/08/Screen-Shot-2014-08-27-at-1.32.33-PM.png
coverImage: coverImage-sync-async.png
---

Java 7 에는 비동기 방식의 File I/O를 지원하는 `AsynchronousFileChannel`이 추가되었다.
 
비동기 방식이므로 File I/O에 소요되는 시간 동안 다른 처리를 할 수 있다는 장점이 있다.
 
![](http://i.imgur.com/641EZTR.png)
 
특히 용량이 큰 파일일 수록 File I/O에 소요되는 시간이 클 수 있으므로, 비동기 방식의 장점을 더 살릴 수 있다.
 
# `AsynchronousFileChannel`을 사용하는 일반적인 방법
 
`AsynchronousFileChannel`로 파일을 읽으려면 아래의 메서드를 사용하면 된다.
 
```java
public abstract <A> void read(ByteBuffer dst,
           long position,
           A attachment,
           CompletionHandler<Integer,? super A> handler)
```
 
`CompletionHandler`를 사용하는 대신 `Future`를 반환하는 `read()` 메서드도 있는데, ~~while (!result.isDone()) { ... } 와 같은 식으로 계속 완료 여부를 polling하는 Future 방식보다는~~(`Future`도 `Future.get()`을 사용하면 굳이 polling 하지 않아도 된다.) `CompletionHandler` 방식이 더 간지나므로 `Future` 방식은 여기서는 다루지 않는다.
 
암튼 API를 보니 파일의 `position` 위치에서 부터 읽은 데이터를 `dst` 라는 ByteBuffer에 담고, 성공/실패 시 `CompletionHandler`에 구현된 callback 메서드를 호출하는구나.. 라고 이해되는데, `attachment`는 뭘까? API문서에서도 그냥 아래와 같이 뜬구름 잡는 소리만 있다.
 
>attachment - The object to attach to the I/O operation; can be null
 
`attachment`가 뭔지 궁금하지만, `null` 일 수도 있다고 하니 일단 그냥 `null`로 둬보자.
 
## 일반적인 코드
 
nio의 `Channel`은 데이터의 I/O에 `byte[]` 대신 `Buffer`를 사용한다. `AsynchronousFileChannel`도 마찬가지로 `ByteBuffer`를 사용하며, `AsynchronousFileChannel`를 이용해서 파일을 읽어들이는 코드는 다음과 같다.
 
```java
private void asyncFileChannelTest(Path sourceFilePath, boolean isWrite) throws IOException {
 
    try (
            AsynchronousFileChannel asyncFileChannel = AsynchronousFileChannel.open(
                sourceFilePath,
                StandardOpenOption.READ
            );
    ) {
        System.err.println("AsynchronousFileChannel 테스트 시작");
 
        long startTime = System.nanoTime();
 
        long fileSize = asyncFileChannel.size();
 
        ByteBuffer byteBuffer = ByteBuffer.allocate((int)fileSize);
 
        System.err.println("AsynchronousFileChannel.read() 호출");
 
        asyncFileChannel.read(
            byteBuffer, 0, null,
            new CompletionHandler<Integer, Object>() {
 
                @Override
                public void completed(Integer result, Object object) {
                    if (result == -1) {
                        long endTime = System.nanoTime();
                        System.err.println("비정상 종료 : " + (endTime - startTime) + " ns elapsed.");
                        return;
                    }
 
                    byteBuffer.flip();
                    byteBuffer.mark();
                    if (isWrite) System.out.write(byteBuffer.array(), 0, result);
                    byteBuffer.reset();
 
                    long endTime = System.nanoTime();
                    System.err.println("AsynchronousFileChannel.read() 완료 : " + (endTime - startTime) + " ns elapsed.");
                }
 
                @Override
                public void failed(Throwable exc, Object object) {
                    exc.printStackTrace();
                }
            }
        );
 
        System.err.println("AsyncFileChannel I/O 진행 중에는 다른 작업도 할 수 있지롱");
        System.err.println("그동안 그리스에도 다녀오고");
        System.err.println("크로아티아에도 갔다오자");
    }
}
```
 
실행하면 다음과 같은 결과가 나온다.
 
```
AsynchronousFileChannel 테스트 시작
AsynchronousFileChannel.read() 호출
AsyncFileChannel I/O 진행 중에는 다른 작업도 할 수 있지롱
그동안 그리스에도 다녀오고
크로아티아에도 갔다오자
AsynchronousFileChannel.read() 완료 : 320668276 ns elapsed.
```
 
위에서 보는 것처럼 File I/O가 처리되는 시간 동안에도 메시지를 콘솔에 출력하는 것처럼 다른 작업을 수행할 수 있다.
 
한 가지 마음에 걸리는 것은 `ByteBuffer`의 크기를 파일 사이즈와 같게 한다는 점이다. 용량이 클수록 비동기 방식의 장점이 더 드러난다고는 하지만, 용량이 기가 단위로 정말 거대한 파일을 통으로 메모리에 모두 담아 처리하면 OutOfMemoryError를 유발할 수도 있다. 
 
![](http://i.imgur.com/26xMoli.png)
 
위의 그래프는 Java SDK에 번들로 제공되는 VisualVM을 사용해서 메모리 사용을 모니터링한 것인데, 160메가 정도의 파일로 테스트 해본 결과 위와 같이 메모리 사용이 쭈욱~ 올라간 것을 알 수 있다. 기가 단위의 파일이라면 역시나 OutOfMemoryError가 발생할 것 같다.
 
참고로 일반적인 `main()`으로 실행하면 금방 종료되어 위처럼 캡쳐 등이 불편해서, 편의상 간단하게 SpringBoot로 만든 웹 애플리케이션에서 테스트를 진행했다.
 
암튼 메모리 사용량을 적게 할 수 있도록 작은 크기의 `ByteBuffer`를 생성해서 이를 재활용하는 것이 좋겠다.
 
# 작은 크기의 ByteBuffer을 재사용해서 OutOfMemoryError 를 막는 방법
 
파일 크기 만큼의 `ByteBuffer`를 사용하는 대신 작은 크기의 `ByteBuffer`에 데이터를 담는 일을 반복하면 OutOfMemoryError 걱정없이도 파일 내용을 읽을 수 있다. 그런데 그냥 쉽게 되는 것은 아니고 손 봐줘야 할 곳이 몇 군데 있다. 
 
## 반복 문제
 
비동기 방식이라 Handler를 통해서 구현하므로 통상적인 방법처럼 단순하게 `while` 문으로는 해결할 수 없다.
 
그렇다고 엄청난 고도의 방법이 필요한 것은 아니다. `while`을 쓰는 대신 `CompletionHander`내에서 다시 `asynchronousFileChannel.read()`를 호출하게 하면 될 것 같다.
 
## 읽을 위치 지정 문제
 
`asynchronousFileChannel.read()`를 다시 호출할 때 주의해야할 점이 있다. 바로 `asynchronousFileChannel.read()`의 두번째 파라미터인 `position` 값의 적절한 설정이다. `ByteBuffer` 사이즈만큼 읽은 후에 다시 읽을 때는, 앞에서 읽고난 위치에서부터 다시 읽기 시작해야  중복 또는 누락 없이 정확하게 파일 내용을 읽을 수 있다. 
 
이 역시도 어려운 문제는 아니다. `ByteBuffer` 크기에 반복회수를 곱해준 값을 두번째 파라미터로 넘겨주면 되겠다. `long` 타입의 `iterations`라는 변수로 반복회수를 관리하자.
 
그런데, 한가지 문제가 있다. 반복회수는 익명 내부 클래스인`CompletionHandler` 내의 `completed()` 메서드 내에서 증가시켜야 하는데, 내부 클래스의 메서드에서는 바깥 클래스의 변수의 값을 직접 변경할 수 없다. 그래서 단순히 primitive 타입의 `iterations`을 사용하면 내부 클래스의 메서드에서 증가시킬 수 없으므로, primitive 타입인 `long` 대신에 객체인 `Long` 타입을 쓰면 값을 변경할 수 있다. 하지만 이 `Long` 타입의 변수를 `CompletionHandler`에게 어떻게 넘겨주지?
 
## 아하 attachment
 
그렇다. 우리에겐 미지의 파라미터인 `attachment`가 있었다.
 
Java API Doc에 뜬구름 잡는 설명만 있었던 `attachment`는 이럴 때 쓰라는 넘이었구나.. `asynchronousFileChannel.read()`의 세번째 파라미터에 `null` 대신 Long 타입의 iterations라는 변수를 넘겨주자.
 
그럼 대략 아래와 같이 코드가 바뀐다. 바뀐 부분에는 주석을 추가했다.
 
```java
private void asyncFileChannelTest(Path sourceFilePath, boolean isWrite) throws IOException {
 
    try (
            AsynchronousFileChannel asyncFileChannel = AsynchronousFileChannel.open(
                sourceFilePath,
                StandardOpenOption.READ
            );
    ) {
        System.err.println("AsynchronousFileChannel 테스트 시작");
 
        long startTime = System.nanoTime();
 
        long fileSize = asyncFileChannel.size();
 
        // ByteBuffer 크기를 8k로 축소
        ByteBuffer byteBuffer = ByteBuffer.allocate(8 * 1024);
 
        // 반복 회수 관리용 변수
        Long iterations = 0L;
 
        System.err.println("AsynchronousFileChannel.read() 호출");
 
        asyncFileChannel.read(
            byteBuffer, 0, iterations,    // null 대신 iterations 전달
            new CompletionHandler<Integer, Long>() {    // 타입 파라미터에 Object 대신 Long 전달
 
                @Override
                public void completed(Integer result, Long iterations) {    // 타입 파라미터에 Object 대신 Long
                    if (result == -1) {
                        long endTime = System.nanoTime();
                        System.err.println("비정상 종료 : " + (endTime - startTime) + " ns elapsed.");
                        return;
                    }
 
                    // 반복 회수 확인
                    System.err.println((iterations + 1) + "회차 반복");
 
                    byteBuffer.flip();
                    byteBuffer.mark();
                    if (isWrite) System.out.write(byteBuffer.array(), 0, result);
                    byteBuffer.reset();
 
                    // 읽어들인 바이트수가
                    // 파일사이즈와 같거나(버퍼 크기와 파일 크기가 같은 경우)
                    // 버퍼 사이즈보다 작다면 파일의 끝까지 읽은 것이므로 종료 처리
                    if (result == fileSize || result < byteBuffer.capacity()) {
                        long endTime = System.nanoTime();
                        System.err.println("AsynchronousFileChannel.read() 완료 : " + (endTime - startTime) + " ns elapsed.");
                        return;
                    }
                    // 읽을 내용이 남아있으므로 반복 회수를 증가 시키고 다시 읽는다.
                    iterations++;
                    asyncFileChannel.read(byteBuffer, result * iterations, iterations, this);
                }
 
                @Override
                public void failed(Throwable exc, Long iterations) {    // 타입 파라미터에 Object 대신 Long
                    exc.printStackTrace();
                }
            }
        );
 
        System.err.println("AsyncFileChannel I/O 진행 중에는 다른 작업도 할 수 있지롱");
        System.err.println("그동안 그리스에도 다녀오고");
        System.err.println("크로아티아에도 갔다오자");
    }
}
```
 
자 이제 실행해보면 메모리를 적게 쓰면서도 비동기 방식으로 파일 내용을 읽어올 것이다. 생각만해도 흐뭇하다. 얼른 실행해보자.
 
```
AsynchronousFileChannel 테스트 시작
AsynchronousFileChannel.read() 호출
AsyncFileChannel I/O 진행 중에는 다른 작업도 할 수 있지롱
그동안 그리스에도 다녀오고
크로아티아에도 갔다오자
1회차 반복
java.nio.channels.ClosedChannelException
	at sun.nio.ch.SimpleAsynchronousFileChannelImpl.implRead(SimpleAsynchronousFileChannelImpl.java:302)
	at sun.nio.ch.AsynchronousFileChannelImpl.read(AsynchronousFileChannelImpl.java:229)
	... 이하 생략 ...
```
 
ㅋㅋㅋ 한 방에 될리가.. 에러 메시지를 보니 채널이 이미 닫혀있다고 한다. 응? 나 채널 닫은 적 없는데..
 
## 채널이 닫힌 이유
 
어디서 닫혔을까 하고 코드를 보니 `AsynchronousFileChannel`을 가져올 때, 자원 해제의 편의를 위해 Java 7에 도입된 `try-with-resources` 구문을 사용했다. 채널이 닫힌 이유를 알 것 같다. 
 
파일 내용을 `ByteBuffer`에 성공적으로 한 번 읽어들인 후에 `CompletionHandler`내에서 다시 호출하는 `read()`는 `System.err.println("크로아티아에도 갔다오자");`가 실행되고 난 시점에 호출되는데, 이 시점에는 이미 `try-with-resources`를 빠져나온 후가 된다. 따라서 `try-with-resources`에 의해 자동으로 자원이 해제되면서 `AsynchronousFileChannel`가 닫히고, 그 다음에 이미 닫혀있는 `AsynchronousFileChannel`의 `read()`를 다시 호출하니까 채널이 이미 닫혀있다는 에러가 발생한 것이다.
 
원인은 알겠는데 해결은 또 어떻게 해야하나.
 
## try-catch 적용
 
일단 `AsynchronousFileChannel`를 닫는 처리를 프로그래머가 직접 제어할 수 있도록 `try-with-resources` 부터 걷어내는 것이 순서일 것 같다. 그대신 적절한 위치에서 명시적으로 `AsynchronousFileChannel.close()`를 호출해서 자원 해제 처리를 확실히 해주면, 채널이 닫히지 않은 채로 비동기 방식의 반복을 수행하고, 적절한 위치에서 채널을 닫는 처리가 가능할 것 같다. 
 
코드는 아래와 같이 바뀐다. 이번에 바뀐 내용은 `//// 2차 변경`와 같이 슬래쉬 4개로 주석처리했다.
 
```java
private void asyncFileChannelTest(Path sourceFilePath, boolean isWrite) throws IOException {
 
    //// try-with-resource 대신 try-catch-finally 적용
    try {
        System.err.println("AsynchronousFileChannel 테스트 시작");
 
        AsynchronousFileChannel asyncFileChannel = AsynchronousFileChannel.open(
                sourceFilePath,
                StandardOpenOption.READ
        );
 
        long startTime = System.nanoTime();
 
        long fileSize = asyncFileChannel.size();
 
        // ByteBuffer 크기를 8k로 축소
        ByteBuffer byteBuffer = ByteBuffer.allocate(8 * 1024);
 
        // 반복 회수 관리용 변수
        Long iterations = 0L;
 
        System.err.println("AsynchronousFileChannel.read() 호출");
 
        asyncFileChannel.read(
                byteBuffer, 0, iterations,    // null 대신 iterations 전달
                new CompletionHandler<Integer, Long>() {    // 타입 파라미터에 Object 대신 Long 전달
 
                    @Override
                    public void completed(Integer result, Long iterations) {    // 타입 파라미터에 Object 대신 Long
                        if (result == -1) {
                            long endTime = System.nanoTime();
                            System.err.println("비정상 종료 : " + (endTime - startTime) + " ns elapsed.");
 
                            //// asyncFileChannel 닫기
                            closeAsyncFileChannel(asyncFileChannel);
 
                            return;
                        }
 
                        // 반복 회수 확인
                        System.err.println((iterations + 1) + "회차 반복");
 
                        byteBuffer.flip();
                        byteBuffer.mark();
                        if (isWrite) System.out.write(byteBuffer.array(), 0, result);
                        byteBuffer.reset();
 
                        // 읽어들인 바이트수가
                        // 파일사이즈와 같거나(버퍼 크기와 파일 크기가 같은 경우)
                        // 버퍼 사이즈보다 작다면 파일의 끝까지 읽은 것이므로 종료 처리
                        if (result == fileSize || result < byteBuffer.capacity()) {
                            long endTime = System.nanoTime();
                            System.err.println("AsynchronousFileChannel.read() 완료 : " + (endTime - startTime) + " ns elapsed.");
 
                            //// asyncFileChannel 닫기
                            closeAsyncFileChannel(asyncFileChannel);
 
                            return;
                        }
                        // 읽을 내용이 남아있으므로 반복 회수를 증가 시키고 다시 읽는다.
                        iterations++;
                        asyncFileChannel.read(byteBuffer, result * iterations, iterations, this);
                    }
 
                    @Override
                    public void failed(Throwable exc, Long iterations) {    // 타입 파라미터에 Object 대신 Long
                        exc.printStackTrace();
 
                        //// asyncFileChannel 닫기
                        closeAsyncFileChannel(asyncFileChannel);
                    }
                }
        );
 
        System.err.println("AsyncFileChannel I/O 진행 중에는 다른 작업도 할 수 있지롱");
        System.err.println("그동안 그리스에도 다녀오고");
        System.err.println("크로아티아에도 갔다오자");
 
    } catch (Exception e) {
        e.printStackTrace();
        throw new RuntimeException(e);    //// 상황에 맞는 예외 처리 필요
    }
}
 
//// asyncFileChannel 닫기
private void closeAsyncFileChannel(AsynchronousFileChannel asyncFileChannel) {
 
    if (asyncFileChannel != null && asyncFileChannel.isOpen()) {
 
        try {
            asyncFileChannel.close();
        } catch (IOException e) {
            e.printStackTrace();
            throw new RuntimeException(e);    //// 상황에 맞는 예외 처리 필요
        }
    }
}
```
 
실행하면 드디어!! 다음과 같이 정상적으로 표시된다.
 
```
AsynchronousFileChannel 테스트 시작
AsynchronousFileChannel.read() 호출
AsyncFileChannel I/O 진행 중에는 다른 작업도 할 수 있지롱
그동안 그리스에도 다녀오고
크로아티아에도 갔다오자
1회차 반복
2회차 반복
3회차 반복
...
19496회차 반복
19497회차 반복
AsynchronousFileChannel.read() 완료 : 844209043 ns elapsed.
```
 
메모리 사용량을 확인해보면 아래와 같이 거의 미미한 수준의 변화만 있을 뿐이다.
 
![](http://i.imgur.com/V5ub1z4.png)
 
## attachment의 활용
 
앞에서 단순히 `Long` 타입의 변수를 `attachment`로 활용해서 반복 회수를 관리했는데, `attachment`에 다른 객체를 사용하면 더 많은 정보를 관리할 수 있다. 예를 들어, 읽어들인 바이트수를 `attachment`에 사용된 객체에 계속 누적하면, 파일 읽기 완료 후 읽어들인 바이트수와 실제 파일 크기를 비교할 수도 있다.
 
코드는 다시 아래와 같이 바뀐다. 이번에 바뀌는 부분은 슬래쉬 6개로 주석 처리했다.
 
```java
private void asyncFileChannelTest(Path sourceFilePath, boolean isWrite) throws IOException {
 
        //// try-with-resource 대신 try-catch-finally 적용
        try {
            System.err.println("AsynchronousFileChannel 테스트 시작");
 
            AsynchronousFileChannel asyncFileChannel = AsynchronousFileChannel.open(
                    sourceFilePath,
                    StandardOpenOption.READ
            );
 
            long startTime = System.nanoTime();
 
            long fileSize = asyncFileChannel.size();
 
            // ByteBuffer 크기를 8k로 축소
            ByteBuffer byteBuffer = ByteBuffer.allocate(8 * 1024);
 
            ////// attachment 용 객체
            class AsyncIOResultInfo {
                long iterations = 0L;
                long totalBytesRead = 0L;
            }
            AsyncIOResultInfo asyncIOResultInfo = new AsyncIOResultInfo();
 
            System.err.println("AsynchronousFileChannel.read() 호출");
 
            asyncFileChannel.read(
                    byteBuffer, 0, asyncIOResultInfo,    ////// iterations 대신 asyncIOResultInfo 전달
                    new CompletionHandler<Integer, AsyncIOResultInfo>() {    ////// 타입 파라미터에 Long 대신 AsyncIOResultInfo 전달
 
                        @Override
                        public void completed(Integer result, AsyncIOResultInfo asyncIOResultInfo) {    ////// Long 대신 AsyncIOResultInfo 전달
                            if (result == -1) {
                                long endTime = System.nanoTime();
                                System.err.println("비정상 종료 : " + (endTime - startTime) + " ns elapsed.");
 
                                //// asyncFileChannel 닫기
                                closeAsyncFileChannel(asyncFileChannel);
 
                                return;
                            }
 
                            // 반복 회수 확인
                            System.err.println((asyncIOResultInfo.iterations + 1) + "회차 반복");    ////// iterations 대신 asyncIOResultInfo.iterations
 
                            ////// 읽어들인 바이트수 누적
                            asyncIOResultInfo.totalBytesRead += result;
 
                            byteBuffer.flip();
                            byteBuffer.mark();
                            if (isWrite) System.out.write(byteBuffer.array(), 0, result);
                            byteBuffer.reset();
 
                            // 읽어들인 바이트수가
                            // 파일사이즈와 같거나(버퍼 크기와 파일 크기가 같은 경우)
                            // 버퍼 사이즈보다 작다면 파일의 끝까지 읽은 것이므로 종료 처리
                            if (result == fileSize || result < byteBuffer.capacity()) {
                                long endTime = System.nanoTime();
                                System.err.println("AsynchronousFileChannel.read() 완료 : " + (endTime - startTime) + " ns elapsed.");
 
                                ////// 총 읽어들인 바이트수 비교
                                System.err.println("fileSize       : " + fileSize);
                                System.err.println("totalBytesRead : " + asyncIOResultInfo.totalBytesRead);
 
                                //// asyncFileChannel 닫기
                                closeAsyncFileChannel(asyncFileChannel);
 
                                return;
                            }
                            // 읽을 내용이 남아있으므로 반복 회수를 증가 시키고 다시 읽는다.
                            ////// iterations 대신 asyncIOResultInfo.iterations
                            asyncIOResultInfo.iterations++;
                            asyncFileChannel.read(byteBuffer, result * asyncIOResultInfo.iterations, asyncIOResultInfo, this);
                        }
 
                        @Override
                        public void failed(Throwable exc, AsyncIOResultInfo iterations) {    ////// Long 대신 AsyncIOResultInfo 전달
                            exc.printStackTrace();
 
                            //// asyncFileChannel 닫기
                            closeAsyncFileChannel(asyncFileChannel);
                        }
                    }
            );
 
            System.err.println("AsyncFileChannel I/O 진행 중에는 다른 작업도 할 수 있지롱");
            System.err.println("그동안 그리스에도 다녀오고");
            System.err.println("크로아티아에도 갔다오자");
 
        } catch (Exception e) {
            e.printStackTrace();
            throw new RuntimeException(e);    //// 상황에 맞는 예외 처리 필요
        }
    }
 
    //// asyncFileChannel 닫기
    private void closeAsyncFileChannel(AsynchronousFileChannel asyncFileChannel) {
 
        if (asyncFileChannel != null && asyncFileChannel.isOpen()) {
 
            try {
                asyncFileChannel.close();
            } catch (IOException e) {
                e.printStackTrace();
                throw new RuntimeException(e);    //// 상황에 맞는 예외 처리 필요
            }
        }
    }
```
 
실행해보면 아래와 같이 전체 읽어들인 바이트수와 파일 크기도 함께 표시할 수 있다.
 
```
AsynchronousFileChannel 테스트 시작
AsynchronousFileChannel.read() 호출
AsyncFileChannel I/O 진행 중에는 다른 작업도 할 수 있지롱
그동안 그리스에도 다녀오고
크로아티아에도 갔다오자
1회차 반복
2회차 반복
3회차 반복
...
19496회차 반복
19497회차 반복
AsynchronousFileChannel.read() 완료 : 683431718 ns elapsed.
fileSize       : 159718093
totalBytesRead : 159718093
```
 
 
# 기존 방식과의 비교
 
## 속도
 
동기와 비동기는 그 작업 자체의 속도 비교보다는 대기 시간 동안 다른 작업 처리가 가능하냐 마냐가 중요하므로, 처리 속도가 중요한 것은 아니지만 그래도 궁금하니까 기존 방식이랑 한 번 비교해보자.
 
980메가 정도의 파일로 비교해봤다. 버퍼를 사용할 수 있는 부분에서는 8k 를 적용했다. 참고로 테스트용 대용량 텍스트 파일은 [여기](https://dumps.wikimedia.org/mediawikiwiki/20160720/)에서 내려받을 수 있다.
 
![](http://i.imgur.com/hNq09Zb.png)
 
`AsynchronousFileChannel`은 약 2.75초 정도 소요되었고, 가장 빠른 `FileChannel`과 `BufferedInputStream`은 0.5초 이내, `BufferedReader`와 `InputStreamReader`는 4~5초 정도 소요되었다.
 
텍스트을 읽을 때 간편해서 가장 많이 사용하는 `BufferedReader.readLine()`이 아무래도 8k 보다는 현저히 바이트수가 작을 행 단위로 반복을 하므로 반복 회수가 가장 많을테고, 따라서 가장 느릴 거라고 예상은 했지만 이 정도 차이라면 상당히 놀랍다. 작은 파일은 관계없겠지만 대용량 파일에서는 `BufferedReader.readLine()`는 피하는 것이 좋을 것 같다.
 
## 자원 사용

아래 그림은 다음과 같이 6번의 테스트 수행 시  CPU와 메모리 변화 추이를 나타내고 있다.

1. AsynchronousFileChannel.read()
1. FileChannel.read()
1. BufferedInputStream.read()
1. BufferedReader.read()
1. InputStreamReader.read()
1. BufferedReader.readLine()

`BufferedReader.readLine()`를 실행할 때만 메모리 사용량이 급격히 증가한다. 처리 속도 뿐아니라 메모리 사용 측면에서도 `BufferedReader.readLine()`는 대용량 파일에서는 사용하지 않는 것이 좋을 것 같다.
 
![](http://i.imgur.com/86OemjJ.png)
 
# 정리
 
>- **대용량 파일도 `AsynchronousFileChannel`을 활용해서 비동기 방식으로 I/O를 처리할 수 있다.**
>
>- 하지만 OutOfMemoryError가 발생하지 않도록 **적당한 크기의 `ByteBuffer`로 쪼개서 반복 처리**하는 것이 좋다.
>
>- **반복 처리 방식, 파일 읽을 위치 지정, 채널 자원의 해제, attachment의 사용** 등 신경써야 할 부분이 있다.
>
>- **대용량 파일에서는 `BufferedReader.readLine()`는 사용하지 않는 것이 좋다.**
 
 
# 더 읽을 거리
 
- jenkov tutorials : http://tutorials.jenkov.com/java-nio/asynchronousfilechannel.html
- java NIO : http://www.slideshare.net/allnewangel/java-nio-23150417
- java nio intro : https://tutorials.techmytalk.com/2014/11/03/java-nio-introduction-2/
- java file I/O tutorials : https://docs.oracle.com/javase/tutorial/essential/io/fileio.html
- API docs
	- https://docs.oracle.com/javase/7/docs/api/java/nio/channels/AsynchronousFileChannel.html
	- https://docs.oracle.com/javase/7/docs/api/java/nio/channels/CompletionHandler.html
	- https://docs.oracle.com/javase/7/docs/api/java/nio/ByteBuffer.html
- Async IO 개념 정리 : http://djkeh.github.io/articles/Boost-application-performance-using-asynchronous-IO-kor/
 
# 더 해볼 거리
 
- `ByteBuffer`를 사용할 때마다 생성하지 말고 Pooling 하면 속도가 더 나아질 것 같다.
- `ByteBuffer`의 크기를 바꿔가면서 `FileChannel`, `BufferedInputStream`와 속도 비교를 해보는 것도 좋을 것 같다.
- `attachment`를 잘 활용하면 예외 발생 처리 시 처음부터 모두 다시 읽지 않고 성공적으로 읽기를 마친 위치부터 다시 읽도록 효율화도 할 수 있을 것 같다.
- `ByteBuffer` 대신 `Direct ByteBuffer`로 테스트 해보는 것도 재미있을 것 같다.