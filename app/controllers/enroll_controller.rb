# encoding: utf-8

class EnrollController < ApplicationController
  before_filter :load_user
  before_filter :load_session_and_participation, :only => [:confirm, :register]
  
  def index
    @session_participations_in_the_future = @user.participations
      .includes(:session)
      .where("session_id IS NOT NULL AND sessions.start_at > NOW()")
      .all
      
    @availabe_sessions = @user.available_sessions
  end

  def confirm
    
  end

  def register
    sql = <<EOSQL
      UPDATE 
        participations,
        (SELECT s.needed + s.reserve - count(p.id) as count
        FROM sessions s, participations p 
        WHERE p.session_id = s.id AND s.id = #{@session.id}) as c
      SET
        participations.session_id = #{@session.id}
      WHERE
        participations.session_id IS NULL AND participations.id = #{@participation.id} AND c.count > 0;
EOSQL
    
    ActiveRecord::Base.connection.execute(sql)
    @participation.reload
    
    if @participation.session_id.to_i > 0
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
    unless @session && @user.available_sessions.include?(@session)
      redirect_to enroll_path(params[:code]), :alert => "Die Anmeldung wurde abgebrochen, da diese Session bereits voll ist."
      return
    end
          
    @participation = Participation.find_by_user_id_and_experiment_id(@user.id, @session.experiment_id)
    unless @participation
      redirect_to enroll_path(params[:code])
      return
    end
  end

end
