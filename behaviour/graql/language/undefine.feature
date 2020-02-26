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
Feature: Graql Undefine Query

  Scenario: undefine a subtype removes a type
    Given graql define
      | define dog sub entity; |
    Given the integrity is validated
    When get answers of graql query
      | match $x type dog; get; |
    # do we want to also check the number of answers
    Then answers are labeled
      | x   |
      | dog |


  Scenario: undefine 'plays' from super entity removes 'plays' from subtypes


  Scenario: undefine 'has' from super entity removes 'has' from child entity


  Scenario: undefine 'key' from super entity removes 'key' from child entity


  @ignore
  # re-enable when 'relates' is inherited
  Scenario: undefine 'relates' from super relation removes 'relates' from child relation


  @ignore
  # re-enable when 'relates' is bound to a relation and blockable
  Scenario: undefine 'relates' from super relation that is overriden using 'as' removes override from child (?)

  Scenario: undefine a sub-role using 'as' removes sub-role from child relations


  Scenario: undefine 'plays' from super relation removes 'plays' from child relation
  Scenario: undefine 'has' from super relation removes 'has' from child relation
  Scenario: undefine 'key' from super relation removes 'key' from child relation


  Scenario: undefine 'plays' from super attribute removes 'plays' from child attribute
  Scenario: undefine 'has' from super attribute removes 'has' from child attribute
  Scenario: undefine 'key' from super attribute removes 'key' from child attribute



  Scenario: undefine a type as abstract converts an abstract to concrete type

  Scenario: undefine a type as abstract errors if has abstract child types (?)

  Scenario: undefine a regex on an attribute type, removes regex constraints on attribute

  Scenario: undefine a rule removes a rule

  Scenario: undefining an attribute key- and owner-ship removes implicit owner-/key-ship relation types

  Scenario: undefining an attribute subtype removes implicit ownership relation from hierarchy

  Scenario: undefining all attribute ownerships removes implicit ownership relation (?)
