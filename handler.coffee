emailServer = new EmailServer()

emailServer.on "email", (emailMessage) ->
  mailParser = new MailParser()
  emailMessage.on "data", (data) ->
    mailParser.feed(data)
  emailMessage.on "close", () ->
    mailParser.end() 

emailServer.listen(25)
