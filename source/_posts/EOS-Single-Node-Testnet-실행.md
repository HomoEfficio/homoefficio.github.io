title: EOS Single Node Testnet 실행
date: 2018-06-06 08:45:33
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
  - Testnet
  - 테스트넷
thumbnailImage: https://streamity.org/uploads/media/coin/0001/01/62322d7972d7c0fe7831736e4f4e9baf1d44108d.svg
coverImage: cover-EOS-eosio-blockchain.jpg
---
# EOS Single Node Testnet 실행

공식 문서인 https://developers.eos.io/eosio-nodeos/docs/local-single-node-testnet 를 기준으로 약간의 커스터마이징과 과도한 친절함을 가미했다.

## 사전 조건

https://homoefficio.github.io/2018/06/06/EOS-소스-구성-빌드-및-테스트/ 에서와 같이 빌드를 성공적으로 마치면 아래와 같이 build 디렉토리에 빌드 결과물이 생성된다.

![Imgur](https://i.imgur.com/3JFK47Y.png)

## EOSIO 아키텍처 다시 보기

![Imgur](https://i.imgur.com/nnJYbmt.png)

이 글에서는 위 3가지 컴포넌트 중 `nodeos` 실행에 대해 알아본다.


## nodeos 실행

>cd build/programs/nodeos
>
>./nodeos -e -p eosio \-\-plugin eosio::chain_api_plugin \-\-plugin eosio::history_api_plugin

- `-e`: 체인이 stale 상태이더라도 블록을 생성할 수 있도록 한다.
- `-p`: 실행될 노드에 의해 제어되는 블록 생산자의 계정 이름을 지정한다.
  - 예제에서는 `eosio`가 블록 생산자 계정이며, `eosio` 계정의 Key는 `nodeos`의 설정 파일인 `~/.local/share/eosio/config/config.ini`(Mac OS: `~/Library/Application Support/eosio/nodeos/config/config.ini`)에서 확인할 수 있다.
- `--plugin`: `nodeos`에서 사용할 플러그인을 지정한다. 여러번 지정할 수 있다.
  - 예제에서는 `eosio::chain_api_plugin`, `eosio::history_api_plugin` 플러그인을 사용한다.

위와 같이 실행하면 아래와 같이 싱글 노드로 구성된 테스트넷이 실행되고, 블록도 매우 빠른 속도(0.5초)로 계속 생성된다.

![Imgur](https://i.imgur.com/BJNM5Et.png)

싱글 노드로 구성된 테스트넷에는 아래 그림과 같이 `keosd`, `cleos`, `nodeos` 모두 하나의 호스트 안에서 실행된다.

![Imgur](https://i.imgur.com/ehc7Jpa.png)

`nodeos`가 실행되면 아래와 같이 `~/.local/share/eosio`(Mac OS: `~/Library/Application Support/eosio`) 디렉터리에 테스트넷 관련 데이터 및 설정 파일이 생성된다.

![Imgur](https://i.imgur.com/dOsfBVI.png)

`~/.local/share/eosio/nodeos/config/config.ini`(Mac OS: `~/Library/Application Support/eosio/nodeos/config/config.ini`) 파일에 여러가지 네트워크 설정 사항이 담겨 있다.

`~/.local/share/eosio/nodeos/data`(Mac OS: `~/Library/Application Support/eosio/nodeos/data`) 디렉터리에는 공유 메모리, 로그 등 EOS 블록체인 관련 여러 런타임 데이터가 저장된다. 데이터 디렉터리의 위치는 `nodeos` 실행 시 `--data-dir` 옵션으로 다른 위치를 지정할 수도 있다.

`nodeos`는 CTRL+C로 종료할 수 있으며 화면은 다음과 같다. #184번 블록까지 생성한 후 종료되었다.

![Imgur](https://i.imgur.com/pgbzFRE.png)

다시 `./nodeos -e -p eosio --plugin eosio::chain_api_plugin --plugin eosio::history_api_plugin` 명령으로 실행하면 다음과 같이 #185번 블록부터 다시 블록 생성이 이어진다.

![Imgur](https://i.imgur.com/pbCVcz1.png)

## cleos 에서 nodeos 정보 확인

`nodeos`를 실행한 터미널 말고 다른 새 터미널의 eos 디렉터리에서 아래 명령 실행

>./build/programs/cleos/cleos \-\-url http://localhost:8888 get info

![Imgur](https://i.imgur.com/99DPIh2.png)


## nodeos 종료

`CTRL+C`로 종료한다. 더 우아한 방법이 있을거라 생각했지만 `nodeos --help`로 확인해본 결과 종료 옵션은 없는 것 같다. 

계속 켜두어도 되지만 다음 과정인 지갑 만들기 및 Key 연동에서는 `nodeos`를 사용하지 않으므로 종료해도 무방하다.

이것으로 `nodeos` 실행을 마쳤다. 다음에는 [EOS 지갑 만들기 및 Key 연동](https://homoefficio.github.io/2018/06/06/EOS-지갑-만들기-및-Key-연동/)에서 지갑을 만들고 Key를 생성해서 연동하는 방법을 알아본다.
