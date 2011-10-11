require 'test_helper'

class ExperimentTest < ActiveSupport::TestCase
  
  context "the scope search" do
    setup do
      @user = Factory(:user, :firstname => "John", :lastname => "smith")
      @e1 = Factory(:experiment, :name => 'test', :description => "s sample description")
      @e2 = Factory(:experiment, :name => 'bla')
      @e3 = Factory(:experiment, :name => 'blubb')
    
      @e1.experimenters << @user
      @e2.experimenters << @user
    end
  
    should "find by name or description" do
      assert_equal [@e2,@e3], Experiment.search('bl')
      assert_equal [@e1], Experiment.search('sample')
    end
    
    should "find by experimenter firstname or lastname" do
      assert_equal [@e1,@e2], Experiment.search('ohn')
      assert_equal [@e1,@e2], Experiment.search('MITH')
    end
  end
  
  context "updating roles" do
    setup do
      @user1 = Factory(:user)
      @user2 = Factory(:user)
      @user3 = Factory(:user)
      @user4 = Factory(:user)
      @user5 = Factory(:user)
      
      @e = Factory(:experiment)
      
      ExperimenterAssignment.create(:experiment => @e, :user => @user1, :role => "experiment_admin")
      ExperimenterAssignment.create(:experiment => @e, :user => @user2, :role => "experiment_admin")
      ExperimenterAssignment.create(:experiment => @e, :user => @user3, :role => "experiment_admin")
      ExperimenterAssignment.create(:experiment => @e, :user => @user4, :role => "experiment_helper")
      ExperimenterAssignment.create(:experiment => @e, :user => @user5, :role => "experiment_helper")
      
    end
    
    should "work" do
      @e.update_experiment_assignments [@user1.id, @user2.id], "experiment_helper"
      @e.update_experiment_assignments [@user3.id, @user4.id], "experiment_admin"
      
      assert_equal [@user3, @user4], @e.experimenter_assignments.where(:role => "experiment_admin").collect(&:user)
      assert_equal [@user1, @user2], @e.experimenter_assignments.where(:role => "experiment_helper").collect(&:user)
      
    end
  end
  
end
