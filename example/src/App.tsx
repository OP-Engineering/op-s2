import * as React from 'react';
import { View, Text, SafeAreaView, ScrollView, Button } from 'react-native';
import { getSetTests } from './tests/secureStore.spec';
import { runTests } from './tests/MochaSetup';
import { get, set } from '@op-engineering/op-s2';
import performance from 'react-native-performance';
import { MMKV } from 'react-native-mmkv';
import { open as openDB } from '@op-engineering/op-sqlcipher';

const db = openDB({
  name: 'test',
  encryptionKey: 'testKey',
});

db.execute('DROP TABLE IF EXISTS Test;');
db.execute('CREATE TABLE Test (v1 TEXT) STRICT;');

const ITERATION_COUNT = 1;

export const mmkv = new MMKV({
  id: 'encrypted-mmkv-storage',
  encryptionKey: 'hunter2',
});

export default function App() {
  const [results, setResults] = React.useState<any>([]);
  const [benchmarks, setBenchmarks] = React.useState<any>();

  React.useEffect(() => {
    setResults([]);
    runTests(getSetTests)
      .then(setResults)
      .then(runBenchmarks)
      .then(setBenchmarks);
  }, []);

  const runBenchmarks = async () => {
    let totalStart = performance.now();
    for (let i = 0; i < ITERATION_COUNT; i++) {
      set({
        key: 'benchmarkKey',
        value: 'blah',
      });
    }
    let totalEnd = performance.now();
    let s2totalWrite = totalEnd - totalStart;

    totalStart = performance.now();
    for (let i = 0; i < ITERATION_COUNT; i++) {
      get({
        key: 'benchmarkKey',
      });
    }
    totalEnd = performance.now();
    let s2totalRead = totalEnd - totalStart;

    totalStart = performance.now();
    for (let i = 0; i < ITERATION_COUNT; i++) {
      mmkv.set('benchmarkKey', 'quack');
    }
    totalEnd = performance.now();
    let mmkvTotalWrite = totalEnd - totalStart;

    totalStart = performance.now();
    for (let i = 0; i < ITERATION_COUNT; i++) {
      mmkv.getString('benchmarkKey');
    }
    totalEnd = performance.now();
    let mmkvTotalRead = totalEnd - totalStart;

    totalStart = performance.now();
    for (let i = 0; i < ITERATION_COUNT; i++) {
      db.execute('INSERT INTO "Test" (v1) VALUES(?)', ['quack']);
    }
    totalEnd = performance.now();
    let sqliteWrite = totalEnd - totalStart;

    totalStart = performance.now();
    for (let i = 0; i < ITERATION_COUNT; i++) {
      db.execute('SELECT * FROM Test;');
    }
    totalEnd = performance.now();
    let sqliteRead = totalEnd - totalStart;

    return {
      s2totalWrite,
      s2totalRead,
      mmkvTotalWrite,
      mmkvTotalRead,
      sqliteWrite,
      sqliteRead,
    };
  };

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
          <Text className={'text-lg flex-1  text-white'}>BENCHMARKS</Text>
        </View>
        {benchmarks != null && (
          <View className="p-2">
            <Text className="text-white font-bold">OP-S2</Text>
            <Text className="text-white">
              Write {benchmarks.s2totalWrite.toFixed(2)}ms.
            </Text>

            <Text className="text-white">
              Read {benchmarks.s2totalRead.toFixed(2)}ms.
            </Text>

            <Text className="text-white font-bold mt-4">MMKV</Text>
            <Text className="text-white">
              Write {benchmarks.mmkvTotalWrite.toFixed(2)}ms.
            </Text>
            <Text className="text-white">
              Read {benchmarks.mmkvTotalRead.toFixed(2)}ms.
            </Text>

            <Text className="text-white font-bold mt-4">SQLCipher</Text>
            <Text className="text-white">
              Write {benchmarks.sqliteWrite.toFixed(2)}ms.
            </Text>
            <Text className="text-white">
              Read {benchmarks.sqliteRead.toFixed(2)}ms.
            </Text>
          </View>
        )}

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
              <Text className="bg-neutral-700 p-2 text-white">
                {r.description}
              </Text>
            );
          }

          if (r.type === 'incorrect') {
            return (
              <View className="border-b border-neutral-600 p-2 flex-row">
                <Text key={i} className="text-white flex-1">
                  {r.description}: {r.errorMsg}
                </Text>
                <Text>🔻</Text>
              </View>
            );
          }

          return (
            <View className="border-b border-neutral-600 p-2 flex-row">
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
