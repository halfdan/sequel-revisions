$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'sequel'
require 'rspec'

require_relative '../lib/sequel/plugins/history'

Sequel.extension :inflector

# Create tables to test on
DB = Sequel.sqlite
DB.create_table :posts do
  primary_key :id, :integer, auto_increment: true
  varchar :title, null: false
  text :content, null: false

  DateTime :created_at
  DateTime :updated_at
end

DB.create_table :post_history_events do
  primary_key :id, :integer, auto_increment: true
  integer :post_id, null: false
  text :meta, default: "{}"
  text :changes, default: "{}"

  DateTime :created_at
  DateTime :updated_at

  index [:post_id]
end

class Post < Sequel::Model; end

RSpec.configure do |config|
  #config.after(:each)  { Post.delete }
end
