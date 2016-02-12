require 'spec_helper'

class Post < Sequel::Model; end

describe Sequel::Plugins::Revisions do
  describe "Single Model" do

    before(:each) do
      Post.plugin :revisions, meta: -> () {
        {
          user_id: 12,
          user_name: "Marvin"
        }
      }, on: [:updated]
    end

    it "should be loaded using Model.plugin" do
      Post.plugins.should include(Sequel::Plugins::Revisions)
    end

    it "should define a PostRevisions model" do
      Object.const_get("PostRevision").should_not be_nil
    end

    describe "Revision Tracking" do
      before(:each) do
        @post = Post.new(title: "Test Post", content: "Awesome Content")
      end

      it "should start with empty history" do
        @post.revisions.should be_empty
      end

      it "should track changes after update" do
        # First save
        @post.save
        # Changing post
        @post.title = "New Title"
        @post.save

        @post.revisions.length.should eq(1)
      end

      it "should track the correct fields" do
        # First save
        @post.save

        # Changing post
        @post.title = "New Title"
        @post.content = "Different content"
        @post.save

        revision = @post.revisions.last
        revision.changes.size.should eq(2)
      end
    end

    describe "Reverting Changes" do
      before(:each) do
        @post = Post.create(title: "Test Post", content: "Awesome Content")
      end

      it "does nothing when there's are no revisions" do
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

      it "tracks changes when reverting" do
        @post.title = "Changed Title"
        @post.content = "Changed Content"
        @post.save

        @post.revisions.length.should eq(1)

        @post.revert!
        @post.revisions.length.should eq(2)
      end
    end

    describe "Meta values" do
      it "evaluates the meta lambda" do
        @post = Post.create(title: "Test Post", content: "Awesome Content")
        @post.title = "Other Title"
        @post.save

        meta = @post.revisions.last.meta
        meta.should_not be_empty
        meta['user_id'].should eq(12)
        #meta['revisions'].should eq(1)
      end
    end
  end
end
