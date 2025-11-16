import type { AppType } from './server';
import { hc } from 'hono/client';

export const create_client = (base: string) => hc<AppType>(base);
