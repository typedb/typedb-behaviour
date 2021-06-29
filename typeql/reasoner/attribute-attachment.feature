#
# Copyright (C) 2021 Vaticle
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

#noinspection CucumberUndefinedStep
Feature: Attribute Attachment Resolution

  Background: Set up database
    Given connection has been opened
    Given connection does not have any database
    Given connection create database: typedb
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write
    Given typeql define
      """
      define

      person sub entity,
          plays team:leader,
          plays team:member,
          owns string-attribute,
          owns unrelated-attribute,
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
      unrelated-attribute sub attribute, value string;
      """
    Given transaction commits
    Given session opens transaction of type: write


  Scenario: when a rule copies an attribute from one entity to another, the existing attribute instance is reused
    Given typeql define
      """
      define
      rule transfer-string-attribute-to-other-people: when {
        $x isa person, has string-attribute $r1;
        $y isa person;
      } then {
        $y has $r1;
      };
      """
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $geX isa person, has string-attribute "banana";
      $geY isa person;
      """
    Given transaction commits
    Given correctness checker is initialised
    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x isa person, has string-attribute $y;
      """
    Then answer size is: 2
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete
    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x isa string-attribute;
      """
    Then answer size is: 1
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete


  Scenario: when the same attribute is inferred on an entity and relation, both owners are correctly retrieved
    Given typeql define
      """
      define
      rule transfer-string-attribute-to-other-people: when {
        $x isa person, has string-attribute $r1;
        $y isa person;
      } then {
        $y has $r1;
      };

      rule transfer-string-attribute-from-people-to-teams: when {
        $x isa person, has string-attribute $y;
        $z isa team;
      } then {
        $z has $y;
      };
      """
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $geX isa person, has string-attribute "banana";
      $geY isa person;
      (leader:$geX, member:$geX) isa team;
      """
    Given transaction commits
    Given correctness checker is initialised
    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x has string-attribute $y;
      """
    Then answer size is: 3
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete


  Scenario: a rule can infer an attribute value that did not previously exist in the graph
    Given typeql define
      """
      define
      rule tesco-sells-all-soft-drinks: when {
        $x isa soft-drink;
      } then {
        $x has retailer 'Tesco';
      };

      rule if-ocado-exists-it-sells-all-soft-drinks: when {
        $x isa retailer;
        $x = 'Ocado';
        $y isa soft-drink;
      } then {
        $y has retailer 'Ocado';
      };
      """
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $aeX isa soft-drink;
      $aeY isa soft-drink;
      $r "Ocado" isa retailer;
      """
    Given transaction commits
    Given correctness checker is initialised
    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x has retailer 'Ocado';
      """
    Then answer size is: 2
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete
    Then connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x has retailer $r;
      """
    Then answer size is: 4
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete
    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x has retailer 'Tesco';
      """
    Then answer size is: 2
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete


  Scenario: a rule can make a thing own an attribute that had no prior owners
    Given typeql define
      """
      define
      rule if-ocado-exists-it-sells-all-soft-drinks: when {
        $x isa retailer;
        $x = 'Ocado';
        $y isa soft-drink;
      } then {
        $y has $x;
      };
      """
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $aeX isa soft-drink;
      $aeY isa soft-drink;
      $r "Ocado" isa retailer;
      """
    Given transaction commits
    Given correctness checker is initialised
    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x isa soft-drink, has retailer 'Ocado';
      """
    Then answer size is: 2
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete


  Scenario: Querying for anonymous attributes with predicates finds the correct answers
    Given typeql define
      """
      define
      rule people-have-a-specific-age: when {
        $x isa person;
      } then {
        $x has age 10;
      };
      """
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $geY isa person;
      """
    Given transaction commits
    Given correctness checker is initialised
    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x has age > 20;
      """
    Then answer size is: 0
    Then session transaction closes
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete

    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x has age > 5;
      """
    Then answer size is: 1
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete
