# encoding: utf-8

class EnrollController < ApplicationController
  authorize_resource :class => false, :except => :enroll_sign_in
  
  before_filter :load_session_or_group_and_participation, :only => [:confirm, :register]
  
  def index
    @ungrouped_sessions, @session_groups = current_user.available_sessions
  end

  def confirm
    if @session
      render :confirm_session
    else
      render :confirm_group
    end 
  end

  def report_session
    @session_participation = SessionParticipation.find_by_user_id_and_session_id(current_user.id, params[:session_id])
  end

  def report_group
    @group = SessionGroup.find(params[:group_id])
    @session_participations = SessionParticipation.where( :user_id => current_user.id, :session_id => @group.sessions.map(&:id))
  end


  def register
    # create session participation if there is enough space
    
    # anythinghere should not use cache and should be in one transaction
    @sessions = []

    SessionParticipation.uncached do 
      SessionParticipation.transaction do
        
        # if user wants to enroll in a single session...
        if @session
          # first check if there is enough space in the sessions - reload session from the database
          session = Session.find(@session.id)
          
          # if there is space
          if session.session_participations.count < session.needed + session.reserve
            # yes there is space - put the user in the session now
            @new_participations = [SessionParticipation.create(:session => session, :user => current_user)]
            @sessions = [session]
          end
        end
      
        # if user wants to enroll in a group...
        if @group
          # first check if there is enough space in the sessions - reload sessions from the database
          sessions = @group.sessions.includes(:session_participations)
          
          # randomized case
          if @group.is_randomized?
            # first take sessions which have space
            sessions_with_space = sessions.select do |session|
              session.session_participations.count < session.needed + session.reserve
            end

            # find sessionwith lowest count of participants
            min_session = sessions_with_space.min {|s1,s2| s1.session_participations.size <=> s2.session_participations.size}

            # if there is a session, put the user in
            if min_session
              @new_participations = [SessionParticipation.create(:session => min_session, :user => current_user)]
              @sessions = [min_session]
            end
          else
            # non randomized case - try to put the user in each session - if it fails, abort the transaction
            @new_participations = []
            @sessions = []
            sessions.each do |session|
              # if there is space
              if session.session_participations.count < session.needed + session.reserve
                @new_participations << SessionParticipation.create(:session => session, :user => current_user)
                @sessions << session
              else
                # if one session is already full, rollback
                @sessions = []
                raise ActiveRecord::Rollback
              end
            end
          end  
        end # if @group
      end # transaction
    end # uncached

    # send email on success
    if @sessions.size > 0
      # successful registration - send confirmation mail
      @first = @sessions.first
      e = @first.experiment

      subject = Task.replace(e.confirmation_subject.to_s, current_user, nil, @first)
      text = Task.replace(e.confirmation_text.to_s, current_user, nil, @first)

      # todo refactor this with proper i18n
      sessionlist_de =  @sessions.map{|s| s.start_at.strftime("%d.%m.%Y, %H:%M") + ' - ' + s.end_at.strftime("%H:%M Uhr") + (if s.location then " (#{t('controllers.enroll.location')} #{s.location.name.chomp})" else "" end) }.join("\n")
      sessionlist_en =  @sessions.map{|s| s.start_at.strftime("%Y-%m-%d, %H:%M") + ' - ' + s.end_at.strftime("%H:%M") + (if s.location then " (#{t('controllers.enroll.location')} #{s.location.name.chomp})" else "" end) }.join("\n")
            
      text = text.to_s.mreplace([
        ["#sessionlist_de", sessionlist_de],
        ["#sessionlist_en", sessionlist_en],
        ["#sessionlist", sessionlist_de]
      ])
            
      UserMailer.email(
        subject,
        text,
        current_user.main_email,
        e.sender_email_or_default
      ).deliver

      SentMail.create(
        :subject => subject,
        :message => text, 
        :from => e.sender_email_or_default,
        :to => current_user.main_email,
        :message_type => UserMailer::SESSION_CONFIRMATION,
        :user_id => current_user.id,
        :experiment_id => e.id,
        :sender_id => nil,
        :session_id => @first
      )
    else
      if @session
        # show report page for successful or unsuccessful session enrollment
        redirect_to enroll_report_session_path(:session_id => @session.id)
      elsif @group
        # show report page for successful or unsuccessful group enrollment
        redirect_to enroll_report_group_path(:group_id => @group.id)
      else
        # no enrollment, send back to start
        redirect_to enroll_path, :alert => t('controllers.enroll.notice_abort')
      end
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

  def load_session_or_group_and_participation
    ungrouped_sessions, session_groups = current_user.available_sessions

    # user has chosen a session?
    choice, id = params[:choice].split(',')

    if choice == 'session'
      # user has picked session, load it
      @session = Session.find_by_id(id.to_i)
    
      # check if it exists
      unless @session
        redirect_to enroll_path
        return 
      end
    
      # check that user is not already participating in that sessino
      @session_participation = SessionParticipation.find_by_user_id_and_session_id(current_user.id, @session.id)
      if @session_participation
        redirect_to enroll_path
        return
      end
    
      # check again if this session is available to enroll
      unless ungrouped_sessions.include?(@session)
        redirect_to enroll_path, :alert => t('controllers.enroll.notice_abort')
        return
      end
    elsif choice =='group'
      # user has picked a session group, load it together with its sessions
      @group = SessionGroup.where(:id => id.to_i).includes(:sessions).first

      # check if this was successfull
      unless @group
        redirect_to enroll_path
        return 
      end
    
      # ensure that user is not participant in any of the sessions of this group
      @session_participations = SessionParticipation.where(:user_id => current_user.id).where(:session_id => @group.sessions.collect(&:id)).count
      if @session_participations > 0
        redirect_to enroll_path
        return
      end
    
      # check again if this session group is available to enroll
      unless session_groups.include?(@group)
        redirect_to enroll_path, :alert => t('controllers.enroll.notice_abort')
        return
      end
    else
      redirect_to enroll_path
      return
    end
  end

end
