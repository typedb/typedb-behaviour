# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Relation Inference Resolution

  Background: Set up database
    Given typedb starts
    Given connection opens with default authentication
    Given reasoning schema
      """
      define

      person sub entity,
        owns name,
        plays friendship:friend,
        plays employment:employee;

      company sub entity,
        owns name,
        plays employment:employer;

      place sub entity,
        owns name,
        plays location-hierarchy:subordinate,
        plays location-hierarchy:superior;

      friendship sub relation,
        relates friend;

      employment sub relation,
        relates employee,
        relates employer;

      location-hierarchy sub relation,
        relates subordinate,
        relates superior;

      name sub attribute, value string;
      """
    # each scenario specialises the schema further

  # nth triangle number = sum of all integers from 1 to n, inclusive
  Scenario: when inferring relations on all pairs from n concepts, the number of relations is the nth triangle number
    Given reasoning schema
      """
      define
      rule everyone-is-my-friend-including-myself: when {
        $x isa person;
        $y isa person;
      } then {
        (friend: $x, friend: $y) isa friendship;
      };
      """
    Given reasoning data
      """
      insert
      $a isa person, has name "Abigail";
      $b isa person, has name "Bernadette";
      $c isa person, has name "Cliff";
      $d isa person, has name "Damien";
      $e isa person, has name "Eustace";
      """
    Given verifier is initialised
    Given reasoning query
      """
      match $r isa friendship;
      """
    # When there is 1 concept we have {aa}.
    # Adding a 2nd concept gives us 2 new relations - where each relation contains b, and one other concept (a or b).
    # Adding a 3rd concept gives us 3 new relations - where each relation contains c, and one other concept (a, b or c).
    # Generally, the total number of relations is the sum of all integers from 1 to n inclusive.
    Then verify answer size is: 15
    Then verify answers are sound
    Then verify answers are complete


  Scenario: when matching all possible pairs inferred from n concepts, the answer size is the square of n
    Given reasoning schema
      """
      define
      rule everyone-is-my-friend-including-myself: when {
        $x isa person;
        $y isa person;
      } then {
        (friend: $x, friend: $y) isa friendship;
      };
      """
    Given reasoning data
      """
      insert
      $a isa person, has name "Abigail";
      $b isa person, has name "Bernadette";
      $c isa person, has name "Cliff";
      $d isa person, has name "Damien";
      $e isa person, has name "Eustace";
      """
    Given verifier is initialised
    Given reasoning query
      """
      match ($x, $y) isa friendship;
      """
    # Here there are n choices for x, and n choices for y, so the total answer size is n^2
    Then verify answer size is: 25
    Then verify answers are sound
    Then verify answers are complete

