class LoginCode < ActiveRecord::Base
  validates :code, :uniqueness => true
   
  belongs_to :user
end
