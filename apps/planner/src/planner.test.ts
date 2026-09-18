import { execFileSync } from 'node:child_process';
import assert from 'node:assert/strict';
import { mkdtempSync, writeFileSync } from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';

const cli = path.join(import.meta.dirname, 'main.ts');
const nodeArgs = [
  '--conditions=@spec-loop/source',
  '--experimental-strip-types',
];

function runCli(
  args: string[],
  file?: string,
): { code: number | null; stdout: string; stderr: string } {
  try {
    const stdout = execFileSync(
      process.execPath,
      [...nodeArgs, cli, ...args, ...(file ? [file] : [])],
      { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] },
    );
    return { code: 0, stdout, stderr: '' };
  } catch (error) {
    const err = error as { status?: number; stdout?: string; stderr?: string };
    return {
      code: err.status ?? 1,
      stdout: err.stdout ?? '',
      stderr: err.stderr ?? '',
    };
  }
}

function writeFixture(content: unknown): string {
  const tmp = mkdtempSync(path.join(os.tmpdir(), 'planner-test-'));
  const file = path.join(tmp, 'tasks.json');
  writeFileSync(file, JSON.stringify(content, null, 2));
  return file;
}

const diamond = [
  { id: 'root' },
  { id: 'a', dependsOn: ['root'] },
  { id: 'b', dependsOn: ['root'] },
  { id: 'c', dependsOn: ['a', 'b'] },
];

test('plan prints a deterministic table for a fixed fixture', () => {
  const file = writeFixture(diamond);
  const first = runCli(['plan'], file);
  const second = runCli(['plan'], file);
  assert.equal(first.code, 0);
  assert.equal(first.stdout, second.stdout);
  assert.match(first.stdout, /root/);
  assert.match(first.stdout, /order/);
});

test('plan --format json emits parseable JSON containing the input ids', () => {
  const file = writeFixture(diamond);
  const result = runCli(['plan', '--format', 'json'], file);
  assert.equal(result.code, 0);
  const parsed = JSON.parse(result.stdout);
  assert.ok(Array.isArray(parsed));
  for (const id of ['root', 'a', 'b', 'c']) {
    assert.ok(parsed.includes(id));
  }
});

test('schedule --parallel 1 yields waves of one id each', () => {
  const chain = [
    { id: 'c', dependsOn: ['b'] },
    { id: 'b', dependsOn: ['a'] },
    { id: 'a' },
  ];
  const file = writeFixture(chain);
  const result = runCli(['schedule', '--parallel', '1'], file);
  assert.equal(result.code, 0);
  assert.match(result.stdout, /wave 1: a/);
  assert.match(result.stdout, /wave 2: b/);
  assert.match(result.stdout, /wave 3: c/);
});

test('a cycle produces the same non-zero error on every run', () => {
  const cycle = [
    { id: 'a', dependsOn: ['b'] },
    { id: 'b', dependsOn: ['a'] },
  ];
  const file = writeFixture(cycle);
  const first = runCli(['plan'], file);
  const second = runCli(['plan'], file);
  assert.notEqual(first.code, 0);
  assert.equal(first.code, second.code);
  assert.equal(first.stderr, second.stderr);
  assert.match(first.stderr, /cycle/);
});

test('an unknown subcommand is rejected with a non-zero exit', () => {
  const file = writeFixture(diamond);
  const result = runCli(['destroy'], file);
  assert.notEqual(result.code, 0);
  assert.match(result.stderr, /unknown subcommand/);
});
