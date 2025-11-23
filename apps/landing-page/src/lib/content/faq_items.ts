export type FaqItem = {
	question: string;
	answer: string;
};

export const faq_items: FaqItem[] = [
	{
		question: 'Is Fictioneer really free?',
		answer:
			'Yes! Fictioneer is free to download and use for writing, projects, exports, and tracking. Advanced AI features require the AI Tools subscription, but the core app stays free without a trial or credit card.'
	},
	{
		question: 'What do I get with the AI Tools subscription?',
		answer:
			"The AI Tools subscription unlocks advanced AI features like story generation, character building, plot outlining, and unlimited AI-powered suggestions. These tools are designed to help you overcome writer's block and develop richer stories."
	},
	{
		question: 'Can I cancel anytime?',
		answer:
			"Absolutely. You can cancel your AI Tools subscription at any time. No questions asked. If you cancel, you'll continue to have access until the end of your billing period, and you can still use the free version of Fictioneer forever."
	},
	{
		question: 'What payment methods do you accept?',
		answer:
			'We accept all major credit cards (Visa, Mastercard, American Express) and other payment methods through our secure payment processor. All payments are encrypted and secure.'
	},
	{
		question: 'Do you offer refunds?',
		answer:
			"We offer a 30-day money-back guarantee. If you're not satisfied with the AI Tools subscription within the first 30 days, contact us for a full refund."
	}
];
