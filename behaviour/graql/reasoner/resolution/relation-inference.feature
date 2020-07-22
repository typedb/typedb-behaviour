#
# Copyright (C) 2020 Grakn Labs
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

Feature: Relation Inference Resolution

  Background: Set up keyspaces for resolution testing

    Given connection has been opened
    Given connection delete all keyspaces
    Given connection open sessions for keyspaces:
      | materialised |
      | reasoned     |
    Given materialised keyspace is named: materialised
    Given reasoned keyspace is named: reasoned
    Given for each session, graql define
      """
      define

      person sub entity,
        has name,
        plays friend,
        plays employee;

      company sub entity,
        has name,
        plays employer;

      place sub entity,
        has name,
        plays location-subordinate,
        plays location-superior;

      friendship sub relation,
        relates friend;

      employment sub relation,
        relates employee,
        relates employer;

      location-hierarchy sub relation,
        relates location-subordinate,
        relates location-superior;

      name sub attribute, value string;
      """


  ##############################
  # CONDITIONS AND CONCLUSIONS #
  ##############################

  Scenario: a relation can be inferred on all concepts of a given type
    Given for each session, graql define
      """
      define
      dog sub entity;
      people-are-employed sub rule,
      when {
        $p isa person;
      }, then {
        (employee: $p) isa employment;
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa person;
      $y isa dog;
      $z isa person;
      """
    When materialised keyspace is completed
    Then for graql query
      """
      match
        $x isa person;
        ($x) isa employment;
      get;
      """
    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 2
    Then for graql query
      """
      match
        $x isa dog;
        ($x) isa employment;
      get;
      """
    Then answer size in reasoned keyspace is: 0
    Then materialised and reasoned keyspaces are the same size


  Scenario: a relation can be inferred based on an attribute ownership
    Given for each session, graql define
      """
      define
      haikal-is-employed sub rule,
      when {
        $p has name "Haikal";
      }, then {
        (employee: $p) isa employment;
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa person, has name "Haikal";
      $y isa person, has name "Michael";
      """
    When materialised keyspace is completed
    Then for graql query
      """
      match
        $x has name "Haikal";
        ($x) isa employment;
      get;
      """
    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 1
    Then for graql query
      """
      match
        $x has name "Michael";
        ($x) isa employment;
      get;
      """
    Then answer size in reasoned keyspace is: 0
    Then materialised and reasoned keyspaces are the same size


  Scenario: a rule can infer a relation with an attribute as a roleplayer
    Given for each session, graql define
      """
      define
      item sub entity, has name, plays listed-item;
      price sub attribute, value double, plays item-price;
      item-listing sub relation, relates listed-item, relates item-price;
      nutella-price sub rule,
      when {
        $x isa item, has name "3kg jar of Nutella";
        $y 14.99 isa price;
      }, then {
        (listed-item: $x, item-price: $y) isa item-listing;
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa item, has name "3kg jar of Nutella";
      $y 14.99 isa price;
      """
    When materialised keyspace is completed
    Then for graql query
      """
      match
        $r (listed-item: $i, item-price: $p) isa item-listing;
        $i isa item, has name $n;
        $n "3kg jar of Nutella" isa name;
        $p 14.99 isa price;
      get;
      """
    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 1
    Then materialised and reasoned keyspaces are the same size


  Scenario: a rule can infer a relation based on ownership of any instance of a specific attribute type
    Given for each session, graql define
      """
      define
      year sub attribute, value long, plays favourite-year;
      employment relates favourite-year;
      kronenbourg-employs-anyone-with-a-name sub rule,
      when {
        $x isa company, has name "Kronenbourg";
        $p isa person, has name $n;
        $y 1664 isa year;
      }, then {
        (employee: $p, employer: $x, favourite-year: $y) isa employment;
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa company, has name "Kronenbourg";
      $p isa person, has name "Ronald";
      $p2 isa person, has name "Prasanth";
      """
    When materialised keyspace is completed
    Then for graql query
      """
      match
        $x 1664 isa year;
        ($x, employee: $p, employer: $y) isa employment;
      get;
      """
    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 2
    Then materialised and reasoned keyspaces are the same size


  ###############
  # REFLEXIVITY #
  ###############

  Scenario: when inferring relations on concept pairs, the number of inferences is the square of the number of concepts
    Given for each session, graql define
      """
      define
      everyone-is-my-friend-including-myself sub rule,
      when {
        $x isa person;
        $y isa person;
      }, then {
        (friend: $x, friend: $y) isa friendship;
      };
      """
    Given for each session, graql insert
      """
      insert
      $a isa person, has name "Abigail";
      $b isa person, has name "Bernadette";
      $c isa person, has name "Cliff";
      $d isa person, has name "Damien";
      $e isa person, has name "Eustace";
      """
    When materialised keyspace is completed
    Then for graql query
      """
      match $r isa friendship; get;
      """
    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 25
    Then materialised and reasoned keyspaces are the same size


  Scenario: when a relation is reflexive, matching concepts are related to themselves
    Given for each session, graql define
      """
      define
      person plays employer;
      self-employment sub rule,
      when {
        $x isa person;
      }, then {
        (employee: $x, employer: $x) isa employment;
      };
      """
    Given for each session, graql insert
      """
      insert
      $f isa person, has name "Ferhat";
      $g isa person, has name "Gawain";
      $h isa person, has name "Hattie";
      """
    When materialised keyspace is completed
    Then for graql query
      """
      match
        (employee: $x, employer: $x) isa employment;
      get;
      """
    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 3
    Then materialised and reasoned keyspaces are the same size


  Scenario: inferred reflexive relations can be retrieved using multiple variables to refer to the same concept
    Given for each session, graql define
      """
      define
      person plays employer;
      self-employment sub rule,
      when {
        $x isa person;
      }, then {
        (employee: $x, employer: $x) isa employment;
      };
      """
    Given for each session, graql insert
      """
      insert
      $i isa person, has name "Irma";
      """
    When materialised keyspace is completed
    Then for graql query
      """
      match
        (employee: $x, employer: $y) isa employment;
      get;
      """
    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 1
    Then materialised and reasoned keyspaces are the same size


  Scenario: inferred relations between distinct concepts are not retrieved when matching concepts related to themselves
    Given for each session, graql define
      """
      define
      person plays employer;
      robert-employs-jane sub rule,
      when {
        $x has name "Robert";
        $y has name "Jane";
      }, then {
        (employee: $y, employer: $x) isa employment;
      };
      """
    Given for each session, graql insert
      """
      insert
      $r isa person, has name "Robert";
      $j isa person, has name "Jane";
      """
    When materialised keyspace is completed
    Then for graql query
      """
      match
        (employee: $x, employer: $x) isa employment;
      get;
      """
    Then answer size in reasoned keyspace is: 0
    Then materialised and reasoned keyspaces are the same size


  ############
  # SYMMETRY #
  ############

  Scenario: when a relation is symmetric, its symmetry can be used to make additional inferences
    Given for each session, graql define
      """
      define

      person plays coworker, plays employer;

      robot sub entity,
          plays coworker,
          plays employee,
          plays employer,
          has name;

      coworkers sub relation,
          relates coworker;

      robot-pet-ownership sub relation,
          relates robot-pet,
          relates robot-pet-owner;

      people-work-with-themselves sub rule,
      when {
          $x isa person;
      },
      then {
          (coworker: $x, coworker: $x) isa coworkers;
      };

      robots-work-with-their-owners-coworkers sub rule,
      when {
          (robot-pet: $c, robot-pet-owner: $m) isa robot-pet-ownership;
          (coworker: $m, coworker: $op) isa coworkers;
      },
      then {
          (coworker: $c, coworker: $op) isa coworkers;
      };
      """
    Given for each session, graql insert
      """
      insert
      $a isa robot-pet, has name 'r1';
      $b isa person, has name 'p';
      $c isa robot-pet, has name 'r2';
      (robot-pet: $a, robot-pet-owner: $b) isa robot-pet-ownership;
      (coworker: $b, coworker: $c) isa coworkers;
      """
    When materialised keyspace is completed
    Then for graql query
      """
      match
        (coworker: $x, coworker: $x) isa coworkers;
      get;
      """
    Then all answers are correct in reasoned keyspace
    # (p,p) is a coworkers since people work with themselves.
    # Applying the robot work rule we see that (r1,p) is a pet ownership, and (p,p) and (p,r2) are coworker relations,
    # so (r1,p) and (r1,r2) are both coworker relations.
    # Coworker relations are symmetric, so (r2,p), (p,r1) and (r2,r1) are all coworker relations.
    # Applying the robot work rule a 2nd time, (r1,p) is a pet ownership and (p,r1) are coworkers,
    # therefore (r1,r1) is a reflexive coworker relation. So the answers are [p] and [r1].
    Then answer size in reasoned keyspace is: 2
    Then for graql query
      """
      match
        (coworker: $x, coworker: $y) isa coworkers;
      get;
      """
    Then all answers are correct in reasoned keyspace
    # $x | $y |
    # p  | p  |
    # p  | r2 |
    # r1 | p  |
    # r1 | r2 |
    # r2 | p  |
    # p  | r1 |
    # r2 | r1 |
    # r1 | r1 |
    Then answer size in reasoned keyspace is: 8
    Then materialised and reasoned keyspaces are the same size


  ################
  # TRANSITIVITY #
  ################

  Scenario: a transitive rule will not infer any new relations when there are only two related entities
    Given for each session, graql define
      """
      define
      transitive-location sub rule,
      when {
        (location-subordinate: $x, location-superior: $y) isa location-hierarchy;
        (location-subordinate: $y, location-superior: $z) isa location-hierarchy;
      }, then {
        (location-subordinate: $x, location-superior: $z) isa location-hierarchy;
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa place, has name "Delhi";
      $y isa place, has name "India";
      (location-subordinate: $x, location-superior: $x) isa location-hierarchy;
      (location-subordinate: $x, location-superior: $y) isa location-hierarchy;
      (location-subordinate: $y, location-superior: $y) isa location-hierarchy;
      """
    When materialised keyspace is completed
    Then for graql query
      """
      match $x isa location-hierarchy; get;
      """
    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 3
    Then materialised and reasoned keyspaces are the same size


  # TODO: re-enable all steps when 3-hop transitivity is resolvable
  Scenario: when a query using transitivity has a limit exceeding the result size, answers are consistent between runs
    Given for each session, graql define
      """
      define
      transitive-location sub rule,
      when {
        (location-subordinate: $x, location-superior: $y) isa location-hierarchy;
        (location-subordinate: $y, location-superior: $z) isa location-hierarchy;
      }, then {
        (location-subordinate: $x, location-superior: $z) isa location-hierarchy;
      };
      """
    Given for each session, graql insert
      """
      insert
      $a isa place, has name "University of Warsaw";
      $b isa place, has name "Warsaw";
      $c isa place, has name "Poland";
      $d isa place, has name "Europe";

      (location-subordinate: $a, location-superior: $b) isa location-hierarchy;
      (location-subordinate: $b, location-superior: $c) isa location-hierarchy;
      (location-subordinate: $c, location-superior: $d) isa location-hierarchy;
      """
#    When materialised keyspace is completed
    Then for graql query
      """
      match (location-subordinate: $x1, location-superior: $x2) isa location-hierarchy; get;
      """
#    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 6
    Then answers are consistent across 5 executions in reasoned keyspace
#    Then materialised and reasoned keyspaces are the same size


  Scenario: when a transitive rule's `then` matches a query, but its `when` is unmet, the material answers are returned

    This test is included because internally, Reasoner uses backward chaining to answer queries, meaning it has to
    perform resolution steps even if the conditions of a rule are never met. In this case, `transitive-location`
    is never triggered because there are no location-hierarchy pairs that satisfy both conditions.

    Given for each session, graql define
      """
      define

      planned-trip sub relation,
        relates planned-source,
        relates planned-destination;

      cycle-route sub relation,
        relates cycle-route-start,
        relates cycle-route-end;

      place plays planned-source,
        plays planned-destination,
        plays cycle-route-start,
        plays cycle-route-end;

      transitive-location sub rule,
      when {
        (location-subordinate: $x, location-superior: $y) isa location-hierarchy;
        (location-subordinate: $y, location-superior: $z) isa location-hierarchy;
      }, then {
        (location-subordinate: $x, location-superior: $z) isa location-hierarchy;
      };
      """
    Given for each session, graql insert
      """
      insert
      $x1 isa place, has name "Waterloo";
      $x2a isa place, has name "Embankment";
      $x2b isa place, has name "Southwark";
      $x2c isa place, has name "Victoria";
      $x3 isa place, has name "Tower Hill";
      $x4 isa place, has name "London";

      (cycle-route-start: $x1, cycle-route-end: $x2a) isa cycle-route;
      (cycle-route-start: $x1, cycle-route-end: $x2b) isa cycle-route;
      (cycle-route-start: $x1, cycle-route-end: $x2c) isa cycle-route;

      (planned-source: $x2a, planned-destination: $x3) isa planned-trip;
      (planned-source: $x2b, planned-destination: $x3) isa planned-trip;
      (planned-source: $x2c, planned-destination: $x3) isa planned-trip;

      (location-subordinate: $x3, location-superior: $x4) isa location-hierarchy;
      """
    When materialised keyspace is completed
    Then for graql query
      """
      match (location-subordinate: $x, location-superior: $y) isa location-hierarchy; get;
      """
    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 1
    Then materialised and reasoned keyspaces are the same size


  #################
  # ROLE MATCHING #
  #################

  Scenario: an inferred relation with one player in a role is not retrieved when the role appears twice in a match query
    Given for each session, graql define
      """
      define
      employment-rule sub rule,
      when {
        $c isa company;
        $p isa person;
      }, then {
        (employee: $p, employer: $c) isa employment;
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa person;
      $c isa company;
      """
    When materialised keyspace is completed
    Then for graql query
      """
      match (employee: $x, employee: $y) isa employment; get;
      """
    Then answer size in reasoned keyspace is: 0
    Then materialised and reasoned keyspaces are the same size


  Scenario: a relation with two roleplayers inferred by the same rule is retrieved when matching only one of the roles
    Given for each session, graql define
      """
      define
      employment-rule sub rule,
      when {
        $c isa company;
        $p isa person;
      }, then {
        (employee: $p, employer: $c) isa employment;
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa person;
      $c isa company;
      """
    When materialised keyspace is completed
    Then for graql query
      """
      match (employee: $x) isa employment; get;
      """
    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 1
    Then materialised and reasoned keyspaces are the same size


  #####################
  # CHAINED INFERENCE #
  #####################

  Scenario: the types of entities in inferred relations can be used to make further inferences
    Given for each session, graql define
      """
      define

      big-place sub place,
        plays big-location-subordinate,
        plays big-location-superior;

      big-location-hierarchy sub location-hierarchy,
        relates big-location-subordinate as location-subordinate,
        relates big-location-superior as location-superior;

      transitive-location sub rule,
      when {
        (location-subordinate: $x, location-superior: $y) isa location-hierarchy;
        (location-subordinate: $y, location-superior: $z) isa location-hierarchy;
      }, then {
        (location-subordinate: $x, location-superior: $z) isa location-hierarchy;
      };

      if-a-big-thing-is-in-a-big-place-then-its-a-big-location sub rule,
      when {
        $x isa big-place;
        $y isa big-place;
        (location-subordinate: $x, location-superior: $y) isa location-hierarchy;
      }, then {
        (big-location-subordinate: $x, big-location-superior: $y) isa big-location-hierarchy;
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa big-place, has name "Mount Kilimanjaro";
      $y isa place, has name "Tanzania";
      $z isa big-place, has name "Africa";

      (location-subordinate: $x, location-superior: $y) isa location-hierarchy;
      (location-subordinate: $y, location-superior: $z) isa location-hierarchy;
      """
    When materialised keyspace is completed
    Then for graql query
      """
      match (big-location-subordinate: $x, big-location-superior: $y) isa big-location-hierarchy; get;
      """
    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 1
    Then materialised and reasoned keyspaces are the same size


  Scenario: the types of inferred relations can be used to make further inferences
    Given for each session, graql define
      """
      define

      entity1 sub entity,
          plays role11,
          plays role12,
          plays role21,
          plays role22,
          plays role31,
          plays role32;

      relation1 sub relation,
          relates role11,
          relates role12;

      relation2 sub relation,
          relates role21,
          relates role22;

      relation3 sub relation,
          relates role31,
          relates role32;

      relation3-inference sub rule,
      when {
          (role11:$x, role12:$y) isa relation1;
          (role21:$y, role22:$z) isa relation2;
          (role11:$z, role12:$u) isa relation1;
      },
      then {
          (role31:$x, role32:$u) isa relation3;
      };

      relation2-transitivity sub rule,
      when {
          (role21:$x, role22:$y) isa relation2;
          (role21:$y, role22:$z) isa relation2;
      },
      then {
          (role21:$x, role22:$z) isa relation2;
      };
      """
    Given for each session, graql insert
      """
      insert

      $x isa entity1;
      $y isa entity1;
      $z isa entity1;
      $u isa entity1;
      $v isa entity1;
      $w isa entity1;
      $q isa entity1;

      (role11:$x, role12:$y) isa relation1;
      (role21:$y, role22:$z) isa relation2;
      (role21:$z, role22:$u) isa relation2;
      (role21:$u, role22:$v) isa relation2;
      (role21:$v, role22:$w) isa relation2;
      (role11:$w, role12:$q) isa relation1;
      """
    When materialised keyspace is completed
    Then for graql query
      """
      match (role31: $x, role32: $y) isa relation3; get;
      """
    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 1
    Then materialised and reasoned keyspaces are the same size


  Scenario: circular rule dependencies can be resolved
    Given for each session, graql define
      """
      define

      entity1 sub entity,
          plays role11,
          plays role12,
          plays role21,
          plays role22,
          plays role31,
          plays role32;

      relation1 sub relation,
          relates role11,
          relates role12;

      relation2 sub relation,
          relates role21,
          relates role22;

      relation3 sub relation,
          relates role31,
          relates role32;

      relation-1-to-2 sub rule,
      when {
          (role11:$x, role12:$y) isa relation1;
      },
      then {
          (role21:$x, role22:$y) isa relation2;
      };

      relation-3-to-2 sub rule,
      when {
          (role31:$x, role32:$y) isa relation3;
      },
      then {
          (role21:$x, role22:$y) isa relation2;
      };

      relation-2-to-3 sub rule,
      when {
          (role21:$x, role22:$y) isa relation2;
      },
      then {
          (role31:$x, role32:$y) isa relation3;
      };
      """
    Given for each session, graql insert
      """
      insert

      $x isa entity1;
      $y isa entity1;

      (role11:$x, role12:$x) isa relation1;
      (role11:$x, role12:$y) isa relation1;
      """
    When materialised keyspace is completed
    Then for graql query
      """
      match (role31: $x, role32: $y) isa relation3; get;
      """
    Then all answers are correct in reasoned keyspace
    # Each of the two material relation1 instances should infer a single relation3 via 1-to-2 and 2-to-3
    Then answer size in reasoned keyspace is: 2
    Then for graql query
      """
      match (role21: $x, role22: $y) isa relation2; get;
      """
    Then all answers are correct in reasoned keyspace
    # Relation-3-to-2 should not make any additional inferences - it should merely assert that the relations exist
    Then answer size in reasoned keyspace is: 2
    Then materialised and reasoned keyspaces are the same size


  Scenario: when resolution produces an infinite stream of answers, limiting the answer size allows it to terminate
    Given for each session, graql define
      """
      define

      dream sub relation,
        relates dreamer,
        relates dream-subject,
        plays dream-subject;

      person plays dreamer, plays dream-subject;

      inception sub rule,
      when {
        $x isa person;
        $z (dreamer: $x, dream-subject: $y) isa dream;
      }, then {
        (dreamer: $x, dream-subject: $z) isa dream;
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa person, has name "Yusuf";
      # If only Yusuf didn't dream about himself...
      (dreamer: $x, dream-subject: $x) isa dream;
      """
    When materialised keyspace is completed
    Then for graql query
      """
      match $x isa dream; get; limit 10;
      """
    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 10
    Then materialised and reasoned keyspaces are the same size


  #######################
  # UNTYPED MATCH QUERY #
  #######################

  Scenario: the relation type constraint can be excluded from a reasoned match query
    Given for each session, graql define
      """
      define
      transitive-location sub rule,
      when {
        (location-subordinate: $x, location-superior: $y) isa location-hierarchy;
        (location-subordinate: $y, location-superior: $z) isa location-hierarchy;
      }, then {
        (location-subordinate: $x, location-superior: $z) isa location-hierarchy;
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa place, has name "Turku Airport";
      $y isa place, has name "Turku";
      $z isa place, has name "Finland";

      (location-subordinate: $x, location-superior: $y) isa location-hierarchy;
      (location-subordinate: $y, location-superior: $z) isa location-hierarchy;
      """
    When materialised keyspace is completed
    Then for graql query
      """
      match
        $a isa place, has name "Turku Airport";
        ($a, $b);
        $b isa place, has name "Turku";
        ($b, $c);
      get;
      """
    Then all answers are correct in reasoned keyspace
    # $c in {'Turku Airport', 'Finland'}
    Then answer size in reasoned keyspace is: 2
    Then materialised and reasoned keyspaces are the same size


  Scenario: when the relation type is excluded in a reasoned match query, all valid roleplayer combinations are matches
    Given for each session, graql define
      """
      define
      transitive-location sub rule,
      when {
        (location-subordinate: $x, location-superior: $y) isa location-hierarchy;
        (location-subordinate: $y, location-superior: $z) isa location-hierarchy;
      }, then {
        (location-subordinate: $x, location-superior: $z) isa location-hierarchy;
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa place, has name "Turku Airport";
      $y isa place, has name "Turku";
      $z isa place, has name "Finland";

      (location-subordinate: $x, location-superior: $y) isa location-hierarchy;
      (location-subordinate: $y, location-superior: $z) isa location-hierarchy;
      """
    When materialised keyspace is completed
    Given for graql query
      """
      match
        $a isa place, has name "Turku Airport";
        ($a, $b);
        $b isa place, has name "Turku";
      get;
      """
#    Given all answers are correct in reasoned keyspace
    Given answer size in reasoned keyspace is: 1
    Then for graql query
      """
      match
        $a isa place, has name "Turku Airport";
        ($a, $b);
        $b isa place, has name "Turku";
        ($c, $d);
      get;
      """
#    Then all answers are correct in reasoned keyspace
    # (2 db relations + 1 inferred) x 2 for variable swap
    Then answer size in reasoned keyspace is: 6
    Then materialised and reasoned keyspaces are the same size


  Scenario: when the relation type is excluded in a reasoned match query, all types of relations match
    Given for each session, graql define
      """
      define

      loc-hie sub relation, relates loc-sub, relates loc-sup;

      place plays loc-sub, plays loc-sup;

      transitive-location sub rule,
      when {
        (location-subordinate: $x, location-superior: $y) isa location-hierarchy;
        (location-subordinate: $y, location-superior: $z) isa location-hierarchy;
      }, then {
        (location-subordinate: $x, location-superior: $z) isa location-hierarchy;
      };

      long-role-names-suck sub rule,
      when {
        (location-subordinate: $x, location-superior: $y) isa location-hierarchy;
      }, then {
        (loc-sub: $x, loc-sup: $y) isa loc-hie;
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa place, has name "Turku Airport";
      $y isa place, has name "Turku";
      $z isa place, has name "Finland";

      (location-subordinate: $x, location-superior: $y) isa location-hierarchy;
      (location-subordinate: $y, location-superior: $z) isa location-hierarchy;
      """
    When materialised keyspace is completed
    Given for graql query
      """
      match
        ($a, $b) isa relation;
      get;
      """
    Then all answers are correct in reasoned keyspace
    # Despite there being more inferred relations, the answer size is still 6 (as in the previous scenario)
    # because the query is only interested in the related concepts, not in the relation instances themselves
    Then answer size in reasoned keyspace is: 6
    Then answer set is equivalent for graql query
      """
      match ($a, $b); get;
      """
    Then materialised and reasoned keyspaces are the same size


  Scenario: conjunctions of untyped reasoned relations are correctly resolved
    Given for each session, graql define
      """
      define
      transitive-location sub rule,
      when {
        (location-subordinate: $x, location-superior: $y) isa location-hierarchy;
        (location-subordinate: $y, location-superior: $z) isa location-hierarchy;
      }, then {
        (location-subordinate: $x, location-superior: $z) isa location-hierarchy;
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa place, has name "Turku Airport";
      $y isa place, has name "Turku";
      $z isa place, has name "Finland";

      (location-subordinate: $x, location-superior: $y) isa location-hierarchy;
      (location-subordinate: $y, location-superior: $z) isa location-hierarchy;
      """
    When materialised keyspace is completed
    Then for graql query
      """
      match
        ($a, $b);
        ($b, $c);
      get;
      """
    Then all answers are correct in reasoned keyspace
    # All 3 entities are related to each other, so the answer size is just (# of entities x # of variables) = 3 x 3 = 9
    Then answer size in reasoned keyspace is: 9
    Then materialised and reasoned keyspaces are the same size
