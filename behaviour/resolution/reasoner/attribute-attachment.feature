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

Feature: Attribute Attachment Resolution

  Background: Setup base KBs

    Given connection has been opened
    Given connection delete all keyspaces
    Given connection open sessions for keyspaces:
      | completion  |
      | test        |
    Given transaction is initialised
    Given the integrity is validated
    Given graql define
      """
      define

      genericEntity sub entity,
          plays someRole,
          plays otherRole,
          has reattachable-resource-string,
          has unrelated-reattachable-string,
          has subResource,
          has resource-long,
          has derived-resource-boolean;

      anotherEntity sub entity,
          has resource-long,
          has derived-resource-boolean;

      yetAnotherEntity sub entity,
          has derived-resource-string;

      relation0 sub relation,
          relates someRole,
          relates otherRole,
          has reattachable-resource-string;

      derivable-resource-string sub attribute, value string;
      reattachable-resource-string sub derivable-resource-string, value string;
      derived-resource-string sub derivable-resource-string, value string;
      resource-long sub attribute, value long;
      derived-resource-boolean sub attribute, value boolean;
      subResource sub reattachable-resource-string;
      unrelated-reattachable-string sub attribute, value string;

      transferResourceToEntity sub rule,
      when {
          $x isa genericEntity, has reattachable-resource-string $r1;
          $y isa genericEntity;
      },
      then {
          $y has reattachable-resource-string $r1;
      };

      transferResourceToRelation sub rule,
      when {
          $x isa genericEntity, has reattachable-resource-string $y;
          $z isa relation0;
      },
      then {
          $z has reattachable-resource-string $y;
      };

      attachResourceValueToResourceOfDifferentSubtype sub rule,
      when {
          $x isa genericEntity, has reattachable-resource-string $r1;
      },
      then {
          $x has subResource $r1;
      };

      attachResourceValueToResourceOfUnrelatedType sub rule,
      when {
          $x isa genericEntity, has reattachable-resource-string $r1;
      },
      then {
          $x has unrelated-reattachable-string $r1;
      };

      setResourceFlagBasedOnOtherResourceValue sub rule,
      when {
          $x isa anotherEntity, has resource-long > 0;
      },
      then {
          $x has derived-resource-boolean true;
      };

      attachResourceToEntity sub rule,
      when {
          $x isa yetAnotherEntity;
      },
      then {
          $x has derived-resource-string 'value';
      };

      attachUnattachedResourceToEntity sub rule,
      when {
          $x isa derived-resource-string;
          $x == 'unattached';
          $y isa yetAnotherEntity;
      },
      then {
          $y has derived-resource-string 'unattached';
      };
      """
    Given the integrity is validated
    Given graql insert
      """
      insert

      $geX isa genericEntity, has reattachable-resource-string "value";
      $geY isa genericEntity;
      (someRole:$geX, otherRole:$geX) isa relation0;

      $se isa anotherEntity, has resource-long 1;
      $aeX isa yetAnotherEntity;
      $aeY isa yetAnotherEntity;

      $r "unattached" isa derived-resource-string;
      """


  Scenario: reusing attributes, reattaching an attribute to an entity
    When reference kb is completed
    Then for graql query
      """
      match $x isa genericEntity; get;
      """
    Then answer count is correct
    Then answers resolution is correct
    Then for graql query
      """
      match $x isa genericEntity, has reattachable-resource-string $y; get;
      """
    Then answer count is correct
    Then answers resolution is correct
    Then for graql query
      """
      match $x isa reattachable-resource-string; get;
      """
    Then answer count is correct
    Then answers resolution is correct
    Then test keyspace is complete
