class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :firstname, :lastname, :matrikel, :role, :phone, :gender
  
  ROLES = %w[user experimenter admin]
  
  has_many :experimenter_assignments
  has_many :experiments, :through => :experimenter_assignments, :source => :experiment
  has_many :experiment_participations
  has_many :participations, :through => :experiment_participation, :source => :experiment
  
  validates_presence_of :firstname, :lastname, :matrikel
  
  def self.search(search)  
    if search  
      where('(firstname LIKE ? OR lastname LIKE ? OR email LIKE ?)', "%#{search}%", "%#{search}%", "%#{search}%")  
    else  
      scoped  
    end  
  end
  
  def admin?
    role == "admin"
  end
end
