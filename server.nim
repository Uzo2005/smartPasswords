import asynchttpserver, asyncdispatch, json, strutils, sequtils, sets, strutils, sequtils, random, sugar
import ./passwordGenerator

let server = newAsyncHttpServer()

when defined(release):
  let port = Port(80)
else:
  let port = Port(2005)

server.listen(port)

echo "Server started on port ", $port.uint16

proc requestCallBack(req: Request) {.async, gcsafe.} =
  let
    txtHeaders = {"Content-type": "text/plain"}
    pngHeaders = {"Content-type": "image/png"}
    jsHeaders = {"Content-type": "text/javascript"}
    svgHeaders = {"Content-type": "image/svg+xml"}
    jsonHeaders = {"Content-type": "application/json"}

  case req.url.path
  of "/":
    let
      indexPage = readfile("index.html")
      htmlHeaders = {"Content-type": "text/html; charset=utf-8"}

    await req.respond(Http200, indexPage, htmlHeaders.newHttpHeaders())
  of "/client.js":
    let clientJs = readfile("client.js")

    await req.respond(Http200, clientJs, jsHeaders.newHttpHeaders())
  of "/styles.css":
    let
      styleCss = readfile("styles.css")
      cssHeaders = {"Content-type": "text/css"}

    await req.respond(Http200, styleCss, cssHeaders.newHttpHeaders())
  of "/generatePassword":
    if req.reqMethod == HttpPost:
      let 
        data = parseJson req.body
        passwordLengthJson = data["passwordLength"]
        exclusionJsonRules = data["exclusionRule"]
        inclusionJsonRules = data["inclusionRule"]
      
      var
        passwordLength = parseInt(($passwordLengthJson)[1..^2])
        exclusionRules, inclusionRules: seq[Rule]

      for exclusion in exclusionJsonRules:
        exclusionRules.add(excludeRule($exclusion))

      for inclusion in inclusionJsonRules:
        inclusionRules.add(includeRule($inclusion))

      let password =  generatePassword(passwordLength, inclusionRules.concat(exclusionRules))
      await req.respond(Http200, password, txtHeaders.newHttpHeaders())
    else:
      await req.respond(Http200, "Sup Bro", txtHeaders.newHttpHeaders())


while true:
  if server.shouldAcceptRequest:
    waitFor server.acceptRequest(requestCallBack)
  else:
    waitFor sleepAsync(500)
