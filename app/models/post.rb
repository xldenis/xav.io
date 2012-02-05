class Post
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Document::Taggable
  field :title
  field :content
  validates_presence_of :title,:content

end
