title: EOS 계정 생성
date: 2018-07-09 00:18:11
categories:
  - BlockChain
tags:
  - BlockChain
  - EOS
  - Wallet
  - Account
  - nodeos
  - keosd
  - cleos
  - 블록체인
  - 이오스
  - development
  - 개발
  - dapp
  - 디앱
  - 지갑
  - 계정
thumbnailImage: https://streamity.org/uploads/media/coin/0001/01/62322d7972d7c0fe7831736e4f4e9baf1d44108d.svg
coverImage: cover-EOS-eosio-blockchain.jpg
---
# EOS 계정 생성

블록체인의 상태에 영향을 미치는 액션을 수행하려면 계정이 필요하다.

`cleos`를 써서 `nodeos`로 하여금 계정을 생성하고 생성된 계정을 블록체인에 발행하게 할 수 있다. 계정을 생성하려면 기존 계정과 기존 계정의 key가 필요하다. 이를 위해 지갑이 필요하며, 지갑을 사용하려면 `keosd`를 실행해야 한다.

또한 계정을 생성하고 발행할 `nodeos`를 실행해서 EOS 노드를 띄워야 한다.

이런 관계는 아래 그림을 보면 더 쉽게 이해할 수 있다.

![Imgur](https://i.imgur.com/nnJYbmt.png)


## keosd 실행

계정 생성을 하려면 `keosd`와 `nodeos`를 동시에 띄워야 하는데, `keosd`를 `cleos`를 통하지 않고 직접 실행하면 8888 포트에서 실행되는데 `nodeos`도 8888 포트에서 실행되게 설정되어 있으므로 `keosd`의 설정을 변경해야 한다.

### keosd 설정 파일 수정

`keosd` 설정 파일은 `--data-dir`로 지갑 데이터 저장 위치를 따로 지정하지 않았다면 기본값으로 `~/eosio-wallet/`에 저장된 `config.ini` 파일이다. `http-server-address = 127.0.0.1:8888`로 되어 있는 것을 `http-server-address = 127.0.0.1:8899`로 변경한다.

![Imgur](https://i.imgur.com/QETOABh.png)

### keosd 실행

다음과 같이 혹시 실행 중일 수 있는 `keosd`를 종료하고 새로 `keosd`를 실행한다. EOSIO 빌드 및 설치 과정에서 `make install`을 해줬다면 어느 디렉터리에서 실행해도 무방하다.

>pkill keosd
>
>keosd --http-server-address=localhost:8899

![Imgur](https://i.imgur.com/W2LvKKU.png)


## nodeos 실행

`nodeos` 명령으로 EOS 노드를 띄우는 방법은 [EOS Single Node Testnet 실행](https://homoefficio.github.io/2018/06/06/EOS-Single-Node-Testnet-실행/)을 참고한다.

![Imgur](https://i.imgur.com/PQ3oqEt.png)


## 계정 생성 준비

### 사전 준비

EOS 블록체인에서 계정을 생성할 때 필요한 요소는 다음과 같다.

- 이미 존재하는 계정
- 새로 생성할 계정의 owner 자격에 사용될 공개키
- 새로 생성할 계정의 active 자격에 사용될 공개키

Single Node Testnet 에는 EOS 노드를 부트스트랩하는 `eosio` 계정 하나만 존재하므로, 최초의 사용자 계정을 만들 때는 `eosio` 계정을 사용할 수 밖에 없다. 그리고 `eosio` 계정으로 서명을 하므로 `eosio` 계정의 비밀키가 필요하다.

`eosio` 계정의 비밀키는 리눅스의 경우 `~/.local/share/eosio/nodeos/config/config.ini`, 맥의 경우 `~/Libraries/Application Support/eosio/nodeos/config/config.ini` 파일 안에 `signature-provider`라는 항목의 `KEY`에 명시되어 있다.

![Imgur](https://i.imgur.com/ecbRbVy.png)

### 계정 생성 명령

계정 생성 명령은 다음과 같다.

>cleos create account ${authorizing_account} ${new_account} ${owner_key} ${active_key}

- `${authorizing_account}`: 새 계정을 생성해서 블록체인에 발행하는 역할을 담당하는 기존 계정
- `${new_account}`: 새로 생성될 계정의 이름
- `${owner_key}`: 새로 생성될 계정의 owner 자격(authority)에 할당될 공개키
- `${active_key}`: 새로 생성될 계정의 active 자격(authority)에 할당될 공개키

#### 새 계정 이름 규칙

- 12글자까지 허용
- 허용되는 문자: `.12345abcdefghijklmnopqrstuvwxyz`

#### owner 자격(owner authority)

계정의 소유권을 나타내는 자격이다. owner 자격을 필요로 하는 트랜잭션은 별로 없지만 소유자 권한을 변경하는 액션에는 owner 자격이 필요하다.

owner 자격에 할당된 키는 콜드 저장소(cold storage)에 저장하는 것이 좋으며 누구와도 공유하지 말아야 한다.

도용된 권한(permission)을 복구하는데도 owner 자격이 필요하다.

#### active 자격(active authority)

송/수금, 블록 생산자(BP, Block Producer) 투표 및 고차원의 계정 사항 변경에 사용되는 자격이다. 대부분의 트랜잭션은 이 active 자격으로 생성할 수 있다.

### 계정 생성

계정 생성 과정을 이해하기 위해 먼저 앞서 다룬 사전 조건과 시나리오를 정리해보자.

#### ${authorizing_account}(계정 생성을 실행하는 계정)

Single Node Testnet에 이미 존재하는 유일한 계정은 Single Node를 실행할 때 사용되는 `eosio`밖에 없다. 따라서 처음 커스텀 계정을 생성할 때는 `eosio` 계정을 사용해야 한다. 이는 `eosio` 계정의 비밀키도 알아야 한다는 의미이며 비밀키 확인 방법은 위 '사전 준비' 부분에 나와있다.

#### ${new_account}

새 계정 이름은 규칙에 맞에 임의로 지정하면 된다. 예제에서는 `homo.efficio`로 한다.

#### ${owner_key}, ${active_key}

새로 생성될 계정의 owner 자격과 active 자격에 사용할 키는 앞서 [EOS 지갑 만들기 및 Key 연동](https://homoefficio.github.io/2018/06/06/EOS-지갑-만들기-및-Key-연동/)에서 'Homo-Efficio' 지갑에 연동했던 두 개의 키의 공개키를 사용한다.

- owner 자격에 사용할 `${owner_key}`: `EOS5pBeZiRgKRrLCCCFZ23EuP2d7XXK8UhYdbRSauXjyGrPjApLAW`
- active 자격에 사용할 `${active_key}`: `EOS8cQKoirjCNSVVywC7WwhuzSg1bC5Q5vG5YhDmAcwf3bVoPys3e`

#### 시나리오 이해

계정 생성 시나리오를 정리하면 다음과 같다.

>`homo.efficio`라는 신규 계정 생성에 `eosio`라는 기존 계정을 사용하며,
>
>'Homo-Efficio' 지갑에 연동했던 두 개의 키를 새로 생성할 계정의 `owner_key`, `active_key`로 설정한다.

그림으로 나타내면 다음과 같다.

![Imgur](https://i.imgur.com/YNsQPK1.png)

결국에는 키를 매개체로 해서 `Homo-Efficio`라는 지갑과 `homo.efficio`라는 계정이 간접적으로 연결되는 모양새다. 위 그림을 토대로 새 계정이 생성된 후 새 계정과 지갑의 관계를 정리해보면 다음과 같다.

>`homo.efficio`라는 계정으로 어떤 트랜잭션을 발생시킬 때
>
>필요한 키 정보를 `Homo-Efficio`라는 지갑에서 가져온다.



## 계정 생성 실행

### 오류 테스트

시험 삼아 길이가 12자를 넘는 계정 이름으로 계정을 생성해보면 다음과 같은 에러가 발생한다.

![Imgur](https://i.imgur.com/sRJcHHm.png)

### 지갑 잠금 오류

지갑 잠금 해제 되지 않은 상태에서 계정 생성을 실행하면 다음과 같은 에러가 발생한다.

![Imgur](https://i.imgur.com/vdL9ahu.png)

지갑 잠금 오류는 `keosd` 실행 화면에도 로그가 찍힌다.

![Imgur](https://i.imgur.com/MKyVMjT.png)

### 지갑 잠금 해제 후 계정 생성

새로 생성될 계정의 `owner_key`와 `active_key`로 사용한 키가 연동되어 있는 `Homo-Efficio` 지갑을 해제한 후, `homo.efficio` 계정 생성을 실행하면 다음과 같은 에러가 발생한다.

![Imgur](https://i.imgur.com/Sj1QugF.png)

이 에러는 `keosd` 관련 오류가 아니므로 `keosd` 화면에는 별다른 로그가 찍히지 않지만, `nodeos` 화면에 더 자세한 에러 로그가 찍힌다.

![Imgur](https://i.imgur.com/Ak37Z07.png)

에러 내용은 serialization 수행 시간이 초과된 것이 원인인 것 같다.

혹시 잠금 해제해야할 지갑이 `Homo-Efficio`가 아니라 `default` 지갑인가 싶어서 다음과 같이 `Homo-Efficio` 지갑을 다시 잠그고 `default` 지갑을 잠금 해제한 후 다시 계정 생성을 시도하면, 이번에는 계정이 이미 있다는 에러가 발생한다.

![Imgur](https://i.imgur.com/CnPqN3N.png)

`nodeos` 화면에 더 자세한 로그가 찍힌다.

![Imgur](https://i.imgur.com/MgN1qwB.png)

`cleos get account homo.efficio` 명령으로 계정을 확인해보면 계정이 생성되어 있는 것으로 나온다.

![Imgur](https://i.imgur.com/OpWGCPH.png)

