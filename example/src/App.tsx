import { Text, StyleSheet } from 'react-native';
import { useEffect, useState } from 'react';
import { SafeAreaProvider, SafeAreaView } from 'react-native-safe-area-context';
import {
  allTestsPassed,
  displayResults,
  runTests,
  type DescribeBlock,
} from '@op-engineering/op-test';
import './tests';

export default function App() {
  let [results, setResults] = useState<DescribeBlock | null>(null);
  useEffect(() => {
    let run = async () => {
      console.log('App has started 🟢');
      try {
        console.log('TESTS STARTED 🟠');
        let results2 = await runTests();
        let passed = allTestsPassed(results2);
        console.log('TESTS FINISHED 🟢');
        console.log(`OPS2_TEST_RESULT:${passed ? 'PASS' : 'FAIL'}`);
        setResults(results2);
      } catch (e) {
        console.log(`TEST FAILED 🟥 ${e}`);
        console.log('OPS2_TEST_RESULT:FAIL');
      }
    };
    run();
  }, []);
  return (
    <SafeAreaProvider>
      <SafeAreaView style={styles.container}>
        {results ? displayResults(results) : <Text>Loading...</Text>}
      </SafeAreaView>
    </SafeAreaProvider>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#222',
  },
});
