# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Schema migration

  Background:
    Given typedb starts
    Given connection opens with default authentication
    Given connection has been opened
    Given connection does not have any database
    Given connection create database: typedb
    Given connection open schema transaction for database: typedb


  Scenario: An ownership can be moved down one type, with data in place at the lower levels
    Given create attribute type: attr0
    Given attribute(attr0) set value type: string
    Given create entity type: ent0
    Given entity(ent0) set owns: attr0
    Given entity(ent0) get owns(attr0) set annotation: @key
    Given create entity type: ent1
    Given entity(ent1) set supertype: ent0
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given $ent1 = entity(ent1) create new instance
    Given $attr0 = attribute(attr0) put instance with value: "attr0"
    Given entity $ent1 set has: $attr0
    Given transaction commits

    Given connection open schema transaction for database: typedb
    When entity(ent1) set owns: attr0
    When entity(ent1) get owns(attr0) set annotation: @unique
    Then transaction commits; fails

    Given connection open schema transaction for database: typedb
    When entity(ent1) set owns: attr0
    When entity(ent1) get owns(attr0) set override: attr0
    Then entity(ent1) get owns(attr0) set annotation: @unique; fails
    Given transaction closes

    Given connection open schema transaction for database: typedb
    When entity(ent1) set owns: attr0
    When entity(ent1) get owns(attr0) set annotation: @unique
    Then entity(ent1) get owns(attr0) set override: attr0; fails
    Given transaction closes

    Given connection open schema transaction for database: typedb
    Then entity(ent0) unset owns: attr0; fails
    Given transaction closes

    Given connection open schema transaction for database: typedb
    When entity(ent1) set owns: attr0
    When entity(ent1) get owns(attr0) set annotation: @key
    # Can't commit yet, because of the redundant declarations
    Then transaction commits; fails

    Given connection open schema transaction for database: typedb
    When entity(ent1) set owns: attr0
    When entity(ent1) get owns(attr0) set annotation: @key
    When entity(ent0) unset owns: attr0
    Then transaction commits


  Scenario: An ownership can be moved up one type, with data in place
    Given create attribute type: attr0
    Given attribute(attr0) set value type: string
    Given create entity type: ent0
    Given create entity type: ent1
    Given entity(ent1) set supertype: ent0
    Given entity(ent1) set owns: attr0
    Given entity(ent1) get owns(attr0) set annotation: @key
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given $ent1 = entity(ent1) create new instance
    Given $attr0 = attribute(attr0) put instance with value: "attr0"
    Given entity $ent1 set has: $attr0
    Given transaction commits

    Given connection open schema transaction for database: typedb

    When entity(ent0) set owns: attr0
    When entity(ent0) get owns(attr0) set annotation: @key
    # Can't commit yet, because of the redundant declarations
    Then transaction commits; fails

    Given connection open schema transaction for database: typedb
    When entity(ent0) set owns: attr0
    When entity(ent0) get owns(attr0) set annotation: @key
    When entity(ent1) unset owns: attr0
    Then transaction commits


  Scenario: A played role can be moved down one type, with data in place at the lower levels
    Given create relation type: rel0
    Given relation(rel0) create role: role0
    Given create entity type: ent0
    Given entity(ent0) set plays: rel0:role0
    Given create entity type: ent1
    Given entity(ent1) set supertype: ent0
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given $ent1 = entity(ent1) create new instance
    Given $rel0 = relation(rel0) create new instance
    Given relation $rel0 add player for role(role0): $ent1
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Then entity(ent0) unset plays: rel0:role0; fails
    Given transaction closes

    Given connection open schema transaction for database: typedb
    Then entity(ent1) set plays: rel0:role0
    Then entity(ent0) unset plays: rel0:role0
    Then transaction commits


  Scenario: A played role can be moved up one type, with data in place
    Given create relation type: rel0
    Given relation(rel0) create role: role0
    Given create entity type: ent0
    Given create entity type: ent1
    Given entity(ent1) set supertype: ent0
    Given entity(ent1) set plays: rel0:role0
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given $ent1 = entity(ent1) create new instance
    Given $rel0 = relation(rel0) create new instance
    Given relation $rel0 add player for role(role0): $ent1
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Then entity(ent0) set plays: rel0:role0
    Then entity(ent1) unset plays: rel0:role0
    Then transaction commits


  Scenario: A type moved with ownership instances in-place by re-declaring ownerships
    Given create attribute type: attr0
    Given attribute(attr0) set value type: string
    Given create entity type: ent0
    Given entity(ent0) set owns: attr0
    Given entity(ent0) get owns(attr0) set annotation: @key
    Given create entity type: ent1
    Given entity(ent1) set supertype: ent0
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given $ent1 = entity(ent1) create new instance
    Given $attr0 = attribute(attr0) put instance with value: "attr0"
    Given entity $ent1 set has: $attr0
    Given transaction commits

    Given connection open schema transaction for database: typedb

    # Should break
    Then entity(ent1) unset supertype; fails
    Given transaction closes

    Given connection open schema transaction for database: typedb
    Then entity(ent1) set owns: attr0
    Then entity(ent1) get owns(attr0) set annotation: @key
    Then entity(ent1) unset supertype
    Then transaction commits


  Scenario: An entity type moved with plays instances in-place by re-declaring played roles
    Given create relation type: rel0
    Given relation(rel0) create role: role0
    Given create entity type: player0
    Given entity(player0) set plays: rel0:role0
    Given create entity type: player1
    Given entity(player1) set supertype: player0
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given $player1 = entity(player1) create new instance
    Given $rel0 = relation(rel0) create new instance
    Given relation $rel0 add player for role(role0): $player1
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Then entity(player1) unset supertype; fails
    Given transaction closes

    Given connection open schema transaction for database: typedb
    Then entity(player1) set plays: rel0:role0
    Then entity(player1) unset supertype
    Then transaction commits


  Scenario: A relation type moved with plays instances in-place by re-declaring played roles RELATION
    Given create relation type: rel0
    Given relation(rel0) create role: role0
    Given create relation type: player0
    Given relation(player0) create role: to-exist
    Given relation(player0) set plays: rel0:role0
    Given create relation type: player1
    Given relation(player1) create role: to-exist2
    Given relation(player1) set supertype: player0
    Given relation(rel0) set plays: player1:to-exist2
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given $player1 = relation(player1) create new instance
    Given $rel0 = relation(rel0) create new instance
    Given relation $rel0 add player for role(role0): $player1
    Given relation $player1 add player for role(to-exist2): $rel0
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Then relation(player1) unset supertype; fails
    Given transaction closes

    Given connection open schema transaction for database: typedb
    Then relation(player1) set plays: rel0:role0
    Then relation(player1) unset supertype
    Then transaction commits


  Scenario: A type can be inserted into an existing hierarchy which has data in place
    Given create relation type: rel
    Given relation(rel) create role: role0
    Given create attribute type: attr
    Given attribute(attr) set value type: string
    Given create entity type: ent0
    Given entity(ent0) set plays: rel:role0
    Given entity(ent0) set owns: attr
    Given entity(ent0) get owns(attr) set annotation: @key
    Given create entity type: ent1
    Given entity(ent1) set supertype: ent0
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given $ent1 = entity(ent1) create new instance with key(attr): "ent1"
    Given $rel = relation(rel) create new instance
    Given relation $rel add player for role(role0): $ent1
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Then create entity type: ent05
    Then entity(ent05) set supertype: ent0
    Then entity(ent1) set supertype: ent05
    Then transaction commits


  Scenario: A type can be removed from an existing hierarchy which has data in place
    Given create relation type: rel
    Given relation(rel) create role: role0
    Given create attribute type: attr
    Given attribute(attr) set value type: string
    Given create entity type: ent0
    Given entity(ent0) set plays: rel:role0
    Given entity(ent0) set owns: attr
    Given entity(ent0) get owns(attr) set annotation: @key
    Given create entity type: ent05
    Given entity(ent05) set supertype: ent0
    Given create entity type: ent1
    Given entity(ent1) set supertype: ent05
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given $ent1 = entity(ent1) create new instance with key(attr): "ent1"
    Given $rel = relation(rel) create new instance
    Given relation $rel add player for role(role0): $ent1
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Then entity(ent1) set supertype: ent0
    Then delete entity type: ent05
    Then transaction commits


  Scenario: Attribute types can be split in two, with instances and ownerships migrated to subtypes
    Given create attribute type: name
    Given attribute(name) set value type: string
    Given create entity type: being
    Given entity(being) set annotation: @abstract
    Given entity(being) set owns: name
    Given entity(being) get owns(name) set annotation: @key
    Given create entity type: person
    Given entity(person) set supertype: being
    Given create entity type: dog
    Given entity(dog) set supertype: being
    Given transaction commits
    Given connection open write transaction for database: typedb
    Given $john = entity(person) create new instance with key(name): "john"
    Given $scooby = entity(dog) create new instance with key(name): "scooby"
    Given transaction commits

    When connection open schema transaction for database: typedb
    When create attribute type: dog-name
    Given attribute(dog-name) set value type: string
    When create attribute type: person-name
    Given attribute(person-name) set value type: string
    When entity(person) set owns: person-name
    When entity(dog) set owns: dog-name
    Then transaction commits
    When connection open write transaction for database: typedb
    When $p = entity(person) get instance with key(name): "john"
    When $pn = attribute(person-name) put instance with value: "john"
    When entity $p set has: $pn
    When $d = entity(dog) get instance with key(name): "scooby"
    When $dn = attribute(dog-name) put instance with value: "scooby"
    When entity $d set has: $dn
    Then transaction commits
    When connection open schema transaction for database: typedb
    # adjust annotations
    When entity(person) set owns: person-name
    When entity(person) get owns(person-name) set annotation: @key
    When entity(dog) set owns: dog-name
    When entity(dog) get owns(dog-name) set annotation: @key
    When entity(being) get owns(name) unset annotation: @key
    Then transaction commits

    When connection open write transaction for database: typedb
    When delete attributes of type: name
    Then transaction commits

    When connection open schema transaction for database: typedb
    When attribute(name) set annotation: @abstract
    When attribute(person-name) set supertype: name
    When attribute(dog-name) set supertype: name
    When attribute(dog-name) unset value type
    When attribute(person-name) unset value type
    When entity(person) set owns: person-name
    When entity(person) get owns(person-name) set annotation: @key
    When entity(person) get owns(person-name) set override: name
    When entity(dog) set owns: dog-name
    When entity(dog) get owns(dog-name) set override: name
    Then transaction commits


  Scenario: Owner types can be split in two, with instances and ownerships migrated to subtypes
    Given create attribute type: male-specific
    Given attribute(male-specific) set value type: string
    Given create attribute type: female-specific
    Given attribute(female-specific) set value type: string
    Given create attribute type: gender
    Given attribute(gender) set value type: string
    Given create attribute type: common
    Given attribute(common) set value type: string
    Given create entity type: person
    Given entity(person) set owns: gender
    Given entity(person) set owns: common
    Given entity(person) set owns: male-specific
    Given entity(person) set owns: female-specific
    Given transaction commits
    Given connection open write transaction for database: typedb
    When $alice = entity(person) create new instance
    When $gender1 = attribute(gender) put instance with value: "F"
    When $common1 = attribute(common) put instance with value: "c-alice"
    When $specific1 = attribute(female-specific) put instance with value: "f-alice"
    When entity $alice set has: $gender1
    When entity $alice set has: $common1
    When entity $alice set has: $specific1
    When $bob = entity(person) create new instance
    When $gender2 = attribute(gender) put instance with value: "M"
    When $common2 = attribute(common) put instance with value: "c-bob"
    When $specific2 = attribute(male-specific) put instance with value: "m-bob"
    When entity $bob set has: $gender2
    When entity $bob set has: $common2
    When entity $bob set has: $specific2
    Given transaction commits

    When connection open schema transaction for database: typedb
    When create entity type: male
    When entity(male) set supertype: person
    When create entity type: female
    When entity(female) set supertype: person
    Then transaction commits

    When connection open write transaction for database: typedb
    When $specific1 = attribute(male-specific) get instance with value: "m-bob"
    When $common1 = attribute(common) get instance with value: "c-bob"
    When $m = entity(male) create new instance
    When entity $m set has: $specific1
    When entity $m set has: $common1
    When $specific2 = attribute(female-specific) get instance with value: "f-alice"
    When $common2 = attribute(common) get instance with value: "c-alice"
    When $f = entity(female) create new instance
    When entity $f set has: $specific2
    When entity $f set has: $common2
    When delete entities of type: person
    When delete attributes of type: gender
    Then transaction commits

    When connection open schema transaction for database: typedb
    When entity(male) set owns: male-specific
    When entity(female) set owns: female-specific
    When entity(person) unset owns: male-specific
    When entity(person) unset owns: female-specific
    When entity(person) set annotation: @abstract
    When delete attribute type: gender
    Then transaction commits

  Scenario: Attribute type cannot change supertype while implicitly losing @independent annotation with data
    When create attribute type: literal
    When create attribute type: word
    When create attribute type: name
    When attribute(literal) set annotation: @abstract
    When attribute(literal) set annotation: @independent
    When attribute(word) set annotation: @abstract
    When attribute(name) set value type: string
    When attribute(name) set supertype: word
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get supertype: word
    When attribute(name) set supertype: literal
    When transaction commits
    Given connection open write transaction for database: typedb
    Given attribute(name) put instance with value: "stopper"
    Given transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get supertype: literal
    Then attribute(name) set supertype: word; fails
    When attribute(name) set annotation: @independent
    When attribute(name) set supertype: word
    When attribute(name) unset annotation: @independent
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(name) get supertype: word
    Then attribute(name) get annotations do not contain: @independent
    When $name = attribute(name) get instance with value: "stopper"
    Then attribute $name does not exist

  Scenario: Attribute type cannot change supertype while implicitly losing @independent annotation with subtype data
    When create attribute type: literal
    When create attribute type: word
    When create attribute type: name
    When create attribute type: surname
    When attribute(literal) set annotation: @abstract
    When attribute(literal) set annotation: @independent
    When attribute(word) set annotation: @abstract
    When attribute(name) set value type: string
    When attribute(name) set supertype: word
    When attribute(name) set annotation: @abstract
    When attribute(surname) set supertype: name
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get supertype: word
    When attribute(name) set supertype: literal
    When transaction commits
    Given connection open write transaction for database: typedb
    Given attribute(surname) put instance with value: "stopper"
    Given transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get supertype: literal
    Then attribute(name) set supertype: word; fails
    When attribute(name) set annotation: @independent
    When attribute(name) set supertype: word
    When attribute(name) unset annotation: @independent
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(name) get supertype: word
    Then attribute(name) get annotations do not contain: @independent
    When $surname = attribute(surname) get instance with value: "stopper"
    Then attribute $surname does not exist

  Scenario: Attribute type cannot unset supertype while implicitly losing @independent annotation with data
    When create attribute type: literal
    When create attribute type: name
    When attribute(literal) set annotation: @abstract
    When attribute(literal) set annotation: @independent
    When attribute(name) set value type: string
    When attribute(name) unset supertype
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get supertype does not exist
    When attribute(name) set supertype: literal
    When transaction commits
    Given connection open write transaction for database: typedb
    Given attribute(name) put instance with value: "stopper"
    Given transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get supertype: literal
    Then attribute(name) unset supertype; fails
    When attribute(name) set annotation: @independent
    When attribute(name) unset supertype
    When attribute(name) unset annotation: @independent
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(name) get supertype does not exist
    Then attribute(name) get annotations do not contain: @independent
    When $name = attribute(name) get instance with value: "stopper"
    Then attribute $name does not exist

  Scenario: Attribute type cannot unset supertype while implicitly losing @independent annotation with subtype data
    When create attribute type: literal
    When create attribute type: name
    When create attribute type: surname
    When attribute(literal) set annotation: @abstract
    When attribute(literal) set annotation: @independent
    When attribute(name) set value type: string
    When attribute(name) unset supertype
    When attribute(name) set annotation: @abstract
    When attribute(surname) set supertype: name
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get supertype does not exist
    When attribute(name) set supertype: literal
    When transaction commits
    Given connection open write transaction for database: typedb
    Given attribute(surname) put instance with value: "stopper"
    Given transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get supertype: literal
    Then attribute(name) unset supertype; fails
    When attribute(name) set annotation: @independent
    When attribute(name) unset supertype
    Then attribute(name) get supertype does not exist
    When attribute(name) unset annotation: @independent
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(name) get supertype does not exist
    Then attribute(name) get annotations do not contain: @independent
    When $surname = attribute(surname) get instance with value: "stopper"
    Then attribute $surname does not exist

  # TODO: Finish it after we understand @cascade!
#  Scenario: Relation type cannot change supertype while implicitly acquiring @cascade annotation with data
#    When create relation type: parentship
#    When relation(parentship) create role: parentship-role
#    When create relation type: connection
#    When relation(connection) create role: connection-role
#    When create relation type: fathership
#    When relation(fathership) create role: fathership-role
#    When relation(parentship) set annotation: @abstract
#    When relation(connection) set annotation: @abstract
#    When relation(connection) set annotation: @cascade
#    When relation(parentship) set supertype: connection
#    When relation(fathership) create role: father
#    When create entity type: person
#    When entity(person) set plays: fathership:father
#    When transaction commits
#    Given connection open write transaction for database: typedb
#    Given $deletable = entity(person) create new instance
#    Given $fathership = relation(fathership) create new instance
#    Given relation $fathership add player for role(father): $deletable
#    Given delete entity: $deletable
#    Given relation(fathership) get instances contain: $fathership
#    Given transaction commits
#    When connection open schema transaction for database: typedb
##    Then relation(fathership) set supertype: parentship; fails
##    When relation(fathership) set annotation: @cascade
#    When relation(fathership) set supertype: parentship
##    When relation(fathership) unset annotation @cascade
#    Then relation(fathership) get annotations contain: @cascade
#    When transaction commits
#    Given connection open read transaction for database: typedb
#    Then relation(fathership) get instances is empty
#    Then transaction closes
#    When connection open schema transaction for database: typedb
#    When relation(fathership) set supertype: connection
#    Then relation(fathership) get annotations do not contain: @cascade
#    When transaction commits
#    Given connection open write transaction for database: typedb
#    Given $deletable = entity(person) create new instance
#    Given $fathership = relation(fathership) create new instance
#    Given relation $fathership add player for role(father): $deletable
#    Given relation(fathership) get instances contain: $fathership
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then relation(fathership) set supertype: parentship; fails
#    When relation(fathership) set annotation: @cascade
#    When relation(fathership) set supertype: parentship
#    When relation(fathership) unset annotation @cascade
#    Then relation(fathership) get annotations contain: @cascade
#    When transaction commits
#    Given connection open write transaction for database: typedb
#    Then relation(fathership) get instances is not empty
#    Given delete entities of type: person
#    Then relation(fathership) get instances is not empty
#    When transaction commits
#    Given connection open read transaction for database: typedb
#    Then relation(fathership) get annotations contain: @cascade
#    Then relation(fathership) get instances is empty
#
#  Scenario: Relation type cannot change supertype while implicitly acquiring @cascade annotation with subtype data
#    When create relation type: parentship
#    When relation(parentship) create role: parentship-role
#    When create relation type: connection
#    When relation(connection) create role: connection-role
#    When create relation type: fathership
#    When relation(fathership) create role: fathership-role
#    When create relation type: single-fathership
#    When relation(parentship) set annotation: @abstract
#    When relation(connection) set annotation: @abstract
#    When relation(connection) set annotation: @cascade
#    When relation(parentship) set supertype: connection
#    When relation(single-fathership) set supertype: fathership
#    When relation(single-fathership) create role: father
#    When create entity type: person
#    When entity(person) set plays: single-fathership:father
#    When transaction commits
#    Given connection open write transaction for database: typedb
#    Given $deletable = entity(person) create new instance
#    Given $fathership = relation(single-fathership) create new instance
#    Given relation $fathership add player for role(father): $deletable
#    Given delete entity: $deletable
#    Given relation(single-fathership) get instances contain: $fathership
#    Given transaction commits
#    When connection open schema transaction for database: typedb
##    Then relation(fathership) set supertype: parentship; fails
##    When relation(fathership) set annotation: @cascade
#    When relation(fathership) set supertype: parentship
##    When relation(fathership) unset annotation @cascade
#    Then relation(single-fathership) get annotations contain: @cascade
#    When transaction commits
#    Given connection open read transaction for database: typedb
#    Then relation(single-fathership) get instances is empty
#    Then transaction closes
#    When connection open schema transaction for database: typedb
#    When relation(fathership) set supertype: connection
#    Then relation(single-fathership) get annotations do not contain: @cascade
#    When transaction commits
#    Given connection open write transaction for database: typedb
#    Given $deletable = entity(person) create new instance
#    Given $fathership = relation(single-fathership) create new instance
#    Given relation $fathership add player for role(father): $deletable
#    Given relation(single-fathership) get instances contain: $fathership
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then relation(fathership) set supertype: parentship; fails
#    When relation(fathership) set annotation: @cascade
#    When relation(fathership) set supertype: parentship
#    When relation(fathership) unset annotation @cascade
#    Then relation(single-fathership) get annotations contain: @cascade
#    When transaction commits
#    Given connection open write transaction for database: typedb
#    Then relation(single-fathership) get instances is not empty
#    Given delete entities of type: person
#    Then relation(single-fathership) get instances is not empty
#    When transaction commits
#    Given connection open read transaction for database: typedb
#    Then relation(single-fathership) get annotations contain: @cascade
#    Then relation(single-fathership) get instances is empty
