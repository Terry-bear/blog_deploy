---
title: "Recompose库在React高阶函数的处理"
date: 2019-06-20T14:24:02+08:00
lastmod: 2019-06-20T14:24:02+08:00
draft: false
keywords: ["javascript"]
description: ""
tags: ["javascript"]
categories: ["code"]
author: "Terryzh"

postMetaInFooter: false

---

<!--more-->
多年来，我逐渐意识到开发高质量的`React`应用的唯一正确途径，是编写函数组件。

在本文中，我将简要介绍函数组件和高阶组件。之后，我们将深入研究臃肿的`React`组件，将之重构为由多个可组合的高阶组件的优雅方案。

## 函数组件简介

之所以被称为函数组件，是因为它们确实是普通的`JavaScript`函数。 常用的`React`中应该只包含函数组件。

首先让我们来看一个非常简单的`Class`组件

fileName->**simple_class_component.jsx**

```jsx
class MyComponent extends React.Component {
  render() {
    return (
      <div>
        <h1>Hi, {this.props.name}</h1>
      </div>
    );
  }
}
```

现在让我们将相同的组件重写为函数组件：

fileName->**simple_functional_component.jsx**

```jsx
const MyComponent = ({name}) => (
  <div>
    <h1>Hi, {name}</h1>
  </div>
);
```

如您所见，函数组件更清晰，更短，更易于阅读。也没有必要使用`this`关键字。

>其他一些好处：

* 易于推理 - 函数组件是纯函数，这意味着它们将始终为相同的输入，输出相同的输出。 给定名称Ilya，上面的组件将呈现

  `<h1> Hi，Ilya </ h1>`
* 易于测试 - 由于函数组件是纯函数，因此很容易对它们进行预测：给定一些props，预测它渲染相应的结构。
* 帮助防止滥用组件state，采用props替代。
* 鼓励可重用和模块化代码。
* 不要让 “god” components 过于承担太多事情
* 组合性-可以根据需要使用高阶组件添加行为。

>如果你的组件没有render（）方法以外的方法，那么就没有理由使用class组件。

## 高阶组件

高阶组件（HOC）是`React`中用于重用（和隔离）组件逻辑的功能。 你可能已经遇到过`HOC - Redux`的`connect`是一个高阶组件。

将HOC应用于组件，将用新特性增强现有组件。这通常是通过添加新的`props`来完成的，这些`props`会传递到组件中。对于`Redux`的`connect`，组件将获得新的`props`，这些`props`与`mapStateToProps`和`mapDispatchToProps`函数进行了映射。

我们经常需要与`localStorage`交互，但是，直接在组件内部与`localStorage`交互是错误的，因为它有副作用。 在常用的`React`中，组件应该没有副作用。 以下简单的高阶组件将向包裹组件添加三个新`props`，并使其能够与`localStorage`交互。

fileName->**simple_hoc.jsx**

```jsx
const withLocalStorage = (WrappedComponent) => {
  const loadFromStorage   = (key) => localStorage.getItem(key);
  const saveToStorage     = (key, value) => localStorage.setItem(key, value);
  const removeFromStorage = (key) => localStorage.removeItem(key);
  
  return (props) => (
      <WrappedComponent
            loadFromStorage={loadFromStorage}
            saveToStorage={saveToStorage}
            removeFromStorage={removeFromStorage}
            {...props}
        />
  );
}
```

然后我们可以简单地使用以下方法:`withLocalStorage(MyComponent)`

### 凌乱的Class组件

让我向您介绍我们将要使用的组件。 它是一个简单的注册表单，由三个字段组成，并带有一些基本的表单验证。

fileName->**complex_form.js**

```jsx
import React from "react";
import { TextField, Button, Grid } from "@material-ui/core";
import axios from 'axios';

class SignupForm extends React.Component {
  state = {
    email: "",
    emailError: "",
    password: "",
    passwordError: "",
    confirmPassword: "",
    confirmPasswordError: ""
  };

  getEmailError = email => {
    const emailRegex = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;

    const isValidEmail = emailRegex.test(email);
    return !isValidEmail ? "Invalid email." : "";
  };

  validateEmail = () => {
    const error = this.getEmailError(this.state.email);

    this.setState({ emailError: error });
    return !error;
  };

  getPasswordError = password => {
    const passwordRegex = /^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$/;

    const isValidPassword = passwordRegex.test(password);
    return !isValidPassword
      ? "The password must contain minimum eight characters, at least one letter and one number."
      : "";
  };

  validatePassword = () => {
    const error = this.getPasswordError(this.state.password);

    this.setState({ passwordError: error });
    return !error;
  };

  getConfirmPasswordError = (password, confirmPassword) => {
    const passwordsMatch = password === confirmPassword;

    return !passwordsMatch ? "Passwords don't match." : "";
  };

  validateConfirmPassword = () => {
    const error = this.getConfirmPasswordError(
      this.state.password,
      this.state.confirmPassword
    );

    this.setState({ confirmPasswordError: error });
    return !error;
  };

  onChangeEmail = event =>
    this.setState({
      email: event.target.value
    });

  onChangePassword = event =>
    this.setState({
      password: event.target.value
    });

  onChangeConfirmPassword = event =>
    this.setState({
      confirmPassword: event.target.value
    });

  handleSubmit = () => {
    if (
      !this.validateEmail() ||
      !this.validatePassword() ||
      !this.validateConfirmPassword()
    ) {
      return;
    }

    const data = {
      email: this.state.email,
      password: this.state.password
    };

    axios.post(`https://mywebsite.com/api/signup`, data);
  };

  render() {
    return (
      <Grid container spacing={16}>
        <Grid item xs={4}>
          <TextField
            label="Email"
            value={this.state.email}
            error={!!this.state.emailError}
            helperText={this.state.emailError}
            onChange={this.onChangeEmail}
            margin="normal"
          />

          <TextField
            label="Password"
            value={this.state.password}
            error={!!this.state.passwordError}
            helperText={this.state.passwordError}
            type="password"
            onChange={this.onChangePassword}
            margin="normal"
          />

          <TextField
            label="Confirm Password"
            value={this.state.confirmPassword}
            error={!!this.state.confirmPasswordError}
            helperText={this.state.confirmPasswordError}
            type="password"
            onChange={this.onChangeConfirmPassword}
            margin="normal"
          />

          <Button
            variant="contained"
            color="primary"
            onClick={this.handleSubmit}
            margin="normal"
          >
            Sign Up
          </Button>
        </Grid>
      </Grid>
    );
  }
}

export default SignupForm;
```

上面的组件很乱，它一次做很多事情：处理它的状态，验证表单字段，以及渲染表单。 它已经是**140**行代码。 添加更多功能很快就无法维护。 我们能做得更好吗？

>让我们看看我们能做些什么。

## 需要Recompose库

>`Recompose`是一个`React`实用库，用于函数组件和高阶组件。把它想象成`React`的`lodash`。

`Recompose`允许你通过添加状态，生命周期方法，上下文等来增强函数组件。

最重要的是，它允许您清晰地分离关注点 - 你可以让主要组件专门负责布局，高阶组件负责处理表单输入，另一个用于处理表单验证，另一个用于提交表单。 它很容易测试！

## 优雅的函数组件

### Step 0. 安装 Recompose

`yarn add recompose`

### Step 1. 提取输入表单的State

我们将从`Recompose`库中使用`withStateHandlers`高阶组件。 它将允许我们将组件状态与组件本身隔离开来。 我们将使用它为电子邮件，密码和确认密码字段添加表单状态，以及上述字段的事件处理程序。

fileName->**withTextFieldState.js**

```jsx
import { withStateHandlers, compose } from "recompose";

const initialState = {
  email: { value: "" },
  password: { value: "" },
  confirmPassword: { value: "" }
};

const onChangeEmail = props => event => ({
  email: {
    value: event.target.value,
    isDirty: true
  }
});

const onChangePassword = props => event => ({
  password: {
    value: event.target.value,
    isDirty: true
  }
});

const onChangeConfirmPassword = props => event => ({
  confirmPassword: {
    value: event.target.value,
    isDirty: true
  }
});

const withTextFieldState = withStateHandlers(initialState, {
  onChangeEmail,
  onChangePassword,
  onChangeConfirmPassword
});

export default withTextFieldState;
```

`withStateHandlers`高阶组件非常简单——它接受初始状态和包含状态处理程序的对象。调用时，每个状态处理程序将返回新的状态。

### Step 2.提取表单验证逻辑

现在是时候提取表单验证逻辑了。我们将从`Recompose`中使用`withProps`高阶组件。它允许将任意`props`添加到现有组件。

我们将使用`withProps`添加`emailError`，`passwordError`和`confirmPasswordError props`，如果我们的表单任何字段存在无效，它们将输出错误。

还应该注意，每个表单字段的验证逻辑都保存在一个单独的文件中（为了更好地分离关注点）。

fileName->**withPasswordError.js**

```jsx
import { withProps } from "recompose";

const getEmailError = email => {
  if (!email.isDirty) {
    return "";
  }

  const emailRegex = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;

  const isValidEmail = emailRegex.test(email.value);
  return !isValidEmail ? "Invalid email." : "";
};

const withEmailError = withProps(ownerProps => ({
  emailError: getEmailError(ownerProps.email)
}));

export default withEmailError;
```

fileName-> **withEmailError.js**

```jsx
import { withProps } from "recompose";

const getPasswordError = password => {
  if (!password.isDirty) {
    return "";
  }

  const passwordRegex = /^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$/;

  const isValidPassword = passwordRegex.test(password.value);
  return !isValidPassword
    ? "The password must contain minimum eight characters, at least one letter and one number."
    : "";
};

const withPasswordError = withProps(ownerProps => ({
  passwordError: getPasswordError(ownerProps.password)
}));

export default withPasswordError;
```

fileName->**withConfirmPasswordError.js**

```jsx
import { withProps } from "recompose";

const getConfirmPasswordError = (password, confirmPassword) => {
  if (!confirmPassword.isDirty) {
      return "";
  }

  const passwordsMatch = password.value === confirmPassword.value;

  return !passwordsMatch ? "Passwords don't match." : "";
};

const withConfirmPasswordError = withProps(
    (ownerProps) => ({
        confirmPasswordError: getConfirmPasswordError(
            ownerProps.password,
            ownerProps.confirmPassword
        )
    })
);

export default withConfirmPasswordError;
```

### Step 3. 提取表单提交逻辑

在这一步中，我们将提取表单提交逻辑。我们将再次使用`withProps`高阶组件来添加`onSubmit`处理程序。

`handleSubmit`函数接受从上一步传递下来的`emailError`，`passwordError`和`confirmPasswordError props`，检查是否有任何错误，如果没有，则会把参数请求到我们的`API`。

fileName->**withSubmitForm.js**

```jsx
import { withProps } from "recompose";
import axios from "axios";

const handleSubmit = ({
  email,
  password,
  emailError,
  passwordError,
  confirmPasswordError
}) => {
  if (emailError || passwordError || confirmPasswordError) {
    return;
  }

  const data = {
    email: email.value,
    password: password.value
  };

  axios.post(`https://mywebsite.com/api/signup`, data);
};

const withSubmitForm = withProps(ownerProps => ({
  onSubmit: handleSubmit(ownerProps)
}));

export default withSubmitForm;
```

### Step 4. 魔术`coming`

最后，将我们创建的高阶组件组合到一个可以在我们的表单上使用的增强器中。 我们将使用`recompose`中的`compose`函数，它可以组合多个高阶组件。

fileName->**withFormLogic.js**

```jsx
import { compose } from "recompose";

import withTextFieldState from "./withTextFieldState";
import withEmailError from "./withEmailError";
import withPasswordError from "./withPasswordError";
import withConfirmPasswordError from "./withConfirmPasswordError";
import withSubmitForm from "./withSubmitForm";

export default compose(
    withTextFieldState,
    withEmailError,
    withPasswordError,
    withConfirmPasswordError,
    withSubmitForm
);
```

>请注意此解决方案的优雅和整洁程度。所有必需的逻辑只是简单地添加到另一个逻辑上以生成一个增强器组件。

### Step 5.呼吸一口新鲜空气

现在让我们来看看`SignupForm`组件本身。

fileName->**SignupForm.js**

```jsx
import React from "react";
import { TextField, Button, Grid } from "@material-ui/core";
import withFormLogic from "./logic";

const SignupForm = ({
    email, onChangeEmail, emailError,
    password, onChangePassword, passwordError,
    confirmPassword, onChangeConfirmPassword, confirmPasswordError,
    onSubmit
}) => (
  <Grid container spacing={16}>
    <Grid item xs={4}>
      <TextField
        label="Email"
        value={email.value}
        error={!!emailError}
        helperText={emailError}
        onChange={onChangeEmail}
        margin="normal"
      />

      <TextField
        label="Password"
        value={password.value}
        error={!!passwordError}
        helperText={passwordError}
        type="password"
        onChange={onChangePassword}
        margin="normal"
      />

      <TextField
        label="Confirm Password"
        value={confirmPassword.value}
        error={!!confirmPasswordError}
        helperText={confirmPasswordError}
        type="password"
        onChange={onChangeConfirmPassword}
        margin="normal"
      />

      <Button
        variant="contained"
        color="primary"
        onClick={onSubmit}
        margin="normal"
      >
        Sign Up
      </Button>
    </Grid>
  </Grid>
);

export default withFormLogic(SignupForm);
```

新的重构组件非常清晰，只做一件事 - **渲染**。 单一责任原则规定模块应该做一件事，它应该做得好。 我相信我们已经实现了这一目标。

所有必需的数据和输入处理程序都只是作为`props`传递下来。 这反过来使组件非常容易测试。

我们应该始终努力使我们的组件完全不包含逻辑，并且只负责渲染。 `Recompose`允许我们这样做。

## Project Source Code

如果接下来遇到任何问题，可以从[github](https://github.com/suzdalnitski/medium-mastering-recompose)下载整个项目

## 惊喜：使用Recompose的pure可以优化性能

`Recompose`有`pure`，这是一个很好的高阶组件，允许我们只在需要的时候重新呈现组件。`pure`将确保组件不会重新呈现，除非任何`props`发生了更改。

fileName->**pureSignupForm.js**

```jsx
import { compose, pure } from "recompose";

...

export default compose(
  pure,
  withFormLogic
)(SignupForm);
```

## 总结

我们应该始终遵循组件的单一责任原则，将逻辑与表现隔离开来。为了实现这一点，首先应该取消`Class`组件的写法。主要组件本身应该是功能性的，并且应该只负责呈现而不是其他任何东西。然后将所有必需的状态和逻辑添加为高阶组件。

遵循以上规则将使您的代码清晰明了、易于**阅读**、易于**维护**和易于**测试**。

>>> 本文转自[Crop Circle](https://zhuanlan.zhihu.com/p/42494044),侵删
