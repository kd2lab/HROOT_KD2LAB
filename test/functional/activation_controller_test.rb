require 'test_helper'

class ActivationControllerTest < ActionController::TestCase
  context "the activation controller with mail restrictions" do
    setup do
      Settings.mail_restrictions = [{"prefix"=>"sdf", "suffix"=>"uni-hamburg.de"}, {"prefix"=>"", "suffix"=>"studium.uni-hamburg.de"}]
      
      @import_token1 = "sdjfhsdfkwefu238h23fksjdhf"
      @u1 = Factory(:user, :email => "test@test.test", :import_token => @import_token1, :imported => true, :activated_after_import => false)
      
      @import_token2 = "asdfasfwesdjfhsdfkwefu238h23fksjdhf"
      @u2 = Factory(:user, :email => "xxxsdfxxx@uni-hamburg.de", :import_token => @import_token2, :imported => true, :activated_after_import => false)

      @import_token3 = "cweesdfasfwesdjfhsdfkwefefksjdhf"
      @u3 = Factory(:user, :email => "blubber@studium.uni-hamburg.de", :import_token => @import_token3, :imported => true, :activated_after_import => false)
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
    
    context "get on index with correct token and correct mail type 1" do
      setup do
        get :index, :import_token => @import_token2
      end
    
      should respond_with :success
    end
    
    context "get on index with correct token and correct mail type 2" do
      setup do
        get :index, :import_token => @import_token3
      end
    
      should respond_with :success
    end
    
    context "get on email" do
      setup do
        get :email, :import_token => @import_token1
      end
    
      should respond_with :success
    end
    
    context "post on email with incorrect mail data 1" do
      setup do
        get :email, :import_token => @import_token1, :user => {:email_prefix => "", :email_suffix => ""}
      end
    
      should "set alert" do
        assert flash[:alert].length > 0
      end
      
      should respond_with :success
    end
    
    context "post on email with incorrect mail data 2" do
      setup do
        get :email, :import_token => @import_token1, :user => {:email_prefix => "xxx", :email_suffix => "uni-hamburg.de"}
      end
    
      should "set alert" do
        assert flash[:alert].length > 0
      end
      
      should respond_with :success
    end
    
    context "post on email with incorrect mail data 3" do
      setup do
        get :email, :import_token => @import_token1, :user => {:email_prefix => "", :email_suffix => "studium.uni-hamburg.de"}
      end
    
      should "set alert" do
        assert flash[:alert].length > 0
      end
      
      should respond_with :success
    end
    
    context "post on email with already used mail data" do
      setup do
        get :email, :import_token => @import_token1, :user => {:email_prefix => "xxxsdfxxx", :email_suffix => "uni-hamburg.de"}
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
      
        get :email, :import_token => @import_token1, :user => {:email_prefix => "yyyyysdfyyyyyy", :email_suffix => "uni-hamburg.de"}
      end
    
      should "set import email fields" do
        assert_response :redirect
        @u1.reload
        assert_equal "yyyyysdfyyyyyy@uni-hamburg.de", @u1.import_email
        assert_equal 32, @u1.import_email_confirmation_token.length
      end
    end
    
    context "post on index with correct password" do
      setup do
        @u4 = Factory(:user, 
          :email => "test5@test5.de", 
          :import_token => "ebpoi44n8nvkwje", 
          :imported => true, 
          :activated_after_import => false, 
          :import_email => "bla@studium.uni-hamburg.de",
          :import_email_confirmation_token => "asdfwefgbfder"
        )
      
        get :index, :import_token => "ebpoi44n8nvkwje", :email_token => "asdfwefgbfder", :user => {:password => "tester_1", :password_confirmation => "tester_1"}
      end
    
      should "activate user and redirect" do
        assert_response :redirect
        @u4.reload
        assert_equal "bla@studium.uni-hamburg.de", @u4.email
        assert_equal "test5@test5.de", @u4.secondary_email
        
        assert_equal nil, @u4.import_email
        assert_equal nil, @u4.import_email_confirmation_token
        assert_equal nil, @u4.import_token

        assert_equal true, @u4.activated_after_import
      end
    end
  end
end
