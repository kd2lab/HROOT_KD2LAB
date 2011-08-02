class HomeController < ApplicationController
  def index
  
  end
  
  def test
    render :text => params.inspect
  end
  
  def import
    require 'sequel'
    @report = []
    
    db = Sequel.connect(:adapter=>'mysql2', :host=>'localhost', :database=>'controlling_orsee', :user=>'root', :password=>'')
    
    User.delete_all
    Experiment.delete_all
    
    # import admins
    @report << "--------- ADMINS ------------"
    db[:or_admin].each do |row|
      u = User.create(
        :email => row[:email], 
        :firstname => row[:fname],
        :lastname => row[:lname],
        :password => "test",
        :password_confirmation => "test",
        :old_id => row[:admin_id],
        :old_admin_name => row[:adminname],
        :matrikel => "admin"
      )
      if !u.valid?
        @report << u.email+" "+u.errors.inspect
      else
        u.has_role!(:admin)
      end
    end
    
    # import users
    @report << "--------- USERS ------------"
    db[:or_participants].each do |row|
      u = User.create(
        :email => row[:email], 
        :firstname => row[:fname],
        :lastname => row[:lname],
        :matrikel => if row[:matrikelnummer].blank? then "0" else row[:matrikelnummer] end,
        :password => "test",
        :password_confirmation => "test",
        :old_id => row[:participant_id]
      )
      if !u.valid?
        @report << u.email+" "+u.errors.inspect
      end
    end
    
    

    
    # import experiments
    @report << "--------- EXPERIMENTS ------------"
    db[:or_experiments].each do |row|
      @report << "Importing experiment "+row[:experiment_name]
      e = Experiment.create(
        :name => row[:experiment_name],
        :public_name => row[:experiment_public_name],
        :type => row[:experiment_type],
        :description => row[:experiment_description]
      )
      if !e.valid?
        @report << e.name.to_s+" "+e.errors.inspect
      else
        # setup admin relation
        row[:experimenter].split(',').each do |admin_name|
          @report << "adding "+admin_name+ " as admin"
          u = User.find_by_old_admin_name(admin_name)     
          if u          
            e.experimenters << u
          else
            @report << "Error: "+admin_name+" not found"
          end
        end
      end
    end
  end
end
