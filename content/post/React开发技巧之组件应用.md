---
title: "React开发技巧之组件应用"
date: 2019-11-04T15:37:49+08:00
lastmod: 2019-11-04T15:37:49+08:00
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

React 中涉及到的组件的复杂应用总结。

# 1.异步组件

1. 场景:路由切换,如果同步加载多个页面路由会导致缓慢

2. 核心 `API`:
    `loader` : 需要加载的组件
    `loading` : 未加载出来的页面展示组件
    `delay` : 延迟加载时间
    `timeout` : 超时时间

3. 使用方法:
    安装 `react-loadable` ,`babel`插件安装 `syntax-dynamic-import. react-loadable`是通过`webpack`的异步`import`实现的

```jsx
const Loading = () => {
  return <div>loading</div>;
};

const LoadableComponent = Loadable({
  loader: () => import("../../components/TwoTen/thirteen"),
  loading: Loading
});

export default class Thirteen extends React.Component {
  render() {
    return <LoadableComponent></LoadableComponent>;
  }
}
```

4. `Loadable.Map()`
    并行加载多个资源的高阶组件

# 2.动态组件

场景:做一个 tab 切换时就会涉及到组件动态加载
 实质上是利用三元表达式判断组件是否显示

```jsx
class FourteenChildOne extends React.Component {
    render() {
        return <div>这是动态组件 1</div>;
    }
}

class FourteenChildTwo extends React.Component {
    render() {
        return <div>这是动态组件 2</div>;
    }
}

export default class Fourteen extends React.Component {
  state={
      oneShowFlag:true
  }
  tab=()=>{
      this.setState({oneShowFlag:!this.state.oneShowFlag})
  }
  render() {
    const {oneShowFlag} = this.state
    return (<div>
        <Button type="primary" onClick={this.tab}>显示组件{oneShowFlag?2:1}</Button>
        {oneShowFlag?<FourteenChildOne></FourteenChildOne>:<FourteenChildTwo></FourteenChildTwo>}
    </div>);
  }
}
```

如果是单个组件是否显示可以用短路运算

```jsx
oneShowFlag&&<FourteenChildOne></FourteenChildOne>
```

# 3.递归组件

场景: `tree`组件
 利用`React.Fragment`或者 `div` 包裹循环

```jsx
class Item extends React.Component {
  render() {
    const list = this.props.children || [];
    return (
      <div className="item">
        {list.map((item, index) => {
          return (
            <React.Fragment key={index}>
              <h3>{item.name}</h3>
              {// 当该节点还有children时，则递归调用本身
              item.children && item.children.length ? (
                <Item>{item.children}</Item>
              ) : null}
            </React.Fragment>
          );
        })}
      </div>
    );
  }
}
```

# 4.受控组件和不受控组件

受控组件 : 组件拥有自己的状态

```jsx
class Controll extends React.Component {
  constructor() {
    super();
    this.state = { value: "这是受控组件默认值" };
  }
  render() {
    return <div>{this.state.value}</div>;
  }
}
```

不受控组件:组件无自己的状态,在父组件通过 `ref` 来控制或者通过 `props` 传值

```jsx
class NoControll extends React.Component {
  render() {
    return <div>{this.props.value}</div>;
  }
}
```

导入代码:

```jsx
export default class Sixteen extends React.Component {
  componentDidMount() {
    console.log("ref 获取的不受控组件值为", this.refs["noControll"]);
  }
  render() {
    return (
      <div>
        <Controll></Controll>
        <NoControll
          value={"这是不受控组件传入值"}
          ref="noControll"
        ></NoControll>
      </div>
    );
  }
}
```

# 5.高阶组件

## 5.1 定义

就是类似高阶函数的定义,将组件作为参数或者返回一个组件的组件

## 5.2 实现方法

1. 属性代理

```jsx
import React,{Component} from 'react';

const Seventeen = WraooedComponent =>
  class extends React.Component {
    render() {
      const props = {
        ...this.props,
        name: "这是高阶组件"
      };
      return <WrappedComponent {...props} />;
    }
  };

class WrappedComponent extends React.Component {
  state={
     baseName:'这是基础组件' 
  }
  render() {
    const {baseName} = this.state
    const {name} = this.props
    return <div>
        <div>基础组件值为{baseName}</div>
        <div>通过高阶组件属性代理的得到的值为{name}</div>
    </div>
  }
}

export default Seventeen(WrappedComponent)
```

2. 反向继承
    原理就是利用 `super` 改变改组件的 `this` 方向,继而就可以在该组件处理容器组件的一些值

```jsx
  const Seventeen = (WrappedComponent)=>{
    return class extends WrappedComponent {
        componentDidMount() {
            this.setState({baseName:'这是通过反向继承修改后的基础组件名称'})
        }
        render(){
            return super.render();
        }
    }
}

class WrappedComponent extends React.Component {
  state={
     baseName:'这是基础组件' 
  }
  render() {
    const {baseName} = this.state
    return <div>
        <div>基础组件值为{baseName}</div>
    </div>
  }
}

export default Seventeen(WrappedComponent);
```


