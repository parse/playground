/*
This is a change
*/
require("socket")
class IrcBot
  attr_accessor :name, :ch, :ch_pw, :admins
  
  # load admins from <channel>.txt
  def setAdmins
    if(File::exist?("#{@ch}.txt"))
      fh = File::open("#{@ch}.txt", "r")
      @admins = fh.readlines
      
    else
      fh = File::open("#{@ch}.txt", "w")
      @admins = []
    end
    fh.close
    @admins.each { |a| a.chop! }
  end
  
  # update <channel>.txt with new admin and reread the whole file
  def updateAdmins(usr)
    fh = File::open("#{@ch}.txt", "a")
    fh.puts("#{usr}\n")
    fh.close
    setAdmins()
  end
  
  # initializes class
  def initialize(server, port)
    print("IRCbot started(#{server}:#{port})\n")
    @IRCsocket = TCPSocket::new(server, port)
  end
  
  
  # logs in to server and channel
  def login(name, channel, password)
    @name = name
    @ch = channel
    @ch_pw = password
    @IRCsocket.write("PASS *\n")
    @IRCsocket.write("NICK #{@name}\n")
    @IRCsocket.write("USER #{@name} 8 * :#{@name}\n")
    @IRCsocket.write("JOIN #{@ch} #{@ch_pw}\n")
  end
  
  # main bot loop
  def run
    while !@IRCsocket.closed?
      data = @IRCsocket.readline.split(" ")
      print(data.join(" ") + "\n")
      if(data[0] == "PING")
        answerPing(data[1])
        
      # JOIN's & PART's
      elsif(data.size <= 3)
        data = joinData(data)
        case data["type"]
        when "JOIN" then
          if(@admins.include?(data["rusr"]) && isNickAuthed(data["rusr"]))
            giveOp(data["rusr"])
          end
        end
      else
        
        # PRIVMSG's to bot
        data = msgData(data)
        if(data["type"] == "PRIVMSG" && data["who"] == @name)
          case data["event"]
          when "!write" then write(data["args"]) # ja alla kan OP'a sig själva men ingen vet hur
          when "!deop" then takeOp(data["rusr"])
          when "!op" then
            if(@admins.include?(data["rusr"]) && isNickAuthed(data["rusr"]))
              giveOp(data["rusr"])
            end
          # when "!rename" then changeNick(data["args"])
          when "!admins" then 
            if(!@admins.empty?) 
              notice(data["rusr"], "Admins: #{@admins.join(", ")}")
            else
              notice(data["rusr"], "Inga admins registrerade")
            end
          when "!help" then notice(data["rusr"], "!autoop (1. regga dig hos NickServ; 2. var OP 3. /msg #{@name} !autoop), !admins, !op, !deop")
          when "!autoop" then
            if(hasOp(data["rusr"]) && isNickAuthed(data["rusr"]))
              unless(@admins.include?(data["rusr"]))
                updateAdmins(data["rusr"])
                notice(data["rusr"], "Du har nu autoop")
              else
                notice(data["rusr"], "Du har redan autoop")
              end
            end
          end
          
        # MSG's to channel
        elsif(data["type"] == "PRIVMSG" && data["who"] == @ch)
          case data["event"]
          when "!do" then
            unless(data["args"].empty?)
              doAction(data["args"])
            end
          when /http:\/\/([a-z]+\.)?youtube.com\/watch\?v=([\w+]+)/i then
            msg(data["who"], getTitleFromUrl(data["event"]))
	  when /http:\/\/([a-z]+\.)?imdb.com\/title\/([\w+]+)/i then
            msg(data["who"], getTitleFromUrl(data["event"]))
	  when /http:\/\/([a-z]+\.)?aftonbladet.se\/([\w+]+)/i then
            msg(data["who"], getTitleFromUrl(data["event"]))
	  when /http:\/\/([a-z]+\.)?idg.se\/([\w+]+)/i then
            msg(data["who"], getTitleFromUrl(data["event"]))          
	  end
	end
      end
      
    end # end of while
  end

  # checks with nickserv if nick is online and authed PRIVMSG nickserv ACC <nickname>
  def isNickAuthed(usr)
    msg("NickServ", "ACC #{usr}")
    data = nickservData(@IRCsocket.readline.split(" "))
    if(data["rusr"] == "NickServ" && data["to"] == @name && data["usr"] == usr && data["status"] == "3")
      return true
    else
      return false
    end
  end
  
  # turns messageinfo into a format easier to handle
  def msgData(arr)
    return data = {"rusr" => arr[0][1..-1].split("!")[0], "raddress" => arr[0].split("!")[1], "type" => arr[1], "who" => arr[2], "event" => arr[3][1..-1], "args" => arr[4..-1].join(" ")}
  end

  # turns NickServ's answer into better format
  def nickservData(arr)
    return data = {"rusr" => arr[0][1..-1].split("!")[0], "raddress" => arr[0].split("!")[1], "to" => arr[2], "usr" => arr[3][1..-1], "status" => arr[5]}
  end
  
  # turns statusinfo into a format easier to handle
  def joinData(arr)
    return data = {"rusr" => arr[0][1..-1].split("!")[0], "raddress" => arr[0].split("!")[1], "type" => arr[1], "where" => arr[2][1..-1]}
  end
  
  def namesData(arr)
    arr[5] = arr[5][1..-1]
    return data = {"raddress" => arr[0][1..-1], "to" => arr[2], "names" => arr[5..-1]}
  end
  
  # true if user has OP
  def hasOp(usr)
    @IRCsocket.write("NAMES #{@ch}\n")
    data = namesData(@IRCsocket.readline.split(" "))
    @IRCsocket.readline # for the second worthless line of answer to the NAMES request
    if(data["to"] == @name && data["names"].include?("@#{usr}"))
      return true
    else
      false
    end
  end
  
  # deOP's user
  def takeOp(usr)
    @IRCsocket.write("MODE #{@ch} -op #{usr}\n")
  end
  
  # performs an action! ie /me smeker luder med en fiskpinne
  def doAction(action)
    @IRCsocket.write("PRIVMSG #{@ch} :\001ACTION #{action} \001\n")
  end
  
  # gives OP to user
  def giveOp(usr)
    @IRCsocket.write("MODE #{@ch} +op #{usr}\n")
  end
  
  # sends a message
  def msg(usr, message)
    @IRCsocket.write("PRIVMSG #{usr} :#{message}\n")
  end

  # sends a notice
  def notice(usr, message)
    @IRCsocket.write("NOTICE  #{usr} :#{message}\n")
  end
  
  # quits server
  def quit
    @IRCsocket.write("QUIT\n")
    @IRCsocket.close
  end
  
  # answers ping
  def answerPing(url)
    @IRCsocket.write("PONG #{url}\n")
  end
  
  # writes raw IRC to server
  def write(whatever)
    @IRCsocket.write("#{whatever}\n")
  end
  
    # moves the bot to another channel
  def changeChannel(channel, password)
    @IRCsocket.write("PART #{@ch}\n")
    @ch = channel
    @ch_pw = password
    @IRCsocket.write("JOIN #{@ch} #{@ch_pw}\n")
  end
  
  # renames bot
  def changeNick(name)
    @name = name
    @IRCsocket.write("NICK #{@name}\n")
  end
  
  # get <title> from url
  def getTitleFromUrl(url)
    require 'net/http'
    puts url
    res = Net::HTTP.get_response(URI.parse(url))
    contents = res.body
    /<title>(.*?)<\/title>/i.match(contents);
    sTitle = $1
    return sTitle
  end
end
