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


  # TODO: re-enable all steps once attribute re-attachment is resolvable
  Scenario: when a rule copies an attribute from one entity to another, the existing attribute instance is reused
    Given for each session, graql define
      """
      define
      rule transfer-string-attribute-to-other-people: when {
        $x isa person, has string-attribute $r1;
        $y isa person;
       } then {
        $y has string-attribute $r1;
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
      match $x isa person, has string-attribute $y;
      """
#    Then all answers are correct in reasoned database
    Then answer size in reasoned database is: 2
    Then for graql query
      """
      match $x isa string-attribute;
      """
#    Then all answers are correct in reasoned database
    Then answer size in reasoned database is: 1
#    Then materialised and reasoned databases are the same size


  # TODO: re-enable all steps once re-attachment of unrelated attributes is resolvable
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


  # TODO: re-enable all steps once attribute re-attachment is resolvable
  Scenario: when the same attribute is inferred on an entity and relation, both owners are correctly retrieved
    Given for each session, graql define
      """
      define
      rule transfer-string-attribute-to-other-people: when {
        $x isa person, has string-attribute $r1;
        $y isa person;
       } then {
        $y has string-attribute $r1;
       };

      rule transfer-string-attribute-from-people-to-teams: when {
        $x isa person, has string-attribute $y;
        $z isa team;
       } then {
        $z has string-attribute $y;
       };
      """
    Given for each session, graql insert
      """
      insert
      $geX isa person, has string-attribute "banana";
      $geY isa person;
      (leader:$geX, team-member:$geX) isa team;
      """
#    When materialised database is completed
    Then for graql query
      """
      match $x has string-attribute $y;
      """
#    Then all answers are correct in reasoned database
    Then answer size in reasoned database is: 3
#    Then materialised and reasoned databases are the same size


  Scenario: a rule can infer an attribute value that did not previously exist in the graph
    Given for each session, graql define
      """
      define
      rule tesco-sells-all-soft-drinks: when {
        $x isa soft-drink;
       } then {
        $x has retailer 'Tesco';
       };

      rule if-ocado-exists-it-sells-all-soft-drinks: when {
        $x isa retailer;
        $x == 'Ocado';
        $y isa soft-drink;
       } then {
        $y has retailer 'Ocado';
       };
      """
    Given for each session, graql insert
      """
      insert
      $aeX isa soft-drink;
      $aeY isa soft-drink;
      $r "Ocado" isa retailer;
      """
    When materialised database is completed
    Then for graql query
      """
      match $x has retailer 'Ocado';
      """
    Then all answers are correct in reasoned database
    Then answer size in reasoned database is: 2
    Then for graql query
      """
      match $x has retailer $r;
      """
    Then all answers are correct in reasoned database
    Then answer size in reasoned database is: 4
    Then for graql query
      """
      match $x has retailer 'Tesco';
      """
    Then all answers are correct in reasoned database
    Then answer size in reasoned database is: 2
    Then materialised and reasoned databases are the same size


  Scenario: a rule can make a thing own an attribute that had no prior owners
    Given for each session, graql define
      """
      define
      rule if-ocado-exists-it-sells-all-soft-drinks: when {
        $x isa retailer;
        $x == 'Ocado';
        $y isa soft-drink;
       } then {
        $y has retailer $x;
       };
      """
    Given for each session, graql insert
      """
      insert
      $aeX isa soft-drink;
      $aeY isa soft-drink;
      $r "Ocado" isa retailer;
      """
    When materialised database is completed
    Then for graql query
      """
      match $x isa soft-drink, has retailer 'Ocado';
      """
    Then all answers are correct in reasoned database
    Then answer size in reasoned database is: 2
    Then materialised and reasoned databases are the same size
