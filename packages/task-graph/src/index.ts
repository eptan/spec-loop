export type Task = {
  id: string;
  dependsOn?: string[];
};

export type ValidatedTask = {
  id: string;
  dependsOn: string[];
};

export function validate(tasks: Task[]): ValidatedTask[] {
  if (!Array.isArray(tasks)) {
    throw new Error('task graph must be an array of tasks');
  }

  const knownIds = new Set(
    tasks.flatMap((task) =>
      task && typeof task.id === 'string' ? [task.id] : [],
    ),
  );
  const seen = new Set<string>();
  const validated: ValidatedTask[] = [];

  for (const [index, task] of tasks.entries()) {
    if (typeof task !== 'object' || task === null) {
      throw new Error(`task at index ${index} must be an object`);
    }

    if (typeof task.id !== 'string') {
      throw new Error(`task id must be a string (got ${String(task.id)})`);
    }

    if (task.id.trim().length === 0) {
      throw new Error('task id must not be empty');
    }

    if (seen.has(task.id)) {
      throw new Error(`duplicate task id: ${task.id}`);
    }
    seen.add(task.id);

    const dependsOn = task.dependsOn === undefined ? [] : task.dependsOn;
    if (!Array.isArray(dependsOn)) {
      throw new Error(`task "${task.id}" dependsOn must be an array`);
    }
    for (const dep of dependsOn) {
      if (typeof dep !== 'string') {
        throw new Error(
          `task "${task.id}" has a non-string dependency: ${String(dep)}`,
        );
      }
      if (dep === task.id) {
        throw new Error(`task "${task.id}" depends on itself`);
      }
      if (!knownIds.has(dep)) {
        throw new Error(`task "${task.id}" has an unknown dependency: ${dep}`);
      }
    }

    validated.push({ id: task.id, dependsOn });
  }

  const cycle = findCycle(validated);
  if (cycle) {
    throw new Error(`dependency cycle: ${cycle.join(' -> ')} -> ${cycle[0]}`);
  }

  return validated;
}

export function topoOrder(tasks: Task[]): string[] {
  const validated = validate(tasks);
  const order: string[] = [];
  const placed = new Set<string>();

  let progress = true;
  while (progress && order.length < validated.length) {
    progress = false;
    for (const task of validated) {
      if (placed.has(task.id)) {
        continue;
      }
      if (task.dependsOn.every((dep) => placed.has(dep))) {
        order.push(task.id);
        placed.add(task.id);
        progress = true;
      }
    }
  }

  if (order.length !== validated.length) {
    throw new Error('task graph cannot be fully ordered');
  }

  return order;
}

export function isReady(task: Task, completed: string[]): boolean {
  if (typeof task.id !== 'string') {
    throw new Error(`task id must be a string (got ${String(task.id)})`);
  }
  if (completed.includes(task.id)) {
    return false;
  }
  const dependsOn = task.dependsOn === undefined ? [] : task.dependsOn;
  if (!Array.isArray(dependsOn)) {
    throw new Error(`task "${task.id}" dependsOn must be an array`);
  }
  return dependsOn.every((dep) => completed.includes(dep));
}

function findCycle(tasks: ValidatedTask[]): string[] | null {
  const WHITE = 0;
  const GRAY = 1;
  const BLACK = 2;
  const color = new Map(tasks.map((task) => [task.id, WHITE]));
  const stack: string[] = [];

  const adjacency = new Map(tasks.map((task) => [task.id, task.dependsOn]));

  const visit = (id: string): string[] | null => {
    color.set(id, GRAY);
    stack.push(id);
    for (const dep of adjacency.get(id) ?? []) {
      const state = color.get(dep);
      if (state === GRAY) {
        return stack.slice(stack.indexOf(dep));
      }
      if (state === WHITE) {
        const found = visit(dep);
        if (found) {
          return found;
        }
      }
    }
    stack.pop();
    color.set(id, BLACK);
    return null;
  };

  for (const task of tasks) {
    if (color.get(task.id) === WHITE) {
      const found = visit(task.id);
      if (found) {
        return found;
      }
    }
  }

  return null;
}
