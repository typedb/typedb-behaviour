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


#  NOTE
#  This file is retained as a placeholder for future functionality
#  The following tests can no longer be run due to restrictions on HAS constraints in then clauses.
#  The ability to take the value of one attribute and give it to another will, however, be useful
#  Therefore every test here will be ignored until further change.

Feature: A description

#noinspection CucumberUndefinedStep
Feature: Attribute Attachment Resolution
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
          plays team:leader,
          plays team:member,
          owns string-attribute,
          owns unrelated-attribute,
          owns sub-string-attribute,
          owns age,
          owns is-old;

      tortoise sub entity,
          owns age,
          owns is-old;

      soft-drink sub entity,
          owns retailer;

      team sub relation,
          relates leader,
          relates member,
          owns string-attribute;

      string-attribute sub attribute, value string;
      retailer sub attribute, value string;
      age sub attribute, value long;
      is-old sub attribute, value boolean;
      sub-string-attribute sub string-attribute;
      unrelated-attribute sub attribute, value string;
      """

      # TODO: re-enable all steps once re-attachment of unrelated attributes is resolvable
  @Ignore
  Scenario: when multiple rules copy attributes from an entity, they all get resolved
    Given for each session, graql define
      """
      define
      rule transfer-string-attribute-to-other-people: when {
        $x isa person, has string-attribute $r1;
        $y isa person;
      } then {
        $y has string-attribute $r1;
      };

      rule transfer-attribute-value-to-sub-attribute: when {
        $x isa person, has string-attribute $r1;
      } then {
        $x has sub-string-attribute $r1;
      };

      rule transfer-attribute-value-to-unrelated-attribute: when {
        $x isa person, has string-attribute $r1;
        $r2 isa unrelated-attribute;
      } then {
        $x has unrelated-attribute $r1;
      };
      """
    Given for each session, graql insert
      """
      insert
      $geX isa person, has string-attribute "banana";
      $geY isa person;
      """
#    When materialised database is completed
    Then for graql query
      """
      match $x isa person;
      """
#    Then all answers are correct in reasoned database
    Then answer size in reasoned database is: 2
    Then for graql query
      """
      match $x isa person, has attribute $y;
      """
    # four attributes for each entity
#    Then all answers are correct in reasoned database
    Then answer size in reasoned database is: 6
#    Then materialised and reasoned databases are the same size


  @Ignore
   # TODO: re-enable all steps once re-attachment of unrelated attributes is resolvable
  Scenario: when a rule copies an attribute value to its sub-attribute, a new attribute concept is inferred
    Given for each session, graql define
      """
      define
      rule transfer-attribute-value-to-sub-attribute: when {
        $x isa person, has string-attribute $r1;
      } then {
        $x has sub-string-attribute $r1;
      };
      """
    Given for each session, graql insert
      """
      insert
      $geX isa person, has string-attribute "banana";
      """
#    When materialised database is completed
    Then for graql query
      """
      match $x isa person, has sub-string-attribute $y;
      """
#    Then all answers are correct in reasoned database
    Then answer size in reasoned database is: 1
    Then for graql query
      """
      match $x isa sub-string-attribute;
      """
#    Then all answers are correct in reasoned database
    Then answer size in reasoned database is: 1
    Then for graql query
      """
      match $x isa string-attribute; $y isa sub-string-attribute;
      """
    # 2 SA instances - one base, one sub hence two answers
#    Then all answers are correct in reasoned database
    Then answer size in reasoned database is: 2
#    Then materialised and reasoned databases are the same size


  @Ignore
  # TODO: re-enable all steps once re-attachment of unrelated attributes is resolvable
  Scenario: when a rule copies an attribute value to an unrelated attribute, a new attribute concept is inferred
    Given for each session, graql define
      """
      define
      rule transfer-attribute-value-to-unrelated-attribute: when {
        $x isa person, has string-attribute $r1;
      } then {
        $x has unrelated-attribute $r1;
      };
      """
    Given for each session, graql insert
      """
      insert
      $geX isa person, has string-attribute "banana";
      $geY isa person;
      """
#    When materialised database is completed
    Then for graql query
      """
      match $x isa person, has unrelated-attribute $y;
      """
#    Then all answers are correct in reasoned database
    Then answer size in reasoned database is: 1
    Then for graql query
      """
      match $x isa unrelated-attribute;
      """
#    Then all answers are correct in reasoned database
    Then answer size in reasoned database is: 1
#    Then materialised and reasoned databases are the same size


  @Ignore
  # TODO: re-enable all steps once attribute re-attachment is resolvable
  # TODO: move to negation.feature
  Scenario: when matching a pair of unrelated inferred attributes with negation and =, the answers are unequal
    Given for each session, graql define
      """
      define
      rule transfer-string-attribute-to-other-people: when {
        $x isa person, has string-attribute $r1;
        $y isa person;
      } then {
        $y has string-attribute $r1;
      };

      rule tesco-sells-all-soft-drinks: when {
        $x isa soft-drink;
      } then {
        $x has retailer 'Tesco';
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa person, has name "Alice", has string-attribute "Tesco";
      $y isa person, has name "Bob", has string-attribute "Safeway";
      $z isa soft-drink, has name "Tango";
      """
#    When materialised database is completed
    Then for graql query
      """
      match
        $x has retailer $re;
        $y has string-attribute $sa;
        not { $re = $sa; };
      """
#    Then all answers are correct in reasoned database
    # The string-attributes are transferred to each other, so in fact both people have both Tesco and Safeway
    # x     | re    | y     | sa      |
    # Tango | Tesco | Alice | Safeway |
    # Tango | Tesco | Bob   | Safeway |
    Then answer size in reasoned database is: 2
#    Then materialised and reasoned databases are the same size

  @Ignore
   # TODO: re-enable all steps once attribute re-attachment is resolvable
  Scenario: when matching a pair of unrelated inferred attributes with '!=', the answers are unequal
    Given for each session, graql define
      """
      define
      rule transfer-string-attribute-to-other-people: when {
        $x isa person, has string-attribute $r1;
        $y isa person;
      } then {
        $y has string-attribute $r1;
      };

      rule tesco-sells-all-soft-drinks: when {
        $x isa soft-drink;
      } then {
        $x has retailer 'Tesco';
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa person, has name "Alice", has string-attribute "Tesco";
      $y isa person, has name "Bob", has string-attribute "Safeway";
      $z isa soft-drink, has name "Tango";
      """
#    When materialised database is completed
    Then for graql query
      """
      match
        $x has retailer $re;
        $y has string-attribute $sa;
        $re != $sa;
      """
#    Then all answers are correct in reasoned database
    # The string-attributes are transferred to each other, so in fact both people have both Tesco and Safeway
    # x     | re    | y     | sa      |
    # Tango | Tesco | Alice | Safeway |
    # Tango | Tesco | Bob   | Safeway |
    Then answer size in reasoned database is: 2
#    Then materialised and reasoned databases are the same size
