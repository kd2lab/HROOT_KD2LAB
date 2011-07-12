require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  context "A request with GET to new" do
    setup do
      get :new
    end

    should respond_with :success
    should render_template :new
    should assign_to :user
  end
  
  context "A request with POST to :create" do
    context "with invalid parameters" do
      setup do
        User.any_instance.stubs(:valid?).returns(false)
        post :create, :user => {
          :email => 'test@hroot.de',
          :password => 'invalid',
          :password_confirmation => 'invalid'
        }
      end
    
      should render_template :new
    end

    context "with valid parameters" do
    
      setup do
        User.any_instance.expects(:deliver_activation_instructions!).once
        post :create, :user => {
          :email => 'test@hroot.de',
          :password => '123456',
          :password_confirmation => '123456',
        }
      end
    
      should redirect_to("root page") { root_path }
      should 'create a user' do 
        assert_equal 'test@hroot.de', User.first.email
      end
    end

  end
  
  #context "Creating a user" do
  #  setup do
  #    post :create, :user => { :password => "benrocks", :password_confirmation => "benrocks", :email => "myemail@email.com" }
  #  end
    
  #  should_change*("User.count", :by => 1)
    
    #should "create user" do 
    #  assert_difference('User.count') do
    #    post :create, :user => { :password => "benrocks", :password_confirmation => "benrocks", :email => "myemail@email.com" }
    #  end
    #  assert_redirected_to root_path    
    #end   
  #end
end