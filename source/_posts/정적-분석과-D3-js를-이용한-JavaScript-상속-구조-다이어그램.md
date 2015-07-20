title: 정적 분석과 D3.js를 이용한 JavaScript 상속 구조 다이어그램
date: 2015-07-19 13:18:14
categories:
  - 시각화
tags:
  - JavaScript
  - 자바스크립트
  - Static Analysis
  - 정적 분석
  - D3
  - 다이어그램
  - Visualization
  - MoGL
thumbnailImage: https://camo.githubusercontent.com/e1a1948f0bcfa095d54793afd3ab96af97731773/687474703a2f2f64336a732e6f72672f65782f636c75737465722e706e67
coverImage: cover-static-analysis.png
---
# Context

모바일에 최적화 된 WebGL 라이브러리를 만들고 있는 [MoGL 프로젝트](https://github.com/projectBS/MoGL)에서는 `MoGL`이라는 최상위 클래스를 기준으로 여러 클래스들이 상속 구조를 형성하고 있다.

상속 방법은 아래와 같이 표준화 되어 있다.

```javascript
MoGL.extend('Matrix',{
    ...
}
```

그렇다면 정적 분석을 통해서 위계(Hierarchy) 정보를 담고 있는 자료 구조를 뽑아내서 시각화 라이브러리와 버무리면, **실제 소스 코드와 언제나 Sync가 맞는 살아있는 다이어그램**을 만들어 낼 수 있지 않을까?

# 정적 분석

소스 코드에서 `.extend(`을 포함하는 행만 추려서 간단한 위계 정보를 추출할 수 있다.
방법은 여러가지가 있겠지만 약간의 정규표현식과 substring()으로 다음과 같이 추출할 수 있다.

{% codeblock lang:javascript Hierarchy 정보 추출 및 구성 %}
// 표준화 된 상속 코드
var extendingPattern = '.extend(';

// 표준화 된 상속 코드를 포함하고 있는 행
// 물론 실무에서는 실제 소스 코드에서 추출해와야 된다.
var lines = [
    "var BlendMode = MoGL.extend('BlendMode', {",
    "return Matrix.extend('Camera',{",
    "return MoGL.extend('Geometry', {",
    "var Group = Matrix.extend('Group', {",
    "return MoGL.extend('Material',{"
];

// child 이름을 추출하기 위한 정규표현식
var regexp0 = /'\w+'|"\w+"/;

// 추출에 사용되는 변수들
var line, splitted, parent, child, tmp, k;

// 위계 정보를 담고 있는 객체를 담는 Map
var clsMoGLMap = {};

for (k in lines) {
    line = lines[k];
    // parent, child 이름을 추출
    if (line.indexOf(extendingPattern) > 0) {
        splitted = line.split(extendingPattern);
        parent = splitted[0].substring(splitted[0].lastIndexOf(' ') + 1);
        tmp = regexp0.exec(splitted[1])[0];
        child = tmp.substring(1, tmp.length - 1);
    }

    // 위계 정보를 담고 있는 객체를 구성해서 clsMoGLMap 에 추가
    if (clsMoGLMap[parent]) {
        clsMoGLMap[parent].childrenNames = child;
    } else {
        clsMoGLMap[parent] = new ClsMoGL();
        clsMoGLMap[parent].name = parent;
        clsMoGLMap[parent].childrenNames = child;
    }

    if (clsMoGLMap[child]) {
        clsMoGLMap[child].parentName = parent;
    } else {
        clsMoGLMap[child] = new ClsMoGL();
        clsMoGLMap[child].name = child;
        clsMoGLMap[child].parentName = parent;
    }

}
{% endcodeblock %}

위계 정보를 담는 객체 `ClsMoGL`은 `LinkedList`와 비슷한 자료구조다. 애초에 단순히 텍스트에서 정보를 추출했기 때문에 텍스트를 담는 `parentName`, `childrenNames`가 추가되어 있다.

부모는 하나고 자식은 여럿일 수 있으므로 자식만 배열로 하면 된다. `children`, `childrenNames` 배열에는 편리하게 그냥 값 할당을 하면 내부적으로는 push()가 호출되도록 구현했다.

{% codeblock lang:javascript Hierarchy 정보를 담는 자료 구조 %}
var ClsMoGL = function() {
    var name, parentName, parent, childrenNames = [], children = [];
    Object.defineProperties(this, {
        'name':{
            enumerable:true,
            get:function() {
                return name;
            },
            set:function(value) {
                name = value;
            }
        },
        'parentName':{
            enumerable:true,
            get:function() {
                return parentName;
            },
            set:function(value) {
                parentName = value;
            }
        },
        'parent':{
            enumerable:true,
            get:function() {
                return parent;
            },
            set:function(value) {
                parent = value;
            }
        },
        'childrenNames':{
            enumerable:true,
            get:function() {
                return childrenNames;
            },
            set:function(childName) {
                childrenNames.push(childName);
            }
        },
        'children':{
            enumerable:true,
            get:function() {
                return children;
            },
            set:function(child) {
                children.push(child);
            }
        }
    });
};
{% endcodeblock %}


`ClsMoGL`을 담고 있는 `clsMoGLMap`를 재귀 함수 등을 이용해서 가공하면(사실 이 부분이 좀 복잡했는데 쉽게 이해할 수 있도록 설명하기는 어렵고, 이 방식이 가장 좋은 방식이라는 보장도 없으니, 필요하다면 그냥 소스 코드를 참고..) 대략 다음과 같은 json을 얻을 수 있다.

{% codeblock lang:javascript json으로 정리된 Hierarchy 정보 %}
{
    "name": "MoGL",
    "children": [{
        "name": "BlendMode"
    }, {
        "name": "Geometry"
    }, {
        "name": "Material"
    }, {
        "name": "Matrix",
        "children": [{
            "name": "Camera"
        }, {
            "name": "Group"
        }, {
            "name": "Mesh"
        }]
    }, {
        "name": "Primitive"
    }, {
        "name": "Scene"
    }, {
        "name": "Shader"
    }, {
        "name": "Shading"
    }, {
        "name": "Texture"
    }, {
        "name": "Vector"
    }, {
        "name": "Vertex"
    }, {
        "name": "World"
    }]
}
{% endcodeblock %}

자료 구조를 만들었으면 나머지 일은 **D3.js** 가 접수한다.


# D3.js

두말이 필요없는 굉장한 시각화 라이브러리인 [**D3.js**](https://github.com/mbostock/d3/wiki/Gallery)에는 이런 위계 정보를 나타내는 다이어그램을 쉽게 만들 수 있는 여러가지 built-in 템플릿을 제공해준다. D3.js에는 이런 build-in 템플릿을 `layout`이라고 부른다.

D3.js의 `Cluster layout`을 사용하면 쉽게(?) 다이어그램을 그릴 수 있다.

여기서는 사실 http://bl.ocks.org/mbostock/4063570 에 있는 예제 중에서 `d3.json()`으로 json을 외부에서 가져오는 대신 위에서 만든 내부의 json을 사용하도록 변경한 부분 외에는 거의 그대로 갖다 썼다. 그래서 '쉽게'라고 할 수 있지만, 사실 D3.js가 그렇게 쉽지만은 않다.

D3.js는 여러가지 다이어그램을 쉽게 그릴 수 있게 해주는 다양한 built-in API가 제공되지만, D3.js를 만든 **Mike Bostock** 형님도 늘 강조하듯, 화려한 시각화 뒤에 숨어있는 **D3.js의 진정한 마술은 데이터와 Dom 요소를 매핑해주는 부분에 있다.** 이 부분을 시각화를 이용해서 잘 설명해준 글이 있는데, 너무 좋아서 번역을 해뒀으니 [**여기**](http://hanmomhanda.github.io/Docs/d3/How-Selections-Work.html)를 참고하면 D3.js를 배우는 데 도움이 될 것이다.

결과와 소스 코드는 [**여기**](http://projectbs.github.io/MoGL/lab/diagram/index.html)에서 볼 수 있다.

화려하진 않지만, 소스 코드가 바뀌면 다이어그램도 알아서 바뀌는 살아있는 문서라는 점에서 쓸모는 꽤 있을 것이다.


# 정리

- JavaScript 프로젝트에서 **표준화 된 상속 구문**을 사용하면, **정적 분석**과 **D3.js**를 엮어서 **살아있는 상속 구조 다이어그램**을 만들 수 있다.
