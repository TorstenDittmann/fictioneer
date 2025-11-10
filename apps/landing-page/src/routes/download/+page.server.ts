import type { PageServerLoad } from './$types';

type Platform = {
	signature: string;
	url: string;
};

type ReleaseData = {
	version: string;
	notes: string;
	pub_date: string;
	platforms: Record<string, Platform>;
};

export type DownloadOption = {
	platform: 'windows' | 'mac' | 'linux';
	name: string;
	description: string;
	versions: {
		arch: string;
		url: string;
	}[];
};

type DetectedPlatform = 'windows' | 'mac' | 'linux' | null;

function detect_platform_from_user_agent(user_agent: string): DetectedPlatform {
	const ua_lower = user_agent.toLowerCase();

	if (ua_lower.includes('mac') || ua_lower.includes('darwin')) {
		return 'mac';
	}
	if (ua_lower.includes('win')) {
		return 'windows';
	}
	if (ua_lower.includes('linux') || ua_lower.includes('x11')) {
		return 'linux';
	}

	return null;
}

export const load: PageServerLoad = async ({ fetch, request }) => {
	try {
		const response = await fetch(
			'https://github.com/TorstenDittmann/fictioneer/releases/latest/download/latest.json'
		);

		if (!response.ok) {
			throw new Error(`Failed to fetch release data: ${response.statusText}`);
		}

		const release_data: ReleaseData = await response.json();

		// Map platform keys to download options
		const download_options: DownloadOption[] = [
			{
				platform: 'mac',
				name: 'macOS',
				description: `Version ${release_data.version}`,
				versions: [
					{
						arch: 'Apple Silicon (M1/M2/M3)',
						url: release_data.platforms['darwin-aarch64']?.url || '#'
					},
					{
						arch: 'Intel',
						url: release_data.platforms['darwin-x86_64']?.url || '#'
					}
				]
			},
			{
				platform: 'windows',
				name: 'Windows',
				description: `Version ${release_data.version}`,
				versions: [
					{
						arch: 'Installer (MSI)',
						url: release_data.platforms['windows-x86_64-msi']?.url || '#'
					},
					{
						arch: 'Setup (NSIS)',
						url: release_data.platforms['windows-x86_64-nsis']?.url || '#'
					}
				]
			},
			{
				platform: 'linux',
				name: 'Linux',
				description: `Version ${release_data.version}`,
				versions: [
					{
						arch: 'AppImage (x64)',
						url: release_data.platforms['linux-x86_64-appimage']?.url || '#'
					},
					{
						arch: 'Debian/Ubuntu (.deb)',
						url: release_data.platforms['linux-x86_64-deb']?.url || '#'
					},
					{
						arch: 'Red Hat/Fedora (.rpm)',
						url: release_data.platforms['linux-x86_64-rpm']?.url || '#'
					}
				]
			}
		];

		const user_agent = request.headers.get('user-agent') || '';
		const detected_platform = detect_platform_from_user_agent(user_agent);

		return {
			download_options,
			version: release_data.version,
			release_notes: release_data.notes,
			pub_date: release_data.pub_date,
			detected_platform
		};
	} catch (error) {
		console.error('Error fetching release data:', error);

		// Return fallback data if GitHub API fails
		const user_agent = request.headers.get('user-agent') || '';
		const detected_platform = detect_platform_from_user_agent(user_agent);

		return {
			download_options: [
				{
					platform: 'mac' as const,
					name: 'macOS',
					description: 'For macOS 11.0 and later',
					versions: [
						{
							arch: 'Apple Silicon (M1/M2/M3)',
							url: '#'
						},
						{
							arch: 'Intel',
							url: '#'
						}
					]
				},
				{
					platform: 'windows' as const,
					name: 'Windows',
					description: 'For Windows 10 and later',
					versions: [
						{
							arch: 'Installer (MSI)',
							url: '#'
						},
						{
							arch: 'Setup (NSIS)',
							url: '#'
						}
					]
				},
				{
					platform: 'linux' as const,
					name: 'Linux',
					description: 'For most modern distributions',
					versions: [
						{
							arch: 'AppImage (x64)',
							url: '#'
						},
						{
							arch: 'Debian/Ubuntu (.deb)',
							url: '#'
						},
						{
							arch: 'Red Hat/Fedora (.rpm)',
							url: '#'
						}
					]
				}
			],
			version: null,
			release_notes: null,
			pub_date: null,
			detected_platform
		};
	}
};
