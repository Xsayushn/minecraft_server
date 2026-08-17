const http = require('http');

const PORT = process.env.PORT || 10000;

const server = http.createServer((req, res) => {
  const uptime = Math.floor(process.uptime());
  const memUsage = process.memoryUsage();
  
  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({
    status: 'ONLINE',
    service: 'Minecraft 24/7 Server on Render',
    uptimeSeconds: uptime,
    memoryUsageMB: {
      rss: Math.round(memUsage.rss / 1024 / 1024),
      heapTotal: Math.round(memUsage.heapTotal / 1024 / 1024),
      heapUsed: Math.round(memUsage.heapUsed / 1024 / 1024)
    },
    message: 'Ping this endpoint via UptimeRobot or Cron-Job.org every 5-10 minutes to prevent Render from sleeping.'
  }, null, 2));
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`[Keep-Alive] HTTP Status Server listening on port ${PORT}`);
});
