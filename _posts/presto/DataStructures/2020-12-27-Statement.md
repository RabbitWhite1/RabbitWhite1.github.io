---
layout: post
title:  Presto/Hetu 源码 —— class Statement
date:   2020-12-27 23:29:00 +0800
image:  /assets/images/presto/presto-hetu.png
author: Hank Wang
tags: presto/hetu 源码阅读
---

**Statement 类的相关介绍**

###### Statement

`Statement` 是一个继承于 `io.prestosql.sql.tree.Node` 的抽象类.

直观感受一下, 它主要内容就是
```java
Query{
    queryBody=QuerySpecification{
        select=Select{distinct=false, selectItems=[*]
    },
    from=Optional[
        Join{
            type=INNER,
            left=Table{catalog_sales}, 
            right=Table{inventory}, 
            criteria=Optional[JoinOn{(cs_item_sk = inv_item_sk)}]
        }
    ],
    where=null,
    groupBy=Optional.empty,
    having=null,
    orderBy=Optional.empty, 
    offset=null, 
    limit=Limit{limit=1}}, 
    orderBy=Optional.empty}
```

对应 sql 代码为
```sql
select *
from catalog_sales
join inventory on (cs_item_sk = inv_item_sk)
limit 10;
```