import { set, get } from '@op-engineering/op-s2';
import { beforeEach, describe, it } from './MochaRNAdapter';
import chai from 'chai';

const expect = chai.expect;

export function getSetTests() {
  beforeEach(() => {});

  describe('securely storage/retrieve', () => {
    it('set/get', () => {
      const key = 'key1';
      set({
        key,
        value: 'myTestValue',
      });

      const { value, error } = get({
        key,
      });

      expect(error).to.be.undefined;
      expect(value).to.equal('myTestValue');
    });

    it('get not set returns empty', () => {
      const key = 'key2';
      const { value, error } = get({
        key,
      });

      expect(value).to.be.undefined;
      expect(error).to.equal('NOT FOUND');
    });

    it('Setting not a string gives error', () => {
      const key = 'key3';

      const { error } = set({
        key,
        // @ts-ignore
        value: 123,
      });

      expect(error).to.equal('Value property is not a string');
    });
  });
}
