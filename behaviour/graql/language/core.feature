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
Feature: Graql Base Cases

  Assertions over the extremely basic functionality of Graql
  For instance, checking validity and existence of very simple defines, etc.
  None of these share any background context

  Scenario: Empty graph is Valid
    Given the KB is valid


  Scenario: define a subtype creates a type
    Given the schema
      | define person sub entity; |
    And the KB is valid
    When executing
      |  match $x type child; get; |
    Then there is 1 answer


  Scenario: define subtype creates child of supertype
    Given the schema
      | define person sub entity; |
    And the KB is valid

    And the schema
      | define child sub person;  |
    And the KB is valid

    When executing
      | match $x sub person; get; |
    Then there are 2 answers

