require 'test_helper'

class UserTest < ActiveSupport::TestCase
  context "a valid user" do
    setup do
      @user = Factory(:user)
    end

    should validate_uniqueness_of(:email).case_insensitive
    
    should allow_value("foo@bar.xyz").for(:email)
    should allow_value("baz@foo.zya").for(:email)
    
    should_not allow_value("foo").for(:email)
    should_not allow_value("baz@.zya").for(:email)
    should_not allow_value("foo.de").for(:email)
    
    should "require password_confirmation to match password" do
      @user.password = "foobar"
      @user.password_confirmation = "barfoo"
      assert !@user.valid?

      @user.password = "foobar"
      @user.password_confirmation = "foobar"
      assert @user.valid?
    end

    should "be valid" do
      assert @user.valid?
    end
    
    should "be activated with activate mathod" do
      assert !@user.active
      @user.activate!
      assert @user.active
    end

  end
end
