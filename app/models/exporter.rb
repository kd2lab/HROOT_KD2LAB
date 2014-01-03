class Exporter
	extend ActionView::Helpers::NumberHelper

	def self.get_header_data(users, columns)
		# header row
	    header = []
	    columns.each do |col|
	      case col
	      when :id
	        header << "ID"
	      when :counter
	        header << ""
	      when :fullname
	        header << I18n.t('usertable.fullname')
	      when :noshow_count
	        header << I18n.t('noshow_shortcut')
	      when :participations_count
	        header << I18n.t('participations_shortcut')
	      else
	        field = CUSTOM_FIELDS.get(col)
	        if field
	          header << I18n.t("activerecord.attributes.user.#{field.name}")
	        else
	          header <<  I18n.t('usertable.'+col.to_s)
	        end
	      end
	    end
	    header
	end

	def self.get_table_data(users, columns)
		# data rows
	    lines = []
	    users.each_with_index do |user, i| 
	      line = []
	      
	      columns.each do |col|
	        case col
	        when :showup
	        	line << user.session_showup
	        when :participated
	        	line << user.session_participated
	        when :noshow
	        	line << user.session_noshow
	        when :payment
	        	line << number_with_precision(user.payment.to_f, separator: '.', precision: 2)
	        when :session
	        	line << "#{I18n.l(user.session_start_at) if user.session_start_at}" 
	        when :deleted
	          line << (user.deleted ? 1 : 0)
	        when :id
	          line << user.id
	        when :counter
	          line << (i+1)
	        when :fullname
	          line << user.lastname+', '+user.firstname
	        when :role  
	          line <<{'user' => 'P', 'experimenter' => 'E', 'admin' => 'A'}[user.role]
	        when :email
	          line << user.email
	        when :noshow_count
	          line << "#{user.noshow_count}" 
	        when :participations_count
	           line <<"#{user.participations_count}"
	        when :created_at
	           line << I18n.l(user.created_at, :format => :date_only)
	        else
	          field = CUSTOM_FIELDS.get(col)
	          if field
	            line << field.display_value(user)
	          else
	            line << user[col]
	          end
	        end
	      end
	      lines << line
	    end
	    lines
	end

	def self.to_csv(users, columns)
		require 'csv'
	  
	    csv_str = CSV.generate({:force_quotes=>true}) do |csv|
	      csv << get_header_data(users, columns)
	      lines = get_table_data(users, columns)
	      lines.each do |line|
	      	csv << line
	      end
	 	end
	    
	 	csv_str
    end

    def self.to_excel(users, columns)
    	book = Spreadsheet::Workbook.new
    	sheet = book.create_worksheet
    	
    	sheet.row(0).concat get_header_data(users, columns)
    	get_table_data(users, columns).each_with_index do |line, i|
	      	sheet.row(i+1).concat line
	    end
	    
        buffer = StringIO.new
    	book.write(buffer)
    	buffer.rewind
    	return buffer.read
    end
end