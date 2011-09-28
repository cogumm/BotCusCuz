#encoding: utf-8
require File.expand_path( File.dirname(__FILE__) + '/config/config' )

# => Iniciando o código do bot
class Seen < Struct.new(:who, :where, :what, :time)
  def to_s
    "[#{time.asctime}] #{who} foi visto em #{where} falando: #{what}"
  end
end

bot = Cinch::Bot.new do
  configure do |c|
    c.server    = SERVER
    c.port      = PORT
    c.channels  = CHANNELS
    c.nick      = NICK
    c.password  = SECRET
    c.realname  = REALNAME
    c.secure    = true
    c.verbose   = true
    
    @autovoice  = false
    @autoop     = false
    @admin      = "CoGUMm"
    @users      = {}
  end

  helpers do
    def is_admin?(user)
      true if user.nick == @admin
    end
    # Pega o primeiro resultado retornado pelo Google
    # caso contrário "Resultado não encontrado!!" 
    def google(query)
      url = "http://www.google.com/search?q=#{CGI.escape(query)}"
      res = Nokogiri::HTML(open(url)).at("h3.r")

      title = res.text
      link = res.at('a')[:href]
      desc = res.at("./following::div").children.first.text
    rescue
      "Resultado não encontrado!!"
    else
#      m.reply "Primeiro resultado retornado pelo Google:"
      CGI.unescape_html "#{title} - #{desc} (#{link})"
    end

    # API URELE
    def shorten(url)
      url = open("http://urele.com/api/create_url?url=#{URI.escape(url)}").read
      url == "Error" ? nil : url
    rescue OpenURI::HTTPError
      nil
    end
  end
  
  on :join do |m|
    m.reply "Seja bem vindo ao #{m.channel} #{m.user.nick}! Para qualquer ajuda digite HELP ou AJUDA." unless m.user.nick == bot.nick
  end

  # Envia mensagem em PVT
  on :message, /^.privado (.+?) (.+)/ do |m, who, text|
    User(who).send text
  end


#  on :message, /ola|olá|OLA|OLÁ|Olá|Ola|\. BotCusCuz/ do |m|
#    m.reply "Olá, #{m.user.nick}!"
#  end

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
#      m.reply @users[nick].to_s
      m.reply "Olá #{m.user.nick}!"
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
#  on :connect do
#    bot.join "#ZouGames"
#  end

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
  on :channel, /^.link/ do |m|
    urls = URI.extract(m.message, "http")

      unless urls.empty?
      short_urls = urls.map {|url| shorten(url) }.compact

      unless short_urls.empty?
        m.reply short_urls.join("Sua URL: ")
      end
    end
  end
  # Fim encurtador

  # Pesquisa Google
  on :message, /^.google (.+)/ do |m, query|
    m.reply google(query)
  end

  on :channel do |m|
    urls = URI.extract(m.message, "http")

    unless urls.empty?
      short_urls = urls.map {|url| shorten(url) }.compact

      unless short_urls.empty?
        m.reply short_urls.join(", ")
      end
    end
  end
  # Fim da Pesquisa Google

  # Help
  on :message, /^.help|.h|.HELP|.AJUDA|.ajuda/ do |m|
    m.reply "BotCusCuz Bot"
    m.reply "Para encurtar uma URL longa basta utilizar o comando:"
    m.reply ".link <SUA URL>"
    m.reply " "
    m.reply "Quer utilizar o google de forma bem rápida?"
    m.reply ".google <SUA PESQUISA>"
    m.reply " "
    m.reply "Enviar uma mensagem privada para alguêm:"
    m.reply ".privado <NICK> <SUA MENSAGEM>"
    m.reply " "
#    m.reply "Digite .nick <NICK> e veja o resultado! =D"
#    m.reply " "
#    m.reply "Visite www.ZouGames.org"
    m.reply "Quer dar uma melhorada em mim? Veja o meu repositório!!"
    m.reply ".repo"
    m.reply " "
    m.reply "Bot desenvolvido por CoGUMm utilizando Cinch + Sinatra"
  end

  on :message, /^.repo/ do |m|
    REPO = "#{m.user.nick}, caso queira ajudar, esse é o meu repositório! https://cogumm@github.com/cogumm/BotCusCuz.git"
    m.reply REPO
  end

#  on :channel, /^.list (.+)/ do |users, channel|
#    channel.users
#  end


end
bot.start
