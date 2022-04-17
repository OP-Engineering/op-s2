import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

export interface Spec extends TurboModule {
  getConstants: () => {};

  setItem(key: string, value: string): { error?: Object };

  getItem(key: string): { error?: Object; value: string };

  deleteItem(key: string): { error?: Object };
}

export default TurboModuleRegistry.get<Spec>('TurboSecureStorage')!;
