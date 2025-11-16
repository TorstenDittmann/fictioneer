import { PUBLIC_INTELLIGENCE_SERVER_URL } from '$env/static/public';
import { create_client } from '@fictioneer/intelligence/client';

export const client = create_client(PUBLIC_INTELLIGENCE_SERVER_URL);
