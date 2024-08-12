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

########################
# delete/unset with existing data
########################

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
    When delete entities of type: person
    When transaction commits
    When connection open schema transaction for database: typedb
    When delete entity type: person
    Then entity(person) does not exist
    Then transaction commits


  Scenario: Relation types that have instances cannot be deleted
    When create relation type: marriage
    When relation(marriage) create role: wife
    When create entity type: person
    When entity(person) set plays: marriage:wife
    When transaction commits
    When connection open write transaction for database: typedb
    When $m = relation(marriage) create new instance
    When transaction commits
    When connection open schema transaction for database: typedb
    # Relation instance without players is cleaned up, so there are no instances
    When delete relation type: marriage
    When transaction closes
    When connection open write transaction for database: typedb
    When $m = relation(marriage) create new instance
    When $p = entity(person) create new instance
    When relation $m add player for role(wife): $p
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
    When relation(marriage) get role(husband) set annotation: @card(0..)
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
    Then relation(marriage) delete role: wife
    Then relation(marriage) get role(wife) does not exist
    Then delete relation type: marriage
    Then relation(marriage) does not exist
    Then transaction commits


  Scenario: Ordered role types that have instances cannot be deleted or unset
    When create attribute type: id
    When attribute(id) set value type: string
    When create relation type: marriage
    When relation(marriage) create role: wife
    When relation(marriage) create role: husband
    When relation(marriage) get role(wife) set ordering: ordered
    When relation(marriage) get role(husband) set ordering: ordered
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
    Then relation(marriage) delete role: wife
    Then relation(marriage) get role(wife) does not exist
    Then delete relation type: marriage
    Then relation(marriage) does not exist
    Then transaction commits


  Scenario Outline: Owns that have instances of type <value-type> cannot be unset
    When create entity type: person
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When entity(person) set owns: name
    When transaction commits
    When connection open write transaction for database: typedb
    When $p = entity(person) create new instance
    When $n = attribute(name) put instance with value: <value>
    When entity $p set has: $n
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) unset owns: name; fails
    When transaction closes
    When connection open write transaction for database: typedb
    When $p = entity(person) get instance with key(name): <value>
    When $n = attribute(name) get instance with value: <value>
    When entity $p unset has: $n
    When transaction commits
    When connection open schema transaction for database: typedb
    When entity(person) unset owns: name
    Then entity(person) get owns do not contain:
      | name |
    When transaction commits
    Examples:
      | value-type  | value           |
      | long        | 1               |
      | double      | 1.0             |
      | decimal     | 1.0             |
      | string      | "alice"         |
      | boolean     | true            |
      | date        | 2024-05-04      |
      | datetime    | 2024-05-04      |
      | datetime-tz | 2024-05-04+0010 |
      | duration    | P1Y             |


  Scenario Outline: Ordered owns that have instances of type <value-type> cannot be unset
    When create entity type: person
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When entity(person) set owns: name
    When entity(person) get owns(name) set ordering: ordered
    When transaction commits
    When connection open write transaction for database: typedb
    When $p = entity(person) create new instance
    When $n = attribute(name) put instance with value: <value>
    When entity $p set has(name[]): [$n]
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) unset owns: name; fails
    When transaction closes
    When connection open write transaction for database: typedb
    # TODO: If cant get by ordered key, just create another owns for get!
    When $p = entity(person) get instance with key(name): <value>
    When entity $p unset has: name[]
    When transaction commits
    When connection open schema transaction for database: typedb
    When entity(person) unset owns: name
    Then entity(person) get owns do not contain:
      | name |
    When transaction commits
    Examples:
      | value-type  | value           |
      | long        | 1               |
      | double      | 1.0             |
      | decimal     | 1.0             |
      | string      | "alice"         |
      | boolean     | true            |
      | date        | 2024-05-04      |
      | datetime    | 2024-05-04      |
      | datetime-tz | 2024-05-04+0010 |
      | duration    | P1Y             |


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
    When relation(fathership) set supertype: parentship
    When create entity type: person
    When entity(person) set plays: fathership:father
    Then transaction commits
    When connection open write transaction for database: typedb
    When $f = relation(fathership) create new instance
    When $p = entity(person) create new instance
    When relation $f add player for role(father): $p
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
    When relation(fathership) set supertype: parentship
    When create entity type: person
    When entity(person) set plays: fathership:father
    Then transaction commits
    When connection open write transaction for database: typedb
    When $f = relation(fathership) create new instance
    When $p = entity(person) create new instance
    When relation $f add player for role(father): $p
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

########################
# ordering or value type update with existing data
########################

  Scenario: Role can change ordering if it does not have role instances even if its relation has instances
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) create role: child
    When relation(parentship) get role(child) set annotation: @card(0..)
    When create entity type: person
    When entity(person) set plays: parentship:parent
    When transaction commits
    When connection open write transaction for database: typedb
    When $m = relation(parentship) create new instance
    When $a = entity(person) create new instance
    When relation $m add player for role(parent): $a
    When transaction commits
    When connection open schema transaction for database: typedb
    When relation(parentship) get role(child) set ordering: ordered
    Then relation(parentship) get role(child) get ordering: ordered
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(child) get ordering: ordered
    When relation(parentship) get role(child) set ordering: unordered
    Then relation(parentship) get role(child) get ordering: unordered
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(child) get ordering: unordered

  Scenario: Role cannot change ordering if it has role instances
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) create role: child
    When relation(parentship) get role(child) set ordering: ordered
    When create attribute type: id
    When attribute(id) set value type: long
    When relation(parentship) set owns: id
    When relation(parentship) get owns(id) set annotation: @key
    When create entity type: person
    When entity(person) set plays: parentship:parent
    When entity(person) set plays: parentship:child
    When entity(person) set owns: id
    When entity(person) get owns(id) set annotation: @key
    When transaction commits
    When connection open write transaction for database: typedb
    When $m = relation(parentship) create new instance with key(id): 1
    When $a = entity(person) create new instance with key(id): 1
    When relation $m add player for role(parent): $a
    When relation $m add player for role(child): $a
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) set ordering: unordered; fails
    Then relation(parentship) get role(parent) set ordering: ordered; fails
    Then relation(parentship) get role(child) set ordering: unordered; fails
    Then relation(parentship) get role(child) set ordering: ordered; fails
    When transaction closes
    When connection open write transaction for database: typedb
    When $m = relation(parentship) get instance with key(id): 1
    When $a = entity(person) get instance with key(id): 1
    When delete entity: $a
    When delete relation: $m
    When transaction commits
    When connection open schema transaction for database: typedb
    When relation(parentship) get role(parent) set ordering: ordered
    Then relation(parentship) get role(parent) get ordering: ordered
    When relation(parentship) get role(child) set ordering: unordered
    Then relation(parentship) get role(child) get ordering: unordered
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get role(parent) get ordering: ordered
    Then relation(parentship) get role(child) get ordering: unordered

  Scenario: Owns can change ordering if it does not have instances even if its owner has instances for entity type
    When create attribute type: name
    When attribute(name) set value type: double
    When create entity type: person
    When entity(person) set owns: name
    When transaction commits
    When connection open write transaction for database: typedb
    When $a = entity(person) create new instance
    When transaction commits
    When connection open schema transaction for database: typedb
    When entity(person) get owns(name) set ordering: ordered
    Then entity(person) get owns(name) get ordering: ordered
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(name) get ordering: ordered
    When entity(person) get owns(name) set ordering: unordered
    Then entity(person) get owns(name) get ordering: unordered
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(name) get ordering: unordered

  Scenario: Owns cannot change ordering if it has role instances for entity type
    When create attribute type: id
    When attribute(id) set value type: long
    When create attribute type: name
    When attribute(name) set value type: string
    When create attribute type: email
    When attribute(email) set value type: decimal
    When create entity type: person
    When entity(person) set owns: id
    When entity(person) get owns(id) set annotation: @key
    When entity(person) set owns: name
    When entity(person) get owns(name) set annotation: @card(0..)
    When entity(person) set owns: email
    When entity(person) get owns(email) set ordering: ordered
    When transaction commits
    When connection open write transaction for database: typedb
    When $e = entity(person) create new instance with key(id): 1
    When $a1 = attribute(name) put instance with value: "a1"
    When $a2 = attribute(name) put instance with value: "a2"
    When entity $e set has: $a1
    When entity $e set has: $a2
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(name) set ordering: unordered; fails
    Then entity(person) get owns(name) set ordering: ordered; fails
    Then entity(person) get owns(email) set ordering: unordered
    Then entity(person) get owns(email) set ordering: ordered
    When transaction commits
    When connection open write transaction for database: typedb
    When $a = entity(person) get instance with key(id): 1
    When delete entity: $a
    When transaction commits
    When connection open schema transaction for database: typedb
    When entity(person) get owns(name) set ordering: ordered
    Then entity(person) get owns(name) get ordering: ordered
    When entity(person) get owns(email) set ordering: unordered
    Then entity(person) get owns(email) get ordering: unordered
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns(name) get ordering: ordered
    Then entity(person) get owns(email) get ordering: unordered


  Scenario: Attribute types cannot change value type while having instances
    When create attribute type: name
    When attribute(name) set value type: string
    When attribute(name) set annotation: @independent
    Then transaction commits
    When connection open write transaction for database: typedb
    When attribute(name) put instance with value: "bob"
    Then transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) set value type: long; fails
    Then attribute(name) set value type: double; fails
    Then attribute(name) set value type: decimal; fails
    Then attribute(name) set value type: datetime; fails
    Then attribute(name) set value type: boolean; fails
    Then attribute(name) set value type: date; fails
    Then attribute(name) set value type: datetime-tz; fails
    Then attribute(name) set value type: duration; fails
    When attribute(name) set value type: string
    Then transaction closes
    When connection open read transaction for database: typedb
    Then $a = attribute(name) get instance with value: "bob"
    Then attribute $a exists

########################
# @annotations update with existing data
########################

     # TODO: Make a series of annotations validations on the existing data for each type and capability
  Scenario: <root-type> types can only commit keys if every instance owns a distinct key
    When create attribute type: email
    When attribute(email) set value type: string
    When create attribute type: username
    When attribute(username) set value type: string
    When create entity type: person
    When entity(person) set owns: username
    When entity(person) get owns(username) set annotation: @key
    Then transaction commits
    When connection open write transaction for database: typedb
    When $a = entity(person) create new instance with key(username): alice
    When $b = entity(person) create new instance with key(username): bob
    Then transaction commits
    When connection open schema transaction for database: typedb
    When entity(person) set owns: email
    When entity(person) get owns(email) set annotation: @key; fails
    When transaction closes
    When connection open schema transaction for database: typedb
    When entity(person) set owns: email
    Then transaction commits
    When connection open write transaction for database: typedb
    When $a = entity(person) get instance with key(username): alice
    When $alice = attribute(email) put instance with value: alice@vaticle.com
    When entity $a set has: $alice
    When $b = entity(person) get instance with key(username): bob
    When $bob = attribute(email) put instance with value: bob@vaticle.com
    When entity $b set has: $bob
    Then transaction commits
    When connection open schema transaction for database: typedb
    When entity(person) set owns: email
    When entity(person) get owns(email) set annotation: @key
    Then entity(person) get owns(email) get annotations contain: @key
    Then entity(person) get owns(username) get annotations contain: @key
    Then transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns(email) get annotations contain: @key
    Then entity(person) get owns(username) get annotations contain: @key


  Scenario: Owns data is revalidated with set/unset @key, @card and @unique annotations
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
    Then entity(ent0u) get owns(attr0) unset annotation: @card; fails
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
    Given connection open schema transaction for database: typedb
    When entity(ent0u) get owns(attr0) unset annotation: @key
    Then transaction commits
    Given connection open write transaction for database: typedb
    When $ent0u = entity(ent0u) get instance with key(ref): ent0u
    When $attr0 = attribute(attr0) get instance with value: "attr0"
    Then entity $ent0u get has contain: $attr0
    When entity $ent0u unset has: $attr0
    Then entity $ent0u get has do not contain: $attr0
    Then transaction commits
    Given connection open schema transaction for database: typedb
    Then entity(ent0u) get owns(attr0) set annotation: @key; fails
    Then entity(ent0u) get owns(attr0) set annotation: @card(1..1); fails


  Scenario: Owns data is validated to be unique for all siblings overriding an owns with @unique
    Given create attribute type: attr0
    Given attribute(attr0) set value type: string
    Given attribute(attr0) set annotation: @abstract
    Given attribute(attr0) set annotation: @independent
    Given create attribute type: attr1
    Given attribute(attr1) set supertype: attr0
    Given create attribute type: attr2
    Given attribute(attr2) set supertype: attr0
    Given create attribute type: ref
    Given attribute(ref) set value type: string
    Given create entity type: ent0
    Given create entity type: ent1
    Given create entity type: ent2
    Given entity(ent0) set annotation: @abstract
    Given entity(ent0) set owns: ref
    Given entity(ent0) set owns: attr0
    Given entity(ent1) set owns: attr1
    Given entity(ent1) set supertype: ent0
    Given entity(ent1) get owns(attr1) set override: attr0
    Given entity(ent2) set owns: attr2
    Given entity(ent2) set supertype: ent0
    Given entity(ent2) get owns(attr2) set override: attr0
    Given entity(ent0) get owns(attr0) set annotation: @card(0..)
    Given transaction commits
    Given connection open write transaction for database: typedb
    Given $ent1 = entity(ent1) create new instance with key(ref): ent1
    Given $ent2 = entity(ent2) create new instance with key(ref): ent2
    Given $attr1_0 = attribute(attr1) put instance with value: "val1"
    Given $attr2_0 = attribute(attr2) put instance with value: "val2"
    Given $attr2_1 = attribute(attr2) put instance with value: "val1"
    Given entity $ent1 set has: $attr1_0
    Given entity $ent2 set has: $attr2_0
    Given entity $ent2 set has: $attr2_1
    Given transaction commits
    Given connection open schema transaction for database: typedb
    Then entity(ent0) get owns(attr0) set annotation: @unique; fails
    When entity(ent1) get owns(attr1) set annotation: @unique
    When entity(ent2) get owns(attr2) set annotation: @unique

    When transaction commits
    Given connection open read transaction for database: typedb
    Given $ent1 = entity(ent1) get instance with key(ref): ent1
    Given $ent2 = entity(ent2) get instance with key(ref): ent2
    Given $attr1_0 = attribute(attr1) get instance with value: "val1"
    Given $attr2_0 = attribute(attr2) get instance with value: "val2"
    Given $attr2_1 = attribute(attr2) get instance with value: "val1"
    Then entity $ent1 get has contain: $attr1_0
    Then entity $ent2 get has contain: $attr2_0
    Then entity $ent2 get has contain: $attr2_1
    Given transaction closes

    Given connection open schema transaction for database: typedb
    Then entity(ent0) get owns(attr0) set annotation: @unique; fails
    When entity(ent1) get owns(attr1) unset annotation: @unique
    When entity(ent2) get owns(attr2) unset annotation: @unique
    Then entity(ent0) get owns(attr0) set annotation: @unique; fails
    When transaction commits

    Given connection open write transaction for database: typedb
    Given $ent2 = entity(ent2) get instance with key(ref): ent2
    Given $attr2_1 = attribute(attr2) get instance with value: "val1"
    Given entity $ent2 unset has: $attr2_1
    When transaction commits

    Given connection open schema transaction for database: typedb
    Then entity(ent0) get owns(attr0) set annotation: @unique
    Then transaction commits
    Given connection open write transaction for database: typedb
    Given $ent2 = entity(ent2) get instance with key(ref): ent2
    Given $attr2_1 = attribute(attr2) get instance with value: "val1"
    Then entity $ent2 set has: $attr2_1; fails
    Given $ent1 = entity(ent1) get instance with key(ref): ent1
    Given $attr1_0 = attribute(attr1) get instance with value: "val1"
    When entity $ent1 unset has: $attr1_0
    Then entity $ent2 set has: $attr2_1
    Then transaction commits


  Scenario: Owns data is validated to be unique for all siblings overriding an owns with @key
    Given create attribute type: attr0
    Given attribute(attr0) set value type: string
    Given attribute(attr0) set annotation: @abstract
    Given attribute(attr0) set annotation: @independent
    Given create attribute type: attr1
    Given attribute(attr1) set supertype: attr0
    Given create attribute type: attr2
    Given attribute(attr2) set supertype: attr0
    Given create attribute type: ref
    Given attribute(ref) set value type: string
    Given create entity type: ent0
    Given create entity type: ent1
    Given create entity type: ent2
    Given entity(ent0) set annotation: @abstract
    Given entity(ent0) set owns: ref
    Given entity(ent0) set owns: attr0
    Given entity(ent1) set owns: attr1
    Given entity(ent1) set supertype: ent0
    Given entity(ent1) get owns(attr1) set override: attr0
    Given entity(ent2) set owns: attr2
    Given entity(ent2) set supertype: ent0
    Given entity(ent2) get owns(attr2) set override: attr0
    Given transaction commits
    Given connection open write transaction for database: typedb
    Given $ent1 = entity(ent1) create new instance with key(ref): ent1
    Given $ent2 = entity(ent2) create new instance with key(ref): ent2
    Given $attr1_0 = attribute(attr1) put instance with value: "val1"
    Given $attr2_0 = attribute(attr2) put instance with value: "val1"
    Given entity $ent1 set has: $attr1_0
    Given entity $ent2 set has: $attr2_0
    Given transaction commits
    Given connection open schema transaction for database: typedb
    Then entity(ent0) get owns(attr0) set annotation: @key; fails
    When entity(ent1) get owns(attr1) set annotation: @key
    When entity(ent2) get owns(attr2) set annotation: @key

    When transaction commits
    Given connection open read transaction for database: typedb
    Given $ent1 = entity(ent1) get instance with key(ref): ent1
    Given $ent2 = entity(ent2) get instance with key(ref): ent2
    Given $attr1_0 = attribute(attr1) get instance with value: "val1"
    Given $attr2_0 = attribute(attr2) get instance with value: "val1"
    Then entity $ent1 get has contain: $attr1_0
    Then entity $ent2 get has contain: $attr2_0
    Given transaction closes

    Given connection open schema transaction for database: typedb
    Then entity(ent0) get owns(attr0) set annotation: @key; fails
    When entity(ent1) get owns(attr1) unset annotation: @key
    When entity(ent2) get owns(attr2) unset annotation: @key
    Then entity(ent0) get owns(attr0) set annotation: @key; fails
    When transaction commits

    Given connection open write transaction for database: typedb
    Given $ent2 = entity(ent2) get instance with key(ref): ent2
    Given $attr2_0 = attribute(attr2) get instance with value: "val1"
    Given entity $ent2 unset has: $attr2_0
    When transaction commits

    Given connection open schema transaction for database: typedb
    Then entity(ent0) get owns(attr0) set annotation: @key; fails
    When transaction closes

    Given connection open write transaction for database: typedb
    Given $ent2 = entity(ent2) get instance with key(ref): ent2
    When $attr2_1 = attribute(attr2) put instance with value: "val2"
    When entity $ent2 set has: $attr2_1
    Then transaction commits

    Given connection open schema transaction for database: typedb
    Then entity(ent0) get owns(attr0) set annotation: @key

    Then transaction commits
    Given connection open write transaction for database: typedb
    Given $ent2 = entity(ent2) get instance with key(ref): ent2
    Given $attr2_0 = attribute(attr2) get instance with value: "val1"
    Then entity $ent2 set has: $attr2_0; fails
    When $attr2_1 = attribute(attr2) get instance with value: "val2"
    When entity $ent2 unset has: $attr2_1
    Then entity $ent2 set has: $attr2_0; fails
    # Wrong cardinality
    Then transaction commits; fails


  Scenario: Owns data is revalidated with set @regex
    When create attribute type: attr0
    When attribute(attr0) set value type: string
    When attribute(attr0) set annotation: @abstract
    When attribute(attr0) set annotation: @independent
    When create attribute type: attr1
    When attribute(attr1) set supertype: attr0
    When create attribute type: attr2
    When attribute(attr2) set supertype: attr0
    When create attribute type: ref
    When attribute(ref) set value type: string
    When create entity type: ent0
    When create entity type: ent1
    When entity(ent0) set annotation: @abstract
    When entity(ent0) set owns: ref
    When entity(ent0) set owns: attr0
    When entity(ent0) get owns(attr0) set annotation: @card(0..)
    When entity(ent1) set owns: attr1
    When entity(ent1) set owns: attr2
    When entity(ent1) set supertype: ent0
    When entity(ent1) get owns(attr1) set override: attr0
    When entity(ent1) get owns(attr2) set override: attr0
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent1 = entity(ent1) create new instance with key(ref): ent1
    When $attr1_val = attribute(attr1) put instance with value: "val"
    When $attr2_val1 = attribute(attr2) put instance with value: "val1"
    When entity $ent1 set has: $attr1_val
    When entity $ent1 set has: $attr2_val1
    When transaction commits

    When connection open schema transaction for database: typedb
    Then entity(ent0) get owns(attr0) set annotation: @regex("val\d+"); fails
    Then entity(ent1) get owns(attr1) set annotation: @regex("val\d+"); fails
    When entity(ent1) get owns(attr2) set annotation: @regex("val\d+")

    When transaction commits
    When connection open write transaction for database: typedb
    When $ent1 = entity(ent1) get instance with key(ref): ent1
    When $attr1_val = attribute(attr1) get instance with value: "val"
    When $attr2_val1 = attribute(attr2) get instance with value: "val1"
    Then entity $ent1 get has contain: $attr1_val
    Then entity $ent1 get has contain: $attr2_val1
    When $attr2_val = attribute(attr2) put instance with value: "val"
    Then entity $ent1 set has: $attr2_val; fails
    When entity $ent1 unset has: $attr1_val
    Then entity $ent1 get has do not contain: $attr1_val
    When transaction commits

    When connection open schema transaction for database: typedb
    Then entity(ent0) get owns(attr0) set annotation: @regex("val\d+")
    Then entity(ent1) get owns(attr1) set annotation: @regex("val\d+")
    When entity(ent1) get owns(attr1) unset annotation: @regex
    When entity(ent1) get owns(attr2) unset annotation: @regex
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent1 = entity(ent1) get instance with key(ref): ent1
    When $attr1_val = attribute(attr1) get instance with value: "val"
    When $attr2_val = attribute(attr2) get instance with value: "val"
    When $attr2_val1 = attribute(attr2) get instance with value: "val1"
    Then entity $ent1 get has do not contain: $attr1_val
    Then entity $ent1 get has do not contain: $attr2_val
    Then entity $ent1 get has contain: $attr2_val1
    Then entity $ent1 set has: $attr1_val; fails
    Then entity $ent1 set has: $attr2_val; fails
    When $attr1_val22 = attribute(attr1) put instance with value: "val22"
    When $attr2_val22 = attribute(attr2) put instance with value: "val22"
    Then entity $ent1 set has: $attr1_val22
    Then entity $ent1 set has: $attr2_val22
    When transaction commits

    When connection open schema transaction for database: typedb
    When create attribute type: attr01
    When attribute(attr01) set annotation: @abstract
    When entity(ent0) set owns: attr01
#    When entity(ent0) get owns(attr01) set annotation: @regex("val.*")
    When entity(ent0) get owns(attr01) set annotation: @card(0..)
    When attribute(attr0) set supertype: attr01
    When entity(ent1) get owns(attr1) set override: attr01
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent1 = entity(ent1) get instance with key(ref): ent1
    When $attr1_val = attribute(attr1) get instance with value: "val"
    Then entity $ent1 set has: $attr1_val
    When transaction commits

    When connection open schema transaction for database: typedb
    Then entity(ent1) get owns(attr1) set override: attr0; fails
    Then entity(ent0) get owns(attr01) set annotation: @regex("val\d+"); fails
    Then entity(ent1) get owns(attr1) set annotation: @regex("val\d+"); fails
    When transaction closes

    When connection open write transaction for database: typedb
    When $ent1 = entity(ent1) get instance with key(ref): ent1
    When $attr1_val = attribute(attr1) get instance with value: "val"
    Then entity $ent1 unset has: $attr1_val
    When transaction commits

    When connection open schema transaction for database: typedb
    Then entity(ent1) get owns(attr1) set override: attr0
    # To override all abstract interfaces:
    Then entity(ent1) get owns(attr2) set override: attr01
    Then transaction commits


  Scenario: Owns data is revalidated with set @range
    When create attribute type: attr0
    When attribute(attr0) set value type: string
    When attribute(attr0) set annotation: @abstract
    When attribute(attr0) set annotation: @independent
    When create attribute type: attr1
    When attribute(attr1) set supertype: attr0
    When create attribute type: attr2
    When attribute(attr2) set supertype: attr0
    When create attribute type: ref
    When attribute(ref) set value type: string
    When create entity type: ent0
    When create entity type: ent1
    When entity(ent0) set annotation: @abstract
    When entity(ent0) set owns: ref
    When entity(ent0) set owns: attr0
    When entity(ent0) get owns(attr0) set annotation: @card(0..)
    When entity(ent1) set owns: attr1
    When entity(ent1) set owns: attr2
    When entity(ent1) set supertype: ent0
    When entity(ent1) get owns(attr1) set override: attr0
    When entity(ent1) get owns(attr2) set override: attr0
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent1 = entity(ent1) create new instance with key(ref): ent1
    When $attr1_val = attribute(attr1) put instance with value: "val"
    When $attr2_val1 = attribute(attr2) put instance with value: "val1"
    When entity $ent1 set has: $attr1_val
    When entity $ent1 set has: $attr2_val1
    When transaction commits

    When connection open schema transaction for database: typedb
    Then entity(ent0) get owns(attr0) set annotation: @range("val1".."val9"); fails
    Then entity(ent1) get owns(attr1) set annotation: @range("val1".."val9"); fails
    When entity(ent1) get owns(attr2) set annotation: @range("val1".."val9")

    When transaction commits
    When connection open write transaction for database: typedb
    When $ent1 = entity(ent1) get instance with key(ref): ent1
    When $attr1_val = attribute(attr1) get instance with value: "val"
    When $attr2_val1 = attribute(attr2) get instance with value: "val1"
    Then entity $ent1 get has contain: $attr1_val
    Then entity $ent1 get has contain: $attr2_val1
    When $attr2_val = attribute(attr2) put instance with value: "val"
    Then entity $ent1 set has: $attr2_val; fails
    When entity $ent1 unset has: $attr1_val
    Then entity $ent1 get has do not contain: $attr1_val
    When transaction commits

    When connection open schema transaction for database: typedb
    Then entity(ent0) get owns(attr0) set annotation: @range("val1".."val9")
    Then entity(ent1) get owns(attr1) set annotation: @range("val1".."val9")
    When entity(ent1) get owns(attr1) unset annotation: @range
    When entity(ent1) get owns(attr2) unset annotation: @range
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent1 = entity(ent1) get instance with key(ref): ent1
    When $attr1_val = attribute(attr1) get instance with value: "val"
    When $attr2_val = attribute(attr2) get instance with value: "val"
    When $attr2_val1 = attribute(attr2) get instance with value: "val1"
    Then entity $ent1 get has do not contain: $attr1_val
    Then entity $ent1 get has do not contain: $attr2_val
    Then entity $ent1 get has contain: $attr2_val1
    Then entity $ent1 set has: $attr1_val; fails
    Then entity $ent1 set has: $attr2_val; fails
    When $attr1_val22 = attribute(attr1) put instance with value: "val22"
    When $attr2_val22 = attribute(attr2) put instance with value: "val22"
    Then entity $ent1 set has: $attr1_val22
    Then entity $ent1 set has: $attr2_val22
    When transaction commits

    When connection open schema transaction for database: typedb
    When create attribute type: attr01
    When attribute(attr01) set annotation: @abstract
    When attribute(attr01) set value type: string
    When attribute(attr0) set supertype: attr01
    When attribute(attr0) unset value type
    When entity(ent0) set owns: attr01
    When entity(ent0) get owns(attr01) set annotation: @range("val".."val9999")
    When entity(ent0) get owns(attr01) set annotation: @card(0..)
    When entity(ent1) get owns(attr1) set override: attr01
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent1 = entity(ent1) get instance with key(ref): ent1
    When $attr1_val = attribute(attr1) get instance with value: "val"
    Then entity $ent1 set has: $attr1_val
    When transaction commits

    When connection open schema transaction for database: typedb
    Then entity(ent1) get owns(attr1) set override: attr0; fails
    Then entity(ent0) get owns(attr01) set annotation: @range("val1".."val9"); fails
    Then entity(ent1) get owns(attr1) set annotation: @range("val1".."val9"); fails
    When transaction closes

    When connection open write transaction for database: typedb
    When $ent1 = entity(ent1) get instance with key(ref): ent1
    When $attr1_val = attribute(attr1) get instance with value: "val"
    Then entity $ent1 unset has: $attr1_val
    When transaction commits

    When connection open schema transaction for database: typedb
    Then entity(ent1) get owns(attr1) set override: attr0
    # To override all abstract interfaces:
    Then entity(ent1) get owns(attr2) set override: attr01
    Then transaction commits


  Scenario: Owns data is revalidated with set @values
    When create attribute type: attr0
    When attribute(attr0) set value type: string
    When attribute(attr0) set annotation: @abstract
    When attribute(attr0) set annotation: @independent
    When create attribute type: attr1
    When attribute(attr1) set supertype: attr0
    When create attribute type: attr2
    When attribute(attr2) set supertype: attr0
    When create attribute type: ref
    When attribute(ref) set value type: string
    When create entity type: ent0
    When create entity type: ent1
    When entity(ent0) set annotation: @abstract
    When entity(ent0) set owns: ref
    When entity(ent0) set owns: attr0
    When entity(ent0) get owns(attr0) set annotation: @card(0..)
    When entity(ent1) set owns: attr1
    When entity(ent1) set owns: attr2
    When entity(ent1) set supertype: ent0
    When entity(ent1) get owns(attr1) set override: attr0
    When entity(ent1) get owns(attr2) set override: attr0
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent1 = entity(ent1) create new instance with key(ref): ent1
    When $attr1_val = attribute(attr1) put instance with value: "val"
    When $attr2_val1 = attribute(attr2) put instance with value: "val1"
    When entity $ent1 set has: $attr1_val
    When entity $ent1 set has: $attr2_val1
    When transaction commits

    When connection open schema transaction for database: typedb
    Then entity(ent0) get owns(attr0) set annotation: @values("val1", "val22", "vall"); fails
    Then entity(ent1) get owns(attr1) set annotation: @values("val1", "val22", "vall"); fails
    When entity(ent1) get owns(attr2) set annotation: @values("val1", "val22", "vall")

    When transaction commits
    When connection open write transaction for database: typedb
    When $ent1 = entity(ent1) get instance with key(ref): ent1
    When $attr1_val = attribute(attr1) get instance with value: "val"
    When $attr2_val1 = attribute(attr2) get instance with value: "val1"
    Then entity $ent1 get has contain: $attr1_val
    Then entity $ent1 get has contain: $attr2_val1
    When $attr2_val = attribute(attr2) put instance with value: "val"
    Then entity $ent1 set has: $attr2_val; fails
    When entity $ent1 unset has: $attr1_val
    Then entity $ent1 get has do not contain: $attr1_val
    When transaction commits

    When connection open schema transaction for database: typedb
    Then entity(ent0) get owns(attr0) set annotation: @values("val1", "val22", "vall")
    Then entity(ent1) get owns(attr1) set annotation: @values("val1", "val22", "vall")
    When entity(ent1) get owns(attr1) unset annotation: @values
    When entity(ent1) get owns(attr2) unset annotation: @values
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent1 = entity(ent1) get instance with key(ref): ent1
    When $attr1_val = attribute(attr1) get instance with value: "val"
    When $attr2_val = attribute(attr2) get instance with value: "val"
    When $attr2_val1 = attribute(attr2) get instance with value: "val1"
    Then entity $ent1 get has do not contain: $attr1_val
    Then entity $ent1 get has do not contain: $attr2_val
    Then entity $ent1 get has contain: $attr2_val1
    Then entity $ent1 set has: $attr1_val; fails
    Then entity $ent1 set has: $attr2_val; fails
    When $attr1_val22 = attribute(attr1) put instance with value: "val22"
    When $attr2_val22 = attribute(attr2) put instance with value: "val22"
    Then entity $ent1 set has: $attr1_val22
    Then entity $ent1 set has: $attr2_val22
    When transaction commits

    When connection open schema transaction for database: typedb
    When create attribute type: attr01
    When attribute(attr01) set annotation: @abstract
    When attribute(attr01) set value type: string
    When attribute(attr0) set supertype: attr01
    When attribute(attr0) unset value type
    When entity(ent0) set owns: attr01
    When entity(ent0) get owns(attr01) set annotation: @values("val", "vall", "val1", "val22", "val9")
    When entity(ent0) get owns(attr01) set annotation: @card(0..)
    When entity(ent1) get owns(attr1) set override: attr01
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent1 = entity(ent1) get instance with key(ref): ent1
    When $attr1_val = attribute(attr1) get instance with value: "val"
    Then entity $ent1 set has: $attr1_val
    When transaction commits

    When connection open schema transaction for database: typedb
    Then entity(ent1) get owns(attr1) set override: attr0; fails
    Then entity(ent0) get owns(attr01) set annotation: @values("val1", "val22", "vall"); fails
    Then entity(ent1) get owns(attr1) set annotation: @values("val1", "val22", "vall"); fails
    When transaction closes

    When connection open write transaction for database: typedb
    When $ent1 = entity(ent1) get instance with key(ref): ent1
    When $attr1_val = attribute(attr1) get instance with value: "val"
    Then entity $ent1 unset has: $attr1_val
    When transaction commits

    When connection open schema transaction for database: typedb
    Then entity(ent1) get owns(attr1) set override: attr0
    # To override all abstract interfaces:
    Then entity(ent1) get owns(attr2) set override: attr01
    Then transaction commits



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
