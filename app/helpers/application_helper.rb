module ApplicationHelper
def markdown(text)
  _text = text
  
  options = Hash[:hard_wrap,true, :autolink,true,:no_intraemphasis,true,:fenced_code,true,:gh_blockcode,true]
  Redcarpet::Markdown.new(Redcarpet::Render::HTML,options).render(_text).html_safe
  
end
def gravatar_url(email)
    digest = Digest::MD5.hexdigest(email)
    "http://gravatar.com/avatar/#{digest}.png?s=75"
end
end
