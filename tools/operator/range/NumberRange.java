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

package grakn.verification.tools.operator.range;

import com.google.common.collect.Sets;
import graql.lang.Graql;
import graql.lang.property.ValueProperty;
import graql.lang.statement.Statement;
import graql.lang.statement.Variable;
import java.util.HashSet;
import java.util.Set;

public class NumberRange implements Range<Number>{
    private final Number lowerBound;
    private final Number upperBound;

    private NumberRange(Number low, Number high){
        this.lowerBound = low;
        this.upperBound = high;
    }

    public static Range create(Graql.Token.Comparator comp, Object val){
        if (!(val instanceof Number)) return new NumberRange(null, null);
        Number value = (Number) val;
        switch(comp){
            case EQV: case NEQV:
                return new NumberRange(value, value);
            case GT: case GTE:
                return new NumberRange(value, null);
            case LT: case LTE:
                return new NumberRange(null, value);
            default:
                return new NumberRange(null, null);
        }
    }

    @Override
    public String toString(){
        return "[" + (lowerBound() != null? lowerBound : "-INF") + ", " + (upperBound() != null? upperBound : "INF") +"]";
    }

    @Override public Number lowerBound() { return lowerBound; }
    @Override public Number upperBound() { return upperBound; }

    @Override
    public Range<Number> merge(Range<Number> that){
        Number low = lowerBound() == null?
                that.lowerBound() :
                that.lowerBound() != null? Math.max(lowerBound().doubleValue(), that.lowerBound().doubleValue()) : lowerBound();
        Number high = upperBound() == null?
                that.upperBound() :
                that.upperBound() != null? Math.min(upperBound().doubleValue(), that.upperBound().doubleValue()) : upperBound();
        return new NumberRange( low, high);
    }

    @Override
    public Range<Number> generalise(){
        if (lowerBound() != null && upperBound() != null){
            double hdiff = Math.abs((upperBound().doubleValue() - lowerBound().doubleValue()))/2;
            if (lowerBound().equals(upperBound())) hdiff = lowerBound().doubleValue()/2;
            Number low = lowerBound().doubleValue() - hdiff;
            Number high = upperBound().doubleValue() + hdiff;
            return new NumberRange(low, high);
        }

        Number low = null;
        Number high = null;
        if (lowerBound() != null){
            double val = lowerBound().doubleValue();
            low = val - Math.abs(val)/2;
        }
        if (upperBound() != null) {
            double val = upperBound().doubleValue();
            high = val + Math.abs(val)/2;
        }
        return new NumberRange(low, high);
    }

    @Override
    public Set<ValueProperty> toProperties(){
        if (lowerBound() == null && upperBound() == null){
            Statement newStatement = Graql.var(new Variable().asReturnedVar());
            ValueProperty.Operation.Comparison.Variable operation = new ValueProperty.Operation.Comparison.Variable(Graql.Token.Comparator.EQV, newStatement);
            return Sets.newHashSet(new ValueProperty<>(operation));
        }

        if (lowerBound() != null && lowerBound().equals(upperBound())) {
            ValueProperty.Operation.Assignment.Number<Number> assignment = new ValueProperty.Operation.Assignment.Number.Number<Number>(lowerBound());
            return Sets.newHashSet(new ValueProperty<>(assignment));
        }
        Set<ValueProperty > vps = new HashSet<>();
        if (lowerBound() != null){
            ValueProperty.Operation.Comparison.Number<Number> comparison = new ValueProperty.Operation.Comparison.Number<>(Graql.Token.Comparator.GT, lowerBound());
            vps.add(new ValueProperty<>(comparison));
        }
        if (upperBound() != null) {
            ValueProperty.Operation.Comparison.Number<Number> comparison = new ValueProperty.Operation.Comparison.Number<>(Graql.Token.Comparator.LT, upperBound());
            vps.add(new ValueProperty<>(comparison));
        }
        return vps;
    }

}
