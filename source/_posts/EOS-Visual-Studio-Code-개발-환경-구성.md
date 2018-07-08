title: EOS Visual Studio Code 개발 환경 구성
date: 2018-06-06 08:31:22
categories:
  - BlockChain
tags:
  - BlockChain
  - EOS
  - Visual Studio Code
  - vscode
  - IDE
  - 블록체인
  - 이오스
  - development
  - 개발
  - dapp
  - 디앱
  - 개발 환경
  - 비주얼 스튜디오 코드
thumbnailImage: https://streamity.org/uploads/media/coin/0001/01/62322d7972d7c0fe7831736e4f4e9baf1d44108d.svg
coverImage: cover-EOS-eosio-blockchain.jpg
---
# EOS Visual Studio Code 개발 환경 구성

https://infinitexlabs.com/setup-ide-for-eos-development/ 를 참고해서 작성한 EOS 개발 환경 구성

## Visual Studio Code

### 다운로드 및 설치

https://code.visualstudio.com/docs/setup/linux 참고해서 .deb 파일 다운로드 후 설치


### VS Code Extension 설치

아래와 같이 Extension 버튼을 누르고

![Imgur](https://i.imgur.com/etrHfut.png)

다음 항목을 차례로 설치한다.

- C/C++ by MicroSoft

- CMake by twxs

- CMake Tools by vector-of-bool

- WebAssembly Dmitriy Tsvettsikh

![Imgur](https://i.imgur.com/ml1iOWX.png)

Extension은 아래와 같이 `~/.vscode` 아래에 설치된다.

![Imgur](https://i.imgur.com/5mhpfwG.png)


## EOS 프로젝트 열기

VS Code에는 IntelliJ나 Eclipse에 익숙한 개발자에게는 살짝 당황스러운 것이 `New Project...`나 `Import...` 같은 메뉴가 없다.

아래 화면과 같이 Explorer 버튼을 누른 후 Open Folder를 클릭해서 EOS 프로젝트 루트 폴더를 지정한다.

![Imgur](https://i.imgur.com/ZnIGQD8.png)

열고 나면 다음과 같이 파일 변화를 감지하는 watch가 제대로 동작을 할 수 없다고 나온다.

![Imgur](https://i.imgur.com/VGfTDvh.png)

버튼을 눌러보면 [여기](https://code.visualstudio.com/docs/setup/linux#_visual-studio-code-is-unable-to-watch-for-file-changes-in-this-large-workspace-error-enospc) 로 이동해서 아래와 같은 내용이 표시된다.

![Imgur](https://i.imgur.com/gcvmYnM.png)

대략 워크스페이스가 너무 많은 파일을 가지고 있는 게 문제라는 얘기인데, 설명에 나온 것처럼 `/etc/sysctl.conf` 파일을 열어서 아래의 내용을 추가해준다. 524,288개의 파일까지 변경 감지가 가능하다는 설정이다.

```
fs.inotify.max_user_watches=524288
```

파일을 저장하고 `sudo sysctl -p` 명령을 실행해서 설정 내용을 적용한다.

아래 화면을 보면 설정 내용을 적용하기 전에는 8192 였고, 설정 후 524288 이 적용되었음을 확인할 수 있다.

![Imgur](https://i.imgur.com/lAFDUyE.png)

언어 팩 설치 관련 팝업은 아래와 같이 설정 아이콘을 누르고 Don't Show Again 을 클릭해서 다시 안 보이게 할 수도 있고, 설치해서 한글로 사용할 수도 있다.

![Imgur](https://i.imgur.com/SQEEum1.png)


## 작업 편의를 위한 Tasks 작성

일반적인 컴파일, 빌드를 위한 Tasks와 스마트 컨트랙의 ABI를 만들어내는 Tasks를 작성한다.


`SHIFT+CTRL+P`를 눌러서 Command Palette를 띄우고 `Tasks`를 입력한 후 `Configure Task`를 선택한다.

![Imgur](https://i.imgur.com/KmYnWqz.png)

`Create tasks.json file from template`를 선택한다.

![Imgur](https://i.imgur.com/KmYnWqz.png)

`Others`를 선택한다.

![Imgur](https://i.imgur.com/0akpWnP.png)

아래와 같이 `.vscode` 폴더 아래에 `tasks.json` 파일 템플릿이 표시된다.

![Imgur](https://i.imgur.com/B41aoV5.png)

`tasks.json` 파일 내용을 다음과 같이 수정한다.

```json
{
    "version": "2.0.0",
    "reveal": "always",
    "options": {
        "cwd": "${workspaceRoot}"
    },
    "tasks": [
        {
            "label": "CMake",
            "type": "shell",
            "command": "sh ${workspaceRoot}/.vscode/scripts/compile.sh"
        },
        {
            "label": "Build",
            "type": "shell",
            "command": "sh ${workspaceRoot}/.vscode/scripts/build.sh"            
        },
        {
            "label": "Generate ABI",
            "type": "shell",
            "command": "sh ${workspaceRoot}/.vscode/scripts/generate.sh ${fileDirname} ${fileBasenameNoExtension}",
        }
    ]
}
```

각 Task에 해당하는 셸 파일을 작성한다.

### compile.sh

```bash
mkdir -p build

cd build

# 필요한 모든 빌드 파일 생성
cmake -G 'Unix Makefiles' -DCMAKE_BUILD_TYPE=Debug ..
```

### build.sh

```bash
mkdir -p build

cd build

# 필요한 모든 빌드 파일 생성
cmake -G 'Unix Makefiles' -DCMAKE_BUILD_TYPE=Debug ..

# 빌드
make
```

### generate.sh

```bash
echo "Current working directory -" $1
cd $1

eosiocpp -g $2.abi $2.cpp
```


## Tasks를 위한 단축키 설정

`compile`, `build`, `generate` task를 편리하게 실행할 수 있는 단축키를 등록한다. 

`File > Preferences > Keyboard Shortcuts` 클릭

![Imgur](https://i.imgur.com/UdBaQzE.png)

`keybindings.json` 클릭

![Imgur](https://i.imgur.com/VEluHdM.png)

아래와 같이 단축키를 등록한다. 기존의 단축키와 충돌만 나지 않는다면 취향에 맞게 다른 키를 등록할 수도 있다. 

![Imgur](https://i.imgur.com/aO5SviF.png)

