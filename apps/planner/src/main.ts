import { readFileSync } from 'node:fs';
import process from 'node:process';
import { plan, schedule, type Task } from '@spec-loop/task-sched';

type Args = {
  subcommand: string;
  file?: string;
  format: 'table' | 'json';
  parallel?: number;
};

function parse(argv: string[]): Args {
  const tokens = argv.slice(2);
  if (tokens.length === 0) {
    throw new Error('missing subcommand (expected plan or schedule)');
  }

  const subcommand = tokens[0];
  const flags = tokens.slice(1);

  const args: Args = { subcommand, format: 'table' };

  let i = 0;
  while (i < flags.length) {
    const flag = flags[i];
    if (flag === '--format') {
      const value = flags[i + 1];
      if (value !== 'table' && value !== 'json') {
        throw new Error(
          `unknown --format value: ${value} (expected table or json)`,
        );
      }
      args.format = value;
      i += 2;
      continue;
    }
    if (flag === '--parallel') {
      const value = flags[i + 1];
      const parsed = Number(value);
      if (!Number.isInteger(parsed) || parsed < 1) {
        throw new Error(
          `invalid --parallel value: ${value} (expected a positive integer)`,
        );
      }
      args.parallel = parsed;
      i += 2;
      continue;
    }
    if (!flag.startsWith('-') && args.file === undefined) {
      args.file = flag;
      i += 1;
      continue;
    }
    throw new Error(`unknown flag: ${flag}`);
  }

  return args;
}

function loadTasks(file?: string): Task[] {
  if (!file) {
    throw new Error('missing input file');
  }
  const raw = readFileSync(file, 'utf8');
  const parsed = JSON.parse(raw) as unknown;
  if (!Array.isArray(parsed)) {
    throw new Error('task file must contain a JSON array of tasks');
  }
  return parsed as Task[];
}

function usage(): string {
  return 'Usage: planner plan <file> [--format table|json]\n       planner schedule <file> [--parallel N] [--format table|json]';
}

function formatTable(planIds: string[]): string {
  const width = Math.max(...planIds.map((id) => id.length), 5);
  return `order\n${'-'.repeat(width)}\n${planIds.map((id, i) => `${String(i + 1).padStart(width - 1, ' ')}  ${id}`).join('\n')}`;
}

function formatWaves(waves: string[][]): string {
  return waves.map((wave, i) => `wave ${i + 1}: ${wave.join(', ')}`).join('\n');
}

function render(
  value: string[] | string[][],
  subcommand: 'plan' | 'schedule',
  format: 'table' | 'json',
): string {
  if (format === 'json') {
    return JSON.stringify(value, null, 2);
  }
  return subcommand === 'schedule'
    ? formatWaves(value as string[][])
    : formatTable(value as string[]);
}

export function main(argv: string[]): number {
  let args: Args;
  try {
    args = parse(argv);
  } catch (error) {
    process.stderr.write(
      `${error instanceof Error ? error.message : String(error)}\n${usage()}\n`,
    );
    return 2;
  }

  if (args.subcommand !== 'plan' && args.subcommand !== 'schedule') {
    process.stderr.write(
      `unknown subcommand: ${args.subcommand}\n${usage()}\n`,
    );
    return 2;
  }

  let tasks: Task[];
  try {
    tasks = loadTasks(args.file);
  } catch (error) {
    process.stderr.write(
      `${error instanceof Error ? error.message : String(error)}\n`,
    );
    return 1;
  }

  const subcommand = args.subcommand;
  try {
    const value =
      subcommand === 'plan' ? plan(tasks) : schedule(tasks, args.parallel ?? 1);
    process.stdout.write(render(value, subcommand, args.format) + '\n');
    return 0;
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    if (args.format === 'json') {
      process.stderr.write(JSON.stringify({ error: message }, null, 2) + '\n');
    } else {
      process.stderr.write(message + '\n');
    }
    return 1;
  }
}

if (process.argv[1] && process.argv[1].includes('main.ts')) {
  const code = main(process.argv);
  process.exitCode = code;
}
