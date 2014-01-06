require 'test_helper'

class ActivationControllerTest < ActionController::TestCase
  context "the activation controller with mail restrictions" do
    setup do
      # invalid user
      @import_token1 = "sdjfhsdfkwefu238h23fksjdhf"
      @u1 = FactoryGirl.create(:user, :email => "test@test.test", :import_token => @import_token1, :imported => true, :activated_after_import => false, :admin_update => true)
      
      # valid user
      @import_token2 = "asdfasfwesdjfhsdfkwefu238h23fksjdhf"
      @u2 = FactoryGirl.create(:user, :email => "xxxsdfxxx@uni-hamburg.de", :import_token => @import_token2, :imported => true, :activated_after_import => false)

    end
    
    context "get on index with wrong token" do
      setup do
        get :index, :import_token => "asdf"
      end
    
      should respond_with :redirect
    end

    context "get on index with correct token and invalid mail" do
      setup do
        get :index, :import_token => @import_token1
      end
    
      should respond_with :redirect
    end
    
    context "get on index with correct token and correct mail" do
      setup do
        get :index, :import_token => @import_token2
      end
    
      should respond_with :success
    end
    
    context "get on email" do
      setup do
        get :email, :import_token => @import_token1
      end
    
      should respond_with :success
    end
    
    context "post on email with incorrect mail data" do
      setup do
        get :email, :import_token => @import_token1, :user => {:email => "" }
      end
    
      should "set alert" do
        assert flash[:alert].length > 0
      end
      
      should respond_with :success
    end
    
    context "post on email with incorrect mail data 2" do
      setup do
        get :email, :import_token => @import_token1, :user => {:email => "dd@somewhereelse.de"}
      end
    
      should "set alert" do
        assert flash[:alert].length > 0
      end
      
      should respond_with :success
    end
    
    
    context "post on email with already used mail data" do
      setup do
        get :email, :import_token => @import_token1, :user => {:email => "xxxsdfxxx@uni-hamburg.de"}
      end
    
      should "set alert" do
        assert flash[:alert].length > 0
      end
      
      should respond_with :success
    
    end
    
    context "post on email with correct mail data" do
      setup do
        m = mock()
        UserMailer.stubs(:import_email_confirmation).returns(m)
        m.expects(:deliver).times(1)
      
        get :email, :import_token => @import_token1, :user => {:email => "new@uni-hamburg.de"}
      end
    
      should "set import email fields" do
        assert_response :redirect
        @u1.reload
        assert_equal "new@uni-hamburg.de", @u1.import_email
        assert_equal 32, @u1.import_email_confirmation_token.length
      end
    end
    
    context "post on index with correct password" do
      setup do
        @u4 = FactoryGirl.create(:user, 
          :email => "test5@test5.de", 
          :import_token => "ebpoi44n8nvkwje", 
          :imported => true, 
          :activated_after_import => false, 
          :import_email => "bla@uni-hamburg.de",
          :import_email_confirmation_token => "asdfwefgbfder",
          :admin_update => true
        )

        get :index, :import_token => "ebpoi44n8nvkwje", :email_token => "asdfwefgbfder", :user => {:password => "tester_1", :password_confirmation => "tester_1"}
      end
    
      should "activate user and redirect" do
        assert_response :redirect
        @u4.reload
        assert_equal "bla@uni-hamburg.de", @u4.email
        assert_equal "test5@test5.de", @u4.secondary_email
        
        assert_equal nil, @u4.import_email
        assert_equal nil, @u4.import_email_confirmation_token
        assert_equal nil, @u4.import_token

        assert_equal true, @u4.activated_after_import
      end
    end
  end
end
