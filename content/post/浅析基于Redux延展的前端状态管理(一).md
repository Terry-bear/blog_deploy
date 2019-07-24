---
title: "TODO浅析基于Redux延展的前端状态管理(一)"
date: 2019-06-27T20:29:22+08:00
lastmod: 2019-06-27T20:29:22+08:00
draft: false
keywords: [“javascript”, “Redux”, "React"]
description: ""
tags: ["javascript", “Redux”, “React"]
categories: ["code"]
author: "Terryzh"

postMetaInFooter: false

---

<!--more-->

## 序

最近研究了一下一直云里雾里的前端传输问题。

随着前端开发的逐渐复杂化，前端的状态管理和参数传递变得越来越复杂。

单纯的从`URL`或者是`localStorage`、`sessionStorage`来取值变的繁琐且难用。

基于这一点，众多的框架都封装了自己的状态管理层。

包括

* `VUE`的`Vuex`
* `React`的`Redux`
* 异步处理数据状态的`Redux-thunk`、`Redux-saga`等等
* 火热的函数式编程的`RxJS`
* 阿里开源的基于`Redux`、`React-router`封装的`Dva`



> 本系列分为三个小结。
>
> 第一小结主要介绍Redux的基础易用和原理剖析。
>
> 第二小结主要对比Vuex和Redux等在业务中解决的问题。
>
> 第三小结主要分析目前前端状态管理层的优劣和未来处理前端状态的趋势。



## 什么是Redux?

Redux 是 JavaScript 状态容器，提供可预测化的状态管理。

可以让你构建一致化的应用，运行于不同的环境（客户端、服务器、原生应用），并且易于测试。

在开始阅读之前，或许你有一个疑问？

我们是不是真的需要Redux这个东西，毕竟是需要学习成本的。

[You Might Not Need Redux戳我看👉]: https://medium.com/@dan_abramov/you-might-not-need-redux-be46360cf367	"戳我看👉"











## 为什么需要Redux?



## Redux如何和UI组件关联的？



## Redux的底层实现原理是什么？
