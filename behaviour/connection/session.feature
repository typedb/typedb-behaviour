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

Feature: Connection Session

  Background:
    Given connection has been opened
    Given connection delete all keyspaces
    Given connection does not have any keyspace

  Scenario: for one keyspace, open one session
    When connection create keyspace:
      | grakn   |
    When connection open session for keyspace:
      | grakn   |
    Then session is null: false
    Then session is open: true
    Then session has keyspace:
      | grakn   |

  Scenario: for one keyspace, open many sessions
    When connection create keyspace:
      | grakn   |
    When connection open sessions for keyspaces:
      | grakn   |
      | grakn   |
      | grakn   |
      | grakn   |
      | grakn   |
      | grakn   |
      | grakn   |
      | grakn   |
      | grakn   |
      | grakn   |
      | grakn   |
      | grakn   |
    Then sessions are null: false
    Then sessions are open: true
    Then sessions have keyspaces:
      | grakn   |
      | grakn   |
      | grakn   |
      | grakn   |
      | grakn   |
      | grakn   |
      | grakn   |
      | grakn   |
      | grakn   |
      | grakn   |
      | grakn   |
      | grakn   |

  Scenario: for one keyspace, open many sessions in parallel
    When connection create keyspace:
      | grakn   |
    When connection open sessions in parallel for keyspaces:
      | grakn   |
      | grakn   |
      | grakn   |
      | grakn   |
      | grakn   |
      | grakn   |
      | grakn   |
      | grakn   |
      | grakn   |
      | grakn   |
      | grakn   |
      | grakn   |
    Then sessions in parallel are null: false
    Then sessions in parallel are open: true
    Then sessions in parallel have keyspaces:
      | grakn   |
      | grakn   |
      | grakn   |
      | grakn   |
      | grakn   |
      | grakn   |
      | grakn   |
      | grakn   |
      | grakn   |
      | grakn   |
      | grakn   |
      | grakn   |

  Scenario: for many keyspaces, open many sessions
    When connection create keyspaces:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |
      | eve     |
      | frank   |
      | george  |
      | heidi   |
      | ivan    |
      | judy    |
      | mike    |
      | neil    |
    When connection open sessions for keyspaces:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |
      | eve     |
      | frank   |
      | george  |
      | heidi   |
      | ivan    |
      | judy    |
      | mike    |
      | neil    |
    Then sessions are null: false
    Then sessions are open: true
    Then sessions have keyspaces:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |
      | eve     |
      | frank   |
      | george  |
      | heidi   |
      | ivan    |
      | judy    |
      | mike    |
      | neil    |

  Scenario: for many keyspaces, open many sessions in parallel
    When connection create keyspaces:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |
      | eve     |
      | frank   |
      | george  |
      | heidi   |
      | ivan    |
      | judy    |
      | mike    |
      | neil    |
    When connection open sessions in parallel for keyspaces:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |
      | eve     |
      | frank   |
      | george  |
      | heidi   |
      | ivan    |
      | judy    |
      | mike    |
      | neil    |
    Then sessions in parallel are null: false
    Then sessions in parallel are open: true
    Then sessions in parallel have keyspaces:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |
      | eve     |
      | frank   |
      | george  |
      | heidi   |
      | ivan    |
      | judy    |
      | mike    |
      | neil    |
