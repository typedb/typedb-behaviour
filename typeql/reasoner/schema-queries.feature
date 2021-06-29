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
Feature: Schema Query Resolution (Variable Types)

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
    Given transaction commits
    # each scenario specialises the schema further
    Given session opens transaction of type: write

  # TODO: re-enable all steps once schema queries are resolvable (#75)
  Scenario: all instances and their types can be retrieved
    Given typeql define
      """
      define

      rule maryland: when {
        $x isa person;
      } then {
        $x has name "Mary";
      };

      rule friendship-everlasting: when {
        $x isa person;
        $y isa person;
      } then {
        (friend: $x, friend: $y) isa friendship;
      };
      """
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa person;
      $y isa person;
      $z isa person;
      """
    Given transaction commits
    Given correctness checker is initialised
    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x isa entity;
      """
    Then answer size is: 3
    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x isa relation;
      """
    # (xx, yy, zz, xy, xz, yz)
    Then answer size is: 6
    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x isa attribute;
      """
    Then answer size is: 1
    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x isa $type;
      """
    # 3 people x 3 types of person {person,entity,thing}
    # 6 friendships x 3 types of friendship {friendship, relation, thing}
    # 1 name x 3 types of name {name,attribute,thing}
    # = 9 + 18 + 3 = 30
    Then answer size is: 30
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete


  # TODO: re-enable all steps once schema queries are resolvable (#75)
  Scenario: all relations and their types can be retrieved
    Given typeql define
      """
      define

      rule friendship-eternal: when {
        $x isa person;
        $y isa person;
      } then {
        (friend: $x, friend: $y) isa friendship;
      };
      """
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa person, has name "Annette";
      $y isa person, has name "Richard";
      $z isa person, has name "Rupert";
      """
    Given transaction commits
    Given correctness checker is initialised
    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match ($u, $v) isa relation;
      """
    # (xx, yy, zz, xy, xz, yz, yx, zx, zy)
    Then answer size is: 9
    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match ($u, $v) isa $type;
      """
    # 3 possible $u x 3 possible $v x 3 possible $type {friendship,relation,thing}
    Then answer size is: 27
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete


  # TODO: re-enable all steps once schema queries are resolvable (#75)
  Scenario: all inferred instances of types that can own a given attribute type can be retrieved
    Given typeql define
      """
      define

      residency sub relation,
        relates resident,
        relates residence,
        owns contract;

      contract sub attribute, value string;

      person plays residency:resident;
      place plays residency:residence;

      employment owns contract;

      rule everyone-has-friends: when {
        $x isa person;
      } then {
        (friend: $x) isa friendship;
      };

      rule there-is-no-unemployment: when {
        $x isa person;
      } then {
        (employee: $x) isa employment;
      };

      rule there-are-no-homeless: when {
        $x isa person;
      } then {
        (resident: $x) isa residency;
      };
      """
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa person, has name "Sharon";
      $y isa person, has name "Tobias";
      """
    Given transaction commits
    Given correctness checker is initialised
    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x isa relation;
      """
    Then answer size is: 6
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete
    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match
        $x isa $type;
        $type owns contract;
      """
    # friendship can't have a contract... at least, not in this pristine test world
    # note: enforcing 'has contract' also eliminates 'relation' and 'thing' as possible types
    Then answer size is: 4
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete


  # TODO: re-enable all steps once schema queries are resolvable (#75)
  Scenario: all inferred instances of types that are subtypes of a given type can be retrieved
    Given typeql define
      """
      define

      rule everyone-has-friends: when {
        $x isa person;
      } then {
        (friend: $x) isa friendship;
      };

      rule there-is-no-unemployment: when {
        $x isa person;
      } then {
        (employee: $x) isa employment;
      };
      """
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa person, has name "Annette";
      $y isa person, has name "Richard";
      $z isa person, has name "Rupert";
      """
    Given transaction commits
    Given correctness checker is initialised
    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x isa relation;
      """
    # 3 friendships, 3 employments
    Then answer size is: 6
    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match
        $x isa $type;
        $type sub relation;
      """
    # 3 friendships, 3 employments, 6 relations
    Then answer size is: 12
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete


  # TODO: re-enable all steps once schema queries are resolvable (#75)
  Scenario: all inferred instances of types that can play a given role can be retrieved
    Given typeql define
      """
      define

      residency sub relation,
        relates resident,
        relates residence,
        plays legal-documentation:subject;

      legal-documentation sub relation,
        relates subject,
        relates party;

      person plays legal-documentation:party, plays residency:resident;
      employment plays legal-documentation:subject;

      rule everyone-has-friends: when {
        $x isa person;
      } then {
        (friend: $x) isa friendship;
      };

      rule there-is-no-unemployment: when {
        $x isa person;
      } then {
        (employee: $x) isa employment;
      };

      rule there-are-no-homeless: when {
        $x isa person;
      } then {
        (resident: $x) isa residency;
      };
      """
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa person, has name "Sharon";
      $y isa person, has name "Tobias";
      """
    Given transaction commits
    Given correctness checker is initialised
    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x isa relation;
      """
    Then answer size is: 6
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete
    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match
        $x isa $type;
        $type plays legal-documentation:subject;
      """
    # friendship can't be a documented-thing
    # note: enforcing 'plays legal-documentation:subject' also eliminates 'relation' and 'thing' as possible types
    Then answer size is: 4
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete


  # TODO: implement this once roles are scoped to relations
  Scenario: all inferred instances of relation types that relate a given role can be retrieved


  # TODO: re-enable all steps once schema queries are resolvable (#75)
  Scenario: all roleplayers and their types can be retrieved from a relation
    Given typeql define
      """
      define

      military-person sub person;
      colonel sub military-person;

      rule armed-forces-employ-the-military: when {
        $x isa company, has name "Armed Forces";
        $y isa military-person;
      } then {
        (employee: $y, employer: $x) isa employment;
      };
      """
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa company, has name "Armed Forces";
      $y isa colonel;
      $z isa colonel;
      $w isa colonel;
      """
    Given transaction commits
    Given correctness checker is initialised
    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match (employee: $x, employer: $y) isa employment;
      """
    Then answer size is: 3
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete
    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match
        (employee: $x, employer: $y) isa employment;
        $x isa $type;
      """
    # 3 colonels * 5 supertypes of colonel (colonel, military-person, person, entity, thing)
    Then answer size is: 15
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete
    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match
        ($x, $y) isa employment;
        $x isa $type;
      """
    # (3 colonels * 5 supertypes of colonel * 1 company)
    # + (1 company * 3 supertypes of company * 3 colonels)
    Then answer size is: 24
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete


  Scenario: entity pairs can be matched based on the entity type they are related to
    Given typeql define
      """
      define

      retail-company sub company;
      finance-company sub company;
      """
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert

      $s1 isa person;
      $s2 isa person;
      $s3 isa person;
      $s4 isa person;

      $c1 isa retail-company;
      $c1prime isa retail-company;
      $c2 isa finance-company;
      $c2prime isa finance-company;

      (employee: $s1, employer: $c1) isa employment;
      (employee: $s2, employer: $c1prime) isa employment;
      (employee: $s3, employer: $c2) isa employment;
      (employee: $s4, employer: $c2prime) isa employment;
      """
    Given transaction commits
    Given correctness checker is initialised
    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match
        $x isa person;
        $y isa person;
        (employee: $x, employer: $xx) isa employment;
        $xx isa $type;
        (employee: $y, employer: $yy) isa employment;
        $yy isa $type;
        not { $y is $x; };
      get $x, $y;
      """
    # All companies match when $type is company (or entity)
    # Query returns {ab,ac,ad,bc,bd,cd} and each of them with the variables flipped
    Then answer size is: 12
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete
    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match
        $x isa person;
        $y isa person;
        (employee: $x, employer: $xx) isa employment;
        $xx isa $type;
        (employee: $y, employer: $yy) isa employment;
        $yy isa $type;
        not { $y is $x; };
        $meta type entity; not { $type is $meta; };
        $meta2 type thing; not { $type is $meta2; };
        $meta3 type company; not { $type is $meta3; };
      get $x, $y;
      """
    # $type is forced to be either finance-company or retail-company, restricting the answer space
    # Query returns {ab,cd} and each of them with the variables flipped
    # Note: the two Captain Obvious rules should not affect the answer, as the concepts retain their original types
    Then answer size is: 4
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete
