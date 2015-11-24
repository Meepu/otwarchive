When /^I view the series "([^\"]*)"$/ do |series|
  visit series_url(Series.find_by_title!(series))
end

When /^I add the series "([^\"]*)"$/ do |series_title|
  check("series-options-show")  
  if Series.find_by_title(series_title)
    step %{I select "#{series_title}" from "work_series_attributes_id"}
  else
    fill_in("work_series_attributes_title", :with => series_title)
  end
end

When /^I add the work "([^\"]*)" to series "([^\"]*)"(?: as "([^"]*)")?$/ do |work_title, series_title, pseud|
  work = Work.find_by_title(work_title)
  if work.blank?
    step "the draft \"#{work_title}\""
    work = Work.find_by_title(work_title)
    visit preview_work_url(work)
    click_button("Post")
    step "I should see \"Work was successfully posted.\""
    Work.tire.index.refresh
  end
  
  step "I edit the work \"#{work_title}\""

  unless pseud.blank?
    step %{I create the pseud "#{pseud}"}
    select(pseud, :from => "work_author_attributes_ids_")
  end
  
  step %{I add the series "#{series_title}"}
  click_button("Post Without Preview")
end

When /^I add the draft "([^\"]*)" to series "([^\"]*)"$/ do |work_title, series_title|
  step %{I edit the work "#{work_title}"}
  step %{I add the series "#{series_title}"}
  click_button("Save Without Posting")
end

When /^I add the work "([^\"]*)" to "(\d+)" series "([^\"]*)"$/ do |work_title, count, series_title|
  work = Work.find_by_title(work_title)
  if work.blank?
    step "the draft \"#{work_title}\""
    work = Work.find_by_title(work_title)
    visit preview_work_url(work)
    click_button("Post")
    step "I should see \"Work was successfully posted.\""
    Work.tire.index.refresh
  end
  
  count.to_i.times do |i|
    step "I edit the work \"#{work_title}\""
    check("series-options-show")
    fill_in("work_series_attributes_title", :with => series_title + i.to_s)
    click_button("Post Without Preview")
  end
end

Then /^the series "(.*)" should be deleted/ do |series|
  assert Series.where(title: series).first.nil?
end

Then /^the work "([^\"]*)" should be part of the "([^\"]*)" series in the database$/ do |work_title, series_title|
  work = Work.find_by_title(work_title)
  series = Series.find_by_title(series_title)
  assert SerialWork.where(series_id: series, work_id: work).exists?
end

Then /^the work "([^\"]*)" should not be visible on the "([^\"]*)" series page$/ do |work_title, series_title|
  work = Work.find_by_title(work_title)
  series = Series.find_by_title(series_title)
  visit series_path(series)
  page.should_not have_content(work_title)
end

Then /^the series "([^\"]*)" should not be visible on the "([^\"]*)" work page$/ do |series_title, work_title|
  work = Work.find_by_title(work_title)
  series = Series.find_by_title(series_title)
  visit work_path(work)
  page.should_not have_content(series_title)
end

Then /^the work "([^\"]*)" should be visible on the "([^\"]*)" series page$/ do |work_title, series_title|
  work = Work.find_by_title(work_title)
  series = Series.find_by_title(series_title)
  visit series_path(series)
  page.should have_content(work_title)
end

Then /^the series "([^\"]*)" should be visible on the "([^\"]*)" work page$/ do |series_title, work_title|
  work = Work.find_by_title(work_title)
  series = Series.find_by_title(series_title)
  visit work_path(work)
  page.should have_content(series_title)
  page.should have_content("Part #{SerialWork.where(series_id: series, work_id: work).first.position}")
end

Then /^the neighbors of "([^\"]*)" in the "([^\"]*)" series should link over it$/ do |work_title, series_title|
  work = Work.find_by_title(work_title)
  series = Series.find_by_title(series_title)
  position = SerialWork.where(series_id: series, work_id: work).first.position
  neighbors = SerialWork.where(series_id: series, position: [position-1, position+1])
  neighbors.each_with_index do |neighbor, index|
    visit work_path(neighbor.work)
    page.should_not have_content(work_url(work))
    # instead the neighbors should link to each other if they both exist
    if neighbors.count > 1 && index == 0
      page.should have_content("&raquo;")      
      page.should have_content(work_url(neighbors[1].work))
    elsif neighbors.count > 1 && index == 1
      page.should have_content("&laquo;")      
      page.should have_content(work_url(neighbors[0].work))
    end
  end  
end

Then /^the neighbors of "([^\"]*)" in the "([^\"]*)" series should link to it$/ do |work_title, series_title|
  work = Work.find_by_title(work_title)
  series = Series.find_by_title(series_title)
  position = SerialWork.where(series_id: series, work_id: work).first.position
  neighbors = SerialWork.where(series_id: series, position: [position-1, position+1])
  neighbors.each do |neighbor|
    visit work_path(neighbor.work)
    page.should have_content(work_url(work))
    if neighbor.position > position
      page.should have_content("&laquo;")
    else      
      page.should have_content("&raquo;")
    end
  end
end
