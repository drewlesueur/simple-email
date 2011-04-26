net = require "net"
util = require "util"
events = require "events"
Server = net.Server
Socket = net.Socket
MailParser = require("mailparser").MailParser
_ = require("underscore")
require("drews-mixins") _

class EmailMessage extends events.EventEmitter
  constructor: (socket) ->
    @socket = socket

ip = ""
name = ""
eol = "\r\n"
commands  =
  'OPEN' : '220 ' + ip + ' ESMTP ' + name,  
  'EHLO' : [
    '250-' + ip + ' OH HAI <var>'
    '250-SIZE 35651584'
    '250-PIPELINING'
    '250-ENHANCEDSTATUSCODES'
    '250 8BITMIME'
  ].join( eol )
  'HELO' : '250 OH HAI <var>'
  'MAIL' : '250 Ok'
  'RCPT' : '250 Ok'
  'DATA' : '354 End data with <CR><LF>.<CR><LF>'
  '.'    : '250 OK id=1778te-0009TT-00'
  'QUIT' : '221 Peace Out'

     
sendResponse = (socket, command, arg) ->
  response = commands[ command ];
  if arg
    response = response.replace '<var>', arg
  console.log 'S: ' + response
  socket.write response + eol


class EmailServer extends events.EventEmitter
  constructor: (args...) ->
    if args[0] instanceof Server
      @server = args[0]
    else
      @server = new Server args...
    @server.on 'connection', @handleConnection
  listen: (args...) => 
    @server.listen args...
  handleConnection: (socket) ->
    email = ""
    timeout = null
    emailMessage = new EmailMessage socket
    # Set encoding
    socket.setEncoding( 'utf8' );

    # New Connections
    socket.on 'connect', () ->
      console.log 'Incoming email!\n'
      sendResponse socket, 'OPEN'

    socket.on 'data', (data) ->
      if socket.state == "data"
        if data.substr(-5) == "\r\n.\r\n"
          email += data.substring 0, data.length - 5
          sendResponse socket, '.'
          emailMessage.emit "close"
          console.log email
        else
          email += data
          emailMessage.emit "data", data
      else
        parts   = data.split(/\s|\\r|\\n/)
        command = parts[0]

        console.log('C: ' + parts.join(' ').trim())

        # Check for a command
        if commands[command]
          sendResponse socket, command, parts[1]

          if command == "DATA" then socket.state = "data"
    #Finished
    socket.on 'close', () ->
      clearTimeout timeout
      console.log "the email was" + email

emailer = new EmailServer
emailer.listen 25
      
