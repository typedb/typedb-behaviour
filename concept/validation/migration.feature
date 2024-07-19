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

    # Should break
    Given connection open schema transaction for database: typedb
    # TODO: Either of these steps could fail, not sure for now
    When entity(ent1) set owns: attr0
    Then entity(ent1) get owns(attr0) set annotation: @unique; fails

    Given connection open schema transaction for database: typedb
    Then entity(ent0) unset owns: attr0; fails

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
    Then entity(ent1) set supertype: entity; fails
    Given session transaction close

    Given connection open schema transaction for database: typedb
    Then entity(ent1) set owns: attr0
    Then entity(ent1) get owns(attr0) set annotation: @key
    Then entity(ent1) set supertype: entity
    Then transaction commits


  Scenario: A type moved with plays instances in-place by re-declaring played roles
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
    Then entity(ent1) set supertype: entity; fails

    Given connection open schema transaction for database: typedb
    Then entity(ent1) set plays: rel0:role0
    Then entity(ent1) set supertype: entity
    Then transaction commits

  Scenario: A type can be inserted into an existing hierarchy which has data in place
    Given create relation type: rel
    Given relation(rel) create role: role0
    Given create attribute type: attr
    Given attribute(attr0) set value type: string
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
    Given attribute(attr0) set value type: string
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
    Given typeql insert
    """
    insert
    $john isa person, has name "john";
    $scooby isa dog, has name "scooby";
    """
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
    When typeql insert
    """
    match $p isa person, has name $name; ?value = $name;
    insert $p has person-name ?value;
    """
    When typeql insert
    """
    match $d isa dog, has name $name; ?value = $name;
    insert $d has dog-name ?value;
    """
    Then transaction commits
    When connection open schema transaction for database: typedb
    # adjust annotations
    When entity(person) set owns: person-name
    When entity(person) get owns(person-name) set annotation: @key
    When entity(dog) set owns: dog-name
    When entity(dog) get owns(dog-name) set annotation: @key
    When entity(being) set owns: name
    Then transaction commits

    When connection open write transaction for database: typedb
    When typeql delete
    """
    match $n isa! name;
    delete $n isa name;
    """
    Then transaction commits

    When connection open schema transaction for database: typedb
    When attribute(name) set annotation: @abstract
    When attribute(person-name) set supertype: name
    When attribute(dog-name) set supertype: name
    When entity(person) set owns: person-name
    When entity(person) get owns(person-name) set override: name
    When entity(person) get owns(person-name) set annotation: @key
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
    Given typeql insert
    """
    insert
      $alice isa person, has gender "F", has common "c-alice", has female-specific "f-alice";
      $bob isa person, has gender "M", has common "c-bob", has male-specific "m-bob";
    """
    Given transaction commits

    When connection open schema transaction for database: typedb
    When create entity type: male
    When entity(male) set supertype: person
    When create entity type: female
    When entity(female) set supertype: person
    Then transaction commits

    When connection open write transaction for database: typedb
    When typeql insert
    """
    match $p isa person, has gender "M", has male-specific $ms, has common $c;
    insert $m isa male, has $ms, has $c;
    """
    When typeql insert
    """
    match $p isa person, has gender "F", has female-specific $fs, has common $c;
    insert $f isa female, has $fs, has $c;
    """
    When typeql delete
    """
    match $p isa! person;
    delete $p isa person;
    """
    When typeql delete
    """
    match $g isa! gender;
    delete $g isa gender;
    """
    Then transaction commits

    When connection open schema transaction for database: typedb
    When entity(male) set owns: male-specific
    When entity(female) set owns: female-specific
    When entity(person) unset owns: male-specific
    When entity(person) unset owns: female-specific
    When entity(person) set annotation: @abstract
    When delete attribute type: gender
    Then transaction commits
