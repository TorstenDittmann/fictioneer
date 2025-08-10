import { check } from '@tauri-apps/plugin-updater';
import { relaunch } from '@tauri-apps/plugin-process';

export interface UpdateState {
	is_checking: boolean;
	is_downloading: boolean;
	is_installing: boolean;
	update_available: boolean;
	update_version?: string;
	update_body?: string;
	download_progress: number;
	download_total: number;
	error?: string;
}

class UpdaterService {
	private _state = $state<UpdateState>({
		is_checking: false,
		is_downloading: false,
		is_installing: false,
		update_available: false,
		download_progress: 0,
		download_total: 0
	});

	private _check_interval: ReturnType<typeof setInterval> | null = null;

	get state(): UpdateState {
		return this._state;
	}

	start_auto_check(): void {
		// Check immediately
		this.check_for_updates();

		// Then check every 10 minutes
		this._check_interval = setInterval(
			() => {
				this.check_for_updates();
			},
			10 * 60 * 1000
		) as ReturnType<typeof setInterval>; // 10 minutes in milliseconds
	}

	stop_auto_check(): void {
		if (this._check_interval) {
			clearInterval(this._check_interval);
			this._check_interval = null;
		}
	}

	async check_for_updates(): Promise<boolean> {
		if (this._state.is_checking) {
			return false;
		}

		this._state.is_checking = true;
		this._state.error = undefined;

		try {
			const update = await check();

			if (update) {
				this._state.update_available = true;
				this._state.update_version = update.version;
				this._state.update_body = update.body;
				console.log(
					`Found update ${update.version} from ${update.date} with notes: ${update.body}`
				);
				return true;
			} else {
				this._state.update_available = false;
				return false;
			}
		} catch (error) {
			console.error('Failed to check for updates:', error);
			this._state.error = error instanceof Error ? error.message : 'Unknown error occurred';
			return false;
		} finally {
			this._state.is_checking = false;
		}
	}

	async download_and_install_update(): Promise<boolean> {
		if (!this._state.update_available || this._state.is_downloading) {
			return false;
		}

		this._state.is_downloading = true;
		this._state.error = undefined;
		this._state.download_progress = 0;
		this._state.download_total = 0;

		try {
			const update = await check();

			if (!update) {
				throw new Error('No update available');
			}

			await update.downloadAndInstall((event) => {
				switch (event.event) {
					case 'Started':
						this._state.download_total = event.data.contentLength ?? 0;
						console.log(`Started downloading ${event.data.contentLength ?? 0} bytes`);
						break;
					case 'Progress':
						this._state.download_progress += event.data.chunkLength;
						console.log(
							`Downloaded ${this._state.download_progress} from ${this._state.download_total}`
						);
						break;
					case 'Finished':
						console.log('Download finished');
						this._state.is_downloading = false;
						this._state.is_installing = true;
						break;
				}
			});

			console.log('Update installed successfully');

			// Relaunch the application
			await relaunch();

			return true;
		} catch (error) {
			console.error('Failed to download and install update:', error);
			this._state.error = error instanceof Error ? error.message : 'Unknown error occurred';
			return false;
		} finally {
			this._state.is_downloading = false;
			this._state.is_installing = false;
		}
	}

	get_download_percentage(): number {
		if (this._state.download_total === 0) {
			return 0;
		}
		return Math.round((this._state.download_progress / this._state.download_total) * 100);
	}

	reset_state(): void {
		this._state.update_available = false;
		this._state.update_version = undefined;
		this._state.update_body = undefined;
		this._state.download_progress = 0;
		this._state.download_total = 0;
		this._state.error = undefined;
	}

	destroy(): void {
		this.stop_auto_check();
	}
}

export const updater_service = new UpdaterService();
