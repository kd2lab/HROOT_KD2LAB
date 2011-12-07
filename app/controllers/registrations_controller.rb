class RegistrationsController < Devise::RegistrationsController
  def new
    super
  end

  def create
    if Settings.mail_restrictions && Settings.mail_restrictions.select{|r| !r["suffix"].blank?}.count > 0
      params[:user][:email] = nil
    end  
    
    # if there are mail restrictions, ande the user has submitted separate params for prefix and suffix..
    if Settings.mail_restrictions && Settings.mail_restrictions.count > 0 && params[:user] && !params[:user][:email_prefix].blank? && !params[:user][:email_suffix].blank?
      Settings.mail_restrictions.each do |r|
        # does the suffix match?
        if r['suffix'].to_s == params[:user][:email_suffix]
          # is the prefix emptry
          if r['prefix'].blank?
            params[:user][:email] = params[:user][:email_prefix]+"@"+params[:user][:email_suffix]
          else
            # also check for prefix inclusion
            if params[:user][:email_prefix].include?(r['prefix'].to_s)
              params[:user][:email] = params[:user][:email_prefix]+"@"+params[:user][:email_suffix]
            end
          end
        end
      end
    end         
  
    super
  end

  def update
    super
  end
end