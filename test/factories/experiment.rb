Factory.define :experiment do |e|
  e.sequence(:name) {|n| "Experiment #{n}"}
  e.invitation_hours 1
  e.invitation_size 2
end
