---
title: “VUE3之 compositionAPI"
date: 2019-11-27T15:28:21+08:00
lastmod: 2020-03-12T01:28:21+08:00
draft: false
keywords: ["javascript"]
description: ""
tags: ["javascript"]
categories: ["code"]
author: "Terryzh"

postMetaInFooter: false

---

<!--more-->

## 前言

2019年2月6号，React 发布 16.8.0 版本，新增 Hooks 特性。随即，Vue 在 2019 的各大 JSConf 中也宣告了 Vue3.0 最重要的 RFC，即 Function-based API。Vue3.0 将抛弃之前的 Class API 的提案，选择了 Function API。目前，[vue 官方](https://github.com/vuejs) 也提供了 Vue3.0 特性的尝鲜版本，前段时间叫 `vue-function-api`，目前已经改名叫 `composition-api`。

## 一、Composition API

首先，我们得了解一下，Composition API 设计初衷是什么？



![1-vuecomp](http://terryzhblog.s3-cn-south-1.qiniucs.com/uPic/1-vuecomp.png)



1. 逻辑组合和复用
2. 类型推导：Vue3.0 最核心的点之一就是使用 TS 重构，以实现对 TS 丝滑般的支持。而基于函数 的 API 则天然对类型推导很友好。
3. 打包尺寸：每个函数都可作为 named ES export 被单独引入，对 tree-shaking 很友好；其次所有函数名和 setup 函数内部的变量都能被压缩，所以能有更好的压缩效率。

我们再来具体了解一下 **逻辑组合和复用** 这块。

开始之前，我们先回顾下目前 Vue2.x 对于**逻辑复用的方案**都有哪些？如图



![2-vuecomp](http://terryzhblog.s3-cn-south-1.qiniucs.com/uPic/2-vuecomp.png)



其中 Mixins 和 HOC 都可能存在 **①模板数据来源不清晰** 的问题。

并且在 mixin 的属性、方法的命名以及 HOC 的 props 注入也可能会产生 **②命名空间冲突的问题**。

最后，由于 HOC 和 Renderless Components 都需要额外的组件实例来做逻辑封装，会导致**③无谓的性能开销**。

### 1、基本用法

OK，大致了解了 Composition API 设计的目的了，接下来，我们来看看其基本用法。

安装

```bash
npm i @vue/composition-api -S
```

使用

```js
import Vue from 'vue'
import VueCompositionApi from '@vue/composition-api'

Vue.use(VueCompositionApi)
```

如果，你项目是用的 TS，那么请使用 `createComponent` 来定义组件，这样你才能使用类型推断

```typescript
import { createComponent } from '@vue/composition-api'

const Component = createComponent({
  // ...
})
```

由于我本身项目使用的就是 TS，所以这里 JS 的一些用法我就不过多提及，上个尤大的例子之后就不提了

```typescript
import { value, computed, watch, onMounted } from 'vue'

const App = {
  template: `
    <div>
      <span>count is {{ count }}</span>
      <span>plusOne is {{ plusOne }}</span>
      <button @click="increment">count++</button>
    </div>
  `,
  setup() {
    // reactive state
    const count = value(0)
    // computed state
    const plusOne = computed(() => count.value + 1)
    // method
    const increment = () => { count.value++ }
    // watch
    watch(() => count.value * 2, val => {
      console.log(`count * 2 is ${val}`)
    })
    // lifecycle
    onMounted(() => {
      console.log(`mounted`)
    })
    // expose bindings on render context
    return {
      count,
      plusOne,
      increment
    }
  }
}
```

OK，回到 TS，我们看看其基本用法，其实用法基本一致。

```vue
<template>
  <div class="hooks-one">
    <h2>{{ msg }}</h2>
    <p>count is {{ count }}</p>
    <p>plusOne is {{ plusOne }}</p>
    <button @click="increment">count++</button>
  </div>
</template>

<script lang="ts">
import { ref, computed, watch, onMounted, Ref, createComponent } from '@vue/composition-api'

export default createComponent({
  props: {
    name: String
  },
  setup (props) {
    const count: Ref<number> = ref(0)
    // computed
    const plusOne = computed(() => count.value + 1)
    // method
    const increment = () => { count.value++ }
    // watch
    watch(() => count.value * 2, val => {
      console.log(`count * 2 is ${val}`)
    })
		// lifecycle
    onMounted(() => {
      console.log('onMounted')
    })
		// expose bindings on render context
    return {
      count,
      plusOne,
      increment,
      msg: `hello ${props.name}`
    }
  }
})
</script>
```

### 2、组合函数

我们已经了解到 Composition API 初衷之一就是做逻辑组合，这就有了所谓的**组合函数**。

尤大在 [Vue Function-based API RFC](https://zhuanlan.zhihu.com/p/68477600) 中举了一个鼠标位置侦听的例子，我这里举一个带业务场景的例子吧。

**场景：我需要在一些特定的页面修改页面 title，而我又不想做成全局。**

传统做法我们会直接将逻辑丢到 mixins 中，做法如下

```typescript
import { Vue, Component } from 'vue-property-decorator'

declare module 'vue/types/vue' {
  interface Vue {
    setTitle (title: string): void
  }
}

function setTitle (title: string) {
  document.title = title
}

@Component
export default class SetTitle extends Vue {
  setTitle (title: string) {
    setTitle.call(this, title)
  }
}
```

然后在页面引用

```typescript
import SetTitle from '@/mixins/title'

@Component({
  mixins: [ SetTitle ]
})
export default class Home extends Vue {
  mounted () {
    this.setTitle('首页')
  }
}
```

那么，让我们使用 **Composition API** 来做处理，看看又是如何做的

```typescript
export function setTitle (title: string) {
  document.title = title
}
```

然后在页面引用

```typescript
import { setTitle } from '@/hooks/title'
import { onMounted, createComponent } from '@vue/composition-api'

export default createComponent({
  setup () {
    onMounted(() => {
      setTitle('首页')
    })
  }
})
```

能看出来，我们只需要将需要复用的逻辑抽离出来，然后只需直接在 `setup()` 中直接使用即可，非常的方便。

当然你硬要做成全局也不是不行，这种情况一般会做成全局指令，如下

```typescript
import Vue, { VNodeDirective } from 'vue'

Vue.directive('title', {
  inserted (el: any, binding: VNodeDirective) {
    document.title = el.dataset.title
  }
})
```

页面使用如下

```vue
<template>
  <div class="home" v-title data-title="首页">
    home
  </div>
</template>
```

有些小伙伴可能看完这个场景会觉得，我这样明显使用全局指令的方式更便捷啊，Vue3.0 组合函数的优势在哪呢？

别急，上面的例子其实只是为了告诉大家**如何将你们目前 Mixins 使用组合函数做改造**。

在之后的实战环节，还有很多真实场景呢，如果你等不及，可以直接跳过去看第二章。

### 3、setup() 函数

`setup()` 是 Vue3.0 中引入的一个新的组件选项，setup 组件逻辑的地方。

#### i. 初始化时机

`setup()` 什么时候进行初始化呢？我们看张图



![3-vuecomp](http://terryzhblog.s3-cn-south-1.qiniucs.com/uPic/3-vuecomp.png)



setup 是在组件实例被创建时， 初始化了 props 之后调用，处于 created 前。

这个时候我们能接收初始 props 作为参数。

```typescript
import { Component, Vue, Prop } from 'vue-property-decorator'

@Component({
  setup (props) {
    console.log('setup', props.test)
    return {}
  }
})
export default class Hooks extends Vue {
  @Prop({ default: 'hello' })
  test: string

  beforeCreate () {
    console.log('beforeCreate')
  }

  created () {
    console.log('created')
  }
}
```

控制台打印顺序如下



<img src="http://terryzhblog.s3-cn-south-1.qiniucs.com/uPic/4-vuecomp.png" alt="4-vuecomp" style="zoom:25%;" />



其次，我们从上面的所有例子能发现，`setup()` 和 `data()` 很像，都可以返回一个对象，而这个对象上的属性则会直接暴露给模板渲染上下文：

```vue
<template>
  <div class="hooks">
    {{ msg }}
  </div>
</template>

<script lang="ts">
import { createComponent } from '@vue/composition-api'

export default createComponent({
  props: {
    name: String
  },
  setup (props) {
    return {
      msg: `hello ${props.name}`
    }
  }
})
</script>
```

#### ii. reactivity api

与 React Hooks 的函数增强路线不同，Vue Hooks 走的是 value 增强路线，它要做的是如何从一个响应式的值中，衍生出普通的值以及 view。

在 `setup()` 内部，Vue 则为我们提供了一系列响应式的 API，比如 ref，它返回一个 Ref 包装对象，并在 view 层引用的时候自动展开

```vue
<template>
  <div class="hooks">
    <button @click="count++">{{ count }}</button>
  </div>
</template>

<script lang="ts">
import { ref, Ref, createComponent } from '@vue/composition-api'

export default createComponent({
  setup (props) {
    const count: Ref<number> = ref(0)
    console.log(count.value)
    return {
      count
    }
  }
})
</script>
```

然后便是我们常见的 computed 和 watch 了

```typescript
import { ref, computed, Ref, createComponent } from '@vue/composition-api'

export default createComponent({
  setup (props) {
    const count: Ref<number> = ref(0)
    const plusOne = computed(() => count.value + 1)
    watch(() => count.value * 2, val => {
      console.log(`count * 2 is ${val}`)
    })

    return {
      count,
      plusOne
    }
  }
})
```

而我们通过计算产生的值，即使不进行类型申明，也能直接拿到进行其类型做推导，因为它是依赖 Ref 进行计算的



![5-vuecomp](http://terryzhblog.s3-cn-south-1.qiniucs.com/uPic/5-vuecomp.png)



`setup()` 中其它的内部 API 以及生命周期函数我这就不过多介绍了，想了解的直接查看 [原文](https://zhuanlan.zhihu.com/p/68477600)

### 4、Props 类型推导

关于 Props 类型推导，一开始我就有说过，在 TS 中，你想使用类型推导，那么你必须在 createComponent 函数来定义组件

```typescript
import { createComponent } from '@vue/composition-api'

const MyComponent = createComponent({
  props: {
    msg: String
  },
  setup(props) {
    props.msg // string | undefined
    return {}
  }
})
```

当然，props 选项并不是必须的，假如你不需要运行时的 props 类型检查，你可以直接在 TS 类型层面进行申明

```typescript
import { createComponent } from '@vue/composition-api'

interface Props {
  msg: string
}
export default createComponent({
  props: ['msg'],
  setup (props: Props, { root }) {
    const { $createElement: h } = root
    return () => h('div', props.msg)
  }
})
```

对于复杂的 Props 类型，你可以使用 Vue 提供的 PropType 来申明任意复杂度的 props 类型，不过按照其类型申明来看，我们需要用 any 做一层强制转换

```typescript
export type Prop<T> = { (): T } | { new(...args: any[]): T & object } | { new(...args: string[]): Function }

export type PropType<T> = Prop<T> | Prop<T>[]

import { createComponent } from '@vue/composition-api'
import { PropType } from 'vue'

export default createComponent({
  props: {
    options: (null as any) as PropType<{ msg: string }>
  },
  setup (props) {
    props.options // { msg: string } | undefined
    return {}
  }
})
```

## 二、业务实践

目前为止，我们对 Vue3.0 的 Composition API 有了一定的了解，也清楚了其适合使用的一些实际业务场景。

而我在具体业务中又做了哪些尝鲜呢？接下来，让我们一起进入真正的实战阶段

### 1、列表分页查询

**场景：我需要对业务中的列表做分页查询，其中包括页码、页码大小这两个通用查询条件，以及一些特定条件做查询，比如关键字、状态等。**

在 Vue2.x 中，我们的做法有两种，如图所示



![6-vuecomp](http://terryzhblog.s3-cn-south-1.qiniucs.com/uPic/6-vuecomp.png)



1. 最简单的方式就是直接将通用查询存储到一个地方，需要使用查询的地方直接引入即可，然后在页面做一系列重复的操作，这个时候最考验 `Ctrl + C`、`Ctrl + V` 的功力了。
2. 将其通用的变量和方法抽离到 `mixins` 当中，然后页面直接使用即可，可免去一大堆重复的工作。但是当我们页面存在一个以上的分页列表时，问题就来了，我的变量会被冲掉，导致查询出错。

所以现在，我们试着使用 Vue3.0 的特性，将其重复的逻辑抽离出来放置到 `@/hooks/paging-query.ts` 中

```typescript
import { ref, Ref, reactive } from '@vue/composition-api'
import { UnwrapRef } from '@vue/composition-api/dist/reactivity'

export function usePaging () {
  const conditions: UnwrapRef<{
    page: Ref<number>,
    pageSize: Ref<number>,
    totalCount: Ref<number>
  }> = reactive({
    page: ref(1),
    pageSize: ref(10),
    totalCount: ref(1000)
  })

  const handleSizeChange = (val: number) => {
    conditions.pageSize = val
  }

  const handleCurrentChange = (val: number) => {
    conditions.page = val
  }

  return {
    conditions,
    handleSizeChange,
    handleCurrentChange
  }
}
```

然后我们在具体页面中对其进行组合去使用

```vue
<template>
  <div class="paging-demo">
    <el-input v-model="query"></el-input>
    <el-pagination
      background
      @size-change="handleSizeChange"
      @current-change="handleCurrentChange"
      :current-page.sync="cons.page"
      :page-sizes="[10, 20, 30, 50]"
      :page-size.sync="cons.pageSize"
      layout="prev, pager, next, sizes"
      :total="cons.totalCount">
    </el-pagination>
  </div>
</template>

<script lang="ts">
import { usePaging } from '@/hooks/paging-query'
import { ref, Ref, watch } from '@vue/composition-api'

export default createComponent({
  setup () {
    const { conditions: cons, handleSizeChange, handleCurrentChange } = usePaging()
    const query: Ref<string> = ref('')
    watch([
      () => cons.page,
      () => cons.pageSize,
      () => query.value
    ], ([val1, val2, val3]) => {
      console.log('conditions changed，do search', val1, val2, val3)
    })
    return {
      cons,
      query,
      handleSizeChange,
      handleCurrentChange
    }
  }
})
</script>
```

从这个例子我们能看出来，暴露给模板的属性来源非常清晰，直接从 `usePaging()` 返回；并且能够随意重命名，所以也不会有命名空间冲突的问题；更不会有额外的组件实例带来的性能损耗。

怎么样，有没有点真香的感觉了。

### 2、user-select 组件

**场景：在我负责的业务中，有一个通用的业务组件，我称之为 user-select，它是一个人员选择组件**。如图



![7-vuecomp](http://terryzhblog.s3-cn-south-1.qiniucs.com/uPic/7-vuecomp.png)



关于改造前后的对比我们先看张图，好大致有个了解



![8-vuecomp](http://terryzhblog.s3-cn-south-1.qiniucs.com/uPic/8-vuecomp.png)



在 Vue2.x 中，它通用的业务逻辑和数据并没有得到很好的处理，大致原因和上面那个案例原因差不多。

然后我每次想要使用的时候需要做以下操作，这充分锻炼了我  `Ctrl + C`、`Ctrl + V` 的功力

```typescript
<template>
  <div class="demo">
    <user-select
      :options="users"
      :user.sync="user"
      @search="adminSearch" />
  </div>
</template>

<script lang="ts">
import { Component, Prop, Vue } from 'vue-property-decorator'
import { Action } from 'vuex-class'
import UserSelect from '@/views/service/components/user-select.vue'

@Component({
  components: { UserSelect }
})
export default class Demo extends Vue {
  user = []
  users: User[] = []

  @Prop()
  visible: boolean
  
  @Action('userSearch') userSearch: Function

  adminSearch (query: string) {
    this.userSearch({ search: query, pageSize: 200 }).then((res: Ajax.AjaxResponse) => {
      this.users = res.data.items
    })
  }
}
</script>
```

那么使用 Composition API 后就能避免掉这个情况么？答案肯定是能避免掉。

我们先看看，使用 Vue3.0 进行改造 `setup` 中的逻辑如何

```typescript
import { ref, computed, Ref, watch, createComponent } from '@vue/composition-api'
import { userSearch, IOption } from '@/hooks/user-search'

export default createComponent({
  setup (props, { emit, root }) {
    let isFirstFoucs: Ref<boolean> = ref(false)
    let showCheckbox: Ref<boolean> = ref(true)
	// computed
    // 当前选中选项
    const chooseItems: Ref<string | string[]> = ref(computed(() => props.user))
    // 选项去重(包含对象的情况)
    const uniqueOptions = computed(() => {
      const originArr: IOption[] | any = props.customSearch ? props.options : items.value
      const newArr: IOption[] = []
      const strArr: string[] = []
      originArr.forEach((item: IOption) => {
        if (!strArr.includes(JSON.stringify(item))) {
          strArr.push(JSON.stringify(item))
          newArr.push(item)
        }
      })
      return newArr
    })
	// watch
    watch(() => chooseItems.value, (val) => {
      emit('update:user', val)
      emit('change', val)
    })
		// methods
    const remoteMethod = (query: string) => {
      // 可抛出去自定义，也可使用内部集成好的方法处理 remote
      if (props.customSearch) {
        emit('search', query)
      } else {
        handleUserSearch(query)
      }
    }
    const handleFoucs = (event) => {
      if (isFirstFoucs.value) {
        return false
      }
      remoteMethod(event.target.value)
      isFirstFoucs.value = true
    }
    const handleOptionClick = (item) => {
      emit('option-click', item)
    }
    // 显示勾选状态，若是单选则无需显示 checkbox
    const isChecked = (value: string) => {
      let checked: boolean = false
      if (typeof chooseItems.value === 'string') {
        showCheckbox.value = false
        return false
      }
      chooseItems.value.forEach((item: string) => {
        if (item === value) {
          checked = true
        }
      })
      return checked
    }
    return {
      isFirstFoucs, showCheckbox, // ref
      uniqueOptions, chooseItems, // computed
      handleUserSearch, remoteMethod, handleFoucs, handleOptionClick, isChecked // methods
    }
  }
})
```

然后我们再将可以重复使用的逻辑和数据抽离到 `hooks/user-search.ts` 中

```typescript
import { ref, Ref } from '@vue/composition-api'

export interface IOption {
  [key: string]: string
}

export function userSearch ({ root }) {
  const items: Ref<IOption[]> = ref([])

  const handleUserSearch = (query: string) => {
    root.$store.dispatch('userSearch', { search: query, pageSize: 25 }).then(res => {
      items.value = res.data.items
    })
  }

  return { items, handleUserSearch }
}
```

然后即可在组件中直接使用（当然你可以随便重命名）

```typescript
import { userSearch, IOption } from '@/hooks/user-search'

export default createComponent({
  setup (props, { emit, root }) {
    const { items, handleUserSearch } = userSearch({ root })
  }
})
```

最后，避免掉命名冲突的后患，有做了业务集成后，我现在使用 `` 组件只需这样即可

```html
 <user-select :user.sync="user" />
```
