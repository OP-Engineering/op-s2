import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

export interface Spec extends TurboModule {
  getConstants: () => {};

  setItem(key: string, value: string): { error?: Object };
}

export default TurboModuleRegistry.get<Spec>('TurboSecureStorage')!;
