#encoding: utf-8
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
#   m.reply "Primeiro resultado retornado pelo Google:"
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
