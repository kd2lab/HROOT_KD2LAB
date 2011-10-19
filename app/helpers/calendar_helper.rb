module CalendarHelper
  def month_link(month_date)
    link_to(I18n.localize(month_date, :format => "%B"), {:month => month_date.month, :year => month_date.year})
  end
  
  # custom options for this calendar
  def event_calendar_opts
    { 
      :year => @year,
      :month => @month,
      :event_strips => @event_strips,
      :month_name_text => I18n.localize(@shown_month, :format => "%B %Y"),
      :previous_month_text => "<< " + month_link(@shown_month.prev_month),
      :next_month_text => month_link(@shown_month.next_month) + " >>",
      :first_day_of_week => 1,
      :height => 400,
      :event_height => 20,
      :event_margin => 1,
      :event_padding_top => 2,
      :day_names_height => 30
    }
  end

  def event_calendar
    # args is an argument hash containing :event, :day, and :options
    calendar(event_calendar_opts) do |args|
      session = args[:event]
      %(<div class="event-qtip"
          data-title="#{session.experiment.name}"
          data-exptype="#{session.experiment.experiment_type.name if session.experiment.experiment_type}"
          data-location="#{session.location.name if session.location}"
          data-expid="#{session.experiment.id}"
          data-sessionid="#{session.id}"
          data-count="#{session.participations.count} (#{session.needed},#{session.reserve})"
          data-exp="#{session.experiment.experimenters.collect{|u| u.firstname[0]+". "+u.lastname}.join(' | ')}">
          <div style="float:right">
            <a href="">#{image_tag("group.png")}</a>
          </div>
          <a href="#{edit_experiment_session_path(session.experiment, session)}">#{session.start_at.strftime("%H:%M")}</a>
          <a href="#{edit_experiment_path(session.experiment)}">#{h(truncate(session.experiment.name, :length => 8))}</a>
          </div>)
    
    #<a href="/admin/experiments/#{session.experiment.id}/edit" title="#{h(session.experiment.name)}">  ...... </a>
    end
  end
end
