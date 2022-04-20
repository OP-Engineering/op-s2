<h1 align="center">React Native Turbo Secure Storage</h1>

![screenshot](https://raw.githubusercontent.com/ospfranco/turbo-secure-storage/main/header.png)

<div align="center">
  <pre align="center">
    yarn add turbo-secure-storage
  </pre>
  <a align="center" href="https://github.com/ospfranco?tab=followers">
    <img src="https://img.shields.io/github/followers/ospfranco?label=Follow%20%40ospfranco&style=social" />
  </a>
  <br />
  <a align="center" href="https://twitter.com/ospfranco">
    <img src="https://img.shields.io/twitter/follow/ospfranco?label=Follow%20%40ospfranco&style=social" />
  </a>
</div>
<br />

A turbo-module to securely store data, uses Keychain on iOS and KeyStore on Android.

## Gotcha's

- This being a TurboModule is only compatible with RN 0.68+
- You might face some compilation errors on Android, please open tickets until I completely debug the process

## API

```ts
setItem(key: string, value: string): { error?: Object };

getItem(key: string): { error?: Object; value: string };

deleteItem(key: string): { error?: Object };
```

> The android implementation of Keystore was taken from [rn-secure-storage](https://github.com/talut/rn-secure-storage), all the credit to the authors of the library.

## About me

I'm available for React Native consulting. You can also see how this library was built from scratch on my [YouTube channel](https://www.youtube.com/watch?v=U0shm20ClkU).

## License

MIT License
