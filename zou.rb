#encoding: utf-8

require 'rubygems'
require "sinatra"
require "cinch"
require "open-uri"

set :cache, Dalli::Client.new

# => Iniciando o código do bot

#http://www.advogados.com.br/canal_sjc/comandos_de_irc.htm
#http://fit.faccat.br/~jackson/comandos.html

#/kick #canal nick mensagem
#/invite nick #canal


class Seen < Struct.new(:who, :where, :what, :time)
  def to_s
    "[#{time.asctime}] #{who} foi visto em #{where} falando: #{what}"
  end
end

bot = Cinch::Bot.new do
  configure do |c|
    c.server    = "irc.freenode.org"
    c.realname  = "BotCusCuz o seu Bot do dia-a-dia!"
    c.channels  = ["#ZouGames"]
    c.nick      = "ZouGames"
    #c.password  = "comando"
    c.secure    = true
    c.verbose   = true
    
    @autovoice  = false
    @autoop     = false
    @admin      = "CoGUMm"
    @users      = {}
  end
  
  on :join do |m|
    m.reply "Seja bem vindo #{m.user.nick}, ao #{m.channel}!" unless m.user.nick == bot.nick
  end

  helpers do
    def is_admin?(user)
      true if user.nick == @admin
    end
  end

  # Envia mensagem em PVT
  on :message, /^.privado (.+?) (.+)/ do |m, who, text|
    User(who).send text
  end


  on :message, "ola ZouGames" do |m|
    m.reply "Olá, #{m.user.nick}!"
  end

  # Only log channel messages
#  on :channel do |m|
 #   @users[m.user.nick] = Nick.new(m.user.nick, m.channel, m.message, Time.new)
#  end

  on :channel, /^.nick (.+)/ do |m, nick|
    if nick == bot.nick
      m.reply "Esse sou eu! =D"
    elsif nick == m.user.nick
      m.reply "Esse é você, #{nick}! o.O'"
    elsif @users.key?(nick)
      m.reply @users[nick].to_s
    else
      m.reply "Eu não sei quem é esse tal de #{nick}!! =("
    end
  end

  # AutoOP e AutoVoice
  on :join do |m|
    unless m.user.nick == bot.nick
      m.channel.voice(m.user) if @autovoice
      m.channel.op(m.user) if @autoop
    end
  end

  on :channel, /^.voice (on|off)/ do |m, option|
    if is_admin?(m.user)
      @autovoice = option == "on"
      m.reply "Auto voice agora está #{@autovoice ? 'ativado.' : 'desativado.'}"
    end
  end

  on :channel, /^.op (on|off)/ do |m, option|
    if is_admin?(m.user)
      @autoop = option == "on"
      m.reply "Auto op agora está #{@autoop ? 'ativado.' : 'desativado.'}"
    end
  end
  # Fim autoOp e autoVoice
  
  # Dá op e voice e tira de um <nick>
  on :message, /.op (.+)/ do |m|
    unless m.user.nick == bot.nick
      m.channel.op(m.user) if is_admin?(m.user)
    end
  end

  on :message, /.deop (.+)/ do |m|
    unless m.user.nick == bot.nick
      m.channel.deop(m.user) if is_admin?(m.user)
    end
  end
  
  on :message, /.voice (.+)/ do |m|
    unless m.user.nick == bot.nick
      m.channel.voice(m.user) if is_admin?(m.user)
    end
  end
  
  on :message, /.devoice (.+)/ do |m|
    unless m.user.nick == bot.nick
      m.channel.devoice(m.user) if is_admin?(m.user)
    end
  end
  # Dá op e tira de um <nick>  

  # Entra e sai de um canal
  on :connect do
    bot.join "#ZouGames"
  end

  on :message, /^.entra (.+)/ do |m, channel|
    bot.join(channel) if is_admin?(m.user)
  end

  on :message, /^.sai(?: (.+))?/ do |m, channel|
    # Part current channel if none is given
    channel = channel || m.channel

    if channel
      bot.part(channel) if is_admin?(m.user)
    end
  end
  # Fim entra e sai de um canal

  # Encurtar links
  # API URELE
  helpers do
    def shorten(url)
      url = open("http://urele.com/api/create_url?url=#{URI.escape(url)}").read
      url == "Error" ? nil : url
    rescue OpenURI::HTTPError
      nil
    end
  end

  on :channel, /^.link/ do |m|
#  on :channel do |m|
    urls = URI.extract(m.message, "http")

    unless urls.empty?
      short_urls = urls.map {|url| shorten(url) }.compact

      unless short_urls.empty?
        m.reply short_urls.join("Sua url #{m.user.nick}: ")
      end
    end
  end
  # Fim encurtador





end

bot.start
