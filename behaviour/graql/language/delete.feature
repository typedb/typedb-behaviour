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
Feature: Graql Delete Query
  Scenario: delete an instance using 'thing' meta label succeeds
  Scenario: delete an relation instance using 'relation' meta label succeeds
  Scenario: delete an entity instance using 'entity' meta label succeeds
  Scenario: delete an attribute instance using 'attribute' meta label succeeds
  Scenario: delete a role player from a relation removes the player from the relation
  Scenario: delete an instance the instance not a player in any relation anymore
  Scenario: delete duplicate role players from a relation removes duplicate player from relation
  Scenario: delete attribute ownership makes attribute invisible to owner
  Scenario: delete role players in multiple statements are all deleted
  Scenario: delete all role players of relation cleans up relation instance
  Scenario: delete more role players than exist throws
  Scenario: delete a role player with too-specific (downcasting) role label throws
  Scenario: delete an instance using wrong type throws
  Scenario: delete an instance using too-specific (downcasting) type throws