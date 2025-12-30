import { redirect } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = () => {
	redirect(302, 'https://customer.dodopayments.com/login/bus_0NVC5X8uiM38cYaFFTcxA');
};
