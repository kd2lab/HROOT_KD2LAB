# encoding: utf-8

class AccountController < ApplicationController
  authorize_resource :class => false
  before_filter :check_for_missing_data, :except => [:missing]

  def index
    @experiment = Experiment.where(:refkey => cookies[:refkey]).first

    if @experiment && current_user.user?
      
      # participation already exists?
      if Participation.where(:user_id => current_user.id, :experiment_id => @experiment.id).count == 0
        # if not create participation and history entry
        Participation.create(:user_id => current_user.id, :experiment_id => @experiment.id, :added_by_public_key => 1)
        HistoryEntry.create(:search => '', :experiment_id => @experiment.id, :action => "added_by_public_key", :user_count => 1, :user_ids => [current_user.id].to_json)          
      end

      # and delete cookie
      cookies.delete :refkey
    end
  end
  
  def optional
    add_breadcrumb :data, :account_data_path
    add_breadcrumb :optional, :account_optional_path

    if params[:user]      
      if current_user.update_attributes(params[:user])
        redirect_to(account_optional_path, :notice => t('controllers.account.notice_data_changed')) 
      end
    end  
  end

  def data
    add_breadcrumb :data, :account_data_path
  end
  
  def alternative_email
    add_breadcrumb :data, :account_data_path
    add_breadcrumb :alternative_email, :account_alternative_email_path

    if params[:delete]
      current_user.secondary_email = nil
      current_user.secondary_email_confirmation_token = nil
      current_user.secondary_email_confirmed_at = nil
      current_user.save
      redirect_to({:action => :alternative_email}, :notice =>  t('controllers.account.notice_alternative_mail1'))
    end  

    if params[:resend] && !current_user.secondary_email_confirmation_token.blank?
      UserMailer.secondary_email_confirmation(current_user).deliver
      redirect_to({:action => :alternative_email}, :notice => t('controllers.account.notice_alternative_mail2'))
    end  
      
    if params[:user]
      current_user.secondary_email = params[:user][:secondary_email]
      
      if current_user.valid?
        current_user.secondary_email_confirmation_token = SecureRandom.hex(16)
        current_user.secondary_email_confirmed_at = nil
        current_user.save
        UserMailer.secondary_email_confirmation(current_user).deliver
      end
    end
  end
  
  def edit
    if params[:user]
      params[:user][:country_name] = nil if params[:user][:country_name] == ''
      
      if current_user.update_attributes(params[:user])
        redirect_to(account_edit_path, :notice => t('controllers.account.notice_data_changed')) 
      end
    end
  end

  def missing
    add_breadcrumb :data, :account_data_path
    add_breadcrumb :missing, :account_missing_path
    
    if current_user.valid?
      redirect_to account_url
    else
      if params[:user]
        if current_user.update_attributes(params[:user])
          redirect_to account_path, :notice => t('controllers.account.notice_data_changed')
        end
      end
    end
  end

private

  def check_for_missing_data
    # is all data ok? if not, ask user
    if current_user.user? && !current_user.valid?
      redirect_to account_missing_path
    end
  end


end
