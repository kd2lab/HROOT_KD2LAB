Factory.define :location do |e|
  e.sequence(:name) {|n| "Location #{n}"}
end