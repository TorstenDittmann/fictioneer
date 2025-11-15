export type MicroLenisOptions = {
	lerp: number;
	smoothWheel: boolean;
	smoothTouch: boolean;
};

class MicroLenis {
	private target = 0;
	private current = 0;
	private raf_id: number | null = null;
	private touch_start = 0;
	private readonly options: MicroLenisOptions;
	private is_programmatic = false;

	constructor(options: MicroLenisOptions) {
		this.options = options;
		this.target = window.scrollY;
		this.current = window.scrollY;

		this.handleWheel = this.handleWheel.bind(this);
		this.handleTouchMove = this.handleTouchMove.bind(this);
		this.handleTouchStart = this.handleTouchStart.bind(this);
		this.handleNativeScroll = this.handleNativeScroll.bind(this);

		if (this.options.smoothWheel) {
			window.addEventListener('wheel', this.handleWheel, { passive: false });
		}

		if (this.options.smoothTouch) {
			window.addEventListener('touchstart', this.handleTouchStart, { passive: false });
			window.addEventListener('touchmove', this.handleTouchMove, { passive: false });
		}

		window.addEventListener('scroll', this.handleNativeScroll, { passive: true });
		this.startLoop();
	}

	destroy() {
		if (this.options.smoothWheel) {
			window.removeEventListener('wheel', this.handleWheel);
		}

		if (this.options.smoothTouch) {
			window.removeEventListener('touchstart', this.handleTouchStart);
			window.removeEventListener('touchmove', this.handleTouchMove);
		}

		window.removeEventListener('scroll', this.handleNativeScroll);

		if (this.raf_id) {
			cancelAnimationFrame(this.raf_id);
			this.raf_id = null;
		}
	}

	private startLoop() {
		if (this.raf_id !== null) return;
		this.raf_id = requestAnimationFrame(this.loop);
	}

	private loop = () => {
		const diff = this.target - this.current;
		if (Math.abs(diff) > 0.02) {
			this.current += diff * this.options.lerp;
		} else {
			this.current = this.target;
		}

		this.is_programmatic = true;
		window.scrollTo(0, this.current);
		this.is_programmatic = false;

		this.raf_id = requestAnimationFrame(this.loop);
	};

	private clampTarget() {
		const max = Math.max(document.documentElement.scrollHeight - window.innerHeight, 0);
		this.target = Math.min(Math.max(this.target, 0), max);
	}

	private handleWheel(event: WheelEvent) {
		event.preventDefault();
		this.target += event.deltaY;
		this.clampTarget();
	}

	private handleTouchStart(event: TouchEvent) {
		this.touch_start = event.touches[0]?.clientY ?? 0;
	}

	private handleTouchMove(event: TouchEvent) {
		event.preventDefault();
		const current = event.touches[0]?.clientY ?? 0;
		const delta = this.touch_start - current;
		this.touch_start = current;
		this.target += delta;
		this.clampTarget();
	}

	private handleNativeScroll() {
		if (this.is_programmatic) {
			return;
		}

		this.target = window.scrollY;
		this.current = window.scrollY;
	}
}

export function initialize_lenis(options: Partial<MicroLenisOptions> = {}) {
	if (typeof window === 'undefined') {
		return () => {};
	}

	const controller = new MicroLenis({
		lerp: options.lerp ?? 0.1,
		smoothWheel: options.smoothWheel ?? true,
		smoothTouch: options.smoothTouch ?? true
	});

	return () => controller.destroy();
}
