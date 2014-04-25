#encoding: utf-8

class ExperimentsController < ApplicationController
  load_and_authorize_resource :except => :autocomplete_tags
  
  def index
    if current_user.admin?
      @experiments = Experiment.search(params[:search]).includes(:sessions, :tags)
        .order("experiments.finished, COALESCE(sessions.start_at, experiments.created_at) DESC")
        .paginate(:per_page => 30, :page => params[:page])  
    else
      @experiments = Experiment.search(params[:search]).includes(:sessions, :tags)
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
      if current_user.can_create_experiment
        ExperimenterAssignment.create(:experiment_id => @experiment.id, :user_id => current_user.id, :rights => ExperimenterAssignment.right_keys.join(','))
      end
      redirect_to reminders_experiment_path(@experiment), :notice => t('controllers.experiments.notice_created')
    else
      render :action => "new"
    end
  end
  
  def autocomplete_tags
    render :json =>  Experiment.tag_counts_on('tags').where(["name LIKE ?", params[:query]+'%']).collect{|e| e.name}
  end

  def experimenters
    unless params[:privileges]
      params[:privileges] = []

      @experiment.experimenter_assignments.each do |assign|
        params[:privileges] << {:id => assign.user_id, :name => assign.user.lastname+', '+assign.user.firstname, :list => assign.rights.split(',')}
      end
    end


    if params[:commit]
      if current_user.experimenter?
        ExperimenterAssignment.update_experiment_rights @experiment, params[:privileges], current_user.id
      else
        ExperimenterAssignment.update_experiment_rights @experiment, params[:privileges]  
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
    if @experiment.sessions.count == 0 && @experiment.participations.count == 0
      @experiment.destroy
      redirect_to(experiments_url)
    else
      redirect_to(experiments_url, :notice => I18n.t('controllers.notice_cant_delete_experiment'))
    end  
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

  def public_link

  end

  def message_history
    if params[:mail]
      mail = SentMail.where(:id => params[:mail]).first
      render :json => {:subject => mail.subject, :message => help.simple_format(mail.message)}
    end
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
    @experiment.sessions.each do |session|
      realpath, relpath = get_valid_dir("session__#{session.id}") 
      FileUtils::mkdir(realpath) unless File.exists?(realpath)
    end    
  end
  
  # ------ file display

  
  # todo later - do not user template
  def filelist
    realpath, relpath = get_valid_dir(params[:dir] || '')

    if realpath && File.exists?(realpath)
      Dir.chdir(realpath);
    
      @dirnames = []
      @filenames = []
    
      Dir.glob("*") { |x|
        if not File.directory?(x.untaint) then next end 
        @dirnames << x
      }
    
      Dir.glob("*") { |file|
        if not File.file?(file.untaint) then next end 
        @filenames << file
      }
    
      render :partial => 'filelist', :locals => {:dir => relpath}
    end
  end  
  


  # --------------------------- File handling ----------------------------------------


  # -------------------- sanitation ---------------------

  

  # ------ Operations

  def new_folder
    # sanizie param
    realpath, relpath = get_valid_dir(params[:parent]+params['dirname'])
    
    if realpath
      FileUtils::mkdir realpath unless File.exists?(realpath)
    end
    
    render :json => {:result => "ok"}
  end

  def delete
    require 'fileutils'
    
    result = ''

    # first delete all files
    params[:files].each do |i, f|
      # sanitation
      realpath, relpath = get_valid_filename(f[:path], f[:file])     
      
      if !File.directory?(realpath)
        if File.exist?(realpath)
          File.delete(realpath) 
        else
          result += "#{relpath}: #{I18n.t('upload.cant_delete_file')}\n"
        end
      end
    end
    
    # then try to delete dirs
    params[:files].each do |i, f|
      # sanitation
      realpath, relpath = get_valid_filename(f[:path], f[:file])     
      
      if File.directory?(realpath) && !(relpath =~ /session__(\d)+\/?$/)
        if Dir[realpath+'*'].empty? 
          FileUtils.rmdir(realpath)
        else
          result += "#{relpath}: #{I18n.t('upload.cant_delete_nonempty_folder')}\n"  
        end
      end
    end
    
    render :text => result
  end

  def upload_via_form
    if upload_file(params[:file], params[:path])
      redirect_to(files_experiment_url(@experiment), :notice => t('upload.upload_success'))
    else  
      redirect_to(files_experiment_url(@experiment), :alert => t('upload.upload_failure'))
    end
  end

  def upload
    if upload_file(params[:file], params['dir'])
      render :json => { :result => 'ok'}
    else
      render :json => { :result => 'error'}
    end      
  end

  def move
    # things to check: dirs should not be move in same dir or lower
    # files should not be moved if parent folder ist supposed to be moved

    real_target_path, rel_target_path =get_valid_dir(params[:target_path])

    sanitized_dirs = []
    sanitized_files = []

    params[:files].each do |i, f|
      # sanitation
      realpath, relpath = get_valid_filename(f[:path], f[:file])         
      if File.directory?(realpath)
        sanitized_dirs << realpath
      else
        sanitized_files << realpath
      end
    end

    # keep only dirs, which are not subdirs of other dirs
    kept_dirs = sanitized_dirs.select do |p|
      prefixes = sanitized_dirs.select do |p2| p.start_with?(p2) && p != p2 end
      prefixes.length == 0 && !real_target_path.start_with?(p)
    end   
  

    # keep only files, if they are not part of a moved dir
    kept_files = sanitized_files.select do |p|
      prefixes = sanitized_dirs.select do |p2| p.start_with?(p2) end
      prefixes.length == 0
    end   

    kept_dirs.each do |dir|
      begin
        FileUtils.mv(dir, real_target_path)
      rescue
      end
    end

    kept_files.each do |file|
      begin
        FileUtils.mv(file, real_target_path)
      rescue
      end
    end

    render :text => "ok"
  end
  
  def download
    require 'tempfile'
    require 'zip'

    session_lookup = Hash.new
    @experiment.sessions.each{|s| session_lookup["session__#{s.id}"] = s.folder_str}
      
    files = JSON.parse(params[:files])

    if files.length == 1
      realpath, relpath = get_valid_filename(files[0]["path"], files[0]["file"])
      if !File.directory?(realpath)
        send_file realpath, :x_sendfile=>true
        return
      end
    end

    begin
      folder_name = @experiment.name.parameterize
      tempfile = Tempfile.new('hroot')
     
      #Initialize the temp file as a zip file
      Zip::OutputStream.open(tempfile) { |zos| }
 
      #Add files to the zip file as usual
      Zip::File.open(tempfile.path, Zip::File::CREATE) do |zip|
        files.each do |f|
          realpath, relpath = get_valid_filename(f["path"], f["file"])

          if File.directory?(realpath)
            destpath = "#{folder_name}/"+relpath  
            destpath = destpath.mreplace(session_lookup)  
            zip.add(destpath,realpath)
            Dir[File.join(realpath, '**', '**')].each do |file|
              begin
                destpath = "#{folder_name}/"+file.sub(realpath,relpath)
                destpath = destpath.mreplace(session_lookup)
                zip.add(destpath,file)
              rescue
              end
            end
          elsif File.file?(realpath)
            begin
              destpath = "#{folder_name}/"+relpath  
              destpath = destpath.mreplace(session_lookup)
              zip.add(destpath, realpath)
            rescue
            end
          end
        end
      end
 
      #Read the binary data from the file
      zip_data = File.read(tempfile.path)
 
      #Send the data to the browser as an attachment
      #We do not send the file directly because it will
      #get deleted before rails actually starts sending it
      send_data(zip_data, :type => 'application/zip', :filename => "#{folder_name}.zip")
    ensure
      #Close and delete the temp file
      tempfile.close
      tempfile.unlink
    end  
  end


  private

  def sanitize_filename(filename)
    filename = '' unless filename

    # remove any slashes
    filename.gsub!(/^.*(\\|\/)/, '')

    # Strip out the non-ascii character
    filename.gsub!(/[^0-9A-Za-z.\-\(\)]/, '_')

    filename
  end

  def basedir
    # create basedir if not exists
    base = File.join(Rails.configuration.upload_dir, 'experiments', @experiment.id.to_s)
    FileUtils::mkdir_p base unless File.exists?(base)
    base
  end

  def get_valid_filename(path, filename)
    # sanitize param
    realpath, relpath = get_valid_dir(path)
    filename = sanitize_filename(filename)

    if realpath
      if relpath.blank?
        return "#{realpath}/#{filename}", "#{filename}"
      else
        return "#{realpath}/#{filename}", "#{relpath}/#{filename}"
      end
    else
      return false, false
    end
  end

  def get_valid_dir(rel_path)
    rel_path = '' unless rel_path
    base = basedir

    # create a clean path without .. and // 
    p = Pathname.new(File.join(base, rel_path)).cleanpath

    # allow only absolute paths which resemble a directory
    if p.absolute? 
      # allow only paths, which have the base path as prefix
      if p.to_s[0..base.length-1] == base
        # return real path and relative path
        return p.to_s, p.to_s.slice((base.length+1)..-1)
      end
    end

    return false, false
  end
  
  def upload_file(file, target_dir)
    realpath, relpath = get_valid_dir(target_dir)

    if realpath && File.directory?(realpath)
      if file
        real_filepath, rel_filepath = get_valid_filename(target_dir, file.original_filename)

        if real_filepath
          File.open(real_filepath, 'wb') do |f|
            f.write(file.read)
          end
          return true
        end
      end      
    end

    return false
  end


  # access to text helpers - without polluting the namespace
  def help
    Helper.instance
  end

  class Helper
    include Singleton
    include ActionView::Helpers::TextHelper
  end
  
end
