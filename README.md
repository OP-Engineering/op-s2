![screenshot](https://github.com/ospfranco/turbo-secure-storage/blob/main/header.png?raw=true)

<div align="center">
  <pre align="center" style="padding-bottom: 0;">
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

## Examples

```ts
import TurboSecureStorage, { ACCESSIBILITY } from 'turbo-secure-storage';

const { error } = TurboSecureStorage.setItem('foo', 'bar', {
  accessibility: ACCESSIBILITY, // the most secure option
});

const { error, value } = TurboSecureStorage.getItem('foo');

const { error } = TurboSecureStorage.deleteItem('foo');
```

> Certain parts of the implementation where taken from or inspirted by [rn-secure-storage](https://github.com/talut/rn-secure-storage), all the credit to the authors of the library.

### Accessibility

On iOS (for now, would like to implement the same on Android) you can specify an accesibility value which allows to customize the behavior of accessing the data. Some examples: always available, available only after first device unlock, available only when device is awake and unlocked and so on.

## TODO

- [ ] Support Secure Enclave on Apple devices
- [ ] Revisit Android code to make sure it handles all edge cases (RTL text)
- [ ] Security audit by expert

## About me

I'm available for React Native consulting and also create other products, [get in touch](https://ospfranco.com). You can also see how this library was built from scratch on my [YouTube channel](https://www.youtube.com/watch?v=U0shm20ClkU).

## License

MIT License
