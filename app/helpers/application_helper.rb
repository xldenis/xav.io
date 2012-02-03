module ApplicationHelper
def markdown(text)
  options = [:hard_wrap, :autolink,:no_intraemphasis,:fenced_code,:gh_blockcode]
  Redcarpet::Markdown.new(Redcarpet::Render::HTML,:autolink => true, :space_after_headers => true)
end
end
