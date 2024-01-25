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
    Given put entity type: ent0
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
    Given put entity type: ent0a
    Given entity(ent0a) set abstract: true
    Given put entity type: ent0c
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
    Given put entity type: ent00
    Given put attribute type: attr00, with value type: string
    Given entity(ent00) set owns attribute type: attr00
    Given put entity type: ent1
    Given entity(ent1) set supertype: ent00
    Given put entity type: ent01
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
    # BUG?: The transaction goes through fine
    Then entity(ent1) set supertype: ent01; throws exception


  Scenario: Instances of role-playing not in the schema must not exist
    Given put relation type: rel0
    Given relation(rel0) set relates role: role0
    Given put relation type: rel1
    Given relation(rel1) set supertype: rel0
    Given relation(rel1) set relates role: role1 as role0
    Given put entity type: ent00
    Given entity(ent00) set plays role: rel0:role0
    Given put entity type: ent1
    Given entity(ent1) set supertype: ent00
    Given put entity type: ent01
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
    Then entity(ent00) unset plays role: rel0:role0; throws exception

    When session opens transaction of type: write
    # Bug?: The transaction goes through fine
    Then entity(ent1) set supertype: ent01; throws exception

  # If we ever introduce abstract roles, we need a scenario here


  Scenario: Instances of role-playing hidden by a relates override must not exist
    Given put relation type: rel0
    Given relation(rel0) set relates role: role0
    Given put relation type: rel1
    Given relation(rel1) set supertype: rel0
    Given relation(rel1) set relates role: role1 as role0
    Given put entity type: ent00
    Given entity(ent00) set plays role: rel0:role0
    Given entity(ent00) set plays role: rel1:role1
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


  Scenario: A relation type may not override a role if instances of that type involving that role exist
    Given put relation type: rel0
    Given relation(rel0) set relates role: role0
    Given put relation type: rel1
    Given relation(rel1) set supertype: rel0
    # With no override
    Given relation(rel1) set relates role: role1
    Given put entity type: ent00
    Given entity(ent00) set plays role: rel0:role0
    Given entity(ent00) set plays role: rel1:role1
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb

    When session opens transaction of type: write
    When $ent00 = entity(ent00) create new instance
    When $rel1 = relation(rel1) create new instance
    When relation $rel1 add player for role(role0): $ent00
    Then transaction commits

    Given connection close all sessions
    Given connection open schema session for database: typedb
    When session opens transaction of type: write
    # Bug: The transaction goes through fine
    Then relation(rel1) set relates role: role1 as role0; throws exception


  Scenario: Instances of role-playing hidden by a plays override must not exist
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


  Scenario: A type may not override a role it plays through inheritance if instances of that type playing that role
    Given put relation type: rel0
    Given relation(rel0) set relates role: role0
    Given put relation type: rel1
    Given relation(rel1) set supertype: rel0
    Given relation(rel1) set relates role: role1 as role0
    Given put entity type: ent00
    Given entity(ent00) set plays role: rel0:role0
    Given put entity type: ent1
    Given entity(ent1) set supertype: ent00
    # Without the override
    Given entity(ent1) set plays role: rel1:role1
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb

    When session opens transaction of type: write
    When $ent1 = entity(ent1) create new instance
    When $rel0 = relation(rel0) create new instance
    When relation $rel0 add player for role(role0): $ent1
    Then transaction commits

    Given connection close all sessions
    Given connection open schema session for database: typedb

    When session opens transaction of type: write
    # Bug?: The transaction goes through fine.
    Then entity(ent1) set plays role: rel1:role1 as rel0:role0; throws exception


  Scenario: A type may not be moved if it has instances of it playing a role which would be hidden as a result of that move
    Given put relation type: rel0
    Given relation(rel0) set relates role: role0
    Given put relation type: rel1
    Given relation(rel1) set supertype: rel0
    Given relation(rel1) set relates role: role1 as role0
    Given put entity type: ent0
    Given entity(ent0) set plays role: rel0:role0
    Given put entity type: ent10
    Given entity(ent10) set supertype: ent0
    Given put entity type: ent2
    Given entity(ent2) set supertype: ent10
    Given put entity type: ent11
    Given entity(ent11) set supertype: ent0
    Given entity(ent11) set plays role: rel1:role1 as rel0:role0
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
