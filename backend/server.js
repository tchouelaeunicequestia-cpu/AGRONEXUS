const http = require('http');

const server = http.createServer((req, res) => {
  res.writeHead(200, {'Content-Type': 'text/plain'});
  res.end('AgroNexus backend running');
});

server.listen(3000, () => {
  console.log('AgroNexus backend running on http://localhost:3000');
});
