#encoding: utf-8

class Session < ActiveRecord::Base
  has_event_calendar

  belongs_to :experiment
  belongs_to :location
  belongs_to :session_group
  has_many :session_participations

  validates_presence_of :start_at
  validates_presence_of :end_at

  validates_numericality_of :needed, :only_integer => true
  validates_numericality_of :reserve, :only_integer => true

  scope :in_the_future, lambda {
    where("start_at > NOW()")
  }

  scope :in_the_past, lambda {
    where("end_at < NOW()")
  }

  def self.session_times
    (0..23).to_a.product(["00","15","30","45"]).collect{|t| ("%02d:%02d" % t)}
  end

  def start_date
    I18n.l(start_at.to_date) if start_at
  end

  def duration
    begin
      (end_at - start_at).round / 60
    rescue
      90
    end
  end

  def self.remove_members_from_sessions(members, experiment)
    members.each do |id|
      if u = User.find(id)
        SessionParticipation.where(:user_id => u.id, :session_id => experiment.sessions).delete_all
      end
    end
  end

  def self.move_members(members, experiment, target)
    members.each do |id|
      if u = User.find(id)
        # remove user from any sessions he is in
        SessionParticipation.where(:user_id => u.id, :session_id => experiment.sessions).delete_all

        # put member in target session
        if target.kind_of?(Session)
          SessionParticipation.create(:user => u, :session => target)
        else
          # if the target is a session group, put the user in all sessions of the group
          if target.signup_mode == SessionGroup::USER_VISITS_ALL_SESSIONS_OF_GROUP
            target.sessions.each do |s|
              SessionParticipation.create(:user => u, :session => s)
            end
          end
        end
      end
    end
  end

  def full_name
    experiment.name+' ('+self.time_str+')'
  end

  def time_str
    I18n.l(start_at) + ' - ' + I18n.l(end_at, :format => :time_only)
  end

  def only_time_str
    I18n.l(start_at, :format => :time_only) + ' - ' + I18n.l(end_at, :format => :time_only)
  end

  def folder_str
    start_at.strftime("%Y-%m-%d_%H%M")
  end

  def self.find_overlapping_sessions_by_date(date, duration, location_id, session_id, time_before, time_after)
    sql = <<EOSQL
      SELECT * FROM sessions
      WHERE DATE_ADD(end_at,   INTERVAL time_after  MINUTE) > DATE_SUB('#{date.strftime("%Y-%m-%d %H:%M:%S")}', INTERVAL #{time_before.to_i} MINUTE)
      AND   DATE_SUB(start_at, INTERVAL time_before MINUTE) < DATE_ADD('#{(date+duration.to_i.minutes).strftime("%Y-%m-%d %H:%M:%S")}', INTERVAL #{time_after.to_i} MINUTE)
      AND location_id = #{location_id.to_i}
EOSQL
    sql += " AND id<>#{session_id.to_i}" if session_id.to_i > 0
    Session.find_by_sql(sql)
  end

  def self.find_overlapping_sessions(year, month)
    sql = <<EOSQL
      SELECT DISTINCT s.*,
      ( SELECT GROUP_CONCAT(s2.id)
        FROM sessions s2
        WHERE DATE_ADD(s2.end_at,   INTERVAL s2.time_after  MINUTE) > DATE_SUB(s.start_at, INTERVAL s.time_before MINUTE)
        AND   DATE_SUB(s2.start_at, INTERVAL s2.time_before MINUTE) < DATE_ADD(s.end_at,   INTERVAL s.time_after  MINUTE)
        AND s.id < s2.id
        AND s.location_id = s2.location_id)
      AS overlap_ids
      FROM sessions s
      WHERE s.end_at IS NOT NULL
      AND MONTH(s.start_at) = #{month.to_i} AND YEAR(s.start_at) = #{year.to_i}
      HAVING overlap_ids IS NOT NULL;
EOSQL
    Session.find_by_sql(sql)
  end

  def space_left
    needed + reserve - session_participations.count
  end

  def self.incomplete_sessions
    # load sessions in the past with incomplete lists
    Session.in_the_past.where('(SELECT count(s.id) FROM session_participations s WHERE s.session_id=sessions.id AND showup=false AND participated=false AND noshow=false) >0')
  end

  def has_no_participants?
    return !has_participants?
  end

  def has_participants?
    return session_participations.count != 0
  end

  def path
    File.join(Rails.configuration.upload_dir, 'experiments', experiment.id.to_s, "session__#{id}")
  end

  def has_files?
    !Dir[path+'/*'].empty?
  end

  def remove_folder
    require 'fileutils'
    FileUtils.rmdir(path)
  end

  def to_s
    self.time_str
  end
end
