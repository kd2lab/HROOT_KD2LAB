class Location < ActiveRecord::Base
  has_many :sessions
end
