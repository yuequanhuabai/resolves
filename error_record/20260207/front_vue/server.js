// 裸 TCP 服务器：不用 http 模块，亲眼看 HTTP 到底是什么。
// 运行：node server.js  →  然后用浏览器 / fetch / curl 打 http://localhost:4000
const net = require('net')

let seq = 0

const server = net.createServer((socket) => {
  socket.on('data', (chunk) => {
    seq++
    // chunk 就是对方（浏览器/curl）通过 TCP 发来的原始字节，原样打印
    console.log(`\n========== 收到第 ${seq} 段原始字节（${chunk.length} bytes）==========`)
    console.log(chunk.toString('utf8'))
    console.log('========== 原始字节结束 ==========')

    // HTTP 响应也只是一段手写的纯文本：状态行 + 头部 + 空行 + 体。
    // 头和体之间必须是 \r\n\r\n（HTTP 规定用 CRLF 换行），这就是全部规矩。
    const body = JSON.stringify({ code: 200, msg: 'ok', data: `你是第 ${seq} 个请求` })
    const bodyBytes = Buffer.byteLength(body)
    const response =
      'HTTP/1.1 200 OK\r\n' +
      'Content-Type: application/json; charset=utf-8\r\n' +
      `Content-Length: ${bodyBytes}\r\n` +
      // 下面两行是 CORS 放行头，允许你从 Vite 页面(5173)的控制台 fetch 过来
      'Access-Control-Allow-Origin: *\r\n' +
      'Access-Control-Allow-Headers: *\r\n' +
      'Connection: close\r\n' +
      '\r\n' +
      body

    socket.write(response)
    socket.end()
  })
})

server.listen(4000, () => {
  console.log('裸 TCP 服务器已启动: http://localhost:4000')
  console.log('它不认识 HTTP，只会把收到的字节打出来，再回一段手写文本。\n')
})
