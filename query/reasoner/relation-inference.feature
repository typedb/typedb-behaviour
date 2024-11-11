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

  #######################
  # BASIC FUNCTIONALITY #
  #######################
  ###############
  # REFLEXIVITY #
  ###############

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


  ############
  # SYMMETRY #
  ############
  ################
  # TRANSITIVITY #
  ################


  Scenario: when a query using transitivity has a limit exceeding the result size, answers are consistent between runs
    Given reasoning schema
      """
      define
      rule transitive-location: when {
        (subordinate: $x, superior: $y) isa location-hierarchy;
        (subordinate: $y, superior: $z) isa location-hierarchy;
      } then {
        (subordinate: $x, superior: $z) isa location-hierarchy;
      };
      """
    Given reasoning data
      """
      insert
      $a isa place, has name "University of Warsaw";
      $b isa place, has name "Warsaw";
      $c isa place, has name "Poland";
      $d isa place, has name "Europe";

      (subordinate: $a, superior: $b) isa location-hierarchy;
      (subordinate: $b, superior: $c) isa location-hierarchy;
      (subordinate: $c, superior: $d) isa location-hierarchy;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match (subordinate: $x1, superior: $x2) isa location-hierarchy;
      """
    Then verify answer size is: 6
    Then verify answers are consistent across 5 executions
    Then verify answers are sound
    Then verify answers are complete


  Scenario: when a transitive rule's 'then' matches a query, but its 'when' is unmet, the material answers are returned

  This test is included because internally, Reasoner uses backward chaining to answer queries, meaning it has to
  perform resolution steps even if the conditions of a rule are never met. In this case, 'transitive-location'
  is never triggered because there are no location-hierarchy pairs that satisfy both conditions.

    Given reasoning schema
      """
      define

      planned-trip sub relation,
        relates source,
        relates destination;

      cycle-route sub relation,
        relates start,
        relates end;

      place plays planned-trip:source,
        plays planned-trip:destination,
        plays cycle-route:start,
        plays cycle-route:end;

      rule transitive-location: when {
        (subordinate: $x, superior: $y) isa location-hierarchy;
        (subordinate: $y, superior: $z) isa location-hierarchy;
      } then {
        (subordinate: $x, superior: $z) isa location-hierarchy;
      };
      """
    Given reasoning data
      """
      insert
      $x1 isa place, has name "Waterloo";
      $x2a isa place, has name "Embankment";
      $x2b isa place, has name "Southwark";
      $x2c isa place, has name "Victoria";
      $x3 isa place, has name "Tower Hill";
      $x4 isa place, has name "London";

      (start: $x1, end: $x2a) isa cycle-route;
      (start: $x1, end: $x2b) isa cycle-route;
      (start: $x1, end: $x2c) isa cycle-route;

      (source: $x2a, destination: $x3) isa planned-trip;
      (source: $x2b, destination: $x3) isa planned-trip;
      (source: $x2c, destination: $x3) isa planned-trip;

      (subordinate: $x3, superior: $x4) isa location-hierarchy;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match (subordinate: $x, superior: $y) isa location-hierarchy;
      """
    Then verify answer size is: 1
    Then verify answers are sound
    Then verify answers are complete


  ######################
  # ROLEPLAYER MATCHING #
  ######################

  Scenario: an inferred relation with one player in a role is not retrieved when the role appears twice in a match query
    Given reasoning schema
      """
      define
      rule employment-rule: when {
        $c isa company;
        $p isa person;
      } then {
        (employee: $p, employer: $c) isa employment;
      };
      """
    Given reasoning data
      """
      insert
      $x isa person;
      $c isa company;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match (employee: $x, employee: $y) isa employment;
      """
    Then verify answer size is: 0
    Then verify answers are sound
    Then verify answers are complete


  Scenario: a relation with two roleplayers inferred by the same rule is retrieved when matching only one of the roles
    Given reasoning schema
      """
      define
      rule employment-rule: when {
        $c isa company;
        $p isa person;
      } then {
        (employee: $p, employer: $c) isa employment;
      };
      """
    Given reasoning data
      """
      insert
      $x isa person;
      $c isa company;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match (employee: $x) isa employment;
      """
    Then verify answer size is: 1
    Then verify answers are sound
    Then verify answers are complete


  Scenario: when matching an inferred relation with repeated roles, answers contain all permutations of the roleplayers
    Given reasoning schema
      """
      define
      rule alice-bob-and-charlie-are-friends: when {
        $a isa person, has name "Alice";
        $b isa person, has name "Bob";
        $c isa person, has name "Charlie";
      } then {
        (friend: $a, friend: $b, friend: $c) isa friendship;
      };
      """
    Given reasoning data
      """
      insert
      $x isa person, has name "Alice";
      $y isa person, has name "Bob";
      $z isa person, has name "Charlie";
      """
    Given verifier is initialised
    Given reasoning query
      """
      match (friend: $a, friend: $b, friend: $c) isa friendship;
      """
    Then verify answer size is: 6
    Then verify answers are sound
    Then verify answers are complete
    Then verify answer set is equivalent for query
      """
      match
        $r (friend: $a, friend: $b, friend: $c) isa friendship;
      get $a, $b, $c;
      """


  Scenario: inferred relations can be filtered by shared attribute ownership
    Given reasoning schema
      """
      define
      selection sub relation, relates choice1, relates choice2;
      person plays selection:choice1, plays selection:choice2;
      rule symmetric-selection: when {
        (choice1: $x, choice2: $y) isa selection;
      } then {
        (choice1: $y, choice2: $x) isa selection;
      };
      rule transitive-selection: when {
        (choice1: $x, choice2: $y) isa selection;
        (choice1: $y, choice2: $z) isa selection;
      } then {
        (choice1: $x, choice2: $z) isa selection;
      };
      """
    Given reasoning data
      """
      insert
      $x isa person, has name "a";
      $y isa person, has name "b";
      $z isa person, has name "c";

      (choice1: $x, choice2: $y) isa selection;
      (choice1: $y, choice2: $z) isa selection;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match
        (choice1: $x, choice2: $y) isa selection;
        $x has name $n;
        $y has name $n;

      """
    # (a,a), (b,b), (c,c)
    Then verify answer size is: 3
    Then verify answers are sound
    Then verify answers are complete
    Given reasoning query
      """
      match
        (choice1: $x, choice2: $y) isa selection;
        $x has name $n;
        $y has name $n;
        $n == 'a';
      get $x, $y;
      """
    Then verify answer size is: 1
    Then verify answers are sound
    Then verify answers are complete
    Then verify answer set is equivalent for query
      """
      match
        (choice1: $x, choice2: $y) isa selection;
        $x has name 'a';
        $y has name 'a';

      """


  #######################
  # UNTYPED MATCH QUERY #
  #######################

  Scenario: the relation type constraint can be excluded from a reasoned match query
    Given reasoning schema
      """
      define
      rule transitive-location: when {
        (subordinate: $x, superior: $y) isa location-hierarchy;
        (subordinate: $y, superior: $z) isa location-hierarchy;
      } then {
        (subordinate: $x, superior: $z) isa location-hierarchy;
      };
      """
    Given reasoning data
      """
      insert
      $x isa place, has name "Turku Airport";
      $y isa place, has name "Turku";
      $z isa place, has name "Finland";

      (subordinate: $x, superior: $y) isa location-hierarchy;
      (subordinate: $y, superior: $z) isa location-hierarchy;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match
        $a isa place, has name "Turku Airport";
        ($a, $b);
        $b isa place, has name "Turku";
        ($b, $c);

      """
    # $c in {'Turku Airport', 'Finland'}
    Then verify answer size is: 2
    Then verify answers are sound
    Then verify answers are complete


  Scenario: when the relation type is excluded in a reasoned match query, all valid roleplayer combinations are matches
    Given reasoning schema
      """
      define
      rule transitive-location: when {
        (subordinate: $x, superior: $y) isa location-hierarchy;
        (subordinate: $y, superior: $z) isa location-hierarchy;
      } then {
        (subordinate: $x, superior: $z) isa location-hierarchy;
      };
      """
    Given reasoning data
      """
      insert
      $x isa place, has name "Turku Airport";
      $y isa place, has name "Turku";
      $z isa place, has name "Finland";

      (subordinate: $x, superior: $y) isa location-hierarchy;
      (subordinate: $y, superior: $z) isa location-hierarchy;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match
        $a isa place, has name "Turku Airport";
        ($a, $b);
        $b isa place, has name "Turku";

      """
    Then verify answer size is: 1
    Then verify answers are sound
    Then verify answers are complete
    Given reasoning query
      """
      match
        $a isa place, has name "Turku Airport";
        ($a, $b);
        $b isa place, has name "Turku";
        ($c, $d);

      """
    # (2 db relations + 1 inferred) x 2 for variable swap
    Then verify answer size is: 6
    Then verify answers are sound
    Then verify answers are complete


  Scenario: when the relation type is excluded in a reasoned match query, all types of relations match
    Given reasoning schema
      """
      define

      loc-hie sub relation, relates loc-sub, relates loc-sup;

      place plays loc-hie:loc-sub, plays loc-hie:loc-sup;

      rule transitive-location: when {
        (subordinate: $x, superior: $y) isa location-hierarchy;
        (subordinate: $y, superior: $z) isa location-hierarchy;
      } then {
        (subordinate: $x, superior: $z) isa location-hierarchy;
      };

      rule long-role-names-suck: when {
        (subordinate: $x, superior: $y) isa location-hierarchy;
      } then {
        (loc-sub: $x, loc-sup: $y) isa loc-hie;
      };
      """
    Given reasoning data
      """
      insert
      $x isa place, has name "Turku Airport";
      $y isa place, has name "Turku";
      $z isa place, has name "Finland";

      (subordinate: $x, superior: $y) isa location-hierarchy;
      (subordinate: $y, superior: $z) isa location-hierarchy;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match ($a, $b) isa relation;
      """
    Then verify answers are sound
    Then verify answers are complete
    # Despite there being more inferred relations, the answer size is still 6 (as in the previous scenario)
    # because the query is only interested in the related concepts, not in the relation instances themselves
    Then verify answer size is: 6
    Then verify answer set is equivalent for query
      """
      match ($a, $b);
      """

  Scenario: conjunctions of untyped reasoned relations are correctly resolved
    Given reasoning schema
      """
      define
      rule transitive-location: when {
        (subordinate: $x, superior: $y) isa location-hierarchy;
        (subordinate: $y, superior: $z) isa location-hierarchy;
      } then {
        (subordinate: $x, superior: $z) isa location-hierarchy;
      };
      """
    Given reasoning data
      """
      insert
      $x isa place, has name "Turku Airport";
      $y isa place, has name "Turku";
      $z isa place, has name "Finland";

      (subordinate: $x, superior: $y) isa location-hierarchy;
      (subordinate: $y, superior: $z) isa location-hierarchy;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match
        ($a, $b);
        ($b, $c);

      """
    # a   | b   | c   |
    # AIR | TUR | FIN |
    # AIR | FIN | TUR |
    # AIR | TUR | AIR |
    # AIR | FIN | AIR |
    # TUR | AIR | FIN |
    # TUR | FIN | AIR |
    # TUR | AIR | TUR |
    # TUR | FIN | TUR |
    # FIN | AIR | TUR |
    # FIN | TUR | AIR |
    # FIN | AIR | FIN |
    # FIN | TUR | FIN |
    Then verify answer size is: 12
    Then verify answers are sound
    Then verify answers are complete


  Scenario: a relation can be inferred based on a direct type
    Given reasoning schema
      """
      define

      baseEntity sub entity,
          plays baseRelation:baseRole,
          plays derivedRelation:derivedRelationRole;

      baseRelation sub relation,
          relates baseRole;
      subRelation sub baseRelation;
      subSubRelation sub subRelation;

      derivedRelation sub relation,
          relates derivedRelationRole;
      directDerivedRelation sub derivedRelation;

      rule relationRule: when {
          ($x) isa subRelation;
      } then {
          (derivedRelationRole: $x) isa derivedRelation;
      };

      rule directRelationRule: when {
          ($x) isa! subRelation;
      } then {
          (derivedRelationRole: $x) isa directDerivedRelation;
      };
      """
    Given reasoning data
      """
      insert
      $x isa baseEntity;
      $y isa baseEntity;
      $z isa baseEntity;

      (baseRole: $x) isa baseRelation;
      (baseRole: $y) isa subRelation;
      (baseRole: $z) isa subSubRelation;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match ($x) isa derivedRelation;
      """
    Then verify answer size is: 2
    Then verify answers are sound
    Then verify answers are complete
    Given reasoning query
      """
      match ($x) isa! derivedRelation;
      """
    Then verify answer size is: 2
    Then verify answers are sound
    Then verify answers are complete
    Given reasoning query
      """
      match ($x) isa directDerivedRelation;
      """
    Then verify answer size is: 1
    Then verify answers are sound
    Then verify answers are complete