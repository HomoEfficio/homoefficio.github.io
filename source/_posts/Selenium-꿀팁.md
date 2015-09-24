title: Selenium 꿀팁
date: 2015-09-23 17:37:13
categories:
  - 개발 환경 및 도구
tags:
  - Selenium
  - Selenium IDE
  - Web Driver
  - JUnit
  - Browser Test
  - Test
  - 셀레늄
  - 웹 드라이버
  - 브라우저 테스트
  - 테스트
thumbnailImage: http://www.seleniumhq.org/images/big-logo.png
coverImage: coverImage-Selenium.png

---

# Selenium

## 개요

**Selenium은 테스트 코드 실행으로 브라우저에서의 액션을 테스트 할 수 있게 해주는 테스팅 도구**다.
**Selenium IDE로 브라우저 상에서의 액션을 녹화해서 테스트 코드를 생성**할 수 있으며, 그 테스트 코드를 Eclipse나 IntelliJ 같은 **IDE의 런타임에서 JUnit 테스트와 같은 방식으로 실행해서 브라우저 상에서의 액션을 재생**할 수 있다.

## Selenium을 사용하기 위한 pom.xml

```xml
<dependency>
    <groupId>org.seleniumhq.selenium</groupId>
    <artifactId>selenium-java</artifactId>
    <version>2.47.1</version>
    <scope>provided</scope>
</dependency>
```

**이 글에서는 Java를 기준**으로 하지만, **Selenium은 C#, Python, Ruby, PHP, Perl, JavaScript도 지원**한다.

## Selenium IDE 설치

Selenium IDE는 파이어폭스 브라우저의 플러그인이다. **Selenium은 Firefox 외에도 IE, Chrome, Safari, Opera 등 다른 브라우저에서의 테스트도 지원**하지만, **Selenium IDE는 다른 브라우저에서는 사용할 수 없다.**

1. 파이어폭스 브라우저 설치
2. 파이어폭스 브라우저 실행
3. http://docs.seleniumhq.org/download/ 방문해서 아래와 같이 Selenium IDE 다운로드 링크 클릭

    ![](http://i.imgur.com/iN69Tbp.png)

4. 허가 클릭

    ![](http://i.imgur.com/vpR6Zdu.png)

5. 설치 클릭

    ![](http://i.imgur.com/OE0zgEF.png)

6. 설치 후 브라우저 재실행하면 아래와 같이 우상단에 Selenium IDE 아이콘이 보인다.

    ![](http://i.imgur.com/pvHNXB4.png)

## Selenium IDE 실행 및 녹화

파이어폭스 우상단의 Selenium IDE 아이콘을 누르면 실행된다.

![](http://i.imgur.com/BQEkfTS.png)

실행과 동시에 녹화가 시작되며, IDE를 실행한 파이어폭스 브라우저에서 액션을 취하면 IDE 화면에 녹화되는 것을 확인할 수 있다.

![](http://i.imgur.com/JJYOt2T.png)

IDE 우상단의 빨간 녹화 버튼을 다시 누르면 녹화가 정지된다.

![](http://i.imgur.com/eHt8e9M.png)

## Selenium IDE 자바 소스 추출

아래와 같이 IDE의 메뉴에서 소스를 추출할 수 있다.

![](http://i.imgur.com/8wn8ztA.png)

적절한 이름으로 저장한다.

![](http://i.imgur.com/2n51Rkx.png)

소스는 대략 아래와 같이 생겼다.

![](http://i.imgur.com/QNANiEd.png)

기본적으로는 이 파일을 JUnit처럼 실행할 수 있지만, 실무적으로는 손을 좀 봐야한다.

## Selenium 테스트 큰 흐름

Selenium으로 Daum 사이트를 테스트 해보면서 살펴봤지만 정리를 한 번 해보자.

1. Selenium 사용을 위한 pom.xml 설정
1. Selenium IDE 설치
1. Firefox 실행
1. Firefox에서 Selenium IDE 실행 및 녹화 시작
1. Firefox에서 이것저것 테스트
1. 녹화 정지
1. Selenium IDE에서 테스트 소스 코드 추출
1. 개발 환경에 테스트 코드 추가 - maven 등 Project Convention(규약)에 맞게 추가
1. **테스트 코드 보완**
1. IDE에서 테스트 실행

8번 까지는 일반적인 내용이라 그다지 어려울 것이 없는데, 9번 **테스트 코드 보완** 부분이 조금 신경쓸 부분이 있다. 이제 실전에서 마주치게 되는 문제를 해결해보자.

# Selenium 테스트 코드 작성 꿀팁

예제와 실전은 언제나 차이가 크다. Selenium 역시 실제 프로젝트에 적용해보니 몇 가지 시간 도둑들이 있었는데, 해결 방법을 하나하나 살펴보자.

## 로그인 세션 유지

Selenium IDE가 추출해주는 코드는 테스트는 기본적으로 JUnit의 애노테이션 중 `@Before`, `@Test`, `@After`만 사용해서 작성되어 있다. 각각 다음과 같은 역할을 수행한다.

- `@Before`는 Selenium Web Driver, 즉 테스트 용 Firefox 브라우저 인스턴스를 띄워서 테스트 대상 사이트에 접속
- `@Test`는 테스트 대상 페이지에 접속해서 이런저런 테스트를 브라우저 상에서 직접 실행
- `@After`는 테스트 용 Firefox 브라우저 인스턴스를 닫고 테스트를 종료

Selenium IDE가 추출해준 소스대로라면 `@Test` 항목 하나마다 브라우저를 띄우고, 종료하고를 반복하는데, 시간이 많이 소요되고 여러모로 낭비가 발생한다. 실무에서는 로그인 하고 로그인 세션을 유지한 채로 시스템 기능을 사용하는 테스트를 해야하므로 대책이 필요하다.

인터넷을 찾아보면 몇 가지 방법이 있기는 한데, **가장 간단한 방법은 `@Before`, `@After` 대신 `@BeforeClass`, `@AfterClass`를 사용**하는 것이다. **어차피 테스트니까 간단한게 최고다.**

`@BeforeClass`, `@AfterClass`는 `@Test` 메서드 하나마다 실행되지 않고, 테스트 클래스 하나 실행될 때 한 번씩만 실행된다. 주의할 점은 `@BeforeClass`, `@AfterClass` 메서드는 `static`이어야 한다는 점이다.

결론적으로 다음과 같이 하면 된다.
>- `@BeforeClass` 메서드 내에서 Selenium Web Driver 실행, 대상 사이트 접속, 로그인을 포함시키고,
>- 여러 개의 `@Test` 메서드에서 로그인 세션을 유지한채로 여러 가지 테스트를 수행하고,
>- `@AfterClass` 메서드에서 Selenium Web Driver를 종료시키고 테스트를 마친다.

물론 필요에 따라 `@Before`, `@After`를 함께 사용해도 된다.

`@BeforeClass`를 사용하는 테스트 코드는 다음과 같다.

![](http://i.imgur.com/OBX9TjJ.png)

`@AfterClass`를 사용하는 테스트 코드는 다음과 같다. `static`을 추가한 것외에는 Selenium IDE가 추출해준 그대로다.

![](http://i.imgur.com/rmS6BlT.png)

## 테스트 메서드 실행 순서 지정

단위 테스트라면 테스트 메서드의 실행 순서를 굳이 유지할 필요가 없겠지만, Selenium은 브라우저 상에서의 테스트이므로 단위 테스트라기 보다는 인수 테스트(또는 사용자 테스트)의 용도로 사용되는 경우가 많다.
**`@FixMethodOrder`를 테스트 클래스에 지정하면 메서드의 실행 순서를 고정시켜서 시나리오를 구성할 수 있다.**

`@FixMethodOrder`로 지정할 수 있는 옵션은 세 가지가 있지만, **개발자가 원하는 순서대로 지정할 수 있는 옵션은 `MethodSorters.NAME_ASCENDING` 하나 뿐**이다.

결론적으로 다음과 같이 하면 된다.
>- 테스트 클래스에 `@FixMethodOrder(MethodSorters.NAME_ASCENDING)`을 지정한다.
>- `@Test` 메서드의 이름을 테스트 시나리오 순서에 따라 알파벳 오름차순으로 명명한다.

`@FixMethodOrder`을 적용한 소스는 다음과 같다.

![](http://i.imgur.com/Lp3R5qe.png)

지금까지는 Selenium에서의 꿀팁이라기보다는 JUnit의 꿀팁인데 이제부터는 Selenium에서의 꿀팁을 알아보자.

## 브라우저 테스트 수행이 멈출 때

테스트를 수행하다보면 분명히 올바른 id를 지정해줬음에도 불구하고 브라우저 상에서 테스트가 더 진행되지 못하고, 결국 아래와 같은 에러를 토하면서 테스트가 비정상 종료될 때가 있다.

```
Caused by: org.openqa.selenium.ElementNotVisibleException: Element is not currently visible and so may not be interacted with
Build info: version: '2.47.1', revision: 'unknown', time: '2015-07-30 11:02:44'
System info: host: 'hanmomhanda-virtual-rebecca', ip: '127.0.1.1', os.name: 'Linux', os.arch: 'amd64', os.version: '3.16.0-38-generic', java.version: '1.7.0_80'
Driver info: driver.version: unknown
    at <anonymous class>.fxdriver.preconditions.visible(file:///tmp/anonymous29080281595295739webdriver-profile/extensions/fxdriver@googlecode.com/components/command-processor.js:9982)
    at <anonymous class>.DelayedCommand.prototype.checkPreconditions_(file:///tmp/anonymous29080281595295739webdriver-profile/extensions/fxdriver@googlecode.com/components/command-processor.js:12626)
    at <anonymous class>.DelayedCommand.prototype.executeInternal_/h(file:///tmp/anonymous29080281595295739webdriver-profile/extensions/fxdriver@googlecode.com/components/command-processor.js:12643)
    at <anonymous class>.fxdriver.Timer.prototype.setTimeout/<.notify(file:///tmp/anonymous29080281595295739webdriver-profile/extensions/fxdriver@googlecode.com/components/command-processor.js:623)


Process finished with exit code 255
```

Element가 보이지 않는다는 소리인데, 말 그대로 Element가 보이지 않아서 발생하는 에러다.
정확히는 viewport 내에 해당 Element가 렌더링 되어있지 않으면 `driver.findElement(By.id("ELEMENT_ID"))`와 같은 방식으로는 Element를 find하지 못하기 때문에 발생하는 에러다.

이를 해결하는 방법은 일단 두 가지가 떠오른다.

1. 해당 Element가 viewport 내에 들어오도록 테스트 수행이 멈춘 상태에서 수동으로 스크롤 해준다.
2. 테스트 자동화하자고 Selenium 쓰는데 수동이 웬말이냐, 소스에서 해결해보자.

우습지만 실제로 해보면 첫번째 방법도 유효하다!!

하지만 수동이 웬말이냐.. 소스에서 해결해보자. 바로 JavaScript를 사용하는 것이다.


## JavaScript 사용

Selenium 테스트 코드는 분명히 Java이지만, 놀랍게도 브라우저에서 실행 중인 Context를 JavaScript로 접근할 수 있다! 게다가 방법마저 쉽다!

```java
@FixMethodOrder(MethodSorters.NAME_ASCENDING)
public class TestBasis {
    private static WebDriver driver;
    private static String baseUrl;
    private boolean acceptNextAlert = true;
    private static StringBuffer verificationErrors = new StringBuffer();
    private static WebDriverWait wait;
    private static JavascriptExecutor js;  // JavascriptExecutor 클래스 선언

    @BeforeClass
    public static void setUp() throws Exception {
        driver = new FirefoxDriver();
        baseUrl = "http://localhost:8080";
        driver.manage().timeouts().implicitlyWait(15, TimeUnit.SECONDS);
        js = (JavascriptExecutor) driver;  // Web Driver를 JavascriptExecutor로 캐스팅
        ...
```

위와 같이 JavascriptExecutor 클래스를 선언하고, Web Driver를 JavascriptExecutor로 캐스팅하는 두 줄의 코드만 있으면 `js.executeScript("scroll(0, 300)");`와 같은 방식으로 JavaScript 구문을 실행할 수 있다.

앞에서 다루었던 viewport에 렌더링 되지 않은 Element를 찾지 못해서 테스트가 멈췄다가 비정상 종료하는 문제도 `js.executeScript("scroll(0, 300)");`로 스크롤해서 viewport를 적절히 이동시켜 주면 테스트가 바르게 수행된다.

## jQuery 사용

테스트 대상 웹 페이지가 jQuery를 사용하도록 설정되어 있다면 jQuery 구문도 Selenium에서 실행할 수 있다.

앞에서 다루었던 viewport에 렌더링 되지 않은 Element를 찾지 못해서 테스트가 멈췄다가 비정상 종료하는 문제를 해결하는 주요 코드는 다음과 같은데,

```java
js.executeScript("scroll(0, 300)");
driver.findElement(By.id("toMyList")).click();
```

아래와 같이 jQuery를 이용하면 일부러 scroll을 시켜 viewport를 맞춰주지 않아도 해당 Element를 찾아서 이벤트를 발생시킬 수 있다.

```java
js.executeScript("$('#toMyList').click()");
```

jQuery를 이용하는 방법은 특히 다음과 같은 상황에서 유용하다.

>- viewport에 안 보이는 hidden 필드에 값을 쓰거나 읽을 때
>    - hidden 필드는 HTML 기준으로는 현재의 viewport 내에 위치하더라도 `driver.findElement(By.id("ID"))`의 방식으로 찾지 못한다.
>- 어떤 요소에 이벤트 핸들러가 있는 경우
>    - `js.executeScript("$('#eventDispatcher').change()")`와 같은 식으로 이벤트를 발생시키면 이벤트 핸들러가 실행된다.

동일한 원리로 jQuery 뿐 아니라 웹 페이지에 사용하도록 설정만 되어 있다면 jQuery 뿐 아니라 다른 라이브러리도 사용할 수 있다.

## select 요소 테스트

아마도 버그로 추정되는데, 테스트를 하다보면 `select`에 대한 테스트가 의도한대로 동작하지 않는 경우가 있다.
<a href='http://www.seleniumhq.org/docs/03_webdriver.jsp#user-input-filling-in-forms' target='_blank'>Selenium API</a>에 보면 `select`의 선택 항목을 변경하는 코드는 아래와 같다.

```java
Select select = new Select(driver.findElement(By.tagName("select")));
select.deselectAll();
select.selectByVisibleText("Edam");
```
하지만 위 방식으로 `select`의 `option`을 설정해도 정작 "Edam"으로 표시된 `option`이 `selected`로 되지는 않아서 결국 "Edam"으로 선택되지 않는 일이 발생한다. 공식 문서의 내용에도 불구하고 내 경우엔 언제나 "Edam"으로 설정이 되지 않았다.

<a href='http://www.seleniumhq.org/docs/03_webdriver.jsp#user-input-filling-in-forms' target='_blank'>Selenium API</a>에 있는 다른 예제 코드를 응용해서 아래와 같은 방법으로 "Edam"으로 표시된 `option`을 명시적으로 click 해줘도 `selected`가 먹지 않는다.

```java
WebElement select = driver.findElement(By.tagName("select"));
List<WebElement> allOptions = select.findElements(By.tagName("option"));
for (WebElement option : allOptions) {
    System.out.println(String.format("Value is: %s", option.getAttribute("value")));
    if ("Edam".equals(option.getAttribute("value"))) {
        option.click();
        System.err.println(option.isSelected()); // false 가 출력됨
    }
}
```

이 문제의 해결 방법은 다음과 같다.

> select를 click 해주면 언제나 의도한대로 실행된다.

이를 적용한 실제 소스 코드는 다음과 같다.

```java
WebElement selectElement = driver.findElement(By.id("collegeList0.grdaTypeCode"));
selectElement.click(); // 바로 이 부분!!
Select select = new Select(selectElement);
select.selectByVisibleText("졸업예정");
```

# 정리

>Selenium은 JUnit과 같은 방식으로 실행해서, 테스트 용 브라우저 인스턴스를 띄우고, 브라우저 상에서 웹 애플리케이션의 기능을 테스트 할 수 있게 해주는 도구다.
>
>Selenium IDE를 이용해서 웹 브라우저 상에서의 사용자 동작을 녹화하고 테스트 소스 코드를 추출할 수 있다.
>
>- 추출한 테스트 코드를 실무에 그대로 쓸 수는 없고 몇 가지 보완 작업을 해야 한다.
>- 테스트 코드 상에서 JavaScript 코드를 실행할 수 있고, jQuery 같은 라이브러리 코드도 실행할 수 있다.
>- select 요소 테스트 시 select 요소에 click 이벤트를 실행해줘야 정확히 동작한다.

# 더 읽을거리

- Selenium 문서 - http://www.seleniumhq.org/docs/index.jsp