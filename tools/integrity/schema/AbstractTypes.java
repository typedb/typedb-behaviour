/*
* Copyright (C) 2020 Grakn Labs
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

import com.google.common.collect.Sets;
import grakn.verification.tools.integrity.IntegrityException;
import grakn.verification.tools.integrity.RejectDuplicateSet;
import grakn.verification.tools.integrity.Type;
import grakn.verification.tools.integrity.Validator;

import java.util.Set;

public class AbstractTypes extends RejectDuplicateSet<Type> {

    @Override
    public void validate() {
        /*
        Must contain all the meta types
         */

        for (Validator.META_TYPES metaLabel : Validator.META_TYPES.values()) {
            boolean found = false;
            for (Type type : set) {
                if (type.label().equals(metaLabel.getName())) {
                    found = true;
                }
            }
            if (!found) {
                throw IntegrityException.metaTypeNotAbstract(metaLabel.toString());
            }
        }
    }
}
