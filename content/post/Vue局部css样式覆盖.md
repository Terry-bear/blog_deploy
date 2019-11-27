---
title: "Vue局部css样式覆盖"
date: 2019-11-14T16:05:08+08:00
lastmod: 2019-11-14T16:05:08+08:00
draft: false
keywords: ["javascript"]
description: ""
tags: ["javascript"]
categories: ["code"]
author: "Terryzh"

postMetaInFooter: false

---

<!--more-->

### 前言

VUE 和 React 中 CSS 样式覆盖问题。



# VUE

## 1 局部样式

1.Vue中style标签的scoped属性表示它的样式只作用于当前模块，是样式私有化.

2.渲染的规则/原理： 给HTML的DOM节点添加一个 不重复的data属性 来表示 唯一性 在对应的 CSS选择器 末尾添加一个当前组件的 data属性选择器来私有化样式，如：.demo[data-v-2311c06a]{} 如果引入 less 或 sass 只会在最后一个元素上设置

```vue
// 原始代码
<template>
  <div class="demo">
    <span class="content">
      Vue.js scoped
    </span>
  </div>
</template>

<style lang="less" scoped>
  .demo{
    font-size: 16px;
    .content{
      color: red;
    }
  }
</style>

// 浏览器渲染效果
<div data-v-fed36922>
  Vue.js scoped
</div>
<style type="text/css">
.demo[data-v-039c5b43] {
  font-size: 14px;
}
.demo .content[data-v-039c5b43] { //.demo 上并没有加 data 属性
  color: red;
}
</style>
```

## 2 deep 属性

```vue
// 上面样式加一个 /deep/
<style lang="less" scoped>
  .demo{
    font-size: 14px;
  }
  .demo /deep/ .content{
    color: blue;
  }
</style>

// 浏览器编译后
<style type="text/css">
.demo[data-v-039c5b43] {
  font-size: 14px;
}
.demo[data-v-039c5b43] .content {
  color: blue;
}
</style>
```



# React

