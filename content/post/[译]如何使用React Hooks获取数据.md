---
title: "[译]如何使用React Hooks获取数据"
date: 2019-07-24T10:56:12+08:00
lastmod: 2019-07-24T10:56:12+08:00
draft: false
keywords: ["javascript"]
description: ""
tags: ["javascript"]
categories: ["code"]
author: "Terryzh"

postMetaInFooter: false

---

<!--more-->

在本教程中，我想向您**展示如何**使用[state](https://reactjs.org/docs/hooks-state.html)和[effect](https://reactjs.org/docs/hooks-effect.html)**Hook**在**React with Hooks**中获取数据。我们将使用广为人知的[黑客新闻API](https://hn.algolia.com/api)来获取科技界的热门文章。您还将实现数据提取的自定义挂钩，可以在应用程序的任何位置重用，也可以作为独立节点包在npm上发布。

如果您对这个新的React功能一无所知，请[查看React Hooks的](https://www.robinwieruch.de/react-hooks/)这个[介绍](https://www.robinwieruch.de/react-hooks/)。如果您想要查看完成的项目以获取展示如何在React with Hooks中获取数据的展示示例，请检查此[GitHub存储库](https://github.com/the-road-to-learn-react/react-hooks-introduction)。

如果您只是想准备好React Hook进行数据获取：`npm install use-data-api`并按照[文档进行操作](https://github.com/the-road-to-learn-react/use-data-api)。

> **注意：**将来，React Hooks不适用于React中的数据获取。相反，一个名为Suspense的功能将负责它。以下演练是了解React中有关状态和效果挂钩的更多信息的好方法。



## 使用React Hooks获取数据

如何使用[Render Prop组件](https://www.robinwieruch.de/react-render-props-pattern/)和[高阶组件重新获取](https://www.robinwieruch.de/gentle-introduction-higher-order-components/)它，以及它如何处理错误处理和加载微调器。在本文中，我想在功能组件中使用React Hooks向您展示所有内容。

```javascript
import React, { useState } from 'react';

function App() {
  const [data, setData] = useState({ hits: [] });

  return (
    <ul>
      {data.hits.map(item => (
        <li key={item.objectID}>
          <a href={item.url}>{item.title}</a>
        </li>
      ))}
    </ul>
  );
}

export default App;
```

App组件显示了一个项目列表（hits = Hacker News文章）。状态(state)和状态更新(state update)函数来自状态钩子`useState`，它被称为负责管理我们要为App组件获取的数据的本地状态。初始状态是表示数据的对象中的空命中列表。目前还没有人为这些数据设置任何状态。

我们将使用[axios](https://github.com/axios/axios)来获取数据，但是您可以使用另一个数据获取库或浏览器的本机提取API。如果尚未安装axios，可以在命令行中执行此操作`npm install axios`。然后为数据获取实现效果钩子：

```javascript
import React, { useState, useEffect } from 'react';
import axios from 'axios';

function App() {
  const [data, setData] = useState({ hits: [] });

  useEffect(async () => {
    const result = await axios(
      'http://hn.algolia.com/api/v1/search?query=redux',
    );

    setData(result.data);
  });

  return (
    <ul>
      {data.hits.map(item => (
        <li key={item.objectID}>
          <a href={item.url}>{item.title}</a>
        </li>
      ))}
    </ul>
  );
}

export default App;
```

名为`useEffect`的`Effect hook`用于从API获取带有axios的数据，并使用状态挂钩的更新功能将数据设置为组件的本地状态。`Promise resolving`发生在`async / await`中。

但是，当您运行应用程序时，您应该偶然发现一个讨厌的循环。`effect hook`在组件安装时运行，但也在组件更新时运行。因为我们在每次数据提取后设置状态，所以组件会更新并且效果会再次运行。它一次又一次地获取数据。**这是一个错误，需要避免**。**绝大多数的新手肯定会犯错的地方**。**我们只想在组件安装时获取数据。**这就是为什么你可以提供一个空数组作为`effect hook`的第二个参数，以避免在组件更新时激活它，但仅用于组件的安装。

```javascript
import React, { useState, useEffect } from 'react';
import axios from 'axios';

function App() {
  const [data, setData] = useState({ hits: [] });

  useEffect(async () => {
    const result = await axios(
      'http://hn.algolia.com/api/v1/search?query=redux',
    );

    setData(result.data);
  }, []);

  return (
    <ul>
      {data.hits.map(item => (
        <li key={item.objectID}>
          <a href={item.url}>{item.title}</a>
        </li>
      ))}
    </ul>
  );
}

export default App;
```

第二个参数可用于定义钩子所依赖的所有变量（在此数组中分配）。如果其中一个变量发生变化，则钩子再次运行。如果包含变量的数组为空，则在更新组件时挂钩不会运行，因为它不必监视任何变量。

还有最后一个问题。在代码中，我们使用async / await从第三方API获取数据。根据文档，每个使用async注释的函数都会返回一个隐式的promise：*“async函数声明定义了一个异步函数，它返回一个AsyncFunction对象。异步函数是一个通过事件循环异步操作的函数，使用隐式Promise返回其结果。“*。但是，`effect hook`应该不返回任何内容或清除功能。这就是为什么你可能会在开发者控制台日志中看到以下警告：**07：41：22.910 index.js：1452.Warning: useEffect function must return a cleanup function or nothing.。不支持Promises和useEffect（async（）=> ...），但可以在effect中调用异步函数。**。这就是为什么`useEffect`不允许在函数中直接使用async的原因。让我们通过在效果中使用async函数来实现它的解决方法。

```javascript
import React, { useState, useEffect } from 'react';
import axios from 'axios';

function App() {
  const [data, setData] = useState({ hits: [] });

  useEffect(() => {
    const fetchData = async () => {
      const result = await axios(
        'http://hn.algolia.com/api/v1/search?query=redux',
      );

      setData(result.data);
    };

    fetchData();
  }, []);

  return (
    <ul>
      {data.hits.map(item => (
        <li key={item.objectID}>
          <a href={item.url}>{item.title}</a>
        </li>
      ))}
    </ul>
  );
}

export default App;
```

> 简而言之，就是使用React钩子获取数据。但是如果您对错误处理，loading indicator，如何触发从表单中获取数据以及如何实现可重用数据获取挂钩感兴趣，请继续阅读。



## 如何以编程方式/手动触发Hook？

非常棒，我们在组件安装后获取数据。但是如何使用输入字段告诉API我们感兴趣的主题？“Redux”被视为默认查询。但是关于“React”的话题呢？让我们实现一个输入元素，使某人能够获取除“Redux”故事之外的其他故事。因此，为input元素引入一个新状态。

```javascript
import React, { Fragment, useState, useEffect } from 'react';
import axios from 'axios';

function App() {
  const [data, setData] = useState({ hits: [] });
  const [query, setQuery] = useState('redux');

  useEffect(() => {
    const fetchData = async () => {
      const result = await axios(
        'http://hn.algolia.com/api/v1/search?query=redux',
      );

      setData(result.data);
    };

    fetchData();
  }, []);

  return (
    <Fragment>
      <input
        type="text"
        value={query}
        onChange={event => setQuery(event.target.value)}
      />
      <ul>
        {data.hits.map(item => (
          <li key={item.objectID}>
            <a href={item.url}>{item.title}</a>
          </li>
        ))}
      </ul>
    </Fragment>
  );
}

export default App;
```

目前，两个状态彼此独立，但现在您希望将它们耦合到仅获取输入字段中查询指定的文章。通过以下更改，组件应在挂载后按查询字词获取所有文章。

```javascript
...

function App() {
  const [data, setData] = useState({ hits: [] });
  const [query, setQuery] = useState('redux');

  useEffect(() => {
    const fetchData = async () => {
      const result = await axios(
        `http://hn.algolia.com/api/v1/search?query=${query}`,
      );

      setData(result.data);
    };

    fetchData();
  }, []);

  return (
    ...
  );
}

export default App;
```

缺少一点：当您尝试在输入字段中键入内容时，在从效果触发安装后没有其他数据获取。那是因为你提供了空数组作为效果的第二个参数。效果取决于无变量，因此仅在组件安装时触发。但是，现在效果应该取决于查询。查询更改后，数据请求将再次触发。

```javascript
...

function App() {
  const [data, setData] = useState({ hits: [] });
  const [query, setQuery] = useState('redux');

  useEffect(() => {
    const fetchData = async () => {
      const result = await axios(
        `http://hn.algolia.com/api/v1/search?query=${query}`,
      );

      setData(result.data);
    };

    fetchData();
  }, [query]);

  return (
    ...
  );
}

export default App;
```

一旦更改输入字段中的值，就可以重新获取数据。但这会带来另一个问题：**在输入字段中键入的每个字符上，都会触发效果并执行另一个数据提取请求**。如何提供一个按钮来触发请求，从而手动控制hook？

```javascript
function App() {
  const [data, setData] = useState({ hits: [] });
  const [query, setQuery] = useState('redux');
  const [search, setSearch] = useState('');

  useEffect(() => {
    const fetchData = async () => {
      const result = await axios(
        `http://hn.algolia.com/api/v1/search?query=${query}`,
      );

      setData(result.data);
    };

    fetchData();
  }, [query]);

  return (
    <Fragment>
      <input
        type="text"
        value={query}
        onChange={event => setQuery(event.target.value)}
      />
      <button type="button" onClick={() => setSearch(query)}>
        Search
      </button>

      <ul>
        {data.hits.map(item => (
          <li key={item.objectID}>
            <a href={item.url}>{item.title}</a>
          </li>
        ))}
      </ul>
    </Fragment>
  );
}
```

现在，使效果取决于搜索状态，而不是每次键盘点击后的查询状态。用户单击该按钮后，将设置新的搜索状态，并应手动触发`effect hook`。

```javascript
...

function App() {
  const [data, setData] = useState({ hits: [] });
  const [query, setQuery] = useState('redux');
  const [search, setSearch] = useState('redux');

  useEffect(() => {
    const fetchData = async () => {
      const result = await axios(
        `http://hn.algolia.com/api/v1/search?query=${search}`,
      );

      setData(result.data);
    };

    fetchData();
  }, [search]);

  return (
    ...
  );
}

export default App;
```

此外，搜索状态的初始状态设置为与查询状态相同的状态，因为组件也在mount上获取数据，因此结果应该与输入字段的值保持一致。但是，具有类似的查询和搜索状态有点令人困惑。为什么不将实际的URL设置为状态而不是搜索状态？

```javascript
function App() {
  const [data, setData] = useState({ hits: [] });
  const [query, setQuery] = useState('redux');
  const [url, setUrl] = useState(
    'http://hn.algolia.com/api/v1/search?query=redux',
  );

  useEffect(() => {
    const fetchData = async () => {
      const result = await axios(url);

      setData(result.data);
    };

    fetchData();
  }, [url]);

  return (
    <Fragment>
      <input
        type="text"
        value={query}
        onChange={event => setQuery(event.target.value)}
      />
      <button
        type="button"
        onClick={() =>
          setUrl(`http://hn.algolia.com/api/v1/search?query=${query}`)
        }
      >
        Search
      </button>

      <ul>
        {data.hits.map(item => (
          <li key={item.objectID}>
            <a href={item.url}>{item.title}</a>
          </li>
        ))}
      </ul>
    </Fragment>
  );
}
```

> 这就是使用效果钩子获取隐式程序数据的情况。您可以决定`effect`所依赖的`state`。一旦您在单击或其他副作用中设置此`state`，`effect`将再次运行。在这种情况下，如果URL状态发生更改，则`effect`会再次运行以从API获取故事。



## 在React Hooks中的Loading indicator

让我们为数据提取引入一个`Loading indicator`。它只是另一个由`state hook`管理的状态。加载标志用于在App组件中呈现加载指示符。

```javascript
import React, { Fragment, useState, useEffect } from 'react';
import axios from 'axios';

function App() {
  const [data, setData] = useState({ hits: [] });
  const [query, setQuery] = useState('redux');
  const [url, setUrl] = useState(
    'http://hn.algolia.com/api/v1/search?query=redux',
  );
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    const fetchData = async () => {
      setIsLoading(true);

      const result = await axios(url);

      setData(result.data);
      setIsLoading(false);
    };

    fetchData();
  }, [url]);

  return (
    <Fragment>
      <input
        type="text"
        value={query}
        onChange={event => setQuery(event.target.value)}
      />
      <button
        type="button"
        onClick={() =>
          setUrl(`http://hn.algolia.com/api/v1/search?query=${query}`)
        }
      >
        Search
      </button>

      {isLoading ? (
        <div>Loading ...</div>
      ) : (
        <ul>
          {data.hits.map(item => (
            <li key={item.objectID}>
              <a href={item.url}>{item.title}</a>
            </li>
          ))}
        </ul>
      )}
    </Fragment>
  );
}

export default App;
```

一旦为数据提取调用了效果，这在组件安装或URL状态更改时发生，则加载状态设置为true。请求解析后，加载状态再次设置为false。



## 使用React Hook进行错误处理

使用React钩子获取数据的错误处理怎么样？错误只是用状态挂钩初始化的另一个状态。一旦出现错误状态，App组件就可以为用户呈现反馈。使用async / await时，通常使用try / catch块进行错误处理。你可以在`effect`范围内完成：

```javascript
import React, { Fragment, useState, useEffect } from 'react';
import axios from 'axios';

function App() {
  const [data, setData] = useState({ hits: [] });
  const [query, setQuery] = useState('redux');
  const [url, setUrl] = useState(
    'http://hn.algolia.com/api/v1/search?query=redux',
  );
  const [isLoading, setIsLoading] = useState(false);
  const [isError, setIsError] = useState(false);

  useEffect(() => {
    const fetchData = async () => {
      setIsError(false);
      setIsLoading(true);

      try {
        const result = await axios(url);

        setData(result.data);
      } catch (error) {
        setIsError(true);
      }

      setIsLoading(false);
    };

    fetchData();
  }, [url]);

  return (
    <Fragment>
      <input
        type="text"
        value={query}
        onChange={event => setQuery(event.target.value)}
      />
      <button
        type="button"
        onClick={() =>
          setUrl(`http://hn.algolia.com/api/v1/search?query=${query}`)
        }
      >
        Search
      </button>

      {isError && <div>Something went wrong ...</div>}

      {isLoading ? (
        <div>Loading ...</div>
      ) : (
        <ul>
          {data.hits.map(item => (
            <li key={item.objectID}>
              <a href={item.url}>{item.title}</a>
            </li>
          ))}
        </ul>
      )}
    </Fragment>
  );
}

export default App;
```

每次`hook`再次运行时，错误状态都会重置。这很有用，因为在失败的请求之后，用户可能想要再次尝试它，这应该重置错误。为了自己执行错误，您可以将URL更改为无效的内容。然后检查错误消息是否显示。



## 在React中使用表单获取数据

获取数据的正确表单怎么样？到目前为止，我们只有输入字段和按钮的组合。一旦引入了更多输入元素，您可能希望用表单元素包装它们。此外，表单也可以通过键盘上的“Enter”触发按钮。

```javascript
function App() {
  ...

  return (
    <Fragment>
      <form
        onSubmit={() =>
          setUrl(`http://hn.algolia.com/api/v1/search?query=${query}`)
        }
      >
        <input
          type="text"
          value={query}
          onChange={event => setQuery(event.target.value)}
        />
        <button type="submit">Search</button>
      </form>

      {isError && <div>Something went wrong ...</div>}

      ...
    </Fragment>
  );
}
```

但是现在浏览器在单击提交按钮时会重新加载，因为这是提交表单时浏览器的本机行为。为了防止默认行为，我们可以在React事件上调用一个函数。这就是你在React类组件中的表现。

```javascript
function App() {
  ...

  return (
    <Fragment>
      <form onSubmit={event => {
        setUrl(`http://hn.algolia.com/api/v1/search?query=${query}`);

        event.preventDefault();
      }}>
        <input
          type="text"
          value={query}
          onChange={event => setQuery(event.target.value)}
        />
        <button type="submit">Search</button>
      </form>

      {isError && <div>Something went wrong ...</div>}

      ...
    </Fragment>
  );
}
```

现在，当您单击“提交”按钮时，浏览器不应再重新加载。它像以前一样工作，但这次是使用表单而不是简单的输入字段和按钮组合。您也可以按键盘上的“Enter”键。



## 自定义数据获取hook

为了提取数据提取的自定义`hook`，将属于数据提取的所有内容（属于输入字段的查询状态除外，包括加载指示符和错误处理）移动到其自己的函数中。还要确保从App组件中使用的函数返回所有必需的变量。

```javascript
const useHackerNewsApi = () => {
  const [data, setData] = useState({ hits: [] });
  const [url, setUrl] = useState(
    'http://hn.algolia.com/api/v1/search?query=redux',
  );
  const [isLoading, setIsLoading] = useState(false);
  const [isError, setIsError] = useState(false);

  useEffect(() => {
    const fetchData = async () => {
      setIsError(false);
      setIsLoading(true);

      try {
        const result = await axios(url);

        setData(result.data);
      } catch (error) {
        setIsError(true);
      }

      setIsLoading(false);
    };

    fetchData();
  }, [url]);

  return [{ data, isLoading, isError }, setUrl];
}
```

现在，您的新`hook`可以再次在App组件中使用：

```javascript
function App() {
  const [query, setQuery] = useState('redux');
  const [{ data, isLoading, isError }, doFetch] = useHackerNewsApi();

  return (
    <Fragment>
      <form onSubmit={event => {
        doFetch(`http://hn.algolia.com/api/v1/search?query=${query}`);

        event.preventDefault();
      }}>
        <input
          type="text"
          value={query}
          onChange={event => setQuery(event.target.value)}
        />
        <button type="submit">Search</button>
      </form>

      ...
    </Fragment>
  );
}
```

初始状态也可以是通用的。将它简单地传递给新的自定义`hook`：

```javascript
import React, { Fragment, useState, useEffect } from 'react';
import axios from 'axios';

const useDataApi = (initialUrl, initialData) => {
  const [data, setData] = useState(initialData);
  const [url, setUrl] = useState(initialUrl);
  const [isLoading, setIsLoading] = useState(false);
  const [isError, setIsError] = useState(false);

  useEffect(() => {
    const fetchData = async () => {
      setIsError(false);
      setIsLoading(true);

      try {
        const result = await axios(url);

        setData(result.data);
      } catch (error) {
        setIsError(true);
      }

      setIsLoading(false);
    };

    fetchData();
  }, [url]);

  return [{ data, isLoading, isError }, setUrl];
};

function App() {
  const [query, setQuery] = useState('redux');
  const [{ data, isLoading, isError }, doFetch] = useDataApi(
    'http://hn.algolia.com/api/v1/search?query=redux',
    { hits: [] },
  );

  return (
    <Fragment>
      <form
        onSubmit={event => {
          doFetch(
            `http://hn.algolia.com/api/v1/search?query=${query}`,
          );

          event.preventDefault();
        }}
      >
        <input
          type="text"
          value={query}
          onChange={event => setQuery(event.target.value)}
        />
        <button type="submit">Search</button>
      </form>

      {isError && <div>Something went wrong ...</div>}

      {isLoading ? (
        <div>Loading ...</div>
      ) : (
        <ul>
          {data.hits.map(item => (
            <li key={item.objectID}>
              <a href={item.url}>{item.title}</a>
            </li>
          ))}
        </ul>
      )}
    </Fragment>
  );
}

export default App;
```

> 这就是使用自定义`hook`获取数据的原因。`hook`本身对API没有任何了解。它从外部接收所有参数，并仅管理必要的状态，例如数据，加载和错误状态。它执行请求并使用它作为自定义数据获取`hook`将数据返回给组件。



## 用于数据获取的Reducer Hook

到目前为止，我们已经使用各种状态挂钩来管理数据，加载和错误状态的数据获取状态。然而，不知何故，所有这些状态，[由他们自己的状态钩子管理，属于一起，因为他们关心同一个问题](https://www.robinwieruch.de/react-usereducer-vs-usestate/)。如您所见，它们都在数据提取功能中使用。一个很好的指标，他们属于一起的是，它们用于一个接一个（例如`setIsError`，`setIsLoading`）。让我们将所有这三个与[Reducer Hook](https://www.robinwieruch.de/react-usereducer-hook/)结合起来。

Reducer Hook返回一个状态对象和一个改变状态对象的函数。该函数（称为调度函数）采用具有类型和可选有效负载的操作。所有这些信息都在实际的reducer函数中用于从先前的状态，动作的可选有效负载和类型中提取新状态。让我们看看它在代码中是如何工作的：

```javascript
import React, {
  Fragment,
  useState,
  useEffect,
  useReducer,
} from 'react';
import axios from 'axios';

const dataFetchReducer = (state, action) => {
  ...
};

const useDataApi = (initialUrl, initialData) => {
  const [url, setUrl] = useState(initialUrl);

  const [state, dispatch] = useReducer(dataFetchReducer, {
    isLoading: false,
    isError: false,
    data: initialData,
  });

  ...
};
```

Reducer Hook将reducer函数和初始状态对象作为参数。在我们的例子中，数据，加载和错误状态的初始状态的参数没有改变，但它们已经聚合到一个由一个reducer钩子而不是单个状态钩子管理的状态对象。

```javascript
const dataFetchReducer = (state, action) => {
  ...
};

const useDataApi = (initialUrl, initialData) => {
  const [url, setUrl] = useState(initialUrl);

  const [state, dispatch] = useReducer(dataFetchReducer, {
    isLoading: false,
    isError: false,
    data: initialData,
  });

  useEffect(() => {
    const fetchData = async () => {
      dispatch({ type: 'FETCH_INIT' });

      try {
        const result = await axios(url);

        dispatch({ type: 'FETCH_SUCCESS', payload: result.data });
      } catch (error) {
        dispatch({ type: 'FETCH_FAILURE' });
      }
    };

    fetchData();
  }, [url]);

  ...
};
```

现在，在获取数据时，可以使用调度功能将信息发送到reducer功能。使用dispatch函数发送的对象具有强制`type`属性和可选`payload`属性。该类型告诉reducer功能需要应用哪个状态转换，并且reducer可以另外使用有效负载来提取新状态。毕竟，我们只有三个状态转换：初始化提取过程，通知成功的数据提取结果，并通知错误的数据提取结果。

在自定义`hook`的末尾，状态像以前一样返回，但是因为我们有一个状态对象而不是独立状态。这样，调用`useDataApi`自定义挂钩的人仍然可以访问`data`，`isLoading`并且`isError`：

```javascript
const useDataApi = (initialUrl, initialData) => {
  const [url, setUrl] = useState(initialUrl);

  const [state, dispatch] = useReducer(dataFetchReducer, {
    isLoading: false,
    isError: false,
    data: initialData,
  });

  ...

  return [state, setUrl];
};
```

最后但并非最不重要的是，缺少`reducer`函数的实现。它需要作用于所谓的三种不同的状态转换`FETCH_INIT`，`FETCH_SUCCESS`和`FETCH_FAILURE`。每个状态转换都需要返回一个新的状态对象。让我们看看如何使用switch case语句实现它：

```javascript
const dataFetchReducer = (state, action) => {
  switch (action.type) {
    case 'FETCH_INIT':
      return { ...state };
    case 'FETCH_SUCCESS':
      return { ...state };
    case 'FETCH_FAILURE':
      return { ...state };
    default:
      throw new Error();
  }
};
```

`reducer`函数可以通过其参数访问当前状态和传入操作。到目前为止，在out case case语句中，每个状态转换仅返回先前的状态。解构语句用于保持状态对象不可变 - 意味着状态永远不会直接变异 - 以强制执行最佳实践。现在让我们覆盖一些当前状态返回的属性来改变每个状态转换的状态：

```javascript
const dataFetchReducer = (state, action) => {
  switch (action.type) {
    case 'FETCH_INIT':
      return {
        ...state,
        isLoading: true,
        isError: false
      };
    case 'FETCH_SUCCESS':
      return {
        ...state,
        isLoading: false,
        isError: false,
        data: action.payload,
      };
    case 'FETCH_FAILURE':
      return {
        ...state,
        isLoading: false,
        isError: true,
      };
    default:
      throw new Error();
  }
};
```

现在，由动作类型决定的每个状态转换都会返回基于先前状态和可选有效负载的新状态。例如，在成功请求的情况下，有效载荷用于设置新状态对象的数据。

总之，Reducer Hook确保状态管理的这一部分用自己的逻辑封装。通过提供操作类型和可选的有效负载，您将始终以谓词状态更改结束。此外，您永远不会遇到无效状态。例如，以前可能会意外地将`isLoading`和`isError`状态设置为true。在这种情况下，UI应该显示什么？现在，reducer函数定义的每个状态转换都会导致一个有效的状态对象。

## 在Effect Hook中终止数据获取

React中的一个常见问题是即使组件已经卸载（例如由于使用React Router导航），也会设置组件状态。让我们看看我们如何阻止在数据提取的自定义`hook`中设置状态：

```javascript
const useDataApi = (initialUrl, initialData) => {
  const [url, setUrl] = useState(initialUrl);

  const [state, dispatch] = useReducer(dataFetchReducer, {
    isLoading: false,
    isError: false,
    data: initialData,
  });

  useEffect(() => {
    let didCancel = false;

    const fetchData = async () => {
      dispatch({ type: 'FETCH_INIT' });

      try {
        const result = await axios(url);

        if (!didCancel) {
          dispatch({ type: 'FETCH_SUCCESS', payload: result.data });
        }
      } catch (error) {
        if (!didCancel) {
          dispatch({ type: 'FETCH_FAILURE' });
        }
      }
    };

    fetchData();

    return () => {
      didCancel = true;
    };
  }, [url]);

  return [state, setUrl];
};
```

每个`effect hook`都带有一个清理功能，该功能在组件卸载时运行。清理功能是`hook`返回的一个功能。在我们的例子中，我们使用一个`boolean`来调用`didCancel`，让我们的数据获取逻辑知道组件的状态（已安装/未安装）。如果组件已卸载，则应将该标志设置为`true`导致在最终异步解析数据提取后阻止设置组件状态。

> *注意：实际上不会中止数据获取 - 这可以通过Axios Cancellation实现- 但是对于未安装的组件不再执行状态转换。由于Axios Cancellation在我看来并不是最好的API，因此这个防止设置状态的布尔标志也能完成这项工作。*



您已经了解了如何在React中使用`useState`和`useEffect`的React Hook进行数据提取，我希望本文对您了解React Hooks以及如何在现实世界中使用它们非常有用。

[PS：原文链接😁](https://www.robinwieruch.de/react-hooks-fetch-data/)
