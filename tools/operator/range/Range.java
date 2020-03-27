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

package grakn.verification.tools.operator.range;

import graql.lang.property.ValueProperty;
import java.util.Set;

public interface Range<T> {

    T lowerBound();
    T upperBound();

    /**
     * @param that range to merge with
     * @return range being a subrange of this and provided ranges
     */
    Range<T> merge(Range<T> that);

    /**
     * @return a range that contains this range (a generalisation of this range)
     */
    Range<T> generalise();

    /**
     * @return Set of ValueProperty that corresponds to this range.
     */
    Set<ValueProperty> toProperties();
}
