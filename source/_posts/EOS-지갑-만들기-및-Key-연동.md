title: EOS 지갑 만들기 및 Key 연동
date: 2018-06-06 08:55:13
categories:
  - BlockChain
tags:
  - BlockChain
  - EOS
  - 블록체인
  - 이오스
  - development
  - 개발
  - dapp
  - 디앱
  - 지갑
thumbnailImage: https://streamity.org/uploads/media/coin/0001/01/62322d7972d7c0fe7831736e4f4e9baf1d44108d.svg
coverImage: cover-EOS-eosio-blockchain.jpg
---
# EOS 지갑 만들기 및 Key 연동

공식 문서인 https://developers.eos.io/eosio-nodeos/docs/learn-about-wallets-keys-and-accounts-with-cleos 를 기준으로 약간의 커스터마이징과 과도한 친절함을 가미했다.


## EOSIO 아키텍처 다시 보기

![Imgur](https://i.imgur.com/nnJYbmt.png)

이 글에서는 위 3가지 컴포넌트 중 `cleos`와 `keosd`에 대해 알아본다.


## 지갑과 계정

### 지갑(Wallet)

지갑은 블록체인의 상태에 영향을 미치는 연산을 승인할 때 필요한 공개키-비밀키 쌍을 담고 있는 저장소다. 지갑 데이터는 `keosd`에 의해 관리 되지만 대부분 직접 `keosd` 명령을 실행하지 않고 `cleos`를 통해 `keosd`를 실행한다.

`keosd`는 지갑 파일을 기본 옵션으로 `~/eosio-wallet` 디렉터리에 저장한다.


### 계정(Account)

계정은 블록체인에 대한 접근 권한을 가진 식별자라고 할 수 있다. `nodeos`가 계정의 발행과 블록체인에 대한 계정 관련 액션(action)을 관리하지만, `cleos`를 통해서도 관리할 수 있다.


### 지갑과 계정의 관계

직관적으로는 계정이 지갑을 가지고 있을 것 같지만, EOS의 지갑과 계정은 직접적인 관계가 없다. 계정은 지갑의 존재를 모르고, 지갑은 계정의 존재를 모른다. 둘 사이에 직접적인 관계가 없음은 위의 EOSIO 아키텍처 그림에서도 알 수 있다. `nodeos`와 `keosd` 사이에는 직접적인 관계가 없고 서로의 존재를 모른다.

둘 사이에 간접적이나마 관계가 발생하는 것은 서명이 필요할 때다. 지갑을 사용하면 보안을 위해 암호화되어 잠금 처리를 할 수 있는 로컬 저장 공간에서 서명을 효율적으로 가져올 수 있다. `cleos`가 키 조회를 담당하는 `keosd`와 키를 사용하는 서명을 필요로 하는 액션 처리를 담당하는 `nodeos` 사이에서 효과적인 중재자 역할을 담당한다.


## 지갑 목록 확인

![Imgur](https://i.imgur.com/GDyaXFi.png)

위 캡처 화면 내용은 다음과 같다.

1. `cleos wallet` 명령으로 `keosd`를 실행하기 전에는 `~/eosio-wallet` 디렉터리는 생성되어 있지 않다.

2. `cleos wallet list` 명령을 실행하면 `keosd`가 실행되고 지갑 목록이 표시된다. 아직 지갑을 생성하지 않았으므로 지갑 목록은 비어 있다. 이처럼 `cleos wallet` 명령을 통해 `keosd`가 자동으로 실행되므로 별도로 직접 `keosd` 명령을 실행할 필요가 없다.

3. `ps -ef | grep keosd` 명령을 실행하면 `keosd`가 실행되어 있고 `http://127.0.0.1/8900`으로 접근할 수 있음을 알 수 있다.

4. `keosd`가 실행되면서 `~/eosio-wallet` 디렉터리와 `keosd` 설정 파일인 `config.ini` 파일이 생성된다.


## 지갑 생성

지갑의 생성도 다음과 같이 `cleos` 명령을 통해 실행한다. 지갑은 `nodeos`의 실행 여부와 관계없이 생성될 수 있다.

>cleos wallet create

![Imgur](https://i.imgur.com/aykCLV4.png)

이름이 default인 지갑은 이제 `keosd`의 관리 대상에 포함되며, 생성된 지갑의 마스터 패스워드가 생성되고 화면에 표시된다. 이 패스워드로 지갑 파일의 잠금을 해제할 수 있으므로 분실되지 않도록 잘 보관해야 한다.

`keosd`는 지갑 파일을 `~/eosio-wallet` 폴더에 저장한다(eos/programs/keosd/main.cpp 에 하드코딩 되어 있음).

>ll ~/eosio-wallet

![Imgur](https://i.imgur.com/E7AjVZC.png)

*참고: 공식 문서(https://developers.eos.io/eosio-nodeos/docs/learn-about-wallets-keys-and-accounts-with-cleos)에는 `keosd`의 `--data-dir` 옵션으로 지갑 파일이 저장되는 데이터 폴더를 지정할 수 있다고 언급되어 있다. 하지만 이후 내용에서 `keosd`를 직접 실행하는 부분이 없고 `cleos`만을 사용하며, `keosd`를 사용하지 않으므로 `--data-dir`를 써서 지갑 데이터가 저장될 위치를 따로 지정할 기회가 없고, 결국 기본값대로 `~/eosio-wallet` 폴더에 지갑 파일이 생성된다.*

`-n` 옵션을 이용하면 이름을 지정해서 지갑을 생성할 수도 있다. ~~따옴표를 이용하면 공백이 포함된 이름도 가능하다.~~ 이 글을 처음 쓸 때는 공백이 허용됐었는데 아래 화면과 같이 2018-06-07에 관련 소스가 변경되어 **공백은 허용되지 않고 알파벳과 숫자, `._-`만 허용**된다.

![Imgur](https://i.imgur.com/7OHbxxl.png)

~~따라서 아래에 나오는, 공백이 포함된 `Homo Efficio`는 더이상 유효하지 않으며 `Homo-Efficio`라고 썼다고 가정하자(다시 다 캡처해서 올리자니 눈물이.. ㅠㅜ).~~ 다시 캡처해서 업데이트 완료.

>cleos wallet create -n Homo-Efficio

![Imgur](https://i.imgur.com/gLIL4rG.png)


## 지갑 목록 확인

>cleos wallet list

![Imgur](https://i.imgur.com/2dZ310g.png)


생성한 지갑 목록이 표시된다. `*`표는 지갑이 잠금 해제(unlocked) 되어 있음을 의미한다.

`cleos wallet create` 명령으로 생성된 지갑은 편의상 잠금 해제된다.

## 지갑 잠금

아래와 같이 'Homo-Efficio' 지갑을 잠그고 지갑 목록을 확인하면 'Homo-Efficio' 지갑 옆에는 `*` 표시가 나타나지 않는다.

>cleos wallet lock -n Homo-Efficio
>
>cleos wallet list

![Imgur](https://i.imgur.com/xW91sHG.png)

지갑이 잠긴 상태에서는 블록체인에 상태 변화를 일으키는 액션을 수행할 수 없다.

## 지갑 열기

이제 `keosd`를 종료하고 다시 시작하면 어떤 현상이 발생하는지 알아보자.

`cleos wallet stop` 명령으로 `keosd`를 종료할 수도 있고, 

![Imgur](https://i.imgur.com/P8Xsg3T.png)

브라우저에서 `http://localhost:8900/v1/keosd/stop`에 접속해서 `keosd`를 종료할 수도 있다.

![Imgur](https://i.imgur.com/fhcKGJr.png)

`ps -ef | grep keosd`로 확인하면 `keosd` 프로세스가 죽은 것을 확인할 수 있다.

![Imgur](https://i.imgur.com/Uj5I3g7.png)

다시 `cleos wallet list` 명령을 실행하면 `keosd`가 자동으로 실행되지만 앞에서 생성한 지갑 목록은 표시되지 않는다.

![Imgur](https://i.imgur.com/n6e6JDW.png)

이유는 `cleos wallet create`로 지갑을 생성했을 때는 지갑이 잠금해제 된 상태로 만들어지고 열린(open) 상태가 되지만, `keosd`가 종료되면 지갑은 자동으로 잠금 상태가 되고 닫힌 상태가 되기 때문이다.

`cleos wallet open` 명령을 실행하면 `default` 지갑이 열리고 `cleos wallet list` 명령을 실행하면 지갑 목록에 표시되지만, 잠금 상태는 해제되지 않으므로 `*`는 표시되지 않는다.

![Imgur](https://i.imgur.com/NjyKtDO.png)

`cleos wallet unlock` 명령을 실행하고 패스워드를 입력하면 `default` 지갑이 잠금 해제 되어 `*`가 표시된다.

![Imgur](https://i.imgur.com/f9sE5RX.png)

이름을 지정해서 만든 'Homo-Efficio' 지갑도 열고, 잠금해제 한다.

![Imgur](https://i.imgur.com/bfROC9w.png)


## Key 생성 및 지갑 연동

EOSIO의 공개키/비밀키를 생성하는 방법은 여러가지가 있지만, 일단 `cleos`를 사용해서 만들어보자.

>cleos create key

![Imgur](https://i.imgur.com/DvhU7nF.png)


거듭 강조하지만 튜토리얼 말고 실제 사용할 때는 Private key를 아무에게도 노출해서는 안되며 분실되지 않도록 잘 보관해야 한다.

'Homo-Efficio' 지갑에 방금 생성한 key를 연동해보자. 역시 `cleos`를 사용한다.

>cleos wallet import -n Homo-Efficio PRIVATE\_KEY\_VALUE

![Imgur](https://i.imgur.com/fmOi9sd.png)


연동할 때 입력한 비밀키의 쌍인 공개키 값이 화면에 표시된다. 앞에서 공개키/비밀키 생성 시 Public key로 표시된 값과 같다.

하나의 지갑에 여러개의 키를 연동할 수 있다. 다음과 같이 키 쌍을 하나더 생성하고 연동해보자.

![Imgur](https://i.imgur.com/2yxG8zF.png)


`cleos wallet keys` 명령을 사용하면 잠금 해제된 모든 지갑에 연동된 공개키의 목록이 표시된다.

>cleos wallet keys

![Imgur](https://i.imgur.com/oX2XZpd.png)

*참고: 키 2개를 연동한 Homo-Efficio를 지정해서 공개키를 조회했는데 3개가 조회되어 나온다. 이유는 지갑을 생성하면 따로 연동하지 않아도 기본으로 1개의 키(default 지갑에 연동된 것과 같은 키)가 새로 생성한 지갑에 연동되기 때문 -> 이 부분은 v1.0.4에서 패치되어 default 지갑에 연동된 것과 같은 키는 지갑에 연동되지 않고 사용자가 직접 지갑에 연동한 키만 연동된다. 따라서 v1.0.4 이후 버전에서는 직접 연동한 2개만 화면에 표시된다.*

~~특정 지갑에 연동된 키 목록만을 조회하는 방법은 없는 것 같다.~~ EOSIO 1.0.2 에서는 다음과 같이 `private_keys` 서브명령으로 특정 지갑에 연동된 공개키/비밀키 쌍 목록을 조회할 수 있다. 실행하려면 지갑의 비밀번호가 필요하며 비밀키까지 같이 확인할 수 있다.

>cleos wallet private_keys

![Imgur](https://i.imgur.com/nMamX8Q.png)


>cleos wallet private_keys -n Homo-Efficio

![Imgur](https://i.imgur.com/JOhBJGs.png)

*참고: 키 2개를 연동한 Homo-Efficio를 지정해서 비밀키를 조회했는데 3개가 조회되어 나온다. 이유는 지갑을 생성하면 따로 연동하지 않아도 기본으로 1개의 키(default 지갑에 연동된 것과 같은 키)가 새로 생성한 지갑에 연동되기 때문 -> 이 부분은 v1.0.4에서 패치되어 default 지갑에 연동된 것과 같은 키는 지갑에 연동되지 않고 사용자가 직접 지갑에 연동한 키만 연동된다. 따라서 v1.0.4 이후 버전에서는 직접 연동한 2개만 화면에 표시된다.*

`cleos wallet create_key` 명령을 사용하면 `cleos create key`와 `cleos wallet import` 두 번의 명령으로 하던 작업을 한 번의 명령으로 실행할 수 있다.

![Imgur](https://i.imgur.com/l0svF16.png)

>cleos wallet keys

![Imgur](https://i.imgur.com/SG4coWx.png)

>cleos wallet private_keys -n Homo-Efficio

![Imgur](https://i.imgur.com/QZNJkNB.png)

*참고: 3개가 아니라 4개가 나오는 이유는 앞서 말한 것과 같음*

## 지갑 백업

지갑의 백업은 단순하다 `~/eosio-wallet` 디렉터리에 있는 지갑 파일을 다른 곳으로 복사해서 백업하면 된다.

![Imgur](https://i.imgur.com/qIVEGAq.png)


