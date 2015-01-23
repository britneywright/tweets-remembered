class CreateTags < ActiveRecord::Migration
  def change
    create_table :tags do |t|
      t.string :name
      t.string :slug
      t.belongs_to :user
      t.timestamps
    end
  end
end
