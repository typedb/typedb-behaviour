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

Feature: Connection Transaction

  Background:
    Given connection has been opened
    Given connection delete all keyspaces
    Given connection does not have any keyspace

  Scenario: session can open one read transaction
    Given connection open 1 session for one keyspace: alice
    When session open 1 transaction of type: read
    Then transaction is null: false
    Then transaction is open: true
    Then transaction has type: read
    Then transaction has keyspace: alice

  Scenario: session can open one write transaction
    Given connection open 1 session for one keyspace: alice
    When session open 1 transaction of type: write
    Then transaction is null: false
    Then transaction is open: true
    Then transaction has type: write
    Then transaction has keyspace: alice

  Scenario: session can open multiple read transaction
    Given connection open 1 session for one keyspace: alice
    When session open 32 transactions of type: read
    Then transactions are null: false
    Then transactions are open: true
    Then transactions have type: read
    Then transactions have keyspace: alice

  Scenario: session can open multiple write transaction
    Given connection open 1 session for one keyspace: alice
    When session open 32 transactions of type: write
    Then transactions are null: false
    Then transactions are open: true
    Then transactions have type: write
    Then transactions have keyspace: alice

#  Scenario: session can open multiple read transaction in parallel
#    Given connection open 1 session for one keyspace: alice
#    When session open 32 transactions in parallel of type: read
#    Then transactions in parallel are null: false
#    Then transactions in parallel are open: true
#    Then transactions in parallel have type: read
#    Then transactions in parallel have keyspace: alice
#
#  Scenario: session can open multiple write transaction in parallel
#    Given connection open 1 session for one keyspace: alice
#    When session open 32 transactions in parallel of type: write
#    Then transactions in parallel are null: false
#    Then transactions in parallel are open: true
#    Then transactions in parallel have type: write
#    Then transactions in parallel have keyspace: alice

#  Scenario: sessions can each open one read transaction
#
#  Scenario: sessions can each open one write transaction
#
#  Scenario: sessions can each open multiple read transaction
#
#  Scenario: sessions can each open multiple write transaction
#
#  Scenario: sessions can each open multiple read transaction in parallel
#
#  Scenario: sessions can each open multiple write transaction in parallel
#
#  Scenario: sessions in parallel can each open one read transaction
#
#  Scenario: sessions in parallel can each open one write transaction
#
#  Scenario: sessions in parallel can each open multiple read transaction
#
#  Scenario: sessions in parallel can each open multiple write transaction
#
#  Scenario: sessions in parallel can each open multiple read transaction in parallel
#
#  Scenario: sessions in parallel can each open multiple write transaction in parallel