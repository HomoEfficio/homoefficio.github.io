title: git subtree - 프로젝트 안의 또 다른 프로젝트
date: 2015-07-18 12:54:46
categories:
  - 개발 환경 및 도구
tags:
  - git
  - subtree
  - subproject
  - hexo
  - 서브트리
  - 서브프로젝트
thumbnailImage: http://blogs.wandisco.com/wp-content/uploads/2013/09/subtrees.png
coverImage: git-subtree.png
---
# Context

이 블로그는 [hexo](https://hexo.io/) 블로그 플랫폼에 [tranquilpeak](https://github.com/LouisBarranqueiro/tranquilpeak-hexo-theme) 테마를 적용하고 GitHub 호스팅에서 돌고 있다.

[tranquilpeak](https://github.com/LouisBarranqueiro/tranquilpeak-hexo-theme)이 아주 마음에 들었지만 기본 폰트가 눈에 거슬렸다. 그래서 고쳐쓰려고 보니, 지속적으로 계속 내가 원하는 폰트를 적용하려면 단순히 CSS 어딘가를 고치면 끝나는 환경이 아니었다. 테마 자체를 사용자 버전이 아닌 개발자 버전으로 가지고 와서 빌드를 해야 내가 딱 원하는 환경을 구성할 수 있었다.

생각해보면 **테마 자체도 하나의 Git repo를 가지고 있는 개발 프로젝트이고, 블로그 포스트를 담고 있는 hexo 인스턴스 역시도 하나의 Git repo를 가지고 있는 일종의 개발 프로젝트다.**

하지만 내 로컬 환경에서의 물리적인 파일 구조는 블로그 포스트를 담고 있는 hexo 인스턴스 내부에 themes/tranquilpeak 가 존재한다. 즉, hexo가 tranquilpeak 테마를 포함하고 있다. 다시 말해, **프로젝트 안에 또 다른 프로젝트가 존재하는 생김새다.**

    {% asset_img 파일구조.png %}


나는 블로그 포스트도 계속 추가해 갈 것이고, 테마도 조금씩 바꿔갈 생각이다. **즉, 포스트는 hexo repo에 반영하고, 테마 수정 내용은 tranquilpeak를 수정한 custom-tranquilpeak repo에 반영하고 싶다.**

그럼 Git repo 내에 또 다른 Git repo를 둬야 되는건가?
hexo repo의 .gitignore에 themes/tranquilpeak 를 추가하고, 포스트를 쓰다가 미리보기로 보니 테마를 바꿔야 할 필요가 있어서 테마를 고치려면 custom-tranquilpeak repo에 가서 고치고 커밋하고 푸쉬해야 되나?


# git subtree

깃느님은 역시나 해법을 가지고 계셨다. 바로 `git subtree`다.

`git subtree`의 기능을 나름대로 정의하자면 다음과 같다.

> git subtree는 실제로는 개별 프로젝트인 여러 개의 프로젝트를 개발자의 로컬에서는 하나의 repo로 관리할 수 있게 해준다.

앞에서 설명한 환경을 대입해서 구체적으로 설명하면,

- **실제로는 개별 프로젝트인 hexo 인스턴스와 custom-tranquilpeak 테마를**
- **내 로컬에서는 hexo 인스턴스 repo 하나로 관리할 수 있다.**
- **hexo 인스턴스의 수정 내용은 당연히 원격의 hexo repo push/pull 할 수 있고, custom-tranquilpeak 테마의 수정 내용은 원격에 개별 프로젝트로 존재하는 repo에 따로 push/pull 할 수 있다.**


# 작업 흐름

작업 흐름도 간단하다.

앞으로는 이해를 쉽게 하기 위해 포함하는 프로젝트를 `Parent`, 포함되는 프로젝트를 `Child` 라고 한다.

### 로컬 repo 구성
- `Parent`를 clone 해서 로컬로 가져온다.

>~/gitRepo $ git clone https://github.com/hanmomhanda/hanmomhanda.github.io
Cloning into 'hanmomhanda.github.io'...
remote: Counting objects: 10173, done.
remote: Compressing objects: 100% (4689/4689), done.
remote: Total 10173 (delta 3043), reused 0 (delta 0), pack-reused 5261
Receiving objects: 100% (10173/10173), 15.02 MiB | 3.39 MiB/s, done.
Resolving deltas: 100% (5565/5565), done.
Checking connectivity... done.

- `Parent repo` 디렉토리로 이동

>~/gitRepo $ cd hanmomhanda.github.io

### 원격 repo 참조 추가

- 로컬의 hexo 인스턴스 repo 설정 파일에 `custom-tranquilpeak`에 대한 원격 참조를 추가한다.
    그래야 로컬의 custom-tranquilpeak의 내용과 원격의 `custom-tranquilpeak` 사이에 push/pull 할 수 있다.

>~/gitRepo/hanmomhanda.github.io $ git remote add custom-tranquilpeak https://github.com/hanmomhanda/custom-tranquilpeak-hexo-theme.git

### subtree 구성

- 로컬의 hexo 인스턴스에 원격에 있는 `custom-tranquilpeak`의 내용을 clone이 아닌 `git subtree add`로 로컬에 물리적으로 가져온다.

>~/gitRepo/hanmomhanda.github.io $ git subtree add --prefix=themes/tranquilpeak/ custom-tranquilpeak dev

- 위의 명령은 `custom-tranquilpeak`이 참조하는 원격 repo의 dev 브랜치의 내용을 `themes/tranquilpeak` 디렉토리로 물리적으로 가져온다.

- **Git repo로서 가져오는 것이 아니라 단순히 디렉토리/파일을 가져오므로 `themes/tranquilpeak` 디렉토리에는 Git repo 설정을 담고 있는 .git 디렉토리가 없다.**

    - 사실 위의 명령 그대로 하면 prefix 'themes/tranquilpeak/' already exists. 라는 에러가 난다. clone 해서 가져온 Parent가 이미 subtree로 구성되어 있기 때문이다. 이럴 때는 간단히 `rm -rf themes/tranquilpeak/` 로 지워주고 다시 위와 같이 `git subtree add` 명령을 실행하면 된다. 처음 subtree를 구성할 때는 이 에러는 발생하지 않는다.

- git log 로 subtree 관련 내용을 확인할 수 있다.

>~/gitRepo/hanmomhanda.github.io $ git log

>commit c807d42f2418be8a48c48575c3da00424393bda4
>Merge: c6cf914 ddac951
>Author: hanmomhanda <hanmomhanda@gmail.com>
>Date:   Sat Jul 18 12:03:16 2015 +0900
>
>    Add 'themes/tranquilpeak/' from commit 'ddac951e92d024aa42206f557029dc61fd3772da'
>
>    git-subtree-dir: themes/tranquilpeak
>    git-subtree-mainline: c6cf914fe11306df562d8b2b2d37ef6fb8a980da
>    git-subtree-split: ddac951e92d024aa42206f557029dc61fd3772da


### Parent 내용의 git 싸이클

- 일반적인 git 흐름과 동일하다. `git add`, `git commit`, `git push`, `git pull` 로 관리한다.

### Child 내용의 git 싸이클

여기가 중요하다. `Child` 관리는 두 가지로 나뉜다.

- **`Child`도 로컬에서는 `Parent`의 한 디렉토리에 불과하다.** 따라서 `Child`의 내용도 `Parent`에서와 마찬가지로 일반적인 `git add`, `git commit`, `git push`, `git push` 로 `Parent`의 변경 관리에 포함된다.

- `Child`는 원래 별개의 프로젝트 였다. 원격에 있는 원래의 repo에도 변경 사항을 동기화 해야 한다. 이럴 떄는 `git push`, `git pull`이 아니라 `git subtree push`, `git subtree pull` 을 사용해야 한다.

>~/gitRepo/hanmomhanda.github.io $ git subtree push --prefix=themes/tranquilpeak/ custom-tranquilpeak dev
git push using:  custom-tranquilpeak dev
Username for 'https://github.com': hanmomhanda
Password for 'https://hanmomhanda@github.com':
Everything up-to-date

>~/gitRepo/hanmomhanda.github.io $ git subtree pull --prefix=themes/tranquilpeak/ custom-tranquilpeak dev
From https://github.com/hanmomhanda/custom-tranquilpeak-hexo-theme
 * branch            dev        -> FETCH_HEAD
Already up-to-date.


# 좋은점

- 여러 개의 프로젝트 repo를 로컬에서 하나의 프로젝트로 repo로 통합해서 관리할 수 있다.

- 원격은 원래와 마찬가지로 개별로 나뉘어진 상태로 계속 변경 사항을 동기화 할 수 있다.

- 예시로 든 것처럼 블로그 플랫폼과 테마를 관리하는 상황이 git subtree와 궁합이 완전히 딱 들어 맞는 Use case가 되며, 그 외 이런 저런 이유로 여러 개의 프로젝트를 통합 관리하고자 할 때 적용할 수 있다.


# 아쉬운 점

- subtree를 만들면 설정 파일에 설정 사항이 기록되면 좋겠는데, `git log` 에만 남는다. 따라서 `git subtree push`, `git subtree pull`을 할 때 어느 디렉토리를 `--prefix`로 지정해야 하는지 기억하고 있어야 한다.

    - 어느 디렉토리에 `.gitignore` 파일이 있는지를 검사하는 등의 방법으로 subtree인 디렉토리를 찾아낼 수도 있기는 하다. 하지만 불편하기는 마찬가지.


# 정리

- 여러 개의 프로젝트를 합쳐서 하나로 관리하고 싶다면 `git subtree`를 사용한다.

- 어느 디렉토리가 subtree인지 별도로 기록해두고 팀원들끼리 공유해야 한다.

    - 이에 관해 김경민 님이 작성하신 [SK Planet의 블로그 포스팅](http://readme.skplanet.com/?p=8542)에 보면 subtree로 추가한 디렉토리를 별도의 브랜치로 빼두는 방법이 있는데, 그 글의 질의응답에 내가 써둔 것처럼 아주 유용한 것 같지는 않다는 생각이다.


# 참고 자료

- [Atlassian 블로그 - 1](https://developer.atlassian.com/blog/2015/05/the-power-of-git-subtree/)
- [Atlassian 블로그 - 2](http://blogs.atlassian.com/2013/05/alternatives-to-git-submodule-git-subtree/)
- [SK Planet 블로그](http://readme.skplanet.com/?p=8542)