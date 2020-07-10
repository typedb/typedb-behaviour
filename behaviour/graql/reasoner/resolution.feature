#
# Copyright (C) 2020 Grakn Labs
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

# TODO: these tests should be implemented somewhere, but probably not in a file called 'resolution.feature'
Feature: Graql Reasoner Resolution

  Background: Initialise a session and transaction for each scenario
    Given connection has been opened
    Given connection delete all keyspaces
    Given connection open sessions for keyspaces:
      | test_resolution |
    Given transaction is initialised

  Scenario: `isa` matches inferred relations

  Scenario: `isa` matches inferred roleplayers in relation instances

  Scenario: `isa` matches inferred types that are subtypes of the thing's defined type

  Scenario: `isa` matches inferred types that are unrelated to the thing's defined type
