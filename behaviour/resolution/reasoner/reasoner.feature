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

Feature: transitivity

  Background: Setup base KBs

    Given connection has been opened
    Given connection delete all keyspaces
    Given connection open sessions for keyspaces:
      | completion  |
      | test        |

  Scenario: 3-hop transitivity
    Given graql define
      """
      define
      name sub attribute,
      value string;

      location-hierarchy-id sub attribute,
          value long;

      location sub entity,
          abstract,
          key name,
          plays location-hierarchy_superior,
          plays location-hierarchy_subordinate;

      area sub location;
      city sub location;
      country sub location;
      continent sub location;

      location-hierarchy sub relation,
          key location-hierarchy-id,
          relates location-hierarchy_superior,
          relates location-hierarchy_subordinate;

      location-hierarchy-transitivity sub rule,
      when {
          (location-hierarchy_superior: $a, location-hierarchy_subordinate: $b) isa location-hierarchy;
          (location-hierarchy_superior: $b, location-hierarchy_subordinate: $c) isa location-hierarchy;
      }, then {
          (location-hierarchy_superior: $a, location-hierarchy_subordinate: $c) isa location-hierarchy;
      };
      """
    Given graql insert
      """
      insert
      $ar isa area, has name "King's Cross";
      $cit isa city, has name "London";
      $cntry isa country, has name "UK";
      $cont isa continent, has name "Europe";
      (location-hierarchy_superior: $cont, location-hierarchy_subordinate: $cntry) isa location-hierarchy, has location-hierarchy-id 0;
      (location-hierarchy_superior: $cntry, location-hierarchy_subordinate: $cit) isa location-hierarchy, has location-hierarchy-id 1;
      (location-hierarchy_superior: $cit, location-hierarchy_subordinate: $ar) isa location-hierarchy, has location-hierarchy-id 2;
      """

    When reference kb is completed
    Then for graql query
      """
      match $lh (location-hierarchy_superior: $continent, location-hierarchy_subordinate: $area) isa location-hierarchy;
      $continent isa continent; $area isa area;
      get;
      """
    Then answer count is correct
    Then answers resolution is correct
    Then test keyspace is complete
