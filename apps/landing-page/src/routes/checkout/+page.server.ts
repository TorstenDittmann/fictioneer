import { redirect } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = () => {
	redirect(302, 'https://checkout.dodopayments.com/buy/pdt_0NVC6brJNi5CilSO8gxAD?quantity=1');
};
