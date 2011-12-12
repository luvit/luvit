var HTTP = require("http");

HTTP.createServer(function (req, res) {
  var length = 0
  var total = 0
  req.on('data', function (chunk) {
    length++;
    total += Buffer.byteLength(chunk)
  });
  req.on('end', function () {
    var body = "length = " + total + "\n";
    res.writeHead(200, {
      "Content-Type": "text/plain",
//      "Content-Length": Buffer.byteLength(body)
    });
    res.end(body);
  });
    
}).listen(8080)

console.log("Server listening at http://localhost:8080/")

