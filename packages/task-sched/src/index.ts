import { isReady, topoOrder, validate, type Task } from '@spec-loop/task-graph';

export { type Task } from '@spec-loop/task-graph';

export type ScheduleOptions = {
  parallel: number;
};

export type Waves = string[][];

export function plan(tasks: Task[]): string[] {
  return topoOrder(tasks);
}

export function ready(tasks: Task[], completed: string[]): string[] {
  return tasks
    .filter((task) => isReady(task, completed))
    .map((task) => task.id);
}

export function schedule(tasks: Task[], parallel: number): Waves {
  if (
    typeof parallel !== 'number' ||
    !Number.isInteger(parallel) ||
    parallel < 1
  ) {
    throw new Error('parallel must be a positive integer');
  }

  validate(tasks);
  if (tasks.length === 0) {
    return [];
  }

  const waves: Waves = [];
  const completed: string[] = [];

  while (completed.length < tasks.length) {
    const wave = ready(tasks, completed).slice(0, parallel);
    if (wave.length === 0) {
      throw new Error('task graph cannot be fully scheduled');
    }
    waves.push(wave);
    for (const id of wave) {
      completed.push(id);
    }
  }

  return waves;
}
