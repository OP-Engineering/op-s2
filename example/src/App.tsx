import * as React from 'react';
import { View, Text, SafeAreaView, ScrollView } from 'react-native';
import { getSetTests } from './tests/secureStore.spec';
import { runTests } from './tests/MochaSetup';
import { get, set } from '@op-engineering/op-s2';
import performance from 'react-native-performance';
import { MMKV } from 'react-native-mmkv';

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
    let writeVals = [];
    let totalStart = performance.now();
    for (let i = 0; i < ITERATION_COUNT; i++) {
      const start = performance.now();
      set({
        key: 'benchmarkKey',
        value: 'blah',
      });
      const end = performance.now();
      writeVals.push(end - start);
    }
    let totalEnd = performance.now();
    let s2totalWrite = totalEnd - totalStart;

    totalStart = performance.now();
    let readVals = [];
    for (let i = 0; i < ITERATION_COUNT; i++) {
      const start = performance.now();
      get({
        key: 'benchmarkKey',
      });
      const end = performance.now();
      readVals.push(end - start);
    }
    totalEnd = performance.now();
    let s2totalRead = totalEnd - totalStart;

    totalStart = performance.now();
    let mmkvWriteVals = [];
    for (let i = 0; i < ITERATION_COUNT; i++) {
      const start = performance.now();
      mmkv.set('benchmarkKey', 'quack');
      const end = performance.now();
      mmkvWriteVals.push(end - start);
    }
    totalEnd = performance.now();
    let mmkvTotalWrite = totalEnd - totalStart;

    totalStart = performance.now();
    let mmkvReadVals = [];
    for (let i = 0; i < ITERATION_COUNT; i++) {
      const start = performance.now();
      mmkv.getString('benchmarkKey');
      const end = performance.now();
      mmkvReadVals.push(end - start);
    }
    totalEnd = performance.now();
    let mmkvTotalRead = totalEnd - totalStart;

    return {
      s2write: writeVals.reduce((acc, n) => acc + n, 0) / writeVals.length,
      s2read: readVals.reduce((acc, n) => acc + n, 0) / readVals.length,
      s2totalWrite,
      s2totalRead,
      mmkvWrite:
        mmkvWriteVals.reduce((acc, n) => acc + n, 0) / mmkvWriteVals.length,
      mmkvRead:
        mmkvReadVals.reduce((acc, n) => acc + n, 0) / mmkvReadVals.length,
      mmkvTotalWrite,
      mmkvTotalRead,
    };
  };

  const allTestsPassed = results.reduce((acc: boolean, r: any) => {
    return acc && r.type !== 'incorrect';
  }, true);

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
              Write {benchmarks.s2write.toFixed(2)}ms.
            </Text>

            <Text className="text-white">
              Read {benchmarks.s2read.toFixed(2)}ms.
            </Text>
            <Text className="text-white font-bold mt-4">MMKV</Text>
            <Text className="text-white">
              Write {benchmarks.mmkvWrite.toFixed(2)}ms.
            </Text>
            <Text className="text-white">
              Read {benchmarks.mmkvRead.toFixed(2)}ms.
            </Text>
          </View>
        )}

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
