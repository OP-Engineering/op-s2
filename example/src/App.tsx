import { Text, StyleSheet } from 'react-native';
import { useEffect, useState } from 'react';
import {
  SafeAreaProvider,
  SafeAreaView,
} from 'react-native-safe-area-context';
import {
  displayResults,
  runTests,
  type DescribeBlock,
} from '@op-engineering/op-test';
import './tests';

export default function App() {
  let [results, setResults] = useState<DescribeBlock | null>(null);
  useEffect(() => {
    let run = async () => {
      let results2 = await runTests();
      setResults(results2);
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
