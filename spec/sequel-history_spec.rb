require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'pry'
class Post < Sequel::Model; end

describe "SequelHistory" do
  before(:each) do
    Post.plugin :history, meta: -> (model) {
      {
        user_id: 12,
        user_name: "Marvin",
        revisions: model.changes.size
      }
    }
  end

  it "should be loaded using Model.plugin" do
    Post.plugins.should include(Sequel::Plugins::History)
  end

  it "should define a PostHistoryEvent model" do
    Object.const_get("PostHistoryEvent").should_not be_nil
  end

  describe "History Tracking" do
    before(:each) do
      @post = Post.new(title: "Test Post", content: "Awesome Content")
    end

    it "should start with empty history" do
      @post.history.should be_empty
    end

    it "should track changes after update" do
      # First save
      @post.save
      # Changing post
      @post.title = "New Title"
      @post.save

      @post.history.length.should eq(1)
    end

    it "should track the correct fields" do
      # First save
      @post.save

      # Changing post
      @post.title = "New Title"
      @post.content = "Different content"
      @post.save

      history = @post.history.last
      history.changes.size.should eq(2)
    end
  end

  describe "Reverting Changes" do
    before(:each) do
      @post = Post.create(title: "Test Post", content: "Awesome Content")
    end

    it "does nothing when there's no history" do
      @post.revert
      @post.changed_columns.should be_empty
    end

    it "reverts previous changes" do
      @post.title = "Changed Title"
      @post.content = "Changed Content"
      @post.save

      @post.revert
      @post.title.should eq("Test Post")
      @post.content.should eq("Awesome Content")
      @post.changed_columns.length.should eq(2)
    end

    it "tracks history when reverting" do
      @post.title = "Changed Title"
      @post.content = "Changed Content"
      @post.save

      @post.history.length.should eq(1)

      @post.revert!
      @post.history.length.should eq(2)
    end
  end

  describe "Meta values" do
    it "evaluates the meta lambda" do
      @post = Post.create(title: "Test Post", content: "Awesome Content")
      @post.title = "Other Title"
      @post.save

      meta = @post.history.last.meta
      meta.should_not be_empty
      meta[:user_id].should eq(12)
      meta[:revisions].should eq(1)
    end
  end
end
