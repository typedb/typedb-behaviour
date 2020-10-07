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

Feature: Roleplayer Attachment Resolution

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

  # TODO: re-enable all steps when fixed (#75)
  Scenario: a rule can attach an additional roleplayer to an existing relation
    Given for each session, graql define
      """
      define
      dominion sub relation, relates ruler, relates ruled-person;
      giant-turtle sub entity, plays dominion:ruler;
      person plays dominion:ruled-person;

      rule giant-turtles-rule-the-world: when {
        $r (ruled-person: $p) isa dominion;
        $gt isa giant-turtle;
      } then {
        $r (ruler: $gt) isa dominion;
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa person;
      $y isa person;
      $z isa giant-turtle;

      (ruled-person: $x) isa dominion;
      (ruled-person: $y) isa dominion;
      """
    When materialised database is completed
    Then for graql query
      """
      match (ruled-person: $x, ruler: $y) isa dominion;
      """
#    Then all answers are correct in reasoned database
    Then answer size in reasoned database is: 2
    Then materialised and reasoned databases are the same size


  # TODO: re-enable all steps when fixed (#75)
  Scenario: additional roleplayers attached to relations can be retrieved without specifying the relation type
    Given for each session, graql define
      """
      define
      dominion sub relation, relates ruler, relates ruled-person;
      giant-turtle sub entity, plays dominion:ruler;
      person plays dominion:ruled-person;

      rule giant-turtles-rule-the-world: when {
        $r (ruled-person: $p) isa dominion;
        $gt isa giant-turtle;
      } then {
        $r (ruler: $gt) isa dominion;
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa person;
      $y isa person;
      $z isa giant-turtle;

      (ruled-person: $x) isa dominion;
      (ruled-person: $y) isa dominion;
      """
    When materialised database is completed
    Then for graql query
      """
      match (ruled-person: $x, ruler: $y);
      """
#    Then all answers are correct in reasoned database
    Then answer size in reasoned database is: 2
    Then materialised and reasoned databases are the same size


  # TODO: re-enable all steps when fixed (#75)
  Scenario: a rule can make an existing relation roleplayer play an additional role in that relation
    Given for each session, graql define
      """
      define
      ship-crew sub relation, relates captain, relates navigator, relates chef;
      person plays ship-crew:captain, plays ship-crew:navigator, plays ship-crew:chef;

      rule i-am-the-cook-therefore-i-am-the-captain: when {
        $r (chef: $p) isa ship-crew;
      } then {
        $r (captain: $p) isa ship-crew;
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa person, has name "Cook";
      $y isa person, has name "Raleigh";

      (navigator: $y, chef: $x) isa ship-crew;
      """
    When materialised database is completed
    Then for graql query
      """
      match (captain: $x, navigator: $y) isa ship-crew;
      """
#    Then all answers are correct in reasoned database
    Then answer size in reasoned database is: 1
    Then answer set is equivalent for graql query
      """
      match (captain: $x, navigator: $y, chef: $x) isa ship-crew;
      """
    Then materialised and reasoned databases are the same size


  # TODO: re-enable all steps when fixed (#75)
  Scenario: a rule can make an existing relation roleplayer play that role an additional time
    Given for each session, graql define
      """
      define
      ship-crew sub relation, relates captain, relates navigator, relates chef;
      person plays ship-crew:captain, plays ship-crew:navigator, plays ship-crew:chef;

      rule i-really-am-the-captain: when {
        $r (captain: $p) isa ship-crew;
      } then {
        $r (captain: $p, captain: $p) isa ship-crew;
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa person, has name "Captain Obvious";
      $y isa person, has name "Bob";

      (navigator: $y, captain: $x) isa ship-crew;
      """
    When materialised database is completed
    Then for graql query
      """
      match (captain: $x, captain: $x) isa ship-crew;
      """
#    Then all answers are correct in reasoned database
    Then answer size in reasoned database is: 1
    Then for graql query
      """
      match (captain: $x, captain: $x, captain: $x) isa ship-crew;
      """
    # too many captains - no match
    Then answer size in reasoned database is: 0
    Then for graql query
      """
      match (captain: $x) isa ship-crew;
      """
#    Then all answers are correct in reasoned database
    # we have more captains than we need, but there is still only 1 matching relation instance
    Then answer size in reasoned database is: 1
    Then materialised and reasoned databases are the same size


  # TODO: re-enable all steps when fixed (#75)
  Scenario: when copying a roleplayer to another role, making it a duplicate role, the players are retrieved correctly
    Given for each session, graql define
      """
      define
      ship-crew sub relation, relates captain, relates navigator, relates chef;
      person plays ship-crew:captain, plays ship-crew:navigator, plays ship-crew:chef;

      rule the-captain-is-required-to-assist-the-navigator: when {
        $r (captain: $y, navigator: $z) isa ship-crew;
      } then {
        $r (navigator: $y) isa ship-crew;
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa person, has name "Maria";
      $y isa person, has name "Isabella";

      (captain: $x, navigator: $y) isa ship-crew;
      """
    When materialised database is completed
    Then for graql query
      """
      match (navigator: $x, navigator: $y) isa ship-crew;
      """
#    Then all answers are correct in reasoned database
    # x        | y        |
    # Maria    | Isabella |
    # Isabella | Maria    |
    Then answer size in reasoned database is: 2
    Then answer set is equivalent for graql query
      """
      match
        (navigator: $x, navigator: $y) isa ship-crew;
        $x != $y;
      """
    Then materialised and reasoned databases are the same size
