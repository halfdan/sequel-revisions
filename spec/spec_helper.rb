$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'sequel'
require 'rspec'

require_relative '../lib/sequel/plugins/revisions'

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

DB.create_table :post_revisions do
  primary_key :id, :integer, auto_increment: true
  integer :post_id, null: false
  text :meta, default: "{}"
  text :changes, default: "{}"

  DateTime :created_at
  DateTime :updated_at

  index [:post_id]
end

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :should }
end
