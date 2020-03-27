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

package grakn.verification.tools.integrity;

import java.util.HashSet;
import java.util.Iterator;
import java.util.Set;

public class RejectDuplicateSet<T> implements SemanticSet<T> {

    protected Set<T> set;

    public RejectDuplicateSet() {
        set = new HashSet<>();
    }

    @Override
    public void add(T item) {
        if (set.contains(item)) {
            throw IntegrityException.duplicateSemanticSetItem(item , this);
        }

        set.add(item);
    }

    @Override
    public Iterator<T> iterator() {
        return set.iterator();
    }

    @Override
    public String toString() {
        StringBuilder stringBuilder = new StringBuilder();
        for (T item : set) {
            stringBuilder.append(item.toString());
            stringBuilder.append(", ");
        }
        return stringBuilder.toString();
    }

    @Override
    public boolean contains(T item) {
        return set.contains(item);
    }

    @Override
    public int size() {
        return set.size();
    }

    @Override
    public void validate() {
        // always valid if we don't error during 'add()'
    }
}
