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

package grakn.verification.tools.integrity;

public class IntegrityException extends RuntimeException {

    private IntegrityException(String message){
        super(message);
    }

    public static IntegrityException typeDoesNotHaveExactlyOneMetaSupertype(Type type, int numMetaSupertypes) {
        return new IntegrityException(String.format("Type %s has %d meta super types", type.toString(), numMetaSupertypes));
    }

    public static IntegrityException typeDoesNotHaveThingSuperType(Type child) {
        return new IntegrityException(String.format("Type %s has no Thing super", child.toString()));
    }

    public static <T> IntegrityException duplicateSemanticSetItem(T duplicateItem, RejectDuplicateSet<T> rejectingSet) {
        return new IntegrityException(String.format("Duplicate insertion of item: %s into set: %s", duplicateItem, rejectingSet));
    }
}
