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
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write


  Scenario: Instances of a type not in the schema must not exist
    Given create entity type: ent0
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given $a = entity(ent0) create new instance
    Given transaction commits

    When connection close all sessions
    When connection open schema session for database: typedb
    When session opens transaction of type: write
    Then delete entity type: ent0; throws exception


  Scenario: Instances of abstract types must not exist
    Given create entity type: ent0a
    Given entity(ent0a) set abstract: true
    Given create entity type: ent0c
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb

    When session opens transaction of type: write
    Then entity(ent0a) create new instance; throws exception

    When session opens transaction of type: write
    Then $a = entity(ent0c) create new instance
    Then transaction commits

    Given connection close all sessions
    Given connection open schema session for database: typedb

    When session opens transaction of type: write
    Then entity(ent0c) set abstract: true; throws exception


  Scenario: Instances of ownerships not in the schema must not exist
    Given create entity type: ent00
    Given create attribute type: attr00, with value type: string
    Given entity(ent00) set owns attribute type: attr00
    Given create entity type: ent1
    Given entity(ent1) set supertype: ent00
    Given create entity type: ent01
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given $ent1 = entity(ent1) create new instance
    Given $attr00 = attribute(attr00) as(string) put: "attr00"
    Given entity $ent1 set has: $attr00
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb

    When session opens transaction of type: write
    When $ent01 = entity(ent01) create new instance
    Then entity $ent01 set has: $attr00; throws exception

    Given connection close all sessions
    Given connection open schema session for database: typedb

    When session opens transaction of type: write
    Then entity(ent00) unset owns attribute type: attr00; throws exception

    When session opens transaction of type: write
    Then entity(ent1) set supertype: ent01; throws exception


  Scenario: Instances of roles not in the schema must not exist
    Given create relation type: rel00
    Given relation(rel00) set relates role: role00
    Given create relation type: rel01
    Given relation(rel01) set relates role: role01
    Given create relation type: rel1
    Given relation(rel1) set supertype: rel00
    Given create entity type: ent0
    Given entity(ent0) set plays: rel00:role00
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given $ent0 = entity(ent0) create new instance
    Given $rel1 = relation(rel1) create new instance
    Given relation $rel1 add player for role(role00): $ent0
    Given transaction commits
    Given connection close all sessions
    Given connection open schema session for database: typedb

    When session opens transaction of type: write
    Then relation(rel00) unset related role: role00; throws exception

    When session opens transaction of type: write
    Then relation(rel1) set supertype: rel01; throws exception

    When session opens transaction of type: write
    Then relation(rel1) set relates role: role1 as role00; throws exception


  # If we ever introduce abstract roles, we need a scenario here

  Scenario: Instances of role-playing not in the schema must not exist
    Given create relation type: rel0
    Given relation(rel0) set relates role: role0
    Given create relation type: rel1
    Given relation(rel1) set supertype: rel0
    Given relation(rel1) set relates role: role1 as role0
    Given create entity type: ent00
    Given entity(ent00) set plays: rel0:role0
    Given create entity type: ent1
    Given entity(ent1) set supertype: ent00
    Given create entity type: ent01
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given $ent1 = entity(ent1) create new instance
    Given $rel0 = relation(rel0) create new instance
    Given relation $rel0 add player for role(role0): $ent1
    Given transaction commits

    When session opens transaction of type: write
    When $e1 = entity(ent1) create new instance
    When $r1 = relation(rel1) create new instance
    Then relation $r1 add player for role(role1): $e1; throws exception

    Given connection close all sessions
    Given connection open schema session for database: typedb

    When session opens transaction of type: write
    Then entity(ent00) unset plays: rel0:role0; throws exception

    When session opens transaction of type: write
    Then entity(ent1) set plays: rel1:role1 as rel0:role0; throws exception

    When session opens transaction of type: write
    Then entity(ent1) set supertype: ent01; throws exception


  # If we ever introduce abstract roles, we need a scenario here

  Scenario: Instances of role-playing hidden by a relates override must not exist
    Given create relation type: rel0
    Given relation(rel0) set relates role: role0
    Given create relation type: rel1
    Given relation(rel1) set supertype: rel0
    Given relation(rel1) set relates role: role1 as role0
    Given create entity type: ent00
    Given entity(ent00) set plays: rel0:role0
    Given entity(ent00) set plays: rel1:role1
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb

    When session opens transaction of type: write
    When $ent00 = entity(ent00) create new instance
    When $rel1 = relation(rel1) create new instance
    # a NullPointerException in the steps because role0 is not related by rel1.
    When relation $rel1 add player for role(role0): $ent00; throws exception

    When session opens transaction of type: write
    When $ent00 = entity(ent00) create new instance
    When $rel1 = relation(rel1) create new instance
    When relation $rel1 add player for role(role1): $ent00
    Then transaction commits

    # With no 'plays' override, we can still play the parent role in the parent relation
    When session opens transaction of type: write
    When $ent00 = entity(ent00) create new instance
    When $rel0 = relation(rel0) create new instance
    When relation $rel0 add player for role(role0): $ent00
    Then transaction commits


  Scenario: Instances of role-playing hidden by a plays override must not exist
    Given create relation type: rel0
    Given relation(rel0) set relates role: role0
    Given create relation type: rel1
    Given relation(rel1) set supertype: rel0
    Given relation(rel1) set relates role: role1 as role0
    Given create entity type: ent00
    Given entity(ent00) set plays: rel0:role0
    Given create entity type: ent1
    Given entity(ent1) set supertype: ent00
    Given entity(ent1) set plays: rel1:role1 as rel0:role0
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb

    When session opens transaction of type: write
    When $ent1 = entity(ent1) create new instance
    When $rel0 = relation(rel0) create new instance
    When relation $rel0 add player for role(role0): $ent1; throws exception

    When session opens transaction of type: write
    When $ent1 = entity(ent1) create new instance
    When $rel1 = relation(rel1) create new instance
    When relation $rel1 add player for role(role1): $ent1
    Then transaction commits


  Scenario: A type may not override a role it plays through inheritance if instances of that type playing that role exist
    Given create relation type: rel0
    Given relation(rel0) set relates role: role0
    Given create relation type: rel1
    Given relation(rel1) set supertype: rel0
    Given relation(rel1) set relates role: role1 as role0
    Given create entity type: ent00
    Given entity(ent00) set plays: rel0:role0
    Given create entity type: ent1
    Given entity(ent1) set supertype: ent00
    # Without the override
    Given entity(ent1) set plays: rel1:role1
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given $ent1 = entity(ent1) create new instance
    Given $rel0 = relation(rel0) create new instance
    Given relation $rel0 add player for role(role0): $ent1
    Given transaction commits

    Given connection close all sessions
    Given connection open schema session for database: typedb

    When session opens transaction of type: write
    Then entity(ent1) set plays: rel1:role1 as rel0:role0; throws exception


  Scenario: A type may not be moved if it has instances of it playing a role which would be hidden as a result of that move
    Given create relation type: rel0
    Given relation(rel0) set relates role: role0
    Given create relation type: rel1
    Given relation(rel1) set supertype: rel0
    Given relation(rel1) set relates role: role1 as role0
    Given create entity type: ent0
    Given entity(ent0) set plays: rel0:role0
    Given create entity type: ent10
    Given entity(ent10) set supertype: ent0
    Given create entity type: ent2
    Given entity(ent2) set supertype: ent10
    Given create entity type: ent11
    Given entity(ent11) set supertype: ent0
    Given entity(ent11) set plays: rel1:role1 as rel0:role0
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given $ent2 = entity(ent2) create new instance
    Given $rel0 = relation(rel0) create new instance
    Given relation $rel0 add player for role(role0): $ent2
    Given transaction commits

    When connection close all sessions
    When connection open schema session for database: typedb
    When session opens transaction of type: write
    Then entity(ent2) set supertype: ent11; throws exception


  Scenario: When annotations on an ownership change, data is revalidated
    Given create attribute type: attr0, with value type: string
    Given create entity type: ent0n
    Given create entity type: ent0u
    Given entity(ent0n) set owns attribute type: attr0
    Given entity(ent0u) set owns attribute type: attr0, with annotations: unique
    Given create attribute type: ref, with value type: string
    Given entity(ent0n) set owns attribute type: ref, with annotations: key
    Given entity(ent0u) set owns attribute type: ref, with annotations: key
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given $ent0n0 = entity(ent0n) create new instance with key(ref): ent0n0
    Given $ent0n1 = entity(ent0n) create new instance with key(ref): ent0n1
    Given $ent0u = entity(ent0u) create new instance with key(ref): ent0u
    Given $attr0 = attribute(attr0) as(string) put: "attr0"
    Given $attr1 = attribute(attr0) as(string) put: "attr1"
    Given entity $ent0n0 set has: $attr1
    Given entity $ent0n1 set has: $attr1
    Given entity $ent0u set has: $attr0
    Given entity $ent0u set has: $attr1
    Given transaction commits
    Given connection close all sessions
    Given connection open schema session for database: typedb

    When session opens transaction of type: write
    Then entity(ent0n) set owns attribute type: attr0, with annotations: unique; throws exception

    When session opens transaction of type: write
    Then entity(ent0u) set owns attribute type: attr0, with annotations: key; throws exception

    Given connection close all sessions
    Given connection open data session for database: typedb
    When session opens transaction of type: write
    When $ent0n1 = entity(ent0n) get instance with key(ref): ent0n1
    When $ent0u = entity(ent0u) get instance with key(ref): ent0u
    When $attr1 = attribute(attr0) as(string) get: "attr1"
    When entity $ent0n1 unset has: $attr1
    When entity $ent0u unset has: $attr1
    Then transaction commits

    Given connection close all sessions
    Given connection open schema session for database: typedb
    When session opens transaction of type: write
    Then entity(ent0n) set owns attribute type: attr0, with annotations: unique
    Then entity(ent0u) set owns attribute type: attr0, with annotations: key
    Then transaction commits

  Scenario: When the super-type of a type is changed, the data is consistent with the annotations on ownerships
    Given create attribute type: attr0, with value type: string
    Given create entity type: ent0k
    Given create entity type: ent0n
    Given create entity type: ent1n
    Given entity(ent1n) set supertype: ent0n
    Given entity(ent0n) set owns attribute type: attr0
    Given entity(ent0k) set owns attribute type: attr0, with annotations: key
    Given create attribute type: ref, with value type: string
    Given entity(ent0n) set owns attribute type: ref, with annotations: key
    Given entity(ent0k) set owns attribute type: ref, with annotations: key
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given $attr0 = attribute(attr0) as(string) put: "attr0"
    Given $attr1 = attribute(attr0) as(string) put: "attr1"
    Given $ent1n = entity(ent1n) create new instance with key(ref): ent1n
    Given entity $ent1n set has: $attr0
    Given entity $ent1n set has: $attr1
    Given $ent0k = entity(ent0k) create new instance with key(ref): ent0k
    Given entity $ent0k set has: $attr0
    Given transaction commits
    Given connection close all sessions
    Given connection open schema session for database: typedb

    When session opens transaction of type: write
    Then entity(ent1n) set supertype: ent0k; throws exception

