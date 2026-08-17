import { NativeModules } from 'react-native';

declare global {
  var __OPS2Proxy: OPS2 | undefined;
}

if (globalThis.__OPS2Proxy == null) {
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
  if (globalThis.__OPS2Proxy == null) {
    throw new Error(
      'Failed to install op-s2, the native initializer function does not exist. Are you trying to use OPS2 from different JS Runtimes?'
    );
  }
}

const proxy = globalThis.__OPS2Proxy;

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

interface BiometricPromptOptions {
  /**
   * Title shown on the biometric/device credential prompt.
   */
  title?: string;
  /**
   * Subtitle shown beneath the title on the biometric/device credential prompt.
   * (iOS does not have a native subtitle field; when provided it is appended to the title.)
   */
  subtitle?: string;
  /**
   * Label of the negative (cancel) button.
   */
  negativeButtonText?: string;
  /**
   * Allow the device passcode (PIN/pattern/password) as an alternative to biometrics.
   * Maps to:
   * - iOS: `kSecAttrAccessControlDevicePasscode` and `LAPolicyDeviceOwnerAuthentication`
   * - Android: `BiometricManager.Authenticators.DEVICE_CREDENTIAL`
   * Defaults to `false`.
   */
  allowDeviceCredential?: boolean;
  /**
   * Allow Class 2 (weak) biometrics on Android (e.g. face/iris without strict hardware backing).
   * On iOS this maps to `kSecAccessControlBiometryAny` instead of
   * `kSecAccessControlBiometryCurrentSet` (less strict re-enrollment check).
   * Defaults to `false` (strong biometrics only).
   */
  allowBiometricWeak?: boolean;
}

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

interface SetParams {
  key: string;
  value: string;
  /**
   * iOS only: the keychain accessibility class. Mutually exclusive with
   * `withBiometrics` on iOS.
   */
  accessibility?: ACCESSIBILITY;
  /**
   * Require biometric (and/or device credential) authentication before
   * reading or writing the value.
   */
  withBiometrics?: boolean;
  /**
   * Customize the biometric prompt and the accepted authenticators.
   */
  biometricPrompt?: BiometricPromptOptions;
}

interface GetParams {
  key: string;
  accessibility?: ACCESSIBILITY;
  withBiometrics?: boolean;
  biometricPrompt?: BiometricPromptOptions;
}

interface OPS2 {
  set: (params: SetParams) => { error?: SetErrors };
  get: (params: GetParams) => { value: string | undefined; error?: GetErrors };
  del: (params: {
    key: string;
    withBiometrics?: boolean;
    biometricPrompt?: BiometricPromptOptions;
  }) => void;
}

// Map the string-based ACCESSIBILITY enum to the integer codes the iOS
// keychain expects. Android ignores this value, so the translation is harmless
// on that platform. Keeping the public enum as strings means existing
// consumers don't need to change anything — we normalize internally before
// hitting the native side.
const ACCESSIBILITY_TO_INT: Record<string, number> = {
  AccessibleWhenUnlocked: 0,
  AccessibleAfterFirstUnlock: 1,
  AccessibleAlways: 2,
  AccessibleWhenPasscodeSetThisDeviceOnly: 3,
  AccessibleAfterFirstUnlockThisDeviceOnly: 4,
  AccessibleAlwaysThisDeviceOnly: 5,
  AccessibleWhenUnlockedThisDeviceOnly: 6,
};

function normalizeAccessibility(
  value: ACCESSIBILITY | undefined
): number | undefined {
  if (value === undefined) return undefined;
  const mapped = ACCESSIBILITY_TO_INT[value as string];
  return mapped ?? 1; // default to kSecAttrAccessibleAfterFirstUnlock
}

type NativeSetParams = {
  key: string;
  value: string;
  accessibility?: number;
  withBiometrics?: boolean;
  biometricPrompt?: BiometricPromptOptions;
};

type NativeGetParams = {
  key: string;
  accessibility?: number;
  withBiometrics?: boolean;
  biometricPrompt?: BiometricPromptOptions;
};

function normalizeSetParams(params: SetParams): NativeSetParams {
  return {
    ...params,
    accessibility: normalizeAccessibility(params.accessibility),
  };
}

function normalizeGetParams(params: GetParams): NativeGetParams {
  return {
    ...params,
    accessibility: normalizeAccessibility(params.accessibility),
  };
}

export const set: OPS2['set'] = (params) =>
  proxy.set(
    normalizeSetParams(params) as unknown as Parameters<typeof proxy.set>[0]
  );

export const get: OPS2['get'] = (params) =>
  proxy.get(
    normalizeGetParams(params) as unknown as Parameters<typeof proxy.get>[0]
  );

export const del = proxy.del;
