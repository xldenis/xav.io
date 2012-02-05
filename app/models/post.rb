class Post
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Document::Taggable
  field :title
  field :content
  default_scope :order => :created_at.desc
  validates_presence_of :title,:content

end
