import React from 'react';
import { Button, SafeAreaView } from 'react-native';
import TurboSecureStorage from 'turbo-secure-storage';

const App = () => {
  return (
    <SafeAreaView>
      <Button
        title="Set Item"
        onPress={() => {
          TurboSecureStorage.setItem('foo', 'bar');
        }}
      />
    </SafeAreaView>
  );
};

export default App;
