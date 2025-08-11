export type GumroadPurchaseResponse = {
	success: boolean;
	uses: number;
	purchase: {
		seller_id: string;
		product_id: string;
		product_name: string;
		permalink: string;
		product_permalink: string;
		email: string;
		price: number;
		gumroad_fee: number;
		currency: string;
		quantity: number;
		discover_fee_charged: boolean;
		can_contact: boolean;
		referrer: string;
		card: {
			visual: string | null;
			type: string | null;
		};
		order_number: number;
		sale_id: string;
		sale_timestamp: string; // ISO date string
		purchaser_id: string;
		subscription_id: string;
		variants: string;
		license_key: string;
		is_multiseat_license: boolean;
		ip_country: string;
		recurrence: string;
		is_gift_receiver_purchase: boolean;
		refunded: boolean;
		disputed: boolean;
		dispute_won: boolean;
		id: string;
		created_at: string; // ISO date string
		custom_fields: any[]; // Could be typed more strictly if structure is known
		chargebacked: boolean;
		subscription_ended_at: string | null;
		subscription_cancelled_at: string | null;
		subscription_failed_at: string | null;
	};
};
