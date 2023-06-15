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
Feature: Concept Rule

  Background:
    Given typedb starts
    Given connection opens with default authentication
    Given connection has been opened
    Given connection does not have any database
    Given connection create database: typedb
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write

  Scenario: Rule can be deleted
    Given typeql define
      """
      define

      person sub entity,
        owns name,
        plays friendship:friend,
        plays marriage:husband,
        plays marriage:wife;
      name sub attribute, value string;
      friendship sub relation,
        relates friend;
      marriage sub relation,
        relates husband, relates wife;
      """
    Given typeql define
      """
      define

      rule marriage-is-friendship: when {
        $x isa person; $y isa person;
        (husband: $x, wife: $y) isa marriage;
      } then {
        (friend: $x, friend: $y) isa friendship;
      };
      """
    Then rules contain: marriage-is-friendship
    When delete rule: marriage-is-friendship
    Then transaction commits
    When session opens transaction of type: read
    Then rules do not contain: marriage-is-friendship

  Scenario: Rule can be renamed
    Given typeql define
      """
      define

      person sub entity,
        owns name,
        plays friendship:friend,
        plays marriage:husband,
        plays marriage:wife;
      name sub attribute, value string;
      friendship sub relation,
        relates friend;
      marriage sub relation,
        relates husband, relates wife;
      """
    Given typeql define
      """
      define

      rule a-rule: when {
        $x isa person; $y isa person;
        (husband: $x, wife: $y) isa marriage;
      } then {
        (friend: $x, friend: $y) isa friendship;
      };
      """
    When rule(a-rule) set label: marriage-is-friendship
    Then transaction commits
    When session opens transaction of type: read
    Then rules contain: marriage-is-friendship
    Then rules do not contain: a-rule

  # TODO: re-enable when we fix it in typedb-core (https://github.com/vaticle/typedb/issues/6825)
  @ignore
  Scenario: Rule can be deleted without committing
    Given typeql define
      """
      define

      person sub entity,
        owns name,
        plays friendship:friend,
        plays marriage:husband,
        plays marriage:wife;
      name sub attribute, value string;
      friendship sub relation,
        relates friend;
      marriage sub relation,
        relates husband, relates wife;
      """
    Given typeql define
      """
      define

      rule marriage-is-friendship: when {
        $x isa person; $y isa person;
        (husband: $x, wife: $y) isa marriage;
      } then {
        (friend: $x, friend: $y) isa friendship;
      };
      """
    Then rules contain: marriage-is-friendship
    When delete rule: marriage-is-friendship
    Then rules do not contain: marriage-is-friendship

  # TODO: re-enable when we fix it in typedb-core (https://github.com/vaticle/typedb/issues/6825)
  @ignore
  Scenario: Rule can be renamed without committing
    Given typeql define
      """
      define

      person sub entity,
        owns name,
        plays friendship:friend,
        plays marriage:husband,
        plays marriage:wife;
      name sub attribute, value string;
      friendship sub relation,
        relates friend;
      marriage sub relation,
        relates husband, relates wife;
      """
    Given typeql define
      """
      define

      rule a-rule: when {
        $x isa person; $y isa person;
        (husband: $x, wife: $y) isa marriage;
      } then {
        (friend: $x, friend: $y) isa friendship;
      };
      """
    When rule(a-rule) set label: marriage-is-friendship
    Then rules contain: marriage-is-friendship
    Then rules do not contain: a-rule
