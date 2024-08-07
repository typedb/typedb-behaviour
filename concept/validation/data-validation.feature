# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Data validation

  Background:
    Given typedb starts
    Given connection opens with default authentication
    Given connection has been opened
    Given connection does not have any database
    Given connection create database: typedb
    Given connection open schema transaction for database: typedb


  Scenario: Instances of a type not in the schema must not exist
    Given create entity type: ent0
    Given transaction commits
    Given connection open write transaction for database: typedb
    Given $a = entity(ent0) create new instance
    Given transaction commits

    When connection open schema transaction for database: typedb
    Then delete entity type: ent0; fails


  Scenario: Instances of abstract types must not exist
    Given create entity type: ent0a
    Given entity(ent0a) set annotation: @abstract
    Given create entity type: ent0c
    Given transaction commits

    Given connection open write transaction for database: typedb
    Then entity(ent0a) create new instance; fails

    When transaction closes
    Given connection open write transaction for database: typedb
    Then $a = entity(ent0c) create new instance
    Then transaction commits

    Given connection open write transaction for database: typedb
    Then entity(ent0c) set annotation: @abstract; fails


  Scenario: Instances of ownerships not in the schema must not exist
    Given create entity type: ent00
    Given create attribute type: attr00
    Given attribute(attr00) set value type: string
    Given entity(ent00) set owns: attr00
    Given create entity type: ent1
    Given entity(ent1) set supertype: ent00
    Given create entity type: ent01
    Given transaction commits
    Given connection open write transaction for database: typedb
    Given $ent1 = entity(ent1) create new instance
    Given $attr00 = attribute(attr00) put instance with value: "attr00"
    Given entity $ent1 set has: $attr00
    Given transaction commits
    Given connection open write transaction for database: typedb

    When $ent01 = entity(ent01) create new instance
    Then entity $ent01 set has: $attr00; fails

    Given transaction closes
    Given connection open schema transaction for database: typedb

    Then entity(ent00) unset owns: attr00; fails

    Then entity(ent1) set supertype: ent01; fails


  Scenario: Instances of roles not in the schema must not exist
    Given create relation type: rel00
    Given relation(rel00) create role: role00
    Given create relation type: rel01
    Given relation(rel01) create role: role01
    Given create relation type: rel1
    Given relation(rel1) set supertype: rel00
    Given create entity type: ent0
    Given entity(ent0) set plays: rel00:role00
    Given transaction commits
    Given connection open write transaction for database: typedb
    Given $ent0 = entity(ent0) create new instance
    Given $rel1 = relation(rel1) create new instance
    Given relation $rel1 add player for role(role00): $ent0
    Given transaction commits
    Given connection open schema transaction for database: typedb

    Then relation(rel00) delete role: role00; fails

    When transaction closes
    Given connection open schema transaction for database: typedb
    Then relation(rel1) set supertype: rel01; fails

    When transaction closes
    Given connection open schema transaction for database: typedb
    Then relation(rel1) create role: role1
    Then relation(rel1) get role(role1) set override: role00; fails


  # If we ever introduce abstract roles, we need a scenario here

  Scenario: Instances of role-playing not in the schema must not exist
    Given create relation type: rel0
    Given relation(rel0) create role: role0
    Given create relation type: rel1
    Given relation(rel1) set supertype: rel0
    Given relation(rel1) create role: role1
    Given relation(rel1) get role(role1) set override: role0
    Given create entity type: ent00
    Given entity(ent00) set plays: rel0:role0
    Given create entity type: ent1
    Given entity(ent1) set supertype: ent00
    Given create entity type: ent01
    Given transaction commits
    Given connection open write transaction for database: typedb
    Given $ent1 = entity(ent1) create new instance
    Given $rel0 = relation(rel0) create new instance
    Given relation $rel0 add player for role(role0): $ent1
    Given transaction commits

    Given connection open write transaction for database: typedb
    When $e1 = entity(ent1) create new instance
    When $r1 = relation(rel1) create new instance
    Then relation $r1 add player for role(role1): $e1; fails

    When transaction closes
    Given connection open schema transaction for database: typedb
    Then entity(ent00) unset plays: rel0:role0; fails

    When transaction closes
    Given connection open schema transaction for database: typedb
    When entity(ent1) set plays: rel1:role1
    Then entity(ent1) get plays(rel1:role1) set override: rel0:role0; fails

    When transaction closes
    Given connection open schema transaction for database: typedb
    Then entity(ent1) set supertype: ent01; fails


  # If we ever introduce abstract roles, we need a scenario here

  Scenario: Instances of role-playing hidden by a relates override must not exist
    Given create relation type: rel0
    Given relation(rel0) create role: role0
    Given create relation type: rel1
    Given relation(rel1) set supertype: rel0
    Given relation(rel1) create role: role1
    Given relation(rel1) get role(role1) set override: role0
    Given create entity type: ent00
    Given entity(ent00) set plays: rel0:role0
    Given entity(ent00) set plays: rel1:role1
    Given transaction commits

    Given connection open write transaction for database: typedb
    When $ent00 = entity(ent00) create new instance
    When $rel1 = relation(rel1) create new instance
    # a NullPointerException in the steps because role0 is not related by rel1.
    When relation $rel1 add player for role(role0): $ent00; fails

    When transaction closes
    Given connection open write transaction for database: typedb
    When $ent00 = entity(ent00) create new instance
    When $rel1 = relation(rel1) create new instance
    When relation $rel1 add player for role(role1): $ent00
    Then transaction commits

    # With no 'plays' override, we can still play the parent role in the parent relation
    Given connection open write transaction for database: typedb
    When $ent00 = entity(ent00) create new instance
    When $rel0 = relation(rel0) create new instance
    When relation $rel0 add player for role(role0): $ent00
    Then transaction commits


  Scenario: Instances of role-playing hidden by a plays override must not exist
    Given create relation type: rel0
    Given relation(rel0) create role: role0
    Given create relation type: rel1
    Given relation(rel1) set supertype: rel0
    Given relation(rel1) create role: role1
    Given relation(rel1) get role(role1) set override: role0
    Given create entity type: ent00
    Given entity(ent00) set plays: rel0:role0
    Given create entity type: ent1
    Given entity(ent1) set supertype: ent00
    Given entity(ent1) set plays: rel1:role1
    Given entity(ent1) get plays(rel1:role1) set override: rel0:role0
    Given transaction commits

    Given connection open write transaction for database: typedb
    When $ent1 = entity(ent1) create new instance
    When $rel0 = relation(rel0) create new instance
    When relation $rel0 add player for role(role0): $ent1; fails

    When transaction closes
    Given connection open write transaction for database: typedb
    When $ent1 = entity(ent1) create new instance
    When $rel1 = relation(rel1) create new instance
    When relation $rel1 add player for role(role1): $ent1
    Then transaction commits


  Scenario: A type may not override a role it plays through inheritance if instances of that type playing that role exist
    Given create relation type: rel0
    Given relation(rel0) create role: role0
    Given create relation type: rel1
    Given relation(rel1) set supertype: rel0
    Given relation(rel1) create role: role1
    Given relation(rel1) get role(role1) set override: role0
    Given create entity type: ent00
    Given entity(ent00) set plays: rel0:role0
    Given create entity type: ent1
    Given entity(ent1) set supertype: ent00
    # Without the override
    Given entity(ent1) set plays: rel1:role1
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given $ent1 = entity(ent1) create new instance
    Given $rel0 = relation(rel0) create new instance
    Given relation $rel0 add player for role(role0): $ent1
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Given entity(ent1) set plays: rel1:role1
    Then entity(ent1) get plays(rel1:role1) set override: rel0:role0; fails


  Scenario: A type may not be moved if it has instances of it owning an attribute which would be lost as a result of that move
    Given create attribute type: attr0
    Given attribute(attr0) set value type: string
    Given create entity type: ent1
    Given entity(ent1) set owns: attr0
    Given create entity type: ent2
    Given entity(ent2) set supertype: ent1
    Given create entity type: ent10
    Given transaction commits
    Given connection open write transaction for database: typedb
    Given $ent2 = entity(ent2) create new instance
    Given $attr0 = attribute(attr0) put instance with value: "attr0"
    Given entity $ent2 set has: $attr0
    Given transaction commits

    When connection open schema transaction for database: typedb
    Then entity(ent2) set supertype: ent10; fails


  Scenario: A type may not be moved if it has instances of it playing a role which would be hidden as a result of that move
    Given create relation type: rel0
    Given relation(rel0) create role: role0
    Given create relation type: rel1
    Given relation(rel1) set supertype: rel0
    Given relation(rel1) create role: role1
    Given relation(rel1) get role(role1) set override: role0
    Given create entity type: ent0
    Given entity(ent0) set plays: rel0:role0
    Given create entity type: ent10
    Given entity(ent10) set supertype: ent0
    Given create entity type: ent2
    Given entity(ent2) set supertype: ent10
    Given create entity type: ent11
    Given entity(ent11) set supertype: ent0
    Given entity(ent11) set plays: rel1:role1
    Given entity(ent11) get plays(rel1:role1) set override: rel0:role0
    Given transaction commits
    Given connection open write transaction for database: typedb
    Given $ent2 = entity(ent2) create new instance
    Given $rel0 = relation(rel0) create new instance
    Given relation $rel0 add player for role(role0): $ent2
    Given transaction commits

    When connection open schema transaction for database: typedb
    Then entity(ent2) set supertype: ent11; fails


  Scenario: When annotations on an ownership change, data is revalidated
    Given create attribute type: attr0
    Given attribute(attr0) set value type: string
    Given create entity type: ent0n
    Given create entity type: ent0u
    Given entity(ent0n) set owns: attr0
    Given entity(ent0u) set owns: attr0
    Given entity(ent0u) get owns(attr0) set annotation: @unique
    Given entity(ent0u) get owns(attr0) set annotation: @card(0..2)
    Given create attribute type: ref
    Given attribute(ref) set value type: string
    Given entity(ent0n) set owns: ref
    Given entity(ent0n) get owns(ref) set annotation: @key
    Given entity(ent0u) set owns: ref
    Given entity(ent0u) get owns(ref) set annotation: @key
    Given transaction commits
    Given connection open write transaction for database: typedb
    Given $ent0n0 = entity(ent0n) create new instance with key(ref): ent0n0
    Given $ent0n1 = entity(ent0n) create new instance with key(ref): ent0n1
    Given $ent0u = entity(ent0u) create new instance with key(ref): ent0u
    Given $attr0 = attribute(attr0) put instance with value: "attr0"
    Given $attr1 = attribute(attr0) put instance with value: "attr1"
    Given entity $ent0n0 set has: $attr1
    Given entity $ent0n1 set has: $attr1
    Given entity $ent0u set has: $attr0
    Given entity $ent0u set has: $attr1
    Given transaction commits
    Given connection open schema transaction for database: typedb
    Then entity(ent0n) get owns(attr0) set annotation: @unique; fails

    When transaction closes
    Given connection open schema transaction for database: typedb
    When entity(ent0u) get owns(attr0) unset annotation: @card
    Then entity(ent0u) get owns(attr0) set annotation: @key; fails

    Given transaction closes
    Given connection open write transaction for database: typedb
    When $ent0n1 = entity(ent0n) get instance with key(ref): ent0n1
    When $ent0u = entity(ent0u) get instance with key(ref): ent0u
    When $attr1 = attribute(attr0) get instance with value: "attr1"
    When entity $ent0n1 unset has: $attr1
    When entity $ent0u unset has: $attr1
    Then transaction commits

    Given connection open schema transaction for database: typedb
    When entity(ent0n) get owns(attr0) set annotation: @unique
    When entity(ent0u) get owns(attr0) unset annotation: @card
    When entity(ent0u) get owns(attr0) unset annotation: @unique
    When entity(ent0u) get owns(attr0) set annotation: @key
    Then transaction commits

    # TODO: Add a test for unique where we have a supertype without unique, subtype with unique, and multiple subsubtypes for it. Supertype can be duplicated
    # with the subtypes or subsubtypes!

  # TODO: Add test when data is invalid while we change any of the new annotations (regex, values, range, independent, ...)

  # TODO: Add test how data is cleaned up when we set cascade / remove independent (maybe it's for migration.feature)

  Scenario: When the super-type of a type is changed, the data is consistent with the annotations on ownerships
    Given create attribute type: attr0
    Given attribute(attr0) set value type: string
    Given create entity type: ent0k
    Given create entity type: ent0n
    Given create entity type: ent1n
    Given entity(ent1n) set supertype: ent0n
    Given entity(ent0n) set owns: attr0
    Given entity(ent0n) get owns(attr0) set annotation: @card(0..2)
    Given entity(ent0k) set owns: attr0
    Given entity(ent0k) get owns(attr0) set annotation: @key
    Given create attribute type: ref
    Given attribute(ref) set value type: string
    Given entity(ent0n) set owns: ref
    Given entity(ent0n) get owns(ref) set annotation: @key
    Given entity(ent0k) set owns: ref
    Given entity(ent0k) get owns(ref) set annotation: @key
    Given transaction commits
    Given connection open write transaction for database: typedb
    Given $attr0 = attribute(attr0) put instance with value: "attr0"
    Given $attr1 = attribute(attr0) put instance with value: "attr1"
    Given $ent1n = entity(ent1n) create new instance with key(ref): ent1n
    Given entity $ent1n set has: $attr0
    Given entity $ent1n set has: $attr1
    Given $ent0k = entity(ent0k) create new instance with key(ref): ent0k
    Given entity $ent0k set has: $attr0
    Given transaction commits
    Given connection open schema transaction for database: typedb
    Then entity(ent1n) set supertype: ent0k; fails

    # TODO: Repeat these "cannot be deleted" tests for subtypes instances with reverse "can be deleted". See abstract annotation!

  Scenario: Entity types that have instances cannot be deleted
    When create entity type: person
    When transaction commits
    When connection open write transaction for database: typedb
    When $x = entity(person) create new instance
    When transaction commits
    When connection open schema transaction for database: typedb
    Then delete entity type: person; fails
    When transaction closes
    When connection open write transaction for database: typedb
    When delete entities of type: person    When transaction commits
    When connection open schema transaction for database: typedb
    When delete entity type: person
    Then entity(person) does not exist
    Then transaction commits

  Scenario: Relation types that have instances cannot be deleted
    When create relation type: marriage
    When relation(marriage) create role: wife
    When transaction commits
    When connection open write transaction for database: typedb
    When $m = relation(marriage) create new instance
    When transaction commits
    When connection open schema transaction for database: typedb
    Then delete relation type: marriage; fails
    When transaction closes
    When connection open write transaction for database: typedb
    When delete relations of type: marriage
    When transaction commits
    When connection open schema transaction for database: typedb
    When delete relation type: marriage
    Then relation(marriage) does not exist
    Then transaction commits

  Scenario: Attribute types that have instances cannot be deleted
    When create attribute type: name
    When attribute(name) set value type: string
    When attribute(name) set annotation: @independent
    When transaction commits
    When connection open write transaction for database: typedb
    When $x = attribute(name) put instance with value: alice
    When transaction commits
    When connection open schema transaction for database: typedb
    Then delete attribute type: name; fails
    When transaction closes
    When connection open write transaction for database: typedb
    When delete attributes of type: name
    When transaction commits
    When connection open schema transaction for database: typedb
    When delete attribute type: name
    Then attribute(name) does not exist
    Then transaction commits

  Scenario: Role types that have instances cannot be deleted or unset
    When create attribute type: id
    When attribute(id) set value type: string
    When create relation type: marriage
    When relation(marriage) create role: wife
    When relation(marriage) create role: husband
    When relation(marriage) set owns: id
    When create entity type: person
    When entity(person) set plays: marriage:wife
    When entity(person) set owns: id
    When transaction commits
    When connection open write transaction for database: typedb
    When $m = relation(marriage) create new instance with key(id): "m"
    When $p = entity(person) create new instance with key(id): "p"
    When relation $m add player for role(wife): $p
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(marriage) delete role: wife; fails
    Then entity(person) unset plays: marriage:wife; fails
    Then relation(marriage) delete role: husband
    Then transaction commits
    When connection open write transaction for database: typedb
    When $m = relation(marriage) get instance with key(id): "m"
    When $p = entity(person) get instance with key(id): "p"
    When relation $m remove player for role(wife): $p
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(marriage) delete role: wife; fails
    When entity(person) unset plays: marriage:wife
    Then relation(marriage) delete role: wife
    Then relation(marriage) get role(wife) does not exist
    Then transaction commits

  Scenario: Owns that have instances cannot be unset
    When create entity type: person
    When create attribute type: name
    When attribute(name) set value type: string
    When entity(person) set owns: name
    When transaction commits
    When connection open write transaction for database: typedb
    When $p = entity(person) create new instance
    When $n = attribute(name) put instance with value: "bob"
    When entity $p set has: $n
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) unset owns: name; fails
    When transaction closes
    When connection open write transaction for database: typedb
    When $p = entity(person) get instance with key: "bob"
    When $n = attribute(name) get instance with value: "bob"
    When entity $p unset has: $n
    When transaction commits
    When connection open schema transaction for database: typedb
    When entity(person) unset owns: name
    Then entity(person) get owns do not contain:
      | name |
    When transaction commits

  Scenario: Plays that have instances cannot be unset
    When create attribute type: id
    When attribute(id) set value type: string
    When create relation type: marriage
    When relation(marriage) create role: wife
    When relation(marriage) set owns: id
    When create entity type: person
    When entity(person) set plays: marriage:wife
    When entity(person) set owns: id
    When transaction commits
    When connection open write transaction for database: typedb
    When $m = relation(marriage) create new instance with key(id): "m"
    When $p = entity(person) create new instance with key(id): "p"
    When relation $m add player for role(wife): $p
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) unset plays: marriage:wife; fails
    Then transaction commits
    When connection open write transaction for database: typedb
    When $m = relation(marriage) get instance with key(id): "m"
    When $p = entity(person) get instance with key(id): "p"
    When relation $m remove player for role(wife): $p
    When transaction commits
    When connection open schema transaction for database: typedb
    When entity(person) unset plays: marriage:wife
    Then entity(person) get plays do not contain:
      | marriage:wife |
    Then transaction commits

  Scenario: Entity types can be set to abstract when a subtype has instances
    When create entity type: person
    When create entity type: player
    When entity(player) set supertype: person
    Then transaction commits
    When connection open write transaction for database: typedb
    When entity(player) create new instance
    Then transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) set annotation: @abstract
    Then transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get annotations contain: @abstract
    Then entity(person) get declared annotations contain: @abstract
    Then entity(player) get annotations do not contain: @abstract
    Then entity(player) get declared annotations do not contain: @abstract
    Then entity(player) get instances is not empty

  Scenario: Relation types can be set to abstract when a subtype has instances
    When create relation type: parentship
    When relation(parentship) create role: parent
    When create relation type: fathership
    When relation(fathership) create role: father
    When relation(fathership) set supertype: parent
    Then transaction commits
    When connection open write transaction for database: typedb
    When relation(fathership) create new instance
    Then transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) set annotation: @abstract
    Then transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get annotations contain: @abstract
    Then relation(parentship) get declared annotations contain: @abstract
    Then relation(fathership) get annotations do not contain: @abstract
    Then relation(fathership) get declared annotations do not contain: @abstract
    Then relation(fathership) get instances is not empty

  Scenario: Entity types can be unset as supertype and deleted when a subtype has instances
    When create entity type: person
    When create entity type: player
    When entity(player) set supertype: person
    Then transaction commits
    When connection open write transaction for database: typedb
    When entity(player) create new instance
    Then transaction commits
    When connection open schema transaction for database: typedb
    When entity(player) unset supertype
    Then delete entity type: person
    Then transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) does not exist
    Then entity(player) get instances is not empty

  Scenario: Relation types can be unset as supertype and deleted when a subtype has instances
    When create relation type: parentship
    When relation(parentship) create role: parent
    When create relation type: fathership
    When relation(fathership) create role: father
    When relation(fathership) set supertype: parent
    Then transaction commits
    When connection open write transaction for database: typedb
    When relation(fathership) create new instance
    Then transaction commits
    When connection open schema transaction for database: typedb
    When relation(fathership) unset supertype
    Then delete relation type: parentship
    Then transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) does not exist
    Then relation(fathership) get instances is not empty

  Scenario: Attribute types can be unset as supertype and deleted when a subtype has instances
    When create attribute type: literal
    When attribute(literal) set annotation: @abstract
    When attribute(literal) set value type: string
    When create attribute type: name
    When attribute(name) set supertype: literal
    When attribute(name) set annotation: @independent
    Then transaction commits
    When connection open write transaction for database: typedb
    When attribute(name) put instance with value: "bob"
    Then transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) unset supertype; fails
    When attribute(name) set value type: string
    Then attribute(name) unset supertype
    Then delete attribute type: literal
    Then transaction commits
    When connection open read transaction for database: typedb
    Then attribute(literal) does not exist
    Then $a = attribute(name) get instance with value: "bob"
    Then attribute $a exists
