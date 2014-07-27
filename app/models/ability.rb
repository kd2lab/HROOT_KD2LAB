class Ability
  include CanCan::Ability

  def initialize(user)
    if user && !user.deleted?
      if user.admin?
        can :manage, :all 
      elsif user.experimenter?
        can [:new, :create], Experiment do |experiment|
          user.can_create_experiment
        end

        can :read, Experiment do |experiment|
          experiment.experimenter_assignments.where(:user_id => user.id).count > 0
        end
        
        # edit experiment data
        can [:edit, :update, :reminders], Experiment do |experiment|
          experiment.experimenter_assignments.where(:user_id => user.id).where("rights LIKE '%edit%'").count > 0
        end
        
        # change rights of experimenters
        can :experimenters, Experiment do |experiment|
          experiment.experimenter_assignments.where(:user_id => user.id).where("rights LIKE '%rights%'").count > 0
        end
        
        # Sessionverwaltung
        can [:index, :print, :participants], Session
        
        can :manage, Session do |session|
          session.experiment.experimenter_assignments.where(:user_id => user.id).where("rights LIKE '%manage_sessions%'").count > 0
        end
        
        # Einladungsverwaltung
        can [:invitation, :mail, :enable, :disable], Experiment do |experiment|
          experiment.experimenter_assignments.where(:user_id => user.id).where("rights LIKE '%manage_invitation%'").count > 0
        end
                
        
        can :index, :admin
        can :calendar, :admin
      end
      
      # all users..
      can :manage, :account
      can :manage, :enroll 
    end
    
    
    # See the wiki for details: https://github.com/ryanb/cancan/wiki/Defining-Abilities
  end
end
