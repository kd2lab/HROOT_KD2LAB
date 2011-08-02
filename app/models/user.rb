class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :firstname, :lastname, :matrikel
  
  has_many :experimenter_assignments
  has_many :experiments, :through => :experimenter_assignments, :source => :experiment
  
  acts_as_authorization_subject  :association_name => :roles
  
  validates_presence_of :firstname, :lastname, :matrikel
end
