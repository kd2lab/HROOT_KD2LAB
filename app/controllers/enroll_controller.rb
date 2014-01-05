# encoding: utf-8

class EnrollController < ApplicationController
  authorize_resource :class => false, :except => :enroll_sign_in
  
  before_filter :load_session_and_participation, :only => [:confirm, :register]
  
  def index
    @available_sessions = current_user.available_sessions
  end

  def confirm
    
  end

  def report
    @session_participation = SessionParticipation.find_by_user_id_and_session_id(current_user.id, params[:session_id])
  end

  def register
    # create session participation if there is space (a) and user is not in the session already (b)
    sql = <<EOSQL
      INSERT INTO session_participations 
      SELECT NULL, #{@session.id}, #{current_user.id}, NULL, 0, 0, 0, NOW(), NOW(), NULL, NULL 
      FROM sessions s
      WHERE
        s.id = #{@session.id} AND
        ( -- (a)
          SELECT s.needed + s.reserve - count(sp.id) 
          FROM session_participations sp 
          WHERE sp.session_id = s.id
        ) > 0 AND
        ( -- (b)
          SELECT count(sps.id) FROM session_participations sps
          WHERE sps.session_id = s.id AND sps.user_id = #{current_user.id}
        ) = 0
EOSQL
   
    ActiveRecord::Base.connection.execute(sql)
   
    # check for result - do not use cache :-)
    SessionParticipation.uncached do
      @session_participation = SessionParticipation.find_by_user_id_and_session_id(current_user.id, @session.id)
    end
    
    if @session_participation
      # success!

      # add user to all following sessions
      sql = <<EOSQL
      INSERT INTO session_participations 
      SELECT NULL, s.id, #{current_user.id}, NULL, 0, 0, 0, NOW(), NOW(), NULL, NULL
      FROM sessions s
      WHERE
        s.reference_session_id = #{@session.id} AND
        s.id <> s.reference_session_id
EOSQL
      
      ActiveRecord::Base.connection.execute(sql)
      
      # successful registration - send confirmation mail
      subject = Task.replace(@session.experiment.confirmation_subject.to_s, current_user, nil, nil)
      text = Task.replace(@session.experiment.confirmation_text.to_s, current_user, nil, nil)

      sessionlist_de =  ([@session] + @session.following_sessions).map{|s| s.start_at.strftime("%d.%m.%Y") + (if s.location then " (#{t('controllers.enroll.location')} #{s.location.name.chomp})" else "" end) }.join("\n")
      sessionlist_en =  ([@session] + @session.following_sessions).map{|s| s.start_at.strftime("%Y-%m-%d") + (if s.location then " (#{t('controllers.enroll.location')} #{s.location.name.chomp})" else "" end) }.join("\n")
      
      text = text.to_s.mreplace([
        ["#sessionlist_de", sessionlist_de],
        ["#sessionlist_en", sessionlist_en],
        ["#sessionlist", sessionlist_de]
      ])
      
      UserMailer.email(
        subject,
        text,
        current_user.main_email,
        @session.experiment.sender_email_or_default
      ).deliver

      SentMail.create(
        :subject => subject,
        :message => text, 
        :from => @session.experiment.sender_email_or_default,
        :to => current_user.main_email,
        :message_type => UserMailer::SESSION_CONFIRMATION,
        :user_id => current_user.id,
        :experiment_id => @session.experiment_id,
        :sender_id => nil,
        :session_id => @session.id
      )

    end
    
    redirect_to enroll_report_path(:session_id => @session.id)
  end

  def enroll_sign_in
    if params['code']
      code = LoginCode.find_by_code(params['code'])
      if code && code.user
        sign_in code.user
      end
    end
    
    if user_signed_in?
      redirect_to enroll_path
    else
      redirect_to root_url
    end
  end

protected

  def load_session_and_participation
    @session = Session.find_by_id(params[:session])
    
    unless @session
      redirect_to enroll_path
      return 
    end
    
    @session_participation = SessionParticipation.find_by_user_id_and_session_id(current_user.id, @session.id)
    if @session_participation
      redirect_to enroll_path
      return
    end
    
    unless current_user.available_sessions.include?(@session)
      redirect_to enroll_path, :alert => t('controllers.enroll.notice_abort')
      return
    end
  end

end
