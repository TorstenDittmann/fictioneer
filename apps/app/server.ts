const serveStatic = async (path: string) => {
	try {
		return new Response(Bun.file(path));
	} catch {
		return null;
	}
};

Bun.serve({
	port: 3000,
	async fetch(req) {
		const url = new URL(req.url);
		const filePath = `./build${url.pathname}`;

		// If the path is a directory or doesn't exist, serve index.html (SPA fallback)
		let fileResponse = await serveStatic(filePath);
		if (!fileResponse || filePath.endsWith('/')) {
			fileResponse = await serveStatic('./build/index.html');
		}

		return (
			fileResponse ||
			new Response('Not found', {
				status: 404
			})
		);
	}
});

console.log('Server running at http://localhost:3000');
