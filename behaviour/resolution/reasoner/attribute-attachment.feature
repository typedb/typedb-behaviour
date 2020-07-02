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
      | completion |
      | test       |
    Given transaction is initialised
    Given the integrity is validated
    Given graql define
      """
      define

      person sub entity,
          plays leader,
          plays team-member,
          has string-attribute,
          has unrelated-attribute,
          has sub-string-attribute,
          has age,
          has is-old;

      tortoise sub entity,
          has age,
          has is-old;

      soft-drink sub entity,
          has retailer;

      team sub relation,
          relates leader,
          relates team-member,
          has string-attribute;

      string-attribute sub attribute, value string;
      retailer sub attribute, value string;
      age sub attribute, value long;
      is-old sub attribute, value boolean;
      sub-string-attribute sub string-attribute;
      unrelated-attribute sub attribute, value string;
      """
    Given the integrity is validated


  Scenario: reusing attributes, reattaching an attribute to an entity
    When reference kb is completed
    Then for graql query
      """
      match $x isa genericEntity; get;
      """
    Then answer size is: 2
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
