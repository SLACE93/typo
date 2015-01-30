Given /^some users, articles and comments has been created$/ do
  User.create!({:login => 'non_admin',
                :password => '123user',
                :email => 'boring@user.com',
                :profile_id => 2,
                :name => 'non admin',
                :state => 'active'})
  Article.create!({:id => 3,
                :title => 'Article 1',
                :author => 'admin',
                :user_id => 1,
                :body => 'A very fun first article',
                :allow_comments => true,
                :published => true,
                :published_at => Time.now,
                :state => 'published',
                :type => 'article'})
  Article.create!({:id => 4,
                :title => 'Article 2',
                :author => 'non_admin',
                :user_id => 2,
                :body => 'A very fun second article, hum?',
                :allow_comments => true,
                :published => true,
                :published_at => Time.now + 120,
                :state => 'published',
                :type => 'Article'})
  Comment.create!({:id => 1,
                :type => 'Comment',
                :author => 'non_admin',
                :user_id => 2,
                :body => 'Some blah blah',
                :article_id => 3,
                :created_at => Time.now + 240})
  Comment.create!({:id => 2,
                :type => 'Comment',
                :author => 'non_admin',
                :user_id => 2,
                :body => 'Some other blah blah',
                :article_id => 4,
                :created_at => Time.now + 240})
end

And /^I am logged in as "(.*?)" with password "(.*?)"$/ do |user,password|
  visit '/accounts/login'
  fill_in 'user_login', :with => user
  fill_in 'user_password', :with => password
  click_button 'Login'
  if page.respond_to? :should
    page.should have_content('Login successful')
  else
    assert page.has_content?('Login successful')
  end
end

And /^I merged article with id "(.*?)" with articled with id "(.*?)"$/ do |id,id_merge|
  article = Article.find_by_id(id)
  article.merge_with(id_merge)
end


And /^user "(.*?)" should have "(\d+)" articles$/ do |user,quantity|
  assert Article.find_all_by_author(user).size == Integer(quantity)
end

