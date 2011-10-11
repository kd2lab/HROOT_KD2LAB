Factory.define :experiment do |e|
  e.sequence(:name) {|n| "Experiment #{n}"}
end
