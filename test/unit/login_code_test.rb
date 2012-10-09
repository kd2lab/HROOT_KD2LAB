require 'test_helper'

class LoginCodeTest < ActiveSupport::TestCase
  
  context "Login Codes" do
    setup do
      @user = FactoryGirl.create(:user)
      @l1 = LoginCode.create(:user => @user, :code => rand(36**10).to_s(36), :created_at => Time.now - 40.days)
      @l2 = LoginCode.create(:user => @user, :code => rand(36**10).to_s(36), :created_at => Time.now - 32.days)
      @l3 = LoginCode.create(:user => @user, :code => rand(36**10).to_s(36))
      @l4 = LoginCode.create(:user => @user, :code => rand(36**10).to_s(36))
    end
    
    should "be destroyed after 30 days" do
      LoginCode.cleanup
      
      assert_same_elements [@l3, @l4], LoginCode.find(:all)
    end
  end
end
