# encoding: utf-8

class EnrollController < ApplicationController
  authorize_resource :class => false, :except => :enroll_sign_in
  
  before_filter :load_session_and_participation, :only => [:confirm, :register]
  
  def index
    @availabe_sessions = current_user.available_sessions
  end

  def confirm
    
  end

  def register
    # create session participation if there is space (a) and user is not in the session already (b)
    sql = <<EOSQL
      INSERT INTO session_participations 
      SELECT NULL, #{@session.id}, #{current_user.id}, NULL, 0, 0, 0, NOW(), NOW() 
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
      # add user to all following sessions
      sql = <<EOSQL
      INSERT INTO session_participations 
      SELECT NULL, s.id, #{current_user.id}, NULL, 0, 0, 0, NOW(), NOW() 
      FROM sessions s
      WHERE
        s.reference_session_id = #{@session.id} AND
        s.id <> s.reference_session_id
EOSQL
      
      ActiveRecord::Base.connection.execute(sql)
      
      # successful registration - send confirmation mail
      subject = @session.experiment.confirmation_subject.to_s.mreplace({
        "#firstname" => current_user.firstname, 
        "#lastname"  => current_user.lastname,
        "#session_date"  => I18n.l(@session.start_at, :format => :date_only),
        "#session_start_time" => I18n.l(@session.start_at, :format => :time_only),
        "#session_end_time" => I18n.l(@session.end_at, :format => :time_only),
        "#session_location" => if @session.location then @session.location.name else "" end
      })
      
      text = @session.experiment.confirmation_text.to_s.mreplace({
        "#firstname" => current_user.firstname, 
        "#lastname"  => current_user.lastname,
        "#session_date"  => I18n.l(@session.start_at, :format => :date_only),
        "#session_start_time" => I18n.l(@session.start_at, :format => :time_only),
        "#session_end_time" => I18n.l(@session.end_at, :format => :time_only),
        "#session_location" => if @session.location then @session.location.name else "" end,
        "#sessionlist"  =>  ([@session] + @session.following_sessions).map{|s| I18n.l(s.start_at) + (if s.location then " (#{t('controllers.enroll.location')} #{s.location.name.chomp})" else "" end) }.join("\n")
      })
      
      UserMailer.email(
        subject,
        text,
        current_user.main_email,
        @session.experiment.sender_email
      ).deliver
      
      redirect_to enroll_path(params[:code]), :notice => t('controllers.enroll.notice_registered')
    else
      redirect_to enroll_path(params[:code]), :alert => t('controllers.enroll.notice_not_registered')
    end
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
