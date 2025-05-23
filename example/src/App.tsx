import { Text, StyleSheet, SafeAreaView } from 'react-native';
import { useEffect, useState } from 'react';
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
    <SafeAreaView style={styles.container}>
      {results ? displayResults(results) : <Text>Loading...</Text>}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#222',
  },
});
