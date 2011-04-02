Given /^(?:|I ) log in as #{capture_model} with password: (.*)$/ do |user, password|
  user = model!(user)
  visit path_to(page_name)
end

Given /^(?:|I ) fill in as #{capture_model} with password: (.*)$/ do |user, password|
  Given 'I am logged in as "" and password "" '
  user = model!(user)
  visit path_to(page_name)
end


Email
