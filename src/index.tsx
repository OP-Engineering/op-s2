import { NativeModules } from 'react-native';

declare global {
  var __OPS2Proxy: OPS2 | undefined;
}

if (global.__OPS2Proxy == null) {
  const OPS2 = NativeModules.OPS2;

  if (OPS2 == null) {
    throw new Error('Base module not found. Maybe try rebuilding the app.');
  }

  if (OPS2.install == null) {
    throw new Error(
      'Failed to install op-s2: React Native is not running on-device.'
    );
  }

  // Call the synchronous blocking install() function
  const result = OPS2.install();
  if (result !== true) {
    throw new Error(
      `Failed to install op-s2: The native module could not be installed! Looks like something went wrong when installing JSI bindings: ${result}`
    );
  }

  // Check again if the constructor now exists. If not, throw an error.
  if (global.__OPS2Proxy == null) {
    throw new Error(
      'Failed to install op-s2, the native initializer function does not exist. Are you trying to use OPS2 from different JS Runtimes?'
    );
  }
}

const proxy = global.__OPS2Proxy;

export enum ACCESSIBILITY {
  /**
   * The data in the keychain item cannot be accessed after a restart until the device
   * has been unlocked once by the user.
   */
  AFTER_FIRST_UNLOCK = 'AccessibleAfterFirstUnlock',
  /**
   * The data in the keychain item cannot be accessed after a restart until the device
   * has been unlocked once by the user.
   * Items with this attribute never migrate to a new device.
   */
  AFTER_FIRST_UNLOCK_THIS_DEVICE_ONLY = 'AccessibleAfterFirstUnlockThisDeviceOnly',
  /**
   * The data in the keychain item can always be accessed regardless of whether
   * the device is locked.
   */
  ALWAYS = 'AccessibleAlways',
  /**
   * The data in the keychain item can always be accessed regardless of whether the
   * device is locked.
   * Items with this attribute never migrate to a new device.
   */
  ALWAYS_THIS_DEVICE_ONLY = 'AccessibleAlwaysThisDeviceOnly',
  /**
   * The data in the keychain can only be accessed when the device is unlocked.
   * Only available if a passcode is set on the device.
   * Items with this attribute never migrate to a new device.
   */
  WHEN_PASSCODE_SET_THIS_DEVICE_ONLY = 'AccessibleWhenPasscodeSetThisDeviceOnly',
  /**
   * The data in the keychain item can be accessed only while the device is
   * unlocked by the user.
   * This is the default value.
   */
  WHEN_UNLOCKED = 'AccessibleWhenUnlocked',
  /**
   * The data in the keychain item can be accessed only while the device is
   * unlocked by the user.
   * Items with this attribute do not migrate to a new device.
   */
  WHEN_UNLOCKED_THIS_DEVICE_ONLY = 'AccessibleWhenUnlockedThisDeviceOnly',
}

export const get = proxy.get;
export const set = proxy.set;
export const del = proxy.del;

type SharedOperationErrors =
  | '[op-s2] User cancelled authentication'
  | '[op-s2] Authentication failed'
  | '[op-s2] User interaction not allowed'
  | '[op-s2] Missing entitlement'
  | `[op-s2] Security error code: ${string}. Look up code error at https://www.osstatus.com/`
  | `op-s2 could not set value, error code: ${string}`;

type SetErrors =
  | 'Params object is missing'
  | 'Params is not an object'
  | 'Key property is missing'
  | 'Value property is missing'
  | 'Value property is not a string'
  | '[op-s2] Could not set value, duplicate item'
  | SharedOperationErrors;

type GetErrors =
  | 'Params object is missing'
  | 'Params must be an object with key and value'
  | 'key property is missing'
  | '[op-s2] Item not found'
  | 'Biometrics not available'
  | SharedOperationErrors;

interface OPS2 {
  set: (params: {
    key: string;
    value: string;
    withBiometrics?: boolean;
    accessibility?: ACCESSIBILITY;
  }) => { error?: SetErrors };
  get: (params: {
    key: string;
    withBiometrics?: boolean;
    accessibility?: ACCESSIBILITY;
  }) => { value: string | undefined; error?: GetErrors };
  del: (params: { key: string; withBiometrics?: boolean }) => void;
}
