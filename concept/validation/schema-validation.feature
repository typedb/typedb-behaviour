#
# Copyright (C) 2022 Vaticle
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
Feature: Schema validation

  #TODO: Should we divide this into operation & commit time validation?
  #TODO: Do we need to split scenarios per operation?

  Background:
    Given typedb starts
    Given connection opens with default authentication
    Given connection has been opened
    Given connection does not have any database
    Given connection create database: typedb
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write


  # Not a meaningful test. The step throws an exception before the server is hit.
  @ignore
  Scenario: Attribute-types can only subtype other attribute-types
    Given put entity type: ent0
    Given put relation type: rel0
    Given relation(rel0) set relates role: role0
    Given put attribute type: attr0, with value type: string
    Given attribute(attr0) set abstract: true
    Given transaction commits

    When session opens transaction of type: write
    When put attribute type: attr1, with value type: string
    Then transaction commits

    When session opens transaction of type: write
    When attribute(attr1) set supertype: attr0
    Then transaction commits

    When session opens transaction of type: write
    Then attribute(attr1) set supertype: ent0; throws exception
    When session opens transaction of type: write
    Then attribute(attr1) set supertype: rel0; throws exception
    When session opens transaction of type: write
    Then delete attribute type: attr0; throws exception


  # Not a meaningful test. The step throws an exception before the server is hit.
  @ignore
  Scenario: Entity-types can only subtype other entity-types
    Given put entity type: ent0
    Given put relation type: rel0
    Given relation(rel0) set relates role: role0
    Given put attribute type: attr0, with value type: string
    Given attribute(attr0) set abstract: true
    Given transaction commits

    When session opens transaction of type: write
    When put entity type: ent1
    Then transaction commits

    When session opens transaction of type: write
    When entity(ent1) set supertype: ent0
    Then transaction commits

    When session opens transaction of type: write
    Then entity(ent1) set supertype: attr0; throws exception
    When session opens transaction of type: write
    Then entity(ent1) set supertype: rel0; throws exception
    When session opens transaction of type: write
    Then delete entity type: ent0; throws exception


  # Not a meaningful test. The step throws an exception before the server is hit.
  @ignore
  Scenario: Relation-types can only subtype other relation-types
    Given put entity type: ent0
    Given put relation type: rel0
    Given relation(rel0) set relates role: role0
    Given put attribute type: attr0, with value type: string
    Given attribute(attr0) set abstract: true
    Given transaction commits

    When session opens transaction of type: write
    When put relation type: rel1
    When relation(rel1) set relates role: role1
    Then transaction commits

    When session opens transaction of type: write
    When relation(rel1) set supertype: rel0
    Then transaction commits

    When session opens transaction of type: write
    Then relation(rel1) set supertype: ent0; throws exception
    When session opens transaction of type: write
    Then relation(rel1) set supertype: attr0; throws exception
    When session opens transaction of type: write
    Then delete relation type: rel0; throws exception


  Scenario: Cyclic type hierarchies are disallowed
    Given put attribute type: attr0, with value type: string
    Given put attribute type: attr1, with value type: string
    Given attribute(attr0) set abstract: true
    Given attribute(attr1) set abstract: true
    Given attribute(attr1) set supertype: attr0
    Given put entity type: ent0
    Given put entity type: ent1
    Given entity(ent1) set supertype: ent0
    Given put relation type: rel0
    Given relation(rel0) set relates role: role0
    Given put relation type: rel1
    Given relation(rel1) set relates role: role1
    Given relation(rel1) set supertype: rel0
    Given transaction commits

    When session opens transaction of type: write
    Then attribute(attr1) set supertype: attr1; throws exception
    Given session transaction closes

    When session opens transaction of type: write
    Then attribute(attr0) set supertype: attr1; throws exception
    Given session transaction closes

    When session opens transaction of type: write
    Then entity(ent1) set supertype: ent1; throws exception
    Given session transaction closes

    When session opens transaction of type: write
    Then entity(ent0) set supertype: ent1; throws exception
    Given session transaction closes

    When session opens transaction of type: write
    Then relation(rel1) set supertype: rel1; throws exception
    Given session transaction closes

    When session opens transaction of type: write
    Then relation(rel0) set supertype: rel1; throws exception
    Given session transaction closes


  Scenario: An attribute-type must have the same value type as its ancestors
    Given put attribute type: attr0s, with value type: string
    Given attribute(attr0s) set abstract: true
    Given put attribute type: attr0d, with value type: double
    Given attribute(attr0d) set abstract: true
    Given put attribute type: attr1, with value type: string
    Given transaction commits

    When session opens transaction of type: write
    When attribute(attr1) set supertype: attr0s
    Then transaction commits

    When session opens transaction of type: write
    Then attribute(attr1) set supertype: attr0d; throws exception


  Scenario: Only abstract attributes may be subtyped
    Given put attribute type: attr0a, with value type: string
    Given put attribute type: attr0c, with value type: string
    Given attribute(attr0a) set abstract: true
    Given transaction commits

    When session opens transaction of type: write
    When put attribute type: attr1, with value type: string
    When attribute(attr1) set supertype: attr0c; throws exception

    When session opens transaction of type: write
    When put attribute type: attr1, with value type: string
    When attribute(attr1) set supertype: attr0a
    Then transaction commits

    When session opens transaction of type: write
    When attribute(attr1) set supertype: attr0c
    Then transaction commits; throws exception

    When session opens transaction of type: write
    When attribute(attr00) set abstract: false
    Then transaction commits; throws exception


  # Relation types must relate at least one role
  Scenario: Concrete relation types must relate at least one role - basic
    When put relation type: rel0c
    Then transaction commits; throws exception

    # ADD_TYPE
    When session opens transaction of type: write
    When put relation type: rel0c
    When relation(rel0c) set relates role: role0c
    Then transaction commits

    # DEL_ITF
    When session opens transaction of type: write
    When relation(rel0c) unset related role: role0c
    Then transaction commits; throws exception

    When session opens transaction of type: write
    When put relation type: rel0a
    When relation(rel0a) set abstract: true
    Then transaction commits

    # DEL_ABS
    When session opens transaction of type: write
    When put relation type: rel0a
    When relation(rel0a) set abstract: false
    Then transaction commits; throws exception


  Scenario: Concrete relation types must relate at least one role, but these may be inherited
    Given put relation type: rel00
    Given relation(rel00) set abstract: true
    Given relation(rel00) set relates role: role00
    Given put relation type: rel01
    Given relation(rel01) set abstract: true
    Given transaction commits

    # ADD_TYPE
    When session opens transaction of type: write
    When put relation type: rel1
    When relation(rel1) set supertype: rel01
    Then transaction commits; throws exception

    When session opens transaction of type: write
    When put relation type: rel1
    When relation(rel1) set supertype: rel00
    Then transaction commits

    # DEL_ITF
    When session opens transaction of type: write
    When relation(rel00) unset related role: role00
    Then transaction commits; throws exception

    # MOVE_TYPE
    When session opens transaction of type: write
    When relation(rel1) set supertype: rel01
    Then transaction commits; throws exception


  Scenario: Concrete types may not own abstract attributes
    Given put attribute type: attr0, with value type: string
    Given attribute(attr0) set abstract: true
    Given put entity type: ent0
    Given transaction commits

    When session opens transaction of type: write
    When entity(ent0) set owns attribute type: attr0
    Then transaction commits; throws exception

    When session opens transaction of type: write
    When entity(ent0) set abstract: true
    When entity(ent0) set owns attribute type: attr0
    Then transaction commits

    When session opens transaction of type: write
    When entity(ent0) set abstract: false
    Then transaction commits; throws exception

    When session opens transaction of type: write
    When put entity type: ent1
    When entity(ent1) set supertype: ent0
    Then transaction commits; throws exception


  Scenario: Modifying a relation or role does not leave invalid overrides
    Given put relation type: rel00
    Given relation(rel00) set relates role: role00
    Given relation(rel00) set relates role: extra_role
    Given put relation type: rel01
    Given relation(rel01) set relates role: role01
    Given put relation type: rel1
    Given relation(rel1) set supertype: rel00
    Given put relation type: rel2
    Given relation(rel2) set supertype: rel1
    Given relation(rel2) set relates role: role2 as role00
    Given transaction commits

    When session opens transaction of type: write
    Then relation(rel00) unset related role: role00; throws exception

    When session opens transaction of type: write
    Then relation(rel2) set supertype: rel01; throws exception
    Then session transaction close

    When session opens transaction of type: write
    Then relation(rel1) set relates role: role1 as role00; throws exception


  Scenario: Deleting a role does not leave dangling 'plays' declarations
    Given put relation type: rel0
    Given relation(rel0) set relates role: role0
    Given relation(rel0) set relates role: extra_role
    Given put entity type: ent0
    Given entity(ent0) set plays role: rel0:role0
    Given transaction commits

    When session opens transaction of type: write
    When entity(ent0) get playing roles contain:
      | rel0:role0 |
    When relation(rel0) unset related role: role0
    Then entity(ent0) get playing roles do not contain:
      | rel0:role0 |
    Then transaction commits


  Scenario: Deleting an attribute-type does not leave dangling 'owns' declarations
    Given put attribute type: attr0, with value type: string
    Given put entity type: ent0
    Given entity(ent0) set owns attribute type: attr0
    Given transaction commits

    When session opens transaction of type: write
    When entity(ent0) get owns attribute types contain:
      | attr0 |
    When delete attribute type: attr0
    Then entity(ent0) get owns attribute types do not contain:
      | attr0 |
    Then transaction commits


  Scenario: The schema does not contain redundant owns declarations
    Given put attribute type: attr0, with value type: string
    Given put entity type: ent00
    Given entity(ent00) set owns attribute type: attr0
    Given put entity type: ent01
    Given put entity type: ent1
    Given entity(ent1) set supertype: ent00
    Given transaction commits

    When session opens transaction of type: write
    Then entity(ent1) set owns attribute type: attr0
    Then transaction commits; throws exception

    When entity(ent1) set supertype: ent01
    When entity(ent1) set owns attribute type: attr0
    Then transaction commits

    When session opens transaction of type: write
    # Bug? Transaction commits fine. It's a redundant owns but not wrong
    Then entity(ent1) set supertype: ent00
    Then transaction commits; throws exception


  Scenario: The schema does not contain redundant plays declarations
    Given put relation type: rel0
    Given relation(rel0) set relates role: role0
    Given put entity type: ent00
    Given entity(ent00) set plays role: rel0:role0
    Given put entity type: ent01
    Given put entity type: ent1
    Given entity(ent1) set supertype: ent00
    Given transaction commits

    When session opens transaction of type: write
    Then entity(ent1) set plays role: rel0:role0
    Then transaction commits; throws exception

    When session opens transaction of type: write
    When entity(ent1) set supertype: ent01
    When entity(ent1) set plays role: rel0:role0
    Then transaction commits

    When session opens transaction of type: write
    # Bug? Transaction commits fine. It's a redundant owns but not wrong
    Then entity(ent1) set supertype: ent00
    Then transaction commits; throws exception


  Scenario: A relation-type may only override role-types it inherits
    Given put relation type: rel00
    Given relation(rel00) set relates role: role00
    Given put relation type: rel01
    Given relation(rel01) set relates role: role01
    Given transaction commits

    When session opens transaction of type: write
    When put relation type: rel1
    Then relation(rel1) set relates role: role1 as role00; throws exception
    Given session transaction closes

    When session opens transaction of type: write
    When put relation type: rel1
    When relation(rel1) set supertype: rel00
    Then relation(rel1) set relates role: role1 as role00
    Then relation(rel1) get related roles contain:
      | rel1:role1 |
    Then relation(rel1) get related roles do not contain:
      | rel0:role0 |
    Then transaction commits

    When session opens transaction of type: write
    Then relation(rel1) set supertype: rel01; throws exception
    Given session transaction closes

    When session opens transaction of type: write
    Then relation(rel00) unset related role: role00; throws exception
    Given session transaction closes


  Scenario: A type may only override an ownership it inherits
    Given put attribute type: attr0, with value type: string
    Given attribute(attr0) set abstract: true
    Given put attribute type: attr1, with value type: string
    Given attribute(attr1) set supertype: attr0
    Given put entity type: ent00
    Given entity(ent00) set abstract: true
    Given entity(ent00) set owns attribute type: attr0
    Given put entity type: ent01
    Given entity(ent01) set abstract: true
    Given transaction commits

    When session opens transaction of type: write
    When put entity type: ent1
    Then entity(ent1) set owns attribute type: attr1 as attr0; throws exception

    When session opens transaction of type: write
    When put entity type: ent1
    When entity(ent1) set supertype: ent00
    When entity(ent1) set owns attribute type: attr1 as attr0
    Then transaction commits

    When session opens transaction of type: write
    When entity(ent00) unset owns attribute type: attr0
    Then transaction commits; throws exception

    When session opens transaction of type: write
    When entity(ent1) set supertype: ent01
    Then transaction commits; throws exception


  Scenario: A type may only override an ownership it inherits with a subtype of the inherited attribute
    Given put attribute type: attr0, with value type: string
    Given attribute(attr0) set abstract: true
    Given put attribute type: attr1, with value type: string
    # Same, but the attributes are not subtypes
    Given put entity type: ent00
    Given entity(ent00) set abstract: true
    Given entity(ent00) set owns attribute type: attr0
    Given transaction commits

    When session opens transaction of type: write
    When put entity type: ent1
    When entity(ent1) set supertype: ent00
    Then entity(ent1) set owns attribute type: attr1 as attr0; throws exception


  Scenario: A type may only override a role it plays by inheritance
    Given put relation type: rel0
    Given relation(rel0) set relates role: role0
    Given put relation type: rel1
    Given relation(rel1) set supertype: rel0
    # Not yet as an override
    Given relation(rel1) set relates role: role1
    Given put entity type: ent00
    Given entity(ent00) set plays role: rel0:role0
    Given put entity type: ent01
    Given transaction commits

    # Roles aren't subtypes of each other
    When session opens transaction of type: write
    When put entity type: ent1
    When entity(ent1) set supertype: ent00
    Then entity(ent1) set plays role: rel1:role1 as rel0:role0; throws exception

    When session opens transaction of type: write
    When relation(rel1) set relates role: role1 as role0
    Then transaction commits

    # ent1 doesn't sub ent00
    When session opens transaction of type: write
    When put entity type: ent1
    Then entity(ent1) set plays role: rel1:role1 as rel0:role0; throws exception

    When session opens transaction of type: write
    When put entity type: ent1
    When entity(ent1) set supertype: ent00
    When entity(ent1) get playing roles contain:
      | rel0:role0 |
    # First without override
    Then entity(ent1) set plays role: rel1:role1
    Then entity(ent1) get playing roles contain:
      | rel0:role0 |
      | rel1:role1 |
    Then transaction commits

    When session opens transaction of type: write
    Then entity(ent1) set plays role: rel1:role1 as rel0:role0
    Then entity(ent1) get playing roles contain:
      | rel1:role1 |
    Then entity(ent1) get playing roles do not contain:
      | rel0:role0 |
    Then transaction commits


  Scenario: The schema may not be modified in a way that an overridden plays role is no longer inherited by the overriding type
    Given put relation type: rel0
    Given relation(rel0) set relates role: role0
    Given put relation type: rel1
    Given relation(rel1) set supertype: rel0
    Given relation(rel1) set relates role: role1 as role0
    Given put entity type: ent00
    Given entity(ent00) set plays role: rel0:role0
    Given put entity type: ent1
    Given entity(ent1) set supertype: ent00
    Given entity(ent1) set plays role: rel1:role1 as rel0:role0
    Given put entity type: ent01
    Given transaction commits

    When session opens transaction of type: write
    # Remove the relates override of role1 on role0
    Then relation(rel1) set relates role: role1
    Then transaction commits; throws exception

    When session opens transaction of type: write
    Then entity(ent00) unset plays role: rel0:role0
    # BUG: Doesn't throw
    Then transaction commits; throws exception

    When session opens transaction of type: write
    Then entity(ent1) set supertype: ent01
    # BUG: Doesn't throw
    Then transaction commits; throws exception


  Scenario: A concrete type must override any ownerships of abstract attributes it inherits.
    Given put attribute type: attr00, with value type: string
    Given attribute(attr00) set abstract: true
    Given put attribute type: attr10, with value type: string
    Given attribute(attr10) set supertype: attr00
    Given put attribute type: attr01, with value type: string
    Given attribute(attr01) set abstract: true
    Given put attribute type: attr11, with value type: string
    Given attribute(attr11) set supertype: attr01
    Given put entity type: ent00
    Given entity(ent00) set abstract: true
    Given entity(ent00) set owns attribute type: attr00
    Given put entity type: ent01
    Given entity(ent01) set abstract: true
    Given entity(ent01) set owns attribute type: attr01
    When put entity type: ent1
    Given transaction commits

    #  MUST_OVERRIDE: declares concrete ownership but is missing override clause
    When session opens transaction of type: write
    When entity(ent1) set supertype: ent00
    Then transaction commits; throws exception

    # MISSING_OVERRIDE: declares concrete ownership but is missing override clause
    When session opens transaction of type: write
    When entity(ent1) set supertype: ent00
    When entity(ent1) set owns attribute type: attr10
    Then transaction commits; throws exception

    When session opens transaction of type: write
    When entity(ent1) set supertype: ent00
    When entity(ent1) set owns attribute type: attr10 as attr00
    Then transaction commits

    When session opens transaction of type: write
    When entity(ent1) set supertype: ent00
    When entity(ent1) set owns attribute type: attr10 as attr00
    Then transaction commits

    When session opens transaction of type: write
    When entity(ent1) set owns attribute type: attr11
    Then transaction commits

    When session opens transaction of type: write
    When entity(ent1) set supertype: ent01
    Then transaction commits; throws exception


  Scenario: Types which are referenced in rules may not be deleted
    Given typeql define
    """
    define
      rel00 sub relation, relates role00, relates extra_role;
      rel01 sub relation, relates role01;
      rel1 sub rel00;
      ent0 sub entity, plays rel00:role00, plays rel01:role01;

      rule make-me-illegal:
      when {
        (role00: $e) isa rel1;
      } then {
        (role01: $e) isa rel01;
      };
    """
    Given transaction commits

    When session opens transaction of type: write
    Then delete relation type: rel00; throws exception

    When session opens transaction of type: write
    Then delete relation type: rel01; throws exception

    When session opens transaction of type: write
    Then relation(rel00) unset related role: role00; throws exception

    When session opens transaction of type: write
    Then relation(rel01) unset related role: role01; throws exception

    # TODO: Do we want to do this at operation time or commit time?
    When session opens transaction of type: write
    Then relation(rel1) set supertype: rel01; throws exception


  Scenario: Rules made unsatisfiable by schema modifications are flagged at commit time
    Given typeql define
    """
    define
      rel0 sub relation, relates role00, relates role01;
      ent00 sub entity, abstract, plays rel0:role00, plays rel0:role01;
      ent01 sub entity, abstract;
      ent1 sub ent00;

      rule make-me-unsatisfiable:
      when {
        $e isa ent1;
        (role00: $e) isa rel0;
      } then {
        (role01: $e) isa rel0;
      };
    """
    Given transaction commits

    When session opens transaction of type: write
    Then entity(ent00) unset plays role: rel0:role00
    Then transaction commits; throws exception

    When session opens transaction of type: write
    Then entity(ent1) set supertype: ent01
    Then transaction commits; throws exception
