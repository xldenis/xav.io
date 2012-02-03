class PostsController < ApplicationController
  respond_to :html
  def index
    @posts = Post.all
  	respond_with @posts
  end
  def show
    @post = Post.find(params[:id])
  	respond_with @post
  end
  def new
    @post = Post.new
    respond_with @post
  end
  def create
    @post = Post.new(params[:post])
    @post.save
    respond_with @post
  end
  def edit
    @post = Post.find(params[:id])
    respond_with @post
  end
  def update
    @post = Post.find(params[:id])
    @post.update_attributes(params[:post])
    respond_with @post
  end
  def destroy
  	@post = Post.find(params[:id])
  	@post.destroy
  	respond_with @post
  end
  def tag
    @posts = Post.tagged_with(params[:tag])
    respond_with @posts
  end
end