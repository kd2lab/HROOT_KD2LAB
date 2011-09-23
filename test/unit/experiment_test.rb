require 'test_helper'

class ExperimentTest < ActiveSupport::TestCase
  context "a valid experiment" do
    should validate_presence_of :name
  end 

end
