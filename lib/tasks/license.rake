require 'gem_licenses'
 
task :licenses do
  Gem.licenses.each do |license, gems|
    puts "#{license}"
    gems.sort_by { |gem| gem.name }.each do |gem|
      puts "* #{gem.name} #{gem.version} (#{gem.homepage}) - #{gem.summary}"
    end
  end
end