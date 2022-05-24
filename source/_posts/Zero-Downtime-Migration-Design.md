title: Zero Downtime Migration - Design
date: 2022-05-21 20:09:58
categories:
  - Technique
  - SRE
tags:
  - migration
  - architecture
  - zero downtime
thumbnailImage: https://i.imgur.com/mUTRoWz.png
coverImage: cover-migration.jpg
---

# Zero Downtime Migration - Design

오징어 전문 쇼핑몰을 만들었는데 입소문이 잘 났다. 그래서 포털 몇 군데에도 API 열어줬더니 대애애애박이 났다. 물 들어 온 김에 노저어야지. 해산물 종합 쇼핑몰로 확장하려고 한다.

그런데 아뿔싸.. 엔티티 이름, 테이블 이름 등이 `squid`로 돼 있다. 잘못된 건 없다. 애초에 오징어 전문 쇼핑몰이 목표였으니까. 요구사항이 바뀌었고 그에 따라 시스템을 전환해야 하는 일이 생겼을 뿐 잘못된 것은 없다.

어떻게 전환해야 할까? 시스템을 멈추고 점검 화면을 보여주고 전환해도 될 것 같지만, 우리를 돈쭐내고 싶어 안달이난 사용자들을 오랜 시간 대기하게 만드는 것은 예의가 아니다.

![Imgur](https://i.imgur.com/LYJSPU8.jpg)

시스템 중단 없이 마이그레이션 해보자.


# 요구사항

- 마이그레이션 전/중/후에 사용자 요청 처리에 아무 오류가 없어야 한다.
- API 클라이언트는 마이그레이션 후에도 당분간 기존 API를 사용할 수 있어야 각자 편한 시기에 새 API로 변경할 수 있어야 한다.
- `squid` 엔티티는 `seafood` 엔티티로 변경한다.


# 일반적인 마이그레이션 시나리오

편의상 기존 오징어 전문 쇼핑몰은 OLD 라고 하고, 해산물 종합 쇼핑몰은 NEW 라고 하면 대략 다음과 같은 시나리오로 전환 작업이 진행된다.

1. `squid` 대신 `seafood` 기준으로 동작하는 NEW 애플리케이션 작성
2. `squid` 기준의 OLD db에서 `seafood` 기준으로 구성된 NEW db로의 데이터 복제 구성
3. NEW 애플리케이션 배포
4. OLD 애플리케이션으로 향하던 트래픽을 NEW 애플리케이션으로 향하도록 라우팅 변경


# Command와 Query의 분리

시스템의 상태를 변경하는 CUD 작업과 상태를 변경하지 않고 R 작업만 수행하는 기능이 하나의 애플리케이션에 들어있다면, 전환도 한 번에 할 수 밖에 없다. 한 번에 전환하는 것이 꼭 나쁘다고 할 수는 없지만, CUD와 R을 분리해서 전환하면 분리 집중, 점진적 실행 등 Divide and Conquer 전략의 일반적인 장점을 누릴 수 있다. 조금 더 구체적으로 기술하면 다음과 같다.

- 상태 변경이 없으므로 전환 작업이 상대적으로 훨씬 수월한 R을 먼저 전환하고 모니터링하면서 `seafood` 기준의 로직에 오류가 없는지 점검하고 수정할 기회를 가질 수 있다.
- R 전환에서 얻은 경험을 토대로 데이터 일관성 유지에 훨씬 더 많은 주의를 기울어야 할 CUD에 대해 더 면밀히 준비하고, 전환 이후에도 상태 변경에 대해서만 집중적으로 모니터링하고 대처할 수 있다.

따라서 가능하다면 기존 애플리케이션을 CUD를 수행하는 Command와 R을 수행하는 Query로 분리할 수 있다면 분리하는 것이 좋다. 마이그레이션 관점에서는 API Endpoint 수준에서만 분리돼도 충분하다. Endpoint 수준에서의 분리가 말은 쉬워보이지만 다음과 같이 데이터 조회와 수정에 대한 API URL이 동일하게 구성되고 HTTP Method만 다르게 돼 있는 경우에는,

```
- 특정 해산물 조회: /api/seafoods/{id} GET
- 특정 해산물 수정: /api/seafoods/{id} PUT
```

애플리케이션 서버 앞단에 있는 Reverse Proxy에서 API 하나하나마다 HTTP Method 수준의 분기를 구성해야 하므로 굉장히 고된 작업일 수 있다.

![Imgur](https://i.imgur.com/ZzyAanE.jpg)

따라서 고된 분리 작업을 거쳐서 전환 과정에서의 안정성을 높일지, 아니면 고된 분리 작업을 생략하는 대신 전환 과정에서 발생할 수 있는 위험을 감수하고 한 방에 전환할지 신중하게 고민하고 선택해야 한다.

하지만 API가 애초부터 다음과 같이 구성돼 있었다면 아주 자연스럽게 Command와 Query를 분리 전환할 할 수 있다. 

```
- 특정 해산물 조회: /query/api/seafoods/{id} GET
- 특정 해산물 수정: /command/api/seafoods/{id} PUT
```

다행스럽게도 OLD 애플리케이션은 위와 같이 Command와 Query가 분리돼 있었다.

![Imgur](https://i.imgur.com/hCjQ43f.jpg)


서론이 길었는데 위와 같은 현황과 요구사항을 반영해서 구체화된 설계도는 다음과 같다.


# 전환 작업 설계

그림에 간략한 설명이 있으니 그냥 주욱 살펴보자.

### 1. 현황

![Imgur](https://i.imgur.com/1POOzAp.png)

### 2. 데이터 복제

![Imgur](https://i.imgur.com/7iLeHNP.png)

### 3. NEW Query 애플리케이션 배포

![Imgur](https://i.imgur.com/1cmjqcV.png)

### 4. Query 라우팅 전환

![Imgur](https://i.imgur.com/Pnaf5mM.png)

### 5. NEW Command 애플리케이션 배포

![Imgur](https://i.imgur.com/aGE0xxC.png)

### 6. Command 라우팅 전환

![Imgur](https://i.imgur.com/o1hUGlF.png)

### 7. DB 복제 중지

![Imgur](https://i.imgur.com/iJ6Iy3K.png)

### 8. NEW API 라우팅 추가

![Imgur](https://i.imgur.com/80AUKB0.png)

### 9. 클라이언트 API 변경

![Imgur](https://i.imgur.com/yd1MLVp.png)

### 10. OLD 라우팅 제거

![Imgur](https://i.imgur.com/hPVKUbC.png)

### 11. OLD API Endpoint 제거

![Imgur](https://i.imgur.com/JCrhECX.png)

### 12. 마이그레이션 완료

![Imgur](https://i.imgur.com/wI6kcCW.png)


단계별 실제 구현 작업은 다음 편에서 알아보자.
