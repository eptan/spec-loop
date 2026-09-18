import assert from 'node:assert/strict';
import test from 'node:test';
import { isReady, topoOrder, validate } from './index.ts';

const diamond = [
  { id: 'root' },
  { id: 'a', dependsOn: ['root'] },
  { id: 'b', dependsOn: ['root'] },
  { id: 'c', dependsOn: ['a', 'b'] },
];

test('accepts a single valid task', () => {
  const validated = validate([{ id: 'a' }]);
  assert.deepEqual(validated, [{ id: 'a', dependsOn: [] }]);
});

test('rejects a missing task array', () => {
  // @ts-expect-error — exercising the runtime guard for a non-array input
  assert.throws(() => validate(undefined), /must be an array/);
});

test('rejects a non-string id with its value in the message', () => {
  assert.throws(() => validate([{ id: 42 }]), /42/);
});

test('rejects duplicate ids', () => {
  assert.throws(
    () => validate([{ id: 'a' }, { id: 'a' }]),
    /duplicate task id: a/,
  );
});

test('rejects a two-node cycle naming both ids', () => {
  assert.throws(
    () =>
      validate([
        { id: 'a', dependsOn: ['b'] },
        { id: 'b', dependsOn: ['a'] },
      ]),
    /cycle.*a.*b|cycle.*b.*a/,
  );
});

test('rejects a self-dependency with the offending id', () => {
  assert.throws(
    () => validate([{ id: 'a', dependsOn: ['a'] }]),
    /depends on itself/,
  );
});

test('rejects an unknown dependency naming the missing id', () => {
  assert.throws(
    () => validate([{ id: 'a', dependsOn: ['missing'] }]),
    /unknown dependency: missing/,
  );
});

test('orders a diamond graph deterministically in input order', () => {
  const order = topoOrder(diamond);
  const order2 = topoOrder(diamond);
  assert.deepEqual(order, ['root', 'a', 'b', 'c']);
  assert.deepEqual(order2, order);
});

test('orders a chain in dependency order', () => {
  assert.deepEqual(
    topoOrder([
      { id: 'c', dependsOn: ['b'] },
      { id: 'b', dependsOn: ['a'] },
      { id: 'a' },
    ]),
    ['a', 'b', 'c'],
  );
});

test('treats a dependency-free task as ready', () => {
  assert.equal(isReady({ id: 'a' }, []), true);
});

test('gates a task behind all of its dependencies', () => {
  assert.equal(isReady({ id: 'b', dependsOn: ['a'] }, []), false);
  assert.equal(isReady({ id: 'b', dependsOn: ['a'] }, ['a']), true);
});

test('excludes an already completed task', () => {
  assert.equal(isReady({ id: 'a' }, ['a']), false);
});
