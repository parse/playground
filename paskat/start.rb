/*
Test */
require("IrcBot")
thebot = IrcBot.new("irc.freenode.net", 6667)
thebot.login("paskat", "#it-uppsala", "")
thebot.setAdmins
thebot.run
