Feature: Create and Edit Categories
    As a blog administrator
    In order to organize the articles
    I want to be able to create new categories and assign articles to them

    Background:
        Given the blog is set up
        And I am logged into the admin panel
        When I follow "Categories"

    Scenario: Categories page shown
        Then I should see "Categories"
        And I should see "Name"
        And I should see "Keywords"
        And I should see "Permalink"

    Scenario: Successfully create category
        When I fill in "Name" with "NewCategory"
        And I press "Save"
        Then I should see "NewCategory"
        And I should see "no articles"

    Scenario: Successfully edit existing category
        When I follow "General"
        Then I fill in "Description" with "test description"
        And I press "Save"
        Then I should see "test description"
