Feature:
  As a founder
  I want to know when a founding vote fails
  In order to know respond to it
  
  
  Scenario: failing vote should show notification
    
    Given an organisation exists
    And 3 members exist with organisation: the organisation
    And I am logged in as the 1st member
    When I start a founding vote
    And I decline the vote
    And I am logged in as the 2nd member
    And I decline the vote
    And I am logged in as the 3rd member
    And I decline the vote
    And I am logged in as the 1st member
    Then I should see "Sorry, the founding vote has failed"
    
    When I start a founding vote
    And I decline the vote
    And I am logged in as the 2nd member
    And I decline the vote
    And I am logged in as the 3rd member
    And I decline the vote
    And I am logged in as the 1st member
    Then I should see "Sorry, the founding vote has failed"
    