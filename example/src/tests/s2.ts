import { del, get, set } from '@op-engineering/op-s2';
import { describe, expect, it } from '@op-engineering/op-test';

describe('securely storage/retrieve', () => {
  it('set/get', () => {
    const key = 'key1';
    const { error: setError } = set({
      key,
      value: 'myTestValue',
    });

    if (setError) {
      console.warn(setError);
    }
    expect(setError).toBe(undefined);

    const { value, error } = get({
      key,
    });

    expect(error).toBe(undefined);
    expect(value).toEqual('myTestValue');
  });

  it('get not set returns empty', () => {
    const key = 'key2';
    const { value, error } = get({
      key,
    });

    expect(value).toBe(undefined);
    expect(error).toEqual('[op-s2] Item not found');
  });

  it('Setting not a string gives error', () => {
    const key = 'key3';

    const { error } = set({
      key,
      // @ts-ignore
      value: 123,
    });

    expect(error).toBe('Value property is not a string');
  });

  it('Deletes a key', () => {
    const key = 'key4';

    set({
      key,
      value: 'myTestValue',
    });

    let { value, error } = get({
      key,
    });

    expect(error).toBe(undefined);
    expect(value).toEqual('myTestValue');

    del({
      key,
    });

    let { value: val2, error: error2 } = get({
      key,
    });

    expect(val2).toBe(undefined);
    expect(error2).toEqual('[op-s2] Item not found');
  });
});
