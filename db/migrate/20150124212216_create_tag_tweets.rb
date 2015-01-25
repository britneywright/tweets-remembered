class CreateTagTweets < ActiveRecord::Migration
  def change
    create_join_table :tags, :tweets
  end
end
