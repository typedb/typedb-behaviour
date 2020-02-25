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

import com.google.common.collect.Sets;
import grakn.common.util.Pair;
import grakn.verification.tools.integrity.IntegrityException;
import grakn.verification.tools.integrity.SemanticSet;
import grakn.verification.tools.integrity.Type;
import grakn.verification.tools.integrity.Validator;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Transitive closure of Sub, not including (x,x) pairs
 * In other words, transitive Sub relation without the identity relation
 */
public class SubTrans implements SemanticSet<Pair<Type, Type>> {

    private Set<Pair<Type,Type>> set;

    public SubTrans() {
        set = new HashSet<>();
    }

    @Override
    public void validate() {
        /*
        Conditions of validity:
        1. every type that isn't a meta type has exactly one parent in [entity, relation or attribute]
        2. every type has an entry (x, thing)
         */

        Set<String> metaTypes = Sets.newHashSet(
                Validator.META_ENTITY,
                Validator.META_RELATION,
                Validator.META_ATTRIBUTE,
                Validator.META_ROLE
        );

        Map<Type, Integer> typeMetaParentCount = new HashMap<>();
        for (Pair<Type, Type> item : set) {
            Type child = item.first();
            Type parent = item.second();
            if (metaTypes.contains(parent.label())) {
                typeMetaParentCount.putIfAbsent(child, 0);
                typeMetaParentCount.compute(child, (childType, oldCount) -> oldCount + 1);
            }
        }

        Set<Type> nonMetaTypes = set.stream()
                .map(pair -> pair.first())
                .filter(type -> !metaTypes.contains(type.label()))
                .filter(type -> !type.label().equals("thing"))
                .collect(Collectors.toSet());
        for (Type type : nonMetaTypes) {
            int numMetaParents = typeMetaParentCount.getOrDefault(type, 0);
            if (numMetaParents != 1) {
                throw IntegrityException.typeDoesNotHaveExactlyOneMetaSupertype(type, numMetaParents);
            }
        }

        Set<Type> children = set.stream().map(pair -> pair.first()).collect(Collectors.toSet());
        for (Type child : children) {
            boolean hasThingSuper = false;
            for (Pair<Type, Type> sub : set) {
                if (sub.first() == child && sub.second().label().equals(Validator.META_THING)) {
                    hasThingSuper = true;
                    break;
                }
            }
            if (!hasThingSuper) {
                throw IntegrityException.typeDoesNotHaveThingSuperType(child);
            }
        }
    }

    @Override
    public void add(Pair<Type, Type> item) {
        set.add(item);
    }

    public boolean contains(Pair<Type, Type> item) {
        return set.contains(item);
    }

    @Override
    public Iterator<Pair<Type, Type>> iterator() {
        return set.iterator();
    }

    public SubTrans shallowCopy() {
        SubTrans copy = new SubTrans();
        set.forEach(copy::add);
        return copy;
    }

    public int size() {
        return set.size();
    }
}
