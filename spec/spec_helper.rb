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
  string :action, null: false
  text :meta, default: "{}"
  text :changes, default: "{}"

  DateTime :created_at
  DateTime :updated_at

  index [:post_id]
end

DB.create_table :articles do
  primary_key :id, :integer, auto_increment: true
  varchar :title, null: false
  text :content, null: false

  DateTime :created_at
  DateTime :updated_at
end

DB.create_table :comments do
  primary_key :id, :integer, auto_increment: true
  integer :article_id, null: false

  string :name
  varchar :text

  DateTime :created_at
  DateTime :updated_at
end

DB.create_table :revisions do
  primary_key :id, :integer, auto_increment: true

  string :action, null: false
  integer :trackable_id, null: false
  string :trackable_type, null: false

  integer :embeddable_id, null: true
  string :embeddable_type, null: true

  text :meta, default: "{}"
  text :changes, default: "{}"

  DateTime :created_at
  DateTime :updated_at

  index [:trackable_id, :trackable_type]
end

Sequel::Model.plugin(:polymorphic)

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :should }
end
