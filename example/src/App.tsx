import * as React from 'react';
import { View, Text, SafeAreaView, ScrollView, Button } from 'react-native';
import { getSetTests } from './tests/secureStore.spec';
import { runTests } from './tests/MochaSetup';
import { get, set } from '@op-engineering/op-s2';

export default function App() {
  const [results, setResults] = React.useState<any>([]);

  React.useEffect(() => {
    setResults([]);
    runTests(getSetTests).then(setResults);
  }, []);

  const allTestsPassed = results.reduce((acc: boolean, r: any) => {
    return acc && r.type !== 'incorrect';
  }, true);

  const setWithBiometrics = () => {
    const { error } = set({
      key: 'withBiometrics',
      value: 'quack',
      withBiometrics: true,
    });

    if (error) {
      console.warn(error);
    }
  };

  const getWithBiometrics = () => {
    const { value } = get({
      key: 'withBiometrics',
      withBiometrics: true,
    });

    if (value) {
      console.warn('got value', value);
    }
  };

  return (
    <SafeAreaView className="flex-1 bg-neutral-900">
      <ScrollView className="flex-1">
        <Text className=" text-white text-2xl p-2">OP-S2</Text>

        <View className="flex-row p-2 bg-neutral-600 items-center">
          <Text className={'text-lg flex-1  text-white'}>BIOMETRICS</Text>
        </View>
        <Button title="Set with biometrics" onPress={setWithBiometrics} />
        <Button title="Get with biometrics" onPress={getWithBiometrics} />

        <View className="flex-row p-2 mt-4 bg-neutral-600 items-center">
          <Text className={'text-lg flex-1  text-white'}>ALL TESTS</Text>
          {allTestsPassed ? <Text>🟩</Text> : <Text>🟥</Text>}
        </View>
        {results.map((r: any, i: number) => {
          if (r.type === 'grouping') {
            return (
              <Text className="bg-neutral-700 p-2 text-white" key={i}>
                {r.description}
              </Text>
            );
          }

          if (r.type === 'incorrect') {
            return (
              <View
                className="border-b border-neutral-600 p-2 flex-row"
                key={i}
              >
                <Text key={i} className="text-white flex-1">
                  {r.description}: {r.errorMsg}
                </Text>
                <Text>🔻</Text>
              </View>
            );
          }

          return (
            <View className="border-b border-neutral-600 p-2 flex-row" key={i}>
              <Text key={i} className="text-white flex-1">
                {r.description}
              </Text>
              <Text>🟢</Text>
            </View>
          );
        })}
      </ScrollView>
    </SafeAreaView>
  );
}
