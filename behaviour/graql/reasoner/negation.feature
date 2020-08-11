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

Feature: Negation Resolution

  Background: Set up databases for resolution testing

    Given connection has been opened
    Given connection delete all databases
    Given connection open sessions for databases:
      | materialised |
      | reasoned     |
    Given materialised database is named: materialised
    Given reasoned database is named: reasoned
    Given for each session, graql define
      """
      define

      person sub entity,
        owns name,
        owns age,
        plays friend,
        plays employee;

      company sub entity,
        owns name,
        plays employer;

      place sub entity,
        owns name,
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
      age sub attribute, value long;
      """


  #####################
  # NEGATION IN MATCH #
  #####################

  # Negation is currently handled by Reasoner, even inside a match clause.

  Scenario: negation can check that an entity does not play a specified role in any relation
    Given for each session, graql insert
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
    Given for graql query
      """
      match $x isa person; get;
      """
    Given answer size in reasoned database is: 5
    Then for graql query
      """
      match
        $x isa person;
        not {
          $e (employee: $x) isa employment;
        };
      get;
      """
    Then answer size in reasoned database is: 3


  Scenario: negation can check that an entity does not play any role in any relation
    Given for each session, graql insert
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
    Given for graql query
      """
      match $x isa person; get;
      """
    Given answer size in reasoned database is: 5
    Then for graql query
      """
      match
        $x isa person;
        not {
          ($x) isa relation;
        };
      get;
      """
    Then answer size in reasoned database is: 3


  Scenario: negation can check that an entity does not own any instance of a specific attribute type
    Given for each session, graql insert
      """
      insert
      $x1 isa person, has name "asdf";
      $x2 isa person, has name "cgt";
      $x3 isa person;
      $x4 isa person, has name "bleh";
      $x5 isa person;
      """
    Given for graql query
      """
      match $x isa person; get;
      """
    Given answer size in reasoned database is: 5
    Then for graql query
      """
      match
        $x isa person;
        not {
          $x has name $val;
        };
      get;
      """
    Then answer size in reasoned database is: 2


  Scenario: negation can check that an entity does not own a particular attribute
    Given for each session, graql insert
      """
      insert
      $x1 isa person, has name "Bob";
      $x2 isa person, has name "cgt";
      $x3 isa person;
      $x4 isa person, has name "bleh";
      $x5 isa person;
      """
    Given for graql query
      """
      match $x isa person; get;
      """
    Given answer size in reasoned database is: 5
    Then for graql query
      """
      match
        $x isa person;
        not {
          $x has name "Bob";
        };
      get;
      """
    Then answer size in reasoned database is: 4


  Scenario: negation can check that an entity owns an attribute which is not equal to a specific value
    Given for each session, graql insert
      """
      insert
      $x isa person, has age 10;
      $y isa person, has age 20;
      $z isa person;
      """
    Then for graql query
      """
      match
        $x has age $y;
        not {$y 20;};
      get;
      """
    Then answer size in reasoned database is: 1
    Then answer set is equivalent for graql query
      """
      match
        $x has age $y;
        $y 10;
      get;
      """


  Scenario: negation can check that an entity owns an attribute that is not of a specified type
    Given for each session, graql insert
      """
      insert
      $x isa person, has age 10, has name "Bob";
      $y isa person, has age 20;
      $z isa person;
      $w isa person, has name "Charlie";
      """
    Then for graql query
      """
      match
        $x has attribute $y;
        not {$y isa name;};
      get;
      """
    Then answer size in reasoned database is: 2
    Then answer set is equivalent for graql query
      """
      match
        $x has age $y;
      get;
      """


  Scenario: negation can filter out an unwanted entity type from part of a chain of matched relations
    Given for each session, graql define
      """
      define
      dog sub entity, plays friend;
      """
    Given for each session, graql insert
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
    Given for graql query
      """
      match
        (friend: $a, friend: $b) isa friendship;
        (friend: $b, friend: $c) isa friendship;
        (friend: $c, friend: $d) isa friendship;
      get;
      """
    # abab, abcb, abcd,
    # baba, babc, bcba, bcbc, bcdc, bcdz,
    # cbab, cbcb, cbcd, cdcb, cdcd, cdzd,
    # dcba, dcbc, dcdc, dcdz, dzdc, dzdz,
    # zdcb, zdcd, zdzd
    Given answer size in reasoned database is: 24
    Then for graql query
      """
      match
        (friend: $a, friend: $b) isa friendship;
        (friend: $b, friend: $c) isa friendship;
        (friend: $c, friend: $d) isa friendship;
        not {$c isa dog;};
      get;
      """
    # Eliminates (cdzd, zdzd)
    Then answer size in reasoned database is: 22
    Then answer set is equivalent for graql query
      """
      match
        (friend: $a, friend: $b) isa friendship;
        (friend: $b, friend: $c) isa friendship;
        (friend: $c, friend: $d) isa friendship;
        $c isa person;
      get;
      """


  Scenario: negation can filter out an unwanted connection between two concepts from a chain of matched relations
    Given for each session, graql define
      """
      define
      dog sub entity, owns name, plays friend;
      """
    Given for each session, graql insert
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
    Given for graql query
      """
      match
        (friend: $a, friend: $b) isa friendship;
        (friend: $b, friend: $c) isa friendship;
      get;
      """
    # aba, abc
    # bab, bcb, bcd
    # cba, cbc, cdc, cdz
    # dcb, dcd, dzd
    # zdc, zdz
    Given answer size in reasoned database is: 14
    Then for graql query
      """
      match
        (friend: $a, friend: $b) isa friendship;
        not {(friend: $b, friend: $z) isa friendship;};
        (friend: $b, friend: $c) isa friendship;
        $z isa dog;
      get;
      """
    # (d,z) is a friendship so we eliminate results where $b is 'd': these are (cdc, cdz, zdc, zdz)
    Then answer size in reasoned database is: 10
    Then answer set is equivalent for graql query
      """
      match
        (friend: $a, friend: $b) isa friendship;
        (friend: $b, friend: $c) isa friendship;
        $z isa dog;
        not {$b has name "d";};
      get;
      """


  Scenario: negation can filter out an unwanted role from a variable role query
    Given for each session, graql insert
      """
      insert

      $x isa person;
      $c isa company;
      (employee: $x, employer: $c) isa employment;
      """
    Given for graql query
      """
      match
        ($r1: $x) isa employment;
      get;
      """
    # r1       | x   |
    # role     | PER |
    # employee | PER |
    # role     | COM |
    # employer | COM |
    Given answer size in reasoned database is: 4
    Then for graql query
      """
      match
        ($r1: $x) isa employment;
        not {$r1 type role;};
      get;
      """
    Then answer size in reasoned database is: 2


  Scenario: a negated statement with multiple properties can be re-written as a negation of multiple statements
    Given for each session, graql insert
      """
      insert

      $x isa person, has name "Tim", has age 45;
      $y isa person, has name "Tim", has age 55;
      $z isa person, has name "Jim", has age 55;
      $w isa person, has name "Winnie";
      $c isa company, has name "Pizza Express";
      """
    Given for graql query
      """
      match
        $x has attribute $r;
      get;
      """
    Given answer size in reasoned database is: 8
    Then for graql query
      """
      match
        $x has attribute $r;
        not {
          $x isa person, has name "Tim", has age 55;
        };
      get;
      """
    Then answer size in reasoned database is: 6
    Then answer set is equivalent for graql query
      """
      match
        $x has attribute $r;
        not {
          $x isa person;
          $x has name "Tim";
          $x has age 55;
        };
      get;
      """


  Scenario: a query can contain multiple negations
    Given for each session, graql insert
      """
      insert

      $x isa person, has name "Tim", has age 45;
      $y isa person, has name "Tim", has age 55;
      $z isa person, has name "Jim", has age 55;
      $w isa person, has name "Winnie";
      $c isa company, has name "Pizza Express";
      """
    Given for graql query
      """
      match
        $x has attribute $r;
      get;
      """
    Given answer size in reasoned database is: 8
    Given for graql query
      """
      match
        $x has attribute $r;
        not { $x isa company; };
      get;
      """
    Given answer size in reasoned database is: 7
    Then for graql query
      """
      match
        $x has attribute $r;
        not { $x isa company; };
        not { $x has name "Tim"; };
      get;
      """
    Then answer size in reasoned database is: 3
    Then for graql query
      """
      match
        $x has attribute $r;
        not { $x isa company; };
        not { $x has name "Tim"; };
        not { $r 55; };
      get;
      """
    Then answer size in reasoned database is: 2


  Scenario: when negating a negation, the statement becomes positive again
    Given for each session, graql insert
      """
      insert

      $x isa person, has name "Tim", has age 45;
      $y isa person, has name "Tim", has age 55;
      $z isa person, has name "Jim", has age 55;
      $w isa person, has name "Winnie";
      $c isa company, has name "Pizza Express";
      """
    Given for graql query
      """
      match
        $x isa person, has name "Tim";
      get;
      """
    Given answer size in reasoned database is: 2
    Then for graql query
      """
      match
        $x isa person, has name "Tim";
        not {
          not {
            $x has age 55;
          };
        };
      get;
      """
    Then answer size in reasoned database is: 1
    Then answer set is equivalent for graql query
      """
      match
        $x isa person, has name "Tim";
        $x has age 55;
      get;
      """


  Scenario: negation can exclude entities of specific types that play roles in a specific relation
    Given for each session, graql define
      """
      define
      pizza-company sub company;
      """
    Given for each session, graql insert
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
    Given for graql query
      """
      match $x isa person; get;
      """
    Then answer size in reasoned database is: 4
    Then for graql query
      """
      match
        $x isa person;
        not {
          (employee: $x, employer: $y) isa employment;
          $y isa pizza-company;
        };
      get;
      """
    Then answer size in reasoned database is: 3


  Scenario: when using negation to exclude entities of specific types, their subtypes are also excluded
    Given for each session, graql define
      """
      define
      pizza-company sub company;
      """
    Given for each session, graql insert
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
    Then for graql query
      """
      match
        $x isa person;
        not {
          (employee: $x, employer: $y) isa employment;
          $y isa company;
        };
      get;
      """
    Then answer size in reasoned database is: 2


  Scenario: answers can be returned even if a statement in a conjunction in a negation is identical to a non-negated one
    Given for each session, graql define
      """
      define
      pizza-company sub company;
      """
    Given for each session, graql insert
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
    Then for graql query
      """
      match
        $x isa person;
        not {
          $x isa person;
          (employee: $x, employer: $y) isa employment;
          $y isa pizza-company;
        };
      get;
      """
    Then answer size in reasoned database is: 3


  ##############################
  # MATCHING INFERRED CONCEPTS #
  ##############################

  Scenario: a negation with a roleplayer but no relation variable checks that no relations have that roleplayer
    Given for each session, graql define
      """
      define
      employment relates manager;
      person plays manager;

      apple-employs-everyone sub rule,
      when {
        $p isa person;
        $c isa company, has name "Apple";
      }, then {
        (employee: $p, employer: $c) isa employment;
      };

      anna-manages-carol sub rule,
      when {
        $r (employee: $x) isa employment;
        $x has name "Carol";
        $y isa person, has name "Anna";
      }, then {
        $r (manager: $y) isa employment;
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa person, has name "Anna";
      $y isa person, has name "Carol";
      $z isa person, has name "Edward";
      $c isa company, has name "Apple";
      """
    When materialised database is completed
    Then for graql query
      """
      match
        (employee: $x, employer: $y) isa employment;
        not {(manager: $x) isa employment;};
      get;
      """
    Then all answers are correct in reasoned database
    # Anna is not retrieved because she is someone's manager
    Then answer size in reasoned database is: 2
    Then materialised and reasoned databases are the same size


  Scenario: a negation with a roleplayer and inferred relation checks that the relation doesn't have that roleplayer
    Given for each session, graql define
      """
      define
      employment relates manager;
      person plays manager;

      apple-employs-everyone sub rule,
      when {
        $p isa person;
        $c isa company, has name "Apple";
      }, then {
        (employee: $p, employer: $c) isa employment;
      };

      anna-manages-carol sub rule,
      when {
        $r (employee: $x) isa employment;
        $x has name "Carol";
        $y isa person, has name "Anna";
      }, then {
        $r (manager: $y) isa employment;
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa person, has name "Anna";
      $y isa person, has name "Carol";
      $z isa person, has name "Edward";
      $c isa company, has name "Apple";
      """
    When materialised database is completed
    Then for graql query
      """
      match
        $r (employee: $x, employer: $y) isa employment;
        not {$r (manager: $x) isa employment;};
      get;
      """
    Then all answers are correct in reasoned database
    # Anna is retrieved because she is not a manager in her own employee-employment relation
    Then answer size in reasoned database is: 3
    Then materialised and reasoned databases are the same size


  Scenario: negation with an unbound roleplayer variable checks that an inferred relation doesn't have that role played
    Given for each session, graql define
      """
      define
      employment relates manager;
      person plays manager;

      apple-employs-everyone sub rule,
      when {
        $p isa person;
        $c isa company, has name "Apple";
      }, then {
        (employee: $p, employer: $c) isa employment;
      };

      anna-manages-carol sub rule,
      when {
        $r (employee: $x) isa employment;
        $x has name "Carol";
        $y isa person, has name "Anna";
      }, then {
        $r (manager: $y) isa employment;
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa person, has name "Anna";
      $y isa person, has name "Carol";
      $z isa person, has name "Edward";
      $c isa company, has name "Apple";
      """
    When materialised database is completed
    Then for graql query
      """
      match
        $r (employee: $x, employer: $y) isa employment;
        not {$r (manager: $z) isa employment;};
      get;
      """
    Then all answers are correct in reasoned database
    # Carol is not retrieved because her employment relation has a manager
    Then answer size in reasoned database is: 2
    Then for graql query
      """
      match
        $r (employee: $x, employer: $y) isa employment;
        not {$r (employee: $z, manager: $z) isa employment;};
      get;
      """
    # Now the negation block is harder to fulfil. Carol is not her own manager, so she is retrieved again
    Then all answers are correct in reasoned database
    Then answer size in reasoned database is: 3
    Then materialised and reasoned databases are the same size


  # TODO: re-enable all steps when 3-hop transitivity is resolvable
  Scenario: negation of a transitive relation is resolvable
    Given for each session, graql define
      """
      define

      area sub place;
      city sub place;
      country sub place;
      continent sub place;

      location-hierarchy-transitivity sub rule,
      when {
          (location-superior: $a, location-subordinate: $b) isa location-hierarchy;
          (location-superior: $b, location-subordinate: $c) isa location-hierarchy;
      }, then {
          (location-superior: $a, location-subordinate: $c) isa location-hierarchy;
      };
      """
    Given for each session, graql insert
      """
      insert
      $ar isa area, has name "King's Cross";
      $cit isa city, has name "London";
      $cntry isa country, has name "UK";
      $cont isa continent, has name "Europe";
      (location-superior: $cont, location-subordinate: $cntry) isa location-hierarchy;
      (location-superior: $cntry, location-subordinate: $cit) isa location-hierarchy;
      (location-superior: $cit, location-subordinate: $ar) isa location-hierarchy;
      """
#    When materialised database is completed
    Given for graql query
      """
      match
        $continent isa continent;
        $area isa area;
      get;
      """
    Then answer size in reasoned database is: 1
    Then for graql query
      """
      match
        $continent isa continent;
        $area isa area;
        not {(location-superior: $continent, location-subordinate: $area) isa location-hierarchy;};
      get;
      """
    Then answer size in reasoned database is: 0
#    Then materialised and reasoned databases are the same size


  Scenario: negation can exclude a particular entity from a matched transitive relation
    Given for each session, graql define
      """
      define

      indexable sub entity,
          owns index;

      traversable sub indexable,
          plays link-from,
          plays link-to,
          plays indirect-from,
          plays indirect-to,
          plays reachable-from,
          plays reachable-to;

      vertex sub traversable;
      node sub traversable;

      link sub relation, relates link-from, relates link-to;
      indirect-link sub relation, relates indirect-from, relates indirect-to;
      reachable sub relation, relates reachable-from, relates reachable-to;

      index sub attribute, value string;

      reachability-transitivityA sub rule,
      when {
          (link-from: $x, link-to: $y) isa link;
      }, then {
          (reachable-from: $x, reachable-to: $y) isa reachable;
      };

      reachability-transitivityB sub rule,
      when {
          (link-from: $x, link-to: $z) isa link;
          (reachable-from: $z, reachable-to: $y) isa reachable;
      }, then {
          (reachable-from: $x, reachable-to: $y) isa reachable;
      };

      indirect-link-rule sub rule,
      when {
          (reachable-from: $x, reachable-to: $y) isa reachable;
          not {(link-from: $x, link-to: $y) isa link;};
      }, then {
          (indirect-from: $x, indirect-to: $y) isa indirect-link;
      };
      """
    Given for each session, graql insert
      """
      insert

      $aa isa node, has index "aa";
      $bb isa node, has index "bb";
      $cc isa node, has index "cc";
      $dd isa node, has index "dd";

      (link-from: $aa, link-to: $bb) isa link;
      (link-from: $bb, link-to: $cc) isa link;
      (link-from: $cc, link-to: $cc) isa link;
      (link-from: $cc, link-to: $dd) isa link;
      """
    Then for graql query
      """
      match
        (indirect-from: $x, indirect-to: $y) isa indirect-link;
        $x has index "aa";
      get;
      """
    Then answer size in reasoned database is: 2
    Then answer set is equivalent for graql query
      """
      match
        (reachable-from: $x, reachable-to: $y) isa reachable;
        $x has index "aa";
        not {$y has index "bb";};
      get;
      """


  #####################
  # NEGATION IN RULES #
  #####################

  # TODO: re-enable all steps when fixed (#75)
  Scenario: a rule can be triggered based on not having a particular attribute
    Given for each session, graql define
      """
      define
      person owns age;
      age sub attribute, value long;
      not-ten sub rule,
      when {
        $x isa person;
        not { $x has age 10; };
      }, then {
        $x has name "Not Ten";
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa person, has age 10;
      $y isa person, has age 20;
      """
    When materialised database is completed
    Then for graql query
      """
      match $x has name "Not Ten", has age 20; get;
      """
#    Then all answers are correct in reasoned database
    Then answer size in reasoned database is: 1
    Then for graql query
      """
      match $x has name "Not Ten", has age 10; get;
      """
    Then answer size in reasoned database is: 0
    Then materialised and reasoned databases are the same size


  Scenario: a rule can be triggered based on not having any instances of a specified attribute type
    Given for each session, graql define
      """
      define
      person owns age;
      age sub attribute, value long;
      not-ten sub rule,
      when {
        $x isa person;
        not { $x has age $val; };
      }, then {
        $x has name "No Age";
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa person, has age 10;
      $y isa person, has age 20;
      $z isa person;
      """
    When materialised database is completed
    Given for graql query
      """
      match $x isa person; get;
      """
    Given all answers are correct in reasoned database
    Given answer size in reasoned database is: 3
    Then for graql query
      """
      match $x isa person, has name "No Age"; get;
      """
    Then answer size in reasoned database is: 1
    Then materialised and reasoned databases are the same size


  Scenario: when negating a conjunction, all the conjuction statements must be met for the negation to be met
    Given for each session, graql define
      """
      define
      country sub entity, owns name, plays country-for-company;
      company plays company-with-country, plays not-in-uk;
      company-country sub relation,
        relates company-with-country,
        relates country-for-company;
      non-uk sub relation,
        relates not-in-uk;
      non-uk-rule sub rule,
      when {
        $x isa company;
        not {
          (company-with-country: $x, country-for-company: $y) isa company-country;
          $y has name 'UK';
        };
      }, then {
        (not-in-uk: $x) isa non-uk;
      };
      """
    Given for each session, graql insert
      """
      insert
      $a isa company, has name "a";
      $b isa company, has name "b";
      $c isa company, has name "c";
      $d isa company, has name "d";

      $e isa country, has name 'UK';
      $f isa country, has name 'France';

      (company-with-country: $a, country-for-company: $e) isa company-country;
      (company-with-country: $b, country-for-company: $e) isa company-country;
      (company-with-country: $c, country-for-company: $f) isa company-country;
      """
    When materialised database is completed
    Given for graql query
      """
      match $x isa company; get;
      """
    Given answer size in reasoned database is: 4
    Then for graql query
      """
      match
        $x isa company;
        not { (not-in-uk: $x) isa non-uk; };
      get;
      """
    # Should exclude both the company in France and the company with no country
    Then answer size in reasoned database is: 2
    Then answer set is equivalent for graql query
      """
      match
        $x isa company;
        (company-with-country: $x, country-for-company: $y) isa company-country;
        $y has name "UK";
      get $x;
      """
    And answer set is equivalent for graql query
      """
      match
        $x isa company;
        { $x has name "a"; } or { $x has name "b"; };
      get;
      """
    Then materialised and reasoned databases are the same size


  Scenario: when nesting multiple negations and conjunctions, they are correctly resolved
    Given for each session, graql define
      """
      define
      country sub entity, owns name, plays country-for-company;
      company plays company-with-country, plays not-in-uk;
      company-country sub relation,
        relates company-with-country,
        relates country-for-company;
      non-uk sub relation,
        relates not-in-uk;
      non-uk-rule sub rule,
      when {
        $x isa company;
        not {
          (company-with-country: $x, country-for-company: $y) isa company-country;
          $y has name 'UK';
        };
      }, then {
        (not-in-uk: $x) isa non-uk;
      };
      """
    Given for each session, graql insert
      """
      insert
      $a isa company, has name "a";
      $b isa company, has name "b";
      $c isa company, has name "c";
      $d isa company, has name "d";

      $e isa country, has name 'UK';
      $f isa country, has name 'France';

      (company-with-country: $a, country-for-company: $e) isa company-country;
      (company-with-country: $b, country-for-company: $e) isa company-country;
      (company-with-country: $c, country-for-company: $f) isa company-country;
      """
    Then for graql query
      """
      match
        $x isa company;
        not {
          (not-in-uk: $x) isa non-uk;
          not {
            $x has name "c";
          };
        };
      get;
      """
    Then answer size in reasoned database is: 3
    Then answer set is equivalent for graql query
      """
      match
        $x isa company;
        not { $x has name "d"; };
      get;
      """


  # TODO: re-enable all steps when fixed (#75)
  Scenario: when evaluating negation blocks, global subgoals are not updated

  The test highlights a potential issue with eagerly updating global subgoals when branching out to determine whether
  negation conditions are met. When checking negation satisfiability, we are interested in a first answer that can
  prove us wrong - we are not exhaustively exploring all answer options.

  Consequently, if we use the same subgoals as for the main loop, we can end up with a query which answers weren't
  fully consumed but that was marked as visited.

  As a result, if it happens that a negated query has multiple answers and is visited more than a single time
  - because of the admissibility check, answers might be missed.

    Given for each session, graql define
      """
      define

      session sub entity,
          plays parent-session;
      fault sub entity,
          plays relevant-fault,
          plays identified-fault,
          plays diagnosed-fault;
      question sub entity,
          owns response,
          plays identifying-question,
          plays question-logged,
          plays question-not-answered;

      response sub attribute, value string;

      reported-fault sub relation,
          relates relevant-fault,
          relates parent-session;

      logged-question sub relation,
          relates question-logged,
          relates parent-session;

      unanswered-question sub relation,
          relates question-not-answered,
          relates parent-session;

      fault-identification sub relation,
          relates identifying-question,
          relates identified-fault;

      diagnosis sub relation,
          relates diagnosed-fault,
          relates parent-session;


      no-response-means-unanswered-question sub rule,
      when {
          $ques isa question;
          (question-logged: $ques, parent-session: $ts) isa logged-question;
          not {
              $ques has response $r;
          };
      }, then {
          (question-not-answered: $ques, parent-session: $ts) isa unanswered-question;
      };

      determined-fault sub rule,
      when {
          (relevant-fault: $flt, parent-session: $ts) isa reported-fault;
          not {
              (question-not-answered: $ques, parent-session: $ts) isa unanswered-question;
              ($flt, $ques) isa fault-identification;
          };
      }, then {
          (diagnosed-fault: $flt, parent-session: $ts) isa diagnosis;
      };
      """
    Given for each session, graql insert
      """
      insert
      $sesh isa session;
      $q1 isa question;
      $q2 isa question;
      $f1 isa fault;
      $f2 isa fault;
      (relevant-fault: $f1, parent-session: $sesh) isa reported-fault;
      (relevant-fault: $f2, parent-session: $sesh) isa reported-fault;

      (question-logged: $q1, parent-session: $sesh) isa logged-question;
      (question-logged: $q2, parent-session: $sesh) isa logged-question;

      (identified-fault: $f1, identifying-question: $q1) isa fault-identification;
      (identified-fault: $f2, identifying-question: $q2) isa fault-identification;
      """
    When materialised database is completed
    Then for graql query
      """
      match (diagnosed-fault: $flt, parent-session: $ts) isa diagnosis; get;
      """
    Then answer size in reasoned database is: 0
    Then answers are consistent across 5 executions in reasoned database
#    Then materialised and reasoned databases are the same size


  # TODO: re-enable all steps when fixed (currently takes too long) (#75)
  Scenario: when evaluating negation blocks, completion of incomplete queries is not acknowledged
    Given for each session, graql define
      """
      define
      resource sub attribute, value string;

      entity-1 sub entity, owns resource, plays role-2, plays role-4;
      entity-2 sub entity, owns resource, plays role-1, plays role-3, plays role-4;
      entity-3 sub entity, owns resource, plays role-1, plays role-3, plays role-4, plays symmetric-role;

      relation-2 sub relation, relates role-1, relates role-2;
      relation-3 sub relation, relates role-3, relates role-4;
      relation-4 sub relation-3, relates role-3, relates role-4;
      relation-5 sub relation-3, relates role-3, relates role-4;
      symmetric-relation sub relation, relates symmetric-role;


      rule-1 sub rule , when {
          (role-3: $x, role-4: $y) isa relation-5;},
      then {
          (role-3: $x, role-4: $y) isa relation-4;};

      rule-2 sub rule , when {
          (role-1: $x, role-2: $y) isa relation-2;
          not {
          (role-3: $x, role-4: $z) isa relation-5;};},
      then {
          (role-3: $x, role-4: $y) isa relation-4;};

      trans-rule sub rule , when {
          (role-3: $y, role-4: $z) isa relation-4;
          (role-3: $x, role-4: $y) isa relation-4;},
      then {
          (role-3: $x, role-4: $z) isa relation-4;};

      rule-3 sub rule , when {
          (symmetric-role: $x, symmetric-role: $y) isa symmetric-relation;},
      then {
          (role-3: $y, role-4: $x) isa relation-5;};
      """
    Given for each session, graql insert
      """
      insert
      $d isa entity-1, has resource "d";
      $e isa entity-2, has resource "e";

      $a isa entity-3, has resource "a";
      $b isa entity-3, has resource "b";
      $c isa entity-3, has resource "c";

      (role-1: $e, role-2: $d)  isa relation-2;
      (role-1: $a, role-2: $d) isa relation-2;
      (role-1: $b, role-2: $d)  isa relation-2;
      (role-1: $c, role-2: $d) isa relation-2;

      (role-3: $a, role-4: $e)  isa relation-5;
      (role-3: $b, role-4: $e)  isa relation-5;
      (role-3: $c, role-4: $e) isa relation-5;

      (symmetric-role: $c, symmetric-role: $b ) isa symmetric-relation;
      """
    When materialised database is completed
    Then for graql query
      """
      match (role-3: $x, role-4: $y) isa relation-4; get;
      """
#    Then all answers are correct in reasoned database
    Then answer size in reasoned database is: 11
    Then answers are consistent across 5 executions in reasoned database
    Then materialised and reasoned databases are the same size


  # TODO: re-enable all steps when fixed (currently takes too long) (#75)
  Scenario: a rule can use negation to exclude things that have any transitive relations to a specific concept
    Given for each session, graql define
      """
      define

      indexable sub entity,
          owns index;

      traversable sub indexable,
          plays link-from,
          plays link-to,
          plays reachable-from,
          plays reachable-to,
          plays unreachable-from,
          plays unreachable-to;

      node sub traversable;

      link sub relation, relates link-from, relates link-to;
      reachable sub relation, relates reachable-from, relates reachable-to;
      unreachable sub relation, relates unreachable-from, relates unreachable-to;

      index sub attribute, value string;

      reachability-transitivityA sub rule,
      when {
          (link-from: $x, link-to: $y) isa link;
      }, then {
          (reachable-from: $x, reachable-to: $y) isa reachable;
      };

      reachability-transitivityB sub rule,
      when {
          (link-from: $x, link-to: $z) isa link;
          (reachable-from: $z, reachable-to: $y) isa reachable;
      }, then {
          (reachable-from: $x, reachable-to: $y) isa reachable;
      };

      unreachability-rule sub rule,
      when {
          $x isa node;
          $y isa node;
          not {(reachable-from: $x, reachable-to: $y) isa reachable;};
      }, then {
          (unreachable-from: $x, unreachable-to: $y) isa unreachable;
      };
      """
    Given for each session, graql insert
      """
      insert

      $aa isa node, has index "aa";
      $bb isa node, has index "bb";
      $cc isa node, has index "cc";
      $dd isa node, has index "dd";
      $ee isa node, has index "ee";
      $ff isa node, has index "ff";
      $gg isa node, has index "gg";
      $hh isa node, has index "hh";

      (link-from: $aa, link-to: $bb) isa link;
      (link-from: $bb, link-to: $cc) isa link;
      (link-from: $cc, link-to: $cc) isa link;
      (link-from: $cc, link-to: $dd) isa link;
      (link-from: $ee, link-to: $ff) isa link;
      (link-from: $ff, link-to: $gg) isa link;
      """
    # When materialised database is completed
    Then for graql query
      """
      match
        (unreachable-from: $x, unreachable-to: $y) isa unreachable;
        $x has index "aa";
      get;
      """
    # aa is not linked to itself. ee, ff, gg are linked to each other, but not to aa. hh is not linked to anything
    Then answer size in reasoned database is: 5
    Then answer set is equivalent for graql query
      """
      match
        $x has index "aa";
        { $y has index "aa"; } or { $y has index "ee"; } or { $y has index "ff"; } or
        { $y has index "gg"; } or { $y has index "hh"; };
      get;
      """
    # Then materialised and reasoned databases are the same size  
