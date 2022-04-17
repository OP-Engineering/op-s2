# React Native Turbo Secure Storage

A turbo-module to securely store data, uses Keychain on iOS and KeyStore on Android.

## Gotcha's

- This being a TurboModule is only compatible with RN 0.68+
- You might face some compilation errors on Android, please open tickets until I completely debug the process

## Installation

```sh
yarn add turbo-secure-storage
```

## API

```ts
setItem(key: string, value: string): { error?: Object };

getItem(key: string): { error?: Object; value: string };

deleteItem(key: string): { error?: Object };
```

The android implementation of Keystore was taking as is from [rn-secure-storage](https://github.com/talut/rn-secure-storage), all the credit to the Authors of the library

## Ospfranco

I'm available for React Native consulting. You can also see how this library was built from scratch on my [YouTube channel](https://www.youtube.com/watch?v=U0shm20ClkU).

## License

MIT License
