# encoding: utf-8

class EnrollController < ApplicationController
  before_filter :load_user
  before_filter :load_session_and_participation, :only => [:confirm, :register]
  
  def index
    @availabe_sessions = @user.available_sessions
  end

  def confirm
    
  end

  def register
    # create session participation if there is space (a) and user is not in the session already (b)
    sql = <<EOSQL
      INSERT INTO session_participations 
      SELECT NULL, #{@session.id}, #{@user.id}, NULL, 0, 0, 0, NOW(), NOW() 
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
          WHERE sps.session_id = s.id AND sps.user_id = #{@user.id}
        ) = 0
EOSQL
   
    ActiveRecord::Base.connection.execute(sql)
   
    # check for result
    @session_participation = SessionParticipation.find_by_user_id_and_session_id(@user.id, @session.id)
    
    if @session_participation
      # successful registration - send confirmation mail
      text = @session.experiment.confirmation_text.to_s.mreplace({
        "#firstname" => @user.firstname, 
        "#lastname"  => @user.lastname,
        "#session_date"  => @session.start_at.strftime("%d.%m.%Y"),
        "#session_start_time" => @session.start_at.strftime("%H:%M"),
        "#session_end_time" => @session.end_at.strftime("%H:%M")
      })
      
      UserMailer.email(
        @session.experiment.confirmation_subject,
        text,
        @user.main_email,
        @session.experiment.sender_email
      ).deliver
      
      redirect_to enroll_path(params[:code]), :notice => "Sie wurden verbindlich angemeldet."
    else
      redirect_to enroll_path(params[:code]), :alert => "Die Anmeldung war NICHT erfolgreich, da keine Plätze mehr frei waren."
    end
  end

protected

  def load_user
    if params['code']
      code = LoginCode.find_by_code(params['code'])
      if code && code.user
        @user = code.user
      end
    elsif current_user
      @user = current_user
    end
    
    redirect_to root_url, :alert => "Für diesen Bereich ist ein Login erforderlich. " unless @user
  end

  def load_session_and_participation
    @session = Session.find_by_id(params[:session])
          
    unless @session
      redirect_to enroll_path(params[:code])
      return 
    end
    
    @session_participation = SessionParticipation.find_by_user_id_and_session_id(@user.id, @session.id)
    if @session_participation
      redirect_to enroll_path(params[:code])
      return
    end
    
    unless @user.available_sessions.include?(@session)
      redirect_to enroll_path(params[:code]), :alert => "Die Anmeldung wurde abgebrochen, da diese Session bereits voll ist."
      return
    end
  end

end
