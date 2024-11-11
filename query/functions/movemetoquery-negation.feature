# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Negation Resolution

  Background: Set up database
    Given typedb starts
    Given connection opens with default authentication
    Given reasoning schema
      """
      define

      person sub entity,
        owns name,
        owns age,
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
      age sub attribute, value long;
      """
    # each scenario specialises the schema further

  # TODO: This section needs to be moved to the regular query feature

  #####################
  # NEGATION IN MATCH #
  #####################

  # Negation is currently handled by Reasoner, even inside a match clause.

  Scenario: negation can check that an entity does not play a specified role in any relation
    Given reasoning data
    """
      insert
      $x1 isa person;
      $x2 isa person;
      $x3 isa person;
      $x4 isa person;
      $x5 isa person;
      $c isa company, has name "Amazon";
      $e1 (employee: $x1, employer: $c) isa employment;
      $e2 (employee: $x2, employer: $c) isa employment;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match $x isa person;
      """
    Then verify answer size is: 5
    Given reasoning query
      """
      match
        $x isa person;
        not {
          $e (employee: $x) isa employment;
        };

      """
    Then verify answer size is: 3


  Scenario: negation can check that an entity does not play any role in any relation
    Given reasoning data
      """
      insert
      $x1 isa person;
      $x2 isa person;
      $x3 isa person;
      $x4 isa person;
      $x5 isa person;
      $c isa company, has name "Amazon";
      $e1 (employee: $x1, employer: $c) isa employment;
      $e2 (employee: $x2, employer: $c) isa employment;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match $x isa person;
      """
    Then verify answer size is: 5
    Given reasoning query
      """
      match
        $x isa person;
        not {
          ($x) isa relation;
        };

      """
    Then verify answer size is: 3


  Scenario: negation can check that an entity does not own any instance of a specific attribute type
    Given reasoning data
      """
      insert
      $x1 isa person, has name "asdf";
      $x2 isa person, has name "cgt";
      $x3 isa person;
      $x4 isa person, has name "bleh";
      $x5 isa person;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match $x isa person;
      """
    Then verify answer size is: 5
    Given reasoning query
      """
      match
        $x isa person;
        not {
          $x has name $val;
        };

      """
    Then verify answer size is: 2


  Scenario: negation can check that an entity does not own a particular attribute
    Given reasoning data
      """
      insert
      $x1 isa person, has name "Bob";
      $x2 isa person, has name "cgt";
      $x3 isa person;
      $x4 isa person, has name "bleh";
      $x5 isa person;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match $x isa person;
      """
    Then verify answer size is: 5
    Given reasoning query
      """
      match
        $x isa person;
        not {
          $x has name "Bob";
        };

      """
    Then verify answer size is: 4


  Scenario: negation can check that an entity owns an attribute which is not equal to a specific value
    Given reasoning data
    """
      insert
      $x isa person, has age 10;
      $y isa person, has age 20;
      $z isa person;
      """
    Given verifier is initialised
    Given reasoning query
    """
      match
        $x has age $y;
        not {$y 20;};

      """
    Then verify answer size is: 1
    Then verify answer set is equivalent for query
      """
      match
        $x has age $y;
        $y 10;

      """


  Scenario: negation can check that an entity owns an attribute that is not of a specified type
    Given reasoning data
    """
      insert
      $x isa person, has age 10, has name "Bob";
      $y isa person, has age 20;
      $z isa person;
      $w isa person, has name "Charlie";
      """
    Given verifier is initialised
    Given reasoning query
    """
      match
        $x has attribute $y;
        not {$y isa name;};

      """
    Then verify answer size is: 2
    Then verify answer set is equivalent for query
      """
      match $x has age $y;
      """


  Scenario: negation can filter out an unwanted entity type from part of a chain of matched relations
    Given reasoning schema
      """
      define
      dog sub entity, plays friendship:friend;
      """
    Given reasoning data
      """
      insert
      $a isa person;
      $b isa person;
      $c isa person;
      $d isa person;
      $z isa dog;

      (friend: $a, friend: $b) isa friendship;
      (friend: $b, friend: $c) isa friendship;
      (friend: $c, friend: $d) isa friendship;
      (friend: $d, friend: $z) isa friendship;
      """
    Given verifier is initialised
    Given reasoning query
    """
      match
        (friend: $a, friend: $b) isa friendship;
        (friend: $b, friend: $c) isa friendship;
        (friend: $c, friend: $d) isa friendship;

      """
    # abab, abcb, abcd,
    # baba, babc, bcba, bcbc, bcdc, bcdz,
    # cbab, cbcb, cbcd, cdcb, cdcd, cdzd,
    # dcba, dcbc, dcdc, dcdz, dzdc, dzdz,
    # zdcb, zdcd, zdzd
    Then verify answer size is: 24
    Given reasoning query
      """
      match
        (friend: $a, friend: $b) isa friendship;
        (friend: $b, friend: $c) isa friendship;
        (friend: $c, friend: $d) isa friendship;
        not {$c isa dog;};

      """
    # Eliminates (cdzd, zdzd)
    Then verify answer size is: 22
    Then verify answer set is equivalent for query
      """
      match
        (friend: $a, friend: $b) isa friendship;
        (friend: $b, friend: $c) isa friendship;
        (friend: $c, friend: $d) isa friendship;
        $c isa person;

      """


  Scenario: negation can filter out an unwanted connection between two concepts from a chain of matched relations
    Given reasoning schema
      """
      define
      dog sub entity, owns name, plays friendship:friend;
      """
    Given reasoning data
      """
      insert
      $a isa person, has name "a";
      $b isa person, has name "b";
      $c isa person, has name "c";
      $d isa person, has name "d";
      $z isa dog, has name "z";

      (friend: $a, friend: $b) isa friendship;
      (friend: $b, friend: $c) isa friendship;
      (friend: $c, friend: $d) isa friendship;
      (friend: $d, friend: $z) isa friendship;
      """
    Given verifier is initialised
    Given reasoning query
    """
      match
        (friend: $a, friend: $b) isa friendship;
        (friend: $b, friend: $c) isa friendship;

      """
    # aba, abc
    # bab, bcb, bcd
    # cba, cbc, cdc, cdz
    # dcb, dcd, dzd
    # zdc, zdz
    Then verify answer size is: 14
    Given reasoning query
      """
      match
        (friend: $a, friend: $b) isa friendship;
        not {(friend: $b, friend: $z) isa friendship;};
        (friend: $b, friend: $c) isa friendship;
        $z isa dog;

      """
    # (d,z) is a friendship so we eliminate results where $b is 'd': these are (cdc, cdz, zdc, zdz)
    Then verify answer size is: 10
    Then verify answer set is equivalent for query
      """
      match
        (friend: $a, friend: $b) isa friendship;
        (friend: $b, friend: $c) isa friendship;
        $z isa dog;
        not {$b has name "d";};

      """


  Scenario: negation can filter out an unwanted role from a variable role query
    Given reasoning data
    """
      insert

      $x isa person;
      $c isa company;
      (employee: $x, employer: $c) isa employment;
      """
    Given verifier is initialised
    Given reasoning query
    """
      match ($r1: $x) isa employment;
      """
    # r1       | x   |
    # role     | PER |
    # employee | PER |
    # role     | COM |
    # employer | COM |
    Then verify answer size is: 4
    Given reasoning query
      """
      match
        ($r1: $x) isa employment;
        not {$r1 type relation:role;};

      """
    Then verify answer size is: 2


  Scenario: a negated statement with multiple properties can be re-written as a negation of multiple statements
    Given reasoning data
    """
      insert

      $x isa person, has name "Tim", has age 45;
      $y isa person, has name "Tim", has age 55;
      $z isa person, has name "Jim", has age 55;
      $w isa person, has name "Winnie";
      $c isa company, has name "Pizza Express";
      """
    Given verifier is initialised
    Given reasoning query
      """
      match $x has attribute $r;
      """
    Then verify answer size is: 8
    Given reasoning query
      """
      match
        $x has attribute $r;
        not {
          $x isa person, has name "Tim", has age 55;
        };

      """
    Then verify answer size is: 6
    Then verify answer set is equivalent for query
      """
      match
        $x has attribute $r;
        not {
          $x isa person;
          $x has name "Tim";
          $x has age 55;
        };

      """


  Scenario: a query can contain multiple negations
    Given reasoning data
      """
      insert

      $x isa person, has name "Tim", has age 45;
      $y isa person, has name "Tim", has age 55;
      $z isa person, has name "Jim", has age 55;
      $w isa person, has name "Winnie";
      $c isa company, has name "Pizza Express";
      """
    Given verifier is initialised
    Given reasoning query
      """
      match $x has attribute $r;
      """
    Then verify answer size is: 8
    Given reasoning query
      """
      match
        $x has attribute $r;
        not { $x isa company; };

      """
    Then verify answer size is: 7
    Given reasoning query
      """
      match
        $x has attribute $r;
        not { $x isa company; };
        not { $x has name "Tim"; };

      """
    Then verify answer size is: 3
    Given reasoning query
      """
      match
        $x has attribute $r;
        not { $x isa company; };
        not { $x has name "Tim"; };
        not { $r 55; };

      """
    Then verify answer size is: 2


  Scenario: negation can exclude entities of specific types that play roles in a specific relation
    Given reasoning schema
      """
      define
      pizza-company sub company;
      """
    Given reasoning data
      """
      insert

      $x isa person, has name "Tim", has age 45;
      $y isa person, has name "Tim", has age 55;
      $z isa person, has name "Jim", has age 55;
      $w isa person, has name "Winnie";
      $c isa pizza-company, has name "Pizza Express";
      $d isa company, has name "Heathrow Express";

      (employee: $x, employer: $c) isa employment;
      (employee: $y, employer: $d) isa employment;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match $x isa person;
      """
    Then verify answer size is: 4
    Given reasoning query
      """
      match
        $x isa person;
        not {
          (employee: $x, employer: $y) isa employment;
          $y isa pizza-company;
        };

      """
    Then verify answer size is: 3


  Scenario: when using negation to exclude entities of specific types, their subtypes are also excluded
    Given reasoning schema
      """
      define
      pizza-company sub company;
      """
    Given reasoning data
      """
      insert

      $x isa person, has name "Tim", has age 45;
      $y isa person, has name "Tim", has age 55;
      $z isa person, has name "Jim", has age 55;
      $w isa person, has name "Winnie";
      $c isa pizza-company, has name "Pizza Express";
      $d isa company, has name "Heathrow Express";

      (employee: $x, employer: $c) isa employment;
      (employee: $y, employer: $d) isa employment;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match
        $x isa person;
        not {
          (employee: $x, employer: $y) isa employment;
          $y isa company;
        };

      """
    Then verify answer size is: 2


  Scenario: answers can be returned even if a statement in a conjunction in a negation is identical to a non-negated one
    Given reasoning schema
      """
      define
      pizza-company sub company;
      """
    Given reasoning data
    """
      insert

      $x isa person, has name "Tim", has age 45;
      $y isa person, has name "Tim", has age 55;
      $z isa person, has name "Jim", has age 55;
      $w isa person, has name "Winnie";
      $c isa pizza-company, has name "Pizza Express";
      $d isa company, has name "Heathrow Express";

      (employee: $x, employer: $c) isa employment;
      (employee: $y, employer: $d) isa employment;
      """
    # We match $x isa person and not {$x isa person; ...}; answers can still be returned because of the conjunction
    Given reasoning query
    """
      match
        $x isa person;
        not {
          $x isa person;
          (employee: $x, employer: $y) isa employment;
          $y isa pizza-company;
        };

      """
    Then verify answer size is: 3


  Scenario: Nested negations
    # TODO: Maybe the subset test
