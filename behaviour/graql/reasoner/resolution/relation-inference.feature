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

      friendship sub relation,
        relates friend;

      employment sub relation,
        relates employee,
        relates employer;

      name sub attribute, value string;
      """


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
