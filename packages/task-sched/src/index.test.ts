import assert from 'node:assert/strict';
import test from 'node:test';
import { plan, ready, schedule } from './index.ts';

const diamond = [
  { id: 'root' },
  { id: 'a', dependsOn: ['root'] },
  { id: 'b', dependsOn: ['root'] },
  { id: 'c', dependsOn: ['a', 'b'] },
];

test('plan returns an empty array for an empty input', () => {
  assert.deepEqual(plan([]), []);
});

test('plan returns a complete, dependency-ordered list for a diamond', () => {
  assert.deepEqual(plan(diamond), ['root', 'a', 'b', 'c']);
  assert.deepEqual(plan(diamond), ['root', 'a', 'b', 'c']);
});

test('plan rejects a cycle', () => {
  assert.throws(
    () =>
      plan([
        { id: 'a', dependsOn: ['b'] },
        { id: 'b', dependsOn: ['a'] },
      ]),
    /cycle/,
  );
});

test('ready excludes completed ids and tasks missing dependencies', () => {
  const all = [
    { id: 'a' },
    { id: 'b', dependsOn: ['a'] },
    { id: 'c', dependsOn: ['b'] },
  ];
  assert.deepEqual(ready(all, []), ['a']);
  assert.deepEqual(ready(all, ['a']), ['b']);
  assert.deepEqual(ready(all, ['a', 'b']), ['c']);
  assert.deepEqual(ready(all, ['a', 'b', 'c']), []);
});

test('schedule returns three waves for a chain with parallel=1', () => {
  const chain = [
    { id: 'c', dependsOn: ['b'] },
    { id: 'b', dependsOn: ['a'] },
    { id: 'a' },
  ];
  assert.deepEqual(schedule(chain, 1), [['a'], ['b'], ['c']]);
});

test('schedule respects the cap on a diamond with parallel=2', () => {
  const waves = schedule(diamond, 2);
  for (const wave of waves) {
    assert.ok(wave.length <= 2, `wave exceeds cap: ${wave.join(',')}`);
  }
  const flat = waves.flat();
  assert.equal(flat.length, 4);
  new Set(flat).forEach((id) =>
    assert.ok(['root', 'a', 'b', 'c'].includes(id)),
  );
  // Root must come before a and b; c must come after a and b.
  const indexOf = (id: string) => flat.indexOf(id);
  assert.ok(indexOf('root') < indexOf('a'));
  assert.ok(indexOf('root') < indexOf('b'));
  assert.ok(indexOf('a') < indexOf('c'));
  assert.ok(indexOf('b') < indexOf('c'));
});

test('schedule preserves input order within a wave', () => {
  const independent = [{ id: 'x' }, { id: 'y' }, { id: 'z' }];
  assert.deepEqual(schedule(independent, 2), [['x', 'y'], ['z']]);
});

test('schedule rejects a non-positive parallel value', () => {
  assert.throws(() => schedule(diamond, 0), /parallel/);
});

test('schedule rejects a cyclic input', () => {
  assert.throws(
    () =>
      schedule(
        [
          { id: 'a', dependsOn: ['b'] },
          { id: 'b', dependsOn: ['a'] },
        ],
        1,
      ),
    /cycle/,
  );
});
