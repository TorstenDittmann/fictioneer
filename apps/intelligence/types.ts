export interface GumroadPurchaseResponse {
	success: boolean;
	uses: number;
	purchase: GumroadPurchase;
}

export interface GumroadPurchase {
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
	card: GumroadCard;
	order_number: number;
	sale_id: string;
	sale_timestamp: string;
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
	created_at: string;
	custom_fields: unknown[];
	chargebacked: boolean;
	subscription_ended_at: string | null;
	subscription_cancelled_at: string | null;
	subscription_failed_at: string | null;
}

export interface GumroadCard {
	visual: string | null;
	type: string | null;
}

export interface ApiErrorResponse {
	error: string;
}

export interface HealthResponse {
	status: 'ok';
	timestamp: string;
	service?: string;
}
