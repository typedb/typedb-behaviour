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
Feature: Type Hierarchy Resolution

  Background: Set up database
    Given connection has been opened
    Given connection does not have any database
    Given connection create database: typedb
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write


  Scenario: subtypes trigger rules based on their parents; parent types don't trigger rules based on their children
    Given typeql define
      """
      define

      person sub entity,
          owns name,
          plays performance:writer,
          plays performance:performer,
          plays film-production:writer,
          plays film-production:actor;

      child sub person;

      performance sub relation,
          relates writer,
          relates performer;

      film-production sub relation,
          relates writer,
          relates actor;

      name sub attribute, value string;

      rule performance-to-film-production: when {
          $x isa child;
          $y isa person;
          (performer:$x, writer:$y) isa performance;
      } then {
          (actor:$x, writer:$y) isa film-production;
      };
      """
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa child, has name "a";
      $y isa person, has name "b";
      $z isa person, has name "a";
      $w isa person, has name "b2";
      $v isa child, has name "a";

      (performer:$x, writer:$z) isa performance;  # child - person   -> satisfies rule
      (performer:$y, writer:$z) isa performance;  # person - person  -> doesn't satisfy rule
      (performer:$x, writer:$v) isa performance;  # child - child    -> satisfies rule
      (performer:$y, writer:$v) isa performance;  # person - child   -> doesn't satisfy rule
      """
    Given transaction commits
    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match
        $x isa person;
        $y isa person;
        (actor: $x, writer: $y) isa film-production;
      """
    # Answers are (actor:$x, writer:$z) and (actor:$x, writer:$v)
    Then answer size is: 2
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete
    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match
        $x isa person;
        $y isa person;
        (actor: $x, writer: $y) isa film-production;
        $y has name 'a';
      """
    Then answer size is: 2
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete
    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match
        $x isa person;
        $y isa child;
        (actor: $x, writer: $y) isa film-production;
      """
    # Answer is (actor:$x, writer:$v) ONLY
    Then answer size is: 1
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete
    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match
        $x isa person;
        $y isa child;
        (actor: $x, writer: $y) isa film-production;
        $y has name 'a';
      """
    Then answer size is: 1
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete
    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match
        $x isa child;
        $y isa person;
        (actor: $x, writer: $y) isa film-production;
      """
    # Answers are (actor:$x, writer:$z) and (actor:$x, writer:$v)
    Then answer size is: 2
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete
    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match
        $x isa child;
        $y isa person;
        (actor: $x, writer: $y) isa film-production;
        $y has name 'a';
      """
    Then answer size is: 2
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete


  Scenario: when matching different roles to those that are actually inferred, no answers are returned
    Given typeql define
      """
      define

      person sub entity,
          plays family:child,
          plays family:parent,
          plays large-family:mother,
          plays large-family:father;

      family sub relation,
          relates child,
          relates parent;

      large-family sub family,
          relates mother as parent,
          relates father as parent;

      rule parents-are-mothers: when {
          (child: $x, parent: $y) isa family;
      } then {
          (child: $x, mother: $y) isa large-family;
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
      (child: $x, parent: $y) isa family;
      """
    Given transaction commits
    Given correctness checker is initialised
    # Matching a sibling of the actual role
    When get answers of typeql match
      """
      match (child: $x, father: $y) isa large-family;
      """
    Then answer size is: 0
    Given session opens transaction of type: read
    # Matching two siblings when only one is present
    When get answers of typeql match
      """
      match (mother: $x, father: $y) isa large-family;
      """
    Then answer size is: 0
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete


  Scenario: when a sub-relation is inferred, it can be retrieved by matching its super-relation and sub-roles
    Given typeql define
      """
      define

      person sub entity,
          plays performance:writer,
          plays performance:performer,
          plays film-production:writer,
          plays film-production:actor,
          plays scifi-production:scifi-writer,
          plays scifi-production:scifi-actor;

      performance sub relation,
          relates writer,
          relates performer;

      film-production sub relation,
          relates writer,
          relates actor;

      scifi-production sub film-production,
          relates scifi-writer as writer,
          relates scifi-actor as actor;

      rule performance-to-scifi: when {
          (writer:$x, performer:$y) isa performance;
      } then {
          (scifi-writer:$x, scifi-actor:$y) isa scifi-production;
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
      (writer:$x, performer:$y) isa performance;
      """
    Given transaction commits
    Given correctness checker is initialised
    # sub-roles, super-relation
    When get answers of typeql match
      """
      match (scifi-writer:$x, scifi-actor:$y) isa film-production;
      """
    Then answer size is: 1
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete


  Scenario: when a sub-relation is inferred, it can be retrieved by matching its sub-relation and super-roles
    Given typeql define
      """
      define

      person sub entity,
          plays performance:writer,
          plays performance:performer,
          plays film-production:writer,
          plays film-production:actor,
          plays scifi-production:scifi-writer,
          plays scifi-production:scifi-actor;

      performance sub relation,
          relates writer,
          relates performer;

      film-production sub relation,
          relates writer,
          relates actor;

      scifi-production sub film-production,
          relates scifi-writer as writer,
          relates scifi-actor as actor;

      rule performance-to-scifi: when {
          (writer:$x, performer:$y) isa performance;
      } then {
          (scifi-writer:$x, scifi-actor:$y) isa scifi-production;
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
      (writer:$x, performer:$y) isa performance;
      """
    Given transaction commits
    Given correctness checker is initialised
    # super-roles, sub-relation
    When get answers of typeql match
      """
      match (writer:$x, actor:$y) isa scifi-production;
      """
    Then answer size is: 1
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete


  Scenario: when a sub-relation is inferred, it can be retrieved by matching its super-relation and super-roles
    Given typeql define
      """
      define

      person sub entity,
          plays performance:writer,
          plays performance:performer,
          plays film-production:writer,
          plays film-production:actor,
          plays scifi-production:scifi-writer,
          plays scifi-production:scifi-actor;

      performance sub relation,
          relates writer,
          relates performer;

      film-production sub relation,
          relates writer,
          relates actor;

      scifi-production sub film-production,
          relates scifi-writer as writer,
          relates scifi-actor as actor;

      rule performance-to-scifi: when {
          (writer:$x, performer:$y) isa performance;
      } then {
          (scifi-writer:$x, scifi-actor:$y) isa scifi-production;
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
      (writer:$x, performer:$y) isa performance;
      """
    Given transaction commits
    Given correctness checker is initialised
    # super-roles, super-relation
    When get answers of typeql match
      """
      match (writer:$x, actor:$y) isa film-production;
      """
    Then answer size is: 1
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete


  Scenario: when a rule is recursive, its inferences respect type hierarchies
    Given typeql define
      """
      define

      person sub entity,
          owns name,
          plays performance:writer,
          plays performance:performer,
          plays film-production:writer,
          plays film-production:actor;

      child sub person;

      performance sub relation,
          relates writer,
          relates performer;

      film-production sub relation,
          relates writer,
          relates actor;

      name sub attribute, value string;

      rule performance-to-film-production: when {
          $x isa child;
          $y isa person;
          (performer:$x, writer:$y) isa performance;
      } then {
          (actor:$x, writer:$y) isa film-production;
      };

      rule performance-to-performance: when {
          $x isa person;
          $y isa child;
          (performer:$x, writer:$y) isa performance;
      } then {
          (performer:$x, writer:$y) isa performance;
      };
      """
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa child, has name "a";
      $y isa person, has name "b";
      $z isa person, has name "a";
      $w isa person, has name "b2";
      $v isa child, has name "a";

      (performer:$x, writer:$z) isa performance;  # child - person   -> satisfies rule
      (performer:$y, writer:$z) isa performance;  # person - person  -> doesn't satisfy rule
      (performer:$x, writer:$v) isa performance;  # child - child    -> satisfies rule
      (performer:$y, writer:$v) isa performance;  # person - child   -> doesn't satisfy rule
      """
    Given transaction commits
    Given correctness checker is initialised
    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match
        $x isa person;
        $y isa person;
        (actor: $x, writer: $y) isa film-production;
      """
    # Answers are (actor:$x, writer:$z) and (actor:$x, writer:$v)
    Then answer size is: 2
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete
    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match
        $x isa person;
        $y isa person;
        (actor: $x, writer: $y) isa film-production;
        $y has name 'a';
      """
    Then answer size is: 2
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete
    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match
        $x isa person;
        $y isa child;
        (actor: $x, writer: $y) isa film-production;
      """
    # Answer is (actor:$x, writer:$v) ONLY
    Then answer size is: 1
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete
    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match
        $x isa person;
        $y isa child;
        (actor: $x, writer: $y) isa film-production;
        $y has name 'a';
      """
    Then answer size is: 1
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete
    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match
        $x isa child;
        $y isa person;
        (actor: $x, writer: $y) isa film-production;
      """
    # Answers are (actor:$x, writer:$z) and (actor:$x, writer:$v)
    Then answer size is: 2
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete
    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match
        $x isa child;
        $y isa person;
        (actor: $x, writer: $y) isa film-production;
        $y has name 'a';
      """
    Then answer size is: 2
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete


  Scenario: querying for a super-relation gives the same answer as querying for its inferred sub-relation
    Given typeql define
      """
      define

      person sub entity,
          plays residence:home-owner,
          plays residence:resident,
          plays family-residence:parent-home-owner,
          plays family-residence:child-resident,
          plays family:parent,
          plays family:child;

      residence sub relation,
          relates home-owner,
          relates resident;

      family-residence sub residence,
          relates parent-home-owner as home-owner,
          relates child-resident as resident;

      family sub relation,
          relates parent,
          relates child;

      rule families-live-together: when {
          (parent:$x, child:$y) isa family;
      } then {
          (parent-home-owner:$x, child-resident:$y) isa family-residence;
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
      (parent:$x, child:$y) isa family;
      """
    Given transaction commits
    Given correctness checker is initialised
    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match (home-owner: $x, resident: $y) isa residence;
      """
    Then answer size is: 1
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete
    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match
        (home-owner: $x, resident: $y) isa residence;
        (parent-home-owner: $x, child-resident: $y) isa family-residence;
      """
    Then answer size is: 1
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete
