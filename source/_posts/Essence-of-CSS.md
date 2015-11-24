CSS는 뭐랄까.. 그냥 이래저래 해보다가 되면 그냥 넘어갔을뿐, 붙잡고 보게되질 않았다. CSS로 뭔가 미려한 UI를 만드는 것은 다른 영역이니 그렇다치더라도, 최소한 만들어져 있는 CSS를 보고 알아는 볼 수 있어야 하지 않을까.

# 우선 순위


## Cascading

CSS는 출처가 세 가지이다. 이것을 cascade라 한다.

1. Author's style
2. Users's style
3. Browser's default style


> `!important` 키워드를 써서 User가 Author의 스타일을 override 할 수 있다.

위에서 아래
파일 끼리도
동일 파일 내에서도

## Specificity

id > class > tag

# 속성값

## 길이

- 절대 길이
    - px

- 상대 길이
    - %
    - em

## color

- 키워드
- #16진수
- rba(), rgba()
- hsl(), hsla()

# Box Model

## display

- block
- inline
- inline-block

## width, height, padding, margin

## 기술 방식

### padding, margin

- 2 values : top/bottom right/left 
- 4 values : top right botton left

### border

- 3 values : width style color

### border-radius

- 2 values : top-left/bottom-right top-right/bottom-left
- 4 values : top right botton left

## box Sizing

- content-box
- padding-box
- border-box

# Positioning


