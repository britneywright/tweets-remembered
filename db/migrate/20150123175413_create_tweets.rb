class CreateTweets < ActiveRecord::Migration
  def change
    create_table :tweets do |t|
      t.integer :uid, :limit => 8
      t.text :text
      t.string :username
      t.string :screenname
      t.boolean :archived, :default => false
      t.belongs_to :user
      t.text :uid_string
      t.datetime :created_at
      t.datetime :updated_at
    end
  end
end
