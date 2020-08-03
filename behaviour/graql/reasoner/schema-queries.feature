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

Feature: Schema Query Resolution (Variable Types)

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


  # TODO: re-enable all steps once schema queries are resolvable (#75)
  Scenario: all instances and their types can be retrieved
    Given for each session, graql define
      """
      define

      maryland sub rule,
      when {
        $x isa person;
      }, then {
        $x has name "Mary";
      };

      friendship-everlasting sub rule,
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
      $x isa person;
      $y isa person;
      $z isa person;
      """
    When materialised database is completed
    Given for graql query
      """
      match $x isa entity; get;
      """
    Given answer size in reasoned database is: 3
    Given for graql query
      """
      match $x isa relation; get;
      """
    # (xx, yy, zz, xy, xz, yz)
    Given answer size in reasoned database is: 6
    Given for graql query
      """
      match $x isa attribute; get;
      """
    Given answer size in reasoned database is: 1
    Then for graql query
      """
      match $x isa $type; get;
      """
#    Then all answers are correct in reasoned database
    # 3 people x 3 types of person {person,entity,thing}
    # 6 friendships x 3 types of friendship {friendship, relation, thing}
    # 1 name x 3 types of name {name,attribute,thing}
    # = 9 + 18 + 3 = 30
    Then answer size in reasoned database is: 30
    Then materialised and reasoned databases are the same size


  @ignore
  # TODO: re-enable when match ($a, $b) isa $type returns 'thing', 'relation' as $type for inferred rels (grakn#5850)
  # TODO: re-enable all steps once schema queries are resolvable (#75)
  Scenario: all relations and their types can be retrieved
    Given for each session, graql define
      """
      define

      friendship-eternal sub rule,
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
      $x isa person, has name "Annette";
      $y isa person, has name "Richard";
      $z isa person, has name "Rupert";
      """
    When materialised database is completed
    Given for graql query
      """
      match ($u, $v) isa relation; get;
      """
    # (xx, yy, zz, xy, xz, yz, yx, zx, zy)
    Given answer size in reasoned database is: 9
    Then for graql query
      """
      match ($u, $v) isa $type; get;
      """
#    Then all answers are correct in reasoned database
    # 3 possible $u x 3 possible $v x 3 possible $type {friendship,relation,thing}
    Then answer size in reasoned database is: 27
    Then materialised and reasoned databases are the same size


  # TODO: re-enable all steps once schema queries are resolvable (#75)
  Scenario: all inferred instances of types that can own a given attribute type can be retrieved
    Given for each session, graql define
      """
      define

      residency sub relation,
        relates resident,
        relates residence,
        has contract;

      contract sub attribute, value string;

      person plays resident;
      place plays residence;

      employment has contract;

      everyone-has-friends sub rule,
      when {
        $x isa person;
      }, then {
        (friend: $x) isa friendship;
      };

      there-is-no-unemployment sub rule,
      when {
        $x isa person;
      }, then {
        (employee: $x) isa employment;
      };

      there-are-no-homeless sub rule,
      when {
        $x isa person;
      }, then {
        (resident: $x) isa residency;
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa person, has name "Sharon";
      $y isa person, has name "Tobias";
      """
    When materialised database is completed
    Given for graql query
      """
      match
        $x isa relation;
      get;
      """
    Given all answers are correct in reasoned database
    Given answer size in reasoned database is: 6
    Then for graql query
      """
      match
        $x isa $type;
        $type has contract;
      get;
      """
#    Then all answers are correct in reasoned database
    # friendship can't have a contract... at least, not in this pristine test world
    # note: enforcing 'has contract' also eliminates 'relation' and 'thing' as possible types
    Then answer size in reasoned database is: 4
    Then materialised and reasoned databases are the same size


  # TODO: re-enable all steps once schema queries are resolvable (#75)
  Scenario: all inferred instances of types that are subtypes of a given type can be retrieved
    Given for each session, graql define
      """
      define

      everyone-has-friends sub rule,
      when {
        $x isa person;
      }, then {
        (friend: $x) isa friendship;
      };

      there-is-no-unemployment sub rule,
      when {
        $x isa person;
      }, then {
        (employee: $x) isa employment;
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa person, has name "Annette";
      $y isa person, has name "Richard";
      $z isa person, has name "Rupert";
      """
    When materialised database is completed
    Given for graql query
      """
      match $x isa relation; get;
      """
    # 3 friendships, 3 employments
    Given answer size in reasoned database is: 6
    Then for graql query
      """
      match
        $x isa $type;
        $type sub relation;
      get;
      """
#    Then all answers are correct in reasoned database
    # 3 friendships, 3 employments, 6 relations
    Then answer size in reasoned database is: 12
    Then materialised and reasoned databases are the same size


  # TODO: re-enable all steps once schema queries are resolvable (#75)
  Scenario: all inferred instances of types that can play a given role can be retrieved
    Given for each session, graql define
      """
      define

      residency sub relation,
        relates resident,
        relates residence,
        plays documented-thing;

      legal-documentation sub relation,
        relates documented-thing,
        relates consenting-party;

      person plays consenting-party, plays resident;
      employment plays documented-thing;

      everyone-has-friends sub rule,
      when {
        $x isa person;
      }, then {
        (friend: $x) isa friendship;
      };

      there-is-no-unemployment sub rule,
      when {
        $x isa person;
      }, then {
        (employee: $x) isa employment;
      };

      there-are-no-homeless sub rule,
      when {
        $x isa person;
      }, then {
        (resident: $x) isa residency;
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa person, has name "Sharon";
      $y isa person, has name "Tobias";
      """
    When materialised database is completed
    Given for graql query
      """
      match
        $x isa relation;
      get;
      """
    Given all answers are correct in reasoned database
    Given answer size in reasoned database is: 6
    Then for graql query
      """
      match
        $x isa $type;
        $type plays documented-thing;
      get;
      """
#    Then all answers are correct in reasoned database
    # friendship can't be a documented-thing
    # note: enforcing 'plays documented-thing' also eliminates 'relation' and 'thing' as possible types
    Then answer size in reasoned database is: 4
    Then materialised and reasoned databases are the same size


  # TODO: implement this once roles are scoped to relations
  Scenario: all inferred instances of relation types that relate a given role can be retrieved


  # TODO: re-enable all steps once schema queries are resolvable (#75)
  Scenario: all roleplayers and their types can be retrieved from a relation
    Given for each session, graql define
      """
      define

      military-person sub person;
      colonel sub military-person,
        plays employee;

      armed-forces-employ-the-military sub rule,
      when {
        $x isa company, has name "Armed Forces";
        $y isa military-person;
      }, then {
        (employee: $y, employer: $x) isa employment;
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa company, has name "Armed Forces";
      $y isa colonel;
      $z isa colonel;
      $w isa colonel;
      """
    When materialised database is completed
    Given for graql query
      """
      match
        (employee: $x, employer: $y) isa employment;
      get;
      """
    Given all answers are correct in reasoned database
    Given answer size in reasoned database is: 3
    Then for graql query
      """
      match
        (employee: $x, employer: $y) isa employment;
        $x isa $type;
      get;
      """
#    Then all answers are correct in reasoned database
    # 3 colonels * 5 supertypes of colonel (colonel, military-person, person, entity, thing)
    Then answer size in reasoned database is: 15
    Then for graql query
      """
      match
        ($x, $y) isa employment;
        $x isa $type;
      get;
      """
#    Then all answers are correct in reasoned database
    # (3 colonels * 5 supertypes of colonel * 1 company)
    # + (1 company * 3 supertypes of company * 3 colonels)
    Then answer size in reasoned database is: 24
    Then materialised and reasoned databases are the same size


  # TODO: re-enable all steps once schema queries are resolvable (#75)
  Scenario: entity pairs can be matched based on the entity type they are related to
    Given for each session, graql define
      """
      define

      retail-company sub company;
      finance-company sub company;

      captain-obvious-1 sub rule,
      when {
         $x isa retail-company;
      },
      then {
         $x isa company;
      };

      captain-obvious-2 sub rule,
      when {
         $x isa finance-company;
      },
      then {
         $x isa company;
      };
      """
    Given for each session, graql insert
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
    When materialised database is completed
    Then for graql query
      """
      match
        $x isa person;
        $y isa person;
        (employee: $x, employer: $xx) isa employment;
        $xx isa $type;
        (employee: $y, employer: $yy) isa employment;
        $yy isa $type;
        $y != $x;
      get $x, $y;
      """
#    Then all answers are correct in reasoned database
    # All companies match when $type is company (or entity)
    # Query returns {ab,ac,ad,bc,bd,cd} and each of them with the variables flipped
    Then answer size in reasoned database is: 12
    Then for graql query
      """
      match
        $x isa person;
        $y isa person;
        (employee: $x, employer: $xx) isa employment;
        $xx isa $type;
        (employee: $y, employer: $yy) isa employment;
        $yy isa $type;
        $y != $x;
        $meta type entity; $type != $meta;
        $meta2 type thing; $type != $meta2;
        $meta3 type company; $type != $meta3;
      get $x, $y;
      """
    # $type is forced to be either finance-company or retail-company, restricting the answer space
    # Query returns {ab,cd} and each of them with the variables flipped
    # Note: the two Captain Obvious rules should not affect the answer, as the concepts retain their original types
    Then answer size in reasoned database is: 4
    Then materialised and reasoned databases are the same size


  # TODO: re-enable all steps when type generation is supported in resolution test framework (#75)
  Scenario: when two additional types are inferred in parallel, one can be excluded from the results
    Given for each session, graql define
      """
      define

      duelist sub person;
      poet sub person;

      romeo-is-a-duelist sub rule,
      when {
        $x isa person, has name "Romeo";
      }, then {
        $x isa duelist;
      };

      romeo-is-a-poet sub rule,
      when {
        $x isa person, has name "Romeo";
      }, then {
        $x isa poet;
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa person, has name "Romeo";
      """
#    When materialised database is completed
    Given for graql query
      """
      match
        $x isa $type;
        $type sub entity;
      get $x, $type;
      """
#    Given all answers are correct in reasoned database
    # entity, person, duelist, poet
    Given answer size in reasoned database is: 4
    Then for graql query
      """
      match
        $x isa $type;
        $type sub entity;
        $type2 type duelist;
        $type2 != $type;
      get $x, $type;
      """
#    Then all answers are correct in reasoned database
    # entity, person, poet
    Then answer size in reasoned database is: 3
#    Then materialised and reasoned databases are the same size


  # TODO: re-enable all steps when type generation is supported in resolution test framework (#75)
  Scenario: when two additional types are inferred in series, one can be excluded from the results
    Given for each session, graql define
      """
      define

      duelist sub person;
      poet sub person;

      romeo-is-a-duelist sub rule,
      when {
        $x isa person, has name "Romeo";
      }, then {
        $x isa duelist;
      };

      a-duelist-is-a-poet sub rule,
      when {
        $x isa duelist;
      }, then {
        $x isa poet;
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa person, has name "Romeo";
      """
#    When materialised database is completed
    Given for graql query
      """
      match
        $x isa $type;
        $type sub entity;
      get $x, $type;
      """
#    Given all answers are correct in reasoned database
    # entity, person, duelist, poet
    Given answer size in reasoned database is: 4
    Then for graql query
      """
      match
        $x isa $type;
        $type sub entity;
        $type2 type duelist;
        $type2 != $type;
      get $x, $type;
      """
#    Then all answers are correct in reasoned database
    # entity, person, poet
    Then answer size in reasoned database is: 3
#    Then materialised and reasoned databases are the same size
