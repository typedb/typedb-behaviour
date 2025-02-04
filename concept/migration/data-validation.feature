# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Data validation

  Background:
    Given typedb starts
    Given connection opens with default authentication
    Given connection is open: true
    Given connection has 0 databases
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
    When relation(marriage) get role(wife) set annotation: @card(0..1)
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
    When relation(marriage) get role(wife) set annotation: @card(0..)
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
    Then relation $m get players for role(wife) is empty
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
    Then relation $m get players for role(wife) is empty
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
      | integer     | 1               |
      | double      | 1.0             |
      | decimal     | 1.0dec          |
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
      | integer     | 1               |
      | double      | 1.0             |
      | decimal     | 1.0dec          |
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
    When relation(marriage) get role(wife) set annotation: @card(0..1)
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
    Then entity(person) get constraints contain: @abstract
    Then entity(person) get declared annotations contain: @abstract
    Then entity(player) get constraints do not contain: @abstract
    Then entity(player) get declared annotations do not contain: @abstract
    Then entity(player) get instances is not empty


  Scenario: Relation types can be set to abstract when a subtype has instances
    When create relation type: parentship
    When relation(parentship) create role: parent
    When create relation type: fathership
    When relation(fathership) create role: father
    When relation(fathership) set supertype: parentship
    When relation(fathership) get role(father) set specialise: parent
    When create entity type: person
    When entity(person) set plays: fathership:father
    Then transaction commits
    When connection open write transaction for database: typedb
    When $f = relation(fathership) create new instance
    When $p = entity(person) create new instance
    When relation $f add player for role(father): $p
    Then transaction commits
    When connection open schema transaction for database: typedb
    When relation(parentship) set annotation: @abstract
    When relation(parentship) get role(parent) set annotation: @abstract
    Then transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get constraints contain: @abstract
    Then relation(parentship) get declared annotations contain: @abstract
    Then relation(fathership) get constraints do not contain: @abstract
    Then relation(fathership) get declared annotations do not contain: @abstract
    Then relation(parentship) get role(parent) get constraints contain: @abstract
    Then relation(parentship) get role(parent) get declared annotations contain: @abstract
    Then relation(fathership) get role(father) get constraints do not contain: @abstract
    Then relation(fathership) get role(father) get declared annotations do not contain: @abstract
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
    When relation(parentship) get role(parent) set annotation: @card(1..1)
    When create relation type: fathership
    When relation(fathership) create role: father
    When relation(fathership) set supertype: parentship
    When relation(fathership) get role(father) set specialise: parent
    When create entity type: person
    When entity(person) set plays: fathership:father
    Then transaction commits
    When connection open write transaction for database: typedb
    When $f = relation(fathership) create new instance
    When $p = entity(person) create new instance
    When relation $f add player for role(father): $p
    Then transaction commits
    When connection open schema transaction for database: typedb
    When relation(fathership) get role(father) unset specialise
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When relation(fathership) unset supertype; fails with a message containing: "will be lost"
    When delete relation type: parentship; fails with a message containing: "existing subtypes"
    When relation(parentship) get role(parent) set annotation: @card(0..1)
    Then relation(fathership) get role(father) unset specialise
    Then relation(fathership) unset supertype
    Then delete relation type: parentship
    Then transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) does not exist
    Then relation(fathership) get instances is not empty


  Scenario: Relation types relates default cardinality can be violated
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) get cardinality: @card(0..1)
    When create entity type: person
    When entity(person) set plays: parentship:parent
    Then transaction commits
    When connection open write transaction for database: typedb
    When $pa = relation(parentship) create new instance
    When $pe1 = entity(person) create new instance
    When $pe2 = entity(person) create new instance
    When relation $pa add player for role(parent): $pe1
    When relation $pa add player for role(parent): $pe2
    Then transaction commits; fails
    When connection open write transaction for database: typedb
    When $pa = relation(parentship) create new instance
    When $pe1 = entity(person) create new instance
    When relation $pa add player for role(parent): $pe1
    Then transaction commits
    When connection open write transaction for database: typedb
    When $pa1 = relation(parentship) create new instance
    When $pa2 = relation(parentship) create new instance
    When $pe1 = entity(person) create new instance
    When relation $pa1 add player for role(parent): $pe1
    Then transaction commits


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
    When create entity type: ent0
    When transaction commits
    When connection open write transaction for database: typedb
    When $a = entity(ent0) create new instance
    When transaction commits

    When connection open schema transaction for database: typedb
    Then delete entity type: ent0; fails


  Scenario: Instances of ownerships not in the schema must not exist
    When create entity type: ent00
    When create attribute type: attr00
    When attribute(attr00) set value type: string
    When entity(ent00) set owns: attr00
    When create entity type: ent1
    When entity(ent1) set supertype: ent00
    When create entity type: ent01
    When transaction commits
    When connection open write transaction for database: typedb
    When $ent1 = entity(ent1) create new instance
    When $attr00 = attribute(attr00) put instance with value: "attr00"
    When entity $ent1 set has: $attr00
    When transaction commits
    When connection open write transaction for database: typedb

    When $ent01 = entity(ent01) create new instance
    Then entity $ent01 set has: $attr00; fails

    When transaction closes
    When connection open schema transaction for database: typedb

    Then entity(ent00) unset owns: attr00; fails

    Then entity(ent1) set supertype: ent01; fails


  Scenario: Instances of roles not in the schema must not exist
    When create relation type: rel00
    When relation(rel00) create role: role00
    When create relation type: rel01
    When relation(rel01) create role: role01
    When create relation type: rel1
    When relation(rel1) set supertype: rel00
    When create entity type: ent0
    When entity(ent0) set plays: rel00:role00
    When transaction commits
    When connection open write transaction for database: typedb
    When $ent0 = entity(ent0) create new instance
    When $rel1 = relation(rel1) create new instance
    When relation $rel1 add player for role(role00): $ent0
    When transaction commits
    Given connection open schema transaction for database: typedb

    Then relation(rel00) delete role: role00; fails

    When transaction closes
    Given connection open schema transaction for database: typedb
    Then relation(rel1) set supertype: rel01; fails

    When transaction closes
    Given connection open schema transaction for database: typedb
    # The default card is 1..1 and we have instances of rel1!
    When relation(rel1) create role: role1
    Then relation(rel1) get role(role1) get cardinality: @card(0..1)
    Then relation(rel1) get role(role1) set specialise: role00; fails


  Scenario: Instances of role-playing not in the schema must not exist
    Given create relation type: rel0
    Given relation(rel0) create role: role0
    Given create relation type: rel1
    Given relation(rel1) set supertype: rel0
    Given relation(rel1) create role: role1
    Given relation(rel1) get role(role1) set specialise: role0
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
    Then entity(ent1) set supertype: ent01; fails


  Scenario: Instances of role-playing hidden by a relates specialise must not exist
    Given create relation type: rel0
    Given relation(rel0) create role: role0
    Given create relation type: rel1
    Given relation(rel1) set supertype: rel0
    Given relation(rel1) create role: role1
    Given relation(rel1) get role(role1) set specialise: role0
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

    # With no 'plays' specialise, we can still play the parent role in the parent relation
    Given connection open write transaction for database: typedb
    When $ent00 = entity(ent00) create new instance
    When $rel0 = relation(rel0) create new instance
    When relation $rel0 add player for role(role0): $ent00
    Then transaction commits


    # TODO: Uncomment this test when abstract plays are introduced!
#  Scenario: Instances of role-playing hidden by abstract roles must not exist
#    Given create relation type: rel0
#    Given relation(rel0) create role: role0
#    Given create relation type: rel1
#    Given relation(rel1) set supertype: rel0
#    Given relation(rel1) create role: role1
#    Given relation(rel1) get role(role1) set specialise: role0
#    Given create entity type: ent00
#    Given entity(ent00) set plays: rel0:role0
#    Given create entity type: ent1
#    Given entity(ent1) set supertype: ent00
#    Given entity(ent1) set plays: rel1:role1
##    Given entity(ent1) get plays(rel0:role0) set annotation: @abstract
#    Given transaction commits
#
#    Given connection open write transaction for database: typedb
#    When $ent1 = entity(ent1) create new instance
#    When $rel0 = relation(rel0) create new instance
#    When relation $rel0 add player for role(role0): $ent1; fails
#
#    When transaction closes
#    Given connection open write transaction for database: typedb
#    When $ent1 = entity(ent1) create new instance
#    When $rel1 = relation(rel1) create new instance
#    When relation $rel1 add player for role(role1): $ent1
#    Then transaction commits

  # TODO: Same as above, but with Owns when we let superattribute types to be non-abstract and introduce abstract owns

  Scenario: A type can play a subtype of a role it plays with existing instances
    Given create relation type: rel0
    Given relation(rel0) create role: role0
    Given create relation type: rel1
    Given relation(rel1) set supertype: rel0
    Given relation(rel1) create role: role1
    Given relation(rel1) get role(role1) set specialise: role0
    Given create entity type: ent00
    Given entity(ent00) set plays: rel0:role0
    Given create entity type: ent1
    Given entity(ent1) set supertype: ent00
    # Without the specialise
    Given entity(ent1) set plays: rel1:role1
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given $ent1 = entity(ent1) create new instance
    Given $rel0 = relation(rel0) create new instance
    Given relation $rel0 add player for role(role0): $ent1
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Given entity(ent1) set plays: rel1:role1
    Then transaction commits


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
    When entity(ent2) set owns: attr0
    Then entity(ent2) set supertype: ent10
    Then transaction commits

    When connection open schema transaction for database: typedb
    Then entity(ent2) unset owns: attr0; fails
    When entity(ent10) set owns: attr0
    Then entity(ent2) unset owns: attr0
    Then transaction commits

    When connection open schema transaction for database: typedb
    When create entity type: ent11
    Then entity(ent2) set supertype: ent11; fails
    When entity(ent11) set owns: attr0
    Then entity(ent2) set supertype: ent11
    Then transaction commits


  Scenario: A type may not be moved if it has role playing instances which would be lost as a result of that move
    Given create relation type: rel0
    Given relation(rel0) create role: role0
    Given create relation type: rel1
    Given relation(rel1) create role: role1
    Given create relation type: rel2
    Given relation(rel2) set supertype: rel0
    Given relation(rel2) create role: role2
    Given create entity type: ent0
    Given entity(ent0) set plays: rel0:role0
    Given create entity type: ent1
    Given create entity type: ent2
    Given entity(ent2) set supertype: ent0
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given $ent2 = entity(ent2) create new instance
    Given $rel2 = relation(rel2) create new instance
    Given relation $rel2 add player for role(role0): $ent2
    Given transaction commits

    When connection open schema transaction for database: typedb
    Then entity(ent2) set supertype: ent1; fails
    When entity(ent2) set plays: rel0:role0
    Then entity(ent2) set supertype: ent1
    Then transaction commits

    When connection open schema transaction for database: typedb
    Then entity(ent2) unset plays: rel0:role0; fails
    When entity(ent1) set plays: rel0:role0
    Then entity(ent2) unset plays: rel0:role0
    Then transaction commits

    When connection open schema transaction for database: typedb
    When create entity type: ent11
    Then entity(ent2) set supertype: ent11; fails
    When entity(ent11) set plays: rel0:role0
    Then entity(ent2) set supertype: ent11
    Then transaction commits


  Scenario: A relation type may not be moved if it has instances of roleplayers which would be lost as a result of that move
    Given create relation type: rel0
    Given relation(rel0) create role: role0
    Given create relation type: rel1
    Given relation(rel1) create role: role1
    Given create relation type: rel2
    Given relation(rel2) set supertype: rel0
    Given relation(rel2) create role: role2
    Given create entity type: ent0
    Given entity(ent0) set plays: rel0:role0
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given $ent0 = entity(ent0) create new instance
    Given $rel2 = relation(rel2) create new instance
    Given relation $rel2 add player for role(role0): $ent0
    Given transaction commits

    When connection open schema transaction for database: typedb
    Then relation(rel2) set supertype: rel1; fails
    Then transaction commits


    # TODO: Uncomment this test when abstract plays are introduced!
#  Scenario: A type may not be moved if it has instances of it playing a role which would be hidden as a result of that move
#    Given create relation type: rel0
#    Given relation(rel0) create role: role0
#    Given create relation type: rel1
#    Given relation(rel1) set supertype: rel0
#    Given relation(rel1) create role: role1
#    Given relation(rel1) get role(role1) set specialise: role0
#    Given create entity type: ent0
#    Given entity(ent0) set plays: rel0:role0
#    Given create entity type: ent10
#    Given entity(ent10) set supertype: ent0
#    Given create entity type: ent2
#    Given entity(ent2) set supertype: ent10
#    Given create entity type: ent11
#    Given entity(ent11) set supertype: ent0
#    Given entity(ent11) set plays: rel1:role1
#    # Given entity(ent11) get plays(rel1:role1) set annotation: @abstract
#    Given transaction commits
#    Given connection open write transaction for database: typedb
#    Given $ent2 = entity(ent2) create new instance
#    Given $rel0 = relation(rel0) create new instance
#    Given relation $rel0 add player for role(role0): $ent2
#    Given transaction commits
#
#    When connection open schema transaction for database: typedb
#    Then entity(ent2) set supertype: ent11; fails

  # TODO: Same as above, but with Owns when we let superattribute types to be non-abstract and introduce abstract owns

  Scenario: A relation type may not be moved if it has instances of roleplayers which would be hidden as a result of that move
    Given create relation type: rel0
    Given relation(rel0) create role: role0
    Given create relation type: rel1
    Given relation(rel1) set supertype: rel0
    Given relation(rel1) create role: role1
    Given relation(rel1) get role(role1) set specialise: role0
    Given create relation type: rel2
    Given relation(rel2) set supertype: rel0
    Given relation(rel2) create role: role2
    Given create entity type: ent0
    Given entity(ent0) set plays: rel0:role0
    # Given entity(ent11) get plays(rel1:role1) set annotation: @abstract
    Given transaction commits
    Given connection open write transaction for database: typedb
    Given $ent0 = entity(ent0) create new instance
    Given $rel2 = relation(rel2) create new instance
    Given relation $rel2 add player for role(role0): $ent0
    Given transaction commits

    When connection open schema transaction for database: typedb
    Then relation(rel2) set supertype: rel1; fails
    When relation(rel1) get role(role1) unset specialise
    Then relation(rel2) set supertype: rel1
    Then transaction commits

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
    When attribute(id) set value type: integer
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
    When attribute(id) set value type: integer
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
    Then attribute(name) set value type: integer; fails
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

  Scenario: Instances of abstract entity types must not exist
    When create entity type: ent0a
    When entity(ent0a) set annotation: @abstract
    When create entity type: ent0c
    When transaction commits

    When connection open write transaction for database: typedb
    Then entity(ent0a) create new instance; fails
    Then $a = entity(ent0c) create new instance
    Then transaction commits

    When connection open schema transaction for database: typedb
    Then entity(ent0c) set annotation: @abstract; fails


  Scenario: Instances of abstract relation types and role types must not exist
    When create entity type: ent0c
    When create relation type: rel0a
    When relation(rel0a) set annotation: @abstract
    When create relation type: rel0c
    When relation(rel0a) create role: rol0a
    When relation(rel0a) get role(rol0a) set annotation: @abstract
    When relation(rel0a) create role: rol0a2
    When relation(rel0c) create role: rol0c
    When entity(ent0c) set plays: rel0c:rol0c
    When entity(ent0c) set plays: rel0a:rol0a
    When entity(ent0c) set plays: rel0a:rol0a2
    When create relation type: rel0a2
    When relation(rel0a2) set supertype: rel0a
    When relation(rel0a2) create role: specialise
    When relation(rel0a) get role(rol0a) set annotation: @card(0..)
    When relation(rel0a2) get role(specialise) set specialise: rol0a
    Then relation(rel0a2) get relates contain:
      | rel0a:rol0a2 |
    When transaction commits

    When connection open write transaction for database: typedb
    Then relation(rel0a) create new instance; fails
    Then $e = entity(ent0c) create new instance
    Then $r = relation(rel0c) create new instance
    Then relation $r add player for role(rol0c): $e
    Then $rabstract = relation(rel0a) create new instance; fails
    Then $r2 = relation(rel0a2) create new instance
    Then relation $r2 add player for role(rol0a): $e; fails
    Then relation $r2 add player for role(rol0a2): $e
    Then transaction commits

    When connection open schema transaction for database: typedb
    Then relation(rel0c) set annotation: @abstract; fails
    Then relation(rel0c) get role(rol0c) set annotation: @abstract; fails
    Then relation(rel0a) get role(rol0a2) set annotation: @abstract; fails


  Scenario: Instances of abstract attribute types must not exist
    When create attribute type: att0a
    When attribute(att0a) set annotation: @independent
    When attribute(att0a) set annotation: @abstract
    When attribute(att0a) set value type: string
    When create attribute type: att0c
    When attribute(att0c) set annotation: @independent
    When attribute(att0c) set value type: string
    When transaction commits

    When connection open write transaction for database: typedb
    Then attribute(att0a) put instance with value: "att0a"; fails
    When $att0c = attribute(att0c) put instance with value: "att0c"
    Then transaction commits

    When connection open schema transaction for database: typedb
    Then attribute(att0c) set annotation: @abstract; fails


  Scenario: Attribute data is revalidated with set @regex
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
    When transaction commits

    When connection open write transaction for database: typedb
    When $attr1_val = attribute(attr1) put instance with value: "val"
    When $attr2_val1 = attribute(attr2) put instance with value: "val1"
    When transaction commits

    When connection open schema transaction for database: typedb
    Then attribute(attr0) set annotation: @regex("val\d+"); fails
    Then attribute(attr1) set annotation: @regex("val\d+"); fails
    When attribute(attr2) set annotation: @regex("val\d+")

    When transaction commits
    When connection open write transaction for database: typedb
    When $attr1_val = attribute(attr1) get instance with value: "val"
    When $attr2_val1 = attribute(attr2) get instance with value: "val1"
    Then attribute $attr1_val is none: false
    Then attribute $attr2_val1 is none: false
    Then attribute(attr2) get instances contain: $attr2_val1
    Then attribute(attr2) put instance with value: "val"; fails
    When delete attribute: $attr1_val
    When transaction commits

    When connection open schema transaction for database: typedb
    Then attribute(attr0) set annotation: @regex("val\d+")
    Then attribute(attr1) set annotation: @regex("val\d+")
    When attribute(attr1) unset annotation: @regex
    When attribute(attr2) unset annotation: @regex
    When transaction commits

    When connection open write transaction for database: typedb
    When $attr1_val = attribute(attr1) get instance with value: "val"
    When $attr2_val = attribute(attr2) get instance with value: "val"
    When $attr2_val1 = attribute(attr2) get instance with value: "val1"
    Then attribute $attr1_val is none: true
    Then attribute $attr2_val is none: true
    Then attribute $attr2_val1 is none: false
    Then attribute(attr2) get instances contain: $attr2_val1
    When attribute(attr1) put instance with value: "val"; fails
    When attribute(attr2) put instance with value: "val"; fails
    When $attr1_val22 = attribute(attr1) put instance with value: "val22"
    When $attr2_val22 = attribute(attr2) put instance with value: "val22"
    When transaction commits

    When connection open schema transaction for database: typedb
    When create attribute type: attr01
    When attribute(attr01) set annotation: @abstract
    When attribute(attr01) set annotation: @independent
    When attribute(attr01) set value type: string
    When attribute(attr1) set supertype: attr01
    When attribute(attr01) set annotation: @regex("val.*")
    When transaction commits

    When connection open write transaction for database: typedb
    When $attr1_val = attribute(attr1) put instance with value: "val"
    When transaction commits

    When connection open schema transaction for database: typedb
    Then attribute(attr1) set supertype: attr0; fails
    Then attribute(attr01) set annotation: @regex("val\d+"); fails
    Then attribute(attr1) set annotation: @regex("val\d+"); fails
    When transaction closes

    When connection open write transaction for database: typedb
    When $attr1_val = attribute(attr1) get instance with value: "val"
    Then delete attribute: $attr1_val
    When transaction commits

    When connection open schema transaction for database: typedb
    Then attribute(attr1) set supertype: attr0
    Then transaction commits


  Scenario: Attribute data is revalidated with set @range
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
    When transaction commits

    When connection open write transaction for database: typedb
    When $attr1_val = attribute(attr1) put instance with value: "val"
    When $attr2_val1 = attribute(attr2) put instance with value: "val1"
    When transaction commits

    When connection open schema transaction for database: typedb
    Then attribute(attr0) set annotation: @range("val1".."val9"); fails
    Then attribute(attr1) set annotation: @range("val1".."val9"); fails
    When attribute(attr2) set annotation: @range("val1".."val9")

    When transaction commits
    When connection open write transaction for database: typedb
    When $attr1_val = attribute(attr1) get instance with value: "val"
    When $attr2_val1 = attribute(attr2) get instance with value: "val1"
    Then attribute $attr1_val is none: false
    Then attribute $attr2_val1 is none: false
    Then attribute(attr2) get instances contain: $attr2_val1
    Then attribute(attr2) put instance with value: "val"; fails
    When delete attribute: $attr1_val
    When transaction commits

    When connection open schema transaction for database: typedb
    Then attribute(attr0) set annotation: @range("val1".."val9")
    Then attribute(attr1) set annotation: @range("val1".."val9")
    When attribute(attr1) unset annotation: @range
    When attribute(attr2) unset annotation: @range
    When transaction commits

    When connection open write transaction for database: typedb
    When $attr1_val = attribute(attr1) get instance with value: "val"
    When $attr2_val = attribute(attr2) get instance with value: "val"
    When $attr2_val1 = attribute(attr2) get instance with value: "val1"
    Then attribute $attr1_val is none: true
    Then attribute $attr2_val is none: true
    Then attribute $attr2_val1 is none: false
    Then attribute(attr2) get instances contain: $attr2_val1
    When attribute(attr1) put instance with value: "val"; fails
    When attribute(attr2) put instance with value: "val"; fails
    When $attr1_val22 = attribute(attr1) put instance with value: "val22"
    When $attr2_val22 = attribute(attr2) put instance with value: "val22"
    When transaction commits

    When connection open schema transaction for database: typedb
    When create attribute type: attr01
    When attribute(attr01) set annotation: @abstract
    When attribute(attr01) set annotation: @independent
    When attribute(attr01) set value type: string
    When attribute(attr1) set supertype: attr01
    When attribute(attr01) set annotation: @range("val".."val9999")
    When transaction commits

    When connection open write transaction for database: typedb
    When $attr1_val = attribute(attr1) put instance with value: "val"
    When transaction commits

    When connection open schema transaction for database: typedb
    Then attribute(attr1) set supertype: attr0; fails
    Then attribute(attr01) set annotation: @range("val1".."val9"); fails
    Then attribute(attr1) set annotation: @range("val1".."val9"); fails
    When transaction closes

    When connection open write transaction for database: typedb
    When $attr1_val = attribute(attr1) get instance with value: "val"
    Then delete attribute: $attr1_val
    When transaction commits

    When connection open schema transaction for database: typedb
    Then attribute(attr1) set supertype: attr0
    Then transaction commits


  Scenario: Attribute data is revalidated with set @values
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
    When transaction commits

    When connection open write transaction for database: typedb
    When $attr1_val = attribute(attr1) put instance with value: "val"
    When $attr2_val1 = attribute(attr2) put instance with value: "val1"
    When transaction commits

    When connection open schema transaction for database: typedb
    Then attribute(attr0) set annotation: @values("val1", "val22", "vall"); fails
    Then attribute(attr1) set annotation: @values("val1", "val22", "vall"); fails
    When attribute(attr2) set annotation: @values("val1", "val22", "vall")

    When transaction commits
    When connection open write transaction for database: typedb
    When $attr1_val = attribute(attr1) get instance with value: "val"
    When $attr2_val1 = attribute(attr2) get instance with value: "val1"
    Then attribute $attr1_val is none: false
    Then attribute $attr2_val1 is none: false
    Then attribute(attr2) get instances contain: $attr2_val1
    Then attribute(attr2) put instance with value: "val"; fails
    When delete attribute: $attr1_val
    When transaction commits

    When connection open schema transaction for database: typedb
    Then attribute(attr0) set annotation: @values("val1", "val22", "vall")
    Then attribute(attr1) set annotation: @values("val1", "val22", "vall")
    When attribute(attr1) unset annotation: @values
    When attribute(attr2) unset annotation: @values
    When transaction commits

    When connection open write transaction for database: typedb
    When $attr1_val = attribute(attr1) get instance with value: "val"
    When $attr2_val = attribute(attr2) get instance with value: "val"
    When $attr2_val1 = attribute(attr2) get instance with value: "val1"
    Then attribute $attr1_val is none: true
    Then attribute $attr2_val is none: true
    Then attribute $attr2_val1 is none: false
    Then attribute(attr2) get instances contain: $attr2_val1
    When attribute(attr1) put instance with value: "val"; fails
    When attribute(attr2) put instance with value: "val"; fails
    When $attr1_val22 = attribute(attr1) put instance with value: "val22"
    When $attr2_val22 = attribute(attr2) put instance with value: "val22"
    When transaction commits

    When connection open schema transaction for database: typedb
    When create attribute type: attr01
    When attribute(attr01) set annotation: @abstract
    When attribute(attr01) set annotation: @independent
    When attribute(attr01) set value type: string
    When attribute(attr1) set supertype: attr01
    When attribute(attr01) set annotation: @values("val", "vall", "val1", "val22", "val9")
    When transaction commits

    When connection open write transaction for database: typedb
    When $attr1_val = attribute(attr1) put instance with value: "val"
    When transaction commits

    When connection open schema transaction for database: typedb
    Then attribute(attr1) set supertype: attr0; fails
    Then attribute(attr01) set annotation: @values("val1", "val22", "vall"); fails
    Then attribute(attr1) set annotation: @values("val1", "val22", "vall"); fails
    When transaction closes

    When connection open write transaction for database: typedb
    When $attr1_val = attribute(attr1) get instance with value: "val"
    Then delete attribute: $attr1_val
    When transaction commits

    When connection open schema transaction for database: typedb
    Then attribute(attr1) set supertype: attr0
    Then transaction commits


  Scenario: Types can only commit keys if every instance owns a distinct key
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
    When entity(person) get owns(email) set annotation: @key
    Then transaction commits; fails with a message containing: "@card"
    When connection open schema transaction for database: typedb
    When entity(person) set owns: email
    Then transaction commits
    When connection open write transaction for database: typedb
    When $a = entity(person) get instance with key(username): alice
    When $alice = attribute(email) put instance with value: alice@typedb.com
    When entity $a set has: $alice
    When $b = entity(person) get instance with key(username): bob
    When $bob = attribute(email) put instance with value: bob@typedb.com
    When entity $b set has: $bob
    Then transaction commits
    When connection open schema transaction for database: typedb
    When entity(person) set owns: email
    When entity(person) get owns(email) set annotation: @key
    Then entity(person) get owns(email) get constraints contain: @unique
    Then entity(person) get owns(email) get constraints contain: @card(1..1)
    Then entity(person) get owns(email) is key: true
    Then entity(person) get owns(username) get constraints contain: @unique
    Then entity(person) get owns(username) get constraints contain: @card(1..1)
    Then entity(person) get owns(username) is key: true
    Then transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns(email) get constraints contain: @unique
    Then entity(person) get owns(email) get constraints contain: @card(1..1)
    Then entity(person) get owns(email) is key: true
    Then entity(person) get owns(username) get constraints contain: @unique
    Then entity(person) get owns(username) get constraints contain: @card(1..1)
    Then entity(person) get owns(username) is key: true


  Scenario: When the super-type of a type is changed, the data is consistent with the @key annotations on ownerships
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
    When entity(ent1n) set supertype: ent0k
    Then transaction commits; fails with a message containing: "@card"


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
    Then entity(ent0u) get owns(attr0) set annotation: @key; fails
    When entity(ent0u) get owns(attr0) unset annotation: @card
    Then transaction commits; fails with a message containing: "@card(0..1)"

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

    When connection open schema transaction for database: typedb
    When entity(ent0u) get owns(attr0) set annotation: @key
    Then transaction commits; fails with a message containing: "@card(1..1)"

    When connection open schema transaction for database: typedb
    When entity(ent0u) get owns(attr0) set annotation: @card(1..1)
    Then transaction commits; fails with a message containing: "@card(1..1)"


  Scenario: Owns data is validated to be unique for all siblings specialising an owns with @unique
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
    Given entity(ent2) set owns: attr2
    Given entity(ent2) set supertype: ent0
    Given entity(ent0) get owns(attr0) set annotation: @card(0..)
    Given entity(ent1) get owns(attr1) set annotation: @card(0..)
    Given entity(ent2) get owns(attr2) set annotation: @card(0..)
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


  Scenario: Owns data is validated to be unique if attribute type changes supertype and acquires @unique constraint
    Given create attribute type: attr0
    Given attribute(attr0) set value type: string
    Given attribute(attr0) set annotation: @abstract
    Given attribute(attr0) set annotation: @independent
    Given create attribute type: attr00
    Given attribute(attr00) set value type: string
    Given attribute(attr00) set annotation: @abstract
    Given attribute(attr00) set annotation: @independent
    Given create attribute type: attr1
    Given attribute(attr1) set supertype: attr0
    Given create attribute type: attr2
    Given attribute(attr2) set supertype: attr0
    Given create attribute type: ref
    Given attribute(ref) set value type: string
    Given create entity type: ent0
    Given entity(ent0) set owns: ref
    Given entity(ent0) set owns: attr0
    Given entity(ent0) get owns(attr0) set annotation: @card(0..)
    Given entity(ent0) set owns: attr00
    Given entity(ent0) get owns(attr00) set annotation: @card(0..)
    Given entity(ent0) get owns(attr00) set annotation: @unique
    Given create entity type: ent1
    Given entity(ent1) set supertype: ent0
    Given entity(ent1) set owns: attr1
    Given entity(ent1) set owns: attr2
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given $ent1 = entity(ent1) create new instance with key(ref): ent1
    Given $attr1 = attribute(attr1) put instance with value: "val1"
    Given $attr2 = attribute(attr2) put instance with value: "val1"
    Given entity $ent1 set has: $attr1
    Given entity $ent1 set has: $attr2
    Given transaction commits

    When connection open schema transaction for database: typedb
    When attribute(attr2) set supertype: attr00
    When attribute(attr1) set supertype: attr00
    Then transaction commits

    When connection open schema transaction for database: typedb
    When attribute(attr2) set supertype: attr0
    When attribute(attr1) set supertype: attr0
    When attribute(attr0) set supertype: attr00
    When attribute(attr0) unset value type
    When attribute(attr0) unset annotation: @independent
    Then transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent1) create new instance with key(ref): ent2
    When $attr1 = attribute(attr1) get instance with value: "val1"
    Then entity $ent2 set has: $attr1; fails
    When $attr2 = attribute(attr1) get instance with value: "val1"
    Then entity $ent2 set has: $attr2; fails
    When transaction closes

    When connection open schema transaction for database: typedb
    When attribute(attr0) set value type: string
    When attribute(attr0) set annotation: @independent
    When attribute(attr0) unset supertype
    Then transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent1) create new instance with key(ref): ent2
    When $attr1 = attribute(attr1) get instance with value: "val1"
    Then entity $ent2 set has: $attr1
    Then transaction commits

    When connection open schema transaction for database: typedb
    Then attribute(attr0) set supertype: attr00; fails
    Then attribute(attr1) set supertype: attr00; fails
    When attribute(attr2) set supertype: attr00
    Then transaction closes


  Scenario: Owns data is validated to be unique for all siblings specialising an owns with @key
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
    Given entity(ent2) set owns: attr2
    Given entity(ent2) set supertype: ent0
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
    When entity(ent0) get owns(attr0) set annotation: @key
    Then transaction commits; fails with a message containing: "@card"

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
    Then transaction commits; fails with a message containing: "@card"


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
    When entity(ent1) get owns(attr1) set annotation: @card(0..)
    When entity(ent1) set owns: attr2
    When entity(ent1) get owns(attr2) set annotation: @card(0..)
    When entity(ent1) set supertype: ent0
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
    When entity(ent0) get owns(attr01) set annotation: @card(0..)
    When attribute(attr0) set supertype: attr01
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent1 = entity(ent1) get instance with key(ref): ent1
    When $attr1_val = attribute(attr1) get instance with value: "val"
    Then entity $ent1 set has: $attr1_val; fails
    When transaction closes

    When connection open schema transaction for database: typedb
    Then entity(ent0) get owns(attr01) set annotation: @regex("val\d+\d+"); fails
    Then entity(ent1) get owns(attr1) set annotation: @regex("val\d+\d+\d+"); fails
    Then entity(ent1) get owns(attr1) set annotation: @regex("val\d+\d+")
    Then entity(ent1) get owns(attr2) set annotation: @regex("val\d+\d+"); fails
    When entity(ent1) get owns(attr2) set annotation: @regex("val\d*")
    When entity(ent1) get owns(attr1) unset annotation: @regex
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent1 = entity(ent1) get instance with key(ref): ent1
    When $attr1_val = attribute(attr1) get instance with value: "val"
    When $attr2_val = attribute(attr2) get instance with value: "val"
    Then entity $ent1 set has: $attr1_val; fails
    Then entity $ent1 set has: $attr2_val; fails
    When transaction closes

    When connection open schema transaction for database: typedb
    Then entity(ent1) get owns(attr2) set annotation: @regex("$val\d^"); fails
    Then entity(ent1) get owns(attr2) set annotation: @regex("val\d")
    When entity(ent0) get owns(attr0) unset annotation: @regex
    When entity(ent1) get owns(attr2) unset annotation: @regex
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent1 = entity(ent1) get instance with key(ref): ent1
    When $attr1_val = attribute(attr1) get instance with value: "val"
    When $attr2_val = attribute(attr2) get instance with value: "val"
    Then entity $ent1 set has: $attr1_val
    Then entity $ent1 set has: $attr2_val
    Then transaction commits

    When connection open schema transaction for database: typedb
    Then entity(ent1) get owns(attr2) set annotation: @regex("val\d"); fails
    Then entity(ent1) get owns(attr1) set annotation: @regex("val\d"); fails
    Then entity(ent0) get owns(attr0) set annotation: @regex("val\d"); fails
    Then entity(ent1) get owns(attr2) set annotation: @regex("val\d+"); fails
    Then entity(ent1) get owns(attr1) set annotation: @regex("val\d+"); fails
    Then entity(ent0) get owns(attr0) set annotation: @regex("val\d+"); fails
    Then entity(ent1) get owns(attr1) set annotation: @regex("$val\d*^"); fails
    Then entity(ent1) get owns(attr1) set annotation: @regex("val\d"); fails
    Then entity(ent1) get owns(attr2) set annotation: @regex("$val\d*^"); fails
    Then entity(ent1) get owns(attr2) set annotation: @regex("val\d"); fails
    Then entity(ent0) get owns(attr0) set annotation: @regex("$val\d*^"); fails
    Then entity(ent0) get owns(attr0) set annotation: @regex("val\d"); fails
    Then entity(ent1) get owns(attr1) set annotation: @regex("val\d*")
    Then entity(ent1) get owns(attr2) set annotation: @regex("val\d*")
    Then entity(ent0) get owns(attr0) set annotation: @regex("val\d*")
    When transaction closes

    When connection open write transaction for database: typedb
    When $ent1 = entity(ent1) get instance with key(ref): ent1
    When $attr1_val = attribute(attr1) get instance with value: "val"
    Then entity $ent1 unset has: $attr1_val
    Then transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent1) get owns(attr2) set annotation: @regex("val\d+"); fails
    When entity(ent0) get owns(attr0) set annotation: @regex("val\d+"); fails
    When entity(ent1) get owns(attr1) set annotation: @regex("val\d+")
    Then transaction commits


  Scenario: Owns data is validated if attribute type changes supertype and acquires @regex constraint
    Given create attribute type: attr0
    Given attribute(attr0) set value type: string
    Given attribute(attr0) set annotation: @abstract
    Given attribute(attr0) set annotation: @independent
    Given create attribute type: attr00
    Given attribute(attr00) set value type: string
    Given attribute(attr00) set annotation: @abstract
    Given attribute(attr00) set annotation: @independent
    Given create attribute type: attr1
    Given attribute(attr1) set supertype: attr0
    Given create attribute type: ref
    Given attribute(ref) set value type: string
    Given create entity type: ent0
    Given entity(ent0) set owns: ref
    Given entity(ent0) set owns: attr0
    Given entity(ent0) get owns(attr0) set annotation: @card(0..)
    Given entity(ent0) get owns(attr0) set annotation: @regex("val\d*")
    Given entity(ent0) set owns: attr00
    Given entity(ent0) get owns(attr00) set annotation: @card(0..)
    Given entity(ent0) get owns(attr00) set annotation: @regex("val\d+")
    Given create entity type: ent1
    Given entity(ent1) set supertype: ent0
    Given entity(ent1) set owns: attr1
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given $ent1 = entity(ent1) create new instance with key(ref): ent1
    Given $attr1 = attribute(attr1) put instance with value: "val"
    Given entity $ent1 set has: $attr1
    Given transaction commits

    When connection open schema transaction for database: typedb
    Then attribute(attr0) set supertype: attr00; fails
    Then attribute(attr1) set supertype: attr00; fails


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
    When entity(ent1) get owns(attr1) set annotation: @card(0..)
    When entity(ent1) set owns: attr2
    When entity(ent1) get owns(attr2) set annotation: @card(0..)
    When entity(ent1) set supertype: ent0
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent1 = entity(ent1) create new instance with key(ref): ent1
    When $attr1_val = attribute(attr1) put instance with value: "val"
    When $attr2_val1 = attribute(attr2) put instance with value: "val1"
    When entity $ent1 set has: $attr1_val
    When entity $ent1 set has: $attr2_val1
    When transaction commits

    When connection open schema transaction for database: typedb
    Then entity(ent0) get owns(attr0) set annotation: @range("val1".."val9"); fails with a message containing: "@range"
    Then entity(ent1) get owns(attr1) set annotation: @range("val1".."val9"); fails with a message containing: "@range"
    When entity(ent1) get owns(attr2) set annotation: @range("val1".."val9")

    When transaction commits
    When connection open write transaction for database: typedb
    When $ent1 = entity(ent1) get instance with key(ref): ent1
    When $attr1_val = attribute(attr1) get instance with value: "val"
    When $attr2_val1 = attribute(attr2) get instance with value: "val1"
    Then entity $ent1 get has contain: $attr1_val
    Then entity $ent1 get has contain: $attr2_val1
    When $attr2_val = attribute(attr2) put instance with value: "val"
    Then entity $ent1 set has: $attr2_val; fails with a message containing: "@range"
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
    Then entity $ent1 set has: $attr1_val; fails with a message containing: "@range"
    Then entity $ent1 set has: $attr2_val; fails with a message containing: "@range"
    When $attr1_val22 = attribute(attr1) put instance with value: "val22"
    When $attr2_val22 = attribute(attr2) put instance with value: "val22"
    Then entity $ent1 set has: $attr1_val22
    Then entity $ent1 set has: $attr2_val22
    When transaction commits

    When connection open schema transaction for database: typedb
    When create attribute type: attr01
    When attribute(attr01) set annotation: @abstract
    When attribute(attr01) set value type: string
    When entity(ent0) set owns: attr01
    When entity(ent0) get owns(attr01) set annotation: @card(0..)
    When entity(ent0) get owns(attr01) set annotation: @range("val23".."val9999")
    Then attribute(attr0) set supertype: attr01; fails with a message containing: "@range"
    When entity(ent0) get owns(attr01) unset annotation: @range
    Then attribute(attr0) set supertype: attr01
    When entity(ent0) get owns(attr01) set annotation: @range("val23".."val9999"); fails with a message containing: "@range"
    When entity(ent0) get owns(attr01) set annotation: @range("val".."val9999")
    When attribute(attr0) set supertype: attr01
    When attribute(attr0) unset value type
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent1 = entity(ent1) get instance with key(ref): ent1
    When $attr1_val = attribute(attr1) get instance with value: "val"
    Then entity $ent1 set has: $attr1_val; fails with a message containing: "@range"
    When transaction closes

    When connection open schema transaction for database: typedb
    When entity(ent0) get owns(attr0) unset annotation: @range
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent1 = entity(ent1) get instance with key(ref): ent1
    When $attr1_val = attribute(attr1) get instance with value: "val"
    Then entity $ent1 set has: $attr1_val
    When transaction commits

    When connection open schema transaction for database: typedb
    Then entity(ent0) get owns(attr01) set annotation: @range("val1".."val9"); fails with a message containing: "@range"
    Then entity(ent1) get owns(attr1) set annotation: @range("val1".."val9"); fails with a message containing: "@range"
    When transaction closes

    When connection open write transaction for database: typedb
    When $ent1 = entity(ent1) get instance with key(ref): ent1
    When $attr1_val = attribute(attr1) get instance with value: "val"
    Then entity $ent1 unset has: $attr1_val
    Then transaction commits


  Scenario: Owns data is validated if attribute type changes supertype and acquires @range constraint
    Given create attribute type: attr0
    Given attribute(attr0) set value type: string
    Given attribute(attr0) set annotation: @abstract
    Given attribute(attr0) set annotation: @independent
    Given create attribute type: attr00
    Given attribute(attr00) set value type: string
    Given attribute(attr00) set annotation: @abstract
    Given attribute(attr00) set annotation: @independent
    Given create attribute type: attr1
    Given attribute(attr1) set supertype: attr0
    Given create attribute type: ref
    Given attribute(ref) set value type: string
    Given create entity type: ent0
    Given entity(ent0) set owns: ref
    Given entity(ent0) set owns: attr0
    Given entity(ent0) get owns(attr0) set annotation: @card(0..)
    Given entity(ent0) get owns(attr0) set annotation: @range("A".."Z")
    Given entity(ent0) set owns: attr00
    Given entity(ent0) get owns(attr00) set annotation: @card(0..)
    Given entity(ent0) get owns(attr00) set annotation: @range("a".."z")
    Given create entity type: ent1
    Given entity(ent1) set supertype: ent0
    Given entity(ent1) set owns: attr1
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given $ent1 = entity(ent1) create new instance with key(ref): ent1
    Given $attr1 = attribute(attr1) put instance with value: "G"
    Given entity $ent1 set has: $attr1
    Given transaction commits

    When connection open schema transaction for database: typedb
    Then attribute(attr0) set supertype: attr00; fails with a message containing: "@range"
    Then attribute(attr1) set supertype: attr00; fails with a message containing: "@range"


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
    When entity(ent1) get owns(attr1) set annotation: @card(0..)
    When entity(ent1) set owns: attr2
    When entity(ent1) get owns(attr2) set annotation: @card(0..)
    When entity(ent1) set supertype: ent0
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent1 = entity(ent1) create new instance with key(ref): ent1
    When $attr1_val = attribute(attr1) put instance with value: "val"
    When $attr2_val1 = attribute(attr2) put instance with value: "val1"
    When entity $ent1 set has: $attr1_val
    When entity $ent1 set has: $attr2_val1
    When transaction commits

    When connection open schema transaction for database: typedb
    Then entity(ent0) get owns(attr0) set annotation: @values("val5", "val1", "val8"); fails with a message containing: "@values"
    Then entity(ent1) get owns(attr1) set annotation: @values("val5", "val1", "val8"); fails with a message containing: "@values"
    When entity(ent1) get owns(attr2) set annotation: @values("val5", "val1", "val8")

    When transaction commits
    When connection open write transaction for database: typedb
    When $ent1 = entity(ent1) get instance with key(ref): ent1
    When $attr1_val = attribute(attr1) get instance with value: "val"
    When $attr2_val1 = attribute(attr2) get instance with value: "val1"
    Then entity $ent1 get has contain: $attr1_val
    Then entity $ent1 get has contain: $attr2_val1
    When $attr2_val = attribute(attr2) put instance with value: "val"
    Then entity $ent1 set has: $attr2_val; fails with a message containing: "@values"
    When entity $ent1 unset has: $attr1_val
    Then entity $ent1 get has do not contain: $attr1_val
    When transaction commits

    When connection open schema transaction for database: typedb
    Then entity(ent0) get owns(attr0) set annotation: @values("val5", "val1", "val8", "val2", "val22")
    Then entity(ent1) get owns(attr1) set annotation: @values("val5", "val1", "val8", "val2", "val22")
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
    Then entity $ent1 set has: $attr1_val; fails with a message containing: "@values"
    Then entity $ent1 set has: $attr2_val; fails with a message containing: "@values"
    When $attr1_val22 = attribute(attr1) put instance with value: "val22"
    When $attr2_val22 = attribute(attr2) put instance with value: "val22"
    Then entity $ent1 set has: $attr1_val22
    Then entity $ent1 set has: $attr2_val22
    When transaction commits

    When connection open schema transaction for database: typedb
    When create attribute type: attr01
    When attribute(attr01) set annotation: @abstract
    When attribute(attr01) set value type: string
    When entity(ent0) set owns: attr01
    When entity(ent0) get owns(attr01) set annotation: @card(0..)
    When entity(ent0) get owns(attr01) set annotation: @values("val1", "val", "val1237")
    Then attribute(attr0) set supertype: attr01; fails with a message containing: "@values"
    When entity(ent0) get owns(attr01) unset annotation: @values
    Then attribute(attr0) set supertype: attr01
    When entity(ent0) get owns(attr01) set annotation: @values("val1", "val", "val1237"); fails with a message containing: "@values"
    When entity(ent0) get owns(attr01) set annotation: @values("val22", "val", "val1")
    When attribute(attr0) set supertype: attr01
    When attribute(attr0) unset value type
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent1 = entity(ent1) get instance with key(ref): ent1
    When $attr1_val = attribute(attr1) get instance with value: "val"
    Then entity $ent1 set has: $attr1_val; fails with a message containing: "@values"
    When transaction closes

    When connection open schema transaction for database: typedb
    When entity(ent0) get owns(attr0) unset annotation: @values
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent1 = entity(ent1) get instance with key(ref): ent1
    When $attr1_val = attribute(attr1) get instance with value: "val"
    Then entity $ent1 set has: $attr1_val
    When transaction commits

    When connection open schema transaction for database: typedb
    Then entity(ent0) get owns(attr01) set annotation: @values("val5", "val1", "val8"); fails with a message containing: "@values"
    Then entity(ent1) get owns(attr1) set annotation: @values("val5", "val1", "val8"); fails with a message containing: "@values"
    When transaction closes

    When connection open write transaction for database: typedb
    When $ent1 = entity(ent1) get instance with key(ref): ent1
    When $attr1_val = attribute(attr1) get instance with value: "val"
    Then entity $ent1 unset has: $attr1_val
    Then transaction commits


  Scenario: Owns data is validated if attribute type changes supertype and acquires @values constraint
    Given create attribute type: attr0
    Given attribute(attr0) set value type: string
    Given attribute(attr0) set annotation: @abstract
    Given attribute(attr0) set annotation: @independent
    Given create attribute type: attr00
    Given attribute(attr00) set value type: string
    Given attribute(attr00) set annotation: @abstract
    Given attribute(attr00) set annotation: @independent
    Given create attribute type: attr1
    Given attribute(attr1) set supertype: attr0
    Given create attribute type: ref
    Given attribute(ref) set value type: string
    Given create entity type: ent0
    Given entity(ent0) set owns: ref
    Given entity(ent0) set owns: attr0
    Given entity(ent0) get owns(attr0) set annotation: @card(0..)
    Given entity(ent0) get owns(attr0) set annotation: @values("this value", "another value")
    Given entity(ent0) set owns: attr00
    Given entity(ent0) get owns(attr00) set annotation: @card(0..)
    Given entity(ent0) get owns(attr00) set annotation: @values("a different value", "another value")
    Given create entity type: ent1
    Given entity(ent1) set supertype: ent0
    Given entity(ent1) set owns: attr1
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given $ent1 = entity(ent1) create new instance with key(ref): ent1
    Given $attr1 = attribute(attr1) put instance with value: "this value"
    Given entity $ent1 set has: $attr1
    Given transaction commits

    When connection open schema transaction for database: typedb
    Then attribute(attr0) set supertype: attr00; fails with a message containing: "@values"
    Then attribute(attr1) set supertype: attr00; fails with a message containing: "@values"


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
    Then entity(ent0n) get owns(attr0) set annotation: @unique; fails with a message containing: "unique"

    When transaction closes
    Given connection open schema transaction for database: typedb
    Then entity(ent0u) get owns(attr0) set annotation: @key; fails with a message containing: "key"
    When entity(ent0u) get owns(attr0) unset annotation: @card
    Then transaction commits; fails with a message containing: "@card"

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

    When connection open schema transaction for database: typedb
    When entity(ent0u) get owns(attr0) set annotation: @key
    Then transaction commits; fails with a message containing: "@card(1..1)"

    When connection open schema transaction for database: typedb
    When entity(ent0u) get owns(attr0) set annotation: @card(1..1)
    Then transaction commits; fails with a message containing: "@card(1..1)"


  Scenario: Owns data is revalidated with set @distinct
    When create attribute type: attr0
    When attribute(attr0) set value type: string
    When attribute(attr0) set annotation: @abstract
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
    When entity(ent0) set owns: attr0[]
    When entity(ent1) set owns: attr1[]
    When entity(ent1) set owns: attr2[]
    When entity(ent1) set supertype: ent0
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent1 = entity(ent1) create new instance with key(ref): ent1
    When $attr1_val = attribute(attr1) put instance with value: "val"
    When $attr2_val = attribute(attr2) put instance with value: "val"
    When entity $ent1 set has(attr1[]): [$attr1_val, $attr1_val]
    When entity $ent1 set has(attr2[]): [$attr2_val]
    When transaction commits

    When connection open schema transaction for database: typedb
    Then entity(ent0) get owns(attr0) set annotation: @distinct; fails
    Then entity(ent1) get owns(attr1) set annotation: @distinct; fails
    When entity(ent1) get owns(attr2) set annotation: @distinct
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent1 = entity(ent1) get instance with key(ref): ent1
    When $attr1_val = attribute(attr1) get instance with value: "val"
    When $attr2_val = attribute(attr2) get instance with value: "val"
    Then entity $ent1 get has contain: $attr1_val
    Then entity $ent1 get has contain: $attr2_val
    Then entity $ent1 get has(attr1[]) is [$attr1_val, $attr1_val]: true
    Then entity $ent1 get has(attr1[]) is [$attr1_val]: false
    Then entity $ent1 get has(attr2[]) is [$attr2_val, $attr2_val]: false
    Then entity $ent1 get has(attr2[]) is [$attr2_val]: true
    Then entity $ent1 set has(attr2[]): [$attr2_val, $attr2_val]; fails
    When entity $ent1 set has(attr1[]): [$attr1_val]
    Then entity $ent1 get has contain: $attr1_val
    Then entity $ent1 get has contain: $attr2_val
    When transaction commits

    When connection open schema transaction for database: typedb
    Then entity(ent0) get owns(attr0) set annotation: @distinct
    Then entity(ent1) get owns(attr1) set annotation: @distinct
    When entity(ent1) get owns(attr1) unset annotation: @distinct
    When entity(ent1) get owns(attr2) unset annotation: @distinct
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent1 = entity(ent1) get instance with key(ref): ent1
    When $attr1_val = attribute(attr1) get instance with value: "val"
    When $attr2_val = attribute(attr2) get instance with value: "val"
    Then entity $ent1 get has contain: $attr1_val
    Then entity $ent1 get has contain: $attr2_val
    Then entity $ent1 get has(attr1[]) is [$attr1_val]: true
    Then entity $ent1 get has(attr2[]) is [$attr2_val]: true
    Then entity $ent1 set has(attr1[]): [$attr1_val, $attr1_val]; fails
    Then entity $ent1 set has(attr2[]): [$attr2_val, $attr2_val]; fails
    When transaction closes

    When connection open schema transaction for database: typedb
    When create attribute type: attr01
    When attribute(attr01) set annotation: @abstract
    When attribute(attr01) set value type: string
    When attribute(attr0) set supertype: attr01
    When attribute(attr0) unset value type
    When entity(ent0) set owns: attr01[]
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent1 = entity(ent1) get instance with key(ref): ent1
    When $attr1_val = attribute(attr1) get instance with value: "val"
    When $attr2_val = attribute(attr2) get instance with value: "val"
    When entity $ent1 set has(attr1[]): [$attr1_val, $attr1_val]; fails
    Then entity $ent1 set has(attr2[]): [$attr2_val, $attr2_val]; fails
    Then entity $ent1 get has(attr1[]) is [$attr1_val, $attr1_val]: false
    Then entity $ent1 get has(attr1[]) is [$attr1_val]: true
    Then entity $ent1 get has(attr2[]) is [$attr2_val]: true
    When transaction closes

    When connection open schema transaction for database: typedb
    When entity(ent0) get owns(attr0) unset annotation: @distinct
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent1 = entity(ent1) get instance with key(ref): ent1
    When $attr1_val = attribute(attr1) get instance with value: "val"
    When entity $ent1 set has(attr1[]): [$attr1_val, $attr1_val]
    Then entity $ent1 get has(attr1[]) is [$attr1_val, $attr1_val]: true
    Then entity $ent1 get has(attr1[]) is [$attr1_val]: false
    When transaction commits

    When connection open schema transaction for database: typedb
    Then entity(ent0) get owns(attr01) set annotation: @distinct; fails
    Then entity(ent0) get owns(attr0) set annotation: @distinct; fails
    Then entity(ent1) get owns(attr1) set annotation: @distinct; fails
    Then entity(ent1) get owns(attr2) set annotation: @distinct
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent1 = entity(ent1) get instance with key(ref): ent1
    When $attr1_val = attribute(attr1) get instance with value: "val"
    When entity $ent1 set has(attr1[]): [$attr1_val]
    Then entity $ent1 get has(attr1[]) is [$attr1_val]: true
    Then transaction commits


  Scenario: Relates data is revalidated with set @distinct
    When create attribute type: ref
    When attribute(ref) set value type: string
    When create relation type: rel0
    When relation(rel0) set owns: ref
    When relation(rel0) create role: rol0
    When relation(rel0) set annotation: @abstract
    When relation(rel0) get role(rol0) set annotation: @abstract
    When relation(rel0) get role(rol0) set ordering: ordered
    When create relation type: rel1
    When relation(rel1) set supertype: rel0
    When relation(rel1) create role: rol1
    When relation(rel1) get role(rol1) set ordering: ordered
    When relation(rel1) get role(rol1) set specialise: rel0:rol0
    When relation(rel1) create role: rol2
    When relation(rel1) get role(rol2) set ordering: ordered
    When relation(rel1) get role(rol2) set specialise: rel0:rol0
    When create entity type: ent0
    When create entity type: ent1
    When entity(ent0) set annotation: @abstract
    When entity(ent0) set owns: ref
    When entity(ent0) set plays: rel0:rol0
    When entity(ent1) set plays: rel1:rol1
    When entity(ent1) set plays: rel1:rol2
    When entity(ent1) set supertype: ent0
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent1 = entity(ent1) create new instance with key(ref): ent1
    When $rel1 = relation(rel1) create new instance with key(ref): rel
    When relation $rel1 set players for role(rol1[]): [$ent1, $ent1]
    When relation $rel1 set players for role(rol2[]): [$ent1]
    When transaction commits

    When connection open schema transaction for database: typedb
    Then relation(rel0) get role(rol0) set annotation: @distinct; fails
    Then relation(rel1) get role(rol1) set annotation: @distinct; fails
    When relation(rel1) get role(rol2) set annotation: @distinct
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent1 = entity(ent1) get instance with key(ref): ent1
    When $rel1 = relation(rel1) get instance with key(ref): rel
    Then relation $rel1 get players contain: $ent1
    Then relation $rel1 get players contain: $ent1
    Then relation $rel1 get players for role(rol1[]) is [$ent1, $ent1]: true
    Then relation $rel1 get players for role(rol1[]) is [$ent1]: false
    Then relation $rel1 get players for role(rol2[]) is [$ent1, $ent1]: false
    Then relation $rel1 get players for role(rol2[]) is [$ent1]: true
    Then relation $rel1 set players for role(rol2[]): [$ent1, $ent1]; fails
    When relation $rel1 set players for role(rol1[]): [$ent1]
    Then relation $rel1 get players contain: $ent1
    Then relation $rel1 get players contain: $ent1
    When transaction commits

    When connection open schema transaction for database: typedb
    When relation(rel0) get role(rol0) set annotation: @distinct
    When relation(rel1) get role(rol1) set annotation: @distinct
    When relation(rel1) get role(rol1) unset annotation: @distinct
    When relation(rel1) get role(rol2) unset annotation: @distinct
    When transaction commits

    When connection open read transaction for database: typedb
    When $ent1 = entity(ent1) get instance with key(ref): ent1
    When $rel1 = relation(rel1) get instance with key(ref): rel
    Then relation $rel1 get players contain: $ent1
    Then relation $rel1 get players contain: $ent1
    Then relation $rel1 get players for role(rol1[]) is [$ent1]: true
    Then relation $rel1 get players for role(rol2[]) is [$ent1]: true
    Then relation $rel1 get players for role(rol1[]) is [$ent1, $ent1]: false
    Then relation $rel1 get players for role(rol2[]) is [$ent1, $ent1]: false
    When transaction closes

    When connection open schema transaction for database: typedb
    When create relation type: rel01
    When relation(rel01) set owns: ref
    When relation(rel01) create role: rol01
    When relation(rel01) set annotation: @abstract
    When relation(rel01) get role(rol01) set annotation: @abstract
    When relation(rel01) get role(rol01) set ordering: ordered
    When relation(rel0) set supertype: rel01
    When relation(rel0) unset owns: ref
    When relation(rel1) get role(rol1) set specialise: rel01:rol01
    When entity(ent0) set plays: rel01:rol01
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent1 = entity(ent1) get instance with key(ref): ent1
    When $rel1 = relation(rel1) get instance with key(ref): rel
    When relation $rel1 set players for role(rol1[]): [$ent1, $ent1]
    Then relation $rel1 set players for role(rol2[]): [$ent1, $ent1]; fails
    Then relation $rel1 get players for role(rol1[]) is [$ent1, $ent1]: true
    Then relation $rel1 get players for role(rol2[]) is [$ent1]: true
    When transaction commits

    When connection open schema transaction for database: typedb
    Then relation(rel1) get role(rol1) set specialise: rol0; fails
    Then relation(rel1) get role(rol1) set specialise: rol0; fails
    Then relation(rel01) get role(rol01) set annotation: @distinct; fails
    Then relation(rel1) get role(rol1) set annotation: @distinct; fails
    When transaction closes

    When connection open write transaction for database: typedb
    When $ent1 = entity(ent1) get instance with key(ref): ent1
    When $rel1 = relation(rel1) get instance with key(ref): rel
    When relation $rel1 set players for role(rol1[]): [$ent1]
    Then relation $rel1 get players for role(rol1[]) is [$ent1]: true
    When transaction commits

    When connection open schema transaction for database: typedb
    Then relation(rel1) get role(rol1) set specialise: rol0
    Then transaction commits


  Scenario: Owns data is revalidated when new cardinality constraints appear
    # Setup

    When create attribute type: ref
    When attribute(ref) set value type: string
    When create attribute type: attr00
    When attribute(attr00) set value type: string
    When attribute(attr00) set annotation: @abstract
    When attribute(attr00) set annotation: @independent
    When create attribute type: attr0
    When attribute(attr0) set value type: string
    When attribute(attr0) set annotation: @abstract
    When attribute(attr0) set annotation: @independent
    When create attribute type: attr1
    When attribute(attr1) set supertype: attr0
    When create entity type: ent0
    When entity(ent0) set owns: ref
    When entity(ent0) get owns(ref) set annotation: @key
    When create entity type: ent1
    When create entity type: ent2
    When entity(ent1) set supertype: ent0
    When entity(ent2) set supertype: ent1
    When entity(ent0) set owns: attr0
    When entity(ent1) set owns: attr1
    Then entity(ent2) get constraints for owned attribute(attr1) contain: @card(0..1)
    When transaction commits

    # Direct cardinality changes validation

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) create new instance with key(ref): ent2
    When transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent1) get owns(attr1) set annotation: @card(1..)
    Then transaction commits; fails with a message containing: "@card(1..)"

    When connection open schema transaction for database: typedb
    When entity(ent1) get owns(attr1) set annotation: @card(1..1)
    Then transaction commits; fails with a message containing: "@card(1..1)"

    When connection open schema transaction for database: typedb
    When entity(ent0) get owns(attr0) set annotation: @card(1..)
    Then transaction commits; fails with a message containing: "@card(1..)"

    When connection open schema transaction for database: typedb
    When entity(ent0) get owns(attr0) set annotation: @card(1..1)
    Then transaction commits; fails with a message containing: "@card(1..1)"

    When connection open schema transaction for database: typedb
    Then entity(ent2) get constraints for owned attribute(attr1) contain: @card(0..1)
    Then entity(ent2) get constraints for owned attribute(attr1) do not contain: @card(1..1)
    When transaction closes

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $attr1_1 = attribute(attr1) put instance with value: "attr1_1"
    When $attr1_2 = attribute(attr1) put instance with value: "attr1_2"
    When entity $ent2 set has: $attr1_1
    When entity $ent2 set has: $attr1_2
    Then transaction commits; fails with a message containing: "@card"

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $attr1_1 = attribute(attr1) put instance with value: "attr1_1"
    When entity $ent2 set has: $attr1_1
    When transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent0) get owns(attr0) set annotation: @card(1..)
    When entity(ent0) get owns(attr0) set annotation: @card(1..1)
    When entity(ent1) get owns(attr1) set annotation: @card(1..1)
    When entity(ent1) get owns(attr1) set annotation: @card(1..)
    Then entity(ent2) get constraints for owned attribute(attr0) do not contain: @card(0..1)
    Then entity(ent2) get constraints for owned attribute(attr0) contain: @card(1..1)
    Then entity(ent2) get constraints for owned attribute(attr0) do not contain: @card(1..)
    Then entity(ent2) get constraints for owned attribute(attr1) do not contain: @card(0..1)
    Then entity(ent2) get constraints for owned attribute(attr1) contain: @card(1..1)
    Then entity(ent2) get constraints for owned attribute(attr1) contain: @card(1..)
    When entity(ent1) get owns(attr1) unset annotation: @card
    Then entity(ent2) get constraints for owned attribute(attr0) do not contain: @card(0..1)
    Then entity(ent2) get constraints for owned attribute(attr0) contain: @card(1..1)
    Then entity(ent2) get constraints for owned attribute(attr0) do not contain: @card(1..)
    Then entity(ent2) get constraints for owned attribute(attr1) contain: @card(0..1)
    Then entity(ent2) get constraints for owned attribute(attr1) contain: @card(1..1)
    Then entity(ent2) get constraints for owned attribute(attr1) do not contain: @card(1..)
    Then transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent0) get owns(attr0) set annotation: @card(2..3)
    Then transaction commits; fails with a message containing: "@card(2..3)"

    When connection open schema transaction for database: typedb
    When entity(ent0) get owns(attr0) set annotation: @card(1..3)
    When entity(ent1) get owns(attr1) set annotation: @card(1..2)
    Then entity(ent2) get constraints for owned attribute(attr0) contain: @card(1..3)
    Then entity(ent2) get constraints for owned attribute(attr0) do not contain: @card(1..2)
    Then entity(ent2) get constraints for owned attribute(attr1) contain: @card(1..3)
    Then entity(ent2) get constraints for owned attribute(attr1) contain: @card(1..2)
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $attr1_2 = attribute(attr1) put instance with value: "attr1_2"
    When entity $ent2 set has: $attr1_2
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $attr1_3 = attribute(attr1) put instance with value: "attr1_3"
    When entity $ent2 set has: $attr1_3
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent0) get owns(attr0) set annotation: @card(1..2)
    When entity(ent1) get owns(attr1) set annotation: @card(1..3)
    Then entity(ent2) get constraints for owned attribute(attr0) contain: @card(1..2)
    Then entity(ent2) get constraints for owned attribute(attr0) do not contain: @card(1..3)
    Then entity(ent2) get constraints for owned attribute(attr1) contain: @card(1..2)
    Then entity(ent2) get constraints for owned attribute(attr1) contain: @card(1..3)
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $attr1_3 = attribute(attr1) put instance with value: "attr1_3"
    When entity $ent2 set has: $attr1_3
    Then transaction commits; fails with a message containing: "@card"

    # Default cardinality effect validation
    # Set sibling capability effect validation

    When connection open schema transaction for database: typedb
    When entity(ent1) get owns(attr1) unset annotation: @card
    Then transaction commits; fails with a message containing: "@card(0..1)"

    When connection open schema transaction for database: typedb
    When create attribute type: attr2
    When attribute(attr2) set value type: string
    When entity(ent2) set owns: attr2
    When entity(ent2) get owns(attr2) set annotation: @card(1..)
    Then transaction commits; fails with a message containing: "@card(1..)"

    When connection open schema transaction for database: typedb
    When create attribute type: attr2
    When entity(ent2) set owns: attr2
    When attribute(attr2) set supertype: attr0
    When entity(ent0) get owns(attr0) set annotation: @card(0..1)
    Then transaction commits; fails with a message containing: "@card(0..1)"

    When connection open schema transaction for database: typedb
    When create attribute type: attr2
    When entity(ent2) set owns: attr2
    When attribute(attr2) set supertype: attr0
    When entity(ent0) get owns(attr0) set annotation: @card(0..2)
    Then entity(ent2) get constraints for owned attribute(attr0) contain: @card(0..2)
    Then entity(ent2) get constraints for owned attribute(attr0) do not contain: @card(1..3)
    Then entity(ent2) get constraints for owned attribute(attr0) do not contain: @card(0..1)
    Then entity(ent2) get constraints for owned attribute(attr1) contain: @card(0..2)
    Then entity(ent2) get constraints for owned attribute(attr1) contain: @card(1..3)
    Then entity(ent2) get constraints for owned attribute(attr1) do not contain: @card(0..1)
    Then entity(ent2) get constraints for owned attribute(attr2) contain: @card(0..2)
    Then entity(ent2) get constraints for owned attribute(attr2) do not contain: @card(1..3)
    Then entity(ent2) get constraints for owned attribute(attr2) contain: @card(0..1)
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $attr2_1 = attribute(attr2) put instance with value: "attr2_1"
    When entity $ent2 set has: $attr2_1
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent0) get owns(attr0) set annotation: @card(2..3)
    When entity(ent0) get owns(attr0) set annotation: @card(1..3)
    When entity(ent0) get owns(attr0) set annotation: @card(0..3)
    When entity(ent1) get owns(attr1) set annotation: @card(2..2)
    When entity(ent1) get owns(attr1) set annotation: @card(1..2)
    Then entity(ent2) get constraints for owned attribute(attr0) contain: @card(0..3)
    Then entity(ent2) get constraints for owned attribute(attr0) do not contain: @card(1..2)
    Then entity(ent2) get constraints for owned attribute(attr0) do not contain: @card(0..1)
    Then entity(ent2) get constraints for owned attribute(attr1) contain: @card(0..3)
    Then entity(ent2) get constraints for owned attribute(attr1) contain: @card(1..2)
    Then entity(ent2) get constraints for owned attribute(attr1) do not contain: @card(0..1)
    Then entity(ent2) get constraints for owned attribute(attr2) contain: @card(0..3)
    Then entity(ent2) get constraints for owned attribute(attr2) do not contain: @card(1..2)
    Then entity(ent2) get constraints for owned attribute(attr2) contain: @card(0..1)
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $attr2_1 = attribute(attr2) put instance with value: "attr2_1"
    When entity $ent2 set has: $attr2_1
    Then transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent0) get owns(attr0) set annotation: @card(2..3)
    When entity(ent0) get owns(attr0) set annotation: @card(1..3)
    Then entity(ent2) get constraints for owned attribute(attr0) contain: @card(1..3)
    Then entity(ent2) get constraints for owned attribute(attr0) do not contain: @card(1..2)
    Then entity(ent2) get constraints for owned attribute(attr0) do not contain: @card(0..1)
    Then entity(ent2) get constraints for owned attribute(attr1) contain: @card(1..3)
    Then entity(ent2) get constraints for owned attribute(attr1) contain: @card(1..2)
    Then entity(ent2) get constraints for owned attribute(attr1) do not contain: @card(0..1)
    Then entity(ent2) get constraints for owned attribute(attr2) contain: @card(1..3)
    Then entity(ent2) get constraints for owned attribute(attr2) do not contain: @card(1..2)
    Then entity(ent2) get constraints for owned attribute(attr2) contain: @card(0..1)
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $attr2_2 = attribute(attr2) put instance with value: "attr2_2"
    When entity $ent2 set has: $attr2_2
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent2) get owns(attr2) set annotation: @card(1..10)
    Then entity(ent2) get constraints for owned attribute(attr0) contain: @card(1..3)
    Then entity(ent2) get constraints for owned attribute(attr0) do not contain: @card(1..2)
    Then entity(ent2) get constraints for owned attribute(attr0) do not contain: @card(1..10)
    Then entity(ent2) get constraints for owned attribute(attr1) contain: @card(1..3)
    Then entity(ent2) get constraints for owned attribute(attr1) contain: @card(1..2)
    Then entity(ent2) get constraints for owned attribute(attr1) do not contain: @card(1..10)
    Then entity(ent2) get constraints for owned attribute(attr2) contain: @card(1..3)
    Then entity(ent2) get constraints for owned attribute(attr2) do not contain: @card(1..2)
    Then entity(ent2) get constraints for owned attribute(attr2) contain: @card(1..10)
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $attr2_2 = attribute(attr2) put instance with value: "attr2_2"
    When entity $ent2 set has: $attr2_2
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent0) get owns(attr0) set annotation: @card(2..4)
    When entity(ent0) get owns(attr0) set annotation: @card(1..4)
    Then entity(ent2) get constraints for owned attribute(attr0) contain: @card(1..4)
    Then entity(ent2) get constraints for owned attribute(attr0) do not contain: @card(1..2)
    Then entity(ent2) get constraints for owned attribute(attr0) do not contain: @card(1..10)
    Then entity(ent2) get constraints for owned attribute(attr1) contain: @card(1..4)
    Then entity(ent2) get constraints for owned attribute(attr1) contain: @card(1..2)
    Then entity(ent2) get constraints for owned attribute(attr1) do not contain: @card(1..10)
    Then entity(ent2) get constraints for owned attribute(attr2) contain: @card(1..4)
    Then entity(ent2) get constraints for owned attribute(attr2) do not contain: @card(1..2)
    Then entity(ent2) get constraints for owned attribute(attr2) contain: @card(1..10)
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $attr2_2 = attribute(attr2) put instance with value: "attr2_2"
    When entity $ent2 set has: $attr2_2
    Then transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $attr1_2 = attribute(attr1) get instance with value: "attr1_2"
    When entity $ent2 unset has: $attr1_2
    When $attr2_1 = attribute(attr2) get instance with value: "attr2_1"
    When entity $ent2 unset has: $attr2_1
    Then transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $attr1_1 = attribute(attr1) get instance with value: "attr1_1"
    When entity $ent2 unset has: $attr1_1
    Then transaction commits; fails with a message containing: "@card"

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $attr2_2 = attribute(attr2) get instance with value: "attr2_2"
    When entity $ent2 unset has: $attr2_2
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent2) get owns(attr2) set annotation: @card(0..)
    Then entity(ent2) get constraints for owned attribute(attr0) contain: @card(1..4)
    Then entity(ent2) get constraints for owned attribute(attr0) do not contain: @card(1..2)
    Then entity(ent2) get constraints for owned attribute(attr0) do not contain: @card(0..)
    Then entity(ent2) get constraints for owned attribute(attr0) do not contain: @card(0..1)
    Then entity(ent2) get constraints for owned attribute(attr1) contain: @card(1..4)
    Then entity(ent2) get constraints for owned attribute(attr1) contain: @card(1..2)
    Then entity(ent2) get constraints for owned attribute(attr1) do not contain: @card(0..)
    Then entity(ent2) get constraints for owned attribute(attr1) do not contain: @card(0..1)
    Then entity(ent2) get constraints for owned attribute(attr2) contain: @card(1..4)
    Then entity(ent2) get constraints for owned attribute(attr2) do not contain: @card(1..2)
    Then entity(ent2) get constraints for owned attribute(attr2) contain: @card(0..)
    Then entity(ent2) get constraints for owned attribute(attr2) do not contain: @card(0..1)
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $attr2_2 = attribute(attr2) get instance with value: "attr2_2"
    When entity $ent2 unset has: $attr2_2
    Then transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent1) get owns(attr1) unset annotation: @card
    Then entity(ent2) get constraints for owned attribute(attr0) contain: @card(1..4)
    Then entity(ent2) get constraints for owned attribute(attr0) do not contain: @card(1..2)
    Then entity(ent2) get constraints for owned attribute(attr0) do not contain: @card(0..)
    Then entity(ent2) get constraints for owned attribute(attr0) do not contain: @card(0..1)
    Then entity(ent2) get constraints for owned attribute(attr1) contain: @card(1..4)
    Then entity(ent2) get constraints for owned attribute(attr1) do not contain: @card(1..2)
    Then entity(ent2) get constraints for owned attribute(attr1) do not contain: @card(0..)
    Then entity(ent2) get constraints for owned attribute(attr1) contain: @card(0..1)
    Then entity(ent2) get constraints for owned attribute(attr2) contain: @card(1..4)
    Then entity(ent2) get constraints for owned attribute(attr2) do not contain: @card(1..2)
    Then entity(ent2) get constraints for owned attribute(attr2) contain: @card(0..)
    Then entity(ent2) get constraints for owned attribute(attr2) do not contain: @card(0..1)
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $attr1_1 = attribute(attr1) get instance with value: "attr1_1"
    When entity $ent2 unset has: $attr1_1
    Then transaction commits; fails with a message containing: "@card"

    # Interface type supertype changes validation

    When connection open schema transaction for database: typedb
    When attribute(attr1) set value type: string
    When attribute(attr1) set annotation: @independent
    When attribute(attr1) unset supertype
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When attribute(attr1) set value type: string
    When attribute(attr1) set annotation: @independent
    When entity(ent0) get owns(attr0) set annotation: @card(0..3)
    Then attribute(attr1) unset supertype
    Then entity(ent2) get constraints for owned attribute(attr0) contain: @card(0..3)
    Then entity(ent2) get constraints for owned attribute(attr0) do not contain: @card(0..)
    Then entity(ent2) get constraints for owned attribute(attr0) do not contain: @card(0..1)
    Then entity(ent2) get constraints for owned attribute(attr1) do not contain: @card(0..3)
    Then entity(ent2) get constraints for owned attribute(attr1) do not contain: @card(0..)
    Then entity(ent2) get constraints for owned attribute(attr1) contain: @card(0..1)
    Then entity(ent2) get constraints for owned attribute(attr2) contain: @card(0..3)
    Then entity(ent2) get constraints for owned attribute(attr2) contain: @card(0..)
    Then entity(ent2) get constraints for owned attribute(attr2) do not contain: @card(0..1)
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $attr1_1 = attribute(attr1) get instance with value: "attr1_1"
    When entity $ent2 unset has: $attr1_1
    Then transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $attr1_1 = attribute(attr1) get instance with value: "attr1_1"
    When $attr2_1 = attribute(attr2) get instance with value: "attr2_1"
    When entity $ent2 set has: $attr1_1
    When entity $ent2 set has: $attr2_1
    Then transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent0) get owns(attr0) set annotation: @card(1..1)
    When attribute(attr1) set supertype: attr0
    When attribute(attr1) unset value type
    When attribute(attr1) unset annotation: @independent
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent0) get owns(attr0) set annotation: @card(1..1)
    When entity(ent0) get owns(attr0) set annotation: @card(2..2)
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent0) get owns(attr0) set annotation: @card(1..2)
    When attribute(attr1) set supertype: attr0
    When attribute(attr1) unset value type
    When attribute(attr1) unset annotation: @independent
    Then entity(ent0) get owns(attr0) set annotation: @card(2..2)
    Then entity(ent2) get constraints for owned attribute(attr0) contain: @card(2..2)
    Then entity(ent2) get constraints for owned attribute(attr0) do not contain: @card(0..)
    Then entity(ent2) get constraints for owned attribute(attr0) do not contain: @card(0..1)
    Then entity(ent2) get constraints for owned attribute(attr1) contain: @card(2..2)
    Then entity(ent2) get constraints for owned attribute(attr1) do not contain: @card(0..)
    Then entity(ent2) get constraints for owned attribute(attr1) contain: @card(0..1)
    Then entity(ent2) get constraints for owned attribute(attr2) contain: @card(2..2)
    Then entity(ent2) get constraints for owned attribute(attr2) contain: @card(0..)
    Then entity(ent2) get constraints for owned attribute(attr2) do not contain: @card(0..1)
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $attr1_1 = attribute(attr1) get instance with value: "attr1_1"
    When $attr2_1 = attribute(attr2) get instance with value: "attr2_1"
    When entity $ent2 unset has: $attr1_1
    When entity $ent2 unset has: $attr2_1
    Then transaction commits; fails with a message containing: "@card"

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $attr2_1 = attribute(attr2) get instance with value: "attr2_1"
    When entity $ent2 unset has: $attr2_1
    Then transaction commits; fails with a message containing: "@card"

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $attr1_1 = attribute(attr1) get instance with value: "attr1_1"
    When entity $ent2 unset has: $attr1_1
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When attribute(attr1) set value type: string
    When attribute(attr1) set annotation: @independent
    When attribute(attr1) unset supertype
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When attribute(attr2) set value type: string
    When attribute(attr2) set annotation: @independent
    When attribute(attr2) unset supertype
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When attribute(attr1) set supertype: attr00
    Then transaction commits; fails with a message containing: "@card"

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $attr1_1 = attribute(attr1) get instance with value: "attr1_1"
    When $attr2_2 = attribute(attr2) get instance with value: "attr2_2"
    When entity $ent2 unset has: $attr1_1
    When entity $ent2 set has: $attr2_2
    Then transaction commits

    When connection open schema transaction for database: typedb
    Then attribute(attr1) set supertype: attr00
    When transaction commits

    When connection open schema transaction for database: typedb
    When attribute(attr2) set supertype: attr00
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent0) get owns(attr0) set annotation: @card(0..1)
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent0) get owns(attr0) set annotation: @card(0..2)
    When attribute(attr2) set supertype: attr00
    Then transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent2) set owns: attr00
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When attribute(attr2) set supertype: attr0
    When entity(ent2) set owns: attr00
    Then transaction commits

    When connection open schema transaction for database: typedb
    When attribute(attr2) set supertype: attr00
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent2) get owns(attr00) set annotation: @card(0..2)
    When attribute(attr2) set supertype: attr00
    Then transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent2) get owns(attr00) set annotation: @card(2..2)
    When attribute(attr2) set supertype: attr0
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent2) get owns(attr00) set annotation: @card(1..2)
    When attribute(attr2) set supertype: attr0
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent2) get owns(attr00) set annotation: @card(0..2)
    Then attribute(attr2) set supertype: attr0
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $attr1_1 = attribute(attr1) get instance with value: "attr1_1"
    When $attr1_2 = attribute(attr1) get instance with value: "attr1_2"
    When entity $ent2 set has: $attr1_1
    When entity $ent2 set has: $attr1_2
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent1) get owns(attr1) set annotation: @card(2..2)
    Then transaction commits; fails with a message containing: "@card(2..2)"

    When connection open schema transaction for database: typedb
    When entity(ent1) get owns(attr1) set annotation: @card(1..2)
    Then transaction commits; fails with a message containing: "@card(1..2)"

    When connection open schema transaction for database: typedb
    When entity(ent1) get owns(attr1) set annotation: @card(1..)
    Then transaction commits; fails with a message containing: "@card(1..)"

    When connection open schema transaction for database: typedb
    When entity(ent1) get owns(attr1) set annotation: @card(0..2)
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $attr1_1 = attribute(attr1) get instance with value: "attr1_1"
    When $attr1_2 = attribute(attr1) get instance with value: "attr1_2"
    When entity $ent2 set has: $attr1_1
    When entity $ent2 set has: $attr1_2
    Then transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent0) get owns(attr0) set annotation: @card(0..2)
    When transaction commits

    When connection open schema transaction for database: typedb
    When attribute(attr1) set supertype: attr2
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When attribute(attr1) set supertype: attr0
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent0) get owns(attr0) set annotation: @card(2..3)
    Then transaction commits

    When connection open schema transaction for database: typedb
    When attribute(attr1) set supertype: attr2
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When attribute(attr1) set supertype: attr0
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent0) get owns(attr0) set annotation: @card(3..4)
    Then transaction commits; fails with a message containing: "@card(3..4)"

    When connection open schema transaction for database: typedb
    When entity(ent0) get owns(attr0) set annotation: @card(2..4)
    When attribute(attr1) set supertype: attr2
    Then transaction commits

    When connection open schema transaction for database: typedb
    When attribute(attr1) set supertype: attr0
    Then transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $attr2_3 = attribute(attr2) put instance with value: "attr2_3"
    When entity $ent2 set has: $attr2_3
    Then transaction commits; fails with a message containing: "@card"

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $attr2_3 = attribute(attr2) put instance with value: "attr2_3"
    When $attr1_2 = attribute(attr1) get instance with value: "attr1_2"
    When entity $ent2 set has: $attr2_3
    When entity $ent2 unset has: $attr1_2
    Then transaction commits

    When connection open schema transaction for database: typedb
    When attribute(attr2) set supertype: attr00
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    Then attribute(attr1) set supertype: attr00
    Then transaction commits

    When connection open schema transaction for database: typedb
    When attribute(attr2) set supertype: attr00
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    Then attribute(attr1) set supertype: attr0
    Then transaction commits

    # Object type supertype changes validation

    When connection open schema transaction for database: typedb
    When create entity type: ent00
    When entity(ent00) set owns: attr0
    When entity(ent00) set owns: ref
    When entity(ent00) get owns(ref) set annotation: @key
    When create entity type: ent11
    When entity(ent11) set owns: ref
    When entity(ent11) get owns(ref) set annotation: @key
    When entity(ent11) set owns: attr1
    Then entity(ent00) get owns(attr0) get cardinality: @card(0..1)
    Then entity(ent11) get owns(attr1) get cardinality: @card(0..1)
    Then transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent2) set supertype: ent11
    Then transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $attr1_2 = attribute(attr1) get instance with value: "attr1_2"
    When entity $ent2 set has: $attr1_2
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    Then entity(ent2) set supertype: ent00; fails with a message containing: "lost"
    When entity(ent2) set supertype: ent1
    Then transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent11) get owns(attr1) set annotation: @key
    Then entity(ent11) get owns(attr1) get cardinality: @card(1..1)
    When entity(ent2) set supertype: ent11
    Then transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $attr1_2 = attribute(attr1) get instance with value: "attr1_2"
    When entity $ent2 set has: $attr1_2
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent2) set supertype: ent1
    Then transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent1) set supertype: ent00
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent1) set supertype: ent00
    When entity(ent00) get owns(attr0) set annotation: @card(0..3)
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent1) set supertype: ent00
    When entity(ent00) get owns(attr0) set annotation: @card(3..4)
    Then transaction commits

    When connection open schema transaction for database: typedb
    Then entity(ent1) set supertype: ent0
    Then transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent00) get owns(attr0) set annotation: @card(0..3)
    When entity(ent1) set supertype: ent00
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent00) unset owns: attr0
    Then entity(ent1) set supertype: ent00
    Then transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent00) set owns: attr0
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent0) get owns(attr0) set annotation: @card(0..1)
    Then transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent1) set supertype: ent0
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent0) get owns(attr0) set annotation: @card(0..)
    Then entity(ent1) set supertype: ent0
    Then transaction commits

    # Redeclaration with specialisation validation

    When connection open schema transaction for database: typedb
    When entity(ent1) set owns: attr0
    When entity(ent1) get owns(attr0) set annotation: @card(0..1)
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent2) set owns: attr0
    When entity(ent2) get owns(attr0) set annotation: @card(0..1)
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent0) unset owns: attr0
    When entity(ent2) set owns: attr0
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent0) unset owns: attr0
    When entity(ent1) set owns: attr0
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent2) set owns: attr1
    When entity(ent2) get owns(attr1) set annotation: @card(1..)
    Then transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent2) get owns(attr1) set annotation: @card(2..)
    Then transaction commits; fails with a message containing: "@card"

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $attr1_1 = attribute(attr1) get instance with value: "attr1_1"
    When entity $ent2 unset has: $attr1_1
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent2) get owns(attr1) set annotation: @card(0..1)
    Then transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $attr1_1 = attribute(attr1) get instance with value: "attr1_1"
    When entity $ent2 unset has: $attr1_1
    Then transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent0) get owns(attr0) set annotation: @card(3..)
    Then transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $attr2_2 = attribute(attr2) get instance with value: "attr2_2"
    When $attr2_3 = attribute(attr2) get instance with value: "attr2_3"
    When entity $ent2 unset has: $attr2_2
    When entity $ent2 unset has: $attr2_3
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent0) get owns(attr0) set annotation: @card(0..3)
    Then transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $attr2_2 = attribute(attr2) get instance with value: "attr2_2"
    When $attr2_3 = attribute(attr2) get instance with value: "attr2_3"
    When entity $ent2 unset has: $attr2_2
    When entity $ent2 unset has: $attr2_3
    Then transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent2) set owns: attr0
    When entity(ent2) get owns(attr0) set annotation: @card(2..)
    Then transaction commits; fails with a message containing: "@card(2..)"

    When connection open schema transaction for database: typedb
    When entity(ent2) set owns: attr0
    When entity(ent2) get owns(attr0) set annotation: @card(1..)
    When entity(ent2) get owns(attr0) set annotation: @card(1..1)
    Then transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $attr2_2 = attribute(attr2) get instance with value: "attr2_2"
    When entity $ent2 set has: $attr2_2
    Then transaction commits; fails with a message containing: "@card"

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $attr1_1 = attribute(attr1) get instance with value: "attr1_1"
    When entity $ent2 set has: $attr1_1
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent2) get owns(attr0) set annotation: @card(0..5)
    When entity(ent0) get owns(attr0) set annotation: @card(0..1)
    Then transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $attr2_2 = attribute(attr2) get instance with value: "attr2_2"
    When entity $ent2 set has: $attr2_2
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent0) get owns(attr0) set annotation: @card(0..2)
    Then transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $attr2_2 = attribute(attr2) get instance with value: "attr2_2"
    When entity $ent2 set has: $attr2_2
    Then transaction commits


  Scenario: Relates data is revalidated when new cardinality constraints appear
    # Setup

    When create attribute type: ref
    When attribute(ref) set value type: string
    When create relation type: rel0
    When relation(rel0) create role: role00
    When relation(rel0) get role(role00) set annotation: @abstract
    When relation(rel0) create role: role0
    When relation(rel0) get role(role0) set annotation: @abstract
    When create relation type: rel1
    When relation(rel1) set supertype: rel0
    When relation(rel1) create role: role1
    When relation(rel1) get role(role1) set specialise: role0
    When create relation type: rel2
    When relation(rel2) set supertype: rel1
    When relation(rel2) set owns: ref
    When relation(rel2) get owns(ref) set annotation: @key
    When relation(rel2) create role: anchor
    When create entity type: anchor
    When entity(anchor) set plays: rel2:anchor
    When create entity type: ent0
    When entity(ent0) set owns: ref
    When entity(ent0) get owns(ref) set annotation: @key
    When create entity type: ent1
    When create entity type: ent2
    When entity(ent1) set supertype: ent0
    When entity(ent2) set supertype: ent1
    When entity(ent0) set plays: rel0:role0
    When entity(ent1) set plays: rel1:role1
    Then relation(rel2) get constraints for related role(rel1:role1) contain: @card(0..1)
    When transaction commits

    # Direct cardinality changes validation

    When connection open write transaction for database: typedb
    When $anchor = entity(anchor) create new instance
    When $rel2 = relation(rel2) create new instance with key(ref): rel2
    When relation $rel2 add player for role(anchor): $anchor
    When transaction commits

    When connection open schema transaction for database: typedb
    When relation(rel1) get role(role1) set annotation: @card(1..)
    Then transaction commits; fails with a message containing: "@card(1..)"

    When connection open schema transaction for database: typedb
    When relation(rel1) get role(role1) set annotation: @card(1..1)
    Then transaction commits; fails with a message containing: "@card(1..1)"

    When connection open schema transaction for database: typedb
    When relation(rel0) get role(role0) set annotation: @card(1..)
    Then transaction commits; fails with a message containing: "@card(1..)"

    When connection open schema transaction for database: typedb
    When relation(rel0) get role(role0) set annotation: @card(1..1)
    Then relation(rel2) get constraints for related role(rel1:role1) contain: @card(0..1)
    Then relation(rel2) get constraints for related role(rel1:role1) contain: @card(1..1)
    Then transaction commits; fails with a message containing: "@card(1..1)"

    When connection open write transaction for database: typedb
    When $rel2 = relation(rel2) get instance with key(ref): rel2
    When $player1_1 = entity(ent2) create new instance with key(ref): player1_1
    When $player1_2 = entity(ent2) create new instance with key(ref): player1_2
    When relation $rel2 add player for role(role1): $player1_1
    When relation $rel2 add player for role(role1): $player1_2
    Then transaction commits; fails with a message containing: "@card"

    When connection open write transaction for database: typedb
    When $rel2 = relation(rel2) get instance with key(ref): rel2
    When $player1_1 = entity(ent2) create new instance with key(ref): player1_1
    When relation $rel2 add player for role(role1): $player1_1
    When transaction commits

    When connection open schema transaction for database: typedb
    When relation(rel0) get role(role0) set annotation: @card(1..)
    When relation(rel0) get role(role0) set annotation: @card(1..1)
    When relation(rel1) get role(role1) set annotation: @card(1..1)
    When relation(rel1) get role(role1) set annotation: @card(1..)
    Then relation(rel2) get constraints for related role(rel0:role0) do not contain: @card(0..1)
    Then relation(rel2) get constraints for related role(rel0:role0) contain: @card(1..1)
    Then relation(rel2) get constraints for related role(rel0:role0) do not contain: @card(1..)
    Then relation(rel2) get constraints for related role(rel1:role1) do not contain: @card(0..1)
    Then relation(rel2) get constraints for related role(rel1:role1) contain: @card(1..1)
    Then relation(rel2) get constraints for related role(rel1:role1) contain: @card(1..)
    When relation(rel1) get role(role1) unset annotation: @card
    Then relation(rel2) get constraints for related role(rel0:role0) do not contain: @card(0..1)
    Then relation(rel2) get constraints for related role(rel0:role0) contain: @card(1..1)
    Then relation(rel2) get constraints for related role(rel0:role0) do not contain: @card(1..)
    Then relation(rel2) get constraints for related role(rel1:role1) contain: @card(0..1)
    Then relation(rel2) get constraints for related role(rel1:role1) contain: @card(1..1)
    Then relation(rel2) get constraints for related role(rel1:role1) do not contain: @card(1..)
    Then transaction commits

    When connection open schema transaction for database: typedb
    When relation(rel0) get role(role0) set annotation: @card(2..3)
    Then transaction commits; fails with a message containing: "@card(2..3)"

    When connection open schema transaction for database: typedb
    When relation(rel0) get role(role0) set annotation: @card(1..3)
    Then transaction commits

    When connection open schema transaction for database: typedb
    When relation(rel1) get role(role1) set annotation: @card(1..2)
    Then relation(rel2) get constraints for related role(rel0:role0) contain: @card(1..3)
    Then relation(rel2) get constraints for related role(rel0:role0) do not contain: @card(1..2)
    Then relation(rel2) get constraints for related role(rel1:role1) contain: @card(1..3)
    Then relation(rel2) get constraints for related role(rel1:role1) contain: @card(1..2)
    When transaction commits

    When connection open write transaction for database: typedb
    When $rel2 = relation(rel2) get instance with key(ref): rel2
    When $player1_2 = entity(ent2) create new instance with key(ref): player1_2
    When relation $rel2 add player for role(role1): $player1_2
    When transaction commits

    When connection open write transaction for database: typedb
    When $rel2 = relation(rel2) get instance with key(ref): rel2
    When $player1_3 = entity(ent2) create new instance with key(ref): player1_3
    When relation $rel2 add player for role(role1): $player1_3
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When relation(rel0) get role(role0) set annotation: @card(1..2)
    When relation(rel1) get role(role1) set annotation: @card(1..3)
    Then relation(rel2) get constraints for related role(rel0:role0) contain: @card(1..2)
    Then relation(rel2) get constraints for related role(rel0:role0) do not contain: @card(1..3)
    Then relation(rel2) get constraints for related role(rel1:role1) contain: @card(1..2)
    Then relation(rel2) get constraints for related role(rel1:role1) contain: @card(1..3)
    When transaction commits

    When connection open write transaction for database: typedb
    When $rel2 = relation(rel2) get instance with key(ref): rel2
    When $player1_3 = entity(ent2) create new instance with key(ref): player1_3
    When relation $rel2 add player for role(role1): $player1_3
    Then transaction commits; fails with a message containing: "@card"

    # Default cardinality effect validation
    # Set sibling capability effect validation

    When connection open schema transaction for database: typedb
    When relation(rel1) get role(role1) unset annotation: @card
    Then transaction commits; fails with a message containing: "@card(0..1)"

    When connection open schema transaction for database: typedb
    When relation(rel1) create role: role2
    When entity(ent2) set plays: rel1:role2
    When relation(rel1) get role(role2) set specialise: role0
    Then transaction commits

    When connection open schema transaction for database: typedb
    When relation(rel1) get role(role2) set annotation: @card(1..)
    Then transaction commits; fails with a message containing: "@card(1..)"

    When connection open schema transaction for database: typedb
    When relation(rel1) get role(role2) set specialise: role0
    Then transaction commits

    When connection open schema transaction for database: typedb
    When relation(rel0) get role(role0) set annotation: @card(0..1)
    Then transaction commits; fails with a message containing: "@card(0..1)"

    When connection open schema transaction for database: typedb
    When relation(rel0) get role(role0) set annotation: @card(0..2)
    Then relation(rel2) get constraints for related role(rel0:role0) contain: @card(0..2)
    Then relation(rel2) get constraints for related role(rel0:role0) do not contain: @card(1..3)
    Then relation(rel2) get constraints for related role(rel0:role0) do not contain: @card(0..1)
    Then relation(rel2) get constraints for related role(rel1:role1) contain: @card(0..2)
    Then relation(rel2) get constraints for related role(rel1:role1) contain: @card(1..3)
    Then relation(rel2) get constraints for related role(rel1:role1) do not contain: @card(0..1)
    Then relation(rel2) get constraints for related role(rel1:role2) contain: @card(0..2)
    Then relation(rel2) get constraints for related role(rel1:role2) do not contain: @card(1..3)
    Then relation(rel2) get constraints for related role(rel1:role2) contain: @card(0..1)
    When transaction commits

    When connection open write transaction for database: typedb
    When $rel2 = relation(rel2) get instance with key(ref): rel2
    When $player2_1 = entity(ent2) create new instance with key(ref): player2_1
    When relation $rel2 add player for role(role2): $player2_1
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When relation(rel0) get role(role0) set annotation: @card(2..3)
    When relation(rel0) get role(role0) set annotation: @card(1..3)
    When relation(rel0) get role(role0) set annotation: @card(0..3)
    When relation(rel1) get role(role1) set annotation: @card(2..2)
    When relation(rel1) get role(role1) set annotation: @card(1..2)
    Then relation(rel2) get constraints for related role(rel0:role0) contain: @card(0..3)
    Then relation(rel2) get constraints for related role(rel0:role0) do not contain: @card(1..2)
    Then relation(rel2) get constraints for related role(rel0:role0) do not contain: @card(0..1)
    Then relation(rel2) get constraints for related role(rel1:role1) contain: @card(0..3)
    Then relation(rel2) get constraints for related role(rel1:role1) contain: @card(1..2)
    Then relation(rel2) get constraints for related role(rel1:role1) do not contain: @card(0..1)
    Then relation(rel2) get constraints for related role(rel1:role2) contain: @card(0..3)
    Then relation(rel2) get constraints for related role(rel1:role2) do not contain: @card(1..2)
    Then relation(rel2) get constraints for related role(rel1:role2) contain: @card(0..1)
    When transaction commits

    When connection open write transaction for database: typedb
    When $rel2 = relation(rel2) get instance with key(ref): rel2
    When $player2_1 = entity(ent2) create new instance with key(ref): player2_1
    When relation $rel2 add player for role(role2): $player2_1
    Then transaction commits

    When connection open schema transaction for database: typedb
    When relation(rel0) get role(role0) set annotation: @card(2..3)
    When relation(rel0) get role(role0) set annotation: @card(1..3)
    Then relation(rel2) get constraints for related role(rel0:role0) contain: @card(1..3)
    Then relation(rel2) get constraints for related role(rel0:role0) do not contain: @card(1..2)
    Then relation(rel2) get constraints for related role(rel0:role0) do not contain: @card(0..1)
    Then relation(rel2) get constraints for related role(rel1:role1) contain: @card(1..3)
    Then relation(rel2) get constraints for related role(rel1:role1) contain: @card(1..2)
    Then relation(rel2) get constraints for related role(rel1:role1) do not contain: @card(0..1)
    Then relation(rel2) get constraints for related role(rel1:role2) contain: @card(1..3)
    Then relation(rel2) get constraints for related role(rel1:role2) do not contain: @card(1..2)
    Then relation(rel2) get constraints for related role(rel1:role2) contain: @card(0..1)
    When transaction commits

    When connection open write transaction for database: typedb
    When $rel2 = relation(rel2) get instance with key(ref): rel2
    When $player2_2 = entity(ent2) create new instance with key(ref): player2_2
    When relation $rel2 add player for role(role2): $player2_2
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When relation(rel1) get role(role2) set annotation: @card(1..10)
    Then relation(rel2) get constraints for related role(rel0:role0) contain: @card(1..3)
    Then relation(rel2) get constraints for related role(rel0:role0) do not contain: @card(1..2)
    Then relation(rel2) get constraints for related role(rel0:role0) do not contain: @card(1..10)
    Then relation(rel2) get constraints for related role(rel1:role1) contain: @card(1..3)
    Then relation(rel2) get constraints for related role(rel1:role1) contain: @card(1..2)
    Then relation(rel2) get constraints for related role(rel1:role1) do not contain: @card(1..10)
    Then relation(rel2) get constraints for related role(rel1:role2) contain: @card(1..3)
    Then relation(rel2) get constraints for related role(rel1:role2) do not contain: @card(1..2)
    Then relation(rel2) get constraints for related role(rel1:role2) contain: @card(1..10)
    When transaction commits

    When connection open write transaction for database: typedb
    When $rel2 = relation(rel2) get instance with key(ref): rel2
    When $player2_2 = entity(ent2) create new instance with key(ref): player2_2
    When relation $rel2 add player for role(role2): $player2_2
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When relation(rel0) get role(role0) set annotation: @card(2..4)
    When relation(rel0) get role(role0) set annotation: @card(1..4)
    Then relation(rel2) get constraints for related role(rel0:role0) contain: @card(1..4)
    Then relation(rel2) get constraints for related role(rel0:role0) do not contain: @card(1..2)
    Then relation(rel2) get constraints for related role(rel0:role0) do not contain: @card(1..10)
    Then relation(rel2) get constraints for related role(rel1:role1) contain: @card(1..4)
    Then relation(rel2) get constraints for related role(rel1:role1) contain: @card(1..2)
    Then relation(rel2) get constraints for related role(rel1:role1) do not contain: @card(1..10)
    Then relation(rel2) get constraints for related role(rel1:role2) contain: @card(1..4)
    Then relation(rel2) get constraints for related role(rel1:role2) do not contain: @card(1..2)
    Then relation(rel2) get constraints for related role(rel1:role2) contain: @card(1..10)
    When transaction commits

    When connection open write transaction for database: typedb
    When $rel2 = relation(rel2) get instance with key(ref): rel2
    When $player2_2 = entity(ent2) create new instance with key(ref): player2_2
    When relation $rel2 add player for role(role2): $player2_2
    Then transaction commits

    When connection open write transaction for database: typedb
    When $rel2 = relation(rel2) get instance with key(ref): rel2
    When $player1_2 = entity(ent2) get instance with key(ref): player1_2
    When relation $rel2 remove player for role(role1): $player1_2
    When $player2_1 = entity(ent2) get instance with key(ref): player2_1
    When relation $rel2 remove player for role(role2): $player2_1
    Then transaction commits

    When connection open write transaction for database: typedb
    When $rel2 = relation(rel2) get instance with key(ref): rel2
    When $player1_1 = entity(ent2) get instance with key(ref): player1_1
    When relation $rel2 remove player for role(role1): $player1_1
    Then transaction commits; fails with a message containing: "@card"

    When connection open write transaction for database: typedb
    When $rel2 = relation(rel2) get instance with key(ref): rel2
    When $player2_2 = entity(ent2) get instance with key(ref): player2_2
    When relation $rel2 remove player for role(role2): $player2_2
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When relation(rel1) get role(role2) set annotation: @card(0..)
    Then relation(rel2) get constraints for related role(rel0:role0) contain: @card(1..4)
    Then relation(rel2) get constraints for related role(rel0:role0) do not contain: @card(1..2)
    Then relation(rel2) get constraints for related role(rel0:role0) do not contain: @card(0..)
    Then relation(rel2) get constraints for related role(rel0:role0) do not contain: @card(0..1)
    Then relation(rel2) get constraints for related role(rel1:role1) contain: @card(1..4)
    Then relation(rel2) get constraints for related role(rel1:role1) contain: @card(1..2)
    Then relation(rel2) get constraints for related role(rel1:role1) do not contain: @card(0..)
    Then relation(rel2) get constraints for related role(rel1:role1) do not contain: @card(0..1)
    Then relation(rel2) get constraints for related role(rel1:role2) contain: @card(1..4)
    Then relation(rel2) get constraints for related role(rel1:role2) do not contain: @card(1..2)
    Then relation(rel2) get constraints for related role(rel1:role2) contain: @card(0..)
    Then relation(rel2) get constraints for related role(rel1:role2) do not contain: @card(0..1)
    When transaction commits

    When connection open write transaction for database: typedb
    When $rel2 = relation(rel2) get instance with key(ref): rel2
    When $player2_2 = entity(ent2) get instance with key(ref): player2_2
    When relation $rel2 remove player for role(role2): $player2_2
    Then transaction commits

    When connection open schema transaction for database: typedb
    When relation(rel1) get role(role1) unset annotation: @card
    Then relation(rel2) get constraints for related role(rel0:role0) contain: @card(1..4)
    Then relation(rel2) get constraints for related role(rel0:role0) do not contain: @card(1..2)
    Then relation(rel2) get constraints for related role(rel0:role0) do not contain: @card(0..)
    Then relation(rel2) get constraints for related role(rel0:role0) do not contain: @card(0..1)
    Then relation(rel2) get constraints for related role(rel1:role1) contain: @card(1..4)
    Then relation(rel2) get constraints for related role(rel1:role1) do not contain: @card(1..2)
    Then relation(rel2) get constraints for related role(rel1:role1) do not contain: @card(0..)
    Then relation(rel2) get constraints for related role(rel1:role1) contain: @card(0..1)
    Then relation(rel2) get constraints for related role(rel1:role2) contain: @card(1..4)
    Then relation(rel2) get constraints for related role(rel1:role2) do not contain: @card(1..2)
    Then relation(rel2) get constraints for related role(rel1:role2) contain: @card(0..)
    Then relation(rel2) get constraints for related role(rel1:role2) do not contain: @card(0..1)
    When transaction commits

    When connection open write transaction for database: typedb
    When $rel2 = relation(rel2) get instance with key(ref): rel2
    When $player1_1 = entity(ent2) get instance with key(ref): player1_1
    When relation $rel2 remove player for role(role1): $player1_1
    Then transaction commits; fails with a message containing: "@card"

    # Interface type supertype changes validation

    When connection open schema transaction for database: typedb
    When relation(rel1) get role(role1) unset specialise
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When relation(rel0) get role(role0) set annotation: @card(0..3)
    Then relation(rel1) get role(role1) unset specialise
    Then relation(rel2) get constraints for related role(rel0:role0) contain: @card(0..3)
    Then relation(rel2) get constraints for related role(rel0:role0) do not contain: @card(0..)
    Then relation(rel2) get constraints for related role(rel0:role0) do not contain: @card(0..1)
    Then relation(rel2) get constraints for related role(rel1:role1) do not contain: @card(0..3)
    Then relation(rel2) get constraints for related role(rel1:role1) do not contain: @card(0..)
    Then relation(rel2) get constraints for related role(rel1:role1) contain: @card(0..1)
    Then relation(rel2) get constraints for related role(rel1:role2) contain: @card(0..3)
    Then relation(rel2) get constraints for related role(rel1:role2) contain: @card(0..)
    Then relation(rel2) get constraints for related role(rel1:role2) do not contain: @card(0..1)
    When transaction commits

    When connection open write transaction for database: typedb
    When $rel2 = relation(rel2) get instance with key(ref): rel2
    When $player1_1 = entity(ent2) get instance with key(ref): player1_1
    When relation $rel2 remove player for role(role1): $player1_1
    Then transaction commits

    When connection open write transaction for database: typedb
    When $rel2 = relation(rel2) get instance with key(ref): rel2
    When $player1_1 = entity(ent2) get instance with key(ref): player1_1
    When $player2_1 = entity(ent2) get instance with key(ref): player2_1
    When relation $rel2 add player for role(role1): $player1_1
    When relation $rel2 add player for role(role2): $player2_1
    Then transaction commits

    When connection open schema transaction for database: typedb
    When relation(rel0) get role(role0) set annotation: @card(1..1)
    Then transaction commits

    When connection open schema transaction for database: typedb
    When relation(rel0) get role(role0) set annotation: @card(2..2)
    Then transaction commits; fails with a message containing: "@card(2..2)"

    When connection open schema transaction for database: typedb
    When relation(rel0) get role(role0) set annotation: @card(1..2)
    When relation(rel1) get role(role1) set specialise: role0
    Then relation(rel0) get role(role0) set annotation: @card(2..2)
    Then relation(rel2) get constraints for related role(rel0:role0) contain: @card(2..2)
    Then relation(rel2) get constraints for related role(rel0:role0) do not contain: @card(0..)
    Then relation(rel2) get constraints for related role(rel0:role0) do not contain: @card(0..1)
    Then relation(rel2) get constraints for related role(rel1:role1) contain: @card(2..2)
    Then relation(rel2) get constraints for related role(rel1:role1) do not contain: @card(0..)
    Then relation(rel2) get constraints for related role(rel1:role1) contain: @card(0..1)
    Then relation(rel2) get constraints for related role(rel1:role2) contain: @card(2..2)
    Then relation(rel2) get constraints for related role(rel1:role2) contain: @card(0..)
    Then relation(rel2) get constraints for related role(rel1:role2) do not contain: @card(0..1)
    When transaction commits

    When connection open write transaction for database: typedb
    When $rel2 = relation(rel2) get instance with key(ref): rel2
    When $player1_1 = entity(ent2) get instance with key(ref): player1_1
    When $player2_1 = entity(ent2) get instance with key(ref): player2_1
    When relation $rel2 remove player for role(role1): $player1_1
    When relation $rel2 remove player for role(role2): $player2_1
    Then transaction commits; fails with a message containing: "@card"

    When connection open write transaction for database: typedb
    When $rel2 = relation(rel2) get instance with key(ref): rel2
    When $player2_1 = entity(ent2) get instance with key(ref): player2_1
    When relation $rel2 remove player for role(role2): $player2_1

    Then transaction commits; fails with a message containing: "@card"

    When connection open write transaction for database: typedb
    When $rel2 = relation(rel2) get instance with key(ref): rel2
    When $player1_1 = entity(ent2) get instance with key(ref): player1_1
    When relation $rel2 remove player for role(role1): $player1_1
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When relation(rel1) get role(role1) unset specialise
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    Then relation(rel1) get role(role2) unset specialise
    When transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When relation(rel1) get role(role1) set specialise: role00
    Then transaction commits; fails with a message containing: "@card"

    When connection open write transaction for database: typedb
    When $rel2 = relation(rel2) get instance with key(ref): rel2
    When $player1_1 = entity(ent2) get instance with key(ref): player1_1
    When $player2_2 = entity(ent2) get instance with key(ref): player2_2
    When relation $rel2 remove player for role(role1): $player1_1
    When relation $rel2 add player for role(role2): $player2_2
    Then transaction commits

    When connection open schema transaction for database: typedb
    Then relation(rel1) get role(role1) set specialise: role00
    When transaction commits

    When connection open schema transaction for database: typedb
    When relation(rel1) get role(role2) set specialise: role00
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When relation(rel0) get role(role0) set annotation: @card(0..1)
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When relation(rel0) get role(role0) set annotation: @card(0..2)
    Then transaction commits

    When connection open schema transaction for database: typedb
    When relation(rel1) get role(role2) set specialise: role00
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When relation(rel0) get role(role00) set annotation: @card(0..2)
    Then relation(rel1) get role(role2) set specialise: role00
    When relation(rel0) get role(role00) set annotation: @card(2..2)
    Then transaction commits

    When connection open schema transaction for database: typedb
    When relation(rel1) get role(role2) set specialise: role0
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When relation(rel0) get role(role00) set annotation: @card(1..2)
    Then transaction commits

    When connection open schema transaction for database: typedb
    When relation(rel1) get role(role2) set specialise: role0
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When relation(rel0) get role(role00) set annotation: @card(0..2)
    Then relation(rel1) get role(role2) set specialise: role0
    When transaction commits

    When connection open write transaction for database: typedb
    When $rel2 = relation(rel2) get instance with key(ref): rel2
    When $player1_1 = entity(ent2) get instance with key(ref): player1_1
    When $player1_2 = entity(ent2) get instance with key(ref): player1_2
    When relation $rel2 add player for role(role1): $player1_1
    When relation $rel2 add player for role(role1): $player1_2
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When relation(rel1) get role(role1) set annotation: @card(2..2)
    Then transaction commits; fails with a message containing: "@card(2..2)"

    When connection open schema transaction for database: typedb
    When relation(rel1) get role(role1) set annotation: @card(1..2)
    Then transaction commits; fails with a message containing: "@card(1..2)"

    When connection open schema transaction for database: typedb
    When relation(rel1) get role(role1) set annotation: @card(1..)
    Then transaction commits; fails with a message containing: "@card(1..)"

    When connection open schema transaction for database: typedb
    When relation(rel1) get role(role1) set annotation: @card(0..2)
    When transaction commits

    When connection open write transaction for database: typedb
    When $rel2 = relation(rel2) get instance with key(ref): rel2
    When $player1_1 = entity(ent2) get instance with key(ref): player1_1
    When $player1_2 = entity(ent2) get instance with key(ref): player1_2
    When relation $rel2 add player for role(role1): $player1_1
    When relation $rel2 add player for role(role1): $player1_2
    Then transaction commits

    When connection open schema transaction for database: typedb
    When relation(rel0) get role(role0) set annotation: @card(0..2)
    Then transaction commits

    When connection open schema transaction for database: typedb
    When relation(rel1) get role(role1) set specialise: role0
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When relation(rel0) get role(role0) set annotation: @card(2..3)
    Then transaction commits

    When connection open schema transaction for database: typedb
    When relation(rel1) get role(role1) set specialise: role0
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When relation(rel0) get role(role0) set annotation: @card(3..4)
    Then transaction commits; fails with a message containing: "@card(3..4)"

    When connection open schema transaction for database: typedb
    When relation(rel0) get role(role0) set annotation: @card(2..4)
    Then relation(rel1) get role(role1) set specialise: role0
    Then transaction commits

    When connection open write transaction for database: typedb
    When $rel2 = relation(rel2) get instance with key(ref): rel2
    When $player2_3 = entity(ent2) create new instance with key(ref): player2_3
    When relation $rel2 add player for role(role2): $player2_3
    Then transaction commits; fails with a message containing: "@card"

    When connection open write transaction for database: typedb
    When $rel2 = relation(rel2) get instance with key(ref): rel2
    When $player2_3 = entity(ent2) create new instance with key(ref): player2_3
    When $player1_2 = entity(ent2) get instance with key(ref): player1_2
    When relation $rel2 add player for role(role2): $player2_3
    When relation $rel2 remove player for role(role1): $player1_2
    Then transaction commits

    When connection open schema transaction for database: typedb
    When relation(rel1) get role(role2) set specialise: role00
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    Then relation(rel1) get role(role1) set specialise: role00
    Then transaction commits

    When connection open schema transaction for database: typedb
    When relation(rel1) get role(role2) set specialise: role00
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    Then relation(rel1) get role(role1) set specialise: role0
    Then transaction commits

    # Object type supertype changes cannot affect relates as role types' supertypes are set through specialisation


  Scenario: Plays data is revalidated when new cardinality constraints appear
    # Setup

    When create attribute type: ref
    When attribute(ref) set value type: string
    When create relation type: rel0
    When relation(rel0) create role: role00
    When relation(rel0) get role(role00) set annotation: @abstract
    When relation(rel0) get role(role00) set annotation: @card(0..)
    When relation(rel0) create role: role0
    When relation(rel0) get role(role0) set annotation: @abstract
    When relation(rel0) get role(role0) set annotation: @card(0..)
    When create relation type: rel1
    When relation(rel1) set supertype: rel0
    When relation(rel1) create role: role1
    When relation(rel1) get role(role1) set specialise: role0
    When relation(rel1) get role(role1) set annotation: @card(0..)
    When create relation type: rel2
    When relation(rel2) set supertype: rel1
    When relation(rel2) set owns: ref
    When relation(rel2) get owns(ref) set annotation: @key
    When relation(rel2) create role: anchor
    When create entity type: anchor
    When entity(anchor) set plays: rel2:anchor
    When create entity type: ent0
    When entity(ent0) set owns: ref
    When entity(ent0) get owns(ref) set annotation: @key
    When create entity type: ent1
    When create entity type: ent2
    When entity(ent1) set supertype: ent0
    When entity(ent2) set supertype: ent1
    When entity(ent0) set plays: rel0:role0
    When entity(ent1) set plays: rel1:role1
    Then entity(ent2) get constraints for played role(rel1:role1) contain: @card(0..)
    Then entity(ent2) get constraints for played role(rel1:role1) do not contain: @card(0..1)
    When transaction commits

    When connection open write transaction for database: typedb
    When $anchor = entity(anchor) create new instance
    When $rel1 = relation(rel2) create new instance with key(ref): rel1
    When relation $rel1 add player for role(anchor): $anchor
    When $rel2 = relation(rel2) create new instance with key(ref): rel2
    When relation $rel2 add player for role(anchor): $anchor
    When $rel3 = relation(rel2) create new instance with key(ref): rel3
    When relation $rel3 add player for role(anchor): $anchor
    When transaction commits

    # Direct cardinality changes validation

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) create new instance with key(ref): ent2
    When transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent1) get plays(rel1:role1) set annotation: @card(1..)
    Then transaction commits; fails with a message containing: "card(1..)"

    When connection open schema transaction for database: typedb
    When entity(ent1) get plays(rel1:role1) set annotation: @card(1..1)
    Then transaction commits; fails with a message containing: "card(1..1)"

    When connection open schema transaction for database: typedb
    When entity(ent1) get plays(rel1:role1) set annotation: @card(0..1)
    Then transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent0) get plays(rel0:role0) set annotation: @card(1..)
    Then transaction commits; fails with a message containing: "card(1..)"

    When connection open schema transaction for database: typedb
    When entity(ent0) get plays(rel0:role0) set annotation: @card(1..1)
    Then transaction commits; fails with a message containing: "card(1..1)"

    When connection open schema transaction for database: typedb
    Then entity(ent2) get constraints for played role(rel1:role1) contain: @card(0..1)
    Then entity(ent2) get constraints for played role(rel1:role1) contain: @card(0..)
    Then entity(ent2) get constraints for played role(rel1:role1) do not contain: @card(1..1)
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $rel1 = relation(rel2) get instance with key(ref): rel1
    When $rel2 = relation(rel2) get instance with key(ref): rel2
    When relation $rel1 add player for role(role1): $ent2
    When relation $rel2 add player for role(role1): $ent2
    Then transaction commits; fails with a message containing: "@card(0..1)"

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $rel1 = relation(rel2) get instance with key(ref): rel1
    When relation $rel1 add player for role(role1): $ent2
    When transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent0) get plays(rel0:role0) set annotation: @card(1..)
    When entity(ent0) get plays(rel0:role0) set annotation: @card(1..1)
    When entity(ent1) get plays(rel1:role1) set annotation: @card(1..1)
    When entity(ent1) get plays(rel1:role1) set annotation: @card(1..)
    Then entity(ent2) get constraints for played role(rel0:role0) do not contain: @card(0..1)
    Then entity(ent2) get constraints for played role(rel0:role0) contain: @card(1..1)
    Then entity(ent2) get constraints for played role(rel0:role0) do not contain: @card(1..)
    Then entity(ent2) get constraints for played role(rel1:role1) do not contain: @card(0..1)
    Then entity(ent2) get constraints for played role(rel1:role1) contain: @card(1..1)
    Then entity(ent2) get constraints for played role(rel1:role1) contain: @card(1..)
    When entity(ent1) get plays(rel1:role1) unset annotation: @card
    Then entity(ent2) get constraints for played role(rel0:role0) do not contain: @card(0..1)
    Then entity(ent2) get constraints for played role(rel0:role0) contain: @card(1..1)
    Then entity(ent2) get constraints for played role(rel0:role0) do not contain: @card(1..)
    Then entity(ent2) get constraints for played role(rel1:role1) contain: @card(0..)
    Then entity(ent2) get constraints for played role(rel1:role1) do not contain: @card(0..1)
    Then entity(ent2) get constraints for played role(rel1:role1) contain: @card(1..1)
    Then entity(ent2) get constraints for played role(rel1:role1) do not contain: @card(1..)
    Then transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent0) get plays(rel0:role0) set annotation: @card(2..3)
    Then transaction commits; fails with a message containing: "card(2..3)"

    When connection open schema transaction for database: typedb
    When entity(ent0) get plays(rel0:role0) set annotation: @card(1..3)
    When entity(ent1) get plays(rel1:role1) set annotation: @card(1..2)
    Then entity(ent2) get constraints for played role(rel0:role0) contain: @card(1..3)
    Then entity(ent2) get constraints for played role(rel0:role0) do not contain: @card(1..2)
    Then entity(ent2) get constraints for played role(rel1:role1) contain: @card(1..3)
    Then entity(ent2) get constraints for played role(rel1:role1) contain: @card(1..2)
    Then transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $rel2 = relation(rel2) get instance with key(ref): rel2
    When relation $rel2 add player for role(role1): $ent2
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $rel3 = relation(rel2) get instance with key(ref): rel3
    When relation $rel3 add player for role(role1): $ent2
    Then transaction commits; fails with a message containing: "@card(1..2)"

    When connection open schema transaction for database: typedb
    When entity(ent0) get plays(rel0:role0) set annotation: @card(1..2)
    When entity(ent1) get plays(rel1:role1) set annotation: @card(1..3)
    Then entity(ent2) get constraints for played role(rel0:role0) contain: @card(1..2)
    Then entity(ent2) get constraints for played role(rel0:role0) do not contain: @card(1..3)
    Then entity(ent2) get constraints for played role(rel1:role1) contain: @card(1..2)
    Then entity(ent2) get constraints for played role(rel1:role1) contain: @card(1..3)
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $rel3 = relation(rel2) get instance with key(ref): rel3
    When relation $rel3 add player for role(role1): $ent2
    Then transaction commits; fails with a message containing: "@card(1..2)"

    # Default cardinality effect validation (no validation as it creates @card(0..)!

    When connection open schema transaction for database: typedb
    Then entity(ent1) get plays(rel1:role1) unset annotation: @card
    Then transaction commits

    When connection open schema transaction for database: typedb
    Then entity(ent1) get plays(rel1:role1) set annotation: @card(1..3)
    Then transaction commits

    # Set sibling capability effect validation

    When connection open schema transaction for database: typedb
    When relation(rel1) create role: role2
    When relation(rel1) get role(role2) set specialise: role0
    When relation(rel1) get role(role2) set annotation: @card(0..)
    When entity(ent2) set plays: rel1:role2
    Then transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent2) get plays(rel1:role2) set annotation: @card(1..)
    Then transaction commits; fails with a message containing: "@card(1..)"

    When connection open schema transaction for database: typedb
    When relation(rel1) get role(role2) set specialise: role0
    When entity(ent0) get plays(rel0:role0) set annotation: @card(0..2)
    Then transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent0) get plays(rel0:role0) set annotation: @card(0..1)
    Then transaction commits; fails with a message containing: "@card(0..1)"

    When connection open schema transaction for database: typedb
    When entity(ent2) get plays(rel1:role2) set annotation: @card(1..1)
    Then transaction commits; fails with a message containing: "@card(1..1)"

    When connection open schema transaction for database: typedb
    When entity(ent2) get plays(rel1:role2) set annotation: @card(0..1)
    Then entity(ent2) get constraints for played role(rel0:role0) contain: @card(0..2)
    Then entity(ent2) get constraints for played role(rel0:role0) do not contain: @card(1..3)
    Then entity(ent2) get constraints for played role(rel0:role0) do not contain: @card(0..1)
    Then entity(ent2) get constraints for played role(rel1:role1) contain: @card(0..2)
    Then entity(ent2) get constraints for played role(rel1:role1) contain: @card(1..3)
    Then entity(ent2) get constraints for played role(rel1:role1) do not contain: @card(0..1)
    Then entity(ent2) get constraints for played role(rel1:role2) contain: @card(0..2)
    Then entity(ent2) get constraints for played role(rel1:role2) do not contain: @card(1..3)
    Then entity(ent2) get constraints for played role(rel1:role2) do not contain: @card(0..)
    Then entity(ent2) get constraints for played role(rel1:role2) contain: @card(0..1)
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $rel1 = relation(rel2) get instance with key(ref): rel1
    When relation $rel1 add player for role(role2): $ent2
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent0) get plays(rel0:role0) set annotation: @card(2..3)
    When entity(ent0) get plays(rel0:role0) set annotation: @card(1..3)
    When entity(ent0) get plays(rel0:role0) set annotation: @card(0..3)
    When entity(ent1) get plays(rel1:role1) set annotation: @card(2..2)
    When entity(ent1) get plays(rel1:role1) set annotation: @card(1..2)
    Then entity(ent2) get constraints for played role(rel0:role0) contain: @card(0..3)
    Then entity(ent2) get constraints for played role(rel0:role0) do not contain: @card(1..2)
    Then entity(ent2) get constraints for played role(rel0:role0) do not contain: @card(0..1)
    Then entity(ent2) get constraints for played role(rel1:role1) contain: @card(0..3)
    Then entity(ent2) get constraints for played role(rel1:role1) contain: @card(1..2)
    Then entity(ent2) get constraints for played role(rel1:role1) do not contain: @card(0..1)
    Then entity(ent2) get constraints for played role(rel1:role2) contain: @card(0..3)
    Then entity(ent2) get constraints for played role(rel1:role2) do not contain: @card(1..2)
    Then entity(ent2) get constraints for played role(rel1:role2) contain: @card(0..1)
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $rel1 = relation(rel2) get instance with key(ref): rel1
    When relation $rel1 add player for role(role2): $ent2
    Then transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent0) get plays(rel0:role0) set annotation: @card(2..3)
    When entity(ent0) get plays(rel0:role0) set annotation: @card(1..3)
    Then entity(ent2) get constraints for played role(rel0:role0) contain: @card(1..3)
    Then entity(ent2) get constraints for played role(rel0:role0) do not contain: @card(1..2)
    Then entity(ent2) get constraints for played role(rel0:role0) do not contain: @card(0..1)
    Then entity(ent2) get constraints for played role(rel1:role1) contain: @card(1..3)
    Then entity(ent2) get constraints for played role(rel1:role1) contain: @card(1..2)
    Then entity(ent2) get constraints for played role(rel1:role1) do not contain: @card(0..1)
    Then entity(ent2) get constraints for played role(rel1:role2) contain: @card(1..3)
    Then entity(ent2) get constraints for played role(rel1:role2) do not contain: @card(1..2)
    Then entity(ent2) get constraints for played role(rel1:role2) contain: @card(0..1)
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $rel2 = relation(rel2) get instance with key(ref): rel2
    When relation $rel2 add player for role(role2): $ent2
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent2) get plays(rel1:role2) set annotation: @card(1..10)
    Then entity(ent2) get constraints for played role(rel0:role0) contain: @card(1..3)
    Then entity(ent2) get constraints for played role(rel0:role0) do not contain: @card(1..2)
    Then entity(ent2) get constraints for played role(rel0:role0) do not contain: @card(1..10)
    Then entity(ent2) get constraints for played role(rel1:role1) contain: @card(1..3)
    Then entity(ent2) get constraints for played role(rel1:role1) contain: @card(1..2)
    Then entity(ent2) get constraints for played role(rel1:role1) do not contain: @card(1..10)
    Then entity(ent2) get constraints for played role(rel1:role2) contain: @card(1..3)
    Then entity(ent2) get constraints for played role(rel1:role2) do not contain: @card(1..2)
    Then entity(ent2) get constraints for played role(rel1:role2) contain: @card(1..10)
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $rel2 = relation(rel2) get instance with key(ref): rel2
    When relation $rel2 add player for role(role2): $ent2
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent0) get plays(rel0:role0) set annotation: @card(2..4)
    When entity(ent0) get plays(rel0:role0) set annotation: @card(1..4)
    Then entity(ent2) get constraints for played role(rel0:role0) contain: @card(1..4)
    Then entity(ent2) get constraints for played role(rel0:role0) do not contain: @card(1..2)
    Then entity(ent2) get constraints for played role(rel0:role0) do not contain: @card(1..10)
    Then entity(ent2) get constraints for played role(rel1:role1) contain: @card(1..4)
    Then entity(ent2) get constraints for played role(rel1:role1) contain: @card(1..2)
    Then entity(ent2) get constraints for played role(rel1:role1) do not contain: @card(1..10)
    Then entity(ent2) get constraints for played role(rel1:role2) contain: @card(1..4)
    Then entity(ent2) get constraints for played role(rel1:role2) do not contain: @card(1..2)
    Then entity(ent2) get constraints for played role(rel1:role2) contain: @card(1..10)
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $rel2 = relation(rel2) get instance with key(ref): rel2
    When relation $rel2 add player for role(role2): $ent2
    Then transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $rel2 = relation(rel2) get instance with key(ref): rel2
    When relation $rel2 remove player for role(role1): $ent2
    When $rel1 = relation(rel2) get instance with key(ref): rel1
    When relation $rel1 remove player for role(role2): $ent2
    Then transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $rel1 = relation(rel2) get instance with key(ref): rel1
    When relation $rel1 remove player for role(role1): $ent2
    Then transaction commits; fails with a message containing: "@card"

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $rel2 = relation(rel2) get instance with key(ref): rel2
    When relation $rel2 remove player for role(role2): $ent2
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent2) get plays(rel1:role2) set annotation: @card(0..)
    Then entity(ent2) get constraints for played role(rel0:role0) contain: @card(1..4)
    Then entity(ent2) get constraints for played role(rel0:role0) do not contain: @card(1..2)
    Then entity(ent2) get constraints for played role(rel0:role0) do not contain: @card(0..)
    Then entity(ent2) get constraints for played role(rel0:role0) do not contain: @card(0..1)
    Then entity(ent2) get constraints for played role(rel1:role1) contain: @card(1..4)
    Then entity(ent2) get constraints for played role(rel1:role1) contain: @card(1..2)
    Then entity(ent2) get constraints for played role(rel1:role1) do not contain: @card(0..)
    Then entity(ent2) get constraints for played role(rel1:role1) do not contain: @card(0..1)
    Then entity(ent2) get constraints for played role(rel1:role2) contain: @card(1..4)
    Then entity(ent2) get constraints for played role(rel1:role2) do not contain: @card(1..2)
    Then entity(ent2) get constraints for played role(rel1:role2) contain: @card(0..)
    Then entity(ent2) get constraints for played role(rel1:role2) do not contain: @card(0..1)
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $rel2 = relation(rel2) get instance with key(ref): rel2
    When relation $rel2 remove player for role(role2): $ent2
    Then transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent1) get plays(rel1:role1) unset annotation: @card
    Then entity(ent2) get constraints for played role(rel0:role0) contain: @card(1..4)
    Then entity(ent2) get constraints for played role(rel0:role0) do not contain: @card(1..2)
    Then entity(ent2) get constraints for played role(rel0:role0) do not contain: @card(0..)
    Then entity(ent2) get constraints for played role(rel0:role0) do not contain: @card(0..1)
    Then entity(ent2) get constraints for played role(rel1:role1) contain: @card(1..4)
    Then entity(ent2) get constraints for played role(rel1:role1) do not contain: @card(1..2)
    Then entity(ent2) get constraints for played role(rel1:role1) do not contain: @card(0..1)
    Then entity(ent2) get constraints for played role(rel1:role1) contain: @card(0..)
    Then entity(ent2) get constraints for played role(rel1:role2) contain: @card(1..4)
    Then entity(ent2) get constraints for played role(rel1:role2) do not contain: @card(1..2)
    Then entity(ent2) get constraints for played role(rel1:role2) contain: @card(0..)
    Then entity(ent2) get constraints for played role(rel1:role2) do not contain: @card(0..1)
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $rel1 = relation(rel2) get instance with key(ref): rel1
    When relation $rel1 remove player for role(role1): $ent2
    Then transaction commits; fails with a message containing: "@card"

    # Interface type supertype changes validation

    When connection open schema transaction for database: typedb
    When relation(rel1) get role(role1) unset specialise
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent0) get plays(rel0:role0) set annotation: @card(0..3)
    Then relation(rel1) get role(role1) unset specialise
    Then entity(ent2) get constraints for played role(rel0:role0) contain: @card(0..3)
    Then entity(ent2) get constraints for played role(rel0:role0) do not contain: @card(0..)
    Then entity(ent2) get constraints for played role(rel0:role0) do not contain: @card(0..1)
    Then entity(ent2) get constraints for played role(rel1:role1) do not contain: @card(0..3)
    Then entity(ent2) get constraints for played role(rel1:role1) do not contain: @card(0..1)
    Then entity(ent2) get constraints for played role(rel1:role1) contain: @card(0..)
    Then entity(ent2) get constraints for played role(rel1:role2) contain: @card(0..3)
    Then entity(ent2) get constraints for played role(rel1:role2) contain: @card(0..)
    Then entity(ent2) get constraints for played role(rel1:role2) do not contain: @card(0..1)
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $rel1 = relation(rel2) get instance with key(ref): rel1
    When relation $rel1 remove player for role(role1): $ent2
    Then transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $rel1 = relation(rel2) get instance with key(ref): rel1
    When relation $rel1 add player for role(role1): $ent2
    When relation $rel1 add player for role(role2): $ent2
    Then transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent0) get plays(rel0:role0) set annotation: @card(1..1)
    Then transaction commits

    When connection open schema transaction for database: typedb
    When relation(rel1) get role(role1) set specialise: role0
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent0) get plays(rel0:role0) set annotation: @card(2..2)
    Then transaction commits; fails with a message containing: "@card(2..2)"

    When connection open schema transaction for database: typedb
    When entity(ent0) get plays(rel0:role0) set annotation: @card(1..2)
    When relation(rel1) get role(role1) set specialise: role0
    Then entity(ent0) get plays(rel0:role0) set annotation: @card(2..2)
    Then entity(ent2) get constraints for played role(rel0:role0) contain: @card(2..2)
    Then entity(ent2) get constraints for played role(rel0:role0) do not contain: @card(0..)
    Then entity(ent2) get constraints for played role(rel0:role0) do not contain: @card(0..1)
    Then entity(ent2) get constraints for played role(rel1:role1) contain: @card(2..2)
    Then entity(ent2) get constraints for played role(rel1:role1) do not contain: @card(0..1)
    Then entity(ent2) get constraints for played role(rel1:role1) contain: @card(0..)
    Then entity(ent2) get constraints for played role(rel1:role2) contain: @card(2..2)
    Then entity(ent2) get constraints for played role(rel1:role2) contain: @card(0..)
    Then entity(ent2) get constraints for played role(rel1:role2) do not contain: @card(0..1)
    Then transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $rel1 = relation(rel2) get instance with key(ref): rel1
    When relation $rel1 remove player for role(role1): $ent2
    When relation $rel1 remove player for role(role2): $ent2
    Then transaction commits; fails with a message containing: "@card"

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $rel1 = relation(rel2) get instance with key(ref): rel1
    When relation $rel1 remove player for role(role2): $ent2
    Then transaction commits; fails with a message containing: "@card"

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $rel1 = relation(rel2) get instance with key(ref): rel1
    When relation $rel1 remove player for role(role1): $ent2
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When relation(rel1) get role(role1) unset specialise
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When relation(rel1) get role(role2) unset specialise
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When relation(rel1) get role(role1) set specialise: role00
    Then transaction commits; fails with a message containing: "@card"

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $rel1 = relation(rel2) get instance with key(ref): rel1
    When $rel2 = relation(rel2) get instance with key(ref): rel2
    When relation $rel1 remove player for role(role1): $ent2
    When relation $rel2 add player for role(role2): $ent2
    Then transaction commits

    When connection open schema transaction for database: typedb
    Then relation(rel1) get role(role1) set specialise: role00
    When transaction commits

    When connection open schema transaction for database: typedb
    When relation(rel1) get role(role2) set specialise: role00
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent0) get plays(rel0:role0) set annotation: @card(0..1)
    Then transaction commits; fails with a message containing: "@card(0..1)"

    When connection open schema transaction for database: typedb
    When entity(ent0) get plays(rel0:role0) set annotation: @card(0..2)
    When entity(ent2) set plays: rel0:role00
    When entity(ent2) get plays(rel0:role00) set annotation: @card(0..1)
    Then transaction commits

    When connection open schema transaction for database: typedb
    When relation(rel1) get role(role2) set specialise: role00
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When relation(rel1) get role(role2) set specialise: role0
    Then transaction commits

    When connection open schema transaction for database: typedb
    When relation(rel1) get role(role2) set specialise: role00
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent2) get plays(rel0:role00) set annotation: @card(0..2)
    Then relation(rel1) get role(role2) set specialise: role00
    When entity(ent2) get plays(rel0:role00) set annotation: @card(2..2)
    Then transaction commits

    When connection open schema transaction for database: typedb
    When relation(rel1) get role(role2) set specialise: role0
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent2) get plays(rel0:role00) set annotation: @card(1..2)
    Then transaction commits

    When connection open schema transaction for database: typedb
    When relation(rel1) get role(role2) set specialise: role0
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent2) get plays(rel0:role00) set annotation: @card(0..2)
    Then relation(rel1) get role(role2) set specialise: role0
    When entity(ent1) get plays(rel1:role1) set annotation: @card(0..1)
    Then transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $rel1 = relation(rel2) get instance with key(ref): rel1
    When $rel2 = relation(rel2) get instance with key(ref): rel2
    When relation $rel1 add player for role(role1): $ent2
    When relation $rel2 add player for role(role1): $ent2
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent1) get plays(rel1:role1) set annotation: @card(2..2)
    Then transaction commits; fails with a message containing: "@card(2..2)"

    When connection open schema transaction for database: typedb
    When entity(ent1) get plays(rel1:role1) set annotation: @card(1..2)
    Then transaction commits; fails with a message containing: "@card(1..2)"

    When connection open schema transaction for database: typedb
    When entity(ent1) get plays(rel1:role1) set annotation: @card(1..)
    Then transaction commits; fails with a message containing: "@card(1..)"

    When connection open schema transaction for database: typedb
    When entity(ent1) get plays(rel1:role1) set annotation: @card(0..2)
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $rel1 = relation(rel2) get instance with key(ref): rel1
    When $rel2 = relation(rel2) get instance with key(ref): rel2
    When relation $rel1 add player for role(role1): $ent2
    When relation $rel2 add player for role(role1): $ent2
    Then transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent0) get plays(rel0:role0) set annotation: @card(0..2)
    Then transaction commits

    When connection open schema transaction for database: typedb
    When relation(rel1) get role(role1) set specialise: role0
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent0) get plays(rel0:role0) set annotation: @card(2..3)
    Then transaction commits

    When connection open schema transaction for database: typedb
    When relation(rel1) get role(role1) set specialise: role0
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent0) get plays(rel0:role0) set annotation: @card(3..4)
    Then transaction commits; fails with a message containing: "@card(3..4)"

    When connection open schema transaction for database: typedb
    When entity(ent0) get plays(rel0:role0) set annotation: @card(2..4)
    Then relation(rel1) get role(role1) set specialise: role0
    Then transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $rel3 = relation(rel2) get instance with key(ref): rel3
    When relation $rel3 add player for role(role2): $ent2
    Then transaction commits; fails with a message containing: "@card"

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $rel3 = relation(rel2) get instance with key(ref): rel3
    When relation $rel3 add player for role(role2): $ent2
    When $rel2 = relation(rel2) get instance with key(ref): rel2
    When relation $rel2 remove player for role(role1): $ent2
    Then transaction commits

    When connection open schema transaction for database: typedb
    When relation(rel1) get role(role2) set specialise: role00
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    Then relation(rel1) get role(role1) set specialise: role00
    Then transaction commits

    When connection open schema transaction for database: typedb
    Then relation(rel1) get role(role2) set specialise: role00
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    Then relation(rel1) get role(role1) set specialise: role0
    Then transaction commits

    # Object type supertype changes validation

    When connection open schema transaction for database: typedb
    When create entity type: ent00
    When entity(ent00) set plays: rel0:role0
    When entity(ent00) set owns: ref
    When entity(ent00) get owns(ref) set annotation: @key
    When create entity type: ent11
    When entity(ent11) set owns: ref
    When entity(ent11) get owns(ref) set annotation: @key
    When entity(ent11) set plays: rel1:role1
    Then entity(ent00) get plays(rel0:role0) set annotation: @card(0..1)
    Then entity(ent11) get plays(rel1:role1) set annotation: @card(0..1)
    Then entity(ent00) get plays(rel0:role0) get cardinality: @card(0..1)
    Then entity(ent11) get plays(rel1:role1) get cardinality: @card(0..1)
    Then transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent2) set supertype: ent11
    Then transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $rel2 = relation(rel2) get instance with key(ref): rel2
    When relation $rel2 add player for role(role1): $ent2
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent2) set supertype: ent00; fails with a message containing: "instances"
    When entity(ent2) set supertype: ent1
    Then transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent11) get plays(rel1:role1) set annotation: @card(1..1)
    Then entity(ent11) get plays(rel1:role1) get cardinality: @card(1..1)
    When entity(ent2) set supertype: ent11
    Then transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $rel2 = relation(rel2) get instance with key(ref): rel2
    When relation $rel2 add player for role(role1): $ent2
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent2) set supertype: ent1
    Then transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent1) set supertype: ent00
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent00) get plays(rel0:role0) set annotation: @card(0..3)
    Then transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent1) set supertype: ent00
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent00) get plays(rel0:role0) set annotation: @card(3..4)
    Then entity(ent1) set supertype: ent00
    Then transaction commits

    When connection open schema transaction for database: typedb
    Then entity(ent1) set supertype: ent0
    Then transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent00) get plays(rel0:role0) set annotation: @card(0..3)
    Then transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent1) set supertype: ent00
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent00) unset plays: rel0:role0
    When entity(ent1) set supertype: ent00
    Then transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent00) set plays: rel0:role0
    Then entity(ent00) get plays(rel0:role0) set annotation: @card(0..1)
    Then transaction commits; fails with a message containing: "@card(0..1)"

    When connection open schema transaction for database: typedb
    When entity(ent0) get plays(rel0:role0) set annotation: @card(0..1)
    Then transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent1) set supertype: ent0
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent0) get plays(rel0:role0) set annotation: @card(0..)
    Then entity(ent1) set supertype: ent0
    Then transaction commits

    # Redeclaration with specialisation validation

    When connection open schema transaction for database: typedb
    When entity(ent1) set plays: rel0:role0
    When entity(ent1) get plays(rel0:role0) set annotation: @card(0..1)
    Then transaction commits; fails with a message containing: "@card(0..1)"

    When connection open schema transaction for database: typedb
    When entity(ent1) set plays: rel0:role0
    When entity(ent1) get plays(rel0:role0) set annotation: @card(0..10)
    Then transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent2) set plays: rel0:role0
    When entity(ent2) get plays(rel0:role0) set annotation: @card(0..10)
    When entity(ent1) unset plays: rel0:role0
    Then transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent2) unset plays: rel0:role0
    When entity(ent2) set plays: rel1:role1
    When entity(ent2) get plays(rel1:role1) set annotation: @card(2..)
    Then transaction commits; fails with a message containing: "@card(2..)"

    When connection open schema transaction for database: typedb
    When entity(ent2) unset plays: rel0:role0
    When entity(ent2) set plays: rel1:role1
    When entity(ent2) get plays(rel1:role1) set annotation: @card(1..)
    Then transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $rel1 = relation(rel2) get instance with key(ref): rel1
    When relation $rel1 remove player for role(role1): $ent2
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent2) get plays(rel1:role1) set annotation: @card(0..1)
    Then transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $rel1 = relation(rel2) get instance with key(ref): rel1
    When relation $rel1 remove player for role(role1): $ent2
    Then transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent0) get plays(rel0:role0) set annotation: @card(3..)
    Then transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $rel2 = relation(rel2) get instance with key(ref): rel2
    When $rel3 = relation(rel2) get instance with key(ref): rel3
    When relation $rel2 remove player for role(role2): $ent2
    When relation $rel3 remove player for role(role2): $ent2
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent0) get plays(rel0:role0) set annotation: @card(0..3)
    Then transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $rel2 = relation(rel2) get instance with key(ref): rel2
    When $rel3 = relation(rel2) get instance with key(ref): rel3
    When relation $rel2 remove player for role(role2): $ent2
    When relation $rel3 remove player for role(role2): $ent2
    Then transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent2) set plays: rel0:role0
    When entity(ent2) get plays(rel0:role0) set annotation: @card(1..)
    Then transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent2) get plays(rel0:role0) set annotation: @card(2..)
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent2) get plays(rel0:role0) set annotation: @card(1..1)
    Then transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $rel2 = relation(rel2) get instance with key(ref): rel2
    When relation $rel2 add player for role(role2): $ent2
    Then transaction commits; fails with a message containing: "@card"

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $rel1 = relation(rel2) get instance with key(ref): rel1
    When relation $rel1 add player for role(role1): $ent2
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent2) get plays(rel0:role0) set annotation: @card(0..5)
    When entity(ent0) get plays(rel0:role0) set annotation: @card(0..1)
    Then transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $rel2 = relation(rel2) get instance with key(ref): rel2
    When relation $rel2 add player for role(role2): $ent2
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent0) get plays(rel0:role0) set annotation: @card(0..2)
    Then transaction commits

    When connection open write transaction for database: typedb
    When $ent2 = entity(ent2) get instance with key(ref): ent2
    When $rel2 = relation(rel2) get instance with key(ref): rel2
    When relation $rel2 add player for role(role2): $ent2
    Then transaction commits


  Scenario: Cardinality is not validated if instance is deleted
    Given create attribute type: attr0
    Given attribute(attr0) set value type: string
    Given attribute(attr0) set annotation: @abstract
    Given create attribute type: attr1
    Given attribute(attr1) set supertype: attr0
    Given attribute(attr1) set annotation: @abstract
    Given create attribute type: attr2
    Given attribute(attr2) set supertype: attr1

    Given create attribute type: ref
    Given attribute(ref) set value type: string
    Given create entity type: ent
    Given entity(ent) set owns: ref
    Given entity(ent) get owns(ref) set annotation: @key
    Given entity(ent) set owns: attr0
    Given entity(ent) set owns: attr1
    Given entity(ent) set owns: attr2

    Given entity(ent) get owns(attr0) set annotation: @card(2..)
    Given entity(ent) get owns(attr1) set annotation: @card(3..3)
    Given entity(ent) get owns(attr2) set annotation: @card(1..)
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given $ent = entity(ent) create new instance with key(ref): "ent"
    Given $attr0 = attribute(attr2) put instance with value: "attr0"
    Given $attr1 = attribute(attr2) put instance with value: "attr1"
    Given $attr2 = attribute(attr2) put instance with value: "attr2"
    Given entity $ent set has: $attr0
    Given entity $ent set has: $attr1
    Given entity $ent set has: $attr2
    Given transaction commits

    When connection open schema transaction for database: typedb
    When $ent = entity(ent) get instance with key(ref): "ent"
    When delete entity: $ent
    Then transaction commits


  Scenario: Cardinality is not validated if owns is unset with the instances deletions
    Given create attribute type: attr0
    Given attribute(attr0) set value type: string
    Given attribute(attr0) set annotation: @abstract
    Given create attribute type: attr1
    Given attribute(attr1) set supertype: attr0
    Given attribute(attr1) set annotation: @abstract
    Given create attribute type: attr2
    Given attribute(attr2) set supertype: attr1

    Given create attribute type: ref
    Given attribute(ref) set value type: string
    Given create entity type: ent
    Given entity(ent) set owns: ref
    Given entity(ent) get owns(ref) set annotation: @key
    Given entity(ent) set owns: attr0
    Given entity(ent) set owns: attr1
    Given entity(ent) set owns: attr2

    Given entity(ent) get owns(attr0) set annotation: @card(2..)
    Given entity(ent) get owns(attr1) set annotation: @card(3..3)
    Given entity(ent) get owns(attr2) set annotation: @card(1..)
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given $ent = entity(ent) create new instance with key(ref): "ent"
    Given $attr0 = attribute(attr2) put instance with value: "attr0"
    Given $attr1 = attribute(attr2) put instance with value: "attr1"
    Given $attr2 = attribute(attr2) put instance with value: "attr2"
    Given entity $ent set has: $attr0
    Given entity $ent set has: $attr1
    Given entity $ent set has: $attr2
    Given transaction commits

    When connection open schema transaction for database: typedb
    When $ent = entity(ent) get instance with key(ref): "ent"
    When $attr = attribute(attr2) get instance with value: "attr0"
    When entity $ent unset has: $attr
    Then transaction commits; fails with a message containing: "@card(3..3)"

    When connection open schema transaction for database: typedb
    When $ent = entity(ent) get instance with key(ref): "ent"
    When $attr = attribute(attr2) get instance with value: "attr0"
    When entity $ent unset has: $attr
    When entity(ent) unset owns: attr0
    Then transaction commits; fails with a message containing: "@card(3..3)"

    When connection open schema transaction for database: typedb
    When $ent = entity(ent) get instance with key(ref): "ent"
    When $attr = attribute(attr2) get instance with value: "attr0"
    When entity $ent unset has: $attr
    When entity(ent) unset owns: attr1
    Then transaction commits

    When connection open schema transaction for database: typedb
    When $ent = entity(ent) get instance with key(ref): "ent"
    When $attr = attribute(attr2) get instance with value: "attr1"
    When entity $ent unset has: $attr
    Then transaction commits; fails with a message containing: "@card(2..)"

    When connection open schema transaction for database: typedb
    When $ent = entity(ent) get instance with key(ref): "ent"
    When $attr = attribute(attr2) get instance with value: "attr1"
    When entity $ent unset has: $attr
    When entity(ent) unset owns: attr0
    Then transaction commits

    When connection open schema transaction for database: typedb
    When $ent = entity(ent) get instance with key(ref): "ent"
    When $attr = attribute(attr2) get instance with value: "attr2"
    When entity $ent unset has: $attr
    Then transaction commits; fails with a message containing: "@card(1..)"

    When connection open schema transaction for database: typedb
    When $ent = entity(ent) get instance with key(ref): "ent"
    When $attr = attribute(attr2) get instance with value: "attr2"
    When entity $ent unset has: $attr
    When entity(ent) unset owns: attr2
    Then transaction commits


  Scenario: Cardinality is not validated if cardinality is unset to the default value with the owns unsetting
    Given create attribute type: attr0
    Given attribute(attr0) set value type: string
    Given attribute(attr0) set annotation: @abstract
    Given create attribute type: attr1
    Given attribute(attr1) set supertype: attr0

    Given create entity type: ent
    Given entity(ent) set owns: attr0
    Given entity(ent) set owns: attr1

    Given entity(ent) get owns(attr0) set annotation: @card(0..)
    Given entity(ent) get owns(attr1) set annotation: @card(2..)
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given $ent = entity(ent) create new instance
    Given $attr0 = attribute(attr1) put instance with value: "attr0"
    Given $attr1 = attribute(attr1) put instance with value: "attr1"
    Given entity $ent set has: $attr0
    Given entity $ent set has: $attr1
    Given transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent) get owns(attr0) unset annotation: @card
    Then entity(ent) get owns(attr0) get cardinality: @card(0..1)
    Then transaction commits; fails with a message containing: "@card(0..1)"

    When connection open schema transaction for database: typedb
    When entity(ent) get owns(attr0) unset annotation: @card
    Then entity(ent) get owns(attr0) get cardinality: @card(0..1)
    When entity(ent) unset owns: attr0
    Then transaction commits


  Scenario Outline: Cardinality is correctly revalidated if interface unsets a supertype and does no more satisfy its constraint
    Given create attribute type: attr0
    Given attribute(attr0) set value type: string
    Given attribute(attr0) set annotation: @abstract
    Given create attribute type: attr1
    Given attribute(attr1) set supertype: attr0
    Given attribute(attr1) set annotation: @abstract
    Given create attribute type: attr2
    Given attribute(attr2) set supertype: attr1

    Given create entity type: ent
    Given entity(ent) set owns: attr0
    Given entity(ent) set owns: attr1
    Given entity(ent) set owns: attr2

    Given entity(ent) get owns(attr0) set annotation: @card(<card0>)
    Given entity(ent) get owns(attr1) set annotation: @card(<card1>)
    Given entity(ent) get owns(attr2) set annotation: @card(0..)
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given $ent = entity(ent) create new instance
    Given $attr0 = attribute(attr2) put instance with value: "attr0"
    Given $attr1 = attribute(attr2) put instance with value: "attr1"
    Given entity $ent set has: $attr0
    Given entity $ent set has: $attr1
    Given transaction commits

    When connection open schema transaction for database: typedb
    When attribute(attr2) set value type: string
    When attribute(attr2) unset supertype
    Then transaction commits<opt-error>
    Examples:
      | card0 | card1 | opt-error                                       |
      | 2..   | 0..   | ; fails with a message containing: "@card(2..)" |
      | 0..   | 1..   | ; fails with a message containing: "@card(1..)" |
      | 2..   | 1..   | ; fails with a message containing: "@card"      |
      | 0..   | 0..   |                                                 |


  Scenario Outline: Cardinality is correctly revalidated if interface subtyping hierarchy is split to multiple segments
    Given create attribute type: attr0
    Given attribute(attr0) set value type: string
    Given attribute(attr0) set annotation: @abstract
    Given create attribute type: attr1
    Given attribute(attr1) set supertype: attr0
    Given attribute(attr1) set annotation: @abstract
    Given create attribute type: attr2
    Given attribute(attr2) set supertype: attr1
    Given attribute(attr2) set annotation: @abstract
    Given create attribute type: attr3
    Given attribute(attr3) set supertype: attr2
    Given attribute(attr3) set annotation: @abstract
    Given create attribute type: attr4
    Given attribute(attr4) set supertype: attr3

    Given create entity type: ent0
    Given entity(ent0) set owns: attr0
    Given entity(ent0) set owns: attr1
    Given create entity type: ent1
    Given entity(ent1) set owns: attr2
    Given entity(ent1) set owns: attr3
    Given entity(ent1) set owns: attr4
    Given entity(ent1) set supertype: ent0

    Given entity(ent0) get owns(attr0) set annotation: @card(<card0>)
    Given entity(ent0) get owns(attr1) set annotation: @card(<card1>)
    Given entity(ent1) get owns(attr2) set annotation: @card(<card2>)
    Given entity(ent1) get owns(attr3) set annotation: @card(<card3>)
    Given entity(ent1) get owns(attr4) set annotation: @card(<card4>)
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given $ent = entity(ent1) create new instance
    Given $attr0 = attribute(attr4) put instance with value: "attr0"
    Given $attr1 = attribute(attr4) put instance with value: "attr1"
    Given entity $ent set has: $attr0
    Given entity $ent set has: $attr1
    Given transaction commits

    Given connection open schema transaction for database: typedb
    When attribute(attr4) set value type: string
    When attribute(attr4) unset supertype
    When attribute(attr2) set value type: string
    When attribute(attr2) unset supertype
    Then transaction commits<opt-error>
    Examples:
      | card0 | card1 | card2 | card3 | card4 | opt-error                                        |
      | 2..   | 0..   | 0..   | 0..   | 0..   | ; fails with a message containing: "@card(2..)"  |
      | 0..   | 1..   | 0..   | 0..   | 0..   | ; fails with a message containing: "@card(1..)"  |
      | 0..   | 0..   | 2..2  | 0..   | 0..   | ; fails with a message containing: "@card(2..2)" |
      | 0..   | 0..   | 0..   | 2..3  | 0..   | ; fails with a message containing: "@card(2..3)" |
      | 0..10 | 0..3  | 0..5  | 0..   | 2..   |                                                  |


  Scenario Outline: Cardinality is correctly revalidated if interface subtyping hierarchy is split to multiple segments with partial owns unsetting: <unset-owns-ent-1>-><unset-owns-attr-1> and <unset-owns-ent-2>-><unset-owns-attr-2>
    Given create attribute type: attr0
    Given attribute(attr0) set value type: string
    Given attribute(attr0) set annotation: @abstract
    Given create attribute type: attr1
    Given attribute(attr1) set supertype: attr0
    Given attribute(attr1) set annotation: @abstract
    Given create attribute type: attr2
    Given attribute(attr2) set supertype: attr1
    Given attribute(attr2) set annotation: @abstract
    Given create attribute type: attr3
    Given attribute(attr3) set supertype: attr2
    Given attribute(attr3) set annotation: @abstract
    Given create attribute type: attr4
    Given attribute(attr4) set supertype: attr3

    Given create entity type: ent0
    Given entity(ent0) set owns: attr0
    Given entity(ent0) set owns: attr1
    Given create entity type: ent1
    Given entity(ent1) set owns: attr2
    Given entity(ent1) set owns: attr3
    Given entity(ent1) set owns: attr4
    Given entity(ent1) set supertype: ent0

    Given entity(ent0) get owns(attr0) set annotation: @card(<card0>)
    Given entity(ent0) get owns(attr1) set annotation: @card(<card1>)
    Given entity(ent1) get owns(attr2) set annotation: @card(<card2>)
    Given entity(ent1) get owns(attr3) set annotation: @card(<card3>)
    Given entity(ent1) get owns(attr4) set annotation: @card(<card4>)
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given $ent = entity(ent1) create new instance
    Given $attr0 = attribute(attr4) put instance with value: "attr0"
    Given $attr1 = attribute(attr4) put instance with value: "attr1"
    Given entity $ent set has: $attr0
    Given entity $ent set has: $attr1
    Given transaction commits

    Given connection open schema transaction for database: typedb
    When attribute(attr4) set value type: string
    When attribute(attr4) unset supertype
    When attribute(attr2) set value type: string
    When attribute(attr2) unset supertype
    When entity(<unset-owns-ent-1>) unset owns: <unset-owns-attr-1>
    When entity(<unset-owns-ent-2>) unset owns: <unset-owns-attr-2>
    Then transaction commits<opt-error>
    Examples:
      | card0 | card1 | card2 | card3 | card4 | unset-owns-ent-1 | unset-owns-attr-1 | unset-owns-ent-2 | unset-owns-attr-2 | opt-error                                        |
      | 2..   | 0..   | 0..   | 0..   | 0..   | ent0             | attr1             | ent1             | attr2             | ; fails with a message containing: "@card(2..)"  |
      | 2..   | 0..   | 0..   | 0..   | 0..   | ent0             | attr1             | ent1             | attr3             | ; fails with a message containing: "@card(2..)"  |
      | 2..   | 0..   | 0..   | 0..   | 0..   | ent1             | attr2             | ent1             | attr3             | ; fails with a message containing: "@card(2..)"  |
      | 2..   | 0..   | 0..   | 0..   | 0..   | ent0             | attr0             | ent1             | attr3             |                                                  |
      | 0..   | 1..   | 0..   | 0..   | 0..   | ent0             | attr0             | ent1             | attr2             | ; fails with a message containing: "@card(1..)"  |
      | 0..   | 1..   | 0..   | 0..   | 0..   | ent0             | attr1             | ent1             | attr2             |                                                  |
      | 0..   | 0..   | 2..2  | 0..   | 0..   | ent0             | attr1             | ent1             | attr3             | ; fails with a message containing: "@card(2..2)" |
      | 0..   | 0..   | 2..2  | 0..   | 0..   | ent0             | attr1             | ent1             | attr2             |                                                  |
      | 0..   | 0..   | 0..   | 2..3  | 0..   | ent0             | attr1             | ent1             | attr2             | ; fails with a message containing: "@card(2..3)" |
      | 0..   | 0..   | 0..   | 2..3  | 0..   | ent0             | attr1             | ent1             | attr3             |                                                  |
      | 0..10 | 0..3  | 0..5  | 0..   | 2..   | ent0             | attr1             | ent1             | attr2             |                                                  |


  Scenario Outline: Cardinality is correctly revalidated if interface subtyping hierarchy is split to multiple segments with partial instances deletion
    Given create attribute type: attr0
    Given attribute(attr0) set value type: string
    Given attribute(attr0) set annotation: @abstract
    Given create attribute type: attr1
    Given attribute(attr1) set supertype: attr0
    Given attribute(attr1) set annotation: @abstract
    Given create attribute type: attr2
    Given attribute(attr2) set supertype: attr1
    Given attribute(attr2) set annotation: @abstract
    Given create attribute type: attr3
    Given attribute(attr3) set supertype: attr2
    Given attribute(attr3) set annotation: @abstract
    Given create attribute type: attr4
    Given attribute(attr4) set supertype: attr3

    Given create attribute type: ref
    Given attribute(ref) set value type: string
    Given create entity type: ent0
    Given entity(ent0) set owns: ref
    Given entity(ent0) get owns(ref) set annotation: @key
    Given entity(ent0) set owns: attr0
    Given entity(ent0) set owns: attr1
    Given create entity type: ent1
    Given entity(ent1) set owns: attr2
    Given entity(ent1) set owns: attr3
    Given entity(ent1) set owns: attr4
    Given entity(ent1) set supertype: ent0

    Given entity(ent0) get owns(attr0) set annotation: @card(<card0>)
    Given entity(ent0) get owns(attr1) set annotation: @card(<card1>)
    Given entity(ent1) get owns(attr2) set annotation: @card(<card2>)
    Given entity(ent1) get owns(attr3) set annotation: @card(<card3>)
    Given entity(ent1) get owns(attr4) set annotation: @card(<card4>)
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given $ent = entity(ent1) create new instance with key(ref): ent
    Given $attr0 = attribute(attr4) put instance with value: "attr0"
    Given $attr1 = attribute(attr4) put instance with value: "attr1"
    Given entity $ent set has: $attr0
    Given entity $ent set has: $attr1
    Given transaction commits

    Given connection open schema transaction for database: typedb
    When $ent = entity(ent1) get instance with key(ref): ent
    When $attr = attribute(attr4) get instance with value: "attr0"
    When entity $ent unset has: $attr
    When attribute(attr4) set value type: string
    When attribute(attr4) unset supertype
    When attribute(attr2) set value type: string
    When attribute(attr2) unset supertype
    Then transaction commits<opt-error>
    Examples:
      | card0 | card1 | card2 | card3 | card4 | opt-error                                        |
      | 2..   | 0..   | 0..   | 0..   | 0..   | ; fails with a message containing: "@card(2..)"  |
      | 1..   | 0..   | 0..   | 0..   | 0..   | ; fails with a message containing: "@card(1..)"  |
      | 0..   | 1..   | 0..   | 0..   | 0..   | ; fails with a message containing: "@card(1..)"  |
      | 0..   | 0..   | 2..3  | 0..   | 0..   | ; fails with a message containing: "@card(2..3)" |
      | 0..   | 0..   | 0..   | 2..5  | 0..   | ; fails with a message containing: "@card(2..5)" |
      | 0..   | 0..   | 0..   | 1..5  | 0..   | ; fails with a message containing: "@card(1..5)" |
      | 0..10 | 0..3  | 0..5  | 0..   | 2..   | ; fails with a message containing: "@card(2..)"  |
      | 0..10 | 0..3  | 0..5  | 0..   | 1..   |                                                  |
      | 0..10 | 0..3  | 0..5  | 0..   | 0..   |                                                  |


  Scenario: Cardinality is correctly revalidated when the owner type gets new owns from a new supertype with their partial deletion
    Given create attribute type: attr0
    Given attribute(attr0) set value type: string
    Given attribute(attr0) set annotation: @abstract
    Given create attribute type: attr1
    Given attribute(attr1) set supertype: attr0
    Given attribute(attr1) set annotation: @abstract
    Given create attribute type: attr2
    Given attribute(attr2) set supertype: attr1
    Given attribute(attr2) set annotation: @abstract
    Given create attribute type: attr3
    Given attribute(attr3) set supertype: attr2
    Given attribute(attr3) set annotation: @abstract
    Given create attribute type: attr4
    Given attribute(attr4) set supertype: attr3

    Given create entity type: ent0
    Given entity(ent0) set owns: attr0
    Given entity(ent0) set owns: attr1
    Given entity(ent0) set owns: attr2
    Given create entity type: ent1
    Given entity(ent1) set owns: attr3
    Given entity(ent1) set owns: attr4

    Given entity(ent0) get owns(attr1) set annotation: @card(1..2)
    Given entity(ent0) get owns(attr2) set annotation: @card(2..)
    Given entity(ent1) get owns(attr3) set annotation: @card(0..5)
    Given entity(ent1) get owns(attr4) set annotation: @card(0..12893)
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given $ent = entity(ent1) create new instance
    Given $attr0 = attribute(attr4) put instance with value: "attr0"
    Given $attr1 = attribute(attr4) put instance with value: "attr1"
    Given entity $ent set has: $attr0
    Given entity $ent set has: $attr1
    Given transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent1) set supertype: ent0
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent1) set supertype: ent0
    When entity(ent0) unset owns: attr2
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent1) set supertype: ent0
    When entity(ent0) unset owns: attr1
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent1) set supertype: ent0
    When entity(ent0) unset owns: attr0
    Then transaction commits


  Scenario: Cardinality is correctly revalidated between multiple instances when the owner type gets new owns from a new supertype with their partial deletion
    Given create attribute type: attr0
    Given attribute(attr0) set value type: string
    Given attribute(attr0) set annotation: @abstract
    Given create attribute type: attr1
    Given attribute(attr1) set supertype: attr0
    Given attribute(attr1) set annotation: @abstract
    Given create attribute type: attr2
    Given attribute(attr2) set supertype: attr1
    Given attribute(attr2) set annotation: @abstract
    Given create attribute type: attr3
    Given attribute(attr3) set supertype: attr2
    Given attribute(attr3) set annotation: @abstract
    Given create attribute type: attr4
    Given attribute(attr4) set supertype: attr3

    Given create entity type: ent0
    Given entity(ent0) set owns: attr0
    Given entity(ent0) set owns: attr1
    Given entity(ent0) set owns: attr2
    Given create entity type: ent1
    Given entity(ent1) set owns: attr3
    Given entity(ent1) set owns: attr4

    Given entity(ent0) get owns(attr1) set annotation: @card(1..2)
    Given entity(ent0) get owns(attr2) set annotation: @card(2..)
    Given entity(ent1) get owns(attr3) set annotation: @card(0..5)
    Given entity(ent1) get owns(attr4) set annotation: @card(0..12893)
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given $ent0 = entity(ent1) create new instance
    Given $attr0 = attribute(attr4) put instance with value: "attr0"
    Given $attr1 = attribute(attr4) put instance with value: "attr1"
    Given entity $ent0 set has: $attr0
    Given entity $ent0 set has: $attr1
    Given $ent1 = entity(ent1) create new instance
    Given entity $ent1 set has: $attr0
    Given transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent1) set supertype: ent0
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent1) set supertype: ent0
    When entity(ent0) unset owns: attr2
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent1) set supertype: ent0
    When entity(ent0) unset owns: attr1
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent1) set supertype: ent0
    When entity(ent0) unset owns: attr0
    Then transaction commits; fails with a message containing: "@card"

    When connection open schema transaction for database: typedb
    When entity(ent1) set supertype: ent0
    When entity(ent0) unset owns: attr0
    When entity(ent0) unset owns: attr2
    Then transaction commits


  Scenario Outline: Cardinality is correctly revalidated if instance deletion is combined with owns unsetting: attr0 card(<card0>), attr1 card(<card1>), unset-owns(<unset-owns-attr>)
    Given create attribute type: attr0
    Given attribute(attr0) set value type: string
    Given attribute(attr0) set annotation: @abstract
    Given create attribute type: attr1
    Given attribute(attr1) set supertype: attr0
    Given attribute(attr1) set annotation: @abstract
    Given create attribute type: attr2
    Given attribute(attr2) set supertype: attr1

    Given create attribute type: ref
    Given attribute(ref) set value type: string
    Given create entity type: ent
    Given entity(ent) set owns: ref
    Given entity(ent) get owns(ref) set annotation: @key
    Given entity(ent) set owns: attr0
    Given entity(ent) set owns: attr1
    Given entity(ent) set owns: attr2
    Given entity(ent) get owns(attr0) set annotation: @card(<card0>)
    Given entity(ent) get owns(attr1) set annotation: @card(<card1>)
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given $ent = entity(ent) create new instance with key(ref): "ent"
    Given $attr = attribute(attr2) put instance with value: "attr0"
    Given entity $ent set has: $attr
    Given transaction commits

    When connection open schema transaction for database: typedb
    When $ent = entity(ent) get instance with key(ref): "ent"
    When $attr = attribute(attr2) get instance with value: "attr0"
    When entity $ent unset has: $attr
    When entity(ent) unset owns: <unset-owns-attr>
    Then transaction commits<opt-error>
    Examples:
      | card0 | card1 | unset-owns-attr | opt-error                                        |
      | 1..   | 0..   | attr0           |                                                  |
      | 1..   | 0..   | attr1           | ; fails with a message containing: "@card(1..)"  |
      | 0..   | 1..   | attr0           | ; fails with a message containing: "@card(1..)"  |
      | 0..   | 1..   | attr1           |                                                  |
      | 1..   | 1..1  | attr0           | ; fails with a message containing: "@card(1..1)" |
      | 1..   | 1..1  | attr1           | ; fails with a message containing: "@card(1..)"  |
      | 0..   | 0..   | attr0           |                                                  |
      | 0..   | 0..   | attr1           |                                                  |


  Scenario Outline: Cardinality is correctly revalidated when owns is specialised on a supertype with @card(<card>)
    Given create attribute type: attr
    Given attribute(attr) set value type: string

    Given create entity type: ent0
    Given create entity type: ent1
    Given entity(ent1) set supertype: ent0
    Given entity(ent1) set owns: attr
    Given entity(ent1) get owns(attr) set annotation: @card(2..2)
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given $ent = entity(ent1) create new instance
    Given $attr0 = attribute(attr) put instance with value: "attr0"
    Given $attr1 = attribute(attr) put instance with value: "attr1"
    Given entity $ent set has: $attr0
    Given entity $ent set has: $attr1
    Given transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent0) set owns: attr
    When entity(ent0) get owns(attr) set annotation: @card(<card>)
    Then transaction commits<opt-error>
    Examples:
      | card | opt-error                                        |
      | 0..  |                                                  |
      | 0..2 |                                                  |
      | 2..  |                                                  |
      | 1..1 | ; fails with a message containing: "@card(1..1)" |
      | 0..1 | ; fails with a message containing: "@card(0..1)" |
      | 3..  | ; fails with a message containing: "@card(3..)"  |


  Scenario: Cardinality is correctly revalidated when owns is specialised on a supertype with the default card
    Given create attribute type: attr
    Given attribute(attr) set value type: string

    Given create entity type: ent0
    Given create entity type: ent1
    Given entity(ent1) set supertype: ent0
    Given entity(ent1) set owns: attr
    Given entity(ent1) get owns(attr) set annotation: @card(2..2)
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given $ent = entity(ent1) create new instance
    Given $attr0 = attribute(attr) put instance with value: "attr0"
    Given $attr1 = attribute(attr) put instance with value: "attr1"
    Given entity $ent set has: $attr0
    Given entity $ent set has: $attr1
    Given transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent0) set owns: attr
    Then transaction commits; fails with a message containing: "@card(0..1)"


  Scenario Outline: Cardinality is correctly revalidated when owns is moved from a supertype @card(<super-card>) to a subtype @card(<sub-card>) with instances
    Given create attribute type: attr
    Given attribute(attr) set value type: string

    Given create entity type: ent0
    Given create entity type: ent1
    Given entity(ent0) set owns: attr
    Given entity(ent0) get owns(attr) set annotation: @card(<super-card>)
    Given entity(ent1) set supertype: ent0
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given $ent = entity(ent1) create new instance
    Given $attr0 = attribute(attr) put instance with value: "attr0"
    Given $attr1 = attribute(attr) put instance with value: "attr1"
    Given entity $ent set has: $attr0
    Given entity $ent set has: $attr1
    Given transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent1) set owns: attr
    When entity(ent1) get owns(attr) set annotation: @card(<sub-card>)
    When entity(ent0) unset owns: attr
    Then transaction commits<opt-error>
    Examples:
      | super-card | sub-card | opt-error                                       |
      | 2..        | 2..      |                                                 |
      | 2..        | 1..2     |                                                 |
      | 2..        | 3..      | ; fails with a message containing: "@card(3..)" |


  Scenario: Cardinality validation considers all instances of attribute type subtypes
    Given create attribute type: attr0
    Given attribute(attr0) set value type: string
    Given attribute(attr0) set annotation: @abstract
    Given attribute(attr0) set annotation: @independent
    Given create attribute type: attr1
    Given attribute(attr1) set supertype: attr0
    Given create attribute type: attr2
    Given attribute(attr2) set supertype: attr1
    Given create attribute type: attr3_0
    Given attribute(attr3_0) set supertype: attr2
    Given create attribute type: attr3_1
    Given attribute(attr3_1) set supertype: attr2

    Given create attribute type: ref
    Given attribute(ref) set value type: string
    Given create entity type: ent0
    Given create entity type: ent1
    Given entity(ent1) set supertype: ent0
    Given entity(ent0) set owns: ref
    Given entity(ent0) get owns(ref) set annotation: @key
    Given entity(ent0) set owns: attr0
    Given entity(ent0) set owns: attr1
    Given entity(ent1) set owns: attr2
    Given entity(ent1) set owns: attr3_0
    Given entity(ent1) set owns: attr3_1
    Given entity(ent0) get owns(attr0) set annotation: @card(3..6)
    Given entity(ent0) get owns(attr1) set annotation: @card(3..4)
    Given entity(ent1) get owns(attr2) set annotation: @card(0..)
    Given entity(ent1) get owns(attr3_0) set annotation: @card(1..)
    Given entity(ent1) get owns(attr3_1) set annotation: @card(2..)
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given $attr3_0_0 = attribute(attr3_0) put instance with value: "attr3_0_0"
    Given $attr3_0_1 = attribute(attr3_0) put instance with value: "attr3_0_1"
    Given $attr3_1_0 = attribute(attr3_1) put instance with value: "attr3_1_0"
    Given $attr3_1_1 = attribute(attr3_1) put instance with value: "attr3_1_1"
    Given $attr2 = attribute(attr2) put instance with value: "attr2"
    Given $attr1_0 = attribute(attr1) put instance with value: "attr1_0"
    Given $attr1_1 = attribute(attr1) put instance with value: "attr1_1"
    Given $attr1_2 = attribute(attr1) put instance with value: "attr1_2"
    Given transaction commits

    When connection open write transaction for database: typedb
    When $ent0 = entity(ent1) create new instance with key(ref): ent0
    When $attr3_1_0 = attribute(attr3_1) get instance with value: "attr3_1_0"
    When $attr3_1_1 = attribute(attr3_1) get instance with value: "attr3_1_1"
    When $attr1_0 = attribute(attr1) get instance with value: "attr1_0"
    When $attr1_1 = attribute(attr1) get instance with value: "attr1_1"
    When $attr1_2 = attribute(attr1) get instance with value: "attr1_2"
    When entity $ent0 set has: $attr1_0
    When entity $ent0 set has: $attr1_1
    When entity $ent0 set has: $attr1_2
    When entity $ent0 set has: $attr3_1_0
    When entity $ent0 set has: $attr3_1_1
    Then transaction commits; fails with a message containing: "@card"

    When connection open write transaction for database: typedb
    When $ent0 = entity(ent1) create new instance with key(ref): ent0
    When $attr3_0_0 = attribute(attr3_0) get instance with value: "attr3_0_0"
    When $attr3_1_0 = attribute(attr3_1) get instance with value: "attr3_1_0"
    When $attr3_1_1 = attribute(attr3_1) get instance with value: "attr3_1_1"
    When $attr1_0 = attribute(attr1) get instance with value: "attr1_0"
    When $attr1_1 = attribute(attr1) get instance with value: "attr1_1"
    When $attr1_2 = attribute(attr1) get instance with value: "attr1_2"
    When entity $ent0 set has: $attr1_0
    When entity $ent0 set has: $attr1_1
    When entity $ent0 set has: $attr1_2
    When entity $ent0 set has: $attr3_0_0
    When entity $ent0 set has: $attr3_1_0
    When entity $ent0 set has: $attr3_1_1
    Then transaction commits; fails with a message containing: "@card(3..4)"

    When connection open write transaction for database: typedb
    When $ent0 = entity(ent1) create new instance with key(ref): ent0
    When $attr3_0_0 = attribute(attr3_0) get instance with value: "attr3_0_0"
    When $attr3_0_1 = attribute(attr3_0) get instance with value: "attr3_0_1"
    When $attr1_0 = attribute(attr1) get instance with value: "attr1_0"
    When $attr1_1 = attribute(attr1) get instance with value: "attr1_1"
    When $attr1_2 = attribute(attr1) get instance with value: "attr1_2"
    When entity $ent0 set has: $attr1_0
    When entity $ent0 set has: $attr1_1
    When entity $ent0 set has: $attr1_2
    When entity $ent0 set has: $attr3_0_0
    When entity $ent0 set has: $attr3_0_1
    Then transaction commits; fails with a message containing: "@card"

    When connection open write transaction for database: typedb
    When $ent0 = entity(ent1) create new instance with key(ref): ent0
    When $attr3_0_0 = attribute(attr3_0) get instance with value: "attr3_0_0"
    When $attr3_0_1 = attribute(attr3_0) get instance with value: "attr3_0_1"
    When $attr3_1_0 = attribute(attr3_1) get instance with value: "attr3_1_0"
    When $attr3_1_1 = attribute(attr3_1) get instance with value: "attr3_1_1"
    When $attr1_0 = attribute(attr1) get instance with value: "attr1_0"
    When entity $ent0 set has: $attr1_0
    When entity $ent0 set has: $attr3_0_0
    When entity $ent0 set has: $attr3_0_1
    When entity $ent0 set has: $attr3_1_0
    When entity $ent0 set has: $attr3_1_1
    Then transaction commits; fails with a message containing: "@card(3..4)"

    When connection open write transaction for database: typedb
    When $ent0 = entity(ent1) create new instance with key(ref): ent0
    When $attr3_1_0 = attribute(attr3_1) get instance with value: "attr3_1_0"
    When $attr3_1_1 = attribute(attr3_1) get instance with value: "attr3_1_1"
    When $attr1_0 = attribute(attr1) get instance with value: "attr1_0"
    When entity $ent0 set has: $attr1_0
    When entity $ent0 set has: $attr3_1_0
    When entity $ent0 set has: $attr3_1_1
    Then transaction commits; fails with a message containing: "@card(1..)"

    When connection open write transaction for database: typedb
    When $ent0 = entity(ent1) create new instance with key(ref): ent0
    When $attr3_0_0 = attribute(attr3_0) get instance with value: "attr3_0_0"
    When $attr2 = attribute(attr2) get instance with value: "attr2"
    When $attr1_0 = attribute(attr1) get instance with value: "attr1_0"
    When entity $ent0 set has: $attr1_0
    When entity $ent0 set has: $attr2
    When entity $ent0 set has: $attr3_0_0
    Then transaction commits; fails with a message containing: "@card(2..)"

    When connection open write transaction for database: typedb
    When $ent0 = entity(ent1) create new instance with key(ref): ent0
    When $attr3_0_0 = attribute(attr3_0) get instance with value: "attr3_0_0"
    When $attr3_1_0 = attribute(attr3_1) get instance with value: "attr3_1_0"
    When $attr2 = attribute(attr2) get instance with value: "attr2"
    When $attr1_0 = attribute(attr1) get instance with value: "attr1_0"
    When entity $ent0 set has: $attr1_0
    When entity $ent0 set has: $attr2
    When entity $ent0 set has: $attr3_0_0
    When entity $ent0 set has: $attr3_1_0
    Then transaction commits; fails with a message containing: "@card(2..)"

    When connection open write transaction for database: typedb
    When $ent0 = entity(ent1) create new instance with key(ref): ent0
    When $attr3_0_0 = attribute(attr3_0) get instance with value: "attr3_0_0"
    When $attr3_1_0 = attribute(attr3_1) get instance with value: "attr3_1_0"
    When $attr3_1_1 = attribute(attr3_1) get instance with value: "attr3_1_1"
    When $attr1_0 = attribute(attr1) get instance with value: "attr1_0"
    When entity $ent0 set has: $attr1_0
    When entity $ent0 set has: $attr3_0_0
    When entity $ent0 set has: $attr3_1_0
    When entity $ent0 set has: $attr3_1_1
    When $ent1 = entity(ent1) create new instance with key(ref): ent1
    When entity $ent1 set has: $attr1_0
    When entity $ent1 set has: $attr3_1_0
    When entity $ent1 set has: $attr3_1_1
    Then transaction commits; fails with a message containing: "@card(1..)"

    When connection open write transaction for database: typedb
    When $ent0 = entity(ent1) create new instance with key(ref): ent0
    When $attr3_0_0 = attribute(attr3_0) get instance with value: "attr3_0_0"
    When $attr3_1_0 = attribute(attr3_1) get instance with value: "attr3_1_0"
    When $attr3_1_1 = attribute(attr3_1) get instance with value: "attr3_1_1"
    When $attr1_0 = attribute(attr1) get instance with value: "attr1_0"
    When entity $ent0 set has: $attr1_0
    When entity $ent0 set has: $attr3_0_0
    When entity $ent0 set has: $attr3_1_0
    When entity $ent0 set has: $attr3_1_1
    Then transaction commits

    When connection open write transaction for database: typedb
    When $ent0 = entity(ent1) get instance with key(ref): ent0
    When $attr3_1_1 = attribute(attr3_1) get instance with value: "attr3_1_1"
    When entity $ent0 unset has: $attr3_1_1
    Then transaction commits; fails with a message containing: "@card(2..)"

    When connection open write transaction for database: typedb
    When $ent0 = entity(ent1) get instance with key(ref): ent0
    When $attr3_0_0 = attribute(attr3_0) get instance with value: "attr3_0_0"
    When entity $ent0 unset has: $attr3_0_0
    Then transaction commits; fails with a message containing: "@card(1..)"

    When connection open write transaction for database: typedb
    When $ent0 = entity(ent1) get instance with key(ref): ent0
    When $attr2 = attribute(attr2) get instance with value: "attr2"
    When entity $ent0 set has: $attr2
    Then transaction commits; fails with a message containing: "@card(3..4)"

    When connection open schema transaction for database: typedb
    When entity(ent0) get owns(attr1) set annotation: @card(4..5)
    When $ent0 = entity(ent1) get instance with key(ref): ent0
    When $attr2 = attribute(attr2) get instance with value: "attr2"
    When entity $ent0 set has: $attr2
    Then transaction commits

    When connection open schema transaction for database: typedb
    When $ent0 = entity(ent1) get instance with key(ref): ent0
    When $attr1_0 = attribute(attr1) get instance with value: "attr1_0"
    When entity $ent0 unset has: $attr1_0
    Then transaction commits
