class Location < ActiveRecord::Base
  has_many :sessions
  
  validates_presence_of :name
end
