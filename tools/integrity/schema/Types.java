/*
 * GRAKN.AI - THE KNOWLEDGE GRAPH
 * Copyright (C) 2019 Grakn Labs Ltd
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 */

package grakn.verification.tools.integrity.schema;

import grakn.verification.tools.integrity.RejectDuplicateSet;
import grakn.verification.tools.integrity.Type;
import grakn.verification.tools.integrity.Validatable;

public class Types extends RejectDuplicateSet<Type> implements Validatable {

    @Override
    public void validate() {
        // always valid as long as the internal set construction errors on duplicate entry
    }
}
