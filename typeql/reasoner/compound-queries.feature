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
Feature: Compound Query Resolution

  Background: Set up database
    When typedb starts
    And open connection
    Given reasoning schema
      """
      define

      person sub entity,
        owns name;

      soft-drink sub entity,
        owns name,
        owns retailer;

      string-attribute sub attribute, value string, abstract;
      retailer sub attribute, value string;
      name sub attribute, value string;
      """
    # each scenario specialises the schema further


  Scenario: repeated concludable patterns within a query trigger rules from all pattern occurrences
    Given reasoning schema
      """
      define
      base-attribute sub attribute, value string, abstract;
      base-string-attribute sub base-attribute;
      retailer sub base-attribute;
      brand-name sub base-attribute;

      person owns base-string-attribute;
      soft-drink owns retailer, owns base-string-attribute, owns brand-name;

      rule tesco-sells-all-soft-drinks: when {
        $x isa soft-drink;
      } then {
        $x has retailer "Tesco";
      };
      """
    Given reasoning data
      """
      insert
      $x isa person, has base-string-attribute "Tesco";
      $y isa soft-drink, has brand-name "Tesco";
      """
    Given verifier is initialised
    Given reasoning query
      """
      match
        $x has base-attribute $ax;
        $y has base-attribute $ay;
      """
    Then verify answers are sound
    Then verify answers are complete
    # x   | ax  | y   | ay  |
    # PER | BSA | SOF | NAM |
    # PER | BSA | SOF | RET |
    # SOF | NAM | PER | BSA |
    # SOF | RET | PER | BSA |
    # SOF | NAM | SOF | RET |
    # SOF | RET | SOF | NAM |
    Then verify answer size is: 9
    Then verify answers are sound
    Then verify answers are complete
