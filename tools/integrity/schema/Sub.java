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

import com.google.common.annotations.VisibleForTesting;
import grakn.common.util.Pair;
import grakn.verification.tools.integrity.IntegrityException;
import grakn.verification.tools.integrity.RejectDuplicateSet;
import grakn.verification.tools.integrity.Type;

public class Sub extends RejectDuplicateSet<Pair<Type, Type>> {

    @VisibleForTesting
    public TransitiveSub noIdentityTransitiveSub() {
        TransitiveSub transitiveSub = new TransitiveSub();

        for (Pair<Type, Type> subEntry : set) {
            // don't include (x,x) in the transitive sub closure
            // this is because if we do end up with (x,x) in the transitive closure, then we know there is a loop
            if (subEntry.first() != subEntry.second()) {
                transitiveSub.add(subEntry);
            }
        }

        // note: inefficient!
        // computes transitive closure, updating into `updatedTransitiveSub` from `transitiveSub`
        TransitiveSub updatedTransitiveSub = transitiveSub.shallowCopy();
        boolean changed = true;
        while (changed) {
            transitiveSub = updatedTransitiveSub.shallowCopy();
            changed = false;
            for (Pair<Type, Type> sub1 : transitiveSub) {
                for (Pair<Type, Type> sub2 : transitiveSub) {
                    if (sub1.second().equals(sub2.first())) {
                        Pair<Type, Type> transitiveSubEntry = new Pair<>(sub1.first(), sub2.second());
                        if (!transitiveSub.contains(transitiveSubEntry)) {
                            updatedTransitiveSub.add(transitiveSubEntry);
                            changed = true;
                        }
                    }

                }
            }
        }

        return transitiveSub;
    }

    @Override
    public void validate() {
        /*
        if (x,y) and (x,z) in sub, then y == z

        Also manually building a transitive sub should pass validation
        */

        for (Pair<Type, Type> sub1 : set) {
            for (Pair<Type, Type> sub2 : set) {
                if (sub1.first().equals(sub2.first()) && !sub1.second().equals(sub2.second())) {
                    throw IntegrityException.typeHasMultipleParentTypesInSub(sub1.first(), sub1.second(), sub2.second());
                }
            }
        }

        TransitiveSub transitiveSub = noIdentityTransitiveSub();
        transitiveSub.validate();
    }
}
