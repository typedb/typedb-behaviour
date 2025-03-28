# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Negation Resolution

  Background: Set up database
    Given typedb starts
    Given connection opens with default authentication
    Given connection is open: true
    Given connection has 0 databases
    Given connection create database: typedb
    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
      define

      entity person,
        owns name,
        owns age,
        plays friendship:friend,
        plays employment:employee;

      entity company,
        owns name,
        plays employment:employer;

      entity place,
        owns name,
        plays location-hierarchy:subordinate,
        plays location-hierarchy:superior;

      relation friendship,
        relates friend @card(0..);

      relation employment,
        relates employee,
        relates employer;

      relation location-hierarchy,
        relates subordinate,
        relates superior;

      attribute name, value string;
      attribute age, value integer;
      """
    Given transaction commits
    # each scenario specialises the schema further

  # TODO: This section needs to be moved to the regular query feature

  #####################
  # NEGATION IN MATCH #
  #####################

  Scenario: negation can check that an entity does not play a specified role in any relation
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x1 isa person;
      $x2 isa person;
      $x3 isa person;
      $x4 isa person;
      $x5 isa person;
      $c isa company, has name "Amazon";
      $e1 isa employment, links (employee: $x1, employer: $c);
      $e2 isa employment, links (employee: $x2, employer: $c);
      """
    Given transaction commits
    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person;
      """
    Then answer size is: 5
    When get answers of typeql read query
      """
      match
        $x isa person;
        not {
          $e isa employment, links (employee: $x);
        };

      """
    Then answer size is: 3


  Scenario: negation can check that an entity does not play any role in any relation
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x1 isa person;
      $x2 isa person;
      $x3 isa person;
      $x4 isa person;
      $x5 isa person;
      $c isa company, has name "Amazon";
      $e1 isa employment, links (employee: $x1, employer: $c);
      $e2 isa employment, links (employee: $x2, employer: $c);
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person;
      """
    Then answer size is: 5
    When get answers of typeql read query
      """
      match
        $x isa person;
        not {
          $r links ($x) ;
        };

      """
    Then answer size is: 3


  Scenario: negation can check that an entity does not own any instance of a specific attribute type
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x1 isa person, has name "asdf";
      $x2 isa person, has name "cgt";
      $x3 isa person;
      $x4 isa person, has name "bleh";
      $x5 isa person;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person;
      """
    Then answer size is: 5
    When get answers of typeql read query
      """
      match
        $x isa person;
        not {
          $x has name $val;
        };

      """
    Then answer size is: 2


  Scenario: negation can check that an entity does not own a particular attribute
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x1 isa person, has name "Bob";
      $x2 isa person, has name "cgt";
      $x3 isa person;
      $x4 isa person, has name "bleh";
      $x5 isa person;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person;
      """
    Then answer size is: 5
    When get answers of typeql read query
      """
      match
        $x isa person;
        not {
          $x has name "Bob";
        };

      """
    Then answer size is: 4


  Scenario: negation can check that an entity owns an attribute which is not equal to a specific value
    Given connection open write transaction for database: typedb
    Given typeql write query
    """
      insert
      $x isa person, has age 10;
      $y isa person, has age 20;
      $z isa person;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
    """
      match
        $x has age $y;
        not {$y == 20;};

      """
    Then answer size is: 1
    Then verify answer set is equivalent for query
      """
      match
        $x has age $y;
        $y == 10;

      """


  Scenario: negation can check that an entity owns an attribute that is not of a specified type
    Given connection open write transaction for database: typedb
    Given typeql write query
    """
      insert
      $x isa person, has age 10, has name "Bob";
      $y isa person, has age 20;
      $z isa person;
      $w isa person, has name "Charlie";
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
    """
      match
        $x has $y;
        not {$y isa name;};
      """
    Then answer size is: 2
    Then verify answer set is equivalent for query
      """
      match $x has age $y;
      """


  Scenario: negation can filter out an unwanted entity type from part of a chain of matched relations
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      entity dog, plays friendship:friend;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $a isa person;
      $b isa person;
      $c isa person;
      $d isa person;
      $z isa dog;

       $f1 isa friendship, links (friend: $a, friend: $b);
       $f2 isa friendship, links (friend: $b, friend: $c);
       $f3 isa friendship, links (friend: $c, friend: $d);
       $f4 isa friendship, links (friend: $d, friend: $z);
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
    """
      match
        $f1 isa friendship, links (friend: $a, friend: $b);
        $f2 isa friendship, links (friend: $b, friend: $c);
        $f3 isa friendship, links (friend: $c, friend: $d);

      """
    # abab, abcb, abcd,
    # baba, babc, bcba, bcbc, bcdc, bcdz,
    # cbab, cbcb, cbcd, cdcb, cdcd, cdzd,
    # dcba, dcbc, dcdc, dcdz, dzdc, dzdz,
    # zdcb, zdcd, zdzd
    Then answer size is: 24
    When get answers of typeql read query
      """
      match
        $f1 isa friendship, links (friend: $a, friend: $b);
        $f2 isa friendship, links (friend: $b, friend: $c);
        $f3 isa friendship, links (friend: $c, friend: $d);
        not {$c isa dog;};

      """
    # Eliminates (cdzd, zdzd)
    Then answer size is: 22
    Then verify answer set is equivalent for query
      """
      match
        $f1 isa friendship, links (friend: $a, friend: $b);
        $f2 isa friendship, links (friend: $b, friend: $c);
        $f3 isa friendship, links (friend: $c, friend: $d);
        $c isa person;

      """

  Scenario: negation can filter out an unwanted connection between two concepts from a chain of matched relations
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      entity dog, owns name, plays friendship:friend;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $a isa person, has name "a";
      $b isa person, has name "b";
      $c isa person, has name "c";
      $d isa person, has name "d";
      $z isa dog, has name "z";

      $f1 isa friendship, links (friend: $a, friend: $b);
      $f2 isa friendship, links (friend: $b, friend: $c);
      $f3 isa friendship, links (friend: $c, friend: $d);
      $f4 isa friendship, links (friend: $d, friend: $z);
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
    """
      match
        $f1 isa friendship, links (friend: $a, friend: $b);
        $f2 isa friendship, links (friend: $b, friend: $c);

      """
    # aba, abc
    # bab, bcb, bcd
    # cba, cbc, cdc, cdz
    # dcb, dcd, dzd
    # zdc, zdz
    Then answer size is: 14
    When get answers of typeql read query
      """
      match
        $f1 isa friendship, links (friend: $a, friend: $b);
        not { $f2 isa friendship, links (friend: $b, friend: $z); };
        $f3 isa friendship, links (friend: $b, friend: $c);
        $z isa dog;

      """
    # (d,z) is a friendship so we eliminate results where $b is 'd': these are (cdc, cdz, zdc, zdz)
    Then answer size is: 10
    Then verify answer set is equivalent for query
      """
      match
        $f1 isa friendship, links (friend: $a, friend: $b);
        $f2 isa friendship, links (friend: $b, friend: $c);
        $z isa dog;
        not {$b has name "d";};

      """


  Scenario: negation can filter out an unwanted role from a variable role query
    Given connection open write transaction for database: typedb
    Given typeql write query
    """
      insert

      $x isa person;
      $c isa company;
      $e isa employment, links (employee: $x, employer: $c);
      """
    When get answers of typeql read query
    """
      match ($r1: $x) isa employment;
    """
    # r1       | x   |
    # employee | PER |
    # employer | COM |
    Then answer size is: 2
    When get answers of typeql read query
      """
      match
        $e isa employment, links ($r1: $x);
        not {$r1 label employment:employer;};

      """
    Then answer size is: 1


  Scenario: a negated statement with multiple properties can be re-written as a negation of multiple statements
    Given connection open write transaction for database: typedb
    Given typeql write query
    """
      insert

      $x isa person, has name "Tim", has age 45;
      $y isa person, has name "Tim", has age 55;
      $z isa person, has name "Jim", has age 55;
      $w isa person, has name "Winnie";
      $c isa company, has name "Pizza Express";
    """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x has $r;
      """
    Then answer size is: 8
    When get answers of typeql read query
      """
      match
        $x has $r;
        not {
          $x isa person, has name "Tim", has age 55;
        };

      """
    Then answer size is: 6
    Then verify answer set is equivalent for query
      """
      match
        $x has $r;
        not {
          $x isa person;
          $x has name "Tim";
          $x has age 55;
        };

      """


  Scenario: a query can contain multiple negations
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert

      $x isa person, has name "Tim", has age 45;
      $y isa person, has name "Tim", has age 55;
      $z isa person, has name "Jim", has age 55;
      $w isa person, has name "Winnie";
      $c isa company, has name "Pizza Express";
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x has $r;
      """
    Then answer size is: 8
    When get answers of typeql read query
      """
      match
        $x has $r;
        not { $x isa company; };

      """
    Then answer size is: 7
    When get answers of typeql read query
      """
      match
        $x has $r;
        not { $x isa company; };
        not { $x has name "Tim"; };

      """
    Then answer size is: 3
    When get answers of typeql read query
      """
      match
        $x has $r;
        not { $x isa company; };
        not { $x has name "Tim"; };
        not { $r == 55; };

      """
    Then answer size is: 2


  Scenario: negation can exclude entities of specific types that play roles in a specific relation
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      entity pizza-company sub company;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert

      $x isa person, has name "Tim", has age 45;
      $y isa person, has name "Tim", has age 55;
      $z isa person, has name "Jim", has age 55;
      $w isa person, has name "Winnie";
      $c isa pizza-company, has name "Pizza Express";
      $d isa company, has name "Heathrow Express";

      $e1 isa employment, links (employee: $x, employer: $c);
      $e2 isa employment, links (employee: $y, employer: $d);
      """
    When get answers of typeql read query
      """
      match $x isa person;
      """
    Then answer size is: 4
    When get answers of typeql read query
      """
      match
        $x isa person;
        not {
          $e isa employment, links (employee: $x, employer: $y);
          $y isa pizza-company;
        };

      """
    Then answer size is: 3


  Scenario: when using negation to exclude entities of specific types, their subtypes are also excluded
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      entity pizza-company sub company;
      """
    Given transaction commits
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert

      $x isa person, has name "Tim", has age 45;
      $y isa person, has name "Tim", has age 55;
      $z isa person, has name "Jim", has age 55;
      $w isa person, has name "Winnie";
      $c isa pizza-company, has name "Pizza Express";
      $d isa company, has name "Heathrow Express";

      $e1 isa employment, links (employee: $x, employer: $c);
      $e2 isa employment, links (employee: $y, employer: $d);
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        $x isa person;
        not {
          $e isa employment, links (employee: $x, employer: $y);
          $y isa company;
        };

      """
    Then answer size is: 2


  Scenario: answers can be returned even if a statement in a conjunction in a negation is identical to a non-negated one
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      entity pizza-company sub company;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
    """
      insert

      $x isa person, has name "Tim", has age 45;
      $y isa person, has name "Tim", has age 55;
      $z isa person, has name "Jim", has age 55;
      $w isa person, has name "Winnie";
      $c isa pizza-company, has name "Pizza Express";
      $d isa company, has name "Heathrow Express";

      $e1 isa employment, links (employee: $x, employer: $c);
      $e2 isa employment, links (employee: $y, employer: $d);
      """
    # We match $x isa person and not {$x isa person; ...}; answers can still be returned because of the conjunction
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
    """
      match
        $x isa person;
        not {
          $x isa person;
          $e isa employment (employee: $x, employer: $y);
          $y isa pizza-company;
        };

      """
    Then answer size is: 3


  Scenario: Negation inputs are handled correctly
    Given connection open schema transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person;
      $c isa company;
      $e isa employment, links (employee: $x, employer: $c);
      """
    Given transaction commits
    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        not { # Must be in a negation so that `$x` is not selected for the entire match stage.
          $x isa person;
          not {
            (employee: $x);
            # The planner prefers ordering `$_ role-name employee` (which is free) before `$_ links $_:$x` (which has to hit disk).
            # If `$x` is not marked as input to the negation during lowering, it is not selected by the role name step, and therefore removed from the row.
            # The links executor then crashes as it expects `$x` to be bound.
          };
        };
      """


  Scenario: Nested negations
    # TODO: Maybe the subset test
