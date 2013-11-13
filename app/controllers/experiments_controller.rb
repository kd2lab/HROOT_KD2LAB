#encoding: utf-8

class ExperimentsController < ApplicationController
  load_and_authorize_resource :except => :autocomplete_tags
  
  def index
    if current_user.admin?
      @experiments = Experiment.search(params[:search]).includes(:sessions)
        .order("experiments.finished, COALESCE(sessions.start_at, experiments.created_at) DESC")
        .paginate(:per_page => 30, :page => params[:page])  
    else
      @experiments = Experiment.search(params[:search]).includes(:sessions)
        .where(['experiments.id IN (SELECT experiment_id FROM experimenter_assignments WHERE user_id = ?)', current_user.id])
        .order("experiments.finished, COALESCE(sessions.start_at, experiments.created_at) DESC")
        .paginate(:per_page => 30, :page => params[:page])  
      
    end
  end

  def tag
    @tag = ActsAsTaggableOn::Tag.find(params[:tag])
    if current_user.admin?
      @experiments = Experiment.tagged_with(@tag.name).search(params[:search]).includes(:sessions)
        .order("experiments.finished, COALESCE(sessions.start_at, experiments.created_at) DESC")
        .paginate(:per_page => 30, :page => params[:page])  
    else
      @experiments = Experiment.tagged_with(@tag.name).search(params[:search]).includes(:sessions)
        .where(['experiments.id IN (SELECT experiment_id FROM experimenter_assignments WHERE user_id = ?)', current_user.id])
        .order("experiments.finished, COALESCE(sessions.start_at, experiments.created_at) DESC")
        .paginate(:per_page => 30, :page => params[:page])  
    end
    
    render :action => "index"
  end

  def new
    @experiment = Experiment.new
  end

  def edit

  end

  def create
    @experiment = Experiment.new(params[:experiment])
    @experiment.invitation_subject = Settings.invitation_subject
    @experiment.invitation_text = Settings.invitation_text
    @experiment.confirmation_subject = Settings.confirmation_subject
    @experiment.confirmation_text = Settings.confirmation_text
    @experiment.reminder_subject = Settings.reminder_subject
    @experiment.reminder_text = Settings.reminder_text
    
    if @experiment.save
      redirect_to experiment_sessions_path(@experiment), :notice => t('controllers.experiments.notice_created')
    else
      render :action => "new"
    end
  end
  
  def autocomplete_tags
    render :json =>  Experiment.tag_counts_on('tags').where(["name LIKE ?", params[:query]+'%']).collect{|e| e.name}
  end

  def experimenters
    if params[:commit]
      params[:rights] = {} unless params[:rights]
      
      # include empty rights lines
      if params[:user_submitted]
        params[:user_submitted].each do |user_id|
          unless params[:rights].keys.include?(user_id)
            params[:rights][user_id] = []
          end
        end
      end
      
      # experimenters may not change their own rights
      if current_user.experimenter?
        ExperimenterAssignment.update_experiment_rights @experiment, params[:rights], current_user.id
      else
        ExperimenterAssignment.update_experiment_rights @experiment, params[:rights]  
      end
      
      redirect_to experimenters_experiment_path(@experiment), :notice => t('controllers.notice_saved_changes')
    end  
  end  
  
  def update
    if params[:experiment][:tag_list]
      params[:experiment][:tag_list] = params[:experiment][:tag_list].join(", ")
    else
      params[:experiment][:tag_list] = ""
    end  
    
    if @experiment.update_attributes(params[:experiment])
      redirect_to edit_experiment_url(@experiment), :notice => t('controllers.notice_saved_changes')
    else
      render :action => "edit"
    end
  end

  def destroy
    @experiment.destroy
    redirect_to(experiments_url)
  end
  
  def enable
    @experiment.registration_active = true
    @experiment.save
    render :partial => "enrollment"
  end
  
  def disable
    @experiment.registration_active = false
    @experiment.save
    render :partial => "enrollment"
  end
  
  def invitation
    current_user.settings.templates = {} unless current_user.settings.templates

    # stop invitation
    if params[:stop]
      @experiment.invitation_start = nil
      @experiment.save
    end
      
    # start invitation
    if params[:experiment] && @experiment.update_attributes(params[:experiment])
      @experiment.registration_active = true
      @experiment.invitation_start = Time.zone.now
      @experiment.save
      
      if params[:button] == 'send_all'
        @experiment.participations.where("invited_at IS NOT NULL").each do |p|
          p.invited_at = nil
          p.save
        end
      end
      redirect_to invitation_experiment_path
    end
  end
  
  def save_mail_text
    render :text => t('controllers.notice_saved_changes')
  end
  
  def reminders
   
    if params[:experiment]
      params[:experiment][:reminder_hours] = 48 if params[:experiment][:reminder_hours].to_i == 0
       
      if @experiment.update_attributes(params[:experiment])
        flash[:notice] = t('controllers.notice_saved_changes')
      end
    end
  end
  
  def mail
    if params[:experiment] && @experiment.update_attributes(params[:experiment])
      flash[:notice] = t('controllers.notice_saved_changes')
    end
  end
  
  def start
    redirect_to :action => 'invitation'
  end
  
  def files
    
  end
  
  def filelist
    # todo make this configurable
    dirname = File.dirname(Rails.root.join('uploads', 'experiments', @experiment.id.to_s, 'some_file_name'))
    unless File.directory?(dirname)
      FileUtils.mkdir_p(dirname)
    end
    
    Dir.chdir(dirname);
    
    result = '<ul class="jqueryFileTree" style="display: none;">'
    
		#loop through all directories
		Dir.glob("*") {
			|x|
			if not File.directory?(x.untaint) then next end 
			result+= "<li class=\"directory collapsed\"><a href=\"#\" rel=\"#{dirname}#{x}/\">#{x}</a></li>";
		}

		#loop through all files
		Dir.glob("*") {
			|x|
			if not File.file?(x.untaint) then next end 
			ext = File.extname(x)[1..-1]
			result += "<li class=\"file ext_#{ext}\"><a href=\"#\" rel=\"#{dirname}#{x}\">#{x}</a></li>"
		}
    
    result += "</ul>"
    
    render :text => result
  end  
  
  def upload_via_form
    puts params.inspect
    if (upload_file(params[:file]))
      redirect_to({:action => 'files'}, :notice => t('controllers.experiment.upload_success'))
    else  
      redirect_to({:action => 'files'}, :notice => t('controllers.experiment.upload_failure'))
    end
  end

  def upload
    if (upload_file(params[:file]))
      render :json => { :result => 'ok'}
    else
      render :json => { :result => 'error'}
    end      
  end

  
  private
  
  def upload_file(file)
    require 'fileutils'

    # create path, if not exists
    dirname = File.join(Rails.configuration.upload_dir, 'experiments', @experiment.id.to_s)
    unless File.directory?(dirname)
      FileUtils.mkdir_p(dirname)
    end
    
    # check if uploaded file exists
    uploaded_file = file
    if uploaded_file
      # sanitize path name, cleanpath removes something/../something
      upload_file_path = Pathname(File.join(dirname, uploaded_file.original_filename)).cleanpath.to_s
      
      # check if final upload filename is in upload dir
      if upload_file_path[0..dirname.length-1] == dirname  
        File.open(upload_file_path, 'wb') do |file|
          file.write(uploaded_file.read)
        end
        return true
      else
        return false
      end
    else
      return false  
    end
    
  end
  
  
end
