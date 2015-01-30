require 'sinatra'
require 'sinatra/activerecord'
require 'twitter'
require 'omniauth-twitter'
require 'json'


configure do
  enable :sessions
end

configure :development do
  ActiveRecord::Base.establish_connection(
    :adapter  => 'postgresql',
    :database => 'fave_tweets_ar',
    :encoding => 'unicode'
  )
end

configure :production do
 db = URI.parse(ENV['DATABASE_URL'] || 'postgres:///localhost/mydb')

 ActiveRecord::Base.establish_connection(
   :adapter  => db.scheme == 'postgres' ? 'postgresql' : db.scheme,
   :host     => db.host,
   :username => db.user,
   :password => db.password,
   :database => db.path[1..-1],
   :encoding => 'utf8'
 )
end

helpers do
  def current_user?
    session[:uid]
  end

  def find_or_create_by_uid
    User.find{|f| f["uid"] == session[:uid]} || User.create(uid: session[:uid])
  end

end

use OmniAuth::Builder do
  provider :twitter, ENV['CONSUMER_KEY'], ENV['CONSUMER_SECRET']
end

CLIENT = Twitter::REST::Client.new do |config|
  config.consumer_key        = ENV['CONSUMER_KEY']
  config.consumer_secret     = ENV['CONSUMER_SECRET']
end

class User < ActiveRecord::Base
  validates_presence_of :uid
  validates_uniqueness_of :uid

  has_many :tags
  has_many :tweets

  attr_accessor :tag_list 

  def fetch_tweets
    if self.tweets.count == 0
      all_tweets
    else
      recent_tweets
    end
  end

  def all_tweets
    initial_count = self.tweets.count
    smallest_id = self.tweets.minimum(:uid)
    params = {count: 200}
    params[:max_id] = smallest_id - 1 if smallest_id
    tweet_params(params)
    return if initial_count == self.tweets.count
    all_tweets 
  end

  def recent_tweets
    smallest_id = self.tweets.minimum(:uid)
    tweet_params({:count => 200, :max_id => (smallest_id - 1)})  
    tweet_params({:count => 200, :since_id => self.tweets.maximum(:uid)})
  end  

  def tag_list
    tags.map(&:name).join(", ")
  end

  def tag_list=(names)
    self.tags = names.split(",").map do |n|
      Tag.find_or_create_by(:name => n.strip, :user_id => self.id)
    end
  end

  def tweet_params(query_options)
    CLIENT.favorites(self.uid,query_options).each do |tweet|
      self.tweets.push(Tweet.create_with(:text => tweet.text, :username => tweet.user.name, :screenname => tweet.user.screen_name, :created_at => tweet.created_at, :user_id => self.id, :uid_string => tweet.id.to_s).find_or_create_by(:uid => tweet.id))
    end
  end 
end

class Tag < ActiveRecord::Base
  belongs_to :user
  has_and_belongs_to_many :tweets
  before_save :to_slug

  def to_slug
    self.slug = name.downcase.gsub(/\W/,'-').squeeze('-').chomp('-') 
  end
end

class Tweet < ActiveRecord::Base
  belongs_to :user
  has_and_belongs_to_many :tags

  attr_accessor :tag_list

  def tag_list
    tags.map(&:name).join(", ")
  end

  def tag_list=(names)
    while names != nil
    self.tags = names.split(",").map do |n|
      Tag.find_or_create_by(:name => n.strip, :user_id => self.user_id)
    end
    end
  end

  def tagged_with
    Tag.first(:slug => slug).tweets
  end

end

get '/' do
  if current_user?
    @user = User.find_by(:uid => session[:uid])
    erb :index
  else
    erb :welcome
  end
end

get '/users' do
  @user = User.find_by(:uid => session[:uid])
  @user.to_json(:methods => [:tweets,:tags,:tag_list])
end

get '/tags' do
  @tags = User.find_by(:uid => session[:uid]).tags
  @tags.to_json(:methods => [:tweets])
end

# get '/tags/:id' do
#   @tag = Tag.find(params[:id])
#   @tag.to_json(:methods => [:tweets])
#   erb :"tags/show"
# end

get '/tags/:slug' do
  @tag = User.find_by(:uid => session[:uid]).tags.find_by(:slug => params[:slug])
  @tag.to_json(:methods => [:tweets])
  erb :"tags/show"
end

#GET Returns all tweets
get '/tweets' do
  @tweets = User.find_by(:uid => session[:uid]).tweets.order('uid DESC')
  @tweets.to_json(:methods => [:tags,:tag_list])
end


get '/tweets/:id/change' do
  @tweet = Tweet.get(params[:id])
  @tags = Tag.all
  erb :"tweet/edit"
end

get '/tweets/:id/show' do
  @tweet = Tweet.get(params[:id])
  erb :"tweet/show"
end

get '/users/:uid' do
  @user = User.find_by(:uid => session[:uid])
  @user.to_json(:methods => [:tags,:tag_list,:tweets])
end

get '/tweets/:id' do
  @tweet = Tweet.find_by(:id => params[:id])
  @tweet.to_json(:methods => [:tags,:tag_list])
end

put '/tweets/:id' do
  begin
    params.merge! JSON.parse(request.env["rack.input"].read)
  rescue JSON::ParserError
    logger.error "Cannot parse request body."
  end  
  @tweet = Tweet.find(params[:id])
  if @tweet.update(:archived => params[:archived], :tag_list => params[:tag_list])
    status 201
  else
    halt 500
  end
end

get '/login' do
  redirect to("/auth/twitter") unless current_user?
  @user = User.find_by(:uid => session[:uid])
  @user.fetch_tweets
  redirect to("/")
end

get '/auth/twitter/callback' do
  session[:uid] = env['omniauth.auth']['uid']
  @user = find_or_create_by_uid
  @user.fetch_tweets
  redirect to("/")
end

get '/auth/failure' do
  params[:message]
end

get '/logout' do
  session[:uid] = nil
  "You are now logged out"
end

not_found do
  halt(404,'URL not found.')
end
