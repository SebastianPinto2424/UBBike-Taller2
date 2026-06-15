import { PrismaClient } from '../../src/generated/prisma/client';
import { mockDeep, mockReset, DeepMockProxy } from 'jest-mock-extended';

jest.mock('../../src/configuracion/prisma', () => ({
  __esModule: true,
  prisma: mockDeep<PrismaClient>()
}));

beforeEach(() => {
  mockReset(prismaMock);
  prismaMock.$transaction.mockImplementation((async (arg: unknown) =>
    typeof arg === 'function'
      ? (arg as (tx: typeof prismaMock) => unknown)(prismaMock)
      : Promise.all(arg as Promise<unknown>[])) as never);
});

export const prismaMock = jest.requireMock(
  '../../src/configuracion/prisma'
).prisma as DeepMockProxy<PrismaClient>;
