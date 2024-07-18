# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Schema validation

  Background:
    Given typedb starts
    Given connection opens with default authentication
    Given connection has been opened
    Given connection does not have any database
    Given connection create database: typedb
    Given connection open schema transaction for database: typedb


  Scenario: Cyclic type hierarchies are disallowed
    Given create attribute type: attr0
    Given attribute(attr0) set value type: string
    Given create attribute type: attr1
    Given attribute(attr0) set annotation: @abstract
    Given attribute(attr1) set annotation: @abstract
    Given attribute(attr1) set supertype: attr0
    Given create entity type: ent0
    Given create entity type: ent1
    Given entity(ent1) set supertype: ent0
    Given create relation type: rel0
    Given relation(rel0) create role: role0
    Given create relation type: rel1
    Given relation(rel1) create role: role1
    Given relation(rel1) set supertype: rel0
    Given transaction commits

    When connection open schema transaction for database: typedb
    Then attribute(attr1) set supertype: attr1; fails

    When transaction closes
    When connection open schema transaction for database: typedb
    Then attribute(attr0) set supertype: attr1; fails

    When transaction closes
    When connection open schema transaction for database: typedb
    Then entity(ent1) set supertype: ent1; fails

    When transaction closes
    When connection open schema transaction for database: typedb
    Then entity(ent0) set supertype: ent1; fails

    When transaction closes
    When connection open schema transaction for database: typedb
    Then relation(rel1) set supertype: rel1; fails

    When transaction closes
    When connection open schema transaction for database: typedb
    Then relation(rel0) set supertype: rel1; fails


  Scenario: An attribute-type must have the same value type as its ancestors, but not declare it redundantly
    Given create attribute type: attr0s
    Given attribute(attr0s) set value type: string
    Given attribute(attr0s) set annotation: @abstract
    Given create attribute type: attr0d
    Given attribute(attr0d) set value type: double
    Given attribute(attr0d) set annotation: @abstract
    Given create attribute type: attr1
    Given attribute(attr1) set value type: string
    Given transaction commits

    When connection open schema transaction for database: typedb
    Then attribute(attr1) set supertype: attr0d; fails
    When attribute(attr1) set supertype: attr0s
    Then transaction commits; fails

    When connection open schema transaction for database: typedb
    Then attribute(attr1) set supertype: attr0d; fails
    When attribute(attr1) set supertype: attr0s
    When attribute(attr1) unset value type
    Then transaction commits


  Scenario: Only abstract attributes may have subtypes
    Given create attribute type: attr0a
    Given attribute(attr0a) set value type: string
    Given create attribute type: attr0c
    Given attribute(attr0c) set value type: string
    Given attribute(attr0a) set annotation: @abstract
    Given transaction commits

    When connection open schema transaction for database: typedb
    When create attribute type: attr1
    When attribute(attr1) set supertype: attr0c; fails

    When transaction closes
    When connection open schema transaction for database: typedb
    When create attribute type: attr1
    When attribute(attr1) set supertype: attr0a
    Then transaction commits

    When connection open schema transaction for database: typedb
    When attribute(attr0a) unset annotation: @abstract; fails

    When transaction closes
    When connection open schema transaction for database: typedb
    When attribute(attr1) set supertype: attr0c; fails

    When transaction closes
    When connection open schema transaction for database: typedb
    When attribute(attr0c) set annotation: @abstract
    When attribute(attr1) set supertype: attr0c
    Then transaction commits


  Scenario: Concrete relation types must relate at least one role, cannot unset relates root
    When create relation type: rel0a
    Then relation(rel0a) get roles contain:
      | relation:role |
    Then relation(rel0a) get declared roles is empty
    Then relation(rel0a) get role(role) does not exist
    Then relation(relation) get role(role) exists
    Then relation(relation) delete role: role; fails
    Then transaction commits; fails

    When connection open schema transaction for database: typedb
    When create relation type: rel0b
    When relation(rel0b) create role: role0b
    Then relation(rel0b) get roles contain:
#     TODO: Now we hide relation:role. Do we want this behavior? We show it in typeql 2.x in like "$relation sub relation; $relation relates $r;"
#      | relation:role |
      | rel0b:role0b |
    Then relation(rel0b) get declared roles contain:
      | rel0b:role0b |
    When transaction commits

    When connection open schema transaction for database: typedb
    Then relation(rel0b) get roles contain:
#     TODO: Now we hide relation:role. Do we want this behavior?
#      | relation:role |
      | rel0b:role0b |
    Then relation(rel0b) get declared roles contain:
      | rel0b:role0b |
    When relation(rel0b) delete role: role0b
    Then relation(rel0b) get roles contain:
      | relation:role |
    Then relation(rel0b) get roles do not contain:
      | rel0b:role0b |
    Then relation(rel0b) get declared roles is empty
    Then transaction commits; fails

    When connection open schema transaction for database: typedb
    When create relation type: rel0c
    When relation(rel0c) set annotation: @abstract
    Then relation(rel0c) get roles contain:
      | relation:role |
    Then relation(rel0c) get declared roles is empty
    When transaction commits

    When connection open schema transaction for database: typedb
    Then relation(rel0c) get roles contain:
      | relation:role |
    Then relation(rel0c) get declared roles is empty
    When relation(rel0c) unset annotation: @abstract
    Then relation(rel0c) get roles contain:
      | relation:role |
    Then relation(rel0c) get declared roles is empty
    Then transaction commits; fails


  Scenario: Concrete relation types must relate at least one role
    Given create relation type: rel00
    Given relation(rel00) set annotation: @abstract
    Given relation(rel00) create role: role00
    Given create relation type: rel01
    Given relation(rel01) set annotation: @abstract
    Given transaction commits

    When connection open schema transaction for database: typedb
    When create relation type: rel1
    When relation(rel1) set supertype: rel01
    Then relation(rel1) get roles contain:
      | relation:role |
    Then relation(rel1) get declared roles is empty
    Then transaction commits; fails

    When connection open schema transaction for database: typedb
    When create relation type: rel1
    When relation(rel1) set supertype: rel01
    Then relation(rel1) get roles contain:
      | relation:role |
    Then relation(rel1) get declared roles is empty
    When relation(rel1) set supertype: rel00
    Then relation(rel1) get roles contain:
      | rel00:role00 |
    Then relation(rel1) get declared roles is empty
    When transaction commits

    When connection open schema transaction for database: typedb
    When relation(rel00) delete role: role00
    Then relation(rel00) get roles contain:
      | relation:role |
    Then relation(rel1) get roles contain:
      | relation:role |
    Then relation(rel00) get roles do not contain:
      | rel00:role00 |
    Then relation(rel1) get roles do not contain:
      | rel00:role00 |
    Then transaction commits; fails

    When connection open schema transaction for database: typedb
    When relation(rel1) set supertype: rel01
    Then relation(rel1) get roles contain:
      | relation:role |
    Then relation(rel1) get roles do not contain:
      | rel00:role00 |
    Then transaction commits; fails


  Scenario: Relation types may not declare a role with the same name as one declared in its inheritance line
    When create relation type: rel00
    When relation(rel00) set annotation: @abstract
    When relation(rel00) create role: role00
    When create relation type: rel01
    When relation(rel01) set annotation: @abstract
    When relation(rel01) create role: role01
    When relation(rel01) create role: role02
    When create relation type: rel1
    When relation(rel1) set annotation: @abstract
    When relation(rel1) set supertype: rel00
    When relation(rel1) create role: role01
    Then transaction commits

    When connection open schema transaction for database: typedb
    When relation(rel1) create role: role00; fails

    When transaction closes
    When connection open schema transaction for database: typedb
    When relation(rel00) create role: role01
    Then transaction commits; fails

    When connection open schema transaction for database: typedb
    When relation(rel1) set supertype: rel01; fails

    When transaction closes
    When connection open schema transaction for database: typedb
    When create relation type: rel2
    When relation(rel2) set annotation: @abstract
    When create relation type: rel02
    When relation(rel02) set annotation: @abstract
    When relation(rel02) create role: role02
    When relation(rel02) set supertype: rel2
    When transaction commits

    When connection open schema transaction for database: typedb
    When relation(rel2) set supertype: rel01
    Then transaction commits; fails

    When connection open schema transaction for database: typedb
    When create relation type: rel3
    When relation(rel3) set annotation: @abstract
    When create relation type: rel4
    When relation(rel4) set annotation: @abstract
    When relation(rel4) create role: role02
    When relation(rel4) set supertype: rel3
    Then relation(rel4) set supertype: rel02; fails
    When relation(rel3) set supertype: rel02
    Then transaction commits; fails

    When connection open schema transaction for database: typedb
    When create relation type: rel3
    When relation(rel3) set annotation: @abstract
    When create relation type: rel4
    When relation(rel4) set annotation: @abstract
    When relation(rel4) create role: role02
    When relation(rel3) set supertype: rel02
    Then relation(rel4) set supertype: rel3; fails


  Scenario: Concrete types may not own abstract attributes
    Given create attribute type: attr0
    Given attribute(attr0) set value type: string
    Given attribute(attr0) set annotation: @abstract
    Given create entity type: ent0
    Given transaction commits

    When connection open schema transaction for database: typedb
    Then entity(ent0) set owns: attr0; fails

    When transaction closes
    When connection open schema transaction for database: typedb
    When entity(ent0) set annotation: @abstract
    When entity(ent0) set owns: attr0
    Then transaction commits

    When connection open schema transaction for database: typedb
    Then entity(ent0) unset annotation: @abstract; fails

    When transaction closes
    When connection open schema transaction for database: typedb
    When create entity type: ent1
    When entity(ent1) set supertype: ent0
    Then transaction commits; fails


  Scenario: Modifying a relation or role does not leave invalid overrides
    Given create relation type: rel00
    Given relation(rel00) create role: role00
    Given relation(rel00) create role: extra_role
    Given create relation type: rel01
    Given relation(rel01) create role: role01
    Given create relation type: rel1
    Given relation(rel1) set supertype: rel00
    Given create relation type: rel2
    Given relation(rel2) set supertype: rel1
    Given relation(rel2) create role: role2
    Given relation(rel2) get role(role2) set override: role00
    Given transaction commits

    When connection open schema transaction for database: typedb
    Then relation(rel00) delete role: role00; fails

    When transaction closes
    When connection open schema transaction for database: typedb
    Then relation(rel2) set supertype: rel01; fails

    When transaction closes
    When connection open schema transaction for database: typedb
    When relation(rel1) create role: role1
    Then relation(rel1) get role(role1) set override: role00
    Then transaction commits; fails

    When connection open schema transaction for database: typedb
    When create relation type: rel3
    When relation(rel3) set supertype: rel1
    When relation(rel3) create role: role3
    When create relation type: rel4
    When relation(rel4) set supertype: rel1
    When relation(rel2) set supertype: rel3
    Then relation(rel2) get role(role2) get supertype: rel00:role00
    When transaction commits

    When connection open schema transaction for database: typedb
    Then relation(rel2) get role(role2) get supertype: rel00:role00
    When relation(rel2) set supertype: rel4
    Then relation(rel2) get role(role2) get supertype: rel00:role00
    When transaction commits

    When connection open schema transaction for database: typedb
    When relation(rel3) get role(role3) set override: role00
    Then relation(rel2) set supertype: rel3; fails
    Then relation(rel3) create role: role00; fails

    When transaction closes
    When connection open schema transaction for database: typedb
    When create relation type: rel5
    When relation(rel5) create role: role00
    When transaction commits

    When connection open schema transaction for database: typedb
    Then relation(rel2) get role(role2) get supertype: rel00:role00
    Then relation(rel2) set supertype: rel5; fails

    When transaction closes
    When connection open schema transaction for database: typedb
    Then relation(rel2) get supertype: rel4
    Then relation(rel2) get role(role2) get supertype: rel00:role00
    When relation(rel4) set supertype: rel5
    Then transaction commits; fails

    When connection open schema transaction for database: typedb
    Then relation(rel2) get supertype: rel4
    Then relation(rel2) get role(role2) get supertype: rel00:role00
    When relation(rel4) set supertype: rel01
    Then transaction commits; fails


  Scenario: Deleting a role does not leave dangling 'plays' declarations
    Given create relation type: rel0
    Given relation(rel0) create role: role0
    Given relation(rel0) create role: extra_role
    Given create entity type: ent0
    Given entity(ent0) set plays: rel0:role0
    Given transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent0) get plays contain:
      | rel0:role0 |
    When relation(rel0) delete role: role0
    Then entity(ent0) get plays do not contain:
      | rel0:role0 |
    Then transaction commits

    When connection open read transaction for database: typedb
    Then entity(ent0) get plays do not contain:
      | rel0:role0 |


  Scenario: Deleting an attribute-type does not leave dangling 'owns' declarations
    Given create attribute type: attr0
    Given attribute(attr0) set value type: string
    Given create entity type: ent0
    Given entity(ent0) set owns: attr0
    Given transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent0) get owns contain:
      | attr0 |
    When delete attribute type: attr0
    Then entity(ent0) get owns do not contain:
      | attr0 |
    Then transaction commits

    When connection open read transaction for database: typedb
    Then entity(ent0) get owns do not contain:
      | attr0 |


  Scenario: The schema does not contain redundant owns declarations
    Given create attribute type: attr0
    Given attribute(attr0) set value type: string
    Given create entity type: ent00
    Given entity(ent00) set owns: attr0
    Given create entity type: ent01
    Given create entity type: ent1
    Given entity(ent1) set supertype: ent00
    Given transaction commits

    When connection open schema transaction for database: typedb
    Then entity(ent1) set owns: attr0
    Then transaction commits; fails

    When connection open schema transaction for database: typedb
    When entity(ent1) set supertype: ent01
    When entity(ent1) set owns: attr0
    Then transaction commits

    When connection open schema transaction for database: typedb
    Then entity(ent1) set supertype: ent00
    Then transaction commits; fails


  Scenario: The schema does not contain redundant plays declarations
    Given create relation type: rel0
    Given relation(rel0) create role: role0
    Given create entity type: ent00
    Given entity(ent00) set plays: rel0:role0
    Given create entity type: ent01
    Given create entity type: ent1
    Given entity(ent1) set supertype: ent00
    Given transaction commits

    When connection open schema transaction for database: typedb
    Then entity(ent1) set plays: rel0:role0
    Then transaction commits; fails

    When connection open schema transaction for database: typedb
    When entity(ent1) set supertype: ent01
    When entity(ent1) set plays: rel0:role0
    Then transaction commits

    When connection open schema transaction for database: typedb
    Then entity(ent1) set supertype: ent00
    Then transaction commits; fails


  Scenario: A relation-type may only override role-types it inherits
    Given create relation type: rel00
    Given relation(rel00) create role: role00
    Given create relation type: rel01
    Given relation(rel01) create role: role01
    Given transaction commits

    When connection open schema transaction for database: typedb
    When create relation type: rel1
    When relation(rel1) create role: role1
    Then relation(rel1) get role(role1) set override: role00; fails

    When transaction closes
    When connection open schema transaction for database: typedb
    When create relation type: rel1
    When relation(rel1) set supertype: rel00
    When relation(rel1) create role: role1
    When relation(rel1) get role(role1) set override: role00
    Then relation(rel1) get roles contain:
      | rel1:role1 |
    Then relation(rel1) get roles do not contain:
      | rel0:role0 |
    Then transaction commits

    When connection open schema transaction for database: typedb
    Then relation(rel1) set supertype: rel01; fails

    When transaction closes
    When connection open schema transaction for database: typedb
    Then relation(rel00) delete role: role00; fails


  Scenario: A type may only override an ownership it inherits
    Given create attribute type: attr0
    Given attribute(attr0) set value type: string
    Given attribute(attr0) set annotation: @abstract
    Given create attribute type: attr1
    Given attribute(attr1) set supertype: attr0
    Given create entity type: ent00
    Given entity(ent00) set annotation: @abstract
    Given entity(ent00) set owns: attr0
    Given create entity type: ent01
    Given entity(ent01) set annotation: @abstract
    Given transaction commits

    When connection open schema transaction for database: typedb
    When create entity type: ent1
    When entity(ent1) set owns: attr1
    Then entity(ent1) get owns(attr1) set override: attr0; fails

    When transaction closes
    When connection open schema transaction for database: typedb
    When create entity type: ent1
    When entity(ent1) set supertype: ent00
    When entity(ent1) set owns: attr1
    When entity(ent1) get owns(attr1) set override: attr0
    Then transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent00) unset owns: attr0
    Then transaction commits; fails

    When connection open schema transaction for database: typedb
    When entity(ent1) set supertype: ent01; fails


  Scenario: A type may not declare ownership of an attribute that has been overridden by an inherited ownership
    Given create attribute type: attr0
    Given attribute(attr0) set value type: string
    Given attribute(attr0) set annotation: @abstract
    Given create attribute type: attr1
    Given attribute(attr1) set annotation: @abstract
    Given attribute(attr1) set supertype: attr0
    Given create attribute type: attr2
    Given attribute(attr2) set supertype: attr1
    Given attribute(attr2) set annotation: @abstract
    Given create entity type: ent0
    Given entity(ent0) set annotation: @abstract
    Given entity(ent0) set owns: attr0
    Given create entity type: ent1
    Given entity(ent1) set supertype: ent0
    Given entity(ent1) set annotation: @abstract
    Given entity(ent1) set owns: attr1
    Given entity(ent1) get owns(attr1) set override: attr0
    Given transaction commits

    When connection open schema transaction for database: typedb
    When create entity type: ent2
    When entity(ent2) set supertype: ent1
    When entity(ent2) set annotation: @abstract
    Then entity(ent2) set owns: attr2
    Then entity(ent2) get owns(attr2) set override: attr0; fails

    When transaction closes
    When connection open schema transaction for database: typedb
    When create entity type: ent2
    When entity(ent2) set supertype: ent1
    When entity(ent2) set annotation: @abstract
    When entity(ent1) unset owns: attr1
    When entity(ent2) set owns: attr2
    When entity(ent2) get owns(attr2) set override: attr0
    Then transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent1) set owns: attr1
    When entity(ent1) get owns(attr1) set override: attr0
    Then transaction commits; fails

    When connection open schema transaction for database: typedb
    When create entity type: ent3
    When entity(ent3) set annotation: @abstract
    When entity(ent3) set owns: attr0
    Then transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent3) set supertype: ent2; fails

    When transaction closes
    When connection open schema transaction for database: typedb
    When create entity type: ent4
    When entity(ent4) set annotation: @abstract
    When entity(ent4) set owns: attr0
    When entity(ent4) set supertype: ent3
    When entity(ent3) unset owns: attr0
    When transaction commits

    When connection open schema transaction for database: typedb
    Then entity(ent4) get supertype: ent3
    Then entity(ent4) get owns contain:
      | attr0 |
    Then entity(ent3) get owns do not contain:
      | attr0 |
    When entity(ent3) set supertype: ent2
    Then transaction commits; fails


  Scenario: A type may only override an ownership it inherits with a subtype of the inherited attribute
    Given create attribute type: attr0
    Given attribute(attr0) set value type: string
    Given attribute(attr0) set annotation: @abstract
    Given create attribute type: attr1
    Given attribute(attr1) set value type: string
    # Same, but the attributes are not subtypes
    Given create entity type: ent00
    Given entity(ent00) set annotation: @abstract
    Given entity(ent00) set owns: attr0
    Given transaction commits

    When connection open schema transaction for database: typedb
    When create entity type: ent1
    When entity(ent1) set supertype: ent00
    When entity(ent1) set owns: attr1
    Then entity(ent1) get owns(attr1) set override: attr0; fails


  Scenario: A type may only override a role it plays by inheritance
    Given create relation type: rel0
    Given relation(rel0) create role: role0
    Given create relation type: rel1
    Given relation(rel1) set supertype: rel0
    # Not yet as an override
    Given relation(rel1) create role: role1
    Given create entity type: ent00
    Given entity(ent00) set plays: rel0:role0
    Given create entity type: ent01
    Given transaction commits

    # Roles aren't subtypes of each other
    When connection open schema transaction for database: typedb
    When create entity type: ent1
    When entity(ent1) set supertype: ent00
    When entity(ent1) set plays: rel1:role1
    Then entity(ent1) get plays(rel1:role1) set override: rel0:role0; fails

    When transaction closes
    When connection open schema transaction for database: typedb
    When relation(rel1) get role(role1) set override: role0
    Then transaction commits

    # ent1 doesn't sub ent00
    When connection open schema transaction for database: typedb
    When create entity type: ent1
    When entity(ent1) set plays: rel1:role1
    Then entity(ent1) get plays(rel1:role1) set override: rel0:role0; fails

    When transaction closes
    When connection open schema transaction for database: typedb
    When create entity type: ent1
    When entity(ent1) set supertype: ent00
    When entity(ent1) get plays contain:
      | rel0:role0 |
    # First without override
    Then entity(ent1) set plays: rel1:role1
    Then entity(ent1) get plays contain:
      | rel0:role0 |
      | rel1:role1 |
    Then transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent1) set plays: rel1:role1
    When entity(ent1) get plays(rel1:role1) set override: rel0:role0
    Then entity(ent1) get plays contain:
      | rel1:role1 |
    Then entity(ent1) get plays do not contain:
      | rel0:role0 |
    Then transaction commits


  Scenario: The schema may not be modified in a way that an overridden plays role is no longer inherited by the overriding type
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
    Given create entity type: ent01
    Given transaction commits

    When connection open schema transaction for database: typedb
    Then relation(rel1) get role(role1) unset override
    Then transaction commits; fails

    When connection open schema transaction for database: typedb
    Then entity(ent00) unset plays: rel0:role0
    Then transaction commits; fails

    When connection open schema transaction for database: typedb
    Then entity(ent1) set supertype: ent01; fails


  Scenario: A thing-type may not redeclare the ability to play a RoleType which is hidden by an override
    Given create relation type: rel0
    Given relation(rel0) create role: role0
    Given create relation type: rel1
    Given relation(rel1) set supertype: rel0
    Given relation(rel1) create role: role1
    Given relation(rel1) get role(role1) set override: role0
    Given create entity type: ent0
    Given entity(ent0) set plays: rel0:role0
    Given create entity type: ent1
    Given entity(ent1) set supertype: ent0
    Given create entity type: ent2
    Given entity(ent2) set supertype: ent1
    Given transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent2) set plays: rel0:role0
    When entity(ent2) get plays(rel0:role0) set annotation: @card(1..1)
    When entity(ent2) get plays(rel0:role0) set override: rel0:role0
    When entity(ent1) set plays: rel1:role1
    When transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent1) get plays(rel1:role1) set override: rel0:role0
    Then transaction commits; fails


  Scenario: A thing-type may not be moved in a way that its plays declarations are hidden by an override
    Given create relation type: rel0
    Given relation(rel0) create role: role0
    Given create relation type: rel10
    Given relation(rel10) set supertype: rel0
    Given relation(rel10) create role: role10
    Given relation(rel10) get role(role10) set override: role0
    Given create relation type: rel11
    Given relation(rel11) set supertype: rel0
    Given relation(rel11) create role: role11
    Given relation(rel11) get role(role11) set override: role0

    Given create entity type: ent0
    Given entity(ent0) set plays: rel0:role0
    Given create entity type: ent1
    Given entity(ent1) set supertype: ent0
    Given entity(ent1) set plays: rel10:role10
    Given entity(ent1) get plays(rel10:role10) set override: rel0:role0

    # plays will be hidden under ent1
    Given create entity type: ent20
    Given entity(ent20) set plays: rel0:role0

    # Overridden will be hidden under ent1
    Given create entity type: ent21
    Given entity(ent21) set supertype: ent0
    Given entity(ent21) set plays: rel11:role11
    Given entity(ent21) get plays(rel11:role11) set override: rel0:role0

    # Will be redundant under ent1
    Given create entity type: ent22
    Given entity(ent22) set supertype: ent0
    Given entity(ent22) set plays: rel10:role10
    Given transaction commits

    When connection open schema transaction for database: typedb
    Then entity(ent20) set supertype: ent1; fails

    When transaction closes
    When connection open schema transaction for database: typedb
    Then entity(ent21) set supertype: ent1; fails

    When transaction closes
    When connection open schema transaction for database: typedb
    When entity(ent22) set supertype: ent1
    Then transaction commits; fails


  Scenario: A concrete type must override any ownerships of abstract attributes it inherits
    Given create attribute type: attr00
    Given attribute(attr00) set value type: string
    Given attribute(attr00) set annotation: @abstract
    Given create attribute type: attr10
    Given attribute(attr10) set supertype: attr00
    Given create attribute type: attr01
    Given attribute(attr01) set value type: string
    Given attribute(attr01) set annotation: @abstract
    Given create attribute type: attr11
    Given attribute(attr11) set supertype: attr01
    Given create entity type: ent00
    Given entity(ent00) set annotation: @abstract
    Given entity(ent00) set owns: attr00
    Given create entity type: ent01
    Given entity(ent01) set annotation: @abstract
    Given entity(ent01) set owns: attr01
    When create entity type: ent1
    Given transaction commits

    # inherits abstract ownership but does not override
    When connection open schema transaction for database: typedb
    When entity(ent1) set supertype: ent00
    Then transaction commits; fails

    # declares concrete ownership with a subtype but is missing override clause
    When connection open schema transaction for database: typedb
    When entity(ent1) set supertype: ent00
    When entity(ent1) set owns: attr10
    Then transaction commits; fails

    When connection open schema transaction for database: typedb
    When entity(ent1) set supertype: ent00
    When entity(ent1) set owns: attr10
    When entity(ent1) get owns(attr10) set override: attr00
    Then transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent1) set supertype: ent00
    When entity(ent1) set owns: attr10
    When entity(ent1) get owns(attr10) set override: attr00
    Then transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent1) set owns: attr11
    Then transaction commits

    When connection open schema transaction for database: typedb
    When entity(ent1) set supertype: ent01; fails

#  TODO: Refactor to functions
#  Scenario: Types which are referenced in rules may not be renamed
#    Given typeql define
#    """
#    define
#      rel00 sub relation, relates role00;
#      rel01 sub relation, relates role01;
#      ent0 sub entity, plays rel00:role00, plays rel01:role01;
#
#      rule make-me-illegal:
#      when {
#        (role00: $e) isa rel00;
#      } then {
#        (role01: $e) isa rel01;
#      };
#    """
#    Given transaction commits
#
#    When connection open schema transaction for database: typedb
#    Then relation(rel00) set label: renamed-rel00
#    Then transaction commits; fails

#  TODO: Refactor to functions
#  Scenario: Types which are referenced in rules may not be deleted
#    Given typeql define
#    """
#    define
#      rel00 sub relation, relates role00, relates extra_role;
#      rel01 sub relation, relates role01;
#      rel1 sub rel00;
#      ent0 sub entity, plays rel00:role00, plays rel01:role01;
#
#      rule make-me-illegal:
#      when {
#        (role00: $e) isa rel1;
#      } then {
#        (role01: $e) isa rel01;
#      };
#    """
#    Given transaction commits
#
#    When connection open schema transaction for database: typedb
#    Then delete relation type: rel01; fails
#
#    When transaction closes
#    When connection open schema transaction for database: typedb
#    Then delete relation type: rel1; fails
#
#    When transaction closes
#    When connection open schema transaction for database: typedb
#    Then relation(rel01) delete role: role01; fails
#
#    # We currently can't do this at operation time, so we check at commit-time
#    When transaction closes
#    When connection open schema transaction for database: typedb
#    Then relation(rel00) delete role: role00
#    Then transaction commits; fails

#  TODO: Refactor to functions
#  Scenario: Rules made unsatisfiable by schema modifications are flagged at commit time
#    Given typeql define
#    """
#    define
#      rel00 sub relation, relates role00, relates extra_role;
#      rel01 sub relation, relates role01;
#      rel1 sub rel00;
#
#      ent00 sub entity, abstract, plays rel00:role00, plays rel01:role01;
#      ent01 sub entity, abstract;
#      ent1 sub ent00;
#
#      rule make-me-unsatisfiable:
#      when {
#        $e isa ent1;
#        (role00: $e) isa rel1;
#      } then {
#        (role01: $e) isa rel01;
#      };
#    """
#    Given transaction commits
#
#    When connection open schema transaction for database: typedb
#    Then relation(rel1) set supertype: rel01
#    Then transaction commits; fails
#
#    When connection open schema transaction for database: typedb
#    Then entity(ent00) unset plays: rel00:role00
#    Then transaction commits; fails
#
#    When connection open schema transaction for database: typedb
#    Then entity(ent1) set supertype: ent01
#    Then transaction commits; fails


  Scenario: Annotations on ownership overrides must be at least as strict as the overridden ownerships
    Given create attribute type: attr0
    Given attribute(attr0) set value type: string
    Given attribute(attr0) set annotation: @abstract
    Given create attribute type: attr1
    Given attribute(attr1) set supertype: attr0
    Given create entity type: ent0k
    Given entity(ent0k) set annotation: @abstract
    Given entity(ent0k) set owns: attr0
    Given entity(ent0k) get owns(attr0) set annotation: @key
    Given create entity type: ent0n
    Given entity(ent0n) set annotation: @abstract
    Given entity(ent0n) set owns: attr0
    Given transaction commits

    When connection open schema transaction for database: typedb
    When create entity type: ent1u
    When entity(ent1u) set supertype: ent0k
    When entity(ent1u) set owns: attr1
    When entity(ent1u) get owns(attr1) set override: attr0
    Then entity(ent1u) get owns(attr1) set annotation: @unique; fails

    When transaction closes
    When connection open schema transaction for database: typedb
    When create entity type: ent1u
    When entity(ent1u) set supertype: ent0k
    When entity(ent1u) set owns: attr1
    When entity(ent1u) get owns(attr1) set annotation: @unique
    Then entity(ent1u) get owns(attr1) set override: attr0; fails

    When transaction closes
    When connection open schema transaction for database: typedb
    When create entity type: ent1u
    When entity(ent1u) set supertype: ent0n
    When entity(ent1u) set owns: attr1
    When entity(ent1u) get owns(attr1) set override: attr0
    When entity(ent1u) get owns(attr1) set annotation: @unique
    Then transaction commits

    When connection open schema transaction for database: typedb
    Then entity(ent1u) set supertype: ent0k; fails

    When transaction closes
    When connection open schema transaction for database: typedb
    When entity(ent0n) get owns(attr0) set annotation: @key
    Then transaction commits; fails


  Scenario: Annotations on ownership redeclarations must be stricter than the previous declaration or will be flagged as redundant on commit.
    Given create attribute type: attr0
    Given attribute(attr0) set value type: string
    Given create entity type: ent0n
    Given entity(ent0n) set annotation: @abstract
    Given entity(ent0n) set owns: attr0
    Given create entity type: ent0k
    Given entity(ent0k) set annotation: @abstract
    Given entity(ent0k) set owns: attr0
    Given entity(ent0k) get owns(attr0) set annotation: @key
    Given create entity type: ent0u
    Given entity(ent0u) set annotation: @abstract
    Given entity(ent0u) set owns: attr0
    Given entity(ent0u) get owns(attr0) set annotation: @unique
    Given transaction commits

    When connection open schema transaction for database: typedb
    When create entity type: ent1u
    When entity(ent1u) set supertype: ent0k
    When entity(ent1u) set owns: attr0
    Then transaction commits; fails

    When connection open schema transaction for database: typedb
    When create entity type: ent1u
    When entity(ent1u) set supertype: ent0k
    When entity(ent1u) set owns: attr0
    When entity(ent0u) get owns(attr0) set annotation: @unique
    Then transaction commits; fails

    When connection open schema transaction for database: typedb
    When create entity type: ent1u
    When entity(ent1u) set supertype: ent0k
    When entity(ent1u) set owns: attr0
    When entity(ent1u) get owns(attr0) set override: attr0
    When entity(ent0u) get owns(attr0) set annotation: @unique
    Then transaction commits; fails

    When connection open schema transaction for database: typedb
    When create entity type: ent1u
    When entity(ent1u) set supertype: ent0k
    When entity(ent1u) set owns: attr0
    When entity(ent0u) get owns(attr0) set annotation: @unique
    When entity(ent1u) get owns(attr0) set override: attr0
    Then transaction commits; fails

    When connection open schema transaction for database: typedb
    When create entity type: ent1u
    When entity(ent1u) set supertype: ent0u
    # Fails redundant annotations at commit
    When entity(ent1u) set owns: attr0
    When entity(ent1u) get owns(attr0) set annotation: @unique
    Then transaction commits; fails

    When connection open schema transaction for database: typedb
    When create entity type: ent1u
    When entity(ent1u) set supertype: ent0n
    When entity(ent1u) set owns: attr0
    When entity(ent1u) get owns(attr0) set annotation: @unique
    Then transaction commits; fails

    When connection open schema transaction for database: typedb
    When create entity type: ent1u
    When entity(ent1u) set supertype: ent0n
    When entity(ent1u) set owns: attr0
    When entity(ent1u) get owns(attr0) set annotation: @unique
    When entity(ent1u) get owns(attr0) set override: attr0
    When transaction commits

    When connection open schema transaction for database: typedb
    Then entity(ent1u) set supertype: ent0k; fails
    When entity(ent1u) get owns(attr0) unset override
    When entity(ent1u) set supertype: ent0k
    Then transaction commits; fails

    When connection open schema transaction for database: typedb
    When entity(ent0n) get owns(attr0) set annotation: @key
    Then transaction commits; fails
