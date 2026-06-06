import type { Config } from 'jest';

const config: Config = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  rootDir: '.',
  testMatch: ['<rootDir>/tests/**/*.test.ts'],
  moduleNameMapper: {
    '^(\\.{1,2}/.*)\\.js$': '$1'
  },
  transform: {
    '^.+\\.ts$': ['ts-jest', { tsconfig: { module: 'CommonJS' } }]
  },
  clearMocks: true,
  collectCoverageFrom: [
    'src/modulos/**/*.ts',
    '!src/modulos/**/*.rutas.ts',
    '!src/generated/**'
  ]
};

export default config;
