# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Schema validation

  Background:
    Given typedb starts
    Given connection opens with default authentication
    Given connection is open: true
    Given connection has 0 databases
    Given connection create database: typedb
    Given connection open schema transaction for database: typedb

  # TODO: Refactor existing tests to functions and add new ones!

#  TODO: Refactor to functions
#  Scenario: Types which are referenced in rules may not be renamed
#    Given typeql schema query
#    """
#    define
#      rel00 sub relation, relates role00;
#      rel01 sub relation, relates role01;
#      ent0 sub entity, plays rel00:role00, plays rel01:role01;
#
#      rule make-me-illegal:
#      when {
#        (role00: $e) isa rel00;
#      } then {
#        (role01: $e) isa rel01;
#      };
#    """
#    Given transaction commits
#
#    When connection open schema transaction for database: typedb
#    Then relation(rel00) set label: renamed-rel00
#    Then transaction commits; fails

#  TODO: Refactor to functions
#  Scenario: Types which are referenced in rules may not be deleted
#    Given typeql schema query
#    """
#    define
#      rel00 sub relation, relates role00, relates extra_role;
#      rel01 sub relation, relates role01;
#      rel1 sub rel00;
#      ent0 sub entity, plays rel00:role00, plays rel01:role01;
#
#      rule make-me-illegal:
#      when {
#        (role00: $e) isa rel1;
#      } then {
#        (role01: $e) isa rel01;
#      };
#    """
#    Given transaction commits
#
#    When connection open schema transaction for database: typedb
#    Then delete relation type: rel01; fails
#
#    When transaction closes
#    When connection open schema transaction for database: typedb
#    Then delete relation type: rel1; fails
#
#    When transaction closes
#    When connection open schema transaction for database: typedb
#    Then relation(rel01) delete role: role01; fails
#
#    # We currently can't do this at operation time, so we check at commit-time
#    When transaction closes
#    When connection open schema transaction for database: typedb
#    Then relation(rel00) delete role: role00
#    Then transaction commits; fails

#  TODO: Refactor to functions
#  Scenario: Rules made unsatisfiable by schema modifications are flagged at commit time
#    Given typeql schema query
#    """
#    define
#      rel00 sub relation, relates role00, relates extra_role;
#      rel01 sub relation, relates role01;
#      rel1 sub rel00;
#
#      ent00 sub entity, abstract, plays rel00:role00, plays rel01:role01;
#      ent01 sub entity, abstract;
#      ent1 sub ent00;
#
#      rule make-me-unsatisfiable:
#      when {
#        $e isa ent1;
#        (role00: $e) isa rel1;
#      } then {
#        (role01: $e) isa rel01;
#      };
#    """
#    Given transaction commits
#
#    When connection open schema transaction for database: typedb
#    Then relation(rel1) set supertype: rel01
#    Then transaction commits; fails
#
#    When connection open schema transaction for database: typedb
#    Then entity(ent00) unset plays: rel00:role00
#    Then transaction commits; fails
#
#    When connection open schema transaction for database: typedb
#    Then entity(ent1) set supertype: ent01
#    Then transaction commits; fails
