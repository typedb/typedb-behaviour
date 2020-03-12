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

    public static IntegrityException metaTypeCannotOwnAttribute(Type metaType, Type attribute) {
        return new IntegrityException(String.format("%s meta type may not own attributes, has: %s ", metaType.label(), attribute.label()));
    }

    public static IntegrityException metaTypeCannotPlayRole(Type metaType, Type role) {
        return new IntegrityException(String.format("%s meta type may not play roles, plays: %s", metaType.label(), role.label()));
    }

    public static IntegrityException metaTypeCannotRelateRole(Type metaType, Type role) {
        return new IntegrityException(String.format("%s meta type may not relate roles, relates: %s", metaType.label(), role.label()));
    }

    public static IntegrityException keyshipNotSubsetOfOwnership(Type owner, Type attribute) {
        return new IntegrityException(String.format("Keyship from %s to attribute type %s is identified as attribute ownership as well", owner, attribute));
    }

    public static IntegrityException metaTypeNotAbstract(String metaLabel) {
        return new IntegrityException(String.format("Meta type %s is not labeled abstract", metaLabel));
    }

    public static IntegrityException relationWithoutRole(Type relation) {
        return new IntegrityException(String.format("Relation type %s has no linked roles", relation));
    }

    public static IntegrityException playedRoleIsNotRelated(Type role, Type player) {
        return new IntegrityException(String.format("Role %s is played by %s but is not related", role, player));
    }

    public static IntegrityException subHierarchyHasLoop(Type typeWithLoop) {
        return new IntegrityException(String.format("Type %s is in a loop in the transitive closure of sub, implying a loop in the type hierarchy", typeWithLoop));
    }

    public static IntegrityException typeHasMultipleParentTypesInSub(Type type, Type parent1, Type parent2) {
        return new IntegrityException(String.format("Type %s has two parent types in direct sub: %s and %s", type, parent1, parent2));
    }
}
