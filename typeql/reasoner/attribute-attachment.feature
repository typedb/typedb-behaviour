#
# Copyright (C) 2022 Vaticle
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
    Given typedb starts
    Given connection opens without authentication
    Given reasoning schema
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


  Scenario: when a rule copies an attribute from one entity to another, the existing attribute instance is reused
    Given reasoning schema
      """
      define
      rule transfer-string-attribute-to-other-people: when {
        $x isa person, has string-attribute $r1;
        $y isa person;
      } then {
        $y has $r1;
      };
      """
    Given reasoning data
      """
      insert
      $geX isa person, has string-attribute "banana";
      $geY isa person;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match $x isa person, has string-attribute $y;
      """
    Then verify answer size is: 2
    Then verify answers are sound
    Then verify answers are complete
    Given reasoning query
      """
      match $x isa string-attribute;
      """
    Then verify answer size is: 1
    Then verify answers are sound
    Then verify answers are complete


  Scenario: when the same attribute is inferred on an entity and relation, both owners are correctly retrieved
    Given reasoning schema
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
    Given reasoning data
      """
      insert
      $geX isa person, has string-attribute "banana";
      $geY isa person;
      (leader:$geX, member:$geX) isa team;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match $x has string-attribute $y;
      """
    Then verify answer size is: 3
    Then verify answers are sound
    Then verify answers are complete


  Scenario: a rule can infer an attribute value that did not previously exist in the graph
    Given reasoning schema
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
    Given reasoning data
      """
      insert
      $aeX isa soft-drink;
      $aeY isa soft-drink;
      $r "Ocado" isa retailer;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match $x has retailer 'Ocado';
      """
    Then verify answer size is: 2
    Then verify answers are sound
    Then verify answers are complete
    Given reasoning query
      """
      match $x has retailer $r;
      """
    Then verify answer size is: 4
    Then verify answers are sound
    Then verify answers are complete
    Given reasoning query
      """
      match $x has retailer 'Tesco';
      """
    Then verify answer size is: 2
    Then verify answers are sound
    Then verify answers are complete


  Scenario: a rule can make a thing own an attribute that had no prior owners
    Given reasoning schema
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
    Given reasoning data
      """
      insert
      $aeX isa soft-drink;
      $aeY isa soft-drink;
      $r "Ocado" isa retailer;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match $x isa soft-drink, has retailer 'Ocado';
      """
    Then verify answer size is: 2
    Then verify answers are sound
    Then verify answers are complete


  Scenario: a rule with disjunctions considers every branch
    Given reasoning schema
      """
      define
      crisps sub entity, owns retailer;
      rule tesco-sells-everything-ocado-sells-and-all-soft-drinks: when {
        $x isa $t;
        {$x has retailer 'Ocado';} or {$t type soft-drink;};
      } then {
        $x has retailer 'Tesco';
      };
      """
    Given reasoning data
      """
      insert
      $aeW isa crisps;
      $aeX isa crisps, has retailer 'Ocado';
      $aeY isa soft-drink;
      $aeZ isa soft-drink;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match $x has retailer 'Tesco';
      """
    Then verify answer size is: 3
    Then verify answers are sound
    Then verify answers are complete
    Then verify answer set is equivalent for query
      """
      match
      $x isa $t;
      {$x has retailer 'Ocado';} or {$t type soft-drink;};
      get $x;
      """


  Scenario: a rule with negated disjunctions considers every branch
    Given reasoning schema
      """
      define
      crisps sub entity, owns retailer;
      rule tesco-sells-everything-that-Ocado-doesnt-except-soft-drinks: when {
        $x isa $t; $t owns retailer;
        not { {$x has retailer 'Ocado';} or {$t type soft-drink;}; };
      } then {
        $x has retailer 'Tesco';
      };
      """
    Given reasoning data
      """
      insert
      $aeW isa crisps;
      $aeX isa crisps, has retailer 'Ocado';
      $aeY isa soft-drink;
      $aeZ isa soft-drink;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match $x has retailer 'Tesco';
      """
    Then verify answer size is: 1
    Then verify answers are sound
    Then verify answers are complete
    Then verify answer set is equivalent for query
      """
      match
      $x isa $t; $t owns retailer;
      not {$x has retailer 'Ocado';}; not {$t type soft-drink;};
      get $x;
      """


  Scenario: Querying for anonymous attributes with predicates finds the correct answers
    Given reasoning schema
      """
      define
      rule people-have-a-specific-age: when {
        $x isa person;
      } then {
        $x has age 10;
      };
      """
    Given reasoning data
      """
      insert
      $geY isa person;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match $x has age > 20;
      """
    Then verify answer size is: 0
    Then verify answers are sound
    Then verify answers are complete
    Given reasoning query
      """
      match $x has age > 5;
      """
    Then verify answer size is: 1
    Then verify answers are sound
    Then verify answers are complete
    Given reasoning query
      """
      match $x has age > 5; $x has age < 8;
      """
    Then verify answer size is: 0
    Then verify answers are sound
    Then verify answers are complete
