class Project
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Document::Taggable
  
  field :description
  field :url
  field :name

  has_many :posts

  def self.find_new_projects(token)
    api = Octokit::Client.new(token) 
    repos = api.repositories
    urls = repos.map {|i| i["url"]}
    urls.reject Post.where(:url.in urls).all
  end
  def self.new_from_url(url,token)
    api = Octokit::Client.new(token)
    id = url.split("/").last
    info = api.repositories id
    Project.create(url: info['url'],name: info['name'],description: info['description'])
  end
end
  