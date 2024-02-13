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
Feature: Schema migration

  Background:
    Given typedb starts
    Given connection opens with default authentication
    Given connection has been opened
    Given connection does not have any database
    Given connection create database: typedb
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write


  Scenario: An ownership can be moved down one type, with data in place at the lower levels
    Given put attribute type: attr0, with value type: string
    Given put entity type: ent0
    Given entity(ent0) set owns attribute type: attr0, with annotations: key
    Given put entity type: ent1
    Given entity(ent1) set supertype: ent0
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given $ent1 = entity(ent1) create new instance
    Given $attr0 = attribute(attr0) as(string) put: "attr0"
    Given entity $ent1 set has: $attr0
    Given transaction commits

    Given connection close all sessions
    Given connection open schema session for database: typedb

    # Should break
    When session opens transaction of type: write
    Then entity(ent1) set owns attribute type: attr0, with annotations: unique; throws exception

    When session opens transaction of type: write
    Then entity(ent0) unset owns attribute type: attr0; throws exception

    When session opens transaction of type: write
    When entity(ent1) set owns attribute type: attr0, with annotations: key
    # Can't commit yet, because of the redundant declarations
    Then transaction commits; throws exception

    When session opens transaction of type: write
    When entity(ent1) set owns attribute type: attr0, with annotations: key
    When entity(ent0) unset owns attribute type: attr0
    Then transaction commits


  Scenario: An ownership can be moved up one type, with data in place
    Given put attribute type: attr0, with value type: string
    Given put entity type: ent0
    Given put entity type: ent1
    Given entity(ent1) set supertype: ent0
    Given entity(ent1) set owns attribute type: attr0, with annotations: key
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given $ent1 = entity(ent1) create new instance
    Given $attr0 = attribute(attr0) as(string) put: "attr0"
    Given entity $ent1 set has: $attr0
    Given transaction commits

    Given connection close all sessions
    Given connection open schema session for database: typedb

    When session opens transaction of type: write
    When entity(ent0) set owns attribute type: attr0, with annotations: key
    # Can't commit yet, because of the redundant declarations
    Then transaction commits; throws exception

    When session opens transaction of type: write
    When entity(ent0) set owns attribute type: attr0, with annotations: key
    When entity(ent1) unset owns attribute type: attr0
    Then transaction commits


  Scenario: A played role can be moved down one type, with data in place at the lower levels
    Given put relation type: rel0
    Given relation(rel0) set relates role: role0
    Given put entity type: ent0
    Given entity(ent0) set plays role: rel0:role0
    Given put entity type: ent1
    Given entity(ent1) set supertype: ent0
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
    Then entity(ent0) unset plays role: rel0:role0; throws exception

    When session opens transaction of type: write
    Then entity(ent1) set plays role: rel0:role0
    Then entity(ent0) unset plays role: rel0:role0
    Then transaction commits


  Scenario: A played role can be moved up one type, with data in place
    Given put relation type: rel0
    Given relation(rel0) set relates role: role0
    Given put entity type: ent0
    Given put entity type: ent1
    Given entity(ent1) set supertype: ent0
    Given entity(ent1) set plays role: rel0:role0
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
    Then entity(ent0) set plays role: rel0:role0
    Then entity(ent1) unset plays role: rel0:role0
    Then transaction commits


  Scenario: A type moved with ownership instances in-place by re-declaring ownerships
    Given put attribute type: attr0, with value type: string
    Given put entity type: ent0
    Given entity(ent0) set owns attribute type: attr0, with annotations: key
    Given put entity type: ent1
    Given entity(ent1) set supertype: ent0
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given $ent1 = entity(ent1) create new instance
    Given $attr0 = attribute(attr0) as(string) put: "attr0"
    Given entity $ent1 set has: $attr0
    Given transaction commits

    Given connection close all sessions
    Given connection open schema session for database: typedb

    # Should break
    When session opens transaction of type: write
    Then entity(ent1) set supertype: entity; throws exception
    Given session transaction close

    When session opens transaction of type: write
    Then entity(ent1) set owns attribute type: attr0, with annotations: key
    Then entity(ent1) set supertype: entity
    Then transaction commits


  Scenario: A type moved with plays instances in-place by re-declaring played roles
    Given put relation type: rel0
    Given relation(rel0) set relates role: role0
    Given put entity type: ent0
    Given entity(ent0) set plays role: rel0:role0
    Given put entity type: ent1
    Given entity(ent1) set supertype: ent0
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
    Then entity(ent1) set supertype: entity; throws exception

    When session opens transaction of type: write
    Then entity(ent1) set plays role: rel0:role0
    Then entity(ent1) set supertype: entity
    Then transaction commits
