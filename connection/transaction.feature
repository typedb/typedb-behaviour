#
# GRAKN.AI - THE KNOWLEDGE GRAPH
# Copyright (C) 2019 Grakn Labs Ltd
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

Feature: Transaction

  Background:
    Given connection has been opened
    Given connection has no keyspaces

  Scenario: session can open read transaction
    Given connection open session for keyspace: alice
    When session open transaction: read
    Then transaction is null: false
    Then transaction is open: true
    Then transaction has type: read
    Then transaction has keyspace: alice
    Then transaction has session has keyspace: alice

  Scenario: session can open write transaction
    Given connection open session for keyspace: bob
    When session open transaction: write
    Then transaction is null: false
    Then transaction is open: true
    Then transaction has type: write
    Then transaction has keyspace: bob
    Then transaction has session has keyspace: bob

  Scenario: session can open multiple read transaction

  Scenario: session can open multiple write transaction

  Scenario: session can open multiple read transaction in parallel

  Scenario: session can open multiple write transaction in parallel

  Scenario: sessions can open read transaction

  Scenario: sessions can open write transaction

  Scenario: sessions can open multiple read transaction

  Scenario: sessions can open multiple write transaction

  Scenario: sessions can open multiple read transaction in parallel

  Scenario: sessions can open multiple write transaction in parallel

  Scenario: sessions in parallel can open read transaction

  Scenario: sessions in parallel can open write transaction

  Scenario: sessions in parallel can open multiple read transaction

  Scenario: sessions in parallel can open multiple write transaction

  Scenario: sessions in parallel can open multiple read transaction in parallel

  Scenario: sessions in parallel can open multiple write transaction in parallel