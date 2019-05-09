title: JPA 일대다 단방향 매핑 잘못 사용하면 벌어지는 일
date: 2019-04-28 10:30:35
categories:
  - Technique
tags:
  - JPA
  - Java Persistence API
  - ORM
  - Object Relation Mapping
  - Hibernate
  - 하이버네이트
  - 1:N
  - OneToMany
  - ManyToOne
  - 일대다
  - unidirectional
  - 단방향
  - bidirectional
  - 양방향
  - association
  - 연관관계
  - 매핑
  - 엔티티
  - Entity
  - JoinColumn
  - JoinTable
  - mappedBy
  - cascade
  - orphanRemoval
  - Spring Data JPA
  - 스프링 데이터 JPA
  - Overhead
  - 오버헤드
thumbnailImage: https://i.imgur.com/rQScnoT.png
coverImage: cover-jpa-onetomany.png
---

# JPA 일대다 단방향 매핑 잘못 사용하면 벌어지는 일

`Parent : Child = 1 : N` 의 관계가 있으면 일대다 단방향으로 매핑하는 것보다 일대다 양방향으로 매핑하는 것이 좋다. 왜 그런지 구체적으로 살펴보자.


# 조인테이블 방식의 일대다 단방향 매핑

그런데 어떤 특별한 이유가 있을 수도 있고, 그냥 별 생각없이 작성된 레거시 일 수도 있고, 아니면 JPA에 살짝 서툴러서도 있고, 여튼 다음과 같이 직관적으로 단순하게 **`@OneToMany`만 달랑 붙여서 매핑하면 조인테이블 방식의 일대다 단방향 방식으로 매핑된다.**

```java
@Entity
@Getter
public class Parent {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;

    @OneToMany(cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Child> children = new ArrayList<>();

    protected Parent() {}

    public Parent(String name) {
        this.name = name;
    }

    public Parent(String name, List<Child> children) {
        this.name = name;
        this.children.addAll(children);
    }
}

@Entity
@Getter
public class Child {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;

    protected Child() {
    }

    public Child(String name) {
        this.name = name;
    }
}

```

위와 같이 작성하면 조인테이블인 `parent_children`라는 테이블이 새로 생긴다. 뭐 테이블 하나 생기면 어때.. 큰일 나겠어? 라고 생각할 수도 있지만, **`children`이 많지 않을 때만 큰 일이 안 나고, 많으면 제법 큰 일이 난다.**


# 시나리오

위와 같이 매핑된 상태에서 다음과 같은 간단한 시나리오를 생각해보자.

1. `parent`가 10개의 Child를 포함하는 `children`을 가진다.
2. `parent.children`에서 Child의 id가 1, 2인 것 2개만 삭제한다.

1번은 뭐 처음 생성이니 `parent` 1개에 대해 `parent` 테이블에 insert 1회, `children` 10개에 대해 `child` 테이블에 insert 10회 실행된다. 그리고 조인테이블 방식으로 동작하므로 `parent_children` 테이블에도 insert 10회 실행된다.

2번에서 `children` 중에서 2개를 지우므로 `parent_children` 테이블에서 delete 2회 실행되고, `orphanRemoval = true`로 설정되어 있으므로 `child` 테이블에서 delete 2회 실행될 것이다.

하지만 직접 실행해보면 2번은 예상과 완전히 다르게 동작한다!!

```java
@Component
@Transactional
@RequiredArgsConstructor(onConstructor = @__(@Autowired))
public class OneToManyRunner implements CommandLineRunner {

    @NonNull
    private ParentRepository parentRepository;

    @Override
    public void run(String... args) throws Exception {
        Parent parent1 = new Parent("parent 1");
        for (int i = 1 ; i <= 10 ; i++) {
            parent1.getChildren().add(
                    new Child("child " + i)
            );
        }

        Parent dbParent = this.parentRepository.saveAndFlush(parent1);

        System.out.println("*****************************");
        
        List<Child> children = dbParent.getChildren();
        children.removeIf(child -> 
                child.getId() == 1L || child.getId() == 2L);
    }

}
```

# 실행 결과

`parent_children` 테이블에서 delete 2회, `orphanRemoval = true`로 설정되어 있으므로 `child` 테이블에서 delete 2회 실행될 것으로 예상했지만 실제로는,

- **`parent.children` 10개 모두 delete 되면서 `parent_children` 테이블에서 `children_id`가 1, 2인 것을 제외한 8개의 레코드에 대해 모두 8회의 insert가 실행**되고, 
- 마지막에 `child` 테이블에서 2회의 delete가 실행된다.

```sql
insert into parent (name) values (?)
binding parameter [1] as [VARCHAR] - [parent 1]
insert into child (name) values (?)
binding parameter [1] as [VARCHAR] - [child 1]
insert into child (name) values (?)
binding parameter [1] as [VARCHAR] - [child 2]
insert into child (name) values (?)
binding parameter [1] as [VARCHAR] - [child 3]
insert into child (name) values (?)
binding parameter [1] as [VARCHAR] - [child 4]
insert into child (name) values (?)
binding parameter [1] as [VARCHAR] - [child 5]
insert into child (name) values (?)
binding parameter [1] as [VARCHAR] - [child 6]
insert into child (name) values (?)
binding parameter [1] as [VARCHAR] - [child 7]
insert into child (name) values (?)
binding parameter [1] as [VARCHAR] - [child 8]
insert into child (name) values (?)
binding parameter [1] as [VARCHAR] - [child 9]
insert into child (name) values (?)
binding parameter [1] as [VARCHAR] - [child 10]
insert into parent_children (parent_id, children_id) values (?, ?)
binding parameter [1] as [BIGINT] - [1]
binding parameter [2] as [BIGINT] - [1]
insert into parent_children (parent_id, children_id) values (?, ?)
binding parameter [1] as [BIGINT] - [1]
binding parameter [2] as [BIGINT] - [2]
insert into parent_children (parent_id, children_id) values (?, ?)
binding parameter [1] as [BIGINT] - [1]
binding parameter [2] as [BIGINT] - [3]
insert into parent_children (parent_id, children_id) values (?, ?)
binding parameter [1] as [BIGINT] - [1]
binding parameter [2] as [BIGINT] - [4]
insert into parent_children (parent_id, children_id) values (?, ?)
binding parameter [1] as [BIGINT] - [1]
binding parameter [2] as [BIGINT] - [5]
insert into parent_children (parent_id, children_id) values (?, ?)
binding parameter [1] as [BIGINT] - [1]
binding parameter [2] as [BIGINT] - [6]
insert into parent_children (parent_id, children_id) values (?, ?)
binding parameter [1] as [BIGINT] - [1]
binding parameter [2] as [BIGINT] - [7]
insert into parent_children (parent_id, children_id) values (?, ?)
binding parameter [1] as [BIGINT] - [1]
binding parameter [2] as [BIGINT] - [8]
insert into parent_children (parent_id, children_id) values (?, ?)
binding parameter [1] as [BIGINT] - [1]
binding parameter [2] as [BIGINT] - [9]
insert into parent_children (parent_id, children_id) values (?, ?)
binding parameter [1] as [BIGINT] - [1]
binding parameter [2] as [BIGINT] - [10]
*****************************
delete from parent_children where parent_id=?  <== 헉!! 형이 왜 여기서 나와!!
binding parameter [1] as [BIGINT] - [1]
insert into parent_children (parent_id, children_id) values (?, ?)
binding parameter [1] as [BIGINT] - [1]
binding parameter [2] as [BIGINT] - [3]
insert into parent_children (parent_id, children_id) values (?, ?)
binding parameter [1] as [BIGINT] - [1]
binding parameter [2] as [BIGINT] - [4]
insert into parent_children (parent_id, children_id) values (?, ?)
binding parameter [1] as [BIGINT] - [1]
binding parameter [2] as [BIGINT] - [5]
insert into parent_children (parent_id, children_id) values (?, ?)
binding parameter [1] as [BIGINT] - [1]
binding parameter [2] as [BIGINT] - [6]
insert into parent_children (parent_id, children_id) values (?, ?)
binding parameter [1] as [BIGINT] - [1]
binding parameter [2] as [BIGINT] - [7]
insert into parent_children (parent_id, children_id) values (?, ?)
binding parameter [1] as [BIGINT] - [1]
binding parameter [2] as [BIGINT] - [8]
insert into parent_children (parent_id, children_id) values (?, ?)
binding parameter [1] as [BIGINT] - [1]
binding parameter [2] as [BIGINT] - [9]
insert into parent_children (parent_id, children_id) values (?, ?)
binding parameter [1] as [BIGINT] - [1]
binding parameter [2] as [BIGINT] - [10]
delete from child where id=?
binding parameter [1] as [BIGINT] - [1]
delete from child where id=?
binding parameter [1] as [BIGINT] - [2]
```

앞에서 `children`의 갯수가 많지 않을 때만 큰 일이 안 생긴다고 한 이유가 여기에 있다. 위의 사례에서는 `children`이 10개 밖에 되지 않으므로 insert를 10개 쯤 한다고 해도 사실 거의 티가 나지 않는다. 하지만 10개가 아니라 1000개, 10000개 그 이상이라면? **고작 레코드 2개 삭제하려는 것 뿐인데 1000회, 10000회의 insert가 실행된다.** ㄷㄷㄷ

그런데 왜 이렇게 동작하는 걸까?


# 나름의 사연

실행한 후 `parent_children` 테이블을 보면 다음과 같다.

parent_id | children_id
--- | ---
1 | 3
1 | 4
1 | 5
1 | 6
1 | 7
1 | 8
1 | 9
1 | 10


나: 뭐야, `1 | 1`인 행이랑 `1 | 2`인 행 2개만 지울 수 있었을 것 같은데, 왜 `parent_id`가 1인 걸 몽땅 지워?

Hibernate: 허허.. 그게 말이야.. 허허.. 테이블로 보기엔 저런데.. 허허.. **일대다 단방향이잖아.. 허허.. 그래서.. 허허.. `parent_id`가 1이라는 것을 개별 행에 대한 조건으로 줄 수가 없어..** 허허.. 그래서 `parent_id`가 1인 걸 몽땅 지우고 다시 채웠어.. 허허..

나: 뭐래냐..

이것도 말보다 코드가 더 쉽고 명확한 케이스다. id가 1, 2인 `child`를 삭제하는 코드는 다음과 같다.

```java
List<Child> children = dbParent.getChildren();
children.removeIf(child -> 
        child.getId() == 1L || child.getId() == 2L);  // <-- 여기!!
```

위에 `여기`로 표시한 부분에서 `parent_id`에 대한 조건을 줄 수가 없다. 왜냐고? 위에 Hibernate가 얘기해 준대로 **일대일 단방향이라서 `child`는 `parent`를 모른다. 따라서 `parent_id`를 `children`의 개별 행에 대한 삭제 조건으로 지정할 수가 없다.**

대신에 `dbParent.getChildren()`의 `dbParent`에는 `parent_id`가 1이라는 정보가 있다. 그래서 **`children`를 개별 행 단위로 삭제할 수는 없지만 `parent_children` 테이블에서는 `parent_id`가 1인 행을 모두 삭제할 수는 있다.** 그래서 `parent_id`가 1인 레코드를 모두 delete 한 후에 다시 insert를 반복하는 노가다를 한 것이다.

결국 Hibernate는 주어진 환경에서 최선을 다한 셈이고 아무 죄가 없다. 모두 delete 후 다시 모두 insert 반복으로만 해결할 수 있게 코드를 짠 사람이 잘못이다.


# 해결

이제 문제를 바로잡아보자. 조인테이블 방식의 일대다 단방향 매핑때문에 `children` 쪽에서 행 단위로 `parent_id`를 알 수 없다는 게 원인이었으므로, **어떻게든 `children` 쪽에서 행 단위로 `parent_id`를 알 수 있게 해주면 된다. 즉 테이블 상에서 `children` 쪽에 `parent_id` 컬럼이 추가되도록 매핑하면 된다.**

방법은 두 가지가 있다. 조인테이블이 아닌 조인컬럼 방식의 일대다 단방향 매핑과 일대다 양방향 매핑이다.

먼저 조인컬럼 방식의 일대다 단방향 매핑부터 알아보자.


## 조인컬럼 방식의 일대다 단방향 매핑

이 방식은 Parent에 단 한 줄의 코드만 추가하면 된다. 물론 예제 코드에서만..

```java
@OneToMany(cascade = CascadeType.ALL, orphanRemoval = true)
@JoinColumn(name = "parent_id")  // <-- 여기!!
private List<Child> children = new ArrayList<>();
```

위와 같이 Parent 엔티티에 `@JoinColumn(name = "parent_id")`만 추가해주면 된다.

이제 조인테이블 방식이 아니므로 `parent_children` 테이블은 필요 없고, `child` 테이블에 `parent_id` 컬럼이 추가되고, `child` 테이블의 행 단위로 `parent_id`를 알 수 있으므로 몽창 delete 후 몽창 insert 하는 노가다는 발생하지 않고 id가 1, 2인 `child`만 삭제할 수 있을 것이다.

실행해보면 다음과 같다.

```sql
insert into parent (name) values (?)
binding parameter [1] as [VARCHAR] - [parent 1]
insert into child (name) values (?)
binding parameter [1] as [VARCHAR] - [child 1]
insert into child (name) values (?)
binding parameter [1] as [VARCHAR] - [child 2]
insert into child (name) values (?)
binding parameter [1] as [VARCHAR] - [child 3]
insert into child (name) values (?)
binding parameter [1] as [VARCHAR] - [child 4]
insert into child (name) values (?)
binding parameter [1] as [VARCHAR] - [child 5]
insert into child (name) values (?)
binding parameter [1] as [VARCHAR] - [child 6]
insert into child (name) values (?)
binding parameter [1] as [VARCHAR] - [child 7]
insert into child (name) values (?)
binding parameter [1] as [VARCHAR] - [child 8]
insert into child (name) values (?)
binding parameter [1] as [VARCHAR] - [child 9]
insert into child (name) values (?)
binding parameter [1] as [VARCHAR] - [child 10]
update child set parent_id=? where id=?
binding parameter [1] as [BIGINT] - [1]
binding parameter [2] as [BIGINT] - [1]
update child set parent_id=? where id=?
binding parameter [1] as [BIGINT] - [1]
binding parameter [2] as [BIGINT] - [2]
update child set parent_id=? where id=?
binding parameter [1] as [BIGINT] - [1]
binding parameter [2] as [BIGINT] - [3]
update child set parent_id=? where id=?
binding parameter [1] as [BIGINT] - [1]
binding parameter [2] as [BIGINT] - [4]
update child set parent_id=? where id=?
binding parameter [1] as [BIGINT] - [1]
binding parameter [2] as [BIGINT] - [5]
update child set parent_id=? where id=?
binding parameter [1] as [BIGINT] - [1]
binding parameter [2] as [BIGINT] - [6]
update child set parent_id=? where id=?
binding parameter [1] as [BIGINT] - [1]
binding parameter [2] as [BIGINT] - [7]
update child set parent_id=? where id=?
binding parameter [1] as [BIGINT] - [1]
binding parameter [2] as [BIGINT] - [8]
update child set parent_id=? where id=?
binding parameter [1] as [BIGINT] - [1]
binding parameter [2] as [BIGINT] - [9]
update child set parent_id=? where id=?
binding parameter [1] as [BIGINT] - [1]
binding parameter [2] as [BIGINT] - [10]
*****************************
update child set parent_id=null where parent_id=? and id=?
binding parameter [1] as [BIGINT] - [1]
binding parameter [2] as [BIGINT] - [1]
update child set parent_id=null where parent_id=? and id=?
binding parameter [1] as [BIGINT] - [1]
binding parameter [2] as [BIGINT] - [2]
delete from child where id=?
binding parameter [1] as [BIGINT] - [1]
delete from child where id=?
binding parameter [1] as [BIGINT] - [2]
```

오 역시나 `*****` 아래에 10번의 불필요한 insert 가 모두 사라지고 맨 아래 delete 2회만 실행된 것을 확인할 수 있다.

그런데 `*****` 바로 위에 10번의 update는 또 왜 실행된거지?

이유는 이번에도 단방향이기 때문이다. **조인컬럼 방식으로 변환하면서 `child` 테이블에 `parent_id` 컬럼이 추가되기는 했지만, 단방향이라서 `child`는 `parent`의 존재를 모르므로 `parent_id`의 값을 알 수는 없다.** 뭐랄까 냉장고는 사놨는데 뭘로 채워야할지 모르는..

그래서 **개별 행 단위로는 `parent_id` 컬럼에 값이 없는 채로 insert 되고, insert 된 10개의 행의 `parent_id` 컬럼에는 `dbParent.getChildren()`에서 알아낼 수 있는 `parent_id` 값을 update 를 통해 설정**한다. 하지만 이건 최초에 데이터가 세팅될 때 1회만 그런거고, 이렇게 `parent_id` 값이 저장된 후에는 삭제를 원하는 레코드만 삭제할 수 있게 되므로 조인테이블 방식의 문제는 해결했다고 볼 수 있다.

이제 `*****` 아래에 실행된 쿼리를 살펴보자. update가 2회, delete가 2회 실행됐다. delete 2회만 실행되기를 예상했지만 update 2회가 먼저 실행됐다. 이 부분은 자세히 살펴볼 필요가 있다.

**신동민 님의 도움**으로 정확히 알게 되었는데, 일대다 조인컬럼 방식에서 `children.remove(child)`를 실행해서 `children` 쪽의 레코드 삭제를 시도하면 실제 쿼리는 delete가 아니라 해당 레코드의 `parent_id`에 null을 저장하는 update가 실행된다. 의도와 다르게 동작한 것 같아서 이상해보이지만, 일대다 단방향 매핑에서 **`children.remove(child)`는 사실 `child` 자체를 삭제하라는 게 아니라 `child`가 `parent`의 `children`의 하나로 존재하는 관계를 remove 하라는 것이다. 따라서 `child` 자체를 delete 하는 게 아니라 `parent_id`에 null 값을 넣는 update를 실행하는 게 정확히 맞다.** 이 부분의 코드도 신동민 님이 알려주셨는데 [여기](https://github.com/hibernate/hibernate-orm/blob/master/hibernate-core/src/main/java/org/hibernate/persister/collection/OneToManyPersister.java)에서 확인할 수 있다. 

결국 이번에도 Hibernate는 정확히 동작한다. 관계의 remove를 레코드의 delete로 넘겨짚은 사람이 문제지..

**그럼 마지막에 실행된 2회의 delete는 뭘까? 이건 `orphanRemoval = true`로 설정되어 있기 때문에 2개의 `child` 자체를 delete 한 것**이다.

그런데 사실 Hibernate가 어찌 동작하든 간에, 데이터 처리 관점에서 보자면 원했던 것은 2개의 레코드를 delete 하는 것이었는데, 2회의 update와 2회의 delete가 실행되는 것은 여전히 불필요한 작업이 추가된 것 같다. 하지만 **이를 불필요한 오버헤드라고 부르는 것은 적합하지 않아 보인다.** 

**RDB 관점에서 보면 테이블 사이의 관계는 언제나 양방향이지만 JPA의 엔티티 사이의 관계는 단방향과 양방향이 분명히 다르다.** 따라서 RDB 관점에서야 이걸 오버헤드라고 부를 수도 있겠지만, **단방향으로 매핑된 JPA에서는 레코드의 delete가 아니라 관계의 remove로 동작하는 것이 정확하고 따라서 delete가 아니라 update로 실행되는 것이 맞으므로 불필요한 오버헤드라고 부르는 것은 적합하지 않다.**

그래도 여전히 2회의 delete만으로 끝날 일을 2회의 update와 `orphanRemoval`을 동원해서 2회의 delete로 실행하는 것이 마음에 안 든다면, **RDB 처럼 양방향으로 만들어 주면 JPA도 RDB 처럼 2회의 delete만으로 끝낸다.** 그럼 이제 일대다 양방향 매핑을 살펴보자.

그 전에, 앞에서 조인커럼 방식으로의 전환을 단 한 줄로 적용가능 한 것은 예제 코드라서 가능하다고 했는데, 구체적으로 말하면 `*****` 위에서 update로 값을 자동 세팅해주는 것도 예제 코드라서, **`spring.jpa.properties.hibernate.hbm2ddl.auto` 옵션을 `create` 등 마음대로 줄 수 있기 때문에 가능한 것이고, 실 운영 환경에서는 저렇게 수행할 수 없다.**

운영 환경에서는 `child` 테이블에 `parent_id` 컬럼도 직접 추가해줘야 하고 다음과 같이 update 쿼리를 만들어서 **기존에 `parent_children` 테이블에 있던 값을 기준으로 `child` 테이블의 `parent_id` 컬럼에 수동으로 입력해줘야 한다.**

```sql
update child a
set a.parent_id = (
    select b.parent_id 
    from parent_children b
    where a.id = b.children_id
)
```


## 일대다 양방향 매핑

앞에서 살펴본 것처럼 RDB와 똑같이 동작하기를 원한다면 JPA에서도 양방향으로 매핑을 해줘야 한다. 조인컬럼 방식으로 전환할 때보다는 조금 손이 더 가지만 작업량은 그리 많지 않다.

```java
@Entity
@Getter
public class Parent {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;

    // mappedBy 추가
    @OneToMany(mappedBy = "parent", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Child> children = new ArrayList<>();

    protected Parent() {}

    public Parent(String name) {
        this.name = name;
    }

    public Parent(String name, List<Child> children) {
        this.name = name;
        this.children.addAll(children);
    }
}

@Entity
@Getter
public class Child {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;

    // Parent 필드 추가
    @ManyToOne
    @JoinColumn(name = "parent_id")
    private Parent parent;


    protected Child() {
    }

    // 생성자에 Parent 추가
    public Child(String name, Parent parent) {
        this.name = name;
        this.parent = parent;
    }
}

@Component
@Transactional
@RequiredArgsConstructor(onConstructor = @__(@Autowired))
public class OneToManyRunner implements CommandLineRunner {

    @NonNull
    private ParentRepository parentRepository;

    @Override
    public void run(String... args) throws Exception {
        Parent parent1 = new Parent("parent 1");
        for (int i = 1 ; i <= 10 ; i++) {
            parent1.getChildren().add(
                    new Child("child " + i, parent1)  // 생성 시 parent1 추가
            );
        }
        Parent dbParent = this.parentRepository.saveAndFlush(parent1);

        System.out.println("*****************************");

        List<Child> children = dbParent.getChildren();
        children.removeIf(child -> 
                child.getId() == 1L || child.getId() == 2L);
    }

}
```

실행 결과는 다음과 같다.

```sql
insert into parent (name) values (?)
binding parameter [1] as [VARCHAR] - [parent 1]
insert into child (name, parent_id) values (?, ?)
binding parameter [1] as [VARCHAR] - [child 1]
binding parameter [2] as [BIGINT] - [1]
insert into child (name, parent_id) values (?, ?)
binding parameter [1] as [VARCHAR] - [child 2]
binding parameter [2] as [BIGINT] - [1]
insert into child (name, parent_id) values (?, ?)
binding parameter [1] as [VARCHAR] - [child 3]
binding parameter [2] as [BIGINT] - [1]
insert into child (name, parent_id) values (?, ?)
binding parameter [1] as [VARCHAR] - [child 4]
binding parameter [2] as [BIGINT] - [1]
insert into child (name, parent_id) values (?, ?)
binding parameter [1] as [VARCHAR] - [child 5]
binding parameter [2] as [BIGINT] - [1]
insert into child (name, parent_id) values (?, ?)
binding parameter [1] as [VARCHAR] - [child 6]
binding parameter [2] as [BIGINT] - [1]
insert into child (name, parent_id) values (?, ?)
binding parameter [1] as [VARCHAR] - [child 7]
binding parameter [2] as [BIGINT] - [1]
insert into child (name, parent_id) values (?, ?)
binding parameter [1] as [VARCHAR] - [child 8]
binding parameter [2] as [BIGINT] - [1]
insert into child (name, parent_id) values (?, ?)
binding parameter [1] as [VARCHAR] - [child 9]
binding parameter [2] as [BIGINT] - [1]
insert into child (name, parent_id) values (?, ?)
binding parameter [1] as [VARCHAR] - [child 10]
binding parameter [2] as [BIGINT] - [1]
*****************************
delete from child where id=?
binding parameter [1] as [BIGINT] - [1]
delete from child where id=?
binding parameter [1] as [BIGINT] - [2]
```

오! 처음에 원했던 그대로 delete 만 2회 실행될 뿐 아무런 오버헤드도 발생하지 않는다!

**일대다 양방향 매핑과 일대다 단방향 조인컬럼 매핑의 결과로 나타나는 테이블 구조는 두 방식에서 모두 동일**하다. **두 방식 모두 `child`에 `parent_id` FK 컬럼**을 두게 된다. 

일대다 양방향 매핑과 일대다 단방향 조인컬럼 매핑의 차이점은 다음과 같다.

- 조인컬럼 일대다 단방향 매핑은 `child`가 `parent`를 모르기 때문에, 앞에서 설명한 것처럼 1회성이긴 하지만 `parent_id` 값을 저장하기 위해 update 오버헤드가 발생한다.
- 일대다 양방향 매핑은 `child`가 `parent`를 알기 때문에 불필요한 오버헤드가 발생하지 않는다.

다만 **일대다 양방향 매핑은 도메인 로직 상에서 `parent`를 몰라도 되는 `child`에게 굳이 `parent`를 강제로 알게 만드는 것이 단점**인데, 이 단점은 **`parent`에 대한 public getter 메서드를 만들지 않거나 또는 극단적으로 아예 `parent`에 대한 getter 메서드를 만들지 않는 방식으로 보완할 수 있다.**


# 정리

>일대다 단방향 매핑은 직관적으로는 단순해서 좋지만,  
>조인테이블 방식은 insert가, 조인컬럼 방식은 1회성이긴 하지만 update가 오버헤드로 작용한다.
>
>따라서 1:N에서 N이 큰 상황에서는,
>
>- 오버헤드가 없는 일대다 양방향 매핑을 사용하는 것이 가장 좋고,  
>- 그 다음은 일대다 단방향 조인컬럼 방식,  
>- 그리고 parent 쪽에 `@OneToMany`만 달랑 붙이는 일대다 단방향 조인테이블 방식은 사용하지 않는 것이 좋다.
>
>더 축약하자면, **1:N에서 N이 클 때는 웬만하면 일대다 양방향 매핑을 사용하자.**


# 부록 - 응용편

다음과 같이 하나의 Parent에서 2개의 Child에 대해 1:1, 1:N 연관관계 매핑이 필요하면 어떻게 할까?

```java
@Entity
@Getter
public class Parent {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;

    // 이게 추가된다면?
    private Child singleChild;

    @OneToMany(cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Child> children = new ArrayList<>();

    protected Parent() {}

    public Parent(String name, Child singleChild) {
        this.name = name;
        this.singleChild = singleChild;
    }

    public Parent(String name, Child singleChild, List<Child> children) {
        this.name = name;
        this.singleChild = singleChild;
        this.children.addAll(children);
    }
}

```
이 경우에는 일대일 단방향 매핑을 위해 다음과 같이 Parent 에 `@JoinColumn`을 지정해서 Child를 위한 FK 컬럼을 추가하면, 일대일 단방향 + 일대다 양방향을 함께 쓸 수 있다.

```java
    // 이게 추가된다면?
    //// 일대일 단방향을 쓰되 Child를 가리키는 FK 컬럼을 Parent에 둔다
    @OneToOne
    @JoinColumn(name = "single_child_id")
    private Child singleChild;
```

그럼 `parent` 테이블은 다음과 같이 되고,

`id | name | single_child_id`


`child` 테이블은 다음과 같이 되고, `single_child`와 `children`에 해당하는 데이터가 모두 `child` 테이블에 저장된다.

`id | name | parent_id`

그런데 이렇게 한 테이블에 저장되면 혼동이 될 수도 있을 것 같아 걱정이 된다.

하지만, **일대일 단방향에 의해 저장된 레코드에만 `parent_id` 값이 `NULL`인 상태가 되고,**  
**일대다 양방향에 의해 저장된 레코드에는 `parent_id`에 정상적인 값이 들어가므로 구분 가능**하며 혼동 없이 사용할 수 있다.


