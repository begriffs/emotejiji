require 'test_helper'

describe Emote do
  describe "attributes" do
    it "should respond to it's attributes" do
      emote = Fabricate.build(:emote)
      attrs = [:text, :description, :tags]
      attrs.each do |attr|
        emote.must_respond_to attr
      end
    end
  end

  describe "validations" do
    it "should only be valid with text set" do
      emote = Emote.new
      emote.valid?.must_equal false
      emote.text = "foobar"
      emote.valid?.must_equal true
    end
  end

  describe "row/column calculators" do
    before do
      @emote_single = Fabricate :emote, text: "foobar"
      @emote_multi  = Fabricate :emote, text: "foobar\nfoobaz7\nfoo"
    end

    it "should save longest line length when saved" do
      @emote_single.max_length.must_equal 6
      @emote_multi.max_length.must_equal 7
    end

    it "should save the text row count when saved" do
      @emote_single.text_rows.must_equal 1
      @emote_multi.text_rows.must_equal 3
    end

    it "should calculate the display_column"
    it "should calculate the display_row"
  end

  describe "initialization" do
    it "should be able to take an array for tags if it hasn't been create yet" do
      emote = Fabricate.build(:emote)
      emote.tags = ['foo', 'bar']
      emote.tags.must_equal({ foo: 1, bar: 1 })
    end

    it "should error when given a tag array if it has been created" do
      emote = Fabricate :emote
      proc {
        emote.tags = ['foo', 'bar']
      }.must_raise(TagArrayNotAllowedError)
    end

    it "should create an emote with a user and the right UserEmote relations" do
      emote = Fabricate.build(:emote)
      user  = Fabricate(:user)
      emote.create_with(user)

      owner  = UserEmote.where kind: "Owner",  user_id: user.id, emote_id: emote.id
      owner.length.must_equal 1
      tagged = UserEmote.where kind: "Tagged", user_id: user.id, emote_id: emote.id
      tagged.length.must_equal 1
      tagged.first.tags.must_equal emote.tags.keys.map{ |i| i.to_s }
    end
  end

  describe "relationships" do
    before do
      @emote = Fabricate.build(:emote)
      @user1 = Fabricate(:user)
      @user2 = Fabricate(:user)
      @emote.create_with(@user1)
      # @emote.add_tags
    end

    it "should be able to respond to it's relationships" do
      # Single relationships
      emote = Emote.new
      emote.must_respond_to :owner
      emote.owner.must_equal nil

      # Many relationships
      relations = [:favorited, :tagged]
      relations.each do |relation|
        emote.must_respond_to relation
        emote.send(relation).must_equal []
      end
    end

    it "should return who created it" do
      @emote.owner.must_equal @user1
    end

    it "should return who favorited it" do
      @emote.favorited_by(@user1)
      @emote.favorited_by(@user2)

      @emote.favorited.length.must_equal 2
      @emote.favorited.include?(@user1).must_equal true
      @emote.favorited.include?(@user2).must_equal true
    end

    it "should not allow duplicate favorites"

    it "should return who tagged it" do
      @emote.add_tags @user2.id, ["foo"]

      @emote.tagged.length.must_equal 2
      @emote.tagged.include?(@user1).must_equal true
      @emote.tagged.include?(@user2).must_equal true
    end
  end

  describe "tagging" do
    before do
      @emote1 = Emote.create text: "foobar", tags: { foo: 1, bar: 1 }
      @emote2 = Emote.create text: "foobaz", tags: { foo: 1, bar: 1 }
    end

    describe "should find" do
      it "all emotes containing a tag" do
        emotes = Emote.all_tags ["foo"]
        emotes.count.must_equal 2
      end

      it "all emotes containing any tags" do
        emotes = Emote.any_tags ["bar", "baz"]
        emotes.count.must_equal 2
      end
    end

    it "should convert tag types when creating" do
      emote = Emote.new text: "foobar", tags: { "foo" => 2, baz: 1, "bar" => 3 }
      emote.tags.must_equal({ foo: 2, baz: 1, bar: 3 })
    end

    describe "should create/modify" do
      before do
        @user1 = User.create email: "foo@bar.com", username: "foobar",
                             password: "randomfoo", password_confirmation: "randomfoo"

        @unsaved_emote = Emote.new text: "foomoo", tags: { foo: 1, moo: 1 }
      end

      it "by erroring if the user is invalid for add" do
        bad_id = @emote1.id # Gives an ID that is a valid postgres UID but wont map to a user
        proc { @unsaved_emote.create_with(bad_id) }.must_raise(ActiveRecord::RecordNotFound)

        bad_value = 0 # Try passing in something that isnt a string or user
        proc { @unsaved_emote.create_with(bad_value) }.must_raise(ActiveRecord::RecordNotFound)
      end

      it "should create a UserEmote when saved" do
        @unsaved_emote.create_with @user1
        ue = UserEmote.find_by_kind_and_user_id_and_emote_id "Owner", @user1.id, @unsaved_emote.id
        ue.kind_of?(UserEmote).must_equal true

        ue = UserEmote.find_by_kind_and_user_id_and_emote_id "Tagged", @user1.id, @unsaved_emote.id
        ue.tags.must_equal ["foo", "moo"]
      end

      it "by erroring if the user is invalid for add_tags" do
        bad_id = @emote1.id # Gives an ID that is a valid postgres UID but wont map to a user
        proc { @emote1.add_tags(bad_id, ["foo"]) }.must_raise(ActiveRecord::RecordNotFound)

        bad_value = 0 # Try passing in something that isnt a string or user
        proc { @emote1.add_tags(bad_value, ["foo"]) }.must_raise(ActiveRecord::RecordNotFound)
      end

      it "by adding a tag" do
        @emote1.add_tags @user1.id, ["foo"]
        @emote1.tags.must_equal({ foo: 2, bar: 1 })
      end

      it "by adding multiple tags" do
        @emote1.add_tags @user1, ["foo", "bar", "boo"]
        @emote1.tags.must_equal({ foo: 2, bar: 2, boo: 1})
      end

      it "by creating the appropriate UserEmote to track tagging" do
        @emote1.add_tags @user1, [:foo, :bar, "boo"]
        ue = UserEmote.find_by_kind_and_user_id_and_emote_id "Tagged", @user1.id, @emote1.id
        # Postgres arrays are always stored as strings, thus even if you add symbols, you get string back
        ue.tags.must_equal ["foo", "bar", "boo"]
        @emote1.tags.must_equal({ foo: 2, bar: 2, boo: 1 })
      end

      it "by updating the appropriate UserEmote to track tagging when it exists" do
        @emote1.add_tags @user1, [:foo, :bar, "boo"]
        @emote1.add_tags @user1, ["moo", :cow]
        ue = UserEmote.where kind: "Tagged", user_id: @user1.id, emote_id: @emote1.id
        ue.length.must_equal 1
        ue.first.tags.must_equal ["foo", "bar", "boo", "moo", "cow"]
        @emote1.tags.must_equal({ foo: 2, bar: 2, boo: 1, moo: 1, cow: 1 })
      end
    end
  end

  describe "api meta" do
    it "should have a field that can be used to store api meta data upon creation" do
      emote = Emote.new
      emote.api_meta.kind_of?(Hashie::Mash).must_equal true
    end

    it "should not persist the api meta field upon save" do
      emote = Fabricate.build :emote
      emote.api_meta.foo = "bar"
      emote.save

      test = Emote.find emote.id
      test.api_meta.foo.must_equal nil
    end

    it "should have a api meta field on Emote.find" do
      emote = Fabricate :emote

      test = Emote.find emote.id
      test.api_meta.kind_of?(Hashie::Mash).must_equal true
    end
  end
end


#it "should allow saving of tags as a ruby array" do
#  @emote.tags = { foo: 1, bar: 1, baz: 1 }
#  @emote.tags.must_be_instance_of Hash
#end