---
title: "React开发技巧之组件通信"
date: 2019-11-14T15:05:01+08:00
lastmod: 2019-11-14T15:05:01+08:00
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

React 开发中常用的技巧总结。提高代码整洁性和易读性。

#  组件通讯

## 1.1 props

子组件

```jsx
import React from "react";
import PropTypes from "prop-types";
import { Button } from "antd";

export default class EightteenChildOne extends React.Component {
  static propTypes = { //propTypes校验传入类型,详情在技巧11
    name: PropTypes.string
  };

  click = () => {
    // 通过触发方法子传父
    this.props.eightteenChildOneToFather("这是 props 改变父元素的值");
  };

  render() {
    return (
      <div>
        <div>这是通过 props 传入的值{this.props.name}</div>
        <Button type="primary" onClick={this.click}>
          点击改变父元素值
        </Button>
      </div>
    );
  }
}
```

父组件

```jsx
<EightteenChildOne name={'props 传入的 name 值'} eightteenChildOneToFather={(mode)=>this.eightteenChildOneToFather(mode)}></EightteenChildOne> 
```

props 传多个值时:
 传统写法

```jsx
const {dataOne,dataTwo,dataThree} = this.state
<Com dataOne={dataOne} dataTwo={dataTwo} dataThree={dataThree}>
```

升级写法

```jsx
<Com {...{dataOne,dataTwo,dataThree}}>
或者
const ParentParams = {dataOne, dataTwo, dataThree}
<Com {...ParentParams}>
```

## 1.2 props 升级版

原理:**子组件里面利用 props 获取父组件方法直接调用,从而改变父组件的值**

> 注意: 此方法和 props 大同小异,都是 props 的应用,所以在源码中没有举例

调用父组件方法改变该值

```jsx
// 父组件
state = {
  count: {}
}
changeParentState = obj => {
    this.setState(obj);
}
// 子组件
onClick = () => {
    this.props.changeParentState({ count: 2 });
}
```

## 1.3 Provider,Consumer和Context

1. `Context`在 `16.x` 之前是定义一个全局的对象,类似 `vue` 的 `eventBus`,如果组件要使用到该值直接通过`this.context`获取

```jsx
//根组件
class MessageList extends React.Component {
  getChildContext() {
    return {color: "purple",text: "item text"};
  }

  render() {
    const children = this.props.messages.map((message) =>
      <Message text={message.text} />
    );
    return <div>{children}</div>;
  }
}

MessageList.childContextTypes = {
  color: React.PropTypes.string
  text: React.PropTypes.string
};

//中间组件
class Message extends React.Component {
  render() {
    return (
      <div>
        <MessageItem />
        <Button>Delete</Button>
      </div>
    );
  }
}

//孙组件(接收组件)
class MessageItem extends React.Component {
  render() {
    return (
      <div>
        {this.context.text}
      </div>
    );
  }
}

MessageItem.contextTypes = {
  text: React.PropTypes.string //React.PropTypes在 15.5 版本被废弃,看项目实际的 React 版本
};

class Button extends React.Component {
  render() {
    return (
      <button style={{background: this.context.color}}>
        {this.props.children}
      </button>
    );
  }
}

Button.contextTypes = {
  color: React.PropTypes.string
};
```

2. `16.x` 之后的`Context`使用了`Provider`和`Customer`模式,在顶层的`Provider`中传入`value`，在子孙级的`Consumer`中获取该值，并且能够传递函数，用来修改`context` 声明一个全局的 `context` 定义.

   context.js

```jsx
import React from 'react'
let { Consumer, Provider } = React.createContext();//创建 context 并暴露Consumer和Provider模式
export {
    Consumer,
    Provider
}
```

父组件导入

```jsx
// 导入 Provider
import {Provider} from "../../utils/context"

<Provider value={name}>
  <div style={{border:'1px solid red',width:'30%',margin:'50px auto',textAlign:'center'}}>
    <p>父组件定义的值:{name}</p>
    <EightteenChildTwo></EightteenChildTwo>
  </div>
</Provider>
```

子组件

```jsx
// 导入Consumer
import { Consumer } from "../../utils/context"
function Son(props) {
  return (
    //Consumer容器,可以拿到上文传递下来的name属性,并可以展示对应的值
    <Consumer>
      {name => (
        <div
          style={{
            border: "1px solid blue",
            width: "60%",
            margin: "20px auto",
            textAlign: "center"
          }}
        >
        // 在 Consumer 中可以直接通过 name 获取父组件的值
          <p>子组件。获取父组件的值:{name}</p>
        </div>
      )}
    </Consumer>
  );
}
export default Son;
```

## 1.4 EventEmitter

[EventEmiter 传送门](https://segmentfault.com/a/1190000012361461?utm_source=tag-newest#articleHeader6) 使用 events 插件定义一个全局的事件机制

## 1.5 路由传参

1. params

```jsx
<Route path='/path/:name' component={Path}/>
<link to="/path/2">xxx</Link>
this.props.history.push({pathname:"/path/" + name});
读取参数用:this.props.match.params.name
```

2. query

```jsx
<Route path='/query' component={Query}/>
<Link to={{ path : '/query' , query : { name : 'sunny' }}}>
this.props.history.push({pathname:"/query",query: { name : 'sunny' }});
读取参数用: this.props.location.query.name
```

3. state

```jsx
<Route path='/sort ' component={Sort}/>
<Link to={{ path : '/sort ' , state : { name : 'sunny' }}}> 
this.props.history.push({pathname:"/sort ",state : { name : 'sunny' }});
读取参数用: this.props.location.query.state 
```

4. search

```jsx
<Route path='/web/search ' component={Search}/>
<link to="web/search?id=12121212">xxx</Link>
this.props.history.push({pathname:`/web/search?id ${row.id}`});
读取参数用: this.props.location.search
```

5. 优缺点

```md
1. params和 search 只能传字符串,刷新页面参数不会丢
2. query和 state 可以传对象,但是刷新页面参数会丢失
```

## 1.6 onRef

原理: `onRef` 通讯原理就是通过 `props` 的事件机制将组件的 `this`(组件实例)当做参数传到父组件,父组件就可以操作子组件的 `state` 和方法

`EightteenChildFour.jsx`

```jsx
export default class EightteenChildFour extends React.Component {
  state={
      name:'这是组件EightteenChildFour的name 值'
  }

  componentDidMount(){
    this.props.onRef(this)
    console.log(this) // ->将EightteenChildFour传递给父组件this.props.onRef()方法
  }

  click = () => {
    this.setState({name:'这是组件click 方法改变EightteenChildFour改变的name 值'})
  };

  render() {
    return (
      <div>
        <div>{this.state.name}</div>
        <Button type="primary" onClick={this.click}>
          点击改变组件EightteenChildFour的name 值
        </Button>
      </div>
    );
  }
}
```

`eighteen.jsx`

```jsx
<EightteenChildFour onRef={this.eightteenChildFourRef}></EightteenChildFour>

eightteenChildFourRef = (ref)=>{
  console.log('eightteenChildFour的Ref值为')
  // 获取的 ref 里面包括整个组件实例
  console.log(ref)
  // 调用子组件方法
  ref.click()
}
```

## 1.7 ref

原理:就是通过 `React` 的 `ref` 属性获取到整个子组件实例,再进行操作

`EightteenChildFive.jsx`

```jsx
// 常用的组件定义方法
export default class EightteenChildFive extends React.Component {
  state={
      name:'这是组件EightteenChildFive的name 值'
  }

  click = () => {
    this.setState({name:'这是组件click 方法改变EightteenChildFive改变的name 值'})
  };

  render() {
    return (
      <div>
        <div>{this.state.name}</div>
        <Button type="primary" onClick={this.click}>
          点击改变组件EightteenChildFive的name 值
        </Button>
      </div>
    );
  }
}
```

`eighteen.jsx`

```jsx
// 钩子获取实例
componentDidMount(){
    console.log('eightteenChildFive的Ref值为')
      // 获取的 ref 里面包括整个组件实例,同样可以拿到子组件的实例
    console.log(this.refs["eightteenChildFiveRef"])
  }

// 组件定义 ref 属性
<EightteenChildFive ref="eightteenChildFiveRef"></EightteenChildFive>
```

## 1.8 redux

redux 是一个独立的事件通讯插件,这里就不做过多的叙述 [请戳传送门:](https://www.redux.org.cn/docs/introduction/CoreConcepts.html)

## 1.9 MobX

MobX 也是一个独立的事件通讯插件,这里就不做过多的叙述
 [请戳传送门:](https://cn.mobx.js.org/)

## 1.10 flux

flux 也是一个独立的事件通讯插件,这里就不做过多的叙述
 [请戳传送门:](https://facebook.github.io/flux/docs/flux-utils#!)

## 1.11 hooks

1. `hooks` 是利用 `userReducer` 和 `context` 实现通讯,下面模拟实现一个简单的 `redux`

2. 核心文件分为 `action`,`reducer`,`types`

   `action.js`

```jsx
import * as Types from './types';

export const onChangeCount = count => ({
    type: Types.EXAMPLE_TEST,
    count: count + 1
})
```

`reducer.js`

```jsx
import * as Types from "./types";
export const defaultState = {
  count: 0
};
export default (state, action) => {
  switch (action.type) {
    case Types.EXAMPLE_TEST:
      return {
        ...state,
        count: action.count
      };
    default: {
      return state;
    }
  }
};
```

`types.js`

```jsx
export const EXAMPLE_TEST = 'EXAMPLE_TEST';
```

`eightteen.jsx`

```jsx
export const ExampleContext = React.createContext(null);//创建createContext上下文

// 定义组件
function ReducerCom() {
  const [exampleState, exampleDispatch] = useReducer(example, defaultState);

  return (
    <ExampleContext.Provider
      value={{ exampleState, dispatch: exampleDispatch }}
    >
      <EightteenChildThree></EightteenChildThree>
    </ExampleContext.Provider>
  );
}
```

`EightteenChildThree.jsx`

 // 组件

```jsx
import React, {  useEffect, useContext } from 'react';
import {Button} from 'antd'

import {onChangeCount} from '../../pages/TwoTen/store/action';
import { ExampleContext } from '../../pages/TwoTen/eighteen';

const Example = () => {

    const exampleContext = useContext(ExampleContext);

    useEffect(() => { // 监听变化
        console.log('变化执行啦')
    }, [exampleContext.exampleState.count]);

    return (
        <div>
            <p>值为{exampleContext.exampleState.count}</p>
            <Button onClick={() => exampleContext.dispatch(onChangeCount(exampleContext.exampleState.count))}>点击加 1</Button>
        </div>
    )
}

export default Example;
```

3. `hooks`其实就是对原有`React` 的 `API` 进行了封装,暴露比较方便使用的钩子;

4. 钩子有:

| 钩子名               | 作用                                                         |
| -------------------- | ------------------------------------------------------------ |
| useState             | 初始化和设置状态                                             |
| useEffect            | `componentDidMount`，`componentDidUpdate`和`componentWillUnmount`和结合体,所以可以监听`useState`定义值的变化 |
| useContext           | 定义一个全局的对象,类似 `context`                            |
| useReducer           | 可以增强函数提供类似 `Redux` 的功能                          |
| useCallback          | 记忆作用,共有两个参数，第一个参数为一个匿名函数，就是我们想要创建的函数体。第二参数为一个数组，里面的每一项是用来判断是否需要重新创建函数体的变量，如果传入的变量值保持不变，返回记忆结果。如果任何一项改变，则返回新的结果 |
| useMemo              | 作用和传入参数与 `useCallback` 一致,`useCallback`返回函数,`useDemo` 返回值 |
| useRef               | 获取 `ref` 属性对应的 `dom`                                  |
| useImperativeMethods | 自定义使用 `ref` 时公开给父组件的实例值                      |
| useMutationEffect    | 作用与 `useEffect` 相同，但在更新兄弟组件之前，它在 `React` 执行其`DOM`改变的同一阶段同步触发 |
| useLayoutEffect      | 作用与 `useEffect` 相同，但在所有 `DOM` 改变后同步触发       |

5. `useImperativeMethods`

```jsx
function FancyInput(props, ref) {
  const inputRef = useRef();
  useImperativeMethods(ref, () => ({
    focus: () => {
      inputRef.current.focus();
    }
  }));
  return <input ref={inputRef} ... />;
}
FancyInput = forwardRef(FancyInput);
```



## 1.12 对比

| 方法                       | 优点                                               | 缺点                                  |
| -------------------------- | -------------------------------------------------- | ------------------------------------- |
| props                      | 不需要引入外部插件                                 | 兄弟组件通讯需要建立共同父级组件,麻烦 |
| props 升级版               | 不需要引入外部插件,子传父,不需要在父组件用方法接收 | 同 props                              |
| Provider,Consumer和Context | 不需要引入外部插件,跨多级组件或者兄弟组件通讯利器  | 状态数据状态追踪麻烦                  |
| EventEmitter               | 可支持兄弟,父子组件通讯                            | 要引入外部插件                        |
| 路由传参                   | 可支持兄弟组件传值,页面简单数据传递非常方便        | 父子组件通讯无能为力                  |
| onRef                      | 可以在获取整个子组件实例,使用简单                  | 兄弟组件通讯麻烦,官方不建议使用       |
| ref                        | 同 onRef                                           | 同 onRef                              |
| redux                      | 建立了全局的状态管理器,兄弟父子通讯都可解决        | 引入了外部插件                        |
| mobx                       | 建立了全局的状态管理器,兄弟父子通讯都可解决        | 引入了外部插件                        |
| flux                       | 建立了全局的状态管理器,兄弟父子通讯都可解决        | 引入了外部插件                        |
| hooks                      | 16.x 新的属性,可支持兄弟,父子组件通讯              | 需要结合 context 一起使用             |

`redux` ,` mobx`和`flux`对比

| 方法  | 介绍                                                         |
| ----- | ------------------------------------------------------------ |
| redux | 1.核心模块:Action,Reducer,Store;<br />2. Store 和更改逻辑是分开的;<br />3. 只有一个 Store;<br />4. 带有分层 reducer 的单一 Store;<br />5. 没有调度器的概念;<br />6. 容器组件是有联系的;<br />7. 状态是不可改变的;<br />8.更多的是遵循函数式编程思想 |
| mobx  | 1.核心模块:Action,Reducer,Derivation;<br />2.有多个 store;<br />3.设计更多偏向于面向对象编程和响应式编程，通常将状态包装成可观察对象，一旦状态对象变更，就能自动获得更新 |
| flux  | 1.核心模块:Store,ReduceStore,Container;<br />2.有多个 store; |