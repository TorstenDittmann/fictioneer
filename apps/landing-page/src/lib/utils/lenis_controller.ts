export type LenisControllerOptions = {
	/**
	 * Lerp factor used when easing between the current and target scroll positions.
	 * Values closer to 0 slow the easing, higher values snap to the target faster.
	 */
	lerp?: number;
};

/**
 * Minimal Lenis-inspired scroll controller that exposes a smoothed scroll position.
 * It never mutates the actual scrollTop, which keeps accessibility features intact,
 * but still gives us silky scroll values for parallax driven motion.
 */
export class LenisController {
	private frame = 0;
	private target = 0;
	private current = 0;
	private readonly ease: number;
	private readonly subscribers = new Set<(value: number) => void>();

	constructor(options: LenisControllerOptions = {}) {
		this.ease = this.clamp(options.lerp ?? 0.085, 0.01, 1);
		this.target = window.scrollY;
		this.current = window.scrollY;

		this.handleScroll = this.handleScroll.bind(this);
		this.handleResize = this.handleResize.bind(this);

		window.addEventListener('scroll', this.handleScroll, { passive: true });
		window.addEventListener('resize', this.handleResize);

		this.frame = requestAnimationFrame(this.loop);
	}

	subscribe(callback: (value: number) => void) {
		this.subscribers.add(callback);
		callback(this.current);
		return () => this.subscribers.delete(callback);
	}

	destroy() {
		cancelAnimationFrame(this.frame);
		window.removeEventListener('scroll', this.handleScroll);
		window.removeEventListener('resize', this.handleResize);
		this.subscribers.clear();
	}

	private handleScroll() {
		this.target = window.scrollY;
	}

	private handleResize() {
		const maxScroll = document.body.scrollHeight - window.innerHeight;
		this.target = this.clamp(this.target, 0, Math.max(0, maxScroll));
	}

	private loop = () => {
		this.current += (this.target - this.current) * this.ease;
		this.subscribers.forEach((callback) => callback(this.current));
		this.frame = requestAnimationFrame(this.loop);
	};

	private clamp(value: number, min: number, max: number) {
		return Math.min(Math.max(value, min), max);
	}
}
