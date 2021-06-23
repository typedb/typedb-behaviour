#
# Copyright (C) 2021 Vaticle
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

@ignore-typedb-client-java
@ignore-typedb-client-python
@ignore-typedb-client-nodejs
Feature: Connection Users

  Background: open client
    Given connection has been opened

  Scenario: cluster users can be created and deleted
    Given users contains: admin
    Then users not contains: user
    Then users create: user, password
    Then users contains: user
    Then user password: user, new-password
    Then user connect: user, new-password
    Then user delete: user
    Then users not contains: users
