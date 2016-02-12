require 'spec_helper'

class Article < Sequel::Model
  one_to_many :comments
end

class Comment < Sequel::Model
  many_to_one :article
end

describe Sequel::Plugins::Revisions do
  describe "Polymorphic Model" do
    before(:each) do
      Article.dataset.delete
      Comment.dataset.delete

      Article.plugin :revisions,
        meta: -> () {
          {
            user_id: 12,
            user_name: "Marvin"
          }
        },
        polymorphic: true,
        on: [:update]

      Comment.plugin :revisions,
        embedded_in: :article
    end

    it "should be loaded using Model.plugin" do
      Article.plugins.should include(Sequel::Plugins::Revisions)
    end

    it "should define a articleRevisions model" do
      Object.const_get("Revision").should_not be_nil
    end

    it "should track all actions for Comments" do
      Comment.revisions_on?(:update).should be true
      Comment.revisions_on?(:create).should be true
      Comment.revisions_on?(:destroy).should be true
    end

    it "should only track updates for Articles" do
      Article.revisions_on?(:update).should be true
      Article.revisions_on?(:create).should be false
      Article.revisions_on?(:destroy).should be false
    end

    describe "Revision Tracking" do
      before(:each) do
        @article = Article.new(title: "Test Article", content: "Awesome Content")
      end

      it "should start with empty history" do
        @article.revisions.should be_empty
      end

      it "should track changes after update" do
        # First save
        @article.save

        # Changing article
        @article.title = "New Title"
        @article.save

        @article.revisions.length.should eq(1)
      end

      it "should track the correct fields" do
        # First save
        @article.save

        # Changing article
        @article.title = "New Title"
        @article.content = "Different content"
        @article.save

        revision = @article.revisions.last
        revision.changes.size.should eq(2)
      end
    end

    describe "Reverting Changes" do
      before(:each) do
        @article = Article.create(title: "Test article", content: "Awesome Content")
      end

      it "does nothing when there's are no revisions" do
        @article.revert
        @article.changed_columns.should be_empty
      end

      it "reverts previous changes" do
        @article.title = "Changed Title"
        @article.content = "Changed Content"
        @article.save

        @article.revert
        @article.title.should eq("Test article")
        @article.content.should eq("Awesome Content")
        @article.changed_columns.length.should eq(2)
      end

      it "tracks changes when reverting" do
        @article.title = "Changed Title"
        @article.content = "Changed Content"
        @article.save

        @article.revisions.length.should eq(1)

        @article.revert!
        @article.revisions.length.should eq(2)
      end
    end

    describe "Meta values" do
      it "evaluates the meta lambda" do
        @article = Article.create(title: "Test article", content: "Awesome Content")
        @article.title = "Other Title"
        @article.save

        meta = @article.revisions.last.meta
        meta.should_not be_empty
        meta['user_id'].should eq(12)
        #meta['revisions'].should eq(1)
      end
    end

    describe "Embedding" do
      it "correctly tracks embedded models" do
        @article = Article.create(title: "Test article", content: "Awesome Content")
        @article.title = "Other Title"
        @article.save

        # Changing article
        @article.title = "New Title"
        @article.save
        @article.revisions.length.should eq(2)

        # Create comment and save
        @comment = Comment.create(name: 'halfdan', text: 'Test', article: @article)

        @comment.text = "Test 123"
        @comment.save

        @comment.revisions.length.should eq(1)
      end
    end
  end
end
