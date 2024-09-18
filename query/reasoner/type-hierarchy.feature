# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Type Hierarchy Resolution

  Background: Set up database
    Given typedb starts
    Given connection opens with default authentication

  Scenario: subtypes trigger rules based on their parents; parent types don't trigger rules based on their children
    Given reasoning schema
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
    Given reasoning data
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
    Given verifier is initialised
    Given reasoning query
      """
      match
        $x isa person;
        $y isa person;
        (actor: $x, writer: $y) isa film-production;

      """
    # Answers are (actor:$x, writer:$z) and (actor:$x, writer:$v)
    Then verify answer size is: 2
    Then verify answers are sound
    Then verify answers are complete
    Given reasoning query
      """
      match
        $x isa person;
        $y isa person;
        (actor: $x, writer: $y) isa film-production;
        $y has name 'a';

      """
    Then verify answer size is: 2
    Then verify answers are sound
    Then verify answers are complete
    Given reasoning query
      """
      match
        $x isa person;
        $y isa child;
        (actor: $x, writer: $y) isa film-production;

      """
    # Answer is (actor:$x, writer:$v) ONLY
    Then verify answer size is: 1
    Then verify answers are sound
    Then verify answers are complete
    Given reasoning query
      """
      match
        $x isa person;
        $y isa child;
        (actor: $x, writer: $y) isa film-production;
        $y has name 'a';

      """
    Then verify answer size is: 1
    Then verify answers are sound
    Then verify answers are complete
    Given reasoning query
      """
      match
        $x isa child;
        $y isa person;
        (actor: $x, writer: $y) isa film-production;

      """
    # Answers are (actor:$x, writer:$z) and (actor:$x, writer:$v)
    Then verify answer size is: 2
    Then verify answers are sound
    Then verify answers are complete
    Given reasoning query
      """
      match
        $x isa child;
        $y isa person;
        (actor: $x, writer: $y) isa film-production;
        $y has name 'a';

      """
    Then verify answer size is: 2
    Then verify answers are sound
    Then verify answers are complete


  Scenario: when matching different roles to those that are actually inferred, no answers are returned
    Given reasoning schema
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
    Given reasoning data
      """
      insert
      $x isa person;
      $y isa person;
      (child: $x, parent: $y) isa family;
      """
    # Matching a sibling of the actual role
    Given verifier is initialised
    Given reasoning query
      """
      match (child: $x, father: $y) isa large-family;
      """
    Then verify answer size is: 0
    # Matching two siblings when only one is present
    Given reasoning query
      """
      match (mother: $x, father: $y) isa large-family;
      """
    Then verify answer size is: 0
    Then verify answers are sound
    Then verify answers are complete


  Scenario: when a sub-relation is inferred, it can be retrieved by matching its super-relation and sub-roles
    Given reasoning schema
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
    Given reasoning data
      """
      insert
      $x isa person;
      $y isa person;
      (writer:$x, performer:$y) isa performance;
      """
    # sub-roles, super-relation
    Given verifier is initialised
    Given reasoning query
      """
      match (scifi-writer:$x, scifi-actor:$y) isa film-production;
      """
    Then verify answer size is: 1
    Then verify answers are sound
    Then verify answers are complete


  Scenario: when a sub-relation is inferred, it can be retrieved by matching its sub-relation and super-roles
    Given reasoning schema
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
    Given reasoning data
      """
      insert
      $x isa person;
      $y isa person;
      (writer:$x, performer:$y) isa performance;
      """
    # super-roles, sub-relation
    Given verifier is initialised
    Given reasoning query
      """
      match (writer:$x, actor:$y) isa scifi-production;
      """
    Then verify answer size is: 1
    Then verify answers are sound
    Then verify answers are complete


  Scenario: when a sub-relation is inferred, it can be retrieved by matching its super-relation and super-roles
    Given reasoning schema
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
    Given reasoning data
      """
      insert
      $x isa person;
      $y isa person;
      (writer:$x, performer:$y) isa performance;
      """
    # super-roles, super-relation
    Given verifier is initialised
    Given reasoning query
      """
      match (writer:$x, actor:$y) isa film-production;
      """
    Then verify answer size is: 1
    Then verify answers are sound
    Then verify answers are complete


  Scenario: when a rule is recursive, its inferences respect type hierarchies
    Given reasoning schema
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
    Given reasoning data
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
    Given verifier is initialised
    Given reasoning query
      """
      match
        $x isa person;
        $y isa person;
        (actor: $x, writer: $y) isa film-production;

      """
    # Answers are (actor:$x, writer:$z) and (actor:$x, writer:$v)
    Then verify answer size is: 2
    Then verify answers are sound
    Then verify answers are complete
    Given reasoning query
      """
      match
        $x isa person;
        $y isa person;
        (actor: $x, writer: $y) isa film-production;
        $y has name 'a';

      """
    Then verify answer size is: 2
    Then verify answers are sound
    Then verify answers are complete
    Given reasoning query
      """
      match
        $x isa person;
        $y isa child;
        (actor: $x, writer: $y) isa film-production;

      """
    # Answer is (actor:$x, writer:$v) ONLY
    Then verify answer size is: 1
    Then verify answers are sound
    Then verify answers are complete
    Given reasoning query
      """
      match
        $x isa person;
        $y isa child;
        (actor: $x, writer: $y) isa film-production;
        $y has name 'a';

      """
    Then verify answer size is: 1
    Then verify answers are sound
    Then verify answers are complete
    Given reasoning query
      """
      match
        $x isa child;
        $y isa person;
        (actor: $x, writer: $y) isa film-production;

      """
    # Answers are (actor:$x, writer:$z) and (actor:$x, writer:$v)
    Then verify answer size is: 2
    Then verify answers are sound
    Then verify answers are complete
    Given reasoning query
      """
      match
        $x isa child;
        $y isa person;
        (actor: $x, writer: $y) isa film-production;
        $y has name 'a';

      """
    Then verify answer size is: 2
    Then verify answers are sound
    Then verify answers are complete


  Scenario: querying for a super-relation gives the same answer as querying for its inferred sub-relation
    Given reasoning schema
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
    Given reasoning data
      """
      insert
      $x isa person;
      $y isa person;
      (parent:$x, child:$y) isa family;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match (home-owner: $x, resident: $y) isa residence;
      """
    Then verify answer size is: 1
    Then verify answers are sound
    Then verify answers are complete
    Given reasoning query
      """
      match
        (home-owner: $x, resident: $y) isa residence;
        (parent-home-owner: $x, child-resident: $y) isa family-residence;

      """
    Then verify answer size is: 1
    Then verify answers are sound
    Then verify answers are complete
