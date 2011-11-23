class RegistrationsController < Devise::RegistrationsController
  def new
    super
  end

  def create
    if Settings.mail_restrictions && Settings.mail_restrictions.count > 0
      prefix = ""
      Settings.mail_restrictions.each do |r|
        unless r['suffix'].blank?
          if params[:user][:email_prefix].include?(r['prefix']) && r['suffix'] == params[:user][:email_suffix]
            prefix = params[:user][:email_prefix]  
          end
        end
      end
      
      params[:user][:email] = prefix+"@"+params[:user][:email_suffix]
    end      
  
    super
  end

  def update
    super
  end
end