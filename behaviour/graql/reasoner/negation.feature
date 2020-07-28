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


  # TODO: re-enable when fixed (#75)
  Scenario: a rule can be triggered based on not having a particular attribute
    Given for each session, graql define
      """
      define
      person has age;
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
    When materialised keyspace is completed
    Then for graql query
      """
      match $x has name "Not Ten", has age 20; get;
      """
#    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 1
    Then for graql query
      """
      match $x has name "Not Ten", has age 10; get;
      """
    Then answer size in reasoned keyspace is: 0
    Then materialised and reasoned keyspaces are the same size


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
    When materialised keyspace is completed
    Then for graql query
      """
      match
        (employee: $x, employer: $y) isa employment;
        not {(manager: $x) isa employment;};
      get;
      """
    Then all answers are correct in reasoned keyspace
    # Anna is not retrieved because she is someone's manager
    Then answer size in reasoned keyspace is: 2
    Then materialised and reasoned keyspaces are the same size


  Scenario: a negation with a roleplayer and relation variable checks that the relation doesn't have that roleplayer
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
    When materialised keyspace is completed
    Then for graql query
      """
      match
        $r (employee: $x, employer: $y) isa employment;
        not {$r (manager: $x) isa employment;};
      get;
      """
    Then all answers are correct in reasoned keyspace
    # Anna is retrieved because she is not a manager in her own employee-employment relation
    Then answer size in reasoned keyspace is: 3
    Then materialised and reasoned keyspaces are the same size


  Scenario: a negation with unbound roleplayer variables checks that the relation doesn't have any player for that role
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
    When materialised keyspace is completed
    Then for graql query
      """
      match
        $r (employee: $x, employer: $y) isa employment;
        not {$r (manager: $z) isa employment;};
      get;
      """
    Then all answers are correct in reasoned keyspace
    # Carol is not retrieved because her employment relation has a manager
    Then answer size in reasoned keyspace is: 2
    Then for graql query
      """
      match
        $r (employee: $x, employer: $y) isa employment;
        not {$r (employee: $z, manager: $z) isa employment;};
      get;
      """
    # Now the negation block is harder to fulfil. Carol is not her own manager, so she is retrieved again
    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 3
    Then materialised and reasoned keyspaces are the same size
